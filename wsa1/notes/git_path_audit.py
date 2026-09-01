#!/usr/bin/env python3
"""Does every git read in this tree actually resolve, or does it quietly miss?

WHAT QUESTION THIS ANSWERS
--------------------------
  A probe that opens a file gets a traceback when the file is gone.  A probe
  that asks GIT for a file gets an empty string, and most of this tree's callers
  turn that into "no lines", "no labels", "no diff" -- an answer, not an error.

  On 2026-09-01 the disassembly moved from the root of its own repository into
  `wsa1/` of the unified tree.  `os.path` paths, all derived from `__file__`,
  followed it.  ★ GIT PATHS DID NOT: `<rev>:<path>` is resolved from the
  REPOSITORY ROOT and takes no notice of `-C <dir>` or `cwd=`.  So every
  `git show HEAD:prom_a/wsa1_prom_a.s` in this tree started asking for a path
  that no longer exists, and the ones that did not check a return code said
  nothing about it.

  This is the instrument for that class of failure, and it has two halves:

    LINT (static)   every git invocation site in every committed .py, classified
                    by whether its path goes through asm_source.git_path().
                    Cheap; run it in review.
    TRACE (dynamic) ★ THE EVIDENCE.  Each script is run with a logging `git` on
                    PATH, and every git call it issues is recorded with its
                    return code and the size of its output.  A read that FAILED
                    or came back EMPTY is the failure this tool is named for,
                    and the count is what a before/after is taken on.

  ⚠ THE TRACE IS THE HALF THAT CANNOT BE FOOLED.  The lint reads source; a
  script can spell a git call in a way the regex misses, and one that does would
  be reported clean.  The trace sees what was actually executed.

RUN
---
  python3 notes/git_path_audit.py                 lint every committed .py
  python3 notes/git_path_audit.py --trace         ★ run them under a logging git
  python3 notes/git_path_audit.py --trace --only prom_b
  python3 notes/git_path_audit.py --trace --json out.json
  python3 notes/git_path_audit.py --selftest      the instrument's controls

  A before/after is two --trace --json runs; `bad` per script is the number.

WHAT COUNTS AS BAD
------------------
  An OBJECT READ (`git show <rev>:<path>`, `git cat-file <rev>:<path>`) that
  returned non-zero, or a PATHSPEC-RESTRICTED read (`git show <rev> -- <path>`,
  `git diff <rev> -- <path>`) that returned NOTHING while naming a path that the
  revision does not spell that way.  The second shape never sets a return code:
  git is perfectly happy to restrict a diff to a path no side contains.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ⚠ asm_source is imported LAZILY, inside --selftest only.  This tool has to be
# runnable in a worktree of a revision whose asm_source cannot read git at all --
# that is precisely the state a before/after wants to measure.

TIMEOUT = 300

# ★ THE TRACE ONLY SEES THE GIT CALLS THE RUN ACTUALLY REACHES.  Most of these
# scripts keep their git read behind a flag, so a bare invocation walks straight
# past it and the script is reported "reads 0" -- which is not "clean", it is
# "not measured".  These are the READ-ONLY flags that reach the git code, read
# off each script's own main().  ⚠ NOTHING THAT WRITES A SOURCE GOES IN HERE:
# the trace runs in the tree it is pointed at, with no freeze, so a writer would
# edit the listing it is measuring.
SAFE_ARGV = {
    "notes/gen_prom_a_cover_round1.py":   ["--untouched"],
    "notes/gen_prom_a_cover_round2.py":   ["--untouched"],
    "notes/gen_prom_b_cover_round2.py":   ["--closure"],
    "notes/maincpu_join_probe.py":        ["--selftest"],
    "notes/prom_a_f85ff9_layout.py":      ["--null", "--rev", "HEAD"],
    "notes/prom_a_fa5aeb_layout.py":      ["--null", "--rev", "HEAD"],
    "notes/prom_a_fad800_layout.py":      ["--null", "--rev", "HEAD"],
    "notes/prom_a_frontier_delta.py":     ["--rev", "HEAD"],
    "notes/prom_a_naming_wave8_apply.py": ["--verify"],
    "notes/prom_b_evidence_audit.py":     ["--since"],
    "notes/prom_b_f65000_layout.py":      ["--null", "--rev", "HEAD"],
    "notes/prom_b_probe_answer_diff.py":  ["--base", "HEAD", "--only", "prom_b_string_refs"],
    "notes/promb_macro_rewrite.py":       ["--baseline"],
}

# A git call site: the literal "git" as the program of an argv list.
CALL_RE = re.compile(r'''["']git["']\s*,''')
# ...routed through the helper, on the same line or the two after it.
ROUTED_RE = re.compile(r'\bgit_path\s*\(|\bgit_pathspec\s*\(|\bgit_show\s*\(|'
                       r'\bgit_diff_lines\s*\(|\bimage_(?:lines|text)_at_rev\s*\(')
# An object read: something of the shape <rev>:<path> handed to show/cat-file.
OBJ_RE = re.compile(r'["\']\s*(?:show|cat-file)\s*["\']|'
                    r'%s:%s|\{rev\}:|\{base\}:|:%s|HEAD:|[0-9a-f]{7,40}:')
# A pathspec-restricted read, which fails SILENTLY.
SPEC_RE = re.compile(r'["\'](?:diff|show|log)["\'][^\n]*?["\']--["\']')
# ★ A PATHSPEC IS ONLY SUSPECT WHEN A REVISION IS NAMED.  `git diff -- prom_d/`
# against the working tree is cwd-relative and therefore CORRECT from here; it
# is `git diff <rev> -- prom_d/` that asks a revision for a path spelled the way
# THIS directory spells it.  Without this distinction the lint's bottom line is
# seven false alarms and nobody reads it.
REVTOK_RE = re.compile(r'\b(HEAD|REV|BASE|BASELINE|PRE_MERGE|BASE_COMMIT|'
                       r'JOIN_BASE|rev|base|commit|[0-9a-f]{7,40})\b')
# The module that DEFINES the helper cannot route through it.
IMPLEMENTATION = ("notes/asm_source.py",)


def committed_py(root=ROOT):
    out = subprocess.run(["git", "-C", root, "ls-files", "*.py"],
                         capture_output=True, text=True, check=True).stdout
    return sorted(p for p in out.split("\n") if p)


# ---------------------------------------------------------------------------
# LINT
def lint_file(root, rel):
    """[(lineno, kind, routed, text)] for every git call site in one file."""
    path = os.path.join(root, rel)
    try:
        lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
    except OSError:
        return []
    out = []
    for i, ln in enumerate(lines):
        if not CALL_RE.search(ln) and '"git"' not in ln and "'git'" not in ln:
            continue
        # ⚠ A GIT COMMAND LINE QUOTED INSIDE ANOTHER STRING IS A TEST FIXTURE,
        #   not a call.  probe_health's own git-blind detector is exercised on
        #   three such spellings; counting them makes the bottom line read 1 when
        #   the real answer is 0, and a lint that cries wolf is not read.
        idx = ln.find('"git"')
        if idx < 0:
            idx = ln.find("'git'")
        if idx > 0 and (ln.count("'", 0, idx) % 2 or ln.count('"', 0, idx) % 2):
            continue
        window = " ".join(lines[i:i + 3])
        if OBJ_RE.search(window) and (":" in window):
            kind = "OBJECT"
        elif SPEC_RE.search(window):
            head = window[:window.index('"--"') if '"--"' in window
                          else window.index("'--'")]
            kind = "PATHSPEC" if REVTOK_RE.search(head) else "PATHSPEC-WT"
        else:
            kind = "NO-PATH"
        routed = bool(ROUTED_RE.search(" ".join(lines[max(0, i - 3):i + 3]))) \
            or rel in IMPLEMENTATION
        out.append((i + 1, kind, routed, ln.strip()[:110]))
    return out


def lint(root, only=None):
    rows = []
    for rel in committed_py(root):
        if only and only not in rel:
            continue
        for lineno, kind, routed, text in lint_file(root, rel):
            rows.append({"file": rel, "line": lineno, "kind": kind,
                         "routed": routed, "text": text})
    return rows


# ---------------------------------------------------------------------------
# TRACE
SHIM = '''#!/usr/bin/env python3
import json, os, subprocess, sys
r = subprocess.run([%(real)r] + sys.argv[1:], capture_output=True)
sys.stdout.buffer.write(r.stdout)
sys.stderr.buffer.write(r.stderr)
try:
    with open(os.environ["GIT_AUDIT_LOG"], "a") as fh:
        fh.write(json.dumps({"argv": sys.argv[1:], "cwd": os.getcwd(),
                             "rc": r.returncode, "out": len(r.stdout),
                             "err": r.stderr.decode("utf-8", "replace")[:200]})
                 + "\\n")
except OSError:
    pass
sys.exit(r.returncode)
'''


def _shim_dir(base):
    real = shutil.which("git")
    if real is None:
        raise RuntimeError("no git on PATH; the trace has nothing to wrap")
    d = os.path.join(base, "shim")
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, "git")
    with open(p, "w") as fh:
        fh.write(SHIM % {"real": real})
    os.chmod(p, 0o755)
    return d


REV_PATH = re.compile(r'^(?!-)([^:]+):(.+)$')


def _toplevel(root):
    return subprocess.run(["git", "-C", root, "rev-parse", "--show-toplevel"],
                          capture_output=True, text=True).stdout.strip()


def _effective(call, root, pth):
    """★ HOW GIT ITSELF RESOLVES A PATHSPEC: relative to the CURRENT DIRECTORY,
    which is `-C <dir>` if given and the process cwd otherwise -- never relative
    to the repository.  Checking the literal string against the revision, as the
    first version of this did, misses the whole bug: `prom_a/wsa1_prom_a.s`
    exists at a pre-move revision, so it looked fine, while git was actually
    asking that revision for `wsa1/prom_a/wsa1_prom_a.s`."""
    argv = call["argv"]
    cwd = call.get("cwd") or root
    if "-C" in argv:
        cwd = argv[argv.index("-C") + 1]
    top = _toplevel(root)
    rel = os.path.relpath(os.path.abspath(cwd), top)
    if rel == ".":
        rel = ""
    return os.path.normpath(os.path.join(rel, pth)).replace(os.sep, "/")


def _rev_of(argv, i):
    """The revision named on a `diff`/`show`/`log` command line, if any."""
    for a in argv[i + 1:]:
        if a == "--":
            break
        if a.startswith("-"):
            continue
        return a.split("..")[0]
    return None


def classify_call(call, root):
    """-> (kind, ok, detail).  kind in OBJECT / PATHSPEC / OTHER."""
    argv = call["argv"]
    sub = None
    i = 0
    while i < len(argv):
        if argv[i] == "-C":
            i += 2
            continue
        if argv[i].startswith("-"):
            i += 1
            continue
        sub = argv[i]
        break
    if sub in ("show", "cat-file"):
        # ⚠ `cat-file -e` ASKS WHETHER A PATH EXISTS.  A non-zero answer is the
        #   answer, not a fault -- git_path() uses exactly this to find out which
        #   spelling a revision uses, and counting its "no" as a broken read
        #   would make the FIX look worse than the bug.
        probe = sub == "cat-file" and "-e" in argv
        for a in argv[i + 1:]:
            m = REV_PATH.match(a)
            if m and "/" in m.group(2):
                return ("PROBE" if probe else "OBJECT",
                        True if probe else call["rc"] == 0,
                        "%s (rc=%d)" % (a, call["rc"]))
    if "--" in argv and sub in ("show", "diff", "log"):
        spec = argv[argv.index("--") + 1:]
        rev = _rev_of(argv, i)
        if spec:
            # ★ A PATHSPEC READ NEVER SETS A RETURN CODE.  git is perfectly happy
            #   to restrict a diff to a path that no side of it contains, and the
            #   answer is then "nothing changed" -- or, across the move, the whole
            #   file counted as ADDED.  So the pathspec is checked against the
            #   revision it was handed, in the spelling it was handed in.
            for pth in spec:
                # ★ `:(top)x` and `:/x` are ALREADY repository-relative -- that is
                #   what the magic is for, and asm_source.git_pathspec emits it.
                #   Running them through the cwd rule produces `wsa1/(top)x`.
                magic = pth.startswith(":(top)") or pth.startswith(":/")
                if magic:
                    pth = pth[6:] if pth.startswith(":(top)") else pth[2:]
                else:
                    pth = pth.split(":")[-1]
                pth = pth.rstrip("/")
                if not pth or pth.startswith("-"):
                    continue
                eff = pth if magic else _effective(call, root, pth)
                # ⚠ THE WORKING-TREE FALLBACK IS ONLY FOR A DIFF WITH NO
                #   REVISION.  When a revision IS named, "the path exists on
                #   disk" is exactly the wrong test: `wsa1/prom_a/...` exists
                #   here and does not exist at any pre-move revision, which is
                #   the whole fault.
                if _exists(root, rev or "HEAD", eff):
                    continue
                if rev is None and os.path.exists(
                        os.path.join(_toplevel(root), eff)):
                    continue
                alt = _flip(root, eff)
                if _exists(root, rev or "HEAD", alt):
                    return ("PATHSPEC", False,
                            "git asks %s for %s; that revision spells it %s"
                            % (rev or "the working tree", eff, alt))
                return ("PATHSPEC", False,
                        "git asks %s for %s, which it does not contain"
                        % (rev or "the working tree", eff))
            # ⚠ AN EMPTY DIFF IS NOT A FAULT.  A working-tree diff of a clean
            #   tree is empty and correct.  What is a fault is a pathspec the
            #   named revision does not spell that way -- checked above -- which
            #   produces a big, successful, meaningless answer instead.
            return ("PATHSPEC", True,
                    "%s -> %d byte(s)" % (" ".join(spec), call["out"]))
    return ("OTHER", call["rc"] == 0, sub or "?")


def _exists(root, rev, path):
    return subprocess.run(["git", "-C", root, "cat-file", "-e",
                           "%s:%s" % (rev, path)],
                          capture_output=True).returncode == 0


def _flip(root, path):
    """The same path spelled the OTHER way: prefixed if bare, bare if prefixed."""
    try:
        sys.path.insert(0, os.path.join(root, "notes"))
        from asm_source import git_prefix as _gp
        prefix = _gp(root)
    except Exception:
        prefix = ""
    if not prefix:
        return path
    return path[len(prefix):] if path.startswith(prefix) else prefix + path


def trace_script(root, rel, base, argv_extra=()):
    log = os.path.join(base, "log-%s.jsonl" % rel.replace("/", "_"))
    open(log, "w").close()
    env = dict(os.environ,
               PATH=_shim_dir(base) + os.pathsep + os.environ["PATH"],
               GIT_AUDIT_LOG=log, PYTHONHASHSEED="0",
               PYTHONDONTWRITEBYTECODE="1")
    try:
        r = subprocess.run([sys.executable, rel] + list(argv_extra), cwd=root,
                           env=env, stdin=subprocess.DEVNULL,
                           capture_output=True, text=True, timeout=TIMEOUT)
        rc, out = r.returncode, (r.stdout + r.stderr)
    except subprocess.TimeoutExpired:
        rc, out = None, "<timeout>"
    calls = []
    with open(log) as fh:
        for line in fh:
            line = line.strip()
            if line:
                calls.append(json.loads(line))
    rows = []
    for c in calls:
        kind, ok, detail = classify_call(c, root)
        rows.append({"kind": kind, "ok": ok, "detail": detail,
                     "argv": c["argv"], "rc": c["rc"], "out": c["out"]})
    bad = sum(1 for r_ in rows if not r_["ok"] and r_["kind"] not in ("OTHER",
                                                                      "PROBE"))
    reads = sum(1 for r_ in rows if r_["kind"] in ("OBJECT", "PATHSPEC"))
    return {"script": rel, "rc": rc, "reads": reads, "bad": bad,
            "calls": rows,
            "traceback": "Traceback" in (out or ""),
            "tail": (out or "")[-400:]}


def git_scripts(root, only=None):
    """Committed .py that read a revision -- raw, or through the helper.

    ⚠⚠ THE SECOND HALF IS NOT OPTIONAL.  Discovery used to be "has a raw git
    call site", so the moment a script was migrated to asm_source.git_show it
    DROPPED OUT of the trace: the sweep that was meant to prove the fix went from
    31 scripts to 3 and reported 2 bad reads, which looks like a triumph and is
    an empty room.  A tool that stops measuring what it just fixed measures
    nothing."""
    out = []
    for rel in committed_py(root):
        if only and only not in rel:
            continue
        rows = lint_file(root, rel)
        if any(r[1] in ("OBJECT", "PATHSPEC") for r in rows):
            out.append(rel)
            continue
        try:
            txt = open(os.path.join(root, rel), encoding="utf-8").read()
        except OSError:
            continue
        if ROUTED_RE.search(txt):
            out.append(rel)
    return out


# ---------------------------------------------------------------------------
# PINNED REVISIONS
# ★ A BASELINE IS A DEPENDENCY, AND AN UNREACHABLE ONE IS A SILENT DEADLINE.
# Six probes compare the working tree with a revision they name by hash.  The
# 2026-09-01 migration rewrote the WSA1R history into `wsa1/`, so those hashes
# are NOT ancestors of HEAD any more; they resolve only because a tag still
# points at the old tip.  Nothing in the tree said so, and nothing would have
# said so on the day the tag went away and every one of those probes started
# raising "cannot read ... at ...".
REV_ASSIGN = re.compile(
    r'^\s*(BASE|BASE_COMMIT|BASELINE|PRE_MERGE|JOIN_BASE|REV|COMMIT)\s*=\s*'
    r'["\']([0-9a-f]{7,40})["\']', re.M)
REV_INLINE = re.compile(r'["\']([0-9a-f]{7,40}):')
REV_ARG = re.compile(r'["\']([0-9a-f]{7,40})["\']\s*,\s*["\']--["\']')
# ★ AND ANY HEX LITERAL ON A LINE THAT TALKS TO GIT.  The three that the
# assignment and `<rev>:` forms missed were all of this shape:
#   git_show("prom_a/...", "47d40941b750")   git_diff_lines(..., "ebabc85", ...)
#   REV = os.environ.get('REV', 'db9d8b5')
# A hex constant that is not a revision comes back GONE, which is a visible
# false alarm rather than an invisible miss -- the right way round.
REV_LINE = re.compile(r'git_show|git_diff_lines|git_pathspec|image_(?:lines|text)'
                      r'_at_rev|["\']git["\']|environ\.get')
REV_HEX = re.compile(r'["\']([0-9a-f]{7,40})["\']')


def pinned_revs(root=ROOT):
    found = {}
    for rel in committed_py(root):
        try:
            txt = open(os.path.join(root, rel), encoding="utf-8").read()
        except OSError:
            continue
        for m in REV_ASSIGN.finditer(txt):
            found.setdefault(m.group(2), set()).add("%s (%s=)" % (rel, m.group(1)))
        for rx in (REV_INLINE, REV_ARG):
            for m in rx.finditer(txt):
                found.setdefault(m.group(1), set()).add(rel)
        for ln in txt.split("\n"):
            if REV_LINE.search(ln):
                for m in REV_HEX.finditer(ln):
                    found.setdefault(m.group(1), set()).add(rel)
    rows = []
    for rev in sorted(found):
        t = subprocess.run(["git", "-C", root, "cat-file", "-t", rev],
                           capture_output=True, text=True)
        resolves = t.returncode == 0 and t.stdout.strip() == "commit"
        ancestor = resolves and subprocess.run(
            ["git", "-C", root, "merge-base", "--is-ancestor", rev, "HEAD"],
            capture_output=True).returncode == 0
        where = ""
        if resolves and not ancestor:
            refs = subprocess.run(
                ["git", "-C", root, "for-each-ref", "--contains", rev,
                 "--format=%(refname)"], capture_output=True, text=True).stdout
            where = " ".join(refs.split()) or "(no ref -- unreferenced object)"
        rows.append({"rev": rev, "resolves": resolves, "ancestor": ancestor,
                     "where": where, "sites": sorted(found[rev])})
    return rows


# ---------------------------------------------------------------------------
def _selftest():
    """INVARIANTS.  ★ The two that matter are the CONTROLS: the instrument must
    catch a deliberately-broken git read, and must not flag a fixed one."""
    fails = []

    def check(name, cond, detail=""):
        print("  %s  %s%s" % ("PASS" if cond else "FAIL", name,
                              ("   " + detail) if detail and not cond else ""))
        if not cond:
            fails.append(name)

    sys.path.insert(0, os.path.join(ROOT, "notes"))
    from asm_source import git_prefix          # noqa: E402  (see the note above)
    prefix = git_prefix(ROOT)
    IMAGES_DIR = "prom_a"
    print("  (this tree's git prefix is %r)" % prefix)

    with tempfile.TemporaryDirectory() as td:
        # the shim must log, and must be transparent
        log = os.path.join(td, "l.jsonl")
        open(log, "w").close()
        env = dict(os.environ, PATH=_shim_dir(td) + os.pathsep + os.environ["PATH"],
                   GIT_AUDIT_LOG=log)
        r = subprocess.run(["git", "-C", ROOT, "rev-parse", "--show-prefix"],
                           env=env, capture_output=True, text=True)
        check("the shim passes git's own output through unchanged",
              r.stdout.strip() == prefix.strip("/") + ("/" if prefix else ""),
              repr(r.stdout))
        n = len([l for l in open(log) if l.strip()])
        check("the shim logs the call it wrapped", n == 1, "%d" % n)

        # ★ CONTROL A: a deliberately broken object read must be caught.
        bad_py = os.path.join(ROOT, "notes", ".audit_control_bad.py")
        good_py = os.path.join(ROOT, "notes", ".audit_control_good.py")
        try:
            open(bad_py, "w").write(
                'import subprocess, os\n'
                'ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n'
                'subprocess.run(["git", "-C", ROOT, "show",\n'
                '                "HEAD:prom_a/wsa1_prom_a.s"], capture_output=True)\n')
            open(good_py, "w").write(
                'import os, sys\n'
                'ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n'
                'sys.path.insert(0, os.path.join(ROOT, "notes"))\n'
                'from asm_source import git_show\n'
                'git_show("prom_a/wsa1_prom_a.s")\n')
            rb = trace_script(ROOT, "notes/.audit_control_bad.py", td)
            rg = trace_script(ROOT, "notes/.audit_control_good.py", td)
            if prefix:
                check("★ CONTROL: an UNPREFIXED object read is reported bad",
                      rb["bad"] >= 1, "bad=%d reads=%d" % (rb["bad"], rb["reads"]))
            else:
                check("(no prefix: the unprefixed read is correct here)", True)
            check("★ CONTROL: the same read through git_show() is reported clean",
                  rg["bad"] == 0 and rg["reads"] >= 1,
                  "bad=%d reads=%d" % (rg["bad"], rg["reads"]))
            # the lint must agree about the two
            lb = lint_file(ROOT, "notes/.audit_control_bad.py")
            lg = lint_file(ROOT, "notes/.audit_control_good.py")
            check("the lint sees the raw call site and calls it unrouted",
                  any(k == "OBJECT" and not routed for _, k, routed, _ in lb),
                  "%s" % lb)
            check("the lint sees no unrouted object read in the fixed one",
                  not any(k == "OBJECT" and not routed for _, k, routed, _ in lg),
                  "%s" % lg)
        finally:
            for p in (bad_py, good_py):
                if os.path.exists(p):
                    os.remove(p)

    # classify_call must not call a successful read bad, nor a failure good
    check("classify_call: rc!=0 on an object read is bad",
          classify_call({"argv": ["show", "HEAD:a/b.s"], "rc": 128, "out": 0},
                        ROOT)[1] is False)
    check("classify_call: rc==0 on an object read is fine",
          classify_call({"argv": ["show", "HEAD:a/b.s"], "rc": 0, "out": 99},
                        ROOT)[1] is True)
    check("classify_call: an EMPTY pathspec read over a path that EXISTS is not "
          "a fault (a clean tree diffs to nothing)",
          classify_call({"argv": ["diff", "--", IMAGES_DIR], "cwd": ROOT,
                         "rc": 0, "out": 0}, ROOT)[1] is True)
    check("classify_call: a pathspec naming a path nothing holds IS a fault",
          classify_call({"argv": ["diff", "--", "no_such_dir/x.s"], "cwd": ROOT,
                         "rc": 0, "out": 0}, ROOT)[1] is False)
    check("classify_call: `cat-file -e` saying no is a PROBE, not a broken read",
          classify_call({"argv": ["-C", ROOT, "cat-file", "-e", "HEAD:a/b.s"],
                         "cwd": ROOT, "rc": 1, "out": 0}, ROOT)[0] == "PROBE")
    check("classify_call: a `:(top)` pathspec is NOT re-prefixed with the cwd",
          classify_call({"argv": ["show", "HEAD", "--",
                                  ":(top)" + prefix + "prom_a/wsa1_prom_a.s"],
                         "cwd": ROOT, "rc": 0, "out": 9}, ROOT)[1] is True)
    check("classify_call: `-C <dir>` is not mistaken for the subcommand",
          classify_call({"argv": ["-C", "/x", "show", "HEAD:a/b.s"], "rc": 0,
                         "out": 5}, ROOT)[0] == "OBJECT")
    # ★ CONTROL for the SILENT half.  A pathspec is CWD-relative, so the same
    #   spelling that is correct against HEAD is wrong against any revision from
    #   before the move -- and the wrong one does not fail, it reports the whole
    #   file as added.  Both directions, or "not flagged" would be free.
    if prefix:
        k, ok, _d = classify_call(
            {"argv": ["diff", "HEAD", "--", "prom_a/wsa1_prom_a.s"],
             "cwd": ROOT, "rc": 0, "out": 999999}, ROOT)
        check("a pathspec that git resolves to a path HEAD holds is NOT flagged",
              (k, ok) == ("PATHSPEC", True))
        k, ok, _d = classify_call(
            {"argv": ["diff", "8ff84e5", "--", "prom_a/wsa1_prom_a.s"],
             "cwd": ROOT, "rc": 0, "out": 999999}, ROOT)
        check("★ CONTROL: the SAME spelling at a PRE-MOVE revision is bad too -- "
              "git prefixes it with the cwd either way",
              (k, ok) == ("PATHSPEC", False))
        top = _toplevel(ROOT)
        k, ok, _d = classify_call(
            {"argv": ["diff", "HEAD", "--", prefix + "prom_a/wsa1_prom_a.s"],
             "cwd": top, "rc": 0, "out": 10}, ROOT)
        check("...and the correct spelling, from the repository root, is not "
              "flagged", ok is True)

    # ---- pinned revisions -------------------------------------------------
    rows = pinned_revs(ROOT)
    check("every pinned revision this tree names still RESOLVES",
          all(r["resolves"] for r in rows),
          ", ".join(r["rev"] for r in rows if not r["resolves"]))
    check("the pinned-revision scanner finds something at all", len(rows) > 0,
          "%d" % len(rows))
    check("a revision that cannot resolve is reported GONE, not skipped",
          not any(r["resolves"] for r in pinned_revs_synthetic()),
          "control")

    print("\nFAILURES: %d" % len(fails))
    return 1 if fails else 0


def pinned_revs_synthetic():
    """The CONTROL for pinned_revs: a hash no repository holds must come back
    unresolvable.  A scanner that silently dropped what it could not resolve
    would report a clean sheet forever."""
    rev = "deadbee" + "f" * 33
    t = subprocess.run(["git", "-C", ROOT, "cat-file", "-t", rev],
                       capture_output=True, text=True)
    return [{"rev": rev, "resolves": t.returncode == 0 and
             t.stdout.strip() == "commit", "ancestor": False, "where": "",
             "sites": []}]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--trace", action="store_true")
    ap.add_argument("--only", default=None)
    ap.add_argument("--json", default=None)
    ap.add_argument("--revs", action="store_true",
                    help="every pinned revision this tree names, and what keeps "
                         "it reachable")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--reclassify", default=None,
                    help="re-grade a previous --trace --json without re-running "
                         "anything; the raw argv of every git call is stored")
    a = ap.parse_args()
    if a.selftest:
        return _selftest()

    if a.revs:
        rows = pinned_revs(ROOT)
        for r in rows:
            print("  %-6s %-42s %-14s %s"
                  % ("OK" if r["resolves"] else "GONE", r["rev"],
                     "ancestor" if r["ancestor"] else "NOT an ancestor",
                     r["where"]))
            for site in r["sites"]:
                print("           %s" % site)
        gone = [r for r in rows if not r["resolves"]]
        orphan = [r for r in rows if r["resolves"] and not r["ancestor"]]
        print("\n%d pinned revision(s); %d unresolvable; %d resolvable but NOT "
              "reachable from HEAD" % (len(rows), len(gone), len(orphan)))
        if orphan:
            print("  ⚠ those %d survive only through the ref(s) named above.  "
                  "Delete it and `git gc` drops the baseline of every probe "
                  "listed under it." % len(orphan))
        if a.json:
            json.dump(rows, open(a.json, "w"), indent=1)
        return 1 if gone else 0

    if a.reclassify:
        out = json.load(open(a.reclassify))
        for r in out:
            rows = []
            for c in r["calls"]:
                # ⚠ the trace always runs a script with cwd=ROOT, so that is the
                #   cwd a stored call had unless it carried its own `-C`.
                call = {"argv": c["argv"], "rc": c["rc"], "out": c["out"],
                        "cwd": c.get("cwd", ROOT)}
                kind, ok, detail = classify_call(call, ROOT)
                rows.append(dict(c, kind=kind, ok=ok, detail=detail))
            r["calls"] = rows
            r["bad"] = sum(1 for x in rows
                           if not x["ok"] and x["kind"] not in ("OTHER", "PROBE"))
            r["reads"] = sum(1 for x in rows if x["kind"] in ("OBJECT", "PATHSPEC"))
        for r in out:
            flag = "BAD " if r["bad"] else ("    " if r["reads"] else "  - ")
            print("  %s%-58s reads %3d  bad %3d  rc %s"
                  % (flag, " ".join([r["script"]] + list(SAFE_ARGV.get(r["script"], ()))),
                     r["reads"], r["bad"], r["rc"]))
            for c in r["calls"]:
                if not c["ok"] and c["kind"] not in ("OTHER", "PROBE"):
                    print("        %-8s %s" % (c["kind"], c["detail"][:120]))
        nbad = sum(1 for r in out if r["bad"])
        print("\n%d script(s); %d issued a git read that FAILED or was spelled for "
              "another revision; %d total bad reads"
              % (len(out), nbad, sum(r["bad"] for r in out)))
        if a.json:
            json.dump(out, open(a.json, "w"), indent=1)
        return 1 if nbad else 0

    if not a.trace:
        rows = lint(ROOT, a.only)
        bad = [r for r in rows if r["kind"] in ("OBJECT", "PATHSPEC")
               and not r["routed"]]
        for r in rows:
            if r["kind"] == "NO-PATH":
                continue
            print("  %-9s %-7s %s:%d  %s"
                  % (r["kind"], "routed" if r["routed"] else "RAW",
                     r["file"], r["line"], r["text"]))
        print("\n%d git call site(s); %d name a path and do NOT go through "
              "asm_source.git_path()" % (len(rows), len(bad)))
        if a.json:
            json.dump(rows, open(a.json, "w"), indent=1)
        return 1 if bad else 0

    scripts = git_scripts(ROOT, a.only)
    base = tempfile.mkdtemp(prefix="gitaudit-")
    out = []
    try:
        for rel in scripts:
            r = trace_script(ROOT, rel, base, SAFE_ARGV.get(rel, ()))
            out.append(r)
            flag = "BAD " if r["bad"] else ("    " if r["reads"] else "  - ")
            print("  %s%-58s reads %3d  bad %3d  rc %s%s"
                  % (flag, " ".join([rel] + list(SAFE_ARGV.get(rel, ()))),
                     r["reads"], r["bad"], r["rc"],
                     "  TRACEBACK" if r["traceback"] else ""))
            for c in r["calls"]:
                if not c["ok"] and c["kind"] not in ("OTHER", "PROBE"):
                    print("        %-8s %s" % (c["kind"], c["detail"][:120]))
    finally:
        shutil.rmtree(base, ignore_errors=True)
    nbad = sum(1 for r in out if r["bad"])
    print("\n%d script(s) traced; %d issued a git read that FAILED or came back "
          "EMPTY; %d total bad reads"
          % (len(out), nbad, sum(r["bad"] for r in out)))
    if a.json:
        json.dump(out, open(a.json, "w"), indent=1)
    return 1 if nbad else 0


if __name__ == "__main__":
    sys.exit(main())
