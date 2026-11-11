import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'art.dart';
import 'engine.dart';
import 'level.dart';

class GamePainter extends CustomPainter {
  final GameEngine e;
  final Art a;
  GamePainter(this.e, this.a) : super(repaint: e.frame) {
    final lr = [mkr(11), mkr(16), mkr(21)];
    for (int l = 0; l < 3; l++) {
      for (int i = 0; i < 60; i++) {
        _layers[l].add([i * (60.0 + l * 20), 30 + lr[l]() * (60 + l * 30), 20 + lr[l]() * 30, 15 + lr[l]() * 50]);
      }
    }
    final r = mkr(3);
    for (int i = 0; i < 70; i++) {
      _orbs.add([r() * 2450, 60 + r() * 340, 2 + r() * 3, r() * 6]);
    }
    for (int i = 0; i < 26; i++) {
      _tw.add([r() * 1200, r() * kH * .55, r() * 6]);
    }
    for (int i = 0; i < 40; i++) {
      _motes.add([r() * 1400, r() * kH, r() * 6, .5 + r()]);
    }
  }

  final List<List<List<double>>> _layers = [[], [], []];
  final List<List<double>> _orbs = [], _tw = [], _motes = [];
  final math.Random _rn = math.Random();
  double vw = kW;
  TextPainter? _bossTp;
  String _bossName = '';
  WorldTheme get th => a.th;
  LevelConfig get cfg => e.cfg;

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;

  @override
  void paint(Canvas c, Size size) {
    final s = size.height / kH;
    vw = math.min(kMaxView, size.width / s);
    e.vw = vw;
    c.save();
    c.scale(s);
    c.clipRect(Rect.fromLTWH(0, 0, vw, kH));
    _scene(c);
    c.restore();
  }

  Paint _fill(Color col) => Paint()..color = col;

  void _scene(Canvas c) {
    final t = e.t;
    final cam = e.cam;
    double sx = 0, sy = 0;
    if (e.shake > 0) {
      sx = (_rn.nextDouble() - .5) * e.shake;
      sy = (_rn.nextDouble() - .5) * e.shake;
    }
    c.save();
    c.translate(sx, sy);
    c.drawRect(Rect.fromLTWH(-12, -12, vw + 24, kH + 24), _fill(const Color(0xFF04060C)));
    a.sky.draw(c, cam * .02, 0, vw);
    for (final q in _tw) {
      final al = .25 + .6 * (math.sin(t / 22 + q[2]) * .5 + .5);
      final bx = (q[0] - cam * .03) % vw;
      c.drawRect(Rect.fromLTWH(bx, q[1], 2, 2), _fill(Color.fromRGBO(215, 235, 255, al)));
    }
    a.mt1.draw(c, cam * .08, 0, vw);
    _fog(c, a.fog1, 250, .12, .15);
    a.mt2.draw(c, cam * .18, 0, vw);
    final forest = th.wall == WallStyle.trunks;
    for (int i = 0; i < 3; i++) {
      final f = .2 + i * .25;
      final path = Path();
      for (final q in _layers[i]) {
        final bx = q[0] - cam * f;
        if (bx < -80 || bx > vw + 80) continue;
        if (forest) {
          path.addRect(Rect.fromLTWH(bx, 0, 5 + q[2] * .3, kH));
          path.addOval(Rect.fromCenter(center: Offset(bx + 3, 18 + q[3] * .5), width: 40 + q[1] * .5, height: 26));
        } else {
          path.moveTo(bx, kH);
          path.lineTo(bx + q[2] / 2, kH - q[1] - i * 10 - 40);
          path.lineTo(bx + q[2] + 20, kH);
          path.close();
          path.moveTo(bx, 0);
          path.lineTo(bx + q[3] / 3 + 5, q[3] + 20 + i * 10);
          path.lineTo(bx + q[3] / 1.5 + 10, 0);
          path.close();
        }
      }
      c.drawPath(path, _fill(th.spikes[i]));
    }
    for (final o in _orbs) {
      final bx = ((o[0] - cam * .5) % 2450.0);
      if (bx > vw + 20) continue;
      glow(c, bx, o[1] + math.sin(t / 60 + o[3]) * 10, o[2] * 7, th.orb, .35, add: true);
    }
    c.drawRect(
        Rect.fromLTWH(0, 420, vw, 80),
        Paint()..shader = ui.Gradient.linear(const Offset(0, 420), const Offset(0, kH), const [Color(0x003C96C8), Color(0x4D3C96C8)]));
    a.wall.draw(c, cam * .8, 190, vw);
    for (final ar in a.arches) {
      final x0 = ar.x - cam * .8;
      if (x0 < -100 || x0 > vw + 100) continue;
      final top = 190 + 250 - ar.ah;
      final path = Path()
        ..moveTo(x0 - ar.hw, top)
        ..lineTo(x0 + ar.hw, top)
        ..lineTo(x0 + ar.hw + 90, kFloorY)
        ..lineTo(x0 - ar.hw + 40, kFloorY)
        ..close();
      final al = .10 + math.sin(t / 90 + ar.x) * .03;
      c.drawPath(
          path,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.linear(Offset(x0, top), Offset(x0 + 60, kFloorY), [th.moonGlow.a(al), th.moonGlow.a(0)]));
    }
    _props(c, 0);
    _platforms(c);
    _crumbles(c);
    _movers(c);
    _hazards(c);
    _props(c, 1);
    _chests(c);
    _embers(c);
    _fog(c, a.fog2, 370, .35, .6);
    _goal(c);
    for (final en in e.en) {
      if (en.hp > 0) _enemy(c, en);
    }
    if (e.boss != null) _boss(c);
    if (forest) _vines(c);
    _lighting(c);
    _warmGlows(c);
    _projs(c);
    _player(c);
    for (final q in e.parts) {
      final k = q.l / q.max;
      final col = q.c;
      final p = Paint()..color = col.withAlpha((q.a0 * k).round());
      if (q.add) p.blendMode = BlendMode.plus;
      c.drawCircle(Offset(q.x - cam, q.y), q.size * (.4 + .6 * k), p);
    }
    for (final m in _motes) {
      final bx = ((m[0] - cam * 1.2) % (vw + 40)) - 20 + math.sin(t / 50 + m[2]) * 6;
      final by = (m[1] - t * .12 * m[3]) % kH;
      c.drawCircle(Offset(bx, by), 1.1 * m[3], Paint()..color = Color.fromRGBO(170, 210, 255, .35 + .25 * math.sin(t / 20 + m[2]))..blendMode = BlendMode.plus);
    }
    c.restore();
    c.drawRect(
        Rect.fromLTWH(0, 0, vw, kH),
        Paint()
          ..shader = ui.Gradient.radial(Offset(vw / 2, kH / 2), math.sqrt(vw * vw + kH * kH) * .5, const [Color(0x00000000), Color(0xC0000000)], const [.45, 1]));
    if (e.flash > 0) {
      c.drawRect(Rect.fromLTWH(0, 0, vw, kH), _fill(Color.fromRGBO(255, 210, 120, e.flash * .02)));
    }
    _hud(c);
  }

  void _fog(Canvas c, ui.Image img, double y, double sp, double f) {
    final o = -((e.t * sp + e.cam * f) % kW);
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final h = img.height / Art.ps;
    final p = Paint()..filterQuality = FilterQuality.low;
    for (double x = o; x < vw; x += kW) {
      c.drawImageRect(img, src, Rect.fromLTWH(x, y, kW + 0.5, h), p);
    }
  }

  void _props(Canvas c, int layer) {
    final cam = e.cam;
    final p = Paint()..filterQuality = FilterQuality.medium;
    for (final o in a.props) {
      if (o.layer != layer) continue;
      final img = a.sp[o.dark ? '${o.k}_d' : o.k]!;
      final w = o.h * img.width / img.height;
      final px = o.x - cam;
      if (px + w < 0 || px - w > vw) continue;
      if (o.glw != null) {
        glow(c, px, kFloorY - o.h * .5, o.h * 1.2, o.glw!, .30 + math.sin(e.t / 40 + o.x) * .08, add: true);
      }
      c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), Rect.fromLTWH(px - w / 2, kFloorY - o.h, w, o.h), p);
    }
  }

  // ---------------- المنصات
  void _platforms(Canvas c) {
    final cam = e.cam;
    for (final s in cfg.solids) {
      final px = (s.x - cam).roundToDouble();
      if (px > vw || px + s.w < 0 || (s.h > 100 && s.y < 10)) continue;
      final thin = s.h < 30;
      c.save();
      c.translate(px, s.y);
      c.drawRect(Rect.fromLTWH(0, 0, s.w, s.h), (thin && th.wood) ? a.woodPaint : a.gtPaint);
      if (thin) c.drawRect(Rect.fromLTWH(0, s.h - 3, s.w, 3), _fill(const Color(0x59000000)));
      c.restore();
      _topDecor(c, px, s.x, s.y, s.w, thin ? 14.0 : s.h, thin);
    }
  }

  void _topDecor(Canvas c, double px, double wx, double y, double w, double h, bool thin) {
    final t = e.t;
    c.drawRect(Rect.fromLTWH(px, y, w, 2), _fill(th.edge));
    c.drawRect(Rect.fromLTWH(px, y + 2, w, 1), _fill(th.edgeGlow));
    final lo = math.max(0.0, -px), hi = math.min(w, vw - px);
    final g1 = Path(), g2 = Path(), g3 = Path();
    for (double i = lo - (lo % 2); i < hi; i += 2) {
      final hv = hh(wx + i), bh = hv * 4 + 1, sw = math.sin(t / 35 + i * .3) * .7;
      (hv > .55 ? g1 : g2).addRect(Rect.fromLTWH(px + i + sw, y - bh, 1.2, bh + 1));
      if (hv > .93) g3.addRect(Rect.fromLTWH(px + i + sw, y - bh - 1.5, 1.4, 1.4));
    }
    c.drawPath(g1, _fill(th.grass1));
    c.drawPath(g2, _fill(th.grass2));
    c.drawPath(g3, Paint()..color = th.grassTip..blendMode = BlendMode.plus);
    if (thin) {
      final sp = Path();
      for (double i = lo + 4 - (lo % 10); i < hi; i += 10) {
        final d = hh(wx * 3 + i) * 7 + 2;
        sp.moveTo(px + i - 2, y + h);
        sp.lineTo(px + i, y + h + d);
        sp.lineTo(px + i + 2, y + h);
        sp.close();
      }
      c.drawPath(sp, _fill(th.spikes[0]));
    }
  }

  void _movers(Canvas c) {
    final cam = e.cam;
    for (final m in e.movs) {
      final px = m.x - cam;
      if (px > vw + 20 || px + m.w < -20) continue;
      final rope = Paint()..color = const Color(0xAA3A2A1A)..strokeWidth = 1.2;
      c.drawLine(Offset(px + 6, m.y), Offset(px + 6, m.y - 70), rope);
      c.drawLine(Offset(px + m.w - 6, m.y), Offset(px + m.w - 6, m.y - 70), rope);
      c.save();
      c.translate(px, m.y);
      c.drawRect(Rect.fromLTWH(0, 0, m.w, 14), th.wood ? a.woodPaint : a.gtPaint);
      c.restore();
      _topDecor(c, px, m.ox, m.y, m.w, 14, true);
      glow(c, px + m.w / 2, m.y + 16, 22, th.orb, .25, add: true);
    }
  }

  void _crumbles(Canvas c) {
    final cam = e.cam;
    for (final m in e.crums) {
      if (!m.active) continue;
      final px = m.x - cam;
      if (px > vw + 20 || px + m.w < -20) continue;
      final shk = m.timer >= 0 ? math.sin(e.t * 2.2) * 1.4 : 0.0;
      final rail = Paint()..color = const Color(0xCC5A4026)..strokeWidth = 1.3;
      c.drawLine(Offset(px, m.y - 20), Offset(px + 70, m.y - 20), rail);
      c.drawLine(Offset(px, m.y - 20), Offset(px, m.y), rail);
      c.save();
      c.translate(px + shk, m.y + (m.timer >= 0 ? (28 - m.timer) * .06 : 0));
      c.drawRect(Rect.fromLTWH(0, 0, m.w, 14), th.wood ? a.woodPaint : a.gtPaint);
      c.drawRect(Rect.fromLTWH(0, 0, m.w, 2), _fill(const Color(0x55FFD7A0)));
      if (m.timer >= 0) c.drawRect(Rect.fromLTWH(0, 0, m.w, 14), _fill(Color.fromRGBO(255, 120, 60, (28 - m.timer) / 28 * .35)));
      c.restore();
    }
  }

  void _hazards(Canvas c) {
    final cam = e.cam, t = e.t;
    for (final h in e.haz) {
      final px = h.x - cam;
      if (px > vw + 20 || px + h.w < -20) continue;
      final path = Path();
      final tips = Path();
      final n = (h.w / 6).ceil();
      for (int i = 0; i < n; i++) {
        final bx = px + i * (h.w / n);
        final hv = hh(h.x + i * 3.1);
        final hgt = h.h * (.75 + hv * .5);
        path.moveTo(bx - 1, h.y + h.h);
        path.quadraticBezierTo(bx + (h.w / n) * .3, h.y + h.h - hgt * .6, bx + (h.w / n) * .5 + (hv - .5) * 3, h.y + h.h - hgt);
        path.quadraticBezierTo(bx + (h.w / n) * .7, h.y + h.h - hgt * .5, bx + h.w / n + 1, h.y + h.h);
        path.close();
        tips.addOval(Rect.fromCenter(center: Offset(bx + (h.w / n) * .5 + (hv - .5) * 3, h.y + h.h - hgt), width: 2.6, height: 2.6));
      }
      glow(c, px + h.w / 2, h.y + 6, h.w * .9, th.wall == WallStyle.trunks ? const C3(255, 90, 74) : const C3(140, 200, 255), .18 + math.sin(t / 14 + h.x) * .06, add: true);
      c.drawPath(path, _fill(th.hazA));
      c.drawPath(path, Paint()..color = const Color(0x55000000)..style = PaintingStyle.stroke..strokeWidth = .8);
      c.drawPath(tips, Paint()..color = th.hazB..blendMode = BlendMode.plus);
    }
  }

  void _chests(Canvas c) {
    final cam = e.cam;
    for (final ch in e.chests) {
      final px = ch.x - cam;
      if (px < -30 || px > vw + 30) continue;
      final img = a.sp[ch.open ? 'chest_d' : 'chest']!;
      if (!ch.open) glow(c, px + 9, ch.y + 6, 24, const C3(255, 200, 90), .35 + math.sin(e.t / 14) * .1, add: true);
      c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), Rect.fromLTWH(px, ch.y, 20, 14),
          Paint()..filterQuality = FilterQuality.medium);
      if (ch.open && ch.anim < 30) {
        glow(c, px + 10, ch.y - ch.anim * 1.2, 20, const C3(255, 220, 120), .8 * (1 - ch.anim / 30), add: true);
      }
    }
  }

  void _embers(Canvas c) {
    final t = e.t, cam = e.cam;
    for (final m in e.embers) {
      if (m.taken) continue;
      final x = m.x - cam;
      if (x < -20 || x > vw + 20) continue;
      final y = m.y + math.sin(t / 18 + m.x) * 3;
      glow(c, x, y, 20, const C3(255, 170, 70), .55, add: true);
      c.drawCircle(Offset(x, y), 3.6, Paint()..shader = ui.Gradient.radial(Offset(x, y), 4, const [Color(0xFFFFFFFF), Color(0xFFFFC85A)]));
      final r = t / 25 + m.x;
      final sp = Paint()..color = const Color(0xCCFFE6A8)..strokeWidth = 1;
      c.drawLine(Offset(x + math.cos(r) * 7, y + math.sin(r) * 7), Offset(x - math.cos(r) * 7, y - math.sin(r) * 7), sp);
    }
  }

  void _goal(Canvas c) {
    final t = e.t;
    final gx = cfg.goalX - e.cam, gy = cfg.goalY;
    if (gx < -150 || gx > vw + 150) return;
    final open = e.goalOpen;
    final pulse = (.7 + math.sin(t / 20) * .15) * (open ? 1.0 : .25);
    glow(c, gx, gy + 20, 110, const C3(190, 120, 255), pulse, add: true);
    glow(c, gx, gy + 25, 60, const C3(230, 200, 255), open ? .6 : .12, add: true);
    final cy = gy + 25;
    c.drawOval(Rect.fromCenter(center: Offset(gx, cy), width: 30, height: 100),
        Paint()..shader = ui.Gradient.radial(Offset(gx, cy), 50, open ? const [Color(0xFFFFFFFF), Color(0xFFE6C8FF), Color(0xFF9B5CFF)] : const [Color(0xFF3A2A50), Color(0xFF241838), Color(0xFF140C22)], const [0, .5, 1]));
    if (!open) return;
    for (int i = 0; i < 3; i++) {
      final ang = t / (18.0 + i * 7) + i * 2;
      c.drawArc(Rect.fromCenter(center: Offset(gx, cy), width: 40 + i * 14, height: 108 + i * 10), ang, 1.6, false,
          Paint()..color = const Color.fromRGBO(220, 180, 255, .6)..style = PaintingStyle.stroke..strokeWidth = 1.6..blendMode = BlendMode.plus);
    }
    for (int i = 0; i < 10; i++) {
      final ph = (t / 70 + i / 10) % 1;
      final px = gx + math.sin(i * 7.3 + t / 40) * 22, py = cy + 50 - ph * 110;
      c.drawCircle(Offset(px, py), 1.8, Paint()..color = Color.fromRGBO(240, 220, 255, 1 - ph)..blendMode = BlendMode.plus);
    }
  }

  void _vines(Canvas c) {
    final t = e.t, cam = e.cam;
    for (int i = 0; i < 16; i++) {
      final bx = ((i * 131.0) - cam * 1.15) % (vw + 120) - 60;
      final len = 60 + (i * 37) % 90;
      final sw = math.sin(t / 50 + i) * 6;
      final p = Path()
        ..moveTo(bx, -4)
        ..quadraticBezierTo(bx + sw * .5, len * .5, bx + sw, len.toDouble());
      c.drawPath(p, Paint()..color = const Color(0xFF0B2412)..style = PaintingStyle.stroke..strokeWidth = 1.8);
      for (int k = 1; k < 5; k++) {
        c.drawCircle(Offset(bx + sw * k / 5 * .8, len * k / 5.0), 1.8, _fill(const Color(0xAA1E5A2A)));
      }
    }
  }

  // ---------------- الأعداء
  void _enemy(Canvas c, Enemy en) {
    final t = e.t;
    final ex = en.x - e.cam;
    if (ex < -40 || ex > vw + 40) return;
    final flashed = en.hit > 0 && en.kb > 0;
    final body = _fill(flashed ? Colors.white : const Color(0xFF2B1B2E));
    if (en.kind == 2) {
      _spiderSmall(c, en, ex, flashed);
      return;
    }
    if (en.flying) {
      final cx = ex + 9, cy = en.y + 6;
      glow(c, cx, cy, 30, const C3(255, 90, 120), .35, add: true);
      final fl = math.sin(t / 3.5) * 7;
      for (final sgn in const [-1.0, 1.0]) {
        final w = Path()
          ..moveTo(cx, cy)
          ..quadraticBezierTo(cx + sgn * 12, cy - 12 - fl, cx + sgn * 24, cy - 4 - fl * .5)
          ..quadraticBezierTo(cx + sgn * 14, cy + 2, cx, cy + 4)
          ..close();
        c.drawPath(w, body);
      }
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 14), body);
      c.drawCircle(Offset(cx - 2.5, cy - 1), 1.4, _fill(const Color(0xFFFF5A7A)));
      c.drawCircle(Offset(cx + 2.5, cy - 1), 1.4, _fill(const Color(0xFFFF5A7A)));
      return;
    }
    glow(c, ex + 9, en.y + 8, 26, const C3(255, 106, 77), .22, add: true);
    final legs = Paint()..color = (flashed ? Colors.white : const Color(0xFF2B1B2E))..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final o = math.sin(t / 6 + i) * 2;
      c.drawLine(Offset(ex + 3 + i * 6, en.y + 11), Offset(ex + 1.5 + i * 6 + o, en.y + 15), legs);
    }
    final dome = Path()
      ..moveTo(ex - 1, en.y + 12)
      ..quadraticBezierTo(ex + 9, en.y - 8, ex + 19, en.y + 12)
      ..close();
    c.drawPath(dome, flashed ? _fill(Colors.white) : (Paint()..shader = ui.Gradient.linear(Offset(ex, en.y - 2), Offset(ex, en.y + 12), const [Color(0xFF4A2F55), Color(0xFF1C1020)])));
    for (int i = 0; i < 3; i++) {
      c.drawCircle(Offset(ex + 5 + i * 4.5, en.y + 4 + (i % 2) * 2), 1, _fill(const Color(0xAA4FE3C1)));
    }
    final ex2 = ex + (en.d > 0 ? 12.5 : 5.5);
    glow(c, ex2, en.y + 5.5, 6, const C3(255, 106, 77), .8, add: true);
    c.drawCircle(Offset(ex2, en.y + 5.5), 1.8, _fill(const Color(0xFFFF8A5D)));
  }

  void _spiderSmall(Canvas c, Enemy en, double ex, bool flashed) {
    final t = e.t;
    final cx = ex + 10, cy = en.y + 7;
    final col = flashed ? Colors.white : const Color(0xFF1A1220);
    glow(c, cx, cy, 24, const C3(120, 255, 120), .22, add: true);
    final legs = Paint()..color = col..strokeWidth = 1.3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      for (final sg in const [-1.0, 1.0]) {
        final sw = math.sin(t / 5 + i * 1.3 + (sg > 0 ? 1.5 : 0)) * 2;
        final kx = cx + sg * (6 + i * 1.6), ky = cy - 5 - (i == 0 || i == 3 ? 0 : 1) + sw * .3;
        final fx = cx + sg * (11 + i * 2.2), fy = cy + 5 + (en.jy < 0 ? -3 : 0) + sw * .4;
        c.drawPath(Path()..moveTo(cx + sg * 2, cy)..lineTo(kx, ky)..lineTo(fx, fy), legs);
      }
    }
    c.drawOval(Rect.fromCenter(center: Offset(cx - en.d * 2.5, cy + 1), width: 12, height: 9), _fill(col));
    c.drawOval(Rect.fromCenter(center: Offset(cx + en.d * 4, cy), width: 7, height: 6), _fill(col));
    c.drawCircle(Offset(cx - en.d * 2.5, cy), 1.3, _fill(const Color(0xAA79FF6A)));
    final ey = cx + en.d * 5.2;
    glow(c, ey, cy - 1, 5, const C3(120, 255, 120), .8, add: true);
    c.drawCircle(Offset(ey, cy - 1), 1.1, _fill(const Color(0xFFB6FF9A)));
    c.drawCircle(Offset(ey - en.d * 1.8, cy - 1.2), .9, _fill(const Color(0xFFB6FF9A)));
  }

  // ---------------- الزعيم: ملك العناكب
  void _boss(Canvas c) {
    final b = e.boss!;
    final cx = b.x + b.w / 2 - e.cam;
    if (cx < -120 || cx > vw + 120) return;
    if (b.st == 'dead' && b.dead > 140) return;
    final t = e.t;
    final flashed = b.hit > 0;
    final stun = b.st == 'stun';
    double shk = 0;
    if (b.st == 'charge' && b.t < 32) shk = math.sin(t * 1.8) * 2.2;
    if (b.st == 'dead') shk = math.sin(t * 2.4) * 3;
    final cy = b.y + b.h / 2;
    final face = b.dir.toDouble();
    final fade = b.st == 'dead' ? math.max(0.0, 1 - math.max(0, b.dead - 60) / 80) : 1.0;
    c.saveLayer(Rect.fromLTWH(cx - 130, cy - 120, 260, 200), Paint()..color = Color.fromRGBO(255, 255, 255, fade));
    c.translate(shk, 0);
    c.drawOval(Rect.fromCenter(center: Offset(cx, kFloorY), width: 130, height: 12), _fill(const Color(0x66000000)));
    final dark = flashed ? Colors.white : const Color(0xFF1B1226);
    final mid = flashed ? Colors.white : const Color(0xFF3A2250);
    final legP = Paint()..color = dark..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final moving = b.st == 'idle' || b.st == 'charge';
    for (int i = 0; i < 4; i++) {
      for (final sg in const [-1.0, 1.0]) {
        final ph = moving ? math.sin(t / (b.st == 'charge' ? 2.5 : 7) + i * 1.5 + (sg > 0 ? 1.6 : 0)) : 0.0;
        final hipX = cx + sg * (16 + i * 4), hipY = cy + 2;
        final kneeX = cx + sg * (50 + i * 9), kneeY = cy - 30 + i * 9 - (ph > 0 ? ph * 7 : 0);
        final footX = cx + sg * (66 + i * 12) + ph * 4, footY = kFloorY - (ph > 0 ? ph * 6 : 0);
        c.drawPath(Path()..moveTo(hipX, hipY)..lineTo(kneeX, kneeY)..lineTo(footX, footY), legP);
      }
    }
    final abX = cx - face * 22;
    c.drawOval(Rect.fromCenter(center: Offset(abX, cy - 4), width: 74, height: 56),
        Paint()..shader = flashed ? null : ui.Gradient.radial(Offset(abX - 8, cy - 18), 44, [mid, dark]));
    if (flashed) c.drawOval(Rect.fromCenter(center: Offset(abX, cy - 4), width: 74, height: 56), _fill(Colors.white));
    final markC = stun ? const C3(255, 226, 122) : (b.enraged ? const C3(255, 58, 42) : const C3(184, 74, 255));
    final markA = stun ? .9 + math.sin(t / 3) * .1 : .55;
    glow(c, abX, cy - 6, stun ? 34 : 20, markC, markA, add: true);
    final mark = Path()
      ..moveTo(abX - 8, cy - 18)
      ..lineTo(abX + 8, cy - 18)
      ..lineTo(abX, cy - 6)
      ..lineTo(abX + 8, cy + 6)
      ..lineTo(abX - 8, cy + 6)
      ..lineTo(abX, cy - 6)
      ..close();
    c.drawPath(mark, Paint()..color = markC.a(markA > 1 ? 1.0 : markA));
    final hx = cx + face * 26;
    c.drawOval(Rect.fromCenter(center: Offset(hx, cy + 2), width: 40, height: 34), _fill(flashed ? Colors.white : const Color(0xFF2A1A3A)));
    for (int i = 0; i < 4; i++) {
      final ex = hx + face * (6 + (i % 2) * 7), ey = cy - 3 + (i ~/ 2) * 7;
      final ec = b.enraged ? const C3(255, 60, 40) : const C3(255, 200, 60);
      glow(c, ex, ey, 7, ec, .8, add: true);
      c.drawCircle(Offset(ex, ey), 2.1, _fill(b.enraged ? const Color(0xFFFF6A50) : const Color(0xFFFFE27A)));
    }
    final fang = _fill(const Color(0xFFEDE6D0));
    for (final sg in const [-1.0, 1.0]) {
      c.drawPath(
          Path()
            ..moveTo(hx + face * 14 + sg * 3, cy + 12)
            ..lineTo(hx + face * 14 + sg * 5, cy + 22)
            ..lineTo(hx + face * 14 + sg * 1, cy + 12)
            ..close(),
          fang);
    }
    final crown = _fill(const Color(0xFFE8B83A));
    final crX = hx - face * 2, crY = cy - 16;
    c.drawPath(
        Path()
          ..moveTo(crX - 12, crY + 4)
          ..lineTo(crX - 10, crY - 6)
          ..lineTo(crX - 5, crY)
          ..lineTo(crX, crY - 9)
          ..lineTo(crX + 5, crY)
          ..lineTo(crX + 10, crY - 6)
          ..lineTo(crX + 12, crY + 4)
          ..close(),
        crown);
    if (b.st == 'web' && b.t < 28) {
      glow(c, hx + face * 18, cy + 8, 20 + b.t * .5, const C3(210, 255, 200), .5, add: true);
    }
    if (b.st == 'charge' && b.t < 32) {
      glow(c, cx, cy, 70, const C3(255, 60, 40), .15 + (b.t % 8) * .03, add: true);
    }
    if (b.enraged && b.st != 'dead') glow(c, cx, cy, 80, const C3(255, 50, 30), .18 + math.sin(t / 6) * .05, add: true);
    if (stun) {
      for (int i = 0; i < 4; i++) {
        final ang = t / 8 + i * math.pi / 2;
        c.drawCircle(Offset(hx + math.cos(ang) * 16, cy - 26 + math.sin(ang) * 5), 2.2, Paint()..color = const Color(0xFFFFE27A)..blendMode = BlendMode.plus);
      }
    }
    c.restore();
  }

  void _projs(Canvas c) {
    final cam = e.cam;
    for (final q in e.projs) {
      final x = q.x - cam;
      if (x < -20 || x > vw + 20) continue;
      if (q.kind == 0) {
        glow(c, x, q.y, 12, const C3(200, 255, 190), .7, add: true);
        c.drawCircle(Offset(x, q.y), 3.4, _fill(const Color(0xFFE8FFE0)));
        c.drawLine(Offset(x, q.y), Offset(x - q.vx * 4, q.y - q.vy * 4), Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 1);
      } else {
        glow(c, x, q.y + 6, 16, const C3(200, 120, 255), .6, add: true);
        c.drawOval(Rect.fromCenter(center: Offset(x, q.y + 6), width: 10, height: 16), Paint()..color = const Color(0xCCE6B8FF)..blendMode = BlendMode.plus);
      }
    }
  }

  void _lighting(Canvas c) {
    final cam = e.cam, t = e.t;
    c.saveLayer(Rect.fromLTWH(-12, -12, vw + 24, kH + 24), Paint());
    c.drawRect(Rect.fromLTWH(-12, -12, vw + 24, kH + 24), _fill(Color.fromRGBO(3, 6, 16, th.dark)));
    void hole(double x, double y, double r, double s) {
      if (x < -r || x > vw + r) return;
      c.drawCircle(Offset(x, y), r, Paint()..blendMode = BlendMode.dstOut..shader = ui.Gradient.radial(Offset(x, y), r, [Color.fromRGBO(255, 255, 255, s), const Color(0x00FFFFFF)]));
    }
    hole(e.p.x - cam + 7, e.p.y + 12, 200 + math.sin(t / 12) * 6, .97);
    for (final o in a.props) {
      if (o.glw == null) continue;
      hole(o.x - cam, kFloorY - o.h * .5, o.h * 2.2 + 30, .9);
    }
    for (final m in e.embers) {
      if (!m.taken) hole(m.x - cam, m.y, 40, .9);
    }
    for (final ch in e.chests) {
      if (!ch.open) hole(ch.x - cam + 10, ch.y + 6, 44, .9);
    }
    hole(cfg.goalX - cam, cfg.goalY + 25, 240, e.goalOpen ? 1 : .5);
    for (final en in e.en) {
      if (en.hp > 0) hole(en.x - cam + 9, en.y + 6, 36, .8);
    }
    final b = e.boss;
    if (b != null && b.st != 'sleep') hole(b.x + b.w / 2 - cam, b.y + 28, 110, .95);
    for (final q in e.projs) {
      hole(q.x - cam, q.y, 28, .9);
    }
    c.restore();
  }

  void _warmGlows(Canvas c) {
    final cam = e.cam, t = e.t;
    for (final o in a.props) {
      final px = o.x - cam;
      if (px < -40 || px > vw + 40) continue;
      if (o.k == 'torch') {
        final fy = kFloorY - o.h + 2;
        final fl = math.sin(t / 3 + o.x) * 1.2;
        glow(c, px, fy - 4, 46, const C3(255, 150, 60), .55 + math.sin(t / 5 + o.x) * .1, add: true);
        final f = Path()
          ..moveTo(px - 4, fy)
          ..quadraticBezierTo(px - 5 + fl, fy - 8, px + fl, fy - 15 - fl.abs())
          ..quadraticBezierTo(px + 5 + fl, fy - 8, px + 4, fy)
          ..close();
        c.drawPath(f, Paint()..color = const Color(0xCCFF9A3C)..blendMode = BlendMode.plus);
        c.drawOval(Rect.fromCenter(center: Offset(px, fy - 4), width: 4, height: 8), Paint()..color = const Color(0xCCFFEBB0)..blendMode = BlendMode.plus);
      } else if (o.k == 'lantern') {
        glow(c, px - 4, kFloorY - o.h * .3, 22, const C3(255, 190, 90), .5 + math.sin(t / 9 + o.x) * .08, add: true);
      }
    }
    final p = e.p;
    final px = p.x - cam + 7;
    glow(c, px, p.y + 14, 120, const C3(255, 170, 70), .42 + math.sin(t / 12) * .05, add: true);
  }

  void _player(Canvas c) {
    final p = e.p, t = e.t;
    final px = p.x - e.cam, py = p.y;
    if (e.phase == Phase.dead) return;
    if (p.inv > 0 && t % 6 < 3) return;
    const ch = 39.3;
    const k = ch / 448.0;
    const dw = 188 * k;
    Offset pv(double x, double y) => Offset(-dw / 2 + x * k, -ch + y * k);
    final shN = pv(116.7, 164.3), shF = pv(36.3, 164.3);
    final hipN = pv(85.3, 257.6), hipF = pv(67.6, 257.6);
    const legScale = 0.82; // تقصير الرجلين قليلاً
    const drop = (448 - 257.6) * k * (1 - legScale);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    void layer(String n, {double ang = 0, Offset piv = Offset.zero, double dy = 0, double sy = 1}) {
      final img = a.sp[n]!;
      c.save();
      c.translate(0, dy);
      if (ang != 0 || sy != 1) {
        c.translate(piv.dx, piv.dy);
        c.rotate(ang);
        c.scale(1, sy);
        c.translate(-piv.dx, -piv.dy);
      }
      c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), const Rect.fromLTWH(-dw / 2, -ch, dw, ch), paint);
      c.restore();
    }

    c.save();
    c.translate(px + 7, py + 22);
    c.scale(p.f.toDouble() * (1 + p.sq * .5), 1 - p.sq);
    c.rotate(p.lean);
    // ظل خفيف تحت القدمين
    c.drawOval(Rect.fromCenter(center: const Offset(0, 0.5), width: 14, height: 3), _fill(const Color(0x55000000)));
    layer('hero_armF', ang: p.aF, piv: shF, dy: p.bob + drop);
    layer('hero_legF', ang: p.lF, piv: hipF, dy: drop, sy: legScale);
    layer('hero_legN', ang: p.lN, piv: hipN, dy: drop, sy: legScale);
    layer('hero_body', dy: p.bob + drop);
    layer('hero_armN', ang: p.aN, piv: shN, dy: p.bob + drop);
    layer('hero_weapon', ang: p.aN, piv: shN, dy: p.bob + drop);
    // الفانوس في اليد
    final hand = Offset(shF.dx - math.sin(p.aF) * 12.0, shF.dy + p.bob + drop + math.cos(p.aF) * 12.0);
    final lp = hand + const Offset(1.6, 1.8);
    c.drawLine(hand, lp, Paint()..color = const Color(0xFF1A1424)..strokeWidth = 0.8);
    glow(c, lp.dx, lp.dy + 1, 10, const C3(255, 190, 90), .9, add: true);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lp + const Offset(0, 1.5), width: 3.4, height: 4.2), const Radius.circular(1)), _fill(const Color(0xFFFFB347)));
    c.drawCircle(lp + const Offset(0, 1.5), 0.9, _fill(const Color(0xFFFFF4D2)));
    c.restore();
    // موجة الصدمة عند ضرب المطرقة
    if (p.atk > 7 && p.atk < 13) {
      final k2 = (13 - p.atk) / 6;
      final ix = px + 7 + p.f * 24;
      glow(c, ix, py + 20, 14 + k2 * 22, const C3(150, 230, 255), .9 * (1 - k2), add: true);
      c.drawOval(Rect.fromCenter(center: Offset(ix, py + 21), width: 20 + k2 * 50, height: 6 + k2 * 10),
          Paint()..color = Color.fromRGBO(190, 240, 255, .8 * (1 - k2))..style = PaintingStyle.stroke..strokeWidth = 1.5..blendMode = BlendMode.plus);
    }
  }

  void _hud(Canvas c) {
    final p = e.p, t = e.t;
    for (int i = 0; i < e.maxHp; i++) {
      final on = i < p.hp;
      final x = 20.0 + i * 19, y = 24.0;
      if (on) glow(c, x, y, 13, const C3(255, 170, 70), .6, add: true);
      c.drawCircle(Offset(x, y), 6.5, Paint()..shader = ui.Gradient.radial(Offset(x - 1, y - 1), 8, on ? const [Color(0xFFFFF1C2), Color(0xFFFF9A3C)] : const [Color(0xFF3A4156), Color(0xFF1F2433)]));
      c.drawCircle(Offset(x, y), 6.5, Paint()..color = (on ? const Color(0x88FFE3A8) : const Color(0x44556080))..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    final txt = '${e.collected}/${e.totalEmbers}';
    final tp = TextPainter(text: TextSpan(text: txt, style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 14, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, Offset(vw - 14 - tp.width, 15));
    final ix = vw - 14 - tp.width - 14, iy = 24 + math.sin(t / 15) * 1.0;
    glow(c, ix, iy, 12, const C3(255, 170, 70), .6, add: true);
    c.drawCircle(Offset(ix, iy), 4.2, _fill(const Color(0xFFFFD27A)));
    final b = e.boss;
    if (b != null && b.st != 'sleep') {
      if (_bossName != b.name) {
        _bossName = b.name;
        _bossTp = TextPainter(text: TextSpan(text: b.name, style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 13, fontWeight: FontWeight.w800)), textDirection: TextDirection.rtl)..layout();
      }
      final w = math.min(240.0, vw - 60), x0 = (vw - w) / 2, y0 = 54.0;
      _bossTp?.paint(c, Offset((vw - _bossTp!.width) / 2, y0 - 18));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0 - 2, y0 - 2, w + 4, 12), const Radius.circular(6)), _fill(const Color(0xAA000000)));
      final frac = (b.hp / b.maxHp).clamp(0.0, 1.0).toDouble();
      if (frac > 0) {
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x0, y0, w * frac, 8), const Radius.circular(4)),
            Paint()..shader = ui.Gradient.linear(Offset(x0, y0), Offset(x0 + w, y0), b.enraged ? const [Color(0xFFFF3A2A), Color(0xFFFF8A3C)] : const [Color(0xFFB84AFF), Color(0xFFFF6AB0)]));
      }
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0 - 2, y0 - 2, w + 4, 12), const Radius.circular(6)), Paint()..color = const Color(0x88FFE3A8)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
  }
}
