from dsl import *
def build():
    L=Lv(6,"بحيرة الكريستال",4200,4100); L.world=9
    L.ground(0,4200)
    L.cp(60); L.embers_line(100,420,412,4); L.enemy(0,600,450,800)
    # منصات فوق الماء وبلورات (جمرات) قابلة للجمع فوقها
    L.lake(900,700)
    for i,x in enumerate(range(940,1560,130)): L.plat(x,390-(i%2)*40,80); L.ember(x+40,350-(i%2)*40); L.ember(x+40,320-(i%2)*40)
    L.cp(1650); L.enemy(0,1850,1700,2000); L.embers_line(1670,1990,412,4)
    L.lake(2100,800)
    L.plat(2130,390,70); L.mov(2260,370,80,40,0,.028,0); L.plat(2440,350,90); L.plat(2580,310,80); L.plat(2710,350,80); L.mov(2840,380,80,40,0,.028,1.5)
    L.ember(2170,355); L.ember(2620,275); L.chest(2600,296)
    L.cp(2950); L.enemy(5,3150,3000,3300); L.embers_line(2970,3300,412,4)
    L.lake(3400,400); L.plat(3440,390,70); L.plat(3570,350,70); L.plat(3700,390,70)
    L.ember(3600,315); L.ember(3480,355)
    L.cp(3830); L.enemy(5,4000,3880,4150); L.embers_line(3850,4180,412,5)
    L.auto_runs()
    return L
