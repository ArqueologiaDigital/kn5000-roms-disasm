#!/usr/bin/env python3
"""prepost.py -- does the ACTION-0x07 store land on the PRE-increment cell (like
the bit-4 store, sect. 35) or the POST-increment cell?

Three instruments, in this order:
  MIRROR   reproduce lfo_ramp.py's published 216 dead stores, to prove the
           harness is the published one.
  CONTROL  the same metric applied to the BIT-4 store, whose answer is already
           FORCED (sect. 35: PRE, by the K6 table at 12/12).  If the metric
           prefers POST there, it is not evidence about anything.
  TEST     the metric applied to ACTION 0x07.
  LFO      lfo-ramp.md item L's FORCED-negative constraint, per block.
"""
import collections
import sys

sys.path.insert(0, "/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/"
                   "c6cf97f4-b4f1-4ba1-adc0-85474706b167/scratchpad")
from store_target import (load_corpus, allwords, hi12, class4, addr8, lo12, c_format,
                   f31, src, act, ptrmode, mode, st, b7, delta, txt)


def mode2(w):
    return (not c_format(w)) and (class4(w) & 7) == 2


def reads(w):
    return mode2(w) and not ptrmode(w) and src(w) == 0x07


def walk(ws):
    pre, c = [], 0
    for w in ws:
        pre.append(c)
        if mode2(w):
            c += delta(w)
    return pre


def writes_of(w, pre, st_post, a07_post, gate):
    """(cell, kind) list for one word under a model."""
    out = []
    if not mode2(w):
        return out
    post = pre + delta(w)
    if (hi12(w) & 0x010):
        if gate(bool(hi12(w) & 0x080), f31(w)):
            out.append((post if st_post else pre, "b4"))
    if act(w) == 0x07 and not ptrmode(w):
        out.append((post if a07_post else pre, "a07"))
    return out


GATE_ALWAYS = lambda b, f: True
GATE_SHIPPED = lambda b, f: not (b and f == 1)      # st_suppressed()
GATE_NE2 = lambda b, f: not (b and f != 2)          # the other survivor


def published(images, st_post=False, a07_post=False, gate=GATE_ALWAYS):
    """lfo_ramp.py's own algorithm, with the write cell made model-dependent.
    NOTE: chain continuation requires the READ pointer to stay parked, so this
    metric can only LOSE dead stores when a write is moved off the parked cell.
    It is reported for the mirror check only."""
    tot, ex = 0, collections.Counter()
    for _r, _a, ws in images:
        pre = walk(ws)
        for k in range(len(ws)):
            wk = [c for c, _t in writes_of(ws[k], pre[k], st_post, a07_post, gate)]
            if not wk:
                continue
            cell = wk[0]
            j, chain = k + 1, [k]
            while j < len(ws) and mode2(ws[j]) and pre[j] == pre[k] and not reads(ws[j]):
                if cell in [c for c, _t in writes_of(ws[j], pre[j], st_post, a07_post, gate)]:
                    chain.append(j)
                j += 1
            if len(chain) > 1:
                ex[tuple(txt(ws[x]) for x in chain)] += 1
                tot += len(chain) - 1
    return tot, ex


def general(images, st_post=False, a07_post=False, gate=GATE_ALWAYS):
    """★ THE UNBIASED VERSION.  A write to cell c is DEAD if, scanning forward
    through words of KNOWN addressing (mode 2), the next word that touches c
    writes it.  Scanning stops at the first word whose addressing is not
    modelled -- it might read c.  This can find dead stores ANYWHERE, so moving
    a write can both remove and create them."""
    tot, ex, live, opaque = 0, collections.Counter(), 0, 0
    for _r, _a, ws in images:
        pre = walk(ws)
        for k in range(len(ws)):
            for cell, kind in writes_of(ws[k], pre[k], st_post, a07_post, gate):
                j, verdict = k + 1, "opaque"
                while j < len(ws):
                    if not mode2(ws[j]):
                        verdict = "opaque"
                        break
                    if reads(ws[j]) and pre[j] == cell:
                        verdict = "live"
                        break
                    if cell in [c for c, _t in writes_of(ws[j], pre[j], st_post,
                                                         a07_post, gate)]:
                        verdict = "dead"
                        break
                    j += 1
                if verdict == "dead":
                    tot += 1
                    ex[(txt(ws[k]), txt(ws[j]))] += 1
                elif verdict == "live":
                    live += 1
                else:
                    opaque += 1
    return tot, live, opaque, ex


def main():
    header, epilogue, images = load_corpus()

    print("=" * 78)
    print("A. MIRROR -- reproduce lfo_ramp.py's published census")
    print("=" * 78)
    for nm, g in (("always (shipped in lfo_ramp)", GATE_ALWAYS),
                  ("b7_f31_1_off", GATE_SHIPPED), ("b7_ne2_off", GATE_NE2)):
        t, ex = published(images, gate=g)
        print("   %-30s dead = %d   (lfo-ramp.md: 216 / 161 / --)" % (nm, t))
    t, ex = published(images)
    print("\n   commonest chains (published algorithm, shipped model):")
    for k, v in ex.most_common(6):
        print("      x%-3d %s" % (v, " -> ".join(k)))
    print()

    print("=" * 78)
    print("B. ★ CONTROL FIRST -- the metric applied to the BIT-4 store, whose")
    print("   answer is ALREADY FORCED (sect. 35: PRE, K6 table 12/12).")
    print("   If the metric prefers POST here it is not evidence about anything.")
    print("=" * 78)
    print("   model                                       dead   live  opaque")
    print("   ------------------------------------------  -----  -----  ------")
    for nm, sp, ap in (("bit4 PRE  / act07 PRE   (shipped)", False, False),
                       ("bit4 POST / act07 PRE   ← CONTROL", True, False),
                       ("bit4 PRE  / act07 POST  ← TEST", False, True),
                       ("bit4 POST / act07 POST", True, True)):
        t, l, o, ex = general(images, st_post=sp, a07_post=ap)
        print("   %-42s %5d  %5d  %6d" % (nm, t, l, o))
    print()
    print("   the same four, under the shipped bit-7 gate st_suppressed():")
    for nm, sp, ap in (("bit4 PRE  / act07 PRE", False, False),
                       ("bit4 POST / act07 PRE", True, False),
                       ("bit4 PRE  / act07 POST", False, True),
                       ("bit4 POST / act07 POST", True, True)):
        t, l, o, ex = general(images, st_post=sp, a07_post=ap, gate=GATE_SHIPPED)
        print("   %-42s %5d  %5d  %6d" % (nm, t, l, o))
    print()
    print("   PER-KIND breakdown, shipped model (which store is the dead one):")
    for nm, sp, ap in (("act07 PRE", False, False), ("act07 POST", False, True)):
        tot = collections.Counter()
        for _r, _a, ws in images:
            pre = walk(ws)
            for k in range(len(ws)):
                for cell, kind in writes_of(ws[k], pre[k], sp, ap, GATE_ALWAYS):
                    j, verdict = k + 1, "opaque"
                    while j < len(ws):
                        if not mode2(ws[j]):
                            break
                        if reads(ws[j]) and pre[j] == cell:
                            verdict = "live"
                            break
                        if cell in [c for c, _t in writes_of(ws[j], pre[j], sp, ap,
                                                             GATE_ALWAYS)]:
                            verdict = "dead"
                            break
                        j += 1
                    tot[(kind, verdict)] += 1
        print("      %-12s %s" % (nm, dict(sorted(tot.items()))))
    print()
    print("   ★ WHO KILLS WHOM, shipped model (killer kind -> victim kind):")
    for nm, sp, ap in (("act07 PRE", False, False), ("act07 POST", False, True)):
        pair = collections.Counter()
        for _r, _a, ws in images:
            pre = walk(ws)
            for k in range(len(ws)):
                for cell, kind in writes_of(ws[k], pre[k], sp, ap, GATE_ALWAYS):
                    j = k + 1
                    while j < len(ws):
                        if not mode2(ws[j]):
                            break
                        if reads(ws[j]) and pre[j] == cell:
                            break
                        hit = [t for c, t in writes_of(ws[j], pre[j], sp, ap,
                                                       GATE_ALWAYS) if c == cell]
                        if hit:
                            pair[(kind, hit[0])] += 1
                            break
                        j += 1
        print("      %-12s %s" % (nm, dict(sorted(pair.items()))))
    print()

    print("=" * 78)
    print("C. ★ lfo-ramp.md item L -- the FORCED-NEGATIVE constraint, per block")
    print("=" * 78)
    print("   item L: `094.A.dd.200''s bit-4 store deposits phase+inc in the cell;")
    print("   the ACT-0x07 word that follows must NOT deposit a foreign value there.")
    print("   So: for each block, does the follower's PRE cell equal the phase cell?")
    hit = collections.Counter()
    rows = []
    for r, _a, ws in images:
        pre = walk(ws)
        for k, w in enumerate(ws):
            if lo12(w) == 0x200 and class4(w) == 0xA and f31(w) == 2 and st(w):
                # the wrap word: its bit-4 store lands on pre[k] (sect. 35)
                cell = pre[k]
                for j in range(k + 1, min(k + 4, len(ws))):
                    if act(ws[j]) == 0x07 and mode2(ws[j]) and not ptrmode(ws[j]):
                        dpre = (pre[j] == cell)
                        dpost = (pre[j] + delta(ws[j]) == cell)
                        hit[(dpre, dpost, delta(ws[j]))] += 1
                        rows.append((r, k, txt(w), j, txt(ws[j]), delta(ws[j]),
                                     dpre, dpost))
                        break
    print()
    print("   algo  wrap-word @k        follower @j          delta  PRE hits  POST hits")
    print("   ----  ------------------  ------------------  -----  --------  ---------")
    for r, k, a, j, b, d, dpre, dpost in rows[:40]:
        print("   %4d  %-18s  %-18s  %+5d  %-8s  %s"
              % (r, a, b, d, "CLOBBER" if dpre else "-", "CLOBBER" if dpost else "-"))
    print()
    npre = sum(v for (a, b, d), v in hit.items() if a)
    npost = sum(v for (a, b, d), v in hit.items() if b)
    nz = sum(v for (a, b, d), v in hit.items() if d != 0)
    print("   blocks with a wrap word followed by an ACT-0x07 word: %d" % sum(hit.values()))
    print("   ★ follower's delta != 0 (the models differ)          : %d" % nz)
    print("   ★ PRE  model: follower clobbers the phase cell in     %d of %d"
          % (npre, sum(hit.values())))
    print("   ★ POST model: follower clobbers the phase cell in     %d of %d"
          % (npost, sum(hit.values())))
    print("   (item L FORCES, negatively, that it must NOT clobber.)")
    print()

    print("=" * 78)
    print("D. the double-store words -- SRC bias, with its base rate")
    print("=" * 78)
    C = list(allwords(header, epilogue, images))
    m2a07 = [w for _l, _i, w in C if act(w) == 0x07 and mode2(w) and not ptrmode(w)]
    wb4 = [w for w in m2a07 if st(w)]
    nb4 = [w for w in m2a07 if not st(w)]
    print("   mode-2 ACT-0x07 words:  with bit 4 = %d, without = %d" % (len(wb4), len(nb4)))
    for nm, s in (("WITH bit 4", wb4), ("WITHOUT bit 4 (base rate)", nb4)):
        h = collections.Counter(src(w) for w in s)
        tot = len(s)
        print("      %-26s src histogram %s" % (nm, dict(sorted(h.items()))))
        print("      %-26s src==0x10 (acc): %d/%d = %.1f%%"
              % ("", h.get(0x10, 0), tot, 100.0 * h.get(0x10, 0) / tot))
    print()
    print("   ★ IF bit 4 and ACT 0x07 were TWO ENCODINGS OF ONE WRITE PORT at ONE")
    print("     address, a word carrying both would lose one of two values unless")
    print("     the two sources AGREE -- i.e. unless SRC == 0x10 (acc).  So the")
    print("     one-port reading PREDICTS an excess of SRC 0x10 among the bit-4")
    print("     carriers.  The two-cell reading predicts no such excess.")
    anch = [w for w in wb4 if src(w) in (0x07, 0x10, 0x19, 0x1A)]
    print("   words where the two store VALUES are provably DIFFERENT")
    print("     (bit 4 stores acc; ACT 0x07 stores the bus; anchored SRC != acc):")
    for w in sorted(set(anch)):
        if src(w) != 0x10:
            n = sum(1 for x in m2a07 if x == w)
            print("      %-18s x%-3d src=%02X delta=%+d" % (txt(w), n, src(w), delta(w)))
    print("     ⇒ count = %d.  Method rule 3: this cell is too small to carry a"
          % sum(1 for w in anch if src(w) != 0x10))
    print("       conclusion on its own.")
    print()


if __name__ == "__main__":
    main()
