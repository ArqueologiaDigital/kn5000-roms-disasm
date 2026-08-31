#!/usr/bin/env python3
"""Emit prom_b's 0xF40000 thunk table as assembly, and census what it points at.

QUESTION ANSWERED
  prom_b file 0x40000-0x44017 is a linker thunk region: 4-byte slots, each either
  `1B lo mid hi` (= `jp nnn`), a 32-bit little-endian pointer whose top byte is
  zero, or `0x0E` / `0x00` filler.  Every `jp` slot names a ROUTINE ENTRY POINT
  somewhere in the 1 MiB prom_a+prom_b image, so the table is a routine directory
  and converting it bootstraps labels for the whole image.

  This script (a) writes the assembly for that region and (b) prints the census.

WHAT IS EVIDENCE AND WHAT IS NOT
  * The slot classification is bytes, nothing else, and the gate re-checks it:
    `assert_byte_identical.py` fails on a single wrong byte.
  * The xref counts are OPCODE-ANCHORED: only `1D lo mid hi` (call nnn) and
    `1B lo mid hi` (jp nnn) whose operand lands inside the table are counted.
    They are scanned at EVERY byte offset, not only at instruction boundaries,
    so a count is an UPPER BOUND -- some hits are bytes inside another
    instruction or inside data that happen to spell a call.  Use them to RANK
    slots, never as an exact call count.
  * 0x0E = RET: mame/src/devices/cpu/tlcs900/dasm900.cpp:1267 (opcode 0x0E in the
    single-byte table is M_RET).  0x1B = JP nnn / 0x1D = CALL nnn: confirmed by
    round-tripping through llvm-mc -triple=tlcs900 -disassemble.

RUN
  python3 scripts/analysis/prom_b_thunk_table.py --census
  python3 scripts/analysis/prom_b_thunk_table.py --asm > /tmp/thunks.s
"""
import collections
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B_BASE = 0xF00000
A_BASE = 0xF80000
TBL_LO, TBL_HI = 0x40000, 0x44018          # file offsets, [lo, hi)


def load():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13")


def classify(b, o):
    """('jp', target) | ('ptr', value) | ('fill', None) for the slot at file offset o."""
    s = b[o:o + 4]
    if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
        return ("jp", s[1] | s[2] << 8 | s[3] << 16)
    if s[3] == 0x00 and 0xF0 <= s[2] <= 0xFF:
        return ("ptr", int.from_bytes(s, "little"))
    return ("fill", None)


def xrefs(a, b):
    """Opcode-anchored references into the table. UPPER BOUND -- see docstring."""
    lo, hi = B_BASE + TBL_LO, B_BASE + TBL_HI
    n = collections.Counter()
    for img in (a, b):
        for o in range(len(img) - 3):
            if img[o] in (0x1B, 0x1D):
                t = img[o + 1] | img[o + 2] << 8 | img[o + 3] << 16
                if lo <= t < hi and (t & 3) == 0:
                    n[t] += 1
    return n


def where(addr):
    if A_BASE <= addr <= 0xFFFFFF:
        return "prom_a 0x%05X" % (addr - A_BASE)
    if B_BASE <= addr < A_BASE:
        return "prom_b 0x%05X" % (addr - B_BASE)
    return "?"


def main():
    a, b = load()
    xr = xrefs(a, b)

    if "--census" in sys.argv or len(sys.argv) == 1:
        tg, pt, fl = [], [], 0
        o = TBL_LO
        while o < TBL_HI:
            k, v = classify(b, o)
            (tg if k == "jp" else pt if k == "ptr" else []).append(v) if k != "fill" else None
            if k == "fill":
                fl += 1
            o += 4
        print("slots %d  jp %d  ptr %d  fill %d" % ((TBL_HI - TBL_LO) // 4, len(tg), len(pt), fl))
        print("distinct routine entry points: %d" % len(set(tg)))
        print("  in prom_b: %d (%d distinct)" % (sum(1 for t in tg if t < A_BASE),
                                                 len({t for t in tg if t < A_BASE})))
        print("  in prom_a: %d (%d distinct)" % (sum(1 for t in tg if t >= A_BASE),
                                                len({t for t in tg if t >= A_BASE})))
        print("\nbusiest slots (opcode-anchored xref UPPER BOUND):")
        for addr, c in xr.most_common(30):
            k, v = classify(b, addr - B_BASE)
            print("  0x%06X x%-4d %s" % (addr, c,
                  ("jp 0x%06X  (%s)" % (v, where(v))) if k == "jp" else "%s %r" % (k, v)))

    if "--asm" in sys.argv:
        sys.stdout.write(emit(b, xr))
    return 0


def emit(b, xr):
    """Assembly text for [TBL_LO, TBL_HI)."""
    out = []
    o = TBL_LO
    while o < TBL_HI:
        k, v = classify(b, o)
        addr = B_BASE + o
        if k == "jp":
            c = xr.get(addr, 0)
            tail = "  ; -> %s%s" % (where(v), ("   x%d" % c) if c else "")
            out.append("T_%06X:\tjp 0x%06X%s\n" % (addr, v, tail))
            o += 4
        elif k == "ptr":
            c = xr.get(addr, 0)
            out.append("T_%06X:\t.long 0x%08X\t; ptr -> 0x%06X (%s)%s\n"
                       % (addr, v, v, where(v), ("   x%d" % c) if c else ""))
            o += 4
        else:
            # byte-level run-length over the filler, so a slot like 0e 00 00 00
            # is split honestly instead of being called "a 0x0E slot".
            start = o
            while o < TBL_HI and classify(b, o)[0] == "fill":
                o += 4
            seg = b[start:o]
            i = 0
            while i < len(seg):
                j = i
                while j < len(seg) and seg[j] == seg[i]:
                    j += 1
                run, val = j - i, seg[i]
                name = {0x0E: "ret", 0x00: "nop"}.get(val)
                cmt = "  ; 0x%06X: %d x %s" % (B_BASE + start + i, run,
                                               name if name else "0x%02X" % val)
                if run <= 2 and name:
                    for k2 in range(run):
                        out.append("\t%s%s\n" % (name, cmt if k2 == 0 else ""))
                else:
                    out.append("\t.fill 0x%X, 1, 0x%02X%s\n" % (run, val, cmt))
                i = j
    return "".join(out)


if __name__ == "__main__":
    sys.exit(main())
