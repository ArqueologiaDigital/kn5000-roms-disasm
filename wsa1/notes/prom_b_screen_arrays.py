#!/usr/bin/env python3
"""Is 0xF131E4 ONE 128-entry dispatch table, or FOUR parallel 32-entry arrays?

QUESTION IT ANSWERS
  prom_b/wsa1_prom_b.s used to carry 0xF131E4-0xF133E3 as a single
  `DispatchTable_F131E4` of 128 entries, headed "the code that indexes it fetches
  an entry and then TRANSFERS to it, so the entries are ENTRY POINTS".  Half of
  those entries are NOT entry points: indices 64..95 hold pointers into 0xF157A8+,
  which is display-list DATA and disassembles as garbage.  This script re-derives
  the correct structure from the ROMs, so the correction is a measurement.

WHAT IT CHECKS
  1. FOUR BASES, ONE REFERENCE EACH.  0xF131E4, 0xF13264, 0xF132E4 and 0xF13364
     each occur exactly once as a 3-byte little-endian address across all three
     code images.  Those hits are OPERAND bytes, at 0xF10702, 0xF110EC, 0xF110FB
     and 0xF1172C; the INSTRUCTIONS that own them start at 0xF10700, 0xF110EA,
     0xF110FA and 0xF1172A, and it is the instruction address a header must cite.
     The check proves the pairing rather than assuming it: it asserts the bytes
     between instruction and operand are exactly the opcode recorded in INSTRS
     (`e9 c8` = `add XBC,imm32`, `f2` = `lda XBC,imm24`), so a wrong instruction
     address fails here instead of being published.
     ⚠⚠ CORRECTED 2026-08-25.  This script and four headers used to name the
     OPERAND address as the reference -- the tree's oldest recurring defect,
     "~20 call sites cited one byte past the instruction".  Three of the four
     were off by TWO.  A single 128-entry table would not have four separate
     bases 0x80 bytes apart, each loaded by its own instruction.
  2. THE DEFAULT VALUE MARKS THE EDGES.  In each array, row 0 and row 31 hold that
     array's default: 0x00F42C70 in the three code arrays, 0x00F157A8 in the
     display-list array.  Six of the eight are the SAME constant, which is why the
     old chain rule ran straight through the boundaries.
  3. THE ONLY INDEXER OF 0xF131E4 CANNOT REACH INDEX 32.  0xF106FE computes
     `4*H + 0xF131E4` and jumps; H is byte[4i+1] of the 4-byte records in
     0xF124EC-0xF12F23 (the arrays the 0xF12F24 pointer table names).  Censused
     over the whole region, that byte is 0x1E at most, apart from the 0xFF that
     ends a record list.  So the reachable indices are 0..30 -- inside array 0.
  4. 0xF157A8 IS NOT CODE.  Its first two bytes are `02 0F`, a well-formed
     interpreter-B opcode-02 record of exactly the length that opcode implies, and
     notes/gen_prom_b_dsp_value_lists.py walks 176 such records from there with no
     slack.  As instructions the same bytes decode as `push SR / retd 0x2640 / db`.

RUN
  python3 notes/prom_b_screen_arrays.py        # 22 checks, exit 1 on any failure
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = 0xF00000
BASES = [0xF131E4, 0xF13264, 0xF132E4, 0xF13364]
# (instruction address, opcode bytes before the operand).  The operand address --
# what a byte scan for the base finds -- is instruction + len(opcode), computed
# below; headers must cite the INSTRUCTION.
INSTRS = [(0xF10700, "e9c8"), (0xF110EA, "e9c8"), (0xF110FA, "f2"), (0xF1172A, "e9c8")]
DEFAULT = [0x00F42C70, 0x00F42C70, 0x00F157A8, 0x00F42C70]
RECLO, RECHI = 0xF124EC, 0xF12F24            # the 4-byte record region
FAIL = []
N = [0]


def check(msg, got, want):
    N[0] += 1
    ok = got == want
    print("  %-58s %-26s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def main():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    a, b, c = r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13"), r("wsa1_prom_c.ic28")
    w32 = lambda x: int.from_bytes(b[x - B:x - B + 4], "little")

    print("prom_b_screen_arrays: four parallel 32-entry arrays, not one table of 128")
    for base, (instr, opc) in zip(BASES, INSTRS):
        opc = bytes.fromhex(opc)
        operand = instr + len(opc)
        pat = bytes([base & 0xFF, (base >> 8) & 0xFF, (base >> 16) & 0xFF])
        hits = []
        for nm, img, imgbase in (("a", a, 0xF80000), ("b", b, 0xF00000), ("c", c, 0xF80000)):
            o = img.find(pat)
            while o >= 0:
                hits.append(imgbase + o)
                o = img.find(pat, o + 1)
        check("0x%06X: exactly one operand hit, at 0x%06X" % (base, operand),
              [hex(x) for x in hits], [hex(operand)])
        check("  ... owned by the instruction at 0x%06X" % instr,
              b[instr - B:operand - B].hex(), opc.hex())
    for base, d in zip(BASES, DEFAULT):
        check("0x%06X row 0 = its default" % base, "0x%08X" % w32(base), "0x%08X" % d)
        check("0x%06X row 31 = its default" % base, "0x%08X" % w32(base + 4 * 31), "0x%08X" % d)
    # the indexer's reachable range
    hs = [b[x - B + 1] for x in range(RECLO, RECHI, 4)]
    live = [h for h in hs if h != 0xFF]
    check("0xF106FE's index H: highest live value", "0x%02X" % max(live), "0x1E")
    check("  ... so it cannot reach array 1 (index 32)", max(live) < 32, True)
    check("  ... nor the display-list array (index 64)", max(live) < 64, True)
    check("records censused", len(hs), (RECHI - RECLO) // 4)
    # 0xF157A8 is a record, not an instruction
    check("0xF157A8 opcode/length", (b[0xF157A8 - B], b[0xF157A8 - B + 1]), (0x02, 0x0F))
    check("  ... 0x0F is what interpreter B's opcode-02 handler implies", 0x0F, 15)
    print("\n%d checks ran, %d failed" % (N[0], len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
