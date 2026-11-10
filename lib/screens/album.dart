import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../games/registry.dart';
import '../screens/map.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';

/// Çıkartma -> nasıl kazanılır.
const stickerHints = <String, String>{
  'arac_10': 'Hece Kamyonu: 3 yıldız',
  'd_saman': 'Araba Yıkama: 3 yıldız',
  'k_robot': 'Köprü Kur: 3 yıldız',
  'd_tas': 'Tünel Kazısı: 3 yıldız',
  'k_tozbulut_gul': 'Hayvan Kurtarma: 3 yıldız',
  'k_baykus_okur': 'Hafıza Kartları: 3 yıldız',
  'k_papagan': 'Gemi Yükle: 3 yıldız',
  'i_kupa': 'Balık Tut: 3 yıldız',
  'm_kitap': 'Uçan Araba: 3 yıldız',
  'arac_9': 'Otopark 4. bölüm: 3 yıldız',
  'i_benzin': 'Trafik Kuralları: 3 yıldız',
  'i_kalp': 'İyilik Teslimatı: 3 yıldız',
  'i_yildiz': 'Yarışta birinci ol',
  'k_surucu': 'Günün görevlerini bitir',
  'k_tamirci_sevin': 'Blok Şehri: bütün görevler',
  'd_lale': 'Hikâye: Yarım Elma',
  'd_pembe': 'Hikâye: Kırık Ayna',
  'd_agac': 'Hikâye: Bismillah',
  'd_meyve': 'Hikâye: Yavru Kedi',
  'd_cam': 'Hikâye: Ayşe Nine',
};

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ids = stickerHints.keys.toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7E57C2), Color(0xFFF8BBD0)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            TopBar('Çıkartma Albümü',
                trailing: Text('${game.stickers.length}/${ids.length}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white))),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(14),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: [
                  for (final id in ids)
                    Bouncy(
                      onTap: () {
                        Sfx.play('kart');
                        Voice.say(game.stickers.contains(id) ? 'Bu çıkartma sende var!' : stickerHints[id]!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(game.stickers.contains(id) ? 240 : 120),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Column(children: [
                          Expanded(
                            child: game.stickers.contains(id)
                                ? Pic(id)
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(Color(0x55000000), BlendMode.srcIn),
                                    child: Pic(id),
                                  ),
                          ),
                          Text(game.stickers.contains(id) ? '✓' : stickerHints[id]!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ======================= GÜNÜN GÖREVLERİ =======================

class DailyTask {
  final String id;
  final String title;
  final String emoji;
  const DailyTask(this.id, this.title, this.emoji);
}

List<DailyTask> todayTasks() {
  final pool = <DailyTask>[
    for (final r in regions)
      if (regionOpen(r))
        for (final g in r.games) DailyTask(g.id, g.title, g.emoji),
    const DailyTask('blok', 'Blok Şehri', '🧱'),
    const DailyTask('hikaye', 'Bir hikâye oku', '📖'),
  ];
  final rnd = Random(game.dayKey.hashCode);
  pool.shuffle(rnd);
  return pool.take(3).toList();
}

bool taskDone(DailyTask t) => game.todayPlayed.any((p) => p == t.id || p.startsWith('${t.id}_'));

int tasksReady() => todayTasks().where((t) => taskDone(t) && !game.taskClaimed.contains(t.id)).length;

Future<void> showDailyTasks(BuildContext context) async {
  Voice.say('Günün görevleri! Üç görevi bitir, ödülünü al.');
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final tasks = todayTasks();
      final all = tasks.every((t) => game.taskClaimed.contains(t.id));
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8E1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Günün Görevleri', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final t in tasks)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Text(t.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 10),
                Expanded(child: Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                if (game.taskClaimed.contains(t.id))
                  const Icon(Icons.check_circle, color: Colors.green, size: 34)
                else if (taskDone(t))
                  FilledButton(
                    onPressed: () {
                      game.claimTask(t.id);
                      Sfx.play('unlock');
                      Voice.say('Bir yıldız kazandın!');
                      if (todayTasks().every((x) => game.taskClaimed.contains(x.id))) game.addSticker('k_surucu');
                      setS(() {});
                    },
                    child: const Text('Ödül ⭐', style: TextStyle(fontSize: 18)),
                  )
                else
                  const Icon(Icons.radio_button_unchecked, color: Colors.black26, size: 30),
              ]),
            ),
          if (all)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Hepsi tamam! Maşallah! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green)),
            ),
          const SizedBox(height: 12),
        ]),
      );
    }),
  );
}
