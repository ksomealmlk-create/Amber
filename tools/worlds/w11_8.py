from dsl import *
def build():
    L=Lv(8,"حراس النهاية",4600,4500); L.world=11
    L.ground(0,4600)
    L.cp(60); L.embers_line(100,300,412,3)
    # مواجهات متتابعة: ساحات يحرسها أعداء النخبة مع فخاخ تفصل بينها
    L.enemy(5,600,450,750); L.enemy(5,850,750,1000); L.crate(1100,FLOOR,2); L.embers_line(330,1050,412,6)
    L.cp(1200); L.spikes(1300,60); L.enemy(5,1550,1400,1700); L.enemy(0,1750,1650,1900); L.embers_line(1220,1280,412,2); L.embers_line(1400,1900,412,5)
    L.cp(2050); L.tspikes(2200,60,140,70,0); L.enemy(5,2450,2300,2600); L.enemy(5,2700,2600,2850); L.chest(2900,426); L.embers_line(2070,2180,412,2); L.embers_line(2300,2850,412,5)
    L.cp(3000); L.beam(3150,FLOOR-110,14,110,120,50,0); L.enemy(5,3400,3250,3550); L.enemy(5,3650,3550,3800); L.enemy(5,3900,3800,4050); L.embers_line(3020,3130,412,2); L.embers_line(3250,4050,412,6)
    L.cp(4100); L.secret(4250); L.embers_line(4120,4230,412,2); L.embers_line(4450,4580,412,2)
    L.auto_runs()
    return L
