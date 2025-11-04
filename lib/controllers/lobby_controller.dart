import 'dart:math';

class LobbyController {
  late String lobbyCode;
  late List<String> fakePlayers;

  LobbyController() {
    lobbyCode = _generateLobbyCode();
    fakePlayers = _generatePlayers();
  }

  String _generateLobbyCode() {
    final rand = Random();
    return (rand.nextInt(9000) + 1000).toString(); // 4-digit code
  }

  List<String> _generatePlayers() {
    final rand = Random();
    final count = rand.nextInt(10) + 1; // between 1–10 players
    return List.generate(count, (i) => 'Wizard_${i + 1}');
  }
}
