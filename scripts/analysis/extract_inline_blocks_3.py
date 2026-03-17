#!/usr/bin/env python3
"""
Extract more large inline code blocks from kn5000_v10_program.s into include files.

Round 3: Extract 5 additional blocks totaling ~12,700 lines.
These are mostly NAKA widget data tables, multilingual strings,
and audio/sequencer processing code.
Binary I/O for Latin-1 safety.
"""

import os
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')
MAIN_FILE = os.path.join(MAINCPU_DIR, 'kn5000_v10_program.s')

# Blocks to extract: (start_line, end_line, dest_file, header_title, header_desc)
# Line numbers are 1-based inclusive
BLOCKS = [
    # Block 1: 3658 lines of TechniChord data + UI string tables
    # Between ui_widgets/e81cce_e85f46.s and ui_widgets/ea13cc_ea8c9e.s
    (9569, 13226, 'ui_widgets/technichord_string_data.s',
     'TechniChord & UI String Data Tables (3.7K lines)',
     [
         'TechniChord style dispatch tables, style name strings,',
         'dialog text, multilingual UI strings, and NakaModule',
         'handler pointer tables.',
     ]),

    # Block 2: 2344 lines of multilingual disk warning strings
    # Between ui_widgets/ea13cc_ea8c9e.s and ui_widgets/block_012.s
    (13228, 15571, 'ui_widgets/disk_warning_strings.s',
     'Multilingual Disk Operation Warning Strings (2.3K lines)',
     [
         'Disk format, file delete, and file operation warning',
         'messages in English, Spanish, German, French, Indonesian,',
         'and Italian. Includes pointer tables for each dialog.',
     ]),

    # Block 3: 2396 lines of widget name strings + char encoding + NAKA state
    # Between ui_widgets/block_012.s and ui_widgets/eb2afe_eb71be.s
    (15573, 17968, 'ui_widgets/widget_names_charmap.s',
     'Widget Name Strings & Character Map Data (2.4K lines)',
     [
         'Widget type name strings (VwUserBitmap, TrChordBox, etc.),',
         'character encoding/mapping tables, NAKA presentation root',
         'state, and widget type identifier data.',
     ]),

    # Block 4: 2295 lines of NAKA screen dispatch tables
    # Between ui_widgets/e1ab58_e1b7d2.s and factory_test/test_data.s
    (2402, 4696, 'ui_widgets/naka_screen_dispatch.s',
     'NAKA Screen Dispatch Tables (2.3K lines)',
     [
         'Screen definition tables for SeqToComposer, SeqCopy,',
         'EasyComposer, ModeSelect, ExpandMode, and other screen',
         'layouts. Pointer tables for widget instantiation.',
     ]),

    # Block 5: 2010 lines of sequencer audio mode processing
    # Between sequencer/smf_event_processor.s and sequencer/rhythm_routines.s
    (21176, 23185, 'sequencer/seq_audio_mode.s',
     'Sequencer Audio Mode & Accompaniment Processing (2K lines)',
     [
         'Audio mode stereo flags, accompaniment pedal processing,',
         'sequencer timing setup, part activation, and audio flag',
         'dispatch between SMF event processing and rhythm routines.',
     ]),
]


def make_header(title, desc_lines):
    bar = b'; ' + b'=' * 77 + b'\n'
    lines = [bar]
    lines.append(f'; {title}\n'.encode('ascii'))
    lines.append(bar)
    lines.append(b';\n')
    for line in desc_lines:
        lines.append(f'; {line}\n'.encode('ascii'))
    lines.append(bar)
    lines.append(b'\n')
    return b''.join(lines)


def main():
    with open(MAIN_FILE, 'rb') as f:
        content = f.read()

    all_lines = content.split(b'\n')
    print(f'Main file: {len(all_lines)} lines')

    # Process blocks from LAST to FIRST to preserve line numbers
    sorted_blocks = sorted(BLOCKS, key=lambda b: -b[0])

    for start, end, dest, title, desc in sorted_blocks:
        # Extract lines (0-based indexing)
        extracted = all_lines[start - 1:end]

        # Create header
        header = make_header(title, desc)

        # Write new file
        dest_path = os.path.join(MAINCPU_DIR, dest)
        dest_dir = os.path.dirname(dest_path)
        if not os.path.exists(dest_dir):
            os.makedirs(dest_dir)

        with open(dest_path, 'wb') as f:
            f.write(header)
            f.write(b'\n'.join(extracted))
            # Ensure file ends with newline
            if not extracted[-1].endswith(b'\n'):
                f.write(b'\n')

        # Replace extracted lines with .include directive
        include_line = f'.include "{dest}"'.encode('ascii')
        all_lines[start - 1:end] = [include_line]

        print(f'  Extracted {end - start + 1} lines -> {dest}')
        print(f'  Replaced with .include at line {start}')

    # Write modified main file
    with open(MAIN_FILE, 'wb') as f:
        f.write(b'\n'.join(all_lines))

    print(f'\nMain file: {len(all_lines)} lines (was {len(content.split(b"\n"))})')
    print('Done! Run: make clean && make all')


if __name__ == '__main__':
    main()
