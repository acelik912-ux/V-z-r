import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art.dart';
import '../voice.dart';
import 'blok.dart';

// ================= HARİTA =================

/// Dünyanın kuşbakışı resmi: her hücre bir piksel, rengi en üstteki blok,
/// yükseklik arttıkça biraz açılır.
Future<ui.Image> buildMapImage(BlockWorld w) {
  final wd = maxX - minX + 1, hg = maxY - minY + 1;
  final px = Uint8List(wd * hg * 4);
  final su = matIndex('su');
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final z = w.topZ(x, y);
      final m = w.blocks[ck(x, y, z)];
      var c = m == null ? const Color(0xFF7CB342) : mats[m].color;
      if (m == su) c = const Color(0xFF29B6F6);
      final k = ((x - minX) + (y - minY) * wd) * 4;
      final lift = (z * 0.035).clamp(0.0, 0.5);
      int ch(double v) => (255 * (v + (1 - v) * lift)).round().clamp(0, 255);
      px[k] = ch(c.r);
      px[k + 1] = ch(c.g);
      px[k + 2] = ch(c.b);
      px[k + 3] = 255;
    }
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(px, wd, hg, ui.PixelFormat.rgba8888, done.complete);
  return done.future;
}

/// Köşedeki küçük harita: oyuncunun çevresi, yerler ve yön oku.
class MiniMap extends StatelessWidget {
  final ui.Image? img;
  final double px, py, facing;
  final Map<String, (int, int)> places;
  final List<(double, double)> friends;
  final VoidCallback onTap;
  const MiniMap(
      {super.key,
      required this.img,
      required this.px,
      required this.py,
      required this.facing,
      required this.places,
      required this.friends,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _MiniPainter(img, px, py, facing, places, friends))),
              const Positioned(
                right: 3,
                bottom: 2,
                child: Text('🗺️', style: TextStyle(fontSize: 18)),
              ),
            ]),
          ),
        ),
      );
}

class _MiniPainter extends CustomPainter {
  final ui.Image? img;
  final double px, py, facing;
  final Map<String, (int, int)> places;
  final List<(double, double)> friends;
  _MiniPainter(this.img, this.px, this.py, this.facing, this.places, this.friends);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF29B6F6));
    const span = 48.0; // gösterilen hücre sayısı
    final s = size.width / span;
    final ox = px - span / 2, oy = py - span / 2;
    final im = img;
    if (im != null) {
      canvas.drawImageRect(
          im,
          Rect.fromLTWH(ox - minX, oy - minY, span, span),
          Offset.zero & size,
          Paint()..filterQuality = FilterQuality.none);
    }
    for (final e in places.entries) {
      final o = Offset((e.value.$1 + 0.5 - ox) * s, (e.value.$2 + 0.5 - oy) * s);
      if (!(Offset.zero & size).contains(o)) continue;
      canvas.drawCircle(o, 4, Paint()..color = Colors.white);
      canvas.drawCircle(o, 2.6, Paint()..color = e.key.endsWith('Adası') ? const Color(0xFF0277BD) : const Color(0xFF2E7D32));
    }
    for (final f in friends) {
      final o = Offset((f.$1 - ox) * s, (f.$2 - oy) * s);
      canvas.drawCircle(o, 2.8, Paint()..color = const Color(0xFFAB47BC));
    }
    _arrow(canvas, Offset(size.width / 2, size.height / 2), facing, 8);
  }

  @override
  bool shouldRepaint(covariant _MiniPainter o) =>
      o.img != img || o.px != px || o.py != py || o.facing != facing || o.places.length != places.length;
}

/// Oyuncuyu gösteren ok (bakış yönünde).
void _arrow(Canvas canvas, Offset c, double facing, double r) {
  final dx = sin(facing), dy = cos(facing);
  final tip = c + Offset(dx, dy) * r;
  final l = c + Offset(-dy, dx) * r * 0.65 - Offset(dx, dy) * r * 0.6;
  final rr = c - Offset(-dy, dx) * r * 0.65 - Offset(dx, dy) * r * 0.6;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(l.dx, l.dy)
    ..lineTo(rr.dx, rr.dy)
    ..close();
  canvas.drawPath(path, Paint()..color = Colors.white);
  canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
  canvas.drawCircle(c, r * 0.35, Paint()..color = const Color(0xFFD32F2F));
}

/// Büyük harita: yakınlaştırılabilir. Bir yere ya da bir yer adına dokununca
/// oraya ışınlanılır. Dönüş: (x, y, ad?)
class WorldMapScreen extends StatefulWidget {
  final ui.Image? img;
  final double px, py, facing;
  final Map<String, (int, int)> places;
  final List<(double, double, String)> friends;
  const WorldMapScreen(
      {super.key,
      required this.img,
      required this.px,
      required this.py,
      required this.facing,
      required this.places,
      required this.friends});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  (int, int)? pick;

  @override
  void initState() {
    super.initState();
    Voice.say('Harita! Gitmek istediğin yere dokun, oraya ışınlan.');
  }

  @override
  Widget build(BuildContext context) {
    final wd = (maxX - minX + 1).toDouble(), hg = (maxY - minY + 1).toDouble();
    return Scaffold(
      backgroundColor: const Color(0xFF0277BD),
      body: SafeArea(
        child: Column(children: [
          const TopBar('🗺️ Harita'),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text('Bir yere ya da bir yer adına dokun: oraya ışınlanırsın. İki parmakla büyüt.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final s = min(box.maxWidth / wd, box.maxHeight / hg);
              final w = wd * s, h = hg * s;
              Offset at(double x, double y) => Offset((x - minX) * s, (y - minY) * s);
              return Center(
                child: InteractiveViewer(
                  maxScale: 6,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTapUp: (d) {
                            final x = (d.localPosition.dx / s + minX).floor(), y = (d.localPosition.dy / s + minY).floor();
                            Navigator.pop(context, (x, y, null));
                          },
                          child: CustomPaint(painter: _BigPainter(widget.img, s)),
                        ),
                      ),
                      for (final f in widget.friends)
                        Positioned(
                          left: at(f.$1, f.$2).dx - 5,
                          top: at(f.$1, f.$2).dy - 5,
                          child: IgnorePointer(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFAB47BC), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                            ),
                          ),
                        ),
                      for (final e in widget.places.entries)
                        Positioned(
                          left: at(e.value.$1 + 0.5, e.value.$2 + 0.5).dx,
                          top: at(e.value.$1 + 0.5, e.value.$2 + 0.5).dy,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -1),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context, (e.value.$1, e.value.$2, e.key)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: e.key.endsWith('Adası') ? const Color(0xEE0277BD) : const Color(0xEE2E7D32),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(e.key.split(' ').first,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: at(widget.px, widget.py).dx - 14,
                        top: at(widget.px, widget.py).dy - 14,
                        child: IgnorePointer(
                          child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: _MePainter(widget.facing))),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(spacing: 14, children: const [
              Text('▲ Sen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text('🟢 Köy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text('🔵 Ada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text('🟣 Arkadaş', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BigPainter extends CustomPainter {
  final ui.Image? img;
  final double s;
  _BigPainter(this.img, this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final im = img;
    if (im == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF7CB342));
      return;
    }
    canvas.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), Offset.zero & size,
        Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(covariant _BigPainter o) => o.img != img || o.s != s;
}

class _MePainter extends CustomPainter {
  final double facing;
  _MePainter(this.facing);

  @override
  void paint(Canvas canvas, Size size) => _arrow(canvas, size.center(Offset.zero), facing, size.width * 0.45);

  @override
  bool shouldRepaint(covariant _MePainter o) => o.facing != facing;
}
