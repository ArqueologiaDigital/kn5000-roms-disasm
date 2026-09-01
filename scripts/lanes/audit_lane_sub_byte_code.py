#!/usr/bin/env python3
"""audit_lane_sub_byte_code.py -- does the subcpu 100% claim survive falsification?

QUESTION IT ANSWERS
    kn5000_source_coverage.py reports "subcpu payload v142" and "subcpu boot
    (IC30)" at 100.0% source because it only subtracts `.incbin` bytes. It is
    blind to real TLCS-900 CODE that was emitted as `.byte` by the original
    ASL->LLVM converter and never converted to mnemonics -- exactly the failure
    mode that this project has already shipped once (8,496 bytes of sound code
    counted as "source" because the instrument only understood `.incbin`).

    This script finds every contiguous `.byte`-only run in the two images'
    sources, feeds each one through llvm-mc's disassembler, and reports:
      - how many bytes are in `.byte` runs at all (the ceiling on possible debt)
      - of those, how many the disassembler decodes CLEANLY (0 warnings) as a
        run of ordinary TLCS-900H mnemonics -- i.e. bytes that are almost
        certainly still-undisassembled CODE, not data.
    A block already flagged in a comment as data (lookup tables, parameter
    blocks, DSP-side bytecode consumed by a different chip) is not code by
    this test even if it happens to decode without warnings; the number this
    script produces is a ceiling that a human (or the accompanying manual
    survey in the lane report) must sanity check against context. It is a
    detector, not a verdict.

RUN
    python3 scripts/lanes/audit_lane_sub_byte_code.py v142/subcpu subcpu/boot
"""
import glob, os, re, subprocess, sys

LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

BYTE_LINE = re.compile(r'^\s*\.byte\s+(.+)$')
BYTE_VAL = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:')


def blocks_in_file(path):
    lines = open(path, encoding="latin-1").readlines()
    blocks = []
    cur = None
    cur_label = None
    for i, line in enumerate(lines):
        lm = LABEL_RE.match(line.strip())
        if lm:
            cur_label = lm.group(1)
            continue
        m = BYTE_LINE.match(line)
        if m:
            vals = [int(v, 16) for v in BYTE_VAL.findall(m.group(1))]
            if cur is None:
                cur = {"file": path, "start": i + 1, "label": cur_label, "bytes": []}
            cur["bytes"].extend(vals)
            cur["end"] = i + 1
            continue
        if cur is not None:
            blocks.append(cur)
            cur = None
        if line.strip():
            cur_label = None
    if cur is not None:
        blocks.append(cur)
    return blocks


def disasm_clean(raw_bytes):
    """True if llvm-mc decodes the WHOLE run with zero warnings/errors."""
    if len(raw_bytes) < 3:
        return False, 0
    hexin = " ".join(f"0x{b:02x}" for b in raw_bytes)
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "--disassemble"],
                        input=hexin, capture_output=True, text=True, timeout=15)
    warnings = r.stderr.count("warning:")
    insns = [l for l in r.stdout.splitlines() if l.strip() and not l.strip().startswith(".text")]
    return warnings == 0 and len(insns) > 0, warnings


def main():
    roots = sys.argv[1:] or ["v142/subcpu", "subcpu/boot"]
    total_byte_bytes = 0
    total_clean_code_bytes = 0
    total_clean_code_blocks = 0
    findings = []
    for root in roots:
        for f in sorted(glob.glob(os.path.join(root, "**", "*.s"), recursive=True)):
            for b in blocks_in_file(f):
                n = len(b["bytes"])
                total_byte_bytes += n
                if n < 3:
                    continue
                # Skip runs that are a single repeated value (0xFF padding etc.) --
                # a disassembler will happily "decode" 0xFF as garbage opcodes too,
                # so uniform-fill runs need a different argument (documented fill),
                # not this one.
                if len(set(b["bytes"])) == 1:
                    continue
                ok, warnings = disasm_clean(b["bytes"])
                if ok:
                    total_clean_code_bytes += n
                    total_clean_code_blocks += 1
                    findings.append((n, b["file"], b["start"], b["end"], b["label"]))
    findings.sort(reverse=True)
    print(f"Total bytes inside ANY .byte run (both images' sources): {total_byte_bytes:,}")
    print(f"Of which: cleanly-disassembling non-uniform runs (candidate undecoded CODE): "
          f"{total_clean_code_bytes:,} bytes in {total_clean_code_blocks} blocks\n")
    print(f"{'bytes':>6}  {'file':45} {'lines':>13}  label")
    for n, f, s, e, label in findings:
        print(f"{n:6d}  {f:45} {s:6d}-{e:<6d}  {label}")


if __name__ == "__main__":
    main()
