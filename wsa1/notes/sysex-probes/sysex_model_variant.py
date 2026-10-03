#!/usr/bin/env python3
"""What the model-variant strap changes about the SysEx implementation.

QUESTION THIS ANSWERS
    One firmware serves two boxes.  A byte of direct-page RAM, (0x0000C4), is
    written once at RESET from a port pin and read 111 times afterwards.  Two
    SysEx consequences were already known -- the SEQUENCER bulk-dump category
    and the `25` tempo message are both withheld on one variant, through a
    six-entry feature table.  This script establishes:

      * the WHOLE feature table: all six entries, EVERY reader of it, and the
        literal index every call site passes -- so "what are the other four
        entries" gets a measured answer rather than a guess;
      * every OTHER place the SysEx engine reads the strap;
      * ... which turns out to be ONE routine, and it rewrites the outgoing
        model identifier and re-checksums the message.  That resolves the
        open contradiction left by sysex_wire_capture_check.py: a real dump
        carries `04 01 11` and no `04 01 11` literal exists in any image,
        because the second byte is patched in at transmit time.
      * the three menu/display consequences, so a manual can say what a user
        sees as well as what goes on the wire.

WHAT IT ESTABLISHES, AND HOW

  1. THE STRAP.  prom_a 0xF82882 `Variant_SetFromPB0` is the only write to
     (0x00C4) in 1 MiB of CPU-1 ROM (asserted by an exhaustive scan for the
     `F0 C4 41` store idiom).  It reads PORT B bit 0: HIGH -> 1, LOW -> 2.
     ⚠ WHICH BOX IS WHICH is not decoded here and not decodable from these
     images: no string in any of the four ROMs names either model.  The
     tree's assignment (2 = SX-WSA1R) rests on the SX-WSA1R service manual,
     see notes/WSA1-EMULATION-DISASM-GAPS.md.  This script therefore prints
     "variant 1" / "variant 2" and never a model name.

  2. THE FEATURE TABLE IS SIX ENTRIES AND HAS EXACTLY ONE READER.
     `SysEx_FeatureWordForVariant` (0xFB5FF5) bounds its argument with `cp (XIZ+0x08),0x06 /
     jr NC` -> 0xFFFF, picks prom_b 0xF4FE6A when (0x00C4)==1 and 0xF4FE76
     otherwise, and indexes it with stride 2.  Both table addresses appear in
     exactly two instructions in 1 MiB (exhaustive scan), so nothing else
     reads them.  `SysEx_FeatureWordForVariant` itself has exactly six callers -- an
     exhaustive scan for BOTH `call imm24` and PC-relative `calr` -- and this
     script reads the `pushw imm16` immediately before each one.  All six
     pass 3 or 5.  ⇒ entries 0, 1, 2 and 4 are read by NOTHING.  They are
     0x0000 in both tables, i.e. "permitted", and no code ever asks.

  3. THE OTHER STRAP READER IN THE SYSEX ENGINE.  An exhaustive scan of
     0xFB2000-0xFB8200 for the `C0 C4 3F` compare idiom finds exactly two:
     the feature-table selector above, and `SysExTx_PatchModelByteVariant2` (0xFB5F65).
     SysExTx_PatchModelByteVariant2 runs only when the strap is 2 and, for message families
     0x21, 0x22, 0x2C and 0x2D only:
       * overwrites message byte 4 -- the middle byte of the three-byte model
         identifier that follows the family byte -- with 0x01;
       * for 0x2C and 0x2D, which carry a checksum, recomputes it over bytes
         1..len-3 and stores it at len-2, by the same arithmetic and over the
         same window as the build-time checksum routine SysExTx_AppendChecksumF7.
     Its two callers are found by an exhaustive relative-branch scan, and
     they are the only two routines in the SysEx engine that reach the
     MIDI-out block write -- so every outgoing SysEx message passes through
     the patch.

  4. THE RECEIVE SIDE IS MODEL-BLIND.  The grammar trie accepts model byte
     0x00 and 0x01 for every family that carries one, and each pair maps to
     the SAME command number, so nothing downstream can tell them apart.

  5. WHAT THE USER SEES.  Three display lists and one soft key are swapped
     on the strap, and the script proves the dropped tails byte for byte:
     the SYSEX BULK DUMP menu loses its ` SEQUENCER` row, the send/receive
     progress screen loses its ` SEQUENCER     :` line, the soft key that
     selects menu row 4 returns immediately, and the MIDI menu index loses
     its `REALTIME MESSAGE` caption.

RUN
    python3 wsa1/notes/sysex-probes/sysex_model_variant.py
    python3 wsa1/notes/sysex-probes/sysex_model_variant.py --sites

PASS
    Every assert is silent and the script prints OK.  Headline results:
    6 feature entries / 1 reader / 6 call sites / indices {3,5} only;
    4 patched families; model byte 0x00 -> 0x01; checksum window +0x0F..-2.
"""
import argparse
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.normpath(os.path.join(HERE, "..", "..", "original_ROMs"))

PROM_A_BASE = 0xF80000
PROM_B_BASE = 0xF00000

A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
assert len(A) == 0x80000 and len(B) == 0x80000


def a(addr, n=1):
    return A[addr - PROM_A_BASE:addr - PROM_A_BASE + n]


def b(addr, n=1):
    return B[addr - PROM_B_BASE:addr - PROM_B_BASE + n]


def w16(addr):
    return int.from_bytes(b(addr, 2), "little")


def scan(img, base, pat):
    out, i = [], 0
    while True:
        i = img.find(pat, i)
        if i < 0:
            return out
        out.append(base + i)
        i += 1


# Load bases asserted by content, never assumed.
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base wrong"
assert a(0xF99AE3, 5) == bytes([0, 3, 5, 4, 2]), "prom_a base wrong"


# ====================================================================== 1
# THE STRAP.  One producer in 1 MiB, and it is a port-pin read.
STRAP = 0x00C4
VARIANT_SET = 0xF82882
assert a(VARIANT_SET, 13) == bytes([
    0x21, 0x01,              # ld A,0x01
    0xF0, 0x1F, 0xC8,        # bit 0,(0x1F)      PB, per include/tmp95c061_sfr.inc
    0x6E, 0x02,              # jr NZ,+2
    0x21, 0x02,              # ld A,0x02
    0xF0, 0xC4, 0x41,        # ld (0xC4),A
    0x0E]), "Variant_SetFromPB0 moved"
# the ONLY store to (0xC4) anywhere in either CPU-1 image
assert scan(A, PROM_A_BASE, bytes([0xF0, 0xC4, 0x41])) == [VARIANT_SET + 9]
assert scan(B, PROM_B_BASE, bytes([0xF0, 0xC4, 0x41])) == []

CP_STRAP = bytes([0xC0, 0xC4, 0x3F])          # cp (0xC4),#imm8
STRAP_SITES_A = scan(A, PROM_A_BASE, CP_STRAP)
STRAP_SITES_B = scan(B, PROM_B_BASE, CP_STRAP)
assert len(STRAP_SITES_A) == 109, len(STRAP_SITES_A)
assert STRAP_SITES_B == [0xF440C4, 0xF44582], STRAP_SITES_B
assert {a(s + 3, 1)[0] for s in STRAP_SITES_A} <= {1, 2}, "a third strap value"


# ====================================================================== 2
# THE FEATURE TABLE.  Six entries, one reader, six call sites.
GATE = 0xFB5FF5
TBL_V1 = 0xF4FE6A            # consulted when the strap reads 1
TBL_V2 = 0xF4FE76            # consulted otherwise
NENTRIES = 6
DENIED = 0xFFFF

assert a(GATE, 4) == bytes([0xEE, 0x0C, 0x00, 0x00]), "link"
assert a(0xFB5FFA, 6) == bytes([0x8E, 0x08, 0x3F, NENTRIES,   # cp (XIZ+8),6
                                0x6F, 0x1F]), "bound"         # jr NC,fail
assert a(0xFB6000, 4) == bytes([0xC0, 0xC4, 0x3F, 0x01]), "cp (0xC4),0x01"
assert a(0xFB6004, 2) == bytes([0x6E, 0x07])                  # jr NZ -> table 2
assert a(0xFB6006, 5) == bytes([0xF2, 0x6A, 0xFE, 0xF4, 0x34])  # lda XIX,0xF4FE6A
assert a(0xFB600D, 5) == bytes([0xF2, 0x76, 0xFE, 0xF4, 0x34])  # lda XIX,0xF4FE76
assert a(0xFB6012, 2) == bytes([0x23, 0x02]), "stride 2"      # ld C,0x02
assert a(0xFB601F, 3) == bytes([0x30, 0xFF, 0xFF]), "out-of-range = denied"

V1 = [w16(TBL_V1 + 2 * i) for i in range(NENTRIES)]
V2 = [w16(TBL_V2 + 2 * i) for i in range(NENTRIES)]
assert V1 == [0] * NENTRIES, V1
assert V2 == [0, 0, 0, DENIED, 0, DENIED], V2
# the two tables are contiguous -- 12 words, 0xF4FE6A..0xF4FE81 -- and the
# word before them is the `00 F7` checksum/EOX pair SysExTx_AppendChecksumF7 appends, so a
# reader that walked past the end of table 1 would land in table 2.
assert b(0xF4FE68, 2) == bytes([0x00, 0xF7]), "the 00 F7 word"
assert TBL_V1 + 2 * NENTRIES == TBL_V2

# EVERY reader of either table: the two `lda` above and nothing else.
for t in (TBL_V1, TBL_V2):
    imm = bytes([0xF2]) + (t & 0xFFFFFF).to_bytes(3, "little")
    assert len(scan(A, PROM_A_BASE, imm)) == 1, "extra reader of 0x%06X" % t
    assert scan(B, PROM_B_BASE, imm) == [], "prom_b reads 0x%06X" % t
    ptr = t.to_bytes(3, "little")
    assert len(scan(A, PROM_A_BASE, ptr)) == 1, "0x%06X also appears as data" % t

# EVERY caller: absolute `call imm24` (1D lo mi hi), PC-relative `calr`
# (1E disp16) and every relative jump, scanned exhaustively over the raw
# image.  A raw scan finds matches at non-instruction offsets too, so each
# candidate is filtered through the instruction boundaries of this tree's own
# byte-exact transcription prom_a/wsa1_prom_a.s (re-asserted on every emit).
LISTING = os.path.normpath(os.path.join(HERE, "..", "..", "prom_a",
                                        "wsa1_prom_a.s"))
BOUNDARY = set()
for line in open(LISTING, encoding="utf-8", errors="replace"):
    m = re.search(r"; (F[0-9A-F]{5})  [0-9a-f]{2}", line)
    if m:
        BOUNDARY.add(int(m.group(1), 16))
assert len(BOUNDARY) > 100000, len(BOUNDARY)
assert VARIANT_SET in BOUNDARY and GATE in BOUNDARY


def refs_to(target):
    """Every instruction anywhere in prom_a that transfers control to `target`."""
    out = set(scan(A, PROM_A_BASE,
                   bytes([0x1D]) + target.to_bytes(3, "little")))
    for i in range(len(A) - 3):
        op, ad = A[i], PROM_A_BASE + i
        if op == 0x1E or 0x70 <= op <= 0x7F:
            d = int.from_bytes(A[i + 1:i + 3], "little", signed=True)
            if ad + 3 + d == target:
                out.add(ad)
        elif 0x60 <= op <= 0x6F:
            d = int.from_bytes(A[i + 1:i + 2], "little", signed=True)
            if ad + 2 + d == target:
                out.add(ad)
    return sorted(x for x in out if x in BOUNDARY)


GATE_CALLS = refs_to(GATE)
assert len(GATE_CALLS) == 6, GATE_CALLS

# the index is the `pushw imm16` (0B lo hi) immediately before each call
GATE_INDEX = {}
for c in GATE_CALLS:
    push = a(c - 3, 3)
    assert push[0] == 0x0B, "no pushw before the call at 0x%06X" % c
    GATE_INDEX[c] = int.from_bytes(push[1:3], "little")
assert sorted(GATE_INDEX.values()) == [3, 3, 3, 3, 5, 5], GATE_INDEX
USED = sorted(set(GATE_INDEX.values()))
UNREAD = [i for i in range(NENTRIES) if i not in USED]
assert UNREAD == [0, 1, 2, 4], UNREAD
# every entry no one reads is 0x0000 in BOTH tables -- "available", unasked
for i in UNREAD:
    assert V1[i] == 0 and V2[i] == 0, i

# what each consulted index is, named by what the caller does with it
#   3: the SEQUENCER category -- one transmit gate, three receive gates
#   5: the `25` tempo message -- transmitter and receiver
SEQ_TX = 0xFB258A            # inside SysExDump_SendSequencer, the SEQUENCER send routine
SEQ_RX = (0xFB2E36, 0xFB2E7F, 0xFB2EC8)     # parts 1, 2, 3 data handlers
TEMPO_TX = 0xFB3371          # inside sub_FB3355
TEMPO_RX = 0xFB3403          # inside the 0x25 handler
assert set(GATE_CALLS) == {SEQ_TX, TEMPO_TX, TEMPO_RX} | set(SEQ_RX)
assert all(GATE_INDEX[s] == 3 for s in (SEQ_TX,) + SEQ_RX)
assert all(GATE_INDEX[s] == 5 for s in (TEMPO_TX, TEMPO_RX))
# on the denied arm the SEQUENCER sender returns having emitted nothing --
# the four part emitters are all inside the guarded block
assert a(0xFB258F, 4) == bytes([0xD8, 0xCF, 0xFF, 0xFF])      # cp WA,0xFFFF
assert a(0xFB2593, 2) == bytes([0x66, 0x0C])                  # jr Z,+12 = ret
# ... and the three receive handlers skip only the block store, so the
# message is still parsed and acknowledged.  The SYSTEM,PART & MIDI handler
# calls the same store unconditionally.
STORE = bytes([0x1D, 0xB5, 0x72, 0xFB])                       # call sub_FB72B5
assert a(0xFB2E44, 4) == STORE and a(0xFB2CC0, 4) == STORE

# the SEQUENCER category is reachable three ways, and all three land on the
# gate: the menu's own row, the TOTAL KEYBOARD chain, and the dump request.
assert a(0xF99AE3, 5) == bytes([0, 3, 5, 4, 2])               # row -> job
assert a(0xFB22F1, 3) == bytes([0x1E, 0x93, 0x02])            # job 2 -> FB2587
assert a(0xFB23EB, 3) == bytes([0x1E, 0x99, 0x01])            # TOTAL KBD -> "


# ====================================================================== 3
# THE OTHER STRAP READER IN THE SYSEX ENGINE -- the transmit-time model patch.
ENGINE = (0xFB2000, 0xFB8200)
in_engine = [s for s in STRAP_SITES_A if ENGINE[0] <= s < ENGINE[1]]
assert in_engine == [0xFB5F6D, 0xFB6000], in_engine

PATCH = 0xFB5F65
assert a(0xFB5F6D, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02]), "cp (0xC4),0x02"
assert a(0xFB5F71, 3) == bytes([0x7E, 0x7C, 0x00]), "jrl NZ -> do nothing"
# the message buffer starts at descriptor+0x0E, so +0x10 is message byte 2 =
# the family byte, and +0x0E+4 is message byte 4.
assert a(0xFB5F77, 6) == bytes([0xE9, 0xC8, 0x0E, 0, 0, 0]), "add XBC,0x0E"
assert a(0xFB5F83, 3) == bytes([0x88, 0x10, 0x23]), "ld C,(XWA+0x10)"
FAMILIES_SUM = (0x2C, 0x2D)          # patched AND re-checksummed
FAMILIES_FLAT = (0x21, 0x22)         # patched, no checksum in the message
assert a(0xFB5F88, 4) == bytes([0xD9, 0xCF, 0x21, 0x00])
assert a(0xFB5F8F, 4) == bytes([0xD9, 0xCF, 0x22, 0x00])
assert a(0xFB5F95, 4) == bytes([0xD9, 0xCF, 0x2C, 0x00])
assert a(0xFB5F9B, 4) == bytes([0xD9, 0xCF, 0x2D, 0x00])
assert a(0xFB5FA1, 2) == bytes([0x68, 0x4D]), "any other family: untouched"
MODEL_BYTE_INDEX = 4
PATCH_VALUE = 0x01
for site in (0xFB5FA6, 0xFB5FEC):    # the 2C/2D arm and the 21/22 arm
    assert a(site, 4) == bytes([0xB9, MODEL_BYTE_INDEX, 0x00, PATCH_VALUE]), \
        "ld (XBC+0x04),0x01 at 0x%06X" % site
# the re-checksum: sum bytes +0x0F .. len-3, store (-sum)&0x7F at len-2
assert a(0xFB5FAC, 2) == bytes([0xE9, 0x61]), "cursor = buf+0x0F"
assert a(0xFB5FB4, 3) == bytes([0xA8, 0x0A, 0x25]), "XIY = end cursor"
assert a(0xFB5FB7, 2) == bytes([0xED, 0x6A]), "end - 2"
assert a(0xFB5FD4, 2) == bytes([0xD8, 0xA0]) and a(0xFB5FD6, 2) == bytes([0xD9, 0xA0])
assert a(0xFB5FDA, 3) == bytes([0xCE, 0x30, 0x07]), "res 7,H"
assert a(0xFB5FE3, 2) == bytes([0xE8, 0x6A]) and a(0xFB5FE5, 2) == bytes([0xB0, 0x46])
# ... which is the SAME window and the SAME arithmetic as the build-time
# checksum routine SysExTx_AppendChecksumF7, so a patched message checksums as if it had
# been built with 0x01 from the start.
assert a(0xFB7126, 6) == bytes([0xEC, 0xC8, 0x0F, 0, 0, 0]), "sum from +0x0F"
assert a(0xFB7131, 3) == bytes([0xA8, 0x0A, 0x25]), "to the end cursor"
assert a(0xFB714E, 3) == bytes([0xC9, 0x30, 0x07]), "res 7,A"

# the templates the patch rewrites all ship with 0x00 in that position, and
# no `04 01 11` literal exists in any of the four images -- the reason the
# byte on a real machine's wire could not be traced to a template.
TEMPLATES = {0x21: 0xF4FED5, 0x22: 0xF4FEDC, 0x2C: 0xF4FEF2, 0x2D: 0xF4FEF8}
for fam, t in TEMPLATES.items():
    assert b(t, 6) == bytes([0xF0, 0x50, fam, 0x04, 0x00, 0x11]), hex(t)
for name in ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13",
             "wsa1_prom_c.ic28", "wsa1_prom_d.bin"):
    img = open(os.path.join(ROMS, name), "rb").read()
    for fam in TEMPLATES:
        assert bytes([0x50, fam, 0x04, PATCH_VALUE, 0x11]) not in img, \
            "a `50 %02X 04 01 11` literal exists in %s" % (fam, name)

# EVERY caller of the patch, and every SysEx transmit path.
PATCH_CALLS = refs_to(PATCH)
assert len(PATCH_CALLS) == 2, PATCH_CALLS
SENDERS = (0xFB7165, 0xFB71BB)
assert PATCH_CALLS == [0xFB7174, 0xFB71CA], PATCH_CALLS
for c, s in zip(PATCH_CALLS, SENDERS):
    assert 0 < c - s < 0x20, "patch call is not at the head of 0x%06X" % s
# the MIDI-out block write; inside the SysEx engine only the two senders reach it
MIDI_OUT = scan(A, PROM_A_BASE, bytes([0x1D, 0xF8, 0x1D, 0xF4]))
engine_out = [x for x in MIDI_OUT if ENGINE[0] <= x < ENGINE[1]]
assert engine_out == [0xFB7189, 0xFB71AA, 0xFB71DF, 0xFB720E], engine_out
assert all(0xFB7165 <= x < 0xFB7230 for x in engine_out)
SENDER_CALLS = {s: refs_to(s) for s in SENDERS}
assert len(SENDER_CALLS[0xFB7165]) == 5, SENDER_CALLS[0xFB7165]
assert len(SENDER_CALLS[0xFB71BB]) == 14, SENDER_CALLS[0xFB71BB]
assert all(ENGINE[0] <= x < ENGINE[1]
           for v in SENDER_CALLS.values() for x in v), "a sender is used outside"


# ====================================================================== 4
# THE RECEIVE SIDE IS MODEL-BLIND.
ROOT = 0xF5115B
NULLREC = 0xF4FF61


def records(addr, limit=256):
    out = []
    for i in range(limit):
        r = b(addr + 6 * i, 6)
        out.append((r[0], r[1], int.from_bytes(r[2:6], "little")))
        if r[0] == 0xFF:
            break
    return out


def walk(node, prefix, acc):
    for m, c, nx in records(node):
        if m == 0xFF:
            break
        p = prefix + bytes([m])
        if c:
            acc.append((p, c))
        elif nx != NULLREC:
            walk(nx, p, acc)


BY_FAMILY = {}
for m, c, nx in records(ROOT, 15):
    if m == 0xFF:
        assert c == 0x07, "root terminator carries the root depth code"
        break
    acc = []
    if not c and nx != NULLREC:
        walk(nx, b"", acc)
    BY_FAMILY[m] = acc

MODEL_FAMILIES = {}
for fam, acc in BY_FAMILY.items():
    # sequences shaped `04 <model> 11 ...`
    got = {}
    for seq, cmd in acc:
        if len(seq) >= 3 and seq[0] == 0x04 and seq[2] == 0x11:
            got.setdefault(seq[1], {})[bytes(seq[2:])] = cmd
    if got:
        MODEL_FAMILIES[fam] = got
assert sorted(MODEL_FAMILIES) == [0x21, 0x22, 0x2B, 0x2C, 0x2D], sorted(MODEL_FAMILIES)
for fam, got in MODEL_FAMILIES.items():
    assert sorted(got) == [0x00, 0x01], (hex(fam), sorted(got))
    # the two model bytes lead to identical continuations AND identical
    # command numbers, so nothing downstream can tell them apart
    assert got[0x00] == got[0x01], hex(fam)


# ====================================================================== 5
# WHAT THE USER SEES.  Three display-list swaps and one dead soft key.
def imm32(addr):
    op = a(addr, 5)
    assert op[0] in (0x44, 0x45), (hex(addr), op.hex())
    return int.from_bytes(op[1:5], "little")


def lda24(addr):
    op = a(addr, 5)
    assert op[0] == 0xF2, (hex(addr), op.hex())
    return int.from_bytes(op[1:4], "little")


def strings(lo, hi):
    return [t.decode() for t in re.findall(rb"[ -~]{3,}", b(lo, hi - lo))]


# (a) the SYSEX BULK DUMP menu
assert imm32(0xF99A28) == 0xF0D6AF and imm32(0xF99A2D) == 0xF0D79C
assert a(0xF99A32, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02])
assert a(0xF99A36, 2) == bytes([0x6E, 0x05])
assert imm32(0xF99A38) == 0xF0D77F
MENU_TAIL = b(0xF0D77F, 0xF0D79C - 0xF0D77F)
assert b" SEQUENCER" in MENU_TAIL, MENU_TAIL
assert strings(0xF0D6AF, 0xF0D77F)[-1].strip() == "SYSTEM,PART & MIDI"
assert strings(0xF0D77F, 0xF0D79C) == [" SEQUENCER"]

# (b) the soft key that selects menu row 4 -- SEQUENCER, job 2
assert a(0xF99B3D, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02])
assert a(0xF99B41, 2) == bytes([0x66, 0x28]), "jr Z -> ret, key does nothing"
assert a(0xF99B5D, 5) == bytes([0xF1, 0x20, 0x27, 0x00, 0x04]), "row 4"
assert a(0xF99AE3 + 4, 1)[0] == 2, "row 4 runs job 2"

# (c) the transfer-progress screen's per-category lines
assert imm32(0xF99C61) == 0xF0D7E2 and imm32(0xF99C66) == 0xF0D82E
assert a(0xF99C6B, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02])
assert imm32(0xF99C71) == 0xF0D81B
assert strings(0xF0D7E2, 0xF0D81B) == ["SYS,PART&MIDI :", "SOUND         :",
                                       "COMBINATION   :"]
assert strings(0xF0D81B, 0xF0D82E) == [" SEQUENCER     :"]

# (d) the MIDI menu index
assert a(0xF99F31, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02])
assert a(0xF99F35, 2) == bytes([0x66, 0x0E])
V1_MENU = (lda24(0xF99F3D), lda24(0xF99F37))      # start, end
V2_MENU = (lda24(0xF99F4B), lda24(0xF99F45))
assert V1_MENU == (0xF0C81F, 0xF0C917) and V2_MENU == (0xF0C800, 0xF0C8D5)
S1, S2 = strings(*V1_MENU), strings(*V2_MENU)
assert "REALTIME" in S1 and "MESSAGE#" in S1
assert "REALTIME" not in S2 and "MESSAGE#" not in S2
for keep in ("SYSEX", "BULK DUMP", "GENERAL MIDI", "INPUT&0UTPUT", "FILTER#"):
    assert keep in S1 and keep in S2, keep


# ====================================================================== report
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sites", action="store_true",
                    help="print every strap compare site in prom_a")
    args = ap.parse_args()

    print("base check OK")
    print()
    print("strap (0x%04X): written once, at 0x%06X, from PORT B bit 0"
          "  (HIGH -> 1, LOW -> 2)" % (STRAP, VARIANT_SET))
    print("  %d compare sites in prom_a, %d in prom_b; values compared: 1 and 2"
          % (len(STRAP_SITES_A), len(STRAP_SITES_B)))
    print("  which physical box is 1 and which is 2 is NOT in these images")
    print()
    print("feature table -- %d entries, ONE reader (0x%06X)" % (NENTRIES, GATE))
    print("  idx  strap==1  strap!=1  read by")
    for i in range(NENTRIES):
        who = [hex(c) for c, n in GATE_INDEX.items() if n == i]
        note = {3: "SEQUENCER bulk-dump category",
                5: "the `25` tempo message"}.get(i, "-- NOTHING READS THIS ENTRY --")
        print("   %d   0x%04X    0x%04X    %-30s %s"
              % (i, V1[i], V2[i], note, " ".join(who)))
    print("  out-of-range index -> 0x%04X (denied)" % DENIED)
    print()
    print("call sites, with the literal index each one passes:")
    for c in sorted(GATE_INDEX):
        what = {SEQ_TX: "SEQUENCER send (whole category, incl. its end message)",
                SEQ_RX[0]: "SEQUENCER part 1 received -> block store",
                SEQ_RX[1]: "SEQUENCER part 2 received -> block store",
                SEQ_RX[2]: "SEQUENCER part 3 received -> block store",
                TEMPO_TX: "tempo `25` transmit",
                TEMPO_RX: "tempo `25` receive"}[c]
        print("  0x%06X  index %d  %s" % (c, GATE_INDEX[c], what))
    print()
    print("the OTHER strap reader in the SysEx engine: 0x%06X" % PATCH)
    print("  runs only when the strap is 2, on families %s"
          % " ".join("0x%02X" % f for f in FAMILIES_FLAT + FAMILIES_SUM))
    print("  rewrites message byte %d (the model id's middle byte) 0x00 -> 0x%02X"
          % (MODEL_BYTE_INDEX, PATCH_VALUE))
    print("  and for 0x2C/0x2D recomputes the checksum over +0x0F..len-3,")
    print("  storing (-sum) & 0x7F at len-2 -- SysExTx_AppendChecksumF7's own window")
    print("  reached from both message senders: %s"
          % " ".join("0x%06X" % s for s in SENDERS))
    print()
    print("receive side, by family:")
    for fam in sorted(MODEL_FAMILIES):
        got = MODEL_FAMILIES[fam]
        print("  0x%02X  model byte %s accepted, %d continuation(s) each,"
              " identical command numbers"
              % (fam, "/".join("0x%02X" % k for k in sorted(got)),
                 len(got[0x00])))
    print()
    print("what the user sees on the strap-2 machine:")
    print("  SYSEX BULK DUMP menu loses its last row:      %r" % strings(0xF0D77F, 0xF0D79C))
    print("  transfer progress screen loses its last line: %r" % strings(0xF0D81B, 0xF0D82E))
    print("  the soft key for menu row 4 returns at once (0x%06X)" % 0xF99B3D)
    print("  MIDI menu index loses: %r"
          % [s for s in S1 if s not in S2])
    print()
    if args.sites:
        print("every strap compare site in prom_a")
        for s in STRAP_SITES_A:
            print("  0x%06X  cp (0x%04X),0x%02X" % (s, STRAP, a(s + 3, 1)[0]))
        print()
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
