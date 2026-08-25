#!/usr/bin/env python3
"""prom_c 0x0010C000 BYTE-PAIR CHECK -- are the ten registers of block group
0x20-0x29 (0x0800..0x0A40 + chan) each a PAIR OF 8-BIT FIELDS?

WHAT QUESTION THIS ANSWERS
--------------------------
Gap **A** of ../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md asks what a 0x0010C000
register MEANS.  Before any register can be given a physical name, its FORMAT has to be
read off the code that builds it.  This script establishes one format for one whole block
group: every store into staging words 12..21 -- the words Dev10C_WriteAllChanRegs sends to
registers 0x0800, 0x0840, 0x0880, 0x08C0, 0x0900, 0x0940, 0x0980, 0x09C0, 0x0A00 and
0x0A40 of one channel -- assembles the word out of TWO SEPARATELY COMPUTED BYTES.

Two assembly idioms do it, and the script counts both:

  PACK    `sll 0x08,<hi>` ... `or <hi>,<lo>`            -- the high byte shifted in
  MERGE   `and <src>,0xff00` ... `and <v>,0x00ff` ... `or` -- the high byte KEPT from a
                                                            source word, the low replaced

MERGE is the same split seen from the other side: it proves the boundary is at bit 8 just
as PACK does.

⚠ WHAT THIS IS AND IS NOT.  This is a WINDOW HEURISTIC over the gate-certified listing
`prom_c/wsa1_prom_c.s`, not a dataflow analysis: it looks at the twelve instructions before
each store.  It is offered as a CENSUS, and the per-site readings quoted in
notes/FINDINGS-prom_c-voice-readback.md were done by hand at the six sites named there.
A site classified PLAIN is one where a whole word is stored unchanged -- those are real and
are listed, not hidden.

⚠ It says NOTHING about what either byte MEANS.  No register is named here.

USAGE
    python3 notes/prom_c_reg_bytepair_check.py            # the census
    python3 notes/prom_c_reg_bytepair_check.py --selftest # assert the totals below
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
INSN = re.compile(r";\s([0-9A-F]{6})\s\s(.+?)\s*$")
WINDOW = 12

WORD_OF_ADDR = {0xD776: 12, 0xD778: 13, 0xD77A: 14, 0xD77C: 15, 0xD77E: 16,
                0xD780: 17, 0xD782: 18, 0xD784: 19, 0xD786: 20, 0xD788: 21}
REG_OF_WORD = {12: 0x0800, 13: 0x0840, 14: 0x0880, 15: 0x08C0, 16: 0x0900,
               17: 0x0940, 18: 0x0980, 19: 0x09C0, 20: 0x0A00, 21: 0x0A40}

seq = []
for line in open(SRC, encoding="utf-8"):
    m = INSN.search(line.rstrip("\n"))
    if m:
        seq.append((int(m.group(1), 16), m.group(2)))

rows = []
for i, (addr, text) in enumerate(seq):
    m = re.match(r"ld \(0x00d7([0-9a-f]{2})\),(\S+)", text)
    if not m:
        continue
    slot = 0xD700 | int(m.group(1), 16)
    if slot not in WORD_OF_ADDR:
        continue
    operand = m.group(2)
    if operand.startswith("0x"):
        continue                       # an immediate zero-fill, not a computed value
    back = [seq[j][1] for j in range(max(0, i - WINDOW), i)]
    pack = any(x.startswith("sll 0x08,") for x in back) and any(x.startswith("or ") for x in back)
    merge = (any("0xff00" in x and x.startswith("and ") for x in back)
             and any("0x00ff" in x and x.startswith("and ") for x in back)
             and any(x.startswith("or ") for x in back))
    kind = "PACK" if pack else ("MERGE" if merge else "PLAIN")
    rows.append((WORD_OF_ADDR[slot], addr, kind, text))

rows.sort()
tally = {}
print("word  register        store       how")
for word, addr, kind, text in rows:
    tally[kind] = tally.get(kind, 0) + 1
    print(f" {word:2d}   0x{REG_OF_WORD[word]:04X} + chan   0x{addr:06X}   {kind:<5}  {text}")
print()
print(f"{len(rows)} computed stores over {len({r[0] for r in rows})} of the 10 words: "
      + " · ".join(f"{k} {v}" for k, v in sorted(tally.items())))
print("PLAIN sites store a whole source word unchanged; both other idioms split at bit 8.")

if "--selftest" in sys.argv:
    # the LAST row, and the totals, as of round 2 2026-08-25
    want_last = (21, 0xFA95C3, "PACK")
    got_last = rows[-1][:3]
    ok = (got_last == want_last and len(rows) == 22
          and tally == {"PACK": 12, "MERGE": 8, "PLAIN": 2}
          and len({r[0] for r in rows}) == 10)
    print()
    print(f"selftest: LAST row {got_last} (want {want_last}); {len(rows)} rows "
          f"(want 22); {tally} (want PACK 12 / MERGE 8 / PLAIN 2); "
          f"{len({r[0] for r in rows})} distinct words (want 10)")
    print("selftest: OK" if ok else "selftest: FAILED")
    sys.exit(0 if ok else 1)
