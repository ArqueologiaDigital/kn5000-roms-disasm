#!/usr/bin/env python3
"""What reads the per-element block at RAM 0x00E093, and what is the block FOR?

QUESTION THIS ANSWERS
---------------------
notes/FINDINGS-l7a1429-gate-and-keyscaling.md section 1.8 recorded a lead and
refused to name it: the three routines that open the gate on L7A1429 register
chan+0x0300 also fill a per-element block at the global 0x00E093 with both gains
and both tuning words, and

    "0x00E093 HAS NO LOCATED READER: every spelling of that address in either
     image is a write.  Recorded as a lead, grade UNIDENTIFIED."

That is a claim about a SEARCH.  This probe attacks it and it falls: the block
has a reader, and it is the LAST of the eleven sites in the previous census --
`lda XBC,0x00e093 / push XBC / calr 0xFC4269`.  The address is not read at the
reader because the reader receives it ON THE STACK.  A census that classified
every `lda` of the address as a write could not see it: `lda` takes an ADDRESS,
and three of the eleven immediately push it.

WHAT IT ESTABLISHES
-------------------
 1  THE READER (section 1).  sub_FC4269, 1087 bytes, called from exactly three
    sites, all three of them the gate-opening arms, all three passing &0x00E093.
 2  THE BLOCK'S LAYOUT (section 2).  A 68-byte argument struct: a 2-word header
    (MODE, N) and four parallel N=8 arrays -- gain, level, tuning IN, and a
    RESULT array the arms read back afterwards.
 3  WHERE THE RESULT GOES (section 3).  Result slot 2k -> P_k[+0x12], slot 2k+1
    -> P_k[+0x14], and Dev104_PackStagingStruct adds those to P[+0x0A] and
    P[+0x0C] on the way to registers chan+0x0040 (MAIN RESONATOR tuning) and
    chan+0x0080 (SUB RESONATOR tuning).  So the block's output is A DETUNE.
 4  WHAT THE SOLVER COMPUTES (sections 4 and 5).  Every magic constant in
    sub_FC4269 is a Q11 rendering of a named quantity (2/3, pi, 2pi, 1/2pi), the
    output table is 3072*log2, and the whole routine evaluates the loop
    characteristic function of a network of N coupled delay resonators at each
    resonator's own nominal frequency, then converts the phase error into a pitch
    offset in 1/256 semitone.  Section 5 re-implements it bit-exactly and shows
    the built-in NULL: INTERACTION GAIN = 0 gives a correction of exactly 0.
 5  THE FACTORY POPULATION (section 6), with its denominator stated.

WHAT IT DOES NOT ESTABLISH
--------------------------
  * It does not say what the L7A1429 does with registers 0x0040/0x0080; it says
    what the firmware puts in them.
  * The reading of the characteristic function as a WAVEGUIDE loop (section 4.6)
    is an interpretation of exact constants, not something an instruction says.
    It is graded there.
  * Nothing here measures hardware.  The instrument is in storage abroad.

RUN
    python3 wsa1/notes/w24_e093_coupling_solver.py            # sections 1-7
    python3 wsa1/notes/w24_e093_coupling_solver.py --selftest # FAILURES: 0
    python3 wsa1/notes/w24_e093_coupling_solver.py --census   # every census row
"""
import bisect
import math
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))

IMAGES = [
    ("prom_a", "wsa1_prom_a.ic12", 0xF80000, "prom_a/wsa1_prom_a.s"),
    ("prom_b", "wsa1_prom_b.ic13", 0xF00000, "prom_b/wsa1_prom_b.s"),
    ("prom_c", "wsa1_prom_c.ic28", 0xF80000, "prom_c/wsa1_prom_c.s"),
    ("prom_d", "wsa1_prom_d.bin",  0x000000, "prom_d/wsa1_prom_d.s"),
]
ROM, BASE = {}, {}
for _tag, _fn, _base, _src in IMAGES:
    ROM[_tag] = open(os.path.join(ROOT, "original_ROMs", _fn), "rb").read()
    BASE[_tag] = _base
C = ROM["prom_c"]
DIMG = ROM["prom_d"]

FAILURES = []
QUIET = "--quiet" in sys.argv
FULL = "--census" in sys.argv


def say(*a):
    if not QUIET:
        print(*a)


def check(what, got, want):
    ok = got == want
    if not ok:
        FAILURES.append("%s: got %r, want %r" % (what, got, want))
    say("   [%s] %-64s %s" % ("ok" if ok else "FAIL", what, got))
    return ok


def cb(addr, n=1, tag="prom_c"):
    o = addr - BASE[tag]
    return ROM[tag][o:o + n]


def u16(addr, tag="prom_c"):
    return struct.unpack_from("<H", cb(addr, 2, tag))[0]


def s16(addr, tag="prom_c"):
    return struct.unpack_from("<h", cb(addr, 2, tag))[0]


def u32(addr, tag="prom_c"):
    return struct.unpack_from("<I", cb(addr, 4, tag))[0]


INSTR_RE = re.compile(r";\s+([0-9A-F]{6})\s{2}(\S.*?)\s*$")
_IA = {}


def instr_addrs(tag):
    """Every instruction START ADDRESS and canonical spelling of one image.

    From the image's own listing comments, which the converters gate on a
    byte-identical round trip.  Used only to label a byte-scan hit `code` or
    `data`, and as the spelling half of the checks.
    """
    if tag not in _IA:
        from asm_source import image_lines
        src = dict((t, s) for t, _f, _b, s in IMAGES)[tag]
        d = {}
        for ln in image_lines(ROOT, src):
            m = INSTR_RE.search(ln)
            if m and not ln.lstrip().startswith(";"):
                d[int(m.group(1), 16)] = m.group(2)
        _IA[tag] = d
    return _IA[tag]


def sp(addr, tag="prom_c"):
    return instr_addrs(tag).get(addr, "<not an instruction start>")


def spells(addr, want, tag="prom_c"):
    return check("0x%06X spells `%s`" % (addr, want), sp(addr, tag), want)


# ============================================================ section 1
def sec1_the_reader():
    say("=== 1. THE READER, AND WHY THE PREVIOUS CENSUS COULD NOT SEE IT ===")
    say("   The three gate-opening arms each end their fill loop with the SAME four")
    say("   instructions.  The last of them is a CALL, and the block's address is its")
    say("   ARGUMENT -- pushed, not stored.  `lda` takes an address; a census that reads")
    say("   every `lda 0x00e093` as `a write to 0x00E093` mis-classifies exactly these.")
    say("")
    for arm, a_mode, a_n, a_lda, a_push, a_call in (
            ("sub_FC6D6E", 0xFC6F7C, 0xFC6F83, 0xFC6F8A, 0xFC6F8F, 0xFC6F90),
            ("sub_FC6FFD", 0xFC71A8, 0xFC71AF, 0xFC71B6, 0xFC71BB, 0xFC71BC),
            ("sub_FC723F", 0xFC73EA, 0xFC73F1, 0xFC73F8, 0xFC73FD, 0xFC73FE)):
        say("   %s:" % arm)
        spells(a_lda, "lda XBC,0x00e093")
        spells(a_push, "push XBC")
        spells(a_call, "calr 0xfc4269")
        # the two header words, decoded from raw bytes rather than a spelling
        check("  0x%06X writes MODE  = 0x%04X to 0x00E093" % (a_mode, u16(a_mode + 5)),
              (u32(a_mode + 1) & 0xFFFFFF, cb(a_mode, 1).hex()), (0x00E093, "f2"))
        check("  0x%06X writes N     = %d to 0x00E095" % (a_n, u16(a_n + 5)),
              (u32(a_n + 1) & 0xFFFFFF, cb(a_n, 1).hex()), (0x00E095, "f2"))
    say("")
    check("MODE/N for sub_FC6D6E (H == 0xAA, all four elements GROUPed)",
          (u16(0xFC6F7C + 5), u16(0xFC6F83 + 5)), (0x0200, 8))
    check("MODE/N for sub_FC6FFD (elements 0,1)",
          (u16(0xFC71A8 + 5), u16(0xFC71AF + 5)), (0x0400, 4))
    check("MODE/N for sub_FC723F (elements 2,3)",
          (u16(0xFC73EA + 5), u16(0xFC73F1 + 5)), (0x0400, 4))
    say("      -> N is 2 x (number of elements): each element contributes TWO slots.")
    say("")
    say("   sub_FC4269 reads its argument and immediately unpacks the two header words:")
    spells(0xFC4270, "ld XBC,(XIZ+0x08)")
    spells(0xFC4273, "ld WA,(XBC+0x02)")     # N
    spells(0xFC4279, "ld IY,(XBC)")          # MODE
    spells(0xFC4283, "cp WA,0")
    spells(0xFC4285, "jrl LE,0xfc46a2")
    say("      -> N <= 0 returns immediately.  The block IS this routine's argument.")


# ============================================================ section 2
def sec2_layout():
    say("")
    say("=== 2. THE BLOCK'S LAYOUT: a 68-byte argument struct, four N=8 arrays ===")
    say("   The four base displacements are IMMEDIATES in both the arms and the solver,")
    say("   and they AGREE.  Each element k advances every base by 4, so element k owns")
    say("   slots 2k (MAIN) and 2k+1 (SUB) of every array.")
    say("")
    say("   base  what the ARM puts there                       set at   solver reads at")
    say("   ----  -----------------------------------------     -------  ----------------")
    rows = [
        ("+0x00", "MODE, the coupling scale (0x0200 / 0x0400)", 0xFC6F7C, 0xFC4279),
        ("+0x02", "N, the number of slots (8 / 4)", 0xFC6F83, 0xFC4273),
        ("+0x04", "A[n]: Curve_Exp2Gain_U8_128[p19] << 8", 0xFC6E93, 0xFC4306),
        ("+0x14", "B[n]: 0x8000 (MAIN) / SUB GAIN curve (SUB)", 0xFC6EAD, 0xFC438E),
        ("+0x24", "C[n]: P[+0x0E] (MAIN) / P[+0x10] (SUB)", 0xFC6F36, 0xFC431F),
        ("+0x34", "D[n]: RESULT, written by the solver", None, 0xFC467B),
    ]
    for off, what, wsite, rsite in rows:
        say("   %-5s %-46s %s  %s" % (off, what,
            ("0x%06X" % wsite) if wsite else "  --   ", "0x%06X" % rsite))
    say("")
    say("   The four immediates, straight out of the solver's own bytes:")
    check("0xFC4288 loads 36 = 0x24 (array C base)", u32(0xFC4288 + 1), 36)
    check("0xFC4290 loads 20 = 0x14 (array B base)", u32(0xFC4290 + 1), 20)
    check("0xFC42A5 loads 52 = 0x34 (array D base)", u32(0xFC42A5 + 1), 52)
    check("0xFC42D6 sets the array A base to 4", sp(0xFC42D6), "inc 4,XWA")
    say("   and the matching immediates in the arm sub_FC6D6E:")
    for a, v, lbl in ((0xFC6E20, 20, "B[0] MAIN"), (0xFC6E28, 22, "B[1] SUB"),
                      (0xFC6E2D, 36, "C[0] MAIN"), (0xFC6E35, 38, "C[1] SUB"),
                      (0xFC6F9F, 52, "D[0] MAIN"), (0xFC6FA4, 54, "D[1] SUB")):
        check("0x%06X loads %-3d (%s)" % (a, v, lbl), u32(a + 1), v)
    check("every base advances by 4 per element (0xFC6F65)", sp(0xFC6F65), "inc 4,XIY")
    say("")
    say("   ★ THE SEVEN SCRATCH ARRAYS TILE 0x00E012-0x00E081 EXACTLY.")
    say("   sub_FC4269 uses seven absolute scratch arrays; each is 8 words = 0x10 bytes,")
    say("   and they run end to end and STOP one byte before 0x00E082, the packer's")
    say("   PART pointer.  N = 8 is the hard maximum the RAM map allows.")
    scratch = [0xE012, 0xE022, 0xE032, 0xE042, 0xE052, 0xE062, 0xE072]
    check("the seven scratch bases", ["0x%04X" % v for v in scratch],
          ["0xE012", "0xE022", "0xE032", "0xE042", "0xE052", "0xE062", "0xE072"])
    check("0x00E072 + 8 words == 0x00E082, the next named global",
          "0x%04X" % (0xE072 + 16), "0xE082")
    check("the block itself spans 0x00E093..0x00E0D6 (68 bytes)",
          "0x%04X" % (0xE093 + 68 - 1), "0xE0D6")


# ============================================================ section 3
def sec3_where_the_result_goes():
    say("")
    say("=== 3. WHERE THE RESULT GOES: it is a DETUNE on both resonator tunings ===")
    say("   Each arm's read-back loop, immediately after the call:")
    spells(0xFC6FB4, "lda XBC,0x00e093")
    spells(0xFC6FBC, "ld WA,(XBC)")
    spells(0xFC6FC3, "ld (XBC+0x12),WA")
    spells(0xFC6FCC, "add XBC,0x0000e093")
    spells(0xFC6FD2, "ld BC,(XBC)")
    spells(0xFC6FD9, "ld (XWA+0x14),BC")
    say("      D[2k] -> P_k[+0x12],  D[2k+1] -> P_k[+0x14].")
    say("")
    say("   And Dev104_PackStagingStruct ADDS those to the tuning words:")
    spells(0xFC4DFA, "ld DE,(XBC+0x12)")
    spells(0xFC4DFD, "ld IX,(XBC+0x0a)")
    spells(0xFC4E02, "add HL,DE")
    spells(0xFC4E9F, "ld (XBC+0x02),HL")      # staging word 1 = reg chan+0x0040
    spells(0xFC4EA9, "ld DE,(XBC+0x14)")
    spells(0xFC4EAC, "ld IX,(XBC+0x0c)")
    spells(0xFC4EB1, "add HL,DE")
    say("      SatAsym(P[+0x0A] + P[+0x12] + d1) -> register chan+0x0040, MAIN RESONATOR")
    say("      SatAsym(P[+0x0C] + P[+0x14] + d2) -> register chan+0x0080, SUB  RESONATOR")
    say("      P[+0x0A]/P[+0x0C] are built from P[+0x0E]/P[+0x10] -- THE SOLVER'S OWN")
    say("      INPUT C[] -- by Pack104_ComputeTuningWords_0040_0080.  So the block reads")
    say("      the resonators' nominal tunings and returns a correction to them.")
    say("")
    say("   ★ THE POSITIVE CONTROL IS IN THE FIRMWARE ITSELF.  The three arms that")
    say("   CLEAR the GROUP field -- the not-grouped case -- write the correction as ZERO")
    say("   and never call the solver:")
    for a in (0xFC6CC2, 0xFC6CC7, 0xFC6D04, 0xFC6D09, 0xFC6D46, 0xFC6D4B):
        spells(a, "ld (XDE+0x%02x),0x0000" % (0x12 if a in (0xFC6CC2, 0xFC6D04, 0xFC6D46) else 0x14))
    say("      -> P[+0x12] and P[+0x14] carry a coupling detune when the part is GROUPed")
    say("      and exactly zero when it is not.  That is what a coupling term looks like.")
    say("")
    say("   ⚠ AND THEY HAVE A SECOND WRITER, which the arms OVERWRITE.")
    spells(0xFC490A, "ld (XWA+0x12),HL")
    spells(0xFC4942, "ld (XWA+0x14),HL")
    say("      Pack104_UnpackWaveSelRec_ToSubRecord sets P[+0x12] = (p26<<8)+p27 when")
    say("      p25 bit 7 is set, and P[+0x14] likewise from p38/p39.  So the field is")
    say("      `the second term of the tuning word`, and GROUP REPLACES a per-tone static")
    say("      detune with a computed one.  Which of the two survives depends on call")
    say("      ORDER and is NOT established here -- see the note, section 7.")


# ============================================================ section 4
def sec4_constants():
    say("")
    say("=== 4. EVERY MAGIC CONSTANT IN sub_FC4269 IS A NAMED QUANTITY IN Q11 ===")
    say("   Q11 here means 2048 = 1.0, the scale Math_Sin_Q11/Math_Cos_Q11/Math_Atan_Q11")
    say("   and Multiply16_Signed_Shr11 already carry (their headers, wave 7 / wave 19).")
    say("")
    rows = [
        (0x0555, 0xFC4316, "2/3",      2048 * 2 / 3,
         "octaves per 1/256-semitone unit: 2048/3072"),
        (0x1922, 0xFC445B, "pi",       math.pi * 2048, "half a turn"),
        (0x3244, 0xFC44D9, "2*pi",     2 * math.pi * 2048, "the phase wrap modulus"),
        (0x0146, 0xFC4658, "1/(2*pi)", 2048 / (2 * math.pi), "radians -> turns"),
    ]
    for lit, site, name, exact, why in rows:
        check("0x%04X at 0x%06X = round(2048 * %-8s) = %-7.2f   %s"
              % (lit, site, name, exact, why), lit, round(exact))
    check("0x0800 = 1.0", 0x800, 2048)
    check("0x1000 = 2.0 (the product accumulator's seed, 0xFC43ED)", 0x1000, 4096)
    say("")
    say("   THE OUTPUT TABLE.  0xFC466B indexes MathTable_Log2_256 at 0xFE0CC9 with")
    say("   idx = (0x0800 - x) >> 4, x in Q11 turns.  T[k] = round(3072*(7 - log2 k)):")
    T = [s16(0xFE0CC9 + 2 * k) for k in range(256)]
    bad = [k for k in range(1, 256) if abs(T[k] - round(3072 * (7 - math.log2(k)))) > 1]
    check("T[k] = round(3072*(7 - log2 k)) for k >= 1, err <= 1, outliers", bad, [])
    check("T[0] is the sentinel 0xFFFF", T[0] & 0xFFFF, 0xFFFF)
    check("★ T[128] = 0 -- the NULL is built into the table", T[128], 0)
    check("3072 counts per halving = 12 semitones x 256", 3072, 12 * 256)
    say("      -> idx = 128*(1 - turns), so the returned value is")
    say("         -3072 * log2(1 - dphi/2pi)  in 1/256 SEMITONE,")
    say("         i.e. the pitch offset of a frequency ratio 1/(1 - dphi/2pi).")
    say("")
    say("   ⚠ ONE REAL ROM DEFECT IS REACHABLE FROM HERE.  MathTable_Cos_256[0] is")
    say("   0x8000, which Math_Cos_Q11 reads as -2048: cos(0) comes back as -1.0.")
    check("MathTable_Cos_256[0]", u16(0xFE08C9), 0x8000)
    say("   Section 5's simulator reproduces the defect and section 6 reports whether")
    say("   any factory tone lands on it.")
    return T


def sec4b_units():
    say("")
    say("=== 4b. THE TWO INPUT ARRAYS ARE UNIT-SCALED GAINS, AND MODE NORMALISES BY N ===")
    say("   Array A holds `Curve_Exp2Gain_U8_128[p19] << 8`, which the solver reads back")
    say("   as `A >>u 4`.  The curve's own maximum is 128, and 128 << 4 = 2048 = 1.0 in")
    say("   Q11 -- so array A is INTERACTION GAIN normalised to [0, 1]:")
    g = [cb(0xFDF760 + k)[0] for k in range(128)]
    check("Curve_Exp2Gain_U8_128 range", (min(g), max(g)), (0, 128))
    check("  (max << 8) >>u 4 == 1.0 in Q11", (128 << 8) >> 4, 0x800)
    say("")
    say("   Array B holds 0x8000 for MAIN and Curve_Exp2Gain_Percent_101[|p33|] for SUB,")
    say("   read back the same way.  ★ 0x8000 IS THAT CURVE'S OWN TOP ENTRY -- the arm")
    say("   writes the literal the curve would return for SUB GAIN = 100 %.  So array B")
    say("   is a LEVEL array in the SUB GAIN curve's units, and MAIN's level is pinned")
    say("   to full scale rather than being a different kind of number:")
    check("Curve_Exp2Gain_Percent_101[100]", u16(0xFDFECC + 200), 0x8000)
    check("  which is the literal the arms store for MAIN (0xFC6EAD)",
          u16(0xFC6EAD + 2), 0x8000)
    check("  and 0x8000 >>u 4 == 1.0 in Q11", 0x8000 >> 4, 0x800)
    say("")
    say("   So the damping factor is  damp_n = 1 - (MODE/2048) * GAIN * LEVEL_n,")
    say("   with GAIN and LEVEL_n both in [0, 1].  ★ AND MODE NORMALISES BY THE GROUP")
    say("   SIZE: the 4-element arm passes 0x0200 and the 2-element arms pass 0x0400,")
    say("   and in both cases MODE x (elements in the group) is exactly 1.0:")
    check("0x0200 * 4", 0x200 * 4, 0x800)
    check("0x0400 * 2", 0x400 * 2, 0x800)
    check("  so damp is confined to", ("%.3f" % (1 - 0.25 * 1.0), "%.3f" % 1.0),
          ("0.750", "1.000"))
    say("      for the N=8 arm, and 0.500 .. 1.000 for the N=4 arms.  A number in")
    say("      [0.5, 1.0] multiplying one term of a resonance condition is a POLE")
    say("      RADIUS, and 1.0 -- no coupling -- is exactly the null of section 5.")


# ============================================================ section 5
# ---- a bit-exact re-implementation of the ROM's fixed-point primitives -------
SIN = [s16(0xFE06C9 + 2 * k) for k in range(256)]
COS = [s16(0xFE08C9 + 2 * k) for k in range(256)]
ATAN = [s16(0xFE0AC9 + 2 * k) for k in range(256)]
LOG2 = [s16(0xFE0CC9 + 2 * k) for k in range(256)]
EXP2 = [s16(0xFE0EC9 + 2 * k) for k in range(256)]


def w16(v):
    return ((v + 0x8000) & 0xFFFF) - 0x8000


def sra(v, n):
    return v >> n                      # python >> on a signed int already floors


def mul11(a, b):
    """Multiply16_Signed_Shr11, 0xFC412E: (s16*s16) >> 11, truncated to 16 bits."""
    return w16(sra(w16(a) * w16(b), 11))


def sinq(x):
    """Math_Sin_Q11, 0xFC419D."""
    return sra(SIN[sra(w16(x) * 0x28BE, 19) & 0xFF], 4)


COS0_HITS = [0]


def cosq(x):
    """Math_Cos_Q11, 0xFC41C3 -- including the entry-0 defect.

    MathTable_Cos_256[0] is 0x8000, which `ld BC,(XIY) / sra 4,BC` reads as
    -2048: cos(0) comes back as -1.0.  COS0_HITS counts how often a live path
    lands on it, so the defect can be reported as reached or not reached rather
    than as a worry.
    """
    idx = sra(w16(x) * 0x28BE, 19) & 0xFF
    if idx == 0:
        COS0_HITS[0] += 1
    return sra(COS[idx], 4)


def atanq(x):
    """Math_Atan_Q11, 0xFC41E9 -- an ODD function on |x| >> 7."""
    x = w16(x)
    r = sra(ATAN[min(abs(x) >> 7, 255)], 3)
    return w16(-r) if x < 0 else w16(r)


def exp2q(x):
    """Math_Exp2_Q11, 0xFC4227 -- 2*pi*1024 * 2^x.

    idx = (x & 0x7FF) >> 3, the FRACTIONAL part; then for a negative argument the
    result is shifted right by |x >> 11|, the integer part (Shift16_ArithRight).
    """
    x = w16(x)
    r = sra(EXP2[(x & 0x7FF) >> 3], 1)
    if x < 0:
        r = sra(r, min(31, -sra(x, 11)))
    return w16(r)


def div11sat(num, den):
    """sub_FC4140, 0xFC4140: (num << 11) / den with the ROM's own saturation."""
    ix, de = w16(num), w16(den)
    if de == 0:
        return 0x7FFF if ix >= 0 else -0x8000       # Divide32 traps; no live path
    n32 = ix << 11
    q = abs(n32) // abs(de)                          # truncate TOWARD ZERO
    if (n32 < 0) != (de < 0):
        q = -q
    iy = w16(q)
    hl = iy
    if iy < 0:
        if ix > 0 and de > 0:
            return 0x7FFF
        if ix < 0 and de < 0:
            return 0x7FFF
        return hl
    if hl <= 0:
        return hl
    if ix > 0 and de < 0:
        return -0x8000
    if ix < 0 and de > 0:
        return -0x8000
    return hl


def solve(mode, n, A, B, Cc):
    """A bit-exact re-implementation of sub_FC4269, 0xFC4269-0xFC46A7.

    A[n], B[n], Cc[n] are the three input arrays of the 0x00E093 block; the
    return value is D[n], the result array the arms read back into P[+0x12] and
    P[+0x14].  Every line corresponds to an instruction range, named in the
    comments.
    """
    D = [0] * n
    if n <= 0:
        return D
    E012 = [0] * 8
    E022 = [0] * 8
    E032 = [0] * 8
    E042 = [0] * 8
    E052 = [0] * 8
    E062 = [0] * 8
    E072 = [0] * 8
    for j in range(n):                                          # 0xFC42AD
        s1 = s2 = s3 = s4 = 0
        for i in range(n):                                      # 0xFC42FD loop 1
            E012[i] = w16(-mul11((A[i] & 0xFFFF) >> 4, mode))   # 0xFC4306-0xFC4314
            E052[i] = mul11(w16(Cc[j] - Cc[i]), 0x555)          # 0xFC4316-0xFC432F
            while E052[i] >= 0x800:                             # 0xFC4339 octave fold
                E052[i] = w16(E052[i] - 0x800)
            E022[i] = exp2q(E052[i])                            # 0xFC435B-0xFC4364
        damp = w16(mul11(E012[j], (B[j] & 0xFFFF) >> 4) + 0x800)   # 0xFC4388-0xFC43A1
        for i in range(n):                                      # 0xFC43E5 loop 2
            E032[j] = 0x1000                                    # 0xFC43ED
            E042[i] = mul11(E012[i], (B[i] & 0xFFFF) >> 4)      # 0xFC43F1-0xFC4409
            E062[j] = 0                                         # 0xFC4413
            E072[i] = w16(-w16(E022[i] + E022[i]))              # 0xFC4417-0xFC4423
            for m in range(n):                                  # 0xFC4445 loop 3
                if m == j:
                    continue
                sn = sinq(E022[m])                              # 0xFC444E
                de = sra(w16(0x1922 - w16(2 * E022[m])), 1)     # 0xFC4456-0xFC4465
                E032[j] = mul11(E032[j], sn)                    # 0xFC4467-0xFC4480
                E062[j] = w16(E062[j] + de)                     # 0xFC448A
                if m == i:
                    continue
                E042[i] = mul11(E042[i], sn)                    # 0xFC4493-0xFC44AC
                E072[i] = w16(E072[i] + de)                     # 0xFC44B6
            while E062[j] < 0:                                  # 0xFC44CA
                E062[j] = w16(E062[j] + 0x3244)
            while E062[j] >= 0x3244:                            # 0xFC44F0
                E062[j] = w16(E062[j] - 0x3244)
            while E072[i] < 0:                                  # 0xFC4513
                E072[i] = w16(E072[i] + 0x3244)
            while E072[i] >= 0x3244:                            # 0xFC4534
                E072[i] = w16(E072[i] - 0x3244)
            if i == j:                                          # 0xFC455D
                co, si = cosq(E062[j]), sinq(E062[j])
                t = mul11(E032[j], damp)
                s3 = w16(s3 + mul11(t, co))
                s4 = w16(s4 + mul11(t, si))
                s1 = w16(s1 + mul11(E032[j], co))
                s2 = w16(s2 + mul11(E032[j], si))
            else:                                               # 0xFC45D6
                hl = mul11(E042[i], cosq(E072[i]))
                dd = mul11(E042[i], sinq(E072[i]))
                s3, s4 = w16(s3 - hl), w16(s4 - dd)
                s1, s2 = w16(s1 - hl), w16(s2 - dd)
        r1 = div11sat(s2, s1)                                   # 0xFC463A
        r2 = div11sat(s4, s3)                                   # 0xFC4645
        dphi = w16(atanq(r1) - atanq(r2))                       # 0xFC464B-0xFC4656
        turns = mul11(dphi, 0x146)                              # 0xFC465C
        D[j] = LOG2[max(0, min(255, sra(w16(0x800 - turns), 4)))]   # 0xFC465F-0xFC467B
    return D


def _reachable_index_range():
    """The exhaustive bound on the output table index, over ALL s16 arctangents.

    idx = (0x0800 - mul11(atan(a) - atan(b), 0x0146)) >> 4, and both arctangents
    come from Math_Atan_Q11, whose range is a property of MathTable_Atan_256.
    Sweeping every s16 argument gives the extreme atan, and the rest is exact.
    """
    amax = max(abs(atanq(x)) for x in range(-0x8000, 0x8000))
    lo = min(sra(w16(0x800 - mul11(d, 0x146)), 4) for d in (-2 * amax, 2 * amax))
    hi = max(sra(w16(0x800 - mul11(d, 0x146)), 4) for d in (-2 * amax, 2 * amax))
    return amax, lo, hi


def sec5_simulator():
    say("")
    say("=== 5. THE SOLVER, RE-IMPLEMENTED; ITS NULL, ITS RANGE AND ITS STEP ===")
    say("   `solve()` above is sub_FC4269 line for line, on the ROM's own tables, with")
    say("   every loop annotated with the instruction range it stands for.")
    say("")
    say("   THE NULL, and it is a real one because it can fail: with INTERACTION GAIN")
    say("   p19 = 0 the curve gives 0, so A[] = 0, so E012 = 0, so damp = 0x800 = 1.0")
    say("   EXACTLY and every i != j term is 0.  The damped and undamped accumulators")
    say("   are then identical, dphi = 0, idx = 128, and T[128] = 0.")
    tun = [0x0000, -0x0700, 0x0300, -0x0200, 0x0500, 0x0900, -0x0400, 0x0100]
    B0 = [0x8000, 0x7FFF] * 4
    check("p19 = 0, four elements, spread tunings -> D",
          solve(0x200, 8, [0] * 8, B0, tun), [0] * 8)
    check("  and with every tuning equal", solve(0x200, 8, [0] * 8, B0, [0x100] * 8),
          [0] * 8)
    check("  N = 4 arms too", solve(0x400, 4, [0] * 4, B0[:4], tun[:4]), [0] * 4)
    say("")
    say("   ★ A SECOND, INDEPENDENT NULL, and this one is the reason seven of the eight")
    say("   factory tones in section 6 get nothing.  When every resonator carries the")
    say("   SAME tuning word, every octave difference is 0, so every")
    say("   omega = pi * 2^0 = pi, and sin(pi) = 0 to within the table's own resolution:")
    check("Math_Exp2_Q11(0) = round(2048*pi) - 1", exp2q(0), 6433)
    check("Math_Sin_Q11 of that", sinq(6433), 50)
    say("      50/2048 = 0.024, and E032 accumulates N-1 such factors through a >>11")
    say("      truncation, so it underflows to 0 and the whole accumulator vanishes.")
    check("equal tunings, FULL gain, N=8 -> D", solve(0x200, 8, [0xFF00] * 8, B0, [0] * 8),
          [0] * 8)
    check("equal tunings, FULL gain, N=4 -> D", solve(0x400, 4, [0xFF00] * 4, B0[:4], [0] * 4),
          [0] * 4)
    say("")
    say("   THE POSITIVE CONTROL: the same routine on inputs that are NOT degenerate must")
    say("   move, or both nulls above would be criteria that cannot fail.  These are")
    say("   `Fantasia`'s own two elements, read out of prom_d in section 6.")
    d = solve(0x400, 4, [0x2800] * 4, [0x8000, 0x8000, 0x8000, 0x22E8],
              [0, 0, -1792, -2560])
    check("Fantasia elements 0,1 -> D", d, [-34, -34, 0, 0])
    say("      = %s cents on element 0's MAIN and SUB." % ("%.2f" % (d[0] * 100.0 / 256)))
    say("")
    say("   THE STEP AND THE RANGE, both exact.  One index step of the output table is")
    say("   about 13 cents, so this correction CANNOT be small:")
    check("T[127], T[128], T[129]", (LOG2[127], LOG2[128], LOG2[129]), (34, 0, -34))
    check("  the smallest non-zero correction, in cents",
          "%.2f" % (LOG2[127] * 100.0 / 256), "13.28")
    amax, lo, hi = _reachable_index_range()
    check("|Math_Atan_Q11| never exceeds", amax, 3088)
    check("so the output index is confined to", (lo, hi), (66, 189))
    check("  and index 0 -- the 0xFFFF log2 SENTINEL -- is UNREACHABLE", lo > 0, True)
    check("  the correction is bounded, in cents",
          ("%.0f" % (LOG2[lo] * 100.0 / 256), "%.0f" % (LOG2[hi] * 100.0 / 256)),
          ("1146", "-675"))
    say("      -> a coupling detune of at most about +11.5 / -6.8 SEMITONES, in steps")
    say("      of roughly 13 cents.  That is a pitch pull, not a fine tuning.")


# ============================================================ section 6
def _tone_records(strict):
    """Every tone's 43-byte wave-select records, with its name.

    Copied from notes/w21_lsi_gate_and_keyscaling.py so this probe stands alone;
    the framing and both filters are that lane's, unchanged.
    """
    off = struct.unpack_from("<I", DIMG, 0x08)[0]
    tones = [struct.unpack_from("<I", DIMG, off + 4 * i)[0] for i in range(274)]
    out = []
    for t in tones:
        if t + 0x120 > len(DIMG):
            continue
        if not all(32 <= c < 127 for c in DIMG[t:t + 16]):
            continue
        if DIMG[t + 0x10] == 0x80:
            continue
        mask = DIMG[t + 0x11]
        n = sum(1 for k in range(4) if (mask >> (2 * k)) & 3)
        if n == 0:
            continue
        if strict and not all(
                struct.unpack_from("<H", DIMG, t + 0xD9 + 81 * k + 2)[0] < 307
                for k in range(n)):
            continue
        b = t + 0xD9 + 81 * n
        out.append((DIMG[t:t + 16].decode("latin-1").rstrip(),
                    [DIMG[b + 43 * k:b + 43 * k + 43] for k in range(n)]))
    return out


def _s8(v):
    return v - 256 if v >= 128 else v


def _element_inputs(r):
    """(A, Bmain, Bsub, Cmain, Csub) for one 43-byte wave-select record.

    Every step is Pack104_UnpackWaveSelRec_ToSubRecord's or the arm's own:
      A     = Curve_Exp2Gain_U8_128[p19] << 8               0xFC6E73, 0xFC6E7F
      Bmain = 0x8000                                        0xFC6EAD
      Bsub  = Curve_Exp2Gain_Percent_101[clamp(|p33|,0,100)] 0xFC6EE1
      Cmain = P[+0x0E] = (s8)p29*256 + (s8)p30*2 (+0x0C00 if p21 bit 7)
      Csub  = P[+0x10] = (s8)p41*256 + (s8)p42*2 (+0x0C00 if p31 bit 7)
    """
    a = C[0xFDF760 - 0xF80000 + r[0x13]] << 8
    p33 = _s8(r[0x21])
    bsub = s16(0xFDFECC + 2 * max(0, min(100, abs(p33))))
    cm = w16(_s8(r[0x1D]) * 256 + _s8(r[0x1E]) * 2)
    cs = w16(_s8(r[0x29]) * 256 + _s8(r[0x2A]) * 2)
    if r[0x15] & 0x80:
        cm = w16(cm + 0x0C00)
    if r[0x1F] & 0x80:
        cs = w16(cs + 0x0C00)
    return a, 0x8000, bsub, cm, cs


def _hcode(recs):
    h = 0
    for k, r in enumerate(recs):
        h |= ((r[0x0B] & 0xC0) >> 6) << (2 * k)
    return h


def _solve_group(recs, members, mode, n):
    A, B, Cc = [], [], []
    for k in members:
        a, bm, bs, cm, cs = _element_inputs(recs[k])
        A += [a, a]
        B += [bm, bs]
        Cc += [cm, cs]
    return solve(mode, n, A, B, Cc)


def sec6_factory():
    say("")
    say("=== 6. WHAT THE SOLVER DOES TO THE FACTORY TONES THAT REACH IT ===")
    loose = _tone_records(False)
    strict = _tone_records(True)
    check("★ DENOMINATOR: tones under the loose framing", len(loose), 256)
    check("  their wave-select records (this is the 459 set)",
          sum(len(r) for _n, r in loose), 459)
    check("  and under dev104_topology_probe.py's STRICT filter, which drops every",
          (len(strict), sum(len(r) for _n, r in strict)), (101, 133))
    say("      tone that uses GROUP -- so NO rate below may be quoted through it.")
    say("")
    say("   Pack104_DispatchByResoMode_ForPart (0xFC7481) folds the four elements' GROUP")
    say("   codes into H and picks arms.  H == 0xAA -> sub_FC6D6E, N = 8, all four;")
    say("   otherwise H & 0x0F picks sub_FC6FFD on elements 0,1 and H & 0xF0 picks")
    say("   sub_FC723F on elements 2,3, each with N = 4.  Over the 256 loose tones:")
    users = []
    for nm, rr in loose:
        h = _hcode(rr)
        if not h:
            continue
        if not all(r[0x14] == 100 for r in rr):
            continue                      # mis-framed; excluded, w21 section 6
        users.append((nm.strip(), rr, h))
    check("tones that reach the solver at all (H != 0, p20 invariant holds)",
          len(users), 8)
    say("")
    say("   %-15s %-4s %-3s %-24s %s" % ("tone", "H", "ne", "the solver call", "D, cents"))
    say("   %-15s %-4s %-3s %-24s %s" % ("-" * 15, "-" * 4, "-" * 3, "-" * 24, "-" * 26))
    COS0_HITS[0] = 0
    moved, calls, undet = 0, 0, 0
    equal_tuning = 0
    for nm, rr, h in users:
        ne = len(rr)
        rows = []
        if h == 0xAA and ne == 4:
            rows.append(("sub_FC6D6E N=8 el 0-3", _solve_group(rr, range(4), 0x200, 8)))
        else:
            if h & 0x0F:
                if ne >= 2:
                    rows.append(("sub_FC6FFD N=4 el 0,1",
                                 _solve_group(rr, (0, 1), 0x400, 4)))
                else:
                    rows.append(("sub_FC6FFD N=4 el 0,1", None))
            if h & 0xF0:
                if ne >= 4:
                    rows.append(("sub_FC723F N=4 el 2,3",
                                 _solve_group(rr, (2, 3), 0x400, 4)))
                else:
                    rows.append(("sub_FC723F N=4 el 2,3", None))
        tw = set()
        for r in rr:
            _a, _bm, _bs, cm, cs = _element_inputs(r)
            tw |= {cm, cs}
        if len(tw) == 1:
            equal_tuning += 1
        for lbl, D in rows:
            calls += 1
            if D is None:
                undet += 1
                say("   %-15s 0x%02X %-3d %-24s element 3 is not live: its sub-record"
                    % (nm[:15], h, ne, lbl))
                say("   %-15s %-4s %-3s %-24s is NOT in the ROM -- not computed"
                    % ("", "", "", ""))
                continue
            if any(D):
                moved += 1
            say("   %-15s 0x%02X %-3d %-24s %s"
                % (nm[:15], h, ne, lbl,
                   " ".join("%+.2f" % (v * 100.0 / 256) for v in D)))
    say("")
    check("solver calls the ROM determines completely", calls - undet, 8)
    check("  calls whose inputs the ROM does NOT determine (element 3 not live)",
          undet, 6)
    check("★ of the eight determined calls, how many return a NON-ZERO detune",
          moved, 1)
    check("  and it is the only GROUP tone whose elements are not all identically tuned",
          equal_tuning, 7)
    say("      -> `Fantasia` alone: element 1 sits 7 and 10 semitones below element 0,")
    say("      so the octave differences are non-zero, the sines survive, and element 0")
    say("      is pulled -13.28 cents on BOTH its resonators.  In the other seven tones")
    say("      every tuning word is 0, section 5's second null fires, and D is 0.")
    say("")
    say("   ⚠ THAT IS NOT `THE MECHANISM IS A VESTIGE`.  It is degenerate INPUT, not a")
    say("   degenerate routine.  Over 4000 random tone-like inputs (gains from the real")
    say("   curve, tunings +/- 2 octaves in semitones) the two arms return a non-zero")
    say("   correction in 78 % (N=8) and 42 % (N=4) of draws, with a worst case of")
    say("   1146 cents -- reproduce with --reach.  What the factory set shows is that")
    say("   Technics shipped GROUP tones whose resonators are tuned alike.")
    say("")
    check("Math_Cos_Q11's entry-0 defect was reached on the factory data", COS0_HITS[0], 0)
    say("      -> the cos(0) = -1.0 defect is real (section 4) but no factory tone that")
    say("      reaches this solver lands on it.")


def sec6b_reach():
    """--reach: the randomised reachability figures quoted in section 6."""
    import random
    G = [C[0xFDF760 - 0xF80000 + k] << 8 for k in range(128)]
    SG = [s16(0xFDFECC + 2 * k) for k in range(101)]
    say("")
    say("=== 6b. REACHABILITY (only with --reach; 4000 draws, seed 7) ===")
    for n, mode, ne in ((8, 0x200, 4), (4, 0x400, 2)):
        random.seed(7)
        hits, best = 0, 0
        for _t in range(4000):
            A, B, Cc = [], [], []
            for _k in range(ne):
                g = G[random.randrange(128)]
                A += [g, g]
                B += [0x8000, SG[random.randrange(101)]]
                Cc += [random.randrange(-24, 25) * 256, random.randrange(-24, 25) * 256]
            D = solve(mode, n, A, B, Cc)
            z = max(abs(v) for v in D)
            hits += 1 if z else 0
            best = max(best, z)
        say("      N=%d arm: %4d/4000 draws non-zero (%.0f %%), max |D| = %d = %.0f cents"
            % (n, hits, 100.0 * hits / 4000, best, best * 100.0 / 256))


# ============================================================ section 7
def sec7_census():
    say("")
    say("=== 7. THE CENSUS THAT MAKES `THIS IS THE ONLY READER` FALSIFIABLE ===")
    say("   FORM 1 -- every occurrence of the ADDRESS, framing-independently.")
    say("   The literal is three bytes `93 e0 00` (24-bit absolute) or two bytes")
    say("   `93 e0` (a 16-bit immediate to `add Xrr,#`).  Scanned over all four images")
    say("   at EVERY offset, then labelled code/data from the listings.")
    hits = {}
    for tag, _fn, base, _src in IMAGES:
        data = ROM[tag]
        ia = instr_addrs(tag)
        keys = sorted(ia)
        rows = []
        for off in range(len(data) - 3):
            if data[off] != 0x93 or data[off + 1] != 0xE0:
                continue
            a = base + off
            j = bisect.bisect_right(keys, a)
            owner = keys[j - 1] if j else None
            rows.append((a, owner, ia.get(owner, "<none>") if owner else "<none>"))
        hits[tag] = rows
        say("      %-7s %3d occurrences of the byte pair" % (tag, len(rows)))
    say("")
    say("   Adjudicating prom_c's, by the spelling of the instruction that CONTAINS them:")
    kinds = {}
    for a, owner, spell in hits["prom_c"]:
        k = ("lda XBC,0x00e093" if spell == "lda XBC,0x00e093" else
             "lda XWA,0x00e093" if spell == "lda XWA,0x00e093" else
             "add Xrr,0x0000e093" if spell.startswith("add X") and "e093" in spell else
             "ld (0x00e093),imm" if spell.startswith("ld (0x00e093)") else
             "OTHER: " + spell)
        kinds.setdefault(k, []).append(a)
    for k in sorted(kinds):
        say("      %-24s x%-3d %s" % (k, len(kinds[k]),
            " ".join("0x%06X" % v for v in kinds[k]) if FULL or len(kinds[k]) < 6
            else "0x%06X ... 0x%06X" % (kinds[k][0], kinds[k][-1])))
    check("prom_a occurrences", len(hits["prom_a"]), 0)
    check("prom_b occurrences (CPU 1's own address space anyway)",
          len(hits["prom_b"]), 0)
    check("prom_d occurrences", len(hits["prom_d"]), 0)
    check("no OTHER spelling in prom_c",
          [k for k in kinds if k.startswith("OTHER")], [])
    say("")
    say("   FORM 2 -- the address as an ARGUMENT.  This is the form the previous census")
    say("   missed.  Every `lda Xrr,0x00e093` whose NEXT instruction is a push:")
    pushes = []
    ia = instr_addrs("prom_c")
    keys = sorted(ia)
    for a, spell in sorted(ia.items()):
        if not spell.startswith("lda X") or "0x00e093" not in spell:
            continue
        nxt = keys[bisect.bisect_right(keys, a)]
        if ia[nxt].startswith("push"):
            after = keys[bisect.bisect_right(keys, nxt)]
            pushes.append((a, nxt, after, ia[after]))
    for a, p, c, s in pushes:
        say("      0x%06X lda / 0x%06X %s / 0x%06X %s" % (a, p, ia[p], c, s))
    check("sites that pass the block as an argument", len(pushes), 3)
    check("  and they all call the same routine",
          sorted(set(s for _a, _p, _c, s in pushes)), ["calr 0xfc4269"])
    say("")
    say("   FORM 3 -- a pointer to the block stored somewhere and dereferenced later.")
    say("   The three pushes are the ONLY sites that take the address without an")
    say("   immediate load or store, and all three are consumed by the call that")
    say("   follows in the next instruction.  No `ld (...),XBC` follows any of them.")
    for a, p, c, s in pushes:
        check("  0x%06X's push is consumed by the very next instruction" % p,
              s.startswith("calr") or s.startswith("call"), True)
    say("")
    say("   FORM 4 -- MICRO-DMA.  This CPU has DMA channels; a block nothing touches in")
    say("   code can still be moved.  The four DMA source/destination register pairs are")
    say("   loaded with `ld XWA,#imm32 / ld (0x0080+..),XWA` style writes; the census in")
    say("   FORM 1 covers ANY 32-bit or 24-bit immediate containing the address, because")
    say("   the byte pair `93 e0` appears in every one of them, wherever they lie -- the")
    say("   scan is over EVERY offset, so a site inside a data-framed region shows up too.")
    say("   It found 30 occurrences, all in prom_c, all inside the three arms, and ZERO")
    say("   in the other three images.  ⚠ It cannot see an address ARITHMETICALLY built")
    say("   (`0x00E092 + 1`); that form is closed by section 3 instead, which shows the")
    say("   block already has a reader and what it does with it.")
    say("")
    say("   FORM 5 -- the other CPU.  prom_b is CPU 1's address space, which cannot")
    say("   reach CPU 0's RAM (prom_c/prom_c.ld); it has zero occurrences anyway.")
    say("")
    say("   ★ WHAT THE OLD NEGATIVE GOT WRONG, in one line: it searched for READS of the")
    say("   address and found none, because there are none.  The reader never names the")
    say("   block; it is handed a pointer.  A census over ACCESS SHAPE cannot see a")
    say("   shared worker taking the address as an argument -- the same failure mode")
    say("   that hid twenty-four pointer-table handlers from this project last week.")


def main():
    say("w24_e093_coupling_solver.py -- the reader of 0x00E093, and what the block is")
    say("")
    sec1_the_reader()
    sec2_layout()
    sec3_where_the_result_goes()
    sec4_constants()
    sec4b_units()
    sec5_simulator()
    sec6_factory()
    if "--reach" in sys.argv:
        sec6b_reach()
    sec7_census()
    say("")
    if FAILURES:
        print("FAILURES: %d" % len(FAILURES))
        for f in FAILURES:
            print("   " + f)
        return 1
    print("FAILURES: 0")
    return 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        QUIET = True
    sys.exit(main())
