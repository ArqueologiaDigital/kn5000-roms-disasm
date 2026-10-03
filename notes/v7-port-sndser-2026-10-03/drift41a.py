#!/usr/bin/env python3
"""drift41a.py -- which v7 labels still sit exactly 0x41A after v10's code of the same name?

QUESTION THIS ANSWERS
  After the sndparam/midi_serial port, where is the 0x41A drift left, is each drifted label referenced,
  and which v7 label (if any) already stands at the address v10's code really is?  Uses
  scripts/analysis/v7_label_drift.py's locate() (v10's bytes for the name, found once near the v7
  label) on the four files that showed -0x41A deltas.  Needs both maincpu ELFs (make).

USAGE (repository root)
  python3 notes/v7-port-sndser-2026-10-03/drift41a.py
"""
import collections
import glob
import re
import sys

sys.argv = sys.argv[:1]
sys.path.insert(0, "scripts/analysis")
import v7_label_drift as D  # noqa: E402

v10 = open("original_ROMs/kn5000_v10_program.rom", "rb").read()
v7 = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
s10 = D.syms("rebuilt_ROMs/kn5000_v10_program.llvm.elf")
s7 = D.syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
at7 = collections.defaultdict(list)
for n, a in s7.items():
    at7[a].append(n)
txt = [open(f, "rb").read().decode("latin-1") for f in glob.glob("v7/maincpu/**/*.s", recursive=True)]
for f in ["audio/dsp_config_sysex.s", "audio/note_voice_mapping.s", "midi/midi_dispatch_handlers.s",
          "midi/midipkt_routines.s"]:
    for name in D.labels_in("v7/maincpu/" + f):
        if name in s7 and name in s10:
            hit = D.locate(v10, v7, s10[name], s7[name])
            if hit is not None and hit - s7[name] == -0x41A:
                refs = sum(len(re.findall(r'(?<![\w.$])%s(?![\w.$])' % re.escape(name), t)) for t in txt) - 1
                print(f, name, hex(s7[name]), "->", hex(hit), "refs", refs, "there:", at7.get(hit, []))
