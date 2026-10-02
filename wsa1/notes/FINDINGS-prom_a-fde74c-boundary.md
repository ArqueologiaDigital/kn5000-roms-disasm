# prom_a 0xFDE74C-0xFDFFDF: CONVERTED 2026-09-02, on external call-target
# corroboration instead of a fifth walk-plausibility argument

**Status: this was the largest single item of remaining prom_a debt (6,321 B
at 0xFDE74C-0xFE0000), refused across three prior rounds
(`gen_prom_a_cover_round1.py`, `gen_prom_a_cover_round2.py`, and a round 3 not
separately documented) each time on "0 bytes STRONGLY reachable" from
`notes/reachability.py`.** That is still true after this pass -- nothing in
prom_a's own control-flow graph names this span. What changed is that this
pass found evidence OUTSIDE the walk, following the method that closed
0xFC4000-0xFC52F8 (`FINDINGS-prom_a-fc4000-boundary.md`): eliminate routes with
evidence, and require hits to land ON a boundary derived independently, not
merely "in range".

Converter: `notes/gen_prom_a_fde74c_module.py` (`--check` re-derives and
asserts every number in this note; `--emit-head`/`--emit-body` produce the
assembly spliced into `prom_a/wsa1_prom_a.s`). Gate: `make gate-wsa1`, green.

## The three-way split

```
0xFDE74C-0xFDE75D      17 B  sub_FDE74C          falls through into sub_FDE74C_Skip (already converted)
0xFDE760-0xFDFFDF   6,271 B  sub_FDE760...       CONVERTED, coverage only, sub_XXXXXX labels
0xFDFFDF-0xFE0000      33 B  (unnamed)           REFUSED, left `.incbin`
```

17 + 6,271 + 33 = 6,321 = `0xFE0000 - 0xFDE74C`.

## Why "0 undecodable bytes" was not enough

`python3 notes/prom_a_linear_decode_check.py 0xFDE74C 0xFE0000` reports **zero**
undecodable bytes over 2,458 instructions, yet **fails** test 2: `0xFE0000` is
not an instruction boundary of that decode (nearby candidates land at
`...FA`, `...FC`, `0xFE0002`, `0xFE0004`, `0xFE0008`, none of them right). A
TLCS-900 decode is dense enough that this is not sufficient on its own --
`FINDINGS-prom_a-fcf000-module.md` already proved the same thing about the
exact same tail: of 128 possible decode starts in `0xFDFF80-0xFDFFFF`, only
two make `0xFE0000` a boundary. "It decodes without error" and "it is
correct" are different claims; only the second is worth converting on.

Cutting the span at `0xFDFFDF` instead of `0xFE0000` makes both segments
independently self-consistent
(`python3 notes/prom_a_linear_decode_check.py 0xFDE74C 0xFDFFDF`: 0 db,
end is a boundary). `0xFDFFDF` is not a fitted number: the instruction
immediately before it is `unlk XIZ` / `ret` (bytes `ee 0d 0e`, at
`0xFDFFDC`) -- the single most common function epilogue in this exact span,
closing dozens of routines throughout `0xFDE74C-0xFDFFDE`. Continuing the
SAME linear decode past that `ret`, without restarting it, immediately drifts:
`ld (0x04),0x1d` / `push WA` / `call NC,XIY+0xfd` / `jr F,0xfdffd7` /
`jr PE/OV,0xfdffc2` / `srl A,L` -- condition codes (`F`, `PE/OV`) and operand
shapes that do not occur anywhere else in the 6,271 bytes above it. That is
the signature of genuinely different bytes, not a decoder resync artefact:
resync typically recovers within a couple of instructions
(`prom_a_linear_decode_check.py`'s own docstring), and this one does not
recover at all before `0xFE0000`.

## The external corroboration: 64/64 call/calr targets, three independent sources

Every `call`/`calr` target that appears inside the proposed code
(`0xFDE74C-0xFDFFDF`) was extracted and checked against material this pass did
not produce:

| source | targets | what it proves |
|---|---:|---|
| independently certified `0xFCFDA7-0xFDE70F` module (177/177 directory-slot hits, `FINDINGS-prom_a-fcf000-module.md`) | 45 | these calls land on real instruction starts of a decode this pass never touched |
| the same module's own already-documented "1-2 bytes past a boundary" artefact (`0xFD61E9`, `0xFD6FEE`, `0xFD763E`) | 3 | **word for word** the same three addresses that file reported when IT tried extending its OWN decode past `0xFDE70F` -- written before this pass ran, from a decode started 4 KB away at `0xFCFDA7`. Two decodes with different starting points landing on identical call targets, including the identical off-by-a-few-bytes quirk, is not something a resync coincidence reproduces |
| this span's own internal `calr` targets | 15 | self-consistency of the proposed decode (the dispatcher calls its own helper routines further down, e.g. `0xFDE770 calr 0xfde784` into `0xFDE784`) |
| `0xF41ED4` = `T_Dispatch_Code80` in `prom_b/wsa1_prom_b.s` (`jp 0xF5B9B8`), already named, reached by 109 OTHER opcode-anchored references in the tree | 1 | a target neither decode manufactured: it was named before this pass ever looked at `0xFDE74C` |

**64 distinct targets, 64 resolved.** Not "in range" -- exactly ON a boundary
of one of the three independent sources above, in every case.
`notes/gen_prom_a_fde74c_module.py --check` re-derives this count from the ROM
and the two source files every time it runs.

## What is still NOT claimed

`reachability.py` still reports **zero** STRONG-reachable bytes in the whole
span -- no seed in prom_a's own graph reaches `0xFDE74C`. The call-target
corroboration answers "is this really code", not "when does the CPU run it".
What the code DOES is unnamed throughout: every label is `sub_XXXXXX` or a
local `.LXXXXXX`, an address, not a claim.

## The 33-byte tail, 0xFDFFDF-0xFE0000: refused, not merely unattempted

Two routes were tried and eliminated:

* **Literal decode continuation** from `0xFDFFDF` was already shown above to
  never resynchronise before `0xFE0000` -- ruling out "this is more of the
  same code, just misread from here".
* **The exhaustive tail sweep**, already on record in
  `notes/prom_a_fcf000_checks.py --tail` from 2026-08-25 (before this pass):
  of the 128 possible decode starts in `0xFDFF80-0xFDFFFF`, only `0xFDFFFD`
  and `0xFDFFFF` make `0xFE0000` a boundary. Neither is a clean landing on its
  own merits: `0xFDFFFD`'s first instruction disassembles as `mul ??,W` --
  unidasm printing an unresolved register operand, not a well-formed
  instruction. Nothing pins which candidate (if either) is where real content
  resumes, and no start in between decodes self-consistently to either one.

No reader, stored extent, inbound pointer, or byte-value stride was found for
these 33 bytes. They are reproduced as the same `.incbin` they already were,
narrowed, with the evidence above recorded as a comment immediately above the
directive in `prom_a/wsa1_prom_a.s`.

## Byte accounting

17 (`sub_FDE74C`) + 6,271 (`sub_FDE760`...) + 33 (refused tail) = 6,321 =
`0xFE0000 - 0xFDE74C`, matching the `.incbin` this pass replaced.
