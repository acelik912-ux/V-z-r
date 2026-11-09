import 'package:flutter/material.dart';

import '../car_painter.dart';
import '../state.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'name_entry.dart';
import 'race.dart';
import 'repair.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Voice.say('Garaja hoş geldin! Arabanı istediğin gibi hazırla.');
    });
  }

  List<String> _names(String kind) => kind == 'body' ? bodyNames : (kind == 'color' ? colorNames : wheelNames);

  Future<void> _pick(String kind, int i) async {
    final names = _names(kind);
    if (game.isUnlocked(kind, i)) {
      game.setPart(kind, i);
      Voice.say(names[i]);
      return;
    }
    final req = game.reqsFor(kind)[i];
    if (!game.reqMet(req)) {
      Voice.say(reqText(req));
      return;
    }
    Voice.say('Bu parça kilitli. Tamirci Usta hece tamiri istiyor!');
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const RepairScreen()));
    if (!mounted) return;
    if (ok == true) {
      game.unlock(kind, i);
      game.setPart(kind, i);
      Voice.say('Yeni parça takıldı! ${names[i]}');
    }
  }

  Future<void> _renameCar() async {
    final n = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => NameEntryScreen(prompt: 'Arabana bir isim ver!', initial: game.carName)),
    );
    if (n != null && n.isNotEmpty) game.setCar(n);
  }

  Future<void> _rivals() async {
    Voice.say('Rakiplerine isim verebilirsin.');
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: game,
        builder: (ctx, _) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Rakipler', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              for (var i = 0; i < game.rivalNames.length; i++)
                ListTile(
                  leading: SizedBox(width: 28, height: 49, child: CarView(_rivalSpec(i), width: 28)),
                  title: Text(game.rivalNames[i], style: const TextStyle(fontSize: 22)),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final n = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => NameEntryScreen(prompt: 'Rakibin adı ne olsun?', initial: game.rivalNames[i]),
                      ),
                    );
                    if (n != null && n.isNotEmpty) game.setRival(i, n);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF90A4AE),
        title: const Text('Garaj', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
        actions: const [Padding(padding: EdgeInsets.only(right: 8), child: RewardBar())],
      ),
      body: ListenableBuilder(
        listenable: game,
        builder: (context, _) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: CarView(game.spec, width: 110),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => Voice.say(game.carName.isEmpty ? 'Arabanın adı yok' : 'Arabanın adı ${game.carName}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF59D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black87, width: 2),
                    ),
                    child: game.carName.isEmpty
                        ? const Text('İSİMSİZ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                        : SylText(game.carName, size: 28),
                  ),
                ),
              ),
              _section('Gövde', 'body', bodyNames.length,
                  (i) => CarView(CarSpec(i, game.color, game.wheel), width: 36)),
              _section('Renk', 'color', carColors.length,
                  (i) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: carColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 2),
                        ),
                      )),
              _section('Tekerlek', 'wheel', wheelNames.length,
                  (i) => CarView(CarSpec(game.body, game.color, i), width: 36)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _renameCar,
                        icon: const Icon(Icons.edit),
                        label: const Text('Arabanın adı', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _rivals,
                        icon: const Icon(Icons.groups),
                        label: const Text('Rakipler', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: () {
                      Voice.say('Yarışa gidiyoruz!');
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RaceScreen()));
                    },
                    icon: const Icon(Icons.flag, size: 30),
                    label: const Text('Yarışa git', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String kind, int count, Widget Function(int) preview) {
    final reqs = game.reqsFor(kind);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: count,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final open = game.isUnlocked(kind, i);
                final sel = game.selected(kind) == i;
                return GestureDetector(
                  onTap: () => _pick(kind, i),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sel ? const Color(0xFFE53935) : Colors.black12, width: sel ? 4 : 2),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Opacity(opacity: open ? 1 : 0.35, child: preview(i))),
                        if (!open) ...[
                          const Positioned(top: 4, right: 6, child: Icon(Icons.lock, size: 22, color: Colors.black54)),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 4,
                            child: Text(
                              reqShort(reqs[i]),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: game.reqMet(reqs[i]) ? Colors.green.shade800 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

CarSpec _rivalSpec(int i) => CarSpec(i % 3, const [6, 4, 2][i % 3], 0);
CarSpec rivalSpec(int i) => _rivalSpec(i);
