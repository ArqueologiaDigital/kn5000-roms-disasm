#!/usr/bin/env python3
"""Union of independent corroborations, per range, and the residue."""
import json, os, pickle, re, collections
S = os.environ["SCRATCH"]
cases = sorted(pickle.load(open(os.path.join(S, "cases.pkl"), "rb"))["cases"], key=lambda c: c["entry"])
dec = {r["entry"]: r for r in json.load(open(os.path.join(S, "decide.json")))}
BR = re.compile(r'^(jr|jrl|calr)\s+(?:(\w+),\s*)?0x([0-9a-fA-F]+)$', re.I)
LDA = re.compile(r'lda\s+xsp,\s*\(xsp\s*([-+])\s*(0x[0-9a-f]+)\)', re.I)
INCDEC = re.compile(r'\b(inc|dec)\s+(\d+),\s*xsp\b', re.I)
PUSHPOP = re.compile(r'\b(push|pop)\s+(\w+)\b', re.I)
RETD = re.compile(r'\bretd\s+(0x[0-9a-f]+)', re.I)


def framed(T):
    d, n = 0, 0
    for t in [x.lower() for x in T]:
        m = LDA.search(t)
        if m: d += (-1 if m.group(1) == '-' else 1) * int(m.group(2), 16); n += 1; continue
        m = INCDEC.search(t)
        if m: d += (1 if m.group(1) == 'inc' else -1) * int(m.group(2)); n += 1; continue
        m = PUSHPOP.match(t)
        if m: d += (-1 if m.group(1) == 'push' else 1) * (4 if m.group(2).startswith('x') else 2); n += 1; continue
        m = RETD.search(t)
        if m: d += int(m.group(1), 16); n += 1
    return n > 0 and d == 0


tot = collections.Counter(); tb = collections.Counter()
rows = []
for c in cases:
    e, sp = c["entry"], c["span"]
    ia = {a for a, _n, _x in c["insns"]}
    nbr = 0
    for a, n, x in c["insns"]:
        m = BR.match(x.strip())
        if m:
            t = int(m.group(3), 16)
            if e <= t < e + sp:
                nbr += 1
    d = dec[e]
    sib = d["sib"]
    S1 = bool(sib) and sib["insn"].split("/")[0] == sib["insn"].split("/")[1] and \
        sib["code"].split("/")[0] == sib["code"].split("/")[1]
    S2 = framed(c["texts"])
    S3 = nbr > 0
    S4 = d["E2_prev_terminates"]
    k = sum([S1, S2, S3, S4])
    rows.append((e, sp, S1, S2, S3, S4, nbr, k))
    tot[k] += 1; tb[k] += sp
print("independent corroborations per range (beyond E1 call target + E3 framing convergence):")
print("  S1 sibling revision frames the same bytes identically")
print("  S2 stack frame balances to zero")
print("  S3 >=1 internal jr/jrl/calr lands exactly on a decoded boundary")
print("  S4 the instruction ending at the entry is ret/reti/retd/unconditional jump\n")
print(f"{'entry':>9} {'B':>5}  S1 S2 S3 S4  intbr")
for e, sp, a, b, cc_, dd, nbr, k in rows:
    print(f"0x{e:06X} {sp:5}   {'Y' if a else '.'}  {'Y' if b else '.'}  {'Y' if cc_ else '.'}  {'Y' if dd else '.'}  {nbr:5}")
print()
for k in sorted(tot, reverse=True):
    print(f"  {tot[k]:3} ranges {tb[k]:6} B with {k} independent corroboration(s)")
print(f"\n  ranges with ZERO of S1-S4: {tot[0]} ({tb[0]} B)")
print(f"  S1 {sum(r[2] for r in rows)}  S2 {sum(r[3] for r in rows)}  S3 {sum(r[4] for r in rows)}  S4 {sum(r[5] for r in rows)}")
