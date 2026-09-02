#!/usr/bin/env python3
"""0xF039ED-0xF03C94 is EIGHT DISPLAY-LIST SELECTOR BLOCKS, and the reader is
converted code outside every one of them.

QUESTION IT ANSWERS
    prom_b's last 481 verbatim bytes include four `.incbin` spans in the
    0xF03Axx display-list family -- 0xF03A26 (7 B), 0xF03ADE (21 B),
    0xF03AF8 (77 B), 0xF03BE6 (5 B), 110 bytes in all.  Each one starts and
    ends MID-RECORD, so a stride read off the bytes themselves would frame
    fake records and the byte gate could not object.  Where are the real
    record boundaries, established from OUTSIDE the spans?

THE ANSWER, IN ONE PARAGRAPH
    The whole 680-byte region 0xF039ED-0xF03C94 is one repeating object:

        <list 1><list 2>...<list N><selector table of N+2 LE32 entries>

    with

        table[0] == table[1] == list 1's first byte      (index 0 is padding)
        table[i] == list i's first byte,      i = 1..N
        table[N+1] == the table's OWN address  (== one past the last list)

    The selector table is what converted code indexes.  Six of the eight
    tables are named by a `ld XIZ,<table>` in code this tree has already
    disassembled, and the loop around it is identical every time:

        F5C3DE  push C                 ; C = 4 (or 2), counted DOWN by djnz
        F5C3E0  xor  B,B
        F5C3E2  sla  0x02,BC           ; BC = index*4
        F5C3E5  ld   XIZ,0x00f03a51    ; <- THE SELECTOR TABLE
        F5C3EA  ld   XIY,(XIZ+BC)      ; start = table[i]
        F5C3EF  add  BC,0x0004
        F5C3F3  ld   XIX,(XIZ+BC)      ; end   = table[i+1]
        F5C3F8  call 0xf417f0          ; -> DisplayList_Run
        F5C3FC  pop  C
        F5C420  djnz C,0xf5c3cf

    `djnz` counts C down from 4 (or 2) to 1, so the reader uses entries
    1..N+1 and never entry 0 -- which is exactly why entry 0 duplicates
    entry 1, and exactly why the C=2 blocks carry FOUR entries and the C=4
    blocks SIX.  That is the record boundary, read off the consumer.

    The readers, all in already-converted code:

        0xF03A09  table  <- 0xF5C407  ld XIZ,0x00f03a09   C=4
        0xF03A51  table  <- 0xF5C3E5  ld XIZ,0x00f03a51   C=4
        0xF03B6F  table  <- 0xF09DD0, 0xF09E35            C=2
        0xF03BA9  table  <- 0xF09DAE                      C=2
        0xF03C05  table  <- 0xF5C46E  ld XIZ,0x00f03c05   C=4
        0xF03C7D  table  <- 0xF5C44C  ld XIZ,0x00f03c7d   C=4

⚠ TWO TABLES HAVE NO READER, AND THIS IS SAID OUT LOUD
    0xF03AB5 and 0xF03B2D are named by NOTHING outside themselves -- a
    search of all four ROM images for their little-endian 32-bit values
    finds only the self-reference inside each table (`--evidence` prints
    it).  Their framing therefore rests on the CHAIN, not on a reader:

      * each begins where the previous, reader-proven table ends
        (0xF03A69 = 0xF03A51 + 6*4;  0xF03ACD = 0xF03AB5 + 6*4);
      * each ends on its own self-referential last entry;
      * 0xF03B2D's block ends at 0xF03B45, which is entry 1 of the
        READER-PROVEN table at 0xF03B6F.

    So they are pinned at both ends by external evidence even though no
    instruction names them.  If that chain is ever broken, these two blocks
    are the ones to re-examine first.

WHAT THIS CLOSES
    All four `.incbin` spans, 110 bytes, plus 359 bytes that were sitting in
    untyped `.byte` runs (`Data_F039ED`, `Data_F03A51`, `Data_F03AF3`,
    `Data_F03B6F`, `Data_F03C05`, `Data_F03C7D`) -- the reachability walk's
    extents, every one of which also cut mid-record.  680 bytes of typed
    source, no instructions: `.long` for pointers, `.short`/`.byte` for
    fields, `.ascii` for the text the interpreter draws.

    Five of the six `Data_*` labels turn out to sit on a REAL object
    boundary after all -- they are the selector tables -- and are kept
    exactly where they were.  Only `Data_F03AF3` is genuinely mid-record
    (it is bytes 3..7 of the op-03 record at 0xF03AF1); its label is
    dropped and its header is preserved verbatim in the emitted text.

VERIFICATION
    --check re-derives the eight blocks from the ROM with no hard-coded
    addresses, asserts the three table invariants above, asserts every list
    frames as interpreter-A records with ZERO DRIFT under each handler's own
    implied-length rule (notes/prom_b_dl_length_audit.py, not merely
    `op < 0x24`), re-assembles its own emitted directives back to bytes and
    requires all 680 to equal the ROM, and asserts that 0xF03AB5/0xF03B2D
    really are unreferenced across all four images.
    `make gate-wsa1` is what actually certifies the image.

THE GATE, AND THE PROOF IT CAN SEE THIS CHANGE
    `make gate-wsa1` is green with this conversion in place.  A green gate that
    was never shown to fail on the edit certifies nothing, so ONE byte in EACH
    of the four spans was perturbed and the gate went red at the first of them
    (2026-09-02, llvm tlcs900_backend 6f456a19f05b):

        .long  0x00F0191A -> 0x01F0191A  at 0xF03A21  (top byte 0xF03A26, +7)
        .long  0x00F0191A -> 0x01F0191A  at 0xF03AD9  (top byte 0xF03ADE, +21)
        .long  0x00F03B2D -> 0x00F03B2E  at 0xF03B41  (inside the +77 span)
        .short 0x16F8     -> 0x17F8      at 0xF03BE5  (byte 0xF03BE6, +5)

            -> DIFFERS wsa1_prom_b.ic13: 4 byte(s), first at 0x3A26

    Run singly on an earlier base each one reddened its own address alone:
    0x3B41 for the +77 span, 0x3BE6 for the +5 span, and 2 bytes first at
    0x3A26 for the +7/+21 pair.  Restored, re-gated green: four images
    byte-identical.

WHAT THIS LANE DID NOT TOUCH
    notes/FINDINGS-prom_b-last-481-bytes.md is at the REPOSITORY root, not
    under wsa1/, and this lane's diff is confined to wsa1/.  Its table still
    lists these four spans as open, and its 2026-09-02 appendix (lane res3xx)
    stops at "375 B".  With this lane's four also closed the residue is
    265 bytes in 7 spans -- 0xF02FFE, 0xF03F81, 0xF04D14, 0xF0540B, 0xF05792,
    0xF05CEC, 0xF13D34.  Correcting that document is the integrator's.
    notes/prom_b_residue_481.py IS under wsa1/ and has been corrected here,
    including for lane res3xx's five, which it had not recorded.

RUN
    python3 notes/gen_prom_b_f039ed_selector_blocks.py --check
    python3 notes/gen_prom_b_f039ed_selector_blocks.py --evidence
    python3 notes/gen_prom_b_f039ed_selector_blocks.py --show
    python3 notes/gen_prom_b_f039ed_selector_blocks.py --splice
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL              # noqa: E402
import prom_b_dl_length_audit as LA            # noqa: E402
from asm_source import write_part              # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
REGION = (0xF039ED, 0xF03C95)          # [start, end)

BEGIN = "; === COVER-R1 0xF039ED-0xF03C95 ==="
END = "; === END COVER-R1 0xF039ED-0xF03C95 ==="

# Readers found in already-converted code (grep the .s for `ld XIZ,<table>`).
# value: (list of reader addresses, the C the loop starts with)
READERS = {
    0xF03A09: ([0xF5C407], 4),
    0xF03A51: ([0xF5C3E5], 4),
    0xF03B6F: ([0xF09DD0, 0xF09E35], 2),
    0xF03BA9: ([0xF09DAE], 2),
    0xF03C05: ([0xF5C46E], 4),
    0xF03C7D: ([0xF5C44C], 4),
}
UNREAD = (0xF03AB5, 0xF03B2D)

# Labels that already existed at these addresses and are KEPT.  Every one of
# them turns out to be a selector table's first byte, except Data_F039ED which
# is the first list of block 0.
LABELS = {
    0xF039ED: "Data_F039ED",
    0xF03A51: "Data_F03A51",
    0xF03B6F: "Data_F03B6F",
    0xF03C05: "Data_F03C05",
    0xF03C7D: "Data_F03C7D",
}

# ---------------------------------------------------------------------------
# Comment blocks that existed in the tree before this conversion.  They are
# reproduced here VERBATIM and re-emitted next to the object they describe, per
# this tree's rule that an overturned claim is corrected in place and never
# deleted.  Only the ⚠ paragraphs appended below them are new.
OLD_COVER_R1 = """\
; 0xF039ED-0xF03C94, coverage round 1: 359 of this span's 680 bytes are
; reachable -- 0 as CODE (an entry point in the routine directory, or a branch
; prom_b's own converted instructions decode) in 0 runs, and 359 as DATA (only
; a `.long` or a 32-bit immediate names it) in 6 runs.  Everything else here
; is NOT reachable and stays `.incbin`.  Regenerate: python3
; notes/gen_prom_b_cover_round1.py --splice
"""

OLD_HDR = {
    0xF039ED: """\
; --------------------------------------------------------------------------
; Data_F039ED -- 57 bytes, EMITTED AS DATA (not promoted to code).
; Reached from: 0x00F039ED appears as a 32-bit word at 0xF03A09 0xF03A0D
;               0xF5C3C5; converted code at 0xF5C3C4 loads it as a 32-bit
;               immediate.  No routine-directory slot and no branch decoded in
;               converted code names it.
; Measured: 46% printable ASCII; a linear decode runs 28 instructions and ends
;           `jp 0xf019`, with 30% of the bytes in spellings llvm-mc will not
;           encode.
; ⚠ The extent is the reachability walk's, not the object's; the rest of
;   this span is unreachable and stays `.incbin`.  Why this is data and
;   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.
; ⚠ OVERTURNED 2026-09-02 (lane res03a).  "57 bytes" and "the rest of this
;   span is unreachable and stays `.incbin`" are both withdrawn.  The extent
;   was the walk's: it ran 4 text records + a 24-byte selector table + the
;   first 5 bytes of the record at 0xF03A21.  What survives unchanged is the
;   verdict DATA, and the "Reached from" line -- 0xF5C3C4 does load
;   0x00F039ED, as the END operand of a display-list call, and 0xF03A09 and
;   0xF03A0D are entries 0 and 1 of this block's own selector table.
; --------------------------------------------------------------------------
""",
    0xF03A51: """\
; --------------------------------------------------------------------------
; Data_F03A51 -- 141 bytes, EMITTED AS DATA (not promoted to code).
; Reached from: 0x00F03A51 appears as a 32-bit word at 0xF03A65 0xF5C3E6;
;               converted code at 0xF5C3E5 loads it as a 32-bit immediate.  No
;               routine-directory slot and no branch decoded in converted code
;               names it.
; Measured: 26% printable ASCII; a linear decode runs 61 instructions and ends
;           `jp 0xf019`, with 59% of the bytes in spellings llvm-mc will not
;           encode.
; ⚠ The extent is the reachability walk's, not the object's; the rest of
;   this span is unreachable and stays `.incbin`.  Why this is data and
;   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.
; ⚠ CORRECTED 2026-09-02 (lane res03a).  "141 bytes" is withdrawn -- the walk
;   ran from this table's first byte straight through two more blocks and
;   stopped mid-record at 0xF03ADD.  The label itself lands EXACTLY right:
;   0xF03A51 is block 1's 24-byte selector table, and 0xF5C3E5 is the
;   `ld XIZ` that indexes it.  0xF03A65 is its own entry 5, the
;   self-referential terminator.
; --------------------------------------------------------------------------
""",
    0xF03B6F: """\
; --------------------------------------------------------------------------
; Data_F03B6F -- 119 bytes, EMITTED AS DATA (not promoted to code).
; Reached from: 0x00F03B6F appears as a 32-bit word at 0xF03B7B 0xF09DD1
;               0xF09E36; converted code at 0xF09DD0 0xF09E35 loads it as a
;               32-bit immediate.  No routine-directory slot and no branch
;               decoded in converted code names it.
; Measured: 28% printable ASCII; a linear decode runs 63 instructions and ends
;           `swi 0`, with 40% of the bytes in spellings llvm-mc will not
;           encode.
; ⚠ The extent is the reachability walk's, not the object's; the rest of
;   this span is unreachable and stays `.incbin`.  Why this is data and
;   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.
; ⚠ CORRECTED 2026-09-02 (lane res03a).  "119 bytes" is withdrawn; the walk
;   ran through block 5 and stopped mid-record at 0xF03BE5.  The label is on
;   a real boundary: block 4's selector table, FOUR entries not six, because
;   both its readers (0xF09DD0, 0xF09E35) start their djnz loop at C=2.
; --------------------------------------------------------------------------
""",
    0xF03C05: """\
; --------------------------------------------------------------------------
; Data_F03C05 -- 13 bytes, EMITTED AS DATA (not promoted to code).
; Reached from: 0x00F03C05 appears as a 32-bit word at 0xF03C19 0xF5C46F;
;               converted code at 0xF5C46E loads it as a 32-bit immediate.  No
;               routine-directory slot and no branch decoded in converted code
;               names it.
; Measured: 23% printable ASCII; a linear decode runs 6 instructions and ends
;           `jp NC,0x00`, with 62% of the bytes in spellings llvm-mc will not
;           encode.
; ⚠ The extent is the reachability walk's, not the object's; the rest of
;   this span is unreachable and stays `.incbin`.  Why this is data and
;   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.
; ⚠ CORRECTED 2026-09-02 (lane res03a).  "13 bytes" is withdrawn: the object
;   is a 24-byte, 6-entry selector table, and the walk stopped 11 bytes into
;   it.  Lane promB6 had already spotted the tail from the far side and
;   emitted 0xF03C12-0xF03C1C as "6-entry pointer array"; its three loose
;   bytes were the top of entry 3.  Both halves are now one table.
; --------------------------------------------------------------------------
""",
    0xF03C7D: """\
; --------------------------------------------------------------------------
; Data_F03C7D -- 24 bytes, EMITTED AS DATA (not promoted to code).
; Reached from: 0x00F03C7D appears as a 32-bit word at 0xF03C91 0xF5C44D;
;               converted code at 0xF5C44C loads it as a 32-bit immediate.  No
;               routine-directory slot and no branch decoded in converted code
;               names it.
; Measured: 42% printable ASCII; a linear decode runs 11 instructions and ends
;           `ld (0x00),0x00`, with 21% of the bytes in spellings llvm-mc will
;           not encode.
; ⚠ The extent is the reachability walk's, not the object's; the rest of
;   this span is unreachable and stays `.incbin`.  Why this is data and
;   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.
; ⚠ CONFIRMED 2026-09-02 (lane res03a).  This one the walk got exactly right:
;   24 bytes IS the object -- block 7's 6-entry selector table, read by
;   0xF5C44C.  Only the "stays `.incbin`" sentence is withdrawn.
; --------------------------------------------------------------------------
""",
}

# The one header whose object does not survive: 0xF03AF3 is bytes 3..7 of the
# op-03 record that starts at 0xF03AF1, so no label can stand there.  Kept
# verbatim, with the correction, rather than deleted.
OLD_HDR_F03AF3 = """\
; --------------------------------------------------------------------------
; ⚠ THE ONE LABEL THIS CONVERSION RETIRES, WITH ITS HEADER KEPT VERBATIM.
;   `Data_F03AF3` named bytes 3..7 of the 12-byte op-03 record that starts at
;   0xF03AF1, so it cannot stand on an object boundary and the label is gone.
;   Its own header already said as much -- "nothing aligned holds this
;   address; the walk fell through into it" -- and that sentence is the most
;   accurate thing anyone wrote about this region before now:
;
; | ; --------------------------------------------------------------------------
; | ; Data_F03AF3 -- 5 bytes, EMITTED AS DATA (not promoted to code).
; | ; Reached from: nothing aligned holds this address; the walk fell through into
; | ;               it.  No routine-directory slot and no branch decoded in
; | ;               converted code names it.
; | ; Measured: 20% printable ASCII; a linear decode runs 3 instructions and ends
; | ;           `jp PE/OV,0x00`, with 0% of the bytes in spellings llvm-mc will
; | ;           not encode.
; | ; ⚠ The extent is the reachability walk's, not the object's; the rest of
; | ;   this span is unreachable and stays `.incbin`.  Why this is data and
; | ;   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.
; | ; --------------------------------------------------------------------------
; --------------------------------------------------------------------------
"""

# Headers the untouched-pool lane wrote for three runs of records inside this
# region.  Their record framing was RIGHT and is unchanged; only the sentence
# about "this span" is overturned, because the span it refers to is gone.
OLD_POOL_HDR = {
    0xF03A2D: (0xF03A50, 3, 36, 7),
    0xF03B45: (0xF03B6E, 4, 42, 77),
    0xF03BEB: (0xF03C04, 3, 26, 5),
    0xF03C1D: (0xF03C7C, 8, 96, 11),
}

# Lane promB6's note on 0xF03C12, kept verbatim.  It saw the LAST 11 bytes of
# block 6's selector table from the far side of the walk's cut and called them
# a "6-entry pointer array" -- which is exactly right about the object and 13
# bytes short of its start.  Emitted at 0xF03C12, where it was written.
OLD_PTRTAB4 = """\
; | ; --- 0xF03C12-0xF03C1C: not converted -- decodes as neither interpreter's records and is not a uniform fill ---
; | ; --- 0xF03C12-0xF03C1C, 11 B, converted by lane promB6 (PTRTAB4).
; | ;     6-entry pointer array
; | ;     Evidence checked by scripts/analysis/prom_b_small_span_convert.py --check
; | \t.byte\t0x3B, 0xF0, 0x00\t; F03C12  top 3 bytes of the entry at F03C11 = 0x00F03BDF
; | \t.long\t0x00F03BF2\t; F03C15  entry 4
; | \t.long\t0x00F03C05\t; F03C19  entry 5
; ⚠ 2026-09-02 (lane res03a): that lane had the object RIGHT -- a 6-entry
;   pointer array -- and could only see its last 11 bytes because the
;   reachability walk had cut the first 13 into `Data_F03C05`.  Its three
;   loose leading bytes really were the top of entry 3.  The two halves are
;   one table again, above; the note is kept because it named the object
;   correctly from a fragment.
"""

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-72s %-14s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# ---------------------------------------------------------------------------
def derive_blocks(b):
    """Re-derive the eight selector blocks from the ROM alone.

    No address in this function is hard-coded except the region's start, which
    is the label the tree already carried.  A block is found by walking
    interpreter-A records from `p` until the 32-bit word under the cursor
    equals `p` itself -- that is the selector table's entry 0 -- and then
    reading entries until one equals the table's own address.
    """
    def u32(p):
        return int.from_bytes(b[p - B_BASE:p - B_BASE + 4], "little")

    blocks, p = [], REGION[0]
    while p < REGION[1]:
        q = p
        while u32(q) != p:
            ln = b[q - B_BASE + 1]
            if ln < 2 or q + ln > REGION[1]:
                raise SystemExit("0x%06X: no selector table found; tree has moved" % p)
            q += ln
        tstart, ents, r = q, [], q
        while True:
            v = u32(r)
            ents.append(v)
            r += 4
            if v == tstart:
                break
            if r > tstart + 0x40:
                raise SystemExit("0x%06X: selector table does not terminate" % tstart)
        blocks.append((p, tstart, r, ents))
        p = r
    return blocks


def strict_records(b, ta, s, e):
    """Interpreter-A records tiling [s,e) with zero drift, each length checked
    against ITS OWN handler's implied-length rule, or None."""
    recs, p = [], s
    while p < e:
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= 0x24 or ln < 2 or p + ln > e:
            return None
        kind, n = LA.IMPLIED_A.get(ta[op], (None, None))
        if kind is None or not ((ln == n) if kind == "fixed" else (ln >= n)):
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


# ---------------------------------------------------------------------------
def region_header(blocks):
    out = [BEGIN + "\n"]
    out.append(OLD_COVER_R1)
    out.append(""";
; ⚠⚠ SUPERSEDED 2026-09-02 BY LANE res03a -- AND THE HEADLINE IS THE OPPOSITE
;    OF THE SENTENCE ABOVE.  "Everything else here is NOT reachable and stays
;    `.incbin`" is withdrawn: 0 of these 680 bytes are `.incbin` now, and none
;    of them is code.
;
; WHAT THIS REGION IS.  Eight instances of one object:
;
;        <list 1><list 2>...<list N><selector table of N+2 LE32 entries>
;
;    table[0] == table[1] == list 1's first byte    (entry 0 is padding)
;    table[i] == list i's first byte                (i = 1..N)
;    table[N+1] == the table's OWN address          (one past the last list)
;
;    A list is an ordinary interpreter-A display list: `(opcode, length)`
;    records run by DisplayList_Run (0xF31A09, thunk 0xF417F0).  The table is
;    what the firmware indexes, in a loop that is identical at every reader:
;
;        push C                    ; C = 4 or 2, counted DOWN by djnz
;        xor  B,B
;        sla  0x02,BC              ; BC = index*4
;        ld   XIZ,<table>
;        ld   XIY,(XIZ+BC)         ; start = table[i]
;        add  BC,0x0004
;        ld   XIX,(XIZ+BC)         ; end   = table[i+1]
;        call 0xf417f0             ; -> DisplayList_Run
;        pop  C
;        djnz C,<top>
;
;    `djnz` runs C down from 4 (or 2) to 1, so entries 1..N+1 are used and
;    entry 0 never is -- which is why entry 0 duplicates entry 1, and why the
;    C=2 blocks carry four entries where the C=4 blocks carry six.
;
; ⚠ WHY THIS MATTERS MORE THAN THE BYTE COUNT.  Four `.incbin` spans here
;   (0xF03A26+7, 0xF03ADE+21, 0xF03AF8+77, 0xF03BE6+5, 110 bytes) each began
;   and ended MID-RECORD, and so did five of the six `Data_*` extents around
;   them.  Any stride read off those bytes would have framed fake records and
;   rebuilt the ROM perfectly, because ANY framing of the right bytes does.
;   The boundaries below are not read off the bytes: they come from the
;   `ld XIZ` sites in already-converted code listed per block.
;
;   The four span markers this replaces, kept verbatim -- each said exactly
;   what was true, that the bytes decode as neither interpreter's records,
;   because each span STARTS in the middle of one:
;
; | ; --- 0xF03A26-0xF03A2C: not converted -- decodes as neither interpreter's records and is not a uniform fill ---
; | ; --- 0xF03ADE-0xF03AF2: not converted -- decodes as neither interpreter's records and is not a uniform fill ---
; | ; --- 0xF03AF8-0xF03B44: not converted -- decodes as neither interpreter's records and is not a uniform fill ---
; | ; --- 0xF03BE6-0xF03BEA: not converted -- decodes as neither interpreter's records and is not a uniform fill ---
;
;   0xF03A26 is bytes 6..12 of the op-03 record at 0xF03A21; 0xF03ADE bytes
;   6..12 of the record at 0xF03AD9 plus the whole record at 0xF03AE5 plus the
;   header of the one at 0xF03AF1; 0xF03AF8 the tail of that record, two more
;   lists and block 3's whole selector table; 0xF03BE6 bytes 8..12 of the
;   op-03 record at 0xF03BDF.
;
; ⚠ TWO OF THE EIGHT TABLES HAVE NO READER.  0xF03AB5 and 0xF03B2D are named
;   by nothing outside themselves anywhere in the four ROM images.  Their
;   framing rests on the chain -- each starts where the previous
;   reader-proven table ends, ends on its own self-referential last entry,
;   and 0xF03B2D's block ends exactly where the reader-proven table at
;   0xF03B6F says its own block begins.  Pinned at both ends, but say so.
;
; Regenerate / re-check:
;   python3 notes/gen_prom_b_f039ed_selector_blocks.py --check
;   python3 notes/gen_prom_b_f039ed_selector_blocks.py --evidence
""")
    return out


def build(b, ta):
    blocks = derive_blocks(b)
    out = region_header(blocks)
    for n, (s, tstart, tend, ents) in enumerate(blocks):
        rd, cval = READERS.get(tstart, (None, None))
        if rd:
            ev = ("read by %s (`ld XIZ,0x%08X`, djnz from C=%d)"
                  % (" ".join("0x%06X" % x for x in rd), tstart, cval))
        else:
            ev = ("named by NO INSTRUCTION anywhere in the four images; "
                  "framed by the chain (see the region header)")
        out.append("\n; ------------------------------------------------------------------\n")
        out.append("; SELECTOR BLOCK %d -- 0x%06X-0x%06X, %d bytes: %d display lists\n"
                   "; then a %d-entry selector table at 0x%06X.\n"
                   "; Boundary evidence: the table is %s.\n"
                   "; ------------------------------------------------------------------\n"
                   % (n, s, tend - 1, tend - s, len(ents) - 2, len(ents), tstart, ev))
        starts = ents[1:]
        for i in range(len(starts) - 1):
            ls, le = starts[i], starts[i + 1]
            recs = strict_records(b, ta, ls, le)
            if recs is None:
                raise SystemExit("0x%06X-0x%06X does not frame" % (ls, le))
            if ls in OLD_POOL_HDR:
                pe, pn, pb, pskip = OLD_POOL_HDR[ls]
                out.append(_pool_header(ls, pe, pn, pb, pskip))
            if ls in OLD_HDR:
                out.append("\n" + OLD_HDR[ls])
            out.append("; list %d of block %d -- 0x%06X-0x%06X, %d record%s, %d bytes\n"
                       % (i + 1, n, ls, le - 1, len(recs),
                          "" if len(recs) == 1 else "s", le - ls))
            if ls in LABELS:
                out.append("%s:\n" % LABELS[ls])
            for rec in recs:
                if rec[0] == 0xF03AF1:
                    out.append(OLD_HDR_F03AF3)
                if rec[0] != ls and rec[0] in OLD_POOL_HDR:
                    pe, pn, pb, pskip = OLD_POOL_HDR[rec[0]]
                    out.append(_pool_header(rec[0], pe, pn, pb, pskip))
                out += DL.render(b, [rec], ta, set())
        # the selector table
        if tstart in OLD_HDR:
            out.append("\n" + OLD_HDR[tstart])
        else:
            out.append("\n")
        out.append("; selector table of block %d -- 0x%06X-0x%06X, %d LE32 entries\n"
                   % (n, tstart, tend - 1, len(ents)))
        if tstart in LABELS:
            out.append("%s:\n" % LABELS[tstart])
        for j, v in enumerate(ents):
            if tstart + j * 4 == 0xF03C11:
                out.append(OLD_PTRTAB4)
            if j == 0:
                note = "[0] padding: never indexed (djnz runs C down to 1)"
            elif j == len(ents) - 1:
                note = "[%d] end of list %d == this table's own address" % (j, j - 1)
            elif j == 1:
                note = "[1] start of list 1"
            else:
                note = "[%d] end of list %d / start of list %d" % (j, j - 1, j)
            out.append("\t.long\t0x%08X\t; %06X  %s\n" % (v, tstart + j * 4, note))
    out.append("\n" + END + "\n")
    return "".join(out), blocks


def _pool_header(s, e, nrec, nbytes, skip):
    return (
        "\n; ------------------------------------------------------------------\n"
        "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
        "; NOT reached by any known call shape (reachability.py: prom_b has 0\n"
        "; bytes with start evidence) and not named by any converted record's\n"
        "; own table field either -- found because a plain op/len walk, starting\n"
        "; %d bytes into this span, lands with ZERO DRIFT exactly on the span's\n"
        "; declared end, and every record's length satisfies ITS OWN handler's\n"
        "; implied-length rule (notes/prom_b_dl_length_audit.py), not merely\n"
        "; `op < bound`.  Regenerate: python3 notes/gen_prom_b_untouched_pool_module.py\n"
        "; --splice\n"
        "; ⚠ 2026-09-02 (lane res03a): these records are UNCHANGED -- that lane's\n"
        ";   framing was right.  What is withdrawn is the span it measured\n"
        ";   itself against: the `.incbin` supplying the \"%d bytes into this\n"
        ";   span\" offset is converted, and this run is simply a list of the\n"
        ";   selector block above, named by that block's own table.\n"
        "; ------------------------------------------------------------------\n"
        % (s, e, nrec, nbytes, skip, skip))


# ---------------------------------------------------------------------------
# A miniature assembler over exactly the directive subset this module emits, so
# --check can prove the emitted text encodes the ROM without going near
# llvm-mc.  The byte gate remains the real certification.
DIR_RE = re.compile(r'^\t\.(byte|short|long)\s+(.*?)(?:\t;.*)?$')
ASC_RE = re.compile(r'^\t\.ascii\s+"(.*)"$')


def assemble(text):
    out = bytearray()
    for line in text.split("\n"):
        if not line.startswith("\t"):
            continue
        m = ASC_RE.match(line)
        if m:
            out += m.group(1).encode("ascii").replace(b"\\\\", b"\\").replace(b'\\"', b'"')
            continue
        m = DIR_RE.match(line)
        if not m:
            raise SystemExit("assemble(): unhandled line %r" % line)
        w = {"byte": 1, "short": 2, "long": 4}[m.group(1)]
        for tok in m.group(2).split(","):
            v = int(tok.strip(), 0)
            out += struct.pack("<I", v)[:w] if w < 4 else struct.pack("<I", v)
    return bytes(out)


# ---------------------------------------------------------------------------
def evidence(b, ta):
    blocks = derive_blocks(b)
    print("region 0x%06X-0x%06X, %d bytes, %d selector blocks\n"
          % (REGION[0], REGION[1] - 1, REGION[1] - REGION[0], len(blocks)))
    for n, (s, tstart, tend, ents) in enumerate(blocks):
        rd, cval = READERS.get(tstart, (None, None))
        print("block %d  lists 0x%06X-0x%06X   table 0x%06X-0x%06X  %d entries  %s"
              % (n, s, tstart - 1, tstart, tend - 1, len(ents),
                 ("reader %s C=%d" % (" ".join("0x%06X" % x for x in rd), cval))
                 if rd else "NO READER"))
        print("        entries: %s" % " ".join("%06X" % e for e in ents))
        st = ents[1:]
        for i in range(len(st) - 1):
            recs = strict_records(b, ta, st[i], st[i + 1])
            print("        list %d 0x%06X-0x%06X %3d B  ops %s"
                  % (i + 1, st[i], st[i + 1] - 1, st[i + 1] - st[i],
                     " ".join("%02X/%d" % (op, ln) for _p, op, ln in recs)))
    print("\nthe four .incbin spans this closes, and the record each cut:")
    for s, ln in ((0xF03A26, 7), (0xF03ADE, 21), (0xF03AF8, 77), (0xF03BE6, 5)):
        home = []
        for _bs, tstart, tend, ents in blocks:
            st = ents[1:]
            for i in range(len(st) - 1):
                for p, op, rl in strict_records(b, ta, st[i], st[i + 1]):
                    if p < s + ln and p + rl > s:
                        home.append("rec 0x%06X op%02X len%d" % (p, op, rl))
            if tstart < s + ln and tend > s:
                home.append("table 0x%06X" % tstart)
        print("  0x%06X +%-3d -> %s" % (s, ln, "; ".join(home)))
    print("\nreferences to each table across ALL FOUR images "
          "(self-references excluded):")
    imgs = [("prom_a", "original_ROMs/wsa1_prom_a.ic12", 0xF80000),
            ("prom_b", "original_ROMs/wsa1_prom_b.ic13", 0xF00000),
            ("prom_c", "original_ROMs/wsa1_prom_c.ic28", None),
            ("prom_d", "original_ROMs/wsa1_prom_d.bin", None)]
    for _s, tstart, tend, _e in blocks:
        hits = []
        for tag, path, base in imgs:
            d = open(os.path.join(ROOT, path), "rb").read()
            pat = struct.pack("<I", tstart)
            i = d.find(pat)
            while i >= 0:
                a = (base + i) if base else None
                if not (base == 0xF00000 and tstart <= a < tend):
                    hits.append("%s%s" % (tag, ("@%06X" % a) if a else "+%X" % i))
                i = d.find(pat, i + 1)
        print("  0x%06X  %s" % (tstart, " ".join(hits) if hits else "NONE"))
    return 0


def main():
    _a, b = DL.load()
    ta, _tb = LA.tables(b)

    if "--evidence" in sys.argv:
        return evidence(b, ta)

    text, blocks = build(b, ta)

    if "--check" in sys.argv:
        print("gen_prom_b_f039ed_selector_blocks.py --check")
        check("selector blocks derived from the ROM", len(blocks), 8)
        check("they tile 0xF039ED-0xF03C94 exactly",
              (blocks[0][0], blocks[-1][2]), REGION)
        for n, (s, tstart, tend, ents) in enumerate(blocks):
            check("block %d table[0] == table[1] == first list" % n,
                  (ents[0], ents[1]), (s, s))
            check("block %d table[N+1] == its own address" % n, ents[-1], tstart)
            if tstart in READERS:
                check("block %d entry count == reader's C + 2" % n, len(ents),
                      READERS[tstart][1] + 2)
            else:
                print("  %-72s %-14s %s"
                      % ("block %d table 0x%06X has NO reader -- entry count "
                         "unverified against code" % (n, tstart),
                         len(ents), "NOTED"))
            st = ents[1:]
            for i in range(len(st) - 1):
                check("block %d list %d frames, zero drift, per-handler lengths"
                      % (n, i + 1),
                      strict_records(b, ta, st[i], st[i + 1]) is not None, True)
        # every reader address really carries `ld XIZ,<table>`
        src = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        for t, (addrs, _c) in READERS.items():
            for a in addrs:
                pat = "; %06X  ld XIZ,0x00%06x" % (a, t)
                check("0x%06X reader site %06X present in the source" % (t, a),
                      pat in src, True)
        # the two unread tables are really unread, in all four images
        for t in UNREAD:
            hits = 0
            for path, base in (("original_ROMs/wsa1_prom_a.ic12", 0xF80000),
                               ("original_ROMs/wsa1_prom_b.ic13", 0xF00000),
                               ("original_ROMs/wsa1_prom_c.ic28", None),
                               ("original_ROMs/wsa1_prom_d.bin", None)):
                d = open(os.path.join(ROOT, path), "rb").read()
                pat = struct.pack("<I", t)
                i = d.find(pat)
                while i >= 0:
                    a = (base + i) if base else None
                    if not (base == 0xF00000 and a is not None and t <= a < t + 0x18):
                        hits += 1
                    i = d.find(pat, i + 1)
            check("0x%06X is named by nothing outside itself" % t, hits, 0)
        # the emitted directives encode the ROM, byte for byte
        got = assemble(text)
        want = b[REGION[0] - B_BASE:REGION[1] - B_BASE]
        check("emitted directives assemble to the region's byte count",
              len(got), len(want))
        first = next((i for i in range(min(len(got), len(want)))
                      if got[i] != want[i]), None)
        check("emitted directives equal the ROM",
              "match" if first is None else "differ at 0x%06X" % (REGION[0] + first),
              "match")
        # ⚠ NOT a substring test: the preserved headers below QUOTE the word
        # `.incbin` while overturning it, so "`.incbin` in text" is true and
        # says nothing.  Count real directive lines instead.
        check("no .incbin DIRECTIVE left in the emitted region",
              len(re.findall(r'^\s*\.incbin\b', text, re.M)), 0)
        check("no instructions emitted (data directives only)",
              set(re.findall(r'^\t\.(\w+)', text, re.M)),
              {"byte", "short", "long", "ascii"})
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        sys.stdout.write(text)
        return 0

    if "--splice" in sys.argv:
        path = os.path.join(ROOT, S_FILE)
        cur = open(path, encoding="utf-8").read()
        i, j = cur.find(BEGIN), cur.find(END)
        if i < 0 or j < 0:
            raise SystemExit("COVER-R1 anchors not found -- already spliced?")
        if cur.count(BEGIN) != 1 or cur.count(END) != 1:
            raise SystemExit("COVER-R1 anchors are not unique")
        new = cur[:i] + text + cur[j + len(END) + 1:]
        write_part(path, new, root=ROOT, allow_growth=True)
        print("spliced %d bytes of typed source over 0x%06X-0x%06X into %s"
              % (REGION[1] - REGION[0], REGION[0], REGION[1] - 1, S_FILE))
        return 0

    print(__doc__.split("RUN\n")[-1])
    return 1


if __name__ == "__main__":
    sys.exit(main())
