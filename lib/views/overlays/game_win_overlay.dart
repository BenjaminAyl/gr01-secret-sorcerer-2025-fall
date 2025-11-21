import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/models/game_player.dart';

class GameWinOverlay extends StatelessWidget {
  final WizardGameView game;
  final double width;
  final double height;
  final bool isHost;
  final String winnerTeam; // "order" or "warlocks"
  final VoidCallback? onHostReturn;

  const GameWinOverlay({
    super.key,
    required this.game,
    required this.width,
    required this.height,
    required this.isHost,
    required this.winnerTeam,
    required this.onHostReturn,
  });

  bool get _warlocksWon =>
      winnerTeam.toLowerCase() == 'warlocks' ||
      winnerTeam.toLowerCase() == 'coven';

  String _name(GamePlayer p) =>
      game.nicknameCache[p.username] ?? 'Wizard';

  @override
  Widget build(BuildContext context) {
    final warlocks = game.players
        .where((p) => p.role == 'warlock' || p.role == 'archwarlock')
        .toList();

    final wizards = game.players
        .where((p) => !(p.role == 'warlock' || p.role == 'archwarlock'))
        .toList();

    final archWarlock = warlocks.firstWhere(
      (p) => p.role == 'archwarlock',
      orElse: () => GamePlayer(username: "", role: "none"),
    );

    final accent = _warlocksWon ? AppColors.error : AppColors.customAccent;

    return Container(
      width: width,
      height: height,
      padding: AppSpacing.screen,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.80),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: width * 0.92,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.secondaryBG.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // TITLE
                Text(
                  _warlocksWon ? "COVEN VICTORY" : "ORDER TRIUMPH",
                  textAlign: TextAlign.center,
                  style: TextStyles.heading.copyWith(
                    fontSize: 34,
                    color: accent,
                  ),
                ),
                AppSpacing.gapM,

                // SUBTITLE
                Text(
                  _warlocksWon
                      ? "The Warlock Coven has overtaken the realm."
                      : "The Circle of Wizards has protected the realm.",
                  textAlign: TextAlign.center,
                  style: TextStyles.bodySmall.copyWith(
                    color: AppColors.textAccentSecondary,
                  ),
                ),

                AppSpacing.gapL,

                // ARCH-WARLOCK SECTION
                if (archWarlock.role == "archwarlock") ...[
                  Text(
                    "Arch-Warlock",
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textAccentSecondary,
                    ),
                  ),
                  AppSpacing.gapS,
                  Text(
                    _name(archWarlock),
                    style: TextStyles.bodyLarge.copyWith(
                      color: accent,
                      fontSize: 22,
                    ),
                  ),
                  AppSpacing.gapL,
                ],

                //stacked team cards
                _teamCard(
                  title: "WARLOCK COVEN",
                  players: warlocks,
                  color: AppColors.error,
                ),

                AppSpacing.gapL,

                _teamCard(
                  title: "CIRCLE OF WIZARDS",
                  players: wizards,
                  color: AppColors.customAccent,
                ),

                AppSpacing.gapXL,

                // HOST BUTTON
                if (isHost)
                  ElevatedButton(
                    onPressed: onHostReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusButton),
                      ),
                    ),
                    child: Text(
                      "Return Everyone to Tavern",
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  Text(
                    "Waiting for host to return everyone…",
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textAccentSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamCard({
    required String title,
    required List<GamePlayer> players,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryBrand.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.body.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
          AppSpacing.gapS,
          ...players.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  AppSpacing.gapWS,
                  Expanded(
                    child: Text(
                      _name(p),
                      overflow: TextOverflow.fade,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.textAccent,
                      ),
                    ),
                  ),
                  if (p.role == 'archwarlock')
                    Text(
                      " (Arch)",
                      style: TextStyles.label.copyWith(
                        color: color,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
