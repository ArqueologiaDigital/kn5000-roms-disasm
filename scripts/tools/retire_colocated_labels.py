#!/usr/bin/env python3
"""retire_colocated_labels.py -- a generated structural label sharing its address with another label goes.

QUESTION THIS ANSWERS / JOB IT DOES
  Cross-Version policy 5 (Canonical Label Names, STRICT): one name per address.  The label passes
  of 2026-10-02/03 checked only the line that emits an address for an existing label, not a
  label-only line just above it, so they sometimes put a generated name where a name already was:
  `PmExpFilter_CellKeys:` followed by `PmExpFilter_EventDispatch_Data:` (321 such addresses in
  v10, counting older pairs too).  For every address with two or more column-0 labels in the
  linked ELF where at least one is a GENERATED structural name (`_Data`, `_Data_2`, `_Str_<Text>`,
  `_Target<k>`, `_Code`, `_Name`, `_Helper`, `_Join`, `_Skip`, `_Return`, `_Loop`, `_Sub`,
  `_Entry`, `_Pad`, `_EndName`, `_Tail`, optional number), the generated ones retire into the
  best remaining name (a non-generated one when there is one; symbolize_far_pointer_pushes.pick
  otherwise): the definition goes (a `Name:` line, or the `Name:` prefix of a same-line
  definition) and every use in the tree's .s and .ld files takes the kept name.  A name that
  appears in a C source (where it may be a struct member) is left.  Pairs of hand-written names
  (`BrassSound_SamplePtr_Table` / `SOUND_DATA_BRASS_PTRS`, a struct and its first field) are a
  human's call and are left too.  Labels emit no byte: `make gate-all`.

USAGE
  make all
  python3 scripts/tools/retire_colocated_labels.py --tree v10 [--apply]
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
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import symbolize_far_pointer_pushes as fp     # noqa: E402

GEN = re.compile(r'(_Data\d*|_Data_\d+|_Str_\w+|_Target\d+|_Code\d*|_Code_\d+|_Name|_Name_\d+|_Helper\d*|_Join\d*|_Skip\d*|'
                 r'_Return\d*|_Loop\d*|_Sub\d*|_Entry\d*|_Pad\d*|_EndName|_Tail)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=sorted(fp.IMAGES))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src, _ = fp.IMAGES[a.tree]
    s_files = sorted(glob.glob(os.path.join(REPO, src, "**", "*.s"), recursive=True))
    ld_files = sorted(glob.glob(os.path.join(REPO, src, "**", "*.ld"), recursive=True))
    c_text = "\n".join(open(f, "rb").read().decode("latin-1") for g in ("*.c", "*.h")
                       for f in glob.glob(os.path.join(REPO, src, "**", g), recursive=True))
    col0 = fp.col0_labels(s_files)
    syms = fp.elf_symbols(elf)
    retire, st = {}, collections.Counter()
    for ad, ns in syms.items():
        g = sorted(n for n in ns if n in col0)
        if len(g) < 2:
            continue
        gen = [n for n in g if GEN.search(n)]
        if not gen:
            st["hand-written names only: left"] += 1
            continue
        keep_pool = [n for n in g if n not in gen] or g
        keep = fp.pick(keep_pool, col0)
        for n in gen:
            if n == keep:
                continue
            if re.search(r'(?<![\w$])%s(?![\w$])' % re.escape(n), c_text):
                st["named in C: left"] += 1
                continue
            retire[n] = keep
    st["retired"] = len(retire)
    print("%s: %s%s" % (a.tree, dict(st), "" if a.apply else " (dry run)"))
    if a.apply and retire:
        rp = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True))))
        defn = re.compile(r'^(%s):[ \t]*' % "|".join(map(re.escape, sorted(retire, key=len, reverse=True))))
        for f in s_files + ld_files:
            t = open(f, "rb").read().decode("latin-1")
            out = []
            for l in t.split("\n"):
                m = defn.match(l)
                if m:
                    rest = l[m.end():]
                    if not rest.strip():
                        continue                         # a label-only line
                    l = "\t" + rest                      # keep what the same line defined
                out.append(rp.sub(lambda q: retire[q.group(1)], l))
            t2 = "\n".join(out)
            if t2 != t:
                open(f, "wb").write(t2.encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
