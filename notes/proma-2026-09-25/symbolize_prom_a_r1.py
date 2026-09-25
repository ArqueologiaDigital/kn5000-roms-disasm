#!/usr/bin/env python3
r"""The shared branch symboliser, with ONE guard relaxed for prom_a: a call into
prom_b does not make a block "incoherent".

QUESTION THIS ANSWERS
    scripts/converters/symbolize_numeric_branches.py refuses (R1) every numeric
    branch of a small block (< 24 instructions) that contains ANY branch whose
    target is mid-line or outside the image.  For prom_a "outside the image"
    is mostly prom_b: CPU 1's program is one 1 MiB address space whose low half
    (0xF00000-0xF7FFFF) is prom_b, and prom_a calls its routine directory
    thousands of times.  So a routine that calls one prom_b thunk had all its
    prom_a-internal branches refused -- 274 sites at the time of writing.

    This runs the shared tool UNCHANGED except for that rule: an external
    target inside 0xF00000-0xF7FFFF no longer poisons its block; a mid-line
    target, or an external target anywhere else, still does.  Every other guard
    (R2 fragment, R3 absurd neighbourhood, R5 second-decoder disagreement, R6
    text/pointer table, never-taken `jr f`) runs as before, and --verify still
    re-mirrors the tree and requires the image to equal the dump.

    It is a wrapper, not a fork: it loads the shared script's source, asserts
    the one statement it replaces is present verbatim, and executes the result
    with the same command line.

RUN
    python3 notes/proma-2026-09-25/symbolize_prom_a_r1.py --image prom_a --only prom_a/wsa1_prom_a.s [--apply --verify]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SHARED = os.path.join(ROOT, "scripts", "converters", "symbolize_numeric_branches.py")

OLD = '''        if tkind(s["target"]) != "boundary":
            bad_blocks.add(s["block"])'''
NEW = '''        _tk = tkind(s["target"])
        if _tk == "mid" or (_tk == "external" and not (
                img["key"] == "prom_a" and 0xF00000 <= s["target"] < 0xF80000)):
            bad_blocks.add(s["block"])'''

src = open(SHARED).read()
assert src.count(OLD) == 1, "the shared symboliser changed; re-check this wrapper"
src = src.replace(OLD, NEW)
g = {"__name__": "__main__", "__file__": SHARED}
sys.argv[0] = SHARED
exec(compile(src, SHARED, "exec"), g)
