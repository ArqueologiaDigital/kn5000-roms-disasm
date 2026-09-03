#!/usr/bin/env python3
"""INSERT WAVE 21's evidence blocks into the two .s files this lane owns.

WHAT QUESTION THIS ANSWERS
  Not a question -- an application.  notes/w21_lsi_gate_and_keyscaling.py is the probe
  that establishes the facts; this script is what puts them next to the code, once, so
  the next reader of `Pack104_SetInputs_PartRecord` or of a `LinCoef_*` table does not
  have to find the note first.

  It ADDS a `★ WAVE 21` block to the tail of eleven existing headers and CHANGES NOTHING
  ELSE -- no rename, no reword.  scripts/analysis/assert_comments_preserved.py --base main
  is the gate that says so.

  ⚠ BYTES ONLY.  The sources are UTF-8 and this tree has emptied a 1.4 MB file once by
  round-tripping one through latin-1 with a `★` in it.  Read and write bytes; never
  decode.

RUN
    python3 notes/w21_lsi_gate_document.py           # insert (idempotent: refuses twice)
    python3 notes/w21_lsi_gate_document.py --check   # all eleven blocks present
"""
import io, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if not os.path.isdir(os.path.join(ROOT, "prom_c")):
    raise SystemExit("run this from inside the wsa1 tree: %s has no prom_c/" % ROOT)

SEP = b"; --------------------------------------------------------------------------\n"
SEP2 = b"; ----------------------------------------------------------------------------\n"


CHECK = "--check" in sys.argv


def insert_before_label(path, label, block):
    raw = open(path, "rb").read()
    marker = block.encode("utf-8").split(b"\n")[1][:60]
    lab = label.encode() + b":"
    if CHECK:
        i = raw.find(lab)
        ok = i >= 0 and marker in raw[max(0, i - 6000):i]
        print("  [%s] %-46s %s" % ("ok" if ok else "MISSING", label,
                                   os.path.basename(path)))
        return ok
    lines = raw.split(b"\n")
    tgt = None
    for i, ln in enumerate(lines):
        if ln == label.encode() + b":":
            tgt = i
            break
    if tgt is None:
        raise SystemExit("label %s not found in %s" % (label, path))
    # walk back over the closing separator of the existing header
    j = tgt - 1
    while j >= 0 and lines[j].strip() == b"":
        j -= 1
    if not lines[j].startswith(b"; ---"):
        raise SystemExit("no separator before %s (saw %r)" % (label, lines[j][:60]))
    ins = block.encode("utf-8").split(b"\n")
    if ins and ins[-1] == b"":
        ins = ins[:-1]
    lines[j:j] = ins
    open(path, "wb").write(b"\n".join(lines))
    print("  + %-46s %s" % (label, os.path.basename(path)))


FA = os.path.join(ROOT, "prom_c", "field_accessors.s")
TD = os.path.join(ROOT, "prom_c", "data_tables", "tail_data_zone.s")

W21 = "; ★ WAVE 21 (lane w21/lsi-gate) ------------------------------------------\n"

blocks = []

blocks.append((FA, "Pack104_SetInputs_PartRecord", W21 + """\
; ★★ THIS IS ONE OF THE PRODUCERS OF THE BITS THAT GATE REGISTER chan+0x0300,
;          which notes/HLE-GUIDE-l7a1429.md section 8.5 lists as UNLOCATED.  With
;          DE = P0 = PART+0x13 and HL = P1 = PART+0x3D (0xFC4BF6, 0xFC4C0B), and
;          XIY / XWA the two elements' 43-byte WAVE-SELECT records read through
;          P[+0x03] at PART[+0x16] and PART[+0x40] (0xFC4C03, 0xFC4C18):
;            c = Q0[+0x0B] & 0xC0                     0xFC4C1D-0xFC4C20
;            c = Q1[+0x0B] & 0xC0                     0xFC4C25-0xFC4C28
;            either non-zero -> P0[+0x07] &= 0xFF8F ; bit 4 SET   0xFC4C33-0xFC4C3E
;                               P1[+0x07] &= 0xFF8F ; bit 4 SET   0xFC4C59-0xFC4C64
;            both zero       -> P0[+0x07] &= 0xFF8F               0xFC4C6F
;                               P1[+0x07] &= 0xFF8F               0xFC4C7A
;          0xFF8F is ~0x0070, so the mask writes exactly bits 6:4 and preserves the
;          rest of the word.  Dev104_PackStagingStruct ORs P[+0x07] whole into
;          staging word 0 (0xFC4DEB) and tests those bits at 0xFC51B7 to decide
;          whether register chan+0x0300 gets a value or 0x0000.
;          Q[+0x0B] bits 7:6 are `RESO MODE`
;          (notes/FINDINGS-l7a1429-parameter-names.md section 2d, STRONG).
;          It also sets P0[+0x09] and P1[+0x09] to an element index, 0/1 or 0/0
;          depending on bit 7 of P0[+0x00] (0xFC4C45).
; GRADE: PROVEN for the arithmetic and for the destination field -- every line is
;          an operand, asserted from the ROM by
;          notes/w21_lsi_gate_and_keyscaling.py sections 4 and 5.
"""))

for lbl, extra in (
    ("sub_FC6CA8", "all four elements (H = 0x00, the no-RESO-MODE case)"),
    ("sub_FC6CEA", "elements 0..1 (the low nibble of H is zero)"),
    ("sub_FC6D2C", "elements 2..3 (the high nibble of H is zero); its base is\n;          PART+0x67 = 0x13 + 2*42 and its counter starts at 2"),
):
    blocks.append((FA, lbl, W21 + """\
; ★ ONE OF Pack104_DispatchByResoMode_ForPart's SIX ARMS, and one of the three
;          that CLEAR the gate on register chan+0x0300.  Over %s
;          it writes, per sub-record P:
;            P[+0x09] = the element index
;            P[+0x07] &= 0xFF8F      bits 6:4 <- 0    (the gate on chan+0x0300)
;            P[+0x12] = 0x0000 ; P[+0x14] = 0x0000
;          and then PART[+0x11] = PART[+0x12] = 0x7F -- the two clamp limits the
;          packer applies to v1/v2 and to i3/i4, opened wide.
;          Unlike the three arms that SET a bit it reads no curve at all.
; GRADE: PROVEN (operands; notes/w21_lsi_gate_and_keyscaling.py section 4).
""" % extra))

for lbl, bit, sel in (
    ("sub_FC6D6E", "5", "H == 0xAA, i.e. all four elements in RESO MODE 2"),
    ("sub_FC6FFD", "4", "the low nibble of H non-zero, i.e. elements 0..1"),
    ("sub_FC723F", "4", "the high nibble of H non-zero, i.e. elements 2..3"),
):
    blocks.append((FA, lbl, W21 + """\
; ★★ ONE OF THE THREE ARMS THAT OPEN THE GATE ON REGISTER chan+0x0300.
;          Selected for %s.
;          Per sub-record P it does `P[+0x07] &= 0xFF8F` then `set 0x0%s` -- so the
;          three-bit field at bits 6:4, which Dev104_PackStagingStruct tests at
;          0xFC51B7, becomes 0x%s0 instead of 0.
; ★ AND IT COMPUTES REGISTER 0x0300's OWN VALUE A SECOND TIME.  It reads
;          Q[+0x13] = p19 through P[+0x03] and indexes Curve_Exp2Gain_U8_128 at
;          0xFDF760 -- the same byte and the same table the packer's gated arm uses
;          at 0xFC51C1/0xFC51C8 -- and stores the result into the per-element block
;          at the global 0x00E093.  Those four are the ONLY citations of that curve
;          in the whole image, so the routines that open the gate are exactly the
;          other readers of the gated register's curve.
;          The block also receives Curve_Exp2Gain_Percent_101[clamp(|p33|,0..100)],
;          the curve register chan+0x0280 (`SUB GAIN`) is made from, and both tuning
;          words P[+0x0E] and P[+0x10].
; ⚠ 0x00E093 HAS NO LOCATED READER: every spelling of that address in either
;          image is a write.  What this arm COMPUTES is therefore still open; what
;          it SETS is not.
; GRADE: PROVEN for the gate write and for the curve citation
;          (notes/w21_lsi_gate_and_keyscaling.py sections 4, 5 and 5b);
;          UNIDENTIFIED for the 0x00E093 block's meaning.
""" % (sel, bit, bit)))

blocks.append((FA, "Pack104_DispatchByResoMode_ForPart", W21 + """\
; ★★ WHAT THE SIX ARMS HAVE IN COMMON, found by lane w21/lsi-gate: every one of
;          them writes bits 6:4 of P[+0x07] for the elements it covers, and that is
;          the field Dev104_PackStagingStruct tests at 0xFC51B7 to gate register
;          chan+0x0300.  Three arms clear it (sub_FC6CA8, sub_FC6CEA, sub_FC6D2C)
;          and three set one bit -- bit 5 in sub_FC6D6E, bit 4 in sub_FC6FFD and
;          sub_FC723F.  Bit 6 is never set by any path in either image, so the
;          field is a two-bit enumeration: 0 = no RESO MODE, 1 = some element in a
;          mode, 2 = all four in mode 2.
;          In the factory tone database H is 0 for 246 of 256 framed tones; eight
;          correctly framed tones give it a non-zero value and every one of them is
;          a pad (Fantasia, Dream, Mist, Halo Pad, Voxmosphere, Dark Universe,
;          Goblins, Windy Sweep), with `Dark Universe` the sole user of H == 0xAA.
; GRADE: PROVEN for the dispatch and for the field; the eight tones are STRONG
;          (their records pass the parameter-names lane's p20 and p25 invariants
;          and beat a shuffle null at p < 0.001, but they fail the element-block
;          filter dev104_topology_probe.py uses).
;          Findings: notes/FINDINGS-l7a1429-gate-and-keyscaling.md.
"""))

blocks.append((FA, "Dev104_PackStagingStruct", W21 + """\
; ★★ THE GATE ON REGISTER chan+0x0300 IS AT 0xFC51B5-0xFC51F4, and its input is
;          now located.  Staging word 0 is built at 0xFC4DC4-0xFC4DF1 as
;          `(R[+0x07] << 8) | P[+0x07]`: R[+0x07] is read as a BYTE and shifted
;          left eight, so bits 6:4 of that word can only be bits 6:4 of P[+0x07],
;          the 42-byte sub-record's own field.  Then
;            0xFC51B5  WA = staging word 0
;            0xFC51B7  WA &= 0x0070
;            zero     -> staging word 12 (register chan+0x0300) = 0x0000  0xFC51EF
;            non-zero -> b = Curve_Exp2Gain_U8_128[Q[+0x13]]              0xFC51C8
;                        staging word 12 = (b << 8) | b                   0xFC51E0
;                        and bit 7 of staging word 0 is CLEARED           0xFC51E6
;          The writers of P[+0x07] bits 6:4 are Pack104_SetInputs_PartRecord and
;          the six RESO MODE arms; see their headers.
; ⚠ THIS SUPERSEDES the claim in notes/HLE-GUIDE-l7a1429.md section 8.5 that
;          0xFC4D27 and 0xFC7DE9 write those bits -- they write R[+0x07], which
;          lands in bits 15:8 (notes/FINDINGS-l7a1429-packer-routines.md 4.1).
; GRADE: PROVEN (operands; notes/w21_lsi_gate_and_keyscaling.py sections 1 and 2).
"""))

RAMPS = {
 "LinCoef_Position_KeyRamp_Q5_128": """\
; ★ WAVE 21 -- IN IMPLEMENTER UNITS.  Reader: `r = ((s8)T[k] * A) >> 5` with A
;          the depth byte and k MIRRORED to 0x7F-k when A < 0, so the SIGNED slope
;          is A*(dT/dk)/32 either way and the sign of A chooses which end of the
;          keyboard is the pivot, not the sign of the contribution.  `sra` FLOORS.
;            law slope   2 table counts per key  ->  depth/16 index steps per key
;            excursion   7.9375 * |depth| index steps across the 128 keys, zero at
;                        k = 64
;          ★★ AND THE INDEX IS THE RECIPROCAL OF THE POSITION.  Composing
;          Curve_Position_Log2Period_251's own fit v = round(27543 - 3072*log2 i)
;          with chan+0x00C0's 3072-counts-per-octave log-period unit gives
;          position = C / i EXACTLY for i >= 1.  One index step at i moves the
;          register by -4432.6/i counts = -17.315/i semitones of position.
;          100% key follow is already HARD-WIRED into chan+0x00C0 by its `- R[+0x0C]`
;          pitch term, so this ramp is an ADDITIONAL deviation and no depth byte
;          means 100% on its own.  At the factory-standard index (p13 = 125 in 400
;          of 459 records) depth 32 / 64 / 127 give +27.7% / +55.4% / +110.0% of
;          that hard-wired follow.
;          ★ SECOND DESTINATION: R[+0x14] = |r| >> 2 (0xFC5643, 0xFC564D), which is
;          the first term of register chan+0x0240's Curve_Fitting_Exp2Rise_128
;          index.  This ramp reaches TWO registers; the second gets its magnitude.
;          Numbers: notes/w21_lsi_gate_and_keyscaling.py section 9.
""",
 "LinCoef_Fitting_KeyRamp_Q5_128": """\
; ★ WAVE 21 -- IN IMPLEMENTER UNITS.  Same reader idiom (mirror on a negative
;          depth, `sra 5`, so it FLOORS).
;            law slope   65/128 = 0.507812 counts per key -> depth/63.02 index
;                        steps per key
;            excursion   2 * |depth| index steps across the 128 keys, zero at k = 64
;          One destination index step is 2^(1/16) = 0.37631 dB, so
;            depth  32 -> 0.191 dB/key = 2.29 dB/octave, 24.1 dB across the keyboard
;            depth  64 -> 0.382 dB/key = 4.59 dB/octave, 48.2 dB
;            depth 127 -> 0.758 dB/key = 9.10 dB/octave, 95.6 dB
;          ⚠ There is no pitch-versus-gain identity, so `100% key follow' needs a
;          stated convention here, unlike MUTING.  One octave of the exp2 parameter
;          per octave of key is 4/3 step per key = depth 84 -- a CONVENTION, not a
;          measurement.  The dB/octave column is convention-free.
;          ⚠ AND IT IS NOT LinCoef_Muting_KeyRamp_Q5_128 SHIFTED BY 32, tempting
;          though the endpoints make that: entry for entry the difference is 32 on
;          96 entries and 33 on 32 of them, because the extra k/128 moves the
;          stair's repeat by one key over the top half.  Only Muting and SubGain
;          are byte-identical.  Numbers:
;          notes/w21_lsi_gate_and_keyscaling.py sections 8 and 9.
""",
 "LinCoef_Muting_KeyRamp_Q5_128": """\
; ★ WAVE 21 -- IN IMPLEMENTER UNITS.  Same reader idiom; the mirror on a negative
;          depth is what turns this UNIPOLAR table into a BIPOLAR control, moving
;          the pivot from k = 127 to k = 0 rather than negating the contribution.
;            law slope   exactly 1/2 table count per key -> depth/64 index steps
;                        per key, and the index is a SEMITONE OF CUTOFF
;            excursion   2 * |depth| semitones across the 128 keys
;          so, exactly:
;            depth +-32  ->  +-50.0% cutoff key follow
;            depth +-64  ->  +-100.0%   (the exact one)
;            depth +-127 ->  +-198.4%
;          ⚠ THE ks() STAGE IN THE SAME CHAIN USES A DIFFERENT SCALING: its slope is
;          Q[+o+3] >> 5, so THERE 32 = 100%, not 64.  An implementation that reuses
;          one constant for both stages is wrong by a factor of two.
;          ★ The factory depth bytes are multiples of TEN (132 of 133 in the strict
;          population, the exception a single -5), so the control's real resolution
;          is 15.6% of key follow per click and its factory range -50..+30 is
;          -78%..+47%.  Numbers: notes/w21_lsi_gate_and_keyscaling.py sections 9-10.
""",
 "LinCoef_SubGain_KeyRamp_Q5_128": """\
; ★ WAVE 21 -- IN IMPLEMENTER UNITS, and this one is exact too.  Same law and
;          same reader as its twin, but the destination index is literally a
;          PERCENTAGE of SUB GAIN: clamp(R[+0x10] + R[+0x23], 0..100) into the
;          101-entry Curve_Exp2Gain_Percent_101, one point = 0.37631 dB.
;            law slope   depth/64 PERCENTAGE POINTS OF SUB GAIN PER SEMITONE OF KEY
;            depth  32 -> 0.50 point/key = 0.188 dB/key = 2.26 dB/octave
;            depth  64 -> 1.00 point/key = 0.376 dB/key = 4.52 dB/octave  (exact)
;            depth 127 -> 1.98 point/key = 0.747 dB/key = 8.96 dB/octave
;          ★ and because the excursion is 2*|depth| points into a 0..100 window,
;          |depth| = 50 sweeps exactly the whole control across the keyboard and
;          anything larger saturates it somewhere on the keyboard.
;          Numbers: notes/w21_lsi_gate_and_keyscaling.py section 9.
""",
}

for lbl, blk in RAMPS.items():
    blocks.append((TD, lbl, blk))

bad = 0
for path, lbl, blk in blocks:
    if insert_before_label(path, lbl, blk) is False:
        bad += 1
print("MISSING: %d" % bad if CHECK else "done")
sys.exit(1 if bad else 0)
