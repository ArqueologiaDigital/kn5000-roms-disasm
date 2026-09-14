#!/bin/bash
#  dsp_corpus_scan_all.sh -- run dsp_corpus_scan.py over EVERY dumped ROM, in parallel.
#
#  QUESTION IT ANSWERS
#      "Is there a third uPD6383 corpus among the dumped ROMs?"  dsp_corpus_scan.py answers that
#      for ONE file; this sweeps all of them, which is what makes the answer a CENSUS rather than
#      an anecdote.  The negative half is the load-bearing half: four products carrying ZERO is
#      what makes the one product carrying NINE a finding.
#
#  THE NUMBERS IT PRODUCED (2026-09-14, N-INPUT-GATE-OPENED sect. 204):
#      56 files, six products.  kn1500 IC15: 9 STRONG streams @ 0x1A414D..0x1AC18B.
#      kn2400 (2 files), kn6000 (5), kn6500 (5), kn7000 (20): ZERO.
#      kn5000 non-subprogram ROMs (20): ZERO -- the negative control, since the KN5000's
#      microcode is in the subprogram ROMs, which are EXCLUDED here and used as the POSITIVE
#      control by `dsp_corpus_scan.py --control' instead.
#      ★ Felipe then confirmed the chip independently: a D6383GF-3BA at IC3 on the KN1500.
#
#  USAGE
#      ./dsp/tools/dsp_corpus_scan_all.sh [OUTDIR]        # default: a mktemp -d
#      grep -l 'overlaps merged)  *[1-9]' $OUTDIR/*.txt   # the files with hits
#
#  ⚠ ~35 min single-threaded over ~121 MB; PAR=6 brings it to ~10.  Each file gets its own
#    timeout so one pathological ROM cannot stall the sweep.
set -u
ROMS="${ROMS:-$HOME/compartilhado/kn7000_mame_build/roms}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
OUT="${1:-$(mktemp -d)}"
PAR="${PAR:-6}"
mkdir -p "$OUT"

#  The kn5000 subprogram ROMs are the KNOWN carriers -- excluded so that what remains is a clean
#  negative control.  `.asm' and `dir.txt' are not ROMs.
find "$ROMS" -type f -size +4k ! -name '*.asm' ! -name 'dir.txt' \
  | grep -v 'kn5000_subprogram' | sort > "$OUT/files.txt"
echo "scanning $(wc -l < "$OUT/files.txt") files into $OUT (PAR=$PAR)"

scan_one() {
  f="$1"; OUT="$2"; REPO="$3"
  n=$(echo "$f" | sed 's|.*/roms/||; s|/|__|g')
  ( cd "$REPO" && timeout 3000 python3 dsp/tools/dsp_corpus_scan.py --rom "$f" ) \
      > "$OUT/$n.txt" 2>&1
}
export -f scan_one
xargs -a "$OUT/files.txt" -P "$PAR" -I{} bash -c 'scan_one "$@"' _ {} "$OUT" "$REPO"

echo
echo "=== files with STRONG hits ==="
for f in "$OUT"/*.txt; do
  n=$(grep -oP 'overlaps merged\)\s+\K\d+' "$f" 2>/dev/null | tail -1)
  [ -n "${n:-}" ] && [ "$n" -gt 0 ] && printf "  %-58s %3s streams\n" "$(basename "$f" .txt)" "$n"
done
echo
echo "=== per product ==="
for p in kn1500 kn2400 kn5000 kn6000 kn6500 kn7000 wsa1r; do
  tot=0; nf=0
  for f in "$OUT/${p}__"*.txt; do
    [ -f "$f" ] || continue
    nf=$((nf+1))
    n=$(grep -oP 'overlaps merged\)\s+\K\d+' "$f" 2>/dev/null | tail -1)
    tot=$((tot+${n:-0}))
  done
  printf "  %-10s %3d streams across %2d files\n" "$p" "$tot" "$nf"
done
