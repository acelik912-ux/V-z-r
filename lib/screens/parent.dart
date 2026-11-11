import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sfx.dart';
import '../state.dart';
import '../syllables.dart';
import '../voice.dart';
import 'name_entry.dart';

/// Ebeveyn panelini şifreyle açar. Kilit ekranının üstünden de çalışır.
Future<void> openParentPanel() async {
  final nav = navKey.currentState;
  final ctx = navKey.currentContext;
  if (nav == null || ctx == null) return;
  game.setParentOpen(true);
  try {
    final first = game.pin.isEmpty;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => PinDialog(first: first),
    );
    if (ok != true) return;
    await nav.push(MaterialPageRoute(builder: (_) => const ParentPanel()));
  } finally {
    game.setParentOpen(false);
  }
}

/// Köşedeki ebeveyn düğmesi: büyük dokunma alanı, 1 saniye basılı tutunca
/// dolan halka ile açılır (çocuk kazara açamaz, ebeveyn kolayca açar).
class ParentButton extends StatefulWidget {
  final bool dark;
  const ParentButton({super.key, this.dark = false});

  @override
  State<ParentButton> createState() => _ParentButtonState();
}

class _ParentButtonState extends State<ParentButton> with SingleTickerProviderStateMixin {
  late final AnimationController hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        hold.reset();
        openParentPanel();
      }
    });
  bool hint = false;

  @override
  void dispose() {
    hold.dispose();
    super.dispose();
  }

  void _down() {
    setState(() => hint = false);
    hold.forward(from: 0);
  }

  void _up() {
    if (hold.isAnimating && hold.value < 1) {
      hold.reverse();
      if (hold.value < 0.35) setState(() => hint = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => hint = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.dark ? Colors.white : Colors.black87;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Listener(
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.dark ? Colors.black : Colors.white).withAlpha(110),
                  border: Border.all(color: fg.withAlpha(90), width: 2),
                ),
              ),
              AnimatedBuilder(
                animation: hold,
                builder: (_, __) => SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: hold.value,
                    strokeWidth: 5,
                    color: const Color(0xFFFFC107),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Icon(Icons.lock_person, size: 30, color: fg.withAlpha(200)),
            ]),
          ),
        ),
      ),
      if (hint)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
          child: const Text('Ebeveyn: 1 saniye basılı tutun', style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
    ]);
  }
}

/// Büyük tuşlu şifre ekranı. İlk açılışta şifre belirler (iki kez girilir),
/// yanlış şifrede kapanmaz, uyarır.
class PinDialog extends StatefulWidget {
  final bool first;
  const PinDialog({super.key, this.first = false});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String code = '';
  String? firstEntry;
  String msg = '';
  bool err = false;

  String get title => widget.first
      ? (firstEntry == null ? 'Yeni ebeveyn şifresi belirleyin (4 rakam)' : 'Aynı şifreyi tekrar girin')
      : 'Ebeveyn şifresi';

  void _press(String d) {
    if (code.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      code += d;
      err = false;
      msg = '';
    });
    if (code.length == 4) Future.delayed(const Duration(milliseconds: 180), _check);
  }

  void _check() {
    if (!mounted) return;
    if (widget.first) {
      if (firstEntry == null) {
        setState(() {
          firstEntry = code;
          code = '';
        });
      } else if (firstEntry == code) {
        game.setPin(code);
        Navigator.pop(context, true);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          firstEntry = null;
          code = '';
          err = true;
          msg = 'Şifreler aynı değil, baştan girin.';
        });
      }
      return;
    }
    if (code == game.pin) {
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        code = '';
        err = true;
        msg = 'Şifre yanlış, tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback onTap, {Color? color}) => Padding(
          padding: const EdgeInsets.all(5),
          child: Material(
            color: color ?? const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(width: 84, height: 72, child: Center(child: child)),
            ),
          ),
        );
    Widget digit(String d) => key(Text(d, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)), () => _press(d));
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < code.length ? (err ? Colors.red : const Color(0xFF3949AB)) : Colors.transparent,
                  border: Border.all(color: err ? Colors.red : const Color(0xFF3949AB), width: 2.5),
                ),
              ),
          ]),
          SizedBox(
            height: 28,
            child: Center(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600))),
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) digit(d)]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            key(const Icon(Icons.close, size: 30), () => Navigator.pop(context), color: const Color(0xFFFFEBEE)),
            digit('0'),
            key(const Icon(Icons.backspace_outlined, size: 30),
                () => setState(() => code = code.isEmpty ? '' : code.substring(0, code.length - 1))),
          ]),
          const SizedBox(height: 6),
        ]),
      ),
    );
  }
}

class ParentPanel extends StatelessWidget {
  const ParentPanel({super.key});

  static const _stepNames = ['İki harfli heceler (la, el)', 'Üç harfli heceler (kel, nal)', 'Kelimeler (kale, lale)'];

  Future<void> _rename(BuildContext context, String prompt, String initial, void Function(String) set) async {
    final n = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => NameEntryScreen(prompt: prompt, initial: initial)),
    );
    if (n != null && n.isNotEmpty) set(n);
  }

  void _snack(BuildContext context, String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ebeveyn paneli')),
      body: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          final played = (game.playedSecToday / 60).floor();
          final entries = game.stats.entries.toList()
            ..sort((a, b) {
              final c = b.value[1].compareTo(a.value[1]);
              return c != 0 ? c : (b.value[0] + b.value[1]).compareTo(a.value[0] + a.value[1]);
            });
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _title('Bugün'),
              Text('Oynanan: $played dk  ·  Limit: ${game.dailyLimitMin} dk'
                  '${game.bonusMinToday > 0 ? ' + ${game.bonusMinToday} dk ödül' : ''}'),
              Text('Toplam yarış: ${game.races}  ·  ⭐ ${game.stars}  ❤️ ${game.hearts}  🏆 ${game.cups}'),
              const SizedBox(height: 8),
              Text('Günlük süre: ${game.dailyLimitMin} dakika'),
              Slider(
                value: game.dailyLimitMin.toDouble(),
                min: 10,
                max: 90,
                divisions: 16,
                label: '${game.dailyLimitMin} dk',
                onChanged: (v) => game.setDailyLimit(v.round()),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _snack(
                        context, game.addBonus() ? 'Kitap onaylandı: +10 dk ve 1 yıldız' : 'Bugünkü 2 onay hakkı doldu'),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Kitap okudu +10 dk'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _snack(context,
                        game.addBonus(kindness: true) ? 'İyilik onaylandı: +10 dk ve 1 kalp' : 'Bugünkü 2 onay hakkı doldu'),
                    icon: const Icon(Icons.favorite),
                    label: const Text('İyilik yaptı +10 dk'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gece kilidi (sabah 7\'ye kadar)'),
                value: game.nightLock,
                onChanged: game.setNightLock,
              ),
              if (game.nightLock)
                Row(
                  children: [
                    const Text('Başlangıç saati: '),
                    DropdownButton<int>(
                      value: game.nightHour,
                      items: [for (var h = 19; h <= 23; h++) DropdownMenuItem(value: h, child: Text('$h:00'))],
                      onChanged: (v) {
                        if (v != null) game.setNightHour(v);
                      },
                    ),
                  ],
                ),
              const Divider(height: 32),
              _title('Ses'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ses efektleri (motor, korna, jeton)'),
                value: game.sfxOn,
                onChanged: (v) {
                  game.setSfx(v);
                  if (!v) Sfx.engineStop();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fon müziği'),
                value: game.musicOn,
                onChanged: game.setMusic,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Doğal erkek sesi (önerilen)'),
                subtitle: const Text('Kapalıysa telefonun kendi sesi kullanılır'),
                value: game.neuralVoice,
                onChanged: (v) {
                  game.setNeuralVoice(v);
                  Voice.say('Merhaba! Ben Tamirci Usta. ka, le, kale!');
                },
              ),
              if (!game.neuralVoice) const _VoicePicker(),
              Text('Konuşma hızı: ${(game.speechRate * 100).round()}'),
              Slider(
                value: game.speechRate.clamp(0.25, 0.7).toDouble(),
                min: 0.25,
                max: 0.7,
                divisions: 9,
                onChanged: (v) => game.setSpeech(rate: v),
                onChangeEnd: (_) => Voice.apply().then((_) => Voice.say('Merhaba! Ben Hece Baykuş. ka, le, kale.')),
              ),
              if (!game.neuralVoice) Text('Ses tonu: ${(game.speechPitch * 100).round()}'),
              if (!game.neuralVoice)
                Slider(
                value: game.speechPitch.clamp(0.7, 1.5).toDouble(),
                min: 0.7,
                max: 1.5,
                divisions: 8,
                onChanged: (v) => game.setSpeech(pitch: v),
                onChangeEnd: (_) => Voice.apply().then((_) => Voice.say('Merhaba! Ben Hece Baykuş. ka, le, kale.')),
              ),
              const Divider(height: 32),
              _title('Okuma'),
              const Text('Harf grubu (okulun sırasına göre):'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var g = 1; g <= 5; g++)
                    ChoiceChip(
                      label: Text('$g: ${letterGroups[g - 1].split('').join(' ')}'),
                      selected: game.letterGroup == g,
                      onSelected: (_) => game.setLetterGroup(g),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Basamak:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var s = 1; s <= 3; s++)
                    ChoiceChip(
                      label: Text(_stepNames[s - 1]),
                      selected: game.step == s,
                      onSelected: (_) => game.setStep(s),
                    ),
                ],
              ),
              const Divider(height: 32),
              _title('Gelişim haritası'),
              const Text('Her harf, içinde geçtiği hecelerdeki başarıya göre renklenir. '
                  'Yeşil: oturmuş · Sarı: gelişiyor · Kırmızı: zorlanıyor · Gri: henüz denenmedi'),
              const SizedBox(height: 8),
              const LetterMap(),
              const SizedBox(height: 10),
              Text('Blok Şehri: ${game.crafted.values.fold(0, (a, b) => a + b)} kelime yapıldı · '
                  'çantada ${game.sylBag.values.fold(0, (a, b) => a + b)} hece taşı'),
              if (game.weakSyllables().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Mağarada daha sık çıkacak heceler: ${game.weakSyllables().join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              const Divider(height: 32),
              _title('En çok zorlandığı heceler'),
              if (entries.isEmpty) const Text('Henüz kayıt yok.'),
              for (final e in entries.take(15))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  trailing: Text('✓ ${e.value[0]}   ✗ ${e.value[1]}', style: const TextStyle(fontSize: 16)),
                ),
              const Divider(height: 32),
              _title('İsimler'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Sürücü: ${game.driverName}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _rename(context, 'Sürücünün adı', game.driverName, game.setDriver),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Araba: ${game.carName}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _rename(context, 'Arabanın adı', game.carName, game.setCar),
              ),
              for (var i = 0; i < game.rivalNames.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Rakip ${i + 1}: ${game.rivalNames[i]}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _rename(context, 'Rakibin adı', game.rivalNames[i], (n) => game.setRival(i, n)),
                ),
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => const PinDialog(first: true),
                  );
                  if (ok == true && context.mounted) _snack(context, 'Şifre değiştirildi');
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Şifreyi değiştir'),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      );
}

class _VoicePicker extends StatefulWidget {
  const _VoicePicker();

  @override
  State<_VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends State<_VoicePicker> {
  List<VoiceInfo>? voices;

  @override
  void initState() {
    super.initState();
    Voice.turkishVoices().then((v) {
      if (mounted) setState(() => voices = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = voices;
    if (v == null) return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
    if (v.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Telefonda Türkçe ses bulunamadı. Ayarlar > Genel yönetim > Metin okuma bölümünden '
            'Türkçe ses paketi indirilebilir.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Konuşan ses (dinlemek için dokunun):'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < v.length; i++)
              ChoiceChip(
                label: Text('Ses ${i + 1}${v[i].network ? ' (internet)' : ''}'),
                selected: game.voiceName == v[i].name,
                onSelected: (_) async {
                  game.setVoice(v[i].name, v[i].locale);
                  await Voice.apply();
                  Voice.say('Merhaba! Ben Hece Baykuş. ka, le, kale.');
                  setState(() {});
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Ses gruplarına göre harf harf başarı haritası.
class LetterMap extends StatelessWidget {
  const LetterMap({super.key});

  @override
  Widget build(BuildContext context) {
    final ok = <String, int>{}, bad = <String, int>{};
    for (final e in game.stats.entries) {
      for (final ch in trLower(e.key).split('').toSet()) {
        ok[ch] = (ok[ch] ?? 0) + e.value[0];
        bad[ch] = (bad[ch] ?? 0) + e.value[1];
      }
    }
    Color col(String ch) {
      final o = ok[ch] ?? 0, b = bad[ch] ?? 0;
      if (o + b < 3) return const Color(0xFFE0E0E0);
      final r = o / (o + b);
      if (r >= 0.85) return const Color(0xFFA5D6A7);
      if (r >= 0.65) return const Color(0xFFFFE082);
      return const Color(0xFFEF9A9A);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var g = 0; g < letterGroups.length; g++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(
              width: 64,
              child: Text('${g + 1}. grup', style: TextStyle(fontWeight: game.letterGroup == g + 1 ? FontWeight.w900 : FontWeight.normal)),
            ),
            for (final ch in letterGroups[g].split(''))
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col(ch), borderRadius: BorderRadius.circular(8)),
                child: Text(ch, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
          ]),
        ),
    ]);
  }
}
