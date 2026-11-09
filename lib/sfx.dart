import 'package:audioplayers/audioplayers.dart';

import 'state.dart';

/// Ses efektleri. Hata olursa oyun sessizce devam eder.
class Sfx {
  static final List<AudioPlayer> _pool = [];
  static int _next = 0;
  static AudioPlayer? _engine;
  static double _engineRate = 1;

  static Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (_) {}
    for (var i = 0; i < 5; i++) {
      final p = AudioPlayer();
      try {
        await p.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      _pool.add(p);
    }
  }

  static Future<void> play(String name, {double volume = 1}) async {
    if (!game.sfxOn || _pool.isEmpty) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await p.stop();
      await p.play(AssetSource('sfx/$name.wav'), volume: volume);
    } catch (_) {}
  }

  static Future<void> horn(int i) => play('horn${i.clamp(0, 3)}');

  static Future<void> engineStart() async {
    if (!game.sfxOn) return;
    try {
      _engine ??= AudioPlayer();
      await _engine!.setReleaseMode(ReleaseMode.loop);
      _engineRate = 1;
      await _engine!.play(AssetSource('sfx/engine.wav'), volume: 0.32);
    } catch (_) {}
  }

  /// Motor sesinin perdesi (hız). Sadece belirgin değişimde uygulanır.
  static Future<void> engineRate(double r) async {
    if (_engine == null || (r - _engineRate).abs() < 0.08) return;
    _engineRate = r;
    try {
      await _engine!.setPlaybackRate(r);
    } catch (_) {}
  }

  static Future<void> engineStop() async {
    try {
      await _engine?.stop();
    } catch (_) {}
  }
}
