#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_deframe.py -- de-frame a captured WSA1R DSP host-bus upload.

The WSA1R uploads its three uPD6383GF DSPs over a bit-banged bus; the MAME driver
captures the byte stream (kn7000_mame wsa1.cpp dsp_capture(), LOG_DSPUP; recipe in
tools/rigs/wsa1_dsp_capture.py).  This de-frames that stream into the P7 5-byte
groups (FINDINGS-prom_c-p7-group-and-naming.md) and decodes them:

  ADDRESS group  08 01 (A>>4)&0x0F ((A<<4)&0xF0)+8 <tag>   tag 0x21 / 0x25
                 -> A = ((b2 & 0x0F) << 4) | ((b3 & 0xF0) >> 4)
  VALUE group    0A (v>>17)&0x7F (v>>9)&0xFF (v>>1)&0xFF ((v<<7)&0x80)+K
                 -> v = ((b1&0x7F)<<17) | (b2<<9) | (b3<<1) | ((b4&0x80)>>7)
                    K = b4 & 0x7F

WHAT IT PROVES (2026-09-06, on a 30 s boot capture): the value groups decode to
the EXACT coefficients the KN5000 side derived independently -- 0x400000 = 0.5,
0x000072 = the CHORUS LFO ramp step (dsp/tools/lfo_ramp.py), plus 0x7FFFFF wrap
and many zeros -- and the K tags are the measured 0x15 (opcode 0) / 0x4C (opcode
5).  So the transport AND the value framing are correct, and the WSA1R
coefficient upload cross-confirms the KN5000 constants.  This closes the value
half of the framing gate (HANDOFF-wsa1-dsp-device-build.md step 2); the address
groups decode to C-RAM/coefficient bases (0x00/0x20/0x60/0xC0-region).

    python3 dsp_deframe.py <dspcap.log>

stdlib only, read-only.
"""
import collections
import re
import sys

LINE = re.compile(r"dspup: dest(\d) (?:CMD|DAT) ([0-9A-Fa-f]{2})")
KNOWN = {0x7FFFFF: "wrap", 0x000072: "chorusLFO", 0x200000: "0.25",
         0x400000: "0.5", 0x000000: "zero"}


def deframe(bytes_):
    addrs, vals, i = [], [], 0
    while i < len(bytes_) - 4:
        b = bytes_[i:i + 5]
        if b[0] == 0x08 and b[1] == 0x01 and b[4] in (0x21, 0x25):
            a = ((b[2] & 0x0F) << 4) | ((b[3] & 0xF0) >> 4)
            addrs.append((a, b[4]))
            i += 5
        elif b[0] == 0x0A:
            v = ((b[1] & 0x7F) << 17) | (b[2] << 9) | (b[3] << 1) | ((b[4] & 0x80) >> 7)
            vals.append((v, b[4] & 0x7F))
            i += 5
        else:
            i += 1
    return addrs, vals


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    per = collections.defaultdict(list)
    for ln in open(sys.argv[1]):
        m = LINE.search(ln)
        if m:
            per[int(m.group(1))].append(int(m.group(2), 16))

    names = {0: "IC6", 1: "IC5", 2: "IC30"}
    for d in sorted(per):
        addrs, vals = deframe(per[d])
        hits = collections.Counter(KNOWN.get(v) for v, _ in vals if v in KNOWN)
        ktag = collections.Counter(k for _, k in vals)
        print("dest%d / %-4s  %d bytes -> %d address groups, %d value groups"
              % (d, names.get(d, "?"), len(per[d]), len(addrs), len(vals)))
        print("    known coefficients:", dict(hits))
        print("    K tags:", dict(sorted(ktag.items(), key=lambda kv: -kv[1])[:6]))
        if addrs:
            print("    address range: %d..%d" % (min(a for a, _ in addrs), max(a for a, _ in addrs)))


if __name__ == "__main__":
    sys.exit(main())
