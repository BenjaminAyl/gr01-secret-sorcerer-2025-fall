import 'package:secret_sorcerer/models/game_player.dart';

class GameState {
  //ALL PHASES NAMES FOR REFERENCE
  // waiting       : pre-game
  // start         : selecting spellcaster
  // hm_discard    : HM drew 3; must discard 1
  // sc_choose     : SC got 2; must enact 1
  // resolving     : apply effects and rotate HM
  // executive_*   : all executive powers

  late String phase = 'waiting';

  late int charms = 0; 
  late int curses = 0; 
  late int failedTurns = 0;

  late String headmaster = '';
  late String? spellcaster = '';

  late List<GamePlayer> players = [];

  late List<String> discard = [];
  late List<String> pendingCards = [];
  late String? pendingOwner = null;

  late List<String> deck = [];

  late int headmasterIdx = 0;

  String? lastHeadmaster = '';
  String? lastSpellcaster = '';
  String? spellcasterNominee;
  late String? executivePower = null;
  late bool executiveActive = false;
  late String? executiveTarget = null;
  late List<String> pendingExecutiveCards = [];
  late Map<String, bool> dead = {};
  late String? overrideHM = null;
  late Map<String, bool> votes = {};

  GameState(List<GamePlayer> _players) {
    phase = 'start';
    charms = 0;
    curses = 0;
    failedTurns = 0;
    players = _players;

    // 10 curse + 7 charm deck (randomized)
    deck = (List.filled(10, 'curse') + List.filled(7, 'charm'))..shuffle();

    discard = [];
    pendingCards = [];
    pendingOwner = null;

    headmasterIdx = 0;
    headmaster = players[headmasterIdx].username;

    votes = {};

    //initialize dead map, ALL PLAYERS ALIVE
    dead = {
      for (var p in players) p.username: false,
    };

    // No override HM initially
    overrideHM = null;
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'charms': charms,
      'curses': curses,
      'failedTurns': failedTurns,
      'headmaster': headmaster,
      'spellcaster': spellcaster,
      'spellcasterNominee': spellcasterNominee,
      'players': players.map((p) => p.toMap()).toList(),
      'deck': deck,
      'discard': discard,
      'pendingCards': pendingCards,
      'pendingOwner': pendingOwner,
      'headmasterIdx': headmasterIdx,
      'lastHeadmaster': lastHeadmaster,
      'lastSpellcaster': lastSpellcaster,
      'votes': votes,

      // Executive powers
      'executivePower': executivePower,
      'executiveActive': executiveActive,
      'executiveTarget': executiveTarget,
      'pendingExecutiveCards': pendingExecutiveCards,

      // Dead players
      'dead': dead,
      'overrideHM': overrideHM,
    };
  }
}
