from dsl import *
def build():
    L=Lv(1,"الطريق إلى القلعة",4000,3900); L.world=10
    # جسور حجرية (فجوات قصيرة) مع أعداء وحواجز تُكسر أو يُقفز فوقها
    for a,b in [(0,900),(1020,1800),(1920,2700),(2830,3500),(3620,4000)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,380,412,3); L.enemy(0,600,450,850); L.crate(480,FLOOR,2)
    L.ember(960,380)
    L.cp(1040); L.block(1250,400,40); L.enemy(0,1450,1300,1700); L.embers_line(1060,1230,412,3); L.embers_line(1320,1700,412,4)
    L.spikes(1560,60)
    L.cp(1940); L.wall(2150); L.enemy(5,2400,2250,2650); L.embers_line(1960,2120,412,3); L.embers_line(2200,2640,412,4)
    L.crate(2560,FLOOR,2)
    L.plat(2740,410,70)
    L.cp(2850); L.spikes(3000,60); L.enemy(0,3200,3050,3420); L.secret(3100); L.embers_line(2870,2980,412,2)
    L.cp(3640); L.enemy(0,3800,3700,3900); L.embers_line(3660,3900,412,4)
    L.auto_runs()
    return L
