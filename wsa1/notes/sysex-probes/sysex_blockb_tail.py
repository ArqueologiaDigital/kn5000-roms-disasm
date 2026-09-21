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

  * From block A's base: ZERO groups touch all three, in either image.
  * From block B's base: five groups exist, and none of them is a part record.
    Two are inside a 64-entry uniform three-byte TABLE, which the reference
    disassembler refuses to decode as instructions at all.  The other three do
    not reach a part record.

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


found = {}
for name, base in IMAGES:
    img = open(os.path.join(ROMS, name), "rb").read()
    steps = [m.start() for m in re.finditer(re.escape(SLOT_STEP), img)]
    for label, disps in (("from block A's base", (0x38, 0x39, 0x3A)),
                         ("from block B's base", (0x18, 0x19, 0x1A))):
        g = groups(img, disps)
        print("%-18s %-20s %d group(s) touching all three"
              % (name, label, len(g)))
        for o in g:
            near = any(abs(st - o) < 0x80 for st in steps)
            run = table_run(img, o)
            print("      0x%06X  part-record step nearby: %-3s  inside a %d-entry table: %s"
                  % (base + o, "YES" if near else "no", run, "yes" if run > 8 else "no"))
            assert not near, "0x%06X reaches a part record after all" % (base + o)
        found[(name, label)] = len(g)

    if name == "wsa1_prom_a.ic12":
        # the control: the discriminator must fire on a known part-record writer
        fired = [w for w in TRIPLE_WRITERS
                 if any(abs(st - (w - base)) < 0x80 for st in steps)]
        print("   CONTROL -- the same test on the %d known triple-writer sites: "
              "fires on %d of them %s"
              % (len(TRIPLE_WRITERS), len(fired), ["0x%06X" % w for w in fired]))
        assert fired, "the part-record test fires on nothing, so it cannot fire at all"

assert found[("wsa1_prom_a.ic12", "from block A's base")] == 0
assert found[("wsa1_prom_b.ic13", "from block A's base")] == 0
assert found[("wsa1_prom_a.ic12", "from block B's base")] == 5
assert found[("wsa1_prom_b.ic13", "from block B's base")] == 0

print("""
So no code in either image handles +0x18, +0x19 and +0x1A as fields of a part.
They are carried in stored data and copied wholesale, which is the useful thing
for a librarian to know: preserve them, do not compute them.""")
print("\nOK")
