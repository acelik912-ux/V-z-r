import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';

/// Hata sayısına göre yıldız.
int starsFor(int mistakes, {int ok3 = 1, int ok2 = 3}) => mistakes <= ok3 ? 3 : (mistakes <= ok2 ? 2 : 1);

/// Mini oyunların ortak iskeleti: arka plan, üst çubuk, ilerleme noktaları.
/// Oyun sürerken süre kilidi araya girmez, bölüm bitince devreye girer.
class LevelShell extends StatefulWidget {
  final String title;
  final String bg;
  final int round;
  final int total;
  final Widget child;
  final Color tint;
  const LevelShell({
    super.key,
    required this.title,
    required this.bg,
    required this.child,
    this.round = 0,
    this.total = 0,
    this.tint = const Color(0x00000000),
  });

  @override
  State<LevelShell> createState() => _LevelShellState();
}

class _LevelShellState extends State<LevelShell> {
  @override
  void initState() {
    super.initState();
    game.setInRace(true);
  }

  @override
  void dispose() {
    Say.hide();
    game.setInRace(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDeco(widget.bg),
        child: Container(
          color: widget.tint,
          child: SafeArea(
            child: Column(
              children: [
                TopBar(
                  widget.title,
                  trailing: widget.total > 0 ? _Dots(widget.round, widget.total) : null,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int round;
  final int total;
  const _Dots(this.round, this.total);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withAlpha(210), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < round ? Colors.green : (i == round ? Colors.amber : Colors.black12),
                ),
              ),
          ],
        ),
      );
}

/// Bölüm sonu penceresi. true dönerse oyun tekrar oynanır.
Future<bool> levelDone(
  BuildContext context, {
  required String id,
  required int stars,
  required Who who,
  int hearts = 0,
  String? sticker,
  String? message,
}) async {
  final got = game.finishLevel(id, stars, hearts: hearts, sticker: sticker);
  cheer(stars);
  final praise = message ??
      (stars == 3
          ? 'Harikasın ${game.driverName}! Üç yıldız!'
          : stars == 2
              ? 'Çok güzel! İki yıldız kazandın.'
              : 'Aferin, bitirdin! Bir daha denersen daha çok yıldız kazanırsın.');
  Voice.say(got != null ? '$praise Yeni bir çıkartma kazandın!' : praise);
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (_, a, __, child) =>
        ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
    pageBuilder: (ctx, _, __) => Stack(
      children: [
        const Positioned.fill(child: Confetti()),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: min(MediaQuery.of(ctx).size.width * 0.88, 380),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarRow(stars, size: 64),
                  const SizedBox(height: 6),
                  SizedBox(height: 150, child: Pic(whoPic(who, 'sevin'))),
                  const SizedBox(height: 6),
                  Text(praise,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                  if (hearts > 0) ...[
                    const SizedBox(height: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Pic('i_kalp', width: 30, height: 30),
                      Text(' +$hearts iyilik kalbi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                  if (got != null) ...[
                    const SizedBox(height: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Pic(got, width: 56, height: 56),
                      const Text('  Yeni çıkartma!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DlgBtn('Tekrar', Icons.replay, const Color(0xFF42A5F5), () => Navigator.pop(ctx, true)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DlgBtn('Devam', Icons.check, const Color(0xFF43A047), () => Navigator.pop(ctx, false)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Sfx.play('click');
  return r ?? false;
}

class _DlgBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DlgBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ),
      );
}

/// Bir oyunu bitince "Tekrar" seçilirse yeniden açar.
Future<void> playLoop(BuildContext context, Widget Function() build) async {
  var again = true;
  while (again && context.mounted) {
    again = await Navigator.push<bool>(context, fadeRoute<bool>(build())) ?? false;
  }
}

/// Yuvarlak köşeli renkli seçenek kutusu (hece, sayı, kelime).
class ChoiceTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final bool dim;
  const ChoiceTile({super.key, required this.child, required this.onTap, this.color = Colors.white, this.size = 86, this.dim = false});

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: dim ? 0.3 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            constraints: BoxConstraints(minWidth: size, minHeight: size * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 4))],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: max(0, size - 30)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
            ),
          ),
        ),
      );
}

/// Yanlış seçimde sallanan sarmalayıcı.
class Shake extends StatefulWidget {
  final Widget child;
  final int trigger;
  const Shake({super.key, required this.child, required this.trigger});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(sin(_c.value * pi * 6) * 10 * (1 - _c.value), 0), child: child),
        child: widget.child,
      );
}

/// Panel: beyaz yarı saydam yuvarlak kutu.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(225),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: child,
      );
}

/// Seçili harf grubuna uygun, resmi olan kelimeler (hecelere ayrılmış).
List<List<String>> pictureWords({int minSyl = 1}) {
  final bank = Bank(game.letterGroup, game.step);
  var list = bank.wordList().where((w) => wordEmoji.containsKey(w.join()) && w.length >= minSyl).toList();
  if (list.length < 4) {
    list = words.where((w) => wordEmoji.containsKey(w.join()) && w.length >= minSyl).take(12).toList();
  }
  list.shuffle();
  return list;
}
