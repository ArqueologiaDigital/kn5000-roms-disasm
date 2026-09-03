#!/usr/bin/env python3
"""Is "133 of 133 factory records read ORIGINAL" a fact about the machine?

QUESTION THIS ANSWERS
    The claim that RESONATOR TYPE is a UI preset the chip never sees was
    supported by "133 of 133 factory records read ORIGINAL". That number is
    correct -- and it is computed over a population that EXCLUDES the tones most
    likely to disagree with it.

    `dev104_topology_probe.py`'s strict filter keeps 133 records for a property
    of their ELEMENT BLOCKS. That filter happens to drop every tone using
    RESO MODE, which lives in bits 6:7 of the very byte whose bits 0:5 are
    RESONATOR TYPE. So the statistic was taken on the subset least able to
    contradict it.

    Over the full 459-record set the answer is 455/459: four records carry a
    NON-ZERO resonator type (1, 14, 32, 63), and 28 carry a non-zero RESO MODE.

WHAT SURVIVES AND WHAT DOES NOT
    ⚠ The CONCLUSION survives -- the editor still expands a family into thirty
    coefficients and the chip is still never told which family it is; that rests
    on the packer, not on this count.
    ⚠ The SUPPORTING STATISTIC does not. "133 of 133" implies a uniformity the
    full set does not have, and it was published on the documentation website.
    Quote 455/459 over the loose set, or say plainly which subset a filtered
    figure describes.

★ THE GENERAL POINT, which is why this is a committed script and not a one-off:
  a filter written for one purpose becomes a POPULATION when someone else quotes
  a rate through it. Always report the denominator's definition next to the rate,
  and prefer the widest population the claim is actually about.

RUN
    python3 wsa1/notes/resonator_type_population_check.py
    python3 wsa1/notes/resonator_type_population_check.py --selftest
"""
import collections
import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
PROBE = HERE / "w21_lsi_gate_and_keyscaling.py"


def _load():
    spec = importlib.util.spec_from_file_location("g", PROBE)
    m = importlib.util.module_from_spec(spec)
    saved, sys.argv = sys.argv, ["g", "--quiet"]
    try:
        spec.loader.exec_module(m)
    except SystemExit:
        pass
    finally:
        sys.argv = saved
    return m


def census(pop):
    types, modes, n = collections.Counter(), collections.Counter(), 0
    for _name, recs in pop:
        for r in recs:
            n += 1
            types[r[0x0B] & 0x3F] += 1
            modes[r[0x0B] & 0xC0] += 1
    return types, modes, n


def main(selftest=False):
    m = _load()
    fails = []
    rows = []
    for label, pop in (("strict (the filter)", m._tone_records(True)),
                       ("loose (all tones)", m._tone_records(False))):
        types, modes, n = census(pop)
        orig = types.get(0, 0)
        rows.append((label, len(pop), n, orig, types, modes))
        print(f"  {label:<20} {len(pop):>4} tones  {n:>4} records   "
              f"ORIGINAL {orig}/{n} = {100*orig/n:.1f}%")
        print(f"      RESONATOR TYPE bits 0:5  {dict(sorted(types.items()))}")
        print(f"      RESO MODE      bits 6:7  {dict(sorted(modes.items()))}")

    (_, _, ns, origs, _, modes_s) = rows[0]
    (_, _, nl, origl, typel, _) = rows[1]

    print()
    print(f"  the published figure was {origs}/{ns}; over the full set it is "
          f"{origl}/{nl}")
    if origs != ns:
        fails.append("strict set is no longer uniform -- re-read the claim")
    if origl == nl:
        fails.append("full set is uniform too -- the bias finding would be void")
    if set(modes_s) != {0}:
        fails.append("strict set contains a non-zero RESO MODE -- filter changed")

    if selftest:
        print("\n  --selftest: the check must be able to fail")
        print(f"    strict RESO MODE values {sorted(modes_s)} -- if this ever "
              f"contains a non-zero, the exclusion no longer holds and the")
        print( "    finding must be re-derived rather than assumed")
        non_original = {k: v for k, v in typel.items() if k}
        ok = bool(non_original)
        print(f"    non-ORIGINAL types in the full set: {non_original}   "
              f"{'ok -- the subset really did hide these' if ok else 'NONE -- no bias'}")
        if not ok:
            fails.append("selftest")

    if fails:
        print(f"\nFAIL: {fails}")
        return 1
    print("\nPASS: the filtered figure is uniform; the full population is not.")
    return 0


if __name__ == "__main__":
    sys.exit(main("--selftest" in sys.argv))
