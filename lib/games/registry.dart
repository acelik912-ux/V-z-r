import 'package:flutter/material.dart';

import '../art.dart';
import '../state.dart';
import '../screens/race.dart';
import 'araba_yikama.dart';
import 'blok.dart';
import 'hece_kamyonu.dart';
import 'kasaba.dart';
import 'liman.dart';
import 'orman.dart';
import 'sayi.dart';
import 'ucan_araba.dart';

class GameDef {
  final String id;
  final String title;
  final String emoji;
  final String skill;
  final Widget Function() build;
  final bool loop; // bitince "Tekrar" penceresi döner
  const GameDef(this.id, this.title, this.emoji, this.skill, this.build, {this.loop = true});
}

class Region {
  final String id;
  final String name;
  final String bg;
  final Who who;
  final String intro;
  final int need; // açılması için gereken macera yıldızı
  final Offset at; // ada_harita (720x1290) üzerindeki yeri
  final Color color;
  final List<GameDef> games;
  const Region(this.id, this.name, this.bg, this.who, this.intro, this.need, this.at, this.color, this.games);
}

final regions = <Region>[
  Region('hece', 'Hece Vadisi', 'bolge_hece', Who.baykus, 'Hece Vadisine hoş geldin! Burada heceleri birleştirip kelimeler yaparız.', 0,
      const Offset(270, 1010), const Color(0xFFFFB74D), [
    GameDef('hece_kamyonu', 'Hece Kamyonu', '🚚', 'Hece', () => const HeceKamyonu()),
    GameDef('araba_yikama', 'Araba Yıkama', '🫧', 'Okuma', () => const ArabaYikama()),
    GameDef('yaris', 'Hece Yarışı', '🏁', 'Hece', () => const RaceScreen(), loop: false),
  ]),
  Region('kasaba', 'Kasaba Yolu', 'ana_ekran', Who.tamirci, 'Kasabaya hoş geldin! Komşulara yardım edelim, kuralları öğrenelim.', 0,
      const Offset(470, 850), const Color(0xFF90A4AE), [
    GameDef('iyilik', 'İyilik Teslimatı', '🎁', 'İyilik', () => const IyilikTeslimati()),
    GameDef('trafik', 'Trafik Kuralları', '🚦', 'Kurallar', () => const Trafik()),
    GameDef('otopark', 'Otopark Bulmacası', '🅿️', 'Düşünme', () => const Otopark()),
  ]),
  Region('sayi', 'Sayı Dağları', 'bolge_sayi', Who.robot, 'Ben Robot Rakam! Sayı Dağlarında saymayı ve toplamayı öğreniriz.', 3,
      const Offset(120, 600), const Color(0xFFFF8A65), [
    GameDef('kopru_kur', 'Köprü Kur', '🌉', 'Sayma', () => const KopruKur()),
    GameDef('tunel', 'Tünel Kazısı', '⛏️', 'Sayılar', () => const TunelKazisi()),
  ]),
  Region('orman', 'Kelime Ormanı', 'bolge_kelime', Who.tozbulut, 'Kelime Ormanında kaybolan yavrular var. Haydi onlara yardım edelim!', 6,
      const Offset(340, 620), const Color(0xFF66BB6A), [
    GameDef('hayvan', 'Hayvan Kurtarma', '🐾', 'Okuma', () => const HayvanKurtarma()),
    GameDef('hafiza', 'Hafıza Kartları', '🃏', 'Kelime', () => const HafizaKartlari()),
  ]),
  Region('liman', 'Liman', 'bolge_liman', Who.papagan, 'Hello! Ben Polly. Limanda birlikte İngilizce öğreneceğiz!', 9, const Offset(600, 620),
      const Color(0xFF4FC3F7), [
    GameDef('gemi', 'Gemi Yükle', '🚢', 'İngilizce', () => const GemiYukle()),
    GameDef('balik', 'Balık Tut', '🎣', 'İngilizce', () => const BalikTut()),
  ]),
  Region('bulut', 'Bulut Tepesi', 'bolge_bulut', Who.baykus, 'Bulut Tepesine ulaştın! Arabamız burada uçabiliyor.', 14,
      const Offset(380, 230), const Color(0xFFCE93D8), [
    GameDef('ucan_araba', 'Uçan Araba', '🪽', 'Hece', () => const UcanAraba()),
  ]),
];

final blokGame = GameDef('blok', 'Blok Şehri', '🧱', 'İnşa', () => const BlokAdasi(), loop: false);

GameDef? gameById(String id) {
  if (id == 'blok') return blokGame;
  for (final r in regions) {
    for (final g in r.games) {
      if (g.id == id) return g;
    }
  }
  return null;
}

int regionStars(Region r) {
  // otopark birden çok bölümlü; en iyi sonucu say
  return r.games.fold(0, (a, g) => a + bestOf(g.id));
}

int bestOf(String id) {
  if (id == 'otopark') {
    var m = 0;
    for (var i = 0; i < 8; i++) {
      final v = gameStars('otopark_$i');
      if (v > m) m = v;
    }
    return m;
  }
  return gameStars(id);
}

int gameStars(String id) => game.best(id);
