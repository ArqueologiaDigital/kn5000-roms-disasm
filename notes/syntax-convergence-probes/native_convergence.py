#!/usr/bin/env python3
"""
QUESTION: how far does OPTION B get?  That is: if every synthetic mnemonic were
          retired in favour of the real mnemonic, with the operand FORM moved
          into the operand syntax the way TOOLCHAIN_VERSION UPDATE 7 already
          does it ("the address WIDTH is requested in the source as
          (0x2075:16)"), how many sites would assemble to the right bytes with
          NO backend change at all?

METHOD.  Start from unidasm's own text for each site -- that is by definition
the native mnemonic with the operand in operand position -- and add back
exactly the one thing UPDATE 7 says the source must state: the address-field
WIDTH, read off the real prefix byte in the ROM.  Then assemble and compare.

    unidasm    ld (0x0516),0x00           -> assembles to the 24-bit form, WRONG
    + width    ld (0x0516:16),0x00        -> is this the ROM's bytes?

The delta between this and oracle_ab.py's raw unidasm result is the share of
the divergence that is PURELY the missing width annotation.  What is left over
after it is the divergence that needs something the operand syntax still
cannot say.

⚠ This probe reuses oracle_ab.py's output, so run that first.

EXACT COMMAND (from the tree root):

    python3 notes/syntax-convergence-probes/oracle_ab.py \
        --out notes/syntax-convergence-probes/out
    python3 notes/syntax-convergence-probes/native_convergence.py \
        notes/syntax-convergence-probes/out
"""
import csv, collections, hashlib, os, re, shutil, subprocess, sys, tempfile

HOME = os.path.expanduser("~")
LLVM_MC = os.path.join(HOME, "compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'^\t([A-Za-z_][\w.]*)\t?(.*?)\s*; encoding: \[([^\]]*)\]\s*$')
PUREHEX = re.compile(r'^(?:0x[0-9a-f]{2})(?:,0x[0-9a-f]{2})*$')

TIERS = [(0xC0, 0xC1, 0xC2), (0xD0, 0xD1, 0xD2),
         (0xE0, 0xE1, 0xE2), (0xF0, 0xF1, 0xF2)]
WIDTH = {}
for t in TIERS:
    for i, b in enumerate(t):
        WIDTH[b] = (8, 16, 24)[i]

DIRECT = re.compile(r'\((0x[0-9a-fA-F]+)\)')


def annotate(text, want):
    """Add the ROM's real address width to the first (0x...) operand."""
    if not want or want[0] not in WIDTH:
        return None
    w = WIDTH[want[0]]
    if not DIRECT.search(text):
        return None
    return DIRECT.sub(lambda m: "(%s:%d)" % (m.group(1), w), text, count=1)


def uni_to_llvm(text):
    p = text.strip().split(None, 1)
    ops = re.sub(r',\s*', ', ', p[1]) if len(p) > 1 else ""
    return (p[0].lower() + " " + ops).strip()


def assemble(cands, mc, workdir):
    lines = []
    for i, c in enumerate(cands):
        lines.append("L%d:" % i)
        lines.append("\t" + c)
    path = os.path.join(workdir, "nc.s")
    open(path, "w").write("\n".join(lines) + "\n")
    p = subprocess.run([mc, "-triple=tlcs900", "-show-encoding", path],
                       capture_output=True, text=True, errors="replace")
    bad = set()
    for m in re.finditer(r'^[^\n:]*:(\d+):\d+: error:', p.stderr, re.M):
        idx = (int(m.group(1)) - 1) // 2
        if 0 <= idx < len(cands):
            bad.add(idx)
    got, cur = {}, None
    for line in p.stdout.split("\n"):
        lm = re.match(r'^L(\d+):', line)
        if lm:
            cur = int(lm.group(1)); got.setdefault(cur, None); continue
        m = ENC.match(line)
        if m and cur is not None:
            got[cur] = (bytes(int(b, 16) for b in m.group(3).split(","))
                        if PUREHEX.match(m.group(3)) else "RELOC")
            cur = None
    for i in bad:
        got[i] = None
    return [got.get(i) for i in range(len(cands))]


def main(outdir):
    rows = [r for r in csv.DictReader(
        open(os.path.join(outdir, "oracle_ab_reassembly.csv")))
        if r["verdict"] in ("UNI_ASSEMBLES_DIFF", "UNI_REJECTS")]
    work = tempfile.mkdtemp(prefix="native_conv_")
    mc = os.path.join(work, "llvm-mc")
    shutil.copy2(LLVM_MC, mc)
    print("llvm-mc sha256 %s" % hashlib.sha256(open(mc, "rb").read()).hexdigest()[:16])

    cands, keep = [], []
    for r in rows:
        try:
            want = bytes.fromhex(r["want_bytes"])
        except ValueError:
            continue
        a = annotate(r["unidasm_text"], want)
        if a is None:
            continue
        cands.append(uni_to_llvm(a)); keep.append((r, want))
    print("sites reachable by a width annotation: %d spellings, %d sites"
          % (len(cands), sum(int(r["sites"]) for r, _ in keep)))
    got = assemble(cands, mc, work)

    cnt, sites = collections.Counter(), collections.Counter()
    fixed = []
    for (r, want), g in zip(keep, got):
        if g is None:
            k = "STILL_REJECTS"
        elif g == "RELOC":
            k = "RELOC"
        elif g == want:
            k = "NOW_CORRECT"
        else:
            k = "STILL_WRONG"
        cnt[k] += 1; sites[k] += int(r["sites"])
        if k == "NOW_CORRECT":
            fixed.append((r["verdict"], r["llvm_mnemonic"],
                          r["unidasm_text"], r["sites"]))
    print("%-16s %10s %10s" % ("after width", "spellings", "sites"))
    for k in ("NOW_CORRECT", "STILL_WRONG", "STILL_REJECTS", "RELOC"):
        print("%-16s %10d %10d" % (k, cnt[k], sites[k]))
    with open(os.path.join(outdir, "native_convergence_fixed.csv"), "w") as f:
        f.write("original_verdict,llvm_mnemonic,unidasm_text,sites\n")
        for v, m, t, n in sorted(fixed, key=lambda x: -int(x[3])):
            f.write('%s,%s,"%s",%s\n' % (v, m, t, n))
    fm = collections.Counter()
    for v, m, t, n in fixed:
        fm[m] += int(n)
    print("\ntree mnemonics fully reachable this way: %d" % len(fm))
    for k, n in fm.most_common(20):
        print("   %-16s %8d" % (k, n))
    print("\nwrote %s/native_convergence_fixed.csv" % outdir)
    shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else
         "notes/syntax-convergence-probes/out")
