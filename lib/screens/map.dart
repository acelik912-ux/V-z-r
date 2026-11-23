import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../games/kit.dart';
import '../games/registry.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';

const _mapSize = Size(720, 1290);
String _lastRegion = 'hece';

bool regionOpen(Region r) => game.adventureStars >= r.need;

/// Macera Adası haritası: bölgeler, yıldızlar ve kilitler.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final AnimationController bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Burası Vızır Adası! Bir bölgeye dokun, maceraya başlayalım.', mood: 'iyi');
    });
  }

  @override
  void dispose() {
    bob.dispose();
    super.dispose();
  }

  Future<void> _open(Region r) async {
    if (!regionOpen(r)) {
      Sfx.play('wrong');
      Say.show(context, r.who, '${r.name} için ${r.need} macera yıldızı lazım. Şu an ${game.adventureStars} yıldızın var.');
      return;
    }
    setState(() => _lastRegion = r.id);
    Voice.say(r.name);
    await go(context, RegionScreen(r));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDeco('ada_harita'),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            final pad = MediaQuery.of(context).padding;
            // SafeArea içindeki konuma göre resim noktasını hesapla
            final full = Size(size.width, size.height + pad.top + pad.bottom);
            Offset at(Offset p) => coverPoint(full, _mapSize, p) - Offset(0, pad.top);
            final last = regions.firstWhere((r) => r.id == _lastRegion, orElse: () => regions.first);
            return Stack(children: [
              for (final r in regions) _pin(r, at(r.at)),
              _blokPin(at(const Offset(500, 1030))),
              AnimatedBuilder(
                animation: bob,
                builder: (_, __) {
                  final p = at(last.at);
                  return Positioned(
                    left: p.dx - 30,
                    top: p.dy - 100 + sin(bob.value * 2 * pi) * 5,
                    child: IgnorePointer(child: Pic('arac_${game.selected('body')}', width: 60)),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: TopBar('Macera Adası',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(225), borderRadius: BorderRadius.circular(18)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Pic('i_yildiz', width: 24, height: 24),
                        Text(' ${game.adventureStars}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ]),
                    )),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _pin(Region r, Offset p) {
    final open = regionOpen(r);
    final stars = regionStars(r);
    final maxStars = r.games.length * 3;
    return Positioned(
      left: p.dx - 70,
      top: p.dy - 34,
      width: 140,
      child: Bouncy(
        onTap: () => _open(r),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: open ? r.color : Colors.grey.shade600,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (!open) const Padding(padding: EdgeInsets.only(right: 4), child: Pic('i_kilit', width: 20, height: 20)),
              Flexible(
                child: Text(r.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, shadows: [
                      Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
                    ])),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withAlpha(220), borderRadius: BorderRadius.circular(10)),
            child: Text(open ? '⭐ $stars/$maxStars' : '🔒 ${r.need} ⭐',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  Widget _blokPin(Offset p) => Positioned(
        left: p.dx - 70,
        top: p.dy - 34,
        width: 140,
        child: Bouncy(
          onTap: () {
            Voice.say("Yusuf'un Blok Dünyası");
            go(context, blokGame.build());
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: const Text("🧱 Yusuf'un Blok Dünyası", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ),
      );
}

/// Bölge ekranı: karakter, oyun kartları ve yıldızlar.
class RegionScreen extends StatefulWidget {
  final Region region;
  const RegionScreen(this.region, {super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  Region get r => widget.region;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.say(r.intro));
  }

  Future<void> _play(GameDef g) async {
    Sfx.play('click');
    Voice.say(g.title);
    if (g.loop) {
      await playLoop(context, g.build);
    } else {
      await go(context, g.build());
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDeco(r.bg),
        child: SafeArea(
          child: Column(children: [
            TopBar(r.name),
            const Spacer(),
            for (final g in r.games)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                child: Bouncy(
                  onTap: () => _play(g),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(235),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: r.color, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: r.color.withAlpha(90), borderRadius: BorderRadius.circular(18)),
                        child: Center(child: Text(g.emoji, style: const TextStyle(fontSize: 38))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(g.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          Text(g.skill, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        ]),
                      ),
                      if (g.id != 'yaris') StarRow(bestOf(g.id), size: 24),
                      const Icon(Icons.play_circle_fill, size: 40, color: Color(0xFF43A047)),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Talker(r.who, r.intro, size: 110),
            ),
          ]),
        ),
      ),
    );
  }
}
