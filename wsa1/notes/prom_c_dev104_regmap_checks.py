#!/usr/bin/env python3
"""Re-derive, from prom_c's BYTES, every number the 0x00104000 register map in
prom_c/devices/dev10c_dev104_drivers.s quotes -- and the part-record struct that feeds it.

QUESTION IT ANSWERS
  "For the device at CPU 2's 0x00104000: what is the per-channel register map, which staging
  word feeds each register, which routine computes that word, and out of which record field?"

  Nothing here reads any `.s` file and nothing here reads unidasm's text.  Every check is raw
  bytes at a stated address in `original_ROMs/wsa1_prom_c.ic28`.

WHAT EACH SECTION PROVES
   1  Dev104_WriteAllChanRegs (0xFB77EF) writes 19 per-channel registers, `block*0x40 + chan`,
      block index k = 0..0x12, value from struct word 2k -- extracted by walking the routine's
      `add BC/DE,imm16` / `ld BC/DE,(XIX+d)` pairs, not retyped.  Block 0 is written LAST.
   2  the five small 0x00104000 accessors touch exactly eight blocks, 0x00C0..0x0280, all
      0x40 apart -- plus block 0 on its own.
   3  the nine `ld X??,0x00104000` literals in the WHOLE image, with their addresses: eight in
      the Dev104 block and one in Dev10C_ResetAllChannels.  No other module reaches the device
      and NO site reads it back.
   4  the 19 staging-struct offsets and the 24 stores that fill them: 20 in
      Dev104_PackStagingStruct itself, 3 in sub_FC49AD and 1 in sub_FC4AED.
   5  ★ THE FOUR MIS-ATTRIBUTED SITES.  notes/prom_c_dev10c_field_sources.py --dev104 reports
      0xFC5522, 0xFC55AF, 0xFC55C5 and 0xFC5657 as struct writes.  They are not: each stores
      through the POINTER at RAM 0x00E086, and the bytes say so.
   6  the packer's input globals 0x00E082..0x00E08D and the four Pack104_SetInputs_* routines
      that set them, with the strides 0xBB / 0x2A / 0x25 and the bases 0x005D23 / 0x00753E.
   7  VoiceRegs_Stage_A pushes 0x00D7A2 to the packer and then to Dev104_WriteAllChanRegs,
      two instructions apart -- so 0x00D7A2 is the 0x00104000 staging struct.
   8  the key-zone record's word +0x06 goes to BOTH RAM 0x005A4F (the 0x0010C000 pitch chain's
      zone offset) and, through Pack104_SetInputs_Rec0C_E08C, to (0x00E086)[+0x0C], which the
      0x00104000 packer subtracts.  One record field, two devices.
   9  0x4280 -- note 66 in 1/256-semitone units -- is a key-follow pivot on BOTH devices:
      0xFA7FF6/0xFA8098 in the 0x0010C000 pitch chain and 0xFC4A18 in sub_FC49AD, which feeds
      0x00104000 register 0x00C0 + chan.
  10  the six Q5 depth lookups in the packer: `lda XIX,<LinCoef table>` with the four tables,
      and the `sra 0x05` that makes 32 = 1.0.
  11  the constants: struct +0x16 is the literal 0xFF00; Const_0100_251 (0xFDFCD6) is 0x0100 in
      all 251 entries, so 0x00104000 register 0x0100 + chan is a CONSTANT on this firmware.
  12  Dev104_LoadStageBImage (0xFC571A) copies 19 words from 0xFE1315 and patches five fields,
      so on the Stage_B path the 19 registers are an image, not a packing.
  13  the COMPANION device's block census, for the two-device comparison the register-map
      header in prom_c/devices/dev10c_reg_writers.s draws: 0x0010C000's full writer reaches
      22 blocks, its accessor banks reach SIX the writer never does and miss SEVEN the writer
      has, 28 distinct blocks in all, plus the 13 GLOBAL registers written by immediate.

RUN
  python3 notes/prom_c_dev104_regmap_checks.py            # print every section
  python3 notes/prom_c_dev104_regmap_checks.py --selftest # assert; exit 1 on any failure
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


def u16(addr):
    return IMG[addr - BASE] | (IMG[addr - BASE + 1] << 8)


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILURES.append('%s: got %r want %r' % (label, got, want))
    if not QUIET:
        print('  %-66s %s' % (label, 'OK' if ok else 'FAIL  got=%r want=%r' % (got, want)))
    return ok


def bytes_at(label, addr, hexstr):
    want = bytes(int(x, 16) for x in hexstr.split())
    check('%s @0x%06X' % (label, addr), by(addr, len(want)).hex(' '), want.hex(' '))


# ---------------------------------------------------------------- section 1
# The unrolled writer.  Two instruction forms and nothing else:
#     db 89 / db 8a       ld BC,HL / ld DE,HL
#     d9 c8 lo hi         add BC,imm16          (da c8 lo hi = add DE,imm16)
#     9c dd 21 / 9c dd 22 ld BC,(XIX+dd) / ld DE,(XIX+dd)
# The block-0 write has no `add` at all: the channel goes to the port unmodified.
DEV104_WRITER = (0xFB77EF, 0xFB7967)


def sec1_writer_map():
    a, end = DEV104_WRITER
    pairs = []
    while a < end:
        b = by(a, 4)
        if b[0] in (0xD9, 0xDA) and b[1] == 0xC8:
            blk = b[2] | (b[3] << 8)
            # the field fetch is the next `9c dd 2x` within 12 bytes
            fld = None
            for j in range(a + 4, a + 4 + 14):
                if IMG[j - BASE] == 0x9C and IMG[j - BASE + 2] in (0x21, 0x22):
                    fld = IMG[j - BASE + 1]
                    break
            pairs.append((blk, fld))
            a += 4
            continue
        a += 1
    if not QUIET:
        print('=== 1. Dev104_WriteAllChanRegs 0x%06X: the per-channel map ===' % DEV104_WRITER[0])
        for blk, fld in pairs:
            print('    register chan + 0x%04X  <- struct word 0x%02X   block %2d  field==2*block: %s'
                  % (blk, fld, blk // 0x40, fld == 2 * (blk // 0x40)))
    check('18 add-immediate register writes (block 0 has no add)', len(pairs), 18)
    check('every block is a multiple of 0x40', sorted(set(b % 0x40 for b, _ in pairs)), [0])
    check('blocks are 0x0040..0x0480 with no gap',
          [b for b, _ in pairs], [0x40 * k for k in range(1, 19)])
    check('field == 2 * block index, all 18', all(f == 2 * (b // 0x40) for b, f in pairs), True)
    check('...and the LAST pair is (0x0480, 0x24), not only the first', pairs[-1], (0x0480, 0x24))
    # block 0, written LAST, with no arithmetic: `ld (XBC),HL` then `ld ??,(XIX)` field 0
    bytes_at('block 0 select: ld XBC,(XIZ-4) / ld (XBC),HL, the RAW channel', 0xFB795C,
             'ae fc 21 b1 53')
    bytes_at('block 0 data:   ld BC,(XIX) = struct word 0, and it is the LAST write',
             0xFB7961, '94 21 ae f8 20 b0 51')
    return pairs


# ---------------------------------------------------------------- section 2
SMALL_ACCESSORS = [
    ('Dev104_SetChanRegs_01C0_0200_0240', 0xFB796E, 0xFB79CF),
    ('Dev104_SetChanRegs_0140_to_0240',   0xFB79D0, 0xFB7A57),
    ('Dev104_WriteChanReg0',              0xFB7A58, 0xFB7A73),
    ('Dev104_SetChanRegs_00C0_0100_0240', 0xFB7A74, 0xFB7AC3),
    ('Dev104_SetChanRegs_00C0_0100',      0xFB7AC4, 0xFB7B03),
    ('Dev104_SetChanRegs_0140_0180',      0xFB7B04, 0xFB7B3F),
    ('Dev104_SetChanReg_0280',            0xFB7B40, 0xFB7B62),
]


def sec2_small_accessors():
    allblocks = set()
    rows = []
    for name, lo, hi in SMALL_ACCESSORS:
        blks = []
        a = lo
        while a < hi:
            b = by(a, 4)
            if b[0] in (0xD9, 0xDA, 0xDB) and b[1] == 0xC8:
                blks.append(b[2] | (b[3] << 8))
                a += 4
                continue
            a += 1
        rows.append((name, blks))
        allblocks |= set(blks)
    if not QUIET:
        print('=== 2. the small 0x00104000 accessors ===')
        for name, blks in rows:
            print('    %-36s %s' % (name, ', '.join('0x%04X' % b for b in blks) or '(none: block 0 only)'))
    want = [0x00C0, 0x0100, 0x0140, 0x0180, 0x01C0, 0x0200, 0x0240, 0x0280]
    check('the small accessors touch exactly eight blocks', sorted(allblocks), want)
    check('...and they are 0x40 apart, first to last',
          [want[i + 1] - want[i] for i in range(7)], [0x40] * 7)
    check('...spanning 0x0280 - 0x00C0 = 7 * 0x40', want[-1] - want[0], 7 * 0x40)
    check('Dev104_WriteChanReg0 has no `add` at all -- block 0',
          dict(rows)['Dev104_WriteChanReg0'], [])
    return sorted(allblocks)


# ---------------------------------------------------------------- section 3
def sec3_literal_census():
    sites = []
    i = 0
    needle = bytes.fromhex('00401000')
    while True:
        j = IMG.find(needle, i)
        if j < 0:
            break
        sites.append((BASE + j - 1, IMG[j - 1]))
        i = j + 1
    if not QUIET:
        print('=== 3. every 0x00104000 literal in the image ===')
        for a, op in sites:
            print('    0x%06X  opcode 0x%02X  ld %s,0x00104000'
                  % (a, op, {0x41: 'XBC', 0x44: 'XIX', 0x45: 'XIY'}.get(op, '?')))
    check('nine literal loads, no more', len(sites), 9)
    check('every one is `ld XBC,imm32` or `ld XIX,imm32`',
          sorted(set(op for _, op in sites)), [0x41, 0x44])
    check('eight are inside the Dev104 block 0xFB77EF-0xFB7B62',
          sum(1 for a, _ in sites if 0xFB77EF <= a <= 0xFB7B62), 8)
    check('the ninth is 0xFB80F1, inside Dev10C_ResetAllChannels',
          [a for a, _ in sites if not (0xFB77EF <= a <= 0xFB7B62)], [0xFB80F1])
    return sites


# ---------------------------------------------------------------- section 4
# Every store into the staging struct.  A struct store is reached through
# `ae 08 2x` = `ld X??,(XIZ+0x08)`, the routine's only argument.
STRUCT_STORES = [
    (0xFC4DD7, 'ae 08 21 b1 55', 0x00, 'ld (XBC),IY            word 0 <- P[+0x07]'),
    (0xFC4DEE, 'ae 08 25 b5 50', 0x00, 'ld (XIY),WA            word 0 <- (R[+0x07]<<8)|P[+0x07]'),
    (0xFC4E9C, 'ae 08 21 b9 02 53', 0x02, 'ld (XBC+0x02),HL'),
    (0xFC4F4B, 'ae 08 21 b9 04 53', 0x04, 'ld (XBC+0x04),HL'),
    (0xFC50D2, 'ae 08 21 b9 0a 02 00 00', 0x0A, 'ld (XBC+0x0a),0x0000'),
    (0xFC50DA, 'ae 08 21 b9 0c 02 00 00', 0x0C, 'ld (XBC+0x0c),0x0000'),
    (0xFC5114, 'ae 08 20 b8 0a 51', 0x0A, 'ld (XWA+0x0a),BC'),
    (0xFC5120, 'ae 08 20 b8 0c 51', 0x0C, 'ld (XWA+0x0c),BC'),
    (0xFC51AA, 'ae 08 21 b9 16 02 00 ff', 0x16, 'ld (XBC+0x16),0xff00   the only value it ever takes'),
    (0xFC51E3, 'ae 08 21 91 3c 7f ff', 0x00, 'and (XBC),0xff7f       read-modify-write of word 0'),
    (0xFC51DD, 'ae 08 21 b9 18 52', 0x18, 'ld (XBC+0x18),DE'),
    (0xFC51EC, 'ae 08 21 b9 18 02 00 00', 0x18, 'ld (XBC+0x18),0x0000'),
    (0xFC52E9, 'ae 08 20 b8 20 51', 0x20, 'ld (XWA+0x20),BC'),
    (0xFC52F8, 'ae 08 21 b9 1a 50', 0x1A, 'ld (XBC+0x1a),WA'),
    (0xFC5364, 'ae 08 21 b9 0e 55', 0x0E, 'ld (XBC+0x0e),IY'),
    (0xFC545F, 'ae 08 20 b8 22 51', 0x22, 'ld (XWA+0x22),BC'),
    (0xFC546E, 'ae 08 21 b9 1c 50', 0x1C, 'ld (XBC+0x1c),WA'),
    (0xFC54DA, 'ae 08 21 b9 10 55', 0x10, 'ld (XBC+0x10),IY'),
    (0xFC568C, 'ae 08 25 bd 24 50', 0x24, 'ld (XIY+0x24),WA'),
    (0xFC56B7, 'ae 08 25 bd 1e 50', 0x1E, 'ld (XIY+0x1e),WA'),
]
CALLEE_STORES = [
    (0xFC49F6, 'ae 08 21 b9 08 50', 0x08, 'sub_FC49AD: (XBC+0x08),WA  <- Const_0100_251[idx]'),
    (0xFC4A3F, 'ae 08 21 b9 06 53', 0x06, 'sub_FC49AD: (XBC+0x06),HL  <- Curve_Log2_251[idx] + terms'),
    (0xFC4AD1, 'ae 08 21 b9 12 55', 0x12, 'sub_FC49AD: (XBC+0x12),IY  <- Multiply32 result'),
    (0xFC4AE1, 'ae 08 20 b8 12 51', 0x12, 'sub_FC49AD: (XWA+0x12),BC  <- the same, &0xFFF8 | 7'),
    (0xFC4B23, 'ae 08 21 b9 14 53', 0x14, 'sub_FC4AED: (XBC+0x14),HL  <- Table_FDFECC[clamp 0..100]'),
]


def sec4_struct_stores():
    if not QUIET:
        print('=== 4. every store into the 0x00104000 staging struct ===')
    offs = set()
    for addr, hexstr, off, what in STRUCT_STORES + CALLEE_STORES:
        bytes_at('  +0x%02X  %s' % (off, what), addr, hexstr)
        offs.add(off)
    check('the stores cover exactly the 19 words 0x00..0x24',
          sorted(offs), [2 * k for k in range(19)])
    check('20 stores in the packer itself', len(STRUCT_STORES), 20)
    check('4 more offsets come from its two callees',
          sorted(set(o for _, _, o, _ in CALLEE_STORES) - set(o for _, _, o, _ in STRUCT_STORES)),
          [0x06, 0x08, 0x12, 0x14])
    return sorted(offs)


# ---------------------------------------------------------------- section 5
# The four sites notes/prom_c_dev10c_field_sources.py --dev104 mis-reads as struct writes.
# `d2 86 e0 00 20` is `ld WA,(0x00e086)`; `d2 86 e0 00 21` is `ld BC,(0x00e086)`.
MISREAD = [
    (0xFC551B, 'd2 86 e0 00 20 e8 12 b8 1c 00 01', 0x1C, 'ld (XWA+0x1c),0x01'),
    (0xFC55A8, 'd2 86 e0 00 20 e8 12 b8 1d 46',    0x1D, 'ld (XWA+0x1d),H'),
    (0xFC55BE, 'd2 86 e0 00 20 e8 12 b8 1e 46',    0x1E, 'ld (XWA+0x1e),H'),
    (0xFC5650, 'd2 86 e0 00 20 e8 12 b8 14 51',    0x14, 'ld (XWA+0x14),BC'),
]


def sec5_misread():
    if not QUIET:
        print('=== 5. the four sites that are NOT struct writes ===')
    for addr, hexstr, off, what in MISREAD:
        bytes_at('  (0x00E086)+0x%02X  %s' % (off, what), addr, hexstr)
    check('all four load their base from the ABSOLUTE global 0x00E086, not (XIZ+0x08)',
          sorted(set(by(a, 5).hex(' ') for a, _, _, _ in MISREAD)), ['d2 86 e0 00 20'])
    check('...and no struct store anywhere in the packer starts that way',
          [a for a, h, _, _ in STRUCT_STORES if by(a, 2).hex() != 'ae08'], [])
    check('so the packer writes 15 struct offsets by its own instructions, not 16',
          len(set(o for _, _, o, _ in STRUCT_STORES)), 15)
    check('...and +0x16 IS one of them (0xFC51AA), against the round-6 correction',
          0x16 in set(o for _, _, o, _ in STRUCT_STORES), True)
    check('...while +0x1D is NOT a struct offset at all',
          0x1D in set(o for _, _, o, _ in STRUCT_STORES + CALLEE_STORES), False)


# ---------------------------------------------------------------- section 6
def sec6_input_globals():
    if not QUIET:
        print('=== 6. the packer input globals, and who sets them ===')
    bytes_at('Pack104_SetInputs_PartRecord: ld C,0xBB / mul BC,(XIZ+0x08)',
             0xFC4BBD, '23 bb 8e 08 43')
    bytes_at('...base 0x005D23, stored to 0x00E082',
             0xFC4BC4, '30 23 5d d9 80 f2 82 e0 00 50')
    bytes_at('Pack104_SetInputs_SubRecordPair: the 37-byte array at 0x00753E',
             0xFC4CB0, '30 3e 75 d9 80')
    bytes_at('Pack104_SetInputs_E088_E089_E08A: res 7,C then store 0x00E088',
             0xFC4D67, '8e 0c 23 cb 30 07 f2 88 e0 00 43')
    bytes_at('Pack104_SetInputs_Rec0C_E08C: store through (0x00E086) at +0x0C',
             0xFC4D89, 'd2 86 e0 00 21 e9 12 9e 0c 20 b9 0c 50')
    bytes_at('Pack104_SetInputs_Rec0E_E08D: the same pointer at +0x0E',
             0xFC4DA5, 'd2 86 e0 00 21 e9 12 9e 08 20 b9 0e 50')
    check('187 - 19 = 168 = 4 x 42: four sub-records fit behind the +0x13 header',
          (0xBB - 0x13) // 0x2A, 4)
    check('...exactly, with no remainder', (0xBB - 0x13) % 0x2A, 0)


# ---------------------------------------------------------------- section 7
def sec7_staging_struct_address():
    if not QUIET:
        print('=== 7. VoiceRegs_Stage_A hands 0x00D7A2 to the packer and then to the writer ===')
    bytes_at('lda XBC,0x00D7A2 / push XBC / call 0xFC4DBD',
             0xFB0B5B, 'f2 a2 d7 00 31 39 1d bd 4d fc')
    bytes_at('lda XBC,0x00D7A2 / push XBC ... call 0xFB77EF',
             0xFB0B65, 'f2 a2 d7 00 31 39')
    bytes_at('...the call to Dev104_WriteAllChanRegs', 0xFB0B71, '1d ef 77 fb')
    check('the two pushes are 10 bytes apart -- same struct, packer then writer',
          0xFB0B65 - 0xFB0B5B, 10)


# ---------------------------------------------------------------- section 8
def sec8_zone_word_reaches_both_devices():
    if not QUIET:
        print('=== 8. key-zone record word +0x06 feeds BOTH devices ===')
    # KeyZone_Stage_Reg0040_Stride8, the 8-byte-stride walker
    bytes_at('zone[+0x06] -> RAM 0x005A4F (the 0x0010C000 pitch chain)', 0xFA748D,
             '9c 06 21 f1 4f 5a 51')
    bytes_at('zone[+0x06] pushed, then zone[+0x05], then zone[+0x04]', 0xFA7494,
             '9c 06 21 29 8c 05 23 29 8c 04 23')
    bytes_at('...to Pack104_SetInputs_Rec0C_E08C', 0xFA74A0, '1d 85 4d fc')
    # the callee: arg slot +0x0C is zone[+0x06]; it lands in (0x00E086)[+0x0C]
    bytes_at('which stores its (XIZ+0x0c) word into (0x00E086)[+0x0C]',
             0xFC4D90, '9e 0c 20 b9 0c 50')
    # and the packer subtracts (0x00E086)[+0x0C]
    bytes_at('and sub_FC49AD SUBTRACTS it on the way to register 0x00C0 + chan',
             0xFC4A1F, 'd2 86 e0 00 21 e9 12 99 0c 20 d8 a3')
    bytes_at('...and the packer NEGATES it as the delta for 0x0040 / 0x0080',
             0xFC4E66, 'd2 86 e0 00 21 e9 12 99 0c 22 da 88 d8 07')


# ---------------------------------------------------------------- section 9
def sec9_note66_pivot():
    if not QUIET:
        print('=== 9. 0x4280 = note 66 in 1/256 semitone, a pivot on BOTH devices ===')
    bytes_at('0x0010C000 pitch chain, the fixed-pitch arm', 0xFA80C7, '31 80 42')
    bytes_at('0x0010C000 pitch chain, the key-follow arm (subtract then add back)',
             0xFA80D8, 'c8 80 42')
    bytes_at('...the pivot again', 0xFA80DF, '32 80 42')
    bytes_at('sub_FC49AD -> 0x00104000 register 0x00C0 + chan: ld IY,0x4280 / sub IY,WA',
             0xFC4A18, '35 80 42 d8 a5')
    sites = []
    i = 0
    while True:
        j = IMG.find(bytes([0x80, 0x42]), i)
        if j < 0:
            break
        sites.append(BASE + j - 1)
        i = j + 1
    check('the immediate 0x4280 occurs in FOUR instruction operands in the whole image',
          ['0x%06X' % a for a in sites],
          ['0xFA80C7', '0xFA80D8', '0xFA80DF', '0xFC4A18'])
    check('...three of them on the 0x0010C000 pitch path, ONE on the 0x00104000 path',
          [a < 0xFB0000 for a in sites], [True, True, True, False])
    check('0x4280 >> 8 = 66, and the low byte is the half-step centre 0x80',
          (0x4280 >> 8, 0x4280 & 0xFF), (66, 0x80))


# ---------------------------------------------------------------- section 10
LINCOEF_SITES = [(0xFC4F51, 0xFE0116), (0xFC500E, 0xFE0116), (0xFC513E, 0xFE0216),
                 (0xFC5249, 0xFE0196), (0xFC53BF, 0xFE0196), (0xFC55E0, 0xFE0096)]


def sec10_q5_depth():
    if not QUIET:
        print('=== 10. the six Q5 depth lookups in the packer ===')
    for addr, tbl in LINCOEF_SITES:
        want = 'f2 %02x %02x %02x 34' % (tbl & 0xFF, (tbl >> 8) & 0xFF, (tbl >> 16) & 0xFF)
        bytes_at('lda XIX,0x%06X' % tbl, addr, want)
    check('four distinct tables over six sites', len(set(t for _, t in LINCOEF_SITES)), 4)
    check('LinCoef_FE0216 is byte-identical to LinCoef_FE0196, all 128',
          by(0xFE0216, 128), by(0xFE0196, 128))


# ---------------------------------------------------------------- section 11
def sec11_constants():
    if not QUIET:
        print('=== 11. the constants that reach the device ===')
    tbl = [u16(0xFDFCD6 + 2 * k) for k in range(251)]
    check('Const_0100_251 (0xFDFCD6): 0x0100 in all 251 entries', sorted(set(tbl)), [0x0100])
    check('...so register 0x0100 + chan is a CONSTANT on the packer path', tbl[250], 0x0100)
    check('struct +0x16 is only ever the literal 0xFF00',
          [h for a, h, o, _ in STRUCT_STORES + CALLEE_STORES if o == 0x16],
          ['ae 08 21 b9 16 02 00 ff'])
    # Curve_Log2_251, the 0x00C0 feeder: 3072 counts per halving, checked on the powers of two
    log = [u16(0xFDFAE0 + 2 * k) for k in range(251)]
    check('Curve_Log2_251[0] = 0x6C00', log[0], 0x6C00)
    check('...and it falls 3072 per halving on every power of two in range',
          [log[k] - log[2 * k] for k in (1, 2, 4, 8, 16, 32, 64)], [3072] * 7)


# ---------------------------------------------------------------- section 12
def sec12_stage_b_image():
    if not QUIET:
        print('=== 12. the Stage_B path: an IMAGE, not a packing ===')
    bytes_at('push 0x0026 = 38 bytes = 19 words', 0xFC5751, '0b 26 00')
    bytes_at('...from Dev104_StagingStruct_StageBImage 0xFE1315', 0xFC5755, 'f2 15 13 fe')
    bytes_at('...through MemCopyWords', 0xFC575B, '1d 38 a0 f9')
    check('38 bytes is exactly the 19 words Dev104_WriteAllChanRegs reads', 0x26 // 2, 19)



# ---------------------------------------------------------------- section 13
# The COMPANION device's block census, so the comparison the register-map header in
# prom_c/devices/dev10c_reg_writers.s draws between the two devices is checkable.
DEV10C_SPANS = [
    ('Dev10C_WriteAllChanRegs 0xFB713A', 0xFB713A, 0xFB732C),
    ('accessor bank 1 0xFACE67',         0xFACE67, 0xFAD142),
    ('accessor bank 2 0xFB7B63',         0xFB7B63, 0xFB828E),
    ('the 0xFB6E0A helpers',             0xFB6E0A, 0xFB713A),
]


def _adds(lo, hi):
    out = []
    a = lo
    while a < hi:
        b = by(a, 4)
        if b[0] in (0xD9, 0xDA, 0xDB) and b[1] == 0xC8:
            out.append(b[2] | (b[3] << 8))
            a += 4
            continue
        a += 1
    return out


def sec13_dev10c_block_census():
    if not QUIET:
        print('=== 13. the 0x0010C000 block census (for the two-device comparison) ===')
    got = {}
    for name, lo, hi in DEV10C_SPANS:
        got[name] = sorted(set(_adds(lo, hi)))
        if not QUIET:
            print('    %-34s %s' % (name, ' '.join('0x%04X' % b for b in got[name])))
    writer = set(got['Dev10C_WriteAllChanRegs 0xFB713A']) | {0}
    banks = set().union(*(set(got[n]) for n, _, _ in DEV10C_SPANS[1:]))
    check('the full writer reaches 22 blocks including block 0', len(writer), 22)
    check('...and every one is a multiple of 0x40', sorted(set(b % 0x40 for b in writer)), [0])
    check('the accessor banks and helpers reach these and six MORE',
          sorted('0x%04X' % b for b in banks - writer),
          ['0x01C0', '0x0540', '0x0580', '0x05C0', '0x0600', '0x0640'])
    check('...and seven of the writer\'s are reached by no accessor',
          sorted('0x%04X' % b for b in writer - banks),
          ['0x0000', '0x0040', '0x00C0', '0x08C0', '0x09C0', '0x0A00', '0x0A40'])
    check('28 distinct per-channel blocks in all', len(writer | banks), 28)
    check('the highest is 0x0A40, so the file extends to 0x0A40+0x3F = 0x0A7F',
          max(writer | banks), 0x0A40)
    # the 13 GLOBAL registers, immediates inside Dev10C_WriteGlobalRegs
    glob = []
    a = 0xFB7715
    while a < 0xFB77EF:
        b = by(a, 4)
        if b[0] == 0xB1 and b[1] == 0x02:
            glob.append(b[2] | (b[3] << 8))
            a += 4
            continue
        a += 1
    check('Dev10C_WriteGlobalRegs writes 13 registers by IMMEDIATE, no channel',
          glob, [0x0200, 0x0201, 0x0202, 0x0203, 0x0204, 0x0205,
                 0x0C00, 0x0C01, 0x0C02, 0x0C03, 0x0C04, 0x0C05, 0x0E00])
    check('13 words = 0x1A bytes = the gap between the two reset images',
          0xFE12CF - 0xFE12B5, 2 * len(glob))
    return sorted(writer | banks)


SECTIONS = [sec1_writer_map, sec2_small_accessors, sec3_literal_census, sec4_struct_stores,
            sec5_misread, sec6_input_globals, sec7_staging_struct_address,
            sec8_zone_word_reaches_both_devices, sec9_note66_pivot, sec10_q5_depth,
            sec11_constants, sec12_stage_b_image, sec13_dev10c_block_census]


def main():
    global QUIET
    QUIET = '--selftest' in sys.argv
    for fn in SECTIONS:
        fn()
        if not QUIET:
            print()
    print('FAILURES: %d' % len(FAILURES))
    for f in FAILURES:
        print('  ' + f)
    return 1 if FAILURES else 0


if __name__ == '__main__':
    sys.exit(main())
