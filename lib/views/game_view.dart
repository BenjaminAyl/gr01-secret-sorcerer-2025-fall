import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/game_player.dart';

class WizardGameView extends FlameGame with TapCallbacks {
  final String lobbyId;
  final String myUid;
  final FirebaseController _firebase = FirebaseController();

  List<GamePlayer> players = [];
  Map<String, String> nicknameCache = {}; // uid to nickname
  int headmasterIndex = 0;
  int? spellcasterIndex;
  int? nomineeIndex;  // nominee being voted on
  int charms = 0;
  int curses = 0;
  int countdown = 0;
  String? executivePower;
  bool executiveActive = false;
  String? executiveTarget;
  List<String> pendingExecutiveCards = [];


  // live phase and pending cards for UI
  String phase = 'start';
  List<String> pendingCards = [];

  // NEW: votes map <uid, bool>
  Map<String, bool> votes = {};

  SpriteComponent? baseBoard;
  SpriteComponent? charmsRing;
  SpriteComponent? cursesRing;
  final List<PlayerHatComponent> hats = [];

  bool _initialized = false;

  WizardGameView({required this.lobbyId, required this.myUid});

  bool get isHeadmasterClient =>
      players.isNotEmpty && players[headmasterIndex].username == myUid;

  bool get isSpellcasterClient =>
      spellcasterIndex != null &&
      players[spellcasterIndex!].username == myUid;

  // Voting helpers (read-only)
  bool get iVoted => votes.containsKey(myUid);
  int get eligibleVoters => (players.isEmpty) ? 0 : (players.length - 1); // exclude HM
  int get votedCount => votes.length;
  bool get allVotesIn => votedCount >= (eligibleVoters.clamp(0, 99));

  @override
  Future<void> onLoad() async {
    await _loadBoard();
    _subscribeGameState();
    overlays.add('ControlsOverlay');
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    camera.viewfinder.visibleGameSize = canvasSize;
    camera.viewfinder.position = canvasSize / 2;
    _layoutHats();
  }

  Future<void> _loadBoard() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = AppColors.primaryBrand,
      priority: -10,
    ));

    final boardSprite = await loadSprite('game-assets/board/baseboard.png');
    final boardSize = min(size.x, size.y) * 0.6;
    baseBoard = SpriteComponent(
      sprite: boardSprite,
      size: Vector2.all(boardSize),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2.2),
      priority: -3,
    );
    add(baseBoard!);
  }

  void _subscribeGameState() {
    FirebaseFirestore.instance
        .collection('states')
        .doc(lobbyId)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      await _syncFromData(data);
    });
  }

  Future<void> _syncFromData(Map<String, dynamic> data) async {
    final rawPlayers = (data['players'] as List?) ?? [];
    players = rawPlayers
        .map((p) => GamePlayer(
              username: p['username'] ?? '',
              vote: p['vote'],
              role: p['role'] ?? 'unknown',
            ))
        .toList();

    headmasterIndex = (data['headmasterIdx'] ?? 0) as int;

    final spellName = data['spellcaster'];
    if (spellName == null) {
      spellcasterIndex = null;
    } else {
      final idx = players.indexWhere((p) => p.username == spellName);
      spellcasterIndex = idx >= 0 ? idx : null;
    }

    // nominee during voting
    final nomineeName = data['spellcasterNominee'];
    if (nomineeName == null) {
      nomineeIndex = null;
    } else {
      final j = players.indexWhere((p) => p.username == nomineeName);
      nomineeIndex = j >= 0 ? j : null;
    }

    // votes map
    final rawVotes = (data['votes'] as Map?) ?? {};
    votes = rawVotes.map((k, v) {
      final s = v is bool ? v : v.toString().toLowerCase();
      final isYes = (s is bool) ? s : (s == 'yes');
      return MapEntry(k.toString(), isYes);
    });


    charms = (data['charms'] ?? 0) as int;
    curses = (data['curses'] ?? 0) as int;
    phase = (data['phase'] ?? 'start').toString();
    pendingCards = List<String>.from(
        (data['pendingCards'] as List?)?.map((e) => e.toString()) ?? []);
    executivePower = data['executivePower'];
    executiveActive = data['executiveActive'] == true;
    executiveTarget = data['executiveTarget'];
    pendingExecutiveCards =
        List<String>.from(data['pendingExecutiveCards'] ?? []);


    await _resolveNicknames();

    if (!_initialized && players.isNotEmpty) {
      _initialized = true;
      _placeHats();
    }

    _updateHighlights();
    _updateNomineePulse(); // pulse for nominee during voting
    _updateRings();
  }

  Future<void> _resolveNicknames() async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    for (final p in players) {
      final uid = p.username;
      if (nicknameCache.containsKey(uid)) continue;
      try {
        final doc = await usersRef.doc(uid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          nicknameCache[uid] =
              data['nickname'] ?? data['Nickname'] ?? 'Wizard';
        } else {
          nicknameCache[uid] = 'Wizard';
        }
      } catch (_) {
        nicknameCache[uid] = 'Wizard';
      }
    }
  }

  void _layoutHats() {
    if (players.isEmpty || baseBoard == null || hats.length != players.length) return;

    final n = players.length;
    final center = baseBoard!.position;      // board center
    final boardR = baseBoard!.size.x * 0.5;  // board radius (sprite square)

    // Circle radius slightly OUTSIDE the board
    final outerFactor = (n <= 4 ? 1.18 : (n <= 6 ? 1.20 : 1.25));
    final circleR = boardR * outerFactor;

    const start = -pi / 2; // index 0 at top
    for (int i = 0; i < n; i++) {
      final angle = start + (2 * pi * i) / n;
      final dir = Vector2(cos(angle), sin(angle));
      final hat = hats[i];
      final outwardNudge = (hat.size.y * 0.33) + 6;
      final pos = center + dir * (circleR + outwardNudge);

      hat.position = pos;
    }
  }


  void _placeHats() {
    for (final h in hats) {
      h.removeFromParent();
    }
    hats.clear();

    if (players.isEmpty) return;

    final n = players.length;
    final baseRadius = min(size.x, size.y) * 0.45;
    final radius = n <= 4
        ? baseRadius * 1.25
        : (n <= 6 ? baseRadius * 1.35 : baseRadius * 1.45);
    final center = Vector2(size.x / 2, size.y / 2.2);

    for (int i = 0; i < n; i++) {
      final angle = (2 * pi / n) * i - pi / 2;
      final pos = Vector2(
        center.x + radius * cos(angle),
        center.y + radius * sin(angle),
      );

      final uid = players[i].username;
      final nickname = nicknameCache[uid] ?? 'Wizard ${i + 1}';

      final hat = PlayerHatComponent(i, nickname, _onHatTapped)
        ..position = pos
        ..scale = Vector2.all(1.2);
      add(hat);
      hats.add(hat);
      _layoutHats();

    }
  }

Future<void> _onHatTapped(int index) async {
  // Only the Headmaster can investigate
  if (!isHeadmasterClient) return;

  // EXECUTIVE INVESTIGATE MODE
  if (phase == 'executive_investigate') {
    final targetUid = players[index].username;

    // Cannot investigate yourself
    if (targetUid == players[headmasterIndex].username) return;

    await _firebase.investigateSelectTarget(lobbyId, targetUid);
    return;
  }

  // NORMAL nomination
  if (index == headmasterIndex) return;
  await _firebase.nominateSpellcaster(lobbyId, players[index].username);
}


  // Let overlay call this for Yes/No cards
  Future<void> castVote(bool yes) async {
    await _firebase.castVote(lobbyId, myUid, yes);
  }

  void updateCountdown(int seconds) => countdown = seconds;

  // HM discards 1 of 3
  Future<void> headmasterDiscard(int index) async {
    await _firebase.headmasterDiscard(lobbyId, index);
  }

  // SC enacts 1 of 2
  Future<void> spellcasterChoose(int index) async {
    await _firebase.spellcasterChoose(lobbyId, index);
  }

  int? _prevHeadmaster;
  int? _prevSpellcaster;
  int? _prevNominee;

  void _updateHighlights() {
    final changedHM = _prevHeadmaster != headmasterIndex;
    final changedSC = _prevSpellcaster != spellcasterIndex;

    for (final hat in hats) {
      final isHM = hat.index == headmasterIndex;
      final isSC = spellcasterIndex != null && hat.index == spellcasterIndex;

      final wasHM = hat.index == _prevHeadmaster;
      final wasSC = _prevSpellcaster != null && hat.index == _prevSpellcaster;

      if (isHM && changedHM) {
        hat.clearColorEffects();
        hat.add(ColorEffect(
          const Color(0xFFFFFFFF),
          EffectController(duration: 0.6),
          opacityFrom: 0.0,
          opacityTo: 0.7,
        ));
      } else if (isSC && changedSC && phase != 'voting') {
        // Solid purple only when officially elected (not during voting pulse)
        hat.clearColorEffects();
        hat.add(ColorEffect(
          const Color(0xFF8A2BE2),
          EffectController(duration: 0.6),
          opacityFrom: 0.0,
          opacityTo: 0.6,
        ));
      } else if ((wasHM && !isHM) || (wasSC && !isSC)) {
        hat.clearColorEffects();
        hat.add(ColorEffect(
          const Color(0xFFFFFFFF),
          EffectController(duration: 0.6),
          opacityFrom: 0.7,
          opacityTo: 0.0,
        ));
      }
    }

    _prevHeadmaster = headmasterIndex;
    _prevSpellcaster = spellcasterIndex;
  }

  void _updateNomineePulse() {
    // Stop pulsing previous nominee if changed or voting ended
    if (_prevNominee != null &&
        (_prevNominee != nomineeIndex || phase != 'voting')) {
      for (final h in hats) {
        if (h.index == _prevNominee) {
          h.stopPulse();
          break;
        }
      }
    }

    // Start pulsing current nominee during voting (slower + smaller scale)
    if (phase == 'voting' && nomineeIndex != null) {
      for (final h in hats) {
        if (h.index == nomineeIndex) {
          h.startPulse(
            color: const Color(0xFF8A2BE2),
            minOpacity: 0.20,
            maxOpacity: 0.60,
            periodSec: 1.6, // slower pulse
          );
          break;
        }
      }
    }

    _prevNominee = nomineeIndex;
  }

  int _prevCharmLevel = 0;
  int _prevCurseLevel = 0;

  Future<void> _updateRings() async {
    final ringSize = min(size.x, size.y) * 0.6;
    final center = Vector2(size.x / 2, size.y / 2.2);

    if (charms > 0) {
      if (charms != _prevCharmLevel) {
        charmsRing?.removeFromParent();
        final charmSprite =
            await loadSprite('game-assets/board/charm${charms.clamp(1, 5)}.png');

        charmsRing = SpriteComponent(
          sprite: charmSprite,
          size: Vector2.all(ringSize),
          anchor: Anchor.center,
          position: center,
          priority: -2,
        )..opacity = 0.0;

        charmsRing!.add(OpacityEffect.to(1.0, EffectController(duration: 0.8)));
        add(charmsRing!);
        _prevCharmLevel = charms;
      }
    } else {
      charmsRing?.removeFromParent();
      _prevCharmLevel = 0;
    }

    if (curses > 0) {
      if (curses != _prevCurseLevel) {
        cursesRing?.removeFromParent();
        final curseSprite =
            await loadSprite('game-assets/board/curse${curses.clamp(1, 6)}.png');

        cursesRing = SpriteComponent(
          sprite: curseSprite,
          size: Vector2.all(ringSize),
          anchor: Anchor.center,
          position: center,
          priority: -1,
        )..opacity = 0.0;

        cursesRing!.add(OpacityEffect.to(1.0, EffectController(duration: 0.8)));
        add(cursesRing!);
        _prevCurseLevel = curses;
      }
    } else {
      cursesRing?.removeFromParent();
      _prevCurseLevel = 0;
    }
  }

  void _flashRing({required Color color}) {
    final ring = CircleComponent(
      radius: min(size.x, size.y) * 0.4,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withAlpha(200),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2.2),
      priority: 10,
    );
    add(ring);
    Future.delayed(const Duration(milliseconds: 500),
        () => ring.removeFromParent());
  }
}

//PLAYER HAT CLASS
class PlayerHatComponent extends SpriteComponent with TapCallbacks {
  final int index;
  final String nickname;
  final void Function(int) onTap;
  late TextComponent label;

  Effect? _pulseColor;


  PlayerHatComponent(this.index, this.nickname, this.onTap)
      : super(size: Vector2.all(45), anchor: Anchor.center);
  
  static const double _labelGap = 2;
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('wizard_hat.png');
    label = TextComponent(
      text: nickname,
      textRenderer: TextPaint(
        style: TextStyles.bodySmall.copyWith(
          fontSize: 14,
          color: const Color.fromARGB(121, 255, 255, 255),
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 12),
      priority: 5,
    );
    add(label);
    _relayoutLabel(); 
  }

  void setColorTint(Color color) {
    paint = Paint()..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
  }

  @override
  void onTapDown(TapDownEvent event) => onTap(index);

  void removeEffect<T extends Effect>() {
    children.whereType<T>().toList().forEach((effect) {
      effect.removeFromParent();
    });
  }

  void clearColorEffects() {
    children.whereType<ColorEffect>().toList().forEach((e) => e.removeFromParent());
  }
   @override
  set size(Vector2 v) {
    super.size = v;
    if (isMounted) _relayoutLabel();
  }

  void startPulse({
    required Color color,
    double minOpacity = 0.2,
    double maxOpacity = 0.6,
    double periodSec = 1.6,
  }) {
    stopPulse();
    clearColorEffects();

    // Color-only pulsing via a repeating ColorEffect
    _pulseColor = ColorEffect(
      color,
      EffectController(
        duration: periodSec / 2,
        reverseDuration: periodSec / 2,
        alternate: true,
        infinite: true,
      ),
      opacityFrom: minOpacity,
      opacityTo: maxOpacity,
    );
    add(_pulseColor!);
  }

  void stopPulse() {
    _pulseColor?.removeFromParent();
    _pulseColor = null;
    clearColorEffects();
  }

   void _relayoutLabel() {
    // place the label just BELOW the hat, centered
    label.position = Vector2(size.x / 2, size.y + _labelGap);
  }

  @override
  void onMount() {
    super.onMount();
    _relayoutLabel();
  }
}
