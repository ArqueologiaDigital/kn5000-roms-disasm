#!/usr/bin/env python3
"""hand_edits.py -- the two prose fixes the far-pointer pipeline needs after it runs (2026-10-02).

QUESTION THIS ANSWERS
  Which source text did the pipeline leave saying something that its own changes made false,
  and what does it say now?  Run once, after scripts/converters/far_pointer_pipeline.sh, from
  the repo root; each edit asserts it found its text exactly once per tree.
    1. widget_descriptors.s: the `.equ` block of the DSP naming zone lost all but one alias
       (they are labels now); its section headers are rewritten to say so.
    2. ui/ui_widget_defs.s: DbMemDump_StepTable's note called it a kept positional alias.
"""
import re
import sys

EDITS = [
    ("maincpu/ui_widgets/widget_descriptors.s",
     '''; --- DSP effect naming zone: table bases ---------------------------------
	.equ DspEffectName_Strings, NakaData_WidgetDescriptors + 0x01e1a	; 0xE32C7A, 128 x 18

; --- DSP parameter slots: name at +0x11*i, unit at DspParamUnit_Table+2*i -
''',
     '''; --- DSP effect naming zone ---------------------------------------------
; DspParamUnit_Table (86 x 2), DspParamName_Table (86 x 17; slot 0 is "(spare)"),
; DspParamName_NN_<NAME> (slot NN: name at DspParamName_Table + 0x11*NN, unit at
; DspParamUnit_Table + 2*NN) and DspEffectName_PtrTable (128 x u32) are labels at the
; top of the blob (split there on 2026-10-02 by split_blobs_at_far_pointers.py).
	.equ DspEffectName_Strings, NakaData_WidgetDescriptors + 0x01e1a	; 0xE32C7A, 128 x 18
'''),
    ("maincpu/ui/ui_widget_defs.s",
     "; `cp xwa, 0x5` / `sll xwa, 2` below.  The positional alias DbMemDump_StepTable is\n"
     "; auto-generated and kept; this name says what the bytes ARE.  Not a string.",
     "; `cp xwa, 0x5` / `sll xwa, 2` below.  Not a string.  It is a label of its own\n"
     "; in the Str_No run (disk_warning_strings.s) since 2026-10-02, when the run\n"
     "; was cut at every address code reaches; it was a `.set` alias before."),
]

bad = 0
for v in ("v10", "v9", "v7"):
    for rel, old, new in EDITS:
        p = "%s/%s" % (v, rel)
        t = open(p, "rb").read().decode("latin-1")
        n = t.count(old)
        print("%s: %d" % (p, n))
        if n != 1:
            bad += 1
            continue
        open(p, "wb").write(t.replace(old, new).encode("latin-1"))
sys.exit(1 if bad else 0)
