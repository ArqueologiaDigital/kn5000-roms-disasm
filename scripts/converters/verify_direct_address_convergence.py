#!/usr/bin/env python3
"""
QUESTION IT ANSWERS: every line this branch respelled -- does the NEW spelling
assemble to exactly the bytes the OLD one did, under ONE named assembler?

`convert_direct_address_family.py` checks each site as it writes it, but the
shared `llvm-mc` is relinked by backend lanes several times an evening (five
times on 2026-09-02 alone, all while `git log` said the same commit).  A
per-site check taken with one binary and a byte gate taken with the next are
two measurements, not one.  This re-checks the WHOLE branch with a single
binary you name, after the fact.

It reads the change out of git rather than out of the converter, so it does not
share state with the thing it is testing.

EXACT COMMAND (from the tree root):

    python3 scripts/converters/verify_direct_address_convergence.py \
        --base main \
        --llvm-mc ~/compartilhado/toolchain-snapshot/llvm-mc.snap

Exit status 0 only if every changed line pair encodes identically.

⚠ It requires the change to be LINE-FOR-LINE: same line count before and after,
which is what a mnemonic respelling is.  A file whose line count moved is
reported and NOT certified -- deliberately, because pairing lines across an
insertion would compare the wrong two lines and pass.
"""
import argparse, collections, hashlib, os, re, subprocess, sys, tempfile

MARK = "zzVerifyMark"
ENCRX = re.compile(r'encoding: \[([^\]]*)\]')
FIXRX = re.compile(r'fixup \w+ - (.*)$')
# The seventeen synthetic spellings this branch retires, plus the natives they
# become.  A changed line whose old text does not start with one of these is
# not ours and is reported, not silently accepted.
OLD_MNEMONICS = {
    "stda16", "stda32", "stb_da", "stw_da", "stib_da", "stiw_da",
    "stdi8", "stdi16", "cpdi8", "cpdi16", "anddi8", "ordi8", "bitda",
    "ldb_da", "ldw_da", "ldl_da", "ldda32",
}


def assemble(lines, mc):
    src = []
    for i, l in enumerate(lines):
        src.append("%s%d:" % (MARK, i))
        src.append("\t" + l)
    with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False,
                                     encoding="utf-8") as fh:
        fh.write("\n".join(src) + "\n")
        path = fh.name
    try:
        p = subprocess.run([mc, "-triple=tlcs900", "-show-encoding", path],
                           capture_output=True, text=True, errors="replace")
    finally:
        os.unlink(path)
    bad = set()
    for m in re.finditer(r'^[^\n:]*:(\d+):\d+: error:', p.stderr, re.M):
        idx = (int(m.group(1)) - 1) // 2
        if 0 <= idx < len(lines):
            bad.add(idx)
    sig, cur = {}, None
    for line in p.stdout.split("\n"):
        lm = re.match(r'^%s(\d+):' % MARK, line)
        if lm:
            cur = int(lm.group(1))
            sig.setdefault(cur, [])
            continue
        if cur is None:
            continue
        m = ENCRX.search(line)
        if m:
            sig[cur].append("E:" + m.group(1))
            continue
        m = FIXRX.search(line)
        if m:
            sig[cur].append("F:" + m.group(1))
    return [None if i in bad or not sig.get(i) else "|".join(sig[i])
            for i in range(len(lines))]


def strip_comment(line):
    return line.split(";", 1)[0].strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="main")
    ap.add_argument("--head", default="HEAD")
    ap.add_argument("--llvm-mc", required=True)
    ap.add_argument("--chunk", type=int, default=4000)
    args = ap.parse_args()

    mc = os.path.expanduser(args.llvm_mc)
    print("assembler %s\n  sha256 %s" %
          (mc, hashlib.sha256(open(mc, "rb").read()).hexdigest()))

    files = subprocess.run(
        ["git", "diff", "--name-only", "%s..%s" % (args.base, args.head)],
        capture_output=True, text=True).stdout.split()
    files = [f for f in files if f.endswith(".s")]
    print("changed .s files: %d" % len(files))

    pairs, skipped = [], []
    for f in files:
        old = subprocess.run(["git", "show", "%s:%s" % (args.base, f)],
                             capture_output=True).stdout.decode("latin-1")
        new = subprocess.run(["git", "show", "%s:%s" % (args.head, f)],
                             capture_output=True).stdout.decode("latin-1")
        ol, nl = old.split("\n"), new.split("\n")
        if len(ol) != len(nl):
            skipped.append((f, "line count %d -> %d" % (len(ol), len(nl))))
            continue
        for i, (a, b) in enumerate(zip(ol, nl)):
            if a != b:
                pairs.append((f, i + 1, strip_comment(a), strip_comment(b), a))

    print("changed lines: %d   files not line-for-line: %d"
          % (len(pairs), len(skipped)))
    for f, why in skipped:
        print("   SKIPPED %s (%s)" % (f, why))

    foreign = [p for p in pairs
               if (p[2].split() or [""])[0] not in OLD_MNEMONICS]
    if foreign:
        print("\n⚠ %d changed lines are NOT a retired direct-address mnemonic:"
              % len(foreign))
        for p in foreign[:20]:
            print("   %s:%d  %r" % (p[0], p[1], p[4]))

    bad = []
    per = collections.Counter()
    for base in range(0, len(pairs), args.chunk):
        ch = pairs[base:base + args.chunk]
        oa = assemble([c[2] for c in ch], mc)
        na = assemble([c[3] for c in ch], mc)
        for c, o, n in zip(ch, oa, na):
            if o is None or n is None or o != n:
                bad.append((c, o, n))
            else:
                per[(c[2].split() or [""])[0]] += 1
        sys.stderr.write("\r  %d/%d" % (min(base + args.chunk, len(pairs)),
                                        len(pairs)))
    sys.stderr.write("\n")

    print("\n%-10s %8s" % ("old mnemonic", "verified"))
    for k, v in per.most_common():
        print("%-10s %8d" % (k, v))
    print("%-10s %8d" % ("TOTAL", sum(per.values())))

    if bad:
        print("\nFAIL: %d line pairs do not encode identically" % len(bad))
        for (c, o, n) in bad[:20]:
            print("   %s:%d\n     old %-40s %s\n     new %-40s %s"
                  % (c[0], c[1], c[2], o, c[3], n))
        return 1
    if skipped or foreign:
        print("\nINCOMPLETE: %d file(s) skipped, %d foreign line(s)."
              % (len(skipped), len(foreign)))
        return 2
    print("\nPASS: every changed line encodes identically under this assembler.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
