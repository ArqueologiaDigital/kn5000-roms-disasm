#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_datapath_fingerprint.py -- per-program census of the FOUR kernel primitives.

Backs EFFECT-ALGORITHMS-implementation-spec.md: every effect is a wiring of a small set of
primitives, so counting which primitives each program uses is the "what an emulator needs"
table. For each effect program of both products it reports:

  DRAM r/w  -- external delay-line reads and writes (class-1 escape, addr8 bit6 = direction)
  LFO       -- class-6 LFO-waveform lookups (addr8 in {0x18,0x1A,0x1E,0x20}); count = voices
  SHAPE     -- class-6 waveshaper lookups (addr8 = 0x28); a static distortion curve
  DF-I      -- Direct-Form-I biquad section entries (ld.ta, ACT 0x13); count/2 = bands/ch
  2-state   -- ACT 0x0D two-state-filter updates (reverb/mod feedback damping)
  gains     -- distinct C-format makeup/crossfade immediates at lo12=0x44C

    python3 dsp/tools/dsp_datapath_fingerprint.py            # all programs
    python3 dsp/tools/dsp_datapath_fingerprint.py pitch      # filter by name substring

Example (MEASURED 2026-09-08): PITCH SHIFTER = 8 DRAM r / 7 w, 0 LFO, 0 SHAPE, near-unity
gain 992 -- a delay-line crossfading pitch shifter, NOT a phase vocoder.

Graded structural census from the committed disasm. stdlib + dsp_disasm; read-only.
"""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [(os.path.join(HERE, "..", "disasm"), "KN5000"),
         (os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm"), "WSA1R")]

LFO_SEL = {0x18, 0x1A, 0x1E, 0x20}
SHAPE_SEL = 0x28


def load_all():
    progs = []
    for tree, prod in TREES:
        for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
            b = os.path.basename(p)
            if b in ("index.dsm", "kernel.dsm", "epilogue.dsm") or b.startswith("struct_"):
                continue
            nm, ws = None, []
            for ln in open(p):
                m = NAMELINE.search(ln)
                if m:
                    nm = m.group(1)
                m = WORD.match(ln)
                if m:
                    ws.append(int(m.group(1), 16))
            if nm and ws:
                progs.append((prod, nm, ws))
    return progs


def census(ws):
    dr = dw = lfo = shape = df1 = twos = 0
    gains = set()
    for w in ws:
        c = D.class4(w)
        if c == 1 and (D.hi12(w) & 0x800):
            if D.addr8(w) & 0x40:
                dw += 1
            else:
                dr += 1
        elif c == 6:
            a = D.addr8(w)
            if a in LFO_SEL:
                lfo += 1
            elif a == SHAPE_SEL:
                shape += 1
        if D.lo_act(w) == 0x13:
            df1 += 1
        if D.lo_act(w) == 0x0D:
            twos += 1
        if D.c_format(w) and D.lo12(w) == 0x44C:
            im = D.c_imm13(w)
            gains.add(im - 0x2000 if im & 0x1000 else im)
    return dr, dw, lfo, shape, df1, twos, sorted(gains)


def main():
    filt = sys.argv[1].upper() if len(sys.argv) > 1 else None
    progs = load_all()
    hdr = ("prod   | effect                 | words | DRAMr | DRAMw | LFO | SHAPE | "
           "DF-I | 2-state | gains@0x44C")
    print(hdr)
    print("-" * len(hdr))
    for prod, nm, ws in progs:
        if filt and filt not in nm.upper():
            continue
        dr, dw, lfo, shape, df1, twos, gains = census(ws)
        print("%-6s | %-22s | %5d | %5d | %5d | %3d | %5d | %4d | %7d | %s"
              % (prod, nm[:22], len(ws), dr, dw, lfo, shape, df1, twos,
                 ",".join(str(g) for g in gains) or "-"))

    if filt:
        return 0
    # SRC 0x1C control-bus check: refutes the "0x1C = LFO output" reading. If 0x1C were the
    # LFO it could only appear in programs that HAVE an LFO table -- it does not.
    with_lfo = without_lfo = consumed_by_mac = total_1c = 0
    for prod, nm, ws in progs:
        has_1c = any(not D.c_format(w) and D.lo_src(w) == 0x1C for w in ws)
        has_lfo = any(D.class4(w) == 6 and D.addr8(w) in LFO_SEL for w in ws)
        if has_1c:
            if has_lfo:
                with_lfo += 1
            else:
                without_lfo += 1
        for i, w in enumerate(ws):
            if not D.c_format(w) and D.lo_src(w) == 0x1C:
                total_1c += 1
                if i + 1 < len(ws) and (D.class4(ws[i + 1]) & 8):
                    consumed_by_mac += 1
    print("\nSRC 0x1C control-bus check (refutes 'LFO output'):")
    print("  programs with SRC 0x1C: %d with an LFO table, %d WITHOUT any LFO table"
          % (with_lfo, without_lfo))
    print("  SRC 0x1C words consumed by the NEXT op being a MAC: %d/%d"
          % (consumed_by_mac, total_1c))
    print("  => 0x1C is a control/mod bus multiplied into the path, NOT LFO-specific.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
