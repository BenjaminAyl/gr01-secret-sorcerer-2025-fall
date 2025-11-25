import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/info_row.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class FriendsList extends StatelessWidget {
  final List<AppUser> friends;
  final ValueChanged<AppUser> onRemove;
  final ValueChanged<AppUser>? onJoin;
  final Map<String, String?>? friendLobbyMap;

  const FriendsList({
    super.key,
    required this.friends,
    required this.onRemove,
    this.onJoin,
    this.friendLobbyMap,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Center(
          child: Text(
            'No friends yet',
            style: TextStyles.body,
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: friends.length,
      separatorBuilder: (_, __) => AppSpacing.gapM,
      itemBuilder: (context, i) {
        final friend = friends[i];
        return InfoRow(
          title: friend.nickname,
          value: '@'+friend.username,
          actionLabel: 'Remove',
          onPress: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.secondaryBG,
                title: Text('Remove friend', style: TextStyles.bodyLarge.copyWith(color: AppColors.textAccent)),
                content: Text('Are you sure you want to remove ${friend.nickname} from your friends?', style: TextStyles.body.copyWith(color: AppColors.textAccentSecondary)),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  TextButton(
                    onPressed: () {
                      AudioHelper.playSFX('enterButton.wav');
                      Navigator.of(ctx).pop(false);
                    },
                    child: Text('Cancel', style: TextStyles.body.copyWith(color: AppColors.textAccentSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      AudioHelper.playSFX('enterButton.wav');
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text('Remove', style: TextStyles.body.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              onRemove(friend);
            }
          },
          secondaryActionLabel: 'Join',
          onSecondaryPress: (onJoin != null && (friendLobbyMap?[friend.uid]?.trim().isNotEmpty ?? false))
              ? () => onJoin!(friend)
              : null,
        );
      },
    );
  }
}
