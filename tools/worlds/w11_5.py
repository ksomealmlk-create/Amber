from dsl import *
def build():
    L=Lv(5,"ممر العوالم",5200,5100); L.world=11
    L.ground(0,5200)
    L.cp(60); L.embers_line(100,300,412,3)
    # ممر عقبات من العوالم السابقة: حمم (5) ثم جليد (6) ثم مقبرة (7) ثم معبد (8) ثم منجم (9)
    L.fount(450,44,90,150,60,0); L.fount(650,44,90,150,60,75); L.enemy(0,800,700,950); L.embers_line(330,430,412,2); L.embers_line(500,620,412,2); L.embers_line(700,950,412,3)
    L.cp(1050); L.slip(1100,2000); L.spikes(1350,60); L.enemy(0,1700,1500,1900); L.embers_line(1070,1330,412,3); L.embers_line(1450,1950,412,4)
    L.cp(2100); L.grave(2300); L.grave(2600); L.enemy(5,2800,2650,2950); L.embers_line(2120,2280,412,3); L.embers_line(2350,2580,412,3)
    L.cp(3100); L.beam(3300,FLOOR-110,14,110,120,50,0); L.beam(3500,FLOOR-110,14,110,120,50,60); L.enemy(5,3750,3600,3900); L.embers_line(3120,3280,412,3); L.embers_line(3560,3900,412,4)
    L.cp(4000); L.fall(0,4200,70,0); L.fall(0,4400,70,35); L.crate(4600,FLOOR,2); L.secret(4800); L.embers_line(4020,4180,412,3); L.embers_line(4250,4580,412,4)
    L.auto_runs()
    return L
