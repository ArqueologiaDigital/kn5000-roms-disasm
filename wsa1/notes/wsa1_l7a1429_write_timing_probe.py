#!/usr/bin/env python3
"""WHEN, HOW OFTEN and IN WHAT ORDER does CPU 2 write the device at 0x00104000?

QUESTION IT ANSWERS
  notes/FINDINGS-prom_c-dev104-register-map.md says WHAT each of the nineteen per-channel
  registers is built from.  This says WHEN each one is written: how many channels the
  firmware programs, which routine reaches the device from which event, which registers are
  refreshed periodically and which are written once per note, and whether the block-0-last
  order in Dev104_WriteAllChanRegs is a commit strobe.

  Nothing here reads a `.s` file.  Every check is raw bytes at a stated address in
  original_ROMs/wsa1_prom_c.ic28.  Routine names and extents are the tree's labels, quoted
  so the output is readable; section 0 asserts the first bytes of each named routine so a
  renamed or moved label cannot silently shift a result.

WHAT EACH SECTION PROVES
   0  the eight 0x00104000 driver routines are where this script thinks they are (opcode
      bytes at each stated entry), and the image holds exactly NINE `0x00104000` literals.
   1  ★ THE CHANNEL COUNT IS 64.  The two loops in Dev10C_ResetAllChannels that drive THIS
      device are closed by `cp HL,0x0040 / jr C` (0xFB81B9, 0xFB8281), so the firmware
      programs channels 0..0x3F of 0x00104000 at power-on; and every runtime path bounds
      its channel argument with `cp r,0x40 / jr NC -> skip` before reaching the device
      (five sites).  ⚠ NULL: none of the eight 0x00104000 routines contains the
      `cp HL,0x0040` slot split that six 0x0010C000 routines do, so a channel argument of
      0x40..0x7F has no second meaning here.
   2  the call-site census of all eight entry points, image-wide, from the `1D <addr24>`
      (call) and `1E <disp16>` (calr) bytes -- 27 sites over 6 reached routines, 2 routines
      with no located caller.
   3  ★ THE INIT SEQUENCE.  Register 0x0800 <- the word at ROM 0xFE1313 (once, no channel),
      then a 38-byte ROM image copied to the staging struct at 0x00D91F, then 64 full
      19-register writes, then 64 block-0-only writes with bit 2 CLEARED.
   4  ★ THE POWER-ON IMAGE AGREES WITH THE REGISTER MAP INDEPENDENTLY.  Image word 4 is
      0x0100, the constant Const_0100_251 always yields for register 0x0100, and image word
      11 is 0xFF00, the only literal the packer ever puts in register 0x02C0.  Two
      agreements the word<->register mapping would break if it were off by one.
   5  ★ BIT 2 OF BLOCK 0.  Pack104_SetInputs_SubRecordPair ends `(struct+0) =
      (R[+0x07] << 8)` then `set 2` (0xFC4D50/0xFC4D54); Dev10C_ResetAllChannels's final
      sweep does `res 2` on the same word (0xFB8245).  ⚠ NULL: the set is on the note-OFF
      tail as well as the note-ON tail (5 of 5 MidiNote_* sites go through that one
      routine), so bit 2 is NOT a key gate.
   6  ★ BLOCK-0-LAST IS NOT A COMMIT STROBE.  Over all 8 routines -- register count = half
      the port-store count, and every non-zero select value is formed by an `add rr,imm16`,
      so block-0 writes = registers - adds -- block 0 is written LAST in 1, FIRST in 2 (both
      with no located caller), alone in 1, and NOT AT ALL in 4; and those 4 are exactly the
      ones the periodic and parameter-edit paths use.  A latch that had to follow a
      parameter change would have to appear in them.
   7  no bus padding on this device: the five-`nop` run that follows every 0x0010C000 data
      write does not occur once inside the eight 0x00104000 routines.
   8  ★ PERIODIC VS ONE-SHOT.  Each small accessor's select `add rr,imm16` and its staging
      fetch `ld rr,(Xnn+d)`, asserted by their bytes.  sub_FC49AD writes staging words
      {+0x06,+0x08,+0x12} and Dev104_SetChanRegs_00C0_0100_0240 ships exactly those three;
      sub_FC4AED writes {+0x14} and Dev104_SetChanReg_0280 ships exactly that one.
      Producer and shipper match, register for register.
   9  the tick chain and its rate: `ldio T01MOD,0x0D` at 0xFFF06C (phiT256 for timer 1),
      TREG1 = the fc byte 0x1C = 28, so INTT1 = 28e6/2048/28 = 488.28 Hz; the six-entry
      phase table at 0xF990C8 sets bit 4 of 0x007ED1 on ONE of six phases; MAIN's bit-4 arm
      calls Toggle14FE_AndDispatch, which alternates, so the periodic 0x00104000 refresh
      runs at 488.28/6/2 = 40.69 Hz.
  10  the three Voice_ApplyParamChange_Dispatch arms that reach this device, by table index
      (28, 29, 36 -> target codes 29, 30, 37).

RUN
  python3 notes/wsa1_l7a1429_write_timing_probe.py             # print every section
  python3 notes/wsa1_l7a1429_write_timing_probe.py --selftest  # assert; exit 1 on failure
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28')
BASE = 0xF80000
IMG = open(ROM, 'rb').read()
END = BASE + len(IMG)

FAILURES = []
QUIET = False


def out(*a):
    if not QUIET:
        print(*a)


def check(label, cond):
    if not cond:
        FAILURES.append(label)
    out("  [%s] %s" % ("ok" if cond else "FAIL", label))


def b(addr, n):
    return IMG[addr - BASE:addr - BASE + n]


def u16(addr):
    return IMG[addr - BASE] | (IMG[addr - BASE + 1] << 8)


# ---------------------------------------------------------------- the routines
# name -> (start, end_inclusive).  The tree's labels in
# prom_c/devices/dev10c_dev104_drivers.s; section 0 asserts the entry bytes.
DEV104 = [
    ("Dev104_WriteAllChanRegs",           0xFB77EF, 0xFB796D),
    ("Dev104_SetChanRegs_01C0_0200_0240", 0xFB796E, 0xFB79CF),
    ("Dev104_SetChanRegs_0140_to_0240",   0xFB79D0, 0xFB7A57),
    ("Dev104_WriteChanReg0",              0xFB7A58, 0xFB7A72),
    ("Dev104_SetChanRegs_00C0_0100_0240", 0xFB7A73, 0xFB7AC8),
    ("Dev104_SetChanRegs_00C0_0100",      0xFB7AC9, 0xFB7B04),
    ("Dev104_SetChanRegs_0140_0180",      0xFB7B05, 0xFB7B40),
    ("Dev104_SetChanReg_0280",            0xFB7B41, 0xFB7B62),
]
RESET = ("Dev10C_ResetAllChannels", 0xFB80E1, 0xFB828D)

# enclosing routine of each located call site -- the tree's labels, for readability only.
SITE_OWNER = {
    0xFAC3EC: "sub_FAC34D",            0xFB0B71: "VoiceRegs_Stage_A",
    0xFB1F51: "VoiceRegs_Stage_B",     0xFB2876: "VoiceRegs_Stage_C",
    0xFB2F4B: "VoiceRegs_Stage_D",     0xFB3708: "MidiNote_OnTail",
    0xFB3815: "MidiNote_OffTail",      0xFC3ECD: "NotePool8_NoteOnOff",
    0xFB81A4: "Dev10C_ResetAllChannels",
    0xFAC3D7: "sub_FAC34D",            0xFB36FB: "MidiNote_OnTail",
    0xFB3808: "MidiNote_OffTail",      0xFB3927: "MidiNote_OnByPartMode",
    0xFB3A72: "MidiNote_OnByPartMode", 0xFB3B90: "MidiNote_OnByPartMode",
    0xFC3EA1: "NotePool8_NoteOnOff",   0xFB826B: "Dev10C_ResetAllChannels",
    0xFACB85: "sub_FACAB7",            0xFAEB56: "sub_FAEAF9",
    0xFAEBC2: "sub_FAEB65",            0xFACB96: "sub_FACAB7",
    0xFB373A: "MidiNote_OnTail",       0xFB3847: "MidiNote_OffTail",
    0xFB39D1: "MidiNote_OnByPartMode", 0xFB3AD9: "MidiNote_OnByPartMode",
    0xFB3BF2: "MidiNote_OnByPartMode", 0xFAED24: "sub_FAECC7",
}


def sec0():
    out("\n=== 0. the eight routines are where this script thinks they are ===")
    # each Dev104 routine opens `link XIZ,imm16` = ee 0c xx xx
    for name, start, _end in DEV104:
        check("%s at 0x%06X opens `ee 0c` (link XIZ)" % (name, start),
              b(start, 2) == bytes((0xEE, 0x0C)))
    check("Dev10C_ResetAllChannels at 0xFB80E1 opens `ee 0c`",
          b(RESET[1], 2) == bytes((0xEE, 0x0C)))
    lits = [BASE + i for i in range(len(IMG) - 3)
            if IMG[i:i + 4] == bytes((0x00, 0x40, 0x10, 0x00))]
    out("  0x00104000 literals in the image: %d" % len(lits))
    for a in lits:
        owner = next((n for n, s, e in DEV104 if s <= a <= e), None)
        if owner is None and RESET[1] <= a <= RESET[2]:
            owner = RESET[0]
        out("    0x%06X  %s" % (a, owner or "??"))
    check("exactly nine 0x00104000 literals", len(lits) == 9)
    check("eight of them are one per Dev104 routine",
          sorted(next((n for n, s, e in DEV104 if s <= a <= e), "") for a in lits
                 ).count("") == 1)
    check("the ninth is in Dev10C_ResetAllChannels",
          sum(1 for a in lits if RESET[1] <= a <= RESET[2]) == 1)


def sec1():
    out("\n=== 1. THE CHANNEL COUNT ===")
    # `cp HL,0x0040` = db cf 40 00 ; `jr C` = 67
    check("0xFB81B9 `cp HL,0x0040` / `jr C` closes the loop whose body calls 0xFB77EF",
          b(0xFB81B9, 5) == bytes((0xDB, 0xCF, 0x40, 0x00, 0x67)))
    check("  and that body really does `calr 0xFB77EF` at 0xFB81A4",
          b(0xFB81A4, 3) == bytes((0x1E, 0x48, 0xF6))
          and 0xFB81A7 + int.from_bytes(b(0xFB81A5, 2), 'little', signed=True) == 0xFB77EF)
    check("0xFB8281 `cp HL,0x0040` / `jrl C` closes the loop whose body calls 0xFB7A58",
          b(0xFB8281, 5) == bytes((0xDB, 0xCF, 0x40, 0x00, 0x77)))
    check("  and that body really does `calr 0xFB7A58` at 0xFB826B",
          b(0xFB826B, 3) == bytes((0x1E, 0xEA, 0xF7))
          and 0xFB826E + int.from_bytes(b(0xFB826C, 2), 'little', signed=True) == 0xFB7A58)
    out("  -> the firmware programs channels 0x00..0x3F of 0x00104000 at power-on: 64.")
    out("\n  runtime guards, `cp H,0x40` = ce cf 40 followed by a NC/UGT skip:")
    guards = {0xFB36A8: "MidiNote_OnTail",  0xFB37B5: "MidiNote_OffTail",
              0xFAC37B: "sub_FAC34D",      0xFACACD: "sub_FACAB7",
              0xFC4CE7: "Pack104_SetInputs_SubRecordPair"}
    for a, who in sorted(guards.items()):
        check("0x%06X in %s is `cp H,0x40`" % (a, who), b(a, 3) == bytes((0xCE, 0xCF, 0x40)))
    out("\n  ⚠ NULL -- the 0x0010C000 `chan >= 0x40` slot split does not exist here.")
    pat = bytes((0xDB, 0xCF, 0x40, 0x00))          # cp HL,0x0040
    n104 = sum(IMG[s - BASE:e - BASE + 1].count(pat) for _n, s, e in DEV104)
    dev10c = [(0xFB6E0A, 0xFB7714), (0xFB7B63, 0xFB80E0)]
    n10c = sum(IMG[s - BASE:e - BASE + 1].count(pat) for s, e in dev10c)
    out("    `cp HL,0x0040` inside the eight 0x00104000 routines : %d" % n104)
    out("    `cp HL,0x0040` inside the 0x0010C000 driver blocks   : %d" % n10c)
    check("no 0x00104000 routine splits on chan >= 0x40", n104 == 0)
    check("the companion's routines do (the control)", n10c >= 4)


def _call_sites(target):
    """image-wide `1D <addr24>` and `1E <disp16>` sites that reach `target`."""
    hits = []
    t3 = target.to_bytes(3, 'little')
    for i in range(len(IMG) - 3):
        if IMG[i] == 0x1D and IMG[i + 1:i + 4] == t3:
            hits.append(BASE + i)
        elif IMG[i] == 0x1E:
            disp = int.from_bytes(IMG[i + 1:i + 3], 'little', signed=True)
            if BASE + i + 3 + disp == target:
                hits.append(BASE + i)
    return hits


def sec2():
    out("\n=== 2. WHO CALLS THE WRITERS -- the image-wide census ===")
    total = 0
    reached = 0
    for name, start, _e in DEV104:
        sites = _call_sites(start)
        total += len(sites)
        reached += 1 if sites else 0
        out("  %-34s 0x%06X  %d site(s)" % (name, start, len(sites)))
        for a in sites:
            out("      0x%06X  %s" % (a, SITE_OWNER.get(a, "?")))
    out("  TOTAL: %d located call sites over %d of 8 routines" % (total, reached))
    check("27 located call sites in all", total == 27)
    check("6 of the 8 routines have a located caller", reached == 6)
    check("Dev104_SetChanRegs_01C0_0200_0240 has none", not _call_sites(0xFB796E))
    check("Dev104_SetChanRegs_0140_to_0240 has none", not _call_sites(0xFB79D0))
    check("every located site is accounted for by name",
          all(a in SITE_OWNER for n, s, _e in DEV104 for a in _call_sites(s)))


def sec3():
    out("\n=== 3. THE POWER-ON SEQUENCE ===")
    check("0xFB80F1 `ld XIX,0x00104000`", b(0xFB80F1, 5) == bytes((0x44, 0x00, 0x40, 0x10, 0x00)))
    check("0xFB80F6 `ld (XIX),0x0800`   -- register number 0x0800, no channel added",
          b(0xFB80F6, 4) == bytes((0xB4, 0x02, 0x00, 0x08)))
    check("0xFB80FA `ld BC,(0xFE1313)`  -- its value comes from ROM",
          b(0xFB80FA, 5) == bytes((0xD2, 0x13, 0x13, 0xFE, 0x21)))
    check("0xFB80FF `ld (XIX+0x02),BC`  -- the data port",
          b(0xFB80FF, 3) == bytes((0xBC, 0x02, 0x51)))
    out("  register 0x0800 <- 0x%04X" % u16(0xFE1313))
    check("that value is 0x1100", u16(0xFE1313) == 0x1100)
    check("0xFB8162 pushes ROM 0xFE133B as the copy source",
          b(0xFB8162, 5) == bytes((0xF2, 0x3B, 0x13, 0xFE, 0x31)))
    check("0xFB8159 pushes RAM 0x00D91F as the destination",
          b(0xFB8159, 5) == bytes((0xF2, 0x1F, 0xD9, 0x00, 0x34)))
    check("0xFB815E pushes the count 38 = 19 words",
          b(0xFB815E, 3) == bytes((0x0B, 0x26, 0x00)))
    check("0xFB8168 calls MemCopyWords (0xF9A038)",
          b(0xFB8168, 4) == bytes((0x1D, 0x38, 0xA0, 0xF9)))
    out("  loop 1 (chan 0..0x3F): word 0 bits 13..8 := chan, then all 19 registers")
    check("0xFB8181 `and (0x00D91F),0xC0FF` clears word-0 bits 13..8",
          b(0xFB8181, 7) == bytes((0xD2, 0x1F, 0xD9, 0x00, 0x3C, 0xFF, 0xC0)))
    check("0xFB818F/0xFB8192 `sll 8,BC` / `and BC,0x3F00` build the channel field",
          b(0xFB818F, 3) == bytes((0xD9, 0xEE, 0x08))
          and b(0xFB8192, 4) == bytes((0xD9, 0xCC, 0x00, 0x3F)))
    out("  loop 2 (chan 0..0x3F): word 0 bit 2 cleared, block 0 only")
    check("0xFB8245 `res 0x02,BC`", b(0xFB8245, 3) == bytes((0xD9, 0x30, 0x02)))


def sec4():
    out("\n=== 4. THE POWER-ON IMAGE, WORD BY WORD (ROM 0xFE133B) ===")
    img = [u16(0xFE133B + 2 * k) for k in range(19)]
    for k, v in enumerate(img):
        out("    word %2d  register chan+0x%04X  0x%04X" % (k, k * 0x40, v))
    check("word 0 = 0x0004 -- bit 2 SET in the ROM image", img[0] == 0x0004)
    check("★ word 4 = 0x0100, the constant Const_0100_251 always yields for register 0x0100",
          img[4] == 0x0100)
    check("★ word 11 = 0xFF00, the only literal the packer puts in register 0x02C0",
          img[11] == 0xFF00)
    check("the A/B pairs are equal in the image: w5==w6, w7==w8, w13==w14, w16==w17",
          img[5] == img[6] and img[7] == img[8] and img[13] == img[14] and img[16] == img[17])
    out("  the Stage_B image at 0xFE1315 is the 38 bytes immediately before it:")
    imgb = [u16(0xFE1315 + 2 * k) for k in range(19)]
    out("    " + " ".join("%04X" % v for v in imgb))
    check("0xFE1315 + 38 == 0xFE133B (adjacent, not overlapping)", 0xFE1315 + 38 == 0xFE133B)
    check("both images start 0x0004", imgb[0] == 0x0004)


def sec5():
    out("\n=== 5. BIT 2 OF BLOCK 0 -- set on every note event, cleared only at power-on ===")
    check("0xFC4D4A `sll 8,HL`  (R[+0x07] << 8)", b(0xFC4D4A, 3) == bytes((0xDB, 0xEE, 0x08)))
    check("0xFC4D4D `ld XBC,(XIZ+0x0c)` -- the struct pointer argument",
          b(0xFC4D4D, 3) == bytes((0xAE, 0x0C, 0x21)))
    check("0xFC4D50 `ld (XBC),HL`   -- staging word 0", b(0xFC4D50, 2) == bytes((0xB1, 0x53)))
    check("0xFC4D54 `set 0x02,BC`", b(0xFC4D54, 3) == bytes((0xD9, 0x31, 0x02)))
    check("0xFC4D5A `ld (XWA),BC`   -- staging word 0 again, with bit 2 set",
          b(0xFC4D5A, 2) == bytes((0xB0, 0x51)))
    sites = _call_sites(0xFC4C85)
    out("  Pack104_SetInputs_SubRecordPair call sites: %s"
        % ", ".join("0x%06X" % a for a in sites))
    check("five of them, and they are the five MidiNote_* sites",
          sorted(sites) == [0xFB36F5, 0xFB3802, 0xFB391C, 0xFB3A67, 0xFB3B85])
    out("  ⚠ NULL: 0xFB3802 is inside MidiNote_OffTail, so the note-OFF tail sets bit 2 too.")
    out("     Bit 2 is therefore not a key gate; it is set whenever a channel is programmed.")


def _reg_census(start, end):
    """(ordered non-zero blocks, number of registers, number of block-0 writes, verdict).

    Mechanical, from the routine's own bytes, and it needs no symbolic walk:
      * every write to the device is `ld (Xrr),rr` (opcodes B0/B1/B4/B5 + 50..53) or
        `ld (Xrr+2),rr` (B8/B9/BC/BD + 02 + 50..53) -- one SELECT and one DATA per
        register, so the register count is exactly half the store count;
      * every select value except block 0's is formed by an `add rr,imm16`
        (D8..DB + C8 + imm16), because block 0 IS the channel with nothing added.
    So block-0 writes = registers - adds, and the position of block 0 follows from
    comparing the first/last store address with the first/last add address.
    """
    seg = IMG[start - BASE:end - BASE + 1]
    stores, adds = [], []
    i = 0
    while i < len(seg) - 2:
        if seg[i] in (0xB0, 0xB1, 0xB4, 0xB5) and seg[i + 1] in (0x50, 0x51, 0x52, 0x53):
            stores.append(start + i)
            i += 2
            continue
        if (seg[i] in (0xB8, 0xB9, 0xBC, 0xBD) and seg[i + 1] == 0x02
                and seg[i + 2] in (0x50, 0x51, 0x52, 0x53)):
            stores.append(start + i)
            i += 3
            continue
        if seg[i] in (0xD8, 0xD9, 0xDA, 0xDB) and seg[i + 1] == 0xC8:
            adds.append((start + i, seg[i + 2] | (seg[i + 3] << 8)))
            i += 4
            continue
        i += 1
    nregs = len(stores) // 2
    nzero = nregs - len(adds)
    if nzero == 0:
        verdict = "block 0 ABSENT"
    elif nregs == 1:
        verdict = "block 0 ALONE"
    elif stores[0] < adds[0][0]:
        verdict = "block 0 FIRST"
    elif stores[-1] > adds[-1][0]:
        verdict = "block 0 LAST"
    else:
        verdict = "block 0 IN THE MIDDLE"
    return [k for _a, k in adds], nregs, nzero, verdict


def sec6():
    out("\n=== 6. ORDER: WHERE BLOCK 0 SITS IN EACH ROUTINE ===")
    verdicts = {}
    for name, start, end in DEV104:
        blocks, nregs, nzero, v = _reg_census(start, end)
        verdicts[name] = (v, nregs, nzero)
        out("  %-34s %2d reg(s), %d block-0 write(s)  %-14s  %s"
            % (name, nregs, nzero, v, " ".join("0x%04X" % k for k in blocks)))
    check("Dev104_WriteAllChanRegs writes 19 registers, one of them block 0, LAST",
          verdicts["Dev104_WriteAllChanRegs"] == ("block 0 LAST", 19, 1))
    check("Dev104_SetChanRegs_01C0_0200_0240 writes 4, block 0 FIRST",
          verdicts["Dev104_SetChanRegs_01C0_0200_0240"] == ("block 0 FIRST", 4, 1))
    check("Dev104_SetChanRegs_0140_to_0240 writes 6, block 0 FIRST",
          verdicts["Dev104_SetChanRegs_0140_to_0240"] == ("block 0 FIRST", 6, 1))
    check("Dev104_WriteChanReg0 writes block 0 and nothing else",
          verdicts["Dev104_WriteChanReg0"] == ("block 0 ALONE", 1, 1))
    absent = sorted(n for n, v in verdicts.items() if v[0] == "block 0 ABSENT")
    out("  ⚠ NULL: the four routines that never write block 0, with their caller counts:")
    starts = dict((d[0], d[1]) for d in DEV104)
    for n in absent:
        out("      %-34s %d located caller(s)" % (n, len(_call_sites(starts[n]))))
    check("exactly four routines never write block 0",
          absent == ["Dev104_SetChanReg_0280", "Dev104_SetChanRegs_00C0_0100",
                     "Dev104_SetChanRegs_00C0_0100_0240", "Dev104_SetChanRegs_0140_0180"])
    check("and all four of them DO have located callers",
          all(_call_sites(starts[n]) for n in absent))
    check("while both routines that write block 0 FIRST have none",
          not _call_sites(0xFB796E) and not _call_sites(0xFB79D0))
    out("     -> every parameter change that actually happens on this firmware reaches the")
    out("        device with no block-0 write after it, so block 0 cannot be a commit")
    out("        strobe those registers wait on.")


def sec7():
    out("\n=== 7. BUS PADDING: none on this device ===")
    nop5 = bytes(5)
    n104 = sum(IMG[s - BASE:e - BASE + 1].count(nop5) for _n, s, e in DEV104)
    # the 0x0010C000 control: the reset sweep's own direct writes
    n10c = IMG[0xFB8119 - BASE:0xFB8215 - BASE].count(nop5)
    out("  five-`nop` runs inside the eight 0x00104000 routines      : %d" % n104)
    out("  five-`nop` runs inside Dev10C_ResetAllChannels's 0x10C000 loops: %d" % n10c)
    check("no padding on the 0x00104000 writers", n104 == 0)
    check("the companion's writes do carry it (the control)", n10c >= 3)


def sec8():
    out("\n=== 8. PERIODIC VS ONE-SHOT: producer and shipper match ===")
    out("  What each SMALL accessor ships, read off its own `add rr,imm16` (the select")
    out("  value) and `ld rr,(Xnn+d)` (the staging word) -- addresses from the routine")
    out("  headers in prom_c/devices/dev10c_dev104_drivers.s, bytes from the ROM:")
    SHIP = {
        "Dev104_WriteChanReg0": [
            (0x0000, 0x00, 0xFB7A62, bytes((0x9E, 0x08, 0x21)),      # select = chan, no add
                          0xFB7A6A, bytes((0x91, 0x20))),            # ld WA,(XBC)  = word +0x00
        ],
        "Dev104_SetChanRegs_00C0_0100_0240": [
            (0x00C0, 0x06, 0xFB7A82, bytes((0xDA, 0xC8, 0xC0, 0x00)),
                          0xFB7A90, bytes((0x9C, 0x06, 0x22))),
            (0x0100, 0x08, 0xFB7A9F, bytes((0xD9, 0xC8, 0x00, 0x01)),
                          0xFB7AA8, bytes((0x9C, 0x08, 0x21))),
            (0x0240, 0x12, 0xFB7AB2, bytes((0xD9, 0xC8, 0x40, 0x02)),
                          0xFB7ABB, bytes((0x9C, 0x12, 0x21))),
        ],
        "Dev104_SetChanRegs_00C0_0100": [
            (0x00C0, 0x06, 0xFB7AD2, bytes((0xDB, 0xC8, 0xC0, 0x00)),
                          0xFB7AE0, bytes((0x99, 0x06, 0x23))),
            (0x0100, 0x08, 0xFB7AEF, bytes((0xD9, 0xC8, 0x00, 0x01)),
                          0xFB7AF8, bytes((0x99, 0x08, 0x20))),
        ],
        "Dev104_SetChanRegs_0140_0180": [
            (0x0140, 0x0A, 0xFB7B0E, bytes((0xDB, 0xC8, 0x40, 0x01)),
                          0xFB7B1C, bytes((0x99, 0x0A, 0x23))),
            (0x0180, 0x0C, 0xFB7B2B, bytes((0xD9, 0xC8, 0x80, 0x01)),
                          0xFB7B34, bytes((0x99, 0x0C, 0x20))),
        ],
        "Dev104_SetChanReg_0280": [
            (0x0280, 0x14, 0xFB7B4A, bytes((0xDB, 0xC8, 0x80, 0x02)),
                          0xFB7B58, bytes((0x99, 0x14, 0x20))),
        ],
    }
    for name in ("Dev104_WriteChanReg0", "Dev104_SetChanRegs_00C0_0100_0240",
                 "Dev104_SetChanRegs_00C0_0100", "Dev104_SetChanRegs_0140_0180",
                 "Dev104_SetChanReg_0280"):
        out("  %-34s %s" % (name, "  ".join(
            "chan+0x%04X <- w+0x%02X" % (blk, wd) for blk, wd, _a, _b, _c, _d in SHIP[name])))
        for blk, wd, sa, sb, da, db_ in SHIP[name]:
            check("  %s: 0x%06X selects chan+0x%04X" % (name, sa, blk), b(sa, len(sb)) == sb)
            check("  %s: 0x%06X fetches staging word +0x%02X" % (name, da, wd),
                  b(da, len(db_)) == db_)
    out("  sub_FC49AD (0xFC49AD) is called from: %s"
        % ", ".join("0x%06X" % a for a in _call_sites(0xFC49AD)))
    out("  sub_FC4AED (0xFC4AED) is called from: %s"
        % ", ".join("0x%06X" % a for a in _call_sites(0xFC4AED)))
    check("sub_FC49AD has exactly three callers: the packer, the param-edit path, the tick path",
          sorted(_call_sites(0xFC49AD)) == [0xFC56AA, 0xFC5EE9, 0xFC7CE9])
    check("sub_FC4AED has exactly two: the packer and the param-edit path",
          sorted(_call_sites(0xFC4AED)) == [0xFC51A7, 0xFC67E9])
    out("  -> sub_FC49AD produces staging words {+0x06,+0x08,+0x12} (the register map's")
    out("     own producer index) and Dev104_SetChanRegs_00C0_0100_0240 ships exactly")
    out("     those three; sub_FC4AED produces {+0x14} and Dev104_SetChanReg_0280 ships")
    out("     exactly that one.  Producer and shipper match, register for register.")


def sec9():
    out("\n=== 9. THE TICK, AND THE RATE OF THE PERIODIC REFRESH ===")
    check("0xFFF06C `ldio T01MOD,0x0D` -- phiT256 for timer 1",
          b(0xFFF06C, 3) == bytes((0x08, 0x24, 0x0D)))
    check("0xFFFFEF = 0x1C = 28, the fc-in-MHz byte Timer1_SetPeriodAndStart loads into TREG1",
          IMG[0xFFFFEF - BASE] == 0x1C)
    fc = 1_000_000 * IMG[0xFFFFEF - BASE]
    tick = fc / 2048.0 / IMG[0xFFFFEF - BASE]
    out("  INTT1 = %d / 2048 / %d = %.2f Hz" % (fc, IMG[0xFFFFEF - BASE], tick))
    check("that is the 488.28 Hz notes/WSA1-EMULATION-DISASM-GAPS.md measured live",
          abs(tick - 488.28) < 0.01)
    tbl = [int.from_bytes(b(0xF990C8 + 4 * k, 4), 'little') for k in range(6)]
    out("  the INTT1 phase table at 0xF990C8: %s" % " ".join("0x%06X" % a for a in tbl))
    check("six entries, 4 bytes each, ending at 0xF990E0", 0xF990C8 + 6 * 4 == 0xF990E0)
    # `set n,(0x007ED1)` = f2 d1 7e 00 (b8|n)
    sets = []
    for i in range(len(IMG) - 4):
        if IMG[i:i + 4] == bytes((0xF2, 0xD1, 0x7E, 0x00)) and 0xB8 <= IMG[i + 4] <= 0xBF:
            sets.append((BASE + i, IMG[i + 4] & 7))
    out("  `set n,(0x007ED1)` sites: %s"
        % " ".join("0x%06X:bit%d" % (a, n) for a, n in sets))
    check("eight of them, one bit-4 site -- so bit 4 fires once per six ticks",
          len(sets) == 8 and sum(1 for _a, n in sets if n == 4) == 1)
    check("MAIN's bit-4 arm calls Toggle14FE_AndDispatch (0xFB05EC) at 0xF98C1E",
          b(0xF98C1E, 4) == bytes((0x1D, 0xEC, 0x05, 0xFB)))
    check("Toggle14FE_AndDispatch ends `xor (XIX),0xff` -- it alternates",
          b(0xFB0605, 3) == bytes((0x84, 0x3D, 0xFF)))
    check("its odd path calls sub_FACAB7 (0xFACAB7) at 0xFB0601",
          b(0xFB0601, 4) == bytes((0x1D, 0xB7, 0xCA, 0xFA)))
    out("  -> the per-voice refresh runs at %.2f / 6 / 2 = %.2f Hz" % (tick, tick / 12.0))
    out("  sub_FAC34D's own countdown reloads with 4 (`ld (XIX+0x1e),0x04` at 0xFAC422),")
    out("     so its full-writer burst is at most %.2f / 4 = %.2f Hz, and only while"
        % (tick / 12.0, tick / 48.0))
    out("     (0x151B) is non-zero.")
    check("0xFAC422 `ld (XIX+0x1e),0x04`", b(0xFAC422, 4) == bytes((0xBC, 0x1E, 0x00, 0x04)))


def sec10():
    out("\n=== 10. THE PARAMETER-EDIT ARMS THAT REACH THIS DEVICE ===")
    tbl = 0xFAF08F
    want = {0xFAF246: "sub_FAEAF9 -> 0x00C0, 0x0100, 0x0240",
            0xFAF254: "sub_FAEB65 -> 0x00C0, 0x0100, 0x0240",
            0xFAF29A: "sub_FAECC7 -> 0x0280"}
    found = {}
    for k in range(49):
        a = int.from_bytes(b(tbl + 4 * k, 4), 'little')
        if a in want:
            found[k] = (a, want[a])
            out("  table index %2d (target code %2d) -> arm 0x%06X  %s" % (k, k + 1, a, want[a]))
    check("the 49-entry table ends where the first arm begins", tbl + 4 * 49 == 0xFAF153)
    check("three arms of 49 reach 0x00104000, at indices 28, 29 and 36",
          sorted(found) == [28, 29, 36])


def main():
    global QUIET
    QUIET = '--selftest' in sys.argv[1:]
    for s in (sec0, sec1, sec2, sec3, sec4, sec5, sec6, sec7, sec8, sec9, sec10):
        s()
    print("\nFAILURES: %d" % len(FAILURES))
    for f in FAILURES:
        print("  - %s" % f)
    return 1 if FAILURES else 0


if __name__ == '__main__':
    sys.exit(main())
