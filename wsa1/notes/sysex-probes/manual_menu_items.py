#!/usr/bin/env python3
"""Re-extract the SX-WSA1 owner's manual pages that name user-facing settings.

QUESTION THIS ANSWERS
    "What does the published Technics documentation call each per-part / global
    setting, and on which printed page?"  Every user-facing NAME quoted in the
    System Exclusive reference document should be traceable to a page printed by
    this probe, not to firmware reasoning.

SOURCES (read-only, not in this repo -- they are the scanned/retypeset manuals)
    MANUAL   ~/compartilhado/KN7000/WSA1R_files/WSA1-Practical Applications.pdf
             116 PDF pages; printed page N == PDF page N+2.
             Text layer is clean:  pdftotext -layout <file> out.txt
    REFGUIDE ~/compartilhado/KN7000/WSA1R_files/OM.zip
             -> OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf  (56 pages, IMAGE ONLY,
             printed page == PDF page).  This is the document that carries the
             MIDI Implementation Chart (p34-35) and MIDI DATA FORMAT (p36-56),
             including the Technics MIDI exclusive message format (p41) and the
             21-bit exclusive address map (p45).  pdftotext returns ~134 bytes
             for the whole file: it MUST be rendered, never grepped.

WHY THE RENDER STEP EXISTS
    In the Practical Applications manual the item lists shown on the instrument's
    LCD are bitmap screenshots, so the text layer carries only the prose that
    describes them.  Names such as the INPUT&OUTPUT FILTER command list or the
    SYSEX BULK DUMP data-type list exist ONLY inside those bitmaps and are
    readable only from a rendered page.

USAGE
    python3 manual_menu_items.py --out /tmp/wsa1-manual
        writes  text/pNNN.txt   one file per PRINTED page (text layer)
                png/pNNN.png    rendered page images for the pages listed below

    python3 manual_menu_items.py --out /tmp/wsa1-manual --refguide
        also renders the REFERENCE GUIDE 2 MIDI pages 34-56.

PAGES THAT MATTER (printed numbers, Practical Applications)
    41      COMBINATION EDIT menu (LCD tiles)
    42-43   COMBINATION EDIT / INTERNAL SOUND items + CONTROLLER settings
    44-45   COMBINATION EDIT / MIDI SOUND + its MIDI OUTPUT FILTER pages
    46-47   CONFIGURE (ASSIGN / KEY LAYER / VELOCITY LAYER), MIXER page 1/3
    48      COMBINATION EDIT / DSP EFFECT
    50-52   SYSTEM menu, TUNE & SCALE, CONTROLLER ASSIGN, TOUCH SENSITIVITY
    53-55   SYSTEM MIXER pages, DSP EFFECT + DETAIL EDIT + EQUALIZER
    57-59   SOUND/COMBINATION MANAGER, DATA LOAD FILTER, MEMORY PROTECT,
            DRUMS MAP, MAIN OUT EQUALIZER
    62-65   PART menu, INTERNAL SOUND, CONTROLLER settings, MIDI OUTPUT FILTER
    100-104 MIDI menu: TOTAL MODE, REALTIME MESSAGES, INPUT&OUTPUT FILTER,
            PROGRAM CHANGE MIDI OUT, SYSEX BULK DUMP, GENERAL MIDI
    105     INITIAL + backup memory
    106     rear-panel terminals
    110     error message table (40/41/42 are the exclusive ones)
    113     Specifications (menu inventory per mode)

NEGATIVE RESULT, WITH ITS COVERAGE
    The Practical Applications manual contains NO MIDI implementation chart and
    NO statement of System Exclusive byte formats.  Coverage of that claim: all
    116 PDF pages were extracted to text and the strings "implementation",
    "exclusive", "sysex", "checksum" and "F0" were searched case-insensitively;
    the only hits are the SYSEX BULK DUMP menu item (p100, p103), the index
    entry (p111) and error codes 40/41/42 (p110).  The chart lives in the
    separate REFERENCE GUIDE instead.
"""

import argparse
import os
import subprocess
import sys

MANUAL = os.path.expanduser(
    "~/compartilhado/KN7000/WSA1R_files/WSA1-Practical Applications.pdf")
OM_ZIP = os.path.expanduser("~/compartilhado/KN7000/WSA1R_files/OM.zip")
REFGUIDE_IN_ZIP = "OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf"

# printed page -> PDF page for WSA1-Practical Applications.pdf
PDF_OFFSET = 2

RENDER_PAGES = [41, 42, 43, 44, 45, 46, 47, 48, 50, 51, 52, 53, 54, 55,
                57, 58, 59, 62, 63, 64, 65, 100, 101, 102, 103, 104, 105,
                106, 110, 113]


def run(cmd):
    subprocess.run(cmd, check=True)


def split_text(out_dir):
    txt_dir = os.path.join(out_dir, "text")
    os.makedirs(txt_dir, exist_ok=True)
    whole = os.path.join(out_dir, "practical-applications.txt")
    run(["pdftotext", "-layout", MANUAL, whole])
    pages = open(whole, encoding="utf-8", errors="replace").read().split("\f")
    for i, page in enumerate(pages):
        printed = i + 1 - PDF_OFFSET
        with open(os.path.join(txt_dir, "p%03d.txt" % printed), "w") as fh:
            fh.write(page)
    return len(pages)


def render(out_dir, dpi):
    png_dir = os.path.join(out_dir, "png")
    os.makedirs(png_dir, exist_ok=True)
    for printed in RENDER_PAGES:
        pdfp = printed + PDF_OFFSET
        run(["pdftoppm", "-r", str(dpi), "-png", "-f", str(pdfp), "-l",
             str(pdfp), MANUAL, os.path.join(png_dir, "p%03d" % printed)])


def render_refguide(out_dir, dpi):
    rg_dir = os.path.join(out_dir, "refguide")
    os.makedirs(rg_dir, exist_ok=True)
    run(["unzip", "-o", "-q", "-j", OM_ZIP, REFGUIDE_IN_ZIP, "-d", rg_dir])
    pdf = os.path.join(rg_dir, os.path.basename(REFGUIDE_IN_ZIP))
    # printed page == PDF page in this file; 34-35 chart, 36-56 MIDI DATA FORMAT
    run(["pdftoppm", "-r", str(dpi), "-png", "-f", "34", "-l", "56", pdf,
         os.path.join(rg_dir, "rg2")])


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", required=True)
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument("--refguide", action="store_true")
    args = ap.parse_args()

    if not os.path.exists(MANUAL):
        sys.exit("manual not found: %s" % MANUAL)

    os.makedirs(args.out, exist_ok=True)
    n = split_text(args.out)
    print("text: %d PDF pages -> %s/text/pNNN.txt (printed numbering)"
          % (n, args.out))
    render(args.out, args.dpi)
    print("png : %d pages rendered at %d dpi" % (len(RENDER_PAGES), args.dpi))
    if args.refguide:
        if not os.path.exists(OM_ZIP):
            sys.exit("OM.zip not found: %s" % OM_ZIP)
        render_refguide(args.out, args.dpi)
        print("refguide: pages 34-56 rendered (chart + MIDI DATA FORMAT)")


if __name__ == "__main__":
    main()
