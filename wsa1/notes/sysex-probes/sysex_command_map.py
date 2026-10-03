#!/usr/bin/env python3
"""Map every accepted SysEx sequence to WHAT THE INSTRUMENT DOES.

QUESTION THIS ANSWERS
    `sysex_grammar_dump.py` stops walking at depth 8 and so cannot show the
    deepest arms of the trie.  This script walks it to the bottom and then
    binds each internal command number to the behaviour its handler
    implements, by checking the handler tables and the ROM constants the
    handlers use.  It covers the three families the protocol reference did
    not explain -- the `25` message, `7E` as the third byte, and the
    `2D` subtree -- and the DUMP REQUEST.

WHERE THE SIGNAL IS  (all addresses are the ROMs' own)
  * grammar trie: root prom_b 0xF5115B, records [match][cmd][LE32 next],
    0xFF ends a node.  A node's 0xFF record carries the parser's
    DEPTH-SPECIFIC ERROR CODE, not a command -- the walk must break on it.
  * three 34-entry LE32 handler tables, each named by exactly one
    `add XWA,imm24` in prom_a:
      0xF4F800  (0xFB21AF) interrupt-side ring
      0xF4F888  (0xFB22AC) foreground ring
      0xF4F916  (0xFB28A1) SECOND-LEVEL table, used INSIDE the bulk-transfer
                session loop 0xFB2820 for every command it defaults to.
  * SEND-button menu row -> job code table prom_a 0xF99AE3.
  * transmit templates prom_b 0xF4FEB4..0xF4FF60 (see sysex_bulkdump_tx.py).

RUN
    python3 wsa1/notes/sysex-probes/sysex_command_map.py            # tables
    python3 wsa1/notes/sysex-probes/sysex_command_map.py --paths    # every sequence

PASS
    Every assert is silent and the script prints OK.  The headline facts:
      * the 0x2D subtree yields exactly 16 sequences / 8 command numbers,
        and their address+size septets equal the SEND-button templates';
      * `F0 50 25 lo hi F7` is TEMPO, value = lo | hi<<4, bounds 40..300,
        and the SAME two bounds and the same default 120 appear in the
        sequencer clock programmer;
      * `F0 50 2B 04 d 11 <area> 00 00 x x x F7` is a DUMP REQUEST: its four
        area bytes map to job codes that are exactly four of the five the
        SEND menu uses;
      * six command numbers have a handler and NO accepted sequence.
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
B_BASE, A_BASE = 0xF00000, 0xF80000
b = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
a = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
def rb(ad, n): return b[ad - B_BASE: ad - B_BASE + n]
def ra(ad, n): return a[ad - A_BASE: ad - A_BASE + n]
def le32(ad):  return int.from_bytes(rb(ad, 4), "little")

# --- load bases asserted, never assumed -------------------------------------
assert rb(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert ra(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
print("base check OK: prom_a @0x%06X, prom_b @0x%06X" % (A_BASE, B_BASE))

ROOT, NULLREC, NCMD = 0xF5115B, 0xF4FF61, 0x22
T_IRQ, T_FG, T_SESSION = 0xF4F800, 0xF4F888, 0xF4F916

def records(addr, limit=512):
    out = []
    for i in range(limit):
        r = rb(addr + 6 * i, 6)
        out.append((r[0], r[1], int.from_bytes(r[2:6], "little")))
        if r[0] == 0xFF:
            break
    return out

# --- full-depth walk --------------------------------------------------------
seqs = []           # (cmd, [bytes-after-the-id]) ; 0xFE means "any byte"
def walk(node, prefix, depth):
    assert depth < 24, "trie depth runaway at %s" % prefix
    for m, c, nx in records(node):
        if m == 0xFF:       # node terminator: m[1] is an ERROR code, not a command
            break
        p = prefix + [m]
        if c:
            seqs.append((c, p))
        elif nx != NULLREC:
            walk(nx, p, depth + 1)
for m, c, nx in records(ROOT, 15):
    if m == 0xFF:
        assert c == 0x07, "root terminator should carry status 0x07"
        break
    if c:
        seqs.append((c, [m]))
    elif nx != NULLREC:
        walk(nx, [m], 1)

def fmt(p):  return " ".join("**" if x == 0xFE else "%02X" % x for x in p)

if "--paths" in sys.argv:
    for c, p in seqs:
        print("F0 <50|7E> %-40s F7   => CMD 0x%02X" % (fmt(p), c))
    print("%d accepted sequences" % len(seqs))
    sys.exit(0)

# --- the handler tables tile, which is the last-entry test on 34 ------------
assert T_IRQ + 4 * NCMD == T_FG, "handler tables do not tile"

# --- 1. the 0x2D subtree ----------------------------------------------------
sub2d = [(c, p) for c, p in seqs if p[0] == 0x2D]
assert len(sub2d) == 16, "expected 16 sequences under 0x2D, got %d" % len(sub2d)
assert sorted({c for c, _ in sub2d}) == [0x0B, 0x0C, 0x0E, 0x12, 0x13, 0x14, 0x15, 0x16]

def septet(t):   return (t[0] << 14) | (t[1] << 7) | t[2]

# the SEND-button templates, from sysex_bulkdump_tx.py, as literal prom_b bytes
TEMPLATES = {          # template address -> menu category
    0xF4FEF8: "SYSTEM,PART & MIDI part 1",
    0xF4FF04: "SYSTEM,PART & MIDI part 2",
    0xF4FF1C: "SOUND",
    0xF4FF28: "SEQUENCER part 1",
    0xF4FF34: "SEQUENCER part 2",
    0xF4FF40: "SEQUENCER part 3",
    0xF4FF49: "COMBINATION part 1",
    0xF4FF55: "COMBINATION part 2",
}
tx = {}
for ad, name in TEMPLATES.items():
    t = rb(ad, 12)
    assert t[:4] == bytes([0xF0, 0x50, 0x2D, 0x04]) and t[5] == 0x11, name
    tx[name] = (tuple(t[6:9]), tuple(t[9:12]))      # (addr septets, size septets)

# every 0x2D sequence's septets must be one of those templates' -- and the
# ONE template whose size is computed at run time (SEQUENCER part 3) must be
# the ONE sequence the trie pins only 3 septets deep.
print("\n0x2D data headers accepted on the wire  (F0 50 2D 04 <00|01> 11 ...)")
print(" cmd | address septets | size septets | bytes | category")
seen = {}
for c, p in sorted(sub2d):
    if c in seen:
        continue
    seen[c] = p
    addr = tuple(p[4:7])
    size = tuple(p[7:10]) if len(p) >= 10 else None
    match = [n for n, (ta, ts) in tx.items() if ta == addr and (size is None or ts == size)]
    assert len(match) == 1, "septets %s match %r" % (addr, match)
    print("  %02X  |    %02X %02X %02X      |   %s   | %6s | %s" % (
        c, addr[0], addr[1], addr[2],
        ("%02X %02X %02X" % size) if size else "run-time",
        ("0x%X" % septet(size)) if size else "varies", match[0]))
assert seen[0x14] and len(seen[0x14]) == 7, "SEQUENCER part 3 should pin only the address"
assert all(len(p) == 10 for c, p in seen.items() if c != 0x14)

# --- 2. `25` = TEMPO --------------------------------------------------------
# receive:  prom_a 0xFB3453 `cp BC,0x0028` and 0xFB3459 `cp BC,0x012C`
# transmit: prom_a 0xFB33B2 `cp BC,0x0028` and 0xFB33C0 `cp BC,0x012C`
# clock:    prom_a 0xFAA357 `cp WA,0x0028`, 0xFAA35D `cp WA,0x012C`,
#           0xFAA368 `ldw WA,0x78` (the out-of-range default)
assert ra(0xFB3453, 4) == bytes([0xD9, 0xCF, 0x28, 0x00])
assert ra(0xFB3459, 4) == bytes([0xD9, 0xCF, 0x2C, 0x01])
assert ra(0xFB33B2, 4) == bytes([0xD9, 0xCF, 0x28, 0x00])
assert ra(0xFB33C0, 4) == bytes([0xD9, 0xCF, 0x2C, 0x01])
assert ra(0xFAA357, 4) == bytes([0xD8, 0xCF, 0x28, 0x00])
assert ra(0xFAA35D, 4) == bytes([0xD8, 0xCF, 0x2C, 0x01])
assert ra(0xFAA368, 3) == bytes([0x30, 0x78, 0x00])
# the transmit template is `F0 50 25` and the 3 bytes the sender prefills are
# the ROM's own encoding of the default tempo, terminator included.
assert rb(0xF4FEE3, 3) == bytes([0xF0, 0x50, 0x25])
seed = rb(0xF4FA76, 3)
assert seed[2] == 0xF7, "tempo seed should end the message"
assert (seed[0] | (seed[1] << 4)) == 120, "tempo seed should decode to 120"
assert [(c, p) for c, p in seqs if p == [0x25]] == [(0x09, [0x25])]
assert le32(T_IRQ + 4 * 0x09) == le32(T_FG + 4 * 0x09) == 0x00FB33FE
print("\n`25` = TEMPO: seed %02X %02X decodes to %d BPM; bounds 40..300 appear"
      "\n  in the receiver, the transmitter AND the sequencer clock programmer,"
      "\n  whose out-of-range default is %d." % (seed[0], seed[1],
      seed[0] | (seed[1] << 4), 0x78))

# --- 3. `7E` as the third byte = a data continuation frame ------------------
assert [(c, p) for c, p in seqs if p == [0x7E]] == [(0x0A, [0x7E])]
assert rb(0xF4FED2, 3) == bytes([0xF0, 0x50, 0x7E]), "continuation template"
assert le32(T_IRQ + 4 * 0x0A) == 0x00FB2820, "0x0A must enter the session loop"
assert le32(T_SESSION + 4 * 0x0A) == 0x00FB2C6C
# 0xFB2C6C bounds the transfer phase at 18 and indexes prom_b 0xF4F99E
assert ra(0xFB2C7E, 3) == bytes([0xC9, 0xCF, 0x12]), "phase bound cp A,0x12"
assert ra(0xFB2C88, 6) == bytes([0xE8, 0xC8, 0x9E, 0xF9, 0xF4, 0x00])

# --- 4. the DUMP REQUEST ----------------------------------------------------
# five arms at prom_a 0xFB5122..0xFB514A, each `ld (0x60F802),#job`
ARMS = {0x1B: 0xFB5122, 0x1C: 0xFB512C, 0x1D: 0xFB5136, 0x1E: 0xFB5140, 0x1F: 0xFB514A}
job = {}
for cmd, ad in ARMS.items():
    ins = ra(ad, 6)
    assert ins[:5] == bytes([0xF2, 0x02, 0xF8, 0x60, 0x00]), "arm 0x%02X" % cmd
    job[cmd] = ins[5]
    assert le32(T_IRQ + 4 * cmd) == le32(T_FG + 4 * cmd) == 0x00F00000 + (ad & 0xFFFFF) \
        or le32(T_IRQ + 4 * cmd) == ad
# the SEND menu's own row -> job table
MENU = ["TOTAL KEYBOARD", "SOUND", "COMBINATION", "SYSTEM,PART & MIDI", "SEQUENCER"]
menujobs = list(ra(0xF99AE3, 5))
row_of_job = {j: MENU[i] for i, j in enumerate(menujobs)}
print("\nDUMP REQUEST  (F0 50 2B 04 <00|01> 11 <area> 00 00 x x x F7)")
print(" area | cmd | job | the SEND-menu row that runs the same job")
found = {}
for c, p in seqs:
    if c in ARMS and p[0] == 0x2B:
        found.setdefault(c, p[4])
for c in sorted(found):
    assert job[c] in row_of_job, "job %d has no menu row" % job[c]
    print("  %02X  |  %02X | %2d  | %s" % (found[c], c, job[c], row_of_job[job[c]]))
assert set(found) == {0x1B, 0x1C, 0x1E, 0x1F}, "expected four reachable request arms"
# the requested area byte is the top septet of that category's dump address
for c, area in found.items():
    cat = row_of_job[job[c]]
    tpl = [n for n in tx if n.startswith(cat)]
    assert tpl, cat
    assert tx[sorted(tpl)[0]][0][0] == area, \
        "area %02X != dump address top septet for %s" % (area, cat)
# 0x1D is an arm with a job code that NO wire sequence can reach
assert 0x1D not in found, "0x1D should be unreachable"
# the gate: prom_a 0xFB516A requires screen 0x79, else it raises status 0x11
assert ra(0xFB516A, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79])
assert ra(0xFB5184, 3) == bytes([0x0B, 0x11, 0x00])
# and it reaches the SEND button's own dispatcher by setting bit 7 of the job
assert ra(0xFB5154, 5) == bytes([0xF2, 0x02, 0xF8, 0x60, 0xBF])   # set 7,(0x60F802)
assert ra(0xFB5165, 4) == bytes([0x1D, 0x49, 0x20, 0xFB])         # call 0xFB2049

# --- 5. commands with a handler but no accepted sequence --------------------
reach = {c for c, _ in seqs}
orphan = [i for i in range(1, NCMD) if i not in reach]
assert orphan == [0x06, 0x0D, 0x0F, 0x10, 0x11, 0x1D], orphan
print("\ncommand numbers with a handler but NO accepted wire sequence: %s"
      % " ".join("0x%02X" % i for i in orphan))

# --- 6. the interrupt ring and the foreground ring differ ONLY in the default
dflt_irq = {le32(T_IRQ + 4 * i) for i in range(NCMD)}
for i in range(NCMD):
    x, y = le32(T_IRQ + 4 * i), le32(T_FG + 4 * i)
    assert x == y or (x == 0x00FB2820 and y == 0x00FB22C8), "slot %02X" % i
print("the two ring tables differ only where the interrupt side runs the"
      "\n  bulk-transfer session loop and the foreground side does nothing.")

# --- 7. the received checksum is the transmitted one --------------------------
# prom_a 0xFB6E27 `add XIX,0x0F` (skip only the leading 0xF0), 0xFB6E53
# `res 7,H` (7-bit), 0xFB6E64 `pushw 0x14` (the checksum status)
assert ra(0xFB6E27, 6) == bytes([0xEC, 0xC8, 0x0F, 0x00, 0x00, 0x00])
assert ra(0xFB6E53, 3) == bytes([0xCE, 0x30, 0x07])
assert ra(0xFB6E64, 3) == bytes([0x0B, 0x14, 0x00])

# --- 8. the two ENABLE gates on the `25` message ----------------------------
# prom_a SysEx_FeatureWordForVariant (0xFB5FF5) picks one of two 6-word prom_b tables on the
# model-variant strap `(0x0000C4)` and the caller bails on 0xFFFF:
#   0xFB6000 `cp (0xC4),0x01` -> 0xF4FE6A when equal, else 0xF4FE76.
# Index 5 is the `25` message; index 3 is the SEQUENCER block store.
assert ra(0xFB6000, 4) == bytes([0xC0, 0xC4, 0x3F, 0x01])
assert ra(0xFB6006, 5) == bytes([0xF2, 0x6A, 0xFE, 0xF4, 0x34])
assert ra(0xFB600D, 5) == bytes([0xF2, 0x76, 0xFE, 0xF4, 0x34])
def w16(ad): return int.from_bytes(rb(ad, 2), "little")
allow  = [w16(0xF4FE6A + 2 * i) for i in range(6)]
deny   = [w16(0xF4FE76 + 2 * i) for i in range(6)]
assert allow == [0, 0, 0, 0, 0, 0], allow
assert deny  == [0, 0, 0, 0xFFFF, 0, 0xFFFF], deny
# the two callers that pass index 5 are the tempo receiver and transmitter,
# and the three that pass index 3 are the SEQUENCER part 1/2/3 data handlers.
for site in (0xFB3400, 0xFB336E):
    assert ra(site, 3) == bytes([0x0B, 0x05, 0x00]), "index 5 at 0x%06X" % site
for site in (0xFB2E33, 0xFB2E7C, 0xFB2EC5):
    assert ra(site, 3) == bytes([0x0B, 0x03, 0x00]), "index 3 at 0x%06X" % site
# ... and only the SEQUENCER ones gate the block store: the SYSTEM/PART&MIDI
# data handler calls it unconditionally.
assert ra(0xFB2E44, 4) == bytes([0x1D, 0xB5, 0x72, 0xFB])   # conditional call
assert ra(0xFB2CC0, 4) == bytes([0x1D, 0xB5, 0x72, 0xFB])   # unconditional call
print("\nmodel-variant strap (0xC4): value 1 allows all six gated functions;"
      "\n  any other value denies index 3 (SEQUENCER block store) and index 5"
      "\n  (the `25` tempo message), in BOTH directions.")

# the other two conditions on `25`, present identically in receiver and
# transmitter: the bulk-dump page must NOT be showing, one internal mode bit
# must be clear, and MIDI-filter byte (0x7F38) bit 3 must be SET.
for site in (0xFB340E, 0xFB3387):
    assert ra(site, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79])
for site in (0xFB3415, 0xFB338F):
    assert ra(site, 7) == bytes([0xC1, 0x32, 0x7F, 0x23, 0xCB, 0xCC, 0x04])
for site in (0xFB341E, 0xFB3398):
    assert ra(site, 7) == bytes([0xC1, 0x38, 0x7F, 0x23, 0xCB, 0xCC, 0x08])
# (0x7F38) is the LAST of the eight MIDI INPUT&OUTPUT FILTER rows: the row
# dispatcher prom_a JumpTable_F9AB84 has 8 entries and its last arm calls the
# editor that writes (0x7F38) with mask 0x0F, so "ON" sets bit 3.
assert le32(0) is not None
jt = [int.from_bytes(ra(0xF9AB84 + 4 * i, 4), "little") for i in range(8)]
assert jt[0] == 0x00F9ABA4 and jt[7] == 0x00F9ABE3, jt
assert ra(0xF9ABE7, 3) == bytes([0x1E, 0x2F, 0x03])          # calr 0xF9AF19
assert ra(0xF9AF2B, 3) == bytes([0x0B, 0x0F, 0x00])          # mask 0x0F
assert ra(0xF9AF2E, 4) == bytes([0xF1, 0x38, 0x7F, 0x31])    # lda XBC,0x7F38
assert ra(0xF9ACFB, 7) == bytes([0xC1, 0x38, 0x7F, 0x23, 0xCB, 0xCC, 0x0F])  # painter

# --- 9. `28` (end of dump) and `2A` (memory full) are the SAME command ------
pairs = {tuple(p): c for c, p in seqs if len(p) == 2 and p[1] == 0x7E}
assert pairs[(0x28, 0x7E)] == pairs[(0x2A, 0x7E)] == 0x04, pairs
assert pairs[(0x23, 0x7E)] == 0x01 and pairs[(0x24, 0x7E)] == 0x02
assert pairs[(0x27, 0x7E)] == 0x03 and pairs[(0x29, 0x7E)] == 0x05
print("`28` (end of dump) and `2A` (memory full) both decode to command 0x04,"
      "\n  so the instrument treats a peer's memory-full exactly as an end of dump.")

# --- 10. the receive handshake state machine --------------------------------
# (0x60FD44): 0 idle, 1 enquiry seen, 2 transfer started.  Only when it
# reaches 2 does bit 7 of (0x60FD40) go up, and sub_FB28BE sends NO reply
# until it is up.
assert ra(0xFB28FF, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x00])  # ==0 ?
assert ra(0xFB2907, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x01])  # :=1
assert ra(0xFB2923, 6) == bytes([0xC2, 0x44, 0xFD, 0x60, 0x3F, 0x01])  # ==1 ?
assert ra(0xFB295D, 6) == bytes([0xF2, 0x44, 0xFD, 0x60, 0x00, 0x02])  # :=2
assert ra(0xFB2958, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xBF])        # set 7
assert ra(0xFB28BF, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xCF])        # bit 7?
assert ra(0xFB296D, 4) == bytes([0xB9, 0x04, 0x00, 0x18])              # status 0x18
# the session loop only runs at all on the SYSEX BULK DUMP page, and only for
# command numbers >= 7
assert ra(0xFB2826, 5) == bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79])
assert ra(0xFB283C, 2) == bytes([0xC9, 0xDF])                          # cp A,0x07
print("receive handshake: enquiry -> start-transfer -> the instrument's"
      "\n  acknowledgements switch on; nothing is answered before that.")

# --- 11. the framing cap ----------------------------------------------------
# Both ring parsers run the same three-state framer.  State 0 wants 0xF0,
# state 1 accepts ONLY 0x50 or 0x7E (and then throws it away -- nothing
# re-compares it), state 2 stores data bytes while the stored count is below
# 0xFF.  The count is set to 1 by the 0xF0 itself and the closing 0xF7 is
# appended without the test, so a message holds at most 256 bytes end to end.
for base in (0xFB2104, 0xFB2201):            # state-0 arm of each parser
    assert ra(base, 3) == bytes([0xCE, 0xCF, 0xF0]), "0x%06X" % base
for base in (0xFB210E, 0xFB220B):            # state-1 arm: 0x50 or 0x7E
    assert ra(base, 3) == bytes([0xCE, 0xCF, 0x50]), "0x%06X" % base
    assert ra(base + 5, 3) == bytes([0xCE, 0xCF, 0x7E]), "0x%06X" % base
for base in (0xFB212B, 0xFB2228):            # state-2 arm: cp WA,0x00FF
    assert ra(base, 4) == bytes([0xD8, 0xCF, 0xFF, 0x00]), "0x%06X" % base
assert ra(0xFB6192, 4) == bytes([0x8E, 0x08, 0x3F, 0xF0])          # is it 0xF0?
assert ra(0xFB619A, 4) == bytes([0xB1, 0x02, 0x01, 0x00])          # count := 1
print("framing: F0, then 50 or 7E (accepted then DISCARDED -- the third byte"
      "\n  alone selects), then at most 255 more bytes; a longer message is"
      "\n  abandoned.  256 bytes end to end.")

print("\n%d accepted sequences, %d distinct command numbers" % (len(seqs), len(reach)))
print("OK")
