#!/usr/bin/env bash
# the four decoded LEVEL-DETECTOR programs, at the TRUE DEFAULT (no arms):
cd /home/fsanches/compartilhado/kn5000-roms-disasm
python3 dsp/tools/pickup_cells.py \
  /home/fsanches/.claude/jobs/c9daa85d/tmp/reg/det7/t2_F.log \
  /home/fsanches/.claude/jobs/c9daa85d/tmp/reg/det7/t13_F.log \
  /home/fsanches/.claude/jobs/c9daa85d/tmp/reg/det7/t14_F.log \
  /home/fsanches/.claude/jobs/c9daa85d/tmp/reg/det7/t18_F.log
