import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../car3d/car_view.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'kit.dart';

class _Step {
  final String tool;
  final String emoji;
  final String say;
  final String sfx;
  const _Step(this.tool, this.emoji, this.say, this.sfx);
}

const _steps = [
  _Step('su', '🚿', 'Önce arabayı suyla ıslat.', 'su'),
  _Step('köpük', '🫧', 'Şimdi köpük sür.', 'kopuk'),
  _Step('fırça', '🪥', 'Fırçayla çamurları ov.', 'spray'),
  _Step('havlu', '🧺', 'Son olarak havluyla kurula.', 'pop'),
];

/// Araba Yıkama: doğru aleti oku, seç, parmağınla arabayı temizle.
class ArabaYikama extends StatefulWidget {
  const ArabaYikama({super.key});

  @override
  State<ArabaYikama> createState() => _ArabaYikamaState();
}

class _ArabaYikamaState extends State<ArabaYikama> {
  final rnd = Random();
  int step = 0;
  bool picked = false;
  int mistakes = 0;
  int shake = 0;
  final Set<int> touched = {};
  final List<Offset> foam = [];
  final List<Offset> drops = [];
  late final List<List<double>> mud = [
    for (var i = 0; i < 9; i++) [0.12 + rnd.nextDouble() * 0.76, 0.3 + rnd.nextDouble() * 0.5, 0.05 + rnd.nextDouble() * 0.05, 1.0]
  ];
  late List<int> options;
  int _lastSfx = 0;
  bool sparkle = false;

  @override
  void initState() {
    super.initState();
    _newOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Arabamız çamur olmuş! Haydi yıkayalım. Temizlik imandandır.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 4500), _ask);
    });
  }

  void _newOptions() {
    options = [0, 1, 2, 3]..shuffle(rnd);
  }

  void _ask() {
    if (!mounted || step >= _steps.length) return;
    Voice.say('${_steps[step].say} ${trCapitalize(_steps[step].tool)} yazanı bul.');
  }

  void _pick(int i) {
    if (picked) return;
    if (i == step) {
      Sfx.play('correct');
      Voice.say('${_steps[i].tool}. Şimdi parmağınla arabanın üstünü ov.');
      setState(() {
        picked = true;
        touched.clear();
      });
    } else {
      Sfx.play('wrong');
      Voice.say('Bu ${_steps[i].tool}. Bize ${_steps[step].tool} lazım.');
      setState(() {
        mistakes++;
        shake++;
      });
    }
  }

  void _rub(Offset p, Size s) {
    if (!picked || step >= _steps.length) return;
    final rx = (p.dx / s.width).clamp(0.0, 0.999), ry = (p.dy / s.height).clamp(0.0, 0.999);
    final cell = (ry * 5).floor() * 8 + (rx * 8).floor();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSfx > 450) {
      _lastSfx = now;
      Sfx.play(_steps[step].sfx, volume: 0.5);
    }
    setState(() {
      touched.add(cell);
      final rel = Offset(rx, ry);
      switch (step) {
        case 0:
          if (drops.length < 160) drops.add(rel);
        case 1:
          if (foam.length < 220) foam.add(rel);
        case 2:
          for (final m in mud) {
            if ((Offset(m[0], m[1]) - rel).distance < m[2] + 0.07) m[3] = max(0, m[3] - 0.12);
          }
        case 3:
          foam.removeWhere((f) => (f - rel).distance < 0.09);
          drops.removeWhere((f) => (f - rel).distance < 0.09);
      }
    });
    final need = step == 2 ? mud.every((m) => m[3] <= 0.05) : touched.length >= 24;
    if (need) _next();
  }

  Future<void> _next() async {
    picked = false;
    Sfx.play('correct');
    setState(() => step++);
    if (step >= _steps.length) {
      setState(() {
        foam.clear();
        drops.clear();
        sparkle = true;
      });
      Sfx.play('unlock');
      Voice.say('Pırıl pırıl oldu!');
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      final again = await levelDone(context, id: 'araba_yikama', stars: starsFor(mistakes, ok3: 0, ok2: 2), who: Who.tamirci, sticker: 'd_saman');
      if (mounted) Navigator.pop(context, again);
      return;
    }
    _newOptions();
    await Future.delayed(const Duration(milliseconds: 500));
    _ask();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final carSize = Size(w * 0.92, w * 0.6);
    return LevelShell(
      title: 'Araba Yıkama',
      bg: 'garaj_gunduz',
      round: step,
      total: _steps.length,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              step < _steps.length ? (picked ? 'Parmağınla ov!' : 'Hangi alet?') : 'Pırıl pırıl!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onPanStart: (d) => _rub(d.localPosition, carSize),
            onPanUpdate: (d) => _rub(d.localPosition, carSize),
            child: SizedBox(
              width: carSize.width,
              height: carSize.height,
              child: Stack(
                children: [
                  Positioned.fill(child: CarView(game.config, width: carSize.width)),
                  Positioned.fill(child: CustomPaint(painter: _DirtPainter(mud, foam, drops, sparkle))),
                  if (picked && step < _steps.length)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Text(_steps[step].emoji, style: const TextStyle(fontSize: 40)),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (step < _steps.length)
            AnimatedOpacity(
              opacity: picked ? 0.25 : 1,
              duration: const Duration(milliseconds: 250),
              child: Shake(
                trigger: shake,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final i in options)
                        ChoiceTile(
                          size: 80,
                          color: const Color(0xFFB3E5FC),
                          onTap: () => _pick(i),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_steps[i].emoji, style: const TextStyle(fontSize: 30)),
                            SylText(_steps[i].tool, size: 26),
                          ]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirtPainter extends CustomPainter {
  final List<List<double>> mud;
  final List<Offset> foam;
  final List<Offset> drops;
  final bool sparkle;
  _DirtPainter(this.mud, this.foam, this.drops, this.sparkle);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint();
    for (final m in mud) {
      if (m[3] <= 0.02) continue;
      p.color = const Color(0xFF6D4C2F).withAlpha((m[3] * 200).toInt());
      final c = Offset(m[0] * s.width, m[1] * s.height);
      final r = m[2] * s.width;
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c + Offset(r * 0.8, r * 0.3), r * 0.55, p);
      canvas.drawCircle(c + Offset(-r * 0.6, r * 0.5), r * 0.45, p);
    }
    p.color = const Color(0xAA4FC3F7);
    for (final d in drops) {
      canvas.drawOval(Rect.fromCenter(center: Offset(d.dx * s.width, d.dy * s.height), width: 7, height: 10), p);
    }
    for (var i = 0; i < foam.length; i++) {
      final f = foam[i];
      final c = Offset(f.dx * s.width, f.dy * s.height);
      p.color = const Color(0xE6FFFFFF);
      canvas.drawCircle(c, 9 + (i % 4) * 3, p);
      p.color = const Color(0x55B3E5FC);
      canvas.drawCircle(c + const Offset(-2, -2), 3, p);
    }
    if (sparkle) {
      p.color = Colors.white;
      for (final o in const [Offset(0.2, 0.35), Offset(0.55, 0.3), Offset(0.8, 0.5), Offset(0.4, 0.6)]) {
        final c = Offset(o.dx * s.width, o.dy * s.height);
        final path = Path()
          ..moveTo(c.dx, c.dy - 16)
          ..lineTo(c.dx + 4, c.dy - 4)
          ..lineTo(c.dx + 16, c.dy)
          ..lineTo(c.dx + 4, c.dy + 4)
          ..lineTo(c.dx, c.dy + 16)
          ..lineTo(c.dx - 4, c.dy + 4)
          ..lineTo(c.dx - 16, c.dy)
          ..lineTo(c.dx - 4, c.dy - 4)
          ..close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
