#!/usr/bin/env python3
"""disk_seq_tracks.py -- the .SEQ track layout, and what track 6's 0x80 events are.

QUESTIONS ANSWERED
  1. Does .SEQ have a +0xD0-style track table like the ROM demo songs?
     NO.  A .SEQ file has NO header region at all: every 256-byte block is either a cell
     (byte 0 == 0x80) or a free block.  The track table is POSITIONAL -- track t's chain
     head is block t, i.e. cell number t+1, for t = 0..6, in all seven disks.

  2. What are the 7 tracks?  Measured over the seven floppies:
       track 0, 1   EMPTY on every disk: one cell whose payload begins with 0x82 (end)
       track 2      notes 60..96   -- the top voice
       track 3      notes 65..96   -- sparse, 621 notes against track 2's 4902
       track 4      notes 36..63
       track 5      notes 36..63   -- the densest, 7695 notes
       track 6      NO 0x90 at all -- the conductor track: 0x80, 0xC0, 0xD3, 0xB0, 0xB4
     Every populated track of a file carries the SAME number of 0x81 beat markers.

  3. 0x80 is the TEMPO event.  The demo-preset README records this as an unconfirmed
     inference from ROM data.  The disk corpus supports it independently and much harder:
     0x80 occurs ONLY on track 6, always as event #1 with pos 0 and a musically sane value
     (76, 80, 135, 105, 86, 73, 85 on the seven disks) -- and 04BOS_MX.SEQ contains a
     40-event RAMP: a strictly monotone 76 -> 52 over beats 808..810 (a ritardando, one
     unit every 7-8 ticks) and a strictly monotone 53 -> 68 over beats 846..848.
     A song-global 14-bit value that slides smoothly by one unit at a time, on a track that
     holds no notes, is a tempo curve.  [INFERENCE] -- still not a traced firmware constant.

Run:  python3 disk_seq_tracks.py <dir-with-extracted-disk-files>
"""
import collections
import glob
import os
import sys

NONE = (0x0000, 0xFFFF)


def u16(d, o):
    return d[o] | (d[o + 1] << 8)


def chains(d, n):
    cells = [i for i in range(n) if d[i * 256] == 0x80]
    prev = {i: u16(d, i * 256 + 1) for i in cells}
    nxt = {i: u16(d, i * 256 + 3) for i in cells}
    out = []
    for h in sorted(i for i in cells if prev[i] in NONE):
        ch, c = [], h
        while True:
            ch.append(c)
            v = nxt[c]
            if v in NONE:
                break
            c = v - 1
        out.append(ch)
    return out


def events(d, chain):
    s = b''.join(d[c * 256 + 5:c * 256 + 256] for c in chain)
    i = 0
    while i < len(s):
        b = s[i]
        j = i + 1
        while j < len(s) and not (s[j] & 0x80):
            j += 1
        yield b, s[i + 1:j]
        if b in (0x82, 0x83):
            return
        i = j


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    per = collections.defaultdict(collections.Counter)
    notes = collections.defaultdict(list)
    for f in sorted(glob.glob(os.path.join(root, '**', '*.SEQ'), recursive=True)):
        d = open(f, 'rb').read()
        n = len(d) // 256
        ramp = []
        for t, ch in enumerate(chains(d, n)):
            beat = 0
            for k, (st, a) in enumerate(events(d, ch)):
                per[t][st] += 1
                if st == 0x81:
                    beat += 1
                if st == 0x80:
                    assert t == 6, "0x80 outside track 6"
                    ramp.append((beat, a[0], a[1] + 128 * a[2]))
                if st == 0x90:
                    for q in range(0, len(a) - 4, 5):
                        notes[t].append(a[q + 1])
        print(f"{os.path.basename(f):<16} 0x80 events {len(ramp):3d}  "
              f"first {ramp[0] if ramp else None}  values {ramp[0][2]}"
              + (f" .. ramp {ramp[1][2]}->{ramp[-1][2]}" if len(ramp) > 1 else ""))
    print()
    for t in sorted(per):
        ns = notes[t]
        line = f"track {t}: " + " ".join(f"{s:02X}x{c}" for s, c in sorted(per[t].items()))
        print(line)
        if ns:
            print(f"          notes {len(ns)}  range {min(ns)}..{max(ns)}  "
                  f"top {collections.Counter(ns).most_common(3)}")


if __name__ == '__main__':
    main()
