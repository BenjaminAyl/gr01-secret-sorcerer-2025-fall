import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'dart:math';
import 'package:secret_sorcerer/models/game_state.dart';

class FirebaseController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //authentication management
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

  //lobby management
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchLobby(String lobbyId) =>
      _firestore.collection('lobbies').doc(lobbyId).snapshots();

  Future<DocumentReference<Map<String, dynamic>>> createLobby() async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');

    final randomInt = Random().nextInt(8999) + 1000;
    final code = randomInt.toString();
    final lobbyRef = _firestore.collection('lobbies').doc(code);

    //get nickname
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

  //Add player and their nickname when joining
  Future<void> joinLobby(String lobbyId, String playerId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);

    // Fetch nickname from users collection
    final userDoc = await _firestore.collection('users').doc(playerId).get();
    final userData = userDoc.data() ?? {};
    final nickname = userData['Nickname'] ?? 'Unknown';

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
  ///Reset the lobby to waiting state (after a round)
  Future<void> resetLobby(String lobbyId) async {
    await _firestore.collection('lobbies').doc(lobbyId).update({
      'status': 'waiting',
    });
  }

  //game management
  Future<void> startGame(String lobbyId, List<GamePlayer> players) async {
    final stateRef = _firestore.collection('states').doc(lobbyId);
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    final state = GameState(players);

    await stateRef.set(state.toMap());
    await lobbyRef.update({'status': 'playing'});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGame(String lobbyId) =>
      _firestore.collection('states').doc(lobbyId).snapshots();
}
