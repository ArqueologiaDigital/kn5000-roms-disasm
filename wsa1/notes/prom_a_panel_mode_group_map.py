#!/usr/bin/env python3
"""prom_a_panel_mode_group_map.py -- which panel modes share a PanelModeGroup (0x2076).

QUESTION THIS ANSWERS (FINDINGS-prom_a-panel-mode-group-and-screen-hold.md)
  PanelMode_ToGroup (0xF86CAE) stores the byte at 0xF86E81 + min(PanelMode, 0x1F -> 1) into (0x2076).
  This prints the 32-byte map from the ROM dump and lists the modes that land in each value.

USAGE
  python3 wsa1/notes/prom_a_panel_mode_group_map.py
"""
import collections
import os
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
d = open(os.path.join(REPO, "wsa1/original_ROMs/wsa1_prom_a.ic12"), "rb").read()
MAP = 0xF86E81 - 0xF80000
m = d[MAP:MAP + 32]
print("map 0xF86E81:", " ".join("%02x" % x for x in m))
g = collections.defaultdict(list)
for mode, v in enumerate(m):
    g[v].append(mode)
for v in sorted(g):
    print("group 0x%02x <- mode%s %s" % (v, "s" if len(g[v]) > 1 else "", ", ".join("0x%02x" % i for i in g[v])))
print("identity for %d of 32 modes" % sum(1 for i, v in enumerate(m) if i == v))
