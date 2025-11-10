
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';

class GameController {
  int countdown = 60;
  final _timerStream = StreamController<int>.broadcast();
  Stream<int> get timerStream => _timerStream.stream;

  Timer? _timer;
  final FirebaseController _firebase = FirebaseController();

  // Call this on the host device
  void startCountdown(String lobbyId, void Function() onComplete) {
    countdown = 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdown--;
      _timerStream.add(countdown);

      await FirebaseFirestore.instance
          .collection('states')
          .doc(lobbyId)
          .set({'phase': 'countdown', 'time': countdown},
               SetOptions(merge: true));

      if (countdown <= 0) {
        timer.cancel();
        await endGame(lobbyId);
        onComplete();
      }
    });
  }

  Future<void> endGame(String lobbyId) async {
    // delete state and change lobby back to waiting
    await FirebaseFirestore.instance.collection('states').doc(lobbyId).delete();
    await _firebase.resetLobby(lobbyId);
  }

  void dispose() {
    _timer?.cancel();
    _timerStream.close();
  }
}
