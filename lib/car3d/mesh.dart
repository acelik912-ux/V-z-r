import 'dart:math' as math;
import 'dart:typed_data';

import 'vec.dart';

/// Yüzey malzemeleri. Işıklandırma malzemeye göre değişir.
enum Mat { paint, glass, rubber, chrome, light, trim, decal, tail }

class _Tri {
  final V3 a, b, c, na, nb, nc;
  final int color;
  final Mat mat;
  final int part;
  final bool decal;
  _Tri(this.a, this.b, this.c, this.na, this.nb, this.nc, this.color, this.mat, this.part, this.decal);
}

/// Paketlenmiş üçgen ağı. Her üçgen bir "parça"ya aittir; parçalar kendi aralarında
/// derinliğe göre sıralanır, böylece dönerken parçalar birbirinin önüne atlamaz.
class Mesh {
  late final Float32List pos; // üçgen başına 9
  late final Float32List nrm; // üçgen başına 9
  late final Int32List col;
  late final Uint8List mat;
  late final Int32List part;
  late final Uint8List decal;
  late final Float32List partC; // parça başına 3 (merkez)
  late final Int8List partSide; // -1 sol, 1 sağ, 0 orta (yan parçalar gövdeye göre önde/arkada çizilir)
  int get count => col.length;
  int get parts => partC.length ~/ 3;

  double halfW = 1.0;
  double halfL = 2.2;
  final List<V3> headlights = [];
  final List<V3> wheels = []; // temas gölgesi için (x, yarıçap, z)
}

class MeshBuilder {
  final List<_Tri> _tris = [];
  final Mesh mesh = Mesh();
  int _part = 0;
  int _maxPart = 0;
  final Map<int, int> _sides = {};

  /// Yeni bir parça başlatır ve numarasını döndürür. [side]: -1 sol, 1 sağ yan parça.
  int newPart({double side = 0}) {
    _part = ++_maxPart;
    if (side != 0) _sides[_part] = side > 0 ? 1 : -1;
    return _part;
  }

  int get currentPart => _part;
  set currentPart(int p) => _part = p;

  void tri(V3 a, V3 b, V3 c, int color, Mat mat,
      {V3? inside, V3? outward, V3? na, V3? nb, V3? nc, bool decal = false, int? part}) {
    var n = (b - a).cross(c - a);
    if (n.length < 1e-10) return;
    final cen = (a + b + c) * (1 / 3);
    var flip = false;
    if (outward != null) {
      flip = n.dot(outward) < 0;
    } else if (inside != null) {
      flip = n.dot(cen - inside) < 0;
    }
    var bb = b, cc = c, nbb = nb, ncc = nc;
    if (flip) {
      bb = c;
      cc = b;
      nbb = nc;
      ncc = nb;
      n = -n;
    }
    final fn = n.norm;
    _tris.add(_Tri(a, bb, cc, na ?? fn, nbb ?? fn, ncc ?? fn, color, mat, part ?? _part, decal));
  }

  void quad(V3 a, V3 b, V3 c, V3 d, int color, Mat mat,
      {V3? inside, V3? outward, List<V3>? normals, bool decal = false, int? part}) {
    tri(a, b, c, color, mat,
        inside: inside, outward: outward, na: normals?[0], nb: normals?[1], nc: normals?[2], decal: decal, part: part);
    tri(a, c, d, color, mat,
        inside: inside, outward: outward, na: normals?[0], nb: normals?[2], nc: normals?[3], decal: decal, part: part);
  }

  void box(V3 lo, V3 hi, int color, Mat mat, {bool ownPart = true, double side = 0}) {
    if (ownPart) newPart(side: side);
    final ctr = (lo + hi) * 0.5;
    final x0 = lo.x, y0 = lo.y, z0 = lo.z, x1 = hi.x, y1 = hi.y, z1 = hi.z;
    quad(V3(x0, y0, z0), V3(x0, y1, z0), V3(x0, y1, z1), V3(x0, y0, z1), color, mat, inside: ctr);
    quad(V3(x1, y0, z0), V3(x1, y1, z0), V3(x1, y1, z1), V3(x1, y0, z1), color, mat, inside: ctr);
    quad(V3(x0, y0, z0), V3(x1, y0, z0), V3(x1, y0, z1), V3(x0, y0, z1), color, mat, inside: ctr);
    quad(V3(x0, y1, z0), V3(x1, y1, z0), V3(x1, y1, z1), V3(x0, y1, z1), color, mat, inside: ctr);
    quad(V3(x0, y0, z0), V3(x1, y0, z0), V3(x1, y1, z0), V3(x0, y1, z0), color, mat, inside: ctr);
    quad(V3(x0, y0, z1), V3(x1, y0, z1), V3(x1, y1, z1), V3(x0, y1, z1), color, mat, inside: ctr);
  }

  /// Yuvarlak köşeli kutu (çizgi film görünümü için).
  void softBox(V3 lo, V3 hi, int color, Mat mat, {double r = 0.06, int segs = 3, double side = 0}) {
    newPart(side: side);
    final rr = math.min(r, math.min((hi.x - lo.x), math.min(hi.y - lo.y, hi.z - lo.z)) * 0.45);
    final rings = <List<V3>>[];
    final zs = <double>[lo.z, lo.z + rr * 0.3, lo.z + rr, hi.z - rr, hi.z - rr * 0.3, hi.z];
    final ins = <double>[rr * 0.7, rr * 0.15, 0, 0, rr * 0.15, rr * 0.7];
    for (var k = 0; k < zs.length; k++) {
      final inset = ins[k];
      final x0 = lo.x + inset, x1 = hi.x - inset, y0 = lo.y + inset, y1 = hi.y - inset;
      final ring = <V3>[];
      final cr = math.max(0.001, rr - inset * 0.5);
      void corner(double cx, double cy, double a0) {
        for (var i = 0; i <= segs; i++) {
          final a = a0 + i / segs * math.pi / 2;
          ring.add(V3(cx + cr * math.cos(a), cy + cr * math.sin(a), zs[k]));
        }
      }

      corner(x1 - cr, y1 - cr, 0);
      corner(x0 + cr, y1 - cr, math.pi / 2);
      corner(x0 + cr, y0 + cr, math.pi);
      corner(x1 - cr, y0 + cr, math.pi * 1.5);
      rings.add(ring);
    }
    loft(rings, (s, e) => (color: color, mat: mat), closed: true, newPartFlag: false);
    cap(rings.first, color, mat, const V3(0, 0, -1));
    cap(rings.last, color, mat, const V3(0, 0, 1));
  }

  void loft(
    List<List<V3>> rings,
    ({int color, Mat mat})? Function(int seg, int edge) face, {
    bool closed = false,
    bool smooth = true,
    bool newPartFlag = true,
  }) {
    if (newPartFlag) newPart();
    final m = rings.first.length;
    final segs = rings.length - 1;
    final edges = closed ? m : m - 1;
    final faceN = List.generate(segs, (_) => List<V3?>.filled(edges, null));
    final insides = <V3>[];
    for (var s = 0; s < segs; s++) {
      var sum = const V3(0, 0, 0);
      for (final p in rings[s]) {
        sum = sum + p;
      }
      for (final p in rings[s + 1]) {
        sum = sum + p;
      }
      insides.add(sum * (1 / (2 * m)));
    }
    for (var s = 0; s < segs; s++) {
      for (var e = 0; e < edges; e++) {
        final a = rings[s][e], b = rings[s][(e + 1) % m], c = rings[s + 1][(e + 1) % m], d = rings[s + 1][e];
        var n = (b - a).cross(d - a) + (c - b).cross(a - b) + (d - c).cross(b - c) + (a - d).cross(c - d);
        if (n.length < 1e-10) continue;
        final cen = (a + b + c + d) * 0.25;
        if (n.dot(cen - insides[s]) < 0) n = -n;
        faceN[s][e] = n.norm;
      }
    }
    V3 vn(int s, int i) {
      var sum = const V3(0, 0, 0);
      for (final ss in [s - 1, s]) {
        if (ss < 0 || ss >= segs) continue;
        for (final ee in [i - 1, i]) {
          var e = ee;
          if (e < 0) {
            if (!closed) continue;
            e = edges - 1;
          }
          if (e >= edges) continue;
          final n = faceN[ss][e];
          if (n != null) sum = sum + n;
        }
      }
      return sum.norm;
    }

    for (var s = 0; s < segs; s++) {
      for (var e = 0; e < edges; e++) {
        final f = face(s, e);
        if (f == null || faceN[s][e] == null) continue;
        final i1 = (e + 1) % m;
        final a = rings[s][e], b = rings[s][i1], c = rings[s + 1][i1], d = rings[s + 1][e];
        quad(a, b, c, d, f.color, f.mat,
            inside: insides[s], normals: smooth ? [vn(s, e), vn(s, i1), vn(s + 1, i1), vn(s + 1, e)] : null);
      }
    }
  }

  void cap(List<V3> ring, int color, Mat mat, V3 outward) {
    var sum = const V3(0, 0, 0);
    for (final p in ring) {
      sum = sum + p;
    }
    final c = sum * (1 / ring.length);
    for (var i = 0; i < ring.length; i++) {
      tri(c, ring[i], ring[(i + 1) % ring.length], color, mat, outward: outward);
    }
  }

  void cylinder(V3 center, int axis, double r, double len, int segs, int color, Mat mat,
      {int? capColor, Mat? capMat, double side = 0}) {
    newPart(side: side);
    final pts0 = <V3>[], pts1 = <V3>[];
    for (var i = 0; i < segs; i++) {
      final t = i / segs * 2 * math.pi;
      final u = r * math.cos(t), v = r * math.sin(t);
      if (axis == 0) {
        pts0.add(V3(center.x - len / 2, center.y + v, center.z + u));
        pts1.add(V3(center.x + len / 2, center.y + v, center.z + u));
      } else if (axis == 1) {
        pts0.add(V3(center.x + u, center.y - len / 2, center.z + v));
        pts1.add(V3(center.x + u, center.y + len / 2, center.z + v));
      } else {
        pts0.add(V3(center.x + u, center.y + v, center.z - len / 2));
        pts1.add(V3(center.x + u, center.y + v, center.z + len / 2));
      }
    }
    loft([pts0, pts1], (s, e) => (color: color, mat: mat), closed: true, newPartFlag: false);
    final dir = axis == 0 ? const V3(1, 0, 0) : (axis == 1 ? const V3(0, 1, 0) : const V3(0, 0, 1));
    cap(pts1, capColor ?? color, capMat ?? mat, dir);
    cap(pts0, capColor ?? color, capMat ?? mat, -dir);
  }

  /// Küre (kask vb.). [bandColor] verilirse ön yüzde koyu bir vizör bandı olur.
  void sphere(V3 c, double r, int color, Mat mat, {int lat = 8, int lon = 14, int? bandColor}) {
    newPart();
    final rings = <List<V3>>[];
    for (var i = 1; i < lat; i++) {
      final phi = -math.pi / 2 + math.pi * i / lat;
      final ring = <V3>[];
      for (var j = 0; j < lon; j++) {
        final th = 2 * math.pi * j / lon;
        ring.add(V3(c.x + r * math.cos(phi) * math.sin(th), c.y + r * math.sin(phi), c.z + r * math.cos(phi) * math.cos(th)));
      }
      rings.add(ring);
    }
    loft(rings, (s, e) {
      if (bandColor != null && s == lat ~/ 2 - 1 && (e <= 2 || e >= lon - 3)) return (color: bandColor, mat: Mat.glass);
      return (color: color, mat: mat);
    }, closed: true, newPartFlag: false);
    // kutuplar
    final top = V3(c.x, c.y + r, c.z), bot = V3(c.x, c.y - r, c.z);
    for (var j = 0; j < lon; j++) {
      final a = rings.last[j], b = rings.last[(j + 1) % lon];
      tri(a, b, top, color, mat, inside: c, na: (a - c).norm, nb: (b - c).norm, nc: const V3(0, 1, 0));
      final d = rings.first[j], e = rings.first[(j + 1) % lon];
      tri(d, e, bot, color, mat, inside: c, na: (d - c).norm, nb: (e - c).norm, nc: const V3(0, -1, 0));
    }
  }

  void decalPolygon(List<List<double>> pts2, V3 Function(double u, double v) map, int color, V3 outward, int part) {
    final xs = [for (final p in pts2) p[0]];
    final ys = [for (final p in pts2) p[1]];
    for (final t in earclip(xs, ys)) {
      tri(map(xs[t[0]], ys[t[0]]), map(xs[t[1]], ys[t[1]]), map(xs[t[2]], ys[t[2]]), color, Mat.decal,
          outward: outward, decal: true, part: part);
    }
  }

  /// Ağı paketler ve döndürür.
  Mesh build() {
    final n = _tris.length;
    final m = mesh;
    m.pos = Float32List(n * 9);
    m.nrm = Float32List(n * 9);
    m.col = Int32List(n);
    m.mat = Uint8List(n);
    m.part = Int32List(n);
    m.decal = Uint8List(n);
    final parts = _maxPart + 1;
    final sum = Float64List(parts * 3);
    final cnt = Int32List(parts);
    for (var i = 0; i < n; i++) {
      final t = _tris[i];
      final o = i * 9;
      final vs = [t.a, t.b, t.c];
      final ns = [t.na, t.nb, t.nc];
      for (var k = 0; k < 3; k++) {
        m.pos[o + k * 3] = vs[k].x;
        m.pos[o + k * 3 + 1] = vs[k].y;
        m.pos[o + k * 3 + 2] = vs[k].z;
        m.nrm[o + k * 3] = ns[k].x;
        m.nrm[o + k * 3 + 1] = ns[k].y;
        m.nrm[o + k * 3 + 2] = ns[k].z;
      }
      m.col[i] = t.color;
      m.mat[i] = t.mat.index;
      m.part[i] = t.part;
      m.decal[i] = t.decal ? 1 : 0;
      if (!t.decal) {
        final c = (t.a + t.b + t.c) * (1 / 3);
        sum[t.part * 3] += c.x;
        sum[t.part * 3 + 1] += c.y;
        sum[t.part * 3 + 2] += c.z;
        cnt[t.part]++;
      }
    }
    m.partSide = Int8List(parts);
    _sides.forEach((k, v) => m.partSide[k] = v);
    m.partC = Float32List(parts * 3);
    for (var p = 0; p < parts; p++) {
      final k = cnt[p] == 0 ? 1 : cnt[p];
      m.partC[p * 3] = sum[p * 3] / k;
      m.partC[p * 3 + 1] = sum[p * 3 + 1] / k;
      m.partC[p * 3 + 2] = sum[p * 3 + 2] / k;
    }
    return m;
  }
}

/// Kulak kırpma ile çokgen üçgenleme.
List<List<int>> earclip(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 3) return [];
  var area = 0.0;
  for (var i = 0; i < n; i++) {
    final j = (i + 1) % n;
    area += xs[i] * ys[j] - xs[j] * ys[i];
  }
  var idx = List<int>.generate(n, (i) => i);
  if (area < 0) idx = idx.reversed.toList();
  final res = <List<int>>[];
  var guard = 0;
  while (idx.length > 3 && guard < 1000) {
    guard++;
    var found = false;
    for (var k = 0; k < idx.length; k++) {
      final i0 = idx[(k - 1 + idx.length) % idx.length];
      final i1 = idx[k];
      final i2 = idx[(k + 1) % idx.length];
      final cr = (xs[i1] - xs[i0]) * (ys[i2] - ys[i0]) - (ys[i1] - ys[i0]) * (xs[i2] - xs[i0]);
      if (cr <= 1e-12) continue;
      var inside = false;
      for (final j in idx) {
        if (j == i0 || j == i1 || j == i2) continue;
        if (_inTri(xs[j], ys[j], xs[i0], ys[i0], xs[i1], ys[i1], xs[i2], ys[i2])) {
          inside = true;
          break;
        }
      }
      if (inside) continue;
      res.add([i0, i1, i2]);
      idx.removeAt(k);
      found = true;
      break;
    }
    if (!found) break;
  }
  if (idx.length == 3) res.add([idx[0], idx[1], idx[2]]);
  return res;
}

bool _inTri(double px, double py, double ax, double ay, double bx, double by, double cx, double cy) {
  double s(double x1, double y1, double x2, double y2, double x3, double y3) =>
      (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3);
  final d1 = s(px, py, ax, ay, bx, by);
  final d2 = s(px, py, bx, by, cx, cy);
  final d3 = s(px, py, cx, cy, ax, ay);
  final neg = d1 < 0 || d2 < 0 || d3 < 0;
  final pos = d1 > 0 || d2 > 0 || d3 > 0;
  return !(neg && pos);
}
