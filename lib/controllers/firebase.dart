import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'package:secret_sorcerer/models/game_state.dart';
import 'dart:math';
import 'package:secret_sorcerer/models/user_model.dart';

class FirebaseController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Auth gate
  Future<UserCredential> signUp(String email, String password) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  //Lobby MANAGEMENT
  Future<List<Map<String, dynamic>>> loadAllUsers() async {
    final snapshot = await _firestore.collection('users')
      .orderBy( 'wins', descending: true )
      .get();
    // Map each document to a User instance
    return snapshot.docs.map((doc) {
      final data = doc.data();      // Map<String, dynamic>
      data['id'] = doc.id;          // optionally include the document ID
      return data;
    }).toList();
  }

  //lobby management
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchLobby(String lobbyId) =>
      _firestore.collection('lobbies').doc(lobbyId).snapshots();

  Future<DocumentReference<Map<String, dynamic>>> createLobby() async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');

    final randomInt = Random().nextInt(8999) + 1000;
    final code = randomInt.toString();
    final lobbyRef = _firestore.collection('lobbies').doc(code);

    //lowercase key fix
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final nickname = userData['Nickname'] ?? 'Unknown';

    await lobbyRef.set({
      'status': 'waiting',
      'creatorId': user.uid,
      'players': [user.uid],
      'nicknames': {user.uid: nickname},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return lobbyRef;
  }

  Future<void> joinLobby(String lobbyId, String playerId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);

    final userDoc = await _firestore.collection('users').doc(playerId).get();
    final userData = userDoc.data() ?? {};
    final nickname = userData['Nickname'] ?? 'Unknown'; //lowercase fix

    await lobbyRef.update({
      'players': FieldValue.arrayUnion([playerId]),
      'nicknames.$playerId': nickname,
    });
  }

  Future<void> leaveLobby(String lobbyId, String playerId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    await lobbyRef.update({
      'players': FieldValue.arrayRemove([playerId]),
      'nicknames.$playerId': FieldValue.delete(),
    });
  }

  Future<void> deleteLobby(String lobbyId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    await lobbyRef.update({'status': 'closing'}).catchError((_) {});
    await Future.delayed(const Duration(milliseconds: 300));
    await lobbyRef.delete();
  }

  Future<void> resetLobby(String lobbyId) async {
    await _firestore.collection('lobbies').doc(lobbyId).update({
      'status': 'waiting',
    });
  }

  //Start game entrance
  Future<void> startGame(String lobbyId, List<String> playerIds) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    final shuffled = List<String>.from(playerIds)..shuffle();
    final players = _assignRoles(shuffled);
    final randomHM = Random().nextInt(players.length);

    final state = GameState(players)
      ..headmasterIdx = randomHM
      ..headmaster = players[randomHM].username;

    await stateRef.set(state.toMap());
    await lobbyRef.update({'status': 'playing'});
  }


  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGame(String lobbyId) =>
      _firestore.collection('states').doc(lobbyId).snapshots();

  //GAME ACTIONS (turn order etc)
  Future<void> updateHeadmaster(String lobbyId, int index, String uid) async {
    await _firestore.collection('states').doc(lobbyId).update({
      'headmasterIdx': index,
      'headmaster': uid,
      'spellcaster': null,
      'phase': 'start',
      'pendingCards': [],
      'pendingOwner': null,
    });
  }

  Future<void> nominateSpellcaster(String lobbyId, String nomineeUid) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final phase = data['phase'];
      final headmaster = data['headmaster'];

      // Can only nominate from 'start' (or any phase you want to allow nomination from)
      if (phase != 'start') return;
      if (nomineeUid == headmaster) return;

      tx.update(ref, {
        'spellcasterNominee': nomineeUid,
        'spellcaster': null,
        'votes': <String, String>{},  // clear previous votes
        'phase': 'voting',
        'pendingCards': [],
        'pendingOwner': null,
      });
    });
  }
  Future<void> castVote(String lobbyId, String voterUid, bool approve) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    bool becameResultsPhase = false;
    bool passed = false;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final phase = data['phase'];
      if (phase != 'voting') return;

      final players =
          List<Map<String, dynamic>>.from((data['players'] as List?) ?? []);
      if (players.isEmpty) return;

      final headmaster = (data['headmaster'] ?? '') as String;
      final nominee = (data['spellcasterNominee'] ?? '') as String;
      if (nominee.isEmpty) return;

      final dead = Map<String, bool>.from((data['dead'] as Map?) ?? {});
      if (dead[voterUid] == true) return; // dead can't vote

      if (voterUid == headmaster) return; // HM does not vote

      final votes = Map<String, String>.from((data['votes'] as Map?) ?? {});
      if (votes.containsKey(voterUid)) return; // no double voting

      votes[voterUid] = approve ? 'yes' : 'no';

      // Eligible voters = everyone except HM and dead players
      final eligible = players
          .map((p) => (p['username'] ?? '') as String)
          .where((u) => u.isNotEmpty && u != headmaster && dead[u] != true)
          .toList();
      final totalNeeded = eligible.length;

      if (votes.length >= totalNeeded) {
        final yesCount = votes.values.where((v) => v == 'yes').length;
        final noCount = totalNeeded - yesCount;
        passed = yesCount > noCount;

        tx.update(ref, {
          'phase': 'voting_results',
          'votes': votes,
          'votePassed': passed,
        });
        becameResultsPhase = true;
      } else {
        tx.update(ref, {'votes': votes});
      }
    });

    if (becameResultsPhase) {
      await Future.delayed(const Duration(seconds: 8));

      final after = await _firestore.collection('states').doc(lobbyId).get();
      final d = after.data();
      if (d == null) return;

      if (d['phase'] != 'voting_results') return;

      if (passed) {
        final nominee = (d['spellcasterNominee'] ?? '') as String;
        if (nominee.isNotEmpty) {
          await _firestore.collection('states').doc(lobbyId).update({
            'spellcaster': nominee,
            'spellcasterNominee': null,
            'votes': <String, String>{},
            'votePassed': FieldValue.delete(),
            'phase': 'start',
            'pendingCards': [],
            'pendingOwner': null,
          });
          await _drawForHeadmaster(lobbyId);
        }
      } else {
        await _firestore.collection('states').doc(lobbyId).update({
          'spellcaster': null,
          'spellcasterNominee': null,
          'votes': <String, String>{},
          'votePassed': FieldValue.delete(),
          'phase': 'resolving',
          'pendingCards': [],
          'pendingOwner': null,
        });
        await _rotateHeadmaster(lobbyId);
      }
    }
  }


  Future<void> _rotateHeadmaster(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(stateRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final players = (data['players'] as List?) ?? [];
      if (players.isEmpty) return;

      final deadMap = Map<String, bool>.from((data['dead'] ?? {}));

      final currentIdx = (data['headmasterIdx'] ?? 0) as int;
      int nextIdx = currentIdx;

      //advance until we find a living wizard
      for (int i = 0; i < players.length; i++) {
        nextIdx = (nextIdx + 1) % players.length;
        final candidateUid = players[nextIdx]['username'] ?? '';
        if (deadMap[candidateUid] != true) {
          break;
        }
      }

      final nextUid = players[nextIdx]['username'] ?? '';

      tx.update(stateRef, {
        'headmasterIdx': nextIdx,
        'headmaster': nextUid,
        'spellcaster': null,
        'lastHeadmaster': data['headmaster'],
        'lastSpellcaster': data['spellcaster'],
        'phase': 'start',
        'pendingCards': [],
        'pendingOwner': null,
      });
    });
  }


  Future<void> incrementCharm(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(stateRef);
      if (!snap.exists) return;

      final current = (snap.data()!['charms'] ?? 0) as int;
      tx.update(stateRef, {'charms': current + 1});
    });
    await _rotateHeadmaster(lobbyId);
  }

  Future<void> incrementCurse(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(stateRef);
      if (!snap.exists) return;

      final current = (snap.data()!['curses'] ?? 0) as int;
      tx.update(stateRef, {'curses': current + 1});
    });
    await _rotateHeadmaster(lobbyId);
  }

  //CARD FLOW 

  Future<void> _ensureDeck(String lobbyId, int need) async {
    final ref = _firestore.collection('states').doc(lobbyId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      List deck = List.from((data['deck'] as List?) ?? []);
      List discard = List.from((data['discard'] as List?) ?? []);

      if (deck.length >= need) return;

      if (discard.isNotEmpty) {
        // Shuffle discard back into deck
        discard.shuffle();
        deck = deck + discard;
        discard = [];
        tx.update(ref, {'deck': deck, 'discard': discard});
      }
    });
  }

  Future<void> _drawForHeadmaster(String lobbyId) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    // Ensure at least 3 cards are available (refill from discard if needed)
    await _ensureDeck(lobbyId, 3);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final phase = data['phase'];
      final owner = data['pendingOwner'];

      // Only draw if we are not already in hm_discard and no pending cards exist
      if (phase == 'hm_discard' || owner == 'headmaster') return;

      List deck = List.from((data['deck'] as List?) ?? []);
      List pending = List.from((data['pendingCards'] as List?) ?? []);
      final spellcaster = data['spellcaster'];

      if (spellcaster == null || pending.isNotEmpty) return;

      if (deck.length < 3) {
        List discard = List.from((data['discard'] as List?) ?? []);
        if (discard.isNotEmpty) {
          discard.shuffle();
          deck = deck + discard;
          discard = [];
        }
      }
      if (deck.length < 3) return;

      final draw = deck.sublist(0, 3);
      final newDeck = deck.sublist(3);

      tx.update(ref, {
        'pendingCards': draw,
        'pendingOwner': 'headmaster',
        'deck': newDeck,
        'phase': 'hm_discard',
      });
    });
  }

  /// HM discards one of the 3
  Future<void> headmasterDiscard(String lobbyId, int discardIndex) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final phase = data['phase'];
      final owner = data['pendingOwner'];

      if (phase != 'hm_discard' || owner != 'headmaster') return;

      List<String> pending = List<String>.from((data['pendingCards'] as List?)?.map((e) => e.toString()) ?? []);
      List<String> discard = List<String>.from((data['discard'] as List?)?.map((e) => e.toString()) ?? []);

      if (pending.length != 3 || discardIndex < 0 || discardIndex > 2) return;

      final removed = pending.removeAt(discardIndex);
      discard.add(removed);

      tx.update(ref, {
        'pendingCards': pending,       // now 2
        'pendingOwner': 'spellcaster', // pass to SC
        'discard': discard,
        'phase': 'sc_choose',
      });
    });
  }
  String? _executivePowerFor(int players, int curses) {

    //TESTING: enable executive powers for small test games
    if (players < 5) { 
    if (curses == 1) return 'kill'; //not meant to play with under 5
    return null;
    }

    //real game
    // 5–6 players
    if (players == 5 || players == 6) {
      if (curses == 3) return "peek3";
      if (curses == 4) return "kill";
      if (curses == 5) return "kill"; 
    }

    // 7–8 players
    if (players == 7 || players == 8) {
      if (curses == 2) return "investigate";
      if (curses == 3) return "choose_next_hm";
      if (curses == 4) return "kill";
      if (curses == 5) return "kill";
    }

    // 9–10 players
    if (players == 9 || players == 10) {
      if (curses == 1) return "investigate";
      if (curses == 2) return "investigate";
      if (curses == 3) return "choose_next_hm";
      if (curses == 4) return "kill";
      if (curses == 5) return "kill";
    }

    return null;
  }


  Future<void> investigateSelectTarget(String lobbyId, String targetUid) async {
  final ref = _firestore.collection('states').doc(lobbyId);

  await ref.update({
    'executiveTarget': targetUid,
    'phase': 'executive_investigate_result',
  });
  }

  Future<void> endExecutive(String lobbyId) async {
  final ref = _firestore.collection('states').doc(lobbyId);

  await ref.update({
    'executivePower': null,
    'executiveActive': false,
    'executiveTarget': null,
    'pendingExecutiveCards': [],
    'phase': 'resolving',
  });

  // Once done, go to the next Headmaster
  await _rotateHeadmaster(lobbyId);
}

Future<void> chooseNextHeadmaster(String lobbyId, String targetUid) async {
  final ref = _firestore.collection('states').doc(lobbyId);

  await ref.update({
    'overrideHM': targetUid,
    'executiveTarget': targetUid,
    'phase': 'executive_choose_hm_result',
  });
}

Future<void> confirmNextHeadmaster(String lobbyId) async {
  final ref = _firestore.collection('states').doc(lobbyId);

  await _firestore.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final players = (data['players'] as List).cast<Map<String, dynamic>>();
    final targetUid = data['overrideHM'];

    if (targetUid == null) return;

    final newIndex = players.indexWhere((p) => p['username'] == targetUid);
    if (newIndex < 0) return;

    tx.update(ref, {
      'headmasterIdx': newIndex,
      'headmaster': targetUid,
      'spellcaster': null,
      'executivePower': null,
      'executiveActive': false,
      'executiveTarget': null,
      'pendingExecutiveCards': [],
      'phase': 'start',
    });
  });

  await _drawForHeadmaster(lobbyId);
}

  Future<void> selectKillTarget(String lobbyId, String targetUid) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final players =
          (data['players'] as List).cast<Map<String, dynamic>>();

      final victim = players.firstWhere(
        (p) => p['username'] == targetUid,
        orElse: () => {},
      );

      if (victim.isEmpty) return;

      final role = (victim['role'] ?? 'wizard') as String;

      final phase = role == 'archwarlock'
          ? 'executive_kill_result_arch'
          : 'executive_kill_result';

      tx.update(ref, {
        'executiveTarget': targetUid,
        'phase': phase,
      });
    });
  }

  Future<void> finalizeKill(String lobbyId) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final target = data['executiveTarget'];
      if (target == null) return;

      final dead = Map<String, bool>.from(data['dead'] ?? {});
      dead[target] = true;

      tx.update(ref, {
        'dead': dead,
        'executivePower': null,
        'executiveActive': false,
        'executiveTarget': null,
        'pendingExecutiveCards': [],
        'phase': 'resolving',
      });
    });

    await _rotateHeadmaster(lobbyId);
  }


  Future<void> spellcasterChoose(String lobbyId, int enactIndex) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    bool execTriggered = false;
    String? execPowerToTrigger;
    List<String> peekCards = [];
    int finalPlayersCount = 0;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final phase = data['phase'];
      final owner = data['pendingOwner'];

      if (phase != 'sc_choose' || owner != 'spellcaster') return;

      List<String> pending =
          List<String>.from((data['pendingCards'] ?? []).cast<String>());
      List<String> discard =
          List<String>.from((data['discard'] ?? []).cast<String>());
      int charms = data['charms'] ?? 0;
      int curses = data['curses'] ?? 0;
      finalPlayersCount = (data['players'] as List).length;

      if (pending.length != 2 || enactIndex < 0 || enactIndex > 1) return;

      final enacted = pending.removeAt(enactIndex);
      discard.add(pending.first);

      if (enacted == 'charm') {
        charms += 1;
      } else {
        curses += 1;

        final power = _executivePowerFor(finalPlayersCount, curses);
        if (power != null) {
          execTriggered = true;
          execPowerToTrigger = power;

          if (power == "peek3") {
            final List<String> deck =
                List<String>.from((data['deck'] ?? []).cast<String>());
            if (deck.length >= 3) {
              peekCards = List<String>.from(deck.sublist(0, 3));
            }
          }
        }
      }

      if (charms >= 5) {
        tx.update(ref, {
          'charms': charms,
          'curses': curses,
          'phase': 'game_over',
          'winnerTeam': 'order',
        });
        return;
      }

      if (curses >= 6) {
        tx.update(ref, {
          'charms': charms,
          'curses': curses,
          'phase': 'game_over',
          'winnerTeam': 'warlocks',
        });
        return;
      }

      if (curses >= 3) {
        final scUid = data['spellcaster'];
        if (scUid != null) {
          final players =
              (data['players'] as List).cast<Map<String, dynamic>>();
          final sc = players.firstWhere(
            (p) => p['username'] == scUid,
            orElse: () => {},
          );

          if (sc.isNotEmpty && sc['role'] == 'archwarlock') {
            tx.update(ref, {
              'charms': charms,
              'curses': curses,
              'phase': 'game_over',
              'winnerTeam': 'warlocks',
            });
            return;
          }
        }
      }

      tx.update(ref, {
        'charms': charms,
        'curses': curses,
        'discard': discard,
        'pendingCards': [],
        'pendingOwner': null,
        if (!execTriggered) 'phase': 'resolving',
      });

      if (!execTriggered) return;

      if (execPowerToTrigger == "investigate") {
        tx.update(ref, {
          'executivePower': 'investigate',
          'executiveActive': true,
          'phase': 'executive_investigate',
        });
      } else if (execPowerToTrigger == "peek3") {
        tx.update(ref, {
          'executivePower': 'peek3',
          'executiveActive': true,
          'phase': 'executive_peek3',
          'pendingExecutiveCards': peekCards,
        });
      } else if (execPowerToTrigger == "choose_next_hm") {
        tx.update(ref, {
          'executivePower': 'choose_next_hm',
          'executiveActive': true,
          'phase': 'executive_choose_hm',
          'executiveTarget': null,
        });
      } else if (execPowerToTrigger == "kill") {
        tx.update(ref, {
          'executivePower': 'kill',
          'executiveActive': true,
          'phase': 'executive_kill',
          'executiveTarget': null,
        });
      }
    });

    final snapshot = await _firestore.collection('states').doc(lobbyId).get();
    final endingData = snapshot.data();
    if (endingData == null) return;

    final phaseAfter = endingData['phase'];
    if (phaseAfter == 'game_over') return;

    if (execTriggered) return;

    await _rotateHeadmaster(lobbyId);
  }

  //role assignment below
  List<GamePlayer> _assignRoles(List<String> ids) {
    final n = ids.length;
    final rng = Random();

    // Shuffle for randomness
    final shuffled = List<String>.from(ids)..shuffle();

    late int numWarlocks;   // includes ArchWarlock inside
    late bool archSeesWarlocks;  
    if (n == 5) {
      numWarlocks = 2;       // 1 ArchWarlock + 1 Warlock
      archSeesWarlocks = false;
    } else if (n == 6) {
      numWarlocks = 2;       // 1 ArchWarlock + 1 Warlock
      archSeesWarlocks = true;
    } else if (n == 7) {
      numWarlocks = 3;       // 1 ArchWarlock + 2 Warlocks
      archSeesWarlocks = false;
    } else if (n == 8) {
      numWarlocks = 3;       // 1 ArchWarlock + 2 Warlocks
      archSeesWarlocks = true;
    } else if (n == 9){
      numWarlocks = 4;       // 1 ArchWarlock + 3 Warlocks
      archSeesWarlocks = false;
    } else if (n == 10){
      numWarlocks = 4;       // 1 ArchWarlock + 3 Warlocks
      archSeesWarlocks = true;
    } else {
      numWarlocks = 1;       // failsafe (just ArchWarlock)
      archSeesWarlocks = false;
  }
  final arch = shuffled.first;
  final warlocks = shuffled.sublist(1, numWarlocks);

  final players = <GamePlayer>[];

  for (final uid in shuffled) {
    if (uid == arch) {
      players.add(GamePlayer(username: uid, role: "archwarlock"));
    } else if (warlocks.contains(uid)) {
      players.add(GamePlayer(username: uid, role: "warlock"));
    } else {
      players.add(GamePlayer(username: uid, role: "wizard")); // good team
    }
  }

  for (final p in players) {
    if (p.role == "warlock") {
      // Warlocks see ArchWarlock + other Warlocks
      p.vote = ([arch, ...warlocks.where((w) => w != p.username)]).join(",");
    }
    if (p.role == "archwarlock" && archSeesWarlocks) {
      // ArchWarlock sees warlocks ONLY if rules allow
      p.vote = warlocks.join(",");
    }
  }

  return players;
}

Future<void> setGameOver({
  required String lobbyId,
  required String winningTeam, // "order" or "warlocks"
}) async {
  final ref = _firestore.collection('states').doc(lobbyId);

  await ref.update({
    'phase': 'game_over',
    'winnerTeam': winningTeam,
    'executivePower': null,
    'executiveActive': false,
    'executiveTarget': null,
    'pendingExecutiveCards': [],
    'pendingCards': [],
    'pendingOwner': null,
    'spellcasterNominee': null,
    'spellcaster': null,
    'votes': {},
    'votePassed': FieldValue.delete(),
  });
}


}