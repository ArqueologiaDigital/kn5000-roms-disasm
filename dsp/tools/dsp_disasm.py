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
# link value carries 0xC41 and not 0xC40).  MEASURED over the whole corpus:
# every one of the 11 distinct imm13 values of the 0xC40/0xC41 family, across
# all 61 occurrences, is a multiple of 32 -- so the payload is the 8-bit field
# [24:17] and the low five bits [16:12] are a separate small field.
# (analysis/k5-output-stage.md sect. 2.3.)  The family PREDICATE must therefore
# mask hi12 bit 0 away: (hi12 & 0xFFE) == 0xC40, never hi12 == 0xC40.
def c_format(w):  return (hi12(w) & 0xF00) == 0xC00
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
    changes.  The guard is here because the hazard is real, not because it bit."""
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
    return (hi12(w) & 0xFFE) == 0xC40 and lo12(w) in VECTOR_LO12


def decoded(w):
    """Is this a form with a real mnemonic -- i.e. one a core could EXECUTE?
    (upd6383d.cpp decoded().)  Seven forms; `nop' is the one that rests on
    position rather than construction (see the status table below)."""
    hi, cl, ad, lo = fields(w)
    if hi == 0x000 and cl == 2 and ad == 0x00 and lo == 0x000: return True  # nop
    if hi == 0x801 and cl == 0 and lo == 0x821:                return True  # ldptr
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
    """external delay-DRAM access word.  addr8 0x60 / 0x20 = READ / WRITE:
    FORCED for the all-pass core's own pair (880.1.60.2D4 read, 880.1.20.655
    write) -- the opposite assignment has zero survivors in all three machine
    models searched (analysis/r1-allpass-motif.md sect. 5, F1).  Extending the
    direction to the OTHER lo12 values of the same addr8 is INFERRED, and
    annotate() says so."""
    return hi12(w) == 0x880 and class4(w) == 1 and addr8(w) in (0x20, 0x60)


DRAM_FORCED = {(0x60, 0x2D4): "READ", (0x20, 0x655): "WRITE"}


def status(w):
    """'DECODED' | 'DETERMINED' | 'MEASURED' | None -- what is known about the
    word's OPERATION.  Used by tools/dsp_coverage.py; deliberately does NOT
    promote anything into decoded()."""
    if decoded(w):
        return "DECODED"
    if is_dram(w):
        return "DETERMINED" if (addr8(w), lo12(w)) in DRAM_FORCED else "MEASURED"
    if (hi12(w) & 0xFFE) == 0xC40:
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

    if is_end(w):
        if cl == 1 and ad == 0x0E:
            return "END OF BLOCK, unit 0 -- CALL/RETURN -- and still performs the rest of the word"
        if cl == 1 and ad == 0x0F:
            return "END OF BLOCK, unit 1 -- CALL/RETURN -- and still performs the rest of the word"
        return "END OF BLOCK (falls through) -- and still performs the rest of the word"

    # ---- external delay DRAM.  DIRECTION forced, ADDRESS SOURCE open --------
    if hi == 0x880 and cl == 1 and ad in (0x20, 0x60):
        role = DRAM_FORCED.get((ad, lo))
        if role:
            extra = ("; read data visible 2-5 words later (R1 F6)"
                     if role == "READ" else
                     "; write data staged by the preceding bit-4 store, 44/44")
            return ("external delay-DRAM %s (DETERMINED, R1 F1 -- the opposite "
                    "direction has zero survivors in all 3 models)%s" % (role, extra))
        return ("external delay-DRAM access, addr8 %02X; direction READ/WRITE from "
                "addr8 is INFERRED here (FORCED only for 60.2D4 / 20.655)" % ad)
    if hi == 0x880 and cl == 1 and ad == 0x30:
        return "framing word, carries no DRAM information (MEASURED)"

    # ---- C-FORMAT: bits [24:12] are one immediate ---------------------------
    if c_format(w):
        a, b = c_a(w), c_b(w)
        if is_setvec(w):                       # decoded(); never reaches here
            return None
        if (hi & 0xFFE) == 0xC40:
            return ("C-format IMMEDIATE LOAD: A=%d B=%d (imm13 0x%04X = %d*32, "
                    "MEASURED 61/61); destination register lo12=%03X UNKNOWN"
                    % (a, b, c_imm13(w), a, lo))
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
    if hi == 0x212:
        return "writes mem[ptr] (bit 4), class-independent"

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
        s += " cur+"
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
