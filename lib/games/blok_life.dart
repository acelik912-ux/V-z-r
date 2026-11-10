import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'blok_char.dart';
import 'kit.dart';

// ======================= HAYVANLAR =======================

class AnimalKind {
  final String id;
  final List<String> syl; // adının heceleri (tek heceliyse harfler)
  final String emoji;
  final double speed;
  final String gift; // dost olunca verdiği şey
  const AnimalKind(this.id, this.syl, this.emoji, this.speed, this.gift);
  String get name => syl.join();
}

const animalKinds = [
  AnimalKind('inek', ['i', 'nek'], '🐄', 1.0, 'süt 🥛'),
  AnimalKind('koyun', ['ko', 'yun'], '🐑', 1.0, 'yün 🧶'),
  AnimalKind('tavuk', ['ta', 'vuk'], '🐔', 1.4, 'yumurta 🥚'),
  AnimalKind('kedi', ['ke', 'di'], '🐱', 1.6, 'mırmır 💛'),
  AnimalKind('kopek', ['kö', 'pek'], '🐶', 1.8, 'sevgi 💛'),
  AnimalKind('at', ['a', 't'], '🐴', 2.2, 'gezinti 🐎'),
];

class Animal {
  final AnimalKind kind;
  double x, y, z, facing = 0, walk = 0, timer = 0;
  (double, double)? target;
  bool friend;
  Animal(this.kind, this.x, this.y, this.z, {this.friend = false});
}

AnimalKind kindById(String id) => animalKinds.firstWhere((k) => k.id == id, orElse: () => animalKinds[0]);

ABox _b(double cx, double cy, double cz, double hx, double hy, double hz, Color c, {double pz = 0, double a = 0, bool face = false}) =>
    ABox(cx, cy, cz, hx, hy, hz, c, pivotZ: pz, angle: a, face: face);

/// Hayvanın kutuları (yerel: y ileri, ayaklar z=0)
List<ABox> animalBoxes(String id, double walk) {
  final l = sin(walk) * 0.5;
  switch (id) {
    case 'inek':
      const w = Color(0xFFF5F5F5), k = Color(0xFF263238), p = Color(0xFFF8BBD0);
      return [
        for (final s in const [(-0.18, 0.32, 1.0), (0.18, 0.32, -1.0), (-0.18, -0.32, -1.0), (0.18, -0.32, 1.0)])
          _b(s.$1, s.$2, 0.25, 0.08, 0.08, 0.25, w, pz: 0.5, a: l * s.$3),
        _b(0, 0, 0.75, 0.28, 0.5, 0.25, w),
        _b(0.285, 0.1, 0.8, 0.01, 0.18, 0.12, k),
        _b(-0.285, -0.15, 0.75, 0.01, 0.15, 0.1, k),
        _b(0, 0.6, 0.95, 0.2, 0.17, 0.18, w, face: true),
        _b(0, 0.78, 0.86, 0.13, 0.03, 0.07, p),
        _b(-0.16, 0.55, 1.15, 0.04, 0.04, 0.06, const Color(0xFFBCAAA4)),
        _b(0.16, 0.55, 1.15, 0.04, 0.04, 0.06, const Color(0xFFBCAAA4)),
      ];
    case 'koyun':
      const w = Color(0xFFFAFAFA), g = Color(0xFF9E9E9E);
      return [
        for (final s in const [(-0.15, 0.25, 1.0), (0.15, 0.25, -1.0), (-0.15, -0.25, -1.0), (0.15, -0.25, 1.0)])
          _b(s.$1, s.$2, 0.18, 0.06, 0.06, 0.18, g, pz: 0.36, a: l * s.$3),
        _b(0, 0, 0.6, 0.3, 0.42, 0.25, w),
        _b(0, 0.48, 0.75, 0.15, 0.14, 0.15, g, face: true),
        _b(0, 0.44, 0.92, 0.17, 0.12, 0.05, w),
      ];
    case 'tavuk':
      const w = Color(0xFFFFFFFF), r = Color(0xFFE53935), y = Color(0xFFFFB300);
      return [
        _b(-0.07, 0, 0.1, 0.025, 0.025, 0.1, y, pz: 0.2, a: l),
        _b(0.07, 0, 0.1, 0.025, 0.025, 0.1, y, pz: 0.2, a: -l),
        _b(0, 0, 0.33, 0.15, 0.2, 0.14, w),
        _b(0, -0.2, 0.42, 0.12, 0.05, 0.1, w),
        _b(0, 0.18, 0.58, 0.09, 0.09, 0.1, w, face: true),
        _b(0, 0.29, 0.56, 0.04, 0.04, 0.025, y),
        _b(0, 0.18, 0.72, 0.03, 0.07, 0.04, r),
        _b(0, 0.27, 0.48, 0.02, 0.02, 0.04, r),
      ];
    case 'kedi':
      const o = Color(0xFFFF9800), d = Color(0xFFE65100);
      return [
        for (final s in const [(-0.08, 0.18, 1.0), (0.08, 0.18, -1.0), (-0.08, -0.18, -1.0), (0.08, -0.18, 1.0)])
          _b(s.$1, s.$2, 0.1, 0.04, 0.04, 0.1, o, pz: 0.2, a: l * s.$3),
        _b(0, 0, 0.3, 0.12, 0.27, 0.1, o),
        _b(0, -0.12, 0.31, 0.121, 0.03, 0.101, d),
        _b(0, -0.3, 0.45, 0.03, 0.03, 0.18, o, pz: 0.3, a: -0.5),
        _b(0, 0.32, 0.42, 0.12, 0.1, 0.11, o, face: true),
        _b(-0.08, 0.32, 0.57, 0.035, 0.03, 0.04, d),
        _b(0.08, 0.32, 0.57, 0.035, 0.03, 0.04, d),
      ];
    case 'kopek':
      const b = Color(0xFF8D6E63), d = Color(0xFF4E342E);
      return [
        for (final s in const [(-0.1, 0.25, 1.0), (0.1, 0.25, -1.0), (-0.1, -0.25, -1.0), (0.1, -0.25, 1.0)])
          _b(s.$1, s.$2, 0.15, 0.05, 0.05, 0.15, b, pz: 0.3, a: l * s.$3),
        _b(0, 0, 0.42, 0.15, 0.35, 0.13, b),
        _b(0, -0.38, 0.55, 0.03, 0.03, 0.12, b, pz: 0.45, a: -0.6 + sin(walk * 2) * 0.3),
        _b(0, 0.42, 0.6, 0.14, 0.14, 0.13, b, face: true),
        _b(0, 0.58, 0.55, 0.07, 0.04, 0.05, d),
        _b(-0.15, 0.42, 0.62, 0.02, 0.05, 0.1, d),
        _b(0.15, 0.42, 0.62, 0.02, 0.05, 0.1, d),
      ];
    default: // at
      const b = Color(0xFFA1887F), d = Color(0xFF3E2723);
      return [
        for (final s in const [(-0.17, 0.42, 1.0), (0.17, 0.42, -1.0), (-0.17, -0.42, -1.0), (0.17, -0.42, 1.0)])
          _b(s.$1, s.$2, 0.36, 0.07, 0.07, 0.36, b, pz: 0.72, a: l * s.$3),
        _b(0, 0, 1.0, 0.24, 0.6, 0.25, b),
        _b(0, 0.62, 1.32, 0.12, 0.14, 0.26, b),
        _b(0, 0.82, 1.52, 0.12, 0.2, 0.12, b, face: true),
        _b(0, 0.55, 1.45, 0.04, 0.2, 0.2, d),
        _b(0, -0.62, 0.95, 0.04, 0.04, 0.2, d),
      ];
  }
}

// ======================= TARLA =======================

class Crop {
  final String id;
  final List<String> syl;
  final String emoji;
  final Color color;
  const Crop(this.id, this.syl, this.emoji, this.color);
  String get name => syl.join();
}

const crops = [
  Crop('havuc', ['ha', 'vuç'], '🥕', Color(0xFFFF8F00)),
  Crop('domates', ['do', 'ma', 'tes'], '🍅', Color(0xFFE53935)),
  Crop('bugday', ['buğ', 'day'], '🌾', Color(0xFFFDD835)),
  Crop('misir', ['mı', 'sır'], '🌽', Color(0xFFFFEB3B)),
  Crop('patlican', ['pat', 'lı', 'can'], '🍆', Color(0xFF7B1FA2)),
  Crop('marul', ['ma', 'rul'], '🥬', Color(0xFF7CB342)),
];

Crop cropById(String id) => crops.firstWhere((c) => c.id == id, orElse: () => crops[0]);

/// Her evre 60 saniye: tohum, filiz, büyüyor, olgun
const cropStageMs = 60000;
int cropStage(int plantedMs) => min(3, (DateTime.now().millisecondsSinceEpoch - plantedMs) ~/ cropStageMs);

List<ABox> cropBoxes(String id, int stage) {
  const g = Color(0xFF43A047), dg = Color(0xFF2E7D32), soil = Color(0xFF5D4037);
  final c = cropById(id);
  switch (stage) {
    case 0:
      return [_b(0, 0, 0.04, 0.14, 0.14, 0.04, soil), _b(0, 0, 0.09, 0.03, 0.03, 0.02, const Color(0xFFD7CCC8))];
    case 1:
      return [_b(0, 0, 0.12, 0.03, 0.03, 0.12, g), _b(0, 0, 0.23, 0.12, 0.03, 0.03, g), _b(0, 0, 0.27, 0.03, 0.1, 0.03, g)];
    case 2:
      return [
        _b(0, 0, 0.25, 0.04, 0.04, 0.25, g),
        _b(0.12, 0, 0.28, 0.1, 0.04, 0.035, g),
        _b(-0.12, 0, 0.36, 0.1, 0.04, 0.035, dg),
        _b(0, 0.12, 0.44, 0.04, 0.1, 0.035, g),
      ];
    default:
      switch (id) {
        case 'havuc':
          return [
            _b(0, 0, 0.05, 0.1, 0.1, 0.06, c.color),
            for (final d in const [(-0.06, 0.0), (0.06, 0.0), (0.0, 0.06)]) _b(d.$1, d.$2, 0.3, 0.025, 0.025, 0.2, g),
          ];
        case 'domates':
          return [
            _b(0, 0, 0.35, 0.04, 0.04, 0.35, dg),
            _b(0.12, 0.05, 0.4, 0.08, 0.08, 0.08, c.color),
            _b(-0.1, -0.06, 0.55, 0.08, 0.08, 0.08, c.color),
            _b(0.02, 0.12, 0.25, 0.07, 0.07, 0.07, c.color),
            _b(0, 0, 0.62, 0.15, 0.04, 0.03, g),
          ];
        case 'bugday':
          return [
            for (final d in const [(-0.15, -0.15), (0.15, -0.15), (-0.15, 0.15), (0.15, 0.15), (0.0, 0.0)]) ...[
              _b(d.$1, d.$2, 0.35, 0.02, 0.02, 0.35, const Color(0xFFC0A030)),
              _b(d.$1, d.$2, 0.78, 0.04, 0.04, 0.1, c.color),
            ]
          ];
        case 'misir':
          return [
            _b(0, 0, 0.55, 0.045, 0.045, 0.55, g),
            _b(0.08, 0, 0.62, 0.05, 0.05, 0.13, c.color),
            _b(-0.15, 0, 0.5, 0.12, 0.03, 0.03, dg),
            _b(0, 0.14, 0.85, 0.03, 0.12, 0.03, dg),
          ];
        case 'patlican':
          return [
            _b(0, 0, 0.3, 0.04, 0.04, 0.3, dg),
            _b(0.12, 0, 0.25, 0.06, 0.06, 0.13, c.color),
            _b(-0.12, 0.04, 0.3, 0.06, 0.06, 0.13, c.color),
            _b(0, 0, 0.58, 0.16, 0.05, 0.03, g),
          ];
        default: // marul
          return [
            _b(0, 0, 0.12, 0.16, 0.16, 0.12, c.color),
            _b(0, 0, 0.22, 0.11, 0.11, 0.08, const Color(0xFF9CCC65)),
          ];
      }
  }
}

// ======================= HECE PENCERESİ =======================

/// Bir kelimeyi hecelerinden (tek heceliyse harflerinden) kurdurur.
class SpellDialog extends StatefulWidget {
  final List<String> parts;
  final String emoji;
  final String title;
  final String speech;
  const SpellDialog({super.key, required this.parts, required this.emoji, required this.title, required this.speech});

  @override
  State<SpellDialog> createState() => _SpellDialogState();
}

class _SpellDialogState extends State<SpellDialog> {
  final rnd = Random();
  late final List<String> tiles;
  int placed = 0;
  final Set<int> used = {};
  int shake = 0;
  int wrong = 0;

  List<String> get w => widget.parts;

  @override
  void initState() {
    super.initState();
    final single = w.every((p) => p.length == 1);
    List<String> pool;
    if (single) {
      pool = lettersFor(max(2, game.letterGroup)).toList();
    } else {
      pool = Bank(game.letterGroup, game.step).twoLetter();
    }
    pool.shuffle(rnd);
    final extra = pool.where((s) => !w.contains(s)).take(single ? 3 : 2);
    tiles = [...w, ...extra]..shuffle(rnd);
    Voice.say(widget.speech);
  }

  void _tap(int i) {
    if (used.contains(i)) return;
    if (tiles[i] == w[placed]) {
      Sfx.play('tok');
      Voice.say(tiles[i]);
      game.recordSyllable(tiles[i], true);
      setState(() {
        used.add(i);
        placed++;
      });
      if (placed == w.length) {
        Future.delayed(const Duration(milliseconds: 500), () => Voice.say(trCapitalize(w.join())));
        Future.delayed(const Duration(milliseconds: 1300), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } else {
      Sfx.play('wrong');
      game.recordSyllable(tiles[i], false);
      wrong++;
      Voice.say(wrong >= 2 ? 'Sıradaki ${w[placed]}. Onu bul!' : 'Bir daha dene. Kelimeyi yavaşça söyle.');
      setState(() => shake++);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Voice.say(w.join()),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 64)),
                const Icon(Icons.volume_up, color: Colors.black45),
              ]),
            ),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, children: [
              for (var k = 0; k < w.length; k++)
                Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: k < placed ? const Color(0xFFC8E6C9) : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: k < placed ? SylText(w[k], size: 30) : const Text(' ? ', style: TextStyle(fontSize: 28)),
                ),
            ]),
            const SizedBox(height: 12),
            Shake(
              trigger: shake,
              child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                for (var i = 0; i < tiles.length; i++)
                  ChoiceTile(
                    size: 66,
                    dim: used.contains(i),
                    color: const Color(0xFFFFCC80),
                    onTap: () => _tap(i),
                    child: SylText(tiles[i], size: 30),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç', style: TextStyle(fontSize: 16))),
          ]),
        ),
      );
}

/// Dost hayvanın adını başının üstüne yazar.
void paintNameTag(Canvas canvas, Offset at, String name) {
  final tp = TextPainter(text: sylSpan(name, 15), textDirection: TextDirection.ltr)..layout();
  final r = Rect.fromCenter(center: at, width: tp.width + 12, height: tp.height + 6);
  canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = Colors.white.withAlpha(230));
  tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  final hp = TextPainter(text: const TextSpan(text: '💛', style: TextStyle(fontSize: 12)), textDirection: TextDirection.ltr)..layout();
  hp.paint(canvas, Offset(r.right - 4, r.top - 8));
}

// Kullanılmayan uyarısını önlemek için (Who art.dart'tan gelir)
const lifeWho = Who.tozbulut;
