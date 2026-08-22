#!/usr/bin/env python3
"""How much un-converted `.byte` blob mass would the `res N,(imm)` spelling rule
unlock, and where?

QUESTION ANSWERED
  verify_res_bit_direct.py proves the three encodings behind the printed form
  `res N,(0xADDR)` can all be written in llvm-mc byte-exactly (res_dd8 / resda /
  resda_24).  This script says where the payoff is: it locates every remaining
  `.byte` run of the chosen version's maincpu sources inside the ROM,
  re-disassembles just those runs, and counts the `res N,(imm)` sites that fall
  in them, broken down by encoding prefix and by bit number.

  A site OUTSIDE the blobs is already source; a site INSIDE one is a byte run a
  converter could now turn into an instruction.

  ⚠ TWO-SIDED BOUND, not an exact count.
    * UPPER: a linear scan of a data table also produces these decodes.
      code_or_data_res_bit_direct.py measures the noise on v9, where the answer
      is known: 340 of the 446 whole-ROM sweep hits are real instructions.
    * LOWER: this script can only place a `.byte` run whose bytes occur exactly
      once in the ROM and are at least 8 bytes long, so short and duplicated
      runs are invisible to it (v9: 837 of 17541 runs placed).

RUN
  python3 tools/spelling-probes/blob_res_bit_direct.py [v7|v9|v10]   (default v7)

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  v7   8184 runs / 429841 bytes; 2751 placed (409645 bytes)
       183 sites: 182 f1 + 1 f2, no f0.  54 of them are bit 0
       (53 f1 + 1 f2), the biggest single clusters being
       sequencer/sequencer_engine.s and midi/midi_dispatch_handlers.s.
  v9  17541 runs / 108057 bytes;  837 placed (80753 bytes)
       30 sites: 5 f0 + 25 f1.  8 of them are bit 0 (1 f0 + 7 f1).
  v10 identical to v9.

  The v9/v10 f0 hits all sit in includes/gui_display_struct_data.s, i.e. they
  are the linear sweep reading a widget table -- not code.  The v7 payoff is
  real and it is all f1.
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
TEXT = re.compile(r'^res ([0-7]),\((0x[0-9a-f]+)\)$')

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

cnt, ex, per_file = collections.Counter(), {}, collections.Counter()
for f, ln, addr, b in located:
    tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
    tf.write(b); tf.close()
    out = subprocess.run([UNI, tf.name, '-arch', 'tlcs900', '-basepc', hex(addr)],
                         capture_output=True, text=True).stdout
    os.unlink(tf.name)
    for line in out.split('\n'):
        m = LINE.match(line)
        t = TEXT.match(m.group(3)) if m else None
        if not t: continue
        by = bytes(int(x, 16) for x in m.group(2).split())
        key = (f'{by[0]:02x}', len(by), int(t.group(1)))
        cnt[key] += 1
        per_file[os.path.relpath(f, REPO)] += 1
        ex.setdefault(key, (int(m.group(1), 16), m.group(2), m.group(3),
                            os.path.relpath(f, REPO)))

print(f'\n`res N,(imm)` sites inside the remaining {VER} .byte blobs:')
for k in sorted(cnt):
    a, by, txt, f = ex[k]
    mn = {'f0': 'res_dd8', 'f1': 'resda', 'f2': 'resda_24'}[k[0]]
    print(f'  {cnt[k]:5d}  prefix {k[0]} len {k[1]} bit {k[2]}  {mn:9s}'
          f'  e.g. {a:06x}: {by:18s} {txt:22s} [{f}]')
print(f'  total {sum(cnt.values())} sites, '
      f'{sum(v * k[1] for k, v in cnt.items())} bytes; '
      f'bit-0 only: {sum(v for k, v in cnt.items() if k[2] == 0)}')

print('\nby source file:')
for f, v in per_file.most_common(12):
    print(f'  {v:5d}  {f}')
