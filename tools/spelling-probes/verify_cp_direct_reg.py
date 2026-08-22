#!/usr/bin/env python3
"""Which llvm-mc spelling reproduces unidasm's `cp (imm),r` bytes EXACTLY?

QUESTION ANSWERED
-----------------
unidasm prints e.g. `cp (0x0d57),A` for the ROM bytes `c1 57 0d f9`: compare a
DIRECT (absolute) memory location against a register -- the store-direction
compare, sub-opcode 0xF8+r, as opposed to `cp r,(imm)` which is 0xF0+r and is
covered by verify_cp_reg_direct.py.

That ONE printed text is NINE distinct TLCS-900 encodings: three operand sizes
(byte / word / long) times three address widths (8 / 16 / 24 bit).  A converter
turning `.byte` blobs into instructions has only the RAW BYTES to choose from,
so the rule below is a function of the bytes and never of the printed text.

THE RULE (keyed on the raw bytes)
---------------------------------
    c1 al ah    F8+r   (4B)  ->  cpdm8     (0x<ah><al>),     <GR8[r]>
    d1 al ah    F8+r   (4B)  ->  cpdm16    (0x<ah><al>),     <GPR[r]>
    e1 al ah    F8+r   (4B)  ->  cpdm32    (0x<ah><al>),     <GPR[r]>
    c2 a0 a1 a2 F8+r   (5B)  ->  cpdm8_24  (0x<a2><a1><a0>), <GR8[r]>
    d2 a0 a1 a2 F8+r   (5B)  ->  cpdm16_24 (0x<a2><a1><a0>), <GPR[r]>
    e2 a0 a1 a2 F8+r   (5B)  ->  cpdm32_24 (0x<a2><a1><a0>), <GPR[r]>
    c0 aa       F8+r   (3B)  ->  NO SPELLING EXISTS  (see below)
    d0 aa       F8+r   (3B)  ->  NO SPELLING EXISTS
    e0 aa       F8+r   (3B)  ->  NO SPELLING EXISTS

    r      = last byte & 7
    GR8[r] = w a b c d e h l
    GPR[r] = xwa xbc xde xhl xix xiy xiz xsp

Byte 0's HIGH nibble picks the OPERAND SIZE (c = byte, d = word, e = long) and
its LOW nibble picks the ADDRESS WIDTH (0 = 8-bit direct, 1 = 16-bit, 2 =
24-bit).  The last byte is 0xF8+r and picks the register.

⚠ cpdm16/cpdm32 want the X-NAMES even for word operands: `cpdm16 (a), xwa` IS
`cp (a),WA`; `cpdm16 (a), wa` is rejected.  cpdm8/cpdm8_24 want the GR8 names.
Address may be written with or without parentheses.

PASS = llvm-mc --show-encoding output == the ROM bytes at that address.
"Assembled without error" is NOT a pass.  As an independent second check the
assembled bytes are fed back through unidasm and the printed text must equal
the original listing text.

RUN
  python3 tools/spelling-probes/verify_cp_direct_reg.py
  python3 tools/spelling-probes/verify_cp_direct_reg.py --negative
  python3 tools/spelling-probes/verify_cp_direct_reg.py --dangerous

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  v7     535 /  535 byte-exact  (317 c1 +  55 d1 + 120 e1 + 13 c2 + 21 d2 +  9 e2)
  v9     537 /  537 byte-exact  (317 c1 +  55 d1 + 122 e1 + 12 c2 + 21 d2 + 10 e2)
  v10    537 /  537 byte-exact  (identical to v9)
  table   89 /   89 byte-exact  ( 14 c1 +  24 d1 +  12 e1 +  8 c2 + 21 d2 + 10 e2)
  GRAND TOTAL 1698 / 1698 spellable sites byte-exact, 0 failures.
  Round-trip through unidasm: 1698 / 1698 print the original listing text.
  --negative (address width taken from the VALUE): 1621 / 1698, 77 failures --
  every 24-bit-encoded site whose address happens to fit in 16 bits.

  1030 further sweep hits have NO spelling: 1029 use the 8-bit-direct prefixes
  c0/d0/e0 (AddrWidth in TLCS900InstrFormats.td is ONE bit, and
  emitDirectAddrPrefix() can only ever emit c1/d1/e1 or c2/d2/e2), and ONE is a
  tenth encoding of the same printed text -- see below.  None of them is code:
  code_or_data_cp_direct_reg.py grades the v9 sweep against the DWARF line
  table of a -g rebuild that is byte-identical to the original ROM and finds
  0 / 275 of the c0/d0/e0 sites are source statements, against 120 / 494
  (c1/d1/e1) and 16 / 43 (c2/d2/e2) for the spellable classes.

⚠ A TENTH ENCODING: the printed text can also be PC-RELATIVE
  table_data 0x9D4D29 is `d3 13 14 b0 ff` and unidasm prints
  `cp (0x9cfd41),SP` -- the same shape, but prefix d3 is the *extended*
  addressing prefix and mode byte 0x13 is (PC + d16): 0x9D4D29 + 4 - 0x4FEC =
  0x9CFD41.  The absolute address is NOT IN THE INSTRUCTION.  Spelling it as a
  direct address assembles cleanly and is completely wrong:
  `cpdm16_24 (0x9cfd41), xsp` -> d2 41 fd 9c ff.  The rule below refuses it
  because it keys on the prefix byte, not on the text.  (That one site is data:
  it sits in a d3-led table with a descending index column, and unidasm emits
  eight undecodable `db` lines within the 0x40 bytes around it.)
"""
import os, re, subprocess, collections, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

ROMS = [('kn5000_v7_program.rom',  0xE00000),
        ('kn5000_v9_program.rom',  0xE00000),
        ('kn5000_v10_program.rom', 0xE00000),
        ('kn5000_table_data.rom',  0x800000)]

GR8 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
GPR = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']
MNEM = {0xC: 'cpdm8', 0xD: 'cpdm16', 0xE: 'cpdm32'}

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp \((0x[0-9a-f]+)\),([A-Za-z]+)$')


def spell(b):
    """The rule. Spelling as a function of the RAW BYTES; None = no rule."""
    if len(b) < 3 or (b[-1] & 0xF8) != 0xF8:
        return None
    size, width, r = b[0] >> 4, b[0] & 0x0F, b[-1] & 7
    if size not in MNEM or width not in (1, 2):
        return None                      # width 0 = 8-bit direct: no form
    if len(b) != width + 3:
        return None
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    reg = GR8[r] if size == 0xC else GPR[r]
    return f'{MNEM[size]}{"_24" if width == 2 else ""} (0x{addr:0{width*2}x}), {reg}'


def spell_wrong(b):
    """NEGATIVE CONTROL: the rule a reader of the PRINTED TEXT would write --
    operand size from the register name (correct) but ADDRESS WIDTH from the
    address VALUE instead of from the prefix byte.  Every line of it assembles;
    it is wrong at every 24-bit-encoded site whose address fits in 16 bits."""
    if len(b) < 3 or (b[-1] & 0xF8) != 0xF8:
        return None
    size, width, r = b[0] >> 4, b[0] & 0x0F, b[-1] & 7
    if size not in MNEM or width not in (1, 2) or len(b) != width + 3:
        return None
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    reg = GR8[r] if size == 0xC else GPR[r]
    return f'{MNEM[size]}{"_24" if addr > 0xFFFF else ""} (0x{addr:x}), {reg}'


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
        out.append((addr, by, m.group(3)))
    return out


def roundtrip(pairs):
    """Disassemble the ASSEMBLED bytes and require the printed text to match the
    original listing text.  pairs = [(bytes, expected_text), ...]."""
    blob, want = b'', []
    for by, txt in pairs:
        blob += by
        want.append((len(blob) - len(by), txt, len(by)))
    tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
    tf.write(blob); tf.close()
    out = subprocess.run([UNI, tf.name, '-arch', 'tlcs900', '-basepc', '0x0'],
                         capture_output=True, text=True).stdout
    os.unlink(tf.name)
    seen = {}
    for line in out.split('\n'):
        m = LINE.match(line)
        if m:
            seen[int(m.group(1), 16)] = m.group(3)
    ok = sum(1 for off, txt, _ in want if seen.get(off) == txt)
    bad = [(off, txt, seen.get(off)) for off, txt, _ in want if seen.get(off) != txt]
    return ok, len(want), bad


DANGEROUS = [
    ('cp (0x1234), a',          'REJECTED -- there is no plain `cp (mem),reg` mnemonic. '
                                'llvm-mc STILL prints `encoding: [0xf9]` after the error, '
                                'so trust the EXIT STATUS, not the listing'),
    ('cpdm8 a, (0x0d57)',       'REJECTED -- cpdm* take (addr), reg; the reg-first order '
                                'belongs to cpda*'),
    ('cpda8 a, (0x0d57)',       'c1 57 0d f1 -- the F0 LOAD-direction compare `cp A,(0x0d57)`. '
                                'Same prefix, same length, DIFFERENT INSTRUCTION'),
    ('cpdm16 (0x1234), wa',     'REJECTED -- cpdm16/cpdm32 want the X-names'),
    ('cpdm16 (0x1234), sp',     'REJECTED -- GR16 excludes SP; only `xsp` reaches sub-opcode ff'),
    ('cpdm8 (0x1234), xwa',     'c1 34 12 f9 -- the LOW BYTE of XWA is A(1), not W(0); '
                                'collides with `cpdm8 (..), a`'),
    ('cpdm8 (0x1234), xbc',     'c1 34 12 fb -- low byte of XBC is C(3), not B(2)'),
    ('cpdm8 (0x1234), xde',     'c1 34 12 fd -- collides with `cpdm8 (..), xiy` and with `e`'),
    ('cpdm8 (0x1234), xhl',     'c1 34 12 ff -- collides with `cpdm8 (..), xsp` and with `l`'),
    ('cpdm8 (0x00ce44), a',     'c1 44 ce f9 -- 24-bit address SILENTLY TRUNCATED, '
                                '4 bytes where the ROM has 5'),
    ('cpdm16 (0x0274e0), xde',  'd1 e0 74 fa -- ditto'),
    ('cpdm32 (0xffff00), xsp',  'e1 00 ff ff -- ditto'),
    ('cpdm8_24 (0x0d57), a',    'c2 57 0d 00 f9 -- 5 bytes where the 16-bit form is 4'),
    ('cpdm16_24 (0xe2c6), xwa', 'd2 c6 e2 00 f8 -- ditto'),
    ('cpdm32_24 (0xe921), xiz', 'e2 21 e9 00 fe -- ditto'),
    ('cpdm8 (0xac), e',         'c1 ac 00 fd -- the 8-bit-direct c0 form is UNREACHABLE; '
                                'this silently widens the address to 16 bits, '
                                '4 bytes where the ROM has 3'),
    ('cpdm16_24 (0x9cfd41), xsp', 'd2 41 fd 9c ff -- table_data 0x9D4D29 is '
                                'd3 13 14 b0 ff, a PC-RELATIVE compare that unidasm prints '
                                'with the RESOLVED absolute address. Worst trap of the set'),
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
        texts = sorted({rule(b) for _, b, _ in sites if rule(b)})
        enc = assemble(texts)
        ok, bad, norule = collections.Counter(), [], collections.Counter()
        rtpairs = []
        for addr, by, txt in sites:
            t = rule(by)
            key = f'{by[0]:02x} len{len(by)}'
            if t is None:
                norule[key] += 1
                continue
            e = enc.get(t)
            if e == by:
                ok[key] += 1
                rtpairs.append((e, txt))
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
        if rule is spell and rtpairs:
            rok, rtot, rbad = roundtrip(rtpairs)
            print(f'    round-trip through unidasm: {rok} / {rtot} print the '
                  f'original text')
            for off, want, got in rbad[:5]:
                print(f'      RT-FAIL off {off:#x} want {want!r} got {got!r}')
            grand['rt_ok'] += rok; grand['rt_tot'] += rtot
        grand['sites'] += len(sites); grand['ok'] += sum(ok.values())
        grand['bad'] += len(bad);     grand['norule'] += sum(norule.values())
    print(f'\nGRAND TOTAL {grand["ok"]} / {grand["sites"] - grand["norule"]} '
          f'spellable sites byte-exact, {grand["bad"]} failures; '
          f'{grand["norule"]} sites have no spelling (c0/d0/e0)')
    if grand['rt_tot']:
        print(f'round-trip {grand["rt_ok"]} / {grand["rt_tot"]}')
    sys.exit(1 if (rule is spell and (grand['bad'] or
                                      grand['rt_ok'] != grand['rt_tot'])) else 0)


main()
