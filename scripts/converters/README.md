
## `convert_region.py`

**Question:** does this one pre-vetted `.byte` block decode as real TLCS-900
code, and what are the instructions? Dry run by default; `--apply` writes, to
the v9 and v10 copies together after asserting their bytes match.

    python3 scripts/converters/convert_region.py <relpath> <start_line> <size>

⚠ Anchors on a 1-indexed line number, which goes stale as soon as an earlier
block in the same file is converted. The size assert is the only guard; read
the dry run before applying. ⚠ A clean decode is a candidate, not a verdict —
data decodes as plausible instructions in this ROM family, and the byte gate
cannot tell the difference.
