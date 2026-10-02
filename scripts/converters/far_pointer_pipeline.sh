#!/bin/sh
# far_pointer_pipeline.sh -- name the targets of the C compiler's far-pointer pushes.
#
# `pushw 0x00e4 / pushw 0x5126` passes the pointer 0xe45126.  This runs, in order:
#   1. symbolize_far_pointer_pushes.py  pairs whose pointer has a symbol -> `Sym@hi16 / Sym@lo16`
#   2. split_blobs_at_far_pointers.py   strings / pointer tables INSIDE an .incbin slice get a
#                                       label (and positional `.set` aliases on them retire)
#   3. symbolize_far_pointer_pushes.py  again, for the pairs step 2 made exact
#   4. label_far_pointer_lines.py       a pointer at the START of a data line outside any slice
#                                       (`.include`d strings, `.long` tables) labels that line
#   5. symbolize_far_pointer_pushes.py  again
# with a `make all` before each step, because every step reads the image's linked ELF.
# Needs an assembler with `@hi16`/`@lo16` (TOOLCHAIN_VERSION UPDATE 20).  Changes no byte:
# run `make gate-all` afterwards.  Reports go to $OUT (default: $TMPDIR/far-pointer-pipeline).
set -e
cd "$(git rev-parse --show-toplevel)"
OUT=${OUT:-${TMPDIR:-/tmp}/far-pointer-pipeline}
mkdir -p "$OUT"
C=scripts/converters
make all >"$OUT/make1.log" 2>&1
make wsa1 >"$OUT/make1w.log" 2>&1
for i in v10 v9 v7 hdae5000 prom_a; do
  python3 $C/symbolize_far_pointer_pushes.py --image $i --apply --report "$OUT/pass1_$i.json"
done
make all >"$OUT/make2.log" 2>&1
python3 $C/split_blobs_at_far_pointers.py --image v10 --apply --report "$OUT/split_v10.json"
for i in v9 v7; do                    # same piece, same name as v10 (cross-version diff hygiene)
  python3 $C/split_blobs_at_far_pointers.py --image $i --apply --report "$OUT/split_$i.json" \
    --names-from "$OUT/split_v10.json"
done
make all >"$OUT/make3.log" 2>&1
for i in v10 v9 v7; do
  python3 $C/symbolize_far_pointer_pushes.py --image $i --apply --report "$OUT/pass2_$i.json"
done
make all >"$OUT/make4.log" 2>&1
for i in v10 v9 v7 hdae5000 prom_a; do
  python3 $C/label_far_pointer_lines.py --image $i --apply --report "$OUT/lines_$i.json"
done
make all >"$OUT/make5.log" 2>&1
for i in v10 v9 v7 hdae5000 prom_a; do
  python3 $C/symbolize_far_pointer_pushes.py --image $i --apply --report "$OUT/pass3_$i.json"
done
