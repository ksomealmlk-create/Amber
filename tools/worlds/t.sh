#!/bin/bash
# اختبار مرحلة: ./t.sh W N [عرض الشعاع] [الإطارات] ← عدد الجولات الناجحة/الفاشلة (بدون اندفاع)
# إن وُجد إخفاق يُعاد الاختبار بشعاع أوسع (800) قبل الحكم
W=${3:-350}
run(){ NODASH=1 timeout 1800 python3 run_sim.py w$1_$2 $3 ${4:-6000} 2>&1; }
r=$(run $1 $2 $W $4)
if [ "$(echo "$r"|grep -c '^FAIL')" != "0" ]; then r=$(run $1 $2 800 $4); fi
if [ "$(echo "$r"|grep -c '^FAIL')" != "0" ]; then r=$(run $1 $2 1500 $4); fi
echo "W$1 L$2: OK=$(echo "$r"|grep -c '^OK') FAIL=$(echo "$r"|grep -c '^FAIL')"
echo "$r" | grep '^FAIL' | sed 's/frames=.*//' | head -${5:-8}
