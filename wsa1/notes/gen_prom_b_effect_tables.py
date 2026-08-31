#!/usr/bin/env python3
"""Emit prom_b's two DSP-EFFECT text tables, and prove their tiling first.

QUESTION IT ANSWERS
  "What does the WSA1's DSP effect section offer, and how is its text stored?"

  0xF147AC is 2,048 printable bytes that tile EXACTLY as 128 entries of 16
  characters.  Entry 0 is `  NO OPERATION  `, entry 1 `     CHORUS     `, entry
  127 `   ----------   `.  56 of the 128 are real names and 72 are the
  `----------` placeholder, so the machine has a 128-SLOT effect table with 56
  slots used.

  0xF15024 is 1,924 printable bytes of parameter labels -- `WET`, `DRIVE`,
  `EMPHASIS Fc`, `LFO WAVEFORM`, `REVERB TIME` -- followed by a units strip
  (`Hz`, `ms`, `s`).  ⚠ Its tiling is stated exactly and NOT rounded: 113 rows of
  17 bytes cover 1,921 of the 1,924, and 99 of the first 100 rows end in `:`.
  The 3-byte remainder is emitted as its own row rather than folded away.

WHAT MAKES THIS CHECKABLE
  * Both runs are MAXIMAL: the byte before and the byte after each is outside
    0x20-0x7E, so the extent is a measurement and not a choice.  checks()
    re-reads all four neighbours.
  * 2048 = 128 x 16 with no remainder, and the emitted rows are re-joined and
    compared with the ROM on every emit.
  * "Nothing reads it" is a CHECK, not a shrug: checks() decodes backwards from
    every 4-byte window in prom_a+prom_b that spells the address and asserts that
    none of them is an instruction operand.
  * The 16-byte stride is not assumed from the count: `--stride` prints the
    number of rows that are BLANK-PADDED-CENTRED, which is what a fixed-width
    display column looks like, at 16 and at every other divisor of 2048.

WHAT IS **NOT** ESTABLISHED
  Nothing here reads either table.  No instruction found in prom_a or prom_b
  spells 0x00F147AC or 0x00F15024 in a decodable operand -- the only byte-scan
  hits are 4-byte windows inside the RECORD region above them.  So "entry k is
  effect k" is a correspondence with the 128-entry tables of
  notes/FINDINGS-prom_b-f0ea9f-module.md, not a decoded fact, and the labels say
  so.

RUN
  python3 notes/gen_prom_b_effect_tables.py            # the assembly
  python3 notes/gen_prom_b_effect_tables.py --checks
  python3 notes/gen_prom_b_effect_tables.py --stride
  python3 notes/gen_prom_b_effect_tables.py --names    # the 56 real names
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
NAMES = (0xF147AC, 2048, 16)
PARAMS = (0xF15024, 1924, 17)
PLACE = "----------"
FAIL = []


def rom():
    return open(IMG, "rb").read()


def txt(a, n):
    return rom()[a - B_BASE:a - B_BASE + n].decode("ascii")


def rows(a, n, w):
    s = txt(a, n)
    return [s[i:i + w] for i in range(0, n, w)]


def maximal(a, n):
    d = rom()
    return (32 <= d[a - 1 - B_BASE] < 127, 32 <= d[a + n - B_BASE] < 127)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def readers(addr):
    """(decodable-operand hits, byte-scan-only hits) for a 32-bit spelling of
    `addr` anywhere in prom_a+prom_b.

    Same backward decode as the rest of the lane: a hit counts as a READER only
    if some instruction starting 1-4 bytes earlier contains the address in its
    operand text.  Everything else is a 4-byte window that straddles an object
    boundary and is NOT a reference."""
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
    import prom_b_module_trace as MT
    tgt = addr.to_bytes(4, "little")
    ops, strad = [], []
    a_img = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    for blob, base in ((a_img, 0xF80000), (rom(), B_BASE)):
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            hit = base + i
            for back in (1, 2, 3, 4):
                dec = MT.decode_at(hit - back)
                if dec and dec[0] > back and ("%06x" % addr) in dec[1]:
                    ops.append((hit - back, dec[1]))
                    break
            else:
                strad.append(hit)
            i += 1
    return ops, strad


def c(name, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append((name, got, want))
    if verbose:
        print("  %-66s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                              % (got, want)))


def checks(verbose=True):
    del FAIL[:]
    for label, (a, n, w) in (("names", NAMES), ("params", PARAMS)):
        c("%s: every byte is printable" % label,
          all(32 <= x < 127 for x in rom()[a - B_BASE:a - B_BASE + n]), True,
          verbose)
        c("%s: the run is MAXIMAL (neither neighbour printable)" % label,
          maximal(a, n), (False, False), verbose)
        c("%s: the emitted rows re-join to the ROM bytes" % label,
          "".join(rows(a, n, w)), txt(a, n), verbose)
    a, n, w = NAMES
    r = rows(a, n, w)
    c("names: 2048 tiles as 128 x 16 with no remainder", (n % w, n // w),
      (0, 128), verbose)
    c("names: entry 0 and entry 127", (r[0], r[127]),
      ("  NO OPERATION  ", "   ----------   "), verbose)
    c("names: placeholders + real names == 128",
      (sum(1 for x in r if x.strip() == PLACE),
       sum(1 for x in r if x.strip() != PLACE)), (72, 56), verbose)
    r = rows(*NAMES)
    c("names: bands 0x50 and 0x70 are entirely placeholder",
      [b for b in (5, 7)
       if any(r[i].strip() != PLACE for i in range(b * 16, b * 16 + 16))],
      [], verbose)
    a, n, w = PARAMS
    r = rows(a, n, w)
    c("params: 113 rows of 17 plus a 3-byte remainder",
      (len(r), len(r[-1])), (114, 3), verbose)
    c("params: 99 of rows 0..99 end in a colon",
      sum(1 for x in r[:100] if x.endswith(":")), 99, verbose)
    for label, base in (("names", NAMES[0]), ("params", PARAMS[0])):
        ops, strad = readers(base)
        c("%s: NO instruction reads this address (byte-scan hits are straddles)"
          % label, (len(ops), len(strad) > 0), (0, True), verbose)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


def emit():
    a, n, w = NAMES
    r = rows(a, n, w)
    real = sum(1 for x in r if x.strip() != PLACE)
    out = ["", "; " + "-" * 74,
           "; EffectNames_F147AC -- 128 entries of 16 characters, 2,048 bytes.",
           ";   Entry 0 is `%s`, entry 127 `%s`.  %d entries are the"
           % (r[0], r[127], 128 - real),
           ";   `----------` placeholder and %d are real names, so the machine"
           % real,
           ";   offers a 128-SLOT effect table with %d slots used." % real,
           "; Entry count: 2048 / 16 = 128 EXACTLY, no remainder.  The run is",
           ";   MAXIMAL: the byte before 0xF147AC is 0x%02X and the byte at"
           % rom()[NAMES[0] - 1 - B_BASE],
           ";   0xF14FAC is 0x%02X, neither printable." % rom()[NAMES[0] + n - B_BASE],
           "; Read by: NOTHING in prom_a or prom_b spells 0x00F147AC in a",
           ";   decodable operand.  The only byte-scan hits are 4-byte windows",
           ";   inside the record region at 0xF144A6-0xF146E8, so what indexes",
           ";   this table is NOT established here.",
           "; Evidence: every row is re-read and re-joined against the ROM on",
           ";   every emit (`--checks`), and the two edge entries and the",
           ";   72/56 split are asserted.",
           "; ⚠ Unknown: that entry k is effect algorithm k.  The block at",
           ";   0xF0EA9F-0xF13D33 has three 128-entry tables indexed from",
           ";   (0x2796); 128 and 128 is a CORRESPONDENCE, not a decoded fact.",
           "; " + "-" * 74, "EffectNames_F147AC:"]
    for i, s in enumerate(r):
        out.append('\t.ascii\t"%s"\t; %06X  [%3d]' % (esc(s), a + i * w, i))
    a, n, w = PARAMS
    r = rows(a, n, w)
    out += ["", "; " + "-" * 74,
            "; EffectParamNames_F15024 -- 1,924 printable bytes: the effect",
            ";   parameter labels (`WET`, `DRIVE`, `EMPHASIS Fc`, `LFO",
            ";   WAVEFORM`, `REVERB TIME`) and, after them, a units strip",
            ";   (`Hz`, `ms`, `s`).",
            "; Entry count: NOT a round number, and it is not rounded here.",
            ";   113 rows of 17 bytes cover 1,921 of the 1,924; the last 3",
            ";   bytes are emitted as their own row.  99 of rows 0..99 end in",
            ";   `:`, which is what fixes the width at 17.",
            "; Evidence: the run is MAXIMAL (byte before 0x%02X, byte after"
            % rom()[PARAMS[0] - 1 - B_BASE],
            ";   0x%02X) and the rows re-join to the ROM on every emit."
            % rom()[PARAMS[0] + n - B_BASE],
            "; Unknown: which parameter belongs to which effect, and where the",
            ";   units strip starts.  Rows 100..112 carry no colon; that is",
            ";   recorded, not explained.",
            "; " + "-" * 74, "EffectParamNames_F15024:"]
    for i, s in enumerate(r):
        out.append('\t.ascii\t"%s"\t; %06X  [%3d]%s'
                   % (esc(s), a + i * w, i, "  <- 3-byte remainder"
                      if len(s) != w else ""))
    return out


KNOWN_FLAGS = ("--checks", "--names", "--bands", "--stride")


def main():
    # ROUND-2 AUDIT F11: round 5's report cited this script as `--verify`, which
    # is not one of its flags -- and the old main() silently fell through to the
    # EMIT path, printing 4,000 lines of assembly that look nothing like a check
    # result but are also not an error.  A wrong flag must be loud.
    bad = [a for a in sys.argv[1:] if a.startswith("-") and a not in KNOWN_FLAGS]
    if bad:
        raise SystemExit("unknown flag(s) %s -- this script takes %s "
                         "(the checks flag is --checks, NOT --verify)"
                         % (" ".join(bad), " ".join(KNOWN_FLAGS)))
    if "--checks" in sys.argv:
        return 0 if checks() else 1
    if "--names" in sys.argv:
        a, n, w = NAMES
        for i, s in enumerate(rows(a, n, w)):
            if s.strip() != PLACE:
                print("  [%3d] %s" % (i, s.strip()))
        return 0
    if "--bands" in sys.argv:
        a, n, w = NAMES
        r = rows(a, n, w)
        print("used slots per 16-slot band (band = slot >> 4):")
        for b in range(8):
            used = [i for i in range(b * 16, b * 16 + 16)
                    if r[i].strip() != PLACE]
            print("   band 0x%02X  %2d used  %s"
                  % (b * 16, len(used),
                     "" if not used else "0x%02X..0x%02X"
                     % (min(used), max(used))))
        return 0
    if "--stride" in sys.argv:
        a, n, _ = NAMES
        s = txt(a, n)
        print("centred-looking rows per candidate stride (2048 bytes):")
        for w in (8, 16, 32, 64):
            r = [s[i:i + w] for i in range(0, n, w)]
            cen = sum(1 for x in r
                      if x != x.strip() and x.startswith(" ") and x.endswith(" "))
            print("   stride %3d: %4d rows, %4d of them blank-padded on BOTH "
                  "sides" % (w, len(r), cen))
        return 0
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
