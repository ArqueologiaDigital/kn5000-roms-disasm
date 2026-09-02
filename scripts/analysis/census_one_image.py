#!/usr/bin/env python3
"""census_one_image.py -- run the undisassembled census for ONE image.

QUESTION ANSWERED
  What are the current --census figures for a single image, without paying
  for the other two?

  v9_v10_undisassembled_census.py prepares and censuses every tag in its
  TAGS tuple. For v7 work that is wasteful: v9 and v10 are at their floor,
  and a full three-image prepare is the slow part. This restricts TAGS to
  the one image asked for and times each phase.

RUN
    python3 scripts/analysis/census_one_image.py [tag] [workdir]
      tag      v7 (default), v9 or v10
      workdir  scratch directory for the census's intermediate files
               (default: ./census-work). It holds regenerable artefacts
               only -- nothing here is a result.

⚠ THE FIGURES THIS PRINTS COME FROM THE SHARED CENSUS, and its known
  limits apply unchanged: v7 calibrates as HIGH RISK for this measure
  (DATA-control false-positive rates of 15.7%/11.7% against v9's
  1.0%/0.2%, because v7 is only ~30% CODE and heavily fragmented), so the
  aggregate is sound while each individual region still needs its own
  corroboration before conversion.
"""
import sys, time, os

TAG = sys.argv[1] if len(sys.argv) > 1 else "v7"
_here = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(_here))
os.chdir(REPO)
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import v9_v10_undisassembled_census as c

c.TAGS = (TAG,)
work = sys.argv[2] if len(sys.argv) > 2 else os.path.join(REPO, "census-work")
os.makedirs(work, exist_ok=True)

t0 = time.time(); c.prepare(work); print(f"prepare done in {time.time()-t0:.1f}s")
t0 = time.time(); c.census(TAG, work); print(f"census done in {time.time()-t0:.1f}s")
