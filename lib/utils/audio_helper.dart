import 'dart:async';
import 'package:flame_audio/flame_audio.dart';

class AudioHelper {
  static bool _initialized = false;
  static double _targetVolume = 0.7;

  static Future<void> init() async {
    if (_initialized) return;
    await FlameAudio.bgm.initialize();

    // Preload your tracks so they start instantly later
    await FlameAudio.audioCache.loadAll([
      'TavernLobbyMusic.wav',
      'TavernMusic.wav',
    ]);

    _initialized = true;
  }

  /// Play a track on loop after a short delay (prevents race conditions during screen change)
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

  /// Crossfade to another track with smooth fade out and fade in
  static Future<void> fadeTo(
    String filename, {
    double volume = 0.7,
    int delayMs = 400,
    Duration step = const Duration(milliseconds: 90),
  }) async {
    await init();
    await Future.delayed(Duration(milliseconds: delayMs));

    // Fade out current track
    for (double v = _targetVolume; v > 0.0; v -= 0.1) {
      await FlameAudio.bgm.audioPlayer.setVolume(v.clamp(0.0, 1.0));
      await Future.delayed(step);
    }

    await FlameAudio.bgm.stop();
    await FlameAudio.bgm.play(filename, volume: 0.0);

    // Fade in new track
    _targetVolume = volume.clamp(0.0, 1.0);
    for (double v = 0.0; v < _targetVolume; v += 0.1) {
      await FlameAudio.bgm.audioPlayer.setVolume(v.clamp(0.0, 1.0));
      await Future.delayed(step);
    }

    await FlameAudio.bgm.audioPlayer.setVolume(_targetVolume);
  }

  /// Manually adjust current volume
  static Future<void> setVolume(double v) async {
    await init();
    _targetVolume = v.clamp(0.0, 1.0);
    await FlameAudio.bgm.audioPlayer.setVolume(_targetVolume);
  }

  /// Stop all background music
  static Future<void> stop() async {
    await FlameAudio.bgm.stop();
  }
}
