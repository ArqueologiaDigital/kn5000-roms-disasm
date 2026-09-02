# Backend lane: modelling the operands behind the raw-byte pseudo-instructions

**2026-09-02, lane `w16/conv-backend`.** One commit in `llvm-project`
(`86332721969d`, on top of `7e541b8ddb07`); three committed probes in this tree.

The assignment came out of
`notes/ASSESSMENT-syntax-convergence-2026-09-02.md` **class 3**: 98 mnemonics
over **22,135 sites** whose operands are literal bytes —
`lda_dri xix, 7, 236, 232`, `link32 238, 12, 248, 255` — which no rename can
reach, because the addressing mode was never modelled. Two of the three lanes
renaming class 1 could proceed without a backend; this one could not.

## What was modelled

**`(Xrr+Rn)`, the register-indexed operand.** `TOOLCHAIN_VERSION` UPDATE 8
records that `ld wa,(xix+iz)` was being read as `(Xrr+d16)` with the index
register **swallowed as an undefined symbol** — `d3 f1 00 00 20` where the ROM
has `d3 07 f0 f8 20` — and that this was deliberately turned into a
**diagnostic rather than a guess**. It is now a distinct operand KIND in the
parser, so an index register can no longer reach the displacement slot at all:
the confusion is *impossible* rather than *diagnosed*, and the refusal is gone.
Three index flavours, because the register-file address the encoder writes
differs for each — current-bank word (`(xbc+wa)`), previous-bank word
(`(xwa+qiz)`), and the eight byte halves of WA/BC/DE/HL (`(xbc+w)`).

**Memory-to-memory, `ld (mem),(nn)` and `ld (nn),(mem)`.** One
register-indirect operand and one 16-bit direct address — the single largest
remaining decoder refusal, 274 of the 294 samples in the v10 sub-opcode census
(`notes/lanes/llvmalumem-2026-09-02.md`). That lane refused to decode them to
the existing raw-byte escapes because doing so *"would round-trip and convey
nothing"*, which was right: the escapes name the wrong instruction.

> ⚠ **`ldmi16` and `ldmw2` are semantically wrong and stay bit-for-bit as they
> are.** Destination sub-opcodes 0x14 and 0x16 are not store-immediate:
> unidasm reads `b0 14 38 8d` as `ld (XWA),(0x8d38)`, a move whose trailing
> field is an *address*. The real store-immediate is 0x00 (byte) and 0x02
> (word). Nothing was re-encoded — 670 committed sites write the old
> spellings — but the correct instruction now exists and is what the
> disassembler prints.

## Numbers, and what produced them

All at `tlcs900_backend@86332721969d`. A decode figure is a property of the
build; do not compare these across a relink.

| probe | question | result |
|---|---|---|
| `scripts/analysis/regindexed_convergence.py` | of the register-indexed families, how many sites assemble byte-identically under the modelled spelling? | **12,063 of 12,172**, 0 refused, 0 unexplained differences |
| `scripts/analysis/rawbyte_decode_convergence.py` | of ALL 22,136 class-3 sites, how many now decode to a modelled-operand spelling that re-assembles to the ROM's bytes and that unidasm agrees with? | **18,485** corroborated by unidasm, **+1,280** whose only difference from unidasm is this tree's own synthetic NAME — see below |
| `scripts/analysis/memtomem_test_sites.py` | the memory-to-memory sites, with every decode re-assembled | **763 sites, 290 distinct byte strings, 12 shapes, 0 unidasm disagreements** |
| `scripts/analysis/unidasm_bytes.py` | what does the independent decoder call these bytes? | the oracle behind every naming claim here |

### The class-3 total, split so nothing is folded into it

    CONVERTIBLE           18485   operand modelled, bytes round-trip, unidasm
                                  names the same operation
    UNIDASM_OP_DIFFERS     1280   operand modelled, bytes round-trip, but the
                                  name is one of this tree's synthetic ones
    DECODE_REFUSED         1285   no decode at all -- the R+R immediate/bit/ALU
                                  sub-opcodes, listed by mnemonic in the output
    STILL_RAW_BYTES         979   decodes to itself: the ERP register-code
                                  families, which have no register to name
    ASYMMETRIC              107   decodes, but does not re-assemble: the
                                  `(Xrr+256)` sentinel, every one of them

So **19,765 of 22,136 sites (89.3%) now have a modelled operand** whose text
gives the ROM's bytes back; 18,485 of those also carry a name an independent
decoder corroborates, and the remaining 1,280 are class 1's renaming problem,
not class 3's.

⚠ **The 1,280 are listed pair by pair in the census output and none of them is
an operation disagreement** — `pushm` vs `pushw`, `andmi16` vs `and`, `bitm`
vs `bit`, `incm` vs `incw`, `ldir85` vs `ldir`, 28 pairs in all. They are
printed in full and deliberately *not* absorbed by a permissive name rule: a
rule loose enough to fold `andmi16` into `and` is loose enough to fold an ADD
called SUB into an ADD, and that is the one thing the second decoder is here
to catch.

★ **`regindexed_convergence.py`'s first run scored 571 sites as "bytes differ",
and every one was a defect in the PROBE** — it wrote the `(Xrr+d16)`
displacement unsigned, and `llvm-mc` refuses an operand that fits its field
neither signed nor unsigned. That is the probe catching itself, which is the
only reason to write the byte comparison rather than assume it.

## Three decoder defects found, all of them wrong-answer rather than refusal

A refusal count cannot see any of these.

* **LDA with an 8-bit index** fell out of the R+R decoder. `f3 03 f4 e0 35` —
  `lda XIY,XIY+A` in unidasm, a real v7 site at
  `sequencer/rhythm_routines.s:461` — came back as **three** instructions,
  `<unknown>` + `pop sr` + `st_dpdb e, 224`. Five bytes read as 1 + 1 + 3.
* **A previous-bank index on the load and store sides** was refused with the
  comment *"no previous-bank source form exists"*. It exists: `c3 07 e0 fa 21`
  is `ld A,(XWA+QIZ)`, and three `hdae5000` sites carry unidasm's rendering in
  a trailing comment already. 19 sites in five images.
* **`CALL cc,(base+idx)` is sub-opcode `0xE0|cc`, not `0x08|cc`.** unidasm
  prints `db` for every byte of 0x08–0x17 under this prefix and
  `call T,XBC+WA` for 0xE8; `mem_prefix_test_sites.py` had already recorded the
  destination table's CALL range as 0xE0–0xEF. The wrong range also swallowed
  0x14 and 0x16 — reading the **seven**-byte memory-to-memory move as a
  **five**-byte CALL, which is where UPDATE 13's 16 `ldmm_dri` length errors
  came from. `call_rr`'s own encoding is untouched; no committed source writes
  it.

## ★ The near miss, and the rule it earns

The memory-to-memory address operand was first given the existing `directaddr`
class. That class answers true to a **bare immediate**, because that is what
its parser leaves behind — so `ldw (xwa), 36152`, a store-immediate written in
hundreds of places, immediately started matching `ldw (mem),(nn)` and moved
from `b0 02 38 8d` to `b0 16 38 8d`, **silently**. It was caught by a guard
line in the new lit test, not by reasoning.

> **Adding an operand class is exactly as dangerous as changing an encoding,
> when the new class overlaps an old one.** A form whose operand must be an
> ADDRESS has to reject a VALUE. `daddr16` requires the parentheses, and
> `mem-to-mem.s` pins four store-immediate spellings against exactly this.

## Refused, with the evidence

* **`(Xrr+256)` cannot be written.** `d3 f9 00 01 19 04 04` is
  `ldw (0x0404),(XIZ+0x0100)`; it decodes correctly and unidasm agrees, but the
  line cannot be re-assembled, because **256 is the assembler's sentinel for
  "force the 2-byte (Xrr+d8) form with displacement 0"** (`63ff7d92fb5f`). The
  sentinel steals a legal displacement; the 65536 sentinel one width up does
  not, being outside the field. **103 register-indexed sites and 3
  memory-to-memory sites** hit it. All are already raw bytes in the tree, so
  nothing is *wrong* today — what is missing is a spelling. Not patched here:
  1,132 committed sites depend on the sentinel's current meaning, and
  `notes/TRIAGE-size-form-mnemonics-2026-09-02.md` proposes retiring it through
  the same `:width` idiom, which is the right place to settle it.
* **A bank-relative base register.** `f3 39 01 00 55` is
  `ld (XDE3+0x0001),IY` — base register-file address 0x38, the XDE of bank 3,
  neither the current bank nor the previous one. This backend has `GPR` and
  `PrevGR16` and no way to name a third bank. 6 `stw_dri` sites.
* **The R+R table's immediate, bit and ALU sub-opcodes** — `stib_ind`,
  `stiw_ind`, `bit_dri`, `cpib_sri`, `add_sril_rm` and relatives. The operand
  half is now modelled; what these need is the instruction definitions on top
  of it (`ld (xhl+bc), 0xff`, `bit 3, (xhl+bc)`, `add xix, (xhl+de)`). This is
  the natural next chunk and is named in the census output by mnemonic.
* **The ERP register-code families** — `inc1b_erp` and relatives, which decode
  to themselves because the operand is a Toshiba *register code byte* with no
  register to name. That is feature C of
  `notes/TRIAGE-size-form-mnemonics-2026-09-02.md` (a `PrevGR8` class), not
  this lane.

## Reproducing

    python3 scripts/analysis/regindexed_convergence.py --selftest
    python3 scripts/analysis/regindexed_convergence.py            # the 12,172
    python3 scripts/analysis/regindexed_convergence.py --emit     # the lit test
    python3 scripts/analysis/rawbyte_decode_convergence.py --selftest
    python3 scripts/analysis/rawbyte_decode_convergence.py        # all 22,136
    python3 scripts/analysis/rawbyte_decode_convergence.py --list # the work list
    python3 scripts/analysis/memtomem_test_sites.py
    python3 scripts/analysis/unidasm_bytes.py 'f3 07 e4 e0 e8'

Each `--selftest` pins its verdict rule on **synthetic** input, so that a change
to the tree cannot make it pass or fail for the wrong reason, and each carries a
foil that must fail.
