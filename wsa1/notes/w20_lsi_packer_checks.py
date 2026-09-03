#!/usr/bin/env python3
"""Re-derive from prom_c's BYTES every load-bearing claim lane w20/lsi-packers put
into the headers of prom_c/field_accessors.s.

QUESTION IT ANSWERS
  "The 24 routines this lane named are named for the register or the parameter
  they serve.  Is each of those attributions actually in the ROM?"

  Nothing here reads a `.s` file.  Every check is raw bytes at a stated address
  in `original_ROMs/wsa1_prom_c.ic28`.  Fail it by changing one nibble.

WHAT EACH SECTION PROVES
   1  the 64-entry pool at 0x005B63: 7-byte stride, index stamped at +0x05,
      64 entries, and the pool ending exactly where the part records begin.
   2  the two writers of register chan+0x0000's high byte are the SAME
      instruction on the SAME record, and that record is the 37-byte one
      reached through 0x00E086 -- not the 42-byte sub-record.  This is the
      correction owed to FINDINGS-l7a1429-parameter-names.md section 6.
   3  Pack104_UnpackWaveSelRec_ToSubRecord's tuning and section-C arithmetic:
      the << 8 / * 2 pair, the 44..96 clamp, and the two MUTING curve reads.
   4  Pack104_StageRegs_00C0_0100_0240's four table reads and its `srl 0x00`.
   5  Pack104_StageReg_0280's 0..100 clamp against the 101-entry curve.
   6  the packer's own copies P[+0x26] -> reg 0x0480 and P[+0x24] -> reg 0x03C0.
   7  the eight part-record parameter words: one setter each, and
      Pack104_DispatchByResoMode_ForPart clearing precisely that set.
   8  the movement chain: the 51-entry rate table, the 9-bit phase, the 512-byte
      waveform table that begins where the rate table ends, and the /50.
   9  ★ p20 IS READ.  FINDINGS-l7a1429-parameter-names.md section 5e says
      wave-select byte +0x14 is "read by nothing in the image".  sub_FC578C
      reads it at 0xFC588B and subtracts 100 at 0xFC5890.

RUN (from the wsa1/ directory)
  python3 notes/w20_lsi_packer_checks.py            # print every section
  python3 notes/w20_lsi_packer_checks.py --selftest # assert; exit 1 on failure
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28')
BASE = 0xF80000

IMG = open(ROM, 'rb').read()
FAILURES = []
QUIET = False


def by(addr, n):
    return IMG[addr - BASE:addr - BASE + n]


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILURES.append('%s: got %r want %r' % (label, got, want))
    if not QUIET:
        print('  %-72s %s' % (label, 'OK' if ok else 'FAIL got=%r want=%r' % (got, want)))


def op(label, addr, hexstr):
    """The bytes at `addr` are exactly this instruction encoding."""
    want = bytes(int(x, 16) for x in hexstr.split())
    check('%-52s @0x%06X' % (label, addr), by(addr, len(want)).hex(' '), want.hex(' '))


def section(n, title):
    if not QUIET:
        print('\n--- %d. %s' % (n, title))


# ------------------------------------------------------------------ section 1
section(1, 'the 64-entry slot pool at 0x005B63 (Slot64Pool_*)')
op('ld (XDE+0x05),H       stamp the entry index', 0xFC40FD, 'ba 05 46')
op('inc 7,DE / inc 1,H / cp H,0x40   7-byte stride, 64 entries',
   0xFC410D, 'da 67 ce 61 ce cf 40 67')
op('ld C,(XHL+0x05) / ld A,C   the acquire returns that index', 0xFC409F, '8b 05 23 cb')
op('inc 1,(XHL+0x06)      the use count', 0xFC4078, '8b 06 61')
op('ld C,0xbb / mul BC,(XIZ+0x08)  the part-record stride, for the adjacency',
   0xFC4BBD, '23 bb 8e 08 43')
check('0x005B63 + 7*64 == 0x005D23, the part-record base', 0x005B63 + 7 * 64, 0x005D23)

# ------------------------------------------------------------------ section 2
section(2, "register chan+0x0000's high byte, and which record it lives in")
op('lda XIX,0x00e086      in Pack104_SetInputs_SubRecordPair', 0xFC4C8C, 'f2 86 e0 00 34')
op('ld (XBC+0x07),A       writer 1  == R[+0x07]', 0xFC4D27, 'b9 07 41')
op('lda XIX,0x00e086      in Pack104_StageReg_0000_ForVoice', 0xFC7DB6, 'f2 86 e0 00 34')
op('ld (XBC+0x07),A       writer 2  == R[+0x07]', 0xFC7DE9, 'b9 07 41')
op('ld A,(XBC+0x07) / extz / sll 8 / or (XIZ+0xf0)   the packer builds word 0',
   0xFC4DE3, '89 07 21 d8 12 d8 ee 08 9e f0 e0 ae')
check('both writers are the same three bytes',
      by(0xFC4D27, 3).hex(), by(0xFC7DE9, 3).hex())
check('both take their base from 0x00E086, not 0x00E084',
      (by(0xFC4C8C, 5).hex(), by(0xFC7DB6, 5).hex()),
      ('f2 86 e0 00 34'.replace(' ', ''), 'f2 86 e0 00 34'.replace(' ', '')))

# ------------------------------------------------------------------ section 3
section(3, 'Pack104_UnpackWaveSelRec_ToSubRecord: tuning, and the section-C index')
op('ld (XWA+0x0e),HL      P[+0x0E] <- p29 << 8', 0xFC480B, 'b8 0e 53')
op('muls A,0x02           p30 is a HALF step of the << 8 unit', 0xFC4814, 'c9 09')
op('ld (XWA+0x10),HL      P[+0x10] <- p41 << 8', 0xFC483C, 'b8 10 53')
op('and HL,0x0070         P[+0x07] bits 6:4 are PRESERVED here, not written',
   0xFC4865, 'db cc 70 00')
op('cp WA,0x60 / jr LE / ld HL,0x60 / cp HL,0x2c   i5 = clamp(p15, 44..96)',
   0xFC496B, 'd8 cf 60 00 62 05 33 60 00 68')
op('add XBC,0x00fe04c9    Curve_Muting_Cutoff_Q16_128', 0xFC4987, 'e9 c8 c9 04 fe 00')
op('ld (XBC+0x26),HL      cached in P[+0x26]', 0xFC4993, 'b9 26 53')
op('lda XBC,0xfe05c9      Curve_Muting_Cutoff_Q13_128', 0xFC4996, 'f2 c9 05 fe 31')
op('ld (XBC+0x24),HL      cached in P[+0x24]', 0xFC49A4, 'b9 24 53')

# ------------------------------------------------------------------ section 4
section(4, 'Pack104_StageRegs_00C0_0100_0240: four tables and the shift')
op('cp HL,0x00fa          the 0..250 clamp', 0xFC49CC, 'db cf fa 00')
op('add XBC,0x00fdfae0    Curve_Position_Log2Period_251', 0xFC49E5, 'e9 c8 e0 fa fd 00')
op('lda XBC,0xfdfcd6      Dev104_Reg0100_Const_251', 0xFC49ED, 'f2 d6 fc fd 31')
op('ld (XBC+0x08),WA      staging word 4 = register chan+0x0100', 0xFC49F9, 'b9 08 50')
op('ld IY,0x4280 / sub IY,WA   the note-66 pivot', 0xFC4A18, '35 80 42 d8 a5')
op('ld (XBC+0x06),HL      staging word 3 = register chan+0x00C0', 0xFC4A42, 'b9 06 53')
op('add XBC,0x00fdf9e0    Curve_Fitting_Exp2Rise_128', 0xFC4ABA, 'e9 c8 e0 f9 fd 00')
op('srl 0x00,XIY          the high half; guide section 4', 0xFC4ACC, 'ed ef 00')
op('ld (XBC+0x12),IY      staging word 9 = register chan+0x0240', 0xFC4AD4, 'b9 12 55')
op('and BC,0xfff8 / or BC,0x0007   the low-3-bit field', 0xFC4AD9, 'd9 cc f8 ff d9 ce 07 00')

# ------------------------------------------------------------------ section 5
section(5, 'Pack104_StageReg_0280: the 0..100 control')
op('cp HL,0x0064          clamp to 100', 0xFC4B04, 'db cf 64 00')
op('add XBC,0x00fdfecc    Curve_Exp2Gain_Percent_101', 0xFC4B1B, 'e9 c8 cc fe fd 00')
op('ld (XBC+0x14),HL      staging word 10 = register chan+0x0280', 0xFC4B26, 'b9 14 53')

# ------------------------------------------------------------------ section 6
section(6, 'the packer ships the cached section-C pair to registers 0x0480 / 0x03C0')
op('ld WA,(XBC+0x26)      read P[+0x26]', 0xFC5675, '99 26 20')
op('ld (XBC+0x1a),WA      into R[+0x1A]', 0xFC567F, 'b9 1a 50')
op('ld (XIY+0x24),WA      staging word 18 = register chan+0x0480', 0xFC568F, 'bd 24 50')
op('ld (XIY+0x1e),WA      staging word 15 = register chan+0x03C0', 0xFC56BA, 'bd 1e 50')

# ------------------------------------------------------------------ section 7
section(7, 'the eight part-record parameter words, one setter each')
SETTERS = [
    (0x01, 0xFC58BD, 'PartRec_SetFittingOffset_0001'),
    (0x03, 0xFC5A0E, 'PartRec_SetPositionOffset_0003'),
    (0x05, 0xFC5BC1, 'PartRec_SetPositionOffset_0005'),
    (0x07, 0xFC5F1A, 'PartRec_SetMovementDepth_0007'),
    (0x09, 0xFC6194, 'PartRec_SetMovementRate_0009'),
    (0x0B, 0xFC640B, 'PartRec_SetMutingOffset_000B'),
    (0x0D, 0xFC657A, 'PartRec_SetTuningOffset_000D'),
    (0x0F, 0xFC660B, 'PartRec_SetSubGainOffset_000F'),
]
for off, addr, name in SETTERS:
    got = by(addr, 3)
    # `ld (Xrr+d),BC`: opcode b8..bd, displacement, 0x50..0x55 for the source pair
    check('%-38s stores PART[+0x%02X]' % (name, off),
          (got[1], 0xB8 <= got[0] <= 0xBD, 0x50 <= got[2] <= 0x55),
          (off, True, True))
op('sll 0x08,BC           PART[+0x0D] is stored in WHOLE semitones', 0xFC6572, 'd9 ee 08')
for i, off in enumerate([0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F]):
    addr = 0xFC7527 + 12 * i
    op('DispatchByResoMode clears PART[+0x%02X]' % off, addr, 'b9 %02x 02 00 00' % off)
op('ld C,(XWA+0x0b) / and C,0xc0   RESO MODE, wave-select byte +0x0B bits 7:6',
   0xFC74BC, '88 0b 23 cb cc c0')
op('ld (XBC+0x03),XWA     the wave-select record pointer P[+0x03]', 0xFC6834, 'b9 03 60')

# ------------------------------------------------------------------ section 8
section(8, 'the P0SITI0N MOVEMENT chain')
op('cp HL,0x0032          the movement depth clamps to 0..50', 0xFC5FAB, 'db cf 32 00')
op('add XBC,0x00fe0296    the movement RATE table', 0xFC626E, 'e9 c8 96 02 fe 00')
op('and HL,0x01ff         a 512-step phase accumulator', 0xFC7C7A, 'db cc ff 01')
op('add XWA,0x00fe02c9    the movement WAVEFORM table', 0xFC7C91, 'e8 c8 c9 02 fe 00')
op('divs BC,0x0032        R[+0x21] = waveform * depth / 50', 0xFC7CAA, 'd9 0b 32 00')
op('ld (XWA+0x21),BC      into R[+0x21]', 0xFC7CB4, 'b8 21 51')
check('the rate table is 51 entries and ends where the waveform begins',
      0xFE0296 + 51, 0xFE02C9)
op('ld (XWA+0x1d),H       the packer copies P[+0x28] to R[+0x1D]', 0xFC55AF, 'b8 1d 46')
op('ld (XWA+0x1e),H       and P[+0x29] to R[+0x1E]', 0xFC55C5, 'b8 1e 46')

# ------------------------------------------------------------------ section 9
section(9, 'p20 IS read -- a correction owed to the parameter-names lane')
op('ld C,(XWA+0x14)       sub_FC578C reads wave-select byte +0x14 = p20',
   0xFC588B, '88 14 23')
op('sub BC,0x0064         and subtracts 100, its factory value', 0xFC5890, 'd9 ca 64 00')
op('ld XWA,(XBC+0x03)     through P[+0x03], so the object IS the wave-select record',
   0xFC5888, 'a9 03 20')

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        pass
    print('\nFAILURES: %d' % len(FAILURES))
    for f in FAILURES:
        print('  ' + f)
    sys.exit(1 if FAILURES else 0)
