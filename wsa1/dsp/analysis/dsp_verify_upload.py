#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_verify_upload.py -- verify the captured DSP upload against the static corpus.

This is the DSP-device correctness gate (HANDOFF-wsa1-dsp-device-build.md step 5):
the microcode the emulated WSA1R uploads to its uPD6383GF DSPs at runtime must be
the SAME instruction words the disassembler extracts statically from the ROM
(wsa1_dsp_isa_crossval.py).  If it matches, a upd6383 instance fed this stream has
the right I-RAM, and no word is faked.

It de-interleaves a boot capture (kn7000_mame dsp_capture(), LOG_DSPUP) using the
C/D command markers (traced in FINDINGS-dsp-upload-deframed.md): a program-word
record is `CMD 0x01`, then two `DAT` bytes (a 16-bit big-endian start address),
then N `DAT` payload bytes, which regroup by 5 into 40-bit instruction words.
Coefficient records (opcode 0/1/5) use the 5-byte VALUE/ADDRESS groups instead
and are skipped here.

MEASURED 2026-09-06 (30 s boot): every program-word block found regroups into
words that are all top-nibble-zero (the container invariant) and all present in
the static WSA1R corpus -- e.g. IC30's one block, addr 0x0030, 63/63 words match.

    python3 dsp_verify_upload.py <dspcap.log>

stdlib only, read-only.
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
import wsa1_dsp_isa_crossval as X                            # noqa: E402

LINE = re.compile(r"dspup: dest(\d) (CMD|DAT) ([0-9A-Fa-f]{2})")
NAMES = {0: "IC6", 1: "IC5", 2: "IC30"}


def program_blocks(stream):
    """Yield (start_addr, [40-bit words]) for each CMD 0x01 record with payload."""
    i = 0
    while i < len(stream):
        cd, b = stream[i]
        if cd == "CMD" and b == 0x01:
            j = i + 1
            dat = []
            while j < len(stream) and stream[j][0] == "DAT":
                dat.append(stream[j][1])
                j += 1
            if len(dat) >= 3 + 5:                    # address + at least one word
                addr = (dat[0] << 8) | dat[1]
                pay = dat[2:]
                words = [(pay[k] << 32) | (pay[k + 1] << 24) | (pay[k + 2] << 16)
                         | (pay[k + 3] << 8) | pay[k + 4]
                         for k in range(0, len(pay) - 4, 5)]
                yield addr, words
            i = j
        else:
            i += 1


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    per = collections.defaultdict(list)
    for ln in open(sys.argv[1]):
        m = LINE.search(ln)
        if m:
            per[int(m.group(1))].append((m.group(2), int(m.group(3), 16)))

    corpus = set(X.wsa1_stream_words()[0])
    print("static WSA1R corpus: %d distinct program words" % len(corpus))
    grand_words = grand_hit = grand_tn0 = 0
    for d in sorted(per):
        blocks = list(program_blocks(per[d]))
        tw = sum(len(w) for _, w in blocks)
        hit = sum(1 for _, ws in blocks for w in ws if w in corpus)
        tn0 = sum(1 for _, ws in blocks for w in ws if (w >> 36) == 0)
        grand_words += tw; grand_hit += hit; grand_tn0 += tn0
        print("dest%d / %-4s : %d program block(s), %d words -- container-valid %d/%d, "
              "match static corpus %d/%d"
              % (d, NAMES.get(d, "?"), len(blocks), tw, tn0, tw, hit, tw))
        for addr, ws in blocks[:8]:
            hh = sum(1 for w in ws if w in corpus)
            print("     addr 0x%04X  %d words  %d/%d match" % (addr, len(ws), hh, len(ws)))
    print("\nTOTAL program words: %d   container-valid %d   corpus-match %d  (%.1f%%)"
          % (grand_words, grand_tn0, grand_hit,
             100.0 * grand_hit / grand_words if grand_words else 0.0))


if __name__ == "__main__":
    sys.exit(main())
