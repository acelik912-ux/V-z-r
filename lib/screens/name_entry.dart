import 'package:flutter/material.dart';

import '../syllables.dart';
import '../voice.dart';
import '../widgets/common.dart';

/// Büyük harfli çocuk klavyesiyle isim yazma. Her harften sonra yazılan isim sesli okunur.
class NameEntryScreen extends StatefulWidget {
  final String prompt;
  final String? speech;
  final String initial;
  const NameEntryScreen({super.key, required this.prompt, this.speech, this.initial = ''});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  static final _letters = 'abcçdefgğhıijklmnoöprsştuüvyz'.split('');
  String text = '';
  String? warning;

  @override
  void initState() {
    super.initState();
    text = trLower(widget.initial);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Voice.say(widget.speech ?? widget.prompt);
    });
  }

  void _add(String ch) {
    if (text.length >= 12) return;
    setState(() {
      text += ch;
      warning = null;
    });
    Voice.say(trCapitalize(text));
  }

  void _del() {
    if (text.isEmpty) return;
    setState(() => text = text.substring(0, text.length - 1));
  }

  void _done() {
    if (text.length < 2) {
      Voice.say('En az iki harf yazmalısın.');
      return;
    }
    if (isBadWord(text)) {
      setState(() => warning = 'Başka bir isim deneyelim.');
      Voice.say('Başka bir isim deneyelim.');
      return;
    }
    final name = trCapitalize(text);
    Voice.say('Harika! $name');
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE082),
        title: Text(widget.prompt, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 90,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8D6E63), width: 3),
              ),
              child: text.isEmpty
                  ? const Text('_ _ _', style: TextStyle(fontSize: 40, color: Colors.black26))
                  : FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: SylText(trCapitalize(text), size: 48))),
            ),
            if (warning != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(warning!, style: const TextStyle(fontSize: 18, color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Voice.say(text.isEmpty ? widget.prompt : trCapitalize(text)),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Dinle', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _del,
                      icon: const Icon(Icons.backspace),
                      label: const Text('Sil', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final ch in _letters)
                    Material(
                      color: isVowel(ch) ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _add(ch),
                        child: Center(
                          child: Text(
                            ch,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: isVowel(ch) ? vowelColor : consColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _done,
                  icon: const Icon(Icons.check, size: 32),
                  label: const Text('Tamam', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
