import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'blok_tex.dart';
import 'kit.dart';

// ======================= MALZEMELER =======================

/// Sekmeler: 0 yapı, 1 renkler, 2 doğa, 3 özel
class BlockMat {
  final String id;
  final String name;
  final Color color; // ortalama renk (doku yüklenmeden önce ve küçük resimler için)
  final int tab;
  final bool start;
  final bool see; // saydam (cam, su, buz)
  final bool glow;
  const BlockMat(this.id, this.name, this.color, this.tab, {this.start = false, this.see = false, this.glow = false});
}

// Sıra önemli: kayıtlı adalar bu sıradaki numaraları kullanır. Yeni bloklar sona eklenir.
const mats = <BlockMat>[
  BlockMat('cim', 'çim', Color(0xFF6DBE45), 2, start: true),
  BlockMat('toprak', 'toprak', Color(0xFF8B5A2B), 2, start: true),
  BlockMat('tas', 'taş', Color(0xFF8E8E8E), 0, start: true),
  BlockMat('tahta', 'tahta', Color(0xFFB8834A), 0, start: true),
  BlockMat('kirmizi', 'kırmızı', Color(0xFFE53935), 1, start: true),
  BlockMat('mavi', 'mavi', Color(0xFF1E88E5), 1, start: true),
  BlockMat('sari', 'sarı', Color(0xFFFDD835), 1, start: true),
  BlockMat('yesil', 'yeşil', Color(0xFF43A047), 1, start: true),
  BlockMat('kiremit', 'kiremit', Color(0xFFC0442A), 0),
  BlockMat('tugla', 'tuğla', Color(0xFFB04A2F), 0),
  BlockMat('cam', 'cam', Color(0xFF9EE6FF), 0, see: true),
  BlockMat('beyaz', 'mermer', Color(0xFFF2F0EA), 0),
  BlockMat('altin', 'altın', Color(0xFFFFC928), 3),
  BlockMat('su', 'su', Color(0xFF2E9AE6), 2, see: true),
  BlockMat('kum', 'kum', Color(0xFFE8D29A), 2, start: true),
  BlockMat('parke', 'parke taşı', Color(0xFF7A7A7A), 0, start: true),
  BlockMat('koyu', 'koyu tahta', Color(0xFF6B4423), 0),
  BlockMat('kutuk', 'kütük', Color(0xFF6B4A2B), 2),
  BlockMat('yaprak', 'yaprak', Color(0xFF2E7D32), 2),
  BlockMat('kumtasi', 'kumtaşı', Color(0xFFDCC384), 0),
  BlockMat('kar', 'kar', Color(0xFFF8FBFF), 2),
  BlockMat('buz', 'buz', Color(0xFFA8DDF5), 2, see: true),
  BlockMat('saman', 'saman', Color(0xFFE3C14B), 2),
  BlockMat('kitaplik', 'kitaplık', Color(0xFF9C6B3A), 3),
  BlockMat('kapi', 'kapı', Color(0xFF7A4E2A), 3),
  BlockMat('fener', 'fener', Color(0xFFFFC107), 3, glow: true),
  BlockMat('elmas', 'elmas', Color(0xFF4DD0E1), 3),
  BlockMat('demir', 'demir', Color(0xFFD6D6D6), 0),
  BlockMat('turuncu', 'turuncu', Color(0xFFFB8C00), 1, start: true),
  BlockMat('mor', 'mor', Color(0xFF8E24AA), 1),
  BlockMat('pembe', 'pembe', Color(0xFFF48FB1), 1),
  BlockMat('siyah', 'siyah', Color(0xFF37373F), 1),
  BlockMat('acikmavi', 'açık mavi', Color(0xFF81D4FA), 1),
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
  PropDef('meyve', 'meyve çalısı', 'd_meyve', 1.2),
  PropDef('pembe_agac', 'pembe ağaç', 'd_pembe', 1.9),
  PropDef('saman_balya', 'balya', 'd_saman', 1.0),
  PropDef('kaya', 'kaya', 'd_tas', 0.9),
  PropDef('cali', 'çalı', 'd_cali', 1.0),
];

/// Hece sandığı her açılışta bir grup verir.
const unlockGroups = [
  ['kiremit', 'agac', 'cam'],
  ['tugla', 'lale', 'kapi'],
  ['beyaz', 'altin', 'fener'],
  ['kutuk', 'yaprak', 'camagaci'],
  ['koyu', 'kitaplik', 'cit'],
  ['su', 'kar', 'buz'],
  ['mor', 'pembe', 'acikmavi', 'siyah'],
  ['kumtasi', 'saman', 'meyve'],
  ['elmas', 'demir', 'pembe_agac'],
  ['saman_balya', 'kaya', 'cali'],
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

const W = 10, D = 10, H = 12;
int ck(int x, int y, int z) => x + y * W + z * W * D;
(int, int, int) cxyz(int k) => (k % W, (k ~/ W) % D, k ~/ (W * D));

class Quest {
  final String id;
  final Who who;
  final String text;
  final String speech;
  final int stars;
  final int hearts;
  final Map<int, int> ghost; // hücre -> malzeme (-1: herhangi bir blok)
  final (int, int) Function(BlockWorld w)? progress; // (şu an, hedef)
  final bool exact;
  final String? needs;
  final String? unit;
  const Quest(this.id, this.who, this.text, this.speech,
      {this.stars = 1, this.hearts = 0, this.ghost = const {}, this.progress, this.exact = false, this.needs, this.unit});

  (int, int) prog(BlockWorld w) {
    if (progress != null) return progress!(w);
    final done = ghost.entries.where((e) => w.blocks.containsKey(e.key) && (e.value < 0 || w.blocks[e.key] == e.value)).length;
    return (done, ghost.length);
  }

  bool ok(BlockWorld w) {
    final (a, b) = prog(w);
    return exact ? a == b : a >= b;
  }
}

class BlockWorld {
  final Map<int, int> blocks = {};
  final Map<int, String> propsAt = {};

  int count(String mat) {
    final i = matIndex(mat);
    return blocks.values.where((v) => v == i).length;
  }

  int propCount(Set<String> ids) => propsAt.values.where(ids.contains).length;

  int tallest() {
    var best = 0;
    for (var x = 0; x < W; x++) {
      for (var y = 0; y < D; y++) {
        var h = 0;
        while (blocks.containsKey(ck(x, y, h + 1))) {
          h++;
        }
        if (h > best) best = h;
      }
    }
    return best;
  }

  /// (x,y) sütunundaki en üst dolu z (yoksa -1).
  int top(int x, int y) {
    for (var z = H - 1; z >= 0; z--) {
      if (blocks.containsKey(ck(x, y, z)) || propsAt.containsKey(ck(x, y, z))) return z;
    }
    return -1;
  }

  String encode() {
    final b = blocks.entries.map((e) => '${e.key}:${e.value}').join(',');
    final p = propsAt.entries.map((e) => '${e.key}:${e.value}').join(',');
    return 'v2|$b|$p';
  }

  bool decode(String s) {
    final parts = s.split('|');
    if (parts.length != 3 || (parts[0] != 'v1' && parts[0] != 'v2')) return false;
    final oldH = parts[0] == 'v1' ? 10 : H;
    blocks.clear();
    propsAt.clear();
    int conv(int k) {
      if (oldH == H) return k;
      final x = k % W, y = (k ~/ W) % D, z = k ~/ (W * D);
      return ck(x, y, z);
    }

    for (final e in parts[1].split(',')) {
      final kv = e.split(':');
      if (kv.length == 2) blocks[conv(int.parse(kv[0]))] = int.parse(kv[1]);
    }
    for (final e in parts[2].split(',')) {
      final kv = e.split(':');
      if (kv.length == 2) {
        final id = kv[1] == 'pembe' ? 'pembe_agac' : (kv[1] == 'saman' ? 'saman_balya' : kv[1]);
        propsAt[conv(int.parse(kv[0]))] = id;
      }
    }
    return true;
  }

  void seed() {
    blocks.clear();
    propsAt.clear();
    final cim = matIndex('cim'), su = matIndex('su'), tug = matIndex('tugla'), tah = matIndex('tahta'), kir = matIndex('kiremit');
    final kum = matIndex('kum'), parke = matIndex('parke');
    for (var x = 0; x < W; x++) {
      for (var y = 0; y < D; y++) {
        blocks[ck(x, y, 0)] = y == 6 ? su : ((y == 5 || y == 7) && x > 6 ? kum : cim);
      }
    }
    for (var y = 0; y < 6; y++) {
      blocks[ck(4, y, 0)] = parke;
    }
    for (var y = 7; y < D; y++) {
      blocks[ck(4, y, 0)] = parke;
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
    for (var x = 6; x <= 8; x++) {
      for (var y = 1; y <= 3; y++) {
        if (!roofMissing.contains(ck(x, y, 3))) blocks[ck(x, y, 3)] = kir;
      }
    }
    propsAt[ck(1, 1, 1)] = 'agac';
    propsAt[ck(0, 4, 1)] = 'agac';
    propsAt[ck(9, 9, 1)] = 'camagaci';
    propsAt[ck(2, 2, 1)] = 'lale';
  }

  static final roofAll = [for (var x = 6; x <= 8; x++) for (var y = 1; y <= 3; y++) ck(x, y, 3)];
  static final roofMissing = {ck(7, 1, 3), ck(6, 2, 3), ck(8, 2, 3), ck(7, 3, 3)};
}

final List<Quest> quests = [
  Quest('kule', Who.tamirci, 'Parlayan yere 5 bloklu kule yap', 'Parlayan yere, blokları üst üste koyarak beş bloklu bir kule yap!',
      ghost: {for (var z = 1; z <= 5; z++) ck(2, 3, z): -1}),
  Quest('cati', Who.tozbulut, 'Komşu teyzenin çatısına kiremit koy', 'Komşu teyzenin evinin çatısı akıyor! Parlayan yerlere kiremit koyalım.',
      hearts: 1, needs: 'kiremit', ghost: {for (final c in BlockWorld.roofMissing) c: matIndex('kiremit')}),
  Quest('tas7', Who.robot, 'Adaya tam 7 taş blok koy', 'Adaya tam yedi tane taş blok koy. Ne eksik ne fazla!',
      exact: true, unit: 'taş', progress: (w) => (w.count('tas'), 7)),
  Quest('blue', Who.papagan, 'Use four blue blocks! (4 mavi blok)', 'Use four blue blocks! Dört mavi blok kullan.',
      unit: 'mavi', progress: (w) => (min(w.count('mavi'), 4), 4)),
  Quest('agac3', Who.tozbulut, '3 ağaç dik', 'Ağaç dikmek sadakadır. Adaya üç ağaç daha dikelim!', needs: 'agac', unit: 'ağaç',
      progress: (w) => (max(0, min(3, w.propCount({'agac', 'camagaci', 'pembe_agac'}) - 3)), 3)),
  Quest('kopru', Who.tamirci, 'Dereye tahta köprü yap', 'Dereyi geçmek için parlayan yerlere tahta köprü kuralım.',
      ghost: {ck(4, 6, 1): matIndex('tahta')}),
  Quest('fener', Who.baykus, 'Yola 2 fener koy', 'Akşam olunca yol karanlık oluyor. Yolun kenarına iki fener koyalım!', needs: 'fener', unit: 'fener',
      progress: (w) => (min(w.count('fener'), 2), 2)),
  Quest('mescit', Who.baykus, 'Köye küçük bir mescit yap', 'Köyümüze küçük bir mescit yapalım. Parlayan yerlere mermer ve altın koy!',
      stars: 2, hearts: 2, needs: 'altin', ghost: mescitGhost()),
];

Map<int, int> mescitGhost() {
  final b = matIndex('beyaz'), a = matIndex('altin');
  final g = <int, int>{};
  for (var z = 1; z <= 2; z++) {
    for (var x = 1; x <= 3; x++) {
      for (var y = 7; y <= 9; y++) {
        if (x == 2 && y == 7 && z == 1) continue; // kapı boşluğu
        g[ck(x, y, z)] = b;
      }
    }
  }
  g[ck(2, 8, 3)] = a; // kubbe
  for (var z = 1; z <= 4; z++) {
    g[ck(0, 9, z)] = b; // minare
  }
  g[ck(0, 9, 5)] = a;
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
  int tab = 0;
  final List<String> undo = [];
  List<_Face> faces = [];
  Size? lastSize;
  bool dirty = true;
  ui.Picture? picture;
  final Map<String, ui.Image> sprites = {};
  // yakınlaştırma ve kaydırma
  double zoom = 1.12;
  Offset pan = Offset.zero;
  double _z0 = 1;
  Offset _p0 = Offset.zero, _f0 = Offset.zero;
  bool _moved = false;
  // dokunmadan önce gösterilen yer
  int? previewCell;
  bool previewErase = false;
  final night = DateTime.now().hour >= 19 || DateTime.now().hour < 6;

  Quest? get quest {
    for (final q in quests) {
      if (!game.blockQuests.contains(q.id)) return q;
    }
    return null;
  }

  bool get questReady => quest != null && (quest!.needs == null || unlocked(quest!.needs!));

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
    Tex.load(mats.map((m) => m.id).toList()).then((_) {
      if (mounted) setState(() => dirty = true);
    });
    _loadSprites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Aşağıdan bir blok seç, sonra adaya dokun. Blok, parlayan çerçevenin olduğu yere konur.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 6000), _sayQuest);
    });
  }

  @override
  void dispose() {
    pulse.dispose();
    game.saveBlocks(world.encode());
    super.dispose();
  }

  Future<void> _loadSprites() async {
    await Img.load(props.map((p) => p.pic).toList());
    if (!mounted) return;
    setState(() {
      for (final p in props) {
        final im = Img.get(p.pic);
        if (im != null) sprites[p.id] = im;
      }
      dirty = true;
    });
  }

  void _sayQuest() {
    final q = quest;
    if (!mounted || q == null) return;
    if (!questReady) {
      Say.show(context, q.who, '${q.text}. Önce 🎁 hece sandığını aç, ${itemName(q.needs!)} çıksın!', mood: 'anlat');
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
    if (q == null || !questReady) return;
    if (q.exact && q.unit != null) {
      final (a, b) = q.prog(world);
      if (a > b) {
        Say.show(context, q.who, '$a ${q.unit} var, fazla oldu! ${a - b} tanesini sil.', mood: 'saskin');
        return;
      }
    }
    if (!q.ok(world)) return;
    game.blockQuestDone(q.id, stars: q.stars, hearts: q.hearts);
    Sfx.play('finish');
    Say.show(context, q.who, 'Görev tamam! ${q.hearts > 0 ? 'İyilik kalbi kazandın!' : 'Yıldız kazandın!'}', mood: 'sevin');
    if (quest != null) {
      Future.delayed(const Duration(milliseconds: 4200), _sayQuest);
    } else {
      game.addSticker('k_tamirci_sevin');
    }
  }

  // ---- Görünüm ----
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

  (int, int) _worldDir(int du, int dv) {
    for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final r = _rd(d.$1, d.$2);
      if (r.$1 == du && r.$2 == dv) return d;
    }
    return (0, 0);
  }

  double tw = 30;
  Offset origin = Offset.zero;
  Size area = Size.zero;

  Offset _p(double u, double v, double z) {
    final th = tw / 2, bh = tw * 0.6;
    return origin + Offset((u - v) * tw / 2, (u + v) * th / 2 - z * bh);
  }

  void _layout(Size s) {
    area = s;
    tw = min(s.width * 0.96 * 2 / (W + D), s.height / ((W + D) / 4 + 4.5));
    final islandH = (W + D) * tw / 4;
    origin = Offset(s.width / 2, s.height - islandH - tw * 1.6);
  }

  Offset _toWorld(Offset p) {
    final c = Offset(area.width / 2, area.height / 2);
    return (p - c - pan) / zoom + c;
  }

  List<(int, int, double)> _order() {
    final items = <(int, int, double)>[];
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
    items.sort((a, b) => a.$3.compareTo(b.$3));
    return items;
  }

  Path _quad(Offset a, Offset b, Offset c, Offset d) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy)
    ..lineTo(d.dx, d.dy)
    ..close();

  /// Dünyayı bir kez resme çizer; dokunma için yüzeyleri saklar.
  void _rebuild() {
    final order = _order();
    faces = [];
    final rotMap = <int, int>{};
    for (final e in world.blocks.entries) {
      final (x, y, z) = cxyz(e.key);
      final (u, v) = _r(x, y);
      rotMap[ck(u, v, z)] = e.value;
    }
    bool solid(int u, int v, int z) {
      final m = rotMap[ck(u, v, z)];
      return m != null && !mats[m].see;
    }

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    _paintSea(canvas);
    final du = _worldDir(1, 0), dv = _worldDir(0, 1);
    for (final it in order) {
      final (x, y, z) = cxyz(it.$1);
      final (u, v) = _r(x, y);
      if (it.$2 == 1) {
        final id = world.propsAt[it.$1]!;
        final pd = propById(id);
        final hgt = (pd?.h ?? 1) * tw;
        final base = _p(u + 0.5, v + 0.5, z.toDouble());
        final im = sprites[id];
        if (im != null && pd != null) {
          final wid = hgt * im.width / im.height;
          canvas.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
              Rect.fromLTWH(base.dx - wid / 2, base.dy - hgt + tw * 0.12, wid, hgt), Paint()..filterQuality = FilterQuality.medium);
        }
        faces.add(_Face(Path()..addRect(Rect.fromCenter(center: base - Offset(0, hgt / 2), width: tw * 0.8, height: hgt)), it.$1, 0, 0, 0,
            prop: true));
        continue;
      }
      final mi = world.blocks[it.$1]!;
      final m = mats[mi];
      bool hidden(int uu, int vv, int zz) => solid(uu, vv, zz) || (m.see && rotMap[ck(uu, vv, zz)] == mi);
      final topF = z + 1 >= H || !hidden(u, v, z + 1);
      final rightF = u + 1 >= W || !hidden(u + 1, v, z);
      final leftF = v + 1 >= D || !hidden(u, v + 1, z);
      drawTexCube(canvas, m, _p, u, v, z, topF, rightF, leftF);
      final fz = z.toDouble(), fu = u.toDouble(), fv = v.toDouble();
      faces.add(_Face(_quad(_p(fu + 1, fv, fz + 1), _p(fu + 1, fv + 1, fz + 1), _p(fu + 1, fv + 1, fz), _p(fu + 1, fv, fz)), it.$1, du.$1,
          du.$2, 0));
      faces.add(_Face(_quad(_p(fu, fv + 1, fz + 1), _p(fu + 1, fv + 1, fz + 1), _p(fu + 1, fv + 1, fz), _p(fu, fv + 1, fz)), it.$1, dv.$1,
          dv.$2, 0));
      faces.add(_Face(_quad(_p(fu, fv, fz + 1), _p(fu + 1, fv, fz + 1), _p(fu + 1, fv + 1, fz + 1), _p(fu, fv + 1, fz + 1)), it.$1, 0, 0, 1));
    }
    picture?.dispose();
    picture = rec.endRecording();
  }

  void _paintSea(Canvas canvas) {
    const m = 2.2;
    final a = _p(-m, -m, 0), b = _p(W + m, -m, 0), c = _p(W + m, D + m, 0), d = _p(-m, D + m, 0);
    final sea = _quad(a, b, c, d);
    canvas.drawPath(
        sea,
        Paint()
          ..shader = ui.Gradient.linear(a, c, [const Color(0xFF4FC3F7), const Color(0xFF0288D1)])
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    final wave = Paint()
      ..color = Colors.white.withAlpha(90)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final t = -1.6 + i * 0.4;
      canvas.drawLine(_p(t, -1.0 - i * 0.15, 0), _p(t + 1.2, -1.0 - i * 0.15, 0), wave);
      canvas.drawLine(_p(W + 0.6 + i * 0.12, 2.0 + i * 1.3, 0), _p(W + 0.6 + i * 0.12, 3.0 + i * 1.3, 0), wave);
    }
    // adanın kumsal kenarı
    final e = 0.35;
    canvas.drawPath(_quad(_p(-e, -e, 0), _p(W + e, -e, 0), _p(W + e, D + e, 0), _p(-e, D + e, 0)), Paint()..color = const Color(0xFFF2DFA6));
  }

  /// Dokunulan yerde ne olacağını bulur: (hücre, sil mi)
  (int, bool)? _target(Offset screen) {
    final p = _toWorld(screen);
    for (var i = faces.length - 1; i >= 0; i--) {
      final f = faces[i];
      if (!f.path.contains(p)) continue;
      final (x, y, z) = cxyz(f.cell);
      if (erase) {
        if (!f.prop && z == 0 && world.blocks.length < 2) return null;
        return (f.cell, true);
      }
      if (f.prop) return null;
      final nx = x + f.nx, ny = y + f.ny, nz = z + f.nz;
      if (nx < 0 || ny < 0 || nz < 0 || nx >= W || ny >= D || nz >= H) return null;
      final k = ck(nx, ny, nz);
      if (world.blocks.containsKey(k) || world.propsAt.containsKey(k)) return null;
      if (propById(sel) != null && f.nz != 1) return null; // süsler sadece üste
      return (k, false);
    }
    return null;
  }

  void _down(Offset p) {
    final t = _target(p);
    setState(() {
      previewCell = t?.$1;
      previewErase = t?.$2 ?? false;
    });
  }

  void _up(Offset p) {
    final t = _target(p);
    setState(() => previewCell = null);
    if (t == null) return;
    final (k, del) = t;
    _push();
    if (del) {
      if (world.propsAt.remove(k) == null) {
        world.blocks.remove(k);
        final (x, y, z) = cxyz(k);
        world.propsAt.remove(ck(x, y, z + 1));
      }
      Sfx.play('pop');
    } else if (propById(sel) != null) {
      world.propsAt[k] = sel;
      Sfx.play('pop');
    } else {
      world.blocks[k] = matIndex(sel);
      Sfx.play(mats[matIndex(sel)].tab == 1 ? 'pop' : 'tok');
    }
    _changed();
  }

  void _push() {
    undo.add(world.encode());
    if (undo.length > 60) undo.removeAt(0);
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

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Adayı baştan kuralım mı?'),
        content: const Text('Yaptığın her şey silinir. Açtığın bloklar ve görevler kalır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hayır', style: TextStyle(fontSize: 18))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Evet', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
    if (ok != true) return;
    _push();
    world.seed();
    _changed();
  }

  Future<void> _chest() async {
    final next = unlockGroups.where((g) => !g.every(game.blockItems.contains)).toList();
    if (next.isEmpty) {
      Say.show(context, Who.baykus, 'Sandıktaki her şeyi çıkardın. Maşallah!', mood: 'sevin');
      return;
    }
    final ok = await showDialog<bool>(context: context, builder: (_) => const _ChestDialog());
    if (ok == true && mounted) {
      final group = next.first;
      for (final id in group) {
        game.addBlockItem(id);
      }
      setState(() {
        sel = group.first;
        final m = matIndex(sel);
        tab = m >= 0 ? mats[m].tab : 2;
        erase = false;
      });
      Sfx.play('unlock');
      await showDialog<void>(context: context, builder: (_) => _NewItems(group));
      if (!mounted) return;
      setState(() => dirty = true);
      _checkQuest();
      if (questReady) Future.delayed(const Duration(milliseconds: 500), _sayQuest);
    }
  }

  void _select(String id) {
    Sfx.play('click');
    Voice.say(itemName(id));
    setState(() {
      sel = id;
      erase = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = quest;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _SkyPainter(night))),
        SafeArea(
          child: Column(children: [
            TopBar('Blok Adası', trailing: _Tool(Icons.refresh, _reset, small: true)),
            if (q != null) _questBar(q) else _allDone(),
            Expanded(
              child: LayoutBuilder(builder: (_, c) {
                final s = Size(c.maxWidth, c.maxHeight);
                if (s != lastSize) {
                  lastSize = s;
                  _layout(s);
                  dirty = true;
                }
                if (dirty) {
                  _rebuild();
                  dirty = false;
                }
                return GestureDetector(
                  onTapDown: (d) => _down(d.localPosition),
                  onTapUp: (d) => _up(d.localPosition),
                  onTapCancel: () => setState(() => previewCell = null),
                  onScaleStart: (d) {
                    _z0 = zoom;
                    _p0 = pan;
                    _f0 = d.localFocalPoint;
                    _moved = false;
                  },
                  onScaleUpdate: (d) {
                    final delta = d.localFocalPoint - _f0;
                    if (!_moved && delta.distance < 8 && d.pointerCount < 2) return;
                    _moved = true;
                    setState(() {
                      previewCell = null;
                      zoom = (_z0 * d.scale).clamp(0.8, 2.6).toDouble();
                      pan = Offset(
                        (_p0.dx + delta.dx).clamp(-s.width * zoom * 0.5, s.width * zoom * 0.5).toDouble(),
                        (_p0.dy + delta.dy).clamp(-s.height * zoom * 0.5, s.height * zoom * 0.5).toDouble(),
                      );
                    });
                  },
                  child: ClipRect(
                    child: CustomPaint(size: s, painter: _WorldPainter(this, pulse)),
                  ),
                );
              }),
            ),
            _controls(),
            _tabs(),
            _palette(),
          ]),
        ),
      ]),
    );
  }

  Widget _questBar(Quest q) {
    final ready = questReady;
    final (a, b) = q.prog(world);
    final over = q.exact && a > b;
    return GestureDetector(
      onTap: _sayQuest,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD54F), width: 3),
        ),
        child: Row(children: [
          SizedBox(width: 42, height: 46, child: Pic(whoPic(q.who))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ready ? q.text : 'Önce 🎁 hece sandığını aç!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              if (ready)
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: b == 0 ? 0 : min(1, a / b),
                        minHeight: 12,
                        color: over ? Colors.red : Colors.green,
                        backgroundColor: Colors.black12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$a / $b', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: over ? Colors.red : Colors.black87)),
                ]),
            ]),
          ),
          const Icon(Icons.volume_up, color: Colors.black45),
        ]),
      ),
    );
  }

  Widget _allDone() => Container(
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(16)),
        child: const Text('Bütün görevler tamam! Hayalindeki adayı kur. 🌟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      );

  Widget _controls() => Padding(
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
          _Tool(Icons.zoom_in, () => setState(() => zoom = min(2.6, zoom + 0.3))),
          _Tool(Icons.zoom_out, () => setState(() {
                zoom = max(0.8, zoom - 0.3);
                if (zoom <= 1) pan = Offset.zero;
              })),
          _Tool(Icons.undo, _undo),
          const Spacer(),
          Bouncy(
            onTap: () {
              Sfx.play('click');
              setState(() => erase = !erase);
              Voice.say(erase ? 'Silgi. Dokunduğun blok silinir.' : 'Koyma');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: erase ? const Color(0xFFEF5350) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
              ),
              child: Row(children: [
                Icon(Icons.auto_fix_normal, color: erase ? Colors.white : Colors.black87),
                const SizedBox(width: 4),
                Text('Silgi', style: TextStyle(fontWeight: FontWeight.w900, color: erase ? Colors.white : Colors.black87)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          Bouncy(
            onTap: _chest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFE082), borderRadius: BorderRadius.circular(16)),
              child: const Text('🎁', style: TextStyle(fontSize: 28)),
            ),
          ),
        ]),
      );

  Widget _tabs() {
    const names = ['🧱 Yapı', '🎨 Renk', '🌳 Doğa', '✨ Özel'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Sfx.play('click');
                setState(() => tab = i);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: tab == i ? Colors.white : Colors.white.withAlpha(120),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Text(names[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _palette() {
    final items = <Widget>[
      for (final m in mats)
        if (m.tab == tab && unlocked(m.id)) _PaletteItem(m.name, sel == m.id && !erase, () => _select(m.id), child: _MatSwatch(m)),
      if (tab == 2)
        for (final p in props)
          if (unlocked(p.id)) _PaletteItem(p.name, sel == p.id && !erase, () => _select(p.id), child: Pic(p.pic)),
    ];
    final locked = mats.where((m) => m.tab == tab && !unlocked(m.id)).length + (tab == 2 ? props.where((p) => !unlocked(p.id)).length : 0);
    return Container(
      height: 94,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(14))),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        children: [
          ...items,
          if (locked > 0)
            _PaletteItem('$locked kilitli', false, _chest,
                child: const Center(child: Text('🎁', style: TextStyle(fontSize: 30)))),
        ],
      ),
    );
  }
}

class _NewItems extends StatelessWidget {
  final List<String> ids;
  const _NewItems(this.ids);

  @override
  Widget build(BuildContext context) {
    Voice.say('Sandık açıldı! ${ids.map(itemName).join(', ')}!');
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉 Sandık açıldı!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            for (final id in ids)
              Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: matIndex(id) >= 0 ? _MatSwatch(mats[matIndex(id)]) : Pic(propById(id)!.pic),
                ),
                SylText(itemName(id), size: 20),
              ]),
          ]),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Haydi kuralım!', style: TextStyle(fontSize: 20))),
        ]),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;
  const _Tool(this.icon, this.onTap, {this.small = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(2),
        child: Bouncy(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(small ? 7 : 7),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
            ),
            child: Icon(icon, size: 22),
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
          width: 68,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF59D) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? Colors.orange : Colors.black12, width: on ? 3 : 1),
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
  Widget build(BuildContext context) => CustomPaint(painter: _SwatchPainter(m), size: Size.infinite);
}

class _SwatchPainter extends CustomPainter {
  final BlockMat m;
  _SwatchPainter(this.m);

  @override
  void paint(Canvas canvas, Size s) {
    final tw = min(s.width, s.height / 1.05) * 0.95;
    final o = Offset(s.width / 2, (s.height - tw * 1.1) / 2);
    Offset p(double u, double v, double z) => o + Offset((u - v) * tw / 2, (u + v) * tw / 4 - z * tw * 0.6 + tw * 0.6);
    drawTexCube(canvas, m, p, 0, 0, 0, true, true, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => !Tex.ready;
}

/// Dokulu küp çizer (doku yoksa düz renk).
void drawTexCube(Canvas canvas, BlockMat m, Offset Function(double, double, double) p, int u, int v, int z, bool top, bool right,
    bool left,
    {int alpha = 255}) {
  final uu = u.toDouble(), vv = v.toDouble(), zz = z.toDouble();
  void face(Offset a, Offset b, Offset d, ui.Image? img, double shade) {
    // a: sol üst, b: sağ üst, d: sol alt (paralelkenar)
    final c = b + d - a;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
    final base = Color.lerp(Colors.black, m.color, shade)!;
    if (!m.see) canvas.drawPath(path, Paint()..color = base.withAlpha(alpha));
    if (img != null) {
      final ux = (b - a) / 16, vy = (d - a) / 16;
      canvas.save();
      canvas.transform(Float64List.fromList([ux.dx, ux.dy, 0, 0, vy.dx, vy.dy, 0, 0, 0, 0, 1, 0, a.dx, a.dy, 0, 1]));
      final g = (255 * shade).round();
      canvas.drawImageRect(
        img,
        const Rect.fromLTWH(0, 0, 16, 16),
        const Rect.fromLTWH(-0.06, -0.06, 16.12, 16.12),
        Paint()
          ..filterQuality = FilterQuality.none
          ..colorFilter = ColorFilter.mode(Color.fromARGB(alpha, g, g, g), BlendMode.modulate),
      );
      canvas.restore();
    } else if (m.see) {
      canvas.drawPath(path, Paint()..color = base.withAlpha(min(alpha, 150)));
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withAlpha((alpha * 0.1).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  final side = Tex.get(m.id, true), topI = Tex.get(m.id, false);
  if (right) face(p(uu + 1, vv + 1, zz + 1), p(uu + 1, vv, zz + 1), p(uu + 1, vv + 1, zz), side, 0.68);
  if (left) face(p(uu, vv + 1, zz + 1), p(uu + 1, vv + 1, zz + 1), p(uu, vv + 1, zz), side, 0.84);
  if (top) face(p(uu, vv, zz + 1), p(uu + 1, vv, zz + 1), p(uu, vv + 1, zz + 1), topI, 1.0);
}

class _WorldPainter extends CustomPainter {
  final _BlokAdasiState s;
  final Animation<double> anim;
  _WorldPainter(this.s, this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(c.dx + s.pan.dx, c.dy + s.pan.dy);
    canvas.scale(s.zoom);
    canvas.translate(-c.dx, -c.dy);
    if (s.picture != null) canvas.drawPicture(s.picture!);
    final t = anim.value;
    // görev için parlayan yerler
    final q = s.quest;
    if (q != null && s.questReady) {
      for (final e in q.ghost.entries) {
        final have = s.world.blocks[e.key];
        if (have != null && (e.value < 0 || have == e.value)) continue;
        final (x, y, z) = cxyz(e.key);
        final (u, v) = s._r(x, y);
        final m = e.value < 0 ? mats[matIndex(s.sel) < 0 ? 3 : matIndex(s.sel)] : mats[e.value];
        _ghost(canvas, u, v, z, m.color, (90 + 70 * sin(t * 2 * pi)).toInt());
      }
    }
    // dokunulan yerin önizlemesi
    if (s.previewCell != null) {
      final (x, y, z) = cxyz(s.previewCell!);
      final (u, v) = s._r(x, y);
      _ghost(canvas, u, v, z, s.previewErase ? Colors.red : Colors.white, 200, thick: true);
    }
    // gece fenerleri
    if (s.night) {
      final fi = matIndex('fener');
      for (final e in s.world.blocks.entries) {
        if (e.value != fi) continue;
        final (x, y, z) = cxyz(e.key);
        final (u, v) = s._r(x, y);
        final p = s._p(u + 0.5, v + 0.5, z + 0.5);
        canvas.drawCircle(
            p,
            s.tw * 2.2,
            Paint()
              ..shader = ui.Gradient.radial(p, s.tw * 2.2, [const Color(0x77FFE082), const Color(0x00FFE082)]));
      }
    }
    canvas.restore();
  }

  void _ghost(Canvas canvas, int u, int v, int z, Color c, int a, {bool thick = false}) {
    final fu = u.toDouble(), fv = v.toDouble(), fz = z.toDouble();
    final pts = [
      s._p(fu, fv, fz + 1), s._p(fu + 1, fv, fz + 1), s._p(fu + 1, fv + 1, fz + 1), s._p(fu, fv + 1, fz + 1),
      s._p(fu + 1, fv, fz), s._p(fu + 1, fv + 1, fz), s._p(fu, fv + 1, fz),
    ];
    final outline = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[4].dx, pts[4].dy)
      ..lineTo(pts[5].dx, pts[5].dy)
      ..lineTo(pts[6].dx, pts[6].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..close();
    canvas.drawPath(outline, Paint()..color = c.withAlpha((a * 0.45).toInt()));
    final line = Paint()
      ..color = (thick ? c : Colors.white).withAlpha(a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thick ? 3 : 2;
    canvas.drawPath(outline, line);
    canvas.drawLine(pts[2], pts[5], line);
    canvas.drawLine(pts[2], pts[1], line);
    canvas.drawLine(pts[2], pts[3], line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SkyPainter extends CustomPainter {
  final bool night;
  _SkyPainter(this.night);

  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, s.height),
              night
                  ? const [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF283593)]
                  : const [Color(0xFF81D4FA), Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
              const [0, 0.6, 1]));
    final rnd = Random(4);
    if (night) {
      for (var i = 0; i < 60; i++) {
        canvas.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.5), rnd.nextDouble() * 1.6 + 0.4,
            Paint()..color = Colors.white.withAlpha(150 + rnd.nextInt(100)));
      }
      canvas.drawCircle(Offset(s.width * 0.82, s.height * 0.12), 26, Paint()..color = const Color(0xFFFFF9C4));
      canvas.drawCircle(Offset(s.width * 0.82 + 12, s.height * 0.12 - 8), 24, Paint()..color = const Color(0xFF1F2A80));
    } else {
      final cloud = Paint()..color = Colors.white.withAlpha(210);
      for (final c in const [(0.18, 0.16, 1.0), (0.78, 0.1, 0.8), (0.6, 0.3, 0.6)]) {
        final o = Offset(s.width * c.$1, s.height * c.$2);
        final k = 30 * c.$3;
        canvas.drawCircle(o, k, cloud);
        canvas.drawCircle(o + Offset(k, 6), k * 0.8, cloud);
        canvas.drawCircle(o - Offset(k, -8), k * 0.7, cloud);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
class BlockLogo extends StatefulWidget {
  const BlockLogo({super.key});

  @override
  State<BlockLogo> createState() => _BlockLogoState();
}

class _BlockLogoState extends State<BlockLogo> {
  @override
  void initState() {
    super.initState();
    if (!Tex.ready) {
      Tex.load(mats.map((m) => m.id).toList()).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _LogoPainter(Tex.ready), size: Size.infinite);
}

class _LogoPainter extends CustomPainter {
  final bool ready;
  _LogoPainter(this.ready);

  @override
  void paint(Canvas canvas, Size s) {
    final tw = min(s.width / 2.6, s.height / 2.4);
    final o = Offset(s.width / 2, s.height * 0.22);
    Offset p(double u, double v, double z) => o + Offset((u - v) * tw / 2, (u + v) * tw / 4 - z * tw * 0.6 + tw * 0.4);
    final cubes = [
      (0, 0, 0, 'cim'), (1, 0, 0, 'cim'), (0, 1, 0, 'cim'), (1, 1, 0, 'parke'),
      (0, 0, 1, 'tugla'), (0, 0, 2, 'kiremit'), (1, 1, 1, 'tahta'),
    ]..sort((a, b) => ((a.$1 + a.$2) * 10 + a.$3).compareTo((b.$1 + b.$2) * 10 + b.$3));
    for (final c in cubes) {
      drawTexCube(canvas, mats[matIndex(c.$4)], p, c.$1, c.$2, c.$3, true, true, true);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.ready != ready;
}
