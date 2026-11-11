// مولّد المراحل: مكتبة مقاطع (chunks) مصمّمة يدوياً، كل عالم له طقم عقبات خاص به،
// وكل مرحلة تُركَّب بتسلسل مختلف حسب العالم ورقم المرحلة، مع تدرّج في الصعوبة.
// كل المقاطع محسوبة على قدرات الشخصية: أقصى ارتفاع قفز ~95، سرعة 3، اندفاع ~80.
import 'level.dart';

class _Kit {
  final int pool; // 0 أشواك، 2 سائل خطر (حمم/سم/مستنقع)
  final int crate; // نوع العنصر القابل للتكسير الشائع
  final List<int> timed; // أنواع الفخاخ الزمنية
  final int fall, roll; // نوع الساقط والمتدحرج (-1 غير مستخدم)
  final List<String> sig; // المقاطع المميّزة للعالم بترتيب الظهور
  final List<int> foes; // أنواع الأعداء
  const _Kit(this.pool, this.crate, this.timed, this.fall, this.roll, this.sig, this.foes);
}

const List<_Kit> _kits = [
  // 1 المغارة المنسية
  _Kit(0, 2, [1], 0, 0, ['falling', 'secret', 'crates', 'bridge', 'rolling', 'bed'], [0, 1]),
  // 2 الغابة الملعونة
  _Kit(2, 0, [5], 3, 4, ['timedRow', 'falling', 'bedMover', 'bridge', 'rolling', 'secret'], [2, 0, 1]),
  // 3 كهف الفطر السام
  _Kit(2, 0, [3], 5, -1, ['springs', 'timedRow', 'bed', 'falling', 'secret', 'bridge'], [2, 0, 1]),
  // 4 قلعة الهياكل
  _Kit(0, 1, [6, 1], 0, 0, ['timedRow', 'keydoor', 'bridge', 'shooters', 'secret', 'rolling'], [3, 0, 1]),
  // 5 مملكة الحمم
  _Kit(2, 2, [2], 2, 1, ['bed', 'bedMover', 'bridge', 'falling', 'timedRow', 'rolling'], [0, 1]),
  // 6 مملكة الجليد
  _Kit(0, 3, [1], 1, 3, ['slip', 'falling', 'rolling', 'bedMover', 'bridge', 'springs'], [0, 1, 3]),
  // 7 المقبرة القديمة
  _Kit(0, 2, [1], -1, -1, ['ambush', 'secret', 'keydoor', 'timedRow', 'shooters', 'bridge'], [0, 4, 3]),
  // 8 معبد الأسرار
  _Kit(0, 1, [4, 1], 0, 0, ['vanishers', 'keydoor', 'timedRow', 'secret', 'bridge', 'rolling'], [3, 0]),
  // 9 منجم الكريستال
  _Kit(0, 3, [0, 4], 4, 2, ['rolling', 'falling', 'crates', 'timedRow', 'bedMover', 'secret'], [0, 1, 3]),
  // 10 قلعة الظلام
  _Kit(0, 0, [1, 0, 6], 0, -1, ['vanishers', 'ambush', 'shooters', 'secret', 'timedRow', 'keydoor'], [4, 3, 0]),
  // 11 العالم الأخير
  _Kit(2, 2, [2, 0, 6, 4], 2, 1, ['timedRow', 'vanishers', 'rolling', 'falling', 'bedMover', 'shooters', 'keydoor'], [3, 4, 0, 2]),
];

const List<int> _bossKind = [1, 0, 3, 4, 5, 6, 7, 8, 9, 10, 11];

class LevelGen {
  static LevelConfig build(int world, int idx) {
    final theme = WorldTheme.of(world);
    if (idx == 10) return _boss(world, idx, theme);
    final b = _B(world, idx);
    return b.make(theme);
  }

  static LevelConfig _boss(int world, int idx, WorldTheme theme) {
    final r = mkr(world * 977 + 31);
    final len = world == 11 ? 1600.0 : 1400.0;
    final shift = (world % 3) * 40.0;
    final plats = <Box>[Box(220 + shift, 350, 100, 14), Box(len * .5 - 55, 325 - (world % 2) * 15, 110, 14), Box(len - 340 - shift, 350, 100, 14)];
    if (world >= 6) plats.add(Box(len * .5 - 200, 270, 80, 14));
    final embers = <List<double>>[
      [260 + shift, 320],
      [len * .5, 295],
      [len - 290 - shift, 320],
      [120, 410],
      [len * .38, 410],
      [len * .66, 410],
    ];
    final timed = <TimedSpec>[];
    final springs = <SpringSpec>[];
    // لكل عالم ميزة في ساحة الزعيم
    if (world == 5) {
      timed.add(const TimedSpec(2, 560, kFloorY - 92, 26, 92, 200, 60, 0));
    }
    if (world == 8 || world == 9) {
      springs.add(SpringSpec(len * .5 - 13, kFloorY - 12));
    }
    final ch = ChestSpec(len * .5 - 10, 325 - (world % 2) * 15 - 14);
    r();
    final hp = world == 2 ? 40.0 : (world == 11 ? 90.0 : 34.0 + world * 4);
    return LevelConfig(
      world: world,
      index: idx,
      name: LevelFactory.nameOf(world, idx),
      length: len,
      theme: theme,
      grounds: [Box(0, kFloorY, len, 60)],
      platforms: plats,
      enemies: const [],
      embers: embers,
      chests: [ch],
      timed: timed,
      springs: springs,
      goalX: len - 100,
      boss: BossSpec(Worlds.of(world).bossName, _bossKind[world - 1], len - 350, 380, hp),
      seed: world * 100 + idx,
    );
  }
}

class _B {
  final int world, idx;
  late final _Kit kit;
  late final double Function() r;
  late final double lv;
  final grounds = <Box>[], plats = <Box>[];
  final movs = <MovSpec>[];
  final crumbs = <CrumbleSpec>[];
  final haz = <HazardSpec>[];
  final ens = <EnemySpawn>[];
  final embers = <List<double>>[];
  final chests = <ChestSpec>[];
  final breaks = <BreakSpec>[];
  final timed = <TimedSpec>[];
  final falls = <FallSpec>[];
  final rolls = <RollSpec>[];
  final springs = <SpringSpec>[];
  final kds = <KeyDoorSpec>[];
  final vanish = <VanishSpec>[];
  final slips = <SlipSpec>[];
  final ambush = <AmbushSpec>[];
  bool get early => idx <= 2;

  _B(this.world, this.idx) {
    kit = _kits[world - 1];
    r = mkr(world * 7919 + idx * 104729 + 13);
    lv = ((idx - 1) / 8.0).clamp(0.0, 1.0).toDouble() * 0.85 + (world - 1) * 0.015;
  }

  // ---------- أدوات
  void ground(double x, double L) => grounds.add(Box(x, kFloorY, L, 60));
  void ember(double x, double y) => embers.add([x, y]);

  void foe(double x, double L, {int? force}) {
    final k = force ?? kit.foes[(r() * kit.foes.length).floor() % kit.foes.length];
    final ex = x + 70 + r() * (L - 140);
    switch (k) {
      case 1:
        ens.add(EnemySpawn(ex, x + 20, x + L - 20, 1, 330));
        break;
      case 3:
        ens.add(EnemySpawn(ex, ex - 16, ex + 16, 3));
        break;
      case 4:
        ens.add(EnemySpawn(ex, x, x + L, 4, 370));
        break;
      default:
        ens.add(EnemySpawn(ex, x + 30, x + L - 30, k));
    }
  }

  List<double> brkSize(int k) {
    switch (k) {
      case 1:
        return [24, 30];
      case 2:
        return [34, 30];
      case 3:
        return [22, 36];
      default:
        return [28, 28];
    }
  }

  void crate(double x, {int? kind, bool drop = true}) {
    final k = kind ?? (r() < .35 ? 0 : kit.crate);
    final s = brkSize(k);
    breaks.add(BreakSpec(k, x, kFloorY - s[1], s[0], s[1], drop));
  }

  void pool(double px, double P) {
    if (kit.pool == 0) {
      haz.add(HazardSpec(px, kFloorY - 16, P, 16, 0));
    } else {
      haz.add(HazardSpec(px, kFloorY - 12, P, 12, 2));
    }
  }

  List<double> tg(int k) {
    switch (k) {
      case 0:
        return [46, 38];
      case 1:
        return [40, 24];
      case 2:
        return [26, 92];
      case 3:
        return [58, 44];
      case 4:
        return [20, 100];
      case 5:
        return [34, 36];
      default:
        return [110, 44];
    }
  }

  // ---------- المقاطع (كل مقطع يعيد x الجديد)
  double flat(double x, double L, {bool clear = false}) {
    ground(x, L);
    ember(x + L * .35, 410);
    ember(x + L * .65, 410);
    if (!clear && L >= 260) {
      final n = early ? 1 : (lv > .55 ? 2 : 1);
      for (int i = 0; i < n; i++) {
        foe(x, L);
      }
    }
    return x + L;
  }

  double steps(double x) {
    const L = 380.0;
    ground(x, L);
    final pat = r() < .5;
    final ys = pat ? [384.0, 336.0, 384.0] : [388.0, 342.0, 296.0];
    for (int i = 0; i < 3; i++) {
      final px = x + 70 + i * 100;
      plats.add(Box(px, ys[i], 80, 14));
      ember(px + 40, ys[i] - 26);
    }
    if (!pat) chests.add(ChestSpec(x + 70 + 200 + 50, ys[2] - 14));
    if (lv > .35) ens.add(EnemySpawn(x + 190, x + 60, x + 330, 1, 300));
    return x + L;
  }

  double crates(double x) {
    final n = 2 + (lv > .5 ? 1 : 0);
    final L = 200.0 + n * 100;
    ground(x, L);
    for (int i = 0; i < n; i++) {
      final cx = x + 90 + i * 90;
      crate(cx);
      if (lv > .6 && i == 1) {
        final s = brkSize(0);
        breaks.add(BreakSpec(0, cx, kFloorY - s[1] * 2, s[0], s[1]));
      }
    }
    ember(x + 135, 360);
    if (!early) foe(x, L);
    return x + L;
  }

  double spikes(double x) {
    final n = early ? 1 : 2 + (lv > .6 ? 1 : 0);
    final L = 220.0 + n * 120;
    ground(x, L);
    for (int i = 0; i < n; i++) {
      final sx = x + 110 + i * 120;
      haz.add(HazardSpec(sx, kFloorY - 16, 32 + lv * 10, 16, 0));
      ember(sx + 18, 372);
    }
    if (!early) foe(x, L);
    return x + L;
  }

  double bed(double x) {
    final P = 150 + r() * 60 + lv * 20;
    final L = 160 + P;
    ground(x, L);
    final px = x + 80;
    pool(px, P);
    final k = P < 190 ? 2 : 3;
    final gap = (P - 36 - k * 44) / (k - 1);
    for (int i = 0; i < k; i++) {
      final bx = px + 18 + i * (44 + gap);
      plats.add(Box(bx, 392, 44, 14));
      ember(bx + 22, 366);
    }
    if (lv > .5) foe(x, L);
    return x + L;
  }

  double bedMover(double x) {
    final P = 250 + lv * 30;
    final L = 180 + P;
    ground(x, L);
    final px = x + 90;
    pool(px, P);
    final cx = px + P / 2 - 42;
    final ay = lv > .6 ? 18.0 : 0.0;
    movs.add(MovSpec(cx, 396, 84, P / 2 - 50, ay, 0.022 + lv * 0.01, r() * 3));
    ember(px + P / 2, 360);
    ember(px + P * .25, 360);
    ember(px + P * .75, 360);
    if (lv > .55) foe(x, L);
    return x + L;
  }

  double bridge(double x) {
    final n = 3 + (lv > .5 ? 1 : 0);
    final P = n * 70.0 + 20;
    final L = 160 + P;
    ground(x, L);
    final px = x + 80;
    pool(px, P);
    for (int i = 0; i < n; i++) {
      crumbs.add(CrumbleSpec(px + 8 + i * 70, 396, 56));
      ember(px + 36 + i * 70, 366);
    }
    if (lv > .5) foe(x, L);
    return x + L;
  }

  double timedRow(double x) {
    final n = early ? 1 : 1 + (lv > .35 ? 1 : 0) + (lv > .75 ? 1 : 0);
    final L = 170.0 + n * 170;
    ground(x, L);
    for (int i = 0; i < n; i++) {
      final k = kit.timed[(r() * kit.timed.length).floor() % kit.timed.length];
      final g = tg(k);
      final tx = x + 150 + i * 170;
      final period = 170 - lv * 30;
      final on = 48 + lv * 18;
      timed.add(TimedSpec(k, tx, kFloorY - g[1], g[0], g[1], period, k == 6 ? period : on, r() * period));
      ember(tx + g[0] / 2, 372);
    }
    if (!early && lv > .4) foe(x + 40, L - 80);
    return x + L;
  }

  double falling(double x) {
    final n = 2 + (lv > .5 ? 1 : 0);
    final L = 200.0 + n * 120;
    ground(x, L);
    for (int i = 0; i < n; i++) {
      final period = (160 - lv * 40);
      falls.add(FallSpec(kit.fall, x + 110 + i * 115, period, i * 47.0 + r() * 20));
    }
    ember(x + L / 2, 410);
    if (!early) foe(x, L);
    return x + L;
  }

  double rolling(double x) {
    final L = 560.0;
    ground(x, L);
    final period = 200 - lv * 45;
    rolls.add(RollSpec(kit.roll, x + 40, x + L - 30, period, r() * 60));
    if (lv > .6) rolls.add(RollSpec(kit.roll, x + 40, x + L - 30, period, 100 + r() * 50));
    ember(x + 200, 366);
    ember(x + 330, 366);
    if (lv > .3) crate(x + 260);
    return x + L;
  }

  double springs_(double x) {
    const L = 380.0;
    ground(x, L);
    springs.add(SpringSpec(x + 70, kFloorY - 12));
    plats.add(Box(x + 125, 290, 100, 14));
    chests.add(ChestSpec(x + 175, 290 - 14));
    ember(x + 135, 262);
    ember(x + 215, 262);
    ember(x + 100, 330);
    if (!early) foe(x + 200, L - 200);
    return x + L;
  }

  double keydoor(double x) {
    const L = 640.0;
    ground(x, L);
    plats.add(Box(x + 70, 382, 70, 14));
    plats.add(Box(x + 150, 334, 70, 14));
    plats.add(Box(x + 235, 288, 70, 14));
    kds.add(KeyDoorSpec(x + 262, 288 - 26, x + L - 110));
    ember(x + 105, 354);
    ember(x + 185, 306);
    foe(x + 320, 200);
    ember(x + 420, 410);
    return x + L;
  }

  double secret(double x) {
    const L = 300.0;
    ground(x, L);
    breaks.add(BreakSpec(4, x + 80, kFloorY - 62, 24, 62, false));
    plats.add(Box(x + 104, kFloorY - 86, 84, 14));
    chests.add(ChestSpec(x + 125, kFloorY - 14));
    ember(x + 160, 420);
    ember(x + 175, kFloorY - 100);
    return x + L;
  }

  double vanishers(double x) {
    final hidden = world == 10 && !(idx % 2 == 0);
    final P = 322 + lv * 20;
    final L = 170 + P;
    ground(x, L);
    final px = x + 85;
    pool(px, P);
    final gap = (P - 28 - 4 * 46) / 3;
    for (int i = 0; i < 4; i++) {
      final bx = px + 14 + i * (46 + gap);
      vanish.add(VanishSpec(bx, 396, 46, hidden ? 0.0 : 150.0, i * 38.0, hidden));
      ember(bx + 23, 366);
    }
    if (lv > .5) foe(x, L);
    return x + L;
  }

  double slip(double x) {
    const L = 440.0;
    ground(x, L);
    slips.add(SlipSpec(x + 20, L - 40));
    haz.add(HazardSpec(x + 150, kFloorY - 16, 30, 16, 0));
    haz.add(HazardSpec(x + 290, kFloorY - 16, 30, 16, 0));
    ember(x + 165, 372);
    ember(x + 305, 372);
    if (lv > .3) crate(x + 220);
    foe(x, L);
    return x + L;
  }

  double shooters(double x) {
    const L = 480.0;
    ground(x, L);
    crate(x + 140);
    crate(x + 300);
    ens.add(EnemySpawn(x + 230, x + 222, x + 238, 3));
    if (lv > .5) ens.add(EnemySpawn(x + 420, x + 412, x + 428, 3));
    ember(x + 90, 410);
    ember(x + 360, 410);
    return x + L;
  }

  double ambushChunk(double x) {
    const L = 500.0;
    ground(x, L);
    final graves = world == 7;
    ambush.add(AmbushSpec(x + 170, graves ? 0 : 4, graves));
    ambush.add(AmbushSpec(x + 340, 4, graves));
    ember(x + 100, 410);
    ember(x + 255, 380);
    ember(x + 420, 410);
    return x + L;
  }

  double gauntlet(double x) {
    x = timedRow(x);
    x = shooters(x);
    return crates(x);
  }

  double chunk(String n, double x) {
    switch (n) {
      case 'steps':
        return steps(x);
      case 'crates':
        return crates(x);
      case 'spikes':
        return spikes(x);
      case 'bed':
        return bed(x);
      case 'bedMover':
        return bedMover(x);
      case 'bridge':
        return bridge(x);
      case 'timedRow':
        return timedRow(x);
      case 'falling':
        return falling(x);
      case 'rolling':
        return rolling(x);
      case 'springs':
        return springs_(x);
      case 'keydoor':
        return keydoor(x);
      case 'secret':
        return secret(x);
      case 'vanishers':
        return vanishers(x);
      case 'slip':
        return slip(x);
      case 'shooters':
        return shooters(x);
      case 'ambush':
        return ambushChunk(x);
      case 'gauntlet':
        return gauntlet(x);
      default:
        return flat(x, 260 + r() * 120);
    }
  }

  LevelConfig make(WorldTheme theme) {
    final target = 2300.0 + idx * 150 + world * 40 + r() * 160;
    final tier = idx <= 2 ? 3 : (idx <= 4 ? 4 : kit.sig.length);
    final a = kit.sig.take(tier < kit.sig.length ? tier : kit.sig.length).toList();
    final f1 = a[(idx + world) % a.length];
    final f2 = a[(idx * 2 + world * 3 + 1) % a.length];
    const basics = ['flat', 'steps', 'crates', 'spikes'];
    double x = flat(0, 420, clear: true);
    int i = 0;
    String prev = 'flat';
    int keyUsed = 0;
    while (x < target - 650) {
      String n;
      if (i == 0) {
        n = f1;
      } else if (i == 1) {
        n = 'steps';
      } else if (i == 2) {
        n = f2;
      } else {
        final q = r();
        if (idx >= 7 && q < (idx >= 9 ? .3 : .18)) {
          n = 'gauntlet';
        } else if (q < .6) {
          n = a[(r() * a.length).floor() % a.length];
        } else {
          n = basics[(r() * basics.length).floor() % basics.length];
        }
      }
      if (n == prev && n != 'flat') n = basics[(r() * basics.length).floor() % basics.length];
      if (n == 'keydoor') {
        if (keyUsed >= 1) n = 'steps';
        keyUsed++;
      }
      x = chunk(n, x);
      prev = n;
      i++;
    }
    final len = x + 460;
    ground(x, 460);
    ember(x + 120, 410);
    ember(x + 240, 410);
    ember(x + 330, 410);
    return LevelConfig(
      world: world,
      index: idx,
      name: LevelFactory.nameOf(world, idx),
      length: len,
      theme: theme,
      grounds: grounds,
      platforms: plats,
      movs: movs,
      crumbs: crumbs,
      hazards: haz,
      enemies: ens,
      embers: embers,
      chests: chests,
      breaks: breaks,
      timed: timed,
      falls: falls,
      rolls: rolls,
      springs: springs,
      keyDoors: kds,
      vanish: vanish,
      slips: slips,
      ambush: ambush,
      goalX: len - 110,
      seed: world * 100 + idx,
    );
  }
}
