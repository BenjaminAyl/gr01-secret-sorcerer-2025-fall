import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/game_player.dart';

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
  Future<void> leaveLobby(Map<String, dynamic> data) async {
    final creatorId = data['creatorId'].toString();
    final isHost = creatorId == playerId;

    if (isHost) {
      await _firebase.deleteLobby(lobbyId);
    } else {
      await _firebase.leaveLobby(lobbyId, playerId);
    }
  }

  Future<void> startGame(List<String> ids) async {
    final players = ids
        .map((id) => GamePlayer(username: 'Wizard_$id', role: 'unknown'))
        .toList();
    await _firebase.startGame(lobbyId, players);
  }

  Future<void> resetLobby() async {
    await _firebase.resetLobby(lobbyId);
  }
}
