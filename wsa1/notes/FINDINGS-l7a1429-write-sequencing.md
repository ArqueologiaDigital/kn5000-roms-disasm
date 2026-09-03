# 0x00104000: the write sequencing, not the register map

Lane `w19/lsi-timing`, 2026-09-03.  Companion to
`notes/FINDINGS-prom_c-dev104-register-map.md`, which says **what** each of the nineteen
per-channel registers is built from.  This says **when** each one is written, how often, and
in what order — the half of a device model a register map does not give you.

Everything below is re-derived from `original_ROMs/wsa1_prom_c.ic28` by

```
python3 notes/wsa1_l7a1429_write_timing_probe.py             # 11 sections, printed
python3 notes/wsa1_l7a1429_write_timing_probe.py --selftest  # FAILURES: 0
```

⚠ Scope discipline, kept throughout: this describes **what crosses the bus at 0x00104000**.
Where a value comes out of RAM the RAM address is named as a *source of the number*, never as
a description of the device.  ⚠ "No read-back" remains a fact about the bus.  A device the CPU
never reads can hold as much internal state as it likes, and the firmware's habit of
re-writing whole channels is equally consistent with a chip that remembers everything.

⚠ The reading that 0x00104000 is the acoustic-modelling LSI is a DECLARED INFERENCE held over
from the driver work (no WSA1R ROM names any part).  Nothing below depends on it.

---

## 1. THE CHANNEL COUNT: **64** — PROVEN

Not by analogy with the sibling at `0x0010C000`, and not from the 0x40 block stride.  From the
loops that drive *this* device.

`Dev10C_ResetAllChannels` (0xFB80E1) contains two loops over `HL`, each closed by
`cp HL,0x0040 / jr C` — `db cf 40 00` at **0xFB81B9** and at **0xFB8281** — and each loop body
calls a 0x00104000 writer with `HL` as the channel argument:

| loop | closing compare | what it calls with the channel |
|---|---|---|
| 1 | 0xFB81B9 | `calr 0xFB77EF` at 0xFB81A4 — `Dev104_WriteAllChanRegs`, all nineteen registers |
| 2 | 0xFB8281 | `calr 0xFB7A58` at 0xFB826B — `Dev104_WriteChanReg0`, block 0 only |

So the firmware programs channels **0x00..0x3F** of this device at power-on.  Probe section 1
asserts both compares *and* re-computes both `calr` displacements to their targets, so the
bound and the callee are checked together rather than assumed adjacent.

Corroboration, five further sites (probe section 1): every runtime path bounds its channel
argument with `cp H,0x40` and skips the device on `NC` — `MidiNote_OnTail` 0xFB36A8,
`MidiNote_OffTail` 0xFB37B5, `sub_FAC34D` 0xFAC37B, `sub_FACAB7` 0xFACACD, and
`Pack104_SetInputs_SubRecordPair` 0xFC4CE7.  5 of 5.

⚠ **THE NULL, and it matters.**  On the companion device a channel argument of 0x40..0x7F is
*not* a 65th channel: six of its routines branch on `cp HL,0x0040` and the high arm re-aims the
same staging field at slot 3 (`prom_c/devices/dev10c_dev104_drivers.s`, the 0xFB7B63 banner).
If 0x00104000 had that trick, "64" would be a re-encoding rather than a count.  It does not:

```
`cp HL,0x0040` inside the eight 0x00104000 routines : 0
`cp HL,0x0040` inside the 0x0010C000 driver blocks  : 6      (the control)
```

**64 channels, each with the nineteen registers of the map, plus one register outside the
per-channel space (§3).**

---

## 2. THE COMPLETE BUS SURFACE: eight routines, 27 call sites

The image holds **nine** `0x00104000` literals — eight, one each, in the eight driver routines,
and one direct write inside `Dev10C_ResetAllChannels` (probe section 0; the same census
`notes/prom_c_dev104_regmap_checks.py` section 3 makes).  **Nothing else in prom_c can reach
the device**, so the table below is the whole of it.

Call sites are the image-wide `1D <addr24>` (call) and `1E <disp16>` (calr) scan, probe
section 2.  Enclosing-routine names are the tree's labels.

| routine | registers it writes | sites | who calls it, and WHEN |
|---|---|---|---|
| `Dev104_WriteAllChanRegs` 0xFB77EF | all 19, block 0 **last** | 9 | 4 × `VoiceRegs_Stage_A/B/C/D` (note-on/off staging) · `MidiNote_OnTail` · `MidiNote_OffTail` · `NotePool8_NoteOnOff` (the private 8-slot pool's note-on) · `sub_FAC34D` (the auto-note countdown) · `Dev10C_ResetAllChannels` (**power-on, ×64**) |
| `Dev104_WriteChanReg0` 0xFB7A58 | block 0 only | 8 | `MidiNote_OnTail` · `MidiNote_OffTail` · `MidiNote_OnByPartMode` ×3 (one per part-mode arm) · `NotePool8_NoteOnOff` · `sub_FAC34D` · `Dev10C_ResetAllChannels` (**power-on, ×64**) |
| `Dev104_SetChanRegs_00C0_0100_0240` 0xFB7A73 | 0x00C0, 0x0100, 0x0240 | 3 | `sub_FACAB7` (**periodic**, §5) · `sub_FAEAF9`, `sub_FAEB65` (**parameter edit / MIDI CC**, §6) |
| `Dev104_SetChanRegs_00C0_0100` 0xFB7AC9 | 0x00C0, 0x0100 | 1 | `sub_FACAB7` (**periodic**) |
| `Dev104_SetChanRegs_0140_0180` 0xFB7B05 | 0x0140, 0x0180 | 5 | `MidiNote_OnTail` · `MidiNote_OffTail` · `MidiNote_OnByPartMode` ×3 — always conditional on `sub_FC56C4` returning non-zero |
| `Dev104_SetChanReg_0280` 0xFB7B41 | 0x0280 | 1 | `sub_FAECC7` (**parameter edit / MIDI CC**) |
| `Dev104_SetChanRegs_01C0_0200_0240` 0xFB796E | block 0 **first**, then 0x01C0, 0x0200, 0x0240 | **0** | no located caller |
| `Dev104_SetChanRegs_0140_to_0240` 0xFB79D0 | block 0 **first**, then 0x0140…0x0240 | **0** | no located caller |

**27 located call sites over 6 of the 8 routines.**  ⚠ "No located caller" is a searched
negative of an absolute-`call` and `calr` scan; a call through a register operand is invisible
to it.  Not "dead" — "not found".

⚠ Two dozen of the 27 sites are reached from `MAIN` (0xF98B7D) directly or through
`MidiIn_ParseRingAndDispatch`; the three inside `sub_FAEAF9`/`sub_FAEB65`/`sub_FAECC7` inherit
`Voice_ApplyParamChange_Dispatch`'s 68 call sites, which this lane did not trace.  **No site
was found inside an interrupt handler**, which is consistent with the fact that no writer
disables interrupts around its select/data pair (§7) — but the fan-in above is unfinished, so
grade that WEAK.

### Timing hygiene of the bus itself

**PROVEN, and it is a difference from the companion.**  Every 0x0010C000 data write in this
firmware is followed by **five `nop`s** of bus padding.  Inside the eight 0x00104000 routines
that five-`nop` run occurs **zero** times (probe section 7; the control — the 0x0010C000 loops
of the very same reset routine — has 3).  Consecutive register writes to 0x00104000 are
separated only by the 3–5 instructions that build the next select value.  **An HLE needs no
write-recovery delay on this device.**

---

## 3. INITIALISATION — the state the firmware expects at t=0

There is no `Dev104_ResetAllChannels`.  The equivalent is the **second half of
`Dev10C_ResetAllChannels`** (0xFB80E1), which serves both devices and is called from exactly
one site: 0xFB05CD, at the end of `ExtBoard_ProbeAndInstallBases`, which is the **first** call
`MAIN` makes.  So this runs once, before anything else in the sound path.

In order (probe sections 3 and 4; every address is an instruction operand):

**Step 0 — one register outside the per-channel space.**

```
0xFB80F1  ld XIX,0x00104000
0xFB80F6  ld (XIX),0x0800          ; SELECT register number 0x0800 -- no channel added
0xFB80FA  ld BC,(0xFE1313)         ; = 0x1100
0xFB80FF  ld (XIX+2),BC            ; DATA
```

⚠ **This is a 20th register number and the map does not cover it.**  0x0800 is block 0x20 with
channel 0, or a global register; nothing decides which, and nothing else in the image ever
writes it.  Value **0x1100**, once, at power-on.  MEANING UNIDENTIFIED.

**Step 1 — the staging struct is loaded from a ROM image.**
`MemCopyWords(src=0xFE133B, dst=0x00D91F, 38)` at 0xFB8168 — 38 bytes = the nineteen 16-bit
words, one per register.  `Dev104_StagingStruct_ResetImage` in
`prom_c/data_tables/tail_data_zone.s`.

```
 word  register        value        word  register        value
   0   chan+0x0000     0x0004        10   chan+0x0280     0x8000
   1   chan+0x0040     0x0000        11   chan+0x02C0     0xFF00
   2   chan+0x0080     0x0000        12   chan+0x0300     0x0000
   3   chan+0x00C0     0x6C00        13   chan+0x0340     0xE0B8
   4   chan+0x0100     0x0100        14   chan+0x0380     0xE0B8
   5   chan+0x0140     0x0230        15   chan+0x03C0     0xE05E
   6   chan+0x0180     0x0230        16   chan+0x0400     0xBDF0
   7   chan+0x01C0     0x1C54        17   chan+0x0440     0xBDF0
   8   chan+0x0200     0x1C54        18   chan+0x0480     0x987B
   9   chan+0x0240     0x26D7
```

★ **THE IMAGE CHECKS THE REGISTER MAP, INDEPENDENTLY.**  Two words of it are values the map
derives from completely different evidence, and they agree:

* word 4 = **0x0100** — and the map's register 0x0100 is `Const_0100_251[i]`, a 251-entry table
  that holds 0x0100 in every entry;
* word 11 = **0xFF00** — and the map's register 0x02C0 is the literal 0xFF00, the only value
  any instruction ever puts in that word.

An off-by-one in the word↔register mapping would break both.  ★ The image also shows the map's
A/B pairing directly: w5 = w6, w7 = w8, w13 = w14, w16 = w17.

**Step 2 — 64 full writes.**  For `chan` = 0x00 … 0x3F:

```
(0x00D91F) &= 0xC0FF ; (0x00D91F) |= (chan << 8) & 0x3F00     ; 0xFB8181-0xFB8198
Dev104_WriteAllChanRegs(chan, &0x00D91F)                       ; 0xFB81A4
```

★ **So word 0's bits 13..8 carry the CHANNEL NUMBER** on this path.  The register-map header
reads register 0 as `(R[+0x07] << 8) | P[+0x07]`; here the same byte position is filled with
the channel index instead.  Both are the high byte of block 0.  PROVEN as arithmetic; what the
field *is* stays UNIDENTIFIED.

**Step 3 — 64 block-0-only writes, with bit 2 cleared.**  For `chan` = 0x00 … 0x3F, after that
channel's 0x0010C000 slot writes:

```
(0x00D91F) &= 0xC0FF ; BC = (0x00D91F) ; res 2,BC ; store   ; 0xFB8239-0xFB824B
(0x00D91F) |= (chan << 8) & 0x3F00
Dev104_WriteChanReg0(chan, &0x00D91F)                        ; 0xFB826B
```

**Total power-on traffic: 1 + 64×19 + 64×1 = 1281 register writes = 2562 word writes to the
port pair.**

### The quiescent state an emulated device must come up in

| register | value after init |
|---|---|
| 0x0800 (no channel) | 0x1100 |
| chan+0x0000 | `(chan << 8)` — the ROM image's 0x0004 with **bit 2 cleared** by step 3 |
| chan+0x0040 … chan+0x0480 | the eighteen image words above, identical on all 64 channels |

---

## 4. BIT 2 OF BLOCK 0 — and a reading that the null kills

The image's word 0 is **0x0004**: bit 2 set.  The power-on sweep's last act is to clear it
(`res 0x02,BC`, 0xFB8245).  And the routine every note event runs,
`Pack104_SetInputs_SubRecordPair`, ends by *setting* it (probe section 5):

```
0xFC4D43  ld A,(XBC+0x07)          ; R[+0x07]
0xFC4D4A  sll 8,HL                 ; << 8
0xFC4D50  ld (XBC),HL              ; staging word 0 = R[+0x07] << 8
0xFC4D54  set 0x02,BC
0xFC4D5A  ld (XWA),BC              ; staging word 0 |= 0x0004
```

That is `0x0004` cleared at power-on and set at every note event — exactly the shape of a
per-channel key gate.

⚠ **NULL, AND IT REFUTES THE READING.**  `Pack104_SetInputs_SubRecordPair` has five call sites
and they are 0xFB36F5, 0xFB3802, 0xFB391C, 0xFB3A67, 0xFB3B85 — 5 of 5 are `MidiNote_*`, and
**0xFB3802 is inside `MidiNote_OffTail`**.  The note-OFF tail sets bit 2 just as the note-ON
tail does.  Bit 2 is therefore **not** a key gate; on the evidence it is set whenever a channel
is programmed at all and cleared only once, at the end of the power-on sweep.  Recorded so the
next lane does not re-derive the same wrong conclusion.

---

## 5. PERIODIC VS ONE-SHOT — the classification, per register

### The tick

CPU 2's timer 1 is the pacemaker.  `ldio T01MOD,0x0D` at **0xFFF06C** in `RESET` selects φT256
for timer 1, and `Timer1_SetPeriodAndStart` loads `TREG1` with the fc-in-MHz byte at 0xFFFFEF =
0x1C = 28, so

> **INTT1 = 28 000 000 / 2048 / 28 = 488.28 Hz.**

⚠ **Which number this note used, and why.**  It is NOT derived here from scratch.
`notes/FINDINGS-system-clock.md` derives fc = 28 MHz; `notes/WSA1-EMULATION-DISASM-GAPS.md`
item 2 supplies the **prescaler correction** (upstream `tmp95c061` had the taps 16× slow;
Table 3.8(1) p.81 gives φT1/φT4/φT16/φT256 = 8/32/128/2048 over fc) and reports the rate
**measured live at 488.27 Hz** after the fix, together with the `T01MOD` write that the
scheduler note and `Timer1_SetPeriodAndStart`'s own header still record as "not located".
⚠ Those two texts are in files this lane does not own and are **not edited**; reported.

The INTT1 handler steps a six-phase counter and sets bits in `0x007ED1`; **bit 4 is set on
exactly one of the six phases** — 8 `set n,(0x007ED1)` sites in the whole image, one of them
bit 4 (probe section 9).  `MAIN`'s bit-4 arm calls `Toggle14FE_AndDispatch` (0xFB05EC), which
**alternates** between two paths on every call (`xor (XIX),0xff`, 0xFB0605), and the odd path
calls `sub_FACAB7`.

> **the periodic 0x00104000 refresh runs at 488.28 / 6 / 2 = 40.69 Hz** (24.6 ms).

⚠ That is an upper bound as well as a rate: the flag is a level, so a `MAIN` iteration longer
than 12.3 ms coalesces two settings.  It can be slower, never faster.

### What the refresh does

`sub_FACAB7` walks the active-voice list (terminator `cp H,0x40`), and for each voice calls
`sub_FC7C0D(voice, &0x00D7A2)`, which recomputes staging words through `sub_FC49AD` and returns
1, 2 or neither:

* **1** → `Dev104_SetChanRegs_00C0_0100_0240(voice, &0x00D7A2)` — registers 0x00C0, 0x0100, 0x0240
* **2** → `Dev104_SetChanRegs_00C0_0100(voice, &0x00D7A2)` — registers 0x00C0, 0x0100
* otherwise → no write

★ **PRODUCER AND SHIPPER MATCH, REGISTER FOR REGISTER** (probe section 8).  The register map's
producer index says `sub_FC49AD` writes staging words `{+0x06, +0x08, +0x12}` and `sub_FC4AED`
writes `{+0x14}`.  `Dev104_SetChanRegs_00C0_0100_0240` ships exactly `+0x06, +0x08, +0x12`
(→ 0x00C0, 0x0100, 0x0240) and `Dev104_SetChanReg_0280` ships exactly `+0x14` (→ 0x0280).  Each
of the two sub-packers has exactly the callers that pairing predicts:

| sub-packer | callers |
|---|---|
| `sub_FC49AD` | 0xFC56AA (inside the full packer) · 0xFC5EE9 (`sub_FC5D5B`, parameter edit) · 0xFC7CE9 (`sub_FC7C0D`, the tick) |
| `sub_FC4AED` | 0xFC51A7 (inside the full packer) · 0xFC67E9 (`sub_FC6712`, parameter edit) |

Three producers, three consumers, no leftovers.  This is the strongest structural signal in the
timing picture and it is what separates the modulation destinations from the voice parameters.

### The classification

| register | class | rate / trigger |
|---|---|---|
| chan+0x00C0 | **PERIODIC — model as a stream** | 40.69 Hz per sounding voice (both arms), + parameter edit, + every full write |
| chan+0x0100 | **PERIODIC — but a constant on this firmware** | as above; the value is always 0x0100 (`Const_0100_251`) |
| chan+0x0240 | **PERIODIC** | 40.69 Hz per sounding voice, arm 1 only; + parameter edit; + every full write |
| chan+0x0280 | ONE-SHOT + parameter edit | full writes; plus `sub_FAECC7` on a param change |
| chan+0x0140, chan+0x0180 | ONE-SHOT, with a conditional extra write at note time | full writes; plus `Dev104_SetChanRegs_0140_0180` at all 5 `MidiNote_*` sites when `sub_FC56C4` returns non-zero |
| chan+0x0000 | ONE-SHOT, but written **twice** per note event and twice per channel at power-on | see §7 |
| chan+0x0040, 0x0080, 0x01C0, 0x0200, 0x02C0, 0x0300, 0x0340, 0x0380, 0x03C0, 0x0400, 0x0440, 0x0480 | ONE-SHOT — voice parameters | only ever inside a full 19-register write |

**Population: 19 registers.  3 periodic, 1 param-edit-only, 2 note-time extras, 1 block 0,
12 full-write-only.**  ⚠ Register 0x0100 is periodic *in traffic* and constant *in value* on
this firmware — an emulator that ignores its value must still expect the writes.

---

## 6. PARAMETER EDITS AND MIDI CONTROLLERS

`Voice_ApplyParamChange_Dispatch` (0xFAF031) is the one routine that pushes a changed parameter
back to hardware: a 6-bit target code selects one of 49 arms through the table at 0xFAF08F
(index = code − 1).  Seven of its 68 call sites are inside named MIDI controller handlers
(`MidiCtrl_CC01`, `CC02`, `CC04`, `CC16`, `CC17`, `CC18`, `CC19`).

★ **Three arms of 49 reach 0x00104000** (probe section 10):

| table index | target code | arm | what it recomputes and ships |
|---|---|---|---|
| 28 | 29 | 0xFAF246 → `sub_FAEAF9` | `sub_FC5D5B` → `sub_FC49AD` → registers **0x00C0, 0x0100, 0x0240** |
| 29 | 30 | 0xFAF254 → `sub_FAEB65` | `sub_FC5BA2` / `sub_FC5D5B` → same three registers |
| 36 | 37 | 0xFAF29A → `sub_FAECC7` | `sub_FC6712` → `sub_FC4AED` → register **0x0280** |

All three go through `VoiceQuery_Tag00_Part` first, i.e. they act on the voices of one part.
⚠ What the target codes 29, 30 and 37 *mean* is UNIDENTIFIED — the dispatcher's own header
refuses to name the 49 entries.

**The other 46 arms never touch this device.**  So a parameter edit reaches 0x00104000 through
exactly four of its nineteen registers, and they are the same four the periodic refresh uses.

---

## 7. ORDERING AND ATOMICITY

### Block-0-last is NOT a commit strobe — STRONG

Census over all 8 routines (probe section 6; register count = half the port-store count, and
every non-zero select value is formed by an `add rr,imm16`, so block-0 writes = registers −
adds):

| routine | registers | block-0 writes | position | located callers |
|---|---|---|---|---|
| `Dev104_WriteAllChanRegs` | 19 | 1 | **LAST** | 9 |
| `Dev104_SetChanRegs_01C0_0200_0240` | 4 | 1 | **FIRST** | 0 |
| `Dev104_SetChanRegs_0140_to_0240` | 6 | 1 | **FIRST** | 0 |
| `Dev104_WriteChanReg0` | 1 | 1 | ALONE | 8 |
| `Dev104_SetChanRegs_00C0_0100_0240` | 3 | 0 | ABSENT | 3 |
| `Dev104_SetChanRegs_00C0_0100` | 2 | 0 | ABSENT | 1 |
| `Dev104_SetChanRegs_0140_0180` | 2 | 0 | ABSENT | 5 |
| `Dev104_SetChanReg_0280` | 1 | 0 | ABSENT | 1 |

Two independent reasons the "commit register" reading fails:

1. **The four routines that never write block 0 are exactly the four with real callers.**
   Every parameter change that actually happens on this firmware — the 40.69 Hz refresh, every
   MIDI-CC edit, the note-time 0x0140/0x0180 pair — lands on the device with **no block-0 write
   after it**.  A latch those registers had to wait on would have to appear in them.  It does
   not, in 4 of 4.
2. **The order is not even consistent.**  Block 0 is written LAST in one routine and FIRST in
   two others.  A commit strobe cannot be both.

⚠ Note which way this cuts: 2 of the 2 routines that write block 0 *first* have **no located
caller**, so they contribute no live traffic either way.  The falsification rests on point 1.

**For an HLE: a write to any single register takes effect on its own.**  Nothing has to be
buffered until a later write arrives.

### What *is* atomic

**The (SELECT, DATA) pair, and only that.**  Every register write is
`ld (0x00104000),<register number>` then `ld (0x00104002),<value>`, in that order, always, in
all 8 routines, with 1–4 unrelated instructions in between and **no interrupts disabled**.  A
model must latch the number written to +0x00 and apply it to the next write to +0x02.
⚠ Nothing in the firmware guards that pair, which is only safe if nothing else touches the
device — and nothing does (§2, nine literals).

**No group larger than one register is atomic.**  The strongest counter-evidence is the
firmware's own behaviour: the periodic refresh rewrites 3 registers of 19 and leaves the other
16 standing, 40 times a second.

---

## 8. ★ THE NOTE LIFECYCLE — one note, key-down to silence

The centrepiece.  Order is execution order; addresses are the call sites.  `chan` is the
allocated voice number (0..0x3F).  The staging struct is the single global `0x00D7A2`, shared
by every voice and every path — an emulator must treat each burst as "the struct as of that
moment", not as per-voice state.

Path shown: a part whose mode byte (part record +0x10, bits 7-6) is **0x40**, which is the one
mode that runs both `MidiNote_OnByPartMode`'s arm and `MidiNote_OnTail`.  Modes 0x00 and 0x80
differ only as noted at the end.

### Key-down

MIDI note-on arrives over link channel 0 from CPU 1, is parsed by
`MidiIn_ParseRingAndDispatch`, and reaches `MidiNote_Dispatch`'s velocity-non-zero arm, which
calls `MidiNote_OnByPartMode` (0xFB3F66) and then `MidiNote_OnTail` (0xFB3F75).

| # | moment | register(s) written | value source |
|---|---|---|---|
| 1 | `MidiNote_OnByPartMode` arm 0x40, 0xFB3A0A | — | `Pack104_SetInputs_PartRecord(part)`: (0x00E082) = 0x005D23 + 187·part |
| 2 | 0xFB3A67 | — | `Pack104_SetInputs_SubRecordPair(0, chan)`: (0x00E084), (0x00E086) = 0x00753E + 37·chan; **and staging word 0 := (R[+0x07] << 8) \| 0x0004** |
| 3 | 0xFB3A72 | **chan+0x0000** | `Dev104_WriteChanReg0` — staging word 0 from step 2 |
| 4 | 0xFB3A7A → `VoiceRegs_Stage_B` | — | `Dev104_LoadStageBImage` (0xFB1F42): 19 words copied from ROM 0xFE1315, then five patched — w0 = R[+0x07]<<8, w5 = 0x05A8, w6 = 0x05A8, w10 = 0x8000, w11 = 0xFF00. ★ **On this arm the nineteen registers are a ROM IMAGE, not a computation** |
| 5 | 0xFB1F51 | **all 19**, block 0 last | the struct as patched in step 4 |
| 6 | 0xFB3AC6 | — | `sub_FC56C4(chan, &struct)` → A |
| 7 | 0xFB3AD9, only if A ≠ 0 | **chan+0x0140, chan+0x0180** | staging words +0x0A, +0x0C |
| 8 | `MidiNote_OnTail` 0xFB369D | — | `Pack104_SetInputs_PartRecord(part)` again |
| 9 | 0xFB36A8 | — | voice number re-read from `VoiceParams_Compute_D`'s buffer at +10; **bail if ≥ 0x40** |
| 10 | 0xFB36C3-0xFB36E8 | *(companion device)* | 0x0010C000 `chan+0x0840` := 0xFF00, five `nop`s, `chan+0x0800` := 0xFF80 — the documented quiescent pair |
| 11 | 0xFB36F5 | — | `Pack104_SetInputs_SubRecordPair(0, chan)`; staging word 0 rewritten, bit 2 set |
| 12 | 0xFB36FB | **chan+0x0000** | `Dev104_WriteChanReg0` |
| 13 | 0xFB3703 → `VoiceRegs_Stage_D` | — | ~20 helpers, then `Dev104_PackStagingStruct(&0x00D7A2)` at 0xFB2F3B — the real nineteen-word packing of the register map |
| 14 | 0xFB2F4B | **all 19**, block 0 last | the packed struct |
| 15 | 0xFB3708 | **all 19 again**, block 0 last | ★ a **second** full burst from the same struct — see below |
| 16 | 0xFB3726 | — | `sub_FC56C4(chan, &struct)` → A |
| 17 | 0xFB373A, only if A ≠ 0 | **chan+0x0140, chan+0x0180** | staging words +0x0A, +0x0C |

★ **Steps 14 and 15 are two full 19-register bursts back to back.**  Between them
`VoiceRegs_Stage_D` calls only 0xFAB6D5, 0xFC35B8, 0xFAB7E0 and the *companion* device's
writer; none of the 35 sites in the image that name the literal `0x00D7A2` is inside those
three, and nothing between them calls the 0x00104000 packer — so the second burst repeats the
first's values.  Grade **STRONG**, not PROVEN: a write through a pointer already in a register
would be invisible to a literal scan.  ⚠ Either way, **an emulator matching a bus trace must
expect the burst twice.**

**Worst case per note-on on this path: 1 + 19 + 2 + 1 + 19 + 19 + 2 = 63 register writes = 126
word writes to the port pair.**

### While the note sounds

Every **24.6 ms** (40.69 Hz), for this voice, `sub_FACAB7` → `sub_FC7C0D` recomputes and ships
either `{chan+0x00C0, chan+0x0100, chan+0x0240}` or `{chan+0x00C0, chan+0x0100}` — §5.  Nothing
else in the image writes the device while a note is held.

A MIDI CC or panel edit whose target code is 29, 30 or 37 adds one aperiodic write of the same
registers, plus 0x0280 for code 37 — §6.

### Key-up

Velocity-zero note-on / note-off reaches `MidiNote_Dispatch`'s velocity-zero arm, which runs a
query and a retire walk and then calls `MidiNote_OffTail` (0xFB3F95).

★ **There is no "key off" register and no dedicated stop write.  A note-off is a full
re-program of the channel with release parameters.**  `MidiNote_OffTail` is byte-for-byte a
different routine from `MidiNote_OnTail` (205 of 278 bytes differ) but its **device traffic is
the same shape**, in the same order:

| # | moment | register(s) | value source |
|---|---|---|---|
| 1 | 0xFB376E | — | same part-mode 0x40 gate; the voice number comes from buffer **+11**, not +10 |
| 2 | 0xFB37AA | — | `Pack104_SetInputs_PartRecord(part)` |
| 3 | 0xFB37D0-0xFB37F5 | *(companion)* | 0x0010C000 `chan+0x0840` := 0xFF00, five `nop`s, `chan+0x0800` := 0xFF80 |
| 4 | 0xFB3802 | — | `Pack104_SetInputs_SubRecordPair(0, chan)`; staging word 0, **bit 2 set here too** (§4) |
| 5 | 0xFB3808 | **chan+0x0000** | `Dev104_WriteChanReg0` |
| 6 | 0xFB3810 → `VoiceRegs_Stage_D` → 0xFB2F4B | **all 19**, block 0 last | the repacked struct — release values |
| 7 | 0xFB3815 | **all 19 again** | the second burst, as at note-on |
| 8 | 0xFB3833 | — | `sub_FC56C4` → A |
| 9 | 0xFB3847, only if A ≠ 0 | **chan+0x0140, chan+0x0180** | staging words +0x0A, +0x0C |

### To silence

⚠ **Nothing else.**  The periodic refresh only visits voices still on `sub_FACAB7`'s active
list, so once the voice is retired the device sees no further traffic for that channel: the
last thing written is the note-off's own nineteen words, and the decay to silence is entirely
inside the chip.  `Voice_Retire_Mode20` and `ChanRec_ClearHoldAndRelease` write the companion
device only — the nine-literal census (§2) leaves no other route.

★ **That is the most load-bearing consequence of "no read-back" for an HLE**: the release
envelope is not driven from the CPU.  Whatever silences the note is internal state the firmware
programs once and then stops talking to.

### The other part modes, briefly

* **mode 0x00** (arm at 0xFB38B7): a loop over **at most four** voices, each iteration doing
  `Pack104_SetInputs_SubRecordPair` (0xFB391C) → `Dev104_WriteChanReg0` (0xFB3927) →
  `VoiceRegs_Stage_C` or `VoiceRegs_Stage_A` on a Z test (0xFB3946), i.e. up to **four** full
  19-register bursts per note-on; then once, after the loop, `sub_FC56C4` (0xFB39BC) and
  `Dev104_SetChanRegs_0140_0180` (0xFB39D1).  `MidiNote_OnTail` does **not** run.
* **mode 0x80** (arm at 0xFB3B01): one `VoiceRegs_Stage_C`.  ★ `VoiceRegs_Stage_A`, `_C` and
  `_D` all call the real packer; only `_B` (mode 0x40) uses the ROM image.
* **mode 0xC0 and the default** fall into 0xFB3C0E, which was never traced.  UNIDENTIFIED.

### The two paths that are not the keyboard

* **`NotePool8_NoteOnOff`** (0xFC3E02) — a private eight-slot pool driven by link packets whose
  byte [1] is ≥ 0xF0.  Its note-on programs 0x00104000 in the order
  `sub_FC7DAF` (0xFC3E91) → `Dev104_WriteChanReg0` (0xFC3EA1) →
  `Dev104_LoadStageBImage` (0xFC3EA9) → `Dev104_WriteAllChanRegs` (0xFC3ECD).  ★ Its **note-off
  does not touch this device at all** — it writes 0xA200/0xA280 to the companion's 0x0840/0x0800
  and nothing else.
* **`sub_FAC34D`** (0xFAC34D) — an auto-note countdown, reached from the periodic path.  It runs
  its body only when the counter at (0x151B) is non-zero and the countdown at (0x151C) — reloaded
  with the literal **4** at 0xFAC422 — reaches zero, so at most **40.69 / 4 = 10.17 Hz** (98 ms
  per note).  Both counters are set by arm 0x87 of `GlobalSetup_Dispatch`
  (`VoiceDefaults_StoreFromPackedByte`), i.e. by a global-setup message from CPU 1.  Its device
  order is identical to `NotePool8_NoteOnOff`'s: `sub_FC7DAF` (0xFAC3CC) →
  `Dev104_WriteChanReg0` (0xFAC3D7) → `Dev104_LoadStageBImage` (0xFAC3E1) →
  `Dev104_WriteAllChanRegs` (0xFAC3EC).

---

## 9. WHAT REMAINS UNKNOWN

* **Register 0x0800** — written once at power-on with 0x1100, from ROM 0xFE1313.  Outside the
  19-register per-channel map.  Whether it is block 0x20 channel 0 or a global register, and
  what it does, is UNIDENTIFIED.
* **What selects the `VoiceRegs_Stage_B` / ROM-image path**, beyond "part mode 0x40" — and what
  part-record byte +0x10 *is*.
* **What the Z test at 0xFB3946 tests**, i.e. what makes a mode-0x00 voice take `Stage_A`
  rather than `Stage_C`.
* **Part mode 0xC0** and the default arm at 0xFB3C0E — never traced.
* **Target codes 29, 30, 37** of `Voice_ApplyParamChange_Dispatch` — the three parameters a UI
  edit can push at this device.  Naming them would name three of the four registers that are
  written continuously, which is the highest-value open item here.
* **Whether the second full burst at note-on/off carries the same values** — STRONG, not PROVEN
  (§8).
* **Whether any of the 68 `Voice_ApplyParamChange_Dispatch` call sites is inside an interrupt
  handler**, which is the last hole in "the select/data pair never needs guarding".
* **Seventeen of the nineteen registers' meanings**, unchanged from
  `notes/FINDINGS-prom_c-dev104-register-map.md` §3.  ⚠ Felipe has no access to the hardware,
  so a live trace is not an available next step; the open routes stay the tone-editor UI and
  the localisation strings.
