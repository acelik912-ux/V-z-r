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

  /// Ebeveyn panelindeki hız ayarını doğal sesin hızına çevirir (0.25-0.7 -> 0.9-1.45).
  static double get neuralSpeed => 0.9 + (game.speechRate - 0.25) / 0.45 * 0.55;

  static Future<void> say(String text) async {
    if (game.neuralVoice && !NeuralVoice.failed) {
      if (!NeuralVoice.ready) await NeuralVoice.whenReady();
      if (NeuralVoice.ready) {
        try {
          await _tts.stop();
        } catch (_) {}
        if (await NeuralVoice.say(text, neuralSpeed)) return;
      }
    }
    await NeuralVoice.stop();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }
}
