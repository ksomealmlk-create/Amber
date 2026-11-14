from dsl import *
def build():
    L=Lv(1,"بوابة المقبرة",3600,3500); L.world=7
    for a,b in [(0,950),(1050,1850),(1950,2750),(2850,3600)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,380,412,4)
    for x in (420,640): L.block(x,404,26)
    L.enemy(0,760,640,940); L.plat(985,408,60)
    L.cp(1070)
    # مسار متعرج: شواهد قبور ومنصات بارتفاعات متناوبة
    L.block(1200,404,26); L.plat(1300,370,90); L.plat(1440,330,90); L.plat(1580,370,90); L.spikes(1290,300)
    L.enemy(0,1700,1620,1840); L.ember(1345,335); L.ember(1485,295); L.ember(1625,335)
    L.embers_line(1100,1180,412,2); L.plat(1885,408,60)
    L.cp(1970); L.block(2080,404,26); L.block(2200,380,26); L.enemy(0,2380,2260,2560); L.block(2620,404,26)
    L.embers_line(2000,2060,412,2); L.embers_line(2280,2700,412,5); L.plat(2785,408,60)
    L.cp(2870); L.block(2980,404,26); L.spikes(3100,60); L.enemy(0,3250,3140,3380); L.chest(3420,426)
    L.embers_line(2900,2960,412,2); L.embers_line(3150,3400,412,4)
    L.auto_runs()
    return L
