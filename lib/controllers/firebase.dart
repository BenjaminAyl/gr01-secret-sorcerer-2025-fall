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

    // ✅ Build proper GamePlayer list
    final players = playerIds
        .map((uid) => GamePlayer(username: uid, role: 'unknown'))
        .toList();

    final state = GameState(players);
    await stateRef.set(state.toMap());
    await lobbyRef.update({'status': 'playing'});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGame(String lobbyId) =>
      _firestore.collection('states').doc(lobbyId).snapshots();

  // ---------------- GAME ACTIONS ----------------
  Future<void> updateHeadmaster(String lobbyId, int index, String uid) async {
    // ✅ Always use UID as identifier
    await _firestore.collection('states').doc(lobbyId).update({
      'headmasterIdx': index,
      'headmaster': uid,
      'spellcaster': null,
    });
  }

  Future<void> updateSpellcaster(String lobbyId, String uid) async {
    await _firestore.collection('states').doc(lobbyId).update({
      'spellcaster': uid,
    });
  }
  Future<void> _rotateHeadmaster(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    final doc = await stateRef.get();
    final data = doc.data() ?? {};

    final players = (data['players'] as List?) ?? [];
    if (players.isEmpty) return;

    final currentIdx = (data['headmasterIdx'] ?? 0) as int;
    final nextIdx = (currentIdx + 1) % players.length;
    final nextUid = players[nextIdx]['username'] ?? '';

    await stateRef.update({
      'headmasterIdx': nextIdx,
      'headmaster': nextUid,
      'spellcaster': null,
    });
  }

  Future<void> incrementCharm(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    final doc = await stateRef.get();
    final data = doc.data() ?? {};
    final current = (data['charms'] ?? 0) as int;

    await stateRef.update({'charms': current + 1});
    await _rotateHeadmaster(lobbyId);
  }

  Future<void> incrementCurse(String lobbyId) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    final doc = await stateRef.get();
    final data = doc.data() ?? {};
    final current = (data['curses'] ?? 0) as int;

    await stateRef.update({'curses': current + 1});
    await _rotateHeadmaster(lobbyId);
  }

}
