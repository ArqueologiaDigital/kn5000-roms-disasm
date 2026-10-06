#!/usr/bin/env python3
r"""part_param_enable_mask_retype.py -- the per-part parameter-enable masks the Lsw* functions test (v10/v9/v7).

QUESTION ANSWERED
-----------------
naka_technichord_strings +0xF35C (120 B) was the asm slice SdpartUpdatePartUI_Data and 130 placeholder C members.
Every part-parameter ApFunction (LswVolume, LswPan, LswReverb, LswDSPEffect ... -- the firmware's own names, Murai
ApFunction table) loads it with `lda xix, (<this>:24)`, adds 4 * part index and tests ONE bit of that u32 before it
lets the parameter be edited (`bit N, wa` in <Lsw>_CheckEnabled).  So it is uint32_t[30], one mask per part, and the
bit numbers come from the code (asserted for every Lsw function, every tree):
    15 Volume / Mute   14 Pan   13 Reverb   12 DSPEffect   11 Sustain   10 SustainLength   9 KeyShift   8 Tuning
    7 BendRange   6 GlidePedal   5 SustainPedal   4 KeyScaling   3 DigitalEffect   2 AfterTouch   1 MidiChannel
    0 LocalControl
(bits 16, 30 and 31 are set in some masks but no Lsw function tests them).  The script types the range in C as
`uint32_t PartParam_EnableMask[30]` with each tree's own values, renames the asm label (SdpartUpdatePartUI_Data ->
PartParam_EnableMask) across the tree, and replaces the [nakarest] note with a header.

RUN (repository root)
    python3 scripts/converters/part_param_enable_mask_retype.py [--apply]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all
"""
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402

APPLY = "--apply" in sys.argv
BLOB, OFF, N = "naka_technichord_strings", 0xF35C, 30
OLD, NEW = "SdpartUpdatePartUI_Data", "PartParam_EnableMask"
BITS = {"LswVolume": 15, "LswMute": 15, "LswPan": 14, "LswReverb": 13, "LswDSPEffect": 12, "LswDigitalEffect": 3,
        "LswSustain": 11, "LswSustainLength": 10, "LswKeyShift": 9, "LswTuning": 8, "LswBendRange": 7,
        "LswGlidePedal": 6, "LswSustainPedal": 5, "LswKeyScaling": 4, "LswAfterTouch": 2, "LswMidiChannel": 1,
        "LswLocalControl": 0}
HEADER = [
    "; PartParam_EnableMask -- 30 x u32, one mask per part index: which part parameters may be edited.  Every Lsw*",
    "; part-parameter function loads it, adds 4 * part and tests one bit (`bit N, wa` in <Lsw>_CheckEnabled): 15",
    "; Volume / Mute, 14 Pan, 13 Reverb, 12 DSPEffect, 11 Sustain, 10 SustainLength, 9 KeyShift, 8 Tuning,",
    "; 7 BendRange, 6 GlidePedal, 5 SustainPedal, 4 KeyScaling, 3 DigitalEffect, 2 AfterTouch, 1 MidiChannel,",
    "; 0 LocalControl.  Typed in ui_widgets/naka_technichord_strings.c (scripts/converters/part_param_enable_mask_retype.py).",
]


def check_bits(tree):
    L = open(os.path.join(ROOT, tree, "maincpu/ui/drawbar_panel_ui.s"), "rb").read().decode("latin-1").split("\n")
    seen = {}
    fn = None
    for x in L:
        m = re.match(r'^(Lsw[A-Za-z]+):', x)
        if m:
            fn = m.group(1)
        mb = re.match(r'^\s*bit\s+(\d+),\s*wa\s*(;.*)?$', x)
        if mb and fn in BITS:
            seen.setdefault(fn, set()).add(int(mb.group(1)))
    for fn, bit in BITS.items():
        assert seen.get(fn) == {bit}, (tree, fn, seen.get(fn))


def main():
    for tree in ("v10", "v9", "v7"):
        check_bits(tree)
        b = open(os.path.join(ROOT, tree, "maincpu/includes/generated", BLOB + ".bin"), "rb").read()
        vals = struct.unpack_from("<%dI" % N, b, OFF)
        print("%s: bits asserted for %d Lsw functions; masks %s" % (tree, len(BITS), " ".join("%08X" % v for v in vals[:3])))
        if not APPLY:
            continue
        c = os.path.join(ROOT, tree, "maincpu/ui_widgets", BLOB + ".c")
        if NEW not in open(c, encoding="latin-1").read():
            cb = M.CBlob(c)
            rows = ["        " + ", ".join("0x%08X" % v for v in vals[r:r + 6]) + ",  /* parts %d-%d */" % (r, min(r + 5, N - 1))
                    for r in range(0, N, 6)]
            cb.retype(OFF, OFF + 4 * N, [M.NewMember("uint32_t", NEW, "[%d]" % N, 4 * N, "{\n" + "\n".join(rows) + "\n    }",
                                                     ["    /* PartParam_EnableMask: [part index] = bit set of the part parameters"
                                                      " that may be edited (bit numbers: the asm header) */"])], b)
            data = cb.render().encode("latin-1")
            open(c + ".tmp", "wb").write(data)
            os.replace(c + ".tmp", c)
        p = os.path.join(ROOT, tree, "maincpu/ui_widgets/technichord_string_data.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        k = next((i for i, x in enumerate(L) if x.startswith(OLD + ":")), None)
        if k is not None:
            j = k
            while L[j - 1].startswith("; [nakarest]"):
                j -= 1
            L[j:k] = HEADER
            data = "\n".join(L).encode("latin-1")
            open(p + ".tmp", "wb").write(data)
            os.replace(p + ".tmp", p)
        hit = subprocess.run(["grep", "-rlw", OLD, os.path.join(ROOT, tree, "maincpu"), "--include=*.s", "--include=*.c",
                              "--include=*.ld"], capture_output=True, text=True).stdout.split()
        if hit:
            subprocess.run(["sed", "-i", r"s/\b%s\b/%s/g" % (OLD, NEW)] + hit, check=True)
        print("  %s: C typed, asm headed, label renamed in %d files" % (tree, len(hit)))


if __name__ == "__main__":
    main()
