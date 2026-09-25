#!/usr/bin/env python3
r"""Frame prom_a 0xFCF044-0xFCFDA6 (formerly `ModuleTables_FCF044`) by its READERS.

QUESTION THIS ANSWERS
    `ModuleTables_FCF044` was 3,427 bytes of `.byte` whose header said "not
    referenced by any `add Xrr,imm32` in prom_a or prom_b other than the two
    named above".  That is false: 44 instructions in prom_a and 11 in prom_b
    add a base inside it (`add XBC,0x00FCFxxx` / `add XIY,...`).  This script
    lists every one of them, derives each table's base, element size and count
    from its reader, checks that the tables TILE the span, and (with --apply)
    rewrites the span as typed tables with symbolic entries.

WHAT IT CHECKS BEFORE IT WILL WRITE ANYTHING
    * every reader site is found in the source at the address it claims, and
      its instruction text has the shape this script says it has (dispatch:
      `ld c,4 / m_mul (XIZ-4) / add XBC,base / ld XBC,(XBC) / ... / jp (xbc)`
      preceded by a call to PanelEvent_ToFieldIndex (0xFD7905, `call 16611589`
      in prom_b's spelling)); a single mismatch aborts;
    * the table extents tile 0xFCF044..0xFCFDA7 exactly, no gap, no overlap;
    * every prom_a handler address is the first byte of a statement line whose
      trailing byte comment equals the ROM (srcmap.py's guard), so a label
      placed there is on an instruction boundary; the byte gate then protects
      each label, because the table holds it as `.long <label>`;
    * the ROM bytes of every emitted line are re-read from the dump.

RUN
    make gate-wsa1                                                # builds the ELF srcmap reads
    python3 notes/proma-2026-09-25/gen_fcf044_tables.py           # dry run: the reader table
    python3 notes/proma-2026-09-25/gen_fcf044_tables.py --apply   # rewrite wsa1_prom_a.s
    make gate-wsa1
"""
import argparse
import bisect
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
WSA1 = os.path.join(ROOT, "wsa1")
PB_SRC = os.path.join(WSA1, "prom_b", "wsa1_prom_b.s")
PB_ELF = os.path.join(WSA1, "rebuilt_ROMs", "wsa1_prom_b.llvm.elf")
LO, HI = 0xFCF044, 0xFCFDA7
PANEL_OP_PRODUCER = 0xFD7905

# (base, kind, count, name, readers)  kind: op = 18 x LE32 handler table,
# ptr = LE32 handler table, b = byte table, w = LE16 table, pad = unread
SPECS = [
    (0xFCF044, "zero", 1, None, []),
    (0xFCF048, "b", 12, "KeyboardX_SemitoneOffset", [("a", 0xFD9450)]),
    (0xFCF054, "pad", 1, "Unread_FCF054", []),
    (0xFCF055, "w", 6, "FieldColumnX_ByIndex", [("a", 0xFD96FB)]),
    (0xFCF061, "b", 97, "NameChar_IndexToAscii", [("a", 0xFD7C73)]),
    (0xFCF0C2, "b", 130, "NameChar_AsciiToIndex", [("a", 0xFD7C9D)]),
    (0xFCF144, "b", 15, "IndexMap_FCF144", [("a", 0xFDA782)]),
    (0xFCF153, "b", 50, "IndexMap_FCF153", [("a", 0xFDA7E7)]),
    (0xFCF185, "b", 50, "IndexMap_FCF185", [("a", 0xFDA7BB)]),
    (0xFCF1B7, "b", 50, "IndexMap_FCF1B7", [("a", 0xFDA7FD)]),
    (0xFCF1E9, "b", 50, "IndexMap_FCF1E9", [("a", 0xFDA7D1)]),
]
OP_READERS = {
    0xFCF21B: [("a", 0xFD277E)], 0xFCF263: [("a", 0xFD27D6)], 0xFCF2AB: [("a", 0xFD2826)],
    0xFCF2F3: [("a", 0xFD2886)], 0xFCF33B: [("a", 0xFD28DF)],
    0xFCF383: [("b", 0xF0A02D)], 0xFCF3CB: [("b", 0xF0A085)], 0xFCF413: [("b", 0xF0A0E5)],
    0xFCF45B: [("b", 0xF0A13E)],
    0xFCF4A3: [("a", 0xFDE3F2)], 0xFCF4EB: [("a", 0xFDE452)], 0xFCF533: [("a", 0xFDE4B2)],
    0xFCF57B: [("a", 0xFDE512)], 0xFCF5C3: [("a", 0xFDE572)], 0xFCF60B: [("a", 0xFDE5CB)],
    0xFCF653: [("a", 0xFDE623)], 0xFCF69B: [("a", 0xFDE683)], 0xFCF6E3: [("a", 0xFDE6E3)],
    0xFCF72B: [("a", 0xFDE73C)],
    0xFCF773: [("a", 0xFD056A)], 0xFCF7BB: [("a", 0xFD05DE)],
}
OP_READERS2 = {
    0xFCF80C: [("a", 0xFD0AD2)], 0xFCF854: [("a", 0xFD0B23)], 0xFCF89C: [("a", 0xFD0B7B)],
    0xFCF8E4: [("a", 0xFD0BDB)], 0xFCF92C: [("a", 0xFD0C34)],
    0xFCF974: [("a", 0xFD3DD4)], 0xFCF9BC: [("a", 0xFD3E27)], 0xFCFA04: [("a", 0xFD3E78)],
    0xFCFA4C: [("a", 0xFD3EC9)], 0xFCFA94: [("a", 0xFD3F1A)], 0xFCFADC: [("a", 0xFD3F6B)],
    0xFCFB24: [("a", 0xFD3FBC)],
    0xFCFB6C: [("b", 0xF0A993)], 0xFCFBB4: [("b", 0xF0A9EC)],
    0xFCFBFC: [("b", 0xF0AA3D), ("b", 0xF0AA8E)], 0xFCFC44: [("b", 0xF0A93B)],
    0xFCFC8C: [("b", 0xF0AB26)],
}
TONE_PAGES = {0xFCF974: "A0", 0xFCF9BC: "A3", 0xFCFA04: "A4", 0xFCFA4C: "A5",
              0xFCFA94: "A6", 0xFCFADC: "A7", 0xFCFB24: "A8"}


def opname(b):
    # a table read by ToneEditPage_<page>_KeyDispatch is named after that page
    return ("ToneEditPage_%s_OpTable" % TONE_PAGES[b]) if b in TONE_PAGES else "PanelOpTable_%06X" % b


for b, r in sorted(OP_READERS.items()):
    SPECS.append((b, "op", 18, opname(b), r))
SPECS.append((0xFCF803, "b", 9, "BitMask_Bit0to7", [("a", 0xFD07E5)]))
for b, r in sorted(OP_READERS2.items()):
    SPECS.append((b, "op", 18, opname(b), r))
SPECS += [
    (0xFCFCD4, "b", 19, "IndexMap_FCFCD4", [("b", 0xF0C2AF)]),
    (0xFCFCE7, "ptr", 32, "ScreenCode80_Handlers", [("a", 0xFD2186), ("a", 0xFD22E4), ("a", 0xFD24B3)]),
    (0xFCFD67, "ptr", 16, "ScreenCodeC0_Handlers", [("a", 0xFD21B4), ("a", 0xFD2315), ("a", 0xFD24E1)]),
]
SIZE = {"zero": 4, "b": 1, "pad": 1, "w": 2, "op": 4, "ptr": 4}
NEWNAMES = {0xFD6C93: "PanelOp_Nop", 0xFD2013: "ScreenCode_Nop"}


def u8(s):
    """new text -> the latin-1 str whose latin-1 encoding is its UTF-8 bytes
    (the file is UTF-8 prose read 1:1 as latin-1; a str holding U+2605 would
    raise mid-write and truncate the file)."""
    return s.encode("utf-8").decode("latin-1")


def promb_syms():
    nm = subprocess.run([srcmap.NM, "--defined-only", PB_ELF], capture_output=True, text=True,
                        check=True).stdout
    by = {}
    for ln in nm.split("\n"):
        p = ln.split()
        if len(p) == 3 and not p[2].startswith((".L", "__")):
            by.setdefault(int(p[0], 16), []).append(p[2])
    return by


def enclosing(syms_sorted, addrs, a):
    i = bisect.bisect_right(addrs, a) - 1
    return syms_sorted[i]


def check_reader(m, pb_lines, pb_line_at, img, site, kind):
    """Return the reader's source lines (list of str), after asserting its shape."""
    if img == "a":
        i = m.line_of(site)
        assert i is not None, "no source line for prom_a reader 0x%06X" % site
        L = m.lines
    else:
        i = pb_line_at.get(site)
        assert i is not None, "no source line for prom_b reader 0x%06X" % site
        L = pb_lines
    here = L[i].split(";")[0].lower()
    assert "add" in here, (hex(site), L[i])
    if kind in ("op",):
        back = " ".join(x.split(";")[0].lower() for x in L[i - 3:i])
        assert "m_mul mbd+r6, 0xfc, 3" in back and "0x04:opc" in back.replace("4:opc", "0x04:opc"), \
            (hex(site), back)
        # walk back over statements to the producer call; between it and this
        # add there must be no return and no write to the op byte (XIZ-4)
        call_ok = False
        j, seen = i - 1, 0
        while j > 0 and seen < 40:
            x = L[j].split(";")[0].strip().lower()
            j -= 1
            if not x or x.endswith(":"):
                continue
            seen += 1
            if "panelevent_tofieldindex" in x or "16611589" in x:
                call_ok = True
                break
            assert not re.match(r'(ret|reti|unlk)\b', x), "return between producer and 0x%06X" % site
            assert not re.match(r'(ld|lda)\s+[^,]*\(xiz-4\)|lda\s+x\w+,\s*\(xiz-4\)', x), \
                "op byte rewritten before 0x%06X: %s" % (site, x)
        assert call_ok, "no PanelEvent_ToFieldIndex call before 0x%06X" % site
        fwd = " ".join(x.split(";")[0].lower() for x in L[i + 1:i + 6])
        assert "(xbc)" in fwd and "jp" in fwd, (hex(site), fwd)
    return L[i]


def build(m, pbs):
    rom = m.rom
    B = srcmap.BASE
    # tiling
    cur = LO
    for base, kind, n, name, _ in SPECS:
        assert base == cur, "gap/overlap at 0x%06X (expected 0x%06X)" % (base, cur)
        cur += SIZE[kind] * n
    assert cur == HI, "tiling ends at 0x%06X, not 0x%06X" % (cur, HI)
    # prom_b source line map (its comments carry `; ADDR  mnemonic`)
    pb_lines = open(PB_SRC, encoding="latin-1").read().split("\n")
    pb_line_at = {}
    for i, l in enumerate(pb_lines):
        mm = re.search(r';\s*([0-9A-F]{6})\s', l)
        if mm and not l.lstrip().startswith(";"):
            pb_line_at.setdefault(int(mm.group(1), 16), i)
    a_syms = sorted((a, n) for a, ns in m.by_addr.items() for n in ns
                    if not n.startswith((".L", "__")))
    a_addrs = [a for a, _ in a_syms]
    b_syms = sorted((a, n[0]) for a, n in pbs.items())
    b_addrs = [a for a, _ in b_syms]
    newlabels = {}
    for k in range(17):                      # DispatchTable_FCF000's own entries
        w = int.from_bytes(rom[0xFCF000 - B + 4 * k: 0xFCF000 - B + 4 * k + 4], "little")
        if not m.best_label(w) and w not in newlabels:
            assert m.line_of(w) is not None, "handler 0x%06X is not a guarded statement start" % w
            newlabels[w] = NEWNAMES.get(w, "sub_%06X" % w)
    readers_txt = {}
    for base, kind, n, name, rd in SPECS:
        out = []
        for img, site in rd:
            check_reader(m, pb_lines, pb_line_at, img, site, kind)
            if img == "a":
                who = enclosing(a_syms, a_addrs, site)[1]
            else:
                who = enclosing(b_syms, b_addrs, site)[1] + " (prom_b)"
            out.append((who, site))
        readers_txt[base] = out
        if kind in ("op", "ptr"):
            for k in range(n):
                w = int.from_bytes(rom[base - B + 4 * k: base - B + 4 * k + 4], "little")
                if w >= 0xF80000 and not m.best_label(w) and w not in newlabels:
                    li = m.line_of(w)
                    assert li is not None, "handler 0x%06X is not a guarded statement start" % w
                    newlabels[w] = NEWNAMES.get(w, "sub_%06X" % w)
    return readers_txt, newlabels


def label_for(m, pbs, newlabels, w):
    if w == 0:
        return None, None
    if w >= 0xF80000:
        return (NEWNAMES.get(w) or m.best_label(w) or newlabels[w]), None
    nm = pbs.get(w, ["?"])[0]
    return None, nm


def emit(m, pbs, readers_txt, newlabels):
    rom = m.rom
    B = srcmap.BASE
    O = []

    def rd(base):
        return "; Read by: " + "; ".join("%s at 0x%06X" % (w, s) for w, s in readers_txt[base])

    OPHDR = """; ---------------------------------------------------------------------
; ★ THE 72-BYTE HANDLER TABLES (38 of them, plus DispatchTable_FCF000 above).
;   Every reader has one shape:
;       call PanelEvent_ToFieldIndex(event, flags, &op, &flag)  ; 0xFD7905
;       cp WA,0xFFFF / jr z, skip
;       ld C,4 / mul BC,(XIZ-4) / add XBC,<table> / ld XBC,(XBC)
;       push <return> / jp (XBC)             ; a computed CALL of slot `op`
;   PanelEvent_ToFieldIndex returns WA=0 only after storing `op` in 0..16:
;   event 0x00-0x10 -> op = event; 0x11-0x18 -> op = event-0x11 (and it sets
;   the flag byte's bit 7); 0x19 -> op = 0x10; every other event returns 0xFFFF
;   and the reader skips the dispatch.  So 17 slots are BOUND BY THE PRODUCER;
;   each table's 18th word is 0x00000000, which no reader can index.
;   PanelOp_Nop (0xFD6C93, a lone `ret`) fills the slots a field does not
;   handle.  Which field each table serves is the reader's; what the 17
;   operations mean is not established here.
; ---------------------------------------------------------------------""".split("\n")
    NA = sum(1 for sp in SPECS for img, _ in sp[4] if img == "a")
    NB = sum(1 for sp in SPECS for img, _ in sp[4] if img == "b")
    O += ("""; ---------------------------------------------------------------------
; 0xFCF044-0xFCFDA6 -- THE MODULE'S TABLES, FRAMED BY THEIR READERS (3,427 B)
;
; This span was `ModuleTables_FCF044`, whose header said nothing in prom_a or
; prom_b adds a base inside it.  %d instructions do: %d `add XBC/XIY,0x00FCFxxx`
; in this module's own code and %d `add XBC,0x00FCFxxx` in prom_b (spelled as
; decimal immediates there).  Every table below is named by at least one of
; them, its element size and count come from that reader, and together they
; tile the span with no gap -- which is the independent check on every count.
; Regenerate / re-check: notes/proma-2026-09-25/gen_fcf044_tables.py (repo root).
;
; ---------------------------------------------------------------------""" % (NA + NB, NA, NB)).split("\n")
    for base, kind, n, name, _ in SPECS:
        if kind == "zero":
            O += ["; ModuleTables_FCF044 is KEPT as a label for the span's first byte because",
                  "; wsa1/notes/FINDINGS-prom_a-fcf000-module.md and",
                  "; wsa1/notes/prom_a_fcf000_checks.py name it.  Its first word is the",
                  "; zero word that ends DispatchTable_FCF000 -- the 18th word every handler",
                  "; table of this module has (see PanelOpTable_FCF21B's header).",
                  "ModuleTables_FCF044:",
                  "\t.long 0x00000000%s; FCF044  [17] zero, DispatchTable_FCF000's 18th word"
                  % (" " * 30)]
            continue
        O.append("")
        if kind == "b" and name == "KeyboardX_SemitoneOffset":
            O += ["; KeyboardX_SemitoneOffset -- 12 bytes: the x offset, in pixels, of each",
                  "; semitone C..B within one octave of a drawn keyboard: C 0, C# 2, D 4, D# 6,",
                  "; E 8, F 12, F# 14, G 16, G# 18, A 20, A# 22, B 24 (white keys 4 apart).",
                  rd(base) + " (the one add of 0x00FCF048 in prom_a or",
                  ";          prom_b).  sub_FD9414(note, &x)",
                  ";          clamps note to 20..108, then x = 28*((note-12)/12)",
                  ";          + this[(note-12)%12] - 18: 28 = 7 white keys x 4 px per octave.",
                  ";          COUNT 12 = the `div C,0x0C` remainder range."]
        elif kind == "pad":
            O += ["; Unread_FCF054 -- one byte, 0x00, between the two tables that bracket it.",
                  "; No reader is known (no add/ld of 0x00FCF054 in prom_a or prom_b); it is",
                  "; not claimed as part of either neighbour."]
        elif kind == "w":
            O += ["; FieldColumnX_ByIndex -- 6 x LE16: 0, 97, 128, 159, 190, 0 -- pixel x",
                  "; positions 31 apart for indices 1..4, zero at both ends.",
                  rd(base) + ": `ld C,2 / mul BC,(XIZ+0x0A)",
                  ";          / add XBC,0x00FCF055 / ld DE,(XBC)`; DE is then the x passed to",
                  ";          the draw call at 0xFD9721 (as DE-20).  COUNT 6 is the extent to the",
                  ";          next reader-named base, 0xFCF061; the reader has no bound of its",
                  ";          own (sub_FD6C34 vets the index first).  Which fields: not established."]
        elif name == "NameChar_IndexToAscii":
            O += ["; NameChar_IndexToAscii -- 97 bytes: character-set INDEX -> ASCII.  0 is",
                  "; a space, 1-26 'A'-'Z', 27-52 'a'-'z', 53-62 '0'-'9', then punctuation,",
                  "; 0x7F and '<>[]{}'; index 96 is 0x00.",
                  rd(base) + ": sub_FD7C5A(index, &out): out = index < 0x61 ?",
                  ";          this[index] : ' '.  COUNT 97 = that bound, `cp (XIZ+8),0x61`.",
                  "; ★ It is the exact inverse of NameChar_AsciiToIndex below, checked for",
                  ";   all 96 characters by gen_fcf044_tables.py -- so the pair is the",
                  ";   ordered alphabet a name editor steps through, and its inverse."]
        elif name == "NameChar_AsciiToIndex":
            O += ["; NameChar_AsciiToIndex -- 130 bytes: ASCII code -> character-set index,",
                  "; the inverse of NameChar_IndexToAscii (0 for codes not in the set).",
                  rd(base) + ": sub_FD7C83(code, &out): out = code < 0x82 ?",
                  ";          this[code] : 0, then replaces a result above 0x5F with 0 (so",
                  ";          valid indices are 0..95).  COUNT 130 = the bound `cp (XIZ+8),0x82`."]
        elif kind == "b" and name.startswith("IndexMap_"):
            fn = {0xFCF144: "sub_FDA777(i, &out): out = this[i]",
                  0xFCF153: "sub_FDA7DC(i): A = this[i]", 0xFCF185: "sub_FDA7B0(i): A = this[i]",
                  0xFCF1B7: "sub_FDA7F2(i): A = this[i]", 0xFCF1E9: "sub_FDA7C6(i): A = this[i]",
                  0xFCFCD4: "sub_F0C291 (prom_b): A = this[v], v from call 0xFD6C7B(3, &v)"}[base]
            O += ["; %s -- %d bytes, a byte-to-byte map (values 0x%02X..0x%02X)." % (
                name, n, min(rom[base - B:base - B + n]), max(rom[base - B:base - B + n])),
                rd(base) + ": " + fn + ".",
                ";          COUNT %d is the extent to the next reader-named base; the reader" % n,
                ";          has no bound.  What the index and the values denote: not established."]
        elif name == "BitMask_Bit0to7":
            O += ["; BitMask_Bit0to7 -- 9 bytes: 1<<0 .. 1<<7, then 0x00.",
                  rd(base) + ": `ld C,H / add XBC,0x00FCF803 / ld A,(XBC)` with",
                  ";          H forced into 0..5 just before (`cp H,6 / jr c` else H = 0), so",
                  ";          this reader uses entries 0-5 only.  Entries 6-8 (0x40, 0x80, 0x00)",
                  ";          complete the 8-bit ladder and a zero; no other reader is known."]
        elif kind == "op":
            if base == 0xFCF21B:
                O += OPHDR
            O += ["; %s -- 17 handler addresses + the zero word (72 bytes), one per" % name,
                  "; panel operation 0..16; see the block header for the reader shape.",
                  rd(base) + "."]
        elif name == "ScreenCode80_Handlers":
            O += ["; ScreenCode80_Handlers -- 32 handler addresses for screen codes 0x80-0x9F.",
                  rd(base) + ": `cp (0x207C),0x80 / jr c` + `cp (0x207C),",
                  ";          0xA0 / jr nc` bound the code, then `ld C,4 / mul BC,(0x207C) /",
                  ";          sub XBC,0x200 / add XBC,0x00FCFCE7 / ld XBC,(XBC) / push <ret> /",
                  ";          jp (XBC)`.  COUNT 32 is that bound.  (0x207C) holds the screen code."]
        elif name == "ScreenCodeC0_Handlers":
            O += ["; ScreenCodeC0_Handlers -- 16 handler addresses for screen codes 0xC0-0xCF.",
                  rd(base) + ": the same shape as ScreenCode80_Handlers with",
                  ";          bounds 0xC0/0xD0 and `sub XBC,0x300`.  COUNT 16 is that bound.",
                  ";          Entry 3 is ToneEditPage_A3_PositionParameter, whose own header",
                  ";          says Dispatch_Code80 makes 0xC0+k the same entry as 0xA0+k."]
        O.append("%s:" % name)
        # body
        if kind in ("b", "pad"):
            data = rom[base - B: base - B + n]
            if name == "NameChar_IndexToAscii":
                for r in range(0, n, 16):
                    chunk = data[r:r + 16]
                    O.append("\t.byte %s  ; %06X  [%3d] %s" % (
                        ", ".join("0x%02x" % x for x in chunk), base + r, r,
                        "".join(chr(x) if 0x20 <= x < 0x7F else "." for x in chunk)))
            else:
                for r in range(0, n, 16):
                    chunk = data[r:r + 16]
                    O.append("\t.byte %s  ; %06X  [%3d]" % (
                        ", ".join("0x%02x" % x for x in chunk), base + r, r))
        elif kind == "w":
            for k in range(n):
                v = int.from_bytes(rom[base - B + 2 * k: base - B + 2 * k + 2], "little")
                O.append("\t.short %-36d; %06X  [%d]" % (v, base + 2 * k, k))
        else:
            cnt = 17 if kind == "op" else n
            for k in range(cnt):
                w = int.from_bytes(rom[base - B + 4 * k: base - B + 4 * k + 4], "little")
                lab, pbn = label_for(m, pbs, newlabels, w)
                if lab:
                    O.append("\t.long %-40s; %06X  [%2d]" % (lab, base + 4 * k, k))
                else:
                    O.append("\t.long 0x%08x%s; %06X  [%2d] prom_b %s" % (
                        w, " " * 30, base + 4 * k, k, pbn))
            if kind == "op":
                w = int.from_bytes(rom[base - B + 68: base - B + 72], "little")
                assert w == 0, (hex(base), hex(w))
                O.append("\t.long 0x00000000%s; %06X  [17] zero" % (" " * 30, base + 68))
    return O


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = srcmap.load()
    pbs = promb_syms()
    readers_txt, newlabels = build(m, pbs)
    rom = m.rom
    B = srcmap.BASE
    # the inverse-map check the header quotes
    i2a = rom[0xFCF061 - B: 0xFCF061 - B + 97]
    a2i = rom[0xFCF0C2 - B: 0xFCF0C2 - B + 130]
    bad = [k for k in range(96) if a2i[i2a[k]] != k]
    assert not bad, "inverse check fails at %s" % bad
    print("tiling 0x%06X-0x%06X: OK, %d objects" % (LO, HI, len(SPECS)))
    print("NameChar inverse check: 96/96")
    for base, kind, n, name, _ in SPECS:
        print("  0x%06X %-5s x%-3d %-28s %s" % (base, kind, n, name or "(DispatchTable_FCF000 slot 17)",
              ", ".join("%s@%06X" % w for w in readers_txt[base])))
    print("new code labels: %d" % len(newlabels))
    if not a.apply:
        return
    O = [u8(x) for x in emit(m, pbs, readers_txt, newlabels)]
    L = m.lines
    # 1. the block: from the header rule above `; ModuleTables_FCF044 --` to the line before sub_FCFDA7
    h = next(i for i, l in enumerate(L) if l.startswith("; ModuleTables_FCF044 -- 3,427 bytes"))
    assert L[h - 1].startswith("; -----")
    e = next(i for i in range(h, len(L)) if L[i].startswith("sub_FCFDA7:"))
    # 2. DispatchTable_FCF000 entries (above the block) and its zero slot
    d0 = next(i for i, l in enumerate(L) if l.startswith("DispatchTable_FCF000:"))
    newL = []
    for i, l in enumerate(L):
        if h - 1 <= i < e:
            if i == h - 1:
                newL += O
                newL.append("")
            continue
        if d0 < i < d0 + 18:
            mm = re.match(r'\t\.long 0x00([0-9a-f]{6})\s+; (FCF0[0-4][0-9A-F]  \[\s*\d+\])', l)
            if mm:
                w = int(mm.group(1), 16)
                lab = NEWNAMES.get(w) or m.best_label(w) or newlabels[w]
                l = "\t.long %-40s; %s" % (lab, mm.group(2))

        newL.append(l)
    # 2b. the two pieces of prose above the block that describe it
    FIXES = [
        (";   0xFCF044  3,427 bytes of tables -- see ModuleTables_FCF044 below",
         ";   0xFCF044  3,427 bytes of tables -- framed by their readers below\n"
         ";             (this span was `ModuleTables_FCF044` until 2026-09-25)"),
        ("; Unknown:  what the seventeen operations are.\n; ---------------------------------------------------------------------\nDispatchTable_FCF000:",
         "; Unknown:  what the seventeen operations are.\n"
         "; ⚠ CORRECTION 2026-09-25 (lane proma): the count IS bound, one step\n"
         ";          removed.  The reader, sub_FCFDA7, first calls\n"
         ";          PanelEvent_ToFieldIndex (0xFD7905), which returns WA=0 only after\n"
         ";          storing an operation in 0..16 at (XIZ-4) -- the byte this reader\n"
         ";          multiplies -- and the reader skips the dispatch on 0xFFFF.  And\n"
         ";          word 17 (0xFCF044), 0x00000000, is not the start of another table:\n"
         ";          it is the zero word that ends all 38 tables of this shape framed below.\n"
         "; ---------------------------------------------------------------------\n"
         "DispatchTable_FCF000:"),
    ]
    blob = "\n".join(newL)
    for o, n in FIXES:
        assert blob.count(o) == 1, o[:60]
        blob = blob.replace(o, u8(n))
    newL = blob.split("\n")
    # 3. insert code labels (by guarded address comment), bottom-up
    text = newL
    idx = {}
    for i, l in enumerate(text):
        mm = srcmap.ADDR.search(l)
        if mm and not l.lstrip().startswith((";", ".")):
            ad = int(mm.group(1), 16)
            bs = mm.group(2).split()
            if bs and bytes(int(x, 16) for x in bs) == rom[ad - B: ad - B + len(bs)]:
                idx.setdefault(ad, i)
    ins = sorted(((idx[w], w) for w in newlabels), reverse=True)
    renames = {}
    for li, w in ins:
        tabs = sorted({b for b, k, n, nm, _ in SPECS if k in ("op", "ptr")
                       for j in range(17 if k == "op" else n)
                       if int.from_bytes(rom[b - B + 4 * j: b - B + 4 * j + 4], "little") == w})
        names = [nm for b, k, n, nm, _ in SPECS if b in tabs]
        if w in (0xFCFE42,) or any(True for _ in []):
            pass
        ev = "; %s -- a handler: an entry of %s" % (
            newlabels[w], ", ".join(names) if names else "DispatchTable_FCF000")
        if w == 0xFD6C93:
            ev = ("; PanelOp_Nop -- a lone `ret`: the slot every PanelOpTable_* (and\n"
                  "; DispatchTable_FCF000) uses for an operation its field does not handle.")
        elif w == 0xFD2013:
            ev = ("; ScreenCode_Nop -- a lone `ret`: the entry ScreenCode80_Handlers and\n"
                  "; ScreenCodeC0_Handlers use for a screen code with no handler.")
        loc = [x for x in m.labels_at(w) if x.startswith(".L")]
        if loc:                              # a structural .L label is already there: rename it
            renames[loc[0]] = newlabels[w]
            text[li:li] = [u8(x) for x in ev.split("\n")]
        else:
            text[li:li] = [u8(x) for x in ev.split("\n")] + ["%s:" % newlabels[w]]
    if renames:
        pat = re.compile(r"(?<![\w.$])(" + "|".join(re.escape(k) for k in renames) + r")(?![\w.$])")
        text = [pat.sub(lambda mm: renames[mm.group(1)], l) for l in text]
    # DispatchTable_FCF000 targets that were not in SPECS get the same treatment
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(text))
    print("applied: block %d -> %d lines; %d labels inserted, %d .L labels renamed"
          % (e - h + 1, len(O), len(ins) - len(renames), len(renames)))


if __name__ == "__main__":
    main()
