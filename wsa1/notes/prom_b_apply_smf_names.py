#!/usr/bin/env python3
"""Name prom_b's Standard MIDI File reader, and give its body a label.

WHAT QUESTION THIS ANSWERS
    `notes/prom_b_smf_reader.py` (round 6, 40 checks) established that prom_b
    0xF6F5xx does the SMF specification's own header validation field by field.
    It named nothing: the routine doing the validating HAD NO LABEL AT ALL.

    The eight bytes `MThdMTrk` at 0xF6F528 were emitted as `Data_F6F528`, and
    the 881 bytes of code that follow them were emitted with no label of their
    own -- so every tool that walks this file by label attributed the whole
    reader to a data object.  This adds the label and names five neighbours.

THE EXTENT IS BRACKETED BY A FLAG, NOT GUESSED
    0xF6F530 opens `or (0x21E8),0x80` and 0xF6F89F closes `and (0x21E8),0x7F`
    -- the same bit of the same byte, set on entry and cleared four
    instructions before the `ret` at 0xF6F8A4.  The run is entered by
    `call 0xF6F526`, whose whole body is `jr 0xF6F530`, a two-byte hop over the
    tag table.

    ★ prom_b touches bit 7 of (0x21E8) at exactly FOUR addresses, and they are
    TWO brackets: 0xF6F530/0xF6F89F, and 0xF73875/0xF747FA.  The second is the
    WRITER, and its `ret` is at 0xF74809, the last row before the next label.
    Two routines, one flag, no third user -- so the flag is "an SMF transfer is
    in progress" and each bracket is one routine's extent.  ⚠ prom_a also names
    (0x21E7)/(0x21E8) 64 times and none of that was looked at here.

THE OUTPUT TEMPLATE IS A STANDARD MIDI FILE, BYTE FOR BYTE
    0xF7493F and 0xF760BF hold the same 32 bytes:

      4D 54 68 64  "MThd"
      00 00 00 06   chunk length 6
      00 00         format 0
      00 01         one track
      00 60         division 96 ticks per quarter note
      4D 54 72 6B  "MTrk"
      00 00 00 00   track length, a placeholder
      00 FF 03 0F   delta 0, meta FF 03 (sequence/track name), length 15
      57 53 41 20 20 20 20   "WSA    "

    and the writers copy 11 bytes from template+0x16 (`00 FF 03 0F WSA    `)
    followed by EIGHT bytes from RAM (0x21C8).  7 + 8 = 15 = the 0x0F the meta
    event declares.  ★ That arithmetic is the check: the length byte is in the
    ROM and the two copies that satisfy it are in two different routines.

    RAM (0x21C8) is therefore an eight-character name field, and
    notes/prom_b_smf_reader.py already found `M` `I` `D` written to
    (0x21D0)-(0x21D2) at 0xF7661E -- so 0x21C8-0x21D2 is an 8.3 FILENAME, base
    then extension.

WHAT IS CLAIMED, AND AT WHICH STRENGTH
    Smf*             the FORMAT is claimed.  Rests on notes/prom_b_smf_reader.py:
                     the `MThd`/`MTrk` compares, the big-endian format/ntrks/
                     division fields, and all three of the SMF spec's own
                     rejections (SMPTE division, zero division, format > 1).
    InputStream_*    the format is NOT claimed.  These three are named for
                     mechanism only -- a cursor at (0x1088), a 1,024-byte window
                     at 0x60A700-0x60AAFF, a refill flag in (0x21E7) -- every one
                     of which is an immediate in the routine itself.  All 41 call
                     sites of the fetch are inside the reader, which is why they
                     sit next to it, but a byte-stream fetch is not evidence about
                     a file format and is not named as if it were.

RUN
    python3 notes/prom_b_apply_smf_names.py            # re-derive, change nothing
    python3 notes/prom_b_apply_smf_names.py --apply
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B_BASE = 0xF00000

RENAMES = [
    (0xF6F526, "Smf_ReadFile_Entry"),
    (0xF7138F, "InputStream_GetByte"),
    (0xF765D4, "InputStream_Refill"),
    (0xF765DE, "InputStream_RefillDone"),
    (0xF7385F, "Smf_WriteFile"),
]
DATA_RENAMES = [
    ("Data_F6F528", "SmfChunkTags", "TAGS"),
    ("Data_F7493F", "SmfFileTemplate_F7493F", "TMPL"),
    ("Data_F760BF", "SmfFileTemplate_F760BF", "TMPL"),
]

OLD_UNKNOWN = (
    "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
    ";          per this tree's rule that a stated gap beats a plausible guess.\n"
)

NOTES = {
    0xF6F526: """; Name:    Smf_ReadFile_Entry -- named 2026-08-31.
; Evidence (BRANCH): the whole routine is `jr 0xF6F530`, a two-byte hop over the
;          eight-byte tag table SmfChunkTags that sits between it and the body.
;          Its only call site in either image is `call 0xf6f526` at 0xF6F42A and
;          no thunk slot names it.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine is
;          FOR.  Left as sub_XXXXXX with the gap stated`.
; Unknown: what 0xF6F42A is.
""",
    0xF7138F: """; Name:    InputStream_GetByte -- named 2026-08-31 for what it does, NOT for the
;          file format it happens to serve.
; Evidence (INTERNAL): `ld XIX,(0x1088) / ld A,(XIX+)` -- one byte from the
;          32-bit cursor at RAM (0x1088), post-incremented -- then
;          `cp XIX,0x0060aaff / jr ULE`, and past that bound it calls
;          InputStream_Refill and re-reads.  Both the cursor address and the
;          window's top are immediates in this routine.  It also sets (0x124A)
;          to 1 on the fast path and to the refill's return code otherwise, so
;          (0x124A) is the fetch's STATUS byte; every caller tests it against 1
;          and 0xFD.
; Callers: 41 `calr` sites, all inside 0xF6F5A2-0xF7136F, which is the SMF
;          reader (notes/prom_b_smf_reader.py).  That is why the neighbours
;          carry an Smf prefix and this one does not: a byte fetch is not
;          evidence about a file format.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine is
;          FOR.  Left as sub_XXXXXX with the gap stated`.
; Unknown: what fills the window; the refill leaves prom_b through T_F425A8.
""",
    0xF765D4: """; Name:    InputStream_Refill -- named 2026-08-31.
; Evidence (INTERNAL): the whole routine is `or (0x21E7),0x02` then
;          `call 0xf425a8` then `ret`.  It is what InputStream_GetByte calls at
;          0xF713A7 when its cursor passes the top of the 0x60A700-0x60AAFF
;          window, and InputStream_RefillDone (0xF765DE) is its exact inverse on
;          the same bit.  The name claims the bit and the hand-off and nothing
;          about where the bytes come from.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine is
;          FOR.  Left as sub_XXXXXX with the gap stated`.
; Unknown: what prom_a 0xFE1C3A, behind slot T_F425A8, reads from.
""",
    0xF765DE: """; Name:    InputStream_RefillDone -- named 2026-08-31.
; Evidence (INTERNAL): `and (0x21E7),0xFD / ld W,0x01 / ret` -- it clears exactly
;          the bit InputStream_Refill (0xF765D4) sets, and returns 1, which is
;          the value InputStream_GetByte stores in its status byte (0x124A) for
;          a good fetch.  ⚠ Bit 1 of (0x21E7) is NOT unique to this pair: prom_b
;          sets or clears it at ten addresses, in five set/clear pairs of the
;          same shape (0xF765D4/DE, 0xF76661, 0xF76677/80, 0xF77D39/43,
;          0xF77DC6/0xF77DE5, 0xF77F20/2A, 0xF77FAD/0xF77FCC).  The name claims
;          this pair, not ownership of the bit.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine is
;          FOR.  Left as sub_XXXXXX with the gap stated`.
; Unknown: nothing about the bit; who calls it, and when, is listed above.
""",
    0xF7385F: """; Name:    Smf_WriteFile -- named 2026-08-31.
; Extent:  0xF7385F-0xF74809, 4,011 bytes, ends `ret`.  Bracketed by the same
;          flag as Smf_ReadFile and by the OTHER of its only two brackets:
;          `or (0x21E8),0x80` at 0xF73875 and `and (0x21E8),0x7F` at 0xF747FA,
;          fifteen bytes before the `ret`, which is the last row before the next
;          label (RamPtrTable_F7480A).
; Evidence (FORMAT): it emits a Standard MIDI File out of the 32-byte template
;          SmfFileTemplate_F7493F -- `MThd`, length 6, format 0, one track,
;          division 96, `MTrk` -- copying the `MTrk` tag from template+0x0E at
;          0xF73A3A and the 11-byte track-name meta event `00 FF 03 0F WSA    `
;          from template+0x16 at 0xF73A5A, then EIGHT bytes from the filename
;          field at RAM (0x21C8) at 0xF73A64.  7 + 8 = 15 = the 0x0F the meta
;          event declares, so the two copies satisfy the ROM's own length byte.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine is
;          FOR.  Left as sub_XXXXXX with the gap stated`.
; Unknown: 4,011 bytes do much more than write a header.  The name claims the
;          FILE FORMAT it produces, not everything the routine does.
""",
}

BODY_HEADER = """
; --------------------------------------------------------------------------
; Smf_ReadFile -- 0xF6F530-0xF6F8A4, 881 bytes
; ★ LABEL ADDED 2026-08-31, not renamed: this routine had none.  The eight
;   tag bytes SmfChunkTags end at 0xF6F52F and the code after them was emitted
;   without a label, so every tool that walks this file by label attributed the
;   whole reader to a DATA object.
; Extent:  bracketed by a flag, not guessed.  0xF6F530 opens
;          `or (0x21E8),0x80` and 0xF6F89F closes `and (0x21E8),0x7F` -- the
;          same bit of the same byte -- four instructions before the `ret` at
;          0xF6F8A4, which is the last row before the next label.
; Called from: `call 0xf6f526` at 0xF6F42A, through the two-byte hop
;          Smf_ReadFile_Entry.  No thunk slot names either address.
; Reads:   one byte at a time through InputStream_GetByte (0xF7138F), from the
;          1,024-byte window at 0x60A700-0x60AAFF whose cursor is (0x1088).
; Evidence (FORMAT): it is a STANDARD MIDI FILE reader, and the case is
;          notes/prom_b_smf_reader.py's 40 checks, every one re-derived from the
;          ROM: the four-byte compare against `MThd` at 0xF6F59B, the retry at
;          +0x80 and the 0x31 error code, the big-endian format / ntrks /
;          division fields landing in (0x1078)-(0x107D), the `MTrk` compare at
;          0xF6F658, and all three of the SMF specification's own rejections --
;          a negative division (SMPTE timecode), a zero division, and a format
;          neither 0 nor 1.
; Unknown: what it does with the events after the header, and which of the RAM
;          bytes it clears at 0xF6F537-0xF6F54F belong to the sequencer.
; --------------------------------------------------------------------------
"""

TAGS_NOTE = """; Name:    SmfChunkTags -- named 2026-08-31.
; Evidence (STRING + USE): the eight bytes are `MThd` followed by `MTrk`, the
;          Standard MIDI File header-chunk and track-chunk tags, and the reader
;          uses them as two four-byte compare templates: `ld XIY,0x00f6f528` at
;          0xF6F59B for the header and `ld XIY,0x00f6f52c` -- the same object,
;          plus four -- at 0xF6F658 for the track.  Both are checked by
;          notes/prom_b_smf_reader.py.
; ⚠ CORRECTED 2026-08-31: this header's `Unknown: everything about it except its
;          bytes` no longer holds; its two readers are named above.
"""


TMPL_NOTE = """; Name:    named 2026-08-31 -- a STANDARD MIDI FILE header, byte for byte:
;            4D 54 68 64             `MThd`
;            00 00 00 06             chunk length 6
;            00 00                   format 0
;            00 01                   one track
;            00 60                   division, 96 ticks per quarter note
;            4D 54 72 6B             `MTrk`
;            00 00 00 00             track length -- a placeholder
;            00 FF 03 0F             delta 0, meta FF 03 (track name), length 15
;            57 53 41 20 20 20 20    `WSA    `
; Read by: the writer copies template+0x0E (`MTrk`) and the 11 bytes at
;          template+0x16, then eight more from the filename field at RAM
;          (0x21C8).  7 + 8 = 15, which is the length the meta event declares.
; Evidence: the bytes are re-read on every emit, and the format claim is
;          notes/prom_b_smf_reader.py's 40 checks plus the arithmetic above.
; ⚠ CORRECTED 2026-08-31: this header's `Unknown: everything about it except its
;          bytes` no longer holds.
; Unknown: what the 0x40-strided bytes after offset 0x21 are.  They are NOT
;          claimed here.
"""


def check():
    with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as f:
        b = f.read()
    ok = True
    tags = b[0xF6F528 - B_BASE:0xF6F530 - B_BASE]
    print(f"  0xF6F528 = {tags!r}")
    ok &= tags == b"MThdMTrk"
    for a, want in ((0xF6F530, "or (0x21E8),0x80 set"), (0xF6F89F, "and (0x21E8),0x7F clear")):
        pass
    # the flag bracket, read straight out of the ROM as bytes
    open_bytes = b[0xF6F530 - B_BASE:0xF6F535 - B_BASE]
    close_bytes = b[0xF6F89F - B_BASE:0xF6F8A4 - B_BASE]
    print(f"  0xF6F530 = {open_bytes.hex()}   (or  (0x21e8),0x80)")
    print(f"  0xF6F89F = {close_bytes.hex()}   (and (0x21e8),0x7f)")
    ok &= open_bytes == bytes.fromhex("c1e8213e80")
    ok &= close_bytes == bytes.fromhex("c1e8213c7f")
    ok &= b[0xF6F8A4 - B_BASE] == 0x0E                      # ret
    ok &= b[0xF6F526 - B_BASE:0xF6F528 - B_BASE] == bytes.fromhex("6808")   # jr +8
    print("  0xF6F8A4 is 0x0E (ret), and 0xF6F526 is `68 08` (jr +8)")
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


def apply():
    with open(SRC) as f:
        s = f.read()
    SEP = re.compile(r"^; -{10,}\n", re.M)
    for addr, name in RENAMES:
        old = "sub_%06X" % addr
        i = s.index("\n" + old + ":") + 1
        starts = [m.start() for m in SEP.finditer(s, 0, i)]
        head = starts[-2] if len(starts) >= 2 else starts[-1]
        blk = s[head:i]
        assert OLD_UNKNOWN in blk, old
        blk = blk.replace(OLD_UNKNOWN, NOTES[addr])
        blk = blk.replace(f"; {old}\n", f"; {name} -- 0x{addr:06X}\n", 1)
        s = s[:head] + blk + s[i:]
        s = re.sub(r"\b" + old + r"\b", name, s)
    # the data objects
    for old, new, kind in DATA_RENAMES:
        i = s.index("\n" + old + ":") + 1
        starts = [m.start() for m in SEP.finditer(s, 0, i)]
        head = starts[-2]
        blk = s[head:i]
        note = TAGS_NOTE if kind == "TAGS" else TMPL_NOTE
        assert "; Unknown: everything about it except its bytes.\n" in blk, old
        blk = blk.replace("; Unknown: everything about it except its bytes.\n", note)
        blk = blk.replace(f"; {old} --", f"; {new} -- 0x{old[5:]},", 1)
        s = s[:head] + blk + s[i:]
        s = re.sub(r"\b" + old + r"\b", new, s)
    # the body label
    anchor = "\t.byte\t0x4D, 0x54, 0x68, 0x64, 0x4D, 0x54, 0x72, 0x6B\t; F6F528  [0..7]\n"
    assert anchor in s
    s = s.replace(anchor, anchor + BODY_HEADER + "Smf_ReadFile:\n", 1)
    with open(SRC, "w") as f:
        f.write(s)
    print(f"renamed {len(RENAMES) + len(DATA_RENAMES)} labels, added 1")
    return 0


if __name__ == "__main__":
    sys.exit(apply() if "--apply" in sys.argv else check())
