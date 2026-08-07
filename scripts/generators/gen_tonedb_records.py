#!/usr/bin/env python3
"""Generate table_data tone-database record assembly (package p6-tonedb-records).

Reads the original KN5000 table-data ROM, extracts the 629-entry LE32
stream-offset table at 0x831B00 (offsets relative to the database base
0x830000, exactly as subcpu DSP1_ResolveStreamPtr applies them), and emits a
static .s fragment covering ROM [0x8324D4, 0x855A48) — the 579 variable-length
tone/voice parameter records — with one ToneRec_NNN label per table index.

The OUTPUT (tone_database_records.s) is the authoritative source; this script
is only the one-time generator kept for provenance.
"""
import struct
from collections import defaultdict

import os
_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(_REPO, "original_ROMs", "kn5000_table_data.rom")
OUT_PATH = "tone_database_records.s"  # written to the current directory
BASE = 0x800000
DB_BASE = 0x830000
TBL_ADDR = 0x831B00
N_ENTRIES = 629
LO, HI = 0x8324D4, 0x855A48

rom = open(ROM_PATH, "rb").read()

def rd(addr, n):
    return rom[addr - BASE:addr - BASE + n]

# ---- extract the offset table -------------------------------------------------
offsets = struct.unpack("<%dI" % N_ENTRIES, rd(TBL_ADDR, N_ENTRIES * 4))
addrs = [DB_BASE + o for o in offsets]
bias = struct.unpack("<H", rd(DB_BASE + 0x88, 2))[0]
assert bias == 0x152

by_addr = defaultdict(list)
for i, a in enumerate(addrs):
    if LO <= a < HI:
        by_addr[a].append(i)

starts = sorted(by_addr)
assert starts[0] == LO
sizes = {}
for i, a in enumerate(starts):
    end = starts[i + 1] if i + 1 < len(starts) else HI
    sizes[a] = end - a
    assert (sizes[a] - 21) % 81 == 0 and 1 <= (sizes[a] - 21) // 81 <= 5, hex(a)

# ---- emit ---------------------------------------------------------------------
TAB = 8
COMMENT_COL = 112  # tab stop just past the widest 16-value .byte row

def vcol(s):
    col = 0
    for ch in s:
        col = (col // TAB + 1) * TAB if ch == "\t" else col + 1
    return col

def row(bytes_, off, tag=None):
    txt = "\t.byte\t" + ", ".join("0x%02x" % b for b in bytes_)
    while vcol(txt) < COMMENT_COL:
        txt += "\t"
    txt += "; +0x%02x" % off if tag is None else "; +0x%02x %s" % (off, tag)
    return txt + "\n"

hdr = """\
; =============================================================================
; TONE DATABASE - TONE/VOICE PARAMETER RECORDS (ToneRec_000 .. ToneRec_628)
; =============================================================================
; 579 variable-length tone records tiling ROM 0x8324D4-0x855A47 with no gaps
; or padding.  They are the payload behind the 629-entry stream-offset table
; at 0x831B00: each table entry is a LE32 offset relative to the database base
; 0x830000.  At boot, SubCPU_Send_Payload (maincpu) copies 0x830000-0x87FFFF
; into SubCPU RAM at 0x50000, so the SubCPU sees these records at 0x524D4+.
;
; Pointer resolution (subcpu DSP1_ResolveStreamPtr):
;   ptr = 0x50000 + LE32[0x51B00 + 4*(arg + bias)],  bias = word @0x50088 = 0x152
; so table index = caller's stream number + 338.  Index map:
;   000-309  reached with negative stream numbers (-338..-29)
;   310-337  drum kits (0x863079+) and drawbar records (0x8706BD+); those
;            targets are OUTSIDE this module (see the aux-tables region)
;   338-377  stream numbers 0-39 (the 5-block flagship tones)
;   378-399  stream numbers 40-61: duplicate offsets of index 0 ("Piano"),
;            i.e. unused live-slot entries falling back to the default tone
;   400-628  stream numbers 62-290 (GM-style bank, ends with "Gun Shot")
;
; Records are labeled ToneRec_NNN, NNN = zero-padded decimal table index (the
; same scheme the 0x831B00 table module uses).  This file is in ADDRESS order,
; which is index order 000-309, then 400-628, then 338-377.
;
; RECORD LAYOUT (record length = 21 + 81*N bytes, N = 1..5 blocks; the length
; is implied by the distance to the next record's table offset - no explicit
; size field was found):
;   +0x00  16-byte space-padded ASCII tone name
;   +0x10  5-byte layer-configuration field: bytes 0-3 hold 2-bit sub-fields
;          whose values are only ever 0 or 1 (semantics undetermined; the
;          popcount matches the block count for 311 of 579 records, so it is
;          NOT a plain block count); byte 4 is 0x55 in all 579 records
;   +0x15  81-byte COMMON block: starts 0x81 0x40 in all 579 records; block
;          offsets +8,+9,+11,+12,+36,+48,+52,+53,+64,+68,+69 are always 0x00
;          and +10,+13 always 0x40
;   +0x66  zero to four further 81-byte LAYER blocks (per-layer parameters)
;
; FIELD OBSERVATIONS (from sibling records differing in one known property):
;   layer block +19: semitone offset - "Piano"=66, "Piano 1 Octave"=54,
;       "Piano 2 Octave"=42 (12 per octave; block offsets +48/+73 track it)
;   layer block +54/+55/+62/+69: differ between "Piano" and "Bright Piano",
;       so timbre/filter-related
;   subcpu DSP_Reinit_VoiceSlots always copies 0xD5 words (426 bytes, the
;       maximum record size) from the resolved pointer, over-reading into the
;       following record for shorter tones
; =============================================================================
"""

out = [hdr]

SEGMENT_BANNERS = {
    400: "; --- GM-style bank: indices 400-628 (stream numbers 62-290) ---\n",
    338: "; --- flagship 5-block tones: indices 338-377 (stream numbers 0-39) ---\n",
}

for a in starts:
    idxs = by_addr[a]
    prim = min(idxs)
    name16 = rd(a, 16).decode("ascii")
    assert all(0x20 <= ord(c) < 0x7F for c in name16)
    assert '"' not in name16 and "\\" not in name16
    nblk = (sizes[a] - 21) // 81

    out.append("\n")
    if prim in SEGMENT_BANNERS:
        out.append(SEGMENT_BANNERS[prim])
        out.append("\n")
    label = "ToneRec_%03d:" % prim
    cmt = '; "%s"' % name16.strip()
    if len(idxs) > 1:
        cmt += " - also table indices %d-%d (see .equ aliases below)" % (
            min(idxs[1:]), max(idxs[1:]))
    out.append("%s\t%s\n" % (label, cmt))
    out.append('\t.ascii\t"%s"\n' % name16)
    out.append(row(rd(a + 16, 5), 0x10, "layer configuration"))
    p = a + 21
    off = 0x15
    for b in range(nblk):
        out.append("\t; %s\n" % ("common block" if b == 0 else "layer block %d" % b))
        blk = rd(p, 81)
        for r in range(0, 81, 16):
            out.append(row(blk[r:r + 16], off + r))
        p += 81
        off += 81

    if len(idxs) > 1:
        out.append("\n; Duplicate stream-offset-table entries: indices %d-%d "
                   "all hold offset 0x%04x,\n"
                   "; pointing unused live-slot stream numbers 40-61 at the "
                   "default \"Piano\" record.\n" % (min(idxs[1:]), max(idxs[1:]),
                                                    a - DB_BASE))
        for i in sorted(idxs[1:]):
            out.append(".equ ToneRec_%03d, ToneRec_%03d\n" % (i, prim))

with open(OUT_PATH, "w") as f:
    f.write("".join(out))

total = sum(sizes.values())
print("records:", len(starts), "bytes:", total, "expected:", HI - LO)
assert total == HI - LO
print("wrote", OUT_PATH)
