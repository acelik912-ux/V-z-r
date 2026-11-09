import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vizir/car3d/car_model.dart';
import 'package:vizir/car3d/renderer.dart';

/// Uygulama simgesini çizer: arka plan katmanı, ön plan (araba) katmanı ve birleşik simge.
const double S = 1024;

void drawBackground(Canvas c) {
  const r = Rect.fromLTWH(0, 0, S, S);
  // Gökyüzü
  c.drawRect(
    r,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E88E5), Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
        stops: [0, 0.4, 0.62],
      ).createShader(r),
  );
  // Güneş
  c.drawCircle(const Offset(790, 230), 150,
      Paint()
        ..color = const Color(0x66FFF59D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));
  c.drawCircle(const Offset(790, 230), 95, Paint()..color = const Color(0xFFFFEE58));
  c.drawCircle(const Offset(770, 210), 60, Paint()..color = const Color(0xFFFFF59D));
  // Bulutlar
  final cloud = Paint()..color = Colors.white.withAlpha(235);
  for (final p in const [Offset(230, 250), Offset(300, 220), Offset(370, 255), Offset(300, 275)]) {
    c.drawCircle(p, 62, cloud);
  }
  for (final p in const [Offset(560, 380), Offset(610, 360), Offset(660, 385)]) {
    c.drawCircle(p, 38, cloud);
  }
  // Tepeler
  final hill1 = Path()
    ..moveTo(0, 600)
    ..quadraticBezierTo(250, 470, 520, 590)
    ..quadraticBezierTo(780, 470, S, 560)
    ..lineTo(S, S)
    ..lineTo(0, S)
    ..close();
  c.drawPath(hill1, Paint()..color = const Color(0xFF81C784));
  final hill2 = Path()
    ..moveTo(0, 680)
    ..quadraticBezierTo(300, 600, 600, 690)
    ..quadraticBezierTo(850, 620, S, 670)
    ..lineTo(S, S)
    ..lineTo(0, S)
    ..close();
  c.drawPath(hill2, Paint()..color = const Color(0xFF4CAF50));
  // Laleler
  final colors = [const Color(0xFFE53935), const Color(0xFFFFEB3B), const Color(0xFFEC407A)];
  final rnd = math.Random(3);
  for (var i = 0; i < 26; i++) {
    final left = i.isEven;
    final x = left ? 40 + rnd.nextDouble() * 220 : S - 40 - rnd.nextDouble() * 220;
    final y = 720 + rnd.nextDouble() * 280;
    final sz = 10 + (y - 700) / 300 * 12;
    c.drawLine(Offset(x, y), Offset(x, y + sz * 1.6),
        Paint()
          ..color = const Color(0xFF2E7D32)
          ..strokeWidth = sz * 0.35);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: sz * 1.4, height: sz * 1.7), Paint()..color = colors[i % 3]);
  }
  // Yol
  final road = Path()
    ..moveTo(470, 600)
    ..lineTo(554, 600)
    ..cubicTo(700, 760, 820, 880, 880, S)
    ..lineTo(150, S)
    ..cubicTo(260, 860, 380, 720, 470, 600)
    ..close();
  c.drawPath(road, Paint()..color = const Color(0xFF546E7A));
  // Orta çizgi
  final dash = Paint()..color = Colors.white;
  for (var i = 0; i < 6; i++) {
    final t0 = i / 6.0, t1 = t0 + 0.08;
    double y(double t) => 600 + (S - 600) * t * t;
    double x(double t) => 512 + (515 - 512) * t;
    final w0 = 3 + 18 * t0, w1 = 3 + 18 * t1;
    c.drawPath(
      Path()
        ..moveTo(x(t0) - w0, y(t0))
        ..lineTo(x(t0) + w0, y(t0))
        ..lineTo(x(t1) + w1, y(t1))
        ..lineTo(x(t1) - w1, y(t1))
        ..close(),
      dash,
    );
  }
}

void drawForeground(Canvas c) {
  // Hız çizgileri
  final line = Paint()
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withAlpha(210);
  for (final l in const [
    [170.0, 470.0, 330.0, 470.0, 16.0],
    [130.0, 540.0, 300.0, 540.0, 20.0],
    [180.0, 610.0, 320.0, 610.0, 14.0],
  ]) {
    c.drawLine(Offset(l[0], l[1]), Offset(l[2], l[3]), line..strokeWidth = l[4]);
  }
  const cfg = CarConfig(body: 0, color: 0, sticker: 1, stickerColor: 0, rim: 1, rimColor: 2, spoiler: 2);
  final cam = Camera(center: const Offset(540, 650), scale: 118, yaw: 0.62, pitch: 0.3);
  paintCar(c, cfg, cam, lightsOn: true);
  // Parıltı
  final spark = Paint()..color = Colors.white;
  void star(Offset o, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final rr = i.isEven ? r : r * 0.28;
      final pt = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    c.drawPath(p, spark);
  }

  star(const Offset(690, 420), 34);
  star(const Offset(742, 470), 18);
}

Future<void> _save(String name, void Function(Canvas) draw, {double size = S}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, Rect.fromLTWH(0, 0, size, size));
  draw(canvas);
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('previews').createSync(recursive: true);
  File('previews/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('uygulama simgesi', (tester) async {
    await tester.runAsync(() async {
      await _save('icon_bg', drawBackground);
      await _save('icon_fg', drawForeground);
      await _save('icon_full', (c) {
        drawBackground(c);
        drawForeground(c);
      });
    });
  });
}
