"""REVIEW PROBE (disposable): are the addresses cited in prom_a's NEW header
comments real instruction starts?

The signature of this tree's documented off-by-one is that the byte at cited-1
is an opcode (0x44/0x45/0x46 and friends), i.e. the citation points one byte
past the instruction it means.  Every instruction line of the four .s files
carries a `; ADDR  <bytes>` comment and the byte gate proves those files rebuild
the ROMs, so the set of those ADDRs IS the set of proven instruction starts.
"""
import re, sys, subprocess, collections

ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1"
S = "/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad"
BASE = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
ADDRC = re.compile(r';\s*([0-9A-F]{6})\s')

def instr_addrs(img, path):
    s = set()
    with open(path, encoding="utf-8", errors="replace") as f:
        for ln in f:
            if "\t" not in ln and not ln.startswith(" "):
                continue
            m = ADDRC.search(ln)
            if m:
                s.add(int(m.group(1), 16))
    return s

IA = {}
for img in "abc":
    IA[img] = instr_addrs(img, "%s/prom_%s/wsa1_prom_%s.s" % (ROOT, img, img))
    print("prom_%s: %d proven instruction starts" % (img, len(IA[img])), file=sys.stderr)

# added comment lines in prom_a
# ⚠ NOT `git diff ebabc85 -- prom_a/wsa1_prom_a.s`.  The pathspec is relative to
# the current directory, so after the move it named `wsa1/prom_a/...`, which
# ebabc85 does not contain: git matched nothing on the old side and reported the
# WHOLE working file as added -- 175,190 "new" comment lines to audit, rc 0.
import sys as _sys
_sys.path.insert(0, ROOT + "/notes")
from asm_source import git_diff_lines  # noqa: E402
d = git_diff_lines("prom_a/wsa1_prom_a.s", "ebabc85", root=ROOT, context=0)
added = [l[1:] for l in d if l.startswith("+") and not l.startswith("+++")]
comments = [l for l in added if l.lstrip().startswith(";")]
print("added lines: %d, of which comment lines: %d" % (len(added), len(comments)), file=sys.stderr)

# a citation is 0xHHHHHH (6 hex) inside a comment; image from the nearest
# "prom_X" word on the same line, defaulting to prom_a (the file we are in)
CIT = re.compile(r'\b(?:prom_([abcd])\s+)?0x([0-9A-Fa-f]{6})\b')
rom = {}
for img in "abc":
    rom[img] = open("%s/rebuilt_ROMs/wsa1_prom_%s.llvm.rom" % (ROOT, img), "rb").read() \
        if False else None

cites = collections.Counter()
bad = []
seen = set()
for l in comments:
    # ignore lines that are literally the `.long 0x00XXXXXX` style or a table extent
    for m in CIT.finditer(l):
        img = m.group(1) or "a"
        a = int(m.group(2), 16)
        if img == "d":
            continue
        if a < BASE[img] or a > BASE[img] + 0x7FFFF:
            continue
        key = (img, a, l.strip())
        if key in seen:
            continue
        seen.add(key)
        cites[img] += 1
        if a not in IA[img]:
            bad.append((img, a, l.strip()))

print("\ncitations checked: %s  total=%d" % (dict(cites), sum(cites.values())))
print("citations that are NOT a proven instruction start: %d" % len(bad))
for img, a, l in bad:
    off = "prom_%s 0x%06X" % (img, a)
    nb = [x for x in (a-1, a-2, a+1, a+2) if x in IA[img]]
    print("  %-16s  %s" % (off, l[:110]))
    print("      nearest proven instruction starts: %s"
          % (", ".join("0x%06X" % x for x in nb) or "none within +-2"))
