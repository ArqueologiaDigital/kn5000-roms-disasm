#!/usr/bin/env python3
"""
Generate style_ui_screendata_main.c with proper C struct types.

Parses .byte directives from the .s file and generates a C source file
with typed struct fields (HLINE, VLINE, WIDGET, FILLED_RECT, etc.)
instead of raw byte arrays.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_FILE = os.path.join(REPO, 'original_ROMs', 'kn5000_v10_program.rom')
C_FILE = os.path.join(REPO, 'maincpu', 'style_ui', 'main.c')
# ROM offset for this data block (0xE0BB90 - 0xE00000 = 0xBB90)
ROM_OFFSET = 0xBB90
DATA_SIZE = 3531

# Handler name lookup for widget comments
HANDLER_NAMES = {
    0x00e0bd98: "param_value",
    0x00e0c3a6: "chord_root",
    0x00e0c3c6: "chord_type",
    0x00e0c506: "chord_quality",
    0x00e0c8cc: "track_status",
    0x00000eca: "end_rep",
    0x00000ef8: "empty_slot",
    0x00000f16: "cursor_pos",
    0x00000f34: "selection",
}


def extract_bytes_from_rom(rom_path, offset, size):
    """Read raw bytes from ROM binary at given offset."""
    with open(rom_path, 'rb') as f:
        f.seek(offset)
        data = f.read(size)
    return list(data)


def u16(data, off):
    """Read uint16_t LE from data at offset."""
    return data[off] | (data[off + 1] << 8)


def u32(data, off):
    """Read uint32_t LE from data at offset."""
    return data[off] | (data[off + 1] << 8) | (data[off + 2] << 16) | (data[off + 3] << 24)


def fmt_hline(data, off):
    """Format 10-byte HLINE as C initializer."""
    p1x, p1y = u16(data, off + 2), u16(data, off + 4)
    p2x, p2y = u16(data, off + 6), u16(data, off + 8)
    return (f"{{ .opcode = SD_OP_HLINE, .length = 0x0a, "
            f".p1 = {{ .x = {p1x}, .y = {p1y} }}, "
            f".p2 = {{ .x = {p2x}, .y = {p2y} }} }},")


def fmt_vline(data, off):
    """Format 10-byte VLINE as C initializer."""
    p1x, p1y = u16(data, off + 2), u16(data, off + 4)
    p2x, p2y = u16(data, off + 6), u16(data, off + 8)
    return (f"{{ .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, "
            f".p1 = {{ .x = {p1x}, .y = {p1y} }}, "
            f".p2 = {{ .x = {p2x}, .y = {p2y} }} }},")


def fmt_filled_rect(data, off):
    """Format 10-byte FILLED_RECT as C initializer."""
    tlx, tly = u16(data, off + 2), u16(data, off + 4)
    brx, bry = u16(data, off + 6), u16(data, off + 8)
    return (f"{{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, "
            f".top_left = {{ .x = {tlx}, .y = {tly} }}, "
            f".bottom_right = {{ .x = {brx}, .y = {bry} }} }},")


def fmt_ref1(data, off):
    """Format 5-byte LABELED_REF with 1-byte param."""
    addr = u16(data, off + 2)
    param = data[off + 4]
    return (f"{{ .opcode = SD_OP_LABELED_REF, .length = 5, "
            f".addr = 0x{addr:04x}, .label = {{ 0x{param:02x} }} }},")


def fmt_ref_ex(data, off):
    """Format 10-byte REF_EX."""
    id_val = u16(data, off + 2)
    d = data[off + 4:off + 10]
    dstr = ', '.join(f'0x{b:02x}' for b in d)
    return (f"{{ .opcode = SD_OP_LABELED_REF, .length = 0x0a, "
            f".id = 0x{id_val:04x}, .data = {{ {dstr} }} }},")


def fmt_nop_10(data, off):
    """Format 10-byte NOP/PAD."""
    d = data[off + 2:off + 10]
    dstr = ', '.join(f'0x{b:02x}' for b in d)
    return (f"{{ .opcode = 0x{data[off]:02x}, .length = 0x{data[off+1]:02x}, "
            f".data = {{ {dstr} }} }},")


def fmt_widget(data, off):
    """Format 15-byte WIDGET as C initializer."""
    subtype = data[off + 1]
    id_val = u16(data, off + 2)
    flags = u16(data, off + 4)
    ref_tag = data[off + 6]
    handler = u32(data, off + 7)
    param = u16(data, off + 11)
    x = data[off + 13]
    y = data[off + 14]
    hname = HANDLER_NAMES.get(handler, f"0x{handler:06x}")
    return (f"{{ .opcode = 0x02, .subtype = 0x{subtype:02x}, "
            f".id = 0x{id_val:04x}, .flags = 0x{flags:04x}, "
            f".ref_tag = 0x{ref_tag:02x}, .handler = 0x{handler:08x}, "
            f".param = {param}, .x = {x}, .y = {y} }},"
            f"  /* {hname} */")


def fmt_raw(data, start, end, indent='\t\t', width=16):
    """Format raw bytes as C hex initializer."""
    lines = []
    for i in range(start, end, width):
        chunk = data[i:min(i + width, end)]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'{indent}{hex_vals},')
    return '\n'.join(lines)


def main():
    raw = extract_bytes_from_rom(ROM_FILE, ROM_OFFSET, DATA_SIZE)
    total = len(raw)
    print(f"Extracted {total} bytes from ROM at offset 0x{ROM_OFFSET:x}")
    if total != 3531:
        print(f"ERROR: Expected 3531 bytes, got {total}")
        sys.exit(1)

    # Section boundaries
    CHORD_BOXES = 0          # 180 bytes: 4 boxes
    GRID_LINES = 180         # 270 bytes: 3 rows × 9 segments
    ROW_LABELS = 450         # 55 bytes: 3 REF_EX + 3 REF + 1 NOP
    CONTROL = 505            # 125 bytes: complex interleaved
    PARAM_WIDGETS = 630      # 360 bytes: 24 × 15
    CHORD_WIDGETS = 990      # 1080 bytes: 72 × 15
    CHORD_ROOTS = 2070       # 32 bytes
    CHORD_TYPES = 2102       # 242 bytes
    FOOTER_LABELS = 2344     # 40 bytes
    SETUP_CONTROL = 2384     # 580 bytes
    CHORD_BITMAP = 2964      # 64 bytes
    TRACK_WIDGETS = 3028     # 360 bytes: 24 × 15
    BOTTOM_MARKER = 3388     # 3 bytes
    BOTTOM_RECTS = 3391      # 80 bytes: 8 × 10
    BOTTOM_DIVIDERS = 3471   # 60 bytes: 6 × 10

    assert BOTTOM_DIVIDERS + 60 == 3531

    out = []
    out.append('/**')
    out.append(' * StyleUI_ScreenData_Main — Style UI Main Screen Layout')
    out.append(' *')
    out.append(' * Source: e0bb90_e0c95a.bin (3531 bytes)')
    out.append(' *')
    out.append(' * Screen layout for the accompaniment style editor main view.')
    out.append(' * The 320x240 LCD is divided into:')
    out.append(' *   - Top row (y=35): 4 chord name display boxes (HLINE/VLINE/REF)')
    out.append(' *   - 3 parameter grid rows at y=80, 125, 170 with 4 columns each')
    out.append(' *   - Row label references and control widgets')
    out.append(' *   - 24 parameter value widgets (handler 0xe0bd98)')
    out.append(' *   - 72 chord root/type/quality widgets (3 rows × 8 cells × 3 layers)')
    out.append(' *   - Chord name tables: 12 root names + ~48 type names')
    out.append(' *   - SETUP/CONTROL blocks with coordinate arrays')
    out.append(' *   - Chord recognition bitmap (64 bytes)')
    out.append(' *   - 24 track status widgets + bottom bar (8 FILLED_RECT + 6 HLINE)')
    out.append(' */')
    out.append('')
    out.append('#include "screendata_types.h"')
    out.append('')

    # ========== STRUCT DEFINITION ==========
    out.append('typedef struct __attribute__((packed)) {')

    # Chord boxes
    out.append('\t/* === Chord Name Boxes (180 bytes, y=35) === */')
    for i in range(1, 4):
        out.append(f'\t/* Box {i} */')
        out.append(f'\tsd_hline_t          box{i}_hline_left;')
        out.append(f'\tsd_hline_t          box{i}_hline_right;')
        out.append(f'\tsd_vline_t          box{i}_vline_left;')
        out.append(f'\tsd_vline_t          box{i}_vline_right;')
        out.append(f'\tsd_labeled_ref_1_t  box{i}_ref;')
    out.append('\t/* Box 4 (different element order) */')
    out.append('\tsd_vline_t          box4_vline_left;')
    out.append('\tsd_vline_t          box4_vline_right;')
    out.append('\tsd_labeled_ref_1_t  box4_ref;')
    out.append('\tsd_hline_t          box4_hline_left;')
    out.append('\tsd_hline_t          box4_hline_right;')
    out.append('')

    # Grid lines
    out.append('\t/* === Parameter Grid Lines (270 bytes, 3 rows × 9 segments) === */')
    for r in range(1, 4):
        y_vals = {1: 80, 2: 125, 3: 170}
        out.append(f'\t/* Row {r} (y={y_vals[r]}): 5 corner VLINEs + 4 bar HLINEs */')
        for seg in range(1, 6):
            out.append(f'\tsd_vline_t  grid{r}_corner_{seg};')
            if seg < 5:
                out.append(f'\tsd_hline_t  grid{r}_bar_{seg};')
    out.append('')

    # Row labels
    out.append('\t/* === Row Label References (55 bytes) === */')
    out.append('\tsd_ref_ex_t         row_label_1;')
    out.append('\tsd_ref_ex_t         row_label_2;')
    out.append('\tsd_ref_ex_t         row_label_3;')
    out.append('\tsd_labeled_ref_1_t  row_ref_1;')
    out.append('\tsd_labeled_ref_1_t  row_ref_2;')
    out.append('\tsd_labeled_ref_1_t  row_ref_3;')
    out.append('\tsd_nop_10_t         nop_pad;')
    out.append('')

    # Control widgets (raw — complex interleaved STRING + WIDGET data)
    out.append('\t/* === Control Widgets (125 bytes, complex interleaved) === */')
    out.append('\tuint8_t control_widgets[125];')
    out.append('')

    # Param widgets
    out.append('\t/* === Parameter Value Widgets (360 bytes, 24 × sd_widget_t) === */')
    out.append('\tsd_widget_t param_widgets[24];')
    out.append('')

    # Chord widgets
    out.append('\t/* === Chord Root/Type/Quality Widgets (1080 bytes, 72 × sd_widget_t) === */')
    out.append('\tsd_widget_t chord_widgets[72];')
    out.append('')

    # Chord root names
    out.append('\t/* === Chord Root Names (32 bytes: C Db D Eb E F F# G Ab A Bb B) === */')
    out.append('\tuint8_t chord_root_names[32];')
    out.append('')

    # Chord type names
    out.append('\t/* === Chord Type Names (242 bytes: Maj7, aug, min, dim, etc.) === */')
    out.append('\tuint8_t chord_type_names[242];')
    out.append('')

    # Footer labels
    out.append('\t/* === Footer Labels (40 bytes) === */')
    out.append('\tuint8_t footer_labels[40];')
    out.append('')

    # Setup/control data
    out.append('\t/* === SETUP/CONTROL Blocks + Coordinate Arrays (580 bytes) === */')
    out.append('\tuint8_t setup_control_data[580];')
    out.append('')

    # Chord bitmap
    out.append('\t/* === Chord Recognition Bitmap (64 bytes: 0x91=enabled, 0x2a=disabled) === */')
    out.append('\tuint8_t chord_bitmap[64];')
    out.append('')

    # Track status widgets
    out.append('\t/* === Track Status Widgets (360 bytes, 24 × sd_widget_t) === */')
    out.append('\tsd_widget_t track_status_widgets[24];')
    out.append('')

    # Bottom bar
    out.append('\t/* === Bottom Bar (143 bytes) === */')
    out.append('\tuint8_t bottom_bar_marker[3];')
    out.append('\tsd_filled_rect_t bottom_bar_rects[8];')
    out.append('\tsd_hline_t bottom_bar_dividers[6];')

    out.append('} screendata_main_t;')
    out.append('')
    out.append('_Static_assert(sizeof(screendata_main_t) == 3531,')
    out.append('\t"ScreenData_Main must be exactly 3531 bytes");')
    out.append('')

    # ========== INITIALIZER ==========
    out.append('const screendata_main_t StyleUI_ScreenData_Main')
    out.append('\t__attribute__((section(".text"), used)) = {')
    out.append('')

    # --- Chord boxes ---
    box_x = [(10, 70), (74, 134), (138, 198), (202, 262)]
    off = CHORD_BOXES
    for i in range(1, 4):
        xl, xr = box_x[i - 1]
        out.append(f'\t/* Chord box {i} (x={xl}..{xr}) */')
        out.append(f'\t.box{i}_hline_left  = {fmt_hline(raw, off)}')
        off += 10
        out.append(f'\t.box{i}_hline_right = {fmt_hline(raw, off)}')
        off += 10
        out.append(f'\t.box{i}_vline_left  = {fmt_vline(raw, off)}')
        off += 10
        out.append(f'\t.box{i}_vline_right = {fmt_vline(raw, off)}')
        off += 10
        out.append(f'\t.box{i}_ref         = {fmt_ref1(raw, off)}')
        off += 5
    # Box 4 (different order)
    xl, xr = box_x[3]
    out.append(f'\t/* Chord box 4 (x={xl}..{xr}, different element order) */')
    out.append(f'\t.box4_vline_left  = {fmt_vline(raw, off)}')
    off += 10
    out.append(f'\t.box4_vline_right = {fmt_vline(raw, off)}')
    off += 10
    out.append(f'\t.box4_ref         = {fmt_ref1(raw, off)}')
    off += 5
    out.append(f'\t.box4_hline_left  = {fmt_hline(raw, off)}')
    off += 10
    out.append(f'\t.box4_hline_right = {fmt_hline(raw, off)}')
    off += 10
    assert off == GRID_LINES, f"chord_boxes end: expected {GRID_LINES}, got {off}"
    out.append('')

    # --- Grid lines ---
    y_vals = {1: 80, 2: 125, 3: 170}
    off = GRID_LINES
    for r in range(1, 4):
        out.append(f'\t/* Grid row {r} (y={y_vals[r]}) */')
        for seg in range(1, 6):
            out.append(f'\t.grid{r}_corner_{seg} = {fmt_vline(raw, off)}')
            off += 10
            if seg < 5:
                out.append(f'\t.grid{r}_bar_{seg}    = {fmt_hline(raw, off)}')
                off += 10
    assert off == ROW_LABELS, f"grid_lines end: expected {ROW_LABELS}, got {off}"
    out.append('')

    # --- Row labels ---
    off = ROW_LABELS
    out.append('\t/* Row label references */')
    out.append(f'\t.row_label_1 = {fmt_ref_ex(raw, off)}')
    off += 10
    out.append(f'\t.row_label_2 = {fmt_ref_ex(raw, off)}')
    off += 10
    out.append(f'\t.row_label_3 = {fmt_ref_ex(raw, off)}')
    off += 10
    out.append(f'\t.row_ref_1   = {fmt_ref1(raw, off, "param=45")}')
    off += 5
    out.append(f'\t.row_ref_2   = {fmt_ref1(raw, off, "param=45")}')
    off += 5
    out.append(f'\t.row_ref_3   = {fmt_ref1(raw, off, "param=45")}')
    off += 5
    out.append(f'\t.nop_pad     = {fmt_nop_10(raw, off, "NOP/PAD")}')
    off += 10
    assert off == CONTROL, f"row_labels end: expected {CONTROL}, got {off}"
    out.append('')

    # --- Control widgets (raw) ---
    out.append('\t/* Control widgets (complex interleaved STRING + WIDGET data) */')
    out.append('\t.control_widgets = {')
    out.append(fmt_raw(raw, CONTROL, PARAM_WIDGETS))
    out.append('\t},')
    out.append('')

    # --- Param value widgets ---
    out.append('\t/* Parameter value widgets (handler 0xe0bd98) */')
    out.append('\t.param_widgets = {')
    off = PARAM_WIDGETS
    for i in range(24):
        out.append(f'\t\t{fmt_widget(raw, off)}')
        off += 15
    assert off == CHORD_WIDGETS, f"param_widgets end: expected {CHORD_WIDGETS}, got {off}"
    out.append('\t},')
    out.append('')

    # --- Chord root/type/quality widgets ---
    out.append('\t/* Chord root/type/quality widgets (3 rows × 8 cells × 3 layers) */')
    out.append('\t.chord_widgets = {')
    off = CHORD_WIDGETS
    for i in range(72):
        # Add row separator comments
        if i == 0:
            out.append('\t\t/* Row 1 (y=8): 8 cells × (root + type + quality) */')
        elif i == 24:
            out.append('\t\t/* Row 2 (y=15) */')
        elif i == 48:
            out.append('\t\t/* Row 3 (y=22) */')
        out.append(f'\t\t{fmt_widget(raw, off)}')
        off += 15
    assert off == CHORD_ROOTS, f"chord_widgets end: expected {CHORD_ROOTS}, got {off}"
    out.append('\t},')
    out.append('')

    # --- Chord root names ---
    out.append('\t/* Chord root names: C Db D Eb E F F# G Ab A Bb B */')
    out.append('\t.chord_root_names = {')
    out.append(fmt_raw(raw, CHORD_ROOTS, CHORD_TYPES))
    out.append('\t},')
    out.append('')

    # --- Chord type names ---
    out.append('\t/* Chord type names (Maj7, aug, min, dim, 7sus4, etc.) */')
    out.append('\t.chord_type_names = {')
    out.append(fmt_raw(raw, CHORD_TYPES, FOOTER_LABELS))
    out.append('\t},')
    out.append('')

    # --- Footer labels ---
    out.append('\t/* Footer labels and control bytes */')
    out.append('\t.footer_labels = {')
    out.append(fmt_raw(raw, FOOTER_LABELS, SETUP_CONTROL))
    out.append('\t},')
    out.append('')

    # --- Setup/control data ---
    out.append('\t/* SETUP/CONTROL blocks with coordinate arrays */')
    out.append('\t.setup_control_data = {')
    out.append(fmt_raw(raw, SETUP_CONTROL, CHORD_BITMAP))
    out.append('\t},')
    out.append('')

    # --- Chord bitmap ---
    out.append('\t/* Chord recognition bitmap (0x91=enabled, 0x2a=disabled) */')
    out.append('\t.chord_bitmap = {')
    out.append(fmt_raw(raw, CHORD_BITMAP, TRACK_WIDGETS))
    out.append('\t},')
    out.append('')

    # --- Track status widgets ---
    out.append('\t/* Track status widgets (handler 0xe0c8cc, flags=0x8560) */')
    out.append('\t.track_status_widgets = {')
    off = TRACK_WIDGETS
    for i in range(24):
        out.append(f'\t\t{fmt_widget(raw, off)}')
        off += 15
    assert off == BOTTOM_MARKER, f"track_widgets end: expected {BOTTOM_MARKER}, got {off}"
    out.append('\t},')
    out.append('')

    # --- Bottom bar ---
    out.append('\t/* Bottom bar marker */')
    out.append('\t.bottom_bar_marker = {')
    out.append(fmt_raw(raw, BOTTOM_MARKER, BOTTOM_RECTS))
    out.append('\t},')
    out.append('')

    out.append('\t/* Bottom bar: 8 FILLED_RECTs at y=210-236 */')
    out.append('\t.bottom_bar_rects = {')
    off = BOTTOM_RECTS
    for i in range(8):
        out.append(f'\t\t{fmt_filled_rect(raw, off)}')
        off += 10
    assert off == BOTTOM_DIVIDERS, f"bottom_rects end: expected {BOTTOM_DIVIDERS}, got {off}"
    out.append('\t},')
    out.append('')

    out.append('\t/* Bottom bar: 6 HLINE dividers at y=223 */')
    out.append('\t.bottom_bar_dividers = {')
    off = BOTTOM_DIVIDERS
    for i in range(6):
        out.append(f'\t\t{fmt_hline(raw, off)}')
        off += 10
    assert off == 3531, f"bottom_dividers end: expected 3531, got {off}"
    out.append('\t},')

    out.append('};')
    out.append('')

    with open(C_FILE, 'w') as f:
        f.write('\n'.join(out))

    print(f"Generated {C_FILE} ({total} bytes, fully typed)")


if __name__ == '__main__':
    main()
