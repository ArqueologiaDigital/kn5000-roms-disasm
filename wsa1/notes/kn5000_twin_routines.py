#!/usr/bin/env python3
"""Which WSA1 routines have a structural twin among the KN5000's NAMED routines -- and do the two trees agree on the name?

QUESTION IT ANSWERS
  FINDINGS-kernel-in-the-kn5000.md showed the multitasking kernel is shared by the two products.  This
  asks the same of everything else: for every WSA1 prom_a / prom_b routine, is there a KN5000 routine
  (main program v10 or sub-CPU payload v1.42, any symbol not shaped like an address) with the same
  instruction sequence?  Both sides are decoded from the ROM bytes by MAME unidasm through
  kernel_structural_match's decoder, cut at the first `ret`, every 0x... literal masked; a candidate
  must share >= 3 token 5-grams, and the score is LCS / the longer length.
    default   the still-unnamed `sub_` routines (what a twin could help name)
    --named   the CONTROL: WSA1 routines that already carry a content name, printed beside their
              twin's KN5000 name.  ★ Read this before using any KN5000 name: identical code often
              carries contradictory names in the two trees (BStore_AppendBytes = VoiceSlot_AssignToChannel
              over 79 instructions; display-text-named WSA1 paints = KN5000 SeMenu_*_DataBlock*), so a
              twin is evidence that two routines are ONE routine, not that either tree's name is right.
  --named also prints how many pairs share at least one word of 3+ letters -- a crude agreement
  measure, an upper bound on "the trees agree" (MidiIn_ControlChange / MidiRx_ControlChange share
  ControlChange; so would two wrong names that share a word).
  Options: --min S (default 0.8), --minlen N (default 12 query instructions).

RUN (from wsa1/)
  python3 notes/kn5000_twin_routines.py --min 0.7            # unnamed WSA1 routines with a twin
  python3 notes/kn5000_twin_routines.py --min 0.9 --named    # the control
"""
import collections, os, re, sys
sys.path.insert(0, "notes")
import kernel_structural_match as K

MIN = float(sys.argv[sys.argv.index("--min") + 1]) if "--min" in sys.argv else 0.8
MINLEN = int(sys.argv[sys.argv.index("--minlen") + 1]) if "--minlen" in sys.argv else 12


def cut(seq, cap=120):
    out = []
    for t in seq.tok[:cap]:
        out.append(t)
        if t.startswith("ret"):
            break
    return out


def lcs(a, b):
    prev = [0] * (len(b) + 1)
    for x in a:
        cur = [0]
        for j, y in enumerate(b):
            cur.append(prev[j] + 1 if x == y else max(prev[j + 1], cur[j]))
        prev = cur
    return prev[-1]


def grams(t, k=5):
    return {tuple(t[i:i + k]) for i in range(len(t) - k + 1)}


# WSA1 queries
Q = {}
QNAME = {}
for key, path in (("wsa1:a", "prom_a/wsa1_prom_a.s"), ("wsa1:b", "prom_b/wsa1_prom_b.s")):
    txt = open(path, "rb").read().decode("latin-1")
    if "--named" in sys.argv:
        # named WSA1 routines (the control): a label followed within 3 lines by a `; ADDR` / `; ADDR  bytes` comment
        NAMED = {}
        L = txt.split("\n")
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if not m or m.group(1).startswith(("sub_", "T_F4", "DL_", "DisplayList", "Dispatch", "Table", "PtrTable")) or re.search(r'_(Skip|Join|Loop|Return|Nop)\d*$|_[0-9A-F]{6}$', m.group(1)):
                continue
            for j in range(i, min(i + 3, len(L))):
                mm = re.search(r';\s*(F[0-9A-F]{5})\b', L[j])
                if mm and not L[j].lstrip().startswith((".long", ".byte", ".short", ".ascii", ";")):
                    NAMED[int(mm.group(1), 16)] = m.group(1)
                    break
        addrs = sorted(NAMED)
        QNAME.update({(key, a): n for a, n in NAMED.items()})
    else:
        addrs = sorted({int(a, 16) for a in re.findall(r'^sub_(F[0-9A-F]{5}):', txt, re.M)})
    dec = K.decode_starts(key, [K.off_of(key, a) for a in addrs], 320)
    for a in addrs:
        s = dec.get(K.off_of(key, a))
        if s is None:
            continue
        t = cut(s)
        if len(t) >= MINLEN:
            Q[(key, a)] = t
print("queries", len(Q), file=sys.stderr)

BAD = re.compile(r'^(LABEL_|sub_|loc_|Data_|DAT_|byte_|word_|unk_|j_|nullsub)|_[0-9A-Fa-f]{6}$|^\.')
C = {}
for key, sym in (("kn5000:main", K.KN_MAINSYMS), ("kn5000:payload", K.KN_SUBSYMS)):
    cands = [c for c in K.symbol_candidates(key, sym) if not BAD.search(c[0])]
    dec = K.decode_starts(key, [c[2] for c in cands], 512)
    for name, addr, off in cands:
        s = dec.get(off)
        if s is None:
            continue
        t = cut(s, 200)
        if len(t) >= 6:
            C[(key, name, addr)] = t
print("candidates", len(C), file=sys.stderr)

idx = collections.defaultdict(set)
for k, t in C.items():
    for g in grams(t):
        idx[g].add(k)

rows = []
for qk, qt in Q.items():
    cnt = collections.Counter()
    for g in grams(qt):
        for ck in idx.get(g, ()):
            cnt[ck] += 1
    best = None
    for ck, n in cnt.most_common(25):
        if n < 3:
            break
        ct = C[ck]
        sc = lcs(qt, ct) / max(len(qt), len(ct))
        if best is None or sc > best[0]:
            best = (sc, ck, len(ct))
    if best and best[0] >= MIN:
        rows.append((best[0], qk, best[1], len(qt), best[2]))
rows.sort(reverse=True)
for sc, (qkey, qa), (ckey, cname, ca), nq, nc in rows:
    print("%.3f  %s %06X %-34s (%d)  ~  %s %-40s %06X (%d)" % (sc, qkey, qa, QNAME.get((qkey, qa), ""), nq, ckey, cname, ca, nc))
print("pairs >= %.2f: %d" % (MIN, len(rows)))
if "--named" in sys.argv:
    # crude agreement: do the two names share a word of 3+ letters (CamelCase / `_` split, case-folded)?
    def words(n):
        return {w.lower() for w in re.findall(r'[A-Z][a-z0-9]+|[A-Z]+(?![a-z])|[a-z]+', n) if len(w) >= 3}
    agree = sum(1 for _sc, qk, (_ck, cname, _ca), _nq, _nc in rows if words(QNAME.get(qk, "")) & words(cname))
    print("named pairs sharing a word: %d of %d" % (agree, len(rows)))
