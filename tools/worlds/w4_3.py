from dsl import *
def build():
    L=Lv(3,"قاعة السيوف",4400,4300); L.world=4
    L.ground(0,4400)
    L.cp(60); L.cp(900); L.cp(1845); L.cp(2800); L.cp(3680)
    # شفرات متحركة بتوقيت دقيق (كل مقطع نمط مختلف)
    L.blade(400,160,0,150); L.blade(650,150,2.0,150)
    L.blade(1050,190,0,150); L.blade(1300,190,3.1,150); L.spikes(1180,40)
    L.skeleton(1550,1400,1700); L.blade(1650,140,1.0,150)
    L.blade(1950,200,0,150); L.blade(2200,200,1.6,150); L.blade(2450,200,3.2,150)
    L.plat(2100,330,90); L.plat(2330,330,90)
    L.blade(2900,170,0,150); L.skeleton(3050,2950,3150); L.blade(3200,170,2.2,150); L.blade(3480,150,0.6,150)
    L.blade(3750,160,0,150); L.blade(3950,160,2.4,150); L.spikes(3880,40); L.skeleton(4150,4000,4290)
    L.embers_line(100,380,412,4); L.embers_line(450,1000,412,6); L.embers_line(1100,1700,412,6)
    L.embers_line(2000,2700,412,6); L.embers_line(2950,3500,412,6); L.embers_line(3700,4200,412,6)
    L.ember(2145,300); L.ember(2375,300)
    L.fog(1800,2800,.6)
    L.auto_runs()
    return L
