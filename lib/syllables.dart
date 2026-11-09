import 'dart:math';

/// Okulda kullanılan ses grubu sırası (ses temelli cümle yöntemi).
const letterGroups = <String>['elakin', 'omutüy', 'örıdsb', 'zçgşcp', 'hğvfj'];
const _vowels = 'aeıioöuü';

bool isVowel(String ch) => ch.isNotEmpty && _vowels.contains(trLower(ch));

String trLower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

String trCapitalize(String s) {
  if (s.isEmpty) return s;
  final f = s.substring(0, 1);
  final up = f == 'i' ? 'İ' : (f == 'ı' ? 'I' : f.toUpperCase());
  return up + s.substring(1);
}

/// Hece olarak çıkmaması gereken kaba sözcükler.
const _badExact = <String>{'am', 'amı', 'ami', 'oç', 'piç', 'çük', 'kıç', 'sıç', 'göt', 'bok', 'sik'};
const _badStart = <String>['sik', 'göt', 'piç', 'amk', 'amc', 'yarak', 'taşak', 'orospu', 'ibne', 'pezevenk', 'gavat', 'kahpe', 'sürtük'];

bool isBadWord(String s) {
  final l = trLower(s).trim();
  if (_badExact.contains(l)) return true;
  for (final b in _badStart) {
    if (b.length >= 4 ? l.contains(b) : l.startsWith(b)) return true;
  }
  return false;
}

Set<String> lettersFor(int group) {
  final out = <String>{};
  for (var i = 0; i < group && i < letterGroups.length; i++) {
    out.addAll(letterGroups[i].split(''));
  }
  return out;
}

/// Hecelerine ayrılmış kelimeler (ses grubu sırasına göre).
const words = <List<String>>[
  // 1. grup: e l a k i n
  ['el'], ['al'], ['ak'], ['ek'], ['kek'], ['nal'], ['kil'], ['ilk'],
  ['la', 'le'], ['ka', 'le'], ['ne', 'ne'], ['a', 'na'], ['e', 'la'],
  ['i', 'nek'], ['an', 'ne'], ['ki', 'le'], ['a', 'la'], ['ke', 'le', 'ki'],
  ['a', 'na', 'ne'],
  // 2. grup: o m u t ü y
  ['top'], ['mum'], ['kum'], ['tel'], ['ok'], ['kol'], ['ay'],
  ['el', 'ma'], ['ka', 'lem'], ['ta', 'ne'], ['ü', 'tü'], ['ye', 'mek'],
  ['a', 'ta'], ['o', 'kul'], ['ku', 'tu'], ['kü', 'tük'], ['ma', 'ma'],
  // 3. grup: ö r ı d s b
  ['a', 'ra', 'ba'], ['a', 'rı'], ['ka', 'yık'], ['ba', 'ba'], ['de', 'de'],
  ['ba', 'lık'], ['sa', 'at'], ['ma', 'sa'], ['ka', 'ra'], ['ke', 'di'],
  ['dü', 'dük'], ['bu', 'lut'], ['ö', 'dül'], ['sı', 'ra'], ['bö', 'rek'],
  ['de', 're'], ['ba', 'lon'], ['ka', 'bak'], ['sa', 'bun'],
  // 4. grup: z ç g ş c p
  ['ço', 'cuk'], ['göz'], ['ka', 'pı'], ['şe', 'ker'], ['ye', 'şil'],
  ['kır', 'mı', 'zı'], ['gü', 'neş'], ['ço', 'rap'], ['kuş'], ['pist'],
  ['yaz'], ['de', 'niz'], ['ü', 'züm'], ['çi', 'çek'], ['şap', 'ka'],
  ['kö', 'pek'], ['göz', 'lük'],
  // 5. grup: h ğ v f j
  ['ha', 'va'], ['ev'], ['fil'], ['ho', 'roz'], ['tav', 'şan'], ['va', 'pur'],
  ['ka', 'fes'], ['a', 'ğaç'], ['dağ'], ['yağ', 'mur'], ['hav', 'lu'],
  ['fı', 'rın'], ['ka', 'vun'],
];

class Bank {
  final int group;
  final int step;
  late final Set<String> letters;
  final Random rnd = Random();

  Bank(this.group, this.step) {
    letters = lettersFor(group);
  }

  List<String> get _vow => letters.where(isVowel).toList();
  List<String> get _cons => letters.where((c) => !isVowel(c)).toList();

  bool _allowed(String w) => w.split('').every(letters.contains);

  List<String> twoLetter() {
    final out = <String>[];
    for (final c in _cons) {
      for (final v in _vow) {
        if (c != 'ğ') out.add('$c$v');
        out.add('$v$c');
      }
    }
    return out.where((s) => !isBadWord(s)).toList();
  }

  List<String> threeLetter() {
    final out = <String>[];
    for (final c1 in _cons) {
      if (c1 == 'ğ') continue;
      for (final v in _vow) {
        for (final c2 in _cons) {
          out.add('$c1$v$c2');
        }
      }
    }
    return out.where((s) => !isBadWord(s)).toList();
  }

  List<List<String>> wordList() => words.where((w) => _allowed(w.join())).toList();

  List<String> items() {
    if (step <= 1) return twoLetter();
    if (step == 2) return threeLetter();
    final ws = wordList().map((w) => w.join()).toSet().toList();
    return ws.length >= 3 ? ws : threeLetter();
  }

  /// Hece kapısı için birbirinden farklı [n] seçenek.
  List<String> gate(int n) {
    final it = items()..shuffle(rnd);
    final res = <String>[];
    for (final s in it) {
      if (!res.contains(s)) res.add(s);
      if (res.length == n) break;
    }
    return res;
  }

  /// Hece tamiri için en az iki heceli bir kelime.
  List<String> repairWord() {
    var pool = wordList().where((w) => w.length >= 2).toList();
    if (pool.isEmpty) {
      final g1 = lettersFor(1);
      pool = words
          .where((w) => w.length >= 2 && w.join().split('').every(g1.contains))
          .toList();
    }
    return pool[rnd.nextInt(pool.length)];
  }
}
