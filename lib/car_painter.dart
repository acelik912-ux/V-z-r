import 'dart:math';

import 'package:flutter/material.dart';

const carColors = <Color>[
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFEC407A),
];
const colorNames = <String>['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Turuncu', 'Mor', 'Turkuaz', 'Pembe'];
const bodyNames = <String>['Yarış arabası', 'Cip', 'Kamyonet'];
const wheelNames = <String>['Klasik tekerlek', 'Spor tekerlek', 'Kocaman tekerlek'];

class CarSpec {
  final int body;
  final int color;
  final int wheel;
  const CarSpec(this.body, this.color, this.wheel);

  Color get paint => carColors[color % carColors.length];

  @override
  bool operator ==(Object other) =>
      other is CarSpec && other.body == body && other.color == color && other.wheel == wheel;

  @override
  int get hashCode => Object.hash(body, color, wheel);
}

/// Arabayı yukarıdan, burnu yukarı bakacak şekilde [r] alanına çizer.
void drawCar(Canvas canvas, Rect r, CarSpec spec, {double opacity = 1.0, Color? override}) {
  final useLayer = opacity < 1.0;
  if (useLayer) {
    canvas.saveLayer(r.inflate(r.width), Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
  }
  final base = override ?? spec.paint;
  final dark = Color.lerp(base, Colors.black, 0.38)!;
  final light = Color.lerp(base, Colors.white, 0.3)!;
  const glass = Color(0xFFB3E5FC);
  final w = r.width;
  final h = r.height;
  final cx = r.center.dx;
  final bodyW = w * (spec.body == 0 ? 0.64 : 0.74);
  final body = Rect.fromCenter(center: r.center, width: bodyW, height: h * 0.94);

  // Tekerlekler
  final big = spec.wheel == 2;
  final ww = w * (big ? 0.22 : 0.16);
  final wh = h * (big ? 0.22 : 0.17);
  final tire = Paint()..color = const Color(0xFF263238);
  for (final fy in [0.24, 0.76]) {
    for (final side in [-1.0, 1.0]) {
      final c = Offset(cx + side * (bodyW / 2 - ww * 0.15), r.top + h * fy);
      final wr = Rect.fromCenter(center: c, width: ww, height: wh);
      canvas.drawRRect(RRect.fromRectAndRadius(wr, Radius.circular(ww * 0.35)), tire);
      if (spec.wheel == 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: ww * 0.45, height: wh * 0.55), Radius.circular(ww * 0.2)),
          Paint()..color = const Color(0xFFFFD54F),
        );
      }
      if (big) {
        final tread = Paint()
          ..color = Colors.white24
          ..strokeWidth = max(1.0, wh * 0.06);
        for (final t in [-0.25, 0.0, 0.25]) {
          canvas.drawLine(Offset(wr.left + 2, c.dy + wh * t), Offset(wr.right - 2, c.dy + wh * t), tread);
        }
      }
    }
  }

  // Yarış arabasının spoileri
  if (spec.body == 0) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, body.bottom - h * 0.03), width: w * 0.86, height: h * 0.07),
          Radius.circular(h * 0.02)),
      Paint()..color = dark,
    );
  }

  // Gövde
  final bodyR = RRect.fromRectAndRadius(body, Radius.circular(w * (spec.body == 1 ? 0.12 : 0.2)));
  canvas.drawRRect(bodyR, Paint()..color = base);

  // Kamyonet kasası
  if (spec.body == 2) {
    final bed = Rect.fromLTWH(body.left + bodyW * 0.1, body.top + h * 0.5, bodyW * 0.8, h * 0.38);
    canvas.drawRRect(RRect.fromRectAndRadius(bed, Radius.circular(w * 0.06)), Paint()..color = dark);
    final line = Paint()
      ..color = base
      ..strokeWidth = max(1.0, w * 0.025);
    for (final t in [0.33, 0.66]) {
      canvas.drawLine(Offset(bed.left + bed.width * t, bed.top + 4), Offset(bed.left + bed.width * t, bed.bottom - 4), line);
    }
  }

  // Ön cam
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW * 0.36, body.top + h * 0.2, bodyW * 0.72, h * 0.14), Radius.circular(w * 0.08)),
    Paint()..color = glass,
  );

  if (spec.body != 2) {
    // Tavan ve arka cam
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bodyW * 0.34, body.top + h * 0.36, bodyW * 0.68, h * 0.24), Radius.circular(w * 0.08)),
      Paint()..color = light,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bodyW * 0.3, body.top + h * 0.62, bodyW * 0.6, h * 0.08), Radius.circular(w * 0.05)),
      Paint()..color = glass,
    );
  } else {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bodyW * 0.34, body.top + h * 0.35, bodyW * 0.68, h * 0.12), Radius.circular(w * 0.06)),
      Paint()..color = light,
    );
  }

  if (spec.body == 0) {
    final stripe = Paint()..color = Colors.white70;
    canvas.drawRect(Rect.fromLTWH(cx - bodyW * 0.07, body.top + h * 0.13, bodyW * 0.14, h * 0.07), stripe);
    canvas.drawRect(Rect.fromLTWH(cx - bodyW * 0.07, body.top + h * 0.71, bodyW * 0.14, h * 0.18), stripe);
  }

  if (spec.body == 1) {
    final rack = Paint()
      ..color = dark
      ..strokeWidth = max(1.5, w * 0.025);
    for (final t in [0.42, 0.48, 0.54]) {
      canvas.drawLine(Offset(cx - bodyW * 0.28, body.top + h * t), Offset(cx + bodyW * 0.28, body.top + h * t), rack);
    }
    canvas.drawCircle(Offset(cx, body.bottom - h * 0.06), w * 0.11, tire);
    canvas.drawCircle(Offset(cx, body.bottom - h * 0.06), w * 0.05, Paint()..color = Colors.grey);
  }

  // Kenar çizgisi
  canvas.drawRRect(
    bodyR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.03)
      ..color = dark,
  );

  // Far gözler
  for (final side in [-1.0, 1.0]) {
    final c = Offset(cx + side * bodyW * 0.24, body.top + h * 0.085);
    canvas.drawCircle(c, w * 0.095, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      w * 0.095,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, w * 0.015)
        ..color = dark,
    );
    canvas.drawCircle(c + Offset(-side * w * 0.02, w * 0.01), w * 0.048, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(c + Offset(-side * w * 0.03, -w * 0.01), w * 0.016, Paint()..color = Colors.white);
  }

  // Gülümseme
  canvas.drawArc(
    Rect.fromCenter(center: Offset(cx, body.top + h * 0.12), width: bodyW * 0.24, height: h * 0.07),
    0.3,
    pi - 0.6,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, w * 0.025)
      ..strokeCap = StrokeCap.round
      ..color = dark,
  );

  if (useLayer) canvas.restore();
}

class CarPainter extends CustomPainter {
  final CarSpec spec;
  CarPainter(this.spec);

  @override
  void paint(Canvas canvas, Size size) => drawCar(canvas, Offset.zero & size, spec);

  @override
  bool shouldRepaint(CarPainter oldDelegate) => oldDelegate.spec != spec;
}

/// Arabayı en-boy oranını koruyarak gösteren widget.
class CarView extends StatelessWidget {
  final CarSpec spec;
  final double width;
  const CarView(this.spec, {super.key, this.width = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 1.75,
      child: CustomPaint(painter: CarPainter(spec)),
    );
  }
}
