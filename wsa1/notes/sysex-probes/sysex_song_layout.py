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

# ---- the header, read as the difference between the recorded song and the
# nine identical empty ones.  Every byte that differs is a byte a song writes.
U, E = R[0], R[1]
print("\nTHE HEADER, +0x000..+0x%03X" % (STREAM - 1))
assert U[:4] == b"\x5A" * 4
print("  +000  4  signature 5A 5A 5A 5A")
assert U[4] == 1 and all(R[i][4] == 0 for i in range(1, SONGS)), \
    "+004 is not 1 in the recorded song and 0 in every empty one"
print("  +004  1  1 in the recorded song, 0 in all %d empty ones" % (SONGS - 1))

RAMP = bytes(range(1, 16)) + b"\x20"
for at in (0x23, 0x34):
    assert U[at:at + 16] == RAMP, "the ramp at +%02X has changed" % at
print("  +023 16  a ramp 01..0F then 20 -- and +034 carries the same ramp again")

# three tables of the SAME length, each with its own unused marker.  That they
# agree on seventeen is the evidence; no one of them would be worth much alone.
TABLES = [(0x07E, 2, b"\xFF\xFF"), (0x0A0, 1, b"\x05"), (0x100, 3, b"\x00\xFF\xFF")]
counts = []
for at, w, unused in TABLES:
    n = 0
    while E[at + n * w: at + (n + 1) * w] == unused:
        n += 1
    counts.append(n)
    print("  +%03X %2d  %d entries of %d, unused = %s"
          % (at, n * w, n, w, " ".join("%02X" % c for c in unused)))
assert counts == [17, 17, 17], \
    "the three header tables no longer agree on seventeen: %r" % counts
print("  -> three tables, three different unused markers, all SEVENTEEN entries")
used = [U[0x100 + i * 3] for i in range(17)]
assert set(used) == {0x80}, "the recorded song does not mark all 17 entries in use"
print("     in the recorded song all seventeen of the +100 entries read 80 and")
print("     carry a 16-bit value; the last ten of those run consecutively")
assert U[0xCA:0xD0] == R[1][0xCA:0xD0], "the name field moved"
print("  +0CA  6  NAME")
assert U[0x200:0x207] == b"\x5A\x5A\x01\x00WA0", "the second signature changed"
print("  +200  7  a second signature, 5A 5A 01 00 then 'WA0'")

TAIL = 0xB80
assert all(R[i][TAIL:] == R[1][TAIL:] for i in range(SONGS)), "the tail varies"
print("\n  the last %d bytes, +%03X onwards, are identical in all %d records"
      % (SONG - TAIL, TAIL, SONGS))
d_hdr = sum(1 for i in range(STREAM) if U[i] != E[i])
d_str = sum(1 for i in range(STREAM, TAIL) if U[i] != E[i])
print("  a recorded song differs from an empty one in %d header bytes and %d"
      % (d_hdr, d_str))
print("  stream bytes, and in none of the tail")

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
top = counts.most_common(3)
print("  commonest bytes: %s"
      % ", ".join("0x%02X %.1f%%" % (v, 100.0 * n / len(seq)) for v, n in top))
assert [v for v, _ in top] == [0x00, 0x81, 0x90], "the byte profile has changed"

# NOT "all of it is in use".  An earlier version of this probe argued that no
# power-of-two chunking leaves a chunk empty and the last byte is not zero, so
# the whole file is live.  That does not follow: this is an image of the
# sequencer's memory, ONE of its ten songs is recorded, and a free block holds
# whatever was in it before.  Non-zero is not the same as in use.
live = sum(1 for i in range(0, len(seq), 0x400) if any(seq[i:i + 0x400]))
print("  every one of its %d 1 KiB chunks has a non-zero byte -- which says only"
      % (len(seq) // 0x400))
print("  that nothing was ever blanked, NOT that the data is live: one song of")
print("  ten is recorded here, so most of this is free space holding old bytes.")

# LOCALLY it is events: from the first one the stream parses as
#   [delta < 0x80] [zero or more 0x81] [status >= 0x80, or none] [4 bytes]
# with "no status" being MIDI running status.
def local_parse(start):
    i, n, run, pre = start, 0, 0, 0
    stats = Counter()
    while i < len(seq) - 8:
        if seq[i] >= 0x80:
            break
        j, st = i + 1, []
        while j < len(seq) and seq[j] >= 0x80 and len(st) < 8:
            st.append(seq[j]); j += 1
        if st:
            stats[st[-1]] += 1; pre += len(st) - 1
        else:
            run += 1
        if j + 4 > len(seq):
            break
        n += 1; i = j + 4
    return i, n, run, pre, stats


stop, nrec, nrun, npre, stats = local_parse(8)
print("\n  from the first event it parses as [delta][0x81...][status or none][4 bytes],")
print("  'or none' being running status, for %d records, stopping at 0x%X" % (nrec, stop))
print("    statuses: %s" % ", ".join("0x%02X x%d" % (k, v) for k, v in stats.most_common()))
assert (nrec, nrun, npre) == (85, 5, 20), "the local parse has changed"
assert set(stats) == {0x90, 0xB4}, "the status set has changed"

# ...and it does NOT generalise, which is the point of measuring it.  Let the
# parser skip a byte and retry whenever it fails, and count the skips.
i, recs, resync = 8, 0, 0
while i < len(seq) - 8:
    if seq[i] >= 0x80:
        i += 1; resync += 1; continue
    j = i + 1
    while j < len(seq) and seq[j] >= 0x80 and j - i <= 8:
        j += 1
    if j + 4 > len(seq):
        break
    recs += 1; i = j + 4
print("  over the WHOLE file the same rule needs %d resynchronisations for %d"
      % (resync, recs))
print("  records -- worse than one per record, so the model is wrong for nearly")
print("  all of it.  The 85 at the start are a local run, not the encoding.")
assert resync > recs, "the resync rate has improved; re-open the encoding question"

# And there is no block chain to follow either.  If the header's 17 values were
# block numbers and blocks were linked, some link offset would give disjoint
# chains.  None does, over four block sizes and every offset within a block.
starts = [int.from_bytes(R[0][0x100 + i * 3 + 1:0x100 + i * 3 + 3], "little")
          for i in range(17)]
found = []
for B in (128, 256, 320, 512):
    nb = len(seq) // B
    if max(starts) >= nb:
        continue
    for lo in range(B - 1):
        for big in (False, True):
            seen, ok = set(), True
            for st0 in starts:
                cur, local = st0, set()
                while True:
                    if cur >= nb or cur in local:
                        ok = False; break
                    local.add(cur)
                    o = cur * B + lo
                    nxt = int.from_bytes(seq[o:o + 2], "big" if big else "little")
                    if nxt in (0, 0xFFFF) or nxt >= nb:
                        break
                    cur = nxt
                if not ok or (local & seen):
                    ok = False; break
                seen |= local
            if ok and len(seen) >= 40:
                found.append((B, lo, big))
print("\n  block-chain search: %d block sizes x every link offset x both byte"
      % 4)
print("  orders, asking for disjoint terminating chains from the 17 values --")
print("  solutions found: %d" % len(found))
assert not found, "a block chain exists after all: %r" % found[:3]
print("  So the 17 values are not block numbers in any linked scheme of that")
print("  shape, and the earlier 0x80-alignment observation is not supported by")
print("  a structure. The event encoding needs the playback routine.")

print("\nOK")
