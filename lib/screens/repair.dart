import 'package:flutter/material.dart';

import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';

/// Hece tamiri: Tamirci Usta bir kelime söyler, çocuk heceleri sırayla dizer.
/// Başarılı olunca `true` ile döner.
class RepairScreen extends StatefulWidget {
  const RepairScreen({super.key});

  @override
  State<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends State<RepairScreen> {
  late List<String> word;
  late List<String> tiles;
  final List<int> placed = [];
  int? wrongTile;
  bool done = false;

  @override
  void initState() {
    super.initState();
    final bank = Bank(game.letterGroup, game.step < 3 ? 3 : game.step);
    word = bank.repairWord();
    tiles = List.of(word);
    for (var i = 0; i < 6 && _sameOrder(); i++) {
      tiles.shuffle();
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Voice.say('Kutuyu açmak için heceleri sırayla diz: ${word.join()}');
    });
  }

  bool _sameOrder() {
    for (var i = 0; i < word.length; i++) {
      if (word[i] != tiles[i]) return false;
    }
    return true;
  }

  void _tap(int i) {
    if (done || placed.contains(i)) return;
    final expected = word[placed.length];
    if (tiles[i] == expected) {
      setState(() {
        placed.add(i);
        wrongTile = null;
      });
      game.recordSyllable(expected, true);
      if (placed.length == word.length) {
        setState(() => done = true);
        Voice.say('${word.join(', ')}. ${word.join()}! Aferin, kutu açıldı!');
        Future.delayed(const Duration(milliseconds: 2600), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        Voice.say(expected);
      }
    } else {
      setState(() => wrongTile = i);
      game.recordSyllable(expected, false);
      Voice.say('Bu ${tiles[i]}. Şimdi $expected lazım.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEBE9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBCAAA4),
        title: const Text('Hece tamiri', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(done ? Icons.lock_open : Icons.lock, size: 90, color: done ? Colors.green : const Color(0xFF6D4C41)),
              const SizedBox(height: 8),
              const Text('Parça kutusu kilitli. Heceleri sırayla diz!',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              // Yuvalar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var s = 0; s < word.length; s++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 92,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s < placed.length ? const Color(0xFFC8E6C9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8D6E63), width: 3),
                      ),
                      child: s < placed.length ? SylText(word[s], size: 34) : const SizedBox.shrink(),
                    ),
                ],
              ),
              const Spacer(),
              // Hece kartları
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < tiles.length; i++)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: placed.contains(i) ? 0.15 : 1,
                      child: Material(
                        color: wrongTile == i ? const Color(0xFFFFCDD2) : const Color(0xFFFFF59D),
                        elevation: 4,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _tap(i),
                          child: Container(
                            width: 100,
                            height: 84,
                            alignment: Alignment.center,
                            child: SylText(tiles[i], size: 38),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Voice.say(word.join()),
                icon: const Icon(Icons.volume_up, size: 30),
                label: const Text('Kelimeyi dinle', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
