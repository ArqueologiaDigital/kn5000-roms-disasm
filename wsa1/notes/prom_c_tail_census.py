#!/usr/bin/env python3
"""Which addresses in prom_c's TAIL DATA ZONE (0xFDF7E0-0xFE21E5) does the code cite?

QUESTION IT ANSWERS
  The tail zone is data with no instructions in it, so `notes/prom_c_frontier.py` cannot
  rank it and a linear disassembly of it is noise.  The only thing that fixes an object
  boundary there is prom_c's OWN CODE citing the object's first byte.  This censuses
  every such citation over the whole image, classified by the instruction shape that
  carries it, so a table's START is a measurement.

★ WHY IT EXISTS AS A SECOND TOOL, AND WHAT IT CORRECTS.
  `notes/prom_c_dup_image.py --refs` did this for the two copies of the initialiser
  image, and its classifier recognised three shapes: `ld <X..>,#imm32` (prefix 0x40-0x47),
  the direct-address memory prefixes 0xC2/0xD2/0xE2/0xF2, and `call`/`jp`.  It did NOT
  recognise

        e9 c8 <addr24> 00      add XBC,0x00FE06C9
        e8 c8 / ec c8 / ed c8  the same for XWA / XIX / XIY

  which is the shape the compiler emits for EVERY indexed table read in this image
  (`ld BC,2 / muls XBC,HL / add XBC,<table> / ld HL,(XBC)`).  Round 2 therefore wrote, in
  `prom_c/wsa1_prom_c.s`, that "the reference census finds no address-operand citation
  into the first 1,787 bytes of copy A (0xFE0A6D-0xFE1167; the earliest is 0xFE1168)".
  That is wrong: with the `add` shape included there are EIGHT citations below 0xFE1168,
  and the first of them -- 0xFE0AC9 -- proves that the 256-entry cosine table starting at
  0xFE08C9 runs THROUGH 0xFE0A6D, i.e. that copy A's start is not an object boundary at
  all.  `--corrections` prints exactly that difference, both censuses side by side.

THE FOUR SHAPES, and why each is an address operand and not a coincidence
    0x40-0x47  <addr24> 0x00   `ld <X..>,#imm32`   -- a 32-bit immediate whose top byte is 0
    0xE8-0xEF  0xC8 <addr24> 0x00                  -- `add <X..>,#imm32`, the indexed read
    0xF2       <addr24> 0x30-0x37                  -- `lda <X..>,addr24`
    0xC2/0xD2/0xE2/0xF2 <addr24> <op>              -- a direct-address memory operand
    0x1D / 0x1B <addr24> <hi>                      -- call / jp
  Everything else that merely contains the three bytes is counted as a COINCIDENCE and
  reported as a number, never silently dropped.

LIMITS -- read before quoting
  * literals only.  An address computed at run time, or one already in RAM, is invisible.
    An empty result is "no literal citation", never "unreachable".
  * a shape match is a byte pattern, not a proven instruction.  Sites inside converted
    code can be checked against `prom_c/wsa1_prom_c.s`; `--sites` prints them for that.

RUN
  python3 notes/prom_c_tail_census.py                 # the census, one line per target
  python3 notes/prom_c_tail_census.py --sites         # every citing site, with its shape
  python3 notes/prom_c_tail_census.py --copyb         # the "nothing reaches copy B" claim
  python3 notes/prom_c_tail_census.py --corrections   # old classifier vs this one
  python3 notes/prom_c_tail_census.py --selftest      # exit != 0 if a stated number moved
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
IMG = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()

ZONE_LO, ZONE_HI = 0xFDF7E0, 0xFE21E6      # the tail data zone, exclusive end
COPYB_LO, COPYB_HI = 0xFE1698, 0xFE21E6    # the second copy of the initialiser image


def shape(site, old=False):
    """The instruction shape that carries a 24-bit literal at `site`, or None."""
    o = site - BASE
    if o < 2 or o + 4 > len(IMG):
        return None
    p1, p2, nxt = IMG[o - 1], IMG[o - 2], IMG[o + 3]
    if 0x40 <= p1 <= 0x47 and nxt == 0x00:
        return "ld <X..>,#imm32"
    if not old and p1 == 0xC8 and 0xE8 <= p2 <= 0xEF and nxt == 0x00:
        return "add <X..>,#imm32"
    if not old and p1 == 0xF2 and 0x30 <= nxt <= 0x37:
        return "lda <X..>,addr24"
    if p1 in (0xC2, 0xD2, 0xE2, 0xF2):
        return "direct-address prefix 0x%02X" % p1
    if p1 in (0x1D, 0x1B):
        return "call/jp"
    return None


def census(lo, hi, old=False, exclude_inside=True):
    hits, noise = {}, 0
    for a in range(lo, hi):
        pat = a.to_bytes(3, "little")
        for m in re.finditer(re.escape(pat), IMG):
            site = BASE + m.start()
            if exclude_inside and ZONE_LO <= site < ZONE_HI:
                continue          # a pointer inside the zone is not an outside citation
            s = shape(site, old)
            if s:
                hits.setdefault(a, []).append((site, s))
            else:
                noise += 1
    return hits, noise


def main():
    argv = sys.argv[1:]
    if "--copyb" in argv:
        hits, noise = census(COPYB_LO, COPYB_HI)
        print("copy B, 0x%06X-0x%06X (%d bytes)" % (COPYB_LO, COPYB_HI - 1, COPYB_HI - COPYB_LO))
        print("  %d literal hit(s) in an address-operand position, %d coincidence(s) discarded"
              % (sum(len(v) for v in hits.values()), noise))
        for a in sorted(hits):
            for s, k in hits[a]:
                print("    target 0x%06X  cited at 0x%06X  [%s]" % (a, s, k))
        print("  ⚠ literals only -- see LIMITS.")
        return 0

    if "--corrections" in argv:
        new, _ = census(ZONE_LO, ZONE_HI)
        old, _ = census(ZONE_LO, ZONE_HI, old=True)
        missed = sorted(set(new) - set(old))
        print("targets found by this tool: %d;  by prom_c_dup_image.py's classifier: %d"
              % (len(new), len(old)))
        print("targets the OLD classifier misses, and the shape that carries them:")
        for a in missed:
            print("  0x%06X  %s" % (a, "; ".join("0x%06X [%s]" % t for t in new[a])))
        below = [a for a in missed if 0xFE0A6D <= a < 0xFE1168]
        print("\nof those, %d are inside 0xFE0A6D-0xFE1167 -- the range round 2 said held "
              "NO citation, 0xFE1168 being \"the earliest\":" % len(below))
        for a in below:
            print("  0x%06X" % a)
        return 0

    hits, noise = census(ZONE_LO, ZONE_HI)
    nsite = sum(len(v) for v in hits.values())
    print("prom_c tail data zone 0x%06X-0x%06X: %d cited target(s), %d citing site(s), "
          "%d coincidence(s) discarded" % (ZONE_LO, ZONE_HI - 1, len(hits), nsite, noise))
    if "--sites" in argv:
        for a in sorted(hits):
            print("  0x%06X  %s" % (a, "; ".join("0x%06X [%s]" % t for t in hits[a])))
    else:
        for a in sorted(hits):
            print("  0x%06X  %d site(s)" % (a, len(hits[a])))

    if "--selftest" in argv:
        ok = True
        exp_targets, exp_sites = 70, 133
        if len(hits) != exp_targets or nsite != exp_sites:
            print("FAIL: expected %d targets / %d sites, got %d / %d"
                  % (exp_targets, exp_sites, len(hits), nsite)); ok = False
        bhits, _ = census(COPYB_LO, COPYB_HI)
        if bhits:
            print("FAIL: copy B is cited after all: %s" % sorted(bhits)); ok = False
        old, _ = census(ZONE_LO, ZONE_HI, old=True)
        missed_below = [a for a in set(hits) - set(old) if 0xFE0A6D <= a < 0xFE1168]
        if len(missed_below) != 8:
            print("FAIL: expected 8 targets in 0xFE0A6D-0xFE1167 that the old classifier "
                  "misses, got %d" % len(missed_below)); ok = False
        if 0xFE0AC9 not in hits:
            print("FAIL: 0xFE0AC9 is not cited -- the cosine table's end is unproved"); ok = False
        print("selftest:", "OK" if ok else "FAILED")
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
