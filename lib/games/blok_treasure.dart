import 'package:flutter/material.dart';

import '../art.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';

// ================= HAZİNELER: değerli taşlar ve kültürel miras =================

class Treasure {
  final String id, name, emoji, info;
  final List<String> parts; // heceleri
  final int coins;
  final bool gem; // değerli taş mı, miras eşyası mı
  final String? place; // yalnızca bu yerin sandığından çıkar
  const Treasure(this.id, this.name, this.parts, this.emoji, this.info, {this.coins = 5, this.gem = false, this.place});
}

/// Değerli taşlar: dağlarda, tepelerde ve kıyılarda bulunur.
const gems = [
  Treasure('yakut', 'yakut', ['ya', 'kut'], '🔴', 'Yakut kırmızı renkli, çok değerli bir taştır.', coins: 10, gem: true),
  Treasure('firuze', 'firuze', ['fi', 'ru', 'ze'], '🔵', 'Firuze turkuaz renkli bir taştır. Selçuklu çinilerinde bu renk çok kullanılır.',
      coins: 10, gem: true),
  Treasure('gumus', 'gümüş', ['gü', 'müş'], '⚪', 'Gümüş parlak beyaz bir madendir. Ondan yüzük ve süs eşyası yapılır.', coins: 6, gem: true),
  Treasure('kehribar', 'kehribar', ['keh', 'ri', 'bar'], '🟠',
      'Kehribar, çok eski ağaçların reçinesinden oluşmuş bal renkli bir taştır.', coins: 8, gem: true),
  Treasure('inci', 'inci', ['in', 'ci'], '🦪', 'İnci, denizdeki istiridyenin içinde yavaş yavaş oluşan parlak bir tanedir.',
      coins: 8, gem: true),
];

/// Kültürel miras: köylerdeki ve adalardaki miras sandıklarından çıkar.
/// İnancımıza ve kültürümüze saygıyla seçildi.
const heritage = [
  // yere özgü
  Treasure('kayisi', 'kayısı', ['ka', 'yı', 'sı'], '🍑', 'Malatya kayısısı dünyaca ünlüdür. Tatlı ve şifalı bir meyvedir.', place: 'Malatya'),
  Treasure('selale', 'şelale', ['şe', 'la', 'le'], '💦', "Darende'deki Gürpınar Şelalesi köpük köpük akar.", place: 'Darende'),
  Treasure('hazar', 'göl', ['g', 'ö', 'l'], '🏞️', "Elazığ'daki Hazar Gölü dağların arasında büyük bir göldür.", place: 'Elazığ'),
  Treasure('harputkale', 'kale', ['ka', 'le'], '🏰', 'Harput Kalesi yüksek bir tepenin üstündeki çok eski bir kaledir.', place: 'Harput'),
  Treasure('galata', 'kule', ['ku', 'le'], '🗼', "Galata Kulesi İstanbul'un ünlü taş kulesidir.", place: 'İstanbul'),
  Treasure('tiftik', 'keçi', ['ke', 'çi'], '🐐', 'Ankara keçisi yumuşacık tiftiğiyle ünlüdür. Ondan sıcak giysiler yapılır.', place: 'Ankara'),
  Treasure('saatkulesi', 'saat', ['sa', 'at'], '🕰️', "İzmir Saat Kulesi Konak Meydanı'nın simgesidir.", place: 'İzmir'),
  Treasure('pismaniye', 'pişmaniye', ['piş', 'ma', 'ni', 'ye'], '🍬', 'Kocaeli pişmaniyesi ipek iplik gibi bir tatlıdır.', place: 'Kocaeli'),
  Treasure('kuscenneti', 'kuş', ['k', 'u', 'ş'], '🦜', "Darıca'da birçok kuşun yaşadığı güzel bir kuş bahçesi vardır.", place: 'Darıca'),
  Treasure('cesme', 'çeşme', ['çeş', 'me'], '⛲', 'Çeşme hayır için yapılır; herkes ondan su içer. Pınarın suyu bereketlidir.', place: 'Ulupınar'),
  // her yerden çıkabilir
  Treasure('usturlap', 'usturlap', ['us', 'tur', 'lap'], '🧭',
      'Usturlap ile Müslüman âlimler yıldızlara bakıp yönü ve namaz vakitlerini bulurdu.'),
  Treasure('cezeri', 'su saati', ['sa', 'at'], '⏳', "Müslüman mucit El-Cezerî suyla çalışan harika saatler yaptı."),
  Treasure('cini', 'çini', ['çi', 'ni'], '🔷', "Çini, İznik'te yapılan mavi çiçek desenli süslü karodur. Camileri güzelleştirir."),
  Treasure('yildiz', 'yıldız', ['yıl', 'dız'], '✴️', 'Sekiz köşeli Selçuklu yıldızı, Selçuklu yapılarını süsleyen bir desendir.'),
  Treasure('hat', 'hat', ['h', 'a', 't'], '🖋️', 'Hat, güzel yazı sanatıdır. Hattatlar kamış kalemle büyük bir sabırla yazar.'),
  Treasure('ebru', 'ebru', ['eb', 'ru'], '🎨', 'Ebru, suyun üstüne boya serpilerek yapılan geleneksel bir sanattır.'),
  Treasure('kilim', 'kilim', ['ki', 'lim'], '🧶', "Kilim, Anadolu'da elde dokunan renkli bir yaygıdır."),
  Treasure('kandil', 'kandil', ['kan', 'dil'], '🪔', 'Kandil, eski camileri ve evleri aydınlatan yağ lambasıdır.'),
  Treasure('tesbih', 'tesbih', ['tes', 'bih'], '📿', 'Tesbih, zikir çekerken ve dua ederken kullanılır.'),
  Treasure('seccade', 'seccade', ['sec', 'ca', 'de'], '🕌', 'Seccade, üzerinde namaz kılınan temiz bir halıdır.'),
  Treasure('ibrik', 'ibrik', ['ib', 'rik'], '🫖', 'İbrik, abdest alırken su dökmek için kullanılan güzel bir kaptır.'),
  Treasure('mehter', 'davul', ['da', 'vul'], '🥁', 'Mehter, Osmanlının bandosudur. Davulu uzaklardan duyulur.'),
  Treasure('cezve', 'cezve', ['cez', 've'], '☕', 'Cezve, Türk kahvesinin piştiği küçük kaptır. Misafire ikram edilir.'),
];

final allTreasures = [...gems, ...heritage];

Treasure treasureById(String id) => allTreasures.firstWhere((t) => t.id == id);

/// Sandıktan çıkacak eşya: yerin kendi eşyası bulunmadıysa o, yoksa sıradaki bulunmamış eşya.
Treasure? nextHeritage(String? placeBase) {
  if (placeBase != null) {
    for (final t in heritage) {
      if (t.place == placeBase && !game.treasures.contains(t.id)) return t;
    }
  }
  for (final t in heritage) {
    if (t.place == null && !game.treasures.contains(t.id)) return t;
  }
  return null;
}

/// Hazine müzesi: bulunanlar parlar, bulunmayanlar soru işareti.
class MuseumScreen extends StatelessWidget {
  const MuseumScreen({super.key});

  Widget _grid(BuildContext context, List<Treasure> l) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in l)
          Builder(builder: (_) {
            final has = game.treasures.contains(t.id);
            return Bouncy(
              onTap: () => Voice.say(has ? '${trCapitalize(t.name)}. ${t.info}' : 'Bunu henüz bulmadın. Haydi ara!'),
              child: Container(
                width: 96,
                height: 104,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: has ? const Color(0xFFFFF8E1) : const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: has ? const Color(0xFFFFC107) : Colors.white38, width: has ? 3 : 1.5),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(has ? t.emoji : '❓', style: const TextStyle(fontSize: 38)),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: has
                        ? SylText(t.name, size: 16)
                        : Text(t.place ?? '???', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            );
          }),
      ]);

  @override
  Widget build(BuildContext context) {
    final found = allTreasures.where((t) => game.treasures.contains(t.id)).length;
    Voice.say('Hazine müzesi! $found hazine buldun. Dokununca ne olduğunu anlatırım.');
    return Scaffold(
      backgroundColor: const Color(0xFF4E342E),
      body: SafeArea(
        child: Column(children: [
          TopBar('🏛️ Hazine Müzesi',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text('$found / ${allTreasures.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              )),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(12), children: [
              const Text('💎 Değerli taşlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const Text('Tepelerin, dağların içinde ve kıyılarda. Kırınca adını yaz, çıkar!',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 8),
              _grid(context, gems),
              const SizedBox(height: 18),
              const Text('📜 Kültürel miras', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const Text('Köylerin ve adaların meydanındaki parlayan miras sandıklarında.',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 8),
              _grid(context, heritage),
            ]),
          ),
        ]),
      ),
    );
  }
}
