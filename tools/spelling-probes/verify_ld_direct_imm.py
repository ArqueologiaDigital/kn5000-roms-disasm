#!/usr/bin/env python3
"""FULL verification of the llvm-mc spelling rule for the unidasm printed form
`ld (imm),imm` -- store an immediate to a DIRECT address -- in the KN5000
maincpu ROMs (v7, v9, v10).

QUESTION ANSWERED
  One printed text, `ld (0xADDR),0xIMM`, is EIGHT distinct TLCS-900 encodings.
  Which llvm-mc mnemonic reproduces each of them BYTE-EXACTLY, and can the
  choice be made from the raw bytes alone (a converter has nothing else)?

RULE UNDER TEST -- keyed on the RAW BYTES, never on the printed text:

  08 aa ii              (3B)  ->  ldio     0xaa, 0xii
  0a aa ll hh           (4B)  ->  ldwio    0xaa, 0x<hh><ll>
  f0 aa 00 ii           (4B)  ->  stib_d8  0xaa, 0xii
  f0 aa 02 ll hh        (5B)  ->  stiw_d8  0xaa, 0xll, 0xhh     <- raw byte PAIR
  f1 al ah 00 ii        (5B)  ->  stdi8    (0x<ah><al>), 0xii
  f1 al ah 02 ll hh     (6B)  ->  stdi16   (0x<ah><al>), 0x<hh><ll>
  f2 a0 a1 a2 00 ii     (6B)  ->  stib_da  (0x<a2><a1><a0>), 0xii
  f2 a0 a1 a2 02 ll hh  (7B)  ->  stiw_da  (0x<a2><a1><a0>), 0x<hh><ll>

  Byte 0 is the destination-memory prefix and picks the ADDRESS WIDTH
  (f0 = 8-bit direct, f1 = 16-bit, f2 = 24-bit; 08/0a are the standalone
  8-bit-direct opcodes).  The sub-opcode after the address picks the DATA
  WIDTH (0x00 = byte, 0x02 = word).  Nothing in the printed text carries
  either fact, which is why the rule must read the bytes.

PASS = llvm-mc --show-encoding output == the ROM bytes at that address.
"Assembled without error" is NOT a pass, and this backend proves it: see
--negative below, and the DANGEROUS list at the bottom of this docstring.

RUN
  python3 tools/spelling-probes/verify_ld_direct_imm.py
  python3 tools/spelling-probes/verify_ld_direct_imm.py --negative

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  v7  14067 / 14067 byte-exact   (5501 + 4062 + 141 + 3 + 2995 + 730 + 418 + 217)
  v9  14040 / 14040 byte-exact
  v10 14041 / 14041 byte-exact
  GRAND TOTAL 42148 / 42148, 0 failures.
  --negative (plausible-but-wrong rule): 42148 / 42148 sites FAIL, which is what
  makes the positive run mean something.

DANGEROUS SPELLINGS -- these ASSEMBLE and emit the WRONG bytes, silently:
  ld (0x00), 0x09      -> [f2,A,A,A,00,09]  the address becomes a 24-bit
                          RELOCATION and the prefix is always F2: 6 bytes where
                          the ROM has 3.  `ld` is the obvious first guess.
  ldio 0x00, 0x0002    -> [08,00,02]        truncates the WORD immediate to a
                          byte: 3 bytes where the ROM has 4 (0a 00 02 00).
                          `ld (0x00),0x0002` is exactly the printed text that
                          invites this.
  ldwio 0x00, 0x09     -> [0a,00,09,00]     widens a byte store to a word.
  stdi8 (0x3e), 0x00   -> [f1,3e,00,00,00]  5 bytes; the F0 form is 4.
  stib_da (0x3e), 0x00 -> [f2,3e,00,00,00,00]
  stdi8 (0xe0), 0x0140 -> [f1,e0,00,00,40]  immediate silently truncated.
  stib_d8 0x1234, 0x00 -> [f0,34,00,00]     address silently truncated.
  ldw / ldmi16 / ldmw2 with a parenthesised literal: all take the MEMri path and
  emit F2 + relocation, like `ld` above.
Only `stiw_d8 0x00, 0xf03d` refuses -- it demands the immediate as two raw
bytes, which is the one place the backend protects you.
"""
import os, re, subprocess, collections, sys

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
BASE = 0xE00000
ROMS = ['kn5000_v7_program.rom', 'kn5000_v9_program.rom', 'kn5000_v10_program.rom']

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^ld \((0x[0-9a-f]+)\),(0x[0-9a-f]+)$')


def spell(b):
    """The rule. Spelling as a function of the RAW BYTES; None = no rule."""
    n = len(b)
    if b[0] == 0x08 and n == 3:
        return f'ldio 0x{b[1]:02x}, 0x{b[2]:02x}'
    if b[0] == 0x0a and n == 4:
        return f'ldwio 0x{b[1]:02x}, 0x{b[3] << 8 | b[2]:04x}'
    if b[0] == 0xf0 and n == 4 and b[2] == 0x00:
        return f'stib_d8 0x{b[1]:02x}, 0x{b[3]:02x}'
    if b[0] == 0xf0 and n == 5 and b[2] == 0x02:
        return f'stiw_d8 0x{b[1]:02x}, 0x{b[3]:02x}, 0x{b[4]:02x}'
    if b[0] == 0xf1 and n == 5 and b[3] == 0x00:
        return f'stdi8 (0x{b[2] << 8 | b[1]:04x}), 0x{b[4]:02x}'
    if b[0] == 0xf1 and n == 6 and b[3] == 0x02:
        return f'stdi16 (0x{b[2] << 8 | b[1]:04x}), 0x{b[5] << 8 | b[4]:04x}'
    if b[0] == 0xf2 and n == 6 and b[4] == 0x00:
        return f'stib_da (0x{b[3] << 16 | b[2] << 8 | b[1]:06x}), 0x{b[5]:02x}'
    if b[0] == 0xf2 and n == 7 and b[4] == 0x02:
        return f'stiw_da (0x{b[3] << 16 | b[2] << 8 | b[1]:06x}), 0x{b[6] << 8 | b[5]:04x}'
    return None


def spell_wrong(b):
    """NEGATIVE CONTROL: the rule a reader of the PRINTED TEXT would write --
    one address operand, one immediate operand, mnemonic chosen by immediate
    width only. Every line of it assembles. None of it matches the ROM."""
    n = len(b)
    addr = {3: b[1], 4: b[1] if b[0] in (0x0a, 0xf0) else b[1],
            5: b[1], 6: b[1], 7: b[1]}[n]
    if b[0] == 0x08:
        return f'ldio 0x{b[1]:02x}, 0x{b[2]:02x}'.replace('ldio', 'ldwio')
    if b[0] == 0x0a:
        return f'ldio 0x{b[1]:02x}, 0x{b[3] << 8 | b[2]:04x}'
    if b[0] == 0xf0:
        return (f'stdi8 (0x{b[1]:02x}), 0x{b[3]:02x}' if n == 4
                else f'stdi16 (0x{b[1]:02x}), 0x{b[4] << 8 | b[3]:04x}')
    if b[0] == 0xf1:
        return (f'stib_da (0x{b[2] << 8 | b[1]:04x}), 0x{b[4]:02x}' if n == 5
                else f'stiw_da (0x{b[2] << 8 | b[1]:04x}), 0x{b[5] << 8 | b[4]:04x}')
    if b[0] == 0xf2:
        return (f'stdi8 (0x{b[3] << 16 | b[2] << 8 | b[1]:06x}), 0x{b[5]:02x}' if n == 6
                else f'stdi16 (0x{b[3] << 16 | b[2] << 8 | b[1]:06x}), 0x{b[6] << 8 | b[5]:04x}')
    return None


def assemble(texts):
    """One llvm-mc run for the whole batch; returns {text: bytes}."""
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


def sites_of(rom_path):
    rom = open(rom_path, 'rb').read()
    dis = subprocess.run([UNI, rom_path, '-arch', 'tlcs900', '-basepc', hex(BASE)],
                         capture_output=True, text=True).stdout
    out = []
    for line in dis.split('\n'):
        m = LINE.match(line)
        if not m or not TEXT.match(m.group(3)):
            continue
        addr = int(m.group(1), 16)
        by = bytes(int(x, 16) for x in m.group(2).split())
        assert rom[addr - BASE:addr - BASE + len(by)] == by, hex(addr)
        out.append((addr, by))
    return out


def main():
    rule = spell_wrong if '--negative' in sys.argv else spell
    if rule is spell_wrong:
        print('NEGATIVE CONTROL: deliberately wrong rule. '
              'Every site below SHOULD fail.\n')
    grand = collections.Counter()
    for rom_name in ROMS:
        sites = sites_of(os.path.join(REPO, 'original_ROMs', rom_name))
        texts = sorted({rule(b) for _, b in sites if rule(b)})
        enc = assemble(texts)
        ok, bad = collections.Counter(), []
        for addr, by in sites:
            t = rule(by)
            e = enc.get(t) if t else None
            key = f'{by[0]:02x} len{len(by)}'
            if e == by:
                ok[key] += 1
            else:
                bad.append((addr, by, t, e))
        print(f'=== {rom_name}: {len(sites)} sites, {len(texts)} distinct spellings')
        for k in sorted(ok):
            print(f'    byte-exact {ok[k]:6d}   {k}')
        print(f'    TOTAL byte-exact {sum(ok.values())} / {len(sites)}'
              f'   failures {len(bad)}')
        for addr, by, t, e in bad[:8]:
            print(f'    FAIL {addr:06x} rom={by.hex(" ")} tried={t!r} '
                  f'got={e.hex(" ") if e else "REJECTED/RELOC/NO-RULE"}')
        if len(bad) > 8:
            print(f'    ... and {len(bad) - 8} more')
        grand['sites'] += len(sites); grand['ok'] += sum(ok.values())
        grand['bad'] += len(bad)
    print(f'\nGRAND TOTAL {grand["ok"]} / {grand["sites"]} byte-exact, '
          f'{grand["bad"]} failures')


main()
