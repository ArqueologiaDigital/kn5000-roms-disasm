#!/usr/bin/env python3
"""Extract v7 .incbin data from the v7 ROM using v9 ELF as address reference.
Run before assembling v7 to ensure correct data blobs."""
import subprocess, os, glob

v7_rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()

# First build v9 if not already built
v9_elf = 'rebuilt_ROMs/kn5000_v9_program.llvm.elf'
if not os.path.exists(v9_elf):
    print("v9 ELF not found, building v9 first...")
    os.system('make rebuilt_ROMs/kn5000_v9_program.llvm.rom')

result = subprocess.run(['/mnt/shared/llvm-project/build/bin/llvm-nm', '--no-sort', v9_elf],
    capture_output=True, text=True)

syms = {}
for line in result.stdout.strip().split('\n'):
    parts = line.strip().split()
    if len(parts) >= 3:
        syms[parts[2]] = int(parts[0], 16)

# Find .incbin labels in v9 source
incbin_map = {}
for fp in sorted(glob.glob('v9/maincpu/**/*.s', recursive=True)):
    with open(fp, 'rb') as f:
        lines = f.readlines()
    last_label = None
    for line in lines:
        s = line.strip()
        # Match "LabelName:" at start of line (may have content after colon)
        import re as _re
        _m = _re.match(rb'^(\w+):', s)
        if _m and not s.startswith(b'.') and not s.startswith(b';'):
            last_label = _m.group(1).decode('latin-1')
        if b'.incbin' in s and b'generated/' in s:
            i1 = s.find(b'"') + 1
            i2 = s.find(b'"', i1)
            bin_rel = s[i1:i2].decode('latin-1')
            if last_label and last_label in syms:
                incbin_map[last_label] = (syms[last_label], f'v9/maincpu/{bin_rel}')

extracted = 0
for label, (addr, v9_path) in sorted(incbin_map.items(), key=lambda x: x[1][0]):
    if not os.path.exists(v9_path):
        continue
    v9_size = os.path.getsize(v9_path)
    rom_off = addr - 0xe00000
    
    v7_data = v7_rom[rom_off:rom_off+v9_size]
    v9_data = open(v9_path, 'rb').read()
    
    # Check similarity (>50% = same block at same address)
    match_pct = sum(1 for a, b in zip(v7_data, v9_data) if a == b) / v9_size if v9_size > 0 else 0
    
    v7_path = v9_path.replace('v9/', 'v7/')
    os.makedirs(os.path.dirname(v7_path), exist_ok=True)
    
    if match_pct > 0.5:
        with open(v7_path, 'wb') as f:
            f.write(v7_data)
        extracted += 1
    else:
        # Different block at this offset — use v9 data (safe default)
        with open(v7_path, 'wb') as f:
            f.write(v9_data)

print(f"Extracted {extracted} v7 bins from ROM")

# Special case: naka_sequencer_channels.bin is 42 bytes SHORTER in v7
# The C compilation produces v9's 7936-byte version.
# Override with correct v7 data (7894 bytes).
seq_path = 'v7/maincpu/includes/generated/naka_sequencer_channels.bin'
seq_off = 0xeee078 - 0xe00000
seq_data = v7_rom[seq_off:seq_off+7894]
os.makedirs(os.path.dirname(seq_path), exist_ok=True)
with open(seq_path, 'wb') as f:
    f.write(seq_data)
print(f"Fixed naka_sequencer_channels.bin: {len(seq_data)} bytes (v7 size)")

# V7-specific data extractions: regions in .s files that use v9 pointer values
# and need to be replaced with v7 ROM data.
v7_data_extractions = [
    # (bin_name, rom_start, rom_end)
    ('v7_data_charmap_fullpermutation.bin', 0xEED118, 0xEEDD36),
    ('v7_data_charmap_valuedata_b.bin', 0xEE8ED8, 0xEEAE08),
    ('v7_data_fdtest_string_testtitlefunc.bin', 0xE1FD3E, 0xE1FFD2),
    ('v7_data_keyscalenotestr_g.bin', 0xED1C82, 0xED1D4A),
    ('v7_data_methodnamestr_mt_svariini.bin', 0xED2F4A, 0xED2FDA),
    ('v7_data_msgtype_excsend.bin', 0xE55D94, 0xE55DF2),
    ('v7_data_mtname_songnameset.bin', 0xE2104A, 0xE21078),
    ('v7_data_naka_subdispatch_a_table.bin', 0xEE0158, 0xEE0198),
    ('v7_data_naka_toshiparam_table.bin', 0xEDB370, 0xEDBAC0),
    ('v7_data_procnamestr_normscreenproc.bin', 0xED3282, 0xED32E6),
    ('v7_data_seqchan_commanddispatch_table.bin', 0xEE2D6C, 0xEE2F26),
    ('v7_data_str_storetotalsetting_de.bin', 0xED0C8C, 0xED0F48),
    ('v7_data_systemconfig_pointertable.bin', 0xEE8C7E, 0xEE8CF8),
    ('v7_data_uistate_defaultconfig_b.bin', 0xEE86B0, 0xEE86D0),
    ('v7_data_widgetparam_selfref_table.bin', 0xEE4E1C, 0xEE4FC6),
    ('v7_data_encoder_region.bin', 0xEDA160, 0xEDA616),
]

gen_dir = 'v7/maincpu/includes/generated'
for bin_name, rom_start, rom_end in v7_data_extractions:
    rom_off = rom_start - 0xe00000
    data = v7_rom[rom_off:rom_end - 0xe00000]
    bin_path = os.path.join(gen_dir, bin_name)
    with open(bin_path, 'wb') as f:
        f.write(data)

print(f"Extracted {len(v7_data_extractions)} v7-specific data bins")
