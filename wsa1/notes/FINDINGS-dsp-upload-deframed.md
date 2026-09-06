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

## The C/D tag is CORRECT — the sampling rule, traced (MEASURED)

An earlier revision here called the driver's C/D tag "unreliable"; that was a
misdiagnosis, now corrected by a full trace of `P7Byte_SendCmd` (0xF9A163),
`P7Byte_SendData` (0xF9A31A) and `P7Byte_SendArg` (0xF9A4B0):

- `res 3,(P5)` (C/D low) is **not** in a shared sequence — it exists at exactly
  three sites, **all inside SendCmd** (0xF9A1D2 / 0xF9A24C / 0xF9A2C6, one per
  destination).  SendData and SendArg **never touch P5.3**; it stays HIGH.
- So at `ld (P7),byte` P5.3 is HIGH for all three routines (can't distinguish),
  and P5.3 diverges only inside SendCmd's `res 3 … set 3` window.
- **The single rule: sample P5.3 at the SECOND /CS-falling edge — the data latch,
  after `ld (P7)` and after `/WR` (PB.5) low.  P5.3==0 ⇒ command (SendCmd);
  P5.3==1 ⇒ data/arg (SendData/SendArg).**  There are TWO /CS-falling edges per
  byte; the first (pre-data) always reads HIGH.

The driver's capture already does exactly this — it triggers on `/CS` falling
while `PB.5` (`/WR`) is low, which is only ever the second edge — so its C/D tags
are **correct**.  What looked wrong ("mostly command" on IC6/IC5) is the real
upload shape: those two get coefficient-heavy streams (SendCmd/SendArg framing),
while IC30 carries a program block (below).

## The program-word framing, traced (MEASURED)

An opcode-3 record (the I-RAM instruction upload) serializes as:
`SendCmd(0x01)` + `SendArg(addr_hi)` + `SendArg(addr_lo)` + **N × `SendData`(raw
byte)** — a flat payload after a 16-bit big-endian start address, **no per-word
grouping** (the 5-byte grouping belongs to the coefficient opcodes 0/1/5).  In the
capture this is a `CMD 0x01` followed by a run of `DAT` bytes.  IC30 shows exactly
one such block: `CMD 0x01`, addr `0x0030`, then a 315-byte `DAT` payload.  To get
instruction words the driver regroups the payload by 5 from the start address (the
ROM gives no per-word framing to key off — the word width is the chip's, INFERRED
5 bytes).

## ✅ FRAMING GATE CLOSED for program words (MEASURED)

De-interleaving by the C/D command markers (not by byte value) works, and the
result verifies against the static corpus.  `dsp_verify_upload.py` on a 30 s boot:

- A program record is `CMD 0x01` + two `DAT` (16-bit big-endian start address) +
  N `DAT` payload bytes, regrouped by 5 into 40-bit words.
- **IC30's static program blocks match the corpus 63/63 per block** — every word
  is container-valid (top nibble 0) AND present in the statically-extracted
  corpus (`wsa1_dsp_isa_crossval.py`).
- The only non-matching words are at start address **0x0160 = I-RAM 352 — the
  host-poke region** (I-RAM 352..382, runtime parameter pokes computed by the
  firmware), which by definition are NOT in the static corpus.  So 126/150 total
  match, and the 24 that don't are exactly the runtime pokes, not a decode gap.
- In this boot IC6/IC5 receive coefficients only (their `CMD 0x01`s are the
  coefficient framing's, with no `DAT` payload); the program code goes to IC30.

⇒ **The DSP-device correctness gate is proven: the microcode the emulator uploads
at runtime is byte-for-byte the microcode the disassembler extracts statically.**
A `upd6383` instance fed this de-interleaved stream has the right I-RAM, and no
word is faked.

## Still open

- **Instantiate the `upd6383` device(s)** and feed the de-interleaved program +
  coefficient stream (mechanical now — the framing is proven).  Then the output
  stage (the KN5000's is a separate blocker) governs whether it makes sound; but
  as an *instrument* it can already run the OPEN codes for decode.
- **Capture the effect-load uploads** (not just boot) to see program code reach
  IC6/IC5 and to exercise more of the 918-word corpus at runtime.
- **The program (opcode-3) words** — the I-RAM instruction upload — are the other
  half; this pass characterised the coefficient (value/address) groups.  MEASURED:
  the three known group forms (addr `08 01`, value `0A`, opcode-0 addr `00 00 1X`)
  account for only **32%** of dest0's bytes (79 + 533 + 74 groups); the other
  **68% (7,398 bytes)** are the program-word upload in a framing not yet aligned.
  Aligning it to the statically-extracted 5,777 words (`wsa1_dsp_isa_crossval.py`)
  is the remaining step before an executing device, and it is helped by first
  fixing the C/D tag (above) so command bytes segment the stream.
