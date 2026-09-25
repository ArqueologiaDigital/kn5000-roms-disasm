#!/usr/bin/env python3
r"""v10_reframe_code_runs.py, also for `.byte` runs that reach the next label.

QUESTION ANSWERED
    Same as scripts/analysis/v10_reframe_code_runs.py (which `.byte` runs inside
    code re-spell as correctly framed instructions), with one gap closed.

    That tool accepts a run only if the linear sweep re-converges with the
    source framing on BOTH sides, and it looks for the right-hand anchor among
    the addresses of the lines of the run's own label region.  A run that ends
    exactly where the next label starts therefore has no right-hand anchor and
    is refused -- although the next label's address is the strongest anchor
    there is (something references it).  In v7, where whole routines sit in
    `.byte` from one label to the next, that refusal covers most of the bytes.

    This wrapper extends every label region's line range by the next label's
    own line, so the next label's address joins the anchor set.  Nothing else
    changes: the sweep still covers only [label, next label), the splice still
    stops before the next label's line, every emitted text is still assembled
    and compared with the ROM bytes, spans containing strings or losing symbols
    are still refused, and label definitions are still checked unchanged.
    Verify with `make gate` after --apply.

RUN (the image is chosen by KN5000_IMAGE, default v10)
    python3 scripts/analysis/v10_line_address_map.py --image v7 FILES --out /tmp/lm.json
    KN5000_IMAGE=v7 python3 scripts/analysis/reframe_code_runs_to_region_end.py \
        --linemap /tmp/lm.json --report FILES
    KN5000_IMAGE=v7 python3 scripts/analysis/reframe_code_runs_to_region_end.py \
        --linemap /tmp/lm.json --apply FILES
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import v10_byte_run_classifier as C  # noqa: E402
import v10_reframe_code_runs as base  # noqa: E402

_parse = C.parse


def parse_to_next_label(path, lm):
    lines, regions = _parse(path, lm)
    for k in range(len(regions) - 1):
        nxt = regions[k + 1]
        if regions[k]["end_line"] == nxt["ln"] and nxt["ln"] in lm and lm[nxt["ln"]] == regions[k]["end"]:
            regions[k]["end_line"] = nxt["ln"] + 1
    return lines, regions


C.parse = parse_to_next_label

if __name__ == "__main__":
    base.main()
