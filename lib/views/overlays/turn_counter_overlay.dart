import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/views/game_view.dart';

class TurnCounterOverlay extends StatelessWidget {
  final WizardGameView game;

  const TurnCounterOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Flame board center
    final boardX = size.width / 2;
    final boardY = size.height / 2.2;

    // Counter size
    final diameter = size.width * 0.11;
    final nudgeRight = size.width * 0.008; //change to center better

    return Stack(
      children: [
        Positioned(
          left: boardX - (diameter / 2) + nudgeRight,
          top: boardY - (diameter / 2),
          child: Container(
            width: diameter,
            height: diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.42),
              border: Border.all(
                color: Colors.white.withOpacity(0.95),
                width: 3.2, // sharper
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.7),
                  blurRadius: 10,
                  spreadRadius: 1.5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "${game.failedTurns}",
              style: TextStyles.title.copyWith(
                fontSize: size.width * 0.067,
                color: Colors.redAccent.shade200,
                height: 1.0,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
