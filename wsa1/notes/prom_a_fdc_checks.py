#!/usr/bin/env python3
"""Re-derive, from the ROM bytes, every quantified claim the FDC module makes.

QUESTION IT ANSWERS: "prom_a's 0xFE54EC-0xFE594B / 0xFE5A41-0xFE6850 headers and
notes/FINDINGS-prom_a-fdc.md say `15 opcodes accepted and 17 rejected, the same
32-value truth table as MAME's uPD765 decoder`, `37 entries in four tables that
tile 74 bytes`, `three geometries`, `these eight status bits map to these eight
error codes` -- are they still true of the ROM?"

The byte gate proves the source rebuilds the ROM and is blind to every one of
those sentences.  This is the other half, and it is the artefact behind the
identification of the device: run it before quoting any number from that note.

    python3 notes/prom_a_fdc_checks.py        # exits non-zero on any failure
    python3 notes/prom_a_fdc_checks.py -v     # print every check
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
MAME_CPP = os.path.join(ROOT, os.pardir, "mame", "src", "devices", "machine",
                        "upd765.cpp")
FAILS, RAN = [], []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def u16(addr):
    return a(addr, 2)[0] | (a(addr, 2)[1] << 8)


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


def hexs(addr, n):
    return " ".join("%02x" % x for x in a(addr, n))


# =========================================================================
# 1.  THE FOUR JUMP TABLES -- entry counts from the ROM's own bounds, and the
#     tiling of 0xFE6E3A-0xFE6E83.
# =========================================================================
# Each indexer is  cp WA,<bound> / jr <out of range> / add WA,WA /
#                  lda XIX,<table> / ld WA,(XIX+WA) / lda XIX,<base> / jp XIX+WA
# The bound is read out of the `cp` and the two addresses out of the two `lda`s.
TABLES = [
    ("media-type", 0xFE5668, 2, 0xFE566E, 0xFE5678),   # cp WA,5   (short form)
    ("validate",   0xFE572A, 4, 0xFE5732, 0xFE573C),   # cp WA,0x000B
    ("opcode",     0xFE5D10, 2, 0xFE5D16, 0xFE5D20),   # cp WA,6   (short form)
    ("operation",  0xFE6788, 4, 0xFE6790, 0xFE679A),
]
layout = []
for tag, cpaddr, cplen, lda_tab, lda_base in TABLES:
    if cplen == 2:                       # d8 <D8+n>  : cp WA,n, n in 0..7
        check("table %s: bound is the short `cp WA,#` form" % tag,
              a(cpaddr, 1) == b"\xd8" and 0xD8 <= a(cpaddr + 1, 1)[0] <= 0xDF,
              hexs(cpaddr, 2))
        bound = a(cpaddr + 1, 1)[0] - 0xD8
    else:                                # d8 cf lo hi : cp WA,imm16
        check("table %s: bound is the `cp WA,imm16` form" % tag,
              a(cpaddr, 2) == b"\xd8\xcf", hexs(cpaddr, 4))
        bound = u16(cpaddr + 2)
    check("table %s: `lda XIX,imm32` opcode at the table site" % tag,
          a(lda_tab, 1) == b"\xf2" and a(lda_tab + 4, 1) == b"\x34",
          hexs(lda_tab, 5))
    check("table %s: `lda XIX,imm32` opcode at the base site" % tag,
          a(lda_base, 1) == b"\xf2" and a(lda_base + 4, 1) == b"\x34",
          hexs(lda_base, 5))
    tab = int.from_bytes(a(lda_tab + 1, 3), "little") | 0xF00000
    base = int.from_bytes(a(lda_base + 1, 3), "little") | 0xF00000
    layout.append((tag, tab, base, bound + 1))

for tag, tab, base, n in layout:
    check("table %s: %d entries, from the ROM's own bound" % (tag, n), n > 0)
layout.sort(key=lambda r: r[1])
check("the four tables are 6 + 12 + 7 + 12 entries",
      [r[3] for r in layout] == [6, 12, 7, 12], str(layout))
check("the four tables total 37 entries / 74 bytes",
      sum(r[3] for r in layout) == 37 and sum(r[3] for r in layout) * 2 == 74)
check("the four tables start at 0xFE6E3A", layout[0][1] == 0xFE6E3A,
      "0x%06X" % layout[0][1])
tile_ok, cur = True, layout[0][1]
for tag, tab, base, n in layout:
    if tab != cur:
        tile_ok = False
    cur = tab + 2 * n
check("the four tables TILE with no gap and no overlap", tile_ok,
      str([(t, "0x%06X" % x, n) for t, x, _, n in layout]))
check("the tiling ends at 0xFE6E84 (exclusive)", cur == 0xFE6E84,
      "0x%06X" % cur)

targets = {}
for tag, tab, base, n in layout:
    targets[tag] = [base + u16(tab + 2 * i) for i in range(n)]
check("operation table: 12 arms 5 bytes apart from 0xFE67A4",
      targets["operation"] == [0xFE67A4 + 5 * i for i in range(12)],
      str(["0x%06X" % x for x in targets["operation"]]))
check("opcode-validity table: 7 entries, each 0xFE5D2A or 0xFE5D2D",
      all(x in (0xFE5D2A, 0xFE5D2D) for x in targets["opcode"]),
      str(["0x%06X" % x for x in targets["opcode"]]))

# =========================================================================
# 2.  THE OPCODE ACCEPTANCE SET -- simulated from the ROM's own constants, and
#     compared against MAME's uPD765 command decoder.
# =========================================================================
check("classifier masks the opcode with 0x1F", a(0xFE5CED, 3) == b"\xc9\xcc\x1f",
      hexs(0xFE5CED, 3))
eq1, eq2 = u16(0xFE5CF4), u16(0xFE5CFA)
hi_range, lo_range = u16(0xFE5D00), a(0xFE5D05, 1)[0] - 0xD8
sub = u16(0xFE5D0A)
check("classifier's two equality tests are 0x1D and 0x19",
      (eq1, eq2) == (0x1D, 0x19), "0x%02X 0x%02X" % (eq1, eq2))
check("classifier's accepted run is 2..0x0A",
      (lo_range, hi_range) == (2, 0x0A), "%d..0x%02X" % (lo_range, hi_range))
check("classifier subtracts 0x0B before indexing the table", sub == 0x0B,
      "0x%02X" % sub)

fw = set()
for c in range(0x100):
    v = c & 0x1F
    if v in (eq1, eq2) or (lo_range <= v <= hi_range):
        ok = True
    else:
        i = v - sub
        ok = (0 <= i < layout[2][3]) and targets["opcode"][i] == 0xFE5D2A
    if ok:
        fw.add(v)
check("firmware accepts exactly 15 of the 32 opcode values", len(fw) == 15,
      str(sorted("0x%02X" % x for x in fw)))
check("firmware's accepted set is {02..0A, 0C, 0D, 0F, 11, 19, 1D}",
      fw == set(range(2, 0x0B)) | {0x0C, 0x0D, 0x0F, 0x11, 0x19, 0x1D},
      str(sorted(fw)))
check("firmware REJECTS 0x13, so Fdc_IssueCommand's CONFIGURE arm is unreachable",
      0x13 not in fw)

try:
    txt = open(MAME_CPP).read()
    i = txt.index("int upd765_family_device::check_command()")
    body = txt[i:txt.index("\n}\n", i)]
    exact, masked = set(), set()
    part = body.split("switch(command[0] & 0x1f)")
    for m in re.finditer(r"case 0x([0-9a-f]{2}):", part[0]):
        exact.add(int(m.group(1), 16))
    for m in re.finditer(r"case 0x([0-9a-f]{2}):", part[1]):
        masked.add(int(m.group(1), 16))
    mame = {v for v in range(0x20) if v in exact or v in masked}
    check("MAME's uPD765 decoder accepts 15 of the 32 values", len(mame) == 15,
          str(sorted("0x%02X" % x for x in mame)))
    check("★ the two 32-value truth tables are IDENTICAL", fw == mame,
          "firmware-only %s  mame-only %s"
          % (sorted(fw - mame), sorted(mame - fw)))
except (OSError, ValueError) as e:
    print("SKIP  MAME upd765.cpp cross-check (%s)" % type(e).__name__)

# =========================================================================
# 3.  THE THREE GEOMETRIES -- 30 immediates, read back from the ROM.
# =========================================================================
GEOM = {
    "0/4/5": (0xFE583E, dict(N=2, STP=1, EOT=0x09, SC=0x09, GPL=0x1B,
                             GPLF=0x54, LASTCYL=0x4F, CYLS=0x50, SPT=9,
                             SPT1=0x0A)),
    "2":     (0xFE586E, dict(N=3, STP=1, EOT=0x08, SC=0x08, GPL=0x53,
                             GPLF=0x74, LASTCYL=0x4C, CYLS=0x4D, SPT=8,
                             SPT1=0x09)),
    "3":     (0xFE589E, dict(N=2, STP=1, EOT=0x12, SC=0x12, GPL=0x1B,
                             GPLF=0x6C, LASTCYL=0x4F, CYLS=0x50, SPT=0x12,
                             SPT1=0x13)),
}
for tag, (base, want) in GEOM.items():
    # ld (Xrr),#imm8 is `b0..b5 00 <imm>`; geometry 3 writes SC as
    # `bb 0a 00 <imm>` (ld (XHL+0x0a),#) instead, which is 4 bytes.
    off = 0
    got = {}
    order = ["N", "STP", "EOT", "SC", "GPL", "GPLF"]
    for field in order:
        op = a(base + off, 1)[0]
        if op == 0xBB:                                   # (XHL+d8),#
            got[field] = a(base + off + 3, 1)[0]
            off += 4
        else:
            got[field] = a(base + off + 2, 1)[0]
            off += 3
    for field, addr in (("LASTCYL", 0x605AEF), ("CYLS", 0x605AF1),
                        ("SPT", 0x605AF5), ("SPT1", 0x605AF7)):
        check("geometry %s: %s is stored to 0x%06X" % (tag, field, addr),
              a(base + off, 1) == b"\xf2"
              and int.from_bytes(a(base + off + 1, 3), "little") == addr,
              hexs(base + off, 7))
        got[field] = u16(base + off + 5)
        off += 7
    for k in want:
        check("geometry %s: %s = 0x%02X" % (tag, k, want[k]),
              got.get(k) == want[k], "got 0x%02X" % got.get(k, 0xFF))
    check("geometry %s: sectors-per-track + 1 really is the EOT bound" % tag,
          got["SPT1"] == got["SPT"] + 1)
    check("geometry %s: cylinder count is last cylinder + 1" % tag,
          got["CYLS"] == got["LASTCYL"] + 1)
cap = {}
for tag, (base, w) in GEOM.items():
    cap[tag] = 2 * w["CYLS"] * w["SPT"] * (128 << w["N"])
check("geometry 0/4/5 is 720 KB", cap["0/4/5"] == 2 * 80 * 9 * 512, str(cap))
check("geometry 2 is 1.2 MB (77 x 2 x 8 x 1024)", cap["2"] == 2 * 77 * 8 * 1024)
check("geometry 3 is 1.44 MB", cap["3"] == 2 * 80 * 18 * 512)

# =========================================================================
# 4.  THE STATUS-BIT -> ERROR-CODE MAP.
# =========================================================================
# ST0: `cd 33 <bit> / 66 03 / 27 <code>`      (bit set -> ld L,code)
ST0 = [(0xFE5B90, 3, 0x31), (0xFE5B98, 4, 0x32)]
for addr, bit, code in ST0:
    check("ST0 bit %d -> 0x%02X" % (bit, code),
          a(addr, 3) == bytes([0xCD, 0x33, bit]) and a(addr + 5, 2) == bytes([0x27, code]),
          hexs(addr, 7))
# ST1: `cd 33 <bit> / 66 09 / 0b <code> 00`
ST1 = [(0xFE5BA3, 0, 0x35), (0xFE5BB1, 1, 0x2F), (0xFE5BBF, 2, 0x33),
       (0xFE5BCD, 4, 0x34), (0xFE5BDB, 5, 0x36), (0xFE5BE9, 7, 0x37)]
for addr, bit, code in ST1:
    check("ST1 bit %d -> 0x%02X" % (bit, code),
          a(addr, 3) == bytes([0xCD, 0x33, bit])
          and a(addr + 5, 3) == bytes([0x0B, code, 0x00]), hexs(addr, 8))
check("ST1's TWO UNDEFINED bits (3 and 6) are not tested",
      {b for _, b, _ in ST1} == {0, 1, 2, 4, 5, 7})
check("the ST0/ST1 decoder ends with the catch-all code 0x08",
      a(0xFE5BF7, 3) == b"\x0b\x08\x00", hexs(0xFE5BF7, 3))
# ST3: `c7 f9 33 <bit> / <66|6e> 08 / 0b <code> 00`
ST3 = [(0xFE669B, 7, 0x66, 0x32), (0xFE66A9, 5, 0x6E, 0x31),
       (0xFE66B7, 6, 0x66, 0x2F)]
for addr, bit, sense, code in ST3:
    check("ST3 bit %d (%s) -> 0x%02X"
          % (bit, "set" if sense == 0x66 else "clear", code),
          a(addr, 4) == bytes([0xC7, 0xF9, 0x33, bit])
          and a(addr + 4, 1) == bytes([sense])
          and a(addr + 6, 3) == bytes([0x0B, code, 0x00]), hexs(addr, 9))
check("★ ST3 and ST0/ST1 use the SAME code for not-ready, fault and read-only",
      {c for _, _, _, c in ST3} == {0x31, 0x32, 0x2F})

# =========================================================================
# 5.  THE COMMAND-PHASE ENCODER.
# =========================================================================
check("Fdc_IssueCommand: the CONFIGURE arm tests for 0x13", u16(0xFE5C3E) == 0x13,
      hexs(0xFE5C3B, 5))
check("Fdc_IssueCommand: SENSE INTERRUPT STATUS arm tests for 0x08",
      a(0xFE5C65, 1) == b"\x08", hexs(0xFE5C62, 4))
check("Fdc_IssueCommand: SPECIFY arm tests for 0x03 and is taken BEFORE the "
      "drive byte is built", a(0xFE5C6B, 1) == b"\x03"
      and a(0xFE5C73, 1) == b"\xf2", hexs(0xFE5C68, 6))
check("Fdc_IssueCommand: SEEK arm tests for 0x0F", u16(0xFE5CBE) == 0x0F,
      hexs(0xFE5CBC, 4))
check("Fdc_IssueCommand: FORMAT TRACK arm tests for 0x4D", u16(0xFE5CC4) == 0x4D,
      hexs(0xFE5CC2, 4))
check("Fdc_IssueCommand: RECALIBRATE (7) and SENSE DRIVE STATUS (4) send no "
      "further byte", a(0xFE5CC8, 2) == b"\xd8\xdf" and a(0xFE5CCC, 2) == b"\xd8\xdc",
      hexs(0xFE5CC8, 6))
check("Fdc_IssueCommand: READ ID arm tests for 0x4A", u16(0xFE5CD2) == 0x4A,
      hexs(0xFE5CD0, 4))
check("drive byte is (head & 1) << 2 | (unit & 3)",
      a(0xFE5C81, 3) == b"\xc9\xcc\x01" and a(0xFE5C87, 3) == b"\xc9\xee\x02"
      and a(0xFE5C95, 3) == b"\xc9\xcc\x03", hexs(0xFE5C7B, 0x20))
check("SPECIFY byte 1 is (SRT << 4) | (HUT & 0x0F)",
      a(0xFE5D49, 3) == b"\xc9\xee\x04" and a(0xFE5D4F, 3) == b"\xcb\xcc\x0f",
      hexs(0xFE5D46, 12))
check("SPECIFY byte 2 is (HLT << 1) | (ND & 1)",
      a(0xFE5D62, 3) == b"\xc9\xee\x01" and a(0xFE5D68, 3) == b"\xcb\xcc\x01",
      hexs(0xFE5D5F, 12))
scan = [u16(0xFE5E0C), u16(0xFE5E12), u16(0xFE5E18)]
check("the three opcodes that get STP instead of DTL are 0xDD, 0xD9, 0xD1",
      scan == [0xDD, 0xD9, 0xD1], str(["0x%02X" % x for x in scan]))
check("those three are the SCAN commands: (op & 0x1F) is 0x1D, 0x19, 0x11",
      [x & 0x1F for x in scan] == [0x1D, 0x19, 0x11])
check("FORMAT TRACK's filler byte D is 0xE5", a(0xFE639C, 4) == b"\xb8\x0c\x00\xe5",
      hexs(0xFE6394, 12))
check("sector size is 0x400 for geometry 2 and 0x200 otherwise",
      u16(0xFE6096) == 0x0400 and u16(0xFE609F) == 0x0200
      and a(0xFE608E, 1) == b"\x02", hexs(0xFE6089, 0x18))

# =========================================================================
# 6.  THE TEN DIRECTION CODES ARE COMMAND OPCODES.
#     (notes/prom_a_byte_checks.py already parses the chain; this asserts the
#      thing that chain MEANS.)
# =========================================================================
TO_DEV = [0x4D, 0xC9, 0xC5]
TO_RAM = [0xDD, 0xD9, 0xD1, 0x4A, 0x42, 0xCC, 0xC6]
check("every RAM->device direction code is an accepted opcode",
      all((c & 0x1F) in fw for c in TO_DEV))
check("every device->RAM direction code is an accepted opcode",
      all((c & 0x1F) in fw for c in TO_RAM))
check("the RAM->device codes are FORMAT TRACK, WRITE DELETED DATA, WRITE DATA",
      [c & 0x1F for c in TO_DEV] == [0x0D, 0x09, 0x05])
check("the device->RAM codes are SCAN HI/LO/EQ, READ ID, READ TRACK, "
      "READ DELETED DATA, READ DATA",
      [c & 0x1F for c in TO_RAM] == [0x1D, 0x19, 0x11, 0x0A, 0x02, 0x0C, 0x06])

# =========================================================================
# 7.  THE NAMES ARE REALLY IN THE SOURCE, AT THESE ADDRESSES.
# =========================================================================
LABELS = {
    0xFE54EC: "Fdc_WaitControllerIdle", 0xFE5533: "Fdc_WaitRqmAndCommandBusy",
    0xFE5576: "Fdc_PulseControlReset", 0xFE558B: "Fdc_ResetAndIdentifyMedia",
    0xFE56D7: "Fdc_Op10_TestControllerPresent", 0xFE5716: "Fdc_ValidateRequest",
    0xFE57FF: "Fdc_SelectFormatParameters", 0xFE5A41: "Fdc_WaitRqm",
    0xFE5A8F: "Fdc_WaitReadyForCommandByte", 0xFE5B5E: "Fdc_ClassifyResultStatus",
    0xFE5C0A: "Fdc_IssueCommand", 0xFE5CE8: "Fdc_ClassifyCommandOpcode",
    0xFE5E84: "Fdc_SetError", 0xFE5FFE: "Fdc_Op3_ReadSectors",
    0xFE6181: "Fdc_Op4_WriteSectors", 0xFE6319: "Fdc_Op5_FormatDisk",
    0xFE6668: "Fdc_Op11_SenseDriveStatus", 0xFE66C7: "Fdc_Request",
    0xFE67F9: "Fdc_ServiceDataByte", 0xFE6E3A: "Fdc_MediaTypeJumpTable",
    0xFE6E46: "Fdc_ValidateJumpTable", 0xFE6E5E: "Fdc_OpcodeValidityJumpTable",
    0xFE6E6C: "Fdc_OperationJumpTable",
}
lines = open(SRC).read().split("\n")
found = {}
# --- the three command-issue routines, added 2026-08-25 (audit F5/F14) -------
# Defends two header sentences: "THE SAME NINE INSTRUCTIONS, 31 bytes each,
# differing in exactly TEN byte positions" (Fdc_IssueWriteData) and "the firmware
# never sends a fixed-opcode command with a top bit set" (the corrected Evidence
# line of Fdc_ClassifyCommandOpcode).
ISSUE = {0xFE5FDF: 0xC6, 0xFE62FA: 0xC5, 0xFE65D0: 0x4D}
for lo, op in sorted(ISSUE.items()):
    check("the issue routine at 0x%06X stores opcode 0x%02X and pushes it again"
          % (lo, op), a(lo, 31)[5] == op and a(lo, 31)[13] == op,
          "%02X %02X" % (a(lo, 31)[5], a(lo, 31)[13]))
_k = sorted(ISSUE)
for i in range(len(_k)):
    for j in range(i + 1, len(_k)):
        d = [n for n in range(31) if a(_k[i], 31)[n] != a(_k[j], 31)[n]]
        check("0x%06X and 0x%06X differ in exactly 10 of their 31 bytes"
              % (_k[i], _k[j]), len(d) == 10, str(len(d)))
        check("...and those ten are the two opcode copies and the four "
              "displacements", d == [5, 7, 8, 10, 11, 13, 16, 17, 29, 30], str(d))

# Every command opcode the module hands to Fdc_IssueCommand, taken from the ROM:
# each is a `pushw imm16` (0x0B lo hi) immediately followed by a `calr` to
# Fdc_IssueCommand at 0xFE5C0A.  MAME's uPD765 matches 0x03, 0x04, 0x07, 0x08 and
# 0x0F WHOLE (no mask); the check is that this firmware never sets a top bit on
# one of those, so its own `& 0x1F` shortcut cannot disagree with the real chip.
FIXED = {0x03, 0x04, 0x07, 0x08, 0x0F}
issued = set()
for off in range(0xFE54B6 - 0xF80000, 0xFE68F3 - 0xF80000):
    if A[off] == 0x0B and A[off + 3] == 0x1E:
        _d = int.from_bytes(A[off + 4:off + 6], "little")
        _d -= 0x10000 if _d >= 0x8000 else 0
        if (0xF80000 + off + 6 + _d) & 0xFFFFFF == 0xFE5C0A:
            issued.add(A[off + 1] | (A[off + 2] << 8))
check("Fdc_IssueCommand is handed exactly these eight opcodes: "
      "0x03 0x04 0x07 0x0F 0x13 0x4D 0xC5 0xC6",
      issued == {0x03, 0x04, 0x07, 0x0F, 0x13, 0x4D, 0xC5, 0xC6},
      " ".join("0x%02X" % v for v in sorted(issued)))
# 0x08, SENSE INTERRUPT STATUS, does not appear above because it does not go
# through Fdc_IssueCommand: 0xFE689C pushes it straight to Dev7B_WriteData.
check("...every fixed-opcode command it issues is sent UNMASKED (no top bits), "
      "so the driver's `& 0x1F` and a real 765's full decode agree",
      all(v == (v & 0x1F) for v in issued if (v & 0x1F) in FIXED),
      " ".join("0x%02X" % v for v in sorted(issued)))

pending = []
for line in lines:
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', line)
    if m:
        pending.append(m.group(1))
        continue
    m = re.search(r';\s*([0-9A-F]{6})\b', line)
    if m and pending:
        for n in pending:
            found.setdefault(n, int(m.group(1), 16))
        pending = []
for addr, name in sorted(LABELS.items()):
    check("source label %s is at 0x%06X" % (name, addr),
          found.get(name) == addr,
          "found at %s" % ("0x%06X" % found[name] if name in found else "nowhere"))

print("\n%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
