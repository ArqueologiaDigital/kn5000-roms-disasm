# CPU 1's kernel: the RAM map, the task lifecycle, and the two published ABIs

**Established 2026-08-25**, converting prom_a `0xF85606-0xF856EB` and
`0xF857D6-0xF85876` (391 bytes). Every number below is re-derived from the ROM
by `python3 notes/prom_a_byte_checks.py`, which prints its own check count;
nothing here is a hand count.

Read `FINDINGS-prom_a-tasks-and-dsp-refresh.md` first — this note answers two of
the questions that one left open, and corrects one of its leads.

---

## 1. The kernel is published TWICE, with two calling conventions

prom_b `0xF42D60-0xF42DDF` is a block of `jp` thunks into prom_a, and it is two
runs, not one:

| run | slots | targets |
|---|---:|---|
| `0xF42D6C`-`0xF42DA8` | 16 | `0xF857D9` `0xF8584A` `0xF85877` `0xF858C0` `0xF85904` `0xF8592D` `0xF8596D` `0xF859AE` `0xF85A22` `0xF85A96` `0xF85B1F` `0xF85BD4` `0xF85C8C` `0xF85DA8` `0xF85E02` `0xF85E5E` |
| `0xF42DAC`-`0xF42DD4` | 11 | `0xF857D6` `0xF8584A` `0xF85874` `0xF85904` `0xF8592A` `0xF859AB` `0xF85A93` `0xF85B0D` `0xF85C89` `0xF85DA2` `0xF85E5B` |

Pair each slot of the second run with the nearest target of the first at or
above it and the run resolves completely, with no residue:

* **2 of 11** are the *same address* in both runs (`0xF8584A`, `0xF85904`) — what
  a routine taking **no argument** looks like;
* **9 of 11** begin with `ld A,(XSP+0x04)`, the three bytes `8F 04 21`. Seven are
  exactly that one instruction and fall through into the register entry three
  bytes on. `0xF85DA2` adds `ld W,(XSP+0x06)` for a **second** argument (6 bytes
  to `0xF85DA8`). `0xF85B0D` fetches its second argument as `ld XIZ,(XSP+0x24)`
  *after* the register pushes — `0x24 = 0x06 + 2 + 7*4`, the same stack slot seen
  through 30 bytes of pushes — then `jr`s into the body.

So the second run is the **stack-argument (C-callable) face** of the same kernel.
Whoever writes a prom_b lane note should treat the two runs as one API with two
entry conventions, not as 27 routines.

⚠ The pairing is a byte fact; **what each pair does is not**. Eleven of the
sixteen register-ABI entries are converted as of 2026-08-25 — `0xF857D9`
`Kernel_StartTask`, `0xF8584A` `Kernel_ExitTask`, `0xF85877`
`Kernel_YieldRotate`, `0xF858C0` `Kernel_RotateQueue`, `0xF85904`
`Kernel_BlockSelf`, `0xF8592D` `Kernel_ReadyTask`, `0xF8596D`
`Kernel_ReadyTask_NoDispatch`, `0xF859AE` `Kernel_SemaSignal`, `0xF85A22`
`Kernel_SemaSignal_NoDispatch`, `0xF85A96` `Kernel_SemaWait`, and `0xF85C8C`,
whose stack face `0xF85C89` is `MsgQueue_ReceiveBlocking`. The other five are
still `.incbin`.

---

## 2. Everything in this kernel is 1-based

The task selector `A` and the priority level `n` index four arrays, and every one
of them is addressed with a one-element negative bias:

| formula in the ROM | the array it means | written by |
|---|---|---|
| `0xF85E7E + A*12` | `EntryPoint_Records + (A-1)*12` | `Kernel_StartTask` `0xF857E9` |
| `0x02F4 + A*12` | task control blocks, `0x0300 + (A-1)*12` | `Kernel_StartTask` `0xF857F3` |
| `0x032C + n*4` | ready-queue heads, `0x0330 + (n-1)*4` | `Kernel_StartTask` `0xF8582D`, and both queue primitives |
| `0x0360 + A*4`, `0x0370 + A*4` | wait / message queues, `0x0364`, `0x0374` | `MsgQueue_ReceiveBlocking` |

`Kernel_InitRam` settles it from the other side: it writes **four** control blocks
from `0x0300` with stride 12 and `B = 4`, so they occupy `0x0300`-`0x032F` and the
first ready-queue head at `0x0330` begins immediately after. There is no 8-byte
hole in the layout — the `+8` in the old "`0x02F4 + 4*12 + 8 = 0x032C`" is
`12 - 4` seen through the bias.

**This is why the earlier round's search failed.** That round looked for a
routine naming `0xF85E8A` and found none. The routine that reads the records
names `0xF85E7E`.

---

## 3. `Kernel_InitRam` (`0xF85606`) declares the kernel's whole RAM map

Reached only through prom_b thunk `0xF42D60`. One pass, all literal addresses:

| RAM | what | written at |
|---|---|---|
| `0x0300 + (A-1)*12` | 4 task control blocks, `+9` (state) := 0 | `0xF8562A` |
| `0x0330 + (n-1)*4` | **3 ready-queue heads**, self-linked | `0xF85615` |
| `0x033C + (s-1)*4` | 8 more list heads — **the semaphore wait queues**, §5.2 | `0xF85662` |
| `0x035C`-`0x0363` | 8 bytes copied from ROM `0xF85EBA` — **the semaphore counts**, §5.2 | `0xF85653` |
| `0x0364 + (A-1)*4` | 4 heads — the **wait queues** | `0xF856B5` |
| `0x0374 + (A-1)*4` | 4 heads — the **message queues** | `0xF856C7` |
| `0x0384 + i*8` | 8 nodes of 8 bytes, `+4` := `0xFFFFFFFF`, all appended to the free list | `0xF85674`, `0xF8569A` |
| `0x03C4` | 1 head — the **free list** | `0xF8568A` |
| `0x03C8 + (n-1)*8` | **2 software timers**, `+4` := `0xFFFFFFFF` | `0xF8563D` |

Six of the nine rows are independently confirmed by a routine converted in an
earlier round: `Kernel_Dispatch` scans three heads from `0x0330`;
`Kernel_ServiceSoftTimers` walks two 8-byte slots at `0x03C8` and treats
`+4 == 0xFFFFFFFF` as "empty"; `MsgQueue_ReceiveBlocking` uses `0x0360 + A*4`,
`0x0370 + A*4` and the free list at `0x03C4`.

The self-linking idiom is `ld IX,HL` then two `ld (XHL+),IX` — `head->next = head`,
`head->prev = head` — which is exactly the empty-list state `Kernel_Dispatch`
tests with `cp HL,IX`.

### It identifies `0xF85EBA`

Those eight bytes sit immediately after `EntryPoint_Records` and this tree has
carried them as *"UNIDENTIFIED. Not a fifth record"*. They are a **ROM image of
RAM `0x035C`-`0x0363`**: `ldir` copies exactly 8 bytes from `0xF85EBA` to `0x035C`
at `0xF85653`-`0xF85661`. Still not a fifth record — and §5.2 goes one step
further: `0x035C` is the semaphore count array, so these eight bytes are the
**initial counts**, `00 01 00 01 00 00 00 00`.

---

## 4. `Kernel_StartTask` (`0xF857D9`) — and the frame it builds

Called from `Kernel_Start` with `A = 1` and `A = 3`, from prom_b thunk
`0xF42D6C`, and by fall-through from the stack-argument entry `0xF857D6`.

It takes a task number, and:

1. refuses if the control block's `+9` state byte is already non-zero — the
   bail-out is `jrl NZ,Kernel_ResumeTask`, which undoes its own seven pushes;
2. builds the task's **initial stack frame** at `record.stack - 0x22`;
3. fills in the control block: `+4` = that stack pointer, `+8` = the priority
   level from `record+10`, `+9` = state **4**;
4. appends the block to the **tail** of ready queue `0x0330 + (level-1)*4`, with
   the tree's established four-store insert idiom;
5. `jrl Kernel_Dispatch` — it never returns.

**The frame is the identification, and it is exact arithmetic against a routine
already converted.** `Kernel_ResumeTask` (`0xF85763`) resumes a task with seven
32-bit pops, then `pop SR`, then `ret`:

```
7 * 4 = 0x1C  the seven register slots      (left uninitialised: a new task has no register state)
0x1C          SR        <- record+8, always 0x8800
0x1E          entry PC  <- record+0
0x22          total, and `sub XIY,0x00000022` is what the routine subtracts
```

So the frame this routine writes is precisely the frame that epilogue consumes.

### State bytes seen so far

| value | written by | meaning |
|---:|---|---|
| 0 | `Kernel_InitRam`, `Kernel_ExitTask`, `0xF85E5B` | not live |
| 3 | `Kernel_BlockSelf`, `MsgQueue_ReceiveBlocking` | blocked — and `Kernel_ReadyTask` only re-queues a block holding this value |
| 4 | `Kernel_StartTask` | runnable |

⚠ Nothing in the firmware names these; the numbers are what is established.

---

## 5. `Kernel_ExitTask` (`0xF8584A`) — the running task removes itself

Published at the same address in **both** thunk runs, which is what a
no-argument entry looks like. It switches to the boot stack `0x0060EB80` —
abandoning whatever stack it was running on — writes 0 to `TCB+9`, clears
`(0xBF)`, unlinks the block with the tree's `prev->next = next; next->prev = prev`
idiom, and jumps into `Kernel_Dispatch`. Nothing is saved on the way out, which
is what distinguishes an exit from a yield.

⚠ **Who calls it is unknown.** Both references are prom_b thunks.

---

## 5.1 `Kernel_BlockSelf` (`0xF85904`) and `Kernel_ReadyTask` (`0xF8592D`)

The inverse pair, and between them they settle how the scheduler actually
decides what is runnable.

`Kernel_BlockSelf` is published at the same address in **both** runs, so it takes
no argument. It takes the running task from `(0xBF)`, unlinks its control block,
writes **3** to `+9` — the same value `MsgQueue_ReceiveBlocking` writes when a
receive finds the queue empty — and jumps into `Kernel_Dispatch`. Crucially it
does **not** clear `(0xBF)` and does **not** switch stacks, so the dispatcher's
own prologue saves this task's `XSP` into `node+4` (`0xF85723`-`0xF85728`). That
is the entire difference from `Kernel_ExitTask`, which clears `(0xBF)` and moves
to the boot stack first, abandoning the stack it was on.

`Kernel_ReadyTask` takes a task number, refuses unless `+9 == 3`
(`cp (XIX+0x09),0x03` at `0xF85942`), and appends the block to the tail of
`0x0330 + (level-1)*4` — the level coming from the task's **own** `+8`, which
`Kernel_StartTask` filled from `EntryPoint_Records+10`, not from an argument.

### ★ Queue membership is runnability; `+9` is bookkeeping

`Kernel_ReadyTask` **never writes `+9`**. The state byte stays 3 while the task
is back on a ready queue and running. That is not an omission:
`Kernel_Dispatch__scan` picks a task by walking the three heads and taking the
first whose `+0` differs from the head address — it never reads `+9` at all.

Both halves are searched negatives, so both name their search:

* `Kernel_ReadyTask` is 64 bytes and contains the byte `0x09` **once**, at
  `0xF85943`, which is the displacement inside the guard's `cp (XIX+0x09),0x03`.
  There is no store to `+9` in any encoding.
* `Kernel_Dispatch` is 87 bytes (`0xF85715`-`0xF8576B`) and contains the byte
  `0x09` **zero** times, so it cannot reference `+9` in any encoding at all.

Both are checks in `notes/prom_a_byte_checks.py`.

---

## 5.2 ★ The eight COUNTING SEMAPHORES — and what `0x033C`, `0x035C` and `0xF85EBA` are for

`Kernel_InitRam` creates eight self-linked list heads at `0x033C` and copies
eight bytes from ROM `0xF85EBA` to `0x035C`, and §3 above could say no more about
either. Converting `0xF8596D`-`0xF85B0C` settles all three at once. They are the
two halves of **eight counting semaphores**:

```
0x033C + (s-1)*4   the wait queue for semaphore s, s = 1..8
0x035C + (s-1)     its count, ONE BYTE, saturating at 0xFF
```

The arrays are adjacent and both are exactly eight long — the last head is at
`0x0358`, `0x0358 + 4 = 0x035C` where the counts begin, and `0x035C + 8 = 0x0364`
which is the wait-queue array `Kernel_InitRam` creates next. Both carry the same
one-element bias as everything else: `0x0338 + s*4` and `0x035B + s`.

**And the ROM image is the initial counts.** `0xF85EBA` holds
`00 01 00 01 00 00 00 00`, so semaphores 2 and 4 start at 1 — two binary
semaphores, free for the first taker — and the other six start at 0 and block
until something signals. Those are the bytes this tree carried as
*"UNIDENTIFIED. Not a fifth record"*.

### The API

| entry | stack face | what it does |
|---|---|---|
| `0xF85A96` `Kernel_SemaWait` | `0xF85A93` | count non-zero → decrement, return; zero → block the running task on queue `s`, state 3, dispatch |
| `0xF859AE` `Kernel_SemaSignal` | `0xF859AB` | queue non-empty → wake its first node, state 4, onto that task's ready queue, dispatch; empty → increment the count, saturating |
| `0xF85A22` `Kernel_SemaSignal_NoDispatch` | `0xF85A1C` | the same, but `ret` instead of entering the scheduler |
| `0xF85AEF` `Kernel_SemaTryWait` | — | count non-zero → decrement, `WA = 0`; zero → `WA = 0xFFFF`, nothing touched. Never blocks |

**What carries the name is that Wait and Signal are exact inverses over the same
two arrays** — the same count byte, the same emptiness test complemented, `dec`
against `inc`, the same queue — not the shape of any one of them. The saturation
is an instruction, not a reading: `ld A,(XHL) / inc 1,A / jr Z,+2 / ld (XHL),A`
skips the store exactly when the increment wrapped `0xFF` to `0x00`.

`notes/prom_a_byte_checks.py` enumerates **every** site in prom_a that forms a
`0x0338` or `0x035B` base: there are **seven**, and they belong to those four
routines and nothing else.

### Two things the measurements corrected mid-round

* A first draft of that census asserted **four** sites and failed on the spot.
  Three were missing — two belonging to the second copy of Signal, and one at
  `0xF85AF4` belonging to `Kernel_SemaTryWait`, **a fourth semaphore routine the
  banner had not accounted for**. The check is what found it.
* A first draft of `Kernel_SemaSignal_NoDispatch`'s header claimed its body was
  *"74 bytes, 0 differ"* from `Kernel_SemaSignal`. Measured, that span differs in
  **51 of 74** bytes. The two routines share four runs, each stopping at the
  first byte of its epilogue:

  | run | addresses | identical bytes |
  |---|---|---:|
  | wake arm | `0xF859E1` / `0xF85A55` | **56** |
  | count arm | `0xF859CE` / `0xF85A3F` | **16** |
  | index arithmetic | `0xF859B8` / `0xF85A26` | **15** |
  | emptiness test | `0xF859C7` / `0xF85A38` | **6** |

  The arithmetic run breaks because the no-dispatch variant defers
  `push SR / ei 0x06` until after it has computed the queue head. The
  `Kernel_ReadyTask` / `_NoDispatch` pair, by contrast, really is identical —
  for **exactly 51 bytes**, checked at both ends of the run.

---

## 6. Two corrections this round forced

**`Kernel_Start`'s header said "arm two software timers".** It starts two
*tasks*. `0xF857D9` was described as "the register a software timer entry"; it is
`Kernel_StartTask`. Software-timer registration is a different routine,
`0xF85D78`, and `Kernel_Start` does not call it.

**`Kernel_Start`'s "Called from" cited an instruction that does not exist.** It
said the routine falls in from *"`0xF856E9`'s `jrl 0xF84F49`"*. `0xF856E8` is
`call 0xF85D78` (opcode `0x1D` at `0xF856E8`, its operand at `0xF856E9`), four
bytes ending exactly at `Kernel_Start`. The `jr` at `0xF856DE` targets `0xF856E8`
and fixes the boundary; **nothing in either ROM names `0xF84F49`.**

⚠ The byte-check suite keeps that mistake visible rather than filtering it: its
PC-relative scan reports a hit for `0xF84F49` at `0xF856E9`, because the scan
walks every byte offset rather than instruction boundaries. That coincidence is
what produced the wrong citation, and there is now a check asserting it *is* a
coincidence — the byte before it is `0x1D`.

---

## 7. What this leaves

* Five of the sixteen register-ABI entries are still `.incbin`: `0xF85B1F`,
  `0xF85BD4`, `0xF85DA8`, `0xF85E02`, `0xF85E5E` — plus the unpaired stack face
  `0xF85D1C`, which computes `0x0370 + A*4`, a MESSAGE queue. The message-queue **post** side is among them —
  something has to move a task off `0x0364 + (A-1)*4` and hand it a node from
  `0x03C4`; `Kernel_ReadyTask` is how that something would make the woken task
  runnable again.
* `0xF85D78`, the software-timer registration, called once from `Kernel_InitRam`
  with an inline 8-byte argument block. Its `0x03C0 + A*8` is another instance of
  the 1-based bias.
* `EntryPoint_Records[1]` and `[3]` — the boot path starts only records 0 and 2.
