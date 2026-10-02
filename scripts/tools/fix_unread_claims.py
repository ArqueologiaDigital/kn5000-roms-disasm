#!/usr/bin/env python3
"""fix_unread_claims.py -- headers that say "no reader" where claims_lint.py proved a reader.

QUESTION THIS ANSWERS / WHY IT EXISTS
  `scripts/analysis/claims_lint.py unread-claims` finds headers claiming nothing reads a range
  ("no registration or code reference reaches them", "No reader found", "Unreferenced") while
  the ROM has a reader: a `pushw 0x00HH / pushw 0xLLLL` far-pointer argument, a 32-bit pointer,
  a source reference, or a block copy.  Its strong tier was verified at ~100 % (notes/
  claims-lint-2026-10-02).  The claim is FALSE, and a false "no reader" is worse than a gap,
  because the census and the next reader stop looking.

  This does the minimum that is certainly true, per strong row:
    * the claim phrase inside the header block (from the last `; ----` above the label down to
      the label) is replaced by "that code DOES reach (Readers below)" -- or, for a bare
      "No reader found." / "Unreferenced", by "Readers below.";
    * a line `; Readers (claims_lint.py unread-claims, 2026-10-02): ...` is added at the end of
      the header block, each reader resolved to the routine that contains it through the
      image's OWN linked ELF (nearest preceding non-local symbol), with its address and the
      kind of reference (pushw far pointer / 32-bit pointer / source / block copy).
  What the readers DO with the bytes is not written here -- that needs reading them.

USAGE
  python3 scripts/analysis/claims_lint.py unread-claims --out DIR
  python3 scripts/tools/fix_unread_claims.py DIR/unread-claims.tsv [--apply]
  Comment-only: `make gate-all` must stay 13/13.
"""
import argparse
import bisect
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ELF = {"v10": "rebuilt_ROMs/kn5000_v10_program.llvm.elf", "v9": "rebuilt_ROMs/kn5000_v9_program.llvm.elf",
       "v7": "rebuilt_ROMs/kn5000_v7_program.llvm.elf",
       "v142": "rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf",
       "tabledata": "rebuilt_ROMs/kn5000_table_data.llvm.elf",
       "hdae5000": "rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf",
       "prom_a": "wsa1/rebuilt_ROMs/wsa1_prom_a.llvm.elf", "prom_b": "wsa1/rebuilt_ROMs/wsa1_prom_b.llvm.elf",
       "prom_c": "wsa1/rebuilt_ROMs/wsa1_prom_c.llvm.elf"}
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Tail|Next|Done|Exit|End)\d*$|__[0-9A-F]{6}$')
S = r'(?:\s|;)+'                                   # a word gap may cross a `; ` line break
CLAIM = re.compile(r'(that' + S + r')?no' + S + r'(registration' + S + r'or' + S + r')?code' + S +
                   r'reference' + S + r'reaches(' + S + r'(them|it))?', re.I)
BARE = re.compile(r'\bNo' + S + r'reader(' + S + r'found)?\.|\bUnreferenced\.?|\bNO READER FOUND\b', re.I)
KIND = {"push": "pushw far pointer", "ptr32": "32-bit pointer", "srcref": "source reference",
        "copy": "block copy", "numref": "numeric reference", "imm": "immediate"}


def symtab(image):
    out = subprocess.run([NM, "--defined-only", "-n", os.path.join(REPO, ELF[image])],
                         capture_output=True, text=True, check=True).stdout
    addrs, names = [], []
    for l in out.splitlines():
        a, t, n = l.split()
        if t.lower() != "t" or n.startswith(".L"):
            continue
        addrs.append(int(a, 16))
        names.append(n)
    return addrs, names


def routine_at(st, addr):
    addrs, names = st
    i = bisect.bisect_right(addrs, addr) - 1
    while i >= 0 and STRUCT.search(names[i]):
        i -= 1
    return names[i] if i >= 0 else "?"


def readers(detail, st):
    out = []
    for kind, body in re.findall(r'\b(push|ptr32|srcref|copy|numref|imm)=\d+[^(]*\(([^)]*)\)', detail):
        for item in [x.strip() for x in body.split(" ") if x.strip()]:
            m = re.match(r'0x([0-9A-Fa-f]+)->', item)
            if m:
                a = int(m.group(1), 16)
                out.append("%s (0x%X, %s)" % (routine_at(st, a), a, KIND[kind]))
            else:
                m = re.match(r'([^:(]+):(\d+)\(([^)]*)\)?', item)
                if m:
                    out.append("%s:%s (%s)" % (os.path.basename(m.group(1)), m.group(2), KIND[kind]))
    total = sum(int(n) for n in re.findall(r'\b(?:push|ptr32|srcref|copy|numref|imm)=(\d+)', detail))
    seen, uniq = set(), []
    for r in out:
        if r not in seen:
            seen.add(r)
            uniq.append(r)
    return uniq, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tsv")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rows = [l.rstrip("\n").split("\t") for l in open(a.tsv, encoding="utf-8")][1:]
    rows = [r for r in rows if len(r) >= 5 and r[4].startswith("READ-DESPITE-CLAIM")]
    tabs, byfile = {}, collections.defaultdict(list)
    for r in rows:
        byfile[r[1]].append(r)
    done = skipped = 0
    for f, rs in sorted(byfile.items()):
        path = os.path.join(REPO, f)
        L = open(path, "rb").read().decode("latin-1").split("\n")
        for r in sorted(rs, key=lambda r: -int(r[2])):          # bottom-up keeps indexes valid
            image, ln = r[0], int(r[2])
            if image not in tabs:
                tabs[image] = symtab(image)
            # the header block: comment lines above the label line (the reported line is in it)
            end = ln - 1
            while end < len(L) and L[end].lstrip().startswith(";"):
                end += 1                                          # first non-comment = label
            start = ln - 1
            while start > 0 and L[start - 1].lstrip().startswith(";"):
                start -= 1
            block = "\n".join(L[start:end])
            new, k = CLAIM.subn("that code DOES reach (Readers below)", block, count=1)
            if not k:
                new, k = BARE.subn("Readers below.", block, count=1)
            if not k:
                print("SKIP %s:%d claim phrase not found" % (f, ln)); skipped += 1
                continue
            rd, total = readers(r[4], tabs[image])
            if not rd:
                print("SKIP %s:%d no reader parsed" % (f, ln)); skipped += 1
                continue
            more = total - len(rd)
            text = "; Readers (claims_lint.py unread-claims, 2026-10-02): " + "; ".join(rd[:6])
            if more > 0 or len(rd) > 6:
                text += "; and %d more" % (total - min(len(rd), 6))
            nl = new.split("\n")
            ins = len(nl)
            if nl and re.match(r'^;\s*-{5,}', nl[-1]):           # keep a closing rule last
                ins -= 1
            # wrap the readers line at ~100 columns
            wrapped, cur = [], ""
            for word in text.split(" "):
                if len(cur) + len(word) + 1 > 100 and cur:
                    wrapped.append(cur)
                    cur = ";   " + word
                else:
                    cur = (cur + " " + word) if cur else word
            wrapped.append(cur)
            nl[ins:ins] = wrapped
            L[start:end] = nl
            done += 1
        if a.apply:
            open(path, "wb").write("\n".join(L).encode("latin-1"))
    print("%s %d header(s); skipped %d" % ("corrected" if a.apply else "would correct", done, skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
