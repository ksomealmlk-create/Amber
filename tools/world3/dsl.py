# إطار تصميم مراحل «المغارة المنسية» — يصدّر بيانات المحاكي وكود Dart من مصدر واحد
import math, json
FLOOR = 440

class Lv:
    def __init__(s, idx, name, length, goal_x, goal_y=370):
        s.idx, s.name, s.length, s.goal_x, s.goal_y = idx, name, length, goal_x, goal_y
        s.grounds=[]; s.plats=[]; s.extra=[]; s.movs=[]; s.crums=[]; s.haz=[]; s.ens=[]; s.embers=[]
        s.chests=[]; s.breaks=[]; s.timed=[]; s.falls=[]; s.rolls=[]; s.keys=[]; s.vans=[]; s.checks=[]
        s.springs=[]; s.bubs=[]; s.fogs=[]
        s.world=1; s.wps=[]; s.runs=[]; s.notes=[]; s.boss=None; s.seed=100+idx
    # ---- تضاريس
    def ground(s, x0, x1): s.grounds.append((x0, x1-x0))
    def block(s, x, y, w, h=None): s.extra.append((x, y, w, (500-y) if h is None else h))
    def ceil(s, x0, x1, bottom): s.extra.append((x0, 10, x1-x0, bottom-10))
    def plat(s, x, y, w): s.plats.append((x, y, w))
    # ---- عقبات
    def spikes(s, x, w, y=FLOOR-16): s.haz.append((x, y, w, 16, 0))
    def mov(s, x, y, w, ax, ay=0, sp=.02, ph=0): s.movs.append((x, y, w, ax, ay, sp, ph))
    def crum(s, x, y, w=56): s.crums.append((x, y, w))
    def wire(s, x, y, w, h, period, on, phase=0): s.timed.append((0, x, y, w, h, period, on, phase, 0))
    def tspikes(s, x, w, period, on, phase=0, h=24): s.timed.append((1, x, FLOOR-h, w, h, period, on, phase, 0))
    def blade(s, x, w, phase=0, period=140): s.timed.append((6, x, FLOOR-44, w, 44, period, period, phase, 0))
    def rock(s, x, period, phase=0): s.falls.append((0, x, period, phase))
    def roll(s, x0, x1, period, phase=0): s.rolls.append((0, x0, x1, period, phase))
    def crate(s, x, ybot=FLOOR, kind=0, drop=True):
        size={1:(24,30),2:(34,30),3:(22,36)}.get(kind,(28,28))
        s.breaks.append((kind, x, ybot-size[1], size[0], size[1], drop))
    def wall(s, x, ybot=FLOOR): s.breaks.append((4, x, ybot-62, 24, 62, False))
    def key(s, kx, ky, dx, bottom=FLOOR): s.keys.append((kx, ky, dx, bottom))
    def van(s, x, y, w, period=0, phase=0, hidden=False): s.vans.append((x, y, w, period, phase, hidden))
    def enemy(s, kind, x, mn, mx, y=None): s.ens.append((x, mn, mx, kind, y))
    def ember(s, x, y): s.embers.append((x, y))
    def embers_line(s, x0, x1, y, n):
        for i in range(n): s.embers.append((x0+(x1-x0)*i/max(1,n-1), y))
    def chest(s, x, ytop): s.chests.append((x, ytop))
    def cp(s, x, gy=FLOOR): s.checks.append((x, gy))
    def wp(s, x, y, r=16): s.wps.append((x, y, r))
    def run(s, name, sx, sy, wps, t0s=(0,), pre=None): s.runs.append((name, sx, sy, wps, t0s, pre))

    # ---- عالم الفطر السام (العالم الثالث)
    def spring(s, x, surface=FLOOR, power=1.0): s.springs.append((x, surface-12, power))
    def bubble(s, x, y, ax=0, ay=0, sp=.03, ph=0): s.bubs.append((x, y, ax, ay, sp, ph))
    def fog(s, x0, x1, d=1.0): s.fogs.append((x0, x1, d))
    def lake(s, x, w): s.haz.append((x, FLOOR-16, w, 16, 2))
    def thorns(s, x, w, y=FLOOR-16): s.haz.append((x, y, w, 16, 0))
    def puffer(s, x, w, h, period, on, phase=0, base=FLOOR): s.timed.append((3, x, base-h, w, h, period, on, phase, 0))
    def plant(s, x, w, h, period, on, phase=0, base=FLOOR): s.timed.append((5, x, base-h, w, h, period, on, phase, 0))
    def root(s, x, w, h, period, on, phase=0, base=FLOOR): s.timed.append((7, x, base-h, w, h, period, on, phase, 0))
    def croot(s, x, w, top, h, period, on, phase=0): s.timed.append((8, x, top, w, h, period, on, phase, 0))
    def wroot(s, x, y, w, h, side, period, on, phase=0): s.timed.append((9 if side=='L' else 10, x, y, w, h, period, on, phase, 0))
    def bossroot(s, kind, x, y, w, h, period, on, phase, minph): s.timed.append((kind, x, y, w, h, period, on, phase, minph))
    def mushwall(s, x, ybot=FLOOR, w=36, h=96): s.breaks.append((5, x, ybot-h, w, h, False))
    def crystal(s, x, ybot=FLOOR, drop=True): s.breaks.append((3, x, ybot-36, 22, 36, drop))
    def mushcrate(s, x, ybot=FLOOR, drop=True): s.breaks.append((0, x, ybot-28, 28, 28, drop))

    def auto_runs(s, via=None, t0s=(0,55,110,165), goal=None, prefix="seg"):
        # جولات اختبار آلية: من البداية إلى أول نقطة حفظ، ثم بين كل نقطتين، ثم إلى الهدف (بعدة أطوار زمنية)
        via = via or {}
        pts = [(30, FLOOR)] + sorted(s.checks)
        for i, (x, g) in enumerate(pts):
            wps = list(via.get(i, []))
            if i + 1 < len(pts): wps.append((pts[i+1][0], pts[i+1][1]-22, 14))
            else:
                gx, gy = goal if goal else (s.goal_x, FLOOR-22)
                wps.append((gx, gy, 18))
            s.run("%s%d"%(prefix,i), x, g-22, wps, t0s)

    # ---- تصدير للمحاكي
    def sim_text(s, run_filter=None):
        L=[f"LEVEL L{s.idx} {s.length} {s.goal_x} {s.goal_y}", "SOLID -10 0 10 500", f"SOLID {s.length-10} 0 10 500"]
        for (x,w) in s.grounds: L.append(f"SOLID {x} {FLOOR} {w} 60")
        for (x,y,w) in s.plats: L.append(f"SOLID {x} {y} {w} 14")
        for (x,y,w,h) in s.extra: L.append(f"SOLID {x} {y} {w} {h}")
        for m in s.movs: L.append("MOV "+" ".join(map(str,m)))
        for c in s.crums: L.append("CRUM "+" ".join(map(str,c)))
        for h in s.haz: L.append("HAZ "+" ".join(map(str,h)))
        for e in s.ens:
            x,mn,mx,k,y=e; L.append(f"EN {x} {mn} {mx} {k} {-1 if y is None else y}")
        for t in s.timed: L.append("TIM "+" ".join(map(str,t)))
        for f in s.falls: L.append("FALL "+" ".join(map(str,f)))
        for r in s.rolls: L.append("ROLL "+" ".join(map(str,r)))
        for k in s.keys: L.append("KEY "+" ".join(map(str,k)))
        for v in s.vans:
            x,y,w,p,ph,h=v; L.append(f"VAN {x} {y} {w} {p} {ph} {1 if h else 0}")
        for b in s.breaks:
            k,x,y,w,h,d=b; L.append(f"BRK {k} {x} {y} {w} {h} {1 if d else 0}")
        for sp in s.springs: L.append("SPR %s %s %s"%sp)
        for b in s.bubs: L.append("BUB "+" ".join(map(str,b)))
        for (name,sx,sy,wps,t0s,pre) in s.runs:
            if run_filter and name not in run_filter: continue
            for t0 in t0s:
                L.append(f"RUN {name}_t{t0} {sx} {sy} {t0}")
                pp = pre if pre is not None else [(i, 1 if k[2] < sx+10 else 0) for i,k in enumerate(s.keys) if k[0] < sx or k[2] < sx+10]
                for (i,o) in pp: L.append(f"PRE {i} {o}")
                for w in wps: L.append("WP %s %s %s"%w)
        return "\n".join(L)

def fnum(v):
    if isinstance(v,float) and v==int(v): v=int(v)
    return repr(v) if not isinstance(v,float) else ("%g"%v if abs(v)>=1e-3 else repr(v))
def D(v):
    # رقم Dart من نوع double
    f=float(v); 
    return ("%r"%f)
