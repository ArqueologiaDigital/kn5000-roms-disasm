#!/usr/bin/env python3
"""
QUESTION IT ANSWERS: which synthetic mnemonics still spell a DIRECT ADDRESS in
the name, and at how many sites?

⚠ NOT BY THE NAME'S SHAPE.  `notes/lanes/conv-width-2026-09-03.md` estimated
the residue at "9,748 sites over 66 names" by grouping census names that LOOK
like direct-address forms (`*da*`, `*di*`, `*_da`).  The real set, read off the
backend, is 95 names and 11,881 sites: the name-shape rule misses `jp_24`,
`call_24`, `lda_24`, `pushdi_24`, `chgda_24` and their `_24` siblings, which
take exactly the same operand and do not look like the others.

★ A census keyed on a naming convention measures the naming convention.

The instrument here is the OPERAND LIST: every `def` in TLCS900InstrInfo.td
whose `(ins ...)` contains `directaddr`, intersected with what the tree writes.
It also prints, per name, the ADDRESS WIDTH (AddrWidth: 0 => a 16-bit field,
1 => a 24-bit one) and the data OpSize, which together are what the native
respelling needs -- the width goes into the operand as `(addr:16|24)` and the
size is carried by the register name, or by a `w` suffix when there is no
register.

EXACT COMMAND (from the tree root):

    python3 notes/syntax-convergence-probes/direct_address_residue.py

    # what the lane converted, i.e. everything convert_direct_address_family.py
    # knows about, is excluded with:
    python3 notes/syntax-convergence-probes/direct_address_residue.py --unmapped

⚠ It reads the WORKING TREE, so it reports the residue as it stands now.  To
reproduce a historical figure, run it in a worktree at that commit:

    git worktree add --detach /tmp/da-residue <commit>

MEASURED:
    base df779dc0 (before lane w26/conv-alu)   95 names, 11,881 sites
    after that lane                             3 names,     41 sites
        lda_24 27 + ldw_da 6   .macro bodies, not assemblable in isolation
        chgda_24 8             `chg` has no memory-operand form in the backend
"""
import argparse, collections, os, re, subprocess, sys

HOME = os.path.expanduser("~")
INSTRTD = os.path.join(
    HOME, "compartilhado/llvm-project/llvm/lib/Target/TLCS900/TLCS900InstrInfo.td")


def direct_address_mnemonics(path=INSTRTD):
    """mnemonic -> {(addr_width, opsize)} for every def taking a directaddr."""
    lines = open(path, encoding="latin-1").read().split("\n")
    scope, out, i = [], collections.defaultdict(set), 0
    while i < len(lines):
        L = lines[i]
        m = re.match(r'\s*let\s+(.*?)\s+in\s*\{\s*$', L)
        if m:
            scope.append(dict(kv=m.group(1), brace=True)); i += 1; continue
        m = re.match(r'\s*let\s+(.*?)\s+in\s*$', L)
        if m:
            scope.append(dict(kv=m.group(1), oneshot=True)); i += 1; continue
        if re.match(r'\s*\}', L):
            for j in range(len(scope) - 1, -1, -1):
                if scope[j].get("brace"):
                    del scope[j]; break
            i += 1; continue
        if L.startswith("def "):
            blk, j = L, i
            while ";" not in blk and j < len(lines) - 1:
                j += 1; blk += " " + lines[j]
            mm = re.search(r'"([a-z0-9_]+)",\s*"', blk)
            ctx = " ".join(s["kv"] for s in scope) + " " + blk
            if mm and "directaddr" in blk[:mm.start()]:
                w = 24 if "AddrWidth = 1" in ctx else 16
                sz = next((s for s in ("OpSize8", "OpSize16", "OpSize32")
                           if s in ctx), "-")
                out[mm.group(1)].add((w, sz))
            scope = [s for s in scope if not s.get("oneshot")]
            i = j + 1; continue
        i += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--unmapped", action="store_true",
                    help="exclude names convert_direct_address_family.py "
                         "already knows how to respell")
    args = ap.parse_args()

    da = direct_address_mnemonics()
    print("mnemonics taking a direct address in the backend: %d" % len(da))

    skip = set()
    if args.unmapped:
        import importlib.util
        here = os.path.dirname(os.path.abspath(__file__))
        p = os.path.join(here, "../../scripts/converters/"
                               "convert_direct_address_family.py")
        spec = importlib.util.spec_from_file_location("cdaf", p)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        skip = set(mod.MAP)
        print("  ...minus %d already in the converter's MAP" % len(skip))

    names = sorted(set(da) - skip, key=len, reverse=True)
    if not names:
        print("\nnothing left to count.")
        return 0
    rx = re.compile(r'^\t(%s)[ \t]' % "|".join(names))
    files = subprocess.run(["git", "ls-files", "*.s"],
                           capture_output=True, text=True).stdout.split()
    sites = collections.Counter()
    infiles = collections.defaultdict(set)
    for f in files:
        for line in open(f, encoding="latin-1"):
            m = rx.match(line)
            if m:
                sites[m.group(1)] += 1
                infiles[m.group(1)].add(f)

    print("\n%-14s %7s %6s  %s" % ("mnemonic", "sites", "files", "width/size"))
    for mn, n in sites.most_common():
        shapes = " ".join("%d/%s" % s for s in sorted(da[mn]))
        print("%-14s %7d %6d  %s" % (mn, n, len(infiles[mn]), shapes))
    print("%-14s %7d %6d" % ("TOTAL", sum(sites.values()),
                             len(set().union(*infiles.values()))))
    print("\n%d names in use, of %d defined." % (len(sites), len(names)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
