from dsl import *
def build():
    L=Lv(1,"مدخل المنجم",3600,3500); L.world=9
    for a,b in [(0,900),(1060,1800),(1960,2700),(2860,3600)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,380,412,4); L.crate(500,FLOOR,2); L.enemy(0,700,560,880)
    # عربات منجم تتحرك فوق الفجوات
    L.mov(910,400,80,40,0,.03,0)
    L.cp(1080); L.block(1250,380,40); L.enemy(0,1450,1320,1600); L.embers_line(1100,1230,412,3); L.embers_line(1330,1700,412,4)
    L.mov(1810,400,80,50,0,.03,1.0)
    L.cp(1980); L.spikes(2150,60); L.plat(2250,370,80); L.enemy(0,2450,2330,2600); L.ember(2290,335); L.embers_line(2000,2130,412,3)
    L.mov(2710,400,80,40,0,.03,2.0)
    L.cp(2880); L.crate(3000,FLOOR,2); L.enemy(0,3250,3100,3400); L.chest(3450,426); L.embers_line(2900,2980,412,2); L.embers_line(3100,3430,412,5)
    L.auto_runs()
    return L
