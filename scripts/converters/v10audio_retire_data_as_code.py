#!/usr/bin/env python3
"""v10audio_retire_data_as_code.py -- return the VoiceSlot_CheckAndApply data
blocks in v10/maincpu/audio/note_voice_mapping.s from garbage mnemonics to
typed data.

QUESTION ANSWERED
  Which bytes of this lane's files are DATA that the disassembly wrote out as
  instructions?  That is the opposite defect from code-as-`.byte`, it is
  invisible to any `.byte`/`.incbin` counter, and the byte gate cannot object to
  it because re-assembling a wrong reading reproduces the same bytes.

THE EVIDENCE -- the lane brief's own rule, satisfied exactly
  Every reference in the whole tree to this family's data labels is an ADDRESS
  LOAD.  `VoiceSlot_CheckAndApply_Data`, `_Data_0xD`, `_Data_0x91`, `_Data_0xBA`,
  `_Data_0x189` and `_Data2` are reached only by `ld xiz, <label>` (20 such
  sites), never by a call, jp, jr or djnz.  The two labels in the same family
  that ARE branch targets -- `_Prologue` (called) and `_LoadReg` (calr'd) -- are
  genuine code and are left untouched, which is what makes this a discriminating
  test rather than a blanket one.  The positional labels `_0xD` / `_0x91` /
  `_0xBA` / `_0x189` in v10/maincpu/shared/positional_labels.s show the tree had
  already worked out where the sub-tables start; only the CONTENT was still
  spelled as instructions.

  Corroboration from the bytes themselves: every byte of 0xFEA356..0xFEA4B7 is
  <= 0x0F, and 0xFEA356..0xFEA3D9 is the sequence 0x01..0x0C repeated ELEVEN
  times.  The current source spells that as `halt`, `ei 7`, `ldio 9,10`,
  `pushw 268`, `push sr`, `pop sr` and `.fill 8,1,0x04`.
  Lane V10DAC's v10_data_as_code_census.py had already flagged 24 B of it
  (0xFEA409-0xFEA421) with an in-source comment; it could not see the rest
  because its spans are maximal CODE-TERRITORY runs, and the `.byte` islands
  scattered through a misframed region shatter it into pieces below its size
  floor.  That is the general lesson: the two censuses are blind to each other
  exactly where a region alternates between the two defects.

WHAT IS EMITTED
  0xFEA349          1 B   0x00
  0xFEA34A..0xFEA355  12 B  an index row (0x24..0x2C, 0x21..0x23)
  0xFEA356..0xFEA3D9 132 B  11 rows of 0x01..0x0C  -> emitted 12 per line
  0xFEA3DA..0xFEA402  41 B  0x03/0x04 selector bytes
  0xFEA403..0xFEA4D1 207 B  4-byte records         -> emitted 4 per line
  0xFEA4D2..0xFEA501  48 B  24 little-endian 16-bit masks, powers of two
                            -> emitted as .hword (the address is even)
  0xFEA514..0xFEA53A  39 B  16 more 16-bit masks then a 7-byte index row
  0xFEA53B..0xFEA53F   5 B  ⚠ NOT data: the byte 0xC2 that starts
                            `ldb_da a,(0xcede)` had been swallowed by the
                            preceding `.ascii`, so the tree's next "instruction"
                            was framed one byte late as `or iz,8448`.  This is
                            re-framed to the real instruction, which is what
                            every following pair in the same run already says.

RUN
    python3 scripts/analysis/address_line_map.py --dump amap.json
    python3 scripts/converters/v10audio_retire_data_as_code.py --amap amap.json
    python3 scripts/converters/v10audio_retire_data_as_code.py --amap amap.json --apply

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = 0xE00000
REL = "audio/note_voice_mapping.s"
LABEL_RE = re.compile(r'^\s*[A-Za-z_.$][\w.$]*\s*:')


def rows(rom, a, b, width, kind="byte"):
    out = []
    if kind == "hword":
        for off in range(a, b, 2 * width):
            vals = [int.from_bytes(rom[o - BASE:o - BASE + 2], "little")
                    for o in range(off, min(off + 2 * width, b), 2)]
            out.append("\t.hword " + ", ".join("0x%04x" % v for v in vals))
    else:
        for off in range(a, b, width):
            vals = rom[off - BASE:min(off + width, b) - BASE]
            out.append("\t.byte " + ", ".join("0x%02x" % v for v in vals))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    rom = (REPO / "original_ROMs" / "kn5000_v10_program.rom").read_bytes()
    src = "v10/maincpu/" + REL
    amap = json.load(open(a.amap))
    first = {}
    for e in amap:
        if e["src"] == src:
            first.setdefault(e["line"], e["addr"])
    ordered = sorted(first.items(), key=lambda kv: (kv[1], kv[0]))

    body1 = (rows(rom, 0xFEA349, 0xFEA34A, 1)
             + ["\t; index row"] + rows(rom, 0xFEA34A, 0xFEA356, 12)
             + ["\t; 11 rows of 0x01..0x0c"] + rows(rom, 0xFEA356, 0xFEA3DA, 12)
             + ["\t; selector bytes"] + rows(rom, 0xFEA3DA, 0xFEA403, 8)
             + ["\t; 4-byte records"] + rows(rom, 0xFEA403, 0xFEA4D2, 4)
             + ["\t; 16-bit masks, powers of two"]
             + rows(rom, 0xFEA4D2, 0xFEA502, 8, "hword"))
    body2 = (rows(rom, 0xFEA514, 0xFEA534, 8, "hword")
             + ["\t; index row"] + rows(rom, 0xFEA534, 0xFEA53B, 7)
             + ["\tldb_da a, (0xcede)"])

    # (span start addr, span end addr, replacement lines)
    SPANS = [(0xFEA349, 0xFEA502, body1), (0xFEA514, 0xFEA540, body2)]

    path = REPO / "v10" / "maincpu" / REL
    lines = open(path, encoding="latin-1").read().split("\n")
    edits = []
    for start, end, body in SPANS:
        l0 = next(ln for ln, ad in reversed(ordered) if ad <= start)
        l1 = next(ln for ln, ad in reversed(ordered) if ad < end)
        after = [ad for ln, ad in ordered if (ad, ln) > (first[l1], l1)]
        span_end = min(after)
        if first[l0] != start or span_end != end:
            sys.exit(f"0x{start:06X}: span is 0x{first[l0]:06X}..0x{span_end:06X} "
                     f"-- refusing")
        for t in lines[l0 - 1:l1]:
            if LABEL_RE.match(t):
                sys.exit(f"0x{start:06X}: label inside span: {t!r} -- refusing")
        print(f"0x{start:06X}..0x{end:06X}  {end-start:4d} B  lines {l0}..{l1} "
              f"({l1-l0+1} lines) -> {len(body)} lines")
        if not a.apply:
            for t in body[:8]:
                print("      " + t)
            print(f"      ... ({len(body)-8} more)")
        edits.append((l0, l1, body))

    if not a.apply:
        print("(dry run; pass --apply)")
        return
    for l0, l1, body in sorted(edits, reverse=True):
        lines[l0 - 1:l1] = body
    open(path, "w", encoding="latin-1").write("\n".join(lines))
    print(f"wrote {path}")


if __name__ == "__main__":
    main()
