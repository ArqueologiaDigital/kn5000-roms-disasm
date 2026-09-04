#!/usr/bin/env python3
"""How exposed is the tree to the encoding selectors `:i3` / `:opc` / `:io`?

Every number the encoding-selector spec quotes
(notes/SPEC-encoding-selectors-2026-09-04.md) comes from one of the sections
below.  Run it from the tree root; it reads the committed sources through
`git ls-files` and, for the byte facts, the PINNED assembler:

    python3 notes/syntax-convergence-probes/encoding_selector_exposure.py
    python3 notes/syntax-convergence-probes/encoding_selector_exposure.py \
        --llvm-mc ~/compartilhado/toolchain-snapshot/llvm-mc.snap

Q1  How many committed sites spell each synthetic name the selectors retire
    (cps lds lds32 lds8 ldb ldio ldwio), and in how many files?  Line-start
    census over tracked *.s *.inc *.asm -- the same regex as the spec's
    one-liner, so the spec's 71,667 is checkable here.
Q2  Constraint 1 -- how many LONG-form sites would an "assembler picks the
    shortest that fits" rule silently shorten: `cp <reg>, 0..7` and
    `ld <reg>, 0..7` written without a selector.  None of these lines may
    change encoding.
Q3  How many small-immediate operands (cps/lds/lds32/lds8) are NOT a literal,
    what they are (macro `\\Param` substitutions), and the distribution of the
    literal values -- is any outside 0..7?  This is the step-6 exposure for the
    PrefixSmallImm diagnostic (refuse >7, refuse a symbol).
Q4  Introduction is inert -- how many instruction operands already carry a ':'
    OUTSIDE parentheses (the grammar slot the selector takes), by top-level
    directory.  Gated sources must count zero.
Q5  Gate blindness -- how many sites write the UNTAGGED io default rows
    `ld (n:8), ...` and `ldw (n:8), ...`.  A family whose default is exercised
    by no source line is invisible to gate-all; only the lit byte-pin sees it.
Q6  ldio/ldwio operand shapes -- are the address and the value literals, and
    do they fit 8 / 8 / 16 bits?  Step-6 exposure for the LdIoImm diagnostics.
Q7  stib_d8 / stiw_d8 sites -- their PRINTED text changes at step 7 (decoder
    re-point); their bytes and their source spelling do not.
Q8  (needs llvm-mc) the three-encoding tie `ld d, 4` / `lds8 d, 4` /
    `ldb d, 4`, the three live silent miscompiles (`cps a, 9`, `lds hl, 8`,
    `cps a, SYMX`), the io address truncation (`ldio 0x1ff, 0xff`), and that
    every selector spelling is a hard parse error at the pinned binary.

⚠ The assembler is named by sha256, never only by path: the same commit has
produced five different llvm-mc binaries in one week.
"""
import argparse, collections, hashlib, os, re, subprocess, sys

FAMILIES = ["cps", "lds", "lds32", "lds8", "ldb", "ldio", "ldwio"]
GLOBS = ("*.s", "*.inc", "*.asm")


def tracked(root):
    out = subprocess.run(["git", "ls-files", "-z", *GLOBS], cwd=root,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\0") if p]


def read(root, path):
    return open(os.path.join(root, path), encoding="latin-1").read().split("\n")


def is_literal(tok):
    return re.fullmatch(r"-?(0[xX][0-9a-fA-F]+|\d+)", tok) is not None


def literal_value(tok):
    return int(tok, 0)


def strip_comment(line):
    # `;` starts a comment except inside a string literal
    out, q = [], False
    for ch in line:
        if ch == '"':
            q = not q
        if ch == ";" and not q:
            break
        out.append(ch)
    return "".join(out)


def q1_q3_q6_q7(root, files):
    counts = collections.Counter()
    cfiles = collections.defaultdict(set)
    small_nonlit = collections.Counter()
    small_vals = collections.Counter()
    io_shape = collections.Counter()
    io_symbols = collections.Counter()
    stib = collections.Counter()
    fam_re = {m: re.compile(r"^\s*\b" + m + r"\b(?=\s)") for m in FAMILIES}
    ops_re = re.compile(r"^\s*(\w+)\s+(.*)$")
    for path in files:
        for line in read(root, path):
            for m, rx in fam_re.items():
                if rx.match(line):
                    counts[m] += 1
                    cfiles[m].add(path)
            code = strip_comment(line)
            mo = ops_re.match(code)
            if not mo:
                continue
            mn, rest = mo.group(1), mo.group(2)
            if mn in ("stib_d8", "stiw_d8"):
                stib[mn] += 1
            if mn in ("cps", "lds", "lds32", "lds8"):
                parts = [p.strip() for p in rest.split(",")]
                if len(parts) == 2:
                    imm = parts[1]
                    if is_literal(imm):
                        small_vals[literal_value(imm)] += 1
                    else:
                        small_nonlit[imm] += 1
            if mn in ("ldio", "ldwio"):
                parts = [p.strip() for p in rest.split(",")]
                if len(parts) != 2:
                    io_shape[(mn, "not two operands")] += 1
                    continue
                a, v = parts
                if not is_literal(a):
                    io_shape[(mn, "address is a symbol")] += 1
                    io_symbols[a] += 1
                elif not 0 <= literal_value(a) <= 255:
                    io_shape[(mn, "address outside 0..255")] += 1
                if not is_literal(v):
                    io_shape[(mn, "value not a literal: " + v)] += 1
                else:
                    lim = 0xFF if mn == "ldio" else 0xFFFF
                    if not -lim - 1 <= literal_value(v) <= lim:
                        io_shape[(mn, "value does not fit")] += 1
                if is_literal(a) and is_literal(v):
                    io_shape[(mn, "literal, in range")] += 1
    return counts, cfiles, small_nonlit, small_vals, io_shape, io_symbols, stib


def q2(root, files):
    cp = re.compile(r"^\s*cp\s+\w+,\s*(0x0?[0-7]|[0-7])\b")
    ld = re.compile(r"^\s*ld\s+\w+,\s*(0x0?[0-7]|[0-7])\b")
    ncp = collections.Counter()
    nld = collections.Counter()
    for path in files:
        top = path.split("/", 1)[0]
        for line in read(root, path):
            if cp.match(line):
                ncp[top] += 1
            if ld.match(line):
                nld[top] += 1
    return ncp, nld


def q4(root, files):
    insn = re.compile(r"^[ \t]+([A-Za-z_][\w.]*)(?:[ \t]+(.*))?$")
    by_dir = collections.Counter()
    hits = []
    for path in files:
        top = "/".join(path.split("/")[:2]) if path.startswith("archive/") else path.split("/", 1)[0]
        for n, line in enumerate(read(root, path), 1):
            code = strip_comment(line)
            m = insn.match(code)
            if not m or m.group(1).endswith(":") or not m.group(2):
                continue
            ops = re.sub(r'"[^"]*"', '""', m.group(2))
            ops = re.sub(r"\([^()]*\)", "()", ops)
            if ":" in ops:
                by_dir[top] += 1
                hits.append((path, n, line.strip()))
    return by_dir, hits


def q5(root, files):
    ld8 = re.compile(r"^\s*ld\s+\(\s*[^)]*:8\s*\)\s*,")
    ldw8 = re.compile(r"^\s*ldw\s+\(\s*[^)]*:8\s*\)\s*,")
    a = b = 0
    for path in files:
        for line in read(root, path):
            if ld8.match(line):
                a += 1
            if ldw8.match(line):
                b += 1
    return a, b


def q8(mc):
    h = hashlib.sha256(open(mc, "rb").read()).hexdigest()
    print("Q8  byte facts at llvm-mc sha256 %s" % h)
    lines = ["ld d, 4", "lds8 d, 4", "ldb d, 4", "ld w, 0", "ldb w, 0",
             "lds8 w, 0", "cp xwa, 5", "cps xwa, 5", "cps a, 9", "lds hl, 8",
             "cps a, SYMX", "ldio 0x1ff, 0xff", "ld (0x07:8), 0xff",
             "ldw (237:8), 0x8e00", "cp a, 4:i3", "ld d, 4:opc",
             "ld (0x07:8), 0xff:io"]
    for l in lines:
        r = subprocess.run([mc, "-triple=tlcs900", "-show-encoding"],
                           input=l + "\n", capture_output=True, text=True)
        enc = re.search(r"encoding: \[([^\]]*)\]", r.stdout)
        err = [e for e in r.stderr.split("\n") if "error:" in e]
        print("    %-24s -> %s%s" % (l, enc.group(1).replace("0x", "") if enc else "(none)",
                                     "   ERROR: " + err[0].split("error: ")[1] if err else ""))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--llvm-mc", default=os.path.expanduser(
        "~/compartilhado/toolchain-snapshot/llvm-mc.snap"))
    ap.add_argument("--show-colon-hits", action="store_true")
    a = ap.parse_args()
    files = tracked(a.root)
    print("tracked %s files: %d" % ("/".join(GLOBS), len(files)))

    counts, cfiles, nonlit, vals, io_shape, io_symbols, stib = q1_q3_q6_q7(a.root, files)
    print("\nQ1  sites per retired synthetic name (line-start census):")
    for m in FAMILIES:
        print("    %-6s %6d sites in %3d files" % (m, counts[m], len(cfiles[m])))
    print("    total  %6d" % sum(counts.values()))

    ncp, nld = q2(a.root, files)
    print("\nQ2  constraint-1 exposure (long-form sites a shortest-fits rule would rewrite):")
    print("    cp <reg>, 0..7 : %d" % sum(ncp.values()))
    print("    ld <reg>, 0..7 : %d" % sum(nld.values()))
    print("    total          : %d" % (sum(ncp.values()) + sum(nld.values())))
    for d in sorted(set(ncp) | set(nld)):
        print("      %-14s cp %5d   ld %5d" % (d, ncp[d], nld[d]))

    print("\nQ3  small-immediate operands of cps/lds/lds32/lds8:")
    print("    non-literal: %d" % sum(nonlit.values()))
    for k, v in nonlit.most_common():
        print("      %6d  %s" % (v, k))
    out = sum(v for k, v in vals.items() if not 0 <= k <= 7)
    print("    literal values: %d, outside 0..7: %d" % (sum(vals.values()), out))
    print("      " + "  ".join("%d:%d" % (k, vals[k]) for k in sorted(vals)))

    by_dir, hits = q4(a.root, files)
    print("\nQ4  instruction operands with a ':' outside parentheses, by top-level dir:")
    if not by_dir:
        print("    none")
    for d, n in sorted(by_dir.items()):
        print("    %-20s %d" % (d, n))
    if a.show_colon_hits:
        for p, n, l in hits:
            print("      %s:%d: %s" % (p, n, l))

    ld8, ldw8 = q5(a.root, files)
    print("\nQ5  untagged io default rows in the tree (gate blindness):")
    print("    ld  (n:8), ... : %d sites" % ld8)
    print("    ldw (n:8), ... : %d sites" % ldw8)

    print("\nQ6  ldio/ldwio operand shapes:")
    for (mn, what), n in sorted(io_shape.items()):
        print("    %-6s %6d  %s" % (mn, n, what))
    if io_symbols:
        defined = set()
        for path in files:
            for line in read(a.root, path):
                m = re.match(r"^\s*\.(?:equ|set)\s+(\w+)\s*,", line)
                if m:
                    defined.add(m.group(1))
        undefined = [s for s in io_symbols if s not in defined]
        print("    symbolic addresses: %d distinct names (TMP94C241 SFR names from "
              "sfr_tmp94c241.s); not .equ-defined anywhere: %d %s"
              % (len(io_symbols), len(undefined), undefined))
        print("    ⚠ a symbol the parser cannot fold (forward reference or undefined) "
              "assembles TODAY to address 0x00 with no diagnostic: `ldio P5CR, 0x29` "
              "before its .equ -> 08 00 29 at the pinned binary.")

    print("\nQ7  stib_d8 / stiw_d8 sites: %d / %d" % (stib["stib_d8"], stib["stiw_d8"]))

    if os.path.exists(a.llvm_mc):
        print()
        q8(a.llvm_mc)
    else:
        print("\nQ8  skipped: no assembler at %s" % a.llvm_mc)


if __name__ == "__main__":
    main()
