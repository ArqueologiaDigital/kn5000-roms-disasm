# Wave 7, round 1 — the recon ledger

Ten read-only lanes, each followed by an independent skeptic. **Nothing here has been applied to
a `.s` file or a findings document yet**, and several entries must be corrected before any of it
is. This file is generated from `round1-results.json`, which is the run's raw return value.

Regenerate with `python3 notes/wave7-round1/render_ledger.py`.

**What has been DONE about these is tracked separately, in `APPLIED.md`.**

## Status at a glance

| lane | target | verdict | fatal | serious | minor |
|---|---|---|---:|---:|---:|
| a1 | prom_a 0xFAD800 | not refuted | 0 | 1 | 12 |
| a2 | prom_a 0xFA5AEB | not refuted | 0 | 2 | 9 |
| a3 | prom_a 0xFA1404 | not refuted | 0 | 3 | 4 |
| a4 | prom_a 0xF85FF9 | *unverified* | 0 | 0 | 0 |
| b1 | prom_b 0xF17559 | **REFUTED** | 1 | 6 | 6 |
| b2 | prom_b 0xF4F000 | *unverified* | 0 | 0 | 0 |
| b3 | prom_b 0xF067A6 | not refuted | 0 | 4 | 4 |
| c1 | prom_c bytecode VM | *unverified* | 0 | 0 | 0 |
| g1 | gap A registers | not refuted | 0 | 1 | 5 |
| d1 | doc contradiction audit | not refuted | 0 | 2 | 6 |

`unverified` means the lane produced a dossier but its skeptic died on an API error, or the lane
itself died. **An unverified dossier is not evidence.** In this project's history every documented
error was gate-clean and plausible, so a dossier nobody attacked has the status of a hypothesis.


## The corrections owed, per lane

These are what the skeptics reproduced against the ROM. Each must be fixed in the lane's committed
script and in any prose derived from it **before** the span is converted.


### a1 — recon:prom_a 0xFAD800

* **SERIOUS — Segment 0xFAE3A2 evidence: "192 LE32 slots inside the span, 88 of them the 0xFFFFFFFF 'no handler' marker the reader tests at 0xFADB69".**
  The count is 116, not 88. Read straight from original_ROMs/wsa1_prom_a.ic12: of the 192 slots at 0xFAE3A2, 116 are 0xFFFFFFFF and 76 hold real in-span targets (pointing at only 14 distinct handlers). No mode of prom_a_fad800_layout.py prints 88 -- not --tables, not --selftest, not the default report -- so this is a quantified claim reproduced by no script AND contradicted by the ROM. It is the same shape as this project's recorded 'a handler count of 35 that was 34'. The segment boundary itself (768 bytes, 192 entries) is correct and independently confirmed, and the table really is sparse, so the structural conclusion survives -- but the number must be corrected to 116 empty / 76 filled before any of this prose reaches a routine header.

* **MINOR — Verdict: "Module 1 ... and module 2 ... are ordinary dispatched code with 19 inline jump tables between them plus a 192-entry sparse handler table at 0xFAE3A2".**
  There are 18, not 19. The layout has 21 pointer_table segments; removing the 192-entry dispatch table at 0xFAE3A2 and the two 33-entry blob tables (0xFAF7E8, 0xFB0700) leaves 18 -- ten in module 1 (0xFADBA9, 0xFADCBE, 0xFADD77, 0xFADDA0, 0xFADDC1, 0xFADDF1, 0xFADF77, 0xFAE04D, 0xFAE28F, 0xFAE30E) and eight in module 2 (0xFAE802, 0xFAE82A, 0xFAE9D0, 0xFAEDF0, 0xFAEE5C, 0xFAF16C, 0xFAF410, 0xFAF6B8). Related: the committed script's own docstring says "a linear decode ... desynchronises inside the first module -- there are eight inline jump tables in it", and module 1 has ten.

* **MINOR — Segment 0xFADD87-0xFADD9F evidence: "accept()-promoted run 0xFADD89-0xFADDA9".**
  --accepted prints 0xFADD89-0xFADD9F, 23 bytes. The quoted upper bound 0xFADDA9 runs 10 bytes past the segment and straight through the pointer_table at 0xFADDA0-0xFADDA7, which the same dossier frames as a segment. The segment boundary is right; the cited range is not.

* **MINOR — Segment 0xFADDC9-0xFADDF0 evidence: "entries of the table at 0xFADDC1 plus accept()-promoted 0xFADDCA-0xFADDF0".**
  --accepted lists no promoted run anywhere in 0xFADDC9-0xFADDF0; its 26 runs are 0xFAD801, 0xFAD806, 0xFAD819, 0xFAD846, 0xFAD86C, 0xFAD886, 0xFAD89D, 0xFAD8B8, 0xFAD8D9, 0xFAD8FA, 0xFAD98B, 0xFAD9AC, 0xFAD9C7, 0xFADD89, 0xFADF0D, 0xFAE02E, 0xFAE049, 0xFAE2DE, 0xFAE823, 0xFAE84B, 0xFAE861, 0xFAEA11, 0xFAEBAB, 0xFAEC79, 0xFAED7D, 0xFB19E8. The segment is actually BETTER evidenced than claimed (both entries of table 0xFADDC1 are 0xFADDC9 and 0xFADDCA, so it is pure descent), but the stated fact is false.

* **MINOR — Reclist A evidence: "Targets 0x7F32..0x7F3C step 1, LAST record (index 10, 0xFB1A74) = 0x7F3C".**
  Index 10 is at 0xFB1A3E + 10*6 = 0xFB1A7A, whose target is 0x7F3C. 0xFB1A74 is index 9, target 0x7F3B. The value quoted is right and the list really does run 0x7F32..0x7F3C on 11 records (verified record by record from the ROM); only the address of the last record is off by one record.

* **MINOR — Segment 0xFADBD9 evidence "entry [0] of the table at 0xFADBA9", and segment 0xFADD87 evidence "entry [0] of the table at 0xFADD77".**
  In both tables entry[0] is 0xFAE2E2, not the segment start. Table 0xFADBA9 = [0xFAE2E2, 0xFADBD9, 0xFADBD9, 0xFADC20, 0xFADC42, 0xFADC7E x7]; table 0xFADD77 = [0xFAE2E2, 0xFADD87, 0xFADD87, 0xFADD88]. The correct citations are entry[1]/[2] in each case. The segment starts ARE table entries, so the layout is unaffected.

* **MINOR — Segment 0xFAD800 evidence: "descent from thunk targets T_F40860->0xFAD800, T_F4085C->0xFAD805, T_ParamApply_MaskedWriteAndPublish->0xFAD80A and 12 more"; segment 0xFADE01 evidence: "descent from thunk targets T_ParamReset_SixParamsForIndex->0xFADE8**
  Off-by-one and an omission. Recomputed from the prom_b thunk directory: 16 thunk targets land in 0xFAD800-0xFADBA8, so after naming three it is "13 more", not 12. And 0xFADE01-0xFADF76 contains THREE thunk targets, not two -- T_ParamApply_ByModeOfParam80->0xFADF1E is missing from the list. The 33-slot total is still exactly right (16+3+1+1+1+4+4+2+1 = 33).

* **MINOR — Segment 0xFAE822-0xFAE829 evidence: "eight 0x0E bytes that are the targets of the table at 0xFAE802".**
  Only six of the eight are targets of that table (0xFAE822, 24, 25, 26, 27, 28). 0xFAE823 is not referenced by it at all -- it is one of the 26 accept()-promoted runs -- and 0xFAE829 is reached from thunk T_F41F3C and calr 0xfae829 at 0xFAE857, not from the table. The bytes really are eight 0x0E, verified.

* **MINOR — Verdict: "Between module 2's code and module 3 sits a 10.5 KiB parameter store ... each framing ~3.5 KiB of 4-byte records".**
  0xFAF7A6 (first byte after module 2's code) to 0xFB1800 (module 3) is 8,282 bytes = 8.1 KiB, of which 7,150 bytes (7.0 KiB) are the maps, pointer tables and blobs and 1,132 are pad. Even taking it to the end of the span it is 10,330 bytes = 10.1 KiB. And blob 2 is 3,088 bytes = 3.0 KiB, which "~3.5 KiB" overstates (blob 1 is 3,732 = 3.6 KiB).

* **MINOR — notes/prom_a_fad800_layout.py's docstring: "26 code runs totalling ~306 bytes (~4%) are accept()-promoted".**
  The script's own --accepted prints "26 runs, 261 bytes (3.7% of the 7107 code bytes)". The docstring of the one committed artefact disagrees with the artefact's output by 45 bytes. The dossier itself quotes the correct 261/3.7%, so this is a defect in the script that must be fixed before the coordinator commits it.

* **MINOR — notes/prom_a_fad800_layout.py's docstring: "notes/prom_a_module_frontier.py ranks it top by contiguous unconverted extent summed over the thunk runs that point into it".**
  Summed, this span's runs give 3216 + 2595 + 0 = 5,811. The 0xFA5AEB-0xFAA000 span's runs (T_MidiIn_ReqListRebuild_Msg13_16 8,886; T_F40744 7,668; T_F40714 245) sum to 16,799, and T_MidiIn_ReqListRebuild_Msg13_16 alone outranks anything here -- prom_a_module_frontier.py --n 20 puts this span's runs at ranks 4, 6 and 13. The span IS prom_a's largest remaining .incbin (18,432 B), which is what WAVE7-BRIEFING.md says and is a perfectly good justification; the frontier-summed claim is not. The dossier does not repeat this claim, only the script does.

* **MINOR — Summary: "this is the ONLY place the layout is wrong and it is 6 + ~48 bytes".**
  Stronger than the method supports. --tablebases finds unframed data only where DECODED CODE loads the base as a 32-bit immediate; a byte table reached through a 16-bit address, an lda, or a pointer already in RAM would be invisible to it, and --selftest asserting "the list is exactly these two" only pins that route. My own independent sweep for constant-byte runs >= 6 inside code segments found nothing beyond 0xFADD30's zero runs and the legitimate 8 x 0x0E stub block, which supports the claim -- but "ONLY" should be "the only one this method can see".

* **MINOR — --selftest is the artefact that re-proves the layout.**
  Robustness nit found by mutation testing: when a PTRBLOB stops qualifying, selftest() prints the FAIL for 'PTRBLOB count' and then dies with an uncaught IndexError at notes/prom_a_fad800_layout.py:930 (`b0 = [b for b in blobs if b[0] == 0xFAF7E8][0]`), so the remaining ~40 checks never run and the failure summary is never printed. Exit status is still non-zero, so nothing is silently passed, but a future lane debugging a moved boundary gets a traceback instead of a report.


### a2 — recon:prom_a 0xFA5AEB

* **SERIOUS — ~31 per-segment evidence lines of the form "Base loaded at 0xFA6046" / "Base loaded at 5 sites: 0xFA71D4, 0xFA7417, 0xFA745F, 0xFA74A7, 0xFA7562" / "Base loaded at 0xFA6489, 0xFA64F8, 0xFA6539, ... 0x**
  SYSTEMATIC OFF-BY-ONE — the project's signature documented failure. I dumped the byte at cited-1 for all 31 of them: 31 of 31 are 0x44/0x45/0x46, i.e. the opcode of the `ld XIX/XIY/XIZ,imm32` that does the load. Every cited address is the 32-bit IMMEDIATE, one byte past the instruction. Example proven by prom_a/roundtrip.py: the instruction is `ld XIZ,0x00fa607a ; FA6045 46 7a 60 fa 00`, and the dossier cites 0xFA6046. The dossier is also internally inconsistent: the two sites where it quotes the byte string (0xFA7514 `45 20 75 fa 00`, 0xFA83AE `44 c0 83 fa 00`) ARE instruction addresses, so two conventions are mixed. Worse, the committed script does not print these site addresses at all — `named` collects only the VALUES named, never the sites — so not one of the 31 is reproduced by a committed script. Ironically --selftest check C explicitly verifies that the ONE branch citation (0xFA5

* **SERIOUS — "0xFA8FF8 is 800 sixteen-bit RAM addresses = 25 blocks of 32" ... "together tiling a 32-record RAM array of 0x40-byte records around 0x7670-0x7EEF" ... "a 32-part MIDI-controller / parameter store and**
  MATERIAL OMISSION. I read the 800 entries out of the ROM: the 25 blocks are IDENTICAL. set() of the 25 32-tuples has size 1; set() of all 800 values has size 32. All 3,200 bytes hold only 32 distinct addresses (0x76AF..0x7EAF, 31 steps of 0x40 with one 0x80), repeated 25 times. "25 blocks of 32" reads as 25 different blocks and it is one block 25 times. --selftest check K verifies the count, the block arithmetic, the first entry, the last entry and the terminator — but never checks distinctness, so the property that would have caught this is the one check missing. This weakens the stated reading directly: if the row index selects nothing, the table cannot be the per-parameter dispatch layer the verdict describes, and the per-parameter offset must come from somewhere else. It belongs in open_questions and is not there.

* **MINOR — "then a 6,656 B data zone" (verdict).**
  Wrong and reproduced by nothing. The data zone the dossier itself bounds — 0xFA83C0-0xFA9C77, the bytes between the last code segment and the padding — is 6,328 bytes (0xFA9C77-0xFA83C0+1). Off by 328. No mode of the script prints 6,656 and I could not construct it from any combination of the segment lengths.

* **MINOR — "The second module is 8,079 B of code in ten segments" (verdict).**
  8,079 B is right; the segment count is ELEVEN, not ten. The dossier's own segment table lists 11 code segments between 0xFA6018 and 0xFA83BF (0xFA6018, 0xFA609A, 0xFA61A4, 0xFA6262, 0xFA6378, 0xFA7074, 0xFA71C4, 0xFA7530, 0xFA754C, 0xFA81AE, 0xFA835E) and they sum to exactly 8,079 only when all eleven are counted. The summary elsewhere gets the span-wide figure right (12 code segments, 8,540 B). Same class as "a handler count of 35 that was 34".

* **MINOR — Segment 0xFA6378-0xFA7032: "Entered from 46 of the 48 entries of the table above plus T_F40754/T_F40758".**
  Cannot reproduce 46. I read all 48 entries of the pointer table at 0xFA62B8: ALL 48 land inside 0xFA6378-0xFA7032 (28 distinct values; 0xFA6378 itself appears 21 times). No script mode prints 46. The segment's status as code is unaffected — it decodes exactly and ends `ret` — but the number is an unreproduced "46 of 48", the same shape as this project's "243 of 244".

* **MINOR — Summary: "The tables emit as `.long` (the 5 prom_a pointer tables and 3 RAM-address tables) or `.byte` (the 3 sentinel maps, the 23 record-array groups, the index map, the 11x12 record block)".**
  Two of the four counts are wrong. `--tables` lists TEN ptrtab objects (0xFA607A, 0xFA6164, 0xFA6242, 0xFA62B8, 0xFA7034, 0xFA7180, 0xFA7520, 0xFA753C, 0xFA80FE, 0xFA8CC8), not 5, and FOUR holey/sentinel maps (0xFA7FFE, 0xFA83E8, 0xFA8468, 0xFA8FC8), not 3. The 3 ramtab, 23 recarr, 1 ident and 1 recblock are right, and 2+1+1+10+3+4+23+1+1 = 46, which is the object total the script prints — so the dossier's own 46 only balances with 10 and 4. A conversion lane using this inventory as a checklist would emit five tables short.

* **MINOR — The dossier's `segments` array vs its summary's "the 42-segment LAYOUT".**
  The array has 43 rows. The extra is 0xFA83E8-0xFA8467 / 0xFA8468-0xFA84C7, which the LAYOUT emits as ONE merged 224-byte holey segment (they are two separate framed objects in `--tables`, so the split is real at object level, but it is not a layout segment). Both readings tile the span exactly — I checked the 43-row version myself: 0 gaps, 0 overlaps, sum 17,685 — so nothing is lost, but a lane pasting the array gets 43 regions while `--python` gives 42.

* **MINOR — Segment 0xFA6018 evidence: "Includes the 18-byte routine at 0xFA6068 (`call 0xF40004` x4, `ret`)".**
  It is 17 bytes, not 18. prom_a/roundtrip.py 0xFA6018 0xFA6079 shows `call 0xf40004 ; FA6068` / `call 0xf40008 ; FA606C` / `call 0xf4000c ; FA6070` / `call 0xf40010 ; FA7074` / `ret ; FA6078` = 4x4+1 = 17, and 0xFA6078-0xFA6068+1 = 17. Also the four calls go to four DIFFERENT addresses (0xF40004/8/C/0x10), which "`call 0xF40004` x4" misreads.

* **MINOR — Segment 0xFA71C4 evidence: "the 21-byte routine at 0xFA750A (`push SR / normal / pop SR / ld XIY,0x00FA7520 / ld A,0x03 / calr 0xFA754C / ret`)".**
  The 21-byte extent is right and the calr really does resolve to 0xFA754C (`1e 2e 00` at 0xFA751B), but the quoted instruction list omits 7 of the 21 bytes: the run actually starts `ret / nop / nop` at 0xFA750A-0xFA750C and has four more `nop`s at 0xFA7510-0xFA7513. Quoting it as a routine body implies an entry point at 0xFA750A that begins with `ret`.

* **MINOR — Open question on the 506-byte 0x00 run: "506 bytes is 3.95 more blocks — but it stops 2 bytes short of a block boundary".**
  It stops SIX bytes short. 0xFA9C78 is exactly on the 0x80 phase (0xFA8FF8 + 25*0x80); the run ends at 0xFA9E72 and the next boundary is 0xFA9E78. 506 = 126 four-byte words + 2 leftover bytes, so "2" is probably "2 entries" — but as written the arithmetic is wrong. Immaterial (it is a hedge on the segment the dossier already flags as weakest), but it is a stated number that does not check out.

* **MINOR — Script hygiene in notes/prom_a_fa5aeb_layout.py — the reproducibility artefact itself.**
  Three stale statements inside the committed file. (a) Docstring rule 1 says FILL is "a maximal run of >= 16 bytes of 0x0E" while the code has FILL_MIN = 32 (the dossier gets this right, the script's own docstring does not — and this project has already burned a wave on a docstring threshold that disagreed with its code). (b) The RUN section advertises "--selftest # 108 checks" while it prints 116. (c) extend_holey_left's docstring says "the two agree on three objects here" and lists three, but FOUR holey objects are moved: raw holey_maps() over the span returns 0xFA8003, 0xFA83F4, 0xFA8478, 0xFA8FDB and the final layout starts them at 0xFA7FFE, 0xFA83E8, 0xFA8468, 0xFA8FC8 — 0xFA7FFE is the undocumented fourth.


### a3 — recon:prom_a 0xFA1404

* **SERIOUS — '★★ TWO OF THE REFERENCING CODE BLOCKS ARE INSIDE THE SPAN ITSELF — a census built only from prom_a/wsa1_prom_a.s misses them, and with them four display lists (0xFA2FAF, 0xFA2FB9, 0xFA302F) and two d**
  Wrong in both count and membership. The sentence says 'four display lists' but lists three addresses, and of those three only TWO are actually invisible to a .s-only census. 0xFA302F is named from CONVERTED .s code at three sites: prom_a/wsa1_prom_a.s:36335 (0xF9D9ED), :37576 (0xF9E5E7) and :42394 (0xFA13FF, the very lda_24 the dossier itself cites as the converted instruction ending at the span start). I re-derived the true set with the script's own literal_refs(): the only in-span-only data objects are 0xFA2FAF (<-0xFA15D1), 0xFA2FB9 (<-0xFA1405), 0xFA1B82 (<-0xFA14EF), 0xFA1B8B (<-0xFA1552) — two display lists and two descriptors, four objects total, which is probably where the stray 'four' came from. The same wrong sentence is baked into the committed script's docstring, so it will propagate. The underlying structural point (a .s-only census does miss in-span references) SURVIVES for

* **SERIOUS — open_questions #2: 'every PC-relative jr/jrl/calr at a proven boundary (32 of them, all internal to the tail code, none reaching it)'**
  The count and the scope are both wrong, and no script produces 32. The script's own --census prints 71 PC-relative branches at a proven boundary; I bucketed them as 43 in the tail block (0xFA4EB5-0xFA5369), 20 in the head block (0xFA1404-0xFA15E8) and 8 outside the span entirely (e.g. 0xFA049D->0xFA369A, 0xFA1315->0xFA1432). So 'all internal to the tail code' is false, and 32 matches none of 71/43/20/8. The dossier contradicts itself: its own segment evidence for 0xFA4EB5-0xFA5369 says '43 in-range branches'. This is the project's signature 'handler count of 35 that was 34' failure. The CONCLUSION survives — I confirmed 0 of the 71 target 0xFA4EB5, and the selftest asserts it — so the 'nothing references 0xFA4EB5' open question is still correctly open.

* **SERIOUS — Segment evidence citations: 0xFA1E49 'lda_24 XBC,(0xFA1E49) / push / call T_EditValue_StepBitField at 0xFA0130'; 0xFA1B75 '9-byte descriptor named at 0xF9F1F2's site'; 0xFA1690 'call T_PanelCode_ToSlotAndFlags / mul A,0x04 / add XWA,0**
  Three evidence citations name an address that is not the quoted instruction. unidasm shows 0xFA0130 is 'lda XBC,0xfa066d / push XBC / call 0xf42e84' — a different descriptor and a different primitive; the real and ONLY site naming 0xFA1E49 is 0xFA0441, which is what the script itself prints. 0xF9F1F2 is 'pop XIX'; the real sites naming 0xFA1B75 are 0xF9F19B and 0xF9F1D1, again what the script prints. 0xF9C0C2 is 'link XIZ,0x0000' — the call is at 0xF9C0CC and the naming instruction at 0xF9C0D5. I confirmed the script's addresses are the only ones by a ROM-wide byte scan for the operand shape. This is the project's '~20 call sites cited one byte past the instruction' failure class, worse here (off by 10 to 785 bytes), but it is NOT load-bearing: the committed script carries the correct sites and no segment boundary moves.

* **MINOR — open_questions #2: 'Its body from 0xFA4EB5 is byte-for-byte the body from 0xFA5148 inside the routine at 0xFA4FFA'**
  'byte-for-byte' asserted with no count, which is precisely the project's logged error ('byte for byte' for a match that was 170 of 204 bytes). I measured it: the common prefix is 517 bytes, first difference 0x5C vs 0x68 at 0xFA50BA / 0xFA534D. The claim is TRUE and in fact covers the whole 325-byte first routine plus 192 bytes more — but the count has to be in the text before a conversion lane can rely on it.

* **MINOR — summary: '111 call sites give 36 exact extents; 13 more runs come from the framing walk'**
  36 is reproduced by nothing. No mode of the script prints it. The script's dl_sites() returns 111 sites yielding 89 distinct (start,end) extents — 42 covering more than one record, 47 covering exactly one — and --fine tags 86 display_list objects 'call site'. None of 89/86/42/47 is 36. The load-bearing half of the sentence is fine: the 13 R2-accepted runs are real and --selftest does assert each is bounded at both ends by an object another rule proved.

* **MINOR — '0xFA1F21-0xFA4EB5 is 873 display-list records, 52 operand arrays and 34 string tables'**
  Reads as three disjoint populations, but the 34 string tables are a SUBSET of the 52 operand arrays, not additional to them: --fine emits 52 operand_table objects, 34 of which carry a 'strings' note and 18 of which do not. Adding them gives a phantom 86. Also, '873' is correct — I reproduced it exactly by running the script's frame() over the 100 display_list objects — but no committed mode prints it, so it currently reads as an unbacked number.

* **MINOR — retires: 'the header for Stub_Ret_F55018 says 70 2C F4 00 occurs 397 times in prom_a+prom_b, 222 of them in one run at prom_a 0x216B4 ... the run at 0x216B4 is the first table's slot 9'**
  Quotes an already-retracted sentence as if it were the tree's live claim. That exact wording was CORRECTED on 2026-08-25: prom_b/wsa1_prom_b.s:44745-44751 and notes/FINDINGS-prom_b-thunk-table.md:104-118 both state '222 is prom_a's TOTAL; 0x216B4 is only its first occurrence ... The occurrences are scattered, not one run', and measure the run at 0x216B4 as 6 entries. A stale duplicate of the sentence does survive at prom_b/wsa1_prom_b.s:60420-60422, which is presumably what was read — that copy should itself be fixed. Re-adopting 'the run at 0x216B4' repeats the retracted framing. The dossier's OWN substantive claim is nonetheless fully verified: I confirmed all 222 prom_a occurrences are handler-table slots, 222+175=397, and my derivation reproduces every figure of the 2026-08-25 census (67 four-aligned, 0x216B4..0x21E45, longest run 10 at 0x21DED, first-occurrence run 6). Also note the


### a4 — recon:prom_a 0xF85FF9

⚠ **Unverified.** A dossier exists but no skeptic attacked it. Treat as a hypothesis.


### b1 — recon:prom_b 0xF17559

* **FATAL — open_questions: "Six display-list runs come out AMBIG ... Three of them are resolved to B ... 0xF1814E-0xF181D5, 0xF181D6-0xF1825D and 0xF1A048-0xF1A0BE are still labelled AMBIG in the layout." and su**
  The script's own output labels SIX segments AMBIG, not three: 0xF17C00-0xF17C07, 0xF1814E-0xF181D5, 0xF181D6-0xF1825D, 0xF1A037-0xF1A047, 0xF1A048-0xF1A0BE, 0xF1A14D-0xF1A157 (grep -c AMBIG = 6). The three the dossier omits are also the ones --null-frame flags as having NO call site at all (plain E0 bounds), so they are the WEAKEST three, not the resolved three. The stated resolution mechanism does not apply to them either: the dossier says the resolved ones are "named by a push pair", but 0xF17C00, 0xF1A037 and 0xF1A14D are explicitly "no display-list call site names the run". A conversion lane told to leave 3 runs unnamed will confidently name 3 runs the script refuses to name. This is the project's signature failure (a count of 35 that was 34) applied to an instruction handed to the next lane.

* **SERIOUS — summary, correction (a): "WAVE7-BRIEFING.md says 36 of the 41 prom_b_dl_call_shapes runs are in this span" (and in the script docstring: 'notes/WAVE7-BRIEFING.md says "THIRTY-SIX of those 41 runs are **
  notes/WAVE7-BRIEFING.md contains no such sentence. It is committed at 65da9d2, git-clean, and grep -ni for 'thirty', 'shapes', 'display-list', '36' and 'runs' finds nothing of the kind; the only occurrence of that quoted sentence anywhere in the repository is inside notes/prom_b_f17559_layout.py itself. The corrected NUMBER (25 runs / 3,157 bytes of 41 / 5,247) is correct and I reproduced it independently -- but it corrects a statement no one made, and it is presented as one of the lane's three headline corrections. Same class as this project's 'no references asserted without running the census'.

* **SERIOUS — verdict and summary (3) and open_questions: "70 fixed-size parameter descriptors (484 bytes)", "emit the 70 parameter descriptors", "What the 70 fixed-size parameter descriptors MEAN".**
  There are 71, not 70. The script emits 71 segments of kind `record` totalling 484 bytes, and the dossier's OWN segment list adds up to 71 (11 at 0xF1AA7C-0xF1AB09, 59 at 0xF1ACFB-0xF1AE47, 1 at 0xF1B1A7-0xF1B1AF). The byte total 484 is right; the object count is off by one, three times, including in the instruction to the next lane.

* **SERIOUS — verdict: "231 record-runs/arrays of interpreter-A and interpreter-B display-list records (7,900 + 776 bytes)"; segment evidence "22 runs, 231 records" (0xF18A1D-0xF19237), "20 runs, 231 records" (0xF1**
  None of the three record counts reproduces. Summing the script's own per-segment 'N records': 0xF18A1D-0xF19237 = 171 records (not 231), 0xF19ABF-0xF1A18C = 175 records (not 231), 0xF17C8C-0xF18065 = 101 records (not 133). Across the whole span there are 121 runs/arrays holding 711 records; '231 record-runs/arrays' matches neither figure. Only the byte totals (7,900 + 776) are right. Two different ranges being quoted as exactly '231' is itself the tell.

* **SERIOUS — verdict: "24 pointer/dispatch tables (1,756 bytes) whose bases and entry widths come from `add Rx,imm32 / ld ?,(Rx)` in prom_a".**
  The script emits 33 pointer_table segments, each with a distinct prom_a evidence base, totalling 1,756 bytes. Counting the dossier's own segment list the same way also gives 33 (1+12+2+2+3+5+3+1+4). The byte total is right; '24' is reproduced by nothing I could run and appears in no mode's output.

* **SERIOUS — segment 0xF17C00-0xF17C58: "5 one-record lists (op 0E len 8, then 10-byte records); both ends E0 references (prom_a 0xFBE3C1/0xFBE3C9) but no call site names the runs".**
  Three errors in one Evidence line. (i) The runs are 1, 3, 3, 1, 1 records, not five one-record lists. (ii) 0xFBE3C1 and 0xFBE3C9 are not 'both ends' of anything: llvm_roundtrip shows two independent single-record sites -- 0xFBE3C1 lda XBC,0xf17c45 / push / jr 0xfbe3cf, then 0xFBE3C9 lda XBC,0xf17c4f / push / 0xFBE3CF call 0xf42e08. They name two separate records, and the intervening `jr` is exactly the shape the docstring says the byte scanner misses. (iii) 'no call site names the runs' is false for four of the five: --sites lists 0xF17C08 <- prom_a 0xFBE245, 0xF17C2A <- 0xFBE253, 0xF17C45 and 0xF17C4F <- 0xFBE3CF. Only 0xF17C00-0xF17C07 is unnamed. The script gets all of this right; the dossier's summary garbles it.

* **SERIOUS — segment 0xF19481-0xF19744: "seven 2-record lists (op 08 + op 03) each immediately followed by its own 8-byte-entry array of 16/16/8/8/16/8 entries".**
  There are six, not seven -- and the dossier's own list of array sizes has only six items. The script prints six display_list runs of 2 records each (0xF19481, 0xF19517, 0xF195AD, 0xF19603, 0xF19659, 0xF196EF) with arrays of 16, 16, 8, 8, 16, 8 entries. 6 runs, 12 records.

* **MINOR — null_calibration note: "`--null-frame` measures the DISPLAY-LIST FRAMING rule against 248,097 aligned chunks of this span's proven non-list data: 694 accepted, 0.28%".**
  The script prints 'chunks offered 249693'. 248,097 is not produced by any mode; it survives only in the script's own (now stale) docstring, which the dossier copied instead of running. Re-ran --null-frame twice and diffed: deterministic, always 249,693. The load-bearing part (694 accepted, 0.28%, corpus 170 objects / 7,194 bytes, and the 17-of-485 +7 tie-break) does reproduce.

* **MINOR — verdict: "...named by 121 call sites in prom_a".**
  --sites prints 121 sites of which 120 are in prom_a and 1 is in prom_b (0xF123DB, which the dossier itself elsewhere correctly calls 'the only prom_b call site of the span'). Internally inconsistent by one.

* **MINOR — The dossier's `segments` array kind labels.**
  Four rows disagree with the script they are said to come from: 0xF17C59-0xF17C8B is called `bitmap` (script: index_map), 0xF18066-0xF1814D and 0xF185FD-0xF1881C are called `display_list` (script: record_array), and 0xF1A62F-0xF1A7AE is called `ascii` (script: index_map -- correctly, because the table uses non-ASCII bytes 0x88/0x8C/0xB0/0xBC). All extents are right; only the labels drift. Matters because the summary tells the next lane to emit from these kinds.

* **MINOR — summary, correction (b): "the briefing's `T_F42FD0-T_DL_Pt1Pt2Pt3Pt4Pt5Pt6Pt7Pt8 (13 slots)` are STALE, not entry points".**
  The briefing's line 114 reads only `0xF17559-0xF1B400 16,039 T_F42FD0` -- no slot count, no range, and no claim that the slots are unconverted entry points. The finding itself (13 slots, all unreferenced, 11 of 13 mid-record) is fully verified; only the quoted attribution is invented. The `retires` field states this more honestly ('that the briefing lists as this span's thunk run'), so the two disagree with each other.

* **MINOR — summary, cross-lane note: "`Data_F0EEE0` is its first four 24x24 dial glyphs".**
  The existing block header in prom_b/wsa1_prom_b.s:9336 sizes Data_F0EEE0 at 287 bytes, one short of four whole 72-byte glyphs (288). I confirmed 0xF0EEE0[288] == 0xF31EE1[288] and that the 5th block differs, so the substance is right, but the existing block holds three whole glyphs plus 71 bytes of the fourth. The dossier does not state the count. Separately, the dossier missed a correction sitting in the same file: the `.incbin` header at prom_b/wsa1_prom_b.s:21798-21801 says '0xF17A6C holds a 24-entry array of pointers spaced 0x48' -- I measured 29 entries, stride 72 on all 28 gaps, and the dossier's own script agrees on 29. That wrong count is left standing.

* **MINOR — segment 0xF1B1B0-0xF1B22F: "`ldw BC,4 / mul XBC,XHL / add XBC,0x00f1b1b0 / ld XBC,(XBC) / jp (XBC)` at prom_a 0xFBF259-0xFBF26C -- a jump table".**
  The quoted instruction sequence omits `lda XIY,0xfbf26e / push XIY` between `ld XBC,(XBC)` (0xFBF264) and `jp (XBC)` (0xFBF26C) -- it is a call-via-jp with a pushed return address, not a plain jump table. Also `mul XBC,XHL` disassembles as `mul XBC,HL`. The address range and the base 0xF1B1B0 are exactly right and the table is 32 x 4 = 128 bytes as claimed.


### b2 — recon:prom_b 0xF4F000

⚠ **Unverified.** The lane died before returning a dossier.


### b3 — recon:prom_b 0xF067A6

* **SERIOUS — Verdict: "ten of its eleven objects are named by an `ld Xrr,imm32` in prom_a 0xFC0D70-0xFC25A1 whose next instructions state the element size, so the boundaries come from readers, not from a decode."**
  It is NINE of eleven, and the lane's OWN script says so. I loaded notes/prom_b_f067a6_layout.py and counted DATA_READERS: 11 data objects, 9 with an ("a", addr) reader, and exactly two with None - 0xF08134 and 0xF08334. The dossier's own segment evidence and its own open questions 3 and 4 both concede those two are unnamed, so the headline number contradicts the body. My census also confirms neither base has any 32-bit spelling in either image. This is the project's signature error class ("a handler count of 35 that was 34") landing on the single sentence that carries the layout's provenance argument. Secondary: the instruction shape is also not uniform - the reader for 0xF06EF4 is `add XBC,0x00f06ef4` at 0xFC231D, not an `ld Xrr,imm32`. Reproduce: python3 -c "import importlib.util,sys; spec=importlib.util.spec_from_file_location('L','notes/prom_b_f067a6_layout.py'); m=importlib.util.mod

* **SERIOUS — Segment 0xF09800-0xF09B32 evidence: "Contains 24 of the 36 display-list call sites, 0xF0980D onwards."**
  It is 22, not 24. Running the committed scanner directly and printing all 36 sites in address order: sites 0..21 lie at 0xF0980D-0xF09AC2, all below the segment end 0xF09B32; sites 22..35 lie at 0xF09BA0-0xF09D69, inside the SECOND code segment. 22 + 14 = 36. The lane's --dl mode prints the 36 total and the 0xF0980D-0xF09D69 extent but never prints this split, so no committed script reproduces the 24 - it is an eyeballed number, which is exactly what rule 2 of the briefing forbids. Reproduce: sys.path[:0]=['notes','scripts/analysis']; import prom_b_dl_call_shapes as DLC, prom_b_display_lists as DL; a,b=DL.load(); ins=[r for r in DLC.scan(a,b) if 0xF067A6<=r[1]<0xF0C735]; print(len(ins), sum(1 for r in ins if r[1]<0xF09B33))

* **SERIOUS — Segment 0xF09E85-0xF09FFF evidence and verdict: "0xF09EB3 onward is twelve routines of the shape `link XIZ,0x0000 / ... / unlk XIZ / ret`" and "379 bytes ... are almost certainly twelve `link/unlk/ret**
  It is THIRTEEN. `python3 scripts/analysis/llvm_roundtrip.py b 0xF09E85 0x177` puts a `link XIZ,0x0000` prologue at 0xF09EB3, F09ED7, F09EEF, F09F0F, F09F24, F09F39, F09F4E, F09F63, F09F78, F09F8D, F09FA2, F09FC0 and F09FE4 - thirteen, each closed by its own `unlk XIZ / ret`. A raw byte scan for `ee 0c` agrees (14 hits, of which 0xF09FFC is the bodyless tail the dossier correctly calls out separately). The region's true composition is: a 15-byte push/pop/ret stub at 0xF09E85-0xF09E93, ONE routine at 0xF09E94-0xF09EB2 whose `link` lies outside the region (it ends `unlk XIZ` 0xF09EB0 / `ret` 0xF09EB2), THIRTEEN link/unlk/ret routines, and the 4-byte bodyless link - which also sums correctly to the 375 + 4 the dossier quotes. Worse, the wrong count is hard-coded as prose inside the script's --data output, so the 79-check selftest can never catch it. Nothing downstream depends on it (the segm

* **SERIOUS — Segment 0xF08334-0xF08513 evidence: "480 B = 160 records x 3 (records read `ff 03 02 / ff 03 00 / 18 04 02` etc.)".**
  None of those three byte triples exists on the frame the segment claims. On the proven frame (offset 0 from 0xF08334 - proven because all 128 pointer entries are 3-byte aligned on it and entry[127]+3 = 0xF08514), the array reads `00 00 10 / 02 00 18 / 00 00 ff / 03 02 ff / 03 00 ff / 01 01 ff ...` and ends `7b 01 ff / 7d 03 ff / 7b 02 ff`. The quoted triples occur only at byte offsets 8, 11 and 20 - all congruent to 2 mod 3, i.e. read on a frame SHIFTED BY 2. The shift also inverts the array's texture: on the correct frame 128 of the 160 records end in 0xFF (`id, flag, 0xFF`), which the shifted reading `ff, id, flag` hides. The conclusion (160 x 3) survives and is pinned from both sides, but the summary tells a conversion lane to emit "160 3-byte records at 0xF08334" with this evidence line attached, and a lane checking its emission against these bytes would conclude it had mis-framed a 

* **MINOR — Verdict: "0xF09800-0xF0C734 (12,085 B) is CODE - 11,298 bytes of it byte-prove ... plus 848 bytes of nine pointer tables and 104 bytes of a three-object lookup chain."**
  Read as a decomposition of the code block it does not add up: 11,298 + 848 + 104 = 12,250, which exceeds 12,085 by 165. Two faults. (1) The 848 is the SPAN-wide pointer-table total and includes the 512-byte table at 0xF08134, which is in the DATA block, not the code block; only 336 bytes of pointer table lie in 0xF09800-0xF0C734. (2) The 104-byte "three-object lookup chain" double-counts the 32-byte pointer table at 0xF09B7B already inside the 848. The honest decomposition, which I checked tiles exactly, is 11,298 code + 336 (eight in-block pointer tables) + 72 (the 8-byte word table and 64-byte index map) + 379 unknown = 12,085. The segment boundaries themselves are all correct; only the prose summation is.

* **MINOR — Segment 0xF09800 evidence: "Entry 0xF09800 is entry [0] of the proven 48-entry selector dispatch table prom_b 0xF5B8F8 (word at 0xF5B9AC)."**
  0xF09800 is entry [45], not entry [0]. (0xF5B9AC - 0xF5B8F8) / 4 = 45, and the word at 0xF5B9AC does read 0x00F09800. The four entries of that table landing in the span are [26]=0xF099F5, [27]=0xF0985C, [29]=0xF09B9B, [45]=0xF09800. The cited address is right and the EXTPTR grade holds; only the index is wrong. (The parallel evidence line for 0xF09B9B avoids the mistake by giving no index.)

* **MINOR — Verdict: the code block is reached from "the two ~300-entry computed-call tables in prom_a at 0xFCF21B and 0xFCF80C", and its display-list clients use "36 `ld XIY,start / ld XIX,end / call 0xF417F0` s**
  Two loose descriptions that the lane's own tools contradict. (a) --tables and --retires both report 377 entries at 0xFCF21B and 305 at 0xFCF80C; describing 377 as "~300" understates by 26%, and the retires field states the real figures, so the verdict is the weaker text. (b) The 36 sites do not all call 0xF417F0: printing them shows 17 call 0xF417F0 and 19 call 0xF417F4. Neither error changes a boundary.

* **MINOR — notes/prom_b_f067a6_layout.py --dl prints: "... 27 distinct lists, in prom_b 0xF32C2A-0xF33508 and prom_a 0xFC40B4-0xFC527A".**
  The prom_a upper bound is wrong: the actual maximum is 0xFC52B4, from the list 0xFC52AA-0xFC52B4 named at sites 0xF09CEB and 0xF09D52. The 27 is computed but the two address ranges are a hard-coded string in dl_census(), so nothing re-derives them and the selftest cannot catch the drift. Cosmetic here (the lists are outside the span), but it is an un-derived number inside a script whose whole selling point is that it re-derives on every run.


### c1 — recon:prom_c bytecode VM

⚠ **Unverified.** The lane died before returning a dossier.


### g1 — recon:gap A registers

* **SERIOUS — Evidence bullet: 'the 68-byte reset staging image at ROM 0xFE12CF (copied to 0x00D8DB at 0xFB8175 and burst per channel at 0xFB817E)', and section 9b's supporting citation `code(0xFB8162, "f2 3b 13 fe**
  THE CONCLUSION IS TRUE BUT THE EVIDENCE ADDRESSES ARE WRONG. 0xFB8175 is `lda XBC,0x00d8db` -- the argument load for the per-channel burst, not a copy. The one copy the script cites, 0xFB8162 `lda XBC,0xfe133b`, is a DIFFERENT memcpy: 38 bytes (0x0026) from 0xFE133B into 0x00D91F, unrelated to the staging image. The real copy is cited NOWHERE: `llvm_roundtrip.py c 0xFB813C 0x48` shows 0xFB8146 `lda XIX,0x00d8db` / 0xFB814B `push 0x0044` (68) / 0xFB814F `lda XWA,0xfe12cf` / 0xFB8155 `call 0xf9a038`. I verified the conclusion myself -- 0xFE12CF is referenced exactly once in the whole image, at that instruction, with length 68 and destination 0x00D8DB, and the data there really is words 6=0x0040, 8..11=0x0000, 12=0xFF80, 13=0xFF00. So the finding survives; the citation must be repointed to 0xFB8146/0xFB814B/0xFB814F before commit, or a reader following 0xFB8175 finds no copy.

* **MINOR — Section 9d range table: `0x0480 0x00FF 0x00C0<-FA99F3 | 0x003F<-FA9BC2`, i.e. register 0x0480's two high bits are credited to the immediate at 0xFA99F3.**
  MISATTRIBUTED PROVENANCE. There is no `and ...,0x00C0` anywhere in 0x0480's path: I dumped the whole segment 0xFA9B90-0xFA9BC8 and the byte pair `c0 00` does not occur in it. `llvm_roundtrip.py c 0xFA9BAD 0x24` shows the high bits arrive via `or BC,DE` at 0xFA9BC6, DE being sub_FB5E39's return. The correct source of the 0x00C0 is 0xFB5F7F `ld WA,0x00c0`, which the script's own section 5 proves. The stated allowed-bits result (0x00FF) is CORRECT and independently established; only the pointer is wrong. The same applies to the 0x0440 path-B row, where 0xFA99F3 is right for path A only.

* **MINOR — Answer text: 'Four RAM arrays close on one another exactly: 0x0AA8 + 27*34 = 0x0E3E, 0x0E3E + 5*192 = 0x11FE, 0x11FE + 12*64 = 0x14FE, and 0x4CCF + 27*128 = 0x5A4F.'**
  Three of the four closures are asserted by section 6; the third, `0x11FE + 12*64 = 0x14FE`, is NOT asserted by any check() in the script. The arithmetic is correct (4606+768 = 5374 = 0x14FE) and I verified it, but the wave rule is that every quantified claim is reproduced by the committed script. One added check() closes this.

* **MINOR — Section 8b: 'the FIRST 0x0010C000 site is 0xFACFDF (Dev10C_SetChanReg_0440) and the LAST is 0xFB72B5 (inside Dev10C_WriteAllChanRegs)'.**
  'FIRST' and 'LAST' read as address order but are actually the ends of a list sorted by (register, address). 0xFB72B5 is not the highest address among the twelve -- 0xFB7C0E is. The statement is not false under its own ordering, but in a wave whose stated discipline is 'test the LAST element', an ambiguous 'LAST' is worth disambiguating to 'last of block 0x0500'.

* **MINOR — Evidence bullet: '0x0480 = AlgoFlags | (chan & 0x3F), class 12, slot 3', versus the script's GROUPS table which assigns the producing routine sub_FA9915 to slot 2.**
  Inconsistent use of 'slot'. 0x0480 is written at 0xFA9BC8, inside sub_FA9915, which GROUPS labels slot 2, while its accessor (0xFB7D1D -> 0x05C0/0x0640) is labelled slot 3. Both can be true under the dossier's own cross-reference thesis -- a slot-2 routine naming a channel in another slot -- but the prose never separates 'the slot that produced the word' from 'the slot the referenced channel lives in', which is precisely the distinction the thesis rests on.

* **MINOR — 'a residue-0 completeness check that the `add rr,imm16` opcode filter loses nothing inside the driver banks'.**
  Reproduces exactly (I re-ran it independently: residue 0), but its statistical power is low and unstated. The two banks total 5,457 bytes (0xFACE67-0xFAD141 = 730 B, 0xFB7016-0xFB828D = 4,727 B); four 2-byte patterns over that span have an expected chance residue of only ~0.33, so residue 0 is weak evidence rather than the strong completeness proof the phrasing suggests. The dossier does disclose the general limitation in open_questions, so this is a calibration nit, not a false claim. Related and also disclosed: section 10's four byte-diff figures depend on /tmp/kn5000_v142_full.bin, which is volatile scratch; the regeneration command is in the docstring and the section degrades to [skip], but the numbers are quoted in the answer.


### d1 — recon:doc contradiction audit

* **SERIOUS — HANDOFF-RESUME-HERE.md:57's '17,438 labels' is 'unreproducible: no committed script defines or emits a label count. Counting `^ident:` lines in the four sources gives 25,675' (FINDING 5).**
  REFUTED. `grep -hcE '^[A-Za-z_][A-Za-z0-9_]*:' prom_*/wsa1_prom_*.s` returns 17,438 exactly (3846 + 4808 + 6421 + 2363) — the doc's number, to the unit. The audit's 25,675 comes from `^[A-Za-z_.][A-Za-z0-9_.]*:` at wave7_doc_audit.py:253, which adds a leading dot to the character class and thereby counts prom_a's 8,237 `.LFxxxxxx:` compiler-style local labels (25675 - 17438 = 8237, all of it prom_a). A `.L` local is not an identifier label. Worse, the detector is structurally incapable of clearing the doc: wave7_doc_audit.py:249 calls finding() UNCONDITIONALLY — unlike the Evidence-count check three lines above it, which is guarded by `if q != ev` — so FINDING 5 fires whatever number HANDOFF carries, and --selftest has no case for it. A finding that always fires is the mirror image of this project's 'a criterion that cannot fail is not a pass'. The dossier asserted 'no committed script d

* **SERIOUS — HANDOFF-RESUME-HERE.md:58's '191 committed analysis scripts' is wrong; the truth is '194 tracked .py (`git ls-files '*.py'`)' (FINDING 7).**
  REFUTED. `git ls-files 'notes/*.py'` = 177 and `git ls-files 'scripts/analysis/*.py'` = 14; 177 + 14 = 191, exactly the doc's figure. The three extra files in the audit's 194 are prom_a/roundtrip.py, prom_a/insert_region.py and prom_a/kn5000_run_offsets.py — the conversion TOOLS the briefing itself lists separately, not analysis scripts. And the number is not even stale: `git ls-tree -r a4976de` gives the same 191 and `git diff --name-status a4976de HEAD -- '*.py'` is empty. wave7_doc_audit.py:231 defines `tracked` as `git ls-files '*.py'` and :261 compares against `len(tracked)`. This is the same defect the dossier's own group A diagnoses in README (a metric that does not match the words it is printed under), with the roles reversed — here the audit's metric is wrong and it blames the doc.

* **MINOR — 'CONSEQUENCE, observed live: an untracked `notes/prom_c_fcd0f7_interpreter.py` appeared under notes/ during this session — a sibling wave-7 lane is hunting an interpreter that was found and named in w**
  Over-read. I read that file: its docstring opens by declaring the paragraph stale ('⚠ THAT PARAGRAPH IS STALE, and `--stale` proves it from the tree'), cites P7Stream_Run at 0xF9A646 and gen_prom_c_p7stream_pool.py --verify, and then pivots to the genuinely open question the pool findings doc leaves in its own section 0 — the SECOND consumer of the 130 non-interpreter-clean streams, which it identifies as P7Block_Run with framer P7Block_Seek. So the sibling lane was MISDIRECTED BY the briefing (which is the dossier's real point, and findings 11-14 stand fully confirmed) but did not spend the round chasing a phantom. As written, the sentence claims a wasted lane that did not happen.

* **MINOR — Evidence line: 'prom_b really has no PA access: its only three addressed source lines naming `0x1e` are 0xF5DE6F `cp A,0x1e`, 0xF747D0 `ld (0x2880),0x1e`, 0xF7C0AF `cp (0x207a),0x1e`. Asserted in `pyt**
  The set is incomplete and the assertion cannot detect that. There is a fourth: prom_b/wsa1_prom_b.s:89878, `.byte 0x06, 0x1E ; F6A894 ei 0x1e`. And wave7_doc_audit.py:747-749 asserts only `all(a in insb for a in (0xF5DE6F, 0xF747D0, 0xF7C0AF))` — membership of three known addresses, never exclusivity — while printing the word 'only'. The CONCLUSION survives: `ei 0x1e` is an immediate interrupt level, not a memory access, and my own independent scan of all six read/write opcode groups against prom_b's 57,902 addressed lines finds zero hits. But a completeness claim that is both wrong and backed by a check that cannot test it is this project's signature failure, appearing inside the dossier that audits others for it.

* **MINOR — FINDING 22 (generated by the committed script): 'notes/README-prom_b.md:242 `DisplayListB_RunOne_Stack` (`0xf42e0c`) -> `DisplayListB_RunOne_Stack` is defined at 0xF3183D; 0xf42e0c is an INTERIOR inst**
  The generated 'true:' text is false. 0xF42E0C is not interior to anything — it is a slot in the THUNK TABLE at 0xF40000-0xF44017 holding `jp DisplayListB_RunOne_Stack`, stated at prom_b/wsa1_prom_b.s:8871, roughly 70 KB away from the body at 0xF3183D. README-prom_b.md:242 writes `push XBC / call 0xf42e0c`, which is the literal call instruction the code executes, so the doc is factually correct and this row is arguably not a defect at all. The dossier's own prose gets it right ('the thunk slot'); the committed script's boilerplate does not, and the script is what a later round will read.

* **MINOR — scripts_written: '`python3 notes/wave7_doc_audit.py` prints 39 numbered findings ... across 13 check groups'.**
  14, not 13: coverage, spans, counts, pa, stale, pool, db, scripts, labels, kernel, targets, mirror, gapA, untracked (wave7_doc_audit.py:772-779, and the run prints 14 `=== name ===` banners). Trivial in itself, but 'a handler count of 35 that was 34' is already on this tree's error list.

* **MINOR — 'notes/WSA1-EMULATION-DISASM-GAPS.md is 1,115 lines; kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md is 1,477.'**
  Both are one high. `wc -l` and Python `splitlines()` both give 1,114 and 1,476; both files end in a newline, and check_mirror uses `len(text.split('\n'))`, which counts the trailing empty element. The 362-line gap — the load-bearing part — is identical either way, and the cited line numbers elsewhere in the file are unaffected and all checked out.

* **MINOR — Group I is headed 'A KN5000-comparison claim in the wrong unit'.**
  Mislabelled. The claim it corrects (HANDOFF:104-105, 'prom_a and prom_c run the same kernel') is this machine against itself, not a KN5000 comparison; the KN5000 bullet is the one immediately above it in the same section. The substance is right and the byte diff IS stated with a count (144 of 2,180), which is what the wave rule requires.

