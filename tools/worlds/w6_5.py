from dsl import *
def build():
    L=Lv(5,"الجسر الجليدي",4000,3900); L.world=6
    for a,b in [(0,500),(1300,1560),(2360,2620),(3400,4000)]: L.ground(a,b)
    L.slip(0,4000)
    L.cp(60); L.embers_line(100,480,412,4); L.enemy(0,300,150,480)
    # جسر جليدي أجزاؤه تنهار بعد الوقوف عليها
    for i in range(10): L.crum(520+i*78,405,62)
    L.embers_line(540,1260,372,8)
    L.cp(1320); L.enemy(0,1450,1330,1550); L.embers_line(1330,1550,412,3)
    for i in range(7): L.crum(1580+i*78,405,62)
    L.van(2130,405,62,150,0); L.crum(2230,405,62); L.embers_line(1600,2300,372,7)
    L.cp(2370); L.fall(1,2500,80,0); L.enemy(0,2540,2400,2610)
    L.crum(2650,405,62); L.van(2740,405,62,150,0); L.crum(2840,405,62); L.crum(2920,405,62); L.crum(3010,405,62); L.crum(3110,405,62); L.crum(3190,405,62); L.crum(3270,405,62)
    L.embers_line(2660,3340,372,8)
    L.cp(3410); L.enemy(0,3700,3500,3850); L.embers_line(3430,3980,412,6)
    L.auto_runs()
    return L
