import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'car_model.dart';
import 'mesh.dart';
import 'vec.dart';

/// Basit perspektif kamera. yaw: araba etrafında dönüş, pitch: yukarıdan bakış açısı.
class Camera {
  final Offset center;
  final double scale;
  final double yaw;
  final double pitch;
  static const double dist = 12;
  final double cy, sy, cp, sp;

  Camera({required this.center, required this.scale, required this.yaw, required this.pitch})
      : cy = math.cos(yaw),
        sy = math.sin(yaw),
        cp = math.cos(pitch),
        sp = math.sin(pitch);

  V3 view(V3 p) {
    final x1 = p.x * cy + p.z * sy;
    final z1 = -p.x * sy + p.z * cy;
    return V3(x1, p.y * cp - z1 * sp, p.y * sp + z1 * cp);
  }

  Offset proj(V3 v) {
    var d = dist - v.z;
    if (d < 0.5) d = 0.5;
    final s = scale * dist / d;
    return Offset(center.dx + v.x * s, center.dy - v.y * s);
  }

  Offset project(V3 p) => proj(view(p));
}

// Işıklar (kamera uzayında)
const double _lx = -0.42, _ly = 0.74, _lz = 0.53; // ana ışık (sol üst ön), birim
const double _hx = -0.233, _hy = 0.411, _hz = 0.881; // yarı vektör (ışık + bakış)

int _c255(double v) => v <= 0 ? 0 : (v >= 255 ? 255 : v.toInt());

double _p8(double x) {
  final x2 = x * x, x4 = x2 * x2;
  return x4 * x4;
}

/// Bir köşenin rengini hesaplar (yumuşak, çizgi film tarzı ışıklandırma).
int shadeVertex(int base, int mat, double nx, double ny, double nz, int finish, bool lightsOn) {
  final r = ((base >> 16) & 255).toDouble();
  final g = ((base >> 8) & 255).toDouble();
  final b = (base & 255).toDouble();
  var diff = nx * _lx + ny * _ly + nz * _lz;
  if (diff < 0) diff = 0;
  var nh = nx * _hx + ny * _hy + nz * _hz;
  if (nh < 0) nh = 0;
  final facing = nz < 0 ? 0.0 : nz;
  final sky = ny * 0.5 + 0.5;
  final rim = math.pow(1 - facing, 3).toDouble();
  // Gökyüzü (mavimsi) ve zemin (sıcak) ortam ışığı
  final ambR = 0.30 + 0.10 * sky, ambG = 0.31 + 0.11 * sky, ambB = 0.33 + 0.15 * sky;
  double kd = 0.62, spec = 0, env = 0, rimK = 0.0;
  switch (mat) {
    case 0: // boya
    case 6: // çıkartma
      if (finish == 2) {
        kd = 0.66;
        spec = _p8(nh) * 0.05;
        rimK = 0.06;
      } else if (finish == 1) {
        kd = 0.78;
        final s = _p8(nh);
        spec = s * s * 0.55 + s * 0.15;
        env = 0.12 * sky;
        rimK = 0.18;
      } else {
        final s = _p8(nh), s2 = s * s, s4 = s2 * s2;
        spec = s4 * s2 * 0.95 + s * 0.08;
        env = 0.06 * sky;
        rimK = 0.22;
      }
      break;
    case 1: // cam
      kd = 0.25;
      final s = _p8(nh), s2 = s * s;
      spec = s2 * s2 * 1.1;
      env = 0.05 + 0.25 * sky * sky;
      rimK = 0.25;
      break;
    case 2: // lastik
      kd = 0.55;
      spec = _p8(nh) * 0.04;
      rimK = 0.05;
      break;
    case 3: // krom
      kd = 0.5;
      final s = _p8(nh);
      spec = s * s * 0.9;
      env = 0.3 * sky;
      rimK = 0.15;
      break;
    case 4: // far
      final glow = lightsOn ? 1.3 : 0.98;
      final add = lightsOn ? 45.0 : 8.0;
      return 0xFF000000 | (_c255(r * glow + add) << 16) | (_c255(g * glow + add) << 8) | _c255(b * glow + add);
    case 7: // stop lambası
      final glow = lightsOn ? 1.3 : 0.85;
      return 0xFF000000 | (_c255(r * glow + 25) << 16) | (_c255(g * glow) << 8) | _c255(b * glow);
    default: // 5 plastik
      kd = 0.6;
      spec = _p8(nh) * 0.1;
      rimK = 0.05;
  }
  final addW = (spec + env + rim * rimK) * 255;
  return 0xFF000000 |
      (_c255(r * (ambR + kd * diff) + addW) << 16) |
      (_c255(g * (ambG + kd * diff) + addW) << 8) |
      _c255(b * (ambB + kd * diff) + addW * 1.04);
}

class _Scratch {
  final Float32List sx; // üçgen başına 6
  final Int32List cc; // üçgen başına 3
  final Float64List depth;
  final Float64List partDepth;
  _Scratch(int n, int parts)
      : sx = Float32List(n * 6),
        cc = Int32List(n * 3),
        depth = Float64List(n),
        partDepth = Float64List(parts);
}

final Expando<_Scratch> _scratch = Expando();

/// Ağı çizer. Parçalar uzaktan yakına, parça içindeki üçgenler de uzaktan yakına sıralanır.
void drawMesh(Canvas canvas, Mesh mesh, Camera cam, int finish, bool lightsOn, {bool mirror = false, double bob = 0}) {
  final n = mesh.count;
  if (n == 0) return;
  final sc = _scratch[mesh] ??= _Scratch(n, mesh.parts);
  final p = mesh.pos, nr = mesh.nrm;
  final cy = cam.cy, sy = cam.sy, cp = cam.cp, sp = cam.sp;
  const dist = Camera.dist;
  final f = cam.scale * dist;
  final ox = cam.center.dx, oy = cam.center.dy;
  final ym = mirror ? -1.0 : 1.0;

  // Parça derinlikleri
  for (var k = 0; k < mesh.parts; k++) {
    final x = mesh.partC[k * 3], y = mesh.partC[k * 3 + 1] * ym + bob * ym, z = mesh.partC[k * 3 + 2];
    final z1 = -x * sy + z * cy;
    sc.partDepth[k] = y * sp + z1 * cp;
  }

  final vis = <int>[];
  final tx = Float64List(3), ty = Float64List(3), tz = Float64List(3);
  for (var i = 0; i < n; i++) {
    final o = i * 9;
    for (var k = 0; k < 3; k++) {
      final x = p[o + k * 3], y = p[o + k * 3 + 1] * ym + bob * ym, z = p[o + k * 3 + 2];
      final x1 = x * cy + z * sy;
      final z1 = -x * sy + z * cy;
      tx[k] = x1;
      ty[k] = y * cp - z1 * sp;
      tz[k] = y * sp + z1 * cp;
    }
    // Arka yüz ayıklama
    final ax = tx[1] - tx[0], ay = ty[1] - ty[0], az = tz[1] - tz[0];
    final bx = tx[2] - tx[0], by = ty[2] - ty[0], bz = tz[2] - tz[0];
    var nx = ay * bz - az * by, ny = az * bx - ax * bz, nz = ax * by - ay * bx;
    if (mirror) {
      nx = -nx;
      ny = -ny;
      nz = -nz;
    }
    final dot = nx * (0 - tx[0]) + ny * (0 - ty[0]) + nz * (dist - tz[0]);
    if (dot <= 0) continue;
    vis.add(i);
    sc.depth[i] = (tz[0] + tz[1] + tz[2]) / 3;
    final c = mesh.col[i], m = mesh.mat[i];
    for (var k = 0; k < 3; k++) {
      var d = dist - tz[k];
      if (d < 0.5) d = 0.5;
      final s = f / d;
      sc.sx[i * 6 + k * 2] = ox + tx[k] * s;
      sc.sx[i * 6 + k * 2 + 1] = oy - ty[k] * s;
      final qx = nr[o + k * 3], qy = nr[o + k * 3 + 1] * ym, qz = nr[o + k * 3 + 2];
      final vx = qx * cy + qz * sy;
      final vz1 = -qx * sy + qz * cy;
      sc.cc[i * 3 + k] = shadeVertex(c, m, vx, qy * cp - vz1 * sp, qy * sp + vz1 * cp, finish, lightsOn);
    }
  }
  if (vis.isEmpty) return;
  final part = mesh.part, decal = mesh.decal, pd = sc.partDepth, dp = sc.depth;
  vis.sort((a, b) {
    final pa = part[a], pb = part[b];
    if (pa != pb) {
      final c = pd[pa].compareTo(pd[pb]);
      if (c != 0) return c;
      return pa.compareTo(pb);
    }
    final da = decal[a], db = decal[b];
    if (da != db) return da.compareTo(db);
    return dp[a].compareTo(dp[b]);
  });
  final pos = Float32List(vis.length * 6);
  final col = Int32List(vis.length * 3);
  var j = 0, q = 0;
  for (final i in vis) {
    for (var k = 0; k < 6; k++) {
      pos[j++] = sc.sx[i * 6 + k];
    }
    col[q++] = sc.cc[i * 3];
    col[q++] = sc.cc[i * 3 + 1];
    col[q++] = sc.cc[i * 3 + 2];
  }
  final v = ui.Vertices.raw(ui.VertexMode.triangles, pos, colors: col);
  canvas.drawVertices(v, BlendMode.modulate, Paint()..color = Colors.white);
}

Path _footprint(Camera cam, Mesh mesh, double grow) {
  final w = mesh.halfW * grow, l = mesh.halfL * grow;
  final pts = <Offset>[];
  for (var i = 0; i < 28; i++) {
    final a = i / 28 * 2 * math.pi;
    final ca = math.cos(a), sa = math.sin(a);
    final x = w * ca.sign * math.pow(ca.abs(), 0.45).toDouble();
    final z = l * sa.sign * math.pow(sa.abs(), 0.45).toDouble();
    pts.add(cam.project(V3(x, 0, z)));
  }
  return Path()..addPolygon(pts, true);
}

/// Arabayı zemindeki gölge, neon ve far ışığıyla birlikte çizer.
void paintCar(
  Canvas canvas,
  CarConfig cfg,
  Camera cam, {
  bool lightsOn = false,
  bool reflection = false,
  bool shadow = true,
  double bob = 0,
  bool lod = false,
}) {
  final mesh = carMesh(cfg, lod: lod);

  if (cfg.neonColor != 0) {
    canvas.drawPath(
      _footprint(cam, mesh, 1.28),
      Paint()
        ..color = Color(cfg.neonColor).withAlpha(160)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cam.scale * 0.35),
    );
  }
  if (shadow) {
    canvas.drawPath(
      _footprint(cam, mesh, 1.02),
      Paint()
        ..color = Colors.black.withAlpha(cfg.neonColor != 0 ? 80 : 115)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cam.scale * 0.14),
    );
    // Tekerlek temas gölgeleri
    final contact = Paint()
      ..color = Colors.black.withAlpha(120)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cam.scale * 0.06);
    for (final w in mesh.wheels) {
      final a = cam.project(V3(w.x, 0, w.z - w.y * 0.6));
      final b = cam.project(V3(w.x, 0, w.z + w.y * 0.6));
      final c = cam.project(V3(w.x, 0, w.z));
      final rad = (b - a).distance / 2;
      canvas.drawOval(Rect.fromCenter(center: c, width: math.max(rad * 1.1, cam.scale * 0.3), height: math.max(rad * 0.7, cam.scale * 0.12)), contact);
    }
  }
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
    canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.2));
    drawMesh(canvas, carMesh(cfg, lod: true), cam, cfg.finish, lightsOn, mirror: true, bob: bob);
    canvas.restore();
  }
  drawMesh(canvas, mesh, cam, cfg.finish, lightsOn, bob: bob);
}

// ---- Yarış için önbellekli çizim (her karede yeniden hesaplamamak için) ----
final Map<String, ui.Picture> _pics = {};

/// Arabayı (0,0) merkezli kaydedip tekrar tekrar çizer. Yarışta performans için.
void paintCarCached(Canvas canvas, CarConfig cfg, Offset at, double scale, double yaw, double pitch,
    {bool lightsOn = false}) {
  final yq = (yaw * 20).round() / 20;
  final key = '${cfg.meshKey}|${cfg.neon}|${cfg.finish}|$yq|${pitch.toStringAsFixed(2)}|${scale.toStringAsFixed(1)}|$lightsOn';
  var pic = _pics[key];
  if (pic == null) {
    if (_pics.length > 80) _pics.clear();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    paintCar(c, cfg, Camera(center: Offset.zero, scale: scale, yaw: yq, pitch: pitch), lightsOn: lightsOn, lod: true);
    pic = rec.endRecording();
    _pics[key] = pic;
  }
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.drawPicture(pic);
  canvas.restore();
}
