#!/usr/bin/env python3
"""Emit prom_a 0xF8A000-0xF8BBFF -- the PANEL WIRE-to-GROUP module -- as assembly.

QUESTION IT ANSWERS
  "Where is the panel's wire-address to group map, and what does the rest of its
   module look like?"

★ WHY THIS SPAN AND NOT ANOTHER: it is the one prom_a `.incbin` that
  kn7000_mame's `notes/WSA1-EMULATION-DISASM-GAPS.md` names in its gap-O
  section -- "0xF8A109 / 0xF8A189 -- the panel's wire-address to group map,
  eleven button segments and four pots for variant 1 against nine segments and
  one pot for variant 2".  Converting it puts that map, and the INDEX FUNCTION
  that reaches it, in the source instead of in a note.

★ THE INDEX FUNCTION, read off the reader at 0xF8A09C-0xF8A0C2 and not guessed:

      A  = the wire byte, taken from the panel receive ring at RAM 0x2B40
      L  = A & 0x1F                       (0xF8A0A3)
      A  = (A & 0xC0) >> 1                (0xF8A0A6, 0xF8A0A9)
      L |= A                              (0xF8A0AC)   -- index = 7 bits
      XIY = 0x00F8A109                    (0xF8A0AE)   -- variant 1
      if (0xC4) != 1: XIY = 0x00F8A189    (0xF8A0B3-0xF8A0BE) -- variant 2
      L = (XIY + L)                       (0xF8A0BE)   -- the GROUP id

  so `index = (wire & 0x1F) | ((wire & 0xC0) >> 1)`, bit 5 of the wire is
  DROPPED, and each map is 128 bytes.  0x20 means "no group".
  Worked examples the --check mode asserts: wire 0xC0 -> index 0x60 -> group 0,
  wire 0xD3 -> index 0x73 -> group 0x0E, wire 0xD7 -> index 0x77 -> group 0x0F.
  (0xD7 is the DATA ENTRY DIAL of gap Q; 0xD3 is the pot variant 2 keeps.)

RUN
  python3 notes/gen_prom_a_f8a000_module.py > /tmp/region.s
  python3 prom_a/insert_region.py 0xF8A000 0xF8BC00 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
  python3 notes/gen_prom_a_f8a000_module.py --check
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import roundtrip as RT                                          # noqa: E402
import prom_a_ringbuf_map as MAP                                # noqa: E402
from gen_prom_a_block import (bytes_block, longs_block, fill,    # noqa: E402
                              decode_region, emit, load_headers)

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
LO, HI = 0xF8A000, 0xF8BC00
PAD = 0xF8BBB4


def rd(a, n=1):
    return ROM[a - BASE:a - BASE + n]


def group(wire, variant=1):
    idx = (wire & 0x1F) | ((wire & 0xC0) >> 1)
    return rd((0xF8A109 if variant == 1 else 0xF8A189) + idx)[0]


H = "; ---------------------------------------------------------------------\n"


def wiremap_header(base, variant, sibling):
    # the index is 7 bits by construction, so every wire hits the map; the only
    # filter that matters is "this entry is not the 0x20 no-group marker".
    live = [w for w in range(0x100) if group(w, variant) != 0x20]
    # a wire and wire|0x20 share an index, so report the canonical (bit-5-clear) form
    canon = sorted({w & ~0x20 for w in live})
    rows = "\n".join(
        ";     wire 0x%02X -> group 0x%02X" % (w, group(w, variant)) for w in canon)
    return (H +
            "; PanelWireGroupMap_Variant%d -- 128 bytes, wire address -> group id\n"
            % variant +
            "; Read by: 0xF8A0BE `ld A,(XIY+L)` with XIY = 0x%06X, loaded at\n" % base +
            ";          0x%06X.  The other arm loads 0x%06X; `cp (0xC4),0x01` at\n"
            % (0xF8A0AE if variant == 1 else 0xF8A0B9, sibling) +
            ";          0xF8A0B3 picks between them -- (0xC4) is the MODEL STRAP\n"
            ";          (prom_a 0xF82882 reads PB bit 0 into it).\n"
            "; INDEX:   (wire & 0x1F) | ((wire & 0xC0) >> 1), computed at\n"
            ";          0xF8A0A3-0xF8A0AC.  Bit 5 of the wire is DROPPED, so wire\n"
            ";          W and W|0x20 read the same entry.\n"
            "; ENTRY COUNT 128 is the index width: the expression above cannot\n"
            ";          exceed 0x7F, and 0x%06X is where the sibling map starts.\n" % (base + 0x80) +
            "; 0x20 means NO GROUP -- %d of the 128 entries are 0x20.\n"
            % sum(1 for i in range(0x80) if rd(base + i)[0] == 0x20) +
            "; The wires this variant answers to:\n" + rows + "\n" +
            "; ⚠ What a GROUP id then selects is NOT established here.\n" + H)


TABLES = [
    (0xF8A05F, 0xF8A06F, "long", "Dispatch_F8A05F", H +
     "; Dispatch_F8A05F -- 4 routine pointers\n"
     "; Read by: 0xF8A052 `ld XIY,0x00F8A05F` after `sla L,2`, then\n"
     ";          `ld XWA,(XIY+HL) / call (XWA)` at 0xF8A057-0xF8A05C.\n"
     "; ⚠ ENTRY COUNT 4 is the EXTENT -- 0xF8A06F is the `ret` that ends the\n"
     ";          previous routine's fall-through and code resumes at 0xF8A070.\n"
     ";          There is no compare on L at the call site, so this is weaker\n"
     ";          than a bound.\n"
     "; Contents: 0xF8A070, 0xF8A05E, 0xF8A070, 0xF8A05E -- two distinct arms,\n"
     ";          and 0xF8A05E is the bare `ret` one instruction above the table,\n"
     ";          i.e. slots 1 and 3 are DO NOTHING.\n" + H),
    (0xF8A109, 0xF8A189, "byte", "PanelWireGroupMap_Variant1", None),
    (0xF8A189, 0xF8A209, "byte", "PanelWireGroupMap_Variant2", None),
    (0xF8B325, PAD, "byte", "PanelTables_F8B325", H +
     "; PanelTables_F8B325 -- 2,191 bytes of tables.  PARTLY decoded.\n"
     ";\n"
     "; It is DATA, not code, and the test is a decode: a linear disassembly\n"
     "; from 0xF8B325 produces 176 bytes llvm-mc cannot spell in 2 KiB, against\n"
     "; 19 in the 4.6 KiB of code around it, and the run at 0xF8B812 -- which a\n"
     "; pointer table below points AT -- disassembles as `nop / normal /\n"
     "; ld XDE,0x0000f8ab`, which is what a 6-byte record looks like when it is\n"
     "; decoded as instructions.\n"
     ";\n"
     "; WHAT IS FRAMED, each by an `ld XIX/XIY,imm32` in the code above:\n"
     ";   0xF8B325  33 bytes  0x00..0x1F then 0xFF -- an identity map with a\n"
     ";             terminator.  Loaded at 0xF8B2EE and 0xF8B30F.\n"
     ";   0xF8B346  32 x LE32 RAM pointers, 0x000076A2 step 0x40 -- the SAME\n"
     ";             RAM records RecordPtrs_RAM76A2 (0xFEB330) points into.\n"
     ";   0xF8B3C6  32 x LE32, the same records at +0x20.  Loaded at 0xF8AA31.\n"
     ";   0xF8B446  27 x LE32 into this module.  Loaded at 0xF8A84C; the\n"
     ";             sibling 0xF8B4B2 is loaded at 0xF8A857, 108 bytes later.\n"
     ";   0xF8B51E  4-byte records terminated by 0xFF -- lists, not an array.\n"
     ";   0xF8B74A  25 x LE32 list heads.  Loaded at 0xF8A8CC; the sibling\n"
     ";             0xF8B7AE is loaded at 0xF8A8D7, 100 bytes later.\n"
     ";   0xF8B812  6-byte records, `<u16> <LE32>`, terminated by 0xFF 0xFF --\n"
     ";             the lists the 0xF8B74A table points at.\n"
     ";\n"
     "; ⚠ WHAT IS NOT: what any of it MEANS, and where each sub-table ends.\n"
     ";   The boundaries above come from the loads and from the 0xFF sentinels,\n"
     ";   not from a bound in a reader, so the block is emitted as ONE `.byte`\n"
     ";   region rather than as seven objects with invented extents.  Splitting\n"
     ";   it is the next pass's job and it needs the readers traced, not the\n"
     ";   bytes stared at.\n" + H),
]

MODULE_BANNER = """
; ==============================================================================
; 0xF8A000-0xF8BBFF -- the PANEL WIRE-to-GROUP module
; ==============================================================================
;
; ★★ THIS IS WHERE THE PANEL'S WIRE ADDRESSES BECOME GROUP IDS, and it is the
; span kn7000_mame's gap O points at.  Two 128-byte maps, one per model variant,
; selected by the (0xC4) strap, indexed by
;     (wire & 0x1F) | ((wire & 0xC0) >> 1)
; -- see PanelWireGroupMap_Variant1's header for where every term of that comes
; from.  Variant 1 answers to eleven button wires (0xC0-0xCA) plus four
; continuous ones (0xD0-0xD3) plus the dial (0xD7); variant 2 answers to nine
; button wires (0xC0-0xC5, 0xC7-0xC9) plus 0xD3 and 0xD7.  Both lists are
; printed by `python3 notes/gen_prom_a_f8a000_module.py --check`, which reads
; them out of the ROM rather than out of this comment.
;
; The rest of the module is the panel event loop that walks the receive ring at
; RAM 0x2B40 and dispatches on the group, plus 2,191 bytes of tables at
; 0xF8B325 that are framed but not decoded.
;
; ⚠ Every routine here is `sub_XXXXXX`.  This pass converted the module and
; decoded ONE object in it.
; ==============================================================================
"""


def main():
    tables = []
    for lo, hi, kind, nm, hdr in TABLES:
        if hdr is None:
            v = 1 if lo == 0xF8A109 else 2
            hdr = wiremap_header(lo, v, 0xF8A189 if v == 1 else 0xF8A109)
        tables.append((lo, hi, kind, nm, hdr))
    gaps, at = [], LO
    for a, b, *_ in tables:
        if a > at:
            gaps.append((at, a))
        at = b

    if "--check" in sys.argv:
        print("tables: %d, %d bytes" % (len(tables), sum(b - a for a, b, *_ in tables)))
        print("code gaps: %d, %d bytes" % (len(gaps), sum(b - a for a, b in gaps)))
        bad = []
        for a, b in gaps:
            rows, at2 = [], a
            while at2 < b:                       # chunked: see prom_a_span_survey
                rs = RT.convert(at2, min(at2 + 0x800, b))[0]
                if not rs:
                    break
                rows += rs
                at2 = rs[-1][0] + len(rs[-1][1])
            bad += [r[0] for r in rows if r[3] == "byte"]
        print("rows llvm-mc could not spell: %d %s"
              % (len(bad), ["%06X" % a for a in bad]))
        # the index function, on the wires the gaps note names
        for w, want1, want2 in ((0xC0, 0x00, 0x00), (0xCA, 0x0A, 0x20),
                                (0xD0, 0x0B, 0x20), (0xD3, 0x0E, 0x0E),
                                (0xD7, 0x0F, 0x0F)):
            g1, g2 = group(w, 1), group(w, 2)
            print("  wire 0x%02X  index 0x%02X  variant1 group 0x%02X  "
                  "variant2 group 0x%02X"
                  % (w, (w & 0x1F) | ((w & 0xC0) >> 1), g1, g2))
            if (g1, g2) != (want1, want2):
                sys.exit("REFUSED: wire 0x%02X does not map as documented" % w)
        for v, want in ((1, 16), (2, 11)):
            live = sorted({w & ~0x20 for w in range(0x100)
                           if group(w, v) != 0x20})
            print("  variant %d answers to %d wires: %s"
                  % (v, len(live), " ".join("%02X" % w for w in live)))
            if len(live) != want:
                sys.exit("REFUSED: variant %d has %d live wires, not %d"
                         % (v, len(live), want))
        if rd(0xF8A0A3, 3) != b"\xcf\xcc\x1f" or rd(0xF8A0A6, 3) != b"\xc9\xcc\xc0" \
           or rd(0xF8A0A9, 3) != b"\xc9\xef\x01":
            sys.exit("REFUSED: the index function's three instructions are not "
                     "`and L,0x1F / and A,0xC0 / srl A,1`")
        print("  index function bytes at 0xF8A0A3/A6/A9 are exactly "
              "`and L,0x1F`, `and A,0xC0`, `srl A,1`")
        if set(rd(PAD, HI - PAD)) != {0x0E}:
            sys.exit("REFUSED: 0x%06X-0x%06X is not uniform 0x0E" % (PAD, HI))
        print("  pad 0x%06X-0x%06X: %d bytes, all 0x0E" % (PAD, HI - 1, HI - PAD))
        return 0

    hdr, semantic, _ = load_headers()
    refs = MAP.all_refs()
    thunks = MAP.thunk_targets()
    named = {t for t, sites in refs.items()
             if LO <= t < HI
             and any(k in ("call", "jp", "calr") for k, _ in sites)}
    named |= {t for t in thunks if LO <= t < HI}
    named.add(LO)
    labels = {a: semantic.get(a, "sub_%06X" % a) for a in named}
    emitted = set()
    for a, b in gaps:
        emitted |= decode_region(a, b)[1]
    labels = {a: n for a, n in labels.items() if a in emitted}

    out, at = [MODULE_BANNER], LO
    for a, b, kind, nm, h in tables:
        if a > at:
            out += emit(at, a, labels, hdr)[0]
        out += (longs_block if kind == "long" else bytes_block)(a, b, nm, h)
        at = b
    out += fill(PAD, HI)
    text = "\n".join(out)
    used = set(re.findall(r"\b(sub_[0-9A-F]{6})\b", text))
    defined = set(re.findall(r"^(sub_[0-9A-F]{6}):", text, re.M))
    defined |= set(re.findall(r"^(sub_[0-9A-F]{6}):",
                              open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"),
                                   encoding="utf-8").read(), re.M))
    if used - defined:
        sys.exit("REFUSED: %d label(s) referenced but never defined: %s"
                 % (len(used - defined), ", ".join(sorted(used - defined))))
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
