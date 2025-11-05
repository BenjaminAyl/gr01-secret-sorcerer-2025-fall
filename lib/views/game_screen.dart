import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final String code;
  const GameScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('states').doc(code);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) {
          return Scaffold(body: Center(child: Text('Waiting for game state…')));
        }

        final data = snap.data!.data()!;
        final phase = data['phase'];
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Game: $code', style: const TextStyle(color: Colors.white)),
                Text('Phase: $phase', style: const TextStyle(color: Colors.white)),
                Text('Players: ${players.length}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }
}
