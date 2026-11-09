import 'package:flutter/material.dart';

import 'car3d/car_model.dart';

/// Bir parçanın açılması için gereken ödül eşikleri (harcanmaz, ulaşılması yeterli).
class Req {
  final int stars;
  final int hearts;
  final int cups;
  const Req({this.stars = 0, this.hearts = 0, this.cups = 0});
  bool get free => stars == 0 && hearts == 0 && cups == 0;
}

class PartOption {
  final String label;
  final Req req;
  final int? swatch; // renk seçenekleri için
  final String? emoji;
  const PartOption(this.label, {this.req = const Req(), this.swatch, this.emoji});
}

/// Garajdaki bir parça satırı (ör. Jant rengi).
class PartRow {
  final String key; // CarConfig alanı
  final String title;
  final String sound; // seçilince çalan efekt
  final List<PartOption> options;
  const PartRow(this.key, this.title, this.sound, this.options);
}

/// Garaj sekmesi.
class GarageTab {
  final String title;
  final IconData icon;
  final Color color;
  final List<PartRow> rows;
  const GarageTab(this.title, this.icon, this.color, this.rows);
}

List<PartOption> _colors(List<String> names, List<int> colors, [Map<int, Req> reqs = const {}]) => [
      for (var i = 0; i < names.length; i++) PartOption(names[i], swatch: colors[i], req: reqs[i] ?? const Req()),
    ];

final garageTabs = <GarageTab>[
  GarageTab('Gövde', Icons.directions_car, const Color(0xFF546E7A), [
    const PartRow('body', 'Araba', 'wrench', [
      PartOption('Yarış arabası'),
      PartOption('Aile arabası'),
      PartOption('Cip', req: Req(stars: 5)),
      PartOption('Kamyonet', req: Req(stars: 10, hearts: 1)),
    ]),
    const PartRow('height', 'Yükseklik', 'wrench', [
      PartOption('Alçak', emoji: '⬇️'),
      PartOption('Normal', emoji: '↔️'),
      PartOption('Yüksek', emoji: '⬆️'),
    ]),
  ]),
  GarageTab('Boya', Icons.format_paint, const Color(0xFFE53935), [
    PartRow(
      'color',
      'Renk',
      'spray',
      _colors(
        ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Beyaz', 'Siyah', 'Turuncu', 'Mor', 'Turkuaz', 'Pembe', 'Gümüş', 'Altın'],
        paintColors,
        {
          6: const Req(stars: 3),
          7: const Req(hearts: 1),
          8: const Req(cups: 1),
          9: const Req(stars: 6),
          10: const Req(stars: 8, hearts: 2),
          11: const Req(cups: 2),
        },
      ),
    ),
    const PartRow('finish', 'Cila', 'spray', [
      PartOption('Parlak', emoji: '✨'),
      PartOption('Metalik', emoji: '🪩', req: Req(stars: 4)),
      PartOption('Mat', emoji: '🧱', req: Req(hearts: 2)),
    ]),
  ]),
  GarageTab('Çıkartma', Icons.auto_awesome, const Color(0xFFFF8F00), [
    const PartRow('sticker', 'Desen', 'spray', [
      PartOption('Yok', emoji: '⭕'),
      PartOption('Yarış şeridi', emoji: '🏁'),
      PartOption('Yan şerit', emoji: '➖'),
      PartOption('Alev', emoji: '🔥', req: Req(stars: 3)),
      PartOption('Şimşek', emoji: '⚡', req: Req(cups: 1)),
      PartOption('Yıldız', emoji: '✴️', req: Req(hearts: 1)),
      PartOption('Lale', emoji: '🌷', req: Req(stars: 6)),
    ]),
    PartRow('stickerColor', 'Desen rengi', 'spray',
        _colors(['Beyaz', 'Siyah', 'Altın', 'Kırmızı', 'Turkuaz'], stickerColors)),
  ]),
  GarageTab('Tekerlek', Icons.trip_origin, const Color(0xFF37474F), [
    const PartRow('rim', 'Jant', 'wrench', [
      PartOption('Klasik', emoji: '⚙️'),
      PartOption('Altı kollu', emoji: '✳️'),
      PartOption('Çok kollu', emoji: '🔆', req: Req(stars: 3)),
      PartOption('Üç kollu', emoji: '🔱', req: Req(cups: 1)),
      PartOption('Kapalı', emoji: '⚫', req: Req(stars: 8)),
    ]),
    PartRow('rimColor', 'Jant rengi', 'spray',
        _colors(['Gümüş', 'Siyah', 'Altın', 'Kırmızı', 'Mavi'], rimColors, {2: const Req(stars: 5)})),
    const PartRow('tire', 'Lastik', 'wrench', [
      PartOption('Normal', emoji: '🛞'),
      PartOption('Arazi', emoji: '🏔️', req: Req(cups: 2)),
    ]),
  ]),
  GarageTab('Aksesuar', Icons.construction, const Color(0xFF6D4C41), [
    const PartRow('spoiler', 'Spoiler', 'wrench', [
      PartOption('Yok', emoji: '⭕'),
      PartOption('Küçük', emoji: '▬'),
      PartOption('Büyük', emoji: '🪽', req: Req(stars: 4)),
      PartOption('Çift kanat', emoji: '✈️', req: Req(cups: 2)),
    ]),
    const PartRow('roof', 'Tavan', 'wrench', [
      PartOption('Yok', emoji: '⭕'),
      PartOption('Bagaj', emoji: '🧳'),
      PartOption('Siren', emoji: '🚨', req: Req(hearts: 2)),
      PartOption('Işık barı', emoji: '💡', req: Req(stars: 7)),
    ]),
    const PartRow('exhaust', 'Egzoz', 'rev', [
      PartOption('Tek', emoji: '💨'),
      PartOption('Çift', emoji: '💨', req: Req(stars: 2)),
    ]),
  ]),
  GarageTab('Işıklar', Icons.light_mode, const Color(0xFF7B1FA2), [
    const PartRow('light', 'Farlar', 'click', [
      PartOption('Beyaz', swatch: 0xFFFFFDE7),
      PartOption('Sarı', swatch: 0xFFFFD54F),
      PartOption('Mavi', swatch: 0xFF80D8FF, req: Req(stars: 3)),
    ]),
    PartRow('neon', 'Neon', 'unlock', [
      const PartOption('Yok', emoji: '⭕'),
      PartOption('Mavi', swatch: neonColors[1], req: const Req(stars: 2)),
      PartOption('Pembe', swatch: neonColors[2], req: const Req(stars: 2)),
      PartOption('Yeşil', swatch: neonColors[3], req: const Req(hearts: 1)),
      PartOption('Mor', swatch: neonColors[4], req: const Req(cups: 1)),
      PartOption('Turuncu', swatch: neonColors[5], req: const Req(stars: 5)),
      PartOption('Turkuaz', swatch: neonColors[6], req: const Req(hearts: 2)),
    ]),
    PartRow('tint', 'Cam', 'click', _colors(['Açık', 'Füme', 'Siyah'], tintColors)),
  ]),
  GarageTab('Korna', Icons.campaign, const Color(0xFF00897B), [
    const PartRow('horn', 'Korna sesi', 'horn', [
      PartOption('Düt düt', emoji: '📯'),
      PartOption('Bip bip', emoji: '🔔'),
      PartOption('Kamyon', emoji: '🚛', req: Req(hearts: 1)),
      PartOption('Melodi', emoji: '🎵', req: Req(cups: 1)),
    ]),
  ]),
];

PartRow? rowFor(String key) {
  for (final t in garageTabs) {
    for (final r in t.rows) {
      if (r.key == key) return r;
    }
  }
  return null;
}

/// Rakiplerin hazır arabaları.
const rivalConfigs = <CarConfig>[
  CarConfig(body: 0, color: 8, sticker: 1, stickerColor: 0, spoiler: 1),
  CarConfig(body: 1, color: 9, finish: 1, rim: 1),
  CarConfig(body: 2, color: 2, tire: 1, roof: 1),
];
