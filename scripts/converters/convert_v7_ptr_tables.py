#!/usr/bin/env python3
"""convert_v7_ptr_tables.py -- rewrite v7 `.incbin` pointer tables as `.long <symbol>`.

QUESTION ANSWERED
-----------------
`scripts/analysis/l3_slice_structure_triage.py` flags 61 files / 8,440 bytes of
no-source-slice blob as PTR_TABLE -- "addresses; should be symbols, not bytes".
Its own docstring calls that a TRIAGE, not a verdict. This script answers the two
questions the triage cannot:

  1. Is a given blob REALLY a table of code/data addresses, on evidence that
     could have come out the other way?
  2. What do the `.long` lines look like, and do they assemble back to EXACTLY
     the bytes the blob held?

Question 2 is the hard requirement -- the rebuilt ROM must stay byte-identical --
and `--check` settles it WITHOUT running the assembler: every emitted line is
resolved in Python and the result compared with the blob byte for byte.

WHY THE OBVIOUS METHOD ANSWERS "NO" TO QUESTION 1, WRONGLY
-----------------------------------------------------------
Resolving a target through `symbols/maincpu_symbols_reference.txt` lands on a
known symbol for only ~3% of in-range words. That file is generated from
`rebuilt_ROMs/kn5000_v10_program.llvm.elf`: it is the V10 link. v7 is a different
link -- across these blobs v7 addresses sit 0x0 to 0x7d1 below their v10
namesakes, in ten piecewise-constant blocks. Resolving a v7 pointer in the v10
address space is a category error, and it answers "not a pointer table" for
tables that plainly are one.

Against `rebuilt_ROMs/kn5000_v7_program.llvm.elf` the same words resolve as:

    1,536 in-range words in the 58 PTR_TABLE romslices
      1,252 (81.5%) land EXACTLY on a v7 symbol
        284 (18.5%) land INSIDE one, at offset 1..835
          0         land outside every symbol

⚠ "INSIDE a symbol" IS NOT EVIDENCE. 38,984 symbol addresses over a 2 MB ROM put
79.5% of RANDOM in-range addresses within 4 KB after some symbol (`--controls`
measures it). A rule that accepts a blob because its words are "inside symbols"
cannot fail, so this script never counts interior hits toward its verdict -- it
only uses them to SPELL a target once the table is already proven.

HOW A BLOB IS PROVEN (two independent tests, either one suffices)
------------------------------------------------------------------
Let a run be the longest stretch of 4-aligned words that are all either in a ROM
range or a sentinel (0x00000000 / 0xffffffff), holding at least 3 real pointers.
For the k in-range words of that run:

  TIER A -- v7 symbols.  e7 of them land exactly on a v7 ELF symbol. The null is
    the symbol density in the ROM window (1.86% analytically, 1.74% measured), so
    P(Binom(k, p0) >= e7) is the chance of that by accident. Accept below 1e-4.

  TIER B -- v10 corroboration.  Some genuine tables point at code v7 has never
    labelled, so e7 is 0 and Tier A cannot see them. For those, read the SAME
    label's table out of the v10 ROM at its v10 ELF address and ask how many of
    ITS words land exactly on a v10 symbol. Accept when that is significant, the
    v10-address -> v7-address pairing it induces is strictly order-preserving
    (zero inversions), and at least one pair has a nonzero shift -- so the
    agreement cannot be the trivial "the two ROMs are identical here".

Anything that clears neither is REPORTED AND LEFT ALONE. `--near-misses` lists
them with their numbers, because "this looked like a table and is not proven"
is a result, not a gap.

⚠ IT IS NOT ENOUGH FOR A NAME TO EXIST. v7 carries names sitting on a DIFFERENT
routine than the v9/v10 name of the same spelling: `UIState_ProcessDisplayUpdate`
is at 0x00fd009b in v7, while the routine v10 gives that name corresponds to v7
0x00fcfc81, 0x41a away. Emitting the name because the name exists would have
silently changed the ROM. Every symbol emitted here is read out of the v7 ELF AT
THE ADDRESS THE WORD ALREADY HOLDS, so a name can only be emitted when it
resolves to the value it replaces -- and `--check` re-derives that.

SCOPE
-----
`includes/romslices/` only. `includes/generated/` blobs are compiler output from
committed C sources (naka_*.c, sound_data_*.c, ...); they already have the better
human-readable form the completeness spec asks for, and rewriting them as `.long`
would fork the data away from its source. 16 of them match the pattern and are
skipped for that reason; `--include-generated` overrides, and should not be used.

WHAT IT EMITS
-------------
    LABEL:
            .long  Sym                 ; word == address of Sym            (exact)
            .long  Sym + 30            ; word is 30 bytes into Sym         (interior)
            .long  0xffffffff          ; sentinel or unresolvable          (numeric)

A blob that is a table only in part (a string header, a data tail) keeps the rest
as a smaller `.incbin` of a new slice file, so the residue stays honestly counted
as a blob instead of being laundered into `.byte` lines. `--remainder bytes`
inlines it instead.

RUN
---
    python3 scripts/converters/convert_v7_ptr_tables.py               # summary + gain
    python3 scripts/converters/convert_v7_ptr_tables.py --check       # byte-identity gate
    python3 scripts/converters/convert_v7_ptr_tables.py --controls    # the nulls
    python3 scripts/converters/convert_v7_ptr_tables.py --reconcile   # vs the triage headline
    python3 scripts/converters/convert_v7_ptr_tables.py --name-conflicts
    python3 scripts/converters/convert_v7_ptr_tables.py --list
    python3 scripts/converters/convert_v7_ptr_tables.py --near-misses
    python3 scripts/converters/convert_v7_ptr_tables.py --show UIState_HandlerTable_Basic_00
    python3 scripts/converters/convert_v7_ptr_tables.py --apply       # the only writing mode

Needs both program ROMs and both program ELFs (`make llvm-all`).
"""
import argparse
import bisect
import collections
import math
import pathlib
import random
import re
import struct
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
ROM_BASE = 0xE00000
ROM_SIZE = 0x200000
V7_ROM = REPO / 'original_ROMs/kn5000_v7_program.rom'
V10_ROM = REPO / 'original_ROMs/kn5000_v10_program.rom'
V7_ELF = REPO / 'rebuilt_ROMs/kn5000_v7_program.llvm.elf'
V10_ELF = REPO / 'rebuilt_ROMs/kn5000_v10_program.llvm.elf'
LLVM_NM = pathlib.Path.home() / 'compartilhado/llvm-project/build/bin/llvm-nm'
SRC_ROOT = REPO / 'v7'

# CODE-POINTER ranges only -- the same two the triage uses, and for the same
# reason: adding (0, 0x100000) accepts every small integer in the corpus and
# inflated PTR_TABLE twentyfold the first time it was measured.
ROM_RANGES = ((0xE00000, 0x1000000), (0x200000, 0x300000))
SENTINELS = (0x00000000, 0xFFFFFFFF)

MIN_POINTERS = 3            # a run of 1-2 address-shaped words proves nothing
MAX_INTERIOR_OFFSET = 4096  # only used for SPELLING, never for the verdict
P_THRESHOLD = 1e-4          # ~300 blobs are tested; this is Bonferroni-safe

LABEL_RE = re.compile(r'^([A-Za-z_][\w.]*):')
INCBIN_RE = re.compile(r'\.incbin\s+"([^"]+)"')


# ---------------------------------------------------------------- symbol table
def load_symbols(path):
    """address -> [names].

    ⚠ NOT symbols/maincpu_symbols_reference.txt for v7: that is the v10 link and
    naming a v7 target from it produces the wrong routine (see the docstring).
    """
    if not path.exists():
        sys.exit(f'{path} not found -- run `make llvm-all` first (this script '
                 f'reads build OUTPUT; it does not build).')
    if path.suffix in ('.txt', '.map'):
        text = path.read_text()
    else:
        text = subprocess.run([str(LLVM_NM), '--no-sort', str(path)],
                              capture_output=True, text=True, check=True).stdout
    by_addr = collections.defaultdict(list)
    for line in text.splitlines():
        p = line.split()
        if len(p) == 3 and p[1] in 'tTdDrRbB':
            by_addr[int(p[0], 16)].append(p[2])
        elif len(p) == 2:                       # "NAME ADDRESS" reference format
            try:
                by_addr[int(p[1], 16)].append(p[0])
            except ValueError:
                pass
    return by_addr


def pick_name(names):
    """Deterministic pick among aliases: semantic before positional, then
    shortest, then alphabetical."""
    return sorted(names, key=lambda n: (n.startswith('LABEL_'), len(n), n))[0]


def symbol_density(by_addr):
    """P(a random in-range address is exactly a symbol) -- the Tier A/B null."""
    n = sum(1 for a in by_addr if ROM_BASE <= a < ROM_BASE + ROM_SIZE)
    return n / ROM_SIZE


def binom_tail(k, e, p):
    """P(Binom(k, p) >= e)."""
    if e <= 0:
        return 1.0
    return sum(math.comb(k, i) * p ** i * (1 - p) ** (k - i) for i in range(e, k + 1))


# ------------------------------------------------------------------ blob sites
def resolve_incbin(src, target):
    """Resolve an .incbin path the way llvm-mc does: against the include root
    passed with -I, not the directory holding the directive. Getting this wrong
    silently drops 283 of 288 targets and reports a clean, small, wrong answer."""
    cand = src.parent / target
    if cand.is_file():
        return cand.resolve()
    for up in src.parents:
        cand = up / target
        if cand.is_file():
            return cand.resolve()
        if up == REPO:
            break
    return None


def collect_sites():
    """{source file: (lines, [site])} for every .incbin in v7/, in file order."""
    out = collections.OrderedDict()
    for s in sorted(SRC_ROOT.rglob('*.s')):
        lines = s.read_bytes().decode('latin1').splitlines()
        label, sites = None, []
        for i, line in enumerate(lines):
            m = LABEL_RE.match(line)
            if m:
                label = m.group(1)
            mm = INCBIN_RE.search(line)
            if mm and not line.lstrip().startswith(';'):
                path = resolve_incbin(s, mm.group(1))
                if path is not None:
                    sites.append(dict(line=i, label=label, target=mm.group(1),
                                      path=path))
        if sites:
            out[s] = (lines, sites)
    return out


def locate(rom, lines, sites, k):
    """ROM address of site k, by anchoring the contiguous RUN it belongs to.

    A 32-byte handler table occurs 13 times in the v7 ROM, so searching for one
    blob alone is ambiguous. Consecutive directives separated by nothing but
    labels are contiguous in the output, so the run's concatenation is what gets
    searched. Returns None when that is still not unique, rather than guessing.
    """
    def contiguous(a, b):
        for line in lines[sites[a]['line'] + 1: sites[b]['line']]:
            t = line.strip()
            if not t or t.startswith(';') or LABEL_RE.match(line):
                continue
            return False
        return True

    lo, hi = k, k
    while lo > 0 and contiguous(lo - 1, lo):
        lo -= 1
    while hi + 1 < len(sites) and contiguous(hi, hi + 1):
        hi += 1
    blobs = [sites[j]['path'].read_bytes() for j in range(lo, hi + 1)]
    cat = b''.join(blobs)
    first = rom.find(cat)
    if first < 0 or rom.find(cat, first + 1) >= 0:
        return None
    return ROM_BASE + first + sum(len(blobs[j]) for j in range(k - lo))


# ------------------------------------------------------------------ classifier
def in_rom_range(w):
    return any(lo <= w < hi for lo, hi in ROM_RANGES)


def words_of(blob):
    return [struct.unpack_from('<I', blob, i * 4)[0] for i in range(len(blob) // 4)]


def find_run(words):
    """Longest stretch of pointer-or-sentinel words, ranked by pointer count."""
    runs, cur = [], None
    for i, w in enumerate(words):
        if in_rom_range(w) or w in SENTINELS:
            if cur is None:
                cur = [i, i + 1, 0]
                runs.append(cur)
            else:
                cur[1] = i + 1
            if in_rom_range(w):
                cur[2] += 1
        else:
            cur = None
    if not runs:
        return None
    best = max(runs, key=lambda r: (r[2], r[1] - r[0]))
    return (best[0], best[1]) if best[2] >= MIN_POINTERS else None


def resolve_word(w, by_addr, sorted_addrs, interior=True):
    """('exact', name, 0) | ('interior', name, off) | ('numeric', None, 0)"""
    if not in_rom_range(w):
        return ('numeric', None, 0)
    if w in by_addr:
        return ('exact', pick_name(by_addr[w]), 0)
    if interior:
        k = bisect.bisect_right(sorted_addrs, w) - 1
        if k >= 0 and 0 < w - sorted_addrs[k] <= MAX_INTERIOR_OFFSET:
            return ('interior', pick_name(by_addr[sorted_addrs[k]]),
                    w - sorted_addrs[k])
    return ('numeric', None, 0)


# --------------------------------------------------------------------- verdict
def judge(blob, run, ctx, label):
    """Tier A / Tier B / None, with the numbers that decided it."""
    words = words_of(blob)
    ptrs = [w for w in words[run[0]:run[1]] if in_rom_range(w)]
    k = len(ptrs)
    e7 = sum(1 for w in ptrs if w in ctx['v7'])
    p7 = binom_tail(k, e7, ctx['p0_v7'])
    ev = dict(k=k, e7=e7, p7=p7, e10=0, p10=1.0, inv=None, shifted=False)
    if p7 < P_THRESHOLD:
        return 'A', ev

    a10 = ctx['name2a10'].get(label)
    if a10 is None or (a10 - ROM_BASE) + run[1] * 4 > len(ctx['v10rom']):
        return None, ev
    pairs = []
    for i in range(run[0], run[1]):
        w7 = words[i]
        w10 = struct.unpack_from('<I', ctx['v10rom'], (a10 - ROM_BASE) + i * 4)[0]
        if in_rom_range(w7) and w10 in ctx['v10']:
            pairs.append((w10, w7))
    ev['e10'] = len(pairs)
    ev['p10'] = binom_tail(k, len(pairs), ctx['p0_v10'])
    if len(pairs) >= 2:
        sp = sorted(set(pairs))
        ev['inv'] = sum(1 for i in range(1, len(sp)) if sp[i][1] < sp[i - 1][1])
        ev['shifted'] = any(a != b for a, b in pairs)
    if ev['p10'] < P_THRESHOLD and ev['inv'] == 0 and ev['shifted']:
        return 'B', ev
    return None, ev


# -------------------------------------------------------------------- emission
def emit(blob, run, ctx, label, target, interior=True, remainder='slice'):
    start, end = run
    lines, slices = [], {}
    stem = pathlib.PurePosixPath(target)

    def residue(part, suffix):
        if not part:
            return
        if remainder == 'bytes':
            for off in range(0, len(part), 8):
                lines.append('\t.byte ' + ', '.join(
                    f'0x{b:02x}' for b in part[off:off + 8]))
        else:
            new = f'{stem.parent}/{stem.stem}_{suffix}{stem.suffix}'
            lines.append(f'\t.incbin "{new}"')
            slices[new] = part

    residue(blob[:start * 4], 'head')
    if start and label and f'{label}_PtrTable' not in ctx['v7names']:
        lines.append(f'{label}_PtrTable:')
    for i in range(start, end):
        w = struct.unpack_from('<I', blob, i * 4)[0]
        kind, name, off = resolve_word(w, ctx['v7'], ctx['sa7'], interior)
        if kind == 'exact':
            lines.append(f'\t.long {name}')
        elif kind == 'interior':
            lines.append(f'\t.long {name} + {off}')
        else:
            lines.append(f'\t.long 0x{w:08x}')
    residue(blob[end * 4:], 'tail')
    return lines, slices


def assemble(lines, slices, ctx):
    """Resolve the emitted lines back to bytes. A `.long SYM` is worth exactly
    the address the v7 ELF gives SYM -- if that is not the value the blob held,
    this returns different bytes and --check fails."""
    out = bytearray()
    for line in lines:
        t = line.strip()
        if t.endswith(':'):
            continue
        if t.startswith('.long '):
            e = t[6:].strip()
            if '+' in e:
                base, off = (x.strip() for x in e.split('+', 1))
                out += struct.pack('<I', ctx['name2a7'][base] + int(off, 0))
            elif e.startswith('0x'):
                out += struct.pack('<I', int(e, 16) & 0xFFFFFFFF)
            else:
                out += struct.pack('<I', ctx['name2a7'][e])
        elif t.startswith('.byte '):
            out += bytes(int(x, 16) for x in t[6:].split(','))
        elif t.startswith('.incbin '):
            out += slices[t.split('"')[1]]
        else:
            raise AssertionError(f'unassemblable emitted line: {t!r}')
    return bytes(out)


# -------------------------------------------------------------------- pipeline
def context(args):
    v7 = load_symbols(pathlib.Path(args.symbols) if args.symbols else V7_ELF)
    v10 = load_symbols(V10_ELF)
    name2a7, name2a10, names = {}, {}, set()
    for a, ns in v7.items():
        for n in ns:
            name2a7.setdefault(n, a)
            names.add(n)
    for a, ns in v10.items():
        for n in ns:
            name2a10.setdefault(n, a)
    return dict(v7=v7, v10=v10, sa7=sorted(v7), name2a7=name2a7,
                name2a10=name2a10, v7names=names,
                v7rom=V7_ROM.read_bytes(), v10rom=V10_ROM.read_bytes(),
                p0_v7=symbol_density(v7), p0_v10=symbol_density(v10))


def analyse(args, ctx):
    results = []
    for src, (lines, sites) in collect_sites().items():
        for k, site in enumerate(sites):
            generated = '/includes/generated/' in site['path'].as_posix()
            if generated and not args.include_generated:
                scope_skip = True
            else:
                scope_skip = False
            blob = site['path'].read_bytes()
            run = find_run(words_of(blob))
            if run is None:
                continue
            tier, ev = judge(blob, run, ctx, site['label'])
            row = dict(src=src, site=site, blob=blob, run=run, tier=tier, ev=ev,
                       generated=generated, addr=None, lines=None, slices=None,
                       ok=False, why='')
            if scope_skip:
                row['why'] = 'compiler output from a committed C source -- out of scope'
                row['tier'] = None
                results.append(row)
                continue
            if tier is None:
                row['why'] = 'not proven a pointer table'
                results.append(row)
                continue
            addr = locate(ctx['v7rom'], lines, sites, k)
            if addr is None or ctx['v7rom'][addr - ROM_BASE:
                                            addr - ROM_BASE + len(blob)] != blob:
                row['why'] = 'blob not uniquely locatable in the v7 ROM'
                row['tier'] = None
                results.append(row)
                continue
            row['addr'] = addr
            row['lines'], row['slices'] = emit(
                blob, run, ctx, site['label'], site['target'],
                not args.no_interior, args.remainder)
            rebuilt = assemble(row['lines'], row['slices'], ctx)
            row['ok'] = rebuilt == blob
            row['why'] = '' if row['ok'] else 'BYTE MISMATCH'
            results.append(row)
    return results


def report(results, args):
    conv = [r for r in results if r['tier'] and r['ok']]
    broken = [r for r in results if r['tier'] and not r['ok']]
    whole = [r for r in conv
             if r['run'][0] == 0 and r['run'][1] * 4 == len(r['blob'])]
    part = [r for r in conv if r not in whole]
    kinds = collections.Counter()
    for r in conv:
        for i in range(*r['run']):
            w = struct.unpack_from('<I', r['blob'], i * 4)[0]
            kinds[resolve_word(w, r['_ctx']['v7'], r['_ctx']['sa7'],
                               not args.no_interior)[0]] += 1
    print(f'PROVEN pointer tables in v7 romslices : {len(conv)} files')
    print(f'  Tier A (v7 symbols)                 : '
          f'{sum(1 for r in conv if r["tier"] == "A")}')
    print(f'  Tier B (v10 corroboration)          : '
          f'{sum(1 for r in conv if r["tier"] == "B")}')
    print(f'  byte-identity verified in dry run   : {len(conv)}/{len(conv)+len(broken)}')
    print(f'  wholly a table (blob disappears)    : {len(whole)} files, '
          f'{sum(len(r["blob"]) for r in whole):,} B')
    print(f'  partly a table (residue stays blob) : {len(part)} files, '
          f'{sum((r["run"][1]-r["run"][0])*4 for r in part):,} B of '
          f'{sum(len(r["blob"]) for r in part):,} B')
    print(f'  BYTES LEAVING .incbin FOR .long     : '
          f'{sum((r["run"][1]-r["run"][0])*4 for r in conv):,}')
    print(f'\n  words emitted: {sum(kinds.values()):,}   '
          f'.long Sym {kinds["exact"]:,}   .long Sym+off {kinds["interior"]:,}   '
          f'.long 0x.. {kinds["numeric"]:,}')
    if broken:
        print('\n  ⚠ BYTE MISMATCH (never apply these):')
        for r in broken:
            print(f'    {r["site"]["label"]}')
    if args.list:
        print(f'\n  {"label":38s}{"addr":>10s}{"blob":>8s}{"tier":>5s}'
              f'{"k":>5s}{"e7":>5s}{"e10":>5s}{"p":>10s}')
        for r in sorted(conv, key=lambda r: -(r['run'][1] - r['run'][0])):
            ev = r['ev']
            p = ev['p7'] if r['tier'] == 'A' else ev['p10']
            print(f'  {r["site"]["label"]:38s}{r["addr"]:#010x}'
                  f'{len(r["blob"]):>8d}{r["tier"]:>5s}{ev["k"]:>5d}'
                  f'{ev["e7"]:>5d}{ev["e10"]:>5d}{p:>10.1e}')
    if args.near_misses:
        near = [r for r in results if not r['tier']]
        print(f'\n  NOT PROVEN -- left as .incbin ({len(near)}):')
        print(f'  {"label":38s}{"blob":>8s}{"k":>5s}{"e7":>5s}{"e10":>5s}'
              f'{"inv":>5s}  why')
        for r in sorted(near, key=lambda r: -r['ev']['k']):
            ev = r['ev']
            print(f'  {(r["site"]["label"] or "?"):38s}{len(r["blob"]):>8d}'
                  f'{ev["k"]:>5d}{ev["e7"]:>5d}{ev["e10"]:>5d}'
                  f'{("-" if ev["inv"] is None else ev["inv"]):>5}  {r["why"]}')
    return 1 if broken else 0


def controls(ctx, results):
    """Every number the verdict rests on, next to the null that could sink it."""
    syms = set(ctx['v7'])
    sa = ctx['sa7']
    conv = {r['site']['path'] for r in results if r['tier'] and r['ok']}
    slices = sorted((REPO / 'v7/maincpu/includes/romslices').glob('*.bin'))

    def stat(datas):
        tw = ti = te = 0
        for d in datas:
            ws = words_of(d)
            inr = [w for w in ws if in_rom_range(w)]
            tw += len(ws); ti += len(inr)
            te += sum(1 for w in inr if w in syms)
        return tw, ti, te

    def show(tag, datas):
        tw, ti, te = stat(datas)
        print(f'  {tag:36s} words {tw:7,}  in range {ti:6,} '
              f'({100*ti/max(tw,1):5.1f}%)  exact symbol {te:6,} '
              f'({100*te/max(ti,1):5.1f}% of in-range)')

    rnd = random.Random(20260822)
    print('NEGATIVE CONTROLS -- a criterion that cannot fail is not a pass\n')
    show('converted blobs', [f.read_bytes() for f in slices if f in conv])
    show('every other v7 romslice', [f.read_bytes() for f in slices if f not in conv])
    shuffled = []
    for f in slices:
        if f in conv:
            b = bytearray(f.read_bytes())
            rnd.shuffle(b)
            shuffled.append(bytes(b))
    show('same blobs, bytes shuffled', shuffled)
    vals = [rnd.randrange(ROM_BASE, ROM_BASE + ROM_SIZE) for _ in range(50000)]
    print(f'\n  random in-range address, EXACTLY a v7 symbol : '
          f'{100*sum(1 for v in vals if v in syms)/len(vals):.2f}%   '
          f'(analytic {100*ctx["p0_v7"]:.2f}%)')
    print('  random in-range address, INSIDE a symbol at offset <= N:')
    for n in (4096, 256, 64, 16, 4):
        c = 0
        for v in vals:
            k = bisect.bisect_right(sa, v) - 1
            if k >= 0 and 0 < v - sa[k] <= n:
                c += 1
        print(f'      N = {n:5d} : {100*c/len(vals):5.1f}%')
    print('\n  ⇒ the interior test is near-tautological and is never used for a\n'
          '    verdict here; only exact hits are, and their null is ~1.8%.')
    return 0


def u16_alias_note(blob):
    """Is this blob a 16-bit table that the 32-bit window accepts by accident?

    A u16 table of small values, e.g. the organ/accordion drawbar levels
    0x00f0 0x00f0, reads as the u32 0x00f000f0 -- which is inside
    0x00e00000..0x00ffffff and so scores 64/64 "words in a ROM range" while
    containing no address at all. The signature is byte 1 and byte 3 of every
    in-range word being zero: a real address has a nonzero low half far more
    often than never.
    """
    ws = [blob[i:i + 4] for i in range(0, len(blob) - 3, 4)]
    inr = [w for w in ws
           if in_rom_range(int.from_bytes(w, 'little'))]
    if len(inr) < 4:
        return None
    if all(w[1] == 0 and w[3] == 0 for w in inr):
        return ('16-bit table: every in-range word is 0x00XX00YY, i.e. two u16 '
                'values, not an address')
    return None


def reconcile(ctx, results):
    """Re-derive the triage's PTR_TABLE headline and say what survived.

    Imports l3_slice_structure_triage rather than re-implementing it, so the
    two scripts cannot drift apart and quote different totals.
    """
    import importlib.util
    tri_path = REPO / 'scripts/analysis/l3_slice_structure_triage.py'
    spec = importlib.util.spec_from_file_location('l3triage', tri_path)
    tri = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(tri)
    flagged = [f for f in tri.blobs() if tri.classify(f.read_bytes())[0] == 'PTR_TABLE']
    proven = {r['site']['path']: r for r in results if r['tier'] and r['ok']}

    def conv_bytes(r):
        return (r['run'][1] - r['run'][0]) * 4

    hit = [f for f in flagged if f in proven]
    miss = [f for f in flagged if f not in proven]
    extra = [p for p in proven if p not in set(flagged)]
    print(f'triage PTR_TABLE headline        : {len(flagged)} files, '
          f'{sum(f.stat().st_size for f in flagged):,} bytes')
    print(f'  of those, PROVEN a table       : {len(hit)} files, '
          f'{sum(f.stat().st_size for f in hit):,} blob bytes')
    print(f'    -> convert to .long          : '
          f'{sum(conv_bytes(proven[f]) for f in hit):,} bytes')
    print(f'    -> residue staying a blob    : '
          f'{sum(f.stat().st_size for f in hit) - sum(conv_bytes(proven[f]) for f in hit):,} bytes')
    print(f'  NOT a pointer table            : {len(miss)} files, '
          f'{sum(f.stat().st_size for f in miss):,} bytes')
    for f in sorted(miss):
        r = next((x for x in results if x['site']['path'] == f), None)
        blob = f.read_bytes()
        why = u16_alias_note(blob)
        if why is None:
            if r is not None:
                why = r['why']
            elif find_run(words_of(blob)) is None:
                why = 'no run of pointer-shaped words'
            else:
                why = 'outside this converter (it reads v7 sources only)'
        print(f'      {f.relative_to(REPO)}  ({f.stat().st_size} B)')
        print(f'          {why}')
    print(f'  tables the triage did NOT flag : {len(extra)} files, '
          f'{sum(conv_bytes(proven[p]) for p in extra):,} bytes convert')
    print(f'\n  CORRECTED FIGURE: {len(proven)} files, '
          f'{sum(conv_bytes(r) for r in proven.values()):,} bytes of .incbin '
          f'become .long')
    return 0


def name_conflicts(ctx, results):
    """Which names mean a DIFFERENT routine in v7 than in v10?

    Each proven table gives an index-by-index correspondence: word i of the v7
    table and word i of the v10 table are the same entry. When the v10 word is
    exactly a v10 symbol S, the v7 word is where that routine lives in v7. If v7
    ALSO has a symbol spelled S, but at a different address, the spelling means
    two different things -- and emitting it from the v10 side would have changed
    the ROM. Level L2 requires this set to be empty.
    """
    seen, conflicts = {}, {}
    for r in results:
        if not (r['tier'] and r['ok']):
            continue
        for i in range(*r['run']):
            w7 = struct.unpack_from('<I', r['blob'], i * 4)[0]
            if not in_rom_range(w7):
                continue
            a10 = ctx['name2a10'].get(r['site']['label'])
            if a10 is None:
                continue
            off = (a10 - ROM_BASE) + i * 4
            if off + 4 > len(ctx['v10rom']):
                continue
            w10 = struct.unpack_from('<I', ctx['v10rom'], off)[0]
            for name in ctx['v10'].get(w10, ()):
                seen[name] = w7
                a7 = ctx['name2a7'].get(name)
                if a7 is not None and a7 != w7:
                    conflicts[name] = (a7, w7, a7 - w7, w10)
    def fp(a7, a10, n=64):
        """byte agreement between v7@a7 and v10@a10 -- the same routine in two
        links keeps most of its bytes; an unrelated one does not."""
        x = ctx['v7rom'][a7 - ROM_BASE:a7 - ROM_BASE + n]
        y = ctx['v10rom'][a10 - ROM_BASE:a10 - ROM_BASE + n]
        if len(x) < n or len(y) < n:
            return 0.0
        return sum(1 for i, j in zip(x, y) if i == j) / n

    print(f'names shared with v10 and cross-checked : {len(seen)}')
    print(f'names that mean a DIFFERENT routine in v7: {len(conflicts)}')
    print('\n  fp(name) = v7 bytes at the address the v7 ELF gives the name, vs v10\n'
          '  fp(table) = v7 bytes the table actually points at, vs the same v10 bytes\n'
          '  the table wins whenever fp(table) > fp(name).')
    print(f'\n  {"name":42s}{"v7 ELF":>12s}{"table":>12s}{"delta":>7s}'
          f'{"fp(name)":>10s}{"fp(table)":>10s}')
    wins = 0
    for n, (a7, w7, d, a10) in sorted(conflicts.items(), key=lambda kv: kv[1][0]):
        fn_, ft = fp(a7, a10), fp(w7, a10)
        wins += ft > fn_
        print(f'  {n:42s}{f"{a7:#08x}":>12s}{f"{w7:#08x}":>12s}'
              f'{d:>7d}{fn_:>10.2f}{ft:>10.2f}')
    print(f'\n  the table points at the better match in {wins}/{len(conflicts)} cases')
    return 1 if conflicts else 0


def apply_changes(results):
    per_file = collections.defaultdict(list)
    for r in results:
        if r['tier'] and r['ok']:
            per_file[r['src']].append(r)
    for src, rows in per_file.items():
        lines = src.read_bytes().decode('latin1').splitlines(keepends=True)
        for r in sorted(rows, key=lambda r: -r['site']['line']):
            lines[r['site']['line']] = ''.join(l + '\n' for l in r['lines'])
        src.write_bytes(''.join(lines).encode('latin1'))
        for r in rows:
            for rel, data in (r['slices'] or {}).items():
                (r['site']['path'].parent /
                 pathlib.PurePosixPath(rel).name).write_bytes(data)
        print(f'rewrote {src.relative_to(REPO)}')
    print('\nnow rebuild and confirm compare_roms.py still reports 100.00%')
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--symbols', help='v7 ELF, or a "NAME ADDR" file (default: the v7 ELF)')
    ap.add_argument('--check', action='store_true',
                    help='exit non-zero unless every table round-trips byte for byte')
    ap.add_argument('--controls', action='store_true', help='print the nulls')
    ap.add_argument('--name-conflicts', action='store_true',
                    help='names that mean a different routine in v7 than in v10')
    ap.add_argument('--reconcile', action='store_true',
                    help="re-derive the triage's PTR_TABLE headline and reconcile it")
    ap.add_argument('--list', action='store_true', help='one line per proven table')
    ap.add_argument('--near-misses', action='store_true',
                    help='list what looked like a table and was not proven')
    ap.add_argument('--show', metavar='LABEL', help='print the replacement for one blob')
    ap.add_argument('--no-interior', action='store_true',
                    help='never emit "Sym + off"; use a numeric .long instead')
    ap.add_argument('--remainder', choices=('slice', 'bytes'), default='slice',
                    help='non-table residue: new .incbin slice (default) or .byte lines')
    ap.add_argument('--include-generated', action='store_true',
                    help='also rewrite compiler-generated blobs (do not use)')
    ap.add_argument('--apply', action='store_true', help='REWRITE the sources')
    args = ap.parse_args()

    ctx = context(args)
    results = analyse(args, ctx)
    for r in results:
        r['_ctx'] = ctx
    if args.controls:
        return controls(ctx, results)
    if args.reconcile:
        return reconcile(ctx, results)
    if args.name_conflicts:
        return name_conflicts(ctx, results)
    if args.show:
        for r in results:
            if r['site']['label'] == args.show and r['lines']:
                print(f'{r["site"]["label"]}:\t; v7 {r["addr"]:#08x}, '
                      f'{len(r["blob"])} B, tier {r["tier"]}, byte-identity '
                      f'{"VERIFIED" if r["ok"] else "FAILED"}')
                print('\n'.join(r['lines']))
                return 0
        sys.exit(f'no proven table labelled {args.show}')
    rc = report(results, args)
    if args.apply:
        return apply_changes(results)
    return rc if args.check else 0


if __name__ == '__main__':
    sys.exit(main())
