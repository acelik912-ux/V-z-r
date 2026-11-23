import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art.dart';
import '../voice.dart';
import 'blok_map.dart';

// ================= DÜNYA KÜRESİ =================
//
// Düz dünya, kutup üstten bakılmış gibi küreye sarılır: dünyanın ortası kuzey
// kutbu, kenarına doğru gidildikçe ekvatora, en dışta okyanus güney kutbuna
// iner. Çocuk küreyi parmağıyla çevirir, bir yere dokununca oraya ışınlanır.

class GlobeData {
  final Uint8List px; // dünya resmi (RGBA)
  final int wd, hg; // resmin boyu
  final int x0, y0; // resmin sol üst köşesinin dünya koordinatı
  final double cx, cy, rx, ry; // dünyanın ortası ve yarıçapları
  GlobeData(this.px, this.wd, this.hg, this.x0, this.y0, this.cx, this.cy, this.rx, this.ry);

  /// Dünya noktası -> küre üstünde birim vektör
  (double, double, double) toSphere(double x, double y) {
    final u = (x - cx) / rx, v = (y - cy) / ry;
    final t = min(1.0, sqrt(u * u + v * v)) * pi; // kutuptan açı
    final f = atan2(v, u);
    return (sin(t) * cos(f), sin(t) * sin(f), cos(t));
  }

  /// Küre noktası -> dünya noktası (dünyanın dışındaysa null)
  (double, double)? toWorld(double sx, double sy, double sz) {
    final t = acos(sz.clamp(-1.0, 1.0)) / pi;
    if (t > 0.999) return null;
    final f = atan2(sy, sx);
    return (cx + cos(f) * t * rx, cy + sin(f) * t * ry);
  }
}

/// 3x3 döndürme matrisi (satırlar): görünüm = M * küre
class _Rot {
  List<double> m;
  _Rot(this.m);

  /// Verilen küre noktası ekranın ortasına gelsin.
  factory _Rot.facing(double px, double py, double pz) {
    // üçüncü satır: bakılan nokta; ikinci satır: kutba doğru "yukarı"
    var ux = -px * pz, uy = -py * pz, uz = 1 - pz * pz;
    var l = sqrt(ux * ux + uy * uy + uz * uz);
    if (l < 1e-4) {
      ux = 0;
      uy = 1;
      uz = 0;
      l = 1;
    }
    ux /= l;
    uy /= l;
    uz /= l;
    // birinci satır = yukarı x bakış
    final rx = uy * pz - uz * py, ry = uz * px - ux * pz, rz = ux * py - uy * px;
    return _Rot([rx, ry, rz, ux, uy, uz, px, py, pz]);
  }

  (double, double, double) apply(double x, double y, double z) =>
      (m[0] * x + m[1] * y + m[2] * z, m[3] * x + m[4] * y + m[5] * z, m[6] * x + m[7] * y + m[8] * z);

  (double, double, double) back(double x, double y, double z) =>
      (m[0] * x + m[3] * y + m[6] * z, m[1] * x + m[4] * y + m[7] * z, m[2] * x + m[5] * y + m[8] * z);

  /// Ekranda sürükleme: görünüm eksenlerinde döndür.
  void drag(double ax, double ay) {
    // önce y ekseni etrafında (sağa-sola), sonra x ekseni etrafında (yukarı-aşağı)
    final cy = cos(ax), sy = sin(ax), cx = cos(ay), sx = sin(ay);
    final r = [cy, 0.0, sy, sx * sy, cx, -sx * cy, -cx * sy, sx, cx * cy];
    final o = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        var v = 0.0;
        for (var k = 0; k < 3; k++) {
          v += r[i * 3 + k] * m[k * 3 + j];
        }
        o[i * 3 + j] = v;
      }
    }
    m = o;
  }
}

class GlobeMapScreen extends StatefulWidget {
  final GlobeData data;
  final double px, py;
  final Map<String, (int, int)> places;
  final List<(double, double, String)> friends;
  final VoidCallback? onFlat;
  const GlobeMapScreen(
      {super.key, required this.data, required this.px, required this.py, required this.places, required this.friends, this.onFlat});

  @override
  State<GlobeMapScreen> createState() => _GlobeMapScreenState();
}

class _GlobeMapScreenState extends State<GlobeMapScreen> {
  static const n = 300; // kürenin piksel boyu
  late _Rot rot;
  ui.Image? img;
  bool busy = false, again = false;
  double zoom = 1, zoom0 = 1;

  @override
  void initState() {
    super.initState();
    final (x, y, z) = widget.data.toSphere(widget.px, widget.py);
    rot = _Rot.facing(x, y, z);
    _render();
    Voice.say('Dünya küresi! Parmağınla çevir. Gitmek istediğin yere dokun, oraya ışınlan.');
  }

  @override
  void dispose() {
    img?.dispose();
    super.dispose();
  }

  void _render() {
    if (busy) {
      again = true;
      return;
    }
    busy = true;
    final d = widget.data;
    final out = Uint8List(n * n * 4);
    const h = n / 2;
    for (var j = 0; j < n; j++) {
      final vy = -(j + 0.5 - h) / h;
      for (var i = 0; i < n; i++) {
        final vx = (i + 0.5 - h) / h;
        final rr = vx * vx + vy * vy;
        if (rr > 1) continue;
        final vz = sqrt(1 - rr);
        final (sx, sy, sz) = rot.back(vx, vy, vz);
        final w = d.toWorld(sx, sy, sz);
        int r, g, b;
        if (w == null) {
          r = 21;
          g = 101;
          b = 192; // açık okyanus
        } else {
          final ix = (w.$1 - d.x0).floor(), iy = (w.$2 - d.y0).floor();
          if (ix < 0 || iy < 0 || ix >= d.wd || iy >= d.hg) {
            r = 21;
            g = 101;
            b = 192;
          } else {
            final k = (ix + iy * d.wd) * 4;
            r = d.px[k];
            g = d.px[k + 1];
            b = d.px[k + 2];
          }
        }
        // ışık: kenarlar biraz karanlık, üstte parlama
        final light = 0.45 + 0.55 * vz + 0.12 * max(0, vx * -0.4 + vy * 0.6);
        final o = (i + j * n) * 4;
        out[o] = (r * light).round().clamp(0, 255);
        out[o + 1] = (g * light).round().clamp(0, 255);
        out[o + 2] = (b * light).round().clamp(0, 255);
        // kenarda atmosfer
        out[o + 3] = rr > 0.97 ? ((1 - rr) / 0.03 * 255).round().clamp(0, 255) : 255;
      }
    }
    imageFromPixels(out, n, n).then((im) {
      busy = false;
      if (!mounted) {
        im.dispose();
        return;
      }
      setState(() {
        img?.dispose();
        img = im;
      });
      if (again) {
        again = false;
        _render();
      }
    });
  }

  /// Küre üstündeki noktanın ekrandaki yeri (arka yüzdeyse null)
  Offset? _screen(double wx, double wy, double r, Offset c) {
    final (sx, sy, sz) = widget.data.toSphere(wx, wy);
    final (vx, vy, vz) = rot.apply(sx, sy, sz);
    if (vz < 0.12) return null;
    return c + Offset(vx * r, -vy * r);
  }

  void _tap(Offset p, double r, Offset c) {
    final vx = (p.dx - c.dx) / r, vy = -(p.dy - c.dy) / r;
    final rr = vx * vx + vy * vy;
    if (rr > 1) return;
    final (sx, sy, sz) = rot.back(vx, vy, sqrt(1 - rr));
    final w = widget.data.toWorld(sx, sy, sz);
    if (w == null) {
      Voice.say('Orası açık okyanus! Karaya dokun.');
      return;
    }
    Navigator.pop(context, (w.$1.floor(), w.$2.floor(), null));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B1033),
        body: SafeArea(
          child: Column(children: [
            TopBar('🌍 Dünya',
                trailing: widget.onFlat == null
                    ? null
                    : TextButton.icon(
                        style: TextButton.styleFrom(backgroundColor: Colors.white),
                        onPressed: widget.onFlat,
                        icon: const Text('🗺️', style: TextStyle(fontSize: 18)),
                        label: const Text('Düz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      )),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text('Parmağınla çevir · Bir yere ya da bir yer adına dokun: oraya ışınlan',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final r = min(box.maxWidth, box.maxHeight) * 0.46 * zoom;
                final c = Offset(box.maxWidth / 2, box.maxHeight / 2);
                final pins = <Widget>[];
                for (final e in widget.places.entries) {
                  final o = _screen(e.value.$1 + 0.5, e.value.$2 + 0.5, r, c);
                  if (o == null) continue;
                  final island = e.key.endsWith('Adası');
                  pins.add(Positioned(
                    left: o.dx,
                    top: o.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -1),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, (e.value.$1, e.value.$2, e.key)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: island ? const Color(0xEE0277BD) : const Color(0xEE2E7D32),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text('${island ? '🏝️' : '🏘️'} ${e.key.split(' ').first}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          Container(width: 2, height: 6, color: Colors.white),
                        ]),
                      ),
                    ),
                  ));
                }
                for (final f in widget.friends) {
                  final o = _screen(f.$1, f.$2, r, c);
                  if (o == null) continue;
                  pins.add(Positioned(
                    left: o.dx - 5,
                    top: o.dy - 5,
                    child: IgnorePointer(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(color: const Color(0xFFAB47BC), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      ),
                    ),
                  ));
                }
                final me = _screen(widget.px, widget.py, r, c);
                if (me != null) {
                  pins.add(Positioned(
                    left: me.dx - 16,
                    top: me.dy - 34,
                    child: const IgnorePointer(child: Text('📍', style: TextStyle(fontSize: 30))),
                  ));
                }
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (_) => zoom0 = zoom,
                  onScaleUpdate: (d) {
                    if (d.pointerCount > 1) {
                      setState(() => zoom = (zoom0 * d.scale).clamp(0.8, 2.4));
                      return;
                    }
                    rot.drag(d.focalPointDelta.dx / r, d.focalPointDelta.dy / r);
                    _render();
                    setState(() {});
                  },
                  onTapUp: (d) => _tap(d.localPosition, r, c),
                  child: Stack(clipBehavior: Clip.hardEdge, children: [
                    Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
                    Positioned(
                      left: c.dx - r,
                      top: c.dy - r,
                      width: r * 2,
                      height: r * 2,
                      child: CustomPaint(painter: _GlobePainter(img)),
                    ),
                    ...pins,
                  ]),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(spacing: 14, alignment: WrapAlignment.center, children: [
                const Text('📍 Sen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const Text('🏘️ Köy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const Text('🏝️ Ada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const Text('🟣 Arkadaş', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                Bouncy(
                  onTap: () {
                    final (x, y, z) = widget.data.toSphere(widget.px, widget.py);
                    rot = _Rot.facing(x, y, z);
                    _render();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Text('🎯 Bulunduğum yer', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
}

class _GlobePainter extends CustomPainter {
  final ui.Image? img;
  _GlobePainter(this.img);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    canvas.drawCircle(c, r * 1.04, Paint()..color = const Color(0x5539A0FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    final im = img;
    if (im == null) {
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1565C0));
      return;
    }
    canvas.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), Offset.zero & size,
        Paint()..filterQuality = FilterQuality.low);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter o) => o.img != img;
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(5);
    final p = Paint()..color = Colors.white70;
    for (var i = 0; i < 90; i++) {
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), r.nextDouble() * 1.4 + 0.3, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
