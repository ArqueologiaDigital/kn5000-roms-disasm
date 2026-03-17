#!/usr/bin/env python3
"""
Extract large inline code blocks from kn5000_v10_program.s into include files.

Each block is replaced with an .include directive pointing to a new file
in the appropriate subsystem directory. Binary I/O for Latin-1 safety.
"""

import os
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')
MAIN_FILE = os.path.join(MAINCPU_DIR, 'kn5000_v10_program.s')

# Blocks to extract: (start_line, end_line, dest_file, header_title, header_desc)
# Line numbers are 1-based inclusive
BLOCKS = [
    # Block 1: 5195 lines of sequencer/tone-gen code between smf_playback and smf_event_processor
    (24214, 29407, 'sequencer/smf_tonegen_core.s',
     'SMF Tone Generation & Voice Synthesis Core (5K lines)',
     [
         'Sequencer-driven tone generation: floppy I/O integration, SMF track',
         'event parsing, voice channel management, tone generator block writes,',
         'voice synthesis algorithm dispatch, and voice parameter updates.',
         'Sits in the ROM between SMF playback and SMF event processing.',
     ]),

    # Block 4: 3042 lines of UI state/playback mode code between setwall and demo
    (20110, 23151, 'ui/ui_playback_modes.s',
     'UI Playback Mode Handlers (3K lines)',
     [
         'UI state event handling and playback mode control: voice parameter',
         'handlers, sequencer timer/tempo, part validation, play/song/medley',
         'mode dispatch, part format handlers, and display mode transitions.',
     ]),

    # Block 2: 4220 lines of sequencer event/accompaniment code between factory defaults and computer interface
    (31660, 35879, 'sequencer/seq_event_playback.s',
     'Sequencer Event Playback & Accompaniment (4K lines)',
     [
         'Sequencer event buffer processing, voice slot scanning, note/channel',
         'decoding, accompaniment playback loop, tempo event dispatch, MIDI',
         'sustain handling, accompaniment mute queuing, and ring buffer management.',
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
