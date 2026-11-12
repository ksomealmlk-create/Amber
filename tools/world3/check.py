# فحص ساكن لتصميم المراحل: نقاط الحفظ، الجمرات، الأعداء، البداية والهدف، التداخلات
import sys, importlib
from dsl import *
def solids(L):
    S=[(x,FLOOR,w,60) for x,w in L.grounds]+[(x,y,w,14) for x,y,w in L.plats]+list(L.extra)
    return S
def hit(a,b): return a[0]<b[0]+b[2] and a[0]+a[2]>b[0] and a[1]<b[1]+b[3] and a[1]+a[3]>b[1]
def check(L):
    S=solids(L); errs=[]; warn=[]
    def surface(x, y, tol=6):
        for (sx,sy,sw,sh) in S:
            if sx-1<=x<=sx+sw+1 and abs(sy-y)<=tol: return True
        return False
    def on_any_support(x,y):
        if surface(x,y): return True
        for m in L.movs:
            pass
        for (cx,cy,cw) in L.crums:
            if cx<=x<=cx+cw and abs(cy-y)<=6: return True
        for v in L.vans:
            if v[0]<=x<=v[0]+v[2] and abs(v[1]-y)<=6: return True
        return False
    # بداية
    if not surface(30,FLOOR): errs.append("start not on ground")
    # الهدف
    gy=L.goal_y
    if not any(sx<=L.goal_x<=sx+sw and sy<=440 for (sx,sy,sw,sh) in S if sy>=300): warn.append("goal: no ground near goalX")
    for (x,g) in L.checks:
        if not surface(x,g): errs.append("checkpoint %s,%s not on a solid top"%(x,g))
        pb=(x-7,g-22,14,22)
        for s in S:
            if hit(pb,s) and s[1]<g-1: errs.append("checkpoint %s inside solid %s"%(x,s))
        for h in L.haz:
            if hit((x-30,g-40,60,60),(h[0],h[1],h[2],h[3])): errs.append("checkpoint %s near hazard %s"%(x,h))
        for t in L.timed:
            if t[8]==0 and hit((x-40,g-60,80,80),(t[1],t[2],t[3],t[4])): errs.append("checkpoint %s near timed %s"%(x,t))
        for b in L.bubs:
            if abs(b[0]-x)<b[2]+50 and abs(b[1]-g)<b[3]+60: errs.append("checkpoint %s near bubble"%x)
        for e in L.ens:
            if abs(e[0]-x)<60 and e[3]!=1 and e[3]!=6 and (e[4] is None or abs(e[4]-g)<10): warn.append("checkpoint %s near enemy at %s"%(x,e[0]))
    for (x,y) in L.embers:
        b=(x-6,y-6,12,12)
        for s in S:
            if hit(b,s): errs.append("ember %s,%s inside solid %s"%(x,y,s)); break
        for br in L.breaks:
            if hit(b,(br[1],br[2],br[3],br[4])): errs.append("ember %s,%s inside breakable"%(x,y)); break
    for e in L.ens:
        x,mn,mx,k,y=e
        yy=FLOOR if y is None else y
        if k not in (1,6) and not surface(x,yy): errs.append("enemy kind %d at %s,%s has no ground"%(k,x,yy))
        if k not in (1,6):
            for z in (mn,mx):
                if not surface(z,yy): warn.append("enemy patrol edge %s lacks ground (kind %d at %s)"%(z,k,x))
    for c in L.chests:
        if not on_any_support(c[0]+9,c[1]+14): errs.append("chest %s not on ground"%(c,))
    for k in L.keys:
        kb=(k[0]-6,k[1]-6,12,12)
        for s in S:
            if hit(kb,s): errs.append("key inside solid %s"%(k,))
    # حجم المحاكي
    if len(L.crums)>64: errs.append("too many crumbles for sim (%d)"%len(L.crums))
    if len(L.breaks)>32: errs.append("too many breakables for sim (%d)"%len(L.breaks))
    if len(L.ens)>16: errs.append("too many enemies for sim (%d)"%len(L.ens))
    if len(L.keys)>4: errs.append("too many keys for sim")
    if len(L.falls)>16 or len(L.rolls)>8: errs.append("falls/rolls limits")
    if len(L.bubs)>12: errs.append("too many bubbles for sim")
    return errs,warn
if __name__=="__main__":
    for m in sys.argv[1:]:
        L=importlib.import_module(m).build()
        errs,warn=check(L)
        print(m, L.name, "length",L.length,"embers",len(L.embers),"cps",len(L.checks))
        for e in errs: print("  ERR ",e)
        for w in warn: print("  warn",w)
