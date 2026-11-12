import importlib, sys
from dsl import *
import os
WORLD=int(os.environ.get("WORLD","1"))
mods=['lv%d'%i for i in range(1,11)] if WORLD==1 else ['w2_%d'%i for i in range(1,6)]
def D(v): return repr(float(v))
def box(x,y,w,h): return "Box(%s, %s, %s, %s)"%(D(x),D(y),D(w),D(h))
def emit(L):
    o=[]
    o.append("  static LevelConfig level%d() {"%L.idx)
    o.append("    return LevelConfig(")
    o.append("      world: %d,\n      index: %d,\n      name: LevelFactory.nameOf(%d, %d),\n      length: %s,\n      theme: WorldTheme.%s,"%(WORLD,L.idx,WORLD,L.idx,D(L.length),'cave' if WORLD==1 else 'forest'))
    o.append("      grounds: [%s],"%", ".join(box(x,FLOOR,w,60) for x,w in sorted(L.grounds)))
    o.append("      platforms: [%s],"%", ".join(box(x,y,w,14) for x,y,w in L.plats))
    if L.extra: o.append("      extra: [%s],"%", ".join(box(*e) for e in L.extra))
    if L.movs: o.append("      movs: [%s],"%", ".join("MovSpec(%s)"%", ".join(D(v) for v in m) for m in L.movs))
    if L.crums: o.append("      crumbs: [%s],"%", ".join("CrumbleSpec(%s, %s, %s)"%tuple(D(v) for v in c) for c in L.crums))
    if L.haz: o.append("      hazards: [%s],"%", ".join("HazardSpec(%s, %s, %s, %s, %d)"%(D(h[0]),D(h[1]),D(h[2]),D(h[3]),h[4]) for h in L.haz))
    ens=[]
    for (x,mn,mx,k,y) in L.ens:
        ens.append("EnemySpawn(%s, %s, %s, %d%s)"%(D(x),D(mn),D(mx),k,(", "+D(y)) if y is not None else ""))
    o.append("      enemies: [%s],"%", ".join(ens))
    o.append("      embers: [%s],"%", ".join("[%s, %s]"%(D(x),D(y)) for x,y in L.embers))
    if L.chests: o.append("      chests: [%s],"%", ".join("ChestSpec(%s, %s)"%(D(x),D(y)) for x,y in L.chests))
    o.append("      goalX: %s,\n      goalY: 370.0,"%D(L.goal_x))
    if L.boss:
        n,k,x,tr,hp=L.boss
        o.append("      boss: BossSpec('%s', %d, %s, %s, %s),"%(n,k,D(x),D(tr),D(hp)))
    o.append("      seed: %d,"%(WORLD*100+L.idx))
    if L.breaks: o.append("      breaks: [%s],"%", ".join("BreakSpec(%d, %s, %s, %s, %s, %s)"%(b[0],D(b[1]),D(b[2]),D(b[3]),D(b[4]),"true" if b[5] else "false") for b in L.breaks))
    if L.timed: o.append("      timed: [%s],"%", ".join("TimedSpec(%d, %s, %s, %s, %s, %s, %s, %s%s)"%(t[0],D(t[1]),D(t[2]),D(t[3]),D(t[4]),D(t[5]),D(t[6]),D(t[7]),(", %d"%t[8]) if t[8] else "") for t in L.timed))
    if L.falls: o.append("      falls: [%s],"%", ".join("FallSpec(%d, %s, %s, %s)"%(f[0],D(f[1]),D(f[2]),D(f[3])) for f in L.falls))
    if L.rolls: o.append("      rolls: [%s],"%", ".join("RollSpec(%d, %s, %s, %s, %s)"%(r[0],D(r[1]),D(r[2]),D(r[3]),D(r[4])) for r in L.rolls))
    if L.keys: o.append("      keyDoors: [%s],"%", ".join("KeyDoorSpec(%s, %s, %s, %s)"%tuple(D(v) for v in k) for k in L.keys))
    if L.vans: o.append("      vanish: [%s],"%", ".join("VanishSpec(%s, %s, %s, %s, %s%s)"%(D(v[0]),D(v[1]),D(v[2]),D(v[3]),D(v[4]),", true" if v[5] else "") for v in L.vans))
    cps=sorted(L.checks)
    o.append("      checks: [%s],"%", ".join("CheckSpec(%s, %s)"%(D(x),D(g)) for x,g in cps))
    o.append("    );\n  }\n")
    return "\n".join(o)
def main():
    levels=[]
    for m in mods:
        mod=importlib.import_module(m); levels.append(mod.build())
    out=["// العالم الأول «المغارة المنسية»: عشر مراحل مصمَّمة يدوياً ومُختبَرة بمحاكٍ مطابق للمحرك.","// (ملف مولَّد من أدوات التصميم؛ كل مرحلة بتخطيط وفكرة مختلفة، والمرحلة 10 مواجهة الحارس الحجري.)","import 'level.dart';\n","class World%d {"%WORLD+"","  static LevelConfig build(int idx) {","    switch (idx) {"]
    for L in levels: out.append("      case %d:\n        return level%d();"%(L.idx,L.idx))
    out.append("      default:\n        return level1();\n    }\n  }\n")
    for L in levels: out.append(emit(L))
    out.append("}\n")
    open("world%d.dart"%WORLD,"w",encoding="utf-8").write("\n".join(out))
    print("written", sum(len(l.embers) for l in levels), "embers total")
main()
