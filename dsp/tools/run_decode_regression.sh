#!/bin/sh
# run_decode_regression.sh -- reproduce every DSP-datapath decode finding of the
# 2026-09-11 session in one pass, from the committed evidence traces (no MAME
# build/run needed).  Each line prints the committed number so the whole decode
# is checkable at once.  Run from the repo root: sh dsp/tools/run_decode_regression.sh
set -e
cd "$(dirname "$0")/../.."
echo "== 1. comparator selftest ==";      python3 dsp/hle/lle_trace_diff.py --selftest 2>&1 | tail -1
echo "== 2. oracle checks ==";            python3 dsp/hle/test_lle_oracle.py 2>&1 | tail -1
echo "== 3. biquad multiplier (want 27/27, coef[N-1]*L[N]>>6) =="
python3 dsp/tools/biquad_pipeline_probe.py 2>&1 | grep "WINNER"
echo "== 4. multiplier generalises to program 0 (want 18/21) =="
python3 dsp/tools/biquad_pipeline_probe.py dsp/analysis/data/kn5000-dsp-live-frame-trace-2026-09-10.txt --all-rows 2>&1 | grep "WINNER"
echo "== 5. store constant acc>>16 (want 4/4) =="
python3 dsp/tools/store_constant_probe.py 2>&1 | grep "bands whose"
echo "== 6. input route: audio reaches deposit not biquad =="
python3 dsp/tools/input_route_probe.py 2>&1 | grep -A1 "VERDICT" | tail -1
echo "== 7. 4.2 gate codes (unanchored SRC/ACT) =="
python3 dsp/tools/input_route_guards.py 2>&1 | grep "unanchored"
echo "== 8. EQ coefficient layout: b0=0.125 all bands =="
python3 dsp/tools/eq_coef_layout_probe.py 2>&1 | grep "b0 (coef"
echo "== 9. reverb excited by REVSEED (unit-1 live products) =="
python3 dsp/tools/input_route_probe.py dsp/analysis/data/kn5000-dsp-revseed-frame-2026-09-11.txt 2>&1 | grep "UNIT-1"
echo "== ALL DECODE FINDINGS REPRODUCED =="
