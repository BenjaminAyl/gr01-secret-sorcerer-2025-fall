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
import 'package:secret_sorcerer/utils/audio_helper.dart';

class WizardGameView extends FlameGame with TapCallbacks {
  final String lobbyId;
  final String myUid;
  final FirebaseController _firebase = FirebaseController();
  int failedTurns = 0;
  TextComponent? turnCounterText;
  List<String> deck = [];
  List<String> discard = [];


  List<GamePlayer> players = [];
  Set<String> _prevDeadUids = {};
  Map<String, String> nicknameCache = {}; // uid to nickname
  int headmasterIndex = 0;
  int? spellcasterIndex;
  int? nomineeIndex; // nominee being voted on
  int charms = 0;
  int curses = 0;
  int countdown = 0;

  String? executivePower;
  bool executiveActive = false;
  String? executiveTarget;
  List<String> pendingExecutiveCards = [];
  Map<String, bool> dead = {};
  String? lastHeadmaster;
  String? lastSpellcaster;

  // live phase and pending cards for UI
  String phase = 'start';
  List<String> pendingCards = [];

  // votes map <uid, bool>
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
  int get _alivePlayerCount =>
      players.where((p) => !(dead[p.username] ?? false)).length;

  int get eligibleVoters =>
      _alivePlayerCount > 0 ? (_alivePlayerCount - 1) : 0; // exclude HM

  bool get iVoted => votes.containsKey(myUid);
  int get votedCount => votes.length;
  bool get allVotesIn => votedCount >= eligibleVoters;

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
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = AppColors.primaryBrand,
        priority: -10,
      ),
    );

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
        .snapshots().listen((snap) async {
        if (!snap.exists) return;
        final data = snap.data() ?? {};

        await _syncFromData(data);
        Future.microtask(() {
          if (phase == 'game_over') return;

          if (overlays.isActive('ControlsOverlay')) {
            overlays.remove('ControlsOverlay');
            overlays.add('ControlsOverlay');
          }
        });

      });

  }

  Future<void> _syncFromData(Map<String, dynamic> data) async {

    

    final rawPlayers = (data['players'] as List?) ?? [];
    players = rawPlayers
        .map(
          (p) => GamePlayer(
            username: p['username'] ?? '',
            vote: p['vote'],
            role: p['role'] ?? 'unknown',
          ),
        )
        .toList();

    // dead map
    final rawDead = Map<String, dynamic>.from(data['dead'] ?? {});
    dead = rawDead.map((key, value) => MapEntry(key.toString(), value == true));

    headmasterIndex = (data['headmasterIdx'] ?? 0) as int;

    // spellcaster index
    final spellName = data['spellcaster'];
    if (spellName == null) {
      spellcasterIndex = null;
    } else {
      final idx = players.indexWhere((p) => p.username == spellName);
      spellcasterIndex = idx >= 0 ? idx : null;
    }

    // nominee index
    final nomineeName = data['spellcasterNominee'];
    if (nomineeName == null) {
      nomineeIndex = null;
    } else {
      final j = players.indexWhere((p) => p.username == nomineeName);
      nomineeIndex = j >= 0 ? j : null;
    }

    // votes
    final rawVotes = (data['votes'] as Map?) ?? {};
    votes = rawVotes.map((k, v) {
      if (v is bool) return MapEntry(k.toString(), v);
      final s = v.toString().toLowerCase();
      return MapEntry(k.toString(), s == 'yes');
    });

    charms = (data['charms'] ?? 0) as int;
    curses = (data['curses'] ?? 0) as int;
    failedTurns = (data['failedTurns'] ?? 0) as int;
    phase = (data['phase'] ?? 'start').toString();
    pendingCards = List<String>.from(
        (data['pendingCards'] as List?)?.map((e) => e.toString()) ?? []);
    deck = List<String>.from(
      (data['deck'] as List?)?.map((e) => e.toString()) ?? [],
    );
    discard = List<String>.from(
      (data['discard'] as List?)?.map((e) => e.toString()) ?? [],
    );
    

    executivePower = data['executivePower'];
    executiveActive = data['executiveActive'] == true;
    executiveTarget = data['executiveTarget'];
    pendingExecutiveCards =
        List<String>.from(data['pendingExecutiveCards'] ?? []);

    lastHeadmaster = data['lastHeadmaster']?.toString();
    lastSpellcaster = data['lastSpellcaster']?.toString();

    await _resolveNicknames();

    if (!_initialized && players.isNotEmpty) {
      _initialized = true;
      _placeHats();
    }

    // Run death animations for newly dead
    final newlyDead = dead.entries
        .where((e) => e.value == true && !_prevDeadUids.contains(e.key))
        .map((e) => e.key)
        .toSet();

    if (newlyDead.isNotEmpty && hats.length == players.length) {
      for (int i = 0; i < players.length; i++) {
        final uid = players[i].username;
        if (newlyDead.contains(uid)) {
          final isArch = players[i].role == 'archwarlock';
          hats[i].runDeathSequence(isArch: isArch);
        } else if (dead[uid] == true) {
          hats[i].dead = true;
          hats[i].paint = Paint()
            ..colorFilter = const ColorFilter.mode(
              Colors.black,
              BlendMode.modulate,
            );
        }
      }
    }

    _prevDeadUids = dead.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toSet();

    _updateHighlights();
    _updateNomineePulse();
    _updateRings();
    _updateDeadHats();
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
    if (players.isEmpty || baseBoard == null || hats.length != players.length) {
      return;
    }

    final n = players.length;
    final center = baseBoard!.position;
    final boardR = baseBoard!.size.x * 0.5;

    final outerFactor = (n <= 4 ? 1.18 : (n <= 6 ? 1.20 : 1.25));
    final circleR = boardR * outerFactor;

    const start = -pi / 2;

    const double topOffset = 10.0; // extra spacing for top hats

    for (int i = 0; i < n; i++) {
      final angle = start + (2 * pi * i) / n;
      final dir = Vector2(cos(angle), sin(angle));
      final hat = hats[i];

      // outward nudge based on hat size
      final outwardNudge = (hat.size.y * 0.33) + 6;

      // only apply extra spacing to hats ABOVE the board (sin(angle) > 0 => below, < 0 => above)
      double extra = 0;
      if (dir.y < 0) {
        extra = topOffset; 
      }

      hat.position = center + dir * (circleR + outwardNudge + extra);
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
    final radius =
        n <= 4 ? baseRadius * 1.25 : (n <= 6 ? baseRadius * 1.35 : baseRadius * 1.45);
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
    }

    _layoutHats();
    _updateDeadHats(); // in case some were already dead
  }

  //apply dead tint to hats
  void _updateDeadHats() {
    if (hats.length != players.length) return;
    for (final hat in hats) {
      if (hat.index < 0 || hat.index >= players.length) continue;
      final uid = players[hat.index].username;
      final isDead = dead[uid] == true;
      hat.setDead(isDead);
    }
  }

  Future<void> _onHatTapped(int index) async {
    if (index < 0 || index >= players.length) return;
    final targetUid = players[index].username;

    // Dead players are untouchable
    if (dead[targetUid] == true) return;

    // Only HM interacts in special phases
    final isHM = isHeadmasterClient;
    final hmUid = players[headmasterIndex].username;

    // EXECUTIVE: investigate
    if (phase == 'executive_investigate') {
      if (!isHM) return;
      if (targetUid == hmUid) return; // can't inspect self
      await _firebase.investigateSelectTarget(lobbyId, targetUid);
      return;
    }

    // EXECUTIVE: choose next headmaster
    if (phase == 'executive_choose_hm') {
      if (!isHM) return;
      if (targetUid == hmUid) return; // no choosing yourself
      await _firebase.chooseNextHeadmaster(lobbyId, targetUid);
      return;
    }

    // EXECUTIVE: kill
    if (phase == 'executive_kill') {
      if (!isHM) return;
      if (targetUid == hmUid) return; // can't suicide
      await _firebase.selectKillTarget(lobbyId, targetUid);
      return;
    }
    if (phase == 'start') {
      if (!isHM) return;

      //cant pick yourself
      if (targetUid == hmUid) return;

      //cantt pick last HM or last SC
      if (lastHeadmaster != null && targetUid == lastHeadmaster) return;
      if (lastSpellcaster != null && targetUid == lastSpellcaster) return;

      await _firebase.nominateSpellcaster(lobbyId, targetUid);
    }

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

      final uid = (hat.index >= 0 && hat.index < players.length)
          ? players[hat.index].username
          : '';

      // Dead = never highlight
      if (dead[uid] == true) {
        hat.clearColorEffects();
        continue;
      }

      // BLOCKED players (last HM or last SC)
      final isBlocked =
          (lastHeadmaster != null && uid == lastHeadmaster) ||
          (lastSpellcaster != null && uid == lastSpellcaster);

      if (isBlocked && !isHM) {
        hat.paint = Paint()
          ..colorFilter = const ColorFilter.mode(
            Colors.redAccent,
            BlendMode.modulate,
          );
        hat.clearColorEffects();
        continue;
      }

      //Only reset paint if not HM
      if (!isHM) {
        hat.paint = Paint();
      }
      if (isHM) {
        if (!hat.hasWhiteHMGlow) {
          hat.clearColorEffects();
          hat.add(
            ColorEffect(
              const Color(0xFFFFFFFF),
              EffectController(duration: 0.6),
              opacityFrom: 0.0,
              opacityTo: 0.7,
            ),
          );
          hat.hasWhiteHMGlow = true;
        }
        continue; // nothing overrides HM glow
      }
      if (isSC && changedSC && phase != 'voting') {
        hat.clearColorEffects();
        hat.add(
          ColorEffect(
            const Color(0xFF8A2BE2),
            EffectController(duration: 0.6),
            opacityFrom: 0.0,
            opacityTo: 0.6,
          ),
        );
        continue;
      }

      // Fade-out old HM/SC
      if ((wasHM && !isHM) || (wasSC && !isSC)) {
        hat.clearColorEffects();
        hat.add(
          ColorEffect(
            const Color(0xFFFFFFFF),
            EffectController(duration: 0.6),
            opacityFrom: 0.7,
            opacityTo: 0.0,
          ),
        );
      }
    }

    _prevHeadmaster = headmasterIndex;
    _prevSpellcaster = spellcasterIndex;
  }



  void _updateNomineePulse() {
    if (_prevNominee != null &&
        (_prevNominee != nomineeIndex || phase != 'voting')) {
      for (final h in hats) {
        if (h.index == _prevNominee) {
          h.stopPulse();
          break;
        }
      }
    }

    if (phase == 'voting' && nomineeIndex != null) {
      for (final h in hats) {
        if (h.index == nomineeIndex) {
          // Don’t pulse dead
          final uid = players[h.index].username;
          if (dead[uid] == true) {
            h.stopPulse();
            break;
          }
          h.startPulse(
            color: const Color(0xFF8A2BE2),
            minOpacity: 0.20,
            maxOpacity: 0.60,
            periodSec: 1.6,
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
        AudioHelper.playSFX("charmCast.wav");

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

        charmsRing!
            .add(OpacityEffect.to(1.0, EffectController(duration: 0.8)));
        add(charmsRing!);
        _prevCharmLevel = charms;
      }
    } else {
      charmsRing?.removeFromParent();
      _prevCharmLevel = 0;
    }

    if (curses > 0) {
      if (curses != _prevCurseLevel) {
        
        AudioHelper.playSFX("curseCast.wav");

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

        cursesRing!
            .add(OpacityEffect.to(1.0, EffectController(duration: 0.8)));
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
    Future.delayed(
      const Duration(milliseconds: 500),
      () => ring.removeFromParent(),
    );
  }
}

// PLAYER HAT CLASS
class PlayerHatComponent extends SpriteComponent with TapCallbacks {
  final int index;
  final String nickname;
  final void Function(int) onTap;
  late TextComponent label;

  Effect? _pulseColor;
  bool dead = false;
  bool hasWhiteHMGlow = false;


  PlayerHatComponent(this.index, this.nickname, this.onTap)
      : super(size: Vector2.all(45), anchor: Anchor.center);

  static const double _labelGap = 0.5;

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
  void setBlockedRed() {
  paint = Paint()
    ..colorFilter = const ColorFilter.mode(
      Colors.redAccent,
      BlendMode.modulate,
    );
  }

  //Block taps if dead
  @override
  void onTapDown(TapDownEvent event) {
    if (dead) return;
    onTap(index);
  }

  void removeEffect<T extends Effect>() {
    children.whereType<T>().toList().forEach((effect) {
      effect.removeFromParent();
    });
  }

  void clearColorEffects() {
    hasWhiteHMGlow = false; 
    children
        .whereType<ColorEffect>()
        .toList()
        .forEach((e) => e.removeFromParent());
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
    label.position = Vector2(size.x / 2, size.y + _labelGap);
  }

  @override
  void onMount() {
    super.onMount();
    _relayoutLabel();
  }

  //mark dead & tint hat black
  void setDead(bool value) {
    if (dead == value) return;
    dead = value;

    if (dead) {
      stopPulse();
      clearColorEffects();
      paint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Colors.black,
          BlendMode.srcATop,
        );
    } else {
      paint = Paint(); // reset to normal sprite
    }
  }

    Future<void> runDeathSequence({required bool isArch}) async {
    dead = true;
    stopPulse();
    clearColorEffects();

    // Big flash + shake
    add(ColorEffect(
      isArch ? Colors.redAccent : Colors.deepPurple,
      EffectController(
        duration: 0.15,
        reverseDuration: 0.15,
        alternate: true,
        repeatCount: 4,
      ),
      opacityFrom: 0.0,
      opacityTo: 0.9,
    ));

    add(ScaleEffect.to(
      size * 1.4,
      EffectController(
        duration: 0.35,
        reverseDuration: 0.25,
      ),
    ));

    await Future.delayed(const Duration(milliseconds: 700));

    // Lock in: black hat, ghosted name
    paint = Paint()
      ..colorFilter = const ColorFilter.mode(
        Colors.black,
        BlendMode.modulate,
      );

    label.textRenderer = TextPaint(
      style: TextStyles.bodySmall.copyWith(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
    );
  }

}
