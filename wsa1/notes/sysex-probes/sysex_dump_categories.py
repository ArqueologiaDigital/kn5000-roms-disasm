#!/usr/bin/env python3
"""WHICH bulk-dump category emits WHICH data header, and what the header's
address field means.

QUESTION THIS ANSWERS
    The nine literal `F0 50 2D 04 00 11 <addr> <size>` templates in prom_b are
    easy to list.  Which of the five SYSEX BULK DUMP menu rows actually sends
    each one, in what order, and does the 21-bit address in the header
    correspond to anything inside the instrument?

WHAT IT ESTABLISHES, AND HOW
  1. TRANSMIT CALL GRAPH, decoded from prom_a instruction bytes, not assumed:
     menu row -> job code -> job routine -> category routine -> part emitters.
     Every edge is a `calr` (0x1E disp16) or `call` (0x1D imm24) whose target
     this script computes from the bytes.
  2. Each part emitter names exactly ONE template (`lda xbc,(imm24)` = F2 lo mi
     hi 31 pointing into 0xF4FEF2..0xF4FF60) and ONE descriptor writer, and
     pushes ONE step id.  The script asserts the counts, so a mis-scan cannot
     pass.
  3. The header's SIZE septets equal the descriptor writer's own byte extent
     times the block count -- and the ADDRESS septets of consecutive parts of
     one category differ by exactly the previous part's size.
  4. ADDRESS != INTERNAL ADDRESS.  The script prints the source extent each
     part is read from beside the dump address it is labelled with.  The two
     disagree for every single part, and for SOUND/COMBINATION the source is
     not even on this CPU: it is fetched over the inter-processor link from
     CPU 2's flash (0xE80000 / 0xEC0000).  ★ The clincher is that SOUND and
     COMBINATION are ADJACENT in the flash (0xE80000+0x40000 == 0xEC0000) and
     0x0C0000 apart in the dump address space.  No affine map fits.
  5. RECEIVE SIDE.  The grammar trie accepts the address+size pair as a
     LITERAL byte string -- there is no arithmetic decode of it anywhere --
     and the set it accepts is exactly the set the transmitter sends, minus
     the one orphan template.  Each accepted string yields a command number
     whose handler calls the SAME descriptor writer as the transmit side.
     That is what makes "the address is a fixed block identifier" a decode
     and not an opinion.
  6. The one run-time quantity: SEQUENCER part 3's size.  The transmit
     encoder splits a 32-bit count into septets `>>14, >>7, >>0` masked to 7
     bits; the receive decoder rebuilds it with `<<14, <<7, <<0`.  Both shift
     literals are asserted from the instruction stream.  That is the only
     place the firmware treats these fields as a NUMBER, and it is the size,
     never the address.

RUN
    python3 wsa1/notes/sysex-probes/sysex_dump_categories.py
    python3 wsa1/notes/sysex-probes/sysex_dump_categories.py --wire

PASS
    Every assert is silent and the script prints OK.
"""
import argparse
import os
import sys

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


# Load bases asserted, never assumed.
assert b(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base wrong"
assert a(0xF99AE3, 5) == bytes([0, 3, 5, 4, 2]), "prom_a base wrong"


# --------------------------------------------------------- tiny decoders
def calr(addr):
    """`calr disp16` = 1E lo hi, PC-relative to the END of the instruction."""
    op = a(addr, 3)
    assert op[0] == 0x1E, (hex(addr), op.hex())
    d = int.from_bytes(op[1:3], "little", signed=True)
    return addr + 3 + d


def call24(addr):
    """`call imm24` = 1D lo mi hi."""
    op = a(addr, 4)
    assert op[0] == 0x1D, (hex(addr), op.hex())
    return int.from_bytes(op[1:4], "little")


def calr_chain(addr, n):
    out = []
    for _ in range(n):
        out.append(calr(addr))
        addr += 3
    assert a(addr, 1) == b"\x0e", ("chain does not end in RET", hex(addr))
    return out


def septets(t):
    return (t[0] << 14) | (t[1] << 7) | t[2]


# ------------------------------------------- 1. menu row -> job -> routine
ROW_NAMES = ["TOTAL KEYBOARD", "SOUND", "COMBINATION",
             "SYSTEM,PART & MIDI", "SEQUENCER"]
ROW_TO_JOB = list(a(0xF99AE3, 5))

JUMP = [int.from_bytes(a(0xFB2081 + 4 * i, 4), "little") for i in range(6)]
# last-entry test: the table tiles exactly up to the code it dispatches to
assert 0xFB2081 + 6 * 4 == JUMP[0]
JOB_ROUTINE = {i: call24(arm) for i, arm in enumerate(JUMP)}
assert a(0xFB22E6, 1) == b"\x0e", "job 1 is a bare RET"

# ------------------------------- 2. job routine -> category routine (calr)
# Each of the five real job routines is:
#   [optional set flag] lda xbc,(0x60FCE8) / push / call <whole-extent writer>
#   / calr <category routine> / ... / ret
def job_body(routine):
    """-> (whole-extent writer, category routine).  Both read from the bytes."""
    p = routine
    if a(p, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xBB]):     # set 3,(0x60FD40)
        p += 5
    assert a(p, 5) == bytes([0xF2, 0xE8, 0xFC, 0x60, 0x31]), hex(p)  # lda (0x60FCE8)
    p += 5
    assert a(p, 1) == b"\x39"                                # push XBC
    p += 1
    extent = call24(p)
    p += 4
    return extent, calr(p)


JOBS = {}
for job in (0, 2, 3, 4, 5):
    JOBS[job] = job_body(JOB_ROUTINE[job])

TOTAL_EXTENT, TOTAL_ROUTINE = JOBS[0]

# TOTAL KEYBOARD's category routine is a bare chain of four calr -- and THAT
# is the dump order.  The chain length is fixed by the RET that follows it.
TOTAL_ORDER = calr_chain(TOTAL_ROUTINE, 4)

CATEGORY_OF_JOB = {job: JOBS[job][1] for job in (2, 3, 4, 5)}
# every category routine the four single-category jobs run is in the TOTAL
# chain, and the chain has no others -- the same four routines, one order
assert sorted(CATEGORY_OF_JOB.values()) == sorted(TOTAL_ORDER)

CATEGORY_NAME = {CATEGORY_OF_JOB[4]: "SYSTEM,PART & MIDI",
                 CATEGORY_OF_JOB[3]: "SOUND",
                 CATEGORY_OF_JOB[5]: "COMBINATION",
                 CATEGORY_OF_JOB[2]: "SEQUENCER"}

# ------------------------------------ 3. category routine -> part emitters
SEQ_ROUTINE = CATEGORY_OF_JOB[2]
END_OF_CATEGORY = 0xFB277E          # the routine that sends F0 50 27 7E F7
assert b(0xF4FEBE, 5) == bytes([0xF0, 0x50, 0x27, 0x7E, 0xF7])

CAT_PARTS = {}
for cat in TOTAL_ORDER:
    if cat == SEQ_ROUTINE:
        # ★ the SEQUENCER category is GUARDED: `pushw 3 / call sub_FB5FF5 /
        # popw / cp WA,0xFFFF / jr z,<ret>` -- on the 0xFFFF arm it sends
        # nothing at all, not even the end-of-category message.
        assert a(cat, 3) == bytes([0x0B, 0x03, 0x00])
        assert call24(cat + 3) == 0xFB5FF5
        assert a(cat + 8, 4) == bytes([0xD8, 0xCF, 0xFF, 0xFF])   # cp WA,0xFFFF
        assert a(cat + 12, 1) == b"\x66"                          # jr z
        chain = calr_chain(cat + 14, 4)
    else:
        n = 3 if a(cat + 9, 1) == b"\x0e" else 2
        chain = calr_chain(cat, n)
    assert chain[-1] == END_OF_CATEGORY, (hex(cat), [hex(x) for x in chain])
    CAT_PARTS[cat] = chain[:-1]

# ---------------------- 4. part emitter -> step id, descriptor, template
TEMPLATE_LO, TEMPLATE_HI = 0xF4FEF2, 0xF4FF61
DESCRIPTORS = {0xFB75BA, 0xFB75E4, 0xFB7629, 0xFB7649,
               0xFB766F, 0xFB7692, 0xFB76B5, 0xFB76F2, 0xFB7722}
SETFIELD, GETFIELD = 0xFB6219, 0xFB62D3
EMIT = 0xFB6E7F                      # push a literal template into the frame
APPEND_SIZE = 0xFB6EE9               # append the run-time size septets


def scan_emitter(start, end):
    """Read one part emitter's bytes and pull out the three things that
    identify what it sends.  The window is bounded by the NEXT routine in the
    module, and every hit is counted and asserted, so a window that runs into
    a neighbour cannot go unnoticed."""
    steps, templates, descs, hdrlens, appends = [], [], [], [], []
    p = start
    while p < end:
        # pushw <step> ; pushw 0x03 ; ld xbc,(0x60FCE0) ; push ; call setfield
        if (a(p, 1) == b"\x0b" and a(p + 3, 3) == bytes([0x0B, 0x03, 0x00])
                and a(p + 6, 5) == bytes([0xE2, 0xE0, 0xFC, 0x60, 0x21])
                and a(p + 11, 1) == b"\x39" and call24(p + 12) == SETFIELD):
            steps.append(int.from_bytes(a(p + 1, 2), "little"))
        # pushw <n> ; lda xbc,(template) ; push ; call EMIT
        if (a(p, 1) == b"\x0b" and a(p + 3, 1) == b"\xf2"
                and a(p + 7, 1) == b"\x31" and a(p + 8, 1) == b"\x39"
                and call24(p + 9) == EMIT):
            t = int.from_bytes(a(p + 4, 3), "little")
            if TEMPLATE_LO <= t < TEMPLATE_HI:
                templates.append(t)
                hdrlens.append(int.from_bytes(a(p + 1, 2), "little"))
        if a(p, 1) == b"\x1d":
            t = call24(p)
            if t in DESCRIPTORS:
                descs.append(t)
            if t == APPEND_SIZE:
                appends.append(p)
        p += 1
    assert len(steps) == 1, (hex(start), steps)
    assert len(templates) == 1, (hex(start), [hex(x) for x in templates])
    assert len(set(descs)) == 1, (hex(start), [hex(x) for x in descs])
    return steps[0], templates[0], descs[0], hdrlens[0], bool(appends)


# --------------------- 5. descriptor writer -> the SOURCE extent it names
# Each writer stores three longs into the caller's struct: +0 start, +4 end,
# +8 size.  The script reads the literals out of the instruction stream and
# then checks end - start == size, so a transcription slip cannot pass.
def imm24_lda(addr):
    op = a(addr, 5)
    assert op[0] == 0xF2 and op[4] in (0x30, 0x31, 0x34, 0x35), (hex(addr), op.hex())
    return int.from_bytes(op[1:4], "little")


def imm32_ld(addr):
    op = a(addr, 5)
    assert op[0] == 0x41, (hex(addr), op.hex())
    return int.from_bytes(op[1:5], "little")


EXTENTS = {
    0xFB75BA: (0x007600, 0x007620, 0x000020),
    0xFB75E4: (0x007620, 0x007F80, 0x000960),
    0xFB7629: (0x60A000, 0x60A000, 0x000000),
    0xFB7649: (0x60A000, 0x60C000, 0x002000),
    0xFB766F: (0x603400, 0x604000, 0x000C00),
    0xFB7692: (0x610000, 0x617800, 0x007800),
    0xFB76B5: (0x617800, 0x668400, 0x050C00),
    0xFB76F2: (0x609D00, 0x60A000, 0x000300),
    0xFB7722: (0x60A000, 0x60B600, 0x001600),
}
for w, (s_, e_, n_) in EXTENTS.items():
    assert e_ - s_ == n_, (hex(w), hex(e_ - s_), hex(n_))
# four of the nine anchored directly in the bytes
assert imm24_lda(0xFB7649 + 0x08) == 0x60A000
assert imm32_ld(0xFB7649 + 0x17) == 0x00002000
assert imm24_lda(0xFB7692 + 0x08) == 0x610000
assert imm32_ld(0xFB7692 + 0x17) == 0x00007800

# The two block-streamed categories: literal block counts, one loop pass short
# because one more block follows the loop.
assert a(0xFB2524, 2) == bytes([0x26, 0x1F]), "ldb h,0x1F (SOUND)"
assert a(0xFB271F, 2) == bytes([0x26, 0x0F]), "ldb h,0x0F (COMBINATION p2)"
BLOCKS = {0xFB7649: 32, 0xFB7722: 16}

# ★ Where those two categories' bytes actually COME FROM: not this CPU's
# memory at all.  `ld XIX,imm32` then the 0xE2 remote-read entry.
assert a(0xFB251F, 5) == bytes([0x44, 0x00, 0x00, 0xE8, 0x00]), "ld XIX,0x00E80000"
assert a(0xFB271A, 5) == bytes([0x44, 0x00, 0x03, 0xEC, 0x00]), "ld XIX,0x00EC0300"
assert a(0xFB26C8, 5) == bytes([0x41, 0x00, 0x00, 0xEC, 0x00]), "ld XBC,0x00EC0000"
REMOTE = {0xFB7649: 0x00E80000, 0xFB76F2: 0x00EC0000, 0xFB7722: 0x00EC0300}
# and both categories are read through the SAME link entry
for site in (0xFB2534, 0xFB2560, 0xFB26CE, 0xFB272F, 0xFB275B):
    assert call24(site) == 0xF40EF0, hex(site)

# ---------------------------------------------- 6. build the transmit table
# Every routine this module lays out in order, so each part emitter's window
# stops where the next routine begins.  No fixed window length is guessed.
BOUNDS = sorted({TOTAL_ROUTINE, END_OF_CATEGORY} | set(TOTAL_ORDER)
                | {e for parts in CAT_PARTS.values() for e in parts})


def window_end(addr):
    later = [x for x in BOUNDS if x > addr]
    assert later, hex(addr)
    return later[0]


PARTS = []          # (category, index, step, template, desc, hdrlen, runtime)
for cat in TOTAL_ORDER:
    for i, emitter in enumerate(CAT_PARTS[cat]):
        PARTS.append((CATEGORY_NAME[cat], i + 1)
                     + scan_emitter(emitter, window_end(emitter)))

# every part's header is a `F0 50 2D 04 00 11` data header
for _, _, _, tmpl, _, hlen, rt in PARTS:
    assert b(tmpl, 6) == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11]), hex(tmpl)
    assert hlen == (9 if rt else 12), (hex(tmpl), hlen, rt)

# ★ size septets == descriptor size x blocks
for name, idx, step, tmpl, desc, hlen, rt in PARTS:
    if rt:
        continue
    want = EXTENTS[desc][2] * BLOCKS.get(desc, 1)
    got = septets(b(tmpl + 9, 3))
    assert got == want, (name, idx, hex(got), hex(want))

# ★ within a category, addr(N+1) - addr(N) == size(N)
for cat in {p[0] for p in PARTS}:
    rows = [p for p in PARTS if p[0] == cat]
    for first, second in zip(rows, rows[1:]):
        a1 = septets(b(first[3] + 6, 3))
        a2 = septets(b(second[3] + 6, 3))
        s1 = EXTENTS[first[4]][2] * BLOCKS.get(first[4], 1)
        assert a2 - a1 == s1, (cat, hex(a2 - a1), hex(s1))

# ★ THE NEGATIVE THAT MATTERS: the dump address is not the source address,
# under ANY affine map.  SOUND and COMBINATION abut in CPU 2's flash and are
# 0x0C0000 apart in the dump space; that alone kills a linear relation.
snd = [p for p in PARTS if p[0] == "SOUND"][0]
cmb = [p for p in PARTS if p[0] == "COMBINATION"][0]
assert REMOTE[snd[4]] + EXTENTS[snd[4]][2] * BLOCKS[snd[4]] == REMOTE[cmb[4]], \
    "SOUND and COMBINATION are meant to abut in the flash"
assert septets(b(cmb[3] + 6, 3)) - septets(b(snd[3] + 6, 3)) == 0x0C0000
for name, idx, step, tmpl, desc, hlen, rt in PARTS:
    src = REMOTE.get(desc, EXTENTS[desc][0])
    assert septets(b(tmpl + 6, 3)) != src, ("dump address == source", name, idx)

# ---------------------------------------- 7. the RECEIVE side of the same map
ROOT = 0xF5115B                       # prom_a 0xFB63FC `add XBC,0x00F5115B`
NULLREC = 0xF4FF61
RXTABLE = 0xF4F916                    # prom_a 0xFB28A1 `add XWA,0x00F4F916`
assert a(0xFB28A1, 6) == bytes([0xE8, 0xC8, 0x16, 0xF9, 0xF4, 0x00])
assert a(0xFB2896, 3) == bytes([0xCE, 0xCF, 0x22]), "cp H,0x22 bounds the table"


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
        if m == 0xFF:                 # ⚠ the terminator's second byte is the
            break                     #    parser's DEPTH code, not a command
        p = prefix + bytes([m])
        if c:
            acc.append((p, c))
        elif nx != NULLREC:
            walk(nx, p, acc)


rx = []
for m, c, nx in records(ROOT, 15):
    if m == 0xFF:
        assert c == 0x07, "root terminator should carry the root depth code"
        break
    if m == 0x2D:
        walk(nx, bytes([m]), rx)
assert rx, "no 2D leaves"

# Every accepted 2D sequence, for unit byte 0x00, stripped back to the six
# address/size bytes.  (Unit 0x01 is accepted too and duplicates the set.)
rx_units = sorted({seq[2] for seq, _ in rx})
assert rx_units == [0x00, 0x01], rx_units
RX = {seq[4:]: cmd for seq, cmd in rx if seq[2] == 0x00}
assert len(RX) == 8, sorted(RX)

TX = {b(tmpl + 6, 3 if rt else 6): (name, idx)
      for name, idx, step, tmpl, desc, hlen, rt in PARTS}
# ★★ the two sides are the SAME SET.  Nothing arithmetic happens to these
# bytes on the way in: the trie matches them literally, byte for byte.
assert set(RX) == set(TX), (sorted(RX), sorted(TX))

# and the orphan template -- the one no menu row reaches -- is NOT accepted
ORPHAN = 0xF4FF10
assert b(ORPHAN, 12) == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11,
                               0x20, 0x00, 0x00, 0x00, 0x00, 0x10])
assert b(ORPHAN + 6, 6) not in RX, "the orphan header is not accepted"
assert ORPHAN not in {p[3] for p in PARTS}, "the orphan is not sent either"

# ★ each accepted string's command number reaches a handler that calls the
# SAME descriptor writer the transmit side used for that part.
RX_HANDLER = {cmd: int.from_bytes(b(RXTABLE + 4 * cmd, 4), "little")
              for cmd in set(RX.values())}


def handler_descriptors(addr, limit=0x60):
    out = set()
    for p in range(addr, addr + limit):
        if a(p, 1) == b"\x1d" and call24(p) in DESCRIPTORS:
            out.add(call24(p))
    return out


for key, cmd in RX.items():
    name, idx = TX[key]
    desc = [p[4] for p in PARTS if (p[0], p[1]) == (name, idx)][0]
    assert desc in handler_descriptors(RX_HANDLER[cmd]), \
        (name, idx, hex(cmd), hex(RX_HANDLER[cmd]), hex(desc))

# ★ and the receive handlers reach CPU 2's flash at the SAME two bases
assert a(0xFB2A3B, 5) == bytes([0x44, 0x00, 0x00, 0xE8, 0x00]), "rx SOUND 0xE80000"
assert a(0xFB2BF5, 5) == bytes([0x44, 0x00, 0x00, 0xEC, 0x00]), "rx COMBI 0xEC0000"

# --------------------------- 8. the ONE field the firmware treats as a number
# transmit: sub_FB6EE9 splits (0x60FD00) into septets, MOST SIGNIFICANT FIRST
assert a(0xFB6EF6, 3) == bytes([0xE9, 0xEF, 0x0E]), "srl xbc,0x0E"
assert a(0xFB6F03, 3) == bytes([0xE9, 0xEF, 0x07]), "srl xbc,0x07"
assert a(0xFB6EF9, 3) == bytes([0xCB, 0x30, 0x07]), "res 7,C"
# receive: sub_FB741A rebuilds it from parse-record fields 0x0C/0x0D/0x0E
assert a(0xFB7434, 3) == bytes([0xE8, 0xEE, 0x0E]), "sll xwa,0x0E"
assert a(0xFB744A, 3) == bytes([0xE8, 0xEE, 0x07]), "sll xwa,0x07"
assert a(0xFB7424, 3) == bytes([0x0B, 0x0C, 0x00]), "field 0x0C"
assert a(0xFB743A, 3) == bytes([0x0B, 0x0D, 0x00]), "field 0x0D"
assert a(0xFB7453, 3) == bytes([0x0B, 0x0E, 0x00]), "field 0x0E"
# the run-time value itself: 16 x the sequencer's own memory-use counter
assert a(0xFB7754, 3) == bytes([0x31, 0x10, 0x00]), "ldw bc,0x0010"
assert a(0xFB7757, 5) == bytes([0xD2, 0x52, 0x34, 0x60, 0x41]), "mul XBC,(0x603452)"
RUNTIME_UNIT = 0x10
RUNTIME_MAX = EXTENTS[0xFB76B5][2]

# ------------------- 9. the SEQUENCER availability gate, read from the table
# sub_FB5FF5(n<6) returns a word from 0xF4FE6A when the model-variant strap
# (0x00C4) is 1, and from 0xF4FE76 otherwise; 0xFFFF means "not available".
assert a(0xFB6000, 4) == bytes([0xC0, 0xC4, 0x3F, 0x01]), "cp (0xC4),0x01"
assert imm24_lda(0xFB6006) == 0xF4FE6A
assert imm24_lda(0xFB600D) == 0xF4FE76
V1 = [int.from_bytes(b(0xF4FE6A + 2 * i, 2), "little") for i in range(6)]
V2 = [int.from_bytes(b(0xF4FE76 + 2 * i, 2), "little") for i in range(6)]
assert V1 == [0] * 6, V1
assert V2 == [0, 0, 0, 0xFFFF, 0, 0xFFFF], V2
SEQ_FEATURE = 3


# ------------------- 10. ★★★ THE DUMP REQUEST names the category BY ADDRESS
# A remote device can ask for a dump with `F0 50 2B 04 <unit> 11 <addr> <3
# don't-care bytes> F7`.  The trie stores the three address septets
# LITERALLY and the three size septets as WILDCARDS (0xFE), and each of the
# four accepted addresses is exactly the FIRST part's dump address of one
# category -- whose job code the handler then writes to (0x60F802).
# That is an independent second witness that the address identifies a
# category, from a message that has no payload for it to be an offset into.
FIRST_HANDLER = 0xF4F800              # prom_a 0xFB21AF, the IRQ-side table
WILDCARD = 0xFE

req = []
for m, c, nx in records(ROOT, 15):
    if m == 0xFF:
        break
    if m == 0x2B:
        walk(nx, bytes([m]), req)

REQUESTS = {}
for seq, cmd in req:
    if seq[2] != 0x00 or len(seq) != 10:
        continue
    if seq[7:] != bytes([WILDCARD] * 3):      # size septets are don't-care
        continue
    if not all(x < 0x80 for x in seq[4:7]):   # address septets are literal
        continue
    REQUESTS[bytes(seq[4:7])] = cmd
assert len(REQUESTS) == 4, sorted(REQUESTS)

REQ_JOB = {}
for addr3, cmd in REQUESTS.items():
    arm = int.from_bytes(b(FIRST_HANDLER + 4 * cmd, 4), "little")
    op = a(arm, 6)                            # ld (0x60F802),<job>
    assert op[:5] == bytes([0xF2, 0x02, 0xF8, 0x60, 0x00]), (hex(arm), op.hex())
    REQ_JOB[addr3] = op[5]

# each requested address is the first part's address of exactly one category,
# and the job code it starts is that category's own menu job
FIRST_PART_ADDR = {}
for name, idx, step, tmpl, desc, hlen, rt in PARTS:
    if idx == 1:
        FIRST_PART_ADDR[b(tmpl + 6, 3)] = name
assert set(REQUESTS) == set(FIRST_PART_ADDR), (sorted(REQUESTS),
                                               sorted(FIRST_PART_ADDR))
for addr3, job in REQ_JOB.items():
    name = FIRST_PART_ADDR[addr3]
    assert CATEGORY_NAME[CATEGORY_OF_JOB[job]] == name, (name, job)

# ⚠ there is NO dump request for TOTAL KEYBOARD, and one handler slot
# (job 1, the bare RET) has no accepted sequence at all.
assert 0 not in REQ_JOB.values(), "TOTAL KEYBOARD is not requestable"
assert 1 not in REQ_JOB.values()


# ------------------------------------------------------------------ report
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--wire", action="store_true",
                    help="print each header exactly as it goes out")
    args = ap.parse_args()

    print("base check OK")
    print()
    print("SYSEX BULK DUMP menu row -> job -> category routine")
    for row, name in enumerate(ROW_NAMES):
        job = ROW_TO_JOB[row]
        cat = CATEGORY_OF_JOB.get(job)
        tag = CATEGORY_NAME[cat] if cat else "(all four, in order)"
        print("  row %d  %-20s job %d  0x%06X  %s"
              % (row, name, job, JOB_ROUTINE[job], tag))
    print()
    print("TOTAL KEYBOARD order: " + " -> ".join(CATEGORY_NAME[c] for c in TOTAL_ORDER))
    print()
    hdr = ("category", "pt", "step", "dump addr", "length", "read from")
    print("  %-20s %2s %4s  %-9s %9s  %s" % hdr)
    for name, idx, step, tmpl, desc, hlen, rt in PARTS:
        adr = septets(b(tmpl + 6, 3))
        if rt:
            ln = "run-time"
            src = "0x%06X.. (%d x N, max %d)" % (EXTENTS[desc][0], RUNTIME_UNIT,
                                                 RUNTIME_MAX)
        else:
            n = EXTENTS[desc][2] * BLOCKS.get(desc, 1)
            ln = "%d" % n
            if desc in REMOTE:
                src = "CPU2 flash 0x%06X..0x%06X (%d x 0x%X)" % (
                    REMOTE[desc], REMOTE[desc] + n, BLOCKS.get(desc, 1),
                    EXTENTS[desc][2])
            else:
                src = "CPU1 0x%06X..0x%06X" % (EXTENTS[desc][0], EXTENTS[desc][1])
        print("  %-20s %2d 0x%02X  0x%06X %9s  %s" % (name, idx, step, adr, ln, src))
    print()
    print("Accepted on RECEIVE -- the identical byte strings, matched literally")
    for key in sorted(RX, key=lambda k: TX[k]):
        name, idx = TX[key]
        print("  %-20s %d  %-18s -> command 0x%02X, handler 0x%06X"
              % (name, idx, key.hex(" ").upper(), RX[key], RX_HANDLER[RX[key]]))
    print("  (the orphan header %s is neither sent nor accepted)"
          % b(ORPHAN + 6, 6).hex(" ").upper())
    print()
    print("Dump REQUEST -- F0 50 2B 04 <unit> 11 <addr> <3 ignored bytes> F7")
    for addr3 in sorted(REQUESTS, key=lambda k: FIRST_PART_ADDR[k]):
        print("  %-18s -> command 0x%02X -> job %d = %s"
              % (addr3.hex(" ").upper(), REQUESTS[addr3], REQ_JOB[addr3],
                 FIRST_PART_ADDR[addr3]))
    print("  (no request exists for TOTAL KEYBOARD)")
    print()
    print("SEQUENCER availability, by the model-variant strap (0x00C4):")
    print("  strap == 1 -> feature %d = 0x%04X  (category is sent)"
          % (SEQ_FEATURE, V1[SEQ_FEATURE]))
    print("  strap != 1 -> feature %d = 0x%04X  (category sends NOTHING, not"
          " even the end-of-category message)" % (SEQ_FEATURE, V2[SEQ_FEATURE]))
    print()
    if args.wire:
        print("Data headers exactly as transmitted")
        for name, idx, step, tmpl, desc, hlen, rt in PARTS:
            print("  %-20s %d  %s%s" % (name, idx, b(tmpl, hlen).hex(" ").upper(),
                                        "  + <size septets> appended at send time" if rt else ""))
        print()
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
