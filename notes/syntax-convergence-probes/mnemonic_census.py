#!/usr/bin/env python3
"""
QUESTION: how far apart are the two syntaxes, in call sites?

For every tracked assembly source in this tree, count the mnemonic on every
instruction line and put it in one of four buckets:

  NATIVE     the mnemonic exists in MAME unidasm's vocabulary
             (dasm900.cpp s_mnemonic[], 110 real names + "db"), so the
             two syntaxes already agree on the NAME at this site
  SYNTHETIC  the backend has this mnemonic but unidasm does not: the name
             encodes the operand FORM (lda_d16, ldb_erp, add_sril_rm, resm)
  MACRO      a .macro defined inside this tree (m_*, mx_*, ...) that emits
             raw bytes -- these are the "12,539 macro call sites" of
             TOOLCHAIN_VERSION UPDATE 7
  UNKNOWN    neither -- report so it can be looked at

SYNTHETIC is split further by whether a native mnemonic with the same stem
exists in the backend at all, which is the cheap proxy for "could this site
be renamed without a backend change".

EXACT COMMAND (from the tree root):

    python3 notes/syntax-convergence-probes/mnemonic_census.py \
        --out notes/syntax-convergence-probes/out

Inputs, all read live, nothing vendored:
  * git ls-files '*.s' '*.inc'                       -- the sources
  * ~/compartilhado/mame/src/devices/cpu/tlcs900/dasm900.cpp  -- unidasm's names
  * ~/compartilhado/llvm-project/build/lib/Target/TLCS900/TLCS900GenAsmMatcher.inc
                                                     -- the backend's names

⚠ Sources are latin-1, not UTF-8.  Read them as latin-1 (see the lane brief).
"""
import argparse, collections, os, re, subprocess, sys, json

HOME = os.path.expanduser("~")
DASM900 = os.path.join(HOME, "compartilhado/mame/src/devices/cpu/tlcs900/dasm900.cpp")
ASMMATCH = os.path.join(HOME, "compartilhado/llvm-project/build/lib/Target/TLCS900/TLCS900GenAsmMatcher.inc")
INSTRTD = os.path.join(HOME, "compartilhado/llvm-project/llvm/lib/Target/TLCS900/TLCS900InstrInfo.td")


def unidasm_mnemonics(path=DASM900):
    """The literal s_mnemonic[] table -- unidasm can print no other name."""
    src = open(path, encoding="latin-1").read()
    i = src.index("const char *const s_mnemonic[]")
    body = src[src.index("{", i) + 1: src.index("};", i)]
    return {m for m in re.findall(r'"([^"]*)"', body)}


def backend_mnemonics(path=ASMMATCH):
    """The tablegen MnemonicTable: \\<len><name> records, concatenated."""
    src = open(path, encoding="latin-1").read()
    i = src.index("static const char MnemonicTable[] =")
    body = src[i: src.index(";", i)]
    chunks = re.findall(r'"((?:[^"\\]|\\.)*)"', body)
    raw = "".join(chunks)
    # decode the C escapes (\000 \003 \n \t ...) into real bytes
    blob = raw.encode("latin-1").decode("unicode_escape")
    out, p = set(), 0
    while p < len(blob):
        n = ord(blob[p]); p += 1
        if n == 0:
            continue
        out.add(blob[p:p + n]); p += n
    return out


def rawbyte_mnemonics(path=INSTRTD):
    """Mnemonics whose OPERANDS are raw bytes ($b0,$b1,...) rather than a
    modelled operand -- e.g.

        def ADD_SRIL_RM : RIRegInst<0xC3, 0x80, 5, (outs),
            (ins GPR:$rd, i32imm:$b0, i32imm:$b1, i32imm:$b2),
            "add_sril_rm", "$rd, $b0, $b1, $b2", []>;

    which is written `add_sril_rm xix, 7, 236, 232` -- three literal bytes.
    These are BYTE EMITTERS wearing a mnemonic's name.  No renaming reaches
    them: the operand does not exist to be moved into operand position, so
    converging their spelling means MODELLING the operand first."""
    src = open(path, encoding="latin-1").read()
    return set(re.findall(r'"([a-z][\w]*)",\s*"[^"]*\$b0', src))


def tree_macros(root):
    """Every .macro defined anywhere in the tree -- these are not mnemonics."""
    names = {}
    for path in tracked(root, ("*.inc", "*.s")):
        full = os.path.join(root, path)
        try:
            txt = open(full, encoding="latin-1").read()
        except OSError:
            continue
        for m in re.finditer(r'^\s*\.macro\s+([A-Za-z_.$][\w.$]*)', txt, re.M):
            names.setdefault(m.group(1), path)
    return names


def tracked(root, globs):
    out = subprocess.run(["git", "ls-files", "-z", *globs], cwd=root,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\0") if p]


# an instruction line: indented, starts with a letter, first token is the
# mnemonic.  Labels end in ':' and directives start with '.', both excluded.
LINE = re.compile(r'^[ \t]+([A-Za-z_][\w.]*)(?:[ \t]|$)')


def census(root):
    uni = unidasm_mnemonics()
    backend = backend_mnemonics()
    rawbyte = rawbyte_mnemonics()
    macros = tree_macros(root)
    counts = collections.Counter()
    files = collections.defaultdict(set)
    for path in tracked(root, ("*.s", "*.inc")):
        full = os.path.join(root, path)
        try:
            txt = open(full, encoding="latin-1").read()
        except OSError:
            continue
        for line in txt.split("\n"):
            code = line.split(";", 1)[0]
            m = LINE.match(code)
            if not m:
                continue
            tok = m.group(1)
            if tok.endswith(":"):
                continue
            counts[tok] += 1
            files[tok].add(path)
    rows = []
    bucket_files = collections.defaultdict(set)
    for tok, n in counts.most_common():
        if tok in macros:
            kind = "MACRO"
        elif tok in uni:
            kind = "NATIVE"
        elif tok in backend:
            kind = "SYNTHETIC"
        else:
            kind = "UNKNOWN"
        stem = tok.split("_")[0].rstrip("0123456789")
        bucket_files[kind] |= files[tok]
        rows.append(dict(mnemonic=tok, count=n, kind=kind,
                         files=len(files[tok]),
                         stem_is_native=(stem in uni),
                         raw_byte_operands=(tok in rawbyte),
                         stem=stem))
    return (rows, uni, backend, macros, bucket_files,
            len(tracked(root, ("*.s",))), rawbyte)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--out", default=None)
    a = ap.parse_args()
    rows, uni, backend, macros, bfiles, n_s, rawbyte = census(a.root)
    tot = collections.Counter()
    for r in rows:
        tot[r["kind"]] += r["count"]
    names = collections.Counter(r["kind"] for r in rows)
    print("unidasm vocabulary : %d names" % len(uni))
    print("backend vocabulary : %d names" % len(backend))
    print("tree .macro names  : %d" % len(macros))
    print()
    print("tracked .s files  : %d" % n_s)
    print()
    print("%-10s %10s %8s %8s" % ("bucket", "sites", "names", "files"))
    for k in ("NATIVE", "SYNTHETIC", "MACRO", "UNKNOWN"):
        print("%-10s %10d %8d %8d" % (k, tot[k], names[k], len(bfiles[k])))
    print("%-10s %10d %8d %8d"
          % ("TOTAL", sum(tot.values()), len(rows),
             len(set().union(*bfiles.values())) if bfiles else 0))
    print()
    syn = [r for r in rows if r["kind"] == "SYNTHETIC"]
    with_stem = sum(r["count"] for r in syn if r["stem_is_native"])
    print("SYNTHETIC sites whose stem IS a unidasm mnemonic: %d of %d (%.1f%%)"
          % (with_stem, tot["SYNTHETIC"], 100.0 * with_stem / max(1, tot["SYNTHETIC"])))
    print()
    rb = [r for r in rows if r["raw_byte_operands"]]
    print("RAW-BYTE-OPERAND pseudo-instructions in use: %d names, %d sites"
          % (len(rb), sum(r["count"] for r in rb)))
    print("  (these cannot be reached by ANY rename -- the operand is not"
          " modelled)")
    for r in sorted(rb, key=lambda r: -r["count"])[:12]:
        print("   %-20s %8d" % (r["mnemonic"], r["count"]))
    print()
    print("top 40 SYNTHETIC mnemonics by call sites:")
    print("%-22s %8s %6s %s" % ("mnemonic", "sites", "files", "stem native?"))
    for r in syn[:40]:
        print("%-22s %8d %6d %s" % (r["mnemonic"], r["count"], r["files"],
                                    "yes" if r["stem_is_native"] else "NO"))
    if a.out:
        os.makedirs(a.out, exist_ok=True)
        with open(os.path.join(a.out, "mnemonic_census.csv"), "w") as f:
            f.write("mnemonic,count,kind,files,stem,stem_is_native,"
                    "raw_byte_operands\n")
            for r in rows:
                f.write("%s,%d,%s,%d,%s,%d,%d\n" % (r["mnemonic"], r["count"],
                        r["kind"], r["files"], r["stem"], r["stem_is_native"],
                        r["raw_byte_operands"]))
        with open(os.path.join(a.out, "mnemonic_census_totals.json"), "w") as f:
            json.dump(dict(sites=dict(tot), names=dict(names),
                           files=dict((k, len(v)) for k, v in bfiles.items()),
                           tracked_s_files=n_s,
                           rawbyte_names=len(rb),
                           rawbyte_sites=sum(r["count"] for r in rb),
                           unidasm_vocab=len(uni), backend_vocab=len(backend),
                           tree_macros=len(macros)), f, indent=1)
        print("\nwrote %s/mnemonic_census.csv" % a.out)


if __name__ == "__main__":
    sys.exit(main())
