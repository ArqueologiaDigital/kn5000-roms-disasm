# Probe: llvm-mc spelling for the unidasm form `inc <n>,<REG>`

One printed text, `inc 1,WA`, is **two** different TLCS-900 encodings: the
2-byte short register form `d8 61` and the 3-byte extended-register form
`d7 e0 61`. Same for `inc 1,W` (`c8 61` / `c7 e1 61`) and `inc 1,XWA`
(`e8 61` / `e7 e0 61`). **94.0 % of the `inc n,REG` sites in these ROMs print a
text that a second encoding also prints**, so a converter turning `.byte` blobs
into instructions must choose from the RAW BYTES.

| script | question it answers | command |
|---|---|---|
| `verify_inc_reg.py` | Does the rule assemble byte-exactly at **every** encoding in the space, and at every `inc n,REG` site in v7, v9, v10 and the table-data ROM? | `python3 tools/spelling-probes/verify_inc_reg.py` |
| `verify_inc_reg.py --negative` | Can this check fail? Runs the rule a reader of the `.td` **comment** would write (`0x60+(n-1)`, so emit `n+1`). | `python3 tools/spelling-probes/verify_inc_reg.py --negative` |
| `verify_inc_reg.py --dangerous` | Which near-miss spellings assemble and emit the WRONG bytes? Assembles each one live. | `python3 tools/spelling-probes/verify_inc_reg.py --dangerous` |
| `verify_inc_reg.py --ambiguous` | How many sites print a text that another encoding also prints — i.e. how badly does re-spelling from the LISTING fail? | `python3 tools/spelling-probes/verify_inc_reg.py --ambiguous` |
| `code_or_data_inc_reg.py` | Of the sweep hits, which are real instructions — and do the three unspellable classes occur in real code at all? | `python3 tools/spelling-probes/code_or_data_inc_reg.py` |
| `blocking_inc_reg.py` | Which `inc n,REG` sites actually block `convert_reachable_ranges.py`, at what addresses, with what bytes? | `python3 tools/spelling-probes/blocking_inc_reg.py` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_<v>_program.rom`
at load base 0xE00000, `kn5000_table_data.rom` at 0x200000). PASS =
`llvm-mc -triple=tlcs900 --show-encoding` output equals those bytes.
"Assembled without error" is NOT a pass.

## The rule

    n = (last byte) & 7          -- unidasm prints this LITERALLY (0 means 8 in
                                    hardware, and unidasm still prints `inc 0,XSP`)

    c8+r  60+n     (2B)  ->  inc <n>, GR8[r]      GR8  = w a b c d e h l
    d8+r  60+n     (2B)  ->  inc <n>, GR16[r]     GR16 = wa bc de hl ix iy iz
                             r == 7 (SP, `df 6n`)  ->  NO SPELLING EXISTS
    e8+r  60+n     (2B)  ->  inc <n>, GPR[r]      GPR  = xwa xbc xde xhl xix xiy xiz xsp
    c7 rb 60+n     (3B)  ->  incb_erp 0x<rb>, <n>            (every rb, every n)
    d7 rb 61       (3B)  ->  inc1w_erp 0x<rb>
    d7 rb 64       (3B)  ->  inc4w_erp 0x<rb>
    d7 rb 60+n     (3B)  ->  inc <n>, QMAP[rb]    for n not in {1,4}, only where rb
                             names a previous-bank word register:
                             e2=qwa e6=qbc ea=qde ee=qhl f2=qix f6=qiy fa=qiz fe=qsp
                             any other rb  ->  NO SPELLING EXISTS
    e7 rb 64       (3B)  ->  inc4_lerp 0x<rb>
    e7 rb 60+n     (3B)  ->  NO SPELLING EXISTS for n != 4

    r  = first byte & 7
    rb = the RAW extended-register byte, passed straight through as an immediate

Three traps:

* **The count is `n & 7`, not `n - 1`.** `TLCS900InstrInfo.td` documents INC32 as
  `E8+rd, 0x60+(n-1)`; the *encoder* emits `0x60+(n&7)`. `inc 1, xwa` is `e8 61`,
  not `e8 60`. unidasm and llvm-mc therefore agree on the number, digit for digit.
  Believing the comment is what `--negative` measures: it is wrong 20 113 times.
* **`rb` must stay a raw byte.** There is no way to turn it back into a name
  reliably: unidasm renders `0xFB` as `QIZH` under the `c7` prefix and as part of
  `QIZ` (`0xFA`) under `d7`, and anything below `0xE0` as a *bank* register
  (`RC3`, `RBC3`, `XBC3`) that the backend has no name for at all. The `_erp`
  families in this tree all pass the register byte as an immediate; `inc` is the
  same shape.
* **`inc1b_erp 0x<rb>` is the same bytes as `incb_erp 0x<rb>, 1`** and is what the
  v9 sources mostly use (76 of the 77 byte-ERP increments). Prefer `incb_erp`: it also covers
  `n != 1`, where no `inc<N>b_erp` exists.

The spelling is **not new to this tree** — it was only missing from the
converter's unidasm-text → mnemonic map. The byte-exact v9 sources already carry
76 `inc1b_erp`, 36 `inc1w_erp`, 1 `incb_erp`, 1 `inc4w_erp`, 1 `inc4_lerp`
(v7: 64/30/1/-/1; v10 same as v9).
The comment in `scripts/converters/convert_corroborated_blocks.py` that says
"`ld`/`inc` have no `_erpb` equivalent found yet" is false for `inc`.

## Results, 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

EXHAUSTIVE over the whole encoding space — every prefix × every `rb` × every `n`,
6 336 encodings, generated from the SPACE and not from this firmware, so
coverage does not depend on what the KN5000 happens to contain:

    c8+r 6n   (2B)     64 byte-exact       0 no form
    d8+r 6n   (2B)     56 byte-exact       8 no form   (`df 6n` = SP)
    e8+r 6n   (2B)     64 byte-exact       0 no form
    c7 rb 6n  (3B)   2048 byte-exact       0 no form
    d7 rb 6n  (3B)    560 byte-exact    1488 no form   (n not in {1,4}, rb not a Q reg)
    e7 rb 6n  (3B)    256 byte-exact    1792 no form   (n != 4)
    TOTAL            3048 byte-exact    3288 no form   0 WRONG

ROM sweep (unidasm linear scan of every `inc n,REG` site):

    v7     6326 /  6326 byte-exact    7 no form   0 failures
    v9     6743 /  6743 byte-exact    5 no form   0 failures
    v10    6743 /  6743 byte-exact    5 no form   0 failures
    table   548 /   548 byte-exact   26 no form   0 failures
    GRAND TOTAL 20360 / 20360 spellable sites, 0 failures (20403 sites seen)

    by encoding class: e8+r 10354 · d8+r 6179 · c8+r 2601 · c7 rb 61 957 ·
    d7 rb 61 228 · d7 rb 64 10 · c7 rb 60 9 · e7 rb 64 9 · c7 rb 64 6 ·
    c7 rb 62 5 · c7 rb 63 2

    --negative (count taken as n-1):  247 / 20360, 20 113 failures. The 247
    survivors are exactly the d7/e7 forms whose count is baked into the mnemonic
    (`inc1w_erp`, `inc4w_erp`, `inc4_lerp`), where the off-by-one cannot be written.

    --ambiguous: 19 184 / 20 403 sites (94.0 %) print a text that a second
    encoding also prints; 352 such texts exist in the space.

Real instructions, source-anchored in the byte-exact v9 build (`cmp
rebuilt_ROMs/kn5000_v9_program.llvm.rom original_ROMs/kn5000_v9_program.rom` is
silent), one per encoding class. Every address below is a DWARF source-statement
row of a `-g` rebuild that was itself verified byte-identical to the original ROM:

| address | ROM bytes | unidasm | llvm-mc spelling | in |
|---|---|---|---|---|
| 0xEF0898 | `c7 fb 61` | `inc 1,QIZH` | `incb_erp 0xfb, 1` | `Boot_CallInitHandlers__handler_loop+0x1b` (`v9/maincpu/shared/boot_call_init_handlers.s:75`) |
| 0xF0699A | `c7 fb 61` | `inc 1,QIZH` | `inc1b_erp 0xfb` | `SeMenu_SetupMenuDisplay_Data2+0x16` |
| 0xEF4476 | `d7 fa 61` | `inc 1,QIZ` | `inc1w_erp 0xfa` | `FDC_WriteSectors_TrackLoop+0x18` |
| 0xF6D11B | `d7 fa 64` | `inc 4,QIZ` | `inc4w_erp 0xfa` | `StylCnv_Type3_CopyBlockLoop+0x27` |
| 0xEF3FE9 | `e7 34 64` | `inc 4,XBC3` | `inc4_lerp 0x34` | `SLIDE_Decompress_4K_FillRing+0x23` |
| 0xEF0C50 | `c9 61` | `inc 1,A` | `inc 1, a` | `INTT1_StoreCounters+0x12` |
| 0xEF1982 | `d8 61` | `inc 1,WA` | `inc 1, wa` | `TaskSched_Init+0xb` |
| 0xEF46CF | `e8 61` | `inc 1,XWA` | `inc 1, xwa` | `FloppyChange_Debounce1_Loop+0x0` |

End-to-end check that the assembler emits the same bytes through a real object
file, not only in `--show-encoding`:

    printf '\t.text\n\tincb_erp 0xfb, 1\n\tinc1b_erp 0xfb\n\tinc1w_erp 0xfa\n\tinc4w_erp 0xfa\n\tinc4_lerp 0x34\n\tinc 1, a\n\tinc 1, wa\n\tinc 1, xwa\n\tinc 6, qwa\n' > /tmp/seven.s
    llvm-mc -triple=tlcs900 -filetype=obj /tmp/seven.s -o /tmp/seven.o
    llvm-objcopy -O binary --only-section=.text /tmp/seven.o /tmp/seven.bin && xxd -p /tmp/seven.bin
    # c7fb61 c7fb61 d7fa61 d7fa64 e73464 c961 d861 e861 d7e266

## What this unblocks

`blocking_inc_reg.py` re-runs the converter's own decode over the 1129 v7
reachable call targets. 451 distinct `inc n,REG` sites decode inside those
ranges; **41 had no spelling**, and every single one is the byte-size
extended-register form `c7 rb 61`:

    31 x  c7 fb 61   inc 1,QIZH
     9 x  c7 fa 61   inc 1,QIZL
     1 x  c7 ea 61   inc 1,QE

all of which are now `incb_erp 0x<rb>, 1`. No `d7` site is blocked — unidasm's
Q-names for that prefix (`QIZ`, `QWA`, `QBC`, `QHL`, …) are real backend
register names, so the verbatim listing text already assembles to the right
three bytes — and no `e7` site with `n != 4` occurs in a reachable range at all.

⚠ `convert_reachable_ranges.py --forms` reports a smaller number for this form
(22 at the time of writing) because its counter records **one form per RANGE**:
it stops at the first unspellable instruction, so a range that also contains an
unspellable `ld r,(imm)` earlier is attributed to that instead. 41 is the count
of distinct SITES; both are correct about what they measure.

`blocking_inc_reg.py` reproduces the range-level measure too, and puts
`inc 1,r` at the TOP of that list, 27 ranges:

    27  inc 1,r          21  cp r,(imm)       14  lda r,r+r
    13  ld (r+imm),imm   12  ld (r+r),r       11  cp (imm),r
    10  res 0,(imm)       9  push r            9  set 0,(imm)

(27 rather than 22 because this census attributes a range to its first
unspellable non-branch instruction directly, while the converter also truncates
ranges and re-tries the remainder; the RANKING is what both agree on.)


## The three gaps that are NOT worth filling

`code_or_data_inc_reg.py` asks the byte-exact build rather than a heuristic: it
re-assembles the v9 sources with `llvm-mc -g`, proves the result is still
byte-identical to the original ROM, and reads the DWARF line table, which carries
one row per emitting source statement. An instruction the sources really contain
must start a row.

    c7 rb 6n  byte ERP            (incb_erp)                221 /  325 real code
    c8+r 6n   byte register                                 762 /  825 real code
    d7 rb 6n  word ERP            (inc1w_erp/inc4w_erp)      66 /   76 real code
    d8+r 6n   word register                                1918 / 1995 real code
    e7 rb 64  long ERP            (inc4_lerp)                 1 /    3 real code
    e8+r 6n   long register                                2937 / 3519 real code
    df 6n     INC n,SP            (NO llvm-mc form)           0 /    2 real code
    e7 rb 6n  long ERP n != 4     (NO llvm-mc form)           0 /    3 real code

The check can come out positive — it does, 5 905 times. It comes out **zero** for
both unspellable classes. The 43 no-form sweep hits across the four ROMs (30 ×
`df 6n`, 9 × `e7 rb 6n` with n≠4, 4 × `d7 rb 66`) are a linear scan reading data
as code; the four ROMs do not even agree on how many there are, which is what
that looks like.

So: do **not** add a TLCS900 `.td` definition for `INC #n, SP`, for the long-ERP
counts other than 4, or for the word-ERP counts other than 1 and 4, on the
strength of a linear-sweep census. Leave those runs as `.byte`; they are data.

## Spellings that ASSEMBLE and emit the WRONG bytes

Run `--dangerous` to reproduce this table live.

    inc 9, xwa          e8 61 -- imm3 SILENTLY WRAPS (9&7 = 1); this is `inc 1`
    incb_erp 0xfb, 9    c7 fb 61 -- the same silent wrap on the ERP form
    incb_erp 1, 0xfb    c7 01 63 -- OPERANDS SWAPPED and it still assembles:
                        bank byte 0x01, count 3. Nothing warns.
    inc1b_erp 0xfb      c7 fb 61 -- correct for n == 1 ONLY; there is no
                        inc<N>b_erp for other counts, so reusing this mnemonic
                        for a `c7 fb 62` site silently emits 0x61
    inc4w_erp 0xfa      d7 fa 64 -- wrong bytes at a `d7 fa 61` site
    incb_erp 0xfa, 1    c7 fa 61 -- WRONG PREFIX for a d7 site: the byte-size ERP
                        form assembles happily where the word-size one was meant
    inc 2, qiz          d7 fa 62 -- right here, but the Q-names are a trap: they
                        work for the d7 prefix only. `inc 1,QIZH` (c7) and
                        `inc 1,WA` (which is BOTH d8 61 and d7 e0 61) do not
                        survive being read back from the text.
    inc 1, qizh         rejected -- no Q byte-register class exists
    inc 1, ra0          rejected -- bank register names are not in the backend
    inc 1, xwa0         rejected -- ditto
    inc 1, sp           rejected -- GR16 excludes SP, so `df 61` has no spelling

    inc 8, xwa          e8 60 -- NOT a bug: 8&7 = 0 and the hardware count 8 is
                        encoded as 0. unidasm prints that site as `inc 0,XWA`,
                        so a byte-driven converter never writes 8 in the first
                        place.

## A trap in the tooling, not in the ISA

`scripts/converters/convert_reachable_ranges.py:decode_range()` writes its
scratch decode to `os.path.join(tempfile.gettempdir(), "_range.bin")` — a FIXED
path. Two processes using that function at once read each other's bytes. A first
run of `blocking_inc_reg.py` that imported it reported sites such as `0xF04E98
inc 1,WA` where the ROM actually holds `1d 09` (a `call`). `blocking_inc_reg.py`
therefore carries its own copy of the decoder, decoding into a private
`mkdtemp()`. Any probe that re-uses that function concurrently should do the same.
