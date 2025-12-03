import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';

class AvatarDisplay extends StatelessWidget {
  final String avatarColor;
  final String? hatColor;
  final double radius;

  const AvatarDisplay({
    super.key,
    required this.avatarColor,
    this.hatColor,
    this.radius = AppSpacing.avatarMedium,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2.2,
      height: radius * 2.2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Avatar base image (no colored circle)
          Image.asset(
            'assets/images/avatars/$avatarColor.png',
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.contain,
          ),

          // Optional hat overlay
          if (hatColor != null)
            Transform.translate(
              offset: Offset(0, -radius * 1.1),
              child: Image.asset(
                'assets/images/hats/$hatColor.png',
                height: radius * 1.9,
                width: radius * 1.9,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}
