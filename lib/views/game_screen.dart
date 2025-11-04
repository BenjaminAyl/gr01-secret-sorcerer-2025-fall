import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import '../controllers/game_controller.dart';
import 'game_view.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final WizardGameView gameView;

  @override
  void initState() {
    super.initState();
    controller = GameController();
    gameView = WizardGameView();

    controller.startCountdown(() {
      if (mounted) context.go('/lobby');
    });

    controller.timerStream.listen((seconds) {
      gameView.updateCountdown(seconds);
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      body: Stack(
        children: [
          // The Flame game background
          GameWidget(game: gameView),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  ' Game in Progress ',
                  style: TextStyles.title.copyWith(
                    color: Colors.amberAccent,
                    shadows: const [
                      Shadow(blurRadius: 10, color: Colors.purpleAccent),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Returning in ${controller.countdown} seconds',
                  style: TextStyles.body.copyWith(
                    color: AppColors.customAccent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
