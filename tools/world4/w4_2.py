from dsl import *
def build():
    L=Lv(2,"ممر الجماجم",4200,4100); L.world=4
    for a,b in [(0,650),(735,1600),(1690,2650),(2740,3500),(3590,4200)]: L.ground(a,b)
    # سقف منخفض طوال الممر يقيّد القفز ويجعل المقذوفات أخطر
    L.ceil(520,1480,335); L.ceil(1700,2640,335); L.ceil(2760,3480,335)
    L.cp(60); L.skullturret(400); L.embers_line(100,360,412,4); L.ember(300,380)
    # أ: جماجم تطلق مقذوفات من الأمام
    L.cp(560); L.skullturret(900); L.skullturret(1180); L.spikes(1040,70); L.skeleton(1330,1200,1470)
    L.embers_line(600,1400,412,8)
    # ب: جمجمة طائرة تصوّب + أشواك تظهر
    L.cp(1730); L.flyskull(1900,1750,2050,330); L.tspikes(2000,60,120,60,0); L.skullturret(2300); L.spikes(2180,70)
    L.skeleton(2480,2350,2630); L.embers_line(1750,2600,412,8); L.fog(1690,2650,.8)
    # ج: ثلاث جماجم متتابعة تحت السقف
    L.cp(2780); L.skullturret(2950); L.skullturret(3150); L.flyskull(3050,2800,3250,335); L.spikes(3250,50)
    L.skullturret(3400); L.embers_line(2800,3450,412,8)
    # د: ساحة أخيرة مفتوحة
    L.cp(3620); L.skeleton(3800,3600,3960); L.flyskull(3900,3700,4100,320); L.spikes(3700,60); L.tspikes(4000,60,120,60,60)
    L.embers_line(3640,4100,412,6)
    L.auto_runs()
    return L
