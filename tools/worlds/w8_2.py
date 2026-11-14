from dsl import *
def build():
    L=Lv(2,"قاعة التماثيل",3800,3700); L.world=8
    for a,b in [(0,1500),(1600,2700),(2800,3800)]: L.ground(a,b)
    L.cp(60); L.embers_line(100,300,412,3)
    # تماثيل تستيقظ عند الاقتراب (كمائن) وتماثيل حارسة
    for x in (500,820,1150): L.block(x+20,380,34); L.grave(x,0)
    L.enemy(5,1300,1200,1400); L.embers_line(560,800,412,3); L.plat(1530,408,60)
    L.cp(1610); L.grave(1800,0); L.block(1820,380,34); L.grave(2100,0); L.block(2120,380,34); L.enemy(5,2400,2250,2550)
    L.embers_line(1650,1780,412,2); L.embers_line(2180,2380,412,3); L.plat(2730,408,60)
    L.cp(2820); L.secret(2900); L.grave(3150,0); L.block(3170,380,34); L.grave(3350,0); L.enemy(5,3550,3420,3700)
    L.embers_line(3070,3140,412,2); L.embers_line(3400,3700,412,4)
    L.auto_runs()
    return L
