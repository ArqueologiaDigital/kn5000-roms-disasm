#!/usr/bin/env python3
r"""prom_b 0xF4FF61-0xF511B4 (`LinkTable_F4FF61`): the SysEx decode tree prom_a walks.

QUESTION THIS ANSWERS
    The object's header said "Unknown: what the keys mean ... The traversal that
    follows `next` is not located."  The traversal is prom_a sub_FB63D1
    (0xFB63D1), entered at record 767 (0xF5115B) by `add XBC,0x00F5115B` at
    0xFB63FC.  This probe re-derives from the ROM bytes:

      1. the READER's shape, from MAME unidasm's decode of prom_a 0xFB63D1..:
         the root constant, the per-level failure codes (7..16 for levels
         0..9, stored into field 4 of the result object), the 0xFF end-of-list
         and 0xFE any-byte tests;
      2. the TREE, walked the way that reader walks it: each record is
         {+0 u8 match, +1 u8 result, +2 u32 pointer}; result 0 -> descend to the
         list at the pointer, result != 0 -> a leaf whose pointer names a
         PAYLOAD record whose first two bytes the reader takes;
      3. the census: lists, records in lists, leaf payload records, records
         reached by neither; the terminator's +1 byte against 7 + depth;
      4. the CROSS-CHECK with the writer: every one of the 74 SysEx bodies
         SmfExport_ParamSysExTemplates (0xF74FCF) writes, taken from its +4
         byte (the one after the 0x50 ID), must be a complete path of the tree
         ending on a leaf after exactly seven bytes.

RUN
    python3 notes/promb-2026-09-25/sysex_decode_tree_probe.py
"""
import collections
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
A = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
UNI = os.path.join(os.path.expanduser("~/compartilhado"), "tools", "unidasm")
BB, AB = 0xF00000, 0xF80000
T, N, ROOTREC = 0xF4FF61, 782, 0xF5115B
SMF, NSMF, STRIDE = 0xF74FCF, 74, 19
READER = 0xFB63D1
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def main():
    rom = open(B, "rb").read()
    arom = open(A, "rb").read()
    rec = lambda a: (rom[a - BB], rom[a - BB + 1], int.from_bytes(rom[a - BB + 2:a - BB + 6], "little"))
    # 1. reader
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(arom[READER - AB:READER - AB + 0x800])
        f.flush()
        txt = subprocess.run([UNI, f.name, "-arch", "tlcs900", "-basepc", hex(READER)],
                             capture_output=True, text=True).stdout.lower()
    check("reader adds the root 0x00f5115b", "add xbc,0x00f5115b" in txt)
    # the per-level failure code: `push 0x00NN` right before the jump to the
    # common error exit (which pushes field index 4), plus the last level's
    # `push 0x0010` that falls into it
    lines = re.findall(r'^([0-9a-f]+):\s+(?:[0-9a-f]{2}\s)+\s*(\S+)\s*(.*)$', txt, re.M)
    err = None
    for a, mn, ops in lines:
        if mn == "push" and ops == "0x0004":
            err = a                                     # the common error exit
            break
    codes = []
    for (a0, m0, o0), (a1, m1, o1) in zip(lines, lines[1:]):
        if m0 == "push" and o0.startswith("0x00") and (
                (m1 == "jrl" and o1.endswith(err)) or a1 == err):
            codes.append(int(o0, 16))
    print("  per-level failure codes the reader stores in field 4:", " ".join("%d" % c for c in codes))
    check("they are 7, 8, ... 16 for levels 0..9", codes == list(range(7, 17)))
    check("reader tests 0xFF (end of list) and 0xFE (any byte)",
          "cp l,0xff" in txt and "cp l,0xfe" in txt)
    # 2./3. the tree
    lists, leaves, depth_of, term = set(), collections.defaultdict(list), {}, []

    def walk(a, d):
        if a in lists:
            return
        lists.add(a)
        depth_of[a] = d
        x = a
        while True:
            m, r, p = rec(x)
            if m == 0xFF:
                term.append((x, d, r))
                break
            if r:
                leaves[p].append(x)
            else:
                walk(p, d + 1)
            x += 6
    walk(ROOTREC, 0)
    inlist = set()
    for a in lists:
        x = a
        while True:
            inlist.add(x)
            if rom[x - BB] == 0xFF:
                break
            x += 6
    payload = set(leaves)
    allrec = {T + 6 * i for i in range(N)}
    other = allrec - inlist - payload
    print("  %d lists (%d records), %d leaf paths onto %d payload records, %d records in neither"
          % (len(lists), len(inlist), sum(len(v) for v in leaves.values()), len(payload), len(other)))
    check("every non-zero pointer lands on a record boundary of the table",
          all(T <= rec(a)[2] < T + 6 * N and (rec(a)[2] - T) % 6 == 0
              for a in allrec if rec(a)[2]))
    check("no payload record is also a list record", not (payload & inlist))
    check("every payload record's +2 names record 0 (0x%06X)" % T,
          all(rec(p)[2] == T for p in payload))
    ok_t = sum(1 for _, d, r in term if r == 7 + d)
    print("  terminators whose +1 byte is 7 + depth: %d of %d; the others: %s" % (
        ok_t, len(term), ", ".join("0x%06X depth %d code %d" % (x, d, r) for x, d, r in term if r != 7 + d)))
    print("  top-level match bytes:", " ".join("%02X" % rom[x - BB] for x in
                                            range(ROOTREC, ROOTREC + 6 * 15, 6)))
    print("  list depths:", dict(sorted(collections.Counter(depth_of.values()).items())))

    # 4. cross-check with the SMF export templates
    def lookup(seq):
        a = ROOTREC
        for i, byte in enumerate(seq):
            while True:
                m, r, p = rec(a)
                if m == 0xFF:
                    return None
                if m == byte or (m == 0xFE and i > 0):
                    break
                a += 6
            if r:
                return (i + 1, r, rom[p - BB], rom[p - BB + 1])
            a = p
        return None
    hits = 0
    for k in range(NSMF):
        body = rom[SMF - BB + STRIDE * k + 4:SMF - BB + STRIDE * k + 11]
        res = lookup(body)
        hits += bool(res and res[0] == 7)
    check("all 74 SmfExport_ParamSysExTemplates bodies are 7-byte paths to a leaf (%d)" % hits,
          hits == NSMF)
    print("\nVERDICT:", "PASS" if not FAIL else "FAIL (%d)" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
