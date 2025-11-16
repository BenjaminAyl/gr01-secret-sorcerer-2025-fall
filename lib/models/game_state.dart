import 'package:secret_sorcerer/models/game_player.dart';

class GameState {
  //ALL PHASES NAMES FOR REFERENCE
  // waiting  : pre-game
  // start    : just started / selecting spellcaster
  // hm_discard: HM drew 3; HM must discard 1
  // sc_choose: SC received 2; SC must pick 1 to enact
  // resolving: applying effects, rotating HM, etc.
  late String phase = 'waiting';

  late int charms = 0; 
  late int curses = 0; 

  
  late String headmaster = '';
  late String? spellcaster = '';

  late List<GamePlayer> players = [];

  late List<String> discard = [];     // discarded cards
  late List<String> pendingCards = []; // current hand
  late String? pendingOwner = null;    // 'headmaster' or 'spellcaster'

  late List<String> deck = [];

  late int headmasterIdx = 0;
  String? lastHeadmaster = '';
  String? lastSpellcaster = '';
  String? spellcasterNominee;      
  late String? executivePower = null;
  late bool executiveActive = false; 
  late String? executiveTarget = null; 
  late List<String> pendingExecutiveCards = []; 


  late Map<String, String> votes = {};


  GameState(List<GamePlayer> _players) {
    phase = 'start';
    charms = 0;
    curses = 0;
    players = _players;
    deck = (List.filled(10, 'curse') + List.filled(7, 'charm'))..shuffle();
    discard = [];
    pendingCards = [];
    pendingOwner = null;
    headmasterIdx = 0;
    headmaster = players[headmasterIdx].username;
    votes = {};
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'charms': charms,
      'curses': curses,
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
      'executivePower': executivePower,
      'executiveActive': executiveActive,
      'executiveTarget': executiveTarget,
      'pendingExecutiveCards': pendingExecutiveCards,

    };
  }
}
