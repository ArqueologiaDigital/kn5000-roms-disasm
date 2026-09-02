# DATA-AS-CODE audit, the last 7 images (lane DATACODEREST, 2026-09-02)

**Question this answers:** how much of v9, v7, the subcpu v1.42 payload, the
subcpu boot ROM (IC30), table_data, custom_data (IC19) and HD-AE5000 is the
THIRD kind of debt named in `notes/DEBT-INVENTORY-2026-09-02.md` — data
disassembled into plausible instruction mnemonics, invisible to
`.byte`/`.incbin` scanners and to the byte-identity gate (re-assembling a
wrong interpretation reproduces the same bytes)? v10 and all four WSA1R
images already had this measured
(`scripts/analysis/v10_data_as_code_census.py`,
`wsa1/notes/data_as_code_audit.py`); these seven did not. Until this lane ran,
every remaining-debt figure in the project was a stated LOWER BOUND because
of that gap.

**Tool:** `scripts/analysis/kn5000_rest_data_as_code_audit.py` (this
directory holds only notes; the script is the committed artefact, and it has
no cache file — each run re-flattens with `llvm-mc`, a few seconds per
image).

**Method, in one paragraph:** flatten each image with
`llvm-mc -triple=tlcs900 -show-encoding` (the same authority the byte gate
itself uses) to get one address per byte and the exact source mnemonic text;
group instruction addresses into maximal CODE regions; build one reference
index of every resolved branch/call target and every literal/`.word` that
lands inside a group's own address range (v9, v7, table_data, custom_data and
HD-AE5000 are each their own group; the subcpu payload and the subcpu boot
ROM share one group, "SUBCPU", because the boot ROM's own source literally
`call`s the payload's entry point at 0x400 — see the script's module
docstring for the full argument and the WSA1 precedent it is ported from);
ask whether each CODE region's start is ever the target of a real control
transfer; score the unreached ones with two signals computed from the RAW
ROM BYTES (ASCII-printability, best-period byte tiling), both gated against a
dominant-byte-ratio guard (a repeated NOP/00 delay-padding run is not a
record table).

**Run:**

    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --build      # once, builds all 7 ELFs
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --verify     # byte-identity vs original_ROMs/
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --report     # the findings, per image, with the top candidates
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --null       # the false-positive control (signals over REACHED code)
    python3 scripts/analysis/kn5000_rest_data_as_code_audit.py --selftest   # detector self-checks, incl. the two HD-AE5000 calibration cases

See `notes/datacoderest-audit/FINDINGS-2026-09-02.md` for the actual numbers
from the run this lane made, and `notes/DEBT-INVENTORY-2026-09-02.md`'s own
entry for the tree-wide status after this lane's pass.
