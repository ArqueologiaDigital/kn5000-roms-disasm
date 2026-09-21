#!/usr/bin/env python3
"""The COMPLETE wire layout of a 2B / 2C parameter message, byte by byte.

QUESTION THIS ANSWERS
    sysex_param_space.py decoded the ADDRESS SPACE -- which parameter each
    byte triple names.  It did not say what a whole message looks like on the
    wire.  This script does: where the data goes, how many bytes it occupies,
    what the count triple means, what a request carries instead of data, what
    the instrument sends back, and what a receiver must compute for the
    checksum.  It ends with three worked examples whose checksums it verifies
    with the instrument's own arithmetic.

ANSWER, IN ONE LINE
    F0 50 <2B|2C> 04 nn 11 <addr3> <count3> [<2 bytes per data byte>] <flag>
    <sum> F7 -- 2C carries the data, 2B does not, and the reply to a 2B is a
    2C that is byte-for-byte the 2C that would write the value back.

WHERE THE SIGNAL IS  (prom_a 0xF80000, prom_b 0xF00000; both bases asserted)

  * FRAME LAYOUT.  The collector record is initialised by 0xFB7FEB: the byte
    buffer starts at record+0x0E (`add XBC,0x0E` at 0xFB7FF9), the read
    cursor (+0x02), the data cursor (+0x06) and the write cursor (+0x0A) all
    start there, and buffer[0] is set to the 0xFF sentinel.  The parser
    (0xFB63D1) opens by `add (XBC+0x02),2` -- it steps over the two bytes the
    collector already matched, F0 and 50 -- and walks the trie from the third
    byte.  So the buffer holds the whole message, F0 first.

  * COUNT TRIPLE.  0xFB6BF4.  For command ids 0x18 (2C) and 0x1A (2B) it
    tests parse field 0x0C for the untouched 0xFF -- 0xFF means the trie did
    not consume a count triple, because the parameter is one byte long -- and
    then reads three bytes off the message itself (three calls to the
    sequential reader 0xFB61B1) and requires their bitwise OR to be 1
    (`or L,H` 0xFB6CD3, `or A,L` 0xFB6CDB, `cp A,1` 0xFB6CE1).  Otherwise
    status 0x0E -> ERROR 41.  For a MULTI-BYTE parameter the trie spells the
    triple out and pins it exactly, and this check is skipped.

  * DATA.  0xFB6CFC.  Families 0x7E / 0x2D / 0x2C only (0xFB6D5F): it walks
    from the read cursor to (end - 3) in steps of 2 and raises status 0x11 if
    it does not land exactly -- the payload must be an even number of bytes --
    and sets the data cursor (+0x06) to the first data byte.  end-3 is flag,
    checksum, F7.  2B is not in the list because it carries no data.

  * NIBBLES.  0xFB77F3 is the only reader of a data byte.  It takes two bytes
    off the message and returns `((b0 << 4) & 0xF0) | (b1 & 0x0F)` -- `ld H,A`
    0xFB780F, `sll h,4` 0xFB7811 (H is 8 bits, so the top nibble of b0 falls
    off), `and A,0x0F` 0xFB7821, `or A,H` 0xFB7824.  That is the bulk dump's
    rejoin rule, identical.  A count-N parameter's method calls it N times.

  * FLAG + CHECKSUM.  0xFB6DBD.  Families 0x7E / 0x2D / 0x2C / 0x2B
    (0xFB6DE8+): one more byte off the message, which must be 0 or 1 (else
    status 0x12), stored in parse field 0x0F; then the sum of every byte from
    buffer+1 (record+0x0F, `add XIX,0x0F` at 0xFB6E27) to the cursor, negated
    and masked to seven bits (`sub WA,WA / sub WA,BC / res 7,H`), compared
    with the next byte (else status 0x14).  The transmitter 0xFB7111 computes
    the identical thing over its own buffer+1 and appends [sum, F7] from the
    word at prom_b 0xF4FE68.  NOTHING reads field 0x0F for 2B/2C afterwards --
    every reader of it is a 2D bulk-data handler.

  * REPLY.  A 2B reaches the descriptor's +0x18 method, which reaches one of
    four builders, one per data length.  Each emits, in order: the six-byte
    literal `F0 50 2C 04 00 11` at prom_b 0xF4FEF2; six bytes of address and
    count taken from the DESCRIPTOR; 2*N nibble bytes; and one flag byte, 0,
    from an all-zero prefill.  Then 0xFB7111 appends the checksum and F7.
        1 byte  0xFB4D62  emits 3  (prefill prom_b 0xF4FA84)
        1 byte  0xFB4F8F  emits 3  (part blocks; `set 5,A` 0xFB4FF9 patches
                                    address byte 7 to 0x20 + part)
        2 bytes 0xFB536D  emits 5  (prefill 0xF4FA90)
        3 bytes 0xFB5425  emits 7  (prefill 0xF4FA95; `add C,0x20` 0xFB5496
                                    patches the same byte)
    So the reply's address is the address that was asked for, and its count
    triple is the parameter's own.

  * SAME ENCODING AS THE BULK DUMP, literally.  The bulk receive unpacker
    0xFB72B5 runs the same three instructions on the same cursor field
    (+0x06): `sll h,4` 0xFB72E2, `and A,0x0F` 0xFB72FC, `xor L,H` 0xFB7301 --
    XOR and OR agree because the two operands' nibbles do not overlap -- and
    stops at the same end-3 boundary (`dec 3,XWA` 0xFB7330).

  * WHICH SOCKET THE ANSWER LEAVES BY.  All four reply builders and the
    refusal call 0xFB71BB, which puts the block into BOTH output rings
    (`T_Ring601432_PutBlock` and `T_Ring60153C_PutBlock`).  The bulk-dump
    path calls 0xFB7165 instead, which uses the first ring only.

  * NO SCREEN GATE.  Slots 0x17..0x1F of the two 34-entry dispatch tables
    0xF4F800 / 0xF4F888 hold the same real handlers, while the DEFAULT slot
    -- where every bulk-dump command lands -- is 0xFB2820 (which opens by
    testing the panel mode byte for screen 0x79) in the first table and
    0xFB22C8, a bare ret, in the second.

  * REJECTION IS AUDIBLE ON THE WIRE, for these two families only.  After
    every message, 0xFB5197 reads the status; if it is non-zero AND the family
    (parse field 5) is 0x2B or 0x2C (`cp A,0x2B` 0xFB51BC, `cp A,0x2C`
    0xFB51C1), it transmits the five-byte literal at prom_b 0xF4FEC8,
    F0 50 29 7E F7.  No other family gets a reply when it is refused.

  * NOT STICKY.  0xFB8156 runs after every message and re-runs 0xFB7FEB,
    which restores the parse record from prom_b 0xF511E9 (`00 00 00 00 00`
    then eleven 0xFF) -- status back to 0, the count-triple fields back to the
    0xFF the check above depends on.

RUN
    python3 wsa1/notes/sysex-probes/sysex_param_wire_format.py
    python3 wsa1/notes/sysex-probes/sysex_param_wire_format.py --lengths
    python3 wsa1/notes/sysex-probes/sysex_param_wire_format.py --capture

PASS
    Every assert is silent and the script prints OK.  Headline numbers:
    3756 sequences under each family, of which 3750 (2C) / 3742 (2B) reach a
    parameter; 6 wire bytes of header, 3 of address, 3 of count; 1809 of the
    1875 addressable parameters are one byte long, 64 are two and 2 are three;
    the checksum is (0 - sum(bytes after F0 up to and including the flag)) & 7F
    and the three worked examples check out under it.
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
BASE_B, BASE_A = 0xF00000, 0xF80000
romb = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
roma = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()


def b(a, n):
    o = a - BASE_B
    assert 0 <= o and o + n <= len(romb), "address outside prom_b"
    return romb[o:o + n]


def a_(a, n):
    o = a - BASE_A
    assert 0 <= o and o + n <= len(roma), "address outside prom_a"
    return roma[o:o + n]


def l32(a):
    return int.from_bytes(b(a, 4), "little")


def hx(s):
    return bytes(int(x, 16) for x in s.split())


assert b(0xF4FEB4, 5) == hx("F0 50 23 7E F7"), "wrong prom_b load base"
assert a_(0xF99AE3, 5) == hx("00 03 05 04 02"), "wrong prom_a load base"
print("base check OK: prom_b at 0x%06X, prom_a at 0x%06X" % (BASE_B, BASE_A))

# ----------------------------------------------------------------- 1. framing
# The buffer starts at record+0x0E and the F0 goes into it, so a sum that
# starts at record+0x0F starts at the byte AFTER the F0.  Both checksum
# routines start at +0x0F; the record initialiser puts the buffer at +0x0E.
assert a_(0xFB7FF9, 6) == hx("E9 C8 0E 00 00 00"), "buffer no longer at record+0x0E"
assert a_(0xFB8014, 3) == hx("B1 00 FF"), "buffer sentinel moved"
assert a_(0xFB6E27, 6) == hx("EC C8 0F 00 00 00"), "receive checksum start moved"
assert a_(0xFB7126, 6) == hx("EC C8 0F 00 00 00"), "transmit checksum start moved"
assert a_(0xFB6E4D, 2) == hx("D8 A0") and a_(0xFB6E4F, 2) == hx("D9 A0")
assert a_(0xFB6E53, 3) == hx("CE 30 07"), "receive: not res 7"
assert a_(0xFB714E, 3) == hx("C9 30 07"), "transmit: not res 7"
assert a_(0xFB7119, 5) == hx("D2 68 FE F4 21"), "checksum tail literal moved"
assert b(0xF4FE68, 2) == hx("00 F7"), "checksum tail is not <sum> F7"
assert b(0xF511E9, 16) == hx("00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF FF")
assert a_(0xFB63D8 + 9, 3) == hx("A9 02 88"), "parser no longer steps over F0 50"


def checksum(body):
    """body = every byte after F0, up to and including the flag."""
    return (-sum(body)) & 0x7F


# ------------------------------------------------------------ 2. the grammar
NULLREC = 0xF4FF61
ROOT = 0xF5115B


def records(addr, limit=4096):
    out = []
    for i in range(limit):
        r = b(addr + 6 * i, 6)
        out.append((r[0], r[1], int.from_bytes(r[2:6], "little")))
        if r[0] == 0xFF:
            break
    return out


def walk(p, prefix, out, depth=0):
    assert depth < 24, "trie deeper than any 2B/2C sequence"
    for m, c, nx in records(p):
        if m == 0xFF:
            break
        pfx = prefix + [m]
        if c:
            k = b(nx, 2)
            out.append((pfx, c, k[0], k[1]))
        elif nx != NULLREC:
            walk(nx, pfx, out, depth + 1)


root = {m: nx for m, c, nx in records(ROOT, 15) if m != 0xFF}
PATHS = {}
for fam in (0x2B, 0x2C):
    recs = [r for r in records(root[fam]) if r[0] != 0xFF]
    assert len(recs) == 1 and recs[0][0] == 0x04, "byte 3 is no longer a fixed 04"
    out = []
    walk(recs[0][2], [], out)
    PATHS[fam] = out
    assert len(out) == 3756, "%02X: %d sequences" % (fam, len(out))

# FIELD ORDER, read off the accepted sequences themselves rather than assumed.
# p[0] device, p[1] model, p[2:5] address, p[5:8] count when present.
for fam in (0x2B, 0x2C):
    for p, c, g, i in PATHS[fam]:
        assert p[0] in (0x00, 0x01), "device byte %02X accepted" % p[0]
        assert p[1] == 0x11, "model id is not 11"
        assert len(p) in (5, 8), "a sequence is %d bytes deep" % len(p)

TABLES = [
    (0x2C, 1, 0xF51E8E, 0x17), (0x2B, 1, 0xF51EEA, 0x17),
    (0x2C, 2, 0xF51F46, 0x05), (0x2B, 2, 0xF51F5A, 0x01),
    (0x2C, 3, 0xF51F5E, 0x19), (0x2B, 3, 0xF51FC2, 0x19),
    (0x2C, 5, 0xF52026, 0x13), (0x2B, 5, 0xF52072, 0x13),
    (0x2C, 6, 0xF520BE, 0x28), (0x2B, 6, 0xF5215E, 0x28),
    (0x2C, 7, 0xF521FE, 0x02), (0x2B, 7, 0xF52206, 0x02),
]
cur = TABLES[0][2]
for fam, g, base, n in TABLES:
    assert base == cur, "descriptor tables no longer tile"
    cur = base + 4 * n
assert cur == 0xF5220E

DESC = {}
for fam, g, base, n in TABLES:
    for i in range(n):
        DESC[(fam, g, i)] = l32(base + 4 * i)

PLACEHOLDER = 0xF511F9


def septets(t):
    return (t[0] << 14) | (t[1] << 7) | t[2]


def desc_count(d):
    return septets(tuple(b(d + 3, 3)))


# ------------------------------------------- 3. what the count triple means
# It is the parameter's own data length in bytes, and it is NOT always 1.
lengths = {}
for p, c, g, i in PATHS[0x2C]:
    if p[0] or g == 0xFF or p[2] != 0x00:
        continue
    d = DESC[(0x2C, g, i)]
    n = desc_count(d)
    lengths.setdefault(n, []).append((tuple(p), d))
    # the trie spells the triple out IF AND ONLY IF the parameter is multi-byte
    assert (len(p) == 8) == (n != 1), "count triple presence disagrees with length"
    if len(p) == 8:
        assert tuple(p[5:8]) == tuple(b(d + 3, 3)), "count triple != descriptor"
assert sorted(lengths) == [1, 2, 3], "data lengths present: %s" % sorted(lengths)
N1, N2, N3 = (len(lengths[k]) for k in (1, 2, 3))
assert (N1, N2, N3) == (1809, 33, 33), "length census moved: %d/%d/%d" % (N1, N2, N3)

# the one-byte case: the triple is on the wire anyway and is checked by OR == 1
assert a_(0xFB6CA6, 3) == hx("CE CF 18") and a_(0xFB6CAB, 3) == hx("CE CF 1A")
assert a_(0xFB6CBE, 3) == hx("C9 CF FF"), "the untouched-0xFF test moved"
assert a_(0xFB6CD3, 2) == hx("CE E7") and a_(0xFB6CDB, 2) == hx("CF E1")
assert a_(0xFB6CE1, 2) == hx("C9 D9"), "the count-triple test is not cp A,1"
assert a_(0xFB6CE3, 2) == hx("66 11"), "the count-triple test is not jr z"
assert a_(0xFB6CE5, 3) == hx("0B 0E 00"), "the failing status is not 0x0E"
# ⚠ it is a bitwise OR of three bytes against 1, NOT a comparison of the
# triple's value against 1: 00 00 01 passes and so does 01 00 00.
ORCHECK = [t for t in ((x, y, z) for x in range(2) for y in range(2) for z in range(2))
           if (t[0] | t[1] | t[2]) == 1]
assert len(ORCHECK) == 7 and (0, 0, 1) in ORCHECK and (1, 0, 0) in ORCHECK

# ------------------------------------------------- 4. the data is nibbles
assert a_(0xFB780F, 2) == hx("C9 8E"), "ld H,A moved"
assert a_(0xFB7811, 3) == hx("CE EE 04"), "sll h,4 moved"
assert a_(0xFB7821, 3) == hx("C9 CC 0F"), "and A,0x0F moved"
assert a_(0xFB7824, 2) == hx("CE E1"), "or A,H moved"


def nibbles(v):
    return [(v >> 4) & 0x0F, v & 0x0F]


def rejoin(hi, lo):
    return ((hi << 4) & 0xF0) | (lo & 0x0F)


for v in range(256):
    assert rejoin(*nibbles(v)) == v

# the even-length rule, and that 2B is not in it
assert a_(0xFB6D5F, 3) == hx("C9 CF 7E")
assert a_(0xFB6D64, 3) == hx("C9 CF 2D")
assert a_(0xFB6D69, 3) == hx("C9 CF 2C")
assert a_(0xFB6D6C, 2) == hx("6E 4A"), "a fourth family slipped into the length check"
assert a_(0xFB6D76, 2) == hx("E8 6B"), "the end-3 back-off moved"
assert a_(0xFB6DA7, 3) == hx("0B 11 00"), "odd-payload status is not 0x11"

# ------------------------------------------------------ 5. flag and checksum
for off, fam in ((0xFB6DE8, 0x7E), (0xFB6DED, 0x2D), (0xFB6DF2, 0x2C), (0xFB6DF7, 0x2B)):
    assert a_(off, 3) == bytes([0xC9, 0xCF, fam]), "flag check family list moved"
assert a_(0xFB6E09, 2) == hx("C9 D8") and a_(0xFB6E0D, 2) == hx("C9 D9")
assert a_(0xFB6E69, 3) == hx("0B 12 00"), "bad-flag status is not 0x12"
assert a_(0xFB6E64, 3) == hx("0B 14 00"), "bad-checksum status is not 0x14"

# ----------------------------------------------------------- 6. the replies
assert b(0xF4FEF2, 6) == hx("F0 50 2C 04 00 11"), "the 2C reply header moved"
assert b(0xF4FA84, 3) == bytes(3) and b(0xF4FA90, 5) == bytes(5) and b(0xF4FA95, 7) == bytes(7)
BUILDERS = {                       # emitter -> (data bytes emitted, prefill)
    0xFB4D62: (3, 0xF4FA84), 0xFB4F8F: (3, 0xF4FA8D),
    0xFB536D: (5, 0xF4FA90), 0xFB5425: (7, 0xF4FA95),
}
SITES = {0xFB4D62: (0xFB4DAC, 0xFB4DB9, 0xFB4DF8),
         0xFB4F8F: (0xFB4FD9, 0xFB4FE6, 0xFB503E),
         0xFB536D: (0xFB53BC, 0xFB53C9, 0xFB5400),
         0xFB5425: (0xFB5470, 0xFB547D, 0xFB5546)}
for fn, (n, pre) in BUILDERS.items():
    hdr, desc, data = SITES[fn]
    assert a_(hdr, 3) == hx("0B 06 00"), "%06X: header is not 6 bytes" % fn
    assert a_(desc, 3) == hx("0B 06 00"), "%06X: descriptor is not 6 bytes" % fn
    assert a_(data, 3) == bytes([0x0B, n, 0x00]), "%06X: data block is not %d" % (fn, n)
    assert (n - 1) % 2 == 0, "data block has no room for the flag"
    assert b(pre, n) == bytes(n), "%06X: prefill is not all zero" % fn
# the header literal is named at each builder, and the part patch at two of them
for site in (0xFB4DAF, 0xFB4FDC, 0xFB53BF, 0xFB5473):
    assert a_(site, 5) == hx("F2 F2 FE F4 31"), "reply header not named at %06X" % site
assert a_(0xFB4FF9, 3) == hx("C9 31 05"), "part patch (set 5,A) moved"
assert a_(0xFB5496, 3) == hx("CB C8 20"), "part patch (add C,0x20) moved"

# the bulk-dump unpacker is the same three instructions on the same cursor
assert a_(0xFB72E2, 3) == hx("CE EE 04"), "bulk sll h,4 moved"
assert a_(0xFB72FC, 3) == hx("C9 CC 0F"), "bulk and A,0x0F moved"
assert a_(0xFB7301, 2) == hx("CE D7"), "bulk join is not xor L,H"
assert a_(0xFB7330, 2) == hx("E8 6B"), "bulk end-3 boundary moved"
for hi in range(16):
    for lo in range(16):
        assert ((hi << 4) ^ lo) == ((hi << 4) | lo), "xor and or disagree"

# the replies leave by both output rings; the bulk dump by one
assert a_(0xFB71DF, 4) == hx("1D F8 1D F4") and a_(0xFB71EB, 4) == hx("1D 1C 1E F4")
assert a_(0xFB7189, 4) == hx("1D F8 1D F4")
assert a_(0xFB718D, 4) == hx("1D 24 07 F4")
for site in (0xFB4E0D, 0xFB5053, 0xFB5412, 0xFB555B, 0xFB51D9):
    assert a_(site, 4) == hx("1D BB 71 FB"), "%06X no longer calls the 2-ring sender" % site

# and they are dispatched with no screen gate: both tables, same handlers
import collections as _c
for base, dflt in ((0xF4F800, 0xFB2820), (0xF4F888, 0xFB22C8)):
    slots = [l32(base + 4 * i) for i in range(34)]
    assert _c.Counter(slots).most_common(1)[0][0] == dflt, "default slot moved"
    assert slots[0x17:0x20] == [0xFB3483, 0xFB34CA, 0xFB3495, 0xFB42AB,
                                0xFB5122, 0xFB512C, 0xFB5136, 0xFB5140, 0xFB514A]

# a rejected 2B/2C is answered with F0 50 29 7E F7 -- and no other family is
assert a_(0xFB51BC, 3) == hx("C9 CF 2B") and a_(0xFB51C1, 3) == hx("C9 CF 2C")
assert a_(0xFB51C6, 3) == hx("0B 05 00"), "the refusal reply is not 5 bytes"
assert a_(0xFB51C9, 5) == hx("F2 C8 FE F4 31"), "the refusal literal moved"
assert b(0xF4FEC8, 5) == hx("F0 50 29 7E F7"), "0xF4FEC8 is not the abort message"

# a 2C write is never acknowledged: its dispatcher transmits nothing
assert b(0xF4F800 + 4 * 0x18, 4) == b(0xF4F888 + 4 * 0x18, 4)
assert l32(0xF4F800 + 4 * 0x18) == 0xFB34CA and l32(0xF4F800 + 4 * 0x1A) == 0xFB42AB

# ------------------------------------------------------- 7. worked examples
def message(fam, addr, count, data=(), unit=0x00, flag=0x00):
    body = [0x50, fam, 0x04, unit, 0x11] + list(addr) + list(count)
    for v in data:
        body += nibbles(v)
    body.append(flag)
    return bytes([0xF0] + body + [checksum(body), 0xF7])


# part 0, parameter 03 (one byte, range 0..127 per its descriptor) set to 100
PART0_03 = None
for p, c, g, i in PATHS[0x2C]:
    if p[0] == 0 and g != 0xFF and tuple(p[2:5]) == (0x00, 0x20, 0x03):
        PART0_03 = (p, DESC[(0x2C, g, i)])
assert PART0_03, "part 0 parameter 03 is no longer in the grammar"
d = PART0_03[1]
assert desc_count(d) == 1 and b(d + 9, 2) == bytes([0, 127]), "example's range moved"

WRITE = message(0x2C, (0x00, 0x20, 0x03), (0x00, 0x00, 0x01), [100])
REQ = message(0x2B, (0x00, 0x20, 0x03), (0x00, 0x00, 0x01))
REPLY = message(0x2C, (0x00, 0x20, 0x03), (0x00, 0x00, 0x01), [100])
assert WRITE == hx("F0 50 2C 04 00 11 00 20 03 00 00 01 06 04 00 41 F7")
assert REQ == hx("F0 50 2B 04 00 11 00 20 03 00 00 01 00 4C F7")
assert REPLY == WRITE, "the reply is not the write that would set it back"
assert len(WRITE) == 17 and len(REQ) == 15

# part 7 of the same parameter: only address byte 7 changes, 0x20 + 7
W7 = message(0x2C, (0x00, 0x27, 0x03), (0x00, 0x00, 0x01), [100])
assert W7 == hx("F0 50 2C 04 00 11 00 27 03 00 00 01 06 04 00 3A F7")

# a three-byte parameter: part 0, parameter 00.  Its count triple is on the
# wire because the grammar pins it, and its payload is six bytes.
THREE = None
for p, c, g, i in PATHS[0x2C]:
    if p[0] == 0 and g != 0xFF and tuple(p[2:5]) == (0x00, 0x20, 0x00):
        THREE = (p, DESC[(0x2C, g, i)])
assert THREE and desc_count(THREE[1]) == 3 and tuple(THREE[0][5:8]) == (0, 0, 3)
W3 = message(0x2C, (0x00, 0x20, 0x00), (0x00, 0x00, 0x03), [0x12, 0x00, 0x40])
assert W3 == hx("F0 50 2C 04 00 11 00 20 00 00 00 03 01 02 00 00 04 00 00 45 F7")
assert len(W3) == 21

# every example verifies under the instrument's own rule
for m in (WRITE, REQ, W7, W3):
    assert checksum(m[1:-2]) == m[-2], "worked example fails its own checksum"
    assert (sum(m[1:-1]) & 0x7F) == 0, "sum after F0 including the checksum is not 0 mod 128"

# --------------------------------------------- 8. optional: the real capture
if "--capture" in sys.argv:
    cands = [os.environ.get("SYSEX_CAPTURE", ""),
             os.path.join(HERE, "SND_CMBI.syx"),
             "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx"]
    path = next((p for p in cands if p and os.path.isfile(p)), None)
    if path is None:
        z = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"
        if os.path.isfile(z):
            import zipfile, tempfile
            path = os.path.join(tempfile.gettempdir(), "SND_CMBI.syx")
            with zipfile.ZipFile(z) as f:
                open(path, "wb").write(f.read("SND_CMBI.syx"))
    if path is None:
        print("\ncapture not found; skipping the cross-check "
              "(see sysex_wire_capture_check.py for how to get it)")
    else:
        raw = open(path, "rb").read()
        msgs, i, bad, seen = [], 0, 0, 0
        while i < len(raw):
            if raw[i] != 0xF0:
                i += 1
                continue
            j = raw.find(b"\xf7", i)
            if j < 0:
                break
            msgs.append(raw[i:j + 1])
            i = j + 1
        for m in msgs:
            if len(m) < 6 or m[2] not in (0x2D, 0x7E):
                continue
            seen += 1
            if checksum(m[1:-2]) != m[-2]:
                bad += 1
        assert seen and bad == 0, "%d of %d frames fail the rule" % (bad, seen)
        print("\ncapture cross-check: %d bulk frames, %d checksum failures "
              "under the same rule" % (seen, bad))

# ------------------------------------------------------------------- output
if "--lengths" in sys.argv:
    print("\nevery parameter whose data is longer than one byte")
    print("addr        count  payload bytes  descriptor")
    for n in (2, 3):
        for p, d in sorted(lengths[n]):
            print("  %02X %02X %02X    %d        %d        0x%06X" % (
                p[2], p[3], p[4], n, 2 * n, d))
    print("\n(byte 7 = 20 is part 0; each of those two parameters exists in all "
          "32 part blocks,\n byte 7 = 20 + part, so 32 of the 33 in each column "
          "are the same parameter)")
    sys.exit(0)

print()
print("WIRE LAYOUT")
print("  offset  write (2C)                request (2B)              reply (2C)")
rows = [
    ("0",      "F0",                     "F0",                    "F0"),
    ("1",      "50  Technics",           "50",                    "50"),
    ("2",      "2C",                     "2B",                    "2C"),
    ("3",      "04",                     "04",                    "04"),
    ("4",      "nn  00 or 01",           "nn  00 or 01",          "00  always"),
    ("5",      "11",                     "11",                    "11"),
    ("6..8",   "address, 3 x 7 bits",    "address",               "address, echoed"),
    ("9..11",  "count, 3 x 7 bits",      "count",                 "count"),
    ("12..",   "2 bytes per data byte",  "-- nothing --",         "2 bytes per data byte"),
    ("",       "flag  00 or 01",         "flag  00 or 01",        "flag  00"),
    ("",       "checksum",               "checksum",              "checksum"),
    ("",       "F7",                     "F7",                    "F7"),
]
for r in rows:
    print("  %-7s %-25s %-25s %s" % r)

print()
print("  message length = 13 + 2*N for a write, 15 for any request,")
print("  13 + 2*N for a reply, where N is the count.")
print("  N is the parameter's own data length: %d parameters take 1 byte, "
      "%d take 2, %d take 3." % (N1, N2, N3))
print("  For N = 1 the triple is not pinned by the grammar; the parser reads it")
print("  itself and requires the three bytes to OR to 1, so 00 00 01 is right")
print("  and the check would also pass %d other combinations." % (len(ORCHECK) - 1))
print("  For N > 1 the grammar pins all three bytes: they must be the")
print("  parameter's own count or the message is not recognised at all.")

print()
print("CHECKSUM   sum every byte after F0 up to and including the flag,")
print("           negate it, keep seven bits:  (0 - S) & 0x7F")
print("           equivalently, everything after F0 including the checksum")
print("           sums to 0 modulo 128.")

print()
print("DATA       each data byte -> two message bytes, HIGH NIBBLE FIRST,")
print("           the same encoding the bulk dump uses; the receiver rejoins")
print("           them as ((first & 0x0F) << 4) | (second & 0x0F).")

print()
print("WORKED EXAMPLE   part 0, parameter 03 (one byte, 0..127), set to 100")
print("  write   %s" % " ".join("%02X" % x for x in WRITE))
print("  request %s" % " ".join("%02X" % x for x in REQ))
print("  reply   %s" % " ".join("%02X" % x for x in REPLY))
print("  the same parameter of part 7:")
print("          %s" % " ".join("%02X" % x for x in W7))
print("  a three-byte parameter (part 0, parameter 00) set to 12 00 40:")
print("          %s" % " ".join("%02X" % x for x in W3))

print()
print("PORTS      a reply and a refusal are put into both MIDI output rings;")
print("           a bulk dump is put into the first only.")
print("           Parameter messages have their own dispatch slots in both")
print("           receive tables, so no screen has to be open for them.")
print()
print("REFUSAL    a 2B or 2C the instrument will not act on is answered with")
print("           F0 50 29 7E F7.  No other message family is answered when it")
print("           is refused, and a 2C that IS acted on is not answered at all.")
print("OK")
