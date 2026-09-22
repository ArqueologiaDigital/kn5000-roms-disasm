#!/usr/bin/env python3
"""WHICH FIRMWARE IS THIS, IN THE INSTRUMENT'S OWN TERMS?

QUESTION IT ANSWERS

This reference has called itself a description of "operating system version
2.0" throughout, and listed version 1 as the one thing it could not reach for
want of a dump.

"Version 2" is a real designation: Felipe, who owns the hardware, reports that
the number is printed on the labels glued to the EPROMs themselves, and that is
where the name for this ROM set comes from.  What it is NOT is anything the
RUNNING instrument says -- it appears on no screen and in no message -- so it
cannot be read without opening the unit.

What the instrument reports instead is per-ROM build stamps.  It has a ROM
VERSION screen, and that screen reports THREE ROMs separately, as WSA-A, WSA-C
and WSA-D.  Those are the identifiers a reader can check with the lid on.

WHERE THE NUMBERS COME FROM
  Each program image ends with a build stamp -- the linker's source file name,
  left in the last sixteen bytes:

      wsa1_prom_a.ic12   wsaa_822 ssf
      wsa1_prom_c.ic28   wsac_230 ssf
      wsa1_prom_d.bin    wsad_54.ssf

  The byte between the name and `ssf` is 0x02 in the first two and a full stop
  in the third, so the stamp is matched on its shape and not on a literal.

  and prom_b has none, because prom_a and prom_b are two halves of ONE program.
  That is why the screen lists three entries for four images, and it is an
  independent confirmation of a structure this project established elsewhere.

  The screen's own code reads them: twenty bytes from the caption, one routine
  checks the two bytes at the end of the stamp against `sf` -- the tail of
  `.ssf` -- and another loads a byte out of the same region.

WHAT THAT MEANS FOR "VERSION 1"
  There is no single number for a reader to match.  A reader with an
  instrument can open its ROM VERSION screen and compare three numbers against
  the three below.  If they differ, they are holding something this reference
  does not describe, and they will know which of the three differs -- which is
  more useful than a single version would have been.

RUN
  python3 wsa1/notes/sysex-probes/rom_version_stamps.py

PASS CRITERION
  Three of the four images carry a stamp of the form wsa?_NNN.ssf and the
  fourth carries none; the stamps sit at the same offset in each; and the
  program contains the comparison that validates the suffix.  A stamp that
  moved, or a fourth that appeared, would mean this is a different dump.
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
IMAGES = [("wsa1_prom_a.ic12", 0xF80000, "A"), ("wsa1_prom_b.ic13", 0xF00000, None),
          ("wsa1_prom_c.ic28", 0xF80000, "C"), ("wsa1_prom_d.bin", 0x000000, "D")]
STAMP = re.compile(rb"wsa([acd])_(\d+)(.)ssf", re.S)
AT = 0x7FFF0                      # every stamp sits here, sixteen bytes from the end

print("BUILD STAMPS, one per program image")
found = {}
for name, base, letter in IMAGES:
    img = open(os.path.join(ROMS, name), "rb").read()
    m = STAMP.search(img)
    if m is None:
        print("   %-18s no stamp" % name)
        assert letter is None, "%s should carry a stamp and does not" % name
        continue
    assert letter is not None, "%s carries a stamp and should not" % name
    assert m.group(1).decode().upper() == letter, \
        "%s's stamp names the wrong ROM" % name
    assert m.start() == AT, "%s's stamp is at 0x%X, not 0x%X" % (name, m.start(), AT)
    found[letter] = m.group(2).decode()
    shown = m.group(0).decode("latin1").replace("\x02", ".")
    print("   %-18s %-14s -> the screen's WSA-%s reads %s"
          % (name, shown, letter, found[letter]))

assert sorted(found) == ["A", "C", "D"], "the set of stamped ROMs changed: %r" % found
print("""
   Four images, three stamps: prom_a and prom_b are two halves of one program,
   which is why the ROM VERSION screen has three entries and not four.""")

# the screen's own code validates the stamp
PROM_A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
SUFFIX = bytes.fromhex("d2faffff3f") + b"sf"      # cp (0xfffffa),'sf'
READ = bytes.fromhex("c2f8ffff23")                # ld C,(0xfffff8)
CAPTION = PROM_A.find(b"ROM VERSION")
s = [0xF80000 + m.start() for m in re.finditer(re.escape(SUFFIX), PROM_A)]
r = [0xF80000 + m.start() for m in re.finditer(re.escape(READ), PROM_A)]
print("   the suffix check   %s" % " ".join("0x%06X" % x for x in s))
print("   a read of the same region %s" % " ".join("0x%06X" % x for x in r))
print("   the ROM VERSION caption at 0x%06X" % (0xF80000 + CAPTION))
assert s and r and CAPTION > 0, "the version screen's machinery is not where it was"
assert min(abs(x - (0xF80000 + CAPTION)) for x in s) < 0x400, \
    "the suffix check is nowhere near the caption"

print("""
   So this reference describes WSA-A %s, WSA-C %s and WSA-D %s.  A reader can
   check all three on the instrument's own ROM VERSION screen; the archive's
   "version 2" is a label on a file set, not a number the machine reports."""
      % (found["A"], found["C"], found["D"]))
print("\nOK")
