import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'blok.dart';
import 'blok_bag.dart';
import 'blok_life.dart';
import 'kit.dart';

// ================= KELİME TEZGÂHI ve HECE MADENİ =================

/// Tezgâhta hecelerden yapılan kelime ve verdiği ödül.
/// Ödül: mat:<blok>, seed:<ekin>, animal:<hayvan>, coins:<n>
class Recipe {
  final List<String> parts;
  final String emoji;
  final String reward;
  const Recipe(this.parts, this.emoji, this.reward);
  String get word => parts.join();

  /// Kelimenin harfleri en erken hangi ses grubunda tamamlanıyor.
  int get group {
    for (var g = 1; g <= letterGroups.length; g++) {
      final l = lettersFor(g);
      if (word.split('').every(l.contains)) return g;
    }
    return letterGroups.length;
  }
}

const recipes = <Recipe>[
  // 1. grup: e l a k i n
  Recipe(['i', 'nek'], '🐄', 'animal:inek'),
  Recipe(['ka', 'le'], '🏰', 'mat:tasduvar'),
  Recipe(['e', 'kin'], '🌾', 'seed:bugday'),
  Recipe(['la', 'le'], '🌷', 'mat:cicek'),
  Recipe(['k', 'i', 'l'], '🧱', 'mat:tugla'),
  Recipe(['n', 'a', 'l'], '🧲', 'coins:4'),
  Recipe(['k', 'e', 'k'], '🍰', 'coins:4'),
  // 2. grup: o m u t ü y
  Recipe(['m', 'u', 'm'], '🕯️', 'mat:lamba'),
  Recipe(['k', 'u', 'm'], '🏖️', 'mat:kumtasi'),
  Recipe(['t', 'e', 'l'], '〰️', 'mat:cit'),
  Recipe(['kü', 'tük'], '🪵', 'mat:kutuk'),
  Recipe(['ko', 'yun'], '🐑', 'animal:koyun'),
  Recipe(['a', 't'], '🐴', 'animal:at'),
  Recipe(['to', 'tem'], '🗿', 'mat:totem'),
  Recipe(['t', 'o', 'p'], '⚽', 'coins:5'),
  Recipe(['ma', 'ta'], '🪓', 'coins:4'),
  // 3. grup: ö r ı d s b
  Recipe(['ke', 'di'], '🐱', 'animal:kedi'),
  Recipe(['ta', 'be', 'la'], '🪧', 'mat:tabela'),
  Recipe(['de', 'mir'], '⚙️', 'mat:demir'),
  Recipe(['mer', 'mer'], '⬜', 'mat:beyaz'),
  Recipe(['el', 'mas'], '💎', 'mat:elmas'),
  Recipe(['al', 'tın'], '🪙', 'mat:altin'),
  Recipe(['ba', 'lık'], '🐟', 'coins:5'),
  // 4. grup: z ç g ş c p
  Recipe(['ka', 'pı'], '🚪', 'mat:hecekapi'),
  Recipe(['kö', 'pek'], '🐶', 'animal:kopek'),
  Recipe(['pen', 'ce', 're'], '🪟', 'mat:pencere'),
  Recipe(['çi', 'çek'], '🌼', 'mat:cicek'),
  Recipe(['gü', 'neş'], '☀️', 'coins:6'),
  // 5. grup: h ğ v f j
  Recipe(['ta', 'vuk'], '🐔', 'animal:tavuk'),
  Recipe(['a', 'ğaç'], '🌳', 'coins:6'),
  Recipe(['fe', 'ner'], '🏮', 'mat:fener'),
];

List<Recipe> recipesNow() {
  final g = max(1, game.letterGroup);
  return recipes.where((r) => r.group <= g).toList();
}

/// Taş kırınca düşecek hece: bazen çocuğun zorlandığı hecelerden (tekrar için),
/// çoğunlukla tezgâhta işine yarayacak, çantada en az olan hecelerden.
String pickDropSyl(Random r) {
  final pool = <String>{for (final rc in recipesNow()) ..._paid(rc)}.toList();
  final weak = game.weakSyllables(10).where((s) => s.length > 1).toList();
  if (weak.isNotEmpty && r.nextDouble() < 0.35) return weak[r.nextInt(weak.length)];
  if (pool.isEmpty) return 'ka';
  pool.shuffle(r);
  pool.sort((a, b) => (game.sylBag[a] ?? 0).compareTo(game.sylBag[b] ?? 0));
  return pool[r.nextInt(min(4, pool.length))];
}

/// Tek harfli parçalar (i-nek'teki i) bedava; tek heceli kelimeler (kil, mum)
/// harflerle dizilir ama madenden kelimenin kendisi gibi tek hece taşı ister.
bool _letters(Recipe rc) => rc.parts.every((p) => p.length == 1);
bool _free(String p) => p.length == 1;

List<String> _paid(Recipe rc) => _letters(rc) ? [rc.word] : rc.parts.where((p) => !_free(p)).toList();

/// Kartta gösterilen parçalar
List<String> _shown(Recipe rc) => _letters(rc) ? [rc.word] : rc.parts;

List<String> missingFor(Recipe rc) {
  final need = <String, int>{};
  for (final p in _paid(rc)) {
    need[p] = (need[p] ?? 0) + 1;
  }
  final out = <String>[];
  for (final e in need.entries) {
    final have = game.sylBag[e.key] ?? 0;
    for (var i = have; i < e.value; i++) {
      out.add(e.key);
    }
  }
  return out;
}

/// Tezgâhta yapılan hayvanlar; Blok Şehri ekran dönünce yanına koyar.
final List<String> pendingAnimals = [];

String rewardName(String reward) {
  final k = reward.split(':');
  switch (k[0]) {
    case 'mat':
      final m = matIndex(k[1]);
      return m >= 0 ? mats[m].name : k[1];
    case 'seed':
      return '${cropById(k[1]).name} tohumu';
    case 'animal':
      return kindById(k[1]).name;
    default:
      return '${k[1]} altın';
  }
}

class WorkbenchScreen extends StatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<WorkbenchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Say.show(
          context,
          Who.tamirci,
          game.sylBag.isEmpty
              ? 'Burası kelime tezgâhı! Taş kırınca hece taşları çıkar. Hecelerle kelime yaparsın, kelime de gerçek olur!'
              : 'Yeşil parlayan kelimeye dokun, hecelerini sırayla diz. Kelime gerçek olsun!',
          mood: 'iyi');
    });
  }

  Future<void> _make(Recipe rc) async {
    final miss = missingFor(rc);
    if (miss.isNotEmpty) {
      Sfx.play('click');
      Voice.say('${trCapitalize(rc.word)} için ${miss.toSet().join(' ve ')} hecesi lazım. Taş kır, hece taşı bul!');
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: rc.parts,
              emoji: rc.emoji,
              title: 'Hecelerini diz: ${rc.word}',
              speech: '${trCapitalize(rc.word)} yapalım! Hecelerini sırayla diz.',
            ));
    if (ok != true || !mounted) return;
    if (!game.useSyls(_paid(rc))) return;
    game.addCrafted(rc.word);
    final k = rc.reward.split(':');
    var msg = '';
    switch (k[0]) {
      case 'mat':
        if (bagUnlocked(k[1])) {
          game.addCoins(3);
          msg = '${trCapitalize(rc.word)} yaptın! ${trCapitalize(rewardName(rc.reward))} zaten çantanda, 3 altın kazandın.';
        } else {
          game.addBlockItem(k[1]);
          msg = 'Harika! Artık çantanda ${rewardName(rc.reward)} var!';
        }
      case 'seed':
        game.addBlockItem('seed_${k[1]}');
        game.addCoins(2);
        msg = '${trCapitalize(rewardName(rc.reward))} çantana girdi. Tarlaya ek!';
      case 'animal':
        pendingAnimals.add(k[1]);
        msg = 'Bir ${rewardName(rc.reward)} doğdu! Yanına geliyor, adı ${rc.word}.';
      default:
        game.addCoins(int.parse(k[1]));
        msg = '${trCapitalize(rc.word)}! ${k[1]} altın kazandın.';
    }
    Sfx.play('unlock');
    if (!mounted) return;
    setState(() {});
    Say.show(context, Who.tamirci, msg, mood: 'sevin');
  }

  @override
  Widget build(BuildContext context) {
    final list = recipesNow()
      ..sort((a, b) {
        final ra = missingFor(a).isEmpty ? 0 : 1, rb = missingFor(b).isEmpty ? 0 : 1;
        return ra != rb ? ra.compareTo(rb) : missingFor(a).length.compareTo(missingFor(b).length);
      });
    final bag = game.sylBag.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(
      backgroundColor: const Color(0xFF5D4037),
      body: SafeArea(
        child: Column(children: [
          TopBar('🔨 Kelime Tezgâhı',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text('🪙 ${game.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              )),
          Container(
            height: 92,
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFD7CCC8), borderRadius: BorderRadius.circular(18)),
            child: bag.isEmpty
                ? const Center(
                    child: Text('⛏️ Taş kır, hece taşı topla!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))
                : ListView(scrollDirection: Axis.horizontal, children: [
                    for (final e in bag)
                      Bouncy(
                        onTap: () => Voice.say(e.key),
                        child: Container(
                          width: 74,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB39DDB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF4527A0), width: 3),
                          ),
                          child: Stack(children: [
                            Center(child: FittedBox(child: Padding(padding: const EdgeInsets.all(4), child: SylText(e.key, size: 28)))),
                            Positioned(
                              right: 3,
                              top: 2,
                              child: Text('×${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ]),
                        ),
                      ),
                  ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final rc = list[i];
                final miss = missingFor(rc);
                final ready = miss.isEmpty;
                final made = game.crafted[rc.word] ?? 0;
                final left = [...miss];
                return Bouncy(
                  onTap: () => _make(rc),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ready ? const Color(0xFFC8E6C9) : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ready ? const Color(0xFF2E7D32) : const Color(0xFF8D6E63), width: ready ? 4 : 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(rc.emoji, style: const TextStyle(fontSize: 38)),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Row(children: [
                          for (final p in _shown(rc))
                            Builder(builder: (_) {
                              final missing = !_free(p) && left.remove(p);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: missing ? Colors.black12 : const Color(0xFFB39DDB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Opacity(opacity: missing ? 0.35 : 1, child: SylText(p, size: 18)),
                              );
                            }),
                        ]),
                      ),
                      if (made > 0) Text('✔ $made', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ================= HAVA TOTEMİ =================

const weathers = [
  ('gunes', ['gü', 'neş'], '☀️'),
  ('yagmur', ['yağ', 'mur'], '🌧️'),
  ('kar', ['k', 'a', 'r'], '❄️'),
];

class WeatherDialog extends StatelessWidget {
  const WeatherDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFE0F2F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🗿 Hava totemi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              for (final w in weathers)
                ChoiceTile(
                  size: 80,
                  color: Colors.white,
                  onTap: () async {
                    final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => SpellDialog(
                              parts: w.$2,
                              emoji: w.$3,
                              title: '${w.$2.join()} yaz, hava değişsin!',
                              speech: '${trCapitalize(w.$2.join())} yaz, hava değişsin!',
                            ));
                    if (ok == true && context.mounted) Navigator.pop(context, w.$1);
                  },
                  child: Column(children: [Text(w.$3, style: const TextStyle(fontSize: 40)), SylText(w.$2.join(), size: 20)]),
                ),
            ]),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç', style: TextStyle(fontSize: 16))),
          ]),
        ),
      );
}

// ================= KONUŞAN TABELA =================

/// Tabelaya yazılacak kelimeyi seçtirir, sonra heceleterek yazdırır.
class SignDialog extends StatelessWidget {
  const SignDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final options = <(List<String>, String)>[
      for (final r in recipesNow()) (r.parts, r.emoji),
      (['ev'], '🏠'),
      (['an', 'ne'], '👩'),
      (['ba', 'ba'], '👨'),
      (['ka', 'le'], '🏰'),
    ];
    final seen = <String>{};
    final uniq = [
      for (final o in options)
        if (seen.add(o.$1.join()) && o.$1.join().split('').every(lettersFor(max(2, game.letterGroup)).contains)) o
    ];
    return Dialog(
      backgroundColor: const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🪧 Tabelaya ne yazalım?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            width: 300,
            child: GridView.count(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
              for (final o in uniq)
                Bouncy(
                  onTap: () async {
                    final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => SpellDialog(
                              parts: o.$1,
                              emoji: o.$2,
                              title: 'Tabelaya yaz: ${o.$1.join()}',
                              speech: 'Tabelaya ${o.$1.join()} yaz!',
                            ));
                    if (ok == true && context.mounted) Navigator.pop(context, o.$1.join());
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(o.$2, style: const TextStyle(fontSize: 32)),
                      FittedBox(child: SylText(o.$1.join(), size: 16)),
                    ]),
                  ),
                ),
            ]),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç', style: TextStyle(fontSize: 16))),
        ]),
      ),
    );
  }
}
