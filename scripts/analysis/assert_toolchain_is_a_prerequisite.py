#!/usr/bin/env python3
"""Assert that changing the assembler rebuilds every image.

QUESTION THIS ANSWERS
    If `llvm-mc` changes, does `make all` rebuild the ROM objects -- or does the
    byte-identity gate silently compare objects built by a *previous* assembler?

WHY IT EXISTS
    On 2026-09-01 the gate was green while four KN5000 images did not assemble
    at all: their objects listed only the root .s file, never the assembler, so
    a toolchain change rebuilt nothing and the gate compared week-old artifacts.
    The KN5000 Makefile was repaired then.  The WSA1R Makefile was not, and on
    2026-09-02 the same defect was still live there: with the assembler touched,
    `make -n` rebuilt 0 of 4 WSA1R images.

HOW IT DECIDES
    Touch the assembler, ask each Makefile `make -n all`, and count how many
    assembler invocations it plans.  An image whose object does not name the
    assembler as a prerequisite plans zero, and is reported as a failure.

    This is a dry run -- it builds nothing and changes no object.

RUN
    python3 scripts/analysis/assert_toolchain_is_a_prerequisite.py
    python3 scripts/analysis/assert_toolchain_is_a_prerequisite.py --selftest

    --selftest strips the prerequisite back out of a scratch copy of each
    Makefile and requires the check to FAIL on it.  A check that cannot go red
    is not evidence, and this one has a green history it did not deserve.
"""
import argparse
import os
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]

# (label, makefile dir, how many images that Makefile builds)
TREES = [
    ("KN5000", ROOT, 8),
    ("SX-WSA1R", ROOT / "wsa1", 4),
]


def planned_assembler_runs(makefile_dir, assembler, makefile=None):
    """Count assembler invocations `make -n all` plans, with `assembler` fresh."""
    os.utime(assembler, None)
    cmd = ["make", "-n", "all", f"LLVM_MC={assembler}"]
    if makefile is not None:
        cmd[1:1] = ["-f", str(makefile)]
    out = subprocess.run(
        cmd, cwd=makefile_dir, capture_output=True, text=True,
    ).stdout
    return sum(1 for line in out.splitlines() if str(assembler) in line)


def strip_prerequisite(makefile_text):
    """Undo the repair: remove $(LLVM_MC) from every object rule."""
    return re.sub(r"(^rebuilt_ROMs/\S+\.llvm\.o:.*?) \$\(LLVM_MC\)",
                  r"\1", makefile_text, flags=re.M)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--assembler", default=None,
                    help="assembler to use as the changed file "
                         "(default: the tree's pinned llvm-mc)")
    ap.add_argument("--selftest", action="store_true",
                    help="require the check to fail on a Makefile with the "
                         "prerequisite removed")
    args = ap.parse_args()

    assembler = pathlib.Path(
        args.assembler or ROOT.parent / "llvm-project/build/bin/llvm-mc")
    if not assembler.exists():
        sys.exit(f"no assembler at {assembler}")

    failures = []
    for label, d, expected in TREES:
        planned = planned_assembler_runs(d, assembler)
        ok = planned >= expected
        print(f"  {label:<10} {planned}/{expected} images rebuild when the "
              f"assembler changes   {'ok' if ok else 'STALE-RISK'}")
        if not ok:
            failures.append(
                f"{label}: {expected - planned} image(s) would be compared "
                f"stale after a toolchain change")

    if args.selftest:
        print("\n  --selftest: the same check against the defect it guards")
        for label, d, expected in TREES:
            broken = strip_prerequisite((d / "Makefile").read_text())
            with tempfile.NamedTemporaryFile(
                    "w", dir=d, prefix=".Makefile.selftest.",
                    delete=False) as fh:
                fh.write(broken)
                tmp = pathlib.Path(fh.name)
            try:
                planned = planned_assembler_runs(d, assembler, makefile=tmp)
            finally:
                tmp.unlink()
            if planned >= expected:
                failures.append(
                    f"SELFTEST {label}: removing the prerequisite did not "
                    f"reduce the count ({planned}) -- this check is blind")
                print(f"    {label:<10} {planned}/{expected}   CHECK IS BLIND")
            else:
                print(f"    {label:<10} {planned}/{expected}   "
                      f"goes red as it must")

    if failures:
        print("\nFAIL:")
        for f in failures:
            print(f"  {f}")
        return 1
    print("\nPASS: a toolchain change rebuilds every image in both trees.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
