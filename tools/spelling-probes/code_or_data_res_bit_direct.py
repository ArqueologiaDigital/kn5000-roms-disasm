#!/usr/bin/env python3
"""Which `res N,(imm)` sites in the v9 ROM are REAL INSTRUCTIONS, and how do
they split over the three direct-address widths (f0 / f1 / f2)?

WHY IT MATTERS
  verify_res_bit_direct.py proves all three encodings behind the printed form
  `res N,(0xADDR)` can be spelled byte-exactly (res_dd8 / resda / resda_24), so
  unlike `cp r,(imm)` there is no backend gap here.  What is still unknown is
  how much of the 446-site whole-ROM sweep is real: a linear scan through a
  pointer table or a bitmap decodes to plausible garbage, and a converter that
  believes the sweep turns data into instructions.

  In particular the f0 (8-bit direct) class deserves a look, because for
  `cp r,(imm)` the equivalent class turned out to be 100% data.  Here it is NOT:
  8-bit direct addressing is how the TMP94C241 reaches its own SFRs, which live
  in the first 256 bytes, so `res 1,(0x68)` is a real MSTAT1 write.

METHOD -- ask the byte-exact build, not a heuristic
  The v9 sources rebuild BYTE-IDENTICAL to the original ROM.  Re-assemble them
  with `llvm-mc -g`: the DWARF line table then carries one row per emitting
  source statement, so "this address starts a row" means "the source emits
  something starting exactly here".  An instruction the sources really contain
  MUST start a row.  The script refuses to conclude anything unless its -g
  rebuild still matches the original ROM byte for byte.

  Two independent cross-checks keep this honest:

  (a) For every site that IS a row, the row's LINE NUMBER is looked up in the
      sources.  If the site is a real `res`, some source file must carry a
      res_dd8/resda/resda_24 statement at exactly that line.  (llvm-mc -g
      records only one file name for an .include tree, so the file cannot be
      read straight out of the line table -- the line number can.)
  (b) The per-class row counts are compared against a plain grep of the
      sources.  They must agree exactly, because the sources ARE the ROM.
      ⚠ use `grep -a`: several .s files carry 8-bit bytes in string tables and
      grep otherwise calls them binary and prints one line for the whole file
      (that mistake undercounted `resda` as 112 instead of 322).

  The check CAN come out negative -- 106 of the 446 sweep hits are not rows.

RUN
  python3 tools/spelling-probes/code_or_data_res_bit_direct.py

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  f0  8-bit direct  (res_dd8)     12 /  22 sites are real code
  f1 16-bit direct  (resda)      322 / 415 sites are real code
  f2 24-bit direct  (resda_24)     6 /   9 sites are real code
  TOTAL                          340 / 446

  Cross-check (b): the v9 sources contain exactly 12 res_dd8, 322 resda and
  6 resda_24 statements -- the same three numbers.  Cross-check (a): all 340
  rows land on a res* source line; 0 land on anything else.

  So 340 of the 446 whole-ROM sweep hits are instructions and the other 106 are
  the linear scan reading data (or a still-unconverted .byte blob) as code.
  All three widths occur in real code; the f0 sites are SFR writes
  (0x20, 0x30, 0x34, 0x3c, 0x44, 0x68 = MSTAT, 0x80).
"""
import os, re, subprocess, sys, tempfile, collections, glob

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
ROM  = os.path.join(REPO, 'original_ROMs/kn5000_v9_program.rom')

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^res ([0-7]),\((0x[0-9a-f]+)\)$')
MNEM = {0: 'res_dd8', 1: 'resda', 2: 'resda_24'}
SRCRE = re.compile(r'^\s*(res_dd8|resda_24|resda)\b')


def line_table(tmp):
    """Rebuild v9 with -g, prove it still byte-matches, return {addr: line}."""
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
    return {int(a, 16): int(n)
            for a, n in re.findall(r'^0x([0-9a-f]{16})\s+(\d+)', dl, re.M)}


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
    src = {f: open(f, errors='replace').read().split('\n')
           for f in glob.glob(f'{REPO}/v9/maincpu/**/*.s', recursive=True)}
    grepped = collections.Counter()
    for lines in src.values():
        for l in lines:
            m = SRCRE.match(l)
            if m:
                grepped[m.group(1)] += 1

    with tempfile.TemporaryDirectory() as tmp:
        rows = line_table(tmp)
    print(f'DWARF line table: {len(rows)} source-statement addresses '
          f'(rebuild verified byte-identical to the original v9 ROM)\n')

    code, total, notres = collections.Counter(), collections.Counter(), []
    examples = collections.defaultdict(list)
    for addr, by, txt in sites():
        w = by[0] & 0x0F
        total[w] += 1
        if addr not in rows:
            continue
        code[w] += 1
        L = rows[addr]
        hits = [(f, lines[L - 1].strip()) for f, lines in src.items()
                if L <= len(lines) and SRCRE.match(lines[L - 1])]
        if hits:
            examples[w].append((addr, by, txt, L, hits))
        else:
            notres.append((addr, by, txt, L))

    for w in sorted(total):
        print(f'  f{w} {["8","16","24"][w]:>2}-bit direct ({MNEM[w]:8s})'
              f' {code[w]:4d} / {total[w]:4d} sites are real code')
    print(f'  {"TOTAL":32s} {sum(code.values()):4d} / {sum(total.values()):4d}')

    print('\ncross-check (b) -- statements actually written in the v9 sources:')
    agree = True
    for w in sorted(MNEM):
        g = grepped[MNEM[w]]
        flag = 'AGREES' if g == code[w] else '*** DISAGREES ***'
        agree &= (g == code[w])
        print(f'  {MNEM[w]:9s} source lines {g:4d}   line-table rows {code[w]:4d}   {flag}')
    print('  ' + ('both methods agree on every class'
                  if agree else 'MISMATCH -- do not trust these numbers'))

    print(f'\ncross-check (a) -- rows whose line is NOT a res* statement: '
          f'{len(notres)}')
    for a, b, t, L in notres[:10]:
        print(f'    {a:06x}: {b.hex(" "):14s} {t:20s} dwarf-line {L}')

    print('\nsource-anchored examples, one per encoding class:')
    for w in sorted(examples):
        a, b, t, L, hits = examples[w][0]
        f, s = hits[0]
        print(f'  {a:06x}: {b.hex(" "):14s} {t:20s} '
              f'{os.path.relpath(f, REPO)}:{L}   {s}')


main()
