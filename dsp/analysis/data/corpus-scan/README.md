# `data/corpus-scan/` — is there a THIRD µPD6383 corpus among the dumped ROMs?

| file | what question it answers | how to regenerate |
|---|---|---|
| `scan-2026-09-14.txt` | **Which dumped ROMs carry µPD6383 host streams?** 56 files, six products. Exactly one other product does: the **KN1500**, 9 streams in IC15 at `0x1A414D..0x1AC18B`. kn2400/kn6000/kn6500/kn7000 and the 20 non-subprogram kn5000 ROMs (the negative control) carry **zero**. | `./dsp/tools/dsp_corpus_scan_all.sh OUTDIR` |
| `kn1500-2026-09-14.txt` | **The KN1500 pool itself**: 37 streams, 31 distinct op-3 blocks, 2389 words, 175 distinct words new to the project. Bodies at I-RAM `0x50` and `0xD0`, a 41-word kernel header at `0x0000` whose first eight words are byte-identical to the KN5000's. | `python3 dsp/tools/dsp_corpus_scan.py --rom <the kn1500 ic15 file>` |
| `control-2026-09-14.txt` | **Is the detector any good, and can it BUILD a corpus?** Two different questions. Offset recall against the KN5000 Sub CPU's own pointer table **plus the kernel header and epilogue** (which no algorithm pointer points at): 38 of 41 covered (93 %), **37 exact (90 %)**. Extraction quality: op-3 **block recall 39 of 42 (93 %)**, **word recall 3034 of 3237 (94 %)**, **precision 39 of 41 (95 %)**. ⚠ Earlier figures of 51 %/68 %/72 %/90 % were limited by an *assumed* opcode alphabet and scored against a truth set that omitted the kernel — see §206. | `python3 dsp/tools/dsp_corpus_scan.py --control` |

## What the numbers mean

* **Good enough to extract with, not good enough to publish a rate from.** 93 % block recall and
  95 % precision will build a working corpus; grade it against the product's own directory
  structures where those are known, the way `wsa1/dsp/analysis/gen_wsa1_dsp_disasm.py` does.
* **The opcode alphabet is `{3, D, E, F}`**, measured over the KN5000's 100 program streams
  (op-3 ×96, op-D ×9, op-E ×4, op-F ×100). `{0,1,2,5}` belong to the *coefficient* streams behind
  the other pointer table. Assuming the wrong alphabet is what held recall at 51 %.
* **No decode rate may be quoted from this scan.** It keeps streams whose words are already in the
  known ISA vocabulary, so the recovered set is *selected* for vocabulary match and its decode rate
  follows the threshold: `0.90 → 92.4 %`, `0.70 → 85.3 %`, `0.50 → 52.3 %`, `0.00 → 2.7 %`.
  `dsp_corpus_scan.py --bias` prints that curve. A "+1.09 pooled points" figure computed from the
  top row was retracted the same session (§205).
* **The chip is confirmed by hardware testimony**, not only by this scan: Felipe reported a
  **D6383GF-3BA at IC3** on the KN1500 *after* the scan found the microcode. Service manual
  `KN7000/service_manual/technics_sx-kn1500_sm.pdf` — image-only, render it, never grep it.
* ⚠ IC15 is recorded elsewhere as a **likely BAD_DUMP**. The microcode region parses at 0.97–0.99
  vocabulary match so it looks intact, but any extraction must be graded against that.

Full write-up: `dsp/analysis/N-INPUT-GATE-OPENED-2026-09-12.md` §204–§205; LEDGER §386–§388.
