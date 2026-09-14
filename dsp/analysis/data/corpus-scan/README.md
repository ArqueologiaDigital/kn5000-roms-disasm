# `data/corpus-scan/` — is there a THIRD µPD6383 corpus among the dumped ROMs?

| file | what question it answers | how to regenerate |
|---|---|---|
| `scan-2026-09-14.txt` | **Which dumped ROMs carry µPD6383 host streams?** 56 files, six products. Exactly one other product does: the **KN1500**, 9 streams in IC15 at `0x1A414D..0x1AC18B`. kn2400/kn6000/kn6500/kn7000 and the 20 non-subprogram kn5000 ROMs (the negative control) carry **zero**. | `./dsp/tools/dsp_corpus_scan_all.sh OUTDIR` |
| `control-2026-09-14.txt` | **Is the detector any good, and can it BUILD a corpus?** Two different questions. Offset recall against the KN5000 Sub CPU's own 100-entry pointer table: 38 of 41 covered (93 %), 21 exact (51 %), shuffled null 0. Extraction quality: op-3 **block recall 27 of 40 (68 %)**, **word recall 2275 of 3154 (72 %)**, **precision 27 of 30 (90 %)**. | `python3 dsp/tools/dsp_corpus_scan.py --control` |

## What the numbers mean

* **A hit is a discovery, not a corpus.** 68 % block recall and 90 % precision would drop a quarter
  of a product's microcode and admit three blocks that are not microcode. Extract through the
  product's own directory structures, the way `wsa1/dsp/analysis/gen_wsa1_dsp_disasm.py` does.
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
