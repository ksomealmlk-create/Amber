from dsl import *
def build():
    L=Lv(8,"ممر التنين",5200,5100); L.world=5
    L.ground(0,5200)
    L.cp(60); L.embers_line(100,500,412,4)
    # ممر طويل بسقف: عدو ناري يطلق هجمات متقطعة (أبراج + جماجم طائرة) وألسنة لهب
    L.ceil(560,5100,300)
    L.skullturret(700); L.fount(900,40,80,150,60,0); L.enemy(0,1050,900,1200)
    L.embers_line(580,1200,412,6)
    L.cp(1300); L.skullturret(1450); L.fount(1600,40,80,150,60,75); L.fount(1760,40,80,150,60,0); L.flyskull(1900,1700,2100,330)
    L.embers_line(1320,2100,412,7)
    L.cp(2200); L.crate(2300,FLOOR,2); L.skullturret(2450); L.fount(2600,40,80,140,60,0); L.fount(2760,40,80,140,60,70); L.enemy(0,2700,2640,2830)
    L.secret(2860); L.embers_line(2220,2840,412,5)
    L.cp(3100); L.rollk(1,3200,3900,120,0); L.skullturret(3300); L.flyskull(3600,3400,3800,320)
    L.embers_line(3120,3900,412,7)
    L.cp(4000); L.fount(4100,40,80,140,60,0); L.skullturret(4250); L.fount(4400,40,80,140,60,70); L.fount(4560,40,80,140,60,35); L.enemy(0,4700,4600,4850)
    L.embers_line(4020,4900,412,8)
    L.cp(4950); L.chest(4990,426)
    L.auto_runs()
    return L
