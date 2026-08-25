#!/usr/bin/env python3
"""What reaches the DISK menu?  -- the one thread gap V asked for, followed to its end.

QUESTION IT ANSWERS
  `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap V: "How does a user reach
  `Fdc_Request` at all?  ... it needs either a menu sequence, or a chord ...
  Where to look: whichever display list in prom_b carries the disk menu."

  The disk menu is now converted -- prom_b 0xF58000, `DISK`, `DISK L0AD`,
  `DISK SAVE`, `MIDI FILE`, `DIRECT PLAY`, `FL0PPY DISK`, `F0RMAT`.  This script
  follows what DRAWS it, backwards, one link at a time, and stops where the
  evidence stops:

      prom_a 0xFF42CD   pushes 0x00F580B0 / 0x00F58014 and calls 0xFF75D3, the
                        interpreter-A stack veneer.  It is a routine start: the
                        byte before it, 0xFF42CC, is 0x0E = `ret`.
        ^
      NOTHING CALLS IT.  Scanning both images for `call` (0x1D + imm24) and
      `calr` (0x1E + disp16) resolving to 0xFF42CD finds ZERO sites, and it is
      in none of the 654 slots of prom_a's dispatch matrix (0xFF3800-0xFF42B1).
        ^
      prom_b T_F42264 = `jp 0xFF42CD`, and the whole three-image set spells
      0xFF42CD exactly once -- in that thunk.
        ^
      prom_a 0xF86EC1: a table of 256 32-bit words, every one of which is either
      a slot of the prom_b directory (175 of them) or the constant 0x00F872C1
      (the other 81), which is the address of the byte IMMEDIATELY AFTER the
      table.  ENTRY 96 IS T_F42264.
        ^
      WHAT INDEXES THAT TABLE IS NOT ESTABLISHED HERE.  It is in prom_a, which
      this lane may not edit, and 0xF86EC1 is inside an `.incbin`.

  So: the disk menu is SCREEN 96 of a 256-screen table, and the open question is
  now one table lookup wide instead of a whole subsystem.  That is a real
  narrowing and it is not a closure -- nothing here says which panel event, menu
  key or state machine produces the index 96.

WHY THE TABLE'S 256 IS NOT A GUESS
  Its last byte is 0xF872C0 and its first is 0xF86EC1: 0x400 bytes, 256 entries,
  and BOTH ends are fixed by something other than the count.  Below it, the four
  bytes at 0xF86EBD read 0x01010101, which is not an address in this map.  Above
  it, the 81 unused slots hold 0x00F872C1 -- the first byte past the table -- so
  the table ends exactly where the thing its empty slots point at begins.
  ⚠ The table is NOT 4-byte aligned (0xF86EC1 = ...C1), which is why a scan that
  assumes alignment misses it.

RUN
  python3 notes/prom_b_diskmenu_entrypoint.py           # 12 checks, exit 1 on failure
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A_BASE, B_BASE = 0xF80000, 0xF00000
TBL, N = 0xF86EC1, 256
DRAW = 0xFF42CD                      # the routine that draws the disk menu
THUNK = 0xF42264
FAIL, NUM = [], [0]


def check(msg, got, want):
    NUM[0] += 1
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def main():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    a, b, c = r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13"), r("wsa1_prom_c.ic28")
    A = lambda x, n=4: a[x - A_BASE:x - A_BASE + n]
    B = lambda x, n=4: b[x - B_BASE:x - B_BASE + n]
    w = lambda x: int.from_bytes(A(x), "little")

    print("prom_b_diskmenu_entrypoint: the disk menu is screen 96")
    # 1. the drawing routine really pushes the disk menu's two ends
    check("0xFF42D7 is `lda XBC,0x00f580b0`", A(0xFF42D7, 5).hex(), "f2b080f531")
    check("0xFF42DD is `lda XWA,0x00f58014`", A(0xFF42DD, 5).hex(), "f21480f530")
    check("0xFF42E3 is `call 0xFF75D3`", A(0xFF42E3, 4).hex(), "1dd375ff")
    check("the byte before 0xFF42CD is `ret`", "0x%02X" % a[DRAW - 1 - A_BASE], "0x0E")
    # 2. nothing calls it
    sites = []
    for img, base in ((a, A_BASE), (b, B_BASE), (c, A_BASE)):
        p = b"\x1d" + DRAW.to_bytes(3, "little")
        o = img.find(p)
        while o >= 0:
            sites.append(base + o)
            o = img.find(p, o + 1)
        for o in range(len(img) - 3):
            if img[o] == 0x1E:
                d = int.from_bytes(img[o + 1:o + 3], "little")
                if base + o + 3 + (d - 0x10000 if d > 0x7FFF else d) == DRAW:
                    sites.append(base + o)
    check("call/calr sites that reach 0xFF42CD", sites, [])
    mat = [int.from_bytes(A(0xFF3800 + 4 * i), "little") for i in range((0xFF42B1 - 0xFF3800) // 4)]
    check("slots of the 654-entry dispatch matrix that hold it",
          [i for i, v in enumerate(mat) if v == DRAW], [])
    # 3. exactly one reference in the whole set, and it is the thunk
    pat = DRAW.to_bytes(3, "little")
    refs = []
    for nm, img, base in (("a", a, A_BASE), ("b", b, B_BASE), ("c", c, A_BASE)):
        o = img.find(pat)
        while o >= 0:
            refs.append("%s:0x%06X" % (nm, base + o))
            o = img.find(pat, o + 1)
    check("3-byte references to 0xFF42CD in all three images", refs, ["b:0x%06X" % (THUNK + 1)])
    check("...and T_F42264 is `jp 0xFF42CD`", B(THUNK, 4).hex(),
          "1b" + DRAW.to_bytes(3, "little").hex())
    # 4. the table
    vals = [w(TBL + 4 * i) for i in range(N)]
    check("0xF86EC1: entries that are prom_b directory slots",
          sum(1 for v in vals if 0xF40000 <= v < 0xF44018), 175)
    check("...and the rest all hold 0x00F872C1, the byte after the table",
          sorted({"0x%06X" % v for v in vals if not (0xF40000 <= v < 0xF44018)}),
          ["0x%06X" % (TBL + 4 * N)])
    check("the word BELOW the table is not an address in this map",
          "0x%08X" % w(TBL - 4), "0x01010101")
    check("★ the index whose entry is T_F42264", [i for i, v in enumerate(vals) if v == THUNK], [96])
    # 5. LAST ENTRY, on its own -- this tree's rule
    check("LAST entry [255] at 0x%06X" % (TBL + 4 * 255), "0x%06X" % vals[255], "0x%06X" % (TBL + 4 * N))
    print("\n%d checks ran, %d failed" % (NUM[0], len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
