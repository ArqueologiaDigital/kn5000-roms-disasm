#!/usr/bin/env python3
"""Probe: the llvm-mc spelling of the unidasm form `ldir` (and its `ldirw` sibling).

QUESTION ANSWERED
  unidasm prints `ldir` with NO operands, so the printed text carries none of
  the information that distinguishes the encodings.  A TLCS-900 block transfer
  is `0x80 + (size << 4) + ridx` followed by a sub-opcode; sub-opcode 0x11 is
  LDIR.  The `ridx` nibble is ignored by the hardware but IS in the ROM, so
  eight different byte pairs (0x80..0x87, 0x11) all print `ldir`, and eight more
  (0x90..0x97, 0x11) all print `ldirw`.  Which of them can be spelled today, and
  what does the WRONG spelling cost?

RUN   python3 tools/spelling-probes/verify_ldir.py
      python3 tools/spelling-probes/verify_ldir.py --dangerous
      python3 tools/spelling-probes/verify_ldir.py --negative

SIGNAL READ
  The raw bytes of each ROM in original_ROMs/ at its load base.  PASS =
  `llvm-mc -triple=tlcs900 --show-encoding` emits exactly those two bytes.
  "Assembled without error" is NOT a pass: `ldir` assembles at every one of the
  1 060 sites in this sweep and is only correct at 19 of them.

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b
  2160 `ldir`/`ldirw` sites across 10 binaries.
      byte-exact 1851   mismatched 0   UNSPELLABLE 309
  Spellable today, and this is the whole rule:
      80 11 -> ldir      83 11 -> ldir83    85 11 -> ldir85
      93 11 -> ldirw93   95 11 -> ldirw
  No spelling exists for 81 82 84 86 87 (print `ldir`) or
                         90 91 92 94 96 97 (print `ldirw`).
  --dangerous: emitting the printed text VERBATIM assembles at all 2160 sites
      and gets the WRONG BYTES at 935 of them (43.3 %), the worst single class
      being 539 sites where the ROM holds [85 11] and `ldir` emits [80 11].
  --negative: the deliberately wrong rule (size and index nibbles swapped)
      mismatches at 1851 sites, so the check can fail.

"""
import os, re, subprocess, sys, collections

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
MC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
ENC = re.compile(r'encoding: \[([^\]]+)\]')
LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$')

BINS = [('kn5000_v7_program.rom', 0xE00000), ('kn5000_v9_program.rom', 0xE00000),
        ('kn5000_v10_program.rom', 0xE00000), ('kn5000_table_data.rom', 0x200000),
        ('kn5000_subprogram_v142.rom', 0), ('kn5000_subprogram_v141.rom', 0),
        ('kn5000_subprogram_v140.rom', 0), ('kn5000_subcpu_boot.ic30', 0xFE0000),
        ('hd-ae5000_v2_06i.ic4', 0x280000), ('kn5000_custom_data.ic19', 0)]

# THE RULE, as a function of the RAW BYTES b0,b1 (b1 == 0x11):
RULE = {0x80: 'ldir', 0x83: 'ldir83', 0x85: 'ldir85',
        0x93: 'ldirw93', 0x95: 'ldirw'}


def encode(text):
    r = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'], input=text + '\n',
                       capture_output=True, text=True)
    m = ENC.search(r.stdout)
    if not m:
        return None
    return bytes(int(x, 16) for x in m.group(1).split(',') if x.strip())


def sweep():
    """Every site where unidasm's linear decode prints ldir / ldirw."""
    out = []
    for name, base in BINS:
        p = os.path.join(REPO, 'original_ROMs', name)
        if not os.path.exists(p):
            continue
        rom = open(p, 'rb').read()
        txt = subprocess.run([UNIDASM, p, '-arch', 'tlcs900', '-basepc', hex(base)],
                             capture_output=True, text=True).stdout
        for line in txt.split('\n'):
            m = LINE.match(line)
            if not m:
                continue
            mn = m.group(3).strip()
            if mn.lower() not in ('ldir', 'ldirw'):
                continue
            addr = int(m.group(1), 16)
            b = rom[addr - base: addr - base + 2]
            assert b.hex(' ') == m.group(2).strip(), (name, hex(addr))   # listing vs FILE
            out.append((name, base, addr, b, mn))
    return out


def main():
    sites = sweep()
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    print(f'{len(sites)} `ldir`/`ldirw` sites in {len(BINS)} binaries\n')

    if mode == '--dangerous':
        print('DANGEROUS: spellings that ASSEMBLE but emit the WRONG bytes.')
        print('The unidasm text is operand-free, so the naive converter emits it verbatim.\n')
        bad = collections.Counter()
        for name, base, addr, b, mn in sites:
            got = encode(mn)            # the printed text, verbatim
            if got != b:
                bad[(mn, b.hex(' '), got.hex(' '))] += 1
        tot = 0
        for (mn, want, got), n in sorted(bad.items(), key=lambda kv: -kv[1]):
            print(f'  {n:5d}x  wrote `{mn}` -> [{got}]   ROM has [{want}]')
            tot += n
        print(f'\n  {tot}/{len(sites)} sites get WRONG BYTES from the verbatim text.')
        # cross-family near misses
        print('\n  cross-family near misses (all assemble cleanly):')
        for cand in ('ldir', 'ldir83', 'ldir85', 'ldirw', 'ldirw93', 'ldi', 'lddr'):
            print(f'    {cand:9s} -> [{encode(cand).hex(" ")}]')
        return

    if mode == '--negative':
        print('NEGATIVE CONTROL: can this check fail?  Apply the rule with the')
        print('size and index nibbles SWAPPED (0x80 + ridx*16 + size).\n')
        bad = 0
        for name, base, addr, b, mn in sites:
            wrong = {0x80: 'ldir85', 0x83: 'ldirw93', 0x85: 'ldir', 0x93: 'ldirw',
                     0x95: 'ldir83'}.get(b[0])
            if wrong is None:
                continue
            if encode(wrong) != b:
                bad += 1
        print(f'  mismatches under the deliberately wrong rule: {bad}  '
              f'(0 would mean the check cannot fail)')
        return

    byenc = collections.Counter((n, b.hex(' '), mn) for n, _, _, b, mn in sites)
    ok = miss = unspell = 0
    print(f'{"binary":30s} {"bytes":7s} {"prints":7s} {"n":>5s}  spelling      verdict')
    for (name, hx, mn), n in sorted(byenc.items()):
        pre = int(hx.split()[0], 16)
        sp = RULE.get(pre)
        if sp is None:
            print(f'{name:30s} [{hx}] {mn:7s} {n:5d}  {"--":12s} NO SPELLING EXISTS')
            unspell += n
            continue
        got = encode(sp)
        want = bytes(int(x, 16) for x in hx.split())
        good = got == want
        ok += n if good else 0
        miss += 0 if good else n
        print(f'{name:30s} [{hx}] {mn:7s} {n:5d}  {sp:12s} '
              f'{"BYTE-EXACT" if good else "MISMATCH " + got.hex(" ")}')
    print(f'\nbyte-exact: {ok}   mismatched: {miss}   unspellable: {unspell}')
    print('\nfull encoding space, sub-opcode 0x11:')
    for pre in list(range(0x80, 0x88)) + list(range(0x90, 0x98)):
        sp = RULE.get(pre)
        got = encode(sp).hex(' ') if sp else '--'
        print(f'  {pre:02x} 11  prints {"ldir" if pre < 0x90 else "ldirw":6s} -> '
              f'{sp or "NO SPELLING":12s} {got}')
    return 0 if miss == 0 else 1


sys.exit(main() or 0)
