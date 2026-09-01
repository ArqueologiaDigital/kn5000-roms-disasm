# CPU 2's two 64-channel parameter devices, 0x0010C000 and 0x00104000

> **Renamed in round 4.**  This file was titled *"The WSA1's tone generator"* and every label
> it describes carried the prefix `TG_` / `TG2_`.  Both are gone; see **§0** for why and for
> the tone-generator argument written out in full.  The prefixes are now `Dev10C_` and
> `Dev104_`.  No structural claim in this note changed — only the names.

Scope: `prom_c` (IC28, CPU 2), the devices at **0x0010C000** and **0x00104000**, and the
48 driver routines converted for them in `prom_c/wsa1_prom_c.s`:

| range | bytes | what |
|---|---:|---|
| 0xFACE67-0xFAD141 | 731 | the first accessor bank, 17 routines |
| 0xFB7715-0xFB7B62 | 1,102 | the 0x00104000 driver and 0x0010C000's GLOBAL registers, 9 routines |
| 0xFB7B63-0xFB828D | 1,835 | the second accessor bank plus `Dev10C_ResetAllChannels`, 22 routines |

Everything below is reproducible from `notes/prom_c_tg_regmap.py`
(`--selftest`, `--callers`, `--dups`, `--slots`, `--dev104`, `--unmatched`) and from
`notes/prom_c_xrefs.py`.  The gate
(`python3 scripts/analysis/assert_byte_identical.py`) certifies the source.

> ★★ **AMENDED 2026-08-25 (round 7): FOUR REGISTERS NOW HAVE A MEANING.**  This note's
> "not one register's meaning" survives for seventeen of the twenty-two per-channel registers and
> is **retracted for four**: `chan + 0x0400` is the PITCH in units of 1/256 semitone,
> `chan + 0x0080` is the OUTPUT LEVEL (bits 11..0 logarithmic, 256 counts per octave; bits 14..12
> an unnamed 3-bit field; bit 15 the gate this note's §5 describes), `chan + 0x0040` carries the
> first word of the key-zone record the played note selects, and `chan + 0x0800` / `chan + 0x0840`
> have `0xFF80` / `0xFF00` as their quiescent pair.  Full argument and the assertions:
> `notes/FINDINGS-prom_c-dev10c-register-meanings.md`, `notes/prom_c_dev10c_meaning_checks.py`.
>
> ⚠ **The `Dev10C_` prefix is deliberately NOT changed back to `TG_`.**  §0 sets the condition for
> that as *"the day a converted routine turns a note number into a CHANNEL argument"* — i.e.
> channel ALLOCATION — and round 7 did not show that.  What it showed is that a converted routine
> turns a note number into a per-channel register VALUE, which is a different statement.  The
> allocation step is still not in evidence in this image, so the prefix still states the address.

> **What this note does NOT establish.**  Not one register's *meaning*.  No part number, no
> "this is the pitch register" — **and, since round 4, not the device's ROLE either.**  What
> follows is the register file's shape, its channel count, its reset values and which struct
> word feeds which register — all of it read off instructions.  Every name in the source
> encodes only that.

---

## 0. ⚠ Why these are not called `TG_` any more

Rounds 2 and 3 named 66 labels `TG_*` / `TG2_*` and titled this file "The WSA1's tone
generator".  The audit of round 1 flagged it, and the audit is right: the prefix asserted a
device role that no line of this note argued for, while
`notes/FINDINGS-memory-map.md` described the same two devices as
"16-bit address/data register pair" and never said tone generator.  Two documents about the
same silicon, disagreeing, with the stronger claim carried by the thing a reader greps.

**The inference, stated in full so nothing is lost.**  All of it is real, and none of it is
proof:

| # | observation | where it is measured |
|---|---|---|
| 1 | exactly **64** channels, from a literal loop counter (`ldb d,0x40`), not from an address stride | §3 |
| 2 | each channel has ~22 parameter registers written from one 68-byte staging struct | §2, §4 |
| 3 | three parallel per-channel "slots", each a gate register pulsed **bit 15 set → clear** with a companion value register loaded in between — the shape of a trigger | §5 |
| 4 | it is CPU 2's **busiest** device by a factor of five (102 pointer loads vs 20 for the next) | §1 |
| 5 | the same CPU owns the 61-key keybed scanner and the touch→velocity curve | `notes/FINDINGS-prom_c-keyboard-and-touch.md` |
| 6 | the machine is a synthesiser, and CPU 2's other devices are all accounted for otherwise: link port, key scanner, expansion board, flash, and 0x00E00000 (whose driver is byte-shaped like CPU 1's 0x007F0000, which the KN5000 sibling calls the DSP) | `notes/FINDINGS-memory-map.md` |

**What is missing, and it is the thing that would settle it.**  No instruction in prom_c
connects a NOTE to a CHANNEL.  The one path this image does show from a key leads the other
way: `KeyScan_ReadEvent` → `ToneGen_VelocityFromTouch` → a MIDI-encoded note-on **handed to
the inter-processor link**, not to either of these devices (see the block comment above
`Link_Ch0_AppendToRing` in `prom_c/wsa1_prom_c.s`).  Whatever allocates a channel is
therefore either on CPU 1 or in the still-unconverted layer at 0xFA83xx / 0xFADCxx that fills
the staging struct.

**So the name states the address.**  `Dev10C_` and `Dev104_` follow the convention this tree
already used for `Dev108000_Preload_80toBF` — which is exactly how that label read until the
key-scan role WAS established, at which point the surrounding header said so and the memory
map got an evidence column.  Do the same here: restore a role-bearing prefix on the day a
converted routine turns a note number into a channel argument, and not before.

---

## 1. Two devices, one interface

`0x0010C000` is CPU 2's busiest device.  prom_c loads that literal into a pointer register
**102 times**, against 20 for 0x00E00000, 12 raw hits for 0x00104000 (**9** of which are real
32-bit immediate loads; the other 3 are data) and 3 for 0x00108000.  All 102 are the same
instruction shape `ld <X..>,0x0010C000` — 51 × XIX, 41 × XBC, 10 × XWA — so the census has no
false positives to throw away.

**The port's shape comes from one 25-byte routine that does nothing else.**
`Dev10C_WriteReg` at `0xFACE89`:

```
    ld bc,(xiz+8)    / ld (xix),bc         ; +0x00 <- argument 0
    ld bc,(xiz+10)   / ld (xix+2),bc       ; +0x02 <- argument 1
```

No arithmetic, no mask, no shift between the arguments and the port.  There is no reading of
that in which +0x00 is anything but a 16-bit register selector and +0x02 anything but that
register's 16-bit data.

**And +0x04 is the read port.**  `0xFA68FC` performs the identical select through the identical
pointer and then reads:

```
    ld (xix),bc                            ; select
    ld xbc,xix / inc 4,xbc / ld hl,(xbc)   ; 0xFA6903 -- read from +0x04
```

So, entirely from prom_c: **{+0x00 select, +0x02 write data, +0x04 read data}, all 16-bit.**
Data writes are followed by five `nop`s at several sites — the bus-timing padding
`notes/FINDINGS-memory-map.md` already recorded.

`0x00104000` has the **same** shape (§4).

---

## 2. The register number is `parameter_block * 0x40 + channel`

`notes/prom_c_tg_regmap.py` extracts the (constant, struct field) pair from each site
mechanically — it parses unidasm's rendering, bounds the window to one routine, and lists the
sites it could NOT match instead of dropping them (75 of 102 matched; `--unmatched` prints the
27 whose register number lives in a register the matcher cannot follow).

Over the matched set, **19 distinct constants, every one a multiple of 0x40**:

```
0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180 0x01C0
0x0400 0x0440 0x0480 0x04C0 0x0540 0x0580 0x05C0 0x0600 0x0640
0x0800 0x0840 0x0880
```

as `K/0x40`: 1 2 3 4 5 6 7 · 16 17 18 19 21 22 23 24 25 · 32 33 34.  `K = 0` occurs too.

> **★ UPDATE 2026-08-25 — there are EIGHT more, and they come from one routine.**
> `Dev10C_WriteAllChanRegs` at `0xFB713A` (now converted) writes twenty-two registers of one
> channel in one unrolled run and uses `0x0500 0x08C0 0x0900 0x0940 0x0980 0x09C0 0x0A00
> 0x0A40` as well.  As `K/0x40` that is 20 · 35 36 37 38 39 40 41.  The highest register
> number the device is known to accept is therefore `0x0A40 + 0x3F = 0x0A7F`, not `0x08BF`.
> The whole map, and the three consecutive runs the struct fields fall into, is derived by
> `python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --groups`; the source header at
> `Dev10C_WriteAllChanRegs` carries the table.  This is the answer to the first bullet of §10.

⚠ "parameter block × 0x40 + channel" is an **observation about the constants**, not something
any instruction says.  What the instructions say is `chan + K`.  §3 is what turns the
observation into an argument.

---

## 3. ★ The channel count is 64, from a loop counter — and `chan >= 0x40` does not mean a 65th channel

**64 is not read off an address stride.**  `Dev10C_ResetAllChannels` (0xFB80E1) contains

```
    ld hl,0x0840 / ldw (xiz-2),0x0800 / ldb d,0x40      ; 0xFB810E
  loop:
    ld (xix),hl        / ldw (xbc),0xFF00               ; register 0x0840 + i
    <5 nops>
    ld bc,(xiz-2) / ld (xix),bc / ldw (xbc),0xFF80      ; register 0x0800 + i
    inc 1,hl / inc 1,bc / dec 1,d / cps d,0 / jr nz,loop
```

`ldb d,0x40` is a literal count of **64**, and each pass advances both register numbers by
one.  Blocks 0x20 and 0x21 therefore hold exactly 0x40 registers each.  A second loop in the
same routine runs `cp hl,0x0040` over the channels.

**Six routines branch on `cp hl,0x0040` and pick a different block AND a different struct
field on each arm.**  That looks like two kinds of channel.  It is not.  The high arm's base is
exactly 0x40 **below** the base an unconditional routine uses for the same struct field, and
the channel argument already carries that 0x40:

```
0x0580 + (0x40 + k) = 0x05C0 + k        0x0600 + (0x40 + k) = 0x0640 + k
```

which are precisely the registers `Dev10C_Slot3_...` writes for channel k, with precisely slot 3's
struct fields.  **Every port write on every arm of all six routines satisfies this** —

```
python3 notes/prom_c_tg_regmap.py --slots      # FAILURES: 0, exit 0
```

— and the reference set that check tests against is built by symbolically walking the 32
family routines that have **no** bound check, so a failure would be printed rather than
absorbed.

⚠ So a "channel" argument of 0x40..0x7F selects **slot 3 of physical channel 0..0x3F**.
Anything that reads the 0x40 bound as a channel count is reading it wrong.

> ⚠ **A retraction inside this note's own tooling.**  The first version of `--slots` collected
> the `add r,imm` constants and the `ld r,(struct+d)` fetches into two lists and zipped them.
> For any routine that writes more than one register the zip is wrong: in
> `Dev10C_Slot1or3_WriteGateAndValue` the encounter order is add 0x0540, fetch 0x3A, fetch 0x3A,
> add 0x01C0, fetch 0x38, so it produced the pair `(0x01C0, 0x3A)` — which the ROM never
> writes.  **The check still reported 0 failures**, because the wrong pairs happened to be in
> the reference set as well.  It was replaced by a symbolic walk that pairs a SELECT with the
> DATA WRITE that follows it.  The comment in `_walk` carries this warning; the numbers in
> this note all come from the fixed version.

---

## 4. ★ 0x00104000: the whole per-channel map, from one unrolled routine

`Dev104_WriteAllChanRegs` at `0xFB77EF` writes **nineteen** registers of one channel in one run:

```
    register (chan + k*0x40) = struct word 2*k      for k = 1 .. 0x12
    register (chan + 0)      = struct word 0        written LAST
```

The relation `field == 2 * (base / 0x40)` holds for all nineteen, checked including the last
pair (0x0480 ← word 0x24):

```
python3 notes/prom_c_tg_regmap.py --dev104     # FAILURES: 0, exit 0
```

So 0x00104000 is an address/data pair of the same kind, with the same
`block * 0x40 + channel` numbering.  Its nine 32-bit-immediate load sites are all inside
0xFB7715-0xFB7B62 or inside `Dev10C_ResetAllChannels`.

⚠ Block 0 being written **last**, after all the others, is the shape of a "commit" register.
Nothing here establishes that.

> ⚠ **And it is not a rule of the device.** Two of the small accessors in the same bank —
> `Dev104_SetChanRegs_01C0_0200_0240` (0xFB796E) and `Dev104_SetChanRegs_0140_to_0240`
> (0xFB79D0) — write block 0 **FIRST**, before the registers they are named for. Round 4
> measured all three with
> `python3 notes/prom_c_tg_chanmap.py <addr> <len> --dev 0x00104000 --pairs`, which reports
> execution order: 0xFB795F is `Dev104_WriteAllChanRegs`'s **last** write, while 0xFB7983 and
> 0xFB79E5 are the **first** writes of their routines. Both of those headers previously claimed
> the opposite and are corrected in the source. So "block 0 is a commit" survives for the
> unrolled writer and is **contradicted** for the two small ones; treat the position as a
> property of each routine, not of the register.

---

## 5. ★ Bit 15 of a gate register is written as a 1-then-0 pulse

Six routines in the second bank write a register with bit 15 set and then write the **same**
register again with bit 15 cleared (`res 15`), loading a companion register in between:

```
Dev10C_Slot2_WriteGateAndValue (0xFB7C27)
    if (staging->0x3C & 0x8000)  register (chan+0x0580) = staging->0x3C
    register (chan+0x0600) = staging->0x40
    register (chan+0x0580) = staging->0x3C with bit 15 CLEARED
```

That is the only place in either bank where one routine writes one register twice.

The pairs come in **three parallel slots**:

| slot | gate register | gate field | value register | value field |
|---|---|---|---|---|
| 1 | chan+0x0540 | 0x3A | chan+**0x01C0** | 0x38 |
| 2 | chan+0x0580 | 0x3C | chan+0x0600 | 0x40 |
| 3 | chan+0x05C0 | 0x3E | chan+0x0640 | 0x42 |

⚠ The gates are a clean 0x40 ladder.  The **value** registers are not — slot 1's is in block 7
while slots 2 and 3 are in blocks 0x18 and 0x19.  Stated as read.

Three more routines write the constant **0x8100** into a gate register (bit 15 set, bit 8 set)
with no struct involved at all.

⚠ What the pulse *does* is not established.  "Trigger", "latch" and "key-on" all fit the shape
and nothing here distinguishes them.

The strongest evidence that the three slots are three parallel per-channel objects rather than
three unrelated parameters is that `Dev10C_ResetAllChannels` calls
`Dev10C_Slot1_WriteGateAndValue`, `Dev10C_Slot2_WriteGateAndValue` and `Dev10C_Slot3_WriteGateAndValue`
**in order, for every one of the 64 channels**.

---

## 6. ★ The reset image is in this ROM, and its sizes check out

`Dev10C_ResetAllChannels` (0xFB80E1) is the power-on sweep.  Reading it top to bottom:

| step | what | evidence |
|---|---|---|
| 1 | `Dev10C_WriteGlobalRegs(ROM 0xFE12B5)` | `lda_24 xbc,0xFE12B5` / `push xbc` / `calr 0xFB7715` |
| 2 | 0x00104000 register **0x0800** = the word at ROM **0xFE1313** | `ld xix,0x00104000` / `ldw (xix),0x0800` / `ldw_da bc,0xFE1313` / `ld (xix+2),bc` |
| 3 | for i = 0..0x3F: register (0x0840+i) = **0xFF00**, register (0x0800+i) = **0xFF80** | the `ldb d,0x40` loop of §3 |
| 4 | `0x00D8DB <- ROM 0xFE12CF, 0x44 = 68 bytes`; `0x00D91F <- ROM 0xFE133B, 0x26 = 38 bytes` | two calls to `MemCopyWords` (0xF9A038), whose argument order its own converted header fixes: (XSP+8) source, (XSP+12) dest, (XSP+16) count |
| 5 | for chan = 0..0x3F: 0xFB713A, 0xFB77EF, `Dev10C_WriteReg`, editing a bitfield at 0x00D91F between calls | `cp hl,0x0040` / `jr c,...` |
| 6 | for chan = 0..0x3F: registers (0x0840+i)=0xFF00, (0x0800+i)=0xFF80, (0x00C0+i)=0x0000, (0x0000+i)=0x7E00, then slots 1, 2, 3 and 0xFB7A58 | the second `cp hl,0x0040` loop |

**Two sizes fall out and agree with things established elsewhere.**

* `Dev10C_WriteGlobalRegs` writes 13 registers from 13 consecutive words = **26 = 0x1A bytes**, and
  `0xFE12CF - 0xFE12B5 = 0x1A` exactly.  The field count in one routine and the spacing of two
  ROM addresses in another give the same answer.
* The staging struct copied to 0x00D8DB is **68 = 0x44 bytes**, which is exactly the span of
  the staging fields the accessors read (0x08 … a word at 0x42).  The same 0x44 is the record
  stride of the per-channel array at RAM 0x003BCF (`ld C,0x44 / mul BC,H` at `0xFADCD9`, with
  H bounded below 0x40 by `cp H,0x40`).

⚠ `0xFB7715`'s first argument aside, **0xFB713A, 0xFB77EF's callers, 0xFB7A58's callers and
0xFB7A58 itself** are converted, but `0xFB713A` and `0xFB7A58`'s siblings `0xFB77EF`/`0xFB7A58`
in steps 5 and 6 sit next to two routines that are **not** converted (`0xFB713A`, `0xFB7A58`
is; `0xFB713A` and `0xFB7A58`'s companion `0xFB7A58` — see the source header for the exact
list).  What steps 1 and 5 *compute* is therefore unknown.  The reset VALUES above are what the
ROM writes; what they mean is not established.

---

## 7. 0x0010C000's thirteen GLOBAL registers

`Dev10C_WriteGlobalRegs` (0xFB7715) takes **no channel argument** — every register number in it is
an immediate — and writes

```
0x0200 0x0201 0x0202 0x0203 0x0204 0x0205   <- arg->0x00 .. 0x0A
0x0C00 0x0C01 0x0C02 0x0C03 0x0C04 0x0C05   <- arg->0x0C .. 0x16
0x0E00                                      <- arg->0x18
```

That "no channel argument" is what makes them global, and it is read off the instructions.
It agrees with the other bank: `Dev10C_WriteReg_0201` at 0xFAD12A writes register **0x0201** alone,
with a value its only caller builds as `and bc,0x0F9F / or bc,ix / or bc,hl` — a packed
control field.

---

## 8. How the drivers are called, and the staging structs

23 of the 25 call sites of the first bank set the arguments up identically:

```
lda XBC,0x00D75E / push XBC / <compute chan> / push WA / calr <accessor>
```

(`--callers`; the two exceptions are the two routines that take no struct).  0x00D75E is work
DRAM, outside the boot RAM image at 0x00E2DF (`notes/FINDINGS-prom_c-ram-image.md`), and
prom_c takes its address **74 times**, every one the identical instruction
(`notes/prom_c_xrefs.py 0x00D75E --no-window --classify`).

⚠ **There are at least two staging structs of the same 68-byte shape**: the first bank's
callers pass 0x00D75E, while `Dev10C_ResetAllChannels` initialises **0x00D8DB**.

The fields the accessors read are
`0x08 0x0A 0x0C 0x0E 0x10 0x12 0x14 0x1A 0x1C 0x2C 0x2E 0x38 0x3A 0x3C 0x3E 0x40 0x42`.

The path into the drivers, from the one caller traced (`0xFADCC3`):

```
per-channel record array at RAM 0x003BCF, stride 0x44, index < 0x40
        -> 0xFA8347 / 0xFA83CC  (not converted)
        -> staging struct at 0x00D75E
        -> the accessor bank -> the device
```

---

## 9. ⚠ The driver exists TWICE in prom_c

13 of the first bank's 17 routines occur a second time, byte for byte, between 0xFB7016 and
0xFB7FCE, and two routines of the first bank (0xFACEA2 and 0xFACF78) are byte-identical to
**each other**.  `python3 notes/prom_c_tg_regmap.py --dups` prints the address of every copy.

The second driver is the larger of the two: it adds the register blocks 0x0040, 0x0080, 0x0480,
0x05C0 and 0x0640, all the bit-15 gate handling, and `Dev10C_ResetAllChannels`.

The duplication is not confined to code.  The 68-byte reset image at ROM 0xFE12CF is byte-
identical to the 68 bytes at **0xFE12CF + 0xC2B**, inside the near-duplicate data region this
project already knew about — and *nothing references the second copy by literal*.  That region
also carries two copies of a pointer table whose entries differ by exactly the same 0xC2B
(0xFE11F8/0xFE1207/0xFE1215 against 0xFE1E23/0xFE1E32/0xFE1E40), i.e. a duplicated block with
its internal pointers relocated.  ~~**Left for a later pass**~~ **DONE 2026-08-25.**

> The data duplication is now fully bounded: copy A is `0xFE0A6D-0xFE15E0` (2,932 bytes) and
> copy B is `0xFE1698-0xFE21E5` (2,894 bytes); the alignment uses **two** deltas, 0xC2B and
> 0xC05, and they differ by exactly the 38-byte object at `0xFE133B` that copy B does not
> have.  Forty of the forty-one differing bytes are relocated pointers; the forty-first is a
> single 0x0010C000 global parameter.  See
> `notes/FINDINGS-prom_c-duplicate-initialiser.md` and `notes/prom_c_dup_image.py`.
> ⚠ That correction matters for this section's own wording: "two copies of a pointer table"
> is one table of **sixteen** 6-byte records, and the three addresses quoted above are three
> of its sixteen pointers, not three separate tables.

---

## 10. What the next pass needs

* ~~`0xFA8347`, `0xFA83CC`, `0xFB713A`, `0xFB77EF`'s callers and `0xFB7A58`'s callers are
  what FILL the staging struct.  Until one of them is converted, every register's meaning
  stays unknown — the drivers only move words.~~
  **DONE 2026-08-25 (wave 5).**  All of them are converted, and the fillers are now
  ENUMERATED PER REGISTER: `python3 notes/prom_c_dev10c_field_sources.py` prints, for each
  of the 22 staged words and therefore for each 0x0010C000 per-channel register, every
  routine that writes it — 70 write sites over 21 of the 22 words, in both the absolute
  and the based addressing forms.  Word 0 has no writer and `Dev10C_WriteAllChanRegs`
  reads no word 0 either, which is two independent readings agreeing.
  ★ The twin device is different in kind: `0x00D7A2`, the 0x00104000 struct, is filled by
  ONE routine, `sub_FC4DBD`, which writes 19 offsets 0x00..0x24 through its pointer
  argument — exactly the span `Dev104_WriteAllChanRegs` reads — out of a "current object"
  pointer block at RAM 0x00E082-0x00E08D that four small routines set from the part record
  (RAM 0x005D23, stride 187) and the voice record (RAM 0x003BCF, stride 0x44).
  Full account, including the first register value written out as a formula:
  **`notes/FINDINGS-prom_c-dev10c-producers.md`**.
  ⚠ Half-closed no longer: **four registers were named in round 7** — `0x0400` pitch,
  `0x0080` output level, `0x0040` the key-zone word, and `0x0800`/`0x0840`'s quiescent pair.
  Seventeen still have no meaning.  `notes/FINDINGS-prom_c-dev10c-register-meanings.md`.
* ~~`0xFA68FC` is the only READ of 0x0010C000 located so far.~~  **CORRECTED
  2026-09-01: there are TWO, and a census that follows base registers finds both
  independently** (`python3 notes/sound/wsa1_sound_boundary.py --stream 0x10C000`,
  which reports `+0x04` as 2 reads and 0 writes across 2 routines).
  * `Dev10C_PollBankAndRetire` `0xFA68FC` — selects at 0xFA6901, reads `+0x04` at
    0xFA690A.  Its register number is a byte from 0x0087CF, multiplied by 2
    afterwards, so what it reads back would name at least one register.
  * `Dev10C_ReadChanReg_0100` `0xFC7E57` — named in round 7 and described in
    `prom_c/field_accessors.s`, which already called it *"the SECOND read site in
    the whole image"*; this line was simply never updated.  `add HL,0x0100` forms
    the selector and `ld BC,(XIX+0x04)` at 0xFC7E6F reads.  So **register
    `chan + 0x0100` is READABLE**, which the sibling map calls TVF cutoff.
  Full account: `notes/FINDINGS-sound-subsystem-boundary.md` §4.4.
* ~~The five blocks the first bank never touches (0x0040, 0x0080, 0x0480, 0x05C0, 0x0640) and
  the unmatched 27 sites in `--unmatched` are the remaining 0x0010C000 surface.~~
  **PARTLY DONE 2026-08-25.** Most of the 27 unmatched sites are inside
  `Dev10C_WriteAllChanRegs` (0xFB713A), which is not an accessor of the fixed shape `--unmatched`
  looks for; `notes/prom_c_tg_chanmap.py` walks it instead and recovers all 23 of its port
  writes, including blocks 0x0040 and 0x0080.  0x05C0 and 0x0640 are still only reached
  through the slot-3 arms.
* ~~`0x00108000`'s three sites (0xF9914D, 0xF99776, 0xF998C6) are still undescribed~~
  **DONE 2026-08-25 for two of the three.** 0x00108000 is the **KEY-SCAN PORT**: +2 is a
  status word whose bit 0 says an event is waiting, and +0 delivers a 16-bit key event whose
  low byte is `bit 7 = note ON | key number` and whose high byte is the touch measurement.
  0xF99776 is inside `KeyScan_ReadEvent` and 0xF998C6 inside
  `KeyScan_InitKeyStateBitmap`, both converted.  0xF9914D is
  `Dev108000_Preload_80toBF`, which was already converted and is still the one site whose
  meaning is open.  See `notes/FINDINGS-prom_c-keyboard-and-touch.md`.
