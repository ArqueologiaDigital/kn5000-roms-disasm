#!/usr/bin/env python3
"""WHAT DOES THE PUBLISHED MANUAL SAY ABOUT THE THINGS THIS PROJECT MEASURED?

QUESTION IT ANSWERS

Three structural facts in the reference were read out of stored data rather
than out of any document: a song record holds THIRTY-TWO parts, the SEQUENCER
block is TEN song records, and a song record's header carries three tables of
SEVENTEEN entries each.

The owner's manual states the first two outright, and states a track count that
bounds the third.  Two of the three are therefore confirmed by a source that
knew nothing about this project's decode, which is worth more than any amount
of internal consistency.

WHY THIS FILE AND NOT THE OTHER MANUALS
  The English owner's manual in the archive exists twice, and one of the two
  copies carries an OCR TEXT LAYER.  Every other Technics volume here is
  image-only, so this is the only one that can be searched rather than
  rendered.  It had been sitting unread for the same reason the Reference
  Guide did: nobody looked inside the archive.

SIGNAL BEING READ
  KN7000/WSA1R_files/OM.zip, sha256
  15548bcc8807357772b7b69629983191994c6891d0871d02e11e77b435f1eef3, member
  OM/EN/sx-WSA1 OM - TXT OCR.pdf, sha256
  2624308af8f75efef8244feab8580856420b9613935c55b21b2c806872bbb96c.
  A community scan; not committed here.

RUN
  python3 wsa1/notes/sysex-probes/manual_sequencer_specs.py

PASS CRITERION
  Each phrase below is present in the extracted text.  The OCR is imperfect --
  it mangles headings badly -- so the phrases are chosen to be short and
  numeric, and a phrase that goes missing is a signal to re-render the page
  rather than to drop the claim.
"""
import hashlib, os, re, subprocess, sys, tempfile, zipfile

ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/OM.zip"
ZIP_SHA = "15548bcc8807357772b7b69629983191994c6891d0871d02e11e77b435f1eef3"
MEMBER = "OM/EN/sx-WSA1 OM - TXT OCR.pdf"
PDF_SHA = "2624308af8f75efef8244feab8580856420b9613935c55b21b2c806872bbb96c"

# (phrase, what it confirms)
CLAIMS = [
    ("32 MIDI parts",
     "a song record's part tags run 00..1F and 20..3F -- thirty-two parts"),
    ("32-part multi-timbral",
     "the same, said a second way on the same page"),
    ("play back up\nto 10 performances",
     "the SEQUENCER block is ten song records of 3072"),
    ("16 recording tracks",
     "the header's three seventeen-entry tables are one MORE than the tracks"),
    ("16-track, 47,000 note Sequencer",
     "capacity: 47,000 notes, which over a PERFORMANCE of this size is about"
     " four bytes a note"),
]

if not os.path.exists(ZIP):
    print("OM.zip is not present; nothing to check.")
    sys.exit(0)
assert hashlib.sha256(open(ZIP, "rb").read()).hexdigest() == ZIP_SHA, \
    "OM.zip is not the archive checked here"
with zipfile.ZipFile(ZIP) as z:
    pdf = z.read(MEMBER)
assert hashlib.sha256(pdf).hexdigest() == PDF_SHA, \
    "the OCR manual is not the copy checked here"

tmp = os.path.join(tempfile.gettempdir(), "wsa1_om_ocr.pdf")
open(tmp, "wb").write(pdf)
text = subprocess.run(["pdftotext", tmp, "-"], capture_output=True).stdout.decode("latin1")
os.unlink(tmp)
print("%s -- %d characters of text layer" % (os.path.basename(MEMBER), len(text)))
assert len(text) > 40000, "the text layer is much smaller than expected"

flat = re.sub(r"[ \t]+", " ", text)
print()
missing = []
for phrase, means in CLAIMS:
    ok = phrase in flat
    print("  %-34s %s" % ("%r" % phrase.replace("\n", " "), "FOUND" if ok else "MISSING"))
    print("      %s" % means)
    if not ok:
        missing.append(phrase)
assert not missing, "phrases missing from the manual text: %r" % missing

print("""
So two of the three structures the reference read out of stored data are stated
outright by Technics -- thirty-two parts and ten songs -- and the third is
bounded: sixteen recording tracks against seventeen table entries, so the
tables carry one entry more than there are tracks.  What that extra entry is,
this does not say.""")
print("\nOK")
