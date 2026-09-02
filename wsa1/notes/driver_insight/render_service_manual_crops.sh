#!/bin/sh
# Regenerate every service-manual figure cited in
# notes/DRIVER-INSIGHT-wsa1-2026-09-02.md.
#
# WHAT QUESTION IT ANSWERS: "which chip and which address does the SX-WSA1R
# schematic put on each chip-select, and does that agree with the addresses the
# disassembly derived from the firmware alone?"  The document reads these crops
# by eye; this script is the recipe that puts the same pixels in front of the
# next reader, so the reading can be checked rather than trusted.
#
# EXACT COMMAND:
#   sh wsa1/notes/driver_insight/render_service_manual_crops.sh [OUTDIR]
#
# INPUT, and it is NOT in this repository:
#   ~/compartilhado/KN7000/service_manual/SX-WSA1R Service Manual.pdf
#   ORDER NO. EMiD951604, (c) 1995 Matsushita Electric Industrial, 42 pages,
#   image-only (pdftotext returns nothing -- there is no text layer).
# Needs poppler's pdftoppm and python3-pil.
#
# WHAT IS ON WHICH PAGE (1-based, as pdftoppm counts):
#   18  BLOCK Diagram
#   19  MAIN (A)/MB2 P.C. Diagram, sheet II-7/II-8   -- IC1 (MAIN), IC12, IC13
#   20  MAIN (A)/MB2 P.C. Diagram, sheet II-9/II-10  -- IC2 (SUB), IC7 SED1330,
#                                                       IC8 uPD72070, IC17/IC18
#   21  MAIN (B) P.C. Diagram,     sheet II-11/II-12 -- IC3 L7A1429, IC27, IC28,
#                                                       IC21, IC22 flash
#   22  MAIN (B) P.C. Diagram,     sheet II-13/II-14 -- IC4 TC163G250092 tone
#                                                       generator, wave DRAMs
#   23  MAIN (C)/HP P.C. Diagram,  sheet II-15/II-16 -- three uPD6383GF-3BA DSPs
#                                                       and the six wave ROMs
set -e
PDF="${PDF:-$HOME/compartilhado/KN7000/service_manual/SX-WSA1R Service Manual.pdf}"
OUT="${1:-./manual-crops}"
mkdir -p "$OUT"
[ -f "$PDF" ] || { echo "not found: $PDF" >&2; exit 2; }

for p in 19 20 21 22 23; do
    pdftoppm -r 400 -png -f $p -l $p "$PDF" "$OUT/p$p"
done

python3 - "$OUT" <<'PY'
import sys, glob, os
from PIL import Image
out = sys.argv[1]
def crop(page, name, x0, y0, x1, y1):
    src = glob.glob(os.path.join(out, 'p%d-*.png' % page))[0]
    im = Image.open(src); w, h = im.size
    im.crop((int(w*x0), int(h*y0), int(w*x1), int(h*y1))).save(
        os.path.join(out, name))
    print(name)

# --- target 2: which processor is IC1 "MAIN" -------------------------------
crop(19, 'fig1_ic1_main.png',      0.62, 0.18, 0.90, 0.60)
#   IC1 TMP95C061AF MICROCOMPUTER (MAIN); port pin names MSTAT0/MSTAT1/
#   SSTAT0/SSTAT1, LCDOFF, MUTE, MIDI1OUT/IN/SNS, TXD1/RXD1/SCLK1, and the
#   interrupt/handshake names FDMON FDINT FDRST FDTC FDDRQ HDIORDY HDINT SIFINT.
crop(19, 'fig2_ic12_ic13.png',     0.40, 0.55, 0.78, 0.85)
#   IC12 QSIGCWSA1AX (/CE = PROMACS) and IC13 QSIGCWSA1BX (/CE = PROMBCS),
#   4M BIT PROGRAMMED EP ROM, A1..A18 and D0..D15 -- x16, on IC1's bus.
crop(20, 'fig3_ic2_sub.png',       0.15, 0.38, 0.36, 0.80)
#   IC2 TMP95C061AF MICROCOMPUTER (SUB), on the S-prefixed bus
#   (SA0..SA21, SD0..SD15, SCS0/SCS1/SCS2, SRD/SWR/SHWR, SRAS/SCAS),
#   with DSP0CS/DSP1CS/DSPCD and DSPD0..DSPD7 on P70..P77.

# --- target 1: 0x7E0008 and 0x7F0000 on CPU 1 ------------------------------
crop(20, 'fig4_cpu1_decoders.png', 0.015, 0.20, 0.20, 0.62)
#   IC17 D74HC139GS  (1E=CS1, 1DA=A19, 1DB=A20; 2E=CS2, 2DA=A19, 2DB=A20)
#       1Y0 RAMCS  2Y0 EXTCS  2Y2 PROMBCS  2Y3 PROMACS
#   IC18 D74HC138GS  (A=A16, B=A17, C=A18; G1=A19, G2A=G2B=CS0)
#       Y1 LCDCS  Y2 FDDAK  Y3 FDCS  Y4 MIF  Y6 HDCS
#       Y0, Y5, Y7 carry no net name.

# --- target 3: 0x104000 is IC3 L7A1429 -------------------------------------
crop(21, 'fig5_cpu2_decoder.png',  0.29, 0.55, 0.62, 0.86)
#   IC27 D74HC139GS  (1E=SCS0, 1DA=SA14, 1DB=SA15)
#       1Y0 SMIF  1Y1 WFICS  1Y2 KSCS  1Y3 SGCS
#                 (2E=SCS2, 2DA=SA19, 2DB=SA20)
#       2Y1 SFLSHCS  2Y2 PROMDCS  2Y3 PROMCCS; 2Y0 carries no net name.
crop(21, 'fig6_ic3_l7a1429_l.png', 0.60, 0.16, 0.80, 0.80)
crop(21, 'fig7_ic3_l7a1429_r.png', 0.78, 0.16, 0.98, 0.80)
#   IC3 L7A1429 MODELING LSI: four 16-bit DRAM ports M1/M2/S1/S2
#   (A0..A9, NRAS/NCAS/NWE, D0..D15, nets WM1*/WM2*/WS1*/WS2*), host port
#   MD0..MD15 <-> SD0..SD15, NSGCE <- WFICS, NAD <- SA1, NWR <- SWR,
#   NRST <- +5MI, MCK, RQWFI, IOWFI(0..12) -> DWFI0..DWFI12.
crop(22, 'fig8_ic4_tonegen.png',   0.30, 0.15, 0.70, 0.85)
#   IC4 TC163G250092 TONE GENERATOR LSI -- the 0x0010C000 device (SGCS).
PY
echo "crops in $OUT"
