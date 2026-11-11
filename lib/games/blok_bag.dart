import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import 'blok.dart';
import 'blok_char.dart';
import 'blok_life.dart';
import 'blok_shapes.dart';

/// Çantadaki bir şey
class BagItem {
  final String id; // blok id, seed_x, p_x, shape:N, zirh_x
  final String name;
  final Widget icon;
  final bool locked;
  final int price;
  const BagItem(this.id, this.name, this.icon, this.locked, {this.price = 0});
}

bool bagUnlocked(String id) {
  if (id.startsWith('shape:')) {
    final n = int.parse(id.substring(6));
    return n <= 1 || game.blockItems.contains('shape_${shapes[n].key}');
  }
  if (id.startsWith('seed_')) return const {'seed_havuc', 'seed_marul'}.contains(id) || game.blockItems.contains(id);
  if (id.startsWith('p_')) return const {'p_agac', 'p_ev', 'p_yol', 'p_kopru'}.contains(id) || game.blockItems.contains(id);
  if (id.startsWith('zirh_')) return game.blockItems.contains(id);
  final m = matIndex(id);
  if (m >= 0 && mats[m].start) return true;
  return game.blockItems.contains(id);
}

List<(String, List<BagItem>)> bagSections() {
  BagItem mat(BlockMat m) => BagItem(m.id, m.name, MatSwatch(m), !bagUnlocked(m.id));
  List<BagItem> tab(int t) => [for (final m in mats) if (m.tab == t) mat(m)];
  return [
    ('🪵 Ahşap', tab(7)),
    ('🧱 Yapı', tab(0)),
    ('🔷 Şekiller', [
      for (final sh in shapes)
        BagItem('shape:${sh.id}', sh.name, Center(child: Text(sh.emoji, style: const TextStyle(fontSize: 30))), !bagUnlocked('shape:${sh.id}'))
    ]),
    ('🎨 Renkler', tab(1)),
    ('🌳 Doğa', tab(2)),
    ('💡 Işıklar', tab(6)),
    ('✨ Özel', tab(3)),
    ('🌱 Bahçe', [
      mat(mats[matIndex('tarla')]),
      for (final c in crops)
        BagItem('seed_${c.id}', c.name, Center(child: Text(c.emoji, style: const TextStyle(fontSize: 30))), !bagUnlocked('seed_${c.id}')),
    ]),
    ('🏠 Hazır yapılar', [
      for (final p in prefabs)
        BagItem(p.id, p.name, Center(child: Text(p.emoji, style: const TextStyle(fontSize: 30))), !bagUnlocked(p.id)),
    ]),
    ('🛒 Pazar (zırhlar)', [
      for (final a in armors)
        BagItem('zirh_${a.id}', a.name, Center(child: Icon(Icons.shield, size: 36, color: a.color)), !bagUnlocked('zirh_${a.id}'),
            price: a.price),
    ]),
  ];
}

/// Tam ekran çanta. Seçilen şeyin kimliğini döndürür.
class BagScreen extends StatefulWidget {
  final String selected;
  final int shape;
  const BagScreen({super.key, required this.selected, required this.shape});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  @override
  void initState() {
    super.initState();
    Voice.say('Çantan! Bir şey seç. Kilitli olanları açmak için adını hecelerle yaz.');
  }

  Future<void> _tap(BagItem it) async {
    Sfx.play('click');
    if (it.id.startsWith('zirh_')) {
      final idx = armors.indexWhere((a) => 'zirh_${a.id}' == it.id) + 1;
      if (!it.locked) {
        final av = myAvatar..armor = idx;
        game.setAvatar(av.encode());
        Voice.say('${it.name} giydin!');
        if (mounted) Navigator.pop(context, null);
        return;
      }
      if (game.coins < it.price) {
        Voice.say('${it.name} ${it.price} altın. Senin ${game.coins} altının var. Hasat yaparak, hayvanlara bakarak altın kazan!');
        _toast('${it.price} 🪙 gerekli, sende ${game.coins} 🪙 var');
        return;
      }
    }
    if (it.locked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
          parts: heceler(it.name),
          emoji: it.id.startsWith('zirh_') ? '🛡️' : '🔒',
          title: it.price > 0 ? '${it.price} 🪙 ile almak için adını yaz' : 'Açmak için adını yaz',
          speech: '${it.name}. Açmak için adını hecelerle yaz!',
        ),
      );
      if (ok != true || !mounted) return;
      if (it.price > 0 && !game.spendCoins(it.price)) return;
      final key = it.id.startsWith('shape:') ? 'shape_${shapes[int.parse(it.id.substring(6))].key}' : it.id;
      game.addBlockItem(key);
      Sfx.play('unlock');
      if (it.id.startsWith('zirh_')) {
        final idx = armors.indexWhere((a) => 'zirh_${a.id}' == it.id) + 1;
        final av = myAvatar..armor = idx;
        game.setAvatar(av.encode());
        Voice.say('${it.name} senin! Hemen giydin.');
        if (mounted) Navigator.pop(context, null);
        return;
      }
    }
    if (mounted) Navigator.pop(context, it.id);
  }

  void _toast(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t, style: const TextStyle(fontSize: 18)), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final secs = bagSections();
    return Scaffold(
      backgroundColor: const Color(0xFF6D4C41),
      body: SafeArea(
        child: Column(children: [
          TopBar('🎒 Çantam',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text('🪙 ${game.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              )),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF3E2723), width: 4),
              ),
              child: CustomScrollView(slivers: [
                for (final sec in secs) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Text(sec.$1, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.78),
                      delegate: SliverChildListDelegate([
                        for (final it in sec.$2)
                          Bouncy(
                            onTap: () => _tap(it),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: (it.id == widget.selected || it.id == 'shape:${widget.shape}')
                                    ? const Color(0xFFFFF59D)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: (it.id == widget.selected || it.id == 'shape:${widget.shape}') ? Colors.orange : Colors.black12,
                                    width: 2),
                              ),
                              child: Column(children: [
                                Expanded(
                                  child: Stack(children: [
                                    Positioned.fill(child: Opacity(opacity: it.locked ? 0.35 : 1, child: it.icon)),
                                    if (it.locked)
                                      const Positioned(right: 0, top: 0, child: Text('🔒', style: TextStyle(fontSize: 16))),
                                  ]),
                                ),
                                Text(it.name,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.05)),
                                if (it.price > 0)
                                  Text('🪙 ${it.price}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                              ]),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
