import 'dart:math';

import 'package:flutter/material.dart';

/// Şekilli bloklar. Hücrede blok malzemesi + şekil (ve yön) saklanır.
class ShapeDef {
  final int id;
  final String key;
  final String name;
  final String emoji;
  final bool directional;
  const ShapeDef(this.id, this.key, this.name, this.emoji, {this.directional = false});
}

const shapes = <ShapeDef>[
  ShapeDef(0, 'kup', 'küp', '⬛'),
  ShapeDef(1, 'yarim', 'yarım blok', '▬'),
  ShapeDef(2, 'merdiven', 'merdiven', '📶', directional: true),
  ShapeDef(3, 'egik', 'eğik çatı', '◢', directional: true),
  ShapeDef(4, 'ucgen', 'üçgen', '🔺'),
  ShapeDef(5, 'besgen', 'beşgen', '⬟'),
  ShapeDef(6, 'altigen', 'altıgen', '⬢'),
  ShapeDef(7, 'silindir', 'silindir', '🛢️'),
  ShapeDef(8, 'piramit', 'piramit', '🔼'),
  ShapeDef(9, 'sutun', 'sütun', '🏛️'),
];

/// Kenar sayısı (eğitici bilgi için)
const shapeEdges = {4: 3, 5: 5, 6: 6, 8: 4};

/// Bir çokgen: köşeler (x,y,z üçlüleri) ve dışa bakan normal
class SPoly {
  final List<double> p;
  final double nx, ny, nz;
  final int? color; // sabit renk (ör. meşale alevi)
  List<double> uv = const [];
  SPoly(this.p, this.nx, this.ny, this.nz, [this.color]);
}

List<SPoly> _box(double x0, double y0, double z0, double x1, double y1, double z1, [int? color]) => [
      SPoly([x0, y0, z1, x1, y0, z1, x1, y1, z1, x0, y1, z1], 0, 0, 1, color),
      SPoly([x0, y1, z0, x1, y1, z0, x1, y0, z0, x0, y0, z0], 0, 0, -1, color),
      SPoly([x1, y1, z1, x1, y0, z1, x1, y0, z0, x1, y1, z0], 1, 0, 0, color),
      SPoly([x0, y0, z1, x0, y1, z1, x0, y1, z0, x0, y0, z0], -1, 0, 0, color),
      SPoly([x0, y1, z1, x1, y1, z1, x1, y1, z0, x0, y1, z0], 0, 1, 0, color),
      SPoly([x1, y0, z1, x0, y0, z1, x0, y0, z0, x1, y0, z0], 0, -1, 0, color),
    ];

List<SPoly> _prism(int n, double r, {double rot = 0}) {
  final out = <SPoly>[];
  final pts = [for (var i = 0; i < n; i++) (0.5 + r * sin(rot + i * 2 * pi / n), 0.5 + r * cos(rot + i * 2 * pi / n))];
  out.add(SPoly([for (final p in pts) ...[p.$1, p.$2, 1.0]], 0, 0, 1));
  out.add(SPoly([for (final p in pts.reversed) ...[p.$1, p.$2, 0.0]], 0, 0, -1));
  for (var i = 0; i < n; i++) {
    final a = pts[i], b = pts[(i + 1) % n];
    final mx = (a.$1 + b.$1) / 2 - 0.5, my = (a.$2 + b.$2) / 2 - 0.5;
    final l = sqrt(mx * mx + my * my) + 1e-9;
    out.add(SPoly([a.$1, a.$2, 1, b.$1, b.$2, 1, b.$1, b.$2, 0, a.$1, a.$2, 0], mx / l, my / l, 0));
  }
  return out;
}

/// Yerel (0..1) çokgenler; yön [r] 0..3 (0: ileri = +y)
List<SPoly> shapeLocal(int shape) {
  switch (shape) {
    case 1:
      return _box(0, 0, 0, 1, 1, 0.5);
    case 2:
      return [..._box(0, 0, 0, 1, 1, 0.5), ..._box(0, 0.5, 0.5, 1, 1, 1)];
    case 3:
      final s = 1 / sqrt(2);
      return [
        SPoly([0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0], 0, 0, -1),
        SPoly([0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0], 0, 1, 0),
        SPoly([0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1], 0, -s, s),
        SPoly([1, 0, 0, 1, 1, 0, 1, 1, 1], 1, 0, 0),
        SPoly([0, 1, 1, 0, 1, 0, 0, 0, 0], -1, 0, 0),
      ];
    case 4:
      return _prism(3, 0.52);
    case 5:
      return _prism(5, 0.5);
    case 6:
      return _prism(6, 0.5, rot: pi / 6);
    case 7:
      return _prism(12, 0.48);
    case 8:
      final out = <SPoly>[SPoly([0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0], 0, 0, -1)];
      const base = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
      for (var i = 0; i < 4; i++) {
        final a = base[i], b = base[(i + 1) % 4];
        final mx = (a.$1 + b.$1) / 2 - 0.5, my = (a.$2 + b.$2) / 2 - 0.5;
        final l = sqrt(mx * mx + my * my + 0.25);
        out.add(SPoly([a.$1, a.$2, 0, b.$1, b.$2, 0, 0.5, 0.5, 1], mx / l, my / l, 0.5 / l));
      }
      return out;
    case 9:
      return [..._prism(8, 0.3), ..._box(0.1, 0.1, 0, 0.9, 0.9, 0.12), ..._box(0.1, 0.1, 0.88, 0.9, 0.9, 1)];
    case 20: // meşale
      return [
        ..._box(0.45, 0.45, 0, 0.55, 0.55, 0.6, 0xFF6D4C41),
        ..._box(0.41, 0.41, 0.6, 0.59, 0.59, 0.76, 0xFFFFB300),
        ..._box(0.45, 0.45, 0.76, 0.55, 0.55, 0.86, 0xFFFFF59D),
      ];
    default:
      return _box(0, 0, 0, 1, 1, 1);
  }
}

/// Dünya koordinatına taşınmış ve döndürülmüş çokgenler.
List<SPoly> shapeWorld(int shape, int rot, int x, int y, int z) {
  final out = <SPoly>[];
  for (final p in shapeLocal(shape)) {
    final q = <double>[];
    final uv = <double>[];
    for (var i = 0; i < p.p.length; i += 3) {
      var lx = p.p[i], ly = p.p[i + 1];
      final lz = p.p[i + 2];
      // doku: döndürmeden önceki yerel koordinatla
      if (p.nz.abs() >= p.nx.abs() && p.nz.abs() >= p.ny.abs()) {
        uv
          ..add(lx)
          ..add(ly);
      } else if (p.nx.abs() >= p.ny.abs()) {
        uv
          ..add(ly)
          ..add(1 - lz);
      } else {
        uv
          ..add(lx)
          ..add(1 - lz);
      }
      switch (rot & 3) {
        case 1:
          (lx, ly) = (ly, 1 - lx);
        case 2:
          (lx, ly) = (1 - lx, 1 - ly);
        case 3:
          (lx, ly) = (1 - ly, lx);
      }
      q
        ..add(x + lx)
        ..add(y + ly)
        ..add(z + p.p[i + 2]);
    }
    var nx = p.nx, ny = p.ny;
    switch (rot & 3) {
      case 1:
        (nx, ny) = (ny, -nx);
      case 2:
        (nx, ny) = (-nx, -ny);
      case 3:
        (nx, ny) = (-ny, nx);
    }
    out.add(SPoly(q, nx, ny, p.nz, p.color)..uv = uv);
  }
  return out;
}

double shadeFor(double nx, double ny, double nz) {
  if (nz > 0.9) return 1.0;
  if (nz < -0.9) return 0.55;
  final side = 0.77 + 0.07 * nx - 0.08 * ny;
  return (max(0.0, nz) * 1.0 + (1 - nz.abs()) * side + max(0.0, -nz) * 0.55).clamp(0.5, 1.0);
}

// ======================= HECELEME =======================

const _vowels = 'aeıioöuüâîû';

/// Türkçe heceleme. Tek heceli kelimeler harflerine ayrılır.
List<String> heceler(String w, {bool lettersIfOne = true}) {
  final s = w.toLowerCase().replaceAll('I', 'ı').replaceAll(' ', '').replaceAll('-', '');
  final idx = <int>[];
  for (var i = 0; i < s.length; i++) {
    if (_vowels.contains(s[i])) idx.add(i);
  }
  if (idx.length <= 1) {
    if (lettersIfOne && s.length <= 4) return s.split('');
    return [s];
  }
  final out = <String>[];
  var start = 0;
  for (var k = 0; k < idx.length - 1; k++) {
    final a = idx[k], b = idx[k + 1];
    final cut = b - a - 1 == 0 ? b : b - 1;
    out.add(s.substring(start, cut));
    start = cut;
  }
  out.add(s.substring(start));
  return out;
}

/// Şeklin küçük 3B resmi (çanta ve düğmeler için)
class ShapeIcon extends StatelessWidget {
  final int shape;
  final double size;
  final Color color;
  const ShapeIcon(this.shape, {super.key, this.size = 40, this.color = const Color(0xFFC08A4E)});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _ShapeIconPainter(shape, color));
}

class _ShapeIconPainter extends CustomPainter {
  final int shape;
  final Color color;
  _ShapeIconPainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final polys = shapeLocal(shape).where((p) => p.nx + p.ny + p.nz * 1.2 > 1e-3).toList();
    double depth(SPoly p) {
      var d = 0.0;
      for (var i = 0; i < p.p.length; i += 3) {
        d += p.p[i] + p.p[i + 1] + p.p[i + 2];
      }
      return d / (p.p.length / 3);
    }

    polys.sort((a, b) => depth(a).compareTo(depth(b)));
    final s = size.width / 2.2;
    final o = Offset(size.width / 2, size.height / 2);
    Offset proj(double x, double y, double z) =>
        o + Offset((x - y) * 0.87 * s, ((x + y) * 0.5 - z) * s);
    for (final p in polys) {
      final path = Path();
      for (var i = 0; i < p.p.length; i += 3) {
        final q = proj(p.p[i] - 0.5, p.p[i + 1] - 0.5, p.p[i + 2] - 0.5);
        if (i == 0) {
          path.moveTo(q.dx, q.dy);
        } else {
          path.lineTo(q.dx, q.dy);
        }
      }
      path.close();
      final base = p.color != null ? Color(p.color!) : color;
      final sh = shadeFor(p.nx, p.ny, p.nz);
      canvas.drawPath(path, Paint()..color = Color.lerp(Colors.black, base, sh)!);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black26);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeIconPainter old) => old.shape != shape || old.color != color;
}
