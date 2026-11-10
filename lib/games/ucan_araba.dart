import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'kit.dart';

class _Cloud {
  final String syl;
  double x;
  final int lane;
  bool hit = false;
  _Cloud(this.syl, this.x, this.lane);
}

/// Uçan Araba: bulutların arasında uç, kelimenin hecelerini sırayla topla.
class UcanAraba extends StatefulWidget {
  const UcanAraba({super.key});

  @override
  State<UcanAraba> createState() => _UcanArabaState();
}

class _UcanArabaState extends State<UcanAraba> with SingleTickerProviderStateMixin {
  static const total = 3;
  static const lanes = 4;
  final rnd = Random();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  late final List<List<String>> rounds;
  int round = 0;
  int got = 0;
  int mistakes = 0;
  double carY = 0.5; // 0..1
  double targetY = 0.5;
  final List<_Cloud> clouds = [];
  double spawn = 0;
  double time = 0;
  bool paused = true;
  late List<String> distract;

  List<String> get word => rounds[round];

  @override
  void initState() {
    super.initState();
    var ws = pictureWords(minSyl: 2);
    if (ws.length < total) ws = [...ws, ...pictureWords()];
    rounds = [for (var i = 0; i < total; i++) ws[i % ws.length]];
    distract = Bank(game.letterGroup, game.step).twoLetter();
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.baykus, 'Arabamız kanatlandı! Yukarı aşağı kaydır, heceleri sırayla topla.', mood: 'gosterir');
      Future.delayed(const Duration(milliseconds: 4000), _start);
    });
  }

  void _start() {
    if (!mounted) return;
    Voice.say('${trCapitalize(word.join())}. İlk hece ${word[0]}.');
    setState(() => paused = false);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration t) {
    final dt = (t - _last).inMicroseconds / 1e6;
    _last = t;
    if (dt <= 0 || dt > 0.1) return;
    time += dt;
    carY += (targetY - carY) * min(1, dt * 8);
    if (paused) {
      setState(() {});
      return;
    }
    spawn -= dt;
    if (spawn <= 0) {
      spawn = 1.25;
      final need = word[got];
      final hasNeed = clouds.any((c) => c.syl == need && !c.hit && c.x > 0.4);
      final s = (!hasNeed && rnd.nextDouble() < 0.6) ? need : distract[rnd.nextInt(distract.length)];
      var lane = rnd.nextInt(lanes);
      if (clouds.isNotEmpty && clouds.last.lane == lane && clouds.last.x > 0.85) lane = (lane + 1) % lanes;
      clouds.add(_Cloud(s, 1.15, lane));
    }
    for (final c in clouds) {
      c.x -= dt * 0.23;
    }
    clouds.removeWhere((c) => c.x < -0.2);
    // çarpışma
    final carLane = (carY * lanes).floor().clamp(0, lanes - 1);
    for (final c in clouds) {
      if (c.hit) continue;
      if (c.lane == carLane && (c.x - 0.18).abs() < 0.08) {
        c.hit = true;
        if (c.syl == word[got]) {
          Sfx.play('coin');
          Voice.say(c.syl);
          got++;
          if (got == word.length) _wordDone();
        } else {
          Sfx.play('pop');
          mistakes++;
        }
      }
    }
    setState(() {});
  }

  Future<void> _wordDone() async {
    paused = true;
    clouds.clear();
    Sfx.play('correct');
    Voice.say('${word.join('-')}. ${trCapitalize(word.join())}!');
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    if (round + 1 >= total) {
      final again = await levelDone(context, id: 'ucan_araba', stars: starsFor(mistakes, ok3: 2, ok2: 5), who: Who.baykus, sticker: 'm_kitap');
      if (mounted) Navigator.pop(context, again);
      return;
    }
    setState(() {
      round++;
      got = 0;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    return LevelShell(
      title: 'Uçan Araba',
      bg: 'bolge_bulut',
      round: round,
      total: total,
      child: Column(children: [
        const SizedBox(height: 6),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emojiFor(word.join()), style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 8),
            for (var i = 0; i < word.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: i < got ? const Color(0xFFC8E6C9) : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: i < got ? SylText(word[i], size: 28) : const Text('  ?  ', style: TextStyle(fontSize: 26)),
              ),
          ]),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            final h = c.maxHeight, w = c.maxWidth;
            final laneH = h / lanes;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => targetY = (d.localPosition.dy / h).clamp(0.02, 0.98),
              onTapDown: (d) => targetY = (d.localPosition.dy / h).clamp(0.02, 0.98),
              child: Stack(children: [
                for (final cl in clouds)
                  Positioned(
                    left: cl.x * w - 55,
                    top: cl.lane * laneH + laneH / 2 - 36,
                    child: AnimatedOpacity(
                      opacity: cl.hit ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: _CloudView(cl.syl),
                    ),
                  ),
                Positioned(
                  left: w * 0.18 - 60,
                  top: carY * h - 45 + sin(time * 4) * 4,
                  child: SizedBox(
                    width: 120,
                    height: 90,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned(left: 20, top: 8, child: Text('🪽', style: TextStyle(fontSize: 34 + sin(time * 14) * 3))),
                      Positioned.fill(
                        child: Transform.flip(flipX: true, child: Pic('arac_${game.selected('body')}')),
                      ),
                    ]),
                  ),
                ),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}

class _CloudView extends StatelessWidget {
  final String syl;
  const _CloudView(this.syl);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        height: 72,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(110, 72), painter: _CloudPainter()),
          SylText(syl, size: 28),
        ]),
      );
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = Colors.white;
    final sh = Paint()..color = const Color(0x33000000);
    for (final o in const [(0.3, 0.55, 0.26), (0.55, 0.42, 0.3), (0.75, 0.58, 0.24), (0.5, 0.66, 0.28)]) {
      canvas.drawCircle(Offset(o.$1 * s.width, o.$2 * s.height + 4), o.$3 * s.width, sh);
    }
    for (final o in const [(0.3, 0.55, 0.26), (0.55, 0.42, 0.3), (0.75, 0.58, 0.24), (0.5, 0.66, 0.28)]) {
      canvas.drawCircle(Offset(o.$1 * s.width, o.$2 * s.height), o.$3 * s.width, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
