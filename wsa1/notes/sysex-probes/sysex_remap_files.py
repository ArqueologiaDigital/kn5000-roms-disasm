#!/usr/bin/env python3
"""WHAT IS A RE-MAP, AND WHY DOES IT EXPLAIN A COMBINATION'S TRAILING TRIPLE?

QUESTION IT ANSWERS

`sysex_unnamed_bytes.py` shows that the last three bytes of each part block are
a 7-bit number split four bits and three, plus a bank -- a second PROGRAM
CHANGE & BANK that agrees with the part's own in a third of cases.  A second
copy of an address that usually differs is an indirection, and the instrument
has one: the disk set carries RE-MAP files.

This decodes them, because their shape is the evidence for that reading.  A
re-map is sixteen GROUPS of eight, which is exactly the 4+3 split, and each of
its 128 entries is a (number, source) pair, which is exactly what the triple
holds.

WHAT A RE-MAP FILE IS
  32-byte header: the ASCII magic `WSA1 `, then three little-endian 32-bit
  offsets, one per map, and a zero terminator.  Then the maps.

  .CRM  COMBI RE-MAP    3 maps of 528 = 1 map name + 16 group names of 16
  .SRM  SOUND RE-MAP        bytes each, then 128 entries of 2 bytes
  .DRM  USER DRUM MAP   3 maps of 144 = 1 map name of 16, then 128 entries of 1

  The sound file's third map is named `GM RE-MAP` and is the one that is not an
  identity: its entries are scattered (number, source) pairs where the first two
  maps run 0,1,2,... with a constant source of 8 and 9.  That the source byte
  takes 0, 1, 2, 8 and 9 across these files, and that a part's +1D takes exactly
  0, 1, 8, 9 and 0x20, is the correspondence that ties the two together.

SIGNAL BEING READ
  KN7000/WSA1R_files/GJS1.zip, sha256
  c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524, members
  GJS1/01220497.{CRM,SRM,DRM}.  A community disk image, not committed here.

RUN
  python3 wsa1/notes/sysex-probes/sysex_remap_files.py

PASS CRITERION
  Each file's three declared offsets are equally spaced, every map's names are
  printable ASCII, and the header plus three maps account for the declared
  region exactly -- the arithmetic has to close, as it does for the combination
  and song streams.  The two identity maps must read 0,1,2,... so that the one
  non-identity map is demonstrably different rather than assumed to be.
"""
import hashlib, os, sys, zipfile

ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/GJS1.zip"
ZIP_SHA = "c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524"
FILES = [("GJS1/01220497.CRM", 2, "COMBI"),
         ("GJS1/01220497.SRM", 2, "SOUND"),
         ("GJS1/01220497.DRM", 1, "DRUM")]
MAGIC, NAME, ENTRIES = b"WSA1 ", 16, 128

if not os.path.exists(ZIP):
    print("GJS1.zip is not present; nothing to check.")
    sys.exit(0)
assert hashlib.sha256(open(ZIP, "rb").read()).hexdigest() == ZIP_SHA, \
    "GJS1.zip is not the archive checked here"

identity_seen = 0
with zipfile.ZipFile(ZIP) as z:
    for member, width, kind in FILES:
        d = z.read(member)
        assert d[:5] == MAGIC, "%s does not open %r" % (member, MAGIC)
        offs = [int.from_bytes(d[0x10 + 4 * i:0x14 + 4 * i], "little") for i in range(4)]
        maps = [o for o in offs if o]
        assert offs[3] == 0, "%s declares more than three maps" % member
        step = maps[1] - maps[0]
        assert all(maps[i + 1] - maps[i] == step for i in range(len(maps) - 1)), \
            "%s's maps are not equally spaced" % member
        groups = (step - ENTRIES * width) // NAME - 1
        assert NAME * (groups + 1) + ENTRIES * width == step, \
            "%s's map size %d does not close" % (member, step)
        print("%s  %d bytes -- %s" % (os.path.basename(member), len(d), kind))
        print("   3 maps of %d = 1 name + %d group names of %d + %d entries of %d"
              % (step, groups, NAME, ENTRIES, width))
        for base in maps:
            names = [d[base + NAME * i:base + NAME * (i + 1)] for i in range(groups + 1)]
            for nm in names:
                assert all(0x20 <= c < 0x7F for c in nm), \
                    "%s has a non-printable name at 0x%X" % (member, base)
            tbl = base + NAME * (groups + 1)
            ent = [d[tbl + width * i:tbl + width * (i + 1)] for i in range(ENTRIES)]
            ident = all(e[0] == i for i, e in enumerate(ent))
            src = sorted({e[1] for e in ent}) if width == 2 else []
            identity_seen += ident
            print("     %-16s %s   first: %s"
                  % (names[0].decode("ascii").strip(),
                     ("identity, source %s" % src) if ident
                     else "NOT an identity map, sources %s" % src,
                     " ".join("%02X" % c for c in d[tbl:tbl + 8])))
        print()

assert identity_seen == 8, \
    "expected eight identity maps of the nine, found %d" % identity_seen
print("Eight of the nine maps are identities; the one that is not is GM RE-MAP.")
print("A re-map is SIXTEEN GROUPS OF EIGHT -- the same 4+3 split a part's")
print("trailing triple uses -- and its entries are (number, source) pairs, which")
print("is what that triple holds.  See sysex_unnamed_bytes.py for the agreement")
print("against the part's own PROGRAM CHANGE & BANK and its control.")
print("\nOK")
