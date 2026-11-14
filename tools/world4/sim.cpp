// محاكي مطابق لفيزياء محرك Amber (engine.dart) + روبوت بحث (beam search) لاختبار إمكانية إكمال المراحل
#include <bits/stdc++.h>
using namespace std;
struct Box { double x, y, w, h; };
static inline bool hit(const Box& a, const Box& b) { return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y; }
static const double kH = 500, kFloorY = 440;
static const int DASHCD = 40;

struct Mov { double ox, oy, w, ax, ay, sp, ph; };
struct Crum { double x, y, w; };
struct Haz { Box b; int kind; };
struct ESpec { double x, mn, mx; int kind; double y; bool hasY; };
struct TSpec { int kind; double x, y, w, h, period, on, phase; };
struct FSpec { int kind; double x, period, phase; };
struct RSpec { int kind; double x0, x1, period, phase; };
struct KSpec { double kx, ky, dx, bottom; };
struct VSpec { double x, y, w, period, phase; bool hidden; };
struct BSpec { int kind; double x, y, w, h; bool drop; };
struct SSpec { double x, y, power; };
struct BuSpec { double x, y, ax, ay, sp, ph; };
struct WP { double x, y, r; };
struct Run { string name; double sx, sy; int t0; vector<WP> wps; vector<pair<int,int>> pre; };

struct Level {
  string name; double length = 0, goalX = 0, goalY = 370;
  vector<Box> solids; vector<Mov> movs; vector<Crum> crums; vector<Haz> haz; vector<ESpec> ens; vector<TSpec> tim;
  vector<FSpec> falls; vector<RSpec> rolls; vector<KSpec> keys; vector<VSpec> vans; vector<BSpec> brks;
  vector<SSpec> springs; vector<BuSpec> bubs;
  vector<Run> runs;
};

// ---------- الحالة
const int ME = 16, MC = 64, MF = 16, MR = 8, MB = 32, MK = 4, MP = 24, MBU = 12;
struct En { double x, y, baseY, mn, mx; int d, hp, hit, kb, kind, hopT; double w; };
struct Pr { double x, y, vx, vy; int l; };
struct Bu { bool alive; int respawn; };
struct Cr { int timer, respawn; bool active; };
struct Fa { int st, tm; double y, vy; };
struct Ro { double x; bool active; int tm; };
struct Bk { bool alive; int hp; };
struct Ky { bool taken, open; };
struct State {
  double x, y, vx, vy; int f, coy, atk, dash, dcd, inv, jb, hp; bool g, pj, pa, pd; int atkBuf, dashBuf;
  int t; int wpi;
  int ne, nc, nf, nr, nb, nk, np, nbu, spr;
  En en[ME]; Cr cr[MC]; Fa fa[MF]; Ro ro[MR]; Bk bk[MB]; Ky ky[MK]; Pr pr[MP]; Bu bu[MBU];
  int gt[8];
  int dmg; // عدد مرات الإصابة
  int parent; int act; // للتتبع
};

static Level LV;
static const double PW = 14, PH = 22;

static inline void movPos(const Mov& m, int t, double& x, double& y) {
  if (t <= 0) { x = m.ox; y = m.oy; return; }
  x = m.ox + sin(t * m.sp + m.ph) * m.ax;
  y = m.oy + sin(t * m.sp * 1.3 + m.ph) * m.ay;
}

static void initState(State& s, const Run& r) {
  memset(&s, 0, sizeof(s));
  s.x = r.sx; s.y = r.sy; s.f = 1; s.hp = 5; s.g = false; s.t = r.t0;
  s.ne = LV.ens.size(); s.nc = LV.crums.size(); s.nf = LV.falls.size(); s.nr = LV.rolls.size(); s.nb = LV.brks.size(); s.nk = LV.keys.size(); s.nbu = LV.bubs.size();
  for (int i = 0; i < s.ne; i++) {
    auto& a = LV.ens[i]; En& e = s.en[i];
    double yy = (a.hasY ? a.y : kFloorY) - 12;
    e.x = a.x; e.y = yy; e.baseY = yy; e.mn = a.mn; e.mx = a.mx; e.d = 1; e.hp = (a.kind == 2 ? 3 : 2); e.hit = 0; e.kb = 0; e.kind = a.kind; e.hopT = 60;
    e.w = a.kind == 2 ? 20 : 18;
  }
  for (int i = 0; i < s.nc; i++) { s.cr[i].timer = -1; s.cr[i].active = true; s.cr[i].respawn = 0; }
  for (int i = 0; i < s.nf; i++) { s.fa[i].st = 0; s.fa[i].tm = (int)LV.falls[i].phase; s.fa[i].y = -30; s.fa[i].vy = 0; }
  for (int i = 0; i < s.nr; i++) { s.ro[i].x = LV.rolls[i].x1; s.ro[i].active = false; s.ro[i].tm = (int)LV.rolls[i].phase; }
  for (int i = 0; i < s.nb; i++) { s.bk[i].alive = true; auto k = LV.brks[i].kind; s.bk[i].hp = (k == 2 || k == 4 || k == 5) ? 3 : (k == 3 ? 2 : 1); }
  for (int i = 0; i < s.nbu; i++) { s.bu[i].alive = true; s.bu[i].respawn = 0; }
  for (auto& pr : r.pre) if (pr.first < s.nk) { s.ky[pr.first].taken = true; s.ky[pr.first].open = pr.second; }
}

// قائمة المجسمات الحية
struct Live { Box b[200]; int n; };
static void buildLive(const State& s, Live& L) {
  L.n = 0;
  for (auto& b : LV.solids) L.b[L.n++] = b;
  for (auto& m : LV.movs) { double x, y; movPos(m, s.t, x, y); L.b[L.n++] = Box{x, y, m.w, 14}; }
  for (int i = 0; i < s.nc; i++) if (s.cr[i].active) L.b[L.n++] = Box{LV.crums[i].x, LV.crums[i].y, LV.crums[i].w, 14};
  for (int i = 0; i < s.nb; i++) if (s.bk[i].alive) L.b[L.n++] = Box{LV.brks[i].x, LV.brks[i].y, LV.brks[i].w, LV.brks[i].h};
  for (int i = 0; i < s.nk; i++) if (!s.ky[i].open) L.b[L.n++] = Box{LV.keys[i].dx, LV.keys[i].bottom - 110, 22, 110};
  for (auto& v : LV.vans) {
    bool solid = true;
    if (v.period > 0) { double m = fmod(s.t + v.phase, v.period); solid = m < v.period * .68; }
    if (solid) L.b[L.n++] = Box{v.x, v.y, v.w, 14};
  }
}

static inline bool onTop(const State& s, const Box& b) { return fabs(s.y + PH - b.y) < 2.6 && s.x + PW > b.x + 1 && s.x < b.x + b.w - 1; }

// يعيد true إذا حدثت إصابة
static bool stepOnce(State& s, bool L_, bool R_, bool jump, bool dashI, bool atkI) {
  bool damaged = false;
  s.t++;
  // ---- updateWorld: movers
  for (auto& m : LV.movs) {
    double ox, oy, nx, ny;
    movPos(m, s.t - 1, ox, oy); if (s.t - 1 <= 0) { ox = m.ox; oy = m.oy; }
    Box old{ox, oy, m.w, 14};
    bool standing = s.g && onTop(s, old);
    movPos(m, s.t, nx, ny);
    if (standing) { s.x += nx - ox; s.y += ny - oy; }
  }
  for (int i = 0; i < s.nc; i++) {
    Cr& c = s.cr[i];
    if (c.active) { if (c.timer >= 0) { c.timer--; if (c.timer == 0) { c.active = false; c.respawn = 260; } } }
    else { c.respawn--; if (c.respawn <= 0) { c.active = true; c.timer = -1; } }
  }
  double px = s.x + 7;
  // ---- gadgets
  Box pb{s.x, s.y, PW, PH};
  for (int i = 0; i < 8; i++) if (s.gt[i] > 0) s.gt[i]--;
  for (auto& h : LV.tim) {
    bool on;
    if (h.kind == 12) { int g = (int)h.period; if (s.g && hit(pb, Box{h.x, h.y, h.w, h.h}) && s.gt[g] <= 0) s.gt[g] = (int)(h.on + h.phase); continue; }
    if (h.kind == 13) { int tt = s.gt[(int)h.period]; if (tt > 0 && tt <= h.on && hit(pb, Box{h.x, h.y, h.w, h.h})) damaged = true; continue; }
    if (h.kind == 6 || h.kind == 11) {
      double w0 = h.kind == 11 ? s.t * 2 * M_PI / h.period : s.t * 0.045;
      on = true; double hx = h.x + (sin(w0 + h.phase) + 1) / 2 * (h.w - 16);
      Box hb{hx, h.y, 16, h.h}; if (hit(pb, hb)) damaged = true; continue;
    }
    double m = fmod(s.t + h.phase, h.period); on = m < h.on;
    if (on && hit(pb, Box{h.x, h.y, h.w, h.h})) damaged = true;
  }
  for (int i = 0; i < s.nf; i++) {
    Fa& f = s.fa[i]; const FSpec& sp = LV.falls[i]; double fx = sp.x;
    if (f.st == 0) { if (fabs(px - fx) < 340) { f.tm++; if (f.tm >= sp.period) { f.st = 1; f.tm = 0; } } }
    else if (f.st == 1) { f.tm++; if (f.tm >= 36) { f.st = 2; f.y = -20; f.vy = 0; } }
    else if (f.st == 2) {
      f.vy = min(8.0, f.vy + .35); f.y += f.vy;
      if (hit(pb, Box{fx - 9, f.y - 9, 18, 18})) { f.st = 3; f.tm = 0; damaged = true; }
      else if (f.y >= kFloorY - 9) { f.st = 3; f.tm = 0; }
    } else { f.tm++; if (f.tm > 20) { f.st = 0; f.tm = 0; } }
  }
  for (int i = 0; i < s.nr; i++) {
    Ro& r = s.ro[i]; const RSpec& sp = LV.rolls[i];
    if (!r.active) { if (px > sp.x0 - 120 && px < sp.x1 - 260) { r.tm++; if (r.tm >= sp.period) { r.active = true; r.x = sp.x1; r.tm = 0; } } }
    else {
      r.x -= sp.kind == 1 ? 2.8 : (sp.kind == 2 ? 3.1 : 2.3);
      if (hit(pb, Box{r.x - 12, kFloorY - 24, 24, 24})) damaged = true;
      if (r.x < sp.x0) { r.active = false; r.tm = 0; }
    }
  }
  for (int i = 0; i < s.nk; i++) {
    const KSpec& k = LV.keys[i]; Ky& y = s.ky[i];
    if (!y.taken && fabs(px - k.kx) < 20 && fabs((s.y + 11) - k.ky) < 28) y.taken = true;
    if (y.taken && !y.open && fabs(px - (k.dx + 11)) < 46) y.open = true;
  }
  for (int i = 0; i < s.nbu; i++) {
    Bu& b = s.bu[i]; const BuSpec& sp = LV.bubs[i];
    if (!b.alive) { b.respawn--; if (b.respawn <= 0) b.alive = true; continue; }
    double bx = sp.x + sin(s.t * sp.sp + sp.ph) * sp.ax, by = sp.y + sin(s.t * sp.sp * 1.3 + sp.ph) * sp.ay;
    if (hit(pb, Box{bx - 11, by - 11, 22, 22})) { b.alive = false; b.respawn = 300; damaged = true; }
  }
  Live live; buildLive(s, live);
  // ---- الحركة
  if (s.inv > 0) s.inv--;
  if (s.spr > 0) s.spr--;
  if (s.dcd > 0) s.dcd--;
  if (jump && !s.pj) s.jb = 10;
  s.pj = jump; if (s.jb > 0) s.jb--;
  if (atkI && !s.pa) s.atkBuf = 10;
  if (s.atkBuf > 0) { s.atkBuf--; if (s.atk <= 0) { s.atk = 26; s.atkBuf = 0; for (int i = 0; i < s.ne; i++) s.en[i].hit = 0; } }
  s.pa = atkI;
  if (dashI && !s.pd) s.dashBuf = 8;
  if (s.dashBuf > 0) { s.dashBuf--; if (s.dcd <= 0 && s.dash <= 0) { s.dash = 10; s.dcd = DASHCD; s.vy = 0; s.dashBuf = 0; } }
  s.pd = dashI;
  if (s.dash > 0) { s.dash--; s.vx = s.f * 8.0; s.vy = 0; }
  else {
    double a = s.g ? .95 : .62;
    if (L_ && !R_) { s.vx -= a; s.f = -1; } else if (R_ && !L_) { s.vx += a; s.f = 1; } else s.vx *= s.g ? .7 : .93;
    s.vx = max(-3.0, min(3.0, s.vx)); s.vy += .5; if (s.vy > 11) s.vy = 11;
  }
  if (s.g) s.coy = 8; else if (s.coy > 0) s.coy--;
  if (s.jb > 0 && s.coy > 0) { s.vy = -9.5; s.coy = 0; s.jb = 0; s.g = false; }
  if (!jump && s.vy < -3.5 && s.dash <= 0 && s.spr <= 0) s.vy = -3.5;
  // moveX
  s.x += s.vx;
  for (int i = 0; i < live.n; i++) { Box& b = live.b[i]; Box pbx{s.x, s.y, PW, PH}; if (hit(pbx, b)) { if (s.vx > 0) s.x = b.x - PW; else if (s.vx < 0) s.x = b.x + b.w; s.vx = 0; } }
  // moveY
  bool g = false; s.y += s.vy;
  for (int i = 0; i < live.n; i++) { Box& b = live.b[i]; Box pbx{s.x, s.y, PW, PH}; if (hit(pbx, b)) { if (s.vy > 0) { s.y = b.y - PH; g = true; } else if (s.vy < 0) { s.y = b.y + b.h; } s.vy = 0; } }
  s.g = g;
  for (auto& sp : LV.springs) {
    Box sb{sp.x, sp.y - 2, 26, 14};
    Box pq{s.x, s.y, PW, PH};
    if (s.vy >= 0 && hit(pq, sb) && s.y + PH <= sp.y + 12) { s.vy = -13.5 * sp.power; s.g = false; s.coy = 0; s.spr = 22; }
  }
  if (s.g) for (int i = 0; i < s.nc; i++) { if (s.cr[i].active && s.cr[i].timer < 0) { Box cb{LV.crums[i].x, LV.crums[i].y, LV.crums[i].w, 14}; if (onTop(s, cb)) s.cr[i].timer = 28; } }
  if (s.y > kH + 40) return true; // سقوط
  // ---- أعداء
  Box ab{s.f > 0 ? s.x + PW : s.x - 36, s.y - 8, 36, 36};
  Box pbx{s.x, s.y, PW, PH};
  for (int i = 0; i < s.ne; i++) {
    En& e = s.en[i]; if (e.hp <= 0) continue;
    // moveEnemy
    double ey = e.y;
    if (e.kind == 1) { /* طائر: نغطي مدى التذبذب */ }
    if (e.kb > 0) { e.kb--; e.x += (s.x < e.x ? 1 : -1) * 2.5; }
    else if (e.kind == 3) {
      double dx = (s.x + 7) - (e.x + 9); e.d = dx > 0 ? 1 : -1; e.hopT--;
      if (e.hopT <= 0 && fabs(dx) < 300 && fabs(dx) > 30) { if (s.np < MP) { s.pr[s.np++] = Pr{e.x + 9, e.y + 6, e.d * 2.6, 0, 150}; } e.hopT = 105; }
    } else if (e.kind == 5) {
      double dx = (s.x + 7) - (e.x + 9);
      bool chase = fabs(dx) < 230 && fabs(s.y - e.y) < 70;
      if (chase) e.d = dx > 0 ? 1 : -1;
      e.x += e.d * (chase ? 1.25 : 0.6);
      if (e.x < e.mn) { e.x = e.mn; e.d = 1; }
      if (e.x + e.w > e.mx) { e.x = e.mx - e.w; e.d = -1; }
    } else if (e.kind == 6) {
      e.x += e.d * 0.6; if (e.x < e.mn) e.d = 1; if (e.x + e.w > e.mx) e.d = -1;
      e.hopT--;
      double dx = (s.x + 7) - (e.x + 9), dy = (s.y + 11) - (e.baseY + 6);
      if (e.hopT <= 0 && fabs(dx) < 330 && fabs(dy) < 260) {
        double dd = sqrt(dx * dx + dy * dy);
        if (dd > 40 && s.np < MP) s.pr[s.np++] = Pr{e.x + 9, e.baseY + 6, dx / dd * 2.3, dy / dd * 2.3, 170};
        e.hopT = 150;
      }
    } else {
      double sp = e.kind == 1 ? 0.9 : (e.kind == 2 ? 0.95 : 0.7);
      e.x += e.d * sp; if (e.x < e.mn) e.d = 1; if (e.x + e.w > e.mx) e.d = -1;
    }
    Box eb{e.x, e.y, e.w, 12};
    if (e.kind == 1 || e.kind == 6) eb = Box{e.x, e.baseY - 10, e.w, 34};
    if (e.kind == 2) eb = Box{e.x, e.y - 40, e.w, 52};
    if (s.atk > 8 && s.atk < 17 && e.hit == 0 && hit(ab, eb)) { e.hit = 1; e.hp -= 2; e.kb = 8; }
    if (e.hp > 0 && hit(pbx, eb)) damaged = true;
  }
  for (auto& h : LV.haz) if (hit(pbx, h.b)) damaged = true;
  // هدف
  // ---- ضربة
  if (s.atk == 12) {
    for (int i = 0; i < s.nb; i++) if (s.bk[i].alive) { Box bb{LV.brks[i].x, LV.brks[i].y, LV.brks[i].w, LV.brks[i].h}; if (hit(ab, bb)) { if (--s.bk[i].hp <= 0) s.bk[i].alive = false; } }
  }
  if (s.atk == 12) {
    for (int i = 0; i < s.nbu; i++) if (s.bu[i].alive) {
      const BuSpec& sp = LV.bubs[i];
      double bx = sp.x + sin(s.t * sp.sp + sp.ph) * sp.ax, by = sp.y + sin(s.t * sp.sp * 1.3 + sp.ph) * sp.ay;
      if (hit(ab, Box{bx - 11, by - 11, 22, 22})) { s.bu[i].alive = false; s.bu[i].respawn = 300; }
    }
  }
  if (s.atk > 0) s.atk--;
  // ---- المقذوفات (بعد اللاعب)
  int w = 0;
  for (int i = 0; i < s.np; i++) {
    Pr q = s.pr[i]; q.x += q.vx; q.y += q.vy; q.l--;
    Box bx{q.x - 4, q.y - 4, 8, 8};
    if (hit(pbx, bx) && q.l > 0) { q.l = 0; damaged = true; }
    if (q.y > kFloorY - 2) q.l = 0;
    if (q.l > 0) { Box pb2{q.x - 3, q.y - 3, 6, 6}; for (int k = 0; k < live.n; k++) if (hit(pb2, live.b[k])) { q.l = 0; break; } }
    if (q.l > 0 && q.x > -20 && q.x < LV.length + 20) s.pr[w++] = q;
  }
  s.np = w;
  return damaged;
}

// ---------- هاش للتجميع
static uint64_t hashState(const State& s) {
  uint64_t h = 1469598103934665603ULL;
  auto mix = [&](long long v) { h ^= (uint64_t)v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2); h *= 1099511628211ULL; };
  mix((long long)floor(s.x * 1.0)); mix((long long)floor(s.y * 1.0)); mix((long long)floor(s.vx * 3)); mix((long long)floor(s.vy * 2));
  mix(s.g); mix(s.coy); mix(s.jb); mix(s.dash); mix(s.dcd / 3); mix(s.atk); mix(s.f); mix(s.pj); mix(s.dashBuf);
  for (int i = 0; i < s.nc; i++) mix(s.cr[i].timer * 3 + s.cr[i].active);
  for (int i = 0; i < s.nf; i++) mix(s.fa[i].st * 1000 + s.fa[i].tm);
  for (int i = 0; i < s.nr; i++) mix(s.ro[i].active * 100000 + s.ro[i].tm);
  for (int i = 0; i < s.ne; i++) mix(s.en[i].hp);
  for (int i = 0; i < s.nb; i++) mix(s.bk[i].alive * 10 + s.bk[i].hp);
  for (int i = 0; i < s.nk; i++) mix(s.ky[i].taken * 2 + s.ky[i].open);
  mix(s.np); mix(s.spr); for (int i = 0; i < 8; i++) mix(s.gt[i]);
  for (int i = 0; i < s.nbu; i++) mix(s.bu[i].alive ? 0 : 1 + s.bu[i].respawn / 6);
  for (int i = 0; i < s.np; i++) { mix((long long)(s.pr[i].x / 4)); mix((long long)(s.pr[i].y / 4)); }
  return h;
}

struct Node { State s; double score; };

static double score(const State& s, const Run& r) {
  int wi = s.wpi;
  if (wi >= (int)r.wps.size()) return 1e9;
  const WP& w = r.wps[wi];
  double dx = fabs(s.x - w.x), dy = fabs(s.y - w.y);
  return wi * 1e5 - (dx + dy * 0.3);
}

int main(int argc, char** argv) {
  if (argc < 2) { fprintf(stderr, "usage\n"); return 1; }
  int W = argc > 2 ? atoi(argv[2]) : 800;
  int maxFrames = argc > 3 ? atoi(argv[3]) : 6000;
  ifstream in(argv[1]); string tok;
  Run* cur = nullptr; 
  while (in >> tok) {
    if (tok == "LEVEL") { in >> LV.name >> LV.length >> LV.goalX >> LV.goalY; }
    else if (tok == "SOLID") { Box b; in >> b.x >> b.y >> b.w >> b.h; LV.solids.push_back(b); }
    else if (tok == "MOV") { Mov m; in >> m.ox >> m.oy >> m.w >> m.ax >> m.ay >> m.sp >> m.ph; LV.movs.push_back(m); }
    else if (tok == "CRUM") { Crum c; in >> c.x >> c.y >> c.w; LV.crums.push_back(c); }
    else if (tok == "HAZ") { Haz h; in >> h.b.x >> h.b.y >> h.b.w >> h.b.h >> h.kind; LV.haz.push_back(h); }
    else if (tok == "EN") { ESpec e; in >> e.x >> e.mn >> e.mx >> e.kind >> e.y; e.hasY = e.y >= 0; LV.ens.push_back(e); }
    else if (tok == "TIM") { TSpec t; int mp; in >> t.kind >> t.x >> t.y >> t.w >> t.h >> t.period >> t.on >> t.phase >> mp; LV.tim.push_back(t); }
    else if (tok == "FALL") { FSpec f; in >> f.kind >> f.x >> f.period >> f.phase; LV.falls.push_back(f); }
    else if (tok == "ROLL") { RSpec r; in >> r.kind >> r.x0 >> r.x1 >> r.period >> r.phase; LV.rolls.push_back(r); }
    else if (tok == "KEY") { KSpec k; in >> k.kx >> k.ky >> k.dx >> k.bottom; LV.keys.push_back(k); }
    else if (tok == "VAN") { VSpec v; int h; in >> v.x >> v.y >> v.w >> v.period >> v.phase >> h; v.hidden = h; LV.vans.push_back(v); }
    else if (tok == "BRK") { BSpec b; int d; in >> b.kind >> b.x >> b.y >> b.w >> b.h >> d; b.drop = d; LV.brks.push_back(b); }
    else if (tok == "SPR") { SSpec q; in >> q.x >> q.y >> q.power; LV.springs.push_back(q); }
    else if (tok == "BUB") { BuSpec q; in >> q.x >> q.y >> q.ax >> q.ay >> q.sp >> q.ph; LV.bubs.push_back(q); }
    else if (tok == "RUN") { Run r; in >> r.name >> r.sx >> r.sy >> r.t0; LV.runs.push_back(r); cur = &LV.runs.back(); }
    else if (tok == "PRE") { int k, o; in >> k >> o; LV.runs.back().pre.push_back({k, o}); }
    else if (tok == "WP") { WP w; in >> w.x >> w.y >> w.r; LV.runs.back().wps.push_back(w); }
  }
  if (argc > 4 && string(argv[4]) == "replay") {
    ifstream af(argv[5]); State s; initState(s, LV.runs[0]); int dir, j, d, a; int f = 0;
    while (af >> dir >> j >> d >> a) { bool dm = stepOnce(s, dir < 0, dir > 0, j, d, a); printf("%d x=%.1f y=%.1f vx=%.2f vy=%.2f g=%d coy=%d dm=%d\n", ++f, s.x, s.y, s.vx, s.vy, (int)s.g, s.coy, (int)dm); }
    return 0;
  }
  int failures = 0;
  for (auto& run : LV.runs) {
    State s0; initState(s0, run); s0.wpi = 0;
    // اهبط أولاً: ابدأ بحالة أرضية
    vector<State> beam; beam.push_back(s0);
    bool done = false; int frames = 0; int bestWp = 0; double bestX = 0;
    vector<State> hist; // لا نحفظ المسار الكامل؛ نحفظ سجل الأفعال عبر parent
    // تتبع الأفعال
    struct Rec { int parent; unsigned char act; };
    vector<vector<Rec>> recs; 
    vector<int> idxInBeam;
    vector<vector<int>> dummy;
    recs.reserve(maxFrames + 1);
    recs.push_back(vector<Rec>{Rec{-1, 0}});
    for (frames = 0; frames < maxFrames && !done; frames++) {
      vector<pair<double, State>> cand; cand.reserve(beam.size() * 8);
      unordered_set<uint64_t> seen;
      vector<Rec> rr;
      for (size_t bi = 0; bi < beam.size(); bi++) {
        const State& s = beam[bi];
        // هل يوجد عدو/كسّار قريب؟ لتفعيل خيار الهجوم
        bool nearT = false;
        for (int i = 0; i < s.ne; i++) if (s.en[i].hp > 0 && fabs(s.en[i].x - s.x) < 70 && fabs(s.en[i].y - s.y) < 60) nearT = true;
        for (int i = 0; i < s.nb; i++) if (s.bk[i].alive && fabs(LV.brks[i].x + LV.brks[i].w / 2 - s.x) < 70 && fabs(LV.brks[i].y - s.y) < 70) nearT = true;
        for (int i = 0; i < s.nbu; i++) if (s.bu[i].alive && fabs(LV.bubs[i].x - s.x) < LV.bubs[i].ax + 70 && fabs(LV.bubs[i].y - s.y) < LV.bubs[i].ay + 70) nearT = true;
        for (int dir = -1; dir <= 1; dir++) for (int j = 0; j < 2; j++) for (int d = 0; d < 2; d++) for (int a = 0; a < (nearT ? 2 : 1); a++) {
          if (d && (s.dcd > 0 || s.dash > 0 || getenv("NODASH")) ) continue;
          State n = s;
          bool dm = stepOnce(n, dir < 0, dir > 0, j, d, a);
          if (dm) continue;
          if (n.y > kH + 40) continue;
          if (!n.g && n.y + PH > 441.5 && n.coy == 0 && n.dash <= 0 && !getenv("LOWOK")) continue; // سقط تحت مستوى الأرض = هالك
          // انتقال نقاط الطريق
          while (n.wpi < (int)run.wps.size()) { const WP& w = run.wps[n.wpi]; if (fabs(n.x - w.x) < w.r && fabs(n.y - w.y) < w.r * 1.6) n.wpi++; else break; }
          uint64_t h = hashState(n) * 31 + n.wpi;
          if (seen.count(h)) continue; seen.insert(h);
          n.parent = bi; n.act = (unsigned char)(((dir + 1) << 4) | (j << 3) | (d << 2) | (a << 1));
          double sc = score(n, run);
          cand.push_back({sc, n});
        }
      }
      if (cand.empty()) break;
      // تنويع: أفضل K لكل خانة x
      sort(cand.begin(), cand.end(), [](const pair<double, State>& a, const pair<double, State>& b) { return a.first > b.first; });
      if (getenv("DBG4") && frames>=89 && frames<=100) { int cj=0; double mn=999; for (auto& c : cand) if (c.second.y<412) { cj++; mn=min(mn,c.second.y);} fprintf(stderr,"f=%d cand=%zu jumpers=%d minY=%.1f\n",frames,cand.size(),cj,mn); }
      vector<State> nb; nb.reserve(W);
      unordered_map<long long, int> bucket;
      int perBucket = 3;
      for (auto& c : cand) {
        if ((int)nb.size() >= W) break;
        long long bk = ((long long)c.second.wpi * 100000000LL + (long long)(c.second.x / 10) * 100000LL + (long long)(c.second.y / 10) * 100 + (c.second.g ? 50 : 0) + (long long)floor((c.second.vy + 12) / 3) + (c.second.dash > 0 ? 7 : 0));
        if (bucket[bk] >= perBucket) continue; bucket[bk]++;
        nb.push_back(c.second);
        rr.push_back(Rec{c.second.parent, (unsigned char)c.second.act});
      }
      // أكمل بالباقي إن بقي مكان
      if ((int)nb.size() < W / 2) { for (auto& c : cand) { if ((int)nb.size() >= W) break; bool dup = false; (void)dup; } }
      recs.push_back(rr);
      if (getenv("DBG3") && frames>=88 && frames<=124 && frames%4==0) { int c=0, nair=0; double minY=999, maxX=0; for (auto& q : nb) { if (q.x>285) { nair++; minY=min(minY,q.y);} maxX=max(maxX,q.x);} fprintf(stderr,"f=%d beam=%zu x>285:%d minY=%.1f maxX=%.1f\n",frames,nb.size(),nair,minY,maxX);} 
      if (getenv("DBG2") && frames % 20 == 0) { int c=0; for (auto& q : nb) { if (q.x>340 && c<8) { fprintf(stderr,"   f=%d x=%.1f y=%.1f vx=%.2f vy=%.2f g=%d\n",frames,q.x,q.y,q.vx,q.vy,(int)q.g); c++; } } }
      if (getenv("DBG") && frames % 10 == 0) { int air=0; double mx=0; for (auto& q : nb) { if(!q.g) air++; mx=max(mx,q.x);} fprintf(stderr,"f=%d beam=%zu air=%d maxx=%.0f cand=%zu\n", frames, nb.size(), air, mx, cand.size()); }
      beam.swap(nb);
      for (auto& s : beam) {
        if (s.wpi >= (int)run.wps.size()) { done = true; }
        if (s.wpi > bestWp) { bestWp = s.wpi; }
        bestX = max(bestX, s.x);
      }
      // أعد ضبط parent إلى فهرس في recs: parent يشير لفهرس في الإطار السابق
      for (size_t i = 0; i < beam.size(); i++) beam[i].parent = i;
      if (done) {
        // استخرج المسار
        int idx = -1; for (size_t i = 0; i < beam.size(); i++) if (beam[i].wpi >= (int)run.wps.size()) { idx = i; break; }
        vector<unsigned char> acts; int cur2 = idx; 
        for (int f = recs.size() - 1; f >= 1; f--) { acts.push_back(recs[f][cur2].act); cur2 = recs[f][cur2].parent; }
        reverse(acts.begin(), acts.end());
        printf("OK   %-28s frames=%d (%.1fs) beam=%zu\n", run.name.c_str(), (int)acts.size(), acts.size() / 60.0, beam.size());
        // احفظ الأفعال
        string fn = string("path_") + run.name + ".txt"; FILE* fo = fopen(fn.c_str(), "w");
        for (auto a : acts) fprintf(fo, "%d %d %d %d\n", (a >> 4) - 1, (a >> 3) & 1, (a >> 2) & 1, (a >> 1) & 1);
        fclose(fo);
      }
    }
    if (!done) {
      printf("FAIL %-28s reached wp=%d/%zu maxX=%.0f frames=%d beam=%zu\n", run.name.c_str(), bestWp, run.wps.size(), bestX, frames, beam.size());
      failures++;
    }
  }
  return failures ? 2 : 0;
}
