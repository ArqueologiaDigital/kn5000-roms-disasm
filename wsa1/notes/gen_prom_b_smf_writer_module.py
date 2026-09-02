#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF7669D-0xF779D4 -- THE SMF WRITER'S THREE
`.byte` BLOCKS -- and type the STANDARD MIDI FILE TEMPLATE that sits in them.

QUESTION IT ANSWERS
  "The census (notes/DATA-CENSUS-2026-09-02.md §8) lists prom_b
   0x07669D-0x0779D5, 4,920 bytes, as self-admitted debt with the shape hint
   *MIDI, ptr-table*.  A Standard MIDI File header sits at 0xF77836 whose MTrk
   length field is ZERO, so every chunk walker steps nowhere.  What is that
   object's REAL EXTENT, what does it contain, who reads it, and what is the
   rest of the 4,920 bytes?"

THE ANSWER, IN ONE LINE
  It is an EXPORT TEMPLATE, not music: 33 bytes of file header that the writer
  copies into the output buffer, followed by a SEPARATE 66-byte word table that
  is not MIDI at all.  The zero length is a PLACEHOLDER the writer backfills
  from a byte count once the track is finished.  Everything else in the 4,920
  bytes -- 4,288 of the 4,790 `.byte` bytes -- is TLCS-900 CODE.

THE SPLIT IS PROVEN BY THE READERS, NOT BY EYE
  prom_b holds FOUR byte-identical 99-byte copies of this object, at 0xF7493F,
  0xF760BF, 0xF768F0 and 0xF77836.  Three are live and one is an orphan.  For
  each live copy the image spells FOUR of its interior addresses as 32-bit
  immediates, and they are the same four offsets every time:

      +0x00  `ld XIY,<tpl>`      then `ld BC,0x0007` / `ldirw`  -> 14 bytes
      +0x0E  `ld XIY,<tpl+0x0E>` then `ld BC,0x0004` / `ldirw`  ->  8 bytes
      +0x16  `ld XIY,<tpl+0x16>` then `ld BC,0x000B` / `ldir`   -> 11 bytes
      +0x21  read FIVE times as `<base>+HL` with HL = index*2      the table

  14 + 8 + 11 = 33 = 0x21, so the third copy ENDS exactly where the fourth
  address BEGINS.  The template's extent is not a guess; it is the difference
  between two addresses the firmware itself names.

WHY THE MTrk LENGTH IS ZERO -- AND WHERE THE REAL ONE COMES FROM
  0xF7789A computes  (0x126C)*1024 + (cursor - 0x60A700) - 22  and stores it as
  four bytes D,E,W,A into (0x10C4)..(0x10C7) -- most significant byte first,
  which is the SMF chunk-length byte order and NOT this CPU's.  22 is exactly
  the size of `MThd`+its 6 payload bytes+`MTrk` -- i.e. everything before the
  length field's own successor.  (0x126C) counts the 1,024-byte buffer windows
  already flushed.  So the template ships the field as 00 00 00 00 because the
  value is not knowable until the track is closed.

IT REALLY IS A MIDI WRITER
  0xF77918 emits a variable-length delta time from (0x1193) and then the bytes
  0xFF, 0x51, 0x03 followed by (0x108E), (0x108D), (0x108C) -- `FF 51 03 tttttt`,
  the SMF **Set Tempo** meta event, most significant byte first.  The three
  staged bytes are written by 0xF778D2, which is 60000 * x, 40000 * x / 24000
  and * 1000 -- a tempo conversion.  0xF77982 builds `0xB0 | channel` from
  (0x119A) -- a Control Change status byte.  0xF77990 computes
  (0x107E)+BC-(0x1082) into (0x11AA) -- a delta time as a tick difference.

THE 66 BYTES AT +0x21 ARE NOT MIDI
  They are 32 little-endian 16-bit values plus a 0xFFFF terminator:
  0x0000, 0x0040, ... 0x0800, stepping by 0x40 everywhere except ONE step of
  0x80 between 0x01C0 and 0x0240.  The reader is
  `ld XDE,<base> / ld HL,(XDE+HL)` at 0xF76FB9 with HL = (a byte from the RAM
  table at 0x603422) * 2, and the value is then added to XIY = 0x006036A0 by
  `lda XIY,XIY+HL`.  So they are BYTE OFFSETS into a 0x40-strided array of 32
  records in RAM, and 0xFFFF means "no record".  ⚠ The skipped slot at 0x0200
  is in the ROM and identical in all four copies; what occupies it is NOT
  established here.

  ★ This retires the standing `Unknown:` on SmfFileTemplate_F7493F and
  SmfFileTemplate_F760BF -- "what the 0x40-strided bytes after offset 0x21 are.
  They are NOT claimed here."

THE FOURTH COPY IS AN ORPHAN
  Not one 32-bit word in prom_a, prom_b, prom_c or prom_d holds ANY address in
  [0xF768F0, 0xF76953).  The three live copies are each named at four interior
  offsets; this one at none.  It is emitted with the same typing and the header
  says it is unreferenced.  ⚠ A computed address cannot be excluded by a scan;
  the claim is about the scan, and it is stated that way.

  ⚠ One byte-scan hit inside copy 4's live sibling is a FALSE POSITIVE and is
  refuted here rather than reported: `0x00F77850` appears at prom_b 0xF47B0E,
  but 0xF47B0B decodes as `ld (0x33e0),WA` and 0xF47B0F as `jrl T,0xf47c09`, so
  the "pointer" straddles two instruction boundaries.

WHAT ELSE IS IN THE 4,920 BYTES
  Data_F7669D (286 B), Data_F7681C (4,089 B) and the tail of Data_F77836
  (316 B) are code.  Each of the three spans ENDS on a `ret` whose last byte is
  the last byte of the block, and the linear decode consumes each span exactly
  -- three independent boundary agreements, none of them chosen.

NOTHING HERE CAN BREAK THE GATE
  Every code byte is printed through notes/llvm_roundtrip_autoforce.py, which
  assembles what it prints before printing it.  verify() then assembles the
  whole emitted text of each block and compares it with the ROM, and --splice
  refuses to write unless every block verifies and every check passes.

RUN
  python3 notes/gen_prom_b_smf_writer_module.py --layout    # the segment table
  python3 notes/gen_prom_b_smf_writer_module.py --selftest  # the evidence
  python3 notes/gen_prom_b_smf_writer_module.py             # the assembly
  python3 notes/gen_prom_b_smf_writer_module.py --splice    # write it into the .s
  python3 notes/gen_prom_b_smf_writer_module.py --splice-siblings
                                          # type the two copies OUTSIDE the range
Then, always:
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B_BASE = 0xF00000
ROMS = ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13", "wsa1_prom_c.ic28", "wsa1_prom_d.bin")

TPLS = (0xF7493F, 0xF760BF, 0xF768F0, 0xF77836)
TPL_LEN, TAB_OFF, TAB_LEN = 0x21, 0x21, 66      # 33 + 66 = 99
NAME_RAM = 0x21C8                               # 8 more name bytes come from here
_c = {}


def rom(name="wsa1_prom_b.ic13"):
    if name not in _c:
        _c[name] = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
    return _c[name]


def bs(addr, n, name="wsa1_prom_b.ic13"):
    return rom(name)[addr - B_BASE: addr - B_BASE + n]


# ------------------------------------------------------------------- layout
# (kind, start, length).  `keep` segments are NOT emitted: they are already
# typed in the source and this tool must not touch them.  The three emitted
# blocks are the maximal runs between them.
def layout():
    return [
        ("code",   0xF7669D,  286),   # was Data_F7669D
        ("keep",   0xF767BB,   64),   # RamPtrTable_F767BB
        ("keep",   0xF767FB,   33),   # ByteMap_F767FB
        ("code",   0xF7681C,   18),   # \
        ("bytab",  0xF7682E,    8),   #  |
        ("code",   0xF76836,  186),   #  |
        ("smftpl", 0xF768F0,   33),   #  |
        ("smftab", 0xF76911,   66),   #  > was Data_F7681C
        ("code",   0xF76953, 1297),   #  |
        ("sysex",  0xF76E64,   16),   #  |
        ("code",   0xF76E74, 2465),   # /
        ("keep",   0xF77815,   33),   # ByteMap_F77815
        ("smftpl", 0xF77836,   33),   # \
        ("smftab", 0xF77857,   66),   #  > was Data_F77836
        ("code",   0xF77899,  316),   # /
    ]


def blocks():
    """[(first_addr, last_addr+1, [segments])] -- the maximal non-`keep` runs."""
    out, cur = [], []
    for seg in layout():
        if seg[0] == "keep":
            if cur:
                out.append(cur)
                cur = []
        else:
            cur.append(seg)
    if cur:
        out.append(cur)
    return [(b[0][1], b[-1][1] + b[-1][2], b) for b in out]


# -------------------------------------------------------------- transcribe
def transcribe(start, length):
    key = ("t", start, length)
    if key not in _c:
        p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(start), hex(length),
                            "--quiet"], capture_output=True, text=True, cwd=ROOT)
        if p.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, p.stderr[-2000:]))
        _c[key] = p.stdout.rstrip("\n").split("\n")
    return _c[key]


def line_addr(ln):
    m = re.search(r";\s*([0-9A-F]{6})\s", ln)
    return int(m.group(1), 16) if m else None


def code_spans():
    return [(s, n) for k, s, n in layout() if k == "code"]


def in_code(a):
    return any(s <= a < s + n for s, n in code_spans())


def in_scan(a):
    """The code spans PLUS the three data objects carved out of them -- i.e.
    everything the linear decode would have swallowed if nothing pointed at
    it.  This is the region pointer_hits() searches, and it must not depend on
    the carve-out, or the scan could not find the reason for the carve-out."""
    return any(s <= a < s + n for k, s, n in layout()
               if k in ("code", "bytab", "sysex"))


# ------------------------------------------------------------------- labels
IMM32_OPCODES = set(range(0x40, 0x48))      # `ld XWA..XSP,imm32`


def pointer_hits():
    """[(image, site, value)] -- every 32-bit little-endian word in the four
    images whose value lands in an emitted CODE span, and whether the byte in
    front of it is an `ld XRR,imm32` opcode.

    ★ THE SCAN ALONE IS NOT EVIDENCE.  12 words match; only 3 are operands.
    The other 9 straddle an instruction boundary -- `78 f7 00` (`jrl T`) and
    `76 f7 00` (`jrl Z`) put `f7 00` in the middle of a long branch, and this
    image is full of them.  The opcode test separates them exactly."""
    if "ph" in _c:
        return _c["ph"]
    out = []
    for name in ROMS:
        d = rom(name)
        for i in range(1, len(d) - 3):
            v = struct.unpack_from("<I", d, i)[0]
            if in_scan(v):
                out.append((name, i, v, d[i - 1] in IMM32_OPCODES))
    _c["ph"] = out
    return out


def call_targets():
    """Addresses inside the emitted code that something CALLS.

    Union of two sources, both re-derived on every run:
      1. `call`/`calr` in this tool's own verified transcription of the spans;
      2. `call`/`calr` in the mame text already committed in prom_b's source
         -- its converted lines carry `; ADDR  <mame text>` comments.
    ⚠ The 32-bit word scan is deliberately NOT one of them: see pointer_hits().
    A target that is not an instruction boundary is REPORTED, not silently
    placed -- see checks()."""
    if "ct" in _c:
        return _c["ct"]
    tg = set()
    for s_, n in code_spans():
        for ln in transcribe(s_, n):
            for m in re.finditer(r"cal[lr]\s+0x([0-9a-f]{6})", ln):
                tg.add(int(m.group(1), 16))
    src = open(SRCB, encoding="utf-8").read()
    for m in re.finditer(r"cal[lr]\s+0x(f7[0-9a-f]{4})", src):
        tg.add(int(m.group(1), 16))
    _c["ct"] = {a for a in tg if in_code(a)}
    return _c["ct"]


def branch_targets():
    """In-range `jr`/`jrl` targets from the transcription -- a misframing
    detector: a branch that lands off an instruction boundary, or inside a
    segment this tool types as DATA, means the decode is wrong."""
    if "bt" in _c:
        return _c["bt"]
    tg = set()
    for s_, n in code_spans():
        for ln in transcribe(s_, n):
            for m in re.finditer(r"j(?:r|rl|p)\s+\S*\s*0x([0-9a-f]{6})", ln):
                v = int(m.group(1), 16)
                if 0xF7669D <= v < 0xF779D5:
                    tg.add(v)
    _c["bt"] = tg
    return tg


def boundaries():
    if "bd" not in _c:
        b = set()
        for s, n in code_spans():
            for ln in transcribe(s, n):
                a = line_addr(ln)
                if a is not None:
                    b.add(a)
        _c["bd"] = b
    return _c["bd"]


# ------------------------------------------------------------------- emit
RULE = ("; " + "-" * 74)


def wrap(prefix, text, width=76):
    out, cur = [], prefix
    for w in text.split():
        if len(cur) + 1 + len(w) > width and cur.strip() != prefix.strip():
            out.append(cur)
            cur = ";" + " " * (len(prefix) - 1)
        cur += (" " if cur[-1] != " " else "") + w
    out.append(cur)
    return out


def tpl_lines(a):
    """The 33-byte file header, typed field by field."""
    b = bs(a, 33)
    assert b[:4] == b"MThd" and b[14:18] == b"MTrk", "not the template at 0x%06X" % a
    L = []
    L.append('\t.ascii\t"MThd"\t; %06X  header chunk tag' % a)
    L.append('\t.byte\t0x00, 0x00, 0x00, 0x06\t; %06X  chunk length 6, most significant byte first' % (a + 4))
    L.append('\t.byte\t0x00, 0x00\t; %06X  format 0 -- one multi-channel track' % (a + 8))
    L.append('\t.byte\t0x00, 0x01\t; %06X  ntrks 1' % (a + 10))
    L.append('\t.byte\t0x00, 0x60\t; %06X  division 0x0060 = 96 ticks per quarter note' % (a + 12))
    L.append('\t.ascii\t"MTrk"\t; %06X  track chunk tag' % (a + 14))
    L.append('\t.byte\t0x00, 0x00, 0x00, 0x00\t; %06X  track length PLACEHOLDER -- backfilled by 0xF7789A' % (a + 18))
    L.append('\t.byte\t0x00\t; %06X  delta time 0' % (a + 22))
    L.append('\t.byte\t0xFF, 0x03\t; %06X  meta event FF 03 -- sequence/track name' % (a + 23))
    L.append('\t.byte\t0x0F\t; %06X  ... declared length 15' % (a + 25))
    L.append('\t.ascii\t"WSA    "\t; %06X  name bytes 1-7; 8-15 come from RAM (0x%04X)' % (a + 26, NAME_RAM))
    return L


def tab_lines(a):
    """The 66-byte word table: 32 record offsets and a 0xFFFF terminator."""
    L, vals = [], words(a)
    for i in range(0, 32, 8):
        L.append("\t.short\t" + ", ".join("0x%04X" % v for v in vals[i:i + 8])
                 + "\t; %06X  slots %2d-%2d" % (a + i * 2, i, i + 7))
    L.append("\t.short\t0x%04X\t; %06X  terminator" % (vals[32], a + 64))
    return L


def words(a):
    b = bs(a, TAB_LEN)
    return list(struct.unpack("<33H", b))


def header(lines):
    return [RULE] + lines + [RULE]


def tpl_header(a, live):
    ref = "; Read by: " if live else "; Read by: "
    L = ["; SmfFileTemplate_%06X -- the 33-byte STANDARD MIDI FILE header this" % a,
         ";          firmware copies into its output buffer before writing a track.",
         ";          Format 0, one track, division 96 ticks per quarter note.",
         ";          ⚠ NOT MUSIC: no note, no end-of-track.  The events are written",
         ";          at run time by the code below; this is only the file's opening."]
    if live:
        L += wrap("; Read by: ", "three `ld XIY,imm32` copy sources -- +0x00 with "
                                 "`ld BC,0x0007`/`ldirw` (14 bytes), +0x0E with "
                                 "`ld BC,0x0004`/`ldirw` (8), +0x16 with "
                                 "`ld BC,0x000B`/`ldir` (11).  14+8+11 = 33, which is "
                                 "why this object ends here and the word table below "
                                 "begins at +0x21.")
        L += wrap("; Then:    ", "`ld XIY,0x%04X` / `ld BC,0x0008` / `ldir` appends "
                                 "eight RAM bytes, so the meta event's declared length "
                                 "of 15 is 7 from ROM + 8 from RAM." % NAME_RAM)
    else:
        L += wrap("; Read by: ", "NOTHING.  Not one 32-bit word in any of the four "
                                 "images holds an address in [0x%06X, 0x%06X) -- while "
                                 "each of the three live copies is spelled at four "
                                 "interior offsets.  This copy is an ORPHAN. ⚠ A "
                                 "computed address cannot be excluded by a scan; the "
                                 "claim is about the scan." % (a, a + 99))
    L += wrap("; Length:  ", "the `00 00 00 00` at +0x12 is a PLACEHOLDER.  0xF7789A "
                             "computes (0x126C)*1024 + (cursor - 0x60A700) - 22 and "
                             "stores it most significant byte first into "
                             "(0x10C4)-(0x10C7).  22 = `MThd` + its 6 payload bytes + "
                             "`MTrk`.  That is why every chunk walker that trusts the "
                             "field steps nowhere.")
    L += ["; Evidence: notes/gen_prom_b_smf_writer_module.py --selftest re-derives "
          "every",
          ";           byte and every reader from the ROM."]
    return header(L)


def tab_header(a, live):
    v = words(a)
    L = ["; SmfPartOffsets_%06X -- 32 little-endian 16-bit BYTE OFFSETS and a" % a,
         ";          0xFFFF terminator.  NOT MIDI, and not part of the file: it only",
         ";          happens to sit 0x21 bytes after the template.",
         ";          0x%04X, 0x%04X ... 0x%04X, step 0x40 -- one record per slot in the"
         % (v[0], v[1], v[31]),
         ";          0x40-strided array at RAM 0x006036A0."]
    if live:
        L += wrap("; Read by: ", "five instructions spell 0x00%06X: 0xF76FB9 is "
                                 "`ld XDE,<base>` followed by `ld HL,(XDE+HL)` with "
                                 "HL = (byte from RAM 0x603422) * 2, and the result "
                                 "reaches `lda XIY,XIY+HL` on XIY = 0x006036A0." % a)
    else:
        L += ["; Read by: nothing -- this copy is the orphan's."]
    L += wrap("; ⚠ Note:  ", "the step is 0x40 everywhere EXCEPT between slots 7 and 8, "
                             "where it is 0x80: the record at 0x0200 is skipped.  That "
                             "is in the ROM and identical in all four copies.  What "
                             "occupies the skipped slot is NOT established.")
    return header(L)


def sysex_lines(a):
    """The two 8-byte SMF SysEx records the writer copies into the file."""
    b = bs(a, 16)
    L = []
    for k, (off, what) in enumerate(((0, "GM System On"), (8, "GM System Off"))):
        o = a + off
        L.append('\t.byte\t0x00\t; %06X  delta time 0' % o)
        L.append('\t.byte\t0xF0, 0x05\t; %06X  SysEx event, 5 bytes follow' % (o + 1))
        L.append('\t.byte\t0x7E, 0x7F\t; %06X  universal NON-real-time, device 0x7F = all'
                 % (o + 3))
        L.append('\t.byte\t0x09, 0x%02X\t; %06X  sub-ID 09 = General MIDI, 0x%02X = %s'
                 % (b[off + 6], o + 5, b[off + 6], what))
        L.append('\t.byte\t0xF7\t; %06X  end of exclusive' % (o + 7))
        if not k:
            L.append("")
    return L


def sysex_header(a):
    L = ["; GmSystemSysEx_%06X -- TWO 8-byte STANDARD MIDI FILE SysEx EVENTS, one" % a,
         ";          of which the writer copies into the output as the track's first",
         ";          event.  `00 F0 05 7E 7F 09 01 F7` is delta 0 + a 5-byte SysEx =",
         ";          universal non-real-time, all devices, General MIDI, GM System On;",
         ";          the second differs in ONE byte, 0x02 = GM System Off."]
    L += wrap("; Read by: ", "0xF76F4A `ld XIY,0x00%06X`, then `bit 2,(0x7f4d)` and "
                             "`jr NZ` past 0xF76F55 `ld XIY,0x00%06X`; the chosen "
                             "record is written a byte at a time by the loop at "
                             "0xF76F66 with `ld BC,0x0008`.  Set -> On, clear -> Off."
                             % (a, a + 8))
    L += wrap("; ⚠ Why:   ", "the linear decode frames these 16 bytes as `nop`, an "
                             "unencodable `db` and `ldx`.  They are DATA, and the byte "
                             "gate cannot tell the difference -- the two `ld XIY` "
                             "operands can.")
    return header(L)


def bytab_lines(a):
    b = bs(a, 8)
    return ["\t.byte\t" + ", ".join("0x%02X" % x for x in b)
            + "\t; %06X  entries 0-7" % a]


def bytab_header(a):
    b = bs(a, 8)
    L = ["; Table_%06X -- an 8-entry BYTE lookup table: %s." % (a, ", ".join("0x%02X" % x for x in b)),
         ";          Non-decreasing, 0x00 to 0x7F.  What the index and the value MEAN",
         ";          is not established here."]
    L += wrap("; Read by: ", "0xF76822 `ld XIX,0x00%06X` followed by "
                             "`ld L,(XIX+HL)` at 0xF76827, with HL = C zero-extended "
                             "-- the whole of the three-instruction routine at "
                             "0xF7681D." % a)
    L += wrap("; ⚠ Why:   ", "the linear decode frames the first five bytes as three "
                             "`nop`s and an `ld XWA,0x7f606040`.  They are DATA; the "
                             "byte gate cannot tell, the operand can.")
    return header(L)


def sub_header(a, live_calls, seg_start=False):
    L = ["; sub_%06X" % a]
    if live_calls:
        L += wrap("; Called from: ", ", ".join("0x%06X" % x for x in sorted(live_calls)))
    elif seg_start:
        L += ["; Called from: no call site is known.  The label marks where a",
              ";              converted run STARTS, so that a tool walking this file",
              ";              by label does not attribute the run to its neighbour."]
    L += ["; Evidence: 0x%06X is an instruction boundary of this transcription," % a,
          ";           re-asserted on every emit.  The name IS the address.",
          "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap",
          ";          stated, per this tree's rule that a stated gap beats a guess."]
    return header(L)


def callers_of(t):
    out = set()
    for s, n in code_spans():
        for ln in transcribe(s, n):
            if re.search(r"cal[lr]\s+0x%06x" % t, ln):
                a = line_addr(ln)
                if a is not None:
                    out.add(a)
    return out


def emit_block(blk):
    lines, tg = [], call_targets()
    first = True
    for kind, s, n in blk:
        if kind == "smftpl":
            lines += ([] if first else [""])
            lines += tpl_header(s, s != 0xF768F0)
            lines.append("SmfFileTemplate_%06X:" % s)
            lines += tpl_lines(s)
        elif kind == "sysex":
            lines += [""]
            lines += sysex_header(s)
            lines.append("GmSystemSysEx_%06X:" % s)
            lines += sysex_lines(s)
            lines += [""]
        elif kind == "bytab":
            lines += [""]
            lines += bytab_header(s)
            lines.append("Table_%06X:" % s)
            lines += bytab_lines(s)
            lines += [""]
        elif kind == "smftab":
            lines += [""]
            lines += tab_header(s, s != 0xF76911)
            lines.append("SmfPartOffsets_%06X:" % s)
            lines += tab_lines(s)
        else:
            for ln in transcribe(s, n):
                a = line_addr(ln)
                if a in tg or a == s:
                    lines += ([] if (first and not lines) else [""])
                    lines += sub_header(a, callers_of(a), seg_start=(a == s))
                    lines.append("sub_%06X:" % a)
                lines.append(ln)
        first = False
    return lines


def emit():
    out = []
    for i, (lo, hi, blk) in enumerate(blocks()):
        if i:
            out += ["", ""]
        out += emit_block(blk)
    return out


# ------------------------------------------------------------------ verify
def verify(lines, lo, hi):
    import llvm_roundtrip as RT
    body = [l + "\n" for l in lines if not l.lstrip().startswith(";") and l.strip()
            and not re.match(r"^[A-Za-z_][A-Za-z0-9_]*:$", l)]
    got, err = RT.assemble(body)
    if got is None:
        return False, "llvm-mc refused the emitted text:\n" + err[-2000:]
    want = bs(lo, hi - lo)
    if got != want:
        for i in range(min(len(got), len(want))):
            if got[i] != want[i]:
                return False, ("first difference at 0x%06X: emitted 0x%02X, ROM 0x%02X"
                               % (lo + i, got[i], want[i]))
        return False, "length differs: emitted %d, ROM %d" % (len(got), len(want))
    return True, "%d bytes re-assemble to the ROM exactly" % len(got)


# ------------------------------------------------------------------ checks
FAIL = []


def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append(desc)
    if verbose:
        print("  %-4s %-64s %s" % ("ok" if ok else "FAIL", desc,
                                   "" if ok else "got %r want %r" % (got, want)))
    return ok


def checks(verbose=True):
    del FAIL[:]
    d = rom()

    # -- 1. four byte-identical copies, and the identity stops at exactly 99
    n = 0
    while len({d[t - B_BASE + n] for t in TPLS}) == 1:
        n += 1
    c("the four copies are byte-identical for exactly 99 bytes", n, 99, verbose)
    c("byte 99 differs across the copies",
      len({d[t - B_BASE + 99] for t in TPLS}) > 1, True, verbose)

    # -- 2. the file header's fields
    b = bs(TPLS[3], 33)
    c("+0x00 is `MThd`", b[:4], b"MThd", verbose)
    c("+0x04 chunk length is 6, most significant byte first",
      struct.unpack(">I", b[4:8])[0], 6, verbose)
    c("+0x08 format is 0", struct.unpack(">H", b[8:10])[0], 0, verbose)
    c("+0x0A ntrks is 1", struct.unpack(">H", b[10:12])[0], 1, verbose)
    c("+0x0C division is 96 ticks per quarter note",
      struct.unpack(">H", b[12:14])[0], 96, verbose)
    c("+0x0E is `MTrk`", b[14:18], b"MTrk", verbose)
    c("+0x12 track length is ZERO -- the placeholder",
      struct.unpack(">I", b[18:22])[0], 0, verbose)
    c("+0x16 is delta 0, meta FF 03 (track name), declared length 15",
      tuple(b[22:26]), (0x00, 0xFF, 0x03, 0x0F), verbose)
    c("+0x1A is the 7 ROM name bytes `WSA    `", b[26:33], b"WSA    ", verbose)

    # -- 3. the copy sequences that PROVE the 33-byte extent
    #    ⚠ copy A is NOT identical to copies B and D: at +0x0E it runs `ldir`
    #    with BC=4 (`MTrk` only) and then writes the REAL length from
    #    (0x10C4)/(0x10C6), where B and D run `ldirw` with BC=4 and ship the
    #    template's four zero bytes.  Both make +0x16 the third source, so the
    #    33-byte extent is the same either way -- and copy A is the proof that
    #    (0x10C4)-(0x10C7) is what the placeholder stands in for.
    for t in (0xF7493F, 0xF760BF, 0xF77836):
        s1 = d.find(struct.pack("<I", t))
        c("0x%06X: `ld XIY,tpl` (opcode 0x45) then `ld BC,7` + `ldirw` = 14 bytes" % t,
          (d[s1 - 1], d[s1 + 4:s1 + 9], d[s1 + 9:s1 + 14]),
          (0x45, bytes([0x44, 0x00, 0xA7, 0x60, 0x00]),
           bytes([0x31, 0x07, 0x00, 0x95, 0x11])), verbose)
        s2 = d.find(struct.pack("<I", t + 0x0E))
        c("0x%06X: `ld XIY,tpl+0x0E` then `ld BC,4` + a block move" % t,
          (d[s2 - 1], d[s2 + 4:s2 + 7], d[s2 + 7] in (0x85, 0x95), d[s2 + 8]),
          (0x45, bytes([0x31, 0x04, 0x00]), True, 0x11), verbose)
        s3 = d.find(struct.pack("<I", t + 0x16))
        c("0x%06X: `ld XIY,tpl+0x16` then `ld BC,11` + `ldir` = 11 bytes" % t,
          (d[s3 - 1], d[s3 + 4:s3 + 9]),
          (0x45, bytes([0x31, 0x0B, 0x00, 0x85, 0x11])), verbose)
        c("0x%06X: 14+8+11 = 33 = the offset of the word table" % t,
          14 + 8 + 11, TAB_OFF, verbose)
        c("0x%06X: then `ld XIY,0x%04X` + `ld BC,8` + `ldir` -- 7+8 = 15, the "
          "declared name length" % (t, NAME_RAM),
          d[s3 + 9:s3 + 19],
          bytes([0x45, NAME_RAM & 0xFF, NAME_RAM >> 8, 0x00, 0x00,
                 0x31, 0x08, 0x00, 0x85, 0x11]), verbose)
    c("copy A ships `ldir` (0x85) at +0x0E where copies B and D ship `ldirw` (0x95)",
      (d[d.find(struct.pack("<I", 0xF7493F + 0x0E)) + 7],
       d[d.find(struct.pack("<I", 0xF760BF + 0x0E)) + 7],
       d[d.find(struct.pack("<I", 0xF77836 + 0x0E)) + 7]),
      (0x85, 0x95, 0x95), verbose)
    c("copy A then writes (0x10C4) and (0x10C6) into the file -- the real MTrk "
      "length, in the placeholder's four bytes",
      (bs(0xF73A3C, 4), bs(0xF73A43, 4)),
      (bytes([0xD1, 0xC4, 0x10, 0x20]), bytes([0xD1, 0xC6, 0x10, 0x20])), verbose)

    # -- 4. the word table
    for t in TPLS:
        v = words(t + TAB_OFF)
        c("0x%06X+0x21: 32 values then 0xFFFF" % t, (len(v), v[32]), (33, 0xFFFF), verbose)
        st = [v[i + 1] - v[i] for i in range(31)]
        c("0x%06X+0x21: 30 steps of 0x40 and one of 0x80" % t,
          (st.count(0x40), st.count(0x80), len(st)), (30, 1, 31), verbose)
        c("0x%06X+0x21: the skipped record is 0x0200" % t,
          v[st.index(0x80)] + 0x40, 0x0200, verbose)

    # -- 5. the readers of the word table
    for t in (0xF7493F, 0xF760BF, 0xF77836):
        cnt = 0
        p, i = struct.pack("<I", t + TAB_OFF), -1
        while True:
            i = d.find(p, i + 1)
            if i < 0:
                break
            cnt += 1
        c("0x%06X+0x21 is spelled 5 times as a 32-bit immediate" % t, cnt, 5, verbose)
    c("0xF76FB9 is `ld XDE,0x00F77857` (42 = ld XDE,imm32)",
      bs(0xF76FB9, 5), bytes([0x42, 0x57, 0x78, 0xF7, 0x00]), verbose)
    c("0xF76FBE is `ld HL,(XDE+HL)`",
      bs(0xF76FBE, 5), bytes([0xD3, 0x07, 0xE8, 0xEC, 0x23]), verbose)
    c("0xF76F87 loads XIY = 0x006036A0, the array the offsets index",
      bs(0xF76F87, 5), bytes([0x45, 0xA0, 0x36, 0x60, 0x00]), verbose)
    c("0xF76FA6 loads XIX = 0x00603422, the RAM byte table that supplies the index",
      bs(0xF76FA6, 5), bytes([0x44, 0x22, 0x34, 0x60, 0x00]), verbose)
    c("0xF76FC4 compares the fetched word with 0xFFFF -- the terminator test",
      bs(0xF76FC4, 4), bytes([0xDB, 0xCF, 0xFF, 0xFF]), verbose)

    # -- 6. the fourth copy is an orphan
    hits = 0
    for name in ROMS:
        dd = rom(name)
        for i in range(len(dd) - 3):
            if 0xF768F0 <= struct.unpack_from("<I", dd, i)[0] < 0xF76953:
                hits += 1
    c("no 32-bit word in any of the four images points inside copy 3", hits, 0, verbose)

    # -- 7. the false positive, refuted
    c("the lone hit on 0x00F77850 straddles two instructions at 0xF47B0B/0xF47B0F",
      (bs(0xF47B0B, 4), bs(0xF47B0F, 3)),
      (bytes([0xF1, 0xE0, 0x33, 0x50]), bytes([0x78, 0xF7, 0x00])), verbose)

    # -- 8. the writer really writes MIDI
    c("0xF77933 stages 0xFF -- a meta event's first byte", bs(0xF77933, 2),
      bytes([0x21, 0xFF]), verbose)
    c("0xF7793F stages 0x51 -- Set Tempo", bs(0xF7793F, 2), bytes([0x21, 0x51]), verbose)
    c("0xF7794B stages 0x03 -- its length", bs(0xF7794B, 2), bytes([0x21, 0x03]), verbose)
    c("0xF77957/0xF77965/0xF77973 read (0x108E), (0x108D), (0x108C) -- the tempo, "
      "most significant byte first",
      (bs(0xF77957, 4), bs(0xF77965, 4), bs(0xF77973, 4)),
      (bytes([0xC1, 0x8E, 0x10, 0x21]), bytes([0xC1, 0x8D, 0x10, 0x21]),
       bytes([0xC1, 0x8C, 0x10, 0x21])), verbose)
    c("0xF77989 ors 0xB0 -- a Control Change status byte",
      bs(0xF77989, 3), bytes([0xC9, 0xCE, 0xB0]), verbose)

    # -- 9. the length backfill
    c("0xF778AC reads the output cursor (0x1088) as 32 bits",
      bs(0xF778AC, 4), bytes([0xE1, 0x88, 0x10, 0x23]), verbose)
    c("0xF778B0 subtracts the buffer base 0x0060A700",
      bs(0xF778B0, 6), bytes([0xEB, 0xCA, 0x00, 0xA7, 0x60, 0x00]), verbose)
    c("0xF778B8 subtracts 22 = len(`MThd`) + 6 + len(`MTrk`) + len(the length field)",
      (bs(0xF778B8, 6), 4 + 4 + 6 + 4 + 4),
      (bytes([0xE8, 0xCA, 0x16, 0x00, 0x00, 0x00]), 22), verbose)
    c("0xF778C1-0xF778CD store D,E,W,A into (0x10C4)-(0x10C7) -- most significant "
      "byte first",
      tuple(bs(0xF778C1 + 4 * k, 4)[1] for k in range(4)), (0xC4, 0xC5, 0xC6, 0xC7),
      verbose)

    # -- 10. every one of the SIX code spans ends on a `ret`
    for s, n in code_spans():
        c("code 0x%06X+%d ends with 0x0E (`ret`)" % (s, n), bs(s + n - 1, 1),
          b"\x0e", verbose)
        last = [line_addr(l) for l in transcribe(s, n) if line_addr(l) is not None][-1]
        c("code 0x%06X+%d: the linear decode's last line is its last instruction"
          % (s, n), last < s + n, True, verbose)

    # -- 11. every call target is an instruction boundary
    bad = sorted(a for a in call_targets() if a not in boundaries())
    c("every decoded call target inside the spans is an instruction boundary",
      bad, [], verbose)
    bad = sorted(a for a in branch_targets()
                 if a not in boundaries() and not any(
                     k != "code" and s_ <= a < s_ + n for k, s_, n in layout()))
    c("every in-range branch target is an instruction boundary or a typed object",
      bad, [], verbose)

    # -- 11b. the byte scan is separated from the operands, and the split is 3/9
    ph = pointer_hits()
    ops = sorted({v for _n, _i, v, isop in ph if isop})
    c("12 words in the four images land in a code span", len(ph), 12, verbose)
    c("exactly 3 of them sit behind an `ld XRR,imm32` opcode -- and they are the "
      "three DATA objects this tool carves out",
      ops, [0xF7682E, 0xF76E64, 0xF76E6C], verbose)
    c("the other 9 have NO `ld XRR,imm32` opcode in front of them, so they are "
      "not operands",
      sorted({d0[i - 1] for d0, i in
              [(rom(n), i) for n, i, _v, o in ph if not o]} & IMM32_OPCODES),
      [], verbose)
    c("and they are these 9 values -- several are the `f7 00` that sits inside a "
      "`78 f7 00` / `76 f7 00` long branch",
      sorted(v for _n, _i, v, o in ph if not o),
      [0xF77000, 0xF7760F, 0xF776C3, 0xF7772A, 0xF77800, 0xF77800, 0xF77800,
       0xF77803, 0xF778EA], verbose)

    # -- 11c. the two data objects the linear decode would have swallowed
    c("0xF76822 is `ld XIX,0x00F7682E` and 0xF76827 is `ld L,(XIX+HL)`",
      (bs(0xF76822, 5), bs(0xF76827, 5)),
      (bytes([0x44, 0x2E, 0x68, 0xF7, 0x00]),
       bytes([0xC3, 0x07, 0xF0, 0xEC, 0x27])), verbose)
    c("0xF76F4A/0xF76F55 select between the two SysEx records on bit 2 of (0x7F4D)",
      (bs(0xF76F4A, 5), bs(0xF76F4F, 4), bs(0xF76F55, 5)),
      (bytes([0x45, 0x64, 0x6E, 0xF7, 0x00]), bytes([0xF1, 0x4D, 0x7F, 0xCA]),
       bytes([0x45, 0x6C, 0x6E, 0xF7, 0x00])), verbose)
    c("0xF76F63 copies 8 bytes of it", bs(0xF76F63, 3), bytes([0x31, 0x08, 0x00]),
      verbose)
    c("record 1 is delta 0 + `F0 05 7E 7F 09 01 F7` -- GM System On",
      bs(0xF76E64, 8), bytes([0x00, 0xF0, 0x05, 0x7E, 0x7F, 0x09, 0x01, 0xF7]), verbose)
    c("record 2 differs in one byte: 0x02 -- GM System Off",
      bs(0xF76E6C, 8), bytes([0x00, 0xF0, 0x05, 0x7E, 0x7F, 0x09, 0x02, 0xF7]), verbose)
    c("the SysEx length byte 0x05 equals the bytes that follow it",
      len(bs(0xF76E67, 5)), bs(0xF76E66, 1)[0], verbose)

    # -- 12. the segments tile the census range with no gap or overlap
    segs, a = layout(), 0xF7669D
    for _k, s, n in segs:
        if s != a:
            c("segments tile: expected 0x%06X" % a, s, a, verbose)
        a = s + n
    c("segments tile up to 0xF779D5", a, 0xF779D5, verbose)

    # -- 13. THE GATE-FACING ONE: every emitted block rebuilds its ROM bytes
    for lo, hi, blk in blocks():
        ok, msg = verify(emit_block(blk), lo, hi)
        c("0x%06X-0x%06X: %s" % (lo, hi - 1, msg), ok, True, verbose)

    if verbose:
        print("\n%d checks, %d failed" % (len(FAIL) + 0, len(FAIL)) if FAIL
              else "\nall checks pass")
    return not FAIL


# ----------------------------------------------------------------- siblings
SIBLINGS = (0xF7493F, 0xF760BF)


def sibling_lines(a):
    """0xF7493F and 0xF760BF were NAMED on 2026-08-31 and left as seven `.byte`
    rows, with a standing `Unknown: what the 0x40-strided bytes after offset
    0x21 are.  They are NOT claimed here.`  This types them the way the two
    copies inside the census range are typed, and retires that Unknown.
    ★ The 2026-08-31 attribution and its own correction note are kept."""
    L = ["; SmfFileTemplate_%06X -- the 33-byte STANDARD MIDI FILE header this" % a,
         ";          firmware copies into its output buffer before writing a track.",
         ";          Named 2026-08-31 by notes/prom_b_apply_smf_names.py, on",
         ";          notes/prom_b_smf_reader.py's 40 checks.",
         ";          ⚠ NOT MUSIC: no note, no end-of-track."]
    L += wrap("; ⚠ CORRECTED 2026-09-02: ",
              "that pass called the object 99 bytes and 32 of them the header. It is "
              "33 bytes of header (14+8+11, the three block moves) and then a "
              "SEPARATE 66-byte word table -- see SmfPartOffsets_%06X below, which "
              "retires this header's standing `Unknown: what the 0x40-strided bytes "
              "after offset 0x21 are`." % (a + TAB_OFF))
    L += wrap("; Read by: ", "`ld XIY,0x00%06X` at 0x%06X, and the image spells "
                             "+0x0E and +0x16 as well -- the three copy sources. "
                             "14+8+11 = 33 = 0x21, which is where the table starts."
                             % (a, ref_site(a)))
    L += wrap("; Length:  ", "the `00 00 00 00` at +0x12 is a PLACEHOLDER; 0xF7789A "
                             "computes the real value into (0x10C4)-(0x10C7), most "
                             "significant byte first. ★ Copy 0xF7493F PROVES it: at "
                             "+0x0E it runs `ldir` with BC=4 -- `MTrk` only -- and "
                             "then writes (0x10C4) and (0x10C6) into the file in the "
                             "placeholder's place.")
    L += ["; Evidence: notes/gen_prom_b_smf_writer_module.py --selftest."]
    out = header(L)
    out.append("SmfFileTemplate_%06X:" % a)
    out += tpl_lines(a)
    out += [""]
    out += tab_header(a + TAB_OFF, True)
    out.append("SmfPartOffsets_%06X:" % (a + TAB_OFF))
    out += tab_lines(a + TAB_OFF)
    return out


def ref_site(a):
    d = rom()
    return d.find(struct.pack("<I", a)) - 1 + B_BASE


def splice_siblings():
    src = open(SRCB, encoding="utf-8").read().split("\n")
    for a in sorted(SIBLINGS, reverse=True):
        lines = sibling_lines(a)
        ok, msg = verify(lines, a, a + 99)
        if not ok:
            raise SystemExit("refusing to splice 0x%06X: %s" % (a, msg))
        lab = "SmfFileTemplate_%06X:" % a
        hit = [i for i, l in enumerate(src) if l == lab]
        if len(hit) != 1:
            raise SystemExit("cannot locate %s: %d hits" % (lab, len(hit)))
        i = hit[0]
        top = i
        while top and (src[top - 1].startswith(";") or not src[top - 1].strip()):
            top -= 1
        bot = i
        while bot + 1 < len(src) and src[bot + 1].startswith("\t.byte"):
            bot += 1
        if bot - i != 7:
            raise SystemExit("%s: expected 7 `.byte` rows, found %d" % (lab, bot - i))
        src[top:bot + 1] = lines
        print("retyped 0x%06X: %d lines replace %d; %s" % (a, len(lines), bot + 1 - top, msg))
    open(SRCB, "w", encoding="utf-8").write("\n".join(src))
    return 0


# ------------------------------------------------------------------ splice
BLOCK_LABELS = {0xF7669D: "Data_F7669D", 0xF7681C: "Data_F7681C",
                0xF77836: "Data_F77836"}


def splice():
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to splice: a check failed (see above)")
    src = open(SRCB, encoding="utf-8").read().split("\n")
    before = len(src)
    for lo, hi, blk in sorted(blocks(), reverse=True):
        lines = emit_block(blk)
        ok, msg = verify(lines, lo, hi)
        if not ok:
            raise SystemExit("refusing to splice 0x%06X: %s" % (lo, msg))
        lab = BLOCK_LABELS[lo] + ":"
        hit = [i for i, l in enumerate(src) if l == lab]
        if len(hit) != 1:
            raise SystemExit("cannot locate %s: %d hits" % (lab, len(hit)))
        i = hit[0]
        top = i
        while top and (src[top - 1].startswith(";") or not src[top - 1].strip()):
            top -= 1
        bot = i
        while bot + 1 < len(src) and src[bot + 1].startswith("\t.byte"):
            bot += 1
        n_byte = bot - i
        if n_byte * 16 < (hi - lo) - 15 or n_byte * 16 > (hi - lo) + 15:
            raise SystemExit("%s: %d `.byte` rows do not cover %d bytes"
                             % (lab, n_byte, hi - lo))
        src[top:bot + 1] = lines
        print("spliced 0x%06X-0x%06X: %d lines replace %d; %s"
              % (lo, hi - 1, len(lines), bot + 1 - top, msg))
    open(SRCB, "w", encoding="utf-8").write("\n".join(src))
    print("prom_b/wsa1_prom_b.s: %d lines -> %d" % (before, len(src)))
    return 0


def main():
    a = sys.argv[1:]
    if "--layout" in a:
        for k, s, n in layout():
            print("  %-7s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        return 0
    if "--selftest" in a:
        return 0 if checks() else 1
    if "--splice-siblings" in a:
        return splice_siblings()
    if "--splice" in a:
        return splice()
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
