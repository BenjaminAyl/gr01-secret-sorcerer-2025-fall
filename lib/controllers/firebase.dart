import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'package:secret_sorcerer/models/game_state.dart';
import 'dart:math';

class FirebaseController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- AUTH ----------------
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

  // ---------------- LOBBY ----------------
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchLobby(String lobbyId) =>
      _firestore.collection('lobbies').doc(lobbyId).snapshots();

  Future<DocumentReference<Map<String, dynamic>>> createLobby() async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');

    final randomInt = Random().nextInt(8999) + 1000;
    final code = randomInt.toString();
    final lobbyRef = _firestore.collection('lobbies').doc(code);

    // ✅ lowercase key fix
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
    final nickname = userData['Nickname'] ?? 'Unknown'; // ✅ lowercase fix

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

  // ---------------- GAME ----------------
  Future<void> startGame(String lobbyId, List<String> playerIds) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);

    final players = playerIds
        .map((uid) => GamePlayer(username: uid, role: 'unknown'))
        .toList();

    final state = GameState(players);
    await stateRef.set(state.toMap());
    await lobbyRef.update({'status': 'playing'});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGame(String lobbyId) =>
      _firestore.collection('states').doc(lobbyId).snapshots();

  // ---------------- GAME ACTIONS (turn order etc.) ----------------
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

  Future<void> updateSpellcaster(String lobbyId, String uid) async {
    final ref = _firestore.collection('states').doc(lobbyId);
    // Set SC, then immediately draw for HM
    await ref.update({'spellcaster': uid});
    await _drawForHeadmaster(lobbyId);
  }

  Future<void> _rotateHeadmaster(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(stateRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final players = (data['players'] as List?) ?? [];
      if (players.isEmpty) return;

      final currentIdx = (data['headmasterIdx'] ?? 0) as int;
      final nextIdx = (currentIdx + 1) % players.length;
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

  /// SC chooses one to cast
  Future<void> spellcasterChoose(String lobbyId, int enactIndex) async {
    final ref = _firestore.collection('states').doc(lobbyId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final phase = data['phase'];
      final owner = data['pendingOwner'];

      if (phase != 'sc_choose' || owner != 'spellcaster') return;

      List<String> pending = List<String>.from((data['pendingCards'] as List?)?.map((e) => e.toString()) ?? []);
      List<String> discard = List<String>.from((data['discard'] as List?)?.map((e) => e.toString()) ?? []);
      int charms = (data['charms'] ?? 0) as int;
      int curses = (data['curses'] ?? 0) as int;

      if (pending.length != 2 || enactIndex < 0 || enactIndex > 1) return;

      final enacted = pending.removeAt(enactIndex); // 1 card left to discard
      final thrown = pending.first;
      discard.add(thrown);

      // Apply 
      if (enacted == 'charm') {
        charms += 1;
      } else {
        curses += 1;
      }

      tx.update(ref, {
        'charms': charms,
        'curses': curses,
        'discard': discard,
        'pendingCards': [],
        'pendingOwner': null,
        'phase': 'resolving',
      });
    });

    //rotate HM (you can also plug executive powers here later Ben)
    await _rotateHeadmaster(lobbyId);
  }
}