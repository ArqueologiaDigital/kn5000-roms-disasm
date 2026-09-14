#!/usr/bin/env bash
# render_pinout_pages.sh -- regenerate the page images the µPD6383GF pinout was read from.
#
# QUESTION IT ANSWERS: "where did upd6383-pinout.md's numbers come from, and can I check them?"
#
#   ./render_pinout_pages.sh [OUTDIR]
#
# The SX-WSA1R service manual is an IMAGE-ONLY scan -- pdftotext returns nothing from it, which
# has caused two false negatives on this project.  Everything in upd6383-pinout.md was read from
# these renders by eye.  400 dpi is the lowest setting at which the two-digit pin numbers inside
# the boxes are unambiguous; at 200 the 3/8 and 6/8 pairs are not.
#
# PAGE 23 = sheet II-15/II-16, MAIN (C)/HP: carries IC5, IC30 and IC6, all three µPD6383GF-3BA.
#           IC30 is the one drawn complete and uncrowded -- it is the source for every pin.
# PAGE 24 = sheet II-17/II-18: the delay DRAMs on IC5/IC6, the four main-board PCM1702U DACs,
#           and connectors CN11/CN14 to the SY-ES1 output expansion board.
set -euo pipefail
SM="${SM:-$HOME/compartilhado/KN7000/service_manual/SX-WSA1R Service Manual.pdf}"
OUT="${1:-$(mktemp -d)}"
mkdir -p "$OUT"
[ -f "$SM" ] || { echo "service manual not found: $SM" >&2; exit 1; }

for p in 23 24; do
    pdftoppm -f $p -l $p -r 400 -png -gray "$SM" "$OUT/hi$p"
done

#  The crops that were actually read, as (left, top, right, bottom) in 400 dpi page pixels.
#  A page is 6617 x 4678 at this setting.
python3 - "$OUT" <<'PY'
import sys, os
from PIL import Image
out = sys.argv[1]
CROPS = {
    "hi23-23.png": {                      # IC30, the complete chip
        "ic30_left":  (3400, 2700, 3760, 3450),   # pins  81-100  GF/RQ/P-S/WRITE/READ/D0-7/SETRDY
        "ic30_right": (4380, 2740, 4760, 3420),   # pins  31-50   EROF/MD1-4/EOSC/SEL/XI/XO/RAS/CAS/WE/A0-A4
        "ic30_top":   (3450, 2600, 4650, 2810),   # pins  51-80   A5-A16, VDD, GND, I/O1-16
        "ic30_bot":   (3450, 3330, 4650, 3560),   # pins   1-30   CS/C-D/SCK/SI/SO/.../TEST
        "gf_trace":   (2950, 2700, 3520, 3300),   # where GF1-3 and RQ1-3 actually go
    },
    "hi24-24.png": {
        "cn14":       (3650, 1075, 4030, 1880),   # CN11 + CN14, the SY-ES1 connectors
    },
}
for page, crops in CROPS.items():
    src = os.path.join(out, page)
    if not os.path.exists(src):
        continue
    im = Image.open(src)
    for name, box in crops.items():
        c = im.crop(box)
        #  Upscale so the 6-8 pt schematic text is readable without a viewer's zoom.
        c.resize((c.width * 3, c.height * 3)).save(os.path.join(out, name + ".png"))
        print("wrote", name + ".png", box)
PY
echo "=== images in $OUT"
