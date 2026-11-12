from dsl import *
def build():
    L=Lv(1,"مدخل الكهف",3400,3300)
    for a,b in [(0,560),(640,1100),(1190,1700),(1980,2150),(2500,3400)]: L.ground(a,b)
    # R1
    L.crate(300); L.enemy(0,450,360,540)
    L.embers_line(120,260,410,3); L.ember(314,380)
    L.ember(600,360)
    # R2 spikes + rock
    L.cp(670)
    L.spikes(760,36); L.spikes(850,36); L.spikes(960,50)
    for x in (778,868,985): L.ember(x,360)
    L.rock(1040,140,40)
    L.ember(1145,350)
    # R3 hill + tunnel
    L.cp(1215)
    L.block(1330,380,120); L.ember(1390,352)
    L.enemy(0,1270,1200,1325)
    L.ceil(1470,1690,372)
    L.spikes(1530,40); L.ember(1550,395)
    L.wire(1620,372,16,68,150,60,0); L.ember(1585,415); L.ember(1665,415)
    # pit C steps
    L.plat(1722,395,52); L.plat(1820,372,48); L.plat(1912,380,48)
    for x,y in [(1748,368),(1844,345),(1936,353)]: L.ember(x,y)
    L.cp(2005)
    # bridge
    for i in range(5): L.crum(2160+i*70,396)
    L.rock(2300,150,40)
    L.embers_line(2190,2420,368,4)
    L.van(2200,330,40,0,0,True); L.van(2290,290,40,0,0,True); L.van(2380,262,60,0,0,True)
    L.chest(2400,248)
    L.cp(2525)
    # final
    L.enemy(0,2640,2540,2780)
    L.spikes(2800,36); L.spikes(2880,36)
    L.tspikes(2980,44,150,60,30)
    L.crate(3100); L.enemy(0,3200,3140,3290)
    L.embers_line(2560,3260,410,8)
    wps=[(520,418,16),(1000,418,16),(1260,418,16),(1400,358,16),(1600,418,16),(1690,418,14),(2000,418,16),(2140,418,14),(2520,418,16),(3000,418,16),(3300,418,22)]
    L.run("full",30,418,wps,(0,))
    return L
