from dsl import *
def build():
    L=Lv(6,"المكتبة المظلمة",4400,4300); L.world=10
    for a,b in [(0,1200),(1350,2400),(2550,3300),(3450,4400)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,380,412,3); L.enemy(0,700,500,1000)
    # رفوف متحركة تعبر الفجوات
    L.mov(1190,410,80,70,0,.026,0); L.ember(1260,375)
    L.cp(1360); L.van(1650,400,90,260,0,True); L.van(1790,360,90,260,130,True); L.enemy(5,1950,1700,2150)
    L.embers_line(1380,1620,412,3); L.embers_line(2000,2300,412,4)
    L.mov(2390,410,80,70,0,.026,1.0)
    L.cp(2560); L.secret(2650); L.enemy(0,3000,2800,3200); L.embers_line(2580,2640,412,2); L.embers_line(2850,3250,412,5)
    L.mov(3290,410,80,70,0,.026,2.0)
    L.cp(3460); L.enemy(5,3700,3550,3850); L.crate(4000,FLOOR,2); L.embers_line(3480,4300,412,6)
    L.auto_runs()
    return L
