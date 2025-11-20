import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class GameScreen extends StatefulWidget {
  final String code;
  const GameScreen({super.key, required this.code});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final _firebase = FirebaseController();
  late final WizardGameView _game;
  String? _creatorId;
  String? _uid;
  bool _navigatedOut = false;

  // local “I clicked” flag so the UI confirms instantly
  bool _myVoteCastLocal = false;

  @override
  void initState() {
    super.initState();

    _uid = FirebaseAuth.instance.currentUser?.uid;
    final myUid = _uid ?? "unknown";
    _game = WizardGameView(lobbyId: widget.code, myUid: myUid);

    // Switch from lobby music to game music
    AudioHelper.crossfade('TavernMusic.wav');
  }

  @override
  Widget build(BuildContext context) {
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbies').doc(widget.code);
    final stateRef =
        FirebaseFirestore.instance.collection('states').doc(widget.code);

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: lobbyRef.snapshots(),
      builder: (context, lobbySnap) {
        if (!lobbySnap.hasData || lobbySnap.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final lobbyData = lobbySnap.data?.data();
        if (lobbyData == null) return const SizedBox.shrink();

        final lobby = lobbySnap.data!.data()!;
        _creatorId ??= lobby['creatorId'] as String?;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stateRef.snapshots(),
          builder: (context, stateSnap) {
            if (!stateSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If state doc was deleted then go return to lobby
            if (!stateSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_navigatedOut) {
                  _navigatedOut = true;
                  context.go('/lobby/${widget.code}');
                }
              });
              return const SizedBox.shrink();
            }

            final rawState = stateSnap.data!.data();
            if (rawState == null) {
              return const SizedBox.shrink();
            }

            // Safety: sometimes phase might not be set yet
            final phase = rawState['phase'] ?? 'start';
            _game.phase = phase;
            _game.executivePower = rawState['executivePower'];
            _game.executiveActive = rawState['executiveActive'] == true;
            _game.executiveTarget = rawState['executiveTarget'];
            _game.pendingExecutiveCards =
                List<String>.from(rawState['pendingExecutiveCards'] ?? []);

            // Reset optimistic flag when voting ends
            if (phase != 'voting' &&
                phase != 'voting_results' &&
                _myVoteCastLocal) {
              _myVoteCastLocal = false;
            }

            return Scaffold(
              backgroundColor: AppColors.primaryBrand,
              body: SafeArea(
                child: Stack(
                  children: [
                    GameWidget(
                      game: _game,
                      overlayBuilderMap: {
                        'ControlsOverlay': (context, game) {
                          final g = game as WizardGameView;
                          final isHM = g.isHeadmasterClient;
                          final isSC = g.isSpellcasterClient;

                          final showHMDiscard = isHM &&
                              g.phase == 'hm_discard' &&
                              g.pendingCards.length == 3;

                          final showSCChoose = isSC &&
                              g.phase == 'sc_choose' &&
                              g.pendingCards.length == 2;

                          final showVoting = (g.phase == 'voting' ||
                                  g.phase == 'voting_results') &&
                              !isHM;

                          // Executive power text + upcoming warning
                          final String? nextExecHint =
                              _nextExecutiveWarning(g);
                          final String? activeExecText =
                              (g.executivePower == 'investigate' &&
                                      g.phase == 'executive_investigate')
                                  ? 'Executive Power active: Investigate Loyalty – Headmaster, tap a hat to inspect a wizard.'
                                  : (g.executivePower == 'peek3' &&
                                          g.phase == 'executive_peek3')
                                      ? 'Executive Power active: Foresight – Headmaster, view the next three spells.'
                                      : null;

                          // Responsive card builder with staggered fade/scale
                          Widget cardWidget(
                            String type,
                            VoidCallback onTap,
                            int index,
                          ) {
                            final cardHeight = height * 0.18;
                            final cardWidth = width * 0.25;
                            final asset = type == 'charm'
                                ? 'assets/images/game-assets/board/charmCard.png'
                                : 'assets/images/game-assets/board/curseCard.png';

                            return _StaggerFadeScale(
                              delayMs: 150 * index,
                              durationMs: 400,
                              beginScale: 0.9,
                              endScale: 1.0,
                              child: InkWell(
                                onTap: onTap,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: width * 0.015,
                                  ),
                                  padding: EdgeInsets.all(width * 0.02),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.white24),
                                  ),
                                  child: Image.asset(
                                    asset,
                                    height: cardHeight,
                                    width: cardWidth,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          }

                          Widget rolePill(String text) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: height * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBrand
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                text,
                                style: TextStyles.bodySmall.copyWith(
                                  color: AppColors.textAccent,
                                  fontSize: height * 0.02,
                                ),
                              ),
                            );
                          }

                          Widget buildCardOverlay(
                            String title,
                            List<String> cards,
                            bool isHMPhase,
                          ) {
                            return AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black.withOpacity(0.65),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: height * 0.025,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: height * 0.02),
                                      SizedBox(
                                        width: width * 0.9,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              cards.length,
                                              (i) {
                                                final type = cards[i];
                                                return cardWidget(
                                                  type,
                                                  () => isHMPhase
                                                      ? g.headmasterDiscard(i)
                                                      : g.spellcasterChoose(i),
                                                  i,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          String nomineeName() {
                            if (g.nomineeIndex == null ||
                                g.nomineeIndex! < 0 ||
                                g.nomineeIndex! >= g.players.length) {
                              return 'the Spellcaster';
                            }
                            final uid =
                                g.players[g.nomineeIndex!].username;
                            return g.nicknameCache[uid] ?? 'the Spellcaster';
                          }

                          // Simple line showing who voted what
                          Widget voteRow(String name, bool yes) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.006,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    yes
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: yes
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: height * 0.022,
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: height * 0.02,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    yes ? 'Yes' : 'No',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: height * 0.018,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          Widget buildVoteOverlay() {
                            final cardH = height * 0.2;
                            final cardW = width * 0.28;

                            // Optimistic “I voted” (local) OR confirmed from Firestore
                            final iVotedNow =
                                _myVoteCastLocal || g.iVoted;
                            final allIn = g.allVotesIn ||
                                g.phase == 'voting_results';

                            // Build tallies and names when all votes are in
                            List<Widget> results = [];
                            if (allIn) {
                              int yesCount = 0;
                              int noCount = 0;
                              g.votes.forEach((uid, val) {
                                final name =
                                    g.nicknameCache[uid] ?? 'Wizard';
                                results.add(voteRow(name, val));
                                if (val) {
                                  yesCount++;
                                } else {
                                  noCount++;
                                }
                              });

                              final passed = yesCount > noCount;
                              results.add(SizedBox(height: height * 0.02));
                              results.add(
                                Text(
                                  passed
                                      ? 'Election Passed'
                                      : 'Election Failed',
                                  style: TextStyle(
                                    color: passed
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: height * 0.024,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            Widget voteCard(
                              String asset,
                              VoidCallback onTap,
                              int index, {
                              String label = '',
                            }) {
                              return _StaggerFadeScale(
                                delayMs: 150 * index,
                                durationMs: 420,
                                beginScale: 0.92,
                                endScale: 1.0,
                                child: InkWell(
                                  onTap: () async {
                                    if (iVotedNow) return;
                                    setState(() {
                                      _myVoteCastLocal = true;
                                    }); // instant feedback
                                    await g.castVote(asset.contains('yes'));
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                        ),
                                        padding: EdgeInsets.all(
                                          width * 0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: Image.asset(
                                          asset,
                                          height: cardH,
                                          width: cardW,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      if (label.isNotEmpty)
                                        SizedBox(
                                          height: height * 0.008,
                                        ),
                                      if (label.isNotEmpty)
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: height * 0.018,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Three states on the SAME dark overlay:
                            // 1) Not voted yet -> show Yes/No cards
                            // 2) Voted but not all in -> “Vote has been cast”
                            // 3) All in -> show tally + result
                            Widget inner;
                            if (!iVotedNow && !allIn) {
                              inner = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Vote to elect ${nomineeName()} as Spellcaster',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: height * 0.026,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.018),
                                  Text(
                                    'Choose wisely, wizard…',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: height * 0.018,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.03),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      voteCard(
                                        'assets/images/game-assets/board/yesCard.png',
                                        () {},
                                        0,
                                        label: 'Yes',
                                      ),
                                      voteCard(
                                        'assets/images/game-assets/board/noCard.png',
                                        () {},
                                        1,
                                        label: 'No',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else if (iVotedNow && !allIn) {
                              inner = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.how_to_vote,
                                    color: Colors.white70,
                                    size: height * 0.06,
                                  ),
                                  SizedBox(height: height * 0.015),
                                  Text(
                                    'Vote has been cast — waiting for others…',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: height * 0.022,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.01),
                                  Text(
                                    '${g.votedCount}/${g.eligibleVoters} votes in',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: height * 0.018,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  const CircularProgressIndicator(
                                    color: Colors.white70,
                                  ),
                                ],
                              );
                            } else {
                              // allIn == true
                              inner = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Voting Results',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: height * 0.026,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  ...results,
                                  SizedBox(height: height * 0.02),
                                  Text(
                                    'Continuing…',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: height * 0.016,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black.withOpacity(0.68),
                                child: Center(child: inner),
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              // Top-left back button (host only)
                              if (_uid == _creatorId)
                                Positioned(
                                  top: height * 0.02,
                                  left: width * 0.03,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                    ),
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                        Colors.black.withOpacity(0.4),
                                      ),
                                      padding:
                                          MaterialStateProperty.all(
                                        EdgeInsets.all(width * 0.025),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.black87,
                                          title: const Text(
                                            "End Game?",
                                            style: TextStyle(
                                                color: Colors.white),
                                          ),
                                          content: const Text(
                                            "Send everyone back to the lobby?",
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.amberAccent,
                                              ),
                                              child: const Text("Yes, return"),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await FirebaseFirestore.instance
                                            .collection('states')
                                            .doc(widget.code)
                                            .delete();
                                        await _firebase
                                            .resetLobby(widget.code);
                                      }
                                    },
                                  ),
                                ),

                              // Top-center role + exec info
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: height * 0.02,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      rolePill(
                                        isHM
                                            ? 'You are the Headmaster'
                                            : (isSC
                                                ? 'You are the Spellcaster'
                                                : 'Waiting for others...'),
                                      ),
                                      if (activeExecText != null)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: height * 0.008,
                                          ),
                                          child: Text(
                                            activeExecText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.amberAccent,
                                              fontSize: height * 0.018,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      else if (nextExecHint != null)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: height * 0.008,
                                          ),
                                          child: Text(
                                            nextExecHint,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: height * 0.017,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Policy card overlays
                              if (showHMDiscard)
                                buildCardOverlay(
                                  'Choose 1 spell to discard',
                                  g.pendingCards,
                                  true,
                                ),

                              if (showSCChoose)
                                buildCardOverlay(
                                  'Choose 1 spell to cast',
                                  g.pendingCards,
                                  false,
                                ),

                              if (showVoting) buildVoteOverlay(),

                              // EXECUTIVE POWER - INVESTIGATE SELECTION
                              if (g.phase == 'executive_investigate')
                                Stack(
                                  children: [
                                    if (!isHM)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black
                                              .withOpacity(0.55),
                                          child: Center(
                                            child: Text(
                                              "Headmaster is investigating…",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: height * 0.028,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    if (isHM)
                                      Positioned(
                                        top: height * 0.18,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Text(
                                            "Tap a wizard to investigate their loyalty",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: height * 0.024,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                              // EXECUTIVE POWER -> INVESTIGATE RESULT
                              if (g.phase == 'executive_investigate_result')
                                Stack(
                                  children: [
                                    if (!isHM)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black
                                              .withOpacity(0.60),
                                          child: Center(
                                            child: Text(
                                              "Headmaster is reviewing loyalty…",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: height * 0.026,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isHM)
                                      Center(
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            height * 0.025,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withOpacity(0.75),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Loyalty Revealed",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: height * 0.030,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: height * 0.02),
                                              if (g.executiveTarget != null) ...[
                                                Text(
                                                  "${g.nicknameCache[g.executiveTarget] ?? "Wizard"} is a:",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: height * 0.022,
                                                  ),
                                                ),
                                                Builder(
                                                  builder: (_) {
                                                    final targetRole = g.players
                                                        .firstWhere((p) =>
                                                            p.username ==
                                                            g.executiveTarget!)
                                                        .role;
                                                    final loyalty =
                                                        (targetRole ==
                                                                'wizard')
                                                            ? 'WIZARD'
                                                            : 'WARLOCK';
                                                    final loyaltyColor =
                                                        (loyalty ==
                                                                'WARLOCK')
                                                            ? Colors
                                                                .redAccent
                                                            : Colors
                                                                .lightBlueAccent;

                                                    return Text(
                                                      loyalty,
                                                      style: TextStyle(
                                                        color: loyaltyColor,
                                                        fontSize:
                                                            height * 0.033,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                              SizedBox(
                                                  height: height * 0.035),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    FirebaseController()
                                                        .endExecutive(
                                                  widget.code,
                                                ),
                                                child: const Text("Continue"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                // EXECUTIVE POWER -> PEEK 3 CARDS
                                if (g.phase == 'executive_peek3')
                                  Stack(
                                    children: [
                                      if (!isHM)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black.withOpacity(0.60),
                                            child: Center(
                                              child: Text(
                                                "Headmaster is foreseeing future spells…",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: height * 0.026,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      
                                      if (isHM)
                                        AnimatedOpacity(
                                          opacity: 1,
                                          duration: const Duration(milliseconds: 300),
                                          child: Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            color: Colors.black.withOpacity(0.65),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Next Three Spells",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: height * 0.028,
                                                      fontWeight: FontWeight.bold,
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
                                                          g.pendingExecutiveCards.length,
                                                          (i) {
                                                            final type = g.pendingExecutiveCards[i];
                                                            final asset = type == 'charm'
                                                                ? 'assets/images/game-assets/board/charmCard.png'
                                                                : 'assets/images/game-assets/board/curseCard.png';

                                                            return _StaggerFadeScale(
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
                                                    onPressed: () => FirebaseController().endExecutive(widget.code),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      foregroundColor: Colors.black,
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: width * 0.08,
                                                        vertical: height * 0.015,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Continue",
                                                      style: TextStyle(
                                                        fontSize: height * 0.022,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                              // Spectator hint (only if no blocking overlays)
                              if (!showHMDiscard &&
                                  !showSCChoose &&
                                  !showVoting &&
                                  g.phase != 'executive_investigate' &&
                                  g.phase != 'executive_investigate_result' &&
                                  g.phase != 'executive_peek3')
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: height * 0.05,
                                    ),
                                    child: Text(
                                      _spectatorHint(g),
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: height * 0.018,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _spectatorHint(WizardGameView g) {
    switch (g.phase) {
      case 'start':
        return 'Headmaster: pick a Spellcaster by tapping a hat.';
      case 'voting':
        return 'Voting in progress…';
      case 'hm_discard':
        return 'Headmaster is discarding 1 card...';
      case 'sc_choose':
        return 'Spellcaster is choosing a card to enact...';
      case 'executive_investigate':
        return 'Headmaster is using Investigate Loyalty…';
      case 'executive_investigate_result':
        return 'Investigation complete – resolving…';
      case 'executive_peek3':
        return 'Headmaster is peeking at the next three spells…';
      case 'resolving':
        return 'Resolving policy and rotating Headmaster...';
      default:
        return 'Waiting...';
    }
  }

  String? _nextExecutiveWarning(WizardGameView g) {
    final int playerCount = g.players.length;
    final int curses = g.curses;

    // Never show warning DURING an executive power
    if (g.executiveActive == true) return null;

    //5-6 PLAYERS
    if (playerCount >= 1 && playerCount <= 6) {
      if (curses == 2) return "If the next Curse is enacted: Foresee three spells.";
      if (curses == 3) return "If the next Curse is enacted: Execute a wizard.";
    }

    //7-8 PLAYERS
    if (playerCount >= 7 && playerCount <= 8) {
      if (curses == 1) return "If the next Curse is enacted: Investigate Loyalty.";
      if (curses == 2) return "If the next Curse is enacted: Foresee three spells.";
      if (curses == 3) return "If the next Curse is enacted: Execute a wizard.";
    }

    //9-10 PLAYERS
    if (playerCount >= 9 && playerCount <= 10) {
      if (curses == 0) return "If the next Curse is enacted: Investigate Loyalty.";
      if (curses == 1) return "If the next Curse is enacted: Investigate Loyalty.";
      if (curses == 2) return "If the next Curse is enacted: Foresee three spells.";
      if (curses == 3) return "If the next Curse is enacted: Execute a wizard.";
    }

    return null;
  }
}

// Simple helper to add a start delay and fade/scale animation to any child.
class _StaggerFadeScale extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final double beginScale;
  final double endScale;

  const _StaggerFadeScale({
    required this.child,
    required this.delayMs,
    required this.durationMs,
    this.beginScale = 0.9,
    this.endScale = 1.0,
  });

  @override
  State<_StaggerFadeScale> createState() => _StaggerFadeScaleState();
}

class _StaggerFadeScaleState extends State<_StaggerFadeScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Start after delay
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
