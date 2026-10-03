#!/usr/bin/env python3
"""Resolve the WSA1R's SysEx status codes to the ERROR nn screens they raise.

QUESTION THIS ANSWERS
    Which internal status code produces "ERROR 40!", "ERROR 41!" and
    "ERROR 42!", and where in prom_a is each code raised?

THE CHAIN, AND WHERE EACH LINK IS READ
    (1) The SysEx engine keeps a parse record; its pointer is RAM
        (0x60FCD8) and *field 4* of that record is the status byte.
        prom_a U8Rec16_SetField (0xFB6219) is the field SETTER and U8Rec16_GetField
        (0xFB62D3) the GETTER; both are 16-way jump tables over offsets
        +0..+15 (`cp BC,0x000F / jrl ugt`, 0xFB622C / 0xFB62E2).

    (2) At the end of a session prom_a SysExDump_ShowResult (0xFB7DFE) reads field 4:
              == 0x00 -> SysExDump_ShowCompleted: message 0x23 ("COMPLETED!")
              == 0x21 -> SysExDump_ShowScreenB3: screen 0xB3, NO popup
              else    -> SysExDump_ShowStatusMessage: message := STATUS_MAP[field4]
        STATUS_MAP is prom_b 0xF511C7, named by the single instruction
        `add XWA,0x00f511c7` at prom_a 0xFB7E54.  The message id goes to
        RAM (0x2880) at 0xFB7E5C and a screen request 0xAB is posted.

    (3) prom_a sub_F99098 (0xF99098) paints (0x2880):
              bound `cp C,0x40` at 0xF990A3
              base  = *(0xF993B9 + 4*(0x7FC1))      # (0x7FC1) = language
              start = *(base + 8*code), end = *(base + 8*code + 4)
        and hands (start, end) to display-list interpreter A.  All three
        language slots hold 0x00F99121 in this ROM.

    SELF-CHECK built into the chain: SysExDump_ShowResult special-cases field4 == 0
    to message 0x23, and STATUS_MAP[0] is 0x23 as well.  Two independent
    statements of the same fact -- that is what pins the table's index
    origin (no off-by-one).

RUN
    python3 wsa1/notes/sysex-probes/sysex_error_codes.py            # the table
    python3 wsa1/notes/sysex-probes/sysex_error_codes.py --sites    # raise sites

PASS
    Every assert below is silent and the last line prints OK.  The
    headline assertions are: status 0x08/0x09/0x0A -> "ERROR 40!",
    0x20 -> "ERROR 42!", 0x07 -> "ERROR 41!", 0x00 -> "COMPLETED!".
"""
import os, re, sys

HERE   = os.path.dirname(os.path.abspath(__file__))
ROMDIR = os.path.join(HERE, "..", "..", "original_ROMs")
PA_BASE, PB_BASE = 0xF80000, 0xF00000
pa = open(os.path.join(ROMDIR, "wsa1_prom_a.ic12"), "rb").read()
pb = open(os.path.join(ROMDIR, "wsa1_prom_b.ic13"), "rb").read()

def a(addr, n): return pa[addr - PA_BASE: addr - PA_BASE + n]
def b(addr, n): return pb[addr - PB_BASE: addr - PB_BASE + n]
def le32(buf):  return int.from_bytes(buf, "little")

# --- load bases, asserted rather than assumed ---------------------------
# prom_b: the outgoing SysEx template block opens with F0 50 23 7E F7.
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
# prom_a: 0xFB7E54 must be `add XWA,0x00f511c7` (e8 c8 c7 11 f5 00).
assert a(0xFB7E54, 6) == bytes([0xE8, 0xC8, 0xC7, 0x11, 0xF5, 0x00]), "prom_a base"
# and 0xFB7E5C must be `ld (0x2880),C` -- the message-id store.
assert a(0xFB7E5C, 4) == bytes([0xF1, 0x80, 0x28, 0x43]), "message-id store"
# the language base table: three slots, all 0x00F99121.
assert [le32(a(0xF993B9 + 4*i, 4)) for i in range(3)] == [0x00F99121]*3, "lang table"

MSGTAB = 0x00F99121          # PtrTable_F99121, (start,end) pairs, stride 8
MSGMAX = 0x40                # `cp C,0x40 / jrl nc` at prom_a 0xF990A3

def dl_text(start, end):
    """Walk display-list records (op, len, 2 operand bytes, ascii)."""
    out, p = [], start
    while p < end:
        ln = b(p + 1, 1)[0]
        if ln < 4 or p + ln > end: break
        out.append(b(p + 4, ln - 4).decode("latin1"))
        p += ln
    return " | ".join(out)

def message(code):
    off = MSGTAB + 8 * code
    s, e = le32(a(off, 4)), le32(a(off + 4, 4))
    return s, e, dl_text(s, e)

# --- STATUS_MAP.  The .s declares 22 bytes because the ASCII heuristic
# stops at the first non-printable one; the READER has no bound at all, so
# the table is read to the last status the firmware can raise (0x21).
STATUS_MAP = b(0xF511C7, 0x22)

assert STATUS_MAP[0x00] == 0x23, "table origin (self-check against SysExDump_ShowCompleted)"

# --- every site that writes field 4, from the ROM ----------------------
# `pushw imm16 / pushw 0x04 / ld Xrr,(0x60FCxx) / push Xrr / call|calr setter`
SETTER = 0xFB6219
def _call_target(off):
    """Decode a call/calr at prom_a file offset `off`; None if neither."""
    op = pa[off]
    if op == 0x1D:                                   # call imm24
        return int.from_bytes(pa[off + 1:off + 4], "little")
    if op == 0x1E:                                   # calr rel16
        rel = int.from_bytes(pa[off + 1:off + 3], "little", signed=True)
        return PA_BASE + off + 3 + rel
    return None

def setter_sites():
    """`pushw imm16 / pushw 0x04 / ld Xrr,(0x60FCxx) / push Xrr / call SETTER`."""
    hits = []
    pat = rb"\x0b(.)\x00\x0b\x04\x00\xe2(.)\xfc\x60[\x20\x21][\x38\x39]"
    for m in re.finditer(pat, pa):
        off = m.start()
        if _call_target(off + 12) == SETTER:
            hits.append((PA_BASE + off, m.group(1)[0], 0x60FC00 | m.group(2)[0]))
    return hits

# Four sites push the status and then BRANCH to a shared
# `pushw 0x04 / ld Xrr,(0x60FCD8) / push / call SETTER` tail, so the byte
# pattern above cannot see them.  Each is asserted from the ROM below.
SPLIT_SITES = {0xFB60E9: 0x01, 0xFB60F7: 0x02,      # -> tail 0xFB6145
               0xFB6E64: 0x14,                       # -> tail 0xFB6E6C
               }

# the ten trie depths raise 0x07..0x10 through one shared tail at 0xFB6ADA
DEPTH_SITES = {0x07: 0xFB640C, 0x08: 0xFB64BF, 0x09: 0xFB6582, 0x0A: 0xFB6645,
               0x0B: 0xFB6708, 0x0C: 0xFB67CB, 0x0D: 0xFB688E, 0x0E: 0xFB6951,
               0x0F: 0xFB6A14, 0x10: 0xFB6AD7}
for code, site in DEPTH_SITES.items():
    assert a(site, 3) == bytes([0x0B, code, 0x00]), f"depth raise 0x{code:02X}"
# 0xFB6ADA is the shared `pushw 0x04` that makes all ten target field 4.
assert a(0xFB6ADA, 3) == bytes([0x0B, 0x04, 0x00]), "shared field-4 push"

for site, code in SPLIT_SITES.items():
    assert a(site, 3) == bytes([0x0B, code, 0x00]), f"split raise 0x{code:02X}"
for tail in (0xFB6145, 0xFB6E6C, 0xFB6CE8):
    assert a(tail, 3) == bytes([0x0B, 0x04, 0x00]), f"shared tail 0x{tail:06X}"

sites = setter_sites()
by_code = {}
for addr, val, rec in sites:
    by_code.setdefault(val, []).append((addr, rec))
for code, site in DEPTH_SITES.items():
    by_code.setdefault(code, []).append((site, 0x60FCD8))
for site, code in SPLIT_SITES.items():
    by_code.setdefault(code, []).append((site, 0x60FCD8))

# --- report -------------------------------------------------------------
print(f"STATUS_MAP = prom_b 0xF511C7, {len(STATUS_MAP)} bytes, read by prom_a 0xFB7E54\n")
print(" status | msg  | screen text                                   | raised at")
print("--------+------+-----------------------------------------------+----------------")
for st in range(len(STATUS_MAP)):
    msg = STATUS_MAP[st]
    _, _, txt = message(msg) if msg < MSGMAX else (0, 0, "<out of range>")
    where = ", ".join(f"0x{x:06X}" for x, _ in by_code.get(st, [])) or "-- never raised --"
    note = "  [special-cased by SysExDump_ShowResult]" if st in (0x00, 0x21) else ""
    print(f"  0x{st:02X}   | 0x{msg:02X} | {txt.split(' | ')[0][:45]:45s} | {where}{note}")

if "--sites" in sys.argv:
    print("\nAll field-4 setter call sites found in prom_a:")
    for addr, val, rec in sorted(sites):
        print(f"  0x{addr:06X}  field4 := 0x{val:02X}  on record *(0x{rec:06X})")

# --- corroboration, from two sources that do not share code ------------
# (a) the ERROR 42 raise writes the SAME status to BOTH records: 0xFB6FFB
#     targets *(0x60FCE0) and its companion 0xFB700A targets *(0x60FCD8)
#     (`ld XBC,(XIX)` with XIX = 0x60FCD8, so the byte pattern above misses
#     it).  Only the second one is what SysExDump_ShowResult reads.
assert a(0xFB700A, 9) == bytes([0x0B, 0x20, 0x00, 0x0B, 0x04, 0x00,
                                0xA4, 0x21, 0x39]), "ERROR 42 companion raise"
assert _call_target(0xFB7013 - PA_BASE) == SETTER, "ERROR 42 companion setter"
# (b) each node of the prom_b grammar trie ends in a 0xFF record whose
#     SECOND byte repeats the depth-specific error code the parser pushes.
#     Two independent statements of the depth -> code map.
for sentinel, code in ((0xF511AF, 0x07),   # root, depth 1
                       (0xF50225, 0x08),   # node "2D",       depth 2
                       (0xF50219, 0x09),   # node "2D 04",    depth 3
                       (0xF50207, 0x0A)):  # node "2D 04 00", depth 4
    assert b(sentinel, 2) == bytes([0xFF, code]), f"sentinel 0x{sentinel:06X}"

# --- WHAT the single reachable ERROR 42 actually tests -------------------
# The raise at 0xFB6FFB is the target of one conditional branch, and the
# instruction pair in front of that branch says what the condition IS:
#     FB6FD1  call 0xF4123C        -> Link_WaitBlockDone
#     FB6FD5  cp WA,0xFFFF         -> 0xFFFF is that routine's timeout return
#     FB6FD9  jr z,.LFB6FFB        -> taken ONLY on the timeout
# So ERROR 42 reports an INTERNAL block-transfer deadline, not a MIDI-side
# condition.  The published manual calls it "the data has not been received
# correctly", which this branch cannot be testing: nothing here reads the
# MIDI input.
assert a(0xFB6FD1, 12) == bytes([0x1D, 0x3C, 0x12, 0xF4,      # call 0xF4123C
                                 0xD8, 0xCF, 0xFF, 0xFF,      # cp WA,0xFFFF
                                 0x66, 0x20,                  # jr z,+0x20
                                 0x1E, 0x62]), "the ERROR 42 branch moved"
assert 0xFB6FD9 + 2 + 0x20 == 0xFB6FFB, "the branch no longer lands on the raise"

# The MIDI-side failures raise ERROR 41, not 42, which is the other half of
# the correction.  Status 0x05 at 0xFB77A1 is guarded by a 1000-tick deadline
# on a reply, and status 0x04 at 0xFB776D by the UART error bits 0x2C of (0x9E).
assert a(0xFB7794, 3) == bytes([0x33, 0xE8, 0x03]), "the reply deadline moved"
assert a(0xFB7761, 6) == bytes([0xC0, 0x9E, 0x23, 0xCB, 0xCC, 0x2C]), \
    "the UART error-bit test moved"

# --- headline assertions -----------------------------------------------
def screen(st): return message(STATUS_MAP[st])[2].split(" | ")[0]
assert screen(0x00) == "COMPLETED!",  screen(0x00)
assert screen(0x07) == "ERROR 41!",   screen(0x07)
for st in (0x08, 0x09, 0x0A):
    assert screen(st) == "ERROR 40!",  (st, screen(st))
assert screen(0x14) == "ERROR 41!",   screen(0x14)   # checksum mismatch
assert screen(0x16) == "ERROR 21!",   screen(0x16)   # "Memory full", NOT a 4x
assert screen(0x20) == "ERROR 42!",   screen(0x20)
assert screen(0x04) == "ERROR 41!",   screen(0x04)   # UART line error
assert screen(0x05) == "ERROR 41!",   screen(0x05)   # reply deadline
# 0x20 is the only status mapping to ERROR 42 that the ROM ever raises
e42 = [st for st in range(len(STATUS_MAP)) if screen(st) == "ERROR 42!"]
assert e42 == [0x18, 0x1F, 0x20], e42
assert set(by_code) & set(e42) == {0x20}, sorted(set(by_code) & set(e42))
print("\nOK")
