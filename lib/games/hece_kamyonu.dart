import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'kit.dart';

/// Hece Kamyonu: heceleri doğru sırayla kamyona yükle, kelime yola çıksın.
class HeceKamyonu extends StatefulWidget {
  const HeceKamyonu({super.key});

  @override
  State<HeceKamyonu> createState() => _HeceKamyonuState();
}

class _HeceKamyonuState extends State<HeceKamyonu> {
  static const total = 5;
  final rnd = Random();
  late final List<List<String>> rounds;
  int round = 0;
  int mistakes = 0;
  int placed = 0;
  int shake = 0;
  bool driving = false;
  List<String> crates = [];
  Set<int> used = {};

  List<String> get word => rounds[round];

  @override
  void initState() {
    super.initState();
    var ws = pictureWords(minSyl: 2);
    if (ws.length < total) ws = [...ws, ...pictureWords()];
    rounds = [for (var i = 0; i < total; i++) ws[i % ws.length]];
    _setup();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.baykus, 'Heceleri sırayla kamyona yükle. Kelime yola çıksın!', mood: 'gosterir');
      Future.delayed(const Duration(milliseconds: 3800), _ask);
    });
  }

  void _setup() {
    placed = 0;
    used = {};
    final bank = Bank(game.letterGroup, game.step).twoLetter()..shuffle(rnd);
    final extra = bank.where((s) => !word.contains(s)).take(word.length == 1 ? 3 : 2);
    crates = [...word, ...extra]..shuffle(rnd);
  }

  void _ask() {
    if (!mounted) return;
    Voice.say('${trCapitalize(word.join())}. Yükle bakalım!');
  }

  void _tap(int i) {
    if (driving || used.contains(i)) return;
    final s = crates[i];
    if (s == word[placed]) {
      Sfx.play('tok');
      Voice.say(s);
      game.recordSyllable(s, true);
      setState(() {
        used.add(i);
        placed++;
      });
      if (placed == word.length) _done();
    } else {
      Sfx.play('wrong');
      game.recordSyllable(s, false);
      setState(() {
        mistakes++;
        shake++;
      });
      Voice.say('Bu $s. Sıradaki hece ${word[placed]}.');
    }
  }

  Future<void> _done() async {
    setState(() => driving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    Sfx.play('correct');
    Voice.say('${word.join('-')}. ${trCapitalize(word.join())}!');
    await Future.delayed(const Duration(milliseconds: 600));
    Sfx.play('rev');
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    if (round + 1 >= total) {
      final again = await levelDone(context, id: 'hece_kamyonu', stars: starsFor(mistakes), who: Who.baykus, sticker: 'arac_10');
      if (mounted) Navigator.pop(context, again);
      return;
    }
    setState(() {
      round++;
      driving = false;
      _setup();
    });
    _ask();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return LevelShell(
      title: 'Hece Kamyonu',
      bg: 'bolge_hece',
      round: round,
      total: total,
      child: Column(
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _ask,
            child: Panel(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(emojiFor(word.join()), style: const TextStyle(fontSize: 64)),
                const SizedBox(width: 10),
                const Icon(Icons.volume_up, size: 34, color: Colors.black54),
              ]),
            ),
          ),
          const Spacer(),
          // Kamyon ve kasasındaki heceler
          AnimatedSlide(
            offset: driving && placed == word.length ? const Offset(1.6, 0) : Offset.zero,
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeInCubic,
            child: SizedBox(
              width: w * 0.9,
              height: w * 0.62,
              child: Stack(
                children: [
                  Positioned.fill(child: Transform.flip(flipX: true, child: const Pic('arac_10'))),
                  Positioned(
                    left: w * 0.04,
                    right: w * 0.32,
                    top: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var k = 0; k < word.length; k++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _Crate(k < placed ? word[k] : '?', filled: k < placed, size: min(76, w * 0.5 / word.length)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Shake(
            trigger: shake,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < crates.length; i++)
                    ChoiceTile(
                      dim: used.contains(i),
                      color: const Color(0xFFFFCC80),
                      onTap: () => _tap(i),
                      child: SylText(crates[i], size: 34),
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

class _Crate extends StatelessWidget {
  final String text;
  final bool filled;
  final double size;
  const _Crate(this.text, {required this.filled, this.size = 70});

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: filled ? 1 : 0.85,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Container(
          width: size,
          height: size * 0.85,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFD7A15A) : Colors.white.withAlpha(150),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: filled ? const Color(0xFF8D5524) : Colors.black26, width: 3),
          ),
          child: Center(
            child: filled
                ? FittedBox(child: Padding(padding: const EdgeInsets.all(4), child: SylText(text, size: 30)))
                : const Text('?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black38)),
          ),
        ),
      );
}
