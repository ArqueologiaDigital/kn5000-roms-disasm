#!/usr/bin/env python3
"""Rebuild a decompressed demo preset (.bin) from its MIDI file + sidecar.

    demo_preset_NN.mid + demo_preset_NN.yaml  ->  demo_preset_NN.bin

Note values (pitch, velocity, in-beat position, duration) come from the MIDI, so
editing them in a DAW is honoured. Everything that is not music -- the song header,
cell allocation and link topology, the unused leading bytes of each cell, padding,
and the exact stream order -- comes from the sidecar (see preset_sidecar.py).

The output is expected to match the checked-in .bin byte-for-byte; `--verify`
turns that into a hard check so the build fails loudly rather than silently
shipping different music.
"""
import argparse
import base64
import yaml
import os
import struct
import sys

TICKS_PER_BEAT = 96
CELL_PAYLOAD = 250


def read_midi_notes(path):
    """Return {midi_track_index: [(tick, note, vel, dur), ...]} in tick order."""
    d = open(path, 'rb').read()
    if d[:4] != b'MThd':
        raise ValueError('not a MIDI file: %s' % path)
    ln, = struct.unpack_from('>I', d, 4)
    off = 8 + ln
    out, ti = {}, 0
    while off < len(d):
        if d[off:off + 4] != b'MTrk':
            raise ValueError('bad MTrk at %d' % off)
        tl, = struct.unpack_from('>I', d, off + 4)
        off += 8
        end = off + tl
        t, run, pending, notes, name = 0, None, {}, [], None
        while off < end:
            v = 0
            while True:
                b = d[off]; off += 1
                v = (v << 7) | (b & 0x7F)
                if not b & 0x80:
                    break
            t += v
            st = d[off]
            if st == 0xFF:
                off += 1
                kind = d[off]; off += 1
                L = 0
                while True:
                    b = d[off]; off += 1
                    L = (L << 7) | (b & 0x7F)
                    if not b & 0x80:
                        break
                if kind == 0x03 and name is None:
                    name = d[off:off + L].decode('ascii', 'replace')
                off += L
                continue
            if st & 0x80:
                run = st; off += 1
            else:
                st = run
            hi = st >> 4
            if hi == 0x9:
                n, vel = d[off], d[off + 1]; off += 2
                if vel:
                    pending.setdefault(n, []).append((t, vel, len(notes)))
                    notes.append([t, n, vel, 1])
                else:
                    hi = 0x8
            if hi == 0x8:
                n = d[off]; off += 2
                q = pending.get(n)
                if q:
                    t0, vel, idx = q.pop(0)
                    notes[idx][3] = max(1, t - t0)
            elif hi in (0xA, 0xB, 0xE):
                off += 2
            elif hi in (0xC, 0xD):
                off += 1
        # Track name is "Part <n> (type 0x..)"; match on <n> so that parts the
        # converter skipped (no events) cannot shift the mapping.
        part = None
        if name and name.startswith('Part '):
            try:
                part = int(name.split()[1])
            except (IndexError, ValueError):
                part = None
        out[part if part is not None else -ti] = [tuple(x) for x in notes]
        ti += 1
    return out


def rebuild(sidecar, midi_notes):
    size = sidecar['size']
    song = bytearray(size)

    # 1. everything non-musical, verbatim
    for pos, b64 in sidecar['residue']:
        blob = base64.b64decode(b64)
        song[pos:pos + len(blob)] = blob

    # 2. per track: re-serialise the event stream, then lay it into its cells
    for tkey in sorted(sidecar['tracks'], key=int):
        tr = sidecar['tracks'][tkey]
        notes = midi_notes.get(int(tkey), [])
        stream = bytearray()
        ni = ri = 0
        for ch in tr['pattern']:
            if ch == 'B':
                stream.append(0x81)
            elif ch == 'E':
                stream.append(0x83)
            elif ch == 'R':
                stream += base64.b64decode(tr['raws'][ri]); ri += 1
            else:                                       # 'N'
                midx = tr['note_order'][ni]
                tick, note, vel, dur = notes[midx]

                if tr['note_status'][ni] >= 0:      # -1 = running status, omitted
                    stream.append(tr['note_status'][ni])
                fix = tr.get('dur_fix', {}).get(str(ni))
                durl, durh = (fix if fix is not None
                              else (dur % TICKS_PER_BEAT, dur // TICKS_PER_BEAT))
                stream += bytes([tick % TICKS_PER_BEAT, note & 0x7F, vel & 0x7F,
                                 durl, durh])
                ni += 1
        # lay the stream into the cell chain, 250 payload bytes per cell
        left, ci = len(stream), 0
        src = 0
        while left > 0 and ci < len(tr['chain']):
            base = 0x800 + (tr['chain'][ci] - 1) * 256 + 5
            n = min(CELL_PAYLOAD, left)
            song[base:base + n] = stream[src:src + n]
            src += n; left -= n; ci += 1
    return bytes(song)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--midi', required=True)
    ap.add_argument('--sidecar', required=True)
    ap.add_argument('-o', '--output')
    ap.add_argument('--verify', help='reference .bin that the result must match exactly')
    args = ap.parse_args()

    sc = yaml.safe_load(open(args.sidecar))
    song = rebuild(sc, read_midi_notes(args.midi))
    if args.output:
        with open(args.output, 'wb') as f:
            f.write(song)
    if args.verify:
        ref = open(args.verify, 'rb').read()
        if song == ref:
            print('OK   %s (%d bytes, byte-identical)'
                  % (os.path.basename(args.verify), len(song)))
            return 0
        diff = sum(1 for a, b in zip(song, ref) if a != b) + abs(len(song) - len(ref))
        first = next((i for i, (a, b) in enumerate(zip(song, ref)) if a != b), None)
        print('FAIL %s: %d/%d bytes differ, first at 0x%X'
              % (os.path.basename(args.verify), diff, len(ref), first or -1),
              file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
