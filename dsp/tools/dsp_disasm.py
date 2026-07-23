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
  * Only the SIX established forms get a real mnemonic; every other word is
    emitted as `?word 0x0XXXXXXXXX' with its field breakdown, hi12 flags, and a
    structural ANNOTATION where the corpus has one.  A landmark is not a decode:
    annotated words keep the greppable `?' prefix.  NEVER invent a mnemonic.
  * A class-A word's coefficient has a KNOWN ABSOLUTE C-RAM address (cursor base
    0x00 MEASURED, +1 per class-A word, reset by rstcur); it is printed as
    `; C-RAM[0xNN]'.  No absolute is invented for the D-RAM state operand.

Word format (MEASURED): 36 bits, right-aligned big-endian in 5 bytes; bits
36..39 always 0.  Field map (INFERRED, notes/kn5000-dsp-encoding.md sect. 8):

    35            24 23  20 19    12 11             0
   +----------------+------+--------+----------------+
   |      hi12      |class4|  addr8 |      lo12      |
   +----------------+------+--------+----------------+
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
    """bit 23 (== class4 bit3) = CURSOR-FETCH enable (NOT multiply-enable)."""
    return bool((w >> 23) & 1)


def coeff_consumer(w):
    """STRICT coefficient consumer: class4 == 0xA (advances the cursor by one)."""
    return class4(w) == 0xA


def is_rstcur(w):
    return hi12(w) == 0x801 and class4(w) == 0 and addr8(w) == 0x00 and lo12(w) == 0x021


def is_end(w):
    """bit 10 with bit 11 clear = END OF BLOCK (the word still does its work)."""
    hi = hi12(w)
    return bool((hi & HI_END) and not (hi & HI_ESC))


def decoded(w):
    """Is this one of the six established forms? (upd6383d.cpp decoded())."""
    hi, cl, ad, lo = fields(w)
    if hi == 0x000 and cl == 2 and ad == 0x00 and lo == 0x000: return True  # nop
    if hi == 0x801 and cl == 0 and lo == 0x821:                return True  # ldptr
    if hi == 0x801 and cl == 0 and ad == 0x00 and lo == 0x021: return True  # rstcur
    if hi == 0x202 and cl == 0xA and lo == 0x1D5:              return True  # mac
    if hi == 0x202 and cl == 0xA and lo == 0x1D4:              return True  # mac.lb
    if hi == 0x212 and cl == 0xA and lo == 0x407:              return True  # mulst
    return False


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


def annotate(w):
    """MEASURED structural landmarks whose SEMANTICS are unknown.  Mirrors
    upd6383d.cpp annotate() verbatim.  Returns a string or None."""
    hi, cl, ad, lo = fields(w)

    if is_end(w):
        if cl == 1 and ad == 0x0E:
            return "END OF BLOCK, unit 0 -- CALL/RETURN -- and still performs the rest of the word"
        if cl == 1 and ad == 0x0F:
            return "END OF BLOCK, unit 1 -- CALL/RETURN -- and still performs the rest of the word"
        return "END OF BLOCK (falls through) -- and still performs the rest of the word"

    if hi == 0x880 and cl == 1 and ad == 0x60:
        return "external-DRAM bracket OPEN (INFERRED)"
    if hi == 0x880 and cl == 1 and ad == 0x20:
        return "external-DRAM bracket CLOSE (INFERRED)"
    if hi == 0x880 and cl == 1 and ad == 0x30:
        return "framing word, carries no DRAM information (MEASURED)"

    if w == 0x104200000:
        return "all-pass marker -- step UNKNOWN"
    if w == 0x012200680:
        return "all-pass: d_in <- x + t (the WRITE), bit 4 breaks the 2-permutation"
    if w == 0x000200419:
        return "all-pass: y <- d_out - t (its partner)"

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
    if hi == 0xC40:
        return "envelope / level detector (INFERRED)"

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
        return "plain store: mem[ptr] <- acc (nothing asked of lo12)"
    if hi == 0x212:
        return "writes mem[ptr] (bit 4), class-independent"

    if hi == 0x102:
        return "gain multiply (same op in phaser all-pass and reverb diffuser)"

    if (hi & 0xF00) == 0xC00:
        return "hi12[11:8]==C: bits [23:12] are a 12-bit IMMEDIATE, not class+addr"
    if (hi & 0xF00) == 0xA00:
        return "hi12[11:8]==A: host-poke data form, bits [23:12] are immediate"

    return None


def text(w):
    """One-line text for a single word (upd6383d.cpp text())."""
    hi, cl, ad, lo = fields(w)
    dd = ad - 256 if ad >= 128 else ad          # addr8 is a SIGNED post-increment

    if decoded(w):
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
    s += "  hi12{%s}" % hi12_text(hi)
    if cursor_fetch(w):
        s += " cur+"
    note = annotate(w)
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
