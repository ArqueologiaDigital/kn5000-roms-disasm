#!/usr/bin/env python3
"""What are the labels that make the converter decline a range?

QUESTION ANSWERED
-----------------
`convert_reachable_ranges.rewrite()` declines a range when a label inside it does
not sit on a decoded instruction boundary. Thirty ranges are refused this way.

⚠ AN EARLIER ANSWER TO THIS QUESTION IS RETRACTED. It claimed 88% of these
labels were "displaced by 0x41A" and that repairing them would open the bucket.
The ROM's own pointer tables contradict that (11 of 11 checkable cases -- see
commit 8998d1b and spec anti-pattern 16), so the explanation is void and the
question was open again.

WHAT THE EVIDENCE NOW SAYS
    313 distinct labels block a range. Cross-checking each label's address
    against every in-range 32-bit value that appears anywhere in the ROM:

        referenced by a value in the ROM :   8
        not referenced                   : 305

    The eight are `WidgetParam_Config_*` in 0x00EE6xxx -- widget configuration
    RECORDS that pointer tables index. So for those the converter is decoding
    DATA as code, and the guard is refusing correctly. That is the opposite of
    a bucket waiting to be unlocked.

    The 305 unreferenced ones are NOT thereby innocent: a label can be a real
    entry point reached only by a `jr` whose bytes are still `.byte` (see
    `v7_unreferenced_labels_are_live.py`). This script separates the cases; it
    does not settle the second group.

A SECOND, STRONGER SIGNAL points the same way: the off-boundary labels CLUSTER.
201 of the 313 sit in a range where THREE OR MORE labels are off-boundary, and
one range has eleven. Eleven independently misplaced labels inside one routine is
not credible; a mis-framed DECODE that disagrees with all of them is. So for most
of this bucket the converter is starting from the wrong offset, and the guard is
the only thing noticing.

⚠ Do not read "the guard refuses N ranges" as "N ranges are waiting". On this
evidence most of it is the guard doing exactly its job, and the honest residue is
much smaller than the raw count suggests.

Run:  python3 scripts/analysis/v7_label_guard_subjects.py
"""
import importlib.util, json, os, struct, sys

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
BASE = 0xE00000


def load(name, path):
    sp = importlib.util.spec_from_file_location(name, os.path.join(REPO, path))
    m = importlib.util.module_from_spec(sp)
    a = sys.argv
    sys.argv = [name]
    try:
        sp.loader.exec_module(m)
    finally:
        sys.argv = a
    return m


def main():
    cr = load("cr", "scripts/converters/convert_reachable_ranges.py")
    spm = load("sp", "scripts/analysis/v7_undisassembled_spans.py")
    rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    idx = cr.source_index(cr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
    terr = spm.territory(spm.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]

    ptr = set()
    for i in range(0, len(rom) - 3):
        w = struct.unpack_from("<I", rom, i)[0]
        if BASE <= w < 0x1000000:
            ptr.add(w)

    seen, rows = set(), []
    for t in sorted(int(x, 16) if isinstance(x, str) else x for x in targets):
        insns = cr.decode_range(rom, terr, t)
        if len(insns) < 3:
            continue
        span = sum(n for _, n, _ in insns)
        ia = {a for a, _, _ in insns}
        for f, (lines, blocks) in idx.items():
            for (l, a, st, e, raw) in blocks:
                if a is None or not (t < a < t + span) or a in ia or a in seen:
                    continue
                seen.add(a)
                rows.append((l, a, a in ptr))

    ref = [r for r in rows if r[2]]
    print(f"  distinct labels blocking a range : {len(rows)}")
    print(f"    referenced by a value in the ROM: {len(ref)}   <- decoding DATA as code")
    print(f"    not referenced                  : {len(rows)-len(ref)}   <- unsettled")
    print("\n  the ROM-referenced ones (the guard is right about these):")
    for l, a, _ in sorted(ref, key=lambda r: r[1]):
        print(f"    {l:46} {a:#010x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
