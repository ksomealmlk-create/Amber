from dsl import *
def build():
    L=Lv(6,"متاهة المعبد",4400,4300); L.world=8
    L.ground(0,4400)
    L.cp(60); L.embers_line(100,420,412,4)
    # طرق متفرعة: علوي (مكافأة) أو أرضي (فخاخ)، وأبواب سرية قابلة للتكسير
    L.plat(520,370,80); L.plat(650,330,80); L.plat(780,330,80); L.plat(910,370,80); L.chest(790,316)
    L.ember(560,335); L.ember(690,295); L.ember(820,295); L.tspikes(600,60,140,70,0); L.tspikes(760,60,140,70,70); L.enemy(5,1000,930,1080)
    L.cp(1150); L.secret(1250); L.embers_line(1170,1240,412,2)
    L.block(1500,380,40); L.plat(1460,370,70); L.plat(1600,330,70); L.plat(1740,370,70)
    L.ember(1495,335); L.ember(1635,295); L.enemy(0,1900,1780,2050)
    L.cp(2100); L.beam(2250,FLOOR-32,120,10,140,50,0); L.beam(2420,FLOOR-32,120,10,140,50,70); L.enemy(5,2700,2550,2800)
    L.embers_line(2120,2230,412,3); L.embers_line(2560,2790,412,4)
    L.cp(2900); L.secret(3000); L.crate(3300); L.enemy(5,3450,3330,3560); L.tspikes(3650,70,140,70,35)
    L.embers_line(2920,2990,412,2); L.embers_line(3350,3600,412,4)
    L.cp(3800); L.enemy(5,4050,3900,4200); L.embers_line(3820,4380,412,6)
    L.auto_runs()
    return L
