# `RESO SCALE`, and the last link in the `0x0000` gate chain

Wave 23, 2026-09-04, lane `w23/reso-scale`.  Seventh companion in the L7A1429 set.
It closes the two items `FINDINGS-l7a1429-editor-pages.md` §6 left open:

| note | answers |
|---|---|
| `FINDINGS-prom_c-dev104-register-map.md` (w17) | what each of the nineteen registers is built from |
| `FINDINGS-l7a1429-write-sequencing.md` (w19) | when each is written |
| `FINDINGS-l7a1429-curve-tables.md` (w19) | what quantity each ROM curve produces |
| `FINDINGS-l7a1429-parameter-names.md` (w19) | what the machine calls each register |
| `HLE-GUIDE-l7a1429.md` (w19) | what kind of engine it adds up to |
| `FINDINGS-l7a1429-packer-routines.md` (w20) | which routine computes each value |
| `FINDINGS-l7a1429-gate-and-keyscaling.md` (w21) | what switches register `0x0300` on |
| `FINDINGS-l7a1429-editor-pages.md` (w21) | which editor page and caption each register belongs to |
| **this note** | **what `RESO SCALE` does**, and **how `GROUP` reaches register `0x0000` bits 6:4** |

Everything asserted here is re-derived from
`original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}` by one committed script:

```
cd <tree>/wsa1
python3 notes/w23_reso_scale_and_group_chain.py            # sections 1-7, printed
python3 notes/w23_reso_scale_and_group_chain.py --selftest # FAILURES: 0
python3 notes/w23_reso_scale_and_group_chain.py --census   # every census row
```

It opens the `.s` listings for exactly one thing — the set of instruction START
ADDRESSES and their canonical spellings, which the converters gate on a
byte-identical round trip — and for nothing else.  `notes/README-w23-reso-scale.md`
says per script what question it answers.

⚠ **Felipe has no access to the hardware** (it is in storage abroad, no date).
Nothing below proposes measuring the instrument; §2 says exactly where that costs
us the last step of an answer.

★ **No `.s` file is edited by this lane**, so neither source gate applies.
`python3 notes/l7a1429_crosscheck.py` was run and **PASSes**: nothing here changes
a register NAME or the count of fourteen named blocks.

---

## 0. THE ANSWER, IN ONE PARAGRAPH

**`RESO SCALE` is read in exactly two places in the whole of prom_c, and they are
registers `chan+0x0040` and `chan+0x0080` — the MAIN and SUB resonator TUNING
words.**  Bit 7 of `Q[+0x16]` (p22) and of `Q[+0x20]` (p32) selects which of two
pitch differences is added to that resonator's tuning: with the bit **clear** the
register carries `KEY SHIFT + DETUNE − zone_offset`; with it **set** it carries
`KEY SHIFT + DETUNE − zone_offset + (voice[+0x08] − voice[+0x06])`, and that extra
term is exactly the last stage of `Voice_ComputePitch` — the key-follow
compression around a pivot, plus the key zone's own sample tuning.  Adding it back
cancels it, so `ON` tunes the resonator from the **raw note** and `OFF` tunes it
from the **pitch the wave is actually played at**.  ⚠ The route
`FINDINGS-l7a1429-editor-pages.md` §6 proposed — "it reaches `R[+0x1A]`
(`index_bias_A`)" — is wrong twice over and is retracted in §4.  Separately, the
`GROUP` chain is **closed**: eight hops from `ToneMsg_Dispatch`'s write arm 4 to
the `and WA,0x0070` gate, every one an asserted instruction, and the pointer
identity that joins hop 3 to hop 6 is `Part_GetWaveSelectRecord`'s own staged arm.

---

## 1. TARGET 1 — THE READER, FOUND

### 1.1 Where the bit is read — PROVEN

`Dev104_PackStagingStruct` loads `Q` (the 43-byte wave-select record) **once**,
into its own frame slot `(XIZ-4)`:

```
   FC4DC4  ld   BC,(0x00E084)      P, the 42-byte sub-record
   FC4DCB  ld   XWA,(XBC+0x03)     Q = P[+0x03]
   FC4DCE  ld   (XIZ-4),XWA        ... spilled to the frame
```

★ That is the **base-spilled-to-a-frame** shape that has hidden producers from this
tree twice.  The census in §3 does not care, because it matches the
**displacement**, which no spill can hide.

The MAIN reader, on the way to staging word 1 = register `chan+0x0040`:

```
   FC4E25  ld   XBC,(XIZ-4)        Q
   FC4E28  ld   A,(XBC+0x16)       p22
   FC4E2B  and  A,0x80             <- RESO SCALE (MAIN)
   FC4E2E  jr   Z,0xFC4E66         clear -> the -R[+0x0C] arm
   FC4E30  ld   DE,(0x00E08A)      set   -> voice[+0x08]
   FC4E35  ld   WA,(0x00E08D)              voice[+0x0A]
   FC4E3A  sub  DE,WA              d1 = voice[+0x08] - voice[+0x0A]
   ...
   FC4E66  ld   BC,(0x00E086)      R, the 37-byte voice record
   FC4E6D  ld   DE,(XBC+0x0c)      R[+0x0C]
   FC4E72  neg  WA                 d1 = -R[+0x0C]
   FC4E9F  ld   (XBC+0x02),HL      -> staging word 1 = register chan+0x0040
```

and the SUB reader at `0xFC4ED4`-`0xFC4F4E` is the same with `+0x20` and word 2.

### 1.2 ★★ NULL 1 — the two are ONE routine written twice

The two spans `0xFC4E25`-`0xFC4E63` and `0xFC4ED4`-`0xFC4F12` are both **63 bytes**
and differ in **exactly ONE byte**: the displacement, `0x16` against `0x20`.  Even
the relative branch displacements are identical, because the spans are the same
length.

**THE NULL.**  Sliding a 63-byte window over all 512 KB of prom_c and counting
windows within four differing bytes of the MAIN span gives **one** — and it is the
SUB span.  A pairing this tight has no second instance in the image.

(This is the narrow core of the `0.9771` over 175 bytes that `HLE-GUIDE-l7a1429.md`
§2.4 already measured for the `0x0040`/`0x0080` pair, against a null mean of
`0.0351`.  The two results agree and neither depends on the other.)

---

## 2. WHAT THE TWO ARMS MEAN

Every term is identified at the instruction that writes it, not by its name in an
earlier note:

| term | who writes it | what it is |
|---|---|---|
| `(0x00E08A)` | `Pack104_SetInputs_E088_E089_E08A` arg `(XIZ+0x0A)`, pushed from `voice[+0x08]` at `0xFB0AF0` | `voice[+0x08]`, and `Voice_ComputePitch` stores it at `0xFA8078` **immediately before** its key-follow stage |
| `(0x00E08D)` | `Pack104_SetInputs_Rec0E_E08D` arg `(XIZ+0x0A)`, pushed from `voice[+0x0A]` at `0xFB0B4F` | `voice[+0x0A]` = `Sat16(voice[+0x06] + (0x005A4F))` |
| `R[+0x0C]` | `Pack104_SetInputs_Rec0C_E08C` arg `(XIZ+0x0C)`, pushed from `zone[+0x06]` at `0xFA7494` | the key-zone record's word `+0x06`, which the same routine also stores to RAM `0x005A4F` — **the very word `voice[+0x0A]` adds** |

So, with the saturations set aside:

```
    RESO SCALE ON :   d = voice[+0x08] - voice[+0x06] - zone[+0x06]
    RESO SCALE OFF:   d =                             - zone[+0x06]
```

Both arms remove the key zone's offset.  Only the `ON` arm also adds
`voice[+0x08] − voice[+0x06]`, which is **the entire last stage of
`Voice_ComputePitch`**: the key-follow compression
`pitch = pivot + ((pitch − pivot) >> H)` (or the fixed `0x4280` when `H == 7`) and
the key zone's coarse/fine sample tuning.

**So `RESO SCALE` decides which pitch the resonator is tuned relative to.**  `OFF`:
the pitch the wave is played at, so the resonator follows whatever key-follow
scaling the tone applies.  `ON`: the raw note, so the resonator tracks the keyboard
at full scale regardless.  A control that decides whether the resonator *scales*
with the key is what `RESO SCALE` is called.

⚠ **GRADES, not rounded up.**

* the two reader sites, both arms' arithmetic, and every term's writer: **PROVEN**
  (operands only);
* "so `ON` tunes from the raw note and `OFF` from the played pitch": **STRONG** —
  it reads a meaning out of an identity, and the identity is exact only up to the
  two `Sat16` clamps in the chain;
* what a listener would hear: **UNIDENTIFIED**, and it will stay that way from the
  image alone.  Playing one note with the flag off and on and comparing the
  resonance across the keyboard would settle it in a minute; the instrument is in
  storage abroad, so that is the conclusion and not a next step.

---

## 3. THE CENSUS THAT MAKES "ONLY THESE TWO" FALSIFIABLE

**Framing-independent byte scan**, the same instrument as
`w21_lsi_gate_and_keyscaling.py` §3: every offset of all four images whose byte 0 is
a `(Xrr+d8)` memory-operand prefix (`0x88-0x8F` byte, `0x98-0x9F` word, `0xA8-0xAF`
long, `0xB8-0xBF` no-size) and whose byte 1 is the displacement.  ★ This is the only
form that sees the tree's raw-byte `extpfx*` pseudo-instructions — `bit 7,(XIX+0x16)`
is the three bytes `bc 16 cf` and matches **no** `ld` pattern.

| d8 | prom_a | prom_b | prom_c | prom_d |
|---|---:|---:|---:|---:|
| `0x16` | 13 code / 42 data | 2 / 8 | **80** / 8 | 0 / 1 |
| `0x20` | 31 code / 482 data | 2 / 198 | **42** / 21 | 0 / 42 |

**Address-space elimination.**  prom_a and prom_b are CPU 1's images and CPU 1 has
its own address space (`prom_c/prom_c.ld`); the staged wave-select records live in
CPU 2 RAM at `0x0087D2 + 0x21D`.  So only prom_c's 122 hits can be readers.

**All 122 partitioned mechanically**, not waved past:

```
    store / read-modify-write   45      byte read    37
    word read                   30      long read     9      unsized operand  1
```

and every READ is then checked for a bit-7 mask — in its own spelling or in the
next three instructions, in any spelling (`and r,0x80`, `and rr,0x0080`, `bit 7,`,
`res 0x07,`, `set 0x07,`).  **Twenty-four qualify:**

* **2** TEST the bit: `0xFC4E28` and `0xFC4ED7`, §1's two;
* **18** CLEAR it first (`res 0x07`) — nine on `+0x16` and nine on `+0x20`, §4's;
* **3** take their base from the routine's **own frame pointer** `XIZ`
  (`0xFB211C`, `0xFB2A14`, `0xFB312D`) and *set* the bit in a stack local; a
  wave-select pointer is never the frame pointer;
* **1** is `0xFC3600 bit 7,(XIX+0x16)`, whose `XIX` is the 23-byte **slot record**
  at `0x00DC0E`, reached through the `0x00DF05` pointer table (`0xFC35E9 mul C,0x04`,
  `0xFC35EE add XBC,0x0000df05`) — a different object.

One more row is worth naming because it looks like a p22 read and is not:
`0xFC7A4B ld XWA,(XBC+0x16)` — its `XBC` is the **PART** record, and `0x13 + 3` is
`P0[+0x03]`, the tone POINTER.  It is the `GROUP` selector read of §5, hop 7.

### 3.1 ⚠ THE FORMS THIS NEGATIVE SEARCHED

| form | how it was searched | found |
|---|---|---|
| a literal displacement `(Xrr+0x16)`/`(Xrr+0x20)` on any base | the byte scan, all four images | the 122 |
| a base **spilled to a frame** and reloaded | the scan matches the displacement, which no spill can hide | ★ **the reader FOUND is exactly this shape** — `Dev104_PackStagingStruct` reads Q only through `(XIZ-4)` |
| a base held in a register across a call | same argument | none new |
| a base **advanced past** the field, then `(Xrr)` | provenance: every wave-select pointer comes from `Part_GetWaveSelectRecord` (§5 hop 5) or `PartElement_SetWaveSelectPointer_ToRomDefault`, both asserted | none |
| an **absolute** access to a staged record byte | ★ **RUN, not asserted**: the eight staged addresses are `0x8A05/0x8A30/0x8A5B/0x8A86` (`+0x16`) and `0x8A0F/0x8A3A/0x8A65/0x8A90` (`+0x20`); prom_c scanned for each as an LE16 **and** an LE24 literal | **one** hit, `0xFE0940`, not at an instruction start — it straddles two entries of the monotone 16-bit table at `0xFE0939` (`0x0FA9, 0x0C8A` → the bytes `0f 8a`).  No absolute reader exists |
| a **block move** over the record | `ToneStage_ApplyWaveSelTailPreset` overwrites bytes 13..42 | it **writes** both bytes; it reads neither |
| an address minus an index (`TABLE − 4*k`) | the literal scan above; the records are RAM, not a table | none |
| a pointer stored in **another table** | `P[+0x03]`, and the part record's `+0x8C + 41*e` slot — both walked instruction by instruction in §5 | the two of §1 |
| a raw-byte `extpfx*` pseudo-instruction | the scan is over BYTES, so these match | `0xFC3600` is one, and it is in the census |

⇒ **In the whole of prom_c, exactly two instructions can see p22/p32 bit 7.**

### 3.2 ★ NULL 4 — is "test bit 7 of a wave-select byte" a special shape?

Over prom_c the shape `ld r,(Xrr+d8)` followed immediately by `and r,0x80` occurs at
**39 sites over 18 displacements**.  Restricted to the sites whose base is `Q`, it
lands on **eight** of the 43 wave-select bytes:

| byte | field | drawn as |
|---|---|---|
| `+0x0E` | p14 bit 7 | `FORMANT`, `FIX`/`MOVE` (PAGE1/2) |
| `+0x12` | p18 bit 7 | `S/H`, `OFF`/`ON` (PAGE2/2) |
| `+0x15` / `+0x1F` | p21 / p31 bit 7 | `RESO MODE`, `OFF`/`ON` (PAGE3/3) |
| `+0x16` / `+0x20` | p22 / p32 bit 7 | **`RESO SCALE`**, `OFF`/`ON` (PAGE1/3) |
| `+0x19` / `+0x25` | p25 / p37 bit 7 | the key-follow breakpoint DISABLE — documented in prom_c, not a drawn caption |

**Six of the eight are the six two-state controls the editor draws out of a
wave-select bit 7, and there are exactly six** — so the correspondence is six of six
in *both* directions.  The remaining two are the documented disables.  **Not one of
the 35 value fields is read this way**, which is what a shape landing on flags by
chance would have done.

---

## 4. ⚠ RETRACTION: `RESO SCALE` DOES NOT REACH `index_bias_A`

`FINDINGS-l7a1429-editor-pages.md` §5 item 3 and §6 say:

> the `0x0340`/`0x0400` index chain reads p22 only through `R[+0x1A]`, and this lane
> did not find that field's writer.

That is wrong twice, and both halves are worth writing down because each is a
recurring failure mode.

**(a) A FIELD-NAME COLLISION.  Two different records have a `+0x1A`.**

```
   P[+0x1A]  `index_bias_A` -- added to the muting index i3   0xFC529F, base (0x00E084)
   R[+0x1A]  the word register 0x0480 carries, copied from P[+0x26]
                                                              0xFC567F, base (0x00E086)
```

`prom_c/devices/dev10c_dev104_drivers.s` names `index_bias_A` inside `struct
Part104Voice`, which is **P**; the note quoted it as `R[+0x1A]`, which is a different
word with a different producer.  ★ *A struct field name is not an address.*

**(b) THE WRITERS ARE LOCATABLE — and all of them clear the bit.**  Byte scan for
`d8 = 0x1A`: prom_c has 62 code hits, of which **13** are stores through a
`(Xrr+0x1a)` operand.  Nine write `P[+0x1A]`:

| sites | routine |
|---|---|
| `0xFC64A2` `0xFC64E9` `0xFC651F` | `PartRec_SetMutingOffset_000B`, three arms |
| `0xFC6B9F` `0xFC6BE6` `0xFC6C1E` | `Pack104_LoadElementWaveSelRec`, three arms |
| `0xFC78FF` `0xFC7946` `0xFC797C` | `Pack104_DispatchByResoMode_ForPart`, three arms |

and the other four are named by their own base: `0xFAC318` (an init loop),
`0xFC52FB` (the 19-word staging struct — word 13 *is* register `0x0340`, which is
how the two `+0x1A`s came to be confused a third way), `0xFC567F` (`R`), and
`0xFC7A8C`, which is a **byte** store through `P[+0x03]` — i.e. into `Q` itself,
writing `Q[+0x1A] = p26`.

★★ **Every one of the nine takes p22 and applies `res 0x07` at once:**

```
   FC6483  ld  C,(XIX+0x16)      p22
   FC6486  res 0x07,C            <- bit 7 discarded HERE
   FC6489  extz BC
   ...
   FC64A2  ld  (XBC+0x1a),DE     P[+0x1A] = (p22 & 0x7F) + PART[+0x0B]
```

nine of nine on `+0x16`, and the SUB half is nine more on `+0x20`.  **So the
`0x0340`/`0x0400` chain cannot see `RESO SCALE` at all.**  What `P[+0x1A]` actually
carries is `(p22 & 0x7F) ± PART[+0x0B]` — the `MUTING` value plus or minus a
part-level cutoff offset, with the sign from `P[+0x01]` bits 1:0; that is wave 20's
reading and it stands unchanged.

⚠ The open item was not "a writer nobody could find".  It was **an answer looked for
in the wrong register**, and the search that would have found it — "what reads this
BIT", rather than "what writes that FIELD" — is the one §3 runs.

---

## 5. TARGET 2 — THE `GROUP` CHAIN, CLOSED

`FINDINGS-l7a1429-gate-and-keyscaling.md` §1 proved that register `chan+0x0000`
bits 6:4 come from `P[+0x07]`, that fifteen sites in seven routines write them, and
that every one is downstream of `Q[+0x0B] & 0xC0` — the editor's five-state `GROUP`.
What it could not say was how the editor's field becomes that byte.  Eight hops,
each an asserted instruction:

**HOP 1 — prom_a sends it.**  A six-byte tone message: `byte[0] = 0x88 | arm`,
`byte[1] = part`, `byte[2] = (element << 6) | parameter`, `byte[4] = value`,
`byte[5] = mask`.  The MODELING top page's `GROUP` editor sends parameter `0x0B`
with mask `0xC0`.  INHERITED, grade **PROVEN**, from
`FINDINGS-l7a1429-parameter-names.md` §2c/§2d and `FINDINGS-l7a1429-editor-pages.md`
§1a.  Not re-derived here.

**HOP 2 — `ToneMsg_Dispatch` picks write arm 4.**  Bit 3 of `byte[0]` selects the
write table at `0xFC2754`; bits 0:2 index it.  Entry 4 is `0xFC26E9`, which calls
`ToneStage_EnsurePartLoaded(msg[1])` (`0xFC26F0`) and then `sub_FBC958` (`0xFC26F8`).

**HOP 3 — `sub_FBC958` stores the byte.**

```
   FBC966  ld  W,(XBC+0x02)          the parameter byte
   FBC96C  and W,0xC0 / srl 6        element = bits 7:6
   FBC97A  mul C,0x2B                43 = the wave-select record stride
   FBC97F  add XBC,0x0000021D        + the tone record's wave-select block
   FBC985  add XBC,0x000087D2        + the RAM tone staging image
   FBC994  and A,0x3F                parameter = bits 5:0
   FBC9A0  ld  A,(XIY+0x04)          the value byte
   FBC9A3  ld  (XBC),A               -> 0x0087D2 + 0x21D + 43*element + parameter
```

⚠ **The mask `byte[5]` is not applied here** — prom_a sends the whole byte.  Its only
use in this image is the parameter-11 arm, which reloads the `RESONATOR TYPE` preset
over bytes 13..42 when the mask is `0x3F` or `0xFF` (`0xFBCA1D`, `0xFBCA25`,
`0xFBCA34`) and does **not** when it is `0xC0`.  ★ So a `GROUP` write changes p11
bits 7:6 and leaves the thirty coefficients alone — which is exactly what a second
control sharing a byte with `RESONATOR TYPE` has to do, and the mask byte exists to
tell the two apart.

**HOP 4 — the tail at `0xFBCB09`, run on EVERY parameter**, reloads that element:

```
   FBCB31  ld  C,0x29                41 = the part-element sub-record stride
   FBCB3D  mul WA,0x012C             300 = the part-record stride
   FBCB43  add WA,0x008C             + 0x88 + 4 = the wave-select pointer slot
   FBCB49  ld  XBC,(XWA+0x1523)      the part record array
   FBCB59  call 0xFC6803             Pack104_LoadElementWaveSelRec(part, elem, ptr, en)
```

**HOP 5 — ★★ that pointer IS the address hop 3 wrote into.**
`Part_GetWaveSelectRecord` tests the part's `staged` flag and, when it is set,
returns the staged record with the *same three literals*:

```
   FB4505  ld  WA,(XIX+BC) / and WA,0x0001    part[+0x04] bit 0 = `staged`
   FB4510  ld  C,0x2B                          43
   FB4517  add XBC,0x0000021D
   FB451D  add XBC,0x000087D2                  -> 0x0087D2 + 0x21D + 43*elem
```

and `Part_LoadToneRecordAndPointers` stores that return into `part[+0x8C + 41*e]`
(`0xFB4865`/`0xFB486B`).  Arm 4 sets the flag itself, via
`ToneStage_EnsurePartLoaded` (`0xFBAB04 or (XBC+0x1523),0x0001`) — hop 2 — so on the
edit path the record hop 3 wrote and the record hop 6 binds are provably the same
object.

**HOP 6 — the bind.**  `Pack104_LoadElementWaveSelRec` sets
`(0x00E082) = 0x005D23 + 0xBB*part`, `(0x00E084) = that + 0x13 + 42*element`, and
`P[+0x03] = the pointer` (`0xFC6831`/`0xFC6834`).

**HOP 7 — the fold.**  `0xFBCB9E call 0xFC7481`, and
`Pack104_DispatchByResoMode_ForPart` reads each element's `Q[+0x0B] & 0xC0` through
`PART[+0x16]` = `P0[+0x03]` (`0xFC7A4B`/`0xFC7A4E`/`0xFC7A51`) and dispatches to the
fifteen `and (Xrr+0x07),0xFF8F` writers of `P[+0x07]` bits 6:4.

**HOP 8 — the ship, and the gate.**  `Dev104_PackStagingStruct` builds staging word 0
as `(R[+0x07] << 8) | P[+0x07]` (`0xFC4DD1`), and `0xFC51B5`/`0xFC51B7`
`and WA,0x0070` is the gate on register `chan+0x0300`.

⇒ **`p11` bits 7:6 → the staged wave-select record byte `+0x0B` →
`Pack104_DispatchByResoMode_ForPart` → `P[+0x07]` bits 6:4 → staging word 0 →
register `chan+0x0000` bits 6:4 → the `0x0300` gate.  GRADE PROVEN** for hops 2-8
(operands only); hop 1 is inherited PROVEN and not re-derived.

### 5.1 NULLS 2 AND 3 — the addressing is a TILING, not a coincidence

The chain rests on two address computations agreeing across four routines.  Both
are arithmetic identities that could have failed:

```
    0xD9  + 4*81 == 0x21D          the four 81-byte element blocks end
                                   exactly where the wave-select block begins
    0x21D + 4*43 == 713 == 0x2C9   and the four 43-byte records end exactly at
                                   prom_d's own tone-record size
    0x88  + 4*41 == 300 == 0x12C   the four 41-byte sub-records tile the part record
```

`0x21D`, `0x2C9`, `0x12C`, `43`, `41` and `81` are all instruction operands.  Under a
wrong stride none of the three closes: 42 gives `0x2C5`, 44 gives `0x2CD`, and
neither is a size prom_d uses.  And `+0x8C` is `+0x88 + 4`, the **second** 32-bit
pointer of the sub-record, which is why hop 4's `add WA,0x008C` and hop 5's
`add BC,0x008C` are the same slot.

---

## 6. THE FACTORY DATA, WITH ITS DENOMINATOR STATED

⚠ **Three different populations are in use across these notes and they disagree.**
A rate quoted without its definition is what once turned `133/133` into an
overstated uniformity.  All three are named:

| population | what it is | `RESO SCALE` MAIN set | SUB set |
|---|---|---|---|
| **loose, 256 tones / 459 records** | every tone prom_d's directory frames | **403 / 459 = 87.8 %** | 402 / 459 = 87.6 % |
| strict, 101 tones / 133 records | + `dev104_topology_probe.py`'s element-block filter (wave index < 307) | 128 / 133 = 96.2 % | 128 / 133 |
| melodic, 223 tones / 392 records | `FINDINGS-l7a1429-editor-pages.md` §4b — melodic tones only, via prom_d's 17-byte-name chain | 346 / 392 = 88.3 % | — |

None of the three is wrong; each is a rate about a different set of tones.  **Prefer
the loose 459 unless the claim is specifically about one of the subsets.**

★ **A finding rather than a rate.**  MAIN and SUB disagree in only **3 of 459**
records.  So in the factory bank `RESO SCALE` behaves almost exactly like a
per-TONE switch, even though the register path is strictly per-RESONATOR and the
firmware would honour a mixed setting.  That is a fact about the shipped data, not
about the firmware, and it is stated as such.

---

## 7. WHAT AN HLE SHOULD DO

Replacing nothing; adding to `HLE-GUIDE-l7a1429.md` §5's rows for `0x0040`/`0x0080`:

```c
// registers chan+0x0040 (MAIN) and chan+0x0080 (SUB), decoded
//   0x0040 = SatAsym(P[+0x0A] + P[+0x12] + d1)
//   0x0080 = SatAsym(P[+0x0C] + P[+0x14] + d2)
// with, for the MAIN half (the SUB half is the same on Q[+0x20]):
//   d1 = (Q[+0x16] & 0x80) ? voice[+0x08] - voice[+0x0A]     // RESO SCALE ON
//                          : -R[+0x0C];                       // RESO SCALE OFF
//   voice[+0x08] = the voice pitch BEFORE Voice_ComputePitch's last stage
//   voice[+0x0A] = Sat16(voice[+0x06] + keyzone[+0x06])       // the played pitch
//   R[+0x0C]     = keyzone[+0x06]                             // == RAM 0x005A4F
// so ON adds back (voice[+0x08] - voice[+0x06]) -- the key-follow compression and
// the key zone's sample tuning -- and the resonator tracks the RAW key instead of
// the pitch the wave is played at.  Unit: 1/256 semitone, as for the whole pitch
// chain.  Q[+0x16] bit 7 is `RESO SCALE` MAIN, Q[+0x20] bit 7 is `RESO SCALE` SUB.
```

An HLE that already models registers `0x0040`/`0x0080` as a tuning offset needs to
change nothing structurally: it needs the correct `d`, and the flag that picks it.

---

## 8. WHAT REMAINS OPEN

* **What `RESO SCALE` sounds like.**  §2 says what the firmware computes; only the
  instrument says what the chip does with it.  ⚠ Not available.
* **Where the DATA-dial edit for `RESO SCALE` lives.**  `FINDINGS-l7a1429-editor-pages.md`
  §6 records that the two `MUTING` editors clamp to `0..0x7F` and so cannot set
  bit 7 of p22/p32, and that the region `0xFD40B6`-`0xFD5B5E` holds editors for only
  six fields.  This lane did not look for the missing editors — it worked from
  `RESO SCALE`'s CPU-2 side — so that hole is **unchanged and still open**.
* **`0x00E093`** — the per-element block the three gate-opening arms fill, still with
  no located reader (`FINDINGS-l7a1429-gate-and-keyscaling.md` §1.8).  Untouched.
* **The eight remaining 43-byte-record parameters** — p0, p1, p2, p12, p20 — still do
  nothing this image reads.  Untouched.
