export const meta = {
  name: 'semantic-wave2',
  description: 'Wave 2 of the semantic push: 20 file-disjoint lanes (worktrees) + a serialized gate-checked integrator',
  phases: [
    { title: 'Lanes', detail: '20 lanes, each in its own worktree on branch s2/<lane>' },
    { title: 'Integrate', detail: 'serialized: ownership check, merge --no-commit, make gate-all, commit or abort' },
  ],
}

const REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const LANES_DIR = '/home/fsanches/compartilhado/disasm-lanes'
const WL = LANES_DIR + '/worklists-2026-09-25'

const COMMON = (lane) => `You are lane \`${lane}\` of a parallel push toward FULLY SEMANTIC disassembly of the KN5000 and SX-WSA1R ROMs (repo ${REPO}).

YOUR WORKTREE: ${LANES_DIR}/s2-${lane} (branch s2/${lane}, already created from main). Do ALL work there: prefix every shell command with \`cd ${LANES_DIR}/s2-${lane} &&\` (your shell does not start there). Never touch ${REPO} itself or any other worktree.

READ FIRST, in your worktree: notes/lanes/BRIEF-2026-09-25-semantic.md (the standard, the work types, the mechanics, the report) and notes/lanes/BRIEF-2026-09-01.md (repo discipline and tooling traps: latin-1 files, \`command grep\`, name files in git add, etc.). Your file ownership is in notes/lanes/ROSTER-2026-09-25.json (lane \`${lane}\`; maincpu globs apply to v10/, v9/ AND v7/). Your precomputed worklist (census bytes, research targets, name-only objects, symboliser refusals = misframe/data-as-code evidence, v7 romslices, data-as-code marker counts) is ${WL}/${lane}.md — start there. notes/branch-symbolization-2026-09-25/README.md explains the symboliser guards and lists leads.

HARD RULES (restated because they are the ones that bite):
- Edit ONLY files your lane owns (you may ADD new files under notes/ or scripts/). An integrator will mechanically reject your branch if you edit anything else. Do not touch symbols/*, .beads/, CHANGELOG.md, Makefile, naka_types.h (unless you are lane nakabig), ../technics-docs.
- Byte-identical is necessary, never sufficient. Before EVERY commit run the gate in your worktree: \`make gate\` (KN5000 files) or \`make gate-wsa1\` (only wsa1/ files); both must PASS. Once, show the gate fails on a deliberate one-byte perturbation of your work, then restore.
- Nothing invented. Every new header must name its evidence (reader routine by name AND address, record stride/fields derived from the reader, entry count and how it was pinned). If a purpose cannot be established, keep/write an honest admission saying what was tried.
- Preserve every existing comment unless you are correcting a claim you have PROVEN false (then say so in the commit message). Check with \`python3 scripts/analysis/assert_comments_preserved.py --base <base> <files>\` where a drop is not intended.
- Commit granularly on your branch with the trailer \`LLVM: tlcs900_backend@<short> (<full>)\` (from \`cd ~/compartilhado/llvm-project && git log -1 --format="%h (%H)"\`) and \`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>\`. Never push. Commit before you stop — uncommitted work is lost.
- After converting code, re-run \`python3 scripts/converters/symbolize_numeric_branches.py --image <v10|v9|v7|...> --only <your files, comma-separated, relative to the image's mirror dir> --apply --verify\` so new code has symbolic branches.
- Multi-version rule: apply what you establish in one of v10/v9/v7 to the others where the same code/data exists.
- Budget your effort by BYTES: biggest wins first. It is fine to not finish everything; report precisely what remains.
- Measure before/after on your files: \`python3 scripts/analysis/data_range_census.py --images <keys> --json <your scratch>/x.json\` (keys: v10 v9 v7 v142 subboot tabledata customdata hdae5000 prom_a prom_b prom_c prom_d) and aggregate research-target / UNKNOWN / KNOWN-A / KNOWN-B bytes over YOUR files (python over the JSON regions: fields image, rel, grade, size, admits, embedded_in_code). Use a private scratch dir: /tmp/claude-1000/lane-${lane}/.

Return the structured report (commits, before/after figures you measured, what you could NOT do and why, leads for the next wave).`

const LANES = [
  { id: 'ext', focus: `extensions/extension_data.s + extension_init.s in v10/v9/v7. v10's extension_data.s was re-typed as DATA (the 18-byte sound-parameter descriptor array 0xEDBA44-0xEE0154, 974 records, registered by SndParam_RegisterAllWidgets walking 972 pointers from 0xEE01A0; chord-type string tables) but v9 and v7 still carry the same regions as DATA DECODED AS CODE (~8,500 absurd markers each, 16,338 total). Port v10's typed representation to v9 and v7 (symbolic labels absorb the address deltas; verify byte-exact), then work the research targets and name-only objects in these files.` },
  { id: 'accomp', focus: `sequencer/accompaniment_engine.s (the largest code file, ~240 KB code across versions), accomp_screens/*.c, accompseq_routines.s. Work: data-as-code retirement (2,864 markers), code-as-data conversion (v7 embedded-in-code ~17.7 KB: AccScreen_UIDataBlock, DrumVoice_Handler7 romslice, AccTone_InlineBytecodeData, CstmCpTtl_Dispatch2...), 23 v7 romslices (port from the v9 twin where the bytes correspond), misframed instructions (R5 refusals: a lone .byte prefix + operand bytes decoded as instructions — re-frame using unidasm), rename structural labels (_Sub/_Helper and code under *_Data/*_DataBlock names) where you understand the code.` },
  { id: 'scoop', focus: `display/scoop_display.s, scoop_editor_data.s, graphics_text_vga.s. v7 has 46 romslices here (scoop_display 14.8 KB, scoop_editor_data 7.4 KB) and ~25 KB embedded-in-code research targets; v9/v10 carry misframes (R5 refusals) and data-as-code (1,701 markers). StringData_KeyNames / StringData_APCModeNames regions are text that is partly decoded as code. Retype data, convert code, re-frame misframes, name what you understand.` },
  { id: 'seui', focus: `audio/sound_editor_ui.s, sound_editor_routines.s, sound_editor_screens/*.c, semenu_routines.s, sndparam_routines.s, sndparam_records/*. sound_editor_ui.s has the most data-as-code in v10 (841 markers) and v7 romslices 18.7 KB; NOTE: ToneGen_ParamTable (0xE0E407 in v7, 1,389 B) is a JUMP TABLE for the sound editor UI, not tone-generator data (prover scripts/analysis/v7_tonegen_paramtable_is_a_jumptable.py) — if it lives in your files, rename it. Data_UnknownBlock (v7 0x110374, 1,041 B) is an UNKNOWN target here.` },
  { id: 'seqeng', focus: `sequencer/sequencer_engine.s, seq_event_playback.s, smf_event_processor.s, smf_tonegen_core.s, smf_playback.s. The v10 judge found sequencer_engine.s has the most phantom branches from misframed instructions (22 sites: a lone .byte 0xd1/0xc1/0xf1/0x8f/0x9f prefix followed by its operand bytes decoded as instructions) — re-frame them with unidasm as reference. seq_event_playback.s: 1,356 data-as-code markers (v9/v7). Research targets ~19.9 KB.` },
  { id: 'sequi', focus: `sequencer/sequencer_ui.s, seq_audio_mode.s, smf_config_routines.s, seq_step_routines.s, rhythm_routines.s, bmdredit_routines.s, composer_msp_defaults.s, ssf_gate_states.s. Smaller lane: research targets ~5.6 KB, name-only 22 KB, misframes, 5 v7 romslices. Also name the structural labels (_Helper/_Sub) in these files where the routine is understood.` },
  { id: 'audio', focus: `audio/* not owned by seui (audio_control_engine.s, note_voice_mapping.s, dsp_config_sysex.s, audioinit_routines.s, tonegen_fileio_handlers.s, sprintf_core.s, presentation_sound_nav.s, sound_navigation.s, tonegen_param_table.c, voice_*, sound_data*.s/.c) and msp_factory_defaults.{s,c}. Known data-as-code: sound_data_brass.s / sound_data_world_perc.s patch entries are 3-byte records {u8,u8,0xFF} decoded as \`jr lt, 0 / swi 7\` — retype as records (find the reader). note_voice_mapping.s: HdaeRom_TableEntry* region mixes data-as-code and code. MSP_FACTORY_DEFAULTS (5,376 B x3) is self-admitted — its C twin msp_factory_defaults.c names fields; resolve the admission if the C already settles it. sprintf_core.s (v7) ~1,000 markers. Name-only 236 KB (sound_data.s 35 KB x3): evidence headers.` },
  { id: 'midi', focus: `midi/*. midi_dispatch_handlers.s: known "data spelled as code" (earlier sessions), 1,906 markers, 26 v7 romslices (6.4 KB), misframes; computer_interface_pcg.s v7 embedded-in-code. Name-only 46 KB.` },
  { id: 'uiproc', focus: `ui/drawbar_panel_ui.s, ui_widget_defs.s, ui_mode_handlers.s, ui_window_procs.s (big code files ~450 KB code across versions). ColorBlit2_LargeCodeBlock in ui_window_procs.s is a code block under a coarse name with dozens of structural labels (Join15, Loop13...) — split into real routines and name them. v7 romslices, embedded-in-code research targets ~13.9 KB, misframes.` },
  { id: 'uimisc', focus: `ui/* not owned by uiproc (bitmap_out_routines, drawing_primitives, cpanel_routines, ui_control_panel, ui_playback_modes, rvari_routines, setwall_routines, psgridbox_routines, char_encoding_naka_state, charmap_dispatch_table, led_panel_write, password_slot_routines, sepaout_config.*), plus ui_widgets/widget_dispatch.s, ui_widgets/*_dispatch.s, naka_property_descriptors.s, naka_direct_play_property_tables.s. KNOWN: WidgetParam_Config_* in widget_dispatch.s are RECORDS decoded as code (nop / reti / jr lt,0 ...) — pointer tables index them — retype as records; the ui_widgets/*_dispatch.s files begin with record headers "XX 6a 00" (e.g. "XXj\\0") decoded as \`jr gt, 0x00\`. v7 has 43 romslices here (widget_dispatch.s 21 KB). Name-only 220 KB.` },
  { id: 'sys', focus: `storage/*, file_io/*, demo/*, boot/*, factory_test/*, shared/*, includes/*, style_ui/*, and the root *.s/*.c/*.ld of each maincpu tree (except msp_factory_defaults). boot/interrupt_vector_trampolines.s has 439 B UNKNOWN in v10 and v9; flash_floppy_handlers.s / fdc_routines.s misframes and v7 romslices; fdemotext_routines.s v7 embedded-in-code. Research targets ~15 KB, name-only 76 KB.` },
  { id: 'nakabig', focus: `ui_widgets/widget_descriptors.s + naka_widget_descriptors.c, naka_widget_tables_2.s + .c, naka_widget_tables_1.s + .c (and naka_types.h, which you alone may edit) in v10/v9/v7. These C sources compile BYTE-EXACT but are auto-generated with one anonymous \`uint16_t field_XXXX\` per word across whole blobs (naka_widget_descriptors.c alone ~59,000 field initialisers, 28,425 of them NAKA_NONE), including BITMAPS (Bitmap_Ntedt0d 30 KB, Bitmap_Dredt0d 20 KB, Bitmap_MIDIConnections_1..3 32 KB each, Display_FontPalette_Table 29 KB) and strings. The .s files slice the compiled .bin with labels (\`Label: .incbin "includes/generated/naka_widget_descriptors.bin", off, len\`) — those labels are what the census grades (932 KB name-only). GOAL: give every object a real type in the C (bitmaps as uint8_t arrays with width/height/stride stated and derived from the code that draws them — find the BitmapOut/Display reader; strings as char arrays; NAKA records per type using notes/FINDINGS-naka-record-format.md field meanings; filler/NAKA_NONE runs as explicit fill arrays), keep the .bin byte-identical (the Makefile compiles the .c; do not edit the Makefile), and put an evidence header on each .s slice label (what it is, who reads it, format). Biggest objects first. Also: NakaInst_OFF_Str's slice covers 37 KB although the string is 3 bytes — split the .s slice at the real object boundaries.` },
  { id: 'nakarest', focus: `ui_widgets/* not owned by nakabig or uimisc: technichord_string_data.s + naka_technichord_strings.c (67K field_ uses, 8,896 of them 0xF7F7 filler), style_bitmaps.s + naka_style_bitmaps.c, the *_screens.s files + their naka_*.c, block_007/012, control_menu_header.c, widget_names_charmap.s + .c, normal_mode_layout.s, sequencer_*.s, technichord_part_settings.s, style_ui_params.s, naka_accomp7_widgets.*, disk_warning_strings.s, naka_debug_proc_names.s, sound_config_lookup.c, tonekit_param_blocks.c. Name-only 1.03 MB. Same approach as the NAKA widget work: type every object in the C (bitmaps with dimensions from their reader, strings, fill, records), keep the .bin byte-identical, put evidence headers on the .s slice labels, split slices that cover several objects. You may NOT edit naka_types.h (lane nakabig owns it) — define any new types locally in your .c files. Biggest objects first.` },
  { id: 'tdata', focus: `table_data/* except style_records.s and tone_database_*: kn5000_table_data.s (523 KB name-only: Feature_Bitmap_* BMPs, Wallpaper_*, DemoSongPreset* SLIDE4K streams, fonts...), help_databases.s, ui_bitmaps.s, panel_memory_presets.s, preset_banks.s (PresetBank_Sec* 18 KB each), fonts.s. Mostly evidence headers: for each object state what it is, the reader (maincpu routine name+address — search v10/maincpu for the address/label), and the format; demo presets are SLIDE4K streams built from .mid+.yaml by scripts (cite them). Name-only 728 KB.` },
  { id: 'tonedb', focus: `table_data/style_records.s (Music Stylist 1000-record database; ~115 KB of parameter block whose own header calls it "MIDI-range values, undecoded") and table_data/tone_database_*.s (tone database copied to subcpu RAM 0x50000; ToneDB_EnvDescTable self-admitted 7.3 KB). Decode record fields from the readers (maincpu for style records; subcpu v142 routines for the tone DB: WaveSel_*, DSP1_ResolveStreamPtr...), write evidence headers, turn undecoded parameter bytes into named fields. Name-only 436 KB, research targets 7.5 KB.` },
  { id: 'proma', focus: `wsa1/prom_a/* (SX-WSA1R CPU1 program, TMP95C061). Research targets 56 KB (DrumKitNames 16.7 KB "self-admitted", SplashImage_DitherA 9.6 KB, ModuleTables_FCF044, Ram3800_DataImage, Data_FF17E2 — MIS-BOUNDED: 0xFF21F6-0xFF2269 are four real subroutines FF21F6/FF2204/FF2232/FF224D with dozens of callers; convert them), 3,695 numeric branches left (3,169 are calls into prom_b, which is a separately linked image — consider a symbolic cross-image scheme, e.g. an .inc of prom_b entry equates generated from prom_b's ELF, only if the byte gate and WSA1's own tooling stay green), ~1,650 numeric ROM-address immediates (ld xreg, 0xF.....) to symbolise, 2,932 data-as-code markers. Read wsa1/README.md and wsa1/HANDOFF-RESUME-HERE.md for WSA1 conventions (WSA1 keeps address comments; sub_<ADDR> names are its house style for unnamed routines). Gate: make gate-wsa1.` },
  { id: 'promb', focus: `wsa1/prom_b/* (low half of CPU1's 1 MiB image). Research targets 98 KB (fonts Font_Svc1A..1F / Svc06 ~28 KB "self-admitted" mostly for encoding questions — resolve what can be resolved, e.g. from notes/fonts-kanji/; LinkTable_F4FF61 keys; ScaleTuningOff..SoundCodeByGroup tables; ButtonTable_Ed*; RecordArray_F511DD...), 1,266 branch targets land MID-INSTRUCTION inside prom_b (misframed regions — find and re-frame them; the unidasm listing is wsa1/original_ROMs/wsa1_prom_b.ic13.unidasm), 5,753 new structural labels (rename the ones you understand), ~1,350 numeric ROM-address immediates. Read wsa1/README.md and wsa1/HANDOFF-RESUME-HERE.md first. Gate: make gate-wsa1.` },
  { id: 'promcd', focus: `wsa1/prom_c/* (CPU2 program), wsa1/prom_d/* (tone database, data only), wsa1/kernel/*, wsa1/dsp/* (shared by prom_a and prom_c — any change must keep BOTH images byte-identical). Research targets 33 KB (prom_d ToneDB_*IndexMap* "what the index SELECTS is not established", ToneDB_PercSource*, tail_data_zone.s, touch_eq_mixer.s, p7_stream_pool.s, voice_dsp_tables.s, mathlib.s constant pools), name-only 200 KB (prom_c preset_bank.s 88 KB...). The KN5000 tone database (table_data/tone_database_*.s, lane tonedb) has the SAME directory layout — cross-reference but do not edit KN5000 files. Gate: make gate-wsa1.` },
  { id: 'subcpu', focus: `v142/subcpu/* (KN5000 sub-CPU payload v1.42) and subcpu/boot/* (IC30 boot ROM; ~97% UNDUMPED 0xFF — do not claim anything about undumped bytes). Name-only 21.9 KB, research targets 247 B, 24 numeric branches left, 457 data-as-code markers, and the DSP bytecode/effect tables (see notes on DSP_Bytecode_Programs: its "Programs" name covers CODE for handler 0). Also check the \`andmi16\`/numeric ROM-range immediates (in v142 the ROM range overlaps small constants — only symbolise what is proven to be an address).` },
  { id: 'hdae', focus: `hdae5000/* (HD-AE5000 hard-disk expansion ROM) and custom_data/* (IC19; already 100% KNOWN-A — only touch if something is wrong). Name-only 50.8 KB. KNOWN WRONG NAMES (verified by the 2026-09-25 panel): HDAE5000_Divide_Signed @0x29B8C5 is the UNSIGNED divide core (uses jr ule; the signed wrapper is at 0x29B870; HDAE5000_Divide_Unsigned @0x29B8BF calls the core); HDAE5000_Display_Sub_294414 (commented "Large display management routine (3061 bytes)") is a single \`ret\` — a compiled-out debug-trace stub whose callers pass XWA = '---[ Name ]---' banner strings (~0x2f8f5e-0x2f92xx); HDAE5000_StrCopy @0x29AF0B is strcat; .L local labels used as cross-file subroutine targets (.Lccb_sign_handler, .Lppc_send_region_to_pc, .Lppc_utility, .Lpsb_finish) should become real labels; coarse region labels ("LDS 3061 bytes", "LDIV 1819 bytes", "LTCI 2171 bytes") span many functions — split and name them; HD self-test / sector I/O code ~0x2974xx-0x2999xx sits under Display_String_Render_*/RAM_Test_* names (IDE status polling at 0x13001E, error codes to 0x200222); 0x29B7DC is a va_arg 8-byte copy under HDAE5000_Multiply. Fix names (with sed scripts per CLAUDE.md), headers, and the 229 structural labels the symboliser added.` },
]

const WORK_SCHEMA = {
  type: 'object',
  properties: {
    lane: { type: 'string' },
    branch_head: { type: 'string' },
    commits: { type: 'array', items: { type: 'object', properties: { hash: { type: 'string' }, summary: { type: 'string' } }, required: ['hash', 'summary'] } },
    measured: { type: 'string', description: 'before/after figures on the lane files, with the command used' },
    gate: { type: 'string' },
    not_done: { type: 'string' },
    leads: { type: 'string' },
  },
  required: ['lane', 'branch_head', 'commits', 'measured', 'gate', 'not_done', 'leads'],
}
const MERGE_SCHEMA = {
  type: 'object',
  properties: {
    lane: { type: 'string' },
    merged: { type: 'boolean' },
    merge_commit: { type: 'string' },
    reason: { type: 'string' },
  },
  required: ['lane', 'merged', 'merge_commit', 'reason'],
}

let chain = Promise.resolve()
const merges = []
function integrate(lane, report) {
  const p = chain.then(() => agent(
`You are the INTEGRATOR for lane \`${lane}\` of a parallel disassembly push. You are the only agent allowed to write to ${REPO} (branch main). Lanes worked in worktrees on branches s2/<lane>; merges are serialized, so no one else is merging right now.

Lane report (for your commit message): ${JSON.stringify(report).slice(0, 3000)}

Do exactly this, prefixing every command with \`cd ${REPO} &&\`:
1. \`git status --porcelain\` must be empty. If not, STOP and report merged=false with the output (do not clean anything).
2. \`git log --oneline main..s2/${lane} | wc -l\` — if 0, report merged=false reason "no commits".
3. \`python3 scripts/analysis/lane_worklists.py --verify-branch ${lane} main s2/${lane}\` must print PASS. If FAIL, report merged=false with the offending paths.
4. \`git merge --no-ff --no-commit s2/${lane}\`. On conflict: \`git merge --abort\`, report merged=false with the conflicting paths.
5. \`make gate-all 2>&1 | tail -40\` (takes a few minutes; timeout 1800000 ms). It must show "PASS: every rebuilt ROM is byte-identical." for the KN5000 set AND for the wsa1 set, and "PASS: a toolchain change rebuilds every image in both trees.", and the command must exit 0. Count the image lines: 9 KN5000 IDENTICAL + 4 wsa1 ok.
6. If the gate passed: commit the merge with a message: first line "Merge lane s2/${lane}: <one-line summary of what it did>", a short body listing the lane's commits count and its measured before/after figures, then a blank line, then the line \`LLVM: tlcs900_backend@<short> (<full>)\` (get it from \`cd ~/compartilhado/llvm-project && git log -1 --format="%h (%H)"\`), then \`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>\`. Report merged=true and the merge commit hash.
   If the gate failed: \`git merge --abort\`, confirm \`git status --porcelain\` is empty, report merged=false with the failing image names and the relevant gate output.
Never push. Never use git reset/checkout/stash on ${REPO}. Never edit files.`,
    { label: `merge:${lane}`, phase: 'Integrate', schema: MERGE_SCHEMA })
  ).then(r => { merges.push(r); return r })
  chain = p.catch(() => null)
  return p
}

phase('Lanes')
const results = await pipeline(
  LANES,
  (L) => agent(COMMON(L.id) + `\n\nLANE FOCUS (${L.id}):\n${L.focus}`,
    { label: `lane:${L.id}`, phase: 'Lanes', schema: WORK_SCHEMA }),
  (report, L) => report ? integrate(L.id, report) : null,
)
await chain
return { lanes: results, merges }
