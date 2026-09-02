#!/usr/bin/env python3
"""
QUESTION: on bytes this tree assembles, are there any places where MAME's
          disassembler and this backend genuinely DISAGREE about the
          instruction -- as opposed to spelling it differently?

Two things count as a disagreement and nothing else does:

  LEN_DIFFER   the two decoders consume a different number of bytes.  ⚠ The
               instrument that looks for this is proved able to SEE it by
               `oracle_ab.py --foil N`, which lengthens every Nth record by
               one byte and must then report LEN_DIFFER on those sites.  A
               LEN_DIFFER=0 quoted without that control means nothing.
  UNIDASM_DB   unidasm prints "db": it has no decode for bytes this backend
               both assembles and disassembles.

Reads oracle_ab.py's per-site output and, for each distinct byte pattern,
finds where it is written in the sources so the site can be looked at.

EXACT COMMAND (from the tree root, after oracle_ab.py):

    python3 notes/syntax-convergence-probes/decoder_disagreements.py \
        notes/syntax-convergence-probes/out
"""
import csv, collections, os, re, subprocess, sys


def main(outdir):
    path = os.path.join(outdir, "oracle_ab_sites.csv")
    hits = collections.defaultdict(collections.Counter)
    for r in csv.DictReader(open(path)):
        if r["class"] in ("LEN_DIFFER", "UNIDASM_DB", "UNIDASM_NOLINE"):
            hits[r["class"]][(r["bytes"], r["llvm_mnemonic"],
                              r["llvm_operands"], r["image"])] += 1
    if not hits:
        print("no decoder disagreements")
        return
    for cls, c in hits.items():
        print("== %s : %d distinct (bytes, mnemonic, image) : %d sites"
              % (cls, len(c), sum(c.values())))
        for (hx, mnem, ops, img), n in c.most_common():
            print("   %-14s %-12s %-14s %-24s x%d" % (hx, mnem, ops, img, n))
            o = re.escape(ops.strip('"').strip())
            # ⚠ POSIX class, not \t: GNU grep -E reads "\t" inside a bracket
            # expression as the two literal characters, so [ \t] matches no
            # tab and this search silently returns nothing.  (The interactive
            # shell's grep is ugrep, which DOES accept \t -- so the pattern
            # works when pasted by hand and fails from a script.)
            pat = r'^[[:blank:]]+%s[[:blank:]]+%s[[:blank:]]*(;|$)' % (
                re.escape(mnem), o)
            g = subprocess.run(["grep", "-arnE", "--include=*.s", pat, "."],
                               capture_output=True, text=True,
                               errors="replace").stdout
            for line in [l for l in g.split("\n") if l][:8]:
                print("        %s" % line[:160])


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else
         "notes/syntax-convergence-probes/out")
