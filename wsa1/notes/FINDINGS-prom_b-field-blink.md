# prom_b's field-blink engine — 0xF0E800-0xF0EA9E

At the start of round 2 the busiest prom_b-targeting thunk slot that was still
`.incbin` was `T_F42E24` (x85). It points at `0xF0E82B`, three instructions
inside a module that makes one on-screen text field flash: **sixteen labels —
eleven routines, four dispatch arms reached only by `jp`, and one 12-entry
table** (`grep -c '^Blink_' prom_b/wsa1_prom_b.s`).

`notes/prom_b_call_graph.py` no longer lists `T_F42E24`, because the ranking is
filtered to targets that are still `.incbin` and this one no longer is — which
is the point of the tool.

Everything below is re-derivable:

```
python3 notes/prom_b_call_graph.py            # why this module was next
python3 notes/prom_b_blink_rate.py            # the clock chain, byte by byte
python3 scripts/analysis/assert_byte_identical.py
```

## Why it is one module, and where it starts

Five consecutive thunk slots name five consecutive routines:

| slot | refs (upper bound) | target |
|---|---:|---|
| `T_F42E20` | 41 | `0xF0E9CF` `Blink_Command` |
| `T_F42E24` | 85 | `0xF0E82B` `Blink_Stop` |
| `T_F42E28` | 21 | `0xF0E800` `Blink_SetEnable` |
| `T_F42E2C` | 1 | `0xF0E83A` `Blink_Tick` |
| `T_F42E30` | 2 | `0xF0E835` `Blink_GetState` |

That is one linker input file, exported in address order. The lower boundary is
hard: the bytes below `0xF0E800` are a long run of `0x0E` (`ret`) fill, the same
fill convention the thunk table uses.

⚠ The reference counts are **opcode-anchored upper bounds** — the scan is at
every byte offset, so some hits are bytes inside another instruction or inside
display-list data. They rank slots; none of them is a call count.

## What makes "blink" a measurement

`Blink_Tick` increments `(0x28D1)`, masks it with 7, and

* at phase **0** renders the field with argument 1 — the live text pointer;
* at phase **4** renders it again with argument 0, which substitutes the ROM
  constant at `0xF78020`: `20 20 20 20 20 20 20 20 00`, eight ASCII spaces.

Draw, erase, draw, erase, 50% duty. The rate falls exactly where a UI blink
falls, and `notes/prom_b_blink_rate.py` re-reads every ROM byte of the chain:

```
28 MHz / 2048 / TREG1 28              = 488.28 Hz   INTT1
(0x86) counts 0,1,2, (0x87) on wrap   = 162.76 Hz   rota slots
1 of 16 rota slots does res 7,(0x88)  =  10.17 Hz   ticks
tick counter has 8 phases             =   1.27 Hz   blink, 0.39 s on / 0.39 s off
```

⚠ The last link assumes prom_a's main loop iterates faster than 10.17 Hz — its
`tset 7,(0x88) / jr NZ` at `0xF82182` calls the tick only when the rota has
cleared the bit since the last pass. That loop's period is not measured anywhere
in this tree, so **1.27 Hz is an upper bound on the rate**, never an exact value.

## How it draws: a display-list record built on the stack

Neither renderer calls a text service directly. Each one:

1. `link XIZ,-15` (or `-17`) to open a frame;
2. `ldir` a **record template out of ROM** into that frame — 15 bytes from
   `0xF78000`, or 17 from `0xF7800F`;
3. patch four (or five) of the record's fields from the control block;
4. save `(0x2540)`, set it from `(0x28C8)`, `push XIX` and
   `call 0xF3183D` — `DisplayListB_RunOne_Stack`;
5. restore `(0x2540)`.

The templates identify themselves by opcode: `0x02` and `0x07`, the two
interpreter-B opcodes whose handlers (`0xF31B21`, `0xF31B39`) imply record
lengths of 15 and 17 — exactly the two `ldir` counts. Both are now decoded as
assembly with a field-by-field layout comment.

### One thing the byte gate caught

The first draft of this decode wrote the op-07 template's length byte as `0x11`
(17), on the strength of "the opcode implies 17 and the copy is 17 bytes, so the
length byte must say 17". **It says `0x0F`.** The build gate rejected the file,
which is the only reason that number is not still sitting in a header looking
plausible.

The disagreement is real and harmless, and the reason is worth recording: these
records are never *framed*. `DisplayListB_RunOne_Stack` sets the end pointer to
`XIY + 1`, so interpreter B's `cp XIX,XIY / jr ULE` lets exactly one record run
and then exits. The length byte only advances `XIY` past the record; any value
≥ 1 ends the loop, and nothing walks from this record to a next one.

It is **not** a counterexample to "494 interpreter-B records, 0 disagree"
(`notes/prom_b_dl_length_audit.py`): that audit walks records reachable from
`ld XIY,imm32 / ld XIX,imm32 / call 0xF417F0|0xF417F4` call sites, and these two
templates are reached by neither — they are copied, not run in place.

## The control block, 0x28C8-0x28D3

Each field is named by the instruction that touches it, and by nothing else.

| address | role | named by |
|---|---|---|
| `(0x28C8)` | LCD layer for the draw | `ld (0x2540),(0x28c8)`; `(0x2540)` indexes prom_a's `LCD_LayerBasePtr_Table` 0..2 |
| `(0x28C9)` | the record's `+6`, the `swi 7` function | `ld (XIX+0x06),(0x28c9)`; values `0x17`/`0x1C` select the op-07 template |
| `(0x28CA)` | op-02's `+0x0D` word | `ldw (XIX+0x0d),(0x28ca)` |
| `(0x28CC)` / `(0x28CE)` | op-07's `+0x0D` / `+0x0F` words | `ldw (XIX+0x0d),(0x28cc)`, `ldw (XIX+0x0f),(0x28ce)` |
| `(0x28D0)` | `+0x0B`, bytes per entry | `ld BC,(0x28d0) / extz BC / ld (XIX+0x0b),BC` |
| `(0x28D1)` | the 8-phase blink counter | `inc 1,(0x28d1)`, `and C,0x07` |
| `(0x28D2)` | blink state: 0 stopped, 2 blinking, 1 unexplained | the only value `Blink_Tick` proceeds on is 2 |
| `(0x28D3)` | 0 ⇒ draw inline, non-0 ⇒ post to the ring buffer | written by `Blink_Command` from a stack-address test |
| `(0x28C0)` | the template's default `+7`, i.e. where the text is | the template's own bytes; nothing in this module writes it |

`(0x2075)` bit 1 is the enable: `Blink_SetEnable` writes it and `Blink_Tick`
refuses to run when it is clear. Bit 3 of the same byte is set by
`Dispatch_Code80` at `0xF5B9EB` — it is a shared flag byte with several owners.

### A gate that looks wrong and is not

`Blink_Tick`'s state test is `ld BC,(0x28d2) / extz BC / cp BC,0 / cp BC,1 /
cp BC,2`. The load really is 16-bit — prefix `0xD1` selects MAME's
`mnemonic_d0`, whose opcodes `0x20-0x27` are `{ M_LD, O_C16, O_M }`
(`dasm900.cpp:846`) — so at first reading it tests `(0x28D2)` **and** `(0x28D3)`
together, which would make the deferred path below it unreachable.

It does not. `extz BC` immediately zeroes the high byte (`*m_p1_reg16 &= 0x00ff`,
`900tbl.hxx:2135`), so only the byte at `0x28D2` is compared and `(0x28D3)` never
contaminates it. The four ring-buffer trampolines at `0xF0E906-0xF0E925` are
live.

## The command dispatcher

`Blink_Command` (`T_F42E20`, x41) reads a command byte `0x00-0x0B` through a
pointer argument and jumps through a 12-entry table at `0xF0EA14`. The count is
bounded twice and the two bounds meet: `cp WA,0x000b / jrl UGT` allows at most
12, and `0xF0EA14 + 12*4 = 0xF0EA44` is the lowest address any entry holds — the
table abuts its own first arm. The table is emitted as **symbols**, so the build
gate itself proves every pointer equals the address of the arm it names.

Only four distinct arms appear; the repetition is the command map. The arms set
`(0x28D2)` to 1 or 2 after testing `(0x2823)` against `0x20`, and in two cases
`(0x2820)` against `0x2D`.

⚠ `0x20` and `0x2D` are ASCII space and `'-'`, and this module's business is
text — but that reading is **not asserted**. What (0x2823) and (0x2820) hold is
not established.

Before dispatching, `Blink_Command` sets `(0x28D3)` by comparing a frame address
(`lda XWA,XIZ+0xfe`) with the constant `0x0060E800`: at or above it the byte
stays 1, below it becomes 0. The boot stack pointer is `0x0060EB80`
(prom_a `0xF85606`, `FINDINGS-memory-map.md`), so the constant sits 896 bytes
into that stack. ⚠ **What the test means is not established** — "deep frame vs
shallow frame", "task stack vs interrupt stack" and "recursion guard" all fit
the same three instructions and this tree cannot tell them apart.

## What is NOT established

* Which on-screen field this is. A cursor and an edited value both fit.
* What the 12 commands are, beyond the four state transitions their arms make.
* What `(0x28D2) == 1` means; nothing here runs on it.
* What `0x17` and `0x1C` are as `swi 7` functions.
* prom_a `0xF8BC78` (reached from `Blink_Stop` through `T_F432F8`), and prom_b
  `0xF0EA9F` and `0xF0EC4A`, which the command arms call. All three are still
  `.incbin`; they are the obvious next step outward.
