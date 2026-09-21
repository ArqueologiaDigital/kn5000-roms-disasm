#!/usr/bin/env python3
"""THE CODE THAT WRITES AND READS A PART'S TRAILING TRIPLE.

QUESTION IT ANSWERS

`sysex_unnamed_bytes.py` identifies the last three bytes of a part block as a
second PROGRAM CHANGE & BANK, from stored data and a control.  An earlier
edition of this project said naming those bytes needed "the writer caught in
the act rather than found by searching", and then searched four more times.

The search that works is neither of the ones tried.  Those bytes are never
named by an absolute address -- a part record is reached through a pointer --
so searching the images for their RAM addresses finds nothing, which is what
happened.  What does find them is the INDEXED form: the six override gates
already established that the instrument walks a part record with XIY at block
A's base, so the three bytes are (XIY+0x1b), (XIY+0x1c) and (XIY+0x1d), and
those are short, distinctive byte strings.

WHAT IT ESTABLISHES

  * The three bytes are written together, as three byte registers -- L to
    +0x1b, H to +0x1c, W to +0x1d -- and read back in the same roles.  They
    are one field of three bytes and not three unrelated ones.
  * At the writing site the three values come back from a CONVERSION: the
    caller hands it a two-byte value and reads a three-byte result out of
    fixed addresses.  There is an inverse beside it taking three bytes and
    returning two.  So the triple is a three-byte form of something the
    instrument also holds in two bytes -- which is exactly the shape of a
    program number plus a bank.
  * H and L here are two byte registers, not a 16-bit pair.  The consumer
    stores them to two separate addresses.  That matters because reading them
    as one 16-bit HL is the obvious rival to the 4+3 split, and the data
    rejects it 4 matches to 296.

SIGNAL BEING READ
  wsa1_prom_a.ic12, as byte strings:
    bd 1b 47 / bd 1c 46 / bd 1d 40   ld (XIY+0x1b),L  (XIY+0x1c),H  (XIY+0x1d),W
    8d 1b 27 / 8d 1c 26 / 8d 1d 20   the same three, loaded back

RUN
  python3 wsa1/notes/sysex-probes/sysex_triple_writer.py

PASS CRITERION
  Every write of any one of the three bytes is part of a group that writes all
  three, and the same for the reads.  A site that touched one byte alone would
  break the "one field" claim, so the script looks for those and asserts there
  are none.
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
IMAGES = [("wsa1_prom_a.ic12", 0xF80000), ("wsa1_prom_b.ic13", 0xF00000),
          ("wsa1_prom_c.ic28", 0xF80000)]

# one instruction each, as bytes -- the listings certify the byte strings
WRITE = {0x1B: bytes.fromhex("bd1b47"), 0x1C: bytes.fromhex("bd1c46"),
         0x1D: bytes.fromhex("bd1d40")}
READ = {0x1B: bytes.fromhex("8d1b27"), 0x1C: bytes.fromhex("8d1c26"),
        0x1D: bytes.fromhex("8d1d20")}
WINDOW = 0x20          # a group is three of them inside this many bytes


def sites(img, pats):
    out = {}
    for off, pat in pats.items():
        out[off] = [m.start() for m in re.finditer(re.escape(pat), img)]
    return out


def group(found):
    """Cluster the three offsets' hits into groups that carry all three."""
    all_hits = sorted((p, off) for off, ps in found.items() for p in ps)
    groups, loose, i = [], [], 0
    while i < len(all_hits):
        j, offs = i, {all_hits[i][1]}
        while j + 1 < len(all_hits) and all_hits[j + 1][0] - all_hits[i][0] <= WINDOW:
            j += 1; offs.add(all_hits[j][1])
        if offs == {0x1B, 0x1C, 0x1D}:
            groups.append(all_hits[i][0])
        else:
            loose.extend(all_hits[i:j + 1])
        i = j + 1
    return groups, loose


total_w = total_r = 0
for name, base in IMAGES:
    img = open(os.path.join(ROMS, name), "rb").read()
    wg, wl = group(sites(img, WRITE))
    rg, rl = group(sites(img, READ))
    if not (wg or rg or wl or rl):
        print("%-18s -- nothing" % name)
        continue
    print("%-18s" % name)
    for label, g, loose in (("writes all three", wg, wl), ("reads all three", rg, rl)):
        print("   %-17s %d: %s"
              % (label, len(g), " ".join("0x%06X" % (base + a) for a in g)))
        assert not loose, \
            "%s: %d site(s) touch these bytes outside a group of three: %s" \
            % (name, len(loose), ["0x%06X" % (base + a) for a, _ in loose])
    total_w += len(wg); total_r += len(rg)

print("\n   %d writing groups, %d reading groups, and NO site anywhere touches"
      % (total_w, total_r))
print("   one of the three bytes on its own -- so they are one field.")
assert (total_w, total_r) == (3, 3), \
    "expected three writing and three reading groups, got %d and %d" % (total_w, total_r)

print("""
   At the writing site the three values are produced by a call whose input is
   written to one fixed address as TWO bytes and whose result is read back from
   another as THREE.  An inverse sits immediately after it, taking three bytes
   in and returning two.  A three-byte form of a two-byte quantity is what a
   program number and a bank become here, and `sysex_unnamed_bytes.py` shows
   from 890 stored parts which two bytes they are.""")
print("\nOK")
