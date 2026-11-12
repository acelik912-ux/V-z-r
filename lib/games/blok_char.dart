import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import 'blok_bag.dart';
import 'blok_life.dart';

// ======================= KARAKTER =======================

const skinColors = [Color(0xFFFFDBB5), Color(0xFFF1C27D), Color(0xFFC68642), Color(0xFF8D5524)];
const hairColors = [Color(0xFF3B2314), Color(0xFF111111), Color(0xFFB5651D), Color(0xFFE6BE8A), Color(0xFF9E9E9E)];
const clothColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF37474F),
  Color(0xFFFFFFFF),
];
const hatColors = [Color(0xFFFFC107), Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF6D4C41), Color(0xFFFFFFFF)];
const hairStyles = ['Kısa saç', 'Uzun saç', 'Kask', 'Şapka', 'Takke'];
const bearStyles = ['Başlıksız', 'Kask', 'Şapka', 'Takke'];

/// Ayı tüy renkleri
const furColors = [
  Color(0xFF8D5A3B), // kahverengi
  Color(0xFF2B2B2B), // siyah
  Color(0xFF8E44AD), // mor
  Color(0xFFF2F2F2), // beyaz (kutup)
  Color(0xFFE0A030), // altın
  Color(0xFF8C8C8C), // gri
  Color(0xFFF06292), // pembe
  Color(0xFF3F7FD0), // mavi
];
const furNames = ['kahverengi', 'siyah', 'mor', 'beyaz', 'altın', 'gri', 'pembe', 'mavi'];

/// Yürürken ayaklardan ve ellerden çıkan renkli izler: (kimlik, heceler, emoji)
const trails = [
  ('gokkusagi', ['gök', 'ku', 'şa', 'ğı'], '🌈'),
  ('yildiz', ['yıl', 'dız'], '⭐'),
  ('ates', ['a', 'teş'], '🔥'),
  ('kalp', ['k', 'a', 'l', 'p'], '💖'),
  ('kopuk', ['kö', 'pük'], '🫧'),
];

bool trailOwned(String id) => game.blockItems.contains('iz_$id');

/// Zırhlar (pazardan para ile alınır)
class Armor {
  final String id;
  final String name;
  final Color color;
  final Color trim;
  final int price;
  final Color cape; // pelerin
  final Color gem; // göğüsteki ve miğferdeki taş
  final Color? plume; // miğfer sorgucu
  final bool horns; // miğferde boynuz/kanat
  final int helm; // 0 şövalye miğferi, 1 sivri miğfer + zincir, 2 sarıklı miğfer, 3 yeniçeri börkü
  final String? pic; // pazardaki resim
  final String? info; // tarihî zırhlar için kısa bilgi
  final String hero; // giyince dönüşülen kahraman
  final String heroTo; // "… dönüştün" için yönelme hâli
  final String heroLine; // dönüşünce söylenen kısa söz
  const Armor(this.id, this.name, this.color, this.trim, this.price,
      {required this.cape,
      required this.gem,
      required this.hero,
      required this.heroTo,
      required this.heroLine,
      this.plume,
      this.horns = false,
      this.helm = 0,
      this.pic,
      this.info});

  /// "Şimdi Sultan Alparslan'a dönüştün! …"
  String get transform => 'Şimdi $heroTo dönüştün! $heroLine';
}

const armors = [
  Armor('deri', 'deri zırh', Color(0xFF8D6E63), Color(0xFF5D4037), 5,
      hero: 'Battal Gazi', heroTo: 'Battal Gazi\'ye', heroLine: 'Kahramanlık destanlarının yiğidi Battal Gazi oldun!',
      cape: Color(0xFF4E342E), gem: Color(0xFFFFB300), pic: 'zirh_deri'),
  Armor('demir', 'demir zırh', Color(0xFFB0BEC5), Color(0xFF607D8B), 10,
      hero: 'Ertuğrul Gazi', heroTo: 'Ertuğrul Gazi\'ye', heroLine: 'Obasını koruyan cesur Ertuğrul Gazi oldun!',
      cape: Color(0xFF1565C0), gem: Color(0xFF90CAF9), plume: Color(0xFFD32F2F), pic: 'zirh_demir'),
  Armor('altin', 'altın zırh', Color(0xFFFFC107), Color(0xFFFF8F00), 20,
      hero: 'Kanuni Sultan Süleyman', heroTo: 'Kanuni Sultan Süleyman\'a', heroLine: 'Adaletiyle bilinen büyük sultan oldun!',
      cape: Color(0xFFC62828), gem: Color(0xFFE53935), plume: Color(0xFFFFFFFF), pic: 'zirh_altin'),
  Armor('elmas', 'elmas zırh', Color(0xFF4DD0E1), Color(0xFF00838F), 35,
      hero: 'Yavuz Sultan Selim', heroTo: 'Yavuz Sultan Selim\'e', heroLine: 'Yıldırım gibi hızlı, cesur sultan oldun!',
      cape: Color(0xFF6A1B9A), gem: Color(0xFFE0F7FA), plume: Color(0xFFFFD54F), horns: true, pic: 'zirh_elmas'),
  Armor('zumrut', 'zümrüt zırh', Color(0xFF00C853), Color(0xFF1B5E20), 50,
      hero: 'Abdülhamid Han', heroTo: 'Abdülhamid Han\'a', heroLine: 'Okullar, hastaneler, demiryolları yaptıran Abdülhamid Han oldun!',
      cape: Color(0xFFFFD54F), gem: Color(0xFFB2FF59), plume: Color(0xFFFFD54F), horns: true, pic: 'zirh_zumrut'),
  // tarihî zırhlar (Müslüman devletler)
  Armor('selcuklu', 'Selçuklu zırhı', Color(0xFF26A69A), Color(0xFFFFB300), 25,
      hero: 'Sultan Alparslan', heroTo: 'Sultan Alparslan\'a', heroLine: 'Malazgirt zaferiyle Anadolu\'nun kapısını açan sultan oldun!',
      cape: Color(0xFF0D47A1), gem: Color(0xFFFFD54F), pic: 'zirh_selcuklu', helm: 1,
      info: 'Selçuklu süvarileri sivri miğfer ve küçük pullardan yapılmış zırh giyerdi. Anadolu kapısını açan Malazgirt zaferi onlarındı.'),
  Armor('osmanli', 'Osmanlı sipahi zırhı', Color(0xFFC62828), Color(0xFFFFC107), 30,
      hero: 'Osman Gazi', heroTo: 'Osman Gazi\'ye', heroLine: 'Osmanlı Devleti\'ni kuran adil bey oldun!',
      cape: Color(0xFF7F0000), gem: Color(0xFF00E676), plume: Color(0xFFFFFFFF), pic: 'zirh_osmanli', helm: 2,
      info: 'Sipahiler Osmanlının atlı askerleriydi. Sarıklı miğfer, zincir zırh ve kırmızı kaftan giyerlerdi.'),
  Armor('yeniceri', 'Yeniçeri zırhı', Color(0xFF1565C0), Color(0xFFFFC107), 30,
      hero: 'Fatih Sultan Mehmet', heroTo: 'Fatih Sultan Mehmet\'e', heroLine: 'İstanbul\'u fetheden genç sultan oldun!',
      cape: Color(0xFFFAFAFA), gem: Color(0xFFE53935), pic: 'zirh_yeniceri', helm: 3,
      info: 'Yeniçeriler başlarına arkası sarkan beyaz börk takardı. Mehter marşıyla yürürlerdi.'),
  Armor('memluk', 'Memlük zırhı', Color(0xFFB87333), Color(0xFF5D4037), 40,
      hero: 'Sultan Baybars', heroTo: 'Sultan Baybars\'a', heroLine: 'Şam\'ı ve Mısır\'ı koruyan yiğit sultan oldun!',
      cape: Color(0xFFFDD835), gem: Color(0xFF29B6F6), plume: Color(0xFFFFFFFF), pic: 'zirh_memluk', helm: 2,
      info: 'Memlükler Mısır ve Şam\'ı korudu. Altın sarısı sancakları ve bakır renkli zırhlarıyla tanınırlardı.'),
  Armor('endulus', 'Endülüs zırhı', Color(0xFFF5F5F5), Color(0xFFD4AF37), 45,
      hero: 'Tarık bin Ziyad', heroTo: 'Tarık bin Ziyad\'a', heroLine: 'Endülüs\'e ilk adımı atan cesur komutan oldun!',
      cape: Color(0xFF00695C), gem: Color(0xFFE53935), pic: 'zirh_endulus', helm: 1,
      info: 'Endülüs Müslümanları İspanya\'da yüzyıllarca yaşadı. Beyaz-altın zırhları ve güzel saraylarıyla ünlüydüler.'),
];

/// Miğfer biçimine göre baş parçaları. [top] başın üstü, [w] genişlik çarpanı.
List<ABox> helmBoxes(Armor ar, double top, {double w = 1, double front = 0.25}) {
  const white = Color(0xFFFAFAFA), chain = Color(0xFF9E9E9E);
  switch (ar.helm) {
    case 1: // sivri miğfer, burun siperi, zincir perde
      return [
        ABox(0, 0, top - 0.02, 0.27 * w, 0.27 * w, 0.045, ar.color),
        ABox(0, 0, top + 0.06, 0.2 * w, 0.2 * w, 0.04, ar.color),
        ABox(0, 0, top + 0.13, 0.13 * w, 0.13 * w, 0.035, ar.color),
        ABox(0, 0, top + 0.19, 0.07, 0.07, 0.035, ar.trim),
        ABox(0, 0, top + 0.26, 0.025, 0.025, 0.05, ar.trim),
        ABox(0, 0, top + 0.02, 0.275 * w, 0.275 * w, 0.015, ar.trim),
        ABox(0, front + 0.005, top - 0.2, 0.03, 0.01, 0.13, ar.trim),
        ABox(0, -front + 0.01, top - 0.32, 0.26 * w, 0.02, 0.2, chain),
        ABox(-0.255 * w, 0, top - 0.3, 0.015, 0.22, 0.16, chain),
        ABox(0.255 * w, 0, top - 0.3, 0.015, 0.22, 0.16, chain),
      ];
    case 2: // sarıklı miğfer
      return [
        ABox(0, 0, top - 0.02, 0.28 * w, 0.28 * w, 0.06, white),
        ABox(0, 0, top + 0.08, 0.24 * w, 0.24 * w, 0.05, white),
        ABox(0, 0.005, top + 0.03, 0.285 * w, 0.27 * w, 0.012, const Color(0xFFE0E0E0)),
        ABox(0, 0, top + 0.15, 0.17 * w, 0.17 * w, 0.04, ar.color),
        ABox(0, 0, top + 0.22, 0.05, 0.05, 0.05, ar.trim),
        ABox(0, front + 0.035, top + 0.04, 0.045, 0.012, 0.045, ar.gem),
        ABox(0, -front + 0.01, top - 0.3, 0.24 * w, 0.02, 0.18, chain),
      ];
    case 3: // yeniçeri börkü
      return [
        ABox(0, 0, top + 0.0, 0.25 * w, 0.25 * w, 0.06, ar.trim),
        ABox(0, -0.02, top + 0.16, 0.22 * w, 0.21 * w, 0.12, white),
        ABox(0, -0.05, top + 0.31, 0.2 * w, 0.18 * w, 0.05, white),
        ABox(0, -front - 0.01, top - 0.18, 0.2 * w, 0.02, 0.3, white),
        ABox(0, front - 0.02, top + 0.16, 0.05, 0.012, 0.1, ar.trim),
        ABox(0, front - 0.01, top + 0.1, 0.03, 0.012, 0.03, ar.gem),
      ];
    default:
      return const [];
  }
}

/// Görkemli zırh parçaları (pelerin, omuzluk, sorguç, taş, kemer). Ölçüler insan için;
/// [k] ayı için büyütme, [dz] yükseklik kayması.
List<ABox> armorExtras(Armor ar, {required double armL, required double armR, required double leg,
    double headTop = 1.88, double chestZ = 1.12, double chestY = 0.165, double shoulderX = 0.36, double shoulderZ = 1.38,
    double pivot = 1.39, double backY = -0.17, double capeZ = 1.0, double capeH = 0.36, double w = 1}) {
  final capeA = -0.12 - leg.abs() * 0.35;
  final out = <ABox>[
    // pelerin (arkada, yürürken dalgalanır)
    ABox(0, backY - 0.035, capeZ, 0.25 * w, 0.02, capeH, ar.cape, pivotZ: capeZ + capeH, angle: capeA),
    ABox(0, backY - 0.03, capeZ + capeH - 0.04, 0.27 * w, 0.03, 0.05, ar.trim),
    // büyük omuzluklar (iki kat)
    ABox(-shoulderX - 0.02, 0, shoulderZ, 0.17, 0.16, 0.08, ar.color, pivotZ: pivot, angle: armL),
    ABox(shoulderX + 0.02, 0, shoulderZ, 0.17, 0.16, 0.08, ar.color, pivotZ: pivot, angle: armR),
    ABox(-shoulderX - 0.02, 0, shoulderZ + 0.08, 0.13, 0.13, 0.03, ar.trim, pivotZ: pivot, angle: armL),
    ABox(shoulderX + 0.02, 0, shoulderZ + 0.08, 0.13, 0.13, 0.03, ar.trim, pivotZ: pivot, angle: armR),
    // göğüs taşı ve kemer
    ABox(0, chestY + 0.012, chestZ + 0.04, 0.065, 0.012, 0.065, ar.gem),
    ABox(0, chestY + 0.02, chestZ + 0.04, 0.03, 0.01, 0.03, const Color(0xFFFFFFFF)),
    ABox(0, 0, chestZ - 0.3, 0.29 * w, chestY + 0.01, 0.035, ar.trim),
    ABox(0, chestY + 0.02, chestZ - 0.3, 0.05, 0.012, 0.045, ar.gem),
  ];
  if (ar.helm == 0) out.add(ABox(0, 0.245, headTop - 0.1, 0.05, 0.012, 0.04, ar.gem));
  final pl = ar.plume;
  if (pl != null && ar.helm == 0) {
    out.add(ABox(0, -0.02, headTop + 0.1, 0.045, 0.2, 0.09, pl));
    out.add(ABox(0, -0.2, headTop + 0.03, 0.045, 0.06, 0.12, pl));
  }
  if (pl != null && ar.helm == 2) {
    // sorguç: sarığın önünde dik tüy
    out.add(ABox(0, 0.17, headTop + 0.27, 0.03, 0.035, 0.13, pl));
    out.add(ABox(0, 0.13, headTop + 0.4, 0.025, 0.05, 0.05, pl));
  }
  if (ar.horns && ar.helm == 0) {
    out.add(ABox(-0.29, 0.02, headTop + 0.02, 0.04, 0.04, 0.1, ar.trim));
    out.add(ABox(0.29, 0.02, headTop + 0.02, 0.04, 0.04, 0.1, ar.trim));
    out.add(ABox(-0.33, 0.02, headTop + 0.14, 0.03, 0.03, 0.06, ar.gem));
    out.add(ABox(0.33, 0.02, headTop + 0.14, 0.03, 0.03, 0.06, ar.gem));
  }
  return out;
}

class Avatar {
  int skin, hair, style, shirt, pants, hat;
  bool bear;
  int fur;
  int armor; // 0 yok, 1.. armors[armor-1]
  Avatar(
      {this.skin = 0,
      this.hair = 0,
      this.style = 0,
      this.shirt = 0,
      this.pants = 6,
      this.hat = 0,
      this.bear = false,
      this.fur = 0,
      this.armor = 0});

  String encode() => '$skin,$hair,$style,$shirt,$pants,$hat,${bear ? 1 : 0},$fur,$armor';

  static Avatar? decode(String s) {
    final p = s.split(',').map(int.tryParse).toList();
    if ((p.length != 6 && p.length != 8 && p.length != 9) || p.any((e) => e == null)) return null;
    return Avatar(
        skin: p[0]!,
        hair: p[1]!,
        style: p[2]!,
        shirt: p[3]!,
        pants: p[4]!,
        hat: p[5]!,
        bear: p.length >= 8 && p[6] == 1,
        fur: p.length >= 8 ? p[7]! : 0,
        armor: p.length >= 9 ? p[8]! : 0);
  }

  Avatar copy() => Avatar(skin: skin, hair: hair, style: style, shirt: shirt, pants: pants, hat: hat, bear: bear, fur: fur, armor: armor);
}

/// Hazır karakterler
final presets = <(String, Avatar)>[
  ('Sürücü', Avatar(skin: 0, hair: 0, style: 0, shirt: 0, pants: 0)),
  ('Mimar', Avatar(skin: 1, hair: 1, style: 2, shirt: 4, pants: 1, hat: 0)),
  ('Bahçıvan', Avatar(skin: 2, hair: 0, style: 3, shirt: 2, pants: 6, hat: 3)),
  ('Kâşif', Avatar(skin: 1, hair: 2, style: 3, shirt: 3, pants: 6, hat: 3)),
  ('Hafız', Avatar(skin: 0, hair: 1, style: 4, shirt: 7, pants: 7, hat: 4)),
  ('Usta', Avatar(skin: 3, hair: 4, style: 1, shirt: 1, pants: 6)),
  ('Kahverengi Ayı', Avatar(bear: true, fur: 0, style: 0, shirt: 0)),
  ('Siyah Ayı', Avatar(bear: true, fur: 1, style: 1, shirt: 3, hat: 1)),
  ('Mor Ayı', Avatar(bear: true, fur: 2, style: 2, shirt: 3, hat: 0)),
  ('Kutup Ayısı', Avatar(bear: true, fur: 3, style: 0, shirt: 1)),
  ('Altın Ayı', Avatar(bear: true, fur: 4, style: 3, shirt: 2, hat: 4)),
];

Avatar get myAvatar => Avatar.decode(game.avatar) ?? presets[0].$2.copy();

/// Aletler (hazine sandıklarından sırayla çıkar)
class Tool {
  final String id;
  final String name;
  final String emoji;
  const Tool(this.id, this.name, this.emoji);
}

const tools = [
  Tool('kazma', 'kazma', '⛏️'),
  Tool('balta', 'balta', '🪓'),
  Tool('kurek', 'kürek', '🪏'),
  Tool('kilic', 'kılıç', '🗡️'),
  Tool('kalkan', 'kalkan', '🛡️'),
  Tool('mizrak', 'mızrak', '🔱'),
];

/// Karakterin bir parçası (yerel koordinat: x sağ, y ileri, z yukarı; ayaklar z=0)
class ABox {
  final double cx, cy, cz, hx, hy, hz;
  final Color color;
  final double pivotZ; // dönme ekseni yüksekliği (x eksenine paralel)
  final double angle; // ileri doğru salınım
  final bool face; // ön yüzü suratlı
  const ABox(this.cx, this.cy, this.cz, this.hx, this.hy, this.hz, this.color, {this.pivotZ = 0, this.angle = 0, this.face = false});
}

/// Ayı karakter
List<ABox> bearBoxes(Avatar a, {double walk = 0, double swing = 0, String? tool, bool shield = false}) {
  final fur = furColors[a.fur % furColors.length];
  final light = a.fur == 1 ? const Color(0xFF8A8A8A) : Color.lerp(fur, Colors.white, a.fur == 3 ? 0.0 : 0.45)!;
  final dark = Color.lerp(fur, Colors.black, 0.6)!;
  final scarf = clothColors[a.shirt % clothColors.length];
  final hat = hatColors[a.hat % hatColors.length];
  final leg = sin(walk) * 0.55;
  final armR = swing > 0 ? -1.9 * sin(swing * pi) : -leg;
  final armL = leg;
  final out = <ABox>[
    ABox(-0.15, 0, 0.22, 0.13, 0.14, 0.22, fur, pivotZ: 0.44, angle: leg),
    ABox(0.15, 0, 0.22, 0.13, 0.14, 0.22, fur, pivotZ: 0.44, angle: -leg),
    ABox(-0.15, 0.03, 0.03, 0.125, 0.15, 0.03, light, pivotZ: 0.44, angle: leg),
    ABox(0.15, 0.03, 0.03, 0.125, 0.15, 0.03, light, pivotZ: 0.44, angle: -leg),
    ABox(0, 0, 0.76, 0.3, 0.22, 0.33, fur),
    ABox(0, 0.225, 0.72, 0.18, 0.012, 0.22, light),
    ABox(0, 0, 1.1, 0.27, 0.21, 0.05, scarf),
    ABox(-0.38, 0, 0.84, 0.1, 0.11, 0.25, fur, pivotZ: 1.05, angle: armL),
    ABox(0.38, 0, 0.84, 0.1, 0.11, 0.25, fur, pivotZ: 1.05, angle: armR),
    ABox(-0.38, 0, 0.56, 0.095, 0.1, 0.05, light, pivotZ: 1.05, angle: armL),
    ABox(0.38, 0, 0.56, 0.095, 0.1, 0.05, light, pivotZ: 1.05, angle: armR),
    ABox(0, 0.02, 1.38, 0.26, 0.24, 0.24, fur, face: true),
    ABox(0, 0.275, 1.29, 0.12, 0.05, 0.08, light),
    ABox(0, 0.33, 1.33, 0.05, 0.015, 0.035, dark),
    ABox(-0.2, 0, 1.66, 0.075, 0.05, 0.075, fur),
    ABox(0.2, 0, 1.66, 0.075, 0.05, 0.075, fur),
    ABox(-0.2, 0.052, 1.66, 0.04, 0.008, 0.04, light),
    ABox(0.2, 0.052, 1.66, 0.04, 0.008, 0.04, light),
  ];
  switch (a.style) {
    case 1: // kask
      out.add(ABox(0, 0.01, 1.63, 0.28, 0.26, 0.07, hat));
      out.add(ABox(0, 0.22, 1.58, 0.28, 0.08, 0.02, hat));
    case 2: // şapka
      out.add(ABox(0, 0.02, 1.63, 0.36, 0.34, 0.02, hat));
      out.add(ABox(0, 0.02, 1.73, 0.2, 0.2, 0.09, hat));
    case 3: // takke
      out.add(ABox(0, 0.02, 1.645, 0.22, 0.22, 0.04, hat));
  }
  if (a.armor > 0 && a.armor <= armors.length) {
    final ar = armors[a.armor - 1];
    out.removeWhere((b) => b.cz > 1.6 && b.color == hat);
    out.addAll([
      if (ar.helm == 0) ABox(0, 0.01, 1.6, 0.27, 0.25, 0.06, ar.color) else ...helmBoxes(ar, 1.64, w: 1.05, front: 0.27),
      ABox(0, 0, 0.8, 0.31, 0.23, 0.26, ar.color),
      ABox(0, 0.235, 0.8, 0.14, 0.01, 0.18, ar.trim),
      ABox(-0.38, 0, 1.0, 0.115, 0.125, 0.08, ar.trim, pivotZ: 1.05, angle: armL),
      ABox(0.38, 0, 1.0, 0.115, 0.125, 0.08, ar.trim, pivotZ: 1.05, angle: armR),
      ABox(-0.15, 0.02, 0.06, 0.135, 0.16, 0.06, ar.trim, pivotZ: 0.44, angle: leg),
      ABox(0.15, 0.02, 0.06, 0.135, 0.16, 0.06, ar.trim, pivotZ: 0.44, angle: -leg),
      ...armorExtras(ar,
          armL: armL,
          armR: armR,
          leg: leg,
          headTop: 1.66,
          chestZ: 0.86,
          chestY: 0.235,
          shoulderX: 0.38,
          shoulderZ: 1.1,
          pivot: 1.05,
          backY: -0.24,
          capeZ: 0.7,
          capeH: 0.32,
          w: 1.2),
    ]);
  }
  if (tool != null) out.addAll(_toolBoxes(tool, armR, hx: 0.38, hz: 0.56, pz: 1.05));
  if (shield) {
    out.add(ABox(-0.5, 0.02, 0.82, 0.03, 0.22, 0.26, const Color(0xFF1565C0), pivotZ: 1.05, angle: armL));
    out.add(ABox(-0.535, 0.02, 0.82, 0.012, 0.08, 0.1, const Color(0xFFFFC107), pivotZ: 1.05, angle: armL));
  }
  return out;
}

/// Yürüme fazı [walk] (radyan), [swing] 0..1 alet vuruşu, [tool] elde tutulan alet.
List<ABox> avatarBoxes(Avatar a, {double walk = 0, double swing = 0, String? tool, bool shield = false}) {
  if (a.bear) return bearBoxes(a, walk: walk, swing: swing, tool: tool, shield: shield);
  final skin = skinColors[a.skin % skinColors.length];
  final hair = hairColors[a.hair % hairColors.length];
  final shirt = clothColors[a.shirt % clothColors.length];
  final pants = clothColors[a.pants % clothColors.length];
  final hat = hatColors[a.hat % hatColors.length];
  final leg = sin(walk) * 0.6;
  final armR = swing > 0 ? -1.9 * sin(swing * pi) : -leg;
  final armL = leg;
  final out = <ABox>[
    ABox(-0.13, 0, 0.375, 0.11, 0.12, 0.375, pants, pivotZ: 0.75, angle: leg),
    ABox(0.13, 0, 0.375, 0.11, 0.12, 0.375, pants, pivotZ: 0.75, angle: -leg),
    ABox(-0.13, 0.02, 0.05, 0.115, 0.15, 0.05, const Color(0xFF3E2723), pivotZ: 0.75, angle: leg),
    ABox(0.13, 0.02, 0.05, 0.115, 0.15, 0.05, const Color(0xFF3E2723), pivotZ: 0.75, angle: -leg),
    ABox(0, 0, 1.08, 0.25, 0.14, 0.33, shirt),
    ABox(-0.36, 0, 1.1, 0.1, 0.1, 0.29, shirt, pivotZ: 1.39, angle: armL),
    ABox(0.36, 0, 1.1, 0.1, 0.1, 0.29, shirt, pivotZ: 1.39, angle: armR),
    ABox(-0.36, 0, 0.76, 0.09, 0.09, 0.06, skin, pivotZ: 1.39, angle: armL),
    ABox(0.36, 0, 0.76, 0.09, 0.09, 0.06, skin, pivotZ: 1.39, angle: armR),
    ABox(0, 0, 1.65, 0.23, 0.23, 0.23, skin, face: true),
  ];
  switch (a.style) {
    case 0:
      out.add(ABox(0, -0.01, 1.86, 0.245, 0.245, 0.04, hair));
      out.add(ABox(0, -0.2, 1.7, 0.245, 0.05, 0.17, hair));
    case 1:
      out.add(ABox(0, -0.01, 1.86, 0.245, 0.245, 0.04, hair));
      out.add(ABox(0, -0.2, 1.55, 0.245, 0.05, 0.3, hair));
      out.add(ABox(-0.235, -0.05, 1.62, 0.03, 0.2, 0.22, hair));
      out.add(ABox(0.235, -0.05, 1.62, 0.03, 0.2, 0.22, hair));
    case 2: // kask
      out.add(ABox(0, -0.01, 1.84, 0.27, 0.27, 0.09, hat));
      out.add(ABox(0, 0.2, 1.79, 0.27, 0.1, 0.025, hat));
    case 3: // şapka
      out.add(ABox(0, 0, 1.79, 0.33, 0.33, 0.025, hat));
      out.add(ABox(0, 0, 1.9, 0.2, 0.2, 0.1, hat));
    default: // takke
      out.add(ABox(0, 0, 1.87, 0.24, 0.24, 0.05, hat));
  }
  if (a.armor > 0 && a.armor <= armors.length) {
    final ar = armors[a.armor - 1];
    // başlıktaki saç/şapka yerine miğfer
    out.removeWhere((b) => b.cz > 1.75 || (b.cz > 1.5 && b.cy < -0.15));
    out.addAll(knightBoxes(ar, armL: armL, armR: armR, leg: leg));
  }
  if (tool != null) out.addAll(_toolBoxes(tool, armR));
  if (shield) {
    out.add(ABox(-0.48, 0.02, 1.0, 0.03, 0.22, 0.26, const Color(0xFF1565C0), pivotZ: 1.39, angle: armL));
    out.add(ABox(-0.515, 0.02, 1.0, 0.012, 0.08, 0.1, const Color(0xFFFFC107), pivotZ: 1.39, angle: armL));
  }
  return out;
}

List<ABox> _toolBoxes(String t, double a, {double hx = 0.36, double hz = 0.76, double pz = 1.39}) {
  return [
    for (final b in _toolBoxesRaw(t, a))
      ABox(b.cx - 0.36 + hx, b.cy, b.cz - 0.76 + hz, b.hx, b.hy, b.hz, b.color, pivotZ: pz, angle: a),
  ];
}

List<ABox> _toolBoxesRaw(String t, double a) {
  const wood = Color(0xFF8D5524), iron = Color(0xFFCFD8DC), gold = Color(0xFFFFC107);
  // el: (0.36, 0, 0.76); alet ileri doğru uzanır
  switch (t) {
    case 'kazma':
      return [
        ABox(0.36, 0.2, 0.76, 0.025, 0.28, 0.025, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.46, 0.76, 0.03, 0.04, 0.2, iron, pivotZ: 1.39, angle: a),
      ];
    case 'balta':
      return [
        ABox(0.36, 0.2, 0.76, 0.025, 0.28, 0.025, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.42, 0.84, 0.02, 0.08, 0.1, iron, pivotZ: 1.39, angle: a),
      ];
    case 'kurek':
      return [
        ABox(0.36, 0.2, 0.76, 0.025, 0.28, 0.025, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.52, 0.76, 0.1, 0.08, 0.015, iron, pivotZ: 1.39, angle: a),
      ];
    case 'kilic':
      return [
        ABox(0.36, 0.05, 0.76, 0.03, 0.06, 0.03, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.12, 0.76, 0.1, 0.015, 0.025, gold, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.42, 0.76, 0.018, 0.3, 0.045, iron, pivotZ: 1.39, angle: a),
      ];
    case 'mizrak':
      return [
        ABox(0.36, 0.25, 0.76, 0.02, 0.6, 0.02, wood, pivotZ: 1.39, angle: a),
        ABox(0.36, 0.9, 0.76, 0.035, 0.08, 0.035, iron, pivotZ: 1.39, angle: a),
      ];
    default:
      return const [];
  }
}

/// Bir kutunun 8 köşesi (dünya koordinatı).
List<(double, double, double)> boxCorners(ABox b, double px, double py, double pz, double facing) {
  final cf = cos(facing), sf = sin(facing);
  final ca = cos(b.angle), sa = sin(b.angle);
  final out = <(double, double, double)>[];
  for (final sx in const [-1.0, 1.0]) {
    for (final sy in const [-1.0, 1.0]) {
      for (final sz in const [-1.0, 1.0]) {
        final lx = b.cx + sx * b.hx;
        var ly = b.cy + sy * b.hy;
        var lz = b.cz + sz * b.hz;
        if (b.angle != 0) {
          final rz = lz - b.pivotZ;
          final y2 = ly * ca - rz * sa;
          final z2 = ly * sa + rz * ca;
          ly = y2;
          lz = z2 + b.pivotZ;
        }
        out.add((px + lx * cf + ly * sf, py - lx * sf + ly * cf, pz + lz));
      }
    }
  }
  return out;
}

/// Kutunun yüzleri: köşe numaraları (sol üst, sağ üst, sağ alt, sol alt) ve yerel normal
/// köşe sırası: (sx,sy,sz) -> index = sx*4 + sy*2 + sz  (0 = eksi, 1 = artı)
const boxFaces = <(List<int>, int)>[
  ([3, 7, 5, 1], 0), // üst  z+
  ([5, 7, 6, 4], 1), // sağ  x+
  ([3, 1, 0, 2], 2), // sol  x-
  ([7, 3, 2, 6], 3), // ön   y+ (yüz)
  ([1, 5, 4, 0], 4), // arka y-
];

// ======================= KARAKTER EKRANI =======================

class AvatarScreen extends StatefulWidget {
  /// Arkadaş oluştururken: başlangıç görünümü verilir, sonuç kodlanmış görünüm olarak döner.
  final Avatar? friendStart;
  const AvatarScreen({super.key, this.friendStart});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> with SingleTickerProviderStateMixin {
  late Avatar a = widget.friendStart?.copy() ?? myAvatar;
  bool get friend => widget.friendStart != null;
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void initState() {
    super.initState();
    Voice.say(friend
        ? 'Yeni arkadaşını oluştur! Saçını, giysisini, rengini sen seç.'
        : 'Kendi karakterini oluştur! Hazır birini seç ya da renklerini değiştir.');
  }

  @override
  void dispose() {
    spin.dispose();
    super.dispose();
  }

  void _set(VoidCallback f) {
    Sfx.play('pop');
    setState(f);
  }

  Widget _row(String title, int count, int sel, Color Function(int) col, void Function(int) on) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 74, child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < count; i++)
                GestureDetector(
                  onTap: () => _set(() => on(i)),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col(i),
                      shape: BoxShape.circle,
                      border: Border.all(color: sel == i ? Colors.orange : Colors.black26, width: sel == i ? 4 : 2),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      );


  Future<void> _setTrail(String id) async {
    if (id.isNotEmpty && !trailOwned(id)) {
      final t = trails.firstWhere((e) => e.$1 == id);
      final ok = await showDialog<bool>(
          context: context,
          builder: (_) => SpellDialog(
                parts: t.$2,
                emoji: t.$3,
                title: '${t.$2.join()} izi! Adını yaz, senin olsun.',
                speech: '${t.$2.join()} izi! Adını yaz, senin olsun.',
              ));
      if (ok != true || !mounted) return;
      game.addBlockItem('iz_$id');
      Sfx.play('unlock');
    }
    game.setTrail(id);
    setState(() {});
    if (id.isNotEmpty) Voice.say('Yürüyünce arkanda ${trails.firstWhere((e) => e.$1 == id).$2.join()} izi çıkacak!');
  }


  Widget _armorTile(int i) {
    final ar = i == 0 ? null : armors[i - 1];
    final owned = ar == null || game.blockItems.contains('zirh_${ar.id}');
    final on = a.armor == i;
    return Bouncy(
      onTap: () async {
        if (ar != null && !owned) {
          final got = await getArmor(context, i);
          if (!got || !mounted) return;
        }
        _set(() => a.armor = i);
        Sfx.play('unlock');
        Voice.say(ar == null ? 'Zırhı çıkardın.' : ar.transform);
      },
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFFFF59D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? const Color(0xFFFF8F00) : Colors.black12, width: on ? 3 : 1.5),
        ),
        child: Column(children: [
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              if (ar == null)
                const Text('🚫', style: TextStyle(fontSize: 30))
              else if (ar.pic != null)
                Opacity(opacity: owned ? 1 : 0.55, child: Pic(ar.pic!, height: 70))
              else
                Icon(Icons.shield, color: ar.color, size: 40),
              if (!owned) const Positioned(right: 0, top: 0, child: Text('🔒', style: TextStyle(fontSize: 16))),
            ]),
          ),
          FittedBox(
            child: Text(ar == null ? 'Zırhsız' : (owned ? ar.hero : '${ar.price} 🪙'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF81D4FA), Color(0xFFC8E6C9)]),
        ),
        child: SafeArea(
          child: Column(children: [
            TopBar(friend ? 'Yeni arkadaş' : 'Karakterim'),
            SizedBox(
              height: 230,
              child: AnimatedBuilder(
                animation: spin,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: AvatarPainter(a, spin.value * 2 * pi, walk: sin(spin.value * 2 * pi * 4) * 0.0),
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
                for (final p in presets)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Bouncy(
                      onTap: () {
                        _set(() => a = p.$2.copy());
                        Voice.say(p.$1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Text(p.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(22)),
                child: ListView(children: [
                  Row(children: [
                    for (final b in [false, true])
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 6),
                        child: ChoiceChip(
                          label: Text(b ? '🐻 Ayı' : '🧒 İnsan', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          selected: a.bear == b,
                          onSelected: (_) => _set(() {
                            a.bear = b;
                            if (b && a.style > 3) a.style = 0;
                          }),
                        ),
                      ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Zırh (dokun, giy)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 104,
                        child: ListView(scrollDirection: Axis.horizontal, children: [
                          _armorTile(0),
                          for (var i = 1; i <= armors.length; i++) _armorTile(i),
                        ]),
                      ),
                    ]),
                  ),
                  if (!friend)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const SizedBox(width: 74, child: Text('Renkli iz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                      Expanded(
                        child: Wrap(spacing: 6, runSpacing: 6, children: [
                          ChoiceChip(label: const Text('Yok'), selected: game.trail.isEmpty, onSelected: (_) => _setTrail('')),
                          for (final t in trails)
                            ChoiceChip(
                              label: Text('${t.$3} ${t.$2.join()}${trailOwned(t.$1) ? '' : ' 🔒'}'),
                              selected: game.trail == t.$1,
                              onSelected: (_) => _setTrail(t.$1),
                            ),
                        ]),
                      ),
                    ]),
                  ),
                  if (a.bear) ...[
                    _row('Tüy', furColors.length, a.fur, (i) => furColors[i], (i) {
                      a.fur = i;
                      Voice.say('${furNames[i]} ayı');
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Wrap(spacing: 6, runSpacing: 6, children: [
                        for (var i = 0; i < bearStyles.length; i++)
                          ChoiceChip(
                            label: Text(bearStyles[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                            selected: a.style == i,
                            onSelected: (_) => _set(() => a.style = i),
                          ),
                      ]),
                    ),
                    if (a.style >= 1) _row('Başlık', hatColors.length, a.hat, (i) => hatColors[i], (i) => a.hat = i),
                    _row('Fular', clothColors.length, a.shirt, (i) => clothColors[i], (i) => a.shirt = i),
                  ] else ...[
                  _row('Ten', skinColors.length, a.skin, (i) => skinColors[i], (i) => a.skin = i),
                  _row('Saç', hairColors.length, a.hair, (i) => hairColors[i], (i) => a.hair = i),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      for (var i = 0; i < hairStyles.length; i++)
                        ChoiceChip(
                          label: Text(hairStyles[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                          selected: a.style == i,
                          onSelected: (_) => _set(() => a.style = i),
                        ),
                    ]),
                  ),
                  if (a.style >= 2) _row('Başlık', hatColors.length, a.hat, (i) => hatColors[i], (i) => a.hat = i),
                  _row('Gömlek', clothColors.length, a.shirt, (i) => clothColors[i], (i) => a.shirt = i),
                  _row('Pantolon', clothColors.length, a.pants, (i) => clothColors[i], (i) => a.pants = i),
                  ],
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF43A047)),
                  onPressed: () {
                    if (friend) {
                      Sfx.play('unlock');
                      Navigator.pop(context, a.encode());
                      return;
                    }
                    game.setAvatar(a.encode());
                    Sfx.play('unlock');
                    Voice.say('Harika görünüyorsun! Haydi şehre!');
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.check, size: 28),
                  label: Text(friend ? 'Tamam, isim verelim' : 'Bu benim!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Karakteri düz renklerle çizer (önizleme için).
class AvatarPainter extends CustomPainter {
  final Avatar a;
  final double facing;
  final double walk;
  AvatarPainter(this.a, this.facing, {this.walk = 0});

  @override
  void paint(Canvas canvas, Size size) {
    const pitch = 0.35;
    final s = size.height / 2.4;
    final sp = sin(pitch), cp = cos(pitch);
    Offset pr(double x, double y, double z) => Offset(size.width / 2 + x * s, size.height * 0.92 + y * sp * s - z * cp * s);
    double dep(double x, double y, double z) => y * cp + z * sp;
    // zemin gölgesi
    canvas.drawOval(Rect.fromCenter(center: pr(0, 0, 0), width: s * 0.9, height: s * 0.3), Paint()..color = Colors.black26);
    final items = <(double, Path, Color)>[];
    for (final b in avatarBoxes(a, walk: walk)) {
      final c = boxCorners(b, 0, 0, 0, facing);
      for (final f in boxFaces) {
        final p = [for (final i in f.$1) c[i]];
        // normal: (p1-p0) x (p3-p0)
        final ux = p[1].$1 - p[0].$1, uy = p[1].$2 - p[0].$2, uz = p[1].$3 - p[0].$3;
        final vx = p[3].$1 - p[0].$1, vy = p[3].$2 - p[0].$2, vz = p[3].$3 - p[0].$3;
        final nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
        // görünürlük: bakış yönü (0, cp, sp)
        if (-(ny * cp + nz * sp) <= 0 && !(nx == 0 && ny == 0 && nz == 0)) continue;
        final path = Path()..moveTo(pr(p[0].$1, p[0].$2, p[0].$3).dx, pr(p[0].$1, p[0].$2, p[0].$3).dy);
        for (var k = 1; k < 4; k++) {
          final q = pr(p[k].$1, p[k].$2, p[k].$3);
          path.lineTo(q.dx, q.dy);
        }
        path.close();
        final len = sqrt(nx * nx + ny * ny + nz * nz) + 1e-9;
        final light = (0.7 + 0.3 * (-(nz) / len).clamp(0.0, 1.0) + 0.15 * (-(nx) / len).clamp(0.0, 1.0)).clamp(0.6, 1.0);
        final cx = (p[0].$1 + p[2].$1) / 2, cy = (p[0].$2 + p[2].$2) / 2, cz = (p[0].$3 + p[2].$3) / 2;
        items.add((dep(cx, cy, cz), path, Color.lerp(Colors.black, b.color, light)!));
        if (b.face && f.$2 == 3) {
          // gözler ve ağız
          Offset at(double u, double v) {
            final x = p[0].$1 + (p[1].$1 - p[0].$1) * u + (p[3].$1 - p[0].$1) * v;
            final y = p[0].$2 + (p[1].$2 - p[0].$2) * u + (p[3].$2 - p[0].$2) * v;
            final z = p[0].$3 + (p[1].$3 - p[0].$3) * u + (p[3].$3 - p[0].$3) * v;
            return pr(x, y, z);
          }

          for (final e in const [(0.3, 0.42), (0.7, 0.42)]) {
            final path2 = Path()..addOval(Rect.fromCenter(center: at(e.$1, e.$2), width: s * 0.07, height: s * 0.09));
            items.add((dep(cx, cy, cz) + 0.001, path2, const Color(0xFF263238)));
          }
          final m = Path()
            ..moveTo(at(0.35, 0.72).dx, at(0.35, 0.72).dy)
            ..quadraticBezierTo(at(0.5, 0.82).dx, at(0.5, 0.82).dy, at(0.65, 0.72).dx, at(0.65, 0.72).dy);
          items.add((dep(cx, cy, cz) + 0.002, m, const Color(0xFFC62828)));
        }
      }
    }
    items.sort((x, y) => x.$1.compareTo(y.$1));
    for (final it in items) {
      final isMouth = it.$3 == const Color(0xFFC62828);
      canvas.drawPath(
          it.$2,
          isMouth
              ? (Paint()
                ..color = it.$3
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round)
              : (Paint()..color = it.$3));
    }
  }

  @override
  bool shouldRepaint(covariant AvatarPainter old) => true;
}

/// Resimdeki gibi tam zırh (insan): kubbe miğfer, büyük tüy, yuvarlak omuzluklar,
/// göğüs zırhı ve taşı, kemer, etek plakaları, kollukler, dizlik ve uzun pelerin.
List<ABox> knightBoxes(Armor ar, {required double armL, required double armR, required double leg}) {
  final c = ar.color, t = ar.trim, g = ar.gem;
  final capeA = -0.08 - leg.abs() * 0.3;
  final out = <ABox>[
    // pelerin (omuzdan dize kadar, altı genişler)
    ABox(0, -0.185, 1.37, 0.3, 0.03, 0.035, t),
    ABox(0, -0.2, 0.92, 0.29, 0.02, 0.44, ar.cape, pivotZ: 1.37, angle: capeA),
    ABox(0, -0.2, 0.42, 0.34, 0.02, 0.07, ar.cape, pivotZ: 1.37, angle: capeA),
    // göğüs zırhı
    ABox(0, 0.01, 1.1, 0.275, 0.17, 0.315, c),
    ABox(0, 0, 1.405, 0.2, 0.15, 0.025, t),
    ABox(0, 0.183, 1.18, 0.26, 0.008, 0.022, t),
    ABox(-0.12, 0.183, 1.3, 0.1, 0.008, 0.018, t),
    ABox(0.12, 0.183, 1.3, 0.1, 0.008, 0.018, t),
    ABox(0, 0.186, 1.28, 0.075, 0.006, 0.075, t),
    ABox(0, 0.195, 1.28, 0.05, 0.008, 0.055, g),
    // kemer ve tokası
    ABox(0, 0.005, 0.83, 0.285, 0.18, 0.045, t),
    ABox(0, 0.19, 0.83, 0.06, 0.008, 0.05, c),
    ABox(0, 0.2, 0.83, 0.035, 0.006, 0.03, g),
    // etek plakaları
    ABox(-0.16, 0.155, 0.67, 0.085, 0.02, 0.12, c),
    ABox(0, 0.165, 0.65, 0.07, 0.02, 0.14, c),
    ABox(0.16, 0.155, 0.67, 0.085, 0.02, 0.12, c),
    ABox(-0.16, 0.16, 0.55, 0.085, 0.02, 0.02, t),
    ABox(0, 0.17, 0.51, 0.07, 0.02, 0.02, t),
    ABox(0.16, 0.16, 0.55, 0.085, 0.02, 0.02, t),
    // yuvarlak omuzluklar
    for (final (sx, an) in [(-1.0, armL), (1.0, armR)]) ...[
      ABox(sx * 0.39, 0, 1.36, 0.17, 0.18, 0.1, c, pivotZ: 1.39, angle: an),
      ABox(sx * 0.39, 0, 1.47, 0.13, 0.14, 0.035, c, pivotZ: 1.39, angle: an),
      ABox(sx * 0.41, 0, 1.26, 0.18, 0.19, 0.025, t, pivotZ: 1.39, angle: an),
      // kol zırhı ve eldiven
      ABox(sx * 0.36, 0, 1.08, 0.11, 0.11, 0.17, c, pivotZ: 1.39, angle: an),
      ABox(sx * 0.36, 0, 0.88, 0.115, 0.115, 0.05, t, pivotZ: 1.39, angle: an),
      ABox(sx * 0.36, 0, 0.77, 0.1, 0.1, 0.06, c, pivotZ: 1.39, angle: an),
    ],
    // bacak zırhı, dizlik, çizme
    for (final (sx, an) in [(-1.0, leg), (1.0, -leg)]) ...[
      ABox(sx * 0.13, 0, 0.33, 0.125, 0.135, 0.22, c, pivotZ: 0.75, angle: an),
      ABox(sx * 0.13, 0.14, 0.5, 0.08, 0.015, 0.05, t, pivotZ: 0.75, angle: an),
      ABox(sx * 0.13, 0.02, 0.06, 0.13, 0.165, 0.06, t, pivotZ: 0.75, angle: an),
    ],
  ];
  if (ar.helm == 0) {
    out.addAll([
      // kubbe miğfer, yüz açık
      ABox(0, 0, 1.9, 0.255, 0.255, 0.04, c),
      ABox(0, -0.01, 1.965, 0.2, 0.2, 0.03, c),
      ABox(0, -0.01, 2.01, 0.12, 0.13, 0.02, t),
      ABox(-0.25, 0, 1.66, 0.03, 0.255, 0.24, c),
      ABox(0.25, 0, 1.66, 0.03, 0.255, 0.24, c),
      ABox(0, -0.25, 1.66, 0.255, 0.03, 0.24, c),
      ABox(0, 0.25, 1.83, 0.26, 0.025, 0.05, t),
      ABox(-0.185, 0.25, 1.58, 0.065, 0.025, 0.16, c),
      ABox(0.185, 0.25, 1.58, 0.065, 0.025, 0.16, c),
      ABox(-0.185, 0.255, 1.43, 0.065, 0.02, 0.015, t),
      ABox(0.185, 0.255, 1.43, 0.065, 0.02, 0.015, t),
      ABox(-0.285, 0.06, 1.8, 0.012, 0.05, 0.05, t),
      ABox(0.285, 0.06, 1.8, 0.012, 0.05, 0.05, t),
      ABox(0, 0.28, 1.83, 0.035, 0.01, 0.03, g),
    ]);
    final pl = ar.plume;
    if (pl != null) {
      // kabarık tüy
      out.addAll([
        ABox(0, -0.02, 2.06, 0.03, 0.03, 0.04, t),
        ABox(0, -0.03, 2.18, 0.11, 0.12, 0.09, pl),
        ABox(0, -0.15, 2.13, 0.09, 0.08, 0.08, pl),
        ABox(0.05, 0.06, 2.26, 0.07, 0.07, 0.06, pl),
        ABox(-0.05, -0.07, 2.29, 0.07, 0.07, 0.06, pl),
        ABox(0, -0.22, 2.03, 0.06, 0.06, 0.07, pl),
      ]);
    }
    if (ar.horns) {
      out.addAll([
        ABox(-0.3, 0.03, 1.93, 0.035, 0.035, 0.07, t),
        ABox(0.3, 0.03, 1.93, 0.035, 0.035, 0.07, t),
        ABox(-0.33, 0.03, 2.03, 0.03, 0.03, 0.05, t),
        ABox(0.33, 0.03, 2.03, 0.03, 0.03, 0.05, t),
        ABox(-0.34, 0.03, 2.1, 0.022, 0.022, 0.03, g),
        ABox(0.34, 0.03, 2.1, 0.022, 0.022, 0.03, g),
      ]);
    }
  } else {
    out.addAll(helmBoxes(ar, 1.88));
    final pl = ar.plume;
    if (pl != null && ar.helm == 2) {
      out.add(ABox(0, 0.17, 2.15, 0.03, 0.035, 0.13, pl));
      out.add(ABox(0, 0.13, 2.28, 0.025, 0.05, 0.05, pl));
    }
  }
  return out;
}
