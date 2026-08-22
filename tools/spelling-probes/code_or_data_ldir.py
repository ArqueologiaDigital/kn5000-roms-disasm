#!/usr/bin/env python3
"""Are the UNSPELLABLE `ldir` sites real instructions, or data?

QUESTION ANSWERED
  verify_ldir.py shows 5 of the 16 block-transfer encodings that print
  `ldir`/`ldirw` have a spelling and 11 do not.  Before asking the LLVM backend
  for eleven new mnemonics, ask whether those bytes are instructions at all: a
  linear decode walks straight through a pointer table and prints plausible
  two-byte instructions, because `0x8n 0x11` is exactly what the low half of a
  little-endian pointer 0x00xx11nn looks like.

  This script tests every `ldir` site in the three MAIN-CPU program ROMs and in
  the sub-CPU program against two data models:

    POINTER TABLE  the 4 bytes AT the site are a little-endian address, and so
                   are the words at site +/- 4k for a long run, all inside one
                   64 KiB page.
    RECORD FIELD   the site is a 16-bit field at a fixed offset in a fixed-stride
                   record, and the field advances by a constant step.

  It prints the CONTEXT BYTES for everything it cannot classify, so "code" is a
  judgement the reader can check, not one the script asserts.

RUN   python3 tools/spelling-probes/code_or_data_ldir.py

RESULT 2026-08-22
  Every UNSPELLABLE `ldir` site in kn5000_v7/v9/v10_program.rom and in
  kn5000_subprogram_v14x.rom is DATA.  Not one is an instruction:
    0xEB0216 [86 11]  low half of pointer 0x00EB1186 -- 353-entry stride-4
                      table 0xEAFFF2..0xEB0572, strictly decreasing
    0xED0F58 [82 11]  low half of pointer 0x00ED1182 -- 31-entry stride-4
                      table 0xED0F44..0xED0FBC, decreasing, step 0x12
    0xF6A803 [81 11]  (v7; 0xF6AC07 in v9/v10) the 16-bit field at +6 of a
                      15-byte record whose first word is the pointer 0x00F6AA80
                      (0x00F6AE84 in v9/v10); the field runs
                      0x0821 0x0CD1 0x1181 0x1631, step +0x04B0
    0x000667 0x00067B 0x000687 0x00068B 0x00068F 0x0006A3 [87 11] (sub-CPU)
                      six copies of pointer 0x00001187 in the 54-entry stride-4
                      vector table at 0x00062B..0x0006FF
  The two [80 11] sites in the program ROMs -- 0xF15416 and 0xF15C03 (0xF15440 /
  0xF15C2D in v9/v10) -- are data as well: a UI resource stream interleaved with
  the ASCII strings "REVERB DEPTH  :" and "VIBRAT0 DEPTH:", where `05 XX 11` is
  an opcode plus a 16-bit operand.  They DO assemble byte-exactly as `ldir`, so
  "it round-trips" would have turned a string table into code there.  Neither
  address is in a v7 reachable range, so the converter never offers to.
"""
import os, re, subprocess

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$')
SPELLABLE = {0x80: 'ldir', 0x83: 'ldir83', 0x85: 'ldir85'}

BINS = [('kn5000_v7_program.rom', 0xE00000), ('kn5000_v9_program.rom', 0xE00000),
        ('kn5000_v10_program.rom', 0xE00000), ('kn5000_subprogram_v142.rom', 0)]
RECORDS = [('kn5000_v7_program.rom', 0xE00000, 0xF6A803),
           ('kn5000_v9_program.rom', 0xE00000, 0xF6AC07),
           ('kn5000_v10_program.rom', 0xE00000, 0xF6AC07)]


def u32(rom, off):
    return int.from_bytes(rom[off:off + 4], 'little')


def pointer_table(rom, base, addr):
    """Longest stride-4 run around addr whose LE words share addr's 64 KiB page."""
    off = addr - base
    tgt = u32(rom, off)
    page = tgt & 0xFFFF0000
    ok = lambda o: 0 <= o and o + 4 <= len(rom) and u32(rom, o) and \
        (u32(rom, o) & 0xFFFF0000) == page
    lo = hi = off
    while ok(lo - 4):
        lo -= 4
    while ok(hi + 4):
        hi += 4
    vals = [u32(rom, o) for o in range(lo, hi + 1, 4)]
    n = len(vals)
    down = all(vals[i] > vals[i + 1] for i in range(n - 1))
    up = all(vals[i] < vals[i + 1] for i in range(n - 1))
    return n, base + lo, base + hi, tgt, vals, ('decreasing' if down else
                                                'increasing' if up else 'unsorted')


def main():
    for name, base in BINS:
        p = os.path.join(REPO, 'original_ROMs', name)
        rom = open(p, 'rb').read()
        txt = subprocess.run([UNIDASM, p, '-arch', 'tlcs900', '-basepc', hex(base)],
                             capture_output=True, text=True).stdout
        print(f'=== {name}')
        for line in txt.split('\n'):
            m = LINE.match(line)
            if not m or m.group(3).strip().lower() != 'ldir':
                continue
            a = int(m.group(1), 16)
            b = rom[a - base:a - base + 2]
            if b[0] == 0x85 or b[0] == 0x83:
                continue                      # the bulk: verified real code elsewhere
            tag = SPELLABLE.get(b[0], 'NO SPELLING')
            n, lo, hi, tgt, vals, order = pointer_table(rom, base, a)
            if n >= 8:
                i = (a - lo) // 4
                nb = ' '.join(f'{v:08X}' for v in vals[max(0, i - 3):i + 4])
                print(f'  0x{a:06X} [{b.hex(" ")}] {tag:11s} DATA: pointer table, '
                      f'{n} stride-4 entries 0x{lo:06X}..0x{hi:06X} ({order}); '
                      f'word here = 0x{tgt:08X}')
                print(f'            neighbours {nb}')
            else:
                o = a - base
                print(f'  0x{a:06X} [{b.hex(" ")}] {tag:11s} not a pointer table; '
                      f'context bytes:')
                print(f'            {rom[o-16:o].hex(" ")} | {rom[o:o+2].hex(" ")} '
                      f'| {rom[o+2:o+18].hex(" ")}')
                print(f'            ascii: {rom[o-16:o+18].decode("latin1")!r}')
    print()
    for name, base, addr in RECORDS:
        rom = open(os.path.join(REPO, 'original_ROMs', name), 'rb').read()
        o = addr - base - 6                      # record start
        recs = [rom[o + k * 15:o + k * 15 + 15] for k in (-2, -1, 0, 1)]
        f = [int.from_bytes(r[6:8], 'little') for r in recs]
        d = [f[i + 1] - f[i] for i in range(len(f) - 1)]
        print(f'{name} 0x{addr:06X}: four 15-byte records ending at the site --')
        for r in recs:
            print(f'    {r.hex(" ")}   ptr=0x{int.from_bytes(r[0:4],"little"):08X} '
                  f'field=0x{int.from_bytes(r[6:8],"little"):04X}')
        print(f'    field deltas: {[hex(x) for x in d]}  '
              f'(constant => arithmetic progression, not opcodes)')


main()
