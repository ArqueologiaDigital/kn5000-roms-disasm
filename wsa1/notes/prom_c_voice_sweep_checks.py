#!/usr/bin/env python3
"""prom_c VOICE-SWEEP CHECKS -- what the firmware READS BACK from 0x0010C000.

WHAT QUESTION THIS ANSWERS
--------------------------
Gap **F** of ../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md:

    "Register block 0x0180 + channel is read at 0xFA69B1 and kept as (value & 0x3FFF) >> 5;
     register 0x0000 + n for n = 0..3 is read at 0xFA690A and OR-ed into a shadow at
     0x0087C7.  Is the first really a per-voice envelope level, and is the second really an
     active-voice bitmap of 16 channels per bank?"

The driver's `tg_status_r()` answers 0 to both and says in as many words that answering 0
is a decision.  This script asserts, from the ROM BYTES of `original_ROMs/wsa1_prom_c.ic28`
alone -- never from `prom_c/wsa1_prom_c.s` and never from unidasm's text -- every
instruction the answer rests on.

WHAT IS ESTABLISHED (see notes/FINDINGS-prom_c-voice-readback.md for the argument)
  * The read at select `0x0000 + n`, n = 0..3, IS used as a 16-channel bitmap: bit i of
    the word read at select n is paired, inside one loop, with hardware channel 16n+i.
  * The SAME encoding -- `1 << (chan & 15)` at word index `chan >> 4` -- is built by two
    unrelated routines for the two RAM masks at 0x0087BF and 0x0087C7, which is a second,
    independent witness that this is the device's own channel numbering.
  * A channel whose bit DROPS out of that word is torn down: `Dev10C_ChanReset(chan)`.
    So a set bit is the channel still being busy, not still being free.
  * The read at select `0x0180 + chan` is masked `& 0x3FFF`, shifted right 5 and TRUNCATED
    TO A BYTE, so what is kept is bits 12..5; it is cached in the channel record and
    compared against 0x80.

WHAT IS **NOT** ESTABLISHED, and is not asserted anywhere here
  * That the 0x0180 quantity is an envelope level.  What is proven is that the firmware
    treats it as a magnitude that FALLS and that crossing below 0x80 means the voice is
    done -- nothing here ties it to amplitude, to a sample position or to time.
  * What the device does on a WRITE to block 0 (it is written per channel with 0x8100 and
    with 0x7E00; the read uses index 0..3).  Read and write are asserted separately.
  * The meanings of channel-record flag bits 1 and 2.

USAGE
    python3 notes/prom_c_voice_sweep_checks.py            # FAILURES must be 0
    python3 notes/prom_c_voice_sweep_checks.py --verbose  # print every value read
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
BASE = 0xF80000

fails = 0
verbose = "--verbose" in sys.argv


def at(addr, n):
    return IMG[addr - BASE: addr - BASE + n]


def check(name, got, want):
    global fails
    ok = got == want
    if not ok:
        fails += 1
    if verbose or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}: got {got!r}, want {want!r}")
    else:
        print(f"  ok    {name}")


def hexs(addr, n):
    return at(addr, n).hex(" ")


print("1. Dev10C_PollBankAndRetire: the bank cursor, and the read at select 0..3")
check("0xFA68E3 inc 1,(0x0087CF)", hexs(0xFA68E3, 5), "c2 cf 87 00 61")
check("0xFA68ED and H,0x03 -- so the cursor runs 0..3", hexs(0xFA68ED, 3), "ce cc 03")
check("0xFA68FC ld XIX,0x0010C000", hexs(0xFA68FC, 5), "44 00 c0 10 00")
check("0xFA6901 ld (XIX),BC -- SELECT = the bank number, nothing added",
      hexs(0xFA6901, 2), "b4 51")
check("0xFA6905 inc 4,XBC -- the readback port is +4", hexs(0xFA6905, 2), "e9 64")
check("0xFA690A ld HL,(XBC) -- one 16-bit word per bank", hexs(0xFA690A, 2), "91 23")

print("2. the loop that pairs bit i of that word with channel 16n+i")
check("0xFA694A sll 0x04,C -- channel base = bank * 16", hexs(0xFA694A, 2), "cb ee")
check("0xFA694F mul C,0x17 -- channel record stride 23", hexs(0xFA694F, 3), "cb 08 17")
check("0xFA6954 ld WA,0x04E8 -- channel record array base", hexs(0xFA6954, 3), "30 e8 04")
check("0xFA695C ld (XIZ-10),0x0001 -- the bit walker starts at bit 0",
      hexs(0xFA695C, 5), "be f6 02 01 00")
check("0xFA696D add BC,0x0180 -- the per-channel select is 0x0180 + channel",
      hexs(0xFA696D, 4), "d9 c8 80 01")
check("0xFA69E2 add (XIZ-8),0x0017 -- record pointer steps by the same 23",
      hexs(0xFA69E2, 5), "9e f8 38 17 00")
check("0xFA69E7 sllw (XIZ-10) -- a 16-bit word shifted left until zero = 16 passes",
      hexs(0xFA69E7, 3), "9e f6 7e")
# the LAST iteration of the LAST bank, computed from those same operands
last_chan = 3 * 16 + 15
check("last channel the four banks reach", last_chan, 63)
check("its record address 0x04E8 + 23*63", 0x04E8 + 23 * last_chan, 0x0A91)
check("its select 0x0180 + 63", 0x0180 + last_chan, 0x01BF)
check("the array's end, 0x04E8 + 23*64, does not overlap 0x0AA8", 0x04E8 + 23 * 64, 0x0AA8)
walker = 1
for _ in range(16):
    walker = (walker << 1) & 0xFFFF
check("the walker is zero after exactly 16 shifts and not before", walker, 0)

print("3. the same channel encoding, built independently for the two RAM masks")
# 0xFA6CE0-0xFA6D01: ld C,(XIZ-5) / and C,0x0f / push BC / push 1 / call Shift16_Left
check("0xFA6CE3 and C,0x0f -- the bit number is chan & 15", hexs(0xFA6CE3, 3), "cb cc 0f")
check("0xFA6CEA call 0xFCA0BA (Shift16_Left)", hexs(0xFA6CEA, 4), "1d ba a0 fc")
check("0xFA6CF3 srl 0x04,C -- the word index is chan >> 4", hexs(0xFA6CF3, 2), "cb ef")
check("0xFA6CF6 mul C,0x02 -- two bytes per word", hexs(0xFA6CF6, 3), "cb 08 02")
check("0xFA6CFB add XBC,0x000087C7", hexs(0xFA6CFB, 6), "e9 c8 c7 87 00 00")
check("0xFA6D01 or (XBC),HL -- the bit is SET in the 0x87C7 mask",
      hexs(0xFA6D01, 2), "91 eb")
check("0xFA6D37 and (XBC),WA -- and CLEARED there by the sibling arm",
      hexs(0xFA6D37, 2), "91 c8")
check("0xFA6D41 or (XBC),HL -- while 0x87BF gets the bit set", hexs(0xFA6D41, 2), "91 eb")
check("0xFA6EE9 and (XBC),WA -- a third site clears 0x87C7 the same way",
      hexs(0xFA6EE9, 2), "91 c8")
# Shift16_Left really is value << count, with value at (XSP+4) and count at (XSP+6)
check("Shift16_Left 0xFCA0BA reads (XSP+0x04) into IY", hexs(0xFCA0BA, 3), "9f 04 25")
check("Shift16_Left 0xFCA0BD reads (XSP+0x06) into B", hexs(0xFCA0BD, 3), "8f 06 22")

print("4. what the firmware does with the two reads")
check("0xFA6918 add XWA,0x000087C7 -- the read word is OR-ed with the 0x87C7 mask",
      hexs(0xFA6918, 6), "e8 c8 c7 87 00 00")
check("0xFA692F xor WA,HL then 0xFA6931 and WA,HL -- old & ~new",
      hexs(0xFA692F, 4), "db d0 db c0")
check("0xFA6990 call 0xFB0A8B (Dev10C_ChanReset) on a channel that DROPPED out",
      hexs(0xFA6990, 4), "1d 8b 0a fb")
check("0xFA6983 and A,0x01 -- a record already free is skipped", hexs(0xFA6983, 3), "c9 cc 01")
check("0xFA69A7 and A,0x81 -- flag bits 0 and 7 skip the per-channel poll",
      hexs(0xFA69A7, 3), "c9 cc 81")
check("0xFA69AF ld (XWA),HL -- SELECT = 0x0180 + chan", hexs(0xFA69AF, 2), "b0 53")
check("0xFA69B1 ld BC,(XIX) -- READ the +4 port", hexs(0xFA69B1, 2), "94 21")
check("0xFA69B6 and BC,0x3FFF", hexs(0xFA69B6, 4), "d9 cc ff 3f")
check("0xFA69BA srl 0x05,BC", hexs(0xFA69BA, 3), "d9 ef 05")
check("0xFA69BD ld E,C -- TRUNCATED to a byte, so bits 12..5 survive and bit 13 does not",
      hexs(0xFA69BD, 2), "cb 8d")
check("0xFA69C4 ld (XBC+0x15),E -- cached in the channel record", hexs(0xFA69C4, 3), "b9 15 45")
check("0xFA69C7 cp E,0x80 -- the threshold", hexs(0xFA69C7, 3), "cd cf 80")
check("0xFA69D4 and A,0x04 -- and flag bit 2 gates the action", hexs(0xFA69D4, 3), "c9 cc 04")

print("5. the channel record's flag byte, from its writers")
check("0xFA6CDC ld (XDE+0x12),0x88 -- allocated WITH bit 7", hexs(0xFA6CDC, 4), "ba 12 00 88")
check("0xFA6D07 ld (XDE+0x12),0x08 -- allocated WITHOUT bit 7", hexs(0xFA6D07, 4), "ba 12 00 08")
check("0xFA6594 ld (XIX+0x12),0x01 -- released", hexs(0xFA6594, 4), "bc 12 00 01")
check("0xFA6598 ld (XIX+0x15),0x00 -- and the cached level cleared with it",
      hexs(0xFA6598, 4), "bc 15 00 00")
print("   -- so flag bit 7 is set exactly by the arm that SETS the channel's 0x87C7 bit,")
print("      and cleared exactly by the arm that clears it.")

print("6. block 0 is WRITTEN per channel, with two constants")
check("0xFB7234 ld (XBC),HL then 0xFB7239 ld (XBC),0x8100 -- Dev10C_WriteAllChanRegs",
      hexs(0xFB7234, 2) + " | " + hexs(0xFB7239, 4), "b1 53 | b1 02 00 81")
check("0xFB0AB3 ld (XIX),HL then 0xFB0AB5 ld (XIX+0x02),0x7E00 -- Dev10C_ChanReset",
      hexs(0xFB0AB3, 2) + " | " + hexs(0xFB0AB5, 5), "b4 53 | bc 02 02 00 7e")

print("7. VoiceSubsystem_Init: the 64-channel silence sweep, four registers each")
check("0xFA668A ld DE,0x0840", hexs(0xFA668A, 3), "32 40 08")
check("0xFA668D ld HL,0x0800", hexs(0xFA668D, 3), "33 00 08")
check("0xFA6690 ld (XIZ-2),0x00C0", hexs(0xFA6690, 5), "be fe 02 c0 00")
check("0xFA669A ld (XBC),0xFF00   -- to select 0x0840 + chan", hexs(0xFA669A, 4), "b1 02 00 ff")
check("0xFA66A8 ld (XBC),0xFF80   -- to select 0x0800 + chan", hexs(0xFA66A8, 4), "b1 02 80 ff")
check("0xFA66B4 ld (XBC),0x0000   -- to select 0x00C0 + chan", hexs(0xFA66B4, 4), "b1 02 00 00")
check("0xFA66C7 ld (XBC),0x7E00   -- to select 0x0000 + chan", hexs(0xFA66C7, 4), "b1 02 00 7e")
check("0xFA66CB/CD/CF the three selects step by 1 together",
      hexs(0xFA66CB, 2) + " " + hexs(0xFA66CD, 2) + " " + hexs(0xFA66CF, 3),
      "da 61 db 61 9e fe 61")
check("0xFA66D5 cp (XIZ-7),0x40 -- 64 channels", hexs(0xFA66D5, 4), "8e f9 3f 40")

print("8. VoiceSubsystem_Init: the channel-record array is 64 records of 23 bytes")
check("0xFA67FF ld DE,0x04E8 -- the array base", hexs(0xFA67FF, 3), "32 e8 04")
check("0xFA680F ld (XBC+0x14),A -- +0x14 = the record's own index", hexs(0xFA680F, 3), "b9 14 41")
check("0xFA6817 ld (XBC),BC -- +0x00 self-linked", hexs(0xFA6817, 2), "b1 51")
check("0xFA6846 ld (XBC+0x12),0x00 -- the flag byte starts at 0", hexs(0xFA6846, 4), "b9 12 00 00")
check("0xFA684A/52 rec[+0x0C] = 0x041C", hexs(0xFA684A, 3) + " " + hexs(0xFA6852, 3),
      "31 1c 04 b8 0c 51")
check("0xFA685A rec[+0x0E] = 1", hexs(0xFA685A, 4), "b9 0e 00 01")
check("0xFA685E/66 rec[+0x0F] = 0x0200", hexs(0xFA685E, 3) + " " + hexs(0xFA6866, 3),
      "31 00 02 b8 0f 51")
check("0xFA686E rec[+0x11] = 6", hexs(0xFA686E, 4), "b9 11 00 06")
check("0xFA6877 rec[+0x15] = 0", hexs(0xFA6877, 4), "b9 15 00 00")
check("0xFA687D add HL,0x0017 -- ★ THE STRIDE, 23", hexs(0xFA687D, 4), "db c8 17 00")
check("0xFA6884 cp (XIZ-7),0x40 -- ★ THE COUNT, 64", hexs(0xFA6884, 4), "8e f9 3f 40")
check("0xFA68A6 ld (XIZ-7),0x04 -- then all 64 are released and the FOUR mask words cleared",
      hexs(0xFA68A6, 4), "be f9 00 04")
check("0xFA68B0 lda XBC,0x0087BF", hexs(0xFA68B0, 5), "f2 bf 87 00 31")
check("0xFA68BB lda XBC,0x0087C7", hexs(0xFA68BB, 5), "f2 c7 87 00 31")
check("0xFA68C8 inc 2,HL -- two bytes per mask word", hexs(0xFA68C8, 2), "db 62")
# the LAST record, from those same operands
check("record 63 sits at 0x04E8 + 23*63", 0x04E8 + 23 * 63, 0x0A91)
check("record 63's last byte is 0x0AA7, and 0x87BF/0x87C7 are far above it",
      0x04E8 + 23 * 64 - 1, 0x0AA7)

print()
print(f"FAILURES: {fails}")
sys.exit(1 if fails else 0)
