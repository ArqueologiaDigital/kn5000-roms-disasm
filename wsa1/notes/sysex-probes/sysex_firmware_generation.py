#!/usr/bin/env python3
"""WHICH GENERATION OF THE FIRMWARE IS THIS REFERENCE READ FROM?

QUESTION IT ANSWERS

Everything in wsa1/docs/system-exclusive-reference/ is read out of operating
system version 2, and the reference says so.  That is the version the ROMs
report about themselves.  This pins the same dump against a document Technics
published, which is independent of anything the ROM says about itself.

Technics issued a one-page multilingual erratum, "SX-WSA1/SX-WSA1R"
(QQCG0279A), for the owner's manuals.  It states one change: the second soft
key of the SOUND MODE home screen is renamed VOL to LVL and now adjusts the
level relative to the current value, -30 to +30.

The dumped firmware ALREADY carries the corrected caption -- and carries it in
exactly one of the two home screens that have this row.  The screen whose last
soft key is MIDI, which is the one the erratum photographs, reads LVL.  A
second screen of the same shape, whose last soft key is PART, still reads VOL.
So the rename landed on the SOUND MODE home screen and not on its neighbour,
and the machine this reference describes is on the late side of the erratum.

SIGNAL BEING READ
  KN7000/WSA1R_files/SX-WSA1 Manual update.pdf, one page, image-only, sha256
  6198dfcf3d3f8645475cf4a32bf0fdab41bdfae6614364dbd2abd077234451d4.  It is a
  community scan and is not committed here; RENDER it, do not grep it:
      pdftoppm -r 150 -png "SX-WSA1 Manual update.pdf" /tmp/upd

  In wsa1_prom_b.ic13, the SOUND MODE soft-key row, as caption records
      [0x17][len][x lo][x hi][y lo][y hi][ASCII]      len = 6 + len(text)
  all sharing one y.

RUN
  python3 wsa1/notes/sysex-probes/sysex_firmware_generation.py

PASS CRITERION
  Exactly two rows read OCT LVL PAN EFF1 EFF2 REV INT MIDI and exactly two read
  OCT VOL PAN EFF1 EFF2 REV INT PART, each on one row at increasing x, and
  every row of this shape in the image is one of those two.  That last clause
  is what makes it a measurement: the row is parsed as a whole rather than
  searched for a string, because a bare grep for "VOL" hits VOLUME fourteen
  times here and would prove nothing either way.  An earlier draft of this
  probe asserted that NO row says VOL; it was wrong, and the assertion caught
  it.
"""
import hashlib, os, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
PROM_B, B_BASE = "wsa1_prom_b.ic13", 0xF00000
IMG = open(os.path.join(ROMS, PROM_B), "rb").read()

UPDATE = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SX-WSA1 Manual update.pdf"
UPDATE_SHA = "6198dfcf3d3f8645475cf4a32bf0fdab41bdfae6614364dbd2abd077234451d4"
SOUND_MODE = ["OCT", "LVL", "PAN", "EFF1", "EFF2", "REV", "INT", "MIDI"]
OTHER      = ["OCT", "VOL", "PAN", "EFF1", "EFF2", "REV", "INT", "PART"]

CAP = 0x17


def caption(o):
    """The caption record at `o`, or None."""
    if IMG[o] != CAP:
        return None
    ln = IMG[o + 1]
    if not (7 <= ln <= 0x20) or o + ln > len(IMG):
        return None
    x = int.from_bytes(IMG[o + 2:o + 4], "little")
    y = int.from_bytes(IMG[o + 4:o + 6], "little")
    t = IMG[o + 6:o + ln]
    if len(t) != ln - 6 or not t or not all(0x20 <= c < 0x7F for c in t):
        return None
    return x, y, t.decode("ascii")


def rows():
    """Every run of >=8 caption records that share one y."""
    out, o = [], 0
    while o < len(IMG) - 0x20:
        c = caption(o)
        if c is None:
            o += 1
            continue
        run, y, p = [c], c[1], o
        p += IMG[p + 1]
        while True:
            n = caption(p)
            if n is None or n[1] != y:
                break
            run.append(n)
            p += IMG[p + 1]
        if len(run) >= 8:
            out.append((B_BASE + o, y, run))
        o = p if len(run) > 1 else o + 1
    return out


ALL = rows()
found = [(a, y, r) for a, y, r in ALL if [t for _, _, t in r][:8] == SOUND_MODE]
other = [(a, y, r) for a, y, r in ALL if [t for _, _, t in r][:8] == OTHER]
print("HOME-SCREEN SOFT-KEY ROWS, in %s" % PROM_B)
for label, group in (("SOUND MODE (erratum applied)", found), ("second home screen", other)):
    for a, y, r in group:
        xs = [x for x, _, _ in r]
        print("  %-28s 0x%06X y=%d  %s"
              % (label, a, y, "  ".join("%s@x%d" % (t, x) for x, _, t in r)))
        assert xs == sorted(set(xs)), "the row's captions are not at increasing x"
        label = ""
assert len(found) == 2, "expected two SOUND MODE rows, found %d" % len(found)
assert len(other) == 2, "expected two rows of the other shape, found %d" % len(other)

# every row of this shape in the image is one of those two -- the coverage that
# turns "the rename landed on one screen" from an impression into a count.
shape = [(a, y, r) for a, y, r in ALL
         if [t for _, _, t in r][:1] == ["OCT"] and len(r) >= 8]
assert len(shape) == len(found) + len(other), \
    "%d rows of this shape, but only %d accounted for" % (len(shape), len(found) + len(other))
print("  %d rows of this shape in the image, all accounted for" % len(shape))

print("\nTHE ERRATUM")
if os.path.exists(UPDATE):
    got = hashlib.sha256(open(UPDATE, "rb").read()).hexdigest()
    assert got == UPDATE_SHA, "the erratum scan is not the one checked here"
    txt = subprocess.run(["pdftotext", UPDATE, "-"], capture_output=True).stdout
    print("  %s" % os.path.basename(UPDATE))
    print("  sha256 %s" % got)
    print("  pdftotext returns %d bytes -- it is image-only, so RENDER it" % len(txt.strip()))
    assert len(txt.strip()) < 16, "the erratum has a text layer; re-read this probe's claim"
else:
    print("  not present; the ROM half of this check stands on its own")

print("\n  QQCG0279A changes the second soft key VOL -> LVL, level -30..+30.")
print("  This dump already has LVL, so it post-dates the erratum.")
print("\nOK")
