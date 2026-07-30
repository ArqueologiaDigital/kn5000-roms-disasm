#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""act15_census.py -- what is `ACT 0x15'?  A static corpus census with nulls.

NEC uPD6383GF (Technics SX-KN5000, IC311).  `ACT = lo12[4:0] == 0x15' is the
second-largest ACTION code in the corpus (707 words, 23.7 %) and the MAME device
decodes it as nothing (`LO_ACT_NONE_5', upd6383d.h:343).  SPECULATIVE-APPLIED-
REGISTER sect. 169 traced the LFO index path dead at exactly this code.

Everything here is STATIC: the 3057-word IC311 corpus straight out of the Sub CPU
ROM through `pat_corpus.load()' (which already excludes algorithms 79/88/89/90/91
-- those are IC310 / MN19413 programs -- and de-duplicates the 38 distinct body
images).  C-format words (hi12[11:8] == 0xC) are excluded from every ACTION
statistic: their `lo12' is part of a 13-bit immediate and carries no ACTION field.

    python3 dsp/tools/act15_census.py pop        the population, and the C-format exclusion
    python3 dsp/tools/act15_census.py census     ACT x {class4, SRC, flags, addr8}
    python3 dsp/tools/act15_census.py forms      the distinct word forms carrying 0x15
    python3 dsp/tools/act15_census.py mi         contingency + expected counts (the NULL)
    python3 dsp/tools/act15_census.py pairs      ★ minimal pairs (identical but for ACT)
    python3 dsp/tools/act15_census.py context    what precedes / follows an 0x15 word
    python3 dsp/tools/act15_census.py bits       is 0x15 = 0x12 | 0x04 | 0x01?  bit algebra
    python3 dsp/tools/act15_census.py decoded    which words the shipped alu_decoded() admits
    python3 dsp/tools/act15_census.py all

stdlib only.  See ../analysis/data/ACT15_findings.md.
"""
import collections
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pat_corpus as PC                                             # noqa: E402

F = PC.F

# ---------------------------------------------------------------------------
#  the shipped decode, transcribed from upd6383d.h (for labelling only)
# ---------------------------------------------------------------------------
ACT_NAME = {
    0x00: "acc <- bus (adder input)",
    0x03: "tempB <- bus         (m_tb = L)",
    0x07: "STORE mem[ptr] <- bus",
    0x0B: "OPEN",
    0x0D: "acc <- bus  (S144)",
    0x0E: "P <- bus    (S144)",
    0x12: "NO-OP",
    0x13: "tempA <- bus",
    0x14: "tempB <- bus",
    0x15: "NO-OP  <-- THE TARGET",
    0x19: "tempA <- ??? (dest not measured)",
    0x1A: "tempB <- ??? (CONSISTENT)",
}
SRC_NAME = {
    0x00: "C-RAM[cursor] (coef, S145)",
    0x07: "mem[ptr]",
    0x08: "the COEFFICIENT",
    0x0B: "dram-rd",
    0x10: "acc",
    0x11: "ACCB / mem[ptr] (contested)",
    0x19: "tempA",
    0x1A: "tempB",
}


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


def load():
    progs, meta = PC.load()
    rows = []          # (prog, index, nwords, F)
    for name, ws in progs.items():
        n = len(ws)
        for i, w in enumerate(ws):
            rows.append((name, i, n, F(w)))
    return progs, meta, rows


def acts(rows):
    """The ACTION population: every non-C-format word."""
    return [r for r in rows if not r[3].cfmt]


# ---------------------------------------------------------------------------
def cmd_pop(progs, meta, rows):
    hdr("POPULATION -- and why C-format must be excluded")
    tot = len(rows)
    cf = sum(1 for r in rows if r[3].cfmt)
    print("  programs (2 kernel + 38 distinct body images):  %d" % len(progs))
    print("  effect SLOTS covered by the bodies:             %d"
          % sum(len(meta[k]["algos"]) for k in progs))
    print("  words total:                                    %d" % tot)
    print("  C-format words (hi12[11:8] == 0xC), EXCLUDED:   %d" % cf)
    print("  ACTION population:                              %d" % (tot - cf))
    print("\n  ⚠ IC310/MN19413 streams {79,88,89,90,91} are already excluded by")
    print("    pat_corpus.load() -- this is a ONE-CHIP population.")

    hdr("the ACTION field, whole population, C-format excluded")
    P = acts(rows)
    c = collections.Counter(r[3].act for r in P)
    pr = collections.defaultdict(set)
    sl = collections.defaultdict(set)
    for name, _i, _n, f in P:
        pr[f.act].add(name)
        sl[f.act].add(name)
    print("  ACT   count      %    images  slots   decode")
    for a, n in c.most_common():
        nslots = sum(len(meta[k]["algos"]) for k in sl[a])
        print("  0x%02X  %5d  %5.1f %%   %4d   %4d   %s"
              % (a, n, 100.0 * n / len(P), len(pr[a]), nslots,
                 ACT_NAME.get(a, "")))
    print("  ---- %d words, %d distinct ACTION codes" % (len(P), len(c)))


# ---------------------------------------------------------------------------
def _xtab(P, key, targets):
    """counter[act][key] plus the marginal, for the given ACT targets."""
    tab = {a: collections.Counter() for a in targets}
    marg = collections.Counter()
    for _p, _i, _n, f in P:
        marg[key(f)] += 1
        if f.act in tab:
            tab[f.act][key(f)] += 1
    return tab, marg


def _print_xtab(title, tab, marg, tot, fmtk=str, name=None):
    ks = sorted(marg, key=lambda k: -marg[k])
    hdr(title)
    head = "  %-22s %7s %7s" % ("value", "corpus", "rate")
    for a in tab:
        head += "  | 0x%02X n / EXPECTED" % a
    print(head)
    for k in ks:
        base = marg[k] / tot
        line = "  %-22s %7d %6.2f%%" % (fmtk(k), marg[k], 100 * base)
        for a in tab:
            n = tab[a][k]
            exp = base * sum(tab[a].values())
            line += "  | %5d %8.1f%s" % (n, exp, _star(n, exp))
        print(line)
    if name:
        print("  " + name)


def _star(n, exp):
    if exp < 1.0:
        return " *" if n >= 3 else ""
    z = (n - exp) / math.sqrt(max(exp, 1e-9))
    if abs(z) < 3:
        return ""
    return " ***" if z > 0 else " ---"


def cmd_census(progs, meta, rows):
    P = acts(rows)
    tot = len(P)
    T = [0x15, 0x12, 0x00, 0x07]

    _print_xtab("ACT x class4   (null = the class marginal x the ACT's own total)",
                *_xtab(P, lambda f: f.class4, T), tot=tot,
                fmtk=lambda k: "class %X" % k)
    _print_xtab("ACT x SRC",
                *_xtab(P, lambda f: f.src, T), tot=tot,
                fmtk=lambda k: "SRC %02X %s" % (k, SRC_NAME.get(k, "")))
    _print_xtab("ACT x hi12 flags",
                *_xtab(P, lambda f: (f.b11, f.b10, f.b7, f.b4), T), tot=tot,
                fmtk=lambda k: "ESC=%d END=%d b7=%d ST=%d" % k)
    _print_xtab("ACT x f98", *_xtab(P, lambda f: f.f98, T), tot=tot,
                fmtk=lambda k: "f98 = %d" % k)
    _print_xtab("ACT x f31", *_xtab(P, lambda f: f.f31, T), tot=tot,
                fmtk=lambda k: "f31 = %d" % k)
    _print_xtab("ACT x lo12 bit 5 (ptrmode)",
                *_xtab(P, lambda f: (f.lo12 >> 5) & 1, T), tot=tot,
                fmtk=lambda k: "ptrmode = %d" % k)

    hdr("ACT 0x15 x addr8  (top 20)")
    c = collections.Counter(f.addr8 for _p, _i, _n, f in P if f.act == 0x15)
    m = collections.Counter(f.addr8 for _p, _i, _n, f in P)
    n15 = sum(c.values())
    print("  addr8  n(0x15)  EXPECTED   corpus")
    for k, n in c.most_common(20):
        print("  0x%02X   %6d  %8.1f%s  %6d" % (k, n, m[k] / tot * n15,
                                                _star(n, m[k] / tot * n15), m[k]))
    print("  ---- %d distinct addr8 values under ACT 0x15 (corpus has %d)"
          % (len(c), len(m)))

    hdr("ACT 0x15 per program")
    print("  %-24s %5s %5s %6s   %s" % ("program", "0x15", "words", "share",
                                        "family"))
    for name in progs:
        ws = [r for r in P if r[0] == name]
        n = sum(1 for r in ws if r[3].act == 0x15)
        print("  %-24s %5d %5d %5.1f%%   %s"
              % (name, n, len(ws), 100.0 * n / max(len(ws), 1),
                 meta[name]["family"]))

    hdr("position in the frame -- normalised index, ACT 0x15 vs the population")
    for a in (0x15, 0x12, 0x00, 0x07):
        v = [i / max(n - 1, 1) for _p, i, n, f in P if f.act == a]
        if not v:
            continue
        v.sort()
        print("  ACT 0x%02X  n=%4d  median %.3f  q1 %.3f  q3 %.3f  mean %.3f"
              % (a, len(v), v[len(v) // 2], v[len(v) // 4], v[3 * len(v) // 4],
                 sum(v) / len(v)))
    v = [i / max(n - 1, 1) for _p, i, n, _f in P]
    v.sort()
    print("  ALL       n=%4d  median %.3f  q1 %.3f  q3 %.3f  mean %.3f"
          % (len(v), v[len(v) // 2], v[len(v) // 4], v[3 * len(v) // 4],
             sum(v) / len(v)))


# ---------------------------------------------------------------------------
def cmd_forms(progs, meta, rows):
    P = acts(rows)
    hdr("the distinct WORD FORMS carrying ACT 0x15")
    c = collections.Counter(f.w for _p, _i, _n, f in P if f.act == 0x15)
    pr = collections.defaultdict(set)
    for name, _i, _n, f in P:
        if f.act == 0x15:
            pr[f.w].add(name)
    print("  %-16s %5s %6s  %s" % ("form", "n", "images", "decode"))
    for w, n in c.most_common():
        print("  %-16s %5d %6d  %s" % (PC.fmt(w), n, len(pr[w]),
                                       PC.decode_str(w)[16:]))
    print("  ---- %d distinct forms, %d words" % (len(c), sum(c.values())))

    hdr("the same, for ACT 0x12 (the named sibling)")
    c = collections.Counter(f.w for _p, _i, _n, f in P if f.act == 0x12)
    for w, n in c.most_common():
        print("  %-16s %5d  %s" % (PC.fmt(w), n, PC.decode_str(w)[16:]))
    print("  ---- %d distinct forms, %d words" % (len(c), sum(c.values())))

    hdr("ACT 0x15 x (class4, SRC) -- the idiom table")
    c = collections.Counter((f.class4, f.src) for _p, _i, _n, f in P
                            if f.act == 0x15)
    m = collections.Counter((f.class4, f.src) for _p, _i, _n, f in P)
    n15 = sum(1 for _p, _i, _n, f in P if f.act == 0x15)
    tot = len(P)
    print("  cls SRC   n(0x15)  EXPECTED  corpus   share-of-form")
    for (cl, s), n in c.most_common():
        exp = m[(cl, s)] / tot * n15
        print("   %X  %02X    %6d  %8.1f%s %6d      %5.1f%%   %s"
              % (cl, s, n, exp, _star(n, exp), m[(cl, s)],
                 100.0 * n / m[(cl, s)], SRC_NAME.get(s, "")))


# ---------------------------------------------------------------------------
def cmd_mi(progs, meta, rows):
    P = acts(rows)
    tot = len(P)
    hdr("★ CLASS-A CO-OCCURRENCE -- the structural question, with its null")
    nA = sum(1 for _p, _i, _n, f in P if f.class4 == 0xA)
    for a in sorted(set(f.act for _p, _i, _n, f in P)):
        n = sum(1 for _p, _i, _n, f in P if f.act == a)
        na = sum(1 for _p, _i, _n, f in P if f.act == a and f.class4 == 0xA)
        exp = n * nA / tot
        if n < 20:
            continue
        z = (na - exp) / math.sqrt(max(exp, 1e-9))
        print("  ACT 0x%02X  n=%4d   class-A %4d   EXPECTED %6.1f   z=%+7.1f  %s"
              % (a, n, na, exp, z, ACT_NAME.get(a, "")))
    print("  ---- corpus class-A rate = %d/%d = %.3f" % (nA, tot, nA / tot))

    hdr("mutual information between ACT and each other field (bits)")
    def mi(key):
        j = collections.Counter()
        ka = collections.Counter()
        kb = collections.Counter()
        for _p, _i, _n, f in P:
            j[(f.act, key(f))] += 1
            ka[f.act] += 1
            kb[key(f)] += 1
        s = 0.0
        for (x, y), n in j.items():
            p = n / tot
            s += p * math.log2(p / ((ka[x] / tot) * (kb[y] / tot)))
        hb = -sum((v / tot) * math.log2(v / tot) for v in kb.values())
        return s, hb
    for nm, key in (("class4", lambda f: f.class4),
                    ("SRC", lambda f: f.src),
                    ("f31", lambda f: f.f31),
                    ("f98", lambda f: f.f98),
                    ("bit4 (store)", lambda f: f.b4),
                    ("bit7", lambda f: f.b7),
                    ("bit10 (END)", lambda f: f.b10),
                    ("bit11 (ESC)", lambda f: f.b11),
                    ("addr8", lambda f: f.addr8),
                    ("program", lambda f: 0)):
        s, hb = mi(key)
        print("  ACT ; %-14s  I = %6.3f bits   H(field) = %6.3f  (%.0f%%)"
              % (nm, s, hb, 100 * s / max(hb, 1e-9)))


# ---------------------------------------------------------------------------
def cmd_pairs(progs, meta, rows):
    P = acts(rows)
    hdr("★ MINIMAL PAIRS -- words identical in hi12/class4/addr8/SRC, ACT differs")
    key = lambda f: (f.hi12, f.class4, f.addr8, f.src)
    g = collections.defaultdict(collections.Counter)
    where = collections.defaultdict(lambda: collections.defaultdict(set))
    for name, _i, _n, f in P:
        g[key(f)][f.act] += 1
        where[key(f)][f.act].add(name)
    hits = [(k, v) for k, v in g.items() if 0x15 in v and len(v) > 1]
    hits.sort(key=lambda kv: -sum(kv[1].values()))
    print("  %-26s  %s" % ("hi12.cls.addr8.SRC", "ACT: n"))
    for k, v in hits:
        print("  %03X.%X.%02X SRC=%02X %-10s  %s"
              % (k[0], k[1], k[2], k[3], SRC_NAME.get(k[3], "")[:10],
                 "  ".join("0x%02X:%d" % (a, n)
                           for a, n in sorted(v.items()))))
    print("  ---- %d minimal-pair groups containing ACT 0x15" % len(hits))

    hdr("the same, keyed on (class4, addr8, SRC) -- hi12 free")
    key2 = lambda f: (f.class4, f.addr8, f.src)
    g2 = collections.defaultdict(collections.Counter)
    for _p, _i, _n, f in P:
        g2[key2(f)][f.act] += 1
    hits2 = [(k, v) for k, v in g2.items() if 0x15 in v and len(v) > 1]
    hits2.sort(key=lambda kv: -sum(kv[1].values()))
    for k, v in hits2[:40]:
        print("  cls %X addr8 %02X SRC %02X   %s"
              % (k[0], k[1], k[2],
                 "  ".join("0x%02X:%d" % (a, n) for a, n in sorted(v.items()))))
    print("  ---- %d groups" % len(hits2))

    hdr("★ THE COMPLEMENT TEST -- which ACT codes NEVER share a (hi12,cls,addr8,SRC)")
    codes = sorted(set(f.act for _p, _i, _n, f in P))
    coex = {a: set() for a in codes}
    for k, v in g.items():
        for a in v:
            coex[a] |= set(v) - {a}
    for a in codes:
        n = sum(1 for _p, _i, _n, f in P if f.act == a)
        print("  ACT 0x%02X (n=%4d) shares a form-key with: %s"
              % (a, n, " ".join("0x%02X" % b for b in sorted(coex[a])) or "-- NOTHING --"))


# ---------------------------------------------------------------------------
def cmd_context(progs, meta, rows):
    hdr("what IMMEDIATELY PRECEDES / FOLLOWS an ACT 0x15 word (C-format kept "
        "in the sequence, since it executes)")
    prevc = collections.Counter()
    nextc = collections.Counter()
    n15 = 0
    allprev = collections.Counter()
    for name, ws in progs.items():
        for i, w in enumerate(ws):
            f = F(w)
            if i:
                allprev[_tag(F(ws[i - 1]))] += 1
            if f.cfmt or f.act != 0x15:
                continue
            n15 += 1
            if i:
                prevc[_tag(F(ws[i - 1]))] += 1
            if i + 1 < len(ws):
                nextc[_tag(F(ws[i + 1]))] += 1
    tot = sum(allprev.values())
    print("  PRECEDED BY            n    EXPECTED   corpus")
    for k, n in prevc.most_common(14):
        exp = allprev[k] / tot * n15
        print("  %-20s %5d  %8.1f%s %6d" % (k, n, exp, _star(n, exp), allprev[k]))
    print("\n  FOLLOWED BY            n    EXPECTED   corpus")
    for k, n in nextc.most_common(14):
        exp = allprev[k] / tot * n15
        print("  %-20s %5d  %8.1f%s %6d" % (k, n, exp, _star(n, exp), allprev[k]))

    hdr("★ RUNS: how often does an ACT 0x15 word follow another ACT 0x15 word?")
    run = pairs = 0
    for name, ws in progs.items():
        for i in range(1, len(ws)):
            a, b = F(ws[i - 1]), F(ws[i])
            if a.cfmt or b.cfmt:
                continue
            pairs += 1
            if a.act == 0x15 and b.act == 0x15:
                run += 1
    P = acts(rows)
    r = sum(1 for _p, _i, _n, f in P if f.act == 0x15) / len(P)
    print("  adjacent non-C pairs: %d   both 0x15: %d   EXPECTED %.1f  (rate^2)"
          % (pairs, run, pairs * r * r))

    hdr("★ DOES AN ACT 0x15 WORD SIT BETWEEN A CLASS-A MULTIPLY AND ITS CONSUMER?")
    print("  lag from each ACT 0x15 word to the NEXT class-A word (same program)")
    lag = collections.Counter()
    for name, ws in progs.items():
        idxA = [i for i, w in enumerate(ws)
                if F(w).class4 == 0xA and not F(w).cfmt]
        for i, w in enumerate(ws):
            f = F(w)
            if f.cfmt or f.act != 0x15:
                continue
            nxt = [j for j in idxA if j > i]
            lag[(nxt[0] - i) if nxt else -1] += 1
    for k in sorted(lag):
        print("   lag %3d : %5d" % (k, lag[k]))


def _tag(f):
    if f.cfmt:
        return "C-FMT"
    return "cls%X/SRC%02X/ACT%02X" % (f.class4, f.src, f.act)


# ---------------------------------------------------------------------------
def cmd_bits(progs, meta, rows):
    P = acts(rows)
    hdr("BIT ALGEBRA -- is the ACTION field structured?")
    c = collections.Counter(f.act for _p, _i, _n, f in P)
    print("  code  bits[4:0]   n     name")
    for a in sorted(c):
        print("  0x%02X  %s  %5d   %s"
              % (a, format(a, "05b"), c[a], ACT_NAME.get(a, "")))
    print("\n  observed codes: %s" % " ".join("0x%02X" % a for a in sorted(c)))
    print("  0x12 = 10010   0x13 = 10011 (tA)   0x14 = 10100 (tB)   0x15 = 10101")
    print("  ⇒ 0x15 = 0x14 | 1 = 0x13 ^ 6 = 0x12 | 3 ... the [1:0] sub-field:")
    sub = collections.Counter()
    for _p, _i, _n, f in P:
        if 0x10 <= f.act <= 0x17:
            sub[(f.act & 0x1C, f.act & 3)] += 1
    print("  ACT[4:2]=100 family:")
    for k in sorted(sub):
        print("     hi=%02X lo=%d  ->  0x%02X  n=%d" % (k[0], k[1], k[0] | k[1],
                                                        sub[k]))

    hdr("Does bit 2 of ACT (0x04) behave like a field?  0x11/0x15, 0x10/0x14 ...")
    for a in sorted(c):
        b = a ^ 0x04
        if b in c and b > a:
            print("  0x%02X (n=%4d)  <->  0x%02X (n=%4d)   [bit 2]"
                  % (a, c[a], b, c[b]))
    for a in sorted(c):
        b = a ^ 0x01
        if b in c and b > a:
            print("  0x%02X (n=%4d)  <->  0x%02X (n=%4d)   [bit 0]"
                  % (a, c[a], b, c[b]))


# ---------------------------------------------------------------------------
def cmd_decoded(progs, meta, rows):
    """Which ACT 0x15 words does the shipped alu_decoded() actually execute?"""
    hdr("alu_decoded() over the ACT 0x15 population  (mirror of upd6383d.h)")
    P = acts(rows)
    g = collections.Counter()
    for _p, _i, _n, f in P:
        if f.act != 0x15:
            continue
        g[_guard(f)] += 1
    NAMES = {0: "DECODED -- executes the ALU", 1: "CLASS (not 2/8/A)",
             21: "bit-11 alternate lo12", 22: "pointer-mode",
             23: "SRC/ACT not anchored", 5: "bit-4 store off mode 2",
             6: "ACTION 0x07 off mode 2", 7: "guard 7", 3: "f31 refused"}
    for k in sorted(g, key=lambda k: -g[k]):
        print("  guard %2d  %5d   %s" % (k, g[k], NAMES.get(k, "?")))
    print("  ---- %d ACT 0x15 words" % sum(g.values()))

    hdr("★ of the DECODED ones, how many are class A (multiply issues anyway)?")
    n = na = nmul = 0
    for _p, _i, _n, f in P:
        if f.act != 0x15 or _guard(f) != 0:
            continue
        n += 1
        if f.class4 == 0xA:
            na += 1
            if f.f31 != 2:
                nmul += 1
    print("  decoded ACT 0x15 words:              %d" % n)
    print("  ... of which class A:                %d" % na)
    print("  ... of which class A AND f31 != 2:   %d   <- the multiply DOES issue"
          % nmul)
    print("\n  ⇒ the shipped multiply is gated by coeff_consumer() = class4==0xA,")
    print("    NOT by the ACTION.  `ACT 0x15 = no-op' therefore does NOT block a")
    print("    class-A multiply.  (See findings sect. 2.)")


def _guard(f):
    """mirror of upd6383_disassembler::alu_guard_fail()."""
    if f.cfmt:
        return 4
    if f.class4 not in (2, 8, 0xA):
        return 1
    if f.lo12 & 0x800:
        return 21
    if (f.lo12 >> 5) & 1:
        return 22
    if f.src not in (0x07, 0x10, 0x19, 0x1A):
        return 23
    if f.act not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19):
        return 23
    if f.b4 and (f.class4 & 7) != 2:
        return 5
    if f.act == 0x07 and (f.class4 & 7) != 2:
        return 6
    if f.b4 and f.b7 and f.f31 != 2:
        return 7
    if f.f31 in (0, 1):
        return 0
    if f.f31 == 2:
        return 0 if f.class4 == 8 else 3
    return 3


# ---------------------------------------------------------------------------
CMDS = {"pop": cmd_pop, "census": cmd_census, "forms": cmd_forms,
        "mi": cmd_mi, "pairs": cmd_pairs, "context": cmd_context,
        "bits": cmd_bits, "decoded": cmd_decoded}


# ---------------------------------------------------------------------------
#  the discriminator sections
# ---------------------------------------------------------------------------
def cmd_disc(progs, meta, rows):
    """★ what separates ACT 0x15 from ACT 0x12 -- the device's own open question."""
    P = acts(rows)
    hdr("0x12 vs 0x15 -- every field, both marginals (the device asks this)")
    for nm, key in (("class4", lambda f: f.class4), ("SRC", lambda f: f.src),
                    ("addr8", lambda f: f.addr8), ("f31", lambda f: f.f31),
                    ("f98", lambda f: f.f98), ("bit4 ST", lambda f: f.b4),
                    ("bit7", lambda f: f.b7), ("bit11 ESC", lambda f: f.b11)):
        a = collections.Counter(key(f) for _p, _i, _n, f in P if f.act == 0x12)
        b = collections.Counter(key(f) for _p, _i, _n, f in P if f.act == 0x15)
        print("  %-10s 0x12: %s" % (nm, " ".join("%02X:%d" % (k, v)
                                                 for k, v in a.most_common(8))))
        print("  %-10s 0x15: %s" % ("", " ".join("%02X:%d" % (k, v)
                                                 for k, v in b.most_common(8))))

    hdr("★ THE CAPTURE QUADRUPLE 0x12/0x13/0x14/0x15 -- addr8 coupling")
    print("  restricted to class A, the only class where all four are common")
    tab = collections.defaultdict(collections.Counter)
    for _p, _i, _n, f in P:
        if f.class4 == 0xA and f.act in (0x12, 0x13, 0x14, 0x15):
            tab[f.act][f.addr8] += 1
    for a in sorted(tab):
        print("  ACT 0x%02X  %s" % (a, "  ".join("addr8=%02X:%d" % (k, v)
                                                 for k, v in tab[a].most_common(6))))

    hdr("★ CLASS-1 (external delay-DRAM) words: ACT x direction (addr8 bit 6)")
    tab = collections.defaultdict(collections.Counter)
    for _p, _i, _n, f in P:
        if f.class4 == 1:
            tab["WR" if (f.addr8 & 0x40) else "RD"][f.act] += 1
    for d in ("RD", "WR"):
        n = sum(tab[d].values())
        print("  %s (n=%d): %s" % (d, n, "  ".join(
            "0x%02X:%d" % (k, v) for k, v in tab[d].most_common())))

    hdr("★ IS ACT 0x15 THE 'DEFAULT' ON A COEFFICIENT-FETCH WORD?")
    fetch = [f for _p, _i, _n, f in P if f.class4 & 8]
    nf = len(fetch)
    c = collections.Counter(f.act for f in fetch)
    nofetch = [f for _p, _i, _n, f in P if not (f.class4 & 8)]
    c2 = collections.Counter(f.act for f in nofetch)
    print("  coefficient-FETCH words (class4 & 8): %d" % nf)
    print("  everything else:                      %d" % len(nofetch))
    print("  ACT     fetch   %%      other   %%     ratio")
    for a in sorted(set(c) | set(c2), key=lambda a: -(c[a] + c2[a])):
        if c[a] + c2[a] < 15:
            continue
        pa = 100.0 * c[a] / nf
        pb = 100.0 * c2[a] / len(nofetch)
        print("  0x%02X  %6d %6.1f %6d %6.1f   %s"
              % (a, c[a], pa, c2[a], pb,
                 ("%.2fx" % (pa / pb)) if pb else "inf"))


def cmd_known(progs, meta, rows):
    """The blocks whose algorithm is NOT in doubt, with every field spelled out."""
    hdr("★ PARAMETRIC EQ -- one biquad section (validated to 0.094-0.198 dB)")
    _dump("a39 PARAMETRIC EQ", progs, 5, 14)
    hdr("★ SINGLE DELAY -- the block action-field.md sect. 6 forces (5145/5145)")
    _dump("a09 SINGLE DELAY", progs, 0, len(progs["a09 SINGLE DELAY"]))
    hdr("★ CHORUS -- the LFO tail sect. 169 traced (lfo-ramp.md sect. 10)")
    _dump("a01 CHORUS", progs, 0, 40)


def _dump(name, progs, lo, hi):
    ws = progs[name]
    for i in range(lo, min(hi, len(ws))):
        f = F(ws[i])
        if f.cfmt:
            print("  w%-3d %010X  %s  C-FORMAT imm13=%d"
                  % (i, ws[i], f.txt(), f.imm13))
            continue
        fl = []
        if f.b11:
            fl.append("ESC")
        if f.b10:
            fl.append("END")
        if f.b7:
            fl.append("b7")
        if f.b4:
            fl.append("ST")
        mark = " ★" if f.act == 0x15 else "  "
        print("  w%-3d %010X  %s cls%X addr8=%02X SRC=%02X %-9s ACT=%02X %-22s "
              "f31=%d f98=%d %s%s"
              % (i, ws[i], f.txt(), f.class4, f.addr8, f.src,
                 SRC_NAME.get(f.src, "")[:9], f.act,
                 ACT_NAME.get(f.act, "?")[:22], f.f31, f.f98,
                 "|".join(fl), mark))


CMDS["disc"] = cmd_disc
CMDS["known"] = cmd_known


if __name__ == "__main__":
    args = sys.argv[1:] or ["all"]
    progs, meta, rows = load()
    for a in (list(CMDS) if args[0] == "all" else args):
        if a not in CMDS:
            sys.exit("unknown section %r; have: %s" % (a, " ".join(CMDS)))
        CMDS[a](progs, meta, rows)
