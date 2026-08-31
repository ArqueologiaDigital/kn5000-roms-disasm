#!/usr/bin/env python3
"""Where are prom_c's COMPUTED-GOTO tables, how many entries has each, and how is
that count established?

QUESTION ANSWERED
  A `switch` compiled by this toolchain becomes

      cp   rr,n              <- the guard: the LARGEST accepted index
      jr   UGT,default       <- or `jrl UGT`
      sll  0x02,rr
      add  Xrr,0x00TTTTTT    <- the table address, as a 32-bit immediate
      ld   Xrr,(Xrr)
      jp   (Xrr)

  where rr is WA **or BC** -- ⚠ BOTH register pairs occur, and a scanner that knows
  only the WA form silently misses tables.  The 49-entry table at 0xFAF08F is a BC
  one; it was found not by this script but by the decode-alignment check in
  notes/gen_prom_c_block.py, after this script reported the range as table-free.
  A `dec 1,rr` may sit between the guard and the shift when the switch is 1-based.

  and the table is (n+1) little-endian 32-bit pointers at 0x00TTTTTT, sitting in the
  middle of the code.  A linear disassembler decodes those pointer bytes as
  instructions -- and worse, they often decode to something that RE-ENCODES to the
  same bytes, so a listing built from a linear decode can pass the byte gate while
  claiming a `pop DE` where the ROM holds the low half of a pointer.  This finds them
  so they can be emitted as `.long`.

  ★ It was written because exactly that happened: converting 0xFA7E2C-0xFABE2F from a
  linear decode put a label reference where the table byte 0x25 lives at 0xFA9024, and
  notes/prom_c_verify_fragment.py caught the rebuilt byte as 0x26.

HOW THE ENTRY COUNT IS ESTABLISHED -- two independent readings, required to agree
  1. THE GUARD.  The `cp WA,n` immediately before the shift gives n; the table has
     n+1 entries because the guard rejects only indices strictly greater than n
     (`jr UGT`).
  2. THE CONTENTS.  Consecutive 32-bit words are read from the table while each is a
     plausible code address in this ROM (0xF80000-0xFFFFFF); the first word that is
     not ends the table.
  A table is reported only when both give the same number.  Disagreements are printed
  as DISAGREE rows and must be read, never averaged.

LIMITS
  * Only this ONE idiom is matched, by exact bytes.  A switch compiled any other way,
    or a table reached through a register loaded far away, is invisible here.
  * "Plausible code address" is a range test, not proof that the target is code.
  * The guard is matched only in its 2-byte (`cp WA,imm3`) and 4-byte
    (`cp WA,imm16`) spellings; anything else is reported with guard = None.

RUN
  python3 notes/prom_c_jumptables.py                      # every table in the image
  python3 notes/prom_c_jumptables.py 0xFA7E2C 0xFABE30    # only inside a range
  python3 notes/prom_c_jumptables.py --selftest
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
IMG = open(ROM, "rb").read()

# (dispatch, add-prefix, shift, cp-prefix) for each register pair the idiom uses.
FORMS = [
    (b"\xa0\x20\xb0\xd8", b"\xe8\xc8", b"\xd8\xee\x02", 0xD8),   # XWA / WA
    (b"\xa1\x21\xb1\xd8", b"\xe9\xc8", b"\xd9\xee\x02", 0xD9),   # XBC / BC
]


def tables():
    """(dispatch_addr, table_addr, guard_n, content_n, has_shift) per matched idiom."""
    out = []
    for DISPATCH, ADDX, SHIFT, CPPFX in FORMS:
        i = 0
        while True:
            i = IMG.find(DISPATCH, i)
            if i < 0:
                break
            add_off = i - 6
            if add_off >= 0 and IMG[add_off:add_off + 2] == ADDX:
                tbl = struct.unpack_from("<I", IMG, add_off + 2)[0]
                sh_off = add_off - 3
                has_shift = sh_off >= 0 and IMG[sh_off:sh_off + 3] == SHIFT
                guard = None
                if has_shift:
                    # the out-of-range branch sits between guard and shift:
                    # `jr UGT,disp8` = 6B dd (2 bytes) or `jrl UGT,disp16` = 7B dd dd (3).
                    # A `dec 1,rr` (D8/D9 69) may sit after the guard as well, so search
                    # a short window backwards rather than assuming a fixed shape.
                    for back in range(2, 12):
                        b = sh_off - back
                        if b < 4:
                            break
                        if IMG[b] == 0x6B or IMG[b] == 0x7B:
                            if IMG[b - 2] == CPPFX and 0xD8 <= IMG[b - 1] <= 0xDF:
                                guard = IMG[b - 1] - 0xD8
                            elif IMG[b - 4] == CPPFX and IMG[b - 3] == 0xCF:
                                guard = struct.unpack_from("<H", IMG, b - 2)[0]
                            if guard is not None:
                                break
                n = 0
                off = tbl - BASE
                while 0 <= off + 4 * n + 4 <= len(IMG):
                    w = struct.unpack_from("<I", IMG, off + 4 * n)[0]
                    if not (0xF80000 <= w <= 0xFFFFFF):
                        break
                    n += 1
                out.append((BASE + add_off, tbl, guard, n, has_shift))
            i += 1
    return sorted(out, key=lambda r: r[1])


def selftest():
    fails = []
    ts = {t[1]: t for t in tables()}
    # 1. the table that broke the first conversion of the voice-parameter module
    if 0xFA9032 not in ts:
        fails.append("the table at 0xFA9032 -- the one that broke a conversion -- is not found")
    else:
        _, _, g, n, sh = ts[0xFA9032]
        if not (g == 5 and n == 6 and sh):
            fails.append("0xFA9032: guard=%s entries=%s (expected 5 and 6)" % (g, n))
    # 2. LAST-ENTRY control: entry 5 of that table must be a code address in the module
    last = struct.unpack_from("<I", IMG, 0xFA9032 - BASE + 5 * 4)[0]
    if not (0xFA7E2C <= last < 0xFABE30):
        fails.append("entry 5 of 0xFA9032 is 0x%06X, outside the module" % last)
    # 3. NEGATIVE control: the byte after the table must NOT be a plausible entry,
    #    otherwise the content walk would have run past it
    past = struct.unpack_from("<I", IMG, 0xFA9032 - BASE + 6 * 4)[0]
    if 0xF80000 <= past <= 0xFFFFFF:
        fails.append("the word after the 0xFA9032 table (0x%08X) looks like an entry" % past)
    # 4. the BC-form table at 0xFAF08F -- the one a WA-only scanner missed
    if 0xFAF08F not in ts:
        fails.append("the BC-form table at 0xFAF08F is not found")
    else:
        _, _, g, n, sh = ts[0xFAF08F]
        if not (g == 0x30 and n == 49):
            fails.append("0xFAF08F: guard=%s entries=%s (expected 0x30 and 49)" % (g, n))
    # 5. every table found must have guard+1 == entries, or be reported as DISAGREE
    for a, t, g, n, sh in tables():
        if g is not None and g + 1 != n:
            print("  note: DISAGREE at 0x%06X table 0x%06X guard %d entries %d" % (a, t, g, n))
    for f in fails:
        print("  FAIL " + f)
    print("SELFTEST %s" % ("FAIL" if fails else "PASS"))
    return 1 if fails else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo = int(args[0], 0) if args else 0
    hi = int(args[1], 0) if len(args) > 1 else 0x1000000
    print("  %-10s %-10s %6s %8s %-9s %s" %
          ("dispatch", "table", "guard", "entries", "verdict", "extent"))
    for a, t, g, n, sh in tables():
        if not (lo <= t < hi):
            continue
        if g is None:
            v = "GUARD?"
        elif g + 1 == n:
            v = "agree"
        else:
            v = "DISAGREE"
        print("  0x%06X   0x%06X   %6s %8d %-9s 0x%06X-0x%06X"
              % (a, t, g if g is not None else "-", n, v, t, t + 4 * n - 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
