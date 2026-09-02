#!/usr/bin/env python3
"""branch_displacement_field_audit.py -- which JR / JRL / CALR / DJNZ operands
in this tree do not fit the displacement field they are written into?

THE DEFECT THIS ANSWERS FOR
    On this backend `jr`, `jrl`, `calr` and `djnz` take the RAW DISPLACEMENT
    FIELD, not a target address.  `jrl` and `calr` have refused an operand too
    wide for their 16-bit field since tlcs900_backend@95f7f2d40428; `jr` and
    `djnz` masked with `& 0xFF` instead, so `jr 99832` silently assembled to
    [0x68,0xf8] -- a branch to somewhere else entirely, with no diagnostic.
    That is the same shape as `push (0x1234)` -> `09 34` and
    `mul WA,(0x1234)` multiplying by the address (TOOLCHAIN_VERSION UPDATE 7/8).

    ⚠ THE GATE CANNOT SEE IT.  Where the truncated byte happens to be the byte
    the ROM holds, the image still rebuilds byte-identically.  The error is in
    what the SOURCE SAYS, and only re-deriving or relocating the region would
    expose it.

TWO CLASSES, and they are not the same mistake
    SIGN-EXTENDED DISPLACEMENT -- `jr c, 16777183` for -33.  The disassembly
        that produced the line widened the field to 24 bits.  The value IS the
        displacement; only its width is wrong.  Truncating it moves no byte.
        This is exactly what 95f7f2d40428 found in 31 `jrl` operands.
    TARGET ADDRESS -- `jr T,0xfe434d` at FE42FE, bytes `68 4d`.  The line names
        the DESTINATION, and the right byte comes out only because the
        instruction ends at 0xFE4300, so the target's low byte IS the
        displacement.  Move the code by one byte and the source silently
        assembles a branch to the wrong place.  Reported separately: it is a
        defect in the tree, not only in the assembler.

RUN
    python3 scripts/analysis/branch_displacement_field_audit.py            # census
    python3 scripts/analysis/branch_displacement_field_audit.py --apply    # rewrite
    python3 scripts/analysis/branch_displacement_field_audit.py --selftest

⚠ Sources are LATIN-1 and contain raw high bytes inside .ascii literals; this
script reads and writes with an explicit latin-1 codec and rewrites ONLY the
operand text of the lines it reports (see the brief's Edit-tool addendum).
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# mnemonic -> displacement field width in bits
FIELD = {"jr": 8, "djnz": 8, "jrl": 16, "calr": 16}

LINE_RE = re.compile(r'^(\s*)(jr|jrl|calr|djnz)(\s+)(.*)$', re.IGNORECASE)


def fits(v, bits):
    return -(1 << (bits - 1)) <= v < (1 << bits)


def sources():
    for root, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d != ".git"]
        for f in files:
            if f.endswith(".s") or f.endswith(".inc"):
                yield os.path.join(root, f)


def scan():
    """-> list of (path, lineno, mnemonic, operand_text, value, bits, line)"""
    out = []
    for fp in sources():
        try:
            src = open(fp, encoding="latin-1").read()
        except OSError:
            continue
        for n, line in enumerate(src.split("\n"), 1):
            code = line.split(";")[0]
            m = LINE_RE.match(code)
            if not m:
                continue
            mn = m.group(2).lower()
            ops = m.group(4).strip()
            if not ops:
                continue
            last = ops.split(",")[-1].strip()
            try:
                v = int(last, 0)
            except ValueError:
                continue          # a label: the fixup path, never truncated
            bits = FIELD[mn]
            if not fits(v, bits):
                out.append((fp, n, mn, last, v, bits, line))
    return out


def classify(v, bits, line):
    """SIGN-EXTENDED if the value is the field sign-extended to 24 bits;
    TARGET if the line's own address comment shows it naming a destination."""
    mask = (1 << bits) - 1
    low = v & mask
    signed = low - (1 << bits) if low >> (bits - 1) else low
    if v == (signed & 0xFFFFFF) and v > 0xFFFF:
        return "SIGN-EXTENDED", signed
    return "TARGET?", signed


def run(apply_it=False):
    hits = scan()
    print("%d operand(s) do not fit their displacement field\n" % len(hits))
    per = {}
    for fp, n, mn, last, v, bits, line in hits:
        kind, signed = classify(v, bits, line)
        per.setdefault(kind, []).append((fp, n, mn, last, v, signed, line))
    for kind in sorted(per):
        rows = per[kind]
        print("=== %s: %d site(s) ===" % (kind, len(rows)))
        for fp, n, mn, last, v, signed, line in rows:
            print("  %s:%d  %s %s -> %d   |%s"
                  % (os.path.relpath(fp, ROOT), n, mn, last, signed, line.strip()[:70]))
        print()
    if not apply_it:
        print("(dry run -- pass --apply to rewrite the operands)")
        return 0

    byfile = {}
    for fp, n, mn, last, v, bits, line in hits:
        signed = classify(v, bits, line)[1]
        # Keep the file's own notation: wsa1's converter writes displacements
        # as unsigned hex (`jr 0x40`), the KN5000 trees as signed decimal.
        # Rewriting one into the other would make a 36-line change look like a
        # style edit in the diff.
        repl = ("0x%02x" % (signed & ((1 << bits) - 1))
                if last.lower().startswith("0x") else str(signed))
        byfile.setdefault(fp, []).append((n, last, repl))
    changed = 0
    for fp, rows in byfile.items():
        src = open(fp, encoding="latin-1").read()
        lines = src.split("\n")
        for n, last, repl in rows:
            old = lines[n - 1]
            # Replace only the operand token, and only once, so a comment that
            # happens to contain the same digits is left alone.
            code, sep, comment = old.partition(";")
            assert last in code, (fp, n, last)
            lines[n - 1] = code.replace(last, repl, 1) + sep + comment
            changed += 1
        out = "\n".join(lines)
        open(fp, "w", encoding="latin-1").write(out)
        print("  rewrote %d line(s) in %s" % (len(rows), os.path.relpath(fp, ROOT)))
    print("\n%d operand(s) rewritten. `make gate-all` must stay GREEN: the "
          "truncation was all the old assembler did, so no byte may move."
          % changed)
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("an 8-bit field accepts -128..255", fits(-128, 8) and fits(255, 8))
    ck("an 8-bit field rejects 256 and -129", not fits(256, 8) and not fits(-129, 8))
    ck("16777183 is -33 sign-extended to 24 bits",
       classify(16777183, 8, "") == ("SIGN-EXTENDED", -33),
       str(classify(16777183, 8, "")))
    ck("0xfe434d is NOT a sign-extended 8-bit displacement",
       classify(0xFE434D, 8, "")[0] == "TARGET?", str(classify(0xFE434D, 8, "")))
    # A control: the scan must find nothing in a file with only in-range and
    # symbolic operands, or "0 hits" would mean nothing.
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        p = os.path.join(td, "t.s")
        open(p, "w", encoding="latin-1").write("\tjr 0x40\n\tjr t, Label\n\tjrl -604\n")
        global ROOT
        keep, ROOT = ROOT, td
        n_clean = len(scan())
        open(p, "w", encoding="latin-1").write("\tjr 0x40\n\tjr c, 16777183\n")
        n_dirty = len(scan())
        ROOT = keep
    ck("a clean file yields no hits", n_clean == 0, str(n_clean))
    ck("a file with one bad operand yields exactly one hit", n_dirty == 1, str(n_dirty))
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    sys.exit(selftest() if a.selftest else run(a.apply))
