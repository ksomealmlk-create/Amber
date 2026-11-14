from dsl import *
def build():
    L=Lv(2,"ساحة القبور",3800,3700); L.world=7
    for a,b in [(0,1300),(1400,2500),(2600,3800)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,300,412,3)
    # قبور تُخرج أعداء عند الاقتراب
    L.grave(500); L.block(520,404,26); L.grave(800); L.block(820,404,26); L.grave(1100); L.block(1120,404,26)
    L.embers_line(560,780,412,4); L.plat(1330,408,60)
    L.cp(1420); L.grave(1600); L.block(1620,404,26); L.enemy(0,1800,1700,1900)
    L.grave(2000); L.block(2020,404,26); L.grave(2250); L.block(2270,404,26)
    L.embers_line(1450,1580,412,3); L.embers_line(2060,2240,412,3); L.plat(2530,408,60)
    L.cp(2620); L.secret(2720); L.grave(3050); L.block(3070,404,26); L.spikes(3200,50)
    L.grave(3350); L.block(3370,404,26); L.enemy(0,3500,3400,3640); L.embers_line(2900,3030,412,3); L.embers_line(3420,3600,412,3)
    L.auto_runs()
    return L
