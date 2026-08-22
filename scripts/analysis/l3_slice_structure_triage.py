#!/usr/bin/env python3
"""l3_slice_structure_triage.py -- do the "no-source slice" .incbin blobs actually LACK
a better human-readable form, or has nobody looked?

QUESTION ANSWERED
-----------------
`audit_incbin_legitimacy.py` reports "0 illegitimate blob bytes", but 790 of its 873
directives are justified by ONE rule:

    (('generated/', 'romslices/'), 'generated or committed no-source slice')

That is a PATH-PREFIX test. A blob counts as legitimate because of the directory it
sits in -- not because anyone showed no better representation exists. For those 790 the
check CANNOT FAIL, which makes it a bookkeeping statement, not a measurement.

The completeness spec asks for something stronger: a binary include is justified only if
it is a true binary that lacks any better/high-level human-readable format. This script
tests each blob against that standard by looking for STRUCTURE, and reports what it
finds so the residue can be worked rather than assumed.

WHAT IT MEASURES (per blob, in priority order)
    PADDING       >= 99% one repeated byte  -- representable as a directive, not a file
    TEXT          >= 90% printable ASCII    -- belongs in .ascii, and IS greppable
    PTR_TABLE     >= 75% of 4-byte LE words land in a known ROM range
    WORD_TABLE    >= 75% of 2-byte LE words inside a narrow band (a lookup table)
    SPARSE        >= 60% zero bytes with structure -- usually a table with holes
    HIGH_ENTROPY  >= 7.5 bits/byte -- compressed or already-encoded; a codec may exist
    OPAQUE        none of the above -- the only class that EARNS "no better format"

⚠ This is a TRIAGE, not a verdict. A PTR_TABLE hit means "worth a human look", not
"proven to be a pointer table". The point is to replace an unfalsifiable path check with
a ranked, checkable list. Every claim it makes is per-blob and re-derivable.

⚠ NEGATIVE CONTROL: --control runs the same classifier over 623 same-sized blobs of
os.urandom. A classifier that flags structure in random bytes is measuring nothing. The
control must come out ~100% OPAQUE/HIGH_ENTROPY.

Run:  python3 scripts/analysis/l3_slice_structure_triage.py
      python3 scripts/analysis/l3_slice_structure_triage.py --control
      python3 scripts/analysis/l3_slice_structure_triage.py --list PTR_TABLE
"""
import collections, math, os, pathlib, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
DIRS = ('romslices', 'generated')
# Load bases actually used by this project's ROMs.
ROM_RANGES = ((0xE00000, 0x1000000), (0x200000, 0x300000), (0x000000, 0x100000))


def entropy(b):
    if not b:
        return 0.0
    c = collections.Counter(b)
    n = len(b)
    return -sum((v / n) * math.log2(v / n) for v in c.values())


def classify(b):
    n = len(b)
    if n == 0:
        return 'EMPTY', ''
    top, cnt = collections.Counter(b).most_common(1)[0]
    if cnt / n >= 0.99:
        return 'PADDING', f'{cnt}/{n} = 0x{top:02x}'
    printable = sum(1 for x in b if 32 <= x < 127 or x in (9, 10, 13))
    if printable / n >= 0.90:
        return 'TEXT', f'{100*printable//n}% printable'
    if n >= 16:
        words = [struct.unpack_from('<I', b, i)[0] for i in range(0, n - 3, 4)]
        hits = sum(1 for w in words if any(lo <= w < hi for lo, hi in ROM_RANGES))
        if words and hits / len(words) >= 0.75:
            return 'PTR_TABLE', f'{hits}/{len(words)} words in a ROM range'
    if n >= 8:
        hw = [struct.unpack_from('<H', b, i)[0] for i in range(0, n - 1, 2)]
        if hw:
            span = max(hw) - min(hw)
            if span and span <= 0x2000 and len(set(hw)) > 2:
                return 'WORD_TABLE', f'{len(hw)} u16 within span 0x{span:x}'
    zeros = b.count(0)
    if zeros / n >= 0.60:
        return 'SPARSE', f'{100*zeros//n}% zero'
    e = entropy(b)
    if e >= 7.5:
        return 'HIGH_ENTROPY', f'{e:.2f} bits/byte'
    return 'OPAQUE', f'{e:.2f} bits/byte'


def blobs():
    """The blobs the .incbin DIRECTIVES name -- not everything in the directory.

    ⚠ An earlier version globbed the directories instead. That swept in `.o` files
    the build had just written, and crashed on one the concurrent `make` deleted
    mid-scan. Worse, it was answering the wrong question: the audit counts
    DIRECTIVES, so the set under test is the set of files those directives include.
    """
    import re as _re
    inc = _re.compile(r'\.incbin\s+"([^"]+)"')
    out, seen = [], set()
    for s_ in sorted(REPO.rglob('*.s')):
        rel = s_.relative_to(REPO).as_posix()
        if rel.startswith('archive/'):
            continue
        for line in s_.read_bytes().decode('latin1').splitlines():
            if line.lstrip().startswith(';'):
                continue
            m = inc.search(line)
            if not m:
                continue
            tgt = m.group(1)
            if not any(f'{d}/' in tgt for d in DIRS):
                continue          # other categories have their own justification
            f = _resolve(s_, tgt)
            if f is not None and f not in seen:
                seen.add(f)
                out.append(f)
    return out


def _resolve(src, tgt):
    """Resolve an .incbin target the way the ASSEMBLER does, not the way a naive
    reader does.

    ⚠ THIS WAS A REAL BUG AND IT PRODUCED A REAL WRONG NUMBER. The first version
    used `src.parent / tgt`. But llvm-mc resolves .incbin against the include
    root passed with -I (here the per-ROM assembly root, e.g. `v7/maincpu`), NOT
    against the directory of the file containing the directive. Every directive
    sitting in a SUBDIRECTORY -- which is most of them -- resolved to a path that
    does not exist, and the script then silently skipped it because it tested
    `f.is_file()`. 283 of 288 romslices targets vanished that way, and the survivors
    were exactly the 5 directives that happen to live in the root .s file. That
    produced the false report "only 5 blobs are committed as binary, 120 bytes",
    when the true figure is 288 files and 136,775 bytes.

    The lesson is the one this project keeps relearning: a lookup that silently
    drops what it cannot resolve reports a clean, small, WRONG answer.
    """
    cand = (src.parent / tgt)
    if cand.is_file():
        return cand.resolve()
    # walk up from the containing file to find the include root that has it
    for up in src.parents:
        c = up / tgt
        if c.is_file():
            return c.resolve()
        if up == REPO:
            break
    return None


def main():
    if '--control' in sys.argv:
        real = [f.stat().st_size for f in blobs()]
        items = [(f'random-{i}', os.urandom(s)) for i, s in enumerate(real)]
        label = 'NEGATIVE CONTROL (os.urandom, same size distribution)'
    else:
        items = [(str(f.relative_to(REPO)), f.read_bytes()) for f in blobs()]
        label = 'no-source-slice blobs'

    want = sys.argv[sys.argv.index('--list') + 1] if '--list' in sys.argv else None
    kinds, bytes_by = collections.Counter(), collections.Counter()
    rows = []
    for name, data in items:
        k, why = classify(data)
        kinds[k] += 1
        bytes_by[k] += len(data)
        rows.append((k, len(data), name, why))

    print(f'{label}: {len(items)} files, {sum(len(d) for _, d in items):,} bytes\n')
    print(f'  {"class":<13}{"files":>7}{"bytes":>12}   meaning')
    MEAN = {
        'PADDING': 'a directive would say this better than a file',
        'TEXT': 'belongs in .ascii and should be greppable',
        'PTR_TABLE': 'addresses -- should be symbols, not bytes',
        'WORD_TABLE': 'a lookup table with a shape',
        'SPARSE': 'structured with holes; worth a look',
        'HIGH_ENTROPY': 'compressed/encoded -- a codec may already exist',
        'OPAQUE': 'EARNS "no better format" on this evidence',
        'EMPTY': 'zero-length',
    }
    for k, c in kinds.most_common():
        print(f'  {k:<13}{c:>7}{bytes_by[k]:>12,}   {MEAN.get(k,"")}')

    earned = bytes_by['OPAQUE'] + bytes_by['HIGH_ENTROPY']
    tot = sum(bytes_by.values())
    print(f'\n  justified as true-binary on evidence: {earned:,} / {tot:,} bytes'
          f'  ({100*earned/tot:.1f}%)')
    print(f'  carrying structure a better format would expose: {tot-earned:,} bytes')

    if want:
        print(f'\n--- {want} ---')
        for k, n, name, why in sorted(rows, key=lambda r: -r[1]):
            if k == want:
                print(f'  {n:>8,}  {name}   [{why}]')


if __name__ == '__main__':
    main()
