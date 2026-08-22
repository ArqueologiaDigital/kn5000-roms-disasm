#!/usr/bin/env python3
"""Are the `sub r,r` sites that have NO byte-exact llvm-mc spelling real code?

verify_sub_rr.py finds 41 sites (of 3597) whose ROM bytes no spelling reproduces:
  * 29 sites where a 16-bit operand is SP   -- GR16 excludes SP, so neither
    `sub sp, wa` nor `sub ix, sp` parses;
  * 12 sites with the E7 (long) ERP prefix  -- there is no `subl_erp` in the
    backend (only `subb_erp`/`subw_erp` exist).
This script asks whether ANY of them is an INSTRUCTION rather than data.

Test that can fail: for each site take the 16 ROM bytes straddling it and look
for that window inside the DATA the project's byte-exact source tree declares --
every `.byte`/`.short`/`.long` run with numeric values, plus every `.incbin`-ed
binary (resolved both relative to the including file and to the tree root, since
the assembler runs with `-I <tree root>`).  A window found there is data.  A
window NOT found is a candidate real instruction and the missing spelling would
matter.  Falsifier: one site reported UNACCOUNTED that turns out to be code.

Input:  sub_rr_unspellable.json, written by verify_sub_rr.py.
Run:    python3 verify_sub_rr.py && python3 sub_rr_gap_is_data.py

Result 2026-08-22: 41/41 unspellable sites are inside source-declared data.
Where they land: 0xE0CBA0 is inside the SOUND_DATA_ORGAN_ACCORDION `.incbin`;
0xEAA760/0xEAA764 are inside the `dd LABEL_EAA7xx` 32-bit pointer table (see
archive/asl/maincpu/kn5000_v10_program.asm:95192); the 24 table_data and the one
v142 sub-program site are inside `.byte` blobs.  Zero real instructions are lost
to either gap, so neither is a blocker for a .byte-blob converter.
"""
import os, re, glob, json, collections

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
HERE = os.path.dirname(os.path.abspath(__file__))

# ROM file -> (load base used by verify_sub_rr.py, source trees that declare it)
TREES = {
    'kn5000_v7_program.rom':      (0xE00000, ['v7/maincpu']),
    'kn5000_v9_program.rom':      (0xE00000, ['v9/maincpu']),
    'kn5000_v10_program.rom':     (0xE00000, ['v10/maincpu', 'v10']),
    'kn5000_table_data.rom':      (0x400000, ['table_data']),
    'kn5000_subcpu_boot.ic30':    (0x000000, ['subcpu/boot', 'subcpu']),
    'kn5000_subprogram_v142.rom': (0x000000, ['v142/subcpu']),
    'kn5000_custom_data.ic19':    (0x000000, ['custom_data']),
    'hd-ae5000_v2_06i.ic4':       (0x000000, ['hdae5000']),
}

data_re   = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$]*:\s*)?\.(byte|short|word|2byte|long|int|4byte)\s+(.*)$')
incbin_re = re.compile(r'\.incbin\s+"([^"]+)"')
WIDTH = {'byte': 1, 'short': 2, 'word': 2, '2byte': 2, 'long': 4, 'int': 4, '4byte': 4}

_tree_cache = {}
def tree_data(dirs):
    key = tuple(dirs)
    if key in _tree_cache: return _tree_cache[key]
    blobs = []
    for d in dirs:
        root = os.path.join(REPO, d)
        if not os.path.isdir(root): continue
        for f in glob.glob(root + '/**/*.s', recursive=True):
            cur = b''
            for line in open(f, errors='replace'):
                m = data_re.match(line)
                if m:
                    w = WIDTH[m.group(1)]
                    vals = [v.strip() for v in m.group(2).split(';')[0].split(',') if v.strip()]
                    try:
                        cur += b''.join((int(v, 0) & ((1 << (8 * w)) - 1)).to_bytes(w, 'little')
                                        for v in vals)
                        continue
                    except ValueError:
                        pass          # symbolic operand -- run is not reconstructible
                if cur: blobs.append(cur); cur = b''
                m = incbin_re.search(line)
                if m:
                    for p in (os.path.join(os.path.dirname(f), m.group(1)),
                              os.path.join(root, m.group(1))):
                        if os.path.exists(p):
                            blobs.append(open(p, 'rb').read()); break
            if cur: blobs.append(cur)
    _tree_cache[key] = blobs
    return blobs

def is_pointer_table(rom, base, off, n):
    """Stage 2, for data the tree declares SYMBOLICALLY (`.long LABEL_...`), whose
    bytes stage 1 cannot reconstruct.  True iff the site sits inside a run of >=4
    consecutive 32-bit little-endian words that are all addresses inside this ROM
    and step by a constant non-zero stride -- i.e. a pointer table."""
    for phase in range(4):
        start = off - ((off - phase) % 4) - 16
        if start < 0: continue
        words, offs = [], []
        for k in range(9):
            w = start + 4 * k
            if w + 4 > len(rom): break
            words.append(int.from_bytes(rom[w:w + 4], 'little')); offs.append(w)
        if len(words) < 5: continue
        # keep only the window that actually covers the instruction bytes
        if not any(o <= off and off + n <= o + 4 for o in offs): continue
        ok = [base <= v < base + len(rom) for v in words]
        d = [words[i + 1] - words[i] for i in range(len(words) - 1)]
        if all(ok) and len(set(d)) == 1 and d[0] != 0:
            return True, f'stride {d[0]:+#x} pointer table'
    return False, ''

sites = json.load(open(os.path.join(HERE, 'sub_rr_unspellable.json')))
by_rom = collections.defaultdict(list)
for s in sites: by_rom[s['rom']].append(s)

total = found = 0
for name, ss in by_rom.items():
    base, dirs = TREES[name]
    rom = open(os.path.join(REPO, 'original_ROMs', name), 'rb').read()
    blobs = tree_data(dirs)
    print(f'{name}: {len(blobs)} data runs, {sum(len(b) for b in blobs)} bytes '
          f'of source-declared data, {len(ss)} unspellable sites')
    for s in sorted(ss, key=lambda x: x['addr']):
        o = s['addr'] - base
        win = rom[o - 6:o + 10]
        hit = any(win in b for b in blobs)
        why = 'declared .byte/.short/.long/.incbin data' if hit else ''
        if not hit:
            hit, why = is_pointer_table(rom, base, o, len(s['bytes']) // 2)
        total += 1; found += hit
        print(f'  {s["addr"]:06x}  {s["bytes"]:<8s} data={str(hit):5s}  {why}'
              + ('' if hit else '   <-- UNACCOUNTED, inspect by hand'))
print(f'\n{found}/{total} unspellable sites are data, not instructions')
