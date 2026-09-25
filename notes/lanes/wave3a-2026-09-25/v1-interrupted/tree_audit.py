#!/usr/bin/env python3
"""tree_audit.py -- does ANY instruction line in the tree still say something MAME disagrees with?

Every instruction line (outside .macro bodies) of every authoritative .s file is
assembled alone with the pinned llvm-mc (fixup bytes zeroed; symbols are
wildcards in the comparison), decoded with unidasm, and the SOURCE TEXT is
compared to MAME's reading with verify_respells.cmp_src.  Pseudo mnemonics are
mapped to an operation family with two_decoder_sweep.family().

Run: python3 tree_audit.py  -> tree_audit.tsv (every non-OK line) + counts
"""
import collections, os, re, sys, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, "/home/fsanches/compartilhado/kn5000-roms-disasm/notes/wave3a-toolchain-probes")
import strict_sweep as S
import verify_respells as V
import two_decoder_sweep as T

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOTS = ["v10", "v9", "v7", "v142", "subcpu", "table_data", "hdae5000", "custom_data", "wsa1"]

_orig_fam = S.fam


def fam2(m):
    f = T.family(m)
    return f[1:] if f.startswith("?") else f


S.fam = fam2


def files():
    out = subprocess.run(["git", "-C", REPO, "ls-files", "--"] + [r + "/*.s" for r in ROOTS] +
                         [r + "/**/*.s" for r in ROOTS], capture_output=True, text=True).stdout.split()
    return sorted(set(f for f in out if "/notes/" not in f and "/archive/" not in f))


def main():
    cand = []
    for f in files():
        data = open(os.path.join(REPO, f), "rb").read().decode("latin-1")
        in_macro = 0
        for n, line in enumerate(data.splitlines(), 1):
            s = V.strip(line)
            low = s.lower()
            if low.startswith(".macro"):
                in_macro += 1; continue
            if low.startswith(".endm"):
                in_macro = max(0, in_macro - 1); continue
            if in_macro or not V.is_insn(s):
                continue
            first = s.split()[0].lower()
            if first in ("addr24",) or first.startswith("m_") or first.startswith("sd_"):
                continue
            cand.append((f, n, s))
    print("instruction lines:", len(cand))
    enc = V.encode([s for _, _, s in cand])
    idx = [i for i, e in enumerate(enc) if e and len(e) <= S.SLOT]
    md = S.mame_decode([enc[i] for i in idx])
    cnt = collections.Counter()
    bymn = collections.Counter()
    rows = []
    for i, m in zip(idx, md):
        f, n, s = cand[i]
        e = enc[i]
        if m is None:
            v = "NO_MAME"
        elif m[0] != len(e):
            v = "LEN"
        elif m[1].split()[0].lower() == "db":
            v = "MAME_DB"
        else:
            try:
                v = V.cmp_src(s, m[1])
            except Exception as ex:
                v = "ERR"
        cnt[v] += 1
        if v != "OK":
            bymn[(v, s.split()[0].lower())] += 1
            rows.append((v, "%s:%d" % (f, n), s, e.hex(" "), m[1] if m else ""))
    print("assembled standalone:", sum(1 for e in enc if e), " decoded:", len(idx))
    for k, c in sorted(cnt.items()):
        print("  %-14s %8d" % (k, c))
    with open(os.path.join(HERE, "tree_audit.tsv"), "w", encoding="latin-1") as fo:
        for r in rows:
            fo.write("\t".join(r) + "\n")
    with open(os.path.join(HERE, "tree_audit_bymnem.txt"), "w") as fo:
        for (v, mn), c in bymn.most_common():
            fo.write("%6d %-14s %s\n" % (c, v, mn))
    with open(os.path.join(HERE, "tree_audit_noasm.txt"), "w", encoding="latin-1") as fo:
        for i, e in enumerate(enc):
            if not e:
                fo.write("%s:%d\t%s\n" % (cand[i][0], cand[i][1], cand[i][2]))


if __name__ == "__main__":
    main()
