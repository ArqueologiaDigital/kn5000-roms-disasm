#!/usr/bin/env python3
"""v10dac_apply_spans.py -- Rewrite one located span from instruction mnemonics back into typed data. ⚠ THIS WRITES.

RUN
    python3 scripts/converters/v10dac_apply_spans.py

⚠ A clean decode is NOT proof the bytes are code, and the byte-identity gate
  cannot help: re-assembling a wrong interpretation reproduces the same bytes.
  Corroborate with call targets landing on routines already named in the tree.

⚠ `--show-encoding`'s `encoding:` field is NOT reliably the bytes the
  disassembler consumed -- it can be a re-encode, shorter than the true
  consumed length. Summing shown-encoding lengths silently desyncs and then
  fabricates a PARTIAL DECODE for everything downstream; that produced a
  phantom 407-byte "decoder gap" which was retracted on 2026-09-02. Verify per
  instruction against the true byte slice.

PROVENANCE
  Lane V10DAC of the 2026-09-02 push; recovered from session scratch,
  which is volatile, before it was lost.
"""
import json, os, sys, collections

REPO = os.path.expanduser("~/compartilhado/disasm-lanes/v10dac")
BASE = 0xE00000
SCRATCH = "/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad"

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
plan = json.load(open(os.path.join(SCRATCH, "span_plan.json")))
try:
    report_rows = json.load(open(os.path.join(SCRATCH, "report_rows.json")))
except Exception:
    report_rows = {}

ok = [r for r in plan if r["file"]]
print(f"{len(ok)} located spans, {sum(r['b']-r['a'] for r in ok):,} B")

byfile = collections.defaultdict(list)
for r in ok:
    byfile[r["file"]].append(r)

WRITE = "--write" in sys.argv

def fmt_bytes(raw, indent="\t"):
    lines = []
    for i in range(0, len(raw), 12):
        chunk = raw[i:i+12]
        lines.append(indent + ".byte " + ", ".join(f"0x{b:02x}" for b in chunk))
    return lines

total_bytes = 0
total_spans = 0
converted_list = []

for fn, spans in byfile.items():
    spans.sort(key=lambda r: r["l0"])
    # verify no overlap (defensive)
    for i in range(1, len(spans)):
        assert spans[i]["l0"] > spans[i-1]["l1"], f"overlap in {fn}"
    lines = open(fn, encoding="utf-8", errors="surrogateescape").read().split("\n")
    orig_len = len(lines)
    # apply bottom-up
    for r in sorted(spans, key=lambda r: -r["l0"]):
        a, b, l0, l1 = r["a"], r["b"], r["l0"], r["l1"]
        raw = rom[a:b]
        key = f"{a}_{b}"
        meta = report_rows.get(key, {})
        header = (f"\t; data-as-code (v10_data_as_code_census.py, STRICT rule): "
                  f"0x{BASE+a:06X}-0x{BASE+b:06X} ({b-a} B), unreached CODE-territory, "
                  f"was disassembled as {l1-l0+1} plausible-but-dead instruction lines; "
                  f"per={meta.get('per','?')}% dist={meta.get('dist','?')} "
                  f"near {meta.get('loc','?')}")
        block = [header] + fmt_bytes(raw)
        lines[l0:l1+1] = block
        total_bytes += (b - a)
        total_spans += 1
        converted_list.append((fn, a, b))
    if WRITE:
        open(fn, "w", encoding="utf-8", errors="surrogateescape").write("\n".join(lines))
        print(f"WROTE {fn}: {len(spans)} spans, {orig_len} -> {len(lines)} lines")
    else:
        print(f"[dry-run] {fn}: {len(spans)} spans")

print(f"\nTOTAL: {total_spans} spans, {total_bytes:,} B" + (" -- WRITTEN" if WRITE else " -- DRY RUN, pass --write to apply"))
json.dump(converted_list, open(os.path.join(SCRATCH, "converted_list.json"), "w"), indent=1)
