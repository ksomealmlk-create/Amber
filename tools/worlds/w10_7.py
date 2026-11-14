from dsl import *
def build():
    L=Lv(7,"الجسر الأسود",4200,4100); L.world=10
    for a,b in [(0,900),(1560,1900),(2560,2900),(3500,4200)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,420,412,4); L.enemy(0,600,450,850)
    # جسور تنهار وفجوات متوسطة
    for x in (950,1060,1170,1280,1390,1500): L.crum(x,420,56); L.ember(x+28,385)
    L.cp(1570); L.enemy(0,1750,1600,1880); L.embers_line(1590,1880,412,4)
    L.plat(1920,408,50)
    for x in (1990,2100,2210,2320,2430): L.crum(x,420,56); L.ember(x+28,385)
    L.plat(2500,408,50)
    L.cp(2570); L.spikes(2680,60); L.enemy(5,2800,2600,2880); L.embers_line(2590,2650,412,2)
    for x in (2950,3070,3190,3310,3410): L.crum(x,420,56)
    L.chest(2730,426)
    L.cp(3510); L.enemy(0,3700,3550,3850); L.crate(3950,FLOOR,2); L.embers_line(3530,4150,412,6)
    L.auto_runs()
    return L
