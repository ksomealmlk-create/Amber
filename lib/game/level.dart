// نظام المراحل: ثوابت، ثيمات العوالم، LevelConfig، ومصنع المراحل
import 'dart:ui' show Color;
import 'levelgen.dart';
import 'world1.dart';
import 'world2.dart';
import 'world3.dart';
import 'world4.dart';
import 'world5.dart';
import 'world6.dart';
import 'world7.dart';
import 'world8.dart';
import 'world9.dart';
import 'world10.dart';
import 'world11.dart';

const double kW = 360;
const double kH = 500;
const double kMaxView = 1300;
const double kFloorY = 440;

double Function() mkr(int seed) {
  int s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  return () {
    s = (s * 16807) % 2147483647;
    return s / 2147483647;
  };
}

double cl(double v, double a, double b) => v < a ? a : (v > b ? b : v);

class C3 {
  final int r, g, b;
  const C3(this.r, this.g, this.b);
  Color a(double al) => Color.fromRGBO(r, g, b, al);
}

class Box {
  double x, y, w, h;
  Box(this.x, this.y, this.w, this.h);
  bool hits(Box o) => x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
}

enum WallStyle { bricks, trunks }

/// ثيم العالم: كل الألوان وأسلوب الخلفية
class WorldTheme {
  final String key;
  final List<Color> sky;
  final C3 blobA, blobB, moonGlow;
  final Color moonA, moonB;
  final List<Color> mt1, mt2;
  final int towers1;
  final C3 fog, orb, rune;
  final WallStyle wall;
  final double wallHue, wallSat;
  final Color wallBase, archStroke, tintTop, tintBottom;
  final bool soil;
  final double gtHue, gtSat;
  final Color edge, edgeGlow, grass1, grass2, grassTip;
  final List<Color> spikes;
  final double dark;
  final Color hazA, hazB;
  final bool wood;

  const WorldTheme({
    this.key = 'cave',
    this.sky = const [Color(0xFF03050B), Color(0xFF0A1630), Color(0xFF12335A), Color(0xFF1B4A6E)],
    this.blobA = const C3(90, 70, 170),
    this.blobB = const C3(40, 160, 175),
    this.moonGlow = const C3(170, 200, 255),
    this.moonA = const Color(0xFFF6FAFF),
    this.moonB = const Color(0xFFC3D4F6),
    this.mt1 = const [Color(0xFF102650), Color(0xFF0A1630), Color(0x5278AAFF)],
    this.mt2 = const [Color(0xFF0C1B38), Color(0xFF08122A), Color(0x405A8CE6)],
    this.towers1 = 4,
    this.fog = const C3(120, 170, 230),
    this.orb = const C3(140, 170, 255),
    this.rune = const C3(130, 220, 255),
    this.wall = WallStyle.bricks,
    this.wallHue = 218,
    this.wallSat = .38,
    this.wallBase = const Color(0xFF050A14),
    this.archStroke = const Color(0xFF27487A),
    this.tintTop = const Color(0x383C6EBE),
    this.tintBottom = const Color(0x80000410),
    this.soil = false,
    this.gtHue = 220,
    this.gtSat = .4,
    this.edge = const Color(0xFF3A6AA6),
    this.edgeGlow = const Color(0x4078B4FF),
    this.grass1 = const Color(0xFF2A7A68),
    this.grass2 = const Color(0xFF1B5252),
    this.grassTip = const Color(0xCC8CFFE1),
    this.spikes = const [Color(0xFF0A1426), Color(0xFF0C1A33), Color(0xFF08101F)],
    this.dark = .58,
    this.hazA = const Color(0xFF1B2A44),
    this.hazB = const Color(0xFF8CC8FF),
    this.wood = false,
  });

  static const WorldTheme cave = WorldTheme();

  static final Map<int, WorldTheme> _cache = {};
  static WorldTheme of(int w) {
    if (w == 1) return cave;
    if (w == 2) return forest;
    if (w == 3) return mush;
    if (w == 4) return castle;
    return _cache.putIfAbsent(w, () => _make(w));
  }

  static List<int> _mx(List<int> a, List<int> b, double t) => [for (int i = 0; i < 3; i++) (a[i] + (b[i] - a[i]) * t).round()];
  static Color _c(List<int> v, [double a = 1]) => Color.fromRGBO(v[0], v[1], v[2], a);
  static C3 _k(List<int> v) => C3(v[0], v[1], v[2]);

  static WorldTheme _make(int w) {
    // s0,s1,s2 = ألوان السماء، acc = لون التوهج، hue/sat للجدران
    late List<int> s0, s1, s2, acc;
    double hue = 220, sat = .3, dark = .55;
    WallStyle wall = WallStyle.bricks;
    bool soil = false;
    int towers = 0;
    List<int>? hz;
    switch (w) {
      case 3:
        s0 = [10, 6, 20]; s1 = [42, 16, 72]; s2 = [90, 42, 122]; acc = [200, 120, 255];
        hue = 280; sat = .35; soil = true; dark = .52;
        break;
      case 4:
        s0 = [8, 8, 10]; s1 = [38, 38, 46]; s2 = [62, 62, 74]; acc = [190, 200, 220];
        hue = 230; sat = .08; towers = 4;
        break;
      case 5:
        s0 = [20, 4, 4]; s1 = [90, 20, 8]; s2 = [180, 64, 14]; acc = [255, 140, 60];
        hue = 8; sat = .5; dark = .45; hz = [255, 110, 30];
        break;
      case 6:
        s0 = [6, 16, 28]; s1 = [30, 74, 112]; s2 = [124, 184, 224]; acc = [170, 230, 255];
        hue = 200; sat = .45; dark = .42;
        break;
      case 7:
        s0 = [5, 6, 10]; s1 = [26, 30, 46]; s2 = [52, 60, 84]; acc = [150, 175, 160];
        hue = 240; sat = .15; wall = WallStyle.trunks; soil = true;
        break;
      case 8:
        s0 = [16, 12, 4]; s1 = [62, 48, 16]; s2 = [122, 100, 34]; acc = [255, 215, 120];
        hue = 40; sat = .4; dark = .5;
        break;
      case 9:
        s0 = [4, 8, 14]; s1 = [14, 58, 80]; s2 = [34, 160, 180]; acc = [90, 235, 255];
        hue = 190; sat = .5; dark = .5;
        break;
      case 10:
        s0 = [2, 2, 4]; s1 = [20, 16, 30]; s2 = [42, 32, 64]; acc = [170, 130, 230];
        hue = 270; sat = .2; dark = .6; towers = 4;
        break;
      default:
        s0 = [10, 4, 16]; s1 = [58, 16, 80]; s2 = [180, 48, 140]; acc = [255, 110, 210];
        hue = 320; sat = .4; dark = .52;
        break;
    }
    const white = [255, 255, 255];
    const black = [0, 0, 0];
    return WorldTheme(
      key: 'w$w',
      sky: [_c(s0), _c(_mx(s0, s1, .6)), _c(s1), _c(s2)],
      blobA: _k(acc),
      blobB: _k(_mx(acc, s2, .5)),
      moonGlow: _k(_mx(acc, white, .5)),
      moonA: _c(_mx(acc, white, .9)),
      moonB: _c(_mx(acc, white, .6)),
      mt1: [_c(_mx(s1, s0, .4)), _c(_mx(s0, black, .2)), _c(acc, .32)],
      mt2: [_c(_mx(s0, s1, .3)), _c(_mx(s0, black, .4)), _c(acc, .25)],
      towers1: towers,
      fog: _k(_mx(acc, s2, .4)),
      orb: _k(acc),
      rune: _k(_mx(acc, white, .3)),
      wall: wall,
      wallHue: hue,
      wallSat: sat,
      wallBase: _c(_mx(s0, black, .3)),
      archStroke: _c(_mx(s1, acc, .4)),
      tintTop: _c(acc, .2),
      tintBottom: _c(s0, .55),
      soil: soil,
      gtHue: hue,
      gtSat: sat,
      edge: _c(_mx(acc, s1, .5)),
      edgeGlow: _c(acc, .3),
      grass1: _c(_mx(acc, s0, .6)),
      grass2: _c(_mx(acc, s0, .8)),
      grassTip: _c(acc, .8),
      spikes: [_c(_mx(s0, s1, .25)), _c(_mx(s0, s1, .4)), _c(_mx(s0, black, .2))],
      dark: dark,
      hazA: _c(_mx(s1, black, .5)),
      hazB: _c(hz ?? acc),
      wood: false,
    );
  }


  /// العالم الثالث «كهف الفطر السام»: بنفسجي وأخضر سام متوهج
  static const WorldTheme mush = WorldTheme(
    key: 'w3',
    sky: [Color(0xFF05030C), Color(0xFF120A26), Color(0xFF241046), Color(0xFF123A3A)],
    blobA: C3(150, 70, 230),
    blobB: C3(70, 220, 120),
    moonGlow: C3(190, 150, 255),
    moonA: Color(0xFFF2E8FF),
    moonB: Color(0xFFC9B0F0),
    mt1: [Color(0xFF1E1040), Color(0xFF0C0620), Color(0x52B48CFF)],
    mt2: [Color(0xFF140A2E), Color(0xFF080416), Color(0x4078E69A)],
    towers1: 0,
    fog: C3(120, 220, 140),
    orb: C3(170, 255, 120),
    rune: C3(190, 150, 255),
    wall: WallStyle.bricks,
    wallHue: 285,
    wallSat: .38,
    wallBase: Color(0xFF07040F),
    archStroke: Color(0xFF3E2A6E),
    tintTop: Color(0x3A8C46D2),
    tintBottom: Color(0x8004000E),
    soil: true,
    gtHue: 280,
    gtSat: .34,
    edge: Color(0xFF6E4AB4),
    edgeGlow: Color(0x40B48CFF),
    grass1: Color(0xFF2E8A5A),
    grass2: Color(0xFF1B4E52),
    grassTip: Color(0xCCB8FF8C),
    spikes: [Color(0xFF0A0618), Color(0xFF100824), Color(0xFF06030E)],
    dark: .5,
    hazA: Color(0xFF1C1030),
    hazB: Color(0xFFB4FF50),
    wood: false,
  );

  /// العالم الرابع «قلعة الهياكل»: حجر رمادي مزرق، مشاعل برتقالية، ضباب بارد
  static const WorldTheme castle = WorldTheme(
    key: 'w4',
    sky: [Color(0xFF040508), Color(0xFF0C0E16), Color(0xFF181B28), Color(0xFF262A3A)],
    blobA: C3(90, 110, 170),
    blobB: C3(255, 150, 70),
    moonGlow: C3(170, 190, 230),
    moonA: Color(0xFFE8ECF6),
    moonB: Color(0xFFB4BCD2),
    mt1: [Color(0xFF14172A), Color(0xFF0A0C16), Color(0x4A8C9CD2)],
    mt2: [Color(0xFF0E1020), Color(0xFF070810), Color(0x3A6E7EB4)],
    towers1: 5,
    fog: C3(150, 165, 200),
    orb: C3(255, 170, 90),
    rune: C3(170, 200, 255),
    wall: WallStyle.bricks,
    wallHue: 225,
    wallSat: .1,
    wallBase: Color(0xFF06070C),
    archStroke: Color(0xFF3A3F56),
    tintTop: Color(0x30506AA0),
    tintBottom: Color(0x88020208),
    soil: false,
    gtHue: 225,
    gtSat: .1,
    edge: Color(0xFF59607C),
    edgeGlow: Color(0x30FFB070),
    grass1: Color(0xFF3A4054),
    grass2: Color(0xFF262A3A),
    grassTip: Color(0xAAD8DCEC),
    spikes: [Color(0xFF080A12), Color(0xFF0C0E18), Color(0xFF05060A)],
    dark: .55,
    hazA: Color(0xFF1C2030),
    hazB: Color(0xFFD8DCEC),
    wood: false,
  );

  static const WorldTheme forest = WorldTheme(
    key: 'forest',
    sky: [Color(0xFF020806), Color(0xFF06180F), Color(0xFF0C3523), Color(0xFF16553A)],
    blobA: C3(40, 150, 90),
    blobB: C3(120, 190, 70),
    moonGlow: C3(170, 255, 200),
    moonA: Color(0xFFF2FFF4),
    moonB: Color(0xFFB9E6C8),
    mt1: [Color(0xFF0C2A1E), Color(0xFF07170F), Color(0x5278FFB4)],
    mt2: [Color(0xFF08201A), Color(0xFF051410), Color(0x405AE6A0)],
    towers1: 0,
    fog: C3(120, 210, 170),
    orb: C3(150, 255, 170),
    rune: C3(150, 255, 160),
    wall: WallStyle.trunks,
    wallBase: Color(0xFF050F0A),
    tintTop: Color(0x3828A064),
    tintBottom: Color(0x80000A04),
    soil: true,
    gtHue: 28,
    gtSat: .35,
    edge: Color(0xFF4A7A3A),
    edgeGlow: Color(0x4090FF90),
    grass1: Color(0xFF2E8A4A),
    grass2: Color(0xFF1F5E34),
    grassTip: Color(0xCC9CFFB0),
    spikes: [Color(0xFF06150E), Color(0xFF081C12), Color(0xFF04100A)],
    dark: .5,
    hazA: Color(0xFF2A1A12),
    hazB: Color(0xFFFF5A4A),
    wood: true,
  );
}

// ---------- مواصفات عناصر المرحلة
class EnemySpawn {
  final double x, min, max;
  final double? y;
  final int kind; // 0 زاحف، 1 طائر، 2 عنكبوت
  const EnemySpawn(this.x, this.min, this.max, this.kind, [this.y]);
}

class MovSpec {
  final double x, y, w, ax, ay, sp, ph;
  const MovSpec(this.x, this.y, this.w, this.ax, this.ay, this.sp, this.ph);
}

class CrumbleSpec {
  final double x, y, w;
  const CrumbleSpec(this.x, this.y, this.w);
}

class HazardSpec {
  final double x, y, w, h;
  final int kind;
  const HazardSpec(this.x, this.y, this.w, this.h, this.kind);
}

class ChestSpec {
  final double x, y;
  const ChestSpec(this.x, this.y);
}

class BossSpec {
  final String name;
  final int kind;
  final double x, trigger, hp;
  const BossSpec(this.name, this.kind, this.x, this.trigger, this.hp);
}

// ---------- مواصفات العناصر التفاعلية الجديدة
/// عنصر قابل للتكسير: kind 0 صندوق، 1 برميل، 2 صخرة، 3 بلورة/جليد، 4 جدار سري
class BreakSpec {
  final double x, y, w, h;
  final int kind;
  final bool drop;
  const BreakSpec(this.kind, this.x, this.y, this.w, this.h, [this.drop = true]);
}

/// فخ زمني: 0 سلك كهربائي، 1 أشواك تظهر، 2 نافورة نار، 3 سحابة سامة، 4 شعاع ضوء، 5 نبات يعضّ، 6 نصل متأرجح
class TimedSpec {
  final int kind;
  final double x, y, w, h, period, on, phase;
  /// > 0: لا يعمل الفخ إلا عندما يصل الزعيم إلى هذه المرحلة من القتال (ساحة الحارس الحجري)
  final int minPhase;
  const TimedSpec(this.kind, this.x, this.y, this.w, this.h, this.period, this.on, this.phase, [this.minPhase = 0]);
}

/// جسم يسقط من السقف مع تحذير: 0 صخرة، 1 جليد، 2 صخرة نارية، 3 غصن، 4 شظية كريستال، 5 كتلة فطر
class FallSpec {
  final int kind;
  final double x, period, phase;
  const FallSpec(this.kind, this.x, this.period, this.phase);
}

/// جسم يتدحرج على الأرض من x1 إلى x0: 0 صخرة، 1 كرة نار، 2 عربة منجم، 3 كرة ثلج، 4 جذع
class RollSpec {
  final int kind;
  final double x0, x1, period, phase;
  const RollSpec(this.kind, this.x0, this.x1, this.period, this.phase);
}

class SpringSpec {
  final double x, y;
  /// قوة القفز (1.0 = الافتراضي): فطر نابض يقذف اللاعب لارتفاعات مختلفة
  final double power;
  const SpringSpec(this.x, this.y, [this.power = 1.0]);
}

/// فقاعة سامة عائمة تنفجر عند ملامستها (الضرب بالمطرقة يفجّرها بأمان). تعود بعد فترة
class BubbleSpec {
  final double x, y, ax, ay, sp, ph;
  const BubbleSpec(this.x, this.y, this.ax, this.ay, this.sp, this.ph);
}

/// منطقة ضباب سام: تقل الرؤية داخلها (تعتيم أخضر حول اللاعب)
class FogSpec {
  final double x0, x1, density;
  const FogSpec(this.x0, this.x1, [this.density = 1.0]);
}

class KeyDoorSpec {
  final double kx, ky, dx;
  /// y لأسفل الباب (الافتراضي: الأرضية)
  final double bottom;
  const KeyDoorSpec(this.kx, this.ky, this.dx, [this.bottom = kFloorY]);
}

/// نقطة حفظ: x مركز الفانوس، gy سطح الأرض الذي يقف عليه اللاعب عند الاستعادة
class CheckSpec {
  final double x, gy;
  const CheckSpec(this.x, this.gy);
}

/// منصة تختفي وتظهر (period > 0) أو منصة مخفية تنكشف عند الاقتراب (hidden)
class VanishSpec {
  final double x, y, w, period, phase;
  final bool hidden;
  const VanishSpec(this.x, this.y, this.w, this.period, this.phase, [this.hidden = false]);
}

class SlipSpec {
  final double x, w;
  const SlipSpec(this.x, this.w);
}

/// منطقة رياح: تدفع اللاعب أفقياً (force موجبة لليمين، سالبة لليسار)
class WindSpec {
  final double x0, x1, force;
  const WindSpec(this.x0, this.x1, this.force);
}

/// كمين: يخرج عدو عندما يقترب اللاعب (kind 0 زاحف من قبر، 4 شبح)
class AmbushSpec {
  final double x;
  final int kind;
  final bool marker;
  const AmbushSpec(this.x, this.kind, [this.marker = true]);
}

class LevelConfig {
  final int world, index;
  final String name;
  final double length;
  final WorldTheme theme;
  final List<Box> grounds, platforms, extra;
  final List<MovSpec> movs;
  final List<CrumbleSpec> crumbs;
  final List<HazardSpec> hazards;
  final List<EnemySpawn> enemies;
  final List<List<double>> embers;
  final List<ChestSpec> chests;
  final double goalX, goalY;
  final BossSpec? boss;
  final int seed;
  final bool classic;
  final List<BreakSpec> breaks;
  final List<TimedSpec> timed;
  final List<FallSpec> falls;
  final List<RollSpec> rolls;
  final List<SpringSpec> springs;
  final List<KeyDoorSpec> keyDoors;
  final List<VanishSpec> vanish;
  final List<SlipSpec> slips;
  final List<AmbushSpec> ambush;
  final List<WindSpec> winds;
  /// نقاط الحفظ (إن وُجدت: الموت يعيد اللاعب لآخر نقطة بدل بداية المرحلة)
  final List<CheckSpec> checks;
  final List<BubbleSpec> bubbles;
  final List<FogSpec> fogs;
  late final List<Box> solids;

  LevelConfig({
    required this.world,
    required this.index,
    required this.name,
    required this.length,
    required this.theme,
    required this.grounds,
    required this.platforms,
    this.extra = const [],
    this.movs = const [],
    this.crumbs = const [],
    this.hazards = const [],
    required this.enemies,
    required this.embers,
    this.chests = const [],
    required this.goalX,
    this.goalY = 370,
    this.boss,
    this.seed = 1,
    this.classic = false,
    this.breaks = const [],
    this.timed = const [],
    this.falls = const [],
    this.rolls = const [],
    this.springs = const [],
    this.keyDoors = const [],
    this.vanish = const [],
    this.slips = const [],
    this.ambush = const [],
    this.winds = const [],
    this.checks = const [],
    this.bubbles = const [],
    this.fogs = const [],
  }) {
    solids = [...grounds, ...platforms, ...extra, Box(length - 10, 0, 10, kH), Box(-10, 0, 10, kH)];
  }

  String get id => 'w${world}l$index';
  int get totalEmbers => embers.length + chests.length * 3 + (boss != null ? 8 : 0) + breaks.where((b) => b.drop).length + keyDoors.length * 2;
}

// ---------- معلومات العوالم لشاشة الاختيار
class WorldInfo {
  final int id;
  final String name, desc, bossName;
  final bool ready;
  final List<Color> thumb; // ألوان السماء للصورة المصغرة
  final Color ground;
  const WorldInfo(this.id, this.name, this.desc, this.bossName, this.ready, this.thumb, this.ground);
}

class Worlds {
  static const List<WorldInfo> all = [
    WorldInfo(1, 'المغارة المنسية', 'كهف مظلم تسكنه الجمرات والأعداء الزاحفة', 'الحارس الحجري', true,
        [Color(0xFF03050B), Color(0xFF12335A), Color(0xFF1B4A6E)], Color(0xFF1A2A4A)),
    WorldInfo(2, 'الغابة الملعونة', 'أشجار ضخمة وعناكب سامة وجسور معلقة', 'ملك العناكب', true,
        [Color(0xFF020806), Color(0xFF0C3523), Color(0xFF16553A)], Color(0xFF2A1F14)),
    WorldInfo(3, 'كهف الفطر السام', 'فطر عملاق وبحيرات سامة وجذور حية وضباب قاتل', 'ملك الفطر السام', true,
        [Color(0xFF0A0614), Color(0xFF2A1048), Color(0xFF5A2A7A)], Color(0xFF2A1840)),
    WorldInfo(4, 'قلعة الهياكل', 'قلعة مظلمة: سيوف وفؤوس وجماجم تطلق النار وأبواب بمفاتيح', 'ملك الهياكل', true,
        [Color(0xFF080808), Color(0xFF26262E), Color(0xFF3E3E4A)], Color(0xFF2A2A34)),
    WorldInfo(5, 'مملكة الحمم', 'براكين وحمم متحركة وصخور متساقطة', 'سيد الحمم', true,
        [Color(0xFF140404), Color(0xFF5A1408), Color(0xFFB4400E)], Color(0xFF3A1208)),
    WorldInfo(6, 'مملكة الجليد', 'كهوف جليدية وأرضيات زلقة وعواصف ثلج', 'ملك الجليد', true,
        [Color(0xFF06101C), Color(0xFF1E4A70), Color(0xFF7CB8E0)], Color(0xFF2A4A68)),
    WorldInfo(7, 'المقبرة القديمة', 'قبور وأشباح وضباب كثيف', 'حارس الموتى', true,
        [Color(0xFF05060A), Color(0xFF1A1E2E), Color(0xFF343C54)], Color(0xFF1E2230)),
    WorldInfo(8, 'معبد الأسرار', 'تماثيل متحركة وألغاز ومفاتيح', 'حارس المعبد', true,
        [Color(0xFF100C04), Color(0xFF3E3010), Color(0xFF7A6422)], Color(0xFF3A2E14)),
    WorldInfo(9, 'منجم الكريستال', 'بلورات مضيئة وعربات وجسور تنهار', 'حارس الكريستال', true,
        [Color(0xFF04080E), Color(0xFF0E3A50), Color(0xFF22A0B4)], Color(0xFF123444)),
    WorldInfo(10, 'قلعة الظلام', 'قلعة ضخمة وغرف سرية وفخاخ متطورة', 'فارس الظلام', true,
        [Color(0xFF020204), Color(0xFF14101E), Color(0xFF2A2040)], Color(0xFF181424)),
    WorldInfo(11, 'العالم الأخير', 'تحديات صعبة وزعيم متعدد المراحل', 'الزعيم الأخير', true,
        [Color(0xFF0A0410), Color(0xFF3A1050), Color(0xFFB4308C)], Color(0xFF2A1038)),
  ];
  static WorldInfo of(int id) => all[id - 1];
}

// ---------- مصنع المراحل
class LevelFactory {
  static const _names1 = [
    'مدخل الكهف', 'ممر الشرارات', 'جسور الهاوية', 'مصعد الأعماق', 'مطر الصخور',
    'سرداب المفاتيح', 'الدربان', 'مصنع الصواعق', 'محنة المغارة', 'عرين الحارس الحجري'
  ];
  static const _names2 = [
    'حافة الغابة', 'الجذور الملتوية', 'جسر الخيوط', 'ممر الأغصان', 'عش الصغار',
    'الغابة الهامسة', 'المستنقع الأخضر', 'الجسور المعلقة', 'وكر العناكب', 'عرين ملك العناكب'
  ];

  static const _names3 = [
    'مدخل الكهف', 'غابة الفطريات العملاقة', 'بحيرة السموم', 'ممر الجذور الحية', 'مستنقع الجراثيم',
    'متاهة الفطر', 'الهاوية الفطرية', 'قلب الكهف', 'مملكة الجراثيم', 'عرش الفطر السام'
  ];

  static const _names4 = [
    'بوابة القلعة', 'ممر الجماجم', 'قاعة السيوف', 'الجسر المعلق', 'سجن الهياكل',
    'برج الموت', 'قاعة الفؤوس', 'سرداب الملك', 'عرش العظام', 'ملك الهياكل'
  ];


  static const _names5 = [
    'طريق البركان', 'الكهف الناري', 'جسر اللهب', 'منجم الحمم', 'بحيرة النار',
    'البركان الداخلي', 'أطلال النار', 'ممر التنين', 'قلب البركان', 'سيد الحمم'
  ];
  static const _names6 = [
    'المدخل المتجمد', 'الغابة الثلجية', 'النهر المتجمد', 'كهف البلورات', 'الجسر الجليدي',
    'عاصفة الثلج', 'القصر المتجمد', 'قمة الجبل', 'قلب الجليد', 'ملك الجليد'
  ];
  static const _names7 = [
    'بوابة المقبرة', 'ساحة القبور', 'سرداب الظلال', 'قاعة التوابيت', 'جسر الأرواح',
    'متاهة العظام', 'برج الساعة', 'مقبرة الملك', 'سرداب الحارس', 'حارس الموتى'
  ];
  static const _names8 = [
    'المدخل القديم', 'قاعة التماثيل', 'غرفة المفاتيح', 'ممر السهام', 'القاعة الدوارة',
    'متاهة المعبد', 'غرفة الميزان', 'معبد الضوء', 'قاعة الأسرار', 'حارس المعبد'
  ];
  static const _names9 = [
    'مدخل المنجم', 'ممر البلورات', 'المصعد القديم', 'الأنفاق المنهارة', 'سكة العربات',
    'بحيرة الكريستال', 'غرفة الليزر', 'المنجم العميق', 'قلب الكريستال', 'حارس الكريستال'
  ];
  static const _names10 = [
    'الطريق إلى القلعة', 'الساحة الخارجية', 'السجن القديم', 'برج الظلال', 'قاعة الفرسان',
    'المكتبة المظلمة', 'الجسر الأسود', 'قاعة السحر', 'عرش الظلام', 'فارس الظلام'
  ];
  static const _names11 = [
    'بوابة النهاية', 'جزر الفراغ', 'الغابة المشوهة', 'أطلال الزمن', 'ممر العوالم',
    'السماء المكسورة', 'متاهة الفراغ', 'حراس النهاية', 'بوابة المصير', 'المعركة النهائية'
  ];

  static String nameOf(int w, int i) {
    if (w == 1) return _names1[i - 1];
    if (w == 2) return _names2[i - 1];
    if (w == 3) return _names3[i - 1];
    if (w == 4) return _names4[i - 1];
    if (w == 5) return _names5[i - 1];
    if (w == 6) return _names6[i - 1];
    if (w == 7) return _names7[i - 1];
    if (w == 8) return _names8[i - 1];
    if (w == 9) return _names9[i - 1];
    if (w == 10) return _names10[i - 1];
    if (w == 11) return _names11[i - 1];
    return '${Worlds.of(w).name} $i';
  }

  static LevelConfig build(int world, int idx) {
    // العالم الأول «المغارة المنسية»: عشر مراحل مصمَّمة يدوياً (أرضيات بفجوات حقيقية، لا تُملأ)
    if (world == 1) return World1.build(idx);
    // العالم الثاني «الغابة»: المراحل العشر مصمَّمة يدوياً
    if (world == 2) return World2.build(idx);
    // العالم الثالث «كهف الفطر السام»: المراحل العشر مصمَّمة يدوياً
    if (world == 3) return World3.build(idx);
    // العالم الرابع «قلعة الهياكل»: المراحل العشر مصمَّمة يدوياً
    if (world == 4) return World4.build(idx);
    // العالم الخامس «مملكة الحمم»: المراحل العشر مصمَّمة يدوياً
    if (world == 5) return World5.build(idx);
    // العالم السادس «مملكة الجليد»: المراحل العشر مصمَّمة يدوياً
    if (world == 6) return World6.build(idx);
    // العالم السابع «المقبرة القديمة»: المراحل العشر مصمَّمة يدوياً
    if (world == 7) return World7.build(idx);
    // العالم الثامن «معبد الأسرار»: المراحل العشر مصمَّمة يدوياً
    if (world == 8) return World8.build(idx);
    // العالم التاسع «منجم الكريستال»: المراحل العشر مصمَّمة يدوياً
    if (world == 9) return World9.build(idx);
    // العالم العاشر «قلعة الظلام»: المراحل العشر مصمَّمة يدوياً
    if (world == 10) return World10.build(idx);
    // العالم الحادي عشر «العالم الأخير»: المراحل العشر مصمَّمة يدوياً
    if (world == 11) return World11.build(idx);
    final cfg = LevelGen.build(world, idx);
    return _solidFloor(cfg);
  }

  /// أرضية كاملة بلا فجوات: كل قطعة أرض تُمدّ حتى بداية التي تليها (والأخيرة حتى نهاية المرحلة).
  /// مواضع القطع الأصلية تبقى كما هي فتبقى نقاط الحفظ تعمل.
  static LevelConfig _solidFloor(LevelConfig c) {
    final gs = [...c.grounds]..sort((a, b) => a.x.compareTo(b.x));
    final filled = <Box>[];
    for (int i = 0; i < gs.length; i++) {
      final g = gs[i];
      final end = i + 1 < gs.length ? gs[i + 1].x : c.length;
      filled.add(Box(g.x, g.y, (end > g.x + g.w ? end : g.x + g.w) - g.x, g.h));
    }
    // منصات الانهيار كانت فوق الفجوات؛ ترتفع لتصبح جسوراً علوية فوق الأرضية الكاملة
    final crumbs = [for (final k in c.crumbs) CrumbleSpec(k.x, k.y >= kFloorY ? 380.0 : k.y, k.w)];
    return LevelConfig(
      world: c.world,
      index: c.index,
      name: c.name,
      length: c.length,
      theme: c.theme,
      grounds: filled,
      platforms: c.platforms,
      extra: c.extra,
      movs: c.movs,
      crumbs: crumbs,
      hazards: c.hazards,
      enemies: c.enemies,
      embers: c.embers,
      chests: c.chests,
      goalX: c.goalX,
      goalY: c.goalY,
      boss: c.boss,
      seed: c.seed,
      classic: c.classic,
      breaks: c.breaks,
      timed: c.timed,
      falls: c.falls,
      rolls: c.rolls,
      springs: c.springs,
      keyDoors: c.keyDoors,
      vanish: c.vanish,
      slips: c.slips,
      ambush: c.ambush,
    );
  }

  // المرحلة الأولى الأصلية كما هي
  static LevelConfig _level1() {
    const g = [[0.0, 500.0], [580.0, 400.0], [1060.0, 500.0], [1640.0, 810.0]];
    const p = [
      [200.0, 370.0, 90.0], [330.0, 310.0, 90.0], [700.0, 360.0, 100.0], [860.0, 300.0, 80.0],
      [1180.0, 350.0, 100.0], [1330.0, 290.0, 100.0], [1700.0, 370.0, 120.0], [2000.0, 360.0, 80.0],
      [2150.0, 300.0, 90.0],
    ];
    const en = [
      EnemySpawn(300, 240, 480, 0),
      EnemySpawn(700, 600, 960, 0),
      EnemySpawn(1230, 1080, 1540, 0),
      EnemySpawn(1800, 1660, 2000, 0),
      EnemySpawn(2100, 2060, 2380, 0),
      EnemySpawn(1360, 1330, 1430, 1, 262),
    ];
    const em = [
      [120.0, 410.0], [250.0, 410.0], [245.0, 345.0], [375.0, 285.0], [440.0, 405.0],
      [540.0, 365.0], [650.0, 412.0], [750.0, 335.0], [900.0, 275.0], [820.0, 412.0],
      [1020.0, 360.0], [1100.0, 412.0], [1230.0, 325.0], [1380.0, 265.0], [1300.0, 412.0],
      [1450.0, 412.0], [1600.0, 370.0], [1760.0, 345.0], [1915.0, 378.0], [2040.0, 335.0],
      [2195.0, 275.0], [2290.0, 410.0],
    ];
    return LevelConfig(
      world: 1,
      index: 1,
      name: nameOf(1, 1),
      length: 2450,
      theme: WorldTheme.cave,
      grounds: g.map((a) => Box(a[0], kFloorY, a[1], 60)).toList(),
      platforms: p.map((a) => Box(a[0], a[1], a[2], 14)).toList(),
      extra: [Box(1900, 400, 30, 40)],
      enemies: en,
      embers: em,
      goalX: 2330,
      goalY: 370,
      seed: 1,
      classic: true,
    );
  }

  static LevelConfig _generate(int world, int idx) {
    final theme = WorldTheme.of(world);
    final r = mkr(world * 7919 + idx * 104729 + 13);
    final d = ((idx - 1) / 9.0) * 0.8 + (world - 1) * 0.25;
    if (world == 2 && idx == 10) return _bossArena(world, idx, theme);

    final len = 2300.0 + idx * 170 + r() * 200;
    final grounds = <Box>[];
    final plats = <Box>[];
    final movs = <MovSpec>[];
    final crumbs = <CrumbleSpec>[];
    final haz = <HazardSpec>[];
    final ens = <EnemySpawn>[];
    final embers = <List<double>>[];
    final chests = <ChestSpec>[];

    void ground(double x, double w) => grounds.add(Box(x, kFloorY, w, 60));
    void ember(double x, double y) => embers.add([x, y]);
    int pickKind() {
      final q = r();
      if (world == 2 || world == 3 || world == 9) return q < .5 ? 2 : (q < .7 ? 0 : 1);
      return q < .75 ? 0 : 1;
    }

    void fill(double x, double L, {bool withEnemies = true}) {
      if (withEnemies && L >= 250) {
        final n = 1 + (d > .9 ? 1 : 0) + (r() < d * .6 ? 1 : 0);
        for (int i = 0; i < n; i++) {
          final k = pickKind();
          final ex = x + 80 + r() * (L - 180);
          if (k == 1) {
            ens.add(EnemySpawn(ex, ex - 70, ex + 70, 1, 300 + r() * 70));
          } else {
            ens.add(EnemySpawn(ex, cl(ex - 100, x + 20, x + L), cl(ex + 100, x, x + L - 20), k));
          }
        }
      }
      ember(x + L * .3, 410);
      ember(x + L * .7, 410);
    }

    double x = 430;
    ground(0, 430);
    ember(150, 410);
    ember(300, 410);
    String last = 'start';
    while (x < len - 650) {
      final opts = <String, double>{
        'flat': 3,
        'gap': 2.5,
        'steps': 2.5,
        'mover': idx >= 3 ? 1.8 : 0,
        'crumble': (idx >= 4 || (world >= 2 && idx >= 2)) ? 1.6 : 0,
        'hazard': idx >= 2 ? 1.8 : 0,
        'secret': idx >= 2 ? 1.3 : 0,
      };
      String pick = 'flat';
      for (int tries = 0; tries < 6; tries++) {
        double tot = 0;
        opts.forEach((k, v) => tot += v);
        double q = r() * tot;
        for (final e in opts.entries) {
          q -= e.value;
          if (q <= 0) {
            pick = e.key;
            break;
          }
        }
        if (pick != last) break;
      }
      last = pick;
      switch (pick) {
        case 'flat': {
          final L = 240 + r() * 260;
          ground(x, L);
          fill(x, L);
          x += L;
          break;
        }
        case 'gap': {
          final gap = cl(52 + r() * (20 + 14 * (d > 1.2 ? 1.2 : d)), 52.0, 86.0);
          ember(x + gap / 2, 380);
          x += gap;
          final L = 220 + r() * 220;
          ground(x, L);
          fill(x, L);
          x += L;
          break;
        }
        case 'steps': {
          final n = 3 + (r() * 3).floor();
          double cx = x + 40 + r() * 24;
          double py = 440 - (30 + r() * 12);
          for (int i = 0; i < n; i++) {
            final w = 70 + r() * 36;
            plats.add(Box(cx, py, w, 14));
            ember(cx + w / 2, py - 26);
            if (i == 1 && d > .5) ens.add(EnemySpawn(cx + w / 2, cx + w / 2 - 40, cx + w / 2 + 40, 1, py - 80));
            double ny = cl(py + (r() * 2 - 1) * 45, 300.0, 410.0);
            final rise = py - ny;
            final maxGap = rise > 25 ? 64.0 : 80.0;
            cx += w + 40 + r() * (maxGap - 40);
            py = ny;
          }
          x = cx;
          final L = 220 + r() * 200;
          ground(x, L);
          fill(x, L);
          x += L;
          break;
        }
        case 'mover': {
          final pit = 210 + r() * 90;
          final center = x + pit / 2;
          final ax = pit / 2 - 85;
          movs.add(MovSpec(center - 42, 400, 84, ax, d > .6 && r() < .5 ? 24 : 0, 0.016 + 0.006 * d, r() * 6));
          ember(center, 345);
          x += pit;
          final L = 220 + r() * 200;
          ground(x, L);
          fill(x, L);
          x += L;
          break;
        }
        case 'crumble': {
          final pit = 230 + r() * 100;
          final n = (pit / 70).floor();
          for (int i = 0; i < n; i++) {
            crumbs.add(CrumbleSpec(x + 8 + i * 70, kFloorY, 56));
            if (i % 2 == 1) ember(x + 8 + i * 70 + 28, 395);
          }
          x += 8 + n * 70 + 6;
          final L = 220 + r() * 200;
          ground(x, L);
          fill(x, L);
          x += L;
          break;
        }
        case 'hazard': {
          final L = 320 + r() * 180;
          ground(x, L);
          final nh = 2 + (d > .7 && r() < .6 ? 1 : 0);
          double hx = x + 90;
          for (int i = 0; i < nh; i++) {
            final w = 26 + r() * 14;
            haz.add(HazardSpec(hx, 424, w, 16, world == 2 ? 1 : 0));
            ember(hx + w / 2, 372);
            hx += w + 100 + r() * 30;
          }
          if (hx < x + L - 40) ember(x + L - 60, 410);
          x += L;
          break;
        }
        default: { // مسار علوي سري وصندوق
          final L = 320 + r() * 120;
          ground(x, L);
          plats.add(Box(x + 60, 380, 80, 14));
          plats.add(Box(x + 160, 335, 80, 14));
          plats.add(Box(x + 260, 290, 80, 14));
          ember(x + 100, 354);
          ember(x + 200, 309);
          chests.add(ChestSpec(x + 290, 290 - 14));
          if (d > .4) ens.add(EnemySpawn(x + 150, x + 40, x + L - 40, world == 2 ? 2 : 0));
          if (d > .6) ens.add(EnemySpawn(x + 200, x + 150, x + 320, 1, 300));
          x += L;
          break;
        }
      }
    }
    final fl = len - x;
    ground(x, fl);
    ember(x + 100, 410);
    ember(x + 250, 410);
    return LevelConfig(
      world: world,
      index: idx,
      name: nameOf(world, idx),
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
      goalX: len - 110,
      seed: world * 100 + idx,
    );
  }

  static LevelConfig _bossArena(int world, int idx, WorldTheme theme) {
    const len = 1400.0;
    return LevelConfig(
      world: world,
      index: idx,
      name: nameOf(world, idx),
      length: len,
      theme: theme,
      grounds: [Box(0, kFloorY, len, 60)],
      platforms: [Box(230, 350, 100, 14), Box(650, 330, 110, 14), Box(1060, 350, 100, 14)],
      enemies: const [],
      embers: const [[280, 320], [705, 300], [1110, 320], [120, 410], [560, 410], [900, 410]],
      chests: [ChestSpec(690, 330 - 14)],
      goalX: 1300,
      boss: const BossSpec('ملك العناكب', 0, 1050, 380, 40),
      seed: world * 100 + idx,
    );
  }
}
