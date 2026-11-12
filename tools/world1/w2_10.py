from dsl import *
def build():
    L=Lv(10,"عرين ملك العناكب",1400,1300); L.world=2
    L.ground(0,1400)
    L.cp(60); L.cp(330)
    L.plat(220,350,100); L.plat(645,325,110); L.plat(1060,350,100); L.plat(445,270,80)
    L.chest(690,311)
    for x,y in [(260,320),(485,240),(700,295),(1100,320)]: L.ember(x,y)
    L.embers_line(120,360,412,4); L.embers_line(500,1000,412,6)
    L.boss=("ملك العناكب",0,1050,380,44)
    return L
