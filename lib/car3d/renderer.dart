import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'car_model.dart';
import 'mesh.dart';
import 'vec.dart';

/// Basit perspektif kamera. yaw: araba etrafında dönüş, pitch: yukarıdan bakış açısı.
class Camera {
  final Offset center; // zemindeki araba merkezinin ekrandaki yeri
  final double scale; // 1 birim = kaç piksel
  final double yaw;
  final double pitch;
  static const double dist = 12;
  final double _cy, _sy, _cp, _sp;

  Camera({required this.center, required this.scale, required this.yaw, required this.pitch})
      : _cy = math.cos(yaw),
        _sy = math.sin(yaw),
        _cp = math.cos(pitch),
        _sp = math.sin(pitch);

  V3 view(V3 p) {
    final x1 = p.x * _cy + p.z * _sy;
    final z1 = -p.x * _sy + p.z * _cy;
    return V3(x1, p.y * _cp - z1 * _sp, p.y * _sp + z1 * _cp);
  }

  Offset proj(V3 v) {
    var d = dist - v.z;
    if (d < 0.5) d = 0.5;
    final s = scale * dist / d;
    return Offset(center.dx + v.x * s, center.dy - v.y * s);
  }

  Offset project(V3 p) => proj(view(p));
}

// Işık (kamera uzayında): sol üst önden
final V3 _light = const V3(-0.45, 0.78, 0.5).norm;
final V3 _half = (_light + const V3(0, 0, 1)).norm;

int _clamp255(double v) => v < 0 ? 0 : (v > 255 ? 255 : v.round());

int _shadeVertex(int base, Mat mat, V3 n, int finish, bool lightsOn) {
  final r = ((base >> 16) & 255).toDouble();
  final g = ((base >> 8) & 255).toDouble();
  final b = (base & 255).toDouble();
  final diff = math.max(0.0, n.dot(_light));
  final nh = math.max(0.0, n.dot(_half));
  final facing = math.max(0.0, n.z);
  final sky = n.y * 0.5 + 0.5; // yukarı bakan yüzeyler gökyüzünü yansıtır
  double k = 0.5, spec = 0, env = 0;
  switch (mat) {
    case Mat.paint:
    case Mat.decal:
      if (finish == 2) {
        k = 0.42 + 0.62 * diff;
        spec = math.pow(nh, 8).toDouble() * 0.06;
        env = 0;
      } else if (finish == 1) {
        k = 0.3 + 0.85 * diff;
        spec = math.pow(nh, 18).toDouble() * 0.75;
        env = math.pow(1 - facing, 2).toDouble() * 0.25 * sky;
      } else {
        k = 0.4 + 0.62 * diff;
        spec = math.pow(nh, 60).toDouble() * 0.9 + math.pow(nh, 12).toDouble() * 0.12;
        env = math.pow(1 - facing, 3).toDouble() * 0.35 * sky;
      }
      break;
    case Mat.glass:
      k = 0.55 + 0.25 * diff;
      spec = math.pow(nh, 50).toDouble() * 0.95;
      env = 0.12 + 0.3 * sky;
      break;
    case Mat.rubber:
      k = 0.55 + 0.5 * diff;
      spec = math.pow(nh, 6).toDouble() * 0.05;
      env = 0;
      break;
    case Mat.chrome:
      k = 0.45 + 0.55 * diff;
      spec = math.pow(nh, 30).toDouble() * 0.9;
      env = 0.25 * sky;
      break;
    case Mat.light:
      final glow = lightsOn ? 1.35 : 0.95;
      return 0xFF000000 |
          (_clamp255(r * glow + (lightsOn ? 40 : 0)) << 16) |
          (_clamp255(g * glow + (lightsOn ? 40 : 0)) << 8) |
          _clamp255(b * glow + (lightsOn ? 40 : 0));
    case Mat.tail:
      final glow = lightsOn ? 1.3 : 0.8;
      return 0xFF000000 | (_clamp255(r * glow + 20) << 16) | (_clamp255(g * glow) << 8) | _clamp255(b * glow);
    case Mat.trim:
      k = 0.6 + 0.5 * diff;
      spec = math.pow(nh, 10).toDouble() * 0.12;
      env = 0;
      break;
  }
  final add = (spec + env) * 255;
  return 0xFF000000 |
      (_clamp255(r * k + add) << 16) |
      (_clamp255(g * k + add) << 8) |
      _clamp255(b * k + add * 1.05);
}

class _Proj {
  final double depth;
  final Offset a, b, c;
  final int ca, cb, cc;
  _Proj(this.depth, this.a, this.b, this.c, this.ca, this.cb, this.cc);
}

List<_Proj> _projectTris(List<Tri> tris, Camera cam, int finish, bool lightsOn, bool mirror, double bob) {
  final out = <_Proj>[];
  const camPos = V3(0, 0, Camera.dist);
  V3 tp(V3 p) => cam.view(V3(p.x, mirror ? -p.y - bob : p.y + bob, p.z));
  V3 tn(V3 n) => cam.view(mirror ? V3(n.x, -n.y, n.z) : n);
  for (final t in tris) {
    final a = tp(t.a), b = tp(t.b), c = tp(t.c);
    var n = (b - a).cross(c - a);
    if (mirror) n = -n;
    if (n.dot(camPos - a) <= 0) continue;
    final depth = (a.z + b.z + c.z) / 3;
    out.add(_Proj(
      depth,
      cam.proj(a),
      cam.proj(b),
      cam.proj(c),
      _shadeVertex(t.color, t.mat, tn(t.na), finish, lightsOn),
      _shadeVertex(t.color, t.mat, tn(t.nb), finish, lightsOn),
      _shadeVertex(t.color, t.mat, tn(t.nc), finish, lightsOn),
    ));
  }
  out.sort((p, q) => p.depth.compareTo(q.depth));
  return out;
}

void _draw(Canvas canvas, List<_Proj> list) {
  if (list.isEmpty) return;
  final pos = Float32List(list.length * 6);
  final col = Int32List(list.length * 3);
  var i = 0, j = 0;
  for (final p in list) {
    pos[i++] = p.a.dx;
    pos[i++] = p.a.dy;
    pos[i++] = p.b.dx;
    pos[i++] = p.b.dy;
    pos[i++] = p.c.dx;
    pos[i++] = p.c.dy;
    col[j++] = p.ca;
    col[j++] = p.cb;
    col[j++] = p.cc;
  }
  final v = ui.Vertices.raw(ui.VertexMode.triangles, pos, colors: col);
  canvas.drawVertices(v, BlendMode.modulate, Paint()..color = Colors.white);
}

Path _footprint(Camera cam, Mesh mesh, double grow) {
  final w = mesh.halfW * grow, l = mesh.halfL * grow;
  final pts = <Offset>[];
  for (var i = 0; i < 24; i++) {
    final a = i / 24 * 2 * math.pi;
    // Yuvarlatılmış dikdörtgen benzeri (süperelips)
    final ca = math.cos(a), sa = math.sin(a);
    final x = w * ca.sign * math.pow(ca.abs(), 0.5);
    final z = l * sa.sign * math.pow(sa.abs(), 0.5);
    pts.add(cam.project(V3(x.toDouble(), 0, z.toDouble())));
  }
  return Path()..addPolygon(pts, true);
}

/// Arabayı çizer. Zemindeki gölge, neon ve far ışığı da dahil.
void paintCar(
  Canvas canvas,
  CarConfig cfg,
  Camera cam, {
  bool lightsOn = false,
  bool reflection = false,
  bool shadow = true,
  double bob = 0,
  bool lod = false,
  double opacity = 1,
}) {
  final mesh = carMesh(cfg, lod: lod);
  if (opacity < 1) {
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
  }

  // Neon ışığı (zeminde renkli parıltı)
  if (cfg.neonColor != 0) {
    final c = Color(cfg.neonColor);
    canvas.drawPath(
      _footprint(cam, mesh, 1.25),
      Paint()
        ..color = c.withAlpha(150)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cam.scale * 0.35),
    );
  }
  // Gölge
  if (shadow) {
    canvas.drawPath(
      _footprint(cam, mesh, 1.0),
      Paint()
        ..color = Colors.black.withAlpha(cfg.neonColor != 0 ? 90 : 130)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cam.scale * 0.12),
    );
  }
  // Far hüzmeleri
  if (lightsOn) {
    for (final h in mesh.headlights) {
      final a = cam.project(V3(h.x - 0.15, 0.02, h.z));
      final b = cam.project(V3(h.x + 0.15, 0.02, h.z));
      final c = cam.project(V3(h.x * 2.2 + 0.9, 0.02, h.z + 4.0));
      final d = cam.project(V3(h.x * 2.2 - 0.9, 0.02, h.z + 4.0));
      canvas.drawPath(
        Path()..addPolygon([a, b, c, d], true),
        Paint()
          ..color = Color(cfg.lightColor).withAlpha(70)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cam.scale * 0.2),
      );
    }
  }

  if (reflection) {
    canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.22));
    _draw(canvas, _projectTris(mesh.tris, cam, cfg.finish, lightsOn, true, bob));
    canvas.restore();
  }

  _draw(canvas, _projectTris(mesh.tris, cam, cfg.finish, lightsOn, false, bob));
  _draw(canvas, _projectTris(mesh.decals, cam, cfg.finish, lightsOn, false, bob));

  if (opacity < 1) canvas.restore();
}
