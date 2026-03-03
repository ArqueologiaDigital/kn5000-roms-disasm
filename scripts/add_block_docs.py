#!/usr/bin/env python3
"""Add documentation comments to recently-decoded .byte blocks in the main program.

These blocks were converted from .byte to native instructions by
convert_roundtrip_blocks.py but lacked documentation per project policy.
Uses binary I/O to safely handle Latin-1 characters.
"""

import os

# Each entry: (label, comment_lines_to_insert_before_label)
BLOCK_DOCS = [
    ('LABEL_F21181', [
        '; --- DisplayMode_BatchEventSend: Dispatch events for display mode transitions ---',
        '; Multiple entry points, each dispatching 2-3 events for a specific mode.',
        '; Pattern per entry: XWA=event_id, XBC=0x1E0043B (target), XDE=0 (param),',
        ';   then call EventDispatch (0xFAC558) or jump to common tail.',
        '; Event IDs encode mode/sub-function: 0x6F000A, 0x70000x, 0x73000C, etc.',
    ]),

    ('LABEL_F3588C', [
        '; --- EQ_7Band_ParamLookup: Look up equalizer parameters for 7 frequency bands ---',
        '; Seven entry points, one per EQ band. Each reads a 16-bit index from',
        '; consecutive RAM addresses (0x297A-0x2986), doubles it as a table offset,',
        '; adds to the base pointer in XBC/XDE, loads a 16-bit value, and jumps',
        '; to a common handler. Alternates between XBC and XDE base registers.',
    ]),

    ('LABEL_F7B4F1', [
        '; --- Bitmap_QueryProperties: Return dimensions/data for 3 bitmap resources ---',
        '; Three identical query handlers. Each checks XBC for property ID:',
        ';   0x1E000A1 -> return data pointer (lda_24 xhl, addr)',
        ';   0x1E000A2 -> return width  (XHL = 22)',
        ';   0x1E000A3 -> return height (XHL = 222)',
        ';   other     -> return 0 (not handled)',
        '; The three copies reference different bitmap data addresses:',
        ';   0xE8E66A, 0xE8F97E, 0xE90C92 (in Table Data ROM).',
    ]),

    ('LABEL_F8686B', [
        '; --- LinkedList_SearchInsert: Search and insert into a 24-byte-node list ---',
        '; Two routines sharing this label block:',
        '; 1) Search: Walks a fixed-size array at 0x249D8 (up to 63 entries,',
        ';    24 bytes each). Calls compare function (0xFF3F35) for each node.',
        ';    Returns pointer to matching entry or falls through.',
        '; 2) Insert: Walks the same list checking node+16 for empty slot,',
        ';    calls insert function (0xFF3F4D), returns success (HL=1) or fail.',
    ]),

    ('LABEL_FD26BC', [
        '; --- FileData_LoadAndParse: Allocate buffer, load file, dispatch by format ---',
        '; Allocates 32-byte buffer via malloc (0xFF3E80). On failure returns 0xFF38.',
        '; Reads data into buffer via (0xF89A74), then dispatches based on format type:',
        ';   type 1: calls local handler (+108 bytes)',
        ';   type 2: calls local handler (+557 bytes), chains to secondary (+7610)',
        ';   type 3: calls local handler (+7252 bytes), chains to secondary (+7610)',
        '; On any sub-handler failure (negative result), returns error.',
        '; Frees buffer via (0xFF3AF2) before returning status in HL.',
    ]),

    ('LABEL_FD9DA0', [
        '; --- MIDI_BuildControlPacket: Construct a 4-byte MIDI control packet ---',
        '; Two entry points building MIDI packets from a parameter structure (XIZ):',
        '; 1) Full packet: reads MIDI map value from table at 0xBCCC (via 0xFD6EB6),',
        ';    adjusts by subtracting 0x20, ORs with (xiz+6) for status byte,',
        ';    copies controller number from *(xiz+7), computes data byte via',
        ';    lookup (0xFD822D), copies channel from (xiz+8).',
        '; 2) Simple packet: same status byte construction but data byte 2 = 0.',
        '; Output: 4-byte packet pointer + source struct pointer stored to (XWA).',
    ]),
]


def main():
    src = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        data = f.read()

    lines = data.split(b'\n')
    new_lines = []
    count = 0

    # Build lookup dict for fast matching
    doc_map = {label: comments for label, comments in BLOCK_DOCS}

    for line in lines:
        line_str = line.decode('latin-1').rstrip()

        # Check if this line is a documented label
        for label, comments in doc_map.items():
            if line_str == label + ':':
                for comment in comments:
                    new_lines.append(comment.encode('latin-1'))
                count += 1
                break

        new_lines.append(line)

    with open(src, 'wb') as f:
        f.write(b'\n'.join(new_lines))

    print(f'Added documentation comments to {count} blocks')


if __name__ == '__main__':
    main()
