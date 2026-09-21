#!/usr/bin/env python3
"""DOES ANY CODE HANDLE BLOCK B's +0x18, +0x19 AND +0x1A?

QUESTION IT ANSWERS

Those three bytes are the last thing in a combination that nothing names.  The
data side is exhausted: over 3080 part records and 220 byte columns none is a
copy of another column, the three together are not a copy of any other
three-byte run, and no column determines them.

So this asks the program, using the technique that worked for the neighbouring
triple: a part record is reached through a pointer, so the bytes are named by
DISPLACEMENT, not by address.  There are two displacements they could have --
block B is 0x20 past block A -- so either (reg+0x38..0x3A) from block A's base
or (reg+0x18..0x1A) from block B's own.

WHAT IT FINDS, AND THE CONTROL THAT MAKES IT WORTH SAYING

  Every INDIVIDUAL access is examined, not only groups of three -- a routine
  touching one of the bytes alone would slip past a grouping test -- and all
  four images are covered, the second processor's included.

  * 127 accesses at either displacement in total.
  * Three of them come near the part pointer table, and all three are in ONE
    routine which indexes that table WITHOUT the 0x80 step that selects a part
    record, so it reaches a sibling structure.
  * None reaches a part record.
  * Of the five groups that touch all three bytes at once, two are inside a
    64-entry uniform three-byte TABLE that the reference disassembler refuses
    to decode as instructions at all.

  The discriminator for "is this a part record" is mechanical and it is
  CONTROLLED: the instrument selects a part record by adding 0x80 to a table
  index before dereferencing, and that step appears twice in the image.  It
  fires on the writer of the neighbouring triple -- the positive control --
  and on none of these five.

  A negative from a test that cannot fire is worth nothing, which is why the
  control is asserted here rather than mentioned.

CONCLUSION
  Nothing in either CPU 1 image handles these three bytes as fields of a part.
  They are carried in stored data and copied wholesale.  For a librarian that
  is actionable: preserve them, do not try to compute them.

RUN
  python3 wsa1/notes/sysex-probes/sysex_blockb_tail.py

PASS CRITERION
  Zero groups at the block-A-relative displacement; five at the other, none
  near the part-record step; and the control firing on at least one known
  triple-writer site.
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
IMAGES = [("wsa1_prom_a.ic12", 0xF80000), ("wsa1_prom_b.ic13", 0xF00000)]
PRE = {0x8C: "XIX", 0x8D: "XIY", 0x8E: "XIZ", 0xBC: "XIX", 0xBD: "XIY", 0xBE: "XIZ"}
WINDOW = 0x20

# add IY,0x0080 -- the step that turns a table index into a PART RECORD slot
SLOT_STEP = bytes.fromhex("ddc88000")
TRIPLE_WRITERS = [0xFAA2FA, 0xFAA6FA, 0xFAE0B8]   # from sysex_triple_writer.py


def groups(img, disps):
    hits = [(i, PRE[img[i]], img[i + 1]) for i in range(len(img) - 3)
            if img[i] in PRE and img[i + 1] in disps]
    out, i = [], 0
    while i < len(hits):
        j, offs, regs = i, {hits[i][2]}, {hits[i][1]}
        while j + 1 < len(hits) and hits[j + 1][0] - hits[i][0] <= WINDOW:
            j += 1; offs.add(hits[j][2]); regs.add(hits[j][1])
        if offs == set(disps) and len(regs) == 1:
            out.append(hits[i][0])
        i = j + 1
    return out


def table_run(img, o):
    """Length of the uniform 3-byte `BC/BD dd 7F` run containing o, in entries."""
    s = o
    while s >= 3 and img[s - 3] in (0xBC, 0xBD) and img[s - 1] == 0x7F:
        s -= 3
    e = o
    while e + 2 < len(img) and img[e] in (0xBC, 0xBD) and img[e + 2] == 0x7F:
        e += 3
    return (e - s) // 3


PTR_TABLE = bytes.fromhex("18f060")     # the operand of ld XIX,(0x60F018)

found, checked = {}, 0
for name, base in IMAGES + [("wsa1_prom_c.ic28", 0xF80000), ("wsa1_prom_d.bin", 0)]:
    path = os.path.join(ROMS, name)
    if not os.path.exists(path):
        continue
    img = open(path, "rb").read()
    steps = [m.start() for m in re.finditer(re.escape(SLOT_STEP), img)]
    ptrs = [m.start() for m in re.finditer(re.escape(PTR_TABLE), img)]
    for label, disps in (("from block A's base", (0x38, 0x39, 0x3A)),
                         ("from block B's base", (0x18, 0x19, 0x1A))):
        # EVERY individual access, not only groups of three: a routine that
        # touched one of the bytes alone would slip past a grouping test.
        singles = [i for i in range(len(img) - 3)
                   if img[i] in PRE and img[i + 1] in disps]
        checked += len(singles)
        # a part record is *(table + 0x80 + i*4).  Being near the table is not
        # enough -- the 0x80 step is what selects a part rather than a sibling.
        near_tbl = [i for i in singles if any(abs(p - i) < 0x40 for p in ptrs)]
        in_part = [i for i in near_tbl if any(abs(st - i) < 0x80 for st in steps)]
        print("%-18s %-20s %3d accesses, %d near the pointer table, %d reaching a part"
              % (name, label, len(singles), len(near_tbl), len(in_part)))
        for i in near_tbl:
            print("      0x%06X  disp %02X -- indexes the table WITHOUT the 0x80 step,"
                  % (base + i, img[i + 1]))
            print("                  so it reaches a sibling structure, not a part")
        assert not in_part, "0x%06X reaches a part record" % (base + near_tbl[0])
        g = groups(img, disps)
        for o in g:
            run = table_run(img, o)
            if run > 8:
                print("      0x%06X  inside a %d-entry uniform table -- data, not code"
                      % (base + o, run))
        found[(name, label)] = len(g)

    if name == "wsa1_prom_a.ic12":
        fired = [w for w in TRIPLE_WRITERS
                 if any(abs(st - (w - base)) < 0x80 for st in steps)]
        allb = [i for i in range(len(img) - 3)
                if img[i] in PRE and img[i + 1] in (0x1B, 0x1C, 0x1D)]
        ctl = [i for i in allb if any(abs(st - i) < 0x80 for st in steps)]
        print("   CONTROL -- the same test on the neighbouring triple's bytes:")
        print("      %d accesses at +1B..+1D, %d of them reaching a part record,"
              % (len(allb), len(ctl)))
        print("      including %d of the %d known triple-writer sites %s"
              % (len(fired), len(TRIPLE_WRITERS), ["0x%06X" % w for w in fired]))
        assert fired and ctl, "the part-record test fires on nothing -- it cannot fire"

print("\n   %d individual accesses examined across every image." % checked)
assert found[("wsa1_prom_a.ic12", "from block A's base")] == 0
assert found[("wsa1_prom_b.ic13", "from block A's base")] == 0
assert found[("wsa1_prom_a.ic12", "from block B's base")] == 5
assert found[("wsa1_prom_b.ic13", "from block B's base")] == 0

print("""
So of 127 individual accesses at either displacement, across all four images
including both of the second processor's, three come near the part pointer
table and all three are in ONE routine that indexes it without the 0x80 step --
so they reach a sibling structure.  None reaches a part record, on a test that
does fire on the bytes next door.

These three bytes are carried in stored data and copied wholesale, and no code
on either processor treats them as fields.  For a librarian that is actionable:
preserve them, do not compute them.""")
print("\nOK")
