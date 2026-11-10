import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';

import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'race.dart';

class ResultScreen extends StatefulWidget {
  final int rank;
  final int correct;
  final int gates;
  final int coins;
  final int helped;

  const ResultScreen({
    super.key,
    required this.rank,
    required this.correct,
    required this.gates,
    required this.coins,
    required this.helped,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int shown = 0;
  Timer? _timer;
  bool countDone = false;

  int get cup => widget.rank <= 3 ? 1 : 0;

  @override
  void initState() {
    super.initState();
    game.addRaceResult(stars: widget.correct, hearts: widget.helped, cups: cup, coins: widget.coins);
    game.markPlayed('yaris');
    if (widget.rank == 1) game.addSticker('i_yildiz');
    Voice.say('Yarış bitti! ${ordinal(widget.rank)} oldun. Şimdi jetonlarını sayalım.');
    Future.delayed(const Duration(milliseconds: 3600), _startCount);
  }

  void _startCount() {
    if (!mounted) return;
    if (widget.coins == 0) {
      setState(() => countDone = true);
      Voice.say('Bu sefer jeton toplayamadık. Elhamdülillah, gayret ettin!');
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (shown >= widget.coins) {
        t.cancel();
        setState(() => countDone = true);
        Voice.say('Toplam ${widget.coins} jeton! Elhamdülillah!');
        return;
      }
      setState(() => shown++);
      Sfx.play('coin', volume: 0.5);
      Voice.say('$shown');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    game.setInRace(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medal = widget.rank == 1 ? '🥇' : (widget.rank == 2 ? '🥈' : (widget.rank == 3 ? '🥉' : '🏁'));
    return Scaffold(
      body: Stack(children: [
        Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF59D), Color(0xFFFFCC80)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _Podium(rank: widget.rank),
                Text('$medal ${widget.rank}. oldun!', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Hece kapıları: ${widget.correct} / ${widget.gates}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Text('Jetonlar: $shown', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < widget.coins; i++)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: i < shown ? 1 : 0.15,
                              child: const Pic('i_jeton', width: 34, height: 34),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Pill('+${widget.correct} ⭐ bilgi yıldızı', color: const Color(0xFFFFF9C4)),
                    if (widget.helped > 0) Pill('+${widget.helped} ❤️ iyilik kalbi', color: const Color(0xFFF8BBD0)),
                    if (cup > 0) Pill('+1 🏆 kupa', color: const Color(0xFFB2EBF2)),
                  ],
                ),
                const Spacer(),
                if (countDone) ...[
                  if (game.lockReason == null)
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (_) => const RaceScreen())),
                        icon: const Icon(Icons.replay, size: 30),
                        label: const Text('Tekrar yarış', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home, size: 30),
                      label: const Text('Ana ekrana dön', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
        if (widget.rank <= 3) const Positioned.fill(child: Confetti()),
      ]),
    );
  }
}

class _Podium extends StatelessWidget {
  final int rank;
  const _Podium({required this.rank});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = min(w * 0.72, MediaQuery.of(context).size.height * 0.34);
    // kürsü basamaklarının resimdeki yerleri (720x720 resim, ortalanmış kesit)
    const spots = {1: Offset(0.5, 0.6), 2: Offset(0.31, 0.73), 3: Offset(0.69, 0.74)};
    final at = spots[rank];
    return SizedBox(
      width: w,
      height: h,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(children: [
          const Positioned.fill(child: Pic('sonuc_kursu', fit: BoxFit.cover)),
          if (at != null)
            Positioned(
              left: at.dx * w - h * 0.25,
              top: at.dy * h - h * 0.32,
              child: SizedBox(width: h * 0.5, height: h * 0.36, child: Pic('arac_${game.selected('body')}')),
            )
          else
            Positioned(right: 8, bottom: 8, child: SizedBox(height: h * 0.6, child: const Pic('k_surucu'))),
        ]),
      ),
    );
  }
}
