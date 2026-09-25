# check_dis_lit.py: every "CHECK: <text>{{.*}}encoding: [bytes]" / "CHECK: <text> ; encoding" line in the
# TLCS900 disassembler lit tests, text compared to MAME unidasm's reading of the bytes.
import re, sys, os, glob, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import verify_respells as V, strict_sweep as S
D = "/home/fsanches/compartilhado/llvm-project/llvm/test/MC/Disassembler/TLCS900/"
pairs = []
for f in sorted(glob.glob(D + "*.txt")):
    lines = open(f).read().splitlines()
    for i, ln in enumerate(lines):
        m = re.match(r'#\s*CHECK[^:]*:\s*(.*?)\s*(\{\{.*?\}\}|;)\s*encoding:\s*\[([^\]]*)\]', ln)
        if m:
            try: b = bytes(int(x, 16) for x in m.group(3).split(','))
            except ValueError: continue
            pairs.append((os.path.basename(f), m.group(1).replace('\t', ' '), b))
            continue
        m = re.match(r'#\s*CHECK[^:]*:\s*(\S.*?)\s*$', ln)
        if m and i + 1 < len(lines) and re.match(r'^\s*0x[0-9a-f]{2}(\s+0x[0-9a-f]{2})*\s*$', lines[i+1], re.I):
            b = bytes(int(x, 16) for x in lines[i+1].split())
            pairs.append((os.path.basename(f), m.group(1).replace('\t', ' ').replace('{{.*}}', ''), b))
md = S.mame_decode(pairs and [p[2][:16] for p in pairs])
c = collections.Counter()
for (f, t, b), m in zip(pairs, md):
    if m is None: v = "NO_MAME"
    elif m[1].split()[0].lower() == 'db': v = "MAME_DB"
    elif m[0] != len(b): v = "LEN(%d/%d)" % (m[0], len(b))
    else:
        try: v = V.cmp_src(t, m[1])
        except Exception: v = "ERR"
    c[(f, v)] += 1
    if v != "OK": print("%-10s %-26s %-40s %-22s %s" % (v, f, t[:40], b.hex(' '), m[1] if m else ''))
for k, n in sorted(c.items()): print(n, k)
