#!/usr/bin/env python3
r"""nakarest_refs.py -- every source-level and data-level reference into an address range.

QUESTION ANSWERED
-----------------
"Who reads these bytes?"  For a ROM address range of the maincpu image it lists

  * SYMBOLIC references: every use, in the version's .s sources, of a symbol
    whose address lies in the range -- labels AND the positional names that
    shared/positional_labels.s defines as `.set X_0xNN, X + NN` (the linker
    resolves them, so llvm-nm lists them with their addresses);
  * NUMERIC references: 0xNNNNNN literals in instruction or directive
    operands of the .s sources that fall in the range (the RegObjTabl /
    RegTitle operands, `lda xwa, (0xe8xxxx:24)` and the like);
  * DATA references: 32-bit little-endian words ANYWHERE in the original ROM
    dump whose value falls in the range (pointer tables, NAKA records),
    reported with the symbol that precedes the word's address.

Each reference is reported with the file, line, the line's text and the
routine (the nearest preceding column-0 label in that file) or, for data
references, the containing object.  A reference is evidence of a reader,
not of what the bytes mean -- the headers built from it quote the
instruction so a reader can check.

Kept deliberately simple: it does not follow a base loaded into a register
and indexed later (the `TABLE - 4*k` idiom, a base spilled to the frame) --
BRIEF-2026-09-01 lists those shapes; a range this tool reports as
unreferenced is "no reference of these three kinds", nothing more.

RUN
    python3 scripts/analysis/nakarest_refs.py v10 0xEB3BDE 0xEB3FDE
"""
import bisect
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
BASE = 0xE00000
ID = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\b')
HEX = re.compile(r'\b0x([0-9A-Fa-f]{5,8})\b')
RAMHEX = re.compile(r'\b0x([0-9A-Fa-f]{3,5})\b')
RAMDEC = re.compile(r'\((\d{3,6}):(?:16|24)\)')

# The work-RAM initial image (the C runtime's .data copy): Boot_InitWorkRAM
# (boot/system_handlers.s) copies two ROM blocks to RAM with `ldir` (83 11,
# a byte copy).  Each block's setup is `ld xde, <RAM dest>` (42 imm32),
# `ld xhl, <ROM src>` (43 imm32), `ld xbc, <count>` (41 imm32), read here
# out of each version's ROM at the labels Boot_InitWorkRAM_ROMCopy1_Start /
# _ROMCopy2_Start -- v10/v9 copy 0x219E bytes to 0x3D524 and 0x95B to
# 0xE35E; v7's second block is 0x931 bytes to 0xE2C2.
def ram_images(sym, rom):
    out = []
    for lab in ('Boot_InitWorkRAM_ROMCopy1_Start', 'Boot_InitWorkRAM_ROMCopy2_Start'):
        a = sym.get(lab)
        if a is None:
            continue
        b = rom[a - BASE:a - BASE + 15]
        if b[0] != 0x42 or b[5] != 0x43 or b[10] != 0x41:
            continue
        dst = int.from_bytes(b[1:5], 'little')
        src = int.from_bytes(b[6:10], 'little')
        cnt = int.from_bytes(b[11:15], 'little')
        out.append((src, src + cnt, dst))
    return out


class Refs:
    def __init__(self, v):
        self.v = v
        elf = os.path.join(ROOT, 'rebuilt_ROMs', 'kn5000_%s_program.llvm.elf' % v)
        out = subprocess.run([os.path.join(LLVM, 'llvm-nm'), '--defined-only', elf],
                             capture_output=True, text=True, check=True).stdout
        self.sym = {}
        for ln in out.split('\n'):
            f = ln.split()
            if len(f) == 3 and f[1] in 'tTaA' and not f[2].startswith('__'):
                self.sym.setdefault(f[2], int(f[0], 16))
        self.rom = open(os.path.join(ROOT, 'original_ROMs', 'kn5000_%s_program.rom' % v), 'rb').read()
        rev = sorted((a, n) for n, a in self.sym.items() if BASE <= a < BASE + len(self.rom))
        self.rev_a = [a for a, _ in rev]
        self.rev_n = [n for _, n in rev]
        self.uses = []          # (addr, kind, file, line, text, routine)
        self.ram_uses = []
        self._scan()
        self.uses.sort()
        self.use_a = [u[0] for u in self.uses]
        self.ram_uses.sort()
        self.ram_a = [u[0] for u in self.ram_uses]
        self.images = ram_images(self.sym, self.rom)
        self._data = None

    def _scan(self):
        for f in sorted(glob.glob(os.path.join(ROOT, self.v, 'maincpu', '**', '*.s'), recursive=True)):
            rel = os.path.relpath(f, os.path.join(ROOT, self.v, 'maincpu'))
            routine = None
            for i, raw in enumerate(open(f, encoding='latin-1')):
                line = raw.rstrip('\n')
                code = line.split(';', 1)[0]
                m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', code)
                if m:
                    routine = m.group(1)
                    code = code[m.end():]
                s = code.strip()
                if not s or s.startswith(('.set', '.equ', '.globl', '.include', '.incbin')):
                    continue
                for n in ID.findall(s):
                    a = self.sym.get(n)
                    if a is not None and BASE <= a < BASE + len(self.rom):
                        self.uses.append((a, 'symbol ' + n, rel, i + 1, s, routine))
                for h in HEX.findall(s):
                    a = int(h, 16)
                    if BASE <= a < BASE + len(self.rom):
                        self.uses.append((a, 'numeric', rel, i + 1, s, routine))
                for h in RAMHEX.findall(s):
                    self.ram_uses.append((int(h, 16), 'RAM literal', rel, i + 1, s, routine))
                for d in RAMDEC.findall(s):
                    self.ram_uses.append((int(d), 'RAM literal', rel, i + 1, s, routine))

    def _build_words(self):
        r = self.rom
        words = []
        for off in range(0, len(r) - 3):
            if r[off + 3] != 0 or r[off + 2] < 0xE0:
                continue
            words.append((int.from_bytes(r[off:off + 4], 'little'), BASE + off))
        words.sort()
        self._data = words
        self._data_v = [w[0] for w in words]

    def data_refs(self, lo, hi, max_word_addr=None):
        """(word address, value, preceding symbol) for every aligned-or-not LE32
        word in the ROM whose value is in [lo, hi) (words inside the range
        itself excluded; with max_word_addr, only words below it)."""
        if self._data is None:
            self._build_words()
        i = bisect.bisect_left(self._data_v, lo)
        j = bisect.bisect_left(self._data_v, hi)
        out = []
        for v, a in self._data[i:j]:
            if lo <= a < hi:
                continue
            if max_word_addr is not None and a >= max_word_addr:
                continue
            out.append((a, v, self.name_before(a)))
        return out

    def name_before(self, a):
        i = bisect.bisect_right(self.rev_a, a) - 1
        return '%s+0x%X' % (self.rev_n[i], a - self.rev_a[i]) if i >= 0 else '?'

    def ram_mirror(self, lo, hi):
        """[(ram_lo, ram_hi)] of the work-RAM copies of ROM [lo, hi)."""
        out = []
        for a, b, r in self.images:
            x, y = max(lo, a), min(hi, b)
            if x < y:
                out.append((r + x - a, r + y - a))
        return out

    def ram_in_range(self, lo, hi):
        i = bisect.bisect_left(self.ram_a, lo)
        j = bisect.bisect_left(self.ram_a, hi)
        return self.ram_uses[i:j]

    def in_range(self, lo, hi):
        i = bisect.bisect_left(self.use_a, lo)
        j = bisect.bisect_left(self.use_a, hi)
        return self.uses[i:j]


def main():
    v = sys.argv[1]
    lo, hi = int(sys.argv[2], 0), int(sys.argv[3], 0)
    R = Refs(v)
    for a, kind, f, ln, text, routine in R.in_range(lo, hi):
        print('0x%06X %-40s %s:%d  [%s]  %s' % (a, kind, f, ln, routine, text))
    for a, val, nm in R.data_refs(lo, hi):
        print('0x%06X data word at 0x%06X (%s)' % (val, a, nm))


if __name__ == '__main__':
    main()
