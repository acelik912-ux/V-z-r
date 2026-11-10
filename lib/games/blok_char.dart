import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';

// ======================= KARAKTER =======================

const skinColors = [Color(0xFFFFDBB5), Color(0xFFF1C27D), Color(0xFFC68642), Color(0xFF8D5524)];
const hairColors = [Color(0xFF3B2314), Color(0xFF111111), Color(0xFFB5651D), Color(0xFFE6BE8A), Color(0xFF9E9E9E)];
const clothColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF37474F),
  Color(0xFFFFFFFF),
];
const hatColors = [Color(0xFFFFC107), Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF6D4C41), Color(0xFFFFFFFF)];
const hairStyles = ['Kısa saç', 'Uzun saç', 'Kask', 'Şapka', 'Takke'];

class Avatar {
  int skin, hair, style, shirt, pants, hat;
  Avatar({this.skin = 0, this.hair = 0, this.style = 0, this.shirt = 0, this.pants = 6, this.hat = 0});

  String encode() => '$skin,$hair,$style,$shirt,$pants,$hat';

  static Avatar? decode(String s) {
    final p = s.split(',').map(int.tryParse).toList();
    if (p.length != 6 || p.any((e) => e == null)) return null;
    return Avatar(skin: p[0]!, hair: p[1]!, style: p[2]!, shirt: p[3]!, pants: p[4]!, hat: p[5]!);
  }

  Avatar copy() => Avatar(skin: skin, hair: hair, style: style, shirt: shirt, pants: pants, hat: hat);
}

/// Hazır karakterler
final presets = <(String, Avatar)>[
  ('Sürücü', Avatar(skin: 0, hair: 0, style: 0, shirt: 0, pants: 0)),
  ('Mimar', Avatar(skin: 1, hair: 1, style: 2, shirt: 4, pants: 1, hat: 0)),
  ('Bahçıvan', Avatar(skin: 2, hair: 0, style: 3, shirt: 2, pants: 6, hat: 3)),
  ('Kâşif', Avatar(skin: 1, hair: 2, style: 3, shirt: 3, pants: 6, hat: 3)),
  ('Hafız', Avatar(skin: 0, hair: 1, style: 4, shirt: 7, pants: 7, hat: 4)),
  ('Usta', Avatar(skin: 3, hair: 4, style: 1, shirt: 1, pants: 6)),
];

Avatar get myAvatar => Avatar.decode(game.avatar) ?? presets[0].$2.copy();

/// Aletler (hazine sandıklarından sırayla çıkar)
class Tool {
  final String id;
  final String name;
  final String emoji;
  const Tool(this.id, this.name, this.emoji);
}

const tools = [
  Tool('kazma', 'kazma', '⛏️'),
  Tool('balta', 'balta', '🪓'),
  Tool('kurek', 'kürek', '🪏'),
  Tool('kilic', 'kılıç', '🗡️'),
  Tool('kalkan', 'kalkan', '🛡️'),
  Tool('mizrak', 'mızrak', '🔱'),
];

/// Karakterin bir parçası (yerel koordinat: x sağ, y ileri, z yukarı; ayaklar z=0)
class ABox {
  final double cx, cy, cz, hx, hy, hz;
  final Color color;
  final double pivotZ; // dönme ekseni yüksekliği (x eksenine paralel)
  final double angle; // ileri doğru salınım
  final bool face; // ön yüzü suratlı
  const ABox(this.cx, this.cy, this.cz, this.hx, this.hy, this.hz, this.color, {this.pivotZ = 0, this.angle = 0, this.face = false});
}

/// Yürüme fazı [walk] (radyan), [swing] 0..1 alet vuruşu, [tool] elde tutulan alet.
List<ABox> avatarBoxes(Avatar a, {double walk = 0, double swing = 0, String? tool, bool shield = false}) {
  final skin = skinColors[a.skin % skinColors.length];
  final hair = hairColors[a.hair % hairColors.length];
  final shirt = clothColors[a.shirt % clothColors.length];
  final pants = clothColors[a.pants % clothColors.length];
  final hat = hatColors[a.hat % hatColors.length];
  final leg = sin(walk) * 0.6;
  final armR = swing > 0 ? -1.9 * sin(swing * pi) : -leg;
  final armL = leg;
  final out = <ABox>[
    ABox(-0.13, 0, 0.375, 0.11, 0.12, 0.375, pants, pivotZ: 0.75, angle: leg),
    ABox(0.13, 0, 0.375, 0.11, 0.12, 0.375, pants, pivotZ: 0.75, angle: -leg),
    ABox(-0.13, 0.02, 0.05, 0.115, 0.15, 0.05, const Color(0xFF3E2723), pivotZ: 0.75, angle: leg),
    ABox(0.13, 0.02, 0.05, 0.115, 0.15, 0.05, const Color(0xFF3E2723), pivotZ: 0.75, angle: -leg),
    ABox(0, 0, 1.08, 0.25, 0.14, 0.33, shirt),
    ABox(-0.36, 0, 1.1, 0.1, 0.1, 0.29, shirt, pivotZ: 1.39, angle: armL),
    ABox(0.36, 0, 1.1, 0.1, 0.1, 0.29, shirt, pivotZ: 1.39, angle: armR),
    ABox(-0.36, 0, 0.76, 0.09, 0.09, 0.06, skin, pivotZ: 1.39, angle: armL),
    ABox(0.36, 0, 0.76, 0.09, 0.09, 0.06, skin, pivotZ: 1.39, angle: armR),
    ABox(0, 0, 1.65, 0.23, 0.23, 0.23, skin, face: true),
  ];
  switch (a.style) {
    case 0:
      out.add(ABox(0, -0.01, 1.86, 0.245, 0.245, 0.04, hair));
      out.add(ABox(0, -0.2, 1.7, 0.245, 0.05, 0.17, hair));
    case 1:
      out.add(ABox(0, -0.01, 1.86, 0.245, 0.245, 0.04, hair));
      out.add(ABox(0, -0.2, 1.55, 0.245, 0.05, 0.3, hair));
      out.add(ABox(-0.235, -0.05, 1.62, 0.03, 0.2, 0.22, hair));
      out.add(ABox(0.235, -0.05, 1.62, 0.03, 0.2, 0.22, hair));
    case 2: // kask
      out.add(ABox(0, -0.01, 1.84, 0.27, 0.27, 0.09, hat));
      out.add(ABox(0, 0.2, 1.79, 0.27, 0.1, 0.025, hat));
    case 3: // şapka
      out.add(ABox(0, 0, 1.79, 0.33, 0.33, 0.025, hat));
      out.add(ABox(0, 0, 1.9, 0.2, 0.2, 0.1, hat));
    default: // takke
      out.add(ABox(0, 0, 1.87, 0.24, 0.24, 0.05, hat));
  }
  if (tool != null) out.addAll(_toolBoxes(tool, armR));
  if (shield) {
    out.add(ABox(-0.48, 0.02, 1.0, 0.03, 0.22, 0.26, const Color(0xFF1565C0), pivotZ: 1.39, angle: armL));
    out.add(ABox(-0.515, 0.02, 1.0, 0.012, 0.08, 0.1, const Color(0xFFFFC107), pivotZ: 1.39, angle: armL));
  }
  return out;
}

List<ABox> _toolBoxes(String t, double a) {
  const wood = Color(0xFF8D5524), iron = Color(0xFFCFD8DC), gold = Color(0xFFFFC107);
  // el: (0.36, 0, 0.76); alet ileri doğru uzanır
  switch (t) {
    case 'kazma':
      return [
        ABox(0.36, 0.2, 0.76, 0.025, 0.28, 0.025, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.46, 0.76, 0.03, 0.04, 0.2, iron, pivotZ: 1.39, angle: a),
      ];
    case 'balta':
      return [
        ABox(0.36, 0.2, 0.76, 0.025, 0.28, 0.025, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.42, 0.84, 0.02, 0.08, 0.1, iron, pivotZ: 1.39, angle: a),
      ];
    case 'kurek':
      return [
        ABox(0.36, 0.2, 0.76, 0.025, 0.28, 0.025, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.52, 0.76, 0.1, 0.08, 0.015, iron, pivotZ: 1.39, angle: a),
      ];
    case 'kilic':
      return [
        ABox(0.36, 0.05, 0.76, 0.03, 0.06, 0.03, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.12, 0.76, 0.1, 0.015, 0.025, gold, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.42, 0.76, 0.018, 0.3, 0.045, iron, pivotZ: 1.39, angle: a),
      ];
    case 'mizrak':
      return [
        ABox(0.36, 0.25, 0.76, 0.02, 0.6, 0.02, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.9, 0.76, 0.035, 0.08, 0.035, iron, pivotZ: 1.39, angle: a),
      ];
    default:
      return const [];
  }
}

/// Bir kutunun 8 köşesi (dünya koordinatı).
List<(double, double, double)> boxCorners(ABox b, double px, double py, double pz, double facing) {
  final cf = cos(facing), sf = sin(facing);
  final ca = cos(b.angle), sa = sin(b.angle);
  final out = <(double, double, double)>[];
  for (final sx in const [-1.0, 1.0]) {
    for (final sy in const [-1.0, 1.0]) {
      for (final sz in const [-1.0, 1.0]) {
        final lx = b.cx + sx * b.hx;
        var ly = b.cy + sy * b.hy;
        var lz = b.cz + sz * b.hz;
        if (b.angle != 0) {
          final rz = lz - b.pivotZ;
          final y2 = ly * ca - rz * sa;
          final z2 = ly * sa + rz * ca;
          ly = y2;
          lz = z2 + b.pivotZ;
        }
        out.add((px + lx * cf + ly * sf, py - lx * sf + ly * cf, pz + lz));
      }
    }
  }
  return out;
}

/// Kutunun yüzleri: köşe numaraları (sol üst, sağ üst, sağ alt, sol alt) ve yerel normal
/// köşe sırası: (sx,sy,sz) -> index = sx*4 + sy*2 + sz  (0 = eksi, 1 = artı)
const boxFaces = <(List<int>, int)>[
  ([3, 7, 5, 1], 0), // üst  z+
  ([5, 7, 6, 4], 1), // sağ  x+
  ([3, 1, 0, 2], 2), // sol  x-
  ([7, 3, 2, 6], 3), // ön   y+ (yüz)
  ([1, 5, 4, 0], 4), // arka y-
];

// ======================= KARAKTER EKRANI =======================

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> with SingleTickerProviderStateMixin {
  late Avatar a = myAvatar;
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void initState() {
    super.initState();
    Voice.say('Kendi karakterini oluştur! Hazır birini seç ya da renklerini değiştir.');
  }

  @override
  void dispose() {
    spin.dispose();
    super.dispose();
  }

  void _set(VoidCallback f) {
    Sfx.play('pop');
    setState(f);
  }

  Widget _row(String title, int count, int sel, Color Function(int) col, void Function(int) on) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 74, child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < count; i++)
                GestureDetector(
                  onTap: () => _set(() => on(i)),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col(i),
                      shape: BoxShape.circle,
                      border: Border.all(color: sel == i ? Colors.orange : Colors.black26, width: sel == i ? 4 : 2),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF81D4FA), Color(0xFFC8E6C9)]),
        ),
        child: SafeArea(
          child: Column(children: [
            const TopBar('Karakterim'),
            SizedBox(
              height: 230,
              child: AnimatedBuilder(
                animation: spin,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: AvatarPainter(a, spin.value * 2 * pi, walk: sin(spin.value * 2 * pi * 4) * 0.0),
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
                for (final p in presets)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Bouncy(
                      onTap: () {
                        _set(() => a = p.$2.copy());
                        Voice.say(p.$1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Text(p.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(22)),
                child: ListView(children: [
                  _row('Ten', skinColors.length, a.skin, (i) => skinColors[i], (i) => a.skin = i),
                  _row('Saç', hairColors.length, a.hair, (i) => hairColors[i], (i) => a.hair = i),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      for (var i = 0; i < hairStyles.length; i++)
                        ChoiceChip(
                          label: Text(hairStyles[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                          selected: a.style == i,
                          onSelected: (_) => _set(() => a.style = i),
                        ),
                    ]),
                  ),
                  if (a.style >= 2) _row('Başlık', hatColors.length, a.hat, (i) => hatColors[i], (i) => a.hat = i),
                  _row('Gömlek', clothColors.length, a.shirt, (i) => clothColors[i], (i) => a.shirt = i),
                  _row('Pantolon', clothColors.length, a.pants, (i) => clothColors[i], (i) => a.pants = i),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF43A047)),
                  onPressed: () {
                    game.setAvatar(a.encode());
                    Sfx.play('unlock');
                    Voice.say('Harika görünüyorsun! Haydi şehre!');
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.check, size: 28),
                  label: const Text('Bu benim!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Karakteri düz renklerle çizer (önizleme için).
class AvatarPainter extends CustomPainter {
  final Avatar a;
  final double facing;
  final double walk;
  AvatarPainter(this.a, this.facing, {this.walk = 0});

  @override
  void paint(Canvas canvas, Size size) {
    const pitch = 0.35;
    final s = size.height / 2.4;
    final sp = sin(pitch), cp = cos(pitch);
    Offset pr(double x, double y, double z) => Offset(size.width / 2 + x * s, size.height * 0.92 + y * sp * s - z * cp * s);
    double dep(double x, double y, double z) => y * cp + z * sp;
    // zemin gölgesi
    canvas.drawOval(Rect.fromCenter(center: pr(0, 0, 0), width: s * 0.9, height: s * 0.3), Paint()..color = Colors.black26);
    final items = <(double, Path, Color)>[];
    for (final b in avatarBoxes(a, walk: walk)) {
      final c = boxCorners(b, 0, 0, 0, facing);
      for (final f in boxFaces) {
        final p = [for (final i in f.$1) c[i]];
        // normal: (p1-p0) x (p3-p0)
        final ux = p[1].$1 - p[0].$1, uy = p[1].$2 - p[0].$2, uz = p[1].$3 - p[0].$3;
        final vx = p[3].$1 - p[0].$1, vy = p[3].$2 - p[0].$2, vz = p[3].$3 - p[0].$3;
        final nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
        // görünürlük: bakış yönü (0, cp, sp)
        if (-(ny * cp + nz * sp) <= 0 && !(nx == 0 && ny == 0 && nz == 0)) continue;
        final path = Path()..moveTo(pr(p[0].$1, p[0].$2, p[0].$3).dx, pr(p[0].$1, p[0].$2, p[0].$3).dy);
        for (var k = 1; k < 4; k++) {
          final q = pr(p[k].$1, p[k].$2, p[k].$3);
          path.lineTo(q.dx, q.dy);
        }
        path.close();
        final len = sqrt(nx * nx + ny * ny + nz * nz) + 1e-9;
        final light = (0.7 + 0.3 * (-(nz) / len).clamp(0.0, 1.0) + 0.15 * (-(nx) / len).clamp(0.0, 1.0)).clamp(0.6, 1.0);
        final cx = (p[0].$1 + p[2].$1) / 2, cy = (p[0].$2 + p[2].$2) / 2, cz = (p[0].$3 + p[2].$3) / 2;
        items.add((dep(cx, cy, cz), path, Color.lerp(Colors.black, b.color, light)!));
        if (b.face && f.$2 == 3) {
          // gözler ve ağız
          Offset at(double u, double v) {
            final x = p[0].$1 + (p[1].$1 - p[0].$1) * u + (p[3].$1 - p[0].$1) * v;
            final y = p[0].$2 + (p[1].$2 - p[0].$2) * u + (p[3].$2 - p[0].$2) * v;
            final z = p[0].$3 + (p[1].$3 - p[0].$3) * u + (p[3].$3 - p[0].$3) * v;
            return pr(x, y, z);
          }

          for (final e in const [(0.3, 0.42), (0.7, 0.42)]) {
            final path2 = Path()..addOval(Rect.fromCenter(center: at(e.$1, e.$2), width: s * 0.07, height: s * 0.09));
            items.add((dep(cx, cy, cz) + 0.001, path2, const Color(0xFF263238)));
          }
          final m = Path()
            ..moveTo(at(0.35, 0.72).dx, at(0.35, 0.72).dy)
            ..quadraticBezierTo(at(0.5, 0.82).dx, at(0.5, 0.82).dy, at(0.65, 0.72).dx, at(0.65, 0.72).dy);
          items.add((dep(cx, cy, cz) + 0.002, m, const Color(0xFFC62828)));
        }
      }
    }
    items.sort((x, y) => x.$1.compareTo(y.$1));
    for (final it in items) {
      final isMouth = it.$3 == const Color(0xFFC62828);
      canvas.drawPath(
          it.$2,
          isMouth
              ? (Paint()
                ..color = it.$3
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round)
              : (Paint()..color = it.$3));
    }
  }

  @override
  bool shouldRepaint(covariant AvatarPainter old) => true;
}
