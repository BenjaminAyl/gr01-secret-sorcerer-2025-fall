import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/views/game_view.dart';

class TurnCounterOverlay extends StatelessWidget {
  final WizardGameView game;
  const TurnCounterOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final diameter = size.width * 0.11;
    final center = game.boardCenterOnScreen;

    final double nudgeRight = size.width * 0.008;

    return Stack(
      children: [
        Positioned(
          left: center.x - (diameter / 2) + nudgeRight,
          top: center.y - (diameter / 2),
          child: Container(
            width: diameter,
            height: diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(140, 0, 0, 0),
              border: Border.all(color: Colors.white, width: 3.2),
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
