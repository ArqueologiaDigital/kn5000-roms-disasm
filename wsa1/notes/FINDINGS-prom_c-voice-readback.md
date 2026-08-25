# Gap F answered: register block `0x0000` IS a 16-channel-per-word busy bitmap, and `0x0180 + chan` is a magnitude the firmware acts on when it falls below half scale

> ⚠ **CORRECTED 2026-08-25 (round-2 audit, F8).**  This title, §0, §3 and the §8 table
> all used to say that crossing below `0x80` **retires** the voice.  It does not.  The
> retire path — `ChanRec_Release` + `Dev10C_ChanReset` + `0xFA5CE9` — is driven by the
> *bitmap difference* alone.  What the `0x80` comparison drives is a second, different
> action: below `0x80`, **and only if the record's flag bit 2 is set** (`0xFA69D4`), the
> record goes to `sub_FA65BD`, an undecoded routine that clears flag bits 2 and 3, sets
> bit 1 and calls `0xFA62DA(rec, rec[+0x0F], 6)`.  The source header at `0xFA68DC` always
> stated this correctly; this note and the round report did not.

Round 2, 2026-08-25, prom_c (IC28, CPU 2). Written against gap **F** of
`../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`, which asks, of the two
`0x0010C000` reads:

> *"Is the first really a per-voice envelope level, and is the second really an
> active-voice bitmap of 16 channels per bank? … Both answer 0, which means 'no voice is
> sounding' and 'every voice is free', and `tg_status_r()` says so in as many words:
> answering 0 is a decision."*

Everything below is re-derived from `original_ROMs/wsa1_prom_c.ic28` by

```
python3 notes/prom_c_voice_sweep_checks.py       # 74 checks, FAILURES: 0
```

which reads **bytes**, never `prom_c/wsa1_prom_c.s` and never unidasm's text. The
conversion itself is certified by `scripts/analysis/assert_byte_identical.py`.

---

## 0. What is NOT established

* **What the `0x0180` quantity physically is.** What is proven is that the firmware
  treats it as a magnitude that FALLS and that crossing below `0x80`, with flag bit 2 set,
  sends the record to `sub_FA65BD`.  ⚠ That is **not** the retire path (see the correction
  under the title); nothing here says what `sub_FA65BD` is for.
  Nothing here ties it to amplitude, to a sample position or to time. **"Envelope" is not
  asserted anywhere in this note or in the source.**
* **What the device does on a WRITE to block 0.** Block 0 is written per channel with
  `0x8100` and with `0x7E00`; the READ uses index 0..3 and is used as a bitmap. Read and
  write are recorded separately and neither is used to argue about the other.
* **That the four "silence" registers silence anything.** They are the four the firmware
  drives to stop a channel. Nothing reads any of them back and no measurement is involved.
* Channel-record flag bits 1, 2 and 3; what `0xFA5CE9`, `0xFA6269`, `0xFA62DA` and
  `0xFA643F` do; what the RAM objects at `0x0200` and `0x041C` are.  ⚠ `ChanRec_Release`
  calls those last two with the POINTERS `0x03FE` (= `0x0200 + 0x01FE`) and `0x04E2`
  (= `0x041C + 0x00C6`), not with `0x0200` and `0x041C` themselves — corrected
  2026-08-25, round-2 audit F4.

---

## 1. The routine: `Dev10C_PollBankAndRetire` (was `sub_FA68DC`, `0xFA68DC`)

It is the **only** reader of `0x0010C000` in either image, and it contains both of the
device's reads. `Toggle14FE_AndDispatch` (`0xFB05EC`) calls it on every other pass of an
alternator that MAIN runs once per loop, and it services **one bank of sixteen channels
per call**, so each channel is looked at once every eight MAIN passes.

```
(0x0087CF) = ((0x0087CF) + 1) & 3                  ; the bank cursor, 0..3
(0x0010C000)   = bank                              ; SELECT -- the bank number, nothing added
HL             = (0x0010C004)                      ; ★ READ 1: one word for sixteen channels
new            = HL | 0x0087C7[bank]               ; OR in the HOLD mask
ended          = 0x0087BF[bank] & ~new             ; (new ^ old) & old
0x0087BF[bank] = new
rec            = 0x04E8 + 23*(bank*16)             ; the channel record
walker         = 0x0001
for i = 0..15:                                     ; the walker is shifted left in memory
    chan = bank*16 + i                             ; until it goes zero -- sixteen passes
    if walker & ended:
        if !(rec[0x12] & 1):                       ; not already released
            ChanRec_Release(rec) ; Dev10C_ChanReset(chan) ; 0xFA5CE9(chan)
    else if !(rec[0x12] & 0x81):                   ; not released, not held
        (0x0010C000) = 0x0180 + chan               ; SELECT
        v = (0x0010C004)                           ; ★ READ 2
        rec[0x15] = LOW BYTE OF ((v & 0x3FFF) >> 5)
        if rec[0x15] < 0x80 and (rec[0x12] & 4):  0xFA65BD(rec)
    rec += 23 ; walker <<= 1
```

## 2. ★★ READ 1 — register block `0x0000`, index 0..3, is a 16-channel bitmap

**Two independent witnesses, which is why this is a finding and not a reading.**

**Witness 1, the loop itself.** The cursor is masked to 0..3 (`and H,0x03`, `0xFA68ED`);
the select is that number with nothing added to it (`ld (XIX),BC`, `0xFA6901`); one word
is read from the `+4` port (`0xFA690A`); the channel number starts at `bank * 16`
(`sll 0x04,C`, `0xFA694A`) and the walker starts at bit 0 (`0xFA695C`) and is shifted left
**in memory** until it goes zero (`sllw (XIZ+0xf6)`, `0xFA69E7`) — a 16-bit word, so
exactly sixteen passes. Bit *i* of the word read at select *n* is therefore paired, inside
one loop body, with channel `16n + i`.

**Witness 2, and it is unrelated code.** The two RAM masks at `0x0087BF` and `0x0087C7`
are **four words each** and use exactly the same encoding — word index `chan >> 4`, bit
`chan & 15` — built by `Shift16_Left(1, chan & 0x0F)` at `0xFA6CE3`-`0xFA6CF6` and
used at three sites (`0xFA6D01`, `0xFA6D37`, `0xFA6EE9`). Two routines that share no code
imposing the same channel encoding on the same four-word shape is what makes "16 channels
per word, four words, 64 channels" the device's numbering rather than one routine's habit.

**Polarity.** `WA = (new ^ old) & old` is `old & ~new`: the channels that were in the mask
and are no longer. Those are **torn down** — `Dev10C_ChanReset(chan)` at `0xFA6990`, plus
`ChanRec_Release`. So a bit that goes away means the channel has stopped, and a bit that is
**set means the channel is still busy**.

★ **What this costs the emulator today.** `tg_status_r()` answers 0, so `new` is
`0 | hold`, so every channel not in the hold mask appears to have stopped **on the first
sweep after it starts** and is immediately reset and released. That is not a neutral stub:
it actively tears voices down. A device model that keeps a per-channel busy bit and clears
it when the voice ends is what this register wants; answering 0xFFFF for a bank whose
channels have been programmed would at least stop the teardown.

## 3. READ 2 — register `0x0180 + chan`, and the half-scale threshold

The select is `0x0180 + chan` (`0xFA696D` builds it, `0xFA69AF` writes it); the read is at
the `+4` port (`0xFA69B1`). Then:

```
and BC,0x3FFF      0xFA69B6
srl 0x05,BC        0xFA69BA
ld E,C             0xFA69BD    ★ TRUNCATED TO A BYTE
```

`(v & 0x3FFF) >> 5` spans 0..0x1FF, and `ld E,C` keeps the low byte — so **what the
firmware uses is bits 12..5, an 8-bit field**, and bit 13 is discarded by the truncation
rather than by the mask. That byte is cached in `rec[+0x15]` (`0xFA69C4`) and compared
against **`0x80`** (`0xFA69C7`) — half of the field's full scale. Below it, and only if the
record's flag bit 2 is set (`0xFA69D4`), the channel goes to `0xFA65BD`, which clears flag
bits 2 and 3, sets bit 1 and re-queues the record.

So: **a per-channel magnitude that falls, with a threshold at half scale.** ⚠ The action at
that threshold is `sub_FA65BD`, not retirement (see the correction under the title). An
envelope level fits and so does a remaining-sample-length counter; this note does not
choose, and the source says so at the routine.

⚠ Note what does **not** follow. The two producers of staging word 6 — which
`Dev10C_WriteAllChanRegs` sends to this same block — both write `voice[+0x27]`, a value
clamped to 0..0x7F by `Clamp_ToRange_LowByte` (`0xFA97E3`) or produced as
`random & 0x7F` (`0xFA978C`/`0xFA9EDC`). A 7-bit write and a bits-12..5 read do not line
up, so **the write side and the read side of block `0x0180` are not the same quantity**,
or not in the same units. Recorded as an inconsistency, not resolved.

## 4. The 64 channel records at RAM `0x04E8`, stride 23

★ **Count and stride are immediates**, not inferences: `ld DE,0x04E8` (`0xFA67FF`),
`add HL,0x0017` (`0xFA687D`), `cp (XIZ-7),0x40` (`0xFA6884`). 64 × 23 = 1472, so the array
is `0x04E8`-`0x0AA7` and the **last** record, channel 63, is at `0x0A91` —
`Dev10C_PollBankAndRetire` reaches exactly that record on the last pass of bank 3, from
the same two constants, which is the independent check on the count.

| off | w | set at init to | what else touches it |
|---|---|---|---|
| +0x00 | 2 | the record itself | a list link |
| +0x02 | 2 | the record itself | a list link |
| +0x04 | 2 | the record itself | a list link |
| +0x06 | 2 | the record itself | a list link |
| +0x08 | 2 | the record itself | PREV — `ChanRec_Release` does `(next+0x08) = prev` |
| +0x0A | 2 | the record itself | NEXT — `ChanRec_Release` does `(prev+0x0A) = next` |
| +0x0C | 2 | `0x041C` | a RAM object shared by all 64 |
| +0x0E | 1 | 1 | |
| +0x0F | 2 | `0x0200` | a second shared object; `ChanRec_Release` decrements its byte `[+0x01]` |
| +0x11 | 1 | 6 | |
| +0x12 | 1 | 0 | ★ the flag byte |
| +0x13 | 1 | *(not written)* | ⚠ unaccounted |
| +0x14 | 1 | the record's index | 0..63, equal to the hardware channel number |
| +0x15 | 1 | 0 | ★ the cached `0x0180` read-back |
| +0x16 | 1 | *(not written)* | ⚠ unaccounted |

**The flag byte `rec[+0x12]`.** Bit 0 = RELEASED: `ChanRec_Release` stores exactly `0x01`
and is its only writer, and four separate guards test it to skip work. Bit 7 mirrors the
channel's bit in the `0x0087C7` hold mask exactly — the arm at `0xFA6CDC` writes `0x88`
and sets that bit, its sibling at `0xFA6D07` writes `0x08` and clears it. Bits 1, 2 and 3
are recorded by the sites that write and test them and are given no roles.

## 5. The four registers this firmware drives to stop a channel

`VoiceSubsystem_Init`'s first arm — which runs **only when at least one `0x0087BF` word is
non-zero**, i.e. only when something was sounding — writes four registers per channel for
all 64:

| register | value | site |
|---|---|---|
| `0x0840 + chan` | `0xFF00` | `0xFA669A` |
| `0x0800 + chan` | `0xFF80` | `0xFA66A8` |
| `0x00C0 + chan` | `0x0000` | `0xFA66B4` |
| `0x0000 + chan` | `0x7E00` | `0xFA66C7` |

Those four constants appear nowhere else except in the three other routines that stop
channels: `Dev10C_ResetAllChannels` (`0x0800`/`0x0840` for all 64, `0xFB811E`/`0xFB8132`),
`Dev10C_QuiesceListedChans_0800_0840` (the same pair, per listed channel) and
`Dev10C_ChanReset` (`0x00C0 := 0` and block 0 `:= 0x7E00`, `0xFB0AA4`/`0xFB0AB5`). So this
is the machine's stop-a-channel set. ⚠ That it makes the channel *silent* is the obvious
reading and is not asserted.

★ This also supplies the **first meaning for register `0x00C0 + chan`** — one of the
seventeen the round-1 note left blank: whatever it carries, `0x0000` is its stopped value,
and it is one of only two registers `Dev10C_ChanReset` touches.

## 6. Where the names went

In `prom_c/wsa1_prom_c.s`, six routines lost address-only names and one was corrected:

| was | now | why |
|---|---|---|
| `sub_FA68DC` | `Dev10C_PollBankAndRetire` | §1-§3 |
| `sub_FA6528` | `ChanRec_Release` | §4 |
| `sub_FA664B` | `VoiceSubsystem_Init` | §4, §5 |
| `sub_FA7598` | `Clamp_ToRange_Word` | §10 — a signed 3-argument clamp, whole body |
| `sub_FA7602` | `DetuneCurve_LookupSigned` | §10 — named for the TABLE, not a quantity |
| `sub_FA7654` | `DetuneCurve_LookupUnsigned` | §10 |
| `Dev10C_ClearVoiceList_0800_0840` | `Dev10C_QuiesceListedChans_0800_0840` | round-1 audit F9: it never writes the list |

Two new block comments carry the tables: **"THE 64 CHANNEL RECORDS, AND WHAT 0x0010C000
GIVES BACK"** (sections A-D above) in front of `VoiceSubsystem_Init`, and **"BLOCK GROUP
0x20-0x29 IS A GROUP OF BYTE PAIRS…"** appended to the register-meanings comment in front
of `Dev10C_WriteAllChanRegs`. Six producer routines — `sub_FAA4C3`, `sub_FAA96C`,
`sub_FAACEE`, `sub_FAB0BD`, `sub_FA842D`, `sub_FA93AF` — keep their `sub_` names and gain a
★ paragraph saying which register they build, because naming a 955-byte routine after one
of its outputs would be the misleading half of a true statement.

Every renamed routine's header cites the instruction addresses, and every one of those
addresses is asserted by `notes/prom_c_voice_sweep_checks.py` or read out in the header
itself. `python3 notes/prom_c_prose_citation_check.py` — new this round — reports **0
OFF-BY citations** over the 231 instruction citations it can classify in prom_c and prom_d
(186 resolve exactly, 40 are abbreviated or paraphrased quotes it cannot anchor, 5 name an
address outside the image's converted text).

## 7. What the emulator can do with this

* `tg_status_r()` for select 0..3 should return a **per-bank busy bitmap**, bit `chan & 15`
  of word `chan >> 4`, set while a channel is sounding. Answering 0 makes the firmware
  retire every voice one sweep after it starts.
* `tg_status_r()` for select `0x0180 + chan` should return a value whose **bits 12..5**
  fall as the voice decays, and stay at or above `0x80` while the voice is alive. A model
  that is not ready to decay one should hold those bits high rather than answer 0.
* The stop-a-channel set of section 5 is four register writes a trace can be keyed on.

---

# Part II — Gap A: block group `0x20-0x29` is a group of BYTE PAIRS, and `chan + 0x0800` is `(level << 8) | rate`

Same round, same image. This half is written against gap **A**'s third question — *"which
block is a LEVEL / envelope target, and is it linear or logarithmic?"*

```
python3 notes/prom_c_reg_bytepair_check.py --selftest    # 22 stores, 10 of 10 words
python3 notes/prom_c_curve_table_census.py --selftest    # the curve <-> register bijection
```

## 8. Every register of block group `0x20-0x29` is two 8-bit fields

`Dev10C_WriteAllChanRegs` sends staging words 12..21 to registers `0x0800`, `0x0840`,
`0x0880`, `0x08C0`, `0x0900`, `0x0940`, `0x0980`, `0x09C0`, `0x0A00` and `0x0A40` of one
channel. Censusing every store into those ten words that stores a computed value gives
**22 stores over all ten words**, in two idioms and no third:

| idiom | count | shape |
|---|---:|---|
| PACK | 12 | `sll 0x08,<hi>` … `or <hi>,<lo>` |
| MERGE | 8 | `(source & 0xFF00) \| (value & 0x00FF)` — the high byte KEPT, the low replaced |
| PLAIN | 2 | a 7-bit value with bit 15 set, stored whole (`set 0x0f,WA`, `0xFAA917`/`0xFAAC99`) |

MERGE is the same split seen from the other side: it proves the boundary sits at bit 8
exactly as PACK does. ⚠ The census is a **window heuristic** over the gate-certified
listing, not a dataflow; the per-site readings quoted below were done by hand.

## 9. ★★ `chan + 0x0800` — the high byte is an envelope LEVEL, the low byte a RATE

**In this image.** Staging word 12 has exactly **four** producers — `sub_FAA4C3`,
`sub_FAA96C`, `sub_FAACEE`, `sub_FAB0BD` — and those are **exactly** the four routines in
prom_c that compute the address of `Voice_LevelPair_AttackCurve` (`0xFDEF74`, 101 bytes
descending `0xFF`..`0x09`). No other routine computes that curve's address and no other
routine stores a computed value into that word. Read out at `sub_FAA4C3`:

```
FAA62E  add XWA,0x00fdf03e        ; Voice_EnvelopeRate_Table[ tone[+0x28] ]
FAA63C  and DE,0x00ff             ;   -> the LOW byte
FAA640  ld IY,HL / sll 0x08,IY    ; the clamped level
FAA647  or IX,DE
FAA649  ld (0x00d776),IX          ; staging word 12 -> register 0x0800 + chan
```

`tone[+0x28]` is tone-record offset **40**.

**And independently, in another project, on another machine.** The KN5000 sub-CPU's
`Voice_EnvelopeRate_Table` is **byte-identical** to this one, and that disassembly's own
header for it reads:

> *"The parameter → envelope-rate table … Indexed by tonerec+40 in
> `Voice_Calc_LevelPair_PatchAtk_*`; packed as **(level << 8) | rate into TG register
> 0x800**. Monotone 0x00..0x7F."*
> — `../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s`

Same table bytes, same tone-record offset **40**, same packing, **same register number
`0x800`** — reached from two disassemblies that share no code. That is what turns a
transplanted table name into a named register.

⚠ **The one caveat, stated because the curve's direction does not settle it.** The level
curve *descends* — `0xFF` at parameter 0 down to `0x09` at parameter 100 — so whether the
byte the device receives is a "level" or an "attenuation" at the pin is not decided here.
"Level" is the sibling's word and is carried over with that caveat.

## 10. The other six of the group, and the ±50 → ±127 law

`0x0900`, `0x0940`, `0x0980` are written by `sub_FA842D` and `0x09C0`, `0x0A00`, `0x0A40`
by `sub_FA93AF` — three registers each, and those are the only routines that store a
**computed** value into them. (`sub_FA96F7` zero-fills words 15..21 at entry with
immediates and then ORs word 16's low byte into word 15's high half at `0xFA976C`; those
are the only other stores, and `notes/prom_c_dev10c_field_sources.py`, which scans the
based `lda XIX,0x00d75e … ld (XIX+n),BC` form as well as the absolute one, lists the same
routines.) Between them the
two routines make **twelve** of prom_c's thirty `Voice_EnvelopeLevel_Curve` lookups (six
each) and no other curve lookup. In every one of the six registers:

* the **high** byte is a value clamped to `0..0xFF` by `Clamp_ToRange_Word`
  (`sub_FA7598`), fed from those curve lookups;
* the **low** byte is `DetuneCurve_LookupSigned` (`sub_FA7602`) of a value first clamped to
  **−50..+50** (`push 0xFFCE / push 0x0032`, e.g. `0xFA94C0`), i.e. a **signed ±127 depth**.

`DetuneCurve_LookupSigned` is `sign(v) · Detune_Scale_Curve[min(|v|,50)]`; the 51-byte
table rises `0x00`..`0x7F` with knees at [16] and [32] and `T[50] = 0x7F`, so the law is *a
±50 control expanded to a ±127 field, coarsening as it goes*. In `sub_FA93AF` the ±50 input
is `tone[+0x3D] + tone[+0x40]` (and `+0x44`, `+0x48`…) — a common offset plus a per-register
signed byte.

⚠ **Not asserted:** that these six are envelope *stages*, nor in what order. What is
established is the byte split, the curve behind the high byte and the ±50 → ±127 law behind
the low byte.

⚠ **A transplanted name that may mislead.** `Detune_Scale_Curve` came from the KN5000
sub-CPU (51 identical bytes). In **both** images its only callers are level/parameter
packers, not a pitch path — the KN5000's own header says its `Detune_ScaleSymmetric` is
*"called from the level packer"*. The local wrappers are therefore named for the **table**
they read, not for a quantity. The KN5000 routine is **not** byte-identical to
`DetuneCurve_LookupSigned`: it takes `WA` and returns `XHL` with no stack frame, where this
one is a framed stack-argument routine. The algorithm matches instruction for instruction;
the encoding does not.

## 11. Where gap A stands after this round

| register | what it carries | round |
|---|---|---|
| `0x0000 + n` (read, n = 0..3) | **busy bitmap**, bit `chan & 15` of word `chan >> 4` | 2 |
| `0x0000 + chan` (write) | `0x8100` on a full update, `0x7E00` on stop | 2 |
| `0x0040 + chan` | key-zone record word 0 | 1 |
| `0x0080 + chan` | OUTPUT LEVEL, log2, 256 counts/octave | 1 |
| `0x00C0 + chan` | *(stopped value `0x0000` only)* | 2 |
| `0x0180 + chan` (read) | a falling magnitude; below `0x80` (with flag bit 2) the record goes to `sub_FA65BD` | 2 |
| `0x0400 + chan` | PITCH, 1/256 semitone | 1 |
| `0x0800 + chan` | **(envelope level << 8) \| envelope rate**; quiescent `0xFF80` | **2** |
| `0x0840 + chan` | byte pair; quiescent `0xFF00` | 1, 2 |
| `0x0880 + chan` | byte pair | 2 |
| `0x08C0`, `0x0900`, `0x0940`, `0x0980`, `0x09C0`, `0x0A00`, `0x0A40 + chan` | byte pair: curve-derived high byte, ±127 depth low byte | 2 |
| `0x0100`, `0x0140`, `0x0440`, `0x0480`, `0x04C0`, `0x0500 + chan` | **still nothing** | — |

Six of the twenty-two per-channel registers still have no statement of any kind against
them, and that is the honest next target.

★ One free observation the naming makes available: `0x0800`'s quiescent value `0xFF80`
reads, under §9, as level `0xFF` — the curve's index-0 entry — and rate `0x80`, which is
**one above `Voice_EnvelopeRate_Table`'s maximum `0x7F`** and therefore a value the normal
path can never produce. A rate outside the table's range as the stop value is consistent
with `0x80` being a "hold / no ramp" encoding, but nothing here tests it and it is not
asserted.
