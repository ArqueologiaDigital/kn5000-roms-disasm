#!/usr/bin/env python3
"""How much of the un-converted .byte blob mass would the `cp r,(imm)` spelling
rule unlock?

QUESTION ANSWERED
  verify_cp_reg_direct.py proves the six spellable encodings behind the printed
  form `cp r,(0xADDR)` can all be written in llvm-mc byte-exactly.  This script
  says where the payoff is: it locates every remaining `.byte` run of the chosen
  version's maincpu sources inside the ROM, re-disassembles just those runs, and
  counts the `cp r,(imm)` sites that fall in them, broken down by encoding.

  A site OUTSIDE the blobs is already source; a site INSIDE one is a byte run a
  converter could now turn into an instruction.

  ⚠ UPPER BOUND. A linear scan of a data table also produces these decodes.
  code_or_data_cp_reg_direct.py measures the noise on the v9 ROM, where the
  answer is known: only 551 of 865 whole-ROM `cp r,(imm)` sweep hits are real
  instructions.  Expect a similar fraction here.

RUN
  python3 tools/spelling-probes/blob_cp_reg_direct.py [v7|v9|v10]   (default v7)

RESULT 2026-08-22 -- see the table this prints; the v7 numbers are quoted in the
commit message that added this file.
"""
import os, re, subprocess, collections, glob, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
VER  = sys.argv[1] if len(sys.argv) > 1 else 'v7'
ROM  = os.path.join(REPO, f'original_ROMs/kn5000_{VER}_program.rom')

rom = open(ROM, 'rb').read()
byte_re = re.compile(r'^\s*\.byte\s+(.*)$')
LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp ([A-Za-z]+),\((0x[0-9a-f]+)\)$')

runs = []
for f in sorted(glob.glob(f'{REPO}/{VER}/maincpu/**/*.s', recursive=True)):
    cur, start = b'', None
    for i, line in enumerate(open(f, errors='replace'), 1):
        m = byte_re.match(line)
        if m:
            vals = [v.strip() for v in m.group(1).split(';')[0].split(',') if v.strip()]
            try:
                b = bytes(int(v, 0) & 0xFF for v in vals)
            except ValueError:
                if cur: runs.append((f, start, cur)); cur, start = b'', None
                continue
            if not cur: start = i
            cur += b
        else:
            s = line.strip()
            if s.startswith(';') or s.endswith(':') or not s:
                continue        # labels/comments do not break a run
            if cur: runs.append((f, start, cur)); cur, start = b'', None
    if cur: runs.append((f, start, cur))

print(f'{VER}: {len(runs)} .byte runs, {sum(len(r[2]) for r in runs)} bytes')

located, unloc, ambig = [], 0, 0
for f, ln, b in runs:
    if len(b) < 8: continue
    idx = rom.find(b)
    if idx < 0: unloc += 1; continue
    if rom.find(b, idx + 1) >= 0: ambig += 1; continue
    located.append((f, ln, BASE + idx, b))
print(f'located {len(located)} runs ({sum(len(x[3]) for x in located)} bytes), '
      f'unlocated {unloc}, ambiguous {ambig}')

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
        key = (f'{by[0]:02x}', len(by))
        cnt[key] += 1
        ex.setdefault(key, (int(m.group(1), 16), m.group(2), m.group(3),
                            os.path.relpath(f, REPO)))

print(f'\n`cp r,(imm)` sites inside the remaining {VER} .byte blobs:')
for k, v in sorted(cnt.items()):
    a, by, txt, f = ex[k]
    spellable = '' if k[0][1] == '0' else '  <- spellable'
    print(f'  {v:6d}  prefix {k[0]} len {k[1]}   e.g. {a:06x}: {by:18s} {txt:24s} '
          f'[{f}]{spellable}')
print('  total:', sum(cnt.values()), ' bytes:', sum(v * k[1] for k, v in cnt.items()))
