import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'sfx.dart';
import 'state.dart';
import 'voice.dart';
import 'widgets/common.dart';

/// Görsel dosyaları (assets/img/*.webp).
String img(String name) => 'assets/img/$name.webp';

class Pic extends StatelessWidget {
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;
  const Pic(this.name, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) => Image.asset(
        img(name),
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
      );
}

/// Tam ekran arka plan resmi.
BoxDecoration bgDeco(String name) => BoxDecoration(
      color: const Color(0xFF87CEEB),
      image: DecorationImage(image: AssetImage(img(name)), fit: BoxFit.cover, filterQuality: FilterQuality.medium),
    );

/// Arka plan resmi üzerindeki bir noktayı (resim pikseli) ekran konumuna çevirir (BoxFit.cover).
Offset coverPoint(Size screen, Size image, Offset p) {
  final s = max(screen.width / image.width, screen.height / image.height);
  final dx = (screen.width - image.width * s) / 2;
  final dy = (screen.height - image.height * s) / 2;
  return Offset(dx + p.dx * s, dy + p.dy * s);
}

// ---------------- Karakterler ----------------

enum Who { tamirci, baykus, tozbulut, robot, papagan, surucu }

const whoNames = {
  Who.tamirci: 'Tamirci Usta',
  Who.baykus: 'Hece Baykuş',
  Who.tozbulut: 'Tozbulut',
  Who.robot: 'Robot Rakam',
  Who.papagan: 'Polly',
  Who.surucu: 'Sürücü',
};

/// Karakterin pozuna göre resim adı.
String whoPic(Who w, [String mood = '']) {
  switch (w) {
    case Who.tamirci:
      return const {'iyi': 'k_tamirci_iyi', 'dusun': 'k_tamirci_dusun', 'saskin': 'k_tamirci_saskin', 'sevin': 'k_tamirci_sevin'}[mood] ??
          'k_tamirci';
    case Who.baykus:
      return const {'saskin': 'k_baykus_saskin', 'okur': 'k_baykus_okur', 'gosterir': 'k_baykus_gosterir', 'uyur': 'k_baykus_uyur'}[
              mood] ??
          'k_baykus';
    case Who.tozbulut:
      return const {'uzgun': 'k_tozbulut_uzgun', 'gul': 'k_tozbulut_gul', 'selam': 'k_tozbulut_selam', 'anlat': 'k_tozbulut_anlat'}[
              mood] ??
          'k_tozbulut';
    case Who.robot:
      return 'k_robot';
    case Who.papagan:
      return 'k_papagan';
    case Who.surucu:
      return 'k_surucu';
  }
}

/// Karakter + konuşma balonu. Ekranın altına yerleştirilir.
class Talker extends StatelessWidget {
  final Who who;
  final String text;
  final String mood;
  final double size;
  final bool right;
  const Talker(this.who, this.text, {super.key, this.mood = '', this.size = 120, this.right = false});

  @override
  Widget build(BuildContext context) {
    final pic = SizedBox(width: size * 0.8, height: size, child: Pic(whoPic(who, mood), height: size));
    final bubble = Flexible(
      child: Container(
        margin: EdgeInsets.only(bottom: size * 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: right ? [bubble, pic] : [pic, bubble],
    );
  }
}

/// Ekranın üstünde birkaç saniye görünen karakter balonu ve sesli konuşma.
class Say {
  static OverlayEntry? _entry;
  static Timer? _t;

  static void show(BuildContext context, Who who, String text, {String mood = '', bool speak = true, String? speech}) {
    if (speak) Voice.say(speech ?? text);
    _t?.cancel();
    _entry?.remove();
    _entry = null;
    final ov = Overlay.maybeOf(context);
    if (ov == null) return;
    final e = OverlayEntry(
      builder: (_) => Positioned(
        left: 8,
        right: 8,
        bottom: 8,
        child: IgnorePointer(
          child: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.translate(offset: Offset(0, (1 - v) * 120), child: child),
              child: Material(type: MaterialType.transparency, child: Talker(who, text, mood: mood)),
            ),
          ),
        ),
      ),
    );
    _entry = e;
    ov.insert(e);
    final ms = 2500 + text.length * 70;
    _t = Timer(Duration(milliseconds: ms), hide);
  }

  static void hide() {
    _t?.cancel();
    _entry?.remove();
    _entry = null;
  }
}

// ---------------- Geçişler ve efektler ----------------

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(c), child: child),
        );
      },
    );

Future<T?> go<T>(BuildContext context, Widget page) {
  Sfx.play('click');
  Say.hide();
  return Navigator.push<T>(context, fadeRoute<T>(page));
}

/// Konfeti yağmuru.
class Confetti extends StatefulWidget {
  final int count;
  const Confetti({super.key, this.count = 70});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..forward();
  final _r = Random();
  late final List<List<double>> _p = [
    for (var i = 0; i < widget.count; i++)
      [_r.nextDouble(), -_r.nextDouble() * 0.6, 0.25 + _r.nextDouble() * 0.5, _r.nextDouble() * 6, _r.nextInt(6).toDouble()]
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_p, _c.value), size: Size.infinite),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  final List<List<double>> p;
  final double t;
  _ConfettiPainter(this.p, this.t);
  static const _cols = [Colors.red, Colors.amber, Colors.green, Colors.blue, Colors.purple, Colors.orange];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final q in p) {
      final y = (q[1] + t * (0.9 + q[2])) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      final x = (q[0] + sin(t * 6 + q[3]) * 0.03) * size.width;
      paint.color = _cols[q[4].toInt()].withAlpha((255 * (1 - max(0.0, t - 0.75) * 4)).clamp(0, 255).toInt());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 10 + q[3]);
      canvas.drawRect(const Rect.fromLTWH(-5, -3, 10, 6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// 0-3 yıldız gösterimi.
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarRow(this.stars, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Opacity(opacity: i < stars ? 1 : 0.25, child: Pic('i_yildiz', width: size, height: size)),
        ],
      );
}

/// Resimli büyük menü kartı.
class PicCard extends StatelessWidget {
  final String pic;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool locked;
  final Widget? badge;
  final Widget? child;
  const PicCard(
      {super.key, required this.pic, required this.label, required this.color, required this.onTap, this.locked = false, this.badge, this.child});

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Opacity(opacity: locked ? 0.5 : 1, child: child ?? Pic(pic)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black45, offset: Offset(1, 2), blurRadius: 2)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (locked) const Positioned(top: 6, right: 6, child: Pic('i_kilit', width: 34, height: 34)),
            if (badge != null) Positioned(top: 6, left: 8, child: badge!),
          ],
        ),
      ),
    );
  }
}

/// Dokununca hafifçe küçülüp büyüyen sarmalayıcı.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.93 : 1,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      );
}

/// Ekranın üstündeki ortak çubuk: geri, başlık, ödüller.
class TopBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Color textColor;
  const TopBar(this.title, {super.key, this.trailing, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          RoundIcon(Icons.arrow_back, () {
            Sfx.play('click');
            Say.hide();
            Navigator.maybePop(context);
          }),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
                shadows: const [Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 3)],
              ),
            ),
          ),
          trailing ?? const SizedBox(),
        ],
      ),
    );
  }
}

/// Kelimeye uygun küçük resim (emoji).
const wordEmoji = <String, String>{
  'el': '✋', 'kek': '🍰', 'anne': '👩', 'inek': '🐄', 'kale': '🏰',
  'top': '⚽', 'mum': '🕯️', 'kum': '🏖️', 'ok': '🏹', 'kol': '💪', 'ay': '🌙', 'elma': '🍎',
  'kalem': '✏️', 'ütü': '👕', 'yemek': '🍲', 'okul': '🏫', 'kutu': '📦', 'kütük': '🪵', 'ata': '🐴',
  'araba': '🚗', 'arı': '🐝', 'kayık': '🛶', 'baba': '👨', 'dede': '👴', 'balık': '🐟', 'saat': '⏰', 'masa': '🪑',
  'kedi': '🐱', 'düdük': '📯', 'bulut': '☁️', 'ödül': '🏆', 'börek': '🥐', 'dere': '🏞️', 'balon': '🎈',
  'kabak': '🎃', 'sabun': '🧼', 'çocuk': '🧒', 'göz': '👁️', 'kapı': '🚪', 'şeker': '🍬', 'yeşil': '💚',
  'kırmızı': '❤️', 'güneş': '☀️', 'çorap': '🧦', 'kuş': '🐦', 'deniz': '🌊', 'üzüm': '🍇',
  'çiçek': '🌷', 'şapka': '🎩', 'köpek': '🐶', 'gözlük': '👓', 'ev': '🏠', 'fil': '🐘',
  'horoz': '🐓', 'tavşan': '🐰', 'vapur': '🛳️', 'ağaç': '🌳', 'dağ': '⛰️', 'yağmur': '🌧️',
  'havlu': '🧺', 'fırın': '🍞', 'kavun': '🍈', 'nine': '👵', 'ekmek': '🍞', 
};

String emojiFor(String w) => wordEmoji[trLowerSafe(w)] ?? '⭐';
String trLowerSafe(String s) => s.toLowerCase();

/// Ses: yıldızla bitiş.
Future<void> cheer(int stars) async {
  Sfx.play(stars >= 3 ? 'finish' : 'correct');
  if (game.sfxOn) Sfx.play('unlock', volume: 0.6);
}

/// Canvas'a çizilecek resimler için önbellek.
class Img {
  static final Map<String, ui.Image> _cache = {};
  static ui.Image? get(String name) => _cache[name];

  static Future<void> load(List<String> names) async {
    final futures = <Future<void>>[];
    for (final n in names) {
      if (_cache.containsKey(n)) continue;
      final c = Completer<void>();
      final stream = AssetImage(img(n)).resolve(ImageConfiguration.empty);
      late final ImageStreamListener l;
      l = ImageStreamListener((info, _) {
        _cache[n] = info.image;
        stream.removeListener(l);
        if (!c.isCompleted) c.complete();
      }, onError: (_, __) {
        if (!c.isCompleted) c.complete();
      });
      stream.addListener(l);
      futures.add(c.future);
    }
    await Future.wait(futures);
  }

  static void draw(Canvas canvas, String name, Rect dst, {double opacity = 1}) {
    final im = _cache[name];
    if (im == null) return;
    final fit = applyBoxFit(BoxFit.contain, Size(im.width.toDouble(), im.height.toDouble()), dst.size);
    final out = Alignment.bottomCenter.inscribe(fit.destination, dst);
    canvas.drawImageRect(
      im,
      Offset.zero & Size(im.width.toDouble(), im.height.toDouble()),
      out,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(0, 0, 0, opacity),
    );
  }
}
