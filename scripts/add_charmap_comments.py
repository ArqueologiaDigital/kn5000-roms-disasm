#!/usr/bin/env python3
"""Add descriptive comments to character mapping tables in the main program.

The region EEC288-EED198 contains 30 character mapping tables, each exactly
128 bytes. These are permutation tables mapping keyboard scan codes to
character codes for the text input system. Different tables correspond to
different keyboard layouts or input modes.

The pointer table at EF0319 references these tables in pairs, likely
(forward mapping, reverse mapping) for each input mode.

Uses binary I/O to safely handle Latin-1 characters in kn5000_v10_program.s.
"""

import os

# Table labels with their known characteristics
# Format: (label, description)
# Tables come in 128-byte blocks. Some are "full" (all 128 values used),
# some are "sparse" (0xFF marks unmapped positions).
TABLES = {
    'LABEL_EEC288': 'Character mapping table - preamble/header (sparse)',
    'LABEL_EEC318': 'Character mapping table - default mode (sparse, 6 refs in pointer table)',
    'LABEL_EEC398': 'Character mapping table - mode 1 forward (sparse)',
    'LABEL_EEC418': 'Character mapping table - mode 2 forward (sparse)',
    'LABEL_EEC498': 'Character mapping table - mode 3 forward (sparse)',
    'LABEL_EEC518': 'Character mapping table - mode 4 forward (sparse)',
    'LABEL_EEC598': 'Character mapping table - mode 5 forward (sparse)',
    'LABEL_EEC618': 'Character mapping table - mode 6 forward (sparse)',
    'LABEL_EEC698': 'Character mapping table - mode 6 reverse (sparse)',
    'LABEL_EEC718': 'Character mapping table - mode 2 reverse (sparse)',
    'LABEL_EEC798': 'Character mapping table - mode 3 reverse (sparse)',
    'LABEL_EEC818': 'Character mapping table - mode 4 reverse (sparse)',
    'LABEL_EEC898': 'Character mapping table - mode 5 reverse (sparse)',
    'LABEL_EEC918': 'Character mapping table - mode 7 (sparse)',
    'LABEL_EEC998': 'Character mapping table - mode 8 (sparse)',
    'LABEL_EECA18': 'Character mapping table - mode 9 forward (sparse)',
    'LABEL_EECA98': 'Character mapping table - mode 9 reverse (sparse)',
    'LABEL_EECB18': 'Character mapping table - mode 10 (sparse)',
    'LABEL_EECB98': 'Character mapping table - full permutation variant A',
    'LABEL_EECC18': 'Character mapping table - full permutation variant B',
    'LABEL_EECC98': 'Character mapping table - full permutation variant C',
    'LABEL_EECD18': 'Character mapping table - full permutation variant D (sequential layout)',
    'LABEL_EECD98': 'Character mapping table - full permutation variant E',
    'LABEL_EECE18': 'Character mapping table - full permutation variant F (sequential layout)',
    'LABEL_EECE98': 'Character mapping table - full permutation variant G',
    'LABEL_EECF18': 'Character mapping table - full permutation variant H',
    'LABEL_EECF98': 'Character mapping table - full permutation variant I',
    'LABEL_EED018': 'Character mapping table - full permutation variant J (sequential layout)',
    'LABEL_EED098': 'Character mapping table - full permutation variant K',
    'LABEL_EED118': 'Character mapping table - full permutation variant L (sequential layout)',
}

# Section header to add before the first table
SECTION_HEADER = """; =============================================================================
; Character Mapping Tables (EEC288-EED198)
; =============================================================================
; 30 tables of 128 bytes each, mapping keyboard scan codes to character codes.
; Used by the text input system for different keyboard layouts/input modes.
; Sparse tables use 0xFF for unmapped scan code positions.
; Full permutation tables contain all values 0x00-0x7F in shuffled order.
; The pointer table at EF0319 references these in pairs (forward/reverse).
; =============================================================================
"""


def main():
    src = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        data = f.read()

    lines = data.split(b'\n')
    new_lines = []
    count = 0
    section_header_added = False

    for line in lines:
        line_str = line.decode('latin-1').rstrip()

        # Check if this line is a table label
        for label, desc in TABLES.items():
            if line_str == label + ':':
                # Add section header before the very first table
                if not section_header_added:
                    for hdr_line in SECTION_HEADER.strip().split('\n'):
                        new_lines.append(hdr_line.encode('latin-1'))
                    section_header_added = True

                # Add comment before this table
                comment = f'; {desc}'
                new_lines.append(comment.encode('latin-1'))
                count += 1
                break

        new_lines.append(line)

    with open(src, 'wb') as f:
        f.write(b'\n'.join(new_lines))

    print(f'Added {count} table comments + section header')


if __name__ == '__main__':
    main()
