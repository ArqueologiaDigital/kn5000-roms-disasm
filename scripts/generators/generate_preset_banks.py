#!/usr/bin/env python3
"""Generate table_data/preset_banks.s from the original Table Data ROM.

Covers ROM 0x800000-0x82FFFF: the 34-entry section directory plus the 27
preset/user data banks that live in the left half of what used to be
includes/initial_data.bin.  Emission rules:

* the directory becomes symbolic .long entries (labels for in-half targets,
  numeric addresses for the six targets inside the UI-bitmap half);
* sections with a verified record stride are emitted record-framed (one
  .byte block per record, constant-record runs coalesced into .fill);
* the remaining sections are emitted as maximal same-byte runs >= RUN_FILL
  bytes as .fill and everything else as 16-byte .byte rows.

The output is byte-exact against the ROM slice [0, 0x30000); verify with:
  llvm-mc -triple=tlcs900 -filetype=obj  +  ld.lld -T table_data.ld  +
  llvm-objcopy -O binary  +  cmp against the first 0x30000 bytes of
  original_ROMs/kn5000_table_data.rom
"""

import sys
from pathlib import Path

ROM_BASE = 0x800000
HALF_END = 0x830000
RUN_FILL = 32          # min same-byte run length emitted as .fill (run-based sections)
COMMENT_COL = 112      # comment alignment column for data lines
DIR_COMMENT_COL = 48   # comment alignment column for the directory .long lines

# Directory targets (34 entries incl. null terminator), read back from the ROM
# and cross-checked below.  in_half = target < HALF_END.
#
# Per-section metadata: address-order size, record stride (None = run-based),
# and the descriptive comment block placed above the section label.
SECTIONS = {
    #  n : (start,    size,   stride, description lines)
    0:  (0x800088, 11400, 120, [
        "95 records x 120 bytes.  Sparse 0x00/0xF8 fields punched into an",
        "erased-flash background of 0xF7.  Section 1 is the SAME image with",
        "one substitution -- see there.",
    ]),
    1:  (0x802D10, 11400, 120, [
        "95 records x 120 bytes.  Byte-for-byte identical to section 0",
        "except that every 0xF8 there reads 0x0A here (3,280 positions, no",
        "other difference) -- one image, two per-entry marker values.",
    ]),
    2:  (0x805998, 1764, None, [
        "Alternating 0xF7/0xF2 runs whose 0xF2 run lengths grow slowly from",
        "~11 to ~19 bytes -- a ramp/curve-like table on erased-flash 0xF7",
        "background (74% 0xF7, 25% 0xF2).",
    ]),
    3:  (0x80607C, 4884, 22, [
        "222 records x 22 bytes.  Fixed framing: every record begins",
        "0x07 0x07 0xF8 and ends 0x07 0xF8 0x00 0x07; the 15-byte body holds",
        "sparse 0xFF/0x00 patterns.  105 of the 222 records are constant.",
        "Sections 3-5 are three near-identical copies of this bank (only",
        "~260 bytes differ between any two).",
    ]),
    4:  (0x807390, 4884, 22, [
        "222 records x 22 bytes -- second copy of the section 3 bank.",
    ]),
    5:  (0x8086A4, 4884, 22, [
        "222 records x 22 bytes -- third copy of the section 3 bank.",
    ]),
    8:  (0x8099B8, 2800, 112, [
        "25 records x 112 bytes; 0x07-default fields with 0xF8 markers.",
        "Same 25-slot layout as section 10 (whose record is 2 bytes wider).",
    ]),
    9:  (0x80A4A8, 1440, 80, [
        "18 records x 80 bytes; only values 0x07 (64%) and 0x01 (35%).",
    ]),
    10: (0x80AA48, 2850, 114, [
        "25 records x 114 bytes; 0x07-default fields with 0xF8 markers --",
        "the 25-slot sibling of section 8.",
    ]),
    11: (0x80B56A, 2160, 108, [
        "20 records x 108 bytes; only values 0x07 (71%) and 0x06 (28%).",
    ]),
    12: (0x80BDDA, 3016, 58, None),  # description generated (slot group)
    13: (0x80C9A2, 3016, 58, None),
    14: (0x80D56A, 3016, 58, None),
    15: (0x80E132, 3016, 58, None),
    16: (0x80ECFA, 3016, 58, None),
    17: (0x80F8C2, 3016, 58, None),
    18: (0x81048A, 3016, 58, None),
    19: (0x811052, 3016, 58, None),
    20: (0x811C1A, 3016, 58, None),
    21: (0x8127E2, 3016, 58, None),
    22: (0x8133AA, 3016, 58, None),
    23: (0x813F72, 3016, 58, None),
    24: (0x814B3A, 3016, 58, None),
    25: (0x815702, 31968, 296, [
        "First of three 31,968-byte user banks (sections 25-27), each an",
        "exact grid of 108 records x 296 bytes: sparse 0x00-filled fields",
        "over an erased 0xFF background (83% 0xFF), with many records",
        "repeated verbatim (77 distinct record images out of 108 here).",
        "Sections 25 and 26 differ in only 48 bytes; section 27 diverges",
        "further (1,260 bytes differ from section 25).",
    ]),
    26: (0x81D3E2, 31968, 296, [
        "Second 108 x 296-byte user bank -- near-identical to section 25",
        "(48 bytes differ; 72 distinct record images).",
    ]),
    27: (0x8250C2, 31968, 296, [
        "Third 108 x 296-byte user bank (1,260 bytes differ from section",
        "25; 79 distinct record images).",
    ]),
    7:  (0x82CDA2, 983646, None, [
        "Head of section 7, the largest directory entry.  8bpp-bitmap-like",
        "content: ~200-byte-period rows of palette indices 0x22-0x2E over the",
        "0xF7 background that DrawBitmap treats as transparent -- smooth",
        "curve/line-art shapes.  The address-order extent of this section",
        "(distance to the next-higher directory target, 0x91D000) is 983,646",
        "bytes, so it nominally spans the whole factory region that follows",
        "(tone database, feature demo, wallpapers); only its first 12,894",
        "bytes -- up to the tone database at 0x830000 -- are emitted here,",
        "and the actual save/load span of the section is unverified.",
    ]),
}

# 13-slot group (sections 12-24): generated description.
SLOT_GROUP = list(range(12, 25))

# Directory entries pointing into the UI-bitmap half (no labels there yet --
# wallpaper1_to_icons.bin is still a monolithic .incbin), with address-order
# sizes for the comments.
OUT_OF_HALF = {
    6:  (0x91D000, 14040, "SectionBank06_TechnicsLogo"),
    28: (0x9206D8, 12000, "SectionBank28_KN5000Picture"),
    29: (0x9235B8, 2032, "SectionBank29_NoteEditKeyboard"),
    30: (0x923DA8, 30480, "SectionBank30_NoteEditGrid"),
    31: (0x92B4B8, 10472, "SectionBank31_DrumEditRows"),
    32: (0x92DDA0, 25184, "SectionBank32_DrumEditGrid"),
}


def tabs_to(col, width):
    n = max(1, -(-(col - width) // 8))
    return "\t" * n


def data_line(vals, comment):
    s = ", ".join(f"0x{b:02x}" for b in vals)
    line = f"\t.byte\t{s}"
    width = 16 + len(s)
    return line + tabs_to(COMMENT_COL, width) + comment


def fill_line(count, val, comment):
    body = f"{count}, 1, 0x{val:02x}"
    line = f"\t.fill\t{body}"
    width = 16 + len(body)
    return line + tabs_to(COMMENT_COL, width) + comment


def emit_record_framed(out, data, stride):
    """Record-framed emission: one .byte block per record, 16 bytes per line;
    runs of records that are entirely one constant coalesce into .fill."""
    nrec = len(data) // stride
    assert nrec * stride == len(data)
    i = 0
    while i < nrec:
        rec = data[i * stride:(i + 1) * stride]
        if len(set(rec)) == 1:
            j = i
            v = rec[0]
            while (j + 1 < nrec
                   and set(data[(j + 1) * stride:(j + 2) * stride]) == {v}):
                j += 1
            n = j - i + 1
            what = (f"; records {i:02d}-{j:02d}: all 0x{v:02x}" if n > 1
                    else f"; record {i:02d}: all 0x{v:02x}")
            out.append(fill_line(n * stride, v, what))
            i = j + 1
        else:
            for k in range(0, stride, 16):
                off = i * stride + k
                tag = f"; +0x{off:04x}" + (f"  record {i:02d}" if k == 0 else "")
                out.append(data_line(rec[k:k + 16], tag))
            i += 1


def emit_run_based(out, data):
    """Run-based emission: same-byte runs >= RUN_FILL become .fill, everything
    else 16-byte .byte rows broken at section-relative 16-byte boundaries."""
    runs = []
    i = 0
    while i < len(data):
        j = i
        while j < len(data) and data[j] == data[i]:
            j += 1
        runs.append((i, j - i, data[i]))
        i = j
    # merge short runs into literal segments
    segs = []  # (start, length, fill_val_or_None)
    for start, length, val in runs:
        if length >= RUN_FILL:
            segs.append((start, length, val))
        elif segs and segs[-1][2] is None:
            s, l, _ = segs[-1]
            segs[-1] = (s, l + length, None)
        else:
            segs.append((start, length, None))
    for start, length, val in segs:
        if val is not None:
            out.append(fill_line(length, val, f"; +0x{start:04x}"))
        else:
            pos = start
            end = start + length
            while pos < end:
                row_end = min(end, (pos // 16 + 1) * 16)
                out.append(data_line(data[pos:row_end], f"; +0x{pos:04x}"))
                pos = row_end


def main():
    repo = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "/home/fsanches/compartilhado/kn5000-roms-disasm")
    outfile = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("preset_banks.s")
    rom = (repo / "original_ROMs/kn5000_table_data.rom").read_bytes()

    # cross-check the directory against the metadata tables above
    import struct
    directory = [struct.unpack_from("<I", rom, i * 4)[0] for i in range(34)]
    for n, (start, _, _, _) in SECTIONS.items():
        assert directory[n] == start, (n, hex(directory[n]), hex(start))
    for n, (start, _, _lbl) in OUT_OF_HALF.items():
        assert directory[n] == start, (n, hex(directory[n]), hex(start))
    assert directory[33] == 0

    out = []
    a = out.append
    a("; =============================================================================")
    a("; SECTION DIRECTORY + PRESET DATA BANKS (0x800000 - 0x82FFFF)")
    a("; =============================================================================")
    a("; First 192KB of the Table Data flash ROM: a 34-entry directory of 4-byte")
    a("; little-endian pointers (33 section pointers + null terminator) followed by")
    a("; the preset/user data banks the pointers describe.  Directory targets are")
    a("; NOT in address order: entry 7 points backward into this half and entries")
    a("; 6 and 28-32 point forward into the UI-bitmap half of the ROM (0x91D000-")
    a("; 0x92DDA0, still inside includes/wallpaper1_to_icons.bin -- kept numeric")
    a("; below until that blob is split).  A section's size is the distance to the")
    a("; next-higher directory target.")
    a(";")
    a("; This region is the rewritable user-data area of the table-data flash pair:")
    a("; the firmware's flash primitives unlock the chip with AMD command cycles at")
    a("; 0x815554/0x80AAA8 (chip word addresses 0xAAAA/0x5554 -- these fall inside")
    a("; sections 25 and 10 but are command writes, not data references), and")
    a('; "Technics KN5000 Table    DATA FILE 1/2" update floppies rewrite the whole')
    a("; 0x800000 half via HANDLE_UPDATE_FILE_TYPE_ID_003h -> Flash_BurnWithProgress")
    a("; + FDC_WriteSectors (maincpu boot/system_handlers.s).  No disassembled")
    a("; maincpu/subcpu code reads an individual directory entry or section address")
    a("; directly, so the per-section roles below are described structurally; the")
    a("; factory images here are the power-on/factory-reset defaults for the user's")
    a("; sound/registration/composer memories (exact mapping still unattributed).")
    a(";")
    a("; FILL-PATTERN LEGEND (factory-default state of each bank):")
    a(";   0xF7/0xF8  erased-flash background patterns")
    a(";   0x07/0x06  default parameter values")
    a(";   0x00       zeroed fields        0xFF/0xFE/0xFC  empty/erased fields")
    a(";")
    a("; RECORD GRIDS (dominant autocorrelation stride, all exact size divisors):")
    a(";   sec 0/1: 95 x 120 B     sec 3-5: 222 x 22 B    sec 8: 25 x 112 B")
    a(";   sec 9: 18 x 80 B        sec 10: 25 x 114 B     sec 11: 20 x 108 B")
    a(";   sec 12-24: 52 x 58 B (13 uniform slots)   sec 25-27: 108 x 296 B")
    a("; =============================================================================")
    a("")
    a("SectionDirectory_Table:")

    # size list in INDEX order for the directory comments
    sizes = {n: meta[1] for n, meta in SECTIONS.items()}
    sizes.update({n: sz for n, (tgt, sz, _lbl) in OUT_OF_HALF.items()})
    for n in range(33):
        if n in SECTIONS:
            tgt = f"PresetBank_Sec{n:02d}"
            note = f"; entry {n:2d}: {sizes[n]:>7,} B"
        else:
            tgt_addr, sz, lbl = OUT_OF_HALF[n]
            tgt = lbl
            note = f"; entry {n:2d}: {sz:>7,} B  (UI-bitmap half, ui_bitmaps.s)"
        line = f"\t.long\t{tgt}"
        a(line + tabs_to(DIR_COMMENT_COL, 16 + len(tgt)) + note)
    a("\t.long\t0x00000000" + tabs_to(DIR_COMMENT_COL, 16 + 10) + "; terminator")

    # sections in address order
    addr_order = sorted(SECTIONS.items(), key=lambda kv: kv[1][0])
    for n, (start, size, stride, desc) in addr_order:
        if desc is None and n in SLOT_GROUP:
            slot = n - 12 + 1
            desc = [f"User slot {slot:02d} of 13 (sections 12-24): 52 records x 58 bytes."]
            if n == 12:
                desc += [
                    "All 13 slots carry ONE identical 3,016-byte factory image that is",
                    "then re-marked per slot: relative to this first slot, every later",
                    "slot differs ONLY by 0xFF bytes rewritten to 0xFE (260 positions",
                    "in slot 02 growing monotonically to 1,700 in slot 13) and 0x00",
                    "bytes rewritten to 0xFC (0 growing to 580).  No other byte value",
                    "changes anywhere in the group.",
                ]
        end = min(start + size, HALF_END)
        data = rom[start - ROM_BASE:end - ROM_BASE]
        a("")
        a("; -----------------------------------------------------------------------------")
        head = f"; Section {n} (0x{start:06X}, {size:,} bytes"
        head += ", head only)" if start + size > HALF_END else ")"
        a(head)
        for d in desc:
            a("; " + d)
        a("; -----------------------------------------------------------------------------")
        a(f"PresetBank_Sec{n:02d}:")
        if stride:
            emit_record_framed(out, data, stride)
        else:
            emit_run_based(out, data)

    outfile.write_text("\n".join(out) + "\n")
    total = sum(min(sz, HALF_END - st) for _, (st, sz, _, _) in SECTIONS.items())
    print(f"wrote {outfile}: {len(out)} lines, sections cover {total + 136:#x} bytes")


if __name__ == "__main__":
    main()
