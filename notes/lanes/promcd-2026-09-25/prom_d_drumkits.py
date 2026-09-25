#!/usr/bin/env python3
r"""Which drum instrument does each note of each of prom_d's 18 drum kits play?

QUESTION THIS ANSWERS
    Each drum-kit record (tone indices 0x100-0x111, 408 B) ends in a 128-entry
    per-note map, framed in wsa1/prom_d/tone_database_aux.s as `.short` under
    `DrumKit_<n>_<Name>_NoteMap`.  Its banner says the per-note value "is
    consistent with an index into DrumKit_NoteMapA/B ... but that chain has NOT
    been confirmed against code" and "it is still NOT confirmed for the
    per-record map emitted below".  It is confirmed, and this script proves the
    chain from the ROM bytes, resolves all 18 x 128 entries to named drum
    instruments, and (--apply) writes the result above each note map.

THE CHAIN (every instruction asserted below)
    ToneStage_SwitchToPart, prom_c 0xFB8900..0xFB893B: for n = 0..0x7F
    (`cp (XIZ+0xf4),0x80` 0xFB8900), 2*n (`ld C,0x02` 0xFB8913), reads the
    byte at kit + 0x99 + 2n (0xFB891C) and pushes it, then the byte at
    kit + 0x98 + 2n (0xFB892A), and calls ToneStage_LoadPercInstHead (0xFB893B),
    which passes them on as the two selector arguments of
    DrumKit_ResolveInstrumentRecord (call at 0xFB85D5).  That routine
    (prom_c 0xFB48F7) masks the +0x98 byte with 0x7F (program), the +0x99 byte
    with 0x0F (bank) and 0x30 (source: 0 = this image), reads slot +0x74
    (DrumKit_NoteMapA, 0xFB4931) and +0x78 (PercInst, 0xFB4937) and the stride
    word +0xEE = 150 (0xFB493D), and returns
        PercInst + 150 * NoteMapA[bank*128 + program]      (0xFB4947, 0xFB495A)
    So an entry is a BYTE PAIR (program, bank) -- a drum-instrument selector in
    the same encoding as a wave selector -- not an LE16.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_d_drumkits.py          # checks
    python3 notes/lanes/promcd-2026-09-25/prom_d_drumkits.py --apply  # + edit
    PASS = "ALL CHECKS HOLD".
"""
import collections
import os
import re
import struct
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
D = open(os.path.join(W, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(W, "prom_d", "tone_database_aux.s")
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
S = u32

CODE = [(0xFB8900, "8e f4 3f 80", "cp (XIZ+0xf4),0x80"), (0xFB8913, "23 02", "ld C,0x02"),
        (0xFB891C, "e9 c8 99 00 00 00", "add XBC,0x99"), (0xFB892A, "e9 c8 98 00 00 00", "add XBC,0x98"),
        (0xFB893B, "1e 40 fc", "calr ToneStage_LoadPercInstHead"),
        (0xFB85D5, "1d f7 48 fb", "call DrumKit_ResolveInstrumentRecord"),
        (0xFB4931, "ac 74 21", "ld XBC,(XIX+0x74)"), (0xFB4937, "ac 78 20", "ld XWA,(XIX+0x78)"),
        (0xFB493D, "d3 f1 ee 00 25", "ld IY,(XIX+0x00ee)"), (0xFB4947, "d9 ee 07", "sll 0x07,BC"),
        (0xFB495A, "d8 45", "mul XIY,WA")]


def resolve():
    for a, enc, what in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        got = C[a - 0xF80000:a - 0xF80000 + len(want)]
        assert got == want, "prom_c 0x%06X %s: %s" % (a, what, got.hex(" "))
    assert u16(0xEE) == 150
    PTR = [u32(0xB80 + 4 * i) for i in range(274)]
    NA = [u16(S(0x74) + 2 * i) for i in range(2048)]
    PI = S(0x78)
    kits = {}
    for t in range(256, 274):
        p = PTR[t]
        assert D[p + 0x10] == 0x80
        notes = []
        for n in range(128):
            pr, f = D[p + 0x98 + 2 * n], D[p + 0x99 + 2 * n]
            assert f & 0x30 == 0, "entry outside this image"
            v = NA[(f & 0x0F) * 128 + (pr & 0x7F)]
            assert v < 504
            notes.append((pr, f, v, D[PI + 150 * v:PI + 150 * v + 13].decode("latin-1").strip()))
        kits[p + 0x98] = (t, D[p:p + 16].decode("latin-1").strip(), notes)
    return kits


def header(t, name, notes):
    played = [(n, x[3]) for n, x in enumerate(notes) if x[2] != 0]
    silent = 128 - len(played)
    body = ("Note map of tone 0x%03X '%s': entry n is the drum-instrument SELECTOR for MIDI note n, "
            "a byte pair (program at +0x98+2n, bank at +0x99+2n) that the firmware reads separately "
            "-- the .short below is only its LE16 view.  ToneStage_SwitchToPart (prom_c 0xFB891C / "
            "0xFB892A) reads it, DrumKit_ResolveInstrumentRecord (0xFB48F7) indexes "
            "DrumKit_NoteMapA with bank*128 + program and scales the result by 150 into PercInst.  "
            "Resolved, %d notes to PercInst record 0 'Silent' and the rest to: " % (t, name, silent)
            + ", ".join("%d '%s'" % (n, x.replace(" ", "\x00")) for n, x in played) + ".")
    return ["; " + x.replace("\x00", " ")
            for x in textwrap.wrap(body, 90, break_long_words=False, break_on_hyphens=False)]


OLD_A = ("; them; it is consistent with an index into DrumKit_NoteMapA/B (slots +0x74\n"
         "; /+0x7C, 2048 entries each, whose values ARE valid drum-instrument\n"
         "; indices), but that chain has NOT been confirmed against code.\n")
NEW_A = ("; them; it is a (program, bank) byte pair resolved through DrumKit_NoteMapA\n"
         "; (slot +0x74, 2048 entries, whose values ARE valid drum-instrument\n"
         "; indices) -- confirmed against code; each kit's NoteMap header gives the\n"
         "; chain and the instrument every note plays (corrected 2026-09-25, lane\n"
         "; promcd: this sentence said the chain was unconfirmed).\n")
OLD_B = "; map; it is still NOT confirmed for the per-record map emitted below.\n"
NEW_B = ("; map; and for the per-record map emitted below it is confirmed too, by\n"
         "; 0xFB891C / 0xFB892A (corrected 2026-09-25, lane promcd).\n")


def apply(kits):
    src = open(SRC, "rb").read().decode("utf-8")
    if "the drum-instrument SELECTOR for MIDI note n" in src:
        sys.exit("already applied")
    for old, new in ((OLD_A, NEW_A), (OLD_B, NEW_B)):
        assert src.count(old) == 1, old[:50]
        src = src.replace(old, new)
    lines = src.split("\n")
    res, done = [], 0
    for i, ln in enumerate(lines):
        if re.match(r"^DrumKit_[0-9A-F]{3}_\w+_NoteMap:$", ln):
            off = int(re.search(r";\s*([0-9A-F]{5})\b", lines[i + 1]).group(1), 16)
            t, name, notes = kits[off]
            res.extend(header(t, name, notes))
            done += 1
        res.append(ln)
    assert done == 18, done
    open(SRC, "wb").write("\n".join(res).encode("utf-8"))
    print("applied: 2 banner corrections, 18 note-map headers")


if __name__ == "__main__":
    kits = resolve()
    c = collections.Counter(x[2] == 0 for _, _, ns in kits.values() for x in ns)
    print("  %d kits x 128 notes resolved; %d to 'Silent', %d to an instrument; %d cited encodings hold"
          % (len(kits), c[True], c[False], len(CODE)))
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply(kits)
