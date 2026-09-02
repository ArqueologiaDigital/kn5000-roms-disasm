#!/usr/bin/env python3
"""mem_prefix_test_sites.py -- the REAL ROM sites behind
llvm/test/MC/TLCS900/mem-prefix-subopcodes.s, and the check that they are real.

THE QUESTION THIS ANSWERS
-------------------------
That lit test claims its byte sequences come out of committed ROM dumps.  A
claim like that rots silently: nothing in the LLVM tree can see these dumps, so
a transcription slip, a re-dump, or an offset copied off the wrong line would
never be noticed.  `--check` re-reads every offset from the dump it names and,
for each site, requires all three of

  1. the ROM bytes at that offset are exactly the bytes the test asserts;
  2. `llvm-mc` assembles the test's asm text back to those same bytes;
  3. `llvm-objdump` disassembles those bytes back to that same asm text.

(2) and (3) together are the property this lane exists to establish: assembler
and disassembler agree, in both directions, on real firmware bytes.  (3) is a
property of the DECODER, so the toolchain commit is printed with the result; a
figure from here means nothing without it.

Each site also records what MAME's `unidasm -arch tlcs900` prints for the same
bytes.  That is an independently written TLCS-900 disassembler, and it is the
reason to believe the NAMES are right rather than merely self-consistent -- a
round-trip cannot tell an ADD called SUB from an ADD.

WHAT THE SITES DO AND DO NOT CLAIM
----------------------------------
Every site with an image name is a statement the disassembly tree's own source
already assembles to those bytes at that offset, so unlike a byte-pattern
search these ARE framed as code by the tree.  Three sites are marked
`no-rom-site`: `jp cc,(mem)` and `call cc,(mem)` (destination sub-opcodes
0xD0-0xEF) occur nowhere in the committed KN5000 images.  They are decoded
because JPCC_m and CALLCC_m are real definitions this backend already encodes
and because unidasm renders those bytes as those instructions -- not because
firmware was found using them.

RUN
    python3 scripts/analysis/mem_prefix_test_sites.py --check
    python3 scripts/analysis/mem_prefix_test_sites.py --foil   # can it fail?
    python3 scripts/analysis/mem_prefix_test_sites.py --emit   # the lit test
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("LLVM_MC") or os.path.join(BIN, "llvm-mc")
OBJDUMP = os.environ.get("LLVM_OBJDUMP") or os.path.join(BIN, "llvm-objdump")
BASE = 0xE00000

ROMS = {
    "v7":  "original_ROMs/kn5000_v7_program.rom",
    "v9":  "original_ROMs/kn5000_v9_program.rom",
    "v10": "original_ROMs/kn5000_v10_program.rom",
}

# (group, image, rom file offset, bytes, this backend's text, unidasm's text)
SITES = [
    # --- ALU r, (mem) and ALU (mem), r -- source memory tables 0x80 / 0x90 / 0xA0 ---
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x142CE7, "8381",
     'add a, (xhl)',
     'add A,(XHL)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x107422, "808b",
     'add (xwa), c',
     'add (XWA),C'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F507A, "82c1",
     'and a, (xde)',
     'and A,(XDE)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x1B59F2, "82d3",
     'xor c, (xde)',
     'xor C,(XDE)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x1B6FF7, "80e3",
     'or c, (xwa)',
     'or C,(XWA)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x10EAAE, "81f1",
     'cp a, (xbc)',
     'cp A,(XBC)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0FAC16, "8d0281",
     'add a, (xiy+2)',
     'add A,(XIY+0x02)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F0046, "888889",
     'add (xwa-120), a',
     'add (XWA+0x88),A'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x1E8DEF, "8e05a1",
     'sub a, (xiz+5)',
     'sub A,(XIZ+0x05)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x197766, "8bdea9",
     'sub (xhl-34), a',
     'sub (XHL+0xde),A'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0FC4FA, "8cccc9",
     'and (xix-52), a',
     'and (XIX+0xcc),A'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x106C2C, "8f10f1",
     'cp a, (xsp+16)',
     'cp A,(XSP+0x10)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x12ACCA, "9081",
     'add bc, (xwa)',
     'add BC,(XWA)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x15FE09, "9090",
     'adc wa, (xwa)',
     'adc WA,(XWA)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F0060, "9595",
     'adc iy, (xiy)',
     'adc IY,(XIY)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x12B61F, "93a0",
     'sub wa, (xhl)',
     'sub WA,(XHL)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x1CCDA4, "90b9",
     'sbc (xwa), bc',
     'sbc (XWA),BC'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x12EE56, "93f0",
     'cp wa, (xhl)',
     'cp WA,(XHL)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F7634, "95f8",
     'cp (xiy), wa',
     'cp (XIY),WA'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F4633, "9f1a80",
     'add wa, (xsp+26)',
     'add WA,(XSP+0x1a)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F149B, "9bfe88",
     'add (xhl-2), wa',
     'add (XHL+0xfe),WA'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x14A970, "9d28b2",
     'sbc de, (xiy+40)',
     'sbc DE,(XIY+0x28)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F15C6, "9bf8f0",
     'cp wa, (xhl-8)',
     'cp WA,(XHL+0xf8)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F44F0, "9f04f8",
     'cp (xsp+4), wa',
     'cp (XSP+0x04),WA'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x1DC42F, "a280",
     'add xwa, (xde)',
     'add XWA,(XDE)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x119011, "a788",
     'add (xsp), xwa',
     'add (XSP),XWA'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x14F63F, "a3f0",
     'cp xwa, (xhl)',
     'cp XWA,(XHL)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x179876, "a6f8",
     'cp (xiz), xwa',
     'cp (XIZ),XWA'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F4F23, "af0c80",
     'add xwa, (xsp+12)',
     'add XWA,(XSP+0x0c)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F331E, "af0288",
     'add (xsp+2), xwa',
     'add (XSP+0x02),XWA'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x1789C9, "af14a0",
     'sub xwa, (xsp+20)',
     'sub XWA,(XSP+0x14)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F3A22, "af04f0",
     'cp xwa, (xsp+4)',
     'cp XWA,(XSP+0x04)'),
    ("ALU r, (mem) and ALU (mem), r", "v10", 0x0F3A00, "af08f8",
     'cp (xsp+8), xwa',
     'cp (XSP+0x08),XWA'),

    # --- ALU (mem), #imm -- source sub-opcodes 0x38-0x3F, byte and word only ---
    ("ALU (mem), #imm", "v10", 0x0F0D82, "833f00",
     'cp (xhl), 0',
     'cp (XHL),0x00'),
    ("ALU (mem), #imm", "v10", 0x101895, "833c7f",
     'andmi8 (xhl), 127',
     'and (XHL),0x7f'),
    ("ALU (mem), #imm", "v10", 0x136F06, "81380b",
     'addmi8 (xbc), 11',
     'add (XBC),0x0b'),
    ("ALU (mem), #imm", "v10", 0x0F1D39, "8c093f03",
     'cp (xix+9), 3',
     'cp (XIX+0x09),0x03'),
    ("ALU (mem), #imm", "v10", 0x116E76, "8f083a1e",
     'submi8 (xsp+8), 30',
     'sub (XSP+0x08),0x1e'),
    ("ALU (mem), #imm", "v10", 0x0FC35E, "953f0000",
     'cpw (xiy), 0',
     'cp (XIY),0x0000'),
    ("ALU (mem), #imm", "v10", 0x17C5F5, "903c7fff",
     'andmi16 (xwa), 65407',
     'and (XWA),0xff7f'),
    ("ALU (mem), #imm", "v10", 0x0F2F48, "9afe3f0000",
     'cpw (xde-2), 0',
     'cp (XDE+0xfe),0x0000'),
    ("ALU (mem), #imm", "v10", 0x0F44B8, "9f06381200",
     'addiw_da (xsp+6), 18',
     'add (XSP+0x06),0x0012'),

    # --- PUSH (mem) -- source sub-opcode 0x04 ---
    ("PUSH (mem)", "v10", 0x102435, "9204",
     'pushm (xde)',
     'pushw (XDE)'),
    ("PUSH (mem)", "v10", 0x0F3C6E, "9f0404",
     'pushm (xsp+4)',
     'pushw (XSP+0x04)'),

    # --- Block transfers -- the prefix's base-register field is part of the encoding ---
    ("Block transfers", "v10", 0x11D280, "8510",
     'ldi85',
     'ldi'),
    ("Block transfers", "v10", 0x0F0BC3, "8311",
     'ldir83',
     'ldir'),
    ("Block transfers", "v10", 0x1016A5, "8313",
     'lddr83',
     'lddr'),
    ("Block transfers", "v10", 0x1F28E0, "8315",
     'cpir83',
     'cpir'),
    ("Block transfers", "v10", 0x109966, "9510",
     'ldiw',
     'ldiw'),
    ("Block transfers", "v10", 0x0F0B64, "9311",
     'ldirw93',
     'ldirw'),

    # --- EX / MUL / MULS / DIV / DIVS / shift on memory -- 0x30-0x5F and 0x78-0x7F ---
    ("EX / MUL / MULS / DIV / DIVS / shift on memory", "v10", 0x1C49C3, "8331",
     'ex (xhl), a',
     'ex (XHL),A'),
    ("EX / MUL / MULS / DIV / DIVS / shift on memory", "v10", 0x19E150, "9648",
     'muls wa, (xiz)',
     'muls XWA,(XIZ)'),
    ("EX / MUL / MULS / DIV / DIVS / shift on memory", "v10", 0x19D960, "9249",
     'muls bc, (xde)',
     'muls XBC,(XDE)'),
    ("EX / MUL / MULS / DIV / DIVS / shift on memory", "v10", 0x1956E7, "9f0c40",
     'mul wa, (xsp+12)',
     'mul XWA,(XSP+0x0c)'),
    ("EX / MUL / MULS / DIV / DIVS / shift on memory", "v10", 0x1F26E0, "907e",
     'sllw (xwa)',
     'sllw (XWA)'),
    ("EX / MUL / MULS / DIV / DIVS / shift on memory", "v10", 0x0F4E85, "9f047f",
     'srlw (xsp+4)',
     'srlw (XSP+0x04)'),

    # --- Destination table bit operations -- LDCF / STCF / TSET / RES / SET / CHG / BIT ---
    ("Destination table bit operations", "v10", 0x18A106, "b09f",
     'ldcfm 7, (xwa)',
     'ldcf 7,(XWA)'),
    ("Destination table bit operations", "v10", 0x1D35A2, "b2a7",
     'stcfm 7, (xde)',
     'stcf 7,(XDE)'),
    ("Destination table bit operations", "v10", 0x0F130E, "b5ae",
     'tsetm 6, (xiy)',
     'tset 6,(XIY)'),
    ("Destination table bit operations", "v10", 0x0F1EBF, "b0b0",
     'resm 0, (xwa)',
     'res 0,(XWA)'),
    ("Destination table bit operations", "v10", 0x106926, "b2bf",
     'setm 7, (xde)',
     'set 7,(XDE)'),
    ("Destination table bit operations", "v10", 0x0F139B, "b5c8",
     'bitm 0, (xiy)',
     'bit 0,(XIY)'),
    ("Destination table bit operations", "v10", 0x1D31B9, "ba0b98",
     'ldcfm 0, (xde+11)',
     'ldcf 0,(XDE+0x0b)'),
    ("Destination table bit operations", "v10", 0x14EBFF, "bf04b2",
     'resm 2, (xsp+4)',
     'res 2,(XSP+0x04)'),
    ("Destination table bit operations", "v10", 0x13B70A, "bf04bf",
     'setm 7, (xsp+4)',
     'set 7,(XSP+0x04)'),
    ("Destination table bit operations", "v10", 0x1098D5, "bb0ec2",
     'chgm 2, (xhl+14)',
     'chg 2,(XHL+0x0e)'),
    ("Destination table bit operations", "v10", 0x1391F9, "bf00cf",
     'bitm 7, (xsp+256)',
     'bit 7,(XSP+0x00)'),

    # --- Destination table, no register in the opcode -- STCF A, (mem) ---
    ("Destination table, no register in the opcode", "v10", 0x106919, "b12c",
     'stcf a, (xbc)',
     'stcf A,(XBC)'),

    # --- RET cc -- the prefix's base-register field again ---
    ("RET cc", "v10", 0x12B00E, "b0f9",
     'ret ge',
     'ret GE'),
    ("RET cc", "v9", 0x0FDB40, "b6f9",
     'ret_cc_ri xiz, 9',
     'ret GE'),

    # --- JP cc, (mem) / CALL cc, (mem) -- destination sub-opcodes 0xD0-0xEF ---
    ("JP cc, (mem) / CALL cc, (mem)", "no-rom-site", 0, "b1d1",
     'jp lt, (xbc)', 'jp LT,XBC'),
    ("JP cc, (mem) / CALL cc, (mem)", "no-rom-site", 0, "b904d2",
     'jp le, (xbc+4)', 'jp LE,XBC+0x04'),
    ("JP cc, (mem) / CALL cc, (mem)", "no-rom-site", 0, "b1e1",
     'call lt, (xbc)', 'call LT,XBC'),

    # --- ALU (addr), #imm -- direct-address sub-opcodes 0x38-0x3F ---
    ("ALU (addr), #imm", "v10", 0x0F5EE0, "c181113830",
     'adddi8 (4481), 48',
     'add (0x1181),0x30'),
    ("ALU (addr), #imm", "v10", 0x14944C, "c1a2253a28",
     'subdi8 (9634), 40',
     'sub (0x25a2),0x28'),
    ("ALU (addr), #imm", "v10", 0x0F0D73, "c122043c6e",
     'anddi8 (1058), 110',
     'and (0x0422),0x6e'),
    ("ALU (addr), #imm", "v10", 0x15C5F4, "c191333d01",
     'xordi8 (13201), 1',
     'xor (0x3391),0x01'),
    ("ALU (addr), #imm", "v10", 0x0F0C35, "c129043e10",
     'ordi8 (1065), 16',
     'or (0x0429),0x10'),
    ("ALU (addr), #imm", "v10", 0x0F05DB, "c102043f04",
     'cpdi8 (1026), 4',
     'cp (0x0402),0x04'),
    ("ALU (addr), #imm", "v10", 0x0F4C54, "d15206381200",
     'adddi16 (1618), 18',
     'add (0x0652),0x0012'),
    ("ALU (addr), #imm", "v10", 0x1EC34C, "d19ad03a0100",
     'subdi16 (53402), 1',
     'sub (0xd09a),0x0001'),
    ("ALU (addr), #imm", "v10", 0x1C711A, "d1448f3cfbff",
     'anddi16 (36676), 65531',
     'and (0x8f44),0xfffb'),
    ("ALU (addr), #imm", "v10", 0x13A700, "d1a21d3e0200",
     'ordi16 (7586), 2',
     'or (0x1da2),0x0002'),
    ("ALU (addr), #imm", "v10", 0x0F0EF9, "d1aa283f0000",
     'cpdi16 (10410), 0',
     'cp (0x28aa),0x0000'),
    ("ALU (addr), #imm", "v10", 0x184971, "c2ee47023c78",
     'anddi8_24 (149486), 120',
     'and (0x0247ee),0x78'),
    ("ALU (addr), #imm", "v10", 0x1851DE, "c2ee47023e07",
     'ordi8_24 (149486), 7',
     'or (0x0247ee),0x07'),
    ("ALU (addr), #imm", "v10", 0x10EA22, "c2380c023f10",
     'cpib_da (134200), 16',
     'cp (0x020c38),0x10'),
    ("ALU (addr), #imm", "v10", 0x0F090D, "d2d4ff0038e803",
     'adddi16_24 (65492), 1000',
     'add (0x00ffd4),0x03e8'),
    ("ALU (addr), #imm", "v10", 0x152F03, "d28035023a0100",
     'subdi16_24 (144768), 1',
     'sub (0x023580),0x0001'),
    ("ALU (addr), #imm", "v10", 0x12CEE0, "d28610023cfeff",
     'anddi16_24 (135302), 65534',
     'and (0x021086),0xfffe'),
    ("ALU (addr), #imm", "v10", 0x12CECB, "d28610023e0100",
     'ordi16_24 (135302), 1',
     'or (0x021086),0x0001'),
    ("ALU (addr), #imm", "v10", 0x0F0583, "d2caff003fa55a",
     'cpw_da (65482), 23205',
     'cp (0x00ffca),0x5aa5'),

    # --- LD (addr), (addr) -- direct-address sub-opcode 0x19, memory to memory ---
    ("LD (addr), (addr)", "v10", 0x136438, "c16029196229",
     'ldmm8 10594, 10592',
     'ld (0x2962),(0x2960)'),
    ("LD (addr), (addr)", "v10", 0x135F8A, "d1fe2719f627",
     'ldmm16 10230, 10238',
     'ldw (0x27f6),(0x27fe)'),

    # --- Bit operations on a direct address -- RES / SET / CHG / BIT ---
    ("Bit operations on a direct address", "v10", 0x0F0CB1, "f17304b0",
     'resda 0, (1139)',
     'res 0,(0x0473)'),
    ("Bit operations on a direct address", "v10", 0x0F0DFF, "f11304b3",
     'resda 3, (1043)',
     'res 3,(0x0413)'),
    ("Bit operations on a direct address", "v10", 0x0F078D, "f10604b7",
     'resda 7, (1030)',
     'res 7,(0x0406)'),
    ("Bit operations on a direct address", "v10", 0x120DAD, "f15c8fb8",
     'setda 0, (36700)',
     'set 0,(0x8f5c)'),
    ("Bit operations on a direct address", "v10", 0x0F7DB5, "f1540dbb",
     'setda 3, (3412)',
     'set 3,(0x0d54)'),
    ("Bit operations on a direct address", "v10", 0x0F0792, "f10604bf",
     'setda 7, (1030)',
     'set 7,(0x0406)'),
    ("Bit operations on a direct address", "v10", 0x0F0C61, "f12004c8",
     'bitda 0, (1056)',
     'bit 0,(0x0420)'),
    ("Bit operations on a direct address", "v10", 0x0F0CE9, "f11e04cb",
     'bitda 3, (1054)',
     'bit 3,(0x041e)'),
    ("Bit operations on a direct address", "v10", 0x0F0F2A, "f11e04cf",
     'bitda 7, (1054)',
     'bit 7,(0x041e)'),
    ("Bit operations on a direct address", "v10", 0x0F4BA7, "f2040016b0",
     'resda_24 0, (1441796)',
     'res 0,(0x160004)'),
    ("Bit operations on a direct address", "v10", 0x0F4B9F, "f2040016b8",
     'setda_24 0, (1441796)',
     'set 0,(0x160004)'),
    ("Bit operations on a direct address", "v10", 0x0F4890, "f2040016c2",
     'chgda_24 2, (1441796)',
     'chg 2,(0x160004)'),
    ("Bit operations on a direct address", "v10", 0x0F5B8B, "f2e60502c8",
     'bitda_24 0, (132582)',
     'bit 0,(0x0205e6)'),
    ("Bit operations on a direct address", "v10", 0x0F5C78, "f2e40502cf",
     'bitda_24 7, (132580)',
     'bit 7,(0x0205e4)'),

    # --- ALU (addr8), #imm8 through the 8-bit-direct (I/O) prefix 0xC0 ---
    # Only AND and OR of the 0x38-0x3F row have a definition for this prefix;
    # the other six stay refused.
    ("ALU (addr8), #imm8 through the 8-bit-direct prefix", "v10", 0x0F03DE,
     "c02c3cf0", 'and_sd8b_im 44, 240', 'and (0x2c),0xf0'),
    ("ALU (addr8), #imm8 through the 8-bit-direct prefix", "v10", 0x1C3F5B,
     "c0c83e10", 'or_sd8b_im 200, 16', 'or (0xc8),0x10'),

    # --- 32-bit AND / OR through a 24-bit direct address ---
    # The decoder's direct-address ALU table had 0 in both 32-bit slots for
    # AND and OR.  Only the 16-bit-address half is genuinely undefined;
    # AND32_da24 / OR32_da24 / AND32m_da24 / OR32m_da24 all exist.
    ("32-bit AND / OR through a 24-bit direct address", "v10", 0x1981C5,
     "e29e7402c0", 'andda32_24 xwa, (160926)', 'and XWA,(0x02749e)'),
    ("32-bit AND / OR through a 24-bit direct address", "v10", 0x198202,
     "e29a7402c8", 'anddm32_24 (160922), xwa', 'and (0x02749a),XWA'),
    ("32-bit AND / OR through a 24-bit direct address", "v10", 0x0FAA5A,
     "e29e7402e0", 'orda32_24 xwa, (160926)', 'or XWA,(0x02749e)'),
    ("32-bit AND / OR through a 24-bit direct address", "v10", 0x1981BE,
     "e29a7402e8", 'ordm32_24 (160922), xwa', 'or (0x02749a),XWA'),

    # --- LINK / UNLK -- register prefix, sub-opcodes 0x0C and 0x0D ---
    # ⚠ These two are the only entries whose asm text is NOT what the tree's
    # source writes.  The source spells the LINK as its four raw bytes
    # (`link32 0xee, 0x0c, 0xf8, 0xff`, v10/maincpu/boot/system_handlers.s
    # line 1828) because there was no register-typed definition; LINK32r adds
    # one, both encode identically, and --check proves it by requiring the
    # ROM's bytes back from `link xiz, -8`.  The pair brackets one function:
    # the UNLK below is that LINK's, 0x46 bytes later, reached by a linear
    # decode with no refusal in between.
    ("LINK / UNLK", "v10", 0x0F17F4, "ee0cf8ff",
     'link xiz, -8', 'link XIZ,0xfff8'),
    ("LINK / UNLK", "v10", 0x0F183A, "ee0d",
     'unlk32 xiz', 'unlk XIZ'),

    # --- JP cc / CALL cc on a 24-bit direct address ---
    ("JP cc / CALL cc on a 24-bit direct address", "v7", 0x13ECAE, "f286adfdee",
     'call_24 nz, (16625030)',
     'call NZ,0xfdad86'),
]


def toolchain():
    return subprocess.run(
        ["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
         "log", "-1", "--format=%h"], capture_output=True, text=True).stdout.strip()


def assemble(text):
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "a.s")
        open(s, "w").write(".text\n" + text + "\n")
        r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", s],
                           capture_output=True, text=True)
        if r.returncode:
            return None, r.stderr.strip().split("\n")[0]
        m = re.search(r"encoding:\s*\[([^\]]*)\]", r.stdout)
        if not m:
            return None, "no encoding printed"
        return bytes(int(x, 16) for x in m.group(1).split(",") if x.strip()), ""


def disassemble(blob):
    """First instruction only, with six bytes of one-byte-instruction padding so
    a form is not refused merely for reaching the end of the input."""
    with tempfile.TemporaryDirectory() as td:
        b = os.path.join(td, "b.bin")
        open(b, "wb").write(blob + bytes([0x10, 0x11, 0x12, 0x13, 0x10, 0x11]))
        s = os.path.join(td, "b.s")
        open(s, "w").write('.text\n.incbin "%s"\n' % b)
        o = os.path.join(td, "b.o")
        subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                       check=True, capture_output=True)
        r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", o],
                           capture_output=True, text=True)
    for ln in r.stdout.split("\n"):
        m = re.match(r"^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$", ln)
        if m and int(m.group(1), 16) == 0:
            return (bytes(int(x, 16) for x in m.group(2).split()),
                    re.sub(r"\s+", " ", m.group(3).strip()))
    return b"", "(nothing)"


def norm(t):
    return re.sub(r"\s+", " ", t.replace("\t", " ")).strip()


def check():
    print("toolchain: %s" % toolchain())
    roms = {}
    for k, p in ROMS.items():
        fp = os.path.join(ROOT, p)
        if os.path.exists(fp):
            roms[k] = open(fp, "rb").read()
    fail = 0
    for grp, img, off, hx, asm, uni in SITES:
        want = bytes.fromhex(hx)
        why = []
        if img != "no-rom-site":
            if img not in roms:
                why.append("no dump for %s" % img)
            elif roms[img][off:off + len(want)] != want:
                why.append("ROM bytes at 0x%06X are %s, not %s"
                           % (off, roms[img][off:off + len(want)].hex(" "),
                              want.hex(" ")))
        got, err = assemble(asm)
        if got is None:
            why.append("llvm-mc refused %r: %s" % (asm, err))
        elif got != want:
            why.append("llvm-mc encodes %r to %s, not %s"
                       % (asm, got.hex(" "), want.hex(" ")))
        raw, txt = disassemble(want)
        if raw != want:
            why.append("llvm-objdump consumed %s, not %s"
                       % (raw.hex(" "), want.hex(" ")))
        elif norm(txt) != norm(asm):
            why.append("llvm-objdump prints %r, not %r" % (txt, asm))
        if why:
            fail += 1
            print("  FAIL %-11s %s +0x%06X [%s]" % (img, grp, off, hx))
            for w in why:
                print("         %s" % w)
    print("\n%d sites, %d failures" % (len(SITES), fail))
    return 1 if fail else 0


HEADER = r"""; RUN: llvm-mc -triple tlcs900 -show-encoding < %s \
; RUN:     | FileCheck -check-prefixes=CHECK,CHECK-ENC %s
; RUN: llvm-mc -triple tlcs900 -filetype=obj %s \
; RUN:     | llvm-objdump -d - | FileCheck --check-prefix=CHECK-INST %s
;
; MEMORY-PREFIX SUB-OPCODES THE DISASSEMBLER COULD NOT READ.
;
; The 0x80/0x90/0xA0 (source: byte/word/long) and 0xB0/0xB8 (destination)
; register-indirect prefixes, and the C1/C2/D1/D2/E1/E2/F1/F2 direct-address
; prefixes, all dispatch on the same sub-opcode tables -- and the ALU and
; bit-operation halves of those tables had no decode.  llvm-mc encoded every
; form below; llvm-objdump answered "invalid instruction encoding".
;
; Two of them were WORSE than missing, because a decode that produces the
; wrong instruction still looks like success:
;
;   * a DESTINATION-table sub-opcode fell through into the SOURCE table's ALU
;     rows, so `b3 c8` ("bit 0,(xhl)") came back as "and (xhl), xwa", which
;     re-assembles to `a3 c8`;
;   * the direct-address bit table was mapped one group out of step -- 0xA0 to
;     BIT, 0xA8 to RES, 0xB0 to SET -- so `f1 13 04 b0` ("res 0,(1043)") came
;     back as "setda 0, (1043)", which re-assembles to `f1 13 04 b8`.
;
; Both changed the bytes silently.  The real sub-opcode assignment, identical
; for both prefix families and confirmed against MAME unidasm, is
; 0x98 LDCF, 0xA0 STCF, 0xA8 TSET, 0xB0 RES, 0xB8 SET, 0xC0 CHG, 0xC8 BIT.
;
; The leading byte is not the unit of the gap: `9f 06 81` was refused while
; `9f 08 23` read fine, and both start 0x9f.  The families below are named by
; (prefix table, sub-opcode), which is what the decoder dispatches on.
;
; PROVENANCE.  Every byte sequence is read out of a committed KN5000 dump at
; the offset named beside it, and is a statement the disassembly tree's own
; source already assembles to those bytes.  MAME unidasm's rendering is quoted
; as an independent decode.  kn5000-roms-disasm's
; scripts/analysis/mem_prefix_test_sites.py --check re-reads every offset from
; the dumps, re-assembles every asm line and re-disassembles every byte
; sequence, so none of the three claims is merely asserted.
;
; THIS FILE IS GENERATED by that script's --emit; edit the script, not this.
"""


def emit():
    print(HEADER)
    last = None
    for grp, img, off, hx, asm, uni in SITES:
        if grp != last:
            print(";%s\n; %s\n;%s" % ("=" * 74, grp, "=" * 74))
            last = grp
        enc = ",".join("0x%02x" % b for b in bytes.fromhex(hx))
        where = ("no located ROM site -- encoding fixture, see the script"
                 if img == "no-rom-site"
                 else "kn5000_%s_program.rom +0x%06X (rom 0x%06X)"
                      % (img, off, BASE + off))
        print("\n; %s -- unidasm: %s" % (where, uni))
        print("; CHECK: %s" % asm)
        print("; CHECK-ENC: encoding: [%s]" % enc)
        print("; CHECK-INST: %s" % asm)
        print(asm)
    return 0


def foil():
    """Prove --check can FAIL.

    A checker that has only ever passed is not evidence.  This flips one bit of
    one site's expected bytes and requires check() to report exactly one
    failure, then puts it back and requires zero.  It exercises all three of
    check()'s claims at once, because a wrong byte string disagrees with the
    ROM, with what llvm-mc encodes, and with what llvm-objdump prints.
    """
    victim = next(i for i, s in enumerate(SITES) if s[1] != "no-rom-site")
    grp, img, off, hx, asm, uni = SITES[victim]
    bad = bytearray(bytes.fromhex(hx))
    bad[-1] ^= 0x01
    print("foil: flipping the low bit of the last byte of %s +0x%06X\n"
          "      %s -> %s\n" % (img, off, hx, bad.hex()))
    SITES[victim] = (grp, img, off, bad.hex(), asm, uni)
    rc_bad = check()
    SITES[victim] = (grp, img, off, hx, asm, uni)
    print("\nfoil: restored; re-running clean\n")
    rc_good = check()
    ok = (rc_bad == 1 and rc_good == 0)
    print("\n%s -- the check %s on a corrupted site and %s on the real one"
          % ("PASS" if ok else "FAIL",
             "failed" if rc_bad else "PASSED (it cannot fail!)",
             "passed" if not rc_good else "failed"))
    return 0 if ok else 1


if __name__ == "__main__":
    if "--emit" in sys.argv:
        sys.exit(emit())
    sys.exit(foil() if "--foil" in sys.argv else check())
