import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/views/profile/friends_screen.dart';

class FriendsSwitch extends StatelessWidget {
  final FriendTab value;
  final ValueChanged<FriendTab> onChanged;
  final String friendsLabel;
  final String requestsLabel;

  const FriendsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.friendsLabel = 'Friends',
    this.requestsLabel = 'Requests',
  });

  @override
  Widget build(BuildContext context) {
    final isFriends = value == FriendTab.friends;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.customAccent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: friendsLabel,
            selected: isFriends,
            onTap: () => onChanged(FriendTab.friends),
          ),
          AppSpacing.gapXS,
          _Segment(
            label: requestsLabel,
            selected: !isFriends,
            onTap: () => onChanged(FriendTab.requests),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryBrand : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.customAccent.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: (selected
                  ? TextStyles.bodyLarge
                  : TextStyles.body)
              .copyWith(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
