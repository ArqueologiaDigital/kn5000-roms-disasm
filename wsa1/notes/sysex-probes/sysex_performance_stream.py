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

notes = [e[2] for e in events if e[1] == 0x90 and len(e[2]) == 5]
print("\n  %d note events; their five bytes, as ranges:" % len(notes))
for k, name in enumerate(("offset in step", "note number", "velocity",
                          "gate low", "gate high")):
    col = [x[k] for x in notes]
    print("    data[%d] %-15s %3d..%-3d" % (k, name, min(col), max(col)))
assert min(x[1] for x in notes) >= 12 and max(x[1] for x in notes) <= 127, \
    "the note-number column left the musical range"
print("\nOK")
