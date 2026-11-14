#!/bin/bash
# اختبار مرحلة: ./t.sh N [عرض الشعاع] [الإطارات] ← يطبع عدد الجولات الناجحة/الفاشلة (بدون اندفاع)


r=$(NODASH=1 timeout 900 python3 run_sim.py w4_$1 ${2:-400} ${3:-7000} 2>&1)
echo "L$1: OK=$(echo "$r"|grep -c '^OK') FAIL=$(echo "$r"|grep -c '^FAIL')"
echo "$r" | grep '^FAIL' | sed 's/frames=.*//' | head -${4:-8}
