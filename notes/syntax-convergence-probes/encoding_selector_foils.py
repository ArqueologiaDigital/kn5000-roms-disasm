#!/usr/bin/env python3
"""Foil the byte gate: make it go RED on the two encoding-selector defects it
must be able to see, then restore and show it GREEN again.

QUESTION THIS ANSWERS
    `make gate-all` was 13/13 at every backend step of the encoding-selector
    work with NO source edit -- and at those steps the gate cannot see the
    feature at all, because no committed source writes a selector.  A green
    gate that was never made red certifies nothing.  These are the two foils
    the spec (notes/SPEC-encoding-selectors-2026-09-04.md, step 8) aims at the
    gate; the two TableGen foils live beside the guard they test, in
    llvm-project: llvm/utils/tlcs900-ambiguity-foils.sh.

FOIL a  v10/maincpu/file_io/single_load.s:361 `cp xwa, 5` -> `cp xwa, 5:i3`.
        Four bytes leave kn5000_v10_program: either the image differs or a
        later `.org` refuses to move backwards.  This is the constraint-1
        failure mode -- the short form MUST be asked for, and asking for it
        MUST move bytes.
FOIL b  in llvm-project's TLCS900InstrInfo.td, point the `cps` legacy alias
        for CP8_small at the LONG def CP8ri, rebuild llvm-mc, run both byte
        gates.  Every 8-bit `cps` site silently gains a byte (c9 dc -> c9 cf
        04), so every image that has one must differ.  The harder foil: a
        wrong answer in the costume of a right one, no diagnostic anywhere.
        Restoring must give back the SAME llvm-mc sha256.

Each foil restores the one file it touched (git checkout) and re-runs the
gate green before the script exits; both files are checked clean at the end.
⚠ Foil b rebuilds llvm-mc twice; nothing else may use the binary meanwhile.

RUN, from the tree root (the transcript belongs in
notes/syntax-convergence-probes/out/, next to the number it produces):
    python3 notes/syntax-convergence-probes/encoding_selector_foils.py --foil a
    python3 notes/syntax-convergence-probes/encoding_selector_foils.py --foil b
    python3 notes/syntax-convergence-probes/encoding_selector_foils.py --foil all
exit 0 = every requested foil went RED and came back GREEN.
"""
import argparse, hashlib, os, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROJECTS = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM = os.path.join(PROJECTS, "llvm-project")
MC = os.path.join(LLVM, "build", "bin", "llvm-mc")
TD_REL = "llvm/lib/Target/TLCS900/TLCS900InstrInfo.td"
TD = os.path.join(LLVM, TD_REL)
SITE_REL = "v10/maincpu/file_io/single_load.s"
SITE = os.path.join(ROOT, SITE_REL)
SITE_LINE = 361  # 1-based
SITE_OLD = "\tcp\txwa, 5"
SITE_NEW = "\tcp\txwa, 5:i3"
ALIAS_OLD = 'def : InstAlias<"cps $rs1, $imm",    (CP8_small  GR8:$rs1,  i8imm:$imm),  0>;'
ALIAS_NEW = 'def : InstAlias<"cps $rs1, $imm",    (CP8ri      GR8:$rs1,  i8imm:$imm),  0>;  // FOIL b'


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def run(cmd, cwd, timeout=3600):
    t0 = time.time()
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    return r.returncode, r.stdout + r.stderr, time.time() - t0


def clean(repo, rel):
    return subprocess.run(["git", "diff", "--quiet", "--", rel], cwd=repo).returncode == 0


def head(repo):
    return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=repo,
                          capture_output=True, text=True).stdout.strip()


def gate(wsa1=True):
    """Both byte gates; each rebuilds through its own `make all` first.
    -> dict(kn=(rc, differing, lines), wsa=(rc, differing, lines) or None)"""
    out = {}
    rc, txt, dt = run([sys.executable, "scripts/analysis/assert_byte_identical.py"], ROOT)
    lines = [l.rstrip() for l in txt.splitlines()
             if any(k in l for k in ("IDENTICAL", "DIFFER", "PASS", "FAIL", "error", "Error"))]
    out["kn"] = (rc, sum("BYTES DIFFER" in l for l in lines), lines, dt)
    if wsa1:
        rc, txt, dt = run([sys.executable, "scripts/analysis/assert_byte_identical.py"],
                          os.path.join(ROOT, "wsa1"))
        lines = [l.rstrip() for l in txt.splitlines()
                 if any(k in l for k in ("ok ", "DIFFERS", "PASS", "FAIL", "error", "Error"))]
        out["wsa"] = (rc, sum("DIFFERS" in l for l in lines), lines, dt)
    return out


def show(tag, g):
    for k in ("kn", "wsa"):
        if k in g:
            rc, n, lines, dt = g[k]
            print(f"  [{tag}] {k}: exit {rc}, {n} image(s) differ, {dt:.0f}s")
            for l in lines[:14]:
                print("     " + l[:110])


def foil_a():
    print("FOIL a -- single_load.s:%d `%s` -> `%s`" % (SITE_LINE, SITE_OLD.strip(), SITE_NEW.strip()))
    assert clean(ROOT, SITE_REL), SITE_REL + " has local changes; refusing"
    raw = open(SITE, "rb").read().decode("latin-1")
    lines = raw.split("\n")
    assert lines[SITE_LINE - 1] == SITE_OLD, repr(lines[SITE_LINE - 1])
    lines[SITE_LINE - 1] = SITE_NEW
    ok = False
    try:
        open(SITE, "wb").write("\n".join(lines).encode("latin-1"))
        g = gate(wsa1=False)
        show("foiled", g)
        red = g["kn"][0] != 0
        print("  RED as required" if red else "  FAIL: the gate stayed green")
    finally:
        subprocess.run(["git", "checkout", "--", SITE_REL], cwd=ROOT, check=True)
    g = gate(wsa1=False)
    show("restored", g)
    green = g["kn"][0] == 0 and clean(ROOT, SITE_REL)
    print("  GREEN as required" if green else "  FAIL: not green after restore")
    return red and green


def foil_b():
    print("FOIL b -- the `cps` alias for CP8_small points at the LONG def CP8ri")
    assert clean(LLVM, TD_REL), TD_REL + " has local changes; refusing"
    s = open(TD).read()
    assert s.count(ALIAS_OLD) == 1, "alias line not found exactly once"
    h0 = sha(MC)
    print(f"  llvm-project HEAD {head(LLVM)}; llvm-mc before: {h0[:16]}")
    red = False
    try:
        open(TD, "w").write(s.replace(ALIAS_OLD, ALIAS_NEW))
        rc, txt, dt = run(["ninja", "-C", "build", "llvm-mc"], LLVM)
        assert rc == 0, "ninja failed:\n" + txt[-2000:]
        h1 = sha(MC)
        print(f"  rebuilt with the foil in {dt:.0f}s: llvm-mc {h1[:16]}")
        assert h1 != h0, "the foil did not change the binary"
        g = gate(wsa1=True)
        show("foiled", g)
        red = g["kn"][0] != 0 and g["wsa"][0] != 0
        print("  RED as required (%d KN5000 + %d SX-WSA1R images differ)"
              % (g["kn"][1], g["wsa"][1]) if red else "  FAIL: a gate stayed green")
    finally:
        subprocess.run(["git", "checkout", "--", TD_REL], cwd=LLVM, check=True)
        rc, txt, dt = run(["ninja", "-C", "build", "llvm-mc"], LLVM)
        assert rc == 0, "ninja failed on restore:\n" + txt[-2000:]
    h2 = sha(MC)
    print(f"  restored and rebuilt in {dt:.0f}s: llvm-mc {h2[:16]} "
          + ("(identical to before)" if h2 == h0 else "(⚠ DIFFERENT from before)"))
    g = gate(wsa1=True)
    show("restored", g)
    green = g["kn"][0] == 0 and g["wsa"][0] == 0 and h2 == h0 and clean(LLVM, TD_REL)
    print("  GREEN as required" if green else "  FAIL: not green after restore")
    return red and green


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--foil", choices=["a", "b", "all"], required=True)
    args = ap.parse_args()
    print(f"tree {head(ROOT)}; llvm-project {head(LLVM)}; llvm-mc sha256 {sha(MC)}")
    results = {}
    if args.foil in ("a", "all"):
        results["a"] = foil_a()
    if args.foil in ("b", "all"):
        results["b"] = foil_b()
    bad = [k for k, v in results.items() if not v]
    print("OK: every foil red, every restore green" if not bad
          else "FAIL: foil(s) %s did not behave" % ",".join(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
