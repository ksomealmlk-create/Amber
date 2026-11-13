#!/usr/bin/env python3
"""يحوّل كل مراحل العوالم 1-3 من ملفات Dart إلى scripts/levels/data_wN.gd
الاستعمال:  python3 tools/export_all.py path/to/lib/game
"""
import re, sys, os

NAMES = {
    1: ['مدخل الكهف', 'ممر الشرارات', 'جسور الهاوية', 'مصعد الأعماق', 'مطر الصخور',
        'سرداب المفاتيح', 'الدربان', 'مصنع الصواعق', 'محنة المغارة', 'عرين الحارس الحجري'],
    2: ['حافة الغابة', 'الجذور الملتوية', 'جسر الخيوط', 'ممر الأغصان', 'عش الصغار',
        'الغابة الهامسة', 'المستنقع الأخضر', 'الجسور المعلقة', 'وكر العناكب', 'عرين ملك العناكب'],
    3: ['مدخل الكهف', 'غابة الفطريات العملاقة', 'بحيرة السموم', 'ممر الجذور الحية', 'مستنقع الجراثيم',
        'متاهة الفطر', 'الهاوية الفطرية', 'قلب الكهف', 'مملكة الجراثيم', 'عرش الفطر السام'],
}

# اسم الحقل -> (اسم الصنف، عدد الحقول الكامل، قيم الإكمال للحقول الاختيارية)
LISTS = {
    'grounds': ('Box', 4, []),
    'platforms': ('Box', 4, []),
    'extra': ('Box', 4, []),
    'movs': ('MovSpec', 7, []),
    'crumbs': ('CrumbleSpec', 3, []),
    'hazards': ('HazardSpec', 5, []),
    'enemies': ('EnemySpawn', 5, ['-1.0']),
    'chests': ('ChestSpec', 2, []),
    'breaks': ('BreakSpec', 6, ['true']),
    'timed': ('TimedSpec', 9, ['0.0']),
    'falls': ('FallSpec', 4, []),
    'rolls': ('RollSpec', 5, []),
    'springs': ('SpringSpec', 3, ['1.0']),
    'keyDoors': ('KeyDoorSpec', 4, ['440.0']),
    'vanish': ('VanishSpec', 6, ['false']),
    'slips': ('SlipSpec', 2, []),
    'ambush': ('AmbushSpec', 3, ['true']),
    'checks': ('CheckSpec', 2, []),
    'bubbles': ('BubbleSpec', 6, []),
    'fogs': ('FogSpec', 3, ['1.0']),
}


def match_bracket(s, i):
    """s[i] == '[' -> فهرس القوس المغلق المقابل"""
    depth = 0
    for j in range(i, len(s)):
        if s[j] == '[':
            depth += 1
        elif s[j] == ']':
            depth -= 1
            if depth == 0:
                return j
    raise ValueError('bracket')


def get_list(body, name):
    m = re.search(r'\n\s{6}%s:\s*\[' % name, body)
    if not m:
        return None
    i = body.index('[', m.start())
    return body[i + 1:match_bracket(body, i)]


def num(a):
    a = a.strip()
    if a in ('true', 'false'):
        return a
    return repr(float(a))


def parse_calls(txt, cls):
    rows = []
    for m in re.finditer(r'\b%s\(([^()]*)\)' % cls, txt):
        rows.append([num(x) for x in m.group(1).split(',') if x.strip()])
    return rows


def fmt_rows(rows, full, extra):
    out = []
    for r in rows:
        r = list(r)
        k = 0
        while len(r) < full and k < len(extra):
            r.append(extra[k])
            k += 1
        out.append('[' + ', '.join(r) + ']')
    return '[' + ',\n\t\t'.join(out) + ']'


def export_level(body, world, idx):
    L = []
    length = float(re.search(r'length:\s*([\d.]+)', body).group(1))
    gx = float(re.search(r'goalX:\s*([\d.]+)', body).group(1))
    gym = re.search(r'goalY:\s*([\d.]+)', body)
    gy = float(gym.group(1)) if gym else 370.0
    seed = re.search(r'seed:\s*(\d+)', body)
    L.append('\t{')
    L.append('\t\t"world": %d, "index": %d, "name": "%s", "length": %r,' % (world, idx, NAMES[world][idx - 1], length))
    L.append('\t\t"goal": [%r, %r], "seed": %s,' % (gx, gy, seed.group(1) if seed else '1'))
    for name, (cls, full, extra) in LISTS.items():
        txt = get_list(body, name)
        rows = parse_calls(txt, cls) if txt else []
        L.append('\t\t"%s": %s,' % (name, fmt_rows(rows, full, extra)))
    emb = get_list(body, 'embers') or ''
    pts = re.findall(r'\[\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\]', emb)
    L.append('\t\t"embers": [' + ', '.join('[%r, %r]' % (float(a), float(b)) for a, b in pts) + '],')
    b = re.search(r"BossSpec\('([^']*)',\s*(\d+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)", body)
    if b:
        L.append('\t\t"boss": ["%s", %s, %r, %r, %r],' % (b.group(1), b.group(2), float(b.group(3)), float(b.group(4)), float(b.group(5))))
    else:
        L.append('\t\t"boss": [],')
    L.append('\t},')
    return '\n'.join(L)


def main():
    src_dir = sys.argv[1]
    os.makedirs('scripts/levels', exist_ok=True)
    for w in (1, 2, 3):
        src = open(os.path.join(src_dir, 'world%d.dart' % w), encoding='utf-8').read()
        out = ['# مولَّد تلقائياً من world%d.dart بواسطة tools/export_all.py — لا تعدّله يدوياً' % w,
               'extends RefCounted', '', 'const LEVELS = [']
        for i in range(1, 11):
            m = re.search(r'static LevelConfig level%d\(\) \{(.*?)\n  \}\n' % i, src, re.S)
            out.append(export_level(m.group(1), w, i))
        out.append(']')
        path = 'scripts/levels/data_w%d.gd' % w
        open(path, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
        print('wrote', path)


main()
