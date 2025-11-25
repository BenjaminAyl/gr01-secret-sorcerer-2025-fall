import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';

class LobbyController {
  final FirebaseController _firebase = FirebaseController();
  late String playerId;
  late String lobbyId;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> lobbyStream;

  Future<void> init(String code) async {
    lobbyId = code;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No signed-in user found.');
    playerId = user.uid;
    lobbyStream = _firebase.watchLobby(lobbyId);
  }
 Future<void> leaveLobby({
    required String lobbyId,
    required String myUid,
    required Map<String, dynamic> lobbyData,
  }) async {
    final creatorId = lobbyData['creatorId'] as String?;
    final players = List<String>.from(lobbyData['players'] ?? []);
    final isHost = creatorId == myUid;

    if (isHost) {
      // Host leaving then completely delete lobby for everyone
      await _firebase.deleteLobby(lobbyId);
      return;
    }

    // Client leaving
    await _firebase.leaveLobby(lobbyId, myUid);

    // If host already gone or only 1 left -> delete lobby
    if (players.length <= 1) {
      await _firebase.deleteLobby(lobbyId);
    }
  }


  Future<void> startGame(List<String> ids) async {
    await _firebase.startGame(lobbyId, ids);
  }

  Future<void> resetLobby() async {
    await _firebase.resetLobby(lobbyId);
  }
}
