#!/usr/bin/env python3
"""Emit @@DATA declarations for prom_a 0xFA15CC-0xFA5400 into
notes/prom_a_block_headers.txt, from the layout notes/prom_a_fa1404_identify.py
already proved (23/23 --selftest checks, 0 bytes unaccounted, 0 overlaps).

QUESTION IT ANSWERS
  "prom_a's biggest remaining `.incbin`, 15,924 bytes, is the SYSTEM-menu
   module. notes/prom_a_fa1404_identify.py already classifies every byte of it
   (jump table, RAM-init descriptors, sixteen 23-entry handler tables, display
   lists, operand arrays, string tables, two code blocks, and the closing
   0x0E pad) and proves the boundaries by content, not by length alone. How
   does that layout become real `.byte`/`.long`-typed source instead of
   `.incbin`, without hand-writing ~270 header blocks?"

  This script is the bridge: it calls identify.solve() (the same function
  --selftest exercises) and turns every non-code, non-pad object into one
  `@@DATA lo hi Label` block for notes/gen_prom_a_block.py, which then
  linearly decodes the gaps left over (the two `code` objects: the 28-byte
  tail of 0xFA148B-0xFA15E8 and the 1,204-byte routine at 0xFA4EB5-0xFA5369)
  as real instructions, verified byte-exact by prom_a/roundtrip.py, and folds
  in the trailing 0x0E pad automatically via its own pad_runs().

  ⚠ TERRITORIAL COVERAGE ONLY. Every label is a bare `<Kind>_XXXXXX` address
  label, not a semantic name -- this round does not interpret what a display
  list draws or what a handler table dispatches, only proves WHERE each object
  starts and ends and reproduces its exact bytes as typed data. Naming is a
  later pass, same rule as every other gen_prom_a_*.py cover script.

WHY .byte, NOT .long, FOR THE HANDLER/POINTER TABLES
  handler_table_23 and pointer_table_3 are 4-byte-aligned pointer arrays by
  construction (R3 PTR23 in identify.py: 23 consecutive LE32 words each either
  the T_TableDefault_Ret no-op stub or inside 0xF90000-0xFB0000), so `.long` would be
  defensible. This script still emits `.byte` for everything, because
  gen_prom_a_block.py's `longs_block` REFUSES a span whose length is not a
  multiple of 4, and getting that wrong for 270 auto-generated spans is a
  bigger risk than a `.long` would repay for a coverage-only pass; `.byte` is
  this tree's stated honest default (see gen_prom_a_block.py's own docstring).

RUN
  python3 notes/gen_prom_a_fa15cc_headers.py >> notes/prom_a_block_headers.txt
  python3 notes/gen_prom_a_block.py 0xFA15CC 0xFA5400 > /tmp/fa15cc_region.s
  python3 prom_a/insert_region.py 0xFA15CC 0xFA5400 /tmp/fa15cc_region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_fa1404_identify as ID  # noqa: E402

LO = 0xFA15CC
HI = 0xFA5400

PREFIX = {
    "display_list": "DisplayList",
    "operand_table": "OperandTable",
    "handler_table_23": "HandlerTable23",
    "pointer_table_3": "PtrTable3",
    "descriptor_9": "Descriptor9",
    "descriptor_3": "Descriptor3",
}


def label_for(lo, kind):
    if kind.startswith("byte_table_"):
        n = kind[len("byte_table_"):]
        return "ByteTable%s_%06X" % (n, lo)
    prefix = PREFIX.get(kind)
    if prefix is None:
        sys.exit("no label prefix known for kind %r" % kind)
    return "%s_%06X" % (prefix, lo)


def main():
    known = ID.solve()
    objs = [o for o in known if o[0] >= LO and o[1] <= HI]
    objs.sort()
    seen_lo = set()
    out = []
    for lo, hi, kind, evidence in objs:
        if kind in ("code", "pad"):
            continue  # left for gen_prom_a_block.py's own decode / pad_runs()
        if lo in seen_lo:
            sys.exit("REFUSED: duplicate object start 0x%06X" % lo)
        seen_lo.add(lo)
        label = label_for(lo, kind)
        out.append("@@DATA 0x%06X 0x%06X %s" % (lo, hi, label))
        out.append("; ---------------------------------------------------------------------")
        out.append("; %s -- %d bytes, kind=%s" % (label, hi - lo, kind))
        out.append(";")
        out.append("; Boundary evidence (notes/prom_a_fa1404_identify.py, function solve(),")
        out.append("; asserted by its own --selftest): %s" % evidence)
        out.append("; Coverage only: this round reproduces the bytes and states the object")
        out.append("; TYPE the layout tool proved; it does not interpret the payload. See")
        out.append("; notes/FINDINGS-prom_a-round3-modules.md \xa74 for the module overview")
        out.append("; (SYSTEM menu: TUNE & SCALE, CONTROLLER ASSIGN, RE-MAP EDIT, MIXER, ...)")
        out.append("; and notes/prom_a_fa1404_identify.py --fine for the full object list.")
        out.append("; ---------------------------------------------------------------------")
        out.append("")
    print("\n".join(out))


if __name__ == "__main__":
    main()
