import 'package:flutter_tts/flutter_tts.dart';

/// Telefonun Türkçe sesiyle konuşma. Hata olursa oyun sessizce devam eder.
class Voice {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  static Future<void> say(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }
}
