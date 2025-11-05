import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'dart:math';

import 'package:secret_sorcerer/models/game_state.dart';

class FirebaseController {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  //helper to fetch collection
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchLobby(int lobbyId) =>
    _firestore.collection('lobbies').doc(lobbyId.toString()).snapshots();
    

  Stream<DocumentSnapshot> createLobby(int hostId) {
    int randomInt = Random().nextInt(9999) + 1000;
    final lobbyRef = _firestore.collection('lobbies').doc(randomInt.toString());
    lobbyRef.set({
      'status': 'waiting',
      'creatorId': hostId,
      'players': [hostId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return lobbyRef.snapshots();
  }

  Stream<DocumentSnapshot> joinLobby(int lobbyId, int playerId) {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId.toString());
    lobbyRef.update({
      'players': FieldValue.arrayUnion([playerId]),
    });
    return lobbyRef.snapshots();
  }

  Future<void> leaveLobby(int lobbyId, int playerId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId.toString());
    await lobbyRef.update({
      'players': FieldValue.arrayRemove([playerId]),
    });
  }

  Future<void> deleteLobby(int lobbyId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId.toString());
    await lobbyRef.delete();
  }

   // Start game
  Future<void> startGame(int lobbyId, List<GamePlayer> player) async {
    final stateRef = _firestore.collection('states').doc(lobbyId.toString());
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId.toString());
    final state = GameState(player);
    await stateRef.set(state.toMap());
    await lobbyRef.update({'status': 'playing'});
  }

  // Watch game state
  Stream<DocumentSnapshot> watchGame(int code) =>
      _firestore.collection('states').doc(code.toString()).snapshots();
}