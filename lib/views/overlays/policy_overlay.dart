import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/views/overlays/overlay_animations.dart';

class PolicyOverlay extends StatelessWidget {
  final WizardGameView game;
  final double width;
  final double height;
  final bool isHMPhase; // true = HM discard, false = SC choose

  const PolicyOverlay({
    super.key,
    required this.game,
    required this.width,
    required this.height,
    required this.isHMPhase,
  });

  @override
  Widget build(BuildContext context) {
    final cards = game.pendingCards;

    if (cards.isEmpty) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isHMPhase
                    ? 'Choose 1 spell to discard'
                    : 'Choose 1 spell to cast',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height * 0.025,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: height * 0.02),
              SizedBox(
                width: width * 0.9,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(cards.length, (i) {
                      final type = cards[i];
                      return _buildCard(type, i);
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String type, int index) {
    final cardHeight = height * 0.18;
    final cardWidth = width * 0.25;
    final asset = type == 'charm'
        ? 'assets/images/game-assets/board/charmCard.png'
        : 'assets/images/game-assets/board/curseCard.png';

    return StaggerFadeScale(
      delayMs: 150 * index,
      durationMs: 400,
      beginScale: 0.9,
      endScale: 1.0,
      child: InkWell(
        onTap: () {
          if (isHMPhase) {
            game.headmasterDiscard(index);
          } else {
            game.spellcasterChoose(index);
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.015),
          padding: EdgeInsets.all(width * 0.02),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Image.asset(
            asset,
            height: cardHeight,
            width: cardWidth,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
