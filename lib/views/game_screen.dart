import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/game_controller.dart';
import 'package:secret_sorcerer/views/game_view.dart';

class GameScreen extends StatefulWidget {
  final String code;
  const GameScreen({super.key, required this.code});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _firebase = FirebaseController();
  final _controller = GameController();
  late final WizardGameView _game;
  String? _creatorId;
  String? _uid;
  bool _navigatedOut = false; // ✅ prevents double navigation

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _game = WizardGameView();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔹 Host-only timer start
  void _maybeStartHostTimer() {
    if (_creatorId != null && _uid == _creatorId) {
      _controller.startCountdown(widget.code, () {
        // Host triggers Firestore reset through endGame()
      });
    }
  }

  /// 🔹 Clean navigation back to the lobby
  void _goBackToLobby() {
    if (_navigatedOut || !mounted) return; // guard against duplicates
    _navigatedOut = true;
    context.go('/lobby/${widget.code}');
  }

  @override
  Widget build(BuildContext context) {
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbies').doc(widget.code);
    final stateRef =
        FirebaseFirestore.instance.collection('states').doc(widget.code);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: lobbyRef.snapshots(),
      builder: (context, lobbySnap) {
        if (!lobbySnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Lobby deleted → everyone goes home
        if (!lobbySnap.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
          return const SizedBox.shrink();
        }

        final lobby = lobbySnap.data!.data()!;
        _creatorId ??= lobby['creatorId'] as String?;
        final status = lobby['status'];

        // ✅ Lobby reset → go back to lobby
        if (status == 'waiting') {
          WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
        }

        _maybeStartHostTimer();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stateRef.snapshots(),
          builder: (context, stateSnap) {
            if (!stateSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ✅ Game state deleted → end of round → return to lobby
            if (!stateSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
              return const SizedBox.shrink();
            }

            final data = stateSnap.data!.data()!;
            final phase = data['phase'] ?? 'countdown';
            final time = (data['time'] ?? 10) as int;
            _game.updateCountdown(time);

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  GameWidget(game: _game),
                  // HUD overlay for timer and info
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Lobby: ${widget.code}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Phase: $phase',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Time: $time',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
