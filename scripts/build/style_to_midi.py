#!/usr/bin/env python3
"""style_to_midi.py -- the 210 factory accompaniment styles as Standard MIDI Files.

QUESTION ANSWERED
-----------------
`custom_data` is 639,296 bytes of accompaniment style data.  It is already readable --
`scripts/build/style_events.py` exports it as `.styles` event listings that rebuild the
ROM byte for byte, and that listing REMAINS THE BUILD SOURCE.  What it is not is
PLAYABLE.  This writes the same event streams out as Standard MIDI Files so a human
can hear what is in the chip.

`scripts/analysis/style_directory_chains.py` establishes which chains belong to which
named style (240 directory records x 5 chains = all 1,200 linked chains, a bijection),
so each file is one directory record and carries the style's own 16-character name.

THE MAPPING, and where it is faithful
-------------------------------------
Format 1, 96 ticks per quarter note -- 96 is the format's own resolution, read out of
the firmware's timing routine (docs/accompaniment-style-format.md), not chosen here.

  stream event            MIDI
  ------------------------------------------------------------------------------
  0x81 BEAT               advances the beat counter; tick = beat * 96 + pos
  0x90 NOTE  p n v dt db  note on (n, v) at tick, note off at tick + db*96 + dt
  0x91 NOTE2 p n v dt db x y   the same note; x and y are NOT decoded for this
                          corpus (see below) and are preserved verbatim instead
  0xD1 CTL1  p v          control change 1   (modulation)
  0xD2 CTL2  p v          PITCH BEND, 14-bit = (v << 7) | (2v - 128 if v >= 64 else 0)
  0xD3 CTL3  p v          control change 64  (damper pedal)
  0x83 END                end of the chain

The controller identities are not guesses: `SeqPerformance_EventDispatch` (ROM
0xFE89A8) holds the selector bodies in order, each ending in `SndPart_SetParam` with a
parameter id -- 1, 432 (pitch bend, not a CC), 64, 10, 11, 94 -- and selector 3 reaches
a literal `0xB0` with controller number `0x40`.  Selectors 4-6 do not occur in the
factory data.

WHAT IS NOT DECODED, AND IS THEREFORE NOT INVENTED
--------------------------------------------------
* **Tempo.**  A style has none; the player supplies it.  The files carry a nominal
  120 BPM (`--bpm`) and say so, exactly as the demo-song MIDIs do.
* **The MIDI channel / instrument.**  The part is not in the stream -- at runtime it
  comes from RAM 0x7E52 and becomes the low nibble of the status.  Each of the five
  chains is put on its own channel (0..4) purely so they are separable by ear; no
  program change is emitted and no General MIDI instrument is claimed.
* **NOTE2's two extra bytes.**  The KN5000's own emitter can produce three distinct
  pairs; this corpus contains 57, so the styles were authored on other equipment whose
  table is not in these ROMs.  They are written verbatim into a sequencer-specific
  meta event, never rendered as sound.
* **The five slots' musical roles.**  Five chains per style is consistent with a
  KN-series style's parts, but nothing here establishes the ORDER, so the tracks are
  named "slot 0".."slot 4".

NOTHING IS DISCARDED.  Every non-note event is ALSO written verbatim as
`FF 7F <len> <status> <args...>` at its tick, so the MIDI carries the complete event
stream even where the meaning is unknown.  `--verify` reads the files back and asserts
that every NOTE and every controller event survives the round trip.

⚠ THE MIDI IS A DERIVED, PLAYABLE VIEW -- NOT THE BUILD SOURCE.  It cannot hold the
cell allocation and link topology, the PAD bytes after 0x83, or which statuses were
explicit; `custom_data/styles/*.styles` holds all of that and is what the ROM is built
from.  Presenting the MIDI as the data would lose those bytes.

USAGE
-----
  python3 scripts/build/style_to_midi.py build     # -> custom_data/styles/midi/
  python3 scripts/build/style_to_midi.py verify    # round-trip the event streams
  python3 scripts/build/style_to_midi.py stats     # what is in the corpus

Run from the repository root.
"""
import argparse
import os
import re
import struct
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, 'scripts', 'build'))
sys.path.insert(0, os.path.join(REPO, 'scripts', 'analysis'))
import style_events as SE                      # noqa: E402
import style_directory_chains as SDC           # noqa: E402
from demo_preset_to_midi import vlq, chunk, build_track, meta_text  # noqa: E402

OUT = os.path.join(REPO, 'custom_data', 'styles', 'midi')
TICKS_PER_BEAT = 96
CTL_CC = {0xD1: 1, 0xD3: 64}          # 0xD2 is pitch bend, not a control change


def chain_payload(d, cells, base, head):
    """Concatenated 249-byte payloads of the chain starting at `head`."""
    cs = set(cells)
    out, o, seen = bytearray(), head, set()
    while o is not None and o not in seen:
        seen.add(o)
        out += d[o + 6:o + 255]
        nx = d[o + 3] | (d[o + 4] << 8)
        o = ((nx & 0xFFF) + base) * 256 if nx != 0xFFFF else None
        if o is not None and o not in cs:
            break
    return bytes(out)


def decode(payload):
    """-> (notes, others).  notes: (tick, note, vel, dur, extra_bytes).
    others: (tick, status, args)."""
    notes, others, beat, i = [], [], 0, 0
    while i < len(payload):
        st = payload[i]
        if st == 0x83:
            break
        n = SE.ARGS.get(st)
        if n is None:
            break
        a = payload[i + 1:i + 1 + n]
        if len(a) < n:
            break
        if st == 0x81:
            beat += 1
        elif st in (0x90, 0x91):
            tick = beat * TICKS_PER_BEAT + a[0]
            dur = a[4] * TICKS_PER_BEAT + a[3]
            notes.append((tick, a[1], a[2], dur, bytes(a[5:])))
            others.append((tick, st, bytes(a)))
        else:
            others.append((beat * TICKS_PER_BEAT + a[0], st, bytes(a)))
        i += 1 + n
    return notes, others


def bend14(v):
    """The firmware's 7-to-14-bit expansion at ROM 0xFE89C4."""
    return (v << 7) | ((2 * v - 128) if v >= 64 else 0)


def build_file(bank, dirn, rec, name, heads, d, cells, base, bpm=120):
    us = int(round(60_000_000 / bpm))
    title = f'{bank} dir {dirn} record {rec:02d}: {name}'
    cond = [(0, 0, meta_text(0x03, title)),
            (0, 1, b'\xFF\x51\x03' + struct.pack('>I', us)[1:]),
            (0, 2, b'\xFF\x58\x04\x04\x02\x18\x08')]
    tracks = [build_track(cond)]
    counts = dict(notes=0, others=0)
    for slot, head in enumerate(heads):
        notes, others = decode(chain_payload(d, cells, base, head))
        counts['notes'] += len(notes)
        counts['others'] += len(others)
        ch = slot & 0x0F
        ev = [(0, 0, meta_text(0x03, f'slot {slot} chain 0x{head >> 8:03X}'))]
        for tick, st, args in others:
            if st in CTL_CC:
                ev.append((tick, 1, bytes([0xB0 | ch, CTL_CC[st], args[1] & 0x7F])))
            elif st == 0xD2:
                b = bend14(args[1] & 0x7F)
                ev.append((tick, 1, bytes([0xE0 | ch, b & 0x7F, (b >> 7) & 0x7F])))
            # verbatim carrier, for every non-BEAT event including the notes
            raw = bytes([st]) + args
            ev.append((tick, 1, b'\xFF\x7F' + vlq(len(raw)) + raw))
        for tick, note, vel, dur, _extra in notes:
            ev.append((tick, 3, bytes([0x90 | ch, note & 0x7F, vel & 0x7F])))
            ev.append((tick + max(dur, 1), 2, bytes([0x80 | ch, note & 0x7F, 0x40])))
        tracks.append(build_track(ev))
    head_chunk = struct.pack('>HHH', 1, len(tracks), TICKS_PER_BEAT)
    return chunk(b'MThd', head_chunk) + b''.join(tracks), counts


def safe(name):
    s = re.sub(r'[^A-Za-z0-9]+', '_', name).strip('_')
    return s or 'unnamed'


def iter_records():
    """One yield per directory record.

    ⚠ The cell set MUST come from the record's OWN HK section.  `section_1_2` and its
    siblings are one file holding TWO directories, so keying the cell set by bank name
    silently gave every record of the first directory the second's cells: 140 of the
    1,050 IC19 chains then walked short and 5,391 events vanished, with nothing raising
    an error.  Caught by comparing the event census against the published one in
    docs/accompaniment-style-format.md.
    """
    ordinal = {}
    for bank, d, s, base, _chains in SDC.banks():
        cells = None
        for a, b in SE.hk_sections(d):
            if a <= s < b:
                cells = SE.cells_of(d, a, b)
                break
        assert cells, (bank, s)
        # ⚠ A BLOB CAN HOLD TWO DIRECTORIES. `section_1_2` and its siblings each carry
        # two, both numbering their records 0..29, so bank+record is NOT unique: naming
        # files by it silently produced 227 files for 240 records, 13 of them
        # overwritten. `d0`/`d1` is the directory's ordinal within the blob.
        dirn = ordinal.get(bank, 0)
        ordinal[bank] = dirn + 1
        for r in range(SDC.N_RECS):
            rec = s + SDC.DIR_OFF + r * SDC.REC_SIZE
            if rec + SDC.REC_SIZE > len(d):
                break
            name = d[rec + SDC.NAME_OFF:rec + SDC.NAME_OFF + SDC.NAME_LEN]
            name = name.decode('latin-1').replace('\x00', ' ').strip()
            heads = [(((d[rec + k] | (d[rec + k + 1] << 8)) & 0x0FFF) + base) * 256
                     for k in SDC.PTR_SLOTS]
            yield bank, dirn, r, name, heads, d, cells, base


def cmd_build(bpm=120):
    os.makedirs(OUT, exist_ok=True)
    n = tot_notes = tot_other = 0
    empty = []
    for bank, dirn, rec, name, heads, d, cells, base in iter_records():
        blob, c = build_file(bank, dirn, rec, name, heads, d, cells, base, bpm)
        path = os.path.join(OUT, f'{bank}_d{dirn}_r{rec:02d}_{safe(name)}.mid')
        with open(path, 'wb') as f:
            f.write(blob)
        n += 1
        tot_notes += c['notes']
        tot_other += c['others'] - c['notes']
        if c['notes'] == 0:
            empty.append(os.path.basename(path))
    print(f"wrote {n} MIDI files to {os.path.relpath(OUT, REPO)}")
    print(f"  {tot_notes:,} note events, {tot_other:,} controller events")
    print(f"  {len(empty)} file(s) carry no notes at all "
          f"(empty factory slots, kept so the set is complete)")
    for e in empty[:10]:
        print(f"    {e}")
    if len(empty) > 10:
        print(f"    ... (+{len(empty) - 10})")


def read_midi_meta(blob):
    """Pull every FF 7F sequencer-specific payload back out of a MIDI file."""
    out = []
    assert blob[:4] == b'MThd'
    ntrk = struct.unpack_from('>H', blob, 10)[0]
    p = 8 + struct.unpack_from('>I', blob, 4)[0]
    for _ in range(ntrk):
        assert blob[p:p + 4] == b'MTrk', blob[p:p + 4]
        ln = struct.unpack_from('>I', blob, p + 4)[0]
        end = p + 8 + ln
        q = p + 8
        running = None
        while q < end:
            while blob[q] & 0x80:      # delta time
                q += 1
            q += 1
            st = blob[q]
            if st == 0xFF:
                kind = blob[q + 1]
                q += 2
                ln2, sh = 0, 0
                while True:
                    b = blob[q]
                    q += 1
                    ln2 |= (b & 0x7F) << sh
                    if not b & 0x80:
                        break
                    ln2 <<= 0
                    sh += 7
                body = blob[q:q + ln2]
                q += ln2
                if kind == 0x7F:
                    out.append(body)
                continue
            if st & 0x80:
                running = st
                q += 1
            elif running is None:
                raise ValueError('running status with no status')
            nargs = 1 if (running & 0xF0) in (0xC0, 0xD0) else 2
            q += nargs
        p = end
    return out


def cmd_verify(bpm=120):
    bad = 0
    tot = rec_ev = 0
    for bank, dirn, rec, name, heads, d, cells, base in iter_records():
        want = []
        for head in heads:
            _n, others = decode(chain_payload(d, cells, base, head))
            want += [bytes([st]) + args for _t, st, args in others]
        blob, _ = build_file(bank, dirn, rec, name, heads, d, cells, base, bpm)
        got = read_midi_meta(blob)
        tot += len(want)
        rec_ev += len(got)
        if sorted(want) != sorted(got):
            bad += 1
            print(f"  MISMATCH {bank} d{dirn} r{rec:02d} {name!r}: "
                  f"{len(want)} events, {len(got)} recovered")
    print(f"round trip: {rec_ev:,}/{tot:,} non-BEAT events recovered from the MIDI, "
          f"{bad} file(s) mismatched")
    return bad


def cmd_stats():
    from collections import Counter
    c = Counter()
    nrec = 0
    for bank, dirn, rec, name, heads, d, cells, base in iter_records():
        nrec += 1
        for head in heads:
            pay = chain_payload(d, cells, base, head)
            i = 0
            while i < len(pay):
                st = pay[i]
                if st == 0x83:
                    c['0x83 END'] += 1
                    break
                n = SE.ARGS.get(st)
                if n is None:
                    c['unrecognised'] += 1
                    break
                c[f'0x{st:02X} {SE.NAME[st]}'] += 1
                i += 1 + n
    print(f"{nrec} directory records, {nrec * 5} chains")
    for k, v in sorted(c.items()):
        print(f"  {k:16s} {v:7,}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('cmd', choices=['build', 'verify', 'stats'])
    ap.add_argument('--bpm', type=float, default=120)
    a = ap.parse_args()
    if a.cmd == 'build':
        cmd_build(a.bpm)
    elif a.cmd == 'verify':
        sys.exit(1 if cmd_verify(a.bpm) else 0)
    else:
        cmd_stats()


if __name__ == '__main__':
    main()
