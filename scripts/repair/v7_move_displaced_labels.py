#!/usr/bin/env python3
"""Move displaced v7 labels onto the routine they name. DRY RUN unless --apply N.

QUESTION ANSWERED
-----------------
3,474 v7 labels in 0x00FCCE4A..0x00FFFE80 sit 0x41A above the routine they name
(`scripts/analysis/v7_label_displacement.py`). This moves them, one at a time,
onto the source line that actually carries the routine's first byte.

HOW THE TARGET LINE IS FOUND, which was the missing piece: walk each file from a
label whose ELF address is known, assembling every instruction to accumulate the
address line by line. Measured on note_voice_mapping.s: 10,777 lines mapped, 3
lines llvm-mc could not encode (which break the walk and reset it), 5 resyncs
where a later label disagreed with the running address -- about 0.05% drift, so
EVERY move is verified independently rather than trusted from the map.

⚠ THE BYTE GATE CANNOT REVIEW THIS. Moving a label changes no bytes, so
`make clean-all && make all` reports 9/9 whether a label lands right or wrong
(spec anti-patterns 12 and 13). The check that can see it is the displacement
detector, plus a direct byte comparison of the label's new address against the
same routine in v9.

⚠ ALIGN THE WINDOW WITH THE DETECTOR. First run: 5 labels moved, all 5 verified
correct by direct comparison (28-32 of 32 bytes matching v9), yet the detector's
count fell by only 3. Not an error -- this script selected on a 32-byte window
and the detector reports on its default 24, so two of the five were never in the
population it counts. Two tools measuring "the same" thing with different
thresholds will not reconcile, and the discrepancy looks like a failure.

WHAT IT REFUSES, rather than guessing:
  * a label sharing its line with an instruction
  * a target address another label already owns (12 such collisions exist and
    each needs a human decision about which name is right)
  * a target with no located source line -- 2,834 of the 3,474 land inside an
    unconverted `.byte` run, and become movable only as conversion proceeds

Run:  python3 scripts/repair/v7_move_displaced_labels.py [--files N] [--apply N]
      then: make clean-all && make all          (must stay 9/9)
            python3 scripts/analysis/l2_symbol_reference.py --regen
            python3 scripts/analysis/v7_label_displacement.py   (must fall)
⚠ The regen between build and measure is mandatory: the detector reads the
symbol file, so without it you are grading a stale copy.
"""
import bisect, importlib.util, os, re, sys
BASE, DISP, W = 0xE00000, 0x41A, 32
LO, HI = 0x00FCCE4A, 0x00FFFE80
LAB = re.compile(r'^([A-Za-z_][\w]*):')

def syms(p):
    d = {}
    for line in open('symbols/' + p, encoding='latin1'):
        if line.startswith('#') or not line.strip(): continue
        f = line.split()
        if len(f) == 2:
            try: d[f[0]] = int(f[1], 16)
            except ValueError: pass
    return d

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); saved = sys.argv; sys.argv = [name]
    spec.loader.exec_module(m); sys.argv = saved; return m

cc = load('cc', 'scripts/converters/convert_corroborated_blocks.py')
s7, s9 = syms('maincpu_v7_symbols_reference.txt'), syms('maincpu_v9_symbols_reference.txt')
rom7 = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
rom9 = open('original_ROMs/kn5000_v9_program.rom', 'rb').read()

displaced = {}
for n in set(s7) & set(s9):
    a7, a9 = s7[n], s9[n]
    if not (LO <= a7 <= HI): continue
    o7, o9 = a7 - BASE, a9 - BASE
    if not (0 <= o9 < len(rom9) - W and DISP <= o7 < len(rom7) - W): continue
    ref = rom9[o9:o9 + W]
    at = sum(1 for x, y in zip(rom7[o7:o7 + W], ref) if x == y)
    tr = sum(1 for x, y in zip(rom7[o7 - DISP:o7 - DISP + W], ref) if x == y)
    if at <= 8 and tr >= 28: displaced[n] = a7

a2n = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
n2a = {v: k for k, v in a2n.items()}
owned = set(a2n)

import glob
files = sorted(glob.glob('v7/maincpu/*/*.s') + glob.glob('v7/maincpu/*.s'))
# Only files that actually DEFINE a displaced label -- walking all 500 costs a
# subprocess per line and never finishes.
_want = set(displaced)
files = [f for f in files
         if _want & {m.group(1) for m in
                     (LAB.match(l) for l in open(f, 'rb').read().decode('latin1').splitlines())
                     if m}]
if '--files' in sys.argv:
    files = files[:int(sys.argv[sys.argv.index('--files') + 1])]
print(f"  files defining a displaced label : {len(files)}")
moves = []
for f in files:
    raw = open(f, 'rb').read().decode('latin1')
    lines = raw.splitlines()
    addr = None; a2l = {}; lab_line = {}
    for i, ln in enumerate(lines):
        m = LAB.match(ln)
        body = ln[m.end():].strip() if m else ln.strip()
        if m:
            if m.group(1) in n2a: addr = n2a[m.group(1)]
            lab_line[m.group(1)] = i
        if not body or body.startswith((';', '#', '.include', '.global', '.section', '.align', '.incbin')):
            continue
        if addr is None: continue
        a2l.setdefault(addr, i)
        if body.startswith('.byte'):
            addr += len([x for x in body[5:].split(',') if x.strip()]); continue
        e = cc.encode(body)
        if e is None: addr = None; continue
        addr += len(e)
    for n, a in displaced.items():
        if n not in lab_line: continue
        tgt = a - DISP
        if tgt in owned: continue                       # a label already there
        if tgt not in a2l: continue                     # no line at that address
        li = lab_line[n]
        if lines[li].strip() != n + ':': continue       # label shares its line: skip
        moves.append((f, n, a, tgt, li, a2l[tgt]))

print(f"  displaced labels                 : {len(displaced):,}")
print(f"  movable with a located target line: {len(moves):,}")
if '--apply' in sys.argv:
    k = int(sys.argv[sys.argv.index('--apply') + 1])
    byfile = {}
    for mv in sorted(moves, key=lambda r: (r[0], -r[4]))[:k]:
        byfile.setdefault(mv[0], []).append(mv)
    done = 0
    for f, mvs in byfile.items():
        lines = open(f, 'rb').read().decode('latin1').splitlines(True)
        for (_, n, a, tgt, li, ti) in sorted(mvs, key=lambda r: -r[4]):
            if lines[li].strip() != n + ':': continue
            del lines[li]
            ins = ti if ti < li else ti - 1
            lines.insert(ins, n + ':\n')
            done += 1
        open(f, 'wb').write(''.join(lines).encode('latin1'))
    print(f"  MOVED {done} label(s)")
else:
    for f, n, a, tgt, li, ti in moves[:10]:
        print(f"    {n:40} {a:#08x} -> {tgt:#08x}   line {li} -> {ti}   {os.path.basename(f)}")
