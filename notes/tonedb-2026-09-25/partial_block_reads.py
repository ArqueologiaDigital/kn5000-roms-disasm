#!/usr/bin/env python3
"""Which bytes of an 81-byte tone-record PARTIAL BLOCK does the subcpu read, and where?

QUESTION THIS ANSWERS
    A melodic tone record (part mode 0x00) carries one 81-byte block per
    present partial at rec + 0x66 + 0x51*rank.  VoiceParam_Update
    (EFFSlotScan_AssignPath, subcpu 0x032295) stores that block's address in
    the part record at +0x6E + 0x25*partial, and Voice_Build_Partial_Descriptor
    (0x02B717) copies it into the voice slot at +0x17 -- the pointer the voice
    code calls "paramA".  So every `(paramA + N)` read in the voice code is a
    read of partial-block byte N.

    This probe finds those reads mechanically in v142/subcpu/*.s: inside each
    routine it tracks which registers and stack slots hold paramA (a
    `ld xR,(xS + 23)` load, register copies, spills to (xsp+k) and reloads) and
    records every `(xR + N)` displacement read through one of them, per routine.

    It is a HEURISTIC dataflow (straight-line, per routine, no call effects),
    so it can miss a read and it can mis-attribute one if a routine reuses a
    stack slot.  Its output is the evidence behind the partial-block field map
    in table_data/tone_database_records.s, which cites only offsets whose
    routine was also read by hand.

    ⚠ The same slot +0x17 holds a PercInst LAYER (21 bytes) for drum voices
    (Voice_Allocate_Type2) -- so a read at N <= 0x14 in a routine that serves
    both voice kinds is ambiguous.  Offsets > 0x14 can only be partial-block
    reads.  The table marks which routines the voice-type-4 (partial block)
    path reaches.

RUN
    python3 notes/tonedb-2026-09-25/partial_block_reads.py            # offset -> routines
    python3 notes/tonedb-2026-09-25/partial_block_reads.py --by-routine
    python3 notes/tonedb-2026-09-25/partial_block_reads.py --chains [--slot 19]
        splits every offset's readers by call-graph reachability: T4 = reached
        from Voice_Build_Register_Set / Voice_Release_Type4 (part modes 0x00 and
        0x40, slot +0x17 = a partial block), T2 = reached from Voice_Init_Type1 /
        _Type2 (slot +0x17 = a PercInst layer).
"""
import collections
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
# slot +0x17 (23) = paramA; `--slot 19` follows slot +0x13 instead, which holds
# the TONE RECORD itself on the melodic path (Voice_Build_Partial_Descriptor)
# and the PercInst record on the drum path (Voice_Allocate_Type2).
SLOT_OFF = int(sys.argv[sys.argv.index("--slot") + 1]) if "--slot" in sys.argv else 23
SRC = ROOT / "v142" / "subcpu" / "kn5000_subprogram_v142.s"

LABEL = re.compile(r'^([A-Za-z_][\w.]*):')
REG32 = r'x(?:wa|bc|de|hl|ix|iy|iz)'


def main():
    lines = SRC.read_bytes().decode("latin-1").split("\n")
    # every call/calr target starts a routine of its own, even when its name
    # extends another routine's (Voice_ComputePitch_Mono is not part of
    # Voice_ComputePitch)
    callees = set()
    for raw in lines:
        mm = re.match(r'^\s*(?:call|calr)\s+([A-Za-z_]\w*)\s*(?:;|$)', raw)
        if mm:
            callees.add(mm.group(1))
    reads = collections.defaultdict(set)      # offset -> {routine}
    per = collections.defaultdict(set)        # routine -> {offset}
    owner = {}                                # label -> routine
    edges = collections.defaultdict(set)      # routine -> {target label}
    routine = None
    regs, stack = set(), set()
    for raw in lines:
        m = LABEL.match(raw)
        if m:
            name = m.group(1)
            # a new routine starts at a label that is not a local-looking suffix
            # of the current one; keep state across internal labels
            if routine is None or not name.startswith(routine) or name in callees:
                routine = name
                regs, stack = set(), set()
            owner[name] = routine
            continue
        code = raw.split(";", 1)[0].strip()
        if not code:
            continue
        mm = re.match(r'^(?:call|calr|jp|jrl|jr)\s+(?:\w+,\s*)?([A-Za-z_]\w*)$', code)
        if mm and routine:
            edges[routine].add(mm.group(1))
        if code.startswith(("ret", "retd")):
            continue
        # paramA load from a slot pointer: ld xR, (xS + 23)
        mm = re.match(r'^ld (%s), \((%s) \+ %d\)$' % (REG32, REG32, SLOT_OFF), code)
        if mm:
            regs.add(mm.group(1))
            continue
        # spill: ld (xsp + k), xR
        mm = re.match(r'^ld \(xsp \+ (\d+)\), (%s)$' % REG32, code)
        if mm:
            if mm.group(2) in regs:
                stack.add(int(mm.group(1)))
            else:
                stack.discard(int(mm.group(1)))
            continue
        # reload: ld xR, (xsp + k)
        mm = re.match(r'^ld (%s), \(xsp \+ (\d+)\)$' % REG32, code)
        if mm:
            if int(mm.group(2)) in stack:
                regs.add(mm.group(1))
            else:
                regs.discard(mm.group(1))
            continue
        # register copy
        mm = re.match(r'^ld (%s), (%s)$' % (REG32, REG32), code)
        if mm:
            if mm.group(2) in regs:
                regs.add(mm.group(1))
            else:
                regs.discard(mm.group(1))
            continue
        # displacement reads through a paramA holder
        for r, n in re.findall(r'\((%s) \+ (\d+)\)' % REG32, code):
            if r in regs:
                reads[int(n)].add(routine)
                per[routine].add(int(n))
        for r in re.findall(r'\((%s)\)' % REG32, code):
            if r in regs:
                reads[0].add(routine)
                per[routine].add(0)
        # any other write to a 32-bit register clears it
        mm = re.match(r'^(?:ld|lda|pop|add|sub|and|or|xor|extz|exts|sll|srl|inc|dec)\w*\s+(%s)\b' % REG32,
                      code)
        if mm and not re.match(r'^(?:inc|dec) \d+, ', code):
            regs.discard(mm.group(1))
        mm = re.match(r'^(?:inc|dec) \d+, (%s)$' % REG32, code)
        if mm:
            regs.discard(mm.group(1))
    graph = collections.defaultdict(set)
    for r, ts in edges.items():
        for t in ts:
            o = owner.get(t)
            if o and o != r:
                graph[r].add(o)

    def reach(roots):
        seen, todo = set(), list(roots)
        while todo:
            x = todo.pop()
            if x in seen:
                continue
            seen.add(x)
            todo.extend(graph.get(x, ()))
        return seen
    T4 = reach(["Voice_Build_Register_Set", "Voice_Release_Type4"])
    T2 = reach(["Voice_Init_Type1", "Voice_Init_Type2"])
    if "--chains" in sys.argv:
        for n in sorted(reads):
            a = sorted(r for r in reads[n] if r in T4)
            b = sorted(r for r in reads[n] if r in T2)
            c = sorted(r for r in reads[n] if r not in T4 and r not in T2)
            print("+0x%02X  T4(partial block): %s | T2(PercInst layer): %s | neither: %s"
                  % (n, ", ".join(a) or "-", ", ".join(b) or "-", ", ".join(c) or "-"))
        return
    if "--by-routine" in sys.argv:
        for r in sorted(per):
            print("%-44s %s" % (r, " ".join("+0x%02X" % n for n in sorted(per[r]))))
        return
    for n in sorted(reads):
        tag = "" if n > 0x14 else "  (<= 0x14: also a PercInst-layer offset)"
        print("+0x%02X  %s%s" % (n, ", ".join(sorted(reads[n])), tag))
    print("\n%d distinct offsets read, %d of them > 0x14" % (len(reads), sum(1 for n in reads if n > 0x14)))


if __name__ == "__main__":
    main()
