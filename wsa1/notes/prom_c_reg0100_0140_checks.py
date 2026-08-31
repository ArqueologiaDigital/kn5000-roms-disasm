#!/usr/bin/env python3
"""WHAT DO 0x0010C000's REGISTERS 0x0100 + chan AND 0x0140 + chan CARRY?

QUESTION ANSWERED
  Gap A of ../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md asks, per register block of
  the device at CPU 2's 0x0010C000, what physical quantity it carries.  Rounds 1-2 named
  0x0040, 0x0080, 0x0400 and 0x0800 and left 0x0100 and 0x0140 with "still nothing".

  This script asserts, FROM THE ROM BYTES, the three things this round establishes:

    1. The two registers are a PAIR.  Every routine that stages either stages BOTH, in the
       same instruction pair, and stages nothing else.  Their values are the voice record's
       words +0x3F and +0x41.
    2. The FIELD SPLIT.  Bits 15..7 pass through from the voice word; bits 6..0 are a value
       clamped to [36, 120] by Clamp_36_to_120 (0xFA76B2), offset by +/- a per-part byte.
    3. Voice_StagePair_Reg0100_0140_AB and _CD are byte twins whose ONE semantic difference
       is the tone-record field they dispatch on: +0x36 versus +0x11.

  Section 6 adds one more register on the way past: 0x0500 + chan is a byte pair whose high
  byte comes out of DetuneCurve_LookupSigned and whose low byte is cached per voice at RAM
  0x00E1DD -- which is what the sibling's name for it, "detune / bend pair", predicts.

  Section 4 is the CROSS-IMAGE part and is reported separately on purpose: the KN5000
  sub-CPU has the same 22-word staging block with the same 22 register numbers, and its own
  disassembly calls +0x100 the TVF cutoff.  This script measures how far that sibling can be
  trusted here -- it diffs the bytes of the three counterpart routines (they are NOT
  identical) and counts the registers where this image has its own answer and the two agree.

WHAT THIS DOES NOT ESTABLISH
  * That the 7-bit quantity IS a filter cutoff.  Nothing in prom_c or prom_d names it.  What
    is measured here is the pair, the split, the bounds 36 and 120, and the sibling's map.
  * Anything about the device at 0x00104000.  Both devices have a register 0x0100; this file
    is 0x0010C000 only, via the staging struct at RAM 0x00D75E.

RUN
  python3 notes/prom_c_reg0100_0140_checks.py             # every section, FAILURES: n
  python3 notes/prom_c_reg0100_0140_checks.py --selftest  # + negative controls
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
SIB_BIN = "/tmp/kn5000_v142_full.bin"          # objcopy -O binary of the KN5000 sub-CPU ELF
SIB_ELF = ("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/"
           "kn5000_subprogram_v142.llvm.elf")
SIB_BASE = 0x0400

ROMB = open(ROM, "rb").read()
FAIL = []

# struct word -> register number, taken from the shipped map rather than retyped
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prom_c_dev10c_field_sources as _fs


def fs_block(w):
    """The register number struct word w is sent to, or 0 for word 0 (written literally)."""
    return _fs.WORD2BLOCK[w] * 0x40 if w in _fs.WORD2BLOCK else 0x000


def b(addr, n):
    return ROMB[addr - BASE:addr - BASE + n]


def check(what, got, want):
    ok = got == want
    if not ok:
        FAIL.append(what)
    print(f"  [{'ok' if ok else 'FAIL'}] {what}\n         got {got!r}  want {want!r}"
          if not ok else f"  [ok] {what}")


def hx(x):
    return x.hex(" ")


print(__doc__.split("RUN")[0].strip().splitlines()[0])
print()

# ---------------------------------------------------------------- 1. the clamp
print("1. Clamp_36_to_120 (0xFA76B2) -- both bounds are immediates")
check("0xFA76BA is `cp HL,0x0078`", hx(b(0xFA76BA, 4)), "db cf 78 00")
check("0xFA76C5 is `cp HL,0x0024`", hx(b(0xFA76C5, 4)), "db cf 24 00")
check("the routine is 36 bytes (0xFA76B2..0xFA76D5)", 0xFA76D6 - 0xFA76B2, 36)
check("no third comparison: `cf` appears exactly twice in the body",
      b(0xFA76B2, 36).count(b"\xcf"), 2)

# ---- 1b. every caller of the clamp is on the 0x0100/0x0140 path
# `calr` is a 1-byte relative displacement (opcode 0x10 = calr in this image's spelling is
# emitted as `1x` by llvm-mc); find the callers by scanning for both call forms instead of
# trusting the header, then check where each one lands.
CALLERS = {0xFA7784: "sub_FA76D6 -- builds voice[+0x3F]/[+0x41]",
           0xFA77E9: "sub_FA778E -- builds voice[+0x3F]/[+0x41]",
           0xFA90D9: "Voice_StagePair_Reg0100_0140_First",
           0xFA915E: "Voice_StagePair_Reg0100_0140_Both",
           0xFA9261: "Voice_StagePair_Reg0100_0140_AB (word 4)",
           0xFA9277: "Voice_StagePair_Reg0100_0140_AB (word 5)",
           0xFA936B: "Voice_StagePair_Reg0100_0140_CD (word 4)",
           0xFA9381: "Voice_StagePair_Reg0100_0140_CD (word 5)"}
def callers_of(target):
    """Every site in the image that transfers to `target` by any of the three call forms:
    0x1D `call addr24` (absolute), 0x1E `calr d16`, 0x1F `calr d24`."""
    out = []
    for o in range(0, len(ROMB) - 4):
        a = BASE + o
        if ROMB[o] == 0x1D:
            if int.from_bytes(ROMB[o + 1:o + 4], "little") == (target & 0xFFFFFF):
                out.append(a)
        elif ROMB[o] == 0x1E:
            if a + 3 + int.from_bytes(ROMB[o + 1:o + 3], "little", signed=True) == target:
                out.append(a)
        elif ROMB[o] == 0x1F:
            if a + 4 + int.from_bytes(ROMB[o + 1:o + 4], "little", signed=True) == target:
                out.append(a)
    return out


found = callers_of(0xFA76B2)
check("the clamp has exactly eight callers, scanning the WHOLE image for all three call "
      "forms", len(found), 8)
check("and they are the eight expected sites, all on the 0x0100/0x0140 path",
      ["0x%06X" % a for a in found], ["0x%06X" % a for a in sorted(CALLERS)])
check("Voice_StagePair_Reg0100_0140_First has exactly two callers, 0xFA91EF and 0xFA92F9",
      ["0x%06X" % a for a in callers_of(0xFA9081)], ["0xFA91EF", "0xFA92F9"])
check("Voice_StagePair_Reg0100_0140_Both has exactly two, 0xFA91F5 and 0xFA92FF",
      ["0x%06X" % a for a in callers_of(0xFA9105)], ["0xFA91F5", "0xFA92FF"])
check("Word_AddTickLow3 has exactly one, 0xFB2EF5 in VoiceRegs_Stage_D",
      ["0x%06X" % a for a in callers_of(0xFC369F)], ["0xFB2EF5"])
check("Rand_FromTickSquared has exactly three, and they are the three the header names",
      ["0x%06X" % a for a in callers_of(0xFA7F04)], ["0xFA8006", "0xFA978C", "0xFA9EDC"])

# ---------------------------------------------------------------- 2. the pair
print("\n2. every stager writes BOTH words 4 and 5, and only those")
# struct 0x00D75E: word 4 = +0x08 -> register 0x0100, word 5 = +0x0A -> register 0x0140
check("First: 0xFA9088 `lda XIX,0x00d75e`", hx(b(0xFA9088, 5)), "f2 5e d7 00 34")
check("First: 0xFA90E9 `ld (XIX+0x08),BC`", hx(b(0xFA90E9, 3)), "bc 08 51")
check("First: 0xFA90F4 `ld (XIX+0x08),BC`", hx(b(0xFA90F4, 3)), "bc 08 51")
check("First: 0xFA90FC `ld (XIX+0x0a),BC`", hx(b(0xFA90FC, 3)), "bc 0a 51")
check("Both:  0xFA910C `lda XIX,0x00d75e`", hx(b(0xFA910C, 5)), "f2 5e d7 00 34")
check("Both:  0xFA9174 word 4", hx(b(0xFA9174, 3)), "bc 08 51")
check("Both:  0xFA9181 word 5", hx(b(0xFA9181, 3)), "bc 0a 51")
check("Both:  0xFA918C word 4 (verbatim arm)", hx(b(0xFA918C, 3)), "bc 08 51")
check("Both:  0xFA9192 word 5 (verbatim arm)", hx(b(0xFA9192, 3)), "bc 0a 51")
check("AB:    0xFA9271 `ld (0x00d766),BC`", hx(b(0xFA9271, 5)), "f2 66 d7 00 51")
check("AB:    0xFA9285 `ld (0x00d768),BC`", hx(b(0xFA9285, 5)), "f2 68 d7 00 51")
check("AB:    0xFA9292 `ld (0x00d766),BC` (verbatim arm)", hx(b(0xFA9292, 5)),
      "f2 66 d7 00 51")
check("AB:    0xFA929A `ld (0x00d768),BC` (verbatim arm)", hx(b(0xFA929A, 5)),
      "f2 68 d7 00 51")
check("CD:    0xFA937B word 4", hx(b(0xFA937B, 5)), "f2 66 d7 00 51")
check("CD:    0xFA938F word 5", hx(b(0xFA938F, 5)), "f2 68 d7 00 51")
check("CD:    0xFA939C word 4 (verbatim arm)", hx(b(0xFA939C, 5)), "f2 66 d7 00 51")
# THE LAST ELEMENT of the list of stores, deliberately:
check("CD:    0xFA93A4 word 5 (verbatim arm) -- LAST store of the family",
      hx(b(0xFA93A4, 5)), "f2 68 d7 00 51")
# and no OTHER staging word is touched by these four routines
others = [0x00D75E + 2 * w for w in range(22) if w not in (0, 4, 5)]
pats = [bytes([0xF2, a & 0xFF, (a >> 8) & 0xFF, 0x00]) for a in others]
body = b(0xFA9081, 0xFA93AF - 0xFA9081)
check("no reference to staging words 1,2,3,6..21 anywhere in 0xFA9081..0xFA93AE",
      sum(body.count(p) for p in pats), 0)
# word 0's ADDRESS is the struct base; it appears twice and both are `lda`, not a store
base_pat = bytes([0xF2, 0x5E, 0xD7, 0x00])
occ = [i for i in range(len(body)) if body[i:i + 4] == base_pat]
check("the struct base 0x00D75E appears exactly twice", len(occ), 2)
check("and both are `lda Xxx` (opcode byte 0x34), not a store",
      sorted({body[i + 4] for i in occ}), [0x34])

# ---------------------------------------------------------------- 3. the split
print("\n3. the field split: 0xFF80 through, 0x7F clamped, +/- one part byte")
check("First: 0xFA909C `and BC,0x0040` (offset enable)", hx(b(0xFA909C, 4)), "d9 cc 40 00")
check("First: 0xFA90A4 `and BC,0x0080` (sign select)", hx(b(0xFA90A4, 4)), "d9 cc 80 00")
check("First: 0xFA90E3 `and BC,0xFF80` (keep bits 15..7)", hx(b(0xFA90E3, 4)),
      "d9 cc 80 ff")
check("Both:  0xFA916F saves the clamped value in (XIZ+0xfc)", hx(b(0xFA916F, 3)),
      "be fc 50")
check("Both:  0xFA917E `or BC,(XIZ+0xfc)` puts the SAME value in word 5",
      hx(b(0xFA917E, 3)), "9e fc e1")
check("AB arm 3 gates on `and WA,0x0200`", hx(b(0xFA91E8, 4)), "d8 cc 00 02")

# ---------------------------------------------------------------- 4. the twins
print("\n4. AB and CD are twins; the one semantic difference is the tone-record field")
A, B = b(0xFA919B, 266), b(0xFA92A5, 266)
diff = [i for i in range(266) if A[i] != B[i]]
check("both routines are 266 bytes", (0xFA92A5 - 0xFA919B, 0xFA93AF - 0xFA92A5), (266, 266))
check("23 bytes differ", len(diff), 23)
check("the first differing byte is +0x010", diff[0], 0x010)
check("AB dispatches on tone[+0x36]: 0xFA91AA = `ld A,(XBC+0x36)`", hx(b(0xFA91AA, 3)),
      "89 36 21")
check("CD dispatches on tone[+0x11]: 0xFA92B4 = `ld A,(XBC+0x11)`", hx(b(0xFA92B4, 3)),
      "89 11 21")
# every other differing byte is inside the jump table or a calr/jrl displacement
TABLE = (0x02B, 0x043)          # the 6 x u32 computed-goto table, +0x02B..+0x042
reloc = [i for i in diff if i != 0x010]
outside = [i for i in reloc if not (TABLE[0] <= i < TABLE[1])]
check("22 of the 23 are relocation", len(reloc), 22)
check("12 of them are inside the 6 x u32 computed-goto table (+0x02B..+0x042)",
      len(reloc) - len(outside), 12)
check("+0x023,+0x024 are the table's own base in `add XWA,0x00fa91c6`",
      outside[:2], [0x023, 0x024])
check("the remaining 8 are the displacement bytes of four calr/jrl",
      outside[2:], [0x055, 0x056, 0x05B, 0x05C, 0x0C7, 0x0C8, 0x0DD, 0x0DE])
print(f"       (the differing positions: {', '.join('+0x%03X' % i for i in diff)})")

# ---------------------------------------------------------------- 5. the sibling
print("\n5. the KN5000 sub-CPU counterparts -- SAME ALGORITHM, DIFFERENT BYTES")
if not os.path.exists(SIB_BIN):
    print(f"  [skip] {SIB_BIN} absent.  Regenerate with:")
    print(f"         llvm-objcopy -O binary {SIB_ELF} {SIB_BIN}")
else:
    SIB = open(SIB_BIN, "rb").read()

    def k(addr, n):
        return SIB[addr - SIB_BASE:addr - SIB_BASE + n]

    for name, wa, wn, ka, kn_ in [
            ("Clamp_36_to_120 / TVF_Clamp_Cutoff", 0xFA76B2, 36, 0x022BF2, 20),
            ("..._First / TVF_Emit_Offset_Reg100", 0xFA9081, 132, 0x024366, 102),
            ("..._Both  / TVF_Emit_Offset_Both", 0xFA9105, 150, 0x0243CC, 120)]:
        x, y = b(wa, wn), k(ka, kn_)
        n = min(wn, kn_)
        d = sum(1 for i in range(n) if x[i] != y[i])
        print(f"  [--] {name}: {d} of the {n} shared bytes differ "
              f"(WSA1 {wn} B at 0x{wa:06X}, KN5000 {kn_} B at 0x{ka:06X})")
        if d == 0:
            FAIL.append(f"{name} unexpectedly byte-identical -- rewrite the caveat")
    # the ONE immediate the two clamps share
    check("both clamps carry the upper bound 0x78 as an immediate",
          (b(0xFA76BA + 2, 2), k(0x022BF2 + 2, 2)), (b"\x78\x00", b"\x78\x00"))
    # and the sibling's emitter really does store to its TG registers 0x100 / 0x140
    check("KN5000 TVF_Emit_Offset_Reg100 stores to 0x0451D4 (its TG reg 0x100)",
          k(0x024366, 102).count(bytes.fromhex("d4 51 04")) > 0, True)
    check("KN5000 TVF_Emit_Offset_Reg100 stores to 0x0451D6 (its TG reg 0x140)",
          k(0x024366, 102).count(bytes.fromhex("d6 51 04")) > 0, True)

    # ---- 5b. the two staging blocks carry THE SAME 22 REGISTER NUMBERS IN THE SAME ORDER
    import re as _re
    sib_src = ("/home/fsanches/compartilhado/kn5000-roms-disasm/v142/subcpu/"
               "kn5000_subprogram_v142.s")
    pat = _re.compile(r"^;\s+0x0451([0-9A-F]{2}) -> \+0x([0-9A-F]{3})")
    sib = [(int(m.group(1), 16), int(m.group(2), 16))
           for m in (pat.match(l) for l in open(sib_src, encoding="utf-8")) if m]
    sib = sib[:22]                                  # the per-voice block; the tail is separate
    check("the sibling's block is 22 words at 0x0451CC..0x0451F6",
          (len(sib), sib[0][0], sib[-1][0]), (22, 0xCC, 0xF6))
    check("its words are consecutive u16", [a for a, _ in sib],
          list(range(0xCC, 0xCC + 44, 2)))
    ours = [fs_block(w) for w in range(22)]
    check("SAME 22 REGISTER NUMBERS IN THE SAME ORDER as this image's staging struct",
          [r for _, r in sib], ours)

# ---------------------------------------------------------------- 6. register 0x0500
print("\n6. register 0x0500 + chan is a BYTE PAIR whose high byte is a detune-curve lookup")
check("0xFA961F is `calr 0xFA7602` (DetuneCurve_LookupSigned)", hx(b(0xFA961F, 3)),
      "1e e0 df")
check("0xFA9676 is `calr 0xFA7602` too", hx(b(0xFA9676, 3)), "1e 89 df")
check("0xFA96AB `sll 0x08,WA` then 0xFA96B0 `ld (0x00d774),WA` -- the pack and the store",
      (hx(b(0xFA96AB, 3)), hx(b(0xFA96B0, 5))), ("d8 ee 08", "f2 74 d7 00 50"))
check("0xFA96D4 `or (0x00d774),BC` is the read-modify-write the shipped census misses",
      hx(b(0xFA96D4, 5)), "d2 74 d7 00 e9")
check("0xFA960D hands the low byte to sub_FC810C, the 0x00E1DD cache writer",
      hx(b(0xFA960D, 4)), "1d 0c 81 fc")
check("sub_FC810C really writes 0x00E1DD + voice[0]: `add XWA,0x0000e1dd` at 0xFC811B",
      hx(b(0xFC811B, 6)), "e8 c8 dd e1 00 00")
check("and sub_FC7FCA ORs that byte back into struct +0x16 at 0xFC80D6",
      hx(b(0xFC80D6, 3)), "99 16 e8")

# ---------------------------------------------------------------- selftest
if "--selftest" in sys.argv:
    print("\nNEGATIVE CONTROLS (each must FAIL to prove the checks can fail)")
    n0 = len(FAIL)
    check("[control] 0xFA76BA is NOT `cp HL,0x0079`", hx(b(0xFA76BA, 4)), "db cf 79 00")
    check("[control] AB and CD do NOT differ in 24 bytes", len(diff), 24)
    check("[control] 0xFA90FC is not a word-4 store", hx(b(0xFA90FC, 3)), "bc 08 51")
    fired = len(FAIL) - n0
    print(f"  {fired} of 3 controls fired")
    if fired != 3:
        print("  SELFTEST BROKEN: a control did not fire")
        sys.exit(2)
    del FAIL[n0:]

print(f"\nFAILURES: {len(FAIL)}")
for f in FAIL:
    print("  -", f)
sys.exit(1 if FAIL else 0)
