// بيانات المرحلة: الأرض، المنصات، الأعداء، الجمرات

const double kW = 360;
const double kH = 500;
const double kLW = 2450;
const double kMaxView = 1300; // أقصى عرض مرئي (للوضع الأفقي)
const double kFloorY = 440;

class Box {
  double x, y, w, h;
  Box(this.x, this.y, this.w, this.h);
  bool hits(Box o) => x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
}

class Level {
  static const List<List<double>> _g = [
    [0, 500],
    [580, 400],
    [1060, 500],
    [1640, 810],
  ];
  static const List<List<double>> _p = [
    [200, 370, 90],
    [330, 310, 90],
    [700, 360, 100],
    [860, 300, 80],
    [1180, 350, 100],
    [1330, 290, 100],
    [1700, 370, 120],
    [2000, 360, 80],
    [2150, 300, 90],
  ];

  static final List<Box> grounds = _g.map((a) => Box(a[0], kFloorY, a[1], 60)).toList();
  static final List<Box> platforms = _p.map((a) => Box(a[0], a[1], a[2], 14)).toList();
  static final List<Box> solids = <Box>[
    ...grounds,
    ...platforms,
    Box(1900, 400, 30, 40),
    Box(kLW - 10, 0, 10, kH), // جدار يمين
    Box(-10, 0, 10, kH), // جدار يسار
  ];

  static const double goalX = 2330;
  static const double goalY = 370;

  // x, min, max, (y اختياري = عدو طائر)
  static const List<List<double>> enemies = [
    [300, 240, 480],
    [700, 600, 960],
    [1230, 1080, 1540],
    [1800, 1660, 2000],
    [2100, 2060, 2380],
    [1360, 1330, 1430, 262],
  ];

  // مواقع الجمرات القابلة للجمع (x, y)
  static const List<List<double>> embers = [
    [120, 410], [250, 410], [245, 345], [375, 285], [440, 405],
    [540, 365], [650, 412], [750, 335], [900, 275], [820, 412],
    [1020, 360], [1100, 412], [1230, 325], [1380, 265], [1300, 412],
    [1450, 412], [1600, 370], [1760, 345], [1915, 378], [2040, 335],
    [2195, 275], [2290, 410],
  ];
}
