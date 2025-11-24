import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/views/overlays/overlay_animations.dart';

class VotingOverlay extends StatelessWidget {
  final WizardGameView game;
  final double width;
  final double height;
  final bool myVoteCastLocal;
  final Future<void> Function(bool yes) onVote;

  const VotingOverlay({
    super.key,
    required this.game,
    required this.width,
    required this.height,
    required this.myVoteCastLocal,
    required this.onVote,
  });

  String _nomineeName() {
    if (game.nomineeIndex == null ||
        game.nomineeIndex! < 0 ||
        game.nomineeIndex! >= game.players.length) {
      return 'the Spellcaster';
    }
    final uid = game.players[game.nomineeIndex!].username;
    return game.nicknameCache[uid] ?? 'the Spellcaster';
  }

  @override
  Widget build(BuildContext context) {
    final cardH = height * 0.2;
    final cardW = width * 0.28;

    final iVotedNow = myVoteCastLocal || game.iVoted;
    final allIn = game.allVotesIn || game.phase == 'voting_results';

    // Build tallies and names when all votes are in
    List<Widget> results = [];
    if (allIn) {
      int yesCount = 0;
      int noCount = 0;
      game.votes.forEach((uid, val) {
        final name = game.nicknameCache[uid] ?? 'Wizard';
        results.add(_voteRow(name, val));
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
          passed ? 'Election Passed' : 'Election Failed',
          style: TextStyle(
            color: passed ? Colors.greenAccent : Colors.redAccent,
            fontSize: height * 0.024,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    final isHM = game.myUid == game.players[game.headmasterIndex].username;

    Widget inner;
    if (!isHM && !iVotedNow && !allIn) {
      // 1) Not voted yet -> show Yes/No cards
      inner = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vote to elect ${_nomineeName()} as Spellcaster',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.026,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: height * 0.018),
          const Text(
            'Choose wisely, wizard…',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          SizedBox(height: height * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _voteCard(
                asset:
                    'assets/images/game-assets/board/yesCard.png',
                label: 'Yes',
                index: 0,
                cardH: cardH,
                cardW: cardW,
                onTap: () async {
                  if (iVotedNow) return;
                  await onVote(true);
                },
              ),
              _voteCard(
                asset:
                    'assets/images/game-assets/board/noCard.png',
                label: 'No',
                index: 1,
                cardH: cardH,
                cardW: cardW,
                onTap: () async {
                  if (iVotedNow) return;
                  await onVote(false);
                },
              ),
            ],
          ),
        ],
      );
    } else if (iVotedNow && !allIn) {
      // 2) Voted but not all in -> “Vote has been cast”
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
            '${game.votedCount}/${game.eligibleVoters} votes in',
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
      // 3) All in -> show tally + result
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

  Widget _voteRow(String name, bool yes) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: height * 0.006,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            yes ? Icons.check_circle : Icons.cancel,
            color: yes ? Colors.greenAccent : Colors.redAccent,
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

  Widget _voteCard({
    required String asset,
    required String label,
    required int index,
    required double cardH,
    required double cardW,
    required VoidCallback onTap,
  }) {
    return StaggerFadeScale(
      delayMs: 150 * index,
      durationMs: 420,
      beginScale: 0.92,
      endScale: 1.0,
      child: InkWell(
        onTap: onTap,
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
                borderRadius: BorderRadius.circular(12),
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
            SizedBox(
              height: height * 0.008,
            ),
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
}
