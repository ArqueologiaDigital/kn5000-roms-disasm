# Q: what is byte +976 (0x3D0) of a rhythm ROM header located by RhythmROM_BankProgramLocators?
# Run from the repository root on a built tree:  python3 analysis/kn5000-naming/probes/rhythm_probe.py
# Supports the header of Rhythm_LoadCurrentTimeSig (analysis/kn5000-naming/proposals-2026-10-06-helpers-d.json).
import os, struct, subprocess, collections
_out = subprocess.run([os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-nm'), '--defined-only',
                       'rebuilt_ROMs/kn5000_v10_program.llvm.elf'], capture_output=True, text=True).stdout
nm = {l.split()[2]: int(l.split()[0], 16) for l in _out.split('\n') if len(l.split()) == 3}
rom = open('/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/kn5000_v10_program.llvm.rom','rb').read()
rr = open('/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_rhythm_data_rom.ic14','rb').read()
base = nm['RhythmROM_BankProgramLocators'] - 0xE00000
vals = collections.Counter()
rows=[]
for bank in range(8):
    for prog in range(128):
        o = base + bank*512 + prog*4
        hi, lo = struct.unpack_from('<HH', rom, o)
        if hi == 0 and lo == 0: continue
        addr = ((hi & 0xff) << 16) | lo
        h = rr[addr:addr+0x400]
        rows.append((bank, prog, addr, h[976], h[986], h[0x3d2], h[0x3d3], h[0x3d8]))
        vals[h[976]] += 1
print(len(rows), sorted(vals.items()))
for r in rows[:40]: print(r)
