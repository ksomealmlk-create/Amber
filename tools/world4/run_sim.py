# تشغيل المحاكي على مراحل العالم الرابع:  python3 run_sim.py w3_1 [W] [frames] [run-filter,...]
# متغير البيئة NODASH=1 يمنع الاندفاع (للتحقق من الطريق الرئيسي بدونه)
import sys, os, subprocess, importlib, tempfile
from dsl import *
def main():
    mod = sys.argv[1]
    W = sys.argv[2] if len(sys.argv) > 2 else "600"
    fr = sys.argv[3] if len(sys.argv) > 3 else "9000"
    filt = sys.argv[4].split(",") if len(sys.argv) > 4 and sys.argv[4] else None
    L = importlib.import_module(mod).build()
    d = tempfile.mkdtemp()
    f = os.path.join(d, "lv.txt")
    open(f, "w").write(L.sim_text(filt))
    here = os.path.dirname(os.path.abspath(__file__))
    r = subprocess.run([os.path.join(here, "sim"), f, W, fr], cwd=d, capture_output=True, text=True)
    print(r.stdout.strip())
    if r.stderr.strip(): print(r.stderr.strip()[:500])
    return r.returncode
if __name__ == "__main__":
    sys.exit(main())
