#!/usr/bin/env python3
"""Does Technics' own user guide say which features are keyboard-only?

QUESTION THIS ANSWERS
    The reference names the model that refuses the SEQUENCER dump and the tempo
    message as the rack.  The firmware names neither model -- it reads a
    hardware input and compares it against 1 or 2 -- so that naming needs a
    source outside the program.

    This is one of the two.  The published user guide marks keyboard-only
    features with the text "(WSA1)", and this counts them and shows the
    headings, so the claim in the reference's "Which machine is which" note can
    be rechecked rather than believed.

    The other source is the service documentation for that hardware input; it
    is an image-only PDF and is not machine-checkable here.

WHERE THE SIGNAL IS
    KN7000/WSA1R_files/WSA1-Practical Applications.pdf -- the user guide, the
    only one of the WSA1 PDFs with a usable text layer.  pdftotext returns
    about 202 KB of text from it; the service manual and technical guide return
    nothing at all, being page images.

RUN
    python3 wsa1/notes/sysex-probes/manual_model_markers.py
    python3 wsa1/notes/sysex-probes/manual_model_markers.py --all

RESULT (2026-09-21)
    59 occurrences of "(WSA1)", 2 of "(WSA1R)".

    The decisive one is the section heading "Part VII Sequencer (WSA1)": the
    sequencer is a keyboard feature.  A model without a sequencer has nothing
    to put in a SEQUENCER bulk dump and no use for a tempo message, which is
    exactly the pair of System Exclusive functions the other model refuses.
"""
import os
import subprocess
import sys

GUIDE = ("/home/fsanches/compartilhado/KN7000/WSA1R_files/"
         "WSA1-Practical Applications.pdf")


def main():
    if not os.path.isfile(GUIDE):
        raise SystemExit("user guide not found at %s" % GUIDE)
    text = subprocess.run(["pdftotext", GUIDE, "-"],
                          capture_output=True, text=True).stdout
    if len(text) < 100000:
        raise SystemExit("text layer too small (%d bytes) -- wrong PDF?" % len(text))

    lines = text.splitlines()
    kbd = [(n, l.strip()) for n, l in enumerate(lines, 1) if "(WSA1)" in l]
    rack = [(n, l.strip()) for n, l in enumerate(lines, 1) if "(WSA1R)" in l]

    print("user guide: %d bytes of text" % len(text))
    print("  (WSA1)  keyboard-only markers: %d" % len(kbd))
    print("  (WSA1R) rack-only markers:     %d" % len(rack))

    heads = [(n, l) for n, l in kbd if l.lower().startswith("part ")]
    print("\nsection headings carrying the keyboard marker:")
    for n, l in heads:
        print("  line %-5d %s" % (n, l))
    assert any("sequencer" in l.lower() for _, l in heads), \
        "expected a Sequencer section marked (WSA1)"

    if "--all" in sys.argv:
        print("\nevery occurrence:")
        for n, l in kbd:
            print("  %-5d %s" % (n, l[:96]))
    print("\nOK")


if __name__ == "__main__":
    main()
