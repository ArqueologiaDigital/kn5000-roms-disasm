#!/usr/bin/env python3
"""Which plausible spellings of the unidasm form `sub r,r` ASSEMBLE but produce
the WRONG bytes?

The printed text `sub <REG>,<REG>` covers TWO encodings -- a 2-byte one
(reg-direct prefix 0xC8/0xD8/0xE8 + reg) and a 3-byte one (extended-register
prefix 0xC7/0xD7/0xE7 + a register-code byte).  A converter that spells the
unidasm TEXT instead of keying on the RAW BYTES silently picks the 2-byte
encoding for 3-byte instructions.  This script demonstrates each trap with
llvm-mc output, and counts how many real ROM sites each trap would corrupt.

Run:  python3 sub_rr_dangerous_spellings.py

Result 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b): 3 traps confirmed --
text-driven collapse of the 3-byte form (1 real site), a bank byte silently
truncated mod 256, and a negative bank byte silently wrapped.  `sub c, qizh`
is NOT a trap: it is rejected, because qizh is not an LLVM register.
"""
import os, re, subprocess, json, collections

LLVMMC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
HERE   = os.path.dirname(os.path.abspath(__file__))
REPO   = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM= os.path.expanduser('~/compartilhado/tools/unidasm')

def mc(text):
    p = subprocess.run([LLVMMC, '-triple=tlcs900', '--show-encoding'],
                       input=text, capture_output=True, text=True)
    m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
    if m: return bytes(int(x, 16) for x in m.group(1).split(','))
    return None

CASES = [
    # (spelling, bytes the ROM really has at a site printed the same way, note)
    ('sub l, l',          'c7eca7', 'text of the 3-byte form `sub L,L` at table_data 0x54238F'),
    ('sub a, c',          'c7e4a1', 'text of a hypothetical 3-byte `sub A,C` (bank 0xE4 = C)'),
    ('subb_erp a, 0x1fa', 'c701faa1', 'bank byte 0x1FA is out of range'),
    ('subb_erp a, -6',    '',        'negative bank byte'),
    ('sub c, qizh',       'c7fba3',  'the task example, spelled with unidasm register names'),
    ('sub ix, sp',        'dfa4',    'SP as a 16-bit source (v7 0xE0CBA0)'),
    ('sub sp, wa',        'd8a7',    'SP as a 16-bit destination (v7 0xEAA764)'),
    ('subl_erp xsp, 0xe7','e7e7a7',  'the long (E7) ERP form'),
]
print('%-22s %-12s %-12s %s' % ('spelling', 'assembles to', 'ROM has', 'verdict'))
for text, rom, note in CASES:
    enc = mc(text)
    e = enc.hex() if enc else 'REJECTED'
    if enc is None:                     verdict = 'safe (rejected)'
    elif rom and enc.hex() == rom:      verdict = 'correct'
    else:                               verdict = 'DANGEROUS (assembles, wrong bytes)'
    print('%-22s %-12s %-12s %s   -- %s' % (text, e, rom or '(n/a)', verdict, note))

# How many real sites would a TEXT-driven converter corrupt?
print('\n--- blast radius of the text-driven trap, over all 8 ROMs ---')
ROMS = [('kn5000_v7_program.rom',0xE00000),('kn5000_v9_program.rom',0xE00000),
        ('kn5000_v10_program.rom',0xE00000),('kn5000_table_data.rom',0x400000),
        ('kn5000_subcpu_boot.ic30',0),('kn5000_subprogram_v142.rom',0),
        ('kn5000_custom_data.ic19',0),('hd-ae5000_v2_06i.ic4',0)]
LINE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+sub ([A-Za-z][A-Za-z0-9-]*),([A-Za-z][A-Za-z0-9-]*)$')
n3 = collapsed = 0
for name, base in ROMS:
    path = os.path.join(REPO, 'original_ROMs', name)
    dis = subprocess.run([UNIDASM, path, '-arch', 'tlcs900', '-basepc', hex(base)],
                         capture_output=True, text=True).stdout
    for line in dis.split('\n'):
        m = LINE.match(line)
        if not m: continue
        by = bytes(int(x, 16) for x in m.group(2).split())
        if len(by) != 3: continue
        n3 += 1
        enc = mc(f'sub {m.group(3).lower()}, {m.group(4).lower()}')
        if enc is not None and enc != by:
            collapsed += 1
            print(f'  {name} {int(m.group(1),16):06x}  rom={by.hex(" ")}  '
                  f'text="{m.group(3)},{m.group(4)}" -> {enc.hex(" ")}  WRONG')
print(f'  {collapsed} of {n3} three-byte sites are silently mis-encoded by the '
      f'text-driven spelling (the rest are rejected outright, which is safe)')
