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

**Wave 9** (`proposals_wave9_{a9,b9,c9,d9}.json`): 126 named, 16 refused. Routines whose only named callers were
OldCopy_* (an older build's code, whose calls into prom_a say nothing about this build) were left out of the batches.
Derivative passes then named 15 thunk slots, 2 wrappers (`sub_FE00EB` / `sub_FE00F8`, which batch c9 had refused
because their targets were still unnamed), 15 display lists, 1 exact copy (`TrackAssign_IsLocalControlDashed_Copy`)
and 904 local labels after their enclosing routine (rename_orphan_locals.py). Leads reported for later:
- `MidiFileSave_Page4_*` / `MidiFileSave_Page5_*` are the button tables of the floppy-format screens 0x50 / 0x51
  (rows 4-5 of `Dispatch_FF3D39`), not of MIDI FILE SAVE; `sub_FE09BE` is now `DiskFormat_Execute`.
- icon cell 49's header says no record uses it, but `Sequencer_DrawTitleIcon_DL` (was DisplayList_FE829B) does,
  through an operand spelled `.ascii "14"`.
- `TrackAssign_IsLocalControlDashed` always returns 0xAA, so its "-- " cell is never drawn.
- (0x215E) receives a 16-bit track mask at 0xF66054 and 0xF6AEDC.
- `ScreenButton_SoundEditFilterLfo_AfterOp` is a return point inside another routine (its siblings are `.L` labels).

**Wave 10** (`proposals_wave10_{a10,b10}.json`): the 46 routines whose callers wave 9 had just named; 45 named,
1 refused. Batch a10 corrected wave 9: 88 00 17 has request[0] bit 3 set, which selects CPU 2's WRITE table
(ToneEdit_Dispatch), and its opcode 0x17 calls SoundRam_ClearFourBanks. So `Msg0716_PostOp17AndRestageAllParts`
became `Msg0716_PostClearSoundRamAndRestageAllParts` (with its `_SaveRegs` wrapper and thunk slot); the wave-9
header stays, with a CORRECTION line under it. Derivative passes: 4 thunk slots, 5 display lists, 80 locals.
Leads: the 64 slots at 0x305A are held notes, with notes held 127 beats split in two; the pitch-bend repair after
an event-ring overflow writes the track number over the centre value 0x40 and reads its target track from a stale
byte (a likely firmware bug, recorded, not changed); the MIXER page-frame painter at 0xFBE135 (after `ret; ret`)
needs its own label; `SmfOut_WriteFirstWindow` at 0xF77F9A sits on an unreachable copy.

**Wave 11** (`proposals_wave11_{a11,t11}.json`): a11 named the last 18 routines with a named caller. t11 was
TABLE-DRIVEN: it decoded the selectors of the address-named dispatch tables and named 26 tables plus their
entries from the index meaning (98 named, 29 refused). The CYCLE RECORD / CYCLE PLAY screens' four
StateDispatchTable_* are the right-column up/down keys by field cursor (0x36CE) / (0x3627): CYCLE on/off, START
MEASURE, END MEASURE, SOLO; the SX-WSA1R TEST page's ITEM cursor is (0x26A7) bits 0-2 (bit 3 TEST, bit 4
MONO/POLY); the DRAWBAR SETTING rows are PERCUSSIVE TONE DECAY / LEVEL, ATTACK and RELEASE TIME. Entry records cite
their body line and name their table index; the selector evidence is in the table's own record. Derivative
passes: 6 display lists, 65 locals (sub_F45478_* and sub_F77F2A_* were left out: a11 found they belong to other
code). Leads: the pitch-bend reset after a ring overflow writes {0xD2, tick, 0, track} to the track held in
(0x34AE), not {.., 0x40} (a firmware bug, unchanged); 0x216E is the COMPARE LED flag; the historical generator
gen_prom_b_f5553f_module.py spells Select36CE_%06X with a format string, so regenerating it would bring the old
names back.
