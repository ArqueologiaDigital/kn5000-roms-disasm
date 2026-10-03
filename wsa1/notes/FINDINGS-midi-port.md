# Serial channel 0 is the MIDI port — the two interrupt handlers, and (0xA0)

**Established 2026-08-24 while converting prom_a.** `prom_a/wsa1_prom_a.s`
already asserted "serial channel 0 = the MIDI port" from traffic. This note
converts the two interrupt handlers that carry that traffic and reads the RAM
protocol out of them.

Both handler bodies are in **prom_a**, reached through prom_b thunks:

| vector | slot | thunk | body |
|---|---|---|---|
| INTRX0 (receive) | `0xFFFF60` | `0xF40714` → | `MIDI_RX_Byte` @ `0xFA5496` |
| INTTX0 (transmit) | `0xFFFF64` | `0xF40718` → | `MIDI_TX_Ready` @ `0xFA542F` |

## (0xA0) is the System Real Time transmit-request bitmap

`MIDI_TX_Ready` is a five-way priority test on `(0xA0)`, and each arm writes one
byte into `SC0BUF` and clears its bit:

| bit | byte | MIDI message | written at |
|---|---|---|---|
| 0 | `0xF8` | TIMING CLOCK | `0xFA5457` |
| 1 | `0xFA` | START | `0xFA5467` |
| 2 | `0xFB` | CONTINUE | `0xFA546F` |
| 3 | `0xFC` | STOP | `0xFA544F` |
| 4 | `0xFE` | ACTIVE SENSING | `0xFA545F` |

The **priority order is not the bit order**: clock, then active sensing, then
start, continue, stop. Timing clock first is the right choice — it is the one
message whose jitter is audible.

When no bit is set, it pulls a byte from the output queue through the prom_b
routine at `0xF41DF0` (`0xFFFF` means empty). When nothing at all is left it
writes `0xFD` to `(0x77)`; the work poster at `0xFA590F` writes `0xDD` to the
same byte, so `(0x77)` is a one-byte mailbox to the foreground, not a register.

**This names an idiom that appears all over the timer handlers.**
`or (0xA0),n` followed by `call 0xF40724` (a thunk for `0xFA590F`) is
*"queue this MIDI real-time byte and wake the sender"*. Sites converted so far:

| site | bit | message |
|---|---|---|
| `INTT1_Tick` `0xF82D3F` | 4 | ACTIVE SENSING |
| `INTT1_Tick` `0xF82D92` | 3 | STOP |
| `INTT1_Tick` `0xF82DC0` | 0 | TIMING CLOCK |
| sequencer tick `0xF82F7D` | 1 | START |

## Active Sensing, both directions

* **Send.** `INTT1_Tick` runs a counter at `(0x9D)` from 0 to `0x86` and requests
  bit 4 on the wrap — **every 135 timer-1 ticks**.
* **Receive timeout.** `MIDI_RX_Byte` zeroes `(0x9C)` on *every* incoming byte
  (`0xFA54AE`), and `0xFA5509` sets bit 7 of `(0x9E)` when a `0xFE` arrives.
  While that bit is set, `INTT1_Tick` counts `(0x9C)` up and gives up at `0xA5` —
  **166 ticks** — clearing bit 7 and setting bit 5 of `(0x9E)`.

At the 488.28 Hz that `notes/FINDINGS-system-clock.md` derives for timer 1, that
is **send every 277 ms, give up after 340 ms** — one either side of MIDI 1.0's
300 ms active-sensing rule, which is what a correct implementation looks like.

⚠ **This is a consistency check, not a fourth lever on fc.** The window is wide.
At 24 MHz the same counts give 323 ms and 397 ms; the *timeout* would still be on
the right side of 300 ms, only the send interval would not. Treat it as
corroboration of the note that already settles fc, not as a new derivation. That
note's lever B — `(0xA1)`, the gap between incoming `0xF8` bytes, converted to
TREG5 at `0xFA553E` — is the strong argument and it is already written up there.

## The receive side's three paths

`MIDI_RX_Byte` saves all seven 32-bit registers and splits on the byte:

| byte | path | target |
|---|---|---|
| bit 7 clear | data byte | `0xFA5763` |
| `0x80`-`0xF7` | status byte | inline: becomes running status in `(0x9A)`; `0xF7` (END OF EXCLUSIVE) closes an in-progress SysEx through `0xF41E3C` |
| `0xF8`-`0xFF` | System Real Time | `0xFA5504` |

Before any of that it tests `SC0CR & 0x1C`; if any of those three bits is set it
takes `MIDI_RX_ErrorReset` (`0xFA5418`) instead, which reads `SC0BUF` to clear
the condition, drops running status, sets bit 3 of `(0x9E)`, bumps an **8-bit**
error counter at `(0x0931)` and returns — **the parser never sees a byte that
arrived with an error**. (⚠ This line said "16-bit" until 2026-08-25; see the
correction below.)

`(0xA9)` is the SysEx state byte: bit 0 armed, bit 1 in-message, bit 5 seen.
⚠ Bit 5 is still uncorroborated. Bits 0 and 1 no longer are — converting
`MIDI_RX_SysExStart` and `MIDI_RX_SysExData` shows bit 0 being set the moment
`0xF0` arrives and bit 1 only when the identifier byte is one the machine
accepts.

## ★ The parser is RESUMED, not called — the register context at `0x0900`

**Established 2026-08-25, converting `0xFA5400-0xFA5941`.** This is the
structural fact the rest of the parser only makes sense against.

`MIDI_RX_Byte` pushes all seven 32-bit registers on the **stack** — those belong
to whatever was interrupted — and then calls `MIDI_Parser_LoadContext`
(`0xFA5884`), which **loads all seven from a fixed RAM block at `0x0900`**. At
the end it calls `MIDI_Parser_SaveContext` (`0xFA58A1`), which writes them back,
and only then pops the interrupted code's registers.

```
        push XWA .. XIZ          <- the interrupted code's registers, to the stack
        calr MIDI_Parser_LoadContext     <- the PARSER's registers, from 0x0900
          ... one incoming byte is parsed ...
        calr MIDI_Parser_SaveContext     <- the parser's registers, back to 0x0900
        pop  XIZ .. XWA
```

So the parser has its **own persistent register set that survives between
incoming bytes**, and it uses it: `C` holds the first data byte of a
two-data-byte message from one interrupt to the next (`0xFA57DB` writes it,
`0xFA5813` reads it, and a whole MIDI byte time passes in between). Reading this
code as ordinary subroutine code — where registers die at the `ret` — gets it
wrong.

The block is 28 bytes, `0x0900`-`0x091B`, in the order `XWA XBC XDE XHL XIX XIY
XIZ`. That it is seven entries and not eight is checked three ways:
`MIDI_Parser_ClearContext` (`0xFA58CC`) zeroes exactly those same seven longs,
both routines `ret` after exactly seven, and an eighth load would start where
the store block does.

## ★ `MIDI_StatusDispatch_Table` — the table that identifies the whole block

> Renamed 2026-08-25 (round-1 audit F5). It was `MIDI_MessageLength_Table`, and
> that name was wrong about the object: every entry is a 32-bit **code
> pointer**, so the name promised `.long 2,2,2,…` and delivered handlers. The
> message length is only *implied*, by which handler a status is grouped onto.
> The grouping argument below is what it always was.

`MIDI_RX_DataByte` (`0xFA5763`) forms `(running_status & 0x70) >> 2` and jumps
through an **eight-entry table of LE32 pointers at `0xFA578E`**. The count is
fixed by that arithmetic, not by inspection: `and A,0x70` leaves three
significant bits and `srl 2` turns them into a 0..28 byte offset, so slot 7 is
the last the code can form — and slot 7 ends at `0xFA57AE`, which is the `RET`
slot 2 points at. A ninth entry would overlap it.

| index | status | MIDI message | target |
|---:|---|---|---|
| 0 | `0x8n` | Note Off | `MIDI_RX_AwaitSecondByte` |
| 1 | `0x9n` | Note On | `MIDI_RX_AwaitSecondByte` |
| 2 | `0xAn` | **Poly Key Pressure** | `MIDI_RX_Drop` — **a bare RET** |
| 3 | `0xBn` | Control Change | `MIDI_RX_AwaitSecondByte` |
| 4 | `0xCn` | Program Change | `MIDI_RX_DeliverTwo` |
| 5 | `0xDn` | Channel Pressure | `MIDI_RX_DeliverTwo` |
| 6 | `0xEn` | Pitch Bend | `MIDI_RX_AwaitSecondByte` |
| 7 | `0xFn` | System Common | `MIDI_RX_SystemCommon` |

That is **exactly** the MIDI 1.0 data-byte count for each status — two data
bytes for `0x8n 0x9n 0xBn 0xEn`, one for `0xCn` and `0xDn`. Nothing was assumed
to produce it: the four addresses are read out of the ROM and the grouping falls
out. It is what turns "this block talks to a UART" into "this block is a MIDI
parser".

★ **Slot 2 is the finding. Polyphonic Key Pressure is the one channel-voice
message this instrument discards.** Its slot points at `0xFA57AE`, a bare `ret`,
and the two data bytes that follow are dropped as well because bit 6 of `(0x9E)`
is never set. It is the only slot pointing there. Every other channel-voice
message is delivered.

## ★ Under overload it sheds note STARTS and always keeps note ENDS

`MIDI_RX_SecondDataByte` (`0xFA57DE`) has two free-space tests, not one.

The ordinary one is "is there room": `cp (XIX+0xfe),0x0004` before appending
three bytes, and `cp (XIX+0xfe),0x0003` before appending two. Each threshold is
**one greater than the number of bytes about to be written**, which is what
makes `(0x600D1C)` a *free* count rather than a used one — the sense is derived,
not assumed.

Before that comes a much larger test:

```
	cp   (XIX+0xfe),0x0040      ; free space still comfortable?
	jr   ugt, deliver           ; yes -> nothing special
	and  D,0xf0
	cp   D,0x90                 ; a Note On?
	jr   nz, deliver
	cp   E,0                    ; velocity zero = a note END
	jr   nz, RET                ; a real note START -- THROW IT AWAY
```

When free space falls to `0x40` or less, a Note On with **non-zero** velocity is
discarded, while a Note On with velocity zero — which is how MIDI spells a
release under running status — falls through and **is** delivered. So an
overloaded input loses note starts and never loses note ends, which is exactly
what stops notes sticking on. ⚠ The sense of the velocity test is worth reading
twice: `jr nz` after `cp E,0` goes to the `ret`, so it is the *non-zero*
velocity that is dropped.

## System Common, and the two SysEx identifiers

`MIDI_RX_SystemCommon` (`0xFA5830`) clears running status **first and
unconditionally** — the MIDI 1.0 rule — then makes exactly three compares:

| status | message | handling |
|---|---|---|
| `0xF0` | System Exclusive | `MIDI_RX_SysExStart` |
| `0xF2` | Song Position Pointer | two data bytes; sets `(0x9E)` bits 6 and 1 |
| `0xF3` | Song Select | one data byte, straight into `MIDI_RX_DeliverTwo` |
| anything else | | **RET** — `0xF1` MTC Quarter Frame and `0xF6` Tune Request are ignored |

Bit 1 of `(0x9E)` exists only because of the `0xF2` case: the status was zeroed
when the `0xF2` arrived, so `MIDI_RX_SecondDataByte` restores `D = 0xF2` from
that flag when the second data byte turns up.

`MIDI_RX_SysExStart` (`0xFA584D`) arms `(0xA9)` bit 0 for **every** SysEx, but
sets bit 1 — "accepted" — for **exactly two identifier bytes, `0x50` and
`0x7E`**. Anything else stays armed but never accepted, so the rest of that
message reaches `MIDI_RX_SysExData` and is discarded there: that is how a device
ignores another maker's SysEx without losing track of where it ends.

`0x7E` is MIDI's Universal Non-Real Time identifier. `0x50` is a manufacturer
identifier and, by the shape of the test, must be this machine's own. ⚠ **Which
company holds `0x50` is not established here** — it needs the MMA's assignment
list, which is not in this tree. Do not write a company name into the source on
the strength of the byte alone.

## ⚠ Correction: `(0x0931)` is an 8-bit counter, not 16-bit

`MIDI_RX_ErrorReset`'s comment said "(0x0931) = an error counter, 16-bit". It is
**8-bit**. The instruction is `c1 31 09 61`, and the `0xC1` prefix selects
MAME's `s_mnemonic_c0` table, whose opcode `0x61` is `op_INCBIM` — *byte*
immediate memory; the 16-bit form would need a `0xD1` prefix, whose `0x61` is
`op_INCWIM` (`../mame/src/devices/cpu/tlcs900/900tbl.hxx`, tables parsed by
`notes/midi_parser_check.py`).

It has to be 8-bit: `(0x0932)`, the byte immediately after it, is the
**input-queue overflow counter**, bumped by `MIDI_RX_DeliverTwo` and
`MIDI_RX_DeliverThree`. A 16-bit `(0x0931)` would overlap it. Corrected in
`prom_a/wsa1_prom_a.s` in the same edit as this note.

## The module ABI, and this build's pad byte

`MIDI_EntryThunks` (`0xFA5400`) is **six 4-byte slots**, built exactly like
`LCD_EntryThunks` at `0xF8E800`: each slot is either a 4-byte `jp` or a `ret`
padded with three `nop`s. **Only slot 3 is live**, holding `jp MIDI_Reset`.
⚠ Nothing that reaches the table has been found, so nothing says *when* the MIDI
subsystem is reset.

⚠ `0x0E` — `RET` — is this build's inter-module pad byte throughout; prom_a
alone has **35 runs of 64 or more** of them, and the table sits at the end of a
152-byte one. That means the pad and slot 0's own `ret` are the *same byte*, so
a scan for the run measures 153 and stops one byte inside the table. **The
boundary comes from the 4-byte stride, not from where the `0x0E` stops.** This
is the same trap that made an earlier draft of `FINDINGS-fonts.md` read 1200
bytes of `0x0E` padding in prom_b as glyph data.

## `MIDI_UART_Configure` (`0xFA58F0`) and the branch that never runs

`SC0MOD = 0x29` (8-bit UART, clocked from the baud-rate generator),
`SC0CR = 0x00`, `BR0CR = 0x0E` (divide by 896). 31250 × 896 = 28,000,000, which
is where `notes/FINDINGS-system-clock.md` gets fc = 28 MHz.

The alternate `BR0CR = 0x0C` at `0xFA5903` is guarded by
`cp (0xFFFFF8),0x24` — and **`0xFFFFF8` holds `0x02`**, a byte inside this
image's `BUILD_TAG`, so the compare always fails and the branch is dead. Checked
by `notes/midi_parser_check.py`.

`ei 0x06` … `ei 0x00` brackets the whole thing: on this part `ei n` **sets** the
interrupt mask level, so the pair is a critical section and the higher number is
the *disabled* end — see `notes/llvm-mc-tlcs900-spellings.md`.

## ★ There are TWO MIDI state machines, and they have the same shape

**Established 2026-08-25, converting `0xFA5942-0xFA5AEA`.**

The interrupt-time parser keeps three bytes of state. The **foreground
consumer** at `MIDI_DrainQueue` (`0xFA5942`) keeps its own private trio, used
the same way, bit for bit:

| | interrupt side | foreground side |
|---|---|---|
| running status | `(0x9A)` | `(0x0960)` |
| flags | `(0x9E)` | `(0x0963)` |
| SysEx state | `(0xA9)` | `(0x0964)` |
| "a first data byte is pending" | bit 6 | bit 6 |
| clear mask on a new status | `and …,0xbd` | `and …,0xbd` |
| status-nibble jump table | `0xFA578E`, 8 entries | `0xFA5A48`, 8 entries |
| first data byte held in | register `C` | RAM `(0x0961)` |

The division of labour is that the interrupt side takes bytes off the UART and
packs them into a queue; the foreground side takes them out again (prom_b
`0xF41D18`) and turns each complete message into an application event (prom_b
`0xF41DD4`). The foreground side has to use RAM where the interrupt side uses a
register, because only the interrupt side has the persistent register context.

⚠ **One deliberate difference, and it matters for the Poly Key Pressure
finding.** The foreground table sends `0xAn` to the ordinary two-data-byte
handler; the interrupt table sends it to a bare `RET`. The foreground code is
*willing* to handle Poly Key Pressure — but nothing ever reaches it, because the
interrupt parser discards the message before it is queued. So "the WSA1 ignores
Polyphonic Key Pressure" is a statement about where the decision is made, and
the foreground table is not evidence against it.

The foreground table's length is asserted more strongly than the interrupt
one's: `cp BC,7` / `jr ugt` rejects any index above 7 **before** the scale by 4,
so eight is the table's declared size rather than a consequence of a mask.

### The message builders

`MIDI_Fg_Deliver2` (`0xFA5A8B`) and `MIDI_Fg_Deliver3` (`0xFA5ABE`) are the same
routine with one more field. Each reserves a frame, fills it, and hands it to
prom_b `0xF41DD4` with a length — and **the frame size and the length argument
agree**, which is what makes them message builders rather than copies:

| | frame | length pushed | fields |
|---|---|---|---|
| `MIDI_Fg_Deliver2` | `link XIZ,0xFFFE` | 2 | status, data |
| `MIDI_Fg_Deliver3` | `link XIZ,0xFFFC` | 3 | status, data1, data2 |

## ★ `(0x9E)` bit 5 is not "active sensing timed out"

**A correction that only two converted routines together could produce.**

`MIDI_Fg_RealTime` (`0xFA59AB`) handles an incoming **`0xFF` SYSTEM RESET** by
setting bit 5 of `(0x9E)` — the *same* bit `INTT1_Tick` sets when the
active-sensing timeout expires. So the bit is not specific to sensing; it is the
condition both events mean: **the link has gone away, treat everything as
reset**.

⚠ And there is a methodological point in how nearly this was missed. A census of
the instruction `set 5,(0x9e)` (`f0 9e bd`) finds **exactly one** site in
prom_a, the new one at `0xFA59F2`. `INTT1_Tick` does not use a bit instruction
at all — it reads `(0x9E)` into `A` at `0xF82D1C`, does `and A,0x7f` / `or
A,0x20` at `0xF82D30`, and writes `A` back at `0xF82D4A`. **A read-modify-write
is invisible to a bit-instruction census.** Both forms are now checked by
`notes/midi_parser_check.py`.

`MIDI_Fg_RealTime` also handles `0xFA` START and `0xFB` CONTINUE, which differ
only in `res 1,H` versus `set 1,H` on `(0x0922)` — so bit 1 of `(0x0922)` is
"this transport run was resumed rather than started". `0xFC` STOP, `0xF8` CLOCK
and `0xFE` ACTIVE SENSING are **not** handled here; the interrupt-side handler
at `0xFA5504` already deals with them.

## ⚠ A note on "nothing calls it"

`PanelLed_ToggleActivityLed_SaveRegs`'s header was written in this same session saying no caller had been
found, citing `notes/prom_a_xref.py`. Converting the next 425 bytes turned up
**two** callers, `MIDI_Fg_Deliver2` at `0xFA5A93` and `MIDI_Fg_Deliver3` at
`0xFA5AC6` — both `calr`, which that tool cannot see because it searches for
*absolute* references. Corrected in the source in the same edit as this note.

This is the third time this tree has recorded the same trap (`Dev7A_StartDma`,
`Kernel_RotateQueue`, now this). **"`prom_a_xref` found nothing" means "no
absolute reference", never "nothing calls it".**

## Still not converted

* `0xFA5AEB` onward — the foreground System Common handler, the SysEx data
  sink at `0xFA5B3D`, and whatever `0xFA5BF7` (called by `MIDI_Reset`) does.
  The module runs to about `0xFA5CC6`, where an 826-byte run of `0x0E` pad
  begins.
* `(0x0922)` beyond bit 1, `(0x0964) = 4`, and the two bare constants `0xA8`
  and `0x10` in the message `MIDI_Fg_RealTime` posts.
* ⚠ **Which queue is which.** `0xF41D18` (drained here), `0xF41DAC` (filled by
  the interrupt parser), `0xF41DF0` (drained by `MIDI_TX_Ready`) and `0xF41DD4`
  (posted to here) are four different prom_b routines, and nothing converted
  proves which of them are the two ends of one queue. That is why
  `MIDI_DrainQueue` is named for what it does and not for a direction.
* `0xF41DAC`, `0xF41E3C`, `0xF41DF0`, `0xF41E00`, `0xF41DD4`, `0xF41B18`,
  `0xF41EA8`, `0xF406A0` — the prom_b side
  of the input and output queues. Another lane's territory, and the reason the
  queue's own structure at `0x00600C1E` is still only "a 16-bit free count at
  `+0xFE`".
* `sub_FA5926` and `PanelLed_ToggleActivityLed_SaveRegs` are deliberately **not** named: `(0xC4)`,
  `(0x0925)` and `0xF406A0` are unidentified, so any name would be a guess.
* `(0xA9)` bit 5 is tested by `MIDI_RX_SysExData` and **set nowhere** in the
  converted code.
* `(0x89)`, which selects the whole second arm of `MIDI_PostSendWork`.

## The scripts

| script | what it answers |
|---|---|
| `notes/midi_parser_check.py` | re-derives every number above; exits non-zero on drift |
| `notes/prom_a_xref.py` | who names a prom_a address (upper bound, opcode-anchored) |
