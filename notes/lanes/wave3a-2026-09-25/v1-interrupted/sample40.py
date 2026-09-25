# sample40.py: 40 random respelled lines across trees/commits, each with the bytes the pinned
# llvm-mc gives the new text and MAME unidasm's reading of those bytes (printed for eyeballing).
import random, sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import verify_respells as V, strict_sweep as S
random.seed(20260925)
commits = ["bc571542","166c9dc3","ff9bdf68","0ac50027","1485d941","e5f6cea1","c71a6d51","08896b73","96a03043"]
pool = []
for c in commits:
    for f, l in V.added_lines(c):
        s = V.strip(l)
        if V.is_insn(s): pool.append((c, f, s))
bytree = collections.defaultdict(list)
for p in pool: bytree[(p[0], p[1].split('/')[0])].append(p)
keys = sorted(bytree)
pick = []
while len(pick) < 40:
    k = random.choice(keys); pick.append(random.choice(bytree[k]))
enc = V.encode([p[2] for p in pick])
md = S.mame_decode(enc)
for p, e, m in zip(pick, enc, md):
    v = V.cmp_src(p[2], m[1]) if m else "NO_MAME"
    print("%-8s %-4s %-48s %-18s %-26s %s" % (p[0], p[1].split('/')[0], p[2].replace('\t',' ')[:48], e.hex(' '), m[1] if m else '', v))
