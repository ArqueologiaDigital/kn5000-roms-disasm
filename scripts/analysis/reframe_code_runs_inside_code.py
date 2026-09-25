#!/usr/bin/env python3
r"""Re-frame `.byte` runs wedged INSIDE instruction code, even when an operand holds 0x01/0x04.

QUESTION ANSWERED
    v10_reframe_code_runs.py refuses any span in which a byte 0x01 or 0x04
    lands inside an operand: the backend cannot decode `normal` (0x01) or
    `max` (0x04), so a sweep could swallow one of them and still re-converge.
    That refusal leaves the tree's worst misframes in place -- e.g. the four
    InitFlagBlock tails in ui/ui_playback_modes.s spelled
        .byte 0xc1, 0xac / pushw wa / push xiz / max
    which are one instruction, `or (0x28ac:16), 4` (`ordi8 (10412), 4`).
    A `max` or `normal` in the middle of a routine is itself the implausible
    reading (they switch the CPU's operating mode), so the risk the refusal
    guards against is far smaller than the misframes it keeps.

    This wrapper drops the refusal, but only for label regions that already
    hold instruction statements outside the run: a region made of nothing but
    `.byte` rows (a table -- SetWall_SlotMaskTable, SetWall_SlotOrderTable) is
    not touched, because a linear sweep will happily "decode" a table.  All
    other refusals of the base tool stand (undecodable bytes, strings, lost
    symbols, texts that do not re-encode to the ROM bytes, moved labels), the
    region-end anchor of reframe_code_runs_to_region_end.py applies, and every
    result must be read before it is committed -- the byte gate cannot tell a
    right framing from a wrong one.

RUN (image from KN5000_IMAGE, default v10)
    python3 scripts/analysis/v10_line_address_map.py --image v10 FILES --out /tmp/lm.json
    python3 scripts/analysis/reframe_code_runs_inside_code.py --linemap /tmp/lm.json --report FILES
    python3 scripts/analysis/reframe_code_runs_inside_code.py --linemap /tmp/lm.json --apply FILES
    git diff; make gate
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reframe_code_runs_to_region_end  # noqa: E402,F401  (region-end anchors; patches C.parse)
import v10_byte_run_classifier as C  # noqa: E402
import v10_reframe_code_runs as base  # noqa: E402

_parse = C.parse
SKIPPED = []


def parse_code_regions(path, lm):
    lines, regions = _parse(path, lm)
    keep = []
    for r in regions:
        body = [lines[i - 1].strip() for i in range(r["ln"] + 1, r["end_line"])
                if lines[i - 1].strip() and not lines[i - 1].strip().startswith(";")
                and not C.LABEL_RE.match(lines[i - 1])]
        has_code = any(not b.startswith(".") and not b.startswith(("aligned_string", "naka_header",
                                                                     "addr24"))
                       for b in body if not b.startswith(".byte"))
        # instruction statements other than the misframed run itself: require at
        # least one instruction line that is not adjacent-only noise
        n_ins = sum(1 for b in body if not b.startswith("."))
        n_byte = sum(1 for b in body if b.startswith(".byte"))
        if has_code and n_ins >= 3 and not all(b.startswith(".byte") for b in body):
            keep.append(r)
        elif n_byte:
            SKIPPED.append(r["label"])
    return lines, keep


C.parse = parse_code_regions
base.BLIND = set()

if __name__ == "__main__":
    try:
        base.main()
    finally:
        print("regions left alone (no instruction statements besides the run): %d" % len(SKIPPED))
