#!/usr/bin/env python3
"""
Extract localization string sets from KN5000 ROM.

Parses the original ROM to find sets of 6 multilingual strings with their
pointer tables, and outputs properly formatted assembly syntax.

Each set contains:
- 6 strings (EN, DE, FR, ES, EN2, ID)
- 6 pointers (dd table)
"""

import struct
import sys
from pathlib import Path

# Language codes in order they appear in the ROM
LANG_CODES = ['EN', 'DE', 'FR', 'ES', 'IT', 'ID']
LANG_NAMES = ['English', 'German', 'French', 'Spanish', 'Italian/Duplicate', 'Indonesian']

# ROM base address
ROM_BASE = 0xE00000

# Known localization string sets (pointer table addresses)
# Format: (pointer_table_addr, set_name)
KNOWN_SETS = [
    # Original dialog strings (0xE1Exxx region) - EN/EN2 duplicate pattern
    (0xE1E516, 'Attention'),
    (0xE1E596, 'AreYouSure'),
    (0xE1E994, 'CustomSoundWillBeCopied'),
    (0xE1EA88, 'SoundGroupAffected'),
    (0xE1ED64, 'CustomSoundMemoryFull'),
    (0xE1EE2C, 'CustomRhythmsAffected'),
    (0xE1EF42, 'InsertStyleConvertDisk'),
    # Sequencer/MIDI dialog strings (0xE26xxx region) - EN/EN2 duplicate pattern
    (0xE26078, 'SequencerTrackHelp'),
    (0xE26090, 'AfterTouchRecording'),
    (0xE260A8, 'SongWillBeCleared'),
    (0xE260C0, 'Attention2'),  # Duplicate strings
    (0xE260D8, 'AreYouSure2'),  # Duplicate strings
    (0xE260F0, 'GeneralMidiModeOn'),
    (0xE26108, 'GeneralMidiModeOff'),
    # MIDI mode strings (0xE7Fxxx region) - duplicates
    (0xE7F34E, 'GeneralMidiModeOn2'),
    (0xE7F5C6, 'GeneralMidiModeOff2'),
    # Sequencer help strings (0xE34xxx region) - ITALIAN placeholder pattern
    # These have "ITALIAN" literal in EN2 slot (Italian was never translated)
    (0xE344D4, 'AreYouSure_IT'),
    (0xE344EC, 'Attention_IT'),
    (0xE34504, 'FeaturesCreatingSong'),
    (0xE3451C, 'FeaturesEditingSong'),
    (0xE34534, 'EasyRecordHelp'),
    (0xE3454C, 'PressOkToProceed'),
    (0xE34564, 'PanelWriteHelp'),
    (0xE3457C, 'TrackSelectHelp'),
    (0xE34594, 'TrackClearConfirm'),
    (0xE345AC, 'StepRecordTrackHelp'),
    (0xE345C4, 'TrackClearWarning'),
    (0xE345DC, 'SongClearWarning'),
    (0xE345F4, 'PressStartStopToBegin'),
]


def read_rom(rom_path):
    """Read the ROM file."""
    with open(rom_path, 'rb') as f:
        return f.read()


def get_byte(rom, addr):
    """Get a byte from ROM at the given address."""
    offset = addr - ROM_BASE
    if 0 <= offset < len(rom):
        return rom[offset]
    return None


def get_dword(rom, addr):
    """Get a 32-bit little-endian value from ROM."""
    offset = addr - ROM_BASE
    if 0 <= offset + 3 < len(rom):
        return struct.unpack('<I', rom[offset:offset+4])[0]
    return None


def extract_string(rom, addr):
    """Extract a null-terminated string from ROM, returning (string_bytes, length)."""
    offset = addr - ROM_BASE
    result = bytearray()

    while offset < len(rom):
        byte = rom[offset]
        result.append(byte)
        offset += 1
        if byte == 0x00:
            # Check for trailing 0xFF padding
            if offset < len(rom) and rom[offset] == 0xFF:
                result.append(0xFF)
            break

    return bytes(result), len(result)


def format_string_as_asm(data):
    """Format string bytes as ASM db statement with proper string literals."""
    result_parts = []
    current_string = ""

    i = 0
    while i < len(data):
        byte = data[i]

        # Printable ASCII (excluding quote and backslash)
        if 0x20 <= byte <= 0x7E and byte not in (0x22, 0x5C):
            current_string += chr(byte)
        else:
            # Flush current string
            if current_string:
                result_parts.append(f'"{current_string}"')
                current_string = ""
            # Add hex byte
            result_parts.append(f'0{byte:02X}h')

        i += 1

    # Flush remaining string
    if current_string:
        result_parts.append(f'"{current_string}"')

    return ', '.join(result_parts)


def extract_string_set(rom, ptr_table_addr, set_name):
    """Extract a complete localization string set."""
    strings = []
    pointers = []

    # Read 6 pointers from the table
    for i in range(6):
        ptr = get_dword(rom, ptr_table_addr + i * 4)
        if ptr is None:
            return None
        pointers.append(ptr)

    # Extract each string
    for i, ptr in enumerate(pointers):
        data, length = extract_string(rom, ptr)
        strings.append({
            'addr': ptr,
            'data': data,
            'length': length,
            'lang_code': LANG_CODES[i],
            'lang_name': LANG_NAMES[i],
        })

    return {
        'name': set_name,
        'ptr_table_addr': ptr_table_addr,
        'pointers': pointers,
        'strings': strings,
    }


def generate_asm_output(string_set, use_address_labels=False):
    """Generate assembly output for a string set."""
    lines = []
    set_name = string_set['name']

    # Comment header
    lines.append(f'\t; Localization: {set_name} (6 languages)')

    # Generate string definitions
    for s in string_set['strings']:
        addr = s['addr']
        lang_code = s['lang_code']
        lang_name = s['lang_name']
        data = s['data']
        length = s['length']

        if use_address_labels:
            label = f"LABEL_{addr:06X}"
        else:
            label = f"Localization_{set_name}_{lang_code}"
        asm_string = format_string_as_asm(data)

        lines.append(f'{label}:\tdb {asm_string}\t; {lang_name} ({length} bytes)')

    # Generate pointer table
    ptr_table_addr = string_set['ptr_table_addr']
    if use_address_labels:
        lines.append(f'\t; Pointer table at 0x{ptr_table_addr:06X}')
    else:
        lines.append(f'\t; Pointer table for {set_name}')
    for i, s in enumerate(string_set['strings']):
        addr = s['addr']
        lang_code = s['lang_code']
        if use_address_labels:
            label = f"LABEL_{addr:06X}"
        else:
            label = f"Localization_{set_name}_{lang_code}"
        lines.append(f'\tdd {label}')

    return '\n'.join(lines)


def find_string_sets(rom, start_addr, end_addr):
    """
    Scan ROM range for potential pointer tables.
    A valid pointer table has 6 consecutive pointers that:
    - Are in the E1E000-E1F000 range
    - Point to addresses before the table itself
    - Are in ascending order
    """
    found_sets = []
    addr = start_addr

    while addr < end_addr - 24:  # Need 24 bytes for 6 pointers
        # Try to read 6 pointers
        pointers = []
        valid = True

        for i in range(6):
            ptr = get_dword(rom, addr + i * 4)
            if ptr is None or ptr < 0xE1E000 or ptr > 0xE1FFFF:
                valid = False
                break
            if ptr >= addr:  # Pointers should point before the table
                valid = False
                break
            pointers.append(ptr)

        if valid and len(pointers) == 6:
            # Check if pointers are roughly in order (with some tolerance for languages)
            # and all point to null-terminated strings
            all_strings_valid = True
            for ptr in pointers:
                data, length = extract_string(rom, ptr)
                if length < 2 or length > 500:  # Reasonable string length
                    all_strings_valid = False
                    break

            if all_strings_valid:
                found_sets.append({
                    'ptr_table_addr': addr,
                    'pointers': pointers,
                })
                addr += 24  # Skip past this table
                continue

        addr += 1

    return found_sets


def main():
    rom_path = Path('original_ROMs/kn5000_v10_program.rom')

    if not rom_path.exists():
        print(f"Error: ROM file not found: {rom_path}")
        sys.exit(1)

    # Check for --address-labels flag
    use_address_labels = '--address-labels' in sys.argv

    rom = read_rom(rom_path)
    print(f"; Localization strings extracted from {rom_path}")
    print(f"; Generated by extract_localization_strings.py")
    print()

    # Process known sets
    for ptr_table_addr, set_name in KNOWN_SETS:
        string_set = extract_string_set(rom, ptr_table_addr, set_name)
        if string_set:
            print(generate_asm_output(string_set, use_address_labels))
            print()
            print()  # Double blank line between sets
        else:
            print(f"; ERROR: Could not extract set '{set_name}' at 0x{ptr_table_addr:06X}")
            print()


if __name__ == '__main__':
    main()
