import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vizir/car3d/car_model.dart';
import 'package:vizir/car3d/car_view.dart';
import 'package:vizir/car3d/renderer.dart';

/// CI'da araba görsellerini PNG olarak üretir (previews/ klasörü).
Future<void> _sheet(String name, List<(CarConfig, double, double, bool)> cars, {int cols = 3, double cell = 400}) async {
  final rows = (cars.length / cols).ceil();
  final w = cols * cell, h = rows * cell * 0.75;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFDDE3E6));
  for (var i = 0; i < cars.length; i++) {
    final (cfg, yaw, pitch, lights) = cars[i];
    final cx = (i % cols) * cell + cell / 2;
    final cy = (i ~/ cols) * cell * 0.75 + cell * 0.52;
    final cam = Camera(center: Offset(cx, cy), scale: cell / 6.0, yaw: yaw, pitch: pitch);
    paintCar(canvas, cfg, cam, lightsOn: lights, reflection: true);
  }
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('previews').createSync(recursive: true);
  File('previews/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _custom(String name, double w, double h, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, Rect.fromLTWH(0, 0, w, h));
  draw(canvas);
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('previews').createSync(recursive: true);
  File('previews/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('3D araba önizlemeleri', (tester) async {
    await tester.runAsync(() async {
      await _sheet('govdeler', [
        for (var i = 0; i < 11; i++) (CarConfig(body: i, color: [0, 1, 3, 4, 2, 4, 8, 0, 6, 0, 1][i]), 0.75, 0.3, false),
        (const CarConfig(body: 1, color: 2, roof: 4), 0.75, 0.3, false),
      ], cols: 4, cell: 360);
      await _sheet('aksesuarlar', [
        (const CarConfig(body: 0, color: 2, sticker: 3, stickerColor: 3, rim: 3), 1.5708, 0.1, false),
        (const CarConfig(body: 1, color: 7, sticker: 4, stickerColor: 2, finish: 2), -1.5708, 0.1, false),
        (const CarConfig(body: 2, color: 8, sticker: 5, stickerColor: 0, neon: 6), 1.2, 0.25, false),
        (const CarConfig(body: 3, color: 9, sticker: 6, stickerColor: 0, exhaust: 1), 3.6, 0.35, false),
        (const CarConfig(body: 0, color: 6, spoiler: 3, rim: 4, rimColor: 1, roof: 3, neon: 2), 0.4, 0.7, true),
        (const CarConfig(body: 7, color: 1, sticker: 1, stickerColor: 2, spoiler: 2), 3.9, 0.35, false),
      ]);
      await _custom('studyo', 800, 420, (c) {
        paintStudio(c, const Size(400, 420), const CarConfig(body: 0, color: 1, finish: 1, sticker: 1, rim: 1, spoiler: 2),
            0.75, 0.3, 1.0, false, 0);
        c.save();
        c.translate(400, 0);
        paintStudio(c, const Size(400, 420), const CarConfig(body: 2, color: 0, neon: 1, roof: 3, tire: 1), 2.3, 0.35, 1.0,
            true, 0);
        c.restore();
      });
      await _custom('yaris', 360, 640, (c) {
        c.drawRect(const Rect.fromLTWH(0, 0, 360, 640), Paint()..color = const Color(0xFF7CB342));
        c.drawRect(const Rect.fromLTWH(40, 0, 280, 640), Paint()..color = const Color(0xFF546E7A));
        for (var i = 0; i < 3; i++) {
          final cfg = [const CarConfig(body: 0, color: 0), const CarConfig(body: 4, color: 9), const CarConfig(body: 6, color: 2)][i];
          final cam = Camera(center: Offset(87 + i * 93.0, 480 - i * 150.0), scale: 26, yaw: 3.14159, pitch: 0.95);
          paintCar(c, cfg, cam, lod: true);
        }
      });
    });
  });
}
