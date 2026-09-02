# The µPD6383GF as this firmware uses it — a host-side specification

**Lane `w12/drvdsp`, 2026-09-02.** Sources: the dumped KN5000 Sub CPU ROM
(v1.42) and boot ROM, the four SX-WSA1R EPROMs, the decoded source in this tree,
and the KN5000 service-manual schematics. **No hardware, no capture, no
datasheet.**

Every number is reproducible with

```
python3 notes/sound/dsp_protocol_cross_product.py            # all sections
python3 notes/sound/dsp_protocol_cross_product.py --selftest # 28 invariants
```

which re-derives, and fails on, figures the `wsa1/` notes already published
(297 streams, 1,832 records, the nine IC310 effects, the four shared runs).
Toolchain-independent: it reads ROM bytes, not disassembler output.

**Gate:** `make gate-all` PASS in this worktree — all 13 images IDENTICAL. This
lane added two files under `notes/` and changed no build input; the gate is
recorded because the lane brief requires it, not because anything could have
moved.

---

## 0. THE ANSWER, FIRST

> **Can the firmware now specify the device well enough to write a MAME device?**

**The *bus interface* — yes. The *chip* — no, and the gap is not small.**

What is now fully specified is the **host side**: every pin, every strobe order,
the timeout, the record container, the command set, and the wire byte stream that
leaves the CPU. A device that accepts that traffic, acknowledges it correctly and
lets both machines boot can be written today from this note alone.

What is **not** specified is what the chip *does* with any of it. The instruction
set is 13.4 % decoded on the frame floor and 9.0 % by vocabulary
(`dsp/README.md`); there is no register map for the chip's own control registers,
only a cell map for the two RAM spaces the host pokes; and no ROM byte in either
machine names a part. A device written from this note would be a **faithful
transport with a silent core** — which is a real and useful milestone, and is
*not* an effects processor.

The specific things that are missing are named in §9, each with what would close
it.

---

## 1. THE DISCRIMINATOR, AND ONE CORRECTION TO THE BRIEF

The brief proposed: *"the same driver code runs on four processors across two
instruments; anything identical across all of them is a property of the chip."*

★ **That instrument has to be re-aimed before it is used, because the 234-byte
driver it points at is not this device.**

The 234-byte block that is 231/234 identical between WSA1R prom_a (`0xF85F0F`)
and prom_c (`0xF98000`) drives a **4-channel × 32-register address/data file** at
`0x007F0000` / `0x00E00000`, whose KN5000 sibling is at `0x00130000`. That is
*not* the µPD6383GF host interface, and the tree already says so in two places:

* `subcpu/boot/kn5000_subcpu_boot.s:52` — *"kn5000.cpp maps it to IC311 but
  records that it is NOT the uPD6383GF host interface, since the microprogram and
  coefficient uploads go over port PZ with the port 7 strobes — so WHICH chip
  decodes it is [UNCERTAIN]"*;
* `wsa1/dsp/dsp_channel_regs.s` — *"'DSP' is a name BORROWED from the KN5000
  lane… It is a borrowed name, not a WSA1 finding."*

**The real cross-product instrument is different and stronger.** It is the pair

| | KN5000 | SX-WSA1R |
|---|---|---|
| upload transport | Sub CPU (TMP94C241), port **PZ** + P7/PE/PH strobes | CPU 2 prom_c (TMP95C061), port **P7** + P5/P2/PB strobes |
| record interpreter | `DSP_BytecodeInterpreter_Loop` `0x03C2CB` | `P7Stream_Run` `0xF9A646` |
| opcode handlers | `DSP_Bytecode_Programs` `0x03C32E` | the arms at `0xF9AD84` |
| corpus | 100 algorithm + 100 coefficient streams, 39,372 B zone | 297 streams, 60,385 B pool |

These are two **independently written** drivers, and that is measured rather
than assumed: the longest run of the WSA1R's 439-byte `P7Byte_SendCmd` occurring
anywhere in the KN5000 Sub CPU ROM is **6 bytes**, searched up to 32. Where two
separately-authored drivers agree, the agreement is about the thing on the other
end — which is exactly what makes their agreements evidence.

**Only two processors are involved, not four.** The data-port write
`ld (0x0013),(XIZ+0x08)` occurs **9 times in prom_c and 0 times in prom_a,
prom_b and prom_d**. CPU 1 has no P7 byte transport at all; CPU 2 alone drives
the DSP destinations.

---

## 2. THE BUS INTERFACE

### 2.1 KN5000 — IC311 (µPD6383GF-3BA), Sub CPU TMP94C241F

Pin map, read off the firmware's nine primitives (`dsp/analysis/host-side.md`
§6.1) and corroborated by the service manual:

```
  PZ  (SFR 0x68)  the 8-bit DATA LATCH, written WHOLE:  ld (0x68),A
  P7  (SFR 0x1C, P7CR = 0x78 -> bits 3..6 outputs)
        bit 3  /WR    assert 0x0383AF   release 0x0383B3
        bit 4  /RD    assert 0x0383B7   release 0x0383BB     <-- 0 call sites
        bit 5  /CS1   assert 0x0383D1   release 0x0383ED     IC311
        bit 6  C/D    0x0383A7 -> COMMAND   0x0383AB -> DATA (idles at DATA)
  PE  (SFR 0x38)
        bit 6  /CS2   assert 0x0383D6   release 0x0383F2     IC310 (a DIFFERENT chip)
  PH  (SFR 0x44, PHCR = 0x46 written 0x07)
        bit 0  READY in  (IC311 pin 8 RDY -> R334 4k7 -> +5D -> net DSPRDY
                          -> TMP94C241 pin 146; service manual pp.33/35)
        bit 1  /RESET DSP1     bit 2  /RESET DSP2
        bit 3  a strap, sampled once at 0x034C87
```

**Register width: none.** There is no addressed register file on the wire. The
interface is a **byte port with a command/data qualifier**: `C/D` low marks a
byte as a command, `C/D` high as data. Everything else — port numbers, I-RAM
addresses, 24-bit coefficients — is carried *inside* the data stream, not on
address lines.

★ **The read strobe exists and has ZERO call sites in 192 KB.** `0x0383B7`
asserts `/RD` and nothing calls it. Two consequences: the byte port is
bidirectional in hardware (or the primitive would not have been written), and
**this firmware's traffic is a pure write log** — nothing is ever read back
except the one-bit READY.

### 2.2 SX-WSA1R — CPU 2 (prom_c, TMP95C061)

```
  P7  (SFR 0x13)  the 8-bit DATA LATCH, written WHOLE:  ld (0x0013),byte
  P5  (SFR 0x0D)  bit 3  command/data qualifier (lowered ONLY by P7Byte_SendCmd)
                  bit 4  destination-0 strobe
                  bit 5  destination-1 strobe
  P2  (SFR 0x06)  bit 7  destination-2 strobe
  PB  (SFR 0x1F)  bit 5  data valid (lowered for every byte, in all nine arms)
                  bit 6  enable -- 1 `set`, 0 `res`, in the whole module
  P9  (SFR 0x19)  bit 3  READY in, polled TWICE per byte at 18 sites
                  bit 0  a strap sampled once, at 0xFB050B, beside the bank map
```

**Three destinations, selected by the routine's second argument.** The machine
carries three µPD6383GF DSPs, which is *consistent* and is not proof.

### 2.3 What is the CHIP and what is the PRODUCT

| | chip or product | evidence |
|---|---|---|
| an 8-bit parallel byte port written whole, never bit-banged | **CHIP** | both, independently |
| a command/data qualifier line | **CHIP** | both, independently |
| a single READY input polled before and after every byte | **CHIP** | both, independently |
| the timeout `0x1F40` = 8000 spins | **CHIP-ADJACENT, but see below** | both, same constant |
| which SFR carries which line | **PRODUCT** | PZ/P7/PE/PH vs P7/P5/P2/PB |
| a `/RD` strobe and a `/RESET` line | **PRODUCT** (KN5000 only) | no WSA1R equivalent found |
| how many destinations one port serves | **PRODUCT** | 1 (+1 serial chip) vs 3 |
| what happens on timeout | **PRODUCT** | see §2.4 |

⚠ **The shared `0x1F40` is weaker evidence than it looks.** 8000 is a round
decimal number, both firmwares are Toshiba-TLCS-900 C-compiler output from the
same vendor in the same era, and a shared house constant is at least as likely as
a datasheet figure. It is recorded because it is a real agreement, and it is
**not** offered as a chip timing parameter.

### 2.4 ★ The READY line is LIVE on one machine and DEAD on the other

This is the single most important thing a device implementer needs, and it is
counter-intuitive.

**KN5000: the handshake is vacuous.** The Sub CPU writes `PHCR := 0x07`
(`ld (0x46),0x07`, once in the boot ROM at `0xFF82F0` and once in the v1.42
payload at `0x01F9A4`), making PH0/1/2 **outputs**. `DSP_Read_Status` is
`SET 0,(PH)` then `LDCF 0,(PH)` — it sets the bit and reads back its own latch.
READY is 1 always, whatever IC311 does. The chip's RDY pin is *wired* and
*invisible*. (`dsp/analysis/second-dsp-and-ready.md` A2; re-measured here.)

**WSA1R: the handshake is real.** The ready bit is P9 bit 3, and P9 is an
**input-only** port on the TMP95C061 — MAME's `tmp95c061.cpp` maps `0x000019`
with `.r(...)` and no writer, and there is no `P9CR` in the SFR map at all. The
emulated machine sits in this poll loop for most of the first 70 seconds of boot
precisely because nothing answers.

⚠ Neither fact is a property of the chip. Both are host-side port-direction
decisions, and they point opposite ways: **a KN5000 device need not drive its
ready pin; a WSA1R device must.** Any "the DSP asserts ready after accepting a
byte" comment in a KN5000 driver is wrong even though the resulting behaviour is
right.

### 2.5 Error paths

```
  KN5000   two distinct failures.  ERROR 1 on timeout (8000 spins with READY
           low) and ERROR 1 again if READY drops between the /WR assert and the
           byte write.  DSP_ParameterWriteEngine tests the return and, on error,
           calls 0x03CFED -- a bare `ret' -- and ABANDONS THE RECORD.
  WSA1R    one failure.  On timeout it sets (0x00F35C) := 1 and SENDS THE BYTE
           ANYWAY.  That flag is the only error report in the whole transport.
```

⚠ **PRODUCT, not chip.** The KN5000 silently drops the write; the WSA1R barrels
on. A device model must not infer from either that the chip tolerates or
requires anything.

### 2.6 A service back-door worth knowing about

When `(0x00F35A) != 0`, the WSA1R formats **every uploaded byte** as two ASCII hex
digits and hands it to `MIDI_Tx_SendUntilFF` — the whole upload leaves on MIDI
OUT. Three trace spellings distinguish the byte roles: `\n\r[XX]\n\r` for a
record's command byte, `[XX] ` for its header arguments, `XX ` for payload.
⚠ What sets `(0x00F35A)` is not established. If it can be reached from the panel,
**this is a way to capture the exact wire stream from real hardware with no
probe** — see §9.

---

## 3. THE UPLOAD RECORD FORMAT

Identical container on both products, verified by walking both corpora with one
framer:

```
  byte 0:  bits 7:4 = OPCODE      bits 3:0 = length[11:8]
  byte 1:                         length[ 7:0]
  length counts the two header bytes.  opcode 0xF = END, record length 2.
```

Opcode census over the two corpora (`… grammar`):

| op | KN5000 records | WSA1R records | what the arm does |
|---:|---:|---:|---|
| 0 | 56 | 895 \* | 3 head bytes, groups of 5, three per-group branches |
| 1 | 71 | 99 | 3 head bytes, groups of 5, one branch |
| 2 | 71 | 99 | 3 head bytes, groups of 3 (KN5000) / 4 (WSA1R) |
| 3 | 40 | 70 | command + 16-bit address + raw tail |
| 4 | 189 | 266 | one command byte, no data |
| 5 | 62 | 81 | 3 head bytes, groups of 5, two branches |
| 13 | 28 | **0** | bus idle + task yield — **KN5000 only, no WSA1R arm** |
| 14 | 26 | 25 | one command byte + raw tail |
| 15 | 100 | 297 | END |

\* ⚠ The WSA1R op-0 count is **contaminated** — see §5.

⚠ **DENOMINATORS.** The KN5000 column counts records over the **100 distinct
stream addresses** the two pointer arrays name, deduplicated — 42 effect numbers
share one stream trio, so a per-effect tally over 200 pointers gives larger
numbers for the same bytes. `second-dsp-and-ready.md` B5's *"op-D occurs 34
times"* is that other denominator and does not contradict the 28 here. Quote one
convention.

### 3.1 ★ What the chip actually sees, per opcode

The record format is a **host-side container**. What reaches the chip is one
command byte and then data bytes. Counting the emit sites in each machine's own
arm, from the ROM bytes (`… handlers`):

| op | KN5000 cmd/data | WSA1R cmd/data | |
|---:|---:|---:|---|
| 0 | 1 / 17 | 1 / 17 | **SAME** — 2 head + 3 branches × 5 |
| 1 | 1 / 7 | 1 / 7 | **SAME** — 2 head + 1 × 5 |
| 2 | 1 / 5 | 1 / 8 | **DIFFER** — 2 + 1×3 vs 2 + 2×3 |
| 3 | 1 / 3 | 1 / 3 | **SAME** — 2 head + a 1-byte tail loop |
| 4 | 1 / 0 | 1 / 0 | **SAME** |
| 5 | 1 / 12 | 1 / 12 | **SAME** — 2 head + 2 branches × 5 |
| 14 † | 1 / 1 | 1 / 1 | **SAME** — command + raw tail loop |

† The KN5000's `0x0D` and `0x0E` handlers lie **outside** the six offset-table
arms, so the probe's ROM census does not cover them; that row is counted from the
decoded source (`DSP_Bytecode_Op0E_SendCommand` plus `_DataLoop`: one command,
then a one-byte data loop). Every other row is a ROM-byte census on both sides.

★ **Every arm but one emits the same number of wire bytes with the same branch
structure on both products.** Two independently written drivers, same traffic
shape per record. That is much stronger than "the framing matches".

★ **And op 2 is reconciled rather than left as a contradiction.** The WSA1R's
op-2 group is **four** stream bytes but still **three** wire bytes: the extra
byte is a per-group tag the host consumes to choose between a raw branch and a
relocated one (`prom_c 0xF9AA53: ld A,(XIX) / cp A,0`), exactly as op 0/1/5
already do on *both* machines. The KN5000's op 2 has no tag and one branch.
So the difference is in the **host-side container**, not in what the chip sees:
on both products an op-2 record delivers command `0x02` and a whole number of
**three-byte** words.

The residue test confirms this from the data rather than the code, and it
discriminates on both sides:

```
  KN5000 op 2:  71 records, 71 fit groups of 3,  7 fit 4    (39 discriminating)
  WSA1R  op 2:  99 records, 61 fit 3,           99 fit 4    (31 discriminating)
```

Each machine's payloads agree with its own handler and disagree with the other's.

⚠ **The one thing that could have arbitrated this and does not.** No byte-
identical run between the two ROMs contains a whole op-2 record, so the shared
bytes are consistent with both readings. That is a limit of the evidence, not a
finding that op 2 agrees.

★ **Opcode 0x0D emits nothing at all** — it is a host scheduling directive
(SPI bus-idle + task yield) that the chip never sees. It occurs 28 times on the
KN5000 (100-stream denominator), **zero times** anywhere in the WSA1R pool, and
`second-dsp-and-ready.md` B5 reports that on the 200-stream denominator all 34
occurrences immediately follow a command-`0x30` record — i.e. it belongs to the
IC310 link, which has no ready bit and needs a settle marker instead. On a device model it is invisible; on a *host* model it is a yield
point.

### 3.2 Is there a header, a length, an entry point?

**A record has a length. A program does not.** There is no program header, no
program length and no declared entry point anywhere in either firmware's upload
material. What exists instead:

* the **stream** is a sequence of records terminated by an `0xF` record;
* an op-3 record names a **16-bit I-RAM word address** and streams 5-byte
  instruction words to it;
* the "entry point" is a **convention** — the resident kernel occupies I-RAM
  word 0, and effect bodies load at word **84** (unit 0) or word **200**
  (unit 1), with the host rewriting link words **64** and **71** to connect a
  unit and an epilogue at word **60**. Those six addresses are the entire set
  seen in the KN5000's canned streams and its one live cold-boot capture.

⚠ *"I-RAM 84 is the unit-0 entry point"* is an inference from what the firmware
consistently does, not a decoded fact about the chip. Nothing in the ROM declares
it.

---

## 4. THE COMMAND SET

The byte sent with the command/data qualifier asserted (`… commands`):

| command | KN5000 | WSA1R | reading |
|---|---|---|---|
| `0x01` | 227 | 340 | aim the write pointer at a 16-bit port/address and stream words |
| `0x02` | 71 | 99 | the 24-bit coefficient port (3-byte words) |
| `0x03` | 189 | 260 | end of transaction, no payload |
| `0x04` | — | 6 | boot-time singleton; KN5000 live capture shows it with a 5-byte payload |
| `0x09` | — | 6 | boot-time singleton; KN5000 capture payload `00 3C` = 60, the epilogue address |
| `0x0C` | — | 3 | boot-time singleton; KN5000 capture payload `00 55 55` |
| `0x0F` | — | 6 | WSA1R only, on op-4 records |
| `0x30` | 28 | — | **NOT this chip** — IC310, an MN19413 on a 3-wire serial link |

★ **`0x01`, `0x02` and `0x03` are the whole of the resident command set on both
products, and they are used the same way.** That is a chip-level finding.

⚠ **`0x04`/`0x09`/`0x0C` appear in the KN5000 only in the one live cold-boot
capture**, not in the canned ROM streams — they are emitted by boot code, not by
an effect stream. On the WSA1R they appear as canned records. So the *union* is
`{01, 02, 03, 04, 09, 0C, 0F}` and only the first three are firmly resident-path.
`0x0F` is seen only on the WSA1R and nothing decodes it.

⚠ `0x30` must never be read across. On the KN5000 it addresses IC310, whose
transport is a completely different one (3-wire bit-banged serial on PF.0/PF.2
with PE.6 as chip select, no ready poll, no timeout, no error return), whose
instruction word is 32 bits and whose coefficient word is 16
(`dsp/analysis/second-dsp-and-ready.md` B4/B6/B7).

### 4.1 The two 16-bit numbers command `0x01` carries

The KN5000 census separates them cleanly:

* `0x0000 0x003C 0x0040 0x0047 0x0054 0x00C8` are **I-RAM word addresses** —
  0 / 60 / 64 / 71 / 84 / 200, the kernel, the epilogue, the two link words the
  host rewrites, and the two body entry points;
* **`0x0160` is a POKE PORT, not an I-RAM address.** Every runtime parameter
  write is aimed there — 312 records over the 100 canned parameter streams
  (`host_side.py hostif`, per-effect denominator), matched one-for-one by 312
  end-of-transaction `0x03` commands — and register and D-RAM traffic share it.
  `0x0161` is the 24-bit coefficient port used by command `0x02`.

⚠ That `0x0160`/`0x0161` are ports rather than addresses is an inference from
their traffic (they carry heterogeneous destinations that the *payload* then
distinguishes by tag — see §6), not a decoded chip fact.

---

## 5. ★ A NEW RESULT: the WSA1R pool's second payload convention is the KN5000's parameter grammar

`wsa1/notes/FINDINGS-prom_c-p7-byte-stream-pool.md` left this open:

> *"130 of the 297 streams contain at least one record whose payload is not a
> whole number of the interpreter's groups. Those cannot be what `P7Stream_Run`
> runs. The container is the same; the payload convention is not, and the routine
> that reads them has not been found."*

**Those records are PARAMETER records, in the KN5000's parameter-record
grammar.** A KN5000 parameter record is `[len_hi, len_lo, id, payload…]` with a
16-bit length; because a record is shorter than 4096 bytes, `len_hi`'s high
nibble is zero and the bytecode framer reads it as "opcode 0" with the *same*
length. That is the contamination in the op-0 row of §3.

The signature, **calibrated on the KN5000 where both kinds are already named**:

```
       KN5000 corpus   tables  records  translator id  end 0x7A
        PARAM VALUES       59      445            445       445
   PARAM DESCRIPTORS       41      258            258         0
```

Every value record carries an id from the translator dispatch set
`{0x21, 0x24, 0x40, 0x61..0x79}` **and** ends on `0x7A`; every descriptor record
carries a translator id and **never** ends on `0x7A`. Applied to the WSA1R pool:

```
        third byte  records  end 0x7A
     translator id      815       441
          cmd 0x01      340         0
          cmd 0x03      260         0
          cmd 0x02       99         0
          cmd 0x0F        6         0
          cmd 0x04        6         0
          cmd 0x09        6         0
          cmd 0x0C        3         0
```

815 records carry a translator id, 441 of them ending `0x7A` — the same
value/descriptor mixture. **Not one** of the 720 records with a command byte ends
on `0x7A`: the signature could have fired on them and does not.

⚠ **What this does and does not say.** It says the second consumer is a
*parameter-record walker* using the KN5000's own translator opcode set, not a
second microcode format. It does **not** locate that walker in the WSA1R ROMs —
nobody has pointed at the routine. And three of the four published byte-identical
runs are KN5000 objects named `*_Param_Values`, which is consistent and is not
independent evidence.

---

## 6. THE COEFFICIENT / PARAMETER INTERFACE

### 6.1 The runtime framing

Every runtime parameter write is one transaction
(`dsp/analysis/host-side.md` §6.2):

```
  DSP_DispatchCommand(0x01)     ; 0x03CA41
  DSP_DispatchData(0x01)        ; the 16-bit port number 0x0160
  DSP_DispatchData(0x60)
  <the translator's output: one address word + one datum,
   or a 36-cell block for opcode 0x74>
  DSP_DispatchCommand(0x03)     ; end of transaction
```

emitted **only when the target chip is DSP1** (`chip = *(0x0001ED6D + unit)`), so
one engine serves both chips.

### 6.2 The datum, and what a value means

A parameter value is a **five-byte packet whose low seven bits are a TAG naming
the destination space** (`dsp/analysis/register-space.md` §1):

```
  byte 0 = 0x0A  (44 of 1751 canned packets carry 0x0B -- OPEN, see below)
  byte 1 = (v >> 17) & 0x7F
  byte 2 = (v >>  9) & 0xFF
  byte 3 = (v >>  1) & 0xFF
  byte 4 = ((v << 7) & 0x80) | TAG

  TAG 0x15  D-RAM / registers      writer 0x03846C / 0x038539
  TAG 0x26  C-RAM                  writer 0x0387E6   (RUNTIME ONLY -- 0 canned)
  TAG 0x4C  delay descriptor       writer 0x038922
```

So a value is a **24-bit quantity carried in a 5-byte container** with a 7-bit
destination-space tag, and coefficients are signed **Q0.23**. The round trip over
all 1,751 canned packets is 1751/1751 for `v >> 17` against 938/1751 for the
previously published `v >> 1`, so the split is measured, not assumed.

⚠ **OPEN, and stated rather than smoothed over:** the writer emits byte 0 as the
literal `0x0A`, but 44 of the 1,751 canned packets carry `0x0B`. All 44 target
*even* cells of the `0x50…` state block — the cells holding delay lengths. One
bit above the 24-bit field is in use and nobody knows what it means.

### 6.3 The write pointer auto-increments by +1

Opcode `0x74` (LFO WAVEFORM) is the proof by construction: the handler emits one
address word and then **three data-only packets with no address word**, 36 times,
filling D-RAM `0x1D..0x40` from a ROM wavetable. Four values reach four cells from
one address ⇒ `|step| = 1`. Direction is fixed by a clobber test (26 algorithms
carry an op-`0x74` record; under `−1` two of them would be clobbered by their own
canned writes to cell `0x1B`; under `+1`, none) and corroborated by waveform
smoothness. (`dsp/analysis/host-side.md` §4.)

### 6.4 What is named, and what that means

The host's own UI tables give **64 distinct parameter names on 31+ cells**, per
space and per unit — e.g. unit-1 C-RAM cell `0x97` = REVERB TIME, cell `0x9E` =
HIGH DAMP GAIN, cell `0xAC` = ER.LEVEL; unit-1 descriptor cell `0x00` = PRE
DELAY; unit-0 D-RAM cell `0x06` = VOLUME (×37), `0x1D` = the 36-cell LFO
waveform block.

⚠ **This is a CELL map, not a REGISTER map.** These are addresses inside the
chip's data/coefficient RAMs that the host pokes, learned from the host's own
parameter tables. The chip's own control registers — clock, sample rate, I/O
routing, delay-DRAM configuration, whatever the boot-time `0x04`/`0x09`/`0x0C`
commands touch — are **entirely unmapped**. A device model can honour the cell
map and still not know how to start the chip.

---

## 7. EFFECT CHANGE vs PARAMETER TWEAK

Two different paths, and the difference matters for a device:

**Effect change** — `EFF_Change_WithDebug(slot, effect)` reads two of four
parallel 100-entry pointer arrays (`0x01ED7C` algorithm streams, `0x01EF0C`
coefficient streams), and uploads **algorithm first, then coefficients**, each as
a full bytecode stream through `DSP_BytecodeInterpreter_Init`. On the WSA1R the
same shape appears as a `PoolDir_Records[n]` entry whose fields +0/+4 are the
coefficient streams and +8/+12 the parameter records.

**Parameter tweak** — `DSP_WriteParameter` → `DSP_ParameterWriteEngine` walks the
**value** record table positionally (record *n* = parameter set *n*) and hands
each body to `DSP_PerParameterTranslator`, which repeats
`{ id, field-index, curve operands… }` until the `0x7A` terminator. The
field-index selects a cell number out of the **descriptor** record with the same
id. So: *descriptor record = id + cell-number list; value record = id +
curve/interp operand stream.* Each id dispatches to an evaluator that computes a
value and a writer that names the address space (§6.2). No microcode moves.

Settled evaluator semantics (`dsp/tools/kn5000_dsp_params.py`):

```
  op61  linear eval -> writer 0x0387E6          op68  ms * 44100/1000 -> DRAM words
  op62  CURVE_D volume law, 1.00 dB per UI step op69  value/180 -> degrees (PHASE/PAN)
  op63  A/B/C curve select -> cell 06 tail level op6D desc+8 pair (COMP attack/release)
  op21  lerp(0x000000..0x666666) = 0..0.8       op70  PEQ biquad coeff + state block
  op72  COMP THRESHOLD/RATIO cells              op74  the 36-cell LFO wavetable
```

UI range is 0..99 (lerp divisor 0x63); the four 100-entry curve tables live at
`0x012483` / `0x012613` / `0x0127A3` / `0x012B33`.

⚠ **A device model must reproduce a firmware behaviour that looks like a bug.**
Touching **DELAY R** adds a permanent +415 samples (+9.41 ms) in SINGLE DELAY and
+200 samples (+4.54 ms) in S.DELAY+VIBRATO, because two effect slots kept a stale
`BASE24` constant. It is measured, it is authored, and it is not ours to fix
(`second-dsp-and-ready.md` C1–C4).

⚠ **And twelve NAMED effects ship a program byte-identical to NO OPERATION** —
MODULATION DELAY, SLOW ATTACKER, PITCH SHIFTER, STRING, CEL, CELM, PEDAL WAH,
DS_D, OVER_D and others; 42 of the 100 effect numbers share one record trio by
pointer identity. Those effects are stubs **in the firmware**. A device that
implements them would be *less* faithful, not more.

---

## 8. HOW MUCH RAM AND DELAY THE FIRMWARE ASSUMES

What the firmware's own behaviour bounds:

| resource | what the firmware implies | how firm |
|---|---|---|
| instruction RAM | **384 words** — streams loading past it are flagged; the six addresses used are 0 / 60 / 64 / 71 / 84 / 200 | the 384 is a bound this tree has used since the corpus was carved; the six addresses are MEASURED |
| instruction word | **36 bits in a 5-byte container**, right-aligned big-endian | MEASURED (op-3 group size, both products) |
| coefficient word | **24 bits, signed Q0.23** | MEASURED (op-2 group size, command `0x02`) |
| resident program | one shared kernel (83 words) + two effect-unit bodies co-resident | MEASURED |
| effect units on this chip | **2** (I-RAM 84 and 200); KN5000 slots 2–4 go to IC310 | MEASURED via the chip table `0x0001ED6D` |
| coefficient/data cells named | 31 C-RAM cells `0x00..0x19`, `0x25`, `0x90`; D-RAM cells to `0x5F`; descriptor cells to `0x2D` | MEASURED from the host tables |
| external delay memory | IC309, an **M5M44260AJ**, **16-bit** wide; delay lengths computed as `ms × 44100/1000` and stored as DRAM word counts | part from the schematic; the conversion is MEASURED (op68) |
| delay address space | **one 64 K word space split at `0x8000`** — effect unit 0 owns `[0, 0x7FFF]`, unit 1 `[0x8000, 0xFFFF]` | MEASURED over 486 + 384 descriptor cells (`dsp/analysis/adjudication-round4.md` item I); permutation null 0/4000 |
| delay taps | **NOT ESTABLISHED.** The reverb tank is solved as two all-pass diffuser ladders of **five and four** stages with 33 coefficients, and 11 algorithms use multi-tap delay lines whose *lengths* are read, but the number of taps the chip provides is nowhere declared | the 5+4 is MEASURED for that algorithm; the chip's capacity is not |
| sample rate / clock | 44,100 Hz; 25 MHz crystal | schematic + the op68 constant |

⚠ Every row is *what the firmware assumes or uses*, which is a **lower bound** on
the chip in each case and never an upper one. "The firmware never loads past word
384" does not establish that the I-RAM is 384 words.

---

## 9. WHAT IS MISSING, NAMED

A precise negative, per the brief. Each item says what would close it.

1. **The instruction set.** 7 word forms carry a real mnemonic; on the frame
   floor that is 29 of 216 words (13.4 %), 9.0 % by vocabulary over the corpus.
   35 more words have a determined *operation* but no operand encoding.
   **Closed by:** a µPD6383GF datasheet or programming manual, or an emulator-side
   behavioural experiment against a chip. Firmware alone has plateaued —
   `dsp/analysis/STRATEGIC-REVIEW-2026-07-31.md` puts the decode ceiling at
   ~93.3 % and says the remaining problem is allocation, not method.

2. **The chip's control registers.** Nothing is known about clock setup, sample
   rate, I/O routing or delay-DRAM configuration. The three boot-time commands
   `0x04`, `0x09` and `0x0C` almost certainly carry it, and they are seen **twice,
   once and once** in the whole KN5000 live capture with payloads
   `FB DA 3F A0 1A`, `00 3C` and `00 55 55`. One capture, three samples, zero
   variation ⇒ nothing can be inferred.
   **Closed by:** a datasheet, or a capture with the settings varied.

3. **What answers READY on the WSA1R, and how fast.** The pin is read, the
   protocol is not. A device that raises P9.3 "because it consumed a byte" would
   unblock ~70 s of emulated boot, but the *timing* — whether ready falls at all,
   and for how long — is unmeasured, and a device that never lowers it is a
   constant with extra steps.
   **Closed by:** a logic-probe capture of P9.3 during a real WSA1R boot; or,
   cheaply, by accepting an always-ready model *and saying so in the code*.

4. **The part number, on the WSA1R.** No ROM byte in any WSA1R image names a
   chip. "Three destinations and three µPD6383GF DSPs in the parts list" is a
   consistency, not proof.
   **Closed by:** a photograph of the WSA1R board, or its service manual.

5. **The op-2 container difference.** Reconciled at the wire level (§3.1) but not
   *explained*: why does one product's authoring tool emit a relocation tag on
   coefficient groups and the other's not? Two format revisions is the obvious
   guess and is a guess.
   **Closed by:** a third product's firmware, or a dated toolchain artefact.

6. **The WSA1R's parameter-record walker.** §5 establishes the *format* of the
   pool's second payload convention; the routine that reads it has still not been
   pointed at in `prom_c`.
   **Closed by:** a targeted xref pass for readers of `PoolDir_Records` fields
   +8/+12 — a bounded, firmware-only job that this lane did not have budget for.

7. **Delay-line capacity and tap count.** §8.
   **Closed by:** a datasheet, or the IC309 address-generator behaviour observed
   on hardware.

8. **Whether either machine's DSP is on the main mix.** Established for the
   KN5000 (IC311 is a send/return insert on IC303; **IC310** is the chip on the
   main output path, and MAME has no device for *that* either). Unknown for the
   WSA1R — `WSA1-EMULATION-DISASM-GAPS.md` says so explicitly.
   **Closed by:** the WSA1R service manual.

### What a device could honestly be written for *today*

A `upd6383gf_device` that: latches a byte on a write strobe; distinguishes
command from data on the qualifier line; implements commands `0x01` (set write
pointer), `0x02` (24-bit coefficient port), `0x03` (end transaction), accepting
and logging `0x04`/`0x09`/`0x0C`/`0x0F`; auto-increments the write pointer by +1;
maintains a 384-word instruction RAM, a coefficient RAM and a data RAM addressed
by the 7-bit destination tag; and asserts READY on the WSA1R side because it
consumed a byte. **It would produce no audio, and it should say so in its own
header.** Its value is that it makes the WSA1R boot in seconds instead of 70,
makes the traffic inspectable, and gives the instruction-set work a live target
that today has to be simulated in Python.

⚠ **Do not fold IC310 into it.** Different chip, different vendor, different
transport, different word widths — and it is the one on the KN5000's main output.

---

## 10. ★ THE ONE FINDING THAT MOST CHANGES THE PICTURE

Measured with `… shared`: how much DSP payload the two products carry
**verbatim**, as the fraction of L-byte windows of one corpus occurring anywhere
in the other image. The null is the same bytes randomly **permuted** — it keeps
the byte histogram and destroys the structure.

```
  DIRECTION 1: the WSA1R prom_c stream pool (61,154 B) in the KN5000 Sub CPU ROM

        L   windows     found       %   null
       16     61139     17165   28.1%      0
       32     61123     10739   17.6%      0
       64     61091      4501    7.4%      0
      128     61027       795    1.3%      0

  DIRECTION 2: each KN5000 DSP corpus in WSA1R prom_c, window length 32

           KN5000 corpus   bytes  windows   found       %   null
   ALGO  (microprograms)   16771    16740    4828   28.8%      0
    COEF  (coefficients)   15965    15934    2624   16.5%      0
            PARAM VALUES    4715     4684     558   11.9%      0
       PARAM DESCRIPTORS    1387     1356       0    0.0%      0
```

★ **The ALGO row is the load-bearing one.** ALGO holds the DSP *microprograms* —
the op-3 records carrying 36-bit instruction words to named I-RAM addresses.
**28.8 % of the KN5000's microprogram corpus occurs verbatim in the WSA1R's
prom_c, against a null of zero.** The two machines execute the same microcode:
the same instruction encoding, the same I-RAM addressing, the same core.

This replaces "four byte-identical streams" as the strongest cross-product
statement, and it is the reason the KN5000's decoded microcode work is
transferable. The `runs` section of the probe lists 14 streams with a verbatim
prefix ≥ 32 B, longest 164 — but it also records, prominently, that the obvious
per-row control **fails**: the two images share so much material that a random
pool window is often found too. `shared` is the instrument whose null holds;
`runs` is an index.

⚠ **It is still not a part number.** Shared microcode identifies a shared core.
It cannot distinguish a µPD6383GF from a second source or another member of the
same family, and no ROM byte in either machine names a chip.

⚠ **And the PARAM DESCRIPTORS zero is weak.** 1,356 windows scoring 0 is a small
sample, not a demonstrated absence.

---

## 11. FILES

| path | what |
|---|---|
| `notes/sound/dsp_protocol_cross_product.py` | every number in this note; `--selftest` |
| `dsp/analysis/host-side.md` | the KN5000 transport, the command census, the LFO block |
| `dsp/analysis/register-space.md` | the 5-byte datum, the tags, the auto-increment |
| `dsp/analysis/second-dsp-and-ready.md` | the READY line, IC310, the chip partition |
| `dsp/README.md` | the corpus, the chip, the decode ceiling |
| `v142/subcpu/subcpu_data_tables.s` | the bytecode and record-table grammars, in situ |
| `v142/subcpu/kn5000_subprogram_v142.s` | `DSP_Bytecode_Op0*` handlers, decoded |
| `wsa1/prom_c/p7/p7_module.s` | `P7Byte_Send*`, `P7Stream_Run`, the arms |
| `wsa1/notes/FINDINGS-prom_c-p7-byte-stream-pool.md` | the WSA1R pool and its port |
| `wsa1/notes/FINDINGS-prom_c-p7-is-dsp-effects.md` | program = effect number |
| `wsa1/notes/WSA1-EMULATION-DISASM-GAPS.md` | gap G, and what it still asks |
