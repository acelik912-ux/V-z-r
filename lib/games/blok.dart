import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'kit.dart';

// ======================= MALZEMELER =======================

class BlockMat {
  final String id;
  final String name;
  final Color color;
  final Color? top;
  final int pattern; // 0 düz, 1 tahta, 2 tuğla, 3 cam, 4 kiremit, 5 su, 6 taş
  final bool start;
  const BlockMat(this.id, this.name, this.color, {this.top, this.pattern = 0, this.start = false});
}

const mats = <BlockMat>[
  BlockMat('cim', 'çim', Color(0xFF8D6E4A), top: Color(0xFF7CB342), start: true),
  BlockMat('toprak', 'toprak', Color(0xFF8D6E4A), start: true),
  BlockMat('tas', 'taş', Color(0xFF9E9E9E), pattern: 6, start: true),
  BlockMat('tahta', 'tahta', Color(0xFFC68642), pattern: 1, start: true),
  BlockMat('kirmizi', 'kırmızı', Color(0xFFE53935), start: true),
  BlockMat('mavi', 'mavi', Color(0xFF1E88E5), start: true),
  BlockMat('sari', 'sarı', Color(0xFFFDD835), start: true),
  BlockMat('yesil', 'yeşil', Color(0xFF43A047), start: true),
  BlockMat('kiremit', 'kiremit', Color(0xFFD84315), pattern: 4),
  BlockMat('tugla', 'tuğla', Color(0xFFB5502F), pattern: 2),
  BlockMat('cam', 'cam', Color(0xFF81D4FA), pattern: 3),
  BlockMat('beyaz', 'beyaz', Color(0xFFF5F5F0)),
  BlockMat('altin', 'altın', Color(0xFFFFC107)),
  BlockMat('su', 'su', Color(0xFF29B6F6), pattern: 5),
  BlockMat('kum', 'kum', Color(0xFFF2D49B)),
];

class PropDef {
  final String id;
  final String name;
  final String pic;
  final double h; // karo genişliğine göre yükseklik
  const PropDef(this.id, this.name, this.pic, this.h);
}

const props = <PropDef>[
  PropDef('agac', 'ağaç', 'd_agac', 1.9),
  PropDef('lale', 'lale', 'd_lale', 0.9),
  PropDef('cit', 'çit', 'd_cit', 1.0),
  PropDef('camagaci', 'çam', 'd_cam', 2.1),
  PropDef('meyve', 'meyve', 'd_meyve', 1.2),
  PropDef('pembe', 'pembe ağaç', 'd_pembe', 1.9),
  PropDef('saman', 'saman', 'd_saman', 1.0),
  PropDef('kaya', 'kaya', 'd_tas', 0.9),
  PropDef('cali', 'çalı', 'd_cali', 1.0),
];

/// Hece sandığından sırayla çıkan şeyler.
const unlockOrder = [
  'kiremit', 'agac', 'tugla', 'cam', 'lale', 'beyaz', 'cit', 'altin', 'camagaci', 'su', 'kum', 'meyve', 'pembe', 'saman', 'kaya', 'cali'
];

int matIndex(String id) => mats.indexWhere((m) => m.id == id);
PropDef? propById(String id) {
  for (final p in props) {
    if (p.id == id) return p;
  }
  return null;
}

String itemName(String id) {
  final m = matIndex(id);
  if (m >= 0) return mats[m].name;
  return propById(id)?.name ?? id;
}

// ======================= DÜNYA =======================

const W = 10, D = 10, H = 10;
int ck(int x, int y, int z) => x + y * W + z * W * D;
(int, int, int) cxyz(int k) => (k % W, (k ~/ W) % D, k ~/ (W * D));

class Quest {
  final String id;
  final Who who;
  final String text;
  final String speech;
  final int stars;
  final int hearts;
  final Map<int, int> ghost; // hücre -> malzeme
  final bool Function(BlockWorld w)? check;
  final String? needs;
  const Quest(this.id, this.who, this.text, this.speech, {this.stars = 1, this.hearts = 0, this.ghost = const {}, this.check, this.needs});
}

class BlockWorld {
  final Map<int, int> blocks = {};
  final Map<int, String> propsAt = {};

  int count(String mat) {
    final i = matIndex(mat);
    return blocks.values.where((v) => v == i).length;
  }

  int propCount(Set<String> ids) => propsAt.values.where(ids.contains).length;

  bool tower(int h) {
    for (var x = 0; x < W; x++) {
      for (var y = 0; y < D; y++) {
        var ok = true;
        for (var z = 1; z <= h; z++) {
          if (!blocks.containsKey(ck(x, y, z))) {
            ok = false;
            break;
          }
        }
        if (ok) return true;
      }
    }
    return false;
  }

  bool fits(Map<int, int> ghost) => ghost.entries.every((e) => blocks[e.key] == e.value);

  String encode() {
    final b = blocks.entries.map((e) => '${e.key}:${e.value}').join(',');
    final p = propsAt.entries.map((e) => '${e.key}:${e.value}').join(',');
    return 'v1|$b|$p';
  }

  bool decode(String s) {
    final parts = s.split('|');
    if (parts.length != 3 || parts[0] != 'v1') return false;
    blocks.clear();
    propsAt.clear();
    for (final e in parts[1].split(',')) {
      final kv = e.split(':');
      if (kv.length == 2) blocks[int.parse(kv[0])] = int.parse(kv[1]);
    }
    for (final e in parts[2].split(',')) {
      final kv = e.split(':');
      if (kv.length == 2) propsAt[int.parse(kv[0])] = kv[1];
    }
    return true;
  }

  void seed() {
    blocks.clear();
    propsAt.clear();
    final cim = matIndex('cim'), su = matIndex('su'), tug = matIndex('tugla'), tah = matIndex('tahta'), kir = matIndex('kiremit');
    for (var x = 0; x < W; x++) {
      for (var y = 0; y < D; y++) {
        blocks[ck(x, y, 0)] = y == 6 ? su : cim;
      }
    }
    // Komşu teyzenin evi (çatısı eksik)
    for (var z = 1; z <= 2; z++) {
      for (var x = 6; x <= 8; x++) {
        for (var y = 1; y <= 3; y++) {
          final edge = x == 6 || x == 8 || y == 1 || y == 3;
          if (!edge) continue;
          if (y == 3 && x == 7 && z == 1) continue; // kapı
          blocks[ck(x, y, z)] = (z == 2 && x == 7) ? tah : tug;
        }
      }
    }
    for (final c in roofDone) {
      blocks[c] = kir;
    }
    propsAt[ck(1, 1, 1)] = 'agac';
    propsAt[ck(0, 4, 1)] = 'agac';
    propsAt[ck(9, 9, 1)] = 'camagaci';
    propsAt[ck(4, 2, 1)] = 'lale';
  }

  static final roofAll = [for (var x = 6; x <= 8; x++) for (var y = 1; y <= 3; y++) ck(x, y, 3)];
  static final roofDone = [ck(6, 1, 3), ck(8, 1, 3), ck(6, 3, 3), ck(7, 2, 3), ck(8, 3, 3)];
}

final List<Quest> quests = [
  Quest('kule', Who.tamirci, '5 bloklu bir kule yap', 'Haydi bakalım, beş blok üst üste koyup bir kule yap!', check: (w) => w.tower(5)),
  Quest('cati', Who.tozbulut, 'Komşu teyzenin çatısını onar', 'Komşu teyzenin evinin çatısı akıyor! Parlayan yerlere kiremit koyalım.',
      hearts: 1, needs: 'kiremit', ghost: {for (final c in BlockWorld.roofAll) c: matIndex('kiremit')}),
  Quest('tas7', Who.robot, 'Tam 7 taş blok koy', 'Adaya tam yedi tane taş blok koy. Ne eksik ne fazla!', check: (w) => w.count('tas') == 7),
  Quest('blue', Who.papagan, 'Use four blue blocks! (4 mavi blok)', 'Use four blue blocks! Dört mavi blok kullan.', check: (w) => w.count('mavi') >= 4),
  Quest('agac3', Who.tozbulut, '3 ağaç dik', 'Ağaç dikmek sadakadır. Adaya üç ağaç daha dikelim!',
      needs: 'agac', check: (w) => w.propCount({'agac', 'camagaci', 'pembe'}) >= 6),
  Quest('kopru', Who.tamirci, 'Dereye tahta köprü yap', 'Dereyi geçmek için parlayan yerlere tahta köprü kuralım.',
      ghost: {ck(4, 6, 1): matIndex('tahta'), ck(5, 6, 1): matIndex('tahta')}),
  Quest('mescit', Who.baykus, 'Köye küçük bir mescit yap', 'Köyümüze küçük bir mescit yapalım. Beyaz duvarlar ve altın tepeli bir minare!',
      stars: 2, hearts: 2, needs: 'altin', ghost: mescitGhost()),
];

Map<int, int> mescitGhost() {
  final b = matIndex('beyaz'), a = matIndex('altin');
  final g = <int, int>{};
  for (var z = 1; z <= 3; z++) {
    for (var x = 1; x <= 3; x++) {
      for (var y = 7; y <= 9; y++) {
        final edge = x == 1 || x == 3 || y == 7 || y == 9;
        if (z < 3 && !edge) continue; // içi boş, üstü düz dam
        if (x == 2 && y == 7 && z == 1) continue; // kapı
        g[ck(x, y, z)] = b;
      }
    }
  }
  g[ck(2, 8, 4)] = a; // kubbe
  for (var z = 1; z <= 4; z++) {
    g[ck(4, 9, z)] = b; // minare
  }
  g[ck(4, 9, 5)] = a;
  return g;
}

// ======================= EKRAN =======================

class BlokAdasi extends StatefulWidget {
  const BlokAdasi({super.key});

  @override
  State<BlokAdasi> createState() => _BlokAdasiState();
}

class _Face {
  final Path path;
  final int cell;
  final int nx, ny, nz; // dünyadaki yön
  final bool prop;
  _Face(this.path, this.cell, this.nx, this.ny, this.nz, {this.prop = false});
}

class _BlokAdasiState extends State<BlokAdasi> with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  final world = BlockWorld();
  int rot = 0;
  String sel = 'tahta';
  bool erase = false;
  final List<String> undo = [];
  List<_Face> faces = [];
  Size? lastSize;
  bool dirty = true;
  final Map<String, ui.Image> sprites = {};

  Quest? get quest {
    for (final q in quests) {
      if (!game.blockQuests.contains(q.id)) return q;
    }
    return null;
  }

  bool unlocked(String id) {
    final m = matIndex(id);
    if (m >= 0 && mats[m].start) return true;
    return game.blockItems.contains(id);
  }

  @override
  void initState() {
    super.initState();
    if (game.blockWorld.isEmpty || !world.decode(game.blockWorld)) world.seed();
    game.markPlayed('blok');
    _loadSprites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Blok Adasına hoş geldin! Aşağıdan bir blok seç, adaya dokunarak koy.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 4500), _sayQuest);
    });
  }

  @override
  void dispose() {
    pulse.dispose();
    game.saveBlocks(world.encode());
    super.dispose();
  }

  Future<void> _loadSprites() async {
    for (final p in props) {
      try {
        final provider = AssetImage(img(p.pic));
        final stream = provider.resolve(ImageConfiguration.empty);
        stream.addListener(ImageStreamListener((info, _) {
          if (!mounted) return;
          setState(() {
            sprites[p.id] = info.image;
            dirty = true;
          });
        }));
      } catch (_) {}
    }
  }

  void _sayQuest() {
    final q = quest;
    if (!mounted || q == null) return;
    if (q.needs != null && !unlocked(q.needs!)) {
      Say.show(context, q.who, '${q.text}. Önce hece sandığından ${itemName(q.needs!)} çıkar!', mood: 'anlat');
      return;
    }
    if (q.who == Who.papagan) {
      Say.show(context, q.who, q.text, speak: false);
      Voice.sayEn('Use four blue blocks!');
    } else {
      Say.show(context, q.who, q.text, speech: q.speech);
    }
  }

  void _checkQuest() {
    final q = quest;
    if (q == null) return;
    if (q.needs != null && !unlocked(q.needs!)) return;
    final ok = q.ghost.isNotEmpty ? world.fits(q.ghost) : (q.check?.call(world) ?? false);
    if (!ok) return;
    game.blockQuestDone(q.id, stars: q.stars, hearts: q.hearts);
    Sfx.play('finish');
    Say.show(context, q.who, 'Görev tamam! ${q.hearts > 0 ? 'İyilik kalbi kazandın!' : 'Yıldız kazandın!'}', mood: 'sevin');
    final next = quest;
    if (next != null) {
      Future.delayed(const Duration(milliseconds: 4200), _sayQuest);
    } else {
      game.addSticker('k_tamirci_sevin');
    }
  }

  // Görünüm döndürme: dünya (x,y) -> ekran (u,v)
  (int, int) _r(int x, int y) {
    switch (rot) {
      case 1:
        return (D - 1 - y, x);
      case 2:
        return (W - 1 - x, D - 1 - y);
      case 3:
        return (y, W - 1 - x);
      default:
        return (x, y);
    }
  }

  (int, int) _rd(int dx, int dy) {
    switch (rot) {
      case 1:
        return (-dy, dx);
      case 2:
        return (-dx, -dy);
      case 3:
        return (dy, -dx);
      default:
        return (dx, dy);
    }
  }

  double tw = 30;
  Offset origin = Offset.zero;

  Offset _p(double u, double v, double z) {
    final th = tw / 2, bh = tw * 0.58;
    return origin + Offset((u - v) * tw / 2, (u + v) * th / 2 - z * bh);
  }

  void _layout(Size s) {
    tw = min(s.width * 0.95 * 2 / (W + D), s.height * 0.9 / ((W + D) / 4 + H * 0.4));
    final th = tw / 2;
    final islandH = (W + D) * th / 2;
    origin = Offset(s.width / 2, s.height - islandH - tw * 0.9);
  }

  /// Çizim sırası ve dokunma için yüzeyleri hazırlar.
  List<(int, int, double)> _order() {
    final items = <(int, int, double)>[]; // hücre, tür (0 blok, 1 süs, 2 hayalet), derinlik
    for (final k in world.blocks.keys) {
      final (x, y, z) = cxyz(k);
      final (u, v) = _r(x, y);
      items.add((k, 0, (u + v) * 100 + z * 2.0));
    }
    for (final k in world.propsAt.keys) {
      final (x, y, z) = cxyz(k);
      final (u, v) = _r(x, y);
      items.add((k, 1, (u + v) * 100 + z * 2.0 + 0.5));
    }
    final q = quest;
    if (q != null && (q.needs == null || unlocked(q.needs!))) {
      for (final e in q.ghost.entries) {
        if (world.blocks[e.key] == e.value) continue;
        final (x, y, z) = cxyz(e.key);
        final (u, v) = _r(x, y);
        items.add((e.key, 2, (u + v) * 100 + z * 2.0 + 0.7));
      }
    }
    items.sort((a, b) => a.$3.compareTo(b.$3));
    return items;
  }

  void _buildFaces() {
    faces = [];
    for (final it in _order()) {
      if (it.$2 == 2) continue;
      final (x, y, z) = cxyz(it.$1);
      final (u, v) = _r(x, y);
      if (it.$2 == 1) {
        final pd = propById(world.propsAt[it.$1]!);
        final hgt = (pd?.h ?? 1) * tw;
        final base = _p(u + 0.5, v + 0.5, z.toDouble());
        faces.add(_Face(Path()..addRect(Rect.fromCenter(center: base - Offset(0, hgt / 2), width: tw * 0.9, height: hgt)), it.$1, 0, 0, 0, prop: true));
        continue;
      }
      final top = Path()
        ..moveTo(_p(u.toDouble(), v.toDouble(), z + 1.0).dx, _p(u.toDouble(), v.toDouble(), z + 1.0).dy)
        ..lineTo(_p(u + 1.0, v.toDouble(), z + 1.0).dx, _p(u + 1.0, v.toDouble(), z + 1.0).dy)
        ..lineTo(_p(u + 1.0, v + 1.0, z + 1.0).dx, _p(u + 1.0, v + 1.0, z + 1.0).dy)
        ..lineTo(_p(u.toDouble(), v + 1.0, z + 1.0).dx, _p(u.toDouble(), v + 1.0, z + 1.0).dy)
        ..close();
      final right = _quad(_p(u + 1.0, v.toDouble(), z + 1.0), _p(u + 1.0, v + 1.0, z + 1.0), _p(u + 1.0, v + 1.0, z.toDouble()),
          _p(u + 1.0, v.toDouble(), z.toDouble()));
      final left = _quad(_p(u.toDouble(), v + 1.0, z + 1.0), _p(u + 1.0, v + 1.0, z + 1.0), _p(u + 1.0, v + 1.0, z.toDouble()),
          _p(u.toDouble(), v + 1.0, z.toDouble()));
      // ekranda +u ve +v yönlerine karşılık gelen dünya yönleri
      final du = _worldDir(1, 0), dv = _worldDir(0, 1);
      faces.add(_Face(right, it.$1, du.$1, du.$2, 0));
      faces.add(_Face(left, it.$1, dv.$1, dv.$2, 0));
      faces.add(_Face(top, it.$1, 0, 0, 1));
    }
  }

  (int, int) _worldDir(int du, int dv) {
    for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final r = _rd(d.$1, d.$2);
      if (r.$1 == du && r.$2 == dv) return d;
    }
    return (0, 0);
  }

  Path _quad(Offset a, Offset b, Offset c, Offset d) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy)
    ..lineTo(d.dx, d.dy)
    ..close();

  void _tap(Offset p) {
    for (var i = faces.length - 1; i >= 0; i--) {
      final f = faces[i];
      if (!f.path.contains(p)) continue;
      final (x, y, z) = cxyz(f.cell);
      if (erase) {
        _push();
        if (f.prop) {
          world.propsAt.remove(f.cell);
        } else {
          if (z == 0 && world.blocks.length < 2) return;
          world.blocks.remove(f.cell);
          world.propsAt.remove(ck(x, y, z + 1));
        }
        Sfx.play('pop');
        _changed();
        return;
      }
      if (f.prop) return;
      final nx = x + f.nx, ny = y + f.ny, nz = z + f.nz;
      if (nx < 0 || ny < 0 || nz < 0 || nx >= W || ny >= D || nz >= H) return;
      final k = ck(nx, ny, nz);
      if (world.blocks.containsKey(k) || world.propsAt.containsKey(k)) return;
      final pd = propById(sel);
      if (pd != null) {
        if (f.nz != 1) return; // süsler sadece üste
        _push();
        world.propsAt[k] = sel;
        Sfx.play('pop');
      } else {
        _push();
        world.blocks[k] = matIndex(sel);
        Sfx.play('tok');
      }
      _changed();
      return;
    }
  }

  void _push() {
    undo.add(world.encode());
    if (undo.length > 40) undo.removeAt(0);
  }

  void _changed() {
    setState(() => dirty = true);
    game.saveBlocks(world.encode());
    _checkQuest();
  }

  void _undo() {
    if (undo.isEmpty) return;
    Sfx.play('click');
    world.decode(undo.removeLast());
    _changed();
  }

  Future<void> _chest() async {
    final next = unlockOrder.where((id) => !game.blockItems.contains(id)).toList();
    if (next.isEmpty) {
      Say.show(context, Who.baykus, 'Sandıktaki her şeyi çıkardın. Maşallah!', mood: 'sevin');
      return;
    }
    final ok = await showDialog<bool>(context: context, builder: (_) => const _ChestDialog());
    if (ok == true && mounted) {
      final id = next.first;
      game.addBlockItem(id);
      setState(() => sel = id);
      Sfx.play('unlock');
      Say.show(context, Who.baykus, 'Sandık açıldı! Yeni: ${itemName(id)}!', mood: 'sevin');
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) setState(() => dirty = true);
        _checkQuest();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = quest;
    final night = DateTime.now().hour >= 18 || DateTime.now().hour < 6;
    return LevelShell(
      title: 'Blok Adası',
      bg: night ? 'kilit_gece' : 'bolge_bulut',
      tint: night ? const Color(0x55000033) : const Color(0x44FFFFFF),
      child: Column(children: [
        // görev
        GestureDetector(
          onTap: _sayQuest,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              SizedBox(width: 40, height: 44, child: Pic(whoPic(q?.who ?? Who.baykus))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q == null ? 'Bütün görevler tamam! Hayalindeki adayı kur.' : q.text,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text('${game.blockQuests.length}/${quests.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            final s = Size(c.maxWidth, c.maxHeight);
            if (s != lastSize) {
              lastSize = s;
              dirty = true;
            }
            if (dirty) {
              _layout(s);
              _buildFaces();
              dirty = false;
            }
            return GestureDetector(
              onTapUp: (d) => _tap(d.localPosition),
              child: CustomPaint(
                size: s,
                painter: _WorldPainter(this, _order(), pulse),
              ),
            );
          }),
        ),
        // kontrol çubuğu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _Tool(Icons.rotate_left, () => setState(() {
                  rot = (rot + 3) % 4;
                  dirty = true;
                  Sfx.play('uc');
                })),
            _Tool(Icons.rotate_right, () => setState(() {
                  rot = (rot + 1) % 4;
                  dirty = true;
                  Sfx.play('uc');
                })),
            _Tool(Icons.undo, _undo),
            const Spacer(),
            _Tool(erase ? Icons.cleaning_services : Icons.pan_tool_alt, () => setState(() => erase = !erase),
                active: erase, color: erase ? const Color(0xFFFFCDD2) : Colors.white),
            const SizedBox(width: 6),
            Bouncy(
              onTap: _chest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFE082), borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Text('🎁', style: TextStyle(fontSize: 26)),
                  SizedBox(width: 4),
                  Text('Hece\nsandığı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, height: 1)),
                ]),
              ),
            ),
          ]),
        ),
        // palet
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            children: [
              for (final m in mats)
                if (unlocked(m.id)) _PaletteItem(m.name, sel == m.id && !erase, () => _select(m.id), child: _MatSwatch(m)),
              for (final p in props)
                if (unlocked(p.id)) _PaletteItem(p.name, sel == p.id && !erase, () => _select(p.id), child: Pic(p.pic)),
            ],
          ),
        ),
      ]),
    );
  }

  void _select(String id) {
    Sfx.play('click');
    Voice.say(itemName(id));
    setState(() {
      sel = id;
      erase = false;
    });
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color color;
  const _Tool(this.icon, this.onTap, {this.active = false, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(3),
        child: Bouncy(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: active ? Border.all(color: Colors.red, width: 3) : null,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
            ),
            child: Icon(icon, size: 26),
          ),
        ),
      );
}

class _PaletteItem extends StatelessWidget {
  final String name;
  final bool on;
  final VoidCallback onTap;
  final Widget child;
  const _PaletteItem(this.name, this.on, this.onTap, {required this.child});

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 66,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF59D) : Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? Colors.orange : Colors.white, width: 3),
          ),
          child: Column(children: [
            Expanded(child: child),
            Text(name, maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _MatSwatch extends StatelessWidget {
  final BlockMat m;
  const _MatSwatch(this.m);

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SwatchPainter(m), size: const Size(44, 44));
}

class _SwatchPainter extends CustomPainter {
  final BlockMat m;
  _SwatchPainter(this.m);

  @override
  void paint(Canvas canvas, Size s) {
    final tw = min(s.width, s.height) * 0.9;
    final o = Offset(s.width / 2, s.height * 0.12);
    Offset p(double u, double v, double z) => o + Offset((u - v) * tw / 2, (u + v) * tw / 4 - z * tw * 0.5 + tw * 0.5);
    paintCube(canvas, m, p, 0, 0, 0, true, true, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tek bir küpün görünen yüzlerini çizer.
void paintCube(Canvas canvas, BlockMat m, Offset Function(double, double, double) p, int u, int v, int z, bool top, bool right,
    bool left,
    {int alpha = 255}) {
  Path quad(Offset a, Offset b, Offset c, Offset d) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy)
    ..lineTo(d.dx, d.dy)
    ..close();
  final uu = u.toDouble(), vv = v.toDouble(), zz = z.toDouble();
  final glass = m.pattern == 3 || m.pattern == 5;
  final a = glass ? min(alpha, 175) : alpha;
  final base = m.color;
  final topC = m.top ?? Color.lerp(base, Colors.white, 0.12)!;
  final edge = Paint()
    ..color = Colors.black.withAlpha((a * 0.16).toInt())
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  void face(Path path, Color c, List<(Offset, Offset)> lines) {
    canvas.drawPath(path, Paint()..color = c.withAlpha(a));
    if (lines.isNotEmpty) {
      final lp = Paint()
        ..color = Colors.black.withAlpha((a * 0.18).toInt())
        ..strokeWidth = 1.2;
      for (final l in lines) {
        canvas.drawLine(l.$1, l.$2, lp);
      }
    }
    canvas.drawPath(path, edge);
  }

  List<(Offset, Offset)> sideLines(Offset a0, Offset b0, Offset a1, Offset b1) {
    // a0-b0 üst kenar, a1-b1 alt kenar
    switch (m.pattern) {
      case 1: // tahta: yatay çizgiler
      case 4:
        return [
          for (final t in const [0.33, 0.66]) (Offset.lerp(a0, a1, t)!, Offset.lerp(b0, b1, t)!)
        ];
      case 2: // tuğla
        return [
          (Offset.lerp(a0, a1, 0.5)!, Offset.lerp(b0, b1, 0.5)!),
          (Offset.lerp(Offset.lerp(a0, b0, 0.5)!, Offset.lerp(a1, b1, 0.5)!, 0)!, Offset.lerp(Offset.lerp(a0, b0, 0.5)!, Offset.lerp(a1, b1, 0.5)!, 0.5)!),
          (Offset.lerp(Offset.lerp(a0, b0, 0.25)!, Offset.lerp(a1, b1, 0.25)!, 0.5)!, Offset.lerp(Offset.lerp(a0, b0, 0.25)!, Offset.lerp(a1, b1, 0.25)!, 1)!),
          (Offset.lerp(Offset.lerp(a0, b0, 0.75)!, Offset.lerp(a1, b1, 0.75)!, 0.5)!, Offset.lerp(Offset.lerp(a0, b0, 0.75)!, Offset.lerp(a1, b1, 0.75)!, 1)!),
        ];
      case 6:
        return [(Offset.lerp(a0, a1, 0.4)!, Offset.lerp(Offset.lerp(a0, b0, 0.5)!, Offset.lerp(a1, b1, 0.5)!, 0.55)!)];
      default:
        return const [];
    }
  }

  if (right) {
    final a0 = p(uu + 1, vv, zz + 1), b0 = p(uu + 1, vv + 1, zz + 1), b1 = p(uu + 1, vv + 1, zz), a1 = p(uu + 1, vv, zz);
    face(quad(a0, b0, b1, a1), Color.lerp(base, Colors.black, 0.28)!, sideLines(a0, b0, a1, b1));
  }
  if (left) {
    final a0 = p(uu, vv + 1, zz + 1), b0 = p(uu + 1, vv + 1, zz + 1), b1 = p(uu + 1, vv + 1, zz), a1 = p(uu, vv + 1, zz);
    face(quad(a0, b0, b1, a1), Color.lerp(base, Colors.black, 0.14)!, sideLines(a0, b0, a1, b1));
  }
  if (top) {
    final t0 = p(uu, vv, zz + 1), t1 = p(uu + 1, vv, zz + 1), t2 = p(uu + 1, vv + 1, zz + 1), t3 = p(uu, vv + 1, zz + 1);
    face(quad(t0, t1, t2, t3), topC, m.pattern == 1 || m.pattern == 4
        ? [for (final t in const [0.33, 0.66]) (Offset.lerp(t0, t3, t)!, Offset.lerp(t1, t2, t)!)]
        : const []);
    if (m.pattern == 3 || m.pattern == 5 || m.id == 'altin') {
      canvas.drawLine(Offset.lerp(t0, t2, 0.3)!, Offset.lerp(t1, t3, 0.3)!, Paint()
        ..color = Colors.white.withAlpha((a * 0.7).toInt())
        ..strokeWidth = 2);
    }
  }
}

class _WorldPainter extends CustomPainter {
  final _BlokAdasiState s;
  final List<(int, int, double)> order;
  final Animation<double> anim;
  _WorldPainter(this.s, this.order, this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final w = s.world;
    // gölge / deniz kenarı
    final c0 = s._p(0, 0, 0), c1 = s._p(W.toDouble(), 0, 0), c2 = s._p(W.toDouble(), D.toDouble(), 0), c3 = s._p(0, D.toDouble(), 0);
    final shadow = Path()
      ..moveTo(c0.dx, c0.dy + 14)
      ..lineTo(c1.dx + 18, c1.dy + 14)
      ..lineTo(c2.dx, c2.dy + 24)
      ..lineTo(c3.dx - 18, c3.dy + 14)
      ..close();
    canvas.drawPath(shadow, Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    final rot = <int, int>{};
    for (final e in w.blocks.entries) {
      final (x, y, z) = cxyz(e.key);
      final (u, v) = s._r(x, y);
      rot[ck(u, v, z)] = e.value;
    }
    for (final it in order) {
      final (x, y, z) = cxyz(it.$1);
      final (u, v) = s._r(x, y);
      if (it.$2 == 0) {
        final m = mats[w.blocks[it.$1]!];
        final topFree = z + 1 >= H || !rot.containsKey(ck(u, v, z + 1));
        final rightFree = u + 1 >= W || !rot.containsKey(ck(u + 1, v, z));
        final leftFree = v + 1 >= D || !rot.containsKey(ck(u, v + 1, z));
        paintCube(canvas, m, s._p, u, v, z, topFree, rightFree, leftFree);
      } else if (it.$2 == 1) {
        final id = w.propsAt[it.$1]!;
        final pd = propById(id);
        final im = s.sprites[id];
        if (pd == null || im == null) continue;
        final hgt = pd.h * s.tw;
        final wid = hgt * im.width / im.height;
        final base = s._p(u + 0.5, v + 0.5, z.toDouble());
        canvas.drawImageRect(
          im,
          Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
          Rect.fromLTWH(base.dx - wid / 2, base.dy - hgt + s.tw * 0.12, wid, hgt),
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        final q = s.quest;
        final m = mats[q!.ghost[it.$1]!];
        final t = anim.value;
        paintCube(canvas, m, s._p, u, v, z, true, true, true, alpha: (70 + 50 * sin(t * 2 * pi)).toInt());
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ======================= HECE SANDIĞI =======================

class _ChestDialog extends StatefulWidget {
  const _ChestDialog();

  @override
  State<_ChestDialog> createState() => _ChestDialogState();
}

class _ChestDialogState extends State<_ChestDialog> {
  final rnd = Random();
  late final List<String> word;
  late final List<String> tiles;
  int placed = 0;
  final Set<int> used = {};
  int shake = 0;

  @override
  void initState() {
    super.initState();
    final ws = pictureWords(minSyl: 2);
    word = ws.isEmpty ? ['a', 'ra', 'ba'] : ws.first;
    final extra = (Bank(game.letterGroup, game.step).twoLetter()..shuffle(rnd)).where((s) => !word.contains(s)).take(2);
    tiles = [...word, ...extra]..shuffle(rnd);
    Voice.say('Sandığı açmak için ${trCapitalize(word.join())} kelimesini heceleriyle yaz.');
  }

  void _tap(int i) {
    if (used.contains(i)) return;
    if (tiles[i] == word[placed]) {
      Sfx.play('tok');
      Voice.say(tiles[i]);
      game.recordSyllable(tiles[i], true);
      setState(() {
        used.add(i);
        placed++;
      });
      if (placed == word.length) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } else {
      Sfx.play('wrong');
      game.recordSyllable(tiles[i], false);
      setState(() => shake++);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(placed == word.length ? '🎉' : '🎁', style: const TextStyle(fontSize: 50)),
              const SizedBox(width: 10),
              Text(emojiFor(word.join()), style: const TextStyle(fontSize: 50)),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < word.length; k++)
                Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: k < placed ? const Color(0xFFC8E6C9) : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: k < placed ? SylText(word[k], size: 28) : const Text(' ? ', style: TextStyle(fontSize: 26)),
                ),
            ]),
            const SizedBox(height: 14),
            Shake(
              trigger: shake,
              child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                for (var i = 0; i < tiles.length; i++)
                  ChoiceTile(
                    size: 70,
                    dim: used.contains(i),
                    color: const Color(0xFFFFCC80),
                    onTap: () => _tap(i),
                    child: SylText(tiles[i], size: 28),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç', style: TextStyle(fontSize: 18))),
          ]),
        ),
      );
}

/// Ana ekrandaki Blok Adası kartı için küçük blok yığını.
class BlockLogo extends StatelessWidget {
  const BlockLogo({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _LogoPainter(), size: Size.infinite);
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final tw = min(s.width / 2.6, s.height / 2.4);
    final o = Offset(s.width / 2, s.height * 0.22);
    Offset p(double u, double v, double z) => o + Offset((u - v) * tw / 2, (u + v) * tw / 4 - z * tw * 0.55 + tw * 0.4);
    final cubes = [
      (0, 0, 0, 'cim'), (1, 0, 0, 'cim'), (0, 1, 0, 'cim'), (1, 1, 0, 'tas'),
      (0, 0, 1, 'tugla'), (0, 0, 2, 'kiremit'), (1, 1, 1, 'tahta'),
    ]..sort((a, b) => ((a.$1 + a.$2) * 10 + a.$3).compareTo((b.$1 + b.$2) * 10 + b.$3));
    for (final c in cubes) {
      final m = mats[matIndex(c.$4)];
      paintCube(canvas, m, p, c.$1, c.$2, c.$3, true, true, true);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
