# claims_lint.py -- do the claims in comments hold? (built and verified 2026-10-02)

`scripts/analysis/claims_lint.py` checks, mechanically and tree-wide, five kinds of claim that
the byte gate cannot see. They are the recurring failure patterns of the adversarial review of
Wave 2 (`notes/lanes/wave2-2026-09-25/claims-review/`).

| check | the question | a strong hit means |
|---|---|---|
| `stale-names` | Is a symbol-like name in a comment defined anywhere: an ELF symbol, a label / .set / .equ / macro, or a C identifier? | the comment names something that no longer exists. STALE-RENAMED: it is on the OLD side of a `scripts/renaming` map, with the NEW name given |
| `unread-claims` | Does a "no reader / unreferenced / purpose not established" header hold? | a pointer, a `pushw` hi/lo pair, a source reference, an immediate or a block copy reaches the range |
| `table-counts` | Does a stated count ("table of N pointers", "N x u32", ...) match the rows emitted? | the count and the rows disagree |
| `header-addrs` | Is a name quoted at an address where THIS image's ELF puts it? | wrong address; 272 of the 299 are v10/v9 addresses copied into v7 |
| `empty-templates` | Is a template slot ("what that code does with it:", "Purpose:", "Readers:") filled? | the generator left it empty |

Run: `python3 scripts/analysis/claims_lint.py [CHECK...] [--images LIST] [--out DIR]` (about
4 minutes over all 12 images; TSVs per check plus the summary on stdout). `--selftest` plants
one defect per check in a temp copy, plus negative controls, and must print PASS. `--explain`
prints each check's docstring.

## Precision (independent adversarial verification, `build_and_verification.json`)

The verifier hand-checked samples, fixed every false-hit pattern it found, and re-measured:

| check | before the fixes | after |
|---|---|---|
| stale-names | ~67 % (volume-weighted) | 92 % (46/50 uniform; 91/100 over two samples). Image-balanced 71 %: lower on the prose-heavy small images |
| unread-claims | 61 % | ~100 % (26/26 sampled; all 59 verified by family) |
| table-counts | 67 % | 100 % (6/6) |
| header-addrs | ~61 % | 100 % (40/40) |
| empty-templates | 94 % | 100 % (25/25 sampled, all 105 checked) |

Misses were probed by planting 3 realistic defects per check; after the fixes all were caught.
The weak tiers (WEAK-*) stay in the TSVs but are not counted.

## At fb30d288 (`summary-fb30d288.txt`)

Strong hits: stale-names 4,121 (313 of them STALE-RENAMED), unread-claims 59, table-counts 6,
header-addrs 299, empty-templates 105.

Of the stale names, about 30 per tree in `shared/event_codes.s` are firmware names quoted in
the event catalog's prose. Some are exact (`EV_SWON`), some mis-quoted (`EV_SW_ON`,
`EV_LSW_DATA`). A firmware name is not a symbol, so the check cannot tell a correct quotation
from a stale symbol; the mis-quotes should be fixed. 992 tabledata hits are one
generator-repeated stale name, `WaveSel_Bind_PartRecords`.

The workflow script is `claims-lint-build.js`.
