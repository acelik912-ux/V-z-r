import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Telefonda internetsiz çalışan doğal Türkçe erkek sesi (Piper / sherpa-onnx).
/// Ses ayrı bir iş parçacığında üretilir, üretilen cümleler önbelleğe alınır.
class NeuralVoice {
  static SendPort? _worker;
  static bool ready = false;
  static bool failed = false;
  static String _cacheDir = '';
  static final AudioPlayer _player = AudioPlayer();
  static int _reqId = 0;
  static final Map<int, Completer<bool>> _pending = {};
  static final Completer<void> _readyC = Completer<void>();

  /// Hazır olana (ya da başarısız olana) kadar bekler.
  static Future<void> whenReady({Duration timeout = const Duration(seconds: 8)}) =>
      _readyC.future.timeout(timeout, onTimeout: () {});

  static void _finish() {
    if (!_readyC.isCompleted) _readyC.complete();
  }

  static Future<void> init() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/tts_v1');
      final marker = File('${dir.path}/.tamam');
      if (!marker.existsSync()) {
        dir.createSync(recursive: true);
        for (final name in ['model.onnx', 'tokens.txt']) {
          final data = await rootBundle.load('assets/tts/$name');
          await File('${dir.path}/$name')
              .writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
        }
        final zip = await rootBundle.load('assets/tts/espeak.zip');
        final archive = ZipDecoder().decodeBytes(zip.buffer.asUint8List(zip.offsetInBytes, zip.lengthInBytes));
        for (final f in archive) {
          final out = '${dir.path}/espeak-ng-data/${f.name}';
          if (f.isFile) {
            File(out)
              ..createSync(recursive: true)
              ..writeAsBytesSync(f.content as List<int>);
          } else {
            Directory(out).createSync(recursive: true);
          }
        }
        marker.writeAsStringSync('1');
      }
      final tmp = await getTemporaryDirectory();
      _cacheDir = '${tmp.path}/ses_onbellek';
      Directory(_cacheDir).createSync(recursive: true);

      final rp = ReceivePort();
      rp.listen((msg) {
        if (msg is SendPort) {
          _worker = msg;
        } else if (msg == 'hazir') {
          ready = true;
          _finish();
        } else if (msg is String) {
          failed = true;
          _finish();
        } else if (msg is List) {
          _pending.remove(msg[0] as int)?.complete(msg[1] as bool);
        }
      });
      await Isolate.spawn(_workerMain, [rp.sendPort, dir.path]);
    } catch (_) {
      failed = true;
      _finish();
    }
  }

  /// Metni okur. Başarısız olursa false döner (o zaman telefonun sesi kullanılır).
  static Future<bool> say(String text, double speed) async {
    final w = _worker;
    if (!ready || w == null) return false;
    final my = ++_reqId;
    try {
      await _player.stop();
      final key = '${text.length}_${text.hashCode.toUnsigned(32)}_${(speed * 100).round()}';
      final path = '$_cacheDir/$key.wav';
      if (!File(path).existsSync()) {
        final c = Completer<bool>();
        _pending[my] = c;
        w.send([my, text, speed, path]);
        final ok = await c.future.timeout(const Duration(seconds: 10), onTimeout: () => false);
        if (!ok) return false;
      }
      if (my != _reqId) return true; // bu arada yeni bir konuşma başladı
      await _player.play(DeviceFileSource(path));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    _reqId++;
    try {
      await _player.stop();
    } catch (_) {}
  }
}

void _workerMain(List<Object> args) {
  final main = args[0] as SendPort;
  final dir = args[1] as String;
  final rp = ReceivePort();
  main.send(rp.sendPort);
  sherpa_onnx.OfflineTts? tts;
  try {
    sherpa_onnx.initBindings();
    final vits = sherpa_onnx.OfflineTtsVitsModelConfig(
      model: '$dir/model.onnx',
      tokens: '$dir/tokens.txt',
      dataDir: '$dir/espeak-ng-data',
    );
    final mc = sherpa_onnx.OfflineTtsModelConfig(vits: vits, numThreads: 2, debug: false, provider: 'cpu');
    tts = sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(model: mc, maxNumSenetences: 1));
    main.send('hazir');
  } catch (e) {
    main.send('hata $e');
    return;
  }
  final engine = tts;
  rp.listen((msg) {
    final m = msg as List;
    final id = m[0] as int;
    try {
      final audio = engine.generate(text: m[1] as String, sid: 0, speed: m[2] as double);
      final ok = audio.samples.isNotEmpty &&
          sherpa_onnx.writeWave(filename: m[3] as String, samples: audio.samples, sampleRate: audio.sampleRate);
      main.send([id, ok]);
    } catch (_) {
      main.send([id, false]);
    }
  });
}
