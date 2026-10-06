#!/usr/bin/env python3
"""Decode the KN5000 panel-work-area (.LSW payload) schema straight out of the ROM.

QUESTION ANSWERED
-----------------
"The .LSW file is a tag/length/value stream -- but is that framing real, or just a
shape the data happens to have?  And what do the records mean?"

It is real, and the firmware carries the schema as data.  The panel work area that the
.LSW writer dumps (0x00F980..0x00FFC0, see docs/kn-disk-file-formats.md) is itself a
TLV stream, laid out by two ROM tables:

    NakaInst_ExtDevice_Screens_0x2814 = 0xED8FE0 -- 46 entries, base 0x00F9A0
    NakaInst_ExtDevice_Screens_0x29E0 = 0xED91AC -- 30 entries, base 0x00FD60

Each table entry is 10 bytes:

    +0  u32  byte offset of the record from the table's base
    +4  u32  ROM pointer to that record's FIELD-DESCRIPTOR LIST
    +8  u8   TAG          <- byte 0 of the record in RAM (and in the file)
    +9  u8   PAYLOAD LEN  <- byte 1 of the record in RAM (and in the file)

Consumers, all in audio/tonegen_fileio_handlers.s:
    PanelTlv_WriteRecordHeader   writes tag to base+off and len to base+off+1
    PanelTlv_ValidateRecord       takes base+off+2 as the payload and walks the descriptor list
    PanelTlv_WriteBlock0Headers / PanelTlv_ValidateBlock0   loop 46 entries over base 0xF9A0
    PanelTlv_WriteBlock1Headers   / PanelTlv_ValidateBlock1   loop 30 entries over base 0xFD60

The last entry of each table has tag=0xFF len=0xFF: that is the `FF FF` block terminator
the .LSW parser sees.  RESOURCE_INFO_HANDLERS (kn5000_v9_program.s) defines the saved
region as 0xF980 .. (0xFFBE + 2), i.e. it ends AT the second block's terminator.

FIELD DESCRIPTOR GRAMMAR (byte 0 = type; list ends at 0xFF)
    0,1,2 : 3 bytes  -- type, payload offset, bit mask
    3,4   : 6 bytes  -- type, payload offset, bit mask, min, max, default
    5,6   : n+5      -- type, offset, mask, count, <count value bytes>
    7     : 3 bytes  -- type, payload offset, default value (whole byte, no mask)
    8     : 2 bytes  -- type, payload offset (plain byte, no mask, no default)
CORRECTED 2026-10-06 from PanelTlv_ApplyFieldRule's nine cases (the parse lengths above are right):
    4 resets the field when it is INSIDE lo..hi (3 when outside), so "min, max" fits type 3 only;
    5,6 are type, offset, mask, count, DEFAULT, <count values> (5: reset unless listed, 6: if listed);
    8 sets the byte to 0.  See README-lsw-panel-schema.md and
    scripts/converters/panel_tlv_schema_retype.py.

PASS = the two tables tile 0xF9A0..0xFFC0 with no gap and no overlap, both terminators
land where the firmware says, and every descriptor list parses to exactly the byte span
between consecutive list pointers.  Exits non-zero otherwise.

    python3 analysis/disk-format-probes/lsw_panel_schema_from_rom.py
    python3 analysis/disk-format-probes/lsw_panel_schema_from_rom.py --quiet
"""
import os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(HERE, '..', '..', 'original_ROMs', 'kn5000_v7_program.rom')
LOAD = 0xE00000

TABLES = (
    ('BLOCK-0 (main panel)', 0xED8FE0, 46, 0xF9A0),
    ('BLOCK-1 (aux panel)',  0xED91AC, 30, 0xFD60),
)
REGION_START = 0xF980   # first byte the .LSW writer saves (32-byte header precedes the TLV)
TLV_START    = 0xF9A0
REGION_END   = 0xFFC0   # exclusive; == second terminator + 2

DESC_FIXED = {0: 3, 1: 3, 2: 3, 3: 6, 4: 6, 7: 3, 8: 2}


def parse_descriptors(rom, addr):
    """Return (list_of_fields, total_byte_length_including_the_0xFF)."""
    out, p = [], addr
    while True:
        t = rom[p - LOAD]
        if t == 0xFF:
            p += 1
            break
        if t in DESC_FIXED:
            n = DESC_FIXED[t]
            rec = [t, rom[p - LOAD + 1]]
            if n >= 3:
                rec.append(rom[p - LOAD + 2])
            if n == 6:
                rec.extend(rom[p - LOAD + 3:p - LOAD + 6])
            out.append(tuple(rec))
            p += n
        elif t in (5, 6):
            n = rom[p - LOAD + 3] + 5
            out.append((t, rom[p - LOAD + 1], rom[p - LOAD + 2], 'var%d' % rom[p - LOAD + 3]))
            p += n
        else:
            out.append(('BADTYPE', t))
            p += 1
        if p - addr > 4096:
            out.append(('OVERRUN',))
            break
    return out, p - addr


def entries(rom, addr, count, base):
    out = []
    for i in range(count):
        o = addr - LOAD + 10 * i
        off, ptr = struct.unpack_from('<II', rom, o)
        out.append((base + off, ptr, rom[o + 8], rom[o + 9]))
    return out


def fmt_field(f):
    if f[0] == 8:
        return 't8:+%02X' % f[1]
    if f[0] == 7:
        return 't7:+%02X def=%d' % (f[1], f[2])
    if len(f) == 3:
        return 't%d:+%02X/%02X' % (f[0], f[1], f[2])
    if len(f) == 6:
        return 't%d:+%02X/%02X min=%d max=%d def=%d' % (f[0], f[1], f[2], f[3], f[4], f[5])
    return str(f)


def main():
    quiet = '--quiet' in sys.argv
    rom = open(ROM_PATH, 'rb').read()
    fail = []
    cursor = TLV_START
    all_ptrs = []

    for name, addr, count, base in TABLES:
        if not quiet:
            print('######## %s: %d entries @0x%06X, base 0x%04X ########' % (name, count, addr, base))
        if base != cursor:
            fail.append('%s starts at 0x%04X but previous block ended at 0x%04X' % (name, base, cursor))
        for st, ptr, tag, ln in entries(rom, addr, count, base):
            all_ptrs.append(ptr)
            if st != cursor:
                fail.append('tag 0x%02X at 0x%04X, expected 0x%04X (gap/overlap)' % (tag, st, cursor))
                cursor = st
            if tag == 0xFF:
                if not quiet:
                    print('tag FF  BLOCK TERMINATOR @0x%04X' % st)
                cursor += 2
                continue
            fields, flen = parse_descriptors(rom, ptr)
            if any(f[0] in ('BADTYPE', 'OVERRUN') for f in fields):
                fail.append('tag 0x%02X: descriptor list @0x%06X did not parse' % (tag, ptr))
            if not quiet:
                print('tag %02X len %02X @0x%04X..0x%04X  fields@0x%06X (%dB): %s'
                      % (tag, ln, st, st + 1 + ln, ptr, flen,
                         '  '.join(fmt_field(f) for f in fields)))
            cursor += 2 + ln
        if not quiet:
            print()

    if cursor != REGION_END:
        fail.append('schema covers 0x%04X..0x%04X, firmware saves ..0x%04X' % (TLV_START, cursor, REGION_END))

    # descriptor lists must be contiguous where consecutive pointers differ
    for a, b in zip(sorted(set(all_ptrs)), sorted(set(all_ptrs))[1:]):
        _, n = parse_descriptors(rom, a)
        # lists are padded to an even address, so one trailing 0xFF filler is legal
        if n != b - a and n + 1 != b - a:
            fail.append('descriptor list @0x%06X parsed %d bytes, next list starts %d later' % (a, n, b - a))

    print('region 0x%04X..0x%04X = 0x%02X header + 0x%03X TLV; schema ends at 0x%04X'
          % (REGION_START, REGION_END, TLV_START - REGION_START, cursor - TLV_START, cursor))
    if fail:
        print('FAIL:')
        for f in fail:
            print('  ' + f)
        return 1
    print('PASS: both schema tables tile 0x%04X..0x%04X exactly, all descriptor lists parse.'
          % (TLV_START, REGION_END))
    return 0


if __name__ == '__main__':
    sys.exit(main())
