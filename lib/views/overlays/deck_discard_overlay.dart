import 'dart:math';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';


class DeckDiscardOverlay extends StatefulWidget {
  final WizardGameView game;

  const DeckDiscardOverlay({super.key, required this.game});

  @override
  State<DeckDiscardOverlay> createState() => _DeckDiscardOverlayState();
}

class _DeckDiscardOverlayState extends State<DeckDiscardOverlay>
    with TickerProviderStateMixin {
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _discardKey = GlobalKey();

  Offset? _deckCenter;
  Offset? _discardCenter;

  int _prevDeck = -1;
  int _prevDiscard = -1;
  int _prevCharms = -1;
  int _prevCurses = -1;
  String _prevPhase = '';

  final List<_FlyingSigil> _sigils = [];

  static const List<String> _runes = [
    "ᛝ", "ᛞ", "ᚨ", "ᛉ", "ᛟ", "ᚾ", "✦", "✧", "✶"
  ];

  @override
  void initState() {
    super.initState();
    // init prev values from current game
    final g = widget.game;
    _prevDeck = g.deck.length;
    _prevDiscard = g.discard.length;
    _prevCharms = g.charms;
    _prevCurses = g.curses;
    _prevPhase = g.phase;

    // compute centers after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCenters());
  }

  @override
  void didUpdateWidget(covariant DeckDiscardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureCenters();
      _handleStateChange();
    });
  }

  void _measureCenters() {
    final deckBox = _deckKey.currentContext?.findRenderObject() as RenderBox?;
    final discardBox =
        _discardKey.currentContext?.findRenderObject() as RenderBox?;

    if (deckBox != null) {
      final pos = deckBox.localToGlobal(Offset.zero);
      _deckCenter = pos + deckBox.size.center(Offset.zero);
    }

    if (discardBox != null) {
      final pos = discardBox.localToGlobal(Offset.zero);
      _discardCenter = pos + discardBox.size.center(Offset.zero);
    }
  }

  void _handleStateChange() {
    final g = widget.game;

    final newDeck = g.deck.length;
    final newDiscard = g.discard.length;
    final newCharms = g.charms;
    final newCurses = g.curses;
    final newPhase = g.phase;

    if (_deckCenter == null || _discardCenter == null) {
      _prevDeck = newDeck;
      _prevDiscard = newDiscard;
      _prevCharms = newCharms;
      _prevCurses = newCurses;
      _prevPhase = newPhase;
      return;
    }

    final deckDelta = newDeck - _prevDeck;
    final discardDelta = newDiscard - _prevDiscard;
    final charmsDelta = newCharms - _prevCharms;
    final cursesDelta = newCurses - _prevCurses;

    final enactedThisTick = (charmsDelta + cursesDelta) > 0;
    if (_prevPhase == 'sc_choose' &&
        newPhase != 'sc_choose' &&
        enactedThisTick) {
      _spawnDeckToDiscardSigils(
        count: 1,
        color: Colors.redAccent,
      );
    } else {
      if (discardDelta > 0) {
        _spawnDeckToDiscardSigils(
          count: discardDelta,
          color: Colors.redAccent,
        );
      }
    }
    final wasLowDeck = _prevDeck >= 0 && _prevDeck < 3;
    final discardShrank = newDiscard < _prevDiscard;
    final deckGrew = newDeck > _prevDeck;

    if (wasLowDeck && discardShrank && deckGrew) {
      final toSendBack = max(_prevDiscard, 0);
      if (toSendBack > 0) {
        _spawnDiscardToDeckSigils(
          count: toSendBack,
          color: Colors.lightBlueAccent,
        );
      }
    }

    _prevDeck = newDeck;
    _prevDiscard = newDiscard;
    _prevCharms = newCharms;
    _prevCurses = newCurses;
    _prevPhase = newPhase;
  }

  void _spawnDeckToDiscardSigils({
    required int count,
    required Color color,
  }) {
    AudioHelper.playSFX("drawDiscard.wav");
    for (int i = 0; i < count; i++) {
      final rune = _runes[Random().nextInt(_runes.length)];
      final start = _deckCenter!;
      final end = _discardCenter!;

      final sigil = _FlyingSigil(
        vsync: this,
        rune: rune,
        start: start,
        end: end,
        color: color,
        durationMs: 900 + Random().nextInt(300),
        scatterPx: 18.0,
        onDone: _removeSigil,
      );

      setState(() => _sigils.add(sigil));
      sigil.controller.forward();
    }
  }

  void _spawnDiscardToDeckSigils({
    required int count,
    required Color color,
  }) {
    AudioHelper.playSFX("drawDiscard.wav");
    for (int i = 0; i < count; i++) {
      final rune = _runes[Random().nextInt(_runes.length)];
      final start = _discardCenter!;
      final end = _deckCenter!;

      final sigil = _FlyingSigil(
        vsync: this,
        rune: rune,
        start: start,
        end: end,
        color: color,
        durationMs: 1000 + Random().nextInt(400),
        scatterPx: 22.0,
        onDone: _removeSigil,
      );

      setState(() => _sigils.add(sigil));
      sigil.controller.forward();
    }
  }

  void _removeSigil(_FlyingSigil s) {
    if (!mounted) return;
    setState(() => _sigils.remove(s));
    s.dispose();
  }

  @override
  void dispose() {
    for (final s in _sigils) {
      s.dispose();
    }
    _sigils.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final size = MediaQuery.of(context).size;

    final deckCount = g.deck.length;
    final discardCount = g.discard.length;

    final assetSize = size.width * 0.18;
    final bottomPad = size.height * 0.05;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: size.width * 0.04,
            bottom: bottomPad,
            child: Column(
              key: _deckKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: assetSize,
                  child: Image.asset(
                    'assets/images/game-assets/board/deck.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$deckCount",
                  style: TextStyle(
                    fontSize: size.width * 0.055,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: size.width * 0.04,
            bottom: bottomPad,
            child: Column(
              key: _discardKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: assetSize,
                  child: Image.asset(
                    'assets/images/game-assets/board/discard.png', 
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$discardCount",
                  style: TextStyle(
                    fontSize: size.width * 0.055,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          //flying sigils
          ..._sigils.map((s) {
            return AnimatedBuilder(
              animation: s.controller,
              builder: (_, __) {
                final p = s.position;
                final t = s.controller.value;
                final scale = 0.85 + (sin(t * pi) * 0.35);
                final opacity = (1.0 - (t * 0.15)).clamp(0.0, 1.0);

                return Positioned(
                  left: p.dx - (s.fontSize / 2),
                  top: p.dy - (s.fontSize / 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: s.rotation.value,
                      child: Transform.scale(
                        scale: scale,
                        child: Text(
                          s.rune,
                          style: TextStyle(
                            fontSize: s.fontSize,
                            fontWeight: FontWeight.w700,
                            color: s.color,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _FlyingSigil {
  final AnimationController controller;
  final Animation<double> rotation;
  final String rune;
  final Offset start;
  final Offset end;
  final Color color;
  final double fontSize;
  final double scatterPx;
  final void Function(_FlyingSigil) onDone;

  late final Offset _control; // for a curved path

  _FlyingSigil({
    required TickerProvider vsync,
    required this.rune,
    required this.start,
    required this.end,
    required this.color,
    required int durationMs,
    required this.scatterPx,
    required this.onDone,
  })  : fontSize = 22 + Random().nextInt(10).toDouble(),
        controller = AnimationController(
          vsync: vsync,
          duration: Duration(milliseconds: durationMs),
        ),
        rotation = Tween<double>(
          begin: -0.8,
          end: 0.8,
        ).animate(
          CurvedAnimation(
            parent: AnimationController(
              vsync: vsync,
              duration: Duration(milliseconds: durationMs),
            )..repeat(reverse: true),
            curve: Curves.easeInOut,
          ),
        ) {
    final mid = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = max(1.0, sqrt(dx * dx + dy * dy));
    final nx = -dy / len;
    final ny = dx / len;

    final curveNudge = (Random().nextDouble() * 2 - 1) * scatterPx;

    _control = mid + Offset(nx * curveNudge, ny * curveNudge);

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onDone(this);
      }
    });
  }

  Offset get position {
    final t = Curves.easeInOutCubic.transform(controller.value);
    return _quadraticBezier(start, _control, end, t);
  }

  static Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  void dispose() {
    controller.dispose();
  }
}
