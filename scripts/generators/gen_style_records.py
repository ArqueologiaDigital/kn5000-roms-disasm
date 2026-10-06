#!/usr/bin/env python3
"""Generate the Music Stylist preset-record assembly (package w2-style-records).

Reads the original KN5000 table-data ROM and emits two .s fragments:

  style_records.s           ROM [0x951000, 0x983B3A) - the 1000 Music Stylist
                            preset records (StyleRec_000..StyleRec_999, 250
                            styles x 4 arrangements) plus the unreferenced
                            residue after the record grid, including the
                            16-bit ramp remnant at 0x983557.
  style_record_ptr_tables.s ROM [0x986000, 0x988000) - the two 1000-entry
                            pointer tables that maincpu indexes by UI state
                            (StyleRec_PtrTable_CategoryOrder / StyleRec_PtrTable_Default),
                            emitted as symbolic .long StyleRec_NNN entries,
                            plus the 96-byte leftover residue of each 4KB page.

The OUTPUT files are the authoritative sources; this script is the one-time
generator kept for provenance.  It verifies every structural invariant it
relies on and byte-verifies its own output against the ROM before writing.
"""
import os
import re
import struct

_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(_REPO, "original_ROMs", "kn5000_table_data.rom")
OUT_RECORDS = "style_records.s"            # written to the current directory
OUT_PTRTABLES = "style_record_ptr_tables.s"

BASE = 0x800000
REC_BASE = 0x951000
REC_SIZE = 198          # grid stride; dword @+0 says 197 (one uncommitted pad byte)
N_RECORDS = 1000
GRID_END = REC_BASE + N_RECORDS * REC_SIZE      # 0x981570
RAMP_LO = 0x983557
MODULE_END = 0x983B3A                            # HelpDB_German_Stale starts here
TBL_C2C5 = 0x986000
TBL_DEFAULT = 0x987000
TBL_ENTRIES = 1000
TBL_RESIDUE = 96        # bytes left of each 4KB page after the 1000 entries
BLOB_BASE = 0x944D78    # table_data/includes/icons_to_strings.bin ROM base

rom = open(ROM_PATH, "rb").read()

def rd(addr, n):
    return rom[addr - BASE:addr - BASE + n]

# ---- extract + verify the records --------------------------------------------
recs = [rd(REC_BASE + REC_SIZE * r, REC_SIZE) for r in range(N_RECORDS)]
for r, d in enumerate(recs):
    assert struct.unpack_from("<I", d, 0)[0] == 197, r    # record byte count
    assert struct.unpack_from("<I", d, 4)[0] == 77, r     # parameter-block offset
    assert all(0x20 <= b < 0x7F for b in d[8:24]), r      # category name
    assert all(0x20 <= b < 0x7F for b in d[24:40]), r     # style name
    assert struct.unpack_from("<H", d, 40)[0] == 1, r
    assert d[42] == 32, r                                 # display-string length
    assert all(0x20 <= b < 0x7F for b in d[43:72]), r     # arrangement name
    assert re.fullmatch(rb"[ \d]\d\d", d[72:75]), r       # tempo, right-aligned
    assert d[75] == 0 and d[76] == 0, r
    assert d[192:197] == b"\xff" * 5, r
    assert b'"' not in d[8:72] and b"\\" not in d[8:72], r

# 250 styles x 4 arrangements sharing the category/style name fields
for g in range(N_RECORDS // 4):
    for i in range(1, 4):
        assert recs[4 * g + i][8:40] == recs[4 * g][8:40], g

def name(r, a, b):
    return recs[r][a:b].decode("ascii").rstrip()

# ---- extract + verify the pointer tables -------------------------------------
tables = {}
for addr in (TBL_C2C5, TBL_DEFAULT):
    ptrs = struct.unpack("<%dI" % TBL_ENTRIES, rd(addr, TBL_ENTRIES * 4))
    idx = []
    for p in ptrs:
        assert (p - REC_BASE) % REC_SIZE == 0 and REC_BASE <= p < GRID_END, hex(p)
        idx.append((p - REC_BASE) // REC_SIZE)
    tables[addr] = idx
assert tables[TBL_C2C5] == list(range(TBL_ENTRIES))       # identity / category order
for g in range(TBL_ENTRIES // 4):                         # Default keeps styles whole
    base = tables[TBL_DEFAULT][4 * g]
    assert base % 4 == 0
    assert tables[TBL_DEFAULT][4 * g:4 * g + 4] == [base, base + 1, base + 2, base + 3]

# ---- emit helpers -------------------------------------------------------------
TAB = 8
COMMENT_COL = 112  # matches tone_database_records.s
PTR_COMMENT_COL = 80

def vcol(s):
    col = 0
    for ch in s:
        col = (col // TAB + 1) * TAB if ch == "\t" else col + 1
    return col

def commented(txt, comment, col=COMMENT_COL):
    if comment is None:
        return txt + "\n"
    while vcol(txt) < col:
        txt += "\t"
    return txt + comment + "\n"

def byte_row(bytes_, comment=None):
    return commented("\t.byte\t" + ", ".join("0x%02x" % b for b in bytes_), comment)

def short_row(words, comment=None):
    return commented("\t.short\t" + ", ".join("0x%04x" % w for w in words), comment)

# ==============================================================================
# style_records.s
# ==============================================================================
records_header = """\
; =============================================================================
; MUSIC STYLIST PRESET RECORDS (StyleRec_000 .. StyleRec_999)
; =============================================================================
; ROM range 0x951000-0x983B39.  This is the MUSIC STYLIST preset database:
; 1000 records of 198 bytes in a contiguous grid - 250 styles x 4 arrangement
; variations, grouped into the ten Stylist categories (the firmware's own
; help text: "Explore 1000 Musical Styles with the Music Stylist."):
;
;   records 000-123  Easy Listening    (31 styles)
;   records 124-255  Rock & Pop        (33 styles)
;   records 256-323  Dance Pop         (17 styles)
;   records 324-399  Party Music       (19 styles)
;   records 400-471  Gospel/Blues/R&B  (18 styles)
;   records 472-591  Jazz & Swing      (30 styles)
;   records 592-715  Show/Trad Dance   (31 styles)
;   records 716-815  Trad & Folk       (25 styles)
;   records 816-883  Country           (17 styles)
;   records 884-999  Latin / World     (29 styles)
;
; No code addresses the records directly: maincpu reaches them exclusively
; through the two 1000-entry pointer tables at 0x986000/0x987000
; (StyleRec_PtrTable_CategoryOrder / StyleRec_PtrTable_Default, see
; style_record_ptr_tables.s), selected on the CURRENT UI STATE ID in RAM
; 0x8D38 - NOT a model code as previously documented.
;
; RECORD LAYOUT (grid stride 198 = the 197 bytes the size field declares
; + 1 uncommitted pad byte; consumers cited from v10 ui/ui_mode_handlers.s,
; same code in v7/v9):
;   +0x00  .long 197   record byte count
;   +0x04  .long 77    offset to the parameter block
;                      (EffectMode_ClampAndLookupPreset: add xhl, (xwa + 4))
;   +0x08  16-char space-padded category name  ("Easy Listening")
;   +0x18  16-char space-padded style name     ("German Schlager")
;   +0x28  .short 1    constant in all 1000 records
;   +0x2a  .byte 32    display-string length: MssName_EventDispatch does
;                      Strncpy(dst, rec+43, rec[42])
;   +0x2b  32-char display string = 29-char arrangement name + 3-char
;          right-aligned ASCII tempo (EffectMode_DisplayPresetName copies
;          only its first 16 chars for the narrow name box)
;   +0x4b  .byte 0, 0  NUL terminator (+ pad) for the display string
;   +0x4d  115-byte parameter block: the panel setup the Stylist applies
;          (sounds/volumes/effects; MIDI-range values, undecoded)
;   +0xc0  5 x 0xff    constant fill in all 1000 records
;   +0xc5  1 uncommitted grid pad byte (assorted leftover values; preserved
;          verbatim, NOT part of the 197-byte record)
;
; After the grid, 0x981570-0x983B39 is UNREFERENCED RESIDUE of an older
; generation of this flash region (no pointer into it exists in any program
; ROM: v7, v9 or v10): first 8167 bytes of high-entropy data with LZSS-style
; text shreds (kept as a raw slice of the dump), then from 0x983557 a ramp
; remnant of 16-bit little-endian values - low byte climbs by 10 mod 256,
; high byte climbs by 8 each time the low byte wraps - with a lone separator
; byte after every eighth value.  The 96-byte residue of the 0x986000
; pointer-table page (style_record_ptr_tables.s) continues the same ramp
; family, tying both residues to the same discarded predecessor data.
;
; Generated by scripts/generators/gen_style_records.py; this file is the
; authoritative source.
; =============================================================================

	.org 0x951000 - 0x800000, 0xff

"""

out = [records_header]
verify = bytearray()

for r, d in enumerate(recs):
    cat, sty = name(r, 8, 24), name(r, 24, 40)
    arr = name(r, 43, 72)
    tempo = int(d[72:75])
    out.append("StyleRec_%03d:\t; %s / %s: \"%s\" tempo %d\n" % (r, cat, sty, arr, tempo))
    out.append(commented("\t.long\t197, 77", "; +0x00 record length, parameter-block offset"))
    out.append(commented('\t.ascii\t"%s"' % d[8:24].decode("ascii"), "; +0x08 category"))
    out.append(commented('\t.ascii\t"%s"' % d[24:40].decode("ascii"), "; +0x18 style"))
    out.append(commented("\t.short\t1", "; +0x28 constant in all records"))
    out.append(commented("\t.byte\t32", "; +0x2a display-string length"))
    out.append(commented('\t.ascii\t"%s"' % d[43:72].decode("ascii"), "; +0x2b arrangement name"))
    out.append(commented('\t.ascii\t"%s"' % d[72:75].decode("ascii"), "; +0x48 tempo (right-aligned)"))
    out.append(commented("\t.byte\t0x00, 0x00", "; +0x4b display-string terminator"))
    for off in range(77, 192, 16):
        chunk = d[off:min(off + 16, 192)]
        out.append(byte_row(chunk, "; +0x%02x" % off))
    out.append(byte_row(d[192:197], "; +0xc0 constant fill"))
    out.append(byte_row(d[197:198], "; +0xc5 grid pad (uncommitted)"))
    out.append("\n")
    verify += d

residue_len = RAMP_LO - GRID_END
out.append("""\
; -----------------------------------------------------------------------------
; Unreferenced residue after the record grid (see module header).  The raw
; slice below is high-entropy data with LZSS-style text shreds - most likely
; the torso of a discarded compressed block whose header no longer exists.
; Byte-exact slice of the dump; do not rebuild.
; -----------------------------------------------------------------------------
StyleRecords_Residue:
\t.incbin\t"includes/icons_to_strings.bin", 0x%x, 0x%x

; -----------------------------------------------------------------------------
; Ramp remnant: 16-bit LE values, low byte +10 mod 256, high byte +8 on every
; low-byte wrap, a lone separator byte after every eighth value.  Runs from
; 0xa74b to 0x7fe9 and is cut off by the stale help DB at 0x983B3A.
; -----------------------------------------------------------------------------
StyleRecords_ResidueRamp:
""" % (GRID_END - BLOB_BASE, residue_len))
verify += rd(GRID_END, residue_len)

def ramp_step(v):
    return (v + (0x70A if (v & 0xFF) + 10 > 0xFF else 10)) & 0xFFFF

pos = RAMP_LO
last = None
while pos < MODULE_END:
    words = []
    while len(words) < 8 and MODULE_END - pos >= 2:
        w = struct.unpack_from("<H", rom, pos - BASE)[0]
        if last is not None and w != ramp_step(last):
            break
        words.append(w)
        last = w
        pos += 2
    if words:
        out.append(short_row(words))
        verify += b"".join(struct.pack("<H", w) for w in words)
    if len(words) < 8:
        break
    if pos < MODULE_END:
        sep = rom[pos - BASE]
        out.append(byte_row([sep], None if sep == 0 else "; irregular separator"))
        verify += bytes([sep])
        pos += 1
tail = rd(pos, MODULE_END - pos)
if tail:
    out.append(byte_row(tail, "; trailing remnant, cut by HelpDB_German_Stale"))
    verify += tail

assert bytes(verify) == rd(REC_BASE, MODULE_END - REC_BASE), "style_records byte mismatch"

with open(OUT_RECORDS, "w") as fh:
    fh.write("".join(out))
print("wrote %s (%d lines)" % (OUT_RECORDS, "".join(out).count("\n")))

# ==============================================================================
# style_record_ptr_tables.s
# ==============================================================================
ptr_header = """\
; =============================================================================
; MUSIC STYLIST POINTER TABLES (0x986000 / 0x987000)
; =============================================================================
; Two 4KB pages, each holding 1000 4-byte LE pointers to the Music Stylist
; preset records (style_records.s) followed by 96 bytes of unreferenced
; leftover residue.  maincpu references the pages numerically; consumers
; (v10 ui/ui_mode_handlers.s, same code in v7/v9):
;
;   EffectMode_ClampAndLookupPreset - clamps the index to 1000 (cp wa, 0x3e8,
;       matching the entry count), picks the table on the CURRENT UI STATE ID
;       in RAM 0x8D38: states 0xC2 and 0xC5 use StyleRec_PtrTable_CategoryOrder, every
;       other state uses StyleRec_PtrTable_Default.  (0x8D38 is the UI state
;       byte that UIState_KeyScan_Dispatch indexes keymaps with - NOT a model
;       code, as this table's comments previously claimed.)
;   EffectMode_DisplayPresetName - same split (its explicit state checks are
;       0xC0/0xC2/0xC5; 0xC0 takes the Default table), copies 16 chars of the
;       record's display string at rec+43.
;   MssName_EventDispatch (event 0x1c00013 bytecode) - Default table only,
;       copies rec[42] = 32 chars of the display string.
;
; ORDERINGS: both tables list all 1000 records, keeping each style's four
; arrangement records together.
;   StyleRec_PtrTable_CategoryOrder     identity: ROM order = the ten Stylist
;                              categories in sequence (browsing by category)
;   StyleRec_PtrTable_Default  re-sorted: interleaves the categories,
;                              starting 8-beat-like styles first (browsing
;                              order of the non-category screens)
;
; The residues are leftovers of an older generation of this flash region:
; the C2C5 page's residue continues the same 16-bit ramp family as
; StyleRecords_ResidueRamp (style_records.s); the Default page's residue is
; high-entropy like StyleRecords_Residue.  Both are unreferenced and
; preserved verbatim.
;
; Generated by scripts/generators/gen_style_records.py; this file is the
; authoritative source.
; =============================================================================

	.org 0x986000 - 0x800000, 0xff

"""

pout = [ptr_header]
pverify = bytearray()

def emit_table(label, addr, banner):
    pout.append(banner)
    pout.append("%s:\n" % label)
    idx = tables[addr]
    for g in range(TBL_ENTRIES // 4):
        four = idx[4 * g:4 * g + 4]
        refs = ", ".join("StyleRec_%03d" % k for k in four)
        sty, cat = name(four[0], 24, 40), name(four[0], 8, 24)
        if addr == TBL_C2C5:
            comment = "; %s (%s)" % (sty, cat)
        else:
            comment = "; slots %d-%d: %s (%s)" % (4 * g, 4 * g + 3, sty, cat)
        pout.append(commented("\t.long\t" + refs, comment, PTR_COMMENT_COL))
        for k in four:
            pverify.extend(struct.pack("<I", REC_BASE + REC_SIZE * k))
    pout.append("\n")

emit_table("StyleRec_PtrTable_CategoryOrder", TBL_C2C5,
           "; UI states 0xC2/0xC5: category order (identity)\n")
res = rd(TBL_C2C5 + TBL_ENTRIES * 4, TBL_RESIDUE)
pout.append("""\
; 96-byte page residue: fragment of the same ramp family as
; StyleRecords_ResidueRamp (16-bit LE, low byte +10 mod 256, high byte +8 on
; wrap, lone separator every eighth value) - leftover under the table page
StyleRec_PtrTable_CategoryOrder_Residue:
""")
for off in range(0, TBL_RESIDUE, 16):
    pout.append(byte_row(res[off:off + 16]))
pverify.extend(res)
pout.append("\n")

emit_table("StyleRec_PtrTable_Default", TBL_DEFAULT,
           "; all other UI states: re-sorted browsing order\n")
res = rd(TBL_DEFAULT + TBL_ENTRIES * 4, TBL_RESIDUE)
pout.append("""\
; 96-byte page residue: high-entropy leftover under the table page
StyleRec_PtrTable_Default_Residue:
""")
for off in range(0, TBL_RESIDUE, 16):
    pout.append(byte_row(res[off:off + 16]))
pverify.extend(res)

assert bytes(pverify) == rd(TBL_C2C5, 0x2000), "ptr_tables byte mismatch"

with open(OUT_PTRTABLES, "w") as fh:
    fh.write("".join(pout))
print("wrote %s (%d lines)" % (OUT_PTRTABLES, "".join(pout).count("\n")))
