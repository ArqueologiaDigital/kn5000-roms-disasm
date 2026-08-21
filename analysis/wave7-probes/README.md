# Wave 7 verification probes

Read-only scripts written by the Wave 7 annotation workers (2026-08-21) to check their claims
against the ROMs and the source before those claims were proposed as header comments. They are kept
because every number in Wave 7's annotations should be re-derivable, and because a header comment
that cannot be re-checked is the failure mode this project has been bitten by repeatedly.

| script | question it answers |
|---|---|
| `probe_set_descriptors.py` | Re-derives every number quoted in the multisample SET descriptor / envelope-descriptor header comments, from `table_data`. |
| `setprobe.py` | The same region, exploratory: record stride and field offsets from the raw bytes. |
| `verify.py` | IC307 wave-directory format: does every parameter record's head word equal its own PCM offset? (the self-check the format carries) |
| `verify_hdae5000_ui_pool.py` | The HD-AE5000 UI descriptor pool at 0x29DC12-0x2A5D2B: true record stride, and whether the current five-way split falls mid-record. |
| `chk.py` | Cross-checks the HD-AE5000 init-data pointer tables against the source. |
| `anchors.py` | Checks that every anchor string a package proposes to match is UNIQUE in its target file -- the mechanical precondition for applying a package safely. |
| `enc.py`, `enc2.py` | Encoding audit of the v142 source: finds non-ASCII bytes and the lines carrying them. |
| `align_packages.py` | Which critique reviewed which package? Pairs them from the workflow's return value. |
| `apply_package.py` | Applies one vetted edit list, aborting unless every anchor is unique. |

All are read-only and most take no arguments: `python3 <script>`. Paths are hardcoded.

⚠ `anchors.py` is the one to run BEFORE applying any package. An anchor that matches twice, or that
has drifted because an earlier package edited the same region, is how a mechanical apply corrupts a
file that otherwise rebuilds byte-for-byte.

## Integrating a package

`align_packages.py` exists because the workflow journal lists results in COMPLETION order, so
zipping packages against critiques read from the journal pairs each package with someone else's
review. The workflow's return value keeps the two arrays aligned by position; that is the authority.

The integration loop, per package, is:

1. read the package's OWN critique and verify its findings against the ROM and the source --
   the critiques have caught real false claims, and have also raised false alarms;
2. correct the package's text rather than dropping it, wherever the evidence supports a narrower
   statement;
3. `python3 apply_package.py pkgN_fixed.json --dry` to check anchors, then apply;
4. `make clean-all && make all`, and READ the result -- 9/9 at `Similarity: 100.00%`;
5. only then commit, with the `LLVM:` version line the hook requires.

⚠ Two classes of critique finding are known to be spurious, because the critique prompt truncated
anchors to 300 and replacements to 1500 characters: "the anchor is truncated" and "the replacement
would delete code". Judge those from the package JSON itself. A replacement that rewrites a comment
block and ends with the anchor's label line is correct and complete.
