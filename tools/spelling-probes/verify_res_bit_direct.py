#!/usr/bin/env python3
"""FULL verification of the llvm-mc spelling rule for the unidasm printed form
`res N,(imm)` -- clear bit N of the byte at a DIRECT (absolute) address -- in
the KN5000 maincpu ROMs (v7, v9, v10) and in the table-data ROM.

QUESTION ANSWERED
  One printed text, `res 0,(0x26e2)`, is THREE distinct TLCS-900 encodings --
  one per direct-address width (8 / 16 / 24 bit) -- and the printed text does
  not say which.  Which llvm-mc mnemonic reproduces each of them BYTE-EXACTLY,
  and can the choice be made from the raw bytes alone (a converter has nothing
  else)?

RULE UNDER TEST -- keyed on the RAW BYTES, never on the printed text:

  f0 aa        0xB0+bit  (3B)  ->  res_dd8  <bit>, 0x<aa>
  f1 al ah     0xB0+bit  (4B)  ->  resda    <bit>, (0x<ah><al>)
  f2 a0 a1 a2  0xB0+bit  (5B)  ->  resda_24 <bit>, (0x<a2><a1><a0>)

    bit = last byte & 7,  and (last byte & 0xF8) must be 0xB0.

  Byte 0 is the DESTINATION-direct prefix and it alone gives the address width:
  f0 = 8-bit, f1 = 16-bit, f2 = 24-bit.  The last byte is the bit-op sub-opcode
  0xB0+bit (0xB8+bit would be SET, 0xC8+bit BIT, 0xA0+bit TSET).

  ⚠ The three mnemonics are NOT interchangeable and none of them range-checks:
    * `resda   0, (0x00ffc2)` silently TRUNCATES to f1 c2 ff b0 -- 4 bytes where
      the ROM has 5.
    * `res_dd8 0, 0x26e2`     silently TRUNCATES to f0 e2 b0 -- 3 bytes where
      the ROM has 4.
    * `resda_24 0, (0x26e2)`  pads to 5 bytes where the ROM has 4.
    * a bit number >= 8 is NOT masked: `resda 8, (0x1234)` emits f1 34 12 b8,
      which is `set 0,(0x1234)` -- a DIFFERENT INSTRUCTION, silently.
    * the literal unidasm text `res 0, (0x26e2)` DOES assemble (it matches the
      `resm` InstAlias) and always emits the 24-bit form f2 + a 24-bit
      relocation.  It is a correct alternative spelling of resda_24 and never
      of resda / res_dd8.

PASS = llvm-mc --show-encoding output == the ROM bytes at that address.
"Assembled without error" is NOT a pass.

RUN
  python3 tools/spelling-probes/verify_res_bit_direct.py
  python3 tools/spelling-probes/verify_res_bit_direct.py --negative
  python3 tools/spelling-probes/verify_res_bit_direct.py --dangerous

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  kn5000_v7_program.rom    444 /  444 byte-exact  ( 21 f0 + 414 f1 +  9 f2)
  kn5000_v9_program.rom    446 /  446 byte-exact  ( 22 f0 + 415 f1 +  9 f2)
  kn5000_v10_program.rom   446 /  446 byte-exact  ( 22 f0 + 415 f1 +  9 f2)
  kn5000_table_data.rom     59 /   59 byte-exact  ( 30 f0 +  14 f1 + 15 f2)
  GRAND TOTAL 1395 / 1395 sites byte-exact, 0 failures, 0 unspellable.

  --negative (address width taken from the VALUE instead of the prefix byte):
  1382 / 1395, 13 failures -- every site encoded wider than its value needs,
  e.g. 0xE7F34F `f1 e7 00 b2` (16-bit encoding of an 8-bit-looking address) and
  0xFC79FB `f2 c2 ff 00 b0` (24-bit encoding of 0x00ffc2).

  Reading the width off the printed TEXT does work, because unidasm zero-pads
  the address to the encoded width: 2 hex digits <=> f0, 4 <=> f1, 6 <=> f2.
  Verified: printed digit count and prefix agree on 1395 / 1395 sites.
"""
import os, re, subprocess, collections, sys

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

ROMS = [('kn5000_v7_program.rom',  0xE00000),
        ('kn5000_v9_program.rom',  0xE00000),
        ('kn5000_v10_program.rom', 0xE00000),
        ('kn5000_table_data.rom',  0x200000)]

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^res ([0-7]),\((0x[0-9a-f]+)\)$')


def spell(b):
    """The rule. Spelling as a function of the RAW BYTES; None = no rule."""
    if len(b) < 3 or (b[-1] & 0xF8) != 0xB0:
        return None
    width = b[0] & 0x0F
    if b[0] >> 4 != 0xF or width not in (0, 1, 2) or len(b) != width + 3:
        return None
    bit = b[-1] & 7
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    if width == 0:                       # F0: addr8, mnemonic wants a BARE imm
        return f'res_dd8 {bit}, 0x{addr:02x}'
    if width == 1:
        return f'resda {bit}, (0x{addr:04x})'
    return f'resda_24 {bit}, (0x{addr:06x})'


def spell_wrong(b):
    """NEGATIVE CONTROL: the rule a reader of the PRINTED TEXT would write --
    correct mnemonic family, but ADDRESS WIDTH chosen from the address VALUE
    instead of from the prefix byte.  Every line of it assembles.  It is wrong
    at every site whose encoded width is wider than its value needs -- e.g.
    0xE7F34F `f1 e7 00 b2` = res 2,(0x00e7), where the value fits in 8 bits."""
    if len(b) < 3 or (b[-1] & 0xF8) != 0xB0:
        return None
    width = b[0] & 0x0F
    if b[0] >> 4 != 0xF or width not in (0, 1, 2) or len(b) != width + 3:
        return None
    bit = b[-1] & 7
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    if addr <= 0xFF:
        return f'res_dd8 {bit}, 0x{addr:02x}'
    if addr <= 0xFFFF:
        return f'resda {bit}, (0x{addr:04x})'
    return f'resda_24 {bit}, (0x{addr:06x})'


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


DIGITS = collections.Counter()


def sites_of(rom_path, base):
    """Every `res N,(0xADDR)` decode in a linear sweep, with the bytes read back
    from the ROM FILE (asserted equal to what the listing printed).

    Also tallies whether the number of hex digits unidasm printed matches the
    width the PREFIX byte encodes (2 <=> f0, 4 <=> f1, 6 <=> f2): that is what
    makes the rule readable off the listing text as well as off the bytes."""
    rom = open(rom_path, 'rb').read()
    dis = subprocess.run([UNI, rom_path, '-arch', 'tlcs900', '-basepc', hex(base)],
                         capture_output=True, text=True).stdout
    out = []
    for line in dis.split('\n'):
        m = LINE.match(line)
        t = TEXT.match(m.group(3)) if m else None
        if not t:
            continue
        addr = int(m.group(1), 16)
        by = bytes(int(x, 16) for x in m.group(2).split())
        assert rom[addr - base:addr - base + len(by)] == by, hex(addr)
        DIGITS['total'] += 1
        DIGITS['agree'] += (len(t.group(2)) - 2 == 2 * ((by[0] & 0x0F) + 1))
        out.append((addr, by))
    return out


DANGEROUS = [
    # (spelling, what it really emits / why it is wrong)
    ('res 0, (0x26e2)',       'f2 + 24-bit RELOC (resm alias) -- ALWAYS 5 bytes, '
                              'never the 4-byte f1 form the ROM has'),
    ('res 0, (0x00)',         'f2 + 24-bit RELOC -- 5 bytes where the f0 form is 3'),
    ('resm 0, (0x26e2)',      'same alias, same wrong width'),
    ('res 0, 0x26e2',         'REJECTED without the parentheses'),
    ('resda 0, (0x00ffc2)',   'f1 c2 ff b0 -- 24-bit address SILENTLY TRUNCATED, '
                              '4 bytes where the ROM has 5'),
    ('resda 0, (0x1ffc2)',    'f1 c2 ff b0 -- ditto, and no diagnostic at all'),
    ('res_dd8 0, 0x26e2',     'f0 e2 b0 -- 16-bit address SILENTLY TRUNCATED to '
                              'its LOW BYTE, 3 bytes where the ROM has 4'),
    ('resda_24 0, (0x26e2)',  'f2 e2 26 00 b0 -- 5 bytes where the 16-bit form is 4'),
    ('resda 8, (0x1234)',     'f1 34 12 b8 = `set 0,(0x1234)` -- the bit number is '
                              'NOT masked; 8 carries into the sub-opcode and turns '
                              'RES into SET'),
    ('res_dd8 8, 0x20',       'f0 20 b8 = `set 0,(0x20)` -- ditto'),
    ('resda (0x26e2), 0',     'f1 00 00 b2 = `res 2,(0x0000)` -- operands swapped '
                              'assembles happily and means something else'),
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
            got = 'rejected'
        print(f'  {text:24s} -> {got:20s} {note}')


def main():
    if '--dangerous' in sys.argv:
        dangerous()
        return
    rule = spell_wrong if '--negative' in sys.argv else spell
    if rule is spell_wrong:
        print('NEGATIVE CONTROL: address width taken from the VALUE, not the '
              'prefix byte.\nEvery site encoded wider than its value needs '
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
            if enc.get(t) == by:
                ok[key] += 1
            else:
                bad.append((addr, by, t, enc.get(t)))
        print(f'=== {rom_name}: {len(sites)} sites, {len(texts)} distinct spellings')
        for k in sorted(ok):
            print(f'    byte-exact {ok[k]:6d}   {k}')
        print(f'    TOTAL byte-exact {sum(ok.values())} / '
              f'{len(sites) - sum(norule.values())} spellable'
              f'   failures {len(bad)}')
        if norule:
            print(f'    NO SPELLING for {sum(norule.values())} sites: '
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
          f'{grand["norule"]} sites have no spelling')
    print(f'printed hex-digit count agrees with the prefix byte on '
          f'{DIGITS["agree"]} / {DIGITS["total"]} sites')


main()
