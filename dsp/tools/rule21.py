#!/usr/bin/env python3
"""§225 T1 -- HOW MUCH OF `28/32/28' IS FREE-RUNNING?  (RULE 21's blast radius)

THE DISCRIMINATOR, and it is forced by the instrument's OWN bucket predicate
(upd6383.cpp :5589):

        const bool nz = (m_in_val[0] != 0) || (m_in_val[1] != 0);

The quiet bucket is not "small input".  It is frames on which the input latch reads
EXACTLY ZERO on both channels -- the SAME value, every frame, 706 040 times.
Therefore:

  D-I  quiet_min == quiet_max  (DEGENERATE quiet range)
       The slot holds ONE value whenever the input is exactly zero, and a different
       one when it is not.  Nothing free-running can do that -- a ramp sampled over
       706 040 frames sweeps.  ==> INPUT-DEPENDENT, PROOF-GRADE.

  D-F  quiet_min != quiet_max  AND  loud range CONTAINED in quiet range
       The slot varies while the input is a literal constant ==> it carries state
       that evolves independently of the input, and the loud bucket reaches NOTHING
       the quiet bucket does not.  ==> FREE-RUNNING; the `*' is RULE 21 exactly.

  D-X  quiet_min != quiet_max  AND  loud reaches outside the quiet range
       Free-running state PLUS extra loud-only reach.  Sub-split:
         X-ramp   extra reach <= 1 % of the quiet span   -- rule-21 endpoint jitter
         X-sign   quiet range never negative, loud goes negative -- a ramp cannot
                  change sign; strong non-ramp evidence
         X-reach  extra reach > 1 % of quiet span        -- real extra excursion

Only D-I is proof-grade input dependence.  D-F is proof-grade FREE-RUNNING.
D-X is the marker being unable to decide, which is what RULE 21 says.
"""
import sys
sys.path.insert(0, sys.path[0] or '.')
from parse104 import parse, RANGES

COLS = ('acc', 'mem', 'L')


def classify(lo_q, hi_q, lo_l, hi_l):
    """Return (class, detail)."""
    if lo_q == hi_q:
        return 'I', ''
    qspan = hi_q - lo_q
    over_lo = max(0, lo_q - lo_l)          # how far loud reaches BELOW quiet
    over_hi = max(0, hi_l - hi_q)          # how far loud reaches ABOVE quiet
    extra = over_lo + over_hi
    if extra == 0:
        return 'F', ''
    tags = []
    if lo_q >= 0 and lo_l < 0:
        tags.append('sign')
    if extra * 100 > qspan:
        tags.append('reach')
    if not tags:
        return 'X-ramp', ''
    return ('X-sign' if 'sign' in tags else 'X-reach'), '+'.join(tags)


def region_report(rows, lo, hi, label, out):
    tot = {c: 0 for c in COLS}
    cls = {}
    for iw in sorted(rows):
        if not (lo <= iw <= hi):
            continue
        r = rows[iw]
        for c in COLS:
            if r[c + 'M'] != '*':
                continue
            tot[c] += 1
            k, det = classify(*r[c])
            cls.setdefault(c, {}).setdefault(k, []).append(iw)
    out.append('  %-9s  %s' % (label, ' | '.join('%s %d' % (c, tot[c]) for c in COLS)))
    for c in COLS:
        d = cls.get(c, {})
        if not d:
            continue
        parts = ['%s=%d' % (k, len(v)) for k, v in sorted(d.items())]
        out.append('      %-4s %-46s  I=%d  FREE(F+X-ramp)=%d  UNDECIDED(X-sign/X-reach)=%d'
                   % (c, ' '.join(parts),
                      len(d.get('I', [])),
                      len(d.get('F', [])) + len(d.get('X-ramp', [])),
                      len(d.get('X-sign', [])) + len(d.get('X-reach', []))))
    return cls


if __name__ == '__main__':
    for path in sys.argv[1:]:
        rows = parse(path)
        out = ['== %s' % path.split('/')[-1]]
        for name, (lo, hi) in RANGES.items():
            region_report(rows, lo, hi, name, out)
        print('\n'.join(out))
        print()
