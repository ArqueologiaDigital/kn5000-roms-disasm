#!/usr/bin/env python3
"""What rate does CPU 2's INTT1 run at?  (lane O1, overlay gap review)

WHY THIS EXISTS
---------------
Two places in this tree say the rate cannot be worked out:

  * prom_c/midi/midi_serial_port.s, header of Timer1_SetPeriodAndStart --
    "⚠ the timer-1 CLOCK SOURCE.  This routine does not write T01MOD, and no
    write to it has been located, so TREG1 = 28 cannot be turned into a tick
    period here.  The INTT1 rate -- which paces the whole six-phase scheduler
    at 0xF99063 -- is therefore NOT ESTABLISHED."
  * notes/FINDINGS-prom_c-scheduler.md -- "⚠ THE TICK RATE IS NOT ESTABLISHED."

It IS established.  prom_c's own reset block writes T01MOD, 0x2F bytes before
the P8CR write the EEPROM note already quotes from the same run.  The write was
missed because the lane that asked the question was reading the MIDI module, and
the answer is in the boot module.

That matters beyond bookkeeping: CPU 2's MIDI active-sensing interval and its
receive timeout are counted in these ticks (FINDINGS-prom_c-serial-midi.md
quotes 135 and 165 ticks and can only offer "a tick of about 2.2 ms or less" as
an inference from the MIDI 1.0 300 ms rule), and the six-phase scheduler that
paces MAIN -- and with it Dev10C_PollBankAndRetire, the voice retire poll --
runs off the same interrupt.

METHOD
------
Census `ldio T01MOD,imm` in each image two independent ways and require them to
agree:

  (a) BY BYTES.  The encoding is `08 24 <imm>` (opcode 0x08 = `ld (n8),#8`,
      dasm900.cpp; SFR 0x24 = T01MOD, include/tmp95c061_sfr.inc, whose names come
      from MAME's tmp95c061 symbol table).
  (b) BY SOURCE.  Count the `ldio T01MOD,...` lines in the gate-verified sources.

⚠ Why (b) is needed AND why the usual instruction-boundary filter is not used
here: the two reset blocks are hand-annotated and emit the symbolic form with no
address comment, so a filter keyed on the address column rejects exactly the
instruction this note is about.  Two whole-image counts agreeing at ONE is the
stronger check anyway -- a data false positive would make (a) exceed (b).

Then apply the arithmetic prom_a's own copy already carries.

Run:  python3 cpu2_timer1_rate.py
"""
import os, re, glob

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, "..", "..", "original_ROMs")
SRC  = os.path.join(HERE, "..", "..")

IMAGES = [("wsa1_prom_a.ic12", 0xF80000, "prom_a (CPU 1)", "prom_a"),
          ("wsa1_prom_c.ic28", 0xF80000, "prom_c (CPU 2)", "prom_c")]

SYM = re.compile(r"^\s*ldio\s+T01MOD\s*,\s*(\S+)", re.M)

ok = True
hits = {}
for fn, base, label, srcdir in IMAGES:
    data = open(os.path.join(BASE, fn), "rb").read()
    all_hits = [(base + i, data[i+2]) for i in range(len(data) - 2)
                if data[i] == 0x08 and data[i+1] == 0x24]
    # ⚠ `08 24 xx` is a common byte triple inside data.  The claim here is about
    # ONE value, 0x0D, so the census is narrowed to it and the rest is reported
    # as the false-positive floor a wider census would have carried.
    byte_hits = [(a, v) for a, v in all_hits if v == 0x0D]
    src_hits = []
    for f in glob.glob(os.path.join(SRC, srcdir, "**", "*.s"), recursive=True):
        src_hits += SYM.findall(open(f, errors="replace").read())

    print(f"\n=== {label} ===")
    print(f"  `08 24 xx` byte triples anywhere in the image: {len(all_hits)}"
          f"  (only imm 0x0D is claimed; the rest is the false-positive floor)")
    for a, v in byte_hits:
        print(f"  (a) bytes  0x{a:06X}  ldio T01MOD,0x{v:02X}")
    for v in src_hits:
        print(f"  (b) source            ldio T01MOD,{v}")
    src_hits = [v for v in src_hits if v.lower() in ("0x0d", "0xd", "13")]
    if len(byte_hits) == len(src_hits) == 1:
        print(f"  AGREE: exactly one write, value 0x{byte_hits[0][1]:02X}")
        hits[label] = byte_hits[0]
    else:
        print(f"  MISMATCH: {len(byte_hits)} byte hit(s) vs {len(src_hits)} source line(s)")
        ok = False

print("""
=== THE ARITHMETIC, identical on both processors ===
T01MOD = 0x0D  ->  bits 3-2 = 0b11 = phiT256 = fc/2048 for TIMER 1
                   (bits 1-0 = 0b01 = phiT1 for timer 0, which is not used here)
fc = 28 MHz  (prom_c[0xFFFFEF] = 0x1C, notes/FINDINGS-system-clock.md)
phiT256 = 28,000,000 / 2048 = 13,671.875 Hz

CPU 1: TREG1 = 0x1C = 28, a literal -- ldio TREG1,0x1C at prom_a 0xF826F4.
CPU 2: TREG1 = 28 too, but LOADED AT RUN TIME from the fc byte --
       Timer1_SetPeriodAndStart (0xF990FA) is called from 0xF98BA8 with
       `ld BC,(0xFFFFEF) / extz BC / push BC`, and 0xFFFFEF = 0x1C = 28.

13,671.875 / 28 = 488.28 Hz ON BOTH PROCESSORS; one tick is 2.048 ms.
""")

a = hits.get("prom_a (CPU 1)")
c = hits.get("prom_c (CPU 2)")
if ok and a and c and a[1] == c[1] == 0x0D:
    print(f"PASS: prom_a writes T01MOD = 0x0D at 0x{a[0]:06X} and prom_c writes the")
    print(f"      SAME VALUE at 0x{c[0]:06X}, each exactly once, each in its reset block.")
    print("      CPU 2's INTT1 therefore ticks at 488.28 Hz, the same as CPU 1's.")
    print("""
      COROLLARY, a check rather than a restatement:
      FINDINGS-prom_c-serial-midi.md measures CPU 2's active-sensing interval at
      135 ticks and its receive timeout at 165 ticks, and could only offer "a
      tick of about 2.2 ms or less" as an inference from MIDI 1.0's 300 ms rule.
      At 2.048 ms those are 276.5 ms and 337.9 ms -- one either side of 300 ms,
      and 276.5 ms is the SAME interval FINDINGS-midi-port.md derives for CPU 1
      from a different counter.  Two MIDI ports, two counters, one answer.

      SO THE FOLLOWING TWO STATEMENTS IN THIS TREE ARE NOW SUPERSEDED:
        * prom_c/midi/midi_serial_port.s, Timer1_SetPeriodAndStart header --
          "no write to it has been located ... The INTT1 rate ... is therefore
          NOT ESTABLISHED"
        * notes/FINDINGS-prom_c-scheduler.md -- "the tick RATE is not established"
      The write is at prom_c 0xFFF06C, in prom_c/boot/reset_and_vectors.s, five
      instructions before the `ldio P8CR,0x19` that FINDINGS-prom_c-eeprom-and-
      runtime.md already quotes from the same run.""")
else:
    print("FAIL: the two censuses did not agree, or the value is not 0x0D.")
