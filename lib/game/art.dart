import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'level.dart';

class C3 {
  final int r, g, b;
  const C3(this.r, this.g, this.b);
  Color a(double al) => Color.fromRGBO(r, g, b, al);
}

double Function() mkr(int seed) {
  int s = seed;
  return () {
    s = (s * 16807) % 2147483647;
    return s / 2147483647;
  };
}

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
}

class Art {
  late Strip sky, mt1, mt2, wall;
  late ui.Image fog1, fog2, gt;
  late Paint gtPaint;
  final Map<String, ui.Image> sp = {};
  final List<Arch> arches = [];
  final List<Prop> props = [];
  static const double ps = 2;

  static double lw(double f) => (kLW * f).ceilToDouble() + kMaxView + 4;

  static Future<Art> load() async {
    final a = Art();
    const names = [
      'mush', 'quartz', 'corner', 'vault', 'bars', 'skull', 'chest', 'lantern',
      'pillar', 'skeleton_a', 'skeleton_b', 'spider', 'statue', 'torch'
    ];
    for (final n in names) {
      for (final suf in ['', '_d']) {
        final bd = await rootBundle.load('assets/sprites/$n$suf.png');
        final codec = await ui.instantiateImageCodec(bd.buffer.asUint8List());
        final fr = await codec.getNextFrame();
        a.sp['$n$suf'] = fr.image;
      }
    }
    for (final n in const ['hero_body', 'hero_armN', 'hero_armF', 'hero_legN', 'hero_legF', 'hero_weapon']) {
      final bd = await rootBundle.load('assets/sprites/$n.png');
      final codec = await ui.instantiateImageCodec(bd.buffer.asUint8List());
      a.sp[n] = (await codec.getNextFrame()).image;
    }
    await a._build();
    a._buildProps();
    return a;
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
    }
    return Strip(tiles, w, h);
  }

  Future<ui.Image> _img(double w, double h, void Function(Canvas) f) async {
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    c.scale(ps, ps);
    f(c);
    return r.endRecording().toImage((w * ps).ceil(), (h * ps).ceil());
  }

  Future<void> _build() async {
    sky = await _strip(lw(.02), kH, _drawSky);
    mt1 = await _strip(lw(.08), kH, (c) => _mount(c, lw(.08), 330, 95, const Color(0xFF102650), const Color(0xFF0A1630), const Color(0x5278AAFF), 23, 4));
    mt2 = await _strip(lw(.18), kH, (c) => _mount(c, lw(.18), 385, 70, const Color(0xFF0C1B38), const Color(0xFF08122A), const Color(0x405A8CE6), 41, 0));
    fog1 = await _img(kW, 140, (c) => _fog(c, 140, 3, 7, .16));
    fog2 = await _img(kW, 110, (c) => _fog(c, 110, 9, 6, .12));
    gt = await _img(96, 60, _drawGT);
    gtPaint = Paint()
      ..shader = ui.ImageShader(gt, TileMode.repeated, TileMode.repeated,
          Float64List.fromList([1 / ps, 0, 0, 0, 0, 1 / ps, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
          filterQuality: FilterQuality.low);
    wall = await _strip(lw(.8), 270, _drawWall);
  }

  void _drawSky(Canvas g) {
    final w = lw(.02);
    final r = mkr(5);
    g.drawRect(
        Rect.fromLTWH(0, 0, w, kH),
        Paint()
          ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, kH),
              const [Color(0xFF03050B), Color(0xFF0A1630), Color(0xFF12335A), Color(0xFF1B4A6E)], const [0, .45, .75, 1]));
    // سديم ناعم
    for (int i = 0; i < 7; i++) {
      final x = r() * w, y = 40 + r() * 220, rr = 70 + r() * 90;
      glow(g, x, y, rr, i.isEven ? const C3(90, 70, 170) : const C3(40, 160, 175), .09);
    }
    for (int i = 0; i < 130; i++) {
      final a = .25 + r() * .7;
      final big = r() < .12;
      g.drawRect(Rect.fromLTWH((r() * w).floorToDouble(), (r() * kH * .62).floorToDouble(), big ? 2 : 1, big ? 2 : 1),
          Paint()..color = Color.fromRGBO(200, 225, 255, a));
    }
    const mx = 262.0, my = 118.0;
    glow(g, mx, my, 150, const C3(170, 200, 255), .42);
    glow(g, mx, my, 60, const C3(210, 225, 255), .35);
    g.drawCircle(const Offset(mx, my), 22,
        Paint()..shader = ui.Gradient.radial(const Offset(mx - 6, my - 6), 28, const [Color(0xFFF6FAFF), Color(0xFFC3D4F6)]));
    final cr = Paint()..color = const Color.fromRGBO(120, 150, 200, .35);
    for (final a in const [[-7, -5, 5], [6, 4, 4], [-2, 9, 3], [9, -8, 3]]) {
      g.drawCircle(Offset(mx + a[0], my + a[1]), a[2].toDouble(), cr);
    }
  }

  void _mount(Canvas g, double w, double base, double amp, Color c0, Color c1, Color rim, int seed, int tw) {
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
      final th = 22 + r() * 34, tww = 8 + r() * 8;
      final ty = top(tx) + 4;
      g.drawRect(Rect.fromLTWH(tx, ty - th, tww, th + 6), fp);
      g.drawRect(Rect.fromLTWH(tx - 2, ty - th - 3, tww + 4, 3), fp);
      g.drawRect(Rect.fromLTWH(tx + 1, ty - th - 7, 2, 4), fp);
      g.drawRect(Rect.fromLTWH(tx + tww - 3, ty - th - 7, 2, 4), fp);
      g.drawRect(Rect.fromLTWH(tx + (tww / 2).floorToDouble() - 1, ty - th + 8, 2, 3), win);
      if (r() < .5) g.drawRect(Rect.fromLTWH(tx + 2, ty - th + 18, 2, 3), win);
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
        glow(g, bx + o, by, rr, const C3(120, 170, 230), a);
      }
    }
  }

  void _drawGT(Canvas g) {
    final r = mkr(77);
    g.drawRect(const Rect.fromLTWH(0, 0, 96, 60), Paint()..color = const Color(0xFF070C18));
    for (int row = 0; row < 4; row++) {
      final y = 4.0 + row * 14, off = (row % 2) * 16.0;
      for (double bx = -off; bx < 96; bx += 32) {
        final l = 9 + r() * 7;
        g.drawRect(Rect.fromLTWH(bx + 1, y, 30, 13), Paint()..color = hslc(220, .4, l / 100));
        g.drawRect(Rect.fromLTWH(bx + 1, y, 30, 1), Paint()..color = const Color.fromRGBO(140, 185, 255, .12));
        g.drawRect(Rect.fromLTWH(bx + 1, y + 12, 30, 1), Paint()..color = const Color.fromRGBO(0, 0, 0, .3));
        for (int k = 0; k < 3; k++) {
          g.drawRect(Rect.fromLTWH(bx + 2 + r() * 26, y + 2 + r() * 9, 2, 1), Paint()..color = Color.fromRGBO(180, 210, 255, .04 + r() * .08));
        }
      }
    }
    g.drawRect(const Rect.fromLTWH(0, 0, 96, 60),
        Paint()..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, 60), const [Color(0x00000000), Color(0x8C000000)]));
  }

  void _drawWall(Canvas g) {
    final w = lw(.8);
    const h = 270.0;
    final r = mkr(91);
    final segs = <List<double>>[[30, 440], [560, 1010], [1130, 1560], [1690, 2090], [2170, 2320]];
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
    final base = Paint()..color = const Color(0xFF050A14);
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
        g.drawRect(Rect.fromLTWH(bx + 1, y + 1, 26, 12), Paint()..color = teal ? hslc(185, .35, l / 100) : hslc(218, .38, l / 100));
        g.drawRect(Rect.fromLTWH(bx + 1, y + 1, 26, 1), Paint()..color = const Color.fromRGBO(150, 190, 255, .10));
        g.drawRect(Rect.fromLTWH(bx + 1, y + 12, 26, 1), Paint()..color = const Color.fromRGBO(0, 0, 0, .25));
        if (r() < .07) {
          g.drawRect(Rect.fromLTWH(bx + 1 + r() * 10, y + 2, 8, 9), Paint()..color = const Color.fromRGBO(0, 0, 0, .45));
        }
      }
    }
    final rune = Paint()..color = const Color.fromRGBO(130, 220, 255, .85);
    final runeGlow = Paint()
      ..color = const Color.fromRGBO(111, 211, 255, .6)
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
    // أقواس تُقطع من الجدار لتظهر السماء
    const baseY = 250.0;
    Path archPath(double ax, double hw, double ah) {
      final p = Path()
        ..moveTo(ax - hw, baseY)
        ..lineTo(ax - hw, baseY - ah)
        ..arcTo(Rect.fromCircle(center: Offset(ax, baseY - ah), radius: hw), math.pi, math.pi, false)
        ..lineTo(ax + hw, baseY)
        ..close();
      return p;
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
    final stroke = Paint()..color = const Color(0xFF27487A)..style = PaintingStyle.stroke..strokeWidth = 3;
    for (final a in arches) {
      g.drawPath(archPath(a.x, a.hw + 1, a.ah), stroke);
    }
    g.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, h), const [Color(0x383C6EBE), Color(0x80000410)]));
    g.drawRect(
        Rect.fromLTWH(0, h - 60, w, 60),
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = ui.Gradient.linear(Offset(0, h - 60), Offset(0, h), const [Color(0x00000000), Color(0x99000000)]));
  }

  void _buildProps() {
    final r = mkr(7);
    void add(String k, double x, double h, {int layer = 0, bool dark = false, C3? g}) => props.add(Prop(k, x, h, layer, dark, g));
    double wOf(String k, double h) => h * sp[k]!.width / sp[k]!.height;
    // بعيدة (خلف المنصات)
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
    for (final s in Level.grounds) {
      final q = (s.w / 170).floor();
      for (int i = 0; i < q; i++) {
        add('quartz', s.x + 40 + r() * (s.w - 80), 32 + r() * 30, g: const C3(120, 230, 255));
      }
    }
    // أمامية
    for (final s in Level.grounds) {
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
}
