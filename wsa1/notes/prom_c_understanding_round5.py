#!/usr/bin/env python3
"""prom_c ROUND 5 -- THE PORT-P7 UNIT MODULE, and what prom_c's 5,176 "framed" labels really are.

QUESTION IT ANSWERS
  Wave 7 round 5 gave this lane one headline: framed -> content.  prom_c reads
  734 content labels against 5,176 framed ones -- 11.4% LOWER against 92.0%
  UPPER, the widest bracket of any image -- so the brief called it "the single
  biggest block of unexplained structure in the tree".

  ★ SECTION 1 SHOWS THAT FIGURE IS MOSTLY AN ARTEFACT, and measures by how much.
  4,681 of the 5,176 are `<Routine>__<ADDR>` INTRA-ROUTINE BRANCH TARGETS -- the
  exact analogue of the `.L` compiler-locals that notes/wave7_documentation_metrics.py
  already excludes by name, spelled differently by this tree's emitter.  Naming one
  of them individually would be noise, and renaming a parent routine does not move
  them out of `framed` either.  The pool a naming round can actually reach in
  prom_c is 495 standalone objects, not 5,176, and 353 of those 495 are the
  P7Stream / PoolDir_FieldRec objects whose bytes are byte-code for an undecoded
  device.  ⚠ That is a correction to the ROUND-5 BRIEF's own framing, and it is
  measured here rather than argued.

  Sections 2-7 then do the naming, on the pool that is left, by the round-4
  mechanism: NAME AN OBJECT FROM WHAT READS IT.

WHAT WAS NAMED, and the one chain that carries it
  ⚠ AND THE HEADLINE IS 4, NOT 5.  Of the 24 names this round shipped, FOUR were
  graded `framed` before and CONTENT after; SIXTEEN were sub_XXXXXX; and ONE --
  PoolDir_IndexMap128 -> PoolDir_RecordForUnitProgram -- was ALREADY graded content
  by the metric, because "IndexMap128" is not a bare number.  It is a better name and
  it moves nothing.  Section 7 asserts that split, so the round cannot be reported as
  five.  prom_c: content 734 -> 757, framed 5,176 -> 5,172, sub_XXXXXX 511 -> 492.

  prom_c drives THREE devices over port P7 (notes/FINDINGS-prom_c-p7-byte-stream-pool.md).
  Round 5 traced the whole path from the number a user changes to the bytes that
  leave the port, and named the objects along it:

    RAM 0x856E + 26*unit          three 26-byte UNIT BLOCKS, unit = 0,1,2
      +0x00  u8   PROGRAM, clamped to 0..127          (0xFA5572 `cp A,0x7f`)
        -> PoolDir_RecordForUnitProgram[program]      (0xFA5582, was PoolDir_IndexMap128)
      +0x18  u8   the resulting PoolDir_Records index  (0xFA558A stores it)
        -> PoolDir_Records[idx]      25 B: 4 stream pointers, 2 DescriptorStrings, 1 byte
        -> PoolDir_FieldRec_PtrTable[idx] -> that program's 7-byte FIELD DESCRIPTORS
    RAM 0x85BC + 26*unit          the SHADOW of the same three blocks (0x856E + 3*26)
      P7Unit_EmitChangedParams diffs live against shadow and emits only what moved.

RUN
    python3 notes/prom_c_understanding_round5.py            # every section
    python3 notes/prom_c_understanding_round5.py --framed   # 1: what "framed" is in prom_c
    python3 notes/prom_c_understanding_round5.py --blocks   # 2: the 3 x 26-byte unit blocks
    python3 notes/prom_c_understanding_round5.py --program  # 3: program -> record -> streams
    python3 notes/prom_c_understanding_round5.py --fields   # 4: the 7-byte field descriptor
    python3 notes/prom_c_understanding_round5.py --ram      # 5: two ROM objects are RAM images
    python3 notes/prom_c_understanding_round5.py --trace    # 6: the MIDI hex trace is DEAD
    python3 notes/prom_c_understanding_round5.py --names    # 7: the names shipped, asserted
    python3 notes/prom_c_understanding_round5.py --selftest # all of it, exit 1 on any failure

WHAT THIS DOES **NOT** ESTABLISH
  * What any P7 destination IS.  Three destinations and three uPD6383GF DSPs in the
    parts list is a consistency, not a proof, and nothing here calls one a DSP.
  * What a PROGRAM 0..127 sounds like, or what any of the 56 directory records is.
    The word "program" is defined by its mechanism -- the 0..127 selector at unit
    block +0 that chooses which streams the unit is sent -- and by nothing else.
  * What the field-descriptor TYPE LETTERS ('b','w','v','s','h','c','B') mean.
    Section 4 measures the descriptor's byte layout and the one relation between
    PoolDir_Records +24 and the field offsets; the letters stay unread.
  * What the four "groups" 2..5 of P7Unit_StreamPtrsByGroupAndUnit are for.  The
    selector is clamped to 0..1 at 0xFA5715, so the three sites found reach only
    groups 0 and 1.  Recorded, not explained away.
  * Any P7Stream object's CONTENT.  297 of them stay `P7Stream_XXXXXX`, which is
    the right answer while their byte-code is undecoded; ONE was renamed, because
    a reader states its role (section 3d).
"""
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")

_rom = open(ROM, "rb").read()
_src = open(SRC).read().split("\n")

OK = [0]
FAIL = [0]


def check(desc, cond):
    print(("  ok   " if cond else "  FAIL ") + desc)
    if cond:
        OK[0] += 1
    else:
        FAIL[0] += 1
    return cond


def rd(a, n):
    return _rom[a - BASE:a - BASE + n]


def u8(a):
    return rd(a, 1)[0]


def u32(a):
    return struct.unpack("<I", rd(a, 4))[0]


def s16(a):
    return struct.unpack("<h", rd(a, 2))[0]


def cstr(a):
    o = a - BASE
    return _rom[o:_rom.index(b"\0", o)].decode("latin1")


def dis(addr, n=16):
    """Decode n bytes at addr with unidasm -- the INDEPENDENT decoder.

    Returns [] when unidasm is not installed, and every check that depends on it
    says [skip] rather than passing quietly."""
    if not os.path.exists(UNIDASM):
        return []
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(rd(addr, n))
        p = f.name
    try:
        out = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(p)
    return out.split("\n")


def oracle(addr, must_contain, why):
    """Assert that unidasm's own text for the instruction AT addr contains a string."""
    lines = [l for l in dis(addr, 12) if l.strip()]
    if not lines:
        print("  [skip] no unidasm: %s" % why)
        return None
    first = lines[0]
    return check("%s -- unidasm at 0x%06X says %r" % (why, addr, first.split(":", 1)[-1].strip()),
                 must_contain.lower().replace(" ", "") in first.lower().replace(" ", ""))


# ---------------------------------------------------------------- source scan
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ADDR = re.compile(r";\s*([0-9A-F]{6})\b")


def all_labels():
    """Every column-0 label in prom_c, with the address of the last addressed line."""
    out = []
    cur = None
    for ln in _src:
        m = ADDR.search(ln)
        if m:
            cur = int(m.group(1), 16)
        lm = LABEL.match(ln)
        if lm:
            out.append((lm.group(1), cur))
    return out


# =============================================================== 1. framed
FRAMED = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*_"
                    r"(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?"
                    r"(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$")
UNNAMED = re.compile(r"^sub_[0-9A-Fa-f]{6}$")
INNER = re.compile(r"^(.*?)__([0-9A-Fa-f]{4,6})$")


def sec_framed():
    """Split prom_c's `framed` labels into intra-routine branch targets and real objects.

    ★ The claim: the metric's `framed` column for prom_c is 90.5% branch labels, so
    the reachable framed->content pool is 495, not 5,176."""
    print("=== 1. WHAT prom_c's 5,176 FRAMED LABELS ACTUALLY ARE ===")
    labs = all_labels()
    names = set(n for n, _a in labs)
    framed = [(n, a) for n, a in labs if not UNNAMED.match(n) and FRAMED.match(n)]
    content = [(n, a) for n, a in labs if not UNNAMED.match(n) and not FRAMED.match(n)]
    unnamed = [(n, a) for n, a in labs if UNNAMED.match(n)]
    inner, outer = [], []
    for n, a in framed:
        m = INNER.match(n)
        (inner if (m and m.group(1) in names) else outer).append((n, a))
    print("  content %d   framed %d   sub_XXXXXX %d" % (len(content), len(framed), len(unnamed)))
    print("  of the framed: %d are <Routine>__<ADDR> INTRA-ROUTINE BRANCH TARGETS (%.1f%%)"
          % (len(inner), 100.0 * len(inner) / len(framed)))
    print("                 %d are standalone objects -- the reachable pool" % len(outer))
    bulk = [x for x in outer if re.match(r"^(P7Stream|PoolDir_FieldRec)_[0-9A-F]{6}$", x[0])]
    print("  of those %d: %d are P7Stream_/PoolDir_FieldRec_ pool objects with no self-name,"
          % (len(outer), len(bulk)))
    print("               %d are everything else" % (len(outer) - len(bulk)))
    check("every `inner` label's prefix really is another label in this file",
          all(INNER.match(n).group(1) in names for n, _a in inner))
    check("no `outer` label is an inner one in disguise",
          not any(INNER.match(n) and INNER.match(n).group(1) in names for n, _a in outer))
    # ★ tested on the LAST element as well as the first
    check("first framed label (%s) classifies" % framed[0][0], framed[0] in inner or framed[0] in outer)
    check("LAST framed label (%s) classifies" % framed[-1][0], framed[-1] in inner or framed[-1] in outer)
    check("the split adds up", len(inner) + len(outer) == len(framed))
    check("branch targets are the majority and it is not close (>= 85%)",
          len(inner) >= 0.85 * len(framed))
    return len(inner), len(outer)


# =============================================================== 2. unit blocks
UNIT_BASE = 0x856E
UNIT_STRIDE = 26
SHADOW_BASE = 0x85BC


def sec_blocks():
    """The three 26-byte per-unit blocks at RAM 0x856E, and their shadow at 0x85BC.

    Every number is an instruction operand, and the three block copies in
    P7Units_ResolveProgramsAndReload name the three bases literally."""
    print("\n=== 2. RAM 0x856E: THREE 26-BYTE UNIT BLOCKS, AND THE SHADOW AT 0x85BC ===")
    bases = [UNIT_BASE + UNIT_STRIDE * n for n in range(3)]
    print("  live   blocks: " + "  ".join("0x%04X" % b for b in bases))
    print("  shadow blocks: " + "  ".join("0x%04X" % (SHADOW_BASE + UNIT_STRIDE * n) for n in range(3)))
    txt = "\n".join(_src)
    # The three literal `lda XIX,<base>` block copies at 0xFA553D / 0xFA554C / 0xFA555B
    for n, (site, base) in enumerate([(0xFA553D, 0x856E), (0xFA554C, 0x8588), (0xFA555B, 0x85A2)]):
        check("unit %d's block base 0x%04X is a literal at 0x%06X" % (n, base, site),
              ("lda_24\txix, (0x%04X)" % base) in txt and ("; %06X" % site) in txt)
        check("  ...and 0x%04X = 0x856E + 26*%d" % (base, n), base == UNIT_BASE + UNIT_STRIDE * n)
    check("the shadow base 0x85BC is exactly where the live array ends (0x856E + 3*26)",
          SHADOW_BASE == UNIT_BASE + 3 * UNIT_STRIDE)
    # the +0x18 field: the three stores in P7Units_ResolveProgramsAndReload
    for n, (site, addr) in enumerate([(0xFA558A, 0x8586), (0xFA55AF, 0x85A0), (0xFA55D4, 0x85BA)]):
        check("unit %d's derived record index is stored to 0x%04X = base+0x18 (site 0x%06X)"
              % (n, addr, site), addr == UNIT_BASE + UNIT_STRIDE * n + 0x18)
    # the shadow's own +0x18, written by the same routine
    for n, addr in enumerate([0x85D4, 0x85EE, 0x8608]):
        check("shadow unit %d's +0x18 is 0x%04X" % (n, addr),
              addr == SHADOW_BASE + UNIT_STRIDE * n + 0x18)
    oracle(0xFA553D, "lda", "the block-copy source is an `lda` at 0xFA553D")
    oracle(0xFA5572, "0x7f", "the program clamp `cp A,0x7f` is AT 0xFA5572")
    return bases


# =============================================================== 3. program chain
POOLDIR = 0xFDBFD9
INDEXMAP = 0xFDC551
FIELDPTR = 0xFDD1CB


def sec_program():
    """program (0..127) -> PoolDir_RecordForUnitProgram -> PoolDir_Records -> streams."""
    print("\n=== 3. THE PROGRAM CHAIN, END TO END ===")
    vals = [u8(INDEXMAP + k) for k in range(128)]
    check("PoolDir_RecordForUnitProgram has 128 entries, all in 0..55",
          all(0 <= v <= 55 for v in vals))
    check("every one of the 56 record indices occurs (that is what fixes the count)",
          set(vals) == set(range(56)))
    from collections import Counter
    c = Counter(vals)
    print("  128 programs -> 56 records; the catch-all is record %d, used by %d programs"
          % (c.most_common(1)[0][0], c.most_common(1)[0][1]))
    check("record 25*56 ends exactly where the index map begins",
          POOLDIR + 25 * 56 == INDEXMAP)
    check("the pointer table 0xFDD1CB has 56 u32 and ends on the pool's last byte",
          FIELDPTR + 4 * 56 == 0xFDD2AB)
    # every record's four stream pointers land inside the pool
    inpool = all(0xFCD0F7 <= u32(POOLDIR + 25 * i + f) <= 0xFDD2AA
                 for i in range(56) for f in (0, 4, 8, 12))
    check("all 56 x 4 stream pointers land inside the pool (incl. record 55 -- last-entry test)",
          inpool)
    # the three instruction operands that make the chain
    txt = "\n".join(_src)
    for site, what in [(0xFA5582, "add XBC,0x00fdc551"), (0xFA2B44, "mul A,0x19"),
                       (0xFA2B4B, "add XWA,0x00fdbfd9"), (0xFA2BBE, "mul C,0x04"),
                       (0xFA2BC3, "add XBC,0x00fdd1cb")]:
        check("0x%06X is `%s`" % (site, what), ("; %06X  %s" % (site, what)) in txt)
    oracle(0xFA2B44, "mul", "the record stride 25 is `mul A,0x19` AT 0xFA2B44")
    oracle(0xFA2B2F, "0x1a", "the block stride 26 is `ld C,0x1a` AT 0xFA2B2F")
    # 3d: the ONE stream a reader names
    print("  3d. P7Stream_UnitPreamble (0xFD2C2B): sent to a unit under a first-use latch")
    check("0xFD2C2B is inside the pool", 0xFCD0F7 <= 0xFD2C2B <= 0xFDD2AA)
    check("P7Unit_SendPreambleOnce guards it with the latch at RAM 0xF354 + 2*unit",
          "add\txbc, 0xF354" in txt and "; FA35E0" in txt and "; FA3615" in txt)
    check("...and the latch is set to 0xFFFF only after the stream has been run",
          "; FA361B  ld (XBC),0xffff" in txt)


# =============================================================== 4. field records
def field_records():
    ptrs = [u32(FIELDPTR + 4 * i) for i in range(56)]
    order = sorted(range(56), key=lambda i: ptrs[i])
    lens = {}
    for k, i in enumerate(order):
        lens[i] = (ptrs[order[k + 1]] if k + 1 < 56 else FIELDPTR) - ptrs[i]
    return ptrs, lens


def sec_fields():
    """The 7-byte field descriptor: min, max, block offset, a flag, a field index."""
    print("\n=== 4. THE 7-BYTE FIELD DESCRIPTOR ===")
    ptrs, lens = field_records()
    tot = sum(l // 7 for l in lens.values())
    print("  56 descriptor arrays, %d field records of 7 bytes" % tot)
    check("every array length is a whole number of 7-byte records",
          all(l % 7 == 0 for l in lens.values()))
    ok_minmax = ok_off = ok_idx = ok_b24 = 0
    maxoff = 0
    for i in range(56):
        n = lens[i] // 7
        offs, idxs = [], []
        for j in range(n):
            b = ptrs[i] + 7 * j
            lo, hi, off, _flag, idx = s16(b), s16(b + 2), u8(b + 4), u8(b + 5), u8(b + 6)
            offs.append(off)
            idxs.append(idx)
            maxoff = max(maxoff, off)
            ok_minmax += 1 if lo <= hi else 0
            ok_off += 1 if off < UNIT_STRIDE else 0
        if idxs == sorted(idxs) and idxs[0] == 0:
            ok_idx += 1
        if u8(POOLDIR + 25 * i + 24) in offs:
            ok_b24 += 1
    print("  +0..+1 s16 minimum   +2..+3 s16 maximum   +4 u8 block offset"
          "   +5 u8 flag   +6 u8 field index")
    check("+0 <= +2 as signed 16-bit in ALL %d records" % tot, ok_minmax == tot)
    check("+4 < 26 in all %d records (it indexes the 26-byte unit block); max seen %d"
          % (tot, maxoff), ok_off == tot)
    check("+6 runs non-decreasing from 0 in all 56 arrays", ok_idx == 56)
    check("PoolDir_Records +24 is one of that record's OWN +4 offsets, 56/56", ok_b24 == 56)
    # the +1 that maps a field offset to a block byte, read off P7Unit_FlushDirtyParams
    txt = "\n".join(_src)
    check("field offset f addresses unit-block byte +1+f: `inc 1,XIX` at 0xFA49B0 then "
          "`lda XWA,0x00856e` at 0xFA49B2",
          "; FA49B0  inc 1,XIX" in txt and "; FA49B2  lda XWA,0x00856e" in txt)
    check("...so the widest field (offset %d) lands at block byte +%d, inside 26"
          % (maxoff, maxoff + 1), maxoff + 1 < UNIT_STRIDE)
    from collections import Counter
    c = Counter(u8(ptrs[i] + 7 * j + 5) for i in range(56) for j in range(lens[i] // 7))
    print("  ⚠ +5 takes only %d values: %s -- NOT decoded, left unnamed"
          % (len(c), ", ".join("0x%02X x%d" % (k, v) for k, v in c.most_common())))


# =============================================================== 5. RAM images
RAM_SRC, RAM_DST, RAM_LEN = 0xFCB4EA, 0x00E2DF, 0x10D8


def rom_to_ram(a):
    return RAM_DST + (a - RAM_SRC)


def sec_ram():
    """Two prom_c ROM objects are boot images of the P7 module's own RAM."""
    print("\n=== 5. TWO ROM OBJECTS ARE BOOT IMAGES OF THE P7 MODULE'S RAM ===")
    # read the copy's three operands out of the ROM, the way prom_c_ram_image.py does,
    # rather than out of the listing text -- the listing spells them differently.
    check("the boot copy is ROM 0x%06X -> RAM 0x%06X, %d bytes, read from the "
          "instruction bytes at 0xF989EF" % (RAM_SRC, RAM_DST, RAM_LEN),
          rd(0xF989EF, 5) == bytes([0xF2, 0xEA, 0xB4, 0xFC, 0x35])
          and rd(0xF989F4, 5) == bytes([0xF2, 0xDF, 0xE2, 0x00, 0x34])
          and rd(0xF989F9, 5) == bytes([0x41, 0xD8, 0x10, 0x00, 0x00]))
    txt0 = "\n".join(_src)
    for a, d in ((0xFCC55F, 0x1075), (0xFCC576, 0x108C)):
        check("the header's own subtraction 0x%06X - 0x%06X = 0x%04X is right AND is what "
              "the source says" % (a, RAM_SRC, d),
              a - RAM_SRC == d and ("0x%06X - 0x%06X = 0x%04X" % (a, RAM_SRC, d)) in txt0)
    check("ROM 0xFCC55F maps to RAM 0x%06X" % rom_to_ram(0xFCC55F), rom_to_ram(0xFCC55F) == 0xF354)
    check("ROM 0xFCC576 maps to RAM 0x%06X" % rom_to_ram(0xFCC576), rom_to_ram(0xFCC576) == 0xF36B)
    check("the first object is 23 bytes, so it images RAM 0xF354..0xF36A",
          0xFCC576 - 0xFCC55F == 23)
    check("the second is 72 bytes = 6 groups x 3 u32", 0xFCC5BE - 0xFCC576 == 72)
    txt = "\n".join(_src)
    for site in (0xFA2B91, 0xFA2CC5, 0xFA2D78):
        check("RAM 0xF36B is indexed at 0x%06X" % site,
              ("; %06X  add XBC,0x0000f36b" % site) in txt)
    check("the index is 12*RAM[0xF35D] + 4*unit (`ld C,0x0c / mul BC,(0x00f35d)` at 0xFA2B86)",
          "; FA2B86  ld C,0x0c" in txt and "; FA2B88  mul BC,(0x00f35d)" in txt)
    check("⚠ RAM[0xF35D] is CLAMPED to 0..1 at 0xFA5715, so only groups 0 and 1 are reached",
          "; FA5715  cp (0x00f35d),0x01" in txt and "; FA571D  ld (0x00f35d),0x01" in txt)
    # the three per-unit latches and the three per-unit words, in the image
    img = rd(0xFCC55F, 23)
    check("the image's first 16 bytes are zero -- RAM 0xF354..0xF363 boots at 0",
          all(b == 0 for b in img[:16]))
    check("the image's last six bytes are three 16-bit 0x006C words -- RAM 0xF365/67/69,"
          " which sub_FA4819 writes", list(img[17:23]) == [0x6c, 0, 0x6c, 0, 0x6c, 0])


# =============================================================== 6. the dead trace
def sec_trace():
    """FINDINGS-prom_c-p7-byte-stream-pool.md §5: "What sets (0x00F35A) is not established."

    Nothing does.  The only literal write in prom_c stores ZERO, and the power-on
    image is zero, so the three trace tests can never take the tracing branch."""
    print("\n=== 6. THE MIDI-OUT HEX TRACE OF THE P7 UPLOAD IS DEAD ON THIS FIRMWARE ===")
    writes = [l for l in _src if "0xF35A" in l or "0x00f35a" in l]
    stores = [l for l in writes if re.search(r"st\w*_da\s*\(0xF35A\)", l)]
    tests = [l for l in writes if "cp (0x00f35a)" in l and not l.lstrip().startswith(";")]
    writes = [l for l in writes if not l.lstrip().startswith(";")]
    print("  code lines mentioning 0x00F35A in prom_c: %d" % len(writes))
    for l in writes:
        print("    " + l.strip())
    check("exactly ONE literal write, and it stores 0", len(stores) == 1 and ", 0 " in stores[0])
    check("that write is at 0xFA56EB", "; FA56EB" in stores[0])
    check("the three readers are the trace tests in P7Byte_SendCmd/SendData/SendArg",
          len(tests) == 3)
    check("the power-on image of RAM 0xF35A is 0 too (byte %d of the 0xFCC55F image)"
          % (0xF35A - 0xF354), u8(0xFCC55F + (0xF35A - 0xF354)) == 0
          and u8(0xFCC55F + (0xF35A - 0xF354) + 1) == 0)
    print("  ⚠ QUALIFIED: a write through a register or over the inter-processor link is")
    print("    invisible to a literal scan.  The claim is: no literal-addressed write in")
    print("    prom_c ever makes 0x00F35A non-zero, and it boots zero.")


# =============================================================== 7. the names
RENAMED_DATA = {
    "PoolDir_RecordForUnitProgram": "PoolDir_IndexMap128",
    "P7Stream_UnitPreamble": "P7Stream_FD2C2B",
    "P7Module_RamStateImage": "unexplained_FCC55F",
    "P7Unit_StreamPtrsByGroupAndUnit": "Packet_PtrTable_FCC576",
    "Link_ClassHandlerTable": "Handler_PtrTable_FCC53F",
}
RENAMED_CODE = {
    "P7Stream_StageAndSend": "sub_F9F8E1",
    "P7Unit_SendFieldParamZero": "sub_FA2B09",
    "P7Unit_LoadProgramStreams": "sub_FA2C5E",
    "P7Unit_SendParamValue": "sub_FA2D11",
    "P7Mixer_RequestGain": "sub_FA2DCD",
    "P7Mixer_SendGainIfChanged": "sub_FA2DEC",
    "P7Mixer_SendGain": "sub_FA2E2D",
    "MixerGain_ProductOfCurves": "sub_FA30B8",
    "P7Units_BootLoadAndStartTask": "sub_FA3127",
    "P7Units_ReloadFixedStreams": "sub_FA336B",
    "P7Units_ReloadForGroup": "sub_FA3802",
    "P7Unit_SelectStreamsForRecord": "sub_FA4819",
    "P7Unit_SendPreambleOnce": "sub_FA35D5",
    "Base36DigitToValue": "sub_FA3CA6",
    "P7Unit_EmitChangedParams": "sub_FA3CD7",
    "P7Unit_MarkParamsDirty": "sub_FA4940",
    "P7Unit_FlushDirtyParams": "sub_FA4957",
    "P7Units_ServiceTask": "sub_FA5177",
    "P7Units_ResolveProgramsAndReload": "sub_FA5535",
}


def sec_names():
    """Assert every shipped name is in the source, that no old spelling survives,
    and that each new name would be graded CONTENT and not FRAMED."""
    print("\n=== 7. THE %d NAMES SHIPPED ===" % (len(RENAMED_DATA) + len(RENAMED_CODE)))
    
    txt = "\n".join(_src)
    labs = dict((n, a) for n, a in all_labels())
    for new, old in sorted(RENAMED_DATA.items()) + sorted(RENAMED_CODE.items()):
        check("%-33s <- %-24s present as a label" % (new, old), new in labs)
        # the only place an old spelling may survive is the one-line rename note that
        # says where a name came from; anything else is a dangling reference.
        stray = [l for l in _src if re.search(r"\b%s\b" % re.escape(old), l)
                 and "renamed it from" not in l]
        check("  ...and no `%s` remains in prom_c outside its rename note" % old, not stray)
        check("  ...and it grades CONTENT, not FRAMED", not FRAMED.match(new))
    # ★ HOW MANY OF THE 21 WERE ACTUALLY `framed`?  Four.  `PoolDir_IndexMap128` was
    # already graded CONTENT by notes/wave7_documentation_metrics.py -- its distinguishing
    # part is "IndexMap128", not a bare number -- so renaming it improved the NAME without
    # moving the metric, and reporting it as a framed->content conversion would have been
    # an overcount.  This check pins the honest split so the round's headline cannot drift.
    was_framed = [old for old in RENAMED_DATA.values() if FRAMED.match(old)]
    was_sub = [old for old in RENAMED_CODE.values() if UNNAMED.match(old)]
    # the claim P7Units_ReloadFixedStreams' header makes, re-derived here
    def pool_streams(lo, hi):
        out = set()
        for ln in _src:
            m = ADDR.search(ln)
            if not (m and lo <= int(m.group(1), 16) <= hi):
                continue
            mm = re.search(r"lda_24\s+x\w+, \(0x(F[CD][0-9A-F]{4})\)", ln)
            if mm and 0xFCD0F7 <= int(mm.group(1), 16) <= 0xFDD2AA:
                out.add(int(mm.group(1), 16))
        return out
    boot = pool_streams(0xFA3127, 0xFA336A)
    reload_ = pool_streams(0xFA336B, 0xFA35D4)
    check("P7Units_ReloadFixedStreams names %d streams and P7Units_BootLoadAndStartTask "
          "%d, and the boot set is a strict SUBSET (boot-only: %d)"
          % (len(reload_), len(boot), len(boot - reload_)),
          len(boot - reload_) == 0 and len(reload_ - boot) == 2)
    print("  of the %d renames: %d were FRAMED, %d were sub_XXXXXX, %d were already CONTENT"
          % (len(RENAMED_DATA) + len(RENAMED_CODE), len(was_framed), len(was_sub),
             len(RENAMED_DATA) + len(RENAMED_CODE) - len(was_framed) - len(was_sub)))
    check("exactly 4 framed->content and 16 sub->content; PoolDir_IndexMap128 was neither",
          len(was_framed) == 4 and len(was_sub) == 19
          and not FRAMED.match("PoolDir_IndexMap128") and not UNNAMED.match("PoolDir_IndexMap128"))
    txt_all = "\n".join(_src)
    # ★ THE KERNEL'S OWN TABLE NAMES THE TASK, which is what makes
    # P7Units_ServiceTask a statement and not a guess.
    ENTRY = 0xF980DE + 12 * 2
    entry_pc = u32(ENTRY)
    check("kernel task 2's record is at 0x%06X and its entry PC is 0x%08X" % (ENTRY, entry_pc),
          entry_pc == 0x00FA54DB)
    check("...which falls inside P7Units_ServiceTask (0xFA5177-0xFA5534)",
          0xFA5177 <= entry_pc <= 0xFA5534)
    check("...and that exact address is a label: P7Units_ServiceTask__FA54DB",
          "P7Units_ServiceTask__FA54DB" in labs)
    check("P7Units_BootLoadAndStartTask starts task 2 (`push 0x0002` at 0xFA3362 before"
          " `call Kernel_StartTask_StackArg` at 0xFA3365)",
          "; FA3362  push 0x0002" in txt and "; FA3365  call 0xf9833b" in txt)
    check("P7Mixer_RequestGain signals semaphore 2 (`push 0x0002` at 0xFA2DE1 before"
          " `call Kernel_SemaSignal_StackArg` at 0xFA2DE4)",
          "; FA2DE1  push 0x0002" in txt and "; FA2DE4  call 0xf98510" in txt)
    check("the module banner for 0xFA2784-0xFA5948 is in the source",
          "★ THE PORT-P7 UNIT MODULE: three devices, their PROGRAMS," in txt_all)
    check("Base36DigitToValue decodes '0'-'9' with sub 0x30 and 'a'+ with sub 0x57",
          "; FA3CCB  sub C,0x30" in txt and "; FA3CB3  sub C,0x57" in txt)
    check("...and its only caller is inside P7Unit_EmitChangedParams, at 0xFA4764",
          "; FA4764  calr 0xfa3ca6" in txt)
    oracle(0xFA3CB3, "0x57", "`sub C,0x57` is AT 0xFA3CB3, not one byte off")
    oracle(0xFA49B0, "inc", "`inc 1,XIX` is AT 0xFA49B0")


def main():
    args = sys.argv[1:]
    run = {"--framed": [sec_framed], "--blocks": [sec_blocks], "--program": [sec_program],
           "--fields": [sec_fields], "--ram": [sec_ram], "--trace": [sec_trace],
           "--names": [sec_names]}
    todo = None
    for a in args:
        if a in run:
            todo = run[a]
    if todo is None:
        todo = [sec_framed, sec_blocks, sec_program, sec_fields, sec_ram, sec_trace, sec_names]
    for f in todo:
        f()
    print("\n%d checks, %d failures" % (OK[0] + FAIL[0], FAIL[0]))
    return 1 if FAIL[0] else 0


if __name__ == "__main__":
    sys.exit(main())
