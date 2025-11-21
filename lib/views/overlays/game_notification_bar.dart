import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';

class GameNotificationBar extends StatelessWidget {
  final WizardGameView game;
  final bool isHM;
  final bool isSC;
  final double width;
  final double height;

  const GameNotificationBar({
    super.key,
    required this.game,
    required this.isHM,
    required this.isSC,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final phase = game.phase;
    final execPower = game.executivePower;
    final isExec = game.executiveActive == true;

    // TITLE + SUBTITLE
    String title = "";
    String? subtitle;

    if (isExec) {
      title = "Executive Power Active";
      subtitle = _execDescription(phase, execPower);
    } else if (phase == "voting") {
      title = "Voting in Progress…";
    } else if (phase == "voting_results") {
      title = "Vote Results";
    } else {
      subtitle = _nextWarning(game);
      title = subtitle != null ? "Warning" : "";
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        vertical: height * 0.014,
        horizontal: width * 0.06,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryBrand.withOpacity(0.9),
            AppColors.primaryBrand.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.customAccent.withOpacity(0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: height * 0.022,
                fontWeight: FontWeight.w800,
              ),
            ),

          if (subtitle != null) ...[
            SizedBox(height: height * 0.006),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyles.bodySmall.copyWith(
                color: AppColors.textAccentSecondary,
                fontSize: height * 0.017,
              ),
            ),
          ],
        ],
      ),
    );
  }


  String? _execDescription(String phase, String? power) {
    switch (phase) {
      case 'executive_investigate':
        return "Investigate Loyalty – choose a wizard.";
      case 'executive_peek3':
        return "Foresight – reviewing the next three spells.";
      case 'executive_choose_hm':
        return "Choose the next Headmaster.";
      case 'executive_kill':
        return "Cast a lethal spell – select a wizard to eliminate.";
    }
    return null;
  }

  String? _nextWarning(WizardGameView g) {
    final pc = g.players.length;
    final c = g.curses;

    if (g.executiveActive == true) return null;

    if (pc == 5 || pc == 6) {
      if (c == 2) return "If the next Curse is enacted: Foresee three spells.";
      if (c == 3) return "If the next Curse is enacted: Execute a wizard.";
    }

    if (pc == 7 || pc == 8) {
      if (c == 1) return "If the next Curse is enacted: Investigate Loyalty.";
      if (c == 2) return "If the next Curse is enacted: Foresee three spells.";
      if (c == 3) return "If the next Curse is enacted: Execute a wizard.";
    }

    if (pc == 9 || pc == 10) {
      if (c == 0) return "If the next Curse is enacted: Investigate Loyalty.";
      if (c == 1) return "If the next Curse is enacted: Investigate Loyalty.";
      if (c == 2) return "If the next Curse is enacted: Foresee three spells.";
      if (c == 3) return "If the next Curse is enacted: Execute a wizard.";
    }

    return null;
  }
}
