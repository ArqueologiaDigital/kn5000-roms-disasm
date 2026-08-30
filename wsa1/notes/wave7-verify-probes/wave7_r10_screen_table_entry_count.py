#!/usr/bin/env python3
"""Do the five per-screen handler tables hold 23 entries or 32?

QUESTION IT ANSWERS
    "A claim repeated in this tree since round 7 says these tables are 32-entry.
     Are they?"  They are not.  They hold 23.

WHY IT MATTERS BEYOND THE COUNT
    The bound lives in prom_b sub_F55019 (reached via T_F42C74), which rejects a
    raw index above 0x1F and then REMAPS it -- 0x11..0x19 become 0..8, and
    0x1A..0x1F become 17..22 -- so what reaches `mul A,0x04` is 0..22, which is
    23 slots.  That remapper is a LAYER-2 result in its own right: the per-screen
    tables are NOT indexed by the raw class-0xA9 event code.  It is also why
    round 9's census saw indices 0x10-0x1F as sparse (non-default in at most 14
    of 32 tables) while 0x00-0x0F were non-default in 31 or 32 -- the top half
    folds back onto the bottom.

WHERE THE 32 CAME FROM
    Round 7 established genuine 32-entry objects elsewhere: prom_b 0xF7D2D8
    onwards, spaced 0x80 = 32*4, indexed by panel button number.  The count was
    transplanted from that shape onto tables that do not have it. A number that
    is true of one object is not thereby true of its neighbour.

RUN
    python3 notes/wave7-verify-probes/wave7_r10_screen_table_entry_count.py
    python3 notes/wave7-verify-probes/wave7_r10_screen_table_entry_count.py --selftest
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A_BASE = 0xF80000
TABLES = [0xFA1690, 0xFA176E, 0xFA17CF, 0xFA1A02]   # the four in prom_a
ROM_LO, ROM_HI = 0xF00000, 0xFFFFFF


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def run_length(d, base, cap=40):
    """How many CONSECUTIVE longwords from `base` are ROM addresses?"""
    n = 0
    while n < cap:
        v = struct.unpack_from("<I", d, base - A_BASE + 4 * n)[0]
        if not (ROM_LO <= v <= ROM_HI):
            return n, v
        n += 1
    return n, None


def report():
    d = rom()
    print("table       consecutive ROM pointers   first non-pointer longword")
    for b in TABLES:
        n, v = run_length(d, b)
        print("  0x%06X   %2d                         0x%08X" % (b, n, v))
    print("\ngap to the next table, and what each count would need:")
    ts = sorted(TABLES)
    for a, b in zip(ts, ts[1:]):
        print("  0x%06X -> 0x%06X: %3d bytes   (23 entries need 92, 32 need 128)"
              % (a, b, b - a))
    print("\nSo a 32-entry table at 0xFA176E would run 31 bytes INTO the table at")
    print("0xFA17CF, while 23 entries end 5 bytes short of it. 23 it is.")


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    d = rom()
    for b in TABLES:
        n, v = run_length(d, b)
        check("0x%06X holds exactly 23 consecutive ROM pointers" % b, n == 23, "got %d" % n)
        check("0x%06X entry[23] is NOT a ROM address" % b,
              not (ROM_LO <= v <= ROM_HI), "0x%08X" % v)
    # the neighbour test, which is what makes 32 impossible rather than merely unobserved
    check("0xFA176E -> 0xFA17CF is 97 bytes, too few for 32 entries (128)",
          0xFA17CF - 0xFA176E == 97)
    check("...and enough for 23 (92), with 5 bytes to spare",
          0xFA17CF - 0xFA176E - 23 * 4 == 5)
    # LAST table checked explicitly, not only the first
    n, v = run_length(d, TABLES[-1])
    check("the LAST table 0x%06X also stops at 23" % TABLES[-1], n == 23)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else (report() or 0))
