import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import 'kit.dart';

const sayiAdi = ['sıfır', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz', 'on'];

// ======================= KÖPRÜ KUR =======================

/// Köprü Kur: Robot Rakam kaç tahta lazım olduğunu söyler, tahtaları say ve köprüyü kur.
class KopruKur extends StatefulWidget {
  const KopruKur({super.key});

  @override
  State<KopruKur> createState() => _KopruKurState();
}

class _KopruKurState extends State<KopruKur> with SingleTickerProviderStateMixin {
  static const total = 5;
  final rnd = Random();
  int round = 0;
  int mistakes = 0;
  int planks = 0;
  int a = 0, b = 0;
  int shake = 0;
  bool crossing = false;
  late final AnimationController car = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  int get need => a + b;
  String get question => b == 0 ? '$a' : '$a + $b';

  @override
  void initState() {
    super.initState();
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.robot, 'Köprü yıkılmış! Tahtaları sayarak köprüyü kuralım.');
      Future.delayed(const Duration(milliseconds: 3500), _ask);
    });
  }

  @override
  void dispose() {
    car.dispose();
    super.dispose();
  }

  void _newRound() {
    planks = 0;
    if (round < 3) {
      a = 2 + rnd.nextInt(round == 0 ? 3 : 6);
      b = 0;
    } else {
      a = 1 + rnd.nextInt(4);
      b = 1 + rnd.nextInt(4);
    }
  }

  void _ask() {
    if (!mounted) return;
    Voice.say(b == 0 ? '${sayiAdi[a]} tahta lazım.' : '${sayiAdi[a]} artı ${sayiAdi[b]} tahta lazım. Kaç eder?');
  }

  void _add() {
    if (crossing || planks >= 9) return;
    Sfx.play('tok');
    setState(() => planks++);
    Voice.say(sayiAdi[planks]);
  }

  void _remove() {
    if (crossing || planks == 0) return;
    Sfx.play('pop');
    setState(() => planks--);
  }

  Future<void> _go() async {
    if (crossing) return;
    if (planks == need) {
      Sfx.play('correct');
      Voice.say(b == 0 ? 'Evet, ${sayiAdi[need]} tahta!' : '${sayiAdi[a]} artı ${sayiAdi[b]}, ${sayiAdi[need]} eder!');
      setState(() => crossing = true);
      Sfx.play('rev');
      await car.forward(from: 0);
      if (!mounted) return;
      if (round + 1 >= total) {
        final again = await levelDone(context, id: 'kopru_kur', stars: starsFor(mistakes), who: Who.robot, sticker: 'k_robot');
        if (mounted) Navigator.pop(context, again);
        return;
      }
      setState(() {
        round++;
        crossing = false;
        car.value = 0;
        _newRound();
      });
      _ask();
    } else {
      Sfx.play('wrong');
      setState(() {
        mistakes++;
        shake++;
      });
      Voice.say('Köprüde ${sayiAdi[planks]} tahta var. ${planks < need ? 'Biraz daha ekle.' : 'Fazla oldu, biraz çıkar.'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return LevelShell(
      title: 'Köprü Kur',
      bg: 'bolge_sayi',
      round: round,
      total: total,
      child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _ask,
            child: Panel(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Pic('k_robot', height: 70),
                const SizedBox(width: 10),
                Text(question, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
                const SizedBox(width: 8),
                const Text('🪵', style: TextStyle(fontSize: 40)),
              ]),
            ),
          ),
          const Spacer(),
          Shake(
            trigger: shake,
            child: SizedBox(
              width: w,
              height: w * 0.7,
              child: AnimatedBuilder(
                animation: car,
                builder: (_, __) => CustomPaint(
                  painter: _BridgePainter(planks, crossing ? car.value : 0, ok: crossing),
                  child: Stack(children: [
                    Positioned(
                      left: -w * 0.05 + car.value * w * 0.85,
                      top: w * 0.7 * 0.42 - 80 - (crossing ? sin(car.value * pi * 8).abs() * 4 : 0),
                      child: Transform.flip(flipX: true, child: Pic('arac_${game.selected('body')}', width: 110)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceTile(
                    color: const Color(0xFFD7A15A),
                    onTap: _add,
                    child: const Text('🪵 Tahta koy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                ChoiceTile(size: 64, color: const Color(0xFFFFCDD2), onTap: _remove, child: const Icon(Icons.undo, size: 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceTile(
                    color: const Color(0xFF81C784),
                    onTap: _go,
                    child: const Text('Geç! 🚗', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BridgePainter extends CustomPainter {
  final int planks;
  final double t;
  final bool ok;
  _BridgePainter(this.planks, this.t, {required this.ok});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint();
    final top = s.height * 0.42;
    final gapL = s.width * 0.26, gapR = s.width * 0.74;
    // nehir
    p.color = const Color(0xFF4FC3F7);
    canvas.drawRRect(RRect.fromLTRBR(gapL - 4, s.height * 0.8, gapR + 4, s.height, const Radius.circular(10)), p);
    p.color = const Color(0x88FFFFFF);
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(Offset(gapL + 20 + i * 40, s.height * 0.88), Offset(gapL + 40 + i * 40, s.height * 0.88), p..strokeWidth = 3);
    }
    // kayalıklar
    void cliff(double x0, double x1, bool left) {
      final path = Path()
        ..moveTo(x0, top)
        ..lineTo(x1, top)
        ..lineTo(left ? x1 - 14 : x1, s.height)
        ..lineTo(left ? x0 : x0 + 14, s.height)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFD9824B));
      canvas.drawRect(Rect.fromLTRB(x0, top - 8, x1, top + 4), Paint()..color = const Color(0xFF7CB342));
      final dark = Paint()..color = const Color(0x33000000);
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(Offset(x0 + 10, top + 30 + i * 28), Offset(x1 - 10, top + 40 + i * 28), dark..strokeWidth = 3);
      }
    }

    cliff(0, gapL, true);
    cliff(gapR, s.width, false);
    // tahtalar
    final pw = (gapR - gapL) / 9;
    for (var i = 0; i < planks; i++) {
      final x = gapL + i * pw;
      final r = RRect.fromLTRBR(x + 1, top - 6, x + pw - 1, top + 10, const Radius.circular(3));
      canvas.drawRRect(r, Paint()..color = i.isEven ? const Color(0xFFC68642) : const Color(0xFFB5763A));
      canvas.drawRRect(r, Paint()
        ..color = const Color(0xFF6D4C2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + pw / 2 - tp.width / 2, top - 5));
    }
    // ip korkuluk
    canvas.drawLine(Offset(gapL, top - 30), Offset(gapR, top - 30), Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _BridgePainter old) => old.planks != planks || old.t != t;
}

// ======================= TÜNEL KAZISI =======================

class _Q {
  final String text;
  final String speech;
  final int answer;
  const _Q(this.text, this.speech, this.answer);
}

/// Tünel Kazısı: doğru sayının yazdığı kayayı kır, tünel açılsın.
class TunelKazisi extends StatefulWidget {
  const TunelKazisi({super.key});

  @override
  State<TunelKazisi> createState() => _TunelKazisiState();
}

class _TunelKazisiState extends State<TunelKazisi> {
  static const total = 6;
  static const _things = ['🍎', '⭐', '🐟', '🎈', '🚗', '🌷'];
  final rnd = Random();
  int round = 0;
  int mistakes = 0;
  int shake = 0;
  int? broken;
  late _Q q;
  late List<int> rocks;

  @override
  void initState() {
    super.initState();
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.robot, 'Dağın içinden tünel açalım! Doğru sayının yazdığı kayayı kır.');
      Future.delayed(const Duration(milliseconds: 3800), _ask);
    });
  }

  void _newRound() {
    broken = null;
    final kind = round % 3;
    if (kind == 0) {
      final n = 2 + rnd.nextInt(7);
      final t = _things[rnd.nextInt(_things.length)];
      q = _Q(List.filled(n, t).join(' '), 'Kaç tane var? Say bakalım.', n);
    } else if (kind == 1) {
      final n = 1 + rnd.nextInt(8);
      q = _Q('$n → ?', '${sayiAdi[n]} sayısından sonra hangi sayı gelir?', n + 1);
    } else {
      final x = 3 + rnd.nextInt(5), y = 1 + rnd.nextInt(min(3, x - 1));
      final t = _things[rnd.nextInt(_things.length)];
      q = _Q('${List.filled(x, t).join(' ')}\n$x − $y = ?', '${sayiAdi[x]} tane vardı, ${sayiAdi[y]} tanesi gitti. Kaç tane kaldı?', x - y);
    }
    final set = <int>{q.answer};
    while (set.length < 4) {
      final v = max(1, q.answer + rnd.nextInt(5) - 2);
      if (v <= 10) set.add(v);
    }
    rocks = set.toList()..shuffle(rnd);
  }

  void _ask() {
    if (mounted) Voice.say(q.speech);
  }

  Future<void> _tap(int i) async {
    if (broken != null) return;
    if (rocks[i] == q.answer) {
      Sfx.play('kir');
      setState(() => broken = i);
      Voice.say('${sayiAdi[q.answer]}! Kaya kırıldı!');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      if (round + 1 >= total) {
        final again = await levelDone(context, id: 'tunel', stars: starsFor(mistakes), who: Who.robot, sticker: 'd_tas');
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
      Voice.say('Bu ${sayiAdi[rocks[i]]}. Bir daha dene.');
      setState(() {
        mistakes++;
        shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LevelShell(
      title: 'Tünel Kazısı',
      bg: 'bolge_sayi',
      round: round,
      total: total,
      child: Column(
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _ask,
            child: Panel(
              padding: const EdgeInsets.all(16),
              child: Text(q.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1565C0), height: 1.3)),
            ),
          ),
          const Spacer(),
          Shake(
            trigger: shake,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: [
                for (var i = 0; i < rocks.length; i++)
                  Bouncy(
                    onTap: () => _tap(i),
                    child: AnimatedOpacity(
                      opacity: broken == i ? 0 : 1,
                      duration: const Duration(milliseconds: 900),
                      child: AnimatedScale(
                        scale: broken == i ? 1.5 : 1,
                        duration: const Duration(milliseconds: 900),
                        child: SizedBox(
                          width: 140,
                          height: 120,
                          child: Stack(alignment: Alignment.center, children: [
                            const Pic('d_tas', width: 140, height: 120),
                            Text('${rocks[i]}',
                                style: const TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2))],
                                )),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
