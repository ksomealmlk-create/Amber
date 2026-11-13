#!/usr/bin/env python3
"""يحوّل مرحلة من world1.dart إلى GDScript (level_data.gd).
الاستعمال: python3 tools/export_level.py path/to/world1.dart 1 > scripts/level_data.gd
"""
import re, sys


def args_of(s):
    return [(m.group(1), m.group(2)) for m in re.finditer(r'(\w+)\(([^()]*)\)', s)]


def nums(txt):
    res = []
    for a in txt.split(','):
        a = a.strip()
        if not a:
            continue
        if a in ('true', 'false'):
            res.append(a)
        else:
            res.append(repr(float(a)))
    return res


def field(body, name):
    m = re.search(name + r':\s*\[(.*?)\],\n', body, re.S)
    return m.group(1) if m else ''


def main():
    src = open(sys.argv[1], encoding='utf-8').read()
    idx = int(sys.argv[2])
    m = re.search(r'static LevelConfig level%d\(\) \{(.*?)\n  \}\n' % idx, src, re.S)
    body = m.group(1)

    def lst(name, cls, fill=None):
        rows = []
        for c, a in args_of(field(body, name)):
            if c != cls:
                continue
            v = nums(a)
            if fill:
                v = fill(v)
            rows.append('[' + ', '.join(v) + ']')
        return '[' + ',\n\t\t'.join(rows) + ']'

    def pad(n, extra):
        def f(v):
            v = list(v)
            if len(v) == n:
                v.append(extra)
            return v
        return f

    emb = re.findall(r'\[([\d.\-]+), ([\d.\-]+)\]', field(body, 'embers'))
    embs = '[' + ', '.join('[%r, %r]' % (float(a), float(b)) for a, b in emb) + ']'
    length = float(re.search(r'length:\s*([\d.]+)', body).group(1))
    gx = float(re.search(r'goalX:\s*([\d.]+)', body).group(1))
    gy = float(re.search(r'goalY:\s*([\d.]+)', body).group(1))
    names = ['مدخل الكهف', 'ممر الشرارات', 'جسور الهاوية', 'مصعد الأعماق', 'مطر الصخور',
             'سرداب المفاتيح', 'الدربان', 'مصنع الصواعق', 'محنة المغارة', 'عرين الحارس الحجري']
    out = []
    out.append('# مولَّد تلقائياً من world1.dart بواسطة tools/export_level.py — لا تعدّله يدوياً')
    out.append('extends RefCounted\n')
    out.append('const LEVEL = {')
    out.append('\t"world": 1, "index": %d, "name": "%s", "length": %r,' % (idx, names[idx - 1], length))
    out.append('\t"goal": [%r, %r],' % (gx, gy))
    out.append('\t"grounds": ' + lst('grounds', 'Box') + ',')
    out.append('\t"platforms": ' + lst('platforms', 'Box') + ',')
    out.append('\t"extra": ' + lst('extra', 'Box') + ',')
    out.append('\t"movs": ' + lst('movs', 'MovSpec') + ',')
    out.append('\t"crumbs": ' + lst('crumbs', 'CrumbleSpec') + ',')
    out.append('\t"hazards": ' + lst('hazards', 'HazardSpec') + ',')
    out.append('\t"enemies": ' + lst('enemies', 'EnemySpawn', pad(4, '-1.0')) + ',')
    out.append('\t"embers": ' + embs + ',')
    out.append('\t"chests": ' + lst('chests', 'ChestSpec') + ',')
    out.append('\t"breaks": ' + lst('breaks', 'BreakSpec', pad(5, 'true')) + ',')
    out.append('\t"timed": ' + lst('timed', 'TimedSpec', pad(8, '0.0')) + ',')
    out.append('\t"falls": ' + lst('falls', 'FallSpec') + ',')
    out.append('\t"vanish": ' + lst('vanish', 'VanishSpec', pad(5, 'false')) + ',')
    out.append('\t"checks": ' + lst('checks', 'CheckSpec') + ',')
    out.append('}')
    print('\n'.join(out))


main()
