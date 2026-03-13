#!/usr/bin/env python3
"""
Generate style_ui_screendata_main.c from the assembly .s file.

Parses .byte directives from the .s file, groups bytes into logical sections,
and generates a C source file with named struct fields for each section.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S_FILE = os.path.join(REPO, 'maincpu', 'includes', 'style_ui_screendata_main.s')
C_FILE = os.path.join(REPO, 'maincpu', 'c_src', 'style_ui_screendata_main.c')

def extract_bytes_from_s(path):
    """Parse all .byte directives and return flat list of byte values."""
    all_bytes = []
    with open(path, 'rb') as f:
        for line in f:
            line_str = line.decode('latin-1', errors='replace').strip()
            if not line_str.startswith('.byte'):
                continue
            # Strip comments
            if ';' in line_str:
                line_str = line_str[:line_str.index(';')]
            # Extract hex values
            for m in re.finditer(r'0x([0-9a-fA-F]{2})', line_str):
                all_bytes.append(int(m.group(1), 16))
    return all_bytes

def format_bytes_c(data, indent='\t\t', width=16):
    """Format byte array as C hex initializer lines."""
    lines = []
    for i in range(0, len(data), width):
        chunk = data[i:i+width]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'{indent}{hex_vals},')
    return '\n'.join(lines)

def main():
    raw = extract_bytes_from_s(S_FILE)
    total = len(raw)
    print(f"Extracted {total} bytes from {S_FILE}")

    if total != 3531:
        print(f"ERROR: Expected 3531 bytes, got {total}")
        sys.exit(1)

    # Define section boundaries (byte offsets, determined from .s file structure)
    # Section 1: Chord boxes - 4 boxes with HLINE/VLINE/REF (lines 37-59)
    # Each box: ~45 bytes. Box 1-3: 2H+2V+1R=45, Box 4: 2V+1R+2H=45
    chord_boxes_end = 180

    # Section 2: Grid lines - 3 rows × 9 segments (lines 69-97)
    # Each row: 5 VLINE(10) + 4 HLINE(10) = 90 bytes, 3 rows = 270
    grid_lines_end = chord_boxes_end + 270  # 450

    # Section 3: Row label refs (lines 103-109)
    # 3 REF_EX(10) + 3 REF(5) + 1 NOP(10) = 55
    row_labels_end = grid_lines_end + 55  # 505

    # Section 4: Control widgets (lines 115-124)
    # Complex interleaved data. Count bytes from .s:
    # Line 115: 15 bytes WIDGET
    # Lines 116-120: 16+16+16+16+1 = 65 bytes (mixed STRING + WIDGET data)
    # Line 122: 15 bytes WIDGET
    # Line 123: 15 bytes WIDGET
    # Line 124: 15 bytes WIDGET
    control_end = row_labels_end + 125  # 630

    # Section 5: Parameter value widgets - 24 widgets × 15 bytes (lines 134-157)
    param_widgets_end = control_end + 360  # 990

    # Section 6: Chord root/type/quality widgets (lines 171-265)
    # Row 1: 8 cells × 3 widgets/cell = 24 widgets, but cell 3 has sub=0x0d variant
    # Actually: 8 triplets × 3 rows = 72 widgets, but one has sub=0x14
    # Row 1 (lines 171-201): 8 cells × 3 widgets = 24 widgets × 15 = 360
    # Row 2 (lines 203-233): 8 cells × 3 + 1 sub=0x14 = 360
    # Row 3 (lines 235-265): 8 cells × 3 = 360
    chord_widgets_end = param_widgets_end + 1080  # 2070

    # Section 7: Chord root names table (32 bytes, lines 274-275)
    chord_roots_end = chord_widgets_end + 32  # 2102

    # Section 8: Chord type names table (242 bytes, lines 282-301)
    # 15 lines × 16 bytes + 1 line × 2 bytes = 240 + 2 = 242
    chord_types_end = chord_roots_end + 242  # 2344

    # Section 9: Footer labels and control (lines 307-309)
    # Line 307: 16 bytes
    # Line 308: 16 bytes
    # Line 309: 8 bytes = 40 bytes
    footer_end = chord_types_end + 40  # 2384

    # Section 10: SETUP blocks and coordinate arrays (lines 318-350)
    # First SETUP: 11 + 32 = 43 bytes
    # Second SETUP: 11 + 64 = 75 bytes
    # Third SETUP header (11 bytes spanning lines 330-333): 16+11 = 27 bytes
    # (the 0x03 at line 330 offset 0 starts at byte 2459)
    # Beat positions: 32 × 8 = 256 bytes
    # Plus CONTROL at end of line 350: 16 bytes partial
    # Total from first SETUP byte to end of beat positions + CONTROL start:
    # Let me just count from offset 2384 to the end
    # Remaining: 3531 - 2384 = 1147 bytes
    # This covers: SETUP blocks, CONTROL blocks, callback refs, bottom bar data,
    # chord bitmap, second widget set, bottom bar rectangles

    # For simplicity, group the remaining into larger logical sections:
    # SETUP+coords: complex, use single raw array
    # Let me split at clear boundaries:

    # After footer (offset 2384):
    # Lines 318-350: SETUP blocks + coords (variable)
    # Lines 356-358: Callback refs
    # Lines 365-369: Bottom bar data
    # Lines 377-380: Chord bitmap (64 bytes)
    # Lines 388-411: Second widget set
    # Lines 418-432: Bottom bar rectangles

    # Rather than trying to split precisely, group remaining into named sections
    # based on what I can verify. Let me compute from known data...

    # Actually, let me just output the remaining as one block and verify total.
    remaining = total - chord_types_end  # 3531 - 2344 = 1187

    sections = [
        ('chord_boxes',    0,                chord_boxes_end),
        ('grid_lines',     chord_boxes_end,  grid_lines_end),
        ('row_labels',     grid_lines_end,   row_labels_end),
        ('control_widgets', row_labels_end,  control_end),
        ('param_value_widgets', control_end, param_widgets_end),
        ('chord_rtq_widgets', param_widgets_end, chord_widgets_end),
        ('chord_root_names', chord_widgets_end, chord_roots_end),
        ('chord_type_names', chord_roots_end, chord_types_end),
        ('footer_and_controls', chord_types_end, total),
    ]

    # Verify sections cover all bytes
    assert sections[-1][2] == total

    # Generate C source
    lines = []
    lines.append('/**')
    lines.append(' * StyleUI_ScreenData_Main — Style UI Main Screen Layout')
    lines.append(' *')
    lines.append(' * Source: e0bb90_e0c95a.bin (3531 bytes)')
    lines.append(' *')
    lines.append(' * Screen layout for the accompaniment style editor main view.')
    lines.append(' * The 320x240 LCD is divided into:')
    lines.append(' *   - Top row (y=35): 4 chord name display boxes (HLINE/VLINE/REF)')
    lines.append(' *   - 3 parameter grid rows at y=80, 125, 170 with 4 columns each')
    lines.append(' *   - Row label references and control widgets')
    lines.append(' *   - 24 parameter value widgets (handler 0xe0bd98)')
    lines.append(' *   - 72 chord root/type/quality widgets (3 rows × 8 cells × 3 layers)')
    lines.append(' *   - Chord name tables: 12 root names + ~48 type names')
    lines.append(' *   - SETUP/CONTROL blocks with coordinate arrays')
    lines.append(' *   - Chord recognition bitmap (64 bytes)')
    lines.append(' *   - Track status widgets + bottom bar (8 FILLED_RECT + 6 HLINE)')
    lines.append(' */')
    lines.append('')
    lines.append('#include "screendata_types.h"')
    lines.append('')
    lines.append('typedef struct __attribute__((packed)) {')

    section_descs = {
        'chord_boxes': '4 chord name boxes (HLINE/VLINE/REF, y=35)',
        'grid_lines': '3×9 parameter grid lines (y=80, 125, 170)',
        'row_labels': 'Row label REF_EX + REF + NOP/PAD',
        'control_widgets': 'Control widgets (END REP, track status, cursor)',
        'param_value_widgets': '24 parameter value widgets (handler 0xe0bd98)',
        'chord_rtq_widgets': '72 chord root/type/quality widgets (3 rows)',
        'chord_root_names': 'Chord root names: C Db D Eb E F F# G Ab A Bb B',
        'chord_type_names': 'Chord type names (Maj7, aug, min, dim, etc.)',
        'footer_and_controls': 'Footer, SETUP/CONTROL blocks, chord bitmap, track status, bottom bar',
    }

    for name, start, end in sections:
        size = end - start
        desc = section_descs.get(name, '')
        lines.append(f'    uint8_t {name}[{size}];  /* {desc} */')
    lines.append('} screendata_main_t;')
    lines.append('')
    lines.append('_Static_assert(sizeof(screendata_main_t) == 3531,')
    lines.append('    "ScreenData_Main must be exactly 3531 bytes");')
    lines.append('')
    lines.append('const screendata_main_t StyleUI_ScreenData_Main')
    lines.append('    __attribute__((section(".text"), used)) = {')
    lines.append('')

    for name, start, end in sections:
        desc = section_descs.get(name, '')
        lines.append(f'    /* {desc} */')
        lines.append(f'    .{name} = {{')
        lines.append(format_bytes_c(raw[start:end]))
        lines.append('    },')
        lines.append('')

    lines.append('};')
    lines.append('')

    with open(C_FILE, 'w') as f:
        f.write('\n'.join(lines))

    print(f"Generated {C_FILE} ({total} bytes in {len(sections)} sections)")

if __name__ == '__main__':
    main()
