from dsl import *
def build():
    L=Lv(1,"المدخل المتجمد",3600,3500); L.world=6
    for a,b in [(0,900),(1000,1700),(1800,2500),(2620,3600)]: L.ground(a,b)
    L.slip(250,3600)
    L.cp(60); L.embers_line(100,420,412,4); L.crate(560,FLOOR,3); L.enemy(0,720,600,880)
    L.plat(930,408,60)
    L.cp(1020); L.spikes(1180,40); L.enemy(0,1400,1260,1690); L.plat(1250,360,90); L.ember(1295,325)
    L.embers_line(1060,1160,412,2); L.embers_line(1240,1680,412,5)
    L.plat(1730,410,60)
    L.cp(1820); L.plat(1950,370,90); L.plat(2090,330,90); L.crate(2250,FLOOR,3); L.enemy(0,2380,2260,2490)
    L.ember(1995,335); L.ember(2135,295); L.embers_line(1840,1920,412,2); L.embers_line(2300,2480,412,3)
    L.plat(2550,410,60)
    L.cp(2640); L.spikes(2800,50); L.enemy(0,3000,2850,3140); L.crate(3200,FLOOR,3); L.enemy(0,3400,3250,3590)
    L.embers_line(2660,2780,412,3); L.embers_line(2880,3180,412,4); L.embers_line(3250,3580,412,4)
    L.auto_runs()
    return L
