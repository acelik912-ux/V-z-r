import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art.dart';
import '../car3d/car_model.dart';
import '../car3d/renderer.dart';
import '../catalog.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'result.dart';

class _Gate {
  final double d;
  final List<String> opts;
  final int answer;
  bool announced = false;
  bool done = false;
  _Gate(this.d, this.opts, this.answer);
  String get target => opts[answer];
}

class _Coin {
  final double d;
  final int lane;
  bool taken = false;
  _Coin(this.d, this.lane);
}

class _Rival {
  final String name;
  final double factor;
  final CarConfig spec;
  final int lane;
  double dist;
  _Rival(this.name, this.factor, this.spec, this.lane, this.dist);
}

class _Helper {
  final double d;
  bool helped = false;
  _Helper(this.d);
}

class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with SingleTickerProviderStateMixin {
  static const double lapLen = 8000;
  static const int laps = 3;
  static const double baseSpeed = 220;
  double get total => lapLen * laps;

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final rnd = Random();

  double dist = 0;
  double lanePos = 1;
  int targetLane = 1;
  double turbo = 0;
  double helping = 0;
  double countdown = 0;
  bool started = false;
  bool finished = false;

  final gates = <_Gate>[];
  final coinList = <_Coin>[];
  final rivals = <_Rival>[];
  final helpers = <_Helper>[];

  int correct = 0;
  int wrong = 0;
  int coinCount = 0;
  int helped = 0;
  String? currentTarget;
  String flash = '';
  double flashT = 0;

  @override
  void initState() {
    super.initState();
    game.setInRace(true);
    Music.hold();
    Img.load(_raceImgs).then((_) {
      if (mounted) setState(() {});
    });
    final bank = Bank(game.letterGroup, game.step);
    for (double d = 1200; d < total - 600; d += 1400) {
      final opts = bank.gate(3);
      if (opts.length < 3) continue;
      gates.add(_Gate(d, opts, rnd.nextInt(3)));
    }
    // 5 grup x 4 jeton = 20 jeton (20'ye kadar sayma)
    for (var g = 0; g < 5; g++) {
      final start = 1900.0 + g * 4600;
      final lane = rnd.nextInt(3);
      for (var k = 0; k < 4; k++) {
        coinList.add(_Coin(start + k * 70, lane));
      }
    }
    for (var l = 0; l < laps; l++) {
      helpers.add(_Helper(l * lapLen + lapLen * 0.5 + 300));
    }
    const factors = [0.93, 1.0, 1.08];
    const lanes = [0, 2, 1];
    const starts = [0.0, 0.0, -160.0];
    for (var i = 0; i < 3; i++) {
      rivals.add(_Rival(game.rivalNames[i], factors[i], rivalConfigs[i], lanes[i], starts[i]));
    }
    _ticker = createTicker(_tick)..start();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !started) {
        Voice.say('Hece kapısında söylediğim heceyi bul ve oradan geç. Ekranın soluna dokunursan sola, sağına dokunursan sağa gidersin.');
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    Sfx.engineStop();
    Music.release();
    if (!finished) game.setInRace(false);
    super.dispose();
  }

  void _tick(Duration now) {
    var dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt > 0.05) dt = 0.05;
    if (dt < 0) dt = 0;
    _update(dt);
    if (mounted) setState(() {});
  }

  int get lane => lanePos.round();
  int get lap => min(laps, (dist / lapLen).floor() + 1);

  void _update(double dt) {
    if (flashT > 0) flashT -= dt;
    final diff = targetLane - lanePos;
    final stepAmt = 7 * dt;
    lanePos = diff.abs() <= stepAmt ? targetLane.toDouble() : lanePos + stepAmt * diff.sign;

    if (countdown > 0) {
      final before = _countText();
      countdown -= dt;
      if (countdown <= 0) {
        countdown = 0;
        started = true;
        Sfx.play('go');
        Sfx.engineStart();
      } else if (_countText() != before) {
        Sfx.play(_countText() == 'Haydi!' ? 'go' : 'beep');
      }
      return;
    }
    if (!started || finished) return;

    final speed = helping > 0 ? 0.0 : baseSpeed * (turbo > 0 ? 1.6 : 1.0);
    if (helping > 0) helping -= dt;
    if (turbo > 0) turbo -= dt;
    dist += speed * dt;
    Sfx.engineRate(helping > 0 ? 0.7 : (turbo > 0 ? 1.45 : 1.0));

    for (final r in rivals) {
      r.dist += baseSpeed * r.factor * dt * (1 + 0.06 * sin(r.dist / 600 + r.lane));
    }

    for (final g in gates) {
      if (!g.announced && g.d - dist < 700) {
        g.announced = true;
        currentTarget = g.target;
        Voice.say(g.target);
      }
      if (!g.done && dist >= g.d) {
        g.done = true;
        currentTarget = null;
        if (lane == g.answer) {
          correct++;
          turbo = 3;
          flash = 'Aferin!';
          flashT = 1.2;
          Voice.say('Aferin! ${g.target}');
          Sfx.play('correct');
          Sfx.play('turbo', volume: 0.7);
          game.recordSyllable(g.target, true);
        } else {
          wrong++;
          flash = g.target;
          flashT = 1.6;
          Voice.say('Bu ${g.target} idi.');
          Sfx.play('wrong', volume: 0.6);
          game.recordSyllable(g.target, false);
        }
      }
    }

    for (final c in coinList) {
      if (!c.taken && c.lane == lane && (dist - c.d).abs() < 35) {
        c.taken = true;
        coinCount++;
        Sfx.play('coin', volume: 0.6);
      }
    }

    if (dist >= total) {
      finished = true;
      _ticker.stop();
      Sfx.engineStop();
      Sfx.play('finish');
      final rank = 1 + rivals.where((r) => r.dist > dist).length;
      game.save();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              rank: rank,
              correct: correct,
              gates: gates.length,
              coins: coinCount,
              helped: helped,
            ),
          ),
        );
      });
    }
  }

  void _start() {
    setState(() => countdown = 3.6);
    Voice.say('Bismillah! Üç, iki, bir, haydi!');
  }

  void _steer(int dir) {
    if (!started || finished) return;
    targetLane = (targetLane + dir).clamp(0, 2).toInt();
  }

  _Helper? _activeHelper() {
    if (!started || finished) return null;
    for (final h in helpers) {
      final rel = h.d - dist;
      if (!h.helped && rel < 520 && rel > -140) return h;
    }
    return null;
  }

  void _help(_Helper h) {
    setState(() {
      h.helped = true;
      helped++;
      helping = 2.0;
      flash = '❤️ İyilik!';
      flashT = 2.0;
    });
    Voice.say('Durup yardım ettin. Allah razı olsun!');
    Sfx.play('heart');
  }

  String _countText() {
    if (countdown > 2.7) return '3';
    if (countdown > 1.8) return '2';
    if (countdown > 0.9) return '1';
    return 'Haydi!';
  }

  Widget _bigText(String t, {Color color = Colors.white}) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: Colors.black.withAlpha(110), borderRadius: BorderRadius.circular(24)),
        child: Text(t, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color)),
      ),
    );
  }

  Widget _dot(Color c, String name, {bool big = false}) {
    final s = big ? 30.0 : 24.0;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Text(
        name.isEmpty ? '?' : name.substring(0, 1),
        style: TextStyle(fontSize: big ? 15 : 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _progress() {
    return LayoutBuilder(builder: (context, cons) {
      final bw = cons.maxWidth;
      double x(double d) => (d / total).clamp(0.0, 1.0).toDouble() * (bw - 30);
      return SizedBox(
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Positioned(right: -4, top: 2, child: Icon(Icons.flag, size: 28, color: Colors.black87)),
            for (final r in rivals) Positioned(left: x(r.dist), top: 5, child: _dot(Color(r.spec.paint), r.name)),
            Positioned(left: x(dist), top: 2, child: _dot(Color(game.config.paint), game.driverName, big: true)),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final helper = _activeHelper();
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _steer(d.localPosition.dx < MediaQuery.of(context).size.width / 2 ? -1 : 1),
              child: CustomPaint(painter: _RacePainter(this)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      RoundIcon(Icons.close, () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      Expanded(child: _progress()),
                      const SizedBox(width: 12),
                      Pill('Tur $lap/$laps'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Pill('⭐ $correct'),
                      const SizedBox(width: 8),
                      Pill('🪙 $coinCount'),
                      const Spacer(),
                      if (currentTarget != null) RoundIcon(Icons.volume_up, () => Voice.say(currentTarget!)),
                      const SizedBox(width: 8),
                      RoundIcon(Icons.campaign, () => Sfx.horn(game.config.horn), color: const Color(0xFFFFD54F)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (flashT > 0) Center(child: _bigText(flash)),
          if (countdown > 0) Center(child: _bigText(_countText(), color: Colors.yellowAccent)),
          if (!started && countdown <= 0)
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: SizedBox(
                height: 76,
                child: FilledButton(
                  onPressed: _start,
                  child: const Text('Bismillah, başla!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          if (helper != null)
            Positioned(
              left: 16,
              bottom: 40,
              child: SizedBox(
                height: 64,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.pink),
                  onPressed: () => _help(helper),
                  icon: const Icon(Icons.favorite, size: 28),
                  label: const Text('Yardım et', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _raceImgs = ['doku_cimen', 'd_agac', 'd_lale', 'd_cali', 'd_cam', 'd_meyve', 'd_saman', 'd_pembe', 'd_tas', 'd_cit', 'bitis_taki', 'i_jeton'];

class _RacePainter extends CustomPainter {
  final _RaceScreenState s;
  _RacePainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadW = min(w * 0.78, 440.0);
    final left = (w - roadW) / 2;
    final laneW = roadW / 3;
    double laneX(double l) => left + laneW * (l + 0.5);
    final carY = h * 0.72;
    double yOf(double d) => carY - (d - s.dist);
    final carW = laneW * 0.55;
    final carH = carW * 1.75;

    // Çimen
    final grass = Img.get('doku_cimen');
    if (grass != null) {
      const tile = 220.0;
      final m = Matrix4.identity()
        ..translate(0.0, s.dist % tile)
        ..scale(tile / grass.width);
      canvas.drawRect(Offset.zero & size, Paint()..shader = ImageShader(grass, TileMode.repeated, TileMode.repeated, m.storage));
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF7CB342));
    }

    // Yol kenarındaki süsler
    if (left > 24) {
      const deco = ['d_agac', 'd_lale', 'd_cali', 'd_cam', 'd_meyve', 'd_saman', 'd_pembe', 'd_tas', 'd_cit', 'd_lale'];
      final sw = min(left * 0.9, 96.0);
      for (var i = 0; i < 12; i++) {
        final y = ((i * 151.0 + s.dist) % (h + 240)) - 120;
        final x = i.isEven ? left * 0.5 : w - left * 0.5;
        final name = deco[(i * 7) % deco.length];
        final big = name == 'd_agac' || name == 'd_cam' || name == 'd_pembe';
        final sz = big ? sw : sw * 0.7;
        Img.draw(canvas, name, Rect.fromCenter(center: Offset(x, y), width: sz, height: sz * 1.1));
      }
    }

    // Yol
    canvas.drawRect(Rect.fromLTWH(left, 0, roadW, h), Paint()..color = const Color(0xFF546E7A));
    final off = s.dist % 60;
    for (double y = off - 60; y < h; y += 60) {
      final red = Paint()..color = const Color(0xFFE53935);
      final white = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(left - 8, y, 8, 30), red);
      canvas.drawRect(Rect.fromLTWH(left - 8, y + 30, 8, 30), white);
      canvas.drawRect(Rect.fromLTWH(left + roadW, y, 8, 30), red);
      canvas.drawRect(Rect.fromLTWH(left + roadW, y + 30, 8, 30), white);
    }
    final dash = Paint()..color = Colors.white70;
    for (var j = 1; j <= 2; j++) {
      final x = left + laneW * j;
      for (double y = (s.dist % 80) - 80; y < h; y += 80) {
        canvas.drawRect(Rect.fromLTWH(x - 3, y, 6, 40), dash);
      }
    }

    // Başlangıç ve bitiş çizgisi
    void checker(double y) {
      if (y < -40 || y > h + 40) return;
      const sq = 20.0;
      for (var row = 0; row < 2; row++) {
        for (double x = left, k = 0; x < left + roadW; x += sq, k++) {
          final black = (k + row) % 2 == 0;
          canvas.drawRect(Rect.fromLTWH(x, y + row * sq, min(sq, left + roadW - x), sq),
              Paint()..color = black ? Colors.black : Colors.white);
        }
      }
    }

    checker(yOf(0) + 30);
    checker(yOf(s.total) - 40);
    final fy = yOf(s.total) - 20;
    if (fy > -300 && fy < h + 40) {
      final aw = roadW * 1.25;
      Img.draw(canvas, 'bitis_taki', Rect.fromLTWH(w / 2 - aw / 2, fy - aw * 0.85, aw, aw * 0.9));
    }

    // Jetonlar
    for (final c in s.coinList) {
      if (c.taken) continue;
      final y = yOf(c.d);
      if (y < -40 || y > h + 40) continue;
      final o = Offset(laneX(c.lane.toDouble()), y);
      if (Img.get('i_jeton') != null) {
        Img.draw(canvas, 'i_jeton', Rect.fromCenter(center: o, width: 34, height: 34));
      } else {
        canvas.drawCircle(o, 15, Paint()..color = const Color(0xFFFFA000));
        canvas.drawCircle(o, 11, Paint()..color = const Color(0xFFFFD54F));
      }
    }

    // Hece kapıları
    for (final g in s.gates) {
      final y = yOf(g.d);
      if (y < -120 || y > h + 80) continue;
      final post = Paint()..color = const Color(0xFF5D4037);
      canvas.drawRect(Rect.fromLTWH(left - 14, y - 45, 10, 90), post);
      canvas.drawRect(Rect.fromLTWH(left + roadW + 4, y - 45, 10, 90), post);
      canvas.drawRect(Rect.fromLTWH(left - 14, y - 48, roadW + 28, 8), post);
      for (var k = 0; k < 3; k++) {
        final rect = Rect.fromCenter(center: Offset(laneX(k.toDouble()), y), width: laneW * 0.86, height: 72);
        final fill = g.done && k == g.answer ? const Color(0xFFC8E6C9) : Colors.white;
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
        canvas.drawRRect(rr, Paint()..color = fill);
        canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = const Color(0xFF5D4037));
        var fs = 40.0;
        var tp = TextPainter(text: sylSpan(g.opts[k], fs), textDirection: TextDirection.ltr)..layout();
        final maxW = rect.width - 12;
        if (tp.width > maxW) {
          fs = fs * maxW / tp.width;
          tp = TextPainter(text: sylSpan(g.opts[k], fs), textDirection: TextDirection.ltr)..layout();
        }
        tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
      }
    }

    // Arızalı arabalar (yardım)
    for (final hp in s.helpers) {
      final y = yOf(hp.d);
      if (y < -120 || y > h + 80) continue;
      final cx = max(left * 0.5, carW * 0.45);
      final sc = min(carW / 1.9, max(left * 0.9, 20.0) / 1.9);
      paintCarCached(canvas, CarConfig(body: 4, color: hp.helped ? 8 : 10, finish: 2), Offset(cx, y), sc, pi, 0.95);
      if (!hp.helped) {
        final smoke = Paint()..color = Colors.black.withAlpha(60);
        canvas.drawCircle(Offset(cx, y - sc * 2.2), 9, smoke);
        canvas.drawCircle(Offset(cx + 6, y - sc * 2.2 - 12), 12, smoke);
        canvas.drawCircle(Offset(cx - 4, y - sc * 2.2 - 26), 14, smoke);
      } else {
        final tp = TextPainter(
            text: const TextSpan(text: '❤️', style: TextStyle(fontSize: 22)), textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, y - sc * 2.2 - 24));
      }
    }

    // Rakipler
    for (final r in s.rivals) {
      final y = carY - (r.dist - s.dist);
      if (y < -carH || y > h + carH) continue;
      final x = laneX(r.lane.toDouble());
      paintCarCached(canvas, r.spec, Offset(x, y), carW / 1.9, pi, 0.95);
      final tp = TextPainter(
        text: TextSpan(
          text: r.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, backgroundColor: Colors.black45),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - carH / 2 - 18));
    }

    // Oyuncu
    final px = laneX(s.lanePos);
    final sc = carW / 1.9;
    final rearY = carY + sc * 2.0;
    if (s.turbo > 0) {
      final flame = Path()
        ..moveTo(px - carW * 0.3, rearY - 4)
        ..lineTo(px, rearY + 30 + 8 * sin(s.dist / 20))
        ..lineTo(px + carW * 0.3, rearY - 4)
        ..close();
      canvas.drawPath(flame, Paint()..color = const Color(0xFFFF6D00));
      final inner = Path()
        ..moveTo(px - carW * 0.15, rearY - 4)
        ..lineTo(px, rearY + 16)
        ..lineTo(px + carW * 0.15, rearY - 4)
        ..close();
      canvas.drawPath(inner, Paint()..color = const Color(0xFFFFEA00));
    }
    // şerit değiştirirken hafif yatma
    final lean = (s.targetLane - s.lanePos).clamp(-1.0, 1.0).toDouble() * 0.25;
    paintCarCached(canvas, game.config, Offset(px, carY), sc, pi - lean, 0.95, lightsOn: s.turbo > 0);
  }

  @override
  bool shouldRepaint(_RacePainter oldDelegate) => true;
}
