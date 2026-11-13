from dsl import *
def build():
    L=Lv(8,"الجسور المعلقة",4500,4400); L.world=2
    for a,b in [(0,350),(1100,1200),(2000,2100),(2900,3000),(3700,4500)]: L.ground(a,b)
    L.crate(150); L.cp(50)
    L.ceil(380,1100,300) if False else None
    for i in range(10): L.crum(360+i*74,400-(i%3)*10,56)
    L.blade(0,0) if False else None
    for x,ph in [(500,0),(720,2.5)]: L.rock(x,100,int(ph*20))
    L.enemy(1,800,400,1090,330)
    L.cp(1110)
    for i in range(11): L.crum(1220+i*72,380+(i%2)*14,52)
    L.rock(1500,90,0); L.rock(1650,90,45); L.rock(1800,90,20)
    L.cp(2010)
    L.ceil(2100,2900,330)
    for i in range(7): L.crum(2120+i*110,396,54)
    L.mov(2150,380,64,0,0,.02,0) if False else None
    L.cp(2910)
    L.mov(3030,396,64,40,0,.03,0); L.mov(3160,380,64,0,50,.032,1.0); L.mov(3290,396,64,40,0,.03,2.0); L.mov(3430,380,64,0,50,.032,3.0)
    L.enemy(1,3300,3100,3600,300)
    L.cp(3710)
    L.enemy(2,3850,3740,3960); L.blade(4000,110,0); L.blade(4200,110,3.0); L.spikes(4380,40)
    L.embers_line(3720,4450,410,10)
    L.embers_line(380,1080,360,8); L.embers_line(1230,2000,340,8); L.embers_line(2120,2880,360,7)
    L.run("full",30,418,[(1110,418,16),(2010,418,16),(2910,418,16),(3710,418,16),(4400,418,22)])
    return L
