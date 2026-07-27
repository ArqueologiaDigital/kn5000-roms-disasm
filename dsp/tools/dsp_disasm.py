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
    if lo_src(w) not in _ANCHORED_SRC or lo_act(w) not in _ANCHORED_ACT:
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
        if hi_f31(hi12(w)) != 2:
            return False
    f = hi_f31(hi12(w))
    if f in (HI_ACC_LOAD, HI_ACC_ADD):
        return True
    if f == HI_ACC_HOLD:
        return cl == 8
    return False


def decoded(w):
    """Is this a form with a real mnemonic -- i.e. one a core could EXECUTE?
    (upd6383d.cpp decoded().)"""
    hi, cl, ad, lo = fields(w)
    if hi == 0x000 and cl == 2 and ad == 0x00 and lo == 0x000: return True  # nop
    if is_ldptr(w) or is_rstcur(w) or is_ldptrd(w):            return True
    if is_setvec(w):                                           return True
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
        a, b = c_a(w), c_b(w)
        if is_setvec(w):                       # decoded(); never reaches here
            return None
        # THE PAYLOAD RULE IS FAMILY-LOCAL (K3 sect. 5.3): `A = imm13 >> 5' is
        # MEASURED 57/57 inside (hi12 & 0xFFE) == 0xC40 and 2/11 outside, so the
        # A/B split is asserted only here.  NOT extended to the other prefixes.
        if is_c40(w):
            return ("C-format IMMEDIATE LOAD: A=%d B=%d (imm13 0x%04X = %d*32, "
                    "MEASURED 57/57 in this sub-family); destination register "
                    "lo12=%03X UNKNOWN" % (a, b, c_imm13(w), a, lo))
        if hi == 0xC00:
            own = ("= its own I-RAM address" if at is not None and at >= 0 and a == at
                   else "(I-RAM index?)")
            return ("WAIT / SYNC (INFERRED): A=%d %s, B=%d = the event; both C00 "
                    "words in the machine encode their own address (2/2)"
                    % (a, own, b))
        if lo in (0x820, 0x825, 0x827, 0x822):
            return ("C-format word with a pointer-load lo12; the A/B split is NOT "
                    "established for this sub-family (B in {0,17,18,23}) -- residue "
                    "A=%d B=%d shown for the record" % (a, b))
        return ("C-format: bits [24:12] are one 13-bit IMMEDIATE reaching into "
                "hi12 bit 0, not class+addr; A=%d B=%d" % (a, b))

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
_SRC_NAME = {LO_SRC_MEM: "(p)", LO_SRC_ACC: "acc", LO_SRC_TA: "ta", LO_SRC_TB: "tb"}
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

        # THE ALU, rendered as the two fields it really is: the OPERATION from
        # hi12[3:1] and the ROUTING from lo12.  The optional multiply / store /
        # pointer controls live outside both.
        s = "%-7s %s" % (_alu_mnemonic(w), _SRC_NAME.get(lo_src(w), "?"))
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
        # ends the block.  (class 1 cannot reach here, so the unit-tagged
        # CALL/RETURN form is unreachable by construction.)
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
