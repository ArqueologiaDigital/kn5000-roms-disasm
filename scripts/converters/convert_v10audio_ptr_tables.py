#!/usr/bin/env python3
"""convert_v10audio_ptr_tables.py -- type the five 32-bit pointer tables of the
v10 maincpu audio control engine as `.long`, byte-exactly.

QUESTION ANSWERED
  Five regions of v10/maincpu/audio/audio_control_engine.s are indexed by code
  that computes `index * 4` and then either CALLs through the result or copies a
  record from it.  They were carried as anonymous `.byte` runs -- and one of them
  (VoiceMode3_DispatchTable) was carried as 25 bytes of MNEMONICS, i.e. as
  data-as-code.  This script replaces exactly those spans with `.long` entries.

  This is a TYPING change, not a decode: a pointer table spelled as `.long` and
  the same table spelled as `.byte` assemble to identical bytes, so `make gate`
  proves the EXTENT is right and says nothing about the reading.  The reading
  rests on the evidence below, not on the gate.

THE EVIDENCE, PER TABLE (all in audio_control_engine.s)
  A  MidiSeqBuf_ProcessorTable_0x1   0xFCA697   8 entries
       `and w,0x7 ; sll w,2 ; ld xix,<table> ; ld_sril3 XIX,... ; call (xix)`
       -- a *4-scaled index and an INDIRECT CALL through the loaded word.
  B  TempoRing_ProcessorTable_0x1    0xFCA8B9  16 entries   same call site shape
  C  VoiceMode3_DispatchTable_0x1    0xFCB025  16 entries   same call site shape
  D  VoiceMode_ParamConfigTables_0x68  0xFCBA47  20 entries
       `sll hl,2 ; ld xix,<table> ; ld_sril3 XIY,...` then a copy loop that
       reads words until 0xFF -- a *4-scaled index into a table of RECORD
       POINTERS, not a call.
  E  VoiceMode_ParamConfigTables_0x5C4 0xFCBFA3  20 entries  same as D

  Corroboration the shape test alone does not give:
   * A, B and C each begin with a byte 0xFF and each has its "unused" slots all
     pointing at ONE address -- the byte immediately after the table (0xFCA6B7,
     0xFCA8F9, 0xFCB065 respectively).  A table whose default slot is its own
     end is a table.
   * D and E: entry[0] is exactly the first byte after the table, the 20 targets
     are all distinct, and their sorted spacings are 0x58,0x58,0x58 then 0x44 x12
     -- which is exactly the length of the config blocks that follow (20 four-byte
     records plus an 8-byte 0xFF separator = 0x58).  D's and E's permutations are
     IDENTICAL, i.e. two parallel tables over the same index space.
   * 0xFCBA47 and 0xFCBFA3 were ALREADY named in v10/maincpu/shared/positional_
     labels.s as VoiceMode_ParamConfigTables_0x68 / _0x5C4 -- the tree already
     knew something pointed at exactly those two offsets.

HOW THE EXTENT IS PINNED
  Source lines are found through scripts/analysis/address_line_map.py's dump, so
  a span is anchored on a ROM ADDRESS, not on a line number that moves when an
  earlier block is edited (convert_region.py's documented fragility).  The script
  refuses to touch a span containing a label or a comment, and refuses to split
  a straddling line that is not itself a `.byte` line.

RUN
    python3 scripts/analysis/address_line_map.py --dump amap.json
    python3 scripts/converters/convert_v10audio_ptr_tables.py --amap amap.json
    python3 scripts/converters/convert_v10audio_ptr_tables.py --amap amap.json --apply
    make rebuilt_ROMs/kn5000_v10_program.llvm.rom && cmp original_ROMs/... rebuilt_ROMs/...

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ELF = REPO / "rebuilt_ROMs" / "kn5000_v10_program.llvm.elf"
BASE = 0xE00000

REL = "audio/audio_control_engine.s"
# name, table base address, entry count, symbol to express targets relative to,
# how many bytes BEFORE the base to pull into the rewritten span as raw `.byte`
# (all three dispatch tables are preceded by a single 0xFF byte; in table C that
# byte was being spelled `swi 7`, i.e. as an instruction).
TABLES = [
    ("MidiSeqBuf_ProcessorTable_0x1",     0xFCA697,  8, None, 0),
    ("TempoRing_ProcessorTable_0x1",      0xFCA8B9, 16, None, 0),
    ("VoiceMode3_DispatchTable_0x1",      0xFCB025, 16, None, 1),
    ("VoiceMode_ParamConfigTables_0x68",  0xFCBA47, 20, "VoiceMode_ParamConfigTables", 0),
    ("VoiceMode_ParamConfigTables_0x5C4", 0xFCBFA3, 20, "VoiceMode_ParamConfigTables", 0),
]

LABEL_RE = re.compile(r'^\s*[A-Za-z_.$][\w.$]*\s*:')
BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')


def symbols():
    out = subprocess.run([NM, "--defined-only", str(ELF)],
                         capture_output=True, text=True).stdout
    sym = {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) == 3 and p[1] in "tTdDrRbB":
            a = int(p[0], 16)
            if BASE <= a < BASE + 0x200000:
                sym.setdefault(a, p[2])
    return sym


def byteline(vals, indent="\t"):
    return indent + ".byte " + ", ".join("0x%02x" % v for v in vals)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    amap = json.load(open(a.amap))
    src_rel = "v10/maincpu/" + REL
    rows = sorted((e["addr"], e["line"]) for e in amap if e["src"] == src_rel)
    # first address emitted by each line, and the line owning each address
    line_addr = {}
    for addr, ln in rows:
        line_addr.setdefault(ln, addr)
    ordered = sorted(line_addr.items(), key=lambda kv: (kv[1], kv[0]))

    rom = open(REPO / "original_ROMs" / "kn5000_v10_program.rom", "rb").read()
    sym = symbols()
    path = REPO / "v10" / "maincpu" / REL
    lines = open(path, encoding="latin-1").read().split("\n")

    def line_of(addr):
        """The 1-indexed line whose emitted bytes contain `addr`."""
        best = None
        for ln, ad in ordered:
            if ad <= addr:
                if best is None or (ad, ln) > (line_addr[best], best):
                    best = ln
            else:
                break
        return best

    def start_of(ln):
        return line_addr[ln]

    def next_line_addr(ln):
        for l2, ad in ordered:
            if (ad, l2) > (line_addr[ln], ln):
                return ad
        return None

    edits = []
    for name, base, k, relsym, pre in TABLES:
        end = base + 4 * k
        l0, l1 = line_of(base - pre), line_of(end - 1)
        assert l0 and l1, name
        span_start, span_end = start_of(l0), next_line_addr(l1)
        body = lines[l0 - 1:l1]
        for t in body:
            if LABEL_RE.match(t):
                sys.exit(f"{name}: label inside span at line: {t!r} -- refusing")
            if ";" in t:
                sys.exit(f"{name}: comment inside span at line: {t!r} -- refusing")
        new = []
        if span_start < base:
            if span_start < base - pre and not BYTE_RE.match(lines[l0 - 1]):
                sys.exit(f"{name}: span starts mid-line on a non-.byte line -- refusing")
            new.append(byteline(rom[span_start - BASE:base - BASE]))
        for i in range(k):
            v = int.from_bytes(rom[base - BASE + 4 * i:base - BASE + 4 * i + 4], "little")
            if v in sym:
                txt = sym[v]
            elif relsym and relsym in [s for s in sym.values()]:
                rb = next(ad for ad, s in sym.items() if s == relsym)
                txt = "%s + 0x%x" % (relsym, v - rb) if v >= rb else "0x%08x" % v
            else:
                txt = "0x%08x" % v
            new.append("\t.long %s" % txt)
        if span_end > end:
            if not BYTE_RE.match(lines[l1 - 1]):
                sys.exit(f"{name}: span ends mid-line on a non-.byte line -- refusing")
            new.append(byteline(rom[end - BASE:span_end - BASE]))
        edits.append((l0, l1, new, name, span_end - span_start))
        print(f"{name}: 0x{base:06X} x{k} -> lines {l0}..{l1} "
              f"(span 0x{span_start:06X}..0x{span_end:06X}, {span_end-span_start} B), "
              f"{l1-l0+1} lines -> {len(new)} lines")
        if not a.apply:
            for t in new:
                print("      " + t)

    if not a.apply:
        print("\n(dry run; pass --apply)")
        return

    for l0, l1, new, name, _ in sorted(edits, reverse=True):
        lines[l0 - 1:l1] = new
    open(path, "w", encoding="latin-1").write("\n".join(lines))
    print(f"\nwrote {path}")


if __name__ == "__main__":
    main()
