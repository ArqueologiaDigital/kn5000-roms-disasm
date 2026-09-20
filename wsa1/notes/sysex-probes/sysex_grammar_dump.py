#!/usr/bin/env python3
"""Dump the WSA1R's RECEIVED-SysEx grammar tables out of prom_b.

QUESTION THIS ANSWERS
    After `F0 <50|7E>`, which byte sequences does the firmware accept, and
    which internal command number does each one produce?

WHERE THE SIGNAL IS
    prom_a `sub_FB63D1` (0xFB63D1) parses a buffered SysEx message:
      * 0xFB63E1  advances the buffer read cursor by 2 -- F0 and the
                  manufacturer byte are SKIPPED, never re-compared;
      * 0xFB63FC  `add XBC,0x00f5115b` names the ROOT table, in prom_b;
      * 0xFB63F2  `ld L,0x0f` + 0xFB649A `dec 1,L` bounds the root at 15
                  records, and `inc 6,DE` fixes the stride at 6 bytes;
      * record layout = [0] match byte, [1] command id (0 = descend),
                        [2..5] LE32 pointer to the next node;
      * 0xFB6407  match byte 0xFF ends a node; 0xFB64C9 `cp L,0xfe` makes
                  0xFE a wildcard;
      * a command id != 0 is written to parse-record field 0 and later
        bounded by `cp A,0x22 / jr nc` (0xFB2194, 0xFB2291) before indexing
        a 34-entry LE32 handler table -- 0xF4F800 for a message that came in
        on the interrupt-side ring, 0xF4F888 for the foreground ring.  The
        two tables tile, which is the last-entry test on the count 34.

    CAUTION: a `next` pointer may aim into the MIDDLE of a record list, so a
    node is "from here forward to the first 0xFF match byte" and can be much
    longer than it looks.  Walking with a short record cap silently runs one
    node's tail into the next node's records.

    prom_b is a 512 KiB image that loads at 0xF00000; PROM_B_BASE below is
    checked against a known byte string rather than assumed.

RUN
    python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py            # root + nodes
    python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py --paths    # accepted sequences

PASS
    The base check prints OK, the root prints 14 command bytes plus the
    0xFF terminator, and the handler table's last valid index is 0x21.
"""
import os, sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
ROM = os.path.join(HERE, "..", "..", "original_ROMs", "wsa1_prom_b.ic13")
PROM_B_BASE = 0xF00000
ROOT        = 0xF5115B      # prom_a 0xFB63FC
NULLREC     = 0xF4FF61      # LinkTable_F4FF61 record 0, key 0xFFFF
HANDLERS    = (0xF4F800,    # prom_a 0xFB21AF -- reached from the IRQ-side ring
               0xF4F888)    # prom_a 0xFB22AC -- reached from the foreground ring
HANDLER_N   = 0x22          # prom_a 0xFB2194 / 0xFB2291 `cp A,0x22 / jr nc`
TEMPLATES   = (0xF4FEB4, 0xF4FF61)   # literal outgoing SysEx strings

rom = open(ROM, "rb").read()
def rd(addr, n):
    o = addr - PROM_B_BASE
    assert 0 <= o < len(rom), "address outside prom_b"
    return rom[o:o + n]

# --- base check: the literal template block must start with F0 50 23 7E F7
assert rd(TEMPLATES[0], 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "wrong load base"
print("base check OK: prom_b loads at 0x%06X" % PROM_B_BASE)

def records(addr, limit=64):
    out = []
    for i in range(limit):
        b = rd(addr + 6 * i, 6)
        out.append((b[0], b[1], int.from_bytes(b[2:6], "little")))
        if b[0] == 0xFF:
            break
    return out

root = records(ROOT, 15)

def show(recs, title):
    print("=== %s ===" % title)
    for m, c, nx in recs:
        tok = "<any>" if m == 0xFE else ("END" if m == 0xFF else "%02X" % m)
        print("   %5s cmd=%02X next=0x%06X%s" % (tok, c, nx, " NULL" if nx == NULLREC else ""))

if "--paths" in sys.argv:
    out = []
    def walk(p, prefix, depth):
        if depth > 8:
            out.append(prefix + " ...(truncated at depth 8)")
            return
        for m, c, nx in records(p):
            if m == 0xFF:
                break
            tok = "<any>" if m == 0xFE else "%02X" % m
            pfx = prefix + " " + tok
            if c:
                out.append("%-44s => CMD 0x%02X" % (pfx, c))
            elif nx != NULLREC:
                walk(nx, pfx, depth + 1)
    for m, c, nx in root:
        if m == 0xFF:
            break
        pfx = "F0 <50|7E> %02X" % m
        if c:
            out.append("%-44s => CMD 0x%02X" % (pfx, c))
        elif nx != NULLREC:
            walk(nx, pfx, 1)
    print("\n".join(out))
    sys.exit(0)

show(root, "ROOT table 0x%06X (message byte 2)" % ROOT)
seen, order, q = set(), [], deque(nx for m, c, nx in root if m != 0xFF and nx != NULLREC)
while q:
    p = q.popleft()
    if p in seen:
        continue
    seen.add(p); order.append(p)
    for m, c, nx in records(p):
        if m != 0xFF and nx != NULLREC and nx not in seen:
            q.append(nx)
print("reachable nodes: %d" % len(order))
for p in order:
    show(records(p), "node 0x%06X" % p)

for base in HANDLERS:
    print("=== handler table 0x%06X, %d entries ===" % (base, HANDLER_N))
    for i in range(HANDLER_N):
        print("   [%02X] 0x%06X" % (i, int.from_bytes(rd(base + 4 * i, 4), "little")))
# last-entry test: the two tables tile, which is what fixes the entry count
assert HANDLERS[0] + 4 * HANDLER_N == HANDLERS[1], "handler tables do not tile"
print("tiling check OK: 0x%06X + %d*4 = 0x%06X" % (HANDLERS[0], HANDLER_N, HANDLERS[1]))

print("=== literal outgoing SysEx templates 0x%06X-0x%06X ===" % (TEMPLATES[0], TEMPLATES[1] - 1))
print(" ".join("%02X" % b for b in rd(TEMPLATES[0], TEMPLATES[1] - TEMPLATES[0])))
