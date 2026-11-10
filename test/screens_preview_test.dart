import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vizir/games/araba_yikama.dart';
import 'package:vizir/games/blok.dart';
import 'package:vizir/games/hece_kamyonu.dart';
import 'package:vizir/games/kasaba.dart';
import 'package:vizir/games/liman.dart';
import 'package:vizir/games/orman.dart';
import 'package:vizir/games/registry.dart';
import 'package:vizir/games/sayi.dart';
import 'package:vizir/games/ucan_araba.dart';
import 'package:vizir/screens/album.dart';
import 'package:vizir/screens/garage.dart';
import 'package:vizir/screens/home.dart';
import 'package:vizir/screens/lock.dart';
import 'package:vizir/screens/map.dart';
import 'package:vizir/screens/result.dart';
import 'package:vizir/screens/stories.dart';
import 'package:vizir/state.dart';
import 'package:vizir/voice.dart';

/// Ekran görüntüleri: previews/ekran_*.png
Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf', 'Roboto-Medium.ttf']) {
    final file = File('$dir/$f');
    if (file.existsSync()) roboto.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
  }
  await roboto.load();
  final icons = File('$dir/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)))).load();
  }
  for (final p in ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf', '/usr/share/fonts/noto/NotoColorEmoji.ttf']) {
    final e = File(p);
    if (e.existsSync()) {
      await (FontLoader('Emoji')..addFont(Future.value(ByteData.view(e.readAsBytesSync().buffer)))).load();
      break;
    }
  }
}

void main() {
  testWidgets('Ekran önizlemeleri', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Voice.muted = true;
    await tester.runAsync(() async {
      await game.load();
      await _loadFonts();
    });
    game.driverName = 'Yusuf';
    game.carName = 'Şimşek';
    game.neuralVoice = false;
    game.nightLock = false;
    game.stars = 12;
    game.hearts = 3;
    game.cups = 2;
    game.levelStars = {'hece_kamyonu': 3, 'araba_yikama': 2, 'kopru_kur': 1};
    game.stickers = {'arac_10', 'k_robot', 'i_yildiz'};
    game.blockItems = {'kiremit', 'agac', 'tugla', 'cam', 'lale'};
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    Directory('previews').createSync(recursive: true);

    final screens = <String, Widget Function()>{
      'ana': () => const HomeScreen(),
      'harita': () => const MapScreen(),
      'bolge': () => RegionScreen(regions[0]),
      'hece_kamyonu': () => const HeceKamyonu(),
      'yikama': () => const ArabaYikama(),
      'kopru': () => const KopruKur(),
      'tunel': () => const TunelKazisi(),
      'hayvan': () => const HayvanKurtarma(),
      'hafiza': () => const HafizaKartlari(),
      'gemi': () => const GemiYukle(),
      'balik': () => const BalikTut(),
      'ucan': () => const UcanAraba(),
      'otopark': () => const Otopark(),
      'trafik': () => const Trafik(),
      'iyilik': () => const IyilikTeslimati(),
      'blok': () => const BlokAdasi(),
      'hikayeler': () => const StoryShelf(),
      'hikaye': () => StoryReader(stories[0], 0),
      'album': () => const AlbumScreen(),
      'sonuc': () => const ResultScreen(rank: 1, correct: 5, gates: 6, coins: 8, helped: 1),
      'kilit_gece': () => const LockScreen(reason: 'night'),
      'kilit_benzin': () => const LockScreen(reason: 'fuel'),
      'garaj': () => const GarageScreen(),
    };

    final key = GlobalKey();
    for (final e in screens.entries) {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji'], colorSchemeSeed: const Color(0xFFE53935)),
        home: RepaintBoundary(key: key, child: e.value()),
      ));
      // resimleri yükle
      await tester.runAsync(() async {
        final ctx = key.currentContext!;
        final names = Directory('assets/img').listSync().map((f) => f.path.split('/').last.replaceAll('.webp', ''));
        for (final n in names) {
          await precacheImage(AssetImage('assets/img/$n.webp'), ctx);
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.runAsync(() async {
        final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final ui.Image im = await ro.toImage(pixelRatio: 1.0);
        final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
        File('previews/ekran_${e.key}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 20));
    }
  });
}
