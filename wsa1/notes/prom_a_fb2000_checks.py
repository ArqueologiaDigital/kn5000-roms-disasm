#!/usr/bin/env python3
"""Re-derive, from the ROM bytes, every quantified claim the 0xFB2000 span makes.

QUESTION IT ANSWERS: "prom_a 0xFB2000-0xFBFFFF's banner and
notes/FINDINGS-prom_a-remote-flash.md say `four modules with these four pads`,
`seven inline jump tables whose entry counts come from their own bound
compares`, `32 blocks of 0x2000 from remote 0xE80000`, `106 directory slots`,
`the MIDI block is these 205 bytes in this order` -- are they still true of the
ROM?"

The byte gate proves the source rebuilds the ROM and is blind to every one of
those sentences.  Run this with the gate; neither catches what the other does.

    python3 notes/prom_a_fb2000_checks.py        # non-zero exit on any failure
    python3 notes/prom_a_fb2000_checks.py -v
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
FAILS, RAN = [], []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def u32(addr):
    return int.from_bytes(a(addr, 4), "little")


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("   " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


# --- 1. the four modules and their 0x0E pads --------------------------------
# The claim is that this span is four modules, each ending in a run of 0x0E that
# reaches the next 0x400/0x800 boundary.  Both ends of every pad are checked.
PADS = [(0xFB8CA6, 0xFB9000, 858), (0xFBA236, 0xFBAC00, 2506),
        (0xFBB42E, 0xFBB800, 978), (0xFBFFD4, 0xFC0000, 44)]
for lo, hi, n in PADS:
    check("pad 0x%06X-0x%06X is %d bytes of uniform 0x0E" % (lo, hi - 1, n),
          hi - lo == n and set(a(lo, n)) == {0x0E},
          "%d bytes, values %s" % (hi - lo, sorted(set(a(lo, n)))[:4]))
    check("...and the byte before it, 0x%06X, is not 0x0E" % (lo - 1),
          a(lo - 1)[0] != 0x0E, "0x%02X" % a(lo - 1)[0])

# The four module starts, and WHICH evidence pins each one (they differ).
check("0xFB2000 opens with `jp 0xFB2018` and `jp 0xFB201D`, a veneer block",
      a(0xFB2000, 4).hex() == "1b1820fb" and a(0xFB200C, 4).hex() == "1b1d20fb",
      a(0xFB2000, 16).hex())
check("0xFB9000 opens on a prologue, NOT a veneer: `push XIZ / ld XIZ,XSP`",
      a(0xFB9000, 3).hex() == "3eef8e", a(0xFB9000, 3).hex())
check("0xFBAC00 opens on `push XIZ / push XIX / push XHL / push XDE`",
      a(0xFBAC00, 4).hex() == "3e3c3b3a", a(0xFBAC00, 4).hex())
check("0xFBB800 opens on `link XIZ,0x0000`",
      a(0xFBB800, 4).hex() == "ee0c0000", a(0xFBB800, 4).hex())

# --- 2. the seven inline jump tables ----------------------------------------
# Each row: table base, entry count, the address of the `cp`/`cps` bound, the
# bound value, and the byte offset of the `add Xrr,imm32` that names the base.
# ENTRY COUNT comes from the bound, never from where the values stop looking
# like addresses; the LAST-ENTRY TEST is that base + 4*count == entry 0, i.e.
# the table tiles exactly up to the code it dispatches into.
TABLES = [(0xFB2081, 6, 0xFB2077), (0xFB3517, 7, 0xFB350D),
          (0xFB42D1, 7, 0xFB42C7), (0xFB6240, 16, 0xFB6236),
          (0xFB62F6, 16, 0xFB62EC), (0xFBD25F, 6, 0xFBD255),
          (0xFBD320, 6, 0xFBD316)]
for base, n, site in TABLES:
    check("0x%06X: the reader at 0x%06X names it in an `add Xrr,0x00%06X`"
          % (base, site, base), u32(site + 2) & 0xFFFFFF == base,
          "0x%06X" % (u32(site + 2) & 0xFFFFFF))
    check("0x%06X: `ld Xrr,(Xrr)` then `jp (Xrr)` follow the add" % base,
          a(site + 6)[0] in (0xA0, 0xA1, 0xA3, 0xA4)
          and a(site + 8)[0] in (0xB0, 0xB1, 0xB3, 0xB4)
          and a(site + 9)[0] == 0xD8,
          a(site + 6, 4).hex())
    check("0x%06X: LAST-ENTRY TEST -- base + %d*4 == entry 0 (0x%06X)"
          % (base, n, u32(base)), base + 4 * n == u32(base),
          "0x%06X" % (base + 4 * n))
    check("0x%06X: all %d entries point inside 0xFB2000-0xFBFFFF" % (base, n),
          all(0xFB2000 <= u32(base + 4 * k) < 0xFC0000 for k in range(n)))
check("the 16 arms of U8Rec16_SetField_Cases step by exactly 5 bytes, "
      "0xFB6280..0xFB62CB",
      [u32(0xFB6240 + 4 * k) for k in range(16)]
      == [0xFB6280 + 5 * k for k in range(16)])


# --- the "Read by: ONE site" claim, made runnable ----------------------------
# Every table header here says the base is named by exactly ONE instruction.
# That is a searched negative about the REST of both images, so it gets a census:
# the 4-byte little-endian immediate, over prom_a and prom_b, at every offset.
_Bimg = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def _imm_sites(v):
    le = bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, 0])
    out = []
    for img, base in ((A, 0xF80000), (_Bimg, 0xF00000)):
        i = img.find(le)
        while i >= 0:
            out.append(base + i)
            i = img.find(le, i + 1)
    return out

for base, n, site in TABLES:
    _h = _imm_sites(base)
    check("0x%06X: the immediate 0x00%06X occurs at exactly ONE offset in prom_a "
          "+ prom_b, and it is the reader's" % (base, base),
          _h == [site + 2], str(["0x%06X" % x for x in _h]))

# --- 3. the remote-flash reader ---------------------------------------------
# The gap-D answer: 31 loop iterations plus one block after the loop, 0x2000
# bytes each, from remote 0xE80000 into RAM 0x60A000.
check("0xFB251F is `ld XIX,0x00E80000`",
      a(0xFB251F, 5).hex() == "4400 00e800".replace(" ", ""), a(0xFB251F, 5).hex())
check("0xFB2524 is `ldb h,0x1F` -- 31 loop iterations",
      a(0xFB2524, 2).hex() == "261f", a(0xFB2524, 2).hex())
check("0xFB2548 is `add XIX,0x00002000` -- the block stride",
      a(0xFB2548, 6).hex() == "ecc800200000", a(0xFB2548, 6).hex())
check("0xFB2530 pushes the count 0x2000 (`pushw 0x2000`)",
      a(0xFB2530, 3).hex() == "0b0020", a(0xFB2530, 3).hex())
check("0xFB252A loads the staging buffer 0x60A000",
      a(0xFB252A, 5).hex() == "f200a06031", a(0xFB252A, 5).hex())
check("0xFB2554 is `jr nz,-44`, back to 0xFB252A -- so the loop body starts at "
      "the buffer push",
      a(0xFB2554, 2).hex() == "6ed4" and 0xFB2556 - 44 == 0xFB252A,
      a(0xFB2554, 2).hex())
check("...so the range covered is 32 x 0x2000 = 0x40000, i.e. remote "
      "0xE80000-0xEBFFFF", (31 + 1) * 0x2000 == 0x40000
      and 0xE80000 + 31 * 0x2000 == 0xEBE000)
for site in (0xFB2534, 0xFB2560, 0xFB24D3):
    check("0x%06X is `call 0xF40EF0`, the link's remote-read slot" % site,
          a(site, 4).hex() == "1df00ef4", a(site, 4).hex())
for site in (0xFB24D7, 0xFB256E):
    check("0x%06X is `call 0xF4123C`, the Link_WaitBlockDone slot" % site,
          a(site, 4).hex() == "1d3c12f4", a(site, 4).hex())
for _site, _val in ((0xFB24BA, 0xF4FF10), (0xFB2515, 0xF4FF1C),
                    (0xFB25D2, 0xF4FF28)):
    check("0x%06X loads the prom_b display list 0x%06X" % (_site, _val),
          a(_site, 5).hex()[:2] == "f2"
          and int.from_bytes(a(_site + 1, 3), "little") == _val,
          a(_site, 5).hex())
check("the single-block sibling at 0xFB248A passes count 0x0000",
      a(0xFB24CA, 3).hex() == "0b0000", a(0xFB24CA, 3).hex())
check("...and source 0x00E80000 (`ld XWA,0x00E80000` at 0xFB24CD)",
      a(0xFB24CD, 5).hex() == "400000e800", a(0xFB24CD, 5).hex())

# --- 4. the MIDI-file table -------------------------------------------------
M = 0xFBA169
check("0x%06X is the ASCII \"MThd\"" % M, a(M, 4) == b"MThd")
check("0x%06X is the ASCII \"MTrk\"" % (M + 4), a(M + 4, 4) == b"MTrk")
check("the block is 205 bytes, 0xFBA169-0xFBA235", 0xFBA236 - M == 205)
check("0xFBA171 is 0x7E 0x7F", a(0xFBA171, 2).hex() == "7e7f")
check("0xFBA173 is 0x09 and 0xFBA174 is the ramp 0x00..0x0F in order",
      a(0xFBA173)[0] == 0x09 and list(a(0xFBA174, 16)) == list(range(16)))
check("0xFBA184 is 0x20 and 0xFBA185 is 0x00..0x08, 0x0A..0x0F, 0x09",
      a(0xFBA184)[0] == 0x20
      and list(a(0xFBA185, 16)) == list(range(9)) + list(range(10, 16)) + [9])
W1 = [u32(0xFBA195 + 4 * k) for k in range(16)]
check("0xFBA195 holds 16 LE32 RAM addresses 0x000076AF..0x00007AAF",
      W1[0] == 0x76AF and W1[-1] == 0x7AAF and all(w < 0x10000 for w in W1))
steps = [W1[k + 1] - W1[k] for k in range(15)]
check("...stepping by 0x40 except once, between entries 7 and 8, where it is "
      "0x80", steps.count(0x40) == 14 and steps[7] == 0x80, str(steps))
check("...so 0x000078AF is the one address the run SKIPS", 0x78AF not in W1)
check("0xFBA1D5 and 0xFBA1E6 are both the ramp 0x00..0x0F in order",
      list(a(0xFBA1D5, 16)) == list(range(16))
      and list(a(0xFBA1E6, 16)) == list(range(16)))
check("0xFBA1E5 is 0x20", a(0xFBA1E5)[0] == 0x20)
check("the second 16-word run at 0xFBA1F6 is byte-identical to the first",
      a(0xFBA1F6, 64) == a(0xFBA195, 64))
check("the block's parts tile it exactly: 8+2+1+16+1+16+64+16+1+16+64 = 205",
      8 + 2 + 1 + 16 + 1 + 16 + 64 + 16 + 1 + 16 + 64 == 205)

# --- 5. the record tables at 0xFB82A0 ---------------------------------------
check("0xFB829D-0xFB829F is `retd 8`, so the code ends at 0xFB82A0",
      a(0xFB829D, 3).hex() == "0f0800", a(0xFB829D, 3).hex())
# The array's EXTENT is taken from the data's own rule -- a record's u32 is an
# address inside this module -- and the stop is then cross-checked against a
# SECOND, independent signal: the byte ramp that starts there.
def _rec(at):
    return (int.from_bytes(a(at, 2), "little"),
            int.from_bytes(a(at + 2, 4), "little"))


at, n = 0xFB82A2, 0
while at < 0xFB8CA6 and 0xFB2000 <= _rec(at)[1] < 0xFC0000:
    at += 6
    n += 1
check("0xFB82A2 carries 332 six-byte records [u16][u32] that tile exactly to "
      "0xFB8A69", n == 332 and at == 0xFB8A6A, "%d records, stop 0x%06X" % (n, at))
check("...332 * 6 == 1992 == 0xFB8A6A - 0xFB82A2", 332 * 6 == 0xFB8A6A - 0xFB82A2)
check("...and the run stops exactly where a byte ramp begins "
      "(00 01 01 02 03 03 04 05)",
      a(0xFB8A6A, 8).hex() == "0001010203030405", a(0xFB8A6A, 8).hex())
recs = [_rec(0xFB83B6 + 6 * k) for k in range(20)]
check("0xFB83B6 is a 20-record stretch whose u16 counts 0,1,2,... and whose u32 "
      "is the constant 0x00FB83AA",
      [r[0] for r in recs] == list(range(20))
      and {r[1] for r in recs} == {0x00FB83AA}, str(recs[:3]))
check("the two bytes at 0xFB82A0 fit no record and are 0xFB 0x00",
      a(0xFB82A0, 2).hex() == "fb00", a(0xFB82A0, 2).hex())

# --- 6. the directory slots -------------------------------------------------
import prom_a_call_graph as CG                                    # noqa: E402
_a, _b = CG.load()
slots = [v for v in CG.jp_slots(_b).values() if 0xFB2000 <= v < 0xFC0000]
check("106 prom_b directory slots point into 0xFB2000-0xFBFFFF",
      len(slots) == 106, str(len(slots)))
check("0xFBAC00 and 0xFBB800 are themselves directory targets; 0xFB2000 and "
      "0xFB9000 are not, and 0xFB2022 is",
      [x in slots for x in (0xFBAC00, 0xFBB800, 0xFB2000, 0xFB9000, 0xFB2022)]
      == [True, True, False, False, True])
for lo, hi, n, nm in ((0xFB2000, 0xFB9000, 12, "0xFB2000"),
                      (0xFB9000, 0xFBAC00, 9, "0xFB9000"),
                      (0xFBAC00, 0xFBB800, 4, "0xFBAC00"),
                      (0xFBB800, 0xFC0000, 81, "0xFBB800")):
    got = sum(1 for v in slots if lo <= v < hi)
    check("module %s publishes %d of them" % (nm, n), got == n, str(got))

# --- 6b. every undecodable byte is inside a DECLARED data region -------------
# Defends the banner sentence "0 undecodable `db` bytes once the tables below are
# excluded".  Runs unidasm through notes/prom_a_linear_decode_check.py, so it is
# the slowest check here; skip it with --fast.
if "--fast" not in sys.argv:
    import prom_a_linear_decode_check as LC                        # noqa: E402
    DATA = [(0xFB2081, 0xFB2099), (0xFB3517, 0xFB3533),
            (0xFB42D1, 0xFB42ED), (0xFB6240, 0xFB6280),
            (0xFB62F6, 0xFB6336), (0xFB82A0, 0xFB8CA6),
            (0xFBA169, 0xFBA236), (0xFBD25F, 0xFBD277),
            (0xFBD320, 0xFBD338)]
    _tot, _out = 0, []
    for _lo, _hi in ((0xFB2000, 0xFB8CA6), (0xFB9000, 0xFBA236),
                     (0xFBAC00, 0xFBB42E), (0xFBB800, 0xFBFFD4)):
        _db = [x for x, _, t in LC.decode(_lo, _hi) if t == "db"]
        _tot += len(_db)
        _out += [x for x in _db
                 if not any(lo <= x < hi for lo, hi in DATA)]
    check("all %d undecodable bytes in 0xFB2000-0xFBFFD3 lie inside a DECLARED "
          "data region" % _tot, _out == [],
          str(["0x%06X" % x for x in _out]))

# --- 7. the source really carries the names this note quotes -----------------
# ⚠ 0xFB248A carries NO label on purpose: nothing names it.  That is a searched
# negative, so it is made runnable here -- if a reference ever appears, this
# check fails and the "no label, deliberately" header above it becomes wrong.
_le = (0x8A, 0x24, 0xFB)
_hits = []
for img, base in ((A, 0xF80000),
                  (open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"),
                        "rb").read(), 0xF00000)):
    for i in range(len(img) - 3):
        if img[i] in (0x1B, 0x1D) and tuple(img[i + 1:i + 4]) == _le:
            _hits.append(base + i)
check("no `call`/`jp 0x00FB248A` exists in prom_a or prom_b, which is why that "
      "routine has no label", _hits == [], str(["0x%06X" % h for h in _hits]))

LABELS = {0xFB24EC: "Remote_E80000_Read32Blocks",
          0xFB2081: "SysExDump_JobTable", 0xFB6240: "U8Rec16_SetField_Cases",
          0xFBD320: "JumpTable_FBD320",
          0xFB82A0: "RecordTables_FB82A0",
          0xFBA169: "MidiFile_Tables_FBA169"}
import re                                                          # noqa: E402
found, pending = {}, []
for line in open(SRC, encoding="utf-8"):
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', line)
    if m:
        pending.append(m.group(1))
        continue
    m = re.search(r';\s*([0-9A-F]{6})\b', line)
    if m and pending:
        for n in pending:
            found.setdefault(n, int(m.group(1), 16))
        pending = []
for addr, nm in sorted(LABELS.items()):
    check("source label %s is at 0x%06X" % (nm, addr), found.get(nm) == addr,
          "found at %s" % ("0x%06X" % found[nm] if nm in found else "nowhere"))

# --- ★ the WHOLE-SPAN linear-decode verdict (round-2 audit F12) -------------
# The banner cites prom_a_linear_decode_check.py for having FOUND the record
# table.  Run on the whole span it also returns "NOT self-consistent", which the
# tree never said.  These checks state the verdict AND account for every
# offender, so the sentence "the residue is entirely declared data" is testable.
if "--fast" not in sys.argv:
    import re as _re2                                                # noqa: E402
    import prom_a_linear_decode_check as _LC2                        # noqa: E402

    _ADDR2 = _re2.compile(r";\s([0-9A-F]{6})(\s|$)")
    _DIR2 = (".byte", ".word", ".long", ".ascii", ".short", ".quad",
             ".fill", ".space", ".incbin", ".asciz")

    def _declared_data(lo, hi):
        """Every address in [lo,hi) that the SOURCE declares as a data directive.

        Extent of a directive line = distance to the next address-commented line,
        which is exact because the file rebuilds the ROM byte-identically."""
        rows = []
        for line in open(SRC, encoding="utf-8"):
            line = line.rstrip("\n")
            if not line.startswith("\t"):
                continue
            m = _ADDR2.search(line)
            if not m:
                continue
            t = line.strip().split(";")[0].strip()
            if not t:
                continue
            rows.append((int(m.group(1), 16), t.split()[0] in _DIR2))
        rows.sort()
        out = set()
        for i, (a, isdir) in enumerate(rows):
            if not (lo <= a < hi) or not isdir:
                continue
            nxt = rows[i + 1][0] if i + 1 < len(rows) else a + 1
            out.update(range(a, min(nxt, hi)))
        return out

    _LO2, _HI2 = 0xFB2000, 0xFC0000
    _rows2 = _LC2.decode(_LO2, _HI2)
    _db2 = [x for x, _u, t in _rows2 if t == "db"]
    _data2 = _declared_data(_LO2, _HI2)
    check("L1 a linear decode of the WHOLE span 0xFB2000-0xFBFFFF leaves 72 "
          "undecodable bytes -- the span does NOT pass the tool's own verdict",
          len(_db2) == 72, str(len(_db2)))
    _out2 = [x for x in _db2 if x not in _data2]
    check("L2 ...and ALL 72 are inside data the source already declares, so the "
          "residue is accounted for, not unexplained",
          _out2 == [], str(["0x%06X" % x for x in _out2]))
    check("L3 the two `call into a non-boundary` offenders, 0xFB846A and "
          "0xFB8770, are both inside declared data too",
          0xFB846A in _data2 and 0xFB8770 in _data2,
          "%s %s" % (0xFB846A in _data2, 0xFB8770 in _data2))
    check("L4 both offenders lie inside the 332-record table 0xFB82A2-0xFB8A69",
          all(0xFB82A2 <= x < 0xFB8A6A for x in (0xFB846A, 0xFB8770)))
    _bounds2 = {x for x, _u, _t in _rows2}
    check("L5 LAST-ELEMENT test: the span's end 0xFC0000 is a boundary of a "
          "decode that runs past it", 0xFC0000 in {x for x, _u, _t in
                                                   _LC2.decode(_LO2, 0xFC0010)})

print("\n%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
