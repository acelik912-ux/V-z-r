import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';
import 'blok_char.dart';
import 'blok_life.dart';
import 'blok_shapes.dart';

// ================= ARKADAŞLAR =================

/// Çocuğun oluşturduğu, adını verdiği, iş buyurabildiği arkadaş.
class Friend {
  String name;
  Avatar look;
  double x, y, z, facing = 0, walk = 0, anim = 0;
  int mode; // 0 takip, 1 bekle, 2 işe gidiyor, 3 çalışıyor
  (int, int, int)? goal; // yapı yeri
  String? job; // yapılacak hazır yapı
  int jobDir = 0;
  Friend(this.name, this.look, this.x, this.y, this.z, {this.mode = 0});

  String encode() {
    final g = goal, j = job;
    final work = (mode == 2 || mode == 3) && g != null && j != null ? '~${g.$1},${g.$2},${g.$3}~$j~$jobDir' : '';
    return '$name~${look.encode()}~${x.toStringAsFixed(1)}~${y.toStringAsFixed(1)}~${z.toStringAsFixed(1)}~${mode == 1 ? 1 : 0}$work';
  }

  static Friend? decode(String s) {
    final p = s.split('~');
    if (p.length != 6 && p.length != 9) return null;
    final a = Avatar.decode(p[1]);
    if (a == null) return null;
    final f = Friend(p[0], a, double.tryParse(p[2]) ?? 17, double.tryParse(p[3]) ?? 17, double.tryParse(p[4]) ?? 1,
        mode: p[5] == '1' ? 1 : 0);
    if (p.length == 9) {
      final g = p[6].split(',').map(int.tryParse).toList();
      if (g.length == 3 && !g.contains(null)) {
        f.goal = (g[0]!, g[1]!, g[2]!);
        f.job = p[7];
        f.jobDir = int.tryParse(p[8]) ?? 0;
        f.mode = 2; // yarım kalan işine geri döner
      }
    }
    return f;
  }
}

List<Friend> loadFriends() => game.blockFriends.split(';').where((e) => e.isNotEmpty).map(Friend.decode).whereType<Friend>().toList();

void saveFriends(List<Friend> l) => game.saveFriends(l.map((f) => f.encode()).join(';'));

const friendNames = [
  'Ali', 'Ayşe', 'Emir', 'Elif', 'Ömer', 'Zeynep', 'Yusuf', 'Meryem', 'Hamza', 'Fatma', //
  'Kerem', 'Ela', 'Selim', 'Esra', 'Eymen', 'Asel', 'Kaan', 'Nil', 'Mete', 'İkra',
];

/// Arkadaşa buyrulabilecek işler: (hazır yapı, ad, emoji)
const friendJobs = [
  ('p_roket', 'roket', '🚀'),
  ('p_ucak', 'uçak', '✈️'),
  ('p_cami', 'cami', '🕌'),
  ('p_okul', 'okul', '🏫'),
  ('p_ev', 'ev', '🏠'),
  ('p_kopru', 'köprü', '🌉'),
  ('p_kule', 'kule', '🏰'),
  ('p_havuz', 'havuz', '⛲'),
  ('p_ahir', 'ahır', '🛖'),
  ('p_agac', 'ağaç', '🌳'),
  ('p_bahce', 'bahçe', '🌷'),
];

/// Yeni arkadaş: önce görünüm, sonra isim (heceleyerek).
Future<Friend?> createFriend(BuildContext context, double x, double y, double z) async {
  final r = Random();
  final start = presets[r.nextInt(presets.length)].$2.copy();
  final code = await Navigator.push<String>(context, fadeRoute<String>(AvatarScreen(friendStart: start)));
  if (code == null || !context.mounted) return null;
  final look = Avatar.decode(code);
  if (look == null) return null;
  final name = await showDialog<String>(context: context, barrierDismissible: false, builder: (_) => const NameDialog());
  if (name == null || name.isEmpty || !context.mounted) return null;
  Sfx.play('unlock');
  Voice.say('Merhaba! Benim adım $name. Seninle arkadaş olmak çok güzel! Ne istersen yaparım.');
  return Friend(name, look, x + 1.2, y + 0.6, z);
}

class NameDialog extends StatelessWidget {
  const NameDialog({super.key});

  Future<void> _pick(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: heceler(trLower(name)),
              emoji: '🧒',
              title: 'Arkadaşının adı: $name. Hecelerini diz!',
              speech: 'Arkadaşının adı $name olsun. Hecelerini sırayla diz!',
            ));
    if (ok == true && context.mounted) Navigator.pop(context, name);
  }

  Future<void> _custom(BuildContext context) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (dc) => AlertDialog(
              title: const Text('Başka bir isim'),
              content: TextField(
                controller: c,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 14,
                decoration: const InputDecoration(hintText: 'İsim yazın'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Vazgeç')),
                FilledButton(onPressed: () => Navigator.pop(dc, c.text.trim()), child: const Text('Tamam')),
              ],
            ));
    final n = (name ?? '').replaceAll(RegExp(r'[~;|,:]'), '');
    if (n.isEmpty || !context.mounted) return;
    await _pick(context, trCapitalize(n));
  }

  @override
  Widget build(BuildContext context) {
    Voice.say('Arkadaşının adı ne olsun?');
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🧒 Arkadaşının adı ne olsun?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          SizedBox(
            width: 320,
            height: 300,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                for (final n in friendNames)
                  Bouncy(
                    onTap: () => _pick(context, n),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: FittedBox(child: Padding(padding: const EdgeInsets.all(4), child: SylText(n, size: 20))),
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _custom(context),
            icon: const Icon(Icons.edit),
            label: const Text('Başka bir isim (anne-baba yazar)', style: TextStyle(fontSize: 15)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç', style: TextStyle(fontSize: 16))),
        ]),
      ),
    );
  }
}

/// Arkadaşa ne yapacağını söyle: gel, bekle, yapı yap.
/// Dönüş: 'gel', 'bekle', 'sil', ya da yapı kimliği (p_cami ...).
class FriendOrderDialog extends StatelessWidget {
  final Friend f;
  const FriendOrderDialog(this.f, {super.key});

  Future<void> _job(BuildContext context, (String, String, String) j) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => SpellDialog(
              parts: heceler(j.$2),
              emoji: j.$3,
              title: '${f.name}, ${j.$2} yap! Hecelerini diz.',
              speech: '${f.name} ${j.$2} yapsın. Hecelerini sırayla diz!',
            ));
    if (ok == true && context.mounted) Navigator.pop(context, j.$1);
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(String emoji, String label, Color c, VoidCallback onTap) => Bouncy(
          onTap: onTap,
          child: Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            ]),
          ),
        );
    return Dialog(
      backgroundColor: const Color(0xFFE3F2FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            SizedBox(width: 70, height: 90, child: CustomPaint(painter: AvatarPainter(f.look, 0.5))),
            const SizedBox(width: 8),
            Expanded(child: SylText(f.name, size: 28)),
            IconButton(
              icon: const Icon(Icons.volume_up, size: 30),
              onPressed: () => Voice.say('Benim adım ${f.name}!'),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            btn('👣', 'Benimle gel', const Color(0xFFC8E6C9), () => Navigator.pop(context, 'gel')),
            btn('✋', 'Burada bekle', const Color(0xFFFFE0B2), () => Navigator.pop(context, 'bekle')),
          ]),
          const SizedBox(height: 10),
          const Text('🔨 Ne yapsın?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final j in friendJobs)
              Bouncy(
                onTap: () => _job(context, j),
                child: Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Text(j.$3, style: const TextStyle(fontSize: 30)),
                    FittedBox(child: SylText(j.$2, size: 16)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton.icon(
              onPressed: () async {
                final sure = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                          title: Text('${f.name} evine gitsin mi?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Hayır')),
                            FilledButton(onPressed: () => Navigator.pop(dc, true), child: const Text('Evet')),
                          ],
                        ));
                if (sure == true && context.mounted) Navigator.pop(context, 'sil');
              },
              icon: const Icon(Icons.home_outlined, color: Colors.black45),
              label: const Text('Evine gönder', style: TextStyle(color: Colors.black45)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat', style: TextStyle(fontSize: 16))),
          ]),
        ]),
      ),
    );
  }
}

/// Bütün arkadaşlar ve yeni arkadaş düğmesi. Dönüş: (arkadaş sırası, emir) ya da null.
class FriendsDialog extends StatelessWidget {
  final List<Friend> friends;
  const FriendsDialog(this.friends, {super.key});

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFF3E5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('👥 Arkadaşlarım', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text('Henüz arkadaşın yok. Haydi bir tane oluştur!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 330),
              child: SingleChildScrollView(
                child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                  for (var i = 0; i < friends.length; i++)
                    Bouncy(
                      onTap: () => Navigator.pop(context, i),
                      child: Container(
                        width: 92,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          SizedBox(width: 60, height: 76, child: CustomPaint(painter: AvatarPainter(friends[i].look, 0.5))),
                          FittedBox(child: SylText(friends[i].name, size: 17)),
                          Text(const ['👣 geliyor', '✋ bekliyor', '🚶 işe gidiyor', '🔨 çalışıyor'][friends[i].mode],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), minimumSize: const Size(220, 52)),
              onPressed: () => Navigator.pop(context, -1),
              icon: const Icon(Icons.person_add, size: 26),
              label: const Text('Yeni arkadaş', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat', style: TextStyle(fontSize: 16))),
          ]),
        ),
      );
}

/// Adlı yerler listesi (adalar, köyler): dokununca oraya gidilir.
class PlacesDialog extends StatelessWidget {
  final List<String> names;
  const PlacesDialog(this.names, {super.key});

  @override
  Widget build(BuildContext context) {
    Voice.say('Nereye gidelim?');
    final islands = names.where((n) => n.endsWith('Adası')).toList();
    final villages = names.where((n) => !n.endsWith('Adası')).toList();
    Widget group(String title, List<String> l, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final n in l)
              Bouncy(
                onTap: () => Navigator.pop(context, n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
                  child: SylText(n.split(' ').first, size: 17),
                ),
              ),
          ]),
        ]);
    return Dialog(
      backgroundColor: const Color(0xFFE0F7FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('📍 Nereye gidelim?', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            if (islands.isNotEmpty) group('🏝️ Adalar', islands, const Color(0xFFB3E5FC)),
            if (villages.isNotEmpty) group('🏘️ Köyler', villages, const Color(0xFFC8E6C9)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç', style: TextStyle(fontSize: 16))),
          ]),
        ),
      ),
    );
  }
}

/// Yer adı tabelası (büyük, uzaktan görünür)
void paintPlace(Canvas canvas, Offset at, String name, {double scale = 1}) {
  final island = name.endsWith('Adası');
  final tp = TextPainter(
      text: TextSpan(
          text: '${island ? '🏝️' : '🏘️'} $name',
          style: TextStyle(fontSize: 19 * scale, fontWeight: FontWeight.w900, color: Colors.white)),
      textDirection: TextDirection.ltr)
    ..layout();
  final r = Rect.fromCenter(center: at, width: tp.width + 20 * scale, height: tp.height + 10 * scale);
  canvas.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(2, 3)), const Radius.circular(12)), Paint()..color = Colors.black26);
  canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)),
      Paint()..color = island ? const Color(0xEE0277BD) : const Color(0xEE2E7D32));
  tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
}

double friendDist(Friend f, double x, double y) => sqrt(pow(f.x - x, 2) + pow(f.y - y, 2));

/// Hazır yapının adı (arkadaş konuşmaları için)
String jobName(String id) => friendJobs.firstWhere((j) => j.$1 == id, orElse: () => (id, 'yapı', '🏗️')).$2;

// ================= KÖYLÜLER (adalarda ve köylerde yaşayan insanlar) =================

class Villager {
  final String name, place;
  final Avatar look;
  final int hx, hy, baseZ; // evinin önü (meydan) ve zemin yüksekliği
  double x, y, z, facing = 0, walk = 0, wait = 0;
  (int, int)? target;
  Villager(this.name, this.place, this.look, this.hx, this.hy, this.baseZ, this.x, this.y, this.z);
}

const _menNames = ['Ahmet', 'Mehmet', 'Mustafa', 'Hasan', 'Hüseyin', 'İbrahim', 'Halil', 'Yakup', 'Bilal', 'Osman', 'Salih', 'Veli'];
const _womenNames = ['Fatma', 'Ayşe', 'Emine', 'Hatice', 'Zehra', 'Hacer', 'Rukiye', 'Havva', 'Saliha', 'Sümeyye', 'Kübra', 'Esma'];

/// Her yere iki-üç köylü: adı, görünüşü yerin adından türetilir (her açılışta aynı).
List<Villager> makeVillagers(Map<String, (int, int)> places, int Function(int, int) topZ) {
  final out = <Villager>[];
  for (final e in places.entries) {
    final r = Random(e.key.hashCode);
    final (cx, cy) = e.value;
    final base = topZ(cx, cy);
    final n = e.key.endsWith('Köyü') ? 3 : 2;
    // köy ve ada dışındaki yerler (üsler, kraterler) astronotlarla dolu
    final space = !e.key.endsWith('Köyü') && !e.key.endsWith('Adası');
    for (var i = 0; i < n; i++) {
      final woman = r.nextBool();
      final name = woman ? _womenNames[r.nextInt(_womenNames.length)] : _menNames[r.nextInt(_menNames.length)];
      final look = space
          ? Avatar.decode('${r.nextInt(skinColors.length)},${r.nextInt(hairColors.length)},2,7,7,4,0,0,0')!
          : Avatar.decode('${r.nextInt(skinColors.length)},${r.nextInt(hairColors.length)},${woman ? 1 : (r.nextBool() ? 4 : 0)},'
              '${r.nextInt(clothColors.length)},${r.nextInt(clothColors.length)},${r.nextInt(hatColors.length)},0,0,0')!;
      final x = cx + 0.5 + (i - 1) * 1.2, y = cy + 0.5;
      out.add(Villager(name, e.key, look, cx, cy, base, x, y, base + 1.0));
    }
  }
  return out;
}

/// "Darende Köyü" -> "Darende köyüne", "Malatya Adası" -> "Malatya adasına"
String placeTo(String key) {
  final base = key.split(' ').first;
  if (key.endsWith('Köyü')) return '$base köyüne';
  if (key.endsWith('Adası')) return '$base adasına';
  // "Ay Üssü'ne", "Olimpos Dağı'na", "Ay'a", "Mars'a"
  const back = 'aıou', vowels = 'aıoueiöü';
  final low = key.toLowerCase();
  String? last;
  for (var i = low.length - 1; i >= 0; i--) {
    if (vowels.contains(low[i])) {
      last = low[i];
      break;
    }
  }
  final b = last == null || back.contains(last);
  final endsVowel = vowels.contains(low[low.length - 1]);
  return "$key'${endsVowel ? 'n' : ''}${b ? 'a' : 'e'}";
}
