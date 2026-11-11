import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// حفظ تقدّم اللاعب: المراحل المكتملة، أفضل النتائج، الجمرات، الترقيات
class SaveData {
  static const _key = 'amber_save_v1';
  static const int levelsPerWorld = 10;
  /// للتجربة: يفتح كل العوالم والمراحل ويعطي رصيداً للمتجر. غيّرها إلى false عند النشر.
  static const bool unlockAll = true;

  final Set<String> done = {};
  final Map<String, int> bestEmbers = {};
  final Map<String, int> bestTime = {}; // بالثواني
  int coins = 0;
  int heartUp = 0, dashUp = 0, hammerUp = 0;
  String last = 'w1l1';

  static String id(int w, int l) => 'w${w}l$l';

  static Future<SaveData> load() async {
    final d = SaveData();
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_key);
      if (s != null) {
        final m = jsonDecode(s) as Map<String, dynamic>;
        d.done.addAll(((m['done'] ?? []) as List).map((e) => e.toString()));
        ((m['bestEmbers'] ?? {}) as Map).forEach((k, v) => d.bestEmbers[k.toString()] = (v as num).toInt());
        ((m['bestTime'] ?? {}) as Map).forEach((k, v) => d.bestTime[k.toString()] = (v as num).toInt());
        d.coins = ((m['coins'] ?? 0) as num).toInt();
        d.heartUp = ((m['heartUp'] ?? 0) as num).toInt();
        d.dashUp = ((m['dashUp'] ?? 0) as num).toInt();
        d.hammerUp = ((m['hammerUp'] ?? 0) as num).toInt();
        d.last = (m['last'] ?? 'w1l1').toString();
      }
    } catch (_) {}
    if (unlockAll && d.coins < 5000) d.coins = 5000;
    return d;
  }

  Future<void> save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
          _key,
          jsonEncode({
            'done': done.toList(),
            'bestEmbers': bestEmbers,
            'bestTime': bestTime,
            'coins': coins,
            'heartUp': heartUp,
            'dashUp': dashUp,
            'hammerUp': hammerUp,
            'last': last,
          }));
    } catch (_) {}
  }

  bool levelDone(int w, int l) => done.contains(id(w, l));

  bool levelUnlocked(int w, int l) {
    if (unlockAll) return true;
    if (w == 1 && l == 1) return true;
    if (l > 1) return levelDone(w, l - 1);
    return levelDone(w - 1, levelsPerWorld);
  }

  bool worldUnlocked(int w) => levelUnlocked(w, 1);

  int worldDone(int w) {
    int n = 0;
    for (int l = 1; l <= levelsPerWorld; l++) {
      if (levelDone(w, l)) n++;
    }
    return n;
  }

  /// يسجّل إكمال مرحلة ويعيد الجمرات المكتسبة
  int complete(int w, int l, int embers, int seconds) {
    final k = id(w, l);
    done.add(k);
    final prev = bestEmbers[k] ?? 0;
    final gain = embers > prev ? embers - prev : 0;
    if (embers > prev) bestEmbers[k] = embers;
    final pt = bestTime[k];
    if (pt == null || seconds < pt) bestTime[k] = seconds;
    coins += gain;
    last = k;
    return gain;
  }

  // الترقيات
  int get maxHearts => 5 + heartUp;
  int get dashCooldown => 40 - dashUp * 6;
  int get hammerDamage => 2 + hammerUp;
  int costHeart() => 30 + 25 * heartUp;
  int costDash() => 25 + 20 * dashUp;
  int costHammer() => 40 + 40 * hammerUp;
  bool get heartMax => heartUp >= 3;
  bool get dashMax => dashUp >= 3;
  bool get hammerMax => hammerUp >= 2;
}
