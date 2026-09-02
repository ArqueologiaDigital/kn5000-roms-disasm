#!/usr/bin/env python3
r"""TYPE THE 4-BYTE POINTER-TABLE ENTRIES IN v10 widget_dispatch.s AS `.long`.

QUESTION ANSWERED
-----------------
`scripts/analysis/v10_widget_dispatch_byte_triage.py` splits the file's 25,211
`.byte` operands into code / structured-data / genuine-byte-table.  This script
performs the only conversion the STRUCT evidence actually supports: `.byte`
lines that are entries of a 4-byte-strided pointer table, rewritten as `.long`.

The conversion is byte-exact by construction (little-endian `.long` of the very
bytes that are already there) and is certified by `make gate-all`.

WHY AN ADJUDICATED WINDOW LIST AND NOT A RULE
---------------------------------------------
An automatic rule -- "4-aligned, size%4==0, inside a stretch that is mostly
`.long`, every word address-shaped" -- proposes ~1.8 KB.  Reviewing the
proposals by hand rejected most of them, and the rejections are the interesting
part.  So the rule PROPOSES and this file's WINDOWS record the adjudication.
Each window below states the evidence that its element width really is 4.

  0xEE0180-0xEE0198  Naka_SubDispatch_A_Table.  Six words; five equal the
      addresses of the MIDI_CC_*_VALUE work-RAM cells (0x8EE4, 0x8EE6, 0x8EE8,
      0x8EEA, 0x8EF4).  Immediately preceded and followed by `.long` entries of
      the same table.
  0xEE1160-0xEE14C8  Naka_MainDispatch_Table tail.  The enclosing table is 916
      `.long` symbol entries (78% of the stretch by bytes); the `.byte` slots
      hold work-RAM record pointers with a constant stride of 0x1A (0xF9B6,
      0xF9D0, 0xF9EA, ...), and the `.zero` separators between them are all
      multiples of 4.
  0xEE8D74-0xEE8DF4  AudioInit_VoiceDispatch_Table.  The SAME 0xF9B6+0x1A
      pointer list, starting immediately after a run of
      `.long AudioInit_ConfigStereoVoice`.  The last source line straddles the
      end of the table -- its first word is the final pointer, its remaining
      four bytes are the first entries of an identity byte map (0,1,2,3) -- so
      that line is SPLIT rather than converted whole.
  0xEE8430-0xEE86D0  UIState_ConfigB_* handler array.  4-byte slots, 89% of the
      stretch already `.long <handler>`; the `.byte` slots are the 0xFFFFFFFF
      empty-slot sentinel (which the same table also spells `.fill 4,1,0xff`)
      and six ROM handler addresses that have no symbol (0x00FEAAC5, 0x00FEABD6,
      0x00FEABD8, 0x00FC7BED, 0x00FDE9AD, 0x00FDE982, 0x00FEAE38, 0x00EF758B,
      0x00FEB932, 0x00EF75FD).
  0xEE6364-0xEE6368  ToneKit_VoiceDispatch_Table.  One null slot inside a
      stretch that is 99% `.long`.

WHAT WAS PROPOSED AND REFUSED (do not "fix" these later without new evidence)
  * MidiPkt_EventType_Table around 0xEE3358.  The rule accepted one line whose
    words are 0x00000000 / 0x0000FF00, but the region is a repeating `00 00 00
    ff` pattern and the accepted line is that pattern seen one byte out of
    phase.  Element width is NOT established.
  * WidgetParam_Entry_* / DisplayScript_Node_* around 0xEE45xx.  These are
    SIX-byte records {u16 tag, u32 pointer}.  Proof: at 0xEE45C8 the stream is
    `78 36 ee 00 | ff 0e | 78 36 ee 00 | fe 00 | c6 45 ee 00`, and the tree's
    existing `.long AudioInit_PartConfig_CheckCarry` (= 0x00FE00EE) at 0xEE45D0
    STRADDLES a record boundary -- it is a byte-exact misframe the gate cannot
    see.  Adding more `.long` there would assert a width that is wrong.
  * SoundEffect_Dispatch_Table 0xEEAE08 onwards (~5 KB of `.byte`).  The values
    read as 16-bit codes (0x8915, 0x8023, 0x801C, 0x0906) or equally as pairs of
    byte fields; nothing in the tree settles which.  `.word` would be a guess.
  * CharMap_ValueData_B 0xEE8ED8 onwards (7,656 B).  Small integers 0x03..0x11;
    a genuine byte table.

STEP 2: ONE CODE MISFRAME INSIDE A CHARACTER MAP
------------------------------------------------
`CharMap_Mode5Forward` is a sparse one-byte-per-slot character map (entries
0x25..0x53, holes 0xFF).  At 0xEEC5C8 the tree spells three of its slots as an
instruction, `ldw hl, 0xff34` -- bytes `33 34 ff`, sitting between `... 31 ff
25` and `2d 36 37 38 39 ...`.  It is byte-exact, so the gate cannot object, and
it is the reason the triage script's fall-through rule reported a CODE verdict
for the 21 bytes that follow it.  Step 2 restores those three bytes to `.byte`.

RUN
    python3 scripts/converters/v10_widget_dispatch_ptr_entries.py --dry-run
    python3 scripts/converters/v10_widget_dispatch_ptr_entries.py
    make gate-all          # the only certification

Idempotent: re-running after a successful conversion finds nothing to do.
Needs the address map; set AMAP_CACHE=<file> to reuse one, otherwise it is
rebuilt (which needs `make everything` to have run once).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TARGET = "v10/maincpu/ui_widgets/widget_dispatch.s"
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000

WINDOWS = [
    (0xEE0180, 0xEE0198, "Naka_SubDispatch_A_Table: MIDI_CC work-RAM pointers"),
    (0xEE1160, 0xEE14C8, "Naka_MainDispatch_Table: work-RAM record pointers, stride 0x1A"),
    (0xEE8D74, 0xEE8DF4, "AudioInit_VoiceDispatch_Table: same pointer list"),
    (0xEE8430, 0xEE86D0, "UIState_ConfigB_*: 4-byte handler slots"),
    (0xEE6364, 0xEE6368, "ToneKit_VoiceDispatch_Table: null slot"),
]


def in_window(a):
    return any(lo <= a < hi for lo, hi, _ in WINDOWS)


def parse_line(ln):
    code = ln.split(";")[0].strip()
    if not code:
        return None, None
    lab = None
    m = re.match(r"^([A-Za-z_.][\w.$]*)\s*:", code)
    if m:
        lab = m.group(1)
        code = code[m.end():].strip()
    if not code:
        return "LABELONLY", lab
    m = re.match(r"^(\.[a-z_0-9]+)\b", code)
    return (m.group(1) if m else "INSN"), lab


def address_map():
    cache = os.environ.get("AMAP_CACHE", "")
    if cache and os.path.exists(cache):
        return json.load(open(cache))
    sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
    import address_line_map as A
    ent, _, _ = A.build()
    out = [{"addr": a, "src": s, "line": l} for a, s, l, _ in ent]
    if cache:
        json.dump(out, open(cache, "w"))
    return out


def main():
    dry = "--dry-run" in sys.argv
    amap = address_map()
    addr = {e["line"]: e["addr"] for e in amap if e["src"] == TARGET}
    path = os.path.join(ROOT, TARGET)
    src = open(path, encoding="latin-1").read().split("\n")
    rom = open(ROM, "rb").read()

    # sizes: the address of the next byte-emitting line
    emit = []
    for i, ln in enumerate(src, 1):
        k, _ = parse_line(ln)
        if k in (None, "LABELONLY"):
            continue
        emit.append({"k": k, "line": i, "a": addr.get(i)})
    for j, x in enumerate(emit):
        x["sz"] = (emit[j + 1]["a"] - x["a"]) if j + 1 < len(emit) and x["a"] is not None else 0

    new = list(src)
    nlines = nwords = nbytes = 0
    for x in emit:
        if x["k"] != ".byte" or x["a"] is None or x["sz"] == 0:
            continue
        if not in_window(x["a"]):
            continue
        ln = src[x["line"] - 1]
        assert ";" not in ln and ":" not in ln, "line %d carries a label/comment" % x["line"]
        assert x["a"] % 4 == 0, "line %d is not 4-aligned" % x["line"]
        b = rom[x["a"] - BASE:x["a"] - BASE + x["sz"]]
        indent = ln[:len(ln) - len(ln.lstrip())] or "\t"
        out, tail = [], []
        for o in range(0, len(b), 4):
            a = x["a"] + o
            if len(b) - o >= 4 and in_window(a):
                out.append("%s.long 0x%08x" % (indent, int.from_bytes(b[o:o + 4], "little")))
                nwords += 1
                nbytes += 4
            else:
                tail.extend(b[o:o + 4])
        if tail:
            out.append("%s.byte %s" % (indent, ", ".join("0x%02x" % c for c in tail)))
        new[x["line"] - 1] = "\n".join(out)
        nlines += 1

    # ---- step 2: the charmap code misframe (see the header) ----------------
    MISFRAME = ("\tldw\thl, 0xff34", "\t.byte 0x33, 0x34, 0xff")
    nmis = 0
    for i, ln in enumerate(new):
        if ln == MISFRAME[0]:
            new[i] = MISFRAME[1]
            nmis += 1
    assert nmis <= 1, "expected at most one charmap misframe, found %d" % nmis

    print("%d source lines -> %d `.long` entries, %d bytes typed; "
          "%d charmap code misframe(s) restored to .byte"
          % (nlines, nwords, nbytes, nmis))
    if dry:
        for i, (o, n) in enumerate(zip(src, new), 1):
            if o != n:
                print("  %5d: %-46s ->  %s" % (i, o.strip(), n.replace("\n", " | ").strip()))
        return
    if nlines or nmis:
        tmp = path + ".tmp"
        open(tmp, "w", encoding="latin-1").write("\n".join(new))
        os.replace(tmp, path)
        print("wrote", path)


if __name__ == "__main__":
    main()
