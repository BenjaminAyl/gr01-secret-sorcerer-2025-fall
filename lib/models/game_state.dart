import 'package:secret_sorcerer/models/game_player.dart';

class GameState {

  late String phase = 'waiting';

  late int charms = 0;

  late int curses = 0;

  late String headmaster = '';

  late String? spellcaster = '';

  late List<GamePlayer> players = [];

  late List<String> deck = [];

  late int headmasterIdx = 0;

  String? lastHeadmaster = '';

  String? lastSpellcaster ='';

  GameState(List<GamePlayer> _players) {
    phase = 'start';
    charms = 0;
    curses = 0;
    players = _players;
    deck = (List.filled(10, 'curse') + List.filled(7, 'charm'))..shuffle();
    headmasterIdx = 0;
    headmaster = players[headmasterIdx].username;
  }

    Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'charms': charms,
      'curses': curses,
      'headmaster': headmaster,
      'spellcaster': spellcaster,
      'players': players.map((p) => p.toMap()).toList(),
      'deck': deck,
      'headmasterIdx': headmasterIdx,
      'lastHeadmaster': lastHeadmaster,
      'lastSpellcaster': lastSpellcaster,
    };
  }
}