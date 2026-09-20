#!/usr/bin/env python3
"""What the WSA1R does with an INCOMING bulk-dump data message.

QUESTION THIS ANSWERS
    When `F0 50 2D 04 nn 11 <addr> <size> ... F7` arrives: what picks the
    destination, is an arbitrary address honoured, what bounds the write,
    what must have happened before the message, and does the front panel
    have to be on the SYSEX BULK DUMP screen?

WHERE THE SIGNAL IS
  * SCREEN GATE.  prom_a 0xFB2820 is the default slot of BOTH outer
    dispatch tables (0xF4F800 interrupt side, 0xF4F888 foreground side),
    i.e. it is what every bulk-dump command reaches.  Its first two tests
    are `cp (0x207A),0x79` (0xFB2826) and `cp a,0x07 / jr c` on parse-record
    field 0 (0xFB283C).  (0x207A) is the panel mode byte and 0x79 is the
    SYSEX BULK DUMP screen -- prom_a's own header on
    ScreenLeave_SysexBulkDump_Entry (0xF99831) binds screen id 0x79 to that
    screen object, whose ENTER method is Paint_SysexBulkDump.

  * DESTINATION SELECTION.  The grammar trie (see sysex_command_map.py)
    matches the six address+size septets LITERALLY.  Eight forms exist and
    they are exactly the eight the instrument itself transmits.  The match
    yields a command number; the command number's handler in the THIRD
    dispatch table (0xF4F916) calls a fixed descriptor writer.  Nothing
    reads the address septets back: parse-record fields 9/0x0A/0x0B are
    never fetched anywhere in the bulk-dump code, only in the 0x2B/0x2C
    single-parameter handlers at 0xFB39xx-0xFB4Axx.

  * ORDER.  Every data handler opens with `sub_FB62D3(3, (0x60FCDC))` --
    parse-record field 3, the session step -- and compares it against one
    literal.  A mismatch stores an error status and the session ends.  The
    step a handler then WRITES is the index under which the same routine
    appears in the continuation table 0xF4F99E, which is how a following
    `F0 50 7E ...` frame (command 0x0A, which carries no address at all)
    finds its way back to the same destination.

  * BOUND.  sub_FB72B5 / sub_FB7365 decode two message bytes into one
    destination byte and decrement the counter at (0x60FD20), which the
    handler's own descriptor writer loaded with a length the FIRMWARE
    knows.  If body bytes remain when that counter reaches zero the status
    becomes 0x16 -> `ERROR 21! Memory full` and the reply is
    `F0 50 2A 7E F7`.  The one message whose length the firmware does not
    know (SEQUENCER part 3) takes its length from the message, and
    sub_FB6BF4 rejects it above 0x50C00 with the same status.

  * COLLECTOR CEILING.  sub_FB6098 refuses a further body byte once the
    stored count reaches 0xFF, and the count starts at 1 on the F0.  The
    closing F7 bypasses the test.

  * WRITE PROTECT.  sub_FB6B87 maps the command number through the byte
    table at prom_b 0xF4FE82 to a class, and refuses class 1 when
    (0x7FD6) bit 1 is set, class 2 when bit 0 is set and class 3 when
    either is -- with status 0x21, which sub_FB7DFE turns into screen 0xB3,
    the "The SOUND or COMBINATION memories are write protected" screen.

RUN
    python3 wsa1/notes/sysex-probes/sysex_bulkdump_rx.py
    python3 wsa1/notes/sysex-probes/sysex_bulkdump_rx.py --order

PASS
    Both load bases check out, every assert is silent and the script
    prints OK.  The headline numbers are 8 accepted header forms, a
    0x50C00 ceiling on the one variable-length message, a 256-byte
    maximum message on the wire, screen 0x79, and 5 steps at which
    `end of category` is legal.
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


# --- load bases, asserted not assumed -------------------------------------
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base wrong"
assert a(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base wrong"
print("base check OK: prom_a @0x%06X, prom_b @0x%06X" % (A_BASE, B_BASE))
print()

# --- 1. the screen gate ---------------------------------------------------
# 0xFB2826  c1 7a 20 3f 79   cp (0x207A),0x79
# 0xFB283C  c9 df            cp a,0x07        (field 0, the command number)
assert a(0xFB2826, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79]), "screen gate moved"
assert a(0xFB283C, 2) == bytes([0xC9, 0xDF]), "command-number floor moved"
SCREEN = a(0xFB2826, 5)[4]
print("Session entry 0xFB2820 -- the default slot of BOTH outer dispatch tables")
print("  requires panel mode (0x207A) == 0x%02X  (SYSEX BULK DUMP)" % SCREEN)
print("  requires parse-record field 0 (command) >= 0x07")
for t in (0xF4F800, 0xF4F888):
    tab = [le32(b(t + 4 * i, 4)) for i in range(0x22)]
    n = sum(1 for v in tab if v == 0xFB2820)
    print("  table 0x%06X sends %2d of 34 commands to 0xFB2820" % (t, n))
assert le32(b(0xF4F888 + 4 * 0x00, 4)) == 0xFB22C8, "foreground default moved"
print("  the foreground table's default is 0xFB22C8, a no-op -> a dump")
print("  offered on the second MIDI input is never received")
print()

# --- 2. the eight accepted headers and where each one lands ---------------
# Transmit templates: prom_b 0xF4FEF8.. , each `F0 50 2D 04 00 11 <a2 a1 a0> <l2 l1 l0>`
TEMPLATES = {
    0x0B: (0xF4FEF8, "SYSTEM, PART & MIDI part 1"),
    0x0C: (0xF4FF04, "SYSTEM, PART & MIDI part 2"),
    0x0E: (0xF4FF1C, "SOUND"),
    0x15: (0xF4FF49, "COMBINATION part 1"),
    0x16: (0xF4FF55, "COMBINATION part 2"),
    0x12: (0xF4FF28, "SEQUENCER part 1"),
    0x13: (0xF4FF34, "SEQUENCER part 2"),
    0x14: (0xF4FF40, "SEQUENCER part 3"),
}

ROOT, NULLREC = 0xF5115B, 0xF4FF61


def records(addr, limit=512):
    out = []
    for i in range(limit):
        r = b(addr + 6 * i, 6)
        out.append((r[0], r[1], le32(r[2:6])))
        if r[0] == 0xFF:
            break
    return out


def walk(node, prefix, out, depth=0):
    if depth > 16:
        return
    for m, c, nx in records(node):
        if m == 0xFF:
            break
        seq = prefix + [m]
        if c:
            out.append((c, seq))
        elif nx != NULLREC:
            walk(nx, seq, out, depth + 1)


# descend the root to the 0x2D subtree, then enumerate it to the bottom
root = records(ROOT, 15)
node_2d = next(nx for m, c, nx in root if m == 0x2D)
forms = []
walk(node_2d, [0x2D], forms)
# the unit field is 0x00 or 0x01; keep the 0x00 arm, they are identical
forms = [(c, s) for c, s in forms if s[2] == 0x00]
assert len(forms) == 8, "expected 8 data-message forms under 0x2D, got %d" % len(forms)
assert sorted(c for c, _ in forms) == sorted(TEMPLATES), "command set changed"

print("Accepted data-message headers -- matched byte for byte, no arithmetic")
print("  %-26s %-11s %-11s %9s" % ("category", "address", "length", "bytes"))
for c, seq in sorted(forms, key=lambda x: TEMPLATES[x[0]][1]):
    tpl, name = TEMPLATES[c]
    hdr = b(tpl, 12)
    assert hdr[:6] == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11]), "template %s" % name
    addr = hdr[6:9]
    # the trie pins bytes 2.. of the message; seq is [2D,04,00,11,...]
    assert list(seq[4:7]) == list(addr), "address mismatch for %s" % name
    if len(seq) > 7:                       # a size is pinned too
        size = hdr[9:12]
        assert list(seq[7:10]) == list(size), "size mismatch for %s" % name
        nbytes = "%d" % (size[0] << 14 | size[1] << 7 | size[2])
        sz = " ".join("%02X" % x for x in size)
    else:
        nbytes = "from the message"
        sz = "-- free --"
    print("  %-26s %-11s %-11s %9s"
          % (name, " ".join("%02X" % x for x in addr), sz, nbytes))
print("  Any other address or length falls off the trie and is an ERROR 41.")
print()

# --- 3. the destination bound --------------------------------------------
# sub_FB76B5 (SEQUENCER part 3's destination) hard-codes 0x00050C00 at +8,
# and sub_FB6BF4 rejects a larger length field with status 0x16.
assert a(0xFB76CC, 5) == bytes([0x41, 0x00, 0x0C, 0x05, 0x00]), "seq3 extent moved"
assert a(0xFB6C69, 6) == bytes([0xE9, 0xCF, 0x00, 0x0C, 0x05, 0x00]), "seq3 ceiling moved"
assert a(0xFB6CA1, 3) == bytes([0x0B, 0x16, 0x00]), "seq3 over-size status moved"
CEIL = le32(a(0xFB6C69, 6)[2:6])
assert CEIL == le32(a(0xFB76CC, 5)[1:5]), "the ceiling and the extent disagree"
print("The only length the message itself controls: SEQUENCER part 3")
print("  ceiling 0x%06X (%d bytes), the exact extent the firmware reserves;"
      % (CEIL, CEIL))
print("  above it, status 0x16 -> ERROR 21! Memory full")
# status 0x16 is also what the unpacker raises when the area fills mid-message
assert a(0xFB734C, 3) == bytes([0x0B, 0x16, 0x00]), "unpacker full-status moved"
assert a(0xFB7401, 3) == bytes([0x0B, 0x16, 0x00]), "unpacker full-status moved"
assert b(0xF511C7 + 0x16) == bytes([0x0F]), "status 0x16 no longer maps to ERROR 21"
assert b(0xF4FECD, 5) == bytes([0xF0, 0x50, 0x2A, 0x7E, 0xF7]), "full reply moved"
print("  the same status is raised when the destination fills mid-message,")
print("  and sub_FB28BE answers it with F0 50 2A 7E F7")
print()

# --- 4. the collector ceiling --------------------------------------------
# sub_FB6098: 0xFB610A `cp WA,0x00FF` / `jr nc` -> status 6; the F7 path at
# 0xFB612C appends without the test; sub_FB6165 sets the count to 1 on F0.
assert a(0xFB610A, 4) == bytes([0xD8, 0xCF, 0xFF, 0x00]), "collector bound moved"
assert a(0xFB611B, 3) == bytes([0x0B, 0x06, 0x00]), "collector status moved"
assert a(0xFB6192, 4) == bytes([0x8E, 0x08, 0x3F, 0xF0]), "F0 test moved"
assert a(0xFB619A, 4) == bytes([0xB1, 0x02, 0x01, 0x00]), "F0 no longer resets to 1"
LIMIT = le32(a(0xFB610A, 4)[2:4])
print("Longest message the receiver will store")
print("  the stored count starts at 1 on the F0 and a body byte is refused")
print("  once it reaches 0x%02X, so F0 + identifier + %d body bytes;" % (LIMIT, LIMIT - 2))
print("  the closing F7 is appended without the test -> %d bytes on the wire."
      % (LIMIT + 1))
print("  Over that: status 0x06 -> ERROR 41!")
print()

# --- 5. write protect ----------------------------------------------------
CLASS = {1: "bit 1 (COMBINATION)", 2: "bit 0 (SOUND)", 3: "either bit"}
assert a(0xFB6BAE, 6) == bytes([0xE8, 0xC8, 0x82, 0xFE, 0xF4, 0x00]), "class table moved"
assert a(0xFB6BE1, 3) == bytes([0x0B, 0x21, 0x00]), "protect status moved"
assert a(0xFB7E38, 5) == bytes([0xF1, 0x70, 0x20, 0x00, 0xB3]), "protect screen moved"
print("Write-protect gate -- prom_b 0xF4FE82 indexed by the command number")
OTHER = {0x0A: "continuation frame",
         0x0D: "(no accepted sequence)",
         0x17: "single-parameter write (2C)"}
for cmd in range(0x22):
    k = b(0xF4FE82 + cmd)[0]
    if k:
        name = TEMPLATES.get(cmd, (0, OTHER.get(cmd, "?")))[1]
        print("  cmd 0x%02X  %-26s refused on %s" % (cmd, name, CLASS[k]))
print("  NOTE the continuation frame is class 3, so a SEQUENCER transfer --")
print("  whose own headers are ungated -- still stops at its second frame")
print("  if either protect bit is set.")
print("  refusal = status 0x21 -> screen 0xB3, no popup, nothing written")
print()

# --- 6. ordering ---------------------------------------------------------
RXTAB, CONT, ENDCAT, ABORT = 0xF4F916, 0xF4F99E, 0xF4F9E6, 0xF4FA2E
assert a(0xFB28A1, 6) == bytes([0xE8, 0xC8, 0x16, 0xF9, 0xF4, 0x00]), "rx table moved"
assert a(0xFB2C88, 6) == bytes([0xE8, 0xC8, 0x9E, 0xF9, 0xF4, 0x00]), "cont table moved"
assert a(0xFB3055, 6) == bytes([0xE8, 0xC8, 0xE6, 0xF9, 0xF4, 0x00]), "endcat table moved"
assert a(0xFB3265, 6) == bytes([0xE8, 0xC8, 0x2E, 0xFA, 0xF4, 0x00]), "abort table moved"
assert a(0xFB2896, 3) == bytes([0xCE, 0xCF, 0x22]), "rx table bound moved"
for t in (CONT, ENDCAT, ABORT):
    # bound `cp H,0x12 / jr nc` at 0xFB2C7E, 0xFB304A, 0xFB325A
    pass
assert a(0xFB2C7E, 3) == bytes([0xC9, 0xCF, 0x12]), "step bound moved"
assert a(0xFB304A, 3) == bytes([0xCE, 0xCF, 0x12]), "step bound moved"
assert a(0xFB325A, 3) == bytes([0xCE, 0xCF, 0x12]), "step bound moved"
NSTEP = 0x12


def step_gate(entry):
    """The literal the handler compares parse-record field 3 against."""
    for off in range(0, 0x40):
        w = a(entry + off, 3)
        if w[0] == 0xC9 and 0xD8 <= w[1] <= 0xDF:      # cp a,imm3
            return w[1] - 0xD8, entry + off
        if w[0] == 0xC9 and w[1] == 0xCF:              # cp A,imm8
            return w[2], entry + off
    raise AssertionError("no step gate under 0x%06X" % entry)


def step_writes(entry):
    """The steps a continuation routine writes: `pushw N / pushw 3`."""
    out = []
    for off in range(0, 0x120):
        w = a(entry + off, 6)
        if w[0] == 0x0B and w[2] == 0x00 and w[3] == 0x0B and w[4] == 0x03 and w[5] == 0x00:
            out.append(w[1])
    return out


rows = []
for cmd, (tpl, name) in TEMPLATES.items():
    entry = le32(b(RXTAB + 4 * cmd, 4))
    need, site = step_gate(entry)
    rows.append((name, cmd, entry, need, site))

print("Order -- every data handler gates on the session step (field 3)")
print("  %-26s %-4s %-8s %s" % ("category", "cmd", "needs", "gate site"))
for name, cmd, entry, need, site in sorted(rows):
    print("  %-26s 0x%02X  step %-3s 0x%06X" % (name, cmd, "0x%02X" % need, site))
print("  A category may therefore only START from step 0, and its later parts")
print("  only after the earlier one has finished.  Out of order: ERROR 41!")
print()

print("Continuation table 0x%06X -- a `F0 50 7E ...` frame carries no address;"
      % CONT)
print("  the session step is what routes it")
ERRARM = 0xFB2C9A
for s in range(NSTEP):
    v = le32(b(CONT + 4 * s, 4))
    if v == ERRARM:
        print("  step 0x%02X -> refused (status 0x13 -> ERROR 41!)" % s)
    else:
        writes = step_writes(v)
        print("  step 0x%02X -> 0x%06X, writes step 0x%02X then 0x%02X on the last frame"
              % (s, v, writes[0], writes[1]) if len(writes) >= 2 else
              "  step 0x%02X -> 0x%06X" % (s, v))
print()

legal = [s for s in range(NSTEP) if le32(b(ENDCAT + 4 * s, 4)) != 0xFB306C]
assert a(0xFB306C, 3) == bytes([0x0B, 0x1E, 0x00]), "end-of-category error moved"
print("`end of category` (F0 50 27 7E F7) is legal at exactly %d steps: %s"
      % (len(legal), ", ".join("0x%02X" % s for s in legal)))
print("  anywhere else: status 0x1E -> ERROR 41!")
print("  each legal arm returns the step to 0 and sets one pending-apply bit")
print()

# end of dump: 0xFB30F7 clears the session flag and runs the five apply arms
assert a(0xFB3107, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xB4]), "end-of-dump moved"
assert a(0xFB2923, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x01]), "handshake moved"
assert a(0xFB296D, 4) == bytes([0xB9, 0x04, 0x00, 0x18]), "unsolicited-22 status moved"
assert b(0xF511C7 + 0x18) == bytes([0x20]), "status 0x18 no longer maps to ERROR 42"
assert a(0xFB3249, 4) == bytes([0xB9, 0x04, 0x00, 0x17]), "abort status moved"
assert b(0xF511C7 + 0x17) == bytes([0x21]), "status 0x17 no longer maps to ERROR 41"
print("Session control")
print("  F0 50 21 ... -> the instrument answers F0 50 22 04 00 11 F7")
print("  F0 50 22 ... accepted ONLY after that; otherwise status 0x18 -> ERROR 42!")
print("  acknowledgements are sent only once F0 50 22 ... has been accepted")
print("  F0 50 29 7E F7 (abort) -> status 0x17 -> ERROR 41!")
print("  F0 50 28 7E F7 (end of dump) -> leaves the session and APPLIES the")
print("  categories whose end-of-category arrived; nothing is applied before that")
print()

# --- 7. between messages -------------------------------------------------
# sub_FB7785: `ldw HL,0x09C4` (2500) or 0x03E8 (1000) if bit 2 of (0x60FD40)
assert a(0xFB778A, 3) == bytes([0x33, 0xC4, 0x09]), "receive timeout moved"
assert a(0xFB7794, 3) == bytes([0x33, 0xE8, 0x03]), "handshake timeout moved"
assert a(0xFB77A1, 3) == bytes([0x0B, 0x05, 0x00]), "timeout status moved"
assert a(0xFB776D, 3) == bytes([0x0B, 0x04, 0x00]), "uart-error status moved"
assert a(0xFB7764, 3) == bytes([0xCB, 0xCC, 0x2C]), "uart-error mask moved"
print("Between messages")
print("  the outgoing MIDI ring is drained, then the next message is awaited")
print("  for %d ticks (about 5 s); the serial error mask 0x%02X is polled every"
      % (le32(a(0xFB778A, 3)[1:3]), a(0xFB7764, 3)[2]))
print("  pass -> status 0x04, and the wait expiring -> status 0x05, both ERROR 41!")
print()

if "--order" in sys.argv:
    print("Full receive dispatch table 0x%06X (34 entries)" % RXTAB)
    for i in range(0x22):
        print("  cmd 0x%02X -> 0x%06X%s"
              % (i, le32(b(RXTAB + 4 * i, 4)),
                 "   " + TEMPLATES[i][1] if i in TEMPLATES else ""))

print("OK")
