#!/usr/bin/env python3
"""name_kn5000_ram.py -- KN5000 main-CPU RAM variables the tree already names (.equ) take their names in the code.

QUESTION THIS ANSWERS / JOB IT DOES
  The maincpu trees define RAM variables -- CPANEL_RX_READ_PTR, ENCODER_0_STATUS, MIDI_CC_MODWHEEL_VALUE,
  SYSTEM_TIMESTAMP ... (cpanel_constants.s, midi_encoder_constants.s, the program file; documented in
  technics-docs memory-map.md) -- but the code spells them by number: `ld (0x8d8c:16), a`.  This rewrites
  the numeric memory operands `(N)` / `(N:8|16|24)`, and a pointer loaded into an index register
  (`ld xix, 0x8da1`), as the name.

  v7 is NOT v10: its UI / panel variables sit elsewhere (v10's `(0x8ee0)` is v7's `(0x8e44)` in
  MidiChannel_ResetAndConfigure), yet v7's constants files carry v10's values -- harmless only because
  v7 code never used them.  So for v9 and v7 the address of each name is DERIVED: every v10 code line
  that uses the name's address is matched to the same routine (same label) in the other tree, whose
  body must have the same number of instructions with the same shape once numbers are blanked; the
  number in the matching position is a vote.  A name is applied only when all its votes agree, and the
  tree's `.equ` is corrected to that value (a comment says so).  A name with no vote whose voted
  neighbours (within 0x100, at least five) ALL moved by one delta takes that delta -- v7's panel block
  moved -0x9C as one, the low variables (0x408, 0x409, 0xC9A) not at all.  Same bytes: make gate-all.

USAGE
  make all
  python3 scripts/tools/name_kn5000_ram.py --tree v10|v9|v7 [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
CONST = ["midi_encoder_constants.s", "cpanel_constants.s", "gui_constants.s", "kn5000_%s_program.s",
         "shared/ram_variables.s"]
EQU = re.compile(r'^(\s*\.equ\s+)([A-Za-z_]\w*)(\s*,\s*)(0x[0-9a-fA-F]+)(.*)$')
MEM = re.compile(r'\((0x[0-9a-fA-F]+|\d+)(:8|:16|:24)?\)')
PTR = re.compile(r'^(\s*ld\s+x(?:ix|iy|iz|hl)\s*,\s*)(0x[0-9a-fA-F]+|\d+)(\s*)$', re.I)
COL0 = re.compile(r'^([A-Za-z_][\w$]*):')
LO, HI = 0x400, 0x100000      # internal RAM and the DRAM the code addresses (pattern buffers at 0x94800)


def const_files(t):
    return [os.path.join(REPO, t, "maincpu", c % t if "%s" in c else c) for c in CONST]


def ram_names(t):
    out = {}
    for f in const_files(t):
        if not os.path.exists(f):
            continue
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = EQU.match(l)
            if m and LO <= int(m.group(4), 16) < HI and m.group(2) != "RHYTHM_ROM_BASE":
                out[m.group(2)] = int(m.group(4), 16)
    return out


def bodies(t):
    """label -> list of (line index, file, code) for each routine of the tree"""
    out = {}
    for f in sorted(glob.glob(os.path.join(REPO, t, "maincpu", "**", "*.s"), recursive=True)):
        L = open(f, "rb").read().decode("latin-1").split("\n")
        cur = None
        for i, l in enumerate(L):
            m = COL0.match(l)
            if m:
                cur = m.group(1)
                out.setdefault(cur, (f, []))
                continue
            code = l.split(";")[0].strip()
            if cur and code and not code.startswith("."):
                out[cur][1].append((i, code))
    return out


NAMED = {}      # filled by main(): v10's RAM names, which count as numbers when shapes are compared


def shape(code):
    if NAMED:
        code = re.sub(r'\b(%s)\b' % "|".join(map(re.escape, NAMED)), "0", code)
    return re.sub(r'\s+', ' ', re.sub(r'(0x[0-9a-fA-F]+|\b\d+\b)', 'N', code.lower()))


def operands10(code):
    """v10's memory-operand values, numeric or already named"""
    out = []
    for m in re.finditer(r'\(([A-Za-z_]\w*|0x[0-9a-fA-F]+|\d+)(?::8|:16|:24)?\)', code):
        t = m.group(1)
        if t in NAMED:
            out.append(NAMED[t])
        elif re.match(r'^(0x|\d)', t):
            out.append(int(t, 0))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    ref = ram_names("v10")
    NAMED.update(ref)
    byaddr10 = {v: n for n, v in ref.items()}
    if a.tree == "v10":
        addr = dict(ref)
        report = {}
    else:
        B10, BT = bodies("v10"), bodies(a.tree)
        votes = collections.defaultdict(collections.Counter)
        for lab, (f, body) in B10.items():
            if lab not in BT:
                continue
            other = BT[lab][1]
            if len(other) != len(body) or any(shape(x[1]) != shape(y[1]) for x, y in zip(body, other)):
                continue
            for (_, c10), (_, ct) in zip(body, other):
                n10 = operands10(c10)
                nt = [int(m.group(1), 0) for m in MEM.finditer(ct)]
                for x, y in zip(n10, nt):
                    if x in byaddr10:
                        votes[byaddr10[x]][y] += 1
        addr, report, inferred = {}, {}, {}
        for n in ref:
            v = votes.get(n)
            if v and len(v) == 1:
                addr[n] = next(iter(v))
            report[n] = dict(v) if v else None
        # a name with no vote inside a block whose voted names ALL moved by the same delta takes that
        # delta (v7's panel / encoder / MIDI-CC block moved -0x9C as one: 40 of 40 voted names)
        for n in ref:
            if n in addr:
                continue
            near = {addr[m] - ref[m] for m in addr if abs(ref[m] - ref[n]) <= 0x100}
            if len(near) == 1 and sum(1 for m in addr if abs(ref[m] - ref[n]) <= 0x100) >= 5:
                addr[n] = ref[n] + near.pop()
                inferred[n] = addr[n]
                report[n] = "inferred"
    byaddr = {v: n for n, v in addr.items()}
    files = sorted(glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.s"), recursive=True))
    st = collections.Counter()
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        ch = False
        for i, l in enumerate(L):
            code, sep, cmt = l.partition(";")
            s = code.strip()
            if not s or s.startswith("."):
                continue

            def mem(m):
                v = int(m.group(1), 0)
                return "(%s%s)" % (byaddr[v], m.group(2) or "") if v in byaddr else m.group(0)

            new = MEM.sub(mem, code)
            p = PTR.match(new)
            if p and int(p.group(2), 0) in byaddr:
                new = p.group(1) + byaddr[int(p.group(2), 0)] + p.group(3)
            if new != code:
                st["operands"] += len([1 for m in MEM.finditer(code) if int(m.group(1), 0) in byaddr]) + \
                    (1 if PTR.match(code) and int(PTR.match(code).group(2), 0) in byaddr else 0)
                L[i] = new + sep + cmt
                ch = True
        if ch and a.apply:
            open(f, "wb").write("\n".join(L).encode("latin-1"))
    fixed = []
    if a.tree != "v10":
        for cf in const_files(a.tree):
            if not os.path.exists(cf):
                continue
            L = open(cf, "rb").read().decode("latin-1").split("\n")
            ch = False
            for i, l in enumerate(L):
                m = EQU.match(l)
                if m and m.group(2) in addr and int(m.group(4), 16) != addr[m.group(2)]:
                    fixed.append((m.group(2), m.group(4), "0x%04x" % addr[m.group(2)]))
                    rest = m.group(5)
                    L[i] = "%s%s%s0x%04x%s\t; %s address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's %s" % (
                        m.group(1), m.group(2), m.group(3), addr[m.group(2)], rest.rstrip(), a.tree, m.group(4))
                    ch = True
            if ch and a.apply:
                open(cf, "wb").write("\n".join(L).encode("latin-1"))
    print("%s: %d names applied; %s%s" % (a.tree, len(addr), dict(st), "" if a.apply else " (dry run)"))
    if report:
        used = set()
        for f in files:
            for l in open(f, "rb").read().decode("latin-1").split("\n"):
                if not l.lstrip().startswith(".equ"):
                    used |= set(re.findall(r'\b(%s)\b' % "|".join(map(re.escape, ref)), l.split(";")[0]))
        # a name the tree's code already uses has nothing numeric left to vote with: not "unsure"
        unsure = {n: v for n, v in report.items() if v != "inferred" and (not v or len(v) != 1) and n not in used}
        print("  inferred from the block's common delta: %s" % {n: report[n] for n in report if report[n] == "inferred"})
        print("  not applied (no vote, or votes disagree): %s" % unsure)
    for x in fixed:
        print("  .equ %s: %s -> %s" % x)
    return 0


if __name__ == "__main__":
    sys.exit(main())
