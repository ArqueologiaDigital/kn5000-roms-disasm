#!/usr/bin/env python3
"""HOW IS A RECORDED PERFORMANCE STORED?

QUESTION IT ANSWERS

This was the reference's largest undecoded area, and two earlier attempts on it
failed in ways worth recording.  A linear parse of the file works for 85
records and then loses sync.  A block-chain search over four block sizes, every
link offset and both byte orders returned nothing, and on the strength of that
this project WITHDREW a correct hypothesis.

The firmware settles it in four instructions.  The sequencer converts an
address in the performance area to a block number with

    sub  XWA,0x00617800     ; the base of PERFORMANCE in CPU 1 RAM
    sra  0x08,XWA           ; >> 8   -- so blocks are 256 bytes
    inc  1,XWA              ; ...and are numbered from ONE

and converts back with `dec 1` then `sla 0x08`.  The chain search had used
zero-based numbering, so every block it looked at was the wrong one.  Nearby,
`ld HL,(XHL+0x03)` reads the next block number from offset 3.

THE FORMAT

  * PERFORMANCE is 256-byte blocks numbered from 1.  A block's header is five
    bytes; the link to the next block is a 16-bit little-endian number at +3,
    and the data is +5..+255.  A chain ends on 0 or 0xFFFF.
  * The song header's seventeen entries hold each track's FIRST block.  The
    seventeen chains are disjoint.
  * A track's data is a flat event stream: a status byte at or above 0x80,
    then a fixed number of data bytes below 0x80.  There is no delta before
    the status -- time is carried by the events themselves:
        0x81  0 bytes   advance the clock one step
        0x90  5 bytes   a note: offset, note number, velocity, gate lo, gate hi
        0xB0  5 bytes   controller       0xB4  5 bytes
        0xC0  5 bytes   program change   0xD2  3 bytes
        0xE0  3 bytes                    0xD1  2 bytes
  * Every event's FIRST data byte is its offset within the current step.

RUN
  python3 wsa1/notes/sysex-probes/sysex_performance_stream.py

PASS CRITERION
  Four things, and the last two are what make it a decode rather than a story.
  The seventeen chains must be disjoint.  The reconstructed streams must parse
  with ZERO bytes that are not part of an event -- one stray byte anywhere and
  the framing is wrong.  The per-status data lengths must be the ones above.
  And the first-data-byte-is-a-time-offset claim is tested against a control:
  within a step those offsets must not go backwards, where the same events
  shuffled go backwards about two fifths of the time.
"""
import hashlib, os, random, sys, zipfile
from collections import Counter, defaultdict

ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/GJS1.zip"
ZIP_SHA = "c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524"
SEQ, SQF = "GJS1/01220497.SEQ", "GJS1/01220497.SQF"

BLOCK, LINK_AT, DATA_AT = 256, 3, 5
TRACKS, TABLE_AT = 17, 0x100
PERF_BASE = 0x617800                      # what the firmware subtracts
LENGTHS = {0x81: 0, 0x90: 5, 0xB0: 5, 0xB4: 5, 0xC0: 5,
           0xD2: 3, 0xE0: 3, 0xD1: 2}

if not os.path.exists(ZIP):
    print("GJS1.zip is not present; nothing to check.")
    sys.exit(0)
assert hashlib.sha256(open(ZIP, "rb").read()).hexdigest() == ZIP_SHA, \
    "GJS1.zip is not the archive checked here"
with zipfile.ZipFile(ZIP) as z:
    perf, hdr = z.read(SEQ), z.read(SQF)[:3072]

NB = len(perf) // BLOCK
print("PERFORMANCE: %d bytes = %d blocks of %d, numbered 1..%d"
      % (len(perf), NB, BLOCK, NB))
print("  (the firmware forms a block number as (addr - 0x%06X) >> 8, then + 1)"
      % PERF_BASE)


def block(n):
    return perf[(n - 1) * BLOCK:n * BLOCK]


def chain(first):
    out, cur = [], first
    while 1 <= cur <= NB and cur not in out:
        out.append(cur)
        nxt = int.from_bytes(block(cur)[LINK_AT:LINK_AT + 2], "little")
        if nxt in (0, 0xFFFF) or nxt > NB:
            break
        cur = nxt
    return out


starts = [int.from_bytes(hdr[TABLE_AT + 3 * i + 1:TABLE_AT + 3 * i + 3], "little")
          for i in range(TRACKS)]
chains, seen = [], set()
for i, s in enumerate(starts):
    c = chain(s)
    assert not (set(c) & seen), "track %d's chain overlaps an earlier one" % i
    seen |= set(c)
    chains.append(c)
print("  %d tracks, %d blocks in total, all chains disjoint (%.0f%% of the area)"
      % (TRACKS, len(seen), 100.0 * len(seen) * BLOCK / len(perf)))
assert len(seen) == 560, "expected 560 blocks in the chains, got %d" % len(seen)

# ---- parse
events, stray, lens = [], 0, defaultdict(Counter)
for ti, c in enumerate(chains):
    p = b"".join(block(n)[DATA_AT:] for n in c)
    i = 0
    while i < len(p):
        if p[i] < 0x80:
            stray += 1; i += 1; continue
        st, j = p[i], i + 1
        while j < len(p) and p[j] < 0x80:
            j += 1
        lens[st][j - i - 1] += 1
        events.append((ti, st, p[i + 1:j]))
        i = j
print("\n  %d events parsed, %d bytes not part of an event" % (len(events), stray))
assert stray == 0, "%d stray bytes -- the framing is wrong" % stray

print("\n  %-7s %-8s %s" % ("status", "count", "data bytes"))
for st in sorted(lens):
    c = lens[st]
    n = c.most_common(1)[0][0]
    flag = ""
    if st in LENGTHS:
        assert n == LENGTHS[st], "status %02X now takes %d data bytes" % (st, n)
        flag = " <-- named"
    print("    %02X    %-8d %s%s" % (st, sum(c.values()), dict(sorted(c.items())), flag))
assert lens[0x81][0] == 19980, "the 0x81 count changed"

# ---- the first data byte is a time offset within the step
random.seed(7)
fwd = back = cfwd = cback = 0
for ti, c in enumerate(chains):
    p = b"".join(block(n)[DATA_AT:] for n in c)
    i, run = 0, []
    while i < len(p):
        st, j = p[i], i + 1
        while j < len(p) and p[j] < 0x80:
            j += 1
        if st == 0x81:
            if len(run) > 1:
                fwd += sum(1 for a, b in zip(run, run[1:]) if a <= b)
                back += sum(1 for a, b in zip(run, run[1:]) if a > b)
                sh = run[:]; random.shuffle(sh)
                cfwd += sum(1 for a, b in zip(sh, sh[1:]) if a <= b)
                cback += sum(1 for a, b in zip(sh, sh[1:]) if a > b)
            run = []
        elif j > i + 1:
            run.append(p[i + 1])
        i = j
print("\n  within a step, consecutive first-data-bytes:")
print("    non-decreasing %d, going backwards %d (%.2f%%)"
      % (fwd, back, 100.0 * back / (fwd + back)))
print("    CONTROL, the same events shuffled: %d backwards (%.1f%%)"
      % (cback, 100.0 * cback / (cfwd + cback)))
assert back / (fwd + back) < 0.01, "the offsets are no longer ordered"
assert cback / (cfwd + cback) > 0.25, "the control no longer disagrees"
print("  -> the first data byte of every event is its offset inside the step")
print("     that 0x81 advances.")

# ---- WHICH TRACK IS WHICH.  A B0 event's second data byte is the part it
# addresses.  If entry i of the song header is track i, then every B0 event in
# entry i's chain should name part i.  A chain's LAST block is only partly
# used and its tail holds stale bytes, so it is excluded -- and that exclusion
# is not a convenience: with it included the stale events are visible as a
# recurring {1, 2, 5, 12} in every chain, which is how it was noticed.
def b0_parts(blocks):
    p = b"".join(block(n)[DATA_AT:] for n in blocks)
    c, i = Counter(), 0
    while i < len(p):
        if p[i] < 0x80:
            i += 1; continue
        st, j = p[i], i + 1
        while j < len(p) and p[j] < 0x80:
            j += 1
        if st == 0xB0 and j - i - 1 == 5:
            c[p[i + 2]] += 1
        i = j
    return c


print("\n  which entry is which track -- a B0 event's second data byte is the")
print("  part it addresses, and a chain's partly-used last block is excluded:")
named = 0
for i, c in enumerate(chains):
    parts = b0_parts(c[:-1])
    ok = list(parts) == [i]
    named += ok
    print("    entry %2d  B0 parts %-14s %s"
          % (i, dict(sorted(parts.items())), "== the entry index" if ok
             else ("no B0 events" if not parts else "")))
assert named == 16, "expected 16 entries to name themselves, got %d" % named

# the control: pair each entry with the NEXT chain instead of its own
shifted = sum(1 for i in range(TRACKS)
              if list(b0_parts(chains[(i + 1) % TRACKS][:-1])) == [i])
print("    CONTROL, each entry paired with the next entry's chain: %d of %d"
      % (shifted, TRACKS))
assert shifted == 0, "the control matches too, so the test proves nothing"
print("  -> entry i is track i, and its events address part i.  Entry 16, the")
print("     one beyond the sixteen recording tracks Technics publishes, carries")
print("     no part-addressed controller events at all.")

# ---- WHAT THE SEVENTEENTH STREAM IS.  Not "the one that does not name a
# part", which is only an absence.  Its status set and the other sixteen's are
# DISJOINT, in both directions, which is a much stronger statement: it shares
# nothing with them and they share nothing with it.
def statuses(blocks):
    p = b"".join(block(n)[DATA_AT:] for n in blocks)
    out, i = Counter(), 0
    while i < len(p):
        if p[i] < 0x80:
            i += 1; continue
        st, j = p[i], i + 1
        while j < len(p) and p[j] < 0x80:
            j += 1
        out[st] += 1; i = j
    return out


CLOCK = 0x81
tracks = [statuses(c[:-1]) for c in chains]
musical = set()
for t in tracks[:16]:
    musical |= set(t) - {CLOCK}
last = set(tracks[16]) - {CLOCK}
print("\n  the seventeenth stream, against the other sixteen:")
print("    statuses used by tracks 0-15 : %s"
      % " ".join("%02X" % x for x in sorted(musical)))
print("    statuses used by entry 16    : %s"
      % " ".join("%02X" % x for x in sorted(last)))
print("    entry 16 is %d events, %d of them the clock"
      % (sum(tracks[16].values()), tracks[16][CLOCK]))
assert not (musical & last), "the status sets are no longer disjoint"
assert tracks[16][CLOCK] / sum(tracks[16].values()) > 0.99, \
    "entry 16 is no longer almost entirely clock"
for i, t in enumerate(tracks[:16]):
    assert 0x90 in t, "track %d carries no notes" % i
assert 0x90 not in tracks[16], "entry 16 carries notes after all"
print("    -> the two sets are DISJOINT in both directions.  Every one of the")
print("    sixteen carries notes and entry 16 carries none; entry 16's two")
print("    statuses appear in none of the sixteen.  So it is not a recording")
print("    track at all, which is what Technics publishing SIXTEEN recording")
print("    tracks predicts.  What its two events mean is not established: the")
print("    values they carry appear nowhere in the song header to check against.")

notes = [e[2] for e in events if e[1] == 0x90 and len(e[2]) == 5]
print("\n  %d note events; their five bytes, as ranges:" % len(notes))
for k, name in enumerate(("offset in step", "note number", "velocity",
                          "gate low", "gate high")):
    col = [x[k] for x in notes]
    print("    data[%d] %-15s %3d..%-3d" % (k, name, min(col), max(col)))
assert min(x[1] for x in notes) >= 12 and max(x[1] for x in notes) <= 127, \
    "the note-number column left the musical range"
print("\nOK")
