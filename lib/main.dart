import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home.dart';
import 'screens/lock.dart';
import 'state.dart';
import 'voice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await game.load();
  game.start();
  await Voice.init();
  runApp(const VizirApp());
}

class VizirApp extends StatelessWidget {
  const VizirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vızır',
      debugShowCheckedModeBanner: false,
      navigatorKey: navKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE53935),
      ),
      home: const HomeScreen(),
      builder: (context, child) {
        return ListenableBuilder(
          listenable: game,
          builder: (context, _) => Stack(
            children: [
              if (child != null) child,
              if (game.showLock) Positioned.fill(child: LockScreen(reason: game.lockReason!)),
            ],
          ),
        );
      },
    );
  }
}
