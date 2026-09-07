#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_program_record_classify.py -- which of the 70 program-pool records are real
executable microcode, and which are data framed as opcode-3?

The runtime measurement (FINDINGS-dsp-runtime-effect-uploads.md) showed the emulated
WSA1R only ever holds ONE resident I-RAM kernel (45 distinct words) and never uploads
the rest of the 918-word "program corpus" -- effects are coefficient-driven.  That
raises the question this tool answers from the STATIC side: of the 70 opcode-3 records
in the P7 stream pool, which are genuine executable programs and which are coefficient/
parameter data that merely sits in an opcode-3 record?

Method (uses the 45 runtime-resident words as ground truth):
  * per record: word count, distinct words, container-valid fraction (top nibble 0),
    strict ALU-decode rate (dsp_disasm.alu_decoded), and OVERLAP with the 45 proven-
    executed runtime words (runtime-resident-iram-words.txt).
  * the record with the highest runtime overlap IS the boot/runtime kernel.
  * a record that is highly decodable is program-like; one near the decode null with
    zero runtime overlap is data-like.

This does NOT execute anything and invents no meanings; it partitions the corpus so the
ISA-decode effort can focus on the words that are actually code.

    python3 dsp_program_record_classify.py

stdlib + the sibling wsa1_dsp_isa_crossval / dsp_disasm modules.  Read-only.
"""
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import wsa1_dsp_isa_crossval as X                                    # noqa: E402
import dsp_disasm as D                                              # noqa: E402


def program_records():
    """Yield (addr16, [words]) for each opcode-3 record in the pool."""
    for o in X.POOL.tile():
        if o["kind"] != "STREAM":
            continue
        for (addr, op, ln) in o["recs"]:
            if op != 3:
                continue
            body = X.POOL.D[addr + 2 - X.POOL.BASE: addr + ln - X.POOL.BASE]
            data = body[3:]
            a16 = (body[1] << 8) | body[2] if len(body) >= 3 else -1
            words = [int.from_bytes(data[k:k + 5], "big")
                     for k in range(0, len(data) - 4, 5)]
            yield a16, words


def main():
    rt_path = os.path.join(HERE, "runtime-resident-iram-words.txt")
    rt = {int(ln.strip(), 16) for ln in open(rt_path) if ln.strip() and not ln.startswith("#")}
    # convert the 5-byte-hex baseline (stored as 10 hex chars) to 40-bit ints
    rt = {int(format(w, "010X"), 16) if w < (1 << 40) else w for w in rt}

    recs = list(program_records())
    print("opcode-3 program records: %d" % len(recs))
    print("runtime-resident words (ground truth): %d\n" % len(rt))
    print("  # addr16  words  distinct  cont-valid  strict-dec  rt-overlap  class")
    print("  " + "-" * 74)

    kernel_i, kernel_ov = -1, -1
    prog_like = data_like = 0
    prog_words = data_words = 0
    for i, (a16, ws) in enumerate(recs):
        if not ws:
            continue
        dist = set(ws)
        cv = sum(1 for w in ws if (w >> 36) == 0)
        dc = sum(1 for w in ws if D.alu_decoded(w))
        ov = len(dist & rt)
        cvf, dcf = cv / len(ws), dc / len(ws)
        # classify: program-like if decodable well above the ~22% null OR any runtime overlap
        cls = "PROGRAM" if (ov > 0 or (cvf > 0.9 and dcf >= 0.30)) else "data?"
        if cls == "PROGRAM":
            prog_like += 1; prog_words += len(dist)
        else:
            data_like += 1; data_words += len(dist)
        if ov > kernel_ov:
            kernel_ov, kernel_i = ov, i
        print("  %2d 0x%04X %5d  %7d   %6.0f%%    %6.1f%%   %4d/%-4d  %s"
              % (i, a16, len(ws), len(dist), 100 * cvf, 100 * dcf, ov, len(dist), cls))

    print("\nSUMMARY")
    print("  runtime kernel  = record #%d (addr 0x%04X): %d/%d of its distinct words are"
          " the 45 proven-executed" % (kernel_i, recs[kernel_i][0],
                                       kernel_ov, len(set(recs[kernel_i][1]))))
    print("  program-like records: %d (%d distinct words)" % (prog_like, prog_words))
    print("  data-like records   : %d (%d distinct words)" % (data_like, data_words))
    allw = set(w for _, ws in recs for w in ws)
    print("  => of %d distinct corpus words, %d are the runtime kernel (measured code);"
          " the rest are unproven" % (len(allw), len(allw & rt)))


if __name__ == "__main__":
    sys.exit(main())
