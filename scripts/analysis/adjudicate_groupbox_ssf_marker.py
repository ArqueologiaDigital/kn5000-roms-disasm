#!/usr/bin/env python3
r"""IS 0xF98697 STILL UNDECODED, AS ui_control_panel.s CLAIMS?

QUESTION ANSWERED
-----------------
`scripts/analysis/kn5000_source_coverage.py` scans for this project's own
self-tagged markers and reports exactly three "still undecoded" regions in the
whole tree -- and all three are the same region in the three main-CPU images:

    v10/maincpu/ui/ui_control_panel.s:1878
    v9/maincpu/ui/ui_control_panel.s:1878
    v7/maincpu/ui/ui_control_panel.s:1885
        ; GroupBoxNotify_SendSSFEvent (0xf98697)  [UNDECODED -- still in .byte form]

This script asks whether that is true, from two directions that cannot agree by
accident:

  A. THE SOURCE.  Does a label sit at exactly 0xF98697, and does the block that
     follows it contain any `.byte`?  The address comes from
     symbols/maincpu_<tag>_symbols_reference.txt, not from the marker.
  B. THE ROM.  Decode original_ROMs/ at 0xF98697 with MAME unidasm -- an
     independent disassembler that has never seen this source -- and check it
     names the same absolute addresses as the source block.

! COMPARING MNEMONIC TEXT DOES NOT WORK, and is not what this does.  The tree
  spells instructions through encoding-specific aliases (`cps hl, 0`,
  `ldb_d8 a, (0x8d38)`, `lda_24`, `ld_rrl`) where unidasm prints the plain form
  (`cp HL,0`, `ld A,(0x8d38)`, `lda`, `ld XIX,(XBC+WA)`).  A first attempt at
  this script scored 7/12 on opcode text alone and would have reported a FALSE
  "still undecoded": the two decodes agree completely, they just do not spell
  the same.  What IS spelling-independent -- and is exactly what a wrong
  framing would destroy -- is the set of OPERAND ADDRESSES the block names,
  with this tree's symbol names resolved back to their numeric values.

! v7 IS DIFFERENT AND THE MARKER HIDES IT.  v7's marker names the same address
  0xf98697, but v7's `UIState_KeyScan_Dispatch` is at 0xF9828A.  The v7 marker
  text was copied from v9/v10 without re-deriving the address, so it points at
  whatever v7 happens to have at 0xF98697.  Reported separately.

RUN (needs only original_ROMs/ and symbols/, no build):
    python3 scripts/analysis/adjudicate_groupbox_ssf_marker.py
"""
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
LABEL = "UIState_KeyScan_Dispatch"
MARKER_ADDR = 0xF98697

TAGS = {"v10": "kn5000_v10_program.rom", "v9": "kn5000_v9_program.rom",
        "v7": "kn5000_v7_program.rom"}

SYMS = {}


def symtab(tag):
    if tag not in SYMS:
        d = {}
        p = os.path.join(REPO, "symbols", f"maincpu_{tag}_symbols_reference.txt")
        for line in open(p, encoding="latin-1"):
            f = line.split()
            if len(f) == 2:
                try:
                    d[f[0]] = int(f[1], 16)
                except ValueError:
                    pass
        SYMS[tag] = d
    return SYMS[tag]


def symaddr(tag, name):
    return symtab(tag).get(name)


def operand_addrs(tag, text):
    """Absolute addresses (>= 0x100) named by a block of assembly, with this
    tree's symbol names resolved to their numeric value."""
    out = set()
    for m in re.finditer(r'0x([0-9a-fA-F]+)', text):
        v = int(m.group(1), 16)
        if v >= 0x100:
            out.add(v & 0xFFFFFF)
    for m in re.finditer(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', text):
        v = symtab(tag).get(m.group(1))
        if v is not None and v >= 0x100:
            out.add(v & 0xFFFFFF)
    return out


def source_block(tag):
    p = os.path.join(REPO, tag, "maincpu", "ui", "ui_control_panel.s")
    lines = open(p, encoding="latin-1").read().split("\n")
    i = next((k for k, l in enumerate(lines) if l.startswith(LABEL + ":")), None)
    if i is None:
        return None, None, None
    j = i + 1
    while j < len(lines) and not (lines[j] and lines[j][0] not in " \t;"):
        j += 1
    blk = lines[i:j]
    nbyte = sum(1 for l in blk if l.strip().startswith(".byte"))
    instr = [l.split(";")[0].strip() for l in blk[1:]
             if l.strip() and not l.strip().startswith(";")]
    return blk, nbyte, instr


def unidasm_at(tag, addr, nbytes):
    rom = open(os.path.join(REPO, "original_ROMs", TAGS[tag]), "rb").read()
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(rom[addr - BASE:addr - BASE + nbytes])
        path = f.name
    out = subprocess.run([UNI, path, "-arch", "tlcs900", "-basepc", hex(addr)],
                         capture_output=True, text=True).stdout
    os.unlink(path)
    rows = []
    for line in out.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            rows.append((int(m.group(1), 16), m.group(3).strip()))
    return rows


def main():
    rc = 0
    for tag in ("v10", "v9", "v7"):
        print(f"=== {tag} ===")
        a = symaddr(tag, LABEL)
        print(f"  {LABEL} = {a:06X}" if a else f"  {LABEL} NOT in symbols")
        print(f"  marker claims 0x{MARKER_ADDR:06x} is undecoded")
        if a != MARKER_ADDR:
            print(f"  ! MARKER ADDRESS DOES NOT MATCH THIS IMAGE "
                  f"({MARKER_ADDR:06X} vs {a:06X}) -- copied from another "
                  f"revision without re-deriving the address.")
        blk, nbyte, instr = source_block(tag)
        if blk is None:
            print("  no such label in this image's ui_control_panel.s")
            rc = 1
            continue
        print(f"  source block: {len(blk)} lines, {len(instr)} directives, "
              f"{nbyte} of them .byte")
        rows = unidasm_at(tag, a, 0xC0)
        n = min(len(instr), len(rows))
        src_addrs = operand_addrs(tag, " ".join(instr[:n]))
        dis_addrs = operand_addrs(tag, " ".join(r[1] for r in rows[:n]))
        common = src_addrs & dis_addrs
        print(f"  addresses named by the source block     : "
              f"{sorted(hex(x) for x in src_addrs)}")
        print(f"  addresses in unidasm's decode of the ROM: "
              f"{sorted(hex(x) for x in dis_addrs)}")
        print(f"  agreement: {len(common)}/{len(src_addrs)}")
        verdict = (nbyte == 0 and bool(src_addrs) and common == src_addrs)
        print(f"  VERDICT: "
              f"{'DECODED -- the marker is STALE' if verdict else 'not decoded here'}")
        if a == MARKER_ADDR and not verdict:
            rc = 1
        print()
    return rc


if __name__ == "__main__":
    sys.exit(main())
