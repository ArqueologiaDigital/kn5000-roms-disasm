#!/usr/bin/env python3
"""What does the instrument DO when `F0 50 21 ...` or `F0 50 22 ...` arrives,
and when does that cause a TRANSMIT?

QUESTION THIS ANSWERS
    sec-models.tex claimed the two messages are an IDENTITY ENQUIRY that "is
    answered with the model's own value, whichever value the enquiry itself
    carried", and offered them as a way to tell an SX-WSA1 from an SX-WSA1R
    over MIDI.  A measurement against the emulated instrument found that an
    idle machine answers neither, while a `2B` parameter request IS answered.
    This script settles it from the program:

      1. where 0x21 and 0x22 dispatch to;
      2. whether either can cause a transmit, and what gates it;
      3. whether any code builds a reply carrying a model value taken FROM
         the received message;
      4. whether the pair is the opening of a bulk-dump session rather than
         an enquiry the instrument answers at rest;
      5. the COVERAGE of the search, so the negative in (3) is a real one.

    Its POSITIVE CONTROL is the `2B` parameter request in the same dispatch
    table: the same wire, the same parser, the same dispatcher -- and it
    reaches a handler with no screen gate at all.  A path that answers
    proves the path that does not answer was capable of being seen.

WHERE THE SIGNAL IS  (ROM addresses, prom_a @0xF80000, prom_b @0xF00000)
  * grammar trie root prom_b 0xF5115B; the 0x21 arm is the node at
    0xF4FF85 and the 0x22 arm the node at 0xF4FFAF.  See
    sysex_command_map.py, which established the trie's shape and the three
    handler tables -- this script reuses both and does not re-derive them.
  * handler tables prom_b 0xF4F800 (interrupt ring), 0xF4F888 (foreground
    ring), 0xF4F916 (inside the bulk-transfer session loop).
  * the session loop prom_a 0xFB2820; the per-message step sub_FB2877;
    the acknowledger sub_FB28BE.
  * the RECEIVE handlers: 0xFB28FF (cmd 0x07 = wire 0x21) and 0xFB291D
    (cmd 0x08 = wire 0x22).
  * the TRANSMIT side sub_FB2323 (0xFB2323), reached from the SEND-button
    dispatcher sub_FB2049.
  * transmit templates prom_b 0xF4FEB4..0xF4FEE5.
  * the parse record: base 0x60FC98, pointer at 0x60FCD8.  The trie walker
    sub_FB63D1 stores wire byte n into FIELD n+3, pinned below by its own
    three store sites.

RUN
    python3 wsa1/notes/sysex-probes/sysex_handshake_21_22.py
    python3 wsa1/notes/sysex-probes/sysex_handshake_21_22.py --census

PASS
    Every assert is silent and the script prints OK.  The headline facts:
      * 0x21 and 0x22 are the two opening steps of a bulk-dump session, not
        an enquiry pair;
      * a received 0x21 is answered with a `22` -- template 0xF4FEDC --
        and NEVER with a `21`: the `21` template has exactly ONE reference
        in 1 MiB and it is on the transmit side;
      * a received 0x22 is answered with `F0 50 23 7E F7`, which carries no
        model triple at all;
      * both replies happen only while the SYSEX BULK DUMP screen (id 0x79)
        is displayed AND the handshake state machine is in the right state;
      * the model triple the peer sends is stored at 0x60FC94..96 and read
        by NOTHING: all 10 references to those slots and to 0x60FC90..92
        are writes;
      * the only thing that puts a model value in an outgoing message is
        sub_FB5F65's unconditional strap patch (see sysex_model_variant.py),
        which writes the MACHINE's own value and never the received one.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
A_BASE, B_BASE = 0xF80000, 0xF00000
IMG = {}
for nm, fn, base in (("prom_a", "wsa1_prom_a.ic12", A_BASE),
                     ("prom_b", "wsa1_prom_b.ic13", B_BASE),
                     ("prom_c", "wsa1_prom_c.ic28", None),
                     ("prom_d", "wsa1_prom_d.bin", None)):
    IMG[nm] = (open(os.path.join(ROMS, fn), "rb").read(), base)
A = IMG["prom_a"][0]
B = IMG["prom_b"][0]


def a(ad, n=1):
    return A[ad - A_BASE:ad - A_BASE + n]


def b(ad, n=1):
    return B[ad - B_BASE:ad - B_BASE + n]


def le32(ad):
    return int.from_bytes(b(ad, 4), "little")


def scan(img, base, pat):
    out, i = [], 0
    while True:
        i = img.find(pat, i)
        if i < 0:
            return out
        out.append(base + i if base is not None else i)
        i += 1


# --- load bases asserted, never assumed --------------------------------------
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert a(0xFB2820, 1) == bytes([0x3C]), "prom_a base"
print("base check OK: prom_a @0x%06X, prom_b @0x%06X" % (A_BASE, B_BASE))

ROOT, NULLREC = 0xF5115B, 0xF4FF61
T_IRQ, T_FG, T_SESSION = 0xF4F800, 0xF4F888, 0xF4F916


def records(addr, limit=512):
    out = []
    for i in range(limit):
        r = b(addr + 6 * i, 6)
        out.append((r[0], r[1], int.from_bytes(r[2:6], "little")))
        if r[0] == 0xFF:
            break
    return out


# ====================================================================== 1
# WHERE 0x21 AND 0x22 DISPATCH.
root = {m: (c, nx) for m, c, nx in records(ROOT, 15)}
assert 0x21 in root and 0x22 in root, "the root must carry both families"
assert root[0x21][0] == 0x00 and root[0x22][0] == 0x00, "both must have subtrees"
ARM = {0x21: root[0x21][1], 0x22: root[0x22][1]}
assert ARM == {0x21: 0xF4FF85, 0x22: 0xF4FFAF}, ARM

CMD = {0x21: 0x07, 0x22: 0x08}
DEPTH_ERR = {}          # family -> [status at each node terminator]
for fam, node in ARM.items():
    seen, errs = [], []
    n1 = records(node)
    errs.append([c for m, c, _ in n1 if m == 0xFF][0])
    kids = [(m, nx) for m, c, nx in n1 if m != 0xFF and c == 0]
    assert kids == [(0x04, {0x21: 0xF4FF73, 0x22: 0xF4FF9D}[fam])], (fam, kids)
    n2 = records(kids[0][1])
    errs.append([c for m, c, _ in n2 if m == 0xFF][0])
    md = [(m, nx) for m, c, nx in n2 if m != 0xFF and c == 0]
    assert [m for m, _ in md] == [0x00, 0x01], "both MD values must be accepted"
    assert md[0][1] == md[1][1], "both MD values must share ONE continuation node"
    n3 = records(md[0][1])
    errs.append([c for m, c, _ in n3 if m == 0xFF][0])
    leaf = [(m, c) for m, c, _ in n3 if m != 0xFF]
    assert leaf == [(0x11, CMD[fam])], (fam, leaf)
    DEPTH_ERR[fam] = errs
assert DEPTH_ERR[0x21] == DEPTH_ERR[0x22] == [0x08, 0x09, 0x0A], DEPTH_ERR

HANDLERS = {}
for fam, c in CMD.items():
    HANDLERS[fam] = (le32(T_IRQ + 4 * c), le32(T_FG + 4 * c), le32(T_SESSION + 4 * c))
assert HANDLERS[0x21] == (0xFB2820, 0xFB22C8, 0xFB28FF), HANDLERS[0x21]
assert HANDLERS[0x22] == (0xFB2820, 0xFB22C8, 0xFB291D), HANDLERS[0x22]
# the foreground slot is the table's DO-NOTHING default: it calls one routine
# and returns, and it is what 30 of the 34 slots hold.
assert a(0xFB22C8, 5) == bytes([0x1D, 0x56, 0x81, 0xFB, 0x0E]), "FG default body"


# ====================================================================== 2
# THE GATES ON ANY REPLY.
# (a) the session loop refuses to run unless the SYSEX BULK DUMP screen is up.
assert a(0xFB2826, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "cp (0x207A),0x79"
assert a(0xFB282B, 2) == bytes([0x6E, 0x46]), "jr nz -> 0xFB2873, do nothing"
assert a(0xFB2873, 4) == bytes([0xB4, 0xB4, 0x5C, 0x0E]), "res 4,(XIX) / pop / ret"
# (b) ... and only for command numbers >= 7, read out of parse-record field 0.
assert a(0xFB283C, 4) == bytes([0xC9, 0xDF, 0x67, 0x33]), "cp A,0x07 / jr c"
# (c) EXHAUSTIVE: only five instructions in 1 MiB compare the panel-mode byte
#     against screen 0x79, and only one of them is the bulk-dump gate.
SCREEN79 = scan(A, A_BASE, bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]))
assert SCREEN79 == [0xFB2826, 0xFB3387, 0xFB340E, 0xFB516A, 0xFB7EFD], SCREEN79
#     0xFB3387/0xFB340E are the `25` tempo transmit/receive, which require the
#     screen NOT to be 0x79; 0xFB516A is the dump-request gate; 0xFB7EFD is
#     Ring600C1E_InitIfPanelMode79.  None of them is on the 0x21/0x22 path.


# ====================================================================== 3
# WHAT THE TWO HANDLERS ACTUALLY DO.
# --- cmd 0x07 (wire 0x21) at 0xFB28FF: idle -> state 1, and TRANSMIT.
assert a(0xFB28FF, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x00]), "cp (0x60FD44),0"
assert a(0xFB2905, 2) == bytes([0x6E, 0x15]), "jr nz -> ret, silently"
assert a(0xFB2907, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x01]), "state := 1"
assert a(0xFB290D, 3) == bytes([0x0B, 0x07, 0x00]), "pushw 7 -- message length"
assert a(0xFB2910, 5) == bytes([0xF2, 0xDC, 0xFE, 0xF4, 0x31]), "lda XBC,0xF4FEDC"
assert a(0xFB2916, 4) == bytes([0x1D, 0x7F, 0x6E, 0xFB]), "call sub_FB6E7F (send)"
assert a(0xFB291C, 1) == bytes([0x0E]), "ret"
REPLY_TO_21 = b(0xF4FEDC, 7)
assert REPLY_TO_21 == bytes([0xF0, 0x50, 0x22, 0x04, 0x00, 0x11, 0xF7]), REPLY_TO_21
# ⇒ a received `21` is answered with a `22`.  It is NOT echoed back as a `21`.

# --- cmd 0x08 (wire 0x22) at 0xFB291D: state 1 -> 2, acknowledgements ON.
assert a(0xFB291E, 5) == bytes([0xF2, 0xD8, 0xFC, 0x60, 0x34]), "XIX = &parse-record ptr"
assert a(0xFB2923, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x01]), "cp (0x60FD44),1"
assert a(0xFB2929, 2) == bytes([0x6E, 0x40]), "jr nz -> the error arm"
for i, (field, dest) in enumerate(((0x06, 0x60FC94), (0x07, 0x60FC95), (0x08, 0x60FC96))):
    at = 0xFB292B + 0x0F * i
    assert a(at, 3) == bytes([0x0B, field, 0x00]), "pushw field %d" % field
    assert a(at + 10, 5) == bytes([0xF2, dest & 0xFF, (dest >> 8) & 0xFF,
                                   (dest >> 16) & 0xFF, 0x41]), "store 0x%06X" % dest
assert a(0xFB2958, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xBF]), "set 7,(0x60FD40)"
assert a(0xFB295D, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x02]), "state := 2"
assert a(0xFB296D, 4) == bytes([0xB9, 0x04, 0x00, 0x18]), "else status := 0x18"
assert a(0xFB2971, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xB4]), "res 4 -- end session"
# the 0x22 handler itself sends nothing.  The reply comes from the
# acknowledger the session step runs right after every handler:
assert a(0xFB28A9, 6) == bytes([0xF2, 0xB1, 0x28, 0xFB, 0x35, 0x3D]), "push 0xFB28B1"
assert a(0xFB28AF, 2) == bytes([0xB0, 0xD8]), "jp (XWA) -- into the handler"
assert a(0xFB28B1, 3) == bytes([0x1E, 0x0A, 0x00]), "calr sub_FB28BE after it"
assert a(0xFB28BF, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xCF]), "bit 7,(0x60FD40)?"
assert a(0xFB28C4, 2) == bytes([0x66, 0x37]), "clear -> send NOTHING"
ACK, NAK, FULL = 0xF4FEB4, 0xF4FEB9, 0xF4FECD
assert a(0xFB28D9, 5) == bytes([0xF2, 0xB4, 0xFE, 0xF4, 0x30]), "status 0 -> ACK"
assert a(0xFB28E9, 5) == bytes([0xF2, 0xCD, 0xFE, 0xF4, 0x31]), "status 0x16 -> 2A"
assert a(0xFB28F1, 5) == bytes([0xF2, 0xB9, 0xFE, 0xF4, 0x31]), "otherwise -> NAK"
assert b(ACK, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7])
assert b(NAK, 5) == bytes([0xF0, 0x50, 0x24, 0x7E, 0xF7])
assert b(FULL, 5) == bytes([0xF0, 0x50, 0x2A, 0x7E, 0xF7])
# ⇒ a received `22` is answered with `F0 50 23 7E F7`, which carries NO model
#   triple, and only because the handler has just raised bit 7.


# ====================================================================== 4
# THE PARSE-RECORD FIELD INDEX IS THE WIRE POSITION PLUS THREE,
# pinned by the trie walker sub_FB63D1's own three store sites, so
# "fields 6,7,8" above are wire bytes 3,4,5 -- the model triple `04 MD 11`.
assert a(0xFB641F, 3) == bytes([0x0B, 0x05, 0x00]), "family byte (wire 2) -> field 5"
assert a(0xFB6445, 3) == bytes([0x0B, 0x00, 0x00]), "command number -> field 0"
assert a(0xFB64D4, 3) == bytes([0x0B, 0x06, 0x00]), "next matched byte (wire 3) -> field 6"
assert a(0xFB6ADA, 3) == bytes([0x0B, 0x04, 0x00]), "parser status -> field 4"
# and the parse record lives at 0x60FC98, immediately after the two triples.
assert a(0xFB7F52, 10) == bytes([0xF2, 0x98, 0xFC, 0x60, 0x30,
                                 0xF2, 0xD8, 0xFC, 0x60, 0x60]), "record base 0x60FC98"


# ====================================================================== 5
# IS THERE ANY CODE THAT BUILDS A REPLY CARRYING THE ENQUIRY'S OWN VALUE?
# The peer's model triple is stored -- twice, once per direction -- and read
# by NOTHING.  EXHAUSTIVE: every reference to all six bytes, in prom_a.
WRITE_OPS = {0x41: "ld (mem),A", 0x46: "ld (mem),H"}
refs = {}
for slot in (0x60FC90, 0x60FC91, 0x60FC92, 0x60FC94, 0x60FC95, 0x60FC96):
    hits = scan(A, A_BASE, slot.to_bytes(3, "little"))
    for h in hits:
        pre, op = A[h - A_BASE - 1], A[h - A_BASE + 3]
        assert pre == 0xF2, "unexpected prefix %02X at 0x%06X" % (pre, h)
        refs.setdefault(slot, []).append((h - 1, op))
assert sorted(refs) == [0x60FC90, 0x60FC91, 0x60FC92, 0x60FC94, 0x60FC95, 0x60FC96]
nwrite = nlda = 0
for slot, lst in refs.items():
    for at, op in lst:
        if op in WRITE_OPS:
            nwrite += 1
        else:
            assert op == 0x34 and at == 0xFB7F21, "unclassified access at 0x%06X" % at
            nlda += 1
assert (nwrite, nlda) == (9, 1), (nwrite, nlda)
# the one address-of is inside sub_FB7F1F, which fills all six bytes with 0xFF
# at reset -- three through XIX, three directly.  It is a WRITER too.
assert a(0xFB7F26, 2) == bytes([0x26, 0xFF]), "H := 0xFF"
assert a(0xFB7F37, 7) == bytes([0xB4, 0x46, 0xBC, 0x01, 0x46, 0xBC, 0x02]), "writes via XIX"
# ⇒ nothing reads the model value the peer sent.  No reply can carry it.

# The ONE thing that puts a model value into an outgoing message is the strap
# patch sub_FB5F65, established by sysex_model_variant.py: it overwrites
# message byte 4 with a constant, from the machine's own strap.
assert a(0xFB5FEC, 4) == bytes([0xB9, 0x04, 0x00, 0x01]), "ld (XBC+4),0x01 -- the 21/22 arm"


# ====================================================================== 6
# THE HANDSHAKE IS A BULK-DUMP SESSION OPENING, AND THE INSTRUMENT IS THE
# ONE THAT SENDS 0x21.  sub_FB2323 is the mirror image of section 3.
assert a(0xFB232A, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xB7]), "res 7 -- acks off"
assert a(0xFB232F, 2) == bytes([0x26, 0x00]), "attempt counter H := 0"
assert a(0xFB2331, 3) == bytes([0x0B, 0x07, 0x00]), "pushw 7"
assert a(0xFB2334, 5) == bytes([0xF2, 0xD5, 0xFE, 0xF4, 0x31]), "lda XBC,0xF4FED5"
assert b(0xF4FED5, 7) == bytes([0xF0, 0x50, 0x21, 0x04, 0x00, 0x11, 0xF7])
assert a(0xFB2355, 3) == bytes([0xC9, 0xCF, 0x08]), "expect cmd 0x08 = a `22`"
assert a(0xFB235A, 4) == bytes([0xCE, 0x61, 0xCE, 0xDB]), "inc H / cp H,3"
for i, (field, dest) in enumerate(((0x06, 0x60FC90), (0x07, 0x60FC91), (0x08, 0x60FC92))):
    at = 0xFB2375 + 0x0F * i
    assert a(at, 3) == bytes([0x0B, field, 0x00]), "pushw field %d" % field
    assert a(at + 10, 5) == bytes([0xF2, dest & 0xFF, (dest >> 8) & 0xFF,
                                   (dest >> 16) & 0xFF, 0x41]), "store 0x%06X" % dest
assert a(0xFB23A2, 2) == bytes([0x26, 0x03]), "attempt counter H := 3"
assert a(0xFB23AD, 5) == bytes([0xF2, 0xDC, 0xFE, 0xF4, 0x31]), "lda XBC,0xF4FEDC"
assert a(0xFB23CE, 2) == bytes([0xC9, 0xD9]), "expect cmd 0x01 = `F0 50 23 7E F7`"
assert a(0xFB23D2, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xBF]), "set 7 -- acks on"
assert a(0xFB23D9, 4) == bytes([0xCE, 0x69, 0xCE, 0xD8]), "dec H / cp H,0"
# BOTH exhausted-attempt paths fall through to the same `ret` with bit 7 still
# clear, so the transfer then runs WITHOUT acknowledgements either way.
assert a(0xFB2373, 2) == bytes([0x68, 0x6A]), "step 1 exhausted -> 0xFB23DF"
assert a(0xFB23DD, 2) == bytes([0x6E, 0xCB]), "step 2 retries, then falls through"
assert a(0xFB23DF, 3) == bytes([0x5C, 0x4B, 0x0E]), "0xFB23DF is the common exit"
# and its caller runs the transfer regardless of what it returned.
assert a(0xFB2060, 4) == bytes([0x1D, 0x23, 0x23, 0xFB]), "sub_FB2049 calls it"
assert a(0xFB2064, 5) == bytes([0xC2, 0x02, 0xF8, 0x60, 0x23]), "then reads the job code"

# EXHAUSTIVE: who names the two templates, across ALL FOUR images.
REF21 = [(n, x) for n, (img, base) in IMG.items()
         for x in scan(img, base, (0xF4FED5).to_bytes(3, "little"))]
REF22 = [(n, x) for n, (img, base) in IMG.items()
         for x in scan(img, base, (0xF4FEDC).to_bytes(3, "little"))]
assert REF21 == [("prom_a", 0xFB2335)], REF21
assert REF22 == [("prom_a", 0xFB23AE), ("prom_a", 0xFB2911)], REF22
# ⇒ the `21` template is named by ONE instruction in 1 MiB and it is on the
#   transmit side.  The instrument SENDS a `21`; it never sends one in reply.
for fam in (0x21, 0x22):
    lits = [(n, x) for n, (img, base) in IMG.items()
            for x in scan(img, base, bytes([0xF0, 0x50, fam]))]
    assert lits == [("prom_b", {0x21: 0xF4FED5, 0x22: 0xF4FEDC}[fam])], lits


# ====================================================================== 7
# THE POSITIVE CONTROL: the `2B` PARAMETER request, same wire, same parser,
# same dispatcher -- and NO screen gate.
node2b = root[0x2B][1]
assert root[0x2B][0] == 0x00 and node2b == 0xF5114F, hex(node2b)
PARAM_REQ = 0x1A
assert le32(T_IRQ + 4 * PARAM_REQ) == le32(T_FG + 4 * PARAM_REQ) == 0x00FB42AB
# its handler never compares the panel-mode byte -- no site in SCREEN79 lies
# in it, and it dispatches straight on parse-record field 1.
assert a(0xFB42AB, 3) == bytes([0x0B, 0x01, 0x00]), "pushw field 1"
assert a(0xFB42C7, 6) == bytes([0xE8, 0xC8, 0xD1, 0x42, 0xFB, 0x00]), "JumpTable_FB42D1"
# EXHAUSTIVE over the WHOLE 2B/2C parameter engine, 0xFB3483..0xFB5122 -- the
# span from the first non-session handler to the dump-request arms:
assert not any(0xFB3483 <= s < 0xFB5122 for s in SCREEN79), "a screen gate in the 2B/2C engine"
# and its reply is built from the `2C` template, which sysex_model_variant.py
# shows the strap patch also rewrites.
assert b(0xF4FEF2, 6) == bytes([0xF0, 0x50, 0x2C, 0x04, 0x00, 0x11])
assert len(scan(A, A_BASE, (0xF4FEF2).to_bytes(3, "little"))) == 9

# the same asymmetry appears in the ERROR reply.  sub_FB5197 runs at the tail
# of BOTH outer dispatchers; it answers a failed message ONLY when the family
# byte in field 5 is 0x2B or 0x2C.  0x21 and 0x22 fall through in silence.
assert a(0xFB21C1, 4) == bytes([0x1D, 0x97, 0x51, 0xFB]), "IRQ dispatcher tail"
assert a(0xFB22BE, 4) == bytes([0x1D, 0x97, 0x51, 0xFB]), "FG dispatcher tail"
assert a(0xFB5198, 3) == bytes([0x0B, 0x04, 0x00]), "read field 4 -- the status"
assert a(0xFB51A7, 4) == bytes([0xC9, 0xD8, 0x66, 0x3A]), "status 0 -> say nothing"
assert a(0xFB51AB, 3) == bytes([0x0B, 0x05, 0x00]), "read field 5 -- the family"
assert a(0xFB51BC, 3) == bytes([0xC9, 0xCF, 0x2B]), "cp A,0x2B"
assert a(0xFB51C1, 5) == bytes([0xC9, 0xCF, 0x2C, 0x6E, 0x1F]), "cp A,0x2C / else out"
assert a(0xFB51C9, 5) == bytes([0xF2, 0xC8, 0xFE, 0xF4, 0x31]), "lda XBC,0xF4FEC8"
assert b(0xF4FEC8, 5) == bytes([0xF0, 0x50, 0x29, 0x7E, 0xF7])

# and the dump-request form of 0x2B has a screen gate that ADMITS a second
# screen, which is why even a refused dump request answers something.
assert a(0xFB516A, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "screen 0x79 ..."
assert a(0xFB5171, 5) == bytes([0xC1, 0x76, 0x20, 0x3F, 0x01]), "... or (0x2076)==1 ..."
assert a(0xFB5178, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x01]), "... and (0x207A)==1"
assert a(0xFB5184, 3) == bytes([0x0B, 0x11, 0x00]), "else status 0x11 -> `29 7E`"


# ====================================================================== 8
# COVERAGE.  Every place a 0x21 or 0x22 can be the FAMILY byte.
CENSUS = {
    "grammar-trie arms (prom_b)": [
        "0x%06X  the 0x21 subtree, 4 accepted sequences, cmd 0x07" % ARM[0x21],
        "0x%06X  the 0x22 subtree, 4 accepted sequences, cmd 0x08" % ARM[0x22]],
    "handler-table slots (prom_b), 3 tables x 2 commands": [
        "0x%06X+0x%02X -> 0x%06X" % (t, 4 * c, le32(t + 4 * c))
        for c in (0x07, 0x08) for t in (T_IRQ, T_FG, T_SESSION)],
    "literal `F0 50 21` / `F0 50 22` in the four images": [
        "prom_b 0xF4FED5 (the `21` template)",
        "prom_b 0xF4FEDC (the `22` template)"],
    "instructions naming those templates": [
        "0x%06X  %s" % (x, w) for x, w in (
            (0xFB2335, "sub_FB2323 step 1 -- SENDS a `21`"),
            (0xFB23AE, "sub_FB2323 step 2 -- SENDS a `22`"),
            (0xFB2911, "the cmd 0x07 handler -- ANSWERS a `21` with a `22`"))],
    "instructions comparing a byte against 0x21 or 0x22 in the SysEx engine": [
        "0x%06X  cp A,0x22 -- the 34-command table bound, not a family byte" % x
        for x in scan(A, A_BASE, bytes([0xC9, 0xCF, 0x22])) if 0xFB2000 <= x < 0xFB8200]
        + ["0x%06X  cp H,0x22 -- the same bound" % x
           for x in scan(A, A_BASE, bytes([0xCE, 0xCF, 0x22])) if 0xFB2000 <= x < 0xFB8200],
}
# the engine never compares an incoming byte against 0x21 at all: the trie does
# all family matching, data-driven, through ONE `cp C,H` at 0xFB6415.
assert not [x for x in scan(A, A_BASE, bytes([0xC9, 0xCF, 0x21])) if 0xFB2000 <= x < 0xFB8200]
assert not [x for x in scan(A, A_BASE, bytes([0xCE, 0xCF, 0x21])) if 0xFB2000 <= x < 0xFB8200]
assert a(0xFB6415, 2) == bytes([0xCE, 0xF3]), "the trie's one comparator"
assert CENSUS["instructions comparing a byte against 0x21 or 0x22 in the SysEx engine"] == [
    "0x%06X  cp A,0x22 -- the 34-command table bound, not a family byte" % x
    for x in (0xFB2194, 0xFB2291)] + [
    "0xFB2896  cp H,0x22 -- the same bound"], CENSUS[
        "instructions comparing a byte against 0x21 or 0x22 in the SysEx engine"]


# ====================================================================== report
print()
print("wire         cmd   irq-table    fg-table     session-table")
for fam in (0x21, 0x22):
    i, f, s = HANDLERS[fam]
    print("F0 50 %02X ..  0x%02X  0x%06X     0x%06X     0x%06X"
          % (fam, CMD[fam], i, f, s))
print("             (irq slot = the bulk-dump SESSION LOOP; fg slot = do nothing)")
print()
print("accepted: F0 50 %02X 04 <00|01> 11 F7 and F0 50 %02X 04 <00|01> 11 F7"
      % (0x21, 0x22))
print("  the MD byte is matched but not compared: both values share one node")
print("  malformed at depth 1/2/3 -> parser status 0x%02X / 0x%02X / 0x%02X"
      % tuple(DEPTH_ERR[0x21]))
print()
print("RECEIVING 0x21  (handler 0xFB28FF)")
print("  gate 1: screen (0x207A) must be 0x79, SYSEX BULK DUMP  (0xFB2826)")
print("  gate 2: handshake state (0x60FD44) must be 0        (0xFB28FF)")
print("  then:   state := 1 and TRANSMIT 7 bytes from 0xF4FEDC:")
print("          %s   <- a `22`, not a `21`"
      % " ".join("%02X" % x for x in REPLY_TO_21))
print()
print("RECEIVING 0x22  (handler 0xFB291D)")
print("  gate 1: screen (0x207A) must be 0x79                 (0xFB2826)")
print("  gate 2: handshake state (0x60FD44) must be 1         (0xFB2923)")
print("  then:   wire bytes 3,4,5 (the peer's model triple) -> 0x60FC94..96,")
print("          bit 7 of (0x60FD40) goes up, state := 2, and the session")
print("          step's acknowledger sub_FB28BE -- which had been silent --")
print("          sends %s"
      % " ".join("%02X" % x for x in b(ACK, 5)))
print("  wrong state: status 0x18, session ends, and nothing is sent")
print()
print("THE PEER'S MODEL VALUE: stored twice, read never")
print("  0x60FC90..92 (transmit side, 0xFB237F/8E/9D)")
print("  0x60FC94..96 (receive side,  0xFB2935/44/53)")
print("  %d references in prom_a, %d writes + %d address-of, and the address-of"
      % (nwrite + nlda, nwrite, nlda))
print("  is sub_FB7F1F filling all six with 0xFF at reset.  NOTHING READS THEM.")
print()
print("THE INSTRUMENT IS THE ONE THAT SENDS A `21`")
print("  the `21` template 0xF4FED5 is named by exactly ONE instruction in the")
print("  four images: 0x%06X, sub_FB2323 step 1." % REF21[0][1])
print("  the `22` template 0xF4FEDC is named by two: 0x%06X (step 2) and"
      % REF22[0][1])
print("  0x%06X (the reply to a received `21`)." % REF22[1][1])
print()
print("POSITIVE CONTROL -- the same parser, a path that DOES answer at rest")
print("  F0 50 2B 04 <00|01> 11 <gg> <pp> ... -> cmd 0x%02X -> 0x%06X in BOTH"
      % (PARAM_REQ, le32(T_IRQ + 4 * PARAM_REQ)))
print("  outer tables, and NO instruction anywhere in 0xFB3483-0xFB5122, the whole")
print("  parameter engine, compares the panel-mode byte.  Its reply is built from")
print("  the `2C` template 0xF4FEF2, named by 9 instructions in that span, and the")
print("  strap patch rewrites its MD too -- so a `2B` request IS an at-rest test")
print("  of which model answered.")
print("  Even a REFUSED 0x2B or 0x2C is answered: sub_FB5197, at the tail of")
print("  both dispatchers, sends F0 50 29 7E F7 when the status is non-zero")
print("  AND the family byte is 0x2B or 0x2C.  0x21 and 0x22 are never in that")
print("  set, so a badly framed or ill-timed 21/22 is answered with silence.")
print()
if "--census" in sys.argv:
    print("COVERAGE CENSUS")
    for k in CENSUS:
        print("  %s" % k)
        for line in CENSUS[k]:
            print("      %s" % line)
    print()
print("every site that can see a 0x21/0x22 family byte is accounted for:")
print("  2 trie subtrees, 6 handler-table slots, 2 ROM literals, 3 instructions")
print("  naming them, and 0 compares against 0x21 or 0x22 as a family byte")
print("  anywhere in 0xFB2000-0xFB8200 -- the trie's single `cp C,H` at")
print("  0xFB6415 does all family matching, from data.")
print()
print("OK")
