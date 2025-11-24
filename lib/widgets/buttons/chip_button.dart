import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class ChipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const ChipButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    // optional glow only for filled state
    final glow = filled
        ? [
            BoxShadow(
              color: AppColors.customAccent.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ]
        : <BoxShadow>[];

    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: glow),
      child: Material(
        // make the Material itself circular and with a border
        color: filled ? AppColors.secondaryBrand : Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.customAccent.withOpacity(0.6)),
        ),
        clipBehavior: Clip.antiAlias, // <- clips ripple to the circle
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: AppColors.customAccent.withOpacity(0.25),
          highlightColor: Colors.white10,
          onTap: () {
            AudioHelper.playSFX('enterButton.wav');
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
