from dsl import *
def build():
    L=Lv(1,"طريق البركان",3600,3500); L.world=5
    for a,b in [(0,640),(770,1300),(1430,2000),(2150,2700),(2850,3600)]: L.ground(a,b)
    L.cp(60); L.crate(380,FLOOR,2); L.embers_line(100,600,412,5)
    # فجوة 1: صخرة عائمة فوق الحمم
    L.plat(675,405,64); L.ember(707,370)
    L.cp(800); L.lake(960,70); L.enemy(0,1100,980,1260); L.secret(1130)
    L.embers_line(820,1100,412,3); L.ember(995,370)
    L.plat(1330,410,64); L.ember(1362,375)
    L.cp(1450); L.lake(1600,80); L.lake(1790,60); L.crate(1700,FLOOR,2); L.enemy(0,1900,1800,1990)
    L.embers_line(1470,1980,412,6); L.ember(1640,368); L.ember(1820,368)
    L.plat(2040,400,60); L.plat(2100,370,44)
    L.cp(2170); L.crate(2260,FLOOR,2); L.crate(2380,FLOOR,2); L.enemy(0,2550,2400,2690); L.embers_line(2190,2690,412,5)
    L.plat(2745,405,64)
    L.cp(2870); L.lake(3000,70); L.lake(3200,60); L.enemy(0,3400,3250,3590); L.crate(3330,FLOOR,2)
    L.embers_line(2890,3580,412,8); L.ember(3035,368); L.ember(3230,368)
    L.auto_runs()
    return L
