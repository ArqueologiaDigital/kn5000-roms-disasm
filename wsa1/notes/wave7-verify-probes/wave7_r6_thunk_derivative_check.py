"""REVIEW-WB check 1: does each of the 103 renamed thunk slots equal
   'T_' + the label that actually sits at its jp target, in the file the
   comment names?  And is that target label pre-existing at HEAD (i.e. is
   the name really DERIVATIVE, not invented here)?"""
import re, subprocess, os
ROOT = "/home/fsanches/compartilhado/wsa1-roms-disasm"
A_BASE, B_BASE = 0xF80000, 0xF00000

def labels(path, base, text=None):
    """addr -> [labels] using the '; ADDR' address comments / .org anchors."""
    return text

# Build addr->label maps by re-using the metric's own approach: scan the .s and
# track the current address from the 'ADDR:' style comments the tree emits.
LBL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')

def load_map(path):
    """label -> set of addresses, from the trailing '; XXXXXX' address comment
       on the label's own line, and from the following line if absent."""
    out = {}
    lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
    return lines

print("placeholder")
