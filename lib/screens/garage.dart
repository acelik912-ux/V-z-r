import 'dart:async';

import 'package:flutter/material.dart';

import '../car3d/car_model.dart';
import '../car3d/car_view.dart';
import '../catalog.dart';
import '../sfx.dart';
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
  final _viewerKey = GlobalKey<CarViewerState>();
  int tab = 0;
  bool lightsOn = false;
  bool autoRotate = true;
  bool revving = false;
  CarConfig? preview; // kilitli parçayı kısa süre deneme
  Timer? _previewTimer;
  Timer? _revTimer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Voice.say('Garaja hoş geldin! Arabanı parmağınla çevirebilirsin. Aşağıdan istediğin parçayı seç.');
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _revTimer?.cancel();
    super.dispose();
  }

  CarConfig get shown => preview ?? game.config;

  void _playRowSound(PartRow row, int i) {
    switch (row.sound) {
      case 'horn':
        Sfx.horn(i);
        break;
      case 'rev':
        _rev();
        break;
      default:
        Sfx.play(row.sound);
    }
  }

  Future<void> _pick(PartRow row, int i) async {
    final opt = row.options[i];
    if (game.isUnlocked(row.key, i)) {
      _previewTimer?.cancel();
      setState(() => preview = null);
      game.setPart(row.key, i);
      _playRowSound(row, i);
      if (row.sound != 'horn') Voice.say(opt.label);
      if (row.key == 'light' || row.key == 'neon') setState(() => lightsOn = true);
      return;
    }
    if (!game.reqMet(opt.req)) {
      // Kısa bir deneme göster, sonra geri al
      _previewTimer?.cancel();
      setState(() => preview = game.config.withPart(row.key, i));
      if (row.key == 'neon' || row.key == 'light') setState(() => lightsOn = true);
      _playRowSound(row, i);
      Voice.say('${opt.label}. ${reqText(opt.req)}');
      _previewTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) setState(() => preview = null);
      });
      return;
    }
    Sfx.play('pop');
    Voice.say('${opt.label} kilitli. Tamirci Usta hece tamiri istiyor!');
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const RepairScreen()));
    if (!mounted) return;
    if (ok == true) {
      game.unlock(row.key, i);
      game.setPart(row.key, i);
      Sfx.play('unlock');
      Voice.say('Yeni parça takıldı! ${opt.label}');
    }
  }

  void _rev() {
    Sfx.play('rev');
    _revTimer?.cancel();
    setState(() => revving = true);
    _revTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => revving = false);
    });
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
                  leading: CarView(rivalConfigs[i], width: 70, shadow: false),
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
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      body: ListenableBuilder(
        listenable: game,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              SizedBox(height: h * 0.4, child: _viewer()),
              _tabBar(),
              Expanded(child: _rows()),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewer() {
    return Stack(
      children: [
        Positioned.fill(
          child: CarViewer(
            key: _viewerKey,
            config: shown,
            lightsOn: lightsOn,
            autoRotate: autoRotate,
            revving: revving,
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: Row(
            children: [
              RoundIcon(Icons.arrow_back, () => Navigator.pop(context)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _renameCar,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF59D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  child: game.carName.isEmpty
                      ? const Text('İSİM VER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                      : SylText(game.carName, size: 22),
                ),
              ),
            ],
          ),
        ),
        const Positioned(right: 8, top: 8, child: RewardBar()),
        if (preview != null)
          Positioned(
            left: 0,
            right: 0,
            top: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Text('🔒 Deneme: bu parça henüz kilitli',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Column(
            children: [
              _toolBtn(Icons.campaign, 'Korna', () => Sfx.horn(shown.horn)),
              _toolBtn(Icons.speed, 'Motor', _rev),
              _toolBtn(lightsOn ? Icons.lightbulb : Icons.lightbulb_outline, 'Farlar', () {
                setState(() => lightsOn = !lightsOn);
                Sfx.play('click');
              }, active: lightsOn),
              _toolBtn(Icons.threesixty, 'Döndür', () {
                setState(() => autoRotate = !autoRotate);
                Sfx.play('click');
              }, active: autoRotate),
            ],
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: IgnorePointer(
            child: Text(
              'Parmağınla çevir · iki parmakla yaklaştır',
              style: TextStyle(fontSize: 12, color: lightsOn ? Colors.white60 : Colors.black45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toolBtn(IconData icon, String tip, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: active ? const Color(0xFFFFD54F) : Colors.white.withAlpha(230),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, size: 26, color: Colors.black87)),
        ),
      ),
    );
  }

  Widget _tabBar() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: garageTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = garageTabs[i];
          final sel = i == tab;
          return GestureDetector(
            onTap: () {
              setState(() => tab = i);
              Sfx.play('click');
              Voice.say(t.title);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? t.color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: t.color, width: 2),
              ),
              child: Row(
                children: [
                  Icon(t.icon, color: sel ? Colors.white : t.color),
                  const SizedBox(width: 6),
                  Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: sel ? Colors.white : t.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rows() {
    final t = garageTabs[tab];
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final r in t.rows)
          if (r.onlyBodies == null || r.onlyBodies!.contains(game.config.body)) _row(r),
      ],
    );
  }

  Widget _row(PartRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Voice.say(row.title),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(row.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: row.options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _tile(row, i),
          ),
        ),
      ],
    );
  }

  Widget _tile(PartRow row, int i) {
    final opt = row.options[i];
    final open = game.isUnlocked(row.key, i);
    final sel = game.selected(row.key) == i;
    final met = game.reqMet(opt.req);
    Widget visual;
    if (row.key == 'body') {
      visual = CarView(game.config.withPart('body', i), width: 84, shadow: false);
    } else if (opt.swatch != null) {
      final c = Color(opt.swatch!);
      visual = Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: [Color.lerp(c, Colors.white, 0.55)!, c, Color.lerp(c, Colors.black, 0.35)!],
            stops: const [0.0, 0.45, 1.0],
          ),
          border: Border.all(color: Colors.black26, width: 2),
          boxShadow: row.key == 'neon' ? [BoxShadow(color: c, blurRadius: 12)] : null,
        ),
      );
    } else {
      visual = Text(opt.emoji ?? '•', style: const TextStyle(fontSize: 34));
    }
    return GestureDetector(
      onTap: () => _pick(row, i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF8E1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sel ? const Color(0xFFE53935) : Colors.black12, width: sel ? 4 : 2),
          boxShadow: sel ? const [BoxShadow(color: Colors.black26, blurRadius: 6)] : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(opacity: open ? 1 : 0.4, child: visual),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.05),
                  ),
                ),
              ],
            ),
            if (!open) ...[
              Positioned(
                top: 4,
                right: 6,
                child: Icon(met ? Icons.lock_open : Icons.lock, size: 20, color: met ? Colors.green : Colors.black54),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Text(
                  reqShort(opt.req),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: met ? Colors.green.shade800 : Colors.black54,
                  ),
                ),
              ),
            ],
            if (sel) const Positioned(top: 4, right: 6, child: Icon(Icons.check_circle, size: 20, color: Color(0xFFE53935))),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton.outlined(onPressed: _rivals, icon: const Icon(Icons.groups), tooltip: 'Rakipler'),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  Voice.say('Yarışa gidiyoruz!');
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RaceScreen()));
                },
                icon: const Icon(Icons.flag, size: 28),
                label: const Text('Yarışa git', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
