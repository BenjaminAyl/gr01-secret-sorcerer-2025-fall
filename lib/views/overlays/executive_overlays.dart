import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/views/overlays/overlay_animations.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

class ExecutiveInvestigateOverlay extends StatelessWidget {
  final bool isHeadmaster;
  final double height;

  const ExecutiveInvestigateOverlay({
    super.key,
    required this.isHeadmaster,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        if (!isHeadmaster)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
              child: Center(
                child: Text(
                  "Headmaster is investigating…",
                  textAlign: TextAlign.center,
                  style: TextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontSize: height * 0.028,
                  ),
                ),
              ),
            ),
          ),

        if (isHeadmaster)
          Positioned(
            top: height * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Tap a wizard to investigate their loyalty",
                textAlign: TextAlign.center,
                style: TextStyles.body.copyWith(
                  color: Colors.white,
                  fontSize: height * 0.024,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ExecutiveInvestigateResultOverlay extends StatelessWidget {
  final WizardGameView game;
  final bool isHeadmaster;
  final double height;
  final VoidCallback onContinue;

  const ExecutiveInvestigateResultOverlay({
    super.key,
    required this.game,
    required this.isHeadmaster,
    required this.height,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        if (!isHeadmaster)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.60),
              child: Center(
                child: Text(
                  "Headmaster is reviewing loyalty…",
                  textAlign: TextAlign.center,
                  style: TextStyles.bodyLarge.copyWith(
                    color: Colors.white70,
                    fontSize: height * 0.026,
                  ),
                ),
              ),
            ),
          ),

        if (isHeadmaster)
          Center(
            child: Container(
              padding: EdgeInsets.all(height * 0.025),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.80),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Text(
                    "Loyalty Revealed",
                    style: TextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: height * 0.030,
                    ),
                  ),
                  SizedBox(height: height * 0.02),

                  if (game.executiveTarget != null) ...[
                    Text(
                      "${game.nicknameCache[game.executiveTarget] ?? "Wizard"} is a:",
                      style: TextStyles.body.copyWith(
                        color: Colors.white70,
                        fontSize: height * 0.022,
                      ),
                    ),

                    Builder(builder: (_) {
                      final target = game.players.firstWhere(
                        (p) => p.username == game.executiveTarget!,
                        orElse: () => game.players.first,
                      );

                      final loyalty =
                          (target.role == 'wizard') ? 'WIZARD' : 'WARLOCK';

                      final loyaltyColor = (loyalty == 'WARLOCK')
                          ? Colors.redAccent
                          : Colors.lightBlueAccent;

                      return Text(
                        loyalty,
                        style: TextStyles.heading.copyWith(
                          color: loyaltyColor,
                          fontSize: height * 0.034,
                        ),
                      );
                    }),
                  ],

                  SizedBox(height: height * 0.035),

                  ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.black,
                        fontSize: height * 0.019,
                      ),
                    ),

                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ExecutivePeek3Overlay extends StatelessWidget {
  final WizardGameView game;
  final bool isHeadmaster;
  final double height;
  final double width;
  final VoidCallback onContinue;

  const ExecutivePeek3Overlay({
    super.key,
    required this.game,
    required this.isHeadmaster,
    required this.height,
    required this.width,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        if (!isHeadmaster)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.60),
              child: Center(
                child: Text(
                  "Headmaster is foreseeing future spells…",
                  textAlign: TextAlign.center,
                  style: TextStyles.bodyLarge.copyWith(
                    color: Colors.white70,
                    fontSize: height * 0.026,
                  ),
                ),
              ),
            ),
          ),

        if (isHeadmaster)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.70),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      "Next Three Spells",
                      style: TextStyles.heading.copyWith(
                        color: Colors.white,
                        fontSize: height * 0.028,
                      ),
                    ),
                    SizedBox(height: height * 0.02),

                    SizedBox(
                      width: width * 0.9,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            game.pendingExecutiveCards.length,
                            (i) {
                              final type = game.pendingExecutiveCards[i];
                              final asset = type == 'charm'
                                  ? 'assets/images/game-assets/board/charmCard.png'
                                  : 'assets/images/game-assets/board/curseCard.png';

                              return StaggerFadeScale(
                                delayMs: 150 * i,
                                durationMs: 400,
                                beginScale: 0.9,
                                endScale: 1.0,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: width * 0.015),
                                  padding: EdgeInsets.all(width * 0.02),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Image.asset(
                                    asset,
                                    height: height * 0.18,
                                    width: width * 0.25,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: height * 0.035),
                    ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        "Continue",
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.black,
                          fontSize: height * 0.020,
                        ),
                      ),

                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ExecutiveChooseHeadmasterOverlay extends StatelessWidget {
  final bool isHeadmaster;
  final double height;

  const ExecutiveChooseHeadmasterOverlay({
    super.key,
    required this.isHeadmaster,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHeadmaster) {
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.60),
          child: Center(
            child: Text(
              "Headmaster is choosing the next Headmaster…",
              textAlign: TextAlign.center,
              style: TextStyles.bodyLarge.copyWith(
                color: Colors.white70,
                fontSize: height * 0.026,
              ),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: height * 0.06,
            left: 16,
            right: 16,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: height * 0.014,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.82),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              "Tap a wizard’s hat to appoint the next Headmaster.\n"
              "Turn order will continue from them.",
              textAlign: TextAlign.center,
              style: TextStyles.body.copyWith(
                color: Colors.white,
                fontSize: height * 0.020,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class ExecutiveKillOverlay extends StatelessWidget {
  final bool isHeadmaster;
  final double height;

  const ExecutiveKillOverlay({
    super.key,
    required this.isHeadmaster,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHeadmaster) {
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: Center(
            child: Text(
              "A lethal spell is being prepared…",
              textAlign: TextAlign.center,
              style: TextStyles.bodyLarge.copyWith(
                color: Colors.redAccent.shade100,
                fontSize: height * 0.026,
              ),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: height * 0.06,
            left: 16,
            right: 16,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: height * 0.014,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  color: Colors.redAccent.shade100,
                  size: height * 0.05,
                ),
                SizedBox(height: height * 0.008),
                Text(
                  "Cast a lethal spell.",
                  textAlign: TextAlign.center,
                  style: TextStyles.heading.copyWith(
                    color: Colors.white,
                    fontSize: height * 0.022,
                  ),
                ),
                SizedBox(height: height * 0.006),
                Text(
                  "Tap a wizard to eliminate them.\n"
                  "They will become a silent specter.",
                  textAlign: TextAlign.center,
                  style: TextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: height * 0.017,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExecutiveChooseHeadmasterResultOverlay extends StatelessWidget {
  final WizardGameView game;
  final bool isHeadmaster;
  final double height;
  final VoidCallback onConfirm;

  const ExecutiveChooseHeadmasterResultOverlay({
    super.key,
    required this.game,
    required this.isHeadmaster,
    required this.height,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final targetUid = game.executiveTarget;
    final name = targetUid != null
        ? (game.nicknameCache[targetUid] ?? 'Wizard')
        : 'Wizard';

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: isHeadmaster
                  ? Container(
                      padding: EdgeInsets.all(height * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amberAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Next Headmaster Chosen",
                            style: TextStyles.heading.copyWith(
                              color: Colors.white,
                              fontSize: height * 0.028,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            "$name will become the next Headmaster.\n"
                            "Turn order will continue from them.",
                            textAlign: TextAlign.center,
                            style: TextStyles.body.copyWith(
                              color: Colors.white70,
                              fontSize: height * 0.021,
                            ),
                          ),
                          SizedBox(height: height * 0.03),
                          ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: Text(
                              "Confirm",
                              style: TextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      "Headmaster is appointing the next Headmaster…",
                      textAlign: TextAlign.center,
                      style: TextStyles.bodyLarge.copyWith(
                        color: Colors.white70,
                        fontSize: height * 0.026,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExecutiveKillResultOverlay extends StatelessWidget {
  final WizardGameView game;
  final double height;
  final double width;
  final bool isArch;
  final bool isHost;
  final VoidCallback? onContinue;

  const ExecutiveKillResultOverlay({
    super.key,
    required this.game,
    required this.height,
    required this.width,
    required this.isArch,
    required this.isHost,
    required this.onContinue,
  });

  String _targetName() {
    final uid = game.executiveTarget;
    if (uid == null) return "A wizard";
    return game.nicknameCache[uid] ?? "A wizard";
  }

  @override
  Widget build(BuildContext context) {
    final title = isArch ? "The ArchWarlock Has Fallen" : "A Wizard Has Fallen";
    final name = _targetName();

    final body = isArch
        ? "$name was the ArchWarlock!\nThe wizards have won."
        : "$name has been struck down by a lethal spell.";

    final subtitle = isArch
        ? "The mortal realm is safe… for now."
        : "Their allegiance remains a mystery…";

    final buttonText = "Continue";

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF311B92),
            Color(0xFF000000),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Icon(
                    isArch ? Icons.bolt : Icons.flash_on,
                    color:
                        isArch ? Colors.amberAccent : Colors.redAccent,
                    size: height * 0.08,
                  ),
                ),

                SizedBox(height: height * 0.02),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyles.heading.copyWith(
                    color: Colors.white,
                    fontSize: height * 0.032,
                  ),
                ),

                SizedBox(height: height * 0.015),

                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyles.body.copyWith(
                    color: Colors.white70,
                    fontSize: height * 0.022,
                  ),
                ),

                SizedBox(height: height * 0.01),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyles.bodySmall.copyWith(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                    fontSize: height * 0.018,
                  ),
                ),

                SizedBox(height: height * 0.035),

                ElevatedButton(
                  onPressed: isHost ? onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isArch ? Colors.greenAccent : Colors.deepOrangeAccent,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.10,
                      vertical: height * 0.016,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyles.bodySmall.copyWith(
                      fontSize: height * 0.022,
                    ),
                  ),
                ),

                if (!isHost)
                  Padding(
                    padding: EdgeInsets.only(top: height * 0.02),
                    child: Text(
                      "Waiting…",
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white60,
                        fontSize: height * 0.018,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExecutiveKillAnimationOverlay extends StatelessWidget {
  final WizardGameView game;
  final bool isHeadmaster;
  final double height;
  final VoidCallback onContinue;

  const ExecutiveKillAnimationOverlay({
    super.key,
    required this.game,
    required this.isHeadmaster,
    required this.height,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final targetUid = game.executiveTarget;
    final target = targetUid == null
        ? null
        : game.players.firstWhere(
            (p) => p.username == targetUid,
            orElse: () => game.players.first,
          );

    final targetName =
        targetUid == null ? 'A wizard' : (game.nicknameCache[targetUid] ?? 'A wizard');

    final isArch = target?.role == 'archwarlock';

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.80),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                Icons.bolt,
                color: Colors.redAccent.shade100,
                size: height * 0.10,
              ),

              SizedBox(height: height * 0.02),

              Text(
                "$targetName has been struck down!",
                textAlign: TextAlign.center,
                style: TextStyles.heading.copyWith(
                  color: Colors.white,
                  fontSize: height * 0.026,
                ),
              ),

              SizedBox(height: height * 0.012),

              Text(
                isArch
                    ? "Their true identity is revealed: the Archwarlock!"
                    : "Their role remains shrouded in mystery…",
                textAlign: TextAlign.center,
                style: TextStyles.body.copyWith(
                  color: Colors.white70,
                  fontSize: height * 0.019,
                ),
              ),

              if (isHeadmaster)
                Padding(
                  padding: EdgeInsets.only(top: height * 0.03),
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyles.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
