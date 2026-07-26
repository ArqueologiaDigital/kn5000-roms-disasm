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

The discipline is the whole point and is preserved exactly:

  * hi12 is NOT an opcode.  It is a HORIZONTAL MICROWORD of independent enable
    bits (MEASURED, notes/kn5000-dsp-hi12.md).  It is rendered as FLAGS + an
    explicit RESIDUE, never as an opaque 12-bit number.
  * Only ESTABLISHED forms get a real mnemonic; every other word is emitted as
    `?word 0x0XXXXXXXXX' with its field breakdown, hi12 flags, and a structural
    ANNOTATION where the corpus has one.  A landmark is not a decode: annotated
    words keep the greppable `?' prefix.  NEVER invent a mnemonic.  Words whose
    OPERATION is now determined but whose OPERAND ENCODING is not (the external
    delay-DRAM read/write, the C-format immediate load) stay `?word' and are
    reported separately by status(); no coverage number launders one into the
    other.
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

2026-07-26, later -- the K3/K4/R2/R3 ADJUDICATION pass changed it again
(analysis/isa-adjudication.md).  ADDED:

  * `ldptr.d #$NN' (801.0.NN.825), the DELAY-DESCRIPTOR pointer -- tier 1, both
    halves PROVEN BY CONSTRUCTION by R3 (encoding from the writer, space from
    the tag).  3 sites, all in the resident kernel.
  * the delay-DRAM family widened from `hi12 == 0x880, addr8 in {20,60}' to
    R2's real predicate (addressing mode 1 WITH the format escape, C-format
    guarded), carrying R3's address model in the annotation.  Tier 2: the
    address is a descriptor cell from an implicit cursor, so the word still
    cannot be executed alone.
  * the internal REGISTER FILE annotation (mode 1 without the escape), with
    named cells 0x06/0x86 = per-unit OUTPUT LEVEL and 0x50/0xD0 = per-unit
    STATE-BLOCK BASE.

WITHDRAWN in the same pass:

  * `880.1.30.* = framing word, carries no DRAM information'.  It is the FIRST
    DRAM ACCESS of a body, 37 of 38 distinct images (R3 sect. 6.2).
  * `addr8 selects the DRAM direction' beyond 2D4/655/64B.  MULTI TAP DELAY's
    tap READS land on 880.1.20.2C7 (R3 sect. 6.3).
  * `hi12 == 0x212 writes mem[ptr], class-independent'.  Bit 4's target is
    MODE-DEPENDENT; mem[ptr] is the mode-2 target (R2).

FIXED: annotate() violated its own stated precedence rule -- the C-format block
sat BELOW the delay-DRAM rule and survived only because that rule tested
hi12 == 0x880 exactly.  Widening the family made it a live bug (the reverb's
C40.1.80.000 matched), which is exactly the error R3 made.  C-format is now
first.  See c_format() vs is_c40() for the two predicates that were conflated.
"""

WORD_MASK = 0xFFFFFFFFF          # 36 bits

# --- hi12 microword bits (upd6383d.h) --------------------------------------
HI_ESC = 1 << 11                 # FORMAT ESCAPE (bits[10:0] mean something else)
HI_END = 1 << 10                 # END OF BLOCK, only when HI_ESC clear
HI_ST  = 1 << 4                  # WRITE ACCUMULATOR -> mem[ptr]


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
# TWO DIFFERENT PREDICATES, and conflating them caused a committed error --
# ADJUDICATED 2026-07-26, analysis/isa-adjudication.md sect. 1:
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
#               B == 0.  analysis/k3-pointers.md.
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
def hi_f31(hi): return (hi >> 1) & 7      # 8/8 values seen


def hi_residue(hi):
    """bits with no reading at all: 7, 6, 5, 0 (+ 10 inside the escape)."""
    known = HI_ESC | HI_ST | 0x300 | 0x00E     # esc, store, f98, f31
    if not (hi & HI_ESC):
        known |= HI_END                        # END only outside the escape
    return hi & ~known


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
    C00.A.47.407 at I-RAM 82, and zero body words are -- so no committed listing
    changes.  The guard is here because the hazard is real, not because it bit.

    FETCH IS NOT ADVANCE (K4, FORCED).  bit 23 says a coefficient is fetched;
    only class4 == 0xA moves the cursor on.  The PARAMETRIC EQ body's ten
    class-8 words sit inside a cursor map proven to the bit at 6 cells per
    band; if class 8 advanced, band k would start at cell 7k and all 60 named
    roles would shift.  MEASURED over the 2974-word body corpus: the only
    classes that set bit 23 are 8 (42) and A (822).  The KERNEL additionally
    has class 9 (4), C (1) and D (1), so a core must NOT assume
    `bit 23 => class 8 or A'."""
    return class4(w) == 0xA and not c_format(w)


def is_rstcur(w):
    return hi12(w) == 0x801 and class4(w) == 0 and addr8(w) == 0x00 and lo12(w) == 0x021


def is_end(w):
    """bit 10 with bit 11 clear = END OF BLOCK (the word still does its work)."""
    hi = hi12(w)
    return bool((hi & HI_END) and not (hi & HI_ESC))


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


def is_setvec(w):
    """C-format immediate load into a per-unit CALL VECTOR register."""
    return is_c40(w) and lo12(w) in VECTOR_LO12


# --- named cells of the internal REGISTER FILE (addressing mode 1, no escape)
# bit 7 of the index is the effect unit, so every role comes in a matched pair.
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


def decoded(w):
    """Is this a form with a real mnemonic -- i.e. one a core could EXECUTE?
    (upd6383d.cpp decoded().)  Seven forms; `nop' is the one that rests on
    position rather than construction (see the status table below)."""
    hi, cl, ad, lo = fields(w)
    if hi == 0x000 and cl == 2 and ad == 0x00 and lo == 0x000: return True  # nop
    if hi == 0x801 and cl == 0 and lo == 0x821:                return True  # ldptr
    if hi == 0x801 and cl == 0 and lo == 0x825:                return True  # ldptr.d
    if hi == 0x801 and cl == 0 and ad == 0x00 and lo == 0x021: return True  # rstcur
    if hi == 0x202 and cl == 0xA and lo == 0x1D5:              return True  # mac
    if hi == 0x202 and cl == 0xA and lo == 0x1D4:              return True  # mac.lb
    if hi == 0x212 and cl == 0xA and lo == 0x407:              return True  # mulst
    if is_setvec(w):                                           return True  # setvec
    return False


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
    falsifies in R3.

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

    DIRECTION: FORCED for the all-pass core's own pair (880.1.60.2D4 read,
    880.1.20.655 write; the opposite assignment has zero survivors in all three
    machine models -- analysis/r1-allpass-motif.md sect. 5, F1).  It does NOT
    generalise: `addr8' does not select direction.  R3 sect. 6.3's cursor
    alignment puts three of MULTI TAP DELAY's four tap READS on 880.1.20.2C7
    and its line WRITE on 880.1.60.000.  Direction must live in lo12/hi12."""
    return (hi12(w) & HI_ESC) and class4(w) == 1 and not c_format(w)


DRAM_FORCED = {(0x60, 0x2D4): "READ", (0x20, 0x655): "WRITE"}


def status(w):
    """'DECODED' | 'DETERMINED' | 'MEASURED' | None -- what is known about the
    word's OPERATION.  Used by tools/dsp_coverage.py; deliberately does NOT
    promote anything into decoded()."""
    if decoded(w):
        return "DECODED"
    if is_dram(w):
        return "DETERMINED" if (addr8(w), lo12(w)) in DRAM_FORCED else "MEASURED"
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

    PRECEDENCE MATTERS.  The C-format rule must come BEFORE any rule keyed on
    lo12 or on the class4 nibble, because in that family class4|addr8 is not a
    class and a pointer -- it is immediate data."""
    hi, cl, ad, lo = fields(w)

    # ---- C-FORMAT FIRST.  bits [24:12] are one immediate --------------------
    # This block MUST precede every rule keyed on class4 or addr8.  It used to
    # sit below the delay-DRAM rule and got away with it only because that rule
    # tested `hi12 == 0x880' exactly; the moment the DRAM family was widened to
    # R2's real predicate (mode 1 + ESCAPE) the reverb's C40.1.80.000 started
    # matching it.  That is precisely R3's error -- see
    # analysis/isa-adjudication.md sect. 1.
    if c_format(w):
        a, b = c_a(w), c_b(w)
        if is_setvec(w):                       # decoded(); never reaches here
            return None
        if is_c40(w):
            return ("C-format IMMEDIATE LOAD: A=%d B=%d (imm13 0x%04X = %d*32, "
                    "MEASURED 57/57 in this sub-family); destination register "
                    "lo12=%03X UNKNOWN" % (a, b, c_imm13(w), a, lo))
        if hi == 0xC00:
            own = ("= its own I-RAM address" if at is not None and a == at
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

    # ---- external delay DRAM.  ADDRESS SOURCE now known, DIRECTION mostly not
    if is_dram(w):
        role = DRAM_FORCED.get((ad, lo))
        base = ("external delay-DRAM access; address = DESCRIPTOR_CELL[cursor] "
                "+ G, from the host bank behind pointer ...825 / tag 0x4C "
                "(R3, PROVEN BY CONSTRUCTION) -- one cell per DRAM word, in "
                "program order, so it is NOT in this word")
        if role:
            extra = ("; read data visible 2-5 words later (R1 F6)"
                     if role == "READ" else
                     "; write data staged by the preceding bit-4 store, 44/44")
            return ("external delay-DRAM %s (DETERMINED, R1 F1 -- the opposite "
                    "direction has zero survivors in all 3 models)%s. %s"
                    % (role, extra, base))
        if ad == 0x30:
            return (base + ". addr8 0x30 marks the FIRST DRAM access of a body "
                    "(37 of 38 distinct images, R3 sect. 6.2)")
        return (base + ". DIRECTION UNKNOWN: addr8 does NOT select it -- MULTI "
                "TAP DELAY's tap READS land on 880.1.20.2C7 and its line WRITE "
                "on 880.1.60.000 (R3 sect. 6.3 falsifies the old addr8 rule)")

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

    if lo in VECTOR_LO12:
        return ("writes the unit-%d CALL VECTOR (I-RAM %d) -- DETERMINED destination; "
                "this SOURCE form is the canned boot default, its source field is OPEN"
                % (VECTOR_LO12[lo], 64 if lo == 0x445 else 71))

    if hi == 0x092 and cl == 0xA and lo == 0x200:
        return "LFO: phase += increment (increment = f/44100 in Q0.23)"
    if hi == 0x094 and cl == 0xA and lo == 0x200:
        return "LFO: phase wrap, consumes the constant 0x7FFFFF (29/29)"

    # ---- mode 1 WITHOUT the escape = the internal REGISTER FILE -------------
    # R2 sect. 1: index space shared with the host's own `000.1.NN.000', which
    # the host stream proves auto-increments.  bit 7 of the index = the effect
    # unit (K4, FORCED: 368 host packets / 23 indices all < 0x80 in unit-0
    # streams, 60 / 5 all >= 0x80 in unit-1 streams, and the boot blob writes
    # the matched pair 000.1.06.000 / 000.1.86.000 back to back).
    if (cl & 7) == 1:          # class 1 and class 9 (= mode 1 + cursor fetch)
        role = REGISTER_ROLE.get(ad)
        unit = "unit %d" % (1 if ad & 0x80 else 0)
        if role:
            return "internal register file [%02X] -- %s, %s" % (ad, role, unit)
        return ("internal register file [%02X], %s (bit 7 = the unit); this "
                "index has no named role yet" % (ad, unit))

    if lo in (0x820, 0x825, 0x827, 0x822):
        return "pointer-load family sibling, target register UNKNOWN"

    if cl == 8:
        return "class 8: post-sum step (rescale/round/saturate?), OPERATION UNKNOWN"

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
    # was WITHDRAWN by R2.  bit 4's TARGET is mode-dependent: mem[ptr] is the
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
        if hi == 0x000:
            return "nop"
        if hi == 0x801 and lo == 0x821:
            return "ldptr   #$%02x" % ad
        if hi == 0x801 and lo == 0x825:
            return "ldptr.d #$%02x" % ad
        if hi == 0x801:
            return "rstcur"
        if hi == 0x202 and lo == 0x1D5:
            return "mac     (p)%+d" % dd
        if hi == 0x202:
            return "mac.lb  (p)%+d" % dd
        return "mulst   (p)%+d" % dd

    # the greppable form: ten nibbles for a 36-bit word
    s = "?word   0x%010X   ; %03X.%X.%02X.%03X" % (w & WORD_MASK, hi, cl, ad, lo)
    if c_format(w):
        # in this family the printed class4|addr8 split is a FICTION -- say so
        s += "  {C-fmt A=%d B=%d}" % (c_a(w), c_b(w))
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
