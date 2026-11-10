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
      _orbs.add([r() * kLW, 60 + r() * 340, 2 + r() * 3, r() * 6]);
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
    // أعمدة كهف متوازية
    const cols = [Color(0xFF0A1426), Color(0xFF0C1A33), Color(0xFF08101F)];
    for (int i = 0; i < 3; i++) {
      final f = .2 + i * .25;
      final path = Path();
      for (final q in _layers[i]) {
        final bx = q[0] - cam * f;
        if (bx < -80 || bx > vw + 80) continue;
        path.moveTo(bx, kH);
        path.lineTo(bx + q[2] / 2, kH - q[1] - i * 10 - 40);
        path.lineTo(bx + q[2] + 20, kH);
        path.close();
        path.moveTo(bx, 0);
        path.lineTo(bx + q[3] / 3 + 5, q[3] + 20 + i * 10);
        path.lineTo(bx + q[3] / 1.5 + 10, 0);
        path.close();
      }
      c.drawPath(path, _fill(cols[i]));
    }
    for (final o in _orbs) {
      final bx = ((o[0] - cam * .5) % kLW);
      if (bx > vw + 20) continue;
      glow(c, bx, o[1] + math.sin(t / 60 + o[3]) * 10, o[2] * 7, const C3(140, 170, 255), .35, add: true);
    }
    c.drawRect(
        Rect.fromLTWH(0, 420, vw, 80),
        Paint()..shader = ui.Gradient.linear(const Offset(0, 420), const Offset(0, kH), const [Color(0x003C96C8), Color(0x4D3C96C8)]));
    a.wall.draw(c, cam * .8, 190, vw);
    // أشعة ضوء من الأقواس
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
            ..shader = ui.Gradient.linear(Offset(x0, top), Offset(x0 + 60, kFloorY), [Color.fromRGBO(150, 190, 255, al), const Color(0x0096BEFF)]));
    }
    _props(c, 0);
    _platforms(c);
    _props(c, 1);
    _embers(c);
    _fog(c, a.fog2, 370, .35, .6);
    _goal(c);
    for (final en in e.en) {
      if (en.hp > 0) _enemy(c, en);
    }
    _lighting(c);
    _warmGlows(c);
    _player(c);
    for (final q in e.parts) {
      final k = q.l / q.max;
      final col = q.c;
      final p = Paint()..color = col.withAlpha((col.alpha * k).round().clamp(0, 255).toInt());
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

  void _platforms(Canvas c) {
    final cam = e.cam, t = e.t;
    for (final s in Level.solids) {
      final px = (s.x - cam).roundToDouble();
      if (px > vw || px + s.w < 0 || (s.h > 100 && s.y < 10)) continue;
      c.save();
      c.translate(px, s.y);
      c.drawRect(Rect.fromLTWH(0, 0, s.w, s.h), a.gtPaint);
      if (s.h < 30) c.drawRect(Rect.fromLTWH(0, s.h - 3, s.w, 3), _fill(const Color(0x59000000)));
      c.restore();
      c.drawRect(Rect.fromLTWH(px, s.y, s.w, 2), _fill(const Color(0xFF3A6AA6)));
      c.drawRect(Rect.fromLTWH(px, s.y + 2, s.w, 1), _fill(const Color(0x4078B4FF)));
      final lo = math.max(0.0, -px), hi = math.min(s.w, vw - px);
      final g1 = Path(), g2 = Path(), g3 = Path();
      for (double i = lo - (lo % 2); i < hi; i += 2) {
        final hv = hh(s.x + i), bh = hv * 4 + 1, sw = math.sin(t / 35 + i * .3) * .7;
        (hv > .55 ? g1 : g2).addRect(Rect.fromLTWH(px + i + sw, s.y - bh, 1.2, bh + 1));
        if (hv > .93) g3.addRect(Rect.fromLTWH(px + i + sw, s.y - bh - 1.5, 1.4, 1.4));
      }
      c.drawPath(g1, _fill(const Color(0xFF2A7A68)));
      c.drawPath(g2, _fill(const Color(0xFF1B5252)));
      c.drawPath(g3, Paint()..color = const Color(0xCC8CFFE1)..blendMode = BlendMode.plus);
      if (s.h < 30) {
        final sp = Path();
        for (double i = lo + 4 - (lo % 10); i < hi; i += 10) {
          final d = hh(s.x * 3 + i) * 7 + 2;
          sp.moveTo(px + i - 2, s.y + s.h);
          sp.lineTo(px + i, s.y + s.h + d);
          sp.lineTo(px + i + 2, s.y + s.h);
          sp.close();
        }
        c.drawPath(sp, _fill(const Color(0xFF0A1426)));
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
    final gx = Level.goalX - e.cam, gy = Level.goalY;
    if (gx < -150 || gx > vw + 150) return;
    final pulse = .7 + math.sin(t / 20) * .15;
    glow(c, gx, gy + 20, 110, const C3(190, 120, 255), pulse, add: true);
    glow(c, gx, gy + 25, 60, const C3(230, 200, 255), .6, add: true);
    final cy = gy + 25;
    c.drawOval(Rect.fromCenter(center: Offset(gx, cy), width: 30, height: 100),
        Paint()..shader = ui.Gradient.radial(Offset(gx, cy), 50, const [Color(0xFFFFFFFF), Color(0xFFE6C8FF), Color(0xFF9B5CFF)], const [0, .5, 1]));
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

  void _enemy(Canvas c, Enemy en) {
    final t = e.t;
    final ex = en.x - e.cam;
    if (ex < -40 || ex > vw + 40) return;
    final flashed = en.hit > 0 && en.kb > 0;
    final body = _fill(flashed ? Colors.white : const Color(0xFF2B1B2E));
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

  void _lighting(Canvas c) {
    final cam = e.cam, t = e.t;
    c.saveLayer(Rect.fromLTWH(-12, -12, vw + 24, kH + 24), Paint());
    c.drawRect(Rect.fromLTWH(-12, -12, vw + 24, kH + 24), _fill(const Color(0x94030610)));
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
    hole(Level.goalX - cam, Level.goalY + 25, 240, 1);
    for (final en in e.en) {
      if (en.hp > 0) hole(en.x - cam + 9, en.y + 6, 36, .8);
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
    final paint = Paint()..filterQuality = FilterQuality.medium;
    void layer(String n, {double ang = 0, Offset piv = Offset.zero, double dy = 0}) {
      final img = a.sp[n]!;
      c.save();
      c.translate(0, dy);
      if (ang != 0) {
        c.translate(piv.dx, piv.dy);
        c.rotate(ang);
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
    layer('hero_armF', ang: p.aF, piv: shF, dy: p.bob);
    layer('hero_legF', ang: p.lF, piv: hipF);
    layer('hero_legN', ang: p.lN, piv: hipN);
    layer('hero_body', dy: p.bob);
    layer('hero_armN', ang: p.aN, piv: shN, dy: p.bob);
    layer('hero_weapon', ang: p.aN, piv: shN, dy: p.bob);
    // الفانوس في اليد
    final hand = Offset(shF.dx - math.sin(p.aF) * 12.0, shF.dy + p.bob + math.cos(p.aF) * 12.0);
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
    for (int i = 0; i < 5; i++) {
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
    // اسم المنطقة
  }
}
