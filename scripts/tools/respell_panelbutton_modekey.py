#!/usr/bin/env python3
"""respell_panelbutton_modekey.py -- PanelButton_ModeKey's `.ascii "n=@.\\x9d\\xed"` + `nop` are two instructions (v10/v9/v7).

QUESTION IT ANSWERS
  PanelButton_ModeKey (audio/audio_control_engine.s) chooses a byte map by the panel event index (RAM 0x8E90).  For
  index 1 the source held
      .ascii "n=@.\\x9d\\xed"
      nop
  These 7 bytes, 6e 3d 40 2e 9d ed 00, are
      jr  nz, <epilogue>                 6e 3d    (the index is not 1 either: leave)
      ld  xwa, 0x00ED9D2E                40 2e 9d ed 00
  0x00ED9D2E is PanelButton_ModeKeyCodes (analysis/nakarest-slices/reviewed-2026-10-06-r2b2.json), and the
  jr target is the routine's `pop xiz` / `ret`, which gets the label PanelButton_ModeKey_Epilogue.  This was found by
  the round-2 triage of the nakarest slices and confirmed with unidasm.  The script:
    - asserts the 7 ROM bytes at the line's address;
    - asserts the jr target and the immediate (from each tree's ELF);
    - writes the two instructions and places the epilogue label.
  The byte gate checks the encodings.

RUN (repository root, built tree)
  python3 scripts/tools/respell_panelbutton_modekey.py [--apply]
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
TREES = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}


def main():
    apply = "--apply" in sys.argv
    for tree, stem in TREES.items():
        syms = {}
        for ln in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs", stem + ".llvm.elf")],
                                 capture_output=True, text=True, check=True).stdout.split("\n"):
            f = ln.split()
            if len(f) == 3 and f[1] in "tT":
                syms.setdefault(f[2], int(f[0], 16))
        rom = open(os.path.join(ROOT, "original_ROMs", stem + ".rom"), "rb").read()
        p = os.path.join(ROOT, tree, "maincpu", "audio", "audio_control_engine.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        k = next(i for i, x in enumerate(L) if x.strip().startswith(".ascii") and '"n=@.' in x)
        assert L[k + 1].strip() == "nop" and L[k + 2].split()[:1] == ["jr"], (tree, L[k + 1], L[k + 2])
        j = L.index("PanelButton_ModeKey_Join3:", k)
        assert L[j + 1].split()[0] == "calr" and L[j + 2].split() == ["pop", "xiz"] and L[j + 3].strip() == "ret"
        base = syms["PanelButton_ModeKey_Join3"] + 3                 # the epilogue: after `calr PanelEvent_Post`
        start = base - 2 - 0x3D                                     # where the jr nz must sit
        assert rom[start - 0xE00000:start - 0xE00000 + 7] == bytes.fromhex("6e3d402e9ded00"), tree
        assert syms["PanelButton_ModeKeyCodes"] == 0xED9D2E, tree
        print("%s: jr nz at 0x%06X -> 0x%06X (PanelButton_ModeKey_Epilogue), ld xwa, PanelButton_ModeKeyCodes" % (tree, start, base))
        if not apply:
            continue
        L[j + 2:j + 2] = ["PanelButton_ModeKey_Epilogue:"]
        L[k:k + 2] = ["\tjr\tnz, PanelButton_ModeKey_Epilogue",
                      "\tld\txwa, PanelButton_ModeKeyCodes"]
        data = "\n".join(L).encode("latin-1")
        with open(p + ".tmp", "wb") as fh:
            fh.write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
