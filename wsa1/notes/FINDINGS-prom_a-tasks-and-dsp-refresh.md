# CPU 1's task entry-point records, and the DSP refresh task

**Established 2026-08-25**, converting prom_a `0xF85E8A-0xF85F58`. Everything
quoted here is re-checked from the ROM by `python3 notes/prom_a_byte_checks.py`
unless the text says otherwise.

## 1. The same table exists in both processors

prom_c's lane decoded a run of 12-byte `{entry, stack, ?}` records at prom_c
`0xF980EA` and named it `EntryPoint_Records`. prom_a has the same structure at
`0xF85E8A`, with **four** records instead of three, and the two agree field for
field:

```
prom_c  7d 8b f9 00 | f0 ff 00 00 | 00 88 02 00    MAIN
        db 54 fa 00 | 80 f9 00 00 | 00 88 02 00
        18 81 f9 00 | 80 f4 00 00 | 00 88 01 00    DSP_ChannelRefresh_Loop
prom_a  5c 00 f4 00 | 00 e8 60 00 | 00 88 03 00    thunk -> 0xF827C8
        88 2e f4 00 | 80 e9 60 00 | 00 88 03 00    thunk -> 0xF8DA00
        c8 5e f8 00 | 80 ec 60 00 | 00 88 01 00    DSP_RefreshTask
        c0 33 f4 00 | 00 eb 60 00 | 00 88 03 00    thunk -> 0xFE02AB
```

Seven records across the two images. The halfword at +8 is `0x8800` in **every
one**, and the halfword at +10 is `0x0001` for the endless DSP refresh entry in
**both** images and larger for everything else.

### The fields

| offset | width | what | how strongly |
|---|---|---|---|
| +0 | LE32 | entry PC | **established.** All four decode as code. Three are prom_b thunk slots that `jp` straight back into prom_a (`0xF4005C`→`0xF827C8`, `0xF42E88`→`0xF8DA00`, `0xF433C0`→`0xFE02AB`); the fourth, `0xF85EC8`, is in prom_a directly — as prom_c's DSP entry is in prom_c |
| +4 | LE32 | initial XSP | **established.** All four are in `0x0060E800`-`0x0060EC80`, CS1 static RAM, and `Kernel_Dispatch`'s own boot stack `0x0060EB80` (`0xF8572B`) falls inside the same run |
| +8 | LE16 | `0x8800` | **a reading.** See below |
| +10 | LE16 | 1, 2 or 3 | **a reading — the ready-queue index, i.e. the priority.** See §1.1 |

**The `0x8800` reading, and what is missing from it.** A TLCS-900/H status
register with S=1 (system mode), MAX=1 and IFF=000 is `0x8800`. MAME resets this
part to SR = `0xF800`, commented "system mode, iff set to 111, max mode, register
bank 0" (`../mame/src/devices/cpu/tlcs900/tlcs900.cpp:218-219`), and IFF is the
interrupt **mask level** — `tmp95c061.cpp:481` blocks dispatch entirely while
IFF == 7 and `:538` scans priority levels upward from IFF. So `0x8800` is the
reset SR with the mask released, which is exactly the SR a task should start
with — and `Kernel_ResumeTask` (`0xF85763`) does `pop SR` immediately before its
`ret`, so a startable task frame needs an SR word and a PC.

⚠ **No site in prom_a or prom_b writes or pushes the constant `0x8800`**, and
**no code anywhere in either image names the address `0xF85E8A`** — no `call`,
`jp`, `lda` or bare 32-bit pointer (`notes/prom_a_xref.py`), and no PC-relative
`calr`/`jr`/`jrl` displacement in prom_a resolves to it. So the consumer of these
records has not been found, and the SR reading is unconfirmed. Recorded as a
fact about the search, not as a claim that the table is dead.

### 1.1 The `+10` field is the ready-queue index

Converting the two queue-rotate primitives at `0xF85877` (§4 below) turned this
field from "unidentified" into a four-link chain:

1. `Kernel_Dispatch` scans **three** list heads four bytes apart from `0x0330`
   and takes the first non-empty one — `ldb b,3` / `ldw ix,0x0330` /
   `ld HL,(XIX+0)` / `cp HL,IX` / `inc 4,IX` / `djnz8 b` at
   `0xF85746`-`0xF85759`. Three heads scanned in order are three priority levels.
2. `Kernel_YieldRotate` and `Kernel_RotateQueue` both address a head as
   `0x032C + A*4`, and `A = 1, 2, 3` gives exactly `0x0330`, `0x0334`, `0x0338`.
3. `sub_F85EC2` calls `Kernel_YieldRotate` with `A = 3`, so those small integers
   really are used as that index somewhere.
4. All **seven** `+10` fields across prom_a and prom_c lie in 1..3, never 0 or 4
   (checked, both images, by `notes/prom_a_byte_checks.py`).

⚠ Still a reading, and for the same reason as `+8`: nothing that **reads** this
table has been found. What is shown is that the values are exactly the right
shape for a ready-queue index, not that they are used as one. Worth noting
anyway: `1` is the level `Kernel_Dispatch` reaches **first**, and `1` is what
both images give the endless DSP refresh task.

**Count = 4**, and the test is the fifth element rather than the first: a fifth
record would begin at `0xF85EBA`, whose first word is `0x01000100` — not in
`0xF00000`-`0xFFFFFF`, so not an entry point, while all four above are. The
eight bytes `0xF85EBA`-`0xF85EC1` are emitted as `.byte` and left unidentified;
prom_c has a 4-byte trailer of the same flavour (`0x01010001`) in the same place.

## 2. `DSP_RefreshTask` (`0xF85EC8`) — and the same task exists in prom_c

For ever: push selector 1 to the kernel primitive at `0xF85C89`, take the block
it returns in XIY, walk it with `ld XIY,(XDE+)` and hand each of four consecutive
pointers to `DSP_WriteChannelRegs_FromTable` (`0xF85F59`, converted earlier) with
channel numbers 0, 1, 2, 3 in order.

It is an **entry point, not a subroutine**: the `link XIZ,0xFFFC` at `0xF85ECA`
opens the frame once and the loop closes back to `0xF85ECE`, *inside* that frame.
Nothing calls it; its address appears exactly once in either image, as the entry
field of `EntryPoint_Records[2]`.

### ⚠ `ei 0x00` ENABLES interrupts — a correction that crosses lanes

`DSP_RefreshTask` opens with `06 00`. That is `EI 0`, and on this part it
**releases** the interrupt mask:

* MAME `op_EI` sets SR bits 6-4 to `imm & 7` (`900tbl.hxx:2073-2078`);
* `tmp95c061.cpp:481` skips interrupt dispatch only while IFF == 7 — so `EI 7`
  is DI;
* `:538` scans priority levels from `max(1, IFF)` upward — so IFF = 0 accepts
  every level.

prom_a's own kernel agrees, in two independent places: `Kernel_Idle` (`0xF85711`)
does `ei 0x00` and then spins for ever — an idle loop does not run with
interrupts off — and `Kernel_ServiceSoftTimers` brackets its scan with
`ei 0x00` … `ei 0x06`, i.e. the **critical section is the one that raises the
number**.

`prom_c/wsa1_prom_c.s` spells the identical `06 00` as `di`, and its
`DSP_ChannelRefresh_Loop` header says that task "starts by disabling interrupts …
and never re-enables them". On the evidence above that is backwards — **and it is
the assembler's fault, not the reader's**: llvm-mc accepts `di` on this target and
emits `06 00`, byte for byte the same as `ei 0x00`. The alias says one thing and
does the other, and the byte gate cannot tell. Written up with the probe command
in `notes/llvm-mc-tlcs900-spellings.md`.

**Flagged, not edited** — prom_c belongs to another lane. The two routines are
otherwise the same design, so whichever way it is resolved should be resolved in
both, and the `di` mnemonic should be removed from both trees.

### ✅ CLOSED 2026-08-25 — and this paragraph was the thing left undone

Round-2 audit F8: *the request above was carried out, and the note that asked
for it was not updated* — which is the tree's own rule about correcting the old
text in the same commit, broken by the note that states the rule's occasion.
Measured now, over the IMAGES:

| | `di` instruction lines | `ei 0` instruction lines |
|---|---:|---:|
| prom_a | 0 | 75 (spelled `ei 0x00`) |
| prom_c | 0 | 31 (spelled `ei 0`) |

⚠ **A `grep` OVER `prom_c/wsa1_prom_c.s` NO LONGER ANSWERS THIS.** Since the
per-subject split that file is a 2,516-line header and its body is in 26
included sources, so the commands this section used to give — plain greps over
the primary — return **0 rows for prom_c whatever the truth is**. Run them over
the image:

```
python3 - <<'EOF'
import re, sys, collections; sys.path.insert(0, "notes")
from asm_source import image_lines
for t in "ac":
    L = image_lines(".", "prom_%s/wsa1_prom_%s.s" % (t, t))
    print("prom_%s  di:" % t, sum(1 for l in L if re.match(r"^\t(di|DI)\b", l)),
          collections.Counter(m.group(0) for l in L
                              for m in [re.match(r"^\s+ei[ \t]+\S+", l)] if m))
EOF
```

⚠ The `ei` column moved for TWO different reasons and only one of them is the
split: prom_c's rows were invisible to the old command, and prom_a's figure
(11 → 75) is later conversion rounds, which is not re-derived here. The `di`
column, which is what the argument below rests on, is 0 either way.

prom_a never had one; prom_c's eighteen (plus the five the same round added)
are gone. **So the "should be removed from both trees" above is DONE, not
pending, and nobody should act on it again.** What remains is prose, in prom_c
only, and it belongs to that lane: `prom_c/wsa1_prom_c.s` still uses the word
`di` in comment lines — **13** as this is written (the plain grep over the
primary returns 0 since the split; count it over the image, as above), and that file is another lane's, so the figure moves. Each
of those now sits next to its own correction: the audit's own example, the
`EntryPoint_Records` header at what is now line 390, carries an explicit
*CORRECTED 2026-08-25 (round-2 audit F8)* line.

## 3. `DSP_Init_Channels` (`0xF85F0F`) — a transplanted name, byte-backed

Zeroes an 8-byte buffer, pushes it to all four channels, then sets register
`(ch<<5)|0x1F` of each channel to 1 by writing `XWA = 0x0101001F` (and `ld W,A`
each pass) to `0x7F0000` with a stride of `0x20`.

`0xF85F4C`-`0xF85F58` is **13 bytes identical** to the KN5000 sub-CPU at
`0x1FCD1`, where the sibling's labels are `DSP_Init_Channels_Loop` inside
`DSP_Init_Channels` at `0x1FC95`
(`../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:396-428`).
Regenerate with `python3 notes/prom_a_sibling_short_runs.py`.

Three differences, all visible in the converted source: this one **zeroes** the
buffer where the KN5000 writes the test pattern `0x5A5A5A5A`; the register file
is at `0x7F0000` instead of `0x00130000`; and the per-channel writer takes stack
arguments instead of `XWA`/`BC`. prom_c has its own copy at `0xF98000`
(`DSP_ChannelRegs_Init`) with the port at `0x00E00000` — **three processors, one
routine, three buses.**

⚠ **Nothing calls it**, by the same two searches used for the table above.

## 4. `sub_F85EC2` — deliberately not named

Six bytes: `ld A,3` / `calr 0xF85877` / `ret`. `0xF85877` is a kernel primitive
reached through prom_b thunk `0xF42D74`; it takes a small selector in A, walks a
doubly-linked list at `0x032C + A*4`, and when the list is empty jumps into
`Kernel_ResumeTask` instead of returning — i.e. it blocks. Naming the wrapper
needs that routine converted, so it stays `sub_`.

## 5. The kernel's queues — and a correction to `Kernel_Dispatch`'s header

Converting `0xF85877`-`0xF85903` and `0xF85C89`-`0xF85D1B` fixed the RAM map of
the whole scheduler:

| address | what | established by |
|---|---|---|
| `0x032C + n*4` | ready queues; `n` = 1,2,3 are the three heads `Kernel_Dispatch` scans | `Kernel_YieldRotate` / `Kernel_RotateQueue` address arithmetic |
| `0x0360 + n*4` | the **wait** queue of message queue `n` | `MsgQueue_ReceiveBlocking`'s empty path parks the caller there |
| `0x0370 + n*4` | the **message** queue itself | its non-empty path takes the node from there |
| `0x03C4` | the free-node list | a consumed node is linked onto it |
| `0x03C8` | the two software timers | `Kernel_ServiceSoftTimers`, converted earlier |
| `(0xBF)` | LE16 pointer to the **current** task's node | `Kernel_Dispatch` writes it, `MsgQueue_ReceiveBlocking` reads it |

**Node layout**, identical for tasks, messages and free nodes: `+0` next, `+2`
prev, `+4` LE32 payload or saved XSP, `+9` byte state. Recycling clears `+4` to
`0xFFFFFFFF` — the same "empty" marker the software-timer slots use.

★ **Correction.** `Kernel_Dispatch`'s header used to say `0x0330` held "the task
control blocks: 3 x 8 bytes". It holds **three four-byte list heads**; the TCBs
are the nodes on them, and the dispatcher's own next instruction,
`ld XSP,(XHL+0x04)`, reads the saved stack out of the node. Corrected in
`prom_a/wsa1_prom_a.s` in the same edit as this note.

★ **On the two "nothing calls it" sentences above.** They are the same shape as
the claim round 1 had to retract, so they are re-derived by
`notes/prom_a_byte_checks.py` rather than asserted: the 3-byte little-endian
address at every offset of prom_a + prom_b, plus every PC-relative
`calr`/`jr`/`jrl` displacement in prom_a resolved to its target. The check
promptly failed two OTHER sentences written the same afternoon —
`Kernel_RotateQueue` is reached through prom_b thunk `0xF42D78`, and
`Dev7A_StartDma` (`0xFE596A`, `FINDINGS-dev7b-and-int5.md`) has four `calr`
callers rather than none. Both were corrected in the source. What the search
still cannot see is an address computed at run time.

Incidentally the thunk that caught the first one is a whole block of kernel
entry points: prom_b `0xF42D70`-`0xF42D83` is `jp 0xF8584A`, `jp 0xF85877`,
`jp 0xF858C0`, `jp 0xF85904`, `jp 0xF8592D` — five in a row, of which this round
converted the middle two. The other three are the obvious next targets.

### Two rotate routines, 38 bytes apart

`Kernel_YieldRotate` (`0xF85877`) and `Kernel_RotateQueue` (`0xF858C0`) are
**byte-identical over 38 bytes** — `0xF85897`-`0xF858BC` against
`0xF858D9`-`0xF858FE` — and the run is exactly 38, breaking on the byte either
side. Only the wrapper differs: one saves `Kernel_ResumeTask`'s full frame,
raises the interrupt mask with `ei 0x06`, and exits into `Kernel_Dispatch`; the
other saves four registers, does **not** raise the mask, and returns.

### One test apart, and it matters

Both rotate primitives ask `cp IX,(XIY+0x02)` — head->next against head->**prev**,
which is true for a queue of zero *or one* element, i.e. "nothing to rotate".
`MsgQueue_ReceiveBlocking` asks `cp IX,IY` — head->next against the **head**,
the zero-element test. Two different tests inside otherwise identical code is
what stops the three readings being interchangeable.

## 6. What this round left

### An open lead: RAM `0x02F4`, stride 12

`0xF85E5B` (still `.incbin`) takes a small number in `A`, forms
`0x02F4 + A*12` (`mul A,0x0c` at `0xF85E64`, `add WA,0x02f4` at `0xF85E67`),
unlinks the node at that address with the same twelve list instructions as
everything above, and writes **`0`** to its `+9` state byte — the counterpart of
the `3` `MsgQueue_ReceiveBlocking` writes. So the task control blocks are a
**12-byte-stride array based at `0x02F4`**, indexed by a task number.

The arithmetic then lines up suspiciously well with the ROM table:

```
RAM   0x02F4 + 4*12 = 0x0324 ,  + 8 = 0x032C   the queue-head base
ROM   0xF85E8A + 4*12 = 0xF85EBA, + 8 = 0xF85EC2  the next routine
```

Four 12-byte records and an 8-byte tail, in both places, ending exactly where the
next structure begins. ⚠ **This is recorded as a lead, not an identification**,
and one fact argues against the obvious reading: the FIELDS do not match. The ROM
record's `+0` is a 32-bit entry PC; the RAM node's `+0`/`+2` are 16-bit list
links. So the ROM table is not a byte image of the RAM array, whatever else it
is. If some routine builds the array *from* the records it has not been found —
and it would have to name `0xF85E8A`, which nothing does.

#### ★ RESOLVED 2026-08-25 — and the search above is *why* it took a round

`Kernel_StartTask` (`0xF857D9`, converted 2026-08-25) is the routine that
builds a RAM node from a ROM record. The lead was right about everything except
its own search: **it does not name `0xF85E8A`.** It names

```
0xF857E9   add XHL,0xfff85e7e      ; low 24 bits = 0xF85E7E = 0xF85E8A - 12
```

because the whole kernel is indexed **1-based**. The same bias is in the TCB
address the lead itself quotes — `0x02F4 + A*12` is `0x0300 + (A-1)*12` — and in
`0x032C + n*4`, `0x0360 + A*4` and `0x0370 + A*4`. `Kernel_InitRam` settles it
from the other side: it writes **four** TCBs starting at `0x0300` with stride 12,
so they occupy `0x0300`-`0x032F` and the first queue head at `0x0330` follows
immediately. The `+8` in "`0x0324 + 8 = 0x032C`" is not a gap in the layout; it
is `12 - 4` seen through the bias.

So a search for "who names `0xF85E8A`" could not have found the answer, and the
lead's closing sentence should be read as a warning about the search rather than
about the ROM. The corrected figures and every address above are re-derived by
`notes/prom_a_byte_checks.py`.

And the two questions the lead's ⚠ raised are answered together: the ROM table is
**not** a byte image of the RAM array, and nothing copies it — `Kernel_StartTask`
reads four fields out of the record and writes three *different* fields into the
node, plus a stack frame at a third address entirely. See
`FINDINGS-prom_a-kernel-lifecycle.md`.

## 6. What this round left

* `0xF85904`-`0xF85C88` and `0xF85D1C`-`0xF85E89`: the rest of the kernel,
  including the **post** side of the message queues (something must move a task
  off `0x0360 + n*4` and write `0` to node+9; `0xF85E5B` does the latter — see
  the lead above).
* ~~Whatever *selects* an entry point.~~ **Answered 2026-08-25.** `Kernel_Start`
  (`0xF856EC`) calls `Kernel_StartTask` twice, with `A = 1` and `A = 3` — records
  0 and 2, i.e. the `0xF4005C` thunk at level 3 and `DSP_RefreshTask` at level 1.
  Those are the only two tasks the boot path starts;
  `EntryPoint_Records[1]` and `[3]` are started by something else, or not at all,
  and that is still open.
* `0xF85C89`'s and `0xF85877`'s callers beyond the ones found here — all three
  converted queue routines are published through prom_b thunks (`0xF42DCC`,
  `0xF42D74`, `0xF42D78`), so their real users are in prom_b and are another
  lane's territory.
