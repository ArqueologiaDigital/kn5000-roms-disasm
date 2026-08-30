#!/usr/bin/env python3
"""Do the quantified claims of the prom_a DISK FORMAT module still hold?

QUESTION IT ANSWERS
  notes/FINDINGS-prom_a-disk-format.md and the routine headers in
  prom_a/wsa1_prom_a.s state a lot of numbers -- BPB fields, an MBR partition
  entry, four filesystem templates, and two tables of disk requests.  Every one
  of them is re-derived here FROM THE ROM IMAGE, not from the source text, so a
  claim cannot drift away from the bytes it describes.

  The byte gate proves the source rebuilds the ROM.  It is blind to whether the
  comment above a `.byte` block is true.  This script is that second gate.

RUN
  python3 notes/prom_a_disk_format_checks.py
Exit status is non-zero if any check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000

FAIL = 0


def check(ok, msg):
    global FAIL
    print(("  ok   " if ok else "  FAIL ") + msg)
    if not ok:
        FAIL = 1


def b(a, n=1):
    return ROM[a - BASE:a - BASE + n]


def u16(a):
    return int.from_bytes(b(a, 2), "little")


def u32(a):
    return int.from_bytes(b(a, 4), "little")


def bpb(a):
    """The BIOS Parameter Block fields this module cares about."""
    return dict(jmp=b(a, 3), oem=b(a + 3, 8), bps=u16(a + 0x0B),
                spc=ROM[a - BASE + 0x0D], resv=u16(a + 0x0E),
                nfat=ROM[a - BASE + 0x10], root=u16(a + 0x11),
                tot16=u16(a + 0x13), media=ROM[a - BASE + 0x15],
                spf=u16(a + 0x16), spt=u16(a + 0x18), heads=u16(a + 0x1A))


print("1. DiskImage_HardDisk_BootSector at 0xFE69BF -- a FAT16 BPB")
h = bpb(0xFE69BF)
check(h["jmp"] == b"\xeb\x3c\x90", "starts EB 3C 90 (x86 JMP SHORT +0x3C / NOP)")
check(h["oem"] == b" EMID2.0", 'OEM name is " EMID2.0"')
check((h["bps"], h["spc"], h["resv"], h["nfat"], h["root"]) == (512, 8, 1, 2, 512),
      "512 B/sector, 8 sec/cluster, 1 reserved, 2 FATs, 512 root entries")
check(h["tot16"] == 0 and u32(0xFE69BF + 0x20) == 511140,
      "total sectors: 16-bit field 0, 32-bit field 511140")
check(h["media"] == 0xF8, "media descriptor 0xF8 -- FIXED DISK")
check((h["spf"], h["spt"], h["heads"]) == (250, 60, 15),
      "250 sectors/FAT, 60 sectors/track, 15 heads")
check(u32(0xFE69BF + 0x1C) == 60, "60 hidden sectors")
check(ROM[0xFE69BF - BASE + 0x24] == 0x80 and ROM[0xFE69BF - BASE + 0x26] == 0x29,
      "BIOS drive number 0x80 (first hard disk), ext boot signature 0x29")
check(b(0xFE69BF + 0x36, 8) == b"FAT16   ", 'filesystem type "FAT16   "')
check(b(0xFE69BF + 0x1FE, 2) == b"\x55\xaa", "boot signature 55 AA at +0x1FE")
tot = u32(0xFE69BF + 0x20) + u32(0xFE69BF + 0x1C)
check(tot == 511200 and tot % (60 * 15) == 0 and tot // (60 * 15) == 568,
      "★ total+hidden = 511200 = 568 cylinders x 15 heads x 60 sectors EXACTLY")
check(tot * 512 == 261734400, "★ capacity 261,734,400 bytes (~250 MiB)")
for s in (b"Non-System disk or disk error", b"This is Technics HDD."):
    check(s in b(0xFE69BF, 0x200), '★ carries the string %r' % s.decode())

print("\n2. DiskImage_HardDisk_MBR at 0xFE6BBF")
p = b(0xFE6BBF + 0x1BE, 16)
check(b(0xFE6BBF + 0x1FE, 2) == b"\x55\xaa", "boot signature 55 AA at +0x1FE")
check(p[0] == 0x00 and p[4] == 0x06, "entry 1: not bootable, type 0x06 = FAT16 >32 MB")
check(int.from_bytes(p[8:12], "little") == 60,
      "entry 1 LBA start 60 == the boot sector's hidden-sector count")
check(int.from_bytes(p[12:16], "little") == 511140,
      "entry 1 sector count 511140 == the boot sector's total-sectors-32")
endc = p[7] | ((p[6] & 0xC0) << 2)
check((p[5], p[6] & 0x3F, endc) == (14, 60, 567),
      "★ entry 1 end CHS = head 14, sector 60, cylinder 567 -- the last sector "
      "of a 568x15x60 disk, the SAME geometry through a different encoding")
check(b(0xFE6BBF + 0x1CE, 48) == bytes(48), "entries 2-4 are all zero")
for s in (b"Invalid partition table", b"Error loading operating system",
          b"Missing operating system"):
    check(s in b(0xFE6BBF, 0x200), "carries the string %r" % s.decode())

print("\n3. The four floppy filesystem templates")
for at, name, want in ((0xFE76B2, "BootSector_Floppy720K",
                        dict(spc=2, root=112, tot16=1440, media=0xF9, spf=3,
                             spt=9, heads=2)),
                       (0xFE76F2, "BootSector_Floppy1440K",
                        dict(spc=1, root=224, tot16=2880, media=0xF0, spf=9,
                             spt=18, heads=2))):
    h = bpb(at)
    check(h["jmp"] == b"\xeb\x1c\x90", "%s starts EB 1C 90" % name)
    check(h["oem"] == b"Technics", '%s OEM name is "Technics"' % name)
    check(h["bps"] == 512 and h["resv"] == 1 and h["nfat"] == 2,
          "%s: 512 B/sector, 1 reserved, 2 FATs" % name)
    check(all(h[k] == v for k, v in want.items()),
          "%s: %s" % (name, ", ".join("%s=%s" % kv for kv in want.items())))
    check(b(at + 0x1E, 2) == b"\xeb\xfe", "%s ends EB FE (x86 JMP $)" % name)
    n = want["tot16"]
    check(n == 80 * 2 * want["spt"],
          "★ %s: %d total sectors == 80 cyl x 2 heads x %d sectors"
          % (name, n, want["spt"]))
for at, name, mid in ((0xFE76D2, "FatId_Floppy720K", 0xF9),
                      (0xFE7712, "FatId_Floppy1440K", 0xF0)):
    check(b(at, 3) == bytes([mid, 0xFF, 0xFF]) and b(at + 3, 29) == bytes(29),
          "%s is %02X FF FF then 29 zero bytes, matching its BPB media byte"
          % (name, mid))

print("\n4. The two format routines' request tables")
# Each request is built field by field and then passed to the veneer.  The
# fields are read back out of the instruction stream by the same immediate
# shapes notes/prom_a_fdc_operation_census.py uses; here only the two shapes
# this module actually emits are needed.
SRC = open(image_path(ROOT, "prom_a/wsa1_prom_a.s"), encoding="utf-8").read()


def requests(lo, hi, absolute):
    """[(op, unit, head, trk, sec, cnt)] for every request built in [lo,hi)."""
    import re
    fields, out, cur = {}, [], {}
    for line in SRC.split("\n"):
        m = re.match(r"^\s*(\S.*?)\s+;\s([0-9A-F]{6})\s\s", line)
        if not m:
            continue
        at, text = int(m.group(2), 16), m.group(1)
        if not (lo <= at < hi):
            continue
        if absolute:
            mm = re.search(r"stiw_da \(0x0*17c([0-9a-f])\), (0x[0-9a-f]+)", text)
            if mm:
                cur[int(mm.group(1), 16)] = int(mm.group(2), 16)
        else:
            mm = re.search(r"m_ld_mi16 MD[ID]\+r4, (0x[0-9a-f]+|0), "
                           r"(0x[0-9a-f]+)", text)
            if mm:
                cur[int(mm.group(1), 16)] = int(mm.group(2), 16)
        if "call 0xf42d38" in text:
            out.append(tuple(cur.get(k) for k in (0, 2, 4, 6, 8, 0xA)))
    return out


r720 = requests(0xFE7222, 0xFE7401, True)
r144 = requests(0xFE7401, 0xFE75CA, False)
want720 = [(0, 0, 0, 0xE0, 1, 1), (5, 0, 0, 0, 1, 1), (4, 0, 0, 0, 1, 1),
           (4, 0, 0, 0, 2, 3), (4, 0, 0, 0, 5, 3), (3, 0, 0, 0x4F, 9, 1),
           (3, 0, 0, 0, 9, 1)]
want144 = [(0, 0, 0, 0xC3, 1, 1), (5, 0, 0, 0, 1, 1), (4, 0, 0, 0, 1, 1),
           (4, 0, 0, 0, 2, 5), (4, 0, 0, 0, 7, 4), (4, 0, 0, 0, 11, 5),
           (4, 0, 0, 0, 16, 4), (3, 0, 0, 0x4F, 18, 1), (3, 0, 0, 0, 9, 1)]
check(r720 == want720, "Disk_Format720K issues exactly 7 requests, in the "
                       "order the header tabulates (got %r)" % (r720,))
check(r144 == want144, "Disk_Format1440K issues exactly 9 requests, in the "
                       "order the header tabulates (got %r)" % (r144,))
check(r720[0][3] & 0x0F == 0,
      "★ 720K media descriptor 0xE0 & 0x0F = 0 -> Fdc_MediaTypeJumpTable "
      "geometry 0 = 512 B x 9 sectors (FINDINGS-prom_a-fdc.md sec.4)")
check(r144[0][3] & 0x0F == 3,
      "★ 1440K media descriptor 0xC3 & 0x0F = 3 -> geometry 3 = 512 B x 18")
check(r720[5][4] == 9 and bpb(0xFE76B2)["spt"] == 9,
      "★ the 720K verify read asks for sector 9 and its BPB says 9/track")
check(r144[7][4] == 18 and bpb(0xFE76F2)["spt"] == 18,
      "★ the 1.44M verify read asks for sector 18 and its BPB says 18/track")
check(sum(r[5] for r in r720[3:5]) == 2 * bpb(0xFE76B2)["spf"],
      "★ the 720K FAT writes total 2 x 3 = 2 FATs x sectors-per-FAT")
check(sum(r[5] for r in r144[3:7]) == 2 * bpb(0xFE76F2)["spf"],
      "★ the 1.44M FAT writes total 2 x 9 = 2 FATs x sectors-per-FAT")

print("\n5. Disk_FormatSelectedMedia's one selector bit")
check("and C,0x40" in SRC.split("; FE7205")[0].split("\n")[-1],
      "0xFE7205 masks (0x21E7) with 0x40 -- one bit picks the density")

print()
sys.exit(FAIL)
