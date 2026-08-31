#!/usr/bin/env python3
"""How big are the two selector-dispatch tables at prom_b 0xF5B8F8 and 0xF5B9F8?

QUESTION ANSWERED
  0xF5B8B6 and 0xF5B9B8 are two of the busiest routines the thunk table names
  (T_F41ED0 x39, T_F41ED4 x109).  Each indexes a table of 32-bit routine
  pointers with a 16-bit selector.  The code's own bound would allow 64 entries
  (0x80..0xBF) but the tables are shorter than that.  This script establishes
  the real length, and refuses to take the bound's word for it.

THE ARGUMENT, and every byte it rests on is re-read here
  1. Each dispatcher's two `ld XIY,imm32` immediates give the two table bases.
  2. All 48 words from each base are inside 0x00F00000-0x00FFFFFF.
  3. The 49th word of each is NOT (0x3B3A3938 and 0x5B5C5D5E -- both are runs of
     TLCS-900 push/pop opcodes, i.e. the next routine's register-save prologue).
  4. base + 48*4 lands exactly on: for the first table, the `push XIZ` (0x3E)
     that starts the second dispatcher; for the second, the `push XWA` (0x38)
     that starts the next routine.  Nothing is left over between them.

  So 48 is measured, not assumed, and the aliasing the code implies (selector
  0xC0+n reaches the same entry as 0xA0+n, for n < 16, and higher selectors run
  off the end) is a property of the CODE, stated but not asserted as intent.

RUN
  python3 notes/prom_b_dispatch_tables.py
Exit status is non-zero if any of the four checks fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B_BASE = 0xF00000
DISPATCHERS = [(0xF5B8B6, 0xF5B8F8, 0xF5B978), (0xF5B9B8, 0xF5B9F8, 0xF5BA78)]
N = 48


def main():
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    L = lambda p: int.from_bytes(b[p - B_BASE:p - B_BASE + 4], "little")
    bad = 0
    for disp, lo, hi in DISPATCHERS:
        # 1. the bases really are the dispatcher's immediates
        i_hi = b.index(bytes([0x45]) + hi.to_bytes(3, "little") + b"\x00", disp - B_BASE, disp - B_BASE + 0x40)
        i_lo = b.index(bytes([0x45]) + lo.to_bytes(3, "little") + b"\x00", disp - B_BASE, disp - B_BASE + 0x40)
        print("0x%06X: `ld XIY,0x%06X` at 0x%06X, `ld XIY,0x%06X` at 0x%06X"
              % (disp, hi, B_BASE + i_hi, lo, B_BASE + i_lo))
        assert hi == lo + 0x80, "table_hi is not table_lo + 0x80"
        # 2. all N entries are ROM pointers
        n_ok = sum(1 for i in range(N) if 0xF00000 <= L(lo + 4 * i) <= 0xFFFFFF)
        # 3. the next word is not
        nxt = L(lo + 4 * N)
        # 4. abutment
        end = lo + 4 * N
        ok = (n_ok == N) and not (0xF00000 <= nxt <= 0xFFFFFF)
        print("   entries 0..%d inside 0x00F00000-0x00FFFFFF: %d of %d   %s"
              % (N - 1, n_ok, N, "OK" if n_ok == N else "FAIL"))
        print("   first word past the table (0x%06X) = 0x%08X   %s"
              % (end, nxt, "OK, not a pointer" if not (0xF00000 <= nxt <= 0xFFFFFF) else "FAIL"))
        print("   table ends at 0x%06X, first byte there = 0x%02X (%s)"
              % (end, b[end - B_BASE],
                 "push XIZ -- the next dispatcher" if b[end - B_BASE] == 0x3E else
                 "push XWA -- a register-save prologue" if b[end - B_BASE] == 0x38 else "UNEXPECTED"))
        print("   default entry 0xF5BF17 (a bare `ret`, byte 0x%02X) fills %d slots"
              % (b[0xF5BF17 - B_BASE], sum(1 for i in range(N) if L(lo + 4 * i) == 0xF5BF17)))
        print("   distinct targets: %d" % len({L(lo + 4 * i) for i in range(N)}))
        if not ok or b[end - B_BASE] not in (0x3E, 0x38):
            bad += 1
        print()
    print("VERDICT: both tables are exactly %d entries" % N if not bad
          else "VERDICT: %d table(s) FAILED" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
