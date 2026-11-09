import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vizir/car3d/car_model.dart';
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

void main() {
  testWidgets('3D araba önizlemeleri', (tester) async {
    await tester.runAsync(() async {
      await _sheet('govdeler', [
        (const CarConfig(body: 0), 0.75, 0.3, false),
        (const CarConfig(body: 1, color: 1, finish: 1), 0.75, 0.3, false),
        (const CarConfig(body: 2, color: 3, tire: 1, height: 2, roof: 1), 0.75, 0.3, false),
        (const CarConfig(body: 3, color: 4), 0.75, 0.3, false),
        (const CarConfig(body: 0, color: 5, sticker: 1, stickerColor: 2, spoiler: 2, rim: 1, rimColor: 2), -0.8, 0.35, false),
        (const CarConfig(body: 1, color: 4, roof: 2, sticker: 2, stickerColor: 1), 2.4, 0.3, true),
      ]);
      await _sheet('aksesuarlar', [
        (const CarConfig(body: 0, color: 2, sticker: 3, stickerColor: 3, rim: 3), 1.5708, 0.1, false),
        (const CarConfig(body: 1, color: 7, sticker: 4, stickerColor: 2, finish: 2), -1.5708, 0.1, false),
        (const CarConfig(body: 2, color: 8, sticker: 5, stickerColor: 0, neon: 6), 1.2, 0.25, false),
        (const CarConfig(body: 3, color: 9, sticker: 6, stickerColor: 0, spoiler: 3, exhaust: 1), 3.6, 0.35, false),
        (const CarConfig(body: 0, color: 6, spoiler: 3, rim: 4, rimColor: 1, roof: 3, neon: 2), 0.4, 0.7, true),
        (const CarConfig(body: 2, color: 11, finish: 1, rim: 2, tint: 2), 3.14159, 0.95, false),
      ]);
    });
  });
}
