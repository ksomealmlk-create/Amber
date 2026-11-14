from dsl import *
def build():
    L=Lv(7,"غرفة الليزر",4000,3900); L.world=9
    L.ground(0,4000)
    L.cp(60); L.embers_line(100,300,412,3)
    # أشعة ليزر عمودية تعمل وتتوقف بتوقيت
    for i in range(3): L.beam(500+i*170,FLOOR-110,14,110,150,55,i*50)
    L.enemy(0,1050,950,1150); L.embers_line(520,900,412,5)
    L.cp(1200)
    for i in range(4): L.beam(1350+i*150,FLOOR-110,14,110,140,55,(i%2)*70)
    L.enemy(5,2100,1950,2250); L.embers_line(1230,1330,412,2); L.embers_line(1950,2250,412,4)
    L.cp(2350); L.beam(2500,FLOOR-110,14,110,130,50,0); L.tspikes(2600,70,130,50,0)
    L.beam(2750,FLOOR-110,14,110,130,50,65); L.tspikes(2850,70,130,50,65); L.chest(3000,426)
    L.embers_line(2370,2480,412,3); L.embers_line(2900,3200,412,5)
    L.cp(3300)
    for i in range(3): L.beam(3450+i*140,FLOOR-110,14,110,120,48,i*40)
    L.enemy(5,3850,3700,3950); L.embers_line(3320,3430,412,2); L.embers_line(3700,3980,412,4)
    L.auto_runs()
    return L
