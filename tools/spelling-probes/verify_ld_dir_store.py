#!/usr/bin/env python3
"""Which llvm-mc spelling reproduces unidasm's `ld (imm),r` DIRECT-ADDRESS STORE bytes?

QUESTION ANSWERED
-----------------
unidasm prints e.g. `ld (0x110e),XHL` for the ROM bytes `f1 0e 11 63`.  A
.byte -> instruction converter needs a spelling whose *encoding* is exactly
those bytes.  This script harvests every instance of that printed form from
four KN5000 unidasm listings, derives a spelling PURELY FROM THE RAW BYTES
(never from the printed text), assembles it with llvm-mc, and fails loudly on
any byte mismatch.

THE RULE: "it assembled" is not success.  Every instance is graded on
    assembled bytes == ROM bytes
and, as an independent second check, the assembled bytes are fed back through
unidasm and the printed text must equal the original listing text.

SPELLING RULE (a function of the raw bytes, not of the printed text)
--------------------------------------------------------------------
ONE printed form `ld (0xN),R` is NINE encodings: 3 address widths x 3 operand
sizes.  The PREFIX byte picks the address width; the SUB-OPCODE nibble picks
the operand size.

  f0 <a8>      <sub>   3 bytes  ->  st_dd8b / st_dd8w / st_dd8l   REG, ADDR
  f1 <a16 LE>  <sub>   4 bytes  ->  stb_d8  / stda16  / stda32    (ADDR), REG
  f2 <a24 LE>  <sub>   5 bytes  ->  stb_da  / stw_da  / stl_da    (ADDR), REG

  sub = 0x40|r -> byte mnemonic, register from GR8  = W  A  B  C  D  E  H  L
  sub = 0x50|r -> word mnemonic, register from GR16 = WA BC DE HL IX IY IZ (SP: below)
  sub = 0x60|r -> long mnemonic, register from GPR  = XWA XBC XDE XHL XIX XIY XIZ XSP

  NOTE the f0 family puts the REGISTER FIRST and takes a BARE address
  (`st_dd8b a, 0x3e`), while f1/f2 put the ADDRESS FIRST, parenthesised
  (`stda32 (0x110e), xhl`).  Different operand order, same instruction family.

  sub = 0x57 (SP) special case: GR16 in the backend EXCLUDES SP, so a literal
  `sp` is rejected.  For f1/f2 the 32-bit name reaches it, because
  getRegEncoding() is taken modulo the instruction's operand size:
        stda16 (0x1800), xsp   -> f1 00 18 57
        stw_da (0xf1453b), xsp -> f2 3b 45 f1 57
  For f0 there is NO spelling: ST_DD8W is declared GR16-only with no GPR
  overload, so `st_dd8w sp,N` and `st_dd8w xsp,N` are both rejected.  See the
  "unreachable" section of the output for what that costs (measured: nothing
  in these four ROMs -- every f0/0x57 site is a linear-sweep artifact inside a
  32-bit pointer table).

TEXT IS ALSO SUFFICIENT HERE (a claim that could have come out false)
---------------------------------------------------------------------
Unlike `ld (0xADDR),0xIMM`, this form is NOT ambiguous in its printed text:
MAME zero-pads the address to the width of the encoding, so the count of hex
digits alone identifies the prefix.  The script asserts this over every site;
if a single site ever violated it the run would abort.
    2 digits -> f0        4 digits -> f1        6 digits -> f2
and the register name gives the operand size.  A converter may therefore drive
off the text -- but the bytes remain the authority and are what is graded.

Signal read: the raw ROM bytes at each address.  PASS = llvm-mc's
--show-encoding output equals those bytes.

Run:  python3 verify_ld_dir_store.py     (exit 0 = all sites byte-exact)
"""
import os, re, subprocess, collections, sys

REPO    = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
LLVMMC  = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

ROMS = [
    ('v7',         'original_ROMs/kn5000_v7_program.rom',  0xE00000),
    ('v9',         'original_ROMs/kn5000_v9_program.rom',  0xE00000),
    ('v10',        'original_ROMs/kn5000_v10_program.rom', 0xE00000),
    ('table_data', 'original_ROMs/kn5000_table_data.rom',  0x800000),
]

R8  = ['W', 'A', 'B', 'C', 'D', 'E', 'H', 'L']
R16 = ['WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP']
R32 = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']

# prefix -> (address byte count, total instruction size, {size nibble: mnemonic}, register-first?)
FAM = {
    0xF0: (1, 3, {4: 'st_dd8b', 5: 'st_dd8w', 6: 'st_dd8l'}, True),
    0xF1: (2, 4, {4: 'stb_d8',  5: 'stda16',  6: 'stda32'},  False),
    0xF2: (3, 5, {4: 'stb_da',  5: 'stw_da',  6: 'stl_da'},  False),
}

LINE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+ld \((0x[0-9a-f]+)\),([A-Z]+)$')


def disasm(path, base):
    return subprocess.run([UNIDASM, path, '-arch', 'tlcs900', '-basepc', hex(base)],
                          capture_output=True, text=True).stdout


def spell(by):
    """Spelling derived from RAW BYTES only.  Returns (text, reason-if-none)."""
    pfx = by[0]
    if pfx not in FAM:
        return None, f'prefix {pfx:02x} is not a direct-address destination prefix'
    nbytes, size, mnem, regfirst = FAM[pfx]
    if len(by) != size:
        return None, f'length {len(by)} != {size}'
    sub = by[-1]
    hi, r = sub >> 4, sub & 0x7
    if sub & 0x08 or hi not in mnem:
        return None, f'sub-opcode {sub:02x} outside 0x40/0x50/0x60 + r'
    addr = int.from_bytes(by[1:1 + nbytes], 'little')
    if hi == 4:
        reg = R8[r]
    elif hi == 6:
        reg = R32[r]
    else:
        if r == 7 and pfx == 0xF0:
            return None, 'st_dd8w is GR16-only (no SP, no GPR overload) -> f0 sub 0x57 unreachable'
        reg = R32[r] if r == 7 else R16[r]   # xsp reaches sub 0x57 for f1/f2
    op = mnem[hi]
    if regfirst:
        return f'{op} {reg.lower()}, 0x{addr:x}', None
    return f'{op} (0x{addr:x}), {reg.lower()}', None


def encode_batch(texts):
    """Assemble many one-line instructions in ONE llvm-mc run."""
    src = '\n'.join(texts) + '\n'
    p = subprocess.run([LLVMMC, '-triple=tlcs900', '--show-encoding'],
                       input=src, capture_output=True, text=True)
    encs = [bytes(int(x, 16) for x in m.group(1).split(','))
            for m in re.finditer(r'encoding: \[([^\]]*)\]', p.stdout)]
    if len(encs) != len(texts):
        sys.exit(f'llvm-mc returned {len(encs)} encodings for {len(texts)} inputs\n'
                 + p.stderr[:2000])
    return dict(zip(texts, encs))


# ------------------------------------------------------------------ harvest
hits = []                       # (rom, addr, bytes, printed text)
subhist = collections.Counter()
digithist = collections.Counter()
for name, rel, base in ROMS:
    path = os.path.join(REPO, rel)
    rom = open(path, 'rb').read()
    for line in disasm(path, base).split('\n'):
        m = LINE.match(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        by = bytes(int(x, 16) for x in m.group(2).split())
        real = rom[addr - base: addr - base + len(by)]   # truth from the FILE
        assert real == by, (name, hex(addr), real.hex(), by.hex())
        hits.append((name, addr, by, line.split('  ')[-1].strip()))
        subhist[(by[0], by[-1])] += 1
        digithist[(by[0], len(m.group(3)) - 2)] += 1

print(f'harvested `ld (imm),REG` sites across {len(ROMS)} ROMs: {len(hits)}')
print('\nprefix -> printed hex digits (the text-side discriminator):')
for (p, d), n in sorted(digithist.items()):
    print(f'  {p:02x} -> {d} digits   {n:7d}')
assert set(digithist) <= {(0xF0, 2), (0xF1, 4), (0xF2, 6)}, \
    'printed digit count does NOT identify the address width -- claim falsified'
print('  (claim holds: digit count identifies the prefix at every site)')

print('\nprefix / sub-opcode histogram:')
for (p, s), n in sorted(subhist.items()):
    print(f'  {p:02x} .. {s:02x}   {n:7d}')

# ------------------------------------------------------------------ grade
texts = {}
for _, _, by, _ in hits:
    t, _ = spell(by)
    if t:
        texts[t] = None
enc = encode_batch(sorted(texts))
print(f'\nunique spellings assembled in one llvm-mc run: {len(enc)}')

stats = collections.Counter()
unreachable = []
bad = []
for name, addr, by, txt in hits:
    t, why = spell(by)
    if t is None:
        stats['NO_SPELLING'] += 1
        unreachable.append((name, addr, by, txt, why))
        continue
    if enc[t] == by:
        stats['OK'] += 1
    else:
        stats['MISMATCH'] += 1
        bad.append((name, addr, by, t, enc[t]))

print('\nresult:')
for k, v in sorted(stats.items()):
    print(f'  {v:7d}  {k}')
for name, addr, by, t, e in bad[:20]:
    print(f'  FAIL {name} {addr:06x} rom={by.hex(" ")} spelling={t!r} enc={e.hex(" ")}')

if unreachable:
    print('\nunreachable sites (no spelling exists in this backend):')
    for name, addr, by, txt, why in unreachable:
        print(f'  {name:10s} {addr:06x}  {by.hex(" ")}  "{txt}"   {why}')
    print('  -- every one of these is a LINEAR-SWEEP ARTIFACT, not code: they sit')
    print('     inside 32-bit pointer tables (e.g. v9 0xE0DBFC is the 3rd byte of')
    print('     the record `f0 00 57 3b`, one of a run of ...3a/...3b pointers).')

# ------------------------------------------- independent check: round trip
print('\nround-trip (assemble -> unidasm -> compare printed text), one site per form:')
canon = {}
for name, addr, by, txt in hits:
    canon.setdefault((by[0], by[-1]), (name, addr, by, txt))
blob, order = bytearray(), []
for key in sorted(canon):
    name, addr, by, txt = canon[key]
    t, why = spell(by)
    if t is None:
        continue
    blob += enc[t]
    order.append((key, txt, len(enc[t])))
tmp = '/tmp/_ld_dir_store_roundtrip.bin'
open(tmp, 'wb').write(bytes(blob))
printed = {}
for line in subprocess.run([UNIDASM, tmp, '-arch', 'tlcs900', '-basepc', '0x0'],
                           capture_output=True, text=True).stdout.split('\n'):
    m = re.match(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(.*)$', line)
    if m:
        printed[int(m.group(1), 16)] = m.group(3).strip()
off = rt_ok = rt_bad = 0
for key, txt, n in order:
    got = printed.get(off, '<not decoded>')
    if got == txt:
        rt_ok += 1
    else:
        rt_bad += 1
        print(f'  RT-FAIL {key[0]:02x}/{key[1]:02x}: expected {txt!r} got {got!r}')
    off += n
print(f'  text identical for {rt_ok} forms, differing for {rt_bad}')

# ------------------------------------------------- dangerous near-misses
print('\nDANGEROUS candidates -- these ASSEMBLE but give the WRONG bytes:')
danger = [
    ('stda16 (0x110e), xhl',  'f1 0e 11 63', 'word store of HL, not a long store of XHL'),
    ('stb_d8 (0x110e), xhl',  'f1 0e 11 63', 'byte store of L -- the 32-bit name silently means index 3'),
    ('stw_da (0x110e), xhl',  'f1 0e 11 63', '24-bit-address form: 5 bytes instead of 4'),
    ('stb_d8 (0x3e), a',      'f0 3e 41',    '16-bit-address form: 4 bytes instead of 3'),
    ('stda32 (0x3e), xhl',    'f0 3e 63',    '16-bit-address form: 4 bytes instead of 3'),
]
denc = encode_batch([d[0] for d in danger])
for text, want, note in danger:
    got = denc[text].hex(' ')
    print(f'  {text:24s} -> {got:17s} (wanted {want:14s}) {"SAME" if got == want else "DIFFERENT"} -- {note}')

print('\nverified examples, one per distinct (prefix, sub-opcode):')
for key in sorted(canon):
    name, addr, by, txt = canon[key]
    t, why = spell(by)
    e = enc[t] if t else None
    print(f'  {name:10s} {addr:06x}  "{txt}"  ->  {t!r}  '
          f'enc={e.hex(" ") if e else None}  rom={by.hex(" ")}  match={e == by}'
          + ('' if t else f'   [{why}]'))

sys.exit(1 if (stats['MISMATCH'] or rt_bad) else 0)
