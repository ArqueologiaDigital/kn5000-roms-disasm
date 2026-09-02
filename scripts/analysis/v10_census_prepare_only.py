#!/usr/bin/env python3
"""v10_census_prepare_only.py -- run v9_v10_undisassembled_census.py's --prepare
stage for ONE tag instead of all three.

QUESTION ANSWERED
  What is the exact ROM address and source file:line of every literal `.byte`
  run in the v10 maincpu image?  (The census's own --prepare answers that, but
  it loops over TAGS = v7, v9, v10 and aborts the whole run if ANY tag fails to
  assemble.  MEASURED 2026-09-02 in lane V10AUDIO: v7's tree in this branch does
  not assemble under the pinned llvm-mc -- `lda XSP,(XSP+0x008e)` is rejected --
  so the v10 markers, which do not depend on v7 at all, were unobtainable.)

  This wrapper overrides the module-level TAGS tuple and nothing else, so the
  marker injection, the byte-identity assert against original_ROMs/, and the
  nm-based marker extraction are the census's own code, unmodified.

RUN
    python3 scripts/analysis/v10_census_prepare_only.py <workdir> [tag ...]
      default tag: v10
  Then the normal census stages work against that workdir:
    python3 scripts/analysis/v9_v10_undisassembled_census.py --census v10 --work <workdir>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import v9_v10_undisassembled_census as C

work = sys.argv[1]
tags = tuple(sys.argv[2:]) or ("v10",)
C.TAGS = tags
C.prepare(work)
