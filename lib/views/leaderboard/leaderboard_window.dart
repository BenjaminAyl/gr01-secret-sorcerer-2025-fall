import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/user_model.dart';

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
                  'Wins',
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
                        flex: 4,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.customAccent,
                                child: Image.asset("assets/images/wizard_hat.png")
                                ),
                              AppSpacing.gapWM,
                              Text(
                                entry['Username'],
                                style: TextStyles.subheading,
                              )
                            ]
                          ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          entry['wins'] != null ? entry['wins'].toString() : '0',
                          style: TextStyles.subheading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry['losses'] != null && entry['losses'] > 0 ? (entry['wins']/(entry['wins'] + entry['losses'])*100).toStringAsFixed(1) + '%' : 'N/A',
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
