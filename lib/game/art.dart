import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'level.dart';

double hh(double n) {
  final v = math.sin(n * 127.1) * 43758.5453;
  return v - v.floorToDouble();
}

int _ci(double v) {
  final r = v.round();
  return r < 0 ? 0 : (r > 255 ? 255 : r);
}

Color hslc(double h, double s, double l, [double a = 1]) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final hp = h / 60.0;
  final x = c * (1 - ((hp % 2) - 1).abs());
  double r = 0, g = 0, b = 0;
  if (hp < 1) {
    r = c; g = x;
  } else if (hp < 2) {
    r = x; g = c;
  } else if (hp < 3) {
    g = c; b = x;
  } else if (hp < 4) {
    g = x; b = c;
  } else if (hp < 5) {
    r = x; b = c;
  } else {
    r = c; b = x;
  }
  final m = l - c / 2;
  return Color.fromRGBO(_ci((r + m) * 255), _ci((g + m) * 255), _ci((b + m) * 255), a);
}

void glow(Canvas c, double x, double y, double r, C3 col, double a, {bool add = false}) {
  final p = Paint()..shader = ui.Gradient.radial(Offset(x, y), r, [col.a(a), col.a(0)]);
  if (add) p.blendMode = BlendMode.plus;
  c.drawCircle(Offset(x, y), r, p);
}

class Prop {
  final String k;
  final double x, h;
  final int layer;
  final bool dark;
  final C3? glw;
  Prop(this.k, this.x, this.h, this.layer, this.dark, this.glw);
}

class Arch {
  final double x, hw, ah;
  Arch(this.x, this.hw, this.ah);
}

/// شريط خلفية مقسّم لقطع (لتفادي حدود حجم الـ texture)
class Strip {
  static const double tw = 1024, pad = 2, ps = 2;
  final List<ui.Image> tiles;
  final double w, h;
  Strip(this.tiles, this.w, this.h);
  static final Paint _p = Paint()..filterQuality = FilterQuality.medium;

  void draw(Canvas c, double sx, double y, double vw) {
    final x0 = math.max(0.0, math.min(sx, w - vw));
    final x1 = x0 + vw;
    final i0 = (x0 / tw).floor();
    final i1 = ((x1 - 0.001) / tw).floor();
    for (int i = i0; i <= i1; i++) {
      if (i < 0 || i >= tiles.length) continue;
      final a = math.max(x0, i * tw), b = math.min(x1, (i + 1) * tw);
      if (b <= a) continue;
      final src = Rect.fromLTRB((a - i * tw + pad) * ps, 0, (b - i * tw + pad) * ps, h * ps);
      final dst = Rect.fromLTRB(a - x0, y, b - x0, y + h);
      c.drawImageRect(tiles[i], src, dst, _p);
    }
  }

  void dispose() {
    for (final t in tiles) {
      t.dispose();
    }
  }
}

/// عنصر طبيعة: sprite، كل كم بكسل يتكرر، مدى الارتفاع، الطبقة، احتمال النسخة الداكنة، التوهج
class NatSpec {
  final String k;
  final double every, h0, h1, dk;
  final int layer;
  final C3? glow;
  const NatSpec(this.k, this.every, this.h0, this.h1, {this.layer = 1, this.dk = 0, this.glow});
}

/// مجسمات الطبيعة (Quaternius Stylized Nature MegaKit - CC0) موزعة حسب العالم
class Nature {
  static const sprites = [
    'n_tree1', 'n_tree3', 'n_pine1', 'n_pine3', 'n_dead1', 'n_dead3', 'n_twist1', 'n_twist3',
    'n_bush', 'n_bushf', 'n_fern', 'n_grassT', 'n_grassW', 'n_flower3', 'n_flower4', 'n_plant1',
    'n_mush', 'n_lae', 'n_rock1', 'n_rock2', 'n_rock3', 'n_pebR', 'n_pebS',
  ];

  static const _rocks = [
    NatSpec('n_rock1', 330, 30, 56), NatSpec('n_rock2', 380, 26, 50), NatSpec('n_rock3', 420, 28, 54),
    NatSpec('n_pebR', 200, 10, 18), NatSpec('n_pebS', 240, 10, 18),
  ];

  static List<NatSpec> forWorld(String key) {
    switch (key) {
      case 'cave':
        return [
          ..._rocks,
          const NatSpec('n_mush', 360, 36, 70, glow: C3(120, 230, 255)),
          const NatSpec('n_lae', 420, 22, 36, glow: C3(255, 170, 90)),
          const NatSpec('n_fern', 300, 22, 34),
        ];
      case 'forest':
        return [
          ..._rocks,
          const NatSpec('n_tree1', 300, 190, 270, layer: 0, dk: .45),
          const NatSpec('n_tree3', 340, 200, 280, layer: 0, dk: .45),
          const NatSpec('n_pine1', 320, 200, 290, layer: 0, dk: .5),
          const NatSpec('n_pine3', 360, 190, 270, layer: 0, dk: .5),
          const NatSpec('n_bush', 260, 34, 52),
          const NatSpec('n_bushf', 240, 34, 52),
          const NatSpec('n_fern', 150, 24, 38),
          const NatSpec('n_grassT', 120, 28, 46),
          const NatSpec('n_grassW', 160, 28, 46),
          const NatSpec('n_flower3', 220, 24, 40),
          const NatSpec('n_flower4', 240, 24, 40),
          const NatSpec('n_plant1', 260, 26, 42),
          const NatSpec('n_mush', 340, 34, 60, glow: C3(150, 255, 150)),
          const NatSpec('n_lae', 380, 22, 34, glow: C3(255, 190, 90)),
        ];
      case 'w3': // كهف الفطر السام
        return [
          ..._rocks,
          const NatSpec('n_mush', 330, 170, 250, layer: 0, dk: .3, glow: C3(190, 130, 255)),
          const NatSpec('n_mush', 150, 40, 84, glow: C3(150, 255, 130)),
          const NatSpec('n_lae', 150, 24, 44, glow: C3(255, 150, 220)),
          const NatSpec('n_fern', 200, 24, 38),
          const NatSpec('n_plant1', 260, 26, 40),
        ];
      case 'w4': // قلعة الهياكل
        return [
          ..._rocks,
          const NatSpec('n_dead1', 420, 170, 240, layer: 0, dk: .8),
          const NatSpec('n_dead3', 460, 180, 250, layer: 0, dk: .8),
          const NatSpec('n_grassW', 260, 24, 38),
        ];
      case 'w5': // مملكة الحمم
        return [
          ..._rocks,
          const NatSpec('n_dead1', 360, 170, 240, layer: 0, dk: .4),
          const NatSpec('n_twist1', 520, 170, 230, layer: 0, dk: .4),
          const NatSpec('n_bush', 300, 30, 46),
        ];
      case 'w6': // مملكة الجليد
        return [
          ..._rocks,
          const NatSpec('n_pine1', 300, 200, 290, layer: 0, dk: .85),
          const NatSpec('n_pine3', 340, 190, 270, layer: 0, dk: .85),
          const NatSpec('n_grassW', 260, 22, 36, dk: .6),
        ];
      case 'w7': // المقبرة
        return [
          ..._rocks,
          const NatSpec('n_dead1', 280, 170, 250, layer: 0, dk: .55),
          const NatSpec('n_dead3', 320, 180, 260, layer: 0, dk: .55),
          const NatSpec('n_grassT', 150, 26, 42, dk: .5),
          const NatSpec('n_lae', 420, 20, 30, glow: C3(150, 175, 160)),
        ];
      case 'w8': // معبد الأسرار
        return [
          ..._rocks,
          const NatSpec('n_bush', 260, 34, 52),
          const NatSpec('n_bushf', 260, 34, 52),
          const NatSpec('n_plant1', 220, 26, 42),
          const NatSpec('n_flower3', 240, 24, 40),
          const NatSpec('n_flower4', 260, 24, 40),
          const NatSpec('n_grassT', 180, 26, 42),
        ];
      case 'w9': // منجم الكريستال
        return [
          ..._rocks,
          const NatSpec('n_mush', 260, 38, 70, glow: C3(90, 235, 255)),
          const NatSpec('n_lae', 340, 22, 34, glow: C3(120, 230, 255)),
          const NatSpec('n_fern', 300, 22, 34),
        ];
      case 'w10': // قلعة الظلام
        return [
          ..._rocks,
          const NatSpec('n_dead1', 340, 170, 250, layer: 0, dk: .9),
          const NatSpec('n_dead3', 380, 180, 250, layer: 0, dk: .9),
          const NatSpec('n_twist3', 520, 170, 230, layer: 0, dk: .9),
        ];
      default: // العالم 11 وما بعده
        return [
          ..._rocks,
          const NatSpec('n_twist1', 360, 180, 250, layer: 0, dk: .4),
          const NatSpec('n_twist3', 420, 180, 250, layer: 0, dk: .4),
          const NatSpec('n_bushf', 260, 34, 52),
          const NatSpec('n_flower3', 220, 24, 40),
          const NatSpec('n_flower4', 240, 24, 40),
          const NatSpec('n_mush', 300, 36, 66, glow: C3(255, 110, 210)),
        ];
    }
  }
}

/// صور خلفيات العوالم (assets/backgrounds/worldN.jpg): تُحمَّل مرة واحدة وتُشارَك بين اللعب والقوائم.
/// إن غابت صورة عالم ما يبقى الرسم البرمجي القديم لذلك العالم.
class Backdrops {
  static final Map<int, ui.Image> cache = {};

  static Future<ui.Image?> get(int world) async {
    final hit = cache[world];
    if (hit != null) return hit;
    try {
      final bd = await rootBundle.load('assets/backgrounds/world$world.jpg');
      final codec = await ui.instantiateImageCodec(bd.buffer.asUint8List());
      final img = (await codec.getNextFrame()).image;
      cache[world] = img;
      return img;
    } catch (_) {
      return null;
    }
  }

  static Future<void> preload() async {
    for (int w = 1; w <= 11; w++) {
      await get(w);
    }
  }
}

/// المجسمات المحوّلة لصور (تُحمَّل مرة واحدة)
class Sprites {
  static Future<Map<String, ui.Image>> load() async {
    final sp = <String, ui.Image>{};
    Future<void> one(String key, String file) async {
      final bd = await rootBundle.load('assets/sprites/$file.png');
      final codec = await ui.instantiateImageCodec(bd.buffer.asUint8List());
      sp[key] = (await codec.getNextFrame()).image;
    }

    const names = [
      'mush', 'quartz', 'corner', 'vault', 'bars', 'skull', 'chest', 'lantern',
      'pillar', 'skeleton_a', 'skeleton_b', 'spider', 'statue', 'torch'
    ];
    for (final n in names) {
      await one(n, n);
      await one('${n}_d', '${n}_d');
    }
    for (final n in Nature.sprites) {
      await one(n, n);
      await one('${n}_d', '${n}_d');
    }
    for (final n in const ['hero_body', 'hero_armN', 'hero_armF', 'hero_legN', 'hero_legF', 'hero_weapon']) {
      await one(n, n);
    }
    return sp;
  }
}

/// خلفيات مرحلة واحدة (تُبنى عند دخول المرحلة وتُحرَّر عند الخروج)
class Art {
  final Map<String, ui.Image> sp;
  final LevelConfig cfg;
  final WorldTheme th;
  late Strip sky, mt1, mt2, wall;
  ui.Image? bg; // خلفية العالم (مشتركة، لا تُحرَّر هنا)
  late ui.Image fog1, fog2, gt, wood;
  late Paint gtPaint, woodPaint;
  final List<Arch> arches = [];
  final List<Prop> props = [];
  static const double ps = 2;

  Art(this.sp, this.cfg) : th = cfg.theme;

  double lw(double f) => (cfg.length * f).ceilToDouble() + kMaxView + 4;

  static Future<Art> build(Map<String, ui.Image> sp, LevelConfig cfg) async {
    final a = Art(sp, cfg);
    await a._build();
    if (cfg.classic) {
      a._classicProps();
    } else {
      a._genProps();
    }
    return a;
  }

  void dispose() {
    sky.dispose();
    mt1.dispose();
    mt2.dispose();
    wall.dispose();
    fog1.dispose();
    fog2.dispose();
    gt.dispose();
    wood.dispose();
  }

  ui.Picture _rec(void Function(Canvas) f) {
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    f(c);
    return r.endRecording();
  }

  Future<Strip> _strip(double w, double h, void Function(Canvas) f) async {
    final pic = _rec(f);
    final tiles = <ui.Image>[];
    final n = (w / Strip.tw).ceil();
    for (int i = 0; i < n; i++) {
      final x0 = i * Strip.tw;
      final tww = math.min(Strip.tw, w - x0);
      final r = ui.PictureRecorder();
      final c = Canvas(r);
      c.scale(Strip.ps, Strip.ps);
      c.translate(Strip.pad - x0, 0);
      c.drawPicture(pic);
      final p2 = r.endRecording();
      tiles.add(await p2.toImage(((tww + 2 * Strip.pad) * Strip.ps).ceil(), (h * Strip.ps).ceil()));
      p2.dispose();
    }
    pic.dispose();
    return Strip(tiles, w, h);
  }

  Future<ui.Image> _img(double w, double h, void Function(Canvas) f) async {
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    c.scale(ps, ps);
    f(c);
    final pic = r.endRecording();
    final img = await pic.toImage((w * ps).ceil(), (h * ps).ceil());
    pic.dispose();
    return img;
  }

  Paint _tilePaint(ui.Image img) => Paint()
    ..shader = ui.ImageShader(img, TileMode.repeated, TileMode.repeated,
        Float64List.fromList([1 / ps, 0, 0, 0, 0, 1 / ps, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
        filterQuality: FilterQuality.low);

  Future<void> _build() async {
    bg = await Backdrops.get(cfg.world);
    sky = await _strip(lw(.02), kH, _drawSky);
    mt1 = await _strip(lw(.08), kH, (c) => _mount(c, lw(.08), 330, 95, th.mt1, 23, th.towers1));
    mt2 = await _strip(lw(.18), kH, (c) => _mount(c, lw(.18), 385, 70, th.mt2, 41, 0));
    fog1 = await _img(kW, 140, (c) => _fog(c, 140, 3, 7, .16));
    fog2 = await _img(kW, 110, (c) => _fog(c, 110, 9, 6, .12));
    gt = await _img(96, 60, _drawGT);
    gtPaint = _tilePaint(gt);
    wood = await _img(64, 14, _drawWood);
    woodPaint = _tilePaint(wood);
    wall = await _strip(lw(.8), 270, th.wall == WallStyle.trunks ? _drawTrunks : _drawWall);
  }

  // ---------------- السماء
  void _drawSky(Canvas g) {
    final w = lw(.02);
    final r = mkr(5);
    g.drawRect(Rect.fromLTWH(0, 0, w, kH),
        Paint()..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, kH), th.sky, const [0, .45, .75, 1]));
    for (int i = 0; i < 7; i++) {
      final x = r() * w, y = 40 + r() * 220, rr = 70 + r() * 90;
      glow(g, x, y, rr, i.isEven ? th.blobA : th.blobB, .09);
    }
    for (int i = 0; i < 130; i++) {
      final a = .25 + r() * .7;
      final big = r() < .12;
      g.drawRect(Rect.fromLTWH((r() * w).floorToDouble(), (r() * kH * .62).floorToDouble(), big ? 2 : 1, big ? 2 : 1),
          Paint()..color = Color.fromRGBO(200, 225, 255, a));
    }
    const mx = 262.0, my = 118.0;
    glow(g, mx, my, 150, th.moonGlow, .42);
    glow(g, mx, my, 60, th.moonGlow, .35);
    g.drawCircle(const Offset(mx, my), 22,
        Paint()..shader = ui.Gradient.radial(const Offset(mx - 6, my - 6), 28, [th.moonA, th.moonB]));
    final cr = Paint()..color = const Color.fromRGBO(120, 150, 200, .35);
    for (final a in const [[-7, -5, 5], [6, 4, 4], [-2, 9, 3], [9, -8, 3]]) {
      g.drawCircle(Offset(mx + a[0], my + a[1]), a[2].toDouble(), cr);
    }
  }

  void _mount(Canvas g, double w, double base, double amp, List<Color> col, int seed, int tw) {
    final c0 = col[0], c1 = col[1], rim = col[2];
    final r = mkr(seed);
    final ph = [r() * 6, r() * 6, r() * 6];
    double top(double i) =>
        base -
        (math.sin(i / 90 + ph[0]) * .5 + math.sin(i / 37 + ph[1]) * .3 + math.sin(i / 13 + ph[2]) * .2 + (math.sin(i / 160 + ph[0] * 2)).abs() * .4) * amp;
    final path = Path()..moveTo(0, kH);
    for (double i = 0; i <= w; i += 2) {
      path.lineTo(i, top(i));
    }
    path.lineTo(w, kH);
    path.close();
    g.drawPath(path, Paint()..shader = ui.Gradient.linear(Offset(0, base - amp * 1.4), const Offset(0, kH), [c0, c1]));
    final fp = Paint()..color = c0;
    final win = Paint()..color = const Color.fromRGBO(255, 205, 120, .8);
    for (int i = 0; i < tw; i++) {
      final tx = (60 + r() * (w - 120)).floorToDouble();
      final th2 = 22 + r() * 34, tww = 8 + r() * 8;
      final ty = top(tx) + 4;
      g.drawRect(Rect.fromLTWH(tx, ty - th2, tww, th2 + 6), fp);
      g.drawRect(Rect.fromLTWH(tx - 2, ty - th2 - 3, tww + 4, 3), fp);
      g.drawRect(Rect.fromLTWH(tx + 1, ty - th2 - 7, 2, 4), fp);
      g.drawRect(Rect.fromLTWH(tx + tww - 3, ty - th2 - 7, 2, 4), fp);
      g.drawRect(Rect.fromLTWH(tx + (tww / 2).floorToDouble() - 1, ty - th2 + 8, 2, 3), win);
      if (r() < .5) g.drawRect(Rect.fromLTWH(tx + 2, ty - th2 + 18, 2, 3), win);
    }
    final rp = Path();
    for (double i = 0; i <= w; i += 2) {
      i == 0 ? rp.moveTo(i, top(i)) : rp.lineTo(i, top(i));
    }
    g.drawPath(rp, Paint()..color = rim..style = PaintingStyle.stroke..strokeWidth = 1.4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
  }

  void _fog(Canvas g, double h, int seed, int n, double a) {
    final r = mkr(seed);
    for (int i = 0; i < n; i++) {
      final bx = r() * kW, by = h * (.3 + r() * .5), rr = 40 + r() * 70;
      for (final o in const [-kW, 0.0, kW]) {
        glow(g, bx + o, by, rr, th.fog, a);
      }
    }
  }

  // ---------------- الأرضية
  void _drawGT(Canvas g) {
    final r = mkr(77);
    g.drawRect(const Rect.fromLTWH(0, 0, 96, 60), Paint()..color = th.soil ? const Color(0xFF0C0906) : const Color(0xFF070C18));
    if (th.soil) {
      for (int i = 0; i < 46; i++) {
        final x = r() * 96, y = r() * 60, w = 4 + r() * 12, h2 = 2 + r() * 6;
        g.drawOval(Rect.fromLTWH(x, y, w, h2), Paint()..color = hslc(th.gtHue + r() * 14, th.gtSat, (7 + r() * 8) / 100));
      }
      final rp = Paint()..color = const Color.fromRGBO(70, 48, 28, .55)..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeCap = StrokeCap.round;
      for (int i = 0; i < 5; i++) {
        final p = Path()..moveTo(r() * 96, r() * 8);
        double x = 0, y = 0;
        for (int k = 0; k < 4; k++) {
          x += (r() - .5) * 18;
          y += 8 + r() * 10;
          p.relativeLineTo((r() - .5) * 18, 8 + r() * 10);
        }
        g.drawPath(p, rp);
      }
      for (int i = 0; i < 10; i++) {
        g.drawCircle(Offset(r() * 96, r() * 60), 1 + r() * 1.5, Paint()..color = Color.fromRGBO(120, 220, 140, .08 + r() * .1));
      }
    } else {
      for (int row = 0; row < 4; row++) {
        final y = 4.0 + row * 14, off = (row % 2) * 16.0;
        for (double bx = -off; bx < 96; bx += 32) {
          final l = 9 + r() * 7;
          g.drawRect(Rect.fromLTWH(bx + 1, y, 30, 13), Paint()..color = hslc(th.gtHue, th.gtSat, l / 100));
          g.drawRect(Rect.fromLTWH(bx + 1, y, 30, 1), Paint()..color = const Color.fromRGBO(140, 185, 255, .12));
          g.drawRect(Rect.fromLTWH(bx + 1, y + 12, 30, 1), Paint()..color = const Color.fromRGBO(0, 0, 0, .3));
          for (int k = 0; k < 3; k++) {
            g.drawRect(Rect.fromLTWH(bx + 2 + r() * 26, y + 2 + r() * 9, 2, 1), Paint()..color = Color.fromRGBO(180, 210, 255, .04 + r() * .08));
          }
        }
      }
    }
    g.drawRect(const Rect.fromLTWH(0, 0, 96, 60),
        Paint()..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, 60), const [Color(0x00000000), Color(0x8C000000)]));
  }

  void _drawWood(Canvas g) {
    final r = mkr(33);
    g.drawRect(const Rect.fromLTWH(0, 0, 64, 14), Paint()..color = const Color(0xFF2A1A0E));
    for (int i = 0; i < 4; i++) {
      final x = i * 16.0;
      g.drawRect(Rect.fromLTWH(x + .5, 0, 15, 14), Paint()..color = hslc(26 + r() * 8, .45, (14 + r() * 7) / 100));
      g.drawRect(Rect.fromLTWH(x + .5, 0, 15, 1.5), Paint()..color = const Color.fromRGBO(255, 210, 150, .16));
      for (int k = 0; k < 3; k++) {
        final y = 2 + r() * 10;
        g.drawLine(Offset(x + 1, y), Offset(x + 14, y + (r() - .5) * 2), Paint()..color = const Color.fromRGBO(0, 0, 0, .28)..strokeWidth = .7);
      }
      g.drawCircle(Offset(x + 3, 7), 1, Paint()..color = const Color.fromRGBO(0, 0, 0, .5));
      g.drawCircle(Offset(x + 13, 7), 1, Paint()..color = const Color.fromRGBO(0, 0, 0, .5));
    }
    g.drawRect(const Rect.fromLTWH(0, 10, 64, 4), Paint()..color = const Color.fromRGBO(0, 0, 0, .3));
  }

  // ---------------- جدار الطوب (الكهف)
  void _drawWall(Canvas g) {
    final w = lw(.8);
    const h = 270.0;
    final r = mkr(91);
    final segs = <List<double>>[];
    if (cfg.classic) {
      segs.addAll([[30, 440], [560, 1010], [1130, 1560], [1690, 2090], [2170, 2320]]);
    } else {
      final rr = mkr(cfg.seed * 31 + 7);
      double pos = 30;
      while (pos < w - 500) {
        final l = 350 + rr() * 450;
        segs.add([pos, math.min(pos + l, w - 100)]);
        pos += l + 60 + rr() * 90;
      }
    }
    final edge = List<double>.filled(w.ceil() + 2, 1e9);
    for (final s in segs) {
      double e = 70 + r() * 60;
      for (int i = s[0].toInt(); i < s[1].toInt(); i++) {
        if (i % 16 == 0) e = math.max(42.0, math.min(150.0, e + (r() - .5) * 50));
        double ee = e;
        final a = i - s[0], b = s[1] - i;
        if (a < 40) ee += (40 - a) * 2.2;
        if (b < 40) ee += (40 - b) * 2.2;
        edge[i] = (ee / 14).round() * 14.0;
      }
    }
    final base = Paint()..color = th.wallBase;
    for (final s in segs) {
      for (int i = s[0].toInt(); i < s[1].toInt(); i++) {
        g.drawRect(Rect.fromLTWH(i.toDouble(), edge[i], 1.05, h - edge[i]), base);
      }
    }
    for (int row = 0; row * 14 < h; row++) {
      final y = row * 14.0, off = (row % 2) * 14.0;
      for (double bx = -off; bx < w; bx += 28) {
        final cx = bx + 14;
        if (cx < 0 || cx >= w || edge[cx.floor()] > y) continue;
        final l = 10 + r() * 9;
        final teal = r() < .06;
        g.drawRect(Rect.fromLTWH(bx + 1, y + 1, 26, 12), Paint()..color = teal ? hslc(185, .35, l / 100) : hslc(th.wallHue, th.wallSat, l / 100));
        g.drawRect(Rect.fromLTWH(bx + 1, y + 1, 26, 1), Paint()..color = const Color.fromRGBO(150, 190, 255, .10));
        g.drawRect(Rect.fromLTWH(bx + 1, y + 12, 26, 1), Paint()..color = const Color.fromRGBO(0, 0, 0, .25));
        if (r() < .07) {
          g.drawRect(Rect.fromLTWH(bx + 1 + r() * 10, y + 2, 8, 9), Paint()..color = const Color.fromRGBO(0, 0, 0, .45));
        }
      }
    }
    final rune = Paint()..color = th.rune.a(.85);
    final runeGlow = Paint()
      ..color = th.rune.a(.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final s in segs) {
      final n = ((s[1] - s[0]) / 22).floor();
      for (int k = 0; k < n; k++) {
        final mx = s[0] + 8 + r() * (s[1] - s[0] - 16);
        final my = edge[mx.floor()];
        g.drawOval(Rect.fromCenter(center: Offset(mx, my + 2), width: 20, height: 8), Paint()..color = const Color.fromRGBO(40, 150, 120, .35));
        if (r() < .6) {
          final len = 20 + r() * 50;
          g.drawLine(Offset(mx, my + 4), Offset(mx + (r() - .5) * 4, my + 4 + len),
              Paint()..color = const Color.fromRGBO(30, 120, 100, .5)..strokeWidth = 1);
        }
      }
      for (int k = 0; k < (n * .7).floor(); k++) {
        double cx = s[0] + 8 + r() * (s[1] - s[0] - 16);
        double cy = edge[cx.floor()] + 10 + r() * 120;
        final cp = Path()..moveTo(cx, cy);
        for (int j = 0; j < 4; j++) {
          cx += (r() - .5) * 10;
          cy += 4 + r() * 8;
          cp.lineTo(cx, cy);
        }
        g.drawPath(cp, Paint()..color = const Color.fromRGBO(0, 0, 0, .55)..style = PaintingStyle.stroke..strokeWidth = 1);
      }
      for (int k = 0; k < 3; k++) {
        final rx = (s[0] + 20 + r() * (s[1] - s[0] - 40)).floorToDouble();
        final ry = (edge[rx.floor()] + 30 + r() * 100).floorToDouble();
        final ty = (r() * 3).floor();
        final rp = Path();
        if (ty == 0) {
          rp.addRect(Rect.fromLTWH(rx, ry, 2, 8));
          rp.addRect(Rect.fromLTWH(rx, ry + 6, 6, 2));
        } else if (ty == 1) {
          rp.addRect(Rect.fromLTWH(rx, ry + 3, 8, 2));
          rp.addRect(Rect.fromLTWH(rx + 3, ry, 2, 8));
        } else {
          rp.addRect(Rect.fromLTWH(rx, ry, 6, 2));
          rp.addRect(Rect.fromLTWH(rx, ry + 6, 6, 2));
          rp.addRect(Rect.fromLTWH(rx + 2, ry, 2, 8));
        }
        g.drawPath(rp, runeGlow);
        g.drawPath(rp, rune);
      }
    }
    const baseY = 250.0;
    Path archPath(double ax, double hw, double ah) {
      return Path()
        ..moveTo(ax - hw, baseY)
        ..lineTo(ax - hw, baseY - ah)
        ..arcTo(Rect.fromCircle(center: Offset(ax, baseY - ah), radius: hw), math.pi, math.pi, false)
        ..lineTo(ax + hw, baseY)
        ..close();
    }
    arches.clear();
    for (final s in segs) {
      final len = s[1] - s[0];
      if (len > 300) {
        final n = len > 400 ? 2 : 1;
        for (int k = 0; k < n; k++) {
          final ax = s[0] + 80 + (k + r() * .6) * ((len - 160) / n);
          if (edge[ax.floor()] < baseY - 110) {
            arches.add(Arch(ax, r() < .5 ? 23 : 17, r() < .5 ? 70 : 90));
          }
        }
      }
    }
    final cut = Paint()..blendMode = BlendMode.dstOut..color = const Color(0xFF000000);
    for (final a in arches) {
      g.drawPath(archPath(a.x, a.hw, a.ah), cut);
    }
    final stroke = Paint()..color = th.archStroke..style = PaintingStyle.stroke..strokeWidth = 3;
    for (final a in arches) {
      g.drawPath(archPath(a.x, a.hw + 1, a.ah), stroke);
    }
    _wallTint(g, w, h);
  }

  void _wallTint(Canvas g, double w, double h) {
    g.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, h), [th.tintTop, th.tintBottom]));
    g.drawRect(Rect.fromLTWH(0, h - 60, w, 60),
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = ui.Gradient.linear(Offset(0, h - 60), Offset(0, h), const [Color(0x00000000), Color(0x99000000)]));
  }

  // ---------------- جدار الغابة: جذوع أشجار ضخمة
  void _drawTrunks(Canvas g) {
    final w = lw(.8);
    const h = 270.0;
    final r = mkr(cfg.seed * 13 + 5);
    g.drawRect(Rect.fromLTWH(0, 40, w, h - 40), Paint()..color = th.wallBase);
    // أشجار خلفية خافتة
    for (double x = 10; x < w; x += 70 + r() * 80) {
      final tw = 16 + r() * 18;
      g.drawRect(Rect.fromLTWH(x, 0, tw, h), Paint()..color = Color.fromRGBO(10, 26, 16, .9));
    }
    // الجذوع الكبيرة
    final trunkXs = <double>[];
    for (double x = 40; x < w - 60; x += 110 + r() * 150) {
      final tw = 34 + r() * 40;
      trunkXs.add(x);
      final body = Path()
        ..moveTo(x, 0)
        ..lineTo(x + tw, 0)
        ..cubicTo(x + tw + 4, h * .5, x + tw - 3, h * .8, x + tw + 14, h)
        ..lineTo(x - 14, h)
        ..cubicTo(x + 3, h * .8, x - 4, h * .5, x, 0)
        ..close();
      g.drawPath(
          body,
          Paint()
            ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x + tw, 0), const [Color(0xFF0A130C), Color(0xFF1E2C1A), Color(0xFF0A120B)], const [0, .35, 1]));
      for (int k = 0; k < 10; k++) {
        final bx = x + 3 + r() * (tw - 6);
        g.drawLine(Offset(bx, r() * 30), Offset(bx + (r() - .5) * 6, h * (.4 + r() * .6)),
            Paint()..color = Color.fromRGBO(0, 0, 0, .35)..strokeWidth = 1 + r());
      }
      for (int k = 0; k < 3; k++) {
        g.drawOval(Rect.fromCenter(center: Offset(x + tw * (.3 + r() * .4), 40 + r() * 170), width: 8 + r() * 6, height: 14 + r() * 10),
            Paint()..color = const Color.fromRGBO(0, 0, 0, .5));
      }
      // طحلب مضيء وفطر صغير
      for (int k = 0; k < 4; k++) {
        final fx = x + r() * tw, fy = 60 + r() * 180;
        glow(g, fx, fy, 7, th.rune, .5);
        g.drawCircle(Offset(fx, fy), 1.4, Paint()..color = th.rune.a(.95));
      }
      // جذور في الأسفل
      final rp = Paint()..color = const Color(0xFF0C140C)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
      for (final sg in const [-1.0, 1.0]) {
        g.drawPath(
            Path()
              ..moveTo(x + tw / 2, h - 40)
              ..quadraticBezierTo(x + tw / 2 + sg * 24, h - 14, x + tw / 2 + sg * (40 + r() * 20), h),
            rp);
      }
    }
    // تاج الأشجار (أوراق)
    for (double x = -20; x < w + 20; x += 26 + r() * 20) {
      final rr = 30 + r() * 38;
      final y = 10 + r() * 50;
      g.drawCircle(Offset(x, y), rr, Paint()..color = Color.fromRGBO(6 + (r() * 8).floor(), 24 + (r() * 22).floor(), 14 + (r() * 10).floor(), .96));
    }
    // الكروم المتدلية
    for (int i = 0; i < (w / 90).floor(); i++) {
      final x = r() * w, len = 60 + r() * 120;
      final p = Path()..moveTo(x, 40);
      p.quadraticBezierTo(x + (r() - .5) * 20, 40 + len / 2, x + (r() - .5) * 14, 40 + len);
      g.drawPath(p, Paint()..color = const Color(0xFF0E2A14)..style = PaintingStyle.stroke..strokeWidth = 1.4);
      for (int k = 0; k < 5; k++) {
        g.drawCircle(Offset(x + (r() - .5) * 8, 50 + r() * len), 1.6, Paint()..color = const Color.fromRGBO(30, 90, 40, .9));
      }
    }
    // أشعة ضوء من بين الأوراق
    arches.clear();
    for (double x = 160; x < w - 160; x += 240 + r() * 220) {
      arches.add(Arch(x, 14 + r() * 8, 250));
    }
    _wallTint(g, w, h);
  }

  // ---------------- الديكور
  void _classicProps() {
    final r = mkr(7);
    void add(String k, double x, double h, {int layer = 0, bool dark = false, C3? g}) => props.add(Prop(k, x, h, layer, dark, g));
    double wOf(String k, double h) => h * sp[k]!.width / sp[k]!.height;
    for (final x in const [250.0, 820.0, 1280.0, 1790.0, 2230.0]) {
      add('pillar', x, 220, dark: true);
    }
    for (final x in const [650.0, 1180.0, 2100.0]) {
      add('statue', x, 125, dark: true);
    }
    void row(String k, double x0, int n, double h) {
      final w = wOf(k, h);
      for (int i = 0; i < n; i++) {
        add(k, x0 + i * w * .98, h, dark: true);
      }
    }
    row('bars', 160, 4, 90);
    row('bars', 1110, 3, 90);
    row('bars', 1840, 3, 90);
    add('corner', 1000, 150, dark: true);
    add('vault', 2385, 170, dark: true);
    for (final s in cfg.grounds) {
      final q = (s.w / 170).floor();
      for (int i = 0; i < q; i++) {
        add('quartz', s.x + 40 + r() * (s.w - 80), 32 + r() * 30, g: const C3(120, 230, 255));
      }
    }
    for (final s in cfg.grounds) {
      final n = (s.w / 110).floor();
      for (int i = 0; i < n; i++) {
        add('mush', s.x + 30 + r() * (s.w - 60), 12 + r() * 22, layer: 1, g: const C3(255, 130, 90));
      }
    }
    for (final x in const [90.0, 610.0, 1090.0, 1670.0, 2250.0]) {
      add('torch', x, 72, layer: 1, g: const C3(255, 170, 70));
    }
    for (final x in const [380.0, 930.0, 1460.0, 2000.0]) {
      add('lantern', x, 44, layer: 1, g: const C3(255, 190, 90));
    }
    for (final x in const [440.0, 900.0, 1480.0, 1980.0, 2300.0]) {
      add('spider', x, 70, layer: 1, g: const C3(255, 80, 90));
    }
    add('skeleton_a', 1510, 64, layer: 1);
    add('skeleton_b', 2020, 56, layer: 1);
    for (final x in const [140.0, 1190.0]) {
      add('chest', x, 17, layer: 1);
    }
    for (final x in const [300.0, 760.0, 1310.0, 1900.0, 2280.0]) {
      add('skull', x, 13, layer: 1);
    }
  }

  /// ديكور المراحل المولَّدة: حسب الثيم وبذرة المرحلة
  void _genProps() {
    final r = mkr(cfg.seed * 977 + 3);
    final forest = th.wall == WallStyle.trunks;
    void add(String k, double x, double h, {int layer = 0, bool dark = false, C3? g}) => props.add(Prop(k, x, h, layer, dark, g));
    for (final s in cfg.grounds) {
      final w = s.w;
      if (w < 120) continue;
      double px(double m) => s.x + m + r() * (w - 2 * m);
      if (!forest) {
        final nf = (w / 380).floor();
        for (int i = 0; i < nf; i++) {
          if (r() < .6) {
            add('pillar', px(60), 200 + r() * 40, dark: true);
          } else {
            add('statue', px(80), 110 + r() * 30, dark: true);
          }
        }
        if (r() < .35) add('bars', px(80), 90, dark: true);
        final q = (w / 200).floor();
        for (int i = 0; i < q; i++) {
          add('quartz', px(40), 30 + r() * 28, g: const C3(120, 230, 255));
        }
      } else {
        final q = (w / 220).floor();
        for (int i = 0; i < q; i++) {
          add('quartz', px(40), 26 + r() * 24, g: const C3(120, 255, 170));
        }
        if (r() < .4) add('statue', px(90), 105, dark: true);
      }
      final m = (w / (forest ? 90 : 120)).floor();
      for (int i = 0; i < m; i++) {
        add('mush', px(30), 12 + r() * (forest ? 30 : 22), layer: 1, g: forest ? const C3(150, 255, 150) : const C3(255, 130, 90));
      }
      if (w > 220) add('torch', px(40), 72, layer: 1, g: const C3(255, 170, 70));
      if (w > 260 && r() < .6) add('lantern', px(40), 44, layer: 1, g: const C3(255, 190, 90));
      if (r() < .5) add('spider', px(40), 70, layer: 1, g: forest ? const C3(255, 90, 160) : const C3(255, 80, 90));
      if (r() < .4) add('skull', px(30), 13, layer: 1);
      if (w > 360 && r() < .25) add(r() < .5 ? 'skeleton_a' : 'skeleton_b', px(60), 58, layer: 1);
    }
    _natureProps();
  }

  /// يوزّع مجسمات الطبيعة على الأرضيات حسب العالم (RNG مستقل)
  void _natureProps() {
    final rn = mkr(cfg.seed * 1313 + 17);
    final specs = Nature.forWorld(th.key);
    for (final s in cfg.grounds) {
      final w = s.w;
      if (w < 120) continue;
      for (final sp in specs) {
        final n = (w / sp.every).floor();
        for (int i = 0; i < n; i++) {
          final m = sp.layer == 0 ? 70.0 : 30.0;
          final x = s.x + m + rn() * math.max(1.0, w - 2 * m);
          final h = sp.h0 + rn() * (sp.h1 - sp.h0);
          final dark = sp.dk > 0 && rn() < sp.dk;
          props.add(Prop(sp.k, x, h, sp.layer, dark, sp.glow));
        }
      }
    }
  }
}
