import 'package:flutter/material.dart';

import '../art.dart';
import '../games/kit.dart';
import '../sfx.dart';
import '../state.dart';
import '../voice.dart';
import '../widgets/common.dart';

class _Page {
  final String pic;
  final String text;
  const _Page(this.pic, this.text);
}

class Story {
  final String title;
  final String cover;
  final String moral;
  final List<_Page> pages;
  final String question;
  final List<(String, String)> answers; // emoji, kelime — ilki doğru
  const Story(this.title, this.cover, this.moral, this.pages, this.question, this.answers);
}

const stories = [
  Story('Yarım Elma', '🍎', 'Paylaşmak', [
    _Page('🚗', '{araba} yola çıktı.'),
    _Page('🦝', 'Yolda Tozbulut ile karşılaştı.'),
    _Page('😢', 'Tozbulut çok acıkmıştı.'),
    _Page('🍎', '{araba} elmasını ikiye böldü.'),
    _Page('🤝', 'Yarısını Tozbulut\'a verdi.'),
    _Page('❤️', 'Paylaşmak ne güzel!'),
  ], 'Kim acıkmıştı?', [('🦝', 'Tozbulut'), ('🦉', 'Baykuş')]),
  Story('Kırık Ayna', '🪞', 'Doğruluk', [
    _Page('⚽', 'Ali bahçede topla oynuyordu.'),
    _Page('💥', 'Top arabanın aynasına çarptı.'),
    _Page('😟', 'Ali çok korktu.'),
    _Page('🗣️', 'Ama doğruyu söyledi.'),
    _Page('👴', 'Tamirci Usta gülümsedi. Doğru söyleyeni herkes sever.'),
    _Page('🔧', 'Birlikte aynayı tamir ettiler.'),
  ], 'Ali ne yaptı?', [('🗣️', 'doğruyu söyledi'), ('🙈', 'saklandı')]),
  Story('Bismillah', '🤲', 'Şükür', [
    _Page('🏁', 'Yarış başlamak üzereydi.'),
    _Page('🤲', '{surucu} önce Bismillah dedi.'),
    _Page('🚗', 'Dikkatli sürdü, kimseyi itmedi.'),
    _Page('🏆', 'Bitiş çizgisine vardı.'),
    _Page('😊', 'Elhamdülillah dedi ve şükretti.'),
  ], 'Başlarken ne deriz?', [('🤲', 'Bismillah'), ('👋', 'Hoşça kal')]),
  Story('Yavru Kedi', '🐱', 'Merhamet', [
    _Page('🌧️', 'Yağmur yağıyordu.'),
    _Page('🐱', 'Ağacın altında bir yavru kedi titriyordu.'),
    _Page('🚗', '{surucu} arabasını durdurdu.'),
    _Page('🧺', 'Kediyi havluya sardı.'),
    _Page('🥛', 'Ona biraz süt verdi.'),
    _Page('💛', 'Hayvanlara merhamet etmek ne güzel!'),
  ], 'Kedi neden titriyordu?', [('🌧️', 'yağmur'), ('☀️', 'güneş')]),
  Story('Ayşe Nine', '👵', 'Saygı', [
    _Page('👵', 'Ayşe Nine\'nin çantası çok ağırdı.'),
    _Page('🏃', '{surucu} hemen yanına koştu.'),
    _Page('👋', 'Selamün aleyküm Nine, dedi.'),
    _Page('🏠', 'Çantayı evine kadar taşıdı.'),
    _Page('🤲', 'Nine dua etti. Allah razı olsun yavrum!'),
  ], 'Kime yardım etti?', [('👵', 'nine'), ('🐶', 'köpek')]),
];

String _fill(String t) => t
    .replaceAll('{araba}', game.carName.isEmpty ? 'Vızır' : game.carName)
    .replaceAll('{surucu}', game.driverName.isEmpty ? 'Sürücü' : game.driverName);

/// Hikâye Kitabım: kısa, resimli, heceli hikâyeler.
class StoryShelf extends StatelessWidget {
  const StoryShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDeco('bolge_kelime'),
        child: SafeArea(
          child: Column(children: [
            const TopBar('Hikâye Kitabım'),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Talker(Who.baykus, 'Bir hikâye seç. Kelimelere dokunursan onları okurum!', mood: 'okur', size: 100),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(14),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  for (var i = 0; i < stories.length; i++)
                    Bouncy(
                      onTap: () => go(context, StoryReader(stories[i], i)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.primaries[(i * 3) % 18].shade200, Colors.primaries[(i * 3) % 18].shade500],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 4))],
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(stories[i].cover, style: const TextStyle(fontSize: 60)),
                          const SizedBox(height: 6),
                          Text(stories[i].title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                          Text(stories[i].moral, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          StarRow(game.best('hikaye_$i'), size: 18),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class StoryReader extends StatefulWidget {
  final Story story;
  final int index;
  const StoryReader(this.story, this.index, {super.key});

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  int page = 0;
  bool quiz = false;
  int shake = 0;
  int wrong = 0;
  late final List<(String, String)> shuffled = [...widget.story.answers]..shuffle();

  Story get s => widget.story;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Voice.say(s.title));
  }

  void _readPage() => Voice.say(_fill(s.pages[page].text));

  void _next() {
    Sfx.play('kart');
    if (page + 1 < s.pages.length) {
      setState(() => page++);
    } else {
      setState(() => quiz = true);
      Voice.say(s.question);
    }
  }

  Future<void> _answer((String, String) a) async {
    if (a == s.answers.first) {
      Sfx.play('correct');
      game.storyDone();
      final again = await levelDone(context,
          id: 'hikaye_${widget.index}',
          stars: wrong == 0 ? 3 : 2,
          who: Who.baykus,
          sticker: const ['d_lale', 'd_pembe', 'd_agac', 'd_meyve', 'd_cam'][widget.index % 5],
          message: 'Hikâyeyi bitirdin! ${s.moral} ne güzel bir şey.');
      if (!mounted) return;
      if (again) {
        setState(() {
          page = 0;
          quiz = false;
          wrong = 0;
        });
      } else {
        Navigator.pop(context);
      }
    } else {
      Sfx.play('wrong');
      Voice.say('Hikâyeyi hatırla. ${s.question}');
      setState(() {
        wrong++;
        shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = s.pages[page];
    final words = _fill(p.text).split(' ');
    return Scaffold(
      body: Container(
        decoration: bgDeco('bolge_kelime'),
        child: SafeArea(
          child: Column(children: [
            TopBar(s.title),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFD7A15A), width: 5),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 6))],
                    ),
                    child: quiz
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            const Pic('k_baykus_saskin', height: 120),
                            const SizedBox(height: 10),
                            Text(s.question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 18),
                            Shake(
                              trigger: shake,
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                for (final a in shuffled)
                                  ChoiceTile(
                                    size: 120,
                                    color: const Color(0xFFE3F2FD),
                                    onTap: () => _answer(a),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text(a.$1, style: const TextStyle(fontSize: 46)),
                                      SylText(a.$2, size: 20),
                                    ]),
                                  ),
                              ]),
                            ),
                          ])
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                              child: Text(p.pic, key: ValueKey(page), style: const TextStyle(fontSize: 110)),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                for (final w in words)
                                  GestureDetector(
                                    onTap: () => Voice.say(w.replaceAll(RegExp(r'[.,!?]'), '')),
                                    child: SylText(w, size: 34),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('${page + 1} / ${s.pages.length}', style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                          ]),
                  ),
                ),
              ),
            ),
            if (!quiz)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(children: [
                  RoundIcon(Icons.chevron_left, () {
                    if (page > 0) setState(() => page--);
                  }),
                  const Spacer(),
                  Bouncy(
                    onTap: _readPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF7E57C2), borderRadius: BorderRadius.circular(24)),
                      child: const Row(children: [
                        Icon(Icons.volume_up, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text('Oku', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  RoundIcon(Icons.chevron_right, _next),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
