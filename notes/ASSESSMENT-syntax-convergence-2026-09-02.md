# Should this tree's assembly syntax converge with MAME `unidasm`?

**Assessment, 2026-09-02.** Lane `w15/llvm-syntax`. No source and no backend
was changed by this lane; every figure below comes from a script committed in
`notes/syntax-convergence-probes/`, and `out/RUN.log` is the transcript of the
run that produced them.

**The question, from the project owner:**

> "I am not sure if it is viable, but I think we should also try to make it
> compatible with unidasm syntax or the other way around. It does not sound
> good to have multiple different syntaxes, but I need your assessment about
> it."

## Recommendation, up front

**Do not converge on unidasm syntax. Converge internally, on native LLVM
mnemonics with the operand form in the operand — the direction UPDATE 7 already
started — and keep unidasm exactly where it is: a second opinion, cited in a
trailing comment, never a source language.**

The reason is not taste. It is that **unidasm's output is not a language you
can assemble.** It renders more than one encoding with the same text. Fed back
to the assembler, unidasm's own text produces the ROM's bytes at 66.1% of
instruction sites, the **wrong** bytes at 23.5%, and does not assemble at
10.4%. A source syntax that silently emits the wrong byte at nearly a quarter
of its sites cannot carry a byte-identity gate, and the byte gate is this
project's only certification.

The good news in the same measurement: the two **decoders** do not disagree.
Over 1,113,485 instruction sites they consume the same bytes every single time.
The divergence the owner is looking at is entirely notational — which is why
fixing it is worth doing, and why it is safe to fix on our side alone.

## 1. What actually differs, and how much

### 1.1 The vocabulary gap

`mnemonic_census.py`, over all 547 tracked `.s` files:

| bucket | call sites | distinct names | files |
|---|---:|---:|---:|
| `NATIVE` — a name unidasm also has | 1,034,935 | 71 | 326 |
| `SYNTHETIC` — a backend name unidasm does not have | **265,116** | **459** | **303** |
| `MACRO` — a `.macro` defined in this tree | 16,922 | 113 | 77 |
| `UNKNOWN` | 163 | 4 | 4 |
| total | 1,317,136 | 647 | 340 |

unidasm's whole vocabulary is 112 names (`dasm900.cpp` `s_mnemonic[]`, 110 real
plus `db` twice). The backend's is 730. So **78.6% of instruction lines are
already spelled with a name both sides use**; the divergence is concentrated in
459 synthetic names over 265,116 sites in 303 files.

### 1.2 The divergence is structural, not cosmetic — but not uniformly so

Three different things hide under "synthetic mnemonic", and they cost very
different amounts to retire:

1. **Form-in-the-mnemonic, operand modelled** — `lda_d16 xwa, (36914)`,
   `ldb_d8`, `stdi8`, `bitda`. The instruction is fully modelled; only the
   *name* carries what should be in the operand. **These are a rename plus an
   operand annotation, and §3 shows 81,858 sites of them already assemble
   correctly under the native spelling with no backend change at all.**
2. **Form-in-the-mnemonic, operand only partly modelled** — `cps`, `lds`,
   `pushw`/`popw`, `ldw`. Here the mnemonic also selects between two legal
   *encodings* of the same instruction (short immediate vs full, 1-byte
   `push WA` = `28` vs prefixed `d8 04`). Retiring the name needs a way to say
   "this form", which the operand syntax does not currently have.
3. **Byte emitters wearing a mnemonic's name** — 98 names, **22,135 sites**.
   `add_sril_rm xix, 7, 236, 232` and `link32 238, 12, 248, 255` do not have
   operands at all: `$b0,$b1,$b2` are literal bytes. No rename reaches these.
   Converging their spelling means **modelling the operand first** — and
   UPDATE 8 deliberately made the `(xix+iz)` MEMri syntax a *diagnostic* rather
   than guess at it, after it had been silently misencoding.

The owner's instinct that this is "a real design divergence, not a formatting
one" is right for classes 2 and 3, and only half right for class 1.

### 1.3 The cosmetics point the other way from LLVM

unidasm prints lowercase mnemonics with **uppercase registers and no space
after the comma**: `ld W,0x4f`, `lda XWA,0x9032`. LLVM's own convention — and
what a backend that might one day be upstreamed has to look like — is lowercase
registers with a space: `ld w, 0x4f`. So even at the level of pure formatting,
**converging toward unidasm and converging toward LLVM norms point in opposite
directions.** This is a small argument, but it runs the same way as the large
one.

## 2. Do the two ever disagree about the instruction? Essentially no

`oracle_ab.py` harvests every instruction the assembler emits for all ten root
sources (bytes included, via `-show-encoding`), lays each one in its own
16-byte NOP-padded slot so a length disagreement cannot desynchronise the rest,
and runs unidasm once over the blob.

**1,113,485 sites compared. `LEN_DIFFER` = 0.** The two decoders consume the
same bytes at every site in both products.

That the instrument can see the failure is proved, not assumed:
`oracle_ab.py --foil 7` lengthens every seventh record by one byte and the run
reports 5,763 `LEN_DIFFER` on 40,330 sites (expected 5,761) —
`out/FOIL-CONTROL.log`.

Mnemonic text differs at **333,866 of the 1,113,485 sites (30.0%)** and agrees
at 779,611. That 30% is the whole of the visible divergence, and none of it is
a disagreement about what the machine does.

**Eight sites are the exception, and they are findings in their own right —
§5.**

## 3. What converging on unidasm would actually cost

Take unidasm's own text for every site, fold case, put a space after the comma,
and hand it back to the assembler. Nothing is translated: the point is to find
out what the backend makes of unidasm's language.

Of the 1,048,586 sites that are comparable as text (excluding 59,316 branches,
where unidasm prints an absolute target and the tree writes a label, and 5,575
that assemble to a relocation):

| verdict | spellings | sites | share |
|---|---:|---:|---:|
| `UNI_ASSEMBLES_SAME` — the backend already accepts it | 36,280 | 701,697 | 66.9% |
| `UNI_ASSEMBLES_DIFF` — **accepted, wrong bytes** | 25,553 | **246,622** | **23.5%** |
| `UNI_REJECTS` — the backend would have to learn it | 12,574 | 100,267 | 9.6% |

Re-measured 2026-09-02 against the preserved assembler `llvm-mc.snap`
(sha256 `53c6621d`), after the size-family conversions landed. The earlier
reading of this table was taken at a binary that no longer exists; the shares
moved by under a point and **no verdict changed**, which is the point of
re-running it. See `notes/TOOLCHAIN-PROVENANCE-2026-09-02.md`.

The 9.6% is the cheap part: 12,574 spellings to teach the parser. **The 23.5%
is the disqualifying part, because it is silent** — the assembler accepts the
line and emits a different byte string, which is exactly the failure class
UPDATE 7 and UPDATE 8 spent two backend commits eliminating.

### 3.1 Why: unidasm's text is many-to-one on encodings

`diff_causes.py` buckets those 246,622 sites by what unidasm's text failed to
say:

| cause | spellings | sites |
|---|---:|---:|
| `ADDR_WIDTH` — the direct-address field's width | 17,103 | 81,858 |
| `SHORT_FORM` — bare opcode vs prefixed form | 6,101 | 98,209 |
| `OTHER` | 2,343 | 66,790 |

and the `OTHER` rows, read one by one in `out/diff_causes_other.csv`, are the
same phenomenon in three more costumes:

    cp HL,0                 dbd8           vs  dbcf0000      short 3-bit imm vs 16-bit imm
    push 0x0000             0b0000         vs  0900          two PUSH-immediate encodings
    ldirw                   9311           vs  9511          register operand not printed at all
    ldir                    8011/8311/8511                   three encodings, one text
    mul BC,(XIZ+0x08)       8e0843         vs  9e0841        operand SIZE not printed
    cp QIZ,0x0080           d7facf8000     vs  d7fad8        immediate form not printed

The TLCS-900 spells the same direct address in an 8-, 16- or 24-bit field
(`C0/C1/C2`, `D0/D1/D2`, `E0/E1/E2`, `F0/F1/F2`) and unidasm prints `(0x0516)`
for all three. ⚠ **The width is not recoverable from the value** — UPDATE 7
records this firmware writing `set 7,(0x00008a)` as `F2 8A 00 00 BF`, a 24-bit
field for an address that fits in eight bits.

### 3.2 The direct proof, with its null

Measured over the same corpus: how many *distinct byte strings* print as the
same text?

| syntax | distinct texts | ambiguous texts | sites under them |
|---|---:|---:|---:|
| unidasm | 133,690 | **134** | 3,172 |
| this tree's LLVM text | 89,904 | **0** | 0 |

The second row is the control, and it is what makes the first row a statement
about unidasm's notation rather than about the corpus. `ldirw` stands for both
`93 11` and `95 11`; `ld W,0x00` for `20 00` and `c8 03 00`; `ret GE` for
`b0 f9` and `b6 f9`; `ldc unknown,XWA` for four different encodings — unidasm
prints the literal word `unknown` where a control register has no name, which
is not text any assembler could take.

Zero ambiguity on our side is partly by design — the printer and the parser are
one component and the byte gate depends on their being inverse. That is the
point: it is a property this tree needs and unidasm has no reason to have.

## 4. The three options, costed

### Option A — converge on unidasm syntax

**Cost:** the parser must learn 13,337 rejected spellings *and* the language
must gain a way to state address width, encoding form, operand size and omitted
implicit operands — none of which unidasm prints. At that point the result is
no longer unidasm syntax, it is unidasm syntax plus annotations, i.e. a third
syntax. Without those annotations, 246,857 sites silently assemble to the wrong
bytes and `make gate-all` goes red on every image.
**Benefit:** one vocabulary in the source and in the oracle's output; trailing
comments become redundant.
**Verdict: not viable as stated.** The blocker is not effort, it is that the
target notation cannot express what the bytes contain.

### Option B — converge on native LLVM mnemonics, teach unidasm nothing

Retire the synthetic mnemonics in favour of the real ones, with the form in the
operand: `lda_d16 xwa, (36914)` → `lda xwa, (0x9032:16)`.

**Cost:** 265,116 sites over 303 of 547 files, 459 names. Of those, 98 names /
22,135 sites are the raw-byte pseudo-instructions of §1.2(3) and need the
operand *modelled in the backend* before any rename is possible — that is
genuine backend work, and UPDATE 8's refusal to guess at `(xix+iz)` says it
should be done deliberately, not quickly.
**What is already paid:** UPDATE 7 proved 9,901 of 12,539 macro call sites
retireable byte-identically. `native_convergence.py` measures the mnemonic side
the same way and finds **81,858 sites across 71 tree mnemonics
(`ldb_d8` 17,406, `stdi8` 10,896, `stb_d8` 9,064, `ldw_d16` 8,948,
`stda16` 7,764, …) assemble to the ROM's exact bytes today** under the native
spelling with the width annotation and **no backend change at all**.
**Benefit:** fewer syntaxes, and the remaining one looks like LLVM. Every step
is certified by the byte gate — a rename that changes one byte is caught, which
makes this the rare mass edit whose safety is mechanically provable.
**Verdict: recommended, staged per mnemonic family.**

### Option C — stay divergent, document the mapping

**Cost:** near zero. `out/mnemonic_census.csv` and
`out/oracle_ab_reassembly.csv.gz` already *are* the mapping table, at 133,689
concrete (bytes, unidasm text, tree text) triples.
**Benefit:** no churn in 303 latin-1 files while a dozen lanes have uncommitted
work in them.
**Verdict: the correct fallback, and the correct thing to do for the 22,135
raw-byte sites specifically, until their operands are modelled.**

## 5. Does converging erode the oracle? Two different questions

This must not be answered as one question.

**Shared syntax does not erode it.** unidasm's value is that it is a *separate
implementation of the decode*, from MAME's own tables, with no stake in this
backend. Renaming our mnemonics changes nothing about that: the two decoders
stay two decoders, and §2's 1,113,485-site length agreement stays exactly the
independent check it is today. Option B does not touch MAME at all.

**Shared decode would destroy it, and there is a real way to slip into it.**
If the tree's source were ever mass-rewritten *from* unidasm's output, the
tree's framing would inherit unidasm's decode, and every later "unidasm agrees"
would be unidasm agreeing with itself. This project has been burned by exactly
this shape — the brief's "a test whose subject includes the tester". So:

> **Rename by a mnemonic-to-mnemonic mapping, verified by the byte gate. Never
> by replacing a source line with unidasm's text.** The current practice —
> unidasm's own rendering carried in a trailing comment for eyeball comparison
> — is right and should stay.

**"The other way around" — teaching unidasm this tree's syntax** — is a change
to a disassembler shared by all of MAME, replacing Toshiba's published
mnemonics with names invented here. It would not be accepted upstream, it would
make unidasm worse for everyone else, and it buys this project nothing that
Option B does not.

## 6. Findings handed back separately

### 6.1 Two opcodes this backend decodes that MAME's tables leave undefined

Eight sites, four distinct byte patterns, found by unidasm printing `db` for
bytes this backend both assembles and disassembles
(`decoder_disagreements.py`):

| bytes | this tree writes | MAME `dasm900.cpp` | sites |
|---|---|---|---|
| `cb 13` | `exts c` | `mnemonic_c8[0x13]` = `M_DB` | `v10`+`v9` `audio/sound_editor_ui.s:11269` / `:11427` |
| `cf 13` | `exts l` | `mnemonic_c8[0x13]` = `M_DB` | `v10`+`v9` `audio/note_voice_mapping.s:17886` / `:18042` |
| `f0 63 08` | `call_dd8 99` | `mnemonic_f0[0x08]` = `M_DB` | `v10`+`v9` `audio/semenu_routines.s:4668` / `:4675` |

* **`EXTS8`** (`TLCS900InstrInfo.td:2360`, prefix `C8+r`, sub-opcode `0x13`)
  gives `exts` an 8-bit-register form. Toshiba defines EXTS for 16-bit
  (`D8+r`) and 32-bit (`E8+r`) only, and MAME's 8-bit table has nothing at
  `0x13`. It reads like the 16/32-bit definitions copied into the 8-bit table.
* **`CALL_DD8`** (`TLCS900InstrInfo.td:4325`, `[F0, addr8, 0x08]`) claims a
  `call (addr8)`; MAME's `F0` group has no entry at `0x08` at all (its CALLs
  live at `0xD0-0xDF`, as `call cc,(mem)`).

⚠ **Both mnemonics are almost certainly labelling data as code.** All six
distinct sites sit in regions that read as residue — the `exts c` site is
surrounded by `.byte 0xc4` / `zcf` / `nop` / `.byte 0xf1`, and the
`call_dd8 99` sites follow a `ret` and precede a bare `.byte 0x9f`. The bytes
are right either way (the gate is green), so this costs no ROM correctness —
but **a spurious decode in the 8-bit register table is precisely what lets a
linear disassembler walk through data and emit plausible-looking code**, which
makes `EXTS8` worth deleting on its own merits, not only for tidiness. Both
need adjudication against the Toshiba manual before anything is changed.

### 6.2 `jr` / `jrl` / `calr` take a displacement, not a target

Handed a bare number, this backend encodes it as the displacement: `jr 99832`
becomes `[0x68,0xf8]` — the operand's low byte, with no diagnostic. It only
ever meets labels in this tree, so nothing is wrong in the ROMs, but it is the
same shape as the truncations UPDATE 8 turned into errors, and it defeats any
attempt to detect PC-relative forms by re-assembling at a shifted origin.

## 7. What would change this recommendation

**One thing, and it is measurable.** If MAME's disassembler were changed to
print an *injective* rendering — the address width, the encoding form, the
operand size, the omitted implicit registers — then unidasm's text would become
a source language and Option A would become the right answer, since one
notation shared with the rest of MAME beats two.

The trigger is exact: re-run `oracle_ab.py`. **If `UNI_ASSEMBLES_DIFF` falls to
approximately zero, the argument flips.** Today it stands at 246,622 sites.

Two smaller things would also move it: if the 98 raw-byte pseudo-instructions
(22,135 sites) were given modelled operands, the residual difference between
the syntaxes would be pure cosmetics and worth settling on style alone — at
which point LLVM's conventions should win, per §1.3. And if a future lane finds
a `LEN_DIFFER` anywhere, the "they never disagree about the instruction"
premise in §2 needs re-examining before any of this is acted on.

## 8. Concretely, next

1. Do **not** open a conversion to unidasm syntax.
2. Take Option B one mnemonic family at a time, largest first: the 71 tree
   mnemonics in `out/native_convergence_fixed.csv` are already proven to
   assemble byte-identically under their native spelling. `ldb_d8` alone is
   17,406 sites in 170 files.
3. Patch those `.s` files with an explicit latin-1 read/write, and check the
   diff **size** against what was intended before committing — per the brief's
   2026-09-02 addendum.
4. Gate every family separately. A rename that changes one byte is a
   regression, and here the gate can prove it did not.
5. Leave the raw-byte pseudo-instructions alone until their operands are
   modelled in the backend, deliberately, with an encoding test each.
