import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'car3d/car_model.dart';
import 'catalog.dart';

final navKey = GlobalKey<NavigatorState>();

class GameState extends ChangeNotifier with WidgetsBindingObserver {
  static const _key = 'vizir_state_v1';
  SharedPreferences? _prefs;

  String driverName = '';
  String carName = '';
  List<String> rivalNames = ['Tozbulut', 'Pırpır', 'Şimşek'];
  Map<String, int> parts = const CarConfig().toParts();
  Set<String> unlocked = <String>{};
  int stars = 0;
  int hearts = 0;
  int cups = 0;
  int coins = 0;
  int races = 0;

  int dailyLimitMin = 30;
  int playedSecToday = 0;
  int bonusMinToday = 0;
  int bonusCountToday = 0;
  String dayKey = '';

  int letterGroup = 1;
  int step = 1;
  bool nightLock = true;
  int nightHour = 21;
  String pin = '';
  Map<String, List<int>> stats = {};
  bool sfxOn = true;
  String voiceName = '';
  String voiceLocale = '';
  double speechRate = 0.5;
  bool neuralVoice = true;
  double speechPitch = 1.05;
  bool musicOn = true;

  // Macera ve mini oyunlar
  Map<String, int> levelStars = {};
  Set<String> stickers = <String>{};
  String blockWorld = '';
  Set<String> blockQuests = <String>{};
  Set<String> blockItems = <String>{};
  Set<String> todayPlayed = <String>{};
  Set<String> taskClaimed = <String>{};
  int storyRead = 0;
  int treesPlanted = 0;
  String avatar = '';
  String blockLife = '';
  Set<String> blockTools = <String>{};
  Map<String, int> mined = {};
  Map<String, int> sylBag = {}; // hece madeninden toplanan heceler
  Map<String, int> crafted = {}; // kelime tezgâhında yapılan kelimeler
  String blockSigns = ''; // konuşan tabelalar: hücre:kelime;...
  Map<String, int> today = {}; // bugünün özeti: hece, kelime, iyilik, urun, satis
  List<String> todayWords = [];
  String surpriseDay = '';
  String trail = ''; // Blok Şehri renkli iz
  String blockFriends = ''; // Blok Şehri arkadaşları
  Set<String> treasures = {}; // bulunan değerli taşlar ve miras eşyaları // akşam masalında söz verilen sürpriz yumurta
  DateTime? windDownAt; // süre bitmeden 3 dk önce

  int _raceDepth = 0;
  bool _parentOpen = false;
  bool _foreground = true;
  Timer? _clock;
  int _tickCount = 0;
  String? _lastLock;

  bool get inRace => _raceDepth > 0;
  bool get parentOpen => _parentOpen;
  CarConfig get config => CarConfig.fromParts(parts);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    _checkDay();
  }

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _lastLock = lockReason;
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    _checkDay();
    if (_foreground && !_parentOpen && (lockReason == null || inRace)) {
      playedSecToday++;
    }
    _tickCount++;
    if (windDownAt == null && lockReason == null && fuelLeftSec <= 180 && fuelLeftSec > 0 && playedSecToday > 60) {
      windDownAt = DateTime.now();
      notifyListeners();
    }
    final lock = lockReason;
    if (lock != _lastLock) {
      _lastLock = lock;
      save();
      notifyListeners();
      return;
    }
    if (_tickCount % 15 == 0) save();
    if (_tickCount % 5 == 0) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      save();
    } else {
      _checkDay();
      notifyListeners();
    }
  }

  void _checkDay() {
    final n = DateTime.now();
    final k = '${n.year}-${n.month}-${n.day}';
    if (k != dayKey) {
      dayKey = k;
      playedSecToday = 0;
      bonusMinToday = 0;
      bonusCountToday = 0;
      todayPlayed = {};
      taskClaimed = {};
      today = {};
      todayWords = [];
      windDownAt = null;
    }
  }

  // ---- Yakıt ve kilit ----
  int get totalSecToday => (dailyLimitMin + bonusMinToday) * 60;
  int get fuelLeftSec => max(0, totalSecToday - playedSecToday);
  double get fuelFraction => totalSecToday == 0 ? 0 : fuelLeftSec / totalSecToday;

  bool get isNight {
    if (!nightLock) return false;
    final h = DateTime.now().hour;
    return h >= nightHour || h < 7;
  }

  String? get lockReason {
    if (isNight) return 'night';
    if (fuelLeftSec <= 0) return 'fuel';
    return null;
  }

  bool get showLock => lockReason != null && !inRace && !_parentOpen;

  void _notifySafe() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void setInRace(bool v) {
    _raceDepth = max(0, _raceDepth + (v ? 1 : -1));
    _notifySafe();
  }

  void setParentOpen(bool v) {
    _parentOpen = v;
    _notifySafe();
  }

  // ---- Garaj ----
  Req reqFor(String kind, int i) {
    final row = rowFor(kind);
    if (row == null || i < 0 || i >= row.options.length) return const Req();
    return row.options[i].req;
  }

  bool isUnlocked(String kind, int i) => reqFor(kind, i).free || unlocked.contains('$kind:$i');

  bool reqMet(Req r) => stars >= r.stars && hearts >= r.hearts && cups >= r.cups;

  void unlock(String kind, int i) {
    unlocked.add('$kind:$i');
    _changed();
  }

  void setPart(String kind, int i) {
    parts = {...parts, kind: i};
    _changed();
  }

  int selected(String kind) => parts[kind] ?? 0;

  // ---- İsimler ----
  void setDriver(String n) {
    driverName = n;
    _changed();
  }

  void setCar(String n) {
    carName = n;
    _changed();
  }

  void setRival(int i, String n) {
    if (i >= 0 && i < rivalNames.length) rivalNames[i] = n;
    _changed();
  }

  // ---- Öğrenme ve ödüller ----
  void addTreasure(String id) {
    treasures.add(id);
    _changed();
  }

  void saveFriends(String v) {
    blockFriends = v;
    save();
  }

  void setTrail(String t) {
    trail = t;
    _changed();
  }

  void countToday(String k, [int n = 1]) {
    today[k] = (today[k] ?? 0) + n;
  }

  /// Satılacak/paylaşılacak ürünler (hayvan ürünleri ve hasat).
  Map<String, int> get products => {
        for (final e in mined.entries)
          if (e.key.startsWith('urun_') && e.value > 0) e.key.substring(5): e.value
      };

  bool takeProduct(String id) {
    final k = 'urun_$id';
    final v = mined[k] ?? 0;
    if (v <= 0) return false;
    mined[k] = v - 1;
    _changed();
    return true;
  }

  void addSyl(String s, [int n = 1]) {
    sylBag[s] = (sylBag[s] ?? 0) + n;
    _changed();
  }

  /// Gereken heceler çantada varsa harcar.
  bool useSyls(List<String> parts) {
    final need = <String, int>{};
    for (final p in parts) {
      need[p] = (need[p] ?? 0) + 1;
    }
    for (final e in need.entries) {
      if ((sylBag[e.key] ?? 0) < e.value) return false;
    }
    for (final e in need.entries) {
      final left = sylBag[e.key]! - e.value;
      if (left <= 0) {
        sylBag.remove(e.key);
      } else {
        sylBag[e.key] = left;
      }
    }
    _changed();
    return true;
  }

  void addCrafted(String w) {
    crafted[w] = (crafted[w] ?? 0) + 1;
    countToday('kelime');
    if (!todayWords.contains(w)) todayWords.add(w);
    _changed();
  }

  void saveSigns(String v) {
    blockSigns = v;
    save();
  }

  /// En çok zorlanılan heceler (yanlış oranı yüksek olanlar önce).
  List<String> weakSyllables([int n = 8]) {
    final l = stats.entries.where((e) => e.value[1] > 0 && e.key.length <= 4).toList()
      ..sort((a, b) {
        double r(List<int> v) => (v[1] + 1) / (v[0] + v[1] + 2);
        final c = r(b.value).compareTo(r(a.value));
        return c != 0 ? c : b.value[1].compareTo(a.value[1]);
      });
    return l.take(n).map((e) => e.key).toList();
  }

  void recordSyllable(String s, bool ok) {
    final e = stats.putIfAbsent(s, () => [0, 0]);
    if (ok) {
      countToday('hece');
      e[0]++;
    } else {
      e[1]++;
    }
  }

  void addRaceResult({required int stars, required int hearts, required int cups, required int coins}) {
    this.stars += stars;
    this.hearts += hearts;
    this.cups += cups;
    this.coins += coins;
    races++;
    _changed();
  }

  void addStars(int n) {
    stars += n;
    _changed();
  }

  /// Ebeveyn onayı: gerçek kitap ya da gerçek iyilik. Günde en fazla 2 kez, her biri +10 dakika.
  bool addBonus({bool kindness = false}) {
    _checkDay();
    if (bonusCountToday >= 2) return false;
    bonusCountToday++;
    bonusMinToday += 10;
    if (kindness) {
      hearts++;
    } else {
      stars++;
    }
    _changed();
    return true;
  }

  // ---- Macera ----
  int best(String id) => levelStars[id] ?? 0;
  int get adventureStars => levelStars.values.fold(0, (a, b) => a + b);

  /// Bir bölüm bitti. Yeni kazanılan yıldızları ve kalpleri ekler.
  /// İlk kez 3 yıldız alınınca bir çıkartma verir; çıkartma adını döndürür.
  String? finishLevel(String id, int stars, {int hearts = 0, String? sticker}) {
    final prev = best(id);
    if (stars > prev) {
      levelStars[id] = stars;
      this.stars += stars - prev;
    }
    this.hearts += hearts;
    coins += stars * 3;
    todayPlayed.add(id);
    String? got;
    if (stars >= 3 && sticker != null && !stickers.contains(sticker)) {
      stickers.add(sticker);
      got = sticker;
    }
    _changed();
    return got;
  }

  void addSticker(String s) {
    if (stickers.add(s)) _changed();
  }

  void markPlayed(String id) {
    if (todayPlayed.add(id)) _changed();
  }

  void claimTask(String id, {int stars = 1, int hearts = 0}) {
    if (!taskClaimed.add(id)) return;
    this.stars += stars;
    this.hearts += hearts;
    _changed();
  }

  void saveBlocks(String w) {
    blockWorld = w;
    save();
  }

  void blockQuestDone(String q, {int stars = 0, int hearts = 0}) {
    if (!blockQuests.add(q)) return;
    this.stars += stars;
    this.hearts += hearts;
    _changed();
  }

  void addBlockItem(String it) {
    if (blockItems.add(it)) _changed();
  }

  void setAvatar(String a) {
    avatar = a;
    _changed();
  }

  void addTool(String t) {
    if (blockTools.add(t)) _changed();
  }

  void addMined(String m) {
    mined[m] = (mined[m] ?? 0) + 1;
    save();
  }

  void saveLife(String l) {
    blockLife = l;
    save();
  }

  void addCoins(int n) {
    coins += n;
    _changed();
  }

  bool spendCoins(int n) {
    if (coins < n) return false;
    coins -= n;
    _changed();
    return true;
  }

  void addHeart() {
    hearts++;
    _changed();
  }

  void plantTree() {
    treesPlanted++;
    save();
  }

  void setMusic(bool v) {
    musicOn = v;
    _changed();
  }

  void storyDone() {
    storyRead++;
    todayPlayed.add('hikaye');
    _changed();
  }

  // ---- Ebeveyn ayarları ----
  void setDailyLimit(int m) {
    dailyLimitMin = m;
    _changed();
  }

  void setLetterGroup(int g) {
    letterGroup = g.clamp(1, 5).toInt();
    _changed();
  }

  void setStep(int s) {
    step = s.clamp(1, 3).toInt();
    _changed();
  }

  void setNightLock(bool v) {
    nightLock = v;
    _changed();
  }

  void setNightHour(int h) {
    nightHour = h;
    _changed();
  }

  void setSfx(bool v) {
    sfxOn = v;
    _changed();
  }

  void setVoice(String name, String locale) {
    voiceName = name;
    voiceLocale = locale;
    _changed();
  }

  void setSpeech({double? rate, double? pitch}) {
    if (rate != null) speechRate = rate;
    if (pitch != null) speechPitch = pitch;
    _changed();
  }

  void setNeuralVoice(bool v) {
    neuralVoice = v;
    _changed();
  }

  void setPin(String p) {
    pin = p;
    _changed();
  }

  void _changed() {
    save();
    _notifySafe();
  }

  void save() {
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'driverName': driverName,
        'carName': carName,
        'rivalNames': rivalNames,
        'parts': parts,
        'sfxOn': sfxOn,
        'voiceName': voiceName,
        'voiceLocale': voiceLocale,
        'speechRate': speechRate,
        'speechPitch': speechPitch,
        'neuralVoice': neuralVoice,
        'unlocked': unlocked.toList(),
        'stars': stars,
        'hearts': hearts,
        'cups': cups,
        'coins': coins,
        'races': races,
        'dailyLimitMin': dailyLimitMin,
        'playedSecToday': playedSecToday,
        'bonusMinToday': bonusMinToday,
        'bonusCountToday': bonusCountToday,
        'dayKey': dayKey,
        'letterGroup': letterGroup,
        'step': step,
        'nightLock': nightLock,
        'nightHour': nightHour,
        'pin': pin,
        'stats': stats,
        'musicOn': musicOn,
        'levelStars': levelStars,
        'stickers': stickers.toList(),
        'blockWorld': blockWorld,
        'blockQuests': blockQuests.toList(),
        'blockItems': blockItems.toList(),
        'todayPlayed': todayPlayed.toList(),
        'taskClaimed': taskClaimed.toList(),
        'storyRead': storyRead,
        'treesPlanted': treesPlanted,
        'avatar': avatar,
        'blockLife': blockLife,
        'blockTools': blockTools.toList(),
        'mined': mined,
        'sylBag': sylBag,
        'crafted': crafted,
        'blockSigns': blockSigns,
        'today': today,
        'todayWords': todayWords,
        'surpriseDay': surpriseDay,
        'trail': trail,
        'blockFriends': blockFriends,
        'treasures': treasures.toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    int gi(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    driverName = j['driverName'] as String? ?? '';
    carName = j['carName'] as String? ?? '';
    final rn = (j['rivalNames'] as List?)?.map((e) => e.toString()).toList();
    if (rn != null && rn.length == 3) rivalNames = rn;
    unlocked = ((j['unlocked'] as List?) ?? const []).map((e) => e.toString()).toSet();
    final pj = j['parts'];
    if (pj is Map) {
      parts = {...const CarConfig().toParts(), ...pj.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))};
    } else {
      // Eski sürümden taşıma
      final ob = gi('body', 0), oc = gi('color', 0), ow = gi('wheel', 0);
      parts = {
        ...const CarConfig().toParts(),
        'body': const [0, 2, 3][ob.clamp(0, 2).toInt()],
        'color': const [0, 1, 2, 3, 6, 7, 8, 9][oc.clamp(0, 7).toInt()],
        'rim': ow == 1 ? 1 : 0,
        'rimColor': ow == 1 ? 2 : 0,
        'tire': ow == 2 ? 1 : 0,
      };
      const oldKeys = {'body1': 'body:2', 'body2': 'body:3', 'wheel1': 'rim:1', 'wheel2': 'tire:1'};
      unlocked = {
        for (final u in unlocked)
          oldKeys[u] ?? (u.startsWith('color') ? 'color:${const [0, 1, 2, 3, 6, 7, 8, 9][(int.tryParse(u.substring(5)) ?? 0).clamp(0, 7).toInt()]}' : u)
      };
    }
    sfxOn = j['sfxOn'] as bool? ?? true;
    voiceName = j['voiceName'] as String? ?? '';
    voiceLocale = j['voiceLocale'] as String? ?? '';
    speechRate = (j['speechRate'] as num?)?.toDouble() ?? 0.5;
    neuralVoice = j['neuralVoice'] as bool? ?? true;
    speechPitch = (j['speechPitch'] as num?)?.toDouble() ?? 1.05;
    stars = gi('stars', 0);
    hearts = gi('hearts', 0);
    cups = gi('cups', 0);
    coins = gi('coins', 0);
    races = gi('races', 0);
    dailyLimitMin = gi('dailyLimitMin', 30);
    playedSecToday = gi('playedSecToday', 0);
    bonusMinToday = gi('bonusMinToday', 0);
    bonusCountToday = gi('bonusCountToday', 0);
    dayKey = j['dayKey'] as String? ?? '';
    letterGroup = gi('letterGroup', 1);
    step = gi('step', 1);
    nightLock = j['nightLock'] as bool? ?? true;
    nightHour = gi('nightHour', 21);
    pin = j['pin'] as String? ?? '';
    musicOn = j['musicOn'] as bool? ?? true;
    final ls = j['levelStars'];
    if (ls is Map) levelStars = ls.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    Set<String> ss(String k) => ((j[k] as List?) ?? const []).map((e) => e.toString()).toSet();
    stickers = ss('stickers');
    blockQuests = ss('blockQuests');
    blockItems = ss('blockItems');
    todayPlayed = ss('todayPlayed');
    taskClaimed = ss('taskClaimed');
    blockWorld = j['blockWorld'] as String? ?? '';
    storyRead = gi('storyRead', 0);
    treesPlanted = gi('treesPlanted', 0);
    avatar = j['avatar'] as String? ?? '';
    blockLife = j['blockLife'] as String? ?? '';
    blockTools = ss('blockTools');
    Map<String, int> mi(String k) {
      final v = j[k];
      return v is Map ? v.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) : <String, int>{};
    }

    sylBag = mi('sylBag');
    crafted = mi('crafted');
    blockSigns = j['blockSigns'] as String? ?? '';
    today = mi('today');
    todayWords = ((j['todayWords'] as List?) ?? const []).map((e) => e.toString()).toList();
    surpriseDay = j['surpriseDay'] as String? ?? '';
    trail = j['trail'] as String? ?? '';
    blockFriends = j['blockFriends'] as String? ?? '';
    treasures = ((j['treasures'] as List?) ?? const []).map((e) => e.toString()).toSet();
    final mj = j['mined'];
    if (mj is Map) mined = mj.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    final st = j['stats'];
    if (st is Map) {
      stats = st.map((k, v) => MapEntry(k.toString(), (v as List).map((e) => (e as num).toInt()).toList()));
    }
  }
}

final game = GameState();
