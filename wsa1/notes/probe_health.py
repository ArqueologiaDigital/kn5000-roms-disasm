#!/usr/bin/env python3
"""Does this probe read the IMAGE, or the file that used to be the whole of it?

WHAT QUESTION THIS ANSWERS
--------------------------
  A committed probe that opens `prom_X/wsa1_prom_X.s` by path scans ONE FILE.
  An image is not one file: prom_c is a 2,517-line master plus 26 included
  subject sources, prom_d is 494 lines plus three, and prom_a and prom_b already
  pull in `kernel/kernel.s` and the two shared maincpu routines.  So "did the
  probe see the whole image?" is a real question with a measurable answer, and
  the answer is not visible in the probe's exit status.

  ★ THE FAILURE THAT MATTERS IS NOT THE ONE THAT CRASHES.  A probe that raises
    told you.  A probe that still prints "ALL CHECKS PASSED" over an input with
    no payload in it is a VACUOUS PASS.  The byte gate cannot see it -- comments
    and the lines a probe scans assemble to nothing that the gate compares.

  This is the generalisation of notes/prom_c_probe_health.py (lane A4), which
  asked the same question of prom_c alone by diffing against a pinned pre-split
  commit.  Pinning to a commit answers "what did the split break".  This asks the
  standing question -- "is this probe reading the whole image, and would a split
  break it" -- for every image, including the two that are NOT split yet.

HOW: THREE TREES THAT DIFFER IN ONE FILE'S LAYOUT AND IN NOTHING ELSE
---------------------------------------------------------------------
  For the image under test, three copies of the tree are built:

    asis   exactly as committed
    full   the primary replaced by the WHOLE image, every `.include` expanded
           inline -- one file, the token stream llvm-mc actually assembles
    stub   the primary reduced to its header plus `.include` lines, with the
           entire body in `<image>/.health_parts/NN.s` -- the shape a
           per-subject split leaves behind, taken to its limit

  ★ BOTH DERIVED TREES STILL ASSEMBLE TO THE ORIGINAL ROM.  --selftest runs the
  byte gate in each.  That is what makes a difference in a probe's output
  attributable to the FILE LAYOUT and to nothing about the ROM.

  Every invocation is run in all three, with PYTHONHASHSEED pinned and the tree
  path masked out of the output.  A probe whose output differs between two
  IDENTICAL trees is non-deterministic and is reported as such rather than
  graded -- an instrument without that control cannot tell "it read the image"
  from "it printed a temp-directory name".

THE GRADES
----------
    UNAFFECTED     full == stub.  The probe resolves includes itself, or never
                   looks at the source.  Nothing to do.
    VACUOUS    ★   asis != full and the asis run REPORTS SUCCESS.  It is
                   answering over part of the image and saying nothing is wrong.
                   FIX THESE FIRST.
    LOUD           asis != full and the asis run fails visibly.  Broken, but
                   honest about it.
    SPLIT-FRAGILE  asis == full, so the probe is right today, but stub != full:
                   splitting this image would silently break it.  This is the
                   bucket that gates the prom_a/prom_b (maincpu) split.
    NONDET         the two identical trees disagreed.  Not graded.

THE FIX, in every case, is notes/asm_source.py -- one reader that resolves an
image the way llvm-mc does:

    sys.path.insert(0, os.path.join(ROOT, "notes"))
    from asm_source import image_lines, image_text
    SRC_LINES = image_lines(ROOT, "prom_c/wsa1_prom_c.s")

⚠⚠ A PROBE THAT WRITES THE LISTING IS NOT IN ANY BUCKET.  Several splice a block
back into the primary (`--apply`, `--emit68`).  Pointing such a probe's READ at
the expanded image while its WRITE stays on the primary would overwrite the
2,517-line master with the whole 132,304-line image and undo the split
silently.  Invocations whose flags are in WRITE_FLAGS are NEVER RUN here; they
are listed under "not run (write mode)" and must be migrated by hand, write path
first.  See notes/listing_writers.md.

RUN
---
  python3 notes/probe_health.py                     grade every image
  python3 notes/probe_health.py --image prom_c      one image
  python3 notes/probe_health.py --only prom_c_head  substring filter on scripts
  python3 notes/probe_health.py --json out.json     machine-readable
  python3 notes/probe_health.py --selftest          ★ the instrument's controls
"""
import argparse
import concurrent.futures
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_files, image_lines, IMAGES  # noqa: E402

IMAGE_PRIMARY = dict(IMAGES)
PARTS_DIRNAME = ".health_parts"
TIMEOUT = 240
HEADER_KEEP = 4          # lines of the primary the stub keeps before the first include

# ⚠ NEVER RUN.  A mode that writes a source file back would write it in the
# derived trees (harmless) but tells us nothing about reading, and the list is
# also the hand-migration work list.
WRITE_FLAGS = {"--apply", "--emit", "--emit68", "--write", "--rewrite", "--splice",
               "--install", "--patch", "--fix", "--force", "--regen", "--update"}

# Words that mean "this run did not succeed".  Deliberately broad: a probe that
# prints a traceback but exits 0 has still failed loudly.
FAILWORD = re.compile(r'\bFAIL\b|Traceback|FAILURES?:\s*[1-9]|\bERROR\b', re.I)

CITE_RE = re.compile(
    r'python3 ((?:notes|scripts/analysis)/[A-Za-z0-9_/-]+\.py)'
    r'((?:[ \t]+(?:--?[A-Za-z0-9][A-Za-z0-9-]*|0x[0-9A-Fa-f]+|[0-9]+))*)')


# ---------------------------------------------------------------------------
# discovery
def committed_py():
    out = subprocess.run(["git", "ls-files", "*.py"], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\n") if p]


def readers(primary):
    """Every committed .py that NAMES this image's primary listing.

    ⚠ This is the CANDIDATE set, not the answer.  Naming the path in a docstring
    is not reading it -- notes/prom_d_base_checks.py names prom_d only in prose.
    The grade below is what separates them, which is why this may be generous.
    """
    tag = os.path.basename(primary)
    hits = []
    for p in committed_py():
        try:
            txt = open(os.path.join(ROOT, p), encoding="utf-8").read()
        except (OSError, UnicodeDecodeError):
            continue
        if tag in txt:
            hits.append(p)
    return sorted(hits)


def citation_index():
    """script -> [argv, ...] as the tree's own prose invokes it, most-cited first."""
    counts = {}
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames
                       if d not in (".git", "rebuilt_ROMs", "original_ROMs")]
        for fn in filenames:
            if not fn.endswith((".s", ".md", ".py", ".inc", ".txt", ".ld")) \
                    and fn != "Makefile":
                continue
            try:
                txt = open(os.path.join(dirpath, fn), encoding="utf-8",
                           errors="ignore").read()
            except OSError:
                continue
            for m in CITE_RE.finditer(txt):
                script, rest = m.group(1), m.group(2).split()
                counts.setdefault(script, {})
                key = tuple(rest)
                counts[script][key] = counts[script].get(key, 0) + 1
    out = {}
    for script, d in counts.items():
        out[script] = [list(k) for k, _ in
                       sorted(d.items(), key=lambda kv: (-kv[1], kv[0]))]
    return out


def invocations(script, cites, per_script):
    """Up to `per_script` runnable invocations, write modes removed."""
    forms = cites.get(script, [])
    keep, skipped = [], []
    for f in forms:
        (skipped if set(f) & WRITE_FLAGS else keep).append(f)
    if not keep:
        keep = [[]]                       # bare run: what a reader would try first
    seen, out = set(), []
    for f in keep:
        t = tuple(f)
        if t in seen:
            continue
        seen.add(t)
        out.append([script] + f)
        if len(out) >= per_script:
            break
    return out, [[script] + f for f in skipped]


# ---------------------------------------------------------------------------
# the three trees
def _copy_tree(dst):
    """A real copy, not symlinks: a probe with a write mode must not be able to
    reach the committed tree through one.  `.git` IS shared, because probes that
    shell out to `git show` must behave the same in every tree."""
    shutil.copytree(ROOT, dst,
                    ignore=shutil.ignore_patterns(".git", "*.pyc", "__pycache__"),
                    symlinks=True)
    os.symlink(os.path.join(ROOT, ".git"), os.path.join(dst, ".git"))


def _write_full(tree, primary):
    """The primary becomes the WHOLE image: every .include expanded inline."""
    text = "\n".join(image_lines(ROOT, primary))
    with open(os.path.join(tree, primary), "w", encoding="utf-8") as fh:
        fh.write(text)


def _write_stub(tree, primary, drop_line=None, nparts=8):
    """The primary becomes a header plus .include lines; the body moves out.

    The extreme of a per-subject split, and byte-neutral for the same reason a
    real one is: llvm-mc's `.include` is textual and the parts are contiguous
    ranges emitted in order, so the token stream is unchanged.

    drop_line deletes one body line -- the MUTATION CONTROL.  A faithful stub and
    a mutated one must not look the same to the instrument, or "UNAFFECTED"
    would be free.
    """
    lines = image_lines(ROOT, primary)
    head, body = lines[:HEADER_KEEP], lines[HEADER_KEEP:]
    if drop_line is not None:
        del body[drop_line % len(body)]
    imgdir = os.path.dirname(primary)
    partdir = os.path.join(tree, imgdir, PARTS_DIRNAME)
    os.makedirs(partdir, exist_ok=True)
    step = (len(body) + nparts - 1) // nparts
    master = list(head)
    for i in range(0, len(body), step):
        name = "%s/%s/%03d.s" % (imgdir, PARTS_DIRNAME, i // step)
        with open(os.path.join(tree, name), "w", encoding="utf-8") as fh:
            fh.write("\n".join(body[i:i + step]))
        master.append('\t.include "%s"' % name)
    with open(os.path.join(tree, primary), "w", encoding="utf-8") as fh:
        fh.write("\n".join(master))
    # ⚠ NO TRAILING NEWLINE IS ADDED, on purpose.  `read().split("\n")` turns a
    # trailing newline into a phantom empty line, so a stub built with one would
    # expand to eight lines MORE than the image and every line-counting probe
    # would differ between the two layouts for a reason that has nothing to do
    # with what it reads.  The stub must expand to the image EXACTLY or the
    # grades are measuring this builder.


def build_trees(base, primary, extra_stub_mutant=False):
    """asis / full / stub (/ stub2 / stub_mut), all under `base`."""
    trees = {}
    for name in ("asis", "full", "stub") + (
            ("asis2", "stub_mut") if extra_stub_mutant else ("asis2",)):
        d = os.path.join(base, name)
        _copy_tree(d)
        trees[name] = d
    _write_full(trees["full"], primary)
    _write_stub(trees["stub"], primary)
    if extra_stub_mutant:
        _write_stub(trees["stub_mut"], primary, drop_line=12345)
    return trees


# ---------------------------------------------------------------------------
# running and grading
def run(tree, argv):
    env = dict(os.environ, PYTHONHASHSEED="0", PYTHONDONTWRITEBYTECODE="1")
    try:
        r = subprocess.run([sys.executable] + argv, cwd=tree, env=env,
                           capture_output=True, text=True, timeout=TIMEOUT)
        rc, out = r.returncode, r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        rc, out = None, "<timeout>"
    except OSError as e:
        rc, out = None, "<oserror %s>" % e
    return rc, out.replace(tree, "<TREE>")


def failed(rc, out):
    return rc != 0 or bool(FAILWORD.search(out or "")) or out == "<timeout>"


def grade(res):
    a, a2, f, s = res["asis"], res["asis2"], res["full"], res["stub"]
    if a != a2:
        return "NONDET"
    if f == s:
        return "UNAFFECTED"
    if a == f:
        return "SPLIT-FRAGILE"
    return "LOUD" if failed(*a) else "VACUOUS"


ORDER = ["VACUOUS", "LOUD", "SPLIT-FRAGILE", "NONDET", "UNAFFECTED"]


def measure(primary, argvs, jobs=6, base=None):
    made = base is None
    base = base or tempfile.mkdtemp(prefix="probehealth-")
    try:
        trees = build_trees(base, primary)
        rows = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as ex:
            futs = {}
            for argv in argvs:
                for name, tree in trees.items():
                    futs[ex.submit(run, tree, argv)] = (tuple(argv), name)
            got = {}
            for fut in concurrent.futures.as_completed(futs):
                key, name = futs[fut]
                got.setdefault(key, {})[name] = fut.result()
        for argv in argvs:
            res = got[tuple(argv)]
            rows.append({"argv": argv, "grade": grade(res),
                         "asis_rc": res["asis"][0],
                         "asis_fails": failed(*res["asis"])})
        return rows
    finally:
        if made:
            shutil.rmtree(base, ignore_errors=True)


# ---------------------------------------------------------------------------
def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", action="append",
                    choices=[t for t, _ in IMAGES] + ["all"], default=None)
    ap.add_argument("--only", default=None, help="substring filter on script path")
    ap.add_argument("--per-script", type=int, default=2)
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--json", default=None)
    a = ap.parse_args(argv)
    want = [t for t, _ in IMAGES] if not a.image or "all" in a.image else a.image

    cites = citation_index()
    report = {}
    for tag in want:
        primary = IMAGE_PRIMARY[tag]
        scripts = [s for s in readers(primary)
                   if a.only is None or a.only in s]
        argvs, skipped = [], []
        for s in scripts:
            keep, skip = invocations(s, cites, a.per_script)
            argvs += keep
            skipped += skip
        print("\n=== %s  (%s)  %d script(s), %d invocation(s) ==="
              % (tag, primary, len(scripts), len(argvs)))
        rows = measure(primary, argvs, jobs=a.jobs)
        rows.sort(key=lambda r: (ORDER.index(r["grade"]), r["argv"]))
        for r in rows:
            if r["grade"] != "UNAFFECTED":
                print("  %-13s %s" % (r["grade"], " ".join(r["argv"])))
        n = {g: sum(1 for r in rows if r["grade"] == g) for g in ORDER}
        print("  " + "   ".join("%s %d" % (g, n[g]) for g in ORDER))
        if skipped:
            print("  not run (write mode), migrate by hand -- see "
                  "notes/listing_writers.md:")
            for s in sorted(set(map(tuple, skipped))):
                print("      %s" % " ".join(s))
        report[tag] = {"rows": rows, "skipped": sorted(set(map(tuple, skipped)))}
    if a.json:
        with open(a.json, "w") as fh:
            json.dump(report, fh, indent=1)
        print("\nwrote %s" % a.json)
    bad = sum(1 for t in report for r in report[t]["rows"]
              if r["grade"] in ("VACUOUS", "LOUD"))
    print("\nVACUOUS+LOUD across the images measured: %d" % bad)
    return 0


# ---------------------------------------------------------------------------
def selftest():
    """INVARIANTS.  Nothing here pins a bucket count.  What is checked is that
    the instrument CAN tell the trees apart, that it does NOT see a difference
    where there is none, and -- the one that makes the whole thing mean
    something -- that all three trees still assemble to the original ROMs."""
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    base = tempfile.mkdtemp(prefix="probehealth-selftest-")
    try:
        primary = IMAGE_PRIMARY["prom_c"]
        trees = build_trees(base, primary, extra_stub_mutant=True)

        full = open(os.path.join(trees["full"], primary), encoding="utf-8").read()
        stub = open(os.path.join(trees["stub"], primary), encoding="utf-8").read()
        asis = open(os.path.join(trees["asis"], primary), encoding="utf-8").read()
        check(len(full.split("\n")) > 20 * len(stub.split("\n")),
              "the full tree's primary is the WHOLE image (%s vs %s lines)"
              % (format(len(full.split("\n")), ","), len(stub.split("\n"))))
        check(asis == open(os.path.join(ROOT, primary), encoding="utf-8").read(),
              "the asis tree is byte-for-byte the committed tree")
        inc = re.compile(r'^\s*\.include\s')
        check(not any(inc.match(l) for l in full.split("\n")),
              "no .include DIRECTIVE survives in the full tree")

        # ★ THE CONTROL THAT MAKES A GRADE MEAN ANYTHING: neither derived layout
        #   changes a single ROM byte, so any difference a probe reports is
        #   about the FILE and not about the image.
        for name in ("full", "stub"):
            r = subprocess.run([sys.executable,
                                "scripts/analysis/assert_byte_identical.py"],
                               cwd=trees[name], capture_output=True, text=True,
                               timeout=1800)
            check(r.returncode == 0 and "PASS" in r.stdout,
                  "the %s tree still assembles to all four original ROMs" % name)

        # Three throwaway probes, one per direction the instrument must get right.
        #   naive    opens the primary by path -- the broken pattern
        #   resolver goes through asm_source -- the prescribed fix
        #   blind    reads only the ROM
        head = ("import os,sys\n"
                "r=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n"
                "sys.path.insert(0,os.path.join(r,'notes'))\n")
        bodies = {
            ".health_naive.py":
                head + "print(len(open(os.path.join(r,%r)).read().split(chr(10))))\n"
                % primary,
            ".health_resolver.py":
                head + "from asm_source import image_lines\n"
                       "print(len(image_lines(r,%r)))\n" % primary,
            ".health_blind.py":
                head + "print(len(open(os.path.join(r,'original_ROMs',"
                       "'wsa1_prom_c.ic28'),'rb').read()))\n",
        }
        for name, body in bodies.items():
            for t in trees.values():
                with open(os.path.join(t, "notes", name), "w") as fh:
                    fh.write(body)
        naive = [os.path.join("notes", ".health_naive.py")]
        resolver = [os.path.join("notes", ".health_resolver.py")]
        blind = [os.path.join("notes", ".health_blind.py")]

        nf, ns = run(trees["full"], naive)[1], run(trees["stub"], naive)[1]
        check(nf != ns, "a PRIMARY-READING probe is SEEN to differ (full %s / stub %s)"
              % (nf.strip(), ns.strip()))
        check(run(trees["full"], blind)[1] == run(trees["stub"], blind)[1],
              "a probe that reads only the ROM does NOT differ")

        # ★ THE FIX ITSELF IS UNDER TEST.  If asm_source did not really resolve
        #   the includes, every migration this tool recommends would be a
        #   no-op and every grade of UNAFFECTED after one would be free.
        rf, rs = run(trees["full"], resolver)[1], run(trees["stub"], resolver)[1]
        check(rf == rs and rf.strip().isdigit() and int(rf.strip()) > 100000,
              "an asm_source-reading probe gives the SAME answer in both "
              "layouts (%s / %s)" % (rf.strip(), rs.strip()))

        # ★ A4's MUTATION CONTROL, kept: a stub with one body line deleted must
        #   NOT look like the faithful stub.  A stub builder that quietly dropped
        #   or duplicated lines would otherwise pass everything above.
        rm = run(trees["stub_mut"], resolver)[1]
        check(rm != rs, "a stub with ONE line deleted is DETECTED (%s vs %s)"
              % (rm.strip(), rs.strip()))
        exp = image_lines(ROOT, primary)
        check(image_lines(trees["stub"], primary) == exp
              and image_lines(trees["full"], primary) == exp,
              "both derived layouts expand to the image LINE FOR LINE "
              "(%d lines)" % len(exp))

        # the grader itself, on synthetic results
        mk = lambda a, a2, f, s: grade({"asis": a, "asis2": a2, "full": f, "stub": s})
        X, Y = (0, "x"), (0, "y")
        check(mk(X, X, X, X) == "UNAFFECTED", "grader: all-equal is UNAFFECTED")
        check(mk(X, Y, X, X) == "NONDET", "grader: identical trees disagreeing is NONDET")
        check(mk(X, X, X, Y) == "SPLIT-FRAGILE",
              "grader: right today, would break on a split")
        check(mk(Y, Y, X, Y) == "VACUOUS",
              "grader: differs from the image and still succeeds is VACUOUS")
        check(mk((1, "FAIL"), (1, "FAIL"), X, Y) == "LOUD",
              "grader: differs from the image and fails is LOUD")

        # the write-mode guard
        keep, skip = invocations("notes/x.py", {"notes/x.py": [["--apply"], ["--verify"]]}, 4)
        check(keep == [["notes/x.py", "--verify"]] and skip == [["notes/x.py", "--apply"]],
              "a --apply invocation is NEVER RUN, and is listed for hand migration")
    finally:
        shutil.rmtree(base, ignore_errors=True)
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
