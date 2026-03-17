#!/usr/bin/env python3
"""Convert .incbin sound data files to structured .s assembly source files.

Replaces opaque binary blobs in maincpu/includes/ with readable, commented
assembly data in maincpu/audio/ (sound data) or maincpu/includes/ (UI/misc data).

Updates kn5000_v10_program.s to use .include instead of .incbin.
Uses binary I/O throughout to preserve Latin-1 characters in the main .s file.
"""

import os
import struct
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAINCPU = os.path.join(REPO, 'maincpu')
INCLUDES_DIR = os.path.join(MAINCPU, 'includes')
AUDIO_DIR = os.path.join(MAINCPU, 'audio')
MAIN_S = os.path.join(MAINCPU, 'kn5000_v10_program.s')

# Category names for the 18 standard categories (indices 0-17)
CATEGORY_NAMES = {
    0: "PIANO",
    1: "GUITAR",
    2: "STRINGS & VOCAL",
    3: "BRASS",
    4: "FLUTE",
    5: "SAX & REED",
    6: "MALLET & ORCH PERC",
    7: "WORLD PERC",
    8: "ORGAN & ACCORDION",
    9: "ORCHESTRAL PAD",
    10: "SYNTH",
    11: "BASS",
    12: "DIGITAL DRAWBAR",
    13: "ACCORDION REG",
    14: "GM SPECIAL",
    15: "DRUM KITS",
    16: "MEMORY A",
    17: "MEMORY B",
}


def format_byte_line(data, offset, bytes_per_line=16):
    """Format a line of .byte directives with ROM offset annotation."""
    vals = ', '.join(f'0x{b:02x}' for b in data)
    return f'\t.byte {vals}\t; ROM offset 0x{offset:06X}\n'


def generate_8320_file(bin_path, label, category_name):
    """Generate .s file for 8320-byte format (128-byte header + 2048 x 4-byte pairs).

    Format:
    - Bytes 0-7: Sub-bank index (0x00-0x07)
    - Bytes 8-127: Zero padding (120 bytes)
    - Bytes 128-8319: 2048 records of (word1:16LE, word2:16LE)
    """
    data = open(bin_path, 'rb').read()
    assert len(data) == 8320, f"Expected 8320 bytes, got {len(data)}"

    lines = []
    lines.append(f'; {label}: {category_name} sound category data\n')
    lines.append(f'; Format: 128-byte header (8-byte sub-bank index + 120 zero pad)\n')
    lines.append(f';         + 2048 x 4-byte records (word1:16LE, word2:16LE)\n')
    lines.append(f'; Total: 8320 bytes\n')
    lines.append(f'; Source: {os.path.basename(bin_path)}\n')
    lines.append('\n')

    # Sub-bank index (8 bytes)
    lines.append('; Sub-bank index (8 entries)\n')
    idx_vals = ', '.join(f'0x{b:02x}' for b in data[:8])
    lines.append(f'\t.byte {idx_vals}\n')

    # Zero padding (120 bytes)
    lines.append('; Zero padding to 128-byte header boundary\n')
    lines.append('\t.zero 120\n')
    lines.append('\n')

    # 2048 records as 16-bit LE pairs
    lines.append('; Sound data records: 2048 x (word1:16LE, word2:16LE)\n')
    num_records = 2048
    records_per_group = 16

    for i in range(num_records):
        off = 128 + i * 4
        w1 = struct.unpack_from('<H', data, off)[0]
        w2 = struct.unpack_from('<H', data, off + 2)[0]

        if i % records_per_group == 0:
            lines.append(f'; --- Records {i}-{min(i + records_per_group - 1, num_records - 1)} ---\n')

        lines.append(f'\t.short 0x{w1:04x}, 0x{w2:04x}\n')

    return ''.join(lines)


def generate_pair_data_file(bin_path, label, category_name, header_size):
    """Generate .s file for variable-header + pair data formats.

    Used for files that have an N-byte sub-bank index followed by
    padding then 16-bit LE pair data.
    """
    data = open(bin_path, 'rb').read()

    lines = []
    lines.append(f'; {label}: {category_name} sound data\n')
    lines.append(f'; Total: {len(data)} bytes\n')
    lines.append(f'; Source: {os.path.basename(bin_path)}\n')
    lines.append('\n')

    # Detect sub-bank index length
    idx_len = 0
    while idx_len < min(32, len(data)) and data[idx_len] == idx_len:
        idx_len += 1

    if idx_len > 1:
        # Has a sub-bank index
        idx_vals = ', '.join(f'0x{b:02x}' for b in data[:idx_len])
        lines.append(f'; Sub-bank index ({idx_len} entries)\n')
        lines.append(f'\t.byte {idx_vals}\n')

        # Check for zero padding or immediate data after index
        # Find how many zeros follow
        zero_end = idx_len
        while zero_end < len(data) and data[zero_end] == 0:
            zero_end += 1

        # If there's significant zero padding, use .zero
        zero_count = zero_end - idx_len
        if zero_count > 0:
            lines.append(f'; Zero padding ({zero_count} bytes)\n')
            lines.append(f'\t.zero {zero_count}\n')

        data_start = zero_end
    else:
        data_start = 0

    # Remaining data as 16-bit LE words if even, else bytes
    remaining = len(data) - data_start

    if remaining > 0 and remaining % 2 == 0:
        # Emit as 16-bit LE words, 8 per line
        lines.append(f'\n; Data ({remaining} bytes = {remaining // 2} words)\n')
        words_per_line = 8
        for i in range(data_start, len(data), 2 * words_per_line):
            chunk_end = min(i + 2 * words_per_line, len(data))
            words = []
            for j in range(i, chunk_end, 2):
                w = struct.unpack_from('<H', data, j)[0]
                words.append(f'0x{w:04x}')
            lines.append(f'\t.short {", ".join(words)}\n')
    elif remaining > 0:
        # Odd remaining - emit as bytes
        lines.append(f'\n; Data ({remaining} bytes)\n')
        for i in range(data_start, len(data), 16):
            chunk = data[i:min(i + 16, len(data))]
            vals = ', '.join(f'0x{b:02x}' for b in chunk)
            lines.append(f'\t.byte {vals}\n')

    return ''.join(lines)


def generate_raw_byte_file(bin_path, label, description, rom_base_offset):
    """Generate .s file with raw .byte data, 16 bytes per line, with ROM offset annotations."""
    data = open(bin_path, 'rb').read()

    lines = []
    lines.append(f'; {label}: {description}\n')
    lines.append(f'; Total: {len(data)} bytes\n')
    lines.append(f'; Source: {os.path.basename(bin_path)}\n')
    lines.append(f'; Format: Raw data (structure not yet fully decoded)\n')
    lines.append('\n')

    for i in range(0, len(data), 16):
        chunk = data[i:min(i + 16, len(data))]
        rom_off = rom_base_offset + i
        vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {vals}\t; {rom_off:06X}\n')

    return ''.join(lines)


def generate_small_byte_file(bin_path, label, description):
    """Generate .s file for small binary blobs (< 256 bytes), using .byte with 16 per line."""
    data = open(bin_path, 'rb').read()

    lines = []
    lines.append(f'; {label}: {description}\n')
    lines.append(f'; Total: {len(data)} bytes\n')
    lines.append(f'; Source: {os.path.basename(bin_path)}\n')
    lines.append('\n')

    for i in range(0, len(data), 16):
        chunk = data[i:min(i + 16, len(data))]
        vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {vals}\n')

    return ''.join(lines)


# Define all .incbin files to convert and their metadata.
# (bin_filename, output_subdir, output_name, label, description, format_type, extra)
# format_type: '8320' | 'pair' | 'raw' | 'small'
# For 'raw': extra = rom_base_offset
# For '8320': extra = category_name
# For 'pair': extra = (category_name, header_size)

CONVERSIONS = [
    # Sound category data files
    ('e02510_e0458f.bin', 'audio', 'sound_data_piano.s',
     'SOUND_DATA_PIANO', 'PIANO category', '8320', 'PIANO'),
    ('e04590_e04b2f.bin', 'audio', 'sound_data_guitar.s',
     'SOUND_DATA_GUITAR', 'GUITAR category', 'raw', 0xE04590),
    ('e04b30_e06baf.bin', 'audio', 'sound_data_strings_vocal.s',
     'SOUND_DATA_STRINGS_VOCAL', 'STRINGS & VOCAL category', '8320', 'STRINGS & VOCAL'),
    ('e06f30_e078f1.bin', 'audio', 'sound_data_flute.s',
     'SOUND_DATA_FLUTE', 'FLUTE category', 'raw', 0xE06F30),
    ('e078f2_e08baf.bin', 'audio', 'sound_data_flute_extra.s',
     'SoundData_Flute_Extra', 'Additional FLUTE data (referenced by pointer table)', 'raw', 0xE078F2),
    ('e08bb0_e0914f.bin', 'audio', 'sound_data_sax_reed.s',
     'SOUND_DATA_SAX_REED', 'SAX & REED category', 'raw', 0xE08BB0),
    ('e09150_e0adcf.bin', 'audio', 'sound_data_mallet_orch_perc.s',
     'SOUND_DATA_MALLET_ORCH_PERC', 'MALLET & ORCH PERC category', 'raw', 0xE09150),

    # Smaller sound data files (Orchestral Pad through Drum Kits)
    ('e0b250_e0b2cf.bin', 'audio', 'sound_data_orchestral_pad.s',
     'SOUND_DATA_ORCHESTRAL_PAD', 'ORCHESTRAL PAD sound data', 'small', None),
    ('e0b2d0_e0b3cf.bin', 'audio', 'sound_data_synth.s',
     'SOUND_DATA_SYNTH', 'SYNTH sound data', 'small', None),
    ('e0b3d0_e0b3e1.bin', 'audio', 'sound_data_bass.s',
     'SOUND_DATA_BASS', 'BASS sound data', 'small', None),
    ('e0b3e2_e0b3f3.bin', 'audio', 'sound_data_digital_drawbar.s',
     'SOUND_DATA_DIGITAL_DRAWBAR', 'DIGITAL DRAWBAR sound data', 'small', None),
    ('e0b3f4_e0b405.bin', 'audio', 'sound_data_accordion_reg.s',
     'SOUND_DATA_ACCORDION_REG', 'ACCORDION REG sound data', 'small', None),
    ('e0b406_e0b417.bin', 'audio', 'sound_data_gm_special.s',
     'SOUND_DATA_GM_SPECIAL', 'GM SPECIAL sound data', 'small', None),
    ('e0b418_e0b4ec.bin', 'audio', 'sound_data_drum_kits.s',
     'SOUND_DATA_DRUM_KITS', 'DRUM KITS sound data', 'small', None),

    # Style UI parameter blocks
    ('e0b4ed_e0b5e6.bin', 'includes', 'style_ui_paramblock_bal.s',
     'StyleUI_ParamBlock_BAL', 'Style UI parameter block (BAL)', 'small', None),
    ('e0b5e7_e0b60d.bin', 'includes', 'style_ui_paramblock_value.s',
     'StyleUI_ParamBlock_VALUE', 'Style UI parameter block (VALUE)', 'small', None),
    ('e0b60e_e0b6a5.bin', 'includes', 'style_ui_paramblock_common.s',
     'StyleUI_ParamBlock_COMMON', 'Style UI parameter block (Common)', 'small', None),
    ('e0b6a6_e0b6cc.bin', 'includes', 'style_ui_paramblock_short.s',
     'StyleUI_ParamBlock_Short', 'Style UI parameter block (Short)', 'small', None),
    ('e0b6cd_e0b783.bin', 'includes', 'style_ui_paramblock_extended.s',
     'StyleUI_ParamBlock_Extended', 'Style UI parameter block (Extended)', 'small', None),
    ('e0b784_e0b842.bin', 'includes', 'style_ui_paramblock_medium.s',
     'StyleUI_ParamBlock_Medium', 'Style UI parameter block (Medium)', 'small', None),
    ('e0b843_e0b8dd.bin', 'includes', 'style_ui_paramblock_meas.s',
     'StyleUI_ParamBlock_MEAS', 'Style UI parameter block (MEAS)', 'small', None),
    ('e0b8de_e0b904.bin', 'includes', 'style_ui_paramblock_alta.s',
     'StyleUI_ParamBlock_AltA', 'Style UI parameter block (AltA)', 'small', None),
    ('e0b905_e0b92d.bin', 'includes', 'style_ui_paramblock_altb.s',
     'StyleUI_ParamBlock_AltB', 'Style UI parameter block (AltB)', 'small', None),
    ('e0b92e_e0b99c.bin', 'includes', 'style_ui_paramblock_altc.s',
     'StyleUI_ParamBlock_AltC', 'Style UI parameter block (AltC)', 'small', None),
    ('e0b99d_e0b9ec.bin', 'includes', 'style_ui_paramblock_altd.s',
     'StyleUI_ParamBlock_AltD', 'Style UI parameter block (AltD)', 'small', None),
    ('e0b9ed_e0ba5f.bin', 'includes', 'style_ui_paramblock_alte.s',
     'StyleUI_ParamBlock_AltE', 'Style UI parameter block (AltE)', 'small', None),

    # Style UI screen data
    ('e0bb90_e0c95a.bin', 'includes', 'style_ui_screendata_main.s',
     'StyleUI_ScreenData_Main', 'Style UI screen data (Main)', 'raw', 0xE0BB90),
    ('e0c95b_e0ca12.bin', 'includes', 'style_ui_screendata_meascursor.s',
     'StyleUI_ScreenData_MeasCursor', 'Style UI screen data (MeasCursor)', 'small', None),
    ('e0ca13_e0caf6.bin', 'includes', 'style_ui_screendata_yesctl.s',
     'StyleUI_ScreenData_YesCtl', 'Style UI screen data (YesCtl)', 'small', None),
    ('e0caf7_e0cd1d.bin', 'includes', 'style_ui_screendata_ctlonly.s',
     'StyleUI_ScreenData_CtlOnly', 'Style UI screen data (CtlOnly)', 'raw', 0xE0CAF7),

    # GUI data
    ('e0cd1e_e0cfdd.bin', 'includes', 'gui_format_strings.s',
     'GUI_FormatStrings', 'GUI format string data', 'raw', 0xE0CD1E),
    ('e0cfde_e0e406.bin', 'includes', 'gui_display_struct_data.s',
     'GUI_DisplayStructData', 'GUI display structure data', 'raw', 0xE0CFDE),

    # Tone gen parameter table
    ('e0e407_e0e973.bin', 'audio', 'tonegen_param_table.s',
     'ToneGen_ParamTable', 'Tone generator parameter table', 'raw', 0xE0E407),
]


def main():
    # Generate all .s files
    for entry in CONVERSIONS:
        bin_name, subdir, out_name, label, desc, fmt, extra = entry
        bin_path = os.path.join(INCLUDES_DIR, bin_name)

        if subdir == 'audio':
            out_dir = AUDIO_DIR
        else:
            out_dir = INCLUDES_DIR

        out_path = os.path.join(out_dir, out_name)

        if not os.path.exists(bin_path):
            print(f"WARNING: {bin_path} not found, skipping", file=sys.stderr)
            continue

        if fmt == '8320':
            content = generate_8320_file(bin_path, label, extra)
        elif fmt == 'raw':
            content = generate_raw_byte_file(bin_path, label, desc, extra)
        elif fmt == 'small':
            content = generate_small_byte_file(bin_path, label, desc)
        elif fmt == 'pair':
            content = generate_pair_data_file(bin_path, label, extra[0], extra[1])
        else:
            print(f"WARNING: Unknown format {fmt} for {bin_name}", file=sys.stderr)
            continue

        with open(out_path, 'w') as f:
            f.write(content)

        print(f"  Created: {out_path} ({os.path.getsize(out_path)} bytes)")

    # Now update kn5000_v10_program.s using binary I/O to preserve Latin-1
    print("\nUpdating kn5000_v10_program.s ...")

    with open(MAIN_S, 'rb') as f:
        main_data = f.read()

    # Build replacement map: .incbin line -> .include line
    replacements = {}
    for entry in CONVERSIONS:
        bin_name, subdir, out_name, label, desc, fmt, extra = entry

        if subdir == 'audio':
            include_path = f'audio/{out_name}'
        else:
            include_path = f'includes/{out_name}'

        # The .incbin line to find (could have trailing comment)
        old_pattern = f'.incbin "includes/{bin_name}"'
        new_line = f'.include "{include_path}"'

        replacements[old_pattern.encode('ascii')] = new_line.encode('ascii')

    # Apply replacements
    modified = main_data
    count = 0
    for old, new in replacements.items():
        if old in modified:
            # Find the full line and replace just the .incbin part
            # We want to keep the label and comment structure, just swap .incbin -> .include
            # Actually we need to replace the entire .incbin directive with .include
            # but preserve any trailing comment on the line

            # Find each occurrence
            pos = 0
            while True:
                idx = modified.find(old, pos)
                if idx == -1:
                    break

                # Find the start of the line (after newline)
                line_start = modified.rfind(b'\n', 0, idx)
                if line_start == -1:
                    line_start = 0
                else:
                    line_start += 1

                # Find end of line
                line_end = modified.find(b'\n', idx)
                if line_end == -1:
                    line_end = len(modified)

                # Get the full line
                full_line = modified[line_start:line_end]

                # Replace the .incbin part, keeping the tab prefix
                # The line looks like: \t.incbin "includes/xxx.bin"\t; comment
                # We want: \t.include "audio/xxx.s"\t; comment  (or keep comment)
                new_line = full_line.replace(old, new)

                modified = modified[:line_start] + new_line + modified[line_end:]
                count += 1
                pos = line_start + len(new_line)

    with open(MAIN_S, 'wb') as f:
        f.write(modified)

    print(f"  Replaced {count} .incbin directives with .include")
    print("\nDone! Run 'make clean && make all' to verify byte-matching.")


if __name__ == '__main__':
    main()
