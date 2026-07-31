#!/usr/bin/env python3
"""§222 — the `:2914' / `:3491' MODE-1 UNIT-REBASE divergence, censused.

`upd6383.cpp' has THREE places that resolve a mode-1 `addr8' to an index:

    the mode-1 READ        rdsrc  = addr8 | (m_cur_unit1 ? 0x80 : 0)     REBASED
    the mode-1 BIT-4 STORE stdest = addr8 | (m_cur_unit1 ? 0x80 : 0)     REBASED
    the mode-1 ACT-07 STORE d07   = addr8                                NOT rebased

...beneath `store_mode()'s own banner "★★★ §99: one rule for both store sites".
`PREDICT_D0_producer.md' §3.3 found the divergence and could not fix it (read-only lane).

This tool decides it from the ROM corpus, and prints the two facts that settle it:

  1. do body images write mode-1 destinations UNIT-RELATIVE or ABSOLUTE?
     (unit-relative => the hardware must supply the unit bit => REBASE IS CORRECT)
  2. which resident words would actually change if the rebase were applied?
     (none => the unification is provably inert and can ship without an arm)

Usage:  rebase_census.py [<log-with-a-§104-table> ...]
With a log, the RESIDENT-FRAME half is computed from the live image (§104's word
column), which differs from the ROM listing at iw64/iw71 (C-format at run time).
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as D                                          # noqa: E402
import pat_corpus as C                                          # noqa: E402

ROW = re.compile(r'upd6383: +(\d+) ([0-9A-F]{10}) ([0-9A-F]{2}) +(\d+)/(\d+)')


def region(iw):
    return ('kernelA' if iw < 50 else 'kernelB' if iw < 60 else 'EPILOGUE'
            if iw < 84 else 'body0(u0)' if iw < 200 else 'body1(u1)')


def mode(w):
    return 2 if D.c_format(w) else (D.class4(w) & 7)


def esc_dly(w):
    """mask bit 61 (SET in the default) routes these to m_dp, not to addr8."""
    return bool(D.hi12(w) & 0x800) and D.class4(w) == 1


def corpus():
    progs, _meta = C.load()
    bodies = C.bodies(progs)
    act07, bit4 = [], []
    for name, words in bodies.items():
        for i, w in enumerate(words):
            if mode(w) != 1:
                continue
            if D.lo_act(w) == 0x07 and not esc_dly(w):
                act07.append((name, i, w, D.addr8(w)))
            if D.hi12(w) & 0x010:
                bit4.append((name, i, w, D.addr8(w)))
    print(f'=== CORPUS: {len(bodies)} body images ===')
    print('  a body image serves BOTH units (the unit context is supplied at run time),')
    print('  so a mode-1 destination it names must be UNIT-RELATIVE unless the hardware')
    print('  is expected to address unit 1 absolutely from inside a shared image.')
    for tag, rows in (('mode-1 ACT-07 (non-ESC)', act07), ('mode-1 BIT-4', bit4)):
        rel = [r for r in rows if not (r[3] & 0x80)]
        abso = [r for r in rows if r[3] & 0x80]
        print(f'  {tag:24s} n={len(rows):3d}  unit-RELATIVE {len(rel)}  ABSOLUTE {len(abso)}')
        for n, i, w, a in rows:
            print(f'        {n:22s} w{i:<4d} {w:010X}  addr8={a:02X}  '
                  f'{"relative" if not a & 0x80 else "ABSOLUTE"}')
    return act07, bit4


def resident(path):
    rows, inside = {}, False
    with open(path, encoding='utf-8', errors='replace') as fh:
        for ln in fh:
            if '§104 PER-SLOT' in ln:
                inside = True
                continue
            if '§104 SUMMARY' in ln:
                inside = False
            if not inside:
                continue
            m = ROW.search(ln)
            if m and int(m.group(1)) not in rows:
                rows[int(m.group(1))] = int(m.group(2), 16)
    print(f'\n=== RESIDENT FRAME from {os.path.basename(path)}: {len(rows)} slots ===')
    div = 0
    for iw, w in sorted(rows.items()):
        if mode(w) != 1:
            continue
        u1 = iw >= 200
        a = D.addr8(w)
        if D.lo_act(w) == 0x07:
            route = 'm_dp (ESC delay, mask bit 61)' if esc_dly(w) else f'addr8={a:02X}'
            changed = (not esc_dly(w)) and u1 and not (a & 0x80)
            div += changed
            print(f'  ACT-07  iw{iw:3d} {w:010X} {region(iw):11s} {route:30s} '
                  f'rebase changes it: {"YES" if changed else "no"}')
        if D.hi12(w) & 0x010:
            print(f'  BIT-4   iw{iw:3d} {w:010X} {region(iw):11s} addr8={a:02X} -> '
                  f'{a | (0x80 if u1 else 0):02X}  (already rebased)')
    print(f'  ==> resident ACT-07 words the unification would change: {div}')
    return div


if __name__ == '__main__':
    corpus()
    for p in sys.argv[1:]:
        resident(p)
