import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'kit.dart';

// ======================= OTOPARK BULMACASI =======================

/// (x, y, uzunluk, yatay=1) — ilk parça bizim kırmızı arabamız. Sağdaki çıkışa ulaşmalı.
const _parkLevels = <(int, List<List<int>>)>[
  (3, [[0, 2, 2, 1], [3, 1, 2, 0], [4, 1, 2, 0]]),
  (4, [[0, 2, 2, 1], [2, 1, 2, 0], [4, 0, 3, 0], [5, 1, 2, 0]]),
  (5, [[1, 2, 2, 1], [4, 0, 3, 0], [3, 4, 2, 1], [2, 3, 2, 0]]),
  (6, [[2, 2, 2, 1], [4, 2, 3, 0], [2, 3, 3, 0], [4, 5, 2, 1]]),
  (7, [[0, 2, 2, 1], [5, 2, 3, 0], [2, 0, 3, 0], [0, 5, 3, 1]]),
  (8, [[0, 2, 2, 1], [3, 4, 2, 1], [4, 0, 2, 0], [4, 2, 2, 0], [2, 3, 3, 0], [1, 4, 2, 0]]),
  (9, [[0, 2, 2, 1], [3, 2, 2, 0], [5, 3, 3, 0], [2, 0, 2, 0], [2, 2, 2, 0], [0, 4, 3, 1]]),
  (10, [[1, 2, 2, 1], [3, 0, 3, 0], [2, 4, 2, 1], [1, 4, 2, 0], [5, 0, 3, 0]]),
];

const _carColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFF00ACC1),
  Color(0xFF6D4C41),
];

class Otopark extends StatefulWidget {
  const Otopark({super.key});

  @override
  State<Otopark> createState() => _OtoparkState();
}

class _OtoparkState extends State<Otopark> {
  static const n = 6;
  late final int level;
  late final int par;
  late List<List<int>> pcs;
  int moves = 0;
  int? dragging;
  double dragOff = 0;
  int lo = 0, hi = 0;
  bool won = false;

  @override
  void initState() {
    super.initState();
    var l = 0;
    while (l < _parkLevels.length && game.best('otopark_$l') > 0) {
      l++;
    }
    level = l % _parkLevels.length;
    par = _parkLevels[level].$1;
    pcs = [for (final p in _parkLevels[level].$2) [...p]];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Otopark çok kalabalık! Arabaları kaydır, kırmızı arabayı çıkışa ulaştır.', mood: 'dusun');
    });
  }

  List<List<int>> _grid({int? skip}) {
    final g = List.generate(n, (_) => List.filled(n, -1));
    for (var i = 0; i < pcs.length; i++) {
      if (i == skip) continue;
      final p = pcs[i];
      for (var k = 0; k < p[2]; k++) {
        final x = p[3] == 1 ? p[0] + k : p[0], y = p[3] == 1 ? p[1] : p[1] + k;
        g[y][x] = i;
      }
    }
    return g;
  }

  void _start(int i) {
    if (won) return;
    final g = _grid(skip: i);
    final p = pcs[i];
    final h = p[3] == 1;
    var a = h ? p[0] : p[1];
    while (a - 1 >= 0 && (h ? g[p[1]][a - 1] : g[a - 1][p[0]]) == -1) {
      a--;
    }
    var b = h ? p[0] : p[1];
    while (b + p[2] < n && (h ? g[p[1]][b + p[2]] : g[b + p[2]][p[0]]) == -1) {
      b++;
    }
    lo = a;
    hi = b;
    dragging = i;
    dragOff = 0;
  }

  void _update(double d, double cell) {
    if (dragging == null) return;
    final p = pcs[dragging!];
    final base = p[3] == 1 ? p[0] : p[1];
    setState(() => dragOff = (dragOff + d / cell).clamp((lo - base).toDouble(), (hi - base).toDouble()));
  }

  Future<void> _end() async {
    final i = dragging;
    if (i == null) return;
    final p = pcs[i];
    final step = dragOff.round();
    setState(() {
      if (step != 0) {
        if (p[3] == 1) {
          p[0] += step;
        } else {
          p[1] += step;
        }
        moves++;
        Sfx.play('tok');
      }
      dragging = null;
      dragOff = 0;
    });
    if (i == 0 && p[0] + p[2] == n) {
      setState(() => won = true);
      Sfx.play('rev');
      Voice.say('Çıkış! Kırmızı araba kurtuldu.');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      final stars = moves <= par + 1 ? 3 : (moves <= par * 2 ? 2 : 1);
      final again = await levelDone(context, id: 'otopark_$level', stars: stars, who: Who.tamirci, sticker: level == 3 ? 'arac_9' : null);
      if (mounted) Navigator.pop(context, again);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final board = min(w - 40, 420.0);
    final cell = board / n;
    return LevelShell(
      title: 'Otopark ${level + 1}',
      bg: 'ana_ekran',
      child: Column(children: [
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Hamle: $moves', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF546E7A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: SizedBox(
            width: board,
            height: board,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: CustomPaint(painter: _LotPainter(n))),
              Positioned(
                left: board + 2,
                top: cell * 2,
                child: Container(width: 14, height: cell, color: Colors.amber, child: const Center(child: Icon(Icons.arrow_right, size: 14))),
              ),
              for (var i = 0; i < pcs.length; i++) _piece(i, cell),
            ]),
          ),
        ),
        const Spacer(),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _piece(int i, double cell) {
    final p = pcs[i];
    final h = p[3] == 1;
    final off = dragging == i ? dragOff : 0.0;
    final x = (p[0] + (h ? off : 0) + (won && i == 0 ? 3 : 0)) * cell;
    final y = (p[1] + (h ? 0 : off)) * cell;
    return AnimatedPositioned(
      duration: dragging == i ? Duration.zero : const Duration(milliseconds: 250),
      left: x,
      top: y,
      child: GestureDetector(
        onPanStart: (_) => _start(i),
        onPanUpdate: (d) => _update(h ? d.delta.dx : d.delta.dy, cell),
        onPanEnd: (_) => _end(),
        child: SizedBox(
          width: h ? cell * p[2] : cell,
          height: h ? cell : cell * p[2],
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: CustomPaint(painter: _TopCarPainter(i == 0 ? _carColors[0] : _carColors[1 + (i % 7)], h, p[2] == 3, i == 0)),
          ),
        ),
      ),
    );
  }
}

class _LotPainter extends CustomPainter {
  final int n;
  _LotPainter(this.n);

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.width / n;
    final line = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    for (var i = 1; i < n; i++) {
      canvas.drawLine(Offset(i * c, 0), Offset(i * c, s.height), line);
      canvas.drawLine(Offset(0, i * c), Offset(s.width, i * c), line);
    }
    canvas.drawRect(Rect.fromLTWH(0, c * 2, s.width, c), Paint()..color = const Color(0x22FFEB3B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopCarPainter extends CustomPainter {
  final Color c;
  final bool horiz;
  final bool truck;
  final bool hero;
  _TopCarPainter(this.c, this.horiz, this.truck, this.hero);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    var w = s.width, h = s.height;
    if (!horiz) {
      canvas.translate(s.width, 0);
      canvas.rotate(pi / 2);
      w = s.height;
      h = s.width;
    }
    final wheel = Paint()..color = const Color(0xFF212121);
    for (final fx in [0.18, 0.78]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * fx - 7, -1, 14, 6), const Radius.circular(2)), wheel);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * fx - 7, h - 5, 14, 6), const Radius.circular(2)), wheel);
    }
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, w, h - 4), Radius.circular(h * 0.3));
    canvas.drawRRect(body.shift(const Offset(0, 3)), Paint()..color = Colors.black26);
    canvas.drawRRect(body, Paint()..color = c);
    final glass = Paint()..color = const Color(0xFF263238);
    if (truck) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, h * 0.12, w * 0.62, h * 0.76), const Radius.circular(6)),
          Paint()..color = Colors.white.withAlpha(200));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h * 0.18, w * 0.08, h * 0.64), const Radius.circular(3)), glass);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.6, h * 0.16, w * 0.14, h * 0.68), const Radius.circular(4)), glass);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.1, h * 0.6), const Radius.circular(4)), glass);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.18, w * 0.26, h * 0.64), const Radius.circular(6)),
          Paint()..color = Color.lerp(c, Colors.white, 0.25)!);
    }
    final lamp = Paint()..color = const Color(0xFFFFF59D);
    canvas.drawCircle(Offset(w - 5, h * 0.25), 3.5, lamp);
    canvas.drawCircle(Offset(w - 5, h * 0.75), 3.5, lamp);
    if (hero) {
      final tp = TextPainter(text: const TextSpan(text: '★', style: TextStyle(fontSize: 22, color: Colors.white)), textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(w * 0.45 - tp.width / 2, h / 2 - tp.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ======================= TRAFİK KURALLARI =======================

class _TQ {
  final String scene;
  final String question;
  final List<(String, String, bool)> options; // emoji, yazı, doğru mu
  final String why;
  final int light; // 0 yok, 1 kırmızı, 2 yeşil, 3 sarı
  const _TQ(this.scene, this.question, this.options, this.why, {this.light = 0});
}

const _trafik = [
  _TQ('🚗', 'Işık kırmızı yandı. Ne yaparız?', [('🛑', 'dur', true), ('💨', 'geç', false)], 'Kırmızı ışıkta durulur.', light: 1),
  _TQ('🚗', 'Işık yeşil yandı. Ne yaparız?', [('🚗', 'dikkatli geç', true), ('😴', 'uyu', false)], 'Yeşilde dikkatlice geçeriz.', light: 2),
  _TQ('🚸 👵', 'Yaya geçidinde bir nine var.', [('✋', 'bekle', true), ('📯', 'korna çal', false)], 'Yayalara yol veririz, büyüklere saygı gösteririz.'),
  _TQ('🚗 💺', 'Arabaya bindik. İlk ne yaparız?', [('🔒', 'kemer tak', true), ('🤸', 'ayakta dur', false)], 'Önce emniyet kemerini takarız.'),
  _TQ('⚽ 🛣️', 'Topumuz yola kaçtı!', [('🙋', 'büyüğüne söyle', true), ('🏃', 'yola koş', false)], 'Yola koşmayız, bir büyüğümüze söyleriz.'),
  _TQ('🚑', 'Arkadan ambulans geliyor.', [('↪️', 'yol ver', true), ('🏁', 'yarış', false)], 'Ambulansa hemen yol veririz, belki biri hasta.'),
  _TQ('🚌', 'Otobüse binerken sıra var.', [('🧍🧍', 'sıra bekle', true), ('🤾', 'it kak', false)], 'Sıramızı bekleriz, kimseyi itmeyiz.'),
];

class Trafik extends StatefulWidget {
  const Trafik({super.key});

  @override
  State<Trafik> createState() => _TrafikState();
}

class _TrafikState extends State<Trafik> {
  final rnd = Random();
  late final List<_TQ> qs = [..._trafik]..shuffle(rnd);
  late List<(String, String, bool)> opts;
  int round = 0;
  int mistakes = 0;
  int shake = 0;
  bool answered = false;
  static const total = 6;

  _TQ get q => qs[round];

  @override
  void initState() {
    super.initState();
    opts = [...q.options]..shuffle(rnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Trafik kurallarını öğrenelim. Kurallara uyan herkes güvende olur.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 3800), _ask);
    });
  }

  void _ask() {
    if (mounted) Voice.say(q.question);
  }

  Future<void> _tap((String, String, bool) o) async {
    if (answered) return;
    if (o.$3) {
      answered = true;
      Sfx.play('correct');
      Voice.say('Doğru! ${q.why}');
      setState(() {});
      await Future.delayed(Duration(milliseconds: 1500 + q.why.length * 60));
      if (!mounted) return;
      if (round + 1 >= total) {
        final again = await levelDone(context, id: 'trafik', stars: starsFor(mistakes, ok3: 0, ok2: 2), who: Who.tamirci, sticker: 'i_benzin');
        if (mounted) Navigator.pop(context, again);
        return;
      }
      setState(() {
        round++;
        answered = false;
        opts = [...q.options]..shuffle(rnd);
      });
      _ask();
    } else {
      Sfx.play('wrong');
      Voice.say('Hayır, bu tehlikeli. Bir daha düşün.');
      setState(() {
        mistakes++;
        shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LevelShell(
      title: 'Trafik Kuralları',
      bg: 'ana_ekran',
      round: round,
      total: total,
      child: Column(children: [
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _ask,
          child: Panel(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (q.light > 0) _Light(q.light),
                const SizedBox(width: 12),
                Text(q.scene, style: const TextStyle(fontSize: 64)),
              ]),
              const SizedBox(height: 8),
              Text(q.question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              if (answered) ...[
                const SizedBox(height: 6),
                Text(q.why, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ],
            ]),
          ),
        ),
        const Spacer(),
        Shake(
          trigger: shake,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (final o in opts)
              ChoiceTile(
                size: 140,
                color: answered && o.$3 ? const Color(0xFFC8E6C9) : Colors.white,
                onTap: () => _tap(o),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(o.$1, style: const TextStyle(fontSize: 48)),
                  SylText(o.$2, size: 24),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _Light extends StatelessWidget {
  final int on;
  const _Light(this.on);

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: const Color(0xFF263238), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          for (final (i, c) in [(1, Colors.red), (3, Colors.amber), (2, Colors.green)])
            Container(
              margin: const EdgeInsets.all(2),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on == i ? c : c.withAlpha(50),
                boxShadow: on == i ? [BoxShadow(color: c, blurRadius: 12)] : null,
              ),
            ),
        ]),
      );
}

// ======================= İYİLİK TESLİMATI =======================

class _Who {
  final String word;
  final String emoji;
  const _Who(this.word, this.emoji);
}

const _people = [
  _Who('nine', '👵'),
  _Who('dede', '👴'),
  _Who('anne', '👩'),
  _Who('baba', '👨'),
  _Who('teyze', '👩‍🦱'),
  _Who('amca', '🧔'),
  _Who('bebek', '👶'),
  _Who('abla', '👧'),
];

const _gifts = [
  ('ekmek', '🍞'),
  ('çiçek', '🌷'),
  ('su', '💧'),
  ('elma', '🍎'),
  ('çorba', '🍲'),
  ('kitap', '📖'),
];

class IyilikTeslimati extends StatefulWidget {
  const IyilikTeslimati({super.key});

  @override
  State<IyilikTeslimati> createState() => _IyilikTeslimatiState();
}

class _IyilikTeslimatiState extends State<IyilikTeslimati> {
  static const total = 4;
  final rnd = Random();
  late final List<_Who> pool;
  int round = 0;
  int mistakes = 0;
  int shake = 0;
  int? arrived;
  late List<_Who> houses;
  late (String, String) gift;

  _Who get target => pool[round];

  @override
  void initState() {
    super.initState();
    final letters = lettersFor(game.letterGroup);
    final readable = _people.where((p) => p.word.split('').every(letters.contains)).toList()..shuffle(rnd);
    final rest = _people.where((p) => !readable.contains(p)).toList()..shuffle(rnd);
    pool = [...readable, ...rest];
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Komşularımıza iyilik götürelim! Kapıdaki yazıyı oku, doğru eve git.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 3800), _ask);
    });
  }

  void _newRound() {
    arrived = null;
    final others = pool.where((p) => p != target).toList()..shuffle(rnd);
    houses = [target, others[0], others[1]]..shuffle(rnd);
    gift = _gifts[rnd.nextInt(_gifts.length)];
  }

  void _ask() {
    if (mounted) Voice.say('${trCapitalize(target.word)} için ${gift.$1} götürelim. ${trCapitalize(target.word)} yazan evi bul.');
  }

  Future<void> _tap(int i) async {
    if (arrived != null) return;
    if (houses[i] == target) {
      Sfx.play('horn0');
      setState(() => arrived = i);
      await Future.delayed(const Duration(milliseconds: 1300));
      Sfx.play('heart');
      Voice.say('Allah razı olsun yavrum! Çok teşekkür ederim.');
      await Future.delayed(const Duration(milliseconds: 2600));
      if (!mounted) return;
      if (round + 1 >= total) {
        final again =
            await levelDone(context, id: 'iyilik', stars: starsFor(mistakes), who: Who.tamirci, hearts: 2, sticker: 'i_kalp', message: 'İyilik yapmak ne güzel! Komşuların çok mutlu oldu.');
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
      Voice.say('Bu evin kapısında ${houses[i].word} yazıyor. Bir daha oku.');
      setState(() {
        mistakes++;
        shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hw = (w - 40) / 3;
    return LevelShell(
      title: 'İyilik Teslimatı',
      bg: 'ana_ekran',
      round: round,
      total: total,
      child: Column(children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _ask,
          child: Panel(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(gift.$2, style: const TextStyle(fontSize: 50)),
              const Text(' → ', style: TextStyle(fontSize: 30)),
              Text(target.emoji, style: const TextStyle(fontSize: 50)),
              const SizedBox(width: 6),
              const Icon(Icons.volume_up, color: Colors.black54),
            ]),
          ),
        ),
        const Spacer(),
        Shake(
          trigger: shake,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (var i = 0; i < houses.length; i++)
              Bouncy(
                onTap: () => _tap(i),
                child: SizedBox(
                  width: hw,
                  child: Column(children: [
                    AnimatedOpacity(
                      opacity: arrived == i ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: Text('${houses[i].emoji}❤️', style: const TextStyle(fontSize: 34)),
                    ),
                    _House(houses[i].word, hw, i),
                  ]),
                ),
              ),
          ]),
        ),
        SizedBox(
          height: 110,
          child: LayoutBuilder(builder: (_, c) {
            final x = arrived == null ? c.maxWidth / 2 - 55 : 20 + arrived! * (hw + 10) + hw / 2 - 55;
            return Stack(children: [
              Positioned(left: 0, right: 0, top: 50, height: 40, child: Container(color: const Color(0xAA546E7A))),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                left: x,
                top: 4,
                child: SizedBox(
                  width: 110,
                  height: 90,
                  child: Stack(children: [
                    Positioned.fill(child: Pic('arac_${game.selected('body')}')),
                    Positioned(right: 0, top: 0, child: Text(gift.$2, style: const TextStyle(fontSize: 26))),
                  ]),
                ),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _House extends StatelessWidget {
  final String word;
  final double w;
  final int style;
  const _House(this.word, this.w, this.style);

  @override
  Widget build(BuildContext context) {
    const roofs = [Color(0xFFD84315), Color(0xFF1565C0), Color(0xFF6A1B9A)];
    const walls = [Color(0xFFFFF3E0), Color(0xFFFFF9C4), Color(0xFFE8F5E9)];
    return SizedBox(
      width: w,
      height: w * 1.15,
      child: CustomPaint(
        painter: _HousePainter(roofs[style % 3], walls[style % 3]),
        child: Align(
          alignment: const Alignment(0, 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8D5524), width: 3),
            ),
            child: FittedBox(child: SylText(word, size: 24)),
          ),
        ),
      ),
    );
  }
}

class _HousePainter extends CustomPainter {
  final Color roof;
  final Color wall;
  _HousePainter(this.roof, this.wall);

  @override
  void paint(Canvas canvas, Size s) {
    final body = Rect.fromLTWH(s.width * 0.1, s.height * 0.38, s.width * 0.8, s.height * 0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(body.shift(const Offset(0, 4)), const Radius.circular(8)), Paint()..color = Colors.black26);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(8)), Paint()..color = wall);
    final r = Path()
      ..moveTo(0, s.height * 0.42)
      ..lineTo(s.width / 2, s.height * 0.05)
      ..lineTo(s.width, s.height * 0.42)
      ..close();
    canvas.drawPath(r, Paint()..color = roof);
    canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(s.width * 0.38, s.height * 0.7, s.width * 0.24, s.height * 0.28),
            topLeft: const Radius.circular(12), topRight: const Radius.circular(12)),
        Paint()..color = const Color(0xFF8D5524));
    canvas.drawCircle(Offset(s.width * 0.57, s.height * 0.85), 3, Paint()..color = Colors.amber);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
