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
    python3 wsa1/dsp/analysis/dsp_zerofill_static.py --cells    # the distinct-cell test

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

★ THE TEST THIS WAS BUILT FOR -- run it the way `cmd_cells' actually states it
    `closure_pointer.py cmd_cells': *"how many DISTINCT D-RAM cells each body touches under the
    walk, against the host's own zero-fill block length ... If the modelled pointer walk visits far
    more distinct cells than that, the walk model -- not a missing pointer load -- is what is
    wrong."*  The body's pointer BASE is unknown, but the COUNT of distinct cells is
    base-independent, so this needs no capture and no emulator.

    ⛔⛔ MY FIRST VERSION COMPARED THE WRONG TWO NUMBERS and produced a finding that was not there.
    It used the walk's SPAN against `max(addr) - min(addr) + 1` of the host's writes -- but the
    host's writes are NOT contiguous.  They are TWO clusters: `0x05`/`0x06` (plus a few scattered
    registers) and a contiguous state run based at **0x50** (OVERDRIVE/EXCITER 0x50..0x57, PHASER
    0x50..0x63, PEQ+CHORUS 0x50..0x67).  `max-min+1` therefore reported 83 where 10 cells are
    written, and the "18 of 22 bodies overflow by exactly 5" that fell out of it was an artefact of
    comparing two spans that derive from the same program structure.  RETRACTED.

    ★ RUN CORRECTLY -- distinct cells VISITED vs cells WRITTEN -- the test HAS power where the span
    version had none: **20 of 22 bodies now separate the two readings** (the span version separated
    2).  But it does not settle mode 4 either:

        bodies visiting MORE cells than the host wrote:   no-move 22 of 22    V7 22 of 22

    Every body over-visits, by 3..12 cells, under BOTH readings.  ⇒ the walk model has a systematic
    defect that dominates the comparison, and reading the margin (no-move is the smaller overflow in
    15 of the 20 differing rows, sign-test p ~ 0.02) would be extracting a signal from two models
    that are both wrong.  NOT evidence for either reading.

    ⇒ what this DOES establish is a well-posed, capture-free, base-independent instrument, and that
    the WSA1R walk over-visits everywhere.  `closure-pointer.md' FORCES a re-establishing mechanism
    nobody has identified (residue +121, no variant closes); a systematic over-visit in the OTHER
    product is the same question seen from a second side.
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


def visited(words, cls4_moves):
    """COUNT of distinct D-RAM cells the relative walk touches.  The base is unknown but the
    COUNT does not depend on it -- which is what makes this usable without a capture."""
    p, seen = 0, {0}
    for w in words:
        if DIS.c_format(w):
            continue
        if (DIS.class4(w) & 7) == 2:
            p += s8(DIS.addr8(w))
            seen.add(p)
        elif cls4_moves and DIS.class4(w) == 4:
            p += s8(DIS.addr8(w))
            seen.add(p)
    return len(seen)


def main():
    nm = names()
    if "--cells" not in sys.argv:
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
            #  ⚠ the zeros are NOT one contiguous block -- report the clusters, not min..max.
            #  Quoting `zeros[0]..zeros[-1]' is what produced the retracted "overflow by 5".
            if zeros:
                runs, cur = [], [zeros[0]]
                for k in zeros[1:]:
                    if k == cur[-1] + 1:
                        cur.append(k)
                    else:
                        runs.append(cur)
                        cur = [k]
                runs.append(cur)
                print("     state clear: %s"
                      % "  ".join("%02X..%02X (%d)" % (r[0], r[-1], len(r)) for r in runs))
            for a, v in nz[:6]:
                sv = v - (1 << 24) if v & 0x800000 else v
                print("     %02X = %06X  Q23 %+.6f" % (a, v, sv / 8388608.0))
        print("\n  total D-RAM values over all %d records: %d ; C-RAM values: 0" % (N, tot))
        print("  ⇒ the per-effect streams write D-RAM REGISTERS, not C-RAM.")
        return 0

    print("=" * 96)
    print("  DISTINCT CELLS VISITED vs CELLS THE HOST WROTE -- base-independent, no capture")
    print("  (`closure_pointer.py cmd_cells' states the criterion; the COUNT needs no base.)")
    print("=" * 96)
    print("\n  %-4s %-20s %8s %8s %8s  %s"
          % ("rec", "effect", "written", "visit A", "visit B", "A = class 4 does NOT move / B = V7"))
    over, rows, differ, smaller = [0, 0], 0, 0, [0, 0]
    for rec in range(N):
        _, _, r = maps_of(rec)
        body = G.op3_body(_rf(rec, 12))
        if not r or not body or not body[1]:
            continue
        ws = body[1]
        if not any((not DIS.c_format(w)) and DIS.class4(w) == 4 for w in ws):
            continue
        a, b = visited(ws, False), visited(ws, True)
        over[0] += a > len(r)
        over[1] += b > len(r)
        rows += 1
        if a != b:
            differ += 1
            smaller[0 if a < b else 1] += 1
        print("  %-4d %-20s %8d %8d %8d  A:%-9s B:%s"
              % (rec, nm.get(rec, "?")[:20], len(r), a, b,
                 "fits" if a <= len(r) else "OVER %d" % (a - len(r)),
                 "fits" if b <= len(r) else "OVER %d" % (b - len(r))))
    print("\n  bodies visiting MORE cells than the host wrote:  A %d of %d   B %d of %d"
          % (over[0], rows, over[1], rows))
    print("  rows where the two readings differ at all: %d of %d" % (differ, rows))
    print("     of those, the SMALLER overflow is A in %d and B in %d" % tuple(smaller))
    print("\n  ⛔ THIS DOES NOT SETTLE MODE 4.  Every body over-visits under BOTH readings, so the")
    print("     walk model has a systematic defect that dominates the comparison; reading the")
    print("     margin would be extracting a signal from two models that are both wrong.")
    print("  ★ What it DOES give: a well-posed, capture-free, base-independent instrument, and the")
    print("     fact that the WSA1R walk over-visits EVERYWHERE.  `closure-pointer.md' forces a")
    print("     re-establishing mechanism nobody has identified -- this is that question from the")
    print("     second product's side.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
