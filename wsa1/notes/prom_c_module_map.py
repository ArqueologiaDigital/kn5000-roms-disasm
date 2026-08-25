#!/usr/bin/env python3
"""What routines does a prom_c address range contain, where does each start and end,
and who transfers to it?

QUESTION ANSWERED
  Before a block can be documented it has to be cut into routines, and the cut has to
  come from the ROM rather than from eyeballing a listing.  For a range this reports,
  per candidate entry:

      entry address, extent (to the next entry), prologue?, and every LITERAL
      transfer site in the whole image, split into sites INSIDE the range and sites
      OUTSIDE it.

WHERE THE CANDIDATE ENTRIES COME FROM -- three independent sources, unioned
  1. every `call`/`jp` absolute-24 and `calr` rel-16 target anywhere in the image that
     lands in the range (the same three byte forms notes/prom_c_xrefs.py documents);
  2. every entry of every computed-goto table inside the range
     (notes/prom_c_jumptables.py);
  3. every address in the range whose bytes are a frame prologue `EE 0C dd dd`
     (`link XIZ,imm16`) AND that is immediately preceded by `0E` (`ret`) or by a
     table's last byte -- i.e. a routine boundary visible in the code itself.
  Source 3 is what finds routines nothing in the CONVERTED part of the image calls
  yet; sources 1 and 2 are what proves the others are entries and not just labels.

★ THE FALSE-ENTRY FILTER -- added 2026-08-25, and it matters
  Sources 1 and 2 are BYTE PATTERNS, and a byte pattern is not an instruction.  A `1D`
  or `1E` inside a longer instruction reads as a call: at 0xFAC2F7 the bytes are
  `10 02 00 00`, part of `ld (XIX+0x10),0x0000`, and a raw scan reports a routine
  there.  When the range is already converted in prom_c/wsa1_prom_c.s this script now
  DROPS every candidate that is not an instruction boundary in that file, and prints
  how many it dropped.  Over the ten blocks converted in round 3 that is **116 of 761
  candidates, 15%** -- an error large enough to have put a wrong routine count into
  ten block comments, which is exactly what it did before the filter existed.
  ⚠ In an UNCONVERTED range there are no boundaries to check against, so no filtering
  happens and the count is an upper bound.  The output says which case it is.

LIMITS -- read before quoting
  * A byte pattern is not a proven instruction.  `EE 0C` can occur inside data; the
    `ret`-before test removes most of that, the filter above removes the rest where
    the file can say, and the extent column makes a bad cut visible as an absurd
    length.
  * Register-indirect and short-`jr` transfers are invisible, so a zero in the site
    columns means "no literal transfer found", never "unreachable".
  * The extent is entry-to-next-entry, NOT a decoded routine length.  If a routine
    has no successor entry the extent runs to the end of the range.

RUN
  python3 notes/prom_c_module_map.py 0xFA7E2C 0xFABE30
  python3 notes/prom_c_module_map.py 0xFA7E2C 0xFABE30 --dups
  python3 notes/prom_c_module_map.py --selftest

--dups: equal-length routine pairs differing in <= 12.5% of their bytes, with every
differing byte tested against the `calr` that owns it.  "every differing byte is a
`calr` displacement to the SAME target" means the two routines are the same routine
duplicated, not merely similar -- a claim worth making only because it is checked.
A pair whose differences are NOT all displacements is printed as such, never rounded
up to "identical", and when there are eight or fewer the differing bytes are printed
with their offsets and both values -- which is how a "same routine, different struct
FIELD" family becomes visible instead of being asserted.
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTES = os.path.dirname(os.path.abspath(__file__))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
IMG = open(ROM, "rb").read()
TOP = BASE + len(IMG)


_BOUNDS = None


def source_boundaries():
    """Instruction addresses prom_c/wsa1_prom_c.s has DECODED -- its `; ADDR  text`
    comments.  Empty for a range the file still holds as `.incbin`."""
    global _BOUNDS
    if _BOUNDS is None:
        _BOUNDS = set()
        path = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
        for ln in open(path):
            m = re.search(r';\s*([0-9A-F]{6})\s\s', ln)
            if m:
                _BOUNDS.add(int(m.group(1), 16))
    return _BOUNDS



_XFER = None


def unconverted_spans():
    """(lo, hi) the source file still holds as `.incbin`."""
    out = []
    text = open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")).read()
    for m in re.finditer(r'^\s*\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
                         text, re.M):
        lo = BASE + int(m.group(1), 16)
        out.append((lo, lo + int(m.group(2), 16)))
    return out


def all_transfers():
    """{target: [site, ...]} for every literal call/jp abs24 and calr rel16 whose SITE
    the source file's own decode agrees is an instruction.

    ★ THE SITE FILTER, added 2026-08-25.  The raw scan is a BYTE-PATTERN scan: a `1D`
    or `1E` inside a longer instruction reads as a call.  147 of the 2,987 ROM
    addresses the first draft of round 3's generated headers cited as call sites --
    5% -- were exactly that.  A site is kept only if it is an address the source file
    has DECODED, or if it lies in a range the file still holds as `.incbin`, where
    there is nothing to check it against.  The second case is an upper bound and is
    what the "(caller not yet converted)" rows of a caller census are made of.
    """
    global _XFER
    if _XFER is not None:
        return _XFER
    raw = {}
    for i in range(len(IMG) - 3):
        op = IMG[i]
        if op in (0x1D, 0x1B):
            t = IMG[i + 1] | (IMG[i + 2] << 8) | (IMG[i + 3] << 16)
            if BASE <= t < TOP:
                raw.setdefault(t, []).append(BASE + i)
        elif op == 0x1E:
            d = struct.unpack_from("<h", IMG, i + 1)[0]
            t = BASE + i + 3 + d
            if BASE <= t < TOP:
                raw.setdefault(t, []).append(BASE + i)
    bounds = source_boundaries()
    unconv = unconverted_spans()

    def ok(a):
        if a in bounds:
            return True
        if any(lo <= a < hi for lo, hi in unconv):
            return True                      # nothing decoded here to check against
        # ⚠ NOT EVERY CONVERTED LINE CARRIES AN `; ADDR` COMMENT.  The round-1 blocks
        # around 0xF98000 comment their lines symbolically, and the data pools emit
        # `.long` with no instruction address at all.  Dropping a site merely because
        # the file has no address for it would HIDE real call sites, so a site is
        # dropped only where the file demonstrably decoded that neighbourhood: an
        # `; ADDR` comment within +/-64 bytes.  Otherwise there is no information and
        # the site is kept, as an upper bound.
        return not any((a + d) in bounds for d in range(-64, 65))
    _XFER = {}
    for t, sites in raw.items():
        keep = [s for s in sites if ok(s)]
        if keep:
            _XFER[t] = keep
    return _XFER


def table_entries(lo, hi):
    sys.path.insert(0, NOTES)
    import prom_c_jumptables as jt
    out, spans = set(), []
    for _, tbl, guard, n, _ in jt.tables():
        if lo <= tbl < hi:
            spans.append((tbl, tbl + 4 * n))
            for k in range(n):
                out.add(struct.unpack_from("<I", IMG, tbl - BASE + 4 * k)[0])
    return out, spans


def entries(lo, hi, report=False):
    xfer = all_transfers()
    cand = {t for t in xfer if lo <= t < hi}
    tents, spans = table_entries(lo, hi)
    cand |= {t for t in tents if lo <= t < hi}
    in_table = lambda a: any(s <= a < e for s, e in spans)
    for a in range(lo, hi - 4):
        if in_table(a):
            continue
        if IMG[a - BASE] == 0xEE and IMG[a - BASE + 1] == 0x0C:
            prev = IMG[a - BASE - 1]
            if prev == 0x0E or any(e == a for _, e in spans):
                cand.add(a)
    # ★ drop candidates the source file's own decode says are not instruction starts
    bounds = source_boundaries()
    covered = sum(1 for a in range(lo, hi, 64) if a in bounds) > 0
    dropped = 0
    if covered:
        keep = {a for a in cand if a in bounds and not in_table(a)}
        dropped = len(cand) - len(keep)
        cand = keep
    if report:
        sys.stderr.write("entry filter: %s; %d candidate(s) dropped as not instruction "
                         "boundaries\n"
                         % ("range is decoded in the source" if covered
                            else "range is still .incbin -- NO filtering, count is an "
                                 "upper bound", dropped))
    return sorted(cand), xfer, spans


def selftest():
    fails = []
    ents, xfer, spans = entries(0xFA7E2C, 0xFABE30)
    if 0xFA7E2C not in ents:
        fails.append("the module's first byte 0xFA7E2C is not an entry")
    # LAST-ELEMENT control: the highest entry must be below the range end and its
    # extent must not run off the end
    if ents[-1] >= 0xFABE30:
        fails.append("last entry 0x%06X is outside the range" % ents[-1])
    # a known transfer: 0xFA7F28 has 12 sites per prom_c_frontier_src.py
    if len(xfer.get(0xFA7F28, [])) < 12:
        fails.append("0xFA7F28 has %d literal sites, expected >= 12"
                     % len(xfer.get(0xFA7F28, [])))
    # negative control: an address in the middle of a jump table is not an entry
    if 0xFA9034 in ents:
        fails.append("0xFA9034, inside a computed-goto table, was called an entry")
    # negative control: a routine that lives OUTSIDE the range is not reported
    if 0xFB3F36 in ents:
        fails.append("0xFB3F36 (MidiNote_Dispatch, outside the range) was reported")
    # ★ the false-entry control: 0xFAC2F7 is `1D`-pattern noise inside
    # `ld (XIX+0x10),0x0000` and MUST NOT be reported once that range is decoded
    e2, _, _ = entries(0xFABE30, 0xFACE67)
    if 0xFAC2F7 in e2:
        fails.append("0xFAC2F7 -- byte-pattern noise inside `ld (XIX+0x10),0x0000` -- "
                     "is still reported as an entry")
    if 0xFAC826 in e2:
        fails.append("0xFAC826 -- byte-pattern noise -- is still reported as an entry")
    # ★ and a candidate INSIDE a computed-goto table is table data, never a routine:
    # 0xFBF236 (bytes 00 5F EB FB) sits inside the table at 0xFBF1C3-0xFBF27A
    e3, _, _ = entries(0xFB828E, 0xFC3407)
    if 0xFBF236 in e3:
        fails.append("0xFBF236, inside the 0xFBF1C3 table, is still reported as an entry")
    for f in fails:
        print("  FAIL " + f)
    print("SELFTEST %s (%d entries found in 0xFA7E2C-0xFABE30)"
          % ("FAIL" if fails else "PASS", len(ents)))
    return 1 if fails else 0


def calr_target(a):
    """If a `1E dd dd` calr starts at `a`, its absolute target; else None."""
    if IMG[a - BASE] != 0x1E:
        return None
    return a + 3 + struct.unpack_from("<h", IMG, a - BASE + 1)[0]


def dups(lo, hi):
    ents, xfer, spans = entries(lo, hi)
    routines = sorted(a for a in ents
                      if xfer.get(a) or IMG[a - BASE:a - BASE + 2] == b"\xee\x0c")
    ext = {a: (routines[k + 1] if k + 1 < len(routines) else hi) - a
           for k, a in enumerate(routines)}
    out = []
    for i in range(len(routines)):
        for j in range(i + 1, len(routines)):
            a, b = routines[i], routines[j]
            n = ext[a]
            if n != ext[b] or n < 24:
                continue
            d = [k for k in range(n) if IMG[a - BASE + k] != IMG[b - BASE + k]]
            if len(d) * 8 > n:
                continue
            all_calr = bool(d)
            detail = [(k, IMG[a - BASE + k], IMG[b - BASE + k]) for k in d]
            for k in d:
                hit = False
                for back in (1, 2):
                    if k - back >= 0 and IMG[a - BASE + k - back] == 0x1E:
                        ta, tb = calr_target(a + k - back), calr_target(b + k - back)
                        if ta is not None and ta == tb:
                            hit = True
                if not hit:
                    all_calr = False
            out.append((a, b, n, len(d), all_calr, detail))
    return out


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--dups" in sys.argv:
        args = [a for a in sys.argv[1:] if not a.startswith("--")]
        lo, hi = int(args[0], 0), int(args[1], 0)
        rows = dups(lo, hi)
        for a, b, n, d, ok, detail in sorted(rows, key=lambda r: r[3]):
            if d == 0:
                why = "-- BYTE-IDENTICAL over the whole length"
            elif ok:
                why = "-- every one a `calr` displacement to the SAME target"
            else:
                why = "-- NOT all displacements; read them"
            print("  0x%06X / 0x%06X  %4d bytes, %3d differ  %s" % (a, b, n, d, why))
            if 0 < d <= 8 and not ok:
                print("           " + "  ".join("+0x%02X: %02X vs %02X" % t for t in detail))
        print("\n  %d pair(s) in 0x%06X-0x%06X" % (len(rows), lo, hi - 1))
        return 0
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo, hi = int(args[0], 0), int(args[1], 0)
    ents, xfer, spans = entries(lo, hi, report=True)
    tot_in = tot_out = 0
    print("  %-9s %6s %-4s %5s %5s  %s" %
          ("entry", "extent", "pro", "in", "out", "outside sites"))
    for k, a in enumerate(ents):
        nxt = ents[k + 1] if k + 1 < len(ents) else hi
        sites = xfer.get(a, [])
        ins = [s for s in sites if lo <= s < hi]
        outs = [s for s in sites if not (lo <= s < hi)]
        tot_in += len(ins)
        tot_out += len(outs)
        pro = "link" if IMG[a - BASE:a - BASE + 2] == b"\xee\x0c" else "-"
        print("  0x%06X %6d %-4s %5d %5d  %s" %
              (a, nxt - a, pro, len(ins), len(outs),
               " ".join("0x%06X" % s for s in outs[:6]) + (" ..." if len(outs) > 6 else "")))
    print("\n  %d entries, %d table span(s), %d in-range site(s), %d outside site(s)"
          % (len(ents), len(spans), tot_in, tot_out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
