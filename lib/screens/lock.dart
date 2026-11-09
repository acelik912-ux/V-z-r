import 'package:flutter/material.dart';

import '../state.dart';
import '../voice.dart';
import '../car3d/car_view.dart';
import 'parent.dart';

/// Yakıt bitince ya da gece olunca çıkan, oyunu kapatan ekran.
class LockScreen extends StatefulWidget {
  final String reason;
  const LockScreen({super.key, required this.reason});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool get night => widget.reason == 'night';

  String get message => night
      ? 'Arabanın uyku vakti geldi.\nİyi geceler!\nYarın görüşürüz.'
      : 'Benzin bitti!\nBugünlük bu kadar, yarın yine yarışırız.\nKitap okursan annen ya da baban depoyu doldurabilir.';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Voice.say(message.replaceAll('\n', ' '));
    });
  }

  @override
  void didUpdateWidget(LockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reason != widget.reason) Voice.say(message.replaceAll('\n', ' '));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: night ? const Color(0xFF1A237E) : const Color(0xFFFFE0B2),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(night ? '🌙  Zzz' : '⛽', style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    CarView(game.config, width: 220),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: night ? Colors.white : Colors.brown.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: GestureDetector(
                onLongPress: openParentPanel,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.settings, color: night ? Colors.white24 : Colors.black26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
