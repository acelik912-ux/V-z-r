import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vizir/games/araba_yikama.dart';
import 'package:vizir/games/blok.dart';
import 'package:vizir/games/blok_bag.dart';
import 'package:vizir/games/blok_char.dart';
import 'package:vizir/games/blok_words.dart';
import 'package:vizir/games/blok_village.dart';
import 'package:vizir/games/blok_friends.dart';
import 'package:vizir/games/blok_map.dart';
import 'package:vizir/games/blok_space.dart';
import 'package:vizir/games/blok_globe.dart';
import 'package:vizir/games/blok_treasure.dart';
import 'package:vizir/games/blok_tex.dart';
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
import 'package:vizir/screens/parent.dart';
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
      await Tex.load(texIds);
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
    game.blockItems = {'beyaz', 'altin', 'fener'};
    game.avatar = '0,0,1,3,0,1,1,2';
    game.blockTools = {'kazma', 'kalkan'};
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
      'karakter': () => const AvatarScreen(),
      'blok': () => const BlokAdasi(),
      'blok_ic': () => const BlokAdasi(startFirstPerson: true),
      'blok_arka': () => const BlokAdasi(startFirstPerson: true, startBehind: true),
      'blok_ucus': () => const BlokAdasi(startFirstPerson: true, startBehind: true, startFlying: true),
      'blok_buyuk': () {
        final w = BlockWorld()..seed();
        w.expand(1, 'orman');
        w.expand(0, 'kar');
        w.expand(3, 'gol');
        game.blockWorld = w.encode();
        return const BlokAdasi();
      },
      'blok_dag_gece': () {
        game.blockWorld = (BlockWorld()..seed()).encode();
        return const BlokAdasi(startFocus: (34, 4), startNight: true);
      },
      'canta': () => const BagScreen(selected: 'tahta', shape: 0),
      'koy': () => const VillageScreen(),
      'adalar': () {
        final w = BlockWorld()..seed();
        w.expand(1, 'adalar');
        w.expand(0, 'koyler');
        game.blockWorld = w.encode();
        game.blockFriends = 'Ali~0,0,1,3,0,1,0,0,3~16.0~17.0~1.0~0;Ayşe~1,2,1,5,2,0,0,0,5~18.5~16.0~1.0~0';
        return BlokAdasi(startFocus: (w.places['Darende Adası']!.$1, w.places['Darende Adası']!.$2));
      },
      'zirh_elmas': () => AvatarScreen(friendStart: Avatar.decode('0,0,1,3,0,1,0,0,4')),
      'zirh_osmanli': () => AvatarScreen(friendStart: Avatar.decode('0,0,1,3,0,1,0,0,7')),
      'zirh_yeniceri': () => AvatarScreen(friendStart: Avatar.decode('0,0,1,3,0,1,0,0,8')),
      'zirh_selcuklu': () => AvatarScreen(friendStart: Avatar.decode('0,0,1,3,0,1,0,0,6')),
      'zirh_altin_on': () => AvatarScreen(friendStart: Avatar.decode('0,0,1,3,0,1,0,0,3')),
      'blok_zirh_arka': () {
        game.avatar = '0,0,1,3,0,1,0,0,3';
        return const BlokAdasi(startFirstPerson: true, startBehind: true);
      },
      'zirh_onizleme': () => Scaffold(body: Center(child: ArmorPreview(armors[2]))),
      'zirh_ayi': () => AvatarScreen(friendStart: Avatar.decode('0,0,1,3,0,1,1,2,5')),
      'arkadas_emir': () => Scaffold(
          body: Center(child: FriendOrderDialog(Friend('Ali', Avatar.decode('0,0,1,3,0,1,0,0,4')!, 0, 0, 0)))),
      'harita_buyuk': () {
        final w = BlockWorld()..seed();
        w.expand(1, 'adalar');
        w.expand(0, 'koyler');
        return FutureBuilder(
            future: buildMapImage(w),
            builder: (_, snap) => WorldMapScreen(img: snap.data, px: 17, py: 17, facing: 0.5, places: w.places, friends: const []));
      },
      'blok_ada_yakin': () {
        final w = BlockWorld()..seed();
        w.ensureLands();
        game.blockWorld = w.encode();
        game.blockFriends = '';
        final p = w.places['İstanbul Adası']!;
        return BlokAdasi(startFocus: (p.$1, p.$2));
      },
      'kure': () {
        final w = BlockWorld()..seed();
        w.ensureLands();
        w.inflate(0, Random(3));
        w.inflate(6, Random(4));
        final hw = (maxX - minX) / 2, hh = (maxY - minY) / 2;
        final d = GlobeData(mapPixels(w), maxX - minX + 1, maxY - minY + 1, minX, minY, (minX + maxX) / 2, (minY + maxY) / 2,
            hw * 1.42 + 1, hh * 1.42 + 1);
        final p = w.places['Malatya Köyü']!;
        return GlobeMapScreen(data: d, px: p.$1 + 0.5, py: p.$2 + 0.5, places: w.places, friends: const [], onFlat: () {});
      },
      'muze': () {
        game.treasures = {'yakut', 'firuze', 'kayisi', 'usturlap', 'cini', 'tesbih'};
        return const MuseumScreen();
      },
      'blok_sisik': () {
        final w = BlockWorld()..seed();
        w.ensureLands();
        w.inflate(0, Random(3));
        w.ensureTreasures(Random(2));
        game.blockWorld = w.encode();
        game.blockFriends = '';
        return BlokAdasi(startFocus: ((w.ecx - w.erx * 0.9).round(), w.ecy.round()));
      },
      'yerler': () => const Scaffold(body: Center(child: PlacesDialog(['Sürgü Adası', 'Malatya Adası', 'Harput Köyü', 'Darende Köyü']))),
      'sifre': () => const Scaffold(body: Center(child: PinDialog())),
      'para_ustu': () => const Scaffold(body: Center(child: ChangeDialog(name: 'süt', emoji: '🥛', price: 4))),
      'ingilizce': () => const Scaffold(body: Center(child: EnglishQuiz())),
      'kamp': () {
        game.today = {'hece': 23, 'iyilik': 1};
        game.todayWords = ['inek', 'kale'];
        return const LockScreen(reason: 'fuel');
      },
      'tezgah': () {
        game.sylBag = {'nek': 1, 'ka': 2, 'le': 1, 'kin': 1, 'kil': 1};
        return const WorkbenchScreen();
      },
      'hikayeler': () => const StoryShelf(),
      'hikaye': () => StoryReader(stories[0], 0),
      'album': () => const AlbumScreen(),
      'sonuc': () => const ResultScreen(rank: 1, correct: 5, gates: 6, coins: 8, helped: 1),
      'kilit_gece': () => const LockScreen(reason: 'night'),
      'kilit_benzin': () => const LockScreen(reason: 'fuel'),
      'garaj': () => const GarageScreen(),
      'uzay_kalkis': () => const SpaceScreen(from: 0),
      'uzay_secim': () => const SpaceScreen(from: 0, startPhase: 1),
      'blok_roket': () {
        game.planet = 0;
        final w = BlockWorld()..seed();
        w.ensureLands();
        w.inflate(0, Random(3));
        w.stamp(prefabById('p_roket')!.cells(), 21, 15, 1, 0);
        w.stamp(prefabById('p_ucak')!.cells(), 13, 24, 1, 0);
        w.stamp(prefabById('p_mekik')!.cells(), 27, 26, 1, 0);
        game.blockWorld = w.encode();
        game.blockFriends = '';
        return const BlokAdasi(startFocus: (20, 20));
      },
      'blok_ucak': () => const BlokAdasi(startFirstPerson: true, startBehind: true, startRiding: true),
      'gezegen_ay': () {
        game.planet = 1;
        game.planetWorlds = {};
        return const BlokAdasi();
      },
      'gezegen_ay_arka': () {
        game.planet = 1;
        return const BlokAdasi(startFirstPerson: true, startBehind: true);
      },
      'gezegen_mars': () {
        game.planet = 2;
        return const BlokAdasi();
      },
      'gezegen_kristal': () {
        game.planet = 3;
        return const BlokAdasi();
      },
      'gezegen_mars_kure': () {
        final w = BlockWorld()..seedPlanet(2, Random(1));
        final hw = (maxX - minX) / 2, hh = (maxY - minY) / 2;
        final d = GlobeData(mapPixels(w), maxX - minX + 1, maxY - minY + 1, minX, minY, (minX + maxX) / 2, (minY + maxY) / 2,
            hw * 1.42 + 1, hh * 1.42 + 1);
        game.planet = 0;
        return GlobeMapScreen(title: '🪐 Mars', data: d, px: 0.5, py: 8.5, places: w.places, friends: const [], onFlat: () {});
      },
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
    await tester.runAsync(() async {
      final a = Tex.atlas;
      File('previews/atlas.txt').writeAsStringSync('atlas: ${a?.width}x${a?.height} ready=${Tex.ready}');
      if (a != null) {
        final b = await a.toByteData(format: ui.ImageByteFormat.png);
        File('previews/atlas.png').writeAsBytesSync(b!.buffer.asUint8List());
      }
    });
  });

  testWidgets('Zırh giyme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Voice.muted = true;
    await tester.runAsync(() async {
      await game.load();
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    game.avatar = '0,0,1,3,0,1,0,0';
    game.blockItems = {'zirh_selcuklu'};
    game.coins = 500;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (c) => Scaffold(
                body: Center(
                    child: ElevatedButton(
                        onPressed: () => Navigator.push<String>(
                            c, MaterialPageRoute(builder: (_) => const BagScreen(selected: 'tahta', shape: 0))),
                        child: const Text('ac')))))));
    await tester.tap(find.text('ac'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final tile = find.text('Selçuklu zırhı');
    await tester.scrollUntilVisible(tile, 300, scrollable: find.byType(Scrollable).first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(tile);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // ignore: avoid_print
    print('ZIRH_SONUC avatar=${game.avatar} items=${game.blockItems}');
    expect(Avatar.decode(game.avatar)!.armor, 6);
  });

  testWidgets('Arkadaşlar iş yapar, dünya büyük', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Voice.muted = true;
    await tester.runAsync(() async {
      await game.load();
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    game.blockWorld = '';
    game.blockFriends = 'Ali~0,0,1,3,0,1,0,0,3~18.0~17.0~1.0~0;Ayşe~1,2,1,5,2,0,0,0,5~16.5~16.0~1.0~0;Can~2,1,0,2,3,1,0,0,0~17.0~18.0~1.0~0';
    await tester.pumpWidget(const MaterialApp(home: BlokAdasi()));
    await tester.pump(const Duration(milliseconds: 100));
    final st = tester.state<BlokAdasiState>(find.byType(BlokAdasi));
    final adalar = st.world.places.keys.where((k) => k.endsWith('Adası')).length;
    final koyler = st.world.places.keys.where((k) => k.endsWith('Köyü')).length;
    // ignore: avoid_print
    print('DUNYA ${maxX - minX + 1}x${maxY - minY + 1} adalar=$adalar koyler=$koyler koylu=${st.npcs.length}');
    expect(adalar, 11);
    final w0 = maxX - minX;
    final ok = st.world.inflate(6, Random(9));
    // ignore: avoid_print
    print('SISME elips=${st.world.erx.toStringAsFixed(1)}x${st.world.ery.toStringAsFixed(1)} genislik $w0 -> ${maxX - minX} ok=$ok miras=${st.world.blocks.values.where((m) => m == matIndex('miras')).length}');
    expect(maxX - minX > w0, true);
    expect(koyler, 11);
    expect(st.npcs.isNotEmpty, true);
    final b0 = st.world.blocks.length;
    st.orderFriend(0, 'p_ev');
    st.orderFriend(1, 'p_cami');
    st.orderFriend(2, 'p_agac');
    for (var i = 0; i < 900; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (st.friends.every((f) => f.mode == 0) && st.jobs.isEmpty && i > 10) break;
    }
    // ignore: avoid_print
    print('ARKADAS modlar=${st.friends.map((f) => f.mode).toList()} isler=${st.jobs.length} blok=${st.world.blocks.length - b0}');
    expect(st.friends.every((f) => f.mode == 0), true);
    expect(st.world.blocks.length - b0 > 80, true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Uzay: gezegenler, roketle iniş, uçağa binme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Voice.muted = true;
    await tester.runAsync(() async {
      await game.load();
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    for (var p = 1; p <= 3; p++) {
      final w = BlockWorld()..seedPlanet(p, Random(p));
      final w2 = BlockWorld();
      expect(w2.decode(w.encode()), true);
      // ignore: avoid_print
      print('GEZEGEN $p blok=${w.blocks.length} yerler=${w.places.keys.toList()} kayit=${w2.blocks.length}');
      expect(w2.blocks.length, w.blocks.length);
      expect(w.places.length, 4);
    }
    expect(placeTo('Ay Üssü'), "Ay Üssü'ne");
    expect(placeTo('Olimpos Dağı'), "Olimpos Dağı'na");
    expect(placeTo('Darende Köyü'), 'Darende köyüne');
    // Mars'a roketle iniş
    game.planet = 2;
    game.planetWorlds = {};
    game.blockFriends = 'Ali~0,0,1,3,0,1,0,0,3~18.0~17.0~1.0~0';
    final rocket = prefabById('p_roket')!.cells().map((c) => (c.$1 + 1, c.$2 + 1, c.$3, c.$4)).toList();
    await tester.pumpWidget(MaterialApp(home: BlokAdasi(arriving: rocket)));
    await tester.pump(const Duration(milliseconds: 100));
    var st = tester.state<BlokAdasiState>(find.byType(BlokAdasi));
    final motors = st.world.blocks.values.where((m) => m == matIndex('motor')).length;
    final kp = st.world.blocks.entries.firstWhere((e) => e.value == matIndex('kokpit')).key;
    // ignore: avoid_print
    print('MARS motor=$motors yer=${st.ax.toStringAsFixed(1)},${st.ay.toStringAsFixed(1)} arkadas=${st.friends.map((f) => '${f.mode}@${f.x.toStringAsFixed(1)}').toList()} koylu=${st.npcs.length}');
    expect(motors, 1); // yalnızca gelen roket, yedek mekik yok
    expect((st.friends.first.x - st.ax).abs() < 3, true);
    expect(game.planetWorlds['2']?.isNotEmpty, true);
    expect(kp > 0, true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
    // Dünya'da uçağa binip başka yere inme
    game.planet = 0;
    final w = BlockWorld()..seed();
    w.stamp(prefabById('p_ucak')!.cells(), 12, 24, 1, 0);
    game.blockWorld = w.encode();
    game.blockFriends = '';
    await tester.pumpWidget(const MaterialApp(home: BlokAdasi(startFocus: (12, 24))));
    await tester.pump(const Duration(milliseconds: 100));
    st = tester.state<BlokAdasiState>(find.byType(BlokAdasi));
    final b0 = st.world.blocks.length;
    final cell = st.world.blocks.entries.firstWhere((e) => e.value == matIndex('kokpit')).key;
    await st.boardVehicle(cell);
    await tester.pump(const Duration(milliseconds: 100));
    final b1 = st.world.blocks.length;
    expect(st.riding, 'ucak');
    st.ax = 30.5;
    st.ay = 8.5;
    st.landPlane();
    await tester.pump(const Duration(milliseconds: 100));
    final kp2 = st.world.blocks.entries.firstWhere((e) => e.value == matIndex('kokpit')).key;
    // ignore: avoid_print
    print('UCAK binince ${b0 - b1} blok kalktı, indi: ${st.world.blocks.length - b1} blok, kokpit ${cxyz(cell)} -> ${cxyz(kp2)}');
    expect(st.riding, null);
    expect(st.world.blocks.length, b0);
    expect(cxyz(kp2).$1 > 25, true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
    game.planet = 0;
  });
}
