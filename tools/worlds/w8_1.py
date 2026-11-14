from dsl import *
def build():
    L=Lv(1,"المدخل القديم",3600,3500); L.world=8
    for a,b in [(0,900),(1000,1600),(1750,2400),(2550,3600)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,380,412,4); L.enemy(0,650,500,850); L.plat(930,408,60)
    # منصات حجرية وأعمدة متباعدة
    L.cp(1020); L.block(1150,350,30); L.block(1330,350,30); L.plat(1200,370,70); L.enemy(0,1480,1380,1590)
    L.ember(1235,335); L.embers_line(1040,1130,412,2); L.embers_line(1400,1580,412,3)
    L.plat(1640,400,70); L.plat(1680,360,70)
    L.cp(1770); L.plat(1900,360,80); L.plat(2040,320,80); L.plat(2180,360,80); L.spikes(1890,370)
    L.ember(1940,325); L.ember(2080,285); L.ember(2220,325); L.plat(2440,408,60)
    L.cp(2570); L.block(2700,350,30); L.block(2900,350,30); L.enemy(0,3050,2950,3200); L.chest(3300,426)
    L.embers_line(2600,2680,412,2); L.embers_line(2750,2880,412,3); L.embers_line(3050,3250,412,3)
    L.auto_runs()
    return L
