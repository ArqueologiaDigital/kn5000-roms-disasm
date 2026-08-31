# prom_c round 3 — ten modules, a zero frontier, and three tools that found what the byte gate cannot

prom_c lane, 2026-08-25.

**Gate: PASS** before, after every edit, and at the end.
**prom_c substantive coverage: 47,284 (9.0%) → 222,190 (42.4%), +174,906 bytes, 0 of it `.fill`.**
**prom_c frontier: 91 targets / 236 sites → 0 / 0.**

---

## 1. What was converted

Ten contiguous blocks, every one chosen by `notes/prom_c_frontier_src.py --clusters` or
`--range`, never by address order. Each was cut at a `ret`/`link XIZ` pair read out of the
bytes, and each cut is printed in its own block comment.

| # | range | bytes | routines | arms | tables | why it was next |
|---|---|---:|---:|---:|---:|---|
| 1 | 0xFA7E2C-0xFABE2F | 16,388 | 60 | 22 | 4 | 40 of 91 frontier targets, 89 of 236 sites |
| 2 | 0xFA5949-0xFA7E2B | 9,443 | 68 | 0 | 0 | 42 of 98, 208 of 346 — module 1's own callees |
| 3 | 0xFC3407-0xFC856B | 20,837 | 86 | 0 | 0 | 32 of 57, five clusters in one run |
| 4 | 0xFABE30-0xFACE66 | 4,151 | 23 | 0 | 0 | closed a whole `.incbin` span |
| 5 | 0xFAD142-0xFB0503 | 13,250 | 99 | 48 | 1 | ditto |
| 6 | 0xFB405F-0xFB6E09 | 11,691 | 55 | 25 | 8 | ditto |
| 7 | 0xFB7345-0xFB7714 | 976 | 9 | 0 | 0 | ditto |
| 8 | 0xFB828E-0xFC3406 | 45,433 | 113 | 179 | 18 | the last big code span with frontier targets |
| 9 | 0xF9A050-0xFA5948 | 47,353 | 75 | 31 | 2 | ditto |
| 10 | 0xFC8BB2-0xFCA0B9 | 5,384 | 12 | 0 | 0 | held the last 4 frontier targets (54 sites) |
| | **total** | **174,906** | **600** | **305** | **33** | |

**600 routine headers**, **33 computed-goto tables** decoded as `.long` (**496 entries**),
**2,289 verified call-site citations added** (410 → 2,699).

## 1a. ★ The count that was wrong twice, and how the file caught it both times

`notes/prom_c_module_map.py` derives candidate routine entries and their call sites partly
from a **byte-pattern scan**, which reports a call wherever a `1D`/`1E` happens to sit inside
a longer instruction — at 0xFAC2F7 the bytes `10 02 00 00` are the tail of
`ld (XIX+0x10),0x0000`.

1. **Entries.** The tool first said **761** routines. `prom_c_apply_headers.py` silently drops
   a header whose address matches no listing line, so the file carried **645**. The
   discrepancy was found by counting headers in the source and comparing with the tool.
   The tool now drops every candidate that is not an instruction boundary in
   `prom_c/wsa1_prom_c.s`, and every candidate inside a table span.
2. **Sites.** A direct census then showed **147 of the 2,987 ROM addresses the generated
   headers cited as call sites — 5% — were not instruction boundaries either.** The tool now
   keeps a site only where the file's own decode agrees it is an instruction, and **only
   where the file demonstrably decoded that neighbourhood** (an `; ADDR` comment within
   ±64 bytes) — because the round-1 blocks near 0xF98000 comment their lines symbolically and
   the data pools carry no instruction addresses at all, and dropping sites there would hide
   real callers rather than noise. Of 7,262 raw pattern hits, **212 are dropped**.

All ten blocks were regenerated and re-spliced with both filters. **Tool and file now agree
at exactly 600 routines**, `--selftest` pins three of the false entries (0xFAC2F7, 0xFAC826,
0xFBF236), and re-running the generator on two blocks reproduces byte-identical header files
(convergence checked, not assumed). Knock-on corrections, each made in place with the reason:
module 1's call census 47/128 → **41/126** and its caller span low end 0xFA2258 →
**0xFABE52** (0xFA2258 was noise); module 2's 256/55 → **254/54** and `sub_FAA61A` removed
from its caller list; module 3's 180/88 → **173/81**.

Every block: `notes/gen_prom_c_block.py` → `notes/gen_prom_c_block_headers.py` →
`notes/prom_c_apply_headers.py` → `notes/prom_c_verify_fragment.py` → splice →
`scripts/analysis/assert_byte_identical.py`. The commands are in each block's own comment.

## 2. ★ The check that the byte gate cannot make — and what it caught

A round trip proves a listing **rebuilds** the bytes. It does not prove the listing **read**
them at the right offsets: a misaligned decode of data can re-encode to the same bytes and
sail through the gate.

`notes/gen_prom_c_block.py` therefore requires, for every block, that **every
`call`/`calr`/`jp`/`jrl`/`jr` target named by a decoded instruction and landing inside the
block is the start of a listing line**. Totals actually checked: 436, 305, 623, 112, 414,
313, 2, 1339, 699, 102 distinct targets — **4,345 in all, zero violations at ship time**.

It earned its keep three times:

1. **The first attempt at block 1 rebuilt 0xFA9024 as 0x26 where the ROM holds 0x25.** Four
   computed-goto tables sit in the middle of that block; the linear decode read their
   pointer bytes as instructions and the branch relabelling then shifted a displacement.
2. **It found a jump-table idiom the table scanner did not know.** `notes/prom_c_jumptables.py`
   matched only the `XWA` form of the dispatch and declared 0xFAD142-0xFB0503 table-free. The
   alignment check failed on one target, and the cause was a **49-entry `XBC`-form table at
   0xFAF08F** — `cp BC,0x30 / jrl UGT / sll 2,BC / add XBC,0x00faf08f / ld XBC,(XBC) / jp (XBC)`.
   The scanner now knows both register pairs and its `--selftest` pins that table.
   Image-wide it now finds **38** tables, **544** entries, and guard+1 == contents for
   every one of them.
3. **Its first draft was itself wrong**, and had to be rewritten. Taking the call SITES from
   a byte-pattern scan for `1D`/`1E` produced six phantom "misalignments": at 0xFA8972 the
   `1E` is the displacement byte of the `jr` at 0xFA8971, and reading it as a `calr` invents
   a call to 0xFA8813. The check now takes sites **only from decoded instructions** — the
   `; ADDR <text>` comments of the source file and of the listing under construction.

## 3. Structure decoded, all of it re-derivable

* **Duplicated routines.** `notes/prom_c_module_map.py <lo> <hi> --dups` finds equal-length
  routines differing in ≤ 12.5% of their bytes and tests every differing byte against the
  `calr` that owns it.
  * Block 2 holds **three BYTE-IDENTICAL pairs**: 0xFA727D/0xFA72B3 (54 bytes),
    0xFA7598/0xFA78C6 (34), 0xFA766C/0xFA7D03 (70). ⚠ **The copies are not equally used**:
    0xFA7598 was the most-called address in the whole prom_c frontier (60 literal sites) and
    its twin 0xFA78C6 has **zero**; 0xFA766C has 14 and its twin has 1. A call through a
    register is invisible to that scan, so "zero" is *no literal transfer found*, not *dead*.
  * Block 1 holds three near-pairs; in two of them **every** differing byte is a `calr`
    displacement to the **same** target (0xFA8347/0xFA83CC, 97 bytes, one differing byte;
    0xFAA87E/0xFAAC00, 238/4). A non-pair control (0xFA8347 vs 0xFA842D) differs in 89 of
    97 bytes, so the test is not vacuous.
    > ⚠ **A fourth pair was retracted the same day.** It read *0xFA8D9B/0xFA8E47, 71 bytes,
    > 1 byte differs*. The 71-byte statement is true — the sole difference in the first 71
    > bytes is at +0x1B, the low half of a `calr 0xFA778E` displacement — but the two
    > routines are **not the same length**: the pair existed only because two byte-pattern
    > false entries (0xFA8DE2, 0xFA8E8E) cut both at 71 bytes. With the filter their extents
    > are 172 and 176. The retraction is asserted in the checker, not just written down.
  * Block 3 holds **nine** pairs, six of them differing in a single byte.
  * The shape shows plainly in block 3: **0xFC37BE, 0xFC37E2 and 0xFC3806 are the same 36-byte
    routine three times, differing only in the displacement of a `ld W,(XBC+n)` — n = 0x09,
    0x0A, 0x0B.** One accessor per struct field.
* **The two dispatchers of block 1 are one routine with one byte changed.**
  `VoiceParam_DispatchOn_17_36` (0xFA8BDD) and `VoiceParam_DispatchOn_17_11` (0xFA900A) are
  64 bytes, share their first twelve, both do `ld XBC,(XHL+0x17)`, and differ semantically in
  exactly one byte: the field read next is +0x36 in one and +0x11 in the other. In all four
  of block 1's tables **entry 0 is the same address the out-of-range guard branches to**, so
  index 0 and index > 5 are not distinguished. Asserted by
  `notes/prom_c_voiceparam_checks.py` sections 2 and 5.
* **An open question elsewhere in the file is closed.** `MidiIn_ParseRingAndDispatch`'s
  header listed as Unknown *"the call to 0xFA5949 at 0xFB061F, made with the byte count
  pushed, before any parsing happens"*. `sub_FA5949` is fifteen bytes:
  `ld BC,(XIZ+0x08) / ld (0x008678),BC / ret`. What 0x008678 is *for* is still not
  established; what the call does is. The header now says so.

## 4. Naming discipline

**No routine converted this round is named for what it does.** 598 of the 600 are
`sub_XXXXXX`; the two exceptions name only an instruction operand (which struct field the
dispatch switches on) and carry the byte-level evidence for it. Every header states the frame
size, the argument slots read, the absolute addresses read and written, the routines called
(marked converted / UNCONVERTED) and the call sites — operands and decoded-instruction scans,
nothing interpreted.

`python3 notes/prom_c_header_audit.py` → 347 semantic labels, **tier C = 0**.
`python3 notes/prom_c_audit_callsites.py --quiet` → **2,699 cited sites, 18 not decoding,
OFF-BY-N 0, RAM 0** (PTR32 10, IN-ROUTINE 1, PROSE 7).

## 5. What is left, and why

Eight `.incbin` spans, 180,082 bytes, and **not one literal control transfer from converted
code reaches any of them** — the frontier is 0/0. They are therefore either data or reached
only indirectly, and the frontier tool cannot rank them. The two large ones are
0xF80000-0xF97FFF (98,304 bytes, the region `notes/FINDINGS-fonts.md` covers) and
0xFCD0F7-0xFDD2AA (65,972, adjacent to the float pool and the tables at 0xFDD2AB).
**Choosing among them needs a different instrument than the call-graph frontier** — a data
census, or the pointer tables that reach them. That is the next round's first problem, not a
conversion task.

★ **UPDATE 2026-08-25: both are done, and the prescription above is what worked.** The preset
bank went in wave 5 round 1 (`notes/FINDINGS-prom_c-preset-bank.md`) and `0xFCD0F7-0xFDD2AA` in
round 2 (`notes/FINDINGS-prom_c-p7-byte-stream-pool.md`) — the latter by exactly the "pointer
tables that reach them" route: every 32-bit pointer into the region, plus the `lda rr,#imm24`
literals, seeded a walk of its interpreter's own length field. prom_c now has 11,005 bytes of
`.incbin` left in 5 spans.

## 6. ⚠ A leak in a tool this lane does not own

`scripts/analysis/llvm_roundtrip.py:81` does `d = tempfile.mkdtemp()` and never removes it.
Every invocation leaks one directory holding the candidate `t.s`. During this round `/tmp`
(a 17 GB tmpfs) reached 100% full with **136,000+** leaked `tmp*` directories, which stopped
the harness mid-round. It is not a prom_c file, so it is reported rather than fixed:
wrapping that in `tempfile.TemporaryDirectory()` would end it.

## 7. Re-runs at the end of the round

| tool | result |
|---|---|
| `scripts/analysis/assert_byte_identical.py` | **PASS** (run after every edit, ~40 times) |
| `scripts/analysis/source_coverage.py` | prom_c **47,284 (9.0%) → 222,190 (42.4%)**, filler unchanged at 122,016 |
| `notes/prom_c_frontier_src.py` | **0 targets / 0 sites**; completeness check clean (0 unmatched literals) |
| `notes/prom_c_frontier_src.py --selftest` | SELFTEST PASS |
| `notes/prom_c_audit_callsites.py --strict` | 2,699 cited / 18 not decoding / **OFF-BY-N 0, RAM 0**; exit 0 |
| `notes/prom_c_audit_callsites.py --selftest` | SELFTEST PASS (6 controls) |
| `notes/prom_c_header_audit.py` | 347 semantic labels, **tier C = 0** |
| `notes/prom_c_module_map.py --selftest` | SELFTEST PASS (incl. 3 false-entry controls) |
| `notes/prom_c_jumptables.py --selftest` | SELFTEST PASS (incl. the BC-form table) |
| `notes/prom_c_voiceparam_checks.py --selftest` | ALL CHECKS PASS (8 sections) |
| `notes/prom_c_voice_module_check.py --selftest` | ALL CHECKS PASS |
| `notes/prom_c_runtime_check.py` | ALL CHECKS PASS |
| `notes/prom_c_kernel_map.py --selftest` | SELFTEST PASS |
| `notes/prom_c_link_state_machine.py --selftest` | SELFTEST PASS |
| `notes/prom_c_dup_image.py --selftest` | selftest: OK |
| `notes/prom_c_flash_driver_check.py` | ALL CHECKS PASS |

## 8. Round-2 audit findings that touched prom_c, and what was done

* **F1 — the voice record's extent, wrong by 1,888 bytes.** `0x00003BCF-0x0000456E` is 2,464
  bytes = 36.2 records where the same sentence says 4,352. Fixed to
  **0x00003BCF-0x00004CCE** in `prom_c/wsa1_prom_c.s`, in
  `notes/FINDINGS-prom_c-voice-module.md` and in the checker — where the bare `print` the
  audit correctly identified as the one uncovered number in section 5 is now four `check()`s
  that read base, stride and count **out of the ROM operands** and assert the extent on
  record 63, the last one the `cp H,0x40` bound admits.
* **F3 — the retracted arm length surviving in `Outputs:`.** "advanced by 4 (5 for the 0xC0
  arm)" replaced by the per-arm lengths, with the 0x80 arm's `cp DE,6` at 0xFB068A cited.
* **F6 — a cluster figure attributed to a tool that prints no such cluster.** "39 of the 91
  targets and 87 of the 236 sites" was three `--clusters` rows hand-summed, and the sum
  dropped the 0xFA8BDD cluster that lies inside the range. The true figures are **40 and 89**,
  and `prom_c_frontier_src.py --range LO-HI` now exists so a range census comes from the tool
  instead of from arithmetic on its output.
* **F7 — "both were moved" was half true, and the number it rested on had no meaning.**
  `0x007ED1` had *not* been moved; ten of the 29 flagged rows were RAM or prose addresses
  inside `Called from:` paragraphs. All ten headers were restructured so `Called from:` holds
  call sites only. More importantly the auditor now **classifies** every non-decoding row, and
  the first run found **three `OFF-BY-N` rows** — the exact defect this tree has committed
  ~20 times — hidden inside the old count. All three fixed; the count is now 0 and `--strict`
  makes it fatal.
* **F8 — `.incbin` spans reported 40, tool printed 41.** The right-hand column of that table
  is `text.count(".incbin")`, a substring count that drifts with every sentence anyone writes;
  it moved 40 → 41 between the note being written and the audit reading it, from prose alone.
  The table now carries the date and the command, and says plainly that only the directive
  count (14, unmoved) is a property of the file.
* **F2, F9, F11 — not fixed here, and why.** F2 is a round-report defect, not a file: this
  report states the before/after from one tree state and names the tool. F9 (`README.md` is a
  stale snapshot) is a shared file that other lanes were editing concurrently during this
  round; writing to it risks losing their work, so it is left. F11 (the evidence base is
  uncommitted) is forced by the harness — this lane is instructed not to `git commit`.
