import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'blok_bag.dart';
import 'blok_char.dart';
import 'blok_life.dart';
import 'blok_shapes.dart';
import 'blok_friends.dart';
import 'blok_globe.dart';
import 'blok_map.dart';
import 'blok_treasure.dart';
import 'blok_village.dart';
import 'blok_words.dart';
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
  BlockMat('tahta', 'tahta', Color(0xFFB8834A), 7, start: true),
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
  BlockMat('koyu', 'koyu tahta', Color(0xFF6B4423), 7, start: true),
  BlockMat('kutuk', 'kütük', Color(0xFF6B4A2B), 7, start: true),
  BlockMat('yaprak', 'yaprak', Color(0xFF2E7D32), 2, start: true),
  BlockMat('kumtasi', 'kumtaşı', Color(0xFFDCC384), 0),
  BlockMat('kar', 'kar', Color(0xFFF8FBFF), 2),
  BlockMat('buz', 'buz', Color(0xFFA8DDF5), 2, see: true),
  BlockMat('saman', 'saman', Color(0xFFE3C14B), 2),
  BlockMat('kitaplik', 'kitaplık', Color(0xFF9C6B3A), 7),
  BlockMat('kapi', 'kapı', Color(0xFF7A4E2A), 7, start: true),
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
  BlockMat('pencere', 'pencere', Color(0xFF9EE6FF), 0, see: true, start: true),
  BlockMat('tasduvar', 'taş duvar', Color(0xFF8A8A8A), 0),
  BlockMat('mavicati', 'mavi çatı', Color(0xFF1E5FB5), 0),
  BlockMat('hazine', 'hazine sandığı', Color(0xFF8D5524), 9),
  BlockMat('tarla', 'tarla', Color(0xFF6B4220), 5, start: true),
  BlockMat('mesale', 'meşale', Color(0xFFFFB300), 6, start: true, glow: true),
  BlockMat('lamba', 'lamba', Color(0xFFFFFDE7), 6, glow: true),
  BlockMat('led_kirmizi', 'kırmızı led', Color(0xFFFF1744), 6, glow: true),
  BlockMat('led_mavi', 'mavi led', Color(0xFF2979FF), 6, glow: true),
  BlockMat('led_yesil', 'yeşil led', Color(0xFF00E676), 6, glow: true),
  BlockMat('led_mor', 'mor led', Color(0xFFD500F9), 6, glow: true),
  BlockMat('led_sari', 'sarı led', Color(0xFFFFEA00), 6, glow: true),
  BlockMat('komur', 'kömür', Color(0xFF424242), 2),
  BlockMat('demirc', 'demir cevheri', Color(0xFFBCAAA4), 2),
  BlockMat('altinc', 'altın cevheri', Color(0xFFE6C35C), 2),
  BlockMat('acikkutuk', 'açık kütük', Color(0xFFD7CCC8), 7, start: true),
  BlockMat('zemin', 'parke zemin', Color(0xFFC49A6C), 7, start: true),
  BlockMat('ahsapcati', 'ahşap çatı', Color(0xFF8D6E63), 7, start: true),
  BlockMat('kirmizitahta', 'kırmızı tahta', Color(0xFFB23A2E), 7),
  BlockMat('yesiltahta', 'yeşil tahta', Color(0xFF4E7D3A), 7),
  BlockMat('mavitahta', 'mavi tahta', Color(0xFF3E6BA8), 7),
  BlockMat('heceta', 'hece taşı', Color(0xFF9575CD), 2, glow: true),
  BlockMat('tezgah', 'kelime tezgâhı', Color(0xFFA1887F), 9, start: true),
  BlockMat('tabela', 'tabela', Color(0xFFD7B98E), 9),
  BlockMat('hecekapi', 'hece kapısı', Color(0xFF7E57C2), 7),
  BlockMat('totem', 'hava totemi', Color(0xFF26A69A), 9),
  BlockMat('yakutc', 'yakut madeni', Color(0xFFC62828), 2, glow: true),
  BlockMat('firuzec', 'firuze madeni', Color(0xFF26C6DA), 2, glow: true),
  BlockMat('gumusc', 'gümüş madeni', Color(0xFFCFD8DC), 2),
  BlockMat('kehribarc', 'kehribar madeni', Color(0xFFFFA000), 2, glow: true),
  BlockMat('istiridye', 'istiridye', Color(0xFFD7CCC8), 2),
  BlockMat('miras', 'miras sandığı', Color(0xFF00897B), 9, glow: true),
];

/// Değerli taş yatakları (kırınca adını heceleyerek çıkarılır)
const gemOres = {'yakutc': 'yakut', 'firuzec': 'firuze', 'gumusc': 'gumus', 'kehribarc': 'kehribar', 'istiridye': 'inci'};

/// Doku atlasındaki sıra: bloklar, sonra beyaz ve yüz karoları.
List<String> get texIds => [...mats.map((m) => m.id), '_beyaz', '_yuz'];

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
  if (id.startsWith('seed_')) return '${cropById(id.substring(5)).name} tohumu';
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

List<(int, int, int, int)> _school() {
  final w = matIndex('sari'), b = matIndex('beyaz'), c = matIndex('pencere'), d = matIndex('kapi'), k = matIndex('kiremit');
  final pole = matIndex('demir'), red = matIndex('kirmizi');
  final out = <(int, int, int, int)>[];
  for (var z = 0; z < 4; z++) {
    for (var dx = -4; dx <= 4; dx++) {
      for (var dy = 0; dy <= 6; dy++) {
        final edge = dx.abs() == 4 || dy == 0 || dy == 6;
        if (!edge) continue;
        var m = (dx.abs() == 4 && (dy == 0 || dy == 6)) ? b : w;
        if (dy == 0 && dx == 0 && z < 2) m = d;
        if ((z == 1 || z == 2) && ((dx.abs() == 4 && dy.isOdd) || ((dy == 0 || dy == 6) && dx.abs() >= 2 && dx.abs() <= 3))) m = c;
        if (z == 3) m = b;
        out.add((dx, dy, z, m));
      }
    }
  }
  for (var dx = -3; dx <= 3; dx++) {
    for (var dy = 1; dy <= 5; dy++) {
      out.add((dx, dy, -1, matIndex('tahta')));
    }
  }
  for (var dx = -4; dx <= 4; dx++) {
    for (var dy = 0; dy <= 6; dy++) {
      out.add((dx, dy, 4, k));
    }
  }
  for (var dx = -3; dx <= 3; dx++) {
    for (var dy = 1; dy <= 5; dy++) {
      out.add((dx, dy, 5, k));
    }
  }
  // bayrak direği ve bayrak
  for (var z = 0; z <= 7; z++) {
    out.add((6, 0, z, pole));
  }
  for (final p in const [(7, 6), (8, 6), (9, 6), (7, 7), (8, 7), (9, 7)]) {
    out.add((p.$1, 0, p.$2, red));
  }
  return out;
}

List<(int, int, int, int)> _tower() {
  final t = matIndex('tasduvar'), d = matIndex('kapi'), c = matIndex('pencere'), red = matIndex('kirmizi'), pole = matIndex('demir');
  final out = <(int, int, int, int)>[];
  for (var z = 0; z < 8; z++) {
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = 0; dy <= 2; dy++) {
        if (dx == 0 && dy == 1) continue;
        var m = t;
        if (dy == 0 && dx == 0 && z < 2) m = d;
        if (z == 5 && dx == 0 && dy == 0) m = c;
        out.add((dx, dy, z, m));
      }
    }
  }
  for (var dx = -2; dx <= 2; dx++) {
    for (var dy = -1; dy <= 3; dy++) {
      out.add((dx, dy, 8, t));
      if ((dx.abs() == 2 || dy == -1 || dy == 3) && (dx + dy).isEven) out.add((dx, dy, 9, t));
    }
  }
  for (var z = 9; z <= 11; z++) {
    out.add((0, 1, z, pole));
  }
  out.add((1, 1, 11, red));
  out.add((2, 1, 11, red));
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

List<(int, int, int, int)> _barn() {
  final r = matIndex('kirmizitahta'), w = matIndex('beyaz'), c = matIndex('ahsapcati'), h = matIndex('saman'), z = matIndex('zemin');
  final out = <(int, int, int, int)>[];
  for (var zz = 0; zz < 3; zz++) {
    for (var dx = -2; dx <= 2; dx++) {
      for (var dy = 0; dy <= 5; dy++) {
        final edge = dx.abs() == 2 || dy == 5 || (dy == 0 && dx.abs() == 2);
        if (!edge) continue;
        out.add((dx, dy, zz, (dx.abs() == 2 && (dy == 0 || dy == 5)) ? w : r));
      }
    }
  }
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = 1; dy <= 4; dy++) {
      out.add((dx, dy, -1, z));
    }
  }
  out.addAll([(-1, 4, 0, h), (1, 4, 0, h), (0, 4, 0, h), (-1, 4, 1, h)]);
  for (var dx = -2; dx <= 2; dx++) {
    for (var dy = 0; dy <= 5; dy++) {
      out.add((dx, dy, 3, c));
      if (dx.abs() <= 1) out.add((dx, dy, 4, c));
      if (dx == 0) out.add((dx, dy, 5, c));
    }
  }
  return out;
}

List<(int, int, int, int)> _pen() {
  final c = matIndex('cit'), k = matIndex('kapi'), s = matIndex('saman');
  return [
    for (var dx = -3; dx <= 3; dx++)
      for (var dy = 0; dy <= 6; dy++)
        if (dx.abs() == 3 || dy == 0 || dy == 6) (dx, dy, 0, (dy == 0 && dx == 0) ? k : c),
    (2, 5, 0, s),
  ];
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
  const Prefab('p_ahir', 'ahır', '🛖', _barn),
  const Prefab('p_agil', 'ağıl', '🐑', _pen),
  const Prefab('p_okul', 'okul', '🏫', _school),
  const Prefab('p_kule', 'kule', '🏰', _tower),
];

Prefab? prefabById(String id) {
  for (final p in prefabs) {
    if (p.id == id) return p;
  }
  return null;
}

// ======================= DÜNYA =======================

/// Başlangıç şehri 40x40; "Büyüt" ile her yöne genişler (en fazla 1024x1024).
const W = 40, D = 40, H = 20;
const _o = 512, _sz = 1024;
int ck(int x, int y, int z) => (x + _o) + (y + _o) * _sz + z * _sz * _sz;
(int, int, int) cxyz(int k) => (k % _sz - _o, (k ~/ _sz) % _sz - _o, k ~/ (_sz * _sz));

// Dünyanın şu anki sınırları (dahil)
int minX = 0, maxX = W - 1, minY = 0, maxY = D - 1;
bool inside(int x, int y, int z) => x >= minX && y >= minY && z >= 0 && x <= maxX && y <= maxY && z < H;
int get worldW => maxX - minX + 1;
int get worldD => maxY - minY + 1;

/// Yeni arazi türleri
const biomes = [
  ('cayir', 'Çayır', '🌼'),
  ('orman', 'Orman', '🌲'),
  ('gol', 'Göl', '💧'),
  ('kar', 'Karlı dağ', '🏔️'),
  ('kumsal', 'Kumsal', '🏖️'),
  ('tepe', 'Tepeler', '⛰️'),
  ('dag', 'Mağaralı dağ', '🗻'),
  ('adalar', 'Adalar denizi', '🏝️'),
  ('koyler', 'Köyler', '🏘️'),
];

/// Denizdeki adaların ve karadaki köylerin adları
const placeNames = ['Sürgü', 'Darende', 'Ulupınar', 'Malatya', 'Kocaeli', 'Darıca', 'İstanbul', 'Ankara', 'İzmir', 'Elazığ', 'Harput'];

// Şehirdeki önemli yerler
const riverY = 21;
const roadX = 19;
const roadY = 10;

class BlockWorld {
  final Map<int, int> blocks = {};
  final Map<int, int> shapeAt = {}; // hücre -> şekil*4 + yön
  int version = 0;

  void removeAt(int k) {
    blocks.remove(k);
    shapeAt.remove(k);
  }

  int count(String mat) {
    final i = matIndex(mat);
    return blocks.values.where((v) => v == i).length;
  }

  int treeCount() {
    final k = matIndex('kutuk');
    var n = 0;
    for (final e in blocks.entries) {
      if (e.value != k) continue;
      final (x, y, z) = cxyz(e.key);
      if (blocks[ck(x, y, z - 1)] != k && z >= 1) n++;
    }
    return n;
  }

  /// Adı olan yerler (ada, köy): ad -> (x, y)
  final Map<String, (int, int)> places = {};

  /// Elips (küre gibi) dünya: merkez ve yarıçaplar. 0 ise henüz şişirilmedi.
  double ecx = 0, ecy = 0, erx = 0, ery = 0;

  int topZ(int x, int y) {
    for (var z = H - 1; z >= 0; z--) {
      if (blocks.containsKey(ck(x, y, z))) return z;
    }
    return -1;
  }

  void put(int x, int y, int z, int m) {
    if (inside(x, y, z)) blocks[ck(x, y, z)] = m;
  }

  /// v4: sınırlar | zemin katmanı (her hücre bir harf) | diğer bloklar
  String encode() {
    final g = StringBuffer();
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final m = blocks[ck(x, y, 0)];
        g.writeCharCode(m == null ? 46 : 65 + m);
      }
    }
    final b = StringBuffer();
    for (final e in blocks.entries) {
      if (e.key < _sz * _sz) continue; // z == 0
      if (b.isNotEmpty) b.write(',');
      b
        ..write(e.key)
        ..write(':')
        ..write(e.value);
    }
    final sh = shapeAt.entries.map((e) => '${e.key}:${e.value}').join(',');
    final pl = places.entries.map((e) => '${e.key}:${e.value.$1}:${e.value.$2}').join(';');
    return 'v4|$minX,$maxX,$minY,$maxY|$g|$b|$sh|$pl|${ecx.toStringAsFixed(1)},${ecy.toStringAsFixed(1)},${erx.toStringAsFixed(1)},${ery.toStringAsFixed(1)}';
  }

  bool decode(String s) {
    final parts = s.split('|');
    if (parts[0] == 'v4' && parts.length >= 4) {
      shapeAt.clear();
      places.clear();
      ecx = ecy = erx = ery = 0;
      if (parts.length >= 7) {
        final e = parts[6].split(',').map(double.tryParse).toList();
        if (e.length == 4 && !e.contains(null)) {
          ecx = e[0]!;
          ecy = e[1]!;
          erx = e[2]!;
          ery = e[3]!;
        }
      }
      if (parts.length >= 6 && parts[5].isNotEmpty) {
        for (final e in parts[5].split(';')) {
          final kv = e.split(':');
          if (kv.length == 3) places[kv[0]] = (int.parse(kv[1]), int.parse(kv[2]));
        }
      }
      if (parts.length >= 5 && parts[4].isNotEmpty) {
        for (final e in parts[4].split(',')) {
          final kv = e.split(':');
          if (kv.length == 2) shapeAt[int.parse(kv[0])] = int.parse(kv[1]);
        }
      }
      final bb = parts[1].split(',').map(int.parse).toList();
      minX = bb[0];
      maxX = bb[1];
      minY = bb[2];
      maxY = bb[3];
      blocks.clear();
      final g = parts[2];
      var i = 0;
      for (var y = minY; y <= maxY; y++) {
        for (var x = minX; x <= maxX; x++) {
          final c = i < g.length ? g.codeUnitAt(i) : 46;
          i++;
          if (c != 46) blocks[ck(x, y, 0)] = c - 65;
        }
      }
      if (parts[3].isNotEmpty) {
        for (final e in parts[3].split(',')) {
          final kv = e.split(':');
          if (kv.length == 2) blocks[int.parse(kv[0])] = int.parse(kv[1]);
        }
      }
      version++;
      return true;
    }
    if (parts.length != 3) return false;
    if (parts[0] == 'v3') {
      // 40x40 eski şehir: anahtar = x + y*40 + z*1600
      minX = 0;
      maxX = W - 1;
      minY = 0;
      maxY = D - 1;
      blocks.clear();
      for (final e in parts[1].split(',')) {
        final kv = e.split(':');
        if (kv.length != 2) continue;
        final k = int.parse(kv[0]);
        blocks[ck(k % 40, (k ~/ 40) % 40, k ~/ 1600)] = int.parse(kv[1]);
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

  /// Hazır yapının konacağı hücreler (henüz koymaz), alttan üste sıralı.
  List<(int, int)> plan(List<(int, int, int, int)> cells, int x, int y, int z, int dir) {
    final out = <(int, int)>[];
    final seen = <int>{};
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
      final k = ck(xx, yy, zz);
      if (!seen.add(k)) continue;
      if (c.$3 < 0 || !blocks.containsKey(k)) out.add((k, c.$4));
    }
    out.sort((a, b) => (a.$1 ~/ (_sz * _sz)).compareTo(b.$1 ~/ (_sz * _sz)));
    return out;
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

  /// Kameranın baktığı yöne yeni arazi ekler. dir: 0 +y, 1 +x, 2 -y, 3 -x
  void expand(int dir, String biome, {int size = 20}) {
    final r = Random();
    if (biome == 'adalar') size = 90;
    if (biome == 'koyler') size = 64;
    int x0, x1, y0, y1;
    switch (dir) {
      case 0:
        (x0, x1, y0, y1) = (minX, maxX, maxY + 1, maxY + size);
      case 1:
        (x0, x1, y0, y1) = (maxX + 1, maxX + size, minY, maxY);
      case 2:
        (x0, x1, y0, y1) = (minX, maxX, minY - size, minY - 1);
      default:
        (x0, x1, y0, y1) = (minX - size, minX - 1, minY, maxY);
    }
    x0 = max(x0, -_o);
    y0 = max(y0, -_o);
    x1 = min(x1, _o - 1);
    y1 = min(y1, _o - 1);
    if (x0 > x1 || y0 > y1) return;
    // sınırdaki su ve yollar yeni araziye uzasın
    final cont = {matIndex('su'), matIndex('asfalt'), matIndex('yol'), matIndex('parke'), matIndex('toprakyol')};
    int? edgeMat(int x, int y) {
      int ex = x, ey = y;
      if (dir == 0) ey = maxY;
      if (dir == 2) ey = minY;
      if (dir == 1) ex = maxX;
      if (dir == 3) ex = minX;
      final m = blocks[ck(ex, ey, 0)];
      return (m != null && cont.contains(m)) ? m : null;
    }

    final cim = matIndex('cim'), cicek = matIndex('cicek'), su = matIndex('su'), kum = matIndex('kum');
    final kar = matIndex('kar'), toprak = matIndex('toprak'), tas = matIndex('tas'), yaprak = matIndex('yaprak'), kutuk = matIndex('kutuk');
    final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
    final rad = min(x1 - x0, y1 - y0) / 2;
    final seedA = r.nextDouble() * 10;
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        final d = sqrt(pow(x - cx, 2) + pow(y - cy, 2)) / max(1, rad);
        var m = cim;
        var h = 0;
        switch (biome) {
          case 'gol':
            m = d < 0.55 ? su : (d < 0.72 ? kum : (r.nextInt(9) == 0 ? cicek : cim));
          case 'kar':
            h = max(0, ((1 - d) * 6 + sin(x / 2.5 + seedA) + cos(y / 3.0)).round());
            m = kar;
          case 'kumsal':
            m = d < 0.4 ? su : kum;
          case 'tepe':
            h = max(0, ((1 - d) * 4 + sin(x / 3 + seedA) * 1.2 + cos(y / 2.7) * 1.2).round());
            m = cim;
          case 'dag':
            m = r.nextInt(9) == 0 ? cicek : cim;
          case 'adalar':
            m = su;
          case 'koyler':
            m = r.nextInt(14) == 0 ? cicek : cim;
          default:
            m = r.nextInt(biome == 'cayir' ? 5 : 12) == 0 ? cicek : cim;
        }
        final e = biome == 'adalar' ? null : edgeMat(x, y);
        if (e != null) {
          m = e;
          h = 0;
        }
        blocks[ck(x, y, 0)] = m;
        for (var z = 1; z <= h && z < H - 1; z++) {
          final top = z == h;
          blocks[ck(x, y, z)] = biome == 'kar' ? (top ? kar : (z > 3 ? tas : toprak)) : (top ? cim : toprak);
        }
      }
    }
    if (biome == 'dag') mountain(x0 + 1, x1 - 1, y0 + 1, y1 - 1, r);
    final oldMinX = minX, oldMaxX = maxX, oldMinY = minY, oldMaxY = maxY;
    minX = min(minX, x0);
    maxX = max(maxX, x1);
    minY = min(minY, y0);
    maxY = max(maxY, y1);
    if (biome == 'adalar') _islands(x0, x1, y0, y1, r);
    if (biome == 'koyler') _villages(x0, x1, y0, y1, r);
    // ağaçlar
    final trees = switch (biome) { 'dag' => 3, 'orman' => 22, 'cayir' => 4, 'tepe' => 6, 'kar' => 7, 'gol' => 5, _ => 2 };
    for (var i = 0; i < trees; i++) {
      final x = x0 + 1 + r.nextInt(max(1, x1 - x0 - 1)), y = y0 + 1 + r.nextInt(max(1, y1 - y0 - 1));
      final z = topZ(x, y);
      final g = blocks[ck(x, y, z)];
      if (g == su || g == null || cont.contains(g)) continue;
      if (biome == 'kar' || (biome == 'orman' && i.isEven)) {
        stamp(_pine(), x, y, z + 1, 0);
      } else {
        stamp(_tree(), x, y, z + 1, 0);
      }
    }
    if (biome == 'kumsal') {
      for (var i = 0; i < 4; i++) {
        final x = x0 + r.nextInt(x1 - x0 + 1), y = y0 + r.nextInt(y1 - y0 + 1);
        if (blocks[ck(x, y, 0)] == kum && topZ(x, y) == 0) {
          for (var z = 1; z <= 3; z++) {
            blocks[ck(x, y, z)] = kutuk;
          }
          for (final dd in const [(1, 0), (-1, 0), (0, 1), (0, -1), (0, 0)]) {
            put(x + dd.$1, y + dd.$2, 4, yaprak);
          }
        }
      }
    }
    for (var i = 0; i < 2; i++) {
      putChest(x0 + 2 + r.nextInt(max(1, x1 - x0 - 3)), y0 + 2 + r.nextInt(max(1, y1 - y0 - 3)));
    }
    if (oldMinX == minX && oldMaxX == maxX && oldMinY == minY && oldMaxY == maxY) return;
    version++;
  }

  /// Alanı ızgaraya bölüp her hücreye bir yer koyar.
  List<(int, int, double, double)> _grid(int x0, int x1, int y0, int y1, int n, Random r) {
    final w = x1 - x0 + 1, h = y1 - y0 + 1;
    final cols = w >= h ? 4 : 3;
    final rows = (n / cols).ceil();
    final cw = w / cols, ch = h / rows;
    final out = <(int, int, double, double)>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (out.length >= n) break;
        final cx = (x0 + cw * (col + 0.5) + (r.nextDouble() - 0.5) * cw * 0.15).round();
        final cy = (y0 + ch * (row + 0.5) + (r.nextDouble() - 0.5) * ch * 0.15).round();
        out.add((cx, cy, cw, ch));
      }
    }
    return out;
  }

  /// Denizde adlı adalar: kumsal, çimenli tepe, ağaç, ev ya da cami.
  void _islands(int x0, int x1, int y0, int y1, Random r) {
    final kum = matIndex('kum'), cim = matIndex('cim'), toprak = matIndex('toprak'), su = matIndex('su');
    final tahta = matIndex('tahta'), kutuk = matIndex('kutuk');
    final cells = _grid(x0, x1, y0, y1, placeNames.length, r);
    for (var i = 0; i < cells.length; i++) {
      final (cx, cy, cw, ch) = cells[i];
      final rad = max(3.0, min(9.5, min(cw, ch) / 2 - 2));
      final ph = r.nextDouble() * 6;
      for (var x = (cx - rad - 1).floor(); x <= cx + rad + 1; x++) {
        for (var y = (cy - rad - 1).floor(); y <= cy + rad + 1; y++) {
          if (!inside(x, y, 0)) continue;
          final a = atan2(y - cy, x - cx);
          final d = sqrt(pow(x - cx, 2) + pow(y - cy, 2)) / (rad * (1 + 0.1 * sin(a * 3 + ph)));
          if (d > 1) continue;
          if (d > 0.8) {
            blocks[ck(x, y, 0)] = kum;
          } else {
            blocks[ck(x, y, 0)] = toprak;
            blocks[ck(x, y, 1)] = cim;
          }
        }
      }
      final name = placeNames[i];
      if (rad >= 6.5) {
        // iki ev, ortada meydan; büyük adalarda cami
        stamp(_house(), cx - 3, cy - 6, 2, 0);
        stamp(_house(), cx + 3, cy - 6, 2, 0);
        if (rad >= 8.5) stamp(i % 2 == 1 ? _mosque() : _house(), cx, cy + 2, 2, 0);
      } else if (rad >= 4.4) {
        stamp(i % 3 == 1 ? _mosque() : _house(), cx, cy - 5, 2, 0);
      } else {
        stamp(_lamp(), cx + 1, cy, 2, 0);
      }
      stamp(_lamp(), cx - 1, cy + 1, 2, 0);
      for (var t = 0; t < 4; t++) {
        final a = r.nextDouble() * 2 * pi;
        final tx = (cx + cos(a) * rad * 0.62).round(), ty = (cy + sin(a) * rad * 0.62).round();
        if (topZ(tx, ty) == 1 && (ty - cy).abs() > 1) stamp(_tree(), tx, ty, 2, 0);
      }
      // iskele: meydandan doğuya denize uzanan tahta yol
      for (var x = cx + 2; x <= cx + rad.ceil() + 4; x++) {
        if (!inside(x, cy, 0)) break;
        final m = blocks[ck(x, cy, 0)];
        if (m == su || m == kum) {
          blocks[ck(x, cy, 0)] = tahta;
          if (m == su && (x - cx).isEven) blocks[ck(x, cy + 1, 0)] = kutuk;
        }
      }
      // kıyıda istiridyeler (içinde inci)
      final ist = matIndex('istiridye');
      for (var k = 0; k < 3; k++) {
        final a = r.nextDouble() * 2 * pi;
        final x = (cx + cos(a) * (rad + 1.5)).round(), y = (cy + sin(a) * (rad + 1.5)).round();
        if (inside(x, y, 0) && blocks[ck(x, y, 0)] == su) blocks[ck(x, y, 0)] = ist;
      }
      places['$name Adası'] = (cx, cy);
    }
  }

  /// Elipsin içinde mi? (1'den küçükse kara)
  double ellipse(double x, double y) => erx == 0 ? 0 : pow((x - ecx) / erx, 2) + pow((y - ecy) / ery, 2).toDouble();

  /// Dünyayı balon gibi her yana birden şişirir: elipsin yeni halkasına
  /// arazi (çayır, tepe, orman, göl, maden), dışına okyanus gelir.
  /// Dönüş: büyüdü mü?
  bool inflate(double step, Random r) {
    final oldE = erx, oldRy0 = ery;
    final ox0 = minX, ox1 = maxX, oy0 = minY, oy1 = maxY;
    if (erx == 0) {
      ecx = (minX + maxX) / 2;
      ecy = (minY + maxY) / 2;
      erx = (maxX - minX) / 2 * 1.22 + 6;
      ery = (maxY - minY) / 2 * 1.22 + 6;
    } else {
      if (erx > 230) return false;
      final k = ery / erx;
      erx += step;
      ery += step * k;
    }
    final nx0 = max(-_o, (ecx - erx - 5).floor()), nx1 = min(_o - 1, (ecx + erx + 5).ceil());
    final ny0 = max(-_o, (ecy - ery - 5).floor()), ny1 = min(_o - 1, (ecy + ery + 5).ceil());
    final oldRx = oldE, oldRy = oldRy0;
    double oldEll(int x, int y) => oldRx == 0 ? 0 : pow((x - ecx) / oldRx, 2) + pow((y - ecy) / oldRy, 2).toDouble();
    final cim = matIndex('cim'), cicek = matIndex('cicek'), su = matIndex('su'), kum = matIndex('kum');
    final toprak = matIndex('toprak'), tas = matIndex('tas'), kar = matIndex('kar');
    final gems = [matIndex('yakutc'), matIndex('firuzec'), matIndex('gumusc'), matIndex('kehribarc')];
    final ist = matIndex('istiridye');
    final seedA = r.nextDouble() * 10, seedB = r.nextDouble() * 10;
    final treeSpots = <(int, int)>[];
    final hillTop = <int, int>{};
    minX = min(minX, nx0);
    maxX = max(maxX, nx1);
    minY = min(minY, ny0);
    maxY = max(maxY, ny1);
    for (var x = nx0; x <= nx1; x++) {
      for (var y = ny0; y <= ny1; y++) {
        final inOld = x >= ox0 && x <= ox1 && y >= oy0 && y <= oy1;
        final e = ellipse(x.toDouble(), y.toDouble());
        if (inOld) {
          // eski okyanus/kumsal halkası şimdi karaya dönüşsün
          if (oldE == 0 || oldEll(x, y) <= 0.9 || e > 0.9) continue;
          for (var z = 0; z < H; z++) {
            blocks.remove(ck(x, y, z));
          }
        }
        if (e > 1) {
          blocks[ck(x, y, 0)] = (e < 1.08 && r.nextInt(30) == 0) ? ist : su;
          continue;
        }
        if (e > 0.9) {
          blocks[ck(x, y, 0)] = kum;
          continue;
        }
        // arazi: dalgalı tepeler, göller, ormanlar
        final n = sin(x * 0.09 + seedA) + cos(y * 0.08 + seedB) + sin((x + y) * 0.05 + seedA * 2) * 0.8;
        if (n < -1.7) {
          blocks[ck(x, y, 0)] = su; // göl
          continue;
        }
        final h = n > 1.1 ? ((n - 1.1) * 5).round().clamp(0, 9) : 0;
        blocks[ck(x, y, 0)] = h > 0 ? toprak : (r.nextInt(14) == 0 ? cicek : cim);
        for (var z = 1; z <= h; z++) {
          var m = z == h ? (h >= 7 ? kar : (h >= 4 ? tas : cim)) : (z < h - 1 ? tas : toprak);
          if (z < h && m == tas && r.nextInt(18) == 0) m = gems[r.nextInt(gems.length)];
          blocks[ck(x, y, z)] = m;
        }
        if (h > 0) hillTop[ck(x, y, 0)] = h;
        if (h == 0 && r.nextInt(38) == 0) treeSpots.add((x, y));
      }
    }
    for (final (x, y) in treeSpots) {
      stamp(r.nextInt(4) == 0 ? _pine() : _tree(), x, y, 1, 0);
    }
    return true;
  }

  /// Her köyün ve adanın meydanına bir miras sandığı; dağlara ve tepelere birkaç değerli taş.
  bool ensureTreasures(Random r) {
    final mi = matIndex('miras');
    if (blocks.values.contains(mi)) return false;
    for (final e in places.entries) {
      final (cx, cy) = e.value;
      for (final (dx, dy) in const [(2, 1), (-2, 1), (1, 2), (-1, 2), (2, -1), (3, 0), (0, 3)]) {
        final x = cx + dx, y = cy + dy;
        if (!inside(x, y, 0)) continue;
        final z = topZ(x, y);
        final m = blocks[ck(x, y, z)];
        if (m == matIndex('su') || z + 1 >= H) continue;
        if (blocks.containsKey(ck(x, y, z + 1))) continue;
        blocks[ck(x, y, z + 1)] = mi;
        break;
      }
    }
    // var olan taş bloklarının bazıları değerli taş olsun
    final gems = [matIndex('yakutc'), matIndex('firuzec'), matIndex('gumusc'), matIndex('kehribarc')];
    final tas = matIndex('tas');
    final stones = blocks.entries.where((e) => e.value == tas).map((e) => e.key).toList()..shuffle(r);
    for (final k in stones.take(16)) {
      blocks[k] = gems[r.nextInt(gems.length)];
    }
    return true;
  }

  /// Deniz, adalar ve köyler yoksa kendisi ekler (dünya kendiliğinden büyük olsun).
  bool ensureLands() {
    var added = false;
    if (!places.keys.any((k) => k.endsWith('Köyü'))) {
      expand(0, 'koyler');
      added = true;
    }
    if (!places.keys.any((k) => k.endsWith('Adası'))) {
      expand(1, 'adalar');
      added = true;
    }
    return added;
  }

  /// Karada adlı köyler: patika yollar, evler, bazılarında cami, ağaçlar.
  void _villages(int x0, int x1, int y0, int y1, Random r) {
    final yol = matIndex('toprakyol');
    final cells = _grid(x0, x1, y0, y1, placeNames.length, r);
    for (var i = 0; i < cells.length; i++) {
      final (cx, cy, _, _) = cells[i];
      for (var d = -6; d <= 6; d++) {
        if (inside(cx + d, cy, 0)) blocks[ck(cx + d, cy, 0)] = yol;
        if (inside(cx, cy + d, 0)) blocks[ck(cx, cy + d, 0)] = yol;
      }
      stamp(_house(), cx - 4, cy + 2, 1, 0);
      stamp(_house(), cx + 4, cy + 2, 1, 0);
      stamp(i % 3 == 0 ? _mosque() : _house(), cx - 4, cy - 2, 1, 2);
      stamp(_tree(), cx + 4, cy - 4, 1, 0);
      stamp(_lamp(), cx + 1, cy + 1, 1, 0);
      places['${placeNames[i]} Köyü'] = (cx, cy);
    }
  }

  void seed() {
    minX = 0;
    maxX = W - 1;
    minY = 0;
    maxY = D - 1;
    blocks.clear();
    shapeAt.clear();
    places.clear();
    ecx = ecy = erx = ery = 0;
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
    for (final p in const [(4, 4), (9, 30), (27, 5), (34, 33), (12, 15), (28, 27), (5, 15), (36, 14), (15, 35)]) {
      stamp(_tree(), p.$1, p.$2, 1, 0);
    }
    stamp(_pine(), 7, 34, 1, 0);
    // köşede mağaralı bir dağ
    mountain(30, 39, 0, 8, Random(7));
    // hazine sandıkları
    for (final p in const [(14, 18), (22, 6), (8, 25), (31, 30), (36, 9), (3, 37), (26, 36)]) {
      putChest(p.$1, p.$2);
    }
    version++;
  }

  /// Taş dağ: içi taş ve cevher dolu, içinden geçen bir mağara tüneli,
  /// tünelde meşaleler ve bir hazine sandığı. Çocuk dağı oyup ev yapabilir.
  void mountain(int x0, int x1, int y0, int y1, Random r) {
    if (x1 - x0 < 4 || y1 - y0 < 4) return;
    final tas = matIndex('tas'), toprak = matIndex('toprak'), cim = matIndex('cim'), kar = matIndex('kar');
    final hc = matIndex('heceta');
    final ores = [matIndex('komur'), matIndex('komur'), matIndex('demirc'), matIndex('demirc'), matIndex('altinc'), matIndex('elmas'), hc, hc, hc, hc,
      matIndex('yakutc'), matIndex('firuzec'), matIndex('gumusc'), matIndex('kehribarc')];
    final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
    final rx = (x1 - x0) / 2, ry = (y1 - y0) / 2;
    final ph = r.nextDouble() * 6;
    final heights = <int, int>{};
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        final d = sqrt(pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2));
        if (d > 1) continue;
        final h = min(H - 3, ((1 - d) * 11 + sin(x / 2.2 + ph) + cos(y / 2.6)).round());
        if (h < 1) continue;
        heights[ck(x, y, 0)] = h;
        for (var z = 1; z <= h; z++) {
          var m = tas;
          if (z == h) {
            m = h >= 9 ? kar : (h <= 3 ? cim : tas);
          } else if (z >= h - 1 && h <= 4) {
            m = toprak;
          } else if (r.nextInt(14) == 0) {
            m = ores[r.nextInt(ores.length)];
          }
          blocks[ck(x, y, z)] = m;
        }
      }
    }
    // mağara: dağın bir yanından öbür yanına kıvrılan tünel (z 1-3)
    var tx = x0.toDouble(), ty = cy + (r.nextDouble() - 0.5) * ry;
    var ang = (r.nextDouble() - 0.5) * 0.6;
    final steps = (x1 - x0) * 2;
    final torches = <(int, int)>[];
    for (var i = 0; i <= steps; i++) {
      final ix = tx.round(), iy = ty.round();
      final wide = (i % 9 == 4) ? 2 : 1; // ara sıra genişleyen odalar
      for (var dx = -wide; dx <= wide; dx++) {
        for (var dy = -wide; dy <= wide; dy++) {
          for (var z = 1; z <= (wide == 2 ? 4 : 3); z++) {
            final k = ck(ix + dx, iy + dy, z);
            if (heights.containsKey(ck(ix + dx, iy + dy, 0)) && z < (heights[ck(ix + dx, iy + dy, 0)] ?? 0)) {
              blocks.remove(k);
              shapeAt.remove(k);
            }
          }
        }
      }
      if (i % 7 == 3) torches.add((ix, iy));
      tx += 0.5;
      ang += (r.nextDouble() - 0.5) * 0.5;
      ang = ang.clamp(-0.9, 0.9);
      ty = (ty + sin(ang) * 0.6).clamp(y0 + 1.0, y1 - 1.0);
    }
    final mes = matIndex('mesale');
    for (final (x, y) in torches) {
      final k = ck(x, y, 1);
      if (!blocks.containsKey(k) && blocks.containsKey(ck(x, y, 4))) {
        blocks[k] = mes;
        shapeAt[k] = 20 * 4;
      }
    }
    // tünelin ortasında hazine
    final mx = ((x0 + x1) / 2).round();
    for (var y = y0; y <= y1; y++) {
      if (!blocks.containsKey(ck(mx, y, 1)) && blocks.containsKey(ck(mx, y, 5))) {
        blocks[ck(mx, y, 1)] = matIndex('hazine');
        break;
      }
    }
  }

  void putChest(int x, int y) {
    final z = topZ(x, y);
    final g = blocks[ck(x, y, z)];
    if (g == matIndex('su')) return;
    put(x, y, z + 1, matIndex('hazine'));
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
      unit: 'ağaç', progress: (w) => (min(3, game.treesPlanted), 3)),
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
  final bool startFirstPerson;
  final (int, int)? startFocus;
  final bool? startNight;
  final bool startBehind;
  final bool startFlying;
  const BlokAdasi(
      {super.key, this.startFirstPerson = false, this.startFocus, this.startNight, this.startBehind = false, this.startFlying = false});

  @override
  State<BlokAdasi> createState() => BlokAdasiState();
}

/// Görünen bir yüz: hücre + yön (0 üst, 1 +x, 2 -x, 3 +y, 4 -y)
class _Face {
  final int cell; // blok hücresi; hayvan için sıra numarası; ekin için hücre
  final int dir;
  final int mat;
  final int ent; // 0 blok, 1 karakter, 2 hayvan, 3 ekin
  _Face(this.cell, this.dir, this.mat, [this.ent = 0]);
}

const _dirs = [(0, 0, 1), (1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, -1)];

class BlokAdasiState extends State<BlokAdasi> with TickerProviderStateMixin {
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
  double _fx0 = 0, _fy0 = 0, _l0 = 0, _lu0 = 0;
  bool _moved = false;
  int _pointers = 1;
  Size area = Size.zero;
  // önizleme
  int? previewCell;
  bool previewErase = false;
  MathTask? task;
  bool night = DateTime.now().hour >= 19 || DateTime.now().hour < 6;
  int selShape = 0;
  final List<String> recent = ['tahta', 'tugla', 'cam', 'kapi', 'kiremit', 'mesale'];
  // son çizimin dokunma bilgisi
  final _hit = _HitData();

  // ---------- karakter ----------
  int mode = 0; // 0 kur, 1 yürü, 2 kır
  Avatar avatar = myAvatar;
  double ax = 17.5, ay = 17.5, az = 1, facing = 0, walk = 0, swing = 0, vz = 0, stuck = 0;
  bool grounded = true;
  // birinci şahıs
  bool firstPerson = false;
  double look = 0, lookUp = -0.15;
  int? aim, aimNormal;
  bool breakHeld = false;
  double padF = 0, padR = 0;
  (int, int)? walkTo;
  int? breakCell;
  int? chestCell;
  int hits = 0;
  String? hand; // elde tutulan alet
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final List<_Particle> parts = [];
  int _blockedSaid = 0;

  String get gameTools => game.blockTools.join();

  List<ABox> avatarParts() {
    final b = avatarBoxes(avatar, walk: flying ? 0 : walk, swing: swing, tool: hand, shield: game.blockTools.contains('kalkan'));
    if (!flying) return b;
    // kanatlar: sırtta, çırparken aşağı yukarı oynar
    final f = sin(flyT * 9) * 0.07;
    const w = Color(0xFFF5F5F5), e = Color(0xFFB3E5FC);
    return [
      ...b,
      ABox(-0.42, -0.2, 1.08 + f, 0.3, 0.03, 0.16, w),
      ABox(0.42, -0.2, 1.08 + f, 0.3, 0.03, 0.16, w),
      ABox(-0.62, -0.21, 0.98 + f * 1.6, 0.14, 0.03, 0.1, e),
      ABox(0.62, -0.21, 0.98 + f * 1.6, 0.14, 0.03, 0.1, e),
    ];
  }

  // ================= arkadaşlar =================
  final List<Friend> friends = [];
  (int, String)? pendingOrder; // (arkadaş, hazır yapı) yer seçilmeyi bekliyor
  int _orderSlot = 0;

  void _tickFriends(double dt) {
    var any = false;
    for (var i = 0; i < friends.length; i++) {
      final f = friends[i];
      double? tx, ty;
      var speed = 4.0;
      if (f.mode == 0) {
        // oyuncunun arkasında, yan yana dizilerek
        final side = (i.isEven ? 1 : -1) * (0.9 + (i ~/ 2) * 0.9);
        final bx = ax - sin(facing) * 1.8 + cos(facing) * side, by = ay - cos(facing) * 1.8 - sin(facing) * side;
        if (sqrt(pow(bx - f.x, 2) + pow(by - f.y, 2)) > 1.4) {
          tx = bx;
          ty = by;
        }
        // çok uzakta kaldıysa (ışınlanma, uçma) yanına gelsin
        if (friendDist(f, ax, ay) > 30) {
          f.x = bx;
          f.y = by;
        }
        speed = flying ? 6.5 : 4.4;
      } else if (f.mode == 2 && f.goal != null) {
        tx = f.goal!.$1 + 0.5 - 1.5;
        ty = f.goal!.$2 + 0.5 - 1.5;
        speed = 6.5;
        if (sqrt(pow(tx - f.x, 2) + pow(ty - f.y, 2)) < 0.6) {
          final pf = prefabById(f.job ?? '');
          final (gx, gy, gz) = f.goal!;
          if (pf != null) {
            final plan = world.plan(pf.cells(), gx, gy, gz, f.jobDir);
            if (pf.id == 'p_agac') game.plantTree();
            _startJob(pf, plan, gx, gy, gz, friend: f);
          } else {
            f.mode = 0;
          }
          tx = null;
        }
      }
      if (f.mode == 3) {
        any = true;
        continue;
      }
      if (tx != null && ty != null) {
        final dx = tx - f.x, dy = ty - f.y, d = sqrt(dx * dx + dy * dy);
        final st = min(d, speed * dt);
        f.x += dx / d * st;
        f.y += dy / d * st;
        f.facing = atan2(dx, dy);
        f.walk += dt * 11;
        any = true;
      } else if (f.walk != 0) {
        f.walk = 0;
        any = true;
      }
      final gz = world.topZ(f.x.floor(), f.y.floor()) + 1.0;
      if ((gz - f.z).abs() > 0.01) {
        f.z += (gz - f.z) * min(1, dt * 10);
        any = true;
      }
    }
    if (any) lifeTick++;
  }

  Future<void> _friendsMenu() async {
    final i = await showDialog<int>(context: context, builder: (_) => FriendsDialog(friends));
    if (i == null || !mounted) return;
    if (i == -1) {
      final f = await createFriend(context, ax, ay, az);
      if (f == null || !mounted) return;
      setState(() => friends.add(f));
      saveFriends(friends);
      lifeTick++;
      return;
    }
    _friendTap(i);
  }

  Future<void> _friendTap(int i) async {
    if (i < 0 || i >= friends.length) return;
    final f = friends[i];
    Voice.say('Efendim? Ben ${f.name}. Ne yapayım?');
    final r = await showDialog<String>(context: context, builder: (_) => FriendOrderDialog(f));
    if (r == null || !mounted) return;
    switch (r) {
      case 'gel':
        f.mode = 0;
        Voice.say('${f.name}: Tamam, seninle geliyorum!');
      case 'bekle':
        f.mode = 1;
        Voice.say('${f.name}: Burada bekliyorum.');
      case 'sil':
        friends.removeAt(i);
        Voice.say('${f.name} evine gitti. Güle güle ${f.name}!');
      default:
        orderFriend(i, r);
    }
    saveFriends(friends);
    setState(() {});
  }

  /// Arkadaşa iş ver: hemen önündeki boş bir yere gider; istersen ekranda başka yere dokunursun.
  void orderFriend(int i, String r) {
    final f = friends[i];
    final slot = const [0, 9, -9, 18, -18, 27, -27][_orderSlot++ % 7];
    final dxF = sin(facing), dyF = cos(facing);
    var gx = (ax + dxF * 8 + dyF * slot).round(), gy = (ay + dyF * 8 - dxF * slot).round();
    if (!inside(gx, gy, 0)) {
      gx = ax.round() + 3;
      gy = ay.round() + 3;
    }
    f.goal = (gx, gy, world.topZ(gx, gy) + 1);
    f.job = r;
    f.jobDir = forwardDir;
    f.mode = 2;
    setState(() => pendingOrder = (i, r));
    Voice.say('${f.name}: Tamam! ${trCapitalize(jobName(r))} yapmaya gidiyorum. Başka bir yer istersen ekrana dokun.');
    saveFriends(friends);
  }

  /// Seçilen yere arkadaşı gönder.
  void _giveOrder(int cell) {
    final o = pendingOrder;
    if (o == null) return;
    pendingOrder = null;
    if (o.$1 >= friends.length) return;
    final f = friends[o.$1];
    if (f.mode == 3) return; // zaten yapmaya başladı
    final (x, y, _) = cxyz(cell);
    f.goal = (x, y, world.topZ(x, y) + 1);
    f.job = o.$2;
    f.jobDir = forwardDir;
    f.mode = 2;
    Sfx.play('click');
    Voice.say('${f.name}: Tamam! Oraya gidip ${jobName(o.$2)} yapıyorum.');
    setState(() {});
  }

  Widget _orderBanner() {
    final o = pendingOrder!;
    final f = o.$1 < friends.length ? friends[o.$1] : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xEE6A1B9A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text('📍 ${f?.name ?? ''} ${jobName(o.$2)} yapmaya gidiyor. Başka yer istersen dokun!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => pendingOrder = null),
        ),
      ]),
    );
  }

  // ================= yerler =================
  // ================= köylüler =================
  List<Villager> npcs = [];
  int _npcPlaces = -1;

  void _ensureNpcs() {
    if (_npcPlaces == world.places.length) return;
    _npcPlaces = world.places.length;
    npcs = makeVillagers(world.places, world.topZ);
  }

  void _tickNpcs(double dt) {
    final r = Random();
    var any = false;
    for (final v in npcs) {
      // yalnızca yakındakiler hareket etsin
      if ((v.x - ax).abs() > 40 && (v.x - fx).abs() > 40) continue;
      if ((v.y - ay).abs() > 40 && (v.y - fy).abs() > 40) continue;
      final t = v.target;
      if (t == null) {
        v.wait -= dt;
        if (v.wait <= 0) {
          v.wait = 2 + r.nextDouble() * 4;
          for (var k = 0; k < 6; k++) {
            final tx = v.hx + r.nextInt(9) - 4, ty = v.hy + r.nextInt(5) - 2;
            if (inside(tx, ty, 0) && world.topZ(tx, ty) == v.baseZ) {
              v.target = (tx, ty);
              break;
            }
          }
        }
        if (v.walk != 0) {
          v.walk = 0;
          any = true;
        }
        continue;
      }
      final dx = t.$1 + 0.5 - v.x, dy = t.$2 + 0.5 - v.y, d = sqrt(dx * dx + dy * dy);
      if (d < 0.1) {
        v.target = null;
        continue;
      }
      final st = min(d, 1.3 * dt);
      final nx = v.x + dx / d * st, ny = v.y + dy / d * st;
      if (world.topZ(nx.floor(), ny.floor()) != v.baseZ) {
        v.target = null; // duvar ya da su: dur
        continue;
      }
      v.x = nx;
      v.y = ny;
      v.facing = atan2(dx, dy);
      v.walk += dt * 8;
      any = true;
    }
    if (any) lifeTick++;
  }

  void _greet(int i) {
    if (i < 0 || i >= npcs.length) return;
    final v = npcs[i];
    Sfx.play('heart');
    Say.show(context, Who.teyze, '${v.name}: Selamün aleyküm! Ben ${v.name}. ${placeTo(v.place)} hoş geldin!', mood: 'sevin');
  }

  // ================= harita =================
  ui.Image? mapImg;
  int _mapVer = -1;
  bool _mapBusy = false;
  double _mapT = 0;

  void _refreshMap() {
    if (_mapBusy || _mapVer == world.version) return;
    _mapBusy = true;
    final v = world.version;
    buildMapImage(world).then((im) {
      _mapBusy = false;
      if (!mounted) return;
      setState(() {
        mapImg?.dispose();
        mapImg = im;
        _mapVer = v;
      });
    });
  }

  Future<void> _openMap({bool flat = false}) async {
    _refreshMap();
    final friendsL = [for (final f in friends) (f.x, f.y, f.name)];
    (int, int, String?)? r;
    if (flat) {
      r = await Navigator.push<(int, int, String?)>(
          context,
          fadeRoute<(int, int, String?)>(WorldMapScreen(
              img: mapImg, px: ax, py: ay, facing: facing, places: world.places, friends: friendsL)));
    } else {
      final hw = (maxX - minX) / 2, hh = (maxY - minY) / 2;
      final data = GlobeData(mapPixels(world), maxX - minX + 1, maxY - minY + 1, minX, minY, (minX + maxX) / 2, (minY + maxY) / 2,
          hw * 1.42 + 1, hh * 1.42 + 1);
      var toFlat = false;
      late BuildContext routeCtx;
      r = await Navigator.push<(int, int, String?)>(
          context,
          fadeRoute<(int, int, String?)>(Builder(builder: (c) {
            routeCtx = c;
            return GlobeMapScreen(
              data: data,
              px: ax,
              py: ay,
              places: world.places,
              friends: friendsL,
              onFlat: () {
                toFlat = true;
                Navigator.pop(routeCtx);
              },
            );
          })));
      if (toFlat && mounted) return _openMap(flat: true);
    }
    if (r == null || !mounted) return;
    final (x, y, name) = r;
    if (!inside(x, y, 0)) return;
    _teleport(x, y, name);
  }

  void _teleport(int x, int y, String? n) {
    // denize düşmesin: en yakın karaya
    final su = matIndex('su');
    if (world.blocks[ck(x, y, world.topZ(x, y))] == su) {
      var best = 1e9;
      var bx = x, by = y;
      for (var dx = -30; dx <= 30; dx++) {
        for (var dy = -30; dy <= 30; dy++) {
          final xx = x + dx, yy = y + dy;
          if (!inside(xx, yy, 0)) continue;
          if (world.blocks[ck(xx, yy, world.topZ(xx, yy))] == su) continue;
          final d = (dx * dx + dy * dy).toDouble();
          if (d < best) {
            best = d;
            bx = xx;
            by = yy;
          }
        }
      }
      x = bx;
      y = by;
    }
    setState(() {
      flying = false;
      _placeAvatar(x, y);
      walkTo = null;
      fx = x + 0.5;
      fy = y + 0.5;
      for (final f in friends) {
        if (f.mode == 0) {
          f.x = ax + 1;
          f.y = ay - 1;
        }
      }
      _geoKey = '';
    });
    Sfx.play('unlock');
    _burst(ck(x, y, az.floor() + 1), const Color(0xFF80DEEA), 16);
    // en yakın yerin adını söyle
    var name = n;
    if (name == null) {
      var best = 15.0;
      for (final e in world.places.entries) {
        final d = sqrt(pow(e.value.$1 - x, 2) + pow(e.value.$2 - y, 2));
        if (d < best) {
          best = d;
          name = e.key;
        }
      }
    }
    final msg = name != null ? '${placeTo(name)} geldiniz!' : 'Işınlandınız!';
    Say.show(context, Who.tamirci, '📍 ${msg[0].toUpperCase()}${msg.substring(1)}', mood: 'sevin');
  }

  // ================= uçma =================
  bool flying = false;
  double flyT = 0;
  int flyUp = 0; // 1 yüksel, -1 in

  Future<void> _toggleFly() async {
    if (!flying && !game.blockItems.contains('kanat')) {
      final ok = await showDialog<bool>(
          context: context,
          builder: (_) => const SpellDialog(
                parts: ['ka', 'nat'],
                emoji: '🪽',
                title: 'Uçmak için kanat lazım! kanat yaz.',
                speech: 'Uçmak için kanat lazım! Kanat yaz, kanatların çıksın!',
              ));
      if (ok != true || !mounted) return;
      game.addBlockItem('kanat');
      Sfx.play('unlock');
    }
    setState(() {
      flying = !flying;
      flyUp = 0;
      walkTo = null;
      if (flying) {
        grounded = false;
        vz = 0;
        if (bodyFree(ax, ay, az + 0.8)) az += 0.8;
      } else {
        grounded = false;
        vz = 0;
      }
      _geoKey = '';
    });
    Sfx.play('uc', volume: 0.6);
    Voice.say(flying ? 'Uçuyorsun! Yüksel tuşuyla yukarı, İn tuşuyla aşağı.' : 'Yere iniyorsun.');
  }

  Widget _flyChip() => Bouncy(
        onTap: _toggleFly,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: flying ? const Color(0xFF8D6E63) : const Color(0xFF29B6F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Text(flying ? '🦶 Kon' : '🪽 Uç', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      );

  Widget _upBtn() => flying
      ? _ActionBtn('⬆️', 'Yüksel', const Color(0xFF29B6F6), down: () => flyUp = 1, up: () => flyUp = 0)
      : _ActionBtn('⬆️', 'Zıpla', const Color(0xFF42A5F5), down: jump);

  Widget _downBtn() => _ActionBtn('⬇️', 'İn', const Color(0xFF7986CB), down: () => flyUp = -1, up: () => flyUp = 0);

  Quest? get quest {
    for (final q in quests) {
      if (!game.blockQuests.contains(q.id)) return q;
    }
    return null;
  }

  bool get questReady => quest != null && (quest!.needs == null || unlocked(quest!.needs!));

  bool unlocked(String id) => bagUnlocked(id);

  /// Zırh değiştiyse dönüşüm: ışıltı ve kahramanın adı.
  void _armorChanged(int before) {
    final a = avatar.armor;
    if (a == before || a <= 0 || a > armors.length) return;
    final ar = armors[a - 1];
    // içeriden bakarken kendini göremez: arkadan görünüme geç
    if (firstPerson && !behind) {
      behind = true;
      lookUp = -0.25;
      _geoKey = '';
    }
    final c = ck(ax.floor(), ay.floor(), az.floor() + 1);
    _burst(c, ar.gem, 18);
    _burst(c, ar.color, 14);
    _burst(c, const Color(0xFFFFD54F), 12);
    Sfx.play('unlock');
    Say.show(context, Who.tamirci, '✨ ${ar.transform}', mood: 'sevin');
  }

  Future<void> _openBag() async {
    final before = avatar.armor;
    final r = await Navigator.push<String>(context, fadeRoute(BagScreen(selected: sel, shape: selShape)));
    if (!mounted) return;
    setState(() => avatar = myAvatar);
    _armorChanged(before);
    if (r == null) return;
    if (r.startsWith('shape:')) {
      final n = int.parse(r.substring(6));
      setState(() => selShape = n);
      final e = shapeEdges[n];
      Voice.say(e == null ? shapes[n].name : '${shapes[n].name}. ${shapes[n].name} $e kenarlıdır!');
      if (prefabById(sel) != null || sel.startsWith('seed_')) sel = 'tahta';
      return;
    }
    _select(r);
  }

  @override
  void initState() {
    super.initState();
    if (game.blockWorld.isEmpty || !world.decode(game.blockWorld)) world.seed();
    var grew = world.ensureLands();
    if (world.erx == 0) grew = world.inflate(0, Random(3)) || grew;
    if (world.ensureTreasures(Random())) grew = true;
    if (grew) game.saveBlocks(world.encode());
    _ensureNpcs();
    _loadLife();
    game.markPlayed('blok');
    Tex.load(texIds).then((_) {
      if (mounted) setState(() {});
    });
    _loadSigns();
    friends.addAll(loadFriends());
    for (final f in friends) {
      if (f.mode == 0) {
        f.x = 18.2;
        f.y = 17.6;
      }
    }
    Future.delayed(const Duration(milliseconds: 9000), () {
      if (mounted) _surpriseEgg();
    });
    final q = quest;
    if (q != null) _lookAt(q.focus.$1, q.focus.$2);
    final sf = widget.startFocus;
    if (sf != null) _lookAt(sf.$1, sf.$2);
    if (widget.startNight != null) night = widget.startNight!;
    _placeAvatar(17, 17);
    if (widget.startFirstPerson) {
      firstPerson = true;
      behind = widget.startBehind;
      if (widget.startFlying) {
        flying = true;
        az += 3;
        lookUp = -0.45;
      }
      look = 2.4;
      lookUp = -0.12;
      facing = look;
    }
    hand = game.blockTools.where((t) => t != 'kalkan').lastOrNull;
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (game.avatar.isEmpty) {
        await Navigator.push(context, fadeRoute(const AvatarScreen()));
        if (!mounted) return;
        setState(() => avatar = myAvatar);
      }
      if (!mounted) return;
      Say.show(context, Who.tamirci, 'Blok Şehrine hoş geldin! Parmağınla sürükle, şehir dönsün. Aşağıdan Kur, Yürü ya da Kır seç.', mood: 'iyi');
      Future.delayed(const Duration(milliseconds: 6500), _sayQuest);
    });
  }

  // ---------- karakterin hareketi (fizik) ----------
  bool solid(int x, int y, int z) {
    if (z < 0) return true;
    final m = world.blocks[ck(x, y, z)];
    if (m == null) return false;
    final id = mats[m].id;
    return id != 'su' && id != 'kapi' && id != 'mesale';
  }

  // ---------- işçiler ----------
  final List<_Job> jobs = [];
  static final workerLook = Avatar(skin: 1, hair: 0, style: 2, shirt: 4, pants: 1, hat: 0);

  void _startJob(Prefab pf, List<(int, int)> plan, int x, int y, int z, {Friend? friend}) {
    if (plan.isEmpty) {
      if (friend != null) {
        friend.mode = 0;
        friend.job = null;
        friend.goal = null;
        Voice.say('${friend.name}: Orada yer yok, başka bir yer seç!');
      }
      return;
    }
    final job = _Job(pf.name, plan, x + 0.5, y + 0.5, z.toDouble())..friend = friend;
    jobs.add(job);
    if (friend != null) {
      friend.mode = 3;
      Voice.say('${friend.name}: ${trCapitalize(pf.name)} yapmaya başladım! ${plan.length} blok koyacağım.');
      return;
    }
    Sfx.play('horn1');
    Say.show(context, Who.tamirci, 'İşçiler geldi! ${trCapitalize(pf.name)} için ${plan.length} blok koyacaklar. Haydi izleyelim!', mood: 'iyi');
  }

  void _tickJobs(double dt) {
    if (jobs.isEmpty) return;
    for (final j in jobs) {
      j.t += dt;
      j.anim += dt;
      while (j.t > 0.09 && j.i < j.cells.length) {
        j.t -= 0.09;
        final (k, m) = j.cells[j.i++];
        world.blocks[k] = m;
        world.shapeAt.remove(k);
        world.version++;
        if (j.i % 3 == 0) Sfx.play('tok', volume: 0.35);
      }
      if (j.i > 0 && j.i <= j.cells.length) {
        final (k, _) = j.cells[j.i - 1];
        final (bx, by, bz) = cxyz(k);
        final fr = j.friend;
        if (fr != null) {
          final tx = bx + 0.5 - 1.2, ty = by + 0.5 + 0.7;
          fr.x += (tx - fr.x) * min(1, dt * 6);
          fr.y += (ty - fr.y) * min(1, dt * 6);
          fr.z += (max(0, bz - 0.0) - fr.z) * min(1, dt * 6);
          fr.facing = atan2(bx + 0.5 - fr.x, by + 0.5 - fr.y);
          fr.anim += dt;
        }
        for (var w = 0; w < 2; w++) {
          final tx = bx + 0.5 + (w == 0 ? -1.1 : 1.1), ty = by + 0.5 + (w == 0 ? 0.6 : -0.6);
          j.wx[w] += (tx - j.wx[w]) * min(1, dt * 6);
          j.wy[w] += (ty - j.wy[w]) * min(1, dt * 6);
          j.wz[w] += (max(0, bz - 0.0) - j.wz[w]) * min(1, dt * 6);
          j.wf[w] = atan2(bx + 0.5 - j.wx[w], by + 0.5 - j.wy[w]);
        }
      }
    }
    lifeTick++;
    final done = jobs.where((j) => j.i >= j.cells.length && (j.finished += dt) > 1.5).toList();
    for (final j in done) {
      jobs.remove(j);
      Sfx.play('finish');
      final fr = j.friend;
      if (fr != null) {
        fr.mode = 0;
        fr.job = null;
        fr.goal = null;
        fr.z = world.topZ(fr.x.floor(), fr.y.floor()) + 1.0;
        saveFriends(friends);
        Say.show(context, Who.tamirci, '${fr.name} ${j.name} işini bitirdi! ${j.cells.length} blok kullandı. Eline sağlık ${fr.name}!', mood: 'sevin');
      } else {
        Say.show(context, Who.tamirci, 'İşçiler ${j.name} işini bitirdi! ${j.cells.length} blok kullandılar. Elinize sağlık!', mood: 'sevin');
      }
      _changed();
    }
  }

  // ---------- hayvanlar ve tarla ----------
  final List<Animal> animals = [];
  final Map<int, (String, int)> cropsAt = {}; // hücre -> (ekin, ekilme zamanı)
  int lifeTick = 0;
  double _lifeSave = 0;
  (int, int)? aimEnt; // birinci şahısta hedeflenen hayvan/ekin: (tür 2/3, numara)

  String _encodeLife() {
    final a = animals
        .map((e) =>
            '${e.kind.id},${e.x.toStringAsFixed(2)},${e.y.toStringAsFixed(2)},${e.z.toStringAsFixed(1)},${e.friend ? 1 : 0},${e.stay ? 1 : 0},${e.last}')
        .join(';');
    final c = cropsAt.entries.map((e) => '${e.key},${e.value.$1},${e.value.$2}').join(';');
    return '$a|$c';
  }

  void _loadLife() {
    animals.clear();
    cropsAt.clear();
    final parts = game.blockLife.split('|');
    if (game.blockLife.isEmpty || parts.length != 2) {
      _spawnAnimals(9, minX, maxX, minY, maxY);
      return;
    }
    for (final a in parts[0].split(';')) {
      final f = a.split(',');
      if (f.length != 5 && f.length != 7) continue;
      final an = Animal(kindById(f[0]), double.parse(f[1]), double.parse(f[2]), double.parse(f[3]), friend: f[4] == '1');
      if (f.length == 7) {
        an.stay = f[5] == '1';
        an.last = int.parse(f[6]);
      }
      animals.add(an);
    }
    for (final c in parts[1].split(';')) {
      final f = c.split(',');
      if (f.length != 3) continue;
      cropsAt[int.parse(f[0])] = (f[1], int.parse(f[2]));
    }
  }

  void _saveLife() => game.saveLife(_encodeLife());

  void _spawnAnimals(int n, int x0, int x1, int y0, int y1) {
    final r = Random();
    for (var i = 0; i < n * 6 && n > 0; i++) {
      final x = x0 + r.nextInt(x1 - x0 + 1), y = y0 + r.nextInt(y1 - y0 + 1);
      final z = world.topZ(x, y);
      final g = world.blocks[ck(x, y, z)];
      if (g == null || mats[g].id != 'cim' && mats[g].id != 'cicek' && mats[g].id != 'kar') continue;
      animals.add(Animal(animalKinds[r.nextInt(animalKinds.length)], x + 0.5, y + 0.5, z + 1.0));
      n--;
    }
  }

  /// Çit ve kapı hayvanları durdurur.
  bool _fenced(int x, int y, int z) {
    final m = world.blocks[ck(x, y, z)];
    if (m == null) return false;
    final id = mats[m].id;
    return id == 'cit' || id == 'kapi' || id == 'hecekapi';
  }

  double _animalHeight(String id) => const {'inek': 1.25, 'koyun': 1.05, 'tavuk': 0.85, 'kedi': 0.7, 'kopek': 0.85, 'at': 1.75}[id] ?? 1.0;

  void _tickAnimals(double dt) {
    final r = Random();
    var moved = false;
    for (final a in animals) {
      a.timer -= dt;
      final dxp = ax - a.x, dyp = ay - a.y;
      if (a.friend && !a.stay && dxp * dxp + dyp * dyp > 16) {
        a.target = (ax - dxp.sign * 1.5, ay - dyp.sign * 1.5);
      } else if (a.timer <= 0) {
        a.timer = 3 + r.nextDouble() * 5;
        a.target = r.nextInt(3) == 0 ? null : (a.x + r.nextInt(11) - 5, a.y + r.nextInt(11) - 5);
      }
      final t = a.target;
      if (t != null) {
        final dx = t.$1 - a.x, dy = t.$2 - a.y;
        final d = sqrt(dx * dx + dy * dy);
        if (d < 0.2) {
          a.target = null;
        } else {
          final st = min(d, a.kind.speed * dt);
          final nx = a.x + dx / d * st, ny = a.y + dy / d * st;
          final cx = nx.floor(), cy = ny.floor(), lv = a.z.round();
          if (!inside(cx, cy, 0) || _fenced(cx, cy, lv) || _fenced(cx, cy, lv - 1)) {
            a.target = null;
            a.timer = 0.5;
          } else if (!solid(cx, cy, lv) && !solid(cx, cy, lv + 1)) {
            a.x = nx;
            a.y = ny;
          } else if (!solid(cx, cy, lv + 1) && !solid(cx, cy, lv + 2)) {
            a.x = nx;
            a.y = ny;
            a.z = lv + 1.0;
          } else {
            a.target = null;
          }
          a.facing = atan2(dx, dy);
          a.walk += dt * 9;
          moved = true;
        }
      } else if (a.walk != 0) {
        a.walk = 0;
        moved = true;
      }
      // düşme
      final cx = a.x.floor(), cy = a.y.floor();
      var lv = a.z.round();
      while (lv > 0 && !solid(cx, cy, lv - 1)) {
        lv--;
      }
      if (lv != a.z.round()) {
        a.z = lv.toDouble();
        moved = true;
      }
    }
    if (moved) lifeTick++;
    _lifeSave += dt;
    if (_lifeSave > 8) {
      _lifeSave = 0;
      _saveLife();
    }
  }

  int get cropStamp => cropsAt.values.fold(0, (a, c) => a + cropStage(c.$2));

  /// Çizilecek bütün hareketli parçalar: (kutu, x, y, z, yön, tür, numara)
  List<(ABox, double, double, double, double, int, int)> entityParts({bool withAvatar = true}) {
    final out = <(ABox, double, double, double, double, int, int)>[];
    if (withAvatar) {
      for (final b in avatarParts()) {
        out.add((b, ax, ay, az, facing, 1, 0));
      }
    }
    for (var i = 0; i < npcs.length; i++) {
      final v = npcs[i];
      final cxp = firstPerson ? ax : fx, cyp = firstPerson ? ay : fy;
      if ((v.x - cxp).abs() > 30 || (v.y - cyp).abs() > 30) continue;
      for (final b in avatarBoxes(v.look, walk: v.walk)) {
        out.add((b, v.x, v.y, v.z, v.facing, 7, i));
      }
    }
    for (var i = 0; i < friends.length; i++) {
      final f = friends[i];
      if ((f.x - fx).abs() > 40 && (f.x - ax).abs() > 40) continue;
      for (final b in avatarBoxes(f.look,
          walk: f.walk, swing: f.mode == 3 ? (f.anim * 2.5) % 1 : 0, tool: f.mode == 3 ? 'kazma' : null)) {
        out.add((b, f.x, f.y, f.z, f.facing, 6, i));
      }
    }
    for (final j in jobs) {
      if (j.friend != null) continue;
      for (var w = 0; w < 2; w++) {
        for (final b in avatarBoxes(workerLook, walk: 0, swing: (j.anim * 2.5 + w * 0.5) % 1, tool: 'kazma')) {
          out.add((b, j.wx[w], j.wy[w], j.wz[w], j.wf[w], 5, 0));
        }
      }
    }
    for (var i = 0; i < animals.length; i++) {
      final a = animals[i];
      if ((a.x - fx).abs() > 40 || (a.y - fy).abs() > 40) continue;
      for (final b in animalBoxes(a.kind.id, a.walk)) {
        out.add((b, a.x, a.y, a.z, a.facing, 2, i));
      }
    }
    for (final e in cropsAt.entries) {
      final (x, y, z) = cxyz(e.key);
      if ((x - fx).abs() > 40 || (y - fy).abs() > 40) continue;
      for (final b in cropBoxes(e.value.$1, cropStage(e.value.$2))) {
        out.add((b, x + 0.5, y + 0.5, z.toDouble(), 0, 3, e.key));
      }
    }
    return out;
  }

  Future<void> _befriend(int i) async {
    if (i < 0 || i >= animals.length) return;
    final a = animals[i];
    if (a.friend) {
      final pr = animalProducts[a.kind.id];
      final now = DateTime.now().millisecondsSinceEpoch;
      if (pr != null && now - a.last > productMs) {
        final ok = await showDialog<bool>(
            context: context,
            builder: (_) => SpellDialog(
                  parts: heceler(pr.$1),
                  emoji: pr.$2,
                  title: '${trCapitalize(a.kind.name)} sana ${pr.$1} verdi! Adını yaz, al.',
                  speech: '${trCapitalize(a.kind.name)} sana ${pr.$1} verdi! Adını yaz, al.',
                ));
        if (ok != true || !mounted) return;
        a.last = now;
        game.addCoins(3);
        game.addMined('urun_${pr.$1}');
        _saveLife();
        Sfx.play('coin');
        Say.show(context, Who.tozbulut, '${trCapitalize(pr.$1)} aldın, 3 altın kazandın! Hayvanına iyi bakarsan yine verir.', mood: 'gul');
        return;
      }
      a.stay = !a.stay;
      _saveLife();
      Sfx.play('heart');
      _burst(ck(a.x.floor(), a.y.floor(), a.z.floor()), const Color(0xFFFF80AB), 8);
      Say.show(
          context,
          Who.tozbulut,
          a.stay
              ? '${trCapitalize(a.kind.name)} burada bekleyecek. Ağıla koyarsan oradan çıkmaz!'
              : '${trCapitalize(a.kind.name)} yine seni takip ediyor!',
          mood: 'gul');
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: a.kind.syl,
              emoji: a.kind.emoji,
              title: 'Bu hayvanın adını yaz, dost olsun!',
              speech: 'Bu bir ${a.kind.name}. Adını ${a.kind.syl.every((p) => p.length == 1) ? 'harflerle' : 'hecelerle'} yaz, seninle dost olsun!',
            ));
    if (ok != true || !mounted) return;
    a.friend = true;
    game.addHeart();
    _saveLife();
    Sfx.play('heart');
    _burst(ck(a.x.floor(), a.y.floor(), a.z.floor()), const Color(0xFFFF80AB), 16);
    Say.show(context, Who.tozbulut,
        '${trCapitalize(a.kind.name)} artık dostun! Seni takip edecek. Hayvanlara iyi bakmak güzel bir iyiliktir.',
        mood: 'gul');
    lifeTick++;
  }

  Future<void> _harvest(int cell) async {
    final c = cropsAt[cell];
    if (c == null) return;
    final crop = cropById(c.$1);
    final st = cropStage(c.$2);
    if (st < 3) {
      final ws = pictureWords();
      final w = ws.isEmpty ? ['su'] : ws.first;
      final ok = await showDialog<bool>(
          context: context,
          builder: (_) => SpellDialog(
                parts: w.length == 1 ? heceler(w.first) : w,
                emoji: '💧${emojiFor(w.join())}',
                title: '${trCapitalize(crop.name)} susamış! Sulamak için bu kelimeyi yaz.',
                speech: '${trCapitalize(crop.name)} susamış! Sulamak için ${w.join()} kelimesini hecelerle yaz.',
              ));
      if (ok != true || !mounted) return;
      final cur = cropsAt[cell];
      if (cur == null) return;
      cropsAt[cell] = (cur.$1, cur.$2 - cropStageMs);
      _saveLife();
      Sfx.play('su');
      _burst(cell, const Color(0xFF4FC3F7), 12);
      final ns = cropStage(cur.$2 - cropStageMs);
      Say.show(context, Who.tamirci,
          ns >= 3 ? 'Suladın ve ${crop.name} olgunlaştı! Şimdi toplayabilirsin.' : 'Suladın! ${trCapitalize(crop.name)} büyüdü. Biraz daha!',
          mood: 'sevin');
      lifeTick++;
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: crop.syl,
              emoji: crop.emoji,
              title: 'Hasat zamanı! Adını yaz, topla.',
              speech: '${trCapitalize(crop.name)} olgunlaştı! Adını hecelerle yaz, toplayalım.',
            ));
    if (ok != true || !mounted) return;
    cropsAt.remove(cell);
    game.addMined('urun_${crop.id}');
    game.addStars(1);
    game.addCoins(5);
    _saveLife();
    Sfx.play('coin');
    _burst(cell, crop.color, 14);
    Say.show(context, Who.tamirci, 'Bereketli olsun! Bir ${crop.name} topladın: 5 altın ve bir yıldız! Elhamdülillah!', mood: 'sevin');
    lifeTick++;
  }

  bool _plant(int targetCell) {
    final seed = sel.substring(5);
    final (x, y, z) = cxyz(targetCell);
    final below = world.blocks[ck(x, y, z - 1)];
    if (below == null || mats[below].id != 'tarla') {
      Say.show(context, Who.tamirci, 'Tohumu tarlaya ekmeliyiz. Önce Bahçe sekmesinden tarla bloğu koy.', mood: 'dusun');
      return false;
    }
    if (cropsAt.containsKey(targetCell) || world.blocks.containsKey(targetCell)) return false;
    cropsAt[targetCell] = (seed, DateTime.now().millisecondsSinceEpoch);
    _saveLife();
    Sfx.play('pop');
    Voice.say('${trCapitalize(cropById(seed).name)} ektin! Üç dakikada büyüyecek.');
    lifeTick++;
    return true;
  }

  void _placeAvatar(int x, int y) {
    var z = 0;
    while (z < H && (solid(x, y, z) || solid(x, y, z + 1))) {
      z++;
    }
    ax = x + 0.5;
    ay = y + 0.5;
    az = z.toDouble();
    vz = 0;
  }

  int get level => (az + 0.01).floor();

  /// Gövde (yarıçap 0.28, boy 1.75) bu konumda boşlukta mı?
  bool bodyFree(double px, double py, double pz) {
    for (final ox in const [-0.28, 0.28]) {
      for (final oy in const [-0.28, 0.28]) {
        final cx = (px + ox).floor(), cy = (py + oy).floor();
        if (!inside(cx, cy, 0)) return false;
        for (final hz in const [0.02, 0.9, 1.72]) {
          if (solid(cx, cy, (pz + hz).floor())) return false;
        }
      }
    }
    return true;
  }

  /// Yatay hareket; bir bloğa kendiliğinden çıkar. Hareket ettiyse true.
  bool _move(double mx, double my) {
    var moved = false;
    for (var axis = 0; axis < 2; axis++) {
      final d = axis == 0 ? mx : my;
      if (d == 0) continue;
      final nx = axis == 0 ? ax + d : ax, ny = axis == 1 ? ay + d : ay;
      if (bodyFree(nx, ny, az)) {
        ax = nx;
        ay = ny;
        moved = true;
      } else if (grounded && bodyFree(nx, ny, level + 1.0) && bodyFree(ax, ay, level + 1.0)) {
        az = level + 1.0; // basamak çık
        ax = nx;
        ay = ny;
        moved = true;
      }
    }
    return moved;
  }

  void jump() {
    if (grounded) {
      vz = 7.6;
      grounded = false;
      Sfx.play('uc', volume: 0.4);
    }
  }

  bool _inReach(int cell) {
    final (x, y, z) = cxyz(cell);
    final ez = az + 1.5;
    final dx = x + 0.5 - ax, dy = y + 0.5 - ay, dz = z + 0.5 - ez;
    return dx * dx + dy * dy + dz * dz <= 5.2 * 5.2 && (dx.abs() <= 1.8 && dy.abs() <= 1.8 || firstPerson);
  }

  int _hitsFor(int mat) {
    final id = mats[mat].id;
    const stone = {'tas', 'tasduvar', 'parke', 'tugla', 'demir', 'elmas', 'altin', 'kumtasi', 'beyaz', 'asfalt', 'yol', 'kiremit', 'mavicati'};
    const wood = {'tahta', 'koyu', 'kutuk', 'kitaplik', 'kapi', 'cit', 'yaprak', 'cali', 'saman', 'kabak', 'karpuz', 'mantar'};
    const soft = {'cim', 'toprak', 'kum', 'kar', 'cicek', 'toprakyol', 'buz', 'su', 'cam', 'pencere'};
    switch (hand) {
      case 'kazma':
        return stone.contains(id) ? 1 : 2;
      case 'balta':
        return wood.contains(id) ? 1 : 2;
      case 'kurek':
        return soft.contains(id) ? 1 : 2;
      case 'kilic':
      case 'mizrak':
        return 2;
      default:
        return 4;
    }
  }

  void _tick(Duration now) {
    var dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0) return;
    if (dt > 0.05) dt = 0.05;
    var changed = false;
    // içine blok konduysa üste çık
    if (!bodyFree(ax, ay, az)) {
      var z = level;
      while (z < H && !bodyFree(ax, ay, z.toDouble())) {
        z++;
      }
      az = z.toDouble();
      vz = 0;
      changed = true;
    }
    // yön tuşları
    var mx = 0.0, my = 0.0;
    if (padF != 0 || padR != 0) {
      walkTo = null;
      double fwx, fwy, rtx, rty;
      if (firstPerson) {
        fwx = sin(look);
        fwy = cos(look);
      } else {
        fwx = -sin(yaw);
        fwy = -cos(yaw);
      }
      rtx = fwy;
      rty = -fwx;
      mx = fwx * padF + rtx * padR;
      my = fwy * padF + rty * padR;
    }
    final target = walkTo;
    if (target != null) {
      final dx = target.$1 + 0.5 - ax, dy = target.$2 + 0.5 - ay;
      final dist = sqrt(dx * dx + dy * dy);
      final near = (chestCell != null && _inReach(chestCell!)) || (breakCell != null && _inReach(breakCell!));
      if (dist < 0.12 || near) {
        walkTo = null;
        _arrived();
      } else {
        mx = dx / dist;
        my = dy / dist;
      }
    }
    final ml = sqrt(mx * mx + my * my);
    if (ml > 0) {
      final speed = (flying ? 5.6 : 3.8) * dt / max(1, ml);
      if (!firstPerson) facing = atan2(mx, my);
      final moved = _move(mx * speed, my * speed);
      if (moved) {
        stuck = 0;
        walk += dt * 11;
      } else {
        stuck += dt;
        if (stuck > 0.35 && walkTo != null) {
          walkTo = null;
          _arrived(blocked: true);
        }
      }
      changed = true;
    } else if (walk != 0) {
      walk = 0;
      changed = true;
    }
    if (firstPerson) facing = look;
    // uçarken yerçekimi yok
    if (flying) {
      flyT += dt;
      grounded = false;
      vz = 0;
      if (flyUp != 0) {
        final nz = (az + flyUp * 4.5 * dt).clamp(-1.0, H + 10.0);
        if (bodyFree(ax, ay, nz)) az = nz;
      }
      changed = true;
    }
    // yerçekimi
    if (!flying && grounded && bodyFree(ax, ay, az - 0.06)) grounded = false;
    if (!flying && !grounded) {
      vz -= 24 * dt;
      final nz = az + vz * dt;
      if (vz < 0 && !bodyFree(ax, ay, nz)) {
        az = (nz).floor() + 1.0;
        if (!bodyFree(ax, ay, az)) az = level.toDouble();
        vz = 0;
        grounded = true;
      } else if (vz > 0 && !bodyFree(ax, ay, nz)) {
        vz = 0;
      } else {
        az = nz;
      }
      if (az < -3) _placeAvatar(ax.floor(), ay.floor());
      changed = true;
    }
    // arkadan görünümde karakter baktığı yöne döner
    if (firstPerson && behind && facing != look) {
      facing = look;
      changed = true;
    }
    // renkli iz
    final mv = (ax - _tpx).abs() + (ay - _tpy).abs();
    _tpx = ax;
    _tpy = ay;
    if (game.trail.isNotEmpty && mv > 0.002 && mv < 1) {
      _trailT -= dt;
      if (_trailT <= 0) {
        _trailT = 0.045;
        _emitTrail();
      }
    }
    // kırma
    final bc = breakCell;
    if (bc != null && walkTo == null) {
      if (!world.blocks.containsKey(bc) || (firstPerson && !breakHeld && hits == 0 && swing == 0)) {
        breakCell = null;
      } else if (_inReach(bc)) {
        if (!firstPerson) {
          final (bx, by, _) = cxyz(bc);
          facing = atan2(bx + 0.5 - ax, by + 0.5 - ay);
        }
        swing += dt / 0.3;
        if (swing >= 1) {
          swing = 0;
          hits++;
          final m = world.blocks[bc]!;
          Sfx.play(hits >= _hitsFor(m) ? 'kir' : 'tok', volume: 0.7);
          _burst(bc, mats[m].color, 5);
          if (hits >= _hitsFor(m)) {
            _push();
            world.removeAt(bc);
            world.version++;
            game.addMined(mats[m].id);
            _burst(bc, mats[m].color, 14);
            _afterBreak(bc, mats[m].id);
            breakCell = null;
            hits = 0;
            _changed();
          } else if (firstPerson && !breakHeld) {
            // tek dokunuş: bloğu bitirene kadar devam
          }
        }
      }
      changed = true;
    } else if (swing != 0) {
      swing = 0;
      changed = true;
    }
    // birinci şahısta nişangâh hedefi
    if (firstPerson) {
      final h = rayHit();
      var tc = h?.$1;
      final e = _rayEntity(h == null ? 5.5 + (behind ? camBack : 0) : lastRayT);
      if (e != null) tc = null;
      if (tc != aim || e != aimEnt) {
        aim = tc;
        aimNormal = tc == null ? null : h?.$2;
        aimEnt = e;
        changed = true;
      }
      if (breakHeld && breakCell == null && aim != null) _startBreak(aim!);
    }
    // işçiler
    if (jobs.isNotEmpty) {
      _tickJobs(dt);
      changed = true;
    }
    if (friends.isNotEmpty) {
      final lt0 = lifeTick;
      _tickFriends(dt);
      if (lifeTick != lt0) changed = true;
    }
    if (npcs.isNotEmpty) {
      final lt0 = lifeTick;
      _tickNpcs(dt);
      if (lifeTick != lt0) changed = true;
    }
    // hayvanlar
    final lt = lifeTick;
    _tickAnimals(dt);
    if (lt != lifeTick) changed = true;
    if (weather.isNotEmpty) wTime += dt;
    _mapT += dt;
    if (_mapT > 3) {
      _mapT = 0;
      _refreshMap();
    }
    if (!_dusk && game.windDownAt != null) {
      _dusk = true;
      night = true;
      _geoKey = '';
      changed = true;
    }
    if (floats.isNotEmpty) {
      for (final f in floats) {
        f.life -= dt;
        f.z += dt * 0.7;
      }
      floats.removeWhere((f) => f.life <= 0);
      changed = true;
    }
    // parçacıklar
    if (parts.isNotEmpty) {
      for (final p in parts) {
        p.life -= dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.z += p.vz * dt;
        p.vz -= p.g * dt;
      }
      parts.removeWhere((p) => p.life <= 0);
      changed = true;
    }
    // kamera karakteri izlesin
    if (!firstPerson && mode != 0 && (ml > 0 || (ax - fx).abs() > 6 || (ay - fy).abs() > 6)) {
      fx += (ax - fx) * min(1, dt * 3);
      fy += (ay - fy) * min(1, dt * 3);
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  double lastRayT = 5.5;

  /// Arkadan görünüm: kamera karakterin arkasında, omuz hizasının biraz üstünde.
  bool behind = false;
  double _tpx = 0, _tpy = 0, _trailT = 0, _hue = 0;

  void _emitTrail() {
    final r = Random();
    final px = cos(facing), py = -sin(facing); // sağ yan
    final pts = [
      (ax + px * 0.14, ay + py * 0.14, az + 0.08), // ayaklar
      (ax - px * 0.14, ay - py * 0.14, az + 0.08),
      (ax + px * 0.42, ay + py * 0.42, az + 0.85), // eller
      (ax - px * 0.42, ay - py * 0.42, az + 0.85),
    ];
    for (final (x, y, z) in pts) {
      if (r.nextDouble() < 0.4) continue;
      Color c;
      var kind = 0;
      var vz = 0.6 + r.nextDouble();
      var g = 3.0;
      var life = 0.9 + r.nextDouble() * 0.5;
      switch (game.trail) {
        case 'gokkusagi':
          _hue = (_hue + 14) % 360;
          c = HSVColor.fromAHSV(1, _hue, 0.85, 1).toColor();
        case 'yildiz':
          c = r.nextBool() ? const Color(0xFFFFEB3B) : Colors.white;
          kind = 1;
        case 'ates':
          c = [const Color(0xFFFF5722), const Color(0xFFFF9800), const Color(0xFFFFEB3B)][r.nextInt(3)];
          vz = 1.2 + r.nextDouble();
          g = -1.5; // yukarı süzülür
          life = 0.55;
        case 'kalp':
          c = [const Color(0xFFFF4081), const Color(0xFFF48FB1), const Color(0xFFE91E63)][r.nextInt(3)];
          kind = 2;
        default: // kopuk
          c = const Color(0xFFB3E5FC).withAlpha(220);
          kind = 2;
          g = -0.6;
          vz = 0.4;
          life = 1.6;
      }
      parts.add(_Particle(x, y, z, (r.nextDouble() - 0.5) * 0.6, (r.nextDouble() - 0.5) * 0.6, vz, c, life, kind: kind, g: g));
    }
    if (parts.length > 400) parts.removeRange(0, parts.length - 400);
  }
  double camBack = 0;

  /// Kameranın (gözün) konumu. Birinci şahısta baş, arkadan görünümde
  /// karakterin arkası; arada blok varsa kamera yaklaşır.
  (double, double, double) camEye() {
    final hx = ax, hy = ay, hz = az + 1.55;
    if (!behind) return (hx, hy, hz);
    final dx = sin(look) * cos(lookUp), dy = cos(look) * cos(lookUp), dz = sin(lookUp);
    var d = 0.0;
    const want = 4.2;
    while (d < want) {
      final nd = d + 0.15;
      final x = hx - dx * nd, y = hy - dy * nd, z = hz - dz * nd + nd * 0.12;
      final m = world.blocks[ck(x.floor(), y.floor(), z.floor())];
      if (m != null && mats[m].id != 'su' && z >= 0) break;
      d = nd;
    }
    d = max(0.0, d - 0.2);
    camBack = d;
    return (hx - dx * d, hy - dy * d, hz - dz * d + d * 0.12);
  }

  /// Gözden ileri ışın hayvan ya da ekine çarpıyor mu?
  (int, int)? _rayEntity(double maxT) {
    final (ex, ey, ez) = camEye();
    final dx = sin(look) * cos(lookUp), dy = cos(look) * cos(lookUp), dz = sin(lookUp);
    double? hitBox(double x0, double y0, double z0, double x1, double y1, double z1) {
      var tmin = 0.0, tmax = maxT;
      for (final (o, d, lo, hi) in [(ex, dx, x0, x1), (ey, dy, y0, y1), (ez, dz, z0, z1)]) {
        if (d.abs() < 1e-9) {
          if (o < lo || o > hi) return null;
        } else {
          var t1 = (lo - o) / d, t2 = (hi - o) / d;
          if (t1 > t2) (t1, t2) = (t2, t1);
          tmin = max(tmin, t1);
          tmax = min(tmax, t2);
          if (tmin > tmax) return null;
        }
      }
      return tmin;
    }

    (int, int)? best;
    var bt = maxT;
    for (var i = 0; i < npcs.length; i++) {
      final v = npcs[i];
      if ((v.x - ax).abs() > 8 || (v.y - ay).abs() > 8) continue;
      final t = hitBox(v.x - 0.35, v.y - 0.35, v.z, v.x + 0.35, v.y + 0.35, v.z + 1.9);
      if (t != null && t < bt) {
        bt = t;
        best = (7, i);
      }
    }
    for (var i = 0; i < friends.length; i++) {
      final f = friends[i];
      final t = hitBox(f.x - 0.35, f.y - 0.35, f.z, f.x + 0.35, f.y + 0.35, f.z + 1.9);
      if (t != null && t < bt) {
        bt = t;
        best = (6, i);
      }
    }
    for (var i = 0; i < animals.length; i++) {
      final a = animals[i];
      final h = _animalHeight(a.kind.id);
      final t = hitBox(a.x - 0.45, a.y - 0.45, a.z, a.x + 0.45, a.y + 0.45, a.z + h);
      if (t != null && t < bt) {
        bt = t;
        best = (2, i);
      }
    }
    for (final c in cropsAt.keys) {
      final (x, y, z) = cxyz(c);
      final t = hitBox(x + 0.1, y + 0.1, z.toDouble(), x + 0.9, y + 0.9, z + 0.8);
      if (t != null && t < bt) {
        bt = t;
        best = (3, c);
      }
    }
    return best;
  }

  /// Gözden ileri ışın: ilk dolu blok ve çarptığı yüz yönü (5 blok).
  (int, int)? rayHit() {
    final (ex, ey, ez) = camEye();
    final reach = 5.5 + (behind ? camBack : 0);
    final dx = sin(look) * cos(lookUp), dy = cos(look) * cos(lookUp), dz = sin(lookUp);
    var x = ex.floor(), y = ey.floor(), z = ez.floor();
    final sx = dx > 0 ? 1 : -1, sy = dy > 0 ? 1 : -1, sz = dz > 0 ? 1 : -1;
    double tMax(double p, double d, int c) {
      if (d.abs() < 1e-9) return 1e9;
      return d > 0 ? (c + 1 - p) / d : (p - c) / -d;
    }

    var tx = tMax(ex, dx, x), ty = tMax(ey, dy, y), tz = tMax(ez, dz, z);
    final ddx = dx.abs() < 1e-9 ? 1e9 : 1 / dx.abs(), ddy = dy.abs() < 1e-9 ? 1e9 : 1 / dy.abs(), ddz = dz.abs() < 1e-9 ? 1e9 : 1 / dz.abs();
    var face = -1;
    for (var i = 0; i < 40; i++) {
      if (tx < ty && tx < tz) {
        if (tx > reach) break;
        x += sx;
        tx += ddx;
        face = sx > 0 ? 2 : 1;
      } else if (ty < tz) {
        if (ty > reach) break;
        y += sy;
        ty += ddy;
        face = sy > 0 ? 4 : 3;
      } else {
        if (tz > reach) break;
        z += sz;
        tz += ddz;
        face = sz > 0 ? 5 : 0;
      }
      if (z < 0 || z >= H) break;
      final m = world.blocks[ck(x, y, z)];
      if (m != null && mats[m].id != 'su') {
        final dt = face == 1 || face == 2 ? tx - ddx : (face == 3 || face == 4 ? ty - ddy : tz - ddz);
        lastRayT = dt;
        return (ck(x, y, z), face);
      }
    }
    return null;
  }

  void _fpAction() {
    final e = aimEnt;
    if (pendingOrder != null && e == null && aim != null) {
      _giveOrder(aim!);
      return;
    }
    if (e != null) {
      if (e.$1 == 7) _greet(e.$2);
      if (e.$1 == 6) _friendTap(e.$2);
      if (e.$1 == 2) _befriend(e.$2);
      if (e.$1 == 3) _harvest(e.$2);
      return;
    }
    final t = aim;
    if (t != null && breakCell == null) _startBreak(t);
  }

  void _startBreak(int cell) {
    if (world.blocks[cell] == matIndex('hazine')) {
      _openChest(cell);
      return;
    }
    breakCell = cell;
    hits = 0;
    swing = 0.001;
  }

  void _fpPlace() {
    final a = aim, n = aimNormal;
    if (a == null || n == null) return;
    if (pendingOrder != null) {
      _giveOrder(a);
      return;
    }
    if (sel.startsWith('seed_')) {
      final (x, y, z) = cxyz(a);
      if (n == 0) _plant(ck(x, y, z + 1));
      return;
    }
    final pf = prefabById(sel);
    if (pf != null) {
      Say.show(context, Who.tamirci, 'Hazır yapıları dışarıdan görünümde, Kur ile koyabilirsin.');
      return;
    }
    final (x, y, z) = cxyz(a);
    final (nx, ny, nz) = _dirs[n];
    final xx = x + nx, yy = y + ny, zz = z + nz;
    if (!inside(xx, yy, zz)) return;
    final k = ck(xx, yy, zz);
    if (world.blocks.containsKey(k)) return;
    world.blocks[k] = matIndex(sel);
    if (!bodyFree(ax, ay, az)) {
      world.removeAt(k);
      Say.show(context, Who.tozbulut, 'Oraya koyamazsın, orada ben duruyorum!', mood: 'gul');
      return;
    }
    world.removeAt(k);
    _push();
    _putBlock(k, lookDir);
    world.version++;
    Sfx.play('tok');
    _changed();
  }

  void _burst(int cell, Color c, int n) {
    final (x, y, z) = cxyz(cell);
    final r = Random();
    for (var i = 0; i < n; i++) {
      parts.add(_Particle(x + 0.5, y + 0.5, z + 0.6, (r.nextDouble() - 0.5) * 3, (r.nextDouble() - 0.5) * 3, 2 + r.nextDouble() * 3,
          Color.lerp(c, Colors.black, r.nextDouble() * 0.3)!, 0.6 + r.nextDouble() * 0.3));
    }
  }

  void _arrived({bool blocked = false}) {
    final cc = chestCell;
    if (cc != null) {
      if (_inReach(cc)) {
        chestCell = null;
        _openChest(cc);
      } else if (blocked) {
        chestCell = null;
        _sayBlocked();
      }
      return;
    }
    final bc = breakCell;
    if (bc != null) {
      if (_inReach(bc)) {
        hits = 0;
        swing = 0.001;
      } else {
        breakCell = null;
        _sayBlocked();
      }
      return;
    }
    if (blocked) _sayBlocked();
  }

  void _sayBlocked() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _blockedSaid < 4000) return;
    _blockedSaid = now;
    Say.show(context, Who.tozbulut, 'Oraya geçemiyorum, yol kapalı! Duvarı kır ya da merdiven yap.', mood: 'uzgun');
  }

  Future<void> _openChest(int cell) async {
    final askMath = Random().nextBool();
    bool? ok;
    if (askMath) {
      final r = Random();
      final add = r.nextBool();
      final a = 2 + r.nextInt(6);
      final b = add ? 1 + r.nextInt(min(4, 10 - a)) : 1 + r.nextInt(a - 1);
      ok = await showDialog<bool>(
          context: context,
          builder: (_) => _MathDialog(add ? '$a + $b = ?' : '$a − $b = ?',
              'Hazine sandığının şifresi: $a ${add ? 'artı' : 'eksi'} $b kaç eder?', add ? a + b : a - b,
              emoji: '🧰'));
    } else {
      ok = await showDialog<bool>(context: context, builder: (_) => const _ChestDialog());
    }
    if (ok != true || !mounted) return;
    _push();
    world.removeAt(cell);
    world.version++;
    _burst(cell, const Color(0xFFFFC107), 18);
    Sfx.play('unlock');
    final next = tools.where((t) => !game.blockTools.contains(t.id)).firstOrNull;
    if (next != null) {
      game.addTool(next.id);
      if (next.id != 'kalkan') hand = next.id;
      _changed();
      await showDialog<void>(context: context, builder: (_) => _ToolDialog(next));
      if (mounted && next.id != 'kalkan') setState(() => mode = 2);
    } else {
      game.addStars(1);
      _changed();
      Say.show(context, Who.tamirci, 'Sandıktan bir yıldız çıktı! Bütün aletleri zaten buldun.', mood: 'sevin');
    }
  }

  @override
  void dispose() {
    mapImg?.dispose();
    _saveLife();
    saveFriends(friends);
    _ticker.dispose();
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
      final x = (fx + r.nextInt(9) - 4).round().clamp(minX + 1, maxX - 2).toInt(), y = (fy + r.nextInt(9) - 4).round().clamp(minY + 1, maxY - 1).toInt();
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
    game.addCoins(3);
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
      if (world.shapeAt.containsKey(e.key)) continue;
      final (x, y, z) = cxyz(e.key);
      final m = mats[e.value];
      for (var d = 0; d < 6; d++) {
        if (d == 5 && z == 0) continue;
        final (nx, ny, nz) = _dirs[d];
        final xx = x + nx, yy = y + ny, zz = z + nz;
        if (inside(xx, yy, zz)) {
          final nk = ck(xx, yy, zz);
          final o = world.blocks[nk];
          if (o != null && !world.shapeAt.containsKey(nk) && (!mats[o].see || (m.see && o == e.value))) continue;
        }
        out.add(_Face(e.key, d, e.value));
      }
    }
    exposed = out;
  }

  // ---------- dokunma ----------
  /// Dokunulan yüz (karakter hariç)
  _Face? _faceAt(Offset p) {
    for (var i = _hit.count - 1; i >= 0; i--) {
      if (_hit.faces[i].ent == 1) continue;
      if (_hit.contains(i, p)) return _hit.faces[i];
    }
    return null;
  }

  (int, bool, int)? _target(Offset p) {
    final n = _hit.count;
    for (var i = n - 1; i >= 0; i--) {
      if (_hit.faces[i].ent != 0 && _hit.faces[i].ent != 4) continue;
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
    final fe = _faceAt(p);
    if (fe != null && (fe.ent == 2 || fe.ent == 3 || fe.ent == 6 || fe.ent == 7)) return;
    if (mode != 0) {
      final f = _faceAt(p);
      setState(() {
        previewCell = f == null ? null : (mode == 2 ? f.cell : _walkCell(f));
        previewErase = mode == 2;
      });
      return;
    }
    final t = _target(p);
    setState(() {
      previewCell = t?.$1;
      previewErase = t?.$2 ?? false;
    });
  }

  int _walkCell(_Face f) {
    final (x, y, z) = cxyz(f.cell);
    final (nx, ny, nz) = _dirs[f.dir];
    return ck(x + nx, y + ny, z + nz);
  }

  void _avatarTap(Offset p) {
    final f = _faceAt(p);
    setState(() => previewCell = null);
    if (f == null) return;
    if (f.ent == 6) {
      _friendTap(f.cell);
      return;
    }
    if (f.ent == 7) {
      _greet(f.cell);
      return;
    }
    if (pendingOrder != null && (f.ent == 0 || f.ent == 4)) {
      _giveOrder(f.cell);
      return;
    }
    if (f.ent == 2) {
      _befriend(f.cell);
      return;
    }
    if (f.ent == 3) {
      _harvest(f.cell);
      return;
    }
    final hz = matIndex('hazine');
    final (x, y, z) = cxyz(f.cell);
    if (mode == 1 && _useSpecial(f.cell)) return;
    if (world.blocks[f.cell] == hz) {
      chestCell = f.cell;
      breakCell = null;
      if (_inReach(f.cell)) {
        chestCell = null;
        _openChest(f.cell);
      } else {
        walkTo = (x, y);
        Voice.say('Hazine sandığı! Gidip açalım.');
      }
      return;
    }
    if (mode == 2) {
      chestCell = null;
      breakCell = f.cell;
      hits = 0;
      if (_inReach(f.cell)) {
        swing = 0.001;
      } else {
        walkTo = (x, y);
      }
      return;
    }
    // yürü
    chestCell = null;
    breakCell = null;
    final (wx, wy, _) = cxyz(_walkCell(f));
    walkTo = f.dir == 0 ? (x, y) : (wx, wy);
    Sfx.play('click', volume: 0.4);
  }

  Future<void> _up(Offset p) async {
    if (mode != 0) {
      _avatarTap(p);
      return;
    }
    final fe = _faceAt(p);
    if (fe != null && fe.ent == 6) {
      setState(() => previewCell = null);
      _friendTap(fe.cell);
      return;
    }
    if (fe != null && fe.ent == 7) {
      setState(() => previewCell = null);
      _greet(fe.cell);
      return;
    }
    if (fe != null && fe.ent == 0 && world.blocks[fe.cell] == matIndex('miras')) {
      setState(() => previewCell = null);
      _openMiras(fe.cell);
      return;
    }
    if (pendingOrder != null) {
      setState(() => previewCell = null);
      if (fe != null && (fe.ent == 0 || fe.ent == 4)) _giveOrder(fe.cell);
      return;
    }
    if (fe != null && (fe.ent == 2 || fe.ent == 3)) {
      setState(() => previewCell = null);
      if (fe.ent == 2) _befriend(fe.cell);
      if (fe.ent == 3) _harvest(fe.cell);
      return;
    }
    final t = _target(p);
    setState(() => previewCell = null);
    if (t == null) return;
    final (k, del, dir) = t;
    if (!del && sel.startsWith('seed_')) {
      if (dir == 0) _plant(k);
      return;
    }
    if (del && cropsAt.containsKey(ck(cxyz(k).$1, cxyz(k).$2, cxyz(k).$3 + 1))) {
      cropsAt.remove(ck(cxyz(k).$1, cxyz(k).$2, cxyz(k).$3 + 1));
      _saveLife();
    }
    if (del) {
      _push();
      world.removeAt(k);
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
      final plan = world.plan(pf.cells(), x, y, z, forwardDir); // kapı kameraya bakar, yapı ileri doğru uzar
      if (pf.id == 'p_agac' || pf.id == 'p_cam') game.plantTree();
      _startJob(pf, plan, x, y, z);
      return;
    }
    final (kx, ky, kz) = cxyz(k);
    if (kx == ax.floor() && ky == ay.floor() && (kz == level || kz == level + 1)) {
      Say.show(context, Who.tozbulut, 'Oraya koyamazsın, orada ben duruyorum!', mood: 'gul');
      return;
    }
    _push();
    _putBlock(k, forwardDir);
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
    animals.clear();
    cropsAt.clear();
    _spawnAnimals(9, minX, maxX, minY, maxY);
    _saveLife();
    _changed();
  }

  /// Büyüt: dünya balon gibi her yana birden şişer.
  Future<void> _grow() async {
    if (world.erx > 230) {
      Say.show(context, Who.tamirci, 'Dünya en büyük hâline geldi! Daha fazla şişemez.');
      return;
    }
    _push();
    Sfx.play('unlock');
    Voice.say('Dünya balon gibi şişiyor!');
    final r = Random();
    for (var i = 0; i < 4; i++) {
      world.inflate(3, r);
      world.version++;
      _geoKey = '';
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }
    _ensureNpcs();
    _spawnAnimals(4, minX, maxX, minY, maxY);
    _saveLife();
    _changed();
    Say.show(context, Who.tamirci,
        'Dünya şişti! Artık $worldW çarpı $worldD blok. Yeni tepeler, göller, ormanlar ve tepelerin içinde değerli taşlar var!',
        mood: 'sevin');
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
      recent.remove(id);
      recent.insert(0, id);
      if (recent.length > 8) recent.removeLast();
      if (id.startsWith('seed_') || id.startsWith('p_')) mode = 0;
    });
  }

  /// Seçili malzemeyi (ve şekli) hücreye koyar.
  // ================= hece madeni, tezgâh, tabela, hece kapısı, hava totemi =================
  final Map<int, String> signs = {};
  String weather = '';
  double wTime = 0;
  bool _dusk = false;
  final List<_Float> floats = [];

  void _loadSigns() {
    signs.clear();
    for (final e in game.blockSigns.split(';')) {
      final i = e.indexOf(':');
      if (i <= 0) continue;
      final k = int.tryParse(e.substring(0, i));
      if (k != null) signs[k] = e.substring(i + 1);
    }
  }

  void _saveSigns() => game.saveSigns(signs.entries.map((e) => '${e.key}:${e.value}').join(';'));

  void _float(int cell, String text, [int i = 0]) {
    final (x, y, z) = cxyz(cell);
    floats.add(_Float(x + 0.5, y + 0.5, z + 1.0 + i * 0.55, text, 1.8));
  }

  void _afterBreak(int cell, String id) {
    if (signs.remove(cell) != null) _saveSigns();
    final gemId = gemOres[id];
    if (gemId != null) {
      _mineGem(cell, id, gemId);
      return;
    }
    final r = Random();
    var n = 0;
    if (id == 'heceta') {
      n = 2;
    } else if (const {'komur', 'demirc', 'altinc', 'elmas'}.contains(id)) {
      n = r.nextDouble() < 0.5 ? 1 : 0;
    } else if (id == 'tas' || id == 'tasduvar' || id == 'kumtasi') {
      n = r.nextDouble() < 0.25 ? 1 : 0;
    }
    if (n == 0) return;
    final got = <String>[];
    for (var i = 0; i < n; i++) {
      final syl = pickDropSyl(r);
      game.addSyl(syl);
      got.add(syl);
      _float(cell, syl, i);
    }
    Sfx.play('pop');
    Voice.say(got.join('... '));
    final total = game.sylBag.values.fold(0, (a, b) => a + b);
    if (total <= 2 && mounted) {
      Say.show(context, Who.tamirci,
          'Hece taşı buldun: ${got.join(', ')}! Aşağıdaki 🔨 düğmesine dokun, hecelerden kelime yap.',
          mood: 'sevin');
    }
  }

  /// Değerli taş: adını heceleyince müzeye girer; vazgeçerse taş yerinde kalır.
  Future<void> _mineGem(int cell, String oreId, String gemId) async {
    final t = treasureById(gemId);
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: t.parts,
              emoji: t.emoji,
              title: 'Değerli taş buldun! Adını yaz: ${t.name}',
              speech: 'Vay! Değerli bir taş buldun. Adını hecelerle yaz, çıkar!',
            ));
    if (!mounted) return;
    if (ok != true) {
      world.blocks[cell] = matIndex(oreId); // taş kaçmasın
      world.version++;
      _changed();
      return;
    }
    final first = !game.treasures.contains(t.id);
    game.addTreasure(t.id);
    game.addCoins(t.coins);
    _burst(cell, mats[matIndex(oreId)].color, 16);
    Sfx.play('unlock');
    Say.show(context, Who.baykus,
        '${trCapitalize(t.name)}! ${t.info} ${t.coins} altın kazandın.${first ? ' Müzene yeni bir hazine girdi!' : ''}',
        mood: 'sevin');
  }

  /// Miras sandığı: içindeki eşyanın adını heceleyince açılır.
  Future<void> _openMiras(int cell) async {
    final (x, y, _) = cxyz(cell);
    String? near;
    var best = 14.0;
    for (final e in world.places.entries) {
      final d = sqrt(pow(e.value.$1 - x, 2) + pow(e.value.$2 - y, 2));
      if (d < best) {
        best = d;
        near = e.key.split(' ').first;
      }
    }
    final t = nextHeritage(near);
    if (t == null) {
      Say.show(context, Who.baykus, 'Bütün miras hazinelerini buldun! Maşallah, müzen dolu.', mood: 'sevin');
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: t.parts,
              emoji: t.emoji,
              title: 'Miras sandığı! İçindekinin adını yaz: ${t.name}',
              speech: 'Bu bir miras sandığı! İçinde ${t.name} var. Adını hecelerle yaz, sandık açılsın.',
            ));
    if (ok != true || !mounted) return;
    world.blocks.remove(cell);
    world.version++;
    game.addTreasure(t.id);
    game.addCoins(t.coins);
    _burst(cell, const Color(0xFF64FFDA), 20);
    _burst(cell, const Color(0xFFFFD54F), 12);
    Sfx.play('unlock');
    _changed();
    Say.show(context, Who.baykus, '${t.emoji} ${trCapitalize(t.name)}! ${t.info} Müzene koydum.', mood: 'sevin');
  }

  Future<void> _openMuseum() async {
    await Navigator.push(context, fadeRoute(const MuseumScreen()));
    if (mounted) setState(() {});
  }

  bool _useSpecial(int cell) {
    final m = world.blocks[cell];
    if (m == null) return false;
    switch (mats[m].id) {
      case 'miras':
        _openMiras(cell);
        return true;
      case 'tezgah':
        _openBench();
        return true;
      case 'tabela':
        final w = signs[cell];
        if (w == null) {
          _setSign(cell);
        } else {
          Voice.say(trCapitalize(w));
          _float(cell, w);
        }
        return true;
      case 'hecekapi':
        _openWordDoor(cell);
        return true;
      case 'totem':
        _castWeather();
        return true;
    }
    return false;
  }

  Future<void> _openBench() async {
    await Navigator.push(context, fadeRoute(const WorkbenchScreen()));
    if (!mounted) return;
    final r = Random();
    for (final id in pendingAnimals) {
      final a = r.nextDouble() * 2 * pi;
      animals.add(Animal(kindById(id), ax + sin(a) * 1.6, ay + cos(a) * 1.6, az, friend: true));
    }
    if (pendingAnimals.isNotEmpty) {
      pendingAnimals.clear();
      _saveLife();
      lifeTick++;
    }
    setState(() {});
  }

  Future<void> _openVillage() async {
    await Navigator.push(context, fadeRoute(const VillageScreen()));
    if (!mounted) return;
    if (pendingBloom > 0) {
      final r = Random();
      final cim = matIndex('cim'), cicek = matIndex('cicek');
      var n = pendingBloom;
      pendingBloom = 0;
      for (var i = 0; i < 80 && n > 0; i++) {
        final x = ax.floor() + r.nextInt(13) - 6, y = ay.floor() + r.nextInt(13) - 6;
        if (!inside(x, y, 0)) continue;
        final z = world.topZ(x, y);
        if (world.blocks[ck(x, y, z)] != cim) continue;
        world.blocks[ck(x, y, z)] = cicek;
        _burst(ck(x, y, z), const Color(0xFFFF80AB), 6);
        n--;
      }
      world.version++;
      _changed();
      Voice.say('Bak! Paylaştın, şehrinde çiçekler açtı.');
    }
    setState(() {});
  }

  /// Akşam masalında söz verilen sürpriz yumurta: ertesi gün çatlar.
  void _surpriseEgg() {
    if (game.surpriseDay.isEmpty || game.surpriseDay == game.dayKey) return;
    game.surpriseDay = '';
    game.save();
    final kind = animalKinds[Random().nextInt(animalKinds.length)];
    animals.add(Animal(kind, ax + 1.5, ay + 0.5, az, friend: true));
    _saveLife();
    lifeTick++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Sfx.play('unlock');
      Say.show(context, Who.ayi, 'Günaydın! Dün söz verdiğim sürpriz yumurta çatladı: içinden bir ${kind.name} çıktı! Artık senin arkadaşın.');
    });
  }

  Future<void> _setSign(int cell) async {
    final w = await showDialog<String>(context: context, builder: (_) => const SignDialog());
    if (w == null || !mounted) return;
    setState(() => signs[cell] = w);
    _saveSigns();
    Sfx.play('unlock');
    Voice.say('Tabelada ${trCapitalize(w)} yazıyor! Dokununca okur.');
  }

  Future<void> _openWordDoor(int cell) async {
    final list = recipesNow();
    final rc = list[Random().nextInt(list.length)];
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: rc.parts,
              emoji: rc.emoji,
              title: 'Hece kapısı! ${rc.word} yaz, kapı açılsın.',
              speech: 'Hece kapısı! ${trCapitalize(rc.word)} yaz, kapı açılsın.',
            ));
    if (ok != true || !mounted) return;
    final hk = matIndex('hecekapi'), kp = matIndex('kapi');
    final (x, y, z) = cxyz(cell);
    for (var zz = z - 2; zz <= z + 2; zz++) {
      final k = ck(x, y, zz);
      if (world.blocks[k] == hk) world.blocks[k] = kp;
    }
    world.version++;
    _changed();
    Sfx.play('unlock');
    game.addCoins(1);
    Say.show(context, Who.tamirci, 'Kapı açıldı! Hece kapısını sen de evine koyabilirsin.', mood: 'sevin');
  }

  Future<void> _castWeather() async {
    final w = await showDialog<String>(context: context, builder: (_) => const WeatherDialog());
    if (w == null || !mounted) return;
    setState(() {
      weather = w == 'gunes' ? '' : w;
      if (w == 'gunes') night = false;
    });
    var msg = '';
    if (w == 'yagmur') {
      for (final k in cropsAt.keys.toList()) {
        final c = cropsAt[k]!;
        cropsAt[k] = (c.$1, c.$2 - cropStageMs);
      }
      _saveLife();
      msg = 'Yağmur yağıyor! Bütün ekinler sulandı ve büyüdü.';
    } else if (w == 'kar') {
      msg = 'Kar yağıyor! Her yer bembeyaz olacak.';
    } else {
      msg = 'Güneş açtı! Hava çok güzel.';
    }
    Sfx.play('unlock');
    Say.show(context, Who.tozbulut, msg, mood: 'gul');
  }

  void _putBlock(int k, int dir) {
    final mi = matIndex(sel);
    world.blocks[k] = mi;
    if (sel == 'mesale') {
      world.shapeAt[k] = 20 * 4;
    } else if (selShape > 0) {
      world.shapeAt[k] = selShape * 4 + dir;
    } else {
      world.shapeAt.remove(k);
    }
    if (sel == 'tabela') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setSign(k);
      });
    } else if (sel == 'tezgah' || sel == 'totem' || sel == 'hecekapi') {
      final tip = const {
        'tezgah': 'Kelime tezgâhı kuruldu! Yürü ile üstüne dokun, hecelerden kelime yap.',
        'totem': 'Hava totemi kuruldu! Yürü ile dokun; güneş, yağmur ya da kar yağdır.',
        'hecekapi': 'Hece kapısı! Yürü ile dokununca bir kelime sorar, doğru yazan girer.',
      }[sel]!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Say.show(context, Who.tamirci, tip, mood: 'iyi');
      });
    }
  }

  int get lookDir {
    final ax2 = sin(look), ay2 = cos(look);
    if (ax2.abs() > ay2.abs()) return ax2 > 0 ? 1 : 3;
    return ay2 > 0 ? 0 : 2;
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
              Bouncy(
                onTap: _openBench,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text('🪙${game.coins}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
              Bouncy(
                onTap: _grow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_location_alt, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text('Büyüt\n$worldW×$worldD',
                        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.05, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
              _Tool(Icons.smart_toy, _newMath, color: const Color(0xFFB3E5FC)),
              _Tool(Icons.refresh, _reset),
            ])),
            _questBar(),
            Expanded(
              child: LayoutBuilder(builder: (_, c) {
                area = Size(c.maxWidth, c.maxHeight);
                return Stack(children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTapDown: (d) => firstPerson ? null : _down(d.localPosition),
                      onTapUp: (d) => firstPerson ? _fpTap() : _up(d.localPosition),
                      onTapCancel: () => setState(() => previewCell = null),
                      onScaleStart: (d) {
                        _y0 = yaw;
                        _p0 = pitch;
                        _z0 = zoom;
                        _f0 = d.localFocalPoint;
                        _fx0 = fx;
                        _fy0 = fy;
                        _l0 = look;
                        _lu0 = lookUp;
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
                          if (firstPerson) {
                            look = _l0 + delta.dx * 0.006;
                            lookUp = (_lu0 - delta.dy * 0.005).clamp(-1.35, 1.35).toDouble();
                          } else if (_pointers >= 2 || moveMode) {
                            zoom = (_z0 * d.scale).clamp(0.5, 3.0).toDouble();
                            final s = scale, sp = sin(pitch);
                            final a = delta.dx / s, b = delta.dy / (sp * s);
                            final wx = a * cos(yaw) + b * sin(yaw), wy = -a * sin(yaw) + b * cos(yaw);
                            fx = (_fx0 - wx).clamp(minX.toDouble(), maxX + 1.0).toDouble();
                            fy = (_fy0 - wy).clamp(minY.toDouble(), maxY + 1.0).toDouble();
                          } else {
                            yaw = _y0 - delta.dx * 0.008;
                            pitch = (_p0 + delta.dy * 0.004).clamp(0.35, 1.25).toDouble();
                          }
                        });
                      },
                      child: ClipRect(child: CustomPaint(size: area, painter: _WorldPainter(this, pulse))),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Column(children: [
                      _ViewSwitch(!firstPerson ? 0 : (behind ? 2 : 1), _toggleView),
                      _Tool(night ? Icons.wb_sunny : Icons.nightlight_round, () {
                        setState(() {
                          night = !night;
                          _geoKey = '';
                        });
                        Voice.say(night ? 'Gece oldu. Işıklarını yak!' : 'Günaydın!');
                      }, color: night ? const Color(0xFF3949AB) : const Color(0xFFFFF59D)),
                      if (!firstPerson) ...[
                        _Tool(Icons.zoom_in, () => setState(() => zoom = min(3.0, zoom + 0.35))),
                        _Tool(Icons.zoom_out, () => setState(() => zoom = max(0.5, zoom - 0.35))),
                        _Tool(moveMode ? Icons.open_with : Icons.threesixty, () {
                          setState(() => moveMode = !moveMode);
                          Voice.say(moveMode ? 'Kaydır' : 'Döndür');
                        }, color: moveMode ? const Color(0xFFFFF59D) : Colors.white),
                        _Tool(Icons.person_pin_circle, () {
                          setState(() {
                            fx = ax;
                            fy = ay;
                            zoom = max(zoom, 1.4);
                          });
                        }),
                      ],
                      Bouncy(
                        onTap: _friendsMenu,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xFFE1BEE7), borderRadius: BorderRadius.circular(12)),
                          child: const Text('👥', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      Bouncy(
                        onTap: _openVillage,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 42,
                          height: 54,
                          decoration: BoxDecoration(color: const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(12)),
                          child: const Pic('k_teyze', height: 52),
                        ),
                      ),
                      Bouncy(
                        onTap: () async {
                          final before = avatar.armor;
                          await Navigator.push(context, fadeRoute(const AvatarScreen()));
                          if (mounted) {
                            setState(() => avatar = myAvatar);
                            _armorChanged(before);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 42,
                          height: 54,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: CustomPaint(painter: AvatarPainter(avatar, 0.5)),
                        ),
                      ),
                    ]),
                  ),
                  if (firstPerson || mode != 0) Positioned(left: 8, bottom: 8, child: _pad()),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: MiniMap(
                      img: mapImg,
                      px: ax,
                      py: ay,
                      facing: facing,
                      places: world.places,
                      friends: [for (final f in friends) (f.x, f.y)],
                      onTap: _openMap,
                    ),
                  ),
                  if (pendingOrder != null) Positioned(left: 8, right: 60, top: 116, child: Center(child: _orderBanner())),
                  if (firstPerson)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        _flyChip(),
                        Row(children: [
                          if (flying) ...[_downBtn(), const SizedBox(width: 8)],
                          _ActionBtn('🧱', 'Koy', const Color(0xFF66BB6A), down: () => _fpPlace()),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          _upBtn(),
                          const SizedBox(width: 8),
                          _ActionBtn(aimEnt == null ? '⛏️' : (aimEnt!.$1 == 2 ? '💛' : '🧺'),
                              aimEnt == null ? 'Kır' : (aimEnt!.$1 == 2 ? 'Sev' : 'Topla'), const Color(0xFFEF5350), big: true, down: () {
                            breakHeld = aimEnt == null;
                            _fpAction();
                          }, up: () => breakHeld = false),
                        ]),
                      ]),
                    )
                  else if (mode != 0)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        _flyChip(),
                        Row(children: [if (flying) ...[_downBtn(), const SizedBox(width: 8)], _upBtn()]),
                      ]),
                    ),
                ]);
              }),
            ),
            if (firstPerson) _fpBar() else ...[
              _modes(),
              if (mode == 0) ...[_controls(), _hotbar()] else _toolBar(),
            ],
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

  void _toggleView() {
    Sfx.play('uc');
    setState(() {
      if (!firstPerson) {
        firstPerson = true;
        behind = false;
      } else if (!behind) {
        behind = true;
      } else {
        firstPerson = false;
        behind = false;
      }
      walkTo = null;
      breakCell = null;
      padF = 0;
      padR = 0;
      if (firstPerson && behind) {
        lookUp = -0.25;
      } else if (firstPerson) {
        look = facing;
        lookUp = -0.2;
      } else {
        fx = ax;
        fy = ay;
        yaw = look + pi; // karakterin arkasından bak
        zoom = max(zoom, 1.4);
      }
      _geoKey = '';
    });
    Voice.say(!firstPerson
        ? 'Dışarıdan bakıyorsun.'
        : (behind
            ? 'Şimdi karakterini arkadan görüyorsun! Yön tuşlarıyla yürüt.'
            : 'Şimdi karakterin gözünden bakıyorsun! Yön tuşlarıyla yürü, ekranı sürükleyerek etrafına bak.'));
  }

  void _fpTap() {
    if (pendingOrder != null && aimEnt == null && aim != null) {
      _giveOrder(aim!);
      return;
    }
    if (aimEnt != null) {
      _fpAction();
      return;
    }
    final t = aim;
    if (t == null) return;
    if (_useSpecial(t)) return;
    if (world.blocks[t] == matIndex('hazine')) {
      _openChest(t);
    }
  }

  Widget _pad() {
    Widget arrow(IconData ic, double f, double r) => Listener(
          onPointerDown: (_) => setState(() {
            padF = f == 0 ? padF : f;
            padR = r == 0 ? padR : r;
          }),
          onPointerUp: (_) => setState(() {
            if (f != 0) padF = 0;
            if (r != 0) padR = 0;
          }),
          onPointerCancel: (_) => setState(() {
            padF = 0;
            padR = 0;
          }),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(((f != 0 && padF == f) || (r != 0 && padR == r)) ? 250 : 170),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Icon(ic, size: 36, color: Colors.black87),
          ),
        );
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(children: [
        Positioned(left: 54, top: 0, child: arrow(Icons.keyboard_arrow_up, 1, 0)),
        Positioned(left: 54, bottom: 0, child: arrow(Icons.keyboard_arrow_down, -1, 0)),
        Positioned(left: 0, top: 54, child: arrow(Icons.keyboard_arrow_left, 0, -1)),
        Positioned(right: 0, top: 54, child: arrow(Icons.keyboard_arrow_right, 0, 1)),
      ]),
    );
  }

  /// Birinci şahısta alt çubuk: alet, çanta ve son kullanılanlar
  Widget _fpBar() {
    final owned = tools.where((t) => game.blockTools.contains(t.id) && t.id != 'kalkan').toList();
    return Container(
      height: 128,
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        SizedBox(
          height: 54,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _toolChip('✊', 'el', hand == null, () => setState(() => hand = null)),
            for (final t in owned) _toolChip(t.emoji, t.name, hand == t.id, () => setState(() => hand = t.id)),
            if (game.blockTools.length < tools.length)
              _toolChip('🧰', 'sandıkta', false,
                  () => Say.show(context, Who.tamirci, 'Hazine sandıklarını bul! Nişangâhı sandığa getirip Kır tuşuna bas.')),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(child: Row(children: [_bagButton(), _benchButton(), _museumButton(), _shapeButton(), Expanded(child: _recentList())])),
      ]),
    );
  }

  Widget itemIcon(String id) {
    if (id.startsWith('seed_')) return Center(child: Text(cropById(id.substring(5)).emoji, style: const TextStyle(fontSize: 26)));
    final pf = prefabById(id);
    if (pf != null) return Center(child: Text(pf.emoji, style: const TextStyle(fontSize: 26)));
    final m = matIndex(id);
    return m >= 0 ? MatSwatch(mats[m]) : const SizedBox();
  }

  Widget _bagButton() => Bouncy(
        onTap: _openBag,
        child: Container(
          width: 64,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4E342E), width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: const FittedBox(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🎒', style: TextStyle(fontSize: 28)),
                Text('Çanta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
            ),
          ),
        ),
      );

  Widget _museumButton() => Bouncy(
        onTap: _openMuseum,
        child: Container(
          width: 52,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6D4C41),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFC107), width: 3),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏛️', style: TextStyle(fontSize: 22)),
                Text('${game.treasures.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
            ),
          ),
        ),
      );

  Widget _benchButton() => Bouncy(
        onTap: _openBench,
        child: Container(
          width: 56,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB39DDB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4527A0), width: 3),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔨', style: TextStyle(fontSize: 22)),
                Text('${game.sylBag.values.fold(0, (a, b) => a + b)} hece',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
            ),
          ),
        ),
      );

  Widget _shapeButton() => Bouncy(
        onTap: _openBag,
        child: Container(
          width: 52,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14)),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ShapeIcon(shapes[selShape].id, size: 30),
                Text(shapes[selShape].name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      );

  Widget _recentList() => ListView(scrollDirection: Axis.horizontal, children: [
        for (final id in recent)
          if (unlocked(id))
            Bouncy(
              onTap: () => _select(id),
              child: Container(
                width: 54,
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel == id && !erase ? const Color(0xFFFFF59D) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel == id && !erase ? Colors.orange : Colors.black12, width: sel == id && !erase ? 3 : 1),
                ),
                child: itemIcon(id),
              ),
            ),
      ]);

  Widget _hotbar() => Container(
        height: 84,
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [_bagButton(), _benchButton(), _museumButton(), _shapeButton(), Expanded(child: _recentList())]),
      );

  Widget _modes() {
    const labels = [('🏗️', 'Kur'), ('🚶', 'Yürü'), ('⛏️', 'Kır')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Bouncy(
              onTap: () {
                Sfx.play('click');
                setState(() {
                  mode = i;
                  erase = false;
                  breakCell = null;
                  chestCell = null;
                  if (i != 0) {
                    fx = ax;
                    fy = ay;
                    zoom = max(zoom, 1.3);
                  }
                });
                Voice.say(const [
                  'Kurma. Blok seç ve dokun.',
                  'Yürü. Gitmek istediğin yere dokun.',
                  'Kır. Kırmak istediğin bloğa dokun.'
                ][i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: mode == i ? const Color(0xFFFFB300) : Colors.white.withAlpha(220),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(labels[i].$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(labels[i].$2, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  /// Yürü/Kır modunda: aletler ve envanter
  Widget _toolBar() {
    final owned = tools.where((t) => game.blockTools.contains(t.id) && t.id != 'kalkan').toList();
    final mined = game.mined.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      height: 150,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Elimde: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          Expanded(
            child: SizedBox(
              height: 58,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _toolChip('✋', 'el', hand == null, () => setState(() => hand = null)),
                for (final t in owned) _toolChip(t.emoji, t.name, hand == t.id, () => setState(() => hand = t.id)),
                if (game.blockTools.contains('kalkan')) _toolChip('🛡️', 'kalkan ✓', false, () => Voice.say('Kalkanın sol kolunda!')),
                if (owned.length + (game.blockTools.contains('kalkan') ? 1 : 0) < tools.length)
                  _toolChip('🧰', '${tools.length - game.blockTools.length} sandıkta', false,
                      () => Say.show(context, Who.tamirci, 'Şehirde hazine sandıkları var! Bul, Yürü ile yanına git, aç. İçinden alet çıkar.')),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Text('Envanter ∞  ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          Expanded(
            child: SizedBox(
              height: 52,
              child: mined.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Kırdığın bloklar burada sayılır. Bütün bloklar sınırsız!',
                          style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)))
                  : ListView(scrollDirection: Axis.horizontal, children: [
                      for (final e in mined)
                        if (matIndex(e.key) >= 0)
                          Container(
                            width: 50,
                            margin: const EdgeInsets.only(right: 4),
                            child: Stack(children: [
                              Positioned.fill(child: MatSwatch(mats[matIndex(e.key)])),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                  child: Text('${e.value}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ]),
                          ),
                    ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _toolChip(String emoji, String name, bool on, VoidCallback tap) => Bouncy(
        onTap: () {
          Sfx.play('click');
          Voice.say(name);
          tap();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF59D) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? Colors.orange : Colors.black12, width: on ? 3 : 1),
          ),
          child: FittedBox(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );

  Widget _controls() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
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


}

/// Ekrandaki dokunulabilir çokgenler (ekran koordinatında, x,y çiftleri)
class _HitData {
  List<_Face> faces = [];
  List<Float32List> polys = [];
  int get count => min(faces.length, polys.length);

  bool contains(int i, Offset p) {
    final q = polys[i];
    final n = q.length ~/ 2;
    if (n < 3) return false;
    var sign = 0;
    for (var k = 0; k < n; k++) {
      final ax = q[k * 2], ay = q[k * 2 + 1];
      final bx = q[((k + 1) % n) * 2], by = q[((k + 1) % n) * 2 + 1];
      final cr = (bx - ax) * (p.dy - ay) - (by - ay) * (p.dx - ax);
      final sg = cr > 0 ? 1 : (cr < 0 ? -1 : 0);
      if (sg == 0) continue;
      if (sign == 0) {
        sign = sg;
      } else if (sg != sign) {
        return false;
      }
    }
    return sign != 0;
  }
}

/// Dünya uzayında dışbükey bir çokgen
class _Poly {
  final List<double> p; // x,y,z üçlüleri
  final List<double> uv; // atlas u,v çiftleri
  final int color;
  final _Face hit;
  final double nx, ny, nz, cx, cy, cz;
  _Poly(this.p, this.uv, this.color, this.hit, this.nx, this.ny, this.nz, this.cx, this.cy, this.cz);
}

const _glowColors = {
  'fener': Color(0xFFFFC107),
  'mesale': Color(0xFFFF9800),
  'lamba': Color(0xFFFFF59D),
  'led_kirmizi': Color(0xFFFF1744),
  'led_mavi': Color(0xFF2979FF),
  'led_yesil': Color(0xFF00E676),
  'led_mor': Color(0xFFD500F9),
  'led_sari': Color(0xFFFFEA00),
  'heceta': Color(0xFFB388FF),
  'yakutc': Color(0xFFFF5252),
  'firuzec': Color(0xFF18FFFF),
  'kehribarc': Color(0xFFFFC400),
  'miras': Color(0xFF64FFDA),
};

class _WorldPainter extends CustomPainter {
  final BlokAdasiState s;
  final Animation<double> anim;
  _WorldPainter(this.s, this.anim) : super(repaint: anim);

  static const _shade = [1.0, 0.80, 0.66, 0.72, 0.88, 0.55];

  static int _gray(double sh) {
    final g = (255 * sh).round().clamp(0, 255);
    return (0xFF << 24) | (g << 16) | (g << 8) | g;
  }

  static int _tint(Color c, double sh) =>
      (0xFF << 24) | ((c.r * 255 * sh).round().clamp(0, 255) << 16) | ((c.g * 255 * sh).round().clamp(0, 255) << 8) | (c.b * 255 * sh).round().clamp(0, 255);

  /// Görüş alanındaki bütün çokgenler: bloklar, şekilli bloklar, karakter, hayvanlar, ekinler
  List<_Poly> _collect(double ox, double oy, double reach, {required bool withAvatar}) {
    final out = <_Poly>[];
    final atlasOk = Tex.atlas != null;
    for (final f in s.exposed) {
      final (x, y, z) = cxyz(f.cell);
      if ((x + 0.5 - ox).abs() > reach || (y + 0.5 - oy).abs() > reach) continue;
      final c = _corners(x.toDouble(), y.toDouble(), z.toDouble(), f.dir);
      final r = Tex.tile(f.mat * 2 + (f.dir == 0 ? 0 : 1));
      final (nx, ny, nz) = _dirs[f.dir];
      final sh = _shade[f.dir];
      out.add(_Poly(
          c,
          [r.left + 0.02, r.top + 0.02, r.right - 0.02, r.top + 0.02, r.right - 0.02, r.bottom - 0.02, r.left + 0.02, r.bottom - 0.02],
          atlasOk ? _gray(sh) : _tint(mats[f.mat].color, sh),
          f,
          nx.toDouble(),
          ny.toDouble(),
          nz.toDouble(),
          x + 0.5 + nx * 0.5,
          y + 0.5 + ny * 0.5,
          z + 0.5 + nz * 0.5));
    }
    // şekilli bloklar
    final white = Tex.tile(mats.length * 2);
    for (final e in s.world.shapeAt.entries) {
      final m = s.world.blocks[e.key];
      if (m == null) continue;
      final (x, y, z) = cxyz(e.key);
      if ((x + 0.5 - ox).abs() > reach || (y + 0.5 - oy).abs() > reach) continue;
      for (final sp in shapeWorld(e.value >> 2, e.value & 3, x, y, z)) {
        final top = sp.nz > 0.7;
        final r = sp.color != null ? white : Tex.tile(m * 2 + (top ? 0 : 1));
        final uv = <double>[];
        for (var i = 0; i < sp.uv.length; i += 2) {
          uv
            ..add(r.left + 0.02 + sp.uv[i].clamp(0.0, 1.0) * (r.width - 0.04))
            ..add(r.top + 0.02 + sp.uv[i + 1].clamp(0.0, 1.0) * (r.height - 0.04));
        }
        final sh = shadeFor(sp.nx, sp.ny, sp.nz);
        int col;
        if (sp.color != null) {
          col = _tint(Color(sp.color!), sh);
        } else {
          col = atlasOk ? _gray(sh) : _tint(mats[m].color, sh);
        }
        var cx = 0.0, cy = 0.0, cz = 0.0;
        final n = sp.p.length ~/ 3;
        for (var i = 0; i < sp.p.length; i += 3) {
          cx += sp.p[i];
          cy += sp.p[i + 1];
          cz += sp.p[i + 2];
        }
        final dir = sp.nz > 0.7 ? 0 : (sp.nz < -0.7 ? 5 : (sp.nx.abs() > sp.ny.abs() ? (sp.nx > 0 ? 1 : 2) : (sp.ny > 0 ? 3 : 4)));
        out.add(_Poly(sp.p, uv, col, _Face(e.key, dir, m, 4), sp.nx, sp.ny, sp.nz, cx / n, cy / n, cz / n));
      }
    }
    // hareketli parçalar
    final whiteTile = Tex.tile(mats.length * 2), faceTile = Tex.tile((mats.length + 1) * 2);
    final none = _Face(-1, 0, 0, 1);
    for (final e in s.entityParts(withAvatar: withAvatar)) {
      if ((e.$2 - ox).abs() > reach || (e.$3 - oy).abs() > reach) continue;
      final b = e.$1;
      final c = boxCorners(b, e.$2, e.$3, e.$4, e.$5);
      final hit = e.$6 == 1 || e.$6 == 5 ? none : _Face(e.$7, 0, 0, e.$6);
      for (final f in boxFaces) {
        final p = [for (final i in f.$1) c[i]];
        final ux = p[1].$1 - p[0].$1, uy = p[1].$2 - p[0].$2, uz = p[1].$3 - p[0].$3;
        final vx = p[3].$1 - p[0].$1, vy = p[3].$2 - p[0].$2, vz = p[3].$3 - p[0].$3;
        var nx = -(uy * vz - uz * vy), ny = -(uz * vx - ux * vz), nz = -(ux * vy - uy * vx);
        final len = sqrt(nx * nx + ny * ny + nz * nz) + 1e-9;
        nx /= len;
        ny /= len;
        nz /= len;
        final light = (0.66 + 0.34 * nz.clamp(0.0, 1.0) + 0.14 * (nx * 0.6 + ny * 0.8).clamp(0.0, 1.0)).clamp(0.55, 1.0);
        final col = Color.lerp(Colors.black, b.color, light)!;
        final r = b.face && f.$2 == 3 ? faceTile : whiteTile;
        out.add(_Poly(
            [for (final q in p) ...[q.$1, q.$2, q.$3]],
            [r.left + 0.02, r.top + 0.02, r.right - 0.02, r.top + 0.02, r.right - 0.02, r.bottom - 0.02, r.left + 0.02, r.bottom - 0.02],
            _tint(col, 1),
            hit,
            nx,
            ny,
            nz,
            (p[0].$1 + p[2].$1) / 2,
            (p[0].$2 + p[2].$2) / 2,
            (p[0].$3 + p[2].$3) / 2));
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    s.area = size;
    if (s.firstPerson) {
      _paintFP(canvas, size);
    } else {
      s.cam();
      _sea(canvas);
      final key = '${s.yaw},${s.pitch},${s.zoom},${s.fx},${s.fy},$size,${s.world.version},${Tex.atlas != null},'
          '${s.ax},${s.ay},${s.az},${s.facing},${s.walk},${s.swing},${s.hand},${s.avatar.encode()},${s.gameTools},${s.lifeTick},${s.cropStamp},${s.flying ? s.flyT : 0}';
      if (key != s._geoKey) {
        s._geoKey = key;
        _build(size);
      }
      _drawVerts(canvas);
      _overlay(canvas);
    }
    _nightAndGlow(canvas, size);
    _weatherFx(canvas, size);
    if (s.firstPerson) _fpHud(canvas, size);
  }

  void _drawVerts(Canvas canvas) {
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
  }

  void _clearVerts() {
    for (final v in s._verts) {
      v.dispose();
    }
    s._verts.clear();
  }

  /// Ekran koordinatlı çokgenlerden çizim listesi oluşturur.
  void _emit(List<(List<double>, List<double>, int)> polys) {
    var pos = <double>[], uv = <double>[];
    var col = <int>[];
    var idx = <int>[];
    void flush() {
      if (pos.isEmpty) return;
      s._verts.add(ui.Vertices.raw(ui.VertexMode.triangles, Float32List.fromList(pos),
          textureCoordinates: Float32List.fromList(uv), colors: Int32List.fromList(col), indices: Uint16List.fromList(idx)));
      pos = [];
      uv = [];
      col = [];
      idx = [];
    }

    for (final p in polys) {
      final n = p.$1.length ~/ 2;
      if (pos.length ~/ 2 + n > 60000) flush();
      final base = pos.length ~/ 2;
      pos.addAll(p.$1);
      uv.addAll(p.$2);
      for (var k = 0; k < n; k++) {
        col.add(p.$3);
      }
      for (var k = 1; k < n - 1; k++) {
        idx
          ..add(base)
          ..add(base + k)
          ..add(base + k + 1);
      }
    }
    flush();
  }

  // ================= dışarıdan görünüm =================
  void _build(Size size) {
    _clearVerts();
    final sy = s._sy, cy = s._cy, sp = s._sp, cp = s._cp;
    final reach = max(size.width, size.height / max(0.3, sp)) / s._s * 0.8 + 6;
    final vx = sy * cp, vy = cy * cp, vz = sp;
    final polys = _collect(s.fx, s.fy, reach, withAvatar: true);
    final vis = <int>[];
    final dep = <double>[];
    for (var i = 0; i < polys.length; i++) {
      final p = polys[i];
      if (p.nx * vx + p.ny * vy + p.nz * vz <= 1e-4) continue;
      final c = s.proj(p.cx, p.cy, p.cz);
      if (c.dx < -80 || c.dy < -80 || c.dx > size.width + 80 || c.dy > size.height + 80) continue;
      vis.add(i);
      // hareketli parçalar biraz öne
      dep.add(s.depth(p.cx, p.cy, p.cz) + (p.hit.ent == 0 || p.hit.ent == 4 ? 0 : 0.02));
    }
    final order = List<int>.generate(vis.length, (i) => i)..sort((a, b) => dep[a].compareTo(dep[b]));
    final out = <(List<double>, List<double>, int)>[];
    final hitPolys = <Float32List>[];
    final hitFaces = <_Face>[];
    for (final o in order) {
      final p = polys[vis[o]];
      final scr = Float32List(p.p.length ~/ 3 * 2);
      for (var k = 0; k < p.p.length ~/ 3; k++) {
        final q = s.proj(p.p[k * 3], p.p[k * 3 + 1], p.p[k * 3 + 2]);
        scr[k * 2] = q.dx;
        scr[k * 2 + 1] = q.dy;
      }
      out.add((scr, p.uv, p.color));
      hitPolys.add(scr);
      hitFaces.add(p.hit);
    }
    _emit(out);
    s._hit
      ..faces = hitFaces
      ..polys = hitPolys;
  }

  // ================= birinci şahıs =================
  double _ex = 0, _ey = 0, _ez = 0, _fx = 0, _fy = 1, _fz = 0, _rx = 1, _ry = 0, _ux = 0, _uy = 0, _uz = 1, _foc = 300;
  Offset _c = Offset.zero;

  void _fpCam(Size size) {
    final (ex, ey, ez) = s.camEye();
    _ex = ex;
    _ey = ey;
    _ez = ez;
    final th = s.look, ph = s.lookUp;
    _fx = sin(th) * cos(ph);
    _fy = cos(th) * cos(ph);
    _fz = sin(ph);
    _rx = cos(th);
    _ry = -sin(th);
    _ux = _ry * _fz;
    _uy = -_rx * _fz;
    _uz = _rx * _fy - _ry * _fx;
    _foc = size.height * 0.5 / tan(0.62);
    _c = Offset(size.width / 2, size.height / 2);
  }

  Offset? fpProj(double x, double y, double z) {
    final dx = x - _ex, dy = y - _ey, dz = z - _ez;
    final zc = dx * _fx + dy * _fy + dz * _fz;
    if (zc < 0.06) return null;
    final xc = dx * _rx + dy * _ry;
    final yc = dx * _ux + dy * _uy + dz * _uz;
    return Offset(_c.dx + xc / zc * _foc, _c.dy - yc / zc * _foc);
  }

  void _paintFP(Canvas canvas, Size size) {
    _fpCam(size);
    final key = 'fp,$_ex,$_ey,$_ez,${s.look},${s.lookUp},$size,${s.world.version},${Tex.atlas != null},${s.lifeTick},${s.cropStamp}'
        '${s.behind ? ',${s.walk},${s.swing},${s.hand},${s.facing},${s.avatar.encode()},${s.gameTools},${s.flying ? s.flyT : 0}' : ''}';
    if (key != s._geoKey) {
      s._geoKey = key;
      _buildFP(size);
    }
    _drawVerts(canvas);
  }

  void _buildFP(Size size) {
    _clearVerts();
    const range = 24.0;
    final polys = _collect(_ex, _ey, range, withAvatar: s.behind);
    final vis = <int>[];
    final dist = <double>[];
    for (var i = 0; i < polys.length; i++) {
      final p = polys[i];
      final vx = _ex - p.cx, vy = _ey - p.cy, vz = _ez - p.cz;
      if (p.nx * vx + p.ny * vy + p.nz * vz <= 0) continue;
      if (-(vx * _fx + vy * _fy + vz * _fz) < -1.2) continue;
      vis.add(i);
      dist.add(vx * vx + vy * vy + vz * vz - (p.hit.ent == 0 || p.hit.ent == 4 ? 0 : 0.01));
    }
    final order = List<int>.generate(vis.length, (i) => i)..sort((a, b) => dist[b].compareTo(dist[a]));
    final out = <(List<double>, List<double>, int)>[];
    const near = 0.06;
    for (final o in order) {
      final p = polys[vis[o]];
      final n = p.p.length ~/ 3;
      var poly = <List<double>>[];
      for (var k = 0; k < n; k++) {
        final dx = p.p[k * 3] - _ex, dy = p.p[k * 3 + 1] - _ey, dz = p.p[k * 3 + 2] - _ez;
        poly.add([dx * _rx + dy * _ry, dx * _ux + dy * _uy + dz * _uz, dx * _fx + dy * _fy + dz * _fz, p.uv[k * 2], p.uv[k * 2 + 1]]);
      }
      if (poly.any((q) => q[2] < near)) {
        final cl = <List<double>>[];
        for (var k = 0; k < poly.length; k++) {
          final a = poly[k], b = poly[(k + 1) % poly.length];
          final ain = a[2] >= near, bin = b[2] >= near;
          if (ain) cl.add(a);
          if (ain != bin) {
            final t = (near - a[2]) / (b[2] - a[2]);
            cl.add([for (var j = 0; j < 5; j++) a[j] + (b[j] - a[j]) * t]);
          }
        }
        poly = cl;
        if (poly.length < 3) continue;
      }
      final scr = <double>[], uv = <double>[];
      for (final q in poly) {
        scr
          ..add(_c.dx + q[0] / q[2] * _foc)
          ..add(_c.dy - q[1] / q[2] * _foc);
        uv
          ..add(q[3])
          ..add(q[4]);
      }
      out.add((scr, uv, p.color));
    }
    _emit(out);
  }

  void _fpHud(Canvas canvas, Size size) {
    _labels(canvas, fpProj, s.ax, s.ay);
    // hedeflenen blok çerçevesi
    final a = s.aim;
    if (a != null) {
      final (x, y, z) = cxyz(a);
      final pts = [
        for (final p in const [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0), (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)])
          fpProj(x + p.$1 * 1.0, y + p.$2 * 1.0, z + p.$3 * 1.0)
      ];
      final line = Paint()
        ..color = Colors.black.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      const edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)];
      for (final e in edges) {
        final p1 = pts[e.$1], p2 = pts[e.$2];
        if (p1 != null && p2 != null) canvas.drawLine(p1, p2, line);
      }
    }
    for (final p in s.parts) {
      final o = fpProj(p.x, p.y, p.z);
      if (o == null) continue;
      final d = sqrt(pow(p.x - _ex, 2) + pow(p.y - _ey, 2) + pow(p.z - _ez, 2)) + 0.3;
      _drawParticle(canvas, o, (_foc * 0.09 / d).clamp(2.0, 30.0), p.c.withAlpha((255 * min(1, p.life * 2)).toInt()), p.kind);
    }
    for (final an in s.animals) {
      if (!an.friend) continue;
      final o = fpProj(an.x, an.y, an.z + s._animalHeight(an.kind.id) + 0.35);
      if (o != null) paintNameTag(canvas, o, an.kind.name);
    }
    final ae = s.aimEnt;
    if (ae != null) {
      String label;
      if (ae.$1 == 2 && ae.$2 < s.animals.length) {
        final an = s.animals[ae.$2];
        label = an.friend ? '💛 Sev' : '❓ Adını yaz';
      } else {
        final c = s.cropsAt[ae.$2];
        label = c == null ? '' : (cropStage(c.$2) >= 3 ? '🧺 Topla' : '💧 Sula');
      }
      if (label.isNotEmpty) {
        final tp = TextPainter(
            text: TextSpan(text: label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            textDirection: TextDirection.ltr)
          ..layout();
        final r = Rect.fromCenter(center: _c + const Offset(0, 46), width: tp.width + 16, height: tp.height + 8);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = Colors.black54);
        tp.paint(canvas, Offset(r.left + 8, r.top + 4));
      }
    }
    final cp = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    final shadow = Paint()
      ..color = Colors.black54
      ..strokeWidth = 5;
    for (final pnt in [shadow, cp]) {
      canvas.drawLine(_c - const Offset(11, 0), _c + const Offset(11, 0), pnt);
      canvas.drawLine(_c - const Offset(0, 11), _c + const Offset(0, 11), pnt);
    }
    final bc = s.breakCell;
    if (bc != null && s.world.blocks[bc] != null) {
      final need = s._hitsFor(s.world.blocks[bc]!);
      final f = ((s.hits + s.swing) / need).clamp(0.0, 1.0);
      final r = Rect.fromLTWH(_c.dx - 30, _c.dy + 20, 60, 8);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = Colors.black45);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width * f, r.height), const Radius.circular(4)),
          Paint()..color = Colors.lightGreenAccent);
    }
    final tool = s.hand == null ? '✊' : tools.firstWhere((t) => t.id == s.hand).emoji;
    final sw = s.swing > 0 ? sin(s.swing * pi) : 0.0;
    final bob = sin(s.walk) * 6;
    canvas.save();
    canvas.translate(size.width * 0.58 - sw * 40, size.height - 46 + bob + sw * 10);
    canvas.rotate(-0.4 - sw * 0.9);
    final tp = TextPainter(text: TextSpan(text: tool, style: const TextStyle(fontSize: 64)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  // ================= gece ve ışıklar =================
  void _nightAndGlow(Canvas canvas, Size size) {
    if (!s.night) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x8A0A0F3C));
    final ox = s.firstPerson ? s.ax : s.fx, oy = s.firstPerson ? s.ay : s.fy;
    const reach = 26;
    var n = 0;
    for (final e in s.world.blocks.entries) {
      final id = mats[e.value].id;
      final gc = _glowColors[id];
      if (gc == null) continue;
      final (x, y, z) = cxyz(e.key);
      final b = s.world.blocks;
      if (b.containsKey(ck(x + 1, y, z)) &&
          b.containsKey(ck(x - 1, y, z)) &&
          b.containsKey(ck(x, y + 1, z)) &&
          b.containsKey(ck(x, y - 1, z)) &&
          b.containsKey(ck(x, y, z + 1))) {
        continue;
      }
      if ((x - ox).abs() > reach || (y - oy).abs() > reach) continue;
      Offset? p;
      double r;
      if (s.firstPerson) {
        p = fpProj(x + 0.5, y + 0.5, z + 0.6);
        if (p == null) continue;
        final d = sqrt(pow(x + 0.5 - _ex, 2) + pow(y + 0.5 - _ey, 2) + pow(z + 0.5 - _ez, 2)) + 0.5;
        r = _foc * 2.6 / d;
      } else {
        p = s.proj(x + 0.5, y + 0.5, z + 0.6);
        r = s._s * 2.6;
      }
      canvas.drawCircle(
          p,
          r,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.radial(p, r, [gc.withAlpha(150), gc.withAlpha(0)]));
      if (++n > 160) break;
    }
  }

  void _labels(Canvas canvas, Offset? Function(double, double, double) pr, double ox, double oy) {
    final tb = matIndex('tabela');
    for (final e in s.world.places.entries) {
      final (x, y) = e.value;
      final dd = sqrt(pow(x - ox, 2) + pow(y - oy, 2));
      if (dd > (s.firstPerson ? 48 : 24)) continue;
      final o = pr(x + 0.5, y + 0.5, s.world.topZ(x, y) + 5.5);
      if (o != null) paintPlace(canvas, o, e.key, scale: dd < 20 ? 1 : 0.8);
    }
    if (!s.firstPerson || s.behind) {
      final a = s.avatar.armor;
      if (a > 0 && a <= armors.length) {
        final o = pr(s.ax, s.ay, s.az + 2.35);
        if (o != null) paintNameTag(canvas, o, armors[a - 1].hero);
      }
    }
    for (final v in s.npcs) {
      if ((v.x - ox).abs() > 10 || (v.y - oy).abs() > 10) continue;
      final o = pr(v.x, v.y, v.z + 2.2);
      if (o != null) paintNameTag(canvas, o, v.name);
    }
    for (final f in s.friends) {
      if ((f.x - ox).abs() > 20 || (f.y - oy).abs() > 20) continue;
      final o = pr(f.x, f.y, f.z + 2.25);
      if (o != null) paintNameTag(canvas, o, f.name);
    }
    for (final e in s.signs.entries) {
      if (s.world.blocks[e.key] != tb) continue;
      final (x, y, z) = cxyz(e.key);
      if ((x - ox).abs() > 14 || (y - oy).abs() > 14) continue;
      final o = pr(x + 0.5, y + 0.5, z + 1.45);
      if (o != null) paintSign(canvas, o, e.value);
    }
    for (final f in s.floats) {
      final o = pr(f.x, f.y, f.z);
      if (o == null) continue;
      final a = (255 * min(1.0, f.life)).toInt();
      final tp = TextPainter(
          text: TextSpan(
              text: f.text,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(a, 255, 255, 255),
                  shadows: [Shadow(color: Color.fromARGB(a, 74, 20, 140), blurRadius: 4, offset: const Offset(1, 1))])),
          textDirection: TextDirection.ltr)
        ..layout();
      final r = Rect.fromCenter(center: o, width: tp.width + 14, height: tp.height + 6);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)), Paint()..color = Color.fromARGB((a * 0.85).toInt(), 149, 117, 205));
      tp.paint(canvas, Offset(o.dx - tp.width / 2, o.dy - tp.height / 2));
    }
  }

  void _weatherFx(Canvas canvas, Size size) {
    if (s.weather.isEmpty) return;
    final t = s.wTime;
    final r = Random(3);
    if (s.weather == 'yagmur') {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x28304060));
      final p = Paint()
        ..color = const Color(0xAAB3E5FC)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 90; i++) {
        final x = r.nextDouble() * size.width, sp = 520 + r.nextDouble() * 300, ph = r.nextDouble();
        final y = (ph * size.height + t * sp) % (size.height + 40) - 20;
        canvas.drawLine(Offset(x, y), Offset(x - 4, y + 16), p);
      }
    } else {
      final p = Paint()..color = const Color(0xE6FFFFFF);
      for (var i = 0; i < 80; i++) {
        final x0 = r.nextDouble() * size.width, sp = 35 + r.nextDouble() * 45, ph = r.nextDouble(), rad = 2 + r.nextDouble() * 2.5;
        final y = (ph * size.height + t * sp) % (size.height + 20) - 10;
        final x = x0 + sin(t * 1.3 + ph * 9) * 12;
        canvas.drawCircle(Offset(x, y), rad, p);
      }
    }
  }

  void _overlay(Canvas canvas) {
    final t = anim.value;
    _labels(canvas, (x, y, z) => s.proj(x, y, z), s.fx, s.fy);
    for (final a in s.animals) {
      if (!a.friend) continue;
      paintNameTag(canvas, s.proj(a.x, a.y, a.z + s._animalHeight(a.kind.id) + 0.4), a.kind.name);
    }
    for (final p in s.parts) {
      final o = s.proj(p.x, p.y, p.z);
      final r = s._s * (p.kind == 0 ? 0.09 : 0.13);
      _drawParticle(canvas, o, r, p.c.withAlpha((255 * min(1, p.life * 2)).toInt()), p.kind);
    }
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
      case 4:
        return [x + 1, y, z + 1, x, y, z + 1, x, y, z, x + 1, y, z];
      default:
        return [x, y + 1, z, x + 1, y + 1, z, x + 1, y, z, x, y, z];
    }
  }

  void _sea(Canvas canvas) {
    const m = 4.0;
    final x0 = minX.toDouble(), x1 = maxX + 1.0, y0 = minY.toDouble(), y1 = maxY + 1.0;
    final a = s.proj(x0 - m, y0 - m, 0), b = s.proj(x1 + m, y0 - m, 0), c = s.proj(x1 + m, y1 + m, 0), d = s.proj(x0 - m, y1 + m, 0);
    canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy)
          ..lineTo(d.dx, d.dy)
          ..close(),
        Paint()..color = const Color(0xFF29B6F6));
    const e = 0.5;
    final a2 = s.proj(x0 - e, y0 - e, 0), b2 = s.proj(x1 + e, y0 - e, 0), c2 = s.proj(x1 + e, y1 + e, 0), d2 = s.proj(x0 - e, y1 + e, 0);
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
                SizedBox(width: 70, height: 70, child: MatSwatch(mats[matIndex(id)])),
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

class MatSwatch extends StatelessWidget {
  final BlockMat m;
  const MatSwatch(this.m);

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
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => oldDelegate.night != night;
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
      Tex.load(texIds).then((_) {
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

class _Particle {
  double x, y, z, vx, vy, vz, life;
  final Color c;
  final int kind; // 0 kare, 1 yıldız (elmas), 2 daire
  final double g; // yerçekimi
  _Particle(this.x, this.y, this.z, this.vx, this.vy, this.vz, this.c, this.life, {this.kind = 0, this.g = 9});
}

void _drawParticle(Canvas canvas, Offset o, double r, Color c, int kind) {
  final paint = Paint()..color = c;
  switch (kind) {
    case 1:
      final path = Path()
        ..moveTo(o.dx, o.dy - r)
        ..lineTo(o.dx + r * 0.38, o.dy - r * 0.38)
        ..lineTo(o.dx + r, o.dy)
        ..lineTo(o.dx + r * 0.38, o.dy + r * 0.38)
        ..lineTo(o.dx, o.dy + r)
        ..lineTo(o.dx - r * 0.38, o.dy + r * 0.38)
        ..lineTo(o.dx - r, o.dy)
        ..lineTo(o.dx - r * 0.38, o.dy - r * 0.38)
        ..close();
      canvas.drawPath(path, paint);
    case 2:
      canvas.drawCircle(o, r * 0.6, paint);
      canvas.drawCircle(o.translate(-r * 0.2, -r * 0.2), r * 0.18, Paint()..color = Colors.white.withAlpha((c.a * 255).round()));
    default:
      canvas.drawRect(Rect.fromCenter(center: o, width: r, height: r), paint);
  }
}

class _ToolDialog extends StatelessWidget {
  final Tool t;
  const _ToolDialog(this.t);

  @override
  Widget build(BuildContext context) {
    Voice.say('Sandıktan ${t.name} çıktı! ${t.id == 'kalkan' ? 'Kalkanı sol koluna taktın.' : 'Şimdi Kır düğmesine bas, bloklara dokun.'}');
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉 Hazine!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(t.emoji, style: const TextStyle(fontSize: 80)),
          SylText(t.name, size: 34),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Harika!', style: TextStyle(fontSize: 20))),
        ]),
      ),
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  final int view; // 0 dışarıdan, 1 içeriden, 2 arkadan
  final VoidCallback onTap;
  const _ViewSwitch(this.view, this.onTap);

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const [Color(0xFFFFB300), Color(0xFF26A69A), Color(0xFF7E57C2)][view],
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: Column(children: [
            // bir sonraki görünümü gösterir
            Text(const ['👁️', '🧍', '🎥'][view], style: const TextStyle(fontSize: 22)),
            Text(const ['İçeriden', 'Arkadan', 'Dışarıdan'][view],
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
          ]),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback down;
  final VoidCallback? up;
  final bool big;
  const _ActionBtn(this.emoji, this.label, this.color, {required this.down, this.up, this.big = false});

  @override
  Widget build(BuildContext context) {
    final sz = big ? 84.0 : 66.0;
    return Listener(
      onPointerDown: (_) => down(),
      onPointerUp: (_) => up?.call(),
      onPointerCancel: (_) => up?.call(),
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          color: color.withAlpha(225),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: TextStyle(fontSize: big ? 30 : 22)),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _Job {
  final String name;
  final List<(int, int)> cells;
  Friend? friend; // yapan arkadaş (yoksa iki işçi)
  int i = 0;
  double t = 0, anim = 0, finished = 0;
  final List<double> wx, wy, wz, wf;
  _Job(this.name, this.cells, double x, double y, double z)
      : wx = [x - 3, x + 3],
        wy = [y - 3, y - 3],
        wz = [z, z],
        wf = [0, 0];
}

class _Float {
  double x, y, z;
  final String text;
  double life;
  _Float(this.x, this.y, this.z, this.text, this.life);
}
