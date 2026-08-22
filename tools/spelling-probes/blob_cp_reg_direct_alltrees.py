#!/usr/bin/env python3
"""WHERE are the `cp r,(imm)` sites that still block conversion -- in EVERY
source tree, not just v7 -- and how many of them does the spelling rule reach?

QUESTION ANSWERED
  blob_cp_reg_direct.py answers this for one maincpu tree at a time.  The
  KN5000 sources are eight trees over six binaries, and a converter run reports
  one blocking count for the lot.  This script gives the whole census in one
  pass, split spellable / unspellable, so "N instances blocking conversion" can
  be attributed to a file and an encoding class instead of guessed at.

METHOD
  Collect every maximal run of `.byte` directives in a tree (labels, comments
  and blank lines do not break a run, matching the other probe), locate each run
  by CONTENT in its binary -- runs shorter than 8 bytes, or occurring more than
  once, are skipped as unlocatable -- disassemble just that run with unidasm at
  its real address, and count the `cp r,(imm)` decodes by prefix byte.

  ⚠ UPPER BOUND.  A linear scan of a pointer table also decodes to this form;
  the run is data until something says otherwise.  code_or_data_cp_reg_direct.py
  measures that noise on v9 (551 of 865 whole-ROM hits are real code).

  ⚠ table_data is disassembled at 0x800000 (table_data/table_data.ld ORIGIN),
  NOT the 0x200000 used by the older probe -- 0x200000 is the region LENGTH.

RUN
  python3 tools/spelling-probes/blob_cp_reg_direct_alltrees.py

RESULT 2026-08-22, unidasm from ~/compartilhado/tools, sources at b081be6

  tree          .byte runs   located   spellable   no spelling (c0/d0/e0)
  v7/maincpu          8184      2751         346          0
  v9/maincpu         17541       837          15          2
  v10/maincpu        17540       837          15          2
  v142/subcpu          301       111           5         49
  subcpu                 8         5           0          0
  table_data          5439      2277           6          2
  custom_data           10         9           0          0
  hdae5000            4922       411           1          1
  TOTAL                                      388         56

  v7 is one big separate job (346 sites, all spellable).  Everything else adds
  up to 42 spellable sites plus 56 in the 8-bit-direct class that has no
  mnemonic at all -- and NONE of those 56 is a real instruction:
  frame_cp_reg_direct_blobs.py attributes every one to a labelled data object
  (DSP_Eff32_Algo_Bytecode, DSP_EffA_Param_Values, AccPlayMode_Dispatch_Table,
  ToneDB_VelocityCurve_0, HDAE5000_UI_Page_Titles) or, in one case, to a
  mis-split 6-byte `ld (nn),(nn)`.

  Note v9 and v10 report the same 17 sites at the same addresses: the two
  revisions differ by 3 bytes, so they are one set of sites counted twice.

"""
import os, re, subprocess, collections, glob, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')

# tree glob -> (binary, ORIGIN)
TREES = [('v7/maincpu',   'kn5000_v7_program.rom',      0xE00000),
         ('v9/maincpu',   'kn5000_v9_program.rom',      0xE00000),
         ('v10/maincpu',  'kn5000_v10_program.rom',     0xE00000),
         ('v142/subcpu',  'kn5000_subprogram_v142.rom', 0x00EF00),
         ('subcpu',       'kn5000_subcpu_boot.ic30',    0xFE0000),
         ('table_data',   'kn5000_table_data.rom',      0x800000),
         ('custom_data',  'kn5000_custom_data.ic19',    0x300000),
         ('hdae5000',     'hd-ae5000_v2_06i.ic4',       0x280000)]

BYTE = re.compile(r'^\s*\.byte\s+(.*)$')
LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp ([A-Za-z]+),\((0x[0-9a-f]+)\)$')


def runs_of(tree):
    out = []
    for f in sorted(glob.glob(f'{REPO}/{tree}/**/*.s', recursive=True)):
        cur, start = b'', None
        for i, line in enumerate(open(f, errors='replace'), 1):
            m = BYTE.match(line)
            if m:
                vals = [v.strip() for v in m.group(1).split(';')[0].split(',') if v.strip()]
                try:
                    b = bytes(int(v, 0) & 0xFF for v in vals)
                except ValueError:
                    if cur: out.append((f, start, cur)); cur, start = b'', None
                    continue
                if not cur: start = i
                cur += b
            else:
                s = line.strip()
                if s.startswith(';') or s.endswith(':') or not s:
                    continue
                if cur: out.append((f, start, cur)); cur, start = b'', None
        if cur: out.append((f, start, cur))
    return out


grand = collections.Counter()
for tree, binname, base in TREES:
    rom = open(os.path.join(REPO, 'original_ROMs', binname), 'rb').read()
    rr = runs_of(tree)
    located = []
    for f, ln, b in rr:
        if len(b) < 8: continue
        i = rom.find(b)
        if i < 0 or rom.find(b, i + 1) >= 0: continue
        located.append((f, ln, base + i, b))
    cnt, ex = collections.Counter(), {}
    for f, ln, addr, b in located:
        tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
        tf.write(b); tf.close()
        out = subprocess.run([UNI, tf.name, '-arch', 'tlcs900', '-basepc', hex(addr)],
                             capture_output=True, text=True).stdout
        os.unlink(tf.name)
        for line in out.split('\n'):
            m = LINE.match(line)
            if not m or not TEXT.match(m.group(3)): continue
            by = bytes(int(x, 16) for x in m.group(2).split())
            k = f'{by[0]:02x}'
            cnt[k] += 1
            ex.setdefault(k, (int(m.group(1), 16), m.group(2), m.group(3),
                              os.path.relpath(f, REPO)))
    sp = sum(v for k, v in cnt.items() if k[1] != '0')
    un = sum(v for k, v in cnt.items() if k[1] == '0')
    print(f'=== {tree:14s} {len(rr):6d} runs, {len(located):5d} located; '
          f'{sp:4d} spellable + {un} unspellable')
    for k in sorted(cnt):
        a, by, txt, f = ex[k]
        print(f'      {cnt[k]:5d}  prefix {k}  '
              f'{"SPELLABLE  " if k[1] != "0" else "no spelling"}  '
              f'e.g. {a:06x}: {by:17s} {txt:22s} [{f}]')
    grand['sp'] += sp; grand['un'] += un

print(f'\nTOTAL still inside .byte blobs: {grand["sp"]} spellable, '
      f'{grand["un"]} with no spelling (8-bit-direct c0/d0/e0)')
