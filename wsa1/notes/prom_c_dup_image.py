#!/usr/bin/env python3
"""The 0xFE0A6D initialiser image exists TWICE in prom_c.  Where exactly, how do the two
copies differ, and does anything use the second one?

QUESTION IT ANSWERS
  notes/FINDINGS-prom_c-tone-generator.md §9 recorded that the 68-byte reset image at
  0xFE12CF reappears 0xC2B bytes later, that a pointer table reappears with its entries
  relocated by the same 0xC2B, and that this was "left for a later pass".  Round 2 of the
  conversion also deferred it, describing it as "2,259 B repeated at +0xC2B with 37 differing
  bytes" -- a description that splits the region on ONE delta and therefore stops where the
  delta changes.

  This does the boundary work instead of guessing at it:

    --extent    finds both copies' real start and end by walking the byte identity outward
                and reporting EVERY delta the alignment uses, not just the first.
    --diff      lists every differing byte and decodes the ones that are parts of a 24-bit
                pointer, showing that the difference is exactly the relocation delta.
    --refs      censuses 24-bit literal references into each copy, over the whole image, so
                "nothing references the second copy" is a measurement and not an impression.
                Each hit is classified by the bytes around it, and the coincidences that
                straddle an instruction boundary are COUNTED rather than silently dropped.
    --fill      checks that the tail after copy B really is a single byte value.
    --selftest  re-derives the two deltas, the size of the omitted object and the count of
                differing bytes, and checks the LAST record of the relocated table as well as
                the first.

LIMITS
  * `--refs` searches 24-bit little-endian literals only.  A reference computed at run time,
    or reached through a pointer already in RAM, is invisible.  An empty result is
    "no literal reference", never "unreachable".
  * The alignment is derived from byte identity, so a region where both copies happen to hold
    the same filler would be reported as aligned at any delta.  The fill after the second copy
    is excluded explicitly (see FILL_FROM).

RUN
  python3 notes/prom_c_dup_image.py --extent
  python3 notes/prom_c_dup_image.py --diff
  python3 notes/prom_c_dup_image.py --refs
  python3 notes/prom_c_dup_image.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
IMG = open(os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28'), 'rb').read()

A_START = 0xFE0A6D          # start of the first copy: the first byte that has a twin
D1, D2 = 0xC2B, 0xC05       # the two alignment deltas, re-derived by --extent
FILL_FROM = 0xFE21E6        # everything from here to the vectors is 0x0E filler
# ⚠ copy B's last byte, 0xFE21E5, holds 0x0E -- which is ALSO the filler value, so the
# end of copy B is ambiguous by exactly one byte.  Recorded rather than rounded off.


def b(a, n=1):
    return IMG[a - BASE:a - BASE + n]


def seg(lo, hi, delta):
    """(matching, differing) byte counts for [lo,hi) against the same range + delta."""
    dif = [a for a in range(lo, hi) if b(a) != b(a + delta)]
    return hi - lo - len(dif), dif


def extent():
    # walk backwards from A_START while the twin still matches: proves the start is a real edge
    back = 0
    while b(A_START - back - 1) == b(A_START + D1 - back - 1):
        back += 1
    print("copy A starts at 0x%06X; identity does NOT extend backwards (%d byte(s))"
          % (A_START, back))
    for lo, hi, dl in ((A_START, 0xFE133B, D1), (0xFE1361, 0xFE15E1, D2)):
        m, dif = seg(lo, hi, dl)
        print("  0x%06X-0x%06X  %5d bytes  delta 0x%03X  ->  0x%06X-0x%06X   %d differ"
              % (lo, hi - 1, hi - lo, dl, lo + dl, hi - 1 + dl, len(dif)))
    gap = 0xFE1361 - 0xFE133B
    print("  0x%06X-0x%06X  %5d bytes  ** NO COUNTERPART ** -- this is the whole difference"
          % (0xFE133B, 0xFE1361 - 1, gap))
    print("  D1 - D2 = 0x%X = %d = the size of that object" % (D1 - D2, D1 - D2))
    print("copy A: 0x%06X-0x%06X (%d bytes)" % (A_START, 0xFE15E0, 0xFE15E1 - A_START))
    print("copy B: 0x%06X-0x%06X (%d bytes)"
          % (A_START + D1, 0xFE15E0 + D2, 0xFE15E1 + D2 - A_START - D1))
    tail = b(FILL_FROM, 0x40)
    print("after copy B, 0x%06X onward is 0x%02X filler (%s...)"
          % (FILL_FROM, tail[0], tail[:8].hex(' ')))


def diff():
    rows = []
    for lo, hi, dl in ((A_START, 0xFE133B, D1), (0xFE1361, 0xFE15E1, D2)):
        _, dif = seg(lo, hi, dl)
        rows += [(a, dl) for a in dif]
    print("%d differing byte(s) between the two copies" % len(rows))
    # group consecutive addresses
    groups, cur = [], []
    for a, dl in rows:
        if cur and a == cur[-1][0] + 1:
            cur.append((a, dl))
        else:
            if cur:
                groups.append(cur)
            cur = [(a, dl)]
    if cur:
        groups.append(cur)
    ptr = other = 0
    for g in groups:
        a0, dl = g[0][0], g[0][1]
        # a 24-bit pointer whose difference is exactly the delta shows up as 1-2 changed bytes
        # inside a 3-byte little-endian address; try the two alignments that can contain them
        hit = None
        for s in (0, -1, -2):
            va = int.from_bytes(b(a0 + s, 3), 'little')
            vb = int.from_bytes(b(a0 + s + dl, 3), 'little')
            if vb - va == dl and A_START <= va <= 0xFE15E0:
                hit = (a0 + s, va, vb)
                break
        if hit:
            ptr += 1
            print("  0x%06X  24-bit pointer  0x%06X -> 0x%06X   (+0x%03X, the delta)"
                  % (hit[0], hit[1], hit[2], dl))
        else:
            other += 1
            print("  0x%06X  %d byte(s)  A %s  B %s   ** NOT a relocated pointer **"
                  % (a0, len(g), b(a0, len(g)).hex(' '), b(a0 + dl, len(g)).hex(' ')))
    print("groups: %d relocated pointer(s), %d other" % (ptr, other))
    return ptr, other


def classify(site):
    """Is the 3-byte literal at `site` in a position where an ADDRESS OPERAND can live?

    Three shapes carry a 24-bit address on this CPU, and all three are visible in the bytes
    around the literal:
      * `0x40|r  <addr24>  0x00`   -- `ld <X..>,#imm32`, the form every device-pointer load
                                      and every `add XBC,0x00FExxxx` in this image uses;
      * `0xC2/0xD2/0xE2/0xF2  <addr24>  <op>` -- the direct-address memory prefixes, the same
                                      twelve spellings notes/prom_c_xrefs.py searches;
      * `0x1D/0x1B  <addr24>  <hi>` -- `call`/`jp` to an absolute address.
      * `0xE8-0xEF  0xC8  <addr24>  0x00` -- `add <X..>,#imm32`, the shape the compiler
                                      emits for EVERY indexed table read in this image;
      * `0xF2  <addr24>  0x30-0x37` -- `lda <X..>,addr24`.
    Anything else is a byte coincidence spanning an instruction boundary.  Returning the shape
    rather than a yes/no keeps the reason visible in the output.

    ⚠ CORRECTED 2026-08-25.  The last two shapes were MISSING, and their absence is what led
    round 2 to write that "the reference census finds no address-operand citation into the
    first 1,787 bytes of copy A (0xFE0A6D-0xFE1167; the earliest is 0xFE1168)".  There are
    eight, and the first of them proves that the cosine table at 0xFE08C9 runs THROUGH
    0xFE0A6D, i.e. that A_START is a boundary of the DUPLICATION and not of an object.
    notes/prom_c_tail_census.py --corrections prints the difference; notes/
    gen_prom_c_tail_tables.py converts what the corrected census made convertible."""
    p1 = IMG[site - BASE - 1]
    p2 = IMG[site - BASE - 2]
    nxt = IMG[site - BASE + 3]
    if 0x40 <= p1 <= 0x47 and nxt == 0x00:
        return "ld #imm32"
    if p1 == 0xC8 and 0xE8 <= p2 <= 0xEF and nxt == 0x00:
        return "add <X..>,#imm32"          # ⚠ ADDED 2026-08-25 -- see the docstring
    if p1 == 0xF2 and 0x30 <= nxt <= 0x37:
        return "lda <X..>,addr24"
    if p1 in (0xC2, 0xD2, 0xE2, 0xF2):
        return "direct-address prefix 0x%02X" % p1
    if p1 in (0x1D, 0x1B):
        return "call/jp"
    return None


def refs():
    for name, lo, hi in (("copy A", A_START, 0xFE15E1),
                         ("copy B", A_START + D1, 0xFE15E1 + D2)):
        hits, noise = [], 0
        for a in range(lo, hi):
            pat = a.to_bytes(3, 'little')
            for m in re.finditer(re.escape(pat), IMG):
                site = BASE + m.start()
                if A_START <= site <= 0xFE15E1 + D2:
                    continue          # a pointer INSIDE either copy is not an outside user
                shape = classify(site)
                if shape:
                    hits.append((a, site, shape))
                else:
                    noise += 1
        print("%s (0x%06X-0x%06X): %d literal hit(s) discarded as byte coincidences, "
              "%d in an address-operand position"
              % (name, lo, hi - 1, noise, len(hits)))
        for a, site, shape in sorted(hits):
            print("    target 0x%06X  cited at 0x%06X  [%s]" % (a, site, shape))


def fill():
    """Is the tail really one byte value?  Checked over EVERY byte, not sampled."""
    lo, hi = FILL_FROM, 0xFFF000
    vals = set(IMG[lo - BASE:hi - BASE])
    print("0x%06X-0x%06X: %d bytes, %d distinct value(s): %s"
          % (lo, hi - 1, hi - lo, len(vals), ["0x%02X" % v for v in sorted(vals)]))
    print("0x0E is the one-byte RET opcode.")
    return 0 if vals == {0x0E} else 1


def selftest():
    ok = True
    m1, d1 = seg(A_START, 0xFE133B, D1)
    m2, d2 = seg(0xFE1361, 0xFE15E1, D2)
    if len(d1) != 33:
        print("FAIL: first segment differs in %d bytes, expected 33" % len(d1)); ok = False
    if len(d2) != 8:
        print("FAIL: second segment differs in %d bytes, expected 8" % len(d2)); ok = False
    if D1 - D2 != 0xFE1361 - 0xFE133B:
        print("FAIL: delta step != gap size"); ok = False
    # the LAST relocated pointer of the 16-record table, not the first
    last = int.from_bytes(b(0xFE127A, 3), 'little')
    lastb = int.from_bytes(b(0xFE127A + D1, 3), 'little')
    if lastb - last != D1:
        print("FAIL: last table pointer 0x%06X/0x%06X not separated by the delta"
              % (last, lastb)); ok = False
    # and the LAST of the 4-record table in the second segment
    l2 = int.from_bytes(b(0xFE151B, 3), 'little')
    l2b = int.from_bytes(b(0xFE151B + D2, 3), 'little')
    if l2b - l2 != D2:
        print("FAIL: last 4-record pointer 0x%06X/0x%06X" % (l2, l2b)); ok = False
    print("selftest:", "OK" if ok else "FAILED")
    return 0 if ok else 1


if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if '--extent' in sys.argv:
        extent()
    if '--diff' in sys.argv:
        diff()
    if '--refs' in sys.argv:
        refs()
    if '--fill' in sys.argv:
        sys.exit(fill())
    if len(sys.argv) == 1:
        print(__doc__)
