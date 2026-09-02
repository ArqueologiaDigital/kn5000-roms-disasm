#!/usr/bin/env python3
"""byte_run_start_enrichment.py -- are an image's leftover `.byte` runs DATA, or
are they CODE that the disassembler could not decode?

QUESTION THIS ANSWERS
----------------------
Every image in this tree carries `.byte` runs. Two very different things produce
them:

  (a) genuine byte-valued data, correctly represented;
  (b) real instructions the decoder could not decode, left behind as raw bytes
      by whatever conversion pass ran -- CODE-AS-BYTE, the debt that
      `kn5000_source_coverage.py` is structurally blind to.

They look identical to every directive counter, and the byte gate cannot tell
them apart either. This script separates them statistically, per image, using
the decoder's OWN blind spots as the probe.

THE IDEA
---------
A conversion pass converts what the decoder can decode and leaves what it
cannot. So if an image's `.byte` residue is case (b), the residue should START
disproportionately often with a byte the decoder REFUSES -- because that refusal
is precisely why the run was left behind. If the residue is case (a), the first
byte of a run carries no information about the decoder at all, and undecodable
byte values should appear as run-starts at whatever rate the DATA happens to use
them.

★ THE CONTROL IS THE WHOLE INSTRUMENT. A raw count of "runs starting with 0x01"
is meaningless: 0x01 is a common data value, and in a pure data image it will
top the table for reasons that have nothing to do with any decoder. So each
BLIND byte is scored against a CONTROL SET of decodable bytes of similar
magnitude -- 0x02, 0x03, 0x05, 0x16, 0x1b. In a data image both sets track each
other. Enrichment of the blind set over the control set is the signal.

⚠ WHAT "BLIND" MEANS HERE, AND ITS ONE IMPORTANT LIMIT. The blind set is
{0x01, 0x04, 0x17, 0x1a, 0x1c} -- five leading opcode bytes with NO decode
anywhere in tlcs900_backend (established over 393,216 operand continuations each
by leading_byte_reserved_probe.py) which MAME's unidasm decodes as real
TLCS-900 instructions: normal, max, ldf, JP nnnn, CALL nnnn
(unmapped_byte_oracle.py). They are backend gaps, NOT reserved silicon -- an
earlier claim that they were reserved was retracted; see
notes/DEBT-INVENTORY-2026-09-02.md.

⚠ The control bytes must stay DECODABLE and of similar magnitude to the blind
ones. Do not "improve" this script by widening the control set to all 256
values: high bytes are prefix bytes with completely different data frequencies
and the comparison stops meaning anything.

⚠ WHAT THIS DOES NOT DO. It is a per-image statistic, not a per-run verdict. A
high enrichment says "this image's residue is largely undecoded code, go look";
it does NOT license converting any individual run. Deciding a specific run is
code still needs the usual evidence -- what references it, whether anything
calls or jumps into it. Data-as-code remains the standing hazard in the other
direction.

RESULT AS OF 2026-09-02 (regenerate before quoting; lanes are converting)

    image     blind {01,04,17,1a,1c}   control {02,03,05,16,1b}   read
    v10             19.2%                      0.4%              CODE, ~48x
    prom_b          15.2%                     17.5%              data
    prom_d          12.2%                      8.3%              data-ish

★ v10 is the finding. Its residue starts with an undecodable opcode ~48x more
often than with a comparable decodable one, and its OTHER top run-starts --
0xC1 5.2%, 0xC7 4.0%, 0xF1 3.3%, 0xF0, 0xF3, 0xD1, 0xD7 -- are exactly the
prefix bytes that dominate v7's blocked-slice census. Only 10 of v10's 3,395
blind-starting runs are in the sound_data_*.s tone tables, so this is not an
artefact of bulk data files; the concentrations are in code:
extension_data.s 58.3%, seq_event_playback.s 40.9%, ui_mode_handlers.s 29.6%.

prom_b and prom_d show no enrichment, which is the negative control the
instrument needs: the same script over comparable trees does NOT cry code
everywhere, so v10's number is not an artefact of the method.

⚠⚠ CORRECTION 2026-09-02, AFTER THE FIVE BLIND BYTES WERE TAUGHT TO THE DECODER
(tlcs900_backend@6f456a19f05b). THE "CODE, ~48x" READING ABOVE DOES NOT HOLD, and
this script has a structural confound that the WSA1R negative control does not
catch.

Where a region was converted by a LINEAR FORCE-DISASSEMBLY pass, a `.byte` run
begins at exactly the byte the decoder refused. A DECODABLE control byte
therefore can almost never START a run -- it is consumed into the surrounding
instruction stream instead. The control rate is pinned near zero BY
CONSTRUCTION, whatever the region really contains, so the blind/control ratio
is close to tautological for any force-disassembled region. The WSA1R images do
not show enrichment because their residue was not produced that way, not
because their residue is more data-like.

And the composition matters: 0x01 and 0x04 -- two of the commonest data values
in any image -- are 2,188 and 993 of v10's 3,395 blind run-starts, 93.6% of the
total. 0x1a and 0x1c, the CONTROL-FLOW bytes that made the finding look
important, are 28 and 62.

Two committed measurements now contradict the code reading directly:
  * scripts/analysis/blind_run_decode_census.py -- with the five bytes decodable,
    82.8% of v10's blind runs decode end-to-end clean, but a SHUFFLE of the same
    bytes scores 82.1%. No instruction structure.
  * scripts/analysis/blind_byte_rom_sites.py -- across six committed images not
    one occurrence of the five survives inspection as code; every site is a byte
    ramp, a mask table, a pointer table, a string or a parameter block.

Keep this script: the per-file table is still a useful pointer at where residue
concentrates. Do NOT quote its ratio as evidence of code.

RUN
    python3 scripts/analysis/byte_run_start_enrichment.py [root ...]
    default roots: v10/maincpu wsa1/prom_a wsa1/prom_b wsa1/prom_c wsa1/prom_d
"""
import collections
import io
import os
import re
import sys

BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf",
         0x1a: "jp nnnn", 0x1c: "call nnnn"}
CONTROL = {0x02, 0x03, 0x05, 0x16, 0x1b}

BYTE_RE = re.compile(r"^\s*\.byte\s+(.*)$")

DEFAULT_ROOTS = ["v10/maincpu", "wsa1/prom_a", "wsa1/prom_b",
                 "wsa1/prom_c", "wsa1/prom_d"]


def run_starts(root):
    """First byte of each maximal .byte run, plus the file it is in."""
    counts = collections.Counter()
    per_file = collections.Counter()
    per_file_total = collections.Counter()
    for dirpath, _, files in os.walk(root):
        for fn in files:
            if not fn.endswith(".s"):
                continue
            path = os.path.join(dirpath, fn)
            prev_was_byte = False
            for line in io.open(path, encoding="latin-1"):
                stripped = line.strip()
                if not stripped or stripped.startswith(";"):
                    continue
                m = BYTE_RE.match(line)
                if m:
                    if not prev_was_byte:
                        per_file_total[path] += 1
                        first = m.group(1).split(";")[0].split(",")[0].strip()
                        try:
                            val = int(first, 0)
                        except ValueError:
                            prev_was_byte = True
                            continue
                        counts[val] += 1
                        if val in BLIND:
                            per_file[path] += 1
                    prev_was_byte = True
                else:
                    prev_was_byte = False
    return counts, per_file, per_file_total


def main():
    roots = sys.argv[1:] or DEFAULT_ROOTS
    print("blind   {%s}  (no decode in tlcs900_backend; real insns per unidasm)"
          % ", ".join("0x%02x" % b for b in sorted(BLIND)))
    print("control {%s}  (decodable, comparable magnitude)"
          % ", ".join("0x%02x" % b for b in sorted(CONTROL)))
    print()
    for root in roots:
        if not os.path.isdir(root):
            print("  %-16s (missing)" % root)
            continue
        counts, per_file, per_file_total = run_starts(root)
        total = sum(counts.values())
        if not total:
            print("  %-16s no .byte runs" % root)
            continue
        blind = sum(counts[b] for b in BLIND)
        ctrl = sum(counts[b] for b in CONTROL)
        ratio = (blind / ctrl) if ctrl else float("inf")
        verdict = ("CODE-AS-BYTE likely" if ratio >= 3
                   else "no enrichment -- reads as data")
        print("  %-16s %6d runs   blind %5.1f%%   control %5.1f%%   "
              "ratio %5.1fx   %s" %
              (root, total, 100 * blind / total, 100 * ctrl / total,
               ratio, verdict))
        if ratio >= 3:
            top = [(p, n) for p, n in per_file.most_common(6)]
            for p, n in top:
                print("        %5d/%-5d %5.1f%%  %s" %
                      (n, per_file_total[p], 100 * n / per_file_total[p], p))
    print()
    print("⚠ Per-image statistic, NOT a per-run verdict. A high ratio says go "
          "look; it does not license converting any individual run.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
