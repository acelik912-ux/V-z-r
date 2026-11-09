import 'dart:math' as math;

import 'vec.dart';

/// Yüzey malzemeleri. Işıklandırma malzemeye göre değişir.
enum Mat { paint, glass, rubber, chrome, light, trim, decal, tail }

class Tri {
  final V3 a;
  final V3 b;
  final V3 c;
  final V3 na;
  final V3 nb;
  final V3 nc;
  final int color;
  final Mat mat;
  Tri(this.a, this.b, this.c, this.na, this.nb, this.nc, this.color, this.mat);
}

class Mesh {
  final List<Tri> tris = [];
  final List<Tri> decals = [];

  /// Zemindeki gölge/neon için yarım genişlik ve yarım uzunluk.
  double halfW = 1.0;
  double halfL = 2.2;

  /// Farların konumları (ışık hüzmesi için).
  final List<V3> headlights = [];
}

class MeshBuilder {
  final Mesh mesh = Mesh();

  /// Üçgen ekler. [inside] verilirse yüzey o noktadan dışarı bakacak şekilde,
  /// [outward] verilirse o yöne bakacak şekilde çevrilir.
  void tri(V3 a, V3 b, V3 c, int color, Mat mat,
      {V3? inside, V3? outward, V3? na, V3? nb, V3? nc, bool decal = false}) {
    var n = (b - a).cross(c - a);
    if (n.length < 1e-9) return;
    final cen = (a + b + c) * (1 / 3);
    var flip = false;
    if (outward != null) {
      flip = n.dot(outward) < 0;
    } else if (inside != null) {
      flip = n.dot(cen - inside) < 0;
    }
    var bb = b;
    var cc = c;
    var nbb = nb;
    var ncc = nc;
    if (flip) {
      bb = c;
      cc = b;
      nbb = nc;
      ncc = nb;
      n = -n;
    }
    final fn = n.norm;
    final t = Tri(a, bb, cc, na ?? fn, nbb ?? fn, ncc ?? fn, color, mat);
    if (decal) {
      mesh.decals.add(t);
    } else {
      mesh.tris.add(t);
    }
  }

  void quad(V3 a, V3 b, V3 c, V3 d, int color, Mat mat,
      {V3? inside, V3? outward, List<V3>? normals, bool decal = false}) {
    tri(a, b, c, color, mat,
        inside: inside, outward: outward, na: normals?[0], nb: normals?[1], nc: normals?[2], decal: decal);
    tri(a, c, d, color, mat,
        inside: inside, outward: outward, na: normals?[0], nb: normals?[2], nc: normals?[3], decal: decal);
  }

  /// Eksenlere hizalı kutu.
  void box(V3 lo, V3 hi, int color, Mat mat) {
    final ctr = (lo + hi) * 0.5;
    final x0 = lo.x, y0 = lo.y, z0 = lo.z, x1 = hi.x, y1 = hi.y, z1 = hi.z;
    quad(V3(x0, y0, z0), V3(x0, y1, z0), V3(x0, y1, z1), V3(x0, y0, z1), color, mat, inside: ctr);
    quad(V3(x1, y0, z0), V3(x1, y1, z0), V3(x1, y1, z1), V3(x1, y0, z1), color, mat, inside: ctr);
    quad(V3(x0, y0, z0), V3(x1, y0, z0), V3(x1, y0, z1), V3(x0, y0, z1), color, mat, inside: ctr);
    quad(V3(x0, y1, z0), V3(x1, y1, z0), V3(x1, y1, z1), V3(x0, y1, z1), color, mat, inside: ctr);
    quad(V3(x0, y0, z0), V3(x1, y0, z0), V3(x1, y1, z0), V3(x0, y1, z0), color, mat, inside: ctr);
    quad(V3(x0, y0, z1), V3(x1, y0, z1), V3(x1, y1, z1), V3(x0, y1, z1), color, mat, inside: ctr);
  }

  /// Kesitlerden yüzey örer. rings[s][i] = s. kesitin i. noktası.
  /// [face] her (kesit aralığı, kenar) için renk ve malzeme döndürür; null dönerse yüz atlanır.
  /// [closed] ise son nokta ilk noktaya bağlanır.
  void loft(
    List<List<V3>> rings,
    ({int color, Mat mat})? Function(int seg, int edge) face, {
    bool closed = false,
    bool smooth = true,
  }) {
    final m = rings.first.length;
    final segs = rings.length - 1;
    final edges = closed ? m : m - 1;
    // Her yüzün dışa dönük normali
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
        var n = (b - a).cross(d - a) + (c - b).cross(a - b);
        if (n.length < 1e-9) n = (c - a).cross(d - b);
        if (n.length < 1e-9) continue;
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

  /// Dışbükey çokgeni merkezden yelpaze ile kapatır.
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

  /// Eksen boyunca silindir (egzoz vb.). axis: 0 = x, 2 = z.
  void cylinder(V3 center, int axis, double r, double len, int segs, int color, Mat mat,
      {int? capColor, Mat? capMat}) {
    final pts0 = <V3>[], pts1 = <V3>[];
    for (var i = 0; i < segs; i++) {
      final t = i / segs * 6.283185307179586;
      final u = r * math.cos(t), v = r * math.sin(t);
      if (axis == 0) {
        pts0.add(V3(center.x - len / 2, center.y + v, center.z + u));
        pts1.add(V3(center.x + len / 2, center.y + v, center.z + u));
      } else {
        pts0.add(V3(center.x + u, center.y + v, center.z - len / 2));
        pts1.add(V3(center.x + u, center.y + v, center.z + len / 2));
      }
    }
    loft([pts0, pts1], (s, e) => (color: color, mat: mat), closed: true);
    final dir = axis == 0 ? const V3(1, 0, 0) : const V3(0, 0, 1);
    cap(pts1, capColor ?? color, capMat ?? mat, dir);
    cap(pts0, capColor ?? color, capMat ?? mat, -dir);
  }

  /// Düz (yan yüzeyde) bir çıkartma çokgeni. pts2: (u, v) noktaları,
  /// map: (u, v) -> 3D nokta.
  void decalPolygon(List<List<double>> pts2, V3 Function(double u, double v) map, int color, V3 outward) {
    final xs = [for (final p in pts2) p[0]];
    final ys = [for (final p in pts2) p[1]];
    for (final t in earclip(xs, ys)) {
      tri(map(xs[t[0]], ys[t[0]]), map(xs[t[1]], ys[t[1]]), map(xs[t[2]], ys[t[2]]), color, Mat.decal,
          outward: outward, decal: true);
    }
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
