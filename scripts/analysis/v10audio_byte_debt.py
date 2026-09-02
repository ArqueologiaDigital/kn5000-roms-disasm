#!/usr/bin/env python3
"""v10audio_byte_debt.py -- how many bytes are spelled as raw `.byte` operands in
the v10 maincpu audio-engine sources this lane owns?

QUESTION ANSWERED
  The single headline number for lane V10AUDIO, measured straight off the source
  text so it can be run against any git revision without a build:

      sum over v10/maincpu/audio/*.s (excluding sound_data_*.s, sound_editor_ui.s
      and semenu_routines.s) of the operand count of every `.byte` directive.

  It counts OPERANDS, not directives, and it reads the files as latin-1 because
  several contain raw high bytes inside `.ascii` literals (a UTF-8 read raises,
  and the harness's ugrep-based `grep` silently skips such files entirely --
  see notes/lanes/grep-binary-skip-REPRODUCED-2026-09-02.md).

  ⚠ THIS NUMBER IS NOT DEBT ON ITS OWN.  A genuine byte-valued coefficient table
  is already correctly represented.  v10audio_byte_triage.py is what splits this
  total into CODE / TYPE / BLOCKED / DATA on cross-reference evidence.

RUN
    python3 scripts/analysis/v10audio_byte_debt.py
    git stash && python3 ... && git stash pop      # for a before/after
"""
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
AUDIO = REPO / "v10" / "maincpu" / "audio"
OTHER_LANE = {"sound_editor_ui.s", "semenu_routines.s"}
BYTE = re.compile(r'(?:^|\s)\.byte\s+(.*)$')
OPERAND = re.compile(r'0x[0-9a-fA-F]+|-?\d+')

total = 0
for f in sorted(AUDIO.glob("*.s")):
    if f.name.startswith("sound_data") or f.name in OTHER_LANE:
        continue
    n = 0
    for line in open(f, encoding="latin-1").read().split("\n"):
        line = line.split(";")[0]
        m = BYTE.search(line)
        if m:
            n += len(OPERAND.findall(m.group(1)))
    print(f"  {f.name:34s} {n:7,}")
    total += n
print(f"  {'TOTAL':34s} {total:7,}")
