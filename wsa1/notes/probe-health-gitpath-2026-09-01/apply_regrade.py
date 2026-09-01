#!/usr/bin/env python3
"""Fold a probe_health --regrade result back into the sweep it came from.

WHY: a TIMEOUT is not a grade, it is "the instrument never saw an answer" -- and
on a loaded machine it is the answer you get for a probe that takes minutes.  The
honest repair is to re-run those rows when the machine is quiet and say so, NOT
to widen the timeout until they pass and NOT to call a timeout green.

    python3 apply_regrade.py SWEEP.json REGRADE.json IMAGE OUT.json
    python3 apply_regrade.py --selftest

⚠ It only replaces rows that are present in BOTH files, and it prints every
substitution it makes.  A regrade row that does not join is reported, not
dropped.
"""
import json
import sys


def merge(sweep, regrade, image):
    rows = sweep[image]["rows"]
    new = {tuple(r["argv"]): r for r in regrade[image]["rows"]}
    out, changed, unjoined = [], [], set(new)
    for r in rows:
        k = tuple(r["argv"])
        if k in new:
            unjoined.discard(k)
            if new[k]["grade"] != r["grade"]:
                changed.append((k, r["grade"], new[k]["grade"]))
            out.append(dict(r, grade=new[k]["grade"]))
        else:
            out.append(r)
    return out, changed, sorted(unjoined)


def _selftest():
    sweep = {"x": {"rows": [{"argv": ["a"], "grade": "TIMEOUT"},
                            {"argv": ["b"], "grade": "UNAFFECTED"}]}}
    reg = {"x": {"rows": [{"argv": ["a"], "grade": "UNAFFECTED"},
                          {"argv": ["c"], "grade": "LOUD"}]}}
    out, changed, unjoined = merge(sweep, reg, "x")
    ok = True
    for cond, msg in (
            (len(out) == 2, "the merge keeps exactly the sweep's rows"),
            (out[0]["grade"] == "UNAFFECTED", "a regraded row is replaced"),
            (out[1]["grade"] == "UNAFFECTED", "an untouched row is left alone"),
            (changed == [(("a",), "TIMEOUT", "UNAFFECTED")],
             "every substitution is reported"),
            (unjoined == [("c",)],
             "a regrade row with no sweep row is REPORTED, not silently added")):
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(_selftest())
    sweep_p, reg_p, image, out_p = sys.argv[1:5]
    sweep, reg = json.load(open(sweep_p)), json.load(open(reg_p))
    rows, changed, unjoined = merge(sweep, reg, image)
    for k, a, b in changed:
        print("  %-14s -> %-14s %s" % (a, b, " ".join(k)))
    for k in unjoined:
        print("  ⚠ regrade row not present in the sweep: %s" % " ".join(k))
    json.dump({image: dict(sweep[image], rows=rows)}, open(out_p, "w"), indent=1)
    print("wrote %s (%d rows, %d regraded)" % (out_p, len(rows), len(changed)))
