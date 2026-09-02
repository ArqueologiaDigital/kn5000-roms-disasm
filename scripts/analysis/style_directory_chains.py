#!/usr/bin/env python3
"""style_directory_chains.py -- WHICH CHAINS BELONG TO WHICH NAMED STYLE?

QUESTION ANSWERED
-----------------
`docs/accompaniment-style-format.md` establishes the IC19 container (256-byte cells in
doubly-linked chains) and the event grammar, and it names the style directory's only
identified field: a 16-character ASCII name at record+0x40.  Everything else in the
96-byte record is listed as "unidentified".  That left the 1,200 music chains
ANONYMOUS: the exported `.styles` listings identify a chain by its block number and
nothing else, so there was no way to say which music belongs to "GospelRevival".

This script establishes the link, and it exists because the FIRST test of it was
worthless and the null said so.

THE FIRST TEST, AND WHY IT PROVED NOTHING
-----------------------------------------
Take the five candidate pointers, resolve each with the documented rule
`block = (v & 0x0FFF) + first_cell_block_of_section`, and ask how many land on a chain
HEAD.  Result: 1,200 of 1,200, a perfect 100%.

  NULL: draw the same number of uniformly random values from the same block range
  those values span.  Result: 1,200 of 1,200.  ALSO 100%.

Chain heads are DENSE in the cell region, so "resolves to a chain head" carries no
information at all.  A test that a random number passes is not a test.

THE TEST THAT DOES WORK -- two properties a random pointer cannot have
----------------------------------------------------------------------
1. STRUCTURE.  The five u16 fields at record +0x00, +0x04, +0x06, +0x08 and +0x0A are
   a CONSECUTIVE ASCENDING RUN -- v, v+1, v+2, v+3, v+4 -- in 240 of 240 records, and
   in 232 of them the run continues directly from the previous record's last value.
   (Field +0x02 is zero in every record.)  Under the null above this has probability
   ~(1/range)^4 per record.

2. SELECTIVITY, which is the discriminating one.  The corpus holds two shapes of chain
   head: 1,200 real linked cells (`byte[0] == 0x80`) and 818 unlinked single-block
   template slots (`byte[0] == 0x00`, the second marker documented in
   docs/accompaniment-style-format.md).  The directory's 1,200 pointers name
   **all 1,200 of the linked chains and 0 of the 818 template blocks** -- an exact
   partition.

   NULL: a pointer landing at random on a chain head would hit a template block
   818/2018 = 40.5% of the time.  Observing 0 of 1,200 has probability 0.595 ** 1200.

   ⚠ A ZERO IS A POINTER HERE.  The first version of this script skipped zero-valued
   slots as "absent" and reported 1,199 named chains with one -- Composer image block
   0x014 -- unnamed.  It was not unnamed: the pointer rule is
   `block = (v & 0x0FFF) + base`, so `v = 0` addresses the section's FIRST cell block,
   and the Composer bank's section nibble is 0 (unlike IC19's, which is section+1) so
   its first pointer is literally 0x0000.  Filtering zeros discarded exactly one real
   pointer and manufactured exactly one phantom gap.  Do not reintroduce the filter.

WHAT THIS DOES NOT CLAIM
------------------------
* Nothing about what the OTHER 0x40..0x5F fields of the record are.
* Nothing about what the five slots MEAN musically.  Five chains per record is
  consistent with the five accompaniment parts a KN-series style has (intro,
  variations, fill, ending) but this script has no evidence for the ORDER, so
  `style_to_midi.py` names its tracks "slot 0".."slot 4" and invents no part names.
* The record grouping is irregular -- 79 distinct names over 240 records, one name
  covering 23 records and 50 covering one each -- so a name is not a style identity.
  `--names` prints the grouping rather than a tidied version of it.

USAGE
-----
  python3 scripts/analysis/style_directory_chains.py            # the evidence table
  python3 scripts/analysis/style_directory_chains.py --names    # name -> records
  python3 scripts/analysis/style_directory_chains.py --gaps     # the exceptions
  python3 scripts/analysis/style_directory_chains.py --selftest # the claims, asserted

Run from the repository root.
"""
import argparse
import os
import random
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, 'scripts', 'build'))
import style_events as SE  # noqa: E402

PTR_SLOTS = (0x00, 0x04, 0x06, 0x08, 0x0A)
NAME_OFF, NAME_LEN, REC_SIZE, DIR_OFF, N_RECS = 0x40, 0x10, 96, 0x60, 30


def banks():
    """Yield (bank, data, dir_start, base, chains) for every style directory."""
    for bank, d in SE.sources():
        for s, e in SE.hk_sections(d):
            cells = SE.cells_of(d, s, e)
            if not cells:
                continue
            base = cells[0] >> 8
            yield bank, d, s, base, SE.chains_of(d, cells, base)


def records():
    """Yield (bank, rec_index, name, [chain head offsets], data, base)."""
    for bank, d, s, base, _chains in banks():
        for r in range(N_RECS):
            rec = s + DIR_OFF + r * REC_SIZE
            if rec + REC_SIZE > len(d):
                break
            name = d[rec + NAME_OFF:rec + NAME_OFF + NAME_LEN]
            name = name.decode('latin-1').replace('\x00', ' ').strip()
            ptrs = [d[rec + k] | (d[rec + k + 1] << 8) for k in PTR_SLOTS]
            heads = [((v & 0x0FFF) + base) * 256 for v in ptrs]
            yield bank, r, name, ptrs, heads, d, base


def evidence(seed=7):
    """-> a dict of every number this script's docstring quotes."""
    n_rec = n_consec = n_follow = 0
    named, heads80, heads00 = set(), set(), set()
    naive_hits = naive_tot = null_hits = null_tot = 0
    rng = random.Random(seed)
    for bank, d, s, base, chains in banks():
        for c in chains:
            h = c[0]
            (heads80 if d[h] == 0x80 else heads00).add((bank, h))
        heads = {c[0] for c in chains}
        prev = None
        # the naive test and its null, over the five POINTER SLOTS -- the same values
        # the real test uses, so the null is drawn from the same range they span.
        vals_all = []
        for r in range(N_RECS):
            rec = s + DIR_OFF + r * REC_SIZE
            if rec + REC_SIZE > len(d):
                break
            ptrs = [d[rec + k] | (d[rec + k + 1] << 8) for k in PTR_SLOTS]
            vals_all += list(ptrs)
            if all(v == 0 for v in ptrs):
                continue
            n_rec += 1
            if all(ptrs[i + 1] == ptrs[i] + 1 for i in range(4)):
                n_consec += 1
            if prev is not None and ptrs[0] == prev + 1:
                n_follow += 1
            prev = ptrs[-1]
            for v in ptrs:
                named.add((bank, ((v & 0x0FFF) + base) * 256))
        resolved = [((v & 0x0FFF) + base) * 256 for v in vals_all]
        naive = [o for o in resolved if o in heads]
        naive_hits += len(naive)
        naive_tot += len(resolved)
        if vals_all:
            lo = min(v & 0xFFF for v in vals_all)
            hi = max(v & 0xFFF for v in vals_all)
            for _ in range(len(vals_all)):
                null_tot += 1
                if (rng.randint(lo, hi) + base) * 256 in heads:
                    null_hits += 1
    return dict(n_rec=n_rec, n_consec=n_consec, n_follow=n_follow,
                named=named, heads80=heads80, heads00=heads00,
                naive_hits=naive_hits, naive_tot=naive_tot,
                null_hits=null_hits, null_tot=null_tot)


def cmd_report():
    e = evidence()
    n80, n00 = len(e['heads80']), len(e['heads00'])
    print("THE NAIVE TEST -- 'the value resolves to a chain head'")
    print(f"  directory u16s that resolve to a chain head : "
          f"{e['naive_hits']}/{e['naive_tot']} "
          f"({100 * e['naive_hits'] / e['naive_tot']:.1f}%)")
    print(f"  NULL, uniform random in the same block range: "
          f"{e['null_hits']}/{e['null_tot']} "
          f"({100 * e['null_hits'] / e['null_tot']:.1f}%)")
    print("  -> the null passes too.  Chain heads are dense; this test is worthless.\n")
    print("TEST 1 -- the five pointer slots are a consecutive ascending run")
    print(f"  records with a nonzero pointer group        : {e['n_rec']}")
    print(f"  five slots form v, v+1, v+2, v+3, v+4       : {e['n_consec']}")
    print(f"  and continue from the previous record's last: {e['n_follow']}\n")
    print("TEST 2 -- selectivity between the two chain-head shapes")
    print(f"  chain heads, byte[0]==0x80 (linked chains)  : {n80}")
    print(f"  chain heads, byte[0]==0x00 (template slots) : {n00}")
    print(f"  named by a directory pointer               : {len(e['named'])}")
    print(f"    of which linked chains                   : "
          f"{len(e['named'] & e['heads80'])}")
    print(f"    of which template slots                  : "
          f"{len(e['named'] & e['heads00'])}")
    print(f"  linked chains left unnamed                 : "
          f"{len(e['heads80'] - e['named'])}")
    p = n00 / (n80 + n00)
    print(f"  NULL: a random chain head is a template slot {100 * p:.1f}% of the time,"
          f"\n        so 0 of {n80} is (1 - {p:.3f}) ** {n80}, i.e. indistinguishable"
          f" from zero.")


def cmd_names():
    from collections import defaultdict
    by = defaultdict(list)
    for bank, r, name, _p, _h, _d, _b in records():
        by[(bank, name)].append(r)
    print(f"{len(by)} (bank, name) pairs over "
          f"{sum(len(v) for v in by.values())} records:\n")
    for (bank, name), rs in by.items():
        print(f"  {bank:28s} {name!r:24s} records {rs}")


def cmd_gaps():
    e = evidence()
    miss = e['heads80'] - e['named']
    print(f"linked chains named by no directory pointer: {len(miss)}")
    for bank, off in sorted(miss):
        print(f"  {bank} block 0x{off >> 8:03X}")
    seen, dup = {}, []
    for bank, r, name, ptrs, heads, _d, _b in records():
        for k, h in zip(PTR_SLOTS, heads):
            key = (bank, h)
            if key in seen:
                dup.append((key, seen[key], (r, k, name)))
            seen[key] = (r, k, name)
    print(f"\nchain heads named by more than one record slot: {len(dup)}")
    for (bank, off), a, b in dup:
        print(f"  {bank} block 0x{off >> 8:03X}: record {a[0]} slot +0x{a[1]:02X} "
              f"({a[2]!r})  and  record {b[0]} slot +0x{b[1]:02X} ({b[2]!r})")


def cmd_selftest():
    e = evidence()
    assert e['n_rec'] == 240, e['n_rec']
    assert e['n_consec'] == 240, e['n_consec']
    assert e['n_follow'] == 232, e['n_follow']
    assert len(e['heads80']) == 1200, len(e['heads80'])
    assert len(e['heads00']) == 818, len(e['heads00'])
    assert len(e['named']) == 1200, len(e['named'])
    assert len(e['named'] & e['heads80']) == 1200
    assert len(e['named'] & e['heads00']) == 0
    assert len(e['heads80'] - e['named']) == 0
    # the naive test and its null must BOTH be ~100%, which is the point of keeping it
    assert e['naive_hits'] == e['naive_tot'], (e['naive_hits'], e['naive_tot'])
    assert e['null_hits'] == e['null_tot'], (e['null_hits'], e['null_tot'])
    print("selftest OK -- 240/240 consecutive runs; 1200 named chains, all linked, "
          "0 template slots; 0 unnamed; naive test and its null both 100%")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--names', action='store_true')
    ap.add_argument('--gaps', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.names:
        cmd_names()
    elif a.gaps:
        cmd_gaps()
    elif a.selftest:
        cmd_selftest()
    else:
        cmd_report()


if __name__ == '__main__':
    main()
