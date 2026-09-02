# Lane RQ-CODESHAPE — the two §6 "code misclassified as data" populations, 2026-09-02

Worktree `~/compartilhado/disasm-lanes/rq-codeshape`, branch `w14/rq-codeshape`.
Base `08d0c4e8`. Toolchain `tlcs900_backend @ 6f456a19f05b`
(`6f456a19f05bf94696728e89e74a53ed62dc9adf`) — unchanged across every number
below; no measurement here straddles a decoder rebuild.

`make gate-all` **PASS: 13 of 13 rebuilt ROMs byte-identical**, run in this
worktree after the conversion. Proven able to go RED: perturbing one converted
operand (`ldw wa, 72` → `73` in `sequencer_engine.s`) makes exactly one byte
differ, at `0xF3B492`, built `0x49` against the dump's `0x48`; restored and
re-verified identical.

## The headline

| | census §6 | this lane |
|---|---|---|
| control-transfer-targeted | 1,089 regions / 85,536 B, uncounted | **484 sites enumerated and graded; 64 converted, 2,466 B** |
| code-shaped label | 26,853 regions / 542,405 B, unranked | **ranked; only 2.6 % of its bytes carry reference evidence, 30 % are address-taken-only, 67 % have no reference at all** |

**Phantoms found: zero.** The IC19 shape — a transfer that is really the
displacement byte of a preceding `jr cc,d8` — does not reproduce anywhere in
this population. The 14 sites that looked like it are misframes of real code,
7 of them duplicated across the v9/v10 twin trees. Evidence in §3.

**And the phantom test itself had to be corrected**: asking llvm-mc "does the
first instruction fail" flagged 199 regions / 6,543 B, all of them real
instructions the backend cannot spell. §3b.

## 1. The instruments, and their nulls

Two scripts, both committed:

* `scripts/analysis/code_suspect_sites.py` — enumerates the population the
  census only counts, with **every referring source site attached**, from
  source text alone (no decoder, so no toolchain dependence).
* `scripts/analysis/code_suspect_adjudicate.py` — grades each site: address
  guard, decode, per-instruction round-trip, referrer quality; plus `--null`,
  `--randomctl` and `--blockers`.

### The flag's null is NOT the pure-data images

`table_data`, `custom_data` and `prom_d` score **0** control-transfer hits, and
that number is **worthless**: those images contain no instruction statements at
all (`prom_d`: 0 non-directive statement lines in 4 files), so no control
transfer can exist to be counted. A control rate pinned at zero by the
structure of the test is precisely the defect that got the "46× undecodable
leading byte" finding retracted, and quoting it here would repeat that mistake.

**The null used instead lives inside the same three code-bearing images** and is
certified by an authority independent of every decoder and every framing
judgement in this tree: regions emitted by `.incbin` of a `.bin` the Makefile
produces by compiling a `.c` file with `clang -target tlcs900`. Those bytes are
data because a C compiler emitted them.

    population (v7+v9+v10)                        labels   targeted    rate
    all labels heading a data run                 23,003        484   2.10%
    NULL: C-compiled .incbin (generated/)         11,179          0   0.00%
    raw ROM-slice .incbin                            180         10   5.56%
    literal .byte/.word/... run                   11,644        474   4.07%

    python3 scripts/analysis/code_suspect_adjudicate.py --null

**And the one confound on that zero was measured, not assumed.** You cannot
write a label inside an `.incbin`, so a real transfer into the middle of a
C-compiled blob could only be spelled numerically and would escape a symbolic
count. Resolving every numeric control transfer against the C-compiled address
ranges of the linked images: **711 numeric transfers, 0 land inside one**
(v7 367, v9 214, v10 130).

So the control-transfer flag has a **hard zero false-positive rate on 11,179
independently certified data regions**, against the name-based flag's 4.7 %.
That is the difference the brief expected, and it is now measured rather than
asserted.

### The decode test's null

    python3 scripts/analysis/code_suspect_adjudicate.py --randomctl 120 \
            --sizes 8,16,24,32,48,64,96,128,192,256

    fully clean decode + per-instruction round-trip   1/120 =  0.8%
    ends exactly on the region end                   29/120 = 24.2%

The 24.2 % reproduces the architecture's known blind-decode base rate
(`blind_run_decode_census.py`, 24.2–24.3 %) — so "it ends on a boundary" is
nearly free and is **not** evidence. Requiring every instruction to reassemble
to its own bytes is what makes the test worth 0.8 %.

⚠ Honest limit, stated because the brief asked for one: under `allclean` the
endpoint column adds nothing — `convert_block` is handed exactly the region's
bytes and cannot overrun, and 0 of 484 regions are clean-but-not-ends-exact.
The independent endpoint evidence is the call-target boundary audit in §4, not
that column.

## 2. Reconciling with the census's 1,089 / 85,536 B

This lane's rule is **stricter** than the census's: the targeted label must
*head* the data run, where the census accepts a targeted label anywhere within
a few lines of the region. Under the strict rule:

(measured at `ec98912f`, BEFORE this lane's 64 conversions -- this is the
population that was adjudicated, not what is left)

    image   sites   bytes(symbol-derived extent)
    v7        413   23,341
    v9         36       83
    v10        35       82
    GRADED    484   23,506 B

    wsa1        1        3   screened only -- the grader has no linked image
    others      0        0   for the WSA1 proms. 485 screened, 484 graded.

The one WSA1 site is `prom_a/wsa1_prom_a.s:3479 sub_F81A83` (`0xF81A83`),
target of `call sub_F81A83` from `0xF81A2D`. It is 3 bytes the source ALREADY
annotates in line as `ld XBC3,0` — a WSA1 backend spelling gap, the same shape
as v9/v10's 71 sites. Real code, blocked on the assembler, adjudicated by
reading it.

The census's larger figure is not contradicted; it is a looser cut of the same
flag, and its extra bytes are regions whose *governing* label is targeted but
which do not begin at it. **Do not read 23,506 as a correction to 85,536** —
read it as the subset where the reference evidence actually points at the
region's first byte, which is the only subset where the reference licenses a
decode.

## 3. Adjudication — and why there are no phantoms here

### 3a. The phantom screen

The IC19 phantoms sat on an **island** of a few apparent instructions floating
between `.byte` runs. `refrun` measures exactly that: how many consecutive
instruction lines the referring transfer sits inside.

    referrer instruction-run length     sites
    20+                                   333
    8-19                                  115
    4-7                                    24
    1-3                                    12

⚠ The obvious metric — distance in lines to the nearest `.byte` — is **not** a
discriminator on this tree and is reported only for continuity with the IC19
work: in v7 almost every file is peppered with `.byte`, so a small distance is
the norm, not a warning. `refrun` is the one that separates.

### 3b. What blocks the regions that do not convert

    python3 scripts/analysis/code_suspect_adjudicate.py --blockers

Two very different things hide behind "does not decode clean", and only one of
them says anything against the transfer. The discriminator is **unidasm** — a
decoder wholly independent of this tree's llvm backend — asked what it sees
**at the branch target**:

    PHANTOM SHAPE: unidasm emits a raw data byte at the target,
    so the target is not an instruction start          14 regions,     18 B
    BACKEND SPELLING GAP: unidasm decodes a real
    instruction there; llvm-mc cannot reassemble
    something in the run                              390 regions, 20,533 B

⚠ **An earlier cut of this section got it wrong and is worth recording.** It
counted "llvm-mc's first failure is at offset 0" as the phantom shape and got
**199 regions / 6,543 B** — but the blocking forms were `bit`, `cp`, `res`,
`and`, `or`: perfectly real TLCS-900 instructions llvm cannot yet spell.
Framing a toolchain gap as evidence against the data would have inverted the
verdict on a fifth of the population. The corrected test asks a decoder that
has no stake in the llvm backend.

First-blocking form, by region count — this is the backend lane's worklist:

    bit 74 · cp 65 · res 54 · and 36 · or 35 · ld 25 · push 24 · set 17
    add 14 · db 14 · call 10 · sub 7 · ldw 6 · pushw 6 · ldirw 3 · ex 2
    div 2 · jp 2 · ldc 2 · ldir 1 · tset 1 · ldiw 1 · lda 1 · srl 1 · pop 1

### 3b-2. And the 14 "phantoms" are not phantoms either — they are misframes

The 14 are **7 distinct sites, each appearing in both the v9 and v10 twin
trees**, and every one is a 1–2 byte `.byte` run that is the **head of a longer
instruction the source splits with a label**. Widening the decode window:

    SetWall_JumpStubData        0xF1EE11  region 2 B  ->  and (0x0ce0),0xfe   5 B
    VoiceSlot_StatusRet         0xEFC7B2  region 1 B  ->  cp  (0x0d65),0x00   5 B
    CtrlPanelGuard_ClearNibble  0xFC78BF  region 1 B  ->  and (XWA),0xf0      3 B
    FDC_CmdRecalibrate          0xF97652  region 1 B  ->  push QIZ            3 B
    FDC_STATUS_COPY             0xF97C54  region 1 B  ->  ld (0x8a24),(0x8a26) 6 B
    FDC_INTERRUPT_HANDLER       0xF97C7C  region 1 B  ->  push QIZ            3 B
    AccAutoPlay_Configure_Done  0xF5ABAF  region 2 B  ->  and (0x3499),0xfe   5 B

`ui/setwall_routines.s` shows the shape exactly:

    SetWall_JumpStubData:
        .byte 0xc1, 0xe0
        incf
        push    xix
        swi     6

`incf`, `push xix` and `swi 6` are decoded **from inside the operand bytes of
the `and`**. The ROM still rebuilds byte-identically — the bytes are right and
only the framing is wrong, which is precisely the class of error the byte gate
cannot see. The `call SetWall_JumpStubData` that targets `0xF1EE11` lands on the
real instruction start, so the transfer is genuine and the region is code.

⚠ **Not fixed by this lane, deliberately.** Repairing them is a RE-FRAMING of
v9 and v10, not a data→code conversion; it would rewrite following lines that
already carry symbolic call targets, and the gate is silent either way. Handed
off with the correct decode above so the owning lane can do it with the right
resync check.

### 3c. Verdict

**80 v7 regions / 2,955 B pass fully** (clean decode + per-instruction
round-trip), against the 0.8 % random-byte null. **No phantom control transfer
was found anywhere in the 484.** The 390 that do not convert are held up by
named llvm spelling gaps at a median 83 % of their bytes convertible; the 14
that looked like phantoms are misframes of real code.

That is a stronger result than the brief expected, and it is worth stating why:
the flag is a *reference*, and a reference in this tree is a symbol the
force-disassembly resolved to an address. The IC19 phantoms were different in
kind — they were transfers named by a *numeric* address inside a byte run that
was itself mis-framed. This population has none of that shape.

## 4. What was converted, and its corroboration

`scripts/converters/convert_code_suspect_v7.py --apply` — **64 regions,
2,466 B**, in 24 v7 files. Selection requires `allclean` AND `refrun >= 8`.

* `make gate-all`: 13/13 byte-identical, and shown able to go red (top of file).
* `scripts/analysis/no_label_was_dropped.py`: 24 files changed, **0 labels lost,
  0 added** — the check the byte gate cannot perform.
* `scripts/analysis/v7_call_target_boundary_audit.py` on the 26 call targets the
  conversion introduces: **17 exact label hits, 9 landing on a real instruction
  boundary, 0 uncorroborated**.

### Debt before and after, measured by something that did not do the conversion

    python3 scripts/analysis/byte_literal_debt.py v7/maincpu --rev ec98912f
    python3 scripts/analysis/byte_literal_debt.py v7/maincpu

    v7/maincpu at ec98912f (before)   293,594 B spelled as `.byte` literals
    v7/maincpu after                  291,128 B
    difference                          2,466 B

Equal to the converter's own tally, computed from the source by counting
`.byte` OPERANDS rather than trusting the tool under test. (Directive counts
are the wrong instrument — the brief is explicit about that — so this counts
bytes. It is a `.byte`-literal figure only: `.word`/`.ascii`/`.zero`/`.incbin`
are excluded on purpose and it must be quoted as such.)

Not converted, with reasons:

    10  refused by the new rewind guard (see §5)
     3  refrun < 8 -- FDC_Format2DD_TrackBody (41 B, `jr ule`),
        AccVoice_ScanForD3 (32 B, `jr`), Rhythm_Transp_WrapCheck (7 B, two
        referrers: `jr` and `jr z`). All three decode clean and all three sit in
        plainly coherent code -- `Rhythm_Transp_WrapCheck`'s referrer reads
        `sub a, 0xc / add w, a / bit 7, w / jr z, Rhythm_Transp_WrapCheck /
        add w, 0xc`, an octave-wrap check. Their `refrun` is low only because
        the surrounding routine is itself bounded by unconverted `.byte` runs,
        which is a property of the tree's current state and not of the evidence.
        The threshold of 8 is deliberately conservative; these are leads for the
        next pass, not rejections.
     3  symbol-derived extent shorter than the source run they begin, so a
        partial conversion would need the run (or the .incbin) split first:
        VoiceSlot_StatusRet (96 of 2,268 B), SeqChLoad_SetupAndCopy (38 of 161),
        SeqTimerFlags_CheckSysFlag (22 of 157).

## 5. ⚠ A LATENT BUG IN THE SHARED CONVERTER, and how close it came to passing

`convert_interrupted_region.rewind_to_true_start()` walks backward "while the
preceding line is still a recognized DATA directive (blanks and labels do not
stop it)". When the region **above** the one being converted is itself a raw
`.byte` run, that walk crosses the intervening label and keeps going —
and `find_span()` then sums the requested size from the **wrong region**.

Hit on the first apply of this lane's batch:
`sequencer_engine.s:4621 AccPedalConfig_StoreCtrl6ValsAlt` (0xF3B526, 20 B) had
its decode written into `AccPedalConfig_StoreCtrl6Vals` (0xF3B512, 20 B), one
region above. **The two are near-clones**, so the rebuilt ROM differed by
exactly ONE byte — the `jrl` displacement, `0x0161` where the dump has `0x0175`.
Had they been exact clones the byte gate would have stayed **green** on a
conversion that rewrote the wrong region.

Fix: `convert_interrupted_region_v7.process()` gains an optional
`min_start_line`. Default `None` = previous behaviour exactly, so no other
lane's calls change. When passed, it refuses if the rewind crosses any
**byte-emitting** line above the region's own label (crossing blanks, comments
and the label line itself is normal and harmless). It refuses 10 of this lane's
74 selected regions, including the culprit.

★ The general shape: a converter that locates its own span by walking outward
from a hint can walk into a neighbour, and when the neighbour is a near-clone
the byte gate degrades from a proof to a one-byte coincidence. Any tool in this
tree that rewinds or extends a span past a label should be given the caller's
own boundary and made to refuse.

## 6. The code-shaped-label population — ranked, not converted

`scripts/analysis/code_shape_shortlist.py`.

Re-derived under the same strict "label heads the run" rule, and excluding
`.incbin` of C-compiled bins (data by external authority — the flag firing there
is a false positive by construction, 1,359 such labels across v7/v9/v10):

    image        literal runs      bytes | table-named       bytes
    v7                  3,588    140,197 |         327      43,151
    v9                    893     25,800 |         134      20,671
    v10                   548     26,472 |         135      21,069
    hdae5000               59     28,016 |           8         904
    v142                   42      1,006 |          17         292
    subboot                 2         48 |           1          32
    wsa1                  558     38,876 |         453      26,492
    tabledata              12     73,844 |           5         120
    customdata              0          0 |           0           0
    TOTAL                          334,259 |                112,731  (33.7%)

### The structural finding: a third of the flagged bytes are self-labelled tables

`dispatch` and `handler` are in the census's `CODE_NAME_TOKENS`, so
`SoundEffect_Dispatch_Table`, `Naka_MainDispatch_Table`,
`TuningSystem_Handler_Table` and `SoundProgram_DispatchTable` all trip a
CODE-shaped flag **while their own names say TABLE**. They are also the flag's
largest byte contributors. Labels carrying a data noun as well as a code token
are **33.7 % of the flagged literal bytes**, and jump tables round-tripping as
code is this project's standing trap — six such conversions were reverted by
hand.

⚠ De-rank, not dismiss. The standing exception is real: one lane found a routine
address-taken nine times from a handler table that is perfectly good code. A
table-shaped name lowers the rank; only a decode plus a reference decides.

### The stronger de-rating signal is the REFERENCE KIND, not the name

    python3 scripts/analysis/code_shape_shortlist.py --refkind

    class                         bytes   share
    CTRL-TARGETED                  8,582    2.6%
    address-taken only            99,911   30.0%
    no reference anywhere        224,930   67.5%

(Measured AFTER this lane's 64 conversions, so v7's CTRL-TARGETED figure is
8,538 B rather than the 9,374 B it was before.)

**Only 2.6 % of the code-shaped flag's bytes carry the reference evidence that
the other population has.** Thirty per cent are address-taken and never called
or jumped into — the project's standing rule for that shape is *data*. And
two thirds have no reference of any kind, so the flag is the ONLY thing said
about them and there is nothing to corroborate it with.

Worked check on the largest non-table-named members of the middle class, all
v7: `WndEvt_EventCodeDispatch` (1,527 B), `CmpNcpTtl_Dispatch2` (1,311 B),
`Sqedt_ParamDispatch` (1,210 B), `Data_InOutGridDispatch` (1,096 B),
`VocalistGrid_CheckDispData` (709 B), `NameGetFuncCall_Dispatch` (697 B),
`Data_ParaLoadOptDispatch` (656 B), `CstmCpTtl_Dispatch2` (591 B),
`SeqAccomp_SubHandlerA` (504 B). **Every one is referenced exactly once, by
`lda_24`, and the instruction after that load is `jp_ind`.** They are
jump-table bases. So the top of the population survives the table-NAME filter
and is caught by the reference filter instead — which is why both are applied.

### And a chunk of the flag's own null is visible here

`prom_d` — one of the three images the census uses as its pure-data null, and
confirmed here to contain **0 instruction statements** — carries **334
code-shaped labels over 19,814 B**, the largest single contributor to the WSA1
total. Those are certain false positives, and they are the flag's 4.7 % floor
made concrete rather than left as a percentage.

### Coverage, stated honestly

See the shortlist output for the ranked table and for how many bytes of the
flagged population were actually decoded. **Most of the 542,405 B was not
examined**: the population is 26,853 regions averaging 20 B, and this lane
decoded only the largest runs of the three images where a linked address is
available. Everything outside that is screened by name and size alone.

## 7. What the next lane should take

1. **The 390 backend-blocked control-transfer-targeted regions, 20,533 B, at a
   median 83 % convertible.** They are the highest-confidence undecoded code in
   the tree — every one is a branch or call target, and the flag has a
   hard-zero false-positive rate on 11,179 certified data regions — and they
   are blocked on *named* llvm spelling gaps, not on judgement. `--blockers`
   prints the form census; `bit`, `cp` and `res` alone gate 193 of them.
   ⚠ **Do not bulk-convert them PARTIALLY.** `convert_interrupted_region` will
   happily emit instructions for the decodable prefix and leave the rest as
   `.byte`, which would harvest most of the 20,533 B and rebuild
   byte-identically. But the decode after an unspellable instruction continues
   from **unidasm's length for an instruction llvm-mc could not confirm**, so a
   mis-sized blocker silently misframes everything downstream — and the byte
   gate cannot object, because the bytes are read back from the same offsets.
   For the fully-clean regions the whole run tiles exactly and that risk does
   not exist. Fix the spelling gaps first, then re-run the clean gate.

2. **The 3 extent-shorter-than-run regions** need an `.incbin` or `.byte`-run
   split first (`scripts/converters/README-incbin-range-splits.md`).
3. **The 7 misframed 1-2 byte sites of §3b-2**, in both v9 and v10, with the
   correct decode already written out. A re-framing, not a conversion.
4. **`min_start_line` should probably become mandatory** for every caller of
   `convert_interrupted_region*.process()`, not optional. This lane left it
   optional to avoid changing other lanes' behaviour mid-push.
