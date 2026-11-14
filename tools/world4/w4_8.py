from dsl import *
def build():
    L=Lv(8,"سرداب الملك",4800,4700); L.world=4
    for a,b in [(0,880),(965,2020),(2105,3300),(3385,4800)]: L.ground(a,b)
    L.fog(0,4800,.55)
    # أ: السرداب: سقف منخفض وهياكل مطاردة
    L.ceil(250,860,335)
    L.cp(60); L.skullturret(330); L.spikes(420,50); L.skeleton(520,400,640); L.skeleton(740,620,860)
    L.embers_line(100,860,412,8); L.cp(800)
    # ب: ممر ألواح الضغط تحت سقف
    L.ceil(1000,1950,335)
    L.cp(1010); L.plate(1090,0); L.trap(1170,70,28,0,100); L.plate(1300,1); L.trap(1380,60,28,1,100)
    L.skeleton(1560,1450,1700); L.tspikes(1760,50,120,60,0); L.skullturret(1900)
    L.embers_line(1050,1900,412,8)
    # ج: درج مخفي إلى المفتاح + باب + غرفة كنز سرية
    L.cp(2130)
    L.van(2170,370,60,0,0,True); L.van(2250,300,60,0,0,True); L.plat(2330,235,110); L.key(2385,223,3000)
    L.flyskull(2560,2420,2720,300); L.skeleton(2640,2500,2780); L.skullturret(2900)
    L.plat(2640,365,60); L.plat(2705,295,150); L.wall(2705,295); L.chest(2800,281)
    L.cp(3050); L.skeleton(3150,3050,3280)
    L.ember(2200,335); L.ember(2280,265); L.ember(2380,205); L.embers_line(2740,2840,265,3)
    # د: القاعة الأخيرة: مفتاح ثانٍ + فؤوس + أعداء أقوى
    L.cp(3410); L.axe(3480,200,380,60,96,0); L.plat(3720,365,90); L.key(3765,353,4300)
    L.skeleton(3640,3500,3780); L.flyskull(3900,3780,4100,290); L.skeleton(4000,3900,4150)
    L.axe(3985,150,320,70,86,1.4); L.cp(4180); L.tspikes(4230,50,110,55,0)
    L.skeleton(4450,4330,4600); L.skullturret(4640)
    L.embers_line(3430,3700,412,5); L.embers_line(3900,4200,412,5); L.embers_line(4350,4600,412,4)
    via={}
    pts=[30]+sorted(c[0] for c in L.checks)
    for i,x in enumerate(pts):
        if x==2130: via[i]=[(2200,348,14),(2280,278,14),(2380,213,14)]
        if x==3410: via[i]=[(3758,342,14)]
    L.auto_runs(via=via)
    L.run("secret_chest",2130,418,[(2670,343,14),(2730,273,14),(2790,262,14)],(0,))
    return L
