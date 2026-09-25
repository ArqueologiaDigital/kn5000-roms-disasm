# Wave 3 plan (drafted 2026-09-25 while Wave 2's last four lanes finish)

Inputs: disasm-lanes/pending/WAVE3-LEADS.md (every lead the Wave 2 lanes reported),
disasm-lanes/pending/lane-reports/*.json, the census after integration.

Interim census with 16/20 Wave 2 lanes integrated (integ/w2 @ 6c16aad8): strict
64.15% -> 93.92%; KNOWN-B 4.43 MB -> 0.69 MB; research targets 391 KB (312 KB honest
admissions, 60 KB UNKNOWN, 19 KB embedded-in-code).

## Ordering constraint

The toolchain lane rebuilds the SHARED llvm-mc every other lane assembles with, and
promoting a pin changes the `LLVM:` trailer. So:

* **3a (solo): toolchain.** No other lane runs. Ends with a promoted pin
  (TOOLCHAIN_VERSION, snapshot, trailer) and gate-all 13/13 under the new binary.
* **3b (parallel): everything else**, on the new toolchain, so lanes can turn the
  `.byte` instructions the new spellings unlock into instructions.

## 3a -- toolchain lane (llvm-project tlcs900_backend, new commits only)

Semantic bugs (byte-exact, text WRONG) -- highest priority:
1. `di` alias -> `(EI 7), 0` (patch ready: pending/di-alias.patch; 7 MC tests).
2. F5-prefix (r32+) sub-opcodes 0x31/0x41 mnemonics SWAPPED (`f5 e0 31` is
   lda XBC,(XWA+), printed `stb_dpi a,224`; `f5 e8 41` is ld (XDE+),A, printed
   `lda_dpi xbc,232`) -- ~228 source lines in v10 alone.
3. Printer misnames registers (`cpda8 xbc,(8990)` = cp A,(0x231E); `addda16 xwa`
   = add WA; `andda16 xhl` = and HL; `div xwa,xbc` = div XWA,BC; `andda8 xbc` for
   `c1 7f c0 c1` = and A,(0xc07f)).
Silent traps:
4. `ld (+xde),a` assembles an ABSOLUTE address expression; `ld (xde+),a` is a
   parse error -> add real post-increment / pre-decrement operand syntax.
5. `lda xwa,(xsp+256)` silently truncates to (xsp+0) -> use the 16-bit form or error.
Missing spellings / decodes (each retires `.byte` instructions tree-wide):
6. SRI ALU decode (`e3 07 e8 e4 80`, `c3 07 f0 e4 3f 00`); SRI store-immediate
   `f3 .. 00 imm`; `mul RR,(mem)` (`d1/c1 xx xx 40+r`); shift/rotate-by-A
   (`cb fe`, `d9 fd`, C8+r FE/FD/FC); register-indexed `ld r,(XRR+RR)`
   (`c3 07 e0 e4 21`); (r32+r16)+imm forms; 0x85-prefixed ldi/ldir; `rlc N,W`;
   `sla N,QBC`; `d3 07 f0 f8 f1/f5`; `c7 3d 2b/2c`; `cp (XIX+HL),imm` decode.
7. hi16/lo16 relocation operators so `pushw (Sym >> 16)` works (extension_init.s
   RegMode/RegTitle).
Then: lit green, gate-all 13/13, pin promotion per TOOLCHAIN_VERSION procedure,
and a tree-wide pass re-spelling every `.byte` island the new forms can express
(two-decoder agreement required, as in scripts/converters/lane_uiproc_respell.py).

## 3b -- parallel lanes (file-disjoint roster regenerated from current main)

A. **v7 drift consolidation** (one owner, cross-file by design): the +0x41A zone
   (sndparam_routines.s <-> midi_serial_routines.s, midipkt_routines.s <->
   dsp_config_sysex.s boundaries; screen_group_dispatch.s; 22 `.set` aliases in
   kn5000_v7_program.s; 49 names pinned at drifted addresses by callers).
   Tools: scripts/converters/port_v10_span_to_v7.py (SPANS), scripts/tools/
   midi_lane_v7_from_v10.py, scripts/analysis/v7_label_drift.py (target ~0).
B. **NAKA per-class structs**: generate one C struct per widget class from the 292
   ClassProc descriptors (sig letters -> field sizes, propname -> field names) and
   type all 3,367 widget records in every naka_*.c (v10/v9/v7); retire the
   naka_dispatch_t misreading; C-side externs resolved from the main link instead
   of hard-coded addresses in *_link.ld where possible.
C. **Tree-wide tool runs** (each with its own guards, per image): 
   symbolize_rom_operands.py (prom_a ~1,650, prom_b ~1,350, v7 664, v10/v9 162,
   hdae5000 127, v142 with care); lane_uiproc_event_handles.py (object handles
   mis-symbolised as ROM addresses); lane_uiproc_respell.py; the consolidated
   re-framer (sequi_reframe.py / lane_reframe_islands.py / scoop_reframe.py ->
   one tool) over every file; symbolize_numeric_branches.py again.
D. **Cross-file renames and cleanup**: positional_labels.s aliases retired by
   lanes; orphaned v7 romslices (lists in the lane reports) deleted after a
   reference check; the renames listed in WAVE3-LEADS (DrawLineWithMode...,
   Malloc/Free v7 swap, ToneGen_ParamTable, HDAE5000 names...).
E. **Research pass 2** per region family, starting with the WORK-RAM MIRROR
   (Boot_InitWorkRAM ROM 0xEED8C8.. -> RAM 0x3D524, ROM 0xEEFA66.. -> RAM 0xE35E):
   re-run every "no reader found" search through it; the tone-DB index-map
   inversion result (promcd) applied to the KN5000 headers.
F. **Census instrument** (with controls, never loosened silently): `NAME = expr`
   lines; comment runs across blank lines; block banners over compact one-line
   label+incbin runs; single-line headers; m_ldc_* macros as code.
G. **Structural label naming**: `_Sub`/`_Helper` (routine entries) first.
H. **Docs/status**: technics-docs pages for each lane's findings; CLAUDE.md status
   table; docs/IS-IT-DONE.md + COMPLETENESS-STATUS refresh; symbols/ regenerated
   (scripts/analysis/l2_symbol_reference.py --regen); blog post; the "Preset Data
   Destination" dispute (0xF7 = bitmap transparent index) confirmed in MAME.

## Integration lessons from Wave 2 (apply in 3b)

* File-disjoint rosters do not prevent SEMANTIC conflicts: renames and label moves
  in one lane break references in another (4 of 16 merges needed fix-ups: add/add
  script names, a dropped label, renamed labels, v7 drift moving labels under
  `.long L + N` and `jp L`). Fix-up method that worked: resolve every reference to
  the label main puts at the address the lane's byte-identical build resolved it
  to (scripts/tools/reanchor_pointer_refs.py for `.long`).
* Give lanes unique script names (prefix with the lane id).
* Put lane scratch and TMPDIR on the share, not /tmp.
* Merge agents queue behind lane agents in one workflow (6-slot cap): run the
  integrator as its own workflow, or merge as lanes finish from the main loop.
