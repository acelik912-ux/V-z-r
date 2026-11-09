import 'package:flutter/material.dart';

import '../catalog.dart';
import '../state.dart';
import '../syllables.dart';

const vowelColor = Color(0xFFD32F2F);
const consColor = Color(0xFF1565C0);

/// Ünlüler kırmızı, ünsüzler mavi.
TextSpan sylSpan(String s, double size, {FontWeight weight = FontWeight.w800}) {
  return TextSpan(
    children: [
      for (final ch in s.split(''))
        TextSpan(
          text: ch,
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: isVowel(ch) ? vowelColor : consColor,
          ),
        ),
    ],
  );
}

class SylText extends StatelessWidget {
  final String text;
  final double size;
  const SylText(this.text, {super.key, this.size = 32});

  @override
  Widget build(BuildContext context) => RichText(text: sylSpan(text, size));
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}

class RewardBar extends StatelessWidget {
  const RewardBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pill('⭐ ${game.stars}'),
          const SizedBox(width: 6),
          Pill('❤️ ${game.hearts}'),
          const SizedBox(width: 6),
          Pill('🏆 ${game.cups}'),
        ],
      ),
    );
  }
}

class FuelGauge extends StatelessWidget {
  const FuelGauge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final f = game.fuelFraction;
        final mins = (game.fuelLeftSec / 60).ceil();
        final c = f < 0.2 ? Colors.red : (f < 0.5 ? Colors.orange : Colors.green);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(220), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station, color: c),
              const SizedBox(width: 4),
              SizedBox(
                width: 54,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: f, minHeight: 10, color: c, backgroundColor: Colors.black12),
                ),
              ),
              const SizedBox(width: 6),
              Text('$mins dk', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  const BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Material(
        color: color,
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 56, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (locked)
                const Positioned(top: 10, right: 12, child: Icon(Icons.lock, color: Colors.white, size: 26)),
            ],
          ),
        ),
      ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const RoundIcon(this.icon, this.onTap, {super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(230),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 28, color: Colors.black87)),
      ),
    );
  }
}

String reqText(Req r) {
  final parts = <String>[
    if (r.stars > 0) '${r.stars} bilgi yıldızı',
    if (r.hearts > 0) '${r.hearts} iyilik kalbi',
    if (r.cups > 0) '${r.cups} kupa',
  ];
  return 'Bunun için ${parts.join(' ve ')} lazım.';
}

String reqShort(Req r) {
  final parts = <String>[
    if (r.stars > 0) '⭐${r.stars}',
    if (r.hearts > 0) '❤️${r.hearts}',
    if (r.cups > 0) '🏆${r.cups}',
  ];
  return parts.join(' ');
}

String ordinal(int n) {
  const o = ['birinci', 'ikinci', 'üçüncü', 'dördüncü'];
  return n >= 1 && n <= o.length ? o[n - 1] : '$n.';
}
