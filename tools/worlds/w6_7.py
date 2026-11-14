from dsl import *
def build():
    L=Lv(7,"القصر المتجمد",4800,4700); L.world=6
    L.ground(0,4800); L.slip(300,4800)
    L.cp(60); L.embers_line(100,420,412,4)
    # غرف متصلة: أبواب تحتاج مفاتيح
    L.ceil(520,1500,290); L.enemy(0,700,560,860); L.block(1000,380,40)
    L.plat(1100,360,90); L.key(1145,348,1450); L.enemy(0,1300,1160,1420)
    L.embers_line(560,980,412,4); L.ember(1020,345)
    L.cp(1560)
    L.ceil(1600,2800,290); L.fall(1,1750,80,0); L.enemy(0,1900,1700,2100)
    L.tspikes(2200,50,140,70,0); L.block(2400,380,40); L.plat(2500,360,90); L.key(2545,348,2750); L.enemy(0,2650,2480,2780)
    L.embers_line(1620,2150,412,5); L.ember(2420,345)
    L.cp(2850)
    L.fall(1,3000,80,0); L.enemy(0,3150,3000,3300); L.tspikes(3400,60,140,70,0)
    L.embers_line(2870,3380,412,6)
    L.cp(3550); L.block(3650,380,40); L.enemy(0,3850,3700,4000); L.tspikes(4100,60,140,70,40); L.enemy(0,4300,4250,4400); L.secret(4480)
    L.embers_line(3570,3640,412,2); L.embers_line(3720,4080,412,4); L.embers_line(4170,4240,412,2); L.embers_line(4660,4780,412,2)
    L.auto_runs(via={2:[(1145,342,14)],3:[(2545,342,14)]})
    return L
