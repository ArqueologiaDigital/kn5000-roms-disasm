# Adversarial review of the Wave 2 lanes' semantic claims (2026-10-01/02)

**Question:** the byte gate proves Wave 2 changed no byte. Are the SEMANTIC claims the 20 lanes
wrote true: headers (what data IS, its reader, stride, count, field meanings), renames,
data retyped from instructions, code converted from bytes, re-framings?

**Method:** `review-wave2-claims.js` (the exact workflow): 10 read-only reviewers, each covering two
related lanes, checked at least 15 claims per lane, favouring the LARGEST objects and BOLDEST
statements, against the readers' code, ROM bytes and MAME unidasm. The symbol tables came from ELFs
frozen at f4d55098 (`~/compartilhado/disasm-lanes/review-w2-frozen/`). The reviewers' probe scripts
are under `~/compartilhado/disasm-lanes/review-w2/<pair>/`; their names are listed in `reviews.json`.

**Because the sample is biased toward bold claims, the precision below is a lower bound for the
lanes' claims in general.** It is a fair measure of how often a confident Wave 2 statement is wrong.

| lane | checked | confirmed | false | unsupported |
|---|---:|---:|---:|---:|
| nakabig | 61 | 24 (39 %) | 35 | 2 |
| nakarest | 47 | 26 (55 %) | 20 | 1 |
| sys | 30 | 17 (57 %) | 5 | 8 |
| scoop | 35 | 21 (60 %) | 12 | 2 |
| subcpu | 44 | 30 (68 %) | 11 | 3 |
| uimisc | 36 | 25 (69 %) | 7 | 4 |
| seui | 23 | 16 (70 %) | 5 | 2 |
| hdae | 31 | 22 (71 %) | 8 | 1 |
| midi | 35 | 26 (74 %) | 4 | 5 |
| uiproc | 29 | 22 (76 %) | 7 | 0 |
| seqeng | 30 | 23 (77 %) | 5 | 2 |
| promb | 27 | 21 (78 %) | 5 | 1 |
| audio | 33 | 26 (79 %) | 4 | 3 |
| tonedb | 41 | 33 (80 %) | 6 | 2 |
| ext | 36 | 29 (81 %) | 7 | 0 |
| accomp | 26 | 21 (81 %) | 2 | 3 |
| tdata | 35 | 29 (83 %) | 5 | 1 |
| proma | 26 | 22 (85 %) | 3 | 1 |
| promcd | 31 | 27 (87 %) | 2 | 2 |
| sequi | 26 | 23 (88 %) | 3 | 0 |
| **total** | **682** | **483 (71 %)** | **156** | **43** |

## Files

| file | contents |
|---|---|
| `reviews.json` | every reviewer's full return: per-lane counts and sampling, every false/unsupported claim (file, line, label, the claim, why, the fix), patterns, probe scripts |
| `findings_by_item.json` | the 178 itemised claims (136 false + 42 unsupported), flattened, with `status` -- the Wave 3b per-file worklist input |
| `review-wave2-claims.js` | the workflow script |

## What holds

Mechanics are almost always right: strides, counts, field offsets, bitmap dimensions, the
AccompSeq grammar, the class-table layout, the RX record tables, cited reader addresses (69/69 in
accomp+audio match the ELFs), the v9 == v10 transplants. The errors cluster in prose
cross-references, reachability, generalisations from a sample, names kept after a retype, and v7
ports.

## Recurring failure patterns (verbatim from each reviewer, with the recipe to find the rest)

### Reviewer of midi + sys

1. Renames do not reach abbreviated or elided names in comments. The midi renames were whole-word seds, so text like '..._CC3_TableLookup' and '_11 (0xFD00E0)' survived in headers in all 3 versions. Recipe: pull every identifier-like token from `;` comments in lane files and check it against syms_<ver>.txt and the old-name side of scripts/renaming/*.map and *.sed. Also grep `\.\.\._[A-Za-z]` and `, _[0-9]+ \(0x`.

2. 'No reader found' / 'purpose not established' searches miss two kinds of reader. (a) Pointers that live inside the blob being cut: GUI_DisplayStructData +0x0 has 19 such pointers. (b) Block copies `ld xiy, X / ldw bc, N / ldirw` that run past the next label: EmbeddedPtrTable_..._000B00. Recipe: check_unread_slices.py <ver> <file> for LE24 pointers anywhere, including SELF and neighbouring slices. Then, for each `ld xiy, L` followed by `ldw bc, N / ldirw`, check whether L + 2N crosses a label.

3. Entry counts come from the generating tool's own range, not from the rows emitted or the reader's index range. Examples: 'table of 7 pointers' over 9 .long, and '28 x u32' over a 4-entry table. Recipe: check_table_counts.py (false positives: pad-byte '+1' tables and comments placed after the label). For each hit, read the reader's index bound (`cp a, N`).

4. A v10 header copied verbatim into v9/v7 carries claims that are false there, or were already false in v10: v7 tables unlabelled with numeric readers, displaced v7 names, and the 0xF9C3+26k grid. Recipe: run check_header_addrs.py for each version (v7 deltas should be exactly the stated 0x7D1). Grep v7 for `ld x.., 0xf[c-d]....` where v10 has a symbol. Diff v7-vs-v10 name addresses (the delta census in this review found 140 v7 names at 0x3B7 instead of 0x7D1).

5. v7 ports emit numeric absolute operands even where a v7 label exists. This affects port_islands.py (sys: 53 -> 97) and midi_lane_v7_from_v10.py (midi: 28 new numeric table operands). The lanes measured only branch operands. Recipe: the numeric-operand census (regex `(ld|lda|call|jp)\s+...0x[ef].....` against syms_v7.txt), before vs after each merge.

6. Data spelled as instructions survives where the census marker regex does not look. Examples: the `swi 7` fill after a `ret`, and a timer descriptor after an unconditional `jr` that a positional alias (`<CodeLabel>_0xNN`) loads. Recipe: grep lane files for `ld x.., <CodeLabel>_0x[0-9A-F]+` (a data pointer into code) and for `swi|halt|normal|max|min|ldf|incf|decf` lines that follow `ret`/`jr`/`jrl` with no label.

7. Headers state a field's meaning by analogy with sibling tables instead of following the reader's tail call. Example: CC94's D called a 'level' when the reader uses the same on/off helper as CC64. Recipe: for each per-part table, record the final call/calr of its reader and group the tables by it. Tables that share a helper should share a header description.

8. Templated headers carry no content. The text 'object named by 1 line(s) of code outside this file; what that code does with it:' is followed only by an evidence line, in roughly 30 GUI slices. Kept names also contradict the lane's own findings: FlashWrite_*/DrumDetailEdit_Entry_* on ScreenData, MidiCC_Handler_BankModeSelect/ExpressionParam on CC6/CC38, MidiSerial_OffsetTable on a COM-select decode table. Recipe: grep 'what that code does with it:$' and '(name .* kept' and fill them from the reader.

Everything confirmed by this review: the main retypes (trampolines -> 192-entry RX table, the MIDI CC receive/transmit tables, the PanelEvt tables, the code-from-bytes conversions, the v9==v10 transplants, the v7 drift-zone mapping) hold up against the bytes and against unidasm framing from known entries.

### Reviewer of accomp + audio

1) CALLER TAKEN FROM A SYMBOLISER NAME (accomp). The AccScreen_UIDataBlock note says 'AccDraw_Secondary CALLS ...' because the callees had been auto-named AccDraw_Secondary_Helper13/14. The real callers are anonymous draw callbacks. To find the rest: for every header sentence of the form 'X calls/reads Y', run `grep -n "calr 0x<Y>\|call 0x<Y>" ud_v10.txt` and map each hit to the routine entry before it, not to the nearest label. Treat every *_Helper<N> / *_Code_* name as evidence of nothing.

2) READER CITED WITHOUT CHECKING THE READER IS REACHABLE (accomp: Demo_StyleRhythmData's sixth loader, the AccVoice_CopyFromROM search routine; audio does this properly, e.g. Chord_EvalAltNoteBuffer and the world-perc table). To find the rest: run each 'readers in ... (address from the linked ELF): Name 0xADDR' through refs.py (branch operands in unidasm plus 24-bit pattern). A reader with zero hits makes the header 'reader not reached'.

3) THE EXOTIC-OPERAND GUARD OVER-CORRECTS (accomp). Bank-3 register save/restore (d7 30 98 / d7 30 88 = ld RWA3,WA / ld WA,RWA3) was treated as a data signal and a real 34-byte routine was withdrawn. This firmware uses RWA3/0x3x scratch registers routinely (101 ERP lines in v10 accompaniment_engine.s; ldfr_berp W,0x31 next door). To find the rest: in the lane's .byte runs marked 'withdrawn' or 'No reader found', decode with unidasm. A run that ends on 0e (ret) with every internal branch landing inside the run, and that uses d7 3x 88/98 pairs, is code.

4) PORT BY TEXT TRANSPLANT IMPORTS THE DONOR'S MISFRAMES (audio). port_v10_span_to_v7.py replaced correct v7 framing with v10's misframed lines. The bytes are identical, so the gate stays green, and the lane's net marker and numeric-branch figures hide it. To find the rest: `python3 regress_hunks.py audio_v7.diff` lists 11 hunks. For each, run unidasm from the clean instruction before it. The fix goes in both v7 and the v10/v9 donor.

5) PIN DETECTION COUNTS COMMENT MENTIONS (audio). 12 of the 49 'kept at this address only for <file>' annotations cite files that name the label only in comments, 10 of them in comments this lane wrote itself. As a result, reader labels were left 0x41A off and mid-instruction. To find the rest: kept_pins_check.py, which strips ';' and C comments before matching.

6) CROSS-LANE FACTS GO STALE AT INTEGRATION. The SOUND_DATA_FLUTE_EXTRA 'phantom reference' had already been fixed by the seqeng lane before this lane merged. Later, the SndParam_ProcessEntry `.set` comment ('only a .long in widget_dispatch.s names this address') became false at HEAD after 24f3c260. To find the rest: for every header that quotes another file's text, run `git show <merge>:<file> | grep` at the merge commit and again at HEAD.

7) RE-FRAMED OR RE-TYPED, BUT THE LEGACY NAME IS KEPT OR A NEW ONE INHERITS IT. Examples: EditSwParam_TempoTable (actually LCD switch X positions), ExtData_VoiceParam_DispatchBytecode (actually code), DSPCfg_InitDispatchData (code), AccTuning_ValueTable (round down to a multiple of 5), and the new MidiStream_RecType48_SysExDispatch (inherits 'SysEx' from an unproven table name). The lanes flagged __pad_* and SOUND_DATA_* as historical but not these. To find the rest: list labels touched by the lane diff whose names contain Data/Table/Bytecode/Block/Tempo/SysEx and whose first bytes (per the ELF) are an instruction that has a caller, plus labels created in the lane that reuse a token from an older neighbouring name. Then re-derive each name from what the reader does.

8) LANE-REFRAMED CODE STILL HOLDS NUMERIC ROM ADDRESSES. lda_24 xix,(0xeec044)/(0xfea84f) in UIState_ProcessKeyEvent, (0xeda62c)/(0xfc7568) above, `call 16069349` after TimeSig_DisplayStrings, `call 16562576` in VoiceMode3_EvType0, `ld xiy, 16165950` in AccScreen_DataBlock. The lanes' 'numeric branch operand' metric does not count these. To find them: `command grep -nP '\((0x[ef][0-9a-f]{5})(:24)?\)|\b1[56]\d{6}\b' <lane files>`.

Overall, the data-typing headers in both lanes stand up well: every stride, count and table boundary I recomputed from ROM bytes matched, and all 69 cited reader addresses match the frozen ELFs. The errors are in caller attribution, reachability, names, and the v7 ports.

### Reviewer of uiproc + uimisc

1. v7/v9 header text is v10 text with v10 numbers (uimisc). The gen_* header generators produce one text and write it into all three versions. The data addresses (0xEExxxx) coincide across versions, so they look right, but code addresses and UI RAM addresses do not: v7 widget_dispatch.s has 202 v10-address 'Name (0xADDR)' citations against 1 own-image one, and v9 has 13. Find the rest: `python3 v7addr_check.py v7|v9 <file.s>` on every v7/v9 file the lane touched. Then grep v7 headers for 0x8Dxx and 0xC0xx RAM values and compare them with the v7 operands (v7 = v10 - 0x9C for the UI/panel variables, v10 - 0xC6 for work-RAM image 2).

2. Stale cross-lane references in comments. A lane renames or retires labels (uimisc retired UIState_Config*), and the other lane's freshly written headers keep naming them (uiproc: UIState_ConfigA_108/_072/_105, UIState_ConfigB_081, in v10, v9 and v7). The integration fix-ups only repaired code that failed to link. Line-number citations rot the same way: 50 of 61 file:line references in the naka_* headers no longer point at the cited instruction. Find the rest: `python3 stale_names.py <img> <files>` (comment identifiers missing from the frozen ELF) and `python3 lineref_check.py <img> <files>`.

3. A correction appended beside the old header instead of replacing it (uimisc). Instances: 'Character mapping table - preamble/header (sparse)' twice, then 'Actually 4 x u32 routine pointers'; 'Record boundaries ... not established yet' stacked over '20 bytes each'; a section header 'Each block is a sequence of 6-byte records' over 60 blocks the lane itself headed as 24-byte settings blocks. Find the rest: for each label, collect the whole comment block above it and flag blocks that hold (a) 'not established' or 'unknown' next to a stated stride or count, (b) duplicate lines, (c) 'Actually' or 'Formerly' without the old sentence removed, (d) a section header whose stride or size contradicts the per-object headers below it.

4. Universal statements generalised from a subset (both lanes). 'Opposite polarity' was true for mode 1 only. 'Same algorithm' missed that the dotted variant has no IsPointOnScreen check. 'Permutations' were rows one entry short. '0x7E/0x7F = Universal SysEx' was a guess from the values, without reading the receive state machine that forces F0 50. A constant was mistyped (0xFDEDEF for 0xFDECEF). Find the rest: grep headers for all|every|same|opposite|permutation|identity|Universal|equals 0x and re-derive each over every instance from the ROM. For quoted constants, `ud.sh` the cited reader and compare the immediate byte for byte.

5. Name-trusting reader and executor attribution (uiproc). 'Executed later by DisplayCmd_DequeueAndExecute' takes the routine's name at face value; the routine enqueues. The *_ParamBlock labels named code by the role a pointer to it plays in a record. Find the rest: for every header that names a routine as reader or executor, disassemble that routine and check that it dereferences or calls the object, not just receives or stores its address. Grep `_ParamBlock:|_Data:|_Table:` labels in code files and check whether they are entered by call or jump.

6. The lane metric is blind to some misframes (uimisc). The 'data-as-code markers 1,201 -> 18' figure uses lane_worklists' ABS regex (halt|incf|decf|ldf|normal|max|min|swi|jr cc,0), which does not see reti, pop sr, push sr or a stray `.byte` before a valid-looking instruction. Two misframes inside called routines (0xFB62B6, 0xF203DB) survive in v10 and v9 and are missing from not_done. Find the rest: widen the regex to `reti|pop\s+sr|push\s+sr|ei\s+[1-7]` plus any `.byte 0x[c-f][0-9a-f]` line followed by an instruction. For each hit, find the enclosing entry with relrefs.py and decode it with ud.sh from that entry.

What held up: in both lanes, ROM-derived tables, strides, counts and reader operands checked out wherever they were tested. That covers 351 computed-jump entries, 117 ToneKit slices, 44 registration headers, every RAM-variable reader in the work-RAM headers, the SwbtWr banks, the DSP record layout, and the value-map inverse property. The errors are in prose generalisations, text copied between versions, and leftover or cross-lane-stale wording.

### Reviewer of seqeng + scoop

SCOOP. Pattern 1, nearest-label attribution crosses routine boundaries. Two lane tools treat the nearest preceding non-structural CODE label in the same file as the enclosing routine: scoop_data_headers.routine_of (which writes 'Read by X (addr)') and scoop_reparent_structural.py. That label can sit before a `ret` and a data block. Many routines here have no label in the file: their entry is known only through a positional `.set` alias in shared/positional_labels.s (PerfMode_VoiceAddressTable_0x50, ToneParam_HandlerTable_BC_0x10, StringData_APCModeNames_0x54E). Others carry names matching the STRUCT regex (`_Helper`, `_Sub`). Readers and structural children of such routines get attributed to the routine BEFORE the data.

Measured: 45 of 90 reader-cited headers in v10 (39 of 84 in v7) name a routine that ends (ret/jp) before the called entry containing the reader. 316 v10 structural labels (308 in v7) sit past a data block and a source-called entry. 233 of the 284 v10 reparent-sed renames are among them. Also, the label of a lone shared `ret` is reused as a routine name (DefaultHandler_Ret as 'reader', ParamPopup_PartPedal placed on the exit `ret` of the preceding routine).

Recipe to find the rest (scripts in /home/fsanches/compartilhado/disasm-lanes/review-w2/scoop-seqeng/):
- src_calltargets.py V
- struct_parent_probe.py <files> > X
- the inline filter used in this review, or struct_parent_calltargets.py, over X
- reader_cite_probe.py V <files> | reader_cite_refine.py V
Then hand-check each SEPARATE line. Run with TMPDIR and SCOOP_SCRATCH pointing at that directory; the mirror build never touches the repo's build tree.

Pattern 2, index/stride heuristics read neighbouring instructions instead of dataflow. 'index from' picks the last load of the same register before the table load, even after the index was already moved (2 headers). The stride was taken from the next dispatch's `sla` when the reader used ld_rr8b (1 of 88 stride claims). Recipe: stride_probe.py, and for 'index from' check that the quoted load precedes the ex8/ld iy that feeds the access.

Pattern 3, stale contradicting comments survive a re-frame. The pre-lane 'data-as-code ... unreached CODE-territory' notes remain (8 in v10 scoop_display.s, one inside traced code). Recipe: `command grep -n -a 'unreached CODE-territory'` in the lane files, then check each address against the trace or the line map.

Pattern 4, corroboration logic. The v7/v10 mnemonic-ratio script is offered as proof of code-ness. It only measures byte similarity under one decoder.

Pattern 5, symbolic but semantically false names. 589 branch operands in v10 scoop files name code by data-table positional aliases.

SEQENG. The mechanics in the hand-written headers (index arithmetic, strides, counts, field offsets) were right in every case checked. Errors cluster in three places.
(a) WHO-lists are over- or under-generalised: a reader that never touches the table is listed (VoiceChannel_ParamLimitTable lists SelectPrevParam); the write behaviour of one reader (CC 6 handler) is attributed to three others; 2 of 12 reader routines are presented as the readers; 'X is what stores it' is written where 11 sites store.
(b) A field meaning is inferred from one compared constant without reading the writer (volume +36 'highest cluster number', actually the 0xFFF/0xFFFF FAT mask set from +54).
(c) A mechanism is mis-paraphrased (Voice_SlotTemplateData low nibble).
Recipe for (a): for each 'Read by'/'stores' claim, `command grep -rn -a '<label>\|<label>_0x'` across v*/maincpu (and the numeric address for stores), map each hit to its enclosing routine, and diff against the header. For (b): find every store to the field (`(x..+N), ` as destination) before accepting a meaning.

No framing problems were found in either lane. In v10 and v7, no typed data byte is a branch target and no branch target lands mid-instruction (data_is_branch_target.py, branch_into_midinsn.py). All 187 EmbeddedPtrTable targets are instruction starts.

Left for the owner to delete (regenerable; my `rm` was blocked by the safety check): /home/fsanches/compartilhado/disasm-lanes/review-w2/scoop-seqeng/scratch/ (205 MB of mirror builds) and /home/fsanches/compartilhado/tmp/review-w2-v10.unidasm (42 MB).

### Reviewer of sequi + seui

The bytes and the machine-checked numbers in both lanes hold up. The errors are in prose cross-references, in generalisations from a sample, and in the v7 lock-step decodes at boundaries.

1. sequi: unchecked prose cross-references. Every number its headers quote is re-derived by sequi_header_evidence.py (23/23 PASS on f4d55098), and all three false claims are sentences pointing at a sibling routine:
   - "the same rule BmDrEdit_ChordScrollUp applies"
   - "Like the routine above"
   - "Readers: X and Y, identically", where Y's copy is dead code.
   Recipe: `git diff 3958235e 30b2b770 -- '*/sequencer/*' | command grep -n '^+\s*;.*\(same rule\|[Ll]ike the\|identical\|analogous\|[Ss]ibling\|near-duplicate\|shaped like\)'`, then diff the named sibling's code. For every header listing more than one reader, run `range_refs.py <img> <block_lo> <block_hi>` on the block holding each read, to show it is reachable. sequi_find_refs.py looks for refs to the table, not refs to the reader.

2. seui: generalising from some handlers to "every handler". Recipe: decode the first 0x40 bytes of each of the 36 static and 12 bound handler-table entries (addresses in segfx_probe.py) and diff the field offsets read against each macro or prose layout. The 12 bound handlers are done here: 06 and 0A break the rule, 01 is a null handler.

3. seui: v7 lock-step runs are framed from the run's or file's first byte. When that byte continues an instruction begun in the previous file, `.byte` or romslice, the first instructions are fictitious (here a fake `ret`). Recipe:
   - for every v7 `.include` and every former romslice boundary, check the preceding emitted byte, e.g. `command grep -n -B1 '\.include' v7/maincpu/kn5000_v7_program.s | command grep -B1 '\.byte'`;
   - decode with unidasm from at least 16 bytes earlier;
   - or run v7_witness_lines.py, which flags v7 instruction lines whose v10 twin is not an instruction start. Every v7 disagreement except the sndparam start turned out to be v10 still misframed (v7 right).

4. seui: circular witness. A v7 run is accepted when its v10 twin is spelled as instructions, even when those v10 instructions are faux instructions over data. Recipe:
   - in each owned v10 file, list lines under a `; data-as-code (v10_data_as_code_census.py` comment outside SeScreenData, and check the v7 twin's spelling;
   - scan owned files for `^\s+(halt|swi|reti|pop\s+sr|push\s+sr|zcf|ldf|pop_f|normal|max|incf)\b` and git-blame each hit to lane commits. Only c03ee162 produced data-as-code; 273804ac/bb3e107d hits were legitimate push_a/pop_a/reti.

5. seui: the comment gate preserved stale census comments that now contradict the typing. 34 remain in v10 SeScreenData, at positions unrelated to their ranges. Recipe: `command grep -n 'data-as-code (v10_data_as_code_census' <file>` inside any block a lane re-typed, then compare each quoted range with the labels around it.

6. seui: 'value range up to N' is quoted from the mask, not from the table extent. Recipe: the extent check in this review (next symbol minus label vs width*N) flagged 10 of 24 string tables.

7. Naming leftovers (not false claims, but nothing supports the names):
   - Code reached only through positional aliases of unrelated labels: the record-pointer draw helper at v10 0xF10BE7 is called 26x as `SeMenu_EqEdit_DrawInit_0x15`; the envelope-curve draw routine at 0xF0F433 is `SeMenu_ShowConfirmDialog_Data_0x4A9`; a whole routine sits after `ret` in SeMenu_PartMask_Data with no label.
   - The seui symboliser parented labels to the wrong routine (SeMenu_StorePartMask_Skip* inside the routine after SeMenu_PartMask_Data). sequi fixed this class in its own files with sequi_reparent_structural_labels.py, which can be pointed at the seui files.
   - BmDrEdit_TestPartTableEntry keeps the raw 0xE4448E. That is WidgetData_DrawbarPositionTable+0x16: 20 RAM pointers 0xF9B6+26k, the same 26-byte part-record stride as SMF_HeaderConstants_0x1A, so it needs a label.

Scratch inputs: f4d55098 was exported to ~/compartilhado/tmp/review-w2-sequi-seui/ and the v7/v10 objects built there (not in the repo). seui_amap.py address maps were generated there (kept), and the 347 MB tree was deleted afterwards. The regeneration recipe is in v7_witness_lines.py's docstring. Nothing was edited or committed in any repo.

### Reviewer of nakabig + nakarest

I checked 61 nakabig claims (24 confirmed, 35 false, 2 unsupported) and 47 nakarest claims (26 confirmed, 20 false, 1 unsupported).

What holds in both lanes: the structural decoding checked out every time I tested it, including bitmap dimensions and strides, the AccompSeq grammar and counts, the class-table layout and the firmware's own field names, class attribution of records, the MstStyle tree, the IvMesage catalog, the work-RAM copies and the welcome-screen script. The false claims fall into these patterns:

1. (nakabig, 33 of the 48 headers that claim "no code reference reaches" / "no reader found" in v10; same in v7.) The no-reference claims came from a search over labels, positional labels and RegObjTabl tables. The firmware reaches these objects in four ways that search cannot see:
   - C string literals passed as far pointers with `pushw 0x00HH; pushw 0xLLLL` (written as numbers in the source).
   - Numeric `.set` aliases in kn5000_v10_program.s, e.g. `.set NakaInst_GM_0x5E, 0xe800ce`.
   - Pointers inside the neighbouring data: class name and signature fields, widget-record caption pointers.
   - Code that was still misframed when the header was written.
   One header even contradicts its own file: MdCmptCnctFunc_LocalInit_Strings vs the MIDIConnections captions. The integrator's earlier "CORRECTED" on PmemOutLGridCheck_LocalInit_Strings was one instance of this.
   - Recipe: `python3 review-w2/nakabig-nakarest/unref_claims.py v10.nm original_ROMs/kn5000_v10_program.rom <file.s>`, then confirm each push2 or ptr32 hit with unidasm. Repeat for v7 and v9. Every '*_Strings' / '*_Tail' / 'NakaT1_Str*' / 'NakaDesc_Str*' header in widget_descriptors.s and naka_widget_tables_1/2.s should be regenerated.

2. (Both lanes.) Records split at a blob boundary were reported as unexplained.
   - A 24-byte class definition whose proc word ends one .bin leaves its last 20 bytes at the head of the next. nakarest headers call these "purpose not established, nothing points into" in 5 places, even though its own C types them as classdef_SSS_N_*. nakabig's NakaData_WidgetTables1 is the same thing for a widget record.
   - Recipe: `command grep -n 'purpose not established: 20 B at' v10/maincpu/ui_widgets/*.s`, then test whether (addr - 4 - table) % 24 == 0 against the registered Class tables (0xeac9ee/0x160, 0xe80cf6/0x161, 0xed27e4/0x162, 0xe559ea/0x163, 0xea0f46/0x165, 0xe0cd94/0x166, 0xe208ec/0x167, 0xe27180/0x168). For blob-head bytes in general, check whether the last record of the previous blob points into them.

3. (nakarest.) Every registered table has count+1 entries: the extra one points to the "" that follows, or is 0 for Viewable tables. The piece cutter used count only, so about 10 terminators became "purpose not established ... no data word points into" even though the terminator word itself points into the range.
   - Recipe: `command grep -n 'purpose not established: [46] B at'`, then check addr == table + 4*count from the same header's 'Continues the table itself' line.

4. (nakarest.) Reader chains of the form "N data word(s) in LABEL ... which is read by X (`jr`/`calr`/`retd`/`cp reg,imm`)":
   - 32-bit coincidences in instruction bytes were taken as data words, and jumps were treated as reads.
   - RAM-mirror readers were matched on any 16-bit literal in range, including misframed bytes and immediate compares.
   - Recipe: `python3 review-w2/nakabig-nakarest/dataword_chains.py v10.nm`. Rows whose LABEL lives in a code file are suspect: 4 confirmed false in system_handlers.s and kn5000_v10_program.s. Also grep 'where they are read by' and reject any instruction form without a memory operand. The '... N more' tails are unchecked.

5. (nakarest.) The lane edited a dead file. block_007.s in v10, v9 and v7 is never .include'd; its bytes are emitted from nakabig's naka_widget_descriptors.bin. Its headers and the 12 naka_classdef_t in naka_block_007.c are therefore not the built source, and data_range_census.py (which uses os.walk) double-counts them.
   - Recipe: `python3 review-w2/nakabig-nakarest/include_graph.py <every lane .s>`.
   - Cross-lane: the same 24-byte class definitions are typed twice. nakabig's naka_class_t (base_class/record_size/props_size/sig/props) and nakarest's naka_classdef_t (proc/parent/allsize/selfsize/name/propdata/propname -- the firmware's own names, verified on root class "Class" 0x1600004) should be unified on the firmware names.

6. (nakabig, 1 case.) The cited reader was the nearest preceding label, not the routine: TimeSig_DisplayStrings is ASCII; the real reader is at +0x935.
   - Recipe: `review-w2/nakabig-nakarest/reader_distance.py`. Then disassemble each cited 'v10/v9 0x...' reader and require the quoted instruction within it. Headers that quote `<this>` beside a positional-label anchor are the likeliest.

7. Minor.
   - Header line citations (e.g. sequencer_ui.s:4302, seq_event_playback.s:2645) have already drifted against HEAD. Cite labels, not line numbers.
   - nakabig left naka_types.h's disproved '{type,0,0x60,1} header' text in place.

### Reviewer of ext + hdae

I checked 67 claims across the two lanes: 15 are false and 1 is unsupported (7 + 0 in ext, 8 + 1 in hdae).

1. **A 'no reader found' search looks only at addresses inside the block (ext).** It misses block copies that start lower and run long: the 558-B block is the tail of two Mem_Copy(0xF9A0, 0xEDB3FC, 0x620) calls. The '1,026 B' size came from the one copier the lane found (DataBuf_InitSlotFromPreset, 0x402). To find the rest, take every block marked 'no reader' or 'admits' and search the ROM for pushes or lda of the enclosing object's base. The source spells it `pushw 0x00ed`+`pushw 0xLLLL` or `lda x,(base:24)`; in ROM bytes it is `0b ed 00 0b LL HH` or `f2 LL HH ed 3x`. Read the length pushed just before each hit and compare base+len with the block extent. `default_image_copy_probe.py` does this for one base and is easy to generalise.

2. **Framing taken from the first stride (ext).** The default RAM image was cut into 26-byte rows because the first 23 entries of the +0x400 pointer table step by 0x1A. The real structure is {cmd,len,data} records (74 of 74 match), and the stride breaks after 0xFC0C. To find the rest, for each 'N-byte blocks/rows' header check that every pointer into the block lands on a row start and that the stride holds for the whole range, not just the first entries. `tlv_probe.py` is the template.

3. **Reader paraphrased from a partial look at the code (ext).** Two examples: the record called '3-byte' (the fetch reads 4 bytes), and 'base pointer at 0xC039' (the instruction is `lda`, so 0xC039 is the stream itself, not a pointer). To find the rest, re-disassemble each cited reader to its `ret`, count the cursor increments, and check every `lda` versus `ld` operand before trusting 'pointer at' or 'address of'.

4. **Tool-ported comment text carries version-specific addresses (ext).** `port_extension_data_from_v10.py` rewrites values but not comments, so the v7 headers cite v10 code addresses (23 symbol-backed, 11 more unlabelled). `v7_stale_addr_probe.py v7` lists them all. Run it with `v9` as a control (it should print nothing). Apply the same check to every other file a lane ported between versions.

5. **Counts and terminators stated loosely (both lanes).** Examples: 30 vs 29 tables, 'plus a NULL' for name tables whose terminator is a pointer to "", and 100 vs 99 functions. These figures came from a tool's printout or a template sentence and were not recounted. Recount each count against the registration code or the operand census (`viewable_probe.py`, `fn_tables_probe.py`).

6. **Renames by sed rewrite only the HDAE5000_-prefixed identifier (hdae).** Several things keep the old, now-contradicted meaning:
   - bare routine names that generators wrote into '; read by X at ADDR' comments (13 wrong);
   - label suffixes derived from them (3 labels);
   - file and section indexes (UiState_Reset 'Register frame handler', 0x28F90C 'Display_Init');
   - trailing comments at call sites (27 candidates, at least 12 clearly false).

   To find them, run `stale_names_probe.py` (77 comment occurrences of retired names; some are deliberate 'Was named X' notes), `stale_callsite_comments_probe.py` and `rodata_readby_probe.py`. The last one checks that each cited ADDR lies inside the routine it names. The same check applies to any lane that renamed through sed, e.g. the ext lane's v7 port and other waves' rename_*.sed files.

7. **A correction note is added on top of a table that stays false (hdae).** Example: the PPORT jump-table rows under a 'CORRECTION' paragraph that admits the numbering is off. To find more, grep `CORRECTION|PROVEN FALSE|Was named|MISNOMER` and verify the rows directly below each note.

8. **A flag's meaning taken from its setter alone (hdae).** Example: LyricLoaded, whose only setter is unreachable and which has no reader. Before naming a variable after what its setter means, check that the setter is reachable and that something reads the variable (grep the unidasm listing for the address as an operand).

Also worth knowing: the README tool behind the hdae lane's 953/100 figures now refuses to run at HEAD, because another lane edited its evidence line. Reproducibility depends on text anchors in files other lanes own.

### Reviewer of tdata + tonedb

1. Lost label while adding a header (tdata). A comment block was written over the label line, so the label disappeared: the bytes are unchanged and the byte gate is green. To find others, run p7_lost_labels.py <merge> [sedmaps] on every Wave-2 merge. It lists label and .equ definitions present in the first parent and absent after, minus committed sed renames. Also diff the symbols reference file before and after each merge for vanished names.

2. Routine names taken from comment prose instead of the symbol table (tonedb: WaveSel_Bind_PartRecords x992, ToneGen_GlobalFlags). Both strings appear in old subcpu comments but are not labels. A related case is stale 'v10 now labels X as Y' notes overtaken by later renames (tdata: AudioMix_BytecodeData). To find them, run p6_dangling_names.py <merge> table_data/ against the union of all frozen-ELF symbols. Re-run it at HEAD after every later merge, because cross-lane renames keep invalidating quoted names.

3. 'No reader found' asserted while the lane's own probe had found readers. The probe's 'neither' column (readers it could not attribute to a chain root) was silently treated as 'unread' for some offsets (partial block +0x04/+0x06, PercInst +0x00) and as 'read' for others (EGA/EGB/EGC). To find the rest, run notes/tonedb-2026-09-25/partial_block_reads.py --chains. For every offset that a header lists as having no reader, look it up in the neither column and walk that routine's callers (command grep 'call|calr|jr.* <name>') to Voice_Build_Partial_Descriptor / Voice_Pitch_Compute (melodic) or Voice_Init_Type1/2 / Voice_Allocate_Type2 (drum). Census the bytes too: non-zero, musically shaped values (±12, +7, a pan spread around 0x40) mean a reader exists.

4. Rules stated more broadly than the code's branch condition. The rank-binding rule is generalised to 'ROM bank selectors' when the code tests selector < 0x10. The clamp 'cp wa,0x3e8 / jr ule' is read as '< 1000' when it means <= 1000, and the claim ignores a sibling reader with no clamp. To find them, grep the lane headers for '<', 'clamp', 'only', 'every', 'always', 'For a ...'. Re-read the cited compare and branch, minding ULE/UGE/LE semantics and any early-exit test, and look for a second reader that skips the check.

5. Hardware arithmetic without the bus geometry, and boundary attributions off by one entry (tdata AMD unlock: chip word address computed as /2 instead of /4, and 0x815554 assigned to entry 25 when it is in entry 24). To find them, recompute every 'chip address' / 'falls inside entry N' claim with the MAME ROM_LOAD geometry and the ELF symbol boundaries.

6. Templated descriptions of sibling objects: one text reused for objects the same header says differ (MIDI diagrams 1/2/3). To find them, render each sibling PNG, check that the per-entry text names the differing feature, and compare with the stated pixel-diff bounding box.

7. Renames applied to labels but not to prose (ToneEnv_* in the aux structure map and field descriptions). To find them, for every sed rename map in scripts/renaming/rename_*_2026-09-25-era, grep the old stem in comment text of the same files.

8. Hex identifiers written without 0x (panel tags '44', '48', 'parts 10..14'). To find them, grep 'tag [0-9][0-9]' and 'parts [0-9]' in style_records.s and its generator.

Everything else sampled held up exactly, often down to the byte: bitmap identities, accessor code, demo titles, PercInst played-by lists, selector headers, partial ranks, velocity-split format, drum resolution formula, wallpaper/palette readers and the boot jump table.

### Reviewer of promcd + subcpu

1) RENAME/RETYPE WITHOUT A SWEEP OF THE SAME HEADER OR BANNER (6 of the 13 false claims). The lanes put the new name or value next to text that the change makes false: the 13 promcd ★ NAMED headers that still say 'the name is an address'; FPConst_Ln2 still placed at 0xF42C after the rename to Sqrt2; WDMOD=0x110 still glossed 'not watchdog'; FPConst_Int32_* still 'returned by double->long' beside 'read by FP_pow'; FP_cos's wrong caller count endorsed by a 'RENAMED: the name now says what the header above established' note. How to find the rest: for every rename map and sed file a lane wrote (notes/subcpu-fp-libm-renames.map, scripts/renaming/rename_v142_*.sed|.py, rename_promcd_*.sed, the .equ corrections in fix_subcpu_boot_sfr_names.py), print the header block above each new label and grep it for 'Unknown:', 'name is an address', 'no caller', 'called once', 'not established', the old name and any address. Also grep each banner covering a renamed object for the old name and old address.
2) 'NO READER' FROM AN ABSOLUTE-ADDRESS SEARCH ONLY. Base+displacement reads are missed (FPConst_InvFact15/17 are read as InvFact3+0x30/+0x38), and so are table reads under a neighbour's label. How to find the rest: for each object marked 'no reader', 'unreferenced' or 'library constant' (subcpu_data_tables.s has 11 more FPConst_* plus the IRAM_Unreferenced_* and EFF_* ones; prom_c has unexplained_*), search for `lda/ld xR,(L:24)` or `add xR,L` where L is an earlier label, then `(xR+d)` within about 6 lines, and test whether L+d falls inside the object. fpconst_readers.py together with a displacement pass does this mechanically.
3) SYMBOLISER 'NEAREST LABEL ABOVE + OFFSET' CROSSES OBJECT BOUNDARIES. When the next object has no label, the operand gets named as a past-the-end offset of the previous one (Voice_Search_Order_List_3+11 is really Voice_SearchOrder_Records), and the real reader stays hidden, so the target's 'NOT ESTABLISHED: what indexes it' survives. How to find the rest: for each Label+N in the symbolize_rom_operands report (35 non-mathlib sites, listed by this review), compare N with the labelled object's documented byte size or with the next comment-banner boundary. Also re-run the check on prom_a/prom_b before applying the tool there, as the lane proposes.
4) COUNTS QUOTED AND NEVER RE-MEASURED: 139/137 TG writes (actually 181+1/179), 'All 20 *_Pad' (22), 'twelve nops' (13), 'six odd-factorial reciprocals' (8), 'All 13 have one now' (14 listed). How to find the rest: extract every '<number> <noun>' in lane-added comment lines (git diff merge^1 merge, lines starting with '+;') and recount each one with a script against the ELF and ROM.
5) A HARDWARE MODEL GENERALISED FROM ONE PORT TO A PAIR: the TG 'window' banner applies the latch's P6.7 state to the data port, and the data port contradicts it at 179/179 sites. Also an index range taken from the table extent rather than from the reader's mask ('8 banks' against `and A,0x0f`). How to find the rest: for every banner that states a bus or port condition, tally the condition at every operand of each named address.
6) A NAME TAKEN FROM A GUESSED ROLE rather than from the routine's callees (DSP_Op_0x61_LinearEval, whose arm is a table fetch, while its sibling arms are named for what they fetch). How to find the rest: for every arm of OFFSETS_14745 and the other computed-goto tables the lane named, check that the name's verb or noun matches the first callee of the arm.
Things that held up and need no re-check: every byte-level framing repair and every code-from-bytes conversion I re-decoded with unidasm; every reader address cited for the large data objects (preset bank, prom_d maps and records, DSP zone tail, effect metadata twin); and the mathlib and libm identifications.

### Reviewer of proma + promb

I found no fabrication. Both lanes' reader-derived counts, strides and decodes reproduce from the ROM almost everywhere. The defects cluster in four places.

1. Old or new text left contradicting the lane's own finding. The comment-preservation gate keeps old header lines verbatim. The lanes then append ANSWERED/CORRECTED paragraphs instead of fixing the first line or the 'Read by' line. Instances:
   - the OldBuild_ValueGlyph_Bitmaps title still says '287 bytes ... could not split'
   - the EffectNames 'Read by: NOTHING ... still holds' sentence
   - DispatchTable_F0F558's 'dispatch-table entry DispatchTable_F0EE6C[23]'
   - Dispatch_By_60F080's 'The 24 real handlers'
   - BStoreCursor's '9 + 30 + 25 + 4', counted before the same commit's symboliser pass
   Recipe: for every header with ANSWERED/CORRECTED/REPLACES, re-test the title line's size against the ELF extent (extent_probe.py) and its Read-by against readby_probe.py. Also grep comment text for labels absent from the frozen ELFs (dangling_names.py; the hits outside history phrases are the live ones).

2. Cross-lane seam staleness. Each lane wrote about the other image from its pre-merge picture.
   - promb's Japanese header uses the old PtrTable_F99121 view, which says interpreter B; proma's split shows those pairs are run by interpreter A.
   - 65 promb comments name the retired PtrTable_FAD28A.
   - prom_a's generated `.set` block still carries 85 promb-retired names (Rec_F3F4xx, DL_F2E91A, Data_F3C53F ...). prom_a code therefore says DL_F2E91A where prom_b says DL_JpChordTrackAlreadyExists. equate_drift.py lists them; `symbolize_prom_a_addresses.py --check-equates` should be rerun after any multi-lane merge.
   - prom_b still spells prom_a tables as decimal or hex immediates (`add XBC,16577411`, `add XWA,0x00f4fa9c`, `add XBC,0x00f5115b`).
   Recipe: after integrating, run equate_drift.py and dangling_names.py over BOTH images for each merge.

3. Readers cited without a reachability check. proma cited prom_b 0xF09E76 and a 'routine' 0xF09AB0 that is mid-instruction. The site lives in 0xF09E52-0xF09E84, which is unreferenced and byte-identical to live 0xF09DF2-0xF09E1F except two relocated call targets. That makes it a FOURTH older-build remnant in prom_b that relocated_copy_scan.py did not report: its internal call moves with the copy (+0x65) while the external one moves by -0x31. The pre-existing label sub_F09E02_Loop sits inside this twin, at 0xF09E59.
   Recipe: for every cited reader, check that every call target in its routine is an instruction start; readby_probe.py's NOTSTART output catches cited addresses that are not. Rerun relocated_copy_scan with per-target deltas, not one constant delta, to find more twins like this one.

4. Label naming of empty or partial objects:
   - Dispatch_By_60F080 counts 9 lone-`ret` stubs as handlers.
   - The symboliser spelled an unexplained table word as `uDMA3_GetDest+0x1`. ptr_into_code2.py finds no other such case outside the deliberate old-build `live - delta` spellings.
   - AddrTable_F8E77C has only 5/17 entries on instruction boundaries and sits next to uDMA routines. It fits the stale-pointer pattern and is a lead for the older-build theory.

Corroboration found along the way: promb's Default_Record99 is the factory default of RAM 0x7F12. Its payload puts CC 1/2/4/16/17/18/19, 0x40 (hold) and 0x88 at exactly the slots proma's PanelGroupToRam7F12Slot uses. That independently confirms proma's 'assignment byte = MIDI CC number' claim, and it is the place to start on the open 0x88/0x89/0x90 assignments.
