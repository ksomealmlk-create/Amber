from dsl import *
def build():
    L=Lv(4,"الأنفاق المنهارة",4000,3900); L.world=9
    for a,b in [(0,1100),(1250,2000),(2150,3000),(3200,4000)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,420,412,4)
    # صخور تسقط وممرات تتغير (أرضية تنهار)
    L.fall(0,550,80,0); L.fall(0,800,80,40); L.enemy(0,950,850,1080); L.embers_line(580,780,412,4)
    for x in (1120,1170,1220): L.crum(x,420,40)
    L.cp(1270); L.fall(0,1450,70,0); L.fall(0,1650,70,35); L.crate(1800,FLOOR,2); L.embers_line(1290,1440,412,3); L.embers_line(1500,1780,412,4)
    L.plat(2030,408,60); L.crum(2070,410,60)
    L.cp(2170); L.fall(0,2350,70,0); L.fall(0,2550,70,35); L.fall(0,2750,70,15); L.enemy(5,2850,2700,2980)
    L.embers_line(2190,2340,412,3); L.embers_line(2400,2700,412,4)
    for x in (3030,3090,3150): L.crum(x,420,50)
    L.cp(3220); L.spikes(3400,60); L.fall(0,3550,70,0); L.enemy(0,3750,3600,3900); L.chest(3850,426)
    L.embers_line(3240,3380,412,3); L.embers_line(3620,3980,412,4)
    L.auto_runs()
    return L
