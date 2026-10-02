"""size_lies.py: in out/asm_sweep.tsv (every non-OK assembler instance, real or pseudo mnemonic),
the defs whose written register NAMES differ from MAME's reading of the emitted bytes only in WIDTH
(xbc written, BC encoded; wa written, XWA encoded; c written, BC encoded ...) -- the class T1
deleted for the direct-address pseudos and fixed for MUL/DIV.  With tree usage of the mnemonic."""
import csv, collections, os, re, subprocess
import asm_sweep as A
fam = {}
for x in ("wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"):
    for n in (x, "x" + x):
        fam[n] = x
for a, b in (("a", "wa"), ("w", "wa"), ("c", "bc"), ("b", "bc"), ("e", "de"), ("d", "de"), ("l", "hl"), ("h", "hl")):
    fam[a] = b
by = collections.defaultdict(lambda: [0, None])
for r in csv.reader(open(os.path.join(A.V.OUT, "asm_sweep.tsv")), delimiter="\t"):
    if r[0] in ("class",) or r[0].startswith("ENC_"): continue
    cl, d, t, b, m, l = r
    x, y = A.regset(t, m)
    cx, cy = collections.Counter(x), collections.Counter(y)
    ox, oy = sorted((cx - cy).elements()), sorted((cy - cx).elements())
    if ox and oy and sorted(fam.get(q, q) for q in ox) == sorted(fam.get(q, q) for q in oy):
        by[d][0] += 1
        if by[d][1] is None: by[d][1] = (t, b, m)
ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm"
for d, (n, ex) in sorted(by.items(), key=lambda kv: -kv[1][0]):
    mn = ex[0].split()[0]
    tree = subprocess.run(["bash", "-c", "cd %s && git grep -h -I -a -c -w -P '^\\s*%s\\s' -- '*.s' '*.inc' | awk '{s+=$1} END{print s+0}'" % (ROOT, mn)], capture_output=True, text=True).stdout.strip()
    print("%-16s n=%-3d tree(%s)=%-5s e.g. %-30r -> %-14s = %r" % (d, n, mn, tree, ex[0], ex[1], ex[2]))
