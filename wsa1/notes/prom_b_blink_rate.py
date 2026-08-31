#!/usr/bin/env python3
"""How often does the prom_b field-blink engine at 0xF0E800 toggle?

QUESTION ANSWERED
  0xF0E83A increments (0x28D1), masks it with 7, and draws the live text at
  phase 0 and eight ROM spaces at phase 4.  That is a 50%-duty blink with an
  8-event period -- but an event is not a second.  This script walks the whole
  clock chain from the crystal to the toggle, RE-READING every ROM byte the
  chain rests on, so the rate is a measurement and not a story.

THE CHAIN, one link per check below
  1. fc = 28 MHz and timer 1's prescaler is /2048.  NOT re-derived here: it is
     established in notes/FINDINGS-system-clock.md (fc from prom_c[0xFFFFEF];
     the /2048 tmp94c241 scale from the firmware's own 1750 constant).  This
     script only re-reads TREG1 and T01MOD and asserts the values that note
     quotes, so a change in either is caught.
  2. INTT1 rate = fc / 2048 / (TREG1+1)?  NO -- the note's arithmetic is
     28e6/2048/28, i.e. TREG1 is used as the divisor directly.  Re-read here.
  3. prom_a 0xF82DE5: (0x86) counts 0,1,2 and (0x87) is incremented on each
     wrap, so the rota advances one slot per THREE INTT1 ticks.
  4. prom_a 0xF82E23: the rota slot is ((0x87) & 0x0F) * 4 into the 16-entry
     table at 0xF82E38, so a given slot recurs every 16 advances.
  5. Exactly one of those 16 slots clears bit 7 of (0x88) (`res 7,(0x88)`).
  6. prom_a 0xF82182: `tset 7,(0x88) / jr NZ` -- the main loop calls the blink
     tick only when the rota has cleared the bit since the last pass, and the
     tset sets it again, so the tick runs ONCE PER CLEAR.
  7. prom_b 0xF0E83F/0xF0E864/0xF0E8B3: the tick's own counter is masked with 7
     and acts at phase 0 (draw) and phase 4 (blank).

⚠ WHAT THIS DOES NOT PROVE
  Link 6 assumes the main loop iterates FASTER than the rota clears the bit.
  That is not established -- the loop's period is not measured anywhere in this
  tree.  So the figure below is an UPPER BOUND on the blink rate (equivalently,
  a LOWER bound on the blink period).  If the loop were slower, the blink would
  be slower, never faster.

RUN
  python3 notes/prom_b_blink_rate.py
Exit status is non-zero if any ROM byte the chain rests on has changed.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAIL = []


def check(msg, cond):
    print("  %-64s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def main():
    a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    A, B = 0xF80000, 0xF00000
    ra = lambda p, n: a[p - A:p - A + n]
    rb = lambda p, n: b[p - B:p - B + n]

    print("link 1-2: timer 1's programming (prom_a RESET block)")
    treg1 = ra(0xF826F4, 3)
    check("0xF826F1 writes T01MOD (SFR 0x22) = 0x0F",
          ra(0xF826F1, 3) == bytes([0x08, 0x22, 0x0F]))
    check("0xF826F4 writes TREG1 (0x23) = 0x1C = 28", treg1 == bytes([0x08, 0x23, 0x1C]))
    fc = 28_000_000
    presc = 2048
    div = treg1[2]
    intt1 = fc / presc / div
    print("     fc %d Hz / prescaler %d / TREG1 %d = INTT1 %.4f Hz"
          % (fc, presc, div, intt1))
    check("that reproduces FINDINGS-system-clock.md's 488.28 Hz",
          abs(intt1 - 488.28) < 0.01)
    print()

    print("link 3: (0x86) counts 0,1,2; (0x87) advances on the wrap  [0xF82DE5]")
    seq = ra(0xF82DE5, 17)
    want = bytes([0xC0, 0x86, 0x21,       # ld A,(0x86)
                  0xC9, 0x61,             # inc 1,A
                  0xC9, 0xDA,             # cp A,2
                  0x63, 0x05,             # jr ULE,+5
                  0xC9, 0xA1,             # sub A,A
                  0xC0, 0x87, 0x61,       # inc 1,(0x87)
                  0xF0, 0x86, 0x41])      # ld (0x86),A
    check("0xF82DE5..0xF82DF5 is that exact 17-byte sequence", seq == want)
    ticks_per_slot = 3
    slot_hz = intt1 / ticks_per_slot
    print("     rota advances %.4f slots/s" % slot_hz)
    print()

    print("link 4-5: the 16-entry rota table at 0xF82E38, and who clears bit 7")
    check("0xF82E23 is `ld A,(0x87) / and A,0x0f / sll 2,A`",
          ra(0xF82E23, 9) == bytes([0xC0, 0x87, 0x21, 0xC9, 0xCC, 0x0F,
                                    0xC9, 0xEE, 0x02]))
    tbl = [int.from_bytes(ra(0xF82E38 + 4 * i, 4), "little") for i in range(16)]
    # a leaf clears bit 7 iff its first three bytes are `f0 88 b7` = res 7,(0x88)
    b7 = [i for i, t in enumerate(tbl) if ra(t, 3) == bytes([0xF0, 0x88, 0xB7])]
    print("     slots whose leaf is `res 7,(0x88)`: %s" % b7)
    check("exactly one of the 16 slots clears bit 7", len(b7) == 1)
    check("that leaf is 0xF82E99", tbl[b7[0]] == 0xF82E99 if b7 else False)
    clears_hz = slot_hz / 16
    print("     bit 7 of (0x88) is cleared %.4f times/s" % clears_hz)
    print()

    print("link 6: the main loop's gate  [prom_a 0xF82182]")
    check("0xF82182 is `tset 7,(0x88)` (f0 88 af)",
          ra(0xF82182, 3) == bytes([0xF0, 0x88, 0xAF]))
    check("0xF82185 is `jr NZ,+8` and 0xF8218B is `call 0xF42E2C`",
          ra(0xF82185, 2) == bytes([0x6E, 0x08])
          and ra(0xF8218B, 4) == bytes([0x1D, 0x2C, 0x2E, 0xF4]))
    check("thunk T_F42E2C is `jp 0xF0E83A` (the blink tick)",
          rb(0xF42E2C, 4) == bytes([0x1B, 0x3A, 0xE8, 0xF0]))
    print()

    print("link 7: the tick's own 8-phase counter  [prom_b 0xF0E83A]")
    check("0xF0E83F is `inc 1,(0x28d1)`",
          rb(0xF0E83F, 4) == bytes([0xC1, 0xD1, 0x28, 0x61]))
    check("0xF0E864 is `ld C,(0x28d1) / and C,0x07 / jr NZ` (phase 0 arm)",
          rb(0xF0E864, 9) == bytes([0xC1, 0xD1, 0x28, 0x23, 0xCB, 0xCC, 0x07, 0x6E, 0x46]))
    check("0xF0E8B3 is the same then `cp C,4 / jr NZ` (phase 4 arm)",
          rb(0xF0E8B3, 11) == bytes([0xC1, 0xD1, 0x28, 0x23, 0xCB, 0xCC, 0x07,
                                     0xCB, 0xDC, 0x6E, 0x46]))
    check("phase 0 pushes 1 (draw) and phase 4 pushes 0 (blank)",
          rb(0xF0E881, 3) == bytes([0x0B, 0x01, 0x00])
          and rb(0xF0E8D2, 3) == bytes([0x0B, 0x00, 0x00]))
    period = 8 / clears_hz
    print()
    print("RESULT (an UPPER bound on the rate -- see the caveat above)")
    print("  blink period  %.4f s   =  %.4f Hz" % (period, 1 / period))
    print("  on  %.4f s   off %.4f s   (50%% duty: phase 0 draws, phase 4 blanks)"
          % (period / 2, period / 2))
    print()
    print("self-checks: %d failed" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
