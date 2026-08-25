# CPU 2's half of the inter-processor link: the TRANSMIT side

**Image:** `prom_c` (IC28, CPU 2, base 0xF80000).
**Converted for this note:** `0xF9993E-0xF99BBD`, six routines, 640 bytes.

`notes/FINDINGS-memory-map.md` §3 established the wires and the packet format from CPU 1's
side; `notes/FINDINGS-prom_c-link-receive.md` decoded what CPU 2 does when a byte arrives.
This is the other half: what CPU 2 does to send one.

Reproduce with

```
python3 notes/prom_c_prom_a_routine_diff.py 0xF99A40 0xF8E0FE 0x83
python3 notes/prom_c_prom_a_routine_diff.py 0xF99B0D 0xF8E26F 0xAB
python3 notes/prom_c_prom_a_routine_diff.py 0xF99AC3 0xF8E181 0x4A
python3 notes/prom_c_xrefs.py 0x00F32C --no-window --classify
```

---

## 1. ★ Timer 2 is the byte clock

`Link_Init` (0xF9993E), called once from `MAIN`'s init chain at 0xF98B8D:

```
INTET32 := 0x00        ; INTT2/INTT3 levels off while this runs
res 2,(TRUN)           ; stop timer 2
T23MOD  := 0x0E
INTETC23:= 0x55        ; INTTC2/INTTC3 levels
0x008535 = 0x008536 = 0x008537 := 0
INTE0AD := 0x01        ; INT0 level
TREG2   := 0x05
uDMA2_SetDest  (0x00100000, mode 0x08)   ; DMAD2 fixed port, DMAM2 = source++
uDMA3_SetSource(0x00100000, mode 0x00)   ; DMAS3 fixed port, DMAM3 = dest++
```

The two micro-DMA halves are the ones `notes/FINDINGS-prom_c-link-receive.md` names — that
note points at *"0xF99966-0xF99977: DMAS3 := 0x00100000, DMAM3 := 0x00"*, which is this
routine's second helper call. Modes: 0x08 is "byte transfer, **source** incremented" and 0x00
is "byte transfer, **destination** incremented"
(`mame/src/devices/cpu/tlcs900/tmp95c061.cpp:366-371` and `:398-401`).

**Every sender below ends with `ldio DMA2V,0x12` then `set 2,(TRUN)`.** `0x12 << 2 = 0x48 =
INTT2` (`tmp95c061.cpp:353`, vector map `:322-346`), so each timer-2 tick moves one byte out of
the packet buffer into the port and the CPU is not involved until INTTC2. Nothing else in the
converted code writes TREG2.

⚠ The T23MOD and INTETC23 bit fields are not decoded anywhere in this tree, so the actual byte
rate is unknown.

---

## 2. Arbitrary-length data: `Link_SendBlock` -> `Link_SendChunk`

`Link_SendBlock` (0xF9997E) is called four times, and as of 2026-08-25 all four are converted
and their channel numbers are readable:

| site | channel | payload |
|---|---:|---|
| 0xF98B30 | — | inside `MAIN`, before the loop |
| 0xF98C00 | 6 | `MAIN`'s MIDI-in drain, up to 32 raw bytes |
| 0xF98D48 | **5** | `KeyEvents_ToLink`, up to ten `0x90, note, velocity` triples |
| 0xF98D8F | 6 | `KeyEvents_ToLink`'s own MIDI-in drain |

★ So **channel 5 carries the keyboard, encoded as MIDI note-on messages, and channel 6 carries
the MIDI IN port's bytes verbatim.** Both are receive-side no-ops on this processor (channels
4-7 all dispatch to the bare `ret` at 0xF9993D), which is what a one-way assignment looks like.

It splits the caller's buffer into packets:

```
while remaining > 0x20:  send 0x20 bytes; pointer += 0x20; remaining -= 0x20
send the remainder                       <- ALWAYS, even when it is zero
```

⚠ A length that is an exact multiple of 32 therefore ends with a **zero-length** call. Read off
the code, not smoothed over. (`Link_SendChunk` rejects a zero length at entry, so nothing goes
out.)

32 is the largest length the header byte can express, which is the first thing in this tree to
corroborate the format from the sending side:

`Link_SendChunk` (0xF999BE) builds the header itself —
`ld L,H / dec 1,L / ld C,(XIZ+0x08) / sll 0x05,C / or C,L` — i.e.

```
header = (channel << 5) | (len - 1)
```

which is exactly the format `notes/FINDINGS-memory-map.md` §3 states. `len - 1` never
underflows because `cp H,0 / jrl Z,exit` rejects zero first.

The handshake is §3's: wait for PA bit 3, drop PA bit 0, write the byte, wait for PA bit 3
again, raise PA bit 0. Both waits are bounded by `0x4E20 = 20000` spins and both time out by
raising PA bit 0 and returning. Then `uDMA2_SetSource(payload, length)`, `DMA2V := 0x12`,
`set 2,(TRUN)`, and a spin on `(0x00F32C)`.

---

## 3. The three command senders, and which are CPU 1's routines recompiled

| prom_c | command | payload | prom_a twin | instruction slots | mnemonic differences |
|---|---|---|---|---:|---:|
| `Link_SendCmdE2_MemRead` 0xF99A40 | `0xE2` | 10-byte packet at 0x008538 | 0xF8E0FE | 47 | **0** |
| `Link_SendCmdE1` 0xF99B0D | `0xE1` | 6-byte packet at 0x008542, then the caller's buffer | 0xF8E26F | 58 | **0** |
| `Link_SendCmdByte` 0xF99AC3 | `0xE0 \| n` | none | 0xF8E181 | 26 | **9** |

★ **"The same routine compiled for the other CPU" is a measurement here, not an impression.**
`notes/prom_c_prom_a_routine_diff.py` aligns two routines instruction by instruction and
separates *different mnemonic* (a structural difference) from *same mnemonic, different
operand* (a substituted address). For 0xF99A40 all 18 differences are the port, the handshake
pins, the flags, the DMA setter and the branch targets; the three packet stores are in the
**identical** group.

⚠ They are **not** byte-identical. A plain byte comparison of 0xF99A40 against 0xF8E0FE gives
an identical run of **eight** bytes. `notes/prom_c_prom_a_shared_runs.py` measures byte
identity and is the wrong tool for this question; that is why the new script exists.

### Command 0xE2's packet layout

`+0x00` u32, `+0x04` u32, `+0x08` u16, filled from arguments `(XIZ+0x08)`, `(XIZ+0x0e)`,
`(XIZ+0x0c)` respectively — the same three stores, in the same order, as CPU 1's. §3 of the
memory-map note pins what those fields *mean* from **two CPU-1 callers**: remote address, local
destination, length.

⚠ Those meanings are carried from prom_a. `notes/prom_c_xrefs.py 0xF99A40` finds **no caller
at all** in prom_c, so nothing in this image confirms the direction.

### Command 0xE1 is a two-stage write

The 6-byte packet carries `arg(XIZ+0x0e)` u32 and `arg(XIZ+0x0c)` u16; then the routine spins
until `(0x00F32C)` falls from 2 to 1, waits 200 more passes, and issues a **second**
micro-DMA of `arg(XIZ+0x0c)` bytes from `arg(XIZ+0x08)`. So the first transfer is a header and
the second is the payload.

⚠ The length is stored twice — to `(0x00851E)` and `(0x008546)` — and the two *addresses* go to
two different slots, `(0x00851A)` and `(0x008542)`, which are 0x28 apart and therefore two
separate buffers. Only `arg(XIZ+0x08)` is ever dereferenced (it is the second transfer's
source), so `arg(XIZ+0x0e)` is the one that travels; reading it as "the destination on CPU 1"
is the analogy with 0xE2, not a finding.

### The bare-command sender is NOT CPU 1's routine

`Link_SendCmdByte` diverges from prom_a in one block of nine instructions: where CPU 1 waits on
its busy pin after writing the byte, **CPU 2 runs a fixed countdown of `0x3E8` = 1000 and then
clears the busy flag itself**. It never waits for the far end and never leaves the flag set.
CPU 1 also takes the command in `(XIZ+0x0c)` and CPU 2 in `(XIZ+0x08)`.

---

## 4. The busy flag takes three values

`python3 notes/prom_c_xrefs.py 0x00F32C --no-window --classify`: **16** literal-addressed
sites. Writes of 0 (0xF99B02, 0xF99D09), of 1 (0xF999E4, 0xF99A67, 0xF99AE3, 0xF99D19) and of
**2** (0xF99B34). `INTTC2_HANDLER` compares against 1 at 0xF99D01 and against 2 at 0xF99D11.

⚠ What distinguishes state 1 from state 2 is not established here; the only thing read off the
code is that the 0xE1 sender is the one that sets 2, and that it then waits for 1.

---

## 5. ★★ Command 0xE2 is a READ REQUEST and command 0xE1 is the WRITE that answers it

`Link_ServiceTask` (0xF99E5F, converted 2026-08-25) is the only caller of `Link_SendCmdE1`, and
it is where the round trip closes:

```
INT0_HANDLER__cmd_E2       points micro-DMA channel 3 at 0x008520 for TEN bytes
INTTC3_HANDLER__state3     the ten bytes have landed -> set bit 7 of 0x00852A
Link_ServiceTask           clears that bit and calls
                             Link_SendCmdE1( (0x008520) u32,
                                             (0x008528) u16,
                                             (0x008524) u32 )
```

`Link_SendCmdE1` **dereferences its first argument** as the source of its payload transfer and
puts its third into the 6-byte header packet. So, entirely from prom_c and without appealing to
prom_a:

```
0xE2 packet  +0x00 u32   the address to read ON THIS PROCESSOR
             +0x04 u32   the destination ON THE OTHER ONE
             +0x08 u16   the length
```

which is exactly the layout `notes/FINDINGS-memory-map.md` §3 derived from CPU 1's two callers
of its own 0xE2 sender. Two independent derivations, opposite ends of the wire, same three
fields. It also removes the "carried from prom_a" caveat that `Link_SendCmdE1`'s source header
used to have to carry.

⚠ The caveat survives in one place: `Link_SendCmdE2_MemRead` (CPU 2 *sending* an 0xE2) still has
no caller in prom_c, so the direction of the fields when CPU 2 is the requester is still only
the analogy.

## 6. What the next pass needs

* Who calls `Link_SendCmdE2_MemRead` — nothing literal-addressed does.
* The six `0xFC8xxx` routines `Link_ServiceTask`'s three jobs call
  (0xFC856C, 0xFC8646, 0xFC88F9, 0xFC893B, 0xFC898F, 0xFC89AF).
* `0x008537`, `0x00851A`, `0x008538`, `0x008542`: the transmit-side work block.
  `0x00852B` bit 7 is already known (it is what `Link_WaitBlockDone` polls), and
  `0x008535`/`0x008536` are now known to be a producer/consumer counter pair.
