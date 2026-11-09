import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'level.dart';

enum Phase { menu, playing, dead, won }

class Player extends Box {
  double vx = 0, vy = 0, anim = 0, sq = 0;
  int f = 1, coy = 0, atk = 0, dash = 0, dcd = 0, hp = 5, inv = 0, jb = 0;
  bool g = false, pj = false, pa = false, pd = false;
  Player() : super(30, 400, 14, 22);
}

class Enemy extends Box {
  double minX, maxX, ph;
  int d = 1, hp = 2, hit = 0, kb = 0;
  bool flying;
  double baseY;
  Enemy(double x, double y, this.minX, this.maxX, this.flying, this.ph)
      : baseY = y,
        super(x, y, 18, 12);
}

class Part {
  double x, y, vx, vy, size;
  int l, max;
  Color c;
  bool add;
  Part(this.x, this.y, this.vx, this.vy, this.l, this.c, this.size, this.add) : max = l;
}

class Ember {
  final double x, y;
  bool taken = false;
  Ember(this.x, this.y);
}

class GameEngine extends ChangeNotifier {
  final ValueNotifier<int> frame = ValueNotifier<int>(0);
  final math.Random rng = math.Random();

  Phase phase = Phase.menu;
  bool paused = false;
  bool left = false, right = false, jump = false, dash = false, atk = false;

  late Player p;
  List<Enemy> en = [];
  List<Ember> embers = [];
  List<Part> parts = [];
  double cam = 0;
  int t = 0, shake = 0, cp = 30, deadT = 0, playFrames = 0, kills = 0, collected = 0, flash = 0;

  double _acc = 0, _last = 0;

  GameEngine() {
    reset(true);
  }

  int get totalEmbers => Level.embers.length;

  void reset(bool full) {
    p = Player()..x = cp.toDouble();
    if (full) {
      cp = 30;
      p.x = 30;
      en = [];
      for (final a in Level.enemies) {
        final fl = a.length > 3;
        final y = (fl ? a[3] : kFloorY) - 12;
        en.add(Enemy(a[0], y, a[1], a[2], fl, rng.nextDouble() * 6));
      }
      embers = Level.embers.map((a) => Ember(a[0], a[1])).toList();
      kills = 0;
      collected = 0;
      playFrames = 0;
      cam = 0;
    }
  }

  void start() {
    reset(true);
    phase = Phase.playing;
    paused = false;
    notifyListeners();
  }

  void togglePause() {
    if (phase != Phase.playing) return;
    paused = !paused;
    left = right = jump = dash = atk = false;
    notifyListeners();
  }

  void tick(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000.0;
    double dt = ms - _last;
    _last = ms;
    if (dt > 50) dt = 50;
    _acc += dt;
    while (_acc > 16.67) {
      _step();
      _acc -= 16.67;
    }
    frame.value++;
  }

  void _step() {
    t++;
    _updateParts();
    if (shake > 0) shake--;
    if (flash > 0) flash--;
    if (phase == Phase.menu) {
      cam += ((math.sin(t / 300) * 0.5 + 0.5) * 120 - cam) * 0.01;
      return;
    }
    if (paused) return;
    if (phase == Phase.dead) {
      deadT++;
      if (deadT > 110) {
        reset(true);
        phase = Phase.playing;
        notifyListeners();
      }
      return;
    }
    if (phase == Phase.won) {
      cam += ((Level.goalX - kW / 2 - cam)) * 0.03;
      if (t % 3 == 0) {
        _spark(Level.goalX + (rng.nextDouble() - .5) * 40, Level.goalY + 20 + (rng.nextDouble() - .5) * 80, 1, const Color(0xFFE6C8FF), add: true);
      }
      return;
    }
    playFrames++;
    _updatePlayer();
  }

  void _updatePlayer() {
    final L = left, R = right;
    if (p.inv > 0) p.inv--;
    if (p.dcd > 0) p.dcd--;
    if (jump && !p.pj) p.jb = 8;
    p.pj = jump;
    if (p.jb > 0) p.jb--;
    if (atk && !p.pa && p.atk <= 0) {
      p.atk = 14;
      for (final e in en) {
        e.hit = 0;
      }
    }
    p.pa = atk;
    if (dash && !p.pd && p.dcd <= 0 && p.dash <= 0) {
      p.dash = 10;
      p.dcd = 40;
      p.vy = 0;
    }
    p.pd = dash;
    if (p.dash > 0) {
      p.dash--;
      p.vx = p.f * 7.0;
      p.vy = 0;
      if (t % 2 == 0) _spark(p.x + 7, p.y + 11, 1, const Color(0xFF66AADD), add: true);
    } else {
      final a = p.g ? .6 : .4;
      if (L && !R) {
        p.vx -= a;
        p.f = -1;
      } else if (R && !L) {
        p.vx += a;
        p.f = 1;
      } else {
        p.vx *= .78;
      }
      p.vx = math.max(-2.7, math.min(2.7, p.vx));
      p.vy += .5;
      if (p.vy > 11) p.vy = 11;
    }
    if (p.g) {
      p.coy = 6;
    } else if (p.coy > 0) {
      p.coy--;
    }
    if (p.jb > 0 && p.coy > 0) {
      p.vy = -9.2;
      p.coy = 0;
      p.jb = 0;
      p.g = false;
      p.sq = -0.25;
      _dust(p.x + 7, p.y + 22, 6);
    }
    if (!jump && p.vy < -3 && p.dash <= 0) p.vy = -3;

    final wasG = p.g;
    final preVy = p.vy;
    _moveX(p, p.vx);
    p.g = _moveY(p, p.vy);
    if (p.g && !wasG && preVy > 3) {
      p.sq = 0.3;
      _dust(p.x + 7, p.y + 22, 8);
    }
    p.sq *= 0.8;
    if (p.g && p.vx.abs() > 0.5) {
      p.anim += p.vx.abs() * 0.12;
      if (t % 9 == 0) _dust(p.x + 7, p.y + 22, 1);
    }
    if (p.atk > 0) p.atk--;

    for (final s in Level.grounds) {
      if (s.x + 20 < p.x && s.x + 30 > cp && p.g) {
        cp = (s.x + 30).toInt();
        _spark(p.x + 7, p.y + 10, 18, const Color(0xFF9FE8FF), add: true);
        HapticFeedback.selectionClick();
      }
    }
    if (p.y > kH + 40) {
      p.hp--;
      shake = 8;
      p.x = cp.toDouble();
      p.y = 380;
      p.vx = p.vy = 0;
      p.inv = 60;
      if (p.hp <= 0) {
        _die();
        return;
      }
    }

    final ab = Box(p.f > 0 ? p.x + p.w : p.x - 30, p.y - 2, 30, 26);
    for (final e in en) {
      if (e.hp <= 0) continue;
      if (e.flying) e.y = e.baseY + math.sin(t / 25 + e.ph) * 10;
      if (e.kb > 0) {
        e.kb--;
        e.x += (p.x < e.x ? 1 : -1) * 2.5;
      } else {
        e.x += e.d * (e.flying ? 0.9 : 0.7);
        if (e.x < e.minX) e.d = 1;
        if (e.x + e.w > e.maxX) e.d = -1;
      }
      if (p.atk > 3 && p.atk < 12 && e.hit == 0 && ab.hits(e)) {
        e.hit = 1;
        e.hp--;
        e.kb = 8;
        _spark(e.x + 9, e.y + 6, 10, const Color(0xFFFFB347), add: true);
        shake = 4;
        HapticFeedback.lightImpact();
        if (e.hp <= 0) {
          kills++;
          _spark(e.x + 9, e.y + 6, 26, const Color(0xFFFFD27A), add: true);
        }
      }
      if (e.hp > 0 && p.inv <= 0 && p.hits(e)) {
        p.hp--;
        p.inv = 70;
        p.vy = -5;
        p.vx = (p.x < e.x ? -1 : 1) * 4.0;
        shake = 7;
        _spark(p.x + 7, p.y + 11, 12, const Color(0xFFFF6666));
        HapticFeedback.mediumImpact();
        if (p.hp <= 0) {
          _die();
          return;
        }
      }
    }

    for (final m in embers) {
      if (m.taken) continue;
      final dx = (p.x + 7) - m.x, dy = (p.y + 11) - m.y;
      if (dx * dx + dy * dy < 20 * 20) {
        m.taken = true;
        collected++;
        _spark(m.x, m.y, 14, const Color(0xFFFFD98A), add: true);
        flash = 6;
        HapticFeedback.selectionClick();
        if (collected % 6 == 0 && p.hp < 5) p.hp++;
      }
    }

    if ((p.x - Level.goalX).abs() < 30 && (p.y - Level.goalY).abs() < 70) {
      phase = Phase.won;
      _spark(Level.goalX, Level.goalY + 20, 50, const Color(0xFFE6C8FF), add: true);
      HapticFeedback.heavyImpact();
      notifyListeners();
    }
    cam += ((math.max(0.0, math.min(kLW - kW, p.x - kW / 2 + p.f * 30))) - cam) * .1;
  }

  void _die() {
    phase = Phase.dead;
    deadT = 0;
    shake = 12;
    _spark(p.x + 7, p.y + 11, 40, const Color(0xFFFFB347), add: true);
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  // ---- فيزياء
  void _moveX(Player o, double dx) {
    o.x += dx;
    for (final s in Level.solids) {
      if (o.hits(s)) {
        if (dx > 0) {
          o.x = s.x - o.w;
        } else if (dx < 0) {
          o.x = s.x + s.w;
        }
        o.vx = 0;
      }
    }
  }

  bool _moveY(Player o, double dy) {
    bool g = false;
    o.y += dy;
    for (final s in Level.solids) {
      if (o.hits(s)) {
        if (dy > 0) {
          o.y = s.y - o.h;
          g = true;
        } else if (dy < 0) {
          o.y = s.y + s.h;
        }
        o.vy = 0;
      }
    }
    return g;
  }

  // ---- جسيمات
  void _spark(double x, double y, int n, Color c, {bool add = false}) {
    for (int i = 0; i < n; i++) {
      parts.add(Part(x, y, (rng.nextDouble() - .5) * 4, (rng.nextDouble() - .5) * 4, 25 + rng.nextInt(15), c, 1.5 + rng.nextDouble() * 2, add));
    }
  }

  void _dust(double x, double y, int n) {
    for (int i = 0; i < n; i++) {
      parts.add(Part(x + (rng.nextDouble() - .5) * 8, y, (rng.nextDouble() - .5) * 1.4, -rng.nextDouble() * .6, 22, const Color(0x889FB8D8), 1.5 + rng.nextDouble() * 1.5, false));
    }
  }

  void _updateParts() {
    for (final q in parts) {
      q.x += q.vx;
      q.y += q.vy;
      q.vy += q.add ? 0.03 : -0.01;
      q.l--;
    }
    parts.removeWhere((q) => q.l <= 0);
    if (parts.length > 400) parts.removeRange(0, parts.length - 400);
  }
}
