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
    WRITER         it tried to WRITE a source and was refused in every tree.  Not
                   a reader; it belongs on the hand-migration list.
    TIMEOUT        it ran out of time in every tree.  NOT a pass: the instrument
                   never saw an answer, and identical timeouts would otherwise
                   read as UNAFFECTED.
    NONDET         the two identical trees disagreed.  Not graded.
    BY-DESIGN      a tool whose SUBJECT is the layout (asm_source, the split
                   probes, this file).  It is meant to differ; see LAYOUT_TOOLS.

★ TWO SHAPES THIS METHOD CANNOT GRADE, both listed separately rather than
  silently bucketed:
    GIT-BLIND         reads the listing through `git show <rev>:<primary>`,
                      which the tree flip cannot reach.  Since the split IS
                      committed, such a probe is reading a header today.  The
                      fix is asm_source.image_text_at_rev.
    WORKING-TREE DIFF compares the tree with HEAD.  This tool works by handing
                      the probe a different tree, so such a probe MUST differ;
                      the difference is the measurement, not the probe.

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
first -- `python3 notes/migrate_listing_readers.py --list` is the ledger, and
asm_source.locate()/write_part() is the safe way to do it.

RUN
---
  python3 notes/probe_health.py                     grade every image
  python3 notes/probe_health.py --image prom_c      one image
  python3 notes/probe_health.py --only prom_c_head  substring filter on scripts
  python3 notes/probe_health.py --json out.json     machine-readable
  python3 notes/probe_health.py --regrade B.json    re-run only B's non-green rows

THE BASELINE, and how to reproduce a per-probe before/after
-----------------------------------------------------------
  notes/probe-health-baseline-2026-08-30/ holds the four sweeps taken before any
  migration, plus regrade-1..3.log.  Once a probe reads the image, the state it
  was in is GONE, so the grades it had are checked in rather than regenerated.

  To reproduce one probe's own PASS/FAIL counts before a change:

      git archive <commit> | tar -x -C /tmp/before
      cp -r original_ROMs /tmp/before/           # git archive carries them, but
      cd /tmp/before && python3 notes/<probe>.py # a worktree copy is safer

  ⚠ `git archive` gives no `.git`, so a probe that shells out to git will fail
  there for that reason and not for the one being measured -- use a real
  worktree (`git worktree add`) when the probe reads a revision.
  python3 notes/probe_health.py --selftest          ★ the instrument's controls

⚠ IF A RUN IS KILLED, its scratch trees are left READ-ONLY (see FROZEN_DIRS) and
`rm -rf` will refuse them.  Clear them with:

    chmod -R u+w /tmp/probehealth-* && rm -rf /tmp/probehealth-*
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
from asm_source import image_files, image_lines, git_prefix, IMAGES  # noqa: E402

IMAGE_PRIMARY = dict(IMAGES)
PARTS_DIRNAME = ".health_parts"
TIMEOUT = 300
HEADER_KEEP = 4          # lines of the primary the stub keeps before the first include

# ⚠ NEVER RUN.  A mode that writes a source file back tells us nothing about
# reading, and the list is also the hand-migration work list.
WRITE_FLAGS = {"--apply", "--emit", "--emit68", "--write", "--rewrite", "--splice",
               "--install", "--patch", "--fix", "--force", "--regen", "--update"}

# ★★ AND THE FLAG LIST IS NOT ENOUGH, WHICH IS WHY THE SOURCES ARE FROZEN.
# scripts/analysis/gen_prom_d_asm.py writes prom_d's four sources with NO FLAG AT
# ALL -- writing is its default and `--check` is the dry run.  The first run of
# this tool invoked it bare, in all four trees, and it rewrote the very files
# whose layout was under test: the `full` tree's expanded primary was replaced by
# the split one, so every invocation that ran afterwards compared two identical
# trees and was graded UNAFFECTED.  ★ AN INSTRUMENT THAT CAN CHANGE WHAT IT
# MEASURES IS NOT AN INSTRUMENT.  So every source directory in every tree is made
# READ-ONLY before anything runs.  A writer now fails identically in all four
# trees and is reported as WRITER instead of silently poisoning its neighbours.
FROZEN_DIRS = ("prom_a", "prom_b", "prom_c", "prom_d", "kernel", "include",
               "maincpu", "original_ROMs")
PERM_DENIED = re.compile(r"Permission denied|PermissionError")

# ★ TOOLS WHOSE SUBJECT IS THE LAYOUT ITSELF.  asm_source prints how many files
# an image is made of; prom_d_split_probe PROVES the split moved lines and did
# not edit them; this file builds the layouts.  Each of them is SUPPOSED to give
# a different answer in a differently-shaped tree -- that is what it measures.
# Grading them VACUOUS would be the instrument reporting on itself, so they are
# graded BY-DESIGN and left out of the work list.  ⚠ The list is short and
# explicit on purpose: "it is meant to differ" is exactly the excuse a genuinely
# broken probe would offer.
LAYOUT_TOOLS = {
    "notes/asm_source.py",
    "notes/probe_health.py",
    "notes/prom_c_probe_health.py",
    "notes/prom_c_image.py",
    "notes/prom_c_split.py",
    "notes/prom_d_split_probe.py",
    "notes/migrate_listing_readers.py",
}

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


# ★ THE ONE THING THE THREE-TREE TEST CANNOT SEE.  Flipping the layout changes
# the WORKING TREE.  A probe that reads the listing out of git --
# `git show HEAD:prom_d/wsa1_prom_d.s` -- gets the same committed blob in all
# three trees and is graded UNAFFECTED for a reason that has nothing to do with
# whether it reads the image.  Since the split IS committed, those probes are
# reading a stub today.  They are detected statically and listed separately,
# because a bucket the instrument is blind to must not be reported as green.
GIT_READ_RE = re.compile(r'git[^\n]{0,40}show[^\n]{0,40}[:"\']([A-Za-z0-9_/]*%s)')


# ★★ AND THE OTHER THING THIS METHOD CANNOT GRADE.  Six review probes compare
# the WORKING TREE with HEAD -- `git diff -- prom_b/`.  The instrument's whole
# method is to hand the probe a different working tree, so such a probe MUST
# report a different diff in each; the difference is caused by the measurement
# and says nothing about whether the probe reads the image.  They are detected
# statically and labelled, because a bucket the instrument cannot see into must
# not be reported as green OR as broken.
#
# ⚠ A probe of this shape can only pass in the session that made the edit it
# measures; once the round is committed the diff is empty.  That is a property
# of the probe, not of this tool.
WORKTREE_DIFF_RE = re.compile(r'"git"[^\n]{0,40}"diff"|git\s+diff\b')


def worktree_diff_text(txt):
    return bool(WORKTREE_DIFF_RE.search(txt))


def worktree_diff(script):
    txt = open(os.path.join(ROOT, script), encoding="utf-8",
               errors="replace").read()
    return worktree_diff_text(txt)


def git_blind_text(txt, primary):
    return bool(re.search(GIT_READ_RE.pattern % re.escape(os.path.basename(primary)),
                          txt))


def git_blind(script, primary):
    return git_blind_text(
        open(os.path.join(ROOT, script), encoding="utf-8", errors="replace").read(),
        primary)


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
# ★★ WHERE `.git` GOES, AND WHY IT IS NOT NEXT TO THE TREE.
# ROOT used to BE the repository root, so a scratch copy of it with a `.git`
# symlink beside it was a faithful repository and `git show HEAD:prom_a/...`
# meant the same thing there as here.  Since the 2026-09-01 move ROOT is
# `<repo>/wsa1`, there is no `wsa1/.git`, and that symlink became a DANGLING
# one: every scratch tree stopped being a repository at all.  ⚠ THAT IS A GREEN
# THAT MEANS NOTHING -- a probe reading the listing out of git then failed
# IDENTICALLY in asis, full and stub, so full == stub and it was graded
# UNAFFECTED.  The copy therefore reproduces the PREFIX: the tree goes at
# `<scratch>/<name>/wsa1` and the `.git` symlink one level above it, so the
# scratch repository has the same shape, and the same prefix, as this one.
PREFIX = git_prefix(ROOT)                       # "wsa1/", or "" at a repo root
GITDIR = subprocess.run(["git", "-C", ROOT, "rev-parse", "--git-common-dir"],
                        capture_output=True, text=True,
                        check=True).stdout.strip()
GITDIR = os.path.abspath(os.path.join(ROOT, GITDIR))
NEST = PREFIX.strip("/").count("/") + 1 if PREFIX else 0


def _tree_top(tree):
    """The repository root of a scratch tree whose ROOT-counterpart is `tree`."""
    return os.path.normpath(os.path.join(tree, *([os.pardir] * NEST))) \
        if NEST else tree


def _copy_tree(dst):
    """A real copy, not symlinks: a probe with a write mode must not be able to
    reach the committed tree through one.  `.git` IS shared, because probes that
    shell out to `git show` must behave the same in every tree."""
    shutil.copytree(ROOT, dst,
                    ignore=shutil.ignore_patterns(".git", "*.pyc", "__pycache__"),
                    symlinks=True)
    link = os.path.join(_tree_top(dst), ".git")
    if not os.path.lexists(link):
        os.symlink(GITDIR, link)


def _freeze(tree):
    """Make every source directory read-only, files and directories alike."""
    for d in FROZEN_DIRS:
        top = os.path.join(tree, d)
        if not os.path.isdir(top):
            continue
        for dirpath, _dirs, files in os.walk(top, topdown=False):
            for fn in files:
                os.chmod(os.path.join(dirpath, fn), 0o444)
            os.chmod(dirpath, 0o555)


def _thaw(tree):
    for d in FROZEN_DIRS:
        top = os.path.join(tree, d)
        if not os.path.isdir(top):
            continue
        for dirpath, _dirs, files in os.walk(top):
            os.chmod(dirpath, 0o755)
            for fn in files:
                os.chmod(os.path.join(dirpath, fn), 0o644)


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
        d = os.path.join(base, name, PREFIX.rstrip("/")) if PREFIX \
            else os.path.join(base, name)
        _copy_tree(d)
        trees[name] = d
    _write_full(trees["full"], primary)
    _write_stub(trees["stub"], primary)
    if extra_stub_mutant:
        _write_stub(trees["stub_mut"], primary, drop_line=12345)
    for t in trees.values():
        _freeze(t)
    return trees


# ---------------------------------------------------------------------------
# running and grading
def run(tree, argv):
    env = dict(os.environ, PYTHONHASHSEED="0", PYTHONDONTWRITEBYTECODE="1")
    try:
        r = subprocess.run([sys.executable] + argv, cwd=tree, env=env,
                           stdin=subprocess.DEVNULL,   # a probe that waits on
                           capture_output=True,        # stdin would burn a whole
                           text=True, timeout=TIMEOUT) # timeout in all four trees
        rc, out = r.returncode, r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        rc, out = None, "<timeout>"
    except OSError as e:
        rc, out = None, "<oserror %s>" % e
    out = out.replace(tree, "<TREE>").replace(_tree_top(tree), "<TOP>")
    # ⚠ NORMALISE THE MATERIALISED PATH.  asm_source.image_path() returns
    # notes/.image-wsa1_prom_b.s when the image is several files and the primary
    # itself when it is one -- so a probe that PRINTS the path it read differs
    # between the trees for a reason that is about the reader, not the answer.
    # notes/prom_b_f65000_header_audit.py was graded VACUOUS for exactly that,
    # AFTER being migrated.  The expansion IS the image, so it is spelled as the
    # image; nothing else is masked.
    for tag, primary in IMAGES:
        out = out.replace("notes/.image-" + os.path.basename(primary), primary)
    return rc, out


def failed(rc, out):
    return rc != 0 or bool(FAILWORD.search(out or "")) or out == "<timeout>"


def grade(res, script=None):
    if script in LAYOUT_TOOLS:
        return "BY-DESIGN"
    a, a2, f, s = res["asis"], res["asis2"], res["full"], res["stub"]
    # ⚠ A probe that ran out of TIME in every tree produced the same string in
    # every tree, and would otherwise be graded UNAFFECTED -- a green that means
    # "the instrument never saw an answer".  Say so instead.
    if all(r[1] == "<timeout>" for r in (a, f, s)):
        return "TIMEOUT"
    if all(PERM_DENIED.search(r[1] or "") for r in (a, f, s)):
        return "WRITER"          # it tried to write a frozen source; see FROZEN_DIRS
    if a != a2:
        return "NONDET"
    if f == s:
        return "UNAFFECTED"
    if a == f:
        return "SPLIT-FRAGILE"
    return "LOUD" if failed(*a) else "VACUOUS"


ORDER = ["VACUOUS", "LOUD", "SPLIT-FRAGILE", "WRITER", "TIMEOUT", "NONDET",
         "BY-DESIGN", "UNAFFECTED"]


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
            got, n_done = {}, 0
            for fut in concurrent.futures.as_completed(futs):
                key, name = futs[fut]
                got.setdefault(key, {})[name] = fut.result()
                n_done += 1
                if n_done % 25 == 0 or n_done == len(futs):
                    print("    ... %d/%d runs" % (n_done, len(futs)), flush=True)
        for argv in argvs:
            res = got[tuple(argv)]
            rows.append({"argv": argv, "grade": grade(res, argv[0]),
                         "asis_rc": res["asis"][0],
                         "asis_fails": failed(*res["asis"])})
        return rows
    finally:
        if made:
            for name in os.listdir(base):
                _thaw(os.path.join(base, name, PREFIX.rstrip("/")) if PREFIX
                      else os.path.join(base, name))
            shutil.rmtree(base, ignore_errors=True)


# ---------------------------------------------------------------------------
GREEN = ("UNAFFECTED", "BY-DESIGN")


def regrade(path, want, jobs):
    """Re-run ONLY the invocations a previous run graded non-green.

    ★ THIS IS THE "did the answer come back" EVIDENCE, and it is the affordable
    form of it.  A full sweep of prom_a is 412 subprocess runs and over an hour;
    the work list after a migration is a few dozen.  A probe that was VACUOUS and
    is now UNAFFECTED has been SHOWN to give the same answer over the image and
    over a stub, which is the only thing that makes the fix a fix.
    """
    old = json.load(open(path))
    out = {}
    for tag in [t for t, _ in IMAGES]:
        if tag not in old or (want and tag not in want):
            continue
        argvs = [r["argv"] for r in old[tag]["rows"] if r["grade"] not in GREEN]
        if not argvs:
            continue
        was = {tuple(r["argv"]): r["grade"] for r in old[tag]["rows"]}
        print("\n=== %s  REGRADE %d invocation(s) that were not green ==="
              % (tag, len(argvs)))
        rows = measure(IMAGE_PRIMARY[tag], argvs, jobs=jobs)
        rows.sort(key=lambda r: (ORDER.index(r["grade"]), r["argv"]))
        fixed = 0
        for r in rows:
            before = was[tuple(r["argv"])]
            mark = "  "
            if r["grade"] in GREEN and before not in GREEN:
                mark, fixed = "✔ ", fixed + 1
            print("  %s%-13s (was %-13s) %s"
                  % (mark, r["grade"], before, " ".join(r["argv"])))
        print("  %d of %d came back green" % (fixed, len(rows)))
        out[tag] = {"rows": rows, "was": {" ".join(k): v for k, v in was.items()}}
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", action="append",
                    choices=[t for t, _ in IMAGES] + ["all"], default=None)
    ap.add_argument("--only", default=None, help="substring filter on script path")
    ap.add_argument("--per-script", type=int, default=2)
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--json", default=None)
    ap.add_argument("--regrade", default=None,
                    help="a previous --json: re-run only its non-green rows")
    a = ap.parse_args(argv)
    if a.regrade:
        want = None if not a.image or "all" in a.image else set(a.image)
        rep = regrade(a.regrade, want, a.jobs)
        if a.json:
            json.dump(rep, open(a.json, "w"), indent=1)
            print("\nwrote %s" % a.json)
        return 0
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
            print("  not run (write mode); the write path must move FIRST -- "
                  "python3 notes/migrate_listing_readers.py --list:")
            for s in sorted(set(map(tuple, skipped))):
                print("      %s" % " ".join(s))
        wt = sorted({r["argv"][0] for r in rows if r["grade"] not in
                     ("UNAFFECTED", "BY-DESIGN") and worktree_diff(r["argv"][0])})
        if wt:
            print("  ★ WORKING-TREE DIFF -- compares the tree with HEAD, so it MUST "
                  "differ between trees that differ; not gradable here:")
            for s in wt:
                print("      %s" % s)
        blind = [s for s in scripts if git_blind(s, primary)]
        if blind:
            print("  ★ GIT-BLIND -- reads the listing through `git show`, where the "
                  "tree flip cannot reach it; classify by hand:")
            for s in blind:
                print("      %s" % s)
        report[tag] = {"rows": rows, "skipped": sorted(set(map(tuple, skipped))),
                       "git_blind": blind, "worktree_diff": wt}
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

        # ★ a probe that PRINTS the path image_path() gave it must not differ
        #   for that reason alone -- see the note in run().
        pp = os.path.join("notes", ".health_printpath.py")
        body = (head + "from asm_source import image_path\n"
                       "print(os.path.relpath(image_path(r,%r), r))\n" % primary)
        for t in trees.values():
            with open(os.path.join(t, "notes", ".health_printpath.py"), "w") as fh:
                fh.write(body)
        check(run(trees["full"], [pp])[1] == run(trees["stub"], [pp])[1],
              "printing the materialised path is not a difference (%s / %s)"
              % (run(trees["full"], [pp])[1].strip(),
                 run(trees["stub"], [pp])[1].strip()))

        # ★★ EVERY SCRATCH TREE MUST BE A REPOSITORY, AND MUST HAVE THIS TREE'S
        #   PREFIX.  When ROOT stopped being the repository root, the `.git`
        #   symlink this tool plants went dangling and every scratch tree became
        #   a non-repository.  A probe that reads the listing out of git then
        #   failed the same way in asis, full and stub -- full == stub -- and
        #   was graded UNAFFECTED.  A whole class of broken probes read as green,
        #   with nothing in the output to say so.
        gp = os.path.join("notes", ".health_gitread.py")
        gbody = (head + 'sys.path.insert(0, os.path.join(r, "notes"))\n'
                 'from asm_source import git_prefix, git_show\n'
                 'print(git_prefix(r), len(git_show(%r, "HEAD", r)))\n' % primary)
        for t in trees.values():
            with open(os.path.join(t, "notes", ".health_gitread.py"), "w") as fh:
                fh.write(gbody)
        got = {n: run(t, [gp]) for n, t in trees.items()}
        want = "%s %d" % (PREFIX, len(open(os.path.join(ROOT, primary),
                                          encoding="utf-8").read()))
        check(all(o[0] == 0 for o in got.values()),
              "git is REACHABLE from every scratch tree (%s)"
              % ", ".join("%s rc=%s" % (n, o[0]) for n, o in sorted(got.items())))
        check(all(o[1].strip() == want.strip() for o in got.values()),
              "...and a git read there returns THIS tree's committed listing "
              "(want %r, got %r)" % (want.strip(),
                                     got["asis"][1].strip()))

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

        # ★★ THE INSTRUMENT MUST NOT BE ABLE TO CHANGE WHAT IT MEASURES.
        # scripts/analysis/gen_prom_d_asm.py rewrites prom_d's four sources with
        # NO FLAG AT ALL, so the flag list above cannot catch it.  The first run
        # of this tool let it rewrite the `full` tree's expanded primary with the
        # split one, and every invocation after that compared two identical trees.
        wr = os.path.join("notes", ".health_writer.py")
        for t in trees.values():
            with open(os.path.join(t, "notes", ".health_writer.py"), "w") as fh:
                fh.write("import os\n"
                         "r=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n"
                         "open(os.path.join(r,%r),'a').write('; clobbered\\n')\n"
                         "print('wrote')\n" % primary)
        before = {n: open(os.path.join(t, primary), encoding="utf-8").read()
                  for n, t in trees.items()}
        outs = {n: run(t, [wr]) for n, t in trees.items()}
        check(all(PERM_DENIED.search(o[1]) for o in outs.values()),
              "a probe that tries to WRITE a source is REFUSED in every tree")
        check(all(open(os.path.join(t, primary), encoding="utf-8").read() == before[n]
                  for n, t in trees.items()),
              "...and every tree's layout is intact afterwards")
        check(grade({k: outs[k] for k in ("asis", "asis2", "full", "stub")}) == "WRITER",
              "...and it is graded WRITER, not UNAFFECTED")
        T = (None, "<timeout>")
        check(grade({"asis": T, "asis2": T, "full": T, "stub": T}) == "TIMEOUT",
              "grader: four identical timeouts are TIMEOUT, not UNAFFECTED")
        X, Yy = (0, "x"), (0, "y")
        check(grade({"asis": Yy, "asis2": Yy, "full": X, "stub": Yy},
                    "notes/asm_source.py") == "BY-DESIGN",
              "grader: a tool whose subject IS the layout is BY-DESIGN")
        check(grade({"asis": Yy, "asis2": Yy, "full": X, "stub": Yy},
                    "notes/prom_c_header_audit.py") == "VACUOUS",
              "...and an ordinary probe with the same numbers is still VACUOUS")

        # The git-blind detector, both directions.  ⚠ Tested on SYNTHETIC text,
        # not on a named file: the first version pinned
        # notes/wave7_round8_review_wd3_prom_d.py, and went red the moment that
        # file was migrated off `git show` -- a check that punishes the fix.
        for form in ('h = subprocess.run(["git", "show", "HEAD:prom_d/wsa1_prom_d.s"])',
                     'os.popen("cd %s && git show HEAD:prom_d/wsa1_prom_d.s" % ROOT)',
                     'git show 8ff84e5:prom_d/wsa1_prom_d.s'):
            check(git_blind_text(form, "prom_d/wsa1_prom_d.s"),
                  "git_blind SEES %r" % form[:46])
        # ⚠ SYNTHETIC TEXT, for the same reason the git_blind forms above are:
        #   pinning a real file makes the check go red the day that file is
        #   fixed, or the day a fixed file merely EXPLAINS the old spelling in a
        #   comment -- which is what asm_source.git_diff_lines does.
        check(worktree_diff_text('d = subprocess.run(["git", "-C", ROOT, "diff",'),
              "worktree_diff SEES a probe that diffs the working tree")
        check(not worktree_diff_text('from asm_source import image_lines\n'
                                     'lines = image_lines(ROOT, PRIMARY)\n'),
              "worktree_diff does NOT fire on a probe that does not")
        for form in ('SRC = image_path(ROOT, "prom_d/wsa1_prom_d.s")',
                     '# see prom_d/wsa1_prom_d.s for the directory'):
            check(not git_blind_text(form, "prom_d/wsa1_prom_d.s"),
                  "git_blind does NOT fire on %r" % form[:46])
    finally:
        for name in os.listdir(base):
            _thaw(os.path.join(base, name, PREFIX.rstrip("/")) if PREFIX
                  else os.path.join(base, name))
        shutil.rmtree(base, ignore_errors=True)
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
