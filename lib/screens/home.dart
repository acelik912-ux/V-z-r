import 'package:flutter/material.dart';

import '../art.dart';
import '../car3d/car_view.dart';
import '../games/blok.dart';
import '../games/registry.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'album.dart';
import 'garage.dart';
import 'map.dart';
import 'name_entry.dart';
import 'parent.dart';
import 'race.dart';
import 'stories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _welcome());
  }

  Future<void> _welcome() async {
    if (game.driverName.isEmpty) {
      final n = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const NameEntryScreen(
            prompt: 'Senin adın ne?',
            speech: 'Merhaba! Vızır Adasına hoş geldin. Senin adın ne? Harflere dokunarak yaz.',
          ),
        ),
      );
      if (!mounted) return;
      if (n != null && n.isNotEmpty) game.setDriver(n);
      final c = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const NameEntryScreen(prompt: 'Arabana bir isim ver!')),
      );
      if (!mounted) return;
      if (c != null && c.isNotEmpty) game.setCar(c);
      Voice.say('Hoş geldin ${game.driverName}! Haydi garaja gidip arabanı hazırlayalım.');
    } else {
      Voice.say('Selamün aleyküm ${game.driverName}!');
    }
  }

  void _go(Widget screen, String label) {
    Voice.say(label);
    go(context, screen).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDeco('ana_ekran'),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(children: [RewardBar(), Spacer(), FuelGauge()]),
                ),
                const Text(
                  'Vızır',
                  style: TextStyle(
                    fontSize: 58,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0xFFE53935), offset: Offset(3, 3)),
                      Shadow(color: Colors.black38, offset: Offset(4, 6), blurRadius: 6),
                    ],
                  ),
                ),
                const Text(
                  'Hız ve Macera Adası',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(flex: 2, child: Pic('k_surucu')),
                      Expanded(
                        flex: 5,
                        child: GestureDetector(
                          onTap: () {
                            Sfx.horn(game.config.horn);
                            Voice.say(game.carName.isEmpty ? 'Arabamız hazır!' : '${game.carName} hazır!');
                          },
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            SpinningCar(game.config, width: 230),
                            if (game.carName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white.withAlpha(210), borderRadius: BorderRadius.circular(12)),
                                child: Text(game.carName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                              ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                _tasksBanner(),
                Expanded(
                  flex: 9,
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: [
                      PicCard(pic: 'm_macera', label: 'Macera', color: const Color(0xFF43A047), onTap: () => _go(const MapScreen(), 'Macera adası')),
                      PicCard(pic: 'm_yaris', label: 'Yarış', color: const Color(0xFFE53935), onTap: () => _go(const RaceScreen(), 'Yarış')),
                      PicCard(pic: 'm_garaj', label: 'Garaj', color: const Color(0xFF546E7A), onTap: () => _go(const GarageScreen(), 'Garaj')),
                      PicCard(
                        pic: 'd_saman',
                        label: 'Blok Şehri',
                        color: const Color(0xFF8D6E63),
                        onTap: () => _go(blokGame.build(), 'Blok Şehri'),
                        child: const BlockLogo(),
                      ),
                      PicCard(pic: 'm_kitap', label: 'Hikâyeler', color: const Color(0xFF8E24AA), onTap: () => _go(const StoryShelf(), 'Hikâye kitabım')),
                      PicCard(
                        pic: 'i_yildiz',
                        label: 'Albüm',
                        color: const Color(0xFFF06292),
                        onTap: () => _go(const AlbumScreen(), 'Çıkartma albümü'),
                        badge: Text('${game.stickers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const ParentButton(dark: true),
                    const Spacer(),
                    if (game.driverName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text('Sürücü: ${game.driverName}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                              Shadow(color: Colors.black54, blurRadius: 3),
                            ])),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tasksBanner() {
    final tasks = todayTasks();
    final done = tasks.where((t) => game.taskClaimed.contains(t.id)).length;
    final ready = tasksReady();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Bouncy(
        onTap: () async {
          await showDailyTasks(context);
          if (mounted) setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ready > 0 ? const Color(0xFFFFD54F) : Colors.white.withAlpha(225),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(children: [
            const Text('📋', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Günün görevleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            for (final t in tasks)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(opacity: taskDone(t) ? 1 : 0.35, child: Text(t.emoji, style: const TextStyle(fontSize: 22))),
              ),
            const SizedBox(width: 6),
            Text('$done/3', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}
