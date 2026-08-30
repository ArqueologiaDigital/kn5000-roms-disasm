#!/usr/bin/env python3
"""Which of Fdc_Request's twelve operations does this firmware ever ASK FOR?

QUESTION IT ANSWERS
  Emulation gap T asks what CPU 1's PA bit 3 drives.  Inside the FDC module,
  PA bit 3 is written only by `Fdc_Op6_PortA3_Off` (0xFE65EF) and
  `Fdc_Op7_PortA3_On` (0xFE661F), and both are reachable ONLY as arms 6 and 7
  of `Fdc_OperationJumpTable`, i.e. only by a caller that puts 6 or 7 in a
  request block's operation word.  So "does any caller ask for operation 6 or
  7?" is a real question and this script answers it: NO.

  ⚠⚠ WHAT THAT ANSWER DOES **NOT** MEAN, retracted 2026-08-25.  This docstring
  used to continue "PA bit 3 has exactly two writers in either image", and the
  notes turned that into "nothing in this firmware ever changes it".  BOTH ARE
  FALSE.  There are two more writers one layer up, 0xFE18EF `res 3,(0x1E)` and
  0xFE18F7 `set 3,(0x1E)`, reached by 15 `calr` sites, and they run.  The check
  below scanned for `f0 1e 41` = `ld (PA),A`; a bit write is `f0 1e b3` /
  `f0 1e bb`, which is a different encoding, so the scan was sound for "the only
  `ld (PA),A`" and worthless for "the only writers".  The whole-port census is
  `python3 notes/prom_a_pa3_census.py`; the consequences are in
  notes/FINDINGS-prom_a-gap-T-pa3.md.

  This script answers it by enumerating every located call site of the request
  layer and reading the operation word out of the instruction stream at each.

WHY THE ENUMERATION IS COMPLETE, and where it is not
  `Fdc_Request` (0xFE66C7) is reachable three ways and this script checks all
  three:
    1. an absolute `call`/`jp` to 0xFE66C7 -- 8 sites, 2 of which are the
       register-preserving VENEERS 0xFE3032 and 0xFE308D themselves;
    2. through veneer 0xFE3004 (published as prom_b thunk T_F42D24);
    3. through veneer 0xFE3018 (published as prom_b thunk T_F42D38).
  The reference scan is opcode-anchored at every byte offset, so it can
  over-report but cannot MISS an absolute call -- absence is exact.
  ⚠ It CANNOT see a computed or indirect call, and it cannot see a caller that
  keeps the operation word in a variable.  Both are reported as such rather
  than assumed away.

WHAT AN "OPERATION WORD" IS HERE
  Fdc_Request takes a pointer to a 16-byte request block whose +0x00 word is
  the operation.  Every located caller writes that word as an IMMEDIATE, in one
  of two shapes:
    `m_ld_mi16 MDI+rN, 0, 0xNNNN`   store imm16 through a register, offset 0
    `stiw_da (0xAAAA), 0xNNNN`      store imm16 to an absolute address
  For the second shape the block base is taken to be the LOWEST absolute
  address any `stiw_da`/`stl_da` in the same window writes, which is what +0x00
  means; the script prints the base it chose so the choice can be checked.

  ⚠ AND THE INDIRECT SHAPE NEEDS A POINTER CHECK, which is why this script has
  one.  `m_ld_mi16 MDI+r0, 0, ...` writes offset 0 OF WHATEVER THE REGISTER
  HOLDS, and at 0xFE3861 the register has already had `add XWA,0x0000000A` done
  to it -- so that instruction writes the SECTOR COUNT, not the operation.  A
  first version of this script read it as operation 0xFFFF and said so loudly.
  The window is therefore walked FORWARD with a per-register clean/dirty flag:
  a register is clean when freshly loaded and dirty after any add/sub/inc/dec,
  and only a clean register's offset-0 store can be the operation word.

RUN
  python3 notes/prom_a_fdc_operation_census.py          # the table
  python3 notes/prom_a_fdc_operation_census.py --quiet  # assertions only
Exit status is non-zero if any assertion fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()

FDC_REQUEST = 0xFE66C7
VENEERS = {0xFE3004: 0xF42D24, 0xFE3018: 0xF42D38}
VENEER_BODIES = (0xFE3020, 0xFE30D8)       # the veneer module's own call sites
WINDOW = 140                               # instructions to walk back

LINE = re.compile(r"^\s*(\S.*?)\s+;\s([0-9A-F]{6})\s\s([0-9a-f ]+?)\s*$")
IND0 = re.compile(r"m_ld_mi16\s+MDI\+r(\d+),\s*0,\s*(0x[0-9a-f]+)")
REGS = ["XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP"]
LOADS = re.compile(r"\b(?:ld|lda|lda_24|ldl_da|ld_sd8b)\s+(x?[a-zA-Z]{2,3})\s*,")
ARITH = re.compile(r"\b(?:add|sub|inc|dec)\s+(?:\d+,)?(x?[a-zA-Z]{2,3})\b")
ABSW = re.compile(r"stiw_da\s+\((0x[0-9a-f]+)\),\s*(0x[0-9a-f]+)")
ABSANY = re.compile(r"st[iwl]+_da\s+\((0x[0-9a-f]+)\)")


def listing():
    """[(addr, text, nbytes)] for every line of prom_a that carries bytes."""
    out = []
    for line in open(SRC, encoding="utf-8"):
        m = LINE.match(line.rstrip("\n"))
        if not m:
            continue
        out.append((int(m.group(2), 16), m.group(1), len(m.group(3).split())))
    out.sort()
    return out


def opcode_refs(target):
    """Every `call nnn` (0x1D) or `jp nnn` (0x1B) whose operand is `target`."""
    pat = bytes([target & 0xFF, (target >> 8) & 0xFF, (target >> 16) & 0xFF])
    hits = []
    for img, base in ((A, 0xF80000), (B, 0xF00000)):
        for i in range(len(img) - 3):
            if img[i + 1:i + 4] == pat and img[i] in (0x1B, 0x1D):
                hits.append(base + i)
    return sorted(hits)


def operation_at(lines, idx):
    """Walk back from lines[idx] and return (value, how, base) or None."""
    lo = max(0, idx - WINDOW)
    win = lines[lo:idx]
    # block base for the absolute shape: the lowest absolute address written
    absaddrs = [int(m.group(1), 16) for _, t, _ in win
                for m in [ABSANY.search(t)] if m]
    base = min(absaddrs) if absaddrs else None
    best = None
    dirty = set()
    for at, text, _ in win:
        m = IND0.search(text)
        if m:
            reg = REGS[int(m.group(1))]
            if reg not in dirty:
                best = (int(m.group(2), 16), "indirect +0 @%06X" % at, None)
            _track(text, dirty)
            continue
        _track(text, dirty)
        m = ABSW.search(text)
        if m and base is not None and int(m.group(1), 16) == base:
            best = (int(m.group(2), 16), "absolute @%06X" % at, base)
    return best


def _track(text, dirty):
    """Update the dirty-register set from one instruction's text."""
    for m in ARITH.finditer(text):
        r = m.group(1).upper()
        if r in REGS:
            dirty.add(r)
    for m in LOADS.finditer(text):
        r = m.group(1).upper()
        if r in REGS:
            dirty.discard(r)


def main():
    quiet = "--quiet" in sys.argv
    lines = listing()
    index = {a: i for i, (a, _, _) in enumerate(lines)}

    direct = opcode_refs(FDC_REQUEST)
    sites, notes = [], []
    for a in direct:
        if VENEER_BODIES[0] <= a <= VENEER_BODIES[1]:
            notes.append("%06X  veneer body -- operation comes from its caller" % a)
        else:
            sites.append((a, "direct"))

    veneer_hits = {}
    for body, thunk in VENEERS.items():
        hits = [h for h in opcode_refs(thunk) if not (0xF40000 <= h < 0xF44018)]
        hits += [h for h in opcode_refs(body) if not (0xF40000 <= h < 0xF44018)]
        veneer_hits[body] = sorted(set(hits))
        for h in veneer_hits[body]:
            sites.append((h, "via 0x%06X" % body))
    sites.sort()

    rows, missing = [], []
    for at, how in sites:
        if at not in index:
            missing.append(at)
            continue
        r = operation_at(lines, index[at])
        if r is None:
            missing.append(at)
            continue
        rows.append((at, how, r[0], r[1], r[2]))

    if not quiet:
        print("Fdc_Request (0x%06X) call sites that carry an operation word\n"
              % FDC_REQUEST)
        print("  site      reach            op  meaning                      "
              "written by")
        for at, how, op, where, base in rows:
            print("  %06X  %-15s  %2d  %-28s %s%s"
                  % (at, how, op, MEANING.get(op, "?"), where,
                     "" if base is None else "  base %06X" % base))
        for n in notes:
            print("  " + n)
        for body, hits in sorted(veneer_hits.items()):
            print("\n  veneer 0x%06X (thunk 0x%06X): %d call site(s)%s"
                  % (body, VENEERS[body], len(hits),
                     "" if hits else "  <- NO CALLER ANYWHERE IN EITHER IMAGE"))

    seen = sorted({op for _, _, op, _, _ in rows})
    if not quiet:
        print("\n  operations requested: %s" % seen)
        print("  histogram: %s" % {op: [r[2] for r in rows].count(op)
                                   for op in seen})

    fail = 0

    def check(ok, msg):
        nonlocal fail
        print(("  ok   " if ok else "  FAIL ") + msg)
        if not ok:
            fail = 1

    print("\nchecks")
    check(not missing, "every located call site yielded an operation immediate "
                       "(%d unresolved)" % len(missing))
    check(len(rows) == 23, "23 call sites carry an operation word (got %d)"
                           % len(rows))
    check(6 not in seen, "operation 6 (Fdc_Op6_PortA3_Off) is NEVER requested")
    check(7 not in seen, "operation 7 (Fdc_Op7_PortA3_On) is NEVER requested")
    check(seen == [0, 3, 4, 5, 10, 11],
          "the operations requested are exactly {0,3,4,5,10,11} (got %s)" % seen)
    check(veneer_hits[0xFE3004] == [],
          "veneer 0xFE3004 / thunk 0xF42D24 has no caller in either image")
    # LAST-ELEMENT TEST: the final site in address order must be the 1.44 MB
    # format routine's last verify read, operation 3 READ SECTORS at 0xFE75BC.
    # `LD (PA),A` sites, image-wide, from the ROM rather than from the source:
    # `f0 1e 41` is `LD (0x1E),A`, and 0x1E is PA (tmp95c061.cpp:1363).
    # ⚠ This scan supports EXACTLY ONE claim -- "these are the only `ld (PA),A`"
    # -- and NOT the larger claim "these are the only writers of PA bit 3",
    # which it was once used for and which is false.  See the docstring.
    # notes/prom_a_pa3_census.py is the scan that covers all four memory-operand
    # groups and therefore does support a whole-port claim.
    pa = []
    for img, base in ((A, 0xF80000), (B, 0xF00000)):
        pa += [base + i for i in range(len(img) - 2)
               if img[i:i + 3] == b"\xf0\x1e\x41"]
    if not quiet:
        print("\n  `ld (PA),A` (f0 1e 41) sites, both images: %s"
              % ["%06X" % a for a in pa])
    check(pa == [0xFE660D, 0xFE6631],
          "the only two `ld (PA),A` in either image are inside "
          "Fdc_Op6_PortA3_Off and Fdc_Op7_PortA3_On -- NOT the only "
          "writers of PA bit 3 (got %s)" % ["%06X" % a for a in pa])
    # And the cross-check that the old claim would have failed: the bit-write
    # spellings `f0 1e b3` (res 3) and `f0 1e bb` (set 3) DO occur.
    bitw = []
    for img, base in ((A, 0xF80000), (B, 0xF00000)):
        bitw += [base + i for i in range(len(img) - 2)
                 if img[i:i + 3] in (b"\xf0\x1e\xb3", b"\xf0\x1e\xbb")]
    check(bitw == [0xFE18EF, 0xFE18F7],
          "two MORE writers of PA bit 3 exist, at 0xFE18EF and 0xFE18F7 (got %s)"
          % ["%06X" % a for a in bitw])
    check(bool(rows) and rows[-1][0] == 0xFE75BC and rows[-1][2] == 3,
          "last site is 0xFE75BC and its operation is 3 (got %06X op %s)"
          % (rows[-1][0], rows[-1][2]) if rows else "no rows")
    sys.exit(fail)


MEANING = {0: "reset + identify media", 1: "recalibrate", 2: "seek",
           3: "READ SECTORS", 4: "WRITE SECTORS", 5: "FORMAT DISK",
           6: "clear PA bit 3", 7: "set PA bit 3", 8: "get saved error",
           9: "set flag 605A59", 10: "test controller present",
           11: "sense drive status"}

if __name__ == "__main__":
    main()
