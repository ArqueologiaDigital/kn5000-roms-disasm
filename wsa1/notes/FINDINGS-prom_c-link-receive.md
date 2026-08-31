# CPU 2's half of the inter-processor link: the receive state machine

**Image:** `prom_c` (IC28, CPU 2, base 0xF80000).
**Converted in round 2:** 0xF99C12-0xF99CFD, 0xF99D6F-0xF99E5D, 0xF99FC1-0xF9A04F.

`notes/FINDINGS-memory-map.md` §3 established the *wires*: a byte port (0x100000 on CPU 2,
0x7C0000 on CPU 1), a two-wire handshake, micro-DMA channel 2 outbound, and a header byte
`(channel << 5) | (len - 1)`. This note is the *receiving* side: what CPU 2 does when a byte
arrives, decoded from the code rather than inferred from the sender.

Everything below is reproduced by:

```
python3 notes/prom_c_link_state_machine.py --selftest
python3 notes/prom_c_prom_a_shared_runs.py --selftest
python3 notes/prom_c_ram_image.py 0x00F334:32
```

---

## 1. One interrupt, two customers

INT0 (vector slot 0x28) is wired to the link port's strobe. The handler at 0xF99BBE reads one
byte, and the *last* thing every one of its arms does is

```
ldio DMA3V, 0x0A        ; 0x0A << 2 = 0x28 = INT0
```

which hands the *same interrupt* to micro-DMA channel 3. From that moment the payload bytes are
moved port -> buffer by the DMA engine, one per interrupt, and the CPU sees nothing until the
count runs out and INTTC3 fires. INTTC3 then decides what happens next, and either posts a flag
or re-arms the channel for a second transfer.

The trigger arithmetic is MAME's, for this exact part: `(DMAnV & 0x1f) << 2`
(`mame/src/devices/cpu/tlcs900/tmp95c061.cpp:353`) against the vector map at `:322-347`. The
channel's other half is programmed once, at 0xF99966-0xF99977: `DMAS3 := 0x00100000`,
`DMAM3 := 0x00`, and mode 0x00 is "byte transfer, **destination** incremented"
(`tmp95c061.cpp:366-371`) — read the fixed port, walk the buffer.

Channel 2 is the mirror image: `DMAD2 := 0x00100000`, `DMAM2 := 0x08` = "byte transfer,
**source** incremented" (`tmp95c061.cpp:398-401`) — walk the buffer, write the fixed port.

## 2. The command byte is not an opcode, it is a length-prefixed header

Six commands have dedicated arms. The seventh arm takes command 0xE6 **and every byte outside
0xE1..0xE7**, and its transfer count is *computed*:

```
ldb_da a, 0x008518      ; the command byte
and    a, 0x1f
inc    1, wa            ; count = (byte & 0x1F) + 1
```

and when that payload lands, `INTTC3_HANDLER__state1_generic` uses the **top three bits** as a
class index into an eight-entry function-pointer table. So the low 5 bits are a length and the
top 3 bits are a channel — which is exactly the header byte `(channel << 5) | (len - 1)` that
§3 of the memory-map note derived from **CPU 1's transmit code**. Two images, opposite ends of
the same wire, one encoding. Neither derivation used the other.

| command | arm | state | count | buffer |
|---|---|---|---|---|
| 0xE1 | 0xF99C12 | 2 | 6 | 0x008568 |
| 0xE2 | 0xF99C32 | 3 | 10 | 0x008520 |
| 0xE3 | 0xF99C52 | 5 | 4 | 0x00852D |
| 0xE4 | 0xF99C72 | 6 | 6 | 0x008568 |
| 0xE5 | 0xF99C91 | 7 | 4 | 0x008531 |
| 0xE7 | 0xF99CB0 | 8 | 6 | 0x008568 |
| 0xE6 **or any other byte** | 0xF99CCF | 1 | `(b & 0x1F) + 1` | 0x008548 |

⚠ **What the commands MEAN is still not established** — only their payload sizes, their landing
buffers and their follow-up states. prom_a's header for the same protocol says the same thing
and adds "do not name them"; that is kept.

## 3. The state variable, censused completely

| | |
|---|---|
| variable | `(0x00F32D)`, written as a byte, read as a 16-bit word |
| literal-addressed references in prom_c | **18** — 17 immediate byte writes and one read |
| the one read | `ldw_da bc, 0x00F32D` at 0xF99D2C, in INTTC3_HANDLER |
| values ever written | exactly 0..9 |
| where the writers live | all inside 0xF99C12-0xF99FDC |

That census is what makes "states 4 and 9 are entered from INTTC3 itself, never from an INT0
command" a measurement: 0xF99E07 writes 4, 0xF99E3B writes 9, and no INT0 arm writes either.

⚠ It is a census of **literal-addressed** references. A write through a pointer register is
invisible to it, as it is to every search in this tree.

| state | arm | reached from | what it does |
|---|---|---|---|
| 1 | 0xF99D6F | 0xE6 / any other | dispatch on the class bits (§4) |
| 2 | 0xF99DAC | 0xE1 | descriptor `{u32 dest, u16 count}` -> arm the payload -> state 4 |
| 3 | 0xF99DB5 | 0xE2 | `(0x008519) := 0xFF`, post 0x00852A bit 7 |
| 4 | 0xF99DCC | INTTC3 (state 2/6) | payload done: clear 0x00852B bit 7 |
| 5 | 0xF99DDD | 0xE3 | post 0x00852C bit 7 |
| 6 | 0xF99DED | 0xE4 | descriptor, destination forced into 0x010000-0x01FFFF -> state 4 |
| 7 | 0xF99E11 | 0xE5 | post 0x00852C bit 6 |
| 8 | 0xF99E21 | 0xE7 | descriptor, banked like state 6 -> state 9 |
| 9 | 0xF99E43 | INTTC3 (state 8) | post 0x00852C bit 5, bump the counter at 0x008535 |

Each posting flag is censused over all twelve direct-address spellings by
`python3 notes/prom_c_link_state_machine.py --flags`. The three flag bytes have **17** sites
between them, spanning 0xF99AAE-0xF99FE5; adding `0x008519` and `0x008535` gives **23** sites
over 0xF99951-0xF99FE5. (The top of that span is inside `Link_WaitBlockDone`, not inside the
INTTC3 arms — quoting the arms' own range here would have been an off-by-one.)

* `0x00852A` — 3 sites. Set here (state 3); tested and cleared at 0xF99E67/0xF99E6E.
* `0x00852B` — 4 sites. **Set at 0xF99AAE**, right after channel 2 is armed and TRUN bit 2 set,
  i.e. as an *outgoing* transfer begins; cleared by state 4 and by the timeout path in
  `Link_WaitBlockDone`, which is also its only reader. So it means "an exchange is outstanding",
  not "an incoming transfer is running".
* `0x00852C` — 10 sites. Bits 7/6/5 set by states 5/7/9, each tested and cleared by the routine
  at 0xF99E5F; bit 5 also set at 0xF99F48. A three-bit work-request byte.
* `0x008519` — **1 site**, the write in state 3. Never read by any literal-addressed
  instruction anywhere in the image. Reported as measured, not declared dead.

## 4. `Handler_PtrTable_FCC53F` — a question this round closed

That table's header used to say *"nothing in prom_c references 0xFCC53F as a literal, so the
START of this table is inferred … What dispatches through it is not traced."* Both halves are
now answered, and the reason the literal search failed is that **the dispatcher never uses the
ROM address**:

* RESET copies ROM 0xFCB4EA.. to RAM 0x00E2DF (`notes/prom_c_ram_image.py` re-derives the copy's
  source, destination and count from the instruction bytes and refuses to print if they are not
  exactly as expected).
* `0xFCC53F - 0xFCB4EA = 0x1055`, so the table's RAM copy starts at `0x00E2DF + 0x1055 =
  0x00F334`.
* `0xF99D91` is `add xbc, 0x0000F334`, indexed by `(command byte >> 5) * 4`, followed by
  `ld xbc,(xbc)` / `jp (xbc)`.

Eight entries, because the index is three bits. Boot contents: 0xF98D9A, 0xF98DE6, 0xF98FD6,
0xF9901B, then 0xF9993D four times (whose first byte is `0x0E` = RET). ⚠ What the four real
class handlers do is still open.

## 5. `Link_WaitBlockDone` — the same routine on both CPUs

prom_c 0xF99FC1 and prom_a 0xF8E66D are the **same fifteen instructions in the same order with
the same opcodes**; only the operand addresses differ.

| role | prom_a | prom_c |
|---|---|---|
| tick counter | `(0x0080)` | `(0x00F2F3)` |
| outstanding flag | `(0x00008A)` bit 7 | `(0x00852B)` bit 7 |
| transfer state | `(0x6007DA)` | `(0x00F32D)` |
| handshake port | P7 (0x13) bit 1 | PA (0x1E) bit 1 |
| timeout counter | `(0x6007E1)` | `(0x00F333)` |
| timeout | 0x01F4 = 500 ticks | 0x01F4 = 500 ticks |

★ The two tick-counter reads here are the sites the round-1 census of `0x00F2F3` missed: they
use the **16-bit-direct** spelling (prefix 0xD1) rather than the 24-bit one (0xD2). prom_a makes
the point a third time — its counter is at 0x0080, so the identical instruction is spelled with
the **8-bit-direct** prefix 0xD0 there. One instruction, three prefixes, one address space. See
the correction block in `INTT1_HANDLER`'s header and in `notes/prom_c_xrefs.py`.

## 6. The compiler runtime is shared between the two EPROMs

prom_c 0xF99FEE..0xF9A04F is **byte-identical** to prom_a 0xF8E698..0xF8E6F9 — 98 bytes,
maximal (the images differ one byte before and one byte after). Measured, not eyeballed:

```
python3 notes/prom_c_prom_a_shared_runs.py --selftest
```

The run covers all eight helpers, so their prom_a names are carried over on byte identity
rather than on resemblance: `uDMA2_SetDest`, `uDMA2_SetSource`, `uDMA3_SetSource`,
`uDMA3_SetDest`, `uDMA2_GetCount`, `uDMA3_GetCount`, `uDMA3_GetDest`, `MemCopyWords`. The
control-register numbers are MAME's table for the part (`tmp95c061.cpp:1394-1398`).

⚠ Note the crossing the round-1 audit caught in prom_a (finding F8) and which holds here too:
the second argument is the **mode byte** for `uDMA2_SetDest` and `uDMA3_SetSource`, and the
**transfer count** for `uDMA2_SetSource` and `uDMA3_SetDest`. Mode rides with *dest* on channel
2 and with *source* on channel 3.

`MemCopyWords` has **66** call sites in prom_c (byte census of `1D 38 A0 F9`), first 0xFB1DE7,
last 0xFC575B — both ends checked.

## What the next pass needs

* **0xF99E5F-0xF99FC0 is the consumer** of every flag in §3 and is still `.incbin`. It reads
  the 0xE2 packet (`0x008520` +0/+4/+8), calls into 0xFC85xx-0xFC89xx, and polls
  `uDMA3_GetCount`. Converting it should name the flags.
* ~~**The region below INT0_HANDLER, up to 0xF99BBD, is the transmit half**~~
  **DONE 2026-08-25** — converted, and the header byte `(channel << 5) | (len - 1)` is now
  read off the *sender* (`Link_SendChunk` at 0xF999BE) instead of inferred. See
  `notes/FINDINGS-prom_c-link-transmit.md`.
* ~~The four class handlers 0xF98D9A / 0xF98DE6 / 0xF98FD6 / 0xF9901B.~~ **DONE 2026-08-25.**

## ★ The channel map, both directions (added 2026-08-25)

The four `Handler_PtrTable_FCC53F` arms are converted, so the receive side of the channel index
is no longer a shape:

| channel | CPU 2 RECEIVES | CPU 2 SENDS |
|---|---|---|
| 0 | `Link_Ch0_AppendToRing` — bytes into a 4096-byte ring at `0x00E2F1`, whose end (`0x00F2F1`) is the next documented variable | — |
| 1 | `Link_Ch1_WriteParamBlock` — 16 sub-commands 0x80..0x8F writing four ≤26-byte parameter blocks at `0x00007E7E`, `0x00007E98`, `0x00007EB2`, `0x00007ECD`, each with a bit in `0x007ECC` | — |
| 2 | `Link_Ch2_ForwardBytes` — byte stream into `0xF992C6`, with the byte `0xFA` intercepted into `(0x00F328) = 0xFF` | — |
| 3 | `Link_Ch3_SetTouchControl` — a 2-byte packet: `0x80` sets the touch-curve mode, `0x90` the touch offset | — |
| 4-7 | `Link_ChannelHandler_Ignore` (0xF9993D) — a bare `ret` | 5 = key events as MIDI note-on triples, 6 = raw MIDI-in bytes |

⚠ Channels 5 and 6 are the two CPU 2 sends on and they are among the four it discards on
receive, which is what a one-way assignment looks like. Nothing states that as a rule.

★ `Link_Ch3_SetTouchControl` answers a question two converted routines had left open:
`ToneGen_SetVelCurveMode` and `ToneGen_SetVelOffset` both said "Called from: not traced" and
"Unknown: which UI control feeds it". Neither is fed on this processor — **CPU 1 sets them over
the link**. See `notes/FINDINGS-prom_c-keyboard-and-touch.md`.

⚠ **A retraction from the same session.** The first version of the `0xF9993D` header in
`prom_c/wsa1_prom_c.s` called it "a lone `ret` … nothing in prom_c references it
(notes/prom_c_xrefs.py 0xF9993D: no literal, no calr)". The tool had not been run; running it
finds **four** ABS32 references, which are entries 4-7 of `Handler_PtrTable_FCC53F` — a fact
the table's own header in the same file already stated. The byte gate passed either way.
