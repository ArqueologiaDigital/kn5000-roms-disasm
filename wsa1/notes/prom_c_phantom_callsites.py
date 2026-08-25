#!/usr/bin/env python3
"""Which "Called from" addresses in prom_c's routine headers are inside DATA?

QUESTION IT ANSWERS
  Every routine header in prom_c/wsa1_prom_c.s carries a "Called from:" list, produced by an
  image-wide byte scan for `1D <addr24>` (call) and `1E <disp16>` (calr).  That scan does not
  know which parts of the image are code, and prom_c is 24% data by area.  A hit inside a data
  region is a BYTE COINCIDENCE, and quoting it as a caller is the same class of error as
  citing a call site one byte past the instruction.

  This finds them.  It reads the headers, keeps the cited addresses that fall inside a region
  the source itself has established as data, and -- for the preset bank -- shows the record
  index and the offset WITHIN the record, which is what turns "suspicious" into "settled".

★ WHAT IT FOUND (2026-08-25, round 3): ELEVEN of the ~2,300 header call-site citations landed
  inside an established data region -- TEN inside the preset bank (0xF80000-0xF97FFF) and one
  inside the 77-entry f64 coefficient pool.  They are not calls.  Laid on the preset bank's own
  geometry -- 129 records of 704 bytes from file 0x000300, proved by
  notes/gen_prom_c_preset_bank.py -- all ten fall at just FOUR offsets inside a record
  (0x021, 0x02D, 0x041, 0x061), and five of them at offset 0x041 in records 121, 123, 124, 125
  and 126.  A call site does not repeat at a data structure's stride.
  (A twelfth preset-bank citation, 0xF92121 for Kernel_RotateQueue, was already flagged by hand
  in the source as NOT ESTABLISHED before this round.)

  All eleven headers now say NO LOCATED CALLER, so the live scan above is EMPTY and the
  selftest asserts that it stays empty -- plus the geometry of the recorded ten, and that each
  of them really does spell `calr <that routine>` in the data, which is why the scan fell for
  them in the first place.

  The routines affected each had exactly ONE "outside" caller and it was one of these, so
  after this the honest reading is that they have NO located caller:

      sub_F9A86B  sub_F9AB2A  sub_F9ACCE  sub_F9AD65  sub_F9B2EE
      sub_F9B305  sub_F9B32C  sub_F9B5A5  sub_F9B887  sub_F9BE3A

  sub_F9BE3A is the 8,573-byte double-precision routine that reads 64 slots of the floating-
  point constant pool, so this matters: "called once from 0xF95B01" was in two notes and is
  now "no located caller".

LIMITS
  * DATA regions are listed below by hand, from the source's own block banners.  A region not
    listed is treated as code, so this UNDERCOUNTS.
  * It says a citation is not a call.  It does not find the real caller.

RUN
  python3 notes/prom_c_phantom_callsites.py
  python3 notes/prom_c_phantom_callsites.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
BASE = 0xF80000

# established DATA regions, from the block banners at the top of prom_c/wsa1_prom_c.s
DATA = [(0xF80000, 0xF98000, "the preset bank"),
        (0xFCB27E, 0xFCC53F, "the f64 coefficient pool"),
        (0xFCC53F, 0xFCD0F7, "the touch / EQ / mixer zone"),
        (0xFCD0F7, 0xFDD2AB, "the byte-stream pool"),
        (0xFDD2AB, 0xFDF7E0, "the voice / DSP table zone"),
        (0xFDF7E0, 0xFE21E6, "the tail data zone")]
PRESET_REC, PRESET_STRIDE = 0x000300, 704
IMG = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()

# The ten preset-bank citations this tool found, RECORDED because the headers that carried
# them have been rewritten to say they are not call sites.  --selftest re-checks their
# in-record geometry, and that each one really does spell `calr <that routine>` in the data.
FOUND_PRESET = [("sub_F9AB2A", 0xF947E1), ("sub_F9AD65", 0xF94A61), ("sub_F9B2EE", 0xF94FE1),
                ("sub_F9B32C", 0xF94FED), ("sub_F9B305", 0xF95001), ("sub_F9B5A5", 0xF952A1),
                ("sub_F9B887", 0xF95581), ("sub_F9A86B", 0xF95841), ("sub_F9BE3A", 0xF95B01),
                ("sub_F9ACCE", 0xF95DC1)]


def headers():
    """(routine name, [cited call-site addresses]) for every header in the source."""
    txt = open(SRC).read()
    out = []
    for m in re.finditer(r"^; ([A-Za-z_][A-Za-z_0-9]*) -- 0x([0-9A-F]{6})", txt, re.M):
        name = m.group(1)
        seg = txt[m.end():m.end() + 4000]
        # ⚠ bound the search to THIS header: a data object's header has no "Called from:" at
        # all, and without the bound the search runs on into the next routine's and attributes
        # its call sites to the table.  The separator line ends every header.
        cut = seg.find("\n; ---")
        if cut > 0:
            seg = seg[:cut]
        cm = re.search(r"; Called from:(.*?)(?=\n; [A-Z]|\Z)", seg, re.S)
        if not cm:
            continue
        # ⚠ take addresses ONLY from lines that are a LIST of call sites -- i.e. whose text,
        # after "; " and an optional "Called from:", begins with an address.  Prose inside the
        # block (including the corrections this tool caused to be written) mentions addresses
        # too, and counting those would make the tool find its own findings a second time.
        addrs = []
        for ln in cm.group(0).splitlines():
            body = re.sub(r"^;\s*(Called from:)?\s*", "", ln)
            if body.startswith("0x"):
                addrs += [int(a, 16) for a in re.findall(r"0x(F[89A-C][0-9A-F]{4})", body)]
        out.append((name, addrs))
    return out


def main():
    hs = headers()
    total = sum(len(v) for _, v in hs)
    rows = []
    for name, sites in hs:
        for s in sites:
            for lo, hi, what in DATA:
                if lo <= s < hi:
                    rows.append((name, s, what))
    print("prom_c routine headers: %d, citing %d call sites" % (len(hs), total))
    print("citations that land inside an established DATA region: %d" % len(rows))
    for name, s, what in sorted(rows, key=lambda r: r[1]):
        extra = ""
        if what == "the preset bank":
            off = s - BASE - PRESET_REC
            extra = "   record %3d, offset 0x%03X inside it" % (off // PRESET_STRIDE,
                                                                off % PRESET_STRIDE)
        print("  %-24s cited 0x%06X  in %s%s" % (name, s, what, extra))
    if "--selftest" in sys.argv:
        ok = True
        # (1) the live scan must now be EMPTY: every one of the twelve has been rewritten.
        if rows:
            print("FAIL: %d header citation(s) still land in data: %s"
                  % (len(rows), [(n, "0x%06X" % s) for n, s, _ in rows])); ok = False
        # (2) the ten preset-bank ones, re-checked against the bank's geometry from the
        #     RECORDED list below -- recorded because the headers no longer carry them.
        offs = set((s - BASE - PRESET_REC) % PRESET_STRIDE for _, s in FOUND_PRESET)
        if offs != {0x021, 0x02D, 0x041, 0x061}:
            print("FAIL: offsets in record are %s" % sorted(hex(o) for o in offs)); ok = False
        recs = sorted((s - BASE - PRESET_REC) // PRESET_STRIDE for _, s in FOUND_PRESET
                      if (s - BASE - PRESET_REC) % PRESET_STRIDE == 0x041)
        if recs != [121, 123, 124, 125, 126]:
            print("FAIL: the offset-0x041 records are %s" % recs); ok = False
        # (3) and each one really does spell a call to the routine whose header cited it
        for name, s in FOUND_PRESET:
            tgt = int(name.split("_")[1], 16)
            b = IMG[s - BASE:s - BASE + 3]
            hit = (b[0] == 0x1E and s + 3 + int.from_bytes(b[1:3], "little") == tgt) or \
                  (b[0] == 0x1D)
            if not hit:
                print("FAIL: 0x%06X does not spell a call to %s" % (s, name)); ok = False
        print("selftest:", "OK" if ok else "FAILED")
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
