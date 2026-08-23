#!/usr/bin/env python3
"""Transitive closure of v7 code reachability over BRANCH destinations.

QUESTION ANSWERED: `v7_reachable_from_code.py` scans the already-disassembled
CODE territory for `call`/`jp`/`jrl` encodings and stops. That is one iteration
of a fixpoint. Every range the converter accepts is newly-proven code, and the
branches inside it name further addresses that are code by exactly the same
argument. This walks that to a fixpoint and writes the expanded entry set.

WHY IT IS SOUND
---------------
A branch destination is only as trustworthy as the decode it came from, so a
destination is harvested ONLY from a range that passes every structural gate the
converter applies (>=3 instructions, ends in a terminator or exactly at a code
boundary, no branch landing mid-instruction). A misframed decode's "branches"
can be data bytes that happen to read as `jr`, and those are excluded and
counted separately.

Destinations already in CODE territory are dropped -- they are expressed
already. Only destinations still carried as `.byte` are new work.

⚠ This does NOT make the entries correct by itself. It makes them CANDIDATES
with an argument. The byte-match gate (`scripts/analysis/assert_byte_identical.py`)
remains the thing that decides whether a conversion is right.

⚠ Territory encoding is 1 = CODE, 2 = `.byte`, 3 = incbin. An earlier probe of
mine used 0 for DATA, matched nothing, and reported a confident zero.

Run:  python3 scripts/analysis/v7_branch_closure.py [--dump]
"""
import argparse, importlib.util, json, os, sys, collections

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
REPO = os.path.abspath(REPO)
sys.path.insert(0, REPO); os.chdir(REPO)
BASE = 0xE00000
DATA, CODE, INCBIN = 2, 1, 3
OUT = "analysis/v7-reachability/v7_branch_closure_targets.json"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", action="store_true", help=f"write {OUT}")
    ap.add_argument("--max-rounds", type=int, default=12)
    a = ap.parse_args()

    _s = importlib.util.spec_from_file_location(
        "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
    crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
    spec = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()

    seed = set(json.load(open(
        "analysis/v7-reachability/v7_call_targets.json"))["targets"])

    def terr_at(x):
        o = x - BASE
        return terr[o] if 0 <= o < len(terr) else None

    def accepted(t, insns):
        if len(insns) < 3:
            return False
        span = sum(n for _, n, _ in insns)
        o, run = t - BASE, 0
        while o + run < len(terr) and terr[o + run] == DATA:
            run += 1
        last = insns[-1][2].strip()
        if (last.split()[0].lower() not in crr.TERMINATORS
                and not crr.UNCOND_JUMP.match(last) and span != run):
            return False
        addrs = {x for x, _n, _t in insns}
        for _a, _n, x in insns:
            m = crr.BRANCH_RE.match(x.strip())
            if m:
                tg = int(m.group(3), 16)
                if t <= tg < t + span and tg not in addrs:
                    return False
        return True

    known, frontier, rounds = set(seed), set(seed), []
    prov = collections.defaultdict(set)
    rejected_from_refused = set()
    for rnd in range(a.max_rounds):
        found = set()
        for t in sorted(frontier):
            if terr_at(t) != DATA:
                continue
            insns = crr.decode_range(rom, terr, t)
            ok = accepted(t, insns)
            span = sum(n for _, n, _ in insns)
            for _a2, _n2, x in insns:
                m = crr.BRANCH_RE.match(x.strip())
                if not m:
                    continue
                tg = int(m.group(3), 16)
                if t <= tg < t + span or terr_at(tg) != DATA:
                    continue
                if not ok:
                    rejected_from_refused.add(tg); continue
                if tg not in known:
                    found.add(tg)
                prov[tg].add(t)
        new = found - known
        rounds.append({"round": rnd + 1, "frontier": len(frontier), "new": len(new)})
        print(f"  round {rnd+1}: frontier {len(frontier):5} -> {len(new):4} new entries")
        if not new:
            break
        known |= new
        frontier = new

    rejected_from_refused -= known
    print()
    print(f"  seed (call targets)                    : {len(seed)}")
    print(f"  after closure                          : {len(known)}   (+{len(known)-len(seed)})")
    print(f"  withheld (only seen in refused ranges) : {len(rejected_from_refused)}")

    if a.dump:
        json.dump({
            "generated_by": "scripts/analysis/v7_branch_closure.py --dump",
            "seed_file": "analysis/v7-reachability/v7_call_targets.json",
            "seed_count": len(seed),
            "rounds": rounds,
            "withheld_seen_only_in_refused_ranges": sorted(rejected_from_refused),
            "targets": sorted(known),
        }, open(OUT, "w"), indent=1)
        print(f"\n  wrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
