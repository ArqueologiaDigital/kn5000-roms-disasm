#!/usr/bin/env python3
"""Derive the SX-WSA1R system clock (fc) from the firmware.

QUESTION THIS ANSWERS
    What crystal frequency do the two TMP95C061AF processors run at?
    The service manual parts list never ties an oscillator to a processor,
    so the number has to come out of the ROMs.

RUN
    python3 scripts/analysis/derive_system_clock.py

It reads only original_ROMs/ and prints PASS/FAIL for every byte-level claim
that the derivation rests on.  Two independent levers are checked:

  LEVER 1 -- MIDI baud rate.  Serial channel 0 of both CPUs is put in 8-bit
    UART mode clocked from the baud-rate generator, and prom_a's SC0 is
    demonstrably the MIDI port (it transmits the System Real-Time status
    bytes F8/FA/FB/FC/FE and parses F7).  The TLCS-900/H baud chain is

        bit rate = fc / (N << S) / 16
        N = BRxCR[3:0]   (0 means 16)
        S = 2*(BRxCR[5:4] + 1)   ->  taps fc/4, fc/16, fc/64, fc/256

    The tap table is MAME's (src/devices/cpu/tlcs900/tmp94c241_serial.cpp
    lines 305-318, "m_hz = fc / (divisor << shift_amount)") and is confirmed
    by the annotations already carried in ../kn5000-roms-disasm
    (v142/subcpu/kn5000_subprogram_v142.s:94 "T0 (4/fc)",
     v9/maincpu/ui/cpanel_routines.s:104 "T2 (16/fc)" and :650 "T8 (64/fc)").
    The extra /16 is UART oversampling; it is validated end to end against
    the KN5000 subcpu, which at 20 MHz writes BR1CR=0x0A in 8-bit UART mode
    and must come out at MIDI rate: 20e6/(10<<2)/16 = 31250.000 exactly.

  LEVER 2 -- sequencer tempo constant.  prom_a's INTTR4 handler is a musical
    clock that counts 96 ticks per beat, and the tempo setter computes
    TREG5 = round(140000000 / (64*BPM)).  With 16-bit timer 4 clocked from
    phi_T1 = fc/8 the tick period is 8*TREG5/fc, so

        BPM = 60*fc / (768 * TREG5)   =>   the constant must equal 5*fc.

    140,000,000 = 5 * 28,000,000.  This lever needs no MIDI assumption.

The two levers are independent of each other and agree exactly.
"""

import os, struct, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
ROMS = os.path.join(ROOT, "original_ROMs")
BASE = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
FILES = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13", "c": "wsa1_prom_c.ic28"}

img = {k: open(os.path.join(ROMS, v), "rb").read() for k, v in FILES.items()}
fails = []

def at(rom, addr, n=1):
    off = addr - BASE[rom]
    assert 0 <= off < len(img[rom]), f"0x{addr:06X} outside prom_{rom}"
    return img[rom][off:off + n]

def check(label, rom, addr, expect):
    got = at(rom, addr, len(expect))
    ok = got == expect
    if not ok:
        fails.append(label)
    print(f"  [{'PASS' if ok else 'FAIL'}] prom_{rom} 0x{addr:06X} "
          f"(file 0x{addr - BASE[rom]:05X}): {got.hex(' ')}   {label}")
    return ok

def baud_divisor(brcr):
    """Total fc divisor for one BRxCR byte in 8-bit UART mode."""
    n = brcr & 0x0F or 16
    shift = (((brcr >> 4) & 3) + 1) * 2
    return (n << shift) * 16

print(__doc__.split("RUN")[0].strip())
print()

print("LEVER 1 -- SC0 is the MIDI port (prom_a)")
# The INTTX0 path emits the five MIDI System Real-Time status bytes to SC0BUF.
for addr, byte, name in ((0xFA544F, 0xFC, "Stop"), (0xFA5457, 0xF8, "Timing Clock"),
                         (0xFA545F, 0xFE, "Active Sensing"), (0xFA5467, 0xFA, "Start"),
                         (0xFA546F, 0xFB, "Continue")):
    check(f"ld (SC0BUF),0x{byte:02X}  = MIDI {name}", "a", addr,
          bytes((0x08, 0x50, byte)))
check("ld (SC0BUF),0xF6  = MIDI Tune Request", "a", 0xFA7D76, b"\x08\x50\xf6")
check("ld A,(SC0CR); and A,0x1C  = read OERR/PERR/FERR", "a", 0xFA5497,
      b"\xc0\x51\x21\xc9\xcc\x1c")
check("cp A,0xF7  = MIDI End-of-SysEx test in the RX path", "a", 0xFA54B6, b"\xc9\xcf\xf7")
print()

print("LEVER 1 -- the operative BR0CR values")
check("prom_a runtime SC0 init: SC0MOD=0x29 (RXE|8-bit UART|baud gen)", "a", 0xFA58F2,
      b"\x08\x52\x29")
check("prom_a runtime: SC0CR=0x00", "a", 0xFA58F5, b"\x08\x51\x00")
check("prom_a runtime: BR0CR=0x0E", "a", 0xFA58F8, b"\x08\x53\x0e")
check("prom_a runtime: cp (0xFFFFF8),0x24  = build-variant test", "a", 0xFA58FB,
      b"\xc2\xf8\xff\xff\x3f\x24")
check("prom_a runtime: BR0CR=0x0C taken only if that test passes", "a", 0xFA5903,
      b"\x08\x53\x0c")
check("prom_a runtime: SC0BUF=0xFE (first MIDI byte out)", "a", 0xFA5909, b"\x08\x50\xfe")
v = at("a", 0xFFFFF8)[0]
print(f"  [{'PASS' if v != 0x24 else 'FAIL'}] prom_a 0xFFFFF8 = 0x{v:02X} "
      f"({'!= 0x24, so BR0CR stays 0x0E' if v != 0x24 else 'is 0x24'})")
if v == 0x24:
    fails.append("variant byte")

check("prom_c runtime: ld C,(0xFFFFEF); srl 1,C; and C,0x0F; ld (BR0CR),C", "c", 0xF991A2,
      b"\xc2\xef\xff\xff\x23\xcb\xef\x01\xcb\xcc\x0f\xf0\x53\x43")
check("prom_c runtime: SC0CR=0x00 / SC0MOD=0x29", "c", 0xF991B0,
      b"\x08\x51\x00\x08\x52\x29")
w = at("c", 0xFFFFEF)[0]
brcr_c = (w >> 1) & 0x0F
print(f"  [{'PASS' if brcr_c == 0x0E else 'FAIL'}] prom_c 0xFFFFEF = 0x{w:02X} "
      f"-> BR0CR = (0x{w:02X}>>1)&0x0F = 0x{brcr_c:02X}")
if brcr_c != 0x0E:
    fails.append("prom_c BR0CR")
print()

print("LEVER 1 -- arithmetic")
for brcr in (0x0E, 0x0C, 0x13):
    d = baud_divisor(brcr)
    print(f"  BR0CR=0x{brcr:02X}: N={brcr & 0x0F or 16:2d} tap=fc/{1 << ((((brcr >> 4) & 3) + 1) * 2):<3d}"
          f" -> total divisor {d:4d} -> fc for 31250 baud = {31250 * d:,} Hz")
FC_BAUD = 31250 * baud_divisor(0x0E)
print(f"  => operative divisor is 896, fc = 31250 * 896 = {FC_BAUD:,} Hz")
print()

print("LEVER 2 -- sequencer tempo constant (prom_a)")
check("boot: TRUN=0 / T01MOD=0x0D", "a", 0xF826E8, b"\x08\x20\x00\x08\x24\x0d")
check("boot: TREG0=0x0F / TREG1=0x1C", "a", 0xF826F1, b"\x08\x22\x0f\x08\x23\x1c")
check("boot: T4MOD=0x05 (timer 4 clocked from phi_T1)", "a", 0xF82703, b"\x08\x38\x05")
check("boot: TREG4=0x0001", "a", 0xF8270C, b"\x08\x30\x01\x08\x31\x00")
check("boot: TREG5=0x3D09 = 15625", "a", 0xF82712, b"\x08\x32\x09\x08\x33\x3d")
check("boot: TRUN=0xB7 (prescaler + T0,T1,T2,T4,T5)", "a", 0xF8272A, b"\x08\x20\xb7")
check("INTTR4 handler: beat counters wrap at 0x60 = 96 ticks/beat", "a", 0xF82EAF,
      b"\x83\x61\x83\x3f\x60")
check("tempo setter: ld DE,0x0040 / mul XWA,DE / ld XDE,0x08583B00 / div XDE,WA",
      "a", 0xFAA373, b"\x32\x40\x00\xda\x40\x42\x00\x3b\x58\x08\xd8\x52")
check("tempo setter: ld (TREG5),DE", "a", 0xFAA38D, b"\xf0\x32\x52")
check("out-of-range fallback: ld WA,0x4735 (= TREG5 for 120 BPM)", "a", 0xFA5559,
      b"\x30\x35\x47")
check("too-fast clamp: ld WA,0x1C7B (= TREG5 for 300 BPM)", "a", 0xFA554A,
      b"\x30\x7b\x1c")
K = struct.unpack("<I", at("a", 0xFAA378 + 1, 4))[0]
print(f"  constant = 0x{K:08X} = {K:,}")
FC_TEMPO = K // 5
print(f"  BPM = 60*fc/(768*TREG5) and TREG5 = K/(64*BPM)  =>  K = 5*fc")
print(f"  => fc = {K:,} / 5 = {FC_TEMPO:,} Hz")
print(f"  cross-checks: boot TREG5 15625 -> {K / 64 / 15625:.1f} BPM;"
      f" 0x4735 -> {K / 64 / 0x4735:.2f} BPM; 0x1C7B -> {K / 64 / 0x1C7B:.1f} BPM")
print()

print("RESULT")
print(f"  lever 1 (MIDI baud)     : fc = {FC_BAUD:,} Hz")
print(f"  lever 2 (tempo constant): fc = {FC_TEMPO:,} Hz")
agree = FC_BAUD == FC_TEMPO
print(f"  {'AGREE' if agree else 'DISAGREE'}")
if not agree:
    fails.append("levers disagree")
print()

print("NULL -- how wide is the window the baud divisor alone allows?")
for tol in (0.01, 0.02, 0.03):
    lo, hi = 896 * 31250 * (1 - tol), 896 * 31250 * (1 + tol)
    print(f"  +/-{tol * 100:.0f}% on 31250 baud -> fc in [{lo / 1e6:.3f}, {hi / 1e6:.3f}] MHz")
print("  catalogue crystals inside the +/-1% window:")
for x in (28.000e6, 28.224e6, 27.720e6):
    print(f"    {x / 1e6:7.3f} MHz -> {x / 896:9.2f} baud ({(x / 896 / 31250 - 1) * 100:+.2f}%)")
print("  so the baud divisor BOUNDS fc but does not pin it; the tempo")
print("  constant does, because 5*28.224e6 = 141,120,000 != 140,000,000.")
print()

if fails:
    print("FAILED:", ", ".join(fails))
    sys.exit(1)
print("PASS: every byte this derivation cites is present as quoted.")
