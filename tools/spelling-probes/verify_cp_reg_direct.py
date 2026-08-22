#!/usr/bin/env python3
"""FULL verification of the llvm-mc spelling rule for the unidasm printed form
`cp r,(imm)` -- compare a register against a DIRECT (absolute) address -- in the
KN5000 maincpu ROMs (v7, v9, v10) and in the table-data ROM.

QUESTION ANSWERED
  One printed text, `cp WA,(0x0ee8)`, is NINE distinct TLCS-900 encodings: three
  operand sizes (byte / word / long) times three address widths (8 / 16 / 24
  bit).  Which llvm-mc mnemonic reproduces each of them BYTE-EXACTLY, and can
  the choice be made from the raw bytes alone (a converter has nothing else)?

RULE UNDER TEST -- keyed on the RAW BYTES, never on the printed text:

  c1 al ah    F0+r   (4B)  ->  cpda8     <GR8[r]>, (0x<ah><al>)
  d1 al ah    F0+r   (4B)  ->  cpda16    <GPR[r]>, (0x<ah><al>)
  e1 al ah    F0+r   (4B)  ->  cpda32    <GPR[r]>, (0x<ah><al>)
  c2 a0 a1 a2 F0+r   (5B)  ->  cpda8_24  <GR8[r]>, (0x<a2><a1><a0>)
  d2 a0 a1 a2 F0+r   (5B)  ->  cpda16_24 <GPR[r]>, (0x<a2><a1><a0>)
  e2 a0 a1 a2 F0+r   (5B)  ->  cpda32_24 <GPR[r]>, (0x<a2><a1><a0>)
  c0 aa       F0+r   (3B)  ->  NO SPELLING EXISTS (see below)
  d0 aa       F0+r   (3B)  ->  NO SPELLING EXISTS
  e0 aa       F0+r   (3B)  ->  NO SPELLING EXISTS

    GR8[r] = w a b c d e h l          (r = last byte & 7)
    GPR[r] = xwa xbc xde xhl xix xiy xiz xsp

  Byte 0's HIGH nibble picks the OPERAND SIZE (c=byte, d=word, e=long) and its
  LOW nibble picks the ADDRESS WIDTH (0 = 8-bit direct, 1 = 16-bit, 2 = 24-bit).
  The last byte is 0xF0+r and picks the register.

  The register NAME in the printed text does carry the operand size (A vs WA vs
  XWA), but the address width is only visible as the number of printed hex
  digits (2 / 4 / 6, always zero-padded -- verified: prefix low nibble and digit
  count agree on 2881/2881 sites).  Do not derive it from the address VALUE:
  `cpda8 a, (0x00ffe3)` assembles happily and SILENTLY TRUNCATES to c1 e3 ff f1,
  4 bytes where the ROM has 5.  That is what --negative measures.

  ⚠ cpda16/cpda32 want the X-names even for word operands: `cpda16 xwa` IS
  `cp WA,(...)`.  `cpda16 wa` is rejected.  cpda8 wants the GR8 names; it also
  ACCEPTS the X-names and then silently means that register's LOW BYTE
  (cpda8 xbc -> f3 = C, not f1), with xde/xiy and xhl/xsp colliding.

PASS = llvm-mc --show-encoding output == the ROM bytes at that address.
"Assembled without error" is NOT a pass.

RUN
  python3 tools/spelling-probes/verify_cp_reg_direct.py
  python3 tools/spelling-probes/verify_cp_reg_direct.py --negative
  python3 tools/spelling-probes/verify_cp_reg_direct.py --dangerous

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  v7    864 /  864 byte-exact   (325 c1 + 258 d1 + 96 e1 + 62 c2 + 84 d2 + 39 e2)
  v9    865 /  865 byte-exact   (325 + 257 + 96 + 62 + 85 + 40)
  v10   865 /  865 byte-exact
  table  99 /   99 byte-exact   (14 + 15 + 14 + 13 + 19 + 24)
  GRAND TOTAL 2693 / 2693 spellable sites, 0 failures.
  --negative (address width taken from the VALUE): 2502 / 2693, 191 failures --
  every 24-bit-encoded site whose address happens to fit in 16 bits.

  188 further sites use the 8-bit-direct prefixes c0/d0/e0, for which the
  backend has no form at all (TLCS900InstrFormats.td gives AddrWidth ONE bit:
  16- or 24-bit only).  NONE of them is real code -- see
  frame_cp_reg_direct_imm8.py, which re-frames all 33 v9 sites from the nearest
  symbol of the byte-exact v9 build and finds every one inside a pointer table,
  a widget descriptor or an .incbin bitmap.  So this is a gap that costs
  nothing; do not add an instruction for it on this evidence.
"""
import os, re, subprocess, collections, sys

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

ROMS = [('kn5000_v7_program.rom',  0xE00000),
        ('kn5000_v9_program.rom',  0xE00000),
        ('kn5000_v10_program.rom', 0xE00000),
        ('kn5000_table_data.rom',  0x200000)]

GR8 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
GPR = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']
MNEM = {0xC: 'cpda8', 0xD: 'cpda16', 0xE: 'cpda32'}

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp ([A-Za-z]+),\((0x[0-9a-f]+)\)$')


def spell(b):
    """The rule. Spelling as a function of the RAW BYTES; None = no rule."""
    if len(b) < 3 or (b[-1] & 0xF8) != 0xF0:
        return None
    size, width, r = b[0] >> 4, b[0] & 0x0F, b[-1] & 7
    if size not in MNEM or width not in (1, 2):
        return None                      # width 0 = 8-bit direct: no form
    if len(b) != width + 3:
        return None
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    reg = GR8[r] if size == 0xC else GPR[r]
    return f'{MNEM[size]}{"_24" if width == 2 else ""} {reg}, (0x{addr:0{width*2}x})'


def spell_wrong(b):
    """NEGATIVE CONTROL: the rule a reader of the PRINTED TEXT would write --
    operand size from the register name (correct), but ADDRESS WIDTH from the
    address VALUE instead of from the prefix byte. Every line of it assembles.
    It is wrong at every 24-bit-encoded site whose address fits in 16 bits."""
    if len(b) < 3 or (b[-1] & 0xF8) != 0xF0:
        return None
    size, width, r = b[0] >> 4, b[0] & 0x0F, b[-1] & 7
    if size not in MNEM or width not in (1, 2) or len(b) != width + 3:
        return None
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    reg = GR8[r] if size == 0xC else GPR[r]
    return f'{MNEM[size]}{"_24" if addr > 0xFFFF else ""} {reg}, (0x{addr:x})'


def assemble(texts):
    """One llvm-mc run for the whole batch; returns {text: bytes or None}."""
    src = '\n'.join(texts) + '\n'
    p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                       input=src, capture_output=True, text=True)
    encs = re.findall(r'encoding: \[([^\]]*)\]', p.stdout)
    if len(encs) != len(texts):
        sys.exit(f'llvm-mc returned {len(encs)} encodings for {len(texts)} lines\n'
                 + p.stderr[:2000])
    out = {}
    for t, e in zip(texts, encs):
        try:
            out[t] = bytes(int(x, 16) for x in e.split(','))
        except ValueError:
            out[t] = None          # contains a relocation placeholder 'A'
    return out


def sites_of(rom_path, base):
    rom = open(rom_path, 'rb').read()
    dis = subprocess.run([UNI, rom_path, '-arch', 'tlcs900', '-basepc', hex(base)],
                         capture_output=True, text=True).stdout
    out = []
    for line in dis.split('\n'):
        m = LINE.match(line)
        if not m or not TEXT.match(m.group(3)):
            continue
        addr = int(m.group(1), 16)
        by = bytes(int(x, 16) for x in m.group(2).split())
        assert rom[addr - base:addr - base + len(by)] == by, hex(addr)
        out.append((addr, by))
    return out


DANGEROUS = [
    # (spelling, what it really emits / why it is wrong)
    ('cp a, (0x1234)',        'REJECTED: "byte/word direct memory load not encodable"'),
    ('cp wa, (0x1234)',       'REJECTED: same'),
    ('cp xwa, (0x1234)',      'e2 + 24-bit RELOCATION -- always the _24 form, 5 bytes'),
    ('cpda16 wa, (0x0ee8)',   'REJECTED: cpda16/32 want the X-names'),
    ('cpda8 xbc, (0x03ce)',   'c1 ce 03 f3 -- the LOW BYTE of XBC is C(3), not B(2)'),
    ('cpda8 xde, (0x03ce)',   'c1 ce 03 f5 -- collides with cpda8 xiy'),
    ('cpda8 xhl, (0x03ce)',   'c1 ce 03 f7 -- collides with cpda8 xsp'),
    ('cpda8 a, (0x00ffe3)',   'c1 e3 ff f1 -- 24-bit address SILENTLY TRUNCATED'),
    ('cpda16 xhl, (0x00ffd4)', 'd1 d4 ff f3 -- ditto'),
    ('cpda32 xwa, (0x030444)', 'e1 44 04 f0 -- ditto'),
    ('cpda8_24 a, (0x03ce)',  'c2 ce 03 00 f1 -- 5 bytes where the 16-bit form is 4'),
    ('cpda16_24 xwa, (0x0ee8)', 'd2 e8 0e 00 f0 -- ditto'),
]


def dangerous():
    print('Spellings that ASSEMBLE (or are rejected) but do NOT give the '
          'expected bytes.\nEach line assembled live:\n')
    for text, note in DANGEROUS:
        p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                           input=text + '\n', capture_output=True, text=True)
        m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
        got = m.group(1).replace('0x', '').replace(',', ' ') if m else '-'
        if p.returncode != 0:
            # llvm-mc still prints a junk 1-byte encoding after the error;
            # the non-zero exit is the only honest signal.
            got = 'rejected (' + got + ')'
        print(f'  {text:28s} -> {got:24s} {note}')


def main():
    if '--dangerous' in sys.argv:
        dangerous()
        return
    rule = spell_wrong if '--negative' in sys.argv else spell
    if rule is spell_wrong:
        print('NEGATIVE CONTROL: address width taken from the VALUE, not the '
              'prefix byte.\nEvery 24-bit-encoded site with a small address '
              'SHOULD fail.\n')
    grand = collections.Counter()
    for rom_name, base in ROMS:
        sites = sites_of(os.path.join(REPO, 'original_ROMs', rom_name), base)
        texts = sorted({rule(b) for _, b in sites if rule(b)})
        enc = assemble(texts)
        ok, bad, norule = collections.Counter(), [], collections.Counter()
        for addr, by in sites:
            t = rule(by)
            key = f'{by[0]:02x} len{len(by)}'
            if t is None:
                norule[key] += 1
                continue
            e = enc.get(t)
            if e == by:
                ok[key] += 1
            else:
                bad.append((addr, by, t, e))
        print(f'=== {rom_name}: {len(sites)} sites, {len(texts)} distinct spellings')
        for k in sorted(ok):
            print(f'    byte-exact {ok[k]:6d}   {k}')
        print(f'    TOTAL byte-exact {sum(ok.values())} / '
              f'{len(sites) - sum(norule.values())} spellable'
              f'   failures {len(bad)}')
        if norule:
            print(f'    NO SPELLING EXISTS for {sum(norule.values())} sites: '
                  + ', '.join(f'{k} x{v}' for k, v in sorted(norule.items())))
        for addr, by, t, e in bad[:8]:
            print(f'    FAIL {addr:06x} rom={by.hex(" ")} tried={t!r} '
                  f'got={e.hex(" ") if e else "REJECTED/RELOC/NO-RULE"}')
        if len(bad) > 8:
            print(f'    ... and {len(bad) - 8} more')
        grand['sites'] += len(sites); grand['ok'] += sum(ok.values())
        grand['bad'] += len(bad);     grand['norule'] += sum(norule.values())
    print(f'\nGRAND TOTAL {grand["ok"]} / {grand["sites"] - grand["norule"]} '
          f'spellable sites byte-exact, {grand["bad"]} failures; '
          f'{grand["norule"]} sites have no spelling (c0/d0/e0)')


main()
