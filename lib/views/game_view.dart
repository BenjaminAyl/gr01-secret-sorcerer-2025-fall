import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
  Map<String, String> nicknameCache = {}; // uid → nickname
  int headmasterIndex = 0;
  int? spellcasterIndex;
  int charms = 0;
  int curses = 0;
  int countdown = 0;

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
  }

  // --- BOARD SETUP ---
  Future<void> _loadBoard() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = AppColors.primaryBrand,
      priority: -10,
    ));

    final boardSprite = await loadSprite('game-assets/board/baseboard.png');
    final boardSize = min(size.x, size.y) * 0.7; // smaller and centered better
    baseBoard = SpriteComponent(
      sprite: boardSprite,
      size: Vector2.all(boardSize),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2.2), // slightly up
      priority: -3,
    );
    add(baseBoard!);
  }

  // --- STATE LISTENERS ---
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

  // --- SYNC AND PLAYER SETUP ---
  Future<void> _syncFromData(Map<String, dynamic> data) async {
    final rawPlayers = (data['players'] as List?) ?? [];
    players = rawPlayers
        .map((p) => GamePlayer(
              username: p['username'] ?? '', // actually UID
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

    charms = (data['charms'] ?? 0) as int;
    curses = (data['curses'] ?? 0) as int;

    // Fetch user nicknames
    await _resolveNicknames();

    if (!_initialized && players.isNotEmpty) {
      _initialized = true;
      _placeHats();
    }

    _updateHighlights();
    _updateRings();
  }

  // --- GET NICKNAMES FROM FIRESTORE USERS COLLECTION ---
  Future<void> _resolveNicknames() async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    for (final p in players) {
      final uid = p.username;
      if (nicknameCache.containsKey(uid)) continue;

      try {
        final doc = await usersRef.doc(uid).get();
        if (doc.exists) {
          nicknameCache[uid] = doc.data()?['Nickname'] ?? 'Wizard';
        } else {
          nicknameCache[uid] = 'Wizard';
        }
      } catch (_) {
        nicknameCache[uid] = 'Wizard';
      }
    }
  }

  // --- DRAW PLAYER HATS ---
  void _placeHats() {
    for (final h in hats) {
      h.removeFromParent();
    }
    hats.clear();

    if (players.isEmpty) return;

    final n = players.length;
    final baseRadius = min(size.x, size.y) * 0.45;
    final radius =
        n <= 4 ? baseRadius * 1.1 : n <= 6 ? baseRadius * 1.3 : baseRadius * 1.4;

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
        ..scale = Vector2.all(0.8);
      add(hat);
      hats.add(hat);
    }
  }

  // --- HAT TAP HANDLER ---
  Future<void> _onHatTapped(int index) async {
    if (!isHeadmasterClient) return;
    if (index == headmasterIndex) return;
    await _firebase.updateSpellcaster(lobbyId, players[index].username);
  }

  // --- GAME ACTIONS ---
  void updateCountdown(int seconds) => countdown = seconds;

  Future<void> castSpell(bool isCharm) async {
    if (!isSpellcasterClient) return;
    if (isCharm) {
      await _firebase.incrementCharm(lobbyId);
      _flashRing(color: Colors.tealAccent);
    } else {
      await _firebase.incrementCurse(lobbyId);
      _flashRing(color: Colors.redAccent);
    }
  }

  // ✅ FIXED HEADMASTER ROTATION
  Future<void> endTurn() async {
    if (!isHeadmasterClient || players.isEmpty) return;

    final nextIdx = (headmasterIndex + 1) % players.length;
    final nextUid = players[nextIdx].username;

    await FirebaseFirestore.instance.collection('states').doc(lobbyId).update({
      'headmasterIdx': nextIdx,
      'headmaster': nextUid,
      'spellcaster': null, // clear spellcaster between rounds
    });
  }

  // --- VISUAL UPDATES ---
  void _updateHighlights() {
    for (final hat in hats) {
      final isHM = hat.index == headmasterIndex;
      final isSC = spellcasterIndex != null && hat.index == spellcasterIndex;
      if (isHM) {
        hat.setColorTint(Colors.white);
      } else if (isSC) {
        hat.setColorTint(Colors.purpleAccent);
      } else {
        hat.setColorTint(Colors.white);
      }
    }
  }

  Future<void> _updateRings() async {
    charmsRing?.removeFromParent();
    cursesRing?.removeFromParent();

    final ringSize = min(size.x, size.y) * 0.7;
    final center = Vector2(size.x / 2, size.y / 2.2);

    if (charms > 0) {
      final charmSprite =
          await loadSprite('game-assets/board/charm${charms.clamp(1, 5)}.png');
      charmsRing = SpriteComponent(
        sprite: charmSprite,
        size: Vector2.all(ringSize),
        anchor: Anchor.center,
        position: center,
        priority: -2,
      );
      add(charmsRing!);
    }

    if (curses > 0) {
      final curseSprite =
          await loadSprite('game-assets/board/curse${curses.clamp(1, 3)}.png');
      cursesRing = SpriteComponent(
        sprite: curseSprite,
        size: Vector2.all(ringSize),
        anchor: Anchor.center,
        position: center,
        priority: -1,
      );
      add(cursesRing!);
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
    Future.delayed(const Duration(milliseconds: 500), () => ring.removeFromParent());
  }
}

// --- PLAYER HAT CLASS ---
class PlayerHatComponent extends SpriteComponent with TapCallbacks {
  final int index;
  final String nickname;
  final void Function(int) onTap;
  late TextComponent label;

  PlayerHatComponent(this.index, this.nickname, this.onTap)
      : super(size: Vector2.all(60), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('wizard_hat.png');

    label = TextComponent(
      text: nickname,
      textRenderer: TextPaint(
        style: TextStyles.bodySmall.copyWith(
          fontSize: 13,
          color: AppColors.textAccent,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 6),
    );
    add(label);
  }

  void setColorTint(Color color) {
    paint = Paint()..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
  }

  @override
  void onTapDown(TapDownEvent event) => onTap(index);
}
