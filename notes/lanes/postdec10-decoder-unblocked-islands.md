# Lane POSTDEC10 — exploiting the new TLCS900 SriRR/ERP decoder, 2026-09-02

## What opened

`llvm-project` commit `662b3929a72a` ("[TLCS900] Decode ERP (C7/E7) and SRI
Register+Register forms", 2026-09-02 01:52) implemented `decodeSriRRPrefix()`
(the register-indexed `st_rr*`/`ld_rr*`/`lda_rr`/`jp_rr`/`call_rr` family) and
`decodeERPPrefix()` (previously a literal `Fail` stub) in
`TLCS900Disassembler.cpp`. Both families were already correctly ENCODED by
the assembler and already spelled by hand throughout this tree (thousands of
uses) — only `llvm-mc --disassemble` could not turn raw bytes back into
those mnemonics. `975a2c17d683` (test-only, no code change) added six more
literal ROM byte sequences to the regression suite, two of them read
straight from `original_ROMs/kn5000_v10_program.rom` (offsets `0xf477f`,
`0x106da6`, `0x1d0310`) and one from `wsa1/original_ROMs/wsa1_prom_a.ic12`
(`0xF831FF`), each matching what this tree already spells by hand at that
address.

## Step 1 — confirm the decoder actually works, on real ROM bytes

Independently re-derived (not copied from the commit message) by pulling
the exact bytes at each cited address from this lane's own ROM copies and
checking the source annotation at the cited `.s:line` matches:

    kn5000_v10_program.rom @ 0xf477f:   f3 07 f0 e0 d8   -> jp_rr 8, xix, wa
    kn5000_v10_program.rom @ 0x106da6:  f3 07 e0 e4 30   -> lda_rr xwa, xwa, bc
    kn5000_v10_program.rom @ 0x1d0310:  d3 03 f0 e0 21   -> ld_rr8w bc, xix, a
    wsa1_prom_a.ic12 @ 0xF831FF (file offset 0x31FF,
      base 0xF80000 per prom_a.ld):    c7 e3 99         -> ldb_erp a, 227

All four: `llvm-mc --triple=tlcs900 -disassemble -show-encoding` decodes
cleanly, and re-assembling the printed mnemonic (`echo "jp_rr 8, xix, wa" |
llvm-mc --triple=tlcs900 -show-encoding`, etc.) reproduces the exact
consumed bytes. The decoder works, on real hardware bytes, independently
verified.

## Step 2 — re-run v10's censuses: unchanged, and that is expected

`scripts/analysis/v9_v10_undisassembled_census.py --judge` and `--islands`
score CODE-vs-DATA using **MAME's unidasm**, not `llvm-mc -disassemble` (see
`metrics()`/`judge()`/`islands()` — `UNI = ~/compartilhado/tools/unidasm`).
Fresh `--prepare`/`--census`/`--judge`/`--islands` on all three tags
(v7/v9/v10, all rebuilt from this lane's own tree first) reproduces the
confirmed-region backlog **exactly unchanged**: 5 regions / 348 B on both v9
and v10 (the same hand-audited DATA rejects documented since 09-01/09-02),
and `--islands` reports the same shape (v10: 15,855 CODE-flanked `.byte`
runs / 28,698 B, 8,383 in genuine-code context / 13,700 B). A decoder fix
cannot move a number an unrelated tool computes — recorded so nobody re-runs
this expecting movement.

Likewise, `convert_region.py`/`convert_interrupted_region.py` (the
confirmed-region conversion pipeline) decode via unidasm + a hand-written
mnemonic translation table (`convert_code_bytes.py`), falling back to
`llvm-mc --disassemble` only when that table has no rule. A same-day sibling
commit (`353b6796`) already found "the decoder fix did not unblock anything
here" for that pipeline and was correct **for the decoder state at the
time** (`ad8129f59880`, before SriRR/ERP existed). Confirmed-region backlog
for v9/v10 was already fully closed before this session (0 B, per
`scripts/analysis/README-v9v10-census.md`'s 2026-09-02 update) — there was
nothing left in that shape for either decoder state to unblock.

## Step 3 — the actual opening: single-instruction ISLANDS

`--islands` measures literal `.byte` runs flanked by real instructions on
both sides — single TLCS-900 instructions `llvm-mc` could not spell. That
shape is scored by unidasm too, so its *count* does not move, but **whether
a given island can be REPLACED** depends on `llvm-mc --disassemble`
directly, which is exactly the leg this decoder fix touches and exactly the
leg `convert_region.py`'s pipeline never exercises for this shape.

`scripts/converters/convert_decoder_unblocked_islands.py` (committed this
session) scans every CODE-flanked isolated `.byte` line in a tag's maincpu
tree, tries `llvm-mc --disassemble` on it, and — only if warning-free AND a
full binary reassembly reproduces the ORIGINAL bytes exactly (never the
`--show-encoding` field, which can under-report consumed length: the
documented `bb 00 50` vs `b3 50` trap) — replaces that line.

### Round 1 (commit `6f9db2e4`)

150 CODE-flanked isolated `.byte` lines across 24 files, 668 B, now decode
+ round-trip byte-exact. Mirrored to v9 wherever the same line number
carries the identical `.byte` bytes: all but one (`accompaniment_engine.s:
35699`, one of the ~581 B of real, previously-documented v9/v10 territory
divergence — applied to v10 only).

Corroboration:
* `accompaniment_engine.s:10540` ("nop/nop/call 0xF5BF4E/ret") resolves to
  `AccProcess_InlinedCode`, already named in
  `symbols/maincpu_v10_symbols_reference.txt` (1 hit / 1 checkable target,
  `verify_converted_call_targets.py --git-diff HEAD~1 HEAD --tag v10`).
* `widget_dispatch.s`'s 30 identical 7 B stubs (`ex_ff` / `ld xwa,
  0xFFFF00FB` / `swi 7`) are each the target of a `.long UIState_ConfigC_NNN`
  entry in a jump table in the same file — confirmed exhaustively: the file
  carries exactly 128 `.long UIState_ConfigC_\d+` references and exactly
  128 `UIState_ConfigC_\d+:` labels, a perfect match, not a closed loop of
  fabricated references.

Verified: `make rebuilt_ROMs/kn5000_v9_program.llvm.rom
rebuilt_ROMs/kn5000_v10_program.llvm.rom` then `cmp` against the original
dumps — both byte-identical.

### Round 2 (commit `96544abd`)

Re-running the same script after round 1 landed finds a SECOND wave — the
cascading effect the script's docstring warns about: converting one island
can turn a previously DATA-flanked neighbour into a newly CODE-flanked one
once the neighbour itself becomes a real instruction. 15,577 CODE-flanked
isolated `.byte` lines remained after round 1 (23,434 B); 182 of them
(606 B) now convert, concentrated in 10 files (`audio_control_engine.s`,
`sndparam_routines.s`, `sound_editor_ui.s`, `scoop_display.s`, six smaller).
23 candidates did not mirror to v9 (real content divergence in
`note_voice_mapping.s` and `sound_editor_ui.s` between the two firmware
revisions — applied to v10 only). No absolute call/jrl targets in this
batch (mostly short register/ALU forms); corroboration rests on the same
decode+round-trip discipline plus flanking-code context.

Verified: same narrow rebuild + `cmp`, both byte-identical.

### Round 3 — fixpoint

15,395 CODE-flanked isolated `.byte` lines remained after round 2
(22,828 B); **0 of them decode+round-trip** — the cascade from rounds 1-2
has run its course. No further round was applied. This IS the fixpoint,
not an artifact of a smaller scan: the scan logic is identical to rounds
1-2 and the file (`round3_dryrun.log`) is the direct tool run, not a
re-derivation.

### Total, this session

150 + 182 = **332 islands, 1,274 B**, converted across two rounds, both
independently `cmp`-verified byte-identical to the original ROM dumps
before commit. Not attempted further: WSA1R (checked, nothing in this
shape — see below), v7 (deprioritised per lane brief; separately, this
decoder gap is the one item 5 flags "33 of 34 v7 code slices fail a
disassemble/re-assemble round trip" for — a different, romslice-shaped
opportunity than the island shape here, left to whichever lane owns v7).

## WSA1R (priority #2): checked, nothing to convert

`grep -rc '^\s*\.byte\s+0x' wsa1/prom_a/ wsa1/prom_b/ wsa1/prom_c/
wsa1/prom_d/` returns **zero** `.byte` lines anywhere in any WSA1R source —
consistent with the debt inventory's "audited clean" status for prom_a/
prom_b and "0 — survived falsification" for prom_c/prom_d. There is no
code-as-`.byte` residue for this technique to find on WSA1R; its remaining
debt is purely verbatim (`.incbin` of genuinely undump-derived blobs,
41,761 B prom_a / 32,556 B prom_b), a different category this decoder fix
does not touch. The one WSA1R byte sequence this fix's own regression test
already exercises (`ldb_erp`/`ld QW,A` at `wsa1_prom_a.s:6785`,
`0xF831FF`) was already correctly spelled in source before today — the fix
only means a future audit of raw WSA1R blob content for hidden SriRR/ERP
code would no longer be blind to those forms, which is future work, not a
finding.

## Reproduce

    python3 scripts/converters/convert_decoder_unblocked_islands.py v10
        # dry run, lists every remaining candidate
    python3 scripts/converters/convert_decoder_unblocked_islands.py v10 --apply
        # writes v10, and v9 wherever its mirror line matches
    make rebuilt_ROMs/kn5000_v9_program.llvm.rom rebuilt_ROMs/kn5000_v10_program.llvm.rom
    cmp rebuilt_ROMs/kn5000_v9_program.llvm.rom original_ROMs/kn5000_v9_program.rom
    cmp rebuilt_ROMs/kn5000_v10_program.llvm.rom original_ROMs/kn5000_v10_program.rom

LLVM pin used throughout this session: `tlcs900_backend@975a2c17d683`
(`975a2c17d683be783e00219e3e28cc0bb8dcb28f`) — the build/bin binaries on
disk were last rebuilt at 02:24, before the next decoder-touching commit
(`63ff7d92fb5f`, 02:28:53) landed, so that later commit is NOT reflected in
any ROM built by this lane this session.
