#!/usr/bin/env python3
"""lying_pseudo_check.py -- the regression check for "a spelling whose text lies".

QUESTION
    Does any assembler def or alias of the TLCS900 backend encode bytes that
    MAME's unidasm reads as a DIFFERENT register width (size_lies.py) or a
    DIFFERENT operation (pseudo_ops.py) than its spelling names -- beyond the
    defs already known and listed in the baselines?

    bcb142d6ee97 and 6190fbfdb816 deleted every def found that way (the
    second one after the wave 3a V1 panel showed the first was incomplete).
    This makes the finding repeatable: it runs the whole-def assembler sweep
    (asm_sweep.py: every MC def and InstAlias, representative operands,
    assembled alone, read by unidasm), then size_lies.py and pseudo_ops.py, and
    compares the defs they flag with the committed baselines:

      out/size_lies_baseline.txt   expected EMPTY since 6190fbfdb816
      out/pseudo_ops_baseline.txt  defs pseudo_ops.py flags that are NOT lies:
                                   its name -> operation map is heuristic
                                   (`cpda8` is cp, `stda16` is ld, `pushw_erp`
                                   is push ...), and raw-operand pseudos are
                                   flagged for OUT-OF-RANGE probe values (a raw
                                   `0xe4` bit number masks into another
                                   operation) -- the masking class, deferred
                                   (TOOLCHAIN_VERSION UPDATE 17 "masked
                                   immediates").  Each line names the def.

    A def flagged now and absent from its baseline is a NEW lie (or a new
    false positive to look at and, if so, add to the baseline with a reason).
    A baseline def no longer flagged is reported as an improvement.

RUN (any directory; needs MAME's unidasm and dasm900.cpp, see v1a_sweep.py)
    LLVM=~/compartilhado/llvm-project
    $LLVM/build/bin/llvm-tblgen --dump-json -I $LLVM/llvm/include \
        -I $LLVM/llvm/lib/Target/TLCS900 $LLVM/llvm/lib/Target/TLCS900/TLCS900.td \
        -o $TMPDIR/records.json
    RECORDS=$TMPDIR/records.json MC=... OBJDUMP=... \
        python3 notes/wave3a-toolchain-probes/fixround/lying_pseudo_check.py

Exit 0 = nothing new; 1 = a def not in a baseline (listed).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.join(os.path.dirname(HERE), "out")


def flagged(script):
    r = subprocess.run([sys.executable, os.path.join(HERE, script)], capture_output=True,
                       text=True, cwd=HERE)
    if r.returncode:
        sys.exit("%s failed:\n%s" % (script, r.stderr[-2000:]))
    return {l.split()[0]: l for l in r.stdout.splitlines() if l.strip()}


def baseline(name):
    p = os.path.join(OUTDIR, name)
    if not os.path.exists(p):
        return set()
    return {l.split()[0] for l in open(p) if l.strip() and not l.startswith("#")}


def main():
    r = subprocess.run([sys.executable, os.path.join(HERE, "asm_sweep.py")],
                       capture_output=True, text=True, cwd=HERE)
    if r.returncode:
        sys.exit("asm_sweep.py failed:\n" + r.stderr[-2000:])
    print(r.stdout.strip().splitlines()[0])
    new = 0
    for script, base in (("size_lies.py", "size_lies_baseline.txt"),
                         ("pseudo_ops.py", "pseudo_ops_baseline.txt")):
        got = flagged(script)
        known = baseline(base)
        fresh = sorted(set(got) - known)
        gone = sorted(known - set(got))
        print("%-14s flagged %3d  in baseline %3d  NEW %d  no longer flagged %d" % (
            script, len(got), len(known & set(got)), len(fresh), len(gone)))
        for d in fresh:
            print("  NEW  " + got[d])
        for d in gone:
            print("  gone " + d)
        new += len(fresh)
    sys.exit(1 if new else 0)


if __name__ == "__main__":
    main()
