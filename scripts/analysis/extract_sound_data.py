#!/usr/bin/env python3
"""
Extract 3 inline sound data blocks to include files and consolidate all
sound data includes into a single audio/sound_data.s file.

Blocks to extract:
  - SOUND_DATA_BRASS_PTRS (lines 218-620) -> audio/sound_data_brass.s
  - SOUND_DATA_WORLD_PERC (lines 634-1030) -> audio/sound_data_world_perc.s
  - SOUND_DATA_ORGAN_ACCORDION (lines 1031-1063) -> audio/sound_data_organ_accordion.s

Then replace lines 209-1084 (all sound data) with a single .include "audio/sound_data.s"
and create audio/sound_data.s with all labels+includes on single lines, no blank lines.

Binary I/O for Latin-1 safety.
"""

import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAINCPU = os.path.join(REPO, 'maincpu')
MAIN_FILE = os.path.join(MAINCPU, 'kn5000_v10_program.s')
AUDIO_DIR = os.path.join(MAINCPU, 'audio')


def read_lines(path):
    with open(path, 'rb') as f:
        return f.readlines()


def write_lines(path, lines):
    with open(path, 'wb') as f:
        f.writelines(lines)


def main():
    lines = read_lines(MAIN_FILE)

    # Find line indices (0-based) for the blocks
    # SOUND_DATA_BRASS_PTRS starts at line 218 (index 217)
    # It includes BrassSound_SamplePtr_Table at line 219 (index 218)
    # Data ends before SOUND_DATA_FLUTE at line 622 (index 621)
    # So brass content = lines[218:621] (skipping the SOUND_DATA_BRASS_PTRS label itself)

    # SOUND_DATA_WORLD_PERC starts at line 634 (index 633)
    # Actual content starts at line 636 (index 635) after blank lines
    # Data ends before SOUND_DATA_ORGAN_ACCORDION at line 1031 (index 1030)

    # SOUND_DATA_ORGAN_ACCORDION starts at line 1031 (index 1030)
    # Data content at lines 1032-1063 (index 1031-1062)
    # Ends before SOUND_DATA_ORCHESTRAL_PAD at line 1065 (index 1064)

    # Verify landmarks
    assert lines[217].strip() == b'SOUND_DATA_BRASS_PTRS:', \
        f"Expected SOUND_DATA_BRASS_PTRS at line 218, got: {lines[217].strip()}"
    assert lines[621].startswith(b'SOUND_DATA_FLUTE:'), \
        f"Expected SOUND_DATA_FLUTE at line 622, got: {lines[621].strip()}"
    assert lines[633].strip() == b'SOUND_DATA_WORLD_PERC:', \
        f"Expected SOUND_DATA_WORLD_PERC at line 634, got: {lines[633].strip()}"
    assert lines[1030].startswith(b'SOUND_DATA_ORGAN_ACCORDION:'), \
        f"Expected SOUND_DATA_ORGAN_ACCORDION at line 1031, got: {lines[1030].strip()}"
    assert lines[1064].startswith(b'SOUND_DATA_ORCHESTRAL_PAD:'), \
        f"Expected SOUND_DATA_ORCHESTRAL_PAD at line 1065, got: {lines[1064].strip()}"

    # Extract brass data (lines 219-621, indices 218-620)
    brass_content = lines[218:621]
    # Remove trailing blank line if present
    while brass_content and brass_content[-1].strip() == b'':
        brass_content.pop()
    brass_content.append(b'\n')

    # Extract world_perc data (lines 636-1030, indices 635-1029)
    # Skip the blank lines after the label
    wp_start = 634  # index after SOUND_DATA_WORLD_PERC label
    while wp_start < 1030 and lines[wp_start].strip() == b'':
        wp_start += 1
    worldperc_content = lines[wp_start:1030]
    while worldperc_content and worldperc_content[-1].strip() == b'':
        worldperc_content.pop()
    worldperc_content.append(b'\n')

    # Extract organ_accordion data (lines 1032-1063, indices 1031-1063)
    organ_content = lines[1031:1064]
    while organ_content and organ_content[-1].strip() == b'':
        organ_content.pop()
    organ_content.append(b'\n')

    # Write the 3 new include files
    print("Writing extracted files:")

    brass_path = os.path.join(AUDIO_DIR, 'sound_data_brass.s')
    write_lines(brass_path, brass_content)
    print(f"  audio/sound_data_brass.s: {len(brass_content)} lines")

    wp_path = os.path.join(AUDIO_DIR, 'sound_data_world_perc.s')
    write_lines(wp_path, worldperc_content)
    print(f"  audio/sound_data_world_perc.s: {len(worldperc_content)} lines")

    organ_path = os.path.join(AUDIO_DIR, 'sound_data_organ_accordion.s')
    write_lines(organ_path, organ_content)
    print(f"  audio/sound_data_organ_accordion.s: {len(organ_content)} lines")

    # Create the consolidated audio/sound_data.s
    # All labels + includes on single lines, no blank lines between entries
    sound_data_lines = [
        b'SOUND_DATA_PIANO:\n',
        b'\t.include "audio/sound_data_piano.s"\n',
        b'SOUND_DATA_GUITAR:\n',
        b'\t.include "audio/sound_data_guitar.s"\n',
        b'SOUND_DATA_STRINGS_VOCAL:\n',
        b'\t.include "audio/sound_data_strings_vocal.s"\n',
        b'SOUND_DATA_BRASS_PTRS:\n',
        b'\t.include "audio/sound_data_brass.s"\n',
        b'SOUND_DATA_FLUTE:\n',
        b'\t.include "audio/sound_data_flute.s"\n',
        b'SoundData_Flute_Extra:\n',
        b'\t.include "audio/sound_data_flute_extra.s"\n',
        b'SOUND_DATA_SAX_REED:\n',
        b'\t.include "audio/sound_data_sax_reed.s"\n',
        b'SOUND_DATA_MALLET_ORCH_PERC:\n',
        b'\t.include "audio/sound_data_mallet_orch_perc.s"\n',
        b'SOUND_DATA_WORLD_PERC:\n',
        b'\t.include "audio/sound_data_world_perc.s"\n',
        b'SOUND_DATA_ORGAN_ACCORDION:\n',
        b'\t.include "audio/sound_data_organ_accordion.s"\n',
        b'SOUND_DATA_ORCHESTRAL_PAD:\n',
        b'\t.include "audio/sound_data_orchestral_pad.s"\n',
        b'SOUND_DATA_SYNTH:\n',
        b'\t.include "audio/sound_data_synth.s"\n',
        b'SOUND_DATA_BASS:\n',
        b'\t.include "audio/sound_data_bass.s"\n',
        b'SOUND_DATA_DIGITAL_DRAWBAR:\n',
        b'\t.include "audio/sound_data_digital_drawbar.s"\n',
        b'SOUND_DATA_ACCORDION_REG:\n',
        b'\t.include "audio/sound_data_accordion_reg.s"\n',
        b'SOUND_DATA_GM_SPECIAL:\n',
        b'\t.include "audio/sound_data_gm_special.s"\n',
        b'SOUND_DATA_DRUM_KITS:\n',
        b'\t.include "audio/sound_data_drum_kits.s"\n',
    ]

    sd_path = os.path.join(AUDIO_DIR, 'sound_data.s')
    write_lines(sd_path, sound_data_lines)
    print(f"  audio/sound_data.s: {len(sound_data_lines)} lines")

    # Now replace lines 209-1084 (indices 208-1084) in the main file
    # Line 209 = SOUND_DATA_PIANO: (index 208)
    # Line 1085 = blank line after SOUND_DATA_DRUM_KITS include (index 1084)
    # After DRUM_KITS include at line 1084 (index 1083), there's a blank line at 1085 (index 1084)
    # Next content: StyleUI_ParamBlock_BAL at line 1086 (index 1085)

    assert lines[208].startswith(b'SOUND_DATA_PIANO:'), \
        f"Expected SOUND_DATA_PIANO at line 209, got: {lines[208].strip()}"
    assert lines[1085].startswith(b'StyleUI_ParamBlock_BAL:'), \
        f"Expected StyleUI_ParamBlock_BAL at line 1086, got: {lines[1085].strip()}"

    # Replace lines 209-1085 (indices 208-1084) with the single include
    replacement = [
        b'\t.include "audio/sound_data.s"\n',
        b'\n',
    ]

    new_lines = lines[:208] + replacement + lines[1085:]
    write_lines(MAIN_FILE, new_lines)

    old_count = len(lines)
    new_count = len(new_lines)
    print(f"\nMain file: {old_count} -> {new_count} lines ({old_count - new_count} lines removed)")


if __name__ == '__main__':
    main()
