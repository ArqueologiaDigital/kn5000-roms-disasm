#!/usr/bin/env python3
"""How closely related are prom_b's two parameter-field editors?

QUESTION ANSWERED
  sub_F550A6 (thunk T_F42C78, x77) and IndexedParam_AdjustField at 0xF5535B
  (thunk T_F42C94, x23) look like the same routine.  Before 2026-08-25
  sub_F550A6's header asserted that 0xF5535B "is the same routine with the two
  pointer arguments swapped".  That was written from a reading, not a
  measurement, and it is wrong in two ways this script pins down:

    * 0xF5535B's first argument is an INDEX, not a pointer.  It resolves the
      target through IndexedTable_GetPtr (0xF55321) and then adds descriptor +0.
      sub_F550A6 is handed the target byte's address directly.
    * 0xF5535B journals every change to one of the two appenders
      (List2030_Append4 / Queue2C00_Append4).  sub_F550A6 journals nothing and
      instead returns 1/0 to say whether the byte changed.

  What IS shared is the arithmetic, and this script measures exactly how much:
  the 100-byte adjust core.

WHAT IT PRINTS
  A byte-for-byte comparison of the two cores, every differing byte listed, and
  self-checks on the structural claims above (which thunk names each routine,
  which callee each one reaches, and where each ends).

RUN
  python3 notes/prom_b_param_edit_pair.py
Exit status is non-zero if any self-check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = 0xF00000
CORE_A, CORE_B, CORE_N = 0xF550DB, 0xF553B1, 0x64
FAIL = []


def check(msg, cond):
    print("  %-62s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def main():
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    R = lambda a, n: b[a - B:a - B + n]

    x, y = R(CORE_A, CORE_N), R(CORE_B, CORE_N)
    same = sum(1 for p, q in zip(x, y) if p == q)
    print("adjust core: 0x%06X..0x%06X  vs  0x%06X..0x%06X   (%d bytes)"
          % (CORE_A, CORE_A + CORE_N - 1, CORE_B, CORE_B + CORE_N - 1, CORE_N))
    print("  %d of %d bytes equal" % (same, CORE_N))
    diffs = [(i, p, q) for i, (p, q) in enumerate(zip(x, y)) if p != q]
    for i, p, q in diffs:
        print("  differs at +0x%02X: 0x%06X = %02X   vs   0x%06X = %02X"
              % (i, CORE_A + i, p, CORE_B + i, q))
    print()

    print("self-checks")
    check("exactly one byte of the core differs", len(diffs) == 1)
    check("and it is a frame displacement (0xFE = -2 vs 0xF9 = -7)",
          diffs and diffs[0][1] == 0xFE and diffs[0][2] == 0xF9)
    # thunks
    check("T_F42C78 is `jp 0xF550A6`",
          R(0xF42C78, 4) == bytes([0x1B, 0xA6, 0x50, 0xF5]))
    check("T_F42C94 is `jp 0xF5535B`",
          R(0xF42C94, 4) == bytes([0x1B, 0x5B, 0x53, 0xF5]))
    check("T_F42C98 is `jp 0xF5547B`",
          R(0xF42C98, 4) == bytes([0x1B, 0x7B, 0x54, 0xF5]))
    # the structural difference
    check("sub_F550A6 takes its descriptor from (XIZ+0x0C)  [ae 0c 24]",
          R(0xF550AD, 3) == bytes([0xAE, 0x0C, 0x24]))
    check("0xF5535B takes its descriptor from (XIZ+0x0A)  [ae 0a 24]",
          R(0xF5535B + 7, 3) == bytes([0xAE, 0x0A, 0x24]))
    check("0xF5535B calls IndexedTable_GetPtr (calr to 0xF55321)",
          R(0xF55382, 3) == bytes([0x1E, 0x9C, 0xFF]))
    check("0xF5535B reaches List2030_Append4 (0xF552CC) and "
          "Queue2C00_Append4 (0xF55231)",
          R(0xF55447, 3) == bytes([0x1E, 0x82, 0xFE])
          and R(0xF55470, 3) == bytes([0x1E, 0xBE, 0xFD]))
    check("sub_F550A6 ends with `ret` at 0xF5517A", R(0xF5517A, 1) == b"\x0e")
    check("0xF5535B ends with `ret` at 0xF5547A", R(0xF5547A, 1) == b"\x0e")
    check("0xF5547B ends with `ret` at 0xF5553E", R(0xF5553E, 1) == b"\x0e")
    print()
    print("NOT CHECKED HERE: 'sub_F550A6 journals nothing'.  A raw byte scan")
    print("  cannot tell an opcode from an operand, so a `1E`-not-present test")
    print("  would be a criterion that cannot fail.  That claim rests on the")
    print("  disassembly in prom_b/wsa1_prom_b.s, not on this script.")
    print("self-checks failed: %d" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
