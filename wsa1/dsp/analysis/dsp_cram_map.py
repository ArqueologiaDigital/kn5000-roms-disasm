#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_cram_map.py -- de-frame a WSA1R DSP upload into the C-RAM / descriptor maps.

dsp_deframe.py proved the value groups decode to the known coefficients; this goes
one step further and reproduces, statefully, WHAT ENDS UP IN EACH DSP's on-chip
memory -- i.e. the address->value map the emulated upd6383 device must hold after
boot.  It is the GOLDEN REFERENCE for the in-emulator C-RAM readback gate
(kn7000_mame tools/rigs/wsa1_dsp_cram_verify.lua).

The WSA1R serialises coefficient loads as its own 5-byte P7 groups; the chip's
THREE host write pointers are set by ADDRESS groups and auto-increment across the
VALUE groups that follow -- EXACTLY as the KN5000 drives the same chip through
upd6383.cpp host_w's poke path (cross-corroborated between the two products, and
adversarially verified by the wf_dec61ab4-b19 workflow, 2026-09-06):

  ADDRESS groups (a pointer/ldptr word):
    08 01 (A>>4)&0x0F ((A<<4)&0xF0)+8 0x21   -> lo12 0x821 -> set C-RAM      pointer
    08 01 (A>>4)&0x0F ((A<<4)&0xF0)+8 0x25   -> lo12 0x825 -> set DESCRIPTOR  pointer
    00 00 0x10+((A>>4)&0x0F) (A<<4)&0xF0 00   -> class4 1/lo12 0 -> set D-RAM  pointer
                 A = ((b2 & 0x0F) << 4) | ((b3 & 0xF0) >> 4)   (= addr8 of the word)
  VALUE group    0A (v>>17)&0x7F (v>>9)&0xFF (v>>1)&0xFF ((v<<7)&0x80)+K
                 v = ((b1&0x7F)<<17) | (b2<<9) | (b3<<1) | ((b4&0x80)>>7)  (24-bit)
                 -> routed BY ITS OWN K TAG (the device poke switch, upd6383.cpp
                    :1858): K==0x26 -> C-RAM (24-bit); K==0x4C -> descriptor
                    (16-bit); K==0x15 -> D-RAM register file (24-bit); each writes
                    at that space's pointer and post-increments it +1 mod 256.

⚠ CORRECTION (2026-09-06): an earlier revision routed every value to "the pointer
the last ADDRESS group selected".  That CONFLATES the three spaces -- the boot
stream is K=0x15-dominated (dest0: 239 D-RAM / 174 descriptor / 108 C-RAM values),
so active-target routing leaked D-RAM/descriptor values into C-RAM.  Route by the
value's K tag, which the chip does and which pairs 1:1 with the address tag.

    python3 dsp_cram_map.py <dspcap.log>

stdlib only, read-only.  The capture is regenerable (kn7000_mame
tools/rigs/wsa1_dsp_capture.py); this de-framer is the committed instrument.
"""
import collections
import re
import sys

LINE = re.compile(r"dspup: dest(\d) (?:CMD|DAT) ([0-9A-Fa-f]{2})")
NAMES = {0: "IC6", 1: "IC5", 2: "IC30"}
KNOWN = {0x7FFFFF: "wrap", 0x000072: "chorusLFO", 0x200000: "0.25",
         0x400000: "0.5", 0x000000: "zero"}


def deframe_stateful(bytes_):
    """Return (cram, dsc, dram): {addr: value} maps, per-space pointer auto-increment.

    Mirrors the device poke path (upd6383.cpp:1790-1927): address forms set one of
    three pointers; a 0A value is routed by its K tag and post-increments that
    space's pointer.  A sliding 5-byte window finds group leads (the capture is a
    flat byte stream), exactly as dsp_deframe.py."""
    cram, dsc, dram = {}, {}, {}
    wp = {"cram": 0, "dsc": 0, "dram": 0}
    i = 0
    while i < len(bytes_) - 4:
        b = bytes_[i:i + 5]
        if b[0] == 0x08 and b[1] == 0x01 and b[4] in (0x21, 0x25):
            a = ((b[2] & 0x0F) << 4) | ((b[3] & 0xF0) >> 4)
            wp["cram" if b[4] == 0x21 else "dsc"] = a
            i += 5
        elif b[0] == 0x00 and b[1] == 0x00 and (b[2] & 0xF0) == 0x10 and b[4] == 0x00:
            wp["dram"] = ((b[2] & 0x0F) << 4) | ((b[3] & 0xF0) >> 4)
            i += 5
        elif (b[0] & 0xFE) == 0x0A:
            v = ((b[1] & 0x7F) << 17) | (b[2] << 9) | (b[3] << 1) | ((b[4] & 0x80) >> 7)
            k = b[4] & 0x7F
            if k == 0x26:
                cram[wp["cram"]] = v & 0xffffff
                wp["cram"] = (wp["cram"] + 1) & 0xff
            elif k == 0x4C:
                dsc[wp["dsc"]] = v & 0xffff
                wp["dsc"] = (wp["dsc"] + 1) & 0xff
            elif k == 0x15:
                dram[wp["dram"]] = v & 0xffffff
                wp["dram"] = (wp["dram"] + 1) & 0xff
            i += 5
        else:
            i += 1
    return cram, dsc, dram


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    per = collections.defaultdict(list)
    for ln in open(sys.argv[1]):
        m = LINE.search(ln)
        if m:
            per[int(m.group(1))].append(int(m.group(2), 16))

    for d in sorted(per):
        cram, dsc, dram = deframe_stateful(per[d])
        hits = collections.Counter(KNOWN.get(v) for v in cram.values() if v in KNOWN)
        print("dest%d / %-4s : C-RAM %d cells, descriptor %d cells, D-RAM-reg %d cells"
              "   known-in-C-RAM: %s"
              % (d, NAMES.get(d, "?"), len(cram), len(dsc), len(dram), dict(hits)))
        for a in sorted(cram):
            tag = KNOWN.get(cram[a], "")
            print("    cram[0x%02X] = 0x%06X  %s" % (a, cram[a], tag))
        for space, m in (("descriptor", dsc), ("D-RAM-reg", dram)):
            if m:
                lo, hi = min(m), max(m)
                print("    %s addrs 0x%02X..0x%02X (%d cells)" % (space, lo, hi, len(m)))


if __name__ == "__main__":
    sys.exit(main())
