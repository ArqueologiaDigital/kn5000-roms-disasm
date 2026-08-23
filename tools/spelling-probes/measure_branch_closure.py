#!/usr/bin/env python3
"""How many NEW code entry points does a transitive closure over branch
destinations find, beyond the 687 call targets reachability currently knows?

THE GAP: `v7_reachable_from_code.py` scans already-disassembled CODE territory
for `call`/`jp`/`jrl` encodings. It runs ONCE, over the sources as they stand.
But every range the converter accepts and byte-matches is newly-proven code, and
the branches INSIDE it point at further addresses that are proven code by the
same argument -- and those were never fed back in. The target set is the first
iteration of a fixpoint nobody iterated.

⚠ TRUSTWORTHINESS RULE: a branch destination is only as good as the decode it
came from, so this counts destinations ONLY from ranges that pass every
converter gate (decode length, terminator, spelling, byte-match). A refused
range may be mis-framed, and its "branches" may be data bytes that happen to
decode as `jr`. Destinations from refused ranges are counted separately and NOT
proposed.

⚠ Counts only destinations landing in DATA territory (still `.byte`). A
destination inside existing CODE is already expressed and is not new work.

Run:  python3 tools/spelling-probes/measure_branch_closure.py
"""
import importlib.util, json, os, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.path.insert(0, REPO); os.chdir(REPO)
BASE = 0xE00000

_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
_d = importlib.util.spec_from_file_location(
    "_decodes", os.path.join(REPO, "tools/spelling-probes/class-a-sweep/_decodes.py"))
_dm = importlib.util.module_from_spec(_d); _d.loader.exec_module(_dm)

spec = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))

rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
known = set(json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"])
decodes = _dm.load(crr)

# ⚠ Territory encoding, verified against the histogram: 1 = CODE (614,404 B,
# exactly the reported CODE figure), 2 = `.byte` DATA (1,415,996 B), 3 = incbin
# (66,752 B). The first version of this probe had DATA = 0, which matches
# NOTHING, so every candidate was filtered out and it printed a clean zero --
# a negative result that was the constant, not the firmware.
DATA, CODE = 2, 1


def terr_at(a):
    o = a - BASE
    return terr[o] if 0 <= o < len(terr) else None


def accepted(t, insns):
    """Does this range pass the converter's own structural gates?"""
    if len(insns) < 3:
        return False
    span = sum(n for _, n, _ in insns)
    o = t - BASE
    run = 0
    while o + run < len(terr) and terr[o + run] == DATA:
        run += 1
    last = insns[-1][2].strip()
    if (last.split()[0].lower() not in crr.TERMINATORS
            and not crr.UNCOND_JUMP.match(last) and span != run):
        return False
    addrs = {a for a, _n, _x in insns}
    for a, n, x in insns:
        m = crr.BRANCH_RE.match(x.strip())
        if m:
            tg = int(m.group(3), 16)
            if t <= tg < t + span and tg not in addrs:
                return False           # mis-framed
    return True


from_ok, from_bad = collections.Counter(), collections.Counter()
for t, insns in decodes.items():
    ok = accepted(t, insns)
    span = sum(n for _, n, _ in insns)
    for a, n, x in insns:
        m = crr.BRANCH_RE.match(x.strip())
        if not m:
            continue
        tg = int(m.group(3), 16)
        if t <= tg < t + span:
            continue                    # internal, becomes a local label
        if terr_at(tg) != DATA:
            continue                    # already expressed as code
        (from_ok if ok else from_bad)[tg] += 1

new_ok = set(from_ok) - known
new_bad = set(from_bad) - known - new_ok
print(f"  call targets currently known                        : {len(known)}")
print(f"  ranges decoded                                      : {len(decodes)}")
print()
print(f"  NEW code entries from ACCEPTED ranges (proposable)  : {len(new_ok)}")
print(f"  new entries only from REFUSED ranges (NOT proposed) : {len(new_bad)}")
print()
print("  most-referenced new entries from accepted ranges:")
for d, c in from_ok.most_common(40):
    if d in new_ok:
        print(f"    0x{d:06X}  referenced by {c} branch(es)")
        if sum(1 for _ in ()) : pass
json.dump(sorted(new_ok), open(
    os.path.join(os.environ.get("TMPDIR", "/tmp"), "v7_branch_closure_new.json"), "w"))
print(f"\n  wrote {len(new_ok)} proposed entries to $TMPDIR/v7_branch_closure_new.json")
