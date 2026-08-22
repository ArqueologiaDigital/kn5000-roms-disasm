#!/usr/bin/env python3
"""Does the `cp r,(imm)` spelling rule hold on the FOUR binaries the original
probe never looked at -- and is the rule the same one there?

QUESTION ANSWERED
  verify_cp_reg_direct.py proved the rule on the three maincpu revisions and the
  table-data ROM.  Four more dumped binaries in this tree were never checked:
  the sub-CPU payload, the sub-CPU boot ROM, the HD-AE5000 extension ROM and the
  custom-data ROM.  Those are different CPUs' code streams (same TLCS-900 core,
  different compiler runs), so they are an independent sample: if the rule were
  a coincidence of one compiler's output it would break here.

  It also fixes a load base the original probe got wrong: it disassembles
  kn5000_table_data.rom at 0x200000, but table_data/table_data.ld says
  ORIGIN = 0x800000 (0x200000 is the LENGTH).  Every table_data address quoted
  in README-cp_reg_direct.md is therefore 0x600000 too low.  The RULE is
  unaffected -- it is a function of the raw bytes only, and no operand of this
  form is PC-relative -- but the addresses are.  This script uses the linker
  scripts' ORIGIN for every binary.

RULE UNDER TEST (identical to the original probe; keyed on RAW BYTES only)

  c1 al ah    F0+r  (4B) -> cpda8     GR8[r], (0x<ah><al>)
  d1 al ah    F0+r  (4B) -> cpda16    GPR[r], (0x<ah><al>)
  e1 al ah    F0+r  (4B) -> cpda32    GPR[r], (0x<ah><al>)
  c2 a0 a1 a2 F0+r  (5B) -> cpda8_24  GR8[r], (0x<a2><a1><a0>)
  d2 a0 a1 a2 F0+r  (5B) -> cpda16_24 GPR[r], (0x<a2><a1><a0>)
  e2 a0 a1 a2 F0+r  (5B) -> cpda32_24 GPR[r], (0x<a2><a1><a0>)
  c0 aa       F0+r  (3B) -> NO SPELLING EXISTS
  d0 aa       F0+r  (3B) -> NO SPELLING EXISTS
  e0 aa       F0+r  (3B) -> NO SPELLING EXISTS

  r = last byte & 7;  GR8[r] = w a b c d e h l;  GPR[r] = xwa xbc xde xhl xix
  xiy xiz xsp.  Byte 0 high nibble = operand size (c byte / d word / e long),
  low nibble = address width (0 = 8-bit, 1 = 16-bit, 2 = 24-bit).

SIGNAL READ
  The bytes come from the ROM FILE at (address - ORIGIN), NOT from the unidasm
  listing text; the script asserts file bytes == listing bytes at every site and
  dies on the first disagreement.  PASS = `llvm-mc -triple=tlcs900
  --show-encoding` emits exactly those bytes.  Assembling without error is NOT a
  pass.

RUN
  python3 tools/spelling-probes/verify_cp_reg_direct_allbins.py
  python3 tools/spelling-probes/verify_cp_reg_direct_allbins.py --negative
  python3 tools/spelling-probes/verify_cp_reg_direct_allbins.py --dangerous

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

  binary                        spellable   c0/d0/e0 with no spelling
  kn5000_v7_program.rom          864 / 864   28  (c0 5, d0 6, e0 17)
  kn5000_v9_program.rom          865 / 865   33  (c0 8, d0 10, e0 15)
  kn5000_v10_program.rom         865 / 865   33
  kn5000_table_data.rom  @0x800000
                                  99 /  99   94  (c0 36, d0 16, e0 42)
  kn5000_subprogram_v142.rom [NEW]  8 /   8   51  (d0 14, e0 37)
  kn5000_subcpu_boot.ic30    [NEW]  0 /   0    0
  hd-ae5000_v2_06i.ic4       [NEW] 38 /  38    5  (c0 1, e0 4)
  kn5000_custom_data.ic19    [NEW]  0 /   0    0
  GRAND TOTAL 2739 / 2739 spellable sites byte-exact, 0 failures.
  The four never-before-checked binaries contribute 46 / 46 -- three different
  code streams (sub-CPU payload, HD-AE5000 extension, table-data) agree with the
  rule derived on the maincpu, so it is the encoding and not one compiler's habit.

  --negative (address width taken from the VALUE, as a reader of the printed
  text would): 2546 / 2739, 193 failures -- every 24-bit-encoded site whose
  address happens to fit in 16 bits, including 2 in hd-ae5000 that the old probe
  never saw.  The check can fail.

  --dangerous prints the spellings that ASSEMBLE and emit the WRONG bytes.

"""
import os, re, subprocess, collections, sys

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

# (file, ORIGIN, is_new).  ORIGIN is the linker script's ORIGIN, except the
# sub-CPU payload, whose section starts at 0x0EF00 inside its 0x400 region
# (its RESET vector `jp 0x01f924` at file offset 0 fixes it).
BINS = [('kn5000_v7_program.rom',      0xE00000, False),
        ('kn5000_v9_program.rom',      0xE00000, False),
        ('kn5000_v10_program.rom',     0xE00000, False),
        ('kn5000_table_data.rom',      0x800000, False),   # ld ORIGIN, not 0x200000
        ('kn5000_subprogram_v142.rom', 0x00EF00, True),
        ('kn5000_subcpu_boot.ic30',    0xFE0000, True),
        ('hd-ae5000_v2_06i.ic4',       0x280000, True),
        ('kn5000_custom_data.ic19',    0x300000, True)]

GR8 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
GPR = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']
SIZE = {0xC: ('cpda8',  GR8), 0xD: ('cpda16', GPR), 0xE: ('cpda32', GPR)}

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp ([A-Za-z]+),\((0x[0-9a-f]+)\)$')
ENC  = re.compile(r'encoding: \[([^\]]*)\]')

NEG = '--negative' in sys.argv

# (spelling, the ROM site it is a plausible-but-wrong answer for, why it is a trap)
DANGEROUS = [
    ('cp wa, (0x0ee8)',        'd1 e8 0e f0', 'rejected -- but llvm-mc STILL prints an encoding; trust the exit status'),
    ('cp a, (0x8d37)',         'c1 37 8d f1', 'rejected -- ditto'),
    ('cp xwa, (0x0ee8)',       'e1 e8 0e f0', 'always the 24-bit e2 form + a relocation: 5 bytes, never 4'),
    ('cpda16 wa, (0x0ee8)',    'd1 e8 0e f0', 'rejected: cpda16/cpda32 want the X-names'),
    ('cpda32 xwa, (0x0ee8)',   'd1 e8 0e f0', 'SIZE trap: the printed name is WA (word) but the operand shape forces an X-name, so a converter reaching for xwa lands on the LONG compare'),
    ('cpda8 a, (0x0ee8)',      'd1 e8 0e f0', 'same trap the other way: byte compare where the ROM has word'),
    ('cpda16_24 xwa, (0x0ee8)','d1 e8 0e f0', '5 bytes where the 16-bit-direct form is 4'),
    ('cpda16 xhl, (0x040c26)', 'd2 26 0c 04 f3', '24-bit address SILENTLY TRUNCATED: 4 bytes where the ROM has 5'),
    ('cpda32 xsp, (0x00dd00)', 'e2 00 dd 00 f7', 'ditto -- this is exactly the --negative failure at hd-ae5000 0x2a49d8'),
    ('cpda8 xbc, (0x03ce)',    'c1 ce 03 f1', 'X-name in cpda8 means the LOW BYTE: xbc -> f3 = C, not f1 = B'),
    ('cpda8 xde, (0x03ce)',    'c1 ce 03 f5', 'collides with cpda8 xiy'),
    ('cpda8 xiy, (0x03ce)',    'c1 ce 03 f5', 'collides with cpda8 xde'),
    ('cpda8 xhl, (0x03ce)',    'c1 ce 03 f7', 'collides with cpda8 xsp'),
    ('cpda8 xsp, (0x03ce)',    'c1 ce 03 f7', 'collides with cpda8 xhl'),
    ('cps xwa, 0',             'e0 00 f0',   'a DIFFERENT instruction (small-immediate compare), 2 bytes'),
    ('cpda16 xiy, (0xaf)',     'd0 af f5',   '*** the 8-bit-direct trap: assembles, prints the same text, ZERO-EXTENDS the address and emits 4 bytes where the ROM has 3'),
    ('cpda8 e, (0x06)',        'c0 06 f5',   '*** same 8-bit-direct trap (table_data 0x85c71f)'),
    ('cpda32 xwa, (0x00)',     'e0 00 f0',   '*** same 8-bit-direct trap (v142 DSP bytecode)'),
]

if '--dangerous' in sys.argv:
    print('spelling                        emits                  reference bytes    verdict')
    for sp, rom_hex, why in DANGEROUS:
        want = bytes(int(x, 16) for x in rom_hex.split())
        q = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                           input='\t.text\n\t' + sp + '\n',
                           capture_output=True, text=True)
        m = ENC.search(q.stdout)
        if q.returncode != 0:
            got = 'REJECTED'
        elif m and 'A,' in m.group(1):
            got = m.group(1).replace(',', ' ') + ' (reloc)'
        else:
            got = ' '.join(m.group(1).split(',')) if m else '?'
        if q.returncode != 0:
            bad = 'rejected'
        elif m and 'A,' not in m.group(1) and \
             bytes(int(x, 16) for x in m.group(1).split(',')) == want:
            bad = 'ALIAS (same encoding as another spelling)'
        else:
            bad = 'WRONG BYTES'
        print(f'{sp:31s} {got:22s} {rom_hex:18s} {bad}\n{"":31s} {why}')
    sys.exit(0)


def spell(b):
    """Spelling from the RAW BYTES.  None = no spelling exists."""
    mn, regs = SIZE[b[0] >> 4]
    width = b[0] & 0xF
    if width == 0:
        return None
    addr = int.from_bytes(b[1:-1], 'little')
    if NEG:                       # negative control: width from the VALUE
        suffix = '_24' if addr > 0xFFFF else ''
    else:
        suffix = '_24' if width == 2 else ''
    return f'{mn}{suffix} {regs[b[-1] & 7]}, (0x{addr:x})'


def assemble(spellings):
    """Batch-assemble; return {spelling: bytes or None}."""
    src = '\t.text\n' + ''.join('\t' + s + '\n' for s in spellings)
    p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                       input=src, capture_output=True, text=True)
    out, res = p.stdout.split('\n'), {}
    encs = [m.group(1) for line in out for m in [ENC.search(line)] if m]
    # llvm-mc still prints an encoding after an error, so only trust a clean run
    if p.returncode != 0 or len(encs) != len(spellings):
        for s in spellings:                     # fall back to one at a time
            q = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                               input='\t.text\n\t' + s + '\n',
                               capture_output=True, text=True)
            m = ENC.search(q.stdout)
            res[s] = (bytes(int(x, 16) for x in m.group(1).split(','))
                      if m and q.returncode == 0 else None)
        return res
    for s, e in zip(spellings, encs):
        res[s] = bytes(int(x, 16) for x in e.split(','))
    return res


grand_ok = grand_tot = grand_new_ok = grand_new_tot = 0
for name, base, is_new in BINS:
    path = os.path.join(REPO, 'original_ROMs', name)
    rom = open(path, 'rb').read()
    out = subprocess.run([UNI, path, '-arch', 'tlcs900', '-basepc', hex(base)],
                         capture_output=True, text=True).stdout
    sites, unspell = [], collections.Counter()
    for line in out.split('\n'):
        m = LINE.match(line)
        if not m or not TEXT.match(m.group(3)):
            continue
        addr = int(m.group(1), 16)
        listed = bytes(int(x, 16) for x in m.group(2).split())
        real = rom[addr - base: addr - base + len(listed)]
        assert real == listed, (f'{name} {addr:06x}: ROM FILE has '
                                f'{real.hex()} but listing says {listed.hex()}')
        s = spell(real)
        if s is None:
            unspell[f'{real[0]:02x}'] += 1
        else:
            sites.append((addr, real, s))

    enc = assemble(sorted({s for _, _, s in sites}))
    ok = collections.Counter(); bad = []
    for addr, real, s in sites:
        if enc.get(s) == real:
            ok[f'{real[0]:02x} len{len(real)}'] += 1
        else:
            bad.append((addr, real, s, enc.get(s)))
    tot = len(sites)
    tag = '  [NEW]' if is_new else ''
    print(f'=== {name} @ {base:#08x}: {tot + sum(unspell.values())} sites{tag}')
    for k in sorted(ok):
        print(f'    byte-exact {ok[k]:6d}   {k}')
    for addr, real, s, got in bad[:10]:
        print(f'    FAIL {addr:06x}: rom {real.hex(" ")} != '
              f'{"(rejected)" if got is None else got.hex(" ")}  <- {s}')
    print(f'    byte-exact {tot - len(bad)} / {tot} spellable, {len(bad)} failures'
          + (f'; NO SPELLING for {sum(unspell.values())} '
             f'({", ".join(f"{k} x{v}" for k, v in sorted(unspell.items()))})'
             if unspell else ''))
    grand_ok += tot - len(bad); grand_tot += tot
    if is_new:
        grand_new_ok += tot - len(bad); grand_new_tot += tot

print(f'\nGRAND TOTAL {grand_ok} / {grand_tot} spellable sites byte-exact, '
      f'{grand_tot - grand_ok} failures'
      + ('   [NEGATIVE CONTROL: failures here prove the check can fail]' if NEG else ''))
print(f'  of which the four never-checked binaries: {grand_new_ok} / {grand_new_tot}')
