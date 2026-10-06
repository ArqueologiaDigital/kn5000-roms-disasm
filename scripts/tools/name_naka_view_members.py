#!/usr/bin/env python3
"""Give the members of the compiled-C view blobs the names their own data implies.

QUESTION IT ANSWERS / WHAT IT DOES
  The KN5000 C sources that rebuild the firmware's view resources (`*/maincpu/**/naka_*.c` and friends, written
  by scripts/converters/naka_struct_decode.py) describe each ROM blob as one packed struct.  Its members were
  named by position:
    vSS_eK   element K of Viewable slot 0xSS -- a widget instance, whose declaration comment records the
             firmware's own resource name when the resource table gives one: `element 2 of Viewable slot
             0x41 "SYSINI": AcListBox`;
    str_N    a text blob that some widget field points at: `.list = SELF(str_3)`.
  This script renames, file by file:
    1. an element whose comment carries a resource name -> that name (`v41_e2` -> `SYSINI`); a second element
       with the same name in one file keeps its position as a suffix (`SYSINI_v41_e5`);
    2. a str_N that a widget field references -> <element>_<field> (`str_3` -> `SYSINI_list`), from the first
       reference in the initializer, unless that field is itself a placeholder (`.ptr_0160`);
    3. any other str_N whose text is an identifier (a resource, bitmap or style name such as "FTBMP01" or
       "TcBigBandBrass") -> <text>_str;
    4. any other str_N whose text has words -> its first (up to four) words in CamelCase + _str, at most 32
       characters ("Bass Port Speaker" -> BassPortSpeaker_str).  Empty strings and single symbols keep
       their names;
    5. a ptr_XXXX member initialised with NAKA_ADDR(Name) or SELF(member) -> <Name>_ptr / <member's name>_ptr
       (a derivative name: "the pointer to X"); one aimed at a placeholder member keeps its name.
  Only member names change, never a type, size or order, so every compiled blob must stay byte-identical
  (`make all`).  Comments are kept; the position stays in the element comments.

RUN (repository root)
  python3 scripts/tools/name_naka_view_members.py v10 --dry-run
  python3 scripts/tools/name_naka_view_members.py v10          # then: make all, compare_roms.py
"""
import collections
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREES = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu"}
ELEM_DECL = re.compile(r'/\*\s*element (\d+) of Viewable slot 0x([0-9A-Fa-f]+)(?: "([^"]+)")?:[^*]*\*/\s*\n\s*'
                       r'[A-Za-z_]\w*\s+(v[0-9A-Fa-f]+_e\d+)\s*;')
C_RESERVED = {"auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum",
              "extern", "float", "for", "goto", "if", "int", "long", "register", "return", "short", "signed",
              "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while"}


def ident(s):
    s = re.sub(r'[^A-Za-z0-9_]+', '_', s).strip('_')
    if not s or s[0].isdigit():
        s = "r_" + s
    return s


sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
from semantic_score import placeholder_field  # noqa: E402


def plan_file(text):
    code = re.sub(r'/\*.*?\*/', ' ', text, flags=re.S)
    used = set(re.findall(r'\b([A-Za-z_]\w*)\s*(?:\[[^\]]*\]\s*)*;', code))      # declared members
    used |= set(re.findall(r'#\s*define\s+([A-Za-z_]\w*)', code))               # macros
    used |= set(re.findall(r'\}\s*([A-Za-z_]\w*)\s*;', code))                     # typedef names
    ren = {}
    # 1. elements with a resource name
    for k, slot, res, mem in ELEM_DECL.findall(text):
        if not res:
            continue
        nm = ident(res)
        if nm.lower() in C_RESERVED or nm in used:
            nm = "%s_%s" % (nm, mem)
        if nm in used:
            continue
        ren[mem] = nm
        used.add(nm)
    # 2. str_N referenced from an element's field
    first_ref = {}
    for m in re.finditer(r'\n    \.(\w+) = \{(.*?)\n    \},', text, re.S):
        elem, body = m.group(1), m.group(2)
        for f, s in re.findall(r'\.(\w+)\s*=\s*SELF\((str_\d+)\)', body):
            first_ref.setdefault(s, (elem, f))
    for s, (elem, f) in sorted(first_ref.items(), key=lambda x: int(x[0][4:])):
        if placeholder_field(f):
            continue                        # `.ptr_0160 = SELF(str_5)` says nothing about str_5
        base = "%s_%s" % (ren.get(elem, elem), f)
        nm, n = base, 2
        while nm in used:
            nm, n = "%s_%d" % (base, n), n + 1
        ren[s] = nm
        used.add(nm)
    # 3. any other str_N whose text is itself an identifier (a resource, bitmap or style name): <text>_str
    for m in re.finditer(r'\n\s+\.(str_\d+)\s*=\s*(?:ALIGNED_STRING\()?\s*"([A-Za-z_][A-Za-z0-9_]{0,40})"', text):
        s, word = m.group(1), m.group(2)
        if s in ren:
            continue
        base = "%s_str" % word
        nm, n = base, 2
        while nm in used:
            nm, n = "%s_%d" % (base, n), n + 1
        ren[s] = nm
        used.add(nm)
    # 4. any other str_N whose text has words: the first words in CamelCase + _str (ASCII letters and digits)
    for m in re.finditer(r'\n\s+\.(str_\d+)\s*=\s*(?:ALIGNED_STRING\()?\s*"((?:[^"\\]|\\.)*)"', text):
        s, body = m.group(1), m.group(2)
        if s in ren:
            continue
        words = re.findall(r'[A-Za-z][A-Za-z0-9]*', re.sub(r'\\[nrt0x][0-9a-fA-F]*', ' ', body))
        words = [w for w in words if len(w) > 1 or w.isupper()][:4]
        if not words:
            continue
        stem = "".join((w.capitalize() if w.isupper() else w[:1].upper() + w[1:]) for w in words)[:32]
        base = "%s_str" % stem
        nm, k = base, 2
        while nm in used:
            nm, k = "%s_%d" % (base, k), k + 1
        ren[s] = nm
        used.add(nm)
    # 5. a ptr_XXXX member that holds NAKA_ADDR(Name) or SELF(member) -> <Name or member's name>_ptr
    for m in re.finditer(r'\n\s+\.(ptr_[0-9a-f]+)\s*=\s*(?:NAKA_ADDR\((\w+)\)|SELF\((\w+)\))\s*,', text):
        p, ext, own = m.group(1), m.group(2), m.group(3)
        if p in ren:
            continue
        target = ext if ext else ren.get(own, own)
        if placeholder_field(target):
            continue
        base = "%s_ptr" % target
        nm, k = base, 2
        while nm in used:
            nm, k = "%s_%d" % (base, k), k + 1
        ren[p] = nm
        used.add(nm)
    return ren


def main():
    tree = sys.argv[1]
    dry = "--dry-run" in sys.argv
    files = sorted(glob.glob(os.path.join(ROOT, TREES[tree], "**", "*.c"), recursive=True))
    tot = collections.Counter()
    for p in files:
        raw = open(p, "rb").read()
        text = raw.decode("latin-1")
        if "SELF(" not in text:
            continue
        ren = plan_file(text)
        if not ren:
            continue
        tot["files"] += 1
        tot["elements"] += sum(1 for k in ren if k.startswith("v"))
        tot["strings"] += sum(1 for k in ren if k.startswith("str_"))
        if dry:
            for k in list(ren)[:4]:
                print("  %s: %s -> %s" % (os.path.relpath(p, ROOT), k, ren[k]))
            continue
        pat = re.compile(r'\b(%s)\b' % "|".join(re.escape(k) for k in sorted(ren, key=len, reverse=True)))
        new = pat.sub(lambda m: ren[m.group(1)], text)
        data = new.encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
    print("%s: %d files, %d elements named, %d strings named" % (tree, tot["files"], tot["elements"], tot["strings"]))


if __name__ == "__main__":
    main()
