import 'package:flutter/material.dart';

import '../state.dart';
import '../syllables.dart';
import 'name_entry.dart';

/// Ebeveyn panelini şifreyle açar. Kilit ekranının üstünden de çalışır.
Future<void> openParentPanel() async {
  final nav = navKey.currentState;
  final ctx = navKey.currentContext;
  if (nav == null || ctx == null) return;
  game.setParentOpen(true);
  try {
    final first = game.pin.isEmpty;
    final entered = await showDialog<String>(
      context: ctx,
      builder: (_) => PinDialog(title: first ? 'Yeni ebeveyn şifresi belirleyin (4 rakam)' : 'Ebeveyn şifresi'),
    );
    if (entered == null) return;
    if (first) {
      game.setPin(entered);
    } else if (entered != game.pin) {
      return;
    }
    await nav.push(MaterialPageRoute(builder: (_) => const ParentPanel()));
  } finally {
    game.setParentOpen(false);
  }
}

class PinDialog extends StatefulWidget {
  final String title;
  const PinDialog({super.key, required this.title});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String code = '';

  void _press(String d) {
    if (code.length >= 4) return;
    setState(() => code += d);
    if (code.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) Navigator.pop(context, code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String d) => Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 64,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _press(d),
              child: Text(d, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            List.generate(4, (i) => i < code.length ? '●' : '○').join(' '),
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 12),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d)]),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 72),
              key('0'),
              Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 64,
                  height: 56,
                  child: IconButton(
                    onPressed: () => setState(() => code = code.isEmpty ? '' : code.substring(0, code.length - 1)),
                    icon: const Icon(Icons.backspace),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç'))],
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
                  final p = await showDialog<String>(
                    context: context,
                    builder: (_) => const PinDialog(title: 'Yeni şifre (4 rakam)'),
                  );
                  if (p != null && context.mounted) {
                    game.setPin(p);
                    _snack(context, 'Şifre değiştirildi');
                  }
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
