import 'package:flutter/material.dart';

import '../car3d/car_view.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'garage.dart';
import 'name_entry.dart';
import 'parent.dart';
import 'race.dart';

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
    Sfx.play('click');
    Voice.say(label);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _soon(String label) => Voice.say('$label yakında açılacak!');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC), Color(0xFF9CCC65)],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(children: [RewardBar(), Spacer(), FuelGauge()]),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vızır',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Color(0xFFE53935), offset: Offset(3, 3), blurRadius: 0)],
                  ),
                ),
                const Text(
                  'Hız ve Macera Adası',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Sfx.horn(game.config.horn);
                    Voice.say(game.carName.isEmpty ? 'Arabamız hazır!' : '${game.carName} hazır!');
                  },
                  child: SpinningCar(game.config, width: 250),
                ),
                if (game.carName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(game.carName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                  ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      BigButton(
                        label: 'Garaj',
                        icon: Icons.build,
                        color: const Color(0xFF546E7A),
                        onTap: () => _go(const GarageScreen(), 'Garaj'),
                      ),
                      BigButton(
                        label: 'Yarış',
                        icon: Icons.flag,
                        color: const Color(0xFFE53935),
                        onTap: () => _go(const RaceScreen(), 'Yarış'),
                      ),
                      BigButton(
                        label: 'Macera',
                        icon: Icons.explore,
                        color: const Color(0xFF43A047),
                        locked: true,
                        onTap: () => _soon('Macera'),
                      ),
                      BigButton(
                        label: 'Hikâye\nKitabım',
                        icon: Icons.menu_book,
                        color: const Color(0xFF8E24AA),
                        locked: true,
                        onTap: () => _soon('Hikâye kitabım'),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: openParentPanel,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.settings, color: Colors.black26),
                      ),
                    ),
                    const Spacer(),
                    if (game.driverName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text('Sürücü: ${game.driverName}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}
