#!/usr/bin/env python3
"""
QUESTION IT ANSWERS: can the direct-address family of SYNTHETIC mnemonics --
the ones that carry the address WIDTH and the operand SIZE in the mnemonic --
be respelled with the NATIVE mnemonic plus the width annotation the assembler
already supports (`(0x2075:16)`, TOOLCHAIN_VERSION UPDATE 7), without changing
a single ROM byte?

    ldb_da  a, (0x120000)   ->   ld  a, (0x120000:24)
    stda16  61458, xwa      ->   ld  (61458:16), wa
    cpdi16  10215, 48       ->   cpw (10215:16), 48

This implements section 8 of notes/ASSESSMENT-syntax-convergence-2026-09-02.md
("Option B, one mnemonic family at a time").

⚠ THE ADDRESS WIDTH IS NOT DERIVABLE FROM THE ADDRESS VALUE.  This firmware
writes `set 7,(0x00008a)` as a 24-bit field for an 8-bit address.  The width
below is read off the MNEMONIC -- i.e. off the prefix byte the mnemonic is
defined to emit in TLCS900InstrInfo.td -- never off the number.

⚠ EVERY SITE IS VERIFIED INDIVIDUALLY, not per family.  The old and the new
spelling of each line are assembled in isolation by llvm-mc and their encodings
(including relocation fixups) must be identical byte for byte before the line
is written.  A family-level byte gate can be green while one site changed and
another compensated; this cannot.

EXACT COMMANDS (from the tree root):

    # dry run: report only, writes nothing
    python3 scripts/converters/convert_direct_address_family.py --mnemonic stdi8

    # convert and write
    python3 scripts/converters/convert_direct_address_family.py --mnemonic stdi8 --apply

    # all seventeen at once
    python3 scripts/converters/convert_direct_address_family.py --all --apply

Then, always:  make gate-all
"""
import argparse, collections, csv, hashlib, os, re, shutil, subprocess, sys, tempfile

HOME = os.path.expanduser("~")
LLVM_MC = os.environ.get(
    "LLVM_MC", os.path.join(HOME, "compartilhado/llvm-project/build/bin/llvm-mc"))

# ---------------------------------------------------------------- the mapping
#
# width  = the ADDRESS field width the mnemonic is defined to emit
#          (C0/D0/E0/F0 = 8, C1/D1/E1/F1 = 16, C2/D2/E2/F2 = 24).
# addr   = which operand (0-based) is the direct address.
# regmap = the register class the OTHER operand really denotes, which the
#          synthetic mnemonic did not say.  None = the other operand is an
#          immediate and is copied through untouched.
MAP = {
    # 8-bit data
    "ldb_da":  dict(native="ld",  width=24, addr=1, regmap="r8"),
    "stb_da":  dict(native="ld",  width=24, addr=0, regmap="r8"),
    "stib_da": dict(native="ld",  width=24, addr=0, regmap=None),
    "stdi8":   dict(native="ld",  width=16, addr=0, regmap=None),
    "cpdi8":   dict(native="cp",  width=16, addr=0, regmap=None),
    "anddi8":  dict(native="and", width=16, addr=0, regmap=None),
    "ordi8":   dict(native="or",  width=16, addr=0, regmap=None),
    # 16-bit data
    "ldw_da":  dict(native="ld",  width=24, addr=1, regmap="r16"),
    "stw_da":  dict(native="ld",  width=24, addr=0, regmap="r16"),
    "stda16":  dict(native="ld",  width=16, addr=0, regmap="r16"),
    "stiw_da": dict(native="ldw", width=24, addr=0, regmap=None),
    "stdi16":  dict(native="ldw", width=16, addr=0, regmap=None),
    "cpdi16":  dict(native="cpw", width=16, addr=0, regmap=None),
    # 32-bit data
    "ldl_da":  dict(native="ld",  width=24, addr=1, regmap="r32"),
    "ldda32":  dict(native="ld",  width=16, addr=1, regmap="r32"),
    "stda32":  dict(native="ld",  width=16, addr=0, regmap="r32"),
    # bit, no data size
    "bitda":   dict(native="bit", width=16, addr=1, regmap=None),
}

R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]

# A 32-bit register NAME written against a 16-bit form denotes the 16-bit
# register with the SAME FILE INDEX -- verified by encoding all eight, both
# spellings, and comparing the sub-opcode byte.
X_TO_16 = dict(zip(R32, R16))
# Against an 8-bit form it denotes that register pair's LOW BYTE.  Only the
# four pairs that HAVE an 8-bit half are mapped; xix/xiy/xiz/xsp are refused
# rather than guessed (none occur in this tree).  Corroborated by the source's
# own comment at hdae5000/hdae5000_hd_driver.s:403,
#     ldb_da xwa, (0x229d99); c2 99 9d 22 21 - ld a, (0x229d99)
X_TO_8 = {"xwa": "a", "xbc": "c", "xde": "e", "xhl": "l"}

REGSETS = {"r32": set(R32), "r16": set(R16), "r8": set(R8)}

MARK = "zzConvWidthMark"


def line_re(mnemonics):
    return re.compile(r'^(\t)(%s)([ \t]+)([^;]*?)([ \t]*)(;.*)?$'
                      % "|".join(sorted(mnemonics, key=len, reverse=True)))


def split_ops(s):
    """Split on top-level commas, honouring parentheses."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    out.append(cur.strip())
    return out


def unparen(a):
    """Strip ONE enclosing pair of parentheses, only if it really encloses."""
    if not (a.startswith("(") and a.endswith(")")):
        return a
    depth = 0
    for i, ch in enumerate(a):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return a[1:-1].strip() if i == len(a) - 1 else a
    return a


def rewrite(mn, operands, foil=None):
    """Return the new operand text, or (None, reason).

    ⚠ CONTROL.  foil="width" states the OTHER address width (16<->24) and
    foil="reg" leaves a 32-bit register name where the form needs a 16-bit
    one.  Both must make this script REFUSE every site it would otherwise
    convert; a verifier that cannot go red has certified nothing.  See the
    README beside this file for the two runs and their counts."""
    spec = MAP[mn]
    if len(operands) != 2:
        return None, "operand-count-%d" % len(operands)
    ops = list(operands)
    inner = unparen(ops[spec["addr"]])
    if inner.startswith("(") or not inner:
        return None, "unparseable-address"
    w = spec["width"]
    if foil == "width":
        w = 24 if w == 16 else 16
    ops[spec["addr"]] = "(%s:%d)" % (inner, w)
    rm = spec["regmap"]
    if foil == "reg" and rm == "r16":
        rm = None
    if rm:
        oi = 1 - spec["addr"]
        r = ops[oi].lower()
        if r in REGSETS[rm]:
            pass                                  # already the right class
        elif rm == "r16" and r in X_TO_16:
            ops[oi] = X_TO_16[r]
        elif rm == "r8" and r in X_TO_8:
            ops[oi] = X_TO_8[r]
        elif rm == "r8" and r in R32:
            return None, "x-name-with-no-8bit-half:%s" % r
        else:
            return None, "unrecognised-register:%s" % r
    return ", ".join(ops), None


# ------------------------------------------------------------------ assembler
ENCRX = re.compile(r'encoding: \[([^\]]*)\]')
FIXRX = re.compile(r'fixup \w+ - (.*)$')


def assemble(lines, mc):
    """Assemble each line in isolation.  Returns a list of signatures; None
    means the assembler rejected it."""
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
    out = []
    for i in range(len(lines)):
        out.append(None if i in bad or not sig.get(i) else "|".join(sig[i]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mnemonic", action="append", default=[])
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--manifest", default=None,
                    help="write the list of files actually rewritten here, so "
                         "the commit can name its FILES rather than use -u")
    ap.add_argument("--report", default=None,
                    help="CSV of every refused site")
    ap.add_argument("--chunk", type=int, default=4000)
    ap.add_argument("--foil", choices=("width", "reg"), default=None,
                    help="deliberately break the rewrite; every site must be "
                         "refused with BYTES-DIFFER (the verifier's control)")
    args = ap.parse_args()

    mns = list(MAP) if args.all else args.mnemonic
    bad = [m for m in mns if m not in MAP]
    if bad or not mns:
        sys.exit("give --all or --mnemonic from: %s (unknown: %s)"
                 % (" ".join(sorted(MAP)), bad))

    work = tempfile.mkdtemp(prefix="conv_width_")
    mc = os.path.join(work, "llvm-mc")
    shutil.copy2(LLVM_MC, mc)          # the shared toolchain is rebuilt under us
    print("llvm-mc sha256 %s"
          % hashlib.sha256(open(mc, "rb").read()).hexdigest()[:16])

    files = subprocess.run(["git", "ls-files", "*.s"],
                           capture_output=True, text=True).stdout.split()
    rx = line_re(mns)

    sites = []          # (path, lineno, mn, oldline, newline)
    refused = []        # (path, lineno, mn, oldline, reason)
    for f in files:
        src = open(f, encoding="latin-1").read()
        for n, line in enumerate(src.split("\n")):
            m = rx.match(line)
            if not m:
                continue
            mn = m.group(2)
            ops, reason = rewrite(mn, split_ops(m.group(4)), args.foil)
            if ops is None:
                refused.append((f, n + 1, mn, line, reason))
                continue
            new = m.group(1) + MAP[mn]["native"] + m.group(3) + ops \
                + m.group(5) + (m.group(6) or "")
            sites.append([f, n + 1, mn, line, new,
                          mn + " " + m.group(4).strip(),
                          MAP[mn]["native"] + " " + ops])

    print("candidate sites: %d   refused before assembly: %d"
          % (len(sites), len(refused)))

    # ---- per-site byte verification -------------------------------------
    ok = []
    for base in range(0, len(sites), args.chunk):
        chunk = sites[base:base + args.chunk]
        olds = assemble([c[5] for c in chunk], mc)
        news = assemble([c[6] for c in chunk], mc)
        for c, o, n in zip(chunk, olds, news):
            if o is None:
                refused.append((c[0], c[1], c[2], c[3], "old-does-not-assemble"))
            elif n is None:
                refused.append((c[0], c[1], c[2], c[3], "new-does-not-assemble"))
            elif o != n:
                refused.append((c[0], c[1], c[2], c[3],
                                "BYTES-DIFFER old=%s new=%s" % (o, n)))
            else:
                ok.append(c)
        sys.stderr.write("\r  verified %d/%d" % (min(base + args.chunk,
                                                     len(sites)), len(sites)))
    sys.stderr.write("\n")
    shutil.rmtree(work, ignore_errors=True)

    per = collections.Counter(c[2] for c in ok)
    ref = collections.Counter(r[2] for r in refused)
    why = collections.Counter(r[4].split()[0] for r in refused)
    print("\n%-10s %8s %8s" % ("mnemonic", "convert", "refuse"))
    for mn in sorted(mns, key=lambda m: -per[m]):
        print("%-10s %8d %8d" % (mn, per[mn], ref[mn]))
    print("%-10s %8d %8d" % ("TOTAL", len(ok), len(refused)))
    if refused:
        print("\nrefusal reasons:")
        for k, v in why.most_common():
            print("   %-30s %6d" % (k, v))

    if args.report:
        with open(args.report, "w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["file", "line", "mnemonic", "source", "reason"])
            for r in refused:
                w.writerow(r)
        print("\nwrote %s" % args.report)

    if args.foil:
        print("\nFOIL RUN (--foil %s): --apply is refused." % args.foil)
        return
    if not args.apply:
        print("\ndry run -- nothing written.  Re-run with --apply.")
        return

    byfile = collections.defaultdict(dict)
    for c in ok:
        byfile[c[0]][c[1]] = (c[3], c[4])
    changed = 0
    for f, edits in byfile.items():
        src = open(f, encoding="latin-1").read()
        lines = src.split("\n")
        for n, (old, new) in edits.items():
            assert lines[n - 1] == old, "%s:%d moved under us" % (f, n)
            lines[n - 1] = new
        # ⚠ encode the WHOLE file first.  open(...,"w",encoding="latin-1")
        # truncates the file to zero bytes when a character will not encode.
        data = "\n".join(lines).encode("latin-1")
        tmp = f + ".convtmp"
        with open(tmp, "wb") as fh:
            fh.write(data)
        os.replace(tmp, f)
        changed += 1
    print("\nrewrote %d files, %d lines" % (changed, len(ok)))
    if args.manifest:
        with open(args.manifest, "w") as fh:
            fh.write("\n".join(sorted(byfile)) + "\n")
        print("wrote %s" % args.manifest)


if __name__ == "__main__":
    main()
