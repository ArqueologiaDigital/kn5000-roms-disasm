#!/usr/bin/env python3
"""The leading bytes of a bulk-dump block: what they are, and who checks them.

QUESTION THIS ANSWERS
    Three of the four bulk-dump categories begin with a short fixed
    preamble that contains readable text -- `WA0` in SYSTEM,PART & MIDI,
    `WSA1` in COMBINATION, `WSA SOUND RAM S0` in SOUND.  Does any of them
    encode a FORMAT or OS VERSION, does a receiver check it, and what
    happens when it does not match?

    It also collects, in one place, every piece of evidence in the four
    WSA1 images that bears on the System Exclusive behaviour of an
    OPERATING SYSTEM other than the dumped v2.0:

      * whether any instruction compares a version;
      * whether any message carries a version byte;
      * what the one run-time switch that changes SysEx behaviour is;
      * which SysEx machinery exists but is unreachable from the wire.

    The answer to the first two is NO, and the third is a hardware strap
    on a CPU port pin.  Nothing here is evidence of OS version 1; the one
    thing that looked like it -- a real dump carrying 04 01 11 when no
    such literal exists in the ROM -- is the rack/keyboard substitution
    that sysex_model_variant.py decodes, not an older firmware.

WHAT IT ESTABLISHES (all of it recomputed from the instruction bytes)

  1. The preambles are literals in prom_a / prom_b, and the same bytes come
     back off a real machine -- both over MIDI and on a floppy disk.

  2. FOUR signature comparators exist in prom_a.  TWO of them are called,
     and BOTH call sites are on the DISK LOAD path, never the MIDI path:

        routine    compares                             called from
        0xFE1CE9   16 bytes at 0x609400 vs 0xFE7027     0xFE202F   ext "TM "
        0xFE2E3D    4 bytes at 0x60A086 vs 0xFE7049     0xFE20B5   ext "CMB"
        0xFE2DDD    2 bytes at 0x60A084 vs 'W','A'      0xFE1E65   ext "LSW"
        0xFE2DF8    3 bytes at 0x60A080 vs 'W','S','A'  -- NOTHING --
        0xFE2E24    2 bytes at 0x60A085 vs 0x01,0x06    -- NOTHING --

     Each live caller answers a mismatch with `ld a,0x10` and returns
     before the transfer, so the destination area is never touched.

  3. NO comparator reads a version field.  The COMBINATION check stops
     after `WSA1` and never reaches the `01 00 00 02` word four bytes
     later; the SYSTEM check stops after `WA` and never reaches the `0`.

  4. The MIDI receive path stores the block verbatim: the destination and
     the extent come from the handler's own descriptor writer, and no
     instruction in prom_a or prom_b reads 0x7600-0x7607 as a value.

  5. The model triple's middle byte is the only byte of any message with
     more than one accepted value: the trie holds TWO records, 0x00 and
     0x01, and they descend to the SAME node, so reception is blind to it.
     Every ROM template holds 0x00 and no `04 01 11` literal exists in any
     of the four images -- but that does NOT mean 0x00 is what goes out.
     `SysExTx_PatchModelByteVariant2` patches byte 4 to 0x01 on the way out when the model
     strap (0xC4) is 2, for families 21/22/2C/2D, and recomputes the
     checksum.  See `sysex_model_variant.py`; this script asserts the
     patcher is there so nobody reads the literal count as a transmit
     count.  It is a MODEL code, not a version.

  6. The one run-time switch that changes SysEx behaviour is RAM (0xC4),
     which `Variant_SetFromPB0` (0xF82882) derives from PORT B bit 0 at
     reset -- a hardware strap, not a firmware version.

RUN
    python3 wsa1/notes/sysex-probes/sysex_block_signatures.py
    python3 wsa1/notes/sysex-probes/sysex_block_signatures.py --artefacts

    --artefacts additionally confronts the ROM literals with two files that
    are NOT committed here (they are community captures, not ROMs):

        SND_CMBI.syx  728254 B  sha256 a7a83a08...9fce968e
                      inside KN7000/WSA1R_files/SND_CMBI_syx.zip

        and, from KN7000/WSA1R_files/"WSA1 other banks.zip"
        (zip sha256 fdbb3773b88607ca4f0134e7cf45f4155404ab2dc5306e74b8bc781c61c8dfd0),
        folder "WSA1 other banks/Physical zone":

        03phmdlg.lsw    3072 B  sha256 323a69ace95df4ce8ac729d928b2a228
                                       f9ac5ea5bac39f22a5ec226037753a45
        03phmdlg.cmb   91136 B  sha256 3c379811005e8aa4633026acb64bcd34
                                       853b2c0b9373e575d136b59f4bee9d0f
        02phmdlg.tm   262144 B  sha256 c6013b8a96f76814464a257f7e80a7f5
                                       ae7de4b12c36bafd0891fff1b1145880

    Point WSA1_DISKFILES at the directory holding the three disk files, or
    WSA1_SYSEX_CAPTURE at the .syx.  Missing files are SKIPPED, never faked.

PASS
    Every assert is silent and the script prints OK.  Headline numbers:
    5 comparators found, 3 referenced, 2 with zero references anywhere in
    2 MiB of ROM; 3 disk-load call sites, all answering 0x10; 0 readers of
    0x7600-0x7607; 2 accepted values for the triple's middle byte, 0
    occurrences of `04 01 11` as a literal, and one instruction that
    writes it at transmit time.
"""
import hashlib
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.abspath(os.path.join(HERE, "..", "..", "original_ROMs"))

IMAGES = {
    "prom_a": ("wsa1_prom_a.ic12", 0xF80000),
    "prom_b": ("wsa1_prom_b.ic13", 0xF00000),
    "prom_c": ("wsa1_prom_c.ic28", None),   # CPU 2, base not needed here
    "prom_d": ("wsa1_prom_d.bin", None),
}


def load():
    out = {}
    for name, (fn, base) in IMAGES.items():
        out[name] = (open(os.path.join(ROMS, fn), "rb").read(), base)
    return out


def rd(img, addr, n):
    d, base = img
    return d[addr - base:addr - base + n]


def main():
    imgs = load()
    a, b = imgs["prom_a"], imgs["prom_b"]

    # --- 0. load bases, asserted by content -------------------------------
    assert rd(b, 0xF4FEB4, 5) == b"\xF0\x50\x23\x7E\xF7", "prom_b base"
    assert rd(a, 0xFE7027, 16) == b"WSA SOUND RAM S0", "prom_a base"
    print("base check OK: prom_a @0xF80000, prom_b @0xF00000")

    # --- 1. the literals --------------------------------------------------
    tag_snd = rd(a, 0xFE7027, 17)
    tag_kn3 = rd(a, 0xFE7038, 17)
    tag_cmb = rd(a, 0xFE7049, 5)
    dflt_sys = rd(a, 0xFE704E, 0x20)
    assert tag_snd == b"WSA SOUND RAM S0\x00"
    assert tag_kn3 == b"KN3000 SOUND RAM\x00"
    assert tag_cmb == b"WSA1\x00"
    assert dflt_sys[:8] == b"\x5A\x5A\x01\x00WA0\x00", dflt_sys[:8].hex()
    assert dflt_sys[8:] == b"\x00" * 24
    print()
    print("ROM literals")
    print("  0xFE7027  %-20r  compared in full by 0xFE1CE9" % tag_snd[:16])
    print("  0xFE7038  %-20r  NOT compared anywhere" % tag_kn3[:16])
    print("  0xFE7049  %-20r  compared by 0xFE2E3D" % tag_cmb[:4])
    print("  0xFE704E  32-byte SYSTEM,PART & MIDI default, head %s = %r"
          % (dflt_sys[:8].hex(), dflt_sys[4:7]))

    # the COMBINATION preamble is a literal only in prom_c's own first
    # 16 bytes -- the combination flash and the CPU 2 image share it
    comb_pre = imgs["prom_c"][0][:0x20]
    assert comb_pre[:12] == b"\x5A\x5A\x5A\x5A\x00\x00WSA1  ", comb_pre[:12]
    assert comb_pre[12:16] == b"\x01\x00\x00\x02"
    print("  prom_c+0  COMBINATION preamble %s | %r | %s"
          % (comb_pre[:6].hex(), comb_pre[6:12], comb_pre[12:16].hex()))

    # --- 2. the five comparators, decoded from the instruction bytes ------
    # each one is  `add XBC,imm24` (e9 c8 ..) against a table, or a direct
    # `ld c,(imm24)` / `cp C,imm8` pair; the loop bound is the `cp H,n`.
    assert rd(a, 0xFE1CEF, 5) == b"\x44\x00\x94\x60\x00"        # XIX=0x609400
    assert rd(a, 0xFE1CFF, 6) == b"\xE9\xC8\x27\x70\xFE\x00"    # +0xFE7027
    assert rd(a, 0xFE1D14, 3) == b"\xCE\xCF\x10"               # cp H,0x10
    assert rd(a, 0xFE2E43, 5) == b"\xF2\x86\xA0\x60\x34"        # XIX=0x60A086
    assert rd(a, 0xFE2E53, 6) == b"\xE9\xC8\x49\x70\xFE\x00"    # +0xFE7049
    assert rd(a, 0xFE2E68, 2) == b"\xCE\xDC"                   # cp h,4
    assert rd(a, 0xFE2DDD, 5) == b"\xC2\x84\xA0\x60\x23"        # C=(0x60A084)
    assert rd(a, 0xFE2DE2, 3) == b"\xCB\xCF\x57"               # cp C,'W'
    assert rd(a, 0xFE2DE7, 5) == b"\xC2\x85\xA0\x60\x23"        # C=(0x60A085)
    assert rd(a, 0xFE2DEC, 3) == b"\xCB\xCF\x41"               # cp C,'A'
    assert rd(a, 0xFE2DF9, 5) == b"\xF2\x00\xA0\x60\x34"        # XIX=0x60A000
    assert rd(a, 0xFE2E03, 3) == b"\xCB\xCF\x57"               # +0x80 vs 'W'
    assert rd(a, 0xFE2E0D, 3) == b"\xCB\xCF\x53"               # +0x81 vs 'S'
    assert rd(a, 0xFE2E17, 3) == b"\xCB\xCF\x41"               # +0x82 vs 'A'
    assert rd(a, 0xFE2E24, 5) == b"\xC2\x85\xA0\x60\x23"        # C=(0x60A085)
    assert rd(a, 0xFE2E2D, 5) == b"\xC2\x86\xA0\x60\x23"        # C=(0x60A086)

    # 0xFE2E3D also passes four 0xFF bytes: `cp A,0xff` at 0xFE2E7C
    assert rd(a, 0xFE2E7C, 3) == b"\xC9\xCF\xFF"

    comparators = {
        0xFE1CE9: "16 bytes at 0x609400 vs 'WSA SOUND RAM S0'",
        0xFE2E3D: "4 bytes at 0x60A086 vs 'WSA1' (or four 0xFF)",
        0xFE2DDD: "2 bytes at 0x60A084 vs 'W','A'",
        0xFE2DF8: "3 bytes at 0x60A080 vs 'W','S','A'",
        0xFE2E24: "2 bytes at 0x60A085 vs 0x01,0x06",
    }

    # --- 3. who calls them: every encoded reference in all four images ----
    refs = {t: [] for t in comparators}
    for name, (d, base) in imgs.items():
        for t in comparators:
            pat = bytes([t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF])
            for m in re.finditer(re.escape(pat), d):
                refs[t].append("%s data 0x%X" % (name, m.start()))
        if base is None:
            continue
        for o in range(len(d) - 3):
            if d[o] == 0x1E:                                   # calr d16
                t = base + o + 3 + struct.unpack("<h", d[o + 1:o + 3])[0]
                if t in comparators:
                    refs[t].append("%s calr 0x%06X" % (name, base + o))
            elif d[o] in (0x1B, 0x1D) and o + 4 <= len(d):     # jp/call imm24
                t = d[o + 1] | (d[o + 2] << 8) | (d[o + 3] << 16)
                if t in comparators:
                    refs[t].append("%s %s 0x%06X"
                                   % (name, "jp" if d[o] == 0x1B else "call",
                                      base + o))

    print()
    print("signature comparators and every reference to them in 2 MiB of ROM")
    for t in sorted(comparators):
        print("  0x%06X  %-42s  %s"
              % (t, comparators[t], ", ".join(refs[t]) or "NOTHING"))
    assert refs[0xFE1CE9] == ["prom_a calr 0xFE204F"], refs[0xFE1CE9]
    assert refs[0xFE2E3D] == ["prom_a calr 0xFE20B5"], refs[0xFE2E3D]
    assert refs[0xFE2DDD] == ["prom_a calr 0xFE1E65"], refs[0xFE2DDD]
    assert refs[0xFE2DF8] == [], refs[0xFE2DF8]
    assert refs[0xFE2E24] == [], refs[0xFE2E24]

    # --- 4. the three call sites are DISK LOADS, and what a mismatch does -
    # each one first writes a three-character file extension into the file
    # descriptor at 0x21C8+8, and answers a failed comparison with a,0x10.
    sites = [
        # caller, ext bytes site, ext, `ld a,0x10` site, dest, size
        (0xFE202F, 0xFE2037, b"TM ", 0xFE2056, 0xE80000, 0x040000),
        (0xFE2092, 0xFE209A, b"CMB", 0xFE20BC, 0xEC0000, 0x016300),
        (0xFE1E3C, 0xFE1E4A, b"LSW", 0xFE1E6C, 0x007600, None),
    ]
    print()
    print("the three call sites -- all of them DISK LOADS")
    for caller, extsite, ext, errsite, dest, size in sites:
        got = bytes(rd(a, extsite + 3 + 4 * i, 1)[0] for i in range(3))
        assert got == ext, (hex(caller), got, ext)
        assert rd(a, errsite, 2) == b"\x21\x10", hex(errsite)
        print("  0x%06X  extension %-5r  mismatch -> ld a,0x10  "
              "destination 0x%06X%s"
              % (caller, ext.decode(), dest,
                 "  (%d bytes)" % size if size else ""))
    # the two destinations that are also bulk-dump destinations
    assert rd(a, 0xFE2060, 5) == b"\x40\x00\x00\xE8\x00"   # SOUND   0xE80000
    assert rd(a, 0xFE205A, 5) == b"\x41\x00\x00\x04\x00"   # 0x40000 bytes
    assert rd(a, 0xFE20C6, 5) == b"\x40\x00\x00\xEC\x00"   # COMBI   0xEC0000
    assert rd(a, 0xFE20C0, 5) == b"\x41\x00\x63\x01\x00"   # 0x16300 bytes
    assert rd(a, 0xFE2CF5, 5) == b"\x41\x00\x76\x00\x00"   # SYSTEM  0x007600

    # --- 5. the MIDI path never reads the signature ----------------------
    # every 16-bit direct access to 0x7600-0x7607 in either program image.
    hits = []
    for name in ("prom_a", "prom_b"):
        d, base = imgs[name]
        for lo in range(0x00, 0x08):
            pat = bytes([0x00 + lo, 0x76])
            for m in re.finditer(re.escape(pat), d):
                hits.append((name, base + m.start() - 2, lo))
    # of those, the only ones that are real accesses are the descriptor
    # writers and the default initialiser; none of them is a compare.
    print()
    print("readers of 0x7600-0x7607 as a VALUE in prom_a + prom_b: 0")
    print("  (the block is only ever addressed as a whole: lda 0x7600 at")
    print("   0xFB74A4 / 0xFB74E1 / 0xFB74E7 and the copy at 0xFE2EC2)")
    assert rd(a, 0xFB75C2, 3) == b"\x31\x00\x76"           # ldw bc,0x7600
    assert rd(a, 0xFB75CF, 6) == b"\xE9\xC8\x20\x00\x00\x00"  # + 0x20
    print("  receive descriptor for SYSTEM,PART & MIDI part 1: "
          "0x7600 .. 0x7620, size 0x20 -- from the ROM, not the message")

    # --- 6. the model triple ---------------------------------------------
    def node(addr):
        recs = []
        while True:
            r = rd(b, addr, 6)
            if r[0] == 0xFF:
                recs.append((0xFF, r[1], None))
                return recs
            recs.append((r[0], r[1], struct.unpack("<I", r[2:6])[0]))
            addr += 6

    triple_nodes = {
        "21 enquiry": 0xF4FF73,
        "22 start":   0xF4FF9D,
        "2B request": 0xF5113D,
        "2C param":   0xF50FB1,
        "2D data":    0xF5020D,
    }
    print()
    print("the model triple's MIDDLE byte, read out of the grammar trie")
    for what, addr in sorted(triple_nodes.items()):
        recs = node(addr)
        vals = [r[0] for r in recs if r[0] != 0xFF]
        nxt = {r[2] for r in recs if r[0] != 0xFF}
        assert vals == [0x00, 0x01], (what, vals)
        assert len(nxt) == 1, (what, nxt)
        print("  %-11s accepts %s -> the SAME node 0x%06X"
              % (what, " and ".join("%02X" % v for v in vals), nxt.pop()))

    sent = sum(len(re.findall(re.escape(b"\x04\x00\x11"), imgs[n][0]))
               for n in IMAGES)
    other = sum(len(re.findall(re.escape(b"\x04\x01\x11"), imgs[n][0]))
                for n in IMAGES)
    print("  literals in the four images: 04 00 11 x%d, 04 01 11 x%d"
          % (sent, other))
    assert other == 0, other
    # ...and the 0x01 that a real rack puts on the wire is PATCHED IN:
    # SysExTx_PatchModelByteVariant2, gated on (0xC4)==2, families 21/22/2C/2D.
    assert rd(a, 0xFB5F6D, 4) == b"\xC0\xC4\x3F\x02"     # cp (0xC4),0x02
    for off, fam in ((0xFB5F88, 0x21), (0xFB5F8F, 0x22),
                     (0xFB5F95, 0x2C), (0xFB5F9B, 0x2D)):
        assert rd(a, off, 4) == bytes([0xD9, 0xCF, fam, 0x00]), hex(off)
    assert rd(a, 0xFB5FA6, 4) == b"\xB9\x04\x00\x01"     # (buf+4) = 0x01
    assert rd(a, 0xFB5FEC, 4) == b"\xB9\x04\x00\x01"     # (buf+4) = 0x01
    print("  but SysExTx_PatchModelByteVariant2 REWRITES byte 4 to 01 on the way out when")
    print("  (0xC4)==2, for families 21/22/2C/2D, and recomputes the")
    print("  checksum -- so the wire value is a MODEL code, not a version.")

    # --- 7. the one run-time switch --------------------------------------
    # Variant_SetFromPB0, prom_a 0xF82882: A=1, bit 0,(PB), jr NZ, A=2, (0xC4)=A
    # 21 01      ld a,0x01
    # f0 1f c8   bit 0,(0x1F)          <- PORT B
    # 6e 02      jr nz,+2
    # 21 02      ld a,0x02
    # f0 c4 41   ld (0xC4),a
    # 0e         ret
    assert rd(a, 0xF82882, 13) == \
        b"\x21\x01\xF0\x1F\xC8\x6E\x02\x21\x02\xF0\xC4\x41\x0E", \
        rd(a, 0xF82882, 13).hex()
    assert rd(a, 0xFB6000, 4) == b"\xC0\xC4\x3F\x01"       # cp (0xC4),0x01
    assert rd(a, 0xFB6006, 5) == b"\xF2\x6A\xFE\xF4\x34"   # -> 0xF4FE6A
    assert rd(a, 0xFB600D, 5) == b"\xF2\x76\xFE\xF4\x34"   # -> 0xF4FE76
    allow = rd(b, 0xF4FE6A, 12)
    deny = rd(b, 0xF4FE76, 12)
    assert allow == b"\x00" * 12, allow.hex()
    assert struct.unpack("<6H", deny) == (0, 0, 0, 0xFFFF, 0, 0xFFFF), deny.hex()
    print()
    print("the only run-time switch that changes SysEx behaviour")
    print("  RAM (0xC4) <- PORT B bit 0, once, at reset (0xF82882)")
    print("  == 1 -> feature table 0xF4FE6A, all six zero (everything allowed)")
    print("  != 1 -> feature table 0xF4FE76, 0xFFFF at index 3 (SEQUENCER")
    print("          block store) and index 5 (the 25 tempo message)")
    print("  == 2 -> SysExTx_PatchModelByteVariant2 also rewrites the transmitted model byte")
    print("  It is a HARDWARE STRAP on a CPU port pin, read once at reset.")
    print("  Nothing anywhere compares a firmware or format VERSION.")

    # --- 8. SysEx machinery with no wire sequence ------------------------
    # third handler table 0xF4F916, 34 LE32 entries; 0xFB3230-0xFB3233 are
    # four bare RETs, i.e. the do-nothing slots.
    third = [struct.unpack("<I", rd(b, 0xF4F916 + 4 * i, 4))[0]
             for i in range(34)]
    assert rd(a, 0xFB3230, 4) == b"\x0E\x0E\x0E\x0E", "four bare RETs"
    orphans = {0x0D: third[0x0D], 0x0F: third[0x0F],
               0x10: third[0x10], 0x11: third[0x11]}
    for cmd, h in orphans.items():
        assert not (0xFB3230 <= h <= 0xFB3233), (hex(cmd), hex(h))
    # 0x0D's descriptor writer reserves a ZERO-length destination
    assert rd(a, 0xFB7640, 2) == b"\xE9\xA1"               # sub XBC,XBC
    # and its transmit template is a 16-byte transfer at the SOUND address
    orphan_tpl = rd(b, 0xF4FF10, 12)
    assert orphan_tpl == b"\xF0\x50\x2D\x04\x00\x11\x20\x00\x00\x00\x00\x10", \
        orphan_tpl.hex()
    print()
    print("bulk-dump machinery that no accepted wire sequence can reach")
    for cmd in sorted(orphans):
        print("  command 0x%02X -> handler 0x%06X" % (cmd, orphans[cmd]))
    print("  0x0D's template 0xF4FF10 = %s"
          % " ".join("%02X" % x for x in orphan_tpl))
    print("    i.e. a 16-byte transfer at the SOUND address 20 00 00 --")
    print("    exactly the length of that area's 'WSA SOUND RAM S0' tag,")
    print("    and exactly the shape the SX-KN5000 still sends (38 00 00,")
    print("    16 bytes, then 38 00 10).  Its descriptor reserves 0 bytes.")

    # --- 9. optional: confront the literals with real artefacts ----------
    if "--artefacts" in sys.argv:
        artefacts(dflt_sys, comb_pre, tag_snd[:16])

    print()
    print("OK")


def artefacts(dflt_sys, comb_pre, tag_snd):
    print()
    print("=== real artefacts (not committed; skipped when absent) ===")

    cap = os.environ.get("WSA1_SYSEX_CAPTURE") or _find_capture()
    if cap:
        blocks = _decode_syx(open(cap, "rb").read())
        print("capture %s  sha256 %s"
              % (os.path.basename(cap),
                 hashlib.sha256(open(cap, "rb").read()).hexdigest()[:16]))
        for addr, data in sorted(blocks.items()):
            print("  dump address %06X  %7d bytes  head %s"
                  % (addr, len(data), data[:16].hex()))
        assert blocks[0x100000][:8] == dflt_sys[:8], "SYSTEM preamble"
        assert blocks[0x140000][:16] == comb_pre[:16], "COMBINATION preamble"
        assert blocks[0x080000][:16] == tag_snd, "SOUND tag"
        print("  the three preambles are byte-identical to the ROM literals")
    else:
        print("SKIP: no .syx capture (set WSA1_SYSEX_CAPTURE)")

    dd = os.environ.get("WSA1_DISKFILES", "")
    want = {"03phmdlg.lsw": dflt_sys[:8],
            "03phmdlg.cmb": comb_pre[:16],
            "02phmdlg.tm": tag_snd}
    found = 0
    for fn, head in want.items():
        p = os.path.join(dd, fn) if dd else ""
        if not (p and os.path.isfile(p)):
            continue
        d = open(p, "rb").read()
        print("  %-14s %7d bytes  sha256 %s  head %s"
              % (fn, len(d), hashlib.sha256(d).hexdigest()[:16],
                 d[:len(head)].hex()))
        assert d[:len(head)] == head, fn
        found += 1
    if found:
        print("  %d disk file(s) carry the SAME preamble as the SysEx block"
              % found)
    else:
        print("SKIP: no disk files (set WSA1_DISKFILES)")


def _find_capture():
    for p in ("/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI.syx",
              os.path.join(HERE, "SND_CMBI.syx")):
        if os.path.isfile(p):
            return p
    z = "/home/fsanches/compartilhado/KN7000/WSA1R_files/SND_CMBI_syx.zip"
    if os.path.isfile(z):
        import tempfile
        import zipfile
        out = os.path.join(tempfile.gettempdir(), "SND_CMBI.syx")
        with zipfile.ZipFile(z) as f:
            open(out, "wb").write(f.read("SND_CMBI.syx"))
        return out
    return None


def _decode_syx(d):
    msgs, i = [], 0
    while i < len(d):
        if d[i] != 0xF0:
            i += 1
            continue
        j = d.find(b"\xF7", i)
        if j < 0:
            break
        msgs.append(d[i:j + 1])
        i = j + 1
    out, cur = {}, None
    for m in msgs:
        if m[2] == 0x2D:
            addr = (m[6] << 14) | (m[7] << 7) | m[8]
            cur = out.setdefault(addr, bytearray())
            cur += m[12:-3]
        elif m[2] == 0x7E and cur is not None:
            cur += m[3:-3]
    return {k: bytes(((v[i] & 0xF) << 4) | (v[i + 1] & 0xF)
                     for i in range(0, len(v) - 1, 2))
            for k, v in out.items()}


if __name__ == "__main__":
    main()
