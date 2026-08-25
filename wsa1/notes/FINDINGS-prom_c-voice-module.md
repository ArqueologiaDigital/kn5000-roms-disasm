# prom_c 0xFB0504-0xFB405E — the MIDI message path and the 64-voice engine

Round 6, 2026-08-25. 15,195 contiguous bytes, 32 routines, one module.

Everything quantified below is re-derived from `original_ROMs/wsa1_prom_c.ic28`
by

```
python3 notes/prom_c_voice_module_check.py --selftest
```

which matches **bytes**, never unidasm's text and never the `.s` file, and whose
`--selftest` asserts the LAST element of every table it reads plus two negative
controls. The conversion itself is proven by
`python3 scripts/analysis/assert_byte_identical.py`.

---

## 0. What was converted, and why this range

The lane's frontier tool ranks unconverted callees of converted code. **It was
ranking noise**, and finding that out was the first result of the round — see §6.
With a phantom-free frontier the real answer was five targets, four of them in one
neighbourhood, all called from MAIN:

```
0xFA3127  0xFB0504  0xFB05EC  0xFB060A  0xFB0A0D
```

Following 0xFB0504 outward closes at 0xFB405E: the note handler `MidiNote_Dispatch`
(0xFB3F36) and every routine it reaches — the four-way part-mode switch, the four
parameter-compute routines, the four register-stage routines, the six voice
queries and the three retire actions — are all inside that range. The block is a
**closed subsystem**, not an address window.

## 1. The chain, end to end

```
Link_Ch0_AppendToRing (0xF98D9A)   appends bytes to the ring at 0x00E2F1
        v
MAIN  lda XBC,0x00E2EB / push / call 0xFB060A          (0xF98CA4-0xF98CAA)
        v
MidiIn_ParseRingAndDispatch        switch on the status nibble; loops until the
        v                          ring is dry.  80 90 B0 C0 D0 E0 F0, no 0xA0
MidiNote_Dispatch                  the 0x90 arm ONLY
        +-- velocity != 0 -> MidiNote_OnByPartMode + MidiNote_OnTail
        +-- velocity == 0 -> VoiceQuery_Tag80_PartNote + VoiceList_RetireByMode
                             + MidiNote_OffTail
        v
VoiceParams_Compute_{A,B,C,D} -> VoiceRegs_Stage_{A,B,C,D}
        v
Dev10C_WriteAllChanRegs (0xFB713A) and Dev104_WriteAllChanRegs (0xFB77EF)
```

## 2. The packet, and the error this section is here to record

Each arm carries its own `cp DE,n` guard and its own `decw n,(count)`, and the two
always agree. Derived from those bytes by checker section 1b. `0xA0` — the MIDI
status for polyphonic key pressure — has no arm at all and falls to the default.
⚠ *"so this instrument has no per-key aftertouch"* is the tempting next sentence
and it is not written here: this is one internal message path, the format is
MIDI-derived rather than MIDI, and what arrives on the physical MIDI IN is a
different question.

| status | bytes | handler |
|---|---:|---|
| 0x80 | **6** | 0xFC2600 |
| 0x90 | 4 | `MidiNote_Dispatch`, or 0xFC3E02 when byte [1] >= 0xF0 |
| 0xB0 | 4 | 0xFAFDA5 |
| 0xC0 | **5** | 0xFB6BA8 |
| 0xD0 | 4 | 0xFB0013 |
| 0xE0 | 4 | 0xFB0132 |
| 0xF0 | 4 | 0xFB0338 |
| default | — | drains the ring **one byte at a time** until it is empty |

> ⚠ **A first draft of this section, and of the block comment, said "every arm
> consumes four bytes, the 0xC0 arm alone five", and put 0x80 and 0x90 together on
> the note handler.** The 0x80 arm consumes **six** bytes and calls 0xFC2600; it
> never reaches the note handler. The claim came from reading two arms and
> generalising. Checker section 1b now derives the length and the handler for
> every arm from that arm's own bytes, and asserts all eight rows.
>
> What survives, and is now stated properly: **the format is MIDI-DERIVED, not
> MIDI.** The high nibble is a message type that coincides with a MIDI status for
> 0x90/0xB0/0xC0; the lengths are its own; and 0x80 is not "note off" here.

For the four-byte statuses the layout is

```
[0] status byte, low nibble carried through to the handler
[1] part index 0..0x20, or >= 0xF0 for the second note handler
[2] data 1   — note number (0x90), or controller number (0xB0)
[3] data 2   — velocity, or controller value
```

Three more facts about the loop, all in checker section 1b:

* the **default arm is a resync**, not a skip: it drops bytes one at a time until
  the count is zero, so an unrecognised status byte costs the whole buffer;
* the routine **loops** — L is 1 on entry, only the "too few bytes" exit sets it
  to 0, and the tail jumps back while it is non-zero — so one call drains as many
  packets as the ring holds;
* `call 0xF98CB9` (KeyEvents_ToLink) at 0xFB09FE is on the **loop tail**, executed
  once per iteration whatever the status was. It is not one of the arms.

The layout is not read off the parser — it is read off `MidiMsg_SendBootSequence`
(0xFB0A0D), which builds four packets from literals and hands them to the same
three handlers the parser's 0xC0, 0xB0 and 0x90 arms call:

| bytes | handler | reading |
|---|---|---|
| `C0 00 00 00 00` | 0xFB6BA8 | program change, five bytes — the 0xC0 arm's own guard is `cp DE,5` |
| `B0 00 07 00` | 0xFAFDA5 | **controller 7 = MIDI channel volume**, value 0 |
| `90 00 30 01` | `MidiNote_Dispatch` | note 0x30, velocity 1 |
| `B0 00 78 7F` | 0xFAFDA5 | **controller 120 = MIDI all sound off**, value 127 |

Two standard controller numbers landing in byte [2] with their values in byte [3]
is not something a wrong field layout survives.

⚠ **Why a note-on at velocity 1 is in a boot sequence that ends with All Sound Off
is not established.** "Priming the engine" is the obvious reading and it is not
asserted.

## 3. The ring is self-proving

`MidiIn_ParseRingAndDispatch` masks the read cursor with `0x0FFF` and adds
`descriptor + 6`. With MAIN's argument that puts the ring at **0x00E2F1-0x00F2F0**,
and:

* 0x00F2F1 — the byte immediately after — is the main loop's countdown, a variable
  `notes/FINDINGS-prom_c-ram-image.md` already documented, boot value 100;
* the ring's own power-on image is **4096 consecutive zero bytes** in the ROM
  (0xFCB4FC-0xFCC4FB, the RAM-image source for that range), and the two bytes
  after that run are `64 00` = 100.

A wrong base or a wrong size does not land on both edges of a 4096-byte zero run.

### This answers a question an existing header had to leave open

`Link_Ch0_AppendToRing`'s header said *"Unknown: what 0x00E2EF counts — it is
written here and read by nothing that names it."* The descriptor has **four**
fields:

| offset | address | field |
|---|---|---|
| +0 | 0x00E2EB | u16 WRITE index — the producer's |
| +2 | 0x00E2ED | u16 READ index — the parser's |
| +4 | 0x00E2EF | u16 **BYTE COUNT** — `cp DE,4` guard, `decw 4` per packet |
| +6 | 0x00E2F1 | the 4096-byte ring |

The old sentence was right about the *literal census* and wrong about the *fact*:
the parser reaches +4 through the descriptor pointer MAIN pushes, so no
instruction anywhere spells 0x00E2EF and `prom_c_xrefs.py` could not see it.

> ★ **General lesson, worth more than this one field.** A literal-address census
> cannot see a structure MEMBER reached through a base pointer. "No reference
> found" is a much weaker statement for a struct field than for a routine, and
> headers that record a searched negative about a field should say which kind it
> is. The header has been corrected in place.

## 4. The two data structures

**The voice record** — 64 records of 0x44 = 68 bytes at RAM **0x00003BCF**
(**0x00003BCF-0x00004CCE**; record 63, the last, occupies 0x00004C8B-0x00004CCE).

> ⚠ **Corrected 2026-08-25.** This line, and the matching line in the `.s`, used to
> give the end as `0x0000456E` — 2,464 bytes from the base, i.e. 36.2 records, which
> contradicts the "64 × 0x44 = 4352" in the same breath by **1,888 bytes**. The
> checker printed the same wrong string from a bare `print`, the only number in its
> section 5 that its own `check()` did not cover. It is now computed from the base,
> stride and count read out of the ROM operands and asserted on record 63.

The index is *both* the record index and the hardware channel number, and the
proof is the smallest routine in the block. `Dev10C_ChanReset` (0xFB0A8B) takes one
argument `n`, writes device 0x0010C000 registers `n` and `n + 0xC0`, and then
clears the word at `0x3BCF + n*0x44 + 1`. One argument, two uses.

The bound 0x40 appears twice as a guard (`cp H,0x40` at 0xFB3EA2 and 0xFB3FDE) and
is also the list terminator: `VoiceList_RetireByMode` and
`VoiceRecords_InitFromAlloc` both walk a one-byte-per-voice list and stop at the
first byte >= 0x40. And 64 is the channel count
`notes/FINDINGS-prom_c-tone-generator.md` derives independently, from the
`block*0x40 + channel` register numbering of both devices.

**The part record** — 300 bytes (0x012C) each, reached through the pointer array at
RAM **0x00001523**: `mul BC,0x012c` then `ld XWA,(XBC+0x1523)`.
`MidiNote_Dispatch` refuses a part index >= 0x21, so there are 33.

⚠ 0x21 is a **bound read off one guard**, not a length read off a terminator.

## 5. Four families of four, and four orphans

`MidiNote_OnByPartMode` switches on `part_record[0x10] & 0xC0` — two bits, four
values, four arms — and each arm pairs a `VoiceParams_Compute_*` with a
`VoiceRegs_Stage_*`.

Arm 0x00 names *two* staging routines because it is a **loop over at most four
voices**: `add L,C` / `cp L,4` / `jrl C` closes it at 0xFB3958, the body stops at
`cp H,0x40` on the next voice number, and a `jr Z` at 0xFB3946 picks
`VoiceRegs_Stage_A` over `VoiceRegs_Stage_C` per voice. ⚠ What that Z tests is not
established.

The four staging routines are **two families of two**, and that is measured, not
asserted: intersecting their `call` sets gives A∩B = 20 shared, C∩D = 18 shared
(C's set is a strict *subset* of D's, which adds exactly 0xFC35B8 and 0xFC369F),
and every cross-family intersection is 4 or 6.

Four routines in the block — **0xFB0B95, 0xFB1FB1, 0xFB289A, 0xFB2F74** — have no
`call`, no `calr`, no `jrl`, no `jp` and no 24-bit literal anywhere in the 512 KiB
image. Each sits immediately in front of a much larger routine with the same
prologue, and in all four pairs the orphan's `call` targets are a **strict subset**
of the big routine's — with all four big routines adding **the same three**
callees the orphans lack: `MemCopyWords` (0xF9A038), 0xFA6BB5 and 0xFC376C.

"An earlier version the linker kept" is the obvious reading. **It is not
asserted.** The routines are named `sub_FB0B95` and friends, and the census is a
**searched negative**: a target computed at run time is invisible to it.

## 6. ★★ The frontier tool was ranking phantoms — 141 of 146

`notes/prom_c_frontier.py` re-disassembles every converted span **linearly**. Half
of prom_c's converted bytes are DATA — the EQ frequency table, the two 128-entry
mixer-gain curves, the 390-byte descriptor-string pool, the pointer tables — and a
linear decode of a float table produces plausible-looking `jrl` instructions at
random offsets. Its own LIMITS section says so; the *ranking* did not.

`notes/prom_c_frontier_src.py` computes the same frontier from the `.s` file's own
instruction LINES instead. A `.long` line cannot be mistaken for a `call`.

```
$ python3 notes/prom_c_frontier_src.py --phantoms      # before this round
  prom_c_frontier.py (linear decode) :  146 target(s)
  this script        (source lines)  :    5 target(s)
  in BOTH                            :    5
  linear-only (phantom candidates)   :  141
  source-only (linear decode missed) :    0
```

**141 of 146 were noise, and the 5 real ones were a strict subset.** Choosing
targets by "most-called first" from that ranking means choosing by an artefact of
decoding data as code. The source-based frontier also carries a completeness
check — it prints every transfer line with a literal operand that its patterns did
*not* match, and a first draft of those patterns silently dropped twelve real
transfers (conditional `jrl nz, (...)` forms and eight-hex-digit spellings) before
that check was added.

After this round the same comparison reads 232 vs 91, still 141 linear-only, still
0 source-only.

### The frontier GREW, and that is the correct outcome

5 targets / 5 sites → **91 targets / 236 sites**. Converting a module makes its
callees visible; a frontier that shrank would mean the round converted leaves. The
busiest new targets are 0xFA7F28 (12 sites), 0xFC4B2E (10), 0xFC6803 (9), 0xFA727D
(7), 0xFB5D05 (7), 0xFB6272 (7) — and the 17-to-26 small helpers each
`VoiceRegs_Stage_*` calls are contiguous in 0xFA81xx-0xFAB7xx. That block is the
obvious next target and every routine in it now has a named caller.

## 7. 0xFE1280-0xFE12B4 decoded — seven small tables

The previous comment there read *"53 bytes, NOT decoded … the census finds twenty
citations … that pins fields and not edges."* Two things changed together:
converting this module gave four of the tables real consumers, and a **per-byte**
census (rather than a census of the addresses that happened to be quoted) finds
**41** literal sites whose distribution fixes the edges.

| address | contents | sites |
|---|---|---|
| 0xFE1280 | `01 02 04 08 10 20` — 1<<0 … 1<<5 | 4 |
| 0xFE1286 | `01 04 10 40` — the even bit positions | 2 |
| 0xFE128A | `02 08 20 80` — the odd bit positions | 2 |
| 0xFE128E | eight words, low byte 0x80, high bytes 60 62 64 65 67 69 6B 6C | 1 |
| 0xFE129E | `"WSA1 EXTBD"` + NUL | 1 |
| 0xFE12A9 | `00 01 02 03` | 3/2/1/1 |
| 0xFE12AD | `03 0C 30 C0` — four 2-bit field masks | 5/3/2/2 |
| 0xFE12B1 | `00 02 04 06` — their shift counts | 5/3/2/2 |

★ The mask table and the shift table are cited **the same number of times, entry
for entry** — 5, 3, 2, 2 — and each pair of sites is a dozen bytes apart in the
same routine, feeding `Shift8_LogicalRight` (0xFCA0BA block) as
`(field & mask) >> shift`. Two four-entry tables read as a pair is in the census,
not in the eye.

⚠ 0xFE128E has **one** citation, so its count is the space to the next object and
not something a reader established. Its high-byte gaps are 2,2,1,2,2,2,1 — the
step pattern of a major scale — which is suggestive and is **not** asserted.

## 8. What this block does NOT establish

* What any tone-generator register **means**. This module computes values and
  hands them to two already-converted writers whose own headers say the register
  semantics are unknown.
* What any of the 17-to-26 helpers per staging routine computes — all still
  `.incbin`.
* What part-record byte +0x10 is, beyond "its top two bits choose one of four
  arms".
* What the voice record's mode field `(record+1) & 0x3C` means. Four values have
  arms (0x04, 0x08, 0x10, 0x20); nothing here says a fifth is impossible, only
  that the code has none.
* What arm 0xC0 of `MidiNote_OnByPartMode` does — 0xFB3C0E was not traced.


---

## 9. How the block was produced, and what is disposable

```
python3 notes/llvm_roundtrip_autoforce.py c 0xFB0504 0x3B5B --quiet > blk.s
python3 notes/prom_c_listing_prep.py      blk.s --prefix KX      > blk.pretty.s
python3 notes/prom_c_apply_headers.py     blk.pretty.s labels.txt headers.txt > blk.final.s
python3 notes/prom_c_verify_fragment.py   c 0xFB0504 blk.final.s
#   -> OK: 15195 bytes, 0xFB0504-0xFB405E, byte-identical to the ROM
# splice into prom_c/wsa1_prom_c.s, splitting the .incbin at 0x02D142:
#   .incbin ..., 0x02D142, 0x0033C2      (0xFAD142-0xFB0503)
#   <the block>
#   .incbin ..., 0x03405F, 0x002DAB      (0xFB405F-0xFB6E09)
python3 scripts/analysis/assert_byte_identical.py
```

`labels.txt` (239 rows: 32 routine names plus one internal `__FBxxxx` name per
branch target) and `headers.txt` (the 32 header blocks) were **inputs to a
mechanical spelling pass** and their entire output is now in
`prom_c/wsa1_prom_c.s`. They are disposable: nothing in this note or in the source
depends on re-reading them, and every NUMBER either of them carried is re-derived
from the ROM by `notes/prom_c_voice_module_check.py`, which is in the repository
next to what it measures. The listing pipeline is reproducible from the four
commands above.

⚠ One arithmetic slip worth recording because the gate caught it and nothing else
would have: the trailing `.incbin` skip was first written `0x03105F` instead of
`0x03405F` — `0xFB405F − 0xF80000` is 0x3405F. The rebuilt image differed at byte
213088, which is exactly 0xFB405F. **A `.incbin` offset is the one thing in this
workflow that the fragment verifier cannot check**, because the fragment verifier
never sees it; only the whole-image gate does.

---

## 10. Where the next round should go, measured

`python3 notes/prom_c_frontier_src.py --clusters` groups the frontier into runs of
targets no more than 0x400 apart. Top six after this round:

| cluster | targets | sites | extent |
|---|---:|---:|---:|
| 0xFA900A-0xFAB0BD | 19 | 36 | 8,371 |
| 0xFA7E2C-0xFA842D | 10 | 33 | 1,537 |
| 0xFC4B2E-0xFC4DBD | 6 | 31 | 655 |
| 0xFA664B-0xFA72B3 | 8 | 28 | 3,176 |
| 0xFAB5A5-0xFABCF9 | 10 | 18 | 1,876 |
| 0xFB454C-0xFB49EB | 5 | 18 | 1,183 |

The first, second and fifth are the same thing: the per-parameter helpers the four
`VoiceRegs_Stage_*` routines call. Taken together, **0xFA7E2C-0xFABCF9 holds 40 of
the 91 frontier targets and 89 of the 236 sites** in 16,078 bytes, and every one of
those routines now has a named caller with a documented argument list. That is the
next module.

```
$ python3 notes/prom_c_frontier_src.py --range 0xFA7E2C-0xFABCF9
  RANGE 0xFA7E2C-0xFABCF9  ->  40 target(s), 89 site(s), 16078 byte(s) wide
```

> ⚠ **Corrected 2026-08-25: this used to say 39 and 87.** Those were three
> `--clusters` rows added by hand (19+10+10 targets, 36+33+18 sites) and presented as
> if `--clusters` had printed a row for the range — it never did. Hand-summing dropped
> the one-target cluster at 0xFA8BDD (2 sites), which lies *inside* the range. The
> `--range` option above exists so that a range census is produced by the tool
> instead of by arithmetic on its output.

⚠ A cluster is a hint at a boundary, never a proof of one. The extents above are
first-target-to-last-target distances, not routine tilings.
