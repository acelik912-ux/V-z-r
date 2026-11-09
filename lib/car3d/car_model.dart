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

const bodyCount = 11;

/// Profil tabanlı gövde: yandan bakışta bel çizgisi, tavan ve genişlik eğrileri.
class _Profile {
  final double zR, zF, hw, bottom;
  final List<List<double>> width; // [z, oran]
  final List<List<double>> belt; // [z, y]
  final List<List<double>> roof; // [z, y]; y < 0 => bel hizası
  final List<double> pillars;
  final List<double> wheelZ;
  final double tireScale;
  final double tumble; // tavan daralması
  final double bedFront; // kamyonet kasasının ön sınırı (yoksa -99)
  final bool flares;
  const _Profile({
    required this.zR,
    required this.zF,
    required this.hw,
    required this.bottom,
    required this.width,
    required this.belt,
    required this.roof,
    this.pillars = const [],
    required this.wheelZ,
    this.tireScale = 1.0,
    this.tumble = 0.78,
    this.bedFront = -99,
    this.flares = true,
  });
}

const _profiles = <int, _Profile>{
  0: _Profile(
    zR: -2.15, zF: 2.15, hw: 0.94, bottom: 0.26,
    width: [[-2.15, 0.8], [-1.85, 0.97], [-1.2, 1], [1.2, 1], [1.85, 0.95], [2.15, 0.78]],
    belt: [[-2.15, 0.6], [-1.9, 0.8], [-1.2, 0.84], [0, 0.82], [1.0, 0.75], [1.8, 0.64], [2.15, 0.48]],
    roof: [[-1.35, -1], [-0.6, 1.16], [0.2, 1.18], [1.05, -1]],
    pillars: [-0.2], wheelZ: [1.32, -1.32], tumble: 0.74),
  1: _Profile(
    zR: -2.25, zF: 2.25, hw: 0.9, bottom: 0.3,
    width: [[-2.25, 0.84], [-2.0, 0.98], [2.0, 0.97], [2.25, 0.82]],
    belt: [[-2.25, 0.76], [-2.0, 0.93], [-1.4, 0.96], [0, 0.93], [1.4, 0.88], [2.0, 0.8], [2.25, 0.64]],
    roof: [[-1.5, -1], [-0.85, 1.44], [0.45, 1.46], [1.15, -1]],
    pillars: [-0.2], wheelZ: [1.38, -1.38]),
  2: _Profile(
    zR: -2.1, zF: 2.12, hw: 0.96, bottom: 0.42,
    width: [[-2.1, 0.9], [-1.9, 1], [1.9, 1], [2.12, 0.88]],
    belt: [[-2.1, 1.0], [-1.9, 1.1], [0, 1.13], [1.3, 1.1], [1.9, 1.04], [2.12, 0.9]],
    roof: [[-2.02, -1], [-1.88, 1.76], [0.55, 1.78], [1.1, -1]],
    pillars: [-1.05, 0.0], wheelZ: [1.32, -1.32], tireScale: 1.15, tumble: 0.86),
  3: _Profile(
    zR: -2.42, zF: 2.4, hw: 0.96, bottom: 0.38,
    width: [[-2.42, 0.94], [-2.3, 1], [2.2, 0.98], [2.4, 0.86]],
    belt: [[-2.42, 0.94], [-2.3, 0.98], [0, 1.02], [1.4, 1.02], [2.1, 0.96], [2.4, 0.8]],
    roof: [[-0.12, -1], [0.0, 1.7], [0.75, 1.72], [1.28, -1]],
    wheelZ: [1.55, -1.45], tireScale: 1.1, tumble: 0.84, bedFront: -0.14),
  4: _Profile(
    zR: -1.7, zF: 1.75, hw: 0.86, bottom: 0.3,
    width: [[-1.7, 0.92], [-1.5, 1], [1.5, 1], [1.75, 0.84]],
    belt: [[-1.7, 0.86], [-1.5, 0.93], [0, 0.92], [1.2, 0.86], [1.75, 0.64]],
    roof: [[-1.64, -1], [-1.52, 1.52], [0.2, 1.56], [1.0, -1]],
    pillars: [-0.62], wheelZ: [1.12, -1.12], tireScale: 0.95, tumble: 0.8),
  5: _Profile(
    zR: -2.4, zF: 2.4, hw: 0.98, bottom: 0.36,
    width: [[-2.4, 0.95], [-2.25, 1], [2.2, 1], [2.4, 0.88]],
    belt: [[-2.4, 1.0], [-2.2, 1.06], [1.6, 1.06], [2.2, 0.94], [2.4, 0.8]],
    roof: [[-2.33, -1], [-2.25, 1.98], [1.2, 2.0], [2.05, -1]],
    pillars: [-1.3, -0.3, 0.65], wheelZ: [1.55, -1.55], tumble: 0.9),
  6: _Profile(
    zR: -2.25, zF: 2.28, hw: 0.97, bottom: 0.4,
    width: [[-2.25, 0.9], [-2.0, 1], [1.9, 1], [2.28, 0.84]],
    belt: [[-2.25, 0.98], [-2.0, 1.08], [0, 1.1], [1.4, 1.04], [2.0, 0.95], [2.28, 0.8]],
    roof: [[-1.98, -1], [-1.35, 1.62], [0.3, 1.66], [1.25, -1]],
    pillars: [-0.45], wheelZ: [1.45, -1.45], tireScale: 1.1, tumble: 0.8),
  9: _Profile(
    zR: -3.0, zF: 2.4, hw: 1.0, bottom: 0.5,
    width: [[-3.0, 0.97], [-2.85, 1], [2.25, 1], [2.4, 0.9]],
    belt: [[-3.0, 1.12], [1.9, 1.15], [2.25, 1.06], [2.4, 0.92]],
    roof: [[1.0, -1], [1.12, 2.05], [1.72, 2.05], [2.24, -1]],
    wheelZ: [1.72, -1.2, -2.25], tireScale: 1.2, tumble: 0.92, flares: false),
};

double _catmull(List<List<double>> k, double z) {
  if (z <= k.first[0]) return k.first[1];
  if (z >= k.last[0]) return k.last[1];
  var i = 0;
  while (i < k.length - 2 && z > k[i + 1][0]) {
    i++;
  }
  final p0 = k[math.max(0, i - 1)][1], p1 = k[i][1], p2 = k[i + 1][1], p3 = k[math.min(k.length - 1, i + 2)][1];
  final t = (z - k[i][0]) / (k[i + 1][0] - k[i][0]);
  final t2 = t * t, t3 = t2 * t;
  return 0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

final Map<String, Mesh> _cache = {};

Mesh carMesh(CarConfig c, {bool lod = false}) {
  final k = '${c.meshKey}${lod ? '-l' : ''}';
  final hit = _cache[k];
  if (hit != null) return hit;
  if (_cache.length > 60) _cache.clear();
  final m = _build(c, lod);
  _cache[k] = m;
  return m;
}

int _shade(int c, double f) {
  int ch(int v) => (v * f).round().clamp(0, 255).toInt();
  return 0xFF000000 | (ch((c >> 16) & 255) << 16) | (ch((c >> 8) & 255) << 8) | ch(c & 255);
}

class _Ctx {
  final MeshBuilder b;
  final CarConfig c;
  final bool lod;
  final int paint;
  final int glass;
  final int stripe;
  final double tireR;
  final double tireW;
  final double lift;
  _Ctx(this.b, this.c, this.lod, this.paint, this.glass, this.stripe, this.tireR, this.tireW, this.lift);
}

Mesh _build(CarConfig c, bool lod) {
  final b = MeshBuilder();
  final body = c.body.clamp(0, bodyCount - 1).toInt();
  final prof = _profiles[body == 10 ? 9 : body];
  final tireScale = prof?.tireScale ?? (body == 8 ? 1.25 : 1.0);
  final bigTire = c.tire == 1 && body != 7;
  final tireR = 0.36 * tireScale * (bigTire ? 1.25 : 1.0);
  final tireW = 0.28 * (bigTire ? 1.3 : 1.0) * (body == 8 ? 1.3 : 1.0);
  final heightOff = [-0.06, 0.0, 0.18][c.height.clamp(0, 2).toInt()];
  final lift = heightOff + (tireR - 0.36 * tireScale);
  final ctx = _Ctx(b, c, lod, c.paint, tintColors[c.tint % tintColors.length],
      stickerColors[c.stickerColor % stickerColors.length], tireR, tireW, lift);

  if (prof != null) {
    _profileBody(ctx, prof, body);
  } else if (body == 7) {
    _formula(ctx);
  } else {
    _buggy(ctx);
  }
  return b.build();
}

// ---------------- Profil gövdesi ----------------

void _profileBody(_Ctx x, _Profile p, int body) {
  final b = x.b, c = x.c, lift = x.lift;
  const trim = 0xFF202326;
  double width(double z) => p.hw * _catmull(p.width, z);
  double belt(double z) => _catmull(p.belt, z) + lift;
  // Tavan anahtarlarını bel hizasıyla çöz
  final roofKeys = [for (final k in p.roof) [k[0], k[1] < 0 ? _catmull(p.belt, k[0]) : k[1]]];
  double roof(double z) {
    if (z <= roofKeys.first[0] || z >= roofKeys.last[0]) return belt(z);
    var i = 0;
    while (i < roofKeys.length - 2 && z > roofKeys[i + 1][0]) {
      i++;
    }
    final t = (z - roofKeys[i][0]) / (roofKeys[i + 1][0] - roofKeys[i][0]);
    return math.max(belt(z), _lerp(roofKeys[i][1], roofKeys[i + 1][1], t) + lift);
  }

  double bottom(double z) {
    final d = math.min(z - p.zR, p.zF - z);
    final e = (1 - d / 0.4).clamp(0.0, 1.0).toDouble();
    return p.bottom + lift + e * e * 0.12;
  }

  // Kesit konumları: düzgün ızgara + tavan anahtarları
  final n = x.lod ? 12 : 22;
  final zs = <double>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final u = 0.5 - 0.5 * math.cos(t * math.pi); // uçlarda sık
    zs.add(_lerp(p.zR, p.zF, u * 0.85 + t * 0.15));
  }
  for (final k in roofKeys) {
    zs.add(k[0]);
  }
  zs.sort();
  final zz = <double>[];
  for (final z in zs) {
    if (zz.isEmpty || z - zz.last > 0.03) zz.add(z);
  }
  if (zz.last < p.zF) zz.add(p.zF);

  List<V3> ring(double z) {
    final w = width(z);
    final bt = belt(z);
    final rf = roof(z);
    final bo = bottom(z);
    final r = math.min(0.2, (bt - bo) * 0.38);
    final h = rf - bt;
    final s = (h / 0.25).clamp(0.0, 1.0).toDouble();
    final gb = w - r * 1.1;
    final gt = gb * p.tumble;
    final rr = math.min(0.1, h * 0.3);
    final m1 = bo + (bt - bo) * 0.45, m2 = bo + (bt - bo) * 0.62;
    final hoodCrown = 0.035;
    // Kaput (kabin yok) konumları
    final sx = w - r;
    final hood = [
      for (final f in [0.2, 0.4, 0.6, 0.8]) [_lerp(sx, 0.2, f), bt + hoodCrown * f]
    ];
    // Kabin konumları
    final cab = [
      [gb, bt + 0.01],
      [(gb + gt) / 2 + 0.03, bt + h * 0.5],
      [gt, rf - rr],
      [gt - rr, rf],
    ];
    final g = [
      for (var i = 0; i < 4; i++) [_lerp(hood[i][0], cab[i][0], s), _lerp(hood[i][1], cab[i][1], s)]
    ];
    final top = (h > 0.01 ? rf : bt) + (h > 0.01 ? 0.025 : hoodCrown);
    final left = <List<double>>[
      [w * 0.86, bo],
      [w * 0.97, bo + r * 0.3],
      [w, bo + r],
      [w, m1],
      [w, m2],
      [w, bt - r],
      [w - r * 0.29, bt - r * 0.29],
      [w - r, bt],
      ...g,
      [0.2, top],
    ];
    return [
      for (final q in left) V3(-q[0], q[1], z),
      for (final q in left.reversed) V3(q[0], q[1], z),
    ];
  }

  final rings = [for (final z in zz) ring(z)];
  final hs = [for (final z in zz) roof(z) - belt(z)];
  bool isPillar(double z0, double z1) {
    for (final pz in p.pillars) {
      if ((z0 + z1) / 2 - pz < 0.08 && pz - (z0 + z1) / 2 < 0.08) return true;
    }
    return false;
  }

  final bodyPart = b.newPart();
  b.loft(rings, (sg, e) {
    final le = e <= 12 ? e : 24 - e;
    final z0 = zz[sg], z1 = zz[sg + 1];
    final h0 = hs[sg], h1 = hs[sg + 1];
    final cabin = h0 > 0.02 || h1 > 0.02;
    final slope = ((roof(z1) - roof(z0)) / (z1 - z0)).abs();
    final ramp = cabin && slope > 0.3;
    if (le <= 1) return (color: trim, mat: Mat.trim);
    if (le == 3 && c.sticker == 2) return (color: x.stripe, mat: Mat.paint);
    if ((le == 8 || le == 9) && cabin && (h0 > 0.08 || h1 > 0.08)) {
      if (isPillar(z0, z1) && !ramp) return (color: x.paint, mat: Mat.paint);
      return (color: x.glass, mat: Mat.glass);
    }
    if (le >= 10) {
      if (ramp && (h0 > 0.05 || h1 > 0.05)) return (color: x.glass, mat: Mat.glass);
      if (!cabin && (z1 <= p.bedFront + 0.001)) return (color: 0xFF2A2B2E, mat: Mat.trim);
      if (le == 12 && c.sticker == 1) return (color: x.stripe, mat: Mat.paint);
    }
    if (le >= 7 && !cabin && z1 <= p.bedFront + 0.001) return (color: 0xFF2A2B2E, mat: Mat.trim);
    return (color: x.paint, mat: Mat.paint);
  }, newPartFlag: false);
  b.cap(rings.first, x.paint, Mat.paint, const V3(0, 0, -1));
  b.cap(rings.last, x.paint, Mat.paint, const V3(0, 0, 1));

  final zF = p.zF, zR = p.zR;
  final wF = width(zF - 0.05), wR = width(zR + 0.05);
  final bF = bottom(zF), bR = bottom(zR);
  final tF = belt(zF), tR = belt(zR);

  // ---- Ön yüz ----
  if (body == 6) {
    // Özgün tasarım: boydan boya ışık şeridi
    b.softBox(V3(-wF * 0.82, tF - 0.1, zF - 0.06), V3(wF * 0.82, tF - 0.03, zF + 0.03), c.lightColor, Mat.light, r: 0.03);
    b.mesh.headlights.addAll([V3(-wF * 0.6, tF - 0.07, zF), V3(wF * 0.6, tF - 0.07, zF)]);
  } else {
    final fy = math.max(bF + 0.2, tF - 0.14);
    for (final sx in [-1.0, 1.0]) {
      final hx = sx * wF * 0.6;
      b.softBox(V3(hx - 0.19, fy - 0.08, zF - 0.08), V3(hx + 0.19, fy + 0.07, zF + 0.03), c.lightColor, Mat.light, r: 0.06);
      b.mesh.headlights.add(V3(hx, fy, zF + 0.03));
    }
  }
  b.softBox(V3(-wF * 0.34, bF + 0.07, zF - 0.06), V3(wF * 0.34, math.min(bF + 0.22, tF - 0.2), zF + 0.02), 0xFF16181B, Mat.trim,
      r: 0.05);
  b.box(V3(-0.2, bF + 0.0, zF - 0.02), V3(0.2, bF + 0.08, zF + 0.03), 0xFFF5F5F5, Mat.trim);

  // ---- Arka yüz ----
  if (body == 6) {
    b.softBox(V3(-wR * 0.85, tR - 0.12, zR - 0.03), V3(wR * 0.85, tR - 0.05, zR + 0.06), 0xFFE53935, Mat.tail, r: 0.03);
  } else if (body != 9 && body != 10) {
    final ry = math.max(bR + 0.22, tR - 0.14);
    for (final sx in [-1.0, 1.0]) {
      final hx = sx * wR * 0.66;
      b.softBox(V3(hx - 0.17, ry - 0.07, zR - 0.03), V3(hx + 0.17, ry + 0.06, zR + 0.07), 0xFFE53935, Mat.tail, r: 0.05);
    }
  }
  if (body != 9 && body != 10) {
    b.box(V3(-0.22, bR + 0.1, zR - 0.035), V3(0.22, bR + 0.22, zR + 0.02), 0xFFF5F5F5, Mat.trim);
  }
  final exX = c.exhaust == 1 ? [-wR * 0.55, wR * 0.55] : [wR * 0.55];
  for (final ex in exX) {
    b.cylinder(V3(ex, bR - 0.02, zR - 0.06), 2, 0.06, 0.22, 10, 0xFFB0BEC5, Mat.chrome, capColor: 0xFF111111, capMat: Mat.trim);
  }

  // ---- Kabin aksesuarları ----
  final hasCabin = roofKeys.length >= 4;
  final roofZ0 = roofKeys[1][0], roofZ1 = roofKeys[roofKeys.length - 2][0];
  final roofY = roof((roofZ0 + roofZ1) / 2) + 0.02;
  final wsBase = roofKeys.last[0];
  if (hasCabin) {
    for (final sx in [-1.0, 1.0]) {
      final zM = wsBase - 0.12;
      final y = belt(zM) + 0.06;
      final w = width(zM);
      final r0 = math.min(0.2, (belt(zM) - bottom(zM)) * 0.38);
      final base = w - r0 * 1.1;
      final xIn = sx * (base - 0.02), xOut = sx * (base + 0.16);
      b.softBox(V3(math.min(xIn, xOut), y, zM - 0.05), V3(math.max(xIn, xOut), y + 0.11, zM + 0.04), x.paint, Mat.paint,
          r: 0.04, side: sx);
    }
  }

  // ---- Kamyonet kasası ----
  if (body == 3) {
    final bedTop = belt(-1.0) + 0.2;
    for (final sx in [-1.0, 1.0]) {
      final w = width(-1.0);
      final x0 = sx > 0 ? w - 0.1 : -w;
      b.softBox(V3(x0, belt(-1.0) - 0.06, zR + 0.05), V3(x0 + 0.1, bedTop, p.bedFront), x.paint, Mat.paint, r: 0.03, side: sx);
    }
    b.softBox(V3(-width(zR + 0.1), belt(zR) - 0.06, zR - 0.02), V3(width(zR + 0.1), bedTop, zR + 0.1), x.paint, Mat.paint,
        r: 0.03);
  }

  // ---- İtfaiye ve kamyon kasası ----
  if (body == 9 || body == 10) {
    final top = 2.2 + lift;
    final boxC = body == 9 ? x.paint : 0xFFECEFF1;
    b.softBox(V3(-p.hw, belt(-1.0) - 0.05, zR + 0.02), V3(p.hw, top, 0.92), boxC, Mat.paint, r: 0.1);
    // Arka lambalar ve kasa şeridi
    for (final sx in [-1.0, 1.0]) {
      b.softBox(V3(sx * 0.75 - 0.12, belt(zR) + 0.0, zR - 0.04), V3(sx * 0.75 + 0.12, belt(zR) + 0.14, zR + 0.04),
          0xFFE53935, Mat.tail, r: 0.03);
    }
    final band = body == 9 ? 0xFFF5F5F5 : x.paint;
    for (final sx in [-1.0, 1.0]) {
      b.box(V3(sx > 0 ? p.hw : -p.hw - 0.012, belt(0) + 0.25, zR + 0.15), V3(sx > 0 ? p.hw + 0.012 : -p.hw, belt(0) + 0.42, 0.8),
          band, Mat.paint, side: sx);
    }
    if (body == 9) {
      // Merdiven
      for (final sx in [-1.0, 1.0]) {
        b.box(V3(sx * 0.45 - 0.04, top + 0.06, zR + 0.3), V3(sx * 0.45 + 0.04, top + 0.14, 1.6), 0xFFCFD8DC, Mat.chrome);
      }
      for (var i = 0; i < 9; i++) {
        final z = zR + 0.45 + i * 0.45;
        b.box(V3(-0.45, top + 0.08, z - 0.03), V3(0.45, top + 0.12, z + 0.03), 0xFFCFD8DC, Mat.chrome);
      }
      b.box(V3(-0.15, top, -1.0), V3(0.15, top + 0.08, -0.7), 0xFF37474F, Mat.trim);
      // Siren
      final sy = roofY;
      final z = (roofZ0 + roofZ1) / 2;
      b.box(V3(-0.55, sy, z - 0.12), V3(0.55, sy + 0.06, z + 0.12), 0xFF202326, Mat.trim);
      b.softBox(V3(-0.52, sy + 0.06, z - 0.1), V3(-0.02, sy + 0.18, z + 0.1), 0xFFFF1744, Mat.light, r: 0.04);
      b.softBox(V3(0.02, sy + 0.06, z - 0.1), V3(0.52, sy + 0.18, z + 0.1), 0xFFFF1744, Mat.light, r: 0.04);
    }
  }

  // ---- Spoiler ----
  if (c.spoiler > 0 && const [0, 1, 2, 4, 6].contains(body)) {
    final z = zR + 0.3;
    final base = body == 2 || body == 4 ? roof(zR + 0.3) : belt(z);
    final hgt = c.spoiler == 1 ? 0.1 : 0.28;
    final wingW = width(z) * (c.spoiler == 1 ? 0.85 : 0.98);
    for (final sx in [-1.0, 1.0]) {
      final px = sx * wingW * 0.7;
      b.box(V3(px - 0.035, base - 0.02, z - 0.06), V3(px + 0.035, base + hgt, z + 0.06), 0xFF202326, Mat.trim);
    }
    final wingC = c.spoiler == 1 ? x.paint : 0xFF202326;
    b.softBox(V3(-wingW, base + hgt, z - 0.22), V3(wingW, base + hgt + 0.06, z + 0.14), wingC, Mat.paint, r: 0.03);
    if (c.spoiler == 3) {
      b.softBox(V3(-wingW, base + hgt + 0.16, z - 0.18), V3(wingW, base + hgt + 0.21, z + 0.1), x.paint, Mat.paint, r: 0.025);
    }
    if (c.spoiler >= 2) {
      for (final sx in [-1.0, 1.0]) {
        final px = sx * wingW;
        b.box(V3(px - 0.02, base + hgt - 0.08, z - 0.26), V3(px + 0.02, base + hgt + 0.27, z + 0.18), x.paint, Mat.paint,
            side: sx);
      }
    }
  }

  // ---- Tavan aksesuarları ----
  if (hasCabin && body <= 6) {
    final w = width((roofZ0 + roofZ1) / 2) * p.tumble;
    final z = (roofZ0 + roofZ1) / 2;
    switch (c.roof) {
      case 1:
        for (final sx in [-1.0, 1.0]) {
          b.box(V3(sx * w * 0.75 - 0.03, roofY - 0.02, roofZ0 + 0.05), V3(sx * w * 0.75 + 0.03, roofY + 0.07, roofZ1 - 0.05),
              0xFF37474F, Mat.chrome);
        }
        for (final t in [0.2, 0.5, 0.8]) {
          final zz2 = roofZ0 + (roofZ1 - roofZ0) * t;
          b.box(V3(-w * 0.8, roofY + 0.05, zz2 - 0.03), V3(w * 0.8, roofY + 0.09, zz2 + 0.03), 0xFF263238, Mat.trim);
        }
        break;
      case 2:
        b.box(V3(-0.5, roofY - 0.02, z - 0.12), V3(0.5, roofY + 0.05, z + 0.12), 0xFF202326, Mat.trim);
        b.softBox(V3(-0.48, roofY + 0.05, z - 0.1), V3(-0.02, roofY + 0.17, z + 0.1), 0xFFFF1744, Mat.light, r: 0.04);
        b.softBox(V3(0.02, roofY + 0.05, z - 0.1), V3(0.48, roofY + 0.17, z + 0.1), 0xFF2979FF, Mat.light, r: 0.04);
        break;
      case 3:
        final zb = roofZ1 - 0.12;
        b.box(V3(-w * 0.85, roofY - 0.02, zb - 0.08), V3(w * 0.85, roofY + 0.04, zb + 0.08), 0xFF202326, Mat.trim);
        for (var i = 0; i < 4; i++) {
          final px = -w * 0.66 + i * w * 0.44;
          b.softBox(V3(px - 0.12, roofY + 0.04, zb - 0.06), V3(px + 0.12, roofY + 0.15, zb + 0.08), 0xFFFFF59D, Mat.light, r: 0.04);
        }
        break;
      case 4:
        b.softBox(V3(-0.32, roofY - 0.02, z - 0.13), V3(0.32, roofY + 0.2, z + 0.13), 0xFFFFD600, Mat.light, r: 0.05);
        b.box(V3(-0.33, roofY + 0.06, z - 0.135), V3(0.33, roofY + 0.1, z + 0.135), 0xFF111111, Mat.trim);
        break;
    }
  }

  // ---- Tekerlekler ve çamurluklar ----
  for (final wz in p.wheelZ) {
    for (final sx in [-1.0, 1.0]) {
      final wx = sx * (width(wz) - 0.1);
      _wheel(b, V3(wx, x.tireR, wz), sx, x.tireR, x.tireW, c, x.lod);
      b.mesh.wheels.add(V3(wx, x.tireR, wz));
      if (p.flares) _flare(b, sx, width(wz), wz, x.tireR, x.paint, x.lod, belt(wz) - 0.05);
    }
  }

  // ---- Çıkartmalar ve kapı çizgileri ----
  final sideTop = belt(0) - 0.1;
  final sideBot = bottom(0) + 0.16;
  for (final sx in [-1.0, 1.0]) {
    final out = V3(sx, 0, 0);
    V3 map(double u, double v) => V3(sx * (width(u) + 0.006), v, u);
    if (hasCabin && body != 9 && body != 10) {
      final doors = <double>[wsBase - 0.08, ...p.pillars.map((q) => q - 0.02)];
      for (final z in doors) {
        b.decalPolygon([
          [z - 0.008, sideBot],
          [z + 0.008, sideBot],
          [z + 0.008, belt(z) - 0.04],
          [z - 0.008, belt(z) - 0.04],
        ], map, 0xFF1B1B1B, out, bodyPart);
      }
      for (final z in [wsBase - 0.2, ...p.pillars.map((q) => q - 0.16)]) {
        final v = belt(z) - 0.12;
        b.decalPolygon([
          [z - 0.12, v - 0.02],
          [z, v - 0.02],
          [z, v + 0.02],
          [z - 0.12, v + 0.02],
        ], map, _shade(x.paint, 0.6), out, bodyPart);
      }
    }
    _sideDecal(b, c, x.stripe, (sideTop + sideBot) / 2, sideTop - sideBot, map, out, bodyPart, body == 9 || body == 10 ? 1.6 : 0);
  }

  b.mesh.halfW = p.hw * 1.05;
  b.mesh.halfL = math.max(p.zF.abs(), p.zR.abs()) * 1.02;
}

void _sideDecal(MeshBuilder b, CarConfig c, int color, double sv, double sh, V3 Function(double, double) map, V3 out, int part,
    double zOff) {
  List<List<double>> tf(List<List<double>> pts, double su, double sv2) =>
      [for (final p in pts) [p[0] * su + zOff, sv + p[1] * sv2]];
  switch (c.sticker) {
    case 3:
      b.decalPolygon(
          tf(const [
            [1.1, 0.0], [0.6, 0.32], [0.45, 0.12], [0.1, 0.42], [0.0, 0.15], [-0.45, 0.38], [-0.35, 0.08],
            [-0.9, 0.2], [-0.55, -0.05], [-0.95, -0.3], [-0.3, -0.25], [0.2, -0.4], [0.35, -0.18], [0.8, -0.3],
          ], 0.7, sh * 0.9),
          map, color, out, part);
      break;
    case 4:
      b.decalPolygon(
          tf(const [
            [-0.9, 0.35], [0.05, 0.35], [-0.1, 0.05], [0.9, 0.12], [-0.2, -0.45], [0.0, -0.12], [-0.85, -0.12],
          ], 0.7, sh * 0.95),
          map, color, out, part);
      break;
    case 5:
      final pts = <List<double>>[];
      for (var i = 0; i < 16; i++) {
        final r = i.isEven ? 0.42 : 0.3;
        final a = i * math.pi / 8;
        pts.add([r * math.cos(a), r * math.sin(a)]);
      }
      b.decalPolygon(tf(pts, sh, sh), map, color, out, part);
      break;
    case 6:
      b.decalPolygon(
          tf(const [
            [0.0, -0.1], [-0.35, 0.05], [-0.42, 0.55], [-0.2, 0.35], [0.0, 0.7], [0.2, 0.35], [0.42, 0.55], [0.35, 0.05],
          ], sh * 0.45, sh * 0.45),
          map, color, out, part);
      b.decalPolygon(
          tf(const [
            [-0.025, -0.1], [0.025, -0.1], [0.025, -0.9], [-0.025, -0.9],
          ], sh * 0.45, sh * 0.45),
          map, 0xFF2E7D32, out, part);
      break;
  }
}

// ---------------- Formula ----------------

List<V3> _ellipseRing(double z, double hw, double y0, double y1, int n, {double pw = 0.6}) {
  final cy = (y0 + y1) / 2, ry = (y1 - y0) / 2;
  return [
    for (var i = 0; i < n; i++)
      () {
        final a = i / n * 2 * math.pi;
        final ca = math.cos(a), sa = math.sin(a);
        return V3(hw * ca.sign * math.pow(ca.abs(), pw).toDouble(), cy + ry * sa.sign * math.pow(sa.abs(), pw).toDouble(), z);
      }()
  ];
}

void _formula(_Ctx x) {
  final b = x.b, c = x.c, lift = x.lift;
  const trim = 0xFF202326;
  final secs = const [
    [-1.95, 0.32, 0.2, 0.58], [-1.4, 0.42, 0.18, 0.66], [-0.85, 0.4, 0.18, 0.74], [-0.25, 0.34, 0.18, 0.72],
    [0.5, 0.26, 0.18, 0.58], [1.3, 0.16, 0.18, 0.44], [2.0, 0.08, 0.2, 0.32], [2.15, 0.04, 0.22, 0.28],
  ];
  final n = x.lod ? 10 : 16;
  final rings = [for (final s in secs) _ellipseRing(s[0], s[1], s[2] + lift, s[3] + lift, n)];
  b.newPart();
  b.loft(rings, (sg, e) {
    final topEdge = e > n * 0.1 && e < n * 0.4;
    if (sg == 2 && topEdge) return (color: 0xFF111214, mat: Mat.trim); // kokpit
    if (c.sticker == 1 && (e == n ~/ 4 || e == n ~/ 4 - 1)) return (color: x.stripe, mat: Mat.paint);
    return (color: x.paint, mat: Mat.paint);
  }, closed: true, newPartFlag: false);
  b.cap(rings.first, x.paint, Mat.paint, const V3(0, 0, -1));
  b.cap(rings.last, x.paint, Mat.paint, const V3(0, 0, 1));
  // Kask
  b.sphere(V3(0, 0.82 + lift, -0.55), 0.17, x.stripe == 0xFF111111 ? 0xFFF5F5F5 : x.stripe, Mat.paint,
      lat: x.lod ? 6 : 8, lon: x.lod ? 10 : 14, bandColor: 0xFF1A2530);
  // Yan kutular
  final podParts = <double, int>{};
  for (final sx in [-1.0, 1.0]) {
    final x0 = sx > 0 ? 0.36 : -0.8, x1 = sx > 0 ? 0.8 : -0.36;
    b.softBox(V3(x0, 0.2 + lift, -1.35), V3(x1, 0.54 + lift, 0.15), x.paint, Mat.paint, r: 0.12, side: sx);
    podParts[sx] = b.currentPart;
  }
  // Ön ve arka kanat
  b.softBox(V3(-0.98, 0.1 + lift, 1.9), V3(0.98, 0.16 + lift, 2.28), x.paint, Mat.paint, r: 0.03);
  for (final sx in [-1.0, 1.0]) {
    b.box(V3(sx * 0.98 - 0.02, 0.08 + lift, 1.88), V3(sx * 0.98 + 0.02, 0.3 + lift, 2.3), trim, Mat.trim, side: sx);
  }
  b.softBox(V3(-0.72, 0.95 + lift, -2.15), V3(0.72, 1.03 + lift, -1.8), c.spoiler >= 2 ? x.stripe : trim, Mat.paint, r: 0.03);
  for (final sx in [-1.0, 1.0]) {
    b.box(V3(sx * 0.72 - 0.02, 0.6 + lift, -2.18), V3(sx * 0.72 + 0.02, 1.08 + lift, -1.76), x.paint, Mat.paint);
  }
  b.box(V3(-0.04, 0.55 + lift, -1.95), V3(0.04, 0.96 + lift, -1.85), trim, Mat.trim);
  b.softBox(V3(-0.1, 0.32 + lift, -2.02), V3(0.1, 0.42 + lift, -1.94), 0xFFE53935, Mat.tail, r: 0.03);
  // Açık tekerlekler
  for (final wz in [1.45, -1.5]) {
    for (final sx in [-1.0, 1.0]) {
      final w = wz > 0 ? 0.3 : 0.4;
      final wx = sx * 0.88;
      _wheel(b, V3(wx, 0.36, wz), sx, 0.36, w, c, x.lod);
      b.mesh.wheels.add(V3(wx, 0.36, wz));
    }
  }
  // Süspansiyon kolları
  for (final wz in [1.45, -1.5]) {
    for (final sx in [-1.0, 1.0]) {
      b.box(V3(sx > 0 ? 0.2 : -0.75, 0.34 + lift, wz - 0.03), V3(sx > 0 ? 0.75 : -0.2, 0.37 + lift, wz + 0.03), trim, Mat.trim,
          side: sx);
    }
  }
  for (final sx in [-1.0, 1.0]) {
    _sideDecal(b, c, x.stripe, 0.37 + lift, 0.26, (u, v) => V3(sx * 0.806, v, u), V3(sx, 0, 0), podParts[sx]!, -0.6);
  }
  b.mesh.halfW = 1.05;
  b.mesh.halfL = 2.3;
}

// ---------------- Çöl arabası ----------------

void _buggy(_Ctx x) {
  final b = x.b, c = x.c, lift = x.lift + 0.12;
  const tube = 0xFF263238;
  final secs = [
    [-1.5, 0.62, 0.44, 0.82], [-1.3, 0.72, 0.4, 0.9], [-0.9, 0.74, 0.38, 0.92], [0.5, 0.74, 0.38, 0.92],
    [1.2, 0.68, 0.42, 0.86], [1.55, 0.55, 0.48, 0.76], [1.7, 0.42, 0.52, 0.68],
  ];
  final n = x.lod ? 12 : 18;
  final rings = [for (final s in secs) _ellipseRing(s[0], s[1], s[2] + lift, s[3] + lift, n, pw: 0.35)];
  final bodyPart = b.newPart();
  b.loft(rings, (sg, e) {
    final topEdge = e > n * 0.08 && e < n * 0.42;
    if ((sg == 2) && topEdge) return (color: 0xFF1B1C1E, mat: Mat.trim);
    if (c.sticker == 1 && (e == n ~/ 4 || e == n ~/ 4 - 1)) return (color: x.stripe, mat: Mat.paint);
    return (color: x.paint, mat: Mat.paint);
  }, closed: true, newPartFlag: false);
  b.cap(rings.first, x.paint, Mat.paint, const V3(0, 0, -1));
  b.cap(rings.last, x.paint, Mat.paint, const V3(0, 0, 1));
  // Koltuklar
  for (final sx in [-1.0, 1.0]) {
    b.softBox(V3(sx * 0.33 - 0.2, 0.86 + lift, -0.75), V3(sx * 0.33 + 0.2, 1.28 + lift, -0.45), 0xFF3E2723, Mat.trim, r: 0.08);
  }
  // Takla kafesi
  final topY = 1.75 + lift;
  for (final zz in [-0.85, 0.3]) {
    for (final sx in [-1.0, 1.0]) {
      b.cylinder(V3(sx * 0.62, (0.9 + lift + topY) / 2, zz), 1, 0.04, topY - 0.9 - lift, 8, tube, Mat.chrome, side: sx);
    }
    b.cylinder(V3(0, topY, zz), 0, 0.04, 1.28, 8, tube, Mat.chrome);
  }
  for (final sx in [-1.0, 1.0]) {
    b.cylinder(V3(sx * 0.62, topY, -0.275), 2, 0.04, 1.15, 8, tube, Mat.chrome, side: sx);
  }
  // Farlar (kafes üstünde)
  for (final sx in [-1.0, 1.0]) {
    b.softBox(V3(sx * 0.25 - 0.1, topY + 0.02, 0.26), V3(sx * 0.25 + 0.1, topY + 0.16, 0.38), c.lightColor, Mat.light, r: 0.04);
    b.mesh.headlights.add(V3(sx * 0.25, topY, 0.4));
  }
  // Yedek lastik
  b.cylinder(V3(0, 0.75 + lift, -1.62), 2, 0.3, 0.2, x.lod ? 10 : 16, 0xFF1C1C1E, Mat.rubber, capColor: 0xFF9E9E9E, capMat: Mat.chrome);
  b.softBox(V3(-0.5, 0.5 + lift, -1.58), V3(0.5, 0.62 + lift, -1.5), 0xFFE53935, Mat.tail, r: 0.03);
  for (final wz in [1.15, -1.15]) {
    for (final sx in [-1.0, 1.0]) {
      final wx = sx * 0.96;
      _wheel(b, V3(wx, x.tireR, wz), sx, x.tireR, x.tireW, c, x.lod);
      b.mesh.wheels.add(V3(wx, x.tireR, wz));
    }
  }
  for (final sx in [-1.0, 1.0]) {
    _sideDecal(b, c, x.stripe, 0.66 + lift, 0.34, (u, v) => V3(sx * 0.748, v, u), V3(sx, 0, 0), bodyPart, -0.2);
  }
  b.mesh.halfW = 1.1;
  b.mesh.halfL = 1.8;
}

// ---------------- Tekerlek ve çamurluk ----------------

void _wheel(MeshBuilder b, V3 c, double side, double r, double w, CarConfig cfg, bool lod) {
  b.newPart(side: side);
  final segs = lod ? 12 : 20;
  const rubber = 0xFF1C1C1E;
  final rimC = rimColors[cfg.rimColor % rimColors.length];
  final xo = c.x + side * w / 2;
  final xi = c.x - side * w / 2;
  final outer = <V3>[], inner = <V3>[], outerSoft = <V3>[], innerSoft = <V3>[];
  for (var i = 0; i < segs; i++) {
    final t = i / segs * 2 * math.pi;
    final y = c.y + r * math.sin(t), z = c.z + r * math.cos(t);
    final y2 = c.y + r * 0.9 * math.sin(t), z2 = c.z + r * 0.9 * math.cos(t);
    outer.add(V3(xo - side * 0.035, y, z));
    inner.add(V3(xi + side * 0.035, y, z));
    outerSoft.add(V3(xo, y2, z2));
    innerSoft.add(V3(xi, y2, z2));
  }
  b.loft([innerSoft, inner, outer, outerSoft], (s, e) => (color: rubber, mat: Mat.rubber), closed: true, newPartFlag: false);
  b.cap(innerSoft, rubber, Mat.rubber, V3(-side, 0, 0));
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
  final lip = rr * 0.86, hub = rr * 0.26;
  final xr = xo - side * 0.02;
  V3 pt(double rad, double t, double x) => V3(x, c.y + rad * math.sin(t), c.z + rad * math.cos(t));
  final n = lod ? 12 : 24;
  for (var i = 0; i < n; i++) {
    final t0 = i / n * 2 * math.pi, t1 = (i + 1) / n * 2 * math.pi;
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
    b.tri(pt(hub, t0, xr + side * 0.01), pt(hub, t1, xr + side * 0.01), V3(xr + side * 0.03, c.y, c.z),
        cfg.rim == 4 ? 0xFF263238 : rimC, Mat.chrome,
        outward: out);
  }
}

void _flare(MeshBuilder b, double side, double hw, double wz, double r, int paint, bool lod, double maxY) {
  b.newPart(side: side);
  final n = lod ? 6 : 10;
  final ri = r + 0.05, ro = r + 0.13;
  final xi = side * (hw - 0.04), xo = side * (hw + 0.07);
  final cy = r;
  final k = math.min(1.0, math.max(0.35, (maxY - cy) / ro));
  V3 p(double rad, double a, double x) => V3(x, cy + rad * k * math.sin(a), wz + rad * math.cos(a));
  final out = V3(side, 0, 0);
  for (var i = 0; i < n; i++) {
    final a0 = 0.12 + (math.pi - 0.24) * i / n, a1 = 0.12 + (math.pi - 0.24) * (i + 1) / n;
    b.quad(p(ri, a0, xo), p(ro, a0, xo), p(ro, a1, xo), p(ri, a1, xo), paint, Mat.paint, outward: out);
    final mid = (a0 + a1) / 2;
    final radial = V3(0, math.sin(mid), math.cos(mid));
    b.quad(p(ro, a0, xi), p(ro, a0, xo), p(ro, a1, xo), p(ro, a1, xi), paint, Mat.paint, outward: radial);
    b.quad(p(ri, a0, xi), p(ri, a0, xo), p(ri, a1, xo), p(ri, a1, xi), 0xFF111214, Mat.trim, outward: -radial);
  }
}
