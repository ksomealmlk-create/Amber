from dsl import *
def build():
    L=Lv(7,"غرفة الميزان",4000,3900); L.world=8
    for a,b in [(0,800),(1700,2000),(2900,3100),(3600,4000)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,420,412,4); L.enemy(0,500,350,780); L.plat(830,408,60)
    # كفتا ميزان: منصتان تصعد إحداهما بينما تهبط الأخرى (أطوار متعاكسة)
    import math
    for k,x in enumerate((900,1150,1400)):
        L.mov(x,360,90,0,45,.03,0); L.mov(x+110,360,90,0,45,.03,math.pi)
        L.ember(x+45,300); L.ember(x+155,300)
    L.plat(1580,400,70)
    L.cp(1710); L.enemy(0,1850,1730,1980); L.embers_line(1730,1990,412,4)
    for k,x in enumerate((2060,2290,2520)):
        L.mov(x,350,80,0,50,.032,0); L.mov(x+100,350,80,0,50,.032,math.pi); L.ember(x+40,290)
    L.plat(2760,400,70); L.plat(2830,400,60)
    L.cp(2910); L.embers_line(2920,3090,412,3)
    L.mov(3150,380,80,70,0,.03,0); L.mov(3300,330,80,0,40,.03,1.0); L.mov(3450,380,80,60,0,.03,2.0); L.chest(3330,426) if False else None
    L.plat(3540,408,50)
    L.cp(3620); L.chest(3750,426); L.enemy(5,3850,3700,3980); L.embers_line(3640,3980,412,5)
    L.auto_runs()
    return L
