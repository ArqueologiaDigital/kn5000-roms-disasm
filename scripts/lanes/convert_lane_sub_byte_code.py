#!/usr/bin/env python3
"""convert_lane_sub_byte_code.py -- convert verified-code `.byte` runs to real mnemonics.

QUESTION IT ANSWERS
    Of the candidate CODE-as-`.byte` blocks found by audit_lane_sub_byte_code.py in
    v142/subcpu/kn5000_subprogram_v142.s and v142/subcpu/subcpu_fp_math.s (the two
    files that are genuinely program code, as opposed to subcpu_data_tables.s, which
    is data by design and where the same detector produces false positives -- see
    the lane report), which ones can be safely turned into real instructions right
    now, with a mechanical proof rather than a human guess?

METHOD
    For each contiguous, non-uniform `.byte` run of >= 3 bytes:
      1. Disassemble it with `llvm-mc --triple=tlcs900 --disassemble`.
      2. Reject if disassembly produced any warning/error, or zero instructions
         (that is the existing DSP_Bytecode Handler-0/5 case: real code the pinned
         LLVM tlcs900 backend cannot encode/decode yet -- left alone, unconverted).
      3. Re-ASSEMBLE the disassembly text with the same tool and byte-compare
         against the original run. Only an EXACT match is applied -- this is what
         makes the conversion a proof, not a guess: a block that decodes to
         plausible-looking mnemonics but doesn't round-trip is left as `.byte`,
         unconverted, same as a hard LLVM-backend refusal.
    Blocks are replaced in place, byte range preserved, existing header comments
    left untouched; only the `.byte` line(s) directly under a label are swapped
    for the mnemonic lines LLVM produced.

    Data tables that happen to decode cleanly (e.g. Voice_FineTune_Curve, a
    lookup curve of mostly 0x00/0xFF bytes) are a KNOWN failure mode of the
    "decodes cleanly" heuristic alone -- see the audit script's docstring. This
    script is only pointed at the two code files for that reason; it does not
    attempt subcpu_data_tables.s or subcpu/boot at all.

RUN
    python3 scripts/lanes/convert_lane_sub_byte_code.py --apply v142/subcpu/kn5000_subprogram_v142.s v142/subcpu/subcpu_fp_math.s
    (omit --apply for a dry run that only reports what WOULD convert)
"""
import re, subprocess, sys, os

LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
LLVM_OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")

BYTE_LINE = re.compile(r'^\s*\.byte\s+(.+)$')
BYTE_VAL = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:')


def find_blocks(lines):
    """Return list of dicts: start (0-idx), end (0-idx, inclusive), bytes[]"""
    blocks = []
    cur = None
    for i, line in enumerate(lines):
        m = BYTE_LINE.match(line)
        if m:
            vals = [int(v, 16) for v in BYTE_VAL.findall(m.group(1))]
            if cur is None:
                cur = {"start": i, "end": i, "bytes": []}
            cur["bytes"].extend(vals)
            cur["end"] = i
            continue
        if cur is not None:
            blocks.append(cur)
            cur = None
    if cur is not None:
        blocks.append(cur)
    return blocks


def disasm(raw):
    hexin = " ".join(f"0x{b:02x}" for b in raw)
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "--disassemble"],
                        input=hexin, capture_output=True, text=True, timeout=15)
    warnings = r.stderr.count("warning:") + r.stderr.count("error:")
    insns = [l.rstrip() for l in r.stdout.splitlines()
             if l.strip() and not l.strip().startswith(".text")]
    return insns, warnings


def roundtrip_bytes(insn_lines):
    src = "\t.text\n" + "\n".join(insn_lines) + "\n"
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        sp = os.path.join(td, "a.s")
        op = os.path.join(td, "a.o")
        bp = os.path.join(td, "a.bin")
        open(sp, "w").write(src)
        r = subprocess.run([LLVM_MC, "--triple=tlcs900", "-filetype=obj", "-o", op, sp],
                            capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(op):
            return None
        r2 = subprocess.run([LLVM_OBJCOPY, "-O", "binary", "-j", ".text", op, bp],
                             capture_output=True, text=True)
        if r2.returncode != 0 or not os.path.exists(bp):
            return None
        return open(bp, "rb").read()


def process(path, apply_):
    lines = open(path, encoding="latin-1").readlines()
    blocks = find_blocks(lines)
    converted_bytes = 0
    converted_blocks = 0
    skipped_bytes = 0
    replacements = {}  # start_line -> (end_line, new_lines)
    for b in blocks:
        n = len(b["bytes"])
        if n < 3 or len(set(b["bytes"])) == 1:
            continue
        insns, warnings = disasm(b["bytes"])
        if warnings or not insns:
            skipped_bytes += n
            continue
        rt = roundtrip_bytes(insns)
        if rt != bytes(b["bytes"]):
            skipped_bytes += n
            continue
        # indent consistently with a tab, matching the file's own convention
        new_lines = [("\t" + l.strip() + "\n") for l in insns]
        replacements[b["start"]] = (b["end"], new_lines)
        converted_bytes += n
        converted_blocks += 1

    if replacements:
        out = []
        i = 0
        while i < len(lines):
            if i in replacements:
                end, new_lines = replacements[i]
                out.extend(new_lines)
                i = end + 1
            else:
                out.append(lines[i])
                i += 1
        if apply_:
            open(path, "w", encoding="latin-1").writelines(out)

    print(f"{path}: converted {converted_blocks} blocks / {converted_bytes} bytes"
          f"; left {skipped_bytes} bytes as .byte (round-trip failed or LLVM refused)")
    return converted_bytes, skipped_bytes


def main():
    args = sys.argv[1:]
    apply_ = "--apply" in args
    files = [a for a in args if a != "--apply"]
    tot_c = tot_s = 0
    for f in files:
        c, s = process(f, apply_)
        tot_c += c
        tot_s += s
    print(f"\nTOTAL: converted {tot_c} bytes, left {tot_s} bytes as .byte" +
          ("" if apply_ else "  [DRY RUN -- pass --apply to write]"))


if __name__ == "__main__":
    main()
