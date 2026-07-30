#!/usr/bin/env python3
"""lfo_consumer.py -- WHAT DOES THE LFO DRIVE?  ROM-only, static.

Sections
    triple   the coefficient TRIPLE at every LFO block: increment, wrap, and the
             NEXT cursor cell + the cell consumed by the class-A word inside the
             LFO's tail motif.  Plus the class-6 selector of the table idiom.
    walk     the D-RAM pointer walk of one body from the unit base; every access
             to the phase cell Q, in order.
    tail     the full tail motif of every LFO block, word by word, aligned.
"""
import collections, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfo_ramp as L
import dsp_disasm as DIS

hi12, cls, ad8, lo12 = DIS.hi12, DIS.class4, DIS.addr8, DIS.lo12
fmt = L.fmt
s8 = L.s8


def name(i):
    return L.prog_names().get(i, "?")


def sites():
    return L.lfo_sites()


def cram_win(i, base, lo, hi):
    c = L.cram_of_algo(i)
    return [(k, c.get(base + k)) for k in range(lo, hi + 1)]


def sec_triple():
    print("=" * 100)
    print("== TRIPLE -- the coefficient cells around every LFO block")
    print("=" * 100)
    print("%-4s %-22s %-3s %-6s %-6s | %-9s %-9s %-9s %-9s %-9s" %
          ("alg", "program", "u", "w_acc", "w_wrap", "c[n]inc", "c[n+1]wrap",
           "c[n+2]", "c[n+3]", "c[n+4]"))
    rows = []
    for (i, la, a, b, ca, cb, ws) in sites():
        base = 0x90 if la == 200 else 0x00
        cm = L.cram_of_algo(i)
        vals = []
        for k in range(ca, ca + 5):
            v = cm.get(base + k)
            vals.append("--" if v is None else "%06X" % v)
        print("%-4d %-22s %-3d %-6d %-6d | %-9s %-9s %-9s %-9s %-9s" %
              (i, name(i)[:22], 1 if la == 200 else 0, a, b, *vals))
        rows.append((i, la, a, b, ca, cb, ws))
    return rows


def next_coeff_after(ws, b, limit=200):
    """the next class-A (cursor-advancing) word strictly after index b."""
    for k in range(b + 1, min(len(ws), b + limit)):
        if DIS.coeff_consumer(ws[k]):
            return k
    return None


def sec_tail():
    print("\n" + "=" * 100)
    print("== TAIL -- what follows each wrap word, to the first table idiom (class 6)")
    print("=" * 100)
    for (i, la, a, b, ca, cb, ws) in sites():
        base = 0x90 if la == 200 else 0x00
        cm = L.cram_of_algo(i)
        cur = DIS.cursor_addresses(ws)
        print("\n--- algo %d %s  unit %d   acc=w%d wrap=w%d" %
              (i, name(i), 1 if la == 200 else 0, a, b))
        k = b
        seen6 = 0
        while k < len(ws) and k < b + 40:
            w = ws[k]
            tag = ""
            if cur[k] is not None:
                v = cm.get(base + cur[k])
                tag = "  C[%02X]=%s" % (base + cur[k], "--" if v is None else "%06X" % v)
            if cls(w) == 6:
                tag += "   <== class-6 selector addr8=0x%02X (%d)" % (ad8(w), ad8(w))
                seen6 += 1
            print("    w%-4d %010X  %-14s SRC=%02X ACT=%02X M=%d%s" %
                  (k, w, fmt(w), DIS.lo_src(w), DIS.lo_act(w), int(DIS.lo_ptrmode(w)), tag))
            k += 1
            if seen6 >= 2 and k > b + 8:
                break


if __name__ == "__main__":
    args = sys.argv[1:] or ["triple", "tail"]
    if "triple" in args:
        sec_triple()
    if "tail" in args:
        sec_tail()
