import 'dart:math' as math;

import 'mesh.dart';
import 'vec.dart';

// ---------------- Renk ve seçenek tabloları ----------------

const paintColors = <int>[
  0xFFD32F2F, // Kırmızı
  0xFF1565C0, // Mavi
  0xFFFBC02D, // Sarı
  0xFF2E7D32, // Yeşil
  0xFFF5F5F5, // Beyaz
  0xFF212121, // Siyah
  0xFFEF6C00, // Turuncu
  0xFF6A1B9A, // Mor
  0xFF00838F, // Turkuaz
  0xFFD81B60, // Pembe
  0xFF9E9E9E, // Gümüş
  0xFFC9A227, // Altın
];
const stickerColors = <int>[0xFFFFFFFF, 0xFF111111, 0xFFFFC107, 0xFFE53935, 0xFF00BCD4];
const rimColors = <int>[0xFFCFD8DC, 0xFF263238, 0xFFFFC107, 0xFFE53935, 0xFF1E88E5];
const lightColors = <int>[0xFFFFFDE7, 0xFFFFD54F, 0xFF80D8FF];
const neonColors = <int>[0, 0xFF2979FF, 0xFFFF4081, 0xFF00E676, 0xFFD500F9, 0xFFFF9100, 0xFF18FFFF];
const tintColors = <int>[0xFF5F8296, 0xFF34444E, 0xFF15191C];

/// Arabanın tüm parçaları. Her alan bir seçenek numarasıdır.
class CarConfig {
  final int body; // 0 yarış, 1 sedan, 2 cip, 3 kamyonet
  final int color;
  final int finish; // 0 parlak, 1 metalik, 2 mat
  final int sticker; // 0 yok, 1 yarış şeridi, 2 yan şerit, 3 alev, 4 şimşek, 5 yıldız, 6 lale
  final int stickerColor;
  final int rim; // 0 klasik, 1 beş kollu, 2 on kollu, 3 yıldız, 4 kalın
  final int rimColor;
  final int tire; // 0 normal, 1 arazi
  final int spoiler; // 0 yok, 1 küçük, 2 büyük, 3 çift
  final int roof; // 0 yok, 1 bagaj, 2 siren, 3 ışık barı
  final int neon;
  final int height; // 0 alçak, 1 normal, 2 yüksek
  final int tint;
  final int light;
  final int exhaust; // 0 tek, 1 çift
  final int horn;

  const CarConfig({
    this.body = 0,
    this.color = 0,
    this.finish = 0,
    this.sticker = 0,
    this.stickerColor = 0,
    this.rim = 0,
    this.rimColor = 0,
    this.tire = 0,
    this.spoiler = 0,
    this.roof = 0,
    this.neon = 0,
    this.height = 1,
    this.tint = 0,
    this.light = 0,
    this.exhaust = 0,
    this.horn = 0,
  });

  static const keys = <String>[
    'body', 'color', 'finish', 'sticker', 'stickerColor', 'rim', 'rimColor', 'tire',
    'spoiler', 'roof', 'neon', 'height', 'tint', 'light', 'exhaust', 'horn',
  ];

  factory CarConfig.fromParts(Map<String, int> p) => CarConfig(
        body: p['body'] ?? 0,
        color: p['color'] ?? 0,
        finish: p['finish'] ?? 0,
        sticker: p['sticker'] ?? 0,
        stickerColor: p['stickerColor'] ?? 0,
        rim: p['rim'] ?? 0,
        rimColor: p['rimColor'] ?? 0,
        tire: p['tire'] ?? 0,
        spoiler: p['spoiler'] ?? 0,
        roof: p['roof'] ?? 0,
        neon: p['neon'] ?? 0,
        height: p['height'] ?? 1,
        tint: p['tint'] ?? 0,
        light: p['light'] ?? 0,
        exhaust: p['exhaust'] ?? 0,
        horn: p['horn'] ?? 0,
      );

  CarConfig withPart(String k, int v) {
    final m = toParts();
    m[k] = v;
    return CarConfig.fromParts(m);
  }

  Map<String, int> toParts() => {
        'body': body,
        'color': color,
        'finish': finish,
        'sticker': sticker,
        'stickerColor': stickerColor,
        'rim': rim,
        'rimColor': rimColor,
        'tire': tire,
        'spoiler': spoiler,
        'roof': roof,
        'neon': neon,
        'height': height,
        'tint': tint,
        'light': light,
        'exhaust': exhaust,
        'horn': horn,
      };

  int get paint => paintColors[color % paintColors.length];
  int get neonColor => neonColors[neon % neonColors.length];
  int get lightColor => lightColors[light % lightColors.length];

  /// Ağ (mesh) önbelleği için anahtar. Korna ve neon ağı değiştirmez.
  String get meshKey => [body, color, sticker, stickerColor, rim, rimColor, tire, spoiler, roof, height, tint, light, exhaust]
      .join('-');

  @override
  bool operator ==(Object other) => other is CarConfig && other.toParts().toString() == toParts().toString();

  @override
  int get hashCode => toParts().toString().hashCode;
}

// ---------------- Gövde tanımları ----------------

class _BodyDef {
  final double hw;
  final double lift; // gövdenin ek yüksekliği
  final double wheelZ;
  final List<List<double>> sections; // [z, genişlik oranı, üst yükseklik]
  final List<List<double>> cabin; // [z, tabandan yükseklik]
  final double cabinTopW; // tavan genişlik oranı
  const _BodyDef(this.hw, this.lift, this.wheelZ, this.sections, this.cabin, this.cabinTopW);
}

const _bodies = <_BodyDef>[
  // Yarış arabası: alçak, uzun burunlu
  _BodyDef(0.92, 0.0, 1.32, [
    [-2.15, 0.84, 0.66], [-2.02, 0.95, 0.78], [-1.6, 1, 0.82], [-1.0, 1, 0.82], [0, 1, 0.8],
    [1.0, 1, 0.74], [1.6, 1, 0.68], [1.95, 0.95, 0.6], [2.15, 0.86, 0.5],
  ], [
    [-1.3, 0], [-0.55, 0.36], [0.2, 0.38], [1.05, 0],
  ], 0.7),
  // Aile arabası (sedan)
  _BodyDef(0.9, 0.0, 1.38, [
    [-2.25, 0.85, 0.8], [-2.1, 0.95, 0.94], [-1.5, 1, 0.96], [-1.0, 1, 0.95], [0, 1, 0.92],
    [1.0, 1, 0.88], [1.6, 1, 0.85], [2.05, 0.95, 0.77], [2.25, 0.86, 0.64],
  ], [
    [-1.45, 0], [-0.85, 0.5], [0.45, 0.52], [1.15, 0],
  ], 0.74),
  // Cip
  _BodyDef(0.95, 0.12, 1.32, [
    [-2.1, 0.9, 1.04], [-1.96, 0.97, 1.12], [-1.3, 1, 1.14], [0, 1, 1.14], [1.2, 1, 1.1],
    [1.7, 1, 1.06], [2.0, 0.95, 0.99], [2.12, 0.88, 0.9],
  ], [
    [-2.0, 0], [-1.9, 0.6], [0.5, 0.62], [1.08, 0],
  ], 0.84),
  // Kamyonet
  _BodyDef(0.95, 0.06, 1.5, [
    [-2.42, 0.9, 0.84], [-2.3, 0.97, 0.86], [-1.0, 1, 0.86], [-0.12, 1, 0.86], [-0.06, 1, 1.06],
    [1.0, 1, 1.04], [1.7, 1, 1.0], [2.15, 0.95, 0.92], [2.4, 0.86, 0.78],
  ], [
    [-0.08, 0], [0.02, 0.56], [0.72, 0.57], [1.25, 0],
  ], 0.82),
];

// ---------------- Ağ oluşturma ----------------

final Map<String, Mesh> _cache = {};

Mesh carMesh(CarConfig c, {bool lod = false}) {
  final k = '${c.meshKey}${lod ? '-l' : ''}';
  final hit = _cache[k];
  if (hit != null) return hit;
  if (_cache.length > 40) _cache.clear();
  final m = _build(c, lod);
  _cache[k] = m;
  return m;
}

int _shade(int c, double f) {
  int ch(int v) => (v * f).round().clamp(0, 255).toInt();
  return 0xFF000000 | (ch((c >> 16) & 255) << 16) | (ch((c >> 8) & 255) << 8) | ch(c & 255);
}

Mesh _build(CarConfig c, bool lod) {
  final b = MeshBuilder();
  final def = _bodies[c.body.clamp(0, _bodies.length - 1).toInt()];
  final paint = c.paint;
  const trim = 0xFF202326;
  final glass = tintColors[c.tint % tintColors.length];
  final stripe = stickerColors[c.stickerColor % stickerColors.length];

  final bigTire = c.tire == 1;
  final tireR = bigTire ? 0.45 : 0.34;
  final tireW = bigTire ? 0.36 : 0.27;
  final heightOff = [-0.06, 0.0, 0.18][c.height.clamp(0, 2).toInt()];
  final lift = def.lift + heightOff + (tireR - 0.34);
  final hw = def.hw;
  final yb = 0.28 + lift;

  double topAt(double z) {
    final s = def.sections;
    if (z <= s.first[0]) return s.first[2] + lift;
    for (var i = 0; i < s.length - 1; i++) {
      if (z >= s[i][0] && z <= s[i + 1][0]) {
        final t = (z - s[i][0]) / (s[i + 1][0] - s[i][0]);
        return s[i][2] + (s[i + 1][2] - s[i][2]) * t + lift;
      }
    }
    return s.last[2] + lift;
  }

  // ---- Alt gövde ----
  final rings = <List<V3>>[];
  for (final s in def.sections) {
    final z = s[0];
    final w = hw * s[1];
    final top = s[2] + lift;
    final h = top - yb;
    final m1 = yb + h * 0.42, m2 = yb + h * 0.6;
    rings.add([
      V3(-w * 0.93, yb, z),
      V3(-w, yb + 0.12, z),
      V3(-w, m1, z),
      V3(-w, m2, z),
      V3(-w * 0.97, top - 0.06, z),
      V3(-w * 0.84, top, z),
      V3(-0.2, top + 0.004, z),
      V3(0.2, top + 0.004, z),
      V3(w * 0.84, top, z),
      V3(w * 0.97, top - 0.06, z),
      V3(w, m2, z),
      V3(w, m1, z),
      V3(w, yb + 0.12, z),
      V3(w * 0.93, yb, z),
    ]);
  }
  final pickupBedEnd = c.body == 3 ? 3 : -1; // bu kesite kadar olan üst yüzeyler kasa tabanı
  b.loft(rings, (s, e) {
    if (e == 0 || e == 12) return (color: trim, mat: Mat.trim);
    if ((e == 2 || e == 10) && c.sticker == 2) return (color: stripe, mat: Mat.paint);
    final isTop = e >= 4 && e <= 8;
    if (isTop && s < pickupBedEnd) return (color: 0xFF2A2A2A, mat: Mat.trim);
    if (e == 6 && c.sticker == 1) return (color: stripe, mat: Mat.paint);
    return (color: paint, mat: Mat.paint);
  }, closed: false);
  b.cap(rings.first, paint, Mat.paint, const V3(0, 0, -1));
  b.cap(rings.last, paint, Mat.paint, const V3(0, 0, 1));

  final zF = def.sections.last[0];
  final zR = def.sections.first[0];
  final topF = def.sections.last[2] + lift;
  final topR = def.sections.first[2] + lift;
  final wF = hw * def.sections.last[1];
  final wR = hw * def.sections.first[1];

  // ---- Kabin ----
  final cab = def.cabin;
  final cabSecs = <List<double>>[];
  // B direği için tavan aralığını bölen kesitler
  for (var i = 0; i < cab.length; i++) {
    cabSecs.add(cab[i]);
    if (i == 1) {
      final mid = (cab[1][0] + cab[2][0]) / 2;
      final hgt = (cab[1][1] + cab[2][1]) / 2;
      cabSecs.add([mid - 0.06, hgt]);
      cabSecs.add([mid + 0.06, hgt]);
    }
  }
  final cabRings = <List<V3>>[];
  for (final s in cabSecs) {
    final z = s[0];
    final base = topAt(z) - 0.03;
    final top = base + s[1];
    final wb = hw * 0.9;
    final wt = hw * def.cabinTopW;
    cabRings.add([
      V3(-wb, base, z),
      V3(-wt, top, z),
      V3(-0.18, top + 0.004, z),
      V3(0.18, top + 0.004, z),
      V3(wt, top, z),
      V3(wb, base, z),
    ]);
  }
  final nSeg = cabRings.length - 1; // 0: arka cam, 1: tavan, 2: direk, 3: tavan, 4: ön cam
  b.loft(cabRings, (s, e) {
    final side = e == 0 || e == 4;
    final top = e >= 1 && e <= 3;
    if (side) {
      if (s == 2) return (color: paint, mat: Mat.paint);
      return (color: glass, mat: Mat.glass);
    }
    if (top) {
      if (s == 0 || s == nSeg - 1) return (color: glass, mat: Mat.glass);
      if (e == 2 && c.sticker == 1) return (color: stripe, mat: Mat.paint);
      return (color: paint, mat: Mat.paint);
    }
    return null;
  }, closed: false, smooth: false);

  final roofZ0 = cabSecs[1][0], roofZ1 = cabSecs[cabSecs.length - 2][0];
  final roofY = topAt((roofZ0 + roofZ1) / 2) - 0.03 + cab[1][1];
  final cabFrontZ = cab.last[0];

  // Aynalar (kabine bitişik)
  for (final sx in [-1.0, 1.0]) {
    final zM = cabFrontZ - 0.32;
    final y = topAt(zM) + 0.04;
    final xIn = sx * hw * 0.86, xOut = sx * (hw * 0.86 + 0.17);
    b.box(V3(sx > 0 ? xIn : xOut, y, zM - 0.05), V3(sx > 0 ? xOut : xIn, y + 0.1, zM + 0.04), paint, Mat.paint);
  }

  // ---- Ön: farlar, ızgara, plaka ----
  final fy = topF - 0.13;
  for (final sx in [-1.0, 1.0]) {
    final x = sx * wF * 0.62;
    b.box(V3(x - 0.2, fy - 0.07, zF - 0.06), V3(x + 0.2, fy + 0.06, zF + 0.025), c.lightColor, Mat.light);
    b.mesh.headlights.add(V3(x, fy, zF + 0.03));
  }
  b.box(V3(-wF * 0.3, yb + 0.14, zF - 0.04), V3(wF * 0.3, math.min(fy - 0.1, yb + 0.26), zF + 0.015), 0xFF15171A, Mat.trim);
  b.box(V3(-0.2, yb + 0.03, zF - 0.02), V3(0.2, yb + 0.12, zF + 0.035), 0xFFF5F5F5, Mat.trim);

  // ---- Arka: stop lambaları, plaka, egzoz ----
  final ry = topR - 0.13;
  for (final sx in [-1.0, 1.0]) {
    final x = sx * wR * 0.66;
    b.box(V3(x - 0.18, ry - 0.06, zR - 0.025), V3(x + 0.18, ry + 0.05, zR + 0.06), 0xFFE53935, Mat.tail);
  }
  b.box(V3(-0.22, yb + 0.12, zR - 0.035), V3(0.22, yb + 0.24, zR + 0.02), 0xFFF5F5F5, Mat.trim);
  final exX = c.exhaust == 1 ? [-wR * 0.55, wR * 0.55] : [wR * 0.55];
  for (final x in exX) {
    b.cylinder(V3(x, yb + 0.02, zR - 0.08), 2, 0.06, 0.22, 10, 0xFFB0BEC5, Mat.chrome, capColor: 0xFF111111, capMat: Mat.trim);
  }

  // ---- Kamyonet kasası ----
  if (c.body == 3) {
    const bedZ0 = -2.32, bedZ1 = -0.12;
    final floor = 0.86 + lift;
    final wallTop = floor + 0.26;
    for (final sx in [-1.0, 1.0]) {
      final x0 = sx > 0 ? hw - 0.09 : -hw;
      b.box(V3(x0, floor - 0.02, bedZ0), V3(x0 + 0.09, wallTop, bedZ1), paint, Mat.paint);
    }
    b.box(V3(-hw, floor - 0.02, bedZ0 - 0.08), V3(hw, wallTop, bedZ0), paint, Mat.paint);
  }

  // ---- Spoiler ----
  if (c.spoiler > 0 && c.body != 3) {
    final z = zR + 0.28;
    final base = topAt(z);
    final hgt = c.spoiler == 1 ? 0.12 : 0.3;
    final wingW = hw * (c.spoiler == 1 ? 0.8 : 0.95);
    for (final sx in [-1.0, 1.0]) {
      final x = sx * wingW * 0.7;
      b.box(V3(x - 0.04, base - 0.02, z - 0.06), V3(x + 0.04, base + hgt, z + 0.06), trim, Mat.trim);
    }
    final wingC = c.spoiler == 1 ? paint : trim;
    b.box(V3(-wingW, base + hgt, z - 0.2), V3(wingW, base + hgt + 0.05, z + 0.14), wingC, Mat.paint);
    if (c.spoiler == 3) {
      b.box(V3(-wingW, base + hgt + 0.16, z - 0.16), V3(wingW, base + hgt + 0.2, z + 0.1), paint, Mat.paint);
    }
    if (c.spoiler >= 2) {
      for (final sx in [-1.0, 1.0]) {
        final x = sx * wingW;
        b.box(V3(x - 0.02, base + hgt - 0.08, z - 0.24), V3(x + 0.02, base + hgt + 0.26, z + 0.18), paint, Mat.paint);
      }
    }
  }

  // ---- Tavan aksesuarları ----
  if (c.roof == 1) {
    for (final sx in [-1.0, 1.0]) {
      final x = sx * hw * 0.55;
      b.box(V3(x - 0.03, roofY, roofZ0 + 0.05), V3(x + 0.03, roofY + 0.08, roofZ1 - 0.05), 0xFF37474F, Mat.chrome);
    }
    for (final t in [0.2, 0.5, 0.8]) {
      final z = roofZ0 + (roofZ1 - roofZ0) * t;
      b.box(V3(-hw * 0.6, roofY + 0.06, z - 0.03), V3(hw * 0.6, roofY + 0.1, z + 0.03), 0xFF263238, Mat.trim);
    }
  } else if (c.roof == 2) {
    final z = (roofZ0 + roofZ1) / 2;
    b.box(V3(-0.5, roofY, z - 0.12), V3(0.5, roofY + 0.06, z + 0.12), trim, Mat.trim);
    b.box(V3(-0.48, roofY + 0.06, z - 0.1), V3(-0.02, roofY + 0.16, z + 0.1), 0xFFFF1744, Mat.light);
    b.box(V3(0.02, roofY + 0.06, z - 0.1), V3(0.48, roofY + 0.16, z + 0.1), 0xFF2979FF, Mat.light);
  } else if (c.roof == 3) {
    final z = roofZ1 - 0.12;
    b.box(V3(-hw * 0.7, roofY, z - 0.08), V3(hw * 0.7, roofY + 0.05, z + 0.08), trim, Mat.trim);
    for (var i = 0; i < 4; i++) {
      final x = -hw * 0.6 + i * hw * 0.4;
      b.box(V3(x - 0.12, roofY + 0.05, z - 0.06), V3(x + 0.12, roofY + 0.15, z + 0.08), 0xFFFFF59D, Mat.light);
    }
  }

  // ---- Tekerlekler ----
  for (final wz in [def.wheelZ, -def.wheelZ]) {
    for (final sx in [-1.0, 1.0]) {
      _wheel(b, V3(sx * (hw - 0.1), tireR, wz), sx, tireR, tireW, c, lod);
    }
  }

  // ---- Çamurluk kavisleri ----
  for (final wz in [def.wheelZ, -def.wheelZ]) {
    for (final sx in [-1.0, 1.0]) {
      _flare(b, sx, hw, wz, tireR, paint, lod);
    }
  }

  // ---- Çıkartmalar ve kapı çizgileri (yan yüzeyler) ----
  final sideTop = topAt(0) - 0.1;
  final sideBot = yb + 0.14;
  for (final sx in [-1.0, 1.0]) {
    final x = sx * (hw + 0.006);
    final out = V3(sx, 0, 0);
    V3 map(double u, double v) => V3(x, v, u);
    // Kapı çizgileri
    final doorZ = [cab[1][0] + 0.15, (cab[1][0] + cab[2][0]) / 2, cabFrontZ - 0.1];
    for (final z in doorZ) {
      b.decalPolygon([
        [z - 0.008, sideBot],
        [z + 0.008, sideBot],
        [z + 0.008, sideTop],
        [z - 0.008, sideTop],
      ], map, 0xFF1B1B1B, out);
    }
    // Kapı kolları
    for (final z in [doorZ[1] - 0.1, doorZ[2] - 0.1]) {
      final v = sideTop - 0.08;
      b.decalPolygon([
        [z - 0.12, v - 0.02],
        [z, v - 0.02],
        [z, v + 0.02],
        [z - 0.12, v + 0.02],
      ], map, _shade(paint, 0.6), out);
    }
    final sv = (sideTop + sideBot) / 2;
    final sh = (sideTop - sideBot);
    switch (c.sticker) {
      case 3: // alev
        {
        final f = <List<double>>[
          [1.1, 0.0], [0.6, 0.32], [0.45, 0.12], [0.1, 0.42], [0.0, 0.15], [-0.45, 0.38], [-0.35, 0.08],
          [-0.9, 0.2], [-0.55, -0.05], [-0.95, -0.3], [-0.3, -0.25], [0.2, -0.4], [0.35, -0.18], [0.8, -0.3],
        ];
        b.decalPolygon([for (final p in f) [p[0] * 0.72 + 0.1, sv + p[1] * sh * 0.9]], map, stripe, out);
        }
        break;
      case 4: // şimşek
        {
        final f = <List<double>>[
          [-0.9, 0.35], [0.05, 0.35], [-0.1, 0.05], [0.9, 0.12], [-0.2, -0.45], [0.0, -0.12], [-0.85, -0.12],
        ];
        b.decalPolygon([for (final p in f) [p[0] * 0.75, sv + p[1] * sh * 0.95]], map, stripe, out);
        }
        break;
      case 5: // Selçuklu yıldızı
        {
        final pts = <List<double>>[];
        final r1 = sh * 0.42, r2 = sh * 0.3;
        for (var i = 0; i < 16; i++) {
          final r = i.isEven ? r1 : r2;
          final a = i * math.pi / 8;
          pts.add([r * math.cos(a), sv + r * math.sin(a)]);
        }
        b.decalPolygon(pts, map, stripe, out);
        }
        break;
      case 6: // lale
        {
        final s = sh * 0.45;
        final tulip = <List<double>>[
          [0.0, -0.1], [-0.35, 0.05], [-0.42, 0.55], [-0.2, 0.35], [0.0, 0.7], [0.2, 0.35], [0.42, 0.55], [0.35, 0.05],
        ];
        b.decalPolygon([for (final p in tulip) [p[0] * s, sv + p[1] * s]], map, stripe, out);
        b.decalPolygon([
          [-0.025, sv - 0.1 * s],
          [0.025, sv - 0.1 * s],
          [0.025, sv - 0.9 * s],
          [-0.025, sv - 0.9 * s],
        ], map, 0xFF2E7D32, out);
        }
        break;
    }
  }

  b.mesh.halfW = hw * 1.05;
  b.mesh.halfL = math.max(zF.abs(), zR.abs()) * 1.02;
  return b.mesh;
}

void _wheel(MeshBuilder b, V3 c, double side, double r, double w, CarConfig cfg, bool lod) {
  final segs = lod ? 12 : 20;
  const rubber = 0xFF1C1C1E;
  final rimC = rimColors[cfg.rimColor % rimColors.length];
  final xo = c.x + side * w / 2;
  final xi = c.x - side * w / 2;
  final outer = <V3>[], inner = <V3>[], outerSoft = <V3>[], innerSoft = <V3>[];
  for (var i = 0; i < segs; i++) {
    final t = i / segs * 2 * math.pi;
    final y = c.y + r * math.sin(t), z = c.z + r * math.cos(t);
    final y2 = c.y + r * 0.92 * math.sin(t), z2 = c.z + r * 0.92 * math.cos(t);
    outer.add(V3(xo - side * 0.03, y, z));
    inner.add(V3(xi + side * 0.03, y, z));
    outerSoft.add(V3(xo, y2, z2));
    innerSoft.add(V3(xi, y2, z2));
  }
  // Lastik sırtı (yuvarlatılmış)
  b.loft([innerSoft, inner, outer, outerSoft], (s, e) => (color: rubber, mat: Mat.rubber), closed: true);
  // İç yan yüzey (kapalı koyu disk)
  b.cap(innerSoft, rubber, Mat.rubber, V3(-side, 0, 0));
  // Dış yan yüzey: lastik halkası + jant
  final rr = r * (cfg.tire == 1 ? 0.6 : 0.7);
  final out = V3(side, 0, 0);
  final ringIn = <V3>[];
  for (var i = 0; i < segs; i++) {
    final t = i / segs * 2 * math.pi;
    ringIn.add(V3(xo, c.y + rr * math.sin(t), c.z + rr * math.cos(t)));
  }
  for (var i = 0; i < segs; i++) {
    final j = (i + 1) % segs;
    b.quad(outerSoft[i], outerSoft[j], ringIn[j], ringIn[i], rubber, Mat.rubber, outward: out);
  }
  // Jant: dış dudak, kollar, göbek
  final lip = rr * 0.86, hub = rr * 0.26;
  final xr = xo - side * 0.02;
  V3 pt(double rad, double t, double x) => V3(x, c.y + rad * math.sin(t), c.z + rad * math.cos(t));
  final n = lod ? 12 : 24;
  for (var i = 0; i < n; i++) {
    final t0 = i / n * 2 * math.pi, t1 = (i + 1) / n * 2 * math.pi;
    // dudak
    b.quad(pt(rr, t0, xo), pt(rr, t1, xo), pt(lip, t1, xr), pt(lip, t0, xr), rimC, Mat.chrome, outward: out);
    final spoke = switch (cfg.rim) {
      1 => i % 4 < 2,
      2 => i.isEven,
      3 => i % 8 < 2,
      4 => true,
      _ => i % 3 != 0,
    };
    final spokeC = spoke ? rimC : 0xFF15171A;
    final spokeM = spoke ? Mat.chrome : Mat.trim;
    final xs = spoke ? xr : xr - side * 0.04;
    b.quad(pt(lip, t0, xs), pt(lip, t1, xs), pt(hub, t1, xs), pt(hub, t0, xs), spokeC, spokeM, outward: out);
    // göbek
    b.tri(pt(hub, t0, xr + side * 0.01), pt(hub, t1, xr + side * 0.01), V3(xr + side * 0.03, c.y, c.z),
        cfg.rim == 4 ? 0xFF263238 : rimC, Mat.chrome,
        outward: out);
  }
}

void _flare(MeshBuilder b, double side, double hw, double wz, double r, int paint, bool lod) {
  final n = lod ? 6 : 10;
  final ri = r + 0.05, ro = r + 0.13;
  final xi = side * (hw - 0.04), xo = side * (hw + 0.07);
  final cy = r;
  V3 p(double rad, double a, double x) => V3(x, cy + rad * math.sin(a), wz + rad * math.cos(a));
  final out = V3(side, 0, 0);
  for (var i = 0; i < n; i++) {
    final a0 = 0.12 + (math.pi - 0.24) * i / n, a1 = 0.12 + (math.pi - 0.24) * (i + 1) / n;
    // yan yüz
    b.quad(p(ri, a0, xo), p(ro, a0, xo), p(ro, a1, xo), p(ri, a1, xo), paint, Mat.paint, outward: out);
    // dış kavis yüzeyi
    final mid = (a0 + a1) / 2;
    final radial = V3(0, math.sin(mid), math.cos(mid));
    b.quad(p(ro, a0, xi), p(ro, a0, xo), p(ro, a1, xo), p(ro, a1, xi), paint, Mat.paint, outward: radial);
    // iç (karanlık) yüzey
    b.quad(p(ri, a0, xi), p(ri, a0, xo), p(ri, a1, xo), p(ri, a1, xi), 0xFF111214, Mat.trim, outward: -radial);
  }
}
