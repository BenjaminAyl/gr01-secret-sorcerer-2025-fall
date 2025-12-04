import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/avatar/avatar_display.dart';

class LeaderboardWindow extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData;

  const LeaderboardWindow({super.key, required this.leaderboardData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSpacing.cardWidthLarge,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBrand,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(color: AppColors.customAccent, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Leaderboard',
              style: TextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapM,

            /// Column headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Text('Player', style: TextStyles.bodySmall),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text('Wins', style: TextStyles.bodySmall),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('Win %', style: TextStyles.bodySmall),
                  ),
                ),
              ],
            ),

            AppSpacing.gapS,

            Expanded(
              child: ListView.separated(
                itemCount: leaderboardData.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.customAccent, height: 18),
                itemBuilder: (context, index) {
                  final entry = leaderboardData[index];

                  final nickname = entry['Nickname'] ?? 'Unknown';
                  final int wins = (entry['wins'] ?? 0) as int;
                  final int losses = (entry['losses'] ?? 0) as int;

                  final String avatarColor =
                      entry['avatarColor'] ?? 'avatarDefault';
                  final String hatColor = entry['hatColor'] ?? 'hatDefault';

                  String winPercent;
                  if (wins + losses > 0) {
                    final pct = wins / (wins + losses) * 100;
                    winPercent = '${pct.toStringAsFixed(1)}%';
                  } else {
                    winPercent = 'N/A';
                  }

                  return SizedBox(
                    height:
                        58, // 🔥 TALLER ROW HEIGHT (adjust 55–70 as you like)
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // PLAYER: avatar + name
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              /// 🔥 Larger avatar radius so the hat fits
                              Transform.translate(
                                offset: const Offset(
                                  0,
                                  9,
                                ), // 🔥 moves avatar+hat downward slightly
                                child: AvatarDisplay(
                                  avatarColor: avatarColor,
                                  hatColor: hatColor,
                                  radius: 22,
                                ),
                              ),

                              AppSpacing.gapWM,

                              Flexible(
                                child: Text(
                                  nickname,
                                  style: TextStyles.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // WINS
                        Expanded(
                          flex: 1,
                          child: Text(
                            wins.toString(),
                            style: TextStyles.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // WIN %
                        Expanded(
                          flex: 2,
                          child: Text(
                            winPercent,
                            style: TextStyles.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
