#!/usr/bin/env python3
"""
Extract more large inline code blocks from kn5000_v10_program.s into include files.

Round 2: Extract 4 additional blocks totaling ~6700 lines.
Each block is replaced with an .include directive pointing to a new file.
Binary I/O for Latin-1 safety.
"""

import os
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')
MAIN_FILE = os.path.join(MAINCPU_DIR, 'kn5000_v10_program.s')

# Blocks to extract: (start_line, end_line, dest_file, header_title, header_desc)
# Line numbers are 1-based inclusive
BLOCKS = [
    # Block A: 1884 lines of AC/Listener widget handlers + TtMd routines
    # Between midi/computer_interface_config.s and midi/sysex_routines.s
    (23428, 25311, 'midi/ac_listener_handlers.s',
     'AC/Listener Widget Handlers & TtMd Routines (1.9K lines)',
     [
         'AcLswFuncBoxProc event dispatch, parameter processing, mixer',
         'controls, button handlers, and TtMd (title mode) exclusion',
         'routines. Sits between computer interface config and SysEx.',
     ]),

    # Block B: 658 lines of parameter loading between sysex and ui_control_panel
    (25313, 25970, 'midi/param_load_routines.s',
     'Parameter Loading & Audio Flag Routines',
     [
         'ParaLoadOpt parameter loading options, audio flag processing,',
         'and event posting routines. Bridges SysEx processing to the',
         'UI control panel.',
     ]),

    # Block C: 1762 lines of presentation/SSF/sound navigation
    # Between ui/ui_control_panel.s and ui/ui_window_procs.s
    (25972, 27733, 'audio/presentation_sound_nav.s',
     'Presentation System & Sound Navigation (1.8K lines)',
     [
         'SSF presentation workspace building, sound navigation, voice',
         'control, presentation control proc, and visibility management.',
         'Routes between UI control panel and window procedures.',
     ]),

    # Block D: 1071 lines of ToneGen config and FileIO callback handlers
    # Between ui/cpanel_routines.s and audio/audio_control_engine.s
    (28700, 29770, 'audio/tonegen_fileio_handlers.s',
     'Tone Generator Config & File I/O Handlers (1K lines)',
     [
         'ToneGen_Config initialization, DSP configuration entry setup,',
         'FileIO callback handlers, and audio mode dispatch. Late-ROM',
         'routines before the main audio control engine.',
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
