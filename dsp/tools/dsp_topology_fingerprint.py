#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_topology_fingerprint.py -- structural fingerprint of every DSP effect program,
KN5000 and WSA1R, matched against the canonical topology of the named algorithm.

The effect NAMES are ground truth (a program called PARAMETRIC EQ is a biquad chain; one
called SINGLE DELAY is a delay line). This scans each program's disassembled words for the
uPD6383GF idioms that make up those algorithms and reports, per program, a structural
fingerprint plus whether it matches what the name's canonical DSP topology predicts. It is
the "compare the code topology with the payloads" instrument: it turns a wall of microcode
into a small, checkable structural claim per effect.

Idioms counted (via the shared ISA model dsp/tools/dsp_disasm.py):
  DRw / DRr  external delay-DRAM WRITE / READ (class-1 ESC word; addr8 bit6 = direction) --
             the delay-line taps. A delay/reverb/chorus needs them; a pure EQ/dist does not.
  cMAC       class-A coefficient multiply -- filter/gain coefficients. Biquad-heavy programs
             (EQ) are cMAC-dominated; a bypass (NO OPERATION) has almost none.
  tbl        class-6 table-lookup idiom -- a nonlinearity LUT (distortion/exciter/pitch).
  bqp        ACT 0x0D/0x0E biquad delay-stage words (the two z^-1 state updates).
  accB       SRC 0x11 = the 2nd accumulator (parallel path / crossfade).
  st         store-to-memory words (state / output writes).

Reads the committed .dsm listings (no ROM needed):
    python3 dsp/tools/dsp_topology_fingerprint.py            # both products, full table
    python3 dsp/tools/dsp_topology_fingerprint.py --compare  # KN5000 vs WSA1R, shared names

stdlib + dsp_disasm. Read-only.
"""
import argparse
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")

# what each family's canonical algorithm needs on the wire (a qualitative predictor).
EXPECT = {
    "delay":      "delay line: needs DRw>=1 and DRr>=1 (write in, read the tap); feedback = a cMAC",
    "reverb":     "all-pass/comb network: many DRw+DRr, several cMAC (diffuser + damping gains)",
    "modulation": "LFO-swept delay: DRw/DRr for the swept tap + cMAC wet/dry (chorus/ensemble); flanger/phaser add feedback",
    "eq/filter":  "biquad chain: cMAC-dominated (5 per band), bqp state pairs, little/no DRAM",
    "distortion": "waveshaper: a tbl LUT (or rail clip) + a tone cMAC; little/no DRAM",
    "exciter":    "nonlinearity->bandpass: tbl + cMAC; little DRAM",
    "dynamics":   "level detector + gain: cMAC smoothers, no DRAM (except NO OPERATION = ~nothing)",
    "pitch":      "crossfaded variable delay: DRw + two swept DRr + accB crossfade",
    "combination": "serial chain: the union of its named stages' idioms",
    "rotary":     "rotary speaker: LFO-swept delay + filter cMAC",
    "other":      "-",
}


def is_dram(w):
    # external delay-DRAM access = a class-1 ESCAPE word (hi12 bit 11 set).
    # addr8 bit 6 is the direction (0x60-region = WRITE, else READ; adjudication-round5).
    return D.class4(w) == 1 and (D.hi12(w) & 0x800)


def fingerprint(words):
    f = dict(words=len(words), DRw=0, DRr=0, cMAC=0, tbl=0, bqp=0, accB=0, st=0)
    for w in words:
        if is_dram(w):
            if D.addr8(w) & 0x40:
                f["DRw"] += 1
            else:
                f["DRr"] += 1
        if (D.class4(w) & 0x8) and not D.c_format(w):
            f["cMAC"] += 1
        if D.class4(w) == 6:
            f["tbl"] += 1
        if D.lo_act(w) in (0x0D, 0x0E):
            f["bqp"] += 1
        if D.lo_src(w) == 0x11:
            f["accB"] += 1
        if (D.hi12(w) & 0x200) and (D.lo12(w) & 0x010):   # ST flag + mem-write bit
            f["st"] += 1
    return f


def load_dsm(path):
    name, words = None, []
    for ln in open(path):
        m = NAMELINE.search(ln)
        if m:
            name = m.group(1)
        m = WORD.match(ln)
        if m:
            words.append(int(m.group(1), 16))
    return name, words


def family_of(name):
    n = (name or "").upper()
    if "+" in n:              return "combination"
    if "REVERB" in n:         return "reverb"
    if "DELAY" in n:          return "delay"
    if "PITCH" in n:          return "pitch"
    if "ROTARY" in n:         return "rotary"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "ENSEMBLE", "VIBRATO",
                            "AUTO PAN", "RING MOD", "HAAS")):          return "modulation"
    if any(k in n for k in ("DISTORT", "OVERDRIVE", "FUZZ")):          return "distortion"
    if any(k in n for k in ("PARAMETRIC EQ", "ENHANCER", "WAH")):      return "eq/filter"
    if any(k in n for k in ("COMPRESS", "NO OPERATION", "SLOW ATT")):  return "dynamics"
    if any(k in n for k in ("EXCITER", "NOISE")):                      return "exciter"
    return "other"


def collect(tree):
    out = {}
    for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
        if os.path.basename(p) in ("index.dsm",):
            continue
        name, words = load_dsm(p)
        if name and words:
            out[name] = fingerprint(words)
    return out


def verdict(fam, f):
    """one-line match note vs the family's canonical need."""
    dram = f["DRw"] + f["DRr"]
    if fam == "delay":       return "OK" if f["DRw"] and f["DRr"] else "?? no read/write pair"
    if fam == "reverb":      return "OK" if dram >= 4 else "?? few DRAM taps"
    if fam == "modulation":  return "OK" if dram >= 1 else "coeff-only (LFO in C-RAM?)"
    if fam == "eq/filter":   return "OK biquad" if f["cMAC"] >= 8 else "?? light cMAC"
    if fam == "distortion":  return "OK" if f["tbl"] or f["cMAC"] else "??"
    if fam == "dynamics":    return "OK bypass" if f["words"] < 12 else "OK (detector)"
    if fam == "pitch":       return "OK" if dram and f["accB"] else "check crossfade"
    return "-"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", action="store_true")
    a = ap.parse_args()
    kn = collect(os.path.join(HERE, "..", "disasm"))
    ws = collect(os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm"))

    if a.compare:
        print("KN5000 vs WSA1R structural fingerprint (effects present on BOTH):\n")
        print("effect               |  KN5000 w/cMAC/DRw+r/tbl  |  WSA1R w/cMAC/DRw+r/tbl")
        for nm in sorted(set(kn) & set(ws)):
            k, w = kn[nm], ws[nm]
            print("%-20s |  %3d %3d %2d+%-2d %2d       |  %3d %3d %2d+%-2d %2d"
                  % (nm[:20], k["words"], k["cMAC"], k["DRw"], k["DRr"], k["tbl"],
                     w["words"], w["cMAC"], w["DRw"], w["DRr"], w["tbl"]))
        return 0

    for label, table in (("KN5000", kn), ("WSA1R", ws)):
        print("\n===== %s effect topology fingerprint =====" % label)
        print("effect               fam         w  cMAC DRw DRr tbl bqp accB st  verdict")
        for nm in sorted(table, key=lambda n: (family_of(n), n)):
            f = table[nm]
            fam = family_of(nm)
            print("%-20s %-10s %3d %4d %3d %3d %3d %3d %4d %2d  %s"
                  % (nm[:20], fam, f["words"], f["cMAC"], f["DRw"], f["DRr"],
                     f["tbl"], f["bqp"], f["accB"], f["st"], verdict(fam, f)))
    print("\nCanonical topology expectation per family:")
    for fam, exp in EXPECT.items():
        if exp != "-":
            print("  %-11s %s" % (fam, exp))
    return 0


if __name__ == "__main__":
    sys.exit(main())
