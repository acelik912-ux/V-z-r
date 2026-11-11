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

  String get message => night ? 'Arabanın uyku vakti geldi.\nİyi geceler!\nYarın görüşürüz.' : campfireStory();

  /// Kamp ateşi özeti: o gün yapılanları masal gibi anlatır, yarına tatlı bir merak bırakır.
  static String campfireStory() {
    final t = game.today;
    final parts = <String>['Güneş battı, kamp ateşi yandı. Bugün ne güzel bir gündü!'];
    final hece = t['hece'] ?? 0;
    if (hece > 0) parts.add('Tam $hece hece okudun.');
    final w = game.todayWords;
    if (w.isNotEmpty) {
      parts.add('Tezgâhta ${w.take(3).join(', ')} yaptın.');
    }
    if ((t['iyilik'] ?? 0) > 0) parts.add('Komşulara yardım ettin, Allah razı olsun.');
    if ((t['satis'] ?? 0) > 0) parts.add('Pazarda para üstünü doğru verdin.');
    if (parts.length == 1) parts.add('Birlikte oynadık, çok eğlendik.');
    parts.add('Şimdi gözlerimizi dinlendirme vakti. Yarın sabah mağaradaki sürpriz yumurta çatlayacak. İçinden ne çıkacak acaba?');
    return parts.join(' ');
  }

  @override
  void initState() {
    super.initState();
    if (!night && game.surpriseDay.isEmpty) {
      game.surpriseDay = game.dayKey;
      game.save();
    }
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
    if (!night) return _campfire(context);
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
                child: const ParentButton(dark: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campfire(BuildContext context) => Material(
        color: const Color(0xFF1A1A3A),
        child: Container(
          decoration: bgDeco('kamp_atesi'),
          child: SafeArea(
            child: Stack(children: [
              Positioned(
                left: 14,
                right: 14,
                top: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xCC1A1A3A), borderRadius: BorderRadius.circular(24)),
                  child: Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const SizedBox(height: 190, child: Pic('k_ayi', height: 190)),
                  const SizedBox(height: 160, child: Pic('k_teyze_sevin', height: 160)),
                ]),
              ),
              Positioned(
                left: 76,
                right: 8,
                bottom: 26,
                child: Text('Kitap okursan annen ya da baban süreyi uzatabilir.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(200))),
              ),
              Positioned(
                left: 4,
                bottom: 4,
                child: const ParentButton(dark: true),
              ),
            ]),
          ),
        ),
      );
}

/// Süre bitmeden 3 dakika önce: uykucu ayı esner, güneşin battığını haber verir.
class WindDownBanner extends StatefulWidget {
  const WindDownBanner({super.key});

  @override
  State<WindDownBanner> createState() => _WindDownBannerState();
}

class _WindDownBannerState extends State<WindDownBanner> {
  static DateTime? _said;

  @override
  void initState() {
    super.initState();
    if (_said != game.windDownAt) {
      _said = game.windDownAt;
      Voice.say('Hıı, uykum geldi! Güneş batmak üzere. Üç dakika sonra kamp ateşinde buluşalım. İşini bitirmeye başla!');
    }
  }

  @override
  Widget build(BuildContext context) => Positioned(
        left: 8,
        right: 8,
        top: 40,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xEE3949AB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: const Row(children: [
                SizedBox(width: 74, height: 90, child: Pic('k_ayi_esne', height: 90)),
                SizedBox(width: 8),
                Expanded(
                  child: Text('🌅 Güneş batıyor... 3 dakika sonra kamp ateşinde buluşalım!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ]),
            ),
          ),
        ),
      );
}
