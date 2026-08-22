#!/usr/bin/env python3
"""Which `cp (imm),r` sites in the v9 ROM are REAL INSTRUCTIONS, and in
particular: does the 8-bit-direct form (prefixes c0/d0/e0) -- the one the LLVM
TLCS-900 backend cannot spell -- occur in real code at all?

WHY IT MATTERS
  verify_cp_direct_reg.py shows llvm-mc can spell six of the nine encodings
  behind the printed form `cp (imm),r` (sub-opcode 0xF8+r): the 16-bit
  (c1/d1/e1) and 24-bit (c2/d2/e2) direct addresses, via cpdm8/16/32 and their
  _24 variants.  It has NO form for the three 8-bit-direct ones, because
  TLCS900InstrFormats.td gives AddrWidth a single bit (16- or 24-bit) and
  emitDirectAddrPrefix() can therefore only ever emit c1/d1/e1 or c2/d2/e2.
  Before asking for a new instruction definition, check whether the ROM
  actually contains one.  A whole-ROM linear sweep decodes data tables as
  instructions, so a sweep hit is NOT evidence.

METHOD -- ask the byte-exact build, not a heuristic
  The v9 sources rebuild BYTE-IDENTICAL to the original ROM.  Re-assemble them
  with `llvm-mc -g`: the DWARF line table then carries one row per emitting
  source statement, so "this address starts a row" means "the source emits
  something starting exactly here", and an instruction the sources really
  contain MUST start a row.  Inside an .incbin blob there are no rows at all.

  The script refuses to draw a conclusion unless its -g rebuild still matches
  the original ROM byte for byte.

  This check CAN come out positive, and does -- see the c1/d1/e1 line -- so it
  is not a criterion that cannot fail.

RUN
  python3 tools/spelling-probes/code_or_data_cp_direct_reg.py

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b) -- see the table it prints.
"""
import os, re, subprocess, sys, tempfile, collections

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
ROM  = os.path.join(REPO, 'original_ROMs/kn5000_v9_program.rom')

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp \((0x[0-9a-f]+)\),([A-Za-z]+)$')


def line_table_rows(tmp):
    o, elf, rom = (os.path.join(tmp, n) for n in ('v9g.o', 'v9g.elf', 'v9g.rom'))
    subprocess.run([f'{LLVM}/llvm-mc', '-triple=tlcs900', '-filetype=obj', '-g',
                    '-I', 'v9/maincpu', '-o', o,
                    'v9/maincpu/kn5000_v9_program.s'], cwd=REPO, check=True)
    subprocess.run([f'{LLVM}/ld.lld', '-e', '0', '-T', 'v9/maincpu/maincpu.ld',
                    '-o', elf, o], cwd=REPO, check=True)
    subprocess.run([f'{LLVM}/llvm-objcopy', '-O', 'binary', elf, rom], check=True)
    if open(rom, 'rb').read() != open(ROM, 'rb').read():
        sys.exit('ABORT: the -g rebuild is NOT byte-identical to the original '
                 'v9 ROM, so its line table says nothing about the real ROM.')
    dl = subprocess.run([f'{LLVM}/llvm-dwarfdump', '--debug-line', elf],
                        capture_output=True, text=True).stdout
    return {int(m, 16) for m in re.findall(r'^0x([0-9a-f]{16})', dl, re.M)}


def sites():
    dis = subprocess.run([UNI, ROM, '-arch', 'tlcs900', '-basepc', hex(BASE)],
                         capture_output=True, text=True).stdout
    out = []
    for line in dis.split('\n'):
        m = LINE.match(line)
        if not m or not TEXT.match(m.group(3)):
            continue
        by = bytes(int(x, 16) for x in m.group(2).split())
        out.append((int(m.group(1), 16), by, m.group(3)))
    return out


def main():
    with tempfile.TemporaryDirectory() as tmp:
        rows = line_table_rows(tmp)
    print(f'DWARF line table: {len(rows)} source-statement addresses '
          f'(rebuild verified byte-identical to the original v9 ROM)\n')
    code, total = collections.Counter(), collections.Counter()
    real8 = []
    for addr, by, txt in sites():
        w = by[0] & 0x0F
        key = {0: 'c0/d0/e0  8-bit direct  (NO llvm-mc form)',
               1: 'c1/d1/e1 16-bit direct',
               2: 'c2/d2/e2 24-bit direct'}.get(w, f'other low nibble {w:x}')
        total[key] += 1
        if addr in rows:
            code[key] += 1
            if w == 0:
                real8.append((addr, by, txt))
    for k in sorted(total):
        print(f'  {k:44s} {code[k]:4d} / {total[k]:4d} sites are real code')
    print()
    if real8:
        print('⚠ REAL 8-bit-direct instructions found -- the backend gap DOES bite:')
        for a, b, t in real8:
            print(f'    {a:06x}: {b.hex(" "):14s} {t}')
    else:
        print('No 8-bit-direct site is a source statement: the form does not '
              'occur in the\nKN5000 maincpu firmware. The missing llvm-mc form '
              'blocks nothing.')


main()
