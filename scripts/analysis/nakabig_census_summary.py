#!/usr/bin/env python3
r"""nakabig_census_summary.py -- census bytes over the `nakabig` lane's files.

QUESTION ANSWERED
-----------------
How many bytes of the three big NAKA blobs (`widget_descriptors.s`,
`naka_widget_tables_1.s`, `naka_widget_tables_2.s`, in v10/v9/v7) does
`scripts/analysis/data_range_census.py` grade KNOWN-A (documented with
evidence), KNOWN-B (descriptive name only), UNKNOWN, research target
(self-admitted / embedded-in-code / no explanation), and how are the
KNOWN-B bytes distributed over labels?  Run it on a census JSON taken before
and after a change to measure the change.

    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json
    python3 scripts/analysis/nakabig_census_summary.py X.json [--top 20]
    python3 scripts/analysis/nakabig_census_summary.py BEFORE.json AFTER.json

"Research target" uses the census's own rule (grade UNKNOWN, or `admits`, or
`embedded_in_code`); see `is_target()` in data_range_census.py.
"""
import argparse
import collections
import json

FILES = ('ui_widgets/widget_descriptors.s', 'ui_widgets/naka_widget_tables_1.s',
         'ui_widgets/naka_widget_tables_2.s')
GRADES = ('CODE', 'KNOWN-A', 'KNOWN-B', 'UNKNOWN', 'FILLER')


def load(path):
    d = json.load(open(path))
    return [r for r in d['regions'] if r['rel'] in FILES]


def is_target(r):
    return r['grade'] == 'UNKNOWN' or r.get('admits') or r.get('embedded_in_code')


def table(regs):
    t = collections.defaultdict(lambda: collections.Counter())
    for r in regs:
        key = (r['image'], r['rel'].split('/')[-1])
        t[key][r['grade']] += r['size']
        if is_target(r):
            t[key]['TARGET'] += r['size']
    tot = collections.Counter()
    for c in t.values():
        tot.update(c)
    return t, tot


def show(path, top):
    regs = load(path)
    t, tot = table(regs)
    print('%s' % path)
    print('  %-5s %-28s %9s %9s %9s %9s %9s' % ('image', 'file', 'KNOWN-A', 'KNOWN-B',
                                                'UNKNOWN', 'FILLER', 'target'))
    for (img, f), c in sorted(t.items()):
        print('  %-5s %-28s %9d %9d %9d %9d %9d' % (img, f, c['KNOWN-A'], c['KNOWN-B'],
                                                    c['UNKNOWN'], c['FILLER'], c['TARGET']))
    print('  %-34s %9d %9d %9d %9d %9d' % ('TOTAL', tot['KNOWN-A'], tot['KNOWN-B'],
                                           tot['UNKNOWN'], tot['FILLER'], tot['TARGET']))
    if top:
        print('  largest KNOWN-B objects (v10):')
        b = sorted((r for r in regs if r['image'] == 'v10' and r['grade'] == 'KNOWN-B'),
                   key=lambda r: -r['size'])
        for r in b[:top]:
            print('    %6d  %-44s %s:%d' % (r['size'], r['label'], r['rel'], r['line'] + 1))
    return tot


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('json', nargs='+')
    ap.add_argument('--top', type=int, default=0)
    a = ap.parse_args()
    tots = [show(p, a.top) for p in a.json]
    if len(tots) == 2:
        print('delta (after - before):')
        for g in ('KNOWN-A', 'KNOWN-B', 'UNKNOWN', 'FILLER', 'TARGET'):
            print('  %-8s %+9d' % (g, tots[1][g] - tots[0][g]))


if __name__ == '__main__':
    main()
