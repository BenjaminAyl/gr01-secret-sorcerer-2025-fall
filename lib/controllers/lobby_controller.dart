import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'package:secret_sorcerer/utils/dev_auth.dart';

class LobbyController {
  final FirebaseController _firebase = FirebaseController();
  late int playerId;
  late int lobbyId;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> lobbyStream;

  /// Initializes the lobby controller for an existing lobby
  Future<void> init(String code) async {
    lobbyId = int.parse(code);
    playerId = await devSignInAndGetPlayerId();
    lobbyStream = _firebase.watchLobby(lobbyId);
  }

  /// Deletes the lobby if host, removes self otherwise
  Future<void> leaveLobby(Map<String, dynamic> data) async {
    final creatorId = (data['creatorId'] as num).toInt();
    final isHost = creatorId == playerId;

    if (isHost) {
      await _firebase.deleteLobby(lobbyId);
    } else {
      await _firebase.leaveLobby(lobbyId, playerId);
    }
  }

  /// Starts the game
  Future<void> startGame(List<int> ids) async {
    final players = ids
        .map((id) => GamePlayer(username: 'Wizard_$id', role: 'unknown'))
        .toList();
    await _firebase.startGame(lobbyId, players);
  }
}
