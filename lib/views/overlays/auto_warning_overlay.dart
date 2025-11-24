import 'dart:math';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

class AutoWarningOverlay extends StatefulWidget {
  const AutoWarningOverlay({super.key});

  @override
  State<AutoWarningOverlay> createState() => _AutoWarningOverlayState();
}

class _AutoWarningOverlayState extends State<AutoWarningOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fade;
  late Animation<double> _pulse;

  final List<_FloatingRune> _runes = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );

    // Fade IN
    _fadeCtrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 1200));

      // Fade OUT
      if (mounted) _fadeCtrl.reverse();
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseCtrl,
        curve: Curves.easeInOutCubic,
      ),
    );
    for (int i = 0; i < 18; i++) {
      _runes.add(_FloatingRune(this));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fade,
      child: Stack(
        children: [
          // Darkened background
          Container(
            color: Colors.black.withOpacity(0.82),
          ),

          // Floating rune particles
          ..._runes.map(
            (r) => AnimatedBuilder(
              animation: r.controller,
              builder: (_, __) => Positioned(
                left: size.width * r.x,
                top: size.height * r.y.value,
                child: Opacity(
                  opacity: ((1 - r.y.value) * 0.7).clamp(0.0, 1.0),

                  child: Transform.rotate(
                    angle: r.rotation.value,
                    child: Text(
                      r.rune,
                      style: TextStyle(
                        color: Colors.redAccent.withOpacity(0.75),
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Big pulsing warning text
          Center(
            child: ScaleTransition(
              scale: _pulse,
              child: Text(
                "Chaotic Magic Surges…\nA Random Spell Will Be Enacted.",
                textAlign: TextAlign.center,
                style: TextStyles.title.copyWith(
                  fontSize: size.width * 0.075,
                  color: Colors.redAccent,
                  height: 1.25,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 20),
                    Shadow(color: Colors.redAccent, blurRadius: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var r in _runes) {
      r.controller.dispose();
    }
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }
}
class _FloatingRune {
  late AnimationController controller;
  late Animation<double> y;
  late Animation<double> rotation;

  final double x = Random().nextDouble();

  final String rune = const [
    "ᛝ", "ᛞ", "ᚨ", "ᛉ", "ᛟ", "ᚾ", "✦", "✧", "✶"
  ][Random().nextInt(9)];

  _FloatingRune(TickerProvider vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: 3000 + Random().nextInt(2000)),
    )..repeat();

    y = Tween<double>(begin: 1.1, end: -0.2).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    rotation = Tween<double>(begin: -0.5, end: 0.5).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }
}
