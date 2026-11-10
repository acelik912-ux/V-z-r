import 'package:flutter/material.dart';

import '../art.dart';
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
      child: Container(
        decoration: bgDeco(night ? 'kilit_gece' : 'kilit_benzin'),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                top: 40,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (night ? const Color(0xFF1A237E) : Colors.white).withAlpha(200),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: night ? Colors.white : Colors.brown.shade900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 170, child: Pic(night ? 'k_baykus_uyur' : 'k_tamirci_iyi')),
                    CarView(game.config, width: 170),
                  ],
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
      ),
    );
  }
}
