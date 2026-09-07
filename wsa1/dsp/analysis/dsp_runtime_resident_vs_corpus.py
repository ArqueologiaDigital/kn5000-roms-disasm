#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_runtime_resident_vs_corpus.py -- which static corpus words are RUNTIME-RESIDENT.

The in-emulator effect sweep (kn7000_mame tools/rigs/wsa1_dsp_effect_sweep.lua) shows
that at runtime the WSA1R DSPs hold ONE resident I-RAM kernel (IC30, 63 words / 45
distinct) that is invariant across all 55 effects -- effect selection is
coefficient-driven and never re-programs I-RAM (FINDINGS-dsp-runtime-effect-uploads.md).

This cross-checks those 45 measured-resident words against the static 918-word program
corpus (wsa1_dsp_isa_crossval.py). Words that match are PROVEN-EXECUTED: they have a
real runtime execution context, promoting them from static-extraction to
measured-resident -- the sharpest subset for ISA decode.

MEASURED 2026-09-07: all 45 runtime-resident words are container-valid AND all 45 are
in the static corpus (45/45). So the runtime kernel is a genuine subset of the corpus,
and only ~5% (45/918) of the static "program words" are ever executed as microcode.

    python3 dsp_runtime_resident_vs_corpus.py [runtime-resident-iram-words.txt]

Input file: one 5-byte big-endian hex word per line (the IWORD dump from the rig).
Default: runtime-resident-iram-words.txt beside this script. stdlib only, read-only.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wsa1_dsp_isa_crossval as X                                    # noqa: E402


def w2int(h):
    b = bytes.fromhex(h)
    return (b[0] << 32) | (b[1] << 24) | (b[2] << 16) | (b[3] << 8) | b[4]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else \
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "runtime-resident-iram-words.txt")
    rt = sorted({ln.strip() for ln in open(path) if ln.strip() and not ln.startswith("#")})
    corpus = set(X.wsa1_stream_words()[0])
    ints = [w2int(h) for h in rt]
    tn0 = sum(1 for i in ints if (i >> 36) == 0)
    inc = [h for h, i in zip(rt, ints) if i in corpus]
    notin = [h for h, i in zip(rt, ints) if i not in corpus]

    print("runtime-resident distinct I-RAM words : %d" % len(rt))
    print("static program corpus (distinct)      : %d" % len(corpus))
    print("container-valid (top nibble 0)        : %d/%d" % (tn0, len(rt)))
    print("MATCH the static corpus               : %d/%d" % (len(inc), len(rt)))
    print("NOT in the static corpus              : %d  %s" % (len(notin), notin[:8]))
    print("=> measured-resident executable surface = %d of %d static words (%.1f%%)"
          % (len(inc), len(corpus), 100.0 * len(inc) / len(corpus) if corpus else 0.0))
    return 0 if not notin else 1


if __name__ == "__main__":
    sys.exit(main())
