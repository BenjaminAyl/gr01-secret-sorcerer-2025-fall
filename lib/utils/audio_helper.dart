import 'dart:async';
import 'package:flame_audio/flame_audio.dart';

class AudioHelper {
  static bool _initialized = false;
  static double _targetVolume = 0.7;
  static bool _isFading = false;

  static Future<void> init() async {
    if (_initialized) return;
    await FlameAudio.bgm.initialize();

    //Preload your tracks so they start instantly later
    await FlameAudio.audioCache.loadAll([
      'TavernLobbyMusic.wav',
      'TavernMusic.wav',
      'role_reveal.mp3',
    ]);

    _initialized = true;
  }

  //Play a track on loop after a short delay (prevents race conditions during screen change)
  static Future<void> playLoop(
    String filename, {
    double volume = 0.7,
    int delayMs = 400,
  }) async {
    await init();
    await Future.delayed(Duration(milliseconds: delayMs));

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(filename, volume: volume);
      _targetVolume = volume;
    } catch (e) {
      // Retry once if audio engine wasn’t ready
      await Future.delayed(const Duration(milliseconds: 200));
      await FlameAudio.bgm.play(filename, volume: volume);
      _targetVolume = volume;
    }
  }

  //Crossfade to another track with smooth fade out and fade in
  static Future<void> crossfade(String filename,
      {double volume = 0.7, Duration duration = const Duration(seconds: 1)}) async {
    await init();

    if (_isFading) return; //Prevent overlapping fades
    _isFading = true;

    final player = FlameAudio.bgm.audioPlayer;

    // Save current
    final double startVol = _targetVolume;
    final int steps = 30;
    final double dt = duration.inMilliseconds / steps;

    //Fade out current
    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final v = startVol * (1 - t);
      player.setVolume(v);
      await Future.delayed(Duration(milliseconds: dt.round()));
    }

    // Switch track without stopping audio engine
    await FlameAudio.bgm.play(filename, volume: 0.0);

    // Fade in new
    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final v = volume * t;
      player.setVolume(v);
      await Future.delayed(Duration(milliseconds: dt.round()));
    }

    player.setVolume(volume);
    _targetVolume = volume;

    _isFading = false;
  }

  //Manually adjust current volume
  static Future<void> setVolume(double v) async {
    await init();
    _targetVolume = v.clamp(0.0, 1.0);
    await FlameAudio.bgm.audioPlayer.setVolume(_targetVolume);
  }

  //Stop all background music
  static Future<void> stop() async {
    await FlameAudio.bgm.stop();
  }
}
