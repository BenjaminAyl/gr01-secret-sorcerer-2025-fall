import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';

class WizardGameView extends FlameGame {
  TextComponent? text; // nullable now
  int remainingSeconds = 10;
  final Random _random = Random();
  double _spawnTimer = 0;

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()..color = AppColors.primaryBrand,
    ));

    text = TextComponent(
      text: 'Time left: $remainingSeconds',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 3),
    );
    add(text!);

    add(RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..shader = RadialGradient(
          colors: [Colors.purpleAccent.withOpacity(0.2), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer += dt;
    if (_spawnTimer > 0.05) {
      _spawnTimer = 0;
      for (int i = 0; i < 5; i++) {
        _spawnSparkle();
      }
    }
  }

  void _spawnSparkle() {
    final x = _random.nextDouble() * size.x;
    final y = _random.nextDouble() * size.y;
    final colors = [
      Colors.purpleAccent,
      Colors.amberAccent,
      Colors.cyanAccent,
      Colors.white,
      Colors.blueAccent,
    ];
    add(ParticleSystemComponent(
      particle: AcceleratedParticle(
        lifespan: 2 + _random.nextDouble() * 2,
        acceleration: Vector2(0, 10),
        speed: Vector2(
          (_random.nextDouble() - 0.5) * 30,
          (_random.nextDouble() - 0.5) * 30,
        ),
        position: Vector2(x, y),
        child: CircleParticle(
          radius: 1.5 + _random.nextDouble() * 2.5,
          paint: Paint()
            ..color = colors[_random.nextInt(colors.length)]
                .withOpacity(0.3 + _random.nextDouble() * 0.6),
        ),
      ),
    ));
  }
  void updateCountdown(int seconds) {
    remainingSeconds = seconds;
    if (text != null) {
      text!.text = seconds > 0 ? 'Time left: $seconds' : 'Time’s up!';
    }
  }
}
