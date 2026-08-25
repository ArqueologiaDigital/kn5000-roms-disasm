#!/usr/bin/env python3
"""Re-derive, from prom_c's BYTES, every number that notes/FINDINGS-prom_c-dev10c-register-meanings.md
quotes -- and therefore every semantic name that round 7 put into prom_c/wsa1_prom_c.s.

QUESTION IT ANSWERS
  Gap A of ../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md asks, for the device at CPU 2's
  0x0010C000: *which register is the pitch, which a level, which a sample selector?*  This script
  does not answer it -- the findings note does.  What it does is make every step of that argument
  a re-runnable assertion over `original_ROMs/wsa1_prom_c.ic28`, so that a name in the source can
  never drift away from the instruction that justifies it.

  Nothing here reads `prom_c/wsa1_prom_c.s` and nothing here reads unidasm's text.  Every check is
  either raw bytes at a stated address or a closed form over a whole table.

WHAT EACH SECTION PROVES
   1  the MIDI-controller dispatcher at 0xFAFDA5: the 21 (controller number -> handler) arms,
      extracted by walking the `cp BC,imm / jrl Z,target` chain, NOT retyped.
   2  controller 7, 10 and 11 write part-record fields +0x0B, +0x0D and +0x0E of the 300-byte
      record at RAM 0x001523 -- the multiply, the offset and the store.
   3  Voice_CC_VolumeCurve (0xFDF3F1): 128 u16, exactly 32 counts per halving on every power of
      two, endpoints, and the 14 entries that sit one count below round(32*log2(k/127)).
   4  the level chain in 0xFA7D6A: part[+0x0B] + arg + part[+0x0E], clamp 0..0xFF,
      Voice_OutputLevel_Table, double, OR a 3-bit field, store to staging word 2 (0x00D762).
   5  Voice_OutputLevel_Table (0xFDDE2B): 256 u16, an EXACT closed form, all 256 entries.
   6  Voice_Reg080_NoteField_Table (0xFDD2AB): 128 u16, an EXACT closed form, all 128 entries.
   7  Dev10C_WriteAllChanRegs (0xFB713A): the five staging words this round names, each read at a
      stated offset and sent to a stated register block -- including the bit-15 set/clear pulse
      that wraps register chan+0x0080.
   8  the pitch chain in 0xFA7F28: note<<8 masked 0x7F00, the +0x80 half-step centre, the global
      word at 0x001505, part[+0x15]<<8 and part[+0x13], and the 0x4280 fixed-pitch reference.
   9  0xFA7570 saturates to [0, 0x7FFF] -- the 15-bit range that makes 0x7FFF exactly note 128.
  10  0xFA744F is a 128-entry key map: index = (pitch & 0x7F00) >> 8.
  11  the four key-zone walkers: strides 8, 6, 6, 4, their flag masks, and the pairwise byte
      difference counts (they are NOT copies of one another).
  12  registers chan+0x0800 and chan+0x0840 are written 0xFF80 / 0xFF00 as a PAIR, in the power-on
      sweep and in the voice-list clear at 0xFB0200.
  13  the high-nibble doubling fix-up applied to staging word 1 at 0xFA823D and 0xFA82F0.
  14  controller 64 is a switch whose threshold is the MIDI standard's 64.
  15  internal controllers 0x81 / 0x82, and the arithmetic that fixes the pitch unit at
      1/256 of a semitone from BOTH sides.
  16  the key map and the key-zone record array are 0-BASED OFFSETS relocated against
      RAM 0x00D7ED = 0x00F00000 (or 0x00D80D = the expansion board) -- which is prom_d's
      own addressing scheme and prom_d's established base.

RUN
  python3 notes/prom_c_dev10c_meaning_checks.py            # print every section
  python3 notes/prom_c_dev10c_meaning_checks.py --selftest # assert; exit 1 on any failure
"""
import math
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


def s16(addr):
    v = u16(addr)
    return v - 0x10000 if v >= 0x8000 else v


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILURES.append('%s: got %r want %r' % (label, got, want))
    if not QUIET:
        print('  %-58s %s' % (label, 'OK' if ok else 'FAIL  got=%r want=%r' % (got, want)))
    return ok


def bytes_at(label, addr, hexstr):
    want = bytes(int(x, 16) for x in hexstr.split())
    check('%s @0x%06X' % (label, addr), by(addr, len(want)).hex(' '), want.hex(' '))


# ---------------------------------------------------------------- section 1
def sec1_controller_table():
    """Walk the cp/jrl chain of the controller dispatcher and return [(cc, handler)].

    Encodings, both read off these bytes and nothing else:
        d9 dN            cp BC,N        for N = 0..7   (N = byte1 - 0xD8)
        d9 cf ll hh      cp BC,imm16
        76 ll hh         jrl Z,rel16    (relative to the byte after the 3-byte instruction)
    The walk stops at the first byte that is neither of the two `cp` forms, which is the
    unconditional `jrl` of the default arm -- so the arm COUNT is read off the ROM, not assumed.
    """
    a = 0xFAFDBB
    out = []
    while True:
        b0, b1 = IMG[a - BASE], IMG[a - BASE + 1]
        if b0 == 0xD9 and 0xD8 <= b1 <= 0xDF:
            cc, n = b1 - 0xD8, 2
        elif b0 == 0xD9 and b1 == 0xCF:
            cc, n = u16(a + 2), 4
        else:
            break
        if IMG[a - BASE + n] != 0x76:
            break
        rel = u16(a + n + 1)
        rel -= 0x10000 if rel >= 0x8000 else 0
        out.append((cc, a + n + 3 + rel, a))
        a += n + 3
    return out


def sec1():
    print('1. the MIDI-controller dispatcher at 0xFAFDA5')
    bytes_at('part index is packet byte [1]: ld C,(XIX+0x01)', 0xFAFDAD, '8c 01 23')
    bytes_at('  ... and the part guard cp C,0x21', 0xFAFDB0, 'cb cf 21')
    bytes_at('controller number is packet byte [2]', 0xFAFDB6, '8c 02 23')
    walked = sec1_controller_table()
    arms = [(cc, tgt) for cc, tgt, _ in walked]
    sites = [site for _, _, site in walked]
    full = [(1, 0xFAFE6C), (2, 0xFAFE7A), (4, 0xFAFE88), (7, 0xFAFE96), (10, 0xFAFEA3),
            (11, 0xFAFEB8), (16, 0xFAFED5), (17, 0xFAFEE3), (18, 0xFAFEF1), (19, 0xFAFEFF),
            (64, 0xFAFF0D), (91, 0xFAFF30), (93, 0xFAFF3E), (94, 0xFAFF4C), (120, 0xFAFF5A),
            (121, 0xFAFF63), (123, 0xFAFF6F), (128, 0xFAFF89), (129, 0xFAFF97), (130, 0xFAFFB5),
            (149, 0xFAFFC2), (151, 0xFAFFCF), (153, 0xFAFFDC), (154, 0xFAFFE9), (155, 0xFAFFF6),
            (156, 0xFB0003)]
    check('arm count', len(arms), 26)
    check('(controller, handler) pairs', arms, full)
    check('LAST arm is controller 156 -> 0xFB0003', arms[-1], (156, 0xFB0003))
    check('the `cp BC,imm` site of every arm (cited in the source headers)',
          ['0x%06X' % x for x in sites],
          ['0x%06X' % x for x in
           (0xFAFDBB, 0xFAFDC0, 0xFAFDC5, 0xFAFDCA, 0xFAFDCF, 0xFAFDD6, 0xFAFDDD, 0xFAFDE4,
            0xFAFDEB, 0xFAFDF2, 0xFAFDF9, 0xFAFE00, 0xFAFE07, 0xFAFE0E, 0xFAFE15, 0xFAFE1C,
            0xFAFE23, 0xFAFE2A, 0xFAFE31, 0xFAFE38, 0xFAFE3F, 0xFAFE46, 0xFAFE4D, 0xFAFE54,
            0xFAFE5B, 0xFAFE62)])
    lo = [cc for cc, _ in arms if cc < 0x80]
    check('controllers below 0x80 (legal MIDI CC numbers)', lo,
          [1, 2, 4, 7, 10, 11, 16, 17, 18, 19, 64, 91, 93, 94, 120, 121, 123])
    print()


# ---------------------------------------------------------------- section 2
def sec2():
    print('2. controllers 7 / 10 / 11 write part-record fields +0x0B / +0x0D / +0x0E')
    # CC7 handler 0xFAD6EB
    bytes_at('CC7  : add XBC,0x00FDF3F1 (Voice_CC_VolumeCurve)', 0xFAD710, 'e9 c8 f1 f3 fd 00')
    bytes_at('CC7  : mul BC,0x012C ; add BC,0x000B', 0xFAD71C, 'd9 08 2c 01 d9 c8 0b 00')
    bytes_at('CC7  : ld (XBC),DE', 0xFAD728, 'b1 52')
    # CC11 handler 0xFAD782
    bytes_at('CC11 : add XBC,0x00FDF3F1 (the same curve)', 0xFAD7A7, 'e9 c8 f1 f3 fd 00')
    bytes_at('CC11 : mul BC,0x012C ; add BC,0x000E', 0xFAD7B3, 'd9 08 2c 01 d9 c8 0e 00')
    bytes_at('CC11 : ld (XBC),DE', 0xFAD7BF, 'b1 52')
    # CC10 handler 0xFAD764
    bytes_at('CC10 : mul BC,0x012C ; add BC,0x000D', 0xFAD76D, 'd9 08 2c 01 d9 c8 0d 00')
    bytes_at('CC10 : ld A,(XIZ+0x0A) (the raw controller value)', 0xFAD777, '8e 0a 21')
    bytes_at('CC10 : ld (XBC+0x1523),A  -- ONE byte, no curve', 0xFAD77A, 'f3 e5 23 15 41')
    check('CC7 and CC11 handlers use the same curve address', by(0xFAD710, 6), by(0xFAD7A7, 6))
    print()


# ---------------------------------------------------------------- section 3
def sec3():
    print('3. Voice_CC_VolumeCurve (0xFDF3F1) -- 128 u16')
    T = [s16(0xFDF3F1 + 2 * k) for k in range(128)]
    check('T[0]   (the CC = 0 floor)', T[0], -255)
    check('T[127] (the CC = 127 ceiling)', T[127], 0)
    check('T[126]', T[126], 0)
    pow2 = {k: T[k] for k in (1, 2, 4, 8, 16, 32, 64)}
    check('powers of two: exactly -32 per halving', pow2,
          {1: -224, 2: -192, 4: -160, 8: -128, 16: -96, 32: -64, 64: -32})
    off = [k for k in range(1, 128) if T[k] != round(32 * math.log2(k / 127))]
    check('entries differing from round(32*log2(k/127))', len(off), 14)
    check('  ... and every one of them is exactly one count LOWER',
          sorted({T[k] - round(32 * math.log2(k / 127)) for k in off}), [-1])
    check('  ... their indices', off,
          [3, 5, 9, 10, 13, 18, 20, 27, 40, 54, 59, 87, 99, 108])
    check('monotone non-decreasing over all 128', all(T[k] <= T[k + 1] for k in range(127)), True)
    print()


# ---------------------------------------------------------------- section 4
def sec4():
    print('4. the level chain in 0xFA7D6A -> staging word 2 (RAM 0x00D762)')
    bytes_at('DE = voice[+0x23]  (the part-record pointer)', 0xFA7D79, '9a 23 22')
    bytes_at('BC = part[+0x0B]   (CC 7)  ; add BC,IX (the caller argument)', 0xFA7D7E, '9a 0b 21 dc 81')
    bytes_at('WA = part[+0x0E]   (CC 11) ; add BC,WA', 0xFA7D86, '9a 0e 20 d8 81')
    bytes_at('calr 0xFA7D49  (clamp 0..0xFF)', 0xFA7DCA, '1e 7c ff')
    bytes_at('muls WA,2 ; add XWA,0x00FDDE2B (Voice_OutputLevel_Table)', 0xFA7DCD,
             'd8 09 02 00 e8 c8 2b de fd 00')
    bytes_at('ld BC,(XWA) ; ld IX,BC ; add IX,IX   -- the result is DOUBLED', 0xFA7DD7,
             '90 21 d9 8c dc 84')
    bytes_at('add XWA,0x00FDD2AB (Voice_Reg080_NoteField_Table)', 0xFA7E12, 'e8 c8 ab d2 fd 00')
    bytes_at('or BC,IX ; ld (0x00D762),BC', 0xFA7E1A, 'db 89 dc e1 d9 31 0f f2 62 d7 00 51')
    # 0xFA7D49 is the clamp: 0xFF high, 0 low
    bytes_at('0xFA7D49: cp HL,0x00FF -> 0x00FF', 0xFA7D51, 'db cf ff 00')
    bytes_at('0xFA7D49: else cp HL,0 -> 0', 0xFA7D5C, 'db d8')
    print()


# ---------------------------------------------------------------- section 5
def sec5():
    print('5. Voice_OutputLevel_Table (0xFDDE2B) -- 256 u16, EXACT closed form')
    bad = []
    for k in range(256):
        e, m = divmod(k, 16)
        pred = 128 * e + round(128 * math.log2(1 + m / 16))
        if u16(0xFDDE2B + 2 * k) != pred:
            bad.append(k)
    check('T[16e+m] == 128e + round(128*log2(1+m/16)) : mismatches', bad, [])
    check('T[0]', u16(0xFDDE2B), 0x0000)
    check('T[255] (the LAST entry)', u16(0xFDDE2B + 2 * 255), 0x07FA)
    check('2*T[255] fits the 12 bits below the note field', 2 * 0x07FA <= 0x0FFF, True)
    print()


# ---------------------------------------------------------------- section 6
def sec6():
    print('6. Voice_Reg080_NoteField_Table (0xFDD2AB) -- 128 u16, EXACT closed form')
    bad = [n for n in range(128) if u16(0xFDD2AB + 2 * n) != ((2 * (n % 12)) // 3) << 12]
    check('T[n] == (2*(n mod 12) // 3) << 12 : mismatches', bad, [])
    check('T[127] (the LAST entry)', u16(0xFDD2AB + 2 * 127), 0x4000)
    check('every entry lands in bits 14..12 only',
          sorted({u16(0xFDD2AB + 2 * n) & ~0x7000 for n in range(128)}), [0])
    print()


# ---------------------------------------------------------------- section 7
def sec7():
    print('7. Dev10C_WriteAllChanRegs (0xFB713A): word -> register, for the five named registers')
    bytes_at('reg chan+0x0040 <- struct+0x02 (add DE,0x0040)', 0xFB7155, 'da c8 40 00')
    bytes_at('   ... its data fetch ld DE,(XIX+0x02)', 0xFB7163, '9c 02 22')
    bytes_at('reg chan+0x0080 <- struct+0x04 with bit 15 SET', 0xFB7172, 'da c8 80 00')
    bytes_at('   ... ld BC,(XIX+0x04) / set 0x0F,BC', 0xFB717B, '9c 04 21 d9 31 0f')
    bytes_at('reg chan+0x0400 <- struct+0x0E', 0xFB71D4, 'd9 c8 00 04')
    bytes_at('   ... ld BC,(XIX+0x0E)', 0xFB71DD, '9c 0e 21')
    bytes_at('reg chan+0x0800 <- struct+0x18', 0xFB7220, 'd9 c8 00 08')
    bytes_at('   ... ld BC,(XIX+0x18)', 0xFB7229, '9c 18 21')
    bytes_at('reg chan+0x0840 <- struct+0x1A', 0xFB723F, 'd9 c8 40 08')
    bytes_at('   ... ld BC,(XIX+0x1A)', 0xFB7248, '9c 1a 21')
    bytes_at('the LAST write: reg chan+0x0080 again, bit 15 CLEAR', 0xFB7304,
             '9c 04 21 d9 30 0f')
    print()


# ---------------------------------------------------------------- section 8
def sec8():
    print('8. the pitch chain in 0xFA7F28')
    bytes_at('A = voice[+0x05] (the note byte)', 0xFA7F3A, '8c 05 21')
    bytes_at('sll 8,WA ; and WA,0x7F00', 0xFA7F3F, 'd8 ee 08 d8 cc 00 7f')
    bytes_at('add HL,0x0080  -- the half-step centre', 0xFA7F48, 'db c8 80 00')
    bytes_at('ld WA,(0x1505) ; add WA,HL  -- a global transpose word', 0xFA7F4C,
             'd1 05 15 20 db 80')
    bytes_at('HL = voice[+0x23] (part record) ; C = part[+0x15] SIGNED, <<8', 0xFA7F55,
             '9c 23 23 eb 12 8b 15 23 d9 13 d9 ee 08')
    bytes_at('WA = part[+0x13] ; add HL,WA', 0xFA7F68, '9b 13 20 d9 8b d8 83')
    bytes_at('key-follow: sub DE,0x4280 (the fixed-pitch reference)', 0xFA80C7, '31 80 42')
    bytes_at('key-follow == 7: DE = 0x4280 outright', 0xFA80DF, '32 80 42')
    bytes_at('push DE ; calr 0xFA7570 ; ld (XIX+0x08),WA', 0xFA8072, '2a 1e fa f4 ec 12 bc 08 50')
    print('   -- and the two stages that turn voice[+0x06] into staging word 7:')
    bytes_at('0xFA8323: HL = voice[+0x06] ; WA = (0x5A4F) ; add WA,HL', 0xFA832D,
             '99 06 23 d1 4f 5a 20 db 80')
    bytes_at('0xFA8323: calr 0xFA7570 ; ld (XBC+0x0A),WA', 0xFA8337, '1e 36 f2 9e 08 21 e9 12 b9 0a 50')
    bytes_at('0xFA8347: HL = voice[+0x0A] ; BC = (0x1503) ; add DE,HL', 0xFA8353,
             '9c 0a 23 d1 03 15 21 d9 8a db 82')
    bytes_at('0xFA8347: calr 0xFA7570 ; ld (0x00D76C),WA', 0xFA8398,
             '2a 1e d4 f1 f2 6c d7 00 50')
    print()


# ---------------------------------------------------------------- section 9
def sec9():
    print('9. 0xFA7570 saturates to [0, 0x7FFF]')
    bytes_at('and BC,0x8000', 0xFA757D, 'd9 cc 00 80')
    bytes_at('cp HL,0xC000', 0xFA7583, 'db cf 00 c0')
    bytes_at('DE = 0x0000', 0xFA7589, '32 00 00')
    bytes_at('DE = 0x7FFF', 0xFA758E, '32 ff 7f')
    check('0x7FFF / 256 == note 127.996 -- the top of the 128-note range',
          round(0x7FFF / 256.0, 3), 127.996)
    print()


# ---------------------------------------------------------------- section 10
def sec10():
    print('10. 0xFA744F is a 128-entry key map: index = (pitch & 0x7F00) >> 8')
    bytes_at('ld BC,(XIZ+0x0C) ; and BC,0x7F00 ; sra 8,BC', 0xFA7453,
             '9e 0c 21 d9 cc 00 7f d9 ed 08')
    bytes_at('exts XBC ; add XBC,(XIZ+0x08) ; ld A,(XBC)', 0xFA745D, 'e9 13 ae 08 81 81 21')
    print()


# ---------------------------------------------------------------- section 11
def sec11():
    print('11. the four key-zone walkers')
    walkers = {0xFA7467: (0xFA74AA, 8), 0xFA74AB: (0xFA74EC, 6),
               0xFA74ED: (0xFA752E, 6), 0xFA752F: (0xFA756F, 4)}
    for a, (end, stride) in walkers.items():
        # `ld C,imm8` is 0x23 0xNN at +9 in every one of the four
        check('0x%06X stride byte' % a, IMG[a - BASE + 9], 0x23)
        check('0x%06X stride' % a, IMG[a - BASE + 10], stride)
        # every one stores the record's word 0 into 0x00D760
        blob = by(a, end - a + 1)
        check('0x%06X writes staging word 1 (0x00D760)' % a,
              bytes.fromhex('f2 60 d7 00'.replace(' ', '')) in blob, True)
    check('flag mask 0xFA7467', u16(0xFA7467 + 0x1D), 0x6000)
    check('flag mask 0xFA74AB', u16(0xFA74AB + 0x1D), 0x6000)
    check('flag mask 0xFA74ED', u16(0xFA74ED + 0x1D), 0x4000)
    # the `or (XHL+0x01),imm16` opcode run is absent from the fourth
    check('0xFA752F has no `or (XHL+0x01),imm16`',
          bytes.fromhex('9b013e') in by(0xFA752F, 0x41), False)
    # borrowed-name rule: they are NOT copies of one another
    lens = {a: end - a + 1 for a, (end, _) in walkers.items()}
    addrs = sorted(walkers)
    diffs = {}
    for i in range(len(addrs)):
        for j in range(i + 1, len(addrs)):
            a, b = addrs[i], addrs[j]
            n = min(lens[a], lens[b])
            diffs['%06X/%06X' % (a, b)] = sum(1 for k in range(n)
                                              if IMG[a - BASE + k] != IMG[b - BASE + k])
    check('byte lengths', [lens[a] for a in addrs], [68, 66, 66, 65])
    check('pairwise differing bytes over the common prefix', diffs,
          {'FA7467/FA74AB': 29, 'FA7467/FA74ED': 21, 'FA7467/FA752F': 38,
           'FA74AB/FA74ED': 18, 'FA74AB/FA752F': 36, 'FA74ED/FA752F': 36})
    check('no pair is byte-identical', all(v > 0 for v in diffs.values()), True)
    print()


# ---------------------------------------------------------------- section 12
def sec12():
    print('12. chan+0x0800 and chan+0x0840 are written 0xFF80 / 0xFF00 as a pair')
    bytes_at('reset sweep: ld (XBC),0xFF00  (register 0x0840+i)', 0xFB811E, 'b1 02 00 ff')
    bytes_at('reset sweep: ld (XBC),0xFF80  (register 0x0800+i)', 0xFB8132, 'b1 02 80 ff')
    bytes_at('0xFB0200: add BC,0x0840 ; ... ; ld (XBC),0xFF00', 0xFB023A,
             'd9 c8 40 08 ae f8 20 b0 51 ae fc 21 b1 02 00 ff')
    bytes_at('0xFB0200: add BC,0x0800 ; ... ; ld (XBC),0xFF80', 0xFB0253,
             'd9 c8 00 08 ae f8 20 b0 51 ae fc 21 b1 02 80 ff')
    bytes_at('0xFB0200 walks a voice list terminated by >= 0x40', 0xFB022F, '84 26 ce cf 40')
    print()


# ---------------------------------------------------------------- section 13
def sec13():
    print('13. the high-nibble doubling fix-up on staging word 1')
    bytes_at('0xFA8233: ld BC,(0x14FF) ; and BC,0x0004', 0xFA8233, 'd1 ff 14 21 d9 cc 04 00')
    bytes_at('0xFA8244: and HL,0xF000 ; cp HL,0x6000', 0xFA8244, 'db cc 00 f0 db cf 00 60')
    bytes_at('0xFA824E: ld IX,HL ; add IX,IX  (the field is DOUBLED)', 0xFA824E, 'db 8c dc 84')
    bytes_at('0xFA8254: and HL,0x0FFF  (the payload passes through)', 0xFA8254, 'db cc ff 0f')
    bytes_at('0xFA82F0: the same fix-up in 0xFA826C, gated on the same bit', 0xFA82F0,
             'd1 ff 14 21 d9 cc 04 00')
    bytes_at('0xFA8301: and BC,0xF000 ; ld DE,BC ; add DE,DE', 0xFA8301,
             'd9 cc 00 f0 d9 8a da 82')
    bytes_at('0xFA830B: and IX,0x0FFF', 0xFA830B, 'dc cc ff 0f')
    print()


# ---------------------------------------------------------------- section 14
def sec14():
    print('14. controller 64 is a SWITCH with the MIDI threshold of 64')
    bytes_at('mul BC,0x012C ; ld HL,BC ; add BC,0x0009', 0xFAD80B,
             'd9 08 2c 01 d9 8b d9 c8 09 00')
    bytes_at('cp (XIZ+0x0A),0x40   -- the MIDI on/off threshold', 0xFAD81E, '8e 0a 3f 40')
    bytes_at('v >= 0x40: ld WA,DE ; set 0,WA', 0xFAD824, 'da 88 d8 31 00')
    bytes_at('v <  0x40: res 0,BC', 0xFAD833, 'd9 30 00')
    print()


# ---------------------------------------------------------------- section 15
def sec15():
    print('15. internal controllers 0x81 / 0x82 and the pitch unit')
    bytes_at('0x81: sub BC,0x0080 ; ld HL,BC ; add HL,HL   -> (v-0x80)*2', 0xFAD8F9,
             'd9 12 d9 ca 80 00 d9 8b db 83')
    bytes_at('0x81: add BC,0x0013 ; ld (XBC+0x1523),HL  (a WORD)', 0xFAD90C,
             'd9 c8 13 00 e9 12 f3 e5 23 15 53')
    bytes_at('0x82: ld H,(XIZ+0x0A) ; sub H,0x40', 0xFAD920, '8e 0a 26 ce ca 40')
    bytes_at('0x82: add BC,0x0015 ; ld (XBC+0x1523),H  (a BYTE)', 0xFAD92F,
             'd9 c8 15 00 e9 12 f3 e5 23 15 46')
    bytes_at('Voice_ComputePitch: part[+0x15] SIGNED and <<8', 0xFA7F5A, '8b 15 23 d9 13 d9 ee 08')
    bytes_at('Voice_ComputePitch: part[+0x13] added UNSHIFTED', 0xFA7F68, '9b 13 20 d9 8b d8 83')
    check('so 0x81 spans exactly one semitone: 2*0x80 counts / 256 per semitone',
          (2 * 0x80) / 256.0, 1.0)
    check('and 0x82 spans +/-64 semitones', 0x40, 64)
    print()


# ---------------------------------------------------------------- section 16
def sec16():
    print('16. the key-zone structures are read out of the image based at 0x00F00000')
    bytes_at('ExtBoard_ProbeAndInstallBases: ld XBC,0x00F00000 / ld (0x00D7ED),XBC', 0xFB051E,
             '41 00 00 f0 00 f2 ed d7 00 61')
    bytes_at('   ... and (0x00D80D) = 0x00C00000 only when the board answers', 0xFB0594,
             '41 00 00 c0 00 f2 0d d8 00 61')
    bytes_at('ld XWA,(XBC+0x1F)  -- the voice record\'s tone-object pointer', 0xFA81A6,
             'a9 1f 20')
    bytes_at('ld XIX,(0x00D7ED) / cp XWA,XIX / jr ULE', 0xFA81AC, 'e2 ed d7 00 24 ec f0')
    bytes_at('  above the base -> relocate against (0x00D7ED)', 0xFA81B5, 'e2 ed d7 00 24')
    bytes_at('  below it       -> relocate against (0x00D80D)', 0xFA81BC, 'e2 0d d8 00 24')
    bytes_at('ld XWA,(XBC+0x01) / add XWA,XIX   -- a 0-BASED OFFSET + the base', 0xFA81C4,
             'a9 01 20 ec 80')
    bytes_at('ld XIY,(XBC+0x05) / add XIY,XIX   -- a second one', 0xFA81CC,
             'a9 05 25 ec 85')
    bytes_at('ld XBC,(XWA) / add XBC,XIX        -- and a third, nested', 0xFA81E0,
             'a0 21 ec 81')
    bytes_at('inc 4,XWA / add XWA,(XIZ-12) / ld L,(XWA)  -- byte[4 + zone]', 0xFA81EC,
             'e8 64 ae f4 80 80')
    print()


def main():
    global QUIET
    args = sys.argv[1:]
    QUIET = '--quiet' in args
    for fn in (sec1, sec2, sec3, sec4, sec5, sec6, sec7, sec8, sec9, sec10, sec11, sec12, sec13, sec14, sec15, sec16):
        fn()
    print('FAILURES: %d' % len(FAILURES))
    for f in FAILURES:
        print('  ' + f)
    return 1 if FAILURES else 0


if __name__ == '__main__':
    sys.exit(main())
