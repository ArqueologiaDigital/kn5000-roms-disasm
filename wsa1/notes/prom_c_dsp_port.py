#!/usr/bin/env python3
"""By which port do CPU 2's microcode bytes leave, and what answers READY?  -- emulation gap G.

QUESTION IT ANSWERS
  `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap G, PRIORITY 2:

      "CPU 2 polls P9 bit 3 at eighteen sites (0xF9A19F ld C,(0x19) / and C,0x08) during a
       microcode upload.  Which port do the microcode BYTES leave by -- 0x00E00000, or
       something not yet reached?  ...  The driver refuses to answer 0x08 on P9 because
       that would be a fabricated ready signal on a pin nobody has read.  If the byte path
       were identified, a device could be modelled that asserts READY because it CONSUMED A
       BYTE, which is a real handshake rather than a constant, and boot would drop by most
       of a minute."

THE ANSWER
  Neither.  The bytes leave by **PORT P7 (SFR 0x13), written whole**, in a hand-rolled
  parallel handshake with THREE selectable destinations:

      data      P7           `ld (0x0013),(XIZ+0x08)`, the routine's byte argument
      strobe    P5 bit 4     destination 0      the second argument, 0/1/2, picks one
                P5 bit 5     destination 1
                P2 bit 7     destination 2
      valid     PB bit 5     lowered for EVERY byte, in all nine arms, raised at the end
      cmd/data  P5 bit 3     lowered ONLY by P7Byte_SendCmd -- 3 `res` sites against 9 arms,
                             so this line distinguishes a record's first byte from the rest
      enable    PB bit 6     set once, in P7Byte_SendCmd's preamble, and never cleared
      ready in  P9 bit 3     polled until non-zero, TWICE per byte
      timeout   0x1F40 = 8000 poll iterations; on expiry (0x00F35C) := 1 and the byte is
                sent anyway.  That flag is the ONLY error report.

  and the sequence per byte, from `P7Byte_SendCmd`'s destination-0 arm
  (prom_c 0xF9A197-0xF9A210), is

      res 4,(P5)                       ; strobe low
      wait P9.3 != 0, <= 8000 spins    ; peer ready
      set 4,(P5)
      ld (P7),<byte>                   ; DATA ON THE BUS
      res 5,(PB) / res 3,(P5) / res 4,(P5)
      wait P9.3 != 0, <= 8000 spins    ; peer took it
      set 4,(P5) / set 3,(P5) / set 5,(PB)

  Destinations 1 and 2 are the same steps with P5 bit 5, or with P2 bit 7, in place of
  P5 bit 4.  `P7Byte_SendData` and `P7Byte_SendArg` run the SAME sequence WITHOUT the
  `res 3,(P5)` / `set 3,(P5)` pair -- which is what makes P5 bit 3 a command qualifier
  rather than a fourth common line.  THREE routines implement this, one per byte ROLE,
  and the last two differ from each other only in which trace helper they call (--diff):

      0xF9A163  P7Byte_SendCmd    trace prints "\\n\\r[XX]\\n\\r"  -- a record's first byte
      0xF9A31A  P7Byte_SendData   trace prints "XX "            -- payload
      0xF9A4B0  P7Byte_SendArg    trace prints "[XX] "          -- a record's header args

  The trace is real, not inferred: when `(0x00F35A) != 0` each routine calls a helper that
  formats the byte and hands the string to `MIDI_Tx_SendUntilFF` (0xF992A7), so a service
  technician can watch every byte of the upload on MIDI OUT.

WHAT THIS DOES NOT ESTABLISH
  * WHICH CHIP is on the other end.  P7 is an instruction operand; the chip is not.  The
    SX-WSA1R carries three uPD6383GF DSPs and this port has three destinations, which is
    consistent and is NOT proof.
  * What P9 bit 0 (gap G's second half) IS.  What it DOES is answered below and is
    asserted by --verify: `bit 0,(0x19)` occurs EXACTLY ONCE in prom_c, at 0xFB050B, and
    its only effect is bit 2 of the 16-bit RAM word (0x0014FF) -- set when the pin reads
    LOW, cleared when it reads HIGH.  The routine that reads it then installs the bank
    base table at RAM 0x00D7ED: 0x00F00000, 0x00F00000, 0x00E80000, 0x00E90000,
    0x00EA0000, 0x00EB0000, 0x00010000, 0x00010000 -- the flash and wave banks.  So the
    pin is a STRAP sampled once, beside the bank map, and its flag is then read at seven
    sites in the voice module (0xFA72F1 to 0xFAD798).  Which physical option it selects is
    NOT established.
  * The eighteen P9-bit-3 poll sites gap G counts are exactly these three routines' six
    waits each -- 3 x 6 = 18 -- which is checked below.

METHOD
  Byte-window scan, the same discipline as notes/prom_a_p7_link_census.py: the encodings
  come from MAME's TLCS-900 disassembler tables (`F0 <addr8> <op>` with op = 0xB0|n RES,
  0xB8|n SET, 0xC8|n BIT).  A window scan is an UPPER bound in general -- a hit can be
  bytes inside another instruction or inside data -- but every hit reported here lands in
  0xF9A050-0xF9A645, which is converted assembly in prom_c/wsa1_prom_c.s, so for this
  range the counts are exact.

RUN
    python3 notes/prom_c_dsp_port.py            # the census
    python3 notes/prom_c_dsp_port.py --diff     # the three writers, byte for byte
    python3 notes/prom_c_dsp_port.py --verify   # assertions; exit != 0 on failure
"""
import argparse, os, sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
BASE = 0xF80000
MODULE = (0xF9A050, 0xF9A646)          # the three writers and their three trace helpers
WRITERS = {0xF9A163: ("P7Byte_SendCmd",  0xF9A319, 0xF9A0B9),
           0xF9A31A: ("P7Byte_SendData", 0xF9A4AF, 0xF9A0FD),
           0xF9A4B0: ("P7Byte_SendArg",  0xF9A645, 0xF9A12B)}
SFR = {0x06: "P2", 0x0D: "P5", 0x13: "P7", 0x19: "P9", 0x1F: "PB"}

def scan(pat):
    out, i = [], 0
    while True:
        i = D.find(pat, i)
        if i < 0: return out
        out.append(BASE + i); i += 1

def bitops():
    """(addr, sfr, op, bit) for every F0-form bit operation on a port SFR."""
    out = []
    for a in scan(b"\xf0"):
        o = a - BASE
        if o + 2 >= len(D): continue
        sfr, op = D[o+1], D[o+2]
        if sfr not in SFR: continue
        kind = {0xB0: "res", 0xB8: "set", 0xC8: "bit"}.get(op & 0xF8)
        if kind is None: continue
        out.append((a, SFR[sfr], kind, op & 7))
    return out

LD_P7   = b"\x8e\x08\x19\x13\x00"      # ld (0x0013),(XIZ+0x08)
P9_POLL = b"\xc0\x19\x23\xcb\xcc\x08"  # ld C,(0x19) / and C,0x08
TIMEOUT = b"\xbe\xfe\x02\x40\x1f"      # ld (XIZ-2),0x1F40
ERRFLAG = b"\xf2\x5c\xf3\x00\x00\x01"  # ld (0x00F35C),0x01

def census(verify=False):
    fails = []
    def chk(c, m):
        print(("  ok   " if c else "  FAIL ") + m)
        if not c: fails.append(m)

    inmod = lambda a: MODULE[0] <= a < MODULE[1]

    p7 = scan(LD_P7)
    print("THE DATA PORT")
    for a in p7: print(f"     0x{a:06X}  ld (0x0013),(XIZ+0x08)     -- P7 <- the byte argument")
    chk(len(p7) == 9 and all(inmod(a) for a in p7),
        f"{len(p7)} whole-register writes to P7 in prom_c -- 3 writers x 3 destination arms -- "
        "and every one is inside 0xF9A163-0xF9A645")

    poll = scan(P9_POLL)
    print("THE READY LINE")
    chk(len(poll) == 18 and all(inmod(a) for a in poll),
        f"{len(poll)} P9-bit-3 poll sites -- gap G's eighteen -- all inside the three writers")
    per = Counter()
    for a in poll:
        for w, (n, end, _) in WRITERS.items():
            if w <= a <= end: per[n] += 1
    chk(all(v == 6 for v in per.values()) and len(per) == 3,
        f"they split 6/6/6 across the three writers: {dict(per)}")

    to = [a for a in scan(TIMEOUT) if inmod(a)]
    er = [a for a in scan(ERRFLAG) if inmod(a)]
    chk(len(to) == 18, f"{len(to)} sites arm the same 0x1F40 = 8000 timeout, one per poll")
    chk(len(er) == 18, f"{len(er)} sites set the error flag (0x00F35C) := 1 on expiry, one per poll")

    print("THE STROBES")
    ops = [b for b in bitops() if inmod(b[0])]
    got = Counter((s, k, n) for _, s, k, n in ops)
    for key in sorted(got):
        print(f"     {key[0]} bit {key[2]}  {key[1]}  x{got[key]}")
    chk(set((s, n) for s, _, n in got) == {("P2", 7), ("P5", 3), ("P5", 4), ("P5", 5), ("PB", 5), ("PB", 6)},
        "exactly six port bits are touched: P2.7, P5.3, P5.4, P5.5, PB.5, PB.6")
    for s, n in (("P5", 4), ("P5", 5), ("P2", 7)):
        r, st = got[(s, "res", n)], got[(s, "set", n)]
        chk(r == 6 and st == 7,
            f"{s} bit {n}: {r} res / {st} set -- two of each in the three arms that use it, "
            "plus one `set` in P7Byte_SendCmd's preamble.  A destination strobe.")
    chk(got[("PB", "res", 5)] == 9 and got[("PB", "set", 5)] == 10,
        f"PB bit 5: {got[('PB','res',5)]} res / {got[('PB','set',5)]} set -- ONE res in every "
        "one of the nine arms.  Lowered for every byte: the data-valid line.")
    chk(got[("P5", "res", 3)] == 3 and got[("P5", "set", 3)] == 6,
        f"P5 bit 3: only {got[('P5','res',3)]} res against nine arms, and all three are in "
        "P7Byte_SendCmd (0xF9A1D2, 0xF9A24C, 0xF9A2C6).  A COMMAND/DATA qualifier, not a "
        "common line.")
    chk(got[("PB", "set", 6)] == 1 and got[("PB", "res", 6)] == 0,
        f"PB bit 6: {got[('PB','set',6)]} set and {got[('PB','res',6)]} res in the whole "
        "module -- raised once in the preamble and never lowered.  An enable.")
    chk(not any(k == "bit" for _, k, _ in got),
        "no BIT test on any of the six -- the ready line is read with `ld C,(P9) / and C,0x08`, not tested")

    print("P9 BIT 0 -- gap G's second half")
    b0 = [a for a, sfr, k, n in bitops() if sfr == "P9" and k == "bit" and n == 0]
    chk(b0 == [0xFB050B], f"`bit 0,(P9)` occurs exactly once in prom_c: {[hex(x) for x in b0]}")
    f14ff = scan(b"\xd1\xff\x14")
    print(f"     (0x0014FF) is read at {len(f14ff)} site(s): " +
          ", ".join(f"0x{a:06X}" for a in f14ff))
    chk(len(f14ff) == 9 and 0xFB0510 in f14ff and 0xFB0518 in f14ff,
        f"{len(f14ff)} sites carry the direct operand (0x14ff) -- the two arms at 0xFB0510 and "
        "0xFB0518 plus seven in the voice module.  (These are INSTRUCTION starts: the scan "
        "matches the 0xD1 prefix, and the literal sits one byte later.)")
    banktab = [a for a in scan(b"\xf2\xed\xd7\x00\x61") if 0xFB0500 < a < 0xFB0570]
    chk(len(banktab) == 1,
        f"the same routine installs the bank base table: {len(banktab)} `ld (0x00d7ed),XBC` "
        "in 0xFB0500-0xFB0570")

    print()
    if verify:
        if fails:
            print(f"{len(fails)} CHECK(S) FAILED"); return 1
        print("ALL CHECKS PASSED")
    return 0

def diff():
    """The three writers, byte for byte.  The brief's rule: state the differing count."""
    A = D[0xF9A31A-BASE:0xF9A4B0-BASE]
    B = D[0xF9A4B0-BASE:0xF9A646-BASE]
    d = [(i, A[i], B[i]) for i in range(min(len(A), len(B))) if A[i] != B[i]]
    print(f"P7Byte_SendData (0xF9A31A, {len(A)} B) vs P7Byte_SendArg (0xF9A4B0, {len(B)} B):")
    print(f"  same length, {len(d)} differing byte(s):")
    for i, x, y in d:
        print(f"    +0x{i:03X}  0x{0xF9A31A+i:06X}={x:02x}  0x{0xF9A4B0+i:06X}={y:02x}")
    print("  both are the two bytes of ONE `calr` displacement: 0xF9A331 targets the trace")
    print("  helper 0xF9A0FD, 0xF9A4C7 targets 0xF9A12B.  Nothing else differs, so the two")
    print("  routines are the same handshake and differ only in what they PRINT.")
    C = D[0xF9A163-BASE:0xF9A31A-BASE]
    print(f"\nP7Byte_SendCmd (0xF9A163) is {len(C)} bytes, {len(C)-len(A)} longer than the other two;")
    print("  its extra bytes are the destination-0 arm's `set 7,(P2)` / `set 6,(PB)` preamble at")
    print("  0xF9A168-0xF9A179, which the other two do not have.")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--diff", action="store_true")
    a = ap.parse_args()
    if a.diff: diff()
    else: sys.exit(census(a.verify))
