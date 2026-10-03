#!/usr/bin/env python3
"""What answers `F0 50 21 ...` and `F0 50 22 ...`, and under exactly what conditions.

QUESTION THIS ANSWERS
    The reference called these two messages an identity enquiry and said both
    are answered with the model's own MD byte.  This asks the ROM instead:
    which handler receives each one, what has to be true for it to reply, what
    it puts on the wire, and what the model byte in that reply is.

WHERE THE SIGNAL IS
  * GRAMMAR.  `21 04 <00|01> 11 F7` terminates in command 0x07 and
    `22 04 <00|01> 11 F7` in command 0x08 -- read out of the trie by
    sysex_command_map.py, whose paths this script does not repeat.

  * SCREEN GATE.  Both command numbers are routed by the interrupt-side
    dispatch table (prom_b 0xF4F800) to 0xFB2820, the bulk-dump SESSION
    ENTRY, whose first instruction is `cp (0x207A),0x79` -- the panel mode
    byte against the SYSEX BULK DUMP screen -- and whose failure arm,
    0xFB2873, is `res 4,(XIX) / pop XIX / ret`.  Nothing is transmitted and
    no error is raised: off that screen the message is dropped in silence.
    The foreground table (0xF4F888) sends both to the no-op at 0xFB22C8.
    Contrast command 0x1A, the `2B` parameter request, which BOTH tables
    send straight to 0xFB42AB with no screen test anywhere.

  * HANDSHAKE STATE.  Inside a session, the third table (prom_b 0xF4F916)
    gives 0x07 -> 0xFB28FF and 0x08 -> 0xFB291D.  (0x60FD44) is the state:
      - 0xFB28FF answers `21` ONLY while it is 0, then writes 1 and
        transmits the 7 bytes at prom_b 0xF4FEDC, `F0 50 22 04 00 11 F7`.
      - 0xFB291D accepts `22` ONLY while it is 1, then stores the sender's
        own PC/MD/VER at (0x60FC94..96), sets bit 7 of (0x60FD40) -- the
        flag that switches acknowledgements on -- and writes 2.  It
        transmits NOTHING.  Out of state it stores status 0x18 at
        0xFB296D, which is `ERROR 42!`.
      - 0xFB8177 puts the state back to 0 when the session ends.

  * WHAT REPLIES ONCE THE SESSION IS OPEN.  With bit 7 of (0x60FD40) set,
    sub_FB28BE answers EVERY message from the parse record's status field:
    0 -> `F0 50 23 7E F7` (0xF4FEB4), 0x16 -> `F0 50 2A 7E F7` (0xF4FECD),
    anything else -> `F0 50 24 7E F7` (0xF4FEB9).  So a `21` arriving with a
    session already open is answered -- with an acknowledgement that carries
    no model byte at all.

  * THE MODEL BYTE.  The reply template is `04 00 11`.  SysExTx_AppendAndSendOnF7, the
    transmitter the `21` handler calls, reaches SysExTx_SendFrameMidi1, whose first call
    is SysExTx_PatchModelByteVariant2 -- the patcher that rewrites message byte 4 from 00 to 01
    on families 0x21/0x22/0x2C/0x2D when the strap (0xC4) reads 2.  The
    reply therefore carries the machine's OWN model byte whatever the
    enquiry carried, because the enquiry's byte is never consulted.

  * THE DUMP REQUEST's DIFFERENT GATE.  Commands 0x1B..0x1F (`2B` with an
    area byte) run sub_FB516A, which admits the request on screen 0x79 OR
    when (0x2076) and (0x207A) both read 1, and otherwise stores status
    0x11.  That is a second, wider screen gate -- not the absence of one.

RUN
    python3 wsa1/notes/sysex-probes/sysex_handshake_gate.py
    python3 wsa1/notes/sysex-probes/sysex_handshake_gate.py --tables

MEASURED AGAINST THE EMULATED INSTRUMENT
    wsa1r-librarian/tools/emulator-probes/ask-sysex-screen-gate.sh (idle:
    silence), ask-sysex-on-bulkdump-screen.sh (on screen 0x79: answered) and
    panel-send-dump.sh (the instrument TRANSMITS `F0 50 21 04 01 11 F7` when a
    dump is started from its own panel).

PASS
    Both load bases check out, every assert is silent and the script prints
    OK.  Headline facts: 2 commands behind ONE screen gate, 1 of the 2 ever
    transmits a reply, reply `F0 50 22 04 00 11 F7` -> `04 01 11` on the rack,
    3 acknowledgement templates, and 0 screen tests on the parameter path.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
A_BASE, B_BASE = 0xF80000, 0xF00000
rom_a = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
rom_b = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()


def a(addr, n=1):
    o = addr - A_BASE
    assert 0 <= o < len(rom_a), "prom_a address out of range"
    return rom_a[o:o + n]


def b(addr, n=1):
    o = addr - B_BASE
    assert 0 <= o < len(rom_b), "prom_b address out of range"
    return rom_b[o:o + n]


def le32(buf):
    return int.from_bytes(buf, "little")


def hexs(buf):
    return " ".join("%02X" % x for x in buf)


# --- load bases, asserted by content not assumed --------------------------
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base wrong"
assert a(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base wrong"
print("base check OK: prom_a @0x%06X, prom_b @0x%06X" % (A_BASE, B_BASE))
print()

SESSION_ENTRY = 0xFB2820
NOOP = 0xFB22C8
PARAM_REQ = 0xFB42AB

# --- 1. both commands land on the session entry, and the parameter one does not
IRQ_TAB, FG_TAB = 0xF4F800, 0xF4F888
irq = [le32(b(IRQ_TAB + 4 * i, 4)) for i in range(0x22)]
fg = [le32(b(FG_TAB + 4 * i, 4)) for i in range(0x22)]
assert irq[0x07] == SESSION_ENTRY and irq[0x08] == SESSION_ENTRY, "21/22 no longer session commands"
assert fg[0x07] == NOOP and fg[0x08] == NOOP, "foreground slot for 21/22 moved"
assert irq[0x1A] == PARAM_REQ and fg[0x1A] == PARAM_REQ, "parameter request handler moved"
print("outer dispatch")
print("  cmd 0x07  `F0 50 21 04 <00|01> 11 F7`   irq -> 0x%06X   fg -> 0x%06X" % (irq[0x07], fg[0x07]))
print("  cmd 0x08  `F0 50 22 04 <00|01> 11 F7`   irq -> 0x%06X   fg -> 0x%06X" % (irq[0x08], fg[0x08]))
print("  cmd 0x1A  `F0 50 2B ...` one parameter  irq -> 0x%06X   fg -> 0x%06X" % (irq[0x1A], fg[0x1A]))
print()

# --- 2. the screen gate, and the fact that failing it says nothing --------
# 0xFB2826  c1 7a 20 3f 79   cp (0x207A),0x79
# 0xFB282B  6e 46            jr nz, +0x46   -> 0xFB2873
# 0xFB2873  b4 b4 5c 0e      res 4,(XIX) / pop XIX / ret
assert a(0xFB2826, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "screen gate moved"
assert a(0xFB282B, 2) == bytes([0x6E, 0x46]), "screen gate branch moved"
assert 0xFB282D + 0x46 == 0xFB2873, "screen gate branch target moved"
assert a(0xFB2873, 4) == bytes([0xB4, 0xB4, 0x5C, 0x0E]), "silent-return arm moved"
SCREEN = a(0xFB2826, 5)[4]
print("screen gate at 0x%06X" % SESSION_ENTRY)
print("  cp (0x207A),0x%02X    -- 0x%02X is the SYSEX BULK DUMP screen" % (SCREEN, SCREEN))
print("  jr nz -> 0xFB2873 = res 4,(XIX) / pop XIX / ret")
print("  nothing transmitted, no status stored: off that screen it is SILENCE,")
print("  which on the wire is indistinguishable from a dead cable.")
print()

# nothing on the parameter path tests the panel. Scan the whole 0x2B/0x2C
# handler region for a reference to the panel mode byte.
NEEDLE = bytes([0x7A, 0x20])        # the 16-bit operand of any (0x207A) access
lo, hi = 0xFB39A0, 0xFB4B00          # the single-parameter handlers
hits = [lo + i for i in range(hi - lo) if a(lo + i, 2) == NEEDLE]
print("panel-mode references inside the single-parameter handlers 0x%06X-0x%06X: %d"
      % (lo, hi, len(hits)))
assert not hits, "something in the parameter path now reads the panel mode byte"
print("  -> a parameter message is answered wherever the instrument is standing")
print()

# --- 3. the handshake state machine --------------------------------------
INNER = 0xF4F916
inner = [le32(b(INNER + 4 * i, 4)) for i in range(0x22)]
assert inner[0x07] == 0xFB28FF, "in-session handler for 21 moved"
assert inner[0x08] == 0xFB291D, "in-session handler for 22 moved"
# 0xFB28FF  c2 44 fd 60 3f 00  cp (0x60FD44),0x00
# 0xFB2905  6e 15              jr nz, +0x15 -> 0xFB291C (a bare ret)
# 0xFB2907  f2 44 fd 60 00 01  ld (0x60FD44),0x01
# 0xFB2910  f2 dc fe f4 31     lda xbc,0xF4FEDC
assert a(0xFB28FF, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x00]), "HRQ state test moved"
assert a(0xFB2905, 2) == bytes([0x6E, 0x15]) and 0xFB2907 + 0x15 == 0xFB291C, "HRQ refusal arm moved"
assert a(0xFB291C, 1) == bytes([0x0E]), "HRQ refusal arm is not a bare ret"
assert a(0xFB2907, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x01]), "HRQ state write moved"
assert a(0xFB290D, 3) == bytes([0x0B, 0x07, 0x00]), "HRQ reply length moved"
assert a(0xFB2910, 5) == bytes([0xF2, 0xDC, 0xFE, 0xF4, 0x31]), "HRQ reply template moved"
assert a(0xFB2916, 4) == bytes([0x1D, 0x7F, 0x6E, 0xFB]), "HRQ transmitter moved"
HRT = b(0xF4FEDC, 7)
assert HRT == bytes([0xF0, 0x50, 0x22, 0x04, 0x00, 0x11, 0xF7]), "HRQ reply bytes changed"

# 0xFB2923  c2 44 fd 60 3f 01  cp (0x60FD44),0x01
# 0xFB2958  f2 40 fd 60 bf     set 7,(0x60FD40)     -- acknowledgements on
# 0xFB295D  f2 44 fd 60 00 02  ld (0x60FD44),0x02
# 0xFB296D  b9 04 00 18        ld (XBC+4),0x18      -- ERROR 42!
assert a(0xFB2923, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x01]), "HRT state test moved"
assert a(0xFB2958, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xBF]), "acknowledgement enable moved"
assert a(0xFB295D, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x02]), "HRT state write moved"
assert a(0xFB296D, 4) == bytes([0xB9, 0x04, 0x00, 0x18]), "HRT out-of-state status moved"
assert a(0xFB8177, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x00]), "state reset moved"
# the HRT handler transmits nothing: no call to either message sender in its body
BODY = a(0xFB291D, 0xFB2978 - 0xFB291D)
for sender in (0xFB6E7F, 0xFB6F24):
    call = bytes([0x1D]) + sender.to_bytes(4, "little")[:3] + b"\xfb"
    assert call[:4] not in BODY, "the HRT handler now transmits something"
print("handshake state (0x60FD44), inside a session on screen 0x%02X" % SCREEN)
print("  `21` 0xFB28FF   state must be 0 -> writes 1, transmits %s" % hexs(HRT))
print("                  state not 0     -> 0xFB291C, a bare ret, nothing sent")
print("  `22` 0xFB291D   state must be 1 -> writes 2, sets bit 7 of (0x60FD40),")
print("                                     transmits NOTHING of its own")
print("                  state not 1     -> status 0x18 = ERROR 42!")
print("  0xFB8177 puts the state back to 0 when the session ends")
print()

# --- 4. what an open session answers with --------------------------------
# sub_FB28BE, gated on bit 7 of (0x60FD40)
assert a(0xFB28BF, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xCF]), "acknowledgement gate moved"
assert a(0xFB28D2, 2) == bytes([0xCE, 0xD8]), "status==0 test moved"
assert a(0xFB28D9, 5) == bytes([0xF2, 0xB4, 0xFE, 0xF4, 0x30]), "ACK template moved"
assert a(0xFB28E4, 3) == bytes([0xCE, 0xCF, 0x16]), "memory-full test moved"
assert a(0xFB28E9, 5) == bytes([0xF2, 0xCD, 0xFE, 0xF4, 0x31]), "memory-full template moved"
assert a(0xFB28F1, 5) == bytes([0xF2, 0xB9, 0xFE, 0xF4, 0x31]), "NAK template moved"
ACKS = [(0x00, 0xF4FEB4), (0x16, 0xF4FECD), (None, 0xF4FEB9)]
print("with a session open (bit 7 of (0x60FD40) set) sub_FB28BE answers EVERY message")
for status, tpl in ACKS:
    print("  status %-4s -> 0x%06X  %s"
          % ("0x%02X" % status if status is not None else "any", tpl, hexs(b(tpl, 5))))
print("  none of the three carries a model byte")
print()

# --- 5. the model byte in the reply --------------------------------------
# SysExTx_AppendAndSendOnF7 0xFB6ED8 `calr SysExTx_SendFrameMidi1`; SysExTx_SendFrameMidi1 0xFB7174 `calr SysExTx_PatchModelByteVariant2`
def calr_target(addr):
    op = a(addr, 3)
    assert op[0] == 0x1E, "not a calr at 0x%06X" % addr
    disp = int.from_bytes(op[1:3], "little", signed=True)
    return addr + 3 + disp


assert calr_target(0xFB6ED8) == 0xFB7165, "transmitter no longer calls 0xFB7165"
assert calr_target(0xFB7174) == 0xFB5F65, "0xFB7165 no longer calls the model patcher"
assert a(0xFB5F6D, 4) == bytes([0xC0, 0xC4, 0x3F, 0x02]), "strap test in the patcher moved"
# the patcher's family whitelist, read as the four `cp BC,imm16` operands
fams = []
for off in (0xFB5F88, 0xFB5F8F, 0xFB5F95, 0xFB5F9B):
    ins = a(off, 4)
    assert ins[0] == 0xD9 and ins[1] == 0xCF, "family test at 0x%06X moved" % off
    fams.append(ins[2])
assert fams == [0x21, 0x22, 0x2C, 0x2D], "patcher family list changed: %s" % fams
patched = bytearray(HRT)
patched[4] = 0x01
print("model byte")
print("  0xFB6E7F -> 0xFB7165 -> 0xFB5F65, which when (0xC4) == 2 rewrites byte 4")
print("  of families %s from 00 to 01" % " ".join("%02X" % f for f in fams))
print("  keyboard transmits  %s" % hexs(HRT))
print("  rack transmits      %s" % hexs(patched))
# the enquiry's own MD byte cannot reach the reply: the trie's two records for it
# descend to the same node. Records are [match, cmd, LE32 next], 6 bytes.
for node, name in ((0xF4FF73, "21"), (0xF4FF9D, "22")):
    recs = [b(node + 6 * i, 6) for i in range(2)]
    assert recs[0][0] == 0x00 and recs[1][0] == 0x01, "%s MD records changed" % name
    assert le32(recs[0][2:]) == le32(recs[1][2:]), "%s MD records now diverge" % name
print("  the enquiry's own byte is never read back: the trie's records for 00 and 01")
print("  at 0x%06X (`21`) and 0x%06X (`22`) both descend to the SAME node, so it"
      % (0xF4FF73, 0xF4FF9D))
print("  cannot reach the reply")
print()

# --- 6. the dump request's own, wider gate -------------------------------
assert a(0xFB516A, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "DRQ screen test moved"
assert a(0xFB5171, 5) == bytes([0xC1, 0x76, 0x20, 0x3F, 0x01]), "DRQ second test moved"
assert a(0xFB5178, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x01]), "DRQ third test moved"
print("dump request (commands 0x1B..0x1F) -- sub_FB516A")
print("  accepted when (0x207A) == 0x79, or when (0x2076) == 1 and (0x207A) == 1")
print("  otherwise status 0x11")
print("  -- a gate of its own, wider than the session entry's but not absent")
print()

if "--tables" in sys.argv:
    print("=== every command number, and where the three tables send it ===")
    print(" cmd | interrupt  | foreground | in-session")
    for i in range(0x22):
        print("  %02X  |  0x%06X  |  0x%06X  |  0x%06X" % (i, irq[i], fg[i], inner[i]))
    print()

print("OK")
