#!/usr/bin/env python3
"""Did this pass DESTROY anything in prom_a's listing, or only ADD to it?

QUESTION IT ANSWERS
-------------------
  "Every comment line and every label that was in prom_a at commit REF -- is it
   still there, verbatim?"

★ WHY THE BYTE GATE IS NOT ENOUGH.  `scripts/analysis/assert_byte_identical.py`
proves the file still assembles to the ROM.  Comments and label NAMES assemble
to nothing, so a pass that deleted a 400-line documentation header, or quietly
renamed a semantic label back to `sub_XXXXXX`, would pass the gate in silence.
This is the instrument for that, and it is the one a naming pass owes a
reviewer.

WHAT IT CHECKS
  COMMENTS  every `;`-comment line of REF's copy, compared as a MULTISET after
            stripping trailing whitespace.  A multiset, not a set: deleting one
            of two identical lines is a deletion.
  LABELS    every column-0 label of REF's copy is still defined.  A label that
            is gone must be declared in RENAMES below, and its new name must be
            present -- so a rename is ALLOWED but must be DECLARED, and an
            undeclared disappearance fails.
  ⚠ It says nothing about lines that were ADDED.  Adding is the point.

USAGE
    python3 notes/prom_a_preservation_check.py              # vs HEAD
    python3 notes/prom_a_preservation_check.py --ref <rev>  # vs any commit
    python3 notes/prom_a_preservation_check.py --list       # the deltas
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_text, image_text_at_rev      # noqa: E402

PATH = "prom_a/wsa1_prom_a.s"
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')

# Renames this pass declares.  old -> new.  A label missing from the working
# copy is a FAILURE unless it is a key here and its value is present.
# ⚠ DECLARED STATICALLY, not read back from the applier.  The applier's --plan
# is empty once --apply has run -- there is nothing left to rename -- so a probe
# that asked it would forgive every loss the moment the work was done.  A
# declaration has to survive the thing it declares.
RENAMES = {
    "sub_F95765": "ScreenLeave_GateArrayCheck",
    "sub_F95766": "ScreenButton_GateArrayCheck",
    "sub_F95795": "ScreenLeave_PanelCpuCheck",
    "sub_F95796": "ScreenButton_PanelCpuCheck",
    "sub_F95890": "ScreenLeave_SineWaveCheckMode",
    "sub_F95891": "ScreenButton_SineWaveCheckMode",
    "sub_F959BD": "ScreenLeave_PanelSwLedCheck",
    "sub_F959BE": "ScreenButton_PanelSwLedCheck",
    "sub_F99831": "ScreenLeave_SysexBulkDump_Entry",
    "sub_F99835": "ScreenButton_SysexBulkDump_Entry",
    "sub_F99848": "ScreenLeave_GeneralMidiMode_Entry",
    "sub_F9984C": "ScreenButton_GeneralMidiMode_Entry",
    "sub_F9A26D": "ScreenLeave_MidiTotalMode",
    "sub_F9A26F": "ScreenButton_MidiTotalMode",
    "sub_F9A754": "ScreenLeave_MidiRealtimeMessages",
    "sub_F9A756": "ScreenButton_MidiRealtimeMessages",
    "sub_F9AA4F": "ScreenLeave_MidiInputOutputFilter",
    "sub_F9AA51": "ScreenButton_MidiInputOutputFilter",
    "sub_F9B05E": "ScreenLeave_MidiOutProgramChange",
    "sub_F9B060": "ScreenButton_MidiOutProgramChange",
    "sub_FE8060": "ScreenButton_Sequencer",
    "sub_FE8165": "ScreenLeave_Sequencer",
    "sub_FF431C": "PanelButtonDispatch_DiskMenu",
    "sub_FF457C": "ScreenLeave_MidiFileDirectPlay",
    "sub_FF4596": "PanelButtonDispatch_MidiFileDirectPlay",
    "sub_FF45F6": "LcdKeyRow2_MidiFileDirectPlay",
    "sub_FF4986": "ScreenLeave_DiskL0adFile",
    "sub_FF4995": "PanelButtonDispatch_DiskL0adFile",
    "sub_FF4A91": "LcdKeyRow3_DiskL0adFile",
    "sub_FF4ACB": "LcdKeyRow4_DiskL0adFile",
    "sub_FF4D5D": "LcdKeyRow5_DiskL0adFile",
    "sub_FF520C": "ScreenLeave_MidiFileL0ad",
    "sub_FF522F": "PanelButtonDispatch_MidiFileL0ad",
    "sub_FF52E2": "LcdKeyRow2_MidiFileL0ad",
    "sub_FF548A": "PageDispatch_DiskSaveFile",
    "sub_FF572E": "PanelButtonDispatch_DiskSaveFile",
    "sub_FF5A69": "LcdKeyRow2_DiskSaveFile_Page1",
    "sub_FF5C3E": "PageDispatch_MidiFileSave",
    "sub_FF5ED1": "PanelButtonDispatch_MidiFileSave",
    "sub_FF654F": "ScreenLeave_FloppyDiskFormatSelectType",
    "sub_FF6550": "PanelButtonDispatch_FloppyDiskFormatSelectType",
    "sub_FF66A9": "ScreenLeave_FloppyDiskFormatAreYouSure",
    "sub_FF66AA": "PanelButtonDispatch_FloppyDiskFormatAreYouSure",
    "sub_FF672D": "PageDispatch_L0adSingleS0und",
    "sub_FF68D8": "PanelButtonDispatch_L0adSingleS0und",
    "sub_FF6DB7": "PageDispatch_L0adSingleC0mbination",
    "sub_FF6F21": "PanelButtonDispatch_L0adSingleC0mbination",
}


def _renames():
    return RENAMES


def ref_text(ref):
    """★ BOTH SIDES ARE READ AS THE IMAGE, not as the file.

    A `git show <rev>:prom_a/wsa1_prom_a.s` on one side and an `open()` on the
    other compares two FILES, and this tree splits images into a primary plus
    included parts.  The day prom_a is split, that comparison would report the
    entire body as LOST -- or, worse, as unchanged in a tree where the primary
    is a header.  asm_source resolves both sides the way llvm-mc does, so the
    answer is about the IMAGE and survives a split on either side."""
    return image_text_at_rev(ROOT, PATH, ref)


def comments(text):
    out = collections.Counter()
    for ln in text.splitlines():
        s = ln.rstrip()
        if s.lstrip().startswith(";"):
            out[s] += 1
    return out


def labels(text):
    return {m.group(1) for m in
            (LABEL.match(ln) for ln in text.splitlines()) if m}


def main():
    argv = sys.argv[1:]
    ref = argv[argv.index("--ref") + 1] if "--ref" in argv else "HEAD"
    old = ref_text(ref)
    new = image_text(ROOT, PATH)

    co, cn = comments(old), comments(new)
    lost = co - cn                       # Counter subtraction: multiset delta

    # ⚠ A DECLARED RENAME REWRITES THE COMMENTS THAT CITE THE OLD NAME, and a
    # naive multiset diff would call every one of those a deletion.  A lost line
    # that becomes a PRESENT line under the declared substitutions is an UPDATE,
    # not a loss -- and it is counted and printed separately rather than
    # forgiven silently, because "how many comments did this pass rewrite" is
    # itself a number a reviewer wants.
    updated = collections.Counter()
    for line, n in list(lost.items()):
        sub = line
        for o, w in RENAMES.items():
            sub = re.sub(r'\b%s\b' % o, w, sub)
        if sub != line and cn.get(sub, 0) >= 1:
            updated[line] += n
            del lost[line]
    lo, ln_ = labels(old), labels(new)
    gone = sorted(lo - ln_)
    undeclared = [g for g in gone if RENAMES.get(g) not in ln_]
    declared = [g for g in gone if RENAMES.get(g) in ln_]

    print("prom_a preservation, working tree vs %s" % ref)
    print("  comment lines   %6d -> %6d   (+%d added)"
          % (sum(co.values()), sum(cn.values()),
             sum(cn.values()) - sum(co.values())))
    print("  comment lines REWRITTEN by a declared rename: %d"
          % sum(updated.values()))
    print("  LOST comment lines: %d" % sum(lost.values()))
    print("  labels          %6d -> %6d" % (len(lo), len(ln_)))
    print("  labels gone: %d, of which DECLARED renames: %d, UNDECLARED: %d"
          % (len(gone), len(declared), len(undeclared)))
    if "--list" in argv:
        for line, n in lost.items():
            print("    LOST x%d  %s" % (n, line[:110]))
        for g in undeclared:
            print("    UNDECLARED LABEL LOSS  %s" % g)
        for g in declared:
            print("    renamed  %s -> %s" % (g, RENAMES[g]))
        for line, n in updated.items():
            print("    rewritten x%d  %s" % (n, line[:110]))
    bad = sum(lost.values()) + len(undeclared)
    print("FAILURES: %d" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
