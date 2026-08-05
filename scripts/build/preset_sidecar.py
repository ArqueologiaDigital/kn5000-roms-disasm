#!/usr/bin/env python3
"""Emit the non-musical sidecar needed to rebuild a demo preset from its MIDI.

A `.mid` carries the musical content (notes, and every other event preserved
verbatim), but a preset `.bin` also contains things that are not music and cannot
live in a MIDI file:

  * the song header +0x00..+0x800 (track types, present flags, ...)
  * the cell allocation and link topology
  * the three leading bytes of every cell (unused by the reader, values vary)
  * unreached cells and trailing padding
  * the exact stream ORDER: the factory streams are not strictly time-sorted
    (about 200 of 43,348 events are out of order, e.g. two notes at position
    0x5F then 0x5E within one beat), so sorting by time does not reproduce them

The sidecar stores exactly those, plus a per-track pattern describing how notes
and other events interleave. Note VALUES still come from the MIDI, so editing
pitch/velocity/timing in a DAW is honoured; only the structure comes from here.
"""
import argparse
import base64
import json
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from demo_preset_to_midi import (cells, split_events, split_events_ex,
                                 TICKS_PER_BEAT, CELL_PAYLOAD)


def cell_chain(song, start):
    c, seen, out = start, set(), []
    while c not in (0, 0xFFFF) and c not in seen:
        seen.add(c)
        base = 0x800 + (c - 1) * 256
        if base + 256 > len(song):
            break
        out.append(c)
        c = struct.unpack_from('<H', song, base + 3)[0]
    return out


def build(song):
    """Return (sidecar_dict, covered_positions)."""
    sc = {'size': len(song), 'tracks': {}}
    covered = bytearray(len(song))          # 1 = produced from the MIDI stream

    for t in range(16):
        if not (song[0xD0 + t * 3] & 0x80):
            continue
        start = struct.unpack_from('<H', song, 0xD0 + t * 3 + 1)[0]
        chain = cell_chain(song, start)
        stream = bytes(cells(song, start))
        evs = split_events_ex(stream)

        pattern, note_status, notes_seq, raws = [], [], [], []
        beat = 0
        for st, data, explicit in evs:
            if st == 0x81:
                pattern.append('B')
                beat += 1
                continue
            if st == 0x83:
                pattern.append('E')
                break
            if st & 0xF0 == 0x90 and len(data) == 5:
                pos, note, vel, durl, durh = data
                pattern.append('N')
                note_status.append(st if explicit else -1)
                notes_seq.append((beat * TICKS_PER_BEAT + pos, note, vel,
                                  durh * TICKS_PER_BEAT + durl, durl, durh))
            else:
                pattern.append('R')
                blob = (bytes([st]) if explicit else b'') + data
                raws.append(base64.b64encode(blob).decode())

        # MIDI cannot represent two same-pitch notes overlapping on one channel with
        # crossing durations: note-off pairing is FIFO, so the durations come back
        # swapped. Simulate the write/read pairing and record only the notes whose
        # duration does not survive, so the MIDI stays authoritative for the rest.
        midi_order = sorted(range(len(notes_seq)), key=lambda i: (notes_seq[i][0], i))
        stream_ev = []
        for mi, si in enumerate(midi_order):
            tick, note, vel, dur = notes_seq[si][:4]
            stream_ev.append((tick, 3, 'on', note, mi))
            stream_ev.append((tick + max(1, dur), 2, 'off', note, mi))
        stream_ev.sort(key=lambda e: (e[0], e[1]))
        pend, got = {}, {}
        for tick, _o, kind, note, mi in stream_ev:
            if kind == 'on':
                pend.setdefault(note, []).append((tick, mi))
            else:
                q = pend.get(note)
                if q:
                    t0, owner = q.pop(0)
                    got[owner] = max(1, tick - t0)
        # A fixup is needed when the duration does not survive the MIDI round-trip,
        # OR when the original (low, high) pair is not what dur%96 / dur//96 would
        # regenerate -- a few records carry a low byte above 95, so the base-96
        # split does not reproduce them. Store the raw byte pair in both cases.
        dur_fix = {}
        for mi, si in enumerate(midi_order):
            dur, durl, durh = notes_seq[si][3], notes_seq[si][4], notes_seq[si][5]
            rt = got.get(mi)
            if rt != max(1, dur) or (rt or 0) % 96 != durl or (rt or 0) // 96 != durh:
                dur_fix[str(si)] = [durl, durh]

        # How the stream's note order maps onto the MIDI's tick-sorted note order.
        order = sorted(range(len(notes_seq)),
                       key=lambda i: (notes_seq[i][0], i))
        rank = [0] * len(order)
        for midi_index, stream_index in enumerate(order):
            rank[stream_index] = midi_index

        sc['tracks'][str(t)] = {
            'start_cell': start,
            'chain': chain,
            'cell_prefix': {str(c): list(song[0x800 + (c - 1) * 256:
                                              0x800 + (c - 1) * 256 + 3])
                            for c in chain},
            'stream_len': len(stream),
            'used_len': 0,
            'pattern': ''.join(pattern),
            'note_status': note_status,
            'note_order': rank,
            'dur_fix': dur_fix,
            'raws': raws,
        }

        # Mark the payload bytes this track's stream occupies.
        consumed = 0
        consumed = 0
        for st, d, ex in evs:
            consumed += (1 if ex else 0) + len(d)
            if st == 0x83:
                break
        sc['tracks'][str(t)]['used_len'] = consumed
        left, ci = consumed, 0
        while left > 0 and ci < len(chain):
            base = 0x800 + (chain[ci] - 1) * 256 + 5
            n = min(CELL_PAYLOAD, left)
            for k in range(n):
                covered[base + k] = 1
            left -= n
            ci += 1

    # Everything not produced from a MIDI stream is stored verbatim as runs.
    residue, i, n = [], 0, len(song)
    while i < n:
        if covered[i]:
            i += 1
            continue
        j = i
        while j < n and not covered[j]:
            j += 1
        residue.append([i, base64.b64encode(song[i:j]).decode()])
        i = j
    sc['residue'] = residue
    return sc, covered


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('inputs', nargs='+')
    ap.add_argument('-o', '--output-dir', required=True)
    args = ap.parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    for path in args.inputs:
        song = open(path, 'rb').read()
        sc, covered = build(song)
        name = os.path.splitext(os.path.basename(path))[0]
        out = os.path.join(args.output_dir, name + '.json')
        with open(out, 'w') as f:
            json.dump(sc, f, separators=(',', ':'))
        cov = sum(covered)
        print('%-20s %6d bytes, %6d from MIDI (%4.1f%%), %5d residue runs -> %s'
              % (name, len(song), cov, 100 * cov / len(song),
                 len(sc['residue']), os.path.basename(out)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
