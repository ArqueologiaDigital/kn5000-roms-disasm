#!/usr/bin/env python3
"""roundtrip_tree.py -- assemble -> llvm disassemble -> reassemble, for every tree line in the
families T1 touched ((R+)/(-R), :8/:16 displacement, direct (n:8/16/24), MUL/DIV, ldto_/ldfr_, ei,
and every line whose bytes start with a C4/C5/D4/D5/E4/E5/F4/F5 prefix).
Pass = the reassembled bytes equal the first assembly's bytes. Symbols are zeroed (fixups), so a
line's bytes are compared as assembled standalone.
Output: rt_fail.tsv"""
import os, re, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import strict_sweep as S, verify_respells as V, tree_audit as TA
HERE = os.path.dirname(os.path.abspath(__file__))
PAT = re.compile(r'\(\s*-\s*x|\bx\w+\s*\+\s*(:\d)?\s*\)|:(8|16|24)\)|^\s*(mul|muls|div|divs)\b|^\s*ldto_|^\s*ldfr_|^\s*ei\b', re.I)
cand = []
for f in TA.files():
    data = open(os.path.join(TA.REPO, f), "rb").read().decode("latin-1")
    inm = 0
    for n, line in enumerate(data.splitlines(), 1):
        s = V.strip(line); low = s.lower()
        if low.startswith(".macro"): inm += 1; continue
        if low.startswith(".endm"): inm = max(0, inm - 1); continue
        if inm or not V.is_insn(s): continue
        cand.append((f, n, s))
enc = V.encode([s for _, _, s in cand])
sel = [i for i, e in enumerate(enc) if e and (PAT.search(cand[i][2]) or e[0] in (0xc4,0xc5,0xd4,0xd5,0xe4,0xe5,0xf4,0xf5))]
print("selected lines:", len(sel))
blobs = [enc[i] + bytes(max(0, S.SLOT - len(enc[i]))) for i in sel]
ld = S.llvm_decode([enc[i] for i in sel])
texts = [(x[1] if x and not x[1].startswith("<unknown>") else None) for x in ld]
re_enc = S.llvm_encode([t or "nop" for t in texts])
c = collections.Counter(); rows = []
for i, l, t, e in zip(sel, ld, texts, re_enc):
    b = enc[i]
    if t is None: v = "NODECODE"
    elif l[0] != len(b): v = "LEN"
    elif e is None: v = "NOREENC"
    elif e == b"<fixup>": v = "FIXUP"
    elif e != b: v = "ASYM"
    else: v = "OK"
    c[v] += 1
    if v != "OK":
        rows.append((v, "%s:%d" % cand[i][:2], cand[i][2].replace("\t", " "), b.hex(" "), t or "", e.hex(" ") if isinstance(e, bytes) else ""))
for k, n in sorted(c.items()): print("  %-10s %7d" % (k, n))
with open(os.path.join(HERE, "rt_fail.tsv"), "w", encoding="latin-1") as fo:
    for r in rows: fo.write("\t".join(r) + "\n")
