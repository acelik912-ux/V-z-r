import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'car_painter.dart';

final navKey = GlobalKey<NavigatorState>();

/// Bir parçanın açılması için gereken ödül eşikleri (harcanmaz, sadece ulaşılması gerekir).
class Req {
  final int stars;
  final int hearts;
  final int cups;
  const Req({this.stars = 0, this.hearts = 0, this.cups = 0});
  bool get free => stars == 0 && hearts == 0 && cups == 0;
}

const bodyReqs = <Req>[Req(), Req(stars: 5), Req(stars: 10, hearts: 1)];
const colorReqs = <Req>[
  Req(), Req(), Req(), Req(),
  Req(stars: 3), Req(hearts: 1), Req(cups: 1), Req(stars: 8, hearts: 2),
];
const wheelReqs = <Req>[Req(), Req(cups: 1), Req(stars: 6)];

class GameState extends ChangeNotifier with WidgetsBindingObserver {
  static const _key = 'vizir_state_v1';
  SharedPreferences? _prefs;

  String driverName = '';
  String carName = '';
  List<String> rivalNames = ['Tozbulut', 'Pırpır', 'Şimşek'];
  int body = 0;
  int color = 0;
  int wheel = 0;
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

  int _raceDepth = 0;
  bool _parentOpen = false;
  bool _foreground = true;
  Timer? _clock;
  int _tickCount = 0;
  String? _lastLock;

  bool get inRace => _raceDepth > 0;
  bool get parentOpen => _parentOpen;
  CarSpec get spec => CarSpec(body, color, wheel);

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
  List<Req> reqsFor(String kind) => kind == 'body' ? bodyReqs : (kind == 'color' ? colorReqs : wheelReqs);

  bool isUnlocked(String kind, int i) {
    final reqs = reqsFor(kind);
    if (i < reqs.length && reqs[i].free) return true;
    return unlocked.contains('$kind$i');
  }

  bool reqMet(Req r) => stars >= r.stars && hearts >= r.hearts && cups >= r.cups;

  void unlock(String kind, int i) {
    unlocked.add('$kind$i');
    _changed();
  }

  void setPart(String kind, int i) {
    if (kind == 'body') {
      body = i;
    } else if (kind == 'color') {
      color = i;
    } else {
      wheel = i;
    }
    _changed();
  }

  int selected(String kind) => kind == 'body' ? body : (kind == 'color' ? color : wheel);

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
  void recordSyllable(String s, bool ok) {
    final e = stats.putIfAbsent(s, () => [0, 0]);
    if (ok) {
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
        'body': body,
        'color': color,
        'wheel': wheel,
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
      };

  void _fromJson(Map<String, dynamic> j) {
    int gi(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    driverName = j['driverName'] as String? ?? '';
    carName = j['carName'] as String? ?? '';
    final rn = (j['rivalNames'] as List?)?.map((e) => e.toString()).toList();
    if (rn != null && rn.length == 3) rivalNames = rn;
    body = gi('body', 0);
    color = gi('color', 0);
    wheel = gi('wheel', 0);
    unlocked = ((j['unlocked'] as List?) ?? const []).map((e) => e.toString()).toSet();
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
    final st = j['stats'];
    if (st is Map) {
      stats = st.map((k, v) => MapEntry(k.toString(), (v as List).map((e) => (e as num).toInt()).toList()));
    }
  }
}

final game = GameState();
