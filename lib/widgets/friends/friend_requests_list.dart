import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/buttons/chip_button.dart';

class FriendRequestsList extends StatelessWidget {
  final List<AppUser> requests;
  final ValueChanged<AppUser> onAccept;
  final ValueChanged<AppUser> onDecline;

  const FriendRequestsList({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Text('No pending requests', style: TextStyles.body));
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: requests.length,
      separatorBuilder: (_, __) => AppSpacing.gapM,
      itemBuilder: (context, i) {
        final AppUser friendRequest = requests[i];
        return Row(
          children: [
            // Name + handle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friendRequest.nickname, style: TextStyles.bodyLarge),
                  AppSpacing.gapXS,
                  Text(
                    '@'+friendRequest.username,
                    style: TextStyles.body.copyWith(
                      color: AppColors.textAccentSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              children: [
                ChipButton(
                  icon: Icons.check,
                  onTap: () => onAccept(friendRequest),
                  filled: true,
                ),
                AppSpacing.gapWS,
                ChipButton(
                  icon: Icons.close,
                  onTap: () => onDecline(friendRequest),
                  filled: false,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
