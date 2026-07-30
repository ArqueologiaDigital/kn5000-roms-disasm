#!/usr/bin/env python3
"""lfo_walk.py -- the D-RAM pointer walk of a body, and WHO TOUCHES THE PHASE CELL.

Model (all of it already in dsp_disasm / the MAME core):
    p starts at  base = 0x05 | (unit << 7)   at the per-unit CALL   (FORCED,
      analysis/output-stage-decode.md item D)
    every word with (class4 & 7) == 2 and not C-format does  p += (s8)addr8  AFTER
      its own access                                          (MEASURED, K6)
    p is 8 bits and wraps mod 256.

CALIBRATION (stated before use, method rule 4): the live core reports dp = 0x05
at CHORUS iw84/85 and dp = 0x07 at iw89..92 (upd6383.cpp ~line 3712, the §108
refutation note).  This walk must reproduce BOTH anchors or it is not usable.
"""
import os, sys, collections
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfo_ramp as L
import dsp_disasm as DIS

hi12, cls, ad8, lo12, s8, fmt = L.hi12, L.cls, L.ad8, L.lo12, L.s8, L.fmt


def walk(ws, base):
    """-> [(k, word, p_at_access)]"""
    p, out = base & 0xFF, []
    for k, w in enumerate(ws):
        out.append((k, w, p))
        if DIS.ptr_postinc(w):
            p = (p + s8(ad8(w))) & 0xFF
    return out, p


def touches(w):
    """does this word have a MODELLED access to mem[p]?  ('r','w','rw' or '')"""
    if DIS.c_format(w) or (cls(w) & 7) != 2:
        return ""
    r = DIS.lo_src(w) in (0x07, 0x11) and not DIS.lo_ptrmode(w)
    wr = bool(hi12(w) & DIS.HI_ST) or DIS.lo_act(w) == 0x07
    return ("r" if r else "") + ("w" if wr else "")


def body(algo):
    a2i = L.algo_to_image()
    p, la, ws = a2i[algo]
    return la, ws


def sec_calib():
    print("=" * 96)
    print("== CALIBRATION -- the two live anchors the core prints for CHORUS")
    print("=" * 96)
    la, ws = body(1)
    tr, end = walk(ws, 0x05)
    for k in (0, 1, 5, 6, 7, 8):
        print("   iw%-3d (w%-2d) %010X  dp = 0x%02X" % (la + k, k, ws[k], tr[k][2]))
    ok = tr[0][2] == 0x05 and tr[1][2] == 0x05 and all(tr[k][2] == 0x07 for k in (5, 6, 7, 8))
    print("\n   live core: dp = 0x05 at iw84/85, dp = 0x07 at iw89..92")
    print("   this walk: %s" % ("MATCHES BOTH ANCHORS -- calibrated" if ok else "*** DISAGREES -- NOT usable"))
    return ok


def sec_phase(algo=1):
    la, ws = body(algo)
    unit = 1 if la == 200 else 0
    base = 0x05 | (unit << 7)
    tr, end = walk(ws, base)
    # find the LFO trio to learn Q
    sites = [s for s in L.lfo_sites() if s[0] == algo]
    print("\n" + "=" * 96)
    print("== PHASE CELL -- algo %d %s (unit %d, base 0x%02X)" %
          (algo, L.prog_names().get(algo, "?"), unit, base))
    print("=" * 96)
    Qs = []
    for (i, la_, a, b, ca, cb, ws_) in sites:
        Q = tr[a][2]
        Qs.append(Q)
        print("   LFO block w%d/w%d/w%d -> phase cell Q = 0x%02X   (acc dp=0x%02X mid dp=0x%02X wrap dp=0x%02X)"
              % (a, a + 1, b, Q, tr[a][2], tr[a + 1][2], tr[b][2]))
    print("   walk end dp = 0x%02X (net %+d over %d words)" % (end, (end - base) & 0xFF, len(ws)))
    for Q in sorted(set(Qs)):
        print("\n   --- every slot whose pointer is 0x%02X ---" % Q)
        print("   %-6s %-12s %-14s %-5s %-4s %-4s %-3s %s" %
              ("slot", "word", "fields", "acc", "SRC", "ACT", "M", "note"))
        for (k, w, p) in tr:
            if p != Q:
                continue
            t = touches(w)
            note = ""
            if DIS.coeff_consumer(w):
                note += "class-A coeff "
            if hi12(w) & DIS.HI_B7:
                note += "gate7 "
            note += "f31=%d " % DIS.hi_f31(hi12(w))
            if hi12(w) & DIS.HI_ST:
                note += "ST "
            print("   w%-5d %010X %-14s %-5s 0x%02X 0x%02X %-3d %s" %
                  (k, w, fmt(w), t or "-", DIS.lo_src(w), DIS.lo_act(w),
                   int(DIS.lo_ptrmode(w)), note))
    return tr, Qs


def sec_full(algo=1, lo=0, hi=999):
    la, ws = body(algo)
    unit = 1 if la == 200 else 0
    tr, end = walk(ws, 0x05 | (unit << 7))
    print("\n" + "=" * 96)
    print("== FULL WALK -- algo %d %s" % (algo, L.prog_names().get(algo, "?")))
    print("=" * 96)
    for (k, w, p) in tr:
        if not (lo <= k <= hi):
            continue
        print("   w%-4d dp=%02X %010X %-14s acc=%-3s SRC=%02X ACT=%02X %s" %
              (k, p, w, fmt(w), touches(w) or "-", DIS.lo_src(w), DIS.lo_act(w),
               DIS.text(w)))


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] == "calib":
        sec_calib()
    if not a or a[0] == "phase":
        for alg in [int(x) for x in a[1:]] or [1]:
            sec_phase(alg)
    if a and a[0] == "full":
        sec_full(int(a[1]), int(a[2]) if len(a) > 2 else 0, int(a[3]) if len(a) > 3 else 999)
