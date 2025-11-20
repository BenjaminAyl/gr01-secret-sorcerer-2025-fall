import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/views/overlays/overlay_animations.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class PolicyOverlay extends StatefulWidget {
  final WizardGameView game;
  final double width;
  final double height;
  final bool isHMPhase;

  const PolicyOverlay({
    super.key,
    required this.game,
    required this.width,
    required this.height,
    required this.isHMPhase,
  });

  @override
  State<PolicyOverlay> createState() => _PolicyOverlayState();
}

class _PolicyOverlayState extends State<PolicyOverlay> {
  late List<bool> revealed;

  @override
  void initState() {
    super.initState();
    final cards = widget.game.pendingCards;
    revealed = List<bool>.filled(cards.length, false);

    _revealCardsOneByOne();
  }

  Future<void> _revealCardsOneByOne() async {
    for (int i = 0; i < revealed.length; i++) {
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;

      setState(() {
        revealed[i] = true;
      });
      AudioHelper.playSFX("card_pick_up.mp3");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.game.pendingCards;
    final w = widget.width;
    final h = widget.height;

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
                widget.isHMPhase
                    ? 'Choose 1 spell to discard'
                    : 'Choose 1 spell to cast',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: h * 0.025,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: h * 0.02),

              SizedBox(
                width: w * 0.9,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(cards.length, (i) {
                      // not yet revealed → show placeholder
                      if (!revealed[i]) {
                        return SizedBox(
                          width: w * 0.25,
                          height: h * 0.18,
                        );
                      }

                      // revealed → animate card in
                      return StaggerFadeScale(
                        delayMs: 50,
                        durationMs: 300,
                        child: _buildCard(cards[i], i),
                      );
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
    final cardHeight = widget.height * 0.18;
    final cardWidth = widget.width * 0.25;

    final asset = type == 'charm'
        ? 'assets/images/game-assets/board/charmCard.png'
        : 'assets/images/game-assets/board/curseCard.png';

    return InkWell(
      onTap: () {
        if (widget.isHMPhase) {
          widget.game.headmasterDiscard(index);
        } else {
          widget.game.spellcasterChoose(index);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: widget.width * 0.015),
        padding: EdgeInsets.all(widget.width * 0.02),
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
    );
  }
}
