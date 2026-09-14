# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_disasm.py -- NEC uPD6383GF (SX-KN5000 IC311) effects-DSP disassembler.

    *** DRAFT / RESEARCH INSTRUMENT.  THE INSTRUCTION SET IS NOT DECODED. ***

This is a byte-faithful Python mirror of the MAME disassembler
`src/devices/cpu/upd6383/upd6383d.{cpp,h}` (in the kn7000_mame research tree).
It is vendored self-contained INTO the KN5000 disassembly repo on purpose: this
module is the living ISA reference, and re-generating the dsp/ tree must not
depend on the MAME C++ build or on `unidasm`.  When the C++ disassembler learns
a new form, port it here (or vice-versa) and re-run the generator.

  ⚠ THE TWO MIRRORS ARE CHECKED, NOT ASSUMED.  `kn7000_mame/tools/upd6383d_dump.cpp`
  is a tiny harness that prints `upd6383_disassembler::text()` for a list of
  words, and `kn7000_mame/tools/upd6383d_diff.sh` builds it and diffs its output
  against this module's `text()` over the whole 3057-word corpus.  Every claim
  that the two agree in this repo is that diff, run.  They HAD drifted -- for
  most of 2026-07-26 the C++ side carried the ALU decode and this side carried
  `ldptr.d` / `setvec` / the C-format split, and neither had the other's.

The discipline is the whole point and is preserved exactly:

  * hi12 is NOT an opcode.  It is a HORIZONTAL MICROWORD of independent enable
    bits (MEASURED, notes/kn5000-dsp-hi12.md).  It is rendered as FLAGS + an
    explicit RESIDUE, never as an opaque 12-bit number.
  * Only ESTABLISHED forms get a real mnemonic.  Everything else is emitted in
    one of two greppable forms with its field breakdown, hi12 flags and a
    structural ANNOTATION where the corpus has one:
        `?word'   nothing about the word's job is known -- THE WORKLIST;
        `~word'   K6: its ADDRESSING is decoded and executed, its ALU is not.
    A landmark is not a decode: annotated words keep their prefix.  NEVER invent
    a mnemonic.  Words whose OPERATION is determined but whose OPERAND ENCODING
    is not (the external delay-DRAM read/write, the C-format immediate load)
    stay `?word' and are reported separately by status(); no coverage number
    launders one into the other.
  * A class-A word's coefficient has a KNOWN ABSOLUTE C-RAM address (cursor base
    0x00 MEASURED, +1 per class-A word, reset by rstcur); it is printed as
    `; C-RAM[0xNN]'.  No absolute is invented for the D-RAM state operand.

Word format (MEASURED): 36 bits, right-aligned big-endian in 5 bytes; bits
36..39 always 0.  Field map (INFERRED, notes/kn5000-dsp-encoding.md sect. 8):

    35            24 23  20 19    12 11             0
   +----------------+------+--------+----------------+
   |      hi12      |class4|  addr8 |      lo12      |
   +----------------+------+--------+----------------+

...EXCEPT in the C-FORMAT family (hi12[11:8] == 0xC), where bits [24:12] are one
13-bit immediate that reaches into hi12 bit 0, so `class4' and `addr8' are a
fiction there.  See c_format()/c_a()/c_b().

2026-07-26 -- the K5 + R1 pass changed this file.  WITHDRAWN as falsified:
`hi12 == 0xC40 -> envelope / level detector' (wrong on all 61 sites);
`880.1.60/20 -> external-DRAM bracket OPEN/CLOSE' (the words are a READ and a
WRITE); the family-A-only all-pass readings of 012.2.00.680 and 000.2.00.419
(two assignments survive); and the `hi12[11:8]==A -> host-poke' rule, which
fired on genuine in-program words -- host packets are a HOST-STREAM object and
now live in host_packet().

2026-07-26, later -- the K3/K4/R2/R3 ADJUDICATION pass added `ldptr.d', widened
the delay-DRAM family to R2's predicate (C-format guarded), added the internal
register-file annotation, split `c_format()` from `is_c40()`, and moved the
C-format test to the TOP of annotate() where its precedence is load-bearing.

2026-07-26, the SYNC pass -- this file and the MAME mirror were brought back
into step and every one of the adjudication's queued MAME items landed on BOTH
sides.  What arrived HERE from the C++ side:

  * ★ THE ALU.  `lo12' is the OPERAND ROUTING and `hi12[3:1]' is the
    ACCUMULATOR OPERATION -- verified to 0.094 dB worst case over 8 coefficient
    banks, 11 biquad sections and 4 programs (notes/dsp-alu-applied.md).  This
    SUPERSEDES the three hi12-specific forms this file used to carry
    (`202.A.dd.1D5 mac', `202.A.dd.1D4 mac.lb', `212.A.dd.407 mulst'): they are
    the same instruction read through a narrower window, and they are now
    rendered by the field decode like every other routed word.  1029 corpus
    words are decoded by it, against 273 for the whole old form list.
  * K6 -- the twelve AUDIO INPUT STAGE words, whose ADDRESSING is decoded and
    whose ALU is not.  They print as `~word' with a `{addr:}' group; that is a
    THIRD state, and it is what a core can execute without guessing.

and what arrived on the C++ side from here: `ldptr.d', `setvec', the C-format
split, the guarded delay-DRAM family, the register-file annotation, the C00
wait rendering, `cur+' -> `cur', and the removal of the falsified labels.

★ THE REGISTER-LOAD FAMILY IS ONE ROUTE PLUS A MODIFIER (K3, PROVEN BY
CONSTRUCTION): lo12[7:0] is the register SELECTOR and bit 11 is a separately
assembled flag (`INC 8, WA' on top of the low byte), so `0x021' and `0x821' are
NOT two unrelated codes.  is_regload()/lo_sel()/lo_imm() model it that way.
"""

WORD_MASK = 0xFFFFFFFFF          # 36 bits

# --- hi12 microword bits (upd6383d.h) --------------------------------------
HI_ESC = 1 << 11                 # FORMAT ESCAPE (bits[10:0] mean something else)
HI_END = 1 << 10                 # END OF BLOCK, only when HI_ESC clear
HI_ST  = 1 << 4                  # WRITE ACCUMULATOR -> mem[ptr] (target is MODE-DEPENDENT)


# --- field accessors -------------------------------------------------------
def hi12(w):   return (w >> 24) & 0xFFF
def class4(w): return (w >> 20) & 0xF
def addr8(w):  return (w >> 12) & 0xFF
def lo12(w):   return w & 0xFFF


def fields(w):
    return hi12(w), class4(w), addr8(w), lo12(w)


# --- the C-FORMAT split (hi12[11:8] == 0xC) --------------------------------
# In this family `class4|addr8' is NOT a class and a pointer: bits [24:12] are
# one 13-bit IMMEDIATE that reaches ONE BIT INTO hi12 (which is why the unit-1
# link value carries 0xC41 and not 0xC40).
#
# TWO DIFFERENT PREDICATES, and conflating them caused two committed errors --
# ADJUDICATED 2026-07-26, analysis/isa-adjudication.md sect. 1, sect. 3:
#
#   c_format()  hi12[11:8] == 0xC          the FORMAT.  68 words of 3057.
#               This is the one that decides whether class4/addr8 exist.
#               R2's addressing-mode census (2989 non-C-format words) is
#               reproduced EXACTLY, row for row, ONLY by this predicate, and
#               it is the predicate that empties classes 3/7/B/E/F -- under
#               the narrow mask the corpus's one apparent `class 3' is
#               C04.3.12.820, a header word of the pointer-load lo12 family.
#   is_c40()    (hi12 & 0xFFE) == 0xC40     the PAYLOAD RULE.  57 words.
#               Only inside it is imm13 a multiple of 32 (57/57; 2/11 outside),
#               so only there is the payload the 8-bit field [24:17] with
#               B == 0.  FAMILY-LOCAL: analysis/k3-pointers.md sect. 8 item 3
#               warns explicitly against extending it to C00/C04/C0A/C16/
#               C42/C4A/C64, and this module does not.
#
# The 11 words between the two predicates are ALL kernel words (8 header, 3
# output stage) and 0 of 2974 body words, and their imm13 carries a non-zero B
# -- e.g. both C00 wait words encode their own I-RAM address as A*32+B
# (76*32+4 at I-RAM 76, 82*32+7 at I-RAM 82).
def c_format(w):  return (hi12(w) & 0xF00) == 0xC00
def is_c40(w):    return (hi12(w) & 0xFFE) == 0xC40
def c_imm13(w):   return (w >> 12) & 0x1FFF
def c_a(w):       return (w >> 17) & 0xFF      # payload
def c_b(w):       return (w >> 12) & 0x1F      # 5-bit sub-field
# c_opcode() bits[35:25] -- the C-format OPCODE (output-stage-decode.md sect. 5).
# MEASURED over 68 words: 0x620 x57, 0x605 x3, 0x632 x2, 0x600 x2, and 0x602 /
# 0x621 / 0x625 / 0x60B once each.  The payload rule is_c40() IS opcode 0x620,
# 57/57 both ways; the five lo12=0x820 words carry four opcodes (602/605/621/625),
# a shared destination not an instruction.
def c_opcode(w):  return (w >> 25) & 0x7FF


# proven-to-be FIELDS, meaning UNKNOWN
def hi_f98(hi): return (hi >> 8) & 3      # arity 3 (1713/493/766/2)


# hi12[3:1] = THE ACCUMULATOR OPERATION (notes/dsp-alu-applied.md).  FORCED into
# hi12 and out of lo12 by the LFO's minimal pair `092.A.dd.200' / `094.A.dd.200',
# which is identical in class4, addr8 and ALL TWELVE lo12 BITS.
def hi_f31(hi): return (hi >> 1) & 7      # 8/8 values seen

HI_ACC_LOAD = 0      # acc <- P
HI_ACC_ADD  = 1      # acc <- acc + P
HI_ACC_HOLD = 2      # acc unchanged -- ONLY established on class 8


def hi_residue(hi):
    """bits with no reading at all: 7, 6, 5, 0 (+ 10 inside the escape)."""
    known = HI_ESC | HI_ST | 0x300 | 0x00E     # esc, store, f98, f31
    if not (hi & HI_ESC):
        known |= HI_END                        # END only outside the escape
    return hi & ~known


# --- lo12: THE OPERAND ROUTING (NOT the operation -- see hi_f31) ------------
#
#      11 10           6 5 4              0
#     +--+--------------+-+----------------+
#     |G |     SRC      |M|     ACTION     |
#     +--+--------------+-+----------------+
#
# Four of the eighteen observed SRC codes and five of the twenty-four observed
# ACTION codes are ANCHORED; the rest are OPEN and this decoder does not guess
# them.  The SRC field is FIVE bits, not two: a 2-bit reading agrees on every
# code used by the biquad but corpus-wide it would merge the delay-RAM operand
# into mem[ptr] (0x0B vs 0x07) and the LFO into the accumulator (0x08/0x1C vs
# 0x10) -- separations that are 0-of-106 / 87-of-87 clean.
def lo_src(w):     return (w >> 6) & 0x1F
def lo_act(w):     return w & 0x1F
def lo_ptrmode(w): return bool((w >> 5) & 1)

LO_SRC_MEM = 0x07    # mem[ptr]
LO_SRC_ACC = 0x10    # the accumulator
LO_SRC_TA  = 0x19    # temporary register A
LO_SRC_TB  = 0x1A    # temporary register B

# lo12[4:0] = the ACTION.  Five codes were pinned by the biquad; TWO MORE are
# pinned by the three-context adjudication in analysis/acc-adder.md.
#   0x00  the accumulator's own input term comes from the BUS.  The LARGEST code
#         in the field (820 corpus words).  The ADDER is FORCED; WHICH half this
#         code selects is CONSISTENT, NOT FORCED -- CORRECTED 2026-07-27,
#         analysis/action00-discriminator.md.  SINGLE DELAY and the biquad are
#         BLIND to the question (at hi12[3:1] == 0 `load' and `add' are the same
#         expression, and the biquad carries no ACTION-0x00 word at all), so the
#         published 18/18 was ONE context; widen the store gate by a suppressed
#         store that clears LATE and the same solve gives 33 survivors,
#         load x15 / add x12 / rload x6, with act00 and the gate locked together.
#         `load' ships as the plurality and the only reading compatible with all
#         five surviving gates.  See upd6383d.h LO_ACT_ACC_BUS and exec_alu().
#         ⚠ AND ONE OF THE ADDER'S TWO LEGS IS WITHDRAWN, 2026-07-27
#         (adjudication-round6.md sect. 3): the adder is a RECONCILIATION of the
#         LFO ramp with SINGLE DELAY, and SINGLE DELAY's harness wires the delay
#         line at the polarity round 5 REVERSED.  RETAINED (not refuted; the LFO
#         leg is untouched; 27 of 33 even in the reversed model) but "FORCED"
#         now stands on ONE context.
#   0x19  tempA <- bus, a SECOND CAPTURE PAIR beside 0x13/0x14 (0x19 = 0x13 + 6).
#         ⛔ ITS FORCING IS WITHDRAWN, 2026-07-27 -- adjudication-round6.md sect. 3.
#         This comment used to read "FORCED 72/72 by SINGLE DELAY once the order
#         above is fixed (108/108 in the wider space of
#         action00-discriminator.md sect. 7)", and to add that the reverb comb's
#         conditional falsification (schroeder-topology.md sect. 0-C) was
#         WITHDRAWN because that search omitted "the BLOCKING read SINGLE DELAY
#         forces".  BOTH statements rest on the SAME premise and the premise is
#         FALSIFIED: SINGLE DELAY's harness (action00_discriminate.sd_run,
#         acc_adjudicate.sd_run) hard-codes `addr8 0x20 -> WRITE, 0x60 -> READ',
#         which is the polarity adjudication-round5 item D REVERSED.  SINGLE
#         DELAY is the ONLY published ALU context that contains delay-DRAM words
#         (ACTION 0x19 appears in 92 of 94 corpus sites inside DRAM-carrying
#         images; the only DRAM-free one is algo 88, an IC310 stream), so it is
#         the only one affected -- and it is the only context that constrains
#         0x19 at all.  Re-run at the corrected polarity the same harness scores
#         0 of 5832, because its one-cursor `Line' reads and writes the SAME cell
#         and the corrected order is WRITE-then-READ, so the read returns the
#         value written in that very frame (delay 0, demonstrated).  So the 108
#         and the 0 are BOTH artefacts: the determination is UNFORCED, not
#         refuted.  ★ THE SEMANTIC IS RETAINED DELIBERATELY AND IS NOT FORCED --
#         withdrawing it would re-trap words on the strength of a harness that
#         provably cannot model the corrected machine, which is the method-rule-1
#         defect in the other direction.
#         ══════════════════════════════════════════════════════════════════════
#         ★ RESOLVED (as far as it can be), ROUND 7 -- adjudication-round7.md and
#         adjudication-round8.md.  THE SENTENCE THAT USED TO END THIS BLOCK --
#         "what re-derives it is a TWO-ADDRESS delay line ... which nothing in
#         dsp/tools has yet" -- IS NOW FALSE ON BOTH HALVES:
#           (a) the two-address line EXISTS (dsp/tools/delayline.py, audited
#               independently in adjudicate8.py `harness': it delays, it says YES
#               to a textbook comb and NO to that comb's D+1 twin, and all 324
#               ROM lines are representable);
#           (b) IT DOES NOT RE-DERIVE THE FORCING, AND CANNOT.  At the FORCED
#               polarity algo 9's two loops both cross w21..w24 (ACTIONs 0x0D /
#               0x0E, undecoded), so no executable window of SINGLE DELAY
#               contains a delay loop at all -- every cell of the enumeration
#               {forced,published} x {push_read,push_any,latency,blocking} x
#               4 windows x 7776 ALU machines is `-- NONE --' at the forced
#               polarity.  That is an ABSENCE OF A SEARCH, not a zero.
#         WHAT IS MEASURED INSTEAD, by a corpus route with no delay line in it:
#         ACTION 0x19 is followed by a word SOURCING tempA at a tight modal lag
#         of 1, in ** 74 of 89 ** distinct-image sites (base rate 16.0 %,
#         best-of-2000 ACTION-shuffled null 42.7 %).  ⚠ NOT the "401 of 402 /
#         99.8 %" of adjudication-round7.md -- that denominator counts one word
#         position once per ALGORITHM sharing the image, a 4.79x replication
#         (adjudicate8.py `denom').  So: DESTINATION = tempA, MEASURED.
#         SOURCE (`<- bus' vs `<- acc') NEVER TESTED BY ANY OF IT -- still OPEN.
#         ⚠ AND `0x19 = 0x13 + 6, a second encoding of ONE operation' HAS NO
#         POSITIVE EVIDENCE: their consumer lags are DISJOINT (0x13's tempA
#         reader sits at lag EXACTLY 8 -- one 8-word motif repetition -- in 35 of
#         40 sites, against a 5.1 % base rate; 0x19's sits at lag 1), and NINE
#         of 38 images use BOTH, so it is not a per-program assembler
#         convention.  Not refuted; unsupported.  Do not state it as fact.
#         ⇒ IT KEEPS SHIPPING, under the owner's 2026-07-27 decision, with the
#         destination measured and the source OPEN.  Trapping it would still
#         destroy the only executing frames any harness can be validated
#         against, and nothing refutes the semantic.
#         ══════════════════════════════════════════════════════════════════════
LO_ACT_ACC_BUS = 0x00  # acc's input term <- bus (the adder's second selector)
LO_ACT_ST_BUS = 0x07  # mem[ptr] <- bus
LO_ACT_NONE_2 = 0x12  # no temp/memory side effect
LO_ACT_CAP_TA = 0x13  # tempA <- bus
LO_ACT_CAP_TB = 0x14  # tempB <- bus
LO_ACT_NONE_5 = 0x15  # ditto -- how it differs from 0x12 is OPEN
LO_ACT_CAP_TA2 = 0x19  # tempA <- ??? -- SHIPS ON THE OWNER'S DECISION, 2026-07-27.
#   ⚠ The DESTINATION is *** NOT MEASURED ***.  This comment used to say it was
#   ("74/89, lag 1", adjudication-round8.md item G).  That statistic -- a word
#   SOURCING the register at a characteristic lag -- FAILS ITS OWN CALIBRATION
#   0 of 2 on the codes whose destinations we know independently: for 0x13
#   (tempA) tempA and tempB TIE and mem beats both; for 0x14 (tempB) the WRONG
#   temporary wins by 20 points.  It measures structural adjacency in a motif
#   that interleaves two temporaries, not dataflow.  See analysis/
#   capture-signature.md and run tools/capture_sig.py calib before trusting it.
#   0x19's profile IS the cleanest of the three (its own register far above a
#   200-fold null, both rivals AT or BELOW it, which neither known code
#   manages) -- but "cleanest" is not a calibrated criterion.  What survives is
#   SUCCESSION, not destination.  SOURCE (<-bus vs <-acc) open; "second
#   encoding of 0x13" UNSUPPORTED.

_ANCHORED_SRC = (LO_SRC_MEM, LO_SRC_ACC, LO_SRC_TA, LO_SRC_TB)
_ANCHORED_ACT = (LO_ACT_ACC_BUS, LO_ACT_ST_BUS, LO_ACT_NONE_2, LO_ACT_CAP_TA,
                 LO_ACT_CAP_TB, LO_ACT_NONE_5, LO_ACT_CAP_TA2)

# ★ SPECULATIVE TIER (goal 2026-09-06): prospective SRC/ACT readings accepted so
# more of the corpus "fits in place".  Kept separate from the strict sets; each
# rests on a prospective reading, never a MEASURED one (bases: SRC 0x0B = delay-
# read data register, LEDGER sect. 215; SRC 0x11 = ACCB, sect. 27; SRC 0x13 =
# coef/wave table port, CORPUS-PATTERNS-SPECULATIVE S-6; ACT 0x0C = delay READ,
# 12/12; ACT 0x08 = table-port multiply).  Mirrors upd6383d.h *_spec.
LO_SRC_ACCB = 0x11
LO_SRC_DRD  = 0x0B
LO_SRC_TABLE = 0x13
LO_SRC_MEM0 = 0x00   # sect. 233: mem[ptr] / delay-RAM read (null-MAC rival refuted)
LO_SRC_LFO  = 0x08   # ★ = C-RAM[cursor], THE COEFFICIENT.  Name kept for ABI; the old
                     # "LFO / per-unit modulation source" gloss is CORRECTED 2026-09-13 --
                     # it is the coefficient port, and it is the LFO's ramp CONSTANT that
                     # anchored it, not an LFO signal.
LO_SRC_LFOOUT = 0x1C # control/mod source read into a MAC (was "LFO OUTPUT",
                     # action00-discriminator.md:468) -- REFINED 2026-09-08: 0x1C is
                     # present in 19 programs with NO LFO table (distortion/exciter/pitch/
                     # PEQ-combos) and is MAC-consumed 91/91, so it is the effect's control
                     # bus (LFO for modulation, envelope/AGC for dynamics), NOT LFO-specific.
LO_ACT_DELAY_RD = 0x0C
LO_ACT_TBL_MUL  = 0x08
LO_ACT_BIQ_D = 0x0D  # delay/state I/O MIXING (0x0D reads mem onto bus). ⚠ name kept
LO_ACT_BIQ_E = 0x0E  #   for ABI; "biquad delay-stage" CORRECTED 2026-09-11 -- the pair
                     #   is UNIVERSAL (every family incl. plain delay/AM, no biquad);
                     #   true 2nd-order-section state = 0x13/0x14. Exact ALU = hw Q4.
LO_ACT_DELAY_ACC = 0x0B  # delay-line access (dark-words F); READ/WRITE class-borne

#   ★★★★★ 2026-09-13: ACT 0x0D / 0x0E PROMOTED OUT OF THE SPECULATIVE TIER.
#   The pair was CLOSED as `ACT 0x0E' selector 7 by TWO INDEPENDENT ROUTES -- §234 FROM DISK
#   (the EQ's entry window against the designer's biquad, 1 of 49, with a junk-pre-load control
#   that kills the runner-up) and §58 FROM THE HLE ORACLE (`parametric_eq' is a SERIES CASCADE, so
#   only the FIRST band may receive a clean copy of the input; only selector 7 delivers that).
#   It was nevertheless carried as "FOR THE EQ, not a global decode" for ONE stated reason: at
#   selector 7 `prog32_distortion' read STATIC (§61).
#   ⇒ THAT REASON IS NOW REFUTED.  §70-§76 showed the distortion's deadness was its INPUT CELL
#   BEING RAILED, not the selector; with the input-stage decode fixed it runs -- 42 of 42 body
#   rows move frame to frame and its hand-off cell carries -102 851.  The caveat's whole basis
#   was a defect somewhere else.
#   ⇒ and §77 adds a live corroboration the earlier rounds could not have: with these two words
#   behaving, the EQ's five bands all carry signal and the LLE's own operand pointers reproduce
#   the HLE's cascade 4 of 4.
_ANCHORED_ACT = _ANCHORED_ACT + (LO_ACT_BIQ_D, LO_ACT_BIQ_E)

#   ★★★★★ 2026-09-13: SRC 0x00 ANCHORED.  It is the corpus's single largest open axis (648
#   occurrences; sole reason for refusing 348 of them), and BOTH of its populations already have
#   evidenced, SHIPPED readings -- the disassembler's predicate was simply lagging the decode.
#
#     class A & hi12[9:8] == 1  ->  C-RAM[cursor]  (the COEFFICIENT).  §145/§148, SHIPPED in the
#       device behind SPEC bit 59, which is SET in the default mask.  Three pre-registered
#       predictions including a known-answer control.  MEASURED 20 of 20 on the live corpus.
#     everything else           ->  mem[ptr].       §233: SEVEN candidate readings enumerated and
#       SIX REFUTED -- the SINGLE DELAY's lag-1001 ROM product accepts `mem' and ONLY `mem'.  That
#       supersedes the old "1 of 6 enumerated, no independent support" grade.
#
#   ⚠ TWO READINGS, ONE CODE -- and that is legitimate here because the split is a function of the
#   word's OWN FIELDS (class4 and hi12[9:8]), so a disassembler can compute which applies without
#   any context.  `alu_decoded()' asks "is this word's semantics determined"; it is.
#   ⚠ It is NOT anchored because a majority matched: §7 measured the naive whole-code test at
#   1005/1413 and the 232-row residue looked like a third population.  §8-§10 dissolved that -- the
#   residue was words that never DROVE the operand latch, invisible until the `LW' column existed,
#   and 57 of 57 undriven rows hold with zero exceptions.  The partition is clean BECAUSE that
#   sub-question was closed, not in spite of it.
_ANCHORED_SRC = _ANCHORED_SRC + (LO_SRC_MEM0,)

#   ★★★★★ 2026-09-13: SRC 0x0B ANCHORED, and it closes a loop opened the same day.
#   Like SRC 0x00 this is ONE code with TWO readings, split by a field of the word itself:
#     class 1 (the delay ESCAPE)  ->  the delay-read data register.  The original reading,
#       motivated by and validated on the 99 class-1 delay words; unchanged.
#     any other class             ->  mem[ptr].  PROMOTED TO THE DEVICE DEFAULT TODAY
#       (`UPD6383_SRC0B2', N-INPUT-GATE-OPENED §73/§76) on a pre-registered gate: 8 programs
#       across 3 families at the TRUE device default, 8 FIXED / 0 BROKEN, blast radius measured
#       at 7 words before promoting -- and confirmed SEMANTICALLY, not just numerically: under it
#       the kernel's `iw25' loads tempA with EXACTLY each program's own DI1 input-latch cell.
#   ⚠ The 7 words this anchors are EXACTLY that measured blast radius -- kernel `iw25' and the six
#   `020.2.00.2C7' in prog06_ensemble.  Nothing is admitted here that the gate did not exercise.
_ANCHORED_SRC = _ANCHORED_SRC + (LO_SRC_DRD,)

#   ★★★★★ 2026-09-13: SRC 0x08 ANCHORED = C-RAM[cursor], the COEFFICIENT.
#   MEASURED and its rival REFUTED FROM DISK (SQUARING-MULTIPLY_findings.md item B): the chorus
#   LFO at `iw89' has `L = 114' and `acc = 7 471 104 = 114 << 16' EXACTLY, and
#   `114 = C-RAM[0x00] = floor(0.5993 * 2^23 / 44100)' -- the constant `lfo_ramp.py' derives from
#   the ROM.  The rival requires SRC 0x08 to be a SAMPLE source, and a sample there gives no ramp.
#   ⚠ The old gloss "LFO / per-unit modulation source" is CORRECTED above: it is the coefficient
#   port.  What anchored it was the LFO's ramp CONSTANT, not an LFO signal -- the name misread its
#   own evidence.
#   ★ Null, computed (item D): P(SRC 0x08 | not multiply-gated) = 0.05 %, 1 of 2 096; 81 of its 83
#   corpus occurrences are class A (97.6 %).  It is essentially DEFINED by the coefficient gate.
#   ⛔ LEDGER: "do not touch the SRC 0x08 source read (anchored)".
_ANCHORED_SRC = _ANCHORED_SRC + (LO_SRC_LFO,)

_ANCHORED_SRC_SPEC = _ANCHORED_SRC + (LO_SRC_ACCB, LO_SRC_DRD, LO_SRC_TABLE,
                                      LO_SRC_MEM0, LO_SRC_LFO, LO_SRC_LFOOUT)
_ANCHORED_ACT_SPEC = _ANCHORED_ACT + (LO_ACT_DELAY_RD, LO_ACT_TBL_MUL,
                                      LO_ACT_BIQ_D, LO_ACT_BIQ_E, LO_ACT_DELAY_ACC)

# ---------------------------------------------------------------------------
#  hi12 BIT 7 GATES THE BIT-4 STORE (upd6383d.h HI_B7).  The biquad's 0.094 dB
#  never reached a bit-7 word -- PARAMETRIC EQ has ZERO words carrying bit 4 and
#  bit 7 together -- and the LFO cannot run if they store.  Three surviving
#  gates agree that (bit7, hi12[3:1]) == (1, 1) does NOT store; alu_decoded()
#  traps everything they disagree about.
#
#  ★ 2026-07-27: bit 7 being IN THE CONDITION is now FORCED, not assumed --
#  analysis/store-gate.md item C runs all nine enumerated conditions against
#  both witnesses (the biquad needs class (0,1) to store, the LFO needs class
#  (1,1) not to) and exactly two survive, `b7 & f31 == 1' (this one) and
#  `b7 & f31 != 2'.  They differ only where alu_decoded() already refuses.
#  What the suppressed case DOES is forced only negatively: 0 of 17 928
#  survivors write mem[ptr], but 21 of 33 effects survive, including `LOAD'
#  (bit 7 as a memory-port DIRECTION bit).  See analysis/adjudication-round4.md.
HI_B7 = 1 << 7


def st_suppressed(w):
    return bool(hi12(w) & HI_B7) and hi_f31(hi12(w)) == 1


# --- lo12 bit 11 is a FIELD, not part of an opcode -------------------------
# PROVEN BY CONSTRUCTION (analysis/k3-pointers.md sect. 1.1 item 2): the Sub CPU
# writer assembles the low byte and then does a literal `INC 8, WA' into byte 3's
# low nibble, i.e. it builds `lo12 = 0x800 | 0x021' and `lo12 = 0x800 | 0x025'.
def lo_sel(w): return lo12(w) & 0xFF          # the register SELECTOR
def lo_imm(w): return bool((w >> 11) & 1)     # "addr8 carries a payload"
def lo_mid(w): return (lo12(w) >> 8) & 7      # residue: 0 at all 10 corpus sites


# --- lo12 bit 11 SELECTS A SECOND ENCODING -------------------------------
# analysis/bit11-family.md sect. 9.  Over the 38 distinct IC311 images, bits 11
# and 5 CO-VARY: 80 words have both set, 0 have bit 11 without bit 5, and the
# single bit-5-without-bit-11 word is `801.0.00.021' -- PARAMETRIC EQ's cursor
# reset, an is_regload() word whose lo12 is PROVEN BY CONSTRUCTION (K3 item A) to
# be selector+flag rather than SRC/mode/ACTION.  Excluding that one already-known
# family the co-occurrence is EXCEPTIONLESS.
#
# Under a SRC/mode/ACTION parse the five bit-11 shapes would need SRC 0x02, SRC
# 0x04, ACT 0x03, ACT 0x04 and ACT 0x1C -- every one of which occurs ZERO times
# among the 2836 bit-11-clear words.  So bit 11 switches lo12 out of the ALU
# encoding, exactly as it does in the register-load family, and bit 5 is part of
# the alternate form, NOT the pointer mode.
#
# WHAT the alternate form encodes is OPEN.  This says only what it is not.
def alt_lo12(w):
    """True if lo12 is NOT the SRC/mode/ACTION route.  lo_src()/lo_act()/
    lo_ptrmode() are MEANINGLESS on these words -- they are the field accessors
    applied to the wrong encoding, and using them is how PHANTOM_ACT/PHANTOM_SRC
    got into published censuses."""
    return (not c_format(w)) and bool((w >> 11) & 1)


# Codes whose every corpus site is an alt_lo12() word: they are parse artefacts,
# not instructions.  Counts over the IC311 corpus, analysis/bit11-family.md 9.3.
PHANTOM_ACT = {0x03: 54, 0x04: 1, 0x1C: 25}
PHANTOM_SRC = {0x02: 25, 0x04: 1}

# Codes whose counts are INFLATED by alt_lo12() words (corrected value second),
# analysis/bit11-family.md sect. 9.4.  ACT 0x19 is LO_ACT_CAP_TA2.
INFLATED_ACT = {0x19: (425, 383), 0x01: (40, 39)}
INFLATED_SRC = {0x11: (231, 177), 0x00: (1653, 1611), 0x01: (39, 38)}

LO_SEL_CP  = 0x21    # a C-RAM pointer -- NOT the cursor, NOT the D-RAM pointer
LO_SEL_DSC = 0x25    # the delay-DESCRIPTOR pointer (tag 0x4C)
_REGLOAD_SEL = (0x20, 0x21, 0x22, 0x25, 0x27)


def is_regload(w):
    """THE REGISTER-LOAD FAMILY.  `hi12 == 0x801' IS NOT AN ALU OPCODE (K3
    sect. 8 item 1): with class4 == 0 and a `0x_2x' selector this word is a
    register write and nothing else -- nine corpus words carry hi12 == 0x801
    (6 header, 2 output stage, 1 body) and a tenth, `859.0.86.822', is the same
    form with other microword bits set, INCLUDING bit 4.  All ten must be
    dropped from any lo12-as-ALU-route modelling.

    hi12 is deliberately NOT in the predicate: it cannot be, because hi12 is a
    horizontal microword and `859.0.86.822' proves the family carries other
    bits.  That word is a register write that ALSO stores, which is exactly why
    it is not decoded below."""
    return ((not c_format(w)) and class4(w) == 0 and lo_mid(w) == 0
            and lo_sel(w) in _REGLOAD_SEL)


# The three members whose REGISTER and MODIFIER are both established.  A member
# carrying the bit-4 store is excluded: its second effect has an unproven target
# off mode 2 (R2), so it keeps trapping.
def is_ldptr(w):
    return is_regload(w) and not (hi12(w) & HI_ST) and lo_sel(w) == LO_SEL_CP and lo_imm(w)


def is_rstcur(w):
    return is_regload(w) and not (hi12(w) & HI_ST) and lo_sel(w) == LO_SEL_CP and not lo_imm(w)


def is_ldptrd(w):
    return is_regload(w) and not (hi12(w) & HI_ST) and lo_sel(w) == LO_SEL_DSC and lo_imm(w)


def is_end(w):
    """bit 10 with bit 11 clear = END OF BLOCK (the word still does its work)."""
    hi = hi12(w)
    return bool((hi & HI_END) and not (hi & HI_ESC))


def cursor_fetch(w):
    """bit 23 (== class4 bit3) = CURSOR-FETCH enable (NOT multiply-enable).
    NOT in the C-format family: there bit 23 is a bit of the immediate
    (analysis/k5-output-stage.md sect. 3.1)."""
    return bool((w >> 23) & 1) and not c_format(w)


def coeff_consumer(w):
    """STRICT coefficient consumer: class4 == 0xA (advances the cursor by one).
    C-format words are excluded -- their class4 is immediate data, so a C-format
    word does NOT shift the C-RAM addresses after it.  MEASURED: exactly ONE word
    in the whole 3057-word corpus is affected, the frame terminator
    C00.A.47.407 at I-RAM 82, and zero body words are.  On the MAME side that
    one word was not merely mis-annotated but DECODED AND EXECUTED as a class-A
    multiply-and-store until this guard landed.

    FETCH IS NOT ADVANCE (K4, FORCED).  bit 23 says a coefficient is fetched;
    only class4 == 0xA moves the cursor on.  The PARAMETRIC EQ body's ten
    class-8 words sit inside a cursor map proven to the bit at 6 cells per
    band; if class 8 advanced, band k would start at cell 7k and all 60 named
    roles would shift.  MEASURED over the 2974-word body corpus: the only
    classes that set bit 23 are 8 (42) and A (822).  The KERNEL additionally
    has class 9 (4), C (1) and D (1), so a core must NOT assume
    `bit 23 => class 8 or A'."""
    return class4(w) == 0xA and not c_format(w)


# ---------------------------------------------------------------------------
#  ★ THE ADDRESS GENERATOR IS DECODED EVEN WHERE THE ALU IS NOT.
#  (upd6383d.h ptr_postinc() / has_addressing().)
#
#  Two of this machine's addressing effects read NO PART of lo12:
#      ptr_postinc()     class4 & 7 == 2  ->  p += (s8)addr8   [MEASURED]
#      coeff_consumer()  class4 == 0xA    ->  cursor++         [FORCED, K4]
#  so they do not need the ALU decode, and the MAME core now performs them on
#  EVERY word rather than on the twelve whitelisted K6 words.  Restricting them
#  was a LIVE DEFECT: over the cold-boot frame (285 slots) the pointer's net
#  displacement was -259 with only the executing words moving it and is -135 with
#  every word moving it, and the coefficient cursor advanced 37 times instead of
#  73 -- so a decoded `mac (p),c+' late in the frame was reading a D-RAM cell
#  ~124 away from the right one and a coefficient ~36 cells early.
#
#  NOT generalised: hi12 bit 4 (the accumulator store), which needs a CORRECT
#  accumulator.  EXECUTE WHAT ADDRESSES, NEVER WHAT COMPUTES.
# ---------------------------------------------------------------------------
def ptr_postinc(w):
    return (not c_format(w)) and (class4(w) & 7) == 2


def has_addressing(w):
    """Does this word have ANY modelled addressing effect?  A word that has none
    (a delay-DRAM access, a table lookup, a register-file word) executes NOTHING
    -- its own addressing is undecoded too."""
    return ptr_postinc(w) or coeff_consumer(w) or cursor_fetch(w)


# lo12 0x445 / 0x446 name the per-unit CALL VECTOR register.  DETERMINED:
# analysis/k5-output-stage.md sect. 2.4 -- the ONLY two I-RAM words the host ever
# rewrites (I-RAM 64 and 71), written by EFF_Link / EFF_Disconnect indexed by
# effect unit, and the four values decode to 84/42 (unit 0) and 200/50 (unit 1),
# which are the I-RAM load address of every unit-0 / unit-1 body (91/91 streams)
# and the first word of that unit's own header setup block.
VECTOR_LO12 = {0x445: 0, 0x446: 1}
VECTOR_MEANING = {
    (0, 84):  "LINK -- unit-0 body entry",
    (0, 42):  "DISCONNECT -- header unit-0 setup block (runs, returns, no body)",
    (1, 200): "LINK -- unit-1 body entry",
    (1, 50):  "DISCONNECT -- header unit-1 setup block (runs, returns, no body)",
}


def is_vector_lo12(lo): return lo in VECTOR_LO12


def is_setvec(w):
    """C-format immediate load into a per-unit CALL VECTOR register."""
    return is_c40(w) and is_vector_lo12(lo12(w))


# --- named cells of the internal REGISTER FILE (addressing mode 1, no escape)
# ★ bit 7 of the index is the effect UNIT -- K4 item G, FORCED over 428 host
# packets (368/23 all < 0x80 in unit-0 streams, 60/5 all >= 0x80 in unit-1
# streams, 5/5 unit-1 numbers a unit-0 number + 0x80), which RESOLVES the
# class-1 addr8 lead K6 opened.  NOTE WHAT IT IS NOT: the delay-DRAM sub-ops
# 0x20/0x30/0x60 are discriminated by hi12 (the FORMAT ESCAPE, 324/324), NOT by
# addr8 bit 7 (which misclassifies 3 of 324).
REGISTER_ROLE = {
    0x06: "per-unit OUTPUT LEVEL (PROVEN BY CONSTRUCTION -- the last four host "
          "actions of cold boot are setvec unit1,#200 / setvec unit0,#84 / "
          "reg 0x06 <- +0.500000 / reg 0x86 <- +0.183992, both cleared at reset)",
    0x86: "per-unit OUTPUT LEVEL (PROVEN BY CONSTRUCTION -- see 0x06)",
    0x50: "base of the per-unit STATE BLOCK (MEASURED: in 87 of 91 parameter "
          "streams the host's tag-0x15 zero-fill is a CONTIGUOUS run based here; "
          "PARAMETRIC EQ's is the 40-cell one, 0x50..0x77 = 5 bands x 2 ch x 4 "
          "Direct-Form-I state words)",
    0xD0: "base of the per-unit STATE BLOCK (MEASURED -- see 0x50; unit 1's run "
          "is 3 cells in all 12 reverbs)",
}


# ---------------------------------------------------------------------------
#  K6 -- THE AUDIO INPUT STAGE, I-RAM 0..11 (notes/dsp-k6-input-stage.md)
#
#  ADDRESSING DECODED, ALU NOT.  Every one of these twelve words has a FORCED
#  pointer/store/cursor effect and an OPEN arithmetic one, so they get their own
#  classification rather than being lumped in with either the decoded forms or
#  the worklist.  Matched by EXACT 36-bit WORD VALUE, never by I-RAM position:
#  each occurs exactly once in the 60-word header and ZERO times in the
#  2974-word body corpus, with one deliberate exception -- the epilogue's w79 is
#  byte-identical to the header's w3, which is the frame-closure loop.
#
#  `iw1' is a C-format word: no class4, no addr8, no memory operand and no
#  cursor effect, so there is nothing for it to do to the input path.  Its
#  13-bit immediate 0x0E0 = 7 x 32 names I-RAM 7, the first word of the second
#  block.  It is listed as an explicit SAFE NO-OP rather than left to trap.
# ---------------------------------------------------------------------------
K6_INPUT_STAGE = {
    0x09220120D: "K6 input stage, header w0: ST mem[X+0], p+1 -- the epilogue's w80/w81 read X+0 this same frame",
    0x0C0A0E0000 & WORD_MASK: "K6 input stage, header w1: C-format, imm13 0x0E0 = 7*32 -> I-RAM 7 = block B; SAFE NO-OP (no memory, pointer or cursor effect)",
    0x084202680: "K6 input stage, header w2: read mem[X+1], p+2 -- X+1 is the one-frame feedback cell the epilogue's w79 wrote",
    0x0122FF1CE: "K6 input stage, header w3 (= epilogue w79): ST mem[p], p-1; ALU UNKNOWN",
    0x2042021CE: "K6 input stage, header w4: *** THE PORT READ, block A *** mem[X+2] is an AUDIO INPUT LATCH (read-never-written by all 3057 words); p+2",
    0x202A00448: "K6 input stage, header w5: read mem[X+4], p+0, cursor+1; ALU UNKNOWN",
    0x400A00419: "K6 input stage, header w6: END OF BLOCK A (falls through), read mem[X+4], p+0, cursor+1",
    0x090A011C8: "K6 input stage, header w7: ST mem[X+4], p+1, cursor+1 -- X+4 is a one-frame state cell (read at w5/w6, written here)",
    0x0842011C0: "K6 input stage, header w8: *** THE PORT READ, block B *** mem[X+5] is an AUDIO INPUT LATCH; p+1",
    0x0122FF1D5: "K6 input stage, header w9: ST mem[X+6], p-1 -- the only input-stage product the header's mix block consumes",
    0x282A01417: "K6 input stage, header w10: read mem[X+5] a SECOND time, p+1, cursor+1; ALU UNKNOWN",
    0x400201447: "K6 input stage, header w11: END OF BLOCK B (falls through), read mem[X+6], p+1 -- the pointer leaves at X+7",
}

# the two whose D-RAM operand IS an audio input latch.  There is no "read DI"
# OPCODE on this chip: the port-ness is entirely in the ADDRESS, which is why
# every opcode-level search for an I/O instruction came up empty.
K6_PORT_READ_L = 0x2042021CE       # 204.2.02.1CE, header w4, cell X+2
K6_PORT_READ_R = 0x0842011C0       # 084.2.01.1C0, header w8, cell X+5


def input_stage_role(w):
    return K6_INPUT_STAGE.get(w & WORD_MASK)


def is_input_latch_read(w):
    """-> None | 'L' | 'R'."""
    w &= WORD_MASK
    if w == K6_PORT_READ_L: return "L"
    if w == K6_PORT_READ_R: return "R"
    return None


# ---------------------------------------------------------------------------
#  THE EXECUTABLE ALU PREDICATE -- five guards, each with its own evidence, and
#  NOTHING outside their conjunction.  (upd6383d.h alu_decoded().)
#
#  lo12 ROUTES, hi12[3:1] OPERATES -- notes/dsp-alu-applied.md, which reconciles
#  three concurrent analyses and FALSIFIES the framing all three started from
#  ("lo12 is the ALU field").  Verified on the PARAMETRIC EQ biquad -- the only
#  block whose arithmetic is known independently, because the firmware designs
#  its coefficients with its own tan()-based bilinear designer -- to max 0.094 dB
#  over 8 ROM coefficient banks, 11 section instances, 4 programs.
#
#      L    := src[ lo12[10:6] ]
#      if hi12 bit 4 :  mem[p] <- acc ; acc := 0        store AND clear
#      hi12[3:1] :  0 -> acc <- P   1 -> acc += P   2 -> acc unchanged
#      lo12[4:0] :  13 -> tempA <- L  14 -> tempB <- L  07 -> mem[p] <- L
#      if class4 == A :  P := coef[cursor++] * L
#      if class4 & 7 == 2 :  p += (s8)addr8
#
#  1. FORMAT.  A C-format word has no class4 and no addr8 at all.  Without this
#     test `C00.A.47.407' -- the frame terminator -- reads as class A with an
#     anchored route and was DECODED AND EXECUTED as a multiply-and-store.
#  2. CLASS.  Only 2, A and 8 are on-chip datapath classes; class 1 is where the
#     external delay-DRAM lives.
#  3. ROUTING.  Both halves of lo12 anchored; neither the pointer-mode bit (5)
#     nor the bit-11 MODIFIER set.  Bit 11 is rejected because it is UNMODELLED
#     on an ALU route, NOT because it is part of an opcode.
#  4. STORE TARGET.  hi12 bit 4's destination is MODE-DEPENDENT and mem[ptr] is
#     the MODE-2 target (R2).  MEASURED: this guard removes ZERO words -- no
#     class-8 corpus word carries bit 4 -- so it costs nothing.
#  4b. ...AND SO IS ACTION 0x07's, which is guard 4's DEFECT TWIN.  L=07 means
#     "write the operand to A DESTINATION" and the destination is again the mode:
#     `2C7' on a mode-1 escape word is the external DELAY-RAM write and the output
#     stage's four L=07 words write the register/port space.  The executor writes
#     mem[ptr] unconditionally and class 8 is MODE 0.  PREDICT-THEN-CHECK:
#     predicted this was already firing; MEASURED that it is NOT -- of the 303
#     executing L=07 words, 303 are mode 2 and 0 are not.  Zero cost, hole closed.
#     * AND IT NOW HAS A POSITIVE REASON, not just a precautionary one
#     (analysis/output-stage-decode.md item J, FORCED).  On a MODE-1 word ACTION
#     0x07 does NOT write reg[addr8]: the output stage's w72 is `000.1.06.087'
#     and register 0x06 is the unit-0 OUTPUT LEVEL, written once by the
#     firmware's EFF_VolumeLoop after linking (PROVEN BY CONSTRUCTION) and
#     carrying the user's effect depth.  If ACTION 0x07 on a mode-1 word wrote
#     the addressed register, that depth would survive exactly ONE frame.  So the
#     guard is not merely cheap -- widening it would be wrong.  (Stated escape,
#     not excluded: SRC 0x02, undecoded, might carry the level itself and make
#     the write an identity.)
#  5. OPERATION.  hi12[3:1] must be one the biquad determines.  HI_ACC_HOLD is
#     admitted ONLY on class 8.
# ---------------------------------------------------------------------------
def _alu_half_anchored(w):
    """The ALU part of `alu_decoded()' WITHOUT the class test -- for a word whose class is already
    explained by its format escape.  A class-1 delay word still runs its datapath half (the device
    calls `exec_alu()' for it under SPEC bit 19, set by default), so these fields are live."""
    hi = hi12(w)
    if lo12(w) & 0x800:
        return False
    if lo_ptrmode(w):
        return False
    if lo_src(w) not in _ANCHORED_SRC or not _act_anchored(w):
        return False
    if (hi & HI_ST) and (hi & HI_B7) and hi_f31(hi) not in (1, 2):
        return False
    return hi_f31(hi) in (HI_ACC_LOAD, HI_ACC_ADD, HI_ACC_HOLD)


def _act_anchored(w):
    """The anchored ACT set, plus one CLASS-CONDITIONAL member.

    ★★★ `ACT 0x0B' ON CLASS A is the all-pass core's fourth MULTIPLICAND ROUTE.  Every one of the
    16 class-A occurrences is the same word shape `lo12 = 0x64B' with `SRC 0x19' (tempA), and the
    listing's own annotation grades it **FORCED**: "class-A multiply whose multiplicand is a SUM OF
    TWO REGISTERS, so lo12 0x64B is a fourth multiplicand route beside mac (0x1D5) and mulst
    (0x407) (FORCED under a 2-input ALU, R1 F8)".  The premise it is forced under -- that the
    multiplier has exactly two ports -- is itself FORCED (SQUARING-MULTIPLY item A: a coefficient
    port hardwired to C-RAM[ccur] and ONE operand bus selected by SRC; there is no third port).

    ⛔ NOT admitted on any other class, and `0x0B' stays OPEN -- but ⛔⛔ THE REASON THIS
    DOCSTRING USED TO GIVE FOR THAT IS FALSE (sect. 129, `dsp/tools/act0b_scope.py').  It quoted
    `adjudication-round5.md' as "ACT 0x0B => READ is DEGENERATE with H-ADB6: EVERY ACT-0x0B DELAY
    WORD CARRIES addr8 0x20/0x30", dropping that measurement's own population -- `dram-matching.md'
    item J states it as *"203 slots over the 83 algorithms where `#cells == #consumers'"*.  Over
    the FULL delay corpus the universal fails:
      * SIX ACT-0x0B delay words carry `addr8 = 0x60', which round 5 item D FORCED as the WRITE --
        `kernel w46/w54', `prog06_ensemble w0/w39' and the WSA1R's `eff20_ensemble w0/w51'.  TWO
        of them are in the KN5000's own algorithm images, so the universal fails inside ONE
        product, before the second is pooled in.
      * The CONVERSE fails harder: 463 WRITE-side delay words carry EIGHT distinct ACTIONs and
        ACT 0x0B is 1.3 % of them.  Neither field determines the other, so "degenerate" is wrong
        in both directions.
      * CONTROL: 4 of the 9 ACTIONs on this family ARE one-sided, so one-sidedness is the NORM
        here and carries little information alone.  ACT 0x0B (159 read / 6 write) is not one.
    ⇒ the SCOPED measurement is untouched and is not re-run here; what is withdrawn is the
    universal and the "adds nothing" inference built on it.  The code stays OPEN on its own
    merits: `act0b-reverb.md' item D still leaves THREE survivors (`none', `mem<-bus', `tA<-acc')
    and `sd_act0b.py' MEASURED that SINGLE DELAY's lag-1001 ROM product accepts all six readings
    (LEDGER sect. 291).  Those class-2 words keep trapping."""
    a = lo_act(w)
    if a in _ANCHORED_ACT:
        return True
    return a == LO_ACT_DELAY_ACC and class4(w) == 0xA


def _is_wrapword(w):
    """§224/§225's LFO WRAP family: the SIX fields together, exactly as the device gates it.
    bit-4 store + bit 7 + hi12[3:1] == 2 + ACTION 0x00 + SRC 0x08 + class A.  29 words."""
    hi = hi12(w)
    return (bool(hi & HI_ST) and bool(hi & HI_B7) and hi_f31(hi) == HI_ACC_HOLD
            and lo_act(w) == LO_ACT_ACC_BUS and lo_src(w) == 0x08 and class4(w) == 0xA)


def alu_decoded(w):
    if c_format(w):
        return False
    cl = class4(w)
    if cl not in (2, 8, 0xA):
        return False
    if lo12(w) & 0x800:
        return False
    if lo_ptrmode(w):
        return False
    if lo_src(w) not in _ANCHORED_SRC or not _act_anchored(w):
        return False
    if (hi12(w) & HI_ST) and (cl & 7) != 2:
        return False
    if lo_act(w) == LO_ACT_ST_BUS and (cl & 7) != 2:
        return False
    if (hi12(w) & HI_ST) and (hi12(w) & HI_B7):
        # guard 7 -- the bit-7 store gate.  The ONLY case the surviving gates
        # settle is hi12[3:1] == 2.
        #
        # ★ THE ACTION-0x00 ESCAPE AT hi12[3:1] == 1 IS WITHDRAWN (2026-07-27,
        # analysis/adjudication-round4.md sect. 6).  Its justification -- "the
        # CLEAR is unobservable because ACTION 0x00 replaces the accumulator
        # feedback outright" -- covers only the gates whose clear is taken
        # BEFORE the ALU or never.  `b7_f31_1_clrlate' defers it to AFTER the
        # ALU, where it zeroes the result whatever the ACTION was, and it is
        # one of the 21 class-(1,1) effects store-gate.md sect. 4 leaves alive.
        # Price, MEASURED: ONE corpus word (`092.A.01.1C0', header I-RAM 37).
        #
        # ★★★★★ 2026-09-13 (N-INPUT-GATE-OPENED sect. 106): `f31 == 1' IS NOW
        # ADMITTED.  The gate's THREE-WAY openness was closed by ELIMINATION, on
        # criteria the ROM and the FIRMWARE supply -- each of which demonstrably
        # CAN fail, because a different arm made each of them fail:
        #   clr:never  (the shipped reading) ⛔ the VOLUME cell `0x06' -- PROVEN BY
        #      CONSTRUCTION as the user's effect depth in 49 of 49 algorithms,
        #      written once by `EFF_VolumeLoop' -- is RAILED in 5 of 5 out-of-sample
        #      programs and churned 11 .. 177 316 times.
        #   clr:after  ⛔ the LFO phase cell stops moving at all.
        #   LD@before  ⛔ the LFO runs at a 4.0-frame period against a ROM constant
        #      of 114 per frame.
        #   LD@after   ⛔ the phase cell is dead.
        #   clr:before ✔ VOLUME written ONCE and unrailed 5 of 5; the LFO alive with
        #      its minimum step exactly the ROM's 114; 10-program hand-off
        #      regression 10 KEPT / 0 BROKEN; re-verified with NO ENV SET AT ALL.
        # ⇒ `none' and `ST(acc->else)' are the only survivors and they are THE SAME
        # MACHINE -- `gate_settle.py:70' makes the `else' key unreadable by
        # construction.  So "is there a store at all" stays UNANSWERABLE and stops
        # mattering for EXECUTION, which is what this predicate asks.  Promoted in
        # the device as `UPD6383_GATECLR' default 1 (`=0' is the control).
        # ⚠ `f31 == 0' still traps: there the two surviving GATE CONDITIONS
        # disagree about whether `mem[ptr]' is written at all, which is not an
        # accumulator question and is untouched by any of this.
        if hi_f31(hi12(w)) not in (1, 2):
            return False
    f = hi_f31(hi12(w))
    if f in (HI_ACC_LOAD, HI_ACC_ADD):
        return True
    if f == HI_ACC_HOLD:
        #   ★★★★★ 2026-09-13: `f31 == 2' ADMITTED OFF CLASS 8, except on the WRAP-WORD family.
        #
        #   This used to be `return cl == 8', for a reason stated right here: the joint solve left
        #   TWO candidates alive -- a plain no-op and `AND 2^23-1' -- and on class 8 the biquad
        #   FORCES the sum in range, where both are the identity.  Elsewhere the two could differ,
        #   so the code was refused.  MEASURED today over 10 live captures: they DO differ
        #   somewhere -- 9 of 216 executions leave datum range, by up to 1.3x the rail.  So the
        #   ambiguity is real and "mostly identity" would not have been enough.
        #
        #   ⇒ WHAT SETTLES IT IS THAT THE RIVAL HAS ITS OWN PREDICATE, AND THESE WORDS FAIL IT.
        #   The `AND' reading is NOT hypothetical -- it is shipped (§224/§225, default ON) as the
        #   LFO WRAP, anchored on the ROM's own ramp constant (+114/frame, 29 LFO blocks in 16
        #   programs, 9 distinct increments).  Its arithmetic is `acc <- datum(acc) & L', and `L'
        #   is the SRC 0x08 operand -- MEASURED as C-RAM[0x01] = 0x7FFFFF, the cell the C-RAM
        #   annotation itself calls "wrap".  The family is identified by SIX fields together:
        #   bit-4 store + bit 7 + f31 == 2 + ACT 0x00 + SRC 0x08 + class A, and it is 29 words.
        #
        #   MEASURED: of the 215 off-class-8 `f31 == 2' words that are NOT in that family,
        #   **ZERO carry SRC 0x08** (their sources are 0x07 x155, 0x00 x51, 0x1A x5, 0x10/0x11 x2).
        #   Without that operand there is no modulus, so the `AND' candidate is not merely
        #   unlikely on them -- it is NOT EXPRESSIBLE.  The one rival that kept this code out has
        #   been claimed by a different predicate and cannot reach here.
        #   ⚠ The 29 wrap-words stay refused; they are a DIFFERENT operation, and they are refused
        #   on `SRC 0x08' as well, which is open on its own account.
        #   ★★★★★ 2026-09-13 (second pass): THE WRAP FAMILY IS ADMITTED TOO, so this is now
        #   unconditional.  I excluded it an hour ago on two grounds and BOTH have since gone:
        #     "a different operation" -- true, but `alu_decoded()' asks whether the semantics is
        #        DETERMINED, not whether it matches its neighbours.  For these 29 it is:
        #        `acc <- (datum(acc) & L) << ACC_SHIFT', §224/§225, SHIPPED AS THE DEVICE DEFAULT,
        #        anchored on the ROM's own ramp constant and carried through FOUR passing
        #        falsifiers (W0 one slot, W1's clip-count delta predicted TO THE UNIT in both
        #        buckets, W2 the chorus LFO reaching its published cell as a +114/frame ramp, W3
        #        every regression control unmoved); the fifth was restated under RULE 21 and is
        #        then 0/0/0 in BOTH arms.
        #     "open on SRC 0x08 anyway" -- no longer true: SRC 0x08 was anchored above in this
        #        same pass, so that reason expired the moment it was written.
        #   ⇒ all three sub-populations of `f31 == 2' are determined: class 8 (forced identity by
        #   the biquad), the wrap family (the modulus, shipped), and the remaining 215 (the AND
        #   rival is not expressible on them -- 0 of 215 carry the SRC 0x08 operand it needs).
        return True
    return False


def alu_decoded_spec(w):
    """★ SPECULATIVE decode (goal 2026-09-06): alu_decoded() with the prospective
    SRC/ACT codes anchored too (_ANCHORED_*_SPEC).  Everything it admits beyond
    alu_decoded() rests on a prospective reading; the strict predicate is
    untouched.  Mirrors upd6383d.h alu_decoded_spec()."""
    if c_format(w):
        return False
    cl = class4(w)
    # ★ SPECULATIVE: also admit register-file modes class 1/9 (rendered "internal
    # register file [XX]") and the table-lookup idiom's class 4/6 (rendered
    # "table-lookup idiom", INFERRED).
    if cl not in (1, 2, 4, 6, 8, 9, 0xA):
        return False
    if lo12(w) & 0x800:
        return False
    if lo_ptrmode(w):
        return False
    if lo_src(w) not in _ANCHORED_SRC_SPEC or lo_act(w) not in _ANCHORED_ACT_SPEC:
        return False
    # ★ SPECULATIVE: drop the three strict store guards (bit-4 / ACT 07 / bit-7
    # off mode 2).  The store OPERATION is known; only its target is
    # mode-dependent (R2), which is a detail for a decode metric and irrelevant
    # here since this predicate never executes.  And accept HI_ACC_HOLD on any
    # admitted class (the op is the same as at class 8).
    f = hi_f31(hi12(w))
    return f in (HI_ACC_LOAD, HI_ACC_ADD, HI_ACC_HOLD)


def decoded(w):
    """Is this a form with a real mnemonic -- i.e. one a core could EXECUTE?
    (upd6383d.cpp decoded().)"""
    hi, cl, ad, lo = fields(w)
    if hi == 0x000 and cl == 2 and ad == 0x00 and lo == 0x000: return True  # nop
    if is_ldptr(w) or is_rstcur(w) or is_ldptrd(w):            return True
    if is_setvec(w):                                           return True
    #   ★★★★★ 2026-09-14 (N-INPUT-GATE-OPENED sect. 115): THE `is_c40' IMMEDIATE LOAD.
    #   `is_c40' is ONE instruction -- opcode 0x620, and the payload rule holds 57 of 57 inside it
    #   and 2 of 11 outside -- and its DESTINATION is selected by `lo12'.  That is not a guess: it
    #   is what `is_setvec(w) = is_c40(w) and is_vector_lo12(lo12(w))' PROVES for `lo12' 0x445 and
    #   0x446, the per-unit CALL VECTOR registers (K5, DETERMINED destination).  ⇒ for one opcode
    #   the destination field selects among REGISTERS; `acc' or `tempB' would mean the same opcode
    #   writes a register for two `lo12' values and the accumulator for the others, which is not
    #   how a destination field works.  INFERRED (strong), on a proven sub-case.
    #   ★ AND THE REGISTER IS NEVER READ: `UPD6383_CFMTDST=7' (`reg[lo12 & 0xFF]') is BIT-IDENTICAL
    #   to the shipped latch on **8 of 8 programs**, with the arm firing ~28 M times in each.
    #   ⇒ the word loads an immediate into a register nothing reads back: EXECUTABLE.
    #   ★★★★★ 2026-09-14 (sect. 122): AND NOW THE OTHER ELEVEN TOO.  The line above used to read
    #   *"⛔ NOT extended to the 11 non-`is_c40' C-format words -- `k3-pointers.md' sect. 8 item 3
    #   warns against carrying the payload rule past opcode 0x620, and this does not."*  That was
    #   right: the extension was UNMEASURED.  It is measured now, by two routes, NEITHER of which
    #   carries the `0xC40' rule outward.
    #     ROUTE 1, `cfmt_addr.py' -- THE REGION TEST.  All ELEVEN payloads land inside the image
    #     that carries them (kernel 0..59, epilogue 60..82).  `A' is 8 bits, so the uniform null is
    #     explicit: p = 6.6e-9.  Two of them (epilogue w76 -> 76, w82 -> 82) are SELF-REFERENCES,
    #     and the two `0x632' words both land at `block start + 3' of their OWN per-unit CALL block.
    #     ROUTE 2, `kernel_homolog.py --reloc' -- THE RELOCATION TEST, and it needs no null at all.
    #     The SX-WSA1R ships a byte-homologous copy of this kernel header at a different offset
    #     (34 of 42 words identical and in order; best unrelated image 2, mean 0.4).  A field that
    #     is an ADDRESS must shift by the number of words inserted before it; one that is DATA must
    #     not.  MEASURED: `A' tracks the relocation EXACTLY in 4 of 4 comparable pairs, while
    #     `B = imm13 & 0x1F' and `f31' are IDENTICAL across the two products at all five positions.
    #   ⇒ the C-format word is ONE instruction -- destination from `lo12', payload = an I-RAM
    #   address in `A' plus a second field `B' -- and the device executes it destination-first
    #   (`UPD6383_CFMTDST=7', bit-identical to the shipped latch on 8 of 8 programs).  EXECUTABLE.
    #   ⚠ THIS DOES NOT SAY WHAT THE ADDRESS IS FOR.  `closure-pointer.md' item B has FALSIFIED the
    #   `0x820' family as the frame-closing D-RAM pointer load ON SITING, and `w40 -> 14' is a
    #   backward reference to an END-OF-BLOCK word that nothing explains.  Encoding, not purpose.
    if c_format(w):                                            return True
    #   ★★★★★ 2026-09-13: THE DELAY ESCAPE IS EXECUTABLE **WHEN BOTH ITS HALVES ARE**.
    #   A class-1 escape is an external delay-DRAM access whose ADDRESSING is FORCED -- direction
    #   from `addr8' bit 6, address = DESCRIPTOR_CELL[k] + G by the IDENTITY map
    #   (adjudication-round5, PROVEN BY CONSTRUCTION) -- so grading it on the CLASS test, which
    #   the escape itself explains, was wrong and cost 276 determined words.
    #   ⛔⛔ BUT MY FIRST VERSION OF THIS WAS TOO STRONG, and §91 caught it.  I wrote that such a
    #   word "never reaches the ALU: the device's own `is_dram' branch RETURNS BEFORE IT", and
    #   admitted all 276 on that basis.  **The branch does not return** -- it calls `exec_alu(word)'
    #   with `m_in_dram = true' under SPEC bit 19, which is SET IN THE DEFAULT MASK.  The delay
    #   word runs its ALU half deliberately, so that the delay datum reaches the datapath, and its
    #   SRC / ACT / f31 therefore DO apply.  MEASURED consequence: `iw331', a delay WRITE, leaves
    #   unit 1's accumulator at exactly the positive rail -- which "an external delay write" does
    #   not describe.
    #   ⇒ a delay escape is decoded when its ADDRESSING is forced AND its ALU half is anchored.
    #   MEASURED: 201 of the 276 qualify; the other 75 are refused on their ALU half
    #   (`ACT 0x0B' on class 1 x50, `ACT 0x1C' x17, `ACT 0x1A' x6, `ACT 0x07' x2).
    #   ★★★★★ 2026-09-13 (N-INPUT-GATE-OPENED sect. 112): THE BLOCK TERMINATOR, on exactly the
    #   argument sect. 90 used for the delay escape -- the CLASS TEST is what refuses it, and the
    #   word's own form EXPLAINS the class.
    #     * WHAT IT IS, MEASURED: `host-side.md' item B1 -- the class-1 index word is THE LAST
    #       WORD OF EVERY BODY IMAGE and carries `addr8 = 0x0E' in 37 of 37 unit-0 images and
    #       `0x0F' in the one unit-1 image.  `instruction-set.md' already publishes the form
    #       ("terminator / END OF BLOCK -- class4 == 1 && addr8 in {0E, 0F}").
    #     * ITS `addr8' IS THE UNIT INDEX, measured on the same 38.
    #     * AND ITS ALU HALF RUNS.  upd6383.cpp's sequencer is explicit -- "the transfer, AFTER
    #       the word has done its datapath work" -- so its SRC / ACT / f31 apply, which is the
    #       check sect. 91 says to make before admitting anything on a format escape.
    #   ⇒ decoded when the ADDRESSING is explained AND the ALU half is anchored, exactly as for
    #   the escape.  ⚠ Disjoint from the delay escape by construction: `is_end' requires hi12
    #   bit 10 SET and bit 11 CLEAR, and `is_dram' requires bit 11 SET.
    #   ⚠ NOT claimed: what the sequencer does with it.  upd6383.cpp calls its call/return model
    #   "the frame SEQUENCER's model, not the ISA's" and that stays true -- this says the WORD is
    #   executable, not that the jump is derived.
    if is_terminator(w):
        return _alu_half_anchored(w)
    #   ★★★★★ 2026-09-14 (sect. 128): MODE 1 -- THE REGISTER FILE -- ON THE SAME FOOTING.
    #   The class test is what refuses these words, and the word's own form explains the class:
    #   `class4 & 7 == 1' with the escape CLEAR is register-file addressing with `addr8' the
    #   index (`r2-output.md' sect. 1.1/1.2, 48 of 48 for the STORE half), and `mode1_index.py'
    #   anchors the READ half four ways -- see `is_mode1()'.  ⚠ Must follow `is_terminator', which
    #   is a mode-1 word with its own rendering.  ⚠ Disjoint from `is_dram' by the escape bit.
    if is_mode1(w):
        return _alu_half_anchored(w)
    #   ★★★★★ 2026-09-14 (sect. 161): MODE 4, ON THE SAME FOOTING AND FOR THE SAME REASON.
    #   The class test is what refuses these words; the word's form explains the class once the
    #   pointer question is settled, and `cls4_arm.sh' settled it with a two-sided emulator run
    #   that COULD have gone the other way -- see `is_mode4()'.  ⚠ Must follow `is_mode1' (a
    #   different mode) and precede nothing that claims class 4; `is_dram' is disjoint by the
    #   escape bit.
    if is_mode4(w):
        return _alu_half_anchored(w)
    if is_dram(w) and dram_dir(w):
        return _alu_half_anchored(w)
    if alu_decoded(w):                                         return True
    return False


def addressing_only(w):
    """K6 -- A THIRD STATE.  The word's ADDRESSING is decoded and executable and
    its ALU is not.  A word is `addressing only' ONLY while it is not fully
    decoded: the ALU field decode claims the stage's `012.2.FF.1D5', so one of
    the twelve graduates from PARTIAL to DECODED, which is exactly the movement
    this classification exists to measure."""
    return input_stage_role(w) is not None and not decoded(w)


def form_of(w):
    """The mnemonic name of a decoded form, or None.  Lives HERE rather than in
    dsp_coverage.py because that copy drifted once already: it mapped every
    `hi12 == 0x801' word that was not ldptr to rstcur, which would have
    mis-tallied ldptr.d (analysis/isa-adjudication.md sect. 7)."""
    if not decoded(w):
        return None
    if is_setvec(w):  return "setvec"
    if _is_wrapword(w):
        return "wrap"
    if is_dram(w) and dram_dir(w):
        return "dly.r" if dram_dir(w) == "READ" else "dly.w"
    if is_ldptr(w):   return "ldptr"
    if is_ldptrd(w):  return "ldptr.d"
    if is_rstcur(w):  return "rstcur"
    if hi12(w) == 0x000 and lo12(w) == 0x000:
        return "nop"
    return _alu_mnemonic(w)


# --------------------------------------------------------------------------
#  TIER 2 -- the OPERATION is determined, the OPERAND ENCODING is not.
#  These words cannot be executed (we do not know where their address comes
#  from), so they are NOT `decoded'; but calling them unknown would now be
#  false.  They are kept separate so no coverage number launders one into the
#  other.  status() is what the coverage tool counts.
# --------------------------------------------------------------------------
def is_terminator(w):
    """THE BLOCK TERMINATOR -- the last word of every body image (sect. 112).

    `class4 == 1' with the END bit.  MEASURED as the final word of 37 of 37 unit-0 images and the
    one unit-1 image (`host-side.md' item B1); the form is already published in
    `instruction-set.md'.  Disjoint from `is_dram()' by construction -- `is_end' needs hi12 bit 10
    set with bit 11 CLEAR, the escape needs bit 11 SET.

    ⛔⛔ 2026-09-14 (sect. 124): THE `addr8 in {0x0E, 0x0F}' CLAUSE WAS OVER-FITTED TO ONE PRODUCT
    AND IS GONE.  Pooled with the SX-WSA1R, which runs the same ISA:

        KN5000   40 terminator-shaped words, addr8 0x0E x38 / 0x0F x2   -- all admitted
        SX-WSA1R 53 terminator-shaped words, addr8 0x4F x53             -- ⛔ ZERO admitted

    The SHAPE is confirmed by the second product, not weakened by it: **93 of 93 class-1 END words
    are the last word of a BLOCK** (the single non-image-final one is kernel `w49', which ends the
    unit-0 CALL block 42..49 -- exactly what a block terminator does).  What the second product
    refutes is the VALUE SET, and the `addr8 = unit index' reading with it: 53 WSA1R images cannot
    all be unit 1.  `addr8' is the terminator's operand and its meaning is OPEN across products.
    ⇒ the guard is the shape; `endblk' no longer names a unit it cannot know."""
    return (not c_format(w)) and class4(w) == 1 and is_end(w)


def is_mode1(w):
    """MODE 1 -- THE REGISTER FILE.  `class4 & 7 == 1' with the format escape CLEAR (sect. 128).

    `r2-output.md' sect. 1.1 splits class 1 on the escape bit and classifies all 324 KN5000
    class-1 words correctly where `addr8' bit 7 misclassifies three; sect. 1.2 names the escape-0
    side *"a REGISTER FILE -- and the host uses the same space"*, `addr8' the index (48 of 48).
    ⇒ the ADDRESSING of these words is explained by their own form, which is exactly the
    condition `is_dram()' and `is_terminator()' are admitted on (sect. 90 / sect. 112).

    ★ `class4 & 7', not `class4 == 1': the device derives the addressing mode that way
    (`upd6383.cpp' rdmode/stmode), so class 1 and class 9 are ONE mode and ONE question -- 247
    undecoded words across the two products, not 25.

    ★★★ AND THE READ HALF IS NO LONGER A GUESS (`dsp/tools/mode1_index.py').  `upd6383.cpp' used
    to say of its own register-file read route *"⛔ GUESSED: symmetry ... no note in this project
    states it"*.  Four measurements state it:
      1. ZERO CALIBRATION -- 327 of 327 mode-1 words carry a NON-ZERO `addr8', including all 228
         that have no store and therefore no documented use for the field.  Control: mode 2,
         where `addr8' IS a signed delta and 0 is legal, is 42.6 % zero.
      2. CONSTANT CONTROL -- 35 distinct values, varying inside a single image (the control that
         killed the previous version of this argument: a constant field is never zero either).
      3. RUN TEST -- one WSA1R image's 32 indices contain a run of 26 CONSECUTIVE values
         (p <= 7.6e-28 for a uniform 8-bit field), walked `n, n+2, n+1, n+3' on a STRIDE OF 4:
         a Direct-Form-I biquad's four state cells per section.
      4. ★ AND THE READ USES IT -- reads sit at lag <= 1 from a WRITE OF THE SAME INDEX in
         51 of 95 cases against a shuffled null of 29.4 +- 2.1 (max 37 over 2000 shuffles).  A
         read that ignored `addr8' would have no reason to sit next to the write of that index.
    ⚠ An earlier form of test 4 was VACUOUS -- "a write of this index exists somewhere in the
    image" is invariant under a multiset shuffle (null mean 95.0, sd 0.0, observed 95) -- and the
    null is what caught it, not care."""
    return ((not c_format(w)) and (class4(w) & 7) == 1
            and not (hi12(w) & HI_ESC))


def is_mode4(w):
    """MODE 4 -- `mem[ptr]', AND THE POINTER DOES NOT MOVE (sect. 158, sect. 160, sect. 161).

    Same footing as `is_mode1': the CLASS TEST is what refused these words, and the word's own
    form explains the class.  What made mode 4 harder than mode 1 is that its addressing had a
    genuinely open axis -- `closure_pointer.py' carried a variant in which class 4 post-increments
    the pointer by `s8(addr8)', exactly as class 2 does -- and sect. 112's standard is *"the
    ADDRESSING is explained AND the ALU half is anchored"*.  It is closed now, in three steps.

    1. ★ THE FIELD CANNOT DECIDE IT.  MEASURED pooled over both products (`lut_idiom.py --modes'):
       class 4 is 99 words carrying the SINGLE `addr8' value 0x01.  Under the delta reading the
       field expresses one displacement in eight bits; under `no move' it expresses nothing.  So
       only an EXECUTION difference could separate them.

    2. ★★ THE RIVAL VARIANTS THAT BUNDLED CLASS 6 ARE EXCLUDED ON THE MEANING OF THE FIELD.  Class
       6's `addr8' is the table ENTRY COUNT -- anchored at 24 by a table independently proven to
       have 24 entries -- so it is not a displacement, and `closure_pointer.py variants' shows V8's
       residue delta is +56 == 24 + 32, the two class-6 `addr8' values of the image it walks.  That
       kills V8, V10 and V12 and leaves V7 (class 4 alone), which had never had an arm.

    3. ★★★★★ AND V7 IS FALSIFIED BY A TWO-SIDED RUN (`dsp/tools/cls4_arm.sh', evidence in
       `analysis/data/cls4/').  `UPD6383_CLS4PTR' was built for it and run at TYPEIDX 12; both
       runs fingerprint `prog35_exciter' (sect. 193) and the arm's unconditional count is
       3 346 456 ON against 0 OFF, so it reached its words.  EXCITER was chosen because
       `f31_oracle_pin.py's own selection puts an `op0x70' biquad band FOUR WORDS DOWNSTREAM of its
       class-4 word (8 of 8 such algorithms have a band downstream; sect. 160).  The D-RAM census
       over 259 308 frames:

           arm OFF   50:32699 51:56868 52:9836 53:9836 | 54:33065 55:57855 56:9941 57:9941
           arm ON    50:57661 51:1     52:1    53:1    | 54:1     55:9255  56:1    57:1   ...

       OFF is TWO LIVE FOUR-CELL BANDS whose offset-2/3 cells change together -- which is the DF-I
       state layout the device's own `SPEC_SUBFB' encodes (`(rdsrc - base) & 3 >= 2' = the y-states)
       -- mirrored across the two channels.  ON, ten of the twelve are written ONCE in 259 308
       frames and the state sprays to 0x58..0x5E: the filter stops running.  ⇒ the pointer does NOT
       advance on class 4.
       ★ The criterion COULD fail and DID: the arm is what produced the dead structure.  And the
       oracle's float-model caveat does not apply -- this is which CELL is read, not a rounding.

    ⚠ `class4 & 7', as for mode 1: class 4 and class C are one mode.  Class C's 7 words carry
    `addr8 = 0' and fail `_alu_half_anchored()', so they stay undecoded on their ALU half, which is
    the right reason.  ⚠ Escape CLEAR: mode 4 with the escape is `is_dram''s business.
    ⚠ NOT claimed: what `addr8 = 0x01' is FOR.  It is constant over all 99 words in two products
    and this says only that it is not a pointer displacement."""
    return ((not c_format(w)) and (class4(w) & 7) == 4
            and not (hi12(w) & HI_ESC))


def is_dram(w):
    """external delay-DRAM access word.

    THE FAMILY is `addressing mode 1 WITH the hi12 FORMAT-ESCAPE bit', which is
    R2's predicate and is exceptionless over the corpus: mode 1 without the
    escape is the internal register file, mode 1 with it is the external delay
    DRAM (analysis/r2-output.md sect. 1).  C-format words must be excluded
    first -- their class4 is immediate data, and C40.1.80.000 (the reverb's
    A=12 immediate load) otherwise walks straight into this family.  That
    misclassification is exactly what analysis/isa-adjudication.md sect. 1
    falsifies in R3, and the deciding argument there is IDENTITY, not counting:
    C40.1.80.000 and C40.2.C0.000 are the SAME instruction on the SAME
    destination register (lo12 = 0x000), differing only in the immediate, and
    they read class4 1 vs 2 only because bit 8 of that immediate differs.  ANY
    predicate that selects DRAM words by class4 alone is wrong.

    THE ADDRESS is NOT in the word (R3, PROVEN BY CONSTRUCTION):

        delay-DRAM address = ( DESCRIPTOR_CELL[cursor] + G ) mod 2^N

    a host-written 24-bit descriptor bank reached through pointer register
    `...825' with host-poke tag 0x4C -- the delay twin of the coefficient bank
    behind `...821' / tag 0x26, written by the very same four instructions in
    the Sub CPU (LABEL_038922 vs LABEL_0387E6).  A cell holds
    LINE_BASE + DELAY_IN_SAMPLES, so a delay is an ADDRESS and a line's delay
    is the DIFFERENCE of two cells.  The cell comes from an implicit
    auto-incrementing cursor, in program order, so it is still not derivable
    from the word alone -- which is why these stay TIER 2.

    DIRECTION: `addr8' bit 6 selects it, and 0x60 is the WRITE -- FORCED in
    analysis/adjudication-round5.md sect. 3.  This REVERSES R1 F1, and the
    reversal is the round's main result, so both sides are named here:

      * the FIELD is forced by an EXHAUSTIVE enumeration (dram-direction.md
        item B): over the 133 non-C-format equal-value descriptor pairs, of
        every boolean function of every named field only two reach zero
        violations -- `addr8' bit 6 and its own global flip -- and bit by bit
        over all 36 bits exactly one reaches zero.
      * the POLARITY is forced twice over, once the cell<->word map is pinned
        to the IDENTITY (adjudication-round5 sect. 1, three polarity-free
        oracles, unique among 13 phases, permutation null 0 of 2000):
          (a) MULTI TAP DELAY has FOUR op-0x67 taps sharing ONE line base, and
              a multi-tap is one write and N reads.  The four taps carry
              addr8 0x20/0x30 and the shared base carries 0x60.
          (b) at a boundary shared by two ladder segments the READ must take
              the aged word BEFORE the write overwrites it; the earlier access
              of all 133 opposite-bit pairs carries bit 6 = 0.
      * R1 F1 said the opposite and is FALSIFIED AS STATED, not outvoted: its
        acceptance test 2 and F6 bound the DRAM read latency to inside one
        8-word repetition, and the descriptor addresses need TWENTY words.
        read_slot = 4 was outside the searched model class.
      * R3 sect. 6.3, which was quoted here as REFUTING the addr8 rule, in fact
        refutes only its old polarity.  Its MULTI TAP observation is (a).

    SCOPE: stated and applied only over addr8 0x20 / 0x30 / 0x60.  The C-format
    consumer C40.1.80.000 carries addr8 0x80 and is excluded by `c_format'
    anyway; it is the word no instruction rule can reach (the identical 36-bit
    word sits on both sides of three equal-value pairs)."""
    return bool(hi12(w) & HI_ESC) and class4(w) == 1 and not c_format(w)


def dram_dir(w):
    """'READ' | 'WRITE' | None -- the delay-DRAM direction, FORCED.

    None means the word's addr8 is outside the validated set and the direction
    keeps trapping (method rule 6)."""
    ad = addr8(w)
    if ad in (0x20, 0x30):
        return "READ"
    if ad == 0x60:
        return "WRITE"
    return None


def status(w):
    """'DECODED' | 'DETERMINED' | 'MEASURED' | 'PARTIAL' | None -- what is known
    about the word's OPERATION.  Used by tools/dsp_coverage.py; deliberately
    does NOT promote anything into decoded()."""
    if decoded(w):
        return "DECODED"
    if addressing_only(w):
        return "PARTIAL"           # K6: addressing decoded and executed, ALU open
    if is_dram(w):
        return "DETERMINED" if dram_dir(w) else "MEASURED"
    if is_c40(w):
        return "MEASURED"          # 13-bit immediate load; destination OPEN
    if lo12(w) in VECTOR_LO12:
        return "MEASURED"          # writes a call vector; SOURCE field OPEN
    return None


def hi12_text(hi):
    """The horizontal microword as FLAGS + an explicit RESIDUE."""
    parts = []
    if hi & HI_ESC:
        parts.append("ESC")
    elif hi & HI_END:
        parts.append("END")
    if (hi & HI_ST) and not (hi & HI_ESC):
        parts.append("ST")
    if hi_f98(hi):
        parts.append("f98=%d" % hi_f98(hi))
    if hi_f31(hi):
        parts.append("f31=%d" % hi_f31(hi))
    res = hi_residue(hi)
    if res:
        for b in range(11, -1, -1):
            if (res >> b) & 1:
                parts.append("?%d" % b)
        parts.append("res=%03X" % res)
    if not parts:
        return "-"        # hi12 == 0x000: every enable clear
    return " ".join(parts)


def annotate(w, at=None):
    """MEASURED structural landmarks whose SEMANTICS are unknown, plus the few
    whose OPERATION is now determined.  Mirrors upd6383d.cpp annotate().
    `at' = the word's I-RAM index when the caller knows it (the C00 self-address
    check needs it).  Returns a string or None.

    ★ PRECEDENCE IS LOAD-BEARING.  The C-format rule must come BEFORE any rule
    keyed on lo12, class4 or addr8, because in that family class4|addr8 is not a
    class and a pointer -- it is immediate data.  The ONE rule above it is the
    K6 whitelist, which matches by exact 36-bit word value over twelve
    individually-reviewed words."""
    hi, cl, ad, lo = fields(w)

    k6 = input_stage_role(w)
    if k6 is not None:
        return k6

    # ---- C-FORMAT FIRST.  bits [24:12] are ONE 13-bit immediate -------------
    if c_format(w):
        a, b, op = c_a(w), c_b(w), c_opcode(w)
        if is_setvec(w):                       # decoded(); never reaches here
            return None
        # THE PAYLOAD RULE IS THE OPCODE (bits[35:25]): is_c40 <=> opcode 0x620,
        # 57/57 both ways, so `A = imm13 >> 5' is that opcode's 8-bit payload.
        if is_c40(w):
            return ("C-format opcode 0x%03X IMMEDIATE LOAD: A=%d B=%d (imm13 0x%04X "
                    "= %d*32, MEASURED 57/57 for this opcode); destination register "
                    "lo12=%03X UNKNOWN" % (op, a, b, c_imm13(w), a, lo))
        if hi == 0xC00:
            own = ("= its own I-RAM address" if at is not None and at >= 0 and a == at
                   else "(I-RAM index?)")
            return ("WAIT / SYNC (INFERRED), C-format opcode 0x%03X: A=%d %s, B=%d = "
                    "the event; both C00 words in the machine encode their own "
                    "address (2/2)" % (op, a, own, b))
        if lo in (0x820, 0x825, 0x827, 0x822):
            return ("C-format opcode 0x%03X, pointer-load lo12; the five lo12=0x820 "
                    "words carry FOUR opcodes (602/605/621/625) -- a shared "
                    "DESTINATION, not an instruction; A=%d B=%d" % (op, a, b))
        return ("C-format opcode 0x%03X: bits [24:12] are one 13-bit IMMEDIATE "
                "reaching into hi12 bit 0, not class+addr; A=%d B=%d" % (op, a, b))

    if is_end(w):
        if cl == 1 and ad == 0x0E:
            return "END OF BLOCK, unit 0 -- CALL/RETURN -- and still performs the rest of the word"
        if cl == 1 and ad == 0x0F:
            return "END OF BLOCK, unit 1 -- CALL/RETURN -- and still performs the rest of the word"
        return "END OF BLOCK (falls through) -- and still performs the rest of the word"

    # ---- external delay DRAM.  ADDRESS SOURCE and DIRECTION known; the CELL is
    #      still an implicit cursor, so these stay TIER 2 and keep trapping.
    if is_dram(w):
        role = dram_dir(w)
        base = ("external delay-DRAM access; address = DESCRIPTOR_CELL[k] + G, "
                "from the host bank behind pointer ...825 / tag 0x4C (R3, PROVEN "
                "BY CONSTRUCTION) -- the k-th class-1 escape word of a body takes "
                "the k-th cell of that body's own descriptor block (the IDENTITY "
                "map, FORCED in adjudication-round5 sect. 1), so the address is "
                "NOT in this word")
        if role == "READ":
            extra = ("; this end moves with the user's DELAY (ms) knob, and the "
                     "delay is READ_CELL - WRITE_CELL")
            if ad == 0x30:
                extra += ("; addr8 0x30 also marks the FIRST DRAM access of a "
                          "body, 37 of 38 distinct images (R3 sect. 6.2)")
        elif role == "WRITE":
            extra = ("; the line BASE -- MULTI TAP DELAY's four taps share "
                     "exactly one of these, which is what forces the polarity")
        else:
            return (base + ". DIRECTION OUT OF SCOPE: addr8 0x%02X is outside "
                    "the 0x20 / 0x30 / 0x60 the rule was validated on" % ad)
        return ("external delay-DRAM %s (FORCED, adjudication-round5 sect. 3 -- "
                "addr8 bit 6 is the direction field and 0x60 is the WRITE; this "
                "REVERSES R1 F1, which bounded the read latency to one "
                "repetition when the descriptors need twenty words)%s. %s"
                % (role, extra, base))

    # ---- the reverb all-pass core (analysis/r1-allpass-motif.md) ------------
    # NOT decoded: two role assignments survive the constraint search and the
    # corpus RANKS -- but does not prove -- the one in which mem[ptr] stages the
    # DRAM write.  The old family-A-only readings printed here were withdrawn.
    if w == 0x104200000:
        return ("all-pass core slot 1/6 -- role NOT settled (family B: acc += P; "
                "family A: no job at all).  Outside the reverb all 8 sites follow "
                "a class-A multiply-and-store")
    if w == 0x000200419:
        return "all-pass core slot 2/6 -- one accumulate step; which one is NOT settled"
    if w == 0x012200680:
        return ("all-pass core slot 3/6 -- the bit-4 store takes the accumulator "
                "BEFORE this word's own ALU step (FORCED, R1 F2)")
    if hi == 0x102 and cl == 0xA and lo == 0x64B:
        return ("all-pass core slot 6/6 -- class-A multiply whose multiplicand is a "
                "SUM OF TWO REGISTERS, so lo12 0x64B is a fourth multiplicand route "
                "beside mac (0x1D5) and mulst (0x407) (FORCED under a 2-input ALU, "
                "R1 F8)")

    if is_vector_lo12(lo):
        return ("writes the unit-%d CALL VECTOR (I-RAM %d) -- DETERMINED destination; "
                "this SOURCE form is the canned boot default, its source field is OPEN"
                % (VECTOR_LO12[lo], 64 if lo == 0x445 else 71))

    if hi == 0x092 and cl == 0xA and lo == 0x200:
        return "LFO: phase += increment (increment = f/44100 in Q0.23)"
    if hi == 0x094 and cl == 0xA and lo == 0x200:
        return "LFO: phase wrap, consumes 0x7FFFFF (29/29); AND vs sub-if-ge OPEN"

    # ---- mode 1 WITHOUT the escape = the internal REGISTER FILE -------------
    # R2 sect. 1: index space shared with the host's own `000.1.NN.000', which
    # the host stream proves auto-increments.  bit 7 of the index = the effect
    # unit (K4, FORCED -- see REGISTER_ROLE above).  Class 1 and class 9
    # (= mode 1 plus the cursor fetch) both land here.
    if (cl & 7) == 1:
        role = REGISTER_ROLE.get(ad)
        if role:
            return "internal register file [%02X] -- %s, unit %d" % (ad, role, 1 if ad & 0x80 else 0)
        return ("internal register file [%02X], unit %d (bit 7 = the unit); this "
                "index has no named role yet" % (ad, 1 if ad & 0x80 else 0))

    # ---- the REGISTER-LOAD family: one route (lo12[7:0]) plus a MODIFIER ----
    # The decoded members never reach here, so what is left is the OPEN
    # selectors -- and `859.0.86.822', a register write that ALSO stores.
    if is_regload(w):
        # ★ A CONFLICT BETWEEN TWO COMMITTED READINGS, REPORTED NOT RESOLVED.
        # K3 sect. 5.2 says `859.0.86.822' "both names a register AND carries the
        # store", because hi12 bit 4 is set.  But hi12 bit 11 -- the FORMAT
        # ESCAPE -- is set too, and this decoder's own escape rule says that
        # inside the escape bits[10:0] mean something else, which is why
        # hi12_text() does not print `ST' there.  Both cannot be right, and the
        # word is the ONLY site, so neither reading has a second data point.
        if not (hi & HI_ST):
            tail = ""
        elif hi & HI_ESC:
            tail = ("; hi12 bit 4 is set BUT SO IS THE FORMAT ESCAPE (bit 11), and inside "
                    "the escape this decoder does not read bit 4 as the store -- K3 sect. 5.2 "
                    "reads it as a store anyway.  CONFLICT, 1 site, UNRESOLVED")
        else:
            tail = ("; and hi12 bit 4 is SET, so it also stores -- to a target that is "
                    "mode-dependent and unproven off mode 2 (R2)")
        return ("register write: selector lo12[7:0]=%02X, %s (bit 11 is a SEPARATE "
                "FLAG -- the firmware builds it with a literal `INC 8, WA' on top of "
                "the low byte).  This selector's register is OPEN%s"
                % (lo_sel(w), "payload = addr8" if lo_imm(w) else "no payload", tail))

    if lo == 0x839:
        return ("lo12 0x839 -- selector OPEN (K3 sect. 5.4: 'sub-op 3 on register 1' "
                "under one field reading, a sixth register under the other); 2 sites "
                "in 3057")

    if cl == 8:
        return "class 8: post-sum step (rescale/round/saturate?), OPERATION UNKNOWN"

    # ★ WITHDRAWN: `hi12 == 0xC40 -> envelope / level detector'.  FALSIFIED at
    # ALL 61 SITES -- it fired on the reverb tank, on CHORUS and on the frame
    # terminator's neighbours.  The family is a 13-bit IMMEDIATE LOAD and is
    # rendered by the C-format block at the top of this function.
    if hi == 0x082:
        return "LFO / modulation-source read (INFERRED)"

    if cl == 6:
        return "table-lookup idiom, class-6 addr8 = table selector (INFERRED)"
    if cl == 4 and hi == 0x012:
        return "table-lookup idiom, third word (INFERRED)"

    if lo == 0x647:
        return "P-consumer, stores latch A (INFERRED)"
    if lo == 0x687:
        return "P-consumer, stores latch B (INFERRED)"
    if lo == 0x1D3:
        return "read into carry latch A (INFERRED)"
    if lo == 0x1D4:
        return "read into carry latch B (INFERRED)"

    if w == 0x212200000:
        return "plain store: mem[ptr] <- acc, taken BEFORE this word's ALU step (FORCED)"
    # NOTE: the old rule `hi12 == 0x212 -> writes mem[ptr], class-independent'
    # was WITHDRAWN by R2.  Bit 4's TARGET is mode-dependent: mem[ptr] is the
    # MODE-2 target.  Two mode-1 bit-4 words (w64/w71) have a DETERMINED
    # destination in the REGISTER space, and w60/w61 are adjacent mode-1 stores
    # with no pointer-moving word between them, so under a universal mem[ptr]
    # reading the first is provably dead -- the old rule manufactured four dead
    # stores in the 23-word output stage.  Bit 4 is now rendered as the flag
    # `ST' by hi12_text() and given no target unless the mode supplies one.
    if hi == 0x212 and (cl & 7) == 2:
        return "writes mem[ptr] (bit 4); mode 2, so the target IS the pointer"

    if hi == 0x102:
        return "gain multiply (same op in phaser all-pass and reverb diffuser)"

    # NOTE: there is deliberately NO `hi12[11:8]==A -> host-poke' rule any more.
    # `0A aa bb cc dd' is a HOST-STREAM coefficient packet, not an instruction
    # (PROVEN BY CONSTRUCTION, analysis/k5-output-stage.md sect. 1.3); the old rule
    # fired on genuine in-program words (A00.0.00.041 in CHORUS, A3C.D.9F.287 at
    # I-RAM 78) where it is meaningless.  Host packets are decoded by
    # host_packet() below, which only a host-stream viewer should call.

    # ★ SPECULATIVE: A3C.D.9F.287 (I-RAM 78) is the only class-D word and sits in
    # the output stage -- role unit 1 -> DO2 -> IC303.SDIB, a DO-write candidate.
    if w == 0xA3CD9F287:
        return ("output-stage word (unit 1 -> DO2 -> IC303.SDIB); the only class-D "
                "word, a DO-write candidate; its operation (f31=6) is OPEN")

    # ★ SPECULATIVE (S-5): A00.0.00.041 heads a fixed 3-word template; operands
    # SRC 0x01/ACT 0x01 stay dark but the structural role is established.
    if w == 0xA00000041:
        return "head of a fixed 3-word template (S-5); operands SRC 0x01/ACT 0x01 dark"

    # ★ SPECULATIVE TIER (goal 2026-09-06): render the prospective SRC/ACT codes,
    # LABELLED, so a speculative-tier word shows its adopted reading.  Mirrors
    # upd6383d.cpp; bases at the _ANCHORED_*_SPEC comment above.
    s, a = lo_src(w), lo_act(w)
    sr = ("SRC 0x00 = mem[ptr]/delay-RAM read" if s == LO_SRC_MEM0 else
          "SRC 0x08 = C-RAM[cursor] (the COEFFICIENT), MEASURED: the chorus LFO at iw89 "
          "reads L = 114 and acc = 114<<16 exactly, and 114 = C-RAM[0x00] = "
          "floor(0.5993*2^23/44100), the ROM's own ramp constant; the rival \"sample source\" "
          "is REFUTED from disk (SQUARING-MULTIPLY item B)" if s == LO_SRC_LFO else
          "SRC 0x0B = delay-read data register" if s == LO_SRC_DRD else
          "SRC 0x11 = ACCB (2nd accumulator)" if s == LO_SRC_ACCB else
          "SRC 0x13 = coef/wave table port" if s == LO_SRC_TABLE else
          "SRC 0x1C = control/mod source into MAC (100% MAC-consumed; LFO in mod fx, "
          "envelope/AGC in dynamics) -- NOT LFO-only: present in 19 non-LFO programs "
          "(dsp_datapath_fingerprint)" if s == LO_SRC_LFOOUT else None)
    ar = ("ACT 0x0C = delay READ" if a == LO_ACT_DELAY_RD else
          "ACT 0x08 = table-port multiply" if a == LO_ACT_TBL_MUL else
          "ACT 0x0B = delay-line access (READ/WRITE class-borne)" if a == LO_ACT_DELAY_ACC else
          "ACT 0x0D = delay/state MIXING: mem onto bus (universal; pair w/ 0x0E)" if a == LO_ACT_BIQ_D else
          "ACT 0x0E = delay/state MIXING: acc onto bus (universal; pair w/ 0x0D)" if a == LO_ACT_BIQ_E else None)
    if sr or ar:
        return ("SPECULATIVE (prospective, not measured): "
                + "; ".join(x for x in (sr, ar) if x))

    # ★ SPECULATIVE partial decode: class A always multiplies (P = coef x L) and
    # class 2 is the post-increment MAC -- established by the class.  A leftover
    # word in one of these classes with a real source has its multiply/MAC
    # decoded even when the accumulator-combine (f31) or a minor operand is open.
    cl = class4(w)
    if cl == 0xA:
        return ("SPECULATIVE: class-A multiply (P = coef x source 0x%02X); the "
                "source id / accumulator-combine f31=%d / ACT 0x%02X may be OPEN"
                % (s, hi_f31(hi12(w)), a))
    if (cl & 7) == 2 and s in _ANCHORED_SRC_SPEC:
        return ("SPECULATIVE: class-2 post-increment MAC (source 0x%02X); the "
                "accumulator-combine f31=%d and/or ACT 0x%02X are OPEN"
                % (s, hi_f31(hi12(w)), a))
    if cl == 0 and (lo12(w) & 0x800) and lo_ptrmode(w):
        return ("SPECULATIVE: lo12 bit-11 modifier word + pointer-mode "
                "(bit11-family); the base selector/register is OPEN")
    # Principled floor: a known accumulator op (f31 LOAD/ADD/HOLD) is a partial
    # decode even when addressing/operands are open.  Unknown f31 stays dark.
    f = hi_f31(hi12(w))
    if f in (HI_ACC_LOAD, HI_ACC_ADD, HI_ACC_HOLD):
        name = {HI_ACC_LOAD: "LOAD", HI_ACC_ADD: "ADD", HI_ACC_HOLD: "HOLD"}[f]
        return ("SPECULATIVE: accumulator op f31=%d (%s) is known; addressing "
                "class 0x%X and operands are OPEN" % (f, name, cl))
    return None


def host_packet(b5):
    """Decode a 5-byte HOST-STREAM coefficient packet `0A aa bb cc dd'.
    PROVEN BY CONSTRUCTION from the three Sub CPU writers LABEL_0387E6 /
    LABEL_038922 / LABEL_0388B3 (analysis/k5-output-stage.md sect. 1.3).
    -> (value24, tag) or None.  NEVER call this on an I-RAM word."""
    if len(b5) != 5 or b5[0] != 0x0A:
        return None
    aa, bb, cc, dd = b5[1], b5[2], b5[3], b5[4]
    return (((aa & 0x7F) << 17) | (bb << 9) | (cc << 1) | (dd >> 7), dd & 0x7F)


# --- the ALU rendering (upd6383d.cpp text(), the `decoded' branch) ----------
#   ★ 2026-09-13: the three codes ANCHORED this session had no NAME, so every word
#   sourcing them printed `?' next to a real mnemonic -- a decoded word that reads
#   as undecoded.  Caught when sect. 106 admitted 82 words and they came out as
#   `mac.b ?,c+'.  The names are the anchorings' own wording, not new claims.
_SRC_NAME = {LO_SRC_MEM: "(p)", LO_SRC_ACC: "acc", LO_SRC_TA: "ta", LO_SRC_TB: "tb",
             LO_SRC_MEM0: "(p)0",     # sect. 233: mem[ptr] / delay-RAM read
             LO_SRC_DRD: "dr",        # the delay-read data register
             LO_SRC_LFO: "c"}         # C-RAM[cursor] -- THE COEFFICIENT
_ACC_MNEM = {HI_ACC_LOAD: "ld", HI_ACC_ADD: "mac"}      # else the class-8 post-sum step
_ACT_SUFFIX = {LO_ACT_CAP_TA: ".ta", LO_ACT_CAP_TA2: ".ta2",
               LO_ACT_CAP_TB: ".tb", LO_ACT_ST_BUS: ".st",
               # the accumulator's input term comes from the BUS, so the
               # hi12[3:1] prefix loses its meaning: `ld.b' and `mac.b' both
               # compute `bus + P'.  Both are printed -- hi12[3:1] IS a field.
               LO_ACT_ACC_BUS: ".b"}


def _alu_mnemonic(w):
    return _ACC_MNEM.get(hi_f31(hi12(w)), "post") + _ACT_SUFFIX.get(lo_act(w), "")


def text(w, at=None):
    """One-line text for a single word (upd6383d.cpp text()).  `at' = the word's
    I-RAM index if the caller knows it; only the C00 self-address check uses it."""
    hi, cl, ad, lo = fields(w)
    dd = ad - 256 if ad >= 128 else ad          # addr8 is a SIGNED post-increment

    if decoded(w):
        if is_setvec(w):
            unit, a = VECTOR_LO12[lo], c_a(w)
            m = VECTOR_MEANING.get((unit, a))
            return "setvec  unit%d,#%d%s" % (unit, a, ("   ; " + m) if m else "")
        if hi == 0x000 and lo == 0x000:
            return "nop"
        if is_ldptr(w):
            return "ldptr   #$%02x" % ad
        if is_ldptrd(w):
            return "ldptr.d #$%02x" % ad
        if is_rstcur(w):
            return "rstcur"
        #   ★ THE DELAY ESCAPE RENDERS AS WHAT IT IS.  Placed BEFORE the ALU branch on purpose:
        #   a class-1 escape never reaches the ALU (the device's `is_dram' branch returns first),
        #   so rendering it through the ALU path produced `ld ?' -- a decoded word whose operand
        #   could not be named, because the operand is a delay-DRAM address and not an ALU source.
        #   `k' is the index of this escape within its own body; the address is DESCRIPTOR_CELL[k]
        #   + G by the IDENTITY map (adjudication-round5, PROVEN BY CONSTRUCTION), which is why
        #   no address appears in the word.
        #   ★ THE WRAP WORD RENDERS AS ITS OWN OPERATION.  It is `f31 == 2' like a HOLD but it
        #   does something else entirely -- `acc <- (datum(acc) & L) << ACC_SHIFT', the LFO's
        #   modulus (§224/§225, shipped).  Rendering it as an ordinary accumulator op would hide
        #   the one instruction in the corpus that wraps.
        if _is_wrapword(w):
            return "wrap    acc,c+          ; acc <- datum(acc) & coef  (LFO modulus)"
        if is_c40(w):
            return "ldreg   r%02X,#%d          ; immediate -> the register lo12 selects" % (
                lo12(w) & 0xFF, c_a(w))
        #   ★★★★★ 2026-09-14 (N-INPUT-GATE-OPENED sect. 122): THE OTHER ELEVEN C-FORMAT WORDS.
        #   `A' is an I-RAM ADDRESS on these too, and `B' is a second field that is NOT an address
        #   -- both MEASURED, and neither by carrying the `0xC40' family's rule outward:
        #     * `cfmt_addr.py': all ELEVEN payloads land inside the region that carries them
        #       (kernel 0..59, epilogue 60..82), p = 6.6e-9 under a uniform 8-bit payload;
        #     * `kernel_homolog.py --reloc': against the SX-WSA1R's byte-homologous copy of this
        #       header, `A' tracks the code relocation EXACTLY in 4 of 4 comparable pairs while
        #       `B' and `f31' are IDENTICAL across the two products at all five positions.
        #   The `B' field is printed because it is real and unexplained, not decoration.
        if c_format(w):
            return "ldreg   r%02X,#iw%d,%d       ; I-RAM address + a second field (B)" % (
                lo12(w) & 0xFF, c_a(w), c_b(w))
        if is_terminator(w):
            #   ⛔ sect. 124: NOT `unit%d' any more.  `addr8' is 0x0E/0x0F in the KN5000 and 0x4F
            #   in all 53 SX-WSA1R images, so the unit-index reading cannot be an ISA rule -- it
            #   was one product's value set.  Print the operand, name nothing it cannot know.
            return "endblk  #%02X             ; END OF BLOCK -- the last word of a block" % addr8(w)
        if is_dram(w) and dram_dir(w):
            return "dly.%s  dsc[k]%s" % ("r" if dram_dir(w) == "READ" else "w",
                                         "" if dd == 0 else ",p%+d" % dd)

        # THE ALU, rendered as the two fields it really is: the OPERATION from
        # hi12[3:1] and the ROUTING from lo12.  The optional multiply / store /
        # pointer controls live outside both.
        #   ★ sect. 128: a MODE-1 word's memory operand is `reg[addr8]', not `mem[ptr]' -- the
        #   device routes it that way (`upd6383.cpp' `regfile'), so the mnemonic must say so or a
        #   decoded word would print an operand it does not use.  Same lesson as the delay
        #   escape's `ld ?' (above): render what the word reads.
        _m1 = is_mode1(w)
        _src = _SRC_NAME.get(lo_src(w), "?")
        if _m1 and lo_src(w) in (LO_SRC_MEM0, LO_SRC_MEM):
            _src = "r%02X" % addr8(w)
        s = "%-7s %s" % (_alu_mnemonic(w), _src)
        # ★ FETCH IS NOT ADVANCE, in the MNEMONIC too.  `,c+' = fetches one
        # coefficient AND post-increments the cursor (class A).  `,c' = bit 23 is
        # set so a coefficient IS fetched, but the cursor does not move (class 8,
        # K4 FORCED) -- and this model gives that word no multiply either.
        if coeff_consumer(w):
            s += ",c+"
        elif cursor_fetch(w):
            s += ",c"
        if (cl & 7) == 2:
            s += ",(p)%+d" % dd
        if hi & HI_ST:
            s += (" ; store SUPPRESSED (bit7)" if st_suppressed(w)
                  else (" ; r%02X<-acc, acc=0" % addr8(w)) if _m1
                  else " ; mem[p]<-acc, acc=0")
        # ★ END OF BLOCK SURVIVES THE DECODE.  A decoded word prints no
        # [annotation], and MEASURED that costs nothing on 381 of the 384 decoded
        # words that carry one -- "writes mem[ptr] (bit 4)", "P-consumer stores
        # latch A/B", "read into carry latch A/B", "gain multiply" and "class 8
        # post-sum step" are all things the FIELD DECODE now says properly, and
        # the two AGREE (lo12 0x1D4 = src mem[p] + action CAP_TB really is "read
        # into carry latch B", which is a nice corroboration of both).  The
        # remaining three are END-OF-BLOCK words, and that is a CONTROL-FLOW fact
        # orthogonal to the ALU: the word still performs its datapath work AND
        # ends the block.  (⛔ sect. 128 CORRECTS the old parenthetical "class 1
        # cannot reach here": mode-1 words DO reach this renderer now, which is
        # why the source and store operands above are register-named for them.
        # The unit-tagged CALL/RETURN form is still not claimed.)
        if is_end(w):
            s += ("; " if (hi & HI_ST) else " ; ") + "END OF BLOCK (falls through)"
        return s

    # TWO greppable forms, because there are two kinds of not-decoded.
    # Ten nibbles: a 36-bit word prints as ten, not nine.
    addr_only = addressing_only(w)
    s = "%s   0x%010X   ; %03X.%X.%02X.%03X" % ("~word" if addr_only else "?word",
                                                w & WORD_MASK, hi, cl, ad, lo)
    if c_format(w):
        # in this family the printed class4|addr8 split is a FICTION -- say so
        s += "  {C-fmt A=%d B=%d}" % (c_a(w), c_b(w))
    if addr_only:
        # what a `~word' actually DOES when the device executes it
        if c_format(w):
            s += "  {addr: none -- C-format, SAFE NO-OP}"
        else:
            s += "  {addr: %s mem[p]%s, p%+d}" % (
                "ST" if ((hi & HI_ST) and not st_suppressed(w)) else "rd",
                (", cur+" if coeff_consumer(w) else ", cur") if cursor_fetch(w) else "",
                dd)
    s += "  hi12{%s}" % hi12_text(hi)
    if cursor_fetch(w):
        # FETCH is not ADVANCE (K4, FORCED).  `cur+' means "fetches AND moves
        # the cursor on"; `cur' means "fetches, cursor stays put".  Only
        # class4 == 0xA advances.
        s += " cur+" if coeff_consumer(w) else " cur"
    note = annotate(w, at)
    if note is not None:
        s += "  [%s]" % note
    if is_end(w) and (hi & HI_ST) and cl == 1 and ad in (0x0E, 0x0F):
        s += "  [!! bit 4 = store, yet addr8 is the unit index -- UNEXPLAINED]"
    return s


def cursor_addresses(words):
    """For each word index, the absolute C-RAM coefficient address 0x00 + k of a
    class-A word (else None).  k counts class-A words since the last rstcur or the
    program start -- exactly the disassembler's backward scan.  `base' is added by
    the caller for the unit-1 reverb bank (0x90)."""
    out = [None] * len(words)
    k = 0
    for i, w in enumerate(words):
        if is_rstcur(w):
            k = 0
        if coeff_consumer(w):
            out[i] = k
            k += 1
    return out
