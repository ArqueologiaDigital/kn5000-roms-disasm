#!/usr/bin/env python3
"""WHAT IS INSIDE A SONG?

QUESTION IT ANSWERS

The reference decodes the SEQUENCER transfer's framing and its two fixed
blocks, and `sysex_sequencer_layout.py` establishes from the firmware that the
30 720-byte block is ten song records of 3 072.  What a song record CONTAINS
was the largest thing the reference did not cover, and no SEQUENCER dump exists
for this project to read -- the rack refuses that category outright.

A disk does just as well.  A community disk image carries `01220497.SQF`, a
native sequencer file of exactly 30 720 bytes, and it decodes on the structure
the firmware predicted without any adjustment.

WHAT IT SETTLES

  * Ten records of 3 072, each opening `5A 5A 5A 5A`, with six printable bytes
    at `+0xCA` -- the name field, at the offset the firmware gave.
  * Most of a song record is the record stream this reference already
    documents.  From `+0x220` it is a TLV stream of exactly the same tagged
    records a combination is built from, and the first 704 bytes of it ARE a
    combination: 23 records in the identical order, checked here against the
    shape `sysex_combination_layout.py` derived independently.
  * A song carries THIRTY-TWO parts.  The part records run `00`..`1F` for
    block A and `20`..`3F` for block B, complete, no gaps -- the same 32 parts
    the parameter grammar addresses at block `20` plus the part number.  Eight
    of them come inside the embedded combination and the other 24 follow it.

  So chapter 8's parameter tables name the fields of 2 400 of a song record's
  3 072 bytes, and the reference can say so instead of calling the record
  opaque.

SIGNAL BEING READ
  KN7000/WSA1R_files/GJS1.zip, sha256
  c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524, holding
  GJS1/01220497.SQF, 30 720 bytes, sha256
  9c5ebf768110d7c11bf5f4241db2a984e217fbf5b2b4c7706b57ef46b0dda886.
  A community disk image; it is not committed here.

RUN
  python3 wsa1/notes/sysex-probes/sysex_song_layout.py

PASS CRITERION
  The file tiles into ten records of 3 072; the TLV walk closes on its own
  terminators with no byte left over; the 64 part tags are complete; and the
  first segment's (tag, length) list EQUALS the combination shape taken from
  the other probe.  That last one is the test that matters -- it is an
  equality against a structure derived from a different source, so agreement
  is not something this script can arrange for itself.
"""
import hashlib, io, os, sys, zipfile, contextlib
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
with contextlib.redirect_stdout(io.StringIO()):
    import sysex_combination_layout as L   # noqa: E402

ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/GJS1.zip"
ZIP_SHA = "c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524"
MEMBER = "GJS1/01220497.SQF"
SQF_SHA = "9c5ebf768110d7c11bf5f4241db2a984e217fbf5b2b4c7706b57ef46b0dda886"
SEQ_MEMBER = "GJS1/01220497.SEQ"

SONG = 3072
SONGS = 10
NAME_AT, NAME_LEN = 0xCA, 6
STREAM = 0x220


def load():
    if not os.path.exists(ZIP):
        return None
    assert hashlib.sha256(open(ZIP, "rb").read()).hexdigest() == ZIP_SHA, \
        "GJS1.zip is not the archive checked here"
    with zipfile.ZipFile(ZIP) as z:
        d = z.read(MEMBER)
    assert hashlib.sha256(d).hexdigest() == SQF_SHA, "the .SQF is not the file checked here"
    return d


def walk(buf, o, limit):
    """The TLV stream at `o`: [(tag, length, payload offset)], and its terminator."""
    recs = []
    while o < limit - 1:
        if buf[o] == 0xFF:
            return recs, o
        t, l = buf[o], buf[o + 1]
        if l == 0 or o + 2 + l > limit:
            return recs, None
        recs.append((t, l, o + 2))
        o += 2 + l
    return recs, None


data = load()
if data is None:
    print("GJS1.zip is not present; nothing to check.")
    sys.exit(0)

print("%s -- %d bytes" % (MEMBER, len(data)))
assert len(data) == SONGS * SONG, "the file is not %d songs of %d" % (SONGS, SONG)
print("  %d song records of %d, which is the SEQUENCER block the reference documents"
      % (SONGS, SONG))

R = [data[i * SONG:(i + 1) * SONG] for i in range(SONGS)]
for i, r in enumerate(R):
    assert r[:4] == b"\x5A\x5A\x5A\x5A", "song %d does not open 5A 5A 5A 5A" % i
    nm = r[NAME_AT:NAME_AT + NAME_LEN]
    assert all(0x20 <= c < 0x7F for c in nm), "song %d has no printable name at +0xCA" % i
print("  every record opens 5A 5A 5A 5A and has %d printable bytes at +0x%02X: %r"
      % (NAME_LEN, NAME_AT, R[0][NAME_AT:NAME_AT + NAME_LEN].decode("ascii")))

used = [i for i in range(SONGS) if R[i] != R[1]]
assert R[2:] == [R[1]] * (SONGS - 2), "the empty songs are not all identical"
print("  songs 1..9 are byte-identical; song 0 is the recorded one, differing in %d bytes"
      % sum(1 for a in range(SONG) if R[0][a] != R[1][a]))

print("\nTHE RECORD STREAM, from +0x%03X" % STREAM)
segs, o = [], STREAM
while o < SONG:
    recs, end = walk(R[1], o, SONG)
    if not recs:
        break
    segs.append((o, recs, end))
    o = end + 2
for s, recs, end in segs:
    print("  +%04X..+%04X  %2d records  %s"
          % (s, end + 1, len(recs), " ".join("%02X" % t for t, _, _ in recs)))
assert len(segs) == 3, "expected three streams, found %d" % len(segs)

first = [(t, l) for t, l, _ in segs[0][1]]
assert first == L.SHAPE, \
    "the first stream is not the combination shape the other probe derived"
assert segs[0][2] + 2 - segs[0][0] == L.COMB, \
    "the embedded combination is not %d bytes" % L.COMB
print("\n  the first stream is a COMBINATION: %d records, %d bytes, identical to the"
      % (len(first), L.COMB))
print("  shape sysex_combination_layout.py derives from the instrument's own uploads")

parts = sorted(t for _, recs, _ in segs for t, l, _ in recs if l == 30 and t < 0x40)
assert parts == list(range(0x40)), "the part tags are not 00..3F complete"
print("  %d part records, tags 00..1F (block A) and 20..3F (block B), complete"
      % len(parts))
print("  -> a song has 32 parts: 8 inside the embedded combination, 24 after it")

covered = sum(end + 2 - s for s, _, end in segs)
print("\n  %d of a song record's %d bytes are records this reference already names"
      % (covered, SONG))
print("  the %d bytes before +0x%03X, and the %d after the last terminator, are not"
      % (STREAM, STREAM, SONG - STREAM - covered))

# ---- the companion file, which is the recorded material
with zipfile.ZipFile(ZIP) as z:
    seq = z.read(SEQ_MEMBER)
print("\n%s -- %d bytes" % (SEQ_MEMBER, len(seq)))
print("  the disk set splits the sequencer the way the transfer does: this file is")
print("  everything the fixed-size song records are not, so it is PERFORMANCE.")
print("  That correspondence is inferred from the split, not read out of a program.")

counts = Counter(seq)
print("  it is not an array of fixed-size records: no power-of-two chunking leaves")
print("  any chunk empty, and the last byte is non-zero, so all of it is in use")
for sz in (0x400, 0x800, 0x1000, 0x2000):
    empty = sum(1 for i in range(0, len(seq), sz)
                if not any(seq[i:i + sz]))
    assert empty == 0, "a %d-byte chunk is empty after all" % sz
assert seq[-1] != 0, "the file ends in padding"

top = counts.most_common(3)
print("  commonest bytes: %s"
      % ", ".join("0x%02X %.1f%%" % (v, 100.0 * n / len(seq)) for v, n in top))
assert [v for v, _ in top] == [0x00, 0x81, 0x90], "the byte profile has changed"
print("  0x90 is MIDI note-on and the stream is full of it, but the event framing")
print("  is NOT decoded here: the six-byte spacing the opening bytes suggest does")
print("  not survive -- the longest run of 0x90 bytes six apart is one.")
run = best = 0
for i in range(len(seq) - 6):
    run = run + 1 if seq[i] == 0x90 and seq[i + 6] == 0x90 else 0
    best = max(best, run)
assert best <= 2, "the stream is periodic after all -- re-open this"
print("  longest such run: %d" % best)

print("\nOK")
