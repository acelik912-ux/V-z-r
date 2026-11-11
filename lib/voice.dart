import 'package:flutter_tts/flutter_tts.dart';

import 'neural_voice.dart';
import 'state.dart';

class VoiceInfo {
  final String name;
  final String locale;
  final bool network;
  const VoiceInfo(this.name, this.locale, this.network);
}

/// Telefonun Türkçe sesiyle konuşma. Hata olursa oyun sessizce devam eder.
class Voice {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setVolume(1.0);
      await apply();
      if (game.voiceName.isEmpty) {
        final best = await bestVoice();
        if (best != null) {
          await _tts.setVoice({'name': best.name, 'locale': best.locale});
        }
      }
    } catch (_) {}
  }

  /// Ebeveyn panelindeki ses ayarlarını uygular.
  static Future<void> apply() async {
    try {
      await _tts.setSpeechRate(game.speechRate);
      await _tts.setPitch(game.speechPitch);
      if (game.voiceName.isNotEmpty) {
        await _tts.setVoice({'name': game.voiceName, 'locale': game.voiceLocale});
      }
    } catch (_) {}
  }

  /// Telefondaki Türkçe sesler (çevrimdışı olanlar önce).
  static Future<List<VoiceInfo>> turkishVoices() async {
    try {
      final raw = await _tts.getVoices;
      final out = <VoiceInfo>[];
      if (raw is List) {
        for (final v in raw) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';
            if (!locale.toLowerCase().startsWith('tr')) continue;
            final net = v['network_required']?.toString() == '1' ||
                v['network_required'] == true ||
                name.toLowerCase().contains('network');
            out.add(VoiceInfo(name, locale, net));
          }
        }
      }
      out.sort((a, b) {
        if (a.network != b.network) return a.network ? 1 : -1;
        return a.name.compareTo(b.name);
      });
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<VoiceInfo?> bestVoice() async {
    final list = await turkishVoices();
    return list.isEmpty ? null : list.first;
  }

  /// Ebeveyn panelindeki hız ayarını doğal sesin hızına çevirir (0.25-0.7 -> 0.7-1.2).
  /// Varsayılan 0.5 -> ~0.98: çocuk için net ve acelesiz.
  static double get neuralSpeed => 0.7 + (game.speechRate - 0.25) / 0.45 * 0.5;

  /// Doğal ses tek hece ve kısa kelimeleri yutabiliyor; onları biraz yavaş ve
  /// cümle gibi (noktalı) okut. Sondaki noktalama son sesi tamamlatır.
  static (String, double) _prep(String text) {
    var t = text.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return (t, neuralSpeed);
    final last = t[t.length - 1];
    if (!'.!?,;:…'.contains(last)) t = '$t.';
    final words = t.split(' ').length;
    final letters = t.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '').length;
    var sp = neuralSpeed;
    if (letters <= 4) {
      sp *= 0.78; // tek hece: "ka", "nek"
    } else if (words <= 2) {
      sp *= 0.88; // tek kelime: "inek", "Aferin!"
    }
    return (t, sp);
  }

  static bool _en = false;

  /// Testlerde sesi tamamen kapatmak için.
  static bool muted = false;

  /// İngilizce cümle (telefonun İngilizce sesiyle).
  static Future<void> sayEn(String text) async {
    if (muted) return;
    await NeuralVoice.stop();
    try {
      await _tts.stop();
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
      _en = true;
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> _backToTurkish() async {
    if (!_en) return;
    _en = false;
    try {
      await _tts.setLanguage('tr-TR');
      await apply();
    } catch (_) {}
  }

  static Future<void> say(String text) async {
    if (muted) return;
    await _backToTurkish();
    if (game.neuralVoice && !NeuralVoice.failed) {
      if (!NeuralVoice.ready) await NeuralVoice.whenReady();
      if (NeuralVoice.ready) {
        try {
          await _tts.stop();
        } catch (_) {}
        final (t, sp) = _prep(text);
        if (await NeuralVoice.say(t, sp)) return;
      }
    }
    await NeuralVoice.stop();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }
}
