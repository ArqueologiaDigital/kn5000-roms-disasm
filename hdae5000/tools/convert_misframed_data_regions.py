#!/usr/bin/env python3
r"""convert_misframed_data_regions.py -- retype HD-AE5000's data-as-code islands.

QUESTION ANSWERED: `hdae5000/tools/data_as_code_census.py` classifies every
labelled region by WHO READS IT. Twelve regions are never the target of any
call or jump anywhere in the tree, AND the source itself already writes 70-100%
of their bytes as data directives. The leftover instruction lines interleaved
through them are the third kind of debt -- data disassembled into plausible
mnemonics -- and no instrument in this tree except that census can see them,
because re-assembling a wrong interpretation reproduces the same bytes.

  HDAE5000_Display_Params 0x2F8DCE   HDAE5000_Panel_Save_UI  0x29F9B2
  HDAE5000_Multilingual_Messages     HDAE5000_UI_Page_Titles 0x29DF8A
  HDAE5000_Credits        0x2A477C   HDAE5000_Dir_Strings    0x2E2500
  HDAE5000_Demo_Data      0x2A5634   HDAE5000_Char_Tables    0x2E2E76
  HDAE5000_Config_Strings 0x2E1C82   HDAE5000_UI_Descriptors 0x29DC14
  HDAE5000_Test_Strings   0x2E21D8   HDAE5000_Path_Strings   0x2E348F

Every one of those names says "data". `HDAE5000_Char_Tables` is the clearest
case and the one that exposed the census's own blind spot: 1,561 B, documented
in `hd-ae5000_v2_06i.s:121` as "Character set tables", holding 4-byte-stride
records and the ASCII "FLS NAME ", with 70% of its bytes already `.byte` and
the other 30% spelled as `setm 0, (xwa-72)` / `cps de, 2` / `andda8_24 c,
(49858)` -- an ascending byte ramp read as instructions.

⚠ THE EVIDENCE IS "NOTHING BRANCHES IN", NOT A DECODER'S OPINION. That is the
argument that settled HDAE5000_RECORD_TABLE and it cannot be confounded. The
interleave fraction is the corroborating second signal, and its false-positive
rate against this image's own proven-called regions is 1/314 = 0.32%.

⚠ RECALL LIMIT: `call (xhl)` resolves to nothing statically, so "never called"
is over-inclusive on its own. That is why a second signal is required, and why
the twelve are exactly the regions whose own source is already mostly data.

HOW THE BYTES ARE PRESERVED. Each instruction line's byte extent comes from the
verified probe address map (`llvm-nm` on a build asserted byte-identical to the
dump), and the replacement `.byte` line emits exactly those bytes read back
from the built image. Byte-exactness is by construction, and the gate confirms
it. Any trailing `;` comment on the line is carried over unchanged.

RUN (from the lane worktree root):
    python3 hdae5000/tools/convert_misframed_data_regions.py           # dry run
    python3 hdae5000/tools/convert_misframed_data_regions.py --apply
    rm -f rebuilt_ROMs/hd-ae5000_v2_06i.llvm.*
    make rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom
    cmp rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom original_ROMs/hd-ae5000_v2_06i.ic4

⚠ latin-1 I/O throughout (BRIEF addendum 2026-09-02).
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
import tier2_byte_split_census as C          # noqa: E402

_spec = importlib.util.spec_from_file_location(
    "dc", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "data_as_code_census.py"))
DC = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(DC)

BASE = 0x280000
MIN_REGION = 64          # bytes
MIN_INTERLEAVE = 0.30    # of the region's bytes already written as data


def main():
    apply_ = "--apply" in sys.argv
    amap = C.build_addrmap("hdae5000")
    tgts = C.entry_targets("HDAE5000")
    raw = C.rom_bytes("hdae5000")
    regions = [r for r in DC.code_regions(amap) if r[4] >= MIN_REGION]
    picked = []
    for r in regions:
        _rel, _l0, _nm, st, sz, ib = r
        if any(a in tgts for a in range(st, st + sz)):
            continue
        if 1.0 - ib / float(sz) < MIN_INTERLEAVE:
            continue
        picked.append(r)
    if not picked:
        print("no misframed data regions left")
        return 0

    by_file = {}
    total = 0
    for r in sorted(picked, key=lambda r: -r[4]):
        rel, l0, nm, st, sz, ib = r
        print("  %-32s 0x%06X %6d B  %3.0f%% already data, %d B framed as code"
              % (nm[:32], st, sz, 100 * (1 - ib / float(sz)), ib))
        by_file.setdefault(rel, []).append(r)
        total += ib
    print("instruction-framed bytes inside never-called data regions: %d B" % total)

    edits = {}
    for rel, rs in by_file.items():
        path = os.path.join(ROOT, "hdae5000", rel)
        lines = open(path, encoding="latin-1").read().split("\n")
        ad = amap[rel]
        n = len(ad) - 1
        marks = sorted((r[1], r[3], r[3] + r[4]) for r in rs)
        for l0, st, en in marks:
            i = l0
            while i <= n and ad[i] is not None and ad[i] < en:
                if ad[i + 1] is None:
                    i += 1
                    continue
                sz = ad[i + 1] - ad[i]
                txt = lines[i - 1] if i - 1 < len(lines) else ""
                if sz == 0 or C.LINE_DIR.match(txt):
                    i += 1
                    continue
                bs = raw[ad[i] - BASE:ad[i] + sz - BASE]
                if len(bs) != sz:
                    sys.exit("byte extent mismatch at %s:%d" % (rel, i))
                cmt = ""
                if ";" in txt:
                    cmt = "\t;" + txt.split(";", 1)[1]
                lab = ""
                m = C.LABEL_DEF.match(txt)
                if m:
                    lab = m.group(1) + ":"
                edits.setdefault(rel, {})[i] = (
                    "%s\t.byte %s%s" % (lab, ", ".join("0x%02x" % b for b in bs), cmt))
                i += 1

    changed = sum(len(v) for v in edits.values())
    print("lines to retype: %d" % changed)
    if not apply_:
        print("(dry run; pass --apply to write)")
        return 0
    for rel, m in edits.items():
        path = os.path.join(ROOT, "hdae5000", rel)
        lines = open(path, encoding="latin-1").read().split("\n")
        for i, new in m.items():
            lines[i - 1] = new
        open(path, "w", encoding="latin-1").write("\n".join(lines))
        print("written: hdae5000/%s (%d lines)" % (rel, len(m)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
