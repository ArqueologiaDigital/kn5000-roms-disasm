# The WSA1's kernel is in the KN5000 too — and in BOTH of its processors

**Answer: YES.** The multitasking kernel that `kernel/kernel.s` assembles into
both of the WSA1's TMP95C061s is also present, routine for routine, in the
KN5000's TMP94C241 **sub-CPU payload** and, independently, in its **main
program ROM**. One kernel, **four processors, two products.**

Everything below is reproduced by

```
python3 notes/kernel_structural_match.py --selftest        # 14 invariant checks
python3 notes/kernel_structural_match.py                   # all sections, sub-CPU
python3 notes/kernel_structural_match.py --target=kn5000:main
```

`notes/kernel_three_way.py` is **superseded** by that tool. Its answer ("0
matches for 23 routines across all 41 KN5000 images") is *true as a statement
about bytes* and *wrong as an answer to the question*, for a reason its own tree
had already proved: `kernel/kernel.s` is ONE source that both WSA1 CPUs build
from, and the two copies still differ in **81 of 941 instruction slots**. Two
processors in the same product, from the same build, are not byte-identical. A
third and fourth, in another product, cannot be.

## 0. The single strongest piece of evidence (`--foil`)

Every other section asks "does the kernel match?". This one asks the question
that would demolish the answer if it came out wrong: **run the identical search
on WSA1 code that is NOT the kernel.** The foils are real prom_c routines —
`call`/`calr` targets outside the kernel block — cut to the same instruction
counts, scored against the same candidate set with the same window.

| | n | max | median | min | ≥ 0.70 |
|---|---:|---:|---:|---:|---:|
| **KERNEL routines** (≥ 20 instructions) | 20 | **1.000** | **0.909** | **0.742** | **20** |
| **NON-kernel prom_c foils** | 26 | 0.333 | 0.212 | 0.143 | **0** |

Foil scores, high to low:
`0.33 0.32 0.31 0.28 0.27 0.27 0.24 0.24 0.23 0.22 0.22 0.21 0.21 0.21 0.20 …`

**The two distributions do not overlap, and there is a gap of 0.41 between
them.** The foil maximum, 0.333, is exactly the P2 calibration point below —
"same idea, independently written". Nothing in prom_c that is not the kernel
gets anywhere near what the kernel gets.

---

## 1. The instrument, and the one decision that matters

Both sides are decoded **from raw ROM bytes by the same disassembler** (MAME
`unidasm -arch tlcs900`). Neither tree's `.s` text is read for instruction
spelling, and no dialect map is needed, because there is only ever one dialect.

That is not a convenience. The two trees spell the same three bytes `9c 00 23`
as `m_ld_rm MWD+r4, 0x00, r3` (WSA1) and `ld hl, (xix + 256)` (KN5000). A
source-to-source comparison would have scored one instruction as a difference.
It is `ld HL,(XIX+0x00)`, and `--selftest` S6/S7 pin exactly that.

* **token** = the disassembled text with every `0x…` literal replaced by `#`.
  Registers are kept (`XIX` and `XIY` are different code); bare decimals are
  opcode fields (`inc 4,IX`, `swi 7`) and are kept too.
* **score** = `LCS(query tokens, candidate tokens) / len(query tokens)` —
  longest common subsequence, not positional alignment.
  `notes/wave7_xref_tlcs900_family.py` §E measured that positional alignment
  falls apart across two builds and it is right: the KN5000 scheduler has whole
  instructions the WSA1 one does not.
* the candidate window is **length-matched to the query** (2× its byte length),
  identically for the real search and for every null.
* **control flow is scored separately**, on the LCS alignment: for each aligned
  pair of branches, does the branch cross the same number of instructions on
  both sides?

★ The check that proves the normaliser is doing the right thing is **S9**:
prom_a and prom_c normalise to *identical* token sequences for every kernel
routine. They are 81 slots apart in bytes. A normaliser that leaked one address
would fail it.

---

## 2. Calibration — what a score MEANS (`--controls`)

Four homologs established by other lanes, without this tool:

| control | what it is | score | rank |
|---|---|---:|---|
| **P0** prom_c `0xF98099` → KN5000 payload `0x01FD27` | ONE routine, two peripheral bases, **cross-product** | **1.000** | 1 of 4790 |
| **P1** prom_c `Kernel_Dispatch` → prom_a `0xF85715` | ONE source, two CPUs, one build | **1.000** | 1 of 37 |
| **P2** prom_a `0xF8E47F` INT0 link receiver → KN5000 sub-boot `0xFF881F` | ★ **same protocol, independently written** | **0.333** | 1 of 198, **12 tied** |
| **P3** prom_a `0xFA58F0` SC0 UART configure → KN5000 main `0xFCF940` | one 11-instruction routine, two builds | 0.636 | 71 of 39393 |

**P2 is the bar.** `wave7_xref_tlcs900_family.py` §B established that the
inter-processor link is *one protocol implemented four times*. That is what
"related but not shared" looks like: **0.333, and indistinguishable from noise
(12 candidates tie with it).** P3 says the other thing that matters: at 11
instructions nothing is decidable — 234 candidates tie and the true site ranks
71st.

---

## 3. The measurement (`--null`), sub-CPU payload

`best` is the routine's best score anywhere in the image. The five nulls:

* **N1** all 4790 named sub-CPU symbols, minus windows overlapping the winner
* **N2** 4000 random windows in `kn5000_table_data.rom` (an image that is DATA)
* **N3** N1's candidates against the query with its token **order shuffled**
* **N4** 4000 random payload offsets
* **N5** ★ the named candidates lying **outside** `0x01FBDA–0x020A0B`, the span
  the matches themselves land in — i.e. the rest of the ROM with the matching
  region deleted

| WSA1 kernel routine | n | best | site | N1 | N2 | N3 | N4 | N5 |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| MsgQueue_Send_NoDispatch | 80 | **0.887** | 0x0204D5 | 0.725 | 0.138 | 0.338 | 0.150 | **0.150** |
| Kernel_InitRam | 78 | **0.949** | 0x01FDDA | 0.256 | 0.154 | 0.372 | 0.103 | **0.103** |
| MsgQueue_Send | 71 | **0.915** | 0x02044F | 0.704 | 0.141 | 0.366 | 0.155 | **0.155** |
| MsgQueue_ReceiveBlocking | 59 | **0.898** | 0x020642 | 0.814 | 0.153 | 0.373 | 0.169 | **0.169** |
| Kernel_SemaSignal_NoDispatch | 55 | **0.945** | 0x020374 | 0.873 | 0.164 | 0.436 | 0.164 | **0.164** |
| Kernel_SemaSignal | 48 | **0.938** | 0x020308 | 0.854 | 0.188 | 0.396 | 0.208 | **0.208** |
| Kernel_StartTask | 45 | **0.978** | 0x01FFFD | 0.556 | 0.178 | 0.311 | 0.200 | **0.200** |
| Kernel_SetTaskLevel_NoDispatch | 42 | **0.905** | 0x0207B0 | 0.667 | 0.143 | 0.333 | 0.167 | **0.167** |
| MsgQueue_Receive_NoBlock | 41 | **0.805** | 0x0206D3 | 0.634 | 0.195 | 0.366 | 0.195 | **0.195** |
| Kernel_SemaWait | 39 | **0.923** | 0x02044F | 0.872 | 0.231 | 0.385 | 0.256 | **0.256** |
| Kernel_SetTaskLevel | 39 | **0.897** | 0x02072A | 0.718 | 0.231 | 0.385 | 0.256 | **0.256** |
| Kernel_YieldRotate | 33 | **0.909** | 0x0200C0 | 0.879 | 0.273 | 0.424 | 0.273 | **0.273** |
| Kernel_RotateQueue | 32 | **0.906** | 0x0200C4 | 0.844 | 0.156 | 0.406 | 0.188 | **0.219** |
| Kernel_Dispatch | 31 | **0.742** | 0x01FF2A | 0.258 | 0.194 | 0.290 | 0.226 | **0.226** |
| Kernel_ReadyTask | 29 | **0.966** | 0x02014D | 0.931 | 0.276 | 0.414 | 0.345 | **0.345** |
| Kernel_ReadyTask_NoDispatch | 29 | **0.966** | 0x020189 | 0.793 | 0.172 | 0.448 | 0.172 | **0.172** |
| Kernel_ServiceSoftTimers | 28 | **0.893** | 0x01FF7F | 0.286 | 0.179 | 0.429 | 0.214 | **0.214** |
| Kernel_KillTask | 22 | **0.909** | 0x02080B | 0.636 | 0.227 | 0.455 | 0.227 | **0.273** |
| IRQ_Epilogue | 20 | **0.950** | 0x01FFD0 | 0.500 | 0.400 | 0.450 | 0.400 | **0.400** |
| SoftTimer_Register | 20 | **1.000** | 0x02072A | 0.700 | 0.350 | 0.500 | 0.400 | **0.400** |
| Kernel_BlockSelf | 19 | 0.895 | 0x02014D | 0.895 | 0.368 | 0.421 | 0.421 | 0.421 |
| Kernel_ExitTask | 15 | 0.600 | 0x02014E | 0.600 | 0.133 | 0.467 | 0.200 | 0.200 |
| Kernel_SemaTryWait | 14 | 0.786 | 0x0204A9 | 0.571 | 0.286 | 0.429 | 0.357 | 0.357 |
| Kernel_Start | 13 | 0.538 | 0x01FEE7 | 0.462 | 0.385 | 0.615 | 0.462 | 0.462 |
| MsgQueue_Send_StackArg | 12 | 0.750 | 0x01FFFD | 0.750 | 0.583 | 0.500 | 0.583 | 0.417 |
| Kernel_ResumeTask | 9 | 1.000 | 0x01FF72 | 0.667 | 0.444 | 0.556 | 0.667 | 0.667 |

**20 of 26 routines** score 0.74–1.00 against an N5 null of 0.10–0.40, and every
one of them beats the P2 bar of 0.333 by a wide margin.

The bottom six are the SHORT ones (9–19 instructions) and they are **not
decidable on their own** — exactly as P3 predicted. They are placed in §6 by
order, not by score.

★ N1's own top hits are worth reading: they all land *inside* `0x01FBDA–0x020A0B`
too. That is not a nuisance, it is a result — they are the sibling routines of
the same kernel. Delete that region (N5) and nothing in the remaining 190 KB
comes close.

---

## 4. The negative controls (`--negative`) — this is not the compiler

8000 random offsets per image, same length-matched window:

| WSA1 kernel routine | n | KN5000 sub-CPU | **prom_b** | KN5000 main | KN5000 sub-boot |
|---|---:|---:|---:|---:|---:|
| MsgQueue_Send_NoDispatch | 80 | 0.887 | **0.175** | 0.887 | 0.113 |
| Kernel_InitRam | 78 | 0.949 | **0.167** | 0.962 | 0.090 |
| MsgQueue_Send | 71 | 0.915 | **0.169** | 0.915 | 0.127 |
| MsgQueue_ReceiveBlocking | 59 | 0.898 | **0.186** | 0.898 | 0.136 |
| Kernel_SemaSignal_NoDispatch | 55 | 0.945 | **0.236** | 0.945 | 0.164 |
| Kernel_SemaSignal | 48 | 0.938 | **0.229** | 0.938 | 0.167 |
| Kernel_StartTask | 45 | 0.978 | **0.200** | 0.933 | 0.156 |
| Kernel_SetTaskLevel_NoDispatch | 42 | 0.905 | **0.214** | 0.905 | 0.143 |
| MsgQueue_Receive_NoBlock | 41 | 0.805 | **0.220** | 0.805 | 0.146 |
| Kernel_SemaWait | 39 | 0.923 | **0.282** | 0.872 | 0.205 |
| Kernel_SetTaskLevel | 39 | 0.897 | **0.256** | 0.692 | 0.205 |
| Kernel_YieldRotate | 33 | 0.909 | **0.242** | 0.909 | 0.212 |

★ **prom_b is the control that closes the case.** Same product, same compiler,
same era, 512 KB of real TLCS-900 code — and *no kernel*: it reaches the kernel
through prom_a's thunk table (`FINDINGS-prom_a-kernel-lifecycle.md` §1). Kernel
routines max out at **0.17–0.28** there. Whatever this tool is measuring, it is
not "TLCS-900 code compiled by this compiler".

The **sub-CPU BOOT ROM** is the same story at 0.09–0.21: same processor as the
target, different image, no kernel.

★★ And the third column is the second headline of this note — see §7.

---

## 5. The order test (`--order`) — no threshold, no name, no score

If the KN5000's scheduler were merely a similar piece of code, its routines
would be laid out in its own order. Take the WSA1 kernel's routines in prom_c
ROM order, ask each one *independently* where its best match is, and count how
long an increasing run the answers form.

|  | sub-CPU payload | main program ROM |
|---|---:|---:|
| routines | 26 | 26 |
| longest **increasing** run of KN5000 sites | **21** | **21** |
| null: same sites permuted 200 000× — mean | 7.5 | 7.5 |
| null max over 200 000 permutations | 14 | 14 |
| times the null reached 21 | **0** | **0** |

p ≤ 5 × 10⁻⁶ empirically, and that is only the resolution of the permutation
count. The five routines outside the run are five of the six the null table
already flagged as too short to decide.

---

## 6. The name-free sweep (`--sweep`) — the naming confound, controlled

Both trees were labelled by agents on this project, so a name correspondence
could be a shared *naming habit* rather than shared code. Names are therefore
inadmissible, and `--sweep` uses none: candidate starts come from k-gram seeding
over eight phase-shifted linear decodes of the whole image.

It returns the same sites and the same scores as the symbol-anchored search
(`0x0204D5`/0.887, `0x02044F`/0.915, `0x020642`/0.898, `0x01FFFD`/0.978, …).
**The result does not rest on the sibling tree's labels.**

The order-constrained assignment in §7 goes further: its candidate starts are
*every byte* of `0x01F9DA–0x020C0B` (4657 of them).

---

## 7. ★★ The KN5000's MAIN CPU has it as well

The negative-control table above was meant to show a third image where the
kernel is absent. It showed the opposite: `kn5000_v10_program.rom` scores
0.69–0.96, matching the sub-CPU payload almost exactly.

Checked adversarially, because "the main ROM merely carries a copy of the
sub-CPU payload" would explain it:

* the bytes at the main-CPU hits are **not** in the payload file at all
  (`pay.find(chunk) == -1` for the sites tested);
* the main CPU's copy has its **own third RAM map** — current task `(0x0487)`,
  ready heads `0x04C5`, TCB base `0x0489`, **five** tasks against the sub-CPU's
  three and the WSA1's four, stack top `0x0001E53A`;
* it has an extra store and an extra TCB field initialiser the other three
  copies do not.

It is an independent build of the same kernel, not a copy of another one.

Its `Kernel_InitRam` is at **`0xEF1977`**, and the order test over the main ROM
gives the same 21-of-26 increasing run at the same p.

The order-constrained assignment over **every byte** of `0xEF1500-0xEF2800`
places all 26 routines at mean score **0.875**:

```
WSA1 kernel routine              prom_c     KN5000     score  cflow  the sibling tree's label there
Kernel_InitRam                   0xF9816B   0xEF1977   0.962   8/8   TaskSched_Init
Kernel_Start                     0xF98251   0xEF1A4E   0.615   0/0   TaskSched_LinkFreeSlots+22
Kernel_Dispatch                  0xF9827A   0xEF1AC9   0.742   3/3   TaskSched_Dispatch+9
Kernel_ResumeTask                0xF982C8   0xEF1B11   1.000   0/0   TaskSched_ReturnToDispatch
Kernel_ServiceSoftTimers         0xF982D1   0xEF1B1E   0.893   3/3   TaskSched_TimerTick+4
IRQ_Epilogue                     0xF9831C   0xEF1B6F   0.950   1/1   INTT3_CheckNesting
Kernel_StartTask                 0xF9833E   0xEF1B9C   0.978   0/0   Show_ScreenGroup_Entry
Kernel_ExitTask                  0xF983AF   0xEF1C16   0.867   0/0   Show_ScreenGroup_Entry_0x7A
Kernel_YieldRotate               0xF983DC   0xEF1C5F   0.909   0/0   TaskSched_YieldToQueue
Kernel_RotateQueue               0xF98425   0xEF1C63   0.906   1/1   TaskSched_YieldToQueue+4
Kernel_BlockSelf                 0xF98469   0xEF1CBD   0.895   0/0   TaskSched_YieldToQueue_NoBlock+21
Kernel_ReadyTask                 0xF98492   0xEF1CCB   0.966   0/0   TaskSched_YieldToQueue_NoBlock+35
Kernel_ReadyTask_NoDispatch      0xF984D2   0xEF1D28   0.966   0/0   TaskSched_WakeBySlotID+4
Kernel_SemaSignal                0xF98513   0xEF1DD4   0.875   1/1   TaskSched_SignalEvent
Kernel_SemaSignal_NoDispatch     0xF98587   0xEF1DD8   0.873   1/1   TaskSched_SignalEvent+4
Kernel_SemaWait                  0xF985FB   0xEF1E4F   0.872   1/1   TaskSched_SignalEvent_NoBlock+19
Kernel_SemaTryWait               0xF98654   0xEF1EB3   0.500   0/0   TaskSched_WaitForEvent+12
MsgQueue_Send_StackArg           0xF98672   0xEF1F08   0.750   0/0   TaskSched_WaitForEvent_Block+68
MsgQueue_Send                    0xF98684   0xEF1FEE   0.915   2/2   Audio_Lock_Acquire
MsgQueue_Send_NoDispatch         0xF98739   0xEF2074   0.887   3/3   TaskMsg_Send+4
MsgQueue_ReceiveBlocking         0xF987F1   0xEF213E   0.898   1/1   TaskMsg_Send_WakeReceiver+93
MsgQueue_Receive_NoBlock         0xF98881   0xEF2257   0.829   2/2   TaskMsg_Receive_Block+28
SoftTimer_Register               0xF988DD   0xEF2295   1.000   0/0   TaskMsg_TryReceive+35
Kernel_SetTaskLevel              0xF9890D   0xEF22C9   0.897   1/1   TaskTimer_Register
Kernel_SetTaskLevel_NoDispatch   0xF98967   0xEF22F9   0.905   1/1   TaskSched_ChangePriority+4
Kernel_KillTask                  0xF989C3   0xEF23AA   0.909   0/0   TaskSched_TCBTemplate
```

⚠ Corroboration, offered *after* the fact and not used as evidence: the KN5000
tree already names `0xEF1977` `TaskSched_Init` and `0xEF1AC0`
`TaskSched_Dispatch`. This tool found those addresses without reading that file.

---

## 8. What differs: three RAM maps for one kernel (`--constants`)

Aligned instruction pairs across the 26 routines: **686 identical text, 136
differing only in operands.** Every one of the 136 is an address, a count or a
relocation. Grouped (WSA1 sub-CPU → KN5000 sub-CPU):

| what | WSA1 prom_c | KN5000 sub-CPU |
|---|---|---|
| a byte cell below the map | `0x00F4` | `0x103C` |
| pending kernel ticks | `0x90` | `0x1044` |
| current task | `0x91` | `0x1046` |
| task control blocks | `0x0100` | `0x1048` |
| (queue heads, 11 sites) | `0x0120` | `0x1068` |
| ready-queue heads | `0x0124` | `0x106C` |
| semaphore wait queues | `0x0128` / `0x012C` | `0x1074` / `0x1078` |
| semaphore counts | `0x013B` / `0x013C` | `0x107F` / `0x1080` |
| message-queue wait queues | `0x0140` / `0x0144` | `0x1096` / `0x109A` |
| message-list heads | `0x0148` | `0x109E` |
| node pool | `0x0150` | `0x1082` / `0x10A6` |
| free-list head | `0x016C` / `0x0170` | `0x10C2` / `0x10C6` |
| software timers | `0x0174` | `0x10CA` |
| kernel stack top | `0x0000FA00` | `0x00040B1E` |
| ROM image of the semaphore counts | `0x00F9810E` | `0x0001FDBC` |
| TCB template | `0xFFF980DE` | `0x0001FD8C` |
| ready levels | `2` | `3` |

The **main CPU's** map, from the same measurement over `kn5000_v10_program.rom`:

| what | WSA1 prom_c | KN5000 main |
|---|---|---|
| a byte cell below the map | `0x00F4` | `0x047D` |
| pending kernel ticks | `0x90` | `0x0485` |
| current task | `0x91` | `0x0487` |
| task control blocks | `0x0100` | `0x0489` |
| (queue heads, 11 sites) | `0x0120` | `0x04C1` |
| ready-queue heads | `0x0124` | `0x04C5` |
| semaphore wait queues | `0x0128` / `0x012C` | `0x04CD` / `0x04D1` |
| semaphore counts | `0x013B` / `0x013C` | `0x04F8` / `0x04F9` |
| message-queue wait queues | `0x0140` / `0x0144` | `0x053F` / `0x054F` |
| message-list heads | `0x0148` | `0x0553` |
| node pool | `0x0150` | `0x0503` / `0x0567` |
| free-list head | `0x016C` / `0x0170` | `0x05B3` / `0x05B7` |
| software timers | `0x0174` | `0x05BB` |
| kernel stack top | `0x0000FA00` | `0x0001E53A` |
| ROM image of the semaphore counts | `0x00F9810E` | `0x00EF1933` |
| TCB template | `0xFFF980DE` | `0x00EF18EB` |
| ready levels | `2` | `3` |
| tasks | `3` | `5` |

★ The KN5000 column is **monotone in the WSA1 column**: the arrays appear in the
same order, with different sizes. That is a second, independent structural
signature — a coincidental resemblance has no reason to preserve the order of a
RAM map. This table is what `kernel/kernel_maincpu.inc` and
`kernel/kernel_subcpu.inc` would need a third and fourth sibling for.

---

## 8b. What it looks like — `Kernel_ServiceSoftTimers`, instruction by instruction

`python3 notes/kernel_structural_match.py --align Kernel_ServiceSoftTimers`
(28 instructions, score 0.893, control flow 3/3):

```
WSA1 prom_c                                  KN5000 sub-CPU
F982D4    inc 1,WA                           01FF7F    inc 1,WA
--                                           01FF81    ld (0x10d2),WA   (extra)
F982D6    ldc unknown,WA                     01FF85    ldc unknown,WA
F982D9    ei 0x00                            01FF88    ei 0x00
F982DB    ld IX,0x0174                       01FF8A    ld IX,0x10ca   <- operand
F982DE    extz XIX                           01FF8D    extz XIX
F982E0    ld B,0x02                          01FF8F    ld B,0x01   <- operand
F982E2    ld XWA,(XIX+0x04)                  01FF91    ld XWA,(XIX+0x04)
F982E5    cp XWA,0xffffffff                  01FF94    cp XWA,0xffffffff
F982EB    jr Z,0xf982f9                      01FF9A    jr Z,0x01ffa8
F982ED    ld WA,(XIX+0x00)                   01FF9C    ld WA,(XIX+0x00)
F982F0    dec 1,WA                           01FF9F    dec 1,WA
F982F2    ld (XIX+0x00),WA                   01FFA1    ld (XIX+0x00),WA
F982F5    or WA,WA                           01FFA4    or WA,WA
F982F7    jr Z,0xf9830b                      01FFA6    jr Z,0x01ffbf
F982F9    add IX,0x0008                      01FFA8    add IX,0x0008
F982FD    djnz B,0xf982e2                    01FFAC    djnz B,0x01ff91
F98300    ei 0x06                            01FFAF    ei 0x06
F98302    ldc WA,unknown                     --        (no counterpart)
--                                           01FFB1    ld WA,(0x10d2)   (extra)
F98305    dec 1,WA                           01FFB5    dec 1,WA
--                                           01FFB7    ld (0x10d2),WA   (extra)
F98307    ldc unknown,WA                     01FFBB    ldc unknown,WA
F9830A    ret                                01FFBE    ret
F9830B    ld WA,(XIX+0x02)                   01FFBF    ld WA,(XIX+0x02)
F9830E    ld (XIX+0x00),WA                   01FFC2    ld (XIX+0x00),WA
F98311    ld XWA,0x00f982f9                  --        (no counterpart)
--                                           01FFC5    lda XWA,0x01ffa8   (extra)
F98316    push XWA                           01FFCA    push XWA
F98317    ld XWA,(XIX+0x04)                  01FFCB    ld XWA,(XIX+0x04)
F9831A    jp T,XWA                           01FFCE    jp T,XWA
```

Read the differences, not the agreements:

* the timer array base `0x0174` → `0x10CA` and its count `2` → `1`;
* ★ `ldc WA,unknown` / `ldc unknown,WA` — the lock depth in **control register
  0x3C** on the TMP95C061 — becomes `ld WA,(0x10d2)` / `ld (0x10d2),WA`, a RAM
  word, because **the TMP94C241 has no such register**. That is a difference
  the *hardware* forces, not one a different author would make;
* `ld XWA,0x00f982f9` (push the loop's continuation, then jump to the callback)
  becomes `lda XWA,0x01ffa8` — the same idiom, PC-relative instead of absolute.

Everything else is the same instruction in the same order, including the
`0xFFFFFFFF`-means-empty test, the decrement-and-store, and the `jp T,XWA` tail
call into the callback.

---

## 9. What this does NOT establish

* **Who wrote it.** "One kernel in four processors across two Technics
  products" is consistent with an in-house RTOS, a Toshiba-supplied one, or a
  third-party one. Nothing here distinguishes those.
* **That the sources are identical.** The KN5000 sub-CPU `Kernel_Dispatch`
  scores 0.742, not 1.000: it has no tick-drain loop, it keeps its lock depth in
  a RAM word rather than control register `0x3C` (a TMP94C241 has no such
  register), and it writes a scaled priority to `(0x0131)` on the way out. These
  are real differences, not measurement noise.
* **The six short routines.** `Kernel_ResumeTask` (9 instructions),
  `MsgQueue_Send_StackArg` (12), `Kernel_Start` (13), `Kernel_SemaTryWait` (14),
  `Kernel_ExitTask` (15) and `Kernel_BlockSelf` (19) are **undecidable on their
  own scores**. They are placed by the order constraint, and that placement is
  an inference, not a measurement.
* **The sibling tree's labels in that block.** The structural match does not
  agree with all of them — the site matching WSA1 `MsgQueue_Send` is labelled
  `TaskSched_Wait` there, the one matching `Kernel_SemaSignal` is labelled
  `TaskEvent_Wait`, and the one matching `Kernel_KillTask` is
  `RingBuf_Access_Opaque_A`. On the main CPU the mismatches are sharper still:
  the site matching `Kernel_StartTask` at **0.978** is labelled
  `Show_ScreenGroup_Entry`, the semaphore-count ROM image is inside
  `TaskSched_ScreenGroupTable`, and the TCB template is inside
  `Checksum_ComputeComplement`. Those are **leads for the KN5000 lane**, not
  corrections made here; this lane is analysis-only in that tree.

---

## 10. What this corrects

1. **`notes/kernel_three_way.py`** — superseded. Byte identity was never going
   to answer this and its "0 matches" should not be quoted as absence.
2. **`notes/wave7_xref_tlcs900_family.py` §D**, "the shared bytes are DSP tables
   and math, not drivers", is still true *of byte-identical runs*. It now needs
   a companion sentence: **an entire multitasking kernel is shared between the
   two products and is completely invisible to a byte test**, because every one
   of its per-CPU constants is a RAM address and no RAM address survives the
   crossing (§A of that same document predicted exactly this).
3. **`notes/wave7_xref_tlcs900_family.py` §E** said positional alignment does
   not transfer across trees. Confirmed, and this is the replacement: LCS with
   gaps, a length-matched window, and five nulls.
