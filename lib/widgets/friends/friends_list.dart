import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/info_row.dart';

class FriendsList extends StatelessWidget {
  final List<AppUser> friends;
  final ValueChanged<AppUser> onRemove;

  const FriendsList({
    super.key,
    required this.friends,
    required this.onRemove,
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
          onPress: () => onRemove(friend),
        );
      },
    );
  }
}
