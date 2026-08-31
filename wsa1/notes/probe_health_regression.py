#!/usr/bin/env python3
"""Did a round make any probe's health WORSE?  Compare two probe_health JSONs.

WHAT QUESTION THIS ANSWERS
    The lane rule is "keep non-green at or below where you found it".  Two raw
    totals cannot settle that, because a round also ADDS scripts: a run with
    more non-green rows than the baseline may have added five clean ones and
    broken none, or added none and broken five.  The honest test is per
    INVOCATION.

    So this joins the two runs on `argv` -- the exact command probe_health ran --
    and reports three things separately:

      REGRESSED   an invocation in BOTH runs whose grade went from green to
                  non-green.  ★ This is the number the rule is about, and it
                  must be 0.
      IMPROVED    the reverse.
      ADDED/GONE  invocations on one side only.  An ADDED non-green row raises
                  the total without regressing anything, and is reported as its
                  own line rather than folded into the comparison.

    GREEN is `UNAFFECTED`.  `BY-DESIGN` is counted green too and named
    explicitly, because probe_health itself uses it for probes whose subject is
    the layout: grading those non-green would be an instrument artefact.

RUN
    python3 notes/probe_health_regression.py BASE.json NEW.json
    python3 notes/probe_health_regression.py BASE.json NEW.json --image prom_b
Exit status is non-zero if anything REGRESSED.
"""
import json
import sys

GREEN = {"UNAFFECTED", "BY-DESIGN"}


def load(path, image=None):
    d = json.load(open(path))
    if image and image in d:
        d = d[image]
    elif len(d) == 1 and "rows" not in d:
        d = next(iter(d.values()))
    return {tuple(r["argv"]): r["grade"] for r in d["rows"]}


def main():
    argv = sys.argv[1:]
    image = None
    args = []
    i = 0
    while i < len(argv):
        if argv[i] == "--image":
            image = argv[i + 1] if i + 1 < len(argv) else None
            i += 2
            continue
        if argv[i].startswith("--"):
            i += 1
            continue
        args.append(argv[i])
        i += 1
    if len(args) != 2:
        print(__doc__)
        return 2
    base, new = load(args[0], image), load(args[1], image)

    def tally(d):
        out = {}
        for g in d.values():
            out[g] = out.get(g, 0) + 1
        return out

    for name, d in (("base", base), ("new ", new)):
        t = tally(d)
        ng = sum(v for k, v in t.items() if k not in GREEN)
        print(f"{name}: {len(d)} invocations, {len(d) - ng} green, {ng} non-green   "
              + " ".join(f"{k}={v}" for k, v in sorted(t.items())))

    both = set(base) & set(new)
    regressed = [k for k in both if base[k] in GREEN and new[k] not in GREEN]
    improved = [k for k in both if base[k] not in GREEN and new[k] in GREEN]
    changed = [k for k in both if base[k] != new[k] and k not in regressed and k not in improved]
    added = sorted(set(new) - set(base))
    gone = sorted(set(base) - set(new))

    print(f"\nin both runs: {len(both)}")
    print(f"  ★ REGRESSED (green -> non-green): {len(regressed)}")
    for k in sorted(regressed):
        print(f"      {base[k]:14s} -> {new[k]:14s} {' '.join(k)}")
    print(f"  IMPROVED (non-green -> green):   {len(improved)}")
    for k in sorted(improved):
        print(f"      {base[k]:14s} -> {new[k]:14s} {' '.join(k)}")
    print(f"  changed within non-green:        {len(changed)}")
    for k in sorted(changed):
        print(f"      {base[k]:14s} -> {new[k]:14s} {' '.join(k)}")
    print(f"\nADDED since base: {len(added)}  "
          f"({sum(1 for k in added if new[k] not in GREEN)} of them non-green)")
    for k in added:
        print(f"      {new[k]:14s} {' '.join(k)}")
    print(f"GONE since base:  {len(gone)}")
    for k in gone:
        print(f"      {base[k]:14s} {' '.join(k)}")
    return 1 if regressed else 0


if __name__ == "__main__":
    sys.exit(main())
