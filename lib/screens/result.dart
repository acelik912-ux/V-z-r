import 'dart:async';

import 'package:flutter/material.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF59D), Color(0xFFFFCC80)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(medal, style: const TextStyle(fontSize: 90)),
                Text('${widget.rank}. oldun!', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
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
                              child: const Text('🪙', style: TextStyle(fontSize: 34)),
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
    );
  }
}
