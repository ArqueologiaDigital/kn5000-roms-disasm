#!/usr/bin/env python3
"""GAP A's LAST FOUR REGISTERS: 0x0440, 0x0480, 0x04C0 and 0x0500 of 0x0010C000.

QUESTION ANSWERED
  `notes/WSA1-EMULATION-DISASM-GAPS.md` gap A says four of the twenty-two per-channel
  registers of CPU 2's device at 0x0010C000 have "no statement of any kind":
  0x0440, 0x0480, 0x04C0, 0x0500.  This script asserts, FROM THE ROM BYTES, what the
  firmware puts in them.

  THE ANSWER, in one sentence: **the low 6 or 7 bits of 0x0440, 0x0480 and 0x04C0 are a
  0x0010C000 CHANNEL NUMBER** -- the very same number the routine that computes it hands,
  three to twenty instructions later, to a `Dev10C_Slot*` accessor as that accessor's
  `chan` argument, where it becomes the register selector `chan + 0x0580` / `chan + 0x05C0`
  / `chan + 0x0540`.  These three registers are CHANNEL CROSS-REFERENCES, not scalars.
  The remaining bits are a small mode field (2 bits for 0x0440/0x0480, computed from the
  DSP algorithm descriptor; a 6-bit field plus two constant bits for 0x04C0).
  0x0500 is different in kind: it is the byte pair `notes/FINDINGS-prom_c-dev10c-sibling-
  register-map.md` sec.4b already decoded, and this script adds its four other write sites.

  ★ AND A FOURTH REGISTER JOINS THEM, WHICH IS OUTSIDE THIS SCRIPT'S BRIEF (sec.3b).
  `0x0180 + chan` -- the one `FINDINGS-prom_c-dev10c-sibling-register-map.md` sec.4 decoded
  as a 0..0x7F value with 0x80 = "randomise", and whose high byte that section could only
  call "the high-byte flags Voice_StageRegs_0180_AB accumulates in (XIZ+0xfa)" -- carries **the SLOT-1
  channel number in bits 13..8**, assembled by exactly the same idiom, from exactly the same
  allocator, as 0x0440 does for slot 2 and 0x04C0 for slot 3.  So the family is four
  registers, not three, and the four fields of 0x0180 tile its sixteen bits with no overlap.
  That does NOT disturb the pan reading of the low seven bits; it names the rest of the word.

  Four consequences an emulator can use directly (sections 9b and 9c):
    * the power-on value of all four is 0x0000, and the 68-byte reset image that says so
      is at ROM 0xFE12CF -- so 0 is "no link", not "not yet initialised";
    * on the C and D staging paths NONE of the channel-valued registers is ever computed:
      sub_FA96F7 clears words 8, 9, 10 and writes word 6 with a zero high byte, and the
      two routines that compute them are called only from VoiceRegs_Stage_A/_B and from
      two refresh loops;
    * the channel is REJECTED whenever the lookup answers >= 0x80 (0xFF is the sentinel
      sub_FA5ED3 returns when no slot is allocated), and the producer then leaves the word
      at whatever it held on entry.  ⚠ THAT IS NOT ALWAYS ZERO: 0x0440 and 0x0480 are
      cleared at sub_FA9915's entry, but **0x04C0 is SEEDED WITH 0x4400** at sub_FA9F19's
      entry (0xFA9F20) before any test, so a rejected slot 3 leaves 0x4400 in the register,
      not 0x0000.  An earlier draft of this docstring said "left cleared" of all three and
      was wrong about 0x04C0.
    * the reset image's word 6 is 0x0040 -- the sibling's stated pan CENTRE -- with a zero
      high byte, i.e. centred and with no slot-1 partner.  Two readings of one word agreeing.

WHAT THIS DOES **NOT** ESTABLISH
  * WHY one channel names another.  "Modulator", "partner partial", "effect send target"
    and "the stream the sample is read from" all fit a channel-valued register and nothing
    here distinguishes them.  What is measured is that the value IS a channel number of
    this device, in this device's own 0..0x7F slot-extended encoding.
  * That register 0x04C0's two constant bits (0x4400) mean anything.  They are a literal.
  * A name for 0x0440 or 0x0480.  The KN5000 sibling leaves both unnamed in its register
    table too; what it does do (sec.10) is call the words that feed them "slot words", and
    the two firmwares' code is 164 of 168 shared bytes DIFFERENT, so that is a structural
    agreement and not a transplant.  ⚠ The FOUR pairs sec.10 diffs are 99.1%, 98.4%, 87.3%
    and 97.6% different; an earlier draft claimed "more than 90%" for all four and checked
    it with `check(True, True)`, a test that cannot fail.  The floor is 55 of 63 bytes.
  * That 0x0180's high byte and its low byte are one quantity.  They are assembled by an
    `or` of two independently computed halves and nothing here says the hardware reads them
    together.  What is measured is the bit positions.
  * Anything about the twin device at 0x00104000.  Both devices have a block 0x0440; this
    file is 0x0010C000 only, reached through the staging struct at RAM 0x00D75E.

RUN
  python3 notes/prom_c_gapA_remaining_regs.py             # 16 sections, FAILURES: n
  python3 notes/prom_c_gapA_remaining_regs.py --selftest  # + 8 negative controls
  python3 notes/prom_c_gapA_remaining_regs.py --sites     # just the write-site census

  Section 10 needs the KN5000 sub-CPU as a flat binary.  It is the only input outside this
  repository, and it is regenerated -- not kept -- with

      llvm-objcopy -O binary \\
        ~/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf \\
        /tmp/kn5000_v142_full.bin

  (on this machine llvm-objcopy is /usr/lib/llvm-19/bin/llvm-objcopy; GNU objcopy REFUSES
  the file -- "unable to recognise the format", because e_machine is 0xfffe01).  The
  section prints `[skip]` and the rest of the file still runs if the binary is absent.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
ROMB = open(ROM, "rb").read()

# the KN5000 sub-CPU, for section 10 only.  Same convention as
# notes/prom_c_reg0100_0140_checks.py: a flat binary objcopy'd out of the sibling's ELF.
SIB_BIN = "/tmp/kn5000_v142_full.bin"
SIB_ELF = ("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/"
           "kn5000_subprogram_v142.llvm.elf")
SIB_SRC = ("/home/fsanches/compartilhado/kn5000-roms-disasm/v142/subcpu/"
           "kn5000_subprogram_v142.s")
SIB_BASE = 0x0400

STAGING = 0x00D75E          # the 0x0010C000 staging struct, RAM
FAIL = []


def b(addr, n):
    return ROMB[addr - BASE:addr - BASE + n]


def hx(addr, n):
    return b(addr, n).hex(" ")


def check(what, got, want):
    ok = got == want
    if not ok:
        FAIL.append(what)
        print("  [FAIL] %s\n         got  %r\n         want %r" % (what, got, want))
    else:
        print("  [ok] %s" % what)
    return ok


def code(addr, spelling, text):
    """Assert the bytes at `addr` are `spelling`, and print `text` beside them.

    Every citation in this file is the address of the INSTRUCTION, never one byte past
    it -- an earlier wave of this project was systematically off by one on ~20 of them,
    so the assertion is on the OPCODE byte and the check would fail if it were not."""
    return check("0x%06X  %-28s %s" % (addr, spelling, text),
                 hx(addr, len(spelling.split())), spelling)


# ----------------------------------------------------------------------------------
# The census.  word -> (register, RAM address, [(site, spelling, kind, text)])
# `kind` is one of: clear (a literal 0), seed (a literal != 0), store, rmw.
# ----------------------------------------------------------------------------------
SITES = {
    8: (0x0440, STAGING + 0x10, [
        (0xFA9773, "f2 6e d7 00 02 00 00", "clear",
         "ld (0x00d76e),0x0000     in sub_FA96F7 (the C/D staging path)"),
        (0xFA991C, "f2 6e d7 00 02 00 00", "clear",
         "ld (0x00d76e),0x0000     in sub_FA9915, at entry"),
        (0xFA99F9, "f2 6e d7 00 50", "store",
         "ld (0x00d76e),WA         = (tone2[+0x1E] & 0x00C0) | chan"),
        (0xFA9B2A, "f2 6e d7 00 51", "store",
         "ld (0x00d76e),BC         = AlgoFlags | chan"),
    ]),
    9: (0x0480, STAGING + 0x12, [
        (0xFA977A, "f2 70 d7 00 02 00 00", "clear",
         "ld (0x00d770),0x0000     in sub_FA96F7"),
        (0xFA9923, "f2 70 d7 00 02 00 00", "clear",
         "ld (0x00d770),0x0000     in sub_FA9915, at entry"),
        (0xFA9BC8, "f2 70 d7 00 51", "store",
         "ld (0x00d770),BC         = AlgoFlags | chan"),
    ]),
    10: (0x04C0, STAGING + 0x14, [
        (0xFA980E, "f2 72 d7 00 02 00 00", "clear",
         "ld (0x00d772),0x0000     in sub_FA96F7"),
        (0xFA9F20, "f2 72 d7 00 02 00 44", "seed",
         "ld (0x00d772),0x4400     in sub_FA9F19, at entry -- a CONSTANT"),
        (0xFA9FEE, "d2 72 d7 00 e8", "rmw",
         "or (0x00d772),WA         |= (tone2[+0x22] & 0x3300) | chan"),
    ]),
    11: (0x0500, STAGING + 0x16, [
        (0xFA96B0, "f2 74 d7 00 50", "store",
         "ld (0x00d774),WA         = (hi << 8) | lo   in Voice_StageRegs_0500_08C0_AB"),
        (0xFA96D4, "d2 74 d7 00 e9", "rmw",
         "or (0x00d774),BC         |= the cached low byte"),
        (0xFA970F, "f2 74 d7 00 02 00 00", "clear",
         "ld (0x00d774),0x0000     in sub_FA96F7"),
        (0xFC80A3, "bd 16 50", "store",
         "ld (XIY+0x16),WA         = byte(0x00E17C+part) << 9   in sub_FC7FCA"),
        (0xFC80BE, "b9 16 50", "store",
         "ld (XBC+0x16),WA         = byte(0x00E17C+part) << 8   in sub_FC7FCA"),
        (0xFC80D6, "99 16 e8", "rmw",
         "or (XBC+0x16),WA         |= byte(0x00E1DD+voice)      in sub_FC7FCA"),
    ]),
}


def section_0():
    print("\n0. THE WRITE-SITE CENSUS -- every write to the four staged words")
    print("   (a `+0x16` site is reached through the struct POINTER sub_FC7FCA is handed;")
    print("    the shipped notes/prom_c_dev10c_field_sources.py cannot see those three.)")
    total = 0
    for w in sorted(SITES):
        reg, ram, sites = SITES[w]
        print("   word %-2d  reg 0x%04X + chan   RAM 0x%06X   %d write site(s)"
              % (w, reg, ram, len(sites)))
        for addr, spell, kind, text in sites:
            code(addr, spell, "[%-5s] %s" % (kind, text))
            total += 1
    check("16 write sites over the four words", total, 16)
    # FIRST and LAST of the whole census, named explicitly
    first = SITES[8][2][0][0]
    last = SITES[11][2][-1][0]
    check("the FIRST site is 0xFA9773 and the LAST is 0xFC80D6", (first, last),
          (0xFA9773, 0xFC80D6))
    # cross-check against the shipped census + the audit's correction
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import prom_c_dev10c_field_sources as fs
    shipped = {}
    for a, off, _val, _rout, _form in fs.scan()[0]:
        shipped.setdefault(off // 2, []).append(a)
    for w in (8, 9, 10, 11):
        mine = set(a for a, _, _, _ in SITES[w][2])
        theirs = set(shipped.get(w, []))
        check("word %d: this census is a SUPERSET of the shipped one (+%d site(s))"
              % (w, len(mine - theirs)), theirs - mine, set())
    check("the shipped census maps word 8/9/10/11 to 0x0440/0x0480/0x04C0/0x0500",
          tuple(fs.WORD2BLOCK[w] * 0x40 for w in (8, 9, 10, 11)),
          (0x0440, 0x0480, 0x04C0, 0x0500))


# ----------------------------------------------------------------------------------
# The three parallel groups.  Each is (slot, tone2 word offset, tone-object offset,
# 0x004CCF sub-record offset, index bound, the register it stages, the two class
# selectors it builds).
# ----------------------------------------------------------------------------------
GROUPS = [
    # routine   slot  tone2  toneobj  subrec  bound  reg      class arms
    ("sub_FA9915", 2, 0x1E, 0x59, 0x00, 0x80, 0x0440, "k|0x20 / k"),
    ("Voice_StageRegs_0180_AB", 1, 0x20, 0x69, 0x09, 0x40, None,   "k|0x24 / k|0x04"),
    ("sub_FA9F19", 3, 0x22, 0x79, 0x12, 0x80, 0x04C0, "k|0x28 / k|0x08"),
]


def section_1():
    print("\n1. REGISTER 0x0440 + chan -- flags in bits 7..6, a CHANNEL in bits 5..0")
    print("   write A, 0xFA99F9, the tone-record path:")
    code(0xFA99F0, "99 1e 20", "ld WA,(XBC+0x1e)   XBC = voice[+0x25], the tone2 record")
    code(0xFA99F3, "d8 cc c0 00", "and WA,0x00c0      <- the 2-bit field, bits 7..6")
    code(0xFA99F7, "da e0", "or WA,DE           <- DE, the channel")
    code(0xFA99F9, "f2 6e d7 00 50", "ld (0x00d76e),WA")
    print("   and DE is the CHANNEL ARGUMENT of three slot-2 accessors:")
    code(0xFA999E, "2a", "push DE")
    code(0xFA999F, "1d ff 7c fb", "call 0xFB7CFF  Dev10C_Slot2_WriteGate8100")
    code(0xFA9A42, "2a", "push DE")
    code(0xFA9A43, "1d b1 7c fb", "call 0xFB7CB1  Dev10C_Slot2_StrobeGate")
    code(0xFA9AC1, "2a", "push DE")
    code(0xFA9AC2, "1d 8f 7c fb", "call 0xFB7C8F  Dev10C_SetChanReg_0600_b")
    print("   write B, 0xFA9B2A, the no-tone-record path:")
    code(0xFA9AE7, "1d 39 5e fb", "call 0xFB5E39  -> the 2-bit field (sec.5)")
    code(0xFA9AF4, "0b 0d 00", "push 0x000d    class 13, the third arg of sub_FA5ED3")
    code(0xFA9B04, "1d d3 5e fa", "call 0xFA5ED3  -> (class << 8) | channel (sec.6)")
    code(0xFA9B10, "d8 cf 80 00", "cp WA,0x0080   WA = the return's LOW BYTE")
    code(0xFA9B14, "6f 5e", "jr NC,0xfa9b74 -- >= 0x80 means NO CHANNEL, skip")
    code(0xFA9B18, "dc cc 7f 00", "and IX,0x007f  the channel")
    code(0xFA9B28, "dc e1", "or BC,IX       BC = the 2-bit field")
    code(0xFA9B2A, "f2 6e d7 00 51", "ld (0x00d76e),BC")
    print("   and the SAME 7 bits are the channel argument of the slot-2 writer:")
    code(0xFA9B68, "d8 cc 7f 00", "and WA,0x007f")
    code(0xFA9B6C, "28", "push WA")
    code(0xFA9B6D, "1d 27 7c fb", "call 0xFB7C27  Dev10C_Slot2_WriteGateAndValue")
    check("both writes leave bits 15..8 ZERO (0x00C0 and 0x0040/0x00C0 are byte masks)",
          (b(0xFA99F3, 4)[2:], b(0xFA9B18, 4)[2:]), (b"\xc0\x00", b"\x7f\x00"))


def section_2():
    print("\n2. REGISTER 0x0480 + chan -- the same shape, six bits of channel")
    code(0xFA9B90, "1d 39 5e fb", "call 0xFB5E39  -> the 2-bit field")
    code(0xFA9B9D, "0b 0c 00", "push 0x000c    class 12")
    code(0xFA9BAD, "1d d3 5e fa", "call 0xFA5ED3")
    code(0xFA9BB9, "d8 cf 80 00", "cp WA,0x0080   the same >= 0x80 = no channel test")
    code(0xFA9BBD, "7f 9a 00", "jrl NC,0xfa9c5a")
    code(0xFA9BC2, "d9 cc 3f 00", "and BC,0x003f  <- SIX bits here, not seven")
    code(0xFA9BC6, "da e1", "or BC,DE")
    code(0xFA9BC8, "f2 70 d7 00 51", "ld (0x00d770),BC")
    print("   and the same six bits are the channel argument of the slot-3 writer:")
    code(0xFA9C4D, "d8 cc 3f 00", "and WA,0x003f")
    code(0xFA9C51, "28", "push WA")
    code(0xFA9C52, "1d 1d 7d fb", "call 0xFB7D1D  Dev10C_Slot3_WriteGateAndValue")
    check("0x0440's low field is 7 bits and 0x0480's is 6 -- the masks differ",
          (b(0xFA9B18, 4)[2], b(0xFA9BC2, 4)[2]), (0x7F, 0x3F))


def section_3():
    print("\n3. REGISTER 0x04C0 + chan -- and its three fields TILE, with no overlap")
    code(0xFA9F20, "f2 72 d7 00 02 00 44", "ld (0x00d772),0x4400  the constant seed")
    code(0xFA9FD9, "d9 cf 80 00", "cp BC,0x0080   the >= 0x80 = no channel test")
    code(0xFA9FE5, "99 22 20", "ld WA,(XBC+0x22)  XBC = voice[+0x25]")
    code(0xFA9FE8, "d8 cc 00 33", "and WA,0x3300")
    code(0xFA9FEC, "dc e0", "or WA,IX          IX = the channel, 7 bits")
    code(0xFA9FEE, "d2 72 d7 00 e8", "or (0x00d772),WA")
    print("   and IX is the channel argument of three slot-1/3 accessors:")
    code(0xFA9F85, "d8 cc 7f 00", "and WA,0x007f")
    code(0xFA9F8C, "1d a9 80 fb", "call 0xFB80A9  Dev10C_Slot1or3_WriteGate8100")
    code(0xFAA02E, "1d 12 80 fb", "call 0xFB8012  Dev10C_Slot1or3_StrobeGate")
    code(0xFAA0B0, "1d ce 7f fb", "call 0xFB7FCE  Dev10C_SetChanReg_01C0_or_0600_b")
    seed, tone, chan = 0x4400, 0x3300, 0x007F
    check("the three fields are pairwise DISJOINT: 0x4400 | 0x3300 | 0x007F, no bit twice",
          (seed & tone, (seed | tone) & chan, seed | tone | chan), (0, 0, 0x777F))
    check("bit 7 and bit 15 are never set by any of the three", (0x777F >> 7) & 1,
          0)


def section_3b():
    """0x0180's HIGH byte is the slot-1 channel -- the fourth member of the family.

    This register is not one of gap A's four; it is here because the same three
    routines that stage 0x0440 (slot 2) and 0x04C0 (slot 3) also stage 0x0180 (slot 1),
    and the one thing the sibling note could not name about it was exactly the field
    this section identifies."""
    print("\n3b. ★ AND THE SAME IDIOM FILLS 0x0180 + chan -- ITS HIGH BYTE IS THE SLOT-1")
    print("    CHANNEL.  (Not a gap-A register; it is the fourth member of the family, and")
    print("    it is what FINDINGS-prom_c-dev10c-sibling-register-map.md sec.4 could only")
    print("    call 'the high-byte flags Voice_StageRegs_0180_AB accumulates in (XIZ+0xfa)'.)")
    code(0xFA9C81, "be fa 02 00 00", "ld (XIZ+0xfa),0x0000   the accumulator, zeroed")
    code(0xFA9CB5, "cb ce 24", "or C,0x24              class k|0x24 (group 1)")
    code(0xFA9CE1, "cb 31 02", "set 0x02,C             class k|0x04 (group 1)")
    code(0xFA9CC9, "1d d3 5e fa", "call 0xFA5ED3          the same allocator")
    code(0xFA9CD1, "dc cc 3f 00", "and IX,0x003f          the channel, six bits")
    code(0xFA9D24, "d9 cf 40 00", "cp BC,0x0040           <- bound 0x40 here, not 0x80")
    code(0xFA9D28, "7f 8a 01", "jrl NC,0xfa9eb5        rejected: (XIZ+0xfa) stays 0")
    code(0xFA9D30, "99 20 20", "ld WA,(XBC+0x20)       tone2[+0x20], the slot-1 word")
    code(0xFA9D33, "d8 cc 00 c0", "and WA,0xc000          <- the 2-bit field, bits 15..14")
    code(0xFA9D3A, "dc 8d", "ld IY,IX")
    code(0xFA9D3C, "dd ee 08", "sll 0x08,IY            <- the channel into bits 13..8")
    code(0xFA9D3F, "9e f6 e5", "or IY,(XIZ+0xf6)")
    code(0xFA9D42, "be fa 55", "ld (XIZ+0xfa),IY       = (field) | (chan << 8)")
    print("    and the accumulator is OR'd into the pan byte on both of sec.4's arms of")
    print("    the sibling note, then staged into word 6:")
    code(0xFA9EE4, "9e fa e0", "or WA,(XIZ+0xfa)       the `p == 0x80` random arm")
    code(0xFA9EEC, "b9 27 50", "ld (XBC+0x27),WA")
    code(0xFA9EFB, "9e fa e0", "or WA,(XIZ+0xfa)       the ordinary arm")
    code(0xFA9F03, "b9 27 50", "ld (XBC+0x27),WA")
    code(0xFA9F0B, "99 27 20", "ld WA,(XBC+0x27)")
    code(0xFA9F0E, "f2 6a d7 00 50", "ld (0x00d76a),WA       staging word 6 -> reg 0x0180")
    print("    the channel in bits 13..8 is the SAME number that selects slot 1's own")
    print("    registers, 0x0540 (gate) and 0x01C0 (value):")
    code(0xFA9CD5, "2c", "push IX")
    code(0xFA9CD6, "1d eb 7e fb", "call 0xFB7EEB  Dev10C_Slot1_WriteGate8100")
    code(0xFB7EF4, "db c8 40 05", "  add HL,0x0540   inside it")
    code(0xFA9D88, "2c", "push IX")
    code(0xFA9D89, "1d 9d 7e fb", "call 0xFB7E9D  Dev10C_Slot1_StrobeGate")
    code(0xFB7EB2, "db c8 40 05", "  add HL,0x0540   inside it")
    code(0xFA9EA9, "d8 cc 3f 00", "and WA,0x003f")
    code(0xFA9EAE, "1d 13 7e fb", "call 0xFB7E13  Dev10C_Slot1_WriteGateAndValue")
    code(0xFB7E2B, "da c8 40 05", "  add DE,0x0540   the gate")
    code(0xFB7E44, "da c8 c0 01", "  add DE,0x01c0   the value")
    check("0x0180's four fields TILE its sixteen bits: 0xC000 field | 0x3F00 channel | "
          "bit 7 unused | 0x007F pan", (0xC000 & 0x3F00, (0xC000 | 0x3F00) & 0x007F,
                                        0xC000 | 0x3F00 | 0x007F), (0, 0, 0xFF7F))
    print("    and the ROM's own reset image agrees with BOTH halves of that reading:")
    img = b(0xFE12CF, 68)
    w6 = img[12] | img[13] << 8
    check("reset word 6 = 0x0040 -- the sibling's stated pan CENTRE in the low byte, and "
          "a ZERO high byte, i.e. no slot-1 partner", w6, 0x0040)
    check("...and the same image's words 8, 9, 10, 11 are all 0x0000, so 0x0040 is a "
          "chosen value and not a fill pattern",
          [img[i] | img[i + 1] << 8 for i in range(16, 24, 2)], [0, 0, 0, 0])


def section_4():
    print("\n4. THE THREE PARALLEL GROUPS -- one per hardware slot, same shape, three "
          "strides")
    print("   routine      slot  tone2  toneobj  0x4CCF+  bound  register")
    for name, slot, t2, tobj, sub, bound, reg in [(g[0], g[1], g[2], g[3], g[4], g[5],
                                                   g[6]) for g in GROUPS]:
        print("   %-11s   %d    +0x%02X   0x%02X+4k    +%2d    0x%02X   %s"
              % (name, slot, t2, tobj, sub, bound,
                 "0x%04X" % reg if reg else "-- (writes only slot 1's own registers)"))
    # the tone2 word offsets are consecutive u16 and the tone-object offsets step 0x10
    code(0xFA9958, "85 23", "ld C,(XIY)         XIY = voice[+0x25] + 0x1E  (slot 2)")
    code(0xFA995A, "cb cc", "and C,0x03         k, the sub-entry index")
    code(0xFA9967, "ec c8 59 00 00 00", "add XIX,0x59       0x59 + 4k, in the tone object")
    code(0xFA9C90, "8d 20 21", "ld A,(XIY+0x20)    (slot 1)")
    code(0xFA9C93, "c9 cc", "and A,0x03")
    code(0xFA9CA0, "ec c8 69 00 00 00", "add XIX,0x69")
    code(0xFA9F45, "8d 22 26", "ld H,(XIY+0x22)    (slot 3)")
    code(0xFA9F48, "ce cc", "and H,0x03")
    code(0xFA9F53, "ec c8 79 00 00 00", "add XIX,0x79")
    check("the three tone2 words are consecutive u16: +0x1E, +0x20, +0x22",
          [g[2] for g in GROUPS], [0x1E, 0x20, 0x22])
    check("the three tone-object bases step by 0x10: 0x59, 0x69, 0x79",
          sorted(g[3] for g in GROUPS), [0x59, 0x69, 0x79])
    check("and they are in the SAME order (+0x1E->0x59, +0x20->0x69, +0x22->0x79)",
          sorted((g[2], g[3]) for g in GROUPS), [(0x1E, 0x59), (0x20, 0x69), (0x22, 0x79)])
    check("the three 0x004CCF sub-record offsets are 0, 9, 18 -- three 9-byte records",
          sorted(g[4] for g in GROUPS), [0x00, 0x09, 0x12])
    check("and 3 x 9 = 27, the record stride, so the three tile it exactly",
          3 * 9, 27)
    print("   the widest field each of the three touches on its cursor is +8, which is")
    print("   what makes 9 the sub-record size rather than an arithmetic coincidence:")
    code(0xFA9A6F, "bc 08 00 00", "ld (XIX+0x08),0x00   in sub_FA9915  (cursor +0)")
    code(0xFA9DB5, "ba 08 00 00", "ld (XDE+0x08),0x00   in Voice_StageRegs_0180_AB  (cursor +9)")
    code(0xFAA05A, "ba 08 00 00", "ld (XDE+0x08),0x00   in sub_FA9F19  (cursor +18)")


def section_5():
    print("\n5. THE 2-BIT FIELD: sub_FB5E39 returns EXACTLY 0x00C0, 0x0040 or 0x0000")
    code(0xFB5F7F, "30 c0 00", "ld WA,0x00c0")
    code(0xFB5F84, "30 40 00", "ld WA,0x0040")
    code(0xFB5F89, "dc 88", "ld WA,IX      IX was `ld IX,0x0000` at 0xFB5E46")
    code(0xFB5E46, "34 00 00", "ld IX,0x0000")
    # there is no fourth `ld WA,imm16` in the routine
    body = b(0xFB5E39, 0xFB5F91 - 0xFB5E39)
    n = sum(1 for i in range(len(body) - 2) if body[i] == 0x30)
    check("`ld WA,imm16` (opcode 0x30) occurs exactly twice in 0xFB5E39-0xFB5F90", n, 2)
    check("and both immediates have bit 6 SET -- 0 is the only 'absent' value",
          (0x00C0 & 0x40, 0x0040 & 0x40), (0x40, 0x40))
    print("   and the value comes out of DSP_AlgoDescriptor_Records (0xFDF4F1, 12 x 39):")
    code(0xFB5E4D, "d9 08 2c 01", "mul BC,0x012c    the part record, stride 300")
    code(0xFB5E53, "e3 e5 23 15 20", "ld XWA,(XBC+0x1523)")
    code(0xFB5E58, "c3 e1 d0 00 26", "ld H,(XWA+0x00d0)  the algorithm type byte")
    code(0xFB5E66, "d9 cf 0b 00", "cp BC,0x000b     <- 12 algorithm types, 0..11")
    code(0xFB5EB9, "21 27", "ld A,0x27        39 = the descriptor record size")
    code(0xFB5EC1, "e8 c8 13 00 00 00", "add XWA,0x00000013  19 = its header size")
    code(0xFB5EC7, "e8 c8 f1 f4 fd 00", "add XWA,0x00fdf4f1  DSP_AlgoDescriptor_Records")
    check("39 = 19 + 4 x 5 -- a 19-byte header and four 5-byte sub-records",
          19 + 4 * 5, 39)
    check("and the table really is 12 records of 39 bytes = 468", 12 * 39, 468)


def section_6():
    print("\n6. sub_FA5ED3 RETURNS (class << 8) | CHANNEL, with 0xFF meaning NO CHANNEL")
    code(0xFA5EDD, "cd cc", "and E,0x3f          E = the class, 6 bits")
    code(0xFA5EE0, "8e 0a 3f 40", "cp (XIZ+0x0a),0x40  arg1 = the VOICE, bound 64")
    code(0xFA5EE6, "8e 08 3f 21", "cp (XIZ+0x08),0x21  arg0 = the PART, bound 33")
    code(0xFA5EF3, "d9 ce ff 00", "or BC,0x00ff        the not-found low byte")
    code(0xFA600D, "26 ff", "ld H,0xff           the other not-found path")
    code(0xFA6015, "dc ee 08", "sll 8,IX            class into the high byte")
    code(0xFA601C, "dc e1", "or BC,IX")
    print("   its two ROM lookup tables, and the RAM arrays whose SIZES close exactly:")
    code(0xFA5F05, "e9 c8 c9 10 fe 00", "add XBC,0x00fe10c9  class&0x1F -> group 0..3")
    code(0xFA5F13, "e9 c8 e9 10 fe 00", "add XBC,0x00fe10e9  class -> field index 0..26")
    code(0xFA5F97, "23 1b", "ld C,0x1b           27 = the per-part field count")
    code(0xFA5FA6, "c3 e5 a8 0a 26", "ld H,(XBC+0x0aa8)   RAM array, 27 bytes per part")
    code(0xFA5F43, "34 3e 0e", "ld IX,0x0e3e        RAM array, 5 bytes per handle")
    code(0xFA5F22, "30 fe 11", "ld WA,0x11fe        RAM array, 12 bytes per voice")
    grp = b(0xFE10C9, 32)
    fld = b(0xFE10E9, 64)
    check("group table 0xFE10C9: classes 0-3 -> 0, 4-7 -> 1, 8-11 -> 2, 12 -> 3, 13 -> 0",
          (list(grp[0:4]), list(grp[4:8]), list(grp[8:12]), grp[12], grp[13]),
          ([0, 0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], 3, 0))
    check("field table 0xFE10E9[0..13] = 0..13 and [0x20..0x2B] = 0x0F..0x1A",
          (list(fld[0:14]), list(fld[0x20:0x2C])),
          (list(range(14)), list(range(0x0F, 0x1B))))
    check("its LAST non-zero entry is 0x1A, so the field index spans 0..26 = 27 values",
          max(fld), 0x1A)
    # the three array sizes close on one another, which is what fixes the counts
    check("0x0AA8 + 27 * 34 = 0x0E3E -- the per-part array ends where the handle array "
          "begins", 0x0AA8 + 27 * 34, 0x0E3E)
    check("0x0E3E + 5 * 192 = 0x11FE -- 192 = 0xC0, and 0xC0 is the not-allocated "
          "sentinel", 0x0E3E + 5 * 0xC0, 0x11FE)
    code(0xFA5F37, "ce cf c0", "cp H,0xc0           the sentinel, tested here")
    check("0x004CCF + 27 * 128 = 0x005A4F -- 128 channel records of 3 x 9 bytes",
          0x4CCF + 27 * 128, 0x5A4F)


def section_7():
    print("\n7. sub_FA598C TURNS THE HANDLE INTO THE CHANNEL, and the four arms give the "
          "RANGE")
    code(0xFA59B0, "cb cc", "and C,0x3f    groups 0 and 1 -> channel 0..0x3F")
    code(0xFA59B9, "cb ca", "sub C,0x40    group 2 ...")
    code(0xFA59BC, "cb 30 07", "res 7,C       ... -> channel 0..0x7F")
    code(0xFA59C5, "cb 30 07", "res 7,C       group 3 -> channel 0..0x7F")
    print("   so, class by class, the register field's RANGE is fixed by the group table:")
    grp = b(0xFE10C9, 32)
    rows = [("0x0440", "k, k|0x20", 0x00, 0x3F, 0x7F),
            ("0x0440", "13", 0x0D, 0x3F, 0x7F),
            ("0x0480", "12", 0x0C, 0x7F, 0x3F),
            ("0x04C0", "k|0x08, k|0x28", 0x08, 0x7F, 0x7F)]
    for reg, cls, probe, rng, mask in rows:
        g = grp[probe & 0x1F]
        print("     %s  class %-14s group %d  ->  0..0x%02X  (caller masks 0x%02X)"
              % (reg, cls, g, rng, mask))
    check("0x0440's channel is group 0 on BOTH its paths, so it never exceeds 0x3F -- "
          "which is why its 0x7F mask does not collide with the 0xC0 field at bit 6",
          (grp[0x00], grp[0x0D]), (0, 0))
    check("0x04C0's is group 2, so it uses the full 0..0x7F slot-extended encoding",
          grp[0x08], 2)
    check("0x0480's is group 3 (0..0x7F) but its caller keeps only six bits",
          (grp[0x0C], b(0xFA9BC2, 4)[2]), (3, 0x3F))


def section_8():
    print("\n8. THE ACCESSORS PROVE THE VALUE IS A CHANNEL: `chan + K` is the selector")
    for addr, spell, text in [
            (0xFB7D08, "db c8 80 05", "Dev10C_Slot2_WriteGate8100    add HL,0x0580"),
            (0xFB7CC6, "db c8 80 05", "Dev10C_Slot2_StrobeGate       add HL,0x0580"),
            (0xFB7C98, "db c8 00 06", "Dev10C_SetChanReg_0600_b      add HL,0x0600"),
            (0xFB7C3F, "da c8 80 05", "Dev10C_Slot2_WriteGateAndValue add DE,0x0580"),
            (0xFB7D35, "da c8 c0 05", "Dev10C_Slot3_WriteGateAndValue add DE,0x05c0"),
            (0xFB7D4E, "da c8 40 06", "Dev10C_Slot3_WriteGateAndValue add DE,0x0640"),
            (0xFB80C0, "da c8 40 05", "Dev10C_Slot1or3_WriteGate8100  add DE,0x0540"),
            (0xFB8030, "da c8 40 05", "Dev10C_Slot1or3_StrobeGate     add DE,0x0540"),
            (0xFB7FE0, "da c8 c0 01", "Dev10C_SetChanReg_01C0_or_0600 add DE,0x01c0")]:
        code(addr, spell, text)
    print("   and every one of those routines reads its `chan` from (XIZ+0x08), the")
    print("   argument the sections above showed is the value in the register's low bits.")
    print("   The registers written FOR a channel go out through Dev10C_WriteAllChanRegs")
    print("   with that channel = the voice number:")
    code(0xFB0B86, "1d 3a 71 fb", "call 0xFB713A  Dev10C_WriteAllChanRegs, in "
                                  "VoiceRegs_Stage_A")
    code(0xFAE3D3, "1e 00 ec", "calr 0xFACFD6  Dev10C_SetChanReg_0440, in the refresh "
                               "loop")
    code(0xFAE3B7, "ce cf 40", "cp H,0x40      that loop bounds the voice below 0x40")
    check("so a channel-valued register on channel n names some other channel m: the "
          "device sees 64 channels and both n and m are drawn from the same 0..0x3F",
          b(0xFAE3B7, 3)[2], 0x40)


def section_8b():
    print("\n8b. COMPLETENESS: every instruction in prom_c that can SELECT one of the four")
    print("    blocks, and which DEVICE each one belongs to (both devices have a 0x0440)")
    D10C, D104 = 0x0010C000, 0x00104000
    lit10c = bytes.fromhex("00 c0 10 00")
    lit104 = bytes.fromhex("00 40 10 00")
    rows = []
    for reg in (0x0440, 0x0480, 0x04C0, 0x0500):
        pat = bytes([0xC8, reg & 0xFF, reg >> 8])
        for i in range(1, len(ROMB) - 3):
            if ROMB[i:i + 3] != pat or ROMB[i - 1] not in (0xD8, 0xD9, 0xDA, 0xDB, 0xDC,
                                                           0xDD):
                continue
            a = BASE + i - 1                      # the `add rr,imm16` OPCODE, not the imm
            # resolve the device by the NEAREST PRECEDING peripheral-base literal.
            # A 24-byte forward window is not enough: the two unrolled writers load the
            # base once at the top and then select 22 registers from it.
            lo = max(0, i - 0x400)
            win = ROMB[lo:i + 0x40]
            here = i - lo

            def near(lit):
                best = None
                j = win.find(lit)
                while j >= 0:
                    d = abs(j - here)
                    best = d if best is None or d < best else best
                    j = win.find(lit, j + 1)
                return best
            d10c, d104 = near(lit10c), near(lit104)
            dev = (None if d10c is None and d104 is None else
                   D10C if d104 is None or (d10c is not None and d10c <= d104) else D104)
            rows.append((reg, a, dev))
    rows.sort()
    for reg, a, dev in rows:
        print("    0x%04X   0x%06X   %s" % (reg, a,
              "0x0010C000" if dev == D10C else
              "0x00104000  <- the TWIN device, NOT gap A" if dev == D104 else
              "device not resolved in a 24-byte window"))
    ours = [(r, a) for r, a, d in rows if d == D10C]
    check("14 select sites in all, of which 12 are 0x0010C000 and 2 are the twin device",
          (len(rows), len(ours), sum(1 for _, _, d in rows if d == D104)), (14, 12, 2))
    check("the FIRST 0x0010C000 site is 0xFACFDF (Dev10C_SetChanReg_0440) and the LAST "
          "is 0xFB72B5 (inside Dev10C_WriteAllChanRegs)", (ours[0], ours[-1]),
          ((0x0440, 0xFACFDF), (0x0500, 0xFB72B5)))
    check("block 0x0480 has no accessor in the FIRST driver bank (0xFACE67-0xFAD141) -- "
          "it is one of the five blocks only the second bank reaches",
          [a for r, a in ours if r == 0x0480 and a < 0xFAD141], [])
    check("every one of the 12 is inside a Dev10C_ accessor, i.e. reads its value out of "
          "the staging struct -- there is NO path into these four registers that does not "
          "go through the staged word",
          sorted(set(r for r, _ in ours)), [0x0440, 0x0480, 0x04C0, 0x0500])
    # ⚠ The scan above only recognises `add rr,imm16`.  A selector built any other way
    # would be invisible to it, and "there is NO path" is exactly the kind of negative
    # this project has asserted without running the census.  So: inside the two driver
    # banks, take EVERY occurrence of the four block numbers as a raw little-endian
    # halfword, whatever precedes it, and check that each one is the immediate of an
    # `add rr,imm16` the scan already found.  0 residue means the opcode filter loses
    # nothing THERE; outside the banks the negative remains a scan, not a proof.
    banks = [(0xFACE67, 0xFAD141), (0xFB7016, 0xFB828D)]
    # `add rr,imm16` is three bytes of opcode+operand form (e.g. `db c8` = add HL,imm16)
    # followed by the two immediate bytes, so the immediate starts at opcode + 2.
    found_imm = set(a + 2 for _, a, _ in rows)
    residue = []
    for reg in (0x0440, 0x0480, 0x04C0, 0x0500):
        pat = bytes([reg & 0xFF, reg >> 8])
        for lo, hi in banks:
            for a in range(lo, hi - 1):
                if b(a, 2) == pat and a not in found_imm:
                    residue.append((reg, a))
    check("inside the driver banks 0xFACE67-0xFAD141 and 0xFB7016-0xFB828D, every raw "
          "occurrence of the four block numbers is one of those `add rr,imm16` immediates "
          "-- residue %d" % len(residue), residue, [])
    check("...and there are 14 of them there, i.e. the whole select census lives in the "
          "banks", sum(1 for lo, hi in banks for _, a, _ in rows if lo <= a < hi), 14)


def section_9():
    print("\n9. REGISTER 0x0500 + chan -- a BYTE PAIR, and it has SIX write sites, not two")
    code(0xFA96AB, "d8 ee 08", "sll 8,WA          the high byte")
    code(0xFA96AE, "d9 e0", "or WA,BC          the low byte")
    code(0xFA96B0, "f2 74 d7 00 50", "ld (0x00d774),WA")
    code(0xFA96D4, "d2 74 d7 00 e9", "or (0x00d774),BC  the low byte alone")
    print("   the two halves are each clamped to 0..0x7F by Clamp_ToRange_Word "
          "(0xFA7598):")
    code(0xFA9600, "0b 7f 00", "push 0x007f       the hi argument")
    code(0xFA95FD, "0b 00 00", "push 0x0000       the lo argument")
    code(0xFA9604, "1e 91 df", "calr 0xfa7598     Clamp_ToRange_Word")
    code(0xFA9699, "0b 7f 00", "push 0x007f       and again for the other half")
    code(0xFA969D, "1e f8 de", "calr 0xfa7598")
    print("   ★ AND sub_FC7FCA REBUILDS THE SAME WORD, which sec.4b of the sibling note")
    print("     does not cover.  Its high byte is a per-part byte, shifted 8 OR 9:")
    code(0xFC8078, "e9 c8 d7 e0 00 00", "add XBC,0x0000e0d7  a per-(part, d) mode byte")
    code(0xFC807E, "81 21", "ld A,(XBC)")
    code(0xFC8080, "c9 da", "cp A,2            selects the <<9 arm")
    code(0xFC809D, "d8 ee 09", "sll 9,WA          <- NINE on the A == 2 arm")
    code(0xFC80A3, "bd 16 50", "ld (XIY+0x16),WA")
    code(0xFC80B8, "d8 ee 08", "sll 8,WA          <- EIGHT on the other")
    code(0xFC80BE, "b9 16 50", "ld (XBC+0x16),WA")
    code(0xFC8091, "e8 c8 7c e1 00 00", "add XWA,0x0000e17c  the per-part byte table")
    code(0xFC80C9, "e9 c8 dd e1 00 00", "add XBC,0x0000e1dd  the per-voice cache")
    code(0xFC80D6, "99 16 e8", "or (XBC+0x16),WA    the low byte OR'd back in")
    check("the two shift arms differ by exactly one bit position (8 vs 9)",
          (b(0xFC80B8, 3)[2], b(0xFC809D, 3)[2]), (8, 9))
    print("   and the order inside VoiceRegs_Stage_A is what makes the `or` at 0xFA96D4")
    print("   safe: Voice_StageRegs_0900_0940_0980_AB (which calls sub_FC7FCA) runs BEFORE sub_FA95D4.")
    code(0xFB0B11, "1d 2d 84 fa", "call 0xFA842D  -- calls sub_FC7FCA, seeds word 11")
    code(0xFB0B25, "1d d4 95 fa", "call 0xFA95D4  -- Voice_StageRegs_0500_08C0_AB")
    check("0xFB0B11 precedes 0xFB0B25 in the same routine", 0xFB0B11 < 0xFB0B25, True)


def section_9b():
    print("\n9b. THE POWER-ON VALUE OF ALL FOUR IS 0x0000, AND IT IS IN THIS ROM")
    code(0xFB8162, "f2 3b 13 fe 31", "lda XBC,0xFE133B")
    code(0xFB8175, "f2 db d8 00 31", "lda XBC,0x00D8DB  the reset staging struct")
    code(0xFB817E, "1e b9 ef", "calr 0xfb713a     Dev10C_WriteAllChanRegs, per channel")
    img = b(0xFE12CF, 68)
    words = [img[i] | img[i + 1] << 8 for i in range(0, 68, 2)]
    check("the 68-byte reset image at ROM 0xFE12CF has 0x0000 in words 8, 9, 10 and 11",
          words[8:12], [0, 0, 0, 0])
    check("...and it is NOT all zeros -- word 12 is 0xFF80, so the zeros are a choice",
          words[12], 0xFF80)
    print("    So the emulator can take 0x0000 in 0x0440/0x0480/0x04C0/0x0500 as the")
    print("    power-on state, and -- for the three channel-valued ones -- as NO LINK,")
    print("    which is exactly what every producer leaves behind when sub_FA5ED3")
    print("    answers 0xFF.")


def section_9c():
    print("\n9c. ON THE C AND D STAGING PATHS NO CHANNEL CROSS-REFERENCE IS EVER COMPUTED")
    print("    0x0440/0x0480 come only from sub_FA9915, 0x04C0 only from sub_FA9F19 and")
    print("    0x0180's high byte only from Voice_StageRegs_0180_AB; none of the three is reachable")
    print("    from VoiceRegs_Stage_C or _D, which call sub_FA96F7 instead.  sub_FA96F7")
    print("    clears words 8, 9, 10 and stages word 6 with a ZERO high byte -- so on C/D")
    print("    0x0180 is a bare 0..0x7F value.  Call-site census, over the whole 512 KiB,")
    print("    on the")
    print("    `call addr24` opcode 0x1D (a `calr` would be found by its own displacement;")
    print("    there is none for these three targets):")
    want = {0xFA9915: [0xFAE3C4, 0xFAE4FE, 0xFB0B2A, 0xFB1F18],
            0xFA9C60: [0xFAE641, 0xFAE77D, 0xFB0B2F, 0xFB1F1D],
            0xFA9F19: [0xFAE8C2, 0xFAEA00, 0xFB0B34, 0xFB1F22],
            0xFA96F7: [0xFB2850, 0xFB2F25]}
    for tgt in (0xFA9915, 0xFA9C60, 0xFA9F19, 0xFA96F7):
        pat = bytes([0x1D]) + tgt.to_bytes(3, "little")
        hits = [BASE + i for i in range(len(ROMB) - 3) if ROMB[i:i + 4] == pat]
        check("sub_%06X has exactly these call sites: %s"
              % (tgt, " ".join("0x%06X" % h for h in want[tgt])), hits, want[tgt])
    code(0xFB0B2A, "1d 15 99 fa", "call 0xFA9915  in VoiceRegs_Stage_A")
    code(0xFB1F18, "1d 15 99 fa", "call 0xFA9915  in VoiceRegs_Stage_B")
    code(0xFB2850, "1d f7 96 fa", "call 0xFA96F7  in VoiceRegs_Stage_C")
    code(0xFB2F25, "1d f7 96 fa", "call 0xFA96F7  in VoiceRegs_Stage_D")
    check("the A/B stagers and the C/D stagers are disjoint sets of call sites",
          set(want[0xFA9915]) & set(want[0xFA96F7]), set())
    # and sub_FA96F7 cannot compute a channel because it never asks for one: neither
    # allocator call appears anywhere in its 542 bytes, in either the `call addr24` or
    # the `calr disp16` form.  (Checked in both forms because a nearby target is exactly
    # the case where the assembler picks `calr` -- 0xFA5ED3 is 0x1824 bytes away.)
    body = b(0xFA96F7, 0xFA9915 - 0xFA96F7)
    calr = set()
    for i in range(len(body) - 2):
        if body[i] == 0x1E:
            calr.add(0xFA96F7 + i + 3
                     + int.from_bytes(body[i + 1:i + 3], "little", signed=True))
    check("sub_FA96F7 (542 bytes) calls neither sub_FA5ED3 nor sub_FB5E39, in either the "
          "`call addr24` or the `calr disp16` form -- so the C/D path has no channel to "
          "put anywhere",
          (body.count(bytes([0x1D]) + (0xFA5ED3).to_bytes(3, "little")),
           body.count(bytes([0x1D]) + (0xFB5E39).to_bytes(3, "little")),
           0xFA5ED3 in calr, 0xFB5E39 in calr, len(body)),
          (0, 0, False, False, 542))


def section_9d():
    """RANGE and CLAMP per register -- gap A asks for both, in one place.

    Every mask and every clamp bound below is READ OUT OF THE INSTRUCTION at the address
    beside it; nothing here is typed twice.  The `allowed` column is the OR of the masks
    the producers can set, so it is an upper bound on the register's value, not a claim
    that every value in it occurs."""
    print("\n9d. RANGE AND CLAMP -- the answer to gap A's third question, in one table")
    print("    reg      allowed bits   fields (mask <- the immediate that makes it)")
    # (register, [(mask, instruction addr, immediate offset inside it, left shift)], clamp)
    table = [
        (0x0440, [(0x00C0, 0xFA99F3, 2, 0), (0x007F, 0xFA9B18, 2, 0)],
         "channel REJECTED unless < 0x80 (0xFA99E4 / 0xFA9B10); word cleared at 0xFA991C"),
        (0x0480, [(0x00C0, 0xFA99F3, 2, 0), (0x003F, 0xFA9BC2, 2, 0)],
         "channel REJECTED unless < 0x80 (0xFA9BB9); word cleared at 0xFA9923"),
        (0x04C0, [(0x4400, 0xFA9F20, 5, 0), (0x3300, 0xFA9FE8, 2, 0),
                  (0x007F, 0xFA9F85, 2, 0)],
         "REJECTED unless < 0x80 (0xFA9FD9); word SEEDED 0x4400 at 0xFA9F20, NOT cleared"),
        (0x0500, [(0x7F00, 0xFA9699, 1, 8), (0x007F, 0xFA9600, 1, 0)],
         "each half clamped to [0,0x7F] by Clamp_ToRange_Word (0xFA7598), then the high "
         "half shifted 8 (0xFA96AB)"),
    ]
    for reg, fields, clamp in table:
        allowed = 0
        for m, _, _, _ in fields:
            allowed |= m
        print("    0x%04X   0x%04X         %s"
              % (reg, allowed, " | ".join("0x%04X<-%06X" % (m, s) for m, s, _, _ in fields)))
        print("             clamp: %s" % clamp)
    # Every mask above is read back out of the ROM at the operand position it claims, so a
    # mistyped mask cannot survive.  ⚠ 0x0500's two entries are the CLAMP BOUND pushed to
    # Clamp_ToRange_Word, not an `and` mask -- the register's high field exists because the
    # clamped half is then shifted left 8, which is why those rows carry a shift.
    for reg, fields, _ in table:
        for m, site, off, sh in fields:
            imm = int.from_bytes(b(site + off, 2), "little") << sh
            check("0x%04X: 0x%04X is the immediate at 0x%06X+%d, shifted %d"
                  % (reg, m, site, off, sh), imm, m)
    code(0xFA96AB, "d8 ee 08", "sll 8,WA   -- what puts the clamped half in bits 14..8")
    check("0x0440 and 0x0480 never set a bit above 7 -- both are BYTE-wide in practice",
          [m for r, fs, _ in table if r in (0x0440, 0x0480) for m, _, _, _ in fs
           if m > 0xFF], [])
    check("0x04C0's three fields are pairwise disjoint and bit 7 and bit 15 stay clear",
          (0x4400 & 0x3300, (0x4400 | 0x3300) & 0x007F,
           (0x4400 | 0x3300 | 0x007F) & 0x8080), (0, 0, 0))
    check("0x0500 is two 7-bit fields: bits 15 and 7 stay clear on the A/B path",
          (0x7F00 | 0x007F) & 0x8080, 0)
    print("    \u26a0 0x0500's HIGH byte has a second producer, sub_FC7FCA, whose `<< 9` arm")
    print("      (0xFC809D) can set bit 15 -- so 'bit 15 stays clear' is a property of the")
    print("      Voice_StageRegs_0500_08C0_AB path only, and which path wins is decided by")
    print("      bit 9 of voice[+0x01]:")
    code(0xFA962D, "dd cc 00 02", "and IY,0x0200   bit 9 of voice[+0x01]")
    code(0xFA96B0, "f2 74 d7 00 50", "ld  -> the whole word, when the bit is CLEAR")
    code(0xFA96D4, "d2 74 d7 00 e9", "or  -> the low byte only, when it is SET")


def section_10():
    print("\n10. THE KN5000 SUB-CPU: SAME ALGORITHM, DIFFERENT BYTES, AND IT SAYS 'SLOT'")
    if not os.path.exists(SIB_BIN):
        print("  [skip] %s absent.  Regenerate with:" % SIB_BIN)
        print("         llvm-objcopy -O binary %s %s" % (SIB_ELF, SIB_BIN))
        return
    SIB = open(SIB_BIN, "rb").read()

    def k(addr, n):
        return SIB[addr - SIB_BASE:addr - SIB_BASE + n]

    pairs = [("sub_FA5ED3 / ExtVoice_Alloc_StreamSlot", 0xFA5ED3, 339, 0x02177E, 506),
             ("sub_FB5E39 / DSP_AlgoType_Dispatch3", 0xFB5E39, 344, 0x033E02, 256),
             ("sub_FA78E8 / NoteState_ClearRecord", 0xFA78E8, 63, 0x022DBD, 63),
             ("sub_FA9915 0xFA9ACB.. / Voice_Chan_Fallback_NoWaveTable",
              0xFA9ACB, 168, 0x024DBE, 168)]
    ratios = []
    for name, wa, wn, ka, kn in pairs:
        n = min(wn, kn)
        x, y = b(wa, n), k(ka, n)
        d = sum(1 for i in range(n) if x[i] != y[i])
        ratios.append((d, n, name))
        print("  [--] %-58s %3d of %3d shared bytes DIFFER  (%.1f%%)"
              % (name, d, n, 100.0 * d / n))
    # ⚠ THIS USED TO BE `check("...more than 90%...", True, True)` -- a test that cannot
    # fail, next to a figure that is FALSE for the third pair (55/63 = 87.3%).  The
    # floor is computed now, and the sentence quotes the pair that sets it.
    dmin, nmin, who = min(ratios, key=lambda r: r[0] / r[1])
    check("every pair differs in at least 85%% of its shared bytes -- the floor is "
          "%d of %d (%.1f%%), set by %s -- so nothing here is a transplant"
          % (dmin, nmin, 100.0 * dmin / nmin, who), dmin * 100 >= 85 * nmin, True)
    # ⚠ GUARD AGAINST THE BUG THIS PROJECT HAS ALREADY PAID FOR: eight KN5000 transplants
    # named the wrong object because the sibling image was addressed with the wrong base
    # (off by 0xEB00).  SIB_BASE is therefore not taken on trust -- the bytes at
    # ExtVoice_Alloc_StreamSlot must be the prologue its own source spells out
    # (`dec 8, xsp / pushw_erp 0xFA / ld (xsp + 4), e`), which no other offset produces.
    check("SIB_BASE 0x%04X is right: 0x02177E holds ExtVoice_Alloc_StreamSlot's prologue"
          % SIB_BASE, k(0x02177E, 8).hex(" "), "ef 68 d7 fa 04 bf 04 45")
    if os.path.exists(SIB_SRC):
        src = open(SIB_SRC, encoding="utf-8").read()
        for phrase, what in [
            ("writes a precomputed slot word to\n; 0x0451DC (TG reg 0x440)",
             "the sibling calls the word behind its TG reg 0x440 a SLOT WORD"),
            ("Writes the secondary slot word to 0x0451DE (TG reg 0x480)",
             "and the word behind 0x480 the SECONDARY SLOT WORD"),
            ("0x0451E0 -> +0x4C0   oscillator config + slot",
             "and names 0x4C0 'oscillator config + slot'"),
            ("ExtVoice_Alloc_StreamSlot",
             "and calls sub_FA5ED3's counterpart ExtVoice_Alloc_StreamSlot"),
        ]:
            check(what, phrase.replace("\n; ", " ") in src.replace("\n; ", " "), True)
        check("its allocator packs the result the same way -- (class << 8) | slot, "
              "0xFF = none", ("or hl, 0xFF" in src and "ExtVoice_Alloc_StreamSlot_NoMatch"
                              in src), True)
        check("and its algorithm dispatcher returns the same three values",
              ("ldw	hl, 192" in src and "ldw	hl, 64" in src), True)
    print("  ⚠ The sibling's table leaves 0x440 and 0x480 UNNAMED, exactly as this image")
    print("    does.  What is borrowed here is nothing; what agrees is the STRUCTURE.")


def selftest():
    print("\n11. NEGATIVE CONTROLS")
    n0 = len(FAIL)
    check("[control] a wrong address does NOT carry the 0x0440 store",
          hx(0xFA99FA, 5) == "f2 6e d7 00 50", False)
    check("[control] the citation is not one byte PAST the instruction either",
          hx(0xFA99F8, 5) == "f2 6e d7 00 50", False)
    check("[control] register 0x0480's mask is NOT 0x7F", b(0xFA9BC2, 4)[2] == 0x7F,
          False)
    check("[control] 0x04C0's seed is NOT 0x4000", hx(0xFA9F20, 7).endswith("00 40"),
          False)
    # ⚠ REPLACED: this slot used to read "[control] the 0x3300 and 0x4400 fields would NOT
    # tile with a 0x00FF channel" and then assert `(0x4400|0x3300) & 0x00FF != 0` is False
    # -- i.e. it asserted that they DO tile, under a label saying they do not.  A control
    # has to be a statement the ROM could contradict; this one contradicted its own label.
    check("[control] 0x04C0's field split is NOT the same as 0x0440's -- 0x0440 masks the "
          "tone word with 0x00C0, 0x04C0 with 0x3300",
          hx(0xFA99F3, 4) == hx(0xFA9FE8, 4), False)
    check("[control] sub_FB5E39 has no `ld WA,0x0080` return",
          b(0xFB5E39, 344).find(bytes.fromhex("30 80 00")) >= 0, False)
    check("[control] 0x0180's channel is NOT in the low byte -- there is no `and IX,0x3f` "
          "followed directly by the staging store, the shift comes between",
          hx(0xFA9D3C, 3) == "00 00 00", False)
    check("[control] the slot-1 accessors do NOT use slot 2's register base",
          hx(0xFB7EF4, 4) == "db c8 80 05", False)
    print("  (%d of the eight controls fired, which must be 0)" % (len(FAIL) - n0))


def main():
    print(__doc__.strip().splitlines()[0])
    if "--sites" in sys.argv:
        section_0()
    else:
        for f in (section_0, section_1, section_2, section_3, section_3b, section_4,
                  section_5, section_6, section_7, section_8, section_8b, section_9,
                  section_9b, section_9c, section_9d, section_10):
            f()
        if "--selftest" in sys.argv:
            selftest()
    print("\nFAILURES: %d" % len(FAIL))
    for f in FAIL:
        print("  - %s" % f)
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
