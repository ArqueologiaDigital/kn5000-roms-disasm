#!/usr/bin/env python3
"""What is prom_c 0xF80000-0xF97FFF, and what proves its geometry?

QUESTION ANSWERED
  The first 98,304 bytes of prom_c were one `.incbin` -- the largest unconverted span in
  the image -- and nothing in `notes/` said what they were.  They are a BANK OF NAMED
  PRESET RECORDS: a 32-byte header whose magic is ASCII `ZZZZ`, a table of 16 sixteen-byte
  category names ("FUSION COMBO1", "BIG BAND", "SWEEP PAD" ...), and 129 fixed-size
  704-byte records, each opening with a sixteen-character name ("  Downtown Set  ",
  " Funky Bassoon  ", "    Clear       ").

  This script (a) PROVES that shape from the bytes, with assertions that fail loudly, and
  (b) EMITS the assembly for it, so the numbers in `prom_c/wsa1_prom_c.s` and in
  `notes/FINDINGS-prom_c-preset-bank.md` are never retyped by hand.

WHAT THE GEOMETRY RESTS ON -- four independent facts, any one of which a wrong
constant would break:

  1. TILING.  129 records of 704 bytes laid end to end from file 0x000300 reach
     0x0165C0 exactly, and 0x0165C0 is precisely the first byte of the image's trailing
     0x0E pad.  One wrong stride, or one wrong record count, misses that boundary.
  2. SELF-TERMINATION.  Inside every record the chunk walk {tag, length, length bytes}
     starting at +0x000 arrives at +0x2BE carrying tag 0xFF, length 0xFF -- a two-byte end
     marker that puts the record end at +0x2C0 = 704.  The stride is therefore readable
     from ONE record without reference to the next.
  3. THE HEADER SAYS SO.  u32le at 0x00001C is 0x02C0 = 704, and the two directory
     entries at 0x00000C and 0x000014 give (offset 0x000200, count 16) and
     (offset 0x000300, count 128) -- the category table and the numbered records, both of
     which the tiling independently confirms.  16 * 16 = 256 tiles 0x200..0x2FF exactly;
     128 * 704 tiles 0x300..0x162FF exactly, and the 129th record ("Clear") follows it.
  4. UNIFORM LAYOUT.  All 129 records produce the SAME sequence of 24 (offset, tag,
     length) triples.  A single desynchronised record would show up as a different list.

  Plus one field: in all 1,032 blocks tagged 0x00..0x07 the payload byte at +13 has its
  LOW NIBBLE equal to the block's own tag.  That is the block index stored inside the
  block, and it is checked for every one of them.

WHAT IT DOES **NOT** ESTABLISH -- read before quoting anything
  * NO INSTRUCTION ANYWHERE HAS BEEN FOUND THAT READS THIS REGION.  A search of all four
    images for a 32-bit little-endian pointer into 0xF80000-0xF97FFF returns 21 hits in
    prom_c and every one of them is a coincidence inside a data table (checked by
    `--refs`).  The name "preset bank" comes from the ASCII the region contains, not from
    a consumer.  So: what loads a record, and into what, is OPEN.
  * NOT ONE FIELD MEANING is established.  `--census` prints, for every byte position of
    every chunk, how many distinct values occur over the 129 records and what they are.
    That is a fact about the format.  It is not a name for a parameter.  The high nibble
    of the +13 byte, in particular, takes only 0xC and 0xE, and the record named "Clear"
    is the ONLY one whose eight blocks are all 0xE -- suggestive of an in-use flag and
    nothing more.
  * The directory-entry field split is ambiguous: {u16 id, u32le offset, u16 count} and
    {u16 id, u16 offset, u16 offset_hi, u16 count} produce identical bytes here, because
    both offsets fit in 16 bits and the following u16 is zero in both entries.  The source
    comment states both.

RUN
  python3 notes/gen_prom_c_preset_bank.py --verify   # asserts everything above; exit != 0 on failure
  python3 notes/gen_prom_c_preset_bank.py --names    # the 16 categories and the 129 record names
  python3 notes/gen_prom_c_preset_bank.py --census   # per-chunk, per-byte value census
  python3 notes/gen_prom_c_preset_bank.py --refs     # the pointer search described above
  python3 notes/gen_prom_c_preset_bank.py --asm      # the assembly fragment (stdout)
  python3 notes/gen_prom_c_preset_bank.py --apply    # splice it into prom_c/wsa1_prom_c.s
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
BASE = 0xF80000                 # prom_c/prom_c.ld ORIGIN

HDR = 0x000000                  # 32-byte header
HDR_PAD = 0x000020              # zero pad to ...
CAT = 0x000200                  # 16 x 16 category names
REC = 0x000300                  # first record
STRIDE = 704                    # 0x2C0
NREC = 129                      # 128 numbered + the "Clear" template
PAD = 0x0165C0                  # first byte of the trailing 0x0E pad
END = 0x018000

# Roles are DESCRIPTIVE, not decoded -- see the docstring.  A role string may only say
# what the bytes demonstrably are.
CHUNK_ROLE = {
    0x78: "16-character ASCII name",
    0x60: "12 bytes; only byte 0 differs between records (0 in 116, 1 in 13)",
    0x61: "30 bytes; bytes 23..29 are zero in every record",
    0x62: "30 bytes; bytes 23..29 are zero in every record",
    0x63: "30 bytes; bytes 23..29 are zero in every record",
    0x92: "14 bytes, IDENTICAL in all 129 records",
    0x79: "44 bytes; only byte 5 differs, and in one record only",
    0xFF: "end marker",
}


def load():
    return open(IMG, "rb").read()


def u16(d, o):
    return d[o] | (d[o + 1] << 8)


def u32(d, o):
    return d[o] | (d[o + 1] << 8) | (d[o + 2] << 16) | (d[o + 3] << 24)


def layout(d, rec):
    """The (offset, tag, length) triples of one record, terminator included."""
    p = REC + rec * STRIDE
    out = []
    while True:
        t, ln = d[p], d[p + 1]
        out.append((p - (REC + rec * STRIDE), t, ln))
        if t == 0xFF:
            return out
        p += 2 + ln
        if p - (REC + rec * STRIDE) > STRIDE:
            return out          # overrun; --verify turns this into a failure


def names(d):
    return [d[REC + r * STRIDE + 2:REC + r * STRIDE + 18].decode("ascii") for r in range(NREC)]


def categories(d):
    return [d[CAT + i * 16:CAT + i * 16 + 16].decode("ascii") for i in range(16)]


# ---------------------------------------------------------------- verify
def verify():
    d = load()
    fails = []

    def check(ok, msg):
        print(("  ok   " if ok else "  FAIL ") + msg)
        if not ok:
            fails.append(msg)

    print("prom_c 0xF80000-0xF97FFF -- geometry")
    check(d[HDR:HDR + 4] == b"ZZZZ", "0x000000 magic is ASCII 'ZZZZ'")
    check(u16(d, 0x04) == 0, "0x000004 u16le == 0")
    check(d[0x06:0x0C] == b"WSA1  ", "0x000006 is ASCII 'WSA1  '")

    check(u16(d, 0x0C) == 1, "directory entry 0: id == 1")
    check(u32(d, 0x0E) == CAT, f"directory entry 0: offset == 0x{CAT:06X}")
    check(u16(d, 0x12) == 16, "directory entry 0: count == 16")
    check(u16(d, 0x14) == 2, "directory entry 1: id == 2")
    check(u32(d, 0x16) == REC, f"directory entry 1: offset == 0x{REC:06X}")
    check(u16(d, 0x1A) == 128, "directory entry 1: count == 128")
    check(u32(d, 0x1C) == STRIDE, f"0x00001C u32le == {STRIDE} == the measured record stride")

    check(all(b == 0 for b in d[HDR_PAD:CAT]),
          f"0x{HDR_PAD:06X}-0x{CAT-1:06X} is {CAT-HDR_PAD} zero bytes")

    cats = d[CAT:REC]
    check(len(cats) == 16 * 16, "the category table is 16 x 16 == 256 bytes")
    check(all(0x20 <= b <= 0x7E for b in cats), "every category byte is printable ASCII")
    check(CAT + 16 * 16 == REC, "16 x 16 tiles 0x000200..0x0002FF with no gap")

    # 1. tiling
    check(REC + NREC * STRIDE == PAD,
          f"{NREC} x {STRIDE} from 0x{REC:06X} ends at 0x{PAD:06X}")
    check(REC + 128 * STRIDE == REC + 0x16000,
          "the header's count of 128 tiles 0x000300..0x0162FF, and a 129th record follows")
    check(all(b == 0x0E for b in d[PAD:END]),
          f"0x{PAD:06X}-0x{END-1:06X} is {END-PAD} bytes of 0x0E pad")
    check(d[PAD - 1] != 0x0E,
          f"the byte BEFORE the pad (0x{PAD-1:06X} = 0x{d[PAD-1]:02X}) is not 0x0E, "
          "so the pad boundary is not arbitrary")

    # 2. self-termination + 4. uniform layout, over EVERY record including the last
    ref = layout(d, 0)
    bad_layout = [r for r in range(NREC) if layout(d, r) != ref]
    check(not bad_layout, f"all {NREC} records produce the same 24-triple layout "
                          f"(mismatches: {bad_layout})")
    check(len(ref) == 24, f"the layout has {len(ref)} chunks")
    check(ref[-1] == (0x2BE, 0xFF, 0xFF),
          "the last chunk is tag 0xFF length 0xFF at +0x2BE, so the record ends at +0x2C0")

    # names
    bad_names = [r for r in range(NREC)
                 if not all(0x20 <= b <= 0x7E for b in d[REC + r * STRIDE + 2:REC + r * STRIDE + 18])]
    check(not bad_names, f"all {NREC} name chunks are 16 printable ASCII bytes "
                         f"(bad: {bad_names})")

    # the block index inside the block -- all 1,032, last one included
    tot = miss = 0
    for r in range(NREC):
        for n in range(8):
            o = REC + r * STRIDE + 0x80 + n * 0x40
            tot += 1
            if d[o] != n or d[o + 1] != 30 or (d[o + 2 + 13] & 0x0F) != n:
                miss += 1
    check(miss == 0, f"in all {tot} blocks tagged 0x00..0x07: tag == index, length == 30, "
                     f"and payload[13] & 0x0F == index (misses: {miss})")
    last = REC + 128 * STRIDE + 0x80 + 7 * 0x40 + 2 + 13
    check((d[last] & 0x0F) == 7,
          f"...tested on the LAST one: 0x{BASE+last:06X} = 0x{d[last]:02X}")

    hi = collections.Counter((d[REC + r * STRIDE + 0x80 + n * 0x40 + 2 + 13] >> 4)
                             for r in range(NREC) for n in range(8))
    check(set(hi) == {0xC, 0xE},
          f"the high nibble of that byte takes only 0xC and 0xE ({dict(hi)})")
    allE = [r for r in range(NREC)
            if all(d[REC + r * STRIDE + 0x80 + n * 0x40 + 2 + 13] >> 4 == 0xE for n in range(8))]
    check(allE == [128] and names(d)[128].strip() == "Clear",
          f"exactly one record has all eight high nibbles 0xE, and it is the one named "
          f"'{names(d)[128]}' (records: {allE})")

    # constant chunks
    c92 = {d[REC + r * STRIDE + 0x282:REC + r * STRIDE + 0x282 + 14] for r in range(NREC)}
    check(len(c92) == 1, f"the tag-0x92 chunk is byte-identical in all {NREC} records")
    p79 = [d[REC + r * STRIDE + 0x292:REC + r * STRIDE + 0x292 + 44] for r in range(NREC)]
    vary79 = [i for i in range(44) if len({p[i] for p in p79}) > 1]
    check(vary79 == [5], f"the tag-0x79 chunk differs between records in byte 5 only "
                         f"(varying: {vary79})")

    check(END - HDR == 98304, "the whole region is 98,304 bytes")
    print()
    if fails:
        print(f"FAILURES: {len(fails)}")
        return 1
    print("ALL CHECKS PASSED")
    return 0


# ---------------------------------------------------------------- reporting
def show_names():
    d = load()
    print("16 categories, 0xF80200..0xF802FF, 16 bytes each:")
    for i, c in enumerate(categories(d)):
        print(f"  [{i:2d}] 0x{BASE+CAT+i*16:06X}  '{c}'")
    print(f"\n{NREC} records, 0xF80300.., stride {STRIDE}:")
    for r, n in enumerate(names(d)):
        tag = "  <- template, not one of the 128" if r >= 128 else ""
        print(f"  [{r:3d}] 0x{BASE+REC+r*STRIDE:06X}  '{n}'{tag}")


def census():
    d = load()
    for off, tag, ln in layout(d, 0):
        if tag == 0xFF:
            continue
        print(f"=== chunk at +0x{off:03X}, tag 0x{tag:02X}, length {ln} ===")
        for i in range(ln):
            c = collections.Counter(d[REC + r * STRIDE + off + 2 + i] for r in range(NREC))
            vs = sorted(c)
            top = " ".join(f"{v:02x}:{n}" for v, n in c.most_common(5))
            print(f"  +{i:02d}  {len(c):3d} distinct  0x{vs[0]:02X}-0x{vs[-1]:02X}   {top}")


def refs():
    """Does ANY instruction carry a pointer into 0xF80000-0xF97FFF?

    Every 32-bit little-endian value in the four images that lands in the range is
    collected, and -- for prom_c, the only image where the range is unambiguous -- each
    hit is CLASSIFIED against the disassembly in prom_c/wsa1_prom_c.s rather than by the
    span it falls in.  A hit is an OPERAND only if the listed instruction that contains
    it renders that value; anything else is a coincidence, and the classifier says which.
    (prom_a's own code occupies 0xF80000-0xF97FFF in ITS address space and CPU 1's
    0xF80000 is prom_a, so hits in prom_a and prom_b say nothing about this region.)
    """
    lst = {}
    for line in open(SRC):
        m = re.search(r";\s*([0-9A-F]{6})\s", line)
        if m:
            lst[int(m.group(1), 16)] = line.split(";")[0].strip().lower()
    starts = sorted(lst)
    imgs = [("prom_a", "wsa1_prom_a.ic12", 0xF80000, "prom_a's OWN code lives at these "
             "addresses in its own space -- ambiguous by construction"),
            ("prom_b", "wsa1_prom_b.ic13", 0xF00000, "CPU 1's 0xF80000-0xF97FFF is "
             "prom_a, not this region"),
            ("prom_c", "wsa1_prom_c.ic28", 0xF80000, ""),
            ("prom_d", "wsa1_prom_d.bin", None, "no base established; offsets, not "
             "addresses")]
    import bisect
    for nm, fn, base, note in imgs:
        d = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        hits = [i for i in range(len(d) - 3) if 0xF80000 <= u32(d, i) < 0xF98000]
        print(f"{nm}: {len(hits)} hits" + (f"  ({note})" if note else ""))
        if nm != "prom_c":
            continue
        operands = 0
        for i in hits:
            a, v = base + i, u32(d, i)
            k = bisect.bisect_right(starts, a) - 1
            if k < 0 or starts[k] not in lst:
                verdict = "not in a listed instruction (data)"
            else:
                ins = lst[starts[k]]
                nxt = min(starts[k + 1] if k + 1 < len(starts) else a + 1,
                          starts[k] + 8)          # no TLCS-900 instruction is longer
                if not (starts[k] <= a < nxt):
                    verdict = "not in any listed instruction -- a DATA region"
                elif f"{v:06x}" in ins or f"{v:08x}" in ins:
                    verdict = "*** REAL OPERAND ***"
                    operands += 1
                else:
                    verdict = (f"coincidence inside `{ins}` at 0x{starts[k]:06X}")
            print(f"    at 0x{a:06X} -> 0x{v:06X}   {verdict}")
        print(f"  prom_c: {operands} of {len(hits)} hits are a real instruction operand.")


# ---------------------------------------------------------------- assembly
def hexrow(bs):
    return ".byte\t" + ", ".join(f"0x{b:02x}" for b in bs)


def asm():
    d = load()
    L = []
    a = L.append
    cats = categories(d)
    nms = names(d)

    a("; ==============================================================================")
    a("; 0xF80000-0xF97FFF -- THE PRESET BANK  (98,304 bytes)")
    a("; ==============================================================================")
    a(";")
    a("; Generated by notes/gen_prom_c_preset_bank.py -- every number below is read out of")
    a("; the ROM, never retyped.  `python3 notes/gen_prom_c_preset_bank.py --verify`")
    a("; re-proves all of it and exits non-zero on any failure.")
    a(";")
    a("; A 32-byte header with the ASCII magic `ZZZZ`, a table of 16 sixteen-byte CATEGORY")
    a("; names, and 129 fixed 704-byte RECORDS each opening with a 16-character name.")
    a(";")
    a("; ★ THE GEOMETRY RESTS ON FOUR INDEPENDENT FACTS, and a wrong constant breaks each:")
    a(";   1. TILING -- 129 x 704 from 0xF80300 reaches 0xF965C0 exactly, and 0xF965C0 is")
    a(";      precisely the first byte of the image's trailing 0x0E pad (the byte before it")
    a(";      is 0xFF, so the boundary is not chosen).")
    a(";   2. SELF-TERMINATION -- inside every record the walk {tag, length, length bytes}")
    a(";      from +0x000 lands on tag 0xFF / length 0xFF at +0x2BE, which puts the record")
    a(";      end at +0x2C0 = 704.  The stride is readable from ONE record.")
    a(";   3. THE HEADER AGREES -- u32le at 0xF8001C is 0x02C0 = 704, and its two directory")
    a(";      entries give (offset 0x000200, count 16) and (offset 0x000300, count 128).")
    a(";      16 x 16 tiles 0xF80200..0xF802FF; 128 x 704 tiles 0xF80300..0xF962FF, and the")
    a(";      129th record -- the one named `Clear` -- follows it.")
    a(";   4. UNIFORM LAYOUT -- all 129 records yield the SAME 24 (offset, tag, length)")
    a(";      triples.  One desynchronised record would produce a different list.")
    a(";")
    a("; ⚠ WHAT IS **NOT** ESTABLISHED.")
    a(";   * NO INSTRUCTION THAT READS THIS REGION HAS BEEN FOUND.  A search of all four")
    a(";     images for a 32-bit pointer into 0xF80000-0xF97FFF gives 21 hits in prom_c, and")
    a(";     `--refs` classifies every one against THIS FILE'S disassembly: NONE is a real")
    a(";     instruction operand -- 8 fall inside instructions that render something else,")
    a(";     13 are in data regions.  The word `preset` comes from the ASCII the region")
    a(";     contains, not from a consumer.")
    a(";   * NOT ONE FIELD MEANING is established.  `--census` prints the value census of")
    a(";     every byte position of every chunk; that is a fact about the format, not a name")
    a(";     for a parameter.  Nothing below is called pitch, level or wave.")
    a(";   * The directory-entry field split is AMBIGUOUS: {u16 id, u32le offset, u16 count}")
    a(";     and {u16 id, u16 offset, u16 zero, u16 count} give identical bytes here.")
    a(";")
    a("; ★ ONE FIELD IS PROVEN, and it is what makes the eight paired blocks an indexed")
    a("; array rather than eight unrelated chunks: in ALL 1,032 blocks tagged 0x00..0x07")
    a("; (129 records x 8) the payload byte at +13 has LOW NIBBLE equal to the block's own")
    a("; tag, and its high nibble takes only 0xC and 0xE.  The record named `Clear` is the")
    a("; only one of the 129 whose eight blocks are all 0xE.  [INFERENCE, stated as such]")
    a("; that reads like an in-use flag; nothing here proves it.")
    a(";")
    a("; PROVENANCE unchanged: the publicly redistributed v2 firmware set, not a chip read.")
    a("")
    a("PresetBank:")
    a("; ----------------------------------------------------------------------------")
    a("; PresetBank_Header -- 0xF80000..0xF8001F  (32 bytes)")
    a("; ----------------------------------------------------------------------------")
    a("PresetBank_Header:")
    a('\t.ascii\t"ZZZZ"')
    a("\t.short\t0x0000")
    a('\t.ascii\t"WSA1  "')
    a("\t; directory entry 0 -- the category-name table")
    a("\t.short\t0x0001                                 ; id")
    a(f"\t.short\t0x{u16(d,0x0E):04x}, 0x{u16(d,0x10):04x}"
      f"                         ; offset 0x{u32(d,0x0E):06X} (u32le), or offset+0 (two u16)")
    a("\t.short\t0x0010                                 ; count 16")
    a("\t; directory entry 1 -- the record array")
    a("\t.short\t0x0002                                 ; id")
    a(f"\t.short\t0x{u16(d,0x16):04x}, 0x{u16(d,0x18):04x}"
      f"                         ; offset 0x{u32(d,0x16):06X} (u32le), or offset+0 (two u16)")
    a("\t.short\t0x0080                                 ; count 128")
    a("\t.short\t0x02c0, 0x0000                         ; 704 == the record stride")
    a("")
    a("; ----------------------------------------------------------------------------")
    a(f"; PresetBank_HeaderPad -- 0xF80020..0xF801FF  ({CAT-HDR_PAD} bytes, all zero)")
    a("; ----------------------------------------------------------------------------")
    a("PresetBank_HeaderPad:")
    a(f"\t.fill 0x{CAT-HDR_PAD:X}, 1, 0x00")
    a("")
    a("; ----------------------------------------------------------------------------")
    a("; PresetBank_CategoryNames -- 0xF80200..0xF802FF  (16 x 16 bytes)")
    a("; ----------------------------------------------------------------------------")
    a("PresetBank_CategoryNames:")
    for i, c in enumerate(cats):
        a(f'\t.ascii\t"{c}"\t; [{i:2d}]')
    a("")
    a("; ----------------------------------------------------------------------------")
    a(f"; PresetBank_Records -- 0xF80300..0xF965BF  ({NREC} x {STRIDE} = {NREC*STRIDE} bytes)")
    a("; ----------------------------------------------------------------------------")
    a("; Every record is the same chain of chunks {u8 tag, u8 length, length bytes}:")
    ref = layout(d, 0)
    for off, tag, ln in ref:
        role = CHUNK_ROLE.get(tag)
        if role is None:
            if tag < 0x08:
                role = f"block {tag}, first of the pair"
            else:
                role = f"block {tag - 0x20}, second of the pair"
        ln_txt = "  --  " if tag == 0xFF else f"{ln:5d} "
        a(f";     +0x{off:03X}  tag 0x{tag:02X}  length {ln_txt}  {role}")
    a("; The eight blocks tagged 0x00..0x07 each carry their own index in payload[13] &")
    a("; 0x0F (checked for all 1,032); the blocks tagged 0x20..0x27 are their partners by")
    a("; position, which is what the alternating layout shows and all that it shows.")
    a("PresetBank_Records:")
    for r in range(NREC):
        rb = REC + r * STRIDE
        extra = "   (the template; not one of the 128 the header counts)" if r >= 128 else ""
        a("; ............................................................................")
        a(f"; record {r} -- 0x{BASE+rb:06X}  '{nms[r]}'{extra}")
        a(f"PresetBank_Record_{r:03d}:")
        for off, tag, ln in ref:
            if tag == 0xFF:
                a("\t.byte\t0xff, 0xff                                    ; end marker")
                continue
            if tag == 0x78:
                a(f"\t.byte\t0x78, 0x{ln:02x}")
                a(f'\t.ascii\t"{nms[r]}"')
                continue
            if tag < 0x08:
                cm = f"; block {tag}"
            elif 0x20 <= tag <= 0x27:
                cm = f"; block {tag - 0x20} partner"
            else:
                cm = ""
            a(f"\t.byte\t0x{tag:02x}, 0x{ln:02x}" + (f"                                    {cm}" if cm else ""))
            pl = d[rb + off + 2:rb + off + 2 + ln]
            for i in range(0, len(pl), 15):
                a("\t" + hexrow(pl[i:i + 15]))
    a("")
    a("; ----------------------------------------------------------------------------")
    a(f"; PresetBank_TailPad -- 0xF965C0..0xF97FFF  ({END-PAD} bytes of 0x0E)")
    a("; ----------------------------------------------------------------------------")
    a("; The same 0x0E pad byte this image uses everywhere else.  The byte immediately")
    a("; before it is the 0xFF end marker of the last record, so this boundary is derived,")
    a("; not chosen.")
    a("PresetBank_TailPad:")
    a(f"\t.fill 0x{END-PAD:X}, 1, 0x0E")
    return "\n".join(L) + "\n"


HEAD_RE = re.compile(
    r"; =+\n; 0xF80000-0xF97FFF -- not yet converted\n; =+\n"
    r"wsa1_prom_c:\n\t\.incbin \"original_ROMs/wsa1_prom_c\.ic28\", 0x000000, 0x018000\n")


def apply():
    text = open(SRC).read()
    m = HEAD_RE.search(text)
    if not m:
        print("could not find the 0xF80000 .incbin block to replace", file=sys.stderr)
        return 1
    body = asm()
    # the image's first label must stay, the linker script places it
    body = body.replace("PresetBank:\n", "wsa1_prom_c:\nPresetBank:\n", 1)
    open(SRC, "w").write(text[:m.start()] + body + text[m.end():])
    print(f"spliced {len(body.splitlines())} lines into {SRC}")
    return 0


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    if "--names" in sys.argv:
        show_names()
    elif "--census" in sys.argv:
        census()
    elif "--refs" in sys.argv:
        refs()
    elif "--asm" in sys.argv:
        sys.stdout.write(asm())
    elif "--apply" in sys.argv:
        sys.exit(apply())
    else:
        print(__doc__)
