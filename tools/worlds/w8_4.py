from dsl import *
def build():
    L=Lv(4,"ممر السهام",4200,4100); L.world=8
    L.ground(0,4200)
    L.cp(60); L.embers_line(100,300,412,3)
    # سهام تنطلق بتوقيت منتظم على ارتفاع القفز
    for i in range(3): L.beam(500+i*180,FLOOR-34,120,10,150,55,i*45)
    L.enemy(0,1100,980,1200); L.embers_line(520,1000,412,5)
    L.cp(1250)
    for i in range(4): L.beam(1400+i*160,FLOOR-30,100,10,140,50,i*35)
    L.tspikes(2100,60,140,70,0); L.enemy(5,2350,2200,2480)
    L.embers_line(1300,2050,412,6)
    L.cp(2600); L.crate(2700); L.beam(2850,FLOOR-34,140,10,130,50,0); L.beam(3050,FLOOR-34,140,10,130,50,65)
    L.plat(3250,370,80); L.chest(3270,356); L.ember(3290,335)
    L.embers_line(2620,3200,412,5)
    L.cp(3400); L.beam(3500,FLOOR-30,100,10,120,45,0); L.tspikes(3700,70,140,70,35); L.enemy(5,3950,3800,4100)
    L.embers_line(3420,3480,412,2); L.embers_line(3820,4180,412,4)
    L.auto_runs()
    return L
