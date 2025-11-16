import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

class LeaderboardWindow extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData;

  const LeaderboardWindow({super.key, required this.leaderboardData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSpacing.cardWidthLarge,
        height: AppSpacing.buttonHeightLarge * 6,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBrand,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(
            color: AppColors.customAccent,
            width: 2.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Leaderboard',
              style: TextStyles.heading,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapM,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Player',
                  style: TextStyles.body,
                ),
                Text(
                  'W/L',
                  style: TextStyles.body,
                ),
                Text(
                  'Win %',
                  style: TextStyles.body,
                )
              ],
            ),
            AppSpacing.gapS,
            Expanded(
              child: ListView.separated(
                itemCount: leaderboardData.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.customAccent,
                  height: 16,
                ),
                itemBuilder: (context, index) {
                  final entry = leaderboardData[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.customAccent,
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              AppSpacing.gapL,
                              Text(
                                entry['username'],
                                style: TextStyles.subheading,
                              )
                            ]
                          ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry['wins'].toString(),
                          style: TextStyles.subheading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "100%",
                          style: TextStyles.subheading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
