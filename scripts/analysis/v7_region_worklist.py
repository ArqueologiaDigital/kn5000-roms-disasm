#!/usr/bin/env python3
"""v7_region_worklist.py -- turn v9_v10_undisassembled_census.py's --judge v7
"797 regions, 247,603 B" verdict into an ORDERED, per-region conversion
worklist with its own corroboration attached, so lane V7CODE2 can convert
best-corroborated-first instead of by size alone.

v7_judged_call_corroboration.py already asked "does this AGGREGATE of 797
regions behave like code" (yes, 75% of call targets resolve). This script
asks the same question PER REGION -- exactly the finer-grained check the
debt inventory and the census's own header demand ("treat the figure as
sound in aggregate and each individual region as needing its own check")
-- and adds the two other independent-of-the-rule signals judge() already
computes (ends-on-ret/reti/jp) plus a NEW one: whether the region ALSO
survives looks_like_a_table_tail() (imported from fill_verified_islands.py)
scored against ITS OWN window, since that check generalizes beyond the
island shape it was written for -- a fixed-width DATA record whose tail
happens to look CODE-like via the db/per/ramp/dist rule is exactly the
2026-09-02 incident's shape, and a >=64B region is not immune to it just
because it is bigger than an island.

For every region the JSON worklist records:
    addr, size, file, src_line (nearest byteblob marker, the census's own
        hint -- NOT necessarily the region's true start, see
        convert_interrupted_region.rewind_to_true_start), n_calls,
        n_call_hits, ends_ok, table_tail_reject, first (opening
        disassembly text for a human skim)

Regions are sorted by a simple priority tuple, strongest evidence first:
    (n_calls > 0 and n_call_hits == n_calls,   # every call target resolves
     n_call_hits,                              # more corroborating hits
     ends_ok,                                  # a real return/branch closes it
     size)

RUN
    python3 scripts/analysis/v7_region_worklist.py --work WORKDIR [--out FILE]
"""
import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000

CALL_ABS_RE = re.compile(r'^\s*([0-9a-f]+):\s+(?:[0-9a-f]{2} )+\s*call\s+(?:[A-Z]+,)?0x([0-9a-f]+)\s*$', re.I)
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
END = re.compile(r'^(ret|reti|retd|jp\b|jrl?\s+T,)', re.I)


def load_symbols():
    path = os.path.join(REPO, 'symbols', 'maincpu_v7_symbols_reference.txt')
    syms = {}
    for line in open(path):
        if line.startswith('#') or not line.strip():
            continue
        parts = line.split()
        if len(parts) != 2:
            continue
        name, addr = parts
        try:
            syms[int(addr, 16)] = name
        except ValueError:
            continue
    return syms


def import_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--out', default=None)
    ap.add_argument('--minsize', type=int, default=64)
    a = ap.parse_args()

    census = import_module('census', os.path.join(HERE, 'v9_v10_undisassembled_census.py'))
    sys.path.insert(0, os.path.join(REPO, 'scripts', 'converters'))
    fvi = import_module('fvi', os.path.join(REPO, 'scripts', 'converters', 'fill_verified_islands.py'))

    terr, blobs, regs, rom = census.load('v7', a.work)
    tmp = tempfile.NamedTemporaryFile(suffix='.bin', delete=False).name
    syms = load_symbols()

    worklist = []
    for r in regs:
        if r['size'] < a.minsize:
            continue
        m = census.metrics(rom, r['start'], r['size'], tmp)
        if not census.rule(m):
            continue
        open(tmp, 'wb').write(rom[r['start']:r['end']])
        out = subprocess.run([UNI, tmp, '-arch', 'tlcs900', '-basepc', hex(BASE + r['start'])],
                             capture_output=True, text=True).stdout
        calls = set()
        lines = [l.strip() for l in out.split('\n') if DASM.match(l.strip())]
        for line in lines:
            cm = CALL_ABS_RE.match(line)
            if cm:
                calls.add(int(cm.group(2), 16))
        n_hits = sum(1 for c in calls if c in syms)
        endok = False
        if lines:
            mm = DASM.match(lines[-1])
            endok = (int(mm.group(1), 16) - BASE + len(mm.group(2).split()) == r['end']) \
                and bool(END.match(mm.group(3).strip()))
        ttr = fvi.looks_like_a_table_tail(rom, r['end'], tmp)
        worklist.append({
            'addr': r['start'] + BASE, 'size': r['size'],
            'file': r['src']['file'], 'src_line': r['src']['line'],
            'n_calls': len(calls), 'n_call_hits': n_hits,
            'ends_ok': endok, 'table_tail_reject': ttr,
            'first': ' ; '.join(l.split(None, 2)[-1] for l in lines[:3]),
        })

    def prio(w):
        clean = w['n_calls'] > 0 and w['n_call_hits'] == w['n_calls']
        return (-int(clean), -w['n_call_hits'], -int(w['ends_ok']), -w['size'])

    worklist.sort(key=prio)
    out_path = a.out or os.path.join(a.work, 'v7_region_worklist.json')
    json.dump(worklist, open(out_path, 'w'), indent=1)
    n_ttr = sum(1 for w in worklist if w['table_tail_reject'])
    n_clean = sum(1 for w in worklist if w['n_calls'] > 0 and w['n_call_hits'] == w['n_calls'])
    print(f"{len(worklist)} regions >= {a.minsize} B in worklist "
          f"({sum(w['size'] for w in worklist):,} B)")
    print(f"  {n_clean} regions have >=1 call, ALL resolving to pre-existing names")
    print(f"  {n_ttr} regions ALSO flagged by looks_like_a_table_tail "
          f"(their own tail window looks like a fixed-width DATA record --"
          f" treat as suspect even if calls resolve)")
    print(f"wrote {out_path}")


if __name__ == '__main__':
    main()
