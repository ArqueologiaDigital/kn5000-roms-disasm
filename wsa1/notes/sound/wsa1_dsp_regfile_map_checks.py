#!/usr/bin/env python3
"""The 4 x 32 register file at CPU 1's 0x007F0000 / CPU 2's 0x00E00000: which registers
does the firmware actually write, and how wide are they?

QUESTION IT ANSWERS
  `dsp/dsp_channel_regs.s` proves ONE SOURCE drives both processors' copies.  It does not
  say which of each channel's 32 registers the firmware ever touches.  This does, from the
  bytes of `original_ROMs/wsa1_prom_a.ic12` and `original_ROMs/wsa1_prom_c.ic28`.

  ★ AND IT USES A SECOND, NON-SHARED DRIVER AS A CONTROL.  prom_a carries an INDEPENDENT
  driver for the same file -- `Dev7F_WriteSlot8` at 0xF83197 and the init sweep at
  0xF831EE -- written with a different calling convention and a different instruction for
  the same bit (`or W,0x10` against the shared driver's `set 0x04,A`).  It reaches the
  SAME nine registers per channel.  A window agreed on by two routines that share no bytes
  is a fact about the DEVICE, not about one author's habit.

WHAT EACH SECTION PROVES
   1  the one per-CPU value: three base literals per image, differing in one byte, 0x7F
      against 0xE0, and nothing else in the 234-byte block.
   2  the register index: `<< 5` then bit 4 set -- (channel << 5) | 0x10 -- at every site
      in both drivers, and the loop counts 8 and 4.
   3  register (channel << 5) | 0x1F is written 0x01, in BOTH drivers, and only there.
   4  the WINDOW: nine of each channel's 32 registers are written and twenty-three are not.
   5  the literal census over the whole of each image: five `0x007F0000` operands in prom_a,
      three `0x00E00000` in prom_c, and NO cross-naming.  No read-back is located.

RUN
  python3 notes/sound/wsa1_dsp_regfile_map_checks.py
  python3 notes/sound/wsa1_dsp_regfile_map_checks.py --selftest
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A = open(os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_a.ic12'), 'rb').read()
C = open(os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28'), 'rb').read()
BASE = 0xF80000
FAILURES = []
QUIET = False


def by(img, addr, n):
    return img[addr - BASE:addr - BASE + n]


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILURES.append('%s: got %r want %r' % (label, got, want))
    if not QUIET:
        print('  %-64s %s' % (label, 'OK' if ok else 'FAIL got=%r want=%r' % (got, want)))


def hx(img, label, addr, hexstr):
    want = bytes(int(x, 16) for x in hexstr.split())
    check('%s @0x%06X' % (label, addr), by(img, addr, len(want)).hex(' '), want.hex(' '))


# ---------------------------------------------------------------- 1
def sec1_bases():
    if not QUIET:
        print('=== 1. the one per-CPU value ===')
    hx(A, 'prom_a DSP_ChannelRegs_Init        ld XBC,0x007F0000', 0xF85F40, '41 00 00 7f 00')
    hx(C, 'prom_c DSP_ChannelRegs_Init        ld XBC,0x00E00000', 0xF98031, '41 00 00 e0 00')
    hx(A, 'prom_a DSP_ChannelRegs_Write8      ld XBC,0x007F0000', 0xF85F66, '41 00 00 7f 00')
    hx(C, 'prom_c DSP_ChannelRegs_Write8      ld XBC,0x00E00000', 0xF98057, '41 00 00 e0 00')
    hx(A, 'prom_a DSP_WriteChannelRegs_Inner  ld XIY,0x007F0000', 0xF85FB4, '45 00 00 7f 00')
    hx(C, 'prom_c DSP_WriteChannelRegs_Inner  ld XIY,0x00E00000', 0xF980A5, '45 00 00 e0 00')
    diff = [i for i in range(234) if by(A, 0xF85F0F + i, 1) != by(C, 0xF98000 + i, 1)]
    check('231 of the 234 bytes are identical', 234 - len(diff), 231)
    check('...and the three that differ are the base literals', diff, [0x034, 0x05A, 0x0A8])


# ---------------------------------------------------------------- 2
def sec2_index():
    if not QUIET:
        print('=== 2. the register index is (channel << 5) | 0x10 ===')
    hx(A, 'shared driver, Write8: sll 0x05,A / set 0x04,A', 0xF85F60, 'c9 ee 05 c9 31 04')
    hx(C, '  ...the same bytes on CPU 2', 0xF98051, 'c9 ee 05 c9 31 04')
    hx(A, 'shared driver, Inner:  sll 0x05,A / set 0x04,A', 0xF85FAE, 'c9 ee 05 c9 31 04')
    hx(C, '  ...the same bytes on CPU 2', 0xF9809F, 'c9 ee 05 c9 31 04')
    hx(A, 'shared driver, Write8: ldb d,0x08 -- eight registers', 0xF85F6B, '24 08')
    hx(C, '  ...the same on CPU 2', 0xF9805C, '24 08')
    hx(A, 'CONTROL, prom_a-only Dev7F_WriteSlot8: sll 0x05,W then or W,0x10',
       0xF83197, 'c8 ee 05')
    hx(A, '  ...the bit set with a DIFFERENT instruction', 0xF831A5, 'c8 ce 10')
    hx(A, '  ...and its own loop count, ldw bc,0x0008', 0xF8319F, '31 08 00')
    hx(A, '  ...index port at +0, data port at +2, index bumped by one',
       0xF831A8, 'b4 40 bc 02 41 c8 61')
    # DERIVED, not restated: shift count, bit number and loop count read as operands
    shift_a = by(A, 0xF85F62, 1)[0]           # the imm of `sll 0x05,A`
    bit_a = by(A, 0xF85F65, 1)[0]             # the imm of `set 0x04,A`
    cnt_a = by(A, 0xF85F6C, 1)[0]             # the imm of `ldb d,0x08`
    bit_ctl = by(A, 0xF831A7, 1)[0]           # the imm of `or W,0x10`
    cnt_ctl = by(A, 0xF831A0, 2)              # the imm of `ldw bc,0x0008`
    check('shift, bit, count read as OPERANDS from the shared driver',
          (shift_a, bit_a, cnt_a), (5, 4, 8))
    check('...and the control driver reaches the same base by a different route',
          (bit_ctl, 1 << bit_a, cnt_ctl.hex(' ')), (0x10, 0x10, '08 00'))


# ---------------------------------------------------------------- 3
def sec3_reg1f():
    if not QUIET:
        print('=== 3. register (channel << 5) | 0x1F := 0x01 ===')
    hx(A, 'shared driver: ld XWA,0x0101001F / ldb d,0x04', 0xF85F45, '40 1f 00 01 01 24 04')
    hx(C, '  ...the same on CPU 2', 0xF98036, '40 1f 00 01 01 24 04')
    hx(A, 'shared driver: ld W,A / ld (XBC),XWA / add A,0x20', 0xF85F4C, 'c9 88 b1 60 c9 c8 20')
    hx(C, '  ...the same on CPU 2', 0xF9803D, 'c9 88 b1 60 c9 c8 20')
    hx(A, 'CONTROL, prom_a-only sweep: ldw bc,0x04 / ldb w,0x1f / ldb a,0x01',
       0xF831F3, '31 04 00 20 1f 21 01')
    hx(A, '  ...same 32-bit store, same stride', 0xF83207, 'b4 60 ed 88 c8 c8 20')
    # DERIVED: the register number and the value out of the one imm32, and the stride
    imm = by(A, 0xF85F46, 4)                   # the operand of `ld XWA,0x0101001F`
    check('the shared driver\'s imm32 is register 0x1F in W:A and 0x01 in the data half',
          (imm[0], imm[1], imm[2], imm[3]), (0x1F, 0x00, 0x01, 0x01))
    check('...stepped by 0x20 four times, so channels 0..3 -> 0x1F 0x3F 0x5F 0x7F',
          [0x1F + 0x20 * n for n in range(by(A, 0xF85F4A, 2)[1])],
          [0x1F, 0x3F, 0x5F, 0x7F])
    check('the control driver states the same two numbers as separate immediates',
          (by(A, 0xF831F7, 1)[0], by(A, 0xF831F9, 1)[0], by(A, 0xF8320D, 1)[0]),
          (0x1F, 0x01, 0x20))


# ---------------------------------------------------------------- 4
def sec4_window():
    if not QUIET:
        print('=== 4. the window: nine registers of thirty-two ===')
    # built from the operands section 2 and 3 read, never typed as a list
    base = 1 << by(A, 0xF85F65, 1)[0]              # `set 0x04,A`  -> 0x10
    count = by(A, 0xF85F6C, 1)[0]                  # `ldb d,0x08`  -> 8
    arm = by(A, 0xF85F46, 1)[0]                    # imm32 low byte -> 0x1F
    written = list(range(base, base + count)) + [arm]
    check('registers written, per channel, DERIVED from three operands', written,
          [0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x1F])
    check('...nine of thirty-two', len(written), 9)
    check('...and the eight data registers end one short of the armed one',
          (base + count, arm), (0x18, 0x1F))
    check('...so twenty-three per channel are NEVER written by either driver',
          len([r for r in range(0x20) if r not in written]), 23)
    check('four channels: 4 * 9 = 36 registers touched of 128', 4 * len(written), 36)


# ---------------------------------------------------------------- 5
def sec5_census():
    if not QUIET:
        print('=== 5. the literal census, whole images ===')

    def cen(img, lit):
        out = []
        i = 0
        needle = lit.to_bytes(4, 'little')
        while True:
            j = img.find(needle, i)
            if j < 0:
                break
            if img[j - 1] in (0x41, 0x44, 0x45):      # ld XBC/XIX/XIY,imm32
                out.append(BASE + j - 1)
            i = j + 1
        return out

    a7f, ae0 = cen(A, 0x007F0000), cen(A, 0x00E00000)
    c7f, ce0 = cen(C, 0x007F0000), cen(C, 0x00E00000)
    if not QUIET:
        print('    prom_a 0x007F0000: %s' % ' '.join('0x%06X' % x for x in a7f))
        print('    prom_c 0x00E00000: %s' % ' '.join('0x%06X' % x for x in ce0))
    check('prom_a names 0x007F0000 in five operands', a7f,
          [0xF8319A, 0xF831EE, 0xF85F40, 0xF85F66, 0xF85FB4])
    check('...three in the shared driver, two in the prom_a-only control driver',
          [x for x in a7f if x < 0xF85000], [0xF8319A, 0xF831EE])
    check('prom_c names 0x00E00000 in three operands, all in the shared driver',
          ce0, [0xF98031, 0xF98057, 0xF980A5])
    check('prom_a NEVER names 0x00E00000', ae0, [])
    check('prom_c NEVER names 0x007F0000', c7f, [])


SECTIONS = [sec1_bases, sec2_index, sec3_reg1f, sec4_window, sec5_census]


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
