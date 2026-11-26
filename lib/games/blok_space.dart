import 'dart:math';

import 'package:flutter/material.dart';

import '../sfx.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'blok_life.dart';

// ================= UZAY: gezegenler ve roket yolculuğu =================

class PlanetInfo {
  final String name;
  final List<String> parts; // heceler
  final Color c1, c2;
  final String fact; // inince söylenen bilgi
  final double gravity; // karakterin düşme hızı
  const PlanetInfo(this.name, this.parts, this.c1, this.c2, this.fact, this.gravity);
}

const planetsInfo = [
  PlanetInfo('Dünya', ['dün', 'ya'], Color(0xFF1E88E5), Color(0xFF43A047),
      'Dünya bizim evimiz! Denizleri, ormanları ve köyleriyle çok güzel bir gezegen.', 24),
  PlanetInfo('Ay', ['a', 'y'], Color(0xFFBDBDBD), Color(0xFF757575),
      "Ay'a geldik! Ay, Dünya'nın etrafında döner. Burada yer çekimi az, zıpla bakalım, çok yükseğe çıkacaksın!", 8),
  PlanetInfo('Mars', ['m', 'a', 'r', 's'], Color(0xFFE64A19), Color(0xFF8D3A1A),
      "Mars'a geldik! Mars'a Kızıl Gezegen denir, çünkü toprağı kırmızıdır. Olimpos Dağı en büyük volkandır.", 14),
  PlanetInfo('Kristal Gezegeni', ['kris', 'tal'], Color(0xFFBA68C8), Color(0xFF4A148C),
      'Kristal Gezegenine geldik! Bu hayali bir gezegen; ışıl ışıl kristaller ve mor ağaçlarla dolu.', 18),
];

/// "Ay" -> "Ay'a", "Mars" -> "Mars'a", "Kristal Gezegeni" -> "Kristal Gezegenine"
String planetTo(int p) => const ["Dünya'ya", "Ay'a", "Mars'a", 'Kristal Gezegenine'][p];

/// Roket yolculuğu: kalkış, gezegen seçimi, yolculuk. Seçilen gezegeni döndürür.
class SpaceScreen extends StatefulWidget {
  final int from;
  final String vehicle; // 'roket', 'uzay mekiği'
  final int startPhase; // önizleme için
  const SpaceScreen({super.key, required this.from, this.vehicle = 'roket', this.startPhase = 0});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  late int phase = widget.startPhase; // 0 kalkış, 1 seçim, 2 yolculuk
  final sw = Stopwatch()..start();
  int? target;
  double travelStart = 0;

  // gezegenlerin ekrandaki yerleri (0..1)
  static const spots = [Offset(0.30, 0.62), Offset(0.52, 0.42), Offset(0.74, 0.70), Offset(0.78, 0.24)];
  static const sizes = [0.13, 0.075, 0.10, 0.11];

  double get t => sw.elapsedMilliseconds / 1000;

  @override
  void initState() {
    super.initState();
    if (phase != 0) return;
    Sfx.play('horn1');
    Voice.say('Bismillah! Üç, iki, bir... Kalkış!');
    Future.delayed(const Duration(milliseconds: 4200), () {
      if (!mounted) return;
      setState(() => phase = 1);
      Voice.say(widget.from == 0
          ? "Uzaydayız! Türkiye'nin ilk astronotu Alper Gezeravcı da uzaya çıkmıştı. Şimdi sıra sende! Hangi gezegene gidelim?"
          : 'Uzaydayız! Hangi gezegene gidelim? Bir gezegene dokun.');
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _pick(int i) async {
    if (phase != 1) return;
    Sfx.play('click');
    if (i == widget.from) {
      Voice.say('Şu an ${planetsInfo[i].name} üstündeyiz. Başka bir gezegen seç!');
      return;
    }
    final p = planetsInfo[i];
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: p.parts,
              emoji: '🚀',
              title: '${p.name} yaz, roket yola çıksın!',
              speech: '${planetTo(i)} gidelim mi? ${p.name} yaz, roket yola çıksın!',
            ));
    if (ok != true || !mounted) return;
    setState(() {
      target = i;
      phase = 2;
      travelStart = t;
    });
    Sfx.play('uc');
    Voice.say('${planetTo(i)} gidiyoruz!');
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) Navigator.pop(context, i);
    });
  }

  void _saturn() {
    Sfx.play('click');
    Voice.say('Bu Satürn! Halkaları buz ve taş parçalarından oluşur. Satürn gazdan oluştuğu için üstüne inilemez.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (_, box) {
        final s = box.biggest;
        final r = min(s.width, s.height);
        return Stack(children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: c,
              builder: (_, __) => CustomPaint(painter: _SpacePainter(this, t)),
            ),
          ),
          if (phase == 1) ...[
            for (var i = 0; i < planetsInfo.length; i++)
              Positioned(
                left: spots[i].dx * s.width - sizes[i] * r - 20,
                top: spots[i].dy * s.height - sizes[i] * r - 20,
                width: sizes[i] * r * 2 + 40,
                height: sizes[i] * r * 2 + 64,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pick(i),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: i == widget.from ? const Color(0xFFFFD54F) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(i == widget.from ? '${planetsInfo[i].name} 📍' : planetsInfo[i].name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0.10 * s.width - 50,
              top: 0.22 * s.height - 40,
              width: 100,
              height: 80,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _saturn),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                RoundIcon(Icons.arrow_back, () {
                  Sfx.play('click');
                  Navigator.pop(context);
                }),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      phase == 0
                          ? '🚀 Bismillah! Kalkış!'
                          : phase == 1
                              ? '🪐 Hangi gezegene gidelim? Dokun!'
                              : '✨ ${planetTo(target!)} gidiyoruz...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }
}

class _SpacePainter extends CustomPainter {
  final _SpaceScreenState st;
  final double t;
  _SpacePainter(this.st, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final r = min(s.width, s.height);
    // kalkışta gökyüzü maviden siyaha döner
    final up = st.phase == 0 ? (t / 4).clamp(0.0, 1.0) : 1.0;
    final top = Color.lerp(const Color(0xFF4FC3F7), const Color(0xFF05051A), up)!;
    final bottom = Color.lerp(const Color(0xFFB3E5FC), const Color(0xFF1A1040), up)!;
    canvas.drawRect(
        Offset.zero & s, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(Offset.zero & s));
    final rnd = Random(9);
    for (var i = 0; i < 140; i++) {
      final p = Offset(rnd.nextDouble() * s.width, (rnd.nextDouble() * s.height + (st.phase == 0 ? t * 120 * (1 + i % 3) : 0)) % s.height);
      final tw = 0.6 + 0.4 * sin(t * 3 + i);
      canvas.drawCircle(p, rnd.nextDouble() * 1.5 + 0.5, Paint()..color = Colors.white.withAlpha((up * 230 * tw).round()));
    }
    if (st.phase == 0) {
      _launch(canvas, s, r);
      return;
    }
    // güneş ve uzak Satürn
    canvas.drawCircle(Offset(-r * 0.05, s.height * 0.5), r * 0.22,
        Paint()..shader = RadialGradient(colors: const [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0x00FF6F00)], stops: const [0.3, 0.75, 1]).createShader(Rect.fromCircle(center: Offset(-r * 0.05, s.height * 0.5), radius: r * 0.22)));
    _saturn(canvas, Offset(s.width * 0.10, s.height * 0.22), r * 0.045);
    for (var i = 0; i < planetsInfo.length; i++) {
      final o = Offset(_SpaceScreenState.spots[i].dx * s.width, _SpaceScreenState.spots[i].dy * s.height);
      var rad = _SpaceScreenState.sizes[i] * r;
      if (st.phase == 2 && i == st.target) rad *= 1 + ((t - st.travelStart) / 3).clamp(0.0, 1.0) * 0.6;
      _planet(canvas, o, rad, i);
    }
    // roket: seçimde bulunduğumuz gezegenin yanında, yolculukta hedefe uçar
    final from = _spot(s, st.widget.from);
    if (st.phase == 1) {
      final a = t * 1.4;
      final rr = _SpaceScreenState.sizes[st.widget.from] * r + 26;
      final p = from + Offset(cos(a), sin(a)) * rr;
      _rocket(canvas, p, r * 0.05, a + pi, true);
    } else if (st.target != null) {
      final to = _spot(s, st.target!);
      final k = Curves.easeInOut.transform(((t - st.travelStart) / 3).clamp(0.0, 1.0));
      final ctrl = Offset((from.dx + to.dx) / 2, min(from.dy, to.dy) - r * 0.25);
      Offset bez(double u) => from * pow(1 - u, 2).toDouble() + ctrl * (2 * u * (1 - u)) + to * (u * u);
      // renkli iz
      for (var i = 0; i < 24; i++) {
        final u = (k - i * 0.012).clamp(0.0, 1.0);
        canvas.drawCircle(bez(u), r * 0.012 * (1 - i / 24), Paint()..color = HSVColor.fromAHSV(0.8, (i * 15 + t * 200) % 360, 0.8, 1).toColor());
      }
      final p = bez(k), q = bez(min(1, k + 0.01));
      _rocket(canvas, p, r * 0.06 * (1 - k * 0.5), atan2(q.dy - p.dy, q.dx - p.dx) + pi / 2, true);
    }
  }

  Offset _spot(Size s, int i) => Offset(_SpaceScreenState.spots[i].dx * s.width, _SpaceScreenState.spots[i].dy * s.height);

  void _launch(Canvas canvas, Size s, double r) {
    final k = Curves.easeIn.transform((t / 4).clamp(0.0, 1.0));
    // aşağıda kalan Dünya ufku
    final groundY = s.height * (0.85 + k * 0.9);
    canvas.drawRect(Rect.fromLTRB(0, groundY, s.width, s.height + 400), Paint()..color = const Color(0xFF66BB6A));
    canvas.drawRect(Rect.fromLTRB(0, groundY - 6, s.width, groundY), Paint()..color = const Color(0xFF8D6E63));
    // bulutlar aşağı kayar
    final cloud = Paint()..color = Colors.white.withAlpha((200 * (1 - k)).round());
    for (final cc in const [(0.2, 0.3), (0.75, 0.2), (0.55, 0.55), (0.1, 0.7)]) {
      final o = Offset(s.width * cc.$1, (s.height * cc.$2 + k * s.height * 1.4));
      canvas.drawCircle(o, 34, cloud);
      canvas.drawCircle(o + const Offset(30, 8), 26, cloud);
      canvas.drawCircle(o - const Offset(30, -8), 24, cloud);
    }
    final shake = t < 1.2 ? sin(t * 70) * 3 : 0.0;
    final y = s.height * 0.72 - k * s.height * 0.35;
    final p = Offset(s.width / 2 + shake, y);
    // duman
    for (var i = 0; i < 18; i++) {
      final u = i / 18;
      canvas.drawCircle(p + Offset(sin(i * 2.3 + t * 3) * 18 * u, r * 0.16 + u * r * 0.4), r * 0.03 + u * r * 0.05,
          Paint()..color = Colors.white.withAlpha((160 * (1 - u)).round()));
    }
    _rocket(canvas, p, r * 0.11, 0, t > 0.4);
    // geri sayım
    if (t < 3) {
      final n = 3 - t.floor();
      final tp = TextPainter(
          text: TextSpan(
              text: '$n',
              style: TextStyle(fontSize: r * 0.25, fontWeight: FontWeight.w900, color: Colors.white, shadows: const [Shadow(blurRadius: 8)])),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(s.width * 0.78 - tp.width / 2, s.height * 0.25));
    }
  }

  void _rocket(Canvas canvas, Offset p, double u, double angle, bool fire) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);
    if (fire) {
      final f = 1 + sin(t * 40) * 0.15;
      canvas.drawPath(
          Path()
            ..moveTo(-u * 0.35, u * 1.1)
            ..quadraticBezierTo(0, u * (1.1 + 1.4 * f), u * 0.35, u * 1.1)
            ..close(),
          Paint()..color = const Color(0xFFFF7043));
      canvas.drawPath(
          Path()
            ..moveTo(-u * 0.2, u * 1.1)
            ..quadraticBezierTo(0, u * (1.1 + 0.8 * f), u * 0.2, u * 1.1)
            ..close(),
          Paint()..color = const Color(0xFFFFEB3B));
    }
    final red = Paint()..color = const Color(0xFFE53935);
    // kanatçıklar
    canvas.drawPath(Path()..moveTo(-u * 0.4, u * 0.4)..lineTo(-u * 0.8, u * 1.2)..lineTo(-u * 0.4, u * 1.0)..close(), red);
    canvas.drawPath(Path()..moveTo(u * 0.4, u * 0.4)..lineTo(u * 0.8, u * 1.2)..lineTo(u * 0.4, u * 1.0)..close(), red);
    // gövde
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-u * 0.4, -u * 0.6, u * 0.4, u * 1.1), Radius.circular(u * 0.2)),
        Paint()..color = Colors.white);
    canvas.drawPath(Path()..moveTo(-u * 0.4, -u * 0.5)..quadraticBezierTo(0, -u * 1.6, u * 0.4, -u * 0.5)..close(), red);
    canvas.drawCircle(Offset(0, -u * 0.05), u * 0.2, Paint()..color = const Color(0xFF4FC3F7));
    canvas.drawCircle(Offset(0, -u * 0.05), u * 0.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.06
          ..color = const Color(0xFF90A4AE));
    canvas.restore();
  }

  void _planet(Canvas canvas, Offset o, double rad, int i) {
    final p = planetsInfo[i];
    canvas.drawCircle(o, rad * 1.18, Paint()..color = p.c1.withAlpha(50));
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: rad)));
    canvas.drawCircle(o, rad, Paint()..color = p.c1);
    final rnd = Random(i * 31 + 1);
    final spin = t * 0.15;
    for (var k = 0; k < 9; k++) {
      final dx = ((rnd.nextDouble() * 2 - 1 + spin) % 2.4) - 1.2;
      final c = o + Offset(dx * rad, (rnd.nextDouble() * 2 - 1) * rad * 0.8);
      final cr = rad * (0.12 + rnd.nextDouble() * 0.22);
      switch (i) {
        case 0:
          canvas.drawOval(Rect.fromCenter(center: c, width: cr * 2.6, height: cr * 1.7), Paint()..color = p.c2);
        case 1:
          canvas.drawCircle(c, cr * 0.7, Paint()..color = p.c2);
          canvas.drawCircle(c + Offset(cr * 0.12, cr * 0.12), cr * 0.5, Paint()..color = const Color(0xFF9E9E9E));
        case 2:
          canvas.drawOval(Rect.fromCenter(center: c, width: cr * 2.4, height: cr * 1.2), Paint()..color = p.c2.withAlpha(170));
        default:
          final path = Path()
            ..moveTo(c.dx, c.dy - cr)
            ..lineTo(c.dx + cr * 0.4, c.dy)
            ..lineTo(c.dx, c.dy + cr)
            ..lineTo(c.dx - cr * 0.4, c.dy)
            ..close();
          canvas.drawPath(path, Paint()..color = const Color(0xFFF8BBD0));
      }
    }
    if (i == 0) {
      // bulutlar
      canvas.drawOval(Rect.fromCenter(center: o + Offset(-rad * 0.3, -rad * 0.5), width: rad * 0.9, height: rad * 0.18),
          Paint()..color = Colors.white.withAlpha(200));
    }
    if (i == 2) {
      canvas.drawOval(Rect.fromCenter(center: o + Offset(0, -rad * 0.95), width: rad * 1.1, height: rad * 0.35), Paint()..color = Colors.white);
    }
    // gölge: güneş solda
    canvas.drawCircle(o, rad,
        Paint()
          ..shader = RadialGradient(center: const Alignment(-0.5, -0.3), colors: [Colors.white.withAlpha(70), Colors.transparent, Colors.black.withAlpha(150)], stops: const [0, 0.5, 1])
              .createShader(Rect.fromCircle(center: o, radius: rad)));
    canvas.restore();
  }

  void _saturn(Canvas canvas, Offset o, double rad) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rad * 0.25
      ..color = const Color(0xFFE6CFA0);
    canvas.drawOval(Rect.fromCenter(center: o, width: rad * 4, height: rad * 1.1), ring);
    canvas.drawCircle(o, rad, Paint()..color = const Color(0xFFE0B870));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(o.dx - rad * 3, o.dy, o.dx + rad * 3, o.dy + rad * 2));
    canvas.drawOval(Rect.fromCenter(center: o, width: rad * 4, height: rad * 1.1), ring);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpacePainter old) => true;
}
