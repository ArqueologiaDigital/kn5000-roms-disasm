#!/usr/bin/env python3
"""lfo_census.py -- corpus census of the LFO tail motif and the table idiom."""
import os, sys, collections
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfo_ramp as L
import dsp_disasm as DIS
hi12, cls, ad8, lo12, s8, fmt = L.hi12, L.cls, L.ad8, L.lo12, L.s8, L.fmt

A2I = L.algo_to_image()
NM = L.prog_names()


def all_bodies():
    seen = {}
    for a, (p, la, ws) in sorted(A2I.items()):
        seen.setdefault(p, (a, la, ws))
    return sorted(seen.values())


def sec_700():
    print("=" * 96)
    print("== POPULATION of 092.2.00.700 (the LFO tail's second word) -- corpus-wide")
    print("=" * 96)
    tot = 0
    lfo_algos = {s[0] for s in L.lfo_sites()}
    hits = collections.Counter()
    for a, la, ws in all_bodies():
        n = sum(1 for w in ws if w == 0x0092200700)
        if n:
            hits[a] = n
            tot += n
    print("   %d occurrences over %d distinct bodies" % (tot, len(hits)))
    for a, n in sorted(hits.items()):
        print("      algo %-3d %-24s x%-2d   LFO-bearing: %s" %
              (a, NM.get(a, "?")[:24], n, "YES" if a in lfo_algos else "*** NO ***"))
    nb = [a for a, la, ws in all_bodies() if a in lfo_algos and a not in hits]
    print("   LFO-bearing bodies WITHOUT it: %s" % (nb or "none"))
    # also: any other hi12=092 class2 word?
    fam = collections.Counter()
    for a, la, ws in all_bodies():
        for w in ws:
            if hi12(w) == 0x092 and cls(w) == 2:
                fam[fmt(w)] += 1
    print("   every 092.2.* word in the body corpus: %s" % dict(fam))


def sec_class6():
    print("\n" + "=" * 96)
    print("== POPULATION of class-6 words (the table idiom's selector)")
    print("=" * 96)
    rows = collections.Counter()
    per = collections.defaultdict(list)
    for a, la, ws in all_bodies():
        for k, w in enumerate(ws):
            if cls(w) == 6 and not DIS.c_format(w):
                rows[(fmt(w),)] += 1
                per[fmt(w)].append((a, k))
    for k, v in sorted(rows.items()):
        algs = sorted({x[0] for x in per[k[0]]})
        print("   %-14s x%-3d  addr8=%3d  in algos %s" %
              (k[0], v, int(k[0].split(".")[2], 16),
               ", ".join("%d %s" % (a, NM.get(a, "?")[:16]) for a in algs)))


def sec_scale():
    """for every LFO block: the class-A word between the 700 word and the class-6
    word, and the coefficient it eats."""
    print("\n" + "=" * 96)
    print("== THE THIRD COEFFICIENT -- the class-A word inside each LFO tail")
    print("=" * 96)
    print("%-4s %-22s %-4s | %-6s %-14s %-8s %-8s | %s" %
          ("alg", "program", "unit", "slot", "word", "C-cell", "value", "class-6 selectors that follow"))
    vals = collections.Counter()
    for (i, la, a, b, ca, cb, ws) in L.lfo_sites():
        base = 0x90 if la == 200 else 0x00
        cm = L.cram_of_algo(i)
        cur = DIS.cursor_addresses(ws)
        # find the 700 word after the wrap
        k700 = next((k for k in range(b, min(len(ws), b + 60)) if ws[k] == 0x0092200700), None)
        if k700 is None:
            print("%-4d %-22s %-4d | -- no 700 word within 60 slots --" % (i, NM.get(i, "?")[:22], 1 if la == 200 else 0))
            continue
        kA = next((k for k in range(k700 + 1, min(len(ws), k700 + 6))
                   if DIS.coeff_consumer(ws[k])), None)
        sels = [ad8(ws[k]) for k in range(k700, min(len(ws), k700 + 12)) if cls(ws[k]) == 6]
        if kA is None:
            print("%-4d %-22s %-4d | w%-5d (700) -- no class-A within 5 --" % (i, NM.get(i, "?")[:22], 1 if la == 200 else 0, k700))
            continue
        v = cm.get(base + cur[kA])
        vals["%06X" % v if v is not None else "--"] += 1
        print("%-4d %-22s %-4d | w%-5d %-14s C[%02X]     %-8s | %s" %
              (i, NM.get(i, "?")[:22], 1 if la == 200 else 0, kA, fmt(ws[kA]),
               base + cur[kA], "%06X" % v if v is not None else "--",
               " ".join("0x%02X(%d)" % (s, s) for s in sels)))
    print("\n   census of the third coefficient over every LFO block: %s" % dict(vals))


def sec_scale_all():
    """EVERY class-A word immediately before a class-6 word, LFO or not (the control)."""
    print("\n" + "=" * 96)
    print("== CONTROL -- every class-A word within 3 slots before ANY class-6 word")
    print("=" * 96)
    vals = collections.Counter()
    for a, la, ws in all_bodies():
        base = 0x90 if la == 200 else 0x00
        cm = L.cram_of_algo(a)
        cur = DIS.cursor_addresses(ws)
        for k, w in enumerate(ws):
            if cls(w) != 6 or DIS.c_format(w):
                continue
            kA = max((j for j in range(max(0, k - 3), k) if DIS.coeff_consumer(ws[j])), default=None)
            v = cm.get(base + cur[kA]) if kA is not None else None
            vals[("%06X" % v if v is not None else "--", ad8(w))] += 1
            print("   algo %-3d %-22s class6 w%-4d sel=0x%02X(%2d)  <- class-A w%s %s  C=%s" %
                  (a, NM.get(a, "?")[:22], k, ad8(w), ad8(w),
                   str(kA) if kA is not None else "--",
                   fmt(ws[kA]) if kA is not None else "",
                   "%06X" % v if v is not None else "--"))
    print("\n   (scale, selector) pairs: ")
    for k, v in sorted(vals.items()):
        print("      scale %-8s selector 0x%02X   x%d" % (k[0], k[1], v))


if __name__ == "__main__":
    a = sys.argv[1:] or ["700", "class6", "scale"]
    if "700" in a: sec_700()
    if "class6" in a: sec_class6()
    if "scale" in a: sec_scale()
    if "control" in a: sec_scale_all()


def sec_src1c():
    print("\n" + "=" * 96)
    print("== SRC 0x1C -- the whole population, corpus-wide (header+epilogue+bodies)")
    print("=" * 96)
    corp = L.corpus()
    pop = collections.Counter()
    for where, ia, w in corp:
        if not DIS.c_format(w) and DIS.lo_src(w) == 0x1C:
            pop[(fmt(w), DIS.lo_act(w))] += 1
    for (f, act), n in sorted(pop.items()):
        print("   %-14s ACT=0x%02X   x%d" % (f, act, n))
    print("   total SRC 0x1C words: %d" % sum(pop.values()))
    print("   ... of which lo12 == 0x700: %d" %
          sum(n for (f, a), n in pop.items() if f.endswith(".700")))


def sec_ctx(algo, lo, hi):
    p, la, ws = A2I[algo]
    print("\n--- algo %d %s  w%d..w%d ---" % (algo, NM.get(algo, "?"), lo, hi))
    base = 0x90 if la == 200 else 0x00
    cm = L.cram_of_algo(algo)
    cur = DIS.cursor_addresses(ws)
    for k in range(lo, min(hi + 1, len(ws))):
        w = ws[k]
        c = ""
        if cur[k] is not None:
            v = cm.get(base + cur[k])
            c = "  C[%02X]=%s" % (base + cur[k], "%06X" % v if v is not None else "--")
        print("   w%-4d %010X %-14s SRC=%02X ACT=%02X%s" %
              (k, w, fmt(w), DIS.lo_src(w), DIS.lo_act(w), c))


def sec_dram():
    print("\n" + "=" * 96)
    print("== DELAY-DRAM WORDS -- lo12 census, and which programs carry each form")
    print("=" * 96)
    lfo = {s[0] for s in L.lfo_sites()}
    pop = collections.defaultdict(list)
    for a, la, ws in all_bodies():
        for k, w in enumerate(ws):
            if DIS.is_dram(w):
                pop[(fmt(w))].append(a)
    print("%-14s %-5s %-5s %-5s %-6s %-6s | %s" %
          ("word", "SRC", "ACT", "n", "#LFO", "#noLFO", "programs"))
    for f, algs in sorted(pop.items(), key=lambda t: -len(t[1])):
        w = int(f.replace(".", ""), 16)
        nl = sum(1 for a in algs if a in lfo)
        print("%-14s 0x%02X  0x%02X  %-5d %-6d %-6d | %s" %
              (f, DIS.lo_src(w), DIS.lo_act(w), len(algs), nl, len(algs) - nl,
               ", ".join(sorted({"%d %s" % (a, NM.get(a, '?')[:14]) for a in algs}))[:110]))


def sec_act0b():
    print("\n" + "=" * 96)
    print("== ACT 0x0B -- the whole population (corpus, C-format excluded)")
    print("=" * 96)
    pop = collections.Counter()
    where = collections.defaultdict(set)
    for a, la, ws in all_bodies():
        for k, w in enumerate(ws):
            if not DIS.c_format(w) and DIS.lo_act(w) == 0x0B:
                pop[fmt(w)] += 1
                where[fmt(w)].add(a)
    for f, n in sorted(pop.items(), key=lambda t: -t[1]):
        w = int(f.replace(".", ""), 16)
        print("   %-14s SRC=0x%02X dram=%-5s x%-3d  algos %s" %
              (f, DIS.lo_src(w), DIS.is_dram(w), n,
               ", ".join("%d %s" % (a, NM.get(a, '?')[:14]) for a in sorted(where[f]))[:120]))
