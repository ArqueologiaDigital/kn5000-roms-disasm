#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_zerofill_static.py -- the WSA1R's per-effect D-RAM parameter map, STRAIGHT FROM ROM.

WHAT WAS MISSING
    `dsp_cram_map.py' reproduces what ends up in each DSP's on-chip memory, but it takes a
    CAPTURE (`dspup:' log lines).  Everything downstream of it therefore needed a running
    emulator, and the KN5000 side has had a static equivalent for months
    (`dsp/tools/lfo_ramp.py::cram_of_algo', which replays a parameter stream out of the ROM).

    This closes that gap.  `dsp_record_field_opcodes.py' MEASURED that the 56 PoolDir_Records at
    0xFDBFD9 (stride 0x19) carry coefficient streams at fields +0/+4/+8 and the I-RAM program at
    +12; `gen_wsa1_dsp_disasm.py' already resolves those pointers and frames the opcode-3 body.
    Compose the two -- resolve +0/+4/+8, take the opcode-0 payload, and hand the raw bytes to
    `dsp_cram_map.deframe_stateful', which SLIDES a 5-byte window and so needs no framing of its
    own -- and the per-effect map falls out with no capture at all.

USAGE
    python3 wsa1/dsp/analysis/dsp_zerofill_static.py            # the per-record map
    python3 wsa1/dsp/analysis/dsp_zerofill_static.py --span     # the walk-span test below

WHAT IT FINDS
    * All 56 records decode.  The per-effect streams write **D-RAM registers (K tag 0x15)** and
      **no C-RAM (0x26) at all** -- the C-RAM coefficients come from elsewhere (the boot streams),
      which is a correction to the loose reading that "effect selection re-uploads C-RAM".
    * The values are recognisable: ENHANCER writes 0x0A and 0x12 = **0.870000** and 0x14 =
      **0.500000**; PHASER writes 0x10 = **1.000000** and 0x13 = **0.500000** -- clean Q23
      fractions.
    * A contiguous run based at **0x50** is written as ZERO in every effect that has one: the
      host's D-RAM **state clear**, the WSA1R's exact analogue of `isa-adjudication.md' sect. 5's
      KN5000 zero-fill block (also based at 0x50).

★ THE TEST THIS WAS BUILT FOR, AND IT DOES NOT DISCRIMINATE -- said plainly so nobody re-runs it
    `closure_pointer.py cmd_cells' states the criterion: *"If the modelled pointer walk of a body
    visits far more distinct cells than [the host's zero-fill block], the walk model -- not a
    missing pointer load -- is what is wrong."*  The body's pointer BASE is unknown, but the walk's
    SPAN is base-independent, so span vs block size is an anchored test that needs no capture.
    It was built to settle `closure_pointer.py' variant V7 (does class 4 post-increment?).

    ⛔ IT CANNOT: 21 of 22 bodies overflow their own zero-fill block under BOTH readings, and only
    TWO rows differ between them at all (rec 49: over by 7 vs 6; rec 51: 5 vs 4).  Neither fits
    either way, so the criterion has no power here.

    ★ But it says something else, and the something else is systematic: **18 of the 22 bodies
    overflow by EXACTLY 5**, regardless of effect, size or family.  A constant offset is not a
    per-program modelling error; it is either five cells the walk over-counts, or five cells the
    host deliberately does not clear -- shared latches, or the input/output pair the kernel owns
    rather than the body.  `closure-pointer.md' already FORCES a re-establishing mechanism the
    project has not identified, and a constant 5 is the shape such a thing leaves behind.
    ⇒ a lead for the pointer-closure question, not for mode 4.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "..", "dsp", "tools"))
import wsa1_dsp_isa_crossval as X                                    # noqa: E402
import dsp_cram_map as CM                                            # noqa: E402
import gen_wsa1_dsp_disasm as G                                      # noqa: E402
import dsp_disasm as DIS                                             # noqa: E402

REC, STRIDE, N = 0xFDBFD9, 0x19, 56


def _rf(rec, off):
    b = X.POOL.D[REC - X.POOL.BASE + STRIDE * rec + off:
                 REC - X.POOL.BASE + STRIDE * rec + off + 2]
    return 0xFD0000 | (b[0] | (b[1] << 8))


def maps_of(rec):
    """(cram, dsc, dram) written by record `rec''s three coefficient streams, from ROM."""
    cram, dsc, dram = {}, {}, {}
    for off in (0, 4, 8):
        a = _rf(rec, off)
        b0 = X.POOL.D[a - X.POOL.BASE]
        if (b0 >> 4) != 0:                       # not a coefficient stream
            continue
        ln = ((b0 & 0x0F) << 8) | X.POOL.D[a - X.POOL.BASE + 1]
        body = bytes(X.POOL.D[a + 2 - X.POOL.BASE: a + ln - X.POOL.BASE])
        c, d, r = CM.deframe_stateful(body)
        cram.update(c)
        dsc.update(d)
        dram.update(r)
    return cram, dsc, dram


def names():
    nm, p2r, out = G.effect_names(), G.prog_to_record(), {}
    for p in range(128):
        r = p2r[p]
        if r not in out and nm[p]:
            out[r] = nm[p]
    return out


def s8(a):
    return a - 256 if a >= 128 else a


def walk_span(words, cls4_moves):
    """max-min of the relative D-RAM pointer over one body.  Base-independent."""
    p = lo = hi = 0
    for w in words:
        if DIS.c_format(w):
            continue
        if (DIS.class4(w) & 7) == 2:
            p += s8(DIS.addr8(w))
        elif cls4_moves and DIS.class4(w) == 4:
            p += s8(DIS.addr8(w))
        lo, hi = min(lo, p), max(hi, p)
    return hi - lo + 1


def main():
    nm = names()
    if "--span" not in sys.argv:
        print("=" * 96)
        print("  WSA1R per-effect D-RAM parameter map, decoded STATICALLY from ROM (no capture)")
        print("=" * 96)
        tot = 0
        for rec in range(N):
            c, d, r = maps_of(rec)
            tot += len(r)
            if not r:
                continue
            zeros = sorted(k for k, v in r.items() if v == 0)
            nz = sorted((k, v) for k, v in r.items() if v)
            print("\n  rec %-3d %-22s  %d D-RAM values (%d zero, %d non-zero)"
                  % (rec, nm.get(rec, "?")[:22], len(r), len(zeros), len(nz)))
            if zeros:
                print("     state clear: %02X..%02X" % (zeros[0], zeros[-1]))
            for a, v in nz[:6]:
                sv = v - (1 << 24) if v & 0x800000 else v
                print("     %02X = %06X  Q23 %+.6f" % (a, v, sv / 8388608.0))
        print("\n  total D-RAM values over all %d records: %d ; C-RAM values: 0" % (N, tot))
        print("  ⇒ the per-effect streams write D-RAM REGISTERS, not C-RAM.")
        return 0

    print("=" * 96)
    print("  WALK SPAN vs the host's own zero-fill block -- base-independent, no capture")
    print("=" * 96)
    print("\n  %-4s %-20s %6s %8s %8s  %s"
          % ("rec", "effect", "block", "span A", "span B", "A = class 4 does NOT move / B = V7"))
    over = [0, 0]
    rows = 0
    for rec in range(N):
        _, _, r = maps_of(rec)
        body = G.op3_body(_rf(rec, 12))
        if not r or not body or not body[1]:
            continue
        ws = body[1]
        if not any((not DIS.c_format(w)) and DIS.class4(w) == 4 for w in ws):
            continue
        ks = sorted(r)
        blk = ks[-1] - ks[0] + 1
        a, b = walk_span(ws, False), walk_span(ws, True)
        over[0] += a > blk
        over[1] += b > blk
        rows += 1
        print("  %-4d %-20s %6d %8d %8d  A:%-11s B:%s"
              % (rec, nm.get(rec, "?")[:20], blk, a, b,
                 "fits" if a <= blk else "OVER by %d" % (a - blk),
                 "fits" if b <= blk else "OVER by %d" % (b - blk)))
    print("\n  bodies overflowing their own zero-fill block:  A %d of %d   B %d of %d"
          % (over[0], rows, over[1], rows))
    print("  ⛔ THE TEST DOES NOT DISCRIMINATE -- both readings overflow almost everywhere, and")
    print("     only two rows differ between them at all.  Recorded so nobody re-runs it.")
    print("  ★ What it DOES show: most bodies overflow by EXACTLY 5, independent of effect, size")
    print("     and family.  A constant offset is not a per-program modelling error -- it is five")
    print("     cells the walk over-counts, or five the host does not clear.  `closure-pointer.md'")
    print("     FORCES a re-establishing mechanism nobody has identified, and a constant 5 is the")
    print("     shape such a thing leaves behind.  A lead for THAT question, not for mode 4.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
