import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioHelper {
  static bool _initialized = false;
  static bool _isFading = false;

  // Music and SFX Volumes
  static double _targetVolume = 1.0; 
  static double _sfxVolume = 1.0;

  static const String _musicKey = 'musicVolume';
  static const String _sfxKey = 'sfxVolume';

  // Public getters (useful for dialog initial values)
  static double get musicVolume => _targetVolume;
  static double get sfxVolume => _sfxVolume;

  static Future<void> _loadVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    _targetVolume = prefs.getDouble(_musicKey) ?? _targetVolume;
    _sfxVolume = prefs.getDouble(_sfxKey) ?? _sfxVolume;
  }

  static Future<void> _saveVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicKey, _targetVolume);
    await prefs.setDouble(_sfxKey, _sfxVolume);
  }

  static Future<void> init() async {
    if (_initialized) return;

    // Load persisted volumes before starting audio
    await _loadVolumes();

    await FlameAudio.bgm.initialize();

    // Preload your tracks so they start instantly later
    await FlameAudio.audioCache.loadAll([
      'TavernLobbyMusic.wav',
      'TavernMusic.wav',
      'role_reveal.mp3',
      'backButton.wav',
      'card_pick_up.mp3',
      'charmCast.wav',
      'curseCast.wav',
      'enterButton.wav',
      'hostJoin.wav',
      'paperRoll.mp3',
      'TavernThemeMusic.wav',
      'drawDiscard.wav',
    ]);

    _initialized = true;
  }

  //Play a track on loop after a short delay (prevents race conditions during screen change)
  static Future<void> playLoop(
    String filename, {
    double volume = 0.7, // parameter not actually used
    int delayMs = 400,
  }) async {
    await init();
    await Future.delayed(Duration(milliseconds: delayMs));

    // Use the current persisted music volume
    final effectiveVolume = _targetVolume.clamp(0.0, 1.0);

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(filename, volume: effectiveVolume);
    } catch (e) {
      // Retry once if audio engine wasn’t ready
      await Future.delayed(const Duration(milliseconds: 200));
      await FlameAudio.bgm.play(filename, volume: effectiveVolume);
    }
  }

  // Crossfade to another track with smooth fade out and fade in
  static Future<void> crossfade(
    String filename, {
    double volume = 0.7, // parameter not actually used
    Duration duration = const Duration(seconds: 1),
  }) async {
    await init();

    if (_isFading) return; //Prevent overlapping fades
    _isFading = true;

    final player = FlameAudio.bgm.audioPlayer;

    // Use current music volume as the target
    final double startVol = player.volume;
    final double endVol = _targetVolume.clamp(0.0, 1.0);

    const int steps = 30;
    final double dt = duration.inMilliseconds / steps;

    // Fade out current
    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final v = startVol * (1 - t);
      await player.setVolume(v.clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: dt.round()));
    }

    // Switch track without stopping audio engine
    await FlameAudio.bgm.play(filename, volume: 0.0);

    // Fade in new
    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final v = endVol * t;
      await player.setVolume(v.clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: dt.round()));
    }

    await player.setVolume(endVol);
    _isFading = false;
  }

  // Setter for music volume
  static Future<void> setVolume(double v) async {
    await init();
    _targetVolume = v.clamp(0.0, 1.0);
    await FlameAudio.bgm.audioPlayer.setVolume(_targetVolume);
    await _saveVolumes();
  }

  // Setter for SFX Volume
  static Future<void> setSfxVolume(double v) async {
    await init();
    _sfxVolume = v.clamp(0.0, 1.0);
    await _saveVolumes();
  }

  // Volume settings resetter
  static Future<void> resetVolumes() async {
    await setVolume(1.0);
    await setSfxVolume(1.0);
  }

  // Stop all background music
  static Future<void> stop() async {
    await FlameAudio.bgm.stop();
  }

  static Future<void> playSFX(
    String filename, {
    double volume = 1.0, // per-effect multiplier
  }) async {
    await init();
    // Global SFX volume scales the individual effect volume
    final effectiveVolume = (volume * _sfxVolume).clamp(0.0, 1.0);
    FlameAudio.play(filename, volume: effectiveVolume);
  }
}
