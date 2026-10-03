#!/usr/bin/env python3
"""prom_ab_screen_stage_and_flags_census.py -- what (0x207E) and (0x2095) hold, from every operand.

QUESTIONS THIS ANSWERS (FINDINGS-prom_ab-screen-stage-and-flags.md)
  A. (0x207E): which values are written, how many `cp (0x207E),0` / `cp (0x207E),1` tests exist, and,
     for every `cp 0 / jr nz` test, whether the "Are You Sure ?" or an "Attention" display list lies
     on the NON-ZERO side (the jump target) and never on the zero side (the fall-through before
     the target).
     Also counted: the two-press shape of the execute keys, `cp (0x207E),1 / jr z, X /
     ld (0x207E),1 / or (0x2071),0x10`, i.e. the first press sets 1 and requests a redraw.
  B. (0x2095): every bit operation, by bit and by kind (set / clear / test), and the full-byte
     reads.

  Both images spell the addresses three ways: hex in prom_a (`0x207e`), decimal in prom_b
  (`8318` / `8341`), and the symbol once named.  All three spellings are matched, so the census
  gives the same counts before and after the rename.

USAGE
  python3 wsa1/notes/prom_ab_screen_stage_and_flags_census.py
"""
import collections
import os
import re
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
FILES = ["wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"]
STAGE = r'(?:0x207e|8318|UI_ScreenStage)'
FLAGS = r'(?:0x2095|8341|UI_ScreenFlags)'
LAB = re.compile(r'^([A-Za-z_.$][\w.$]*):')
JR = re.compile(r'^\s*(?:jr|jrl)\s+(z|nz),\s*([\w.$]+)', re.I)
# a list is DRAWN from its start operand XIY; XIX is the end bound (FINDINGS-ui-display-list-interpreter-b.md),
# so `ld XIX,DL_SongClearKbSongAttenti0n` in Paint_SongClear's zero branch draws nothing of that list
CONFIRM = re.compile(r'\bld\s+xiy,\s*DL_(?:AreYouSure|\w*Attent?i0?o?n\w*)\b', re.I)


def load(f):
    return [l.split(";")[0].rstrip() for l in open(os.path.join(REPO, f), "rb").read().decode("latin-1").split("\n")]


def nxt(L, i):
    j = i + 1
    while j < len(L) and not L[j].strip():
        j += 1
    return j


def main():
    writes, tests = collections.Counter(), collections.Counter()
    conf_nonzero = conf_zero = conf_none = two_press = 0
    bits = collections.Counter()
    for f in FILES:
        L = load(f)
        where = {}
        for i, l in enumerate(L):
            m = LAB.match(l)
            if m:
                where[m.group(1)] = i
        for i, l in enumerate(L):
            s = l.strip()
            # ---- A. the stage byte
            m = re.match(r'ld\s+\(%s:16\),\s*(\w+)$' % STAGE, s, re.I)
            if m:
                v = m.group(1).lower()
                writes[str(int(v, 0)) if v[0].isdigit() else v] += 1
            if re.match(r'inc\s+(?:0x0)?1,\s*\(%s:16\)$' % STAGE, s, re.I):
                writes["inc 1"] += 1
            m = re.match(r'm_cp_mi8\s+MB16,\s*%s,\s*0x0([01])$' % STAGE, s, re.I)
            if m:
                tests["cp %s" % m.group(1)] += 1
                j = nxt(L, i)
                jm = JR.match(L[j])
                if m.group(1) == "0" and jm and jm.group(1).lower() == "nz" and jm.group(2) in where:
                    t = where[jm.group(2)]
                    zero_side = " ".join(L[j + 1:t]) if t > j else ""
                    nonzero_side = " ".join(L[t:t + 25])
                    if CONFIRM.search(zero_side):
                        conf_zero += 1
                        print("  confirmation list on the ZERO side: %s:%d" % (f, i + 1))
                    elif CONFIRM.search(nonzero_side):
                        conf_nonzero += 1
                    else:
                        conf_none += 1
                if m.group(1) == "1" and jm and jm.group(1).lower() == "z":
                    k = nxt(L, j)
                    k2 = nxt(L, k)
                    if re.match(r'\s*ld\s+\(%s:16\),\s*(?:0x0)?1$' % STAGE, L[k], re.I) and \
                            re.search(r'm_or_mi8\s+MB16,\s*(?:0x2071|UI_Request_Hi),\s*0x10', L[k2], re.I):
                        two_press += 1
            # ---- B. the flag byte
            m = re.match(r'm_(set|res|bit)\s+(\d),\s*MD16,\s*%s$' % FLAGS, s, re.I)
            if m:
                bits[(int(m.group(2)), {"set": "set", "res": "clear", "bit": "test"}[m.group(1)])] += 1
            m = re.match(r'm_(or|and)_mi8\s+MB16,\s*%s,\s*(0x[0-9a-f]+)$' % FLAGS, s, re.I)
            if m:
                v = int(m.group(2), 16)
                for b in range(8):
                    if m.group(1) == "or" and v >> b & 1:
                        bits[(b, "set")] += 1
                    if m.group(1) == "and" and not v >> b & 1:
                        bits[(b, "clear")] += 1
            if re.match(r'ld\s+c,\s*\(%s:16\)$' % FLAGS, s, re.I):
                j = nxt(L, i)
                m2 = re.match(r'\s*and\s+C,\s*(0x[0-9a-f]+|\d+)$', L[j], re.I)
                bits[(int(m2.group(1), 0).bit_length() - 1, "test") if m2 and bin(int(m2.group(1), 0)).count("1") == 1
                     else ("byte", "read")] += 1
            elif re.search(r'\(%s:16\)' % FLAGS, s, re.I) and not s.startswith("m_"):
                bits[("byte", s.split()[0].lower())] += 1
            elif re.match(r'm_cp_mi8\s+MB16,\s*%s,' % FLAGS, s, re.I):
                bits[("byte", "cp")] += 1
    print("A. (0x207E)")
    print("   writes:", ", ".join("%s x%d" % kv for kv in sorted(writes.items())))
    print("   tests: ", ", ".join("%s x%d" % kv for kv in sorted(tests.items())))
    print("   `cp 0 / jr nz`: confirmation list on the non-zero side %d, on the zero side %d, neither %d"
          % (conf_nonzero, conf_zero, conf_none))
    print("   two-press shape `cp 1 / jr z / ld 1 / or (0x2071),0x10`: %d" % two_press)
    print("B. (0x2095)")
    for k in sorted(bits, key=str):
        print("   %-6s %-6s x%d" % (k[0], k[1], bits[k]))
    return 1 if conf_zero else 0


if __name__ == "__main__":
    raise SystemExit(main())
