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
    final bool isExec = game.executiveActive == true;

    /// MAIN TITLE AND SUBTITLE
    String title = "";
    String? subtitle;

    if (isExec) {
      title = "Executive Power Active";
      subtitle = _execDescription(phase);
    } else {
      final msg = _phaseDescription(phase);
      title = msg.$1;
      subtitle = msg.$2;

      /// If nothing found, try warning system
      subtitle ??= _nextWarning(game);

      /// Final fallback
      if (title.isEmpty && subtitle == null) {
        title = "Game In Progress";
        subtitle = "Waiting for the next action…";
      }
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

  /// EXECUTIVE POWER TEXT
  String? _execDescription(String phase) {
    switch (phase) {
      case 'executive_investigate':
        return isHM
            ? "Investigate Loyalty – choose a wizard."
            : "Headmaster is investigating loyalty…";

      case 'executive_peek3':
        return isHM
            ? "Foresight – reviewing the next three spells."
            : "Headmaster is peeking at three spells…";

      case 'executive_choose_hm':
        return isHM
            ? "Choose the next Headmaster."
            : "Headmaster is selecting the next Headmaster…";

      case 'executive_kill':
        return isHM
            ? "Choose a wizard to eliminate."
            : "Headmaster is selecting someone to eliminate…";
    }
    return null;
  }

  /// PHASE → TEXT SYSTEM
  (String, String?) _phaseDescription(String phase) {
    switch (phase) {
      case "start":
        return (
          "Nominate a Spellcaster",
          isHM
              ? "Tap a player to nominate."
              : "Headmaster is choosing a nominee…"
        );

      case "voting":
        return (
          "Voting In Progress…",
          isHM
              ? "Waiting for everyone to vote…"
              : "Cast your vote now."
        );

      case "voting_results":
        return (
          "Vote Results",
          "Resolving the election outcome…"
        );

      case "hm_discard":
        return (
          "Headmaster Discarding",
          isHM
              ? "Choose a spell to discard."
              : "Headmaster is discarding…"
        );

      case "sc_choose":
        return (
          "Spellcaster Choosing",
          isSC
              ? "Choose a spell to enact."
              : "Spellcaster is selecting a spell…"
        );

      case "resolving":
        return (
          "Resolving Turn",
          "Preparing the next round…"
        );

      // We intentionally do NOT include:
      // - auto_warning
      // - game_over
      // - kill_archwarlock
      // per your request.

      default:
        return ("Game In Progress", "Phase: $phase");
    }
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
