# PRE-REGISTRATION — §121: `hi12` bit 6 on a C-format word

Written and committed **before** the run. Arm: `UPD6383_HI6C=<mode>`, default 0 = off.
Harness: `dsp/tools/pslot_sweep.sh UPD6383_HI6C 0,1,...,11`.
Static evidence: `dsp/tools/kernel_homolog.py --all`, `dsp/tools/cfmt_opcode.py --all`.

## Why this bit, and why now

§120 reduced the LFO rate defect **and** the audio input path to one word — KN5000 kernel
`iw40 = 0C4A1C0820` — and asked *"what does `w40` **drive** `P` with?"*. The static KN5000 corpus
cannot answer: `cfmt_opcode.py --control` measures that in this ROM the C-format opcode is a
**function of (destination, payload)**, so nothing separates them, and `--twins` finds **no**
minimal pair on the opcode field anywhere in the pooled corpus.

The second product supplies the missing half, and not as a coincidence:

> **`wsa1/dsp/disasm/struct_00_fd4093.dsm` — a WSA1R record the effect directory does not name —
> IS the KN5000 kernel header. 34 of its first 42 words are byte-identical and in order.**
> Control (`kernel_homolog.py --control`): every other image in either product, best **2**, mean
> **0.4**. 75.7× the mean and it beats the best unrelated image outright.

Every divergence between the two copies is a `lo12 = 0x820` word — `closure-pointer.md` item H's
exhaustive negative — and **four of the five keep their opcode across the products. The fifth does
not, and the fifth is §120's word.**

```
   KN  w40   0C4A1C0820   imm13 448    hi12 C4A  f31 5  bit6 1   ★ §120's word
   WSA w45   0C0A5E0820   imm13 1504   hi12 C0A  f31 5  bit6 0
   xor       0040420000   word bits 17, 22, 30 — 17 and 22 are INSIDE the 13-bit immediate
                          ⇒ outside the payload: bit 30 = `hi12` BIT 6, and nothing else
```

`c_opcode` is `hi12 >> 1` and its low three bits are `f31`; both words carry `f31 = 5`. So the
"opcode difference" **is** bit 6. The disassembler prints it `?6` — nothing has ever decoded it.
Pooled census: set on **391 of 445** C-format words (clear is the exception, 54) and on 134 of
7558 non-C-format. Among the 22 `lo12 = 0x820` words in both products it is set on exactly
**three**: KN `w29`, WSA `w34` (both opcode 0x621) and KN `w40` (0x625, a single occurrence).

## The menu (enumerate and eliminate, the shape §104–§106 used to close the store gate)

| mode | reading |
|---:|---|
| 0 | off — bit 6 unmodelled (**the control**) |
| 1 | `P ← 0` |
| 2 | `P ← acc` |
| 3 | `P ← accb` |
| 4 | `P ← mem[ptr]` |
| 5 | `P ← the 13-bit immediate` |
| 6 | `P ← the 8-bit payload A` |
| 7 | `acc ← 0` |
| 8 | `accb ← 0` |
| 9 | `P ← tempA` |
| 10 | `P ← tempB` |
| 11 | `P ← 0` **and** `acc ← 0` |

## Criteria, fixed in advance

* **C0 REACH (rule 15, first).** `hi6c` fired count must be ≈ 8 per frame: the kernel carries four
  bit-6-set C-format words (`w29`, `w40`, `w48`, `w56`) and the chorus body four more
  (`w12/w21/w53/w62`, all `0C4032044C`). §100 needed **three runs** to make one arm fire at the
  predicted *rate*; a non-zero count is not the count.
* **C1 LFO.** §228 rise census, mean step = **114** (ROM: `floor(0.5993 × 2²³/44100)`, anchored
  nine-fold in `lfo-ramp.md`). Default today: 15543.9286.
* **C2 HAND-OFF.** §176 D-RAM census cell `0x05` present and wide — at the true default
  `177684(-2869494..3486228/chg175660)`.
* **C3 POSITIVE CONTROL, and this one can fail.** Bit 6 is set at kernel `w29/w40/w48/w56`, and
  §120 measured `w29/w48/w56` **inert** under a clear. ⇒ **mode 1 must reproduce `PCLRIW=40`
  exactly**: LFO `114.2560`, hand-off ABSENT. If it does not, the arm is not firing where the
  code comment says it is and every other row is void.

## Outcomes, named in advance

* **U1** — some mode passes **C1 and C2 together**. ⇒ a decode candidate for `hi12` bit 6, and the
  first reading that satisfies both of §120's consumers. It would still need the full two-sided
  gate (`pair_gate.sh`) and a catalogue regression before promotion.
* **U2** — only mode 1 (and 11) pass C1, losing C2, i.e. the menu reproduces §120 and adds
  nothing. ⇒ bit 6 acts on the product, but the hand-off's supply is a *different* word, and §120's
  "one word serves both consumers" is refined to "one word breaks both consumers".
* **U3** — nothing passes C1. ⇒ bit 6 does not act on the datapath registers at all. The pair
  stands as a static fact and the LFO defect is not in `P`. **This is a real possible outcome and
  the reading is abandoned if it happens** — §111's boundary (*one program's null does not
  generalise*) cuts the other way too: one product's spelling difference is not a decode.
* **U4** — C0 fails. The run says nothing; fix the siting and re-run, as §100 did twice.

⚠ **What would NOT count.** A mode that passes C1 by starving the machine. §34 proved the ramp
criterion cannot fail in the way that matters when the product is emptied, which is why C2 is
scored at the same setting and why C3 exists.

⚠ **And the WSA1R caveat stands.** The homology is measured on *bytes*; nothing here has run a
WSA1R program in the emulator. A criterion validated on KN5000 programs is not transferred to that
product by this note.
