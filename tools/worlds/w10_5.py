from dsl import *
def build():
    L=Lv(5,"قاعة الفرسان",4400,4300); L.world=10
    L.ground(0,4400)
    L.cp(60); L.embers_line(100,300,412,3)
    # ممرات ضيقة بسقف منخفض وفرسان مدرعون (هياكل بثلاث ضربات)
    L.ceil(380,1300,310); L.enemy(5,800,500,1000); L.embers_line(420,1250,412,6)
    L.cp(1380); L.enemy(5,1650,1450,1800); L.spikes(1900,60); L.embers_line(1400,1850,412,5)
    L.cp(2100)
    L.ceil(2150,3100,310); L.enemy(5,2500,2200,2700); L.enemy(0,2900,2750,3050); L.crate(2380,FLOOR,2)
    L.embers_line(2170,3080,412,6); L.secret(3180)
    L.cp(3500); L.enemy(5,3700,3550,3850); L.enemy(5,4050,3900,4200); L.spikes(3950,40)
    L.embers_line(3520,4300,412,6)
    L.auto_runs()
    return L
