import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class RoleRevealScreen extends StatefulWidget {
  final String code;
  const RoleRevealScreen({super.key, required this.code});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with TickerProviderStateMixin {

  late AnimationController fadeCtrl;
  late AnimationController titleCtrl;
  late AnimationController subtitleCtrl;
  late AnimationController partnersCtrl;
  late AnimationController buttonCtrl;
  bool controllersReady = false;

  @override
  void initState() {
    AudioHelper.crossfade('role_reveal.mp3');
    super.initState();

    fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    partnersCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    controllersReady = true;

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) fadeCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) titleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1150), () {
      if (mounted) subtitleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1650), () {
      if (mounted) partnersCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) buttonCtrl.forward();
    });
  }

  @override
  void dispose() {
    fadeCtrl.dispose();
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    partnersCtrl.dispose();
    buttonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('states')
          .doc(widget.code)
          .snapshots(),
      builder: (context, snap) {
        if (!controllersReady) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (!snap.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/lobby/${widget.code}');
          });
          return const SizedBox.shrink();
        }

        final rawData = snap.data!.data();
        if (rawData == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final playersData = rawData['players'];
        if (playersData == null || playersData.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final players = List<Map<String, dynamic>>.from(playersData);

        final me = players.firstWhere(
          (p) => p['username'] == uid,
          orElse: () => {},
        );

        if (me.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final String role = me['role'];
        final List<String> partnerUids =
            (me['vote'] == null || me['vote'].toString().isEmpty)
                ? []
                : me['vote'].toString().split(",");


        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('lobbies')
              .doc(widget.code)
              .get(),
          builder: (context, lobbySnap) {
            if (!lobbySnap.hasData) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }

            final lobbyData = lobbySnap.data!.data() ?? {};
            final Map<String, dynamic> nicknameMap =
                Map<String, dynamic>.from(lobbyData['nicknames'] ?? {});

            // Convert UID partners -> nickname partners
           final List<String> partnerNames = partnerUids
            .map((uid) => nicknameMap[uid]?.toString() ?? uid)
            .toList();


            // ROLE UI CONFIG
            late Color accent;
            late String title;
            late String subtitle;

            switch (role) {
              case "warlock":
                title = "WARLOCK";
                subtitle = "A disciple of forbidden curses.";
                accent = Colors.purpleAccent;
                break;

              case "archwarlock":
                title = "ARCHWARLOCK";
                subtitle = "The supreme master of the dark arts.";
                accent = Colors.redAccent;
                break;

              default:
                title = "WIZARD";
                subtitle = "A guardian of ancient mystic charms.";
                accent = Colors.blueAccent;
                break;
            }

            return Scaffold(
              backgroundColor: Colors.black,
              body: AnimatedBuilder(
                animation: fadeCtrl,
                builder: (_, __) {
                  return Opacity(
                    opacity: fadeCtrl.value,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.07),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: h * 0.14),

                              // TITLE
                              AnimatedBuilder(
                                animation: titleCtrl,
                                builder: (_, __) {
                                  final slide = (1 - titleCtrl.value) * 40;
                                  final glow = titleCtrl.value * 20;

                                  return Transform.translate(
                                    offset: Offset(0, slide),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            letterSpacing: 5,
                                            fontSize: w * 0.17,
                                            fontWeight: FontWeight.w900,
                                            color: accent,
                                            shadows: [
                                              Shadow(
                                                color: accent.withOpacity(0.6),
                                                blurRadius: glow,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: h * 0.03),

                              // SUBTITLE
                              AnimatedBuilder(
                                animation: subtitleCtrl,
                                builder: (_, __) {
                                  return Opacity(
                                    opacity: subtitleCtrl.value,
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          subtitle,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: w * 0.045,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: h * 0.04),

                              // PARTNERS
                              AnimatedBuilder(
                                animation: partnersCtrl,
                                builder: (_, __) {
                                  return Opacity(
                                    opacity: partnersCtrl.value,
                                    child: Center(
                                      child: buildPartners(
                                        role,
                                        partnerNames,
                                        accent,
                                        w,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const Spacer(),

                              // BUTTON
                              AnimatedBuilder(
                                animation: buttonCtrl,
                                builder: (_, __) {
                                  return Opacity(
                                    opacity: buttonCtrl.value,
                                    child: Center(
                                      child: ScaleTransition(
                                        scale: CurvedAnimation(
                                          parent: buttonCtrl,
                                          curve: Curves.easeOutBack,
                                        ),
                                        child: SizedBox(
                                          width: w * 0.55,
                                          height: h * 0.065,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              AudioHelper.crossfade('TavernMusic.wav');
                                              context.go('/game/${widget.code}');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: accent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: FittedBox(
                                              child: Text(
                                                "BEGIN",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: w * 0.06,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: h * 0.10),
                            ],
                          ),
                        );

                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  //Partners Widget
  Widget buildPartners(
    String myRole,
    List<String> partnerNames,
    Color accent,
    double w,
  ) {
    if (partnerNames.isEmpty) return const SizedBox.shrink();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stateSnap = FirebaseFirestore.instance
        .collection('states')
        .doc(widget.code)
        .get();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: stateSnap,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final data = snap.data!.data();
        if (data == null) return const SizedBox.shrink();

        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final partnerEntries = partnerNames.map((nickname) {
          // Find the player that matches this nickname
          final match = players.firstWhere(
            (p) => p['username'] != uid &&
                  (p['username'] == nickname ||
                    (p['nickname'] ?? "") == nickname),
            orElse: () => {},
          );

          final role = match.isNotEmpty ? match['role'] : "warlock";
          return MapEntry(nickname, role);
        }).toList();

        // Sort for display groups
        final archPartners = partnerEntries
            .where((e) => e.value == "archwarlock")
            .map((e) => e.key)
            .toList();

        final warlockPartners = partnerEntries
            .where((e) => e.value == "warlock")
            .map((e) => e.key)
            .toList();

        return Column(
          children: [
            Text(
              "You sense the presence of:",
              style: TextStyle(color: Colors.white70, fontSize: w * 0.045),
            ),
            SizedBox(height: w * 0.03),

            if (archPartners.isNotEmpty) ...[
              Text(
                "ArchWarlock:",
                style: TextStyle(
                  color: accent,
                  fontSize: w * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...archPartners.map(
                (name) => Text(
                  name,
                  style: TextStyle(
                    color: accent.withOpacity(0.85),
                    fontSize: w * 0.05,
                  ),
                ),
              ),
              SizedBox(height: w * 0.05),
            ],

            if (warlockPartners.isNotEmpty) ...[
              Text(
                "Warlocks:",
                style: TextStyle(
                  color: accent,
                  fontSize: w * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...warlockPartners.map(
                (name) => Text(
                  name,
                  style: TextStyle(
                    color: accent.withOpacity(0.85),
                    fontSize: w * 0.05,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
      }