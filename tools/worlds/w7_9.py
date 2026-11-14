from dsl import *
def build():
    L=Lv(9,"سرداب الحارس",4000,3900); L.world=7
    L.ground(0,4000)
    L.cp(60); L.embers_line(100,420,412,4)
    # غرفة واسعة وفخاخ متتابعة
    for i in range(4): L.tspikes(520+i*150,60,150,75,i*40)
    L.enemy(0,1020,950,1100); L.embers_line(560,1000,412,5)
    L.cp(1180)
    L.blade(1350,60,0,140); L.blade(1520,60,70,140); L.rock(1700,90,0); L.rock(1820,90,45)
    L.enemy(5,2000,1900,2120); L.embers_line(1220,1330,412,3); L.embers_line(1600,1900,412,4)
    L.cp(2160)
    # ممر سري: جدار قابل للتكسير يؤدي إلى غرفة كنز، يتجاوز الفخاخ التالية
    L.secret(2300); L.embers_line(2180,2290,412,3)
    for i in range(3): L.fount(2600+i*130,40,80,170,70,i*50)
    L.enemy(5,3050,2950,3150)
    L.cp(3200); L.tspikes(3300,70,140,70,0); L.blade(3450,60,35,140); L.crate(3600); L.enemy(5,3750,3650,3900)
    L.embers_line(3220,3280,412,2); L.embers_line(3500,3950,412,6)
    L.auto_runs()
    return L
