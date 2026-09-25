#!/usr/bin/env python3
r"""Name five prom_c routines of the part-parameter family, with their evidence.

QUESTION THIS ANSWERS
    Which unnamed routines around Voice_ApplyParamChange_Dispatch can be named
    from instruction operands alone, in the convention the file already uses
    (PartRec_ApplyParam_<part-record offset>, "framed, not content")?  Five,
    each asserted here against the ROM:

      sub_FAD561 -> Scale7Bit_ByDepth_UniOrBipolar_x25
          the sibling of Scale7Bit_ByDepth_UniOrBipolar (x32) with x25: bit 7 of
          record +1 picks the arm (0xFAD56C `and A,0x80`); bipolar
          (v*25 - 0x640)/63 or /64 (0xFAD576, 0xFAD57C, 0xFAD588, 0xFAD594),
          unipolar v*25/127 (0xFAD5A1, 0xFAD5A9); then * record +2 >> 6
          (0xFAD5B2, 0xFAD5BB).
      sub_FAEACE -> PartRec_ApplyParam_0001  Scale7Bit_ByDepth_UniOrBipolar (0xFAEADC)
          then PartRec_SetFittingOffset_0001 (0xFAEAED); table entry 27.
      sub_FAEC21 -> PartRec_ApplyParam_0009  the x25 scaler (0xFAEC30) then
          PartRec_SetMovementRate_0009 (0xFAEC41), then per voice of the part
          Pack104_RefreshMovementRate_ForVoice (0xFAEC63); table entry 32.
      sub_FAEC71 -> PartRec_ApplyParam_000B  Scale7Bit_ByDepth_UniOrBipolar (0xFAEC7F)
          then PartRec_SetMutingOffset_000B; table entry 34.
      sub_FAEC9C -> PartRec_ApplyParam_000D  Scale7Bit_ByDepth_UniOrBipolar (0xFAECAA)
          then PartRec_SetTuningOffset_000D (0xFAECBB); table entry 35.
    "table entry" = the index in Voice_ApplyParamChange_Dispatch's 49-entry table
    at 0xFAF08F whose word points at the arm calling the routine (raw target
    code = entry + 1, per that routine's header).

    Four more candidates (sub_FAEAF9, sub_FAEB65, sub_FAEBD1, sub_FAECC7) and
    the three Rec8644 slot writers are NOT renamed: probes under wsa1/notes/
    that this lane does not own name them.

RUN
    python3 notes/lanes/promcd-2026-09-25/rename_param_appliers.py [--apply]
    (the rename itself is scripts/renaming/rename_promcd_param_appliers.sed)
"""
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SED = os.path.join(ROOT, "scripts", "renaming", "rename_promcd_param_appliers.sed")
CODE = [(0xFAD56C, "c9 cc 80"), (0xFAD576, "d8 09 19 00"), (0xFAD57C, "d8 ca 40 06"), (0xFAD588, "d8 0b 3f 00"),
        (0xFAD594, "d9 0b 40 00"), (0xFAD5A1, "d9 09 19 00"), (0xFAD5A9, "d9 0b 7f 00"), (0xFAD5B2, "89 02 21"),
        (0xFAD5BB, "d8 ed 06"),
        (0xFAEADC, "1e e3 ea"), (0xFAEAED, "1d 9e 58 fc"), (0xFAEC30, "1e 2e e9"), (0xFAEC41, "1d 75 61 fc"),
        (0xFAEC63, "1d 9b 62 fc"), (0xFAEC7F, "1e 40 e9"), (0xFAECAA, "1e 15 e9"), (0xFAECBB, "1d 4f 65 fc")]
ENTRIES = {0xFAF238: 27, 0xFAF270: 32, 0xFAF27E: 34, 0xFAF28C: 35}
NOTE = {
    "sub_FAD561": ["★ NAMED 2026-09-25 (lane promcd): Scale7Bit_ByDepth_UniOrBipolar_x25.",
                   "Scale7Bit_ByDepth_UniOrBipolar's arithmetic with x25 in place of x32: bit 7 of",
                   "record +1 picks the arm (0xFAD56C); bipolar (v*25 - 0x640) / 63 or / 64",
                   "(0xFAD576-0xFAD594), unipolar v*25 / 127 (0xFAD5A1, 0xFAD5A9); then * record +2",
                   ">> 6 (0xFAD5B2, 0xFAD5BB).  So 0..25, or about -25..+25, scaled by the depth byte."],
    "sub_FAEACE": ["★ NAMED 2026-09-25 (lane promcd): PartRec_ApplyParam_0001 -- scales its value with",
                   "Scale7Bit_ByDepth_UniOrBipolar (0xFAEADC) and stores it with",
                   "PartRec_SetFittingOffset_0001 (0xFAEAED).  Reached from entry 27 of",
                   "Voice_ApplyParamChange_Dispatch's table (arm 0xFAF238).  Framed by the offset,",
                   "as PartRec_ApplyParam_0023 and its siblings are."],
    "sub_FAEC21": ["★ NAMED 2026-09-25 (lane promcd): PartRec_ApplyParam_0009 -- scales with",
                   "Scale7Bit_ByDepth_UniOrBipolar_x25 (0xFAEC30), stores with",
                   "PartRec_SetMovementRate_0009 (0xFAEC41), then for each voice of the part calls",
                   "Pack104_RefreshMovementRate_ForVoice (0xFAEC63).  Entry 32 (arm 0xFAF270)."],
    "sub_FAEC71": ["★ NAMED 2026-09-25 (lane promcd): PartRec_ApplyParam_000B -- scales with",
                   "Scale7Bit_ByDepth_UniOrBipolar (0xFAEC7F) and stores with",
                   "PartRec_SetMutingOffset_000B.  Entry 34 (arm 0xFAF27E)."],
    "sub_FAEC9C": ["★ NAMED 2026-09-25 (lane promcd): PartRec_ApplyParam_000D -- scales with",
                   "Scale7Bit_ByDepth_UniOrBipolar (0xFAECAA) and stores with",
                   "PartRec_SetTuningOffset_000D (0xFAECBB).  Entry 35 (arm 0xFAF28C)."],
}


def check():
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        assert C[a - 0xF80000:a - 0xF80000 + len(want)] == want, hex(a)
    t = [struct.unpack_from("<I", C, 0xFAF08F - 0xF80000 + 4 * i)[0] for i in range(49)]
    for arm, e in ENTRIES.items():
        assert t[e] == arm, (hex(arm), e)
    print("  %d encodings and %d table entries hold" % (len(CODE), len(ENTRIES)))


def apply():
    mc = os.path.join(W, "prom_c", "midi", "midi_controllers.s")
    raw = open(mc, "rb").read().decode("latin-1")
    lines = raw.split("\n")
    out = []
    for i, ln in enumerate(lines):
        m = re.match(r"^(sub_[0-9A-F]{6}):$", ln)
        if m and m.group(1) in NOTE and out and out[-1].startswith("; ----"):
            dash = out.pop()
            out.extend("; " + x.encode("utf-8").decode("latin-1") for x in NOTE[m.group(1)])
            out.append(dash)
        out.append(ln)
    data = "\n".join(out).encode("latin-1")
    open(mc, "wb").write(data)
    files = subprocess.run(["git", "grep", "-l", "-E", "sub_FAD561|sub_FAEACE|sub_FAEC21|sub_FAEC71|sub_FAEC9C",
                            "--", "wsa1/prom_c"], cwd=ROOT, capture_output=True, text=True).stdout.split()
    subprocess.run(["sed", "-i", "-f", SED] + [os.path.join(ROOT, f) for f in files], check=True,
                   env=dict(os.environ, LC_ALL="C"))
    print("applied: 5 headers, sed over %d files: %s" % (len(files), " ".join(files)))


if __name__ == "__main__":
    check()
    if "--apply" in sys.argv:
        apply()
