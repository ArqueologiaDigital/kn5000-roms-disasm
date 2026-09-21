#!/usr/bin/env python3
"""WHERE the published System Exclusive specification is, and what is on each page.

QUESTION IT ANSWERS
  This project spent several sessions decoding a protocol that Technics had
  already published.  The specification is not in either user manual -- it is
  in a third volume, the REFERENCE GUIDE, which the user manuals refer to only
  as "the separate REFERENCE GUIDE provided".  An earlier edition of
  wsa1/docs/system-exclusive-reference/ stated that no MIDI implementation
  chart was ever published.  That was wrong, and it was wrong because the
  search had covered one volume out of three.

  This script pins the document so the claim can never drift again: it checks
  the archive by hash, confirms the guide is image-only (so nobody concludes
  "not there" from a text search of it), and prints which page carries what.

SIGNAL BEING READ
  OM.zip, sha256 15548bcc8807357772b7b69629983191994c6891d0871d02e11e77b435f1eef3,
  in KN7000/WSA1R_files/.  Inside it, OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf,
  56 pages, sha256 e57205cae244f769109b1974b3c60cdc373695a845cfa7f2cf27b2d5f23e0345.
  The archive is a community scan and is not committed here.

  THE GUIDE IS IMAGE-ONLY.  `pdftotext` returns a few bytes for the whole
  file.  Its pages must be RENDERED and read:
      pdftoppm -r 150 -png -f 41 -l 41 <pdf> /tmp/rg

PASS CRITERION
  Both hashes match, the page count is 56, the text layer is empty, and OK.

RUN
  python3 wsa1/notes/sysex-probes/manual_reference_guide.py
"""
import hashlib
import os
import subprocess
import sys
import zipfile

ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/OM.zip"
INNER = "OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf"
ZIP_SHA = "15548bcc8807357772b7b69629983191994c6891d0871d02e11e77b435f1eef3"
PDF_SHA = "e57205cae244f769109b1974b3c60cdc373695a845cfa7f2cf27b2d5f23e0345"

# Page numbers are the PDF's own; the printed folio matches.
PAGES = [
    (1, "Contents: DIGITAL EFFECT 2, DSP EFFECT 3, MIDI Implementation Chart 34, "
        "MIDI DATA FORMAT 36"),
    (34, "MIDI Implementation Chart, Synthesizer [SX-WSA1] / Synthesizer module "
         "[SX-WSA1R], PART1-32 -- Transmitted"),
    (35, "MIDI Implementation Chart -- Recognized"),
    (36, "MIDI DATA FORMAT, and the MIDI Data Flowchart"),
    (41, "About the WSA1/WSA1R MIDI exclusive: the field list "
         "SOX/IDC/CMD/PC/MD/VER/[data]/EOX, the CMD table, PC, MD, VER, "
         "and the [data] layout ADR SIZ DT... CN SM"),
    (42, "ACK/NAK handshake sequence"),
    (45, "The form of the transmission message, per command; the MIDI exclusive "
         "address map; SIZ of data dump area; ADR of data request"),
    (46, "Parameter address tables begin"),
    (56, "Parameter address tables end"),
]

# What page 41 and page 45 establish, as this project uses them.
FIELDS = """\
  SOX  F0H          exclusive status
  IDC  50H          Technics ID number
  CMD  21H HRQ hand shake request   22H HRT hand shake routine
       23H ACK acknowledge          24H NAK negative acknowledge
       25H TMP tempo data           27H EOK end of block
       28H END end                  29H ERR error
       2AH FUL memory full          2BH DRQ data request
       2CH ITR individual data      2DH BTR data block
       7EH CDD continuing data
  PC   04H WSA     7EH DMY, the dummy used by ACK/NAK/EOK/END/ERR/FUL
  MD   00H WSA1    01H WSA1R
  VER  11H Ver2.1  -- the EXCLUSIVE version, not the operating system version
  data ADR (3 x 7 bits, one 21-bit address, upper end first)
       SIZ (3 x 7 bits)  DT...  CN continue id  SM checksum
"""

AREAS = """\
  ADR         address    area           subarea        sub-subarea
  00 00 00    000000H    SYSTEM                        REAL TIME
  00 08 00    000400H    SYSTEM                        NON-REAL TIME
  00 10 00    000800H    PART           COMMON         REAL TIME
  00 18 00    000C00H    PART           COMMON         NON-REAL TIME
  00 20 00    001000H    PART           INDIVIDUAL     PART1 REAL TIME
  00 20 40    001040H    PART           INDIVIDUAL     PART1 NON-REAL TIME
  00 3F 40    001FC0H    PART           INDIVIDUAL     PART32 NON-REAL TIME
  00 50 00    003000H    PART           SPECIAL        REAL TIME
  10 00 00    040000H    NORMAL SOUND   INDIVIDUAL
  18 00 00    060000H    DRUM SOUND     INDIVIDUAL
  20 00 00    080000H    SOUND MEMORY   TOTAL
  40 00 00    100000H    PANEL          HEADER
  40 00 20    100020H    PANEL          PANEL DATA
  50 00 00    140000H    COMBINATION    HEADER
  60 00 00    180000H    SEQUENCER      LOCATION / HEADER / PERFORMANCE
                         -- the page prints "SEQUENCER : WSA1 only"
"""


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    if not os.path.exists(ZIP):
        raise SystemExit("not found: %s" % ZIP)
    assert sha(open(ZIP, "rb").read()) == ZIP_SHA, "OM.zip is not the archive checked here"
    with zipfile.ZipFile(ZIP) as z:
        names = [n for n in z.namelist() if n.endswith(INNER.split("/")[-1])
                 and "__MACOSX" not in n]
        assert INNER in z.namelist(), "the guide is not at %s; found %s" % (INNER, names)
        pdf = z.read(INNER)
    assert sha(pdf) == PDF_SHA, "the Reference Guide is not the edition checked here"

    tmp = os.path.join(os.environ.get("TMPDIR", "/tmp"), "wsa1_refguide.pdf")
    open(tmp, "wb").write(pdf)
    info = subprocess.run(["pdfinfo", tmp], capture_output=True, text=True).stdout
    pages = int([l for l in info.splitlines() if l.startswith("Pages")][0].split()[-1])
    assert pages == 56, "the guide has %d pages, expected 56" % pages
    text = subprocess.run(["pdftotext", tmp, "-"], capture_output=True).stdout
    assert len(text.strip()) < 500, \
        "the guide now has a text layer (%d bytes); the render-only warning is stale" \
        % len(text.strip())

    print("\nTHE PUBLISHED SPECIFICATION")
    print("  %s\n    -> %s, %d pages, IMAGE-ONLY (%d bytes of text layer)"
          % (ZIP, INNER, pages, len(text.strip())))
    print("\nPAGE INDEX")
    for n, what in PAGES:
        print("  p%-3d %s" % (n, what))
    print("\nFIELDS, from page 41\n%s" % FIELDS)
    print("MIDI EXCLUSIVE ADDRESS MAP, from page 45\n%s" % AREAS)
    print("  render a page with:")
    print("    pdftoppm -r 150 -png -f 41 -l 41 <the pdf> /tmp/rg")
    print("OK")


if __name__ == "__main__":
    main()
