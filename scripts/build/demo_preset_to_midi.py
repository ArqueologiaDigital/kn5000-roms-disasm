#!/usr/bin/env python3
"""Convert a decompressed KN5000 demo song preset into a Standard MIDI File.

Input is a decompressed preset (see table_data/includes/demo_presets/README.md):

    +0x1E   u16       track-enable mask
    +0x20   16 x u8   track type
    +0xD0   16 x      { u8 flags (bit7 = present), u16 start cell }
    +0x800  cells     cell c at +0x800 + (c-1)*256
                      cell: [0..2] unused by the reader (values vary),
                            [3..4]=u16 next cell (0xFFFF = end),
                            [5..255]=250 payload bytes

Event stream: a byte with bit 7 set is a status byte; the bytes after it with bit 7
clear are its data.

    0x81            advance one beat
    0x83            end of track
    0x9n + 5 bytes  note: [pos, note, velocity, dur_ticks, dur_beats]
    0x82 + n bytes  text / CUE data (emitted as a MIDI marker when printable)

TIMING (validated on the Feature Presentation: 3842 of 3843 note events have a
non-decreasing position within their beat):
    pos is the tick within the current beat, 0..95  =>  96 ticks per beat
    absolute tick = beat * 96 + pos
    duration      = dur_beats * 96 + dur_ticks
Both pos and dur_ticks are bounded by 95, which is why this is base-96 and not a
plain 16-bit little-endian value.

NOT DECODED: the tempo (use --bpm) and the part -> instrument mapping. Track types
are carried through as MIDI track names so nothing is silently invented; no program
change is emitted. Use --drum-track to route a percussion part to MIDI channel 10.
"""
import argparse
import os
import struct
import sys

TICKS_PER_BEAT = 96
CELL_PAYLOAD = 250


def cells(song, start):
    """Yield the payload bytes of the cell chain beginning at cell `start`."""
    c, seen = start, set()
    while c not in (0, 0xFFFF) and c not in seen:
        seen.add(c)
        base = 0x800 + (c - 1) * 256
        if base + 256 > len(song):
            break
        nxt = struct.unpack_from('<H', song, base + 3)[0]
        yield from song[base + 5: base + 5 + CELL_PAYLOAD]
        c = nxt


def split_events_ex(stream):
    """Split a byte stream into (status, data, status_was_explicit) triples.

    The stream uses MIDI-style RUNNING STATUS: a data run with no preceding status
    byte repeats the last non-structural status. 0x81 (beat) and 0x83 (end) are
    structural -- they carry no data and do not clear the running status, so
    `81 22 4C 6C 0C 00` is a beat marker followed by a note that reuses the
    previous 0x9n status. Note records are 5 bytes, so a run is split accordingly.
    """
    out, i, n = [], 0, len(stream)
    running = None
    while i < n and not (stream[i] & 0x80):
        i += 1                                  # leading data with no status
    while i < n:
        b = stream[i]
        if b & 0x80:
            i += 1
            if b in (0x81, 0x83):
                out.append((b, b'', True))
                if b == 0x83:
                    return out
                continue
            running = st = b
            explicit = True
        else:
            st = running
            explicit = False
            if st is None:
                i += 1
                continue
        start = i
        while i < n and not (stream[i] & 0x80):
            i += 1
        data = stream[start:i]
        if st & 0xF0 == 0x90 and len(data) >= 5:
            for k in range(0, len(data) - 4, 5):
                out.append((st, data[k:k + 5], explicit and k == 0))
            rem = len(data) % 5
            if rem:
                out.append((st, data[len(data) - rem:], False))
        else:
            out.append((st, data, explicit))
    return out


def split_events(stream):
    """Pairs-only view of split_events_ex, for callers that ignore running status."""
    return [(st, d) for st, d, _ in split_events_ex(stream)]


def parse_track(song, start_cell):
    """Return (notes, others, total_beats).

    notes:  (tick, note, velocity, duration_ticks)   -- firmware-confirmed layout
    others: (tick, status, data)                     -- every non-note event, verbatim

    Field layout is confirmed from the firmware's own event queue (f57040), which
    stores status, then note (0x342F, compared against a note register at f57006),
    then velocity (0x3430), then duration low (0x3431 -- with an explicit "if zero
    then one") and duration high (0x3432). The 96-ticks-per-beat base is the literal
    0x60 in the timing routine f570BB.
    """
    notes, others, beat = [], [], 0
    for st, data in split_events(bytes(cells(song, start_cell))):
        if st == 0x81:
            beat += 1
            continue
        if st == 0x83:
            break
        # data[0] is the tick within the current beat for EVERY event family
        # (verified: 100% of 10,330 non-note events have data[0] <= 95).
        tick = beat * TICKS_PER_BEAT + (data[0] if data else 0)
        if st & 0xF0 == 0x90 and len(data) == 5:
            pos, note, vel, durl, durh = data
            dur = durh * TICKS_PER_BEAT + durl
            notes.append((beat * TICKS_PER_BEAT + pos, note, vel, max(1, dur)))
        else:
            others.append((tick, st, bytes(data)))
    return notes, others, beat


def vlq(n):
    """MIDI variable-length quantity."""
    out = bytearray([n & 0x7F])
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def chunk(tag, body):
    return tag + struct.pack('>I', len(body)) + bytes(body)


def build_track(events):
    """events: list of (tick, order, payload_bytes) -> an MTrk chunk."""
    events.sort(key=lambda e: (e[0], e[1]))
    body, prev = bytearray(), 0
    for tick, _order, payload in events:
        body += vlq(tick - prev) + payload
        prev = tick
    body += vlq(0) + b'\xFF\x2F\x00'          # end of track
    return chunk(b'MTrk', body)


def meta_text(kind, text):
    raw = text.encode('ascii', 'replace')[:127]
    return bytes([0xFF, kind]) + vlq(len(raw)) + raw


def looks_like_preset(song):
    """Structural sanity check: at least one present track whose start cell resolves
    inside the file. Compressed payloads fail this; decompressed presets pass."""
    if len(song) < 0x900:
        return False
    present = 0
    for t in range(16):
        if not (song[0xD0 + t * 3] & 0x80):
            continue
        c = struct.unpack_from('<H', song, 0xD0 + t * 3 + 1)[0]
        if c in (0, 0xFFFF):
            return False
        if 0x800 + (c - 1) * 256 + 256 > len(song):
            return False
        present += 1
    return present > 0


def convert(song, bpm=120, drum_tracks=(), title='KN5000 demo song', drum_types=(),
            program_changes=False):
    mask = struct.unpack_from('<H', song, 0x1E)[0]
    tracks_out = []

    # Conductor track: tempo + time signature + title.
    us_per_beat = int(round(60_000_000 / bpm))
    cond = [
        (0, 0, meta_text(0x03, title)),
        (0, 1, b'\xFF\x51\x03' + struct.pack('>I', us_per_beat)[1:]),
        (0, 2, b'\xFF\x58\x04\x04\x02\x18\x08'),   # 4/4
    ]
    tracks_out.append(build_track(cond))

    for t in range(16):
        flags = song[0xD0 + t * 3]
        if not (flags & 0x80):
            continue
        start = struct.unpack_from('<H', song, 0xD0 + t * 3 + 1)[0]
        ttype = song[0x20 + t]
        notes, others, _beats = parse_track(song, start)
        if not notes and not others:
            continue

        ch = 9 if (t in drum_tracks or ttype in drum_types) else t
        ev = [(0, 0, meta_text(0x03, 'Part %d (type 0x%02X)%s'
                               % (t, ttype, ' [drums]' if ch == 9 else '')))]
        for tick, st, data in others:
            if st == 0x82:
                text = bytes(b for b in data if 32 <= b < 127).strip()
                if len(text) >= 8:
                    ev.append((tick, 1, meta_text(0x06, text.decode('ascii'))))
            if program_changes and st & 0xF0 == 0xC0 and len(data) >= 4:
                ev.append((tick, 1, bytes([0xC0 | ch, data[3] & 0x7F])))
            # Preserve EVERY non-note event verbatim in a sequencer-specific meta
            # event (FF 7F) so a MIDI -> preset converter can round-trip losslessly.
            raw = bytes([st]) + data
            ev.append((tick, 1, b'\xFF\x7F' + vlq(len(raw)) + raw))
        for tick, note, vel, dur in notes:
            note &= 0x7F
            ev.append((tick, 3, bytes([0x90 | ch, note, vel & 0x7F])))
            ev.append((tick + dur, 2, bytes([0x80 | ch, note, 0x40])))
        tracks_out.append(build_track(ev))

    head = struct.pack('>HHH', 1, len(tracks_out), TICKS_PER_BEAT)
    return chunk(b'MThd', head) + b''.join(tracks_out), mask


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('inputs', nargs='+', help='decompressed demo_preset_NN.bin file(s)')
    ap.add_argument('-o', '--output-dir', default='.', help='where to write .mid files')
    ap.add_argument('--bpm', type=float, default=120.0,
                    help='tempo (the ROM tempo field is not decoded yet; default 120)')
    ap.add_argument('--drum-track', type=int, action='append', default=[],
                    help='route this part index to MIDI channel 10 (repeatable)')
    ap.add_argument('--program-changes', action='store_true',
                    help='emit MIDI Program Change from 0xCn events. OFF by default: the '
                         'value looks like an instrument number (data[2] is always 0, '
                         'data[3] spans 0-127) but KN5000 tone numbers are NOT General '
                         'MIDI, so this makes playback sound confidently wrong.')
    ap.add_argument('--drum-type', type=lambda x: int(x, 0), action='append', default=[],
                    help='route parts with this type byte to MIDI channel 10. Type 0x0C is '
                         'the strongest percussion candidate (median note range 82 vs 39-57 '
                         'for other types, and the highest note count) but is NOT confirmed.')
    args = ap.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    rc = 0
    for path in args.inputs:
        song = open(path, 'rb').read()
        name = os.path.splitext(os.path.basename(path))[0]
        # Guard: this tool takes DECOMPRESSED presets. Check the track table is sane
        # rather than guessing at a magic byte -- cell byte 0 is NOT a fixed marker.
        if not looks_like_preset(song):
            print('%-20s SKIPPED - does not look like a decompressed preset'
                  % name, file=sys.stderr)
            rc = 1
            continue
        mid, mask = convert(song, args.bpm, tuple(args.drum_track), title=name,
                            drum_types=tuple(args.drum_type),
                            program_changes=args.program_changes)
        out = os.path.join(args.output_dir, name + '.mid')
        with open(out, 'wb') as f:
            f.write(mid)
        ntrk = struct.unpack_from('>H', mid, 10)[0]
        print('%-20s mask=%04X  %2d MIDI tracks  %6d bytes -> %s'
              % (name, mask, ntrk, len(mid), os.path.basename(out)))
    return rc


if __name__ == '__main__':
    sys.exit(main())
