#!/usr/bin/env python3
"""lfo_consumer2.py -- ★ THE DECISIVE TABLE.

For every LFO block in the corpus, using the CALIBRATED pointer walk
(dsp/tools/lfo_walk.py; calibration = the live core's dp = 0x05 at CHORUS
iw84/85 and dp = 0x07 at iw89..92):

    Q          the phase cell   (dp at the phase-accumulate word)
    exit       the `xxx.2.dd.447' word after the wrap -- SRC 0x11 = mem[Q],
               ACTION 0x07, and its addr8 is where the pointer goes next
    700        the `092.2.dd.700' word -- SRC 0x1C, hi12 bit4 STORE + bit 7
    x24        the class-A word that eats the 0x000018 coefficient
    sel        the class-6 selector(s) of the table idiom that follows

and the question the brief asks: IS THE x24 WORD ON Q?
"""
import os, sys, collections
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfo_ramp as L, dsp_disasm as DIS, lfo_walk as W
hi12, cls, ad8, lo12, s8, fmt = L.hi12, L.cls, L.ad8, L.lo12, L.s8, L.fmt
NM = L.prog_names()


def is700(w): return hi12(w) == 0x092 and cls(w) == 2 and lo12(w) == 0x700
def is447(w): return cls(w) == 2 and lo12(w) == 0x447 and not DIS.c_format(w)


def main():
    print("=" * 118)
    print("== EVERY LFO BLOCK: the phase cell Q and the cell its ×24 word actually reads")
    print("=" * 118)
    print("%-4s %-20s %-4s %-9s %-16s %-16s %-18s %-16s %s" %
          ("alg", "program", "Q", "wrap w#", "exit .447 (dp)", "092.2.*.700 (dp)",
           "x24 class-A (dp)", "reads Q?", "class-6 sel"))
    ncase = collections.Counter()
    for (i, la, a, b, ca, cb, ws) in L.lfo_sites():
        unit = 1 if la == 200 else 0
        tr, _ = W.walk(ws, 0x05 | (unit << 7))
        Q = tr[a][2]
        k447 = next((k for k in range(b + 1, min(len(ws), b + 4)) if is447(ws[k])), None)
        k700 = next((k for k in range(b + 1, min(len(ws), b + 60)) if is700(ws[k])), None)
        k24 = None
        if k700 is not None:
            k24 = next((k for k in range(k700 + 1, min(len(ws), k700 + 6))
                        if DIS.coeff_consumer(ws[k])), None)
        sels = []
        if k24 is not None:
            sels = ["0x%02X" % ad8(ws[k]) for k in range(k24, min(len(ws), k24 + 22))
                    if cls(ws[k]) == 6]
        onq = "--"
        if k24 is not None:
            onq = "YES" if tr[k24][2] == Q else "no (0x%02X)" % tr[k24][2]
        ncase[onq.split()[0]] += 1
        print("%-4d %-20s 0x%02X w%-8d %-16s %-16s %-18s %-16s %s" %
              (i, NM.get(i, "?")[:20], Q, b,
               ("w%d %+d (0x%02X)" % (k447, s8(ad8(ws[k447])), tr[k447][2])) if k447 is not None else "--",
               ("w%d %+d (0x%02X)" % (k700, s8(ad8(ws[k700])), tr[k700][2])) if k700 is not None else "--",
               ("w%d %s (0x%02X)" % (k24, fmt(ws[k24]), tr[k24][2])) if k24 is not None else "--",
               onq, " ".join(sels)))
    print("\n   ×24 word lands ON the phase cell: %s" % dict(ncase))

    print("\n" + "=" * 118)
    print("== READERS OF Q AFTER THE WRAP, per block (SRC 0x07 or 0x11, dp == Q)")
    print("=" * 118)
    for (i, la, a, b, ca, cb, ws) in L.lfo_sites():
        unit = 1 if la == 200 else 0
        tr, _ = W.walk(ws, 0x05 | (unit << 7))
        Q = tr[a][2]
        later = [(k, ws[k]) for k in range(b + 1, len(ws))
                 if tr[k][2] == Q and (cls(ws[k]) & 7) == 2 and not DIS.c_format(ws[k])
                 and DIS.lo_src(ws[k]) in (0x07, 0x11) and not DIS.lo_ptrmode(ws[k])]
        print("   algo %-3d %-20s Q=0x%02X  wrap w%-3d  later readers of Q: %s" %
              (i, NM.get(i, "?")[:20], Q, b,
               ", ".join("w%d %s" % (k, fmt(w)) for k, w in later) or "*** NONE ***"))


if __name__ == "__main__":
    main()
