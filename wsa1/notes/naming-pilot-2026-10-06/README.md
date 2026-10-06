# WSA1 naming pilot, 2026-10-06 -- routine names from callers, with evidence

**What question this answers.** Each `sub_FXXXXX` routine here was renamed. What was the name based on?

Read-only triage passes picked the unnamed routines that the most NAMED routines call. `OldCopy_*` callers were left
out, because that module is an older build's. For each routine the pass read the callers and then the body. It gave a
name only when the callers' context and the body agreed. A body alone was not enough.

`proposals_<image>.json` holds one object per routine: `old`, `new`, a `header` (what it does), a `basis`, and
`evidence`, the `file:line` instructions that decide the name, including at least one caller site. The reviewer
re-read a sample of bodies against those claims. Each new label carries its header and points back to this file.

**Applied with** the session's rename helper (`wsa1_rename.py`, in research-scratch). It declares every rename to
`notes/prom_a_preservation_check.py` and `notes/prom_b_names_session_53b889a2.py`. After it:
- `notes/prom_b_thunks_round6.py --pending-args` named the routine-directory slots after their targets, with
  `--mark` and `--fix-ranges`;
- `make gate-all` and both preservation checks were re-run.

**Wave 2** (`proposals_wave2_{c,d,e,f}.json`) used the same process on the next 120 routines that at least two
named routines call (`OldCopy_*` callers excluded): 102 named, 18 refused. Refusals are kept with their reasons, e.g.
routines acting on song-data marker bytes whose meaning is not established, or veneers whose only callers are
unnamed.

**Wave 3** (`proposals_wave3_{g,h,i,j}.json`) took the next 120. Many of these have only one named caller. A single
caller was accepted only when its name or header made the role clear and the body confirmed it. Result: 108 named,
12 refused.

**Wave 4** (`proposals_wave4_{k,l,m,n}.json`): 111 named and 9 refused, plus one reviewer-authored record,
`sub_F4D861` -> `BStore_AllocBlock_B`. Batch m had named its veneer assuming that name.

**Wave 5** (`proposals_wave5_{o,p,q,r}.json`, plus `proposals_wave5_review.json`): the next 120 routines that a named
routine (not `OldCopy_*`) calls, leaving out every routine an earlier wave refused. Almost all of them have one named
caller. Result: 105 named, 15 refused, and one reviewer-authored record. Reviewer changes, each noted in the record's
`review` field:
- batch q's two CYCLE PLAY blink callbacks follow batch p's CYCLE RECORD twins (`..._Readout`);
- batch q's veneer `BStore_ClearTrack_Call` became `SongEdit_ClearTrack_Call`, because batch p gives
  `BStore_ClearTrack` to the block store's own routine (sub_F4D346). The veneer's target sub_F6079E (TRACK CLEAR,
  MEASURE DELETE / COPY, TRACK MERGE) is named `SongEdit_ClearTrack` in the reviewer record.
Three existing headers got correction notes (CycleRecord_RestartPass, StepRecord_BuildCurrentMeasureRow,
BStore_AppendBytes); the original text stays.

**Wave 6** (`proposals_wave6_{s,t,u,v}.json`): the next 120 routines with a named (non-OldCopy, non-positional)
caller, leaving out every earlier refusal: 115 named, 5 refused. Most are the step-record, block-store,
cycle-record, TRACK MERGE and SMF import/export routines whose callers wave 5 named. Batch v reports one wrong old
label, to fix separately: `OldCopy_BStore_Workspace_SaveToBank` (0xF6F476) is called by this build's MIDI FILE load
and save, so it is not older-build code. `notes/wsa1_exact_copy_names.py` treats all of 0xF6F000-0xF6FFFF as the
older build, but the banner limits that to 0xF6F000-0xF6F3FF.

**Wave 7** (`proposals_wave7_{w,x,y,z}.json`): the next 120, 116 named and 4 refused. Two of the refusals are the
reviewer's: batch z had named the empty button-table slots sub_F7E750 / sub_F7E758, whose source header deliberately
says "NO NAME". Batch x reports two leads for later. `Data_F6D002` is code: the tail of sub_F6CFCB, the HOLD-latch
append (decoded 2026-10-06; the label is now `StepRecord_AppendLatchedHoldEvent_Cont`). The local labels `sub_F64A34_Join*` and `sub_F6B2EE_Entry*` sit after their routine's `ret` and belong to
other, unlabelled routines.

**Wave 8** (`proposals_wave8_{a8,b8,c8,d8}.json`): 113 named, 7 refused. Leads reported for later:
- `Str_SongNameBlank` (was sub_F81948) is the six bytes "______" (the blank song name), still decoded as six
  `pop XSP`. They should be respelled as text.
- `sub_F82CE8` (now `Variant_SendPortBToCpu2`) is the missing writer of CPU 2's 0xFFF8. This answers the open
  question in FINDINGS-prom_c-scheduler.md:82.
- `sub_F49861`'s tail labels `_Join`/`_Join2` are the entry points of SeqRecord_DrainEventRing*.
