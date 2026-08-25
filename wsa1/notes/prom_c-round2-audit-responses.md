# Round-2 audit: what this lane fixed, and two things the audit could not have known

prom_c lane, 2026-08-25. The round-1 audit raised twelve findings; this file records
what was done about the ones that touch prom_c, and adds two corrections of the same
kind that were found while doing it.

## Fixed

**F3 — a cited call site that is not an instruction boundary.**
`prom_c/wsa1_prom_c.s` (the `DSP_ChannelRefresh_Loop` header) and
`notes/FINDINGS-prom_c-kernel.md` §3.3 both cited *"0xF98C69 in MAIN, 0xFA2DE0"* for the
two `Kernel_SemaSignal` call sites. Disassembled:

```
fa2ddc: f2 b4 f3 00 41  ld (0x00f3b4),A     <- 0xFA2DE0 is this instruction's LAST BYTE
fa2de1: 0b 02 00        push 0x0002
fa2de4: 1d 10 85 f9     call 0xf98510
```

and at the other site the `push` is 0xF98C69 and the `call` is 0xF98C6C. Two citations,
two different anchors, one of them invalid. Both now cite the **call** address with the
`push` named separately, and both were read off
`scripts/analysis/dis.sh c 0xFA2DD0 48` / `... c 0xF98C60 32`. The substantive claim —
exactly two `1D 10 85 F9` sites image-wide — is unaffected.

**F7 — "eight micro-DMA registers" is sixteen.**
`tmp95c061_cr_syms[]` (`../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1399`) holds
four rows of four: DMAM0-3, DMAC0-3, DMAS0-3, DMAD0-3. Corrected in
`notes/FINDINGS-prom_c-kernel.md` and in the kernel block comment. The conclusion it
supports — that MAME names no control register 0x3C, so leaving it as a number is right —
was and remains correct.

**F8 — the `di` residues.**
Two survived in prom_c and both are gone:

* the `EntryPoint_Records` header still described task 3's entry point as
  *"(`di` then `link XIZ,0xfffc`)"* with no correction anywhere near it. `06 00` is
  `EI 0`, which **enables** every maskable interrupt; a task entry point that began by
  disabling interrupts and never re-enabling them would be a different claim entirely.
* *"THE `di` SPELLING IS GONE FROM THIS FILE. All eighteen sites…"* was wrong twice: the
  count is **23** (`grep -oP '^\s+ei\s+\S+' | sort | uniq -c` → 23 `ei 0`, 35 `ei 6`,
  2 `ei 0x07`; `grep -cP '^\s+di\b'` → 0), and six PROSE lines still quote `di` because
  they are explaining the trap. The claim is now scoped to instruction lines and states
  the real count.

**F12 — an upper bound quoted as an exact count.**
`notes/prom_c_runtime_check.py` scans `1D <24-bit LE target>` at **every byte offset** of
the image with no instruction-boundary filter, and asserted the result as
`total == 1274`. The sibling tools (`prom_a_call_graph.py`, `prom_b_call_graph.py`,
`gen_prom_b_songstore_module.py`'s `direct_refs`) all label the identical scan an upper
bound. The script, the 0xFCA0BA block comment, all 29 runtime routine headers,
`notes/FINDINGS-prom_c-eeprom-and-runtime.md` and `notes/README-prom_c-tools.md` now say
UPPER BOUND. The assertion is kept as a regression check on the census, not as a claim of
truth. *Every entry has at least one site* survives as stated.

**F6 — "over all 35 pairs" where the table has 36, and "same lengths to the byte".**
`prom_c_kernel_map.py` has always run and printed **36** (the 35 contiguous rows of
`PAIRS` plus `INTT3_KernelTick`, which sits below the block and cannot be part of the
tiling); the docstring and the block comment said 35. Both corrected.

The length point is the more useful half, and the script now says so in three places: ONE
length column serves BOTH images, so equal lengths are an **input** to the comparison and
never an output of it. What `--pairs` now checks, and fails loudly on:

* the rows TILE each block with no gap and no overlap — **including the last row**, whose
  end is checked against the published block end in both images. Before this round the
  loop stopped one short and the final row's length was unchecked entirely. (The tree's
  own recurring defect: the last element is the one that hides the error.)
* every row's prom_c-minus-prom_a difference is the same constant **0x12B65**.

## Not fixed here, and why

**F4 — the README status table is stale.** `README.md` is shared by three lanes editing
concurrently; this lane's instructions scope it to `prom_c/wsa1_prom_c.s` and `notes/`.
The table should be regenerated from `scripts/analysis/source_coverage.py --markdown`
whole, by whoever integrates.

**F1, F2, F5, F9, F10** concern prom_a and prom_b and the round reports.

## ★ Two corrections the audit could not have made

**A. `source_coverage.py`'s "`.incbin` spans" column counts a SUBSTRING, not directives.**
`measure()` returns `text.count(".incbin")` — every occurrence of the string, including
the ones inside comments. Measured on this tree:

| | prom_c directives (`grep -cP '^\s*\.incbin'`) | prom_c `text.count(".incbin")` |
|---|---:|---:|
| start of round 2 | 14 | 27 |
| end of round 2 | 14 | 40 |
| 2026-08-25, round 3 | 14 | 41 |

⚠ The right-hand column is **not a property of the ROM and drifts with every sentence
anyone writes**: it went 40 → 41 between this file being written and the round-3 audit
reading it, purely from prose. Quote it only with the date and the command that produced
it. The left-hand column is the real one, and it has not moved.

The directive count did not move at all — this round SPLIT one span in two and REMOVED
one by converting 0xFE1280-0xFE12B4 — while the column moved by thirteen, because the new
block comment and routine headers mention `.incbin` thirteen more times in prose. The
column is therefore not a span count and never was.

This is worth stating plainly because the round-1 audit's F11 flags *"Converted spans
14 → 12 — nothing produces it"* and notes that `.incbin` **directives** went 16 → 14. Both
numbers in that dispute are directive counts; the shared tool's column is a third,
different quantity, and any report quoting it as "spans" is quoting prose mentions.

The directive count is `grep -cP '^\s*\.incbin' prom_c/wsa1_prom_c.s`. The fix belongs in
`scripts/analysis/`, which is another lane's directory; **the numbers in this lane's report
are directive counts and say so.**

(The `substantive`, `filler` and `still .incbin` columns of the same table are exact — they
sum the `.incbin` LENGTH arguments and the `.fill` products, and neither can be spoofed by
prose. Only the last column is a substring count.)

**B. A literal census cannot see a structure member reached through a base pointer.**
`Link_Ch0_AppendToRing`'s header recorded *"Unknown: what 0x00E2EF counts — it is written
here and by nothing else that names it, and read by nothing that names it."* Converting
`MidiIn_ParseRingAndDispatch` this round showed 0x00E2EF is the ring's **byte count**: the
parser's entry guard is `cp DE,4` on it and every arm does `decw 4` on it. No instruction
in the image spells 0x00E2EF, because the parser reaches it as `descriptor+4` through the
pointer MAIN pushes.

The sentence was right about the census and wrong about the fact. Corrected in place, with
the general form of the lesson attached: **"no reference found" is a far weaker statement
for a struct FIELD than for a routine**, and a header recording a searched negative should
say which kind it is.

## Re-runs, after this lane's round-6 work

| tool | before | after |
|---|---|---|
| `notes/prom_c_audit_callsites.py` | 364 cited / 29 not decoding | **421 cited / 29 not decoding** (57 new citations, 0 new failures) |
| `notes/prom_c_header_audit.py` | 309 labels, tier C = 0 | **337 labels, tier C = 0** |
| `notes/prom_c_kernel_map.py --selftest` | PASS (35 claimed / 36 run) | PASS (36 claimed / 36 run, last row now boundary-checked) |
| `notes/prom_c_runtime_check.py` | ALL CHECKS PASS | ALL CHECKS PASS |
| `notes/prom_c_voice_module_check.py --selftest` | — | ALL CHECKS PASS (12 sections) |
| `notes/prom_c_frontier_src.py --selftest` | — | SELFTEST PASS |
| `scripts/analysis/assert_byte_identical.py` | PASS | PASS |

Two citations added this round were flagged by `prom_c_audit_callsites.py` on a first
draft — `0x007ED1` and `0x00E2EB`, both addresses that appeared as prose inside a
`Called from:` paragraph and neither a call site. Both were moved out of that paragraph
rather than explained away, which is why the flagged count is unchanged at exactly the
same 29 rows as before.

> ★★ **RETRACTED 2026-08-25 (round-3 audit, finding F7).** "Both were moved" was half
> true. `0x00E2EB` was moved; **`0x007ED1` was not** — it was still inside the
> `Called from:` paragraphs of `Analog_ScanAndReport` and `Link_ServiceTask`, and the
> auditor still flagged it twice. It was not two drafts either: **ten** of the
> 29 flagged rows were RAM or prose addresses sitting inside `Called from:` blocks,
> a systemic property of harvesting every `0xXXXXXX` in a paragraph of prose.
>
> Worse, the number this paragraph rests on — "29 rows" — had **no meaning**, because
> the tool put a mis-cited call site and a variable name in the same bucket. Round 3
> classified every non-decoding row against the ROM
> (`python3 notes/prom_c_audit_callsites.py --quiet`), and **three of the 29 were
> `OFF-BY-N`: a literal transfer to the routine beginning within eight bytes of the
> cited address but not at it — the exact defect this tree has committed ~20 times.**
> Two were `KeyScan_ReadEvent` (the header named the *literal* addresses 0xF98CD5 /
> 0xF98D10 alongside the correct instruction starts) and one was
> `KeyScan_InitKeyStateBitmap`, whose `Called from:` gave the calling routine's entry
> 0xF997FA where the site 0xF997FF belongs. All three headers are fixed.
>
> After the round-3 fixes: **410 cited / 18 not decoding — OFF-BY-N 0, RAM 0,
> PTR32 10, IN-ROUTINE 1, PROSE 7.** The cited total fell from 421 to 410 because
> eleven harvested addresses were prose that no longer sits in a `Called from:`
> paragraph; no call-site claim was removed. `--selftest` runs six negative controls
> on the classifier, including a last-element control (the highest `call 0xf9a038`
> site is 0xFC575B) and a positive control that an address one byte past a real site
> IS reported as OFF-BY-N.
