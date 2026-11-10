import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art.dart';
import '../sfx.dart';
import '../voice.dart';
import 'kit.dart';

class _En {
  final String en;
  final String tr;
  final String emoji;
  final Color? color;
  const _En(this.en, this.tr, this.emoji, [this.color]);
}

const _colors = [
  _En('red', 'kırmızı', '🟥', Color(0xFFE53935)),
  _En('blue', 'mavi', '🟦', Color(0xFF1E88E5)),
  _En('yellow', 'sarı', '🟨', Color(0xFFFDD835)),
  _En('green', 'yeşil', '🟩', Color(0xFF43A047)),
  _En('orange', 'turuncu', '🟧', Color(0xFFFB8C00)),
  _En('purple', 'mor', '🟪', Color(0xFF8E24AA)),
];

const _things = [
  _En('cat', 'kedi', '🐱'),
  _En('dog', 'köpek', '🐶'),
  _En('apple', 'elma', '🍎'),
  _En('car', 'araba', '🚗'),
  _En('house', 'ev', '🏠'),
  _En('sun', 'güneş', '☀️'),
  _En('ball', 'top', '⚽'),
  _En('bird', 'kuş', '🐦'),
  _En('star', 'yıldız', '⭐'),
  _En('tree', 'ağaç', '🌳'),
  _En('book', 'kitap', '📖'),
  _En('fish', 'balık', '🐟'),
];

const _numbers = ['zero', 'one', 'two', 'three', 'four', 'five'];

// ======================= GEMİ YÜKLE =======================

/// Gemi Yükle: Polly İngilizce söyler, doğru kutuyu gemiye yükle.
class GemiYukle extends StatefulWidget {
  const GemiYukle({super.key});

  @override
  State<GemiYukle> createState() => _GemiYukleState();
}

class _GemiYukleState extends State<GemiYukle> {
  static const total = 6;
  final rnd = Random();
  int round = 0;
  int mistakes = 0;
  int shake = 0;
  int loaded = 0;
  int count = 1;
  late _En target;
  late List<_En> boxes;
  final List<Color> onShip = [];
  bool sailing = false;

  @override
  void initState() {
    super.initState();
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.papagan, 'Merhaba! Ben Polly. İngilizce söylediğim kutuyu gemiye yükle!');
      Future.delayed(const Duration(milliseconds: 3800), _ask);
    });
  }

  void _newRound() {
    final pool = [..._colors]..shuffle(rnd);
    boxes = pool.take(4).toList();
    target = boxes[rnd.nextInt(4)];
    count = round >= 4 ? 2 + rnd.nextInt(2) : 1;
    loaded = 0;
  }

  void _ask() {
    if (!mounted) return;
    Voice.sayEn(count == 1 ? '${target.en} box!' : '${_numbers[count]} ${target.en} boxes!');
  }

  Future<void> _tap(_En b) async {
    if (sailing) return;
    if (b == target) {
      Sfx.play('vinc');
      setState(() {
        loaded++;
        onShip.add(b.color!);
      });
      if (loaded < count) return;
      Sfx.play('correct');
      Voice.say(count == 1 ? '${b.tr} kutu. Aferin!' : '${count == 2 ? 'iki' : 'üç'} ${b.tr} kutu. Aferin!');
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      if (round + 1 >= total) {
        setState(() => sailing = true);
        Sfx.play('horn2');
        await Future.delayed(const Duration(milliseconds: 1800));
        if (!mounted) return;
        final again = await levelDone(context, id: 'gemi', stars: starsFor(mistakes), who: Who.papagan, sticker: 'k_papagan');
        if (mounted) Navigator.pop(context, again);
        return;
      }
      setState(() {
        round++;
        _newRound();
      });
      _ask();
    } else {
      Sfx.play('wrong');
      Voice.say('Bu ${b.tr}. Polly ne dedi? Bir daha dinle.');
      setState(() {
        mistakes++;
        shake++;
      });
      Future.delayed(const Duration(milliseconds: 2200), _ask);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return LevelShell(
      title: 'Gemi Yükle',
      bg: 'bolge_liman',
      round: round,
      total: total,
      child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _ask,
            child: Panel(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Pic('k_papagan', height: 70),
                const SizedBox(width: 8),
                Text(count == 1 ? '${target.en} box' : '${_numbers[count]} ${target.en} boxes',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A))),
                const SizedBox(width: 6),
                const Icon(Icons.volume_up, color: Colors.black54),
              ]),
            ),
          ),
          const Spacer(),
          AnimatedSlide(
            offset: sailing ? const Offset(1.4, 0) : Offset.zero,
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeIn,
            child: SizedBox(width: w * 0.9, height: w * 0.45, child: CustomPaint(painter: _ShipPainter(onShip))),
          ),
          const Spacer(),
          Shake(
            trigger: shake,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final b in boxes)
                    Bouncy(
                      onTap: () => _tap(b),
                      child: Container(
                        width: 78,
                        height: 70,
                        decoration: BoxDecoration(
                          color: b.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 4))],
                        ),
                        child: const Center(child: Text('📦', style: TextStyle(fontSize: 30))),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipPainter extends CustomPainter {
  final List<Color> boxes;
  _ShipPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size s) {
    final hull = Path()
      ..moveTo(0, s.height * 0.55)
      ..lineTo(s.width, s.height * 0.55)
      ..lineTo(s.width * 0.88, s.height * 0.92)
      ..lineTo(s.width * 0.08, s.height * 0.92)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFFD32F2F));
    canvas.drawRect(Rect.fromLTWH(0, s.height * 0.55, s.width, s.height * 0.08), Paint()..color = Colors.white);
    // kabin
    canvas.drawRRect(RRect.fromLTRBR(s.width * 0.74, s.height * 0.18, s.width * 0.95, s.height * 0.55, const Radius.circular(8)),
        Paint()..color = Colors.white);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(s.width * (0.79 + i * 0.055), s.height * 0.3), 6, Paint()..color = const Color(0xFF4FC3F7));
    }
    canvas.drawRect(Rect.fromLTWH(s.width * 0.82, 0, s.width * 0.06, s.height * 0.18), Paint()..color = const Color(0xFF263238));
    // yüklenen kutular
    final bw = s.width * 0.11, bh = s.height * 0.16;
    for (var i = 0; i < boxes.length; i++) {
      final col = i % 6, row = i ~/ 6;
      final r = Rect.fromLTWH(s.width * 0.04 + col * (bw + 2), s.height * 0.55 - (row + 1) * (bh + 2), bw, bh);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = boxes[i]);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    // dalga
    final wave = Paint()..color = const Color(0xCC29B6F6);
    canvas.drawRect(Rect.fromLTWH(-20, s.height * 0.86, s.width + 40, s.height * 0.14), wave);
  }

  @override
  bool shouldRepaint(covariant _ShipPainter old) => true;
}

// ======================= BALIK TUT =======================

class _Fish {
  _En thing;
  double x;
  final double y;
  final double speed;
  final Color color;
  bool caught = false;
  _Fish(this.thing, this.x, this.y, this.speed, this.color);
}

/// Balık Tut: Polly'nin söylediği şeyi taşıyan balığı yakala.
class BalikTut extends StatefulWidget {
  const BalikTut({super.key});

  @override
  State<BalikTut> createState() => _BalikTutState();
}

class _BalikTutState extends State<BalikTut> with SingleTickerProviderStateMixin {
  static const total = 6;
  final rnd = Random();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  int round = 0;
  int mistakes = 0;
  late _En target;
  List<_Fish> fish = [];
  bool wait = false;

  @override
  void initState() {
    super.initState();
    _newRound();
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.papagan, 'Balık tutalım! Söylediğim şeyi taşıyan balığa dokun.');
      Future.delayed(const Duration(milliseconds: 3500), _ask);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _newRound() {
    final pool = [..._things]..shuffle(rnd);
    final pick = pool.take(4).toList();
    target = pick[rnd.nextInt(4)];
    const cols = [Color(0xFFFF8A65), Color(0xFF4DD0E1), Color(0xFFFFD54F), Color(0xFFBA68C8)];
    fish = [
      for (var i = 0; i < 4; i++)
        _Fish(pick[i], rnd.nextDouble(), 0.12 + i * 0.21, (0.06 + rnd.nextDouble() * 0.05) * (i.isEven ? 1 : -1), cols[i])
    ];
    wait = false;
  }

  void _ask() {
    if (mounted) Voice.sayEn('Catch the ${target.en}!');
  }

  void _tick(Duration t) {
    final dt = (t - _last).inMicroseconds / 1e6;
    _last = t;
    if (dt <= 0 || dt > 0.2) return;
    setState(() {
      for (final f in fish) {
        if (f.caught) continue;
        f.x += f.speed * dt;
        if (f.x > 1.15) f.x = -0.15;
        if (f.x < -0.15) f.x = 1.15;
      }
    });
  }

  Future<void> _tap(_Fish f) async {
    if (wait || f.caught) return;
    if (f.thing == target) {
      wait = true;
      Sfx.play('su');
      setState(() => f.caught = true);
      Voice.say('${target.en}, yani ${target.tr}. Yakaladın!');
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      if (round + 1 >= total) {
        final again = await levelDone(context, id: 'balik', stars: starsFor(mistakes), who: Who.papagan, sticker: 'i_kupa');
        if (mounted) Navigator.pop(context, again);
        return;
      }
      setState(() {
        round++;
        _newRound();
      });
      _ask();
    } else {
      Sfx.play('wrong');
      mistakes++;
      Voice.say('Bu ${f.thing.tr}. İngilizcesi ${f.thing.en}.');
      Timer(const Duration(milliseconds: 2400), _ask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LevelShell(
      title: 'Balık Tut',
      bg: 'bolge_liman',
      round: round,
      total: total,
      child: Column(children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _ask,
          child: Panel(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Pic('k_papagan', height: 60),
              const SizedBox(width: 8),
              Text('Catch the ${target.en}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF6A1B9A))),
              const Icon(Icons.volume_up, color: Colors.black54),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC4FC3F7), Color(0xEE0277BD)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: LayoutBuilder(builder: (_, c) {
              return Stack(children: [
                for (final f in fish)
                  AnimatedPositioned(
                    duration: f.caught ? const Duration(milliseconds: 900) : Duration.zero,
                    curve: Curves.easeOut,
                    left: f.x * c.maxWidth - 60,
                    top: f.caught ? -120 : f.y * c.maxHeight,
                    child: GestureDetector(
                      onTap: () => _tap(f),
                      child: _FishView(f),
                    ),
                  ),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}

class _FishView extends StatelessWidget {
  final _Fish f;
  const _FishView(this.f);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        height: 84,
        child: Stack(alignment: Alignment.center, children: [
          Transform.flip(
            flipX: f.speed < 0,
            child: CustomPaint(size: const Size(120, 84), painter: _FishPainter(f.color)),
          ),
          Text(f.thing.emoji, style: const TextStyle(fontSize: 34)),
        ]),
      );
}

class _FishPainter extends CustomPainter {
  final Color c;
  _FishPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = c;
    canvas.drawOval(Rect.fromLTWH(s.width * 0.12, s.height * 0.1, s.width * 0.7, s.height * 0.8), p);
    final tail = Path()
      ..moveTo(s.width * 0.18, s.height * 0.5)
      ..lineTo(0, s.height * 0.15)
      ..lineTo(0, s.height * 0.85)
      ..close();
    canvas.drawPath(tail, p);
    canvas.drawCircle(Offset(s.width * 0.7, s.height * 0.4), 7, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(s.width * 0.71, s.height * 0.4), 3.5, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
