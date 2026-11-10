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

/// Sekmeler: 0 yapı, 1 renkler, 2 doğa, 3 özel (4 = hazır yapılar)
class BlockMat {
  final String id;
  final String name;
  final Color color;
  final int tab;
  final bool start;
  final bool see; // saydam (cam, su, buz, çit)
  final bool glow;
  const BlockMat(this.id, this.name, this.color, this.tab, {this.start = false, this.see = false, this.glow = false});
}

// Sıra önemli: kayıtlı şehirler bu numaraları kullanır. Yeni bloklar sona eklenir.
const mats = <BlockMat>[
  BlockMat('cim', 'çim', Color(0xFF6DBE45), 2, start: true),
  BlockMat('toprak', 'toprak', Color(0xFF8B5A2B), 2, start: true),
  BlockMat('tas', 'taş', Color(0xFF8E8E8E), 0, start: true),
  BlockMat('tahta', 'tahta', Color(0xFFB8834A), 0, start: true),
  BlockMat('kirmizi', 'kırmızı', Color(0xFFE53935), 1, start: true),
  BlockMat('mavi', 'mavi', Color(0xFF1E88E5), 1, start: true),
  BlockMat('sari', 'sarı', Color(0xFFFDD835), 1, start: true),
  BlockMat('yesil', 'yeşil', Color(0xFF43A047), 1, start: true),
  BlockMat('kiremit', 'kiremit', Color(0xFFC0442A), 0, start: true),
  BlockMat('tugla', 'tuğla', Color(0xFFB04A2F), 0, start: true),
  BlockMat('cam', 'cam', Color(0xFF9EE6FF), 0, see: true, start: true),
  BlockMat('beyaz', 'mermer', Color(0xFFF2F0EA), 0),
  BlockMat('altin', 'altın', Color(0xFFFFC928), 3),
  BlockMat('su', 'su', Color(0xFF2E9AE6), 2, see: true, start: true),
  BlockMat('kum', 'kum', Color(0xFFE8D29A), 2, start: true),
  BlockMat('parke', 'parke taşı', Color(0xFF7A7A7A), 0, start: true),
  BlockMat('koyu', 'koyu tahta', Color(0xFF6B4423), 0),
  BlockMat('kutuk', 'kütük', Color(0xFF6B4A2B), 2, start: true),
  BlockMat('yaprak', 'yaprak', Color(0xFF2E7D32), 2, start: true),
  BlockMat('kumtasi', 'kumtaşı', Color(0xFFDCC384), 0),
  BlockMat('kar', 'kar', Color(0xFFF8FBFF), 2),
  BlockMat('buz', 'buz', Color(0xFFA8DDF5), 2, see: true),
  BlockMat('saman', 'saman', Color(0xFFE3C14B), 2),
  BlockMat('kitaplik', 'kitaplık', Color(0xFF9C6B3A), 3),
  BlockMat('kapi', 'kapı', Color(0xFF7A4E2A), 3, start: true),
  BlockMat('fener', 'fener', Color(0xFFFFC107), 3, glow: true),
  BlockMat('elmas', 'elmas', Color(0xFF4DD0E1), 3),
  BlockMat('demir', 'demir', Color(0xFFD6D6D6), 0),
  BlockMat('turuncu', 'turuncu', Color(0xFFFB8C00), 1, start: true),
  BlockMat('mor', 'mor', Color(0xFF8E24AA), 1),
  BlockMat('pembe', 'pembe', Color(0xFFF48FB1), 1),
  BlockMat('siyah', 'siyah', Color(0xFF37373F), 1),
  BlockMat('acikmavi', 'açık mavi', Color(0xFF81D4FA), 1),
  BlockMat('asfalt', 'asfalt', Color(0xFF4A4A50), 0, start: true),
  BlockMat('yol', 'yol çizgisi', Color(0xFF55555B), 0, start: true),
  BlockMat('cicek', 'çiçekli çim', Color(0xFF6DBE45), 2, start: true),
  BlockMat('cit', 'çit', Color(0xFFB8834A), 2, see: true),
  BlockMat('cali', 'çalı', Color(0xFF558B2F), 2),
  BlockMat('kabak', 'kabak', Color(0xFFF07F1A), 2),
  BlockMat('karpuz', 'karpuz', Color(0xFF388E3C), 2),
  BlockMat('mantar', 'mantar', Color(0xFFD32F2F), 2),
  BlockMat('bal', 'bal', Color(0xFFFFB300), 3),
  BlockMat('toprakyol', 'patika', Color(0xFFC9A26B), 2),
  BlockMat('pencere', 'pencere', Color(0xFF9EE6FF), 0, see: true),
  BlockMat('tasduvar', 'taş duvar', Color(0xFF8A8A8A), 0),
  BlockMat('mavicati', 'mavi çatı', Color(0xFF1E5FB5), 0),
];

/// Hece sandığı her açılışta bir grup verir.
const unlockGroups = [
  ['beyaz', 'altin', 'fener'],
  ['koyu', 'pencere', 'cit'],
  ['tasduvar', 'mavicati', 'kitaplik'],
  ['mor', 'pembe', 'acikmavi', 'siyah'],
  ['cali', 'kabak', 'karpuz'],
  ['kar', 'buz', 'toprakyol'],
  ['kumtasi', 'saman', 'demir'],
  ['mantar', 'bal', 'elmas'],
];

int matIndex(String id) => mats.indexWhere((m) => m.id == id);
String itemName(String id) {
  final m = matIndex(id);
  if (m >= 0) return mats[m].name;
  return prefabById(id)?.name ?? id;
}

// ======================= HAZIR YAPILAR =======================

class Prefab {
  final String id;
  final String name;
  final String emoji;
  final List<(int, int, int, int)> Function() cells; // dx (sağ), dy (ileri), dz, malzeme
  const Prefab(this.id, this.name, this.emoji, this.cells);
}

List<(int, int, int, int)> _tree() {
  final k = matIndex('kutuk'), y = matIndex('yaprak');
  return [
    for (var z = 0; z < 3; z++) (0, 0, z, k),
    for (var dx = -1; dx <= 1; dx++)
      for (var dy = -1; dy <= 1; dy++)
        for (var z = 2; z <= 3; z++)
          if (!(dx == 0 && dy == 0 && z == 2)) (dx, dy, z, y),
    (0, 0, 4, y),
  ];
}

List<(int, int, int, int)> _pine() {
  final k = matIndex('kutuk'), y = matIndex('yaprak');
  return [
    for (var z = 0; z < 2; z++) (0, 0, z, k),
    for (var dx = -1; dx <= 1; dx++)
      for (var dy = -1; dy <= 1; dy++) (dx, dy, 2, y),
    for (final d in const [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]) (d.$1, d.$2, 3, y),
    (0, 0, 4, y),
    (0, 0, 5, y),
  ];
}

List<(int, int, int, int)> _house() {
  final t = matIndex('tugla'), k = matIndex('kiremit'), c = matIndex('pencere'), d = matIndex('kapi'), w = matIndex('tahta');
  final out = <(int, int, int, int)>[];
  for (var z = 0; z < 3; z++) {
    for (var dx = -2; dx <= 2; dx++) {
      for (var dy = 0; dy <= 4; dy++) {
        final edge = dx.abs() == 2 || dy == 0 || dy == 4;
        if (!edge) continue;
        var m = t;
        if (dy == 0 && dx == 0 && z < 2) m = d;
        if (z == 1 && ((dx.abs() == 2 && dy == 2) || (dy == 4 && dx == 0) || (dy == 0 && dx.abs() == 1))) m = c;
        out.add((dx, dy, z, m));
      }
    }
  }
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = 1; dy <= 3; dy++) {
      out.add((dx, dy, -1, w)); // döşeme
    }
  }
  for (var dx = -2; dx <= 2; dx++) {
    for (var dy = 0; dy <= 4; dy++) {
      out.add((dx, dy, 3, k));
    }
  }
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = 1; dy <= 3; dy++) {
      out.add((dx, dy, 4, k));
    }
  }
  out.add((0, 2, 5, k));
  return out;
}

List<(int, int, int, int)> _mosque() {
  final b = matIndex('beyaz'), a = matIndex('altin'), d = matIndex('kapi'), c = matIndex('pencere');
  final out = <(int, int, int, int)>[];
  for (var z = 0; z < 3; z++) {
    for (var dx = -2; dx <= 2; dx++) {
      for (var dy = 0; dy <= 4; dy++) {
        final edge = dx.abs() == 2 || dy == 0 || dy == 4;
        if (!edge) continue;
        var m = b;
        if (dy == 0 && dx == 0 && z < 2) m = d;
        if (z == 1 && dx.abs() == 2 && dy == 2) m = c;
        out.add((dx, dy, z, m));
      }
    }
  }
  for (var dx = -2; dx <= 2; dx++) {
    for (var dy = 0; dy <= 4; dy++) {
      out.add((dx, dy, 3, b));
    }
  }
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = 1; dy <= 3; dy++) {
      out.add((dx, dy, 4, a));
    }
  }
  out.add((0, 2, 5, a));
  for (var z = 0; z < 7; z++) {
    out.add((3, 0, z, b)); // minare
  }
  out.add((3, 0, 7, a));
  return out;
}

List<(int, int, int, int)> _bridge() {
  final t = matIndex('tahta'), c = matIndex('cit');
  return [
    for (var dy = 0; dy < 6; dy++) ...[(0, dy, 0, t), (-1, dy, 0, t), (1, dy, 1, c), (-2, dy, 1, c)],
  ];
}

List<(int, int, int, int)> _lamp() {
  final d = matIndex('demir'), f = matIndex('fener');
  return [(0, 0, 0, d), (0, 0, 1, d), (0, 0, 2, d), (0, 0, 3, f)];
}

List<(int, int, int, int)> _pool() {
  final m = matIndex('beyaz'), s = matIndex('su');
  return [
    for (var dx = -2; dx <= 2; dx++)
      for (var dy = 0; dy <= 4; dy++) (dx, dy, 0, (dx.abs() == 2 || dy == 0 || dy == 4) ? m : s),
  ];
}

List<(int, int, int, int)> _garden() {
  final c = matIndex('cit'), f = matIndex('cicek');
  return [
    for (var dx = -2; dx <= 2; dx++)
      for (var dy = 0; dy <= 4; dy++)
        if (dx.abs() == 2 || dy == 0 || dy == 4) (dx, dy, 0, c) else (dx, dy, -1, f),
  ];
}

List<(int, int, int, int)> _road() {
  final a = matIndex('asfalt'), y = matIndex('yol');
  return [for (var dy = 0; dy < 8; dy++) ...[(-1, dy, -1, a), (0, dy, -1, dy.isEven ? y : a), (1, dy, -1, a)]];
}

final prefabs = <Prefab>[
  const Prefab('p_agac', 'ağaç', '🌳', _tree),
  const Prefab('p_cam', 'çam ağacı', '🌲', _pine),
  const Prefab('p_ev', 'ev', '🏠', _house),
  const Prefab('p_cami', 'cami', '🕌', _mosque),
  const Prefab('p_kopru', 'köprü', '🌉', _bridge),
  const Prefab('p_fener', 'sokak lambası', '💡', _lamp),
  const Prefab('p_havuz', 'havuz', '⛲', _pool),
  const Prefab('p_bahce', 'çiçek bahçesi', '🌷', _garden),
  const Prefab('p_yol', 'yol', '🛣️', _road),
];

Prefab? prefabById(String id) {
  for (final p in prefabs) {
    if (p.id == id) return p;
  }
  return null;
}

// ======================= DÜNYA =======================

const W = 40, D = 40, H = 20;
int ck(int x, int y, int z) => x + y * W + z * W * D;
(int, int, int) cxyz(int k) => (k % W, (k ~/ W) % D, k ~/ (W * D));
bool inside(int x, int y, int z) => x >= 0 && y >= 0 && z >= 0 && x < W && y < D && z < H;

// Şehirdeki önemli yerler
const riverY = 21;
const roadX = 19;
const roadY = 10;

class BlockWorld {
  final Map<int, int> blocks = {};
  int version = 0;

  int count(String mat) {
    final i = matIndex(mat);
    return blocks.values.where((v) => v == i).length;
  }

  int treeCount() {
    final k = matIndex('kutuk');
    var n = 0;
    for (var x = 0; x < W; x++) {
      for (var y = 0; y < D; y++) {
        if (blocks[ck(x, y, 1)] == k) n++;
      }
    }
    return n;
  }

  int topZ(int x, int y) {
    for (var z = H - 1; z >= 0; z--) {
      if (blocks.containsKey(ck(x, y, z))) return z;
    }
    return -1;
  }

  void put(int x, int y, int z, int m) {
    if (inside(x, y, z)) blocks[ck(x, y, z)] = m;
  }

  String encode() {
    final b = blocks.entries.map((e) => '${e.key}:${e.value}').join(',');
    return 'v3|$b|';
  }

  bool decode(String s) {
    final parts = s.split('|');
    if (parts.length != 3) return false;
    if (parts[0] == 'v3') {
      blocks.clear();
      for (final e in parts[1].split(',')) {
        final kv = e.split(':');
        if (kv.length == 2) blocks[int.parse(kv[0])] = int.parse(kv[1]);
      }
      version++;
      return true;
    }
    if (parts[0] == 'v1' || parts[0] == 'v2') {
      // Eski 10x10 adayı yeni şehrin ortasına taşı
      seed();
      const o = 15;
      for (var x = o; x < o + 10; x++) {
        for (var y = o; y < o + 10; y++) {
          for (var z = 0; z < H; z++) {
            blocks.remove(ck(x, y, z));
          }
        }
      }
      for (final e in parts[1].split(',')) {
        final kv = e.split(':');
        if (kv.length != 2) continue;
        final k = int.parse(kv[0]);
        final x = k % 10, y = (k ~/ 10) % 10, z = k ~/ 100;
        put(x + o, y + o, z, int.parse(kv[1]));
      }
      for (final e in parts[2].split(',')) {
        final kv = e.split(':');
        if (kv.length != 2) continue;
        final k = int.parse(kv[0]);
        final x = k % 10 + o, y = (k ~/ 10) % 10 + o, z = k ~/ 100;
        if (const {'agac', 'camagaci', 'pembe', 'pembe_agac', 'meyve', 'cali'}.contains(kv[1])) {
          stamp(_tree(), x, y, z, 0);
        } else if (kv[1] == 'lale') {
          put(x, y, z - 1, matIndex('cicek'));
        }
      }
      version++;
      return true;
    }
    return false;
  }

  /// Hazır yapıyı yerleştirir. dir: 0 +y ileri, 1 +x, 2 -y, 3 -x
  int stamp(List<(int, int, int, int)> cells, int x, int y, int z, int dir) {
    var n = 0;
    for (final c in cells) {
      int dx = c.$1, dy = c.$2;
      switch (dir) {
        case 1:
          (dx, dy) = (c.$2, -c.$1);
        case 2:
          (dx, dy) = (-c.$1, -c.$2);
        case 3:
          (dx, dy) = (-c.$2, c.$1);
      }
      final xx = x + dx, yy = y + dy, zz = z + c.$3;
      if (!inside(xx, yy, zz)) continue;
      if (c.$3 < 0 || !blocks.containsKey(ck(xx, yy, zz))) {
        blocks[ck(xx, yy, zz)] = c.$4;
        n++;
      }
    }
    version++;
    return n;
  }

  void seed() {
    blocks.clear();
    final cim = matIndex('cim'), su = matIndex('su'), kum = matIndex('kum'), cicek = matIndex('cicek');
    final asf = matIndex('asfalt'), yol = matIndex('yol');
    for (var x = 0; x < W; x++) {
      for (var y = 0; y < D; y++) {
        var m = cim;
        final ry = riverY + (sin(x / 6) * 1.2).round();
        if (y == ry || y == ry + 1) {
          m = su;
        } else if ((y == ry - 1 || y == ry + 2) && x % 7 < 4) {
          m = kum;
        }
        if (x == roadX && (y < ry - 1 || y > ry + 2)) m = (y % 2 == 0) ? yol : asf;
        if ((x == roadX - 1 || x == roadX + 1) && (y < ry - 1 || y > ry + 2)) m = asf;
        if (y == roadY) m = (x % 2 == 0 && x != roadX) ? yol : asf;
        if (m == cim && (x * 7 + y * 13) % 23 == 0) m = cicek;
        blocks[ck(x, y, 0)] = m;
      }
    }
    // Köprünün iki ucu (orta boş, görev)
    // Komşu teyzenin evi (çatısında delikler var)
    stamp(_house(), 25, 13, 1, 0);
    for (final c in roofHoles) {
      blocks.remove(c);
    }
    // ağaçlar
    for (final p in const [(4, 4), (9, 30), (31, 5), (34, 33), (12, 15), (28, 27), (5, 15), (36, 14), (15, 35)]) {
      stamp(_tree(), p.$1, p.$2, 1, 0);
    }
    stamp(_pine(), 7, 34, 1, 0);
    stamp(_pine(), 33, 2, 1, 0);
    version++;
  }

  static final roofHoles = {ck(23, 15, 4), ck(27, 15, 4), ck(25, 13, 4), ck(26, 17, 4)};
}

// ======================= GÖREVLER =======================

class Quest {
  final String id;
  final Who who;
  final String text;
  final String speech;
  final int stars;
  final int hearts;
  final Map<int, int> ghost; // hücre -> malzeme (-1: herhangi)
  final (int, int) Function(BlockWorld w)? progress;
  final bool exact;
  final String? needs;
  final String? unit;
  final (int, int) focus;
  const Quest(this.id, this.who, this.text, this.speech, this.focus,
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

int _seedTrees = 11;

final List<Quest> quests = [
  Quest('kule', Who.tamirci, 'Parlayan yere 5 bloklu kule yap', 'Parlayan yere, blokları üst üste koyarak beş bloklu bir kule yap!', (16, 16),
      ghost: {for (var z = 1; z <= 5; z++) ck(16, 16, z): -1}),
  Quest('cati', Who.tozbulut, 'Komşu teyzenin çatısına kiremit koy', 'Komşu teyzenin evinin çatısı akıyor! Parlayan yerlere kiremit koyalım.',
      (25, 15), hearts: 1, ghost: {for (final c in BlockWorld.roofHoles) c: matIndex('kiremit')}),
  Quest('tas7', Who.robot, 'Şehre tam 7 taş blok koy', 'Şehre tam yedi tane taş blok koy. Ne eksik ne fazla!', (16, 16),
      exact: true, unit: 'taş', progress: (w) => (w.count('tas'), 7)),
  Quest('blue', Who.papagan, 'Use four blue blocks! (4 mavi blok)', 'Use four blue blocks! Dört mavi blok kullan.', (16, 16),
      unit: 'mavi', progress: (w) => (min(w.count('mavi'), 4), 4)),
  Quest('agac3', Who.tozbulut, '3 ağaç dik (🌳 Hazır)', 'Ağaç dikmek sadakadır. Hazır sekmesinden üç ağaç dikelim!', (12, 26),
      unit: 'ağaç', progress: (w) => (max(0, min(3, w.treeCount() - _seedTrees)), 3)),
  Quest('kopru', Who.tamirci, 'Nehrin üstüne köprü kur (🌉 Hazır)', 'Yolumuz nehirde bitiyor! Parlayan yerlere köprü kuralım.', (roadX, riverY),
      ghost: {for (var y = riverY - 1; y <= riverY + 2; y++) ck(roadX, y, 1): -1}),
  Quest('fener', Who.baykus, 'Yola 2 fener koy', 'Akşam olunca yol karanlık oluyor. Yolun kenarına iki fener koyalım!', (roadX, 14),
      needs: 'fener', unit: 'fener', progress: (w) => (min(w.count('fener'), 2), 2)),
  Quest('mescit', Who.baykus, 'Şehre bir cami yap (🕌 Hazır)', 'Şehrimize güzel bir cami yapalım! Hazır sekmesindeki camiyi kullanabilirsin.', (12, 30),
      stars: 2, hearts: 2, needs: 'altin', unit: 'altın', progress: (w) => (min(w.count('altin'), 10), 10)),
];

/// Robot Rakam'ın matematik görevi.
class MathTask {
  final int kind; // 0 toplama, 1 çıkarma, 2 eşitleme
  final int a, b;
  final int x, y;
  final Map<int, int> add = {};
  final Set<int> remove = {};
  bool asked = false;
  MathTask(this.kind, this.a, this.b, this.x, this.y);

  int get answer => kind == 0 ? a + b : (kind == 1 ? a - b : b - a);
  String get question => kind == 0 ? '$a + $b = ?' : (kind == 1 ? '$a − $b = ?' : '$a + ? = $b');
  String get say => kind == 0
      ? '$a artı $b kaç eder?'
      : (kind == 1 ? '$a blok vardı, $b tanesini sildin. Kaç blok kaldı?' : '$a bloklu kuleye kaç blok ekledin ki $b oldu?');
  String get intro => kind == 0
      ? 'Kırmızı kulede $a blok var. Üstüne $b mavi blok koy!'
      : (kind == 1 ? 'Bu kulede $a blok var. Parlayan $b bloğu sil!' : 'Kuleleri eşitle! Kısa kuleye blok ekle.');
  bool built(BlockWorld w) =>
      add.entries.every((e) => w.blocks.containsKey(e.key)) && remove.every((c) => !w.blocks.containsKey(c));
}

// ======================= EKRAN =======================

class BlokAdasi extends StatefulWidget {
  const BlokAdasi({super.key});

  @override
  State<BlokAdasi> createState() => _BlokAdasiState();
}

/// Görünen bir yüz: hücre + yön (0 üst, 1 +x, 2 -x, 3 +y, 4 -y)
class _Face {
  final int cell;
  final int dir;
  final int mat;
  _Face(this.cell, this.dir, this.mat);
}

const _dirs = [(0, 0, 1), (1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0)];

class _BlokAdasiState extends State<BlokAdasi> with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  final world = BlockWorld();
  String sel = 'tahta';
  bool erase = false;
  int tab = 0;
  bool moveMode = false;
  final List<String> undo = [];
  List<_Face> exposed = [];
  int exposedVersion = -1;
  // kamera
  double yaw = 0.78, pitch = 0.62, zoom = 1.0;
  double fx = 19.5, fy = 17, fz = 0;
  double _y0 = 0, _p0 = 0, _z0 = 1;
  Offset _f0 = Offset.zero;
  double _fx0 = 0, _fy0 = 0;
  bool _moved = false;
  int _pointers = 1;
  Size area = Size.zero;
  // önizleme
  int? previewCell;
  bool previewErase = false;
  MathTask? task;
  final night = DateTime.now().hour >= 19 || DateTime.now().hour < 6;
  // son çizimin dokunma bilgisi
  final _hit = _HitData();

  Quest? get quest {
    for (final q in quests) {
      if (!game.blockQuests.contains(q.id)) return q;
    }
    return null;
  }

  bool get questReady => quest != null && (quest!.needs == null || unlocked(quest!.needs!));

  bool unlocked(String id) {
    if (id.startsWith('p_')) return true;
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
      if (mounted) setState(() {});
    });
    final q = quest;
    if (q != null) _lookAt(q.focus.$1, q.focus.$2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Say.show(context, Who.tamirci, 'Blok Şehrine hoş geldin! Parmağınla sürükle, şehir dönsün. Bir blok seç ve dokunarak koy.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 6500), _sayQuest);
    });
  }

  @override
  void dispose() {
    pulse.dispose();
    for (final v in _verts) {
      v.dispose();
    }
    game.saveBlocks(world.encode());
    super.dispose();
  }

  void _lookAt(int x, int y) {
    fx = x + 0.5;
    fy = y + 0.5;
  }

  // ---------- görevler ----------
  void _sayQuest() {
    if (!mounted) return;
    final t = task;
    if (t != null) {
      Say.show(context, Who.robot, t.intro);
      return;
    }
    final q = quest;
    if (q == null) {
      Say.show(context, Who.robot, 'Bütün görevler bitti! 🤖 tuşuna basarsan sana matematik görevi veririm.');
      return;
    }
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

  void _goQuest() {
    final t = task;
    setState(() {
      if (t != null) {
        _lookAt(t.x, t.y);
      } else if (quest != null) {
        _lookAt(quest!.focus.$1, quest!.focus.$2);
      }
      zoom = max(zoom, 1.3);
    });
    _sayQuest();
  }

  void _check() {
    final t = task;
    if (t != null && !t.asked && t.built(world)) {
      t.asked = true;
      Future.delayed(const Duration(milliseconds: 400), () => _askMath(t));
    }
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
      Future.delayed(const Duration(milliseconds: 4200), _goQuest);
    } else {
      game.addSticker('k_tamirci_sevin');
    }
  }

  /// Robot Rakam'dan yeni matematik görevi.
  void _newMath() {
    final r = Random();
    // kameranın baktığı yerin yakınında boş iki sütun bul
    (int, int)? spot;
    for (var tries = 0; tries < 200 && spot == null; tries++) {
      final x = (fx + r.nextInt(9) - 4).round().clamp(1, W - 3).toInt(), y = (fy + r.nextInt(9) - 4).round().clamp(1, D - 2).toInt();
      var ok = true;
      for (final xx in [x, x + 1]) {
        if (world.topZ(xx, y) != 0) ok = false;
        final g = world.blocks[ck(xx, y, 0)];
        if (g == matIndex('su')) ok = false;
      }
      if (ok) spot = (x, y);
    }
    if (spot == null) {
      Say.show(context, Who.robot, 'Burada boş yer yok. Şehrin başka bir yerine git, sonra tekrar bas.');
      return;
    }
    final kind = r.nextInt(3);
    final red = matIndex('kirmizi'), blue = matIndex('mavi');
    late MathTask t;
    _push();
    if (kind == 0) {
      final a = 1 + r.nextInt(4), b = 1 + r.nextInt(4);
      t = MathTask(0, a, b, spot.$1, spot.$2);
      for (var z = 1; z <= a; z++) {
        world.put(t.x, t.y, z, red);
      }
      for (var z = a + 1; z <= a + b; z++) {
        t.add[ck(t.x, t.y, z)] = blue;
      }
    } else if (kind == 1) {
      final a = 3 + r.nextInt(5), b = 1 + r.nextInt(min(3, a - 1));
      t = MathTask(1, a, b, spot.$1, spot.$2);
      for (var z = 1; z <= a; z++) {
        world.put(t.x, t.y, z, blue);
      }
      for (var z = a - b + 1; z <= a; z++) {
        t.remove.add(ck(t.x, t.y, z));
      }
    } else {
      final a = 1 + r.nextInt(4), b = a + 1 + r.nextInt(4);
      t = MathTask(2, a, b, spot.$1, spot.$2);
      for (var z = 1; z <= a; z++) {
        world.put(t.x, t.y, z, red);
      }
      for (var z = 1; z <= b; z++) {
        world.put(t.x + 1, t.y, z, matIndex('sari'));
      }
      for (var z = a + 1; z <= b; z++) {
        t.add[ck(t.x, t.y, z)] = red;
      }
    }
    world.version++;
    setState(() {
      task = t;
      _lookAt(t.x, t.y);
      zoom = max(zoom, 1.5);
      sel = kind == 0 ? 'mavi' : 'kirmizi';
      tab = 1;
      erase = kind == 1;
    });
    Sfx.play('unlock');
    Say.show(context, Who.robot, t.intro);
  }

  Future<void> _askMath(MathTask t) async {
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _MathDialog(t.question, t.say, t.answer));
    if (!mounted || ok != true) return;
    game.addStars(1);
    Sfx.play('finish');
    setState(() {
      task = null;
      erase = false;
    });
    Say.show(context, Who.robot, 'Aferin! ${t.question.replaceAll('?', '${t.answer}')}. Bir yıldız kazandın!');
  }

  // ---------- kamera ----------
  double get scale => min(area.width, area.height) / 22 * zoom;

  double _sy = 0, _cy = 1, _sp = 0.5, _cp = 0.8, _s = 20;

  /// Kamera açılarını önbelleğe alır (her çizimden önce).
  void cam() {
    _sy = sin(yaw);
    _cy = cos(yaw);
    _sp = sin(pitch);
    _cp = cos(pitch);
    _s = scale;
  }

  Offset proj(double x, double y, double z) {
    final dx = x - fx, dy = y - fy, dz = z - fz;
    return Offset(area.width / 2 + (dx * _cy - dy * _sy) * _s, area.height * 0.55 + (dx * _sy + dy * _cy) * _sp * _s - dz * _cp * _s);
  }

  double depth(double x, double y, double z) {
    final dx = x - fx, dy = y - fy, dz = z - fz;
    return (dx * _sy + dy * _cy) * _cp + dz * _sp;
  }

  // çizim önbelleği
  String _geoKey = '';
  final List<ui.Vertices> _verts = [];

  /// Kameranın "ileri" yönüne en yakın eksen (0 +y, 1 +x, 2 -y, 3 -x): ekranın yukarısı.
  int get forwardDir {
    // ekranda yukarı = -(sin yaw, cos yaw)
    final ax = -sin(yaw), ay = -cos(yaw);
    if (ax.abs() > ay.abs()) return ax > 0 ? 1 : 3;
    return ay > 0 ? 0 : 2;
  }

  // ---------- görünen yüzler ----------
  void _rebuildExposed() {
    if (exposedVersion == world.version) return;
    exposedVersion = world.version;
    final out = <_Face>[];
    for (final e in world.blocks.entries) {
      final (x, y, z) = cxyz(e.key);
      final m = mats[e.value];
      for (var d = 0; d < 5; d++) {
        final (nx, ny, nz) = _dirs[d];
        final xx = x + nx, yy = y + ny, zz = z + nz;
        if (inside(xx, yy, zz)) {
          final o = world.blocks[ck(xx, yy, zz)];
          if (o != null && (!mats[o].see || (m.see && o == e.value))) continue;
        }
        out.add(_Face(e.key, d, e.value));
      }
    }
    exposed = out;
  }

  // ---------- dokunma ----------
  (int, bool, int)? _target(Offset p) {
    final n = _hit.count;
    for (var i = n - 1; i >= 0; i--) {
      if (!_hit.contains(i, p)) continue;
      final f = _hit.faces[i];
      final (x, y, z) = cxyz(f.cell);
      if (erase) {
        if (z == 0 && world.blocks.length < 2) return null;
        return (f.cell, true, f.dir);
      }
      final (nx, ny, nz) = _dirs[f.dir];
      final xx = x + nx, yy = y + ny, zz = z + nz;
      if (!inside(xx, yy, zz)) return null;
      final k = ck(xx, yy, zz);
      if (world.blocks.containsKey(k)) return null;
      return (k, false, f.dir);
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

  Future<void> _up(Offset p) async {
    final t = _target(p);
    setState(() => previewCell = null);
    if (t == null) return;
    final (k, del, dir) = t;
    if (del) {
      _push();
      world.blocks.remove(k);
      world.version++;
      Sfx.play('pop');
      _changed();
      return;
    }
    final pf = prefabById(sel);
    if (pf != null) {
      if (dir != 0) return; // hazır yapılar zemine konur
      final ok = await _prefabQuestion(pf);
      if (!ok || !mounted) return;
      _push();
      final (x, y, z) = cxyz(k);
      final n = world.stamp(pf.cells(), x, y, z, forwardDir); // kapı kameraya bakar, yapı ileri doğru uzar
      Sfx.play('finish');
      Voice.say('${trCapitalize(pf.name)} hazır! $n blok kullandık.');
      _changed();
      return;
    }
    _push();
    world.blocks[k] = matIndex(sel);
    world.version++;
    Sfx.play(mats[matIndex(sel)].tab == 1 ? 'pop' : 'tok');
    _changed();
  }

  Future<bool> _prefabQuestion(Prefab pf) async {
    final r = Random();
    final add = r.nextBool();
    final a = 2 + r.nextInt(6);
    final b = add ? 1 + r.nextInt(min(4, 10 - a)) : 1 + r.nextInt(a - 1);
    final q = add ? '$a + $b = ?' : '$a − $b = ?';
    final say = add
        ? '${trCapitalize(pf.name)} için Robot Rakam soruyor: $a artı $b kaç eder?'
        : '${trCapitalize(pf.name)} için Robot Rakam soruyor: $a eksi $b kaç eder?';
    final ok = await showDialog<bool>(context: context, builder: (_) => _MathDialog(q, say, add ? a + b : a - b, emoji: pf.emoji));
    return ok == true;
  }

  void _push() {
    undo.add(world.encode());
    if (undo.length > 30) undo.removeAt(0);
  }

  void _changed() {
    setState(() {});
    game.saveBlocks(world.encode());
    _check();
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
        title: const Text('Şehri baştan kuralım mı?'),
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
    task = null;
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
        tab = mats[matIndex(sel)].tab;
        erase = false;
      });
      Sfx.play('unlock');
      await showDialog<void>(context: context, builder: (_) => _NewItems(group));
      if (!mounted) return;
      _check();
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
    _rebuildExposed();
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _SkyPainter(night))),
        SafeArea(
          child: Column(children: [
            TopBar('Blok Şehri', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              _Tool(Icons.smart_toy, _newMath, color: const Color(0xFFB3E5FC)),
              _Tool(Icons.refresh, _reset),
            ])),
            _questBar(),
            Expanded(
              child: LayoutBuilder(builder: (_, c) {
                area = Size(c.maxWidth, c.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _down(d.localPosition),
                  onTapUp: (d) => _up(d.localPosition),
                  onTapCancel: () => setState(() => previewCell = null),
                  onScaleStart: (d) {
                    _y0 = yaw;
                    _p0 = pitch;
                    _z0 = zoom;
                    _f0 = d.localFocalPoint;
                    _fx0 = fx;
                    _fy0 = fy;
                    _moved = false;
                    _pointers = d.pointerCount;
                  },
                  onScaleUpdate: (d) {
                    final delta = d.localFocalPoint - _f0;
                    if (!_moved && delta.distance < 8 && d.pointerCount < 2) return;
                    _moved = true;
                    if (d.pointerCount > _pointers) _pointers = d.pointerCount;
                    setState(() {
                      previewCell = null;
                      if (_pointers >= 2 || moveMode) {
                        zoom = (_z0 * d.scale).clamp(0.5, 3.0).toDouble();
                        final s = scale, sp = sin(pitch);
                        final a = delta.dx / s, b = delta.dy / (sp * s);
                        final wx = a * cos(yaw) + b * sin(yaw), wy = -a * sin(yaw) + b * cos(yaw);
                        fx = (_fx0 - wx).clamp(0, W.toDouble()).toDouble();
                        fy = (_fy0 - wy).clamp(0, D.toDouble()).toDouble();
                      } else {
                        yaw = _y0 - delta.dx * 0.008;
                        pitch = (_p0 + delta.dy * 0.004).clamp(0.35, 1.25).toDouble();
                      }
                    });
                  },
                  child: ClipRect(child: CustomPaint(size: area, painter: _WorldPainter(this, pulse))),
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

  Widget _questBar() {
    final t = task;
    final q = quest;
    String text;
    Who who;
    int a = 0, b = 0;
    var showBar = true;
    var over = false;
    if (t != null) {
      who = Who.robot;
      text = '🤖 ${t.intro}';
      b = t.add.length + t.remove.length;
      a = t.add.keys.where(world.blocks.containsKey).length + t.remove.where((c) => !world.blocks.containsKey(c)).length;
    } else if (q != null) {
      who = q.who;
      if (questReady) {
        text = q.text;
        (a, b) = q.prog(world);
        over = q.exact && a > b;
      } else {
        text = 'Önce 🎁 hece sandığını aç!';
        showBar = false;
      }
    } else {
      who = Who.robot;
      text = 'Görevler bitti! 🤖 tuşuyla matematik görevi al.';
      showBar = false;
    }
    return GestureDetector(
      onTap: _goQuest,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t != null ? const Color(0xFF4FC3F7) : const Color(0xFFFFD54F), width: 3),
        ),
        child: Row(children: [
          SizedBox(width: 40, height: 44, child: Pic(whoPic(who))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              if (showBar) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: b == 0 ? 0 : min(1, a / b),
                        minHeight: 10,
                        color: over ? Colors.red : Colors.green,
                        backgroundColor: Colors.black12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$a / $b', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: over ? Colors.red : Colors.black87)),
                ]),
              ],
            ]),
          ),
          const Icon(Icons.my_location, color: Colors.black45),
        ]),
      ),
    );
  }

  Widget _controls() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          _Tool(Icons.zoom_in, () => setState(() => zoom = min(3.0, zoom + 0.35))),
          _Tool(Icons.zoom_out, () => setState(() => zoom = max(0.5, zoom - 0.35))),
          _Tool(moveMode ? Icons.open_with : Icons.threesixty, () {
            setState(() => moveMode = !moveMode);
            Voice.say(moveMode ? 'Kaydır' : 'Döndür');
          }, color: moveMode ? const Color(0xFFFFF59D) : Colors.white),
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
    const names = ['🧱 Yapı', '🎨 Renk', '🌳 Doğa', '✨ Özel', '🏠 Hazır'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(children: [
        for (var i = 0; i < names.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Sfx.play('click');
                setState(() => tab = i);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: tab == i ? Colors.white : Colors.white.withAlpha(120),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(names[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _palette() {
    final items = <Widget>[
      if (tab == 4)
        for (final p in prefabs)
          _PaletteItem(p.name, sel == p.id && !erase, () => _select(p.id),
              child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 34))))
      else
        for (final m in mats)
          if (m.tab == tab && unlocked(m.id)) _PaletteItem(m.name, sel == m.id && !erase, () => _select(m.id), child: _MatSwatch(m)),
    ];
    final locked = tab == 4 ? 0 : mats.where((m) => m.tab == tab && !unlocked(m.id)).length;
    return Container(
      height: 92,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(14))),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        children: [
          ...items,
          if (locked > 0)
            _PaletteItem('$locked kilitli', false, _chest, child: const Center(child: Text('🎁', style: TextStyle(fontSize: 30)))),
        ],
      ),
    );
  }
}

/// Son çizilen yüzlerin ekran köşeleri (dokunma için).
class _HitData {
  List<_Face> faces = [];
  Float32List quads = Float32List(0);
  int count = 0;

  bool contains(int i, Offset p) {
    final q = quads;
    final o = i * 8;
    var sign = 0;
    for (var k = 0; k < 4; k++) {
      final ax = q[o + k * 2], ay = q[o + k * 2 + 1];
      final bx = q[o + ((k + 1) % 4) * 2], by = q[o + ((k + 1) % 4) * 2 + 1];
      final cr = (bx - ax) * (p.dy - ay) - (by - ay) * (p.dx - ax);
      final s = cr > 0 ? 1 : (cr < 0 ? -1 : 0);
      if (s == 0) continue;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }
}

class _WorldPainter extends CustomPainter {
  final _BlokAdasiState s;
  final Animation<double> anim;
  _WorldPainter(this.s, this.anim) : super(repaint: anim);

  static const _shade = [1.0, 0.80, 0.66, 0.72, 0.88];

  @override
  void paint(Canvas canvas, Size size) {
    s.area = size;
    s.cam();
    _sea(canvas);
    final key = '${s.yaw},${s.pitch},${s.zoom},${s.fx},${s.fy},$size,${s.world.version},${Tex.atlas != null}';
    if (key != s._geoKey) {
      s._geoKey = key;
      _build(size);
    }
    final paint = Paint();
    final atlas = Tex.atlas;
    if (atlas != null) {
      paint.shader = ui.ImageShader(atlas, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage, filterQuality: FilterQuality.none);
    } else {
      paint.color = Colors.white;
    }
    for (final v in s._verts) {
      canvas.drawVertices(v, BlendMode.modulate, paint);
    }
    _overlay(canvas);
  }

  void _build(Size size) {
    for (final v in s._verts) {
      v.dispose();
    }
    s._verts.clear();
    final sy = s._sy, cy = s._cy;
    // görünen yüzleri seç ve derinliğe göre sırala
    final faces = s.exposed;
    final vis = <int>[];
    final dep = <double>[];
    for (var i = 0; i < faces.length; i++) {
      final f = faces[i];
      if (f.dir != 0) {
        final (nx, ny, _) = _dirs[f.dir];
        if (nx * sy + ny * cy <= 0) continue;
      }
      final (x, y, z) = cxyz(f.cell);
      final (nx, ny, nz) = _dirs[f.dir];
      final c = s.proj(x + 0.5, y + 0.5, z + 0.5);
      if (c.dx < -60 || c.dy < -60 || c.dx > size.width + 60 || c.dy > size.height + 60) continue;
      vis.add(i);
      dep.add(s.depth(x + 0.5 + nx * 0.5, y + 0.5 + ny * 0.5, z + 0.5 + nz * 0.5));
    }
    final order = List<int>.generate(vis.length, (i) => i)..sort((a, b) => dep[a].compareTo(dep[b]));
    final n = order.length;
    final quads = Float32List(n * 8);
    final hitFaces = <_Face>[];
    const chunk = 12000;
    for (var start = 0; start < n; start += chunk) {
      final end = min(n, start + chunk);
      final m = end - start;
      final pos = Float32List(m * 8);
      final uv = Float32List(m * 8);
      final col = Int32List(m * 4);
      final idx = Uint16List(m * 6);
      for (var j = 0; j < m; j++) {
        final f = faces[vis[order[start + j]]];
        final (x, y, z) = cxyz(f.cell);
        final c = _corners(x.toDouble(), y.toDouble(), z.toDouble(), f.dir);
        for (var k = 0; k < 4; k++) {
          final p = s.proj(c[k * 3], c[k * 3 + 1], c[k * 3 + 2]);
          pos[j * 8 + k * 2] = p.dx;
          pos[j * 8 + k * 2 + 1] = p.dy;
          quads[(start + j) * 8 + k * 2] = p.dx;
          quads[(start + j) * 8 + k * 2 + 1] = p.dy;
        }
        hitFaces.add(f);
        final r = Tex.tile(f.mat * 2 + (f.dir == 0 ? 0 : 1));
        final u0 = (r.left + 0.02) , v0 = (r.top + 0.02), u1 = (r.right - 0.02), v1 = (r.bottom - 0.02);
        uv.setAll(j * 8, [u0, v0, u1, v0, u1, v1, u0, v1]);
        final sh = _shade[f.dir];
        int cc;
        if (Tex.atlas != null) {
          final g = (255 * sh).round();
          cc = (0xFF << 24) | (g << 16) | (g << 8) | g;
        } else {
          final mc = mats[f.mat].color;
          cc = (0xFF << 24) | ((mc.r * 255 * sh).round() << 16) | ((mc.g * 255 * sh).round() << 8) | (mc.b * 255 * sh).round();
        }
        col.setAll(j * 4, [cc, cc, cc, cc]);
        final b = j * 4;
        idx.setAll(j * 6, [b, b + 1, b + 2, b, b + 2, b + 3]);
      }
      s._verts.add(ui.Vertices.raw(ui.VertexMode.triangles, pos, textureCoordinates: uv, colors: col, indices: idx));
    }
    s._hit
      ..faces = hitFaces
      ..quads = quads
      ..count = n;
  }

  void _overlay(Canvas canvas) {
    final t = anim.value;
    // görev için parlayan yerler
    final q = s.quest;
    if (s.task != null) {
      for (final e in s.task!.add.entries) {
        if (s.world.blocks.containsKey(e.key)) continue;
        _ghost(canvas, e.key, mats[e.value].color, (100 + 70 * sin(t * 2 * pi)).toInt());
      }
      for (final c in s.task!.remove) {
        if (!s.world.blocks.containsKey(c)) continue;
        _ghost(canvas, c, Colors.red, (120 + 80 * sin(t * 2 * pi)).toInt(), thick: true);
      }
    } else if (q != null && s.questReady) {
      for (final e in q.ghost.entries) {
        final have = s.world.blocks[e.key];
        if (have != null && (e.value < 0 || have == e.value)) continue;
        final col = e.value < 0 ? Colors.white : mats[e.value].color;
        _ghost(canvas, e.key, col, (90 + 70 * sin(t * 2 * pi)).toInt());
      }
    }
    if (s.previewCell != null) {
      _ghost(canvas, s.previewCell!, s.previewErase ? Colors.red : Colors.white, 220, thick: true);
    }
    if (s.night) {
      final fi = matIndex('fener');
      for (final e in s.world.blocks.entries) {
        if (e.value != fi) continue;
        final (x, y, z) = cxyz(e.key);
        final p = s.proj(x + 0.5, y + 0.5, z + 0.5);
        final r = s.scale * 2.4;
        canvas.drawCircle(p, r, Paint()..shader = ui.Gradient.radial(p, r, [const Color(0x88FFE082), const Color(0x00FFE082)]));
      }
    }
  }

  /// Bir yüzün dört köşesi (sol üst, sağ üst, sağ alt, sol alt) dünya koordinatında.
  static List<double> _corners(double x, double y, double z, int dir) {
    switch (dir) {
      case 0:
        return [x, y, z + 1, x + 1, y, z + 1, x + 1, y + 1, z + 1, x, y + 1, z + 1];
      case 1:
        return [x + 1, y + 1, z + 1, x + 1, y, z + 1, x + 1, y, z, x + 1, y + 1, z];
      case 2:
        return [x, y, z + 1, x, y + 1, z + 1, x, y + 1, z, x, y, z];
      case 3:
        return [x, y + 1, z + 1, x + 1, y + 1, z + 1, x + 1, y + 1, z, x, y + 1, z];
      default:
        return [x + 1, y, z + 1, x, y, z + 1, x, y, z, x + 1, y, z];
    }
  }

  void _sea(Canvas canvas) {
    const m = 4.0;
    final a = s.proj(-m, -m, 0), b = s.proj(W + m, -m, 0), c = s.proj(W + m, D + m, 0), d = s.proj(-m, D + m, 0);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = s.night ? const Color(0xFF0D47A1) : const Color(0xFF29B6F6));
    const e = 0.5;
    final a2 = s.proj(-e, -e, 0), b2 = s.proj(W + e, -e, 0), c2 = s.proj(W + e, D + e, 0), d2 = s.proj(-e, D + e, 0);
    canvas.drawPath(
        Path()
          ..moveTo(a2.dx, a2.dy)
          ..lineTo(b2.dx, b2.dy)
          ..lineTo(c2.dx, c2.dy)
          ..lineTo(d2.dx, d2.dy)
          ..close(),
        Paint()..color = const Color(0xFFF2DFA6));
  }

  void _ghost(Canvas canvas, int cell, Color c, int a, {bool thick = false}) {
    final (x, y, z) = cxyz(cell);
    final fx = x.toDouble(), fy = y.toDouble(), fz = z.toDouble();
    final pts = [
      for (final p in const [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0), (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)])
        s.proj(fx + p.$1, fy + p.$2, fz + p.$3)
    ];
    // dışbükey zarf yerine: 6 yüzü yarı saydam çiz
    final fill = Paint()..color = c.withAlpha((a * 0.28).toInt());
    const facesIdx = [
      [4, 5, 6, 7],
      [1, 2, 6, 5],
      [0, 3, 7, 4],
      [3, 2, 6, 7],
      [0, 1, 5, 4],
    ];
    for (final f in facesIdx) {
      canvas.drawPath(
          Path()
            ..moveTo(pts[f[0]].dx, pts[f[0]].dy)
            ..lineTo(pts[f[1]].dx, pts[f[1]].dy)
            ..lineTo(pts[f[2]].dx, pts[f[2]].dy)
            ..lineTo(pts[f[3]].dx, pts[f[3]].dy)
            ..close(),
          fill);
    }
    final line = Paint()
      ..color = c.withAlpha(a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thick ? 3 : 2;
    const edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)];
    for (final e in edges) {
      canvas.drawLine(pts[e.$1], pts[e.$2], line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ======================= PENCERELER VE PARÇALAR =======================

class _MathDialog extends StatefulWidget {
  final String question;
  final String say;
  final int answer;
  final String emoji;
  const _MathDialog(this.question, this.say, this.answer, {this.emoji = '🤖'});

  @override
  State<_MathDialog> createState() => _MathDialogState();
}

class _MathDialogState extends State<_MathDialog> {
  late final List<int> options;
  int shake = 0;
  int? wrong;

  @override
  void initState() {
    super.initState();
    final r = Random();
    final s = <int>{widget.answer};
    while (s.length < 3) {
      final v = widget.answer + r.nextInt(5) - 2;
      if (v >= 0 && v <= 12) s.add(v);
    }
    options = s.toList()..shuffle(r);
    Voice.say(widget.say);
  }

  void _tap(int v) {
    if (v == widget.answer) {
      Sfx.play('correct');
      Voice.say('Evet, $v!');
      Navigator.pop(context, true);
    } else {
      Sfx.play('wrong');
      Voice.say('Hmm, bir daha say bakalım. Parmaklarını kullanabilirsin!');
      setState(() {
        shake++;
        wrong = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFE1F5FE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 80, child: Pic('k_robot')),
              const SizedBox(width: 8),
              Text(widget.emoji, style: const TextStyle(fontSize: 46)),
            ]),
            const SizedBox(height: 8),
            Text(widget.question, style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
            const SizedBox(height: 14),
            Shake(
              trigger: shake,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (final o in options)
                  ChoiceTile(
                    size: 70,
                    color: wrong == o ? const Color(0xFFFFCDD2) : Colors.white,
                    onTap: () => _tap(o),
                    child: Text('$o', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç', style: TextStyle(fontSize: 16)),
            ),
          ]),
        ),
      );
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
                SizedBox(width: 70, height: 70, child: _MatSwatch(mats[matIndex(id)])),
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
  final Color color;
  const _Tool(this.icon, this.onTap, {this.color = Colors.white});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(2),
        child: Bouncy(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
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

/// Küçük resimler için dokulu küp (izometrik).
void drawTexCube(Canvas canvas, BlockMat m, Offset Function(double, double, double) p, int u, int v, int z, bool top, bool right,
    bool left) {
  final uu = u.toDouble(), vv = v.toDouble(), zz = z.toDouble();
  void face(Offset a, Offset b, Offset d, ui.Image? img, double shade) {
    final c = b + d - a;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
    final base = Color.lerp(Colors.black, m.color, shade)!;
    if (!m.see) canvas.drawPath(path, Paint()..color = base);
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
          ..colorFilter = ColorFilter.mode(Color.fromARGB(255, g, g, g), BlendMode.modulate),
      );
      canvas.restore();
    } else if (m.see) {
      canvas.drawPath(path, Paint()..color = base.withAlpha(150));
    }
  }

  final side = Tex.get(m.id, true), topI = Tex.get(m.id, false);
  if (right) face(p(uu + 1, vv + 1, zz + 1), p(uu + 1, vv, zz + 1), p(uu + 1, vv + 1, zz), side, 0.68);
  if (left) face(p(uu, vv + 1, zz + 1), p(uu + 1, vv + 1, zz + 1), p(uu, vv + 1, zz), side, 0.84);
  if (top) face(p(uu, vv, zz + 1), p(uu + 1, vv, zz + 1), p(uu, vv + 1, zz + 1), topI, 1.0);
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

/// Ana ekrandaki Blok Şehri kartı için küçük blok yığını.
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
