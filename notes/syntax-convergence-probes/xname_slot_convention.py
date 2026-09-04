#!/usr/bin/env python3
"""
QUESTION IT ANSWERS: when a 32-bit register NAME is written against a form that
takes a narrower register -- `ldb_da xbc, (addr)`, `cpda8 xbc, (addr)` -- which
register does the assembler actually encode?

This matters because the tree is full of such mis-spellings and a convergence
pass has to replace each with the name the ROM byte really denotes.  The lane
w16/conv-width measured the LD-direct class and found the pair's LOW BYTE
(`ldb_da xwa` is `ld a`), corroborated by the source's own comment at
hdae5000/hdae5000_hd_driver.s:403.  Carrying that rule into the ALU-direct
class produced 161 BYTES-DIFFER refusals, which is what prompted this probe.

★ THE ANSWER IS PER INSTRUCTION CLASS, NOT PER REGISTER FILE.

    ldb_da xbc, (0x120000)  ->  ...,0x23   LD base 0x20 + 3  =  C   low byte
    cpda8  xbc, (0x1000)    ->  ...,0xf1   CP base 0xf0 + 1  =  A   same index

So `convert_direct_address_family.py` asserts NEITHER: it offers every name of
the right class and keeps the one whose encoding equals the line it replaces.
This script is the evidence for that decision and the check that it still
holds; run it before trusting any x-name rename in a new family.

WHAT COUNTS AS PASS: the two classes DISAGREE (that is the finding), the
ALU-direct class is index-preserving for all eight names, and the LD-direct
class is low-byte for the four pairs that have an 8-bit half.

EXACT COMMAND (from the tree root):

    python3 notes/syntax-convergence-probes/xname_slot_convention.py \
        --llvm-mc ~/compartilhado/toolchain-snapshot/llvm-mc.snap

⚠ Name the binary.  The shared llvm-project/build/bin/llvm-mc is relinked
several times an evening behind an unchanging git commit.
"""
import argparse, hashlib, os, re, subprocess, sys, tempfile

R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
LOW_BYTE = {"xwa": "a", "xbc": "c", "xde": "e", "xhl": "l"}

# mnemonic -> (line template, sub-opcode base).  The sub-opcode is the LAST
# byte of the encoding for both of these forms.
CASES = {
    "cpda8":  ("cpda8 %s, (0x1000)", 0xF0, "ALU-direct"),
    "ldb_da": ("ldb_da %s, (0x120000)", 0x20, "LD-direct"),
}


def encode(lines, mc):
    with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False) as fh:
        fh.write("".join("\t%s\n" % l for l in lines))
        path = fh.name
    try:
        p = subprocess.run([mc, "-triple=tlcs900", "-show-encoding", path],
                           capture_output=True, text=True, errors="replace")
    finally:
        os.unlink(path)
    return re.findall(r'encoding: \[([^\]]*)\]', p.stdout)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--llvm-mc", default=os.path.expanduser(
        "~/compartilhado/toolchain-snapshot/llvm-mc.snap"))
    args = ap.parse_args()
    mc = os.path.expanduser(args.llvm_mc)
    print("assembler %s\n  sha256 %s\n"
          % (mc, hashlib.sha256(open(mc, "rb").read()).hexdigest()))

    rules, ok = {}, True
    for mn, (tmpl, base, label) in CASES.items():
        encs = encode([tmpl % r for r in R32] + [tmpl % r for r in R8], mc)
        if len(encs) != 16:
            sys.exit("%s: assembler produced %d encodings, expected 16"
                     % (mn, len(encs)))
        idx_of = {}
        for r, e in zip(R8, encs[8:]):
            idx_of[int(e.split(",")[-1], 16) - base] = r
        print("%-8s (%s)  sub-opcode base 0x%02x" % (mn, label, base))
        rule = {}
        for r, e in zip(R32, encs[:8]):
            i = int(e.split(",")[-1], 16) - base
            rule[r] = idx_of.get(i, "?")
            print("   %-4s -> %-6s  %-30s  index %d  %s"
                  % (r, rule[r], e, i,
                     "index-preserving" if rule[r] == R8[R32.index(r)]
                     else "low-byte" if LOW_BYTE.get(r) == rule[r]
                     else "neither"))
        rules[mn] = rule
        print()

    idx = {r: R8[i] for i, r in enumerate(R32)}
    checks = [
        ("the two classes DISAGREE", rules["cpda8"] != rules["ldb_da"]),
        ("ALU-direct is index-preserving for all eight",
         rules["cpda8"] == idx),
        ("LD-direct is low-byte for the four pairs with an 8-bit half",
         all(rules["ldb_da"][k] == v for k, v in LOW_BYTE.items())),
    ]
    for what, good in checks:
        print("%-60s %s" % (what, "ok" if good else "FAILED"))
        ok = ok and good
    print("\n%s" % ("PASS: the x-name convention is per instruction class."
                    if ok else "FAIL: the measured conventions moved."))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
