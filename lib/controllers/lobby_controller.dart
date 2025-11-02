import 'dart:math';

class LobbyController {
  late String lobbyCode;
  late List<String> fakePlayers;

  LobbyController() {
    lobbyCode = _generateLobbyCode();
    fakePlayers = ['Wizard_1', 'Wizard_2', 'Wizard_3', 'Wizard_4'];
  }

  String _generateLobbyCode() {
    final rand = Random();
    return (rand.nextInt(9000) + 1000).toString();
  }
}
