import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'kit.dart';

class _Animal {
  final String name;
  final String mom;
  final String baby;
  final String babyName;
  const _Animal(this.name, this.mom, this.baby, this.babyName);
}

const _animals = [
  _Animal('kedi', '🐈', '🐱', 'Yavru kedi'),
  _Animal('inek', '🐄', '🐮', 'Buzağı'),
  _Animal('kuş', '🐦', '🐣', 'Yavru kuş'),
  _Animal('ata', '🐎', '🐴', 'Tay'),
  _Animal('köpek', '🐕', '🐶', 'Yavru köpek'),
  _Animal('tavşan', '🐇', '🐰', 'Yavru tavşan'),
  _Animal('horoz', '🐓', '🐤', 'Civciv'),
  _Animal('balık', '🐟', '🐠', 'Yavru balık'),
  _Animal('arı', '🐝', '🐝', 'Küçük arı'),
  _Animal('fil', '🐘', '🐘', 'Yavru fil'),
];

// ======================= HAYVAN KURTARMA =======================

/// Hayvan Kurtarma: yavru annesini arıyor, tabelayı oku ve doğru yola götür.
class HayvanKurtarma extends StatefulWidget {
  const HayvanKurtarma({super.key});

  @override
  State<HayvanKurtarma> createState() => _HayvanKurtarmaState();
}

class _HayvanKurtarmaState extends State<HayvanKurtarma> {
  static const total = 4;
  final rnd = Random();
  late final List<_Animal> pool;
  int round = 0;
  int mistakes = 0;
  int shake = 0;
  int? chosen;
  late List<_Animal> signs;

  _Animal get target => pool[round];

  @override
  void initState() {
    super.initState();
    final letters = lettersFor(game.letterGroup);
    final readable = _animals.where((a) => a.name.split('').every(letters.contains)).toList()..shuffle(rnd);
    final rest = _animals.where((a) => !readable.contains(a)).toList()..shuffle(rnd);
    pool = [...readable, ...rest];
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tozbulut, 'Ormanda yavrular kaybolmuş! Tabelaları okuyup onları annelerine götürelim.', mood: 'anlat');
      Future.delayed(const Duration(milliseconds: 4200), _ask);
    });
  }

  void _newRound() {
    chosen = null;
    final others = pool.where((a) => a != target).toList()..shuffle(rnd);
    signs = [target, others[0], others[1]]..shuffle(rnd);
  }

  void _ask() {
    if (mounted) Voice.say('${target.babyName} annesini arıyor. Annesi ${target.name}. ${trCapitalize(target.name)} yazan tabelayı bul.');
  }

  Future<void> _tap(int i) async {
    if (chosen != null) return;
    final a = signs[i];
    if (a == target) {
      Sfx.play('heart');
      setState(() => chosen = i);
      Voice.say('${trCapitalize(a.name)}! Yavru annesine kavuştu. Hayvanlara merhamet etmek ne güzel!');
      await Future.delayed(const Duration(milliseconds: 2600));
      if (!mounted) return;
      if (round + 1 >= total) {
        final again =
            await levelDone(context, id: 'hayvan', stars: starsFor(mistakes), who: Who.tozbulut, hearts: 1, sticker: 'k_tozbulut_gul');
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
      Voice.say('Burada ${a.name} yazıyor. Bir daha oku.');
      setState(() {
        mistakes++;
        shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LevelShell(
      title: 'Hayvan Kurtarma',
      bg: 'bolge_kelime',
      round: round,
      total: total,
      child: Column(
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _ask,
            child: Panel(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(chosen == null ? target.baby : '${target.mom}❤️${target.baby}',
                      key: ValueKey(chosen), style: const TextStyle(fontSize: 60)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.volume_up, size: 30, color: Colors.black54),
              ]),
            ),
          ),
          const Spacer(),
          Shake(
            trigger: shake,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < signs.length; i++)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Bouncy(
                    onTap: () => _tap(i),
                    child: Column(children: [
                      AnimatedOpacity(
                        opacity: chosen == i ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Text(signs[i].mom, style: const TextStyle(fontSize: 54)),
                      ),
                      _Sign(signs[i].name, highlight: chosen == i),
                    ]),
                  ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Sign extends StatelessWidget {
  final String word;
  final bool highlight;
  const _Sign(this.word, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFFFF59D) : const Color(0xFFF5DEB3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8D5524), width: 4),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 3))],
          ),
          child: SylText(word, size: 30),
        ),
        Container(width: 12, height: 70, color: const Color(0xFF8D5524)),
      ]);
}

// ======================= HAFIZA KARTLARI =======================

/// Hafıza Kartları: kelime kartını resmiyle eşleştir.
class HafizaKartlari extends StatefulWidget {
  const HafizaKartlari({super.key});

  @override
  State<HafizaKartlari> createState() => _HafizaKartlariState();
}

class _Card {
  final String word;
  final bool pic;
  bool open = false;
  bool done = false;
  _Card(this.word, this.pic);
}

class _HafizaKartlariState extends State<HafizaKartlari> {
  final rnd = Random();
  late final List<_Card> cards;
  int? first;
  bool busy = false;
  int mistakes = 0;
  int pairs = 0;
  static const nPairs = 6;

  @override
  void initState() {
    super.initState();
    final ws = pictureWords().map((w) => w.join()).toSet().take(nPairs).toList();
    cards = [for (final w in ws) ...[_Card(w, false), _Card(w, true)]]..shuffle(rnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.baykus, 'Kartları çevir. Kelimeyi resmiyle eşleştir!', mood: 'okur');
    });
  }

  Future<void> _tap(int i) async {
    final c = cards[i];
    if (busy || c.open || c.done) return;
    Sfx.play('kart');
    setState(() => c.open = true);
    if (!c.pic) Voice.say(c.word);
    if (first == null) {
      first = i;
      return;
    }
    final f = cards[first!];
    first = null;
    if (f.word == c.word) {
      busy = true;
      await Future.delayed(const Duration(milliseconds: 500));
      Sfx.play('correct');
      Voice.say('${trCapitalize(c.word)}! Eşleşti.');
      setState(() {
        f.done = true;
        c.done = true;
        pairs++;
      });
      busy = false;
      if (pairs == cards.length ~/ 2) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        final again =
            await levelDone(context, id: 'hafiza', stars: starsFor(mistakes, ok3: 4, ok2: 9), who: Who.baykus, sticker: 'k_baykus_okur');
        if (mounted) Navigator.pop(context, again);
      }
    } else {
      busy = true;
      mistakes++;
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      setState(() {
        f.open = false;
        c.open = false;
      });
      busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LevelShell(
      title: 'Hafıza Kartları',
      bg: 'bolge_kelime',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              for (var i = 0; i < cards.length; i++) _CardView(cards[i], () => _tap(i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  final _Card c;
  final VoidCallback onTap;
  const _CardView(this.c, this.onTap);

  @override
  Widget build(BuildContext context) {
    final shown = c.open || c.done;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: shown ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        builder: (_, v, __) {
          final face = v > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(pi * v),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(face ? pi : 0),
              child: AnimatedOpacity(
                opacity: c.done ? 0.55 : 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: face ? Colors.white : const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 3))],
                  ),
                  child: Center(
                    child: face
                        ? (c.pic
                            ? Text(emojiFor(c.word), style: const TextStyle(fontSize: 52))
                            : FittedBox(child: Padding(padding: const EdgeInsets.all(6), child: SylText(c.word, size: 32))))
                        : const Pic('i_yildiz', width: 46, height: 46),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
