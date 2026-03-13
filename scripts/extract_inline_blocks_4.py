#!/usr/bin/env python3
"""
Extract more large inline code blocks from kn5000_v10_program.s into include files.

Round 4: Extract 4 additional blocks totaling ~5,800 lines.
Binary I/O for Latin-1 safety.
"""

import os
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')
MAIN_FILE = os.path.join(MAINCPU_DIR, 'kn5000_v10_program.s')

# Blocks to extract: (start_line, end_line, dest_file, header_title, header_desc)
# Line numbers are 1-based inclusive
BLOCKS = [
    # Block A: 1909 lines of NAKA widget pointer tables
    # Between ui_widgets/e2107c_e24034.s and ui_widgets/e27408_e27556.s
    (3073, 4981, 'ui_widgets/naka_widget_tables_1.s',
     'NAKA Widget Pointer Tables - Part 1 (1.9K lines)',
     [
         'Widget pointer tables for SmfDp, DocDp, PdDp, KssDp, DrumDp',
         'screen groups. NAKA type headers and NakaInst/NakaDesc references.',
     ]),

    # Block B: 1668 lines of NAKA widget data + string tables
    # Between ui_widgets/e55e38_e5a38e.s and ui_widgets/e812e8_e818e6.s
    (5341, 7008, 'ui_widgets/naka_widget_tables_2.s',
     'NAKA Widget Pointer Tables - Part 2 (1.7K lines)',
     [
         'Widget data tables including CtlMsgGridBox, MidiControlMessage,',
         'and additional NAKA type headers. Continuation of widget',
         'definition data.',
     ]),

    # Block C: 1177 lines of Scoop/display parameter data
    # Between display/scoop_display.s and audio/semenu_routines.s
    (7793, 8969, 'display/scoop_editor_data.s',
     'Scoop Editor & Display Parameter Data (1.2K lines)',
     [
         'Sound editor display data, performance mode parameter',
         'bytecode, Scoop oscilloscope editor configuration tables,',
         'and display dirty-region data.',
     ]),

    # Block D: 1060 lines of demo/sequencer processing
    # Between demo/demo_routines.s and sequencer/smf_playback.s
    (9423, 10482, 'demo/demo_seq_bridge.s',
     'Demo-to-Sequencer Bridge & Playback Init (1K lines)',
     [
         'MiddleFuncCall dispatcher, SqTrSel (sequencer track select),',
         'demo sequence playback initialization, and SMF node/slot',
         'resolution. Bridges demo mode to sequencer engine.',
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
        extracted = all_lines[start - 1:end]
        header = make_header(title, desc)

        dest_path = os.path.join(MAINCPU_DIR, dest)
        dest_dir = os.path.dirname(dest_path)
        if not os.path.exists(dest_dir):
            os.makedirs(dest_dir)

        with open(dest_path, 'wb') as f:
            f.write(header)
            f.write(b'\n'.join(extracted))
            if not extracted[-1].endswith(b'\n'):
                f.write(b'\n')

        include_line = f'.include "{dest}"'.encode('ascii')
        all_lines[start - 1:end] = [include_line]

        print(f'  Extracted {end - start + 1} lines -> {dest}')
        print(f'  Replaced with .include at line {start}')

    with open(MAIN_FILE, 'wb') as f:
        f.write(b'\n'.join(all_lines))

    print(f'\nMain file: {len(all_lines)} lines (was {len(content.split(b"\n"))})')
    print('Done! Run: make clean && make all')


if __name__ == '__main__':
    main()
