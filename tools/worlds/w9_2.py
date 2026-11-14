from dsl import *
def build():
    L=Lv(2,"ممر البلورات",3800,3700); L.world=9
    L.ground(0,3800)
    L.cp(60); L.embers_line(100,300,412,3)
    # بلورات كبيرة تعيق الحركة (قفز فوقها) ومسارات علوية جانبية
    for x in (450,640,830): L.crystal(x,FLOOR,False); L.block(x+30,390,34)
    L.plat(500,350,80); L.plat(640,310,80); L.plat(780,350,80); L.chest(660,296)
    L.ember(540,315); L.ember(680,275); L.ember(820,315); L.enemy(0,1050,950,1150)
    L.cp(1200); L.block(1350,380,50); L.block(1550,360,50); L.block(1750,380,50); L.enemy(0,1950,1800,2100)
    L.embers_line(1220,1330,412,3); L.embers_line(1430,1520,412,2); L.embers_line(1830,1940,412,3)
    L.cp(2200); L.crystal(2350,FLOOR,True); L.crystal(2480,FLOOR,True); L.spikes(2600,70); L.enemy(5,2800,2680,2900)
    L.secret(3000); L.embers_line(2220,2340,412,3)
    L.cp(3250); L.block(3400,380,50); L.enemy(0,3550,3450,3700); L.embers_line(3270,3380,412,3); L.embers_line(3500,3780,412,4)
    L.auto_runs()
    return L
