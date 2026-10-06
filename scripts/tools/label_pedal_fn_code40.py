#!/usr/bin/env python3
"""label_pedal_fn_code40.py -- PanelAction_PedalFunctionHandlers[0] gets a label: PanelAction_PedalFn_Code40 (v10/v9/v7).

QUESTION IT ANSWERS
  PanelAction_PedalFunctionHandlers (ui_widgets/extension_device_screens.s, a naka_extension_device.c object) is the
  22-entry handler table of the foot-pedal functions.  Its entry [0] is the routine right after
  PanelAction_DispatchPedalFunction's `ret`, which had no label.  The C spelled it
  `NAKA_ADDR(PanelAction_DispatchPedalFunction) + 36`, and the dispatch census counted the unframed run as not used
  (nolabel/num; census --compare: unframed_not_used 0 -> 1 in v10/v9/v7, first seen after the round-3 retype).
  PanelAction_PedalAssignHandlerIndex maps exactly one assignment code, 0x40, to handler 0, so the routine is
  named after that code.  The script:
    - asserts the C operand and that dispatcher + 36 is the instruction after the dispatcher's `call (xhl)` / `ret`;
    - places the label and a header;
    - spells the C entry `NAKA_ADDR(PanelAction_PedalFn_Code40)`, swaps the extern and the link-script symbol;
    - updates the table header's "unlabelled routine" sentence.
  v7: run scripts/build/regenerate_v7_c_divergence.py --apply before make.  The byte gate is the proof.

RUN (repository root, built tree)
  python3 scripts/tools/label_pedal_fn_code40.py [--apply]
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
TREES = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}
OLD, NEW = "PanelAction_DispatchPedalFunction", "PanelAction_PedalFn_Code40"
HDR = ["; PanelAction_PedalFn_Code40: Foot-pedal function [0] of PanelAction_PedalFunctionHandlers, the only handler that",
       ";   PanelAction_PedalAssignHandlerIndex gives to assignment code 0x40.  Unless the mode is 17 or (0x34CD) bit 3 is",
       ";   set, it sets (0x90F9) bit 1 and, for each of the up-to-16 part tags in the 0xFF-terminated list at 0x90FB whose",
       ";   SndParam_LookupViaEncode(tag, 0x601) is 1, posts the panel event {tag, 4, 8 if the pedal event's bytes +2 and",
       ";   +3 share a bit else 0, 8}.  [INFERENCE] 0x40 is MIDI CC64, so this is probably the sustain function.  Basis:",
       ";   table + body."]


def rw(p, s):
    data = s.encode("latin-1")
    with open(p + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(p + ".tmp", p)


def main():
    apply = "--apply" in sys.argv
    for tree, stem in TREES.items():
        syms = {}
        for ln in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs", stem + ".llvm.elf")],
                                 capture_output=True, text=True, check=True).stdout.split("\n"):
            f = ln.split()
            if len(f) == 3:
                syms.setdefault(f[2], int(f[0], 16))
        d = os.path.join(ROOT, tree, "maincpu")
        a = syms[OLD] + 36
        # .s: the label after the dispatcher's `call (xhl)` / `ret`
        ps = os.path.join(d, "audio", "audio_control_engine.s")
        L = open(ps, "rb").read().decode("latin-1").split("\n")
        k = L.index(OLD + ":")
        r = next(i for i in range(k, k + 20) if L[i].strip() == "ret" and L[i - 1].split() == ["call", "(xhl)"])
        rom = open(os.path.join(ROOT, "original_ROMs", stem + ".rom"), "rb").read()
        assert rom[a - 0xE00000 - 3:a - 0xE00000] == bytes.fromhex("b3e80e"), (tree, rom[a - 0xE00003:a - 0xE00000].hex())
        L[r + 1:r + 1] = HDR + [NEW + ":"]
        # C operand, extern, link script
        pc = os.path.join(d, "ui_widgets", "naka_extension_device.c")
        C = open(pc, "rb").read().decode("latin-1")
        assert C.count("(NAKA_ADDR(%s) + 36)" % OLD) == 1 and C.count(OLD) == 2, tree
        C = C.replace("(NAKA_ADDR(%s) + 36)" % OLD, "NAKA_ADDR(%s)" % NEW)
        C = C.replace("extern const char %s;" % OLD, "extern const char %s;" % NEW)
        pl = os.path.join(d, "ui_widgets", "naka_extension_device_link.ld")
        LD = open(pl, "rb").read().decode("latin-1")
        old_ld = "%s = 0x%08X;" % (OLD, syms[OLD])
        assert LD.count(old_ld) == 1, (tree, old_ld)
        LD = LD.replace(old_ld, "%s = 0x%08X;" % (NEW, a))
        pt = os.path.join(d, "ui_widgets", "extension_device_screens.s")
        T = open(pt, "rb").read().decode("latin-1")
        old_t = "[0] is the unlabelled routine right after Helper4's `ret`;"
        assert T.count(old_t) == 1, tree
        T = T.replace(old_t, "[0] is PanelAction_PedalFn_Code40, right after its `ret`;")
        print("%s: %s = 0x%06X (%s + 36)" % (tree, NEW, a, OLD))
        if apply:
            rw(ps, "\n".join(L))
            rw(pc, C)
            rw(pl, LD)
            rw(pt, T)


if __name__ == "__main__":
    main()
