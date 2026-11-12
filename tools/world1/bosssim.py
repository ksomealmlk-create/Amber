import random, math, sys
FLOOR=440
LEN=1700
def cl(v,a,b): return a if v<a else (b if v>b else v)
class P: pass
LOG=[]
def run(seed, hp_boss=60, hammer=2, verbose=False, skill=1.0):
    rnd=random.Random(seed)
    # لاعب
    p=P(); p.x=500.0; p.y=418.0; p.vx=0; p.vy=0; p.g=True; p.hp=5; p.inv=0; p.atk=0; p.f=1; p.dcd=0; p.dash=0
    p.coy=8; p.jb=0
    # زعيم
    b=P(); b.x=1350.0; b.y=FLOOR-56; b.w=96; b.h=56; b.hp=float(hp_boss); b.maxhp=float(hp_boss); b.vy=0; b.st='intro'; b.t=0; b.cd=50
    b.dir=-1; b.stun=0; b.ph=1; b.enraged=False; b.hit=0; b.vx=0
    projs=[]; ens=[]
    plats=[(260,350,100),(640,330,100),(1000,330,100),(1330,350,100),(450,255,70),(830,250,70),(1180,255,70)]
    wires=[(560,412,110,28,150,70,0),(900,412,110,28,150,70,75),(1240,412,110,28,150,70,40)]
    t=0; shock=0; hitflag=False; atkcd=0; hurt_count=0
    def hurt(fx,lab='?'):
        nonlocal hurt_count
        if p.inv>0: return
        LOG.append((t,b.st,b.ph,round(b.hp),round(p.x),round(b.x),lab))
        if verbose and lab=='bosscontact': print('CONTACT',t,b.st,'boss',round(b.x),'p',round(p.x),'pvx',round(p.vx,1),'g',p.g)
        p.hp-=1; p.inv=70; p.vy=-5; p.vx=(-1 if p.x<fx else 1)*4.0; hurt_count+=1
    def pool(ph):
        if ph<=1: return ['charge','slam','charge','slam']
        if ph==2: return ['charge','slam','quake','rain']
        return ['charge','slam','quake','rain','web','quake']
    def solids():
        return [(a,b2,c,14) for a,b2,c in plats]
    while t<20000:
        t+=1
        # ---------------- زعيم
        b.t+=1
        if b.hit>0: b.hit-=1
        if b.st=='dead':
            return ('win',t,p.hp)
        r=b.hp/b.maxhp; np_=3 if r<=0.34 else (2 if r<=0.67 else 1)
        if b.st not in ('roar','intro') and np_>b.ph:
            b.ph=np_; b.st='roar'; b.t=0; projs.clear()
            if np_>=3: b.enraged=True
        sp=1.35 if b.enraged else 1.0
        landed=False
        b.vy+=.5; b.y+=b.vy
        if b.y+b.h>=FLOOR:
            b.y=FLOOR-b.h
            if b.vy>2: landed=True
            b.vy=0
        px=p.x+7
        if b.st=='intro':
            if b.t>70: b.st='idle'; b.t=0; b.cd=50
        elif b.st=='idle':
            b.dir=-1 if px<b.x+b.w/2 else 1
            b.x+=b.dir*0.7*sp; b.x=max(4,min(LEN-14-b.w,b.x)); b.cd-=1
            if b.cd<=0:
                pl=pool(b.ph); b.st=rnd.choice(pl); b.t=0
        elif b.st=='web':
            if b.t==28:
                n=5 if b.enraged else 3
                ox=b.x+b.w/2; oy=b.y+12; base=math.atan2((p.y+11)-oy,px-ox)
                for i in range(n):
                    a=base+(i-(n-1)/2)*0.22
                    projs.append([ox,oy,math.cos(a)*3.2*sp,math.sin(a)*3.2*sp,200,0])
            if b.t>56:
                b.st='stun'; b.t=0; b.stun=36
        elif b.st=='rain':
            if b.t%(8 if b.enraged else 12)==0 and b.t<100:
                tx=cl(px+(rnd.random()-.5)*240,20,LEN-20)
                projs.append([tx,-10,0,3.4*sp,220,2])
            if b.t>120: b.st='stun'; b.t=0; b.stun=40
        elif b.st=='charge':
            if b.t==1: b.dir=-1 if px<b.x+b.w/2 else 1
            if b.t>=32:
                b.x+=b.dir*(8.0 if b.enraged else 6.0)
                if b.x<=4 or b.x+b.w>=LEN-14:
                    b.x=max(4,min(LEN-14-b.w,b.x)); b.st='stun'; b.t=0; b.stun=110
        elif b.st=='slam':
            if b.t==1:
                b.vy=-12.5; dx=px-(b.x+b.w/2); b.vx=max(-6,min(6,dx/32))
            if b.t>1:
                b.x+=b.vx; b.x=max(4,min(LEN-14-b.w,b.x))
            if landed and b.t>8:
                s2=4.2 if b.enraged else 3.4
                projs.append([b.x+b.w/2,FLOOR-14,-s2,0,160,1]); projs.append([b.x+b.w/2,FLOOR-14,s2,0,160,1])
                if len([e for e in ens if e[3]>0])<1:
                    for i in range(1):
                        sx=b.x+(-20 if i==0 else b.w+6); nx=max(20,min(LEN-40,sx))
                        ens.append([nx,FLOOR-12,1,1,max(10,nx-160),min(LEN-20,nx+160)])  # x,y,d,hp,mn,mx
                b.st='stun'; b.t=0; b.stun=50
        elif b.st=='roar':
            if b.t%16==4 and b.t<80:
                tx=cl(px+(rnd.random()-.5)*200,20,LEN-20); projs.append([tx,-10,0,3.4,220,2])
            if b.t>90: b.st='idle'; b.cd=36
        elif b.st=='quake':
            qn=4 if b.ph>=3 else 3
            if b.t%34==20 and b.t<20+34*qn:
                qs=3.8 if b.ph>=3 else 3.2
                projs.append([b.x+b.w/2,FLOOR-14,-qs,0,170,1]); projs.append([b.x+b.w/2,FLOOR-14,qs,0,170,1])
            if b.t>20+34*qn+30: b.st='stun'; b.t=0; b.stun=70
        elif b.st=='stun':
            b.stun-=1
            if b.stun<=0: b.st='idle'; b.cd=40
        # ---------------- مقذوفات
        for q in projs:
            q[0]+=q[2]; q[1]+=q[3]; q[4]-=1
            h2=14 if q[5]==1 else 8
            if q[4]>0 and p.x<q[0]+4 and p.x+14>q[0]-4 and p.y<q[1]-4+h2 and p.y+22>q[1]-4:
                q[4]=0; hurt(q[0],'proj%d'%q[5])
            if q[5]!=1 and q[1]>FLOOR-2: q[4]=0
            if q[5]==2 and q[4]>0:
                for (a,b2,c,h) in solids():
                    if q[0]+3>a and q[0]-3<a+c and q[1]+3>b2 and q[1]-3<b2+h: q[4]=0; break
        projs=[q for q in projs if q[4]>0 and -20<q[0]<LEN+20]
        # ---------------- أعداء صغار
        for e in ens:
            if e[3]<=0: continue
            e[0]+=e[2]*0.7
            if e[0]<e[4]: e[2]=1
            if e[0]+18>e[5]: e[2]=-1
            if p.x<e[0]+18 and p.x+14>e[0] and p.y<e[1]+12 and p.y+22>e[1]: hurt(e[0]+9,'minion')
        # ---------------- أسلاك أرضية (مرحلة 3)
        for (wx,wy,ww,wh,per,on,ph) in wires:
            if b.ph>=3:
                m=(t+ph)%per
                if m<on and p.x<wx+ww and p.x+14>wx and p.y<wy+wh and p.y+22>wy: hurt(wx+ww/2,'wire')
        # ---------------- لاعب (سياسة)
        if p.inv>0: p.inv-=1
        if p.dcd>0: p.dcd-=1
        bc=b.x+b.w/2; dist=px-bc; adist=abs(dist)
        L=R=jump=dashb=attack=False
        sk=skill
        reactionok = (t%max(1,int(round(3/sk))))==0
        # تجنب الموجات الأرضية والمقذوفات
        danger_jump=False; dodge_dir=0
        for q in projs:
            if q[5]==1 and p.g:
                dx=q[0]-px
                if abs(dx)<70 and ((dx>0 and q[2]<0) or (dx<0 and q[2]>0)) and abs(dx)>10: danger_jump=True
            if q[5]==2 and q[1]>60 and abs(q[0]-px)<30: dodge_dir=1 if px>=q[0] else -1
            if q[5]==0 and p.g and abs(q[0]-px)<60 and abs(q[1]-(p.y+11))<25: danger_jump=True
        charge_jump=False
        gap_=(px-(bc+b.dir*48))*b.dir
        if b.st=='charge' and b.t>=28 and p.g and gap_>0 and gap_<(70 if not b.enraged else 85): charge_jump=True
        slam_flee = b.st=='slam' and b.t<45 and adist<150
        # أسلاك أرضية: ابتعد عن المنطقة قبل التشغيل
        wire_dodge=0
        if b.ph>=3:
            for (wx,wy,ww,wh,per,on,ph) in wires:
                m=(t+ph)%per
                if (m<on or m>per-30) and px>wx-16 and px<wx+ww+16:
                    wire_dodge= -1 if px-wx < wx+ww-px else 1
        if (danger_jump or charge_jump) and (reactionok or charge_jump): jump=True
        if dodge_dir: L=dodge_dir<0; R=dodge_dir>0
        elif wire_dodge: L=wire_dodge<0; R=wire_dodge>0; jump = jump or (rnd.random()<0.02)
        elif charge_jump: pass
        elif b.st=='charge' and b.t<22 and adist<190 and (px-bc)*b.dir>0:
            L=dist<0; R=dist>0
        elif b.st=='charge': pass
        elif slam_flee:
            fl=1 if dist>=0 else -1
            if adist<70 or True:
                L=fl<0; R=fl>0
            if b.t<4: pass
        elif any(e[3]>0 and abs((e[0]+9)-px)<48 and abs(e[1]-p.y)<30 for e in ens):
            attack=True
            for e in ens:
                if e[3]>0 and abs((e[0]+9)-px)<60: p.f=1 if e[0]+9>px else -1
        elif b.st=='stun':
            if adist>74:
                L=dist>0; R=dist<0
            else: attack=True
            if adist<=90: p.f=-1 if dist>0 else 1
        elif b.st=='idle':
            if adist<120: L=dist<0; R=dist>0
            elif adist>170: L=dist>0; R=dist<0
        elif b.st in ('quake','rain','web','roar','intro'):
            if adist<130 and b.st!='roar':
                L=dist<0; R=dist>0
        # الزاوية: اقفز فوق الزعيم واهرب للجهة الأخرى
        if (L and px<110) or (R and px>LEN-110):
            if b.st in ('idle','slam') and adist<130:
                jump=True; L,R=R,L
        # فيزياء اللاعب
        if jump and p.g: p.vy=-9.5; p.g=False
        if not jump and p.vy<-3.5 and not p.g: pass
        a=.95 if p.g else .62
        if L and not R: p.vx-=a; p.f=-1
        elif R and not L: p.vx+=a; p.f=1
        else: p.vx*= .7 if p.g else .93
        p.vx=max(-3,min(3,p.vx)); p.vy=min(11,p.vy+.5)
        p.x+=p.vx; p.x=max(0,min(LEN-30,p.x))
        # أرض/منصات
        p.y+=p.vy; p.g=False
        if p.y+22>=FLOOR:
            p.y=FLOOR-22; p.vy=0; p.g=True
        else:
            for (a2,b2,c,h) in solids():
                if p.vy>0 and p.x+14>a2 and p.x<a2+c and p.y+22>=b2 and p.y+22-p.vy<=b2+1:
                    p.y=b2-22; p.vy=0; p.g=True; break
        # هجوم
        if attack and p.atk<=0 and atkcd<=0: p.atk=26; hitflag=False; atkcd=26
        if atkcd>0: atkcd-=1
        if p.atk>0:
            if 8<p.atk<17 and not hitflag:
                abx=p.x+14 if p.f>0 else p.x-36
                if abx<b.x+b.w and abx+36>b.x and p.y-8<b.y+b.h and p.y+28>b.y and b.st not in ('roar','intro'):
                    hitflag=True
                    b.hp-=hammer*(2 if b.st=='stun' else 1); b.hit=10
                    if b.hp<=0: b.hp=0; b.st='dead'
                for e in ens:
                    if e[3]>0 and abx<e[0]+18 and abx+36>e[0] and abs(p.y-e[1])<30: e[3]=0
            p.atk-=1
        # تلامس الزعيم
        if b.st not in ('stun','dead','intro','roar') and p.x<b.x+b.w and p.x+14>b.x and p.y<b.y+b.h and p.y+22>b.y: hurt(bc,'bosscontact')
        if p.hp<=0: return ('lose',t,0)
    return ('timeout',t,p.hp)
if __name__=="__main__":
    n=int(sys.argv[1]) if len(sys.argv)>1 else 100
    hp=float(sys.argv[2]) if len(sys.argv)>2 else 60
    skill=float(sys.argv[3]) if len(sys.argv)>3 else 1.0
    res=[run(s,hp,2,False,skill) for s in range(n)]
    w=[r for r in res if r[0]=='win']
    print("win rate %.0f%%  avg time %.1fs  avg hp left %.1f  timeouts %d"%(100*len(w)/n, sum(r[1] for r in w)/max(1,len(w))/60, sum(r[2] for r in w)/max(1,len(w)), len([r for r in res if r[0]=='timeout'])))
