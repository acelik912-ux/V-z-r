import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import 'blok.dart';
import 'blok_bag.dart';
import 'kit.dart';

// ================= KÖY: Komşu Teyze ve Gezgin =================

/// Ürün: (ad, emoji, fiyat)
const productInfo = <String, (String, String, int)>{
  'süt': ('süt', '🥛', 4),
  'yün': ('yün', '🧶', 5),
  'yumurta': ('yumurta', '🥚', 3),
  'havuc': ('havuç', '🥕', 2),
  'domates': ('domates', '🍅', 3),
  'bugday': ('buğday', '🌾', 2),
  'misir': ('mısır', '🌽', 3),
  'patlican': ('patlıcan', '🍆', 4),
  'marul': ('marul', '🥬', 2),
};

(String, String, int) infoOf(String id) => productInfo[id] ?? (id, '🧺', 2);

/// İkramdan sonra Blok Şehri'nde açacak çiçek sayısı.
int pendingBloom = 0;

class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Say.show(context, Who.teyze, 'Hoş geldin evladım! Pazarda satış yapalım mı, yoksa komşulara yardım mı edelim?');
    });
  }

  Widget _card(String pic, String title, String sub, Color c, VoidCallback onTap) => Bouncy(
        onTap: onTap,
        child: Container(
          height: 116,
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Row(children: [
            SizedBox(width: 84, child: Pic(pic, height: 104)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(sub, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
              ]),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF8BC34A),
        body: SafeArea(
          child: Column(children: [
            TopBar('🏡 Köy',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text('🪙 ${game.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                )),
            Expanded(
              child: ListView(children: [
                _card('k_teyze', '🧺 Pazar tezgâhı', 'Ürünlerini sat, para üstünü ver', const Color(0xFFFFE0B2), () async {
                  await Navigator.push(context, fadeRoute(const MarketScreen()));
                  if (mounted) setState(() {});
                }),
                _card('k_teyze_tesekkur', '💝 İkram kutusu', 'Komşularla paylaş, şehir çiçek açsın', const Color(0xFFF8BBD0), () async {
                  await Navigator.push(context, fadeRoute(const ShareScreen()));
                  if (mounted) setState(() {});
                }),
                _card('k_teyze_dusun', '🧱 Komşuya yardım', 'Kaç blok lazım? Hesapla, yardım et', const Color(0xFFB3E5FC), () async {
                  await showDialog(context: context, barrierDismissible: false, builder: (_) => const HelpQuiz());
                  if (mounted) setState(() {});
                }),
                _card('k_gezgin', '🎨 Gezgin: İngilizce', 'Renkler ve hayvanlar: red, blue, cat...', const Color(0xFFDCEDC8), () async {
                  await showDialog(context: context, barrierDismissible: false, builder: (_) => const EnglishQuiz());
                  if (mounted) setState(() {});
                }),
              ]),
            ),
          ]),
        ),
      );
}

// ---------------- Pazar ----------------

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  Future<void> _sell(String id) async {
    final (name, emoji, price) = infoOf(id);
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => ChangeDialog(name: name, emoji: emoji, price: price));
    if (ok != true || !mounted) return;
    if (!game.takeProduct(id)) return;
    game.addCoins(price);
    game.countToday('satis');
    setState(() {});
    Sfx.play('coin');
    Say.show(context, Who.teyze, 'Teşekkür ederim evladım, Allah razı olsun! $price altın senin.', mood: 'tesekkur');
  }

  @override
  Widget build(BuildContext context) {
    final items = game.products.entries.toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFFCC80),
      body: SafeArea(
        child: Column(children: [
          TopBar('🧺 Pazar',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text('🪙 ${game.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              )),
          SizedBox(height: 150, child: Pic('k_teyze_sevin', height: 150)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Satacak ürünün yok. Hayvanlarından süt, yün, yumurta al; tarladan hasat yap, sonra gel!',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(12),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final e in items)
                  Bouncy(
                    onTap: () => _sell(e.key),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(infoOf(e.key).$2, style: const TextStyle(fontSize: 40)),
                        Text('${infoOf(e.key).$1} ×${e.value}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text('🪙 ${infoOf(e.key).$3}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Teyze 10 altın verir, çocuk para üstünü seçer. Yanlışta ceza yok, ipucu var.
class ChangeDialog extends StatefulWidget {
  final String name;
  final String emoji;
  final int price;
  const ChangeDialog({super.key, required this.name, required this.emoji, required this.price});

  @override
  State<ChangeDialog> createState() => _ChangeDialogState();
}

class _ChangeDialogState extends State<ChangeDialog> {
  late final List<int> options;
  int wrong = 0;
  int shake = 0;
  bool done = false;
  int get answer => 10 - widget.price;

  @override
  void initState() {
    super.initState();
    final s = <int>{answer};
    final r = Random();
    while (s.length < 3) {
      final v = answer + r.nextInt(5) - 2;
      if (v >= 0 && v <= 10) s.add(v);
    }
    options = s.toList()..shuffle(r);
    Voice.say('${trCapitalize(widget.name)} ${widget.price} altın. Teyze sana 10 altın verdi. Ona kaç altın geri verirsin?');
  }

  void _pick(int v) {
    if (done) return;
    if (v == answer) {
      done = true;
      Sfx.play('correct');
      Voice.say('Evet! 10 eksi ${widget.price}, $answer eder.');
      setState(() {});
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      wrong++;
      Sfx.play('wrong', volume: 0.6);
      setState(() => shake++);
      Voice.say(wrong >= 2 ? 'Sarı altınlar ${widget.name} için. Geriye kalan beyaz altınları say!' : 'Bir daha say bakalım.');
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 46)),
              const SizedBox(width: 8),
              Text('= ${widget.price} 🪙', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 6),
            const Text('Teyze 10 altın verdi:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
              for (var i = 0; i < 10; i++)
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < widget.price
                        ? const Color(0xFFFFC107)
                        : (wrong >= 2 || done ? const Color(0xFFFFFFFF) : const Color(0xFFFFE082)),
                    border: Border.all(color: const Color(0xFFE65100), width: 2),
                  ),
                  child: Text(i < widget.price ? widget.emoji : (wrong >= 2 || done ? '${i - widget.price + 1}' : ''),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
            ]),
            const SizedBox(height: 12),
            const Text('Kaç altın geri verirsin?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Shake(
              trigger: shake,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final o in options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceTile(
                      size: 70,
                      color: done && o == answer ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                      onTap: () => _pick(o),
                      child: Text('$o', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ]),
            ),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç', style: TextStyle(fontSize: 16))),
          ]),
        ),
      );
}

// ---------------- İkram kutusu ----------------

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

const _needy = [
  ('Hasta komşumuz', 'Hasta komşumuz çok sevinecek. Geçmiş olsun dileriz!'),
  ('Yaşlı dede', 'Yaşlı dede dua etti: Allah seni her zaman mutlu etsin!'),
  ('Yeni gelen komşular', 'Yeni komşular hoş geldin ikramına çok sevindi!'),
  ('Kuşlar ve kediler', 'Hayvanlara iyilik de sadakadır. Kuşlar cıvıl cıvıl öttü!'),
];

class _ShareScreenState extends State<ShareScreen> {
  final r = Random();
  late (String, String) who = _needy[r.nextInt(_needy.length)];

  void _give(String id) {
    if (!game.takeProduct(id)) return;
    game.addHeart();
    game.countToday('iyilik');
    pendingBloom += 6;
    Sfx.play('heart');
    final msg = who.$2;
    setState(() => who = _needy[r.nextInt(_needy.length)]);
    Say.show(context, Who.teyze, '$msg Paylaştıkça bereket artar; şehrinde çiçekler açacak!', mood: 'sevin');
  }

  @override
  Widget build(BuildContext context) {
    final items = game.products.entries.toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8BBD0),
      body: SafeArea(
        child: Column(children: [
          TopBar('💝 İkram kutusu'),
          SizedBox(height: 140, child: Pic('k_teyze_tesekkur', height: 140)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('${who.$1} için bir şey seç:', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Paylaşacak ürünün yok. Önce hayvanlarından ya da tarlandan ürün topla.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(12),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final e in items)
                  Bouncy(
                    onTap: () => _give(e.key),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(infoOf(e.key).$2, style: const TextStyle(fontSize: 40)),
                        Text('${infoOf(e.key).$1} ×${e.value}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------- Komşuya yardım (eksik blok hesabı) ----------------

class HelpQuiz extends StatefulWidget {
  const HelpQuiz({super.key});

  @override
  State<HelpQuiz> createState() => _HelpQuizState();
}

class _HelpQuizState extends State<HelpQuiz> {
  final r = Random();
  int round = 0;
  late int need, have;
  late String what, emoji;
  late List<int> options;
  int shake = 0, wrong = 0;
  bool done = false;

  static const jobs = [
    ('köprü', '🌉', 'tahta'),
    ('duvar', '🧱', 'tuğla'),
    ('çit', '🪵', 'çit'),
    ('kule', '🗼', 'taş'),
  ];

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final j = jobs[r.nextInt(jobs.length)];
    need = 4 + r.nextInt(7); // 4..10
    have = 1 + r.nextInt(need - 1);
    what = j.$1;
    emoji = j.$2;
    final ans = need - have;
    final s = <int>{ans};
    while (s.length < 3) {
      final v = ans + r.nextInt(5) - 2;
      if (v >= 0 && v <= 10) s.add(v);
    }
    options = s.toList()..shuffle(r);
    wrong = 0;
    done = false;
    Voice.say('Teyzenin $what için $need blok lazım. $have tanesini koydu. Kaç blok daha lazım?');
  }

  void _pick(int v) {
    if (done) return;
    if (v == need - have) {
      done = true;
      Sfx.play('correct');
      game.addCoins(2);
      Voice.say('Doğru! $need eksi $have, ${need - have}. Teşekkürler!');
      setState(() {});
      Future.delayed(const Duration(milliseconds: 1700), () {
        if (!mounted) return;
        if (++round >= 3) {
          game.addHeart();
          game.countToday('iyilik');
          Navigator.pop(context);
        } else {
          setState(_next);
        }
      });
    } else {
      wrong++;
      Sfx.play('wrong', volume: 0.6);
      setState(() => shake++);
      Voice.say(wrong >= 2 ? 'Boş kutuları say!' : 'Bir daha bakalım.');
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFE1F5FE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              SizedBox(width: 70, height: 90, child: Pic(done ? 'k_teyze_sevin' : 'k_teyze_dusun', height: 90)),
              Expanded(
                child: Text('$emoji $what: $need blok lazım, $have tane var. Kaç tane daha?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
              for (var i = 0; i < need; i++)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: i < have ? const Color(0xFFA1887F) : (done ? const Color(0xFF81C784) : Colors.white),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF5D4037), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(i < have ? '' : (wrong >= 2 || done ? '${i - have + 1}' : '?'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ),
            ]),
            const SizedBox(height: 10),
            Shake(
              trigger: shake,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final o in options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceTile(
                      size: 70,
                      color: const Color(0xFF81D4FA),
                      onTap: () => _pick(o),
                      child: Text('$o', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ]),
            ),
            Text('${round + 1} / 3', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat', style: TextStyle(fontSize: 16))),
          ]),
        ),
      );
}

// ---------------- Gezgin: İngilizce ----------------

/// (İngilizce, Türkçe, gösterim, açtığı renk bloğu)
const _colorQs = [
  ('red', 'kırmızı', Color(0xFFE53935), 'kirmizi'),
  ('blue', 'mavi', Color(0xFF1E88E5), 'mavi'),
  ('green', 'yeşil', Color(0xFF43A047), 'yesil'),
  ('yellow', 'sarı', Color(0xFFFDD835), 'sari'),
  ('orange', 'turuncu', Color(0xFFFB8C00), 'turuncu'),
  ('purple', 'mor', Color(0xFF8E24AA), 'mor'),
  ('pink', 'pembe', Color(0xFFF48FB1), 'pembe'),
  ('black', 'siyah', Color(0xFF37373F), 'siyah'),
];
const _animalQs = [
  ('cat', 'kedi', '🐱'),
  ('dog', 'köpek', '🐶'),
  ('cow', 'inek', '🐄'),
  ('sheep', 'koyun', '🐑'),
  ('horse', 'at', '🐴'),
  ('chicken', 'tavuk', '🐔'),
  ('bird', 'kuş', '🐦'),
  ('fish', 'balık', '🐟'),
];

class EnglishQuiz extends StatefulWidget {
  const EnglishQuiz({super.key});

  @override
  State<EnglishQuiz> createState() => _EnglishQuizState();
}

class _EnglishQuizState extends State<EnglishQuiz> {
  final r = Random();
  int round = 0, correct = 0, shake = 0;
  bool color = true, done = false;
  late int ans;
  late List<int> opts;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    color = r.nextBool();
    final n = color ? _colorQs.length : _animalQs.length;
    final idx = List.generate(n, (i) => i)..shuffle(r);
    opts = idx.take(4).toList();
    ans = opts[r.nextInt(4)];
    done = false;
    _sayWord();
  }

  void _sayWord() {
    Voice.sayEn(color ? _colorQs[ans].$1 : _animalQs[ans].$1);
  }

  void _pick(int i) {
    if (done) return;
    if (i == ans) {
      done = true;
      correct++;
      Sfx.play('correct');
      game.addCoins(1);
      final en = color ? _colorQs[ans].$1 : _animalQs[ans].$1;
      final tr = color ? _colorQs[ans].$2 : _animalQs[ans].$2;
      var extra = '';
      if (color) {
        final id = _colorQs[ans].$4;
        if (!bagUnlocked(id) && matIndex(id) >= 0) {
          game.addBlockItem(id);
          extra = ' $tr blok çantana girdi!';
        }
      }
      Voice.sayEn(en);
      Future.delayed(const Duration(milliseconds: 1100), () => Voice.say('$tr!$extra'));
      setState(() {});
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (!mounted) return;
        if (++round >= 5) {
          Navigator.pop(context);
        } else {
          setState(_next);
        }
      });
    } else {
      Sfx.play('wrong', volume: 0.6);
      setState(() => shake++);
      Future.delayed(const Duration(milliseconds: 300), _sayWord);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFF1F8E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              SizedBox(width: 70, height: 96, child: Pic(done ? 'k_gezgin_sevin' : 'k_gezgin_gosterir', height: 96)),
              Expanded(
                child: Bouncy(
                  onTap: _sayWord,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.volume_up, size: 34),
                      const SizedBox(width: 6),
                      Text(done ? (color ? _colorQs[ans].$1 : _animalQs[ans].$1) : '?',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Shake(
              trigger: shake,
              child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                for (final i in opts)
                  Bouncy(
                    onTap: () => _pick(i),
                    child: Container(
                      width: 104,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color ? _colorQs[i].$3 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: done && i == ans ? const Color(0xFF2E7D32) : Colors.black26, width: done && i == ans ? 5 : 2),
                      ),
                      child: color ? null : Text(_animalQs[i].$3, style: const TextStyle(fontSize: 50)),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            Text('${round + 1} / 5   ⭐ $correct', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat', style: TextStyle(fontSize: 16))),
          ]),
        ),
      );
}
