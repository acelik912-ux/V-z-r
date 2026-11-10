import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'car_model.dart';
import 'renderer.dart';
import 'vec.dart';

/// Hareketsiz 3D araba görüntüsü (ana ekran, kilit ekranı, küçük resimler).
class CarView extends StatelessWidget {
  final CarConfig config;
  final double width;
  final double yaw;
  final double pitch;
  final bool shadow;
  const CarView(this.config, {super.key, this.width = 120, this.yaw = 0.75, this.pitch = 0.32, this.shadow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.72,
      child: CustomPaint(painter: _StaticCarPainter(config, yaw, pitch, shadow)),
    );
  }
}

class _StaticCarPainter extends CustomPainter {
  final CarConfig cfg;
  final double yaw, pitch;
  final bool shadow;
  _StaticCarPainter(this.cfg, this.yaw, this.pitch, this.shadow);

  @override
  void paint(Canvas canvas, Size size) {
    final cam = Camera(
      center: Offset(size.width / 2, size.height * 0.74),
      scale: size.width / 5.4,
      yaw: yaw,
      pitch: pitch,
    );
    paintCar(canvas, cfg, cam, shadow: shadow);
  }

  @override
  bool shouldRepaint(_StaticCarPainter old) => old.cfg != cfg || old.yaw != yaw || old.pitch != pitch;
}

/// Kendi kendine yavaşça dönen araba (ana ekran).
class SpinningCar extends StatefulWidget {
  final CarConfig config;
  final double width;
  const SpinningCar(this.config, {super.key, this.width = 220});

  @override
  State<SpinningCar> createState() => _SpinningCarState();
}

class _SpinningCarState extends State<SpinningCar> with SingleTickerProviderStateMixin {
  late final Ticker _t;
  double yaw = 0.8;

  @override
  void initState() {
    super.initState();
    _t = createTicker((d) => setState(() => yaw = 0.8 + d.inMilliseconds / 1000 * 0.5))..start();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarView(widget.config, width: widget.width, yaw: yaw, pitch: 0.3);
}

/// Garajdaki etkileşimli stüdyo: parmakla döndür, iki parmakla yakınlaştır.
class CarViewer extends StatefulWidget {
  final CarConfig config;
  final bool lightsOn;
  final bool autoRotate;
  final bool revving;
  final VoidCallback? onTap;
  final bool background;
  const CarViewer({
    super.key,
    required this.config,
    this.lightsOn = false,
    this.autoRotate = true,
    this.revving = false,
    this.onTap,
    this.background = true,
  });

  @override
  State<CarViewer> createState() => CarViewerState();
}

class CarViewerState extends State<CarViewer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double yaw = 0.75;
  double pitch = 0.3;
  double zoom = 1.0;
  double _spinVel = 0;
  double _time = 0;
  bool _touching = false;
  double _startZoom = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void reset() => setState(() {
        yaw = 0.75;
        pitch = 0.3;
        zoom = 1;
        _spinVel = 0;
      });

  void _tick(Duration now) {
    var dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt > 0.05) dt = 0.05;
    _time += dt;
    if (!_touching) {
      if (_spinVel.abs() > 0.01) {
        yaw += _spinVel * dt;
        _spinVel *= math.pow(0.04, dt).toDouble();
      } else if (widget.autoRotate) {
        yaw += 0.35 * dt;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: reset,
      onScaleStart: (d) {
        _touching = true;
        _startZoom = zoom;
        _spinVel = 0;
      },
      onScaleUpdate: (d) {
        setState(() {
          yaw += d.focalPointDelta.dx * 0.012;
          pitch = (pitch + d.focalPointDelta.dy * 0.006).clamp(0.05, 1.2).toDouble();
          if (d.pointerCount > 1) zoom = (_startZoom * d.scale).clamp(0.6, 2.2).toDouble();
          _spinVel = d.focalPointDelta.dx * 0.012 * 60;
        });
      },
      onScaleEnd: (d) {
        _touching = false;
      },
      child: CustomPaint(
        painter: _StudioPainter(
          widget.config,
          yaw,
          pitch,
          zoom,
          widget.lightsOn,
          widget.revving ? 0.012 * math.sin(_time * 70) : 0,
          _time,
          widget.background,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StudioPainter extends CustomPainter {
  final CarConfig cfg;
  final double yaw, pitch, zoom, bob, time;
  final bool lightsOn;
  final bool background;
  _StudioPainter(this.cfg, this.yaw, this.pitch, this.zoom, this.lightsOn, this.bob, this.time, [this.background = true]);

  @override
  void paint(Canvas canvas, Size size) => paintStudio(canvas, size, cfg, yaw, pitch, zoom, lightsOn, bob, background: background);

  @override
  bool shouldRepaint(_StudioPainter old) => true;
}

/// Garaj stüdyosu: arka plan, döner platform, yansımalı araba.
void paintStudio(Canvas canvas, Size size, CarConfig cfg, double yaw, double pitch, double zoom, bool lightsOn, double bob,
    {bool background = true}) {
  final rect = Offset.zero & size;
  // Stüdyo arka planı
  if (background) canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.1,
        colors: lightsOn
            ? const [Color(0xFF263238), Color(0xFF0B0F12)]
            : const [Color(0xFFECEFF1), Color(0xFF90A4AE)],
      ).createShader(rect),
  );
  final scale = math.min(size.width / 6.2, size.height / 4.2) * zoom;
  final cam = Camera(
    center: Offset(size.width / 2, size.height * 0.66),
    scale: scale,
    yaw: yaw,
    pitch: pitch,
  );
  // Döner platform
  const rT = 3.0;
  final disc = <Offset>[];
  for (var i = 0; i < 48; i++) {
    final a = i / 48 * 2 * math.pi;
    disc.add(cam.project(V3(rT * math.cos(a), 0, rT * math.sin(a))));
  }
  canvas.drawPath(
    Path()..addPolygon(disc, true),
    Paint()..color = (lightsOn ? const Color(0xFF37474F) : const Color(0xFFCFD8DC)).withAlpha(background ? 255 : 150),
  );
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = lightsOn ? const Color(0xFF546E7A) : const Color(0xFFB0BEC5);
  canvas.drawPath(Path()..addPolygon(disc, true), ring);
  for (var i = 0; i < 12; i++) {
    final a = i / 12 * 2 * math.pi;
    canvas.drawLine(
      cam.project(V3(2.6 * math.cos(a), 0, 2.6 * math.sin(a))),
      cam.project(V3(2.9 * math.cos(a), 0, 2.9 * math.sin(a))),
      ring,
    );
  }
  paintCar(canvas, cfg, cam, lightsOn: lightsOn, reflection: true, bob: bob);
}
