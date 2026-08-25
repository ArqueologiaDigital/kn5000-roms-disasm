#!/usr/bin/env python3
"""What does each CPU-1 link command make CPU 2 do?  Read out of the ROM, not retyped.

QUESTION ANSWERED
  prom_c's INT0 handler dispatches a command byte through a 7-entry table, and each arm arms
  micro-DMA channel 3 with a buffer and a transfer count and records a "transfer state".  When
  that transfer completes, INTTC3 dispatches the SAME state through a 9-entry table.  Every
  number in the two tables in prom_c/wsa1_prom_c.s comes from here, so a header cannot drift
  away from the bytes and a miscount cannot survive.

  Both arm shapes are FIXED instruction sequences, so the script does not disassemble: it
  matches the exact opcodes and refuses to report a field it did not match.

    stib_da  0x00F32D, state       f2 2d f3 00 00 <state>
    pushw    count                 0b <lo> <hi>
    lda_24   xbc, buffer           f2 <lo> <mid> <hi> 31
    push     xbc                   39
    lda_24   xiy, resume           f2 <lo> <mid> <hi> 35
    push     xiy                   3d
    jp       (xix)                 b4 d8            ; XIX = uDMA3_SetDest

  The seventh arm is DIFFERENT by design -- its count is computed from the command byte at
  run time -- so it is reported separately and never folded into the table.

RUN
  python3 notes/prom_c_link_state_machine.py            # the two tables
  python3 notes/prom_c_link_state_machine.py --dma      # every micro-DMA control-register access
  python3 notes/prom_c_link_state_machine.py --flags    # every reference to the link flag bytes
  python3 notes/prom_c_link_state_machine.py --selftest # re-prove every number a header quotes

LIMITS
  * "state -> handler" is the table's own content.  Which states are actually REACHABLE is
    read off the arms above it; a state no arm ever writes is printed as unreached, not as
    dead code, because nothing here proves no other writer exists.
  * The buffers are addresses, not contents.  What the bytes in them MEAN is not established.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()

INT0_TABLE = 0xF99BF6          # 7 x u32, indexed by (command - 0xE1)
INT0_OUT_OF_RANGE = 0xF99CCF   # where the `jrl ugt` at 0xF99BE9 sends every other byte
TC3_TABLE = 0xF99D4B           # 9 x u32, indexed by (state - 1)


def rd(addr, n):
    return ROM[addr - BASE:addr - BASE + n]


def u32(addr):
    return struct.unpack("<I", rd(addr, 4))[0]


def arm(addr):
    """decode the fixed 7-instruction arming shape; returns None if the bytes do not match"""
    b = rd(addr, 0x1D)
    if b[0:5] != bytes([0xF2, 0x2D, 0xF3, 0x00, 0x00]):
        return None
    state = b[5]
    if b[6] != 0x0B:
        return None
    count = b[7] | (b[8] << 8)
    if b[9] != 0xF2 or b[13] != 0x31 or b[14] != 0x39:
        return None
    buf = b[10] | (b[11] << 8) | (b[12] << 16)
    if b[15] != 0xF2 or b[19] != 0x35 or b[20] != 0x3D:
        return None
    resume = b[16] | (b[17] << 8) | (b[18] << 16)
    if b[21:23] != bytes([0xB4, 0xD8]):
        return None
    return dict(state=state, count=count, buf=buf, resume=resume)


def dma_census():
    """every `ldc CRn,r` / `ldc r,CRn` naming a micro-DMA control register.

    Encoding: <reg-class prefix 0xC8/0xD8/0xE8 group> <0x2E write | 0x2F read> <CR number>.
    CR numbers from mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398.
    ⚠ THE CR-0x00 ROWS (DMAS0) ARE NOISE.  A three-byte pattern ending in 0x00 collides with
    ordinary immediates -- e.g. 0xFAEEF0 is the middle of `add BC,0x002f` (d9 c8 2f 00).  They
    are printed so the collision is visible rather than silently filtered.
    """
    names = {0x08: "DMAS2", 0x28: "DMAC2", 0x18: "DMAD2", 0x2A: "DMAM2",
             0x0C: "DMAS3", 0x2C: "DMAC3", 0x1C: "DMAD3", 0x2E: "DMAM3",
             0x00: "DMAS0", 0x20: "DMAC0", 0x10: "DMAD0", 0x22: "DMAM0",
             0x04: "DMAS1", 0x24: "DMAC1", 0x14: "DMAD1", 0x26: "DMAM1"}
    hits = {}
    for i in range(len(ROM) - 2):
        if ROM[i + 1] in (0x2E, 0x2F) and ROM[i + 2] in names and (ROM[i] & 0xF8) in (0xC8, 0xD8, 0xE8):
            key = (names[ROM[i + 2]], "write" if ROM[i + 1] == 0x2E else "read")
            hits.setdefault(key, []).append(BASE + i)
    print("  micro-DMA control-register accesses in prom_c:")
    for k in sorted(hits):
        tag = "   <- NOISE, CR 0x00 collides with immediates" if k[0] == "DMAS0" else ""
        print(f"    {k[0]:<6} {k[1]:<5} : " + ", ".join(f"0x{a:06X}" for a in hits[k]) + tag)
    real = {k: v for k, v in hits.items() if k[0] != "DMAS0"}
    inblock = all(0xF99FF8 <= a <= 0xF9A037 for v in real.values() for a in v)
    print(f"    every non-noise access is inside the helper block 0xF99FF8-0xF9A037: {inblock}")
    return real, inblock


FLAG_ADDRS = (0x008519, 0x00852A, 0x00852B, 0x00852C, 0x008535)


def flag_census():
    """every literal-addressed reference to the link flag/counter bytes, all twelve spellings.

    Prints the SPAN of the sites, because a header that quotes a range is exactly where an
    off-by-one hides: the 0x00852B sites reach into Link_WaitBlockDone, well past the last
    0x00852C site.
    """
    allsites = []
    print("  references to the link flag bytes (all twelve direct-address spellings):")
    for addr in FLAG_ADDRS:
        sites = []
        for size in range(4):
            pfx = 0xC0 + (size << 4)
            for pat in (bytes([pfx + 1]) + struct.pack("<H", addr),
                        bytes([pfx + 2]) + struct.pack("<I", addr)[:3]):
                i = ROM.find(pat)
                while i >= 0:
                    sites.append(BASE + i)
                    i = ROM.find(pat, i + 1)
        sites = sorted(set(sites))
        allsites += sites
        print(f"    0x{addr:06X}: {len(sites):2d} sites  "
              + ", ".join(f"0x{a:06X}" for a in sites))
    lo, hi = min(allsites), max(allsites)
    print(f"    SPAN of all {len(allsites)} sites: 0x{lo:06X}..0x{hi:06X}")
    flags = []
    for addr in (0x00852A, 0x00852B, 0x00852C):
        for size in range(4):
            pfx = 0xC0 + (size << 4)
            for pat in (bytes([pfx + 1]) + struct.pack("<H", addr),
                        bytes([pfx + 2]) + struct.pack("<I", addr)[:3]):
                i = ROM.find(pat)
                while i >= 0:
                    flags.append(BASE + i)
                    i = ROM.find(pat, i + 1)
    flags = sorted(set(flags))
    print(f"    of which the three FLAG bytes 0x00852A/B/C alone: {len(flags)} sites, "
          f"0x{min(flags):06X}..0x{max(flags):06X}")
    return allsites, lo, hi


def main():
    selftest = "--selftest" in sys.argv
    if "--flags" in sys.argv:
        flag_census()
        return 0
    if "--dma" in sys.argv:
        dma_census()
        return 0
    print(f"INT0 command table at 0x{INT0_TABLE:06X} -- 7 x u32, index = command - 0xE1")
    rows = []
    for k in range(7):
        cmd = 0xE1 + k
        tgt = u32(INT0_TABLE + 4 * k)
        a = arm(tgt)
        rows.append((cmd, tgt, a))
        if a:
            print(f"  0x{cmd:02X} -> 0x{tgt:06X}   state {a['state']:2d}   "
                  f"count {a['count']:2d}   buffer 0x{a['buf']:06X}   resume 0x{a['resume']:06X}")
        else:
            print(f"  0x{cmd:02X} -> 0x{tgt:06X}   (not the fixed arming shape -- see below)")
    print(f"  out-of-range (jrl ugt at 0xF99BE9) -> 0x{INT0_OUT_OF_RANGE:06X}")

    shared = [f"0x{c:02X}" for c, t, a in rows if t == INT0_OUT_OF_RANGE]
    print(f"\n  the out-of-range arm is ALSO the table entry for: {', '.join(shared) or '(none)'}")
    fixed = [r for r in rows if r[2]]
    print(f"  arms matching the fixed shape: {len(fixed)} of 7")

    # the computed-count arm
    d = rd(INT0_OUT_OF_RANGE, 0x21)
    print(f"\n  0x{INT0_OUT_OF_RANGE:06X}: state {d[5]}, and the count is COMPUTED:")
    src = d[7] | (d[8] << 8) | (d[9] << 16)
    print(f"      {d[6:11].hex(' ')}  ld C,(0x{src:06X})   -- the saved command byte")
    print(f"      {d[11:14].hex(' ')}        and C,0x{d[13]:02X}   -- then +1 = the payload length")
    print(f"      buffer 0x{d[20] | d[21] << 8 | d[22] << 16:06X}")

    # a complete census of every literal-addressed BYTE write of the state variable, so
    # "who sets state N" is mechanical rather than eyeballed.  0x00F32D also fits in 16 bits,
    # so both the 24-bit (0xF2) and 16-bit (0xF1) direct spellings are searched -- see the
    # correction in notes/prom_c_xrefs.py for why one spelling is not enough.
    print("\n  every literal-addressed `(0x00F32D) := imm8` in prom_c:")
    pats = [(bytes([0xF2, 0x2D, 0xF3, 0x00, 0x00]), 5), (bytes([0xF1, 0x2D, 0xF3, 0x00]), 4)]
    sites = []
    for pat, n in pats:
        i = ROM.find(pat)
        while i >= 0:
            sites.append((BASE + i, ROM[i + n]))
            i = ROM.find(pat, i + 1)
    for a, v in sorted(sites):
        print(f"    0x{a:06X}  state := {v}")
    print(f"    TOTAL {len(sites)} sites; values written: "
          f"{sorted({v for _, v in sites})}")
    # cross-check: are there OTHER reference forms for this address?  Every direct
    # spelling, any opcode.  The difference tells you what the census above misses.
    allref = []
    for pfx in (0xC0, 0xD0, 0xE0, 0xF0):
        for pat in (bytes([pfx + 1, 0x2D, 0xF3]), bytes([pfx + 2, 0x2D, 0xF3, 0x00])):
            i = ROM.find(pat)
            while i >= 0:
                allref.append(BASE + i)
                i = ROM.find(pat, i + 1)
    extra = sorted(set(allref) - {a for a, _ in sites})
    print(f"    all direct-address references to 0x00F32D: {len(set(allref))}; "
          f"the {len(extra)} that are not imm8 stores: "
          + ", ".join(f"0x{a:06X}" for a in extra))

    print(f"\nINTTC3 state table at 0x{TC3_TABLE:06X} -- 9 x u32, index = state - 1")
    states_written = sorted({a["state"] for c, t, a in rows if a} | {d[5]})
    for k in range(9):
        st = k + 1
        tgt = u32(TC3_TABLE + 4 * k)
        who = [f"0x{c:02X}" for c, t, a in rows if a and a["state"] == st]
        if st == d[5]:
            who.append("0x%02X/any other" % 0xE6)
        tag = ("armed by " + ", ".join(who)) if who else "not written by any INT0 arm"
        print(f"  state {st} -> 0x{tgt:06X}   {tag}")

    if selftest:
        want_rows = [(0xE1, 0xF99C12, 2, 6, 0x008568), (0xE2, 0xF99C32, 3, 10, 0x008520),
                     (0xE3, 0xF99C52, 5, 4, 0x00852D), (0xE4, 0xF99C72, 6, 6, 0x008568),
                     (0xE5, 0xF99C91, 7, 4, 0x008531), (0xE6, 0xF99CCF, None, None, None),
                     (0xE7, 0xF99CB0, 8, 6, 0x008568)]
        ok = True
        for (cmd, tgt, st, cnt, buf), (c2, t2, a2) in zip(want_rows, rows):
            if cmd != c2 or tgt != t2:
                ok = False
            if st is None:
                ok &= a2 is None
            else:
                ok &= a2 is not None and (a2["state"], a2["count"], a2["buf"]) == (st, cnt, buf)
        want_tc3 = [0xF99D6F, 0xF99DAC, 0xF99DB5, 0xF99DCC, 0xF99DDD,
                    0xF99DED, 0xF99E11, 0xF99E21, 0xF99E43]
        ok &= [u32(TC3_TABLE + 4 * k) for k in range(9)] == want_tc3
        ok &= d[5] == 1 and (d[20] | d[21] << 8 | d[22] << 16) == 0x008548
        # LAST entries, not just the first: the 7th command row and the 9th state row
        ok &= rows[6][1] == 0xF99CB0 and rows[6][2]["state"] == 8
        ok &= u32(TC3_TABLE + 4 * 8) == 0xF99E43
        # and the byte immediately after each table is NOT another plausible entry
        after_int0 = u32(INT0_TABLE + 4 * 7)
        after_tc3 = u32(TC3_TABLE + 4 * 9)
        print(f"\n  word after the INT0 table  = 0x{after_int0:08X}  "
              f"(inside prom_c? {0xF80000 <= after_int0 <= 0xFFFFFF})")
        print(f"  word after the INTTC3 table = 0x{after_tc3:08X}  "
              f"(inside prom_c? {0xF80000 <= after_tc3 <= 0xFFFFFF})")
        allsites, lo, hi = flag_census()
        ok &= (lo, hi) == (0xF99951, 0xF99FE5) and len(allsites) == 23
        real, inblock = dma_census()
        ok &= inblock
        ok &= real.get(("DMAS3", "write")) == [0xF9A015]
        ok &= real.get(("DMAM3", "write")) == [0xF9A01B]
        print("  SELFTEST " + ("PASS" if ok else "FAIL"))
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
