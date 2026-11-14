from dsl import *
def build():
    L=Lv(4,"كهف البلورات",4200,4100); L.world=6
    L.ground(0,4200); L.slip(1200,3000)
    L.cp(60); L.embers_line(100,420,412,4)
    # بلورات تعيق الطريق (تُكسر بالضرب) + ممرات سرية ومكافآت
    L.crystal(520); L.crystal(560); L.enemy(0,700,600,850); L.embers_line(440,490,412,2)
    L.cp(900); L.secret(1000); L.crystal(1260); L.crystal(1296); L.enemy(0,1400,1320,1560)
    L.embers_line(920,980,412,2); L.embers_line(1160,1230,412,2); L.embers_line(1340,1560,412,3)
    L.cp(1650); L.plat(1750,370,90); L.plat(1890,320,90); L.chest(1920,306); L.crystal(2050); L.crystal(2086); L.crystal(2122)
    L.ember(1795,335); L.ember(1935,285)
    L.embers_line(1670,1730,412,2); L.embers_line(2160,2360,412,3)
    L.cp(2400); L.fall(4,2550,80,0); L.fall(4,2700,80,40); L.enemy(0,2800,2650,2950); L.secret(2900)
    L.embers_line(2420,2520,412,2); L.embers_line(2580,2850,412,4)
    L.cp(3100); L.crystal(3250); L.crystal(3286); L.crystal(3322); L.enemy(0,3500,3350,3650); L.crystal(3750)
    L.embers_line(3120,3220,412,2); L.embers_line(3360,3720,412,5)
    L.cp(3900); L.embers_line(3920,4180,412,4)
    L.auto_runs(via={3:[(1795,348,14),(1935,298,14)]})
    return L
