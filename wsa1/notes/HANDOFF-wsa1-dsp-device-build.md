# Build spec: a WSA1R DSP MAME device (uPD6383GF x3)

**Date 2026-09-06.** Everything here was reverse-engineered this session and is the
scoped, de-risked plan for the multi-session device build. It is the one lever
that both **implements the DSPs into the MAME core** and creates the **execution
instrument** the OPEN routing codes need to be decoded (see
`dsp/analysis/xcorpus-routing.md`: the corpus supplies occurrences, not a
consumer). Grades: MEASURED / STRONG / INFERRED / OPEN.

## Why it is the lever, and its ceiling

The KN5000 and WSA1R run the **same** uPD6383GF ISA (`FINDINGS-dsp-isa-crossval.md`).
The KN5000's `upd6383` core (`kn7000_mame/src/devices/cpu/upd6383/`) already
executes the ALU and parses the host protocol. Pointing it at the WSA1R microcode
gives the OPEN codes (`SRC 0x11/0x08/0x0B`, `ACT 0x0B/0x08`) their first
discriminating context. ⚠ Even complete, this does **not** reach 100% decode: the
`ACT 0x0D/0x0E` lag is hardware Q4 (needs a scope on a real unit), and the broad
ceiling is ~93.3%. It raises the floor; it does not remove the two hard blockers.

## The transport — MEASURED, and already modelled at the port latch

The three DSPs hang off CPU 2's bit-banged GPIO bus (schematic sheet II-15/16,
transcribed in `wsa1.cpp` above `cpu2_p9_r()`):

| net | pin | role |
|---|---|---|
| DSPD0-7 | P70-77 | the data byte |
| DSPCD | P5.3 | C/D: **low = command, high = data** (= the device's `host_w` `cd`) |
| DSP0CS/DSP1CS/DSP2CS | P5.4 / P5.5 / P2.7 | per-DSP /CS -> dest 0=IC6, 1=IC5, 2=IC30 |
| DSPWR / DSPRD | PB.5 / PB.6 | /WRITE, /READ strobes |
| DSPRDY | P9.3 | shared RDY, pulled up (idles high; `cpu2_p9_r()` returns it high) |
| DSPRST / DSPnRST2 | PB.2 / PB.1,3,4 | shared + per-DSP resets |

**Per-byte send sequence — MEASURED** (`prom_c/p7/p7_module.s:83-89`, command form):
```
res 4,(P5)                 ; /CS low
wait P9.3 != 0 (<=8000)     ; ready poll
set 4,(P5)                 ; /CS high
ld (P7),<byte>             ; data on the bus
res 5,(PB) / res 3,(P5) / res 4,(P5)   ; /WR low, C/D low(cmd), /CS low
wait P9.3 != 0 (<=8000)     ; ready poll (taken)
set 4,(P5) / set 3,(P5) / set 5,(PB)   ; restore
```
`P7Byte_SendData`/`SendArg` are identical but leave P5.3 **high** (data). So the
byte latches on the `/WR` low with the DSP's `/CS` low; `cd = P5.3` at that point.
⚠ EDGE ORDER: `/WR` drops one instruction *before* the `/CS` in the latch step, so
a naive "`/WR` low AND `/CS` low" test misfires — latch on the **`/CS` falling
edge while `/WR` is already low**, or capture on `/WR` low and attribute the DSP
from the CS that goes low next. Get this wrong and bytes are missed/mis-attributed.

## The framing — the RE gap that gates the build (OPEN)

The bytes on the wire are **5-byte groups** (`P7Stream_Run`; `FINDINGS-prom_c-p7-group-and-naming.md`):
```
ADDRESS opcode-1/5:  08 01 (A>>4)&0x0F ((A<<4)&0xF0)+8 0x21/0x25
ADDRESS opcode-0:    00 00 0x10+((A>>4)&0x0F) (A<<4)&0xF0 00
VALUE:               0A (v>>17)&0x7F (v>>9)&0xFF (v>>1)&0xFF ((v<<7)&0x80)+K
```
These are a nibble/7-bit-packed serialization. The chip's host protocol (as the
KN5000 drives it, `upd6383.cpp host_w`) is instead: `cd=0` command byte
(0x01 = write I-RAM: 16-bit addr + N*5-byte words; 0x02 = coeff: N*3-byte words),
then `cd=1` data bytes. **The mapping between the two is NOT established** — the
`08 01`/`0A` group leads do not obviously reduce to the KN5000's `01`/`02` + plain
address/word bytes. This is the gate: feeding raw group bytes into the KN5000
`host_w` mis-parses them. Establishing group -> chip-protocol is the core RE task.

## The build, in order

1. ✅ **DONE (2026-09-06). CPU 2 port handlers** P7/P5/PB/P2 with the `/CS`-falling-
   edge-while-`/WR`-low latch, capture-only, in `wsa1.cpp` (`dsp_capture()`, gated
   on `LOG_DSPUP`).  Analyser + recipe: `kn7000_mame/tools/rigs/wsa1_dsp_capture.py`.
   MEASURED (30 s boot): **17,859 bytes captured** — dest0/IC6 10,830, dest1/IC5
   6,173, dest2/IC30 856 — and the stream carries the documented P7 framing (dest0:
   540 value-group `0x0A` leads, 82 address-group `08 01` leads; the same shape on
   IC5/IC30).  ⇒ **the transport model is CORRECT: the real upload reaches the
   right DSPs in the right framing.**  ⚠ The C/D (`CMD`/`DAT`) tag is imperfect
   (P5.3's exact edge relative to the `/CS` latch needs one more look); the byte
   VALUES are right.
2. **Verify against the static corpus (framing gate, PARTIAL).** The captured
   5-byte groups (`08 01 ..` address, `0A ..` value) match
   `FINDINGS-prom_c-p7-group-and-naming.md`.  Still to do: de-frame the groups back
   to the pool records `wsa1_dsp_isa_crossval.py` extracts (70 opcode-3 / 99
   opcode-2) and confirm word-for-word — this both closes the gate and *reveals*
   the group→chip-protocol mapping (step 3).  The capture is the instrument for it.
3. **Map group -> chip host protocol** from step 2's evidence; if it reduces to the
   KN5000 `01`/`02` framing, feed `host_w(cd, byte)` directly; else extend the
   device (or add a WSA1R host adapter) to the WSA1R framing.
4. **Instantiate three `upd6383` devices** (IC5/IC6/IC30), route each destination's
   bytes, drive DSPRDY from device readiness (replacing the pulled-up-high hack).
5. **Gate**: after boot, each device's I-RAM must equal the statically-extracted
   microcode for its records. Only then is the device real, not a stub.
6. **Then decode**: with the DSPs executing, run the OPEN routing codes in their
   real contexts and anchor them by observing internal state — the method that
   decided every KN5000 code.

## Do NOT

- Feed raw 5-byte groups into `host_w` and call it done (step 3 is unproven).
- Ship a device whose I-RAM does not match the static corpus (step 5 is the gate).
- Claim any OPEN code decoded from occurrences alone — that is what the corpus
  already gives; decoding needs step 6's execution.
