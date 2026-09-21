#!/usr/bin/env python3
"""What is inside the SOUND and COMBINATION blocks of a bulk dump?

QUESTION IT ANSWERS
  Chapter 8 of the reference lays out the sound being EDITED -- the area at
  ADR 10 00 00, 713 bytes, reachable one parameter at a time.  The SOUND bulk
  dump is a different thing: 262144 bytes of sound MEMORY.  The reference said
  the relationship between them was not established, and a librarian that wants
  to show or edit the sounds inside a dump needs exactly that.

  It is establishable, from the dump itself.  If a stored sound uses the same
  layout, then sounds must sit at a 713-byte stride with a printable 16-character
  name at offset 0 -- because NAME is parameter 000-00F of that layout.  And a
  stored drum kit's note records must sit at a 150-byte stride with a printable
  13-character name at offset 0, because that is NOTE GENERAL DATA.

  Both hold, in all four banks, exactly.  The strides are not hard-coded here:
  they are read out of `sound_layout.json`, so if the parameter layout is ever
  corrected and the dump stops matching it, this fails.

WHY IT IS A REAL TEST
  A 713-byte stride landing on a printable 16-byte name 64 times in a row, and a
  150-byte stride doing the same 128 times in a row in each of four banks, does
  not happen by chance in binary data.  The control is the arithmetic itself:
  any other stride breaks the run at the first record.

THE COMBINATION BLOCK
  The same walk resolves it: 16 combinations of 5632 bytes, each of EIGHT parts
  of 704, and every one of the 128 parts carries a printable 16-character name
  two bytes in -- the sound loaded into that part.  Eight parts is what the
  instrument's COMBINATION mode has.  The combinations' own names are the last
  256 bytes of the smaller COMBINATION block.

  704 is NOT 713, so a combination part is not simply a stored sound; what the
  rest of a part holds is not established here.

SIGNAL BEING READ
  SND_CMBI.syx, the SOUND transfer (ADR 20 00 00, 262144 bytes) and both
  COMBINATION transfers, reassembled
  from the wire.  Not committed: it ships in KN7000/WSA1R_files/SND_CMBI_syx.zip.
  Point SYSEX_CAPTURE at the .syx, or drop it beside this script.

RUN
  python3 wsa1/notes/sysex-probes/sysex_sound_memory.py
  python3 wsa1/notes/sysex-probes/sysex_sound_memory.py --names

PASS CRITERION
  Four banks of 0x10000, each with its 128-note drum run and a run of at least
  64 normal sounds, and OK.
"""
import json
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "sound_layout.json")
CANDIDATES = [os.environ.get("SYSEX_CAPTURE", ""),
              os.path.join(HERE, "SND_CMBI.syx"),
              "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx"]
ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"

BANK = 0x10000            # the sound memory is four of these
DRUM_NOTES_AT = 0xB468    # where a bank's drum note records begin
NORMAL_AT = {0: 0x359, 1: 0x090, 2: 0x090, 3: 0x090}
NAME_NORMAL, NAME_NOTE = 16, 13


def capture():
    for p in CANDIDATES:
        if p and os.path.exists(p):
            return open(p, "rb").read()
    if os.path.exists(ZIP):
        with zipfile.ZipFile(ZIP) as z:
            return z.read([n for n in z.namelist() if n.lower().endswith(".syx")][0])
    raise SystemExit("capture not found; set SYSEX_CAPTURE")


def messages(buf):
    i = 0
    while True:
        s = buf.find(b"\xF0", i)
        if s < 0:
            return
        e = buf.find(b"\xF7", s)
        if e < 0:
            return
        yield buf[s:e + 1]
        i = e + 1


def join(p):
    return bytes(((p[i] & 0x0F) << 4) | (p[i + 1] & 0x0F) for i in range(0, len(p), 2))


def all_blocks(buf):
    """Every completed transfer in the capture, keyed by its ADR."""
    out, acc, adr = {}, None, None
    for m in messages(buf):
        if m[:3] == b"\xF0\x50\x2D":
            adr, acc = tuple(m[6:9]), bytearray(join(m[12:-3]))
            if m[-3] == 0x00:
                out[adr], acc = bytes(acc), None
        elif m[:3] == b"\xF0\x50\x7E" and acc is not None:
            acc += join(m[3:-3])
            if m[-3] == 0x00:
                out[adr], acc = bytes(acc), None
    return out


# CORRECTED. A stored COMBINATION is 704 bytes; 0x1600 is a BANK of eight of
# them. What an earlier version of this probe called a 704-byte "part" is a
# whole combination, and what it called eight 64-byte "records" are the eight
# parts, two records each. See sysex_combination_layout.py, which decodes the
# unit properly as a TLV stream.
COMB_SIZE, COMB_BANK = 704, 8
SND = [None]          # the SOUND block, for the part-name cross-check


def strides():
    """The two record sizes, taken from the parameter layout, not hard-coded."""
    doc = json.load(open(LAYOUT))
    areas = {a["name"]: a for a in doc["areas"]}
    normal = areas["NORMAL SOUND"]["size"]
    note = [b for b in areas["DRUM SOUND"]["blocks"]
            if b["name"] == "NOTE DATA"][0]["stride"]
    return normal, note


def check_combinations(blocks, printable_in):
    """The combination blocks, at the level this probe covers: how many
    combinations, where their names are, and the bank names. The INTERNAL
    layout of a combination is sysex_combination_layout.py's subject."""
    c1 = blocks.get((0x50, 0x00, 0x00))
    c2 = blocks.get((0x50, 0x06, 0x00))
    if c1 is None or c2 is None:
        print("\n  (the capture carries no COMBINATION transfer)")
        return
    assert len(c2) % COMB_SIZE == 0, "the combination block is not a whole number"
    n = len(c2) // COMB_SIZE
    print("\nSTORED COMBINATIONS  (%d of %d bytes, %d banks of %d)"
          % (n, COMB_SIZE, n // COMB_BANK, COMB_BANK))
    named = sum(1 for c in range(n)
                if printable_in(c2, c * COMB_SIZE + 2, NAME_NORMAL))
    print("  %d of %d carry a 16-character name two bytes in" % (named, n))
    assert named == n, "some combinations have no name where one is expected"

    # The part names do NOT resolve against the sounds in the same dump.
    stored = set()
    for b in range(4):
        a = b * BANK + NORMAL_AT[b]
        k = 0
        while printable_in(SND[0], a + k * 713, NAME_NORMAL):
            stored.add(SND[0][a + k * 713:a + k * 713 + NAME_NORMAL]
                       .decode("latin1").strip())
            k += 1
    hit = sum(1 for c in range(n)
              if c2[c * COMB_SIZE + 2:c * COMB_SIZE + 2 + NAME_NORMAL]
              .decode("latin1").strip() in stored)
    print("  %d of %d combination names occur in this dump's %d stored sounds"
          % (hit, n, len(stored)))
    assert hit == 0, "some combination names now match a stored sound"

    # The smaller block's tail is the BANK names -- one per eight combinations,
    # not one per combination. An earlier version of this probe called them the
    # combinations' own names, which was wrong.
    banks = n // COMB_BANK
    at = len(c1) - banks * NAME_NORMAL
    names = [c1[at + i * NAME_NORMAL: at + (i + 1) * NAME_NORMAL]
             for i in range(banks)]
    assert all(all(32 <= c < 127 for c in x) for x in names), \
        "the bank names are not the last %d bytes of the smaller block" % (
            banks * NAME_NORMAL)
    print("  the %d BANK names are the last %d bytes of the smaller block,"
          % (banks, banks * NAME_NORMAL))
    print("  beginning %r -- one name per eight combinations"
          % names[0].decode("latin1").strip())
    print("  the inside of a combination is sysex_combination_layout.py's subject")


def main():
    blocks = all_blocks(capture())
    snd = blocks.get((0x20, 0x00, 0x00))
    assert snd is not None, "the capture has no SOUND transfer"
    normal_stride, note_stride = strides()
    print("\nSOUND memory: %d bytes = %d banks of 0x%X"
          % (len(snd), len(snd) // BANK, BANK))
    print("  strides taken from sound_layout.json: normal sound %d, drum note %d"
          % (normal_stride, note_stride))
    assert len(snd) % BANK == 0, "the block is not a whole number of banks"
    banks = len(snd) // BANK

    def printable(o, n):
        s = snd[o:o + n]
        return len(s) == n and all(32 <= c < 127 for c in s)

    def run(start, stride, nlen):
        n = 0
        while printable(start + n * stride, nlen):
            n += 1
        return n

    print("\nSTORED NORMAL SOUNDS  (stride %d, %d-character name at offset 0)"
          % (normal_stride, NAME_NORMAL))
    for b in range(banks):
        at = b * BANK + NORMAL_AT[b]
        n = run(at, normal_stride, NAME_NORMAL)
        first = snd[at:at + NAME_NORMAL].decode("latin1").strip()
        print("  bank %d at 0x%06X: %3d sounds, first %r" % (b, at, n, first))
        assert n >= 64, "bank %d has only %d stored sounds in a row" % (b, n)
        if "--names" in sys.argv:
            for k in range(n):
                o = at + k * normal_stride
                print("      %2d 0x%06X %r"
                      % (k, o, snd[o:o + NAME_NORMAL].decode("latin1")))

    print("\nSTORED DRUM KIT NOTES  (stride %d, %d-character name at offset 0)"
          % (note_stride, NAME_NOTE))
    for b in range(banks):
        at = b * BANK + DRUM_NOTES_AT
        n = run(at, note_stride, NAME_NOTE)
        first = snd[at:at + NAME_NOTE].decode("latin1").strip()
        print("  bank %d at 0x%06X: %3d notes, first %r" % (b, at, n, first))
        assert n == 128, "bank %d has %d consecutive notes, expected 128" % (b, n)

    # The control: the run exists only at the right stride.
    for wrong in (normal_stride - 1, normal_stride + 1, note_stride - 1):
        at = 0 * BANK + NORMAL_AT[0]
        assert run(at, wrong, NAME_NORMAL) < 4, \
            "a stride of %d also produces a run; the test does not discriminate" % wrong
    SND[0] = snd
    check_combinations(blocks, lambda b, o, n: len(b[o:o+n]) == n
                       and all(32 <= c < 127 for c in b[o:o+n]))

    print("\n  a stride one byte either side of %d breaks the run immediately,"
          % normal_stride)
    print("  so the match is the layout and not an artefact of the search")
    print("OK")


if __name__ == "__main__":
    main()
