#!/usr/bin/env python3
"""Which `inc <n>,<REG>` sites in the v9 ROM are REAL INSTRUCTIONS -- and in
particular, do the three encodings llvm-mc has NO form for occur in real code?

WHY IT MATTERS
  verify_inc_reg.py shows the backend can spell 3000 of the 6336 encodings in
  the register-INC space.  The holes are:
      df 6n        INC #n, SP        -- GR16 excludes SP, so no `inc n, sp`
      d7 rb 6n     word ERP, n not in {1,4}  -- only inc1w_erp / inc4w_erp exist
      e7 rb 6n     long ERP, n != 4          -- only inc4_lerp exists
  Before asking for new TLCS900 .td definitions, check whether the firmware
  contains one.  A whole-ROM linear sweep decodes data tables as instructions,
  so a sweep hit is NOT evidence.

METHOD -- ask the byte-exact build, not a heuristic (same as
  code_or_data_cp_reg_direct.py).  The v9 sources rebuild BYTE-IDENTICAL to the
  original ROM; re-assembled with `llvm-mc -g` the DWARF line table carries one
  row per emitting source statement, so "this address starts a row" means the
  sources really emit something starting exactly there.  The script aborts
  unless its -g rebuild still matches the original ROM byte for byte.

  The check CAN come out positive: it does, for thousands of the short-form
  sites and for all the c7-prefix ones -- so it does say YES when the answer
  is yes.

RUN   python3 tools/spelling-probes/code_or_data_inc_reg.py

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b), v9, 358975 line-table rows
  c7 rb 6n  byte ERP            (incb_erp)                221 /  325 real code
  c8+r 6n   byte register                                 762 /  825 real code
  d7 rb 6n  word ERP            (inc1w_erp/inc4w_erp)      66 /   76 real code
  d8+r 6n   word register                                1918 / 1995 real code
  e7 rb 64  long ERP            (inc4_lerp)                 1 /    3 real code
  e8+r 6n   long register                                2937 / 3519 real code
  df 6n     INC n,SP            (NO llvm-mc form)           0 /    2 real code
  e7 rb 6n  long ERP n != 4     (NO llvm-mc form)           0 /    3 real code

  The check comes out POSITIVE 5905 times, so it can say yes.  It says ZERO for
  both unspellable classes.

  VERDICT: `INC #n, SP` and the long-ERP counts other than 4 do not occur in the
  KN5000 maincpu firmware.  Those backend gaps cost nothing; a converter should
  leave `df 6n` and `e7 rb 6n` (n != 4) runs as .byte, because they are data.
  Do NOT add TLCS900 .td definitions for them on a linear-sweep census.
"""
import collections, os, re, subprocess, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
ROM  = os.path.join(REPO, 'original_ROMs/kn5000_v9_program.rom')

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^inc (\d),([A-Z][A-Z0-9]*)$')


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


def klass(b):
    n = b[-1] & 7
    if len(b) == 2:
        p = b[0] & 0xF8
        if p == 0xD8 and (b[0] & 7) == 7:
            return 'df 6n     INC n,SP            (NO llvm-mc form)'
        return {0xC8: 'c8+r 6n   byte register', 0xD8: 'd8+r 6n   word register',
                0xE8: 'e8+r 6n   long register'}[p]
    if b[0] == 0xC7:
        return 'c7 rb 6n  byte ERP            (incb_erp)'
    if b[0] == 0xD7:
        return ('d7 rb 6n  word ERP            (inc1w_erp/inc4w_erp)'
                if n in (1, 4) else
                'd7 rb 6n  word ERP n not 1,4  (NO llvm-mc form)')
    if b[0] == 0xE7:
        return ('e7 rb 64  long ERP            (inc4_lerp)' if n == 4 else
                'e7 rb 6n  long ERP n != 4     (NO llvm-mc form)')
    return 'other'


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
    code, total, real_gap = collections.Counter(), collections.Counter(), []
    for addr, by, txt in sites():
        k = klass(by)
        total[k] += 1
        if addr in rows:
            code[k] += 1
            if 'NO llvm-mc form' in k:
                real_gap.append((addr, by, txt))
    for k in sorted(total):
        print(f'  {k:52s} {code[k]:5d} / {total[k]:5d} are real code')
    print()
    if real_gap:
        print('⚠ REAL instructions in an unspellable class -- the gap DOES bite:')
        for a, b, t in real_gap:
            print(f'    {a:06x}: {b.hex(" "):10s} {t}')
    else:
        print('No site in an unspellable class is a source statement: those\n'
              'encodings do not occur in the KN5000 maincpu firmware, and the\n'
              'missing llvm-mc forms block nothing.  Leave those runs as .byte.')


main()
