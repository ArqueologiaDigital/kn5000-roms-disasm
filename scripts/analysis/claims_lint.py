#!/usr/bin/env python3
"""claims_lint.py -- lint the SEMANTIC claims that comments and headers make, which the byte
gate cannot see.

QUESTION THIS ANSWERS
  `make gate-all` proves that every image rebuilds byte for byte.  It proves nothing about the
  prose around the bytes: a header can name a routine that was renamed three waves ago, say
  "no reader found" over a table that a pointer two kilobytes away reads, promise "a table of 12
  pointers" over eleven `.long`s, or quote a v10 address in the v7 tree, and the gate stays
  green.  The 2026-10-02 adversarial review of the Wave 2 lanes found those defects by hand,
  with one-off probes (disasm-lanes/review-w2/*/: midi-sys/check_header_addrs.py,
  check_table_counts.py, check_unread_slices.py; accomp-audio/check_reader_addrs.py,
  v7_label_alignment.py; uiproc-uimisc/stale_names.py; nakabig-nakarest/unref_claims.py).
  This script turns the recurring patterns into one tree-wide instrument, one check each:

    stale-names     a symbol-like name in a comment that nothing defines any more
    unread-claims   "no reader found" / "purpose not established" / NoRef_ / Unref_ claims
                    that a pointer, a source reference or a block copy contradicts
    table-counts    "table of N pointers" / "N x u32" / "N entries" vs the rows emitted
    header-addrs    "Name (0xADDR)" / "Name = 0xADDR" / "Name at 0xADDR" vs the ELF, per image
    empty-templates templated header lines with nothing after them, unformatted placeholders

  Every check has its own docstring (question, signal, what a hit means, known false-positive
  shapes); `--explain` prints them.

WHAT IS READ
  * sources: for each image, the files its root .s reaches through `.include` (the same graph
    llvm-mc walks: includer's directory, then each -I directory), plus the image tree's C
    sources (*.c, *.h) for the comment checks.  .s files are LATIN-1 (raw ROM bytes inside
    .ascii) and are read as bytes and decoded latin-1, never as UTF-8.
  * symbols: `llvm-nm --defined-only` of each image's linked ELF (`--elf-dir`, repeatable; the
    first directory holding a given ELF wins).  Copy the ELFs aside first if another agent may
    run `make clean` while this runs.
  * image bytes: the ELF's .text section (the gate makes it byte-identical to the original
    ROM); the original ROM is compared over the overlap and any difference is reported.
  * "defined anywhere": every image's ELF symbols, every label / .set / .equ / .equiv / NAME= /
    .macro (and ASL `NAME equ` / `NAME label`) in any .s/.inc/.asm of the tree, and every
    identifier in the code (not comments, not strings) of any .c/.h/.cpp/.hpp of the tree.
    archive/ (the pre-rename ASL tree) and cruft_please_ignore/ are excluded on purpose:
    names defined only there are old names.
  * rename history: the OLD side of scripts/renaming/*.sed (`s/OLD/NEW/`, any address prefix,
    \\b \\< \\> anchors stripped), *.map (`OLD=NEW`) and, as a weaker source, the 'OLD': 'NEW'
    pairs of scripts/renaming/*.py.

OUTPUT
  One TSV per check in --out DIR (default $TMPDIR/claims_lint, never /tmp):
      image  file  line  label  detail
  `image` is the image that owns the file (the first image, in the order below, whose include
  graph reaches it; the detail says "shared with ..." when others include it too).  `detail`
  starts with an upper-case KIND.  Strong kinds are the hits; WEAK-* kinds are written to the
  same TSV and counted in a separate table so they can be filtered.  A summary table (hits per
  check per image) goes to stdout.

USAGE
  python3 scripts/analysis/claims_lint.py [CHECK ...] [--images v10,v7,...] [--out DIR]
          [--elf-dir DIR ...] [--repo DIR]
  python3 scripts/analysis/claims_lint.py --selftest      # plants one bad example per check
  python3 scripts/analysis/claims_lint.py --explain       # prints every check's docstring

  CHECK defaults to all five.  Images: v10 v9 v7 v142 subboot tabledata customdata hdae5000
  prom_a prom_b prom_c prom_d.

  Example, with the ELFs copied aside first so that a concurrent `make clean` cannot pull
  them away mid-run (about 2 minutes for all twelve images):
    python3 scripts/analysis/claims_lint.py \\
        --elf-dir ~/compartilhado/disasm-lanes/claims-lint/elf \\
        --out ~/compartilhado/disasm-lanes/claims-lint/out

  .s files under an image's tree that its include graph never reaches (v10/v9/v7: the 17
  audio/sound_data_*.s, includes/gui_*.s, ui_widgets/block_007.s) are not built and not
  scanned; the run prints how many per image.
"""
import argparse
import bisect
import collections
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile

try:
    import numpy as np
except ImportError:          # the pointer scan falls back to pure Python
    np = None

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
LLVM_NM = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-nm')

CHECKS = ['stale-names', 'unread-claims', 'table-counts', 'header-addrs', 'empty-templates']

# name: (assembler cwd, root .s, -I dirs (relative to cwd), ELF basename, original ROM,
#        C-source directories, peers: images on the same bus whose bytes may hold a pointer)
IMAGES = collections.OrderedDict([
    ('v10', ('.', 'v10/maincpu/kn5000_v10_program.s', ['v10/maincpu'],
             'kn5000_v10_program.llvm.elf', 'original_ROMs/kn5000_v10_program.rom',
             ['v10/maincpu'], ['tabledata', 'customdata', 'hdae5000'])),
    ('v9', ('.', 'v9/maincpu/kn5000_v9_program.s', ['v9/maincpu'],
            'kn5000_v9_program.llvm.elf', 'original_ROMs/kn5000_v9_program.rom',
            ['v9/maincpu'], ['tabledata', 'customdata', 'hdae5000'])),
    ('v7', ('.', 'v7/maincpu/kn5000_v7_program.s', ['v7/maincpu'],
            'kn5000_v7_program.llvm.elf', 'original_ROMs/kn5000_v7_program.rom',
            ['v7/maincpu'], ['tabledata', 'customdata', 'hdae5000'])),
    ('v142', ('.', 'v142/subcpu/kn5000_subprogram_v142.s', ['v142/subcpu'],
              'kn5000_subprogram_v142.llvm.elf', 'original_ROMs/kn5000_subprogram_v142.rom',
              ['v142/subcpu'], ['subboot'])),
    ('subboot', ('.', 'subcpu/boot/kn5000_subcpu_boot.s', ['subcpu/boot'],
                 'kn5000_subcpu_boot.llvm.elf', 'original_ROMs/kn5000_subcpu_boot.ic30',
                 ['subcpu/boot'], ['v142'])),
    ('tabledata', ('.', 'table_data/kn5000_table_data.s', ['table_data'],
                   'kn5000_table_data.llvm.elf', 'original_ROMs/kn5000_table_data.rom',
                   ['table_data'], ['v10', 'v9', 'v7', 'customdata', 'hdae5000'])),
    ('customdata', ('.', 'custom_data/kn5000_custom_data.s', ['custom_data'],
                    'kn5000_custom_data.llvm.elf', 'original_ROMs/kn5000_custom_data.ic19',
                    ['custom_data'], ['v10', 'v9', 'v7', 'tabledata', 'hdae5000'])),
    ('hdae5000', ('.', 'hdae5000/hd-ae5000_v2_06i.s', ['hdae5000'],
                  'hd-ae5000_v2_06i.llvm.elf', 'original_ROMs/hd-ae5000_v2_06i.ic4',
                  ['hdae5000'], ['v10', 'v9', 'v7', 'tabledata', 'customdata'])),
    ('prom_a', ('wsa1', 'prom_a/wsa1_prom_a.s', ['.', 'prom_a'],
                'wsa1_prom_a.llvm.elf', 'wsa1/original_ROMs/wsa1_prom_a.ic12',
                ['wsa1/prom_a'], ['prom_b'])),
    ('prom_b', ('wsa1', 'prom_b/wsa1_prom_b.s', ['.', 'prom_b'],
                'wsa1_prom_b.llvm.elf', 'wsa1/original_ROMs/wsa1_prom_b.ic13',
                ['wsa1/prom_b'], ['prom_a'])),
    ('prom_c', ('wsa1', 'prom_c/wsa1_prom_c.s', ['.', 'prom_c'],
                'wsa1_prom_c.llvm.elf', 'wsa1/original_ROMs/wsa1_prom_c.ic28',
                ['wsa1/prom_c'], [])),
    ('prom_d', ('wsa1', 'prom_d/wsa1_prom_d.s', ['.', 'prom_d'],
                'wsa1_prom_d.llvm.elf', 'wsa1/original_ROMs/wsa1_prom_d.bin',
                ['wsa1/prom_d'], [])),
])
# How the original ROM file is laid out over the ELF .text bytes, where it is not 1:1:
# [(text offset, rom offset, length or None = to the end)].  v142: the Makefile keeps the first
# 256 bytes of the linked binary and then everything from offset 60416 (0xEC00) on.
ROM_LAYOUT = {'v142': [(0, 0, 256), (60416, 256, None)]}
# Images linked at a base this low hold their own addresses as ordinary small numbers, so a
# 32-bit little-endian value in range is no evidence of a pointer there (v142 at 0x400,
# prom_d at 0): the ROM-pointer signal is off for them and only source signals count.
PTR_SCAN_MIN_BASE = 0x100000

# Version words a comment line can use to say "this address is for another image".
VERSION_WORDS = [(re.compile(r'\bv10\b|\bv9/v10\b', re.I), 'v10'),
                 (re.compile(r'\bv9\b', re.I), 'v9'),
                 (re.compile(r'\bv7\b', re.I), 'v7'),
                 (re.compile(r'\bv1\.?42\b|\bv142\b', re.I), 'v142'),
                 (re.compile(r'\bprom[_ ]?a\b|\bIC12\b', re.I), 'prom_a'),
                 (re.compile(r'\bprom[_ ]?b\b|\bIC13\b', re.I), 'prom_b'),
                 (re.compile(r'\bprom[_ ]?c\b|\bIC28\b', re.I), 'prom_c'),
                 (re.compile(r'\bprom[_ ]?d\b', re.I), 'prom_d'),
                 (re.compile(r'\btable[_ ]data\b', re.I), 'tabledata'),
                 (re.compile(r'\bcustom[_ ]data\b|\bIC19\b', re.I), 'customdata'),
                 (re.compile(r'\bHD-?AE5000\b', re.I), 'hdae5000')]

EXCLUDE_DIRS = {'archive', 'cruft_please_ignore', '.git', 'rebuilt_ROMs', 'node_modules',
                '__pycache__'}
FILE_EXTS = ('md', 'py', 's', 'S', 'c', 'h', 'cpp', 'hpp', 'bin', 'sed', 'map', 'txt', 'json',
             'ld', 'asm', 'inc', 'sh', 'rom', 'elf', 'tsv', 'csv', 'mk', 'o', 'yml', 'yaml',
             'png', 'bmp', 'lua', 'unidasm', 'ic4', 'ic19', 'ic30', 'ic12', 'ic13', 'ic28',
             'html', 'svg', 'gif', 'pdf', 'log', 'diff', 'patch', 'nm', 'dat', 'mid', 'wav')
# CamelCase words that are prose, not symbols.
PROSE_CAMEL = {'GitHub', 'JavaScript', 'PostScript', 'TrueType', 'OpenType', 'SoundFont',
               'SmartMedia', 'CompactFlash', 'PlayStation', 'LibreOffice', 'MacOS', 'PowerPC',
               'YouTube', 'WordPress', 'FreeBSD', 'NetBSD', 'OpenBSD', 'BusyBox', 'DosBox',
               'DOSBox', 'ShiftJIS', 'MicroPython', 'SysExes', 'ChatGPT', 'OpenAI',
               'MegaDrive', 'GameBoy', 'MainCPU', 'SubCPU', 'CamelCase', 'CamelCased', 'CamelCases',
               'PascalCase', 'LowerCamel', 'UpperCamel'}

IDENT = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
# C standard-library macro names (float.h / limits.h / stdint.h) that comments quote.
C_STD_NAME = re.compile(r'^(?:DBL|FLT|LDBL|INT|UINT|LONG|ULONG|LLONG|ULLONG|SHRT|USHRT|CHAR|SCHAR|'
                        r'UCHAR|SIZE|PTRDIFF|INTPTR|UINTPTR|WCHAR|INT8|INT16|INT32|INT64|UINT8|'
                        r'UINT16|UINT32|UINT64)_[A-Z0-9_]+$')
# A mention that is history on purpose ("Renamed from Foo_Bar", "formerly Foo_Bar").  Applied
# to the text before the token, which includes the previous comment line of the same block
# ("Renamed 2026-09-25 from\n; CALL_TABLE_12159").
HISTORICAL = re.compile(r'(?:renamed|formerly|previously|was (?:called|named|labell?ed|spelled)|'
                        r'old name|used to be|replaces|replaced|retired|deleted|removed|dropped|'
                        r'superseded|instead of|no longer|\bwas\b|\bwere\b|\bnee\b|\bn\xe9e\b|'
                        r'\bnamed\s+(?:in|by|during|at)\b[^;]{0,30}\bas\b|'
                        r'under the\s+(?:old\s+|legacy\s+)*label|promoted|proposed (?:label|name)|'
                        r'suggested (?:label|name)|would be (?:named|called))[^;]{0,40}$', re.I)
# The unambiguous history words reach further, to the end of their sentence: "The old names
# UIState_Config{A,B,C}_NNN, UIState_HandlerTable_*, ... and UIState_EventHandler_Table".
HISTORICAL_STRONG = re.compile(r'(?:renamed|formerly|previously|old names?|used to be|'
                               r'(?:was|were) (?:named|called|labell?ed)|retired|superseded|'
                               r'no longer)[^;.]{0,110}$', re.I)
# ... and after it: "Foo_Bar (old name)", "Foo_Bar -- the retired label".
HISTORICAL_AFTER = re.compile(r'^\W{0,4}(?:(?:was|is|=)\s+)?(?:the\s+|its\s+|an?\s+)?(?:old|former|'
                              r'previous|retired|historical|legacy|stale|obsolete)\s+'
                              r'(?:name|label|spelling)|^\W{0,4}(?:,\s*)?NOT APPLIED|'
                              r'^\W{0,4}(?:is|was|are|were)\s+not\s+(?:a\s+|an\s+)?(?:label|symbol)',
                              re.I)
# Comment text that is the ASCII column of a hex dump (`0x45, 0x54, ... /* ETONHYB1..TT_SEP */`):
# fragments of ROM strings, not names.  The code holds only byte literals and the comment is
# exactly as wide as the number of bytes.
HEXDUMP_CODE = re.compile(r'^\s*(?:\.(?:byte|2byte|short|hword)\s+)?((?:(?:0x[0-9A-Fa-f]{1,4}|\d{1,3})'
                          r'\s*,\s*)+(?:0x[0-9A-Fa-f]{1,4}|\d{1,3})?)\s*,?\s*$')
# Names a comment DECLARES as a field or type of a structure it describes in pseudo-C or as
# a layout row: `struct P7ValueTable {`, `u8 unk_0C;`, `+0x14 ParamListPtr (RAM)`,
# `+0x00  .long  ProcPtr`.  They are prose names of fields, not labels.
CDECL_TYPES = (r'(?:u8|u16|u24|u32|u64|s8|s16|s32|s64|i8|i16|i32|uint8_t|uint16_t|uint32_t|'
               r'int8_t|int16_t|int32_t|char|short|int|long|byte|word|dword|ptr24|ptr32|addr24|'
               r'bool|float|double|void\s*\*|BYTE|WORD|DWORD)')
CDECL_NAME = re.compile(r'\bstruct\s+([A-Za-z_]\w*)|\b' + CDECL_TYPES +
                        r'\s+\*?\s*([A-Za-z_]\w*)\s*(?:\[[^\]]*\])?\s*[;,]')
LAYOUT_FIELD = re.compile(r'(?:^|[\s,;(])\+\s*(?:0x[0-9A-Fa-f]+|\d+)\s*(?:(?:\.\.|-)\s*\+?\s*'
                          r'(?:0x[0-9A-Fa-f]+|\d+)\s*)?(?::\s*)?(?:\.?(?:long|short|byte|word|'
                          r'u8|u16|u24|u32|s8|s16|s32|ptr|ptr24|ptr32|addr24)\s+)?'
                          r'([A-Za-z_]\w*)\b(?!\s*\()')
# A two-part ALL-CAPS tag (`MENU_ITEM`, `SLOT_CONTROL`, `FILLED_RECT`, `ST1_EN`, `CURVE_D`):
# enum-like vocabulary of widget types, record ops and datasheet bit names, written in prose.
# An address-like part (`T_F41CD0`, `DL_F3A461`) keeps a token strong.
CAPS_TAG = re.compile(r'[A-Z][A-Z0-9]*_[A-Z0-9]+s?')
ADDR_PART = re.compile(r'(?:^|_)(?:0x)?[0-9A-Fa-f]{4,}(?:_|$)')
HUMP = re.compile(r'[A-Z][a-z]')
LABEL_DEF = re.compile(r'^\s*([A-Za-z_$][\w$]*)\s*:(?![:=])')
SET_DEF = re.compile(r'^\s*\.(?:set|equ|equiv|eqv)\s+([A-Za-z_$][\w$]*)\s*,', re.I)
ASSIGN_DEF = re.compile(r'^\s*([A-Za-z_$][\w$]*)\s*=(?!=)')
MACRO_DEF = re.compile(r'^\s*\.macro\s+([A-Za-z_$][\w$]*)', re.I)
ASL_DEF = re.compile(r'^\s*([A-Za-z_][\w]*)\s+(?:equ|set|label|eval)\b', re.I)
INCLUDE = re.compile(r'^\s*\.include\s+"([^"]+)"')


# ============================================================================ source model

class SourceFile:
    """One source file as (code, comment) per line.  `comment` is None on a line without one.
    .s/.inc/.asm: comment = text after the first ';' outside a "string" / 'c' literal, or a
    whole line starting with '//'.  .c/.h: // and /* */ comments, per line."""

    def __init__(self, path, rel, kind=None):
        self.path = path
        self.rel = rel
        self.kind = kind or ('c' if path.endswith(('.c', '.h', '.cpp', '.hpp')) else 's')
        text = open(path, 'rb').read().decode('latin-1')
        raw = text.split('\n')
        if raw and raw[-1] == '':
            raw.pop()
        self.raw = raw
        if self.kind == 'c':
            self.code, self.comment = split_c(raw)
        else:
            self.code, self.comment = [], []
            in_block = False
            for line in raw:
                c, m, in_block = split_asm(line, in_block)
                self.code.append(c)
                self.comment.append(m)
        self._labels = None

    def labels(self):
        """[(line_index, name)] for every label definition, in order."""
        if self._labels is None:
            out = []
            if self.kind == 's':
                for i, c in enumerate(self.code):
                    m = LABEL_DEF.match(c)
                    if m and not m.group(1).startswith('.L'):
                        out.append((i, m.group(1)))
            self._labels = out
        return self._labels

    def comment_only(self, i):
        return self.comment[i] is not None and self.code[i].strip() == ''

    def context_labels(self):
        """Per line: the label a line is 'about' -- the label a comment block directly
        precedes, else the most recent label before the line."""
        n = len(self.raw)
        ctx = [''] * n
        cur = ''
        lab_at = dict(self.labels())
        for i in range(n):
            if i in lab_at:
                cur = lab_at[i]
            ctx[i] = cur
        # comment-only blocks attached to the label right below them
        i = n - 1
        while i >= 0:
            if i in lab_at:
                j = i - 1
                while j >= 0 and self.comment_only(j):
                    ctx[j] = lab_at[i]
                    j -= 1
                i = j
            else:
                i -= 1
        return ctx


def split_asm(line, in_block):
    """Return (code, comment-or-None, in_block) for one assembler line."""
    if in_block:
        end = line.find('*/')
        if end < 0:
            return '', line, True
        rest_code, rest_cmt, ib = split_asm(line[end + 2:], False)
        cm = line[:end] + ((' ' + rest_cmt) if rest_cmt else '')
        return rest_code, cm, ib
    if '"' not in line and "'" not in line and '/' not in line:
        k = line.find(';')
        return (line, None, False) if k < 0 else (line[:k], line[k + 1:], False)
    s = line.lstrip()
    if s.startswith('//'):
        return '', s[2:], False
    if s.startswith('/*'):
        body = s[2:]
        end = body.find('*/')
        if end < 0:
            return '', body, True
        return '', body[:end], False
    i, n = 0, len(line)
    while i < n:
        ch = line[i]
        if ch == '"':
            i += 1
            while i < n and line[i] != '"':
                i += 2 if line[i] == '\\' else 1
            i += 1
            continue
        if ch == "'":
            if re.match(r"'(\\.|[^\\'])'", line[i:]):
                i += 4 if line[i + 1] == '\\' else 3
                continue
        if ch == ';':
            return line[:i], line[i + 1:], False
        i += 1
    return line, None, False


def split_c(raw):
    """Split C source lines into code and comment text (strings blanked out of code)."""
    code, cmt = [], []
    state = None                     # None, 'block'
    for line in raw:
        c, m = [], []
        i, n = 0, len(line)
        while i < n:
            if state == 'block':
                end = line.find('*/', i)
                if end < 0:
                    m.append(line[i:])
                    i = n
                else:
                    m.append(line[i:end])
                    i = end + 2
                    state = None
                continue
            ch = line[i]
            if line.startswith('//', i):
                m.append(line[i + 2:])
                i = n
            elif line.startswith('/*', i):
                state = 'block'
                i += 2
            elif ch in '"\'':
                q = ch
                j = i + 1
                while j < n and line[j] != q:
                    j += 2 if line[j] == '\\' else 1
                c.append(q + q)
                i = j + 1
            else:
                c.append(ch)
                i += 1
        code.append(''.join(c))
        cmt.append(' '.join(m) if m else None)
    return code, cmt


def string_literals(code):
    return re.findall(r'"((?:[^"\\]|\\.)*)"', code)


# ============================================================================ symbols / ELF

def elf_text(path):
    """(base address, bytes) of the .text section of a 32-bit little-endian ELF."""
    data = open(path, 'rb').read()
    if data[:4] != b'\x7fELF' or data[4] != 1:
        raise SystemExit('%s: not a 32-bit ELF' % path)
    e_shoff, = struct.unpack_from('<I', data, 0x20)
    e_shentsize, e_shnum, e_shstrndx = struct.unpack_from('<HHH', data, 0x2E)
    secs = []
    for k in range(e_shnum):
        off = e_shoff + k * e_shentsize
        name, typ, flags, addr, offset, size = struct.unpack_from('<IIIIII', data, off)
        secs.append((name, typ, addr, offset, size))
    stro = secs[e_shstrndx][3]
    for name, typ, addr, offset, size in secs:
        nm = data[stro + name:data.index(b'\0', stro + name)]
        if nm == b'.text':
            return addr, data[offset:offset + size]
    raise SystemExit('%s: no .text section' % path)


class Image:
    def __init__(self, name, repo, elf_dirs):
        self.name = name
        cwd, root, inc, elf, rom, cdirs, peers = IMAGES[name]
        self.cwd = os.path.join(repo, cwd)
        self.root = root
        self.inc = inc
        self.cdirs = cdirs
        self.peers = peers
        self.elf = None
        for d in elf_dirs:
            p = os.path.join(d, elf)
            if os.path.exists(p):
                self.elf = p
                break
        if self.elf is None:
            raise SystemExit('ELF %s not found in %s' % (elf, elf_dirs))
        self.rom_path = os.path.join(repo, rom)
        self.sym = {}                      # name -> (addr, type)
        out = subprocess.run([LLVM_NM, '--defined-only', self.elf], capture_output=True,
                             text=True, check=True).stdout
        for line in out.splitlines():
            p = line.split()
            if len(p) == 3:
                self.sym.setdefault(p[2], (int(p[0], 16), p[1]))
        self.text_addrs = sorted({a for a, t in self.sym.values() if t in 'tT'})
        self.abs_values = {a for a, t in self.sym.values() if t in 'aA'}
        self.addr_names = collections.defaultdict(list)
        for n, (a, t) in self.sym.items():
            if t in 'tT':
                self.addr_names[a].append(n)
        self.base, self.bytes = elf_text(self.elf)
        self.end = self.base + len(self.bytes)
        self.rom_note = ''
        if os.path.exists(self.rom_path):
            rom = open(self.rom_path, 'rb').read()
            diff = total = 0
            for toff, roff, ln in ROM_LAYOUT.get(name, [(0, 0, None)]):
                a = self.bytes[toff:] if ln is None else self.bytes[toff:toff + ln]
                b = rom[roff:] if ln is None else rom[roff:roff + ln]
                n = min(len(a), len(b))
                total += n
                if a[:n] != b[:n]:
                    diff += sum(1 for x, y in zip(a[:n], b[:n]) if x != y)
            if diff:
                self.rom_note = 'ELF .text differs from %s in %d of %d compared bytes' % (
                    self.rom_path, diff, total)
        else:
            self.rom_note = 'original ROM %s missing' % self.rom_path
        self._ptr = None
        self._push = None

    def next_text_addr(self, addr, skip_prefix=None):
        """Address of the first .text symbol above addr (skipping children `prefix_*`)."""
        k = bisect.bisect_right(self.text_addrs, addr)
        while k < len(self.text_addrs):
            a = self.text_addrs[k]
            names = self.addr_names[a]
            if skip_prefix and any(n.startswith(skip_prefix + '_') for n in names):
                k += 1
                continue
            return a
        return self.end

    def ptr_index(self):
        """Sorted (value, position) of every 32-bit little-endian value inside this image's
        address range (= an LE24 pointer followed by a 0x00 high byte)."""
        if self._ptr is None:
            b = self.bytes
            if np is not None and len(b) >= 4:
                a = np.frombuffer(b, dtype=np.uint8).astype(np.uint32)
                v = a[:-3] | (a[1:-2] << 8) | (a[2:-1] << 16) | (a[3:] << 24)
                pos = np.nonzero((v >= self.base) & (v < self.end))[0]
                vals = v[pos]
                order = np.argsort(vals, kind='stable')
                self._ptr = (vals[order].tolist(), pos[order].tolist())
            else:
                pairs = []
                for i in range(len(b) - 3):
                    v = b[i] | b[i + 1] << 8 | b[i + 2] << 16 | b[i + 3] << 24
                    if self.base <= v < self.end:
                        pairs.append((v, i))
                pairs.sort()
                self._ptr = ([p[0] for p in pairs], [p[1] for p in pairs])
        return self._ptr

    def push_index(self):
        """Sorted (value, position) of `pushw hi16 / pushw lo16` pairs (0x0b hh 00 0b ll mm),
        the way compiled code passes a 32-bit pointer on the stack."""
        if self._push is None:
            b = self.bytes
            pairs = []
            for m in re.finditer(rb'\x0b(?=.\x00\x0b..)', b, re.S):
                i = m.start()
                v = (b[i + 1] << 16) | b[i + 4] | (b[i + 5] << 8)
                pairs.append((v, i))
            pairs.sort()
            self._push = ([p[0] for p in pairs], [p[1] for p in pairs])
        return self._push


def range_hits(index, lo, hi):
    vals, poss = index
    a = bisect.bisect_left(vals, lo)
    b = bisect.bisect_left(vals, hi)
    return list(zip(vals[a:b], poss[a:b]))


# ============================================================================ include graph

def include_closure(repo, name):
    cwd, root, inc, *_ = IMAGES[name]
    base = os.path.join(repo, cwd)
    seen, order = set(), []
    stack = [os.path.normpath(os.path.join(base, root))]
    while stack:
        p = stack.pop()
        if p in seen or not os.path.exists(p):
            continue
        seen.add(p)
        order.append(p)
        kids = []
        for line in open(p, 'rb').read().decode('latin-1').split('\n'):
            code, _, _ = split_asm(line, False)
            m = INCLUDE.match(code)
            if not m:
                continue
            tgt = m.group(1)
            for cand in [os.path.join(os.path.dirname(p), tgt)] + \
                        [os.path.join(base, d, tgt) for d in inc] + [os.path.join(base, tgt)]:
                cand = os.path.normpath(cand)
                if os.path.exists(cand):
                    kids.append(cand)
                    break
        stack.extend(reversed(kids))
    return order


def c_sources(repo, cdirs):
    out = []
    for d in cdirs:
        for dp, dns, fns in os.walk(os.path.join(repo, d)):
            dns[:] = sorted(x for x in dns if x not in EXCLUDE_DIRS)
            for f in sorted(fns):
                if f.endswith(('.c', '.h')):
                    out.append(os.path.join(dp, f))
    return out


class Tree:
    """Which files each image owns, parsed once.  `files[image]` lists SourceFile objects the
    image OWNS (first image in IMAGES order reaching the file); `members[path]` lists every
    image that includes the file."""

    def __init__(self, repo, image_names, override=None):
        self.repo = repo
        self.files = collections.OrderedDict()
        self.members = collections.defaultdict(list)
        self.all_files = collections.OrderedDict()      # every image's files (not just owned)
        cache = {}

        def get(p):
            if p not in cache:
                cache[p] = SourceFile(p, os.path.relpath(p, repo))
            return cache[p]

        for name in IMAGES:
            if name not in image_names:
                continue
            if override is not None:
                paths = override.get(name, [])
            else:
                paths = include_closure(repo, name) + c_sources(repo, IMAGES[name][5])
            self.all_files[name] = [get(p) for p in paths]
            for p in paths:
                self.members[p].append(name)
            self.files[name] = [get(p) for p in paths if self.members[p][0] == name]

    def shared_note(self, sf):
        m = self.members[sf.path]
        return (' [shared with %s]' % ','.join(m[1:])) if len(m) > 1 else ''


# ============================================================================ tree-wide facts

class Facts:
    """Everything 'defined anywhere', the string-literal words, and the rename history."""

    def __init__(self, repo, images):
        self.repo = repo
        self.defined = set()
        self.def_src = {}
        for im in images.values():
            for n in im.sym:
                self.defined.add(n)
                self.def_src.setdefault(n, 'elf:' + im.name)
        self.in_string = set()
        self.comment_decl = set()         # field / type names declared in comment pseudo-C
        for dp, dns, fns in os.walk(repo):
            dns[:] = sorted(x for x in dns if x not in EXCLUDE_DIRS)
            for f in fns:
                p = os.path.join(dp, f)
                if f.endswith(('.s', '.inc', '.asm')):
                    self._scan_asm(p)
                elif f.endswith(('.c', '.h', '.cpp', '.hpp')):
                    self._scan_c(p)
        self.sorted_defs = sorted(self.defined)
        self.sorted_rev = sorted(n[::-1] for n in self.defined)
        self._defs_blob = '\n' + '\n'.join(self.sorted_defs) + '\n'
        self.lower = {}
        for n in self.sorted_defs:
            self.lower.setdefault(n.lower(), n)
        self._wild = {}
        self.renames = {}                 # old -> (new, source file)
        self._load_renames()
        self.sorted_old = sorted(self.renames)
        self.sorted_old_rev = sorted(o[::-1] for o in self.renames)
        # identifier-shaped text inside the images' own bytes: NAKA class names (ResName,
        # TtlScreen), Matsushita debug strings -- firmware names, not labels
        self.rom_text = set()
        for im in images.values():
            for m in re.finditer(rb'[A-Za-z_][A-Za-z0-9_]{2,}', im.bytes):
                self.rom_text.add(m.group(0).decode('ascii'))

    def _add(self, n, src):
        self.defined.add(n)
        self.def_src.setdefault(n, src)

    def _scan_comment_decls(self, cm):
        if cm and ('+' in cm or 'struct' in cm or ';' in cm or ',' in cm):
            for m in CDECL_NAME.finditer(cm):
                self.comment_decl.add(m.group(1) or m.group(2))
            if '+' in cm:
                for m in LAYOUT_FIELD.finditer(cm):
                    self.comment_decl.add(m.group(1))

    def _scan_asm(self, p):
        rel = os.path.relpath(p, self.repo)
        in_block = False
        for line in open(p, 'rb').read().decode('latin-1').split('\n'):
            code, cm, in_block = split_asm(line, in_block)
            self._scan_comment_decls(cm)
            if not code.strip():
                continue
            for rx in (LABEL_DEF, SET_DEF, ASSIGN_DEF, MACRO_DEF):
                m = rx.match(code)
                if m:
                    self._add(m.group(1), rel)
            if p.endswith('.asm'):
                m = ASL_DEF.match(code)
                if m:
                    self._add(m.group(1), rel)
            if '"' in code:
                for s in string_literals(code):
                    self.in_string.update(IDENT.findall(s))

    def _scan_c(self, p):
        rel = os.path.relpath(p, self.repo)
        raw = open(p, 'rb').read().decode('latin-1').split('\n')
        code, cms = split_c(raw)
        for cm in cms:
            self._scan_comment_decls(cm)
        for c in code:
            for t in IDENT.findall(c):
                self._add(t, rel)
        for line in raw:
            if '"' in line:
                for s in string_literals(line):
                    self.in_string.update(IDENT.findall(s))

    def _load_renames(self):
        d = os.path.join(self.repo, 'scripts', 'renaming')
        if not os.path.isdir(d):
            return
        sed_s = re.compile(r's(.)(.*?)(?<!\\)\1(.*?)(?<!\\)\1[gIi0-9]*\s*$')
        for f in sorted(os.listdir(d)):
            p = os.path.join(d, f)
            rel = os.path.relpath(p, self.repo)
            txt = open(p, 'rb').read().decode('latin-1')
            if f.endswith('.sed'):
                for line in txt.split('\n'):
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    k = line.find('s/')
                    if k < 0:
                        k = line.find('s|')
                    if k < 0:
                        continue
                    m = sed_s.match(line[k:])
                    if not m:
                        continue
                    old = re.sub(r'\\[bB<>]|\^|\$', '', m.group(2))
                    new = re.sub(r'\\[0-9&]', '', m.group(3))
                    if IDENT.fullmatch(old) and IDENT.fullmatch(new):
                        self.renames.setdefault(old, (new, rel))
            elif f.endswith('.map'):
                for line in txt.split('\n'):
                    m = re.match(r'^\s*([A-Za-z_]\w*)\s*(?:=|->|\t|\s)\s*([A-Za-z_]\w*)\s*$', line)
                    if m:
                        self.renames.setdefault(m.group(1), (m.group(2), rel))
            elif f.endswith('.py'):
                for m in re.finditer(r'''['"]([A-Za-z_]\w{3,})['"]\s*[:,]\s*['"]([A-Za-z_]\w{3,})['"]''', txt):
                    old, new = m.group(1), m.group(2)
                    if old != new:
                        self.renames.setdefault(old, (new, rel + ' (py)'))

    # ---- queries
    def any_with_prefix(self, t, pool=None, rev=False):
        arr = pool if pool is not None else (self.sorted_rev if rev else self.sorted_defs)
        k = bisect.bisect_left(arr, t)
        return k < len(arr) and arr[k].startswith(t)

    def is_defined(self, tok, mode):
        if tok in self.defined:
            return True
        if mode == 'infix':
            return tok in self._defs_blob
        if mode == 'suffix':
            return self.any_with_prefix(tok[::-1], rev=True)
        if mode == 'prefix':
            return self.any_with_prefix(tok)
        return False

    def abbrev_of(self, tok):
        """A defined name that ends in '_' + tok ('ClassName_Table' of
        HDAE5000_ClassName_Table, 'MENU_ITEM' of NAKA_TYPE_MENU_ITEM), or None."""
        t = ('_' + tok)[::-1]
        k = bisect.bisect_left(self.sorted_rev, t)
        if k < len(self.sorted_rev) and self.sorted_rev[k].startswith(t):
            return self.sorted_rev[k][::-1]
        return None

    def numbered_family(self, tok):
        """True if tok names an array of numbered labels and nothing else: every defined
        name starting tok + '_' is tok_<n> ('ToneNumBank_Melodic' of _0 .. _7)."""
        pre = tok + '_'
        k = bisect.bisect_left(self.sorted_defs, pre)
        kids = []
        while k < len(self.sorted_defs) and self.sorted_defs[k].startswith(pre) and len(kids) < 65:
            kids.append(self.sorted_defs[k][len(pre):])
            k += 1
        return bool(kids) and all(re.fullmatch(r'(?:0x)?[0-9A-Fa-f]{1,4}', x) for x in kids)

    def fragment_of(self, tok):
        """True if tok occurs inside some defined name ('UserBitmap' in VwUserBitmapProc)."""
        return tok in self._defs_blob

    def wildcard_defined(self, tok):
        """'DSP_EffNN_Param_Values' / 'Foo_XX_Bar': NN / XX / nn / xx segments are digits or
        letters left out on purpose; True if some defined name fits."""
        if tok not in self._wild:
            wild = r'(?<=[A-Za-z_])(?:NN+|XX+|nn+|xx+)(?=_|$)|(?<=[a-z])N(?=_|$)'
            rx = re.sub(wild, '[0-9A-Za-z]+', tok)
            if rx == tok:
                self._wild[tok] = False
            else:
                pre = tok[:re.search(wild, tok).start()]
                k = bisect.bisect_left(self.sorted_defs, pre)
                cre = re.compile(rx)
                ok = False
                while k < len(self.sorted_defs) and self.sorted_defs[k].startswith(pre):
                    if cre.match(self.sorted_defs[k]):
                        ok = True
                        break
                    k += 1
                self._wild[tok] = ok
        return self._wild[tok]

    def final_name(self, old):
        seen = set()
        n = old
        while n in self.renames and n not in seen:
            seen.add(n)
            n = self.renames[n][0]
        return n

    def rename_note(self, tok, mode):
        """How the rename history explains a stale token, or ''."""
        def fmt(old, extra=''):
            new, src = self.renames[old]
            fin = self.final_name(old)
            tail = '' if fin == new else ' -> %s' % fin
            return 'RENAMED by %s: %s -> %s%s (%s)%s' % (
                src, old, new, tail, 'defined' if fin in self.defined else 'NOT defined', extra)
        if tok in self.renames:
            return fmt(tok)
        if mode in (None, 'prefix'):
            # child of a renamed parent: OLD_Loop where OLD -> NEW
            for k in range(len(tok) - 1, 0, -1):
                if tok[k] == '_' and tok[:k] in self.renames:
                    old = tok[:k]
                    fin = self.final_name(old)
                    cand = fin + tok[k:]
                    return fmt(old, '; child -> %s (%s)' % (
                        cand, 'defined' if cand in self.defined else 'NOT defined'))
        if mode == 'suffix':
            k = bisect.bisect_left(self.sorted_old_rev, tok[::-1])
            if k < len(self.sorted_old_rev) and self.sorted_old_rev[k].startswith(tok[::-1]):
                return fmt(self.sorted_old_rev[k][::-1], '; elided form')
        if mode == 'prefix':
            k = bisect.bisect_left(self.sorted_old, tok)
            if k < len(self.sorted_old) and self.sorted_old[k].startswith(tok):
                return fmt(self.sorted_old[k], '; elided form')
        return ''


def symbol_like(t, minlen=6):
    core = t.lstrip('_')
    if len(t) < minlen or not core:
        return False
    if t in PROSE_CAMEL:
        return False
    if '_' in core and re.search(r'[A-Z]', core):
        return True
    if re.fullmatch(r'[A-Za-z0-9]+', t) and re.search(r'[a-z]', t) and len(HUMP.findall(t)) >= 2:
        return True
    return False


ELLIPSIS = ('...', '..', '\u2026', '\xe2\x80\xa6')

ALIAS_BEFORE = re.compile(r'(?<![\w$])([A-Za-z_]\w*)\s*\(\s*(?:was\s+|formerly\s+|old(?:\s+name)?:?\s+|'
                          r'n\xe9e\s+)?`?$')


def alias_in_parens(cm, start, end, facts):
    """'NewName (OldName)' / 'NewName (was OldName)': a defined name, then the token alone in
    parentheses -- the old spelling kept beside the new one."""
    m = ALIAS_BEFORE.search(cm[:start])
    return bool(m and m.group(1) in facts.defined and symbol_like(m.group(1), 4) and
                re.match(r'`?\s*\)', cm[end:]))


def ram_name(cm, start, end, imn, images):
    """True when a token reads as a RAM variable: written as a dereference `(Name) + 0x..` /
    `(Name)[i]`, or quoted right next to an address that lies in no image of the file's bus
    (`Name (0x0413FB)`, `Name[1] (0x0413FB)`, `Name at 0x045310`, `0x229D90  Name`)."""
    if re.search(r'\(\s*$', cm[:start]) and re.match(r'\s*\)\s*(?:[-+]\s*0x|\[)', cm[end:]):
        return True
    im = images.get(imn)
    space = [im] + [images[p] for p in im.peers if p in images] if im else list(images.values())
    m = re.match(r'\s*(?:\[[^\]]{0,12}\]\s*)?(?:\(\s*|\bat\s+|@\s*|=\s*)0x([0-9A-Fa-f]{4,8})\b',
                 cm[end:end + 40]) or \
        re.search(r'(?<![\w.+])0x([0-9A-Fa-f]{4,8})\s+$', cm[max(0, start - 14):start])
    if not m:
        return False
    q = int(m.group(1), 16)
    if any(q in o.abs_values for o in space):
        return False            # an .equ names that address now: the token is its old name
    return not any(o.base <= q < o.end for o in space)


def hexdump_comment(code, cm):
    """True when cm is the ASCII column of a hex-dump line (as many characters as the line
    has byte literals): its 'names' are fragments of ROM strings."""
    m = HEXDUMP_CODE.match(code)
    if not m:
        return False
    n = len([x for x in m.group(1).split(',') if x.strip()])
    t = cm.strip()
    if t.endswith('*/'):
        t = t[:-2].rstrip()
    return n >= 4 and abs(len(t) - n) <= 1


def comment_tokens(text):
    """Yield (token, mode, start) for identifier tokens in comment text.  mode is 'suffix'
    when the token is elided on the left ('..._Foo', '_Foo'), 'prefix' when elided on the
    right ('Foo_...', 'Foo_'), else None.  Paths, file names and dotted members are skipped."""
    # Foo_{A,B} -> Foo_A, Foo_B (the parts inside the braces are not names on their own)
    braces = []
    for b in re.finditer(r'([A-Za-z_][A-Za-z0-9_]*)\{([A-Za-z0-9_, ]+)\}', text):
        braces.append((b.start(2), b.end(2)))
        for part in b.group(2).split(','):
            part = part.strip()
            if part:
                yield b.group(1) + part, None, b.start()
    for m in IDENT.finditer(text):
        s, e = m.start(), m.end()
        tok = m.group(0)
        if any(a <= s < z for a, z in braces) or text[e:e + 1] == '{':
            continue
        prev = text[s - 1] if s else ''
        mode = None
        if prev and (prev.isalnum() or prev in '_$'):
            continue
        if prev == '.':
            if any(text[:s].endswith(x) for x in ELLIPSIS):
                mode = 'suffix'
            else:
                continue
        elif text[:s].endswith('\xe2\x80\xa6'):
            mode = 'suffix'
        if prev in '/\\%@#&':
            continue
        nxt = text[e:e + 6]
        if nxt.startswith('/'):
            continue
        # a file name, also with a dotted chain: `Foo.bin`, `demo_preset_NN.original.bin`
        mext = re.match(r'((?:\.[A-Za-z0-9_-]{1,20}){1,3})\b', text[e:e + 64])
        if mext and any(x in FILE_EXTS for x in mext.group(1).split('.')[1:]):
            continue
        if mode is None and tok.startswith('_') and tok.endswith('_') and len(tok) > 2:
            mode = 'infix'           # '_SameAs_<name>': a naming component
        if mode is None and tok.startswith('_'):
            mode = 'suffix'
        # 'Foo_...' / 'Foo_*' / 'Foo_{A,B}' / 'Foo_<n>' are elided; 'Foo_Table[9]' is an index
        if nxt.startswith(('...', '\u2026', '\xe2\x80', '*', '{', '<')) or tok.endswith('_') or \
                (nxt.startswith('[') and not re.match(r'\[[^\]]{1,40}\]', nxt + text[e + 6:e + 46])):
            mode = 'prefix' if mode is None else mode
        # placeholder tail: LABEL_XXXXXX, Foo_N, Foo_nn, Foo_xx -> prefix match on the rest
        mp = re.match(r'^(.*_)(?:[Xx]+|[Nn]+|\?+)$', tok)
        if mp and mode is None and len(mp.group(1)) > 1:
            tok, mode = mp.group(1), 'prefix'
        yield tok, mode, s


# ============================================================================ checks

def check_stale_names(tree, images, facts):
    """stale-names -- does a comment name a symbol that no longer exists?

    QUESTION  Which symbol-like names written in comments are defined nowhere: not in any
    image's ELF symbol table, not as a label / .set / .equ / NAME= / .macro in any .s/.inc/.asm
    of the tree, not as an identifier in the code of any .c/.h of the tree?

    SIGNAL  Comment tokens (.s ';' comments, C // and /* */) that are symbol-like: length >= 6
    and either an underscore plus an upper-case letter (`MidiCC_Foo`, `LABEL_E04FB9`) or
    CamelCase with >= 2 humps (`ParamPopup`).  An elided token ('..._CC3_TableLookup', a
    leading '_', a trailing '_' or '...') is matched as a suffix / prefix of the defined names,
    '_SameAs_' (both ends) as an infix, 'DSP_EffNN_Param' with NN / XX as a wildcard.
    Paths and file names (`foo/Bar_Baz`, `TOOLCHAIN_VERSION.md`) are skipped.

    HIT  `STALE` -- the name is defined nowhere.  `STALE-RENAMED` -- also on the OLD side of a
    scripts/renaming/*.sed / *.map (or, marked "(py)", a renaming .py dict): the strongest
    signal; the detail gives the NEW name and whether it is defined, and for a child label
    (`OLD_Loop`) the NEW_Loop it should probably read.  Whole-word seds miss exactly these.
    `STALE-CASE` -- defined only in another letter case (`Foo_Table_0x1d32` for
    `Foo_Table_0x1D32`: a hex-lowercasing pass that reached into a symbol name).
    `WEAK-STALE-ROMTEXT` -- defined nowhere, but the token occurs verbatim as text in an
    image's bytes (NAKA class names such as ResName / TtlScreen, firmware debug strings):
    a firmware name, not a label.
    `WEAK-STALE*-HISTORICAL` -- the same, but the text before it (on the line or the line
    above) reads as a deliberate history note ("Renamed from", "formerly", "was", "were under
    the label", "named in wave 7 as", "Proposed label ..., NOT APPLIED"), the text after it
    does ("... was the old name"), or it is `NewName (OldName)`.
    Further WEAK tiers, written to the TSV but not counted (verified 2026-10-02: every one of
    the sampled rows in these tiers was a non-defect):
      `WEAK-STALE-ABBREV`   a defined name ends in '_' + token: a prefix left off
                            (ClassName_Table of HDAE5000_ClassName_Table, MENU_ITEM of
                            NAKA_TYPE_MENU_ITEM, TrackClear_StageZero of SoftKeyCol1_...).
      `WEAK-STALE-FRAGMENT` a '_'-less CamelCase token inside a defined name (UserBitmap of
                            VwUserBitmapProc).
      `WEAK-STALE-FAMILY`   the token names numbered rows, every Token_<n> is defined
                            (ToneNumBank_Melodic of _0 .. _7).
      `WEAK-STALE-FIELD`    a field / type some comment declares in pseudo-C or as a layout
                            row (`u8 unk_0C;`, `struct P7ValueTable {`, `+0x10 SigPtr`).
      `WEAK-STALE-TAG`      a two-part ALL-CAPS tag with no address part and no Token_*
                            family (SLOT_CONTROL, FILLED_RECT, ST1_EN, REF_EX).
      `WEAK-STALE-RAMBIT`   followed by `.<digit>`: a bit of a RAM variable the code
                            addresses by number (`CP_Flags_A.6 = 1`).
    Lines whose comment is the ASCII column of a hex dump (`0x45, ... /* ETONHYB1..TT_SEP */`,
    as many characters as byte literals) are not scanned.  `Foo_Table[9]` is an index, not an
    elision: the token is looked up whole.
    Not reported: C standard-library macro names (DBL_MAX ...), a CamelCase token that is
    the tail of a defined child label (`BranchSkip` of `Foo_BranchSkip`) or a family prefix
    (`SndParam` of SndParam_*), and prose words in PROSE_CAMEL (`CamelCase`, `GitHub`).  Globs and
    placeholders (`Foo_*`, `Foo_{A,B}`, `LABEL_XXXXXX`, `Foo_N`) are matched as prefixes.

    FALSE POSITIVES  (measured 2026-10-02 on a uniform sample of 50 strong rows after the
    tiers above: 45 true) names of RAM variables that no .equ defines (`ToneDB_RamBankA`),
    sub-block names in comments of C files converted from assembly
    (`SepaOut_LayoutParams_0`), history notes the patterns miss, prose CamelCase not in
    PROSE_CAMEL.  One stale name repeated by a generator counts once per line
    (WaveSel_Bind_PartRecords: ~990 rows in table_data, all true).
    """
    rows = []
    for name, files in tree.files.items():
        for sf in files:
            ctx = sf.context_labels()
            note = tree.shared_note(sf)
            for i, cm in enumerate(sf.comment):
                if not cm:
                    continue
                if hexdump_comment(sf.code[i], cm):
                    continue               # the ASCII column of a hex dump: ROM text
                # the previous line of the same comment block, for history notes that wrap
                prev_cm = sf.comment[i - 1] if i and sf.comment_only(i - 1) else ''
                for tok, mode, start in comment_tokens(cm):
                    core = tok.strip('_')
                    if mode and not symbol_like(core):
                        continue           # 'LABEL_', '_Loop': talk about naming, not a name
                    if not mode and not symbol_like(tok):
                        continue
                    if C_STD_NAME.match(tok):
                        continue
                    if facts.is_defined(tok, mode):
                        continue
                    if re.match(r'-\s*$', cm[start + len(tok):]) and i + 1 < len(sf.comment) \
                            and sf.comment[i + 1]:
                        # wrapped at a hyphen: `NotePool8_Reg00C0_FromPart0-` / `Ctrl91And93`
                        mw = re.match(r'\s*([A-Za-z0-9_]+)', sf.comment[i + 1])
                        if mw and facts.is_defined(tok + mw.group(1), None):
                            continue
                    if mode == 'suffix' and tok.startswith('_') and facts.is_defined(core, None):
                        continue
                    if facts.wildcard_defined(tok):
                        continue
                    if mode is None and '_' not in tok and facts.is_defined('_' + tok, 'suffix'):
                        continue           # a CamelCase fragment of a child label: 'BranchSkip'
                    if mode is None and '_' not in tok and facts.is_defined(tok + '_', 'prefix'):
                        continue           # a family prefix: 'SndParam' of SndParam_*
                    rn = facts.rename_note(tok, mode)
                    kind = 'STALE-RENAMED' if rn else 'STALE'
                    end = start + len(tok)
                    after = cm[end:end + 40]
                    if not rn and (tok in facts.comment_decl or core in facts.comment_decl or
                                   CDECL_NAME.search(cm) and re.search(
                                       r'(?:struct|' + CDECL_TYPES + r')\s+\*?\s*' +
                                       re.escape(tok) + r'\b', cm)):
                        # a field / type the comments declare (`u8 unk_0C;`, `+0x14 SigPtr`)
                        kind = 'WEAK-STALE-FIELD'
                    elif not rn and mode is None and tok.lower() in facts.lower:
                        kind = 'STALE-CASE'
                        rn = 'defined with other letter case as %s' % facts.lower[tok.lower()]
                    if kind.startswith('WEAK'):
                        pass
                    elif HISTORICAL.search((prev_cm + ' ' + cm[:start])[-120:]) or \
                            HISTORICAL_STRONG.search((prev_cm + ' ' + cm[:start])[-200:]) or \
                            HISTORICAL_AFTER.match(after) or alias_in_parens(cm, start, end, facts):
                        kind = 'WEAK-' + kind + '-HISTORICAL'
                    elif not rn and (tok in facts.rom_text or core in facts.rom_text):
                        kind = 'WEAK-STALE-ROMTEXT'
                    elif not rn and kind == 'STALE' and ram_name(cm, start, end, name, images):
                        # `Part_Slot_Sub_Base[1] (0x0413FB)`, `0x229D90  HD_STATUS_FLAG`,
                        # `(ToneDB_RamBankA) + 0x4AA7`: a RAM variable named in prose
                        kind = 'WEAK-STALE-RAMVAR'
                    elif not rn and kind == 'STALE' and re.match(r'\.\d', cm[end:end + 2]):
                        # `CP_Flags_A.6 = 1`: a bit of a RAM variable the code addresses by
                        # number; the name is the comment's own, not a label
                        kind = 'WEAK-STALE-RAMBIT'
                    elif not rn and kind == 'STALE' and mode is None and '_' in tok and \
                            facts.abbrev_of(tok):
                        # 'ClassName_Table' for HDAE5000_ClassName_Table: a prefix left off
                        kind = 'WEAK-STALE-ABBREV'
                        rn = 'abbreviates %s' % facts.abbrev_of(tok)
                    elif not rn and kind == 'STALE' and mode is None and '_' in tok and \
                            facts.numbered_family(tok):
                        # 'ToneNumBank_Melodic' for its rows ToneNumBank_Melodic_0 .. _7
                        kind = 'WEAK-STALE-FAMILY'
                    elif not rn and kind == 'STALE' and mode is None and '_' not in tok and \
                            facts.fragment_of(tok):
                        # 'UserBitmap' of VwUserBitmapProc: a CamelCase part of a defined name
                        kind = 'WEAK-STALE-FRAGMENT'
                    elif not rn and kind == 'STALE' and CAPS_TAG.fullmatch(tok) and \
                            not ADDR_PART.search(tok) and not facts.any_with_prefix(tok + '_'):
                        kind = 'WEAK-STALE-TAG'
                    extra = []
                    if mode:
                        extra.append('elided:%s' % mode)
                    if tok in facts.in_string or core in facts.in_string:
                        extra.append('in-string')
                    detail = '%s %s%s%s%s' % (kind, tok, (' [' + ','.join(extra) + ']') if extra else '',
                                              ('; ' + rn) if rn else '', note)
                    rows.append((name, sf.rel, i + 1, ctx[i], detail))
    return rows


# --- header-addrs -------------------------------------------------------------------------

HA_SEP = (r'(?:\+\s*(?P<off>0x[0-9A-Fa-f]+|\d+)\s*)?'
          r'(?P<sep>\(\s*\+\s*0x[0-9A-Fa-f]+\s*,\s*ROM\s+|\(\s*(?:ROM\s+|at\s+)?|=\s*|\bat\s+|@\s*)'
          r'0x(?P<addr>[0-9A-Fa-f]{4,8})\b')
HA_PAT = re.compile(r'(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*' + HA_SEP)
HA_PLAIN = re.compile(r'(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s+0x(?P<addr>[0-9A-Fa-f]{6})\b(?![0-9A-Fa-f])')
HA_NOT_ADDR = re.compile(r'\s*(?:bytes?\b|B\b|-byte|-entry|entries|words?\b|records?\b|rows?\b|'
                         r'x\s*\d|times\b|items?\b|longs?\b|elements?\b|pointers?\b|slots?\b|chars?\b|'
                         r'characters?\b)', re.I)


def check_header_addrs(tree, images, facts):
    """header-addrs -- is the address a comment quotes for a name where the ELF puts it?

    QUESTION  For every `Name (0xADDR`, `Name = 0xADDR`, `Name at 0xADDR`, `Name @ 0xADDR`,
    `Name+OFF (0xADDR)`, `Name (+0xOFF, ROM 0xADDR)` and (6-digit) `Name 0xADDR` in a comment,
    is ADDR the address of Name in the linked ELF of the image the file belongs to?  v7, v9 and
    v10 are separate links, so a v10 address quoted in the v7 tree is wrong in the v7 tree.

    SIGNAL  The quoted value against llvm-nm of each image that includes the file.  A
    version word on the same comment line ("v10", "v9/v10", "prom_c", ...) lets the quote
    refer to that image instead.  A name not in the file's own image(s) but defined in another
    image is a cross-ROM reference and is checked against that image.  Names defined nowhere
    are stale-names' business and are skipped here.

    HIT  `WRONG-ADDR` -- Name is in this image at another address (the detail gives the delta,
    which symbol this image does have at the quoted address, and `= <image>'s address` when
    the quote is right for a different image: the copy-paste-from-another-version signature).
    Without that signature a quote counts as WRONG-ADDR only when an OBJECT starts at the
    quoted address (some symbol there that is not a local label: `X__n`, `_Skip3`, `_Join`,
    `_Return` ..., or a child `Parent_Tail` of a symbol just before it).  Otherwise it is
    `WEAK-SITE`: the address of an instruction ("calls Foo (0xSITE)", "read by Foo (0xSITE)",
    "Foo at 0xA/0xB/0xC") or of a string a routine is passed ("passes to HDAE5000_DebugTrace
    (ROM 0x2F922C)"); so is a quote followed by `+`, `area`, `region`, `onward` or a range,
    and a `Routine (ROM 0xADDR)` quote of data the routine uses.  `WEAK-CROSS-SITE` and
    `WEAK-ELIDED-SITE` are the same for CROSS-WRONG and ELIDED.  Not a hit at all: the second
    or later name of a list whose first name sits at the address (`FPConst_MaxNorm /
    FPConst_Zero / FPConst_Ln2 at 0x00F420+`, `A and B (0xA)`), a thunk quoted with the
    address it jumps to (`T_DisplayListB_RunOne_Stack (0xF3183D)`: its bytes are `jp
    0xF3183D`), and an elided name whose tail differs from the symbol there only in case.
    `WRONG-VALUE` -- an absolute (.equ) symbol whose value differs.  `CROSS-WRONG` -- a
    cross-ROM name at the wrong address.  `ELIDED` -- '..._11 (0xADDR)' / '_11 (0xADDR)' where
    no symbol ending in the elided tail sits at ADDR.  `WEAK-INSIDE` -- the quoted address lies
    inside Name's own extent (often a deliberately cited instruction, so weak).
    `WRONG-CONTAINER` -- a containment claim ("1 data word in Name (at 0xADDR)", "inside Name
    at 0xADDR") whose ADDR is not inside Name's extent (Name to the next non-child symbol):
    the word sits in another object, which the detail names.  `WEAK-ELIDED-INSIDE` -- an
    elided name whose quoted address falls inside a symbol ending in the elided tail.
    Not checked: call notation `Name(0x7800, 0x72AA)` / `Fn(0x436A - 0x0A)` (no space before
    the parenthesis: arguments), parallel lists `A and B (0xAAAA, 0xBBBB)`, `.equ` values
    against a ROM-range quote (an instruction site: "the load of Var at 0xADDR"), and the
    bare `Name 0xADDR` form outside reader lists (elsewhere it is usually a call-site list).

    FALSE POSITIVES  RAM / work-RAM copies of a ROM object quoted by the ROM object's name; a
    sentence that deliberately quotes an old address without a version word ("moved from");
    a value that is a size, not an address, where the unit word is not adjacent; for shared
    files (wsa1 kernel/, dsp/) the quote need only match one including image.
    """
    rows = []
    for name, files in tree.files.items():
        for sf in files:
            ctx = sf.context_labels()
            own = tree.members[sf.path]
            for i, cm in enumerate(sf.comment):
                if not cm or '0x' not in cm.lower():
                    continue
                vers = [im for rx, im in VERSION_WORDS if rx.search(cm) and im in images]
                seen = set()
                # the bare `Name 0xADDR` form only in reader lists ("readers in v7 (address
                # from the linked ELF): Foo 0x..., Bar 0x..."); elsewhere it is a site list
                ctxt = cm + ' ' + (sf.comment[i - 1] or '' if i else '')
                plain_ok = re.search(r'\breaders?\b|address from the linked ELF', ctxt, re.I)
                for pat in ((HA_PAT, HA_PLAIN) if plain_ok else (HA_PAT,)):
                    for m in pat.finditer(cm):
                        nm = m.group('name')
                        s = m.start('name')
                        if (m.start('addr'), nm) in seen:
                            continue
                        seen.add((m.start('addr'), nm))
                        prev = cm[s - 1] if s else ''
                        if prev and (prev.isalnum() or prev in '_$'):
                            continue
                        elided = any(cm[:s].endswith(x) for x in ELLIPSIS)
                        if prev == '.' and not elided:
                            continue
                        if HA_NOT_ADDR.match(cm, m.end('addr')):
                            continue
                        rest = cm[m.end('addr'):]
                        if pat is HA_PAT and m.group('sep').startswith('('):
                            # call notation `Name(0x7800, 0x72AA)` / `Fn(0x436A - 0x0A)`:
                            # arguments, not an address (a quote reads `Name (0x...)`)
                            # (also `Debug_Print_String(ROM 0x012207 = "\n[")`: an argument)
                            if cm[m.end('name'):m.start('sep')] == '' and \
                                    not re.search(r'\bat\b', m.group('sep')) and \
                                    not re.match(r'\s*,\s*\d+\s*B\b', rest):
                                continue
                            # `A and B (0xAAAA, 0xBBBB)`: a parallel list, not B's address
                            if re.match(r'\s*,\s*0x[0-9A-Fa-f]{4,}', rest):
                                continue
                        q = int(m.group('addr'), 16)
                        off = 0
                        if pat is HA_PAT and m.group('off'):
                            off = num(m.group('off'))
                        # "1 data word in Foo (at 0xADDR)": ADDR is a word INSIDE Foo
                        contain = pat is HA_PAT and (
                            re.match(r'\(\s*at\b', m.group('sep'), re.I) is not None or
                            re.search(r'\b(?:in|inside|within)\s+$', cm[:s]) is not None)
                        prev_cm = sf.comment[i - 1] if i and sf.comment_only(i - 1) else ''
                        if listed_before(prev_cm + ' ' + cm[:s], q, own, images):
                            continue           # `A / B / C at 0xA+`, `A and B (0xA)`: A's address
                        if thunk_to(nm, q, own, images):
                            continue           # `T_Foo (0xF3183D)`: where the thunk jumps
                        r = judge_addr(nm, q, off, elided, own, vers, images, pat is HA_PLAIN,
                                       contain)
                        if r and r.startswith(('WRONG-ADDR', 'CROSS-WRONG')) and \
                                re.match(r'\+|\s*(?:area|region|onwards?|vicinity|and on)\b|'
                                         r'\s*(?:\.\.|-|\u2013)\s*0x', rest):
                            # `0xF420+`, `(0x038DEF area)`, `0xA..0xB`: a place, not a start
                            r = 'WEAK-SITE ' + r.split(' ', 1)[1]
                        if r and r.startswith('WRONG-ADDR') and pat is HA_PAT and \
                                'ROM' in m.group('sep') and ' address' not in r.split(';', 1)[-1]:
                            # `Routine (ROM 0xADDR)`: the ROM data the routine uses or is
                            # passed ("the packet as DSP_WriteAlgoInitPreset (ROM 0x0121F3)")
                            r = 'WEAK-SITE ' + r.split(' ', 1)[1]
                        # `Name (0xV10ADDR / 0xV7ADDR)`: per-version alternatives, any may match
                        alts = re.match(r'(?:\s*/\s*0x[0-9A-Fa-f]{4,8})+', rest)
                        if r and alts:
                            for a in re.findall(r'0x([0-9A-Fa-f]{4,8})', alts.group(0)):
                                if judge_addr(nm, int(a, 16), off, elided, own, vers, images,
                                              False, contain) is None:
                                    r = None
                                    break
                        if r:
                            rows.append((name, sf.rel, i + 1, ctx[i], r + tree.shared_note(sf)))
    return rows


def listed_before(before, q, own, images):
    """True when the quoted name is the 2nd+ item of a list whose first item sits at q:
    `FPConst_MaxNorm / FPConst_Zero / FPConst_Ln2 at 0x00F420+`, `A and B (0xA)`."""
    t = before
    for _ in range(4):
        mo = re.search(r'([A-Za-z_]\w*)`?\s*(?:/|,|\band\b|\bor\b|&)\s*`?$', t)
        if not mo:
            return False
        nm = mo.group(1)
        for imn in own:
            im = images.get(imn)
            if im is not None and nm in im.sym and im.sym[nm][0] == q:
                return True
        t = t[:mo.start()]
    return False


def thunk_to(nm, q, own, images):
    """True when nm is a thunk whose first instruction is `jp q` (1B q0 q1 q2 for a 24-bit
    target, 1A q0 q1 for a 16-bit one) or `jrl q` -- 'T_Foo (0xADDR)' quotes where the
    thunk goes."""
    for imn in own:
        im = images.get(imn)
        if im is None or nm not in im.sym:
            continue
        a = im.sym[nm][0]
        o = a - im.base
        if 0 <= o and o + 4 <= len(im.bytes):
            b = im.bytes
            if b[o] == 0x1B and (b[o + 1] | b[o + 2] << 8 | b[o + 3] << 16) == q:
                return True
            if b[o] == 0x1A and (b[o + 1] | b[o + 2] << 8) == q:
                return True
            if b[o] == 0x78 and o + 3 <= len(b):
                d = b[o + 1] | b[o + 2] << 8
                if (a + 3 + (d - 0x10000 if d & 0x8000 else d)) & 0xFFFFFF == q:
                    return True
    return False


LOCAL_LABEL = re.compile(r'__|_(?:Skip|Join|Loop|Return|Ret|Done|Exit|Next|Resume|Epilogue|Body|'
                         r'Tail|Cont|Continue|Default|End|Common|Wait|Retry|Again|Out|Fail|'
                         r'Entry|L)\d*$')


def site_address(im, q):
    """True when Q is not the start of an object in im: no symbol there, or only local
    labels (`X__suffix`, `_Skip3`, `_Join`, `_Return` ..., or a child `Parent_Tail` of a
    symbol just before it) -- the address of an instruction inside some routine."""
    names = im.addr_names.get(q, [])
    if not names:
        return True
    k = bisect.bisect_left(im.text_addrs, q)
    parents = set()
    j = k - 1
    while j >= 0 and q - im.text_addrs[j] < 0x2000 and len(parents) < 64:
        parents.update(im.addr_names[im.text_addrs[j]])
        j -= 1
    return all(LOCAL_LABEL.search(n) or any(n.startswith(p + '_') for p in parents)
               for n in names)


def judge_addr(nm, q, off, elided, own, vers, images, plain, contain=False):
    defined_in = [im for im in images.values() if nm in im.sym]
    if (elided or nm.startswith('_')) and not defined_in:
        tail = nm
        if len(tail.strip('_')) < 2:
            return None
        core = tail.lstrip('_')
        for imn in own:
            im = images.get(imn)
            if im is None:
                continue
            if any(n.lower().endswith(core.lower()) for n in im.addr_names.get(q, [])):
                return None                # ('_VARIANT_2' for Audio_PlayNote_Variant_2: the
                                           # case is stale-names' business, the address is right)
        for imn in own:                    # Q inside a symbol whose name ends in the tail
            im = images.get(imn)
            if im is None or not (im.base <= q < im.end):
                continue
            k = bisect.bisect_right(im.text_addrs, q) - 1
            while k >= 0 and q - im.text_addrs[k] < 0x1000:
                a = im.text_addrs[k]
                hit = [n for n in im.addr_names[a] if n.endswith(core)]
                if hit and q < im.next_text_addr(a, skip_prefix=hit[0]):
                    return 'WEAK-ELIDED-INSIDE %s quoted 0x%X is inside %s [0x%X,0x%X)' % (
                        nm, q, hit[0], a, im.next_text_addr(a, skip_prefix=hit[0]))
                k -= 1
        there = []
        for imn in own:
            im = images.get(imn)
            if im is not None and im.base <= q < im.end:
                there += im.addr_names.get(q, [])
        if not any(im.base <= q < im.end for im in (images.get(x) for x in own) if im):
            return None
        if not there:
            # no symbol starts at Q: an instruction / site address, which the elided name
            # need not label ("..._CD (0xFADD0A)")
            return 'WEAK-ELIDED-SITE %s quoted 0x%X: no symbol starts there' % (
                ('...' if elided else '') + nm, q)
        return 'ELIDED %s quoted 0x%X: no symbol ending in %s there%s' % (
            ('...' if elided else '') + nm, q, tail,
            ('; at 0x%X: %s' % (q, ','.join(sorted(there)[:3]))) if there else '')
    if not defined_in:
        return None
    if plain and not symbol_like(nm, 4):
        return None
    if not plain and not (symbol_like(nm, 4) or re.search(r'[_0-9]', nm)):
        return None
    ok_images = [im.name for im in defined_in if im.sym[nm][0] + off == q]
    owned = [images[x] for x in own if x in images and nm in images[x].sym]
    if owned:
        if any(im.name in ok_images for im in owned):
            return None
        if any(v in ok_images for v in vers):
            return None
        im = owned[0]
        a, t = im.sym[nm]
        if t in 'aA' and not (im.base <= a < im.end):
            # a value, not an address; `the load of Var at 0xROM` cites an instruction site
            if plain or contain or (im.base <= q < im.end):
                return None
            return 'WRONG-VALUE %s quoted 0x%X, %s value 0x%X' % (nm, q, im.name, a)
        if not any(x.base <= q < x.end for x in owned):
            return None                   # another address space (RAM copy, I/O)
        nxt = im.next_text_addr(a, skip_prefix=nm)
        # (a quote that is exactly another image's address for the name is the copy-paste
        # signature even when it happens to fall inside this image's object)
        if a + off < q < nxt and not [x for x in ok_images if x != im.name]:
            if contain:
                return None
            return 'WEAK-INSIDE %s quoted 0x%X is inside %s [0x%X,0x%X)' % (
                nm, q, nm, a, nxt)
        if contain:
            k = bisect.bisect_right(im.text_addrs, q) - 1
            holder = ','.join(sorted(im.addr_names[im.text_addrs[k]])[:2]) if k >= 0 else '?'
            return 'WRONG-CONTAINER %s (at 0x%X): %s is [0x%X,0x%X) in %s; 0x%X lies in %s' % (
                nm, q, nm, a, nxt, im.name, q, holder)
        there = im.addr_names.get(q, [])
        others = [x for x in ok_images if x != im.name]
        if not others and site_address(im, q):
            # Q is no object's start: a call / read / branch SITE ("calls Foo (0xSITE)",
            # "read by Foo (0xSITE)", "Foo at 0xA/0xB/0xC"), or a string the call passes
            return 'WEAK-SITE %s%s quoted 0x%X, %s ELF 0x%X (delta %+d)%s' % (
                nm, ('+0x%X' % off) if off else '', q, im.name, a + off, q - (a + off),
                ('; %s has %s there' % (im.name, ','.join(sorted(there)[:3]))) if there else '')
        return 'WRONG-ADDR %s%s quoted 0x%X, %s ELF 0x%X (delta %+d)%s%s' % (
            nm, ('+0x%X' % off) if off else '', q, im.name, a + off, q - (a + off),
            ('; = %s address' % '/'.join(others)) if others else '',
            ('; %s has %s there' % (im.name, ','.join(sorted(there)[:3]))) if there else '')
    # cross-ROM reference
    if ok_images:
        return None
    tx = [im for im in defined_in if im.sym[nm][1] in 'tT' and im.base <= q < im.end]
    if not tx:
        return None
    if all(site_address(im, q) for im in tx):
        return 'WEAK-CROSS-SITE %s quoted 0x%X (no object starts there); %s' % (
            nm, q, ', '.join('%s 0x%X' % (im.name, im.sym[nm][0]) for im in defined_in[:4]))
    return 'CROSS-WRONG %s quoted 0x%X; %s' % (
        nm, q, ', '.join('%s 0x%X' % (im.name, im.sym[nm][0]) for im in defined_in[:4]))


# --- unread-claims ------------------------------------------------------------------------

NOREADER = re.compile(
    # 'no reader' only as an existence claim: "no reader found", "No reader.", "no reader of
    # it", not "no reader treats these as data" / "no reader indexes it by category"
    r'no readers?(?=\s*(?:[.;:,)\-]|$|found|of\b|for\b|in\b|anywhere|exists?\b|was\b|has\b|'
    r'at all|by name|is known|known|here|could|can be|reaches|either))'
    r'(?!(?:\s+[\w/]+){0,3}\s+(?:bounds?|treats?|index(?:es)?|uses?|ties|masks?|clamps?|checks?|'
    r'tests?|scales?|interprets?|distinguishes|needs?|cares?|depends?|relies|supplies|says|'
    r'gives|tells|explains|names|establishes|decides|fixes|shows|proves|knows|states|'
    r'identifies|confirms|settles)\b)|'
    r'unreferenced|\bnot referenced|'
    r'no code reference|no reference (?:was )?found|nothing (?:reads|references) (?:it|this|them)|'
    r'no registration or code reference|reader (?:is )?(?:not established|unknown)|'
    r'no known reader|no xref', re.I)
PURPOSE = re.compile(r'purpose (?:is )?not (?:yet )?established|purpose unknown', re.I)
POSITIVE_READER = re.compile(
    r'\bReaders?\s*:|readers below|\bread by\b|\bcopied by\b|\bloaded by\b|\breferenced by\b|'
    r'\breader is\b|\breaders are\b|\breached from\b|\bdispatched by\b|\bcalled by\b|'
    r'\breads? (?:it|this|them)\b', re.I)
RETRACTION = re.compile(r'previously|was marked|formerly|wrongly|incorrectly|corrected|'
                        r'used to (?:say|claim)|no longer|\bconcluded\b|\bwrong\b|'
                        r'\bwas not\b|\bnot asserted\b', re.I)
NAME_CLAIM = re.compile(r'^(?:NoRef|Unref|Unreferenced|NoReader)_')
# a claim about one field / offset / bit of an object, not about the object
FIELD_LEVEL = re.compile(r'\+\s*0x[0-9A-Fa-f]+|\+\d+\b|\bfields?\b|\bbits?\s+\d|\bbyte\s+\d|'
                         r'\bentr(?:y|ies)\s+\d|\barg(?:ument)?s?\b|\bparameters?\b|'
                         # an ordinal part: "the second 0x0E is the unreferenced one"
                         r'\b(?:second|third|fourth|last|trailing|final|remaining)\b|'
                         r'\b(?:length|count|flag|mode|status|index|selector|tag|type|size|id|'
                         r'high|low)\s+(?:byte|word|half|nibble|field|bits?)\b', re.I)
# "NO READER OF W": a one-letter field of the records
FIELD_LETTER = re.compile(r'\b[Oo][Ff]\s+[A-Z]\b(?![\'\w])')
# a claim whose subject is a file ("...SeqResetTable.bin, now unreferenced")
FILE_SUBJECT = re.compile(r'[\w./-]+\.(?:bin|s|c|h|py|asm|inc|md|txt|map|sed|tsv|json)\b')
# "an UNREFERENCED sync-injection block (see below)": a part of the object, introduced
SUBPART_VERB = re.compile(r'\b(?:skips?|inside|within|below|after|before|contains?|holds?|'
                          r'includes?|embeds?|ahead of|in front of)\b', re.I)
# a ROM pointer that only bounds a record list: `ld XIY, start` (45 imm32) directly followed by
# `ld XIX, end` (44 imm32) -- the exclusive end of the list before it, not a reader
LD_XIY_SRC = re.compile(r'^\s*(?:[A-Za-z_]\w*:)?\s*ld\s+xiy\s*,\s*[A-Za-z_0-9]', re.I)
LD_XIX_DST = re.compile(r'^\s*(?:[A-Za-z_]\w*:)?\s*ld\s+xix\s*,\s*[A-Za-z_0-9]', re.I)
DATA32_LINE = re.compile(r'^\s*\.(?:long|4byte|int|word32)\b', re.I)
JUMP_LINE = re.compile(r'^\s*(?:jp|jr|jrl|call|calr|djnz)\b', re.I)


def sentence_spans(txt):
    out, start = [], 0
    for m in re.finditer(r'(?<=[.;?!])\s+', txt):
        out.append((start, m.start()))
        start = m.end()
    out.append((start, len(txt)))
    return out


def text_range(t, im, near=None):
    """(lo, hi) from '(0xADDR, N B)' or '0xLO..0xHI' in t, if inside the image, else None.
    With several, the one nearest to position `near` (the claim word) wins."""
    cands = []
    for rs in RANGE_SIZE.finditer(t):
        lo = int(rs.group(1), 16)
        if im.base <= lo < im.end:
            cands.append((rs.start(), lo, lo + int(rs.group(2))))
    for rd in RANGE_DOTS.finditer(t):
        lo, hi = int(rd.group(1), 16), int(rd.group(2), 16)
        if im.base <= lo < im.end and hi >= lo:
            cands.append((rd.start(), lo, hi + 1))
    if not cands:
        return None
    if near is None:
        return cands[0][1:]
    after = sorted(c for c in cands if 0 <= c[0] - near <= 60)
    if after:                        # "the unreferenced residue after the grid (0xLO-0xHI)"
        return after[0][1:]
    return min(cands, key=lambda c: abs(c[0] - near))[1:]
RANGE_SIZE = re.compile(r'\(?\b0x([0-9A-Fa-f]{4,8}),\s*(\d+)\s*B\b')
RANGE_DOTS = re.compile(r'\b0x([0-9A-Fa-f]{4,8})\s*(?:\.\.|-|\u2013)\s*0x([0-9A-Fa-f]{4,8})\b')
INCBIN = re.compile(r'\.incbin\s+"[^"]+"\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)')
NUMERIC = re.compile(r'(?<![\w$])(0x[0-9A-Fa-f]{5,8}|\d{6,10})(?![\w$])')
LDIR = re.compile(r'^\s*(?:[A-Za-z_]\w*:)?\s*(ldirw?|lddrw?)\b', re.I)
LD_REG_SYM = re.compile(r'^\s*(?:[A-Za-z_]\w*:)?\s*(?:ld|lda|ldl)\s+(xiy|xhl|xix|xde)\s*,\s*'
                        r'(?:\()?\s*([A-Za-z_][\w]*|0x[0-9A-Fa-f]+|\d+)\s*'
                        r'(?:\+\s*(0x[0-9A-Fa-f]+|\d+))?\s*(?::24)?\s*\)?\s*$', re.I)
LD_BC = re.compile(r'^\s*(?:[A-Za-z_]\w*:)?\s*ldw?\s+bc\s*,\s*(0x[0-9A-Fa-f]+|\d+)(?::i\d+)?\s*$', re.I)


class SrcRefIndex:
    """Per image (and its bus peers): where each identifier is used in code, numeric
    ROM-range immediates, and the source spans of ld/ldir block copies."""

    def __init__(self, tree, images):
        self.tree, self.images = tree, images
        self._tok = {}
        self._num = {}
        self._copy = {}

    def tokens(self, imn):
        if imn not in self._tok:
            idx = collections.defaultdict(list)
            nums = []
            for sf in self.tree.all_files.get(imn, []):
                prev = ''
                last_body = ''
                for i, c in enumerate(sf.code):
                    if not c.strip():
                        continue
                    ld = LABEL_DEF.match(c)
                    if ld:
                        prev = ld.group(1)
                    body = c[ld.end():] if ld else c
                    # what kind of use: a 32-bit data word (the ROM-pointer scan sees it too),
                    # a branch, the END bound of a `ld xiy, start / ld xix, end` pair, or other
                    kind = 'code'
                    if sf.kind == 's' and body.strip():
                        if DATA32_LINE.match(body):
                            kind = 'data32'
                        elif JUMP_LINE.match(body):
                            kind = 'jump'
                        elif LD_XIX_DST.match(body) and LD_XIY_SRC.match(last_body):
                            kind = 'endbound'
                        last_body = body
                    if sf.kind == 's':
                        body = re.sub(r'"(?:[^"\\]|\\.)*"', '""', body)
                        # alias definitions and symbol bookkeeping are not readers
                        if re.match(r'\s*\.(?:set|equ|equiv|eqv|globl|global|type|size|weak|'
                                    r'local|hidden)\b', body, re.I):
                            continue
                    else:
                        # C: a declaration (`extern const char Foo;`, `char Foo[6];`) or a
                        # member name (`.Foo = ...`, `x.Foo`) is not a reference
                        st = body.strip()
                        if st.endswith(';') and '=' not in st and '(' not in st:
                            continue
                        body = re.sub(r'(?:\.|->)\s*[A-Za-z_]\w*', ' ', body)
                    for t in set(IDENT.findall(body)):
                        idx[t].append((sf.rel, i + 1, prev, kind))
                    if sf.kind == 's':
                        for n in NUMERIC.findall(body):
                            nums.append((num(n), sf.rel, i + 1, prev, kind))
            nums.sort()
            self._tok[imn] = idx
            self._num[imn] = nums
        return self._tok[imn], self._num[imn]

    def copies(self, imn):
        """[(src_lo, src_hi, file, line, text)] for ld xiy/xhl, X / ld bc, N / ldir[w]."""
        if imn not in self._copy:
            im = self.images[imn]
            out = []
            for sf in self.tree.all_files.get(imn, []):
                if sf.kind != 's':
                    continue
                code = sf.code
                for i, c in enumerate(code):
                    m = LDIR.match(c)
                    if not m:
                        continue
                    op = m.group(1).lower()
                    src = cnt = None
                    j, steps = i - 1, 0
                    while j >= 0 and steps < 8:
                        cj = code[j]
                        if not cj.strip():
                            j -= 1
                            continue
                        if LABEL_DEF.match(cj) and not cj[LABEL_DEF.match(cj).end():].strip():
                            break
                        steps += 1
                        if cnt is None:
                            mb = LD_BC.match(cj)
                            if mb:
                                cnt = num(mb.group(1))
                        ms = LD_REG_SYM.match(cj)
                        if ms and ms.group(1).lower() in ('xiy', 'xhl') and src is None:
                            v = ms.group(2)
                            base = im.sym[v][0] if v in im.sym else \
                                (num(v) if re.match(r'0x|\d', v) else None)
                            if base is not None:
                                src = base + (num(ms.group(3)) if ms.group(3) else 0)
                        if re.match(r'^\s*(?:ret|jp|jr|jrl|call|calr|reti)\b', cj):
                            break
                        j -= 1
                    if src is not None and cnt:
                        n = cnt * (2 if op.endswith('w') else 1)
                        if op.startswith('ldd'):
                            lo, hi = src - n + (2 if op.endswith('w') else 1), src + 1
                        else:
                            lo, hi = src, src + n
                        if im.base <= lo < im.end:
                            out.append((lo, hi, sf.rel, i + 1, '%s bc=%d from 0x%X' % (op, cnt, src)))
            self._copy[imn] = out
        return self._copy[imn]


def claim_blocks(sf):
    """Yield (first_line, last_line, text, target_line) for each run of comment-only lines;
    target_line is the next line with code (None at EOF)."""
    n = len(sf.raw)
    i = 0
    while i < n:
        if sf.comment_only(i):
            j = i
            while j + 1 < n and sf.comment_only(j + 1):
                j += 1
            t = j + 1
            while t < n and not sf.raw[t].strip():
                t += 1
            yield i, j, [sf.comment[k] for k in range(i, j + 1)], (t if t < n else None)
            i = j + 1
        else:
            i += 1


def check_unread_claims(tree, images, facts, srcidx=None):
    """unread-claims -- does anything read what a header says nothing reads?

    QUESTION  For every object whose header claims it is not read -- "no reader found",
    "No reader", "unreferenced", "no code reference reaches", "nothing reads it", "no
    registration or code reference", "reader not established" -- or whose name says so
    (NoRef_*, Unref_*), and for every "purpose not established" header that does not list
    readers: is there in fact a reader?  "no reader" counts only as an existence claim ("no
    reader found", "No reader.", "no reader in the ROM"), not "no reader treats these as data"
    / "no reader in prom_a bounds it" / "no reader in the image supplies one".  Skipped as not
    a claim about the object (claim_not_about_object): a sentence about a field, offset,
    argument or ordinal part ("+0x11 has NO reader", "NO READER OF W", "the second 0x0E is
    the unreferenced one", "the second argument slot ... nothing reads it"); a retracted or
    attributed one ("previously", "corrected", "concluded", "wrong"); a quoted phrase; one
    about a file ("...ResetTable.bin, now unreferenced"); one whose sentence quotes only
    addresses outside the image and its bus peers (RAM); an indefinite "an UNREFERENCED X
    block (see below)" that introduces a part.  When the claim's clause names its own subject
    ("BootSerial_Call_PollTX thunk (itself unreferenced)", "no reader of Foo") that symbol is
    checked instead of the label.

    SIGNAL  The object's range: the label the header precedes, from its ELF address to the next
    ELF symbol that is not its own child (`Label_*`), cut short by a range the header states
    for that address ("0xF96E86-0xF96E89 -- 3 B"); but a table row on the claim's own line
    ("0xF89E34  128  ..., NOTHING REFERENCES IT") or a range the claim's sentence states
    wins, and so does one other address in the sentence when it lies INSIDE the labeled
    object (a slice of it).  A range or single address in the sentence that lies OUTSIDE the
    labeled object ("in front of 0xFB0E4F", "its default, 0xF95D19, lies INSIDE ...") leaves
    the subject undecidable: the claim is skipped and counted as unresolved.  For unlabeled
    slices: the one or two addresses on the claim's own line, else the previous sentence's
    range.  Then, over the image and the
    images on its bus (maincpu + table/custom data + HDAE5000; v142 + sub-boot; WSA1 A + B):
      ptr32  an LE24 pointer with a 0x00 high byte into the range (SELF = from inside the range
             itself, which still means the blob is walked through its own pointers);
      push   `pushw hi / pushw lo` pairs (0b hh 00 0b ll mm) forming an address in range;
      srcref a use, in code (not comments, not the label's own definition), of any symbol
             defined inside the range, in any source of the image or its peers (C included);
      numref a numeric ROM-range immediate in code that falls inside the range;
      copy   a block copy `ld xiy|xhl, X(+k) / ld[w] bc, N / ldir[w]` whose source span
             [X, X+N*width) overlaps the range -- in particular one that starts in the object
             before and runs past the next label into this one.
    The ROM-pointer signals are off for images linked below 0x100000 (v142, prom_d), where an
    in-range 32-bit value is an ordinary small number.

    srcref ignores declarations (`extern ...;`, `char Foo[6];`), C member names (`.Foo =`),
    .set/.equ/.globl/.type lines, uses from lines whose enclosing label lies inside the
    range (internal branches, self-pointers), and -- where the ptr32 scan is on -- `.long X`
    data words, which the ptr32 count already holds.
    Not counted at all: references from a place the claim block itself names (a symbol or
    0xADDR it mentions: "arm 0 of the jump table at 0xFAE802", "the two entry stubs below jump
    here", "copied by ParamPopup_PartTuning (0xEFFA59)" -- the header knows that reference, so
    its claim is about something else), shown as "N more from places the header itself
    names"; and the END bound of a record list, `ld xiy, start / ld xix, <this>` (bytes 45
    imm32 44 imm32 with start < this), which bounds the list before the object and reads
    nothing in it.  SELF pointers are shown but never make a hit strong.

    HIT  `READ-DESPITE-CLAIM` (a no-reader claim or a NoRef_/Unref_ name) or
    `WEAK-PURPOSE-HAS-READER` (a bare "purpose not established" that some reader would let one
    establish) with the signal counts and the first sites.  `WEAK-INTERIOR-...` -- the only
    evidence is 32-bit values pointing INTO the range at no symbol (possibly coincidental
    data bytes; still worth a look when several hit the same address), SELF pointers, or --
    for a range taken from the ELF rather than stated in the text -- a numeric branch
    (`jp 0xFAE84C`) into its interior at no symbol: an entry point the ELF extent swallowed.

    FALSE POSITIVES  a ptr32 that is coincidental data (likeliest in large blobs and tiny
    ranges; the SELF count is shown separately); a claim scoped narrower than the range found
    ("no CODE reference" over a table reached only by a data pointer, which the detail lets you
    see; "the second 0x0E is unreferenced" under a label whose first byte is read; a routine
    reached only through a jump table that is itself unread); claims on unlabeled slices
    whose range text the header does not state are skipped (counted as unresolved in the
    summary line).
    """
    srcidx = srcidx or SrcRefIndex(tree, images)
    rows = []
    unresolved = collections.Counter()
    for name, files in tree.files.items():
        im = images[name]
        for sf in files:
            if sf.kind != 's':
                continue
            claimed_labels = set()
            for first, last, texts, tgt in claim_blocks(sf):
                txt = ' '.join(texts)
                if not (NOREADER.search(txt) or PURPOSE.search(txt)):
                    continue
                spans = sentence_spans(txt)
                claim = None
                for rx, kind in ((NOREADER, 'READ-DESPITE-CLAIM'), (PURPOSE, 'WEAK-PURPOSE-HAS-READER')):
                    for m in rx.finditer(txt):
                        si = next(k for k, (a, b) in enumerate(spans) if a <= m.start() <= b)
                        sent = txt[spans[si][0]:spans[si][1]]
                        if claim_not_about_object(txt, m, spans, si, sent, im, images):
                            continue
                        if rx is PURPOSE and POSITIVE_READER.search(txt):
                            continue
                        claim = (m, kind, si, sent)
                        break
                    if claim:
                        break
                if not claim:
                    continue
                m, kind, si, sent = claim
                rel_m = m.start() - spans[si][0]
                prev_sent = txt[spans[si - 1][0]:spans[si - 1][1]] if si else ''
                pos = 0
                claim_line = first + 1
                for k, t in enumerate(texts):
                    if pos + len(t) >= m.start():
                        claim_line = first + k + 1
                        break
                    pos += len(t) + 1
                line_txt = texts[claim_line - first - 1] or ''
                lo = hi = None
                label = own = ''
                explicit = False
                if tgt is not None:
                    lm = LABEL_DEF.match(sf.code[tgt])
                    if lm and lm.group(1) in im.sym and im.sym[lm.group(1)][1] in 'tT':
                        label = own = lm.group(1)
                        lo = im.sym[label][0]
                        hi = im.next_text_addr(lo, skip_prefix=label)
                        ib = INCBIN.search(sf.code[tgt][lm.end():] or
                                           (sf.code[tgt + 1] if tgt + 1 < len(sf.code) else ''))
                        if ib and lo + num(ib.group(2)) > hi:
                            hi = lo + num(ib.group(2))
                        claimed_labels.add(label)
                subj = claim_subject(sent, rel_m, m, label, im, facts)
                in_img = lambda x: im.base <= x < im.end
                # the claim's own sentence decides when it names a range or one other address
                r = text_range(sent, im, rel_m)
                addrs = {int(x, 16) for x in re.findall(r'\b0x([0-9A-Fa-f]{4,8})\b', sent)}
                addrs = {x for x in addrs if in_img(x)}
                line_addrs = {int(x, 16) for x in re.findall(r'\b0x([0-9A-Fa-f]{4,8})\b', line_txt)}
                line_addrs = {x for x in line_addrs if in_img(x)}
                row = re.search(r'\b0x([0-9A-Fa-f]{4,8})\s+(\d+)\s', line_txt)
                if subj:
                    # "Foo thunk (itself unreferenced)", "no reader of Foo": the claim is Foo's
                    label = subj + '(subject)'
                    lo = im.sym[subj][0]
                    hi = im.next_text_addr(lo, skip_prefix=subj)
                elif subj is None:
                    unresolved[name] += 1
                    continue
                elif row and len(line_addrs) == 1 and in_img(int(row.group(1), 16)):
                    # a table row on the claim's own line: "0xF89E34  128  ..., NOTHING REFERENCES IT"
                    lo = int(row.group(1), 16)
                    hi = lo + int(row.group(2))
                    explicit = True
                    label = '@0x%X' % lo
                elif r and r[0] != lo:
                    if own and not (lo <= r[0] < hi):
                        unresolved[name] += 1   # a range of another object, not the label's
                        continue
                    lo, hi = r
                    explicit = True
                    label = (label + '@' if label else '@') + '0x%X' % lo
                elif not r and len(addrs) == 1 and lo not in addrs:
                    a = addrs.pop()
                    if lo is not None and lo < a < hi:
                        lo = a                  # a slice of the labeled object
                        explicit = True
                    elif lo is None:
                        lo, hi = a, im.next_text_addr(a)
                    else:
                        # the sentence quotes another object's address ("in front of
                        # 0xFB0E4F", "its default, 0xF95D19, lies INSIDE ..."): which one the
                        # claim is about is not decidable from the text
                        unresolved[name] += 1
                        continue
                    label = (label + '@' if label else '@') + '0x%X' % lo
                elif lo is None and texts[claim_line - first - 1] is not None and \
                        len(line_addrs) in (1, 2):
                    # an unlabeled list line "Foo (0xA) / Bar (0xB)  unreferenced stubs"
                    xs = sorted(line_addrs)
                    lo, hi = xs[0], im.next_text_addr(xs[-1])
                    label = '@0x%X' % lo
                elif lo is None:
                    r = text_range(prev_sent, im)
                    if r is None:
                        allr = [x for x in (RANGE_SIZE.findall(txt) + RANGE_DOTS.findall(txt))]
                        if len(allr) == 1:
                            r = text_range(txt, im)
                    if r:
                        lo, hi = r
                        explicit = True
                        label = '@0x%X' % lo
                if lo is None or hi <= lo:
                    unresolved[name] += 1
                    continue
                if own and not explicit and label == own:
                    # the header's own range for the label ("0xF96E86-0xF96E89 -- 3 B")
                    # bounds the object more tightly than the next ELF symbol does
                    for (a0, b0) in all_text_ranges(txt, im):
                        if a0 == lo and lo < b0 < hi:
                            hi = b0
                            explicit = True
                ack = acknowledged(txt, own or label, lo, hi, im, images, facts)
                det, strong = reader_signals(im, lo, hi, srcidx, images, sf.rel, tgt,
                                             explicit, ack)
                if det:
                    k = kind if (strong or kind.startswith('WEAK')) else 'WEAK-INTERIOR-' + kind
                    rows.append((name, sf.rel, claim_line, label,
                                 '%s "%s" [0x%X,0x%X) %d B: %s%s' % (k, m.group(0), lo, hi, hi - lo,
                                                                    det, tree.shared_note(sf))))
            # name claims with no header claim
            for li, lab in sf.labels():
                if NAME_CLAIM.match(lab) and lab not in claimed_labels and lab in im.sym:
                    lo = im.sym[lab][0]
                    hi = im.next_text_addr(lo, skip_prefix=lab)
                    det, strong = reader_signals(im, lo, hi, srcidx, images, sf.rel, li)
                    if det:
                        rows.append((name, sf.rel, li + 1, lab,
                                     '%s name "%s" [0x%X,0x%X) %d B: %s%s' % (
                                         'READ-DESPITE-CLAIM' if strong else
                                         'WEAK-INTERIOR-READ-DESPITE-CLAIM',
                                         lab, lo, hi, hi - lo, det, tree.shared_note(sf))))
    check_unread_claims.unresolved = unresolved
    return rows


def claim_not_about_object(txt, m, spans, si, sent, im, images):
    """True when a matched no-reader phrase is not a claim that the object is unread: it is
    quoted ("NO READER HAS NOW BEEN WRONG ..."), retracted or attributed ("concluded",
    "corrected"), about a field / argument / ordinal part ("the second 0x0E", "the second
    argument slot ... nothing reads it", "NO READER OF W"), about a file ("....bin, now
    unreferenced"), about RAM (every address the sentence quotes is outside the image and its
    bus peers), or an indefinite "an unreferenced X block" that introduces a part."""
    rel = m.start() - spans[si][0]
    if txt[:m.start()].count('"') % 2 == 1:
        return True
    if RETRACTION.search(txt[max(0, m.start() - 80):m.end() + 40]):
        return True
    if FIELD_LEVEL.search(sent) or FIELD_LETTER.search(sent):
        return True
    if re.search(r'\b(?:it|this|them|these)\b', m.group(0), re.I) and si and \
            FIELD_LEVEL.search(txt[spans[si - 1][0]:spans[si - 1][1]]):
        return True                    # "nothing reads it": 'it' is the field named before
    before = sent[:rel]
    k = before.rfind('(')
    clause = before[k + 1:] if k > before.rfind(')') else before
    if FILE_SUBJECT.search(clause[-80:]):
        return True
    if k > before.rfind(')') and re.search(FILE_SUBJECT.pattern + r'\W{0,3}$', before[:k]):
        return True                    # "...SeqStep_ByteBlockEA5F.bin (now unreferenced)"
    space = [im] + [images[p] for p in im.peers if p in images]
    xs = [int(x, 16) for x in re.findall(r'\b0x([0-9A-Fa-f]{5,8})\b', sent)]
    if xs and not any(o.base <= x < o.end for o in space for x in xs):
        return True
    if re.search(r'\ban?\s+$', before, re.I) and m.group(0).lower().startswith('unreferenced') and \
            SUBPART_VERB.search(sent):
        return True
    return False


def claim_subject(sent, rel, m, label, im, facts):
    """The text symbol a claim is about when its own clause names one other than the label:
    "BootSerial_Call_PollTX thunk (itself unreferenced, ...)", "no reader of Foo_Table".
    Returns that name, '' when the clause names nobody else, None when the subject is
    'itself' of something that is not a symbol here."""
    def ok(n):
        return n and n != label and not n.startswith(label + '_') and n in im.sym and \
            im.sym[n][1] in 'tT' and symbol_like(n, 4)
    mo = re.match(r'\s*(?:of|for)\s+`?([A-Za-z_]\w*)', sent[rel + len(m.group(0)):])
    if mo and ok(mo.group(1)):
        return mo.group(1)
    before = sent[:rel]
    k = before.rfind('(')
    in_paren = k > before.rfind(')')
    itself = re.search(r'\bitself\b', before[k + 1:] if in_paren else before[-40:], re.I)
    if in_paren:
        mo = re.search(r'([A-Za-z_]\w*)(?:\s+(?:thunk|stub|veneer|table|routine|entry|slot))?\s*$',
                       before[:k])
        if mo and ok(mo.group(1)):
            return mo.group(1)
        if itself:
            return None
    elif itself:
        mo = re.search(r'([A-Za-z_]\w*)[^A-Za-z_]{0,30}$', before[:itself.start()])
        if mo and ok(mo.group(1)):
            return mo.group(1)
        return None
    return ''


def all_text_ranges(t, im):
    out = []
    for rs in RANGE_SIZE.finditer(t):
        lo = int(rs.group(1), 16)
        if im.base <= lo < im.end:
            out.append((lo, lo + int(rs.group(2))))
    for rd in RANGE_DOTS.finditer(t):
        lo, hi = int(rd.group(1), 16), int(rd.group(2), 16)
        if im.base <= lo < im.end and hi >= lo:
            out.append((lo, hi + 1))
    return out


def acknowledged(txt, label, lo, hi, im, images, facts):
    """(names, addresses) the claim block itself mentions: a reference from inside one of
    those is one the header already knows about ("arm 0 of the jump table at 0xFAE802",
    "the two entry stubs below jump here", "copied by ParamPopup_PartTuning (0xEFFA59)"), so
    the claim is about something else and that reference does not contradict it."""
    names = {x for x in IDENT.findall(txt) if x != label and not x.startswith(label + '_')
             and symbol_like(x, 4) and x in facts.defined}
    addrs = {int(x, 16) for x in re.findall(r'\b0x([0-9A-Fa-f]{4,8})\b', txt)}
    addrs = {x for x in addrs if not (lo <= x < hi)}
    return names, addrs


def reader_signals(im, lo, hi, srcidx, images, rel, tgt, explicit=False, ack=None):
    """(detail, strong) -- every reader signal for [lo, hi).  strong is False when the only
    evidence is 32-bit values pointing INTO the range at no symbol (possibly coincidental
    data bytes), pointers from inside the range itself (SELF), or -- for a range taken from
    the ELF rather than stated in the text -- branches into its interior at no symbol (another
    entry point the extent swallowed).  References from places the claim block itself names
    (`ack`) and END bounds of a `ld xiy, start / ld xix, end` pair are not counted."""
    parts = []
    strong = False
    scan = [im] + [images[p] for p in im.peers if p in images]
    starts = set(im.text_addrs[bisect.bisect_left(im.text_addrs, lo):
                               bisect.bisect_left(im.text_addrs, hi)]) | {lo}
    ack_names, ack_addrs = ack if ack else (set(), set())
    ack_spans = []
    for src in scan:
        for n in ack_names:
            if n in src.sym and src.sym[n][1] in 'tT':
                a = src.sym[n][0]
                if not (lo <= a < hi) and src.base <= a < src.end:
                    ack_spans.append((a, src.next_text_addr(a, skip_prefix=n)))
        for q in ack_addrs:
            if src.base <= q < src.end:
                ack_spans.append((q, max(q + 4, src.next_text_addr(q))))

    def acked_at(addr):
        return any(a <= addr < b for a, b in ack_spans)

    def acked_prev(src, prev):
        return prev in ack_names or (prev in src.sym and acked_at(src.sym[prev][0]))

    nack = 0
    if im.base >= PTR_SCAN_MIN_BASE:
        ext = selfh = interior = ends = 0
        sites = []
        for src in scan:
            if src.base < PTR_SCAN_MIN_BASE:
                continue
            b = src.bytes
            for v, pos in range_hits(src.ptr_index(), lo, hi):
                at = src.base + pos
                is_self = src is im and lo <= at < hi
                if not is_self and acked_at(at):
                    nack += 1
                    continue
                if pos >= 6 and b[pos - 1] == 0x44 and b[pos - 6] == 0x45:
                    st = b[pos - 5] | b[pos - 4] << 8 | b[pos - 3] << 16 | b[pos - 2] << 24
                    if st < v <= st + 0x4000:
                        ends += 1      # `ld xiy, start / ld xix, <this>`: an END bound
                        continue
                if v in starts:
                    if not is_self:
                        strong = True
                else:
                    interior += 1
                if is_self:
                    selfh += 1
                else:
                    ext += 1
                if len(sites) < 4:
                    sites.append('%s%s0x%X->0x%X' % ('SELF ' if is_self else '',
                                                     '' if src is im else src.name + ':', at, v))
        if ext or selfh:
            parts.append('ptr32=%d%s%s (%s)' % (
                ext, (' +SELF %d' % selfh) if selfh else '',
                (', %d at no symbol' % interior) if interior else '', ' '.join(sites)))
        ph, psites = 0, []
        for src in scan:
            if src.base < PTR_SCAN_MIN_BASE:
                continue
            for v, pos in range_hits(src.push_index(), lo, hi):
                if acked_at(src.base + pos):
                    nack += 1
                    continue
                ph += 1
                if len(psites) < 3:
                    psites.append('%s0x%X->0x%X' % ('' if src is im else src.name + ':',
                                                     src.base + pos, v))
        if ph:
            strong = True
            parts.append('push=%d (%s)' % (ph, ' '.join(psites)))
    inside = []
    k = bisect.bisect_left(im.text_addrs, lo)
    while k < len(im.text_addrs) and im.text_addrs[k] < hi:
        inside += im.addr_names[im.text_addrs[k]]
        k += 1

    def inside_range(src, prev):
        # a use from a line whose enclosing label lies inside the range is the object's own
        # internal branch or self-pointer, not a reader
        return src is im and prev in im.sym and lo <= im.sym[prev][0] < hi

    sr, ssites = 0, []
    for src in scan:
        tok, _ = srcidx.tokens(src.name)
        for n in inside:
            for (f, ln, prev, kind) in tok.get(n, []):
                if f == rel and tgt is not None and ln == tgt + 1:
                    continue
                if inside_range(src, prev) or kind == 'endbound':
                    continue
                if kind == 'data32' and src.base >= PTR_SCAN_MIN_BASE:
                    continue            # the same word is in the ptr32 count
                if acked_prev(src, prev):
                    nack += 1
                    continue
                sr += 1
                if len(ssites) < 3:
                    ssites.append('%s:%d(%s)' % (f, ln, n))
    if sr:
        strong = True
        parts.append('srcref=%d (%s)' % (sr, ' '.join(ssites)))
    if im.base >= PTR_SCAN_MIN_BASE:
        nr, nsites, njump = 0, [], 0
        for src in scan:
            _, nums = srcidx.tokens(src.name)
            a = bisect.bisect_left(nums, (lo, '', 0, '', ''))
            while a < len(nums) and nums[a][0] < hi:
                v, f, ln, prev, kind = nums[a]
                a += 1
                if inside_range(src, prev) or kind == 'endbound':
                    continue
                if acked_prev(src, prev):
                    nack += 1
                    continue
                if kind == 'jump' and v not in starts and not explicit:
                    njump += 1
                else:
                    strong = True
                nr += 1
                if len(nsites) < 3:
                    nsites.append('%s:%d(0x%X%s)' % (f, ln, v, ' branch' if kind == 'jump' else ''))
        if nr:
            parts.append('numref=%d%s (%s)' % (nr, (', %d branch into the interior' % njump)
                                               if njump else '', ' '.join(nsites)))
    cp, csites = 0, []
    for src in scan:
        for (clo, chi, f, ln, txt) in srcidx.copies(src.name):
            if clo < hi and chi > lo:
                cp += 1
                if len(csites) < 3:
                    csites.append('%s:%d %s [0x%X,0x%X)%s' % (
                        f, ln, txt, clo, chi, ' starts before the range' if clo < lo else ''))
    if cp:
        strong = True
        parts.append('copy=%d (%s)' % (cp, '; '.join(csites)))
    if parts and nack:
        parts.append('%d more from places the header itself names' % nack)
    return '; '.join(parts), strong


# --- table-counts -------------------------------------------------------------------------

COUNT_RE = re.compile(
    r'(?P<pre>\b(?:table|array|list|vector) of\s+)?'
    r'\b(?P<n>\d+|0x[0-9A-Fa-f]+)(?:\s*|-)(?P<x>x\s*|\u00d7\s*)?'
    r'(?P<unit>(?:(?:handler|code|data|word|long|24-bit|32-bit|routine|function|string|record|'
    r'event|jump)\s+)?pointers?|u32|u16|u8|longs?|dwords?|halfwords?|words?|entries|entry|'
    r'records?|rows?|elements?|slots?|offsets?|items?)\b', re.I)
COUNT_RE2 = re.compile(r'(?P<pre>\bentry count)\s*(?:is\s*|of\s*|=\s*)?(?P<n>\d+|0x[0-9A-Fa-f]+)\b'
                       r'(?P<x>)(?P<unit>)', re.I)
DIRECT_LEAD = re.compile(r'\W*(?:(?:a|an|the|this|it|its|is|are|holds?|has|have|contains?|with|of|'
                         r'table|array|list|vector|exactly|precisely|consists of|made of|now|'
                         r'here|below|just|only)\W*)*', re.I)
PARTIAL_BEFORE = re.compile(r'(?:\bor|\bnor|\bthan|\bvs\.?|versus|first|last|only|remaining|other|used|valid|populated|non-?zero|'
                            r'active|next|extra|more|of which|every|per|each|all but|at least|'
                            r'up to|at most|max(?:imum)?|min(?:imum)?|another|those|these)\s*$', re.I)
PARTIAL_AFTER = re.compile(r'\s*(?:per\b|each\b|apiece|of (?:the|each|which)\b|in each|more\b|'
                           r'(?:it|that|which|they|we|the code|the reader|its reader)\b|'
                           r'later\b|before\b|after\b|above\b|below\b|further\b|back\b|ahead\b|'
                           r'into\b|from\b|earlier\b|away\b)', re.I)
RECSIZE = re.compile(r'\b(\d+)[- ]byte (?:records?|entries|entry|rows?|elements?|slots?)\b|'
                     r'\b(\d+)\s*(?:B|bytes)\s+(?:each|per (?:entry|record|row|element|slot))\b|'
                     r'\bstride\s+(\d+)\b|\brecords? of (\d+) bytes\b', re.I)
GRID = re.compile(r'\s*(?:x|\u00d7)\s*(\d+)\b')
DIRECTIVE = re.compile(r'^\s*(?:[A-Za-z_][\w]*:)?\s*(\.[A-Za-z0-9_]+|addr24)\b\s*(.*)$')
EXACT_UNITS = {'u32': 4, 'long': 4, 'longs': 4, 'dword': 4, 'dwords': 4, 'u16': 2, 'word': 2,
               'words': 2, 'halfword': 2, 'halfwords': 2, 'u8': 1}


def num(x):
    """int() of a decimal (leading zeros allowed) or 0x-hex literal."""
    x = x.strip()
    return int(x, 16) if x[:2].lower() == '0x' else int(x, 10)


def split_operands(s):
    out, depth, cur, q = [], 0, [], None
    for ch in s:
        if q:
            cur.append(ch)
            if ch == q:
                q = None
            continue
        if ch in '"\'':
            q = ch
        elif ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        elif ch == ',' and depth == 0:
            out.append(''.join(cur).strip())
            cur = []
            continue
        cur.append(ch)
    if ''.join(cur).strip():
        out.append(''.join(cur).strip())
    return out


def object_shape(sf, li, label, extend=False):
    """Data emitted from label line li to the next label that is not a child.  extend='glued'
    also runs through labels that follow a data line directly (per-entry labels, a `Table+1`
    label after a pad byte); extend='loose' also through labels separated from the data above
    only by comment lines (no blank line, no ; ---- separator), e.g. a table whose last rows
    sit under a kept legacy label.  Returns a dict, or None when the object holds
    instructions."""
    shape = collections.Counter()
    items = []
    lines = 0
    bytes_ = 0
    first_label_rows = None
    n = len(sf.code)
    i = li
    kids = 0
    # the leading run: items of the first directive kind, up to the first comment-only line,
    # blank line, label or other directive ("SoundProgram_DispatchTable -- 256 handler
    # pointers" followed, after a comment, by the three tables at +0x400 / +0x800 / +0x880)
    run = {'kind': None, 'n': 0, 'open': True}
    while i < n:
        c = sf.code[i]
        lm = LABEL_DEF.match(c)
        if run['open'] and i != li and (lm or sf.comment_only(i) or not sf.raw[i].strip()):
            if run['kind'] is not None:
                run['open'] = False
        if lm and i != li:
            nm = lm.group(1)
            glued = False
            if extend and i > 0:
                k = i - 1
                if extend == 'loose':
                    while k > li and sf.comment_only(k) and \
                            not re.match(r'^\s*[-=*#~]{5,}\s*$', sf.comment[k]):
                        k -= 1
                glued = bool(sf.code[k].strip()) and bool(DIRECTIVE.match(sf.code[k]))
            if not nm.startswith(label + '_') and not glued:
                break
            kids += 1
            if first_label_rows is None:
                first_label_rows = dict(shape)
        body = c[lm.end():] if lm else c
        if not body.strip():
            i += 1
            continue
        dm = DIRECTIVE.match(body)
        if not dm:
            return None                      # an instruction: this is code, not a table
        d, ops = dm.group(1).lower(), dm.group(2)
        if run['open'] and d not in ('.set', '.equ', '.p2align', '.align', '.balign', '.org',
                                     '.globl', '.global', '.type', '.size'):
            if run['kind'] is None:
                run['kind'] = d
            if d == run['kind']:
                run['n'] += len(split_operands(ops)) if d not in ('.ascii', '.asciz', '.string',
                                                                  '.incbin') else 1
            else:
                run['open'] = False
        if d in ('.long', '.4byte', '.int', '.word32'):
            k = len(split_operands(ops))
            shape['long'] += k
            bytes_ += 4 * k
            items += split_operands(ops)
        elif d in ('.short', '.2byte', '.hword', '.word', '.half'):
            k = len(split_operands(ops))
            shape['short'] += k
            bytes_ += 2 * k
            items += split_operands(ops)
        elif d == '.byte':
            k = len(split_operands(ops))
            shape['byte'] += k
            bytes_ += k
            items += split_operands(ops)
        elif d == 'addr24':
            k = len(split_operands(ops))
            shape['addr24'] += k
            bytes_ += 3 * k
            items += split_operands(ops)
        elif d in ('.ascii', '.asciz', '.string'):
            strs = string_literals(ops)
            shape['string'] += len(strs)
            bytes_ += sum(len(re.sub(r'\\(x[0-9A-Fa-f]{1,2}|[0-7]{1,3}|.)', 'x', s)) for s in strs)
            bytes_ += len(strs) if d != '.ascii' else 0
        elif d == '.incbin':
            ib = INCBIN.search(body)
            if not ib:
                return None
            shape['incbin'] += 1
            bytes_ += num(ib.group(2))
        elif d in ('.space', '.zero', '.skip', '.fill'):
            ops_ = split_operands(ops)
            try:
                k = num(ops_[0]) * (num(ops_[1]) if d == '.fill' and len(ops_) > 1 else 1)
            except (ValueError, IndexError):
                return None
            shape['space'] += 1
            bytes_ += k
        elif d in ('.set', '.equ', '.p2align', '.align', '.balign', '.org', '.globl', '.global',
                   '.type', '.size', '.section', '.text', '.equiv', '.local', '.weak'):
            i += 1
            continue
        else:
            shape['other'] += 1
        lines += 1
        i += 1
    return dict(shape=shape, items=items, lines=lines, bytes=bytes_, kids=kids,
                first_rows=first_label_rows, run=run['n'], run_kind=run['kind'])


def is_terminator(v):
    v = v.strip().lower()
    return v in ('0', '0x0', '0x00', '0x0000', '0x00000000', '0xff', '0xffff', '0xffffffff', '-1')


def check_table_counts(tree, images, facts, srcidx=None):
    """table-counts -- does a stated entry count match the rows the source emits?

    QUESTION  When a label's header says "table of N pointers", "N handler pointers", "N x
    u32", "N entries", "N-entry", "N records", "N rows", "N words", "ENTRY COUNT N" ..., does
    the object under that label -- up to the next label that is not its own child
    (`Label_*`) -- emit N of them?  The header is: the comment block directly above the
    label, from its last `; ----` separator down (at most 30 lines), plus any banner section
    above that names the label; the label line's own comment; and, for a bare `Label:`, the
    comment lines between it and its first data line.

    SIGNAL  The directives under the label: .long/.4byte items, .short/.2byte/.word items,
    .byte items, addr24 items, .ascii strings, data lines, child labels + 1, .incbin size.
    "N x u32"/"pointers"/"longs" must equal the 32-bit item count (or addr24 items, or bytes/4);
    "N x u16"/"words" the 16-bit count (or bytes/2); "N x u8" the byte count; "N entries" /
    "records" / "rows" / "elements" / "slots" any one of the row measures, or bytes / K when the
    header states a K-byte record.  One extra trailing terminator item (0, -1, 0xff..) is
    allowed.  "R rows x C" grids accept R or R*C.  Counts that are about something else are
    skipped: "per", "each", "first", "only", "of which", "or", "it / that / which" ... next to
    the number, offsets ('+4 u8'), slash lists ('op03/04/08'), type annotations without 'x'
    ('4 long'), sizes ('6-word'), bitmap pixel rows, a parenthetical after another symbol, or
    another symbol / another 0xADDR in the same clause.  Objects that contain instructions are
    skipped.  The rows are also re-counted through labels glued to the data above (per-entry
    labels, `Table+1` after a pad byte) and through labels separated only by comment lines
    (the last rows kept under a legacy label); a match on any of the three passes.  The
    LEADING RUN -- items of the first directive kind up to the first comment line, blank line,
    label or other directive -- is one more measure: "SoundProgram_DispatchTable -- 256
    handler pointers" holds 256 `.long`s and then, after a comment, three more tables that
    the header says follow it.
    For mismatches the detail lists the bounds (`cp reg, N`) in the code that loads the label,
    which is the reader's opinion of the count.

    HIT  `COUNT-MISMATCH` -- the count is stated OF the object ("table of N", "ENTRY COUNT N",
    the label named in the claim's sentence, or the header's first sentence with nothing but
    filler before the number) and an exact unit disagrees, a stated record size does not
    multiply out (non-pointer data), or a table of one item kind does not hold a multiple of
    N.  `WEAK-COUNT-UNVERIFIED` -- everything else that matches no measure: counts met in
    prose further down the header, .incbin / .byte objects whose layout the directives do not
    show, variable-length records.  The WEAK tier is noisy by design (prom_d's index-map
    headers alone give ~1,350 rows); read the strong tier first.

    FALSE POSITIVES  a count that describes a sub-part named earlier in the same sentence
    without a symbol name ("the header is 4 words"); a table whose later rows sit under labels
    preceded by a blank line or separator; prose that counts the entries the code uses rather
    than the ones stored.
    """
    rows = []
    for name, files in tree.files.items():
        im = images[name]
        for sf in files:
            if sf.kind != 's':
                continue
            for li, label in sf.labels():
                hdr = label_header(sf, li, label)
                if not hdr:
                    continue
                joined, starts = '', []
                for (lj, t) in hdr:
                    t = re.sub(r'^\s*(?:\[[^\]]*\]\s*)+', '', t).strip()
                    # a new header line that starts a field ("ENTRY COUNT 9" under
                    # "evidence: Foo (0xF1011C)") is a new clause, not the same sentence
                    if joined and re.search(r'[):\]]\s*$', joined) and \
                            re.match(r'(?:[A-Z][A-Z0-9 ]{3,}\b|[A-Za-z][\w ]{0,20}:)', t):
                        joined = joined.rstrip() + '; '
                    starts.append((len(joined), lj))
                    joined += t + ' '
                claims = sorted(list(COUNT_RE.finditer(joined)) + list(COUNT_RE2.finditer(joined)),
                                key=lambda x: x.start())
                if not claims:
                    continue
                shapes = None
                own_addr = im.sym.get(label, (None,))[0]
                for m in claims:
                    lj = [x[1] for x in starts if x[0] <= m.start()][-1]
                    n = num(m.group('n'))
                    unit = (m.group('unit') or 'entries').lower()
                    if n < 2 or n > 100000 or len(m.group('n')) > 6 or \
                            (m.group('n')[:2].lower() == '0x' and n > 0x400):
                        continue
                    before = joined[:m.start('n')]
                    after = joined[m.end():]
                    # '+4 u8' / '+0x10 long' are offsets in a layout table, not counts
                    # offsets (+4 u8), slash lists (op03/04/08 record), codes with a leading 0
                    if re.search(r'(?<![-+])[+-]$|/$', before) or re.match(r'0\d', m.group('n')):
                        continue
                    # a type word (u8 .. long, word) is a count only as 'N x u32' or a plural;
                    # '6-word header' / '4 long' are sizes or layout annotations
                    if unit in ('u8', 'u16', 'u32', 'long', 'word', 'dword', 'halfword') and \
                            not m.group('x'):
                        continue
                    if unit in EXACT_UNITS and '-' in joined[m.end('n'):m.start('unit')]:
                        continue
                    if PARTIAL_BEFORE.search(before) or PARTIAL_AFTER.match(after):
                        continue
                    if not about_this_object(before, after, label, own_addr, facts):
                        continue
                    # is the count stated OF this object ("Label -- 12 x u32", "table of 7
                    # pointers", "16-entry table", "ENTRY COUNT 32") or only near it in prose?
                    sent_start = max(before.rfind('. '), 0)
                    lead_raw = re.split(r'\.\s|;\s|:\s|\s--\s|\(', before)[-1]
                    in_paren = before.rfind('(') > max(before.rfind(')'), sent_start)
                    paren_owner = re.search(r'([A-Za-z_]\w*)\s*\([^()]*$', before)
                    first_sentence = m.start() < (joined.find('. ') if '. ' in joined else len(joined))
                    direct = bool(m.group('pre')) or \
                        re.search(r'(?<![\w$])%s(?![\w$])' % re.escape(label),
                                  before[sent_start:]) is not None or \
                        (first_sentence and DIRECT_LEAD.fullmatch(lead_raw) is not None)
                    if in_paren and not (paren_owner and paren_owner.group(1) == label):
                        direct = False             # '(18 longs)' after some other noun

                    sent = joined[max(joined.rfind('. ', 0, m.start()), 0):]
                    sent = sent[:sent.find('. ', 2) + 1 or len(sent)]
                    recs = [int(next(g for g in r.groups() if g)) for r in RECSIZE.finditer(sent)]
                    variable = bool(re.search(r'variable|sentinel|terminated|until|up to', sent, re.I))
                    if re.search(r'\bwhether\b|\beither\b|\bor an?\b', sent, re.I):
                        direct = False             # alternatives, not a statement
                    # pixel rows of a bitmap / glyph are not table rows
                    if unit.startswith('row') and re.search(r'bitmap|pixel|glyph|image|icon|font',
                                                            label + ' ' + sent, re.I):
                        continue
                    if shapes is None:
                        shapes = [object_shape(sf, li, label), object_shape(sf, li, label, 'glued'),
                                  object_shape(sf, li, label, 'loose')]
                        if shapes[0] is None:
                            break
                    want = {n}
                    gm = GRID.match(after)
                    if gm:
                        want.add(n * int(gm.group(1)))
                    gb = re.search(r'(\d+)\s*(?:[A-Za-z]+\s+)?(?:x|\u00d7)\s*$', before)
                    if gb:
                        want.add(n * int(gb.group(1)))
                    verdicts = [judge_count(n, want, unit, sh, recs, variable)
                                for sh in shapes if sh is not None]
                    if any(v is None for v in verdicts):
                        continue
                    kinds = [v[0] for v in verdicts]
                    kind = 'COUNT-MISMATCH' if direct and all(k == 'COUNT-MISMATCH' for k in kinds) \
                        else 'WEAK-COUNT-UNVERIFIED'
                    measure = verdicts[0][1]
                    if len(verdicts) > 2 and verdicts[2][1] != measure:
                        measure += ' (through the labels below it: %s)' % verdicts[2][1]
                    bounds = reader_bounds(tree, name, label) if kind == 'COUNT-MISMATCH' else ''
                    rows.append((name, sf.rel, lj + 1, label,
                                 '%s stated "%s" ; emitted %s%s%s' % (
                                     kind, m.group(0).strip(), measure,
                                     ('; reader bounds: ' + bounds) if bounds else '',
                                     tree.shared_note(sf))))
    return rows


def label_header(sf, li, label):
    """[(line_index, comment)] that describe the label at li: of the comment block directly
    above it, the section below the last separator line (; ---- / ; ====, at most 30 lines)
    plus any banner section that names the label; the label line's own comment; and comment
    lines between the label and its first data line."""
    block = []
    j = li - 1
    while j >= 0 and sf.comment_only(j):
        block.append(j)
        j -= 1
    block.reverse()
    sections, cur = [], []
    for j in block:
        if re.match(r'^\s*[-=*#~]{5,}\s*$', sf.comment[j]):
            if cur:
                sections.append(cur)
            cur = []
        else:
            cur.append(j)
    if cur:
        sections.append(cur)
    keep = []
    if sections:
        last = sections[-1] if block and not re.match(r'^\s*[-=*#~]{5,}\s*$',
                                                       sf.comment[block[-1]]) else []
        keep = last[-30:]
        for sec in sections:
            if sec is not last and any(re.search(r'(?<![\w$])%s(?![\w$])' % re.escape(label),
                                                 sf.comment[j]) for j in sec):
                keep = sec + [x for x in keep if x not in sec]
    hdr = [(j, sf.comment[j]) for j in sorted(set(keep))]
    if sf.comment[li] is not None:
        hdr.append((li, sf.comment[li]))
    lm = LABEL_DEF.match(sf.code[li])
    if lm and not sf.code[li][lm.end():].strip():      # `Label:` alone: its data follows
        j = li + 1
        while j < len(sf.code) and sf.comment_only(j):
            hdr.append((j, sf.comment[j]))
            j += 1
    return hdr


def about_this_object(before, after, label, own_addr, facts):
    """Is a count, given the text before and after it, about the labeled object?  No when the
    count sits in a parenthetical after another symbol, or its clause names another symbol or
    another address."""
    depth, k = 0, len(before) - 1
    while k >= 0:
        ch = before[k]
        if ch == ')':
            depth += 1
        elif ch == '(':
            if depth == 0:
                break
            depth -= 1
        k -= 1
    if k >= 0:                                   # inside '( ... N'
        prev = re.search(r'([A-Za-z_][\w]*)\s*$', before[:k])
        if prev and prev.group(1) != label and prev.group(1) in facts.defined:
            return False
        clause_b = before[k + 1:]
    else:
        clause_b = re.split(r'\.\s|;\s|:\s|\s--\s', before)[-1]
    clause_a = re.split(r'[,;)]|\.\s', after, maxsplit=1)[0]
    clause = clause_b + ' ' + clause_a
    for a in re.findall(r'0x([0-9A-Fa-f]{5,8})', clause):
        if int(a, 16) != own_addr:
            return False
    for x in IDENT.findall(clause):
        if x != label and x in facts.defined and symbol_like(x, 4) and \
                not label.startswith(x) and not x.startswith(label):
            return False
    return True


def judge_count(n, want, unit, sh, recs, variable=False):
    """None when the claim fits the emitted object, else (kind, description)."""
    s = sh['shape']
    items = sh['items']
    term = 1 if items and is_terminator(items[-1]) else 0
    measures = collections.OrderedDict()
    measures['long'] = s.get('long', 0)
    measures['addr24'] = s.get('addr24', 0)
    measures['short'] = s.get('short', 0)
    measures['byte'] = s.get('byte', 0)
    measures['string'] = s.get('string', 0)
    measures['lines'] = sh['lines']
    measures['labels'] = sh['kids'] + 1
    b = sh['bytes']
    desc = '%s, %d B' % (', '.join('%s=%d' % (k, v) for k, v in measures.items() if v), b)

    def hit(vals):
        return any(v in want or (term and v - 1 in want) for v in vals if v)

    base_unit = unit.split()[-1]
    if not b and not any(measures[k] for k in ('long', 'addr24', 'short', 'byte', 'string')):
        return None
    run_n, run_k = sh.get('run', 0), sh.get('run_kind')
    run_w = {'.long': 4, '.4byte': 4, '.int': 4, 'addr24': 3, '.short': 2, '.2byte': 2,
             '.hword': 2, '.word': 2, '.byte': 1}.get(run_k)
    if 'pointer' in base_unit or unit in ('u32', 'long', 'longs', 'dword', 'dwords'):
        vals = [measures['long'], measures['addr24'], measures['long'] + measures['addr24']]
        vals += [run_n] if run_w in (3, 4) else []
        vals += [b // 4] if b % 4 == 0 else []
        vals += [b // 3] if '24' in unit and b % 3 == 0 else []
        if hit(vals):
            return None
        if not measures['long'] and not measures['addr24'] and b >= 3 * min(want):
            # an .incbin / .byte object big enough to hold them: the layout is not visible
            return 'WEAK-COUNT-UNVERIFIED', desc
        return 'COUNT-MISMATCH', desc
    if base_unit in ('offset', 'offsets'):
        vals = [measures['long'], measures['short'], measures['byte'], measures['lines']]
        if hit(vals) or (b and any(b in (2 * w, 4 * w) for w in want)):
            return None
        return 'WEAK-COUNT-UNVERIFIED', desc
    if unit in EXACT_UNITS:
        w = EXACT_UNITS[unit]
        key = {4: 'long', 2: 'short', 1: 'byte'}[w]
        vals = [measures[key]]
        if b % w == 0:
            vals.append(b // w)
        if run_w == w or (unit in ('word', 'words') and run_w == 4):
            vals.append(run_n)
        if unit in ('word', 'words'):             # "word" is also used for a 32-bit cell
            vals += [measures['long']] + ([b // 4] if b % 4 == 0 else [])
        if hit(vals):
            return None
        return 'COUNT-MISMATCH', desc
    # entries / records / rows / elements / slots / items
    vals = list(measures.values()) + [run_n]
    if sh.get('first_rows'):
        vals += list(sh['first_rows'].values())
    if hit(vals):
        return None
    if recs and not measures['long']:
        if any(w * r == b or (w + term) * r == b for r in recs for w in want):
            return None
        return 'COUNT-MISMATCH', desc + '; stated record size %s B' % '/'.join(map(str, recs))
    kinds = [k for k in ('long', 'addr24', 'short') if measures[k]]
    homogeneous_wide = len(kinds) == 1 and not measures['byte'] and not measures['string'] \
        and not s.get('incbin') and not s.get('space')
    if homogeneous_wide and not variable and not any(measures[kinds[0]] % w == 0 for w in want):
        return 'COUNT-MISMATCH', desc + '; every row is %s items, %d does not divide %d' % (
            kinds[0], n, measures[kinds[0]])
    return 'WEAK-COUNT-UNVERIFIED', desc


def reader_bounds(tree, imn, label):
    out = []
    for sf in tree.all_files.get(imn, []):
        if sf.kind != 's':
            continue
        for i, c in enumerate(sf.code):
            if label not in c or LABEL_DEF.match(c) and LABEL_DEF.match(c).group(1) == label:
                continue
            if not re.search(r'(?<![\w$])%s(?![\w$])' % re.escape(label), c):
                continue
            for j in range(max(0, i - 10), min(len(sf.code), i + 12)):
                m = re.match(r'^\s*(?:[A-Za-z_]\w*:)?\s*cp\s+(\w+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)(?::i\d+)?\s*$',
                             sf.code[j], re.I)
                if m:
                    v = num(m.group(2))
                    if 1 < v < 0xff:
                        out.append('%s:%d cp %s,%d' % (sf.rel, j + 1, m.group(1), v))
            if len(out) >= 4:
                return ' '.join(out[:4])
    return ' '.join(out[:4])


# --- empty-templates ----------------------------------------------------------------------

PLACEHOLDER = re.compile(
    r'\{[A-Za-z_][\w.]*(?:![rsa])?(?::[^}]*)?\}|'          # str.format leftovers: {name}, {addr:06X}
    r'%\([A-Za-z_]\w*\)[sdxX]|'                            # %(name)s
    r'(?<![\w%])%0\d+[dxX](?![\w])|'                      # %06X  (a bare %x / %d is prose
    r'\b0x(?![0-9A-Fa-fXx?\-])|'                          #  about printf); '0x' + no digits
    r'<(?:TODO|TBD|FILL(?: ?IN)?|NAME|ADDR|LABEL|PLACEHOLDER|XXX)>|\bTBD\b')
# A comment line that starts a new template field: the line before it, if it ended in ':',
# got no content of its own ("what that code does with it:" / "evidence: ...").
TEMPLATE_FIELD = re.compile(
    r'^\s*(?:\[[^\]]+\]\s*)?(?:evidence|readers?|writers?|purpose|layout|callers?|status|'
    r'confidence|verified|searched|provenance|references|refs|links|users|used by|read by|'
    r'see also|source|forms searched|reached from|caveat)\s*:', re.I)
TEMPLATE_WORDS = re.compile(r'\b(?:what|which|how|reader|readers|purpose|evidence|layout|'
                            r'callers?|called by|read by|used by|meaning|does)\b', re.I)


def check_empty_templates(tree, images, facts, srcidx=None):
    """empty-templates -- did a generated header leave a slot unfilled?

    QUESTION  Which comment lines are template scaffolding with no content: a line that ends
    in ':' ('what that code does with it:', 'Readers:') after which the comment block ends or
    the NEXT template field starts ('evidence:', 'Readers:', 'Purpose:' ... at the same
    indent), and comment text with unformatted placeholders ('{name}', '%(name)s', '%06X',
    '0x' with no digits, '<TODO>', 'TBD')?

    SIGNAL  Per comment block: a line ending in ':' whose following comment lines (skipping
    lines that are just ';') hold nothing before the block ends.  When the next code line is
    a label, a blank line or EOF the colon promises content that is not there (`EMPTY-SLOT`).
    When it is an instruction or data directive the colon may introduce that code, so the hit
    is `WEAK-EMPTY-SLOT` unless the line uses template words (what / readers / purpose /
    evidence / layout / callers ...), which makes it `EMPTY-SLOT`.  A colon line followed
    directly by the next template field is `EMPTY-SLOT` (the 2026-10-02 review's
    "what that code does with it:" / "evidence: ..." shape).  Placeholders are `PLACEHOLDER`;
    text inside "quotes" / `backticks`, '{word}' where word is a firmware property name
    found in the ROM ('{main_func}'), '0xXXXX' / '0x??' prose and pseudo-code colons
    ('else:', 'case 3:', 'if ...:') are not.

    Blank lines (double-spaced headers) and separator lines (an ASCII-art preview framed by
    ; ----) are looked past: the first comment text after them fills the slot, unless a
    separator or an ALL-CAPS / '!!' banner after a blank line opens a new section (then the
    slot is EMPTY-SLOT).

    FALSE POSITIVES  a colon that introduces the data rows below, each commented inline
    (that is why those are WEAK unless the line reads like a template slot); '%06X'-style
    text describing a printf format the firmware uses, outside quotes; '{...}' in comments
    that show a C initializer or set notation.
    """
    rows = []
    for name, files in tree.files.items():
        for sf in files:
            ctx = sf.context_labels()
            note = tree.shared_note(sf)
            n = len(sf.raw)
            for i, cm in enumerate(sf.comment):
                if not cm:
                    continue
                unq = re.sub(r'"[^"]*"|`[^`]*`', lambda x: ' ' * len(x.group(0)), cm)
                for pm in PLACEHOLDER.finditer(unq):
                    if sf.kind == 'c' and pm.group(0).startswith('{'):
                        continue
                    # '{main_func}' / '{index}': a firmware property name in brace notation
                    bm = re.match(r'\{(\w+)', pm.group(0))
                    if bm and bm.group(1) in facts.rom_text:
                        continue
                    rows.append((name, sf.rel, i + 1, ctx[i],
                                 'PLACEHOLDER %r in: %s%s' % (pm.group(0).strip(), cm.strip()[:120], note)))
                    break
                if not sf.comment_only(i):
                    continue
                s = cm.strip()
                if not s.endswith(':') or len(s) < 3 or s.endswith('::'):
                    continue
                if re.search(r'(?:https?|ftp|file):$|\b\d+:$|\bxsp:$', s):
                    continue
                # pseudo-code: 'else:', 'loop:', 'case 3:', 'if (a == 0):' introduce the code below
                if re.search(r'(?:^|\W)(?:else|then|loop|default|otherwise|do|begin|repeat|'
                             r'finally|try|case\s+\S+|if\b.*|when\b.*|while\b.*|for\b.*)\s*:$',
                             s, re.I):
                    continue
                j = i + 1
                filled = False
                next_field = None
                indent = len(cm) - len(cm.lstrip())
                # the slot's content may sit after blank lines (double-spaced headers) and
                # after a separator line (an ASCII-art preview framed by ; ----): skip both,
                # but a separator after a blank line opens a new section
                blank_seen = new_section = False
                while j < n and (sf.comment_only(j) or not sf.raw[j].strip()):
                    if not sf.raw[j].strip():
                        blank_seen = True
                        j += 1
                        continue
                    cj = sf.comment[j]
                    if not cj.strip() or re.match(r'^\s*[-=*#~]{5,}\s*$', cj):
                        if blank_seen and cj.strip():
                            new_section = True
                            break          # a new section starts: the slot stayed empty
                        j += 1
                        continue
                    if TEMPLATE_FIELD.match(cj) and len(cj) - len(cj.lstrip()) <= indent:
                        next_field = cj.strip()
                    elif blank_seen and re.match(r'^\s*(?:!!|[A-Z][A-Z0-9 /-]{6,}$)', cj):
                        new_section = True  # a banner of the next section
                    else:
                        filled = True
                    break
                if filled:
                    continue
                if next_field:
                    rows.append((name, sf.rel, i + 1, ctx[i], 'EMPTY-SLOT "%s" followed by the '
                                 'next field "%s"%s' % (s[-100:], next_field[:60], note)))
                    continue
                # j = first line that is neither comment-only nor blank (or n)
                nxt = sf.raw[j] if j < n else ''
                if j >= n or new_section or not nxt.strip() or LABEL_DEF.match(sf.code[j]) and \
                        not sf.code[j][LABEL_DEF.match(sf.code[j]).end():].strip():
                    kind = 'EMPTY-SLOT'
                elif TEMPLATE_WORDS.search(s):
                    kind = 'EMPTY-SLOT'
                else:
                    kind = 'WEAK-EMPTY-SLOT'
                rows.append((name, sf.rel, i + 1, ctx[i], '%s "%s" followed by %s%s' % (
                    kind, s[-100:], 'EOF' if j >= n else (repr(nxt.strip()[:50]) or 'blank line'),
                    note)))
    return rows


CHECK_FUNCS = collections.OrderedDict([
    ('stale-names', check_stale_names),
    ('unread-claims', check_unread_claims),
    ('table-counts', check_table_counts),
    ('header-addrs', check_header_addrs),
    ('empty-templates', check_empty_templates),
])


# ============================================================================ driver

def is_weak(row):
    return row[4].startswith('WEAK-')


def write_tsv(path, rows):
    with open(path, 'w', encoding='utf-8', errors='replace') as f:
        f.write('image\tfile\tline\tlabel\tdetail\n')
        for r in rows:
            f.write('\t'.join(str(x).replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')


def summary(results, image_names):
    out = []
    cols = list(image_names)
    w = max(len(c) for c in CHECKS) + 2

    def table(title, pred):
        out.append(title)
        out.append(''.ljust(w) + ''.join(c.rjust(11) for c in cols) + 'total'.rjust(9))
        for chk, rows in results.items():
            cnt = collections.Counter(r[0] for r in rows if pred(r))
            out.append(chk.ljust(w) + ''.join(str(cnt.get(c, 0)).rjust(11) for c in cols) +
                       str(sum(cnt.values())).rjust(9))
    table('HITS (strong kinds) per check per image', lambda r: not is_weak(r))
    out.append('')
    table('WEAK-* rows (same TSVs, filter on detail prefix)', is_weak)
    if 'stale-names' in results:
        rn = collections.Counter(r[0] for r in results['stale-names']
                                 if r[4].startswith('STALE-RENAMED'))
        out.append('')
        out.append('stale-names of which STALE-RENAMED (on the OLD side of scripts/renaming): ' +
                   ', '.join('%s=%d' % (c, rn.get(c, 0)) for c in cols) +
                   ', total=%d' % sum(rn.values()))
    return '\n'.join(out)


class Context:
    """Every image's ELF symbols and bytes, and the tree-wide facts -- built once per run."""

    def __init__(self, repo, elf_dirs):
        self.repo = repo
        self.images = collections.OrderedDict()
        for n in IMAGES:
            # every image is loaded: cross-image names and addresses need all of them
            self.images[n] = Image(n, repo, elf_dirs)
        self.facts = Facts(repo, self.images)


def run_checks(ctx, tree, checks, out_dir=None):
    images, facts = ctx.images, ctx.facts
    srcidx = SrcRefIndex(tree, images)
    results = collections.OrderedDict()
    for chk in checks:
        fn = CHECK_FUNCS[chk]
        if fn in (check_unread_claims, check_table_counts):
            rows = fn(tree, images, facts, srcidx)
        else:
            rows = fn(tree, images, facts)
        results[chk] = rows
        if out_dir:
            write_tsv(os.path.join(out_dir, chk + '.tsv'), rows)
    return results


def orphan_sources(repo, tree):
    """.s files under each image's tree that its include graph does not reach (not scanned)."""
    out = {}
    for name in tree.files:
        top = os.path.join(repo, IMAGES[name][0], os.path.dirname(IMAGES[name][1]))
        reached = set(sf.path for sf in tree.all_files[name])
        n = 0
        for dp, dns, fns in os.walk(top):
            dns[:] = [x for x in dns if x not in EXCLUDE_DIRS]
            n += sum(1 for f in fns if f.endswith('.s') and
                     os.path.normpath(os.path.join(dp, f)) not in reached)
        out[name] = n
    return out


def run(repo, image_names, checks, out_dir, elf_dirs):
    ctx = Context(repo, elf_dirs)
    tree = Tree(repo, image_names)
    results = run_checks(ctx, tree, checks, out_dir)
    images = ctx.images
    for im in images.values():
        if im.rom_note:
            print('note: %s: %s' % (im.name, im.rom_note))
    nfiles = sum(len(v) for v in tree.files.values())
    orph = orphan_sources(repo, tree)
    print('images: %s; source files scanned: %d (.s reached by each root\'s .include graph, '
          'plus the tree\'s .c/.h); ELFs from: %s' % (
              ','.join(image_names), nfiles,
              ', '.join(sorted({os.path.dirname(images[x].elf) for x in image_names}))))
    print('not reached by any include (not scanned): ' +
          ', '.join('%s=%d' % (c, orph.get(c, 0)) for c in image_names if orph.get(c)))
    print()
    print(summary(results, image_names))
    if 'unread-claims' in results:
        u = getattr(check_unread_claims, 'unresolved', {})
        print('unread-claims: claim blocks whose range could not be resolved (skipped): ' +
              ', '.join('%s=%d' % (c, u.get(c, 0)) for c in image_names))
    if out_dir:
        print()
        for chk in results:
            print('TSV: %s' % os.path.join(out_dir, chk + '.tsv'))
    return results


def selftest(repo, elf_dirs):
    """Plant one known-bad example per check in a temporary COPY of one v10 source file (the
    tree is never written; the copy goes under $TMPDIR, never /tmp), run every check on that
    copy against the real v10 ELF and ROM, and assert that each planted line is reported --
    and that a correct address quote and a correct count planted beside them are not."""
    ctx = Context(repo, elf_dirs)
    im, facts = ctx.images['v10'], ctx.facts
    # a column-0 label in a v10 source, with no header above it, that a 32-bit pointer
    # elsewhere in the ROM points at exactly
    ptr = im.ptr_index()
    target = None
    for path in include_closure(repo, 'v10'):
        sf = SourceFile(path, os.path.relpath(path, repo))
        for li, lab in sf.labels():
            if lab not in im.sym or im.sym[lab][1] not in 'tT' or not sf.raw[li].startswith(lab):
                continue
            a = im.sym[lab][0]
            hits = [p for v, p in range_hits(ptr, a, a + 1) if not (a <= im.base + p < a + 4)]
            k = bisect.bisect_left(im.text_addrs, a) - 1
            other = im.text_addrs[k] if k >= 0 else None
            if hits and li > 0 and not sf.comment_only(li - 1) and \
                    a - 0x10 not in im.addr_names and im.base <= a - 0x10 and \
                    other is not None and not site_address(im, other) and \
                    lab not in im.addr_names[other]:
                target = (sf, li, lab, a, other)
                break
        if target:
            break
    assert target, 'selftest: no pointer-read label found in v10'
    sf, li, lab, addr, other = target
    # an OLD name from scripts/renaming that nothing defines any more
    old = next((o for o in sorted(facts.renames) if symbol_like(o) and o not in facts.defined
                and not C_STD_NAME.match(o)), None)
    plant = [
        ('stale-names', '; selftest: see Selftest_NoSuchRoutine_Qz9 for the caller'),
        ('stale-renamed', '; selftest: the caller is %s' % (old or 'NONE')),
        ('header-addrs', '; selftest: %s (0x%X) is quoted at the object before it' % (lab, other)),
        ('header-addrs-site', '; selftest: %s (0x%X) is quoted 16 bytes early' % (lab, addr - 0x10)),
        ('header-addrs-control', '; selftest: %s (0x%X) is quoted right' % (lab, addr)),
        ('unread-claims', '; selftest: purpose not established; no reader found.'),
    ]
    lines = list(sf.raw)
    new = lines[:li] + [p[1] for p in plant] + lines[li:]
    at = {p[0]: li + k + 1 for k, p in enumerate(plant)}
    tail = [
        '',
        '; Selftest_BadTable -- table of 3 pointers',
        'Selftest_BadTable:',
        '\t.long\t0x00e00000',
        '\t.long\t0x00e00004',
        '',
        '; Selftest_GoodTable -- table of 2 pointers',
        'Selftest_GoodTable:',
        '\t.long\t0x00e00000',
        '\t.long\t0x00e00004',
        '',
        '; Selftest_Empty -- readers, and what that code does with it:',
        'Selftest_Empty:',
        '\t.byte\t0',
    ]
    at['table-counts'] = len(new) + 2
    at['table-counts-control'] = len(new) + 7
    at['empty-templates'] = len(new) + 12
    new += tail
    scratch_root = os.environ.get('TMPDIR') or os.path.expanduser('~/compartilhado/tmp')
    if os.path.realpath(scratch_root).startswith('/tmp'):
        scratch_root = os.path.expanduser('~/compartilhado/tmp')
    os.makedirs(scratch_root, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix='claims_lint_selftest_', dir=scratch_root)
    try:
        dst = os.path.join(tmp, sf.rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(('\n'.join(new) + '\n').encode('latin-1'))
        # the planted copy stands in for the real file; the rest of the tree supplies facts
        tree = Tree(repo, ['v10'], override={'v10': [dst]})
        for files in tree.all_files.values():
            for f_ in files:
                for _, l_ in f_.labels():
                    facts.defined.add(l_)
        res = run_checks(ctx, tree, CHECKS)
        ok = True

        def expect(chk, key, kind_prefix, present=True):
            nonlocal ok
            line = at[key]
            got = [r for r in res[chk] if r[2] == line and r[4].startswith(kind_prefix)]
            good = bool(got) == present
            ok &= good
            print('%-4s %-15s line %-6d %-24s %s' % (
                'ok' if good else 'FAIL', chk, line,
                ('caught ' + kind_prefix) if present else 'control not flagged',
                (got[0][4][:100] if got else '')))
        expect('stale-names', 'stale-names', 'STALE')
        if old:
            expect('stale-names', 'stale-renamed', 'STALE-RENAMED')
        expect('header-addrs', 'header-addrs', 'WRONG-ADDR')
        expect('header-addrs', 'header-addrs-site', 'WEAK-SITE')
        expect('header-addrs', 'header-addrs-control', 'WRONG-ADDR', present=False)
        expect('unread-claims', 'unread-claims', 'READ-DESPITE-CLAIM')
        expect('table-counts', 'table-counts', 'COUNT-MISMATCH')
        expect('table-counts', 'table-counts-control', 'COUNT', present=False)
        expect('empty-templates', 'empty-templates', 'EMPTY-SLOT')
        print('selftest (planted copy of %s under %s, target label %s): %s' % (
            sf.rel, scratch_root, lab, 'PASS' if ok else 'FAIL'))
        return 0 if ok else 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('checks', nargs='*', metavar='CHECK',
                    help='checks to run: %s (default: all)' % ' '.join(CHECKS))
    ap.add_argument('--images', default=','.join(IMAGES),
                    help='comma-separated images (default: all)')
    ap.add_argument('--out', default=os.path.join(os.environ.get('TMPDIR') or
                                                  os.path.expanduser('~/compartilhado/tmp'),
                                                  'claims_lint'),
                    help='directory for the per-check TSVs')
    ap.add_argument('--elf-dir', action='append', default=[],
                    help='directory holding the *.llvm.elf files (repeatable; default: the '
                         'repo\'s rebuilt_ROMs/ and wsa1/rebuilt_ROMs/)')
    ap.add_argument('--repo', default=DEFAULT_REPO)
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--explain', action='store_true', help='print every check\'s docstring')
    a = ap.parse_args()
    repo = os.path.abspath(a.repo)
    elf_dirs = a.elf_dir or [os.path.join(repo, 'rebuilt_ROMs'),
                             os.path.join(repo, 'wsa1', 'rebuilt_ROMs')]
    if a.explain:
        for chk, fn in CHECK_FUNCS.items():
            print(fn.__doc__)
        return 0
    if a.selftest:
        return selftest(repo, elf_dirs)
    names = [x.strip() for x in a.images.split(',') if x.strip()]
    bad = [x for x in names if x not in IMAGES]
    if bad:
        ap.error('unknown image(s): %s' % ','.join(bad))
    checks = a.checks or CHECKS
    badc = [c for c in checks if c not in CHECKS]
    if badc:
        ap.error('unknown check(s): %s' % ','.join(badc))
    os.makedirs(a.out, exist_ok=True)
    run(repo, names, checks, a.out, elf_dirs)
    return 0


if __name__ == '__main__':
    sys.exit(main())
