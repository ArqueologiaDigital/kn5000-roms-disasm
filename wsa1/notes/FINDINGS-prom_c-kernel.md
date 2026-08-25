# CPU 2 runs the same multitasking kernel as CPU 1 — and that settles five open questions

**Established 2026-08-25**, converting prom_c `0xF9810E-0xF98111`,
`0xF9816B-0xF989EE` and `0xF98A0B-0xF98B1F` (2,461 substantive bytes). Every
number below is re-derived from the ROM by

```
python3 notes/prom_c_kernel_map.py --selftest
```

which prints its own check list and exits non-zero on any failure. Read
`FINDINGS-prom_a-kernel-lifecycle.md` and `FINDINGS-prom_a-tasks-and-dsp-refresh.md`
first: this note is the CPU-2 half of what those two describe for CPU 1, and it
answers three questions they left open.

---

## 1. It is not a resemblance. It is the same 35 routines, in order, at the same lengths

`notes/prom_c_prom_a_routine_diff.py` aligns two routines instruction by
instruction and separates *different mnemonic* (structural) from *same mnemonic,
different operand* (a substituted address). Run over the whole block:

| | |
|---|---:|
| routine pairs | **36** (35 in the block + `INTT3_KernelTick`) |
| pairs whose prom_c length equals their prom_a length | **36 of 36** |
| pairs with **zero** structural differences | **35 of 36** |
| the exception | `Kernel_InitRam`, **2** — and both are inside the 8-byte inline data block |

The lengths are not asserted; `--pairs` **checks** that each routine ends exactly
where the next one begins, in *both* images, and fails if it does not. That check
is what makes the alignment trustworthy: 36 boundaries agreeing to the byte
across two independently compiled images is not something a wrong split survives.

`Kernel_ResumeTask` is the extreme case — **all nine bytes identical**, no
operand to substitute.

Every one of the ~120 operand differences is a RAM address, a ROM table address,
a loop bound or a branch target. The two images differ in their RAM map and in
nothing else.

### The order, and the two calling conventions

prom_a publishes this kernel through two runs of prom_b thunks — a register-argument
face and a stack-argument face (`FINDINGS-prom_a-kernel-lifecycle.md` §1). prom_c
has **no thunk table**; it has the same routines at the same relative offsets, and
the same nine stack faces, each of which is one or two `ld A,(XSP+…)` instructions
falling through into the register face three (or six) bytes on.

Two routines that prom_a's lane has **not** converted are converted here, and the
correspondence is what places them: prom_c `0xF98684` / `0xF98739` are prom_a's
`0xF85B1F` / `0xF85BD4`, and prom_c `0xF9890D` / `0xF98967` are prom_a's
`0xF85DA8` / `0xF85E02`. Names given here — `MsgQueue_Send`,
`MsgQueue_Send_NoDispatch`, `Kernel_SetTaskLevel` — are argued from prom_c's own
code, not borrowed; the slot correspondence is corroboration.

---

## 2. CPU 2's kernel RAM map, and why the entry counts are a proof and not a reading

`Kernel_InitRam` (`0xF9816B`) writes nine arrays with literal bases and literal
`ldb b,N` counts. `prom_c_kernel_map.py --map` reads all eighteen numbers out of
the **instruction bytes** and lays them out in address order:

```
   base    n  stride  end     what
  0x0100   3   12    0x0124  task control blocks       (+9 state := 0)
  0x0124   2    4    0x012C  ready-queue heads         (self-linked)
  0x012C   4    4    0x013C  semaphore wait queues     (self-linked)
  0x013C   4    1    0x0140  semaphore counts          (ldir from ROM 0xF9810E)
  0x0140   2    4    0x0148  message WAIT queues       (self-linked)
  0x0148   2    4    0x0150  MESSAGE queues            (self-linked)
  0x0150   4    8    0x0170  free nodes                (+4 := 0xFFFFFFFF)
  0x0170   1    4    0x0174  free-list head            (self-linked)
  0x0174   2    8    0x0184  software timers           (+4 := 0xFFFFFFFF)
```

**The nine arrays tile `0x0100`–`0x0183` with no gap and no overlap.** A wrong
count anywhere in that chain leaves a hole or an overlap; the script asserts the
tiling and the total extent. So "three tasks", "two priority levels", "four
semaphores", "two message queues", "four free nodes" and "two software timers"
are each pinned twice — once by a literal loop count, once by the array that
starts where it ends.

Everything is **one-based**, exactly as prom_a is: the code forms `0x00F4 + t*12`,
`0x0120 + n*4`, `0x0128 + s*4`, `0x013B + s`, `0x013C + q*4`, `0x0144 + q*4` and
`0x016C + n*8`.

Two scalars and one control register complete it:

| | |
|---|---|
| `(0x0090)` | pending kernel ticks. `INTT3_KernelTick` is its only writer; `Kernel_Dispatch` drains it |
| `(0x0091)` | LE16 pointer to the running task's control block; 0 = "on the kernel stack" |
| cr `0x3C` | the dispatch-inhibit depth |
| `0x0000FA00` | the kernel's own stack |

prom_a's equivalents are `(0xBE)`, `(0xBF)`, cr `0x3C` and `0x0060EB80`.

### ⚠ Control register `0x3C` is left as a number, and MAME is the reason

MAME's TLCS-900 disassembler prints any control register it has no symbol for as
`unknown` (`dasm900.cpp:1445-1450`), and the symbol table for this exact part
names only the **sixteen** micro-DMA registers — DMAM0-3, DMAC0-3, DMAS0-3,
DMAD0-3, four rows of four (`tmp95c061_cr_syms[]`, `tmp95c061.cpp:1394-1399`;
★ corrected 2026-08-25 from "eight", round-2 audit F7 — the count was wrong, the
conclusion it supports is not). **No TLCS-900 part in MAME names a control register
`0x3C` at all.** Worse for anyone emulating this machine: the `default:` arm of
`case p_CR16:` in `900tbl.hxx` points at `m_dummy`, so in MAME this register is a
plain scratch word — reads see what the firmware last wrote and nothing else
touches it.

What the *firmware* does with it is established: zero at boot, ++ / -- around the
software-timer scan, `!= 0` means "do not reschedule" in `Kernel_Dispatch`, `== 1`
means "this interrupt was the outermost" in `IRQ_Epilogue`. If the real part
maintains this register in hardware on interrupt entry and `RETI`, MAME's scratch
word will not, and the two would diverge on nested interrupts. **Flagged for the
emulation lane; not resolved here.**

---

## 3. What this settles in prom_c

### 3.1 `EntryPoint_Records` — consumer found, and the third column was two fields

The table at `0xF980EA` carried *"⚠ IT IS ONLY A READING. Nothing in prom_c refers
to `0xF980EA` … the third column is not decoded at all."* Both are now answered.
`Kernel_StartTask` reads it, and the record is

| offset | field |
|---|---|
| +0 LE32 | entry PC → written to `frame+0x1E`, the address `RET` pops |
| +4 LE32 | initial XSP → the frame is built at this **minus 0x22** |
| +8 LE16 | `0x8800`, the SR → written to `frame+0x1C`, restored by `pop SR` |
| +10 LE16 | 1 or 2 — the **ready-queue level**, copied to TCB+8 |

and `0x22 = 7*4 + 2 + 4` is exactly what `Kernel_ResumeTask` pops.

**The old search could not have succeeded**, and prom_a's lane hit the identical
trap: the kernel is one-based, so the routine names `0xF980DE` = `0xF980EA - 12`.

The count of **three** is now a bound check rather than an argument from the data:
`Kernel_InitRam` creates exactly three task control blocks with the same stride
of 12, and `Kernel_StartTask` indexes both arrays with the same task number, so a
fourth record would have no control block. All three levels (2, 2, 1) lie inside
the two ready queues — a last-element check the script asserts.

### 3.2 CPU 2 runs three tasks

| task | entry | level | started by |
|---|---|---:|---|
| 1 | `MAIN` `0xF98B7D` | 2 | `Kernel_Start`, `ldb a,1` at `0xF9825D` |
| 2 | `0xFA54DB` | 2 | `0xFA3365`, which pushes 2 |
| 3 | `DSP_ChannelRefresh_Loop` `0xF98118` | 1 | `Kernel_Start`, `ldb a,3` at `0xF98263` |

★ prom_a's note asks who starts `EntryPoint_Records[1]` and `[3]`; for prom_c the
answer to the first is `0xFA3365`, found by searching for the stack face rather
than the register face.

### 3.3 `DSP_ChannelRefresh_Loop` is a blocked task, not a spin — and it probably runs once

Its header said *"⚠ what this is FOR … an interrupt-disabled endless loop … is what
a bench test or a fallback mode looks like"*. Both halves were wrong.
`0xF985F8` is `Kernel_SemaWait`, so each pass **blocks on semaphore 3**; and the
`di` it opens with is `06 00` = `EI 0`, which *enables* interrupts.

⚠ And nothing found ever signals semaphore 3. Both `Kernel_SemaSignal` call sites
push 2: `call 0xF98510` at **0xF98C6C** in MAIN (its `push 0x0002` at 0xF98C69)
and at **0xFA2DE4** (its `push 0x0002` at 0xFA2DE1).

> ★ **Corrected 2026-08-25** (round-2 audit F3). This sentence used to cite
> "`0xFA2DE0`", which is the *last byte* of the preceding
> `f2 b4 f3 00 41  ld (0x00f3b4),A` at 0xFA2DDC — not an instruction boundary at
> all — and paired it with 0xF98C69, which is a `push`. Two citations, two
> different anchors, one of them invalid. Read off
> `scripts/analysis/dis.sh c 0xFA2DD0 48` and `... c 0xF98C60 32`; the byte
> census behind the claim (exactly two `1D 10 85 F9` sites image-wide) is
> unaffected and still holds.

`Kernel_SemaSignal_NoDispatch` and
its stack face have **no call site at all**. Semaphore 3 starts at 1, so on the
evidence available this task runs **exactly one pass and then blocks for ever**.
Recorded as a searched negative: `prom_c_xrefs.py` cannot see a target computed at
run time.

### 3.4 `sub_F98112` is the boot software timer's callback

Three instructions: `ldb a,2` / `calr Kernel_YieldRotate` / `ret`. Its address is
the +4 field of the eight-byte `SoftTimer_Request_Boot` block `Kernel_InitRam`
hands to `SoftTimer_Register`, whose +0 and +2 are both 1 — countdown 1, reload 1,
so it fires on **every** kernel tick. Level 2 is the level of both MAIN and task 2,
so this is what time-slices them. Renamed `SoftTimer_RotateLevel2`. The trailing
`ret` is dead, in both images.

### 3.5 `INTT3_HANDLER` → `INTT3_KernelTick`; `(0x0090)` and `0xF9831C` identified

Two instructions, and prom_a's `INTT3_KernelTick` (`0xF85600`) is the same two:
0 structural differences, 2 operand differences (the counter address and the
epilogue address). `(0x0090)` is the pending-tick count; `0xF9831C` is
`IRQ_Epilogue`.

### 3.6 Two of the six "unreferenced trampolines" could not work if they were reached

`0xFFF0C8`'s block contains `call 0xF98610` and `jp 0xF9854E`. With the kernel
converted, both can be checked against real instruction boundaries, and **neither
is one**: `0xF98610` is inside `cp (XWA),0x00` at `0xF9860F` (in
`Kernel_SemaWait`) and `0xF9854E` is inside `ld WA,(XIX+0x00)` at `0xF9854C` (in
`Kernel_SemaSignal`). Independent evidence that the block is dead.

---

## 4. The two A/D inputs (`0xF98A0B-0xF98B1F`)

`MAIN` calls `Analog_ScanAndReport` when scheduler bit 5 of `0x007ED1` is set. It
reads **ADREG1H** (SFR `0x63`) and **ADREG2H** (SFR `0x65`), passes each through
`Analog_ChangeDetect`, and on acceptance sends `Link_SendBuffer(5, 2, 0x00E2E9)`
with a two-byte message `{tag, value}`, tag `0xB0` for channel 1 and `0xB1` for
channel 2.

`Analog_ChangeDetect` is a deadband filter with a confirmation counter packed into
one state byte:

| `|sample - last|` | what happens |
|---|---|
| ≤ 2 | `and C,0xF8` — reset the counter and the arm bit |
| 3 … 6 | bit 2 set → **accept**; bit 2 clear → `or C,4` (arm) |
| > 6 | `C == 3` → **accept**; otherwise `inc 1,C`, `and C,0xFB` |

so bits 0–1 count large moves (accepted on the fourth consecutive one), bit 2 is a
one-shot arm for medium moves, bit 3 is the accept flag, and the return value is
`ld A,C / and A,0x08`. The routine does **not** update the last-reported value —
the caller does, only on acceptance.

The four RAM cells are `0x00E2E5`/`0x00E2E6` (channel 1 value / state) and
`0x00E2E7`/`0x00E2E8` (channel 2), and the boot RAM image gives both value cells
**`0x80`, mid scale**, and both state cells 0
(`python3 notes/prom_c_ram_image.py 0x00E2E5 0x00E2E6 0x00E2E7 0x00E2E8`).

⚠ What the two inputs are physically is **not established** — the A/D is polled
(the INTAD vector points at `IRQ_UNUSED`), `ADC_Init` writes `ADMOD = 0x3F` which
MAME does not decode, and no databook is available. The link tags `0xB0`/`0xB1`
are recorded, not decoded. ⚠ `Link_SendBuffer`'s first argument is 5 while only
two bytes of the buffer are written here; if that argument really is a length,
three bytes of the message come from somewhere this routine does not touch.

---

## 5. A spelling correction that crosses lanes: `di` is gone from prom_c

llvm-mc accepts `di` on this target and assembles it to `06 00`, which is `EI 0` —
and on this part `EI 0` **releases** the interrupt mask (`op_EI`,
`900tbl.hxx:2073-2078`; `tmp95c061.cpp:536-545`; reset leaves IFF at 7,
`tlcs900.cpp:213-220`). prom_a's lane found this and flagged it as
*"the `di` mnemonic should be removed from both trees"*. All **eighteen** sites in
`prom_c/wsa1_prom_c.s` now read `ei 0`. The byte gate proves the change is
spelling only.

---

## 6. What this round left

* `MsgQueue_Send_NoDispatch` writes its status word to `(XSP+0x0E)`, which in its
  own 20-byte frame is the **high half of the saved XIX**, not the saved WA at
  `(XSP+0x10)`; 2 is exactly the width of the `push SR` this variant defers, and
  the blocking variant — whose SR push is not deferred — stores correctly at
  `(XSP+0x14)`. prom_a's copy is structurally identical, so it is not a
  transcription error. Its wake path stores no status at all. No caller found, so
  nothing turns on it yet.
* **Eleven of the kernel's 26 published entry points have no call site in
  prom_c** — `python3 notes/prom_c_kernel_map.py --callers`, which pairs each
  stack face with its register face and *excludes* the five entries reached by
  `jp`, by fall-through or by `jrl` (which `prom_c_xrefs.py` cannot see and which
  would otherwise be miscounted as unused):

  ```
  Kernel_BlockSelf                 MsgQueue_Send
  Kernel_ReadyTask                 MsgQueue_Send_NoDispatch
  Kernel_ReadyTask_NoDispatch      MsgQueue_ReceiveBlocking
  Kernel_SemaSignal_NoDispatch     MsgQueue_Receive_NoBlock
  Kernel_SetTaskLevel              Kernel_SetTaskLevel_NoDispatch
  Kernel_KillTask
  ```

  i.e. the **whole message-queue API**, the whole priority-changing API and the
  whole no-dispatch half of the wake-up API. On CPU 1 the equivalents are reached
  through prom_b thunks; CPU 2 has no thunk table, so either they are library dead
  weight or they are reached from the 96 KiB this file still leaves as `.incbin`
  at the front. Not decided. ⚠ Searched negative — the tool cannot see a target
  computed at run time.
* `0xFA2DE0`-`0xFA55xx` is the module that actually drives the kernel — it starts
  task 2, signals semaphore 2, yields, and exits. It is unconverted and is the
  obvious next target for anyone following this thread.
* `Kernel_RotateQueue`'s one candidate reference, a `calr` displacement at
  `0xF92121`, is inside unconverted bytes and has not been shown to be an
  instruction.
