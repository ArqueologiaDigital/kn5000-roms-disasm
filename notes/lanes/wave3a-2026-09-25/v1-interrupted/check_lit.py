# check_lit.py: for the MC tests T1 added, pair every CHECK line's text with its encoding bytes and
# compare the text with MAME unidasm's reading of the bytes (verify_respells.cmp_src).
import re, sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import verify_respells as V, strict_sweep as S
T = "/home/fsanches/compartilhado/llvm-project/llvm/test/MC/TLCS900/"
files = ["postinc-predec.s", "disp-width.s", "muldiv-registers.s", "erp-ld-direction.s", "system.s", "addressing-modes.s"]
pairs = []
for f in files:
    for ln in open(T + f):
        m = re.search(r'CHECK[^:]*:\s*(.*?)\s*;\s*encoding:\s*\[([^\]]*)\]', ln)
        if m:
            try:
                b = bytes(int(x, 16) for x in m.group(2).split(','))
            except ValueError:
                continue
            pairs.append((f, m.group(1).replace('\t', ' '), b))
md = S.mame_decode([p[2] for p in pairs])
c = collections.Counter()
for (f, t, b), m in zip(pairs, md):
    if m is None or m[0] != len(b):
        v = "LEN/NONE"
    else:
        v = V.cmp_src(t, m[1])
    c[(f, v)] += 1
    if v != "OK":
        print(v, f, t, b.hex(' '), m[1] if m else '')
for k, n in sorted(c.items()): print(n, k)
