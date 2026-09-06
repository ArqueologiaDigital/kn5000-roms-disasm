# The captured WSA1R DSP upload de-frames to the known coefficients

**Date 2026-09-06.** This closes the value half of the DSP-device framing gate
(`HANDOFF-wsa1-dsp-device-build.md` step 2): the byte stream the MAME driver
captures off the WSA1R's DSP host bus de-frames into the documented P7 5-byte
groups, and the value groups decode to the *exact* coefficients the KN5000 side
derived independently.

Reproducer: `wsa1/dsp/analysis/dsp_deframe.py <dspcap.log>`, where the log is a
capture produced per `kn7000_mame/tools/rigs/wsa1_dsp_capture.py` (build with
`LOG_DSPUP`, boot, `grep dspup: error.log`).  The capture is regenerable; the
driver capture code and this de-framer are the committed instruments.

## The framing (MEASURED, from the capture)

```
ADDRESS group  08 01 (A>>4)&0x0F ((A<<4)&0xF0)+8 <tag>   tag 0x21 or 0x25
               A = ((b2 & 0x0F) << 4) | ((b3 & 0xF0) >> 4)
VALUE group    0A (v>>17)&0x7F (v>>9)&0xFF (v>>1)&0xFF ((v<<7)&0x80)+K
               v = ((b1&0x7F)<<17) | (b2<<9) | (b3<<1) | ((b4&0x80)>>7)   (24-bit)
               K = b4 & 0x7F
```

## What de-frames out (MEASURED, one 30 s boot)

| dest | chip | bytes | addr groups | value groups | known coefficients | K tags |
|---|---|---:|---:|---:|---|---|
| 0 | IC6 | 10,830 | 79 | 533 | 0.5 ×16, chorus-LFO ×4, zero ×141 | 0x15 ×239, 0x4C ×174, 0x26 ×108 |
| 1 | IC5 | 6,173 | 47 | 269 | wrap ×2, 0.5 ×2, zero ×94 | 0x4C ×106, 0x15 ×93, 0x26 ×59 |
| 2 | IC30 | 856 | 4 | 15 | wrap ×2, zero ×13 | 0x15 ×15 |

The decoded values are the **exact constants the KN5000 work derived**:
`0x400000` = 0.5, `0x000072` = the CHORUS LFO ramp step (`dsp/tools/lfo_ramp.py`),
`0x7FFFFF` = the wrap constant.  The K tags are the measured `0x15` (opcode-0
tail) and `0x4C` (opcode-5 tail) from
`FINDINGS-prom_c-p7-group-and-naming.md`, plus `0x26`.  Address groups decode to
C-RAM / coefficient bases (0x00 / 0x20 / 0x60 / 0xC0-region).

## Why it matters

1. **The transport + value framing are correct end to end** — the emulated
   WSA1R's coefficient upload reaches the three DSPs and de-frames to the right
   numbers.  This is no longer a guess about the bus; it is measured.
2. **Cross-confirmation both ways.** The WSA1R silicon uploads the same
   coefficient constants the KN5000 firmware analysis derived — each corroborates
   the other, on two products carrying the same chip.
3. **The device is unblocked on the value side.** A `upd6383` instance fed these
   de-framed (address, 24-bit value) coefficient writes has its C-RAM loaded with
   the real numbers.

## Still open

- **The C/D (command/data) tag** the driver records is unreliable — the per-byte
  sequence pulses P5.3 low just before every latch, and sampling it at the P7
  write instead keys off the destination, not the role.  Getting it right needs a
  precise per-destination trace of `P7Byte_SendCmd/SendData/SendArg`
  (prom_c 0xF9A163 / 0xF9A31A / 0xF9A4B0).  The byte VALUES are right regardless.
- **The program (opcode-3) words** — the I-RAM instruction upload — are the other
  half; this pass characterised the coefficient (value/address) groups.  MEASURED:
  the three known group forms (addr `08 01`, value `0A`, opcode-0 addr `00 00 1X`)
  account for only **32%** of dest0's bytes (79 + 533 + 74 groups); the other
  **68% (7,398 bytes)** are the program-word upload in a framing not yet aligned.
  Aligning it to the statically-extracted 5,777 words (`wsa1_dsp_isa_crossval.py`)
  is the remaining step before an executing device, and it is helped by first
  fixing the C/D tag (above) so command bytes segment the stream.
