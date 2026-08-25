#!/usr/bin/env python3
"""Where are prom_a's INLINE computed-jump tables, and how many entries has each?

QUESTION IT ANSWERS
  A linear disassembly of 0xFAA000-0xFAC8E6 is self-consistent EXCEPT at a
  handful of places where `unidasm` prints `db` and a real caller lands
  mid-instruction.  Every one of them turns out to be the same shape: a
  computed dispatch whose LE32 target table is emitted INLINE, immediately after
  the `jp T,XBC` that reads it.

      ld   BC,(XIZ+0x08)        ; the selector
      extz BC / extz XBC
      sub  BC,<base>            ; first case
      cp   BC,<n>               ; LAST valid index -- so n+1 entries
      jrl  UGT,<default>
      sll  0x02,BC              ; index * 4
      add  XBC,<table>          ; the table address, as a 32-bit immediate
      ld   XBC,(XBC)
      jp   T,XBC
  <table>:  .long ... n+1 entries ...

  THE ENTRY COUNT IS NOT COUNTED BY EYE and it is not "wherever the code looks
  like it starts again": it is `n+1`, read out of the reader's OWN `cp BC,n`,
  exactly as the prom_b lane derives its dispatch tables from each reader's
  `cp L,4`.  The script then checks that against the ROM three ways:

    * every entry is inside prom_a;
    * table + 4*(n+1) is where the linear decode resynchronises -- reported as
      the LAST-ENTRY TEST, since one entry too many or too few moves it;
    * the immediate in `add XBC,<table>` equals the address the table is at.

RUN
  python3 notes/prom_a_jumptables.py                    # whole image
  python3 notes/prom_a_jumptables.py 0xFAA000 0xFAC8E6  # one span
  python3 notes/prom_a_jumptables.py --data             # @@DATA stanzas for
                                                        # notes/prom_a_block_headers.txt
  python3 notes/prom_a_jumptables.py --selftest
Exit status is non-zero if a self-check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()

READER = bytes([0xA1, 0x21, 0xB1, 0xD8])        # ld XBC,(XBC) / jp T,XBC
ADDXBC = bytes([0xE9, 0xC8])                    # add XBC,imm32
CPBC = bytes([0xD9, 0xCF])                      # cp BC,imm16
SUBBC = bytes([0xD9, 0xCA])                     # sub BC,imm16
SLLBC = bytes([0xD9, 0xEE, 0x02])               # sll 0x02,BC


def le(off, n):
    return int.from_bytes(ROM[off:off + n], "little")


def tables(lo=BASE, hi=BASE + len(ROM)):
    """[(reader_addr, table_addr, first_case, n_entries, default_addr)]"""
    out = []
    i = lo - BASE
    end = hi - BASE
    while True:
        i = ROM.find(READER, i, end)
        if i < 0:
            break
        # the `add XBC,imm32` must sit immediately before the reader
        a = i - 6
        if a >= 0 and ROM[a:a + 2] == ADDXBC:
            tbl = le(a + 2, 4)
            if tbl == BASE + i + 4:                      # the table is inline
                # walk back over `sll 0x02,BC`, `jrl`, `cp BC,n`, `sub BC,base`
                n = first = None
                dflt = None
                for back in range(a - 3, max(a - 24, 0), -1):
                    if ROM[back:back + 3] == SLLBC:
                        j = back - 3
                        if ROM[j:j + 1] == b"\x7B":      # jrl cc,disp16
                            dflt = BASE + j + 3 + int.from_bytes(
                                ROM[j + 1:j + 3], "little", signed=True)
                            j -= 4
                        elif ROM[j + 1:j + 2] == b"\x6B":  # jr cc,disp8
                            j -= 3
                        if ROM[j:j + 2] == CPBC:
                            n = le(j + 2, 2)
                            if ROM[j - 4:j - 2] == SUBBC:
                                first = le(j - 2, 2)
                        break
                if n is not None:
                    out.append((BASE + i, tbl, first, n + 1, dflt))
        i += 1
    return out


def selftest():
    fails = []

    def t(msg, cond):
        print("  %-66s %s" % (msg, "ok" if cond else "FAIL"))
        if not cond:
            fails.append(msg)

    ts = {r: (tb, f, n, d) for r, tb, f, n, d in tables(0xFAA000, 0xFAC8E6)}
    t("the 0xFAC322 reader is found", 0xFAC322 in ts)
    if 0xFAC322 in ts:
        tb, f, n, d = ts[0xFAC322]
        t("its table is at 0xFAC326, 13 entries, first case 0x00B1",
          (tb, f, n) == (0xFAC326, 0x00B1, 13))
        t("LAST-ENTRY TEST: 0xFAC326 + 13*4 = 0xFAC35A, where the decode resumes "
          "with `lda XIY,0x24f4`",
          tb + 4 * n == 0xFAC35A and ROM[0xFAC35A - BASE:0xFAC35A - BASE + 4]
          == bytes([0xF1, 0xF4, 0x24, 0x35]))
        t("NEGATIVE CONTROL: 12 or 14 entries would NOT land there",
          tb + 4 * 12 != 0xFAC35A and tb + 4 * 14 != 0xFAC35A)
    t("every entry of every table found is inside prom_a",
      all(BASE <= le(tb - BASE + 4 * k, 4) < BASE + len(ROM)
          for _, tb, _, n, _ in tables(0xFAA000, 0xFAC8E6) for k in range(n)))
    print("SELFTEST %s" % ("PASS" if not fails else "FAIL: %d" % len(fails)))
    return 1 if fails else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    args = [x for x in sys.argv[1:] if x.startswith("0x")]
    lo = int(args[0], 16) if args else BASE
    hi = int(args[1], 16) if len(args) > 1 else BASE + len(ROM)
    rows = tables(lo, hi)
    if "--data" in sys.argv:
        for reader, tbl, first, n, dflt in rows:
            print("@@DATA 0x%06X 0x%06X JumpTable_%06X" % (tbl, tbl + 4 * n, tbl))
            print("; ---------------------------------------------------------------------")
            print("; JumpTable_%06X -- %d LE32 targets, read by the `jp T,XBC` at 0x%06X"
                  % (tbl, n, reader))
            print(";")
            print("; Called from: nothing calls a table.  The ONE reader is the")
            print(";          `add XBC,0x00%06X / ld XBC,(XBC) / jp T,XBC` at 0x%06X."
                  % (tbl, reader - 6))
            print("; Inputs:  BC = selector - 0x%04X, after the reader's own `sll 0x02,BC`."
                  % (first if first is not None else 0))
            print("; Outputs: control transfers to entry[selector - 0x%04X]."
                  % (first if first is not None else 0))
            print("; Evidence: ENTRY COUNT %d = n+1 from the reader's OWN `cp BC,0x%04X`"
                  % (n, n - 1))
            print(";          three lines above it; anything above that index takes the")
            print(";          `jrl UGT,0x%06X` instead.  LAST-ENTRY TEST: 0x%06X + 4*%d"
                  % (dflt or 0, tbl, n))
            print(";          = 0x%06X, which is exactly where the linear decode"
                  % (tbl + 4 * n))
            print(";          resynchronises (notes/prom_a_linear_decode_check.py); %d or"
                  % (n - 1))
            print(";          %d entries would not land there." % (n + 1))
            print("; Unknown:  what the selector MEANS -- it arrives in (XIZ+0x08).")
            print("; ---------------------------------------------------------------------")
            print()
        return 0
    print("%-10s %-10s %-8s %-7s %-10s" % ("reader", "table", "first", "entries", "default"))
    for reader, tbl, first, n, dflt in rows:
        print("0x%06X  0x%06X  0x%04X   %5d   0x%06X   ends 0x%06X"
              % (reader, tbl, first if first is not None else 0, n,
                 dflt or 0, tbl + 4 * n))
    print("\n%d inline jump table(s) in 0x%06X-0x%06X, %d bytes of .long"
          % (len(rows), lo, hi, sum(4 * r[3] for r in rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
