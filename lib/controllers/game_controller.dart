import 'dart:async';

class GameController {
  int countdown = 10;
  final StreamController<int> _timerStream = StreamController<int>.broadcast();
  Stream<int> get timerStream => _timerStream.stream;

  Timer? _timer;

  void startCountdown(void Function() onComplete) {
    countdown = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      _timerStream.add(countdown);
      if (countdown <= 0) {
        timer.cancel();
        onComplete();
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timerStream.close();
  }
}
