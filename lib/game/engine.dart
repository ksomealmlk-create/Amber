import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'level.dart';

enum Phase { playing, dead, won }

class Player extends Box {
  double vx = 0, vy = 0, anim = 0, sq = 0;
  double lN = 0, lF = 0, aN = 0, aF = 0, lean = 0, bob = 0;
  int f = 1, coy = 0, atk = 0, dash = 0, dcd = 0, hp = 5, inv = 0, jb = 0, spr = 0;
  bool g = true, pj = false, pa = false, pd = false;
  Player() : super(30, 418, 14, 22);
}

class Enemy extends Box {
  double minX, maxX, ph, baseY, jy = 0, jv = 0;
  int d = 1, hp = 2, hit = 0, kb = 0, kind, hopT = 60;
  bool get flying => kind == 1;
  Enemy(double x, double y, this.minX, this.maxX, this.kind, this.ph)
      : baseY = y,
        super(x, y, kind == 2 ? 20 : 18, 12);
}

class Part {
  double x, y, vx, vy, size;
  int l, max, a0;
  Color c;
  bool add;
  Part(this.x, this.y, this.vx, this.vy, this.l, this.c, this.size, this.add, [this.a0 = 255]) : max = l;
}

class Ember {
  final double x, y;
  bool taken = false;
  Ember(this.x, this.y);
}

class Chest {
  final double x, y;
  bool open = false;
  int anim = 0;
  Chest(this.x, this.y);
}

class MovPlat extends Box {
  final double ox, oy, ax, ay, sp, ph;
  double dx = 0, dy = 0;
  MovPlat(MovSpec s)
      : ox = s.x,
        oy = s.y,
        ax = s.ax,
        ay = s.ay,
        sp = s.sp,
        ph = s.ph,
        super(s.x, s.y, s.w, 14);
}

class Crumble extends Box {
  int timer = -1, respawn = 0;
  bool active = true;
  Crumble(CrumbleSpec s) : super(s.x, s.y, s.w, 14);
}

class Haz extends Box {
  final int kind;
  Haz(double x, double y, double w, double h, this.kind) : super(x, y, w, h);
}

class Brk extends Box {
  final int kind;
  final bool drop;
  int hp, hit = 0;
  bool alive = true;
  Brk(BreakSpec s)
      : kind = s.kind,
        drop = s.drop,
        hp = (s.kind == 2 || s.kind == 4) ? 3 : (s.kind == 3 ? 2 : 1),
        super(s.x, s.y, s.w, s.h);
}

class TimedHaz extends Box {
  final TimedSpec s;
  bool on = false, warn = false;
  TimedHaz(TimedSpec spec)
      : s = spec,
        super(spec.x, spec.y, spec.w, spec.h);
}

class Faller {
  final FallSpec s;
  int st = 0, tm;
  double y = -30, vy = 0;
  Faller(FallSpec spec)
      : s = spec,
        tm = spec.phase.toInt();
}

class Roller {
  final RollSpec s;
  double x;
  bool active = false;
  int tm;
  Roller(RollSpec spec)
      : s = spec,
        x = spec.x1,
        tm = spec.phase.toInt();
}

class SpringPad extends Box {
  int anim = 0;
  SpringPad(SpringSpec s) : super(s.x, s.y, 26, 12);
}

class KeyDoorO {
  final KeyDoorSpec s;
  final Box door;
  bool taken = false, open = false;
  int anim = 0;
  KeyDoorO(KeyDoorSpec spec)
      : s = spec,
        door = Box(spec.dx, kFloorY - 110, 22, 110);
}

class VanishP extends Box {
  final VanishSpec s;
  bool solid = true, warn = false;
  VanishP(VanishSpec spec)
      : s = spec,
        super(spec.x, spec.y, spec.w, 14);
}

class Ambush {
  final AmbushSpec s;
  bool fired = false;
  int anim = 0;
  Ambush(this.s);
}

class Proj {
  double x, y, vx, vy;
  int l, kind; // 0 شبكة، 1 موجة أرضية
  Proj(this.x, this.y, this.vx, this.vy, this.l, this.kind);
}

class Boss extends Box {
  double hp, maxHp, vx = 0, vy = 0;
  String name;
  int kind;
  String st = 'sleep';
  int t = 0, hit = 0, stun = 0, cd = 90, dead = 0, dir = -1;
  bool enraged = false;
  Boss(double x, double y, this.hp, this.name, this.kind)
      : maxHp = hp,
        super(x, y, 96, 56);
}

class GameEngine extends ChangeNotifier {
  final ValueNotifier<int> frame = ValueNotifier<int>(0);
  final math.Random rng = math.Random();

  late LevelConfig cfg;
  Phase phase = Phase.playing;
  bool paused = false;
  bool left = false, right = false, jump = false, dash = false, atk = false;

  // ترقيات
  int maxHp = 5, dashCd = 40, hammerDmg = 2;

  late Player p;
  List<Enemy> en = [];
  List<Ember> embers = [];
  List<Chest> chests = [];
  List<MovPlat> movs = [];
  List<Crumble> crums = [];
  List<Haz> haz = [];
  List<Brk> brks = [];
  List<TimedHaz> timedH = [];
  List<Faller> fallers = [];
  List<Roller> rollers = [];
  List<SpringPad> springsL = [];
  List<KeyDoorO> kdoors = [];
  List<VanishP> vplats = [];
  List<Ambush> ambushes = [];
  int deaths = 0;
  int get stars {
    final tot = totalEmbers;
    final f = tot == 0 ? 1.0 : collected / tot;
    int st = 1;
    if (f >= .7) st = 2;
    if (f >= .9 && deaths == 0) st = 3;
    return st;
  }

  List<Part> parts = [];
  List<Proj> projs = [];
  final List<Box> _live = [];
  Boss? boss;
  bool goalOpen = true, bossHitFlag = false;
  double cam = 0, vw = kW;
  int t = 0, shake = 0, cp = 30, deadT = 0, playFrames = 0, kills = 0, collected = 0, flash = 0;
  int bossIntro = 0, atkBuf = 0, dashBuf = 0;

  double _acc = 0, _last = 0;

  GameEngine() {
    loadLevel(LevelFactory.build(1, 1));
  }

  int get totalEmbers => cfg.totalEmbers;

  void loadLevel(LevelConfig c, {int hearts = 5, int dashCooldown = 40, int hammer = 2}) {
    cfg = c;
    _acc = 0;
    _last = 0;
    left = right = jump = dash = atk = false;
    maxHp = hearts;
    dashCd = dashCooldown;
    hammerDmg = hammer;
    cp = 30;
    deaths = 0;
    reset(true);
    phase = Phase.playing;
    paused = false;
    notifyListeners();
  }

  void reset(bool full) {
    p = Player()..x = cp.toDouble();
    p.hp = maxHp;
    if (full) {
      cp = 30;
      p.x = 30;
      en = cfg.enemies.map((a) {
        final y = (a.y ?? kFloorY) - 12;
        return Enemy(a.x, y, a.min, a.max, a.kind, rng.nextDouble() * 6);
      }).toList();
      embers = cfg.embers.map((a) => Ember(a[0], a[1])).toList();
      chests = cfg.chests.map((a) => Chest(a.x, a.y)).toList();
      movs = cfg.movs.map((a) => MovPlat(a)).toList();
      crums = cfg.crumbs.map((a) => Crumble(a)).toList();
      haz = cfg.hazards.map((a) => Haz(a.x, a.y, a.w, a.h, a.kind)).toList();
      brks = cfg.breaks.map((a) => Brk(a)).toList();
      timedH = cfg.timed.map((a) => TimedHaz(a)).toList();
      fallers = cfg.falls.map((a) => Faller(a)).toList();
      rollers = cfg.rolls.map((a) => Roller(a)).toList();
      springsL = cfg.springs.map((a) => SpringPad(a)).toList();
      kdoors = cfg.keyDoors.map((a) => KeyDoorO(a)).toList();
      vplats = cfg.vanish.map((a) => VanishP(a)).toList();
      ambushes = cfg.ambush.map((a) => Ambush(a)).toList();
      projs = [];
      parts = [];
      final b = cfg.boss;
      boss = b == null ? null : (Boss(b.x, kFloorY - 56, b.hp, b.name, b.kind));
      goalOpen = b == null;
      bossHitFlag = false;
      bossIntro = 0;
      kills = 0;
      collected = 0;
      playFrames = 0;
      cam = 0;
    }
  }

  void restart() {
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
    // عند بدء مرحلة جديدة يبدأ Ticker جديد من الصفر، فيصير dt سالباً ويجمّد اللعبة
    if (dt < 0) dt = 0;
    if (dt > 50) dt = 50;
    if (_acc < 0) _acc = 0;
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
      cam += ((cfg.goalX - vw / 2 - cam)) * 0.03;
      if (t % 3 == 0) {
        _spark(cfg.goalX + (rng.nextDouble() - .5) * 40, cfg.goalY + 20 + (rng.nextDouble() - .5) * 80, 1, const Color(0xFFE6C8FF), add: true);
      }
      return;
    }
    playFrames++;
    _updateWorld();
    _updatePlayer();
    if (boss != null) _updateBoss();
    _updateProjs();
  }

  // ---------- العناصر المتحركة
  bool _onTop(Box b) => (p.y + p.h - b.y).abs() < 2.6 && p.x + p.w > b.x + 1 && p.x < b.x + b.w - 1;

  void _updateWorld() {
    for (final m in movs) {
      final standing = p.g && _onTop(m);
      final nx = m.ox + math.sin(t * m.sp + m.ph) * m.ax;
      final ny = m.oy + math.sin(t * m.sp * 1.3 + m.ph) * m.ay;
      m.dx = nx - m.x;
      m.dy = ny - m.y;
      m.x = nx;
      m.y = ny;
      if (standing) {
        p.x += m.dx;
        p.y += m.dy;
      }
    }
    for (final c in crums) {
      if (c.active) {
        if (c.timer >= 0) {
          c.timer--;
          if (c.timer == 0) {
            c.active = false;
            c.respawn = 260;
            _debris(c);
          }
        }
      } else {
        c.respawn--;
        if (c.respawn <= 0) {
          c.active = true;
          c.timer = -1;
        }
      }
    }
    _updateGadgets();
    _live
      ..clear()
      ..addAll(cfg.solids)
      ..addAll(movs);
    for (final c in crums) {
      if (c.active) _live.add(c);
    }
    for (final b in brks) {
      if (b.alive) _live.add(b);
    }
    for (final k in kdoors) {
      if (!k.open) _live.add(k.door);
    }
    for (final v in vplats) {
      if (v.solid) _live.add(v);
    }
    for (final c in chests) {
      if (c.open && c.anim < 30) c.anim++;
    }
  }

  // ---------- العناصر التفاعلية الجديدة
  bool _onSlip() {
    final cx = p.x + 7;
    for (final z in cfg.slips) {
      if (cx > z.x && cx < z.x + z.w) return true;
    }
    return false;
  }

  Color _brkCol(int k) {
    switch (k) {
      case 1:
        return const Color(0xFF7A4E2A);
      case 2:
        return const Color(0xFF8A8E9A);
      case 3:
        return const Color(0xFF7FE6FF);
      case 4:
        return const Color(0xFF6A6F7A);
      default:
        return const Color(0xFFA06A34);
    }
  }

  void _breakFx(Brk b) {
    final col = _brkCol(b.kind);
    for (int i = 0; i < 16; i++) {
      parts.add(Part(b.x + rng.nextDouble() * b.w, b.y + rng.nextDouble() * b.h, (rng.nextDouble() - .5) * 3.2, -rng.nextDouble() * 2.6, 34, col, 2 + rng.nextDouble() * 2, true, 230));
    }
    _dust(b.x + b.w / 2, b.y + b.h, 8);
    shake = 5;
    HapticFeedback.mediumImpact();
  }

  void _hitBreakables(Box ab) {
    for (final b in brks) {
      if (!b.alive || !ab.hits(b)) continue;
      b.hp--;
      b.hit = 8;
      _spark(b.x + b.w / 2, b.y + b.h / 2, 6, _brkCol(b.kind), add: true);
      if (b.hp <= 0) {
        b.alive = false;
        _breakFx(b);
        if (b.drop) {
          collected++;
          flash = 5;
          _spark(b.x + b.w / 2, b.y, 12, const Color(0xFFFFD98A), add: true);
        }
      }
    }
  }

  void _updateGadgets() {
    if (phase != Phase.playing) return;
    final px = p.x + 7;
    for (final b in brks) {
      if (b.hit > 0) b.hit--;
    }
    // فخاخ زمنية
    for (final h in timedH) {
      final s = h.s;
      if (s.kind == 6) {
        h.on = true;
        h.warn = false;
        h.x = s.x + (math.sin(t * 0.045 + s.phase) + 1) / 2 * (s.w - 16);
        h.w = 16;
      } else {
        final m = (t + s.phase) % s.period;
        h.on = m < s.on;
        h.warn = !h.on && m > s.period - 26;
        if (h.on && m < 2 && (px - h.x).abs() < 300) {
          _spark(h.x + h.w / 2, h.y + h.h, 4, const Color(0xFFFFE27A), add: true);
        }
      }
      if (h.on && p.hits(h)) {
        if (_hurt(h.x + h.w / 2)) return;
      }
    }
    // أجسام ساقطة
    for (final f in fallers) {
      final fx = f.s.x;
      if (f.st == 0) {
        if ((px - fx).abs() < 340) {
          f.tm++;
          if (f.tm >= f.s.period) {
            f.st = 1;
            f.tm = 0;
          }
        }
      } else if (f.st == 1) {
        f.tm++;
        if (f.tm >= 36) {
          f.st = 2;
          f.y = -20;
          f.vy = 0;
        }
      } else if (f.st == 2) {
        f.vy = math.min(8.0, f.vy + .35);
        f.y += f.vy;
        if (p.hits(Box(fx - 9, f.y - 9, 18, 18))) {
          f.st = 3;
          f.tm = 0;
          _spark(fx, f.y, 10, const Color(0xFFCCCCCC), add: true);
          if (_hurt(fx)) return;
        } else if (f.y >= kFloorY - 9) {
          f.st = 3;
          f.tm = 0;
          shake = 3;
          _spark(fx, kFloorY - 8, 12, const Color(0xFFBBBBBB), add: true);
          _dust(fx, kFloorY, 6);
        }
      } else {
        f.tm++;
        if (f.tm > 20) {
          f.st = 0;
          f.tm = 0;
        }
      }
    }
    // أجسام متدحرجة
    for (final r in rollers) {
      if (!r.active) {
        if (px > r.s.x0 - 120 && px < r.s.x1 - 260) {
          r.tm++;
          if (r.tm >= r.s.period) {
            r.active = true;
            r.x = r.s.x1;
            r.tm = 0;
          }
        }
      } else {
        r.x -= r.s.kind == 1 ? 2.8 : (r.s.kind == 2 ? 3.1 : 2.3);
        if (p.hits(Box(r.x - 12, kFloorY - 24, 24, 24))) {
          if (_hurt(r.x)) return;
        }
        if (t % 5 == 0) _dust(r.x + 8, kFloorY, 1);
        if (r.x < r.s.x0) {
          r.active = false;
          r.tm = 0;
        }
      }
    }
    // نوابض
    for (final s in springsL) {
      if (s.anim > 0) s.anim--;
    }
    // مفاتيح وأبواب
    for (final k in kdoors) {
      if (!k.taken && (px - k.s.kx).abs() < 20 && ((p.y + 11) - k.s.ky).abs() < 28) {
        k.taken = true;
        collected += 2;
        _spark(k.s.kx, k.s.ky, 20, const Color(0xFFFFE27A), add: true);
        flash = 6;
        HapticFeedback.heavyImpact();
      }
      if (k.taken && !k.open && (px - (k.door.x + 11)).abs() < 46) {
        k.open = true;
        k.anim = 0;
        shake = 7;
        _spark(k.door.x + 11, k.door.y + 50, 24, const Color(0xFFFFE27A), add: true);
        HapticFeedback.heavyImpact();
      }
      if (k.open && k.anim < 40) k.anim++;
    }
    // منصات تختفي
    for (final v in vplats) {
      if (v.s.period > 0) {
        final m = (t + v.s.phase) % v.s.period;
        v.solid = m < v.s.period * .68;
        v.warn = v.solid && m > v.s.period * .68 - 24;
      } else {
        v.solid = true;
      }
    }
    // كمائن
    for (final a in ambushes) {
      if (!a.fired && px > a.s.x - 130 && px < a.s.x + 60) {
        a.fired = true;
        if (a.s.kind == 4) {
          en.add(Enemy(a.s.x, kFloorY - 80, a.s.x - 60, a.s.x + 60, 4, rng.nextDouble() * 6));
        } else {
          en.add(Enemy(a.s.x, kFloorY - 12, a.s.x - 90, a.s.x + 90, 0, 0));
        }
        shake = 5;
        _spark(a.s.x, kFloorY - 10, 20, const Color(0xFFB8A8FF), add: true);
      }
      if (a.fired) a.anim++;
    }
  }

  void _debris(Box c) {
    for (int i = 0; i < 8; i++) {
      parts.add(Part(c.x + rng.nextDouble() * c.w, c.y + 4, (rng.nextDouble() - .5) * 1.2, rng.nextDouble() * 1.5, 30, const Color(0xFF6B4A2A), 2.2, false));
    }
  }

  // ---------- اللاعب
  bool _hurt(double fromX) {
    if (p.inv > 0) return false;
    p.hp--;
    p.inv = 70;
    p.vy = -5;
    p.vx = (p.x < fromX ? -1 : 1) * 4.0;
    shake = 7;
    _spark(p.x + 7, p.y + 11, 12, const Color(0xFFFF6666));
    HapticFeedback.mediumImpact();
    if (p.hp <= 0) {
      _die();
      return true;
    }
    return false;
  }

  void _updatePlayer() {
    final L = left, R = right;
    if (p.inv > 0) p.inv--;
    if (p.spr > 0) p.spr--;
    if (p.dcd > 0) p.dcd--;
    if (jump && !p.pj) p.jb = 10;
    p.pj = jump;
    if (p.jb > 0) p.jb--;
    if (atk && !p.pa) atkBuf = 10;
    if (atkBuf > 0) {
      atkBuf--;
      if (p.atk <= 0) {
        p.atk = 26;
        atkBuf = 0;
        bossHitFlag = false;
        for (final e in en) {
          e.hit = 0;
        }
      }
    }
    p.pa = atk;
    if (dash && !p.pd) dashBuf = 8;
    if (dashBuf > 0) {
      dashBuf--;
      if (p.dcd <= 0 && p.dash <= 0) {
        p.dash = 10;
        p.dcd = dashCd;
        p.vy = 0;
        dashBuf = 0;
      }
    }
    p.pd = dash;
    if (p.dash > 0) {
      p.dash--;
      p.vx = p.f * 8.0;
      p.vy = 0;
      if (t % 2 == 0) _spark(p.x + 7, p.y + 11, 1, const Color(0xFF66AADD), add: true);
    } else {
      final slip = p.g && _onSlip();
      final a = p.g ? (slip ? .32 : .95) : .62;
      if (L && !R) {
        p.vx -= a;
        p.f = -1;
      } else if (R && !L) {
        p.vx += a;
        p.f = 1;
      } else {
        p.vx *= p.g ? (slip ? .975 : .7) : .93;
      }
      p.vx = math.max(-3.0, math.min(3.0, p.vx));
      p.vy += .5;
      if (p.vy > 11) p.vy = 11;
    }
    if (p.g) {
      p.coy = 8;
    } else if (p.coy > 0) {
      p.coy--;
    }
    if (p.jb > 0 && p.coy > 0) {
      p.vy = -9.5;
      p.coy = 0;
      p.jb = 0;
      p.g = false;
      p.sq = -0.25;
      _dust(p.x + 7, p.y + 22, 6);
    }
    if (!jump && p.vy < -3.5 && p.dash <= 0 && p.spr <= 0) p.vy = -3.5;

    final wasG = p.g;
    final preVy = p.vy;
    _moveX(p, p.vx);
    p.g = _moveY(p, p.vy);
    for (final sp in springsL) {
      if (p.vy >= 0 && p.hits(Box(sp.x, sp.y - 2, sp.w, 14)) && p.y + p.h <= sp.y + 12) {
        p.vy = -13.5;
        p.g = false;
        p.coy = 0;
        p.spr = 22;
        sp.anim = 14;
        p.sq = -0.3;
        _spark(sp.x + 13, sp.y, 12, const Color(0xFFE6B8FF), add: true);
        HapticFeedback.lightImpact();
      }
    }
    if (p.g && !wasG && preVy > 3) {
      p.sq = 0.3;
      _dust(p.x + 7, p.y + 22, 8);
    }
    p.sq *= 0.8;
    if (p.g && p.vx.abs() > 0.5) {
      p.anim += p.vx.abs() * 0.12;
      if (t % 9 == 0) _dust(p.x + 7, p.y + 22, 1);
    }
    if (p.g) {
      for (final c in crums) {
        if (c.active && c.timer < 0 && _onTop(c)) c.timer = 28;
      }
    }

    for (final s in cfg.grounds) {
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

    // ضربة المطرقة
    final ab = Box(p.f > 0 ? p.x + p.w : p.x - 36, p.y - 8, 36, 36);
    for (final e in en) {
      if (e.hp <= 0) continue;
      _moveEnemy(e);
      if (p.atk > 8 && p.atk < 17 && e.hit == 0 && ab.hits(e)) {
        e.hit = 1;
        e.hp -= hammerDmg;
        e.kb = 8;
        _spark(e.x + 9, e.y + 6, 10, const Color(0xFFFFB347), add: true);
        shake = 4;
        HapticFeedback.lightImpact();
        if (e.hp <= 0) {
          kills++;
          _spark(e.x + 9, e.y + 6, 26, const Color(0xFFFFD27A), add: true);
        }
      }
      if (e.hp > 0 && p.hits(e)) {
        if (_hurt(e.x + 9)) return;
      }
    }
    for (final h in haz) {
      if (p.hits(h)) {
        if (_hurt(h.x + h.w / 2)) return;
      }
    }
    final b = boss;
    if (b != null && b.st != 'sleep' && b.st != 'intro' && b.st != 'dead') {
      if (p.atk > 8 && p.atk < 17 && !bossHitFlag && ab.hits(b)) {
        bossHitFlag = true;
        final dmg = hammerDmg * (b.st == 'stun' ? 2 : 1);
        b.hp -= dmg;
        b.hit = 10;
        _spark(b.x + b.w / 2, b.y + 20, 14, b.st == 'stun' ? const Color(0xFFFFE27A) : const Color(0xFFFFB347), add: true);
        shake = 6;
        HapticFeedback.mediumImpact();
        if (b.hp <= 0) {
          b.hp = 0;
          b.st = 'dead';
          b.dead = 0;
          shake = 16;
          projs.clear();
          kills++;
        }
      }
      if (b.st != 'stun' && b.st != 'dead' && p.hits(b)) {
        if (_hurt(b.x + b.w / 2)) return;
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
        if (collected % 6 == 0 && p.hp < maxHp) p.hp++;
      }
    }
    for (final c in chests) {
      if (!c.open && p.hits(Box(c.x - 2, c.y - 2, 22, 18))) {
        c.open = true;
        collected += 3;
        if (p.hp < maxHp) p.hp = math.min(maxHp, p.hp + 2);
        _spark(c.x + 8, c.y + 4, 30, const Color(0xFFFFD27A), add: true);
        shake = 4;
        HapticFeedback.heavyImpact();
      }
    }

    if (goalOpen && (p.x - cfg.goalX).abs() < 30 && (p.y - cfg.goalY).abs() < 70) {
      phase = Phase.won;
      _spark(cfg.goalX, cfg.goalY + 20, 50, const Color(0xFFE6C8FF), add: true);
      HapticFeedback.heavyImpact();
      notifyListeners();
    }
    if (p.atk == 12) {
      _hitBreakables(ab);
      _spark(p.x + 7 + p.f * 24, p.y + 18, 18, const Color(0xFFBDEFFF), add: true);
      shake = 5;
      HapticFeedback.lightImpact();
    }
    if (p.atk > 0) p.atk--;
    _animate();
    cam += ((math.max(0.0, math.min(cfg.length - vw, p.x - vw / 2 + p.f * 40))) - cam) * .14;
  }

  void _moveEnemy(Enemy e) {
    if (e.flying) e.y = e.baseY + math.sin(t / 25 + e.ph) * 10;
    if (e.kb > 0) {
      e.kb--;
      e.x += (p.x < e.x ? 1 : -1) * 2.5;
      return;
    }
    if (e.kind == 4) {
      final dx = (p.x + 7) - (e.x + 9);
      if (dx.abs() < 240) {
        e.x += (dx > 0 ? 1 : -1) * 0.8;
        e.d = dx > 0 ? 1 : -1;
        e.baseY += ((p.y - 6) - e.baseY) * 0.012;
        if (e.baseY < 300) e.baseY = 300;
        if (e.baseY > 410) e.baseY = 410;
      }
      e.x = math.max(10.0, math.min(cfg.length - 30, e.x));
      e.y = e.baseY + math.sin(t / 20 + e.ph) * 12;
      return;
    }
    if (e.kind == 3) {
      final dx = (p.x + 7) - (e.x + 9);
      e.d = dx > 0 ? 1 : -1;
      e.hopT--;
      if (e.hopT <= 0 && dx.abs() < 300 && dx.abs() > 30) {
        projs.add(Proj(e.x + 9, e.y + 6, e.d * 2.6, 0, 150, 2));
        e.hopT = 105;
        _spark(e.x + 9 + e.d * 8, e.y + 6, 5, const Color(0xFFFFB347), add: true);
      }
      return;
    }
    final sp = e.kind == 1 ? 0.9 : (e.kind == 2 ? 0.95 : 0.7);
    e.x += e.d * sp;
    if (e.x < e.minX) e.d = 1;
    if (e.x + e.w > e.maxX) e.d = -1;
    if (e.kind == 2) {
      e.hopT--;
      if (e.hopT <= 0 && e.jy == 0 && (p.x - e.x).abs() < 190) {
        e.jv = -5.5;
        e.hopT = 80 + rng.nextInt(50);
        e.d = p.x < e.x ? -1 : 1;
      }
      if (e.jv != 0 || e.jy != 0) {
        e.jy += e.jv;
        e.jv += 0.42;
        if (e.jy >= 0) {
          e.jy = 0;
          e.jv = 0;
        }
      }
      e.y = e.baseY + e.jy;
    }
  }

  // ---------- الزعيم
  void _updateBoss() {
    final b = boss!;
    b.t++;
    if (b.hit > 0) b.hit--;
    if (b.st == 'sleep') {
      if (p.x > cfg.boss!.trigger) {
        b.st = 'intro';
        b.t = 0;
        shake = 20;
        HapticFeedback.heavyImpact();
      }
      return;
    }
    if (b.st == 'dead') {
      b.dead++;
      if (b.dead % 4 == 0) {
        _spark(b.x + rng.nextDouble() * b.w, b.y + rng.nextDouble() * b.h, 6, const Color(0xFFFFB347), add: true);
      }
      if (b.dead == 140) {
        goalOpen = true;
        collected += 8;
        p.hp = maxHp;
        _spark(b.x + b.w / 2, b.y + 20, 60, const Color(0xFFFFE27A), add: true);
        shake = 12;
        HapticFeedback.heavyImpact();
      }
      return;
    }
    if (b.hp <= b.maxHp * 0.4 && !b.enraged) {
      b.enraged = true;
      shake = 14;
      _spark(b.x + b.w / 2, b.y + 20, 40, const Color(0xFFFF4A3A), add: true);
    }
    final sp = b.enraged ? 1.35 : 1.0;
    bool landed = false;
    b.vy += .5;
    b.y += b.vy;
    if (b.y + b.h >= kFloorY) {
      b.y = kFloorY - b.h;
      if (b.vy > 2) landed = true;
      b.vy = 0;
    }
    final px = p.x + 7;
    switch (b.st) {
      case 'intro':
        if (b.t > 70) {
          b.st = 'idle';
          b.t = 0;
          b.cd = 50;
        }
        break;
      case 'idle':
        b.dir = px < b.x + b.w / 2 ? -1 : 1;
        b.x += b.dir * 0.7 * sp;
        b.x = math.max(4.0, math.min(cfg.length - 14 - b.w, b.x));
        b.cd--;
        if (b.cd <= 0) {
          final pl = _pool(b.kind);
          b.st = pl[rng.nextInt(pl.length)];
          b.t = 0;
        }
        break;
      case 'web':
        if (b.t == 28) {
          final n = b.enraged ? 5 : 3;
          final ox = b.x + b.w / 2, oy = b.y + 12;
          final base = math.atan2((p.y + 11) - oy, px - ox);
          for (int i = 0; i < n; i++) {
            final a = base + (i - (n - 1) / 2) * 0.22;
            projs.add(Proj(ox, oy, math.cos(a) * 3.2 * sp, math.sin(a) * 3.2 * sp, 200, 0));
          }
          shake = 3;
        }
        if (b.t > 56) {
          if (b.kind != 0) {
            b.st = 'stun';
            b.t = 0;
            b.stun = 36;
          } else {
            b.st = 'idle';
            b.cd = b.enraged ? 45 : 75;
          }
        }
        break;
      case 'rain':
        if (b.t % (b.enraged ? 8 : 12) == 0 && b.t < 100) {
          final tx = cl(px + (rng.nextDouble() - .5) * 240, 20.0, cfg.length - 20.0);
          projs.add(Proj(tx, -10, 0, 3.4 * sp, 220, 2));
        }
        if (b.t > 120) {
          b.st = 'stun';
          b.t = 0;
          b.stun = 40;
        }
        break;
      case 'ring':
        if (b.t == 30) {
          final n = b.enraged ? 12 : 8;
          for (int i = 0; i < n; i++) {
            final a = i * 2 * math.pi / n;
            projs.add(Proj(b.x + b.w / 2, b.y + 40, math.cos(a) * 2.4 * sp, math.sin(a) * 2.4 * sp, 150, 2));
          }
          shake = 4;
        }
        if (b.t > 52) {
          b.st = 'stun';
          b.t = 0;
          b.stun = 40;
        }
        break;
      case 'charge':
        if (b.t == 1) b.dir = px < b.x + b.w / 2 ? -1 : 1;
        if (b.t >= 32) {
          b.x += b.dir * (b.enraged ? 8.0 : 6.0);
          if (b.x <= 4 || b.x + b.w >= cfg.length - 14) {
            b.x = math.max(4.0, math.min(cfg.length - 14 - b.w, b.x));
            b.st = 'stun';
            b.t = 0;
            b.stun = 110;
            shake = 12;
            _spark(b.x + b.w / 2, b.y + 20, 20, const Color(0xFFFFE27A), add: true);
            HapticFeedback.heavyImpact();
          }
        }
        break;
      case 'slam':
        if (b.t == 1) {
          b.vy = -12.5;
          final dx = px - (b.x + b.w / 2);
          b.vx = math.max(-6.0, math.min(6.0, dx / 32));
        }
        if (b.t > 1) {
          b.x += b.vx;
          b.x = math.max(4.0, math.min(cfg.length - 14 - b.w, b.x));
        }
        if (landed && b.t > 8) {
          shake = 12;
          HapticFeedback.heavyImpact();
          final s2 = b.enraged ? 4.2 : 3.4;
          projs.add(Proj(b.x + b.w / 2, kFloorY - 14, -s2, 0, 160, 1));
          projs.add(Proj(b.x + b.w / 2, kFloorY - 14, s2, 0, 160, 1));
          if (en.where((e) => e.hp > 0).length < 4) {
            for (int i = 0; i < 2; i++) {
              final sx = b.x + (i == 0 ? -20 : b.w + 6);
              final nx = math.max(20.0, math.min(cfg.length - 40, sx));
              final mk = b.kind == 0 ? 2 : ((b.kind == 7 || b.kind == 10) ? 4 : 0);
              final e = Enemy(nx, kFloorY - 12, math.max(10.0, nx - 160), math.min(cfg.length - 20, nx + 160), mk, rng.nextDouble() * 6);
              e.hp = 1;
              en.add(e);
            }
          }
          b.st = 'stun';
          b.t = 0;
          b.stun = 50;
        }
        break;
      case 'stun':
        b.stun--;
        if (b.stun <= 0) {
          b.st = 'idle';
          b.cd = 40;
        }
        break;
    }
  }

  List<String> _pool(int k) {
    switch (k) {
      case 0:
        return const ['web', 'charge', 'slam'];
      case 1:
        return const ['charge', 'slam', 'rain'];
      case 3:
        return const ['ring', 'slam', 'rain'];
      case 4:
        return const ['charge', 'web', 'slam'];
      case 5:
        return const ['rain', 'web', 'charge'];
      case 6:
        return const ['slam', 'rain', 'ring'];
      case 7:
        return const ['web', 'ring', 'charge'];
      case 8:
        return const ['charge', 'slam', 'web'];
      case 9:
        return const ['ring', 'rain', 'slam'];
      case 10:
        return const ['web', 'charge', 'rain', 'ring'];
      default:
        return const ['web', 'charge', 'slam', 'rain', 'ring'];
    }
  }

  void _updateProjs() {
    for (final q in projs) {
      q.x += q.vx;
      q.y += q.vy;
      q.l--;
      final bx = Box(q.x - 4, q.y - 4, 8, q.kind == 1 ? 14 : 8);
      if (p.hits(bx) && q.l > 0) {
        q.l = 0;
        _hurt(q.x);
      }
      if (q.kind != 1 && q.y > kFloorY - 2) q.l = 0;
      if (q.kind == 2 && q.l > 0) {
        final pb = Box(q.x - 3, q.y - 3, 6, 6);
        for (final sd in _live) {
          if (pb.hits(sd)) {
            q.l = 0;
            _spark(q.x, q.y, 5, const Color(0xFFFFB347), add: true);
            break;
          }
        }
      }
    }
    projs.removeWhere((q) => q.l <= 0 || q.x < -20 || q.x > cfg.length + 20);
    if (phase == Phase.dead) projs.clear();
  }

  // ---------- حركة الأطراف
  void _animate() {
    double lN = 0, lF = 0, aN = 0, aF = 0, lean = 0, bob = 0;
    final sp = math.min(1.0, p.vx.abs() / 3.0);
    final ph = p.anim * 1.0;
    if (p.dash > 0) {
      lN = -0.75; lF = 0.7; aN = 1.2; aF = 1.0; lean = 0.3;
    } else if (!p.g) {
      if (p.vy < 0) {
        lN = -0.6; lF = 0.4; aN = -1.1; aF = -0.8;
      } else {
        lN = -0.2; lF = 0.3; aN = -0.7; aF = -0.4;
      }
      lean = 0.05;
    } else if (p.vx.abs() > 0.5) {
      final sn = math.sin(ph);
      final amp = 0.35 + 0.35 * sp;
      final a2 = 0.5 + 0.3 * sp;
      lN = -amp * sn; lF = amp * sn;
      aN = a2 * sn; aF = -a2 * sn;
      bob = -math.sin(ph).abs() * 0.9;
      lean = 0.07 * sp;
    } else {
      final br = math.sin(t / 25.0);
      aN = 0.08 * br; aF = -0.08 * br;
      bob = br * 0.25;
    }
    double kn = 0.3;
    if (p.atk > 0) {
      kn = 0.5;
      if (p.atk > 16) {
        aN = -3.2; aF = -1.2; lean = -0.12;
      } else if (p.atk > 8) {
        aN = -0.9; aF = 0.5; lean = 0.25;
      } else {
        aN = -0.3; lean = 0.1;
      }
    }
    const k = 0.3;
    p.lN += (lN - p.lN) * k;
    p.lF += (lF - p.lF) * k;
    p.aN += (aN - p.aN) * kn;
    p.aF += (aF - p.aF) * k;
    p.lean += (lean - p.lean) * kn;
    p.bob += (bob - p.bob) * k;
  }

  void _die() {
    deaths++;
    phase = Phase.dead;
    deadT = 0;
    shake = 12;
    _spark(p.x + 7, p.y + 11, 40, const Color(0xFFFFB347), add: true);
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  // ---------- فيزياء
  void _moveX(Player o, double dx) {
    o.x += dx;
    for (final s in _live) {
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
    for (final s in _live) {
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

  // ---------- جسيمات
  void _spark(double x, double y, int n, Color c, {bool add = false}) {
    for (int i = 0; i < n; i++) {
      parts.add(Part(x, y, (rng.nextDouble() - .5) * 4, (rng.nextDouble() - .5) * 4, 25 + rng.nextInt(15), c, 1.5 + rng.nextDouble() * 2, add));
    }
  }

  void _dust(double x, double y, int n) {
    for (int i = 0; i < n; i++) {
      parts.add(Part(x + (rng.nextDouble() - .5) * 8, y, (rng.nextDouble() - .5) * 1.4, -rng.nextDouble() * .6, 22, const Color(0xFF9FB8D8), 1.5 + rng.nextDouble() * 1.5, false, 136));
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
