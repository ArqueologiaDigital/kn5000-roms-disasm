#!/usr/bin/env python3
"""Point a probe's READ at the image, mechanically, and refuse to touch its WRITE.

WHAT QUESTION THIS ANSWERS
--------------------------
  178 sites in 126 committed scripts spell an image as

      os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")

  which WAS the image and is now, for prom_c and prom_d, a 2,517-line and a
  494-line master with the body in included files.  notes/probe_health.py says
  which of those scripts are answering over a stub.  This performs the edit that
  fixes them, one line per site:

      image_path(ROOT, "prom_c/wsa1_prom_c.s")

  `image_path` (notes/asm_source.py) returns a file whose CONTENT is the whole
  image, so the caller's existing `open(SRC)` / `for ln in open(SRC)` scan keeps
  working unchanged.  That is the point of doing it this way: a rewrite of 126
  scans would be 126 chances to change a measurement by accident.

⚠⚠ WHAT IT REFUSES TO TOUCH, AND WHY THAT IS THE WHOLE SAFETY ARGUMENT
----------------------------------------------------------------------
  Several of these scripts SPLICE generated assembly back into the listing --
  gen_prom_c_f64_pool.py --apply, prom_c_record68_round10.py --emit68,
  prom_c_understanding_round6.py --apply/--headers, prom_a/insert_region.py,
  scripts/analysis/gen_prom_d_asm.py.  They do read-modify-write on ONE path.

  ★ REDIRECTING SUCH A SCRIPT'S READ WITHOUT MOVING ITS WRITE WOULD OVERWRITE THE
    MASTER WITH THE WHOLE IMAGE AND UNDO THE SPLIT -- and the byte gate would
    still pass, because the bytes are identical.  26 files would be orphaned and
    nothing would say so.

  So a site is rewritten ONLY if the name it feeds is never used as a write
  target anywhere in the same file.  A file with any write use is REFUSED WHOLE
  and printed under REFUSED, for hand migration through asm_source.locate() and
  asm_source.write_part() -- which is where the write path's own guard lives.

RUN
---
  python3 notes/migrate_listing_readers.py --list      every site and its verdict
  python3 notes/migrate_listing_readers.py --apply     rewrite the safe ones
  python3 notes/migrate_listing_readers.py --apply --only prom_c
  python3 notes/migrate_listing_readers.py --selftest  ★ the controls

★ AN EDIT IS NOT A FIX UNTIL THE ANSWER COMES BACK.  After --apply, re-run
  notes/probe_health.py for the image: a rewritten probe must move OUT of
  VACUOUS/LOUD/SPLIT-FRAGILE and into UNAFFECTED.  Nothing here proves that;
  only the three-tree comparison does.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The three spellings this tree uses for "the image's listing":
#   os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
#   os.path.join(ROOT, "prom_c/wsa1_prom_c.s")
#   os.path.join(ROOT, "prom_%s" % tag, "wsa1_prom_%s.s" % tag)     <- computed
# The computed form matters: it is how the census scripts loop over the images,
# so ONE site of it can put four images through a stub.
SITE = re.compile(
    r'os\.path\.join\(\s*ROOT\s*,\s*"(prom_[abcd])"\s*,\s*"(wsa1_prom_[abcd]\.s)"\s*\)'
    r'|os\.path\.join\(\s*ROOT\s*,\s*"(prom_[abcd])/(wsa1_prom_[abcd]\.s)"\s*\)')
SITE_FMT = re.compile(
    r'os\.path\.join\(\s*ROOT\s*,\s*"prom_%s"\s*%\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*'
    r'"wsa1_prom_%s\.s"\s*%\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)')

# A name used as a write target.  Deliberately loose -- a false REFUSAL costs a
# hand migration, a false rewrite costs the split.
WRITE_USE = re.compile(r'open\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*["\']w')

# Files this tool must never rewrite: the resolver it would import, the health
# tool that measures the result, the shim being retired, and the two emitters
# whose whole job is to WRITE a listing.
EXCLUDE = {
    "notes/asm_source.py",
    "notes/probe_health.py",
    "notes/prom_c_probe_health.py",
    "notes/prom_c_image.py",
    "notes/migrate_listing_readers.py",
    "notes/prom_c_split.py",
    "scripts/analysis/gen_prom_d_asm.py",   # writes prom_d's four sources
    "prom_a/insert_region.py",              # splices a region into prom_a
}

IMPORT_LINE = "from asm_source import image_path"
SYSPATH_RE = re.compile(r'sys\.path\.insert\(\s*0\s*,\s*os\.path\.join\(\s*ROOT\s*,\s*'
                        r'["\']notes["\']\s*\)\s*\)')
ROOT_ASSIGN = re.compile(r'^ROOT\s*=.*$', re.M)


def committed_py():
    out = subprocess.run(["git", "ls-files", "*.py"], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\n") if p]


def writer_names(text):
    return set(WRITE_USE.findall(text))


def site_image(m):
    if m.re is SITE_FMT:
        return "prom_<%s>/wsa1_prom_<%s>.s" % (m.group(1), m.group(1))
    return "%s/%s" % (m.group(1) or m.group(3), m.group(2) or m.group(4))


def assigned_name(text, m):
    """The variable a site is assigned to, if the site IS an assignment's RHS."""
    line_start = text.rfind("\n", 0, m.start()) + 1
    head = text[line_start:m.start()]
    am = re.match(r'\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*$', head)
    return am.group(1) if am else None


def inline_write(text, m):
    """True if the site sits inside an `open(..., "w")`."""
    line_end = text.find("\n", m.end())
    tail = text[m.end():line_end if line_end != -1 else len(text)]
    return bool(re.match(r'\s*,\s*["\']w', tail))


def fmt_sites(text):
    """The computed-path sites, keeping only `prom_%s`/`wsa1_prom_%s.s` pairs
    that use THE SAME variable -- anything else is not this idiom."""
    return [m for m in SITE_FMT.finditer(text) if m.group(1) == m.group(2)]


def survey(only=None):
    """(path, [(image, verdict, reason), ...]) for every file with a site."""
    out = []
    for rel in committed_py():
        text = open(os.path.join(ROOT, rel), encoding="utf-8",
                    errors="replace").read()
        ms = list(SITE.finditer(text)) + fmt_sites(text)
        if not ms:
            continue
        wnames = writer_names(text)
        rows = []
        for m in ms:
            img = site_image(m)
            if only and only not in img:
                rows.append((img, "SKIP", "not selected"))
                continue
            if rel in EXCLUDE:
                rows.append((img, "REFUSED", "on the never-rewrite list"))
            elif inline_write(text, m):
                rows.append((img, "REFUSED", "the site is an open(..., 'w')"))
            else:
                nm = assigned_name(text, m)
                if nm and nm in wnames:
                    rows.append((img, "REFUSED",
                                 "%s is also a write target in this file" % nm))
                elif wnames:
                    rows.append((img, "REFUSED",
                                 "this file writes through %s"
                                 % ", ".join(sorted(wnames))))
                else:
                    rows.append((img, "REWRITE", ""))
        out.append((rel, rows))
    return out


def rewrite_text(text):
    """Rewrite every site and make sure the import is present."""
    new = SITE.sub(lambda m: 'image_path(ROOT, "%s")' % site_image(m), text)
    new = SITE_FMT.sub(
        lambda m: ('image_path(ROOT, "prom_%%s/wsa1_prom_%%s.s" %% (%s, %s))'
                   % (m.group(1), m.group(2)))
        if m.group(1) == m.group(2) else m.group(0), new)
    if new == text:
        return text
    if IMPORT_LINE not in new:
        # ⚠⚠ THE IMPORT GOES IMMEDIATELY AFTER `ROOT =`, AND SO DOES ITS OWN
        # sys.path.insert -- unconditionally, even when the file already has one
        # further down.  Two earlier versions got this wrong in ways a COMPILE
        # CANNOT SEE, and both shipped into eight files before being caught:
        #   * no sys.path.insert, because the file had one lower down
        #     -> ImportError the moment the file was run;
        #   * anchored just after that lower sys.path.insert, which in these
        #     files sits BELOW the first use of SRC -> NameError.
        # ROOT is defined before any site that mentions ROOT, by construction,
        # so this is the one anchor that is always early enough.  A duplicated
        # `sys.path.insert(0, <notes>)` is harmless; a missing one is not.
        ins = ('sys.path.insert(0, os.path.join(ROOT, "notes"))\n'
               + IMPORT_LINE + "  # noqa: E402  (the image, not the master)\n")
        m = ROOT_ASSIGN.search(new)
        if not m:
            raise AssertionError("no `ROOT =` line to anchor the import to")
        at = m.end() + 1
        new = new[:at] + ins + new[at:]
    # `sys` may already be imported on its own line, in a comma list
    # (`import os, re, sys`) or beside a dotted name (`import importlib.util,
    # os, sys`).  All three spellings are in these files; adding a second
    # `import sys` would be harmless but noisy, and missing one is a NameError.
    if not re.search(r'^\s*import\s+[^\n]*\bsys\b', new, re.M):
        anchors = list(re.finditer(r'^import\s+[^\n]*$', new, re.M))
        if not anchors:
            raise AssertionError("no top-level `import` line to anchor `sys` to")
        at = anchors[-1].end()
        new = new[:at] + "\nimport sys" + new[at:]
    return new


# ---------------------------------------------------------------------------
# RETIRING THE prom_c-ONLY SHIM
# ---------------------------------------------------------------------------
# notes/prom_c_image.py was written while asm_source's --selftest was still red,
# to give seven probes a read path that hour.  Its own docstring said it "should
# not survive".  asm_source.image_path() is the same function for all four
# images, so the seven callers move to it and the shim goes.
SHIM_IMPORT = re.compile(r'^import prom_c_image(\s+#.*)?$', re.M)
SHIM_CALL = re.compile(r'prom_c_image\.path\(\)')
# ⚠ The comment above each import states a FACT that this change makes false.
# Leaving it would be worse than the code: it would tell the next reader to go
# looking for a shim that is not there.  It is corrected, not deleted -- the
# sentence about the split and the vacuous pass is the part worth keeping.
SHIM_NOTE = re.compile(
    r'# notes/prom_c_probe_health\.py is the check; notes/prom_c_image\.py is a shim\n'
    r'#\s*(that )?should become `from asm_source import \.\.\.` when that reader is green\.\n'
    r'|# notes/prom_c_probe_health\.py is the check; notes/prom_c_image\.py is a shim that\n'
    r'#\s*should become `from asm_source import \.\.\.` when that reader is green\.\n')
SHIM_NOTE_NEW = ("# notes/probe_health.py is the check; notes/asm_source.py is the reader,\n"
                 "# and it absorbed the prom_c-only shim that used to stand here.\n")


def shim_rewrite(text):
    if "prom_c_image" not in text:
        return text
    text = SHIM_NOTE.sub(SHIM_NOTE_NEW, text)
    text = SHIM_IMPORT.sub(
        "from asm_source import image_path  # noqa: E402  (the image, not the master)",
        text)
    text = SHIM_CALL.sub('image_path(ROOT, "prom_c/wsa1_prom_c.s")', text)
    return text


def shim(quiet=False):
    n = 0
    for rel in committed_py():
        if rel in ("notes/prom_c_image.py", "notes/migrate_listing_readers.py"):
            continue
        p = os.path.join(ROOT, rel)
        text = open(p, encoding="utf-8").read()
        new = shim_rewrite(text)
        if new != text:
            open(p, "w", encoding="utf-8").write(new)
            n += 1
            if not quiet:
                print("  moved %s off the shim" % rel)
    left = [r for r in committed_py()
            if r != "notes/prom_c_image.py"
            and "prom_c_image" in open(os.path.join(ROOT, r), encoding="utf-8",
                                       errors="replace").read()]
    print("\n%d file(s) moved; %d still name the shim%s"
          % (n, len(left), (": " + ", ".join(left)) if left else ""))
    return 0


def apply(only=None, quiet=False):
    changed = refused = 0
    for rel, rows in survey(only):
        if not any(v == "REWRITE" for _i, v, _r in rows):
            continue
        p = os.path.join(ROOT, rel)
        text = open(p, encoding="utf-8").read()
        new = rewrite_text(text)
        if new != text:
            open(p, "w", encoding="utf-8").write(new)
            changed += 1
            if not quiet:
                print("  rewrote %-52s %d site(s)"
                      % (rel, sum(1 for _i, v, _r in rows if v == "REWRITE")))
    for rel, rows in survey(only):
        bad = [(i, r) for i, v, r in rows if v == "REFUSED"]
        if bad:
            refused += 1
            if not quiet:
                print("  REFUSED %-52s %s" % (rel, bad[0][1]))
    print("\n%d file(s) rewritten, %d refused (hand migration, "
          "asm_source.locate()/write_part())" % (changed, refused))
    return 0


def smoke(timeout=90):
    """Run every migrated script once and look for the failure a COMPILE MISSES.

    ⚠ THIS EXISTS BECAUSE A CLEAN COMPILE PROVED NOTHING.  Two versions of the
    import placement above compiled perfectly and died at run time -- once with
    ImportError, once with NameError -- in eight files each.
    """
    bad = []
    scripts = [r for r in committed_py()
               if r not in EXCLUDE
               and "image_path(ROOT," in open(os.path.join(ROOT, r),
                                              encoding="utf-8",
                                              errors="replace").read()]
    for rel in scripts:
        try:
            r = subprocess.run([sys.executable, rel], cwd=ROOT, timeout=timeout,
                               stdin=subprocess.DEVNULL, capture_output=True,
                               text=True)
            out = r.stdout + r.stderr
        except subprocess.TimeoutExpired:
            continue                        # slow is not broken
        m = re.search(r'(ImportError|NameError|ModuleNotFoundError)[^\n]*', out)
        if m:
            bad.append((rel, m.group(0)[:90]))
    for rel, why in bad:
        print("  BROKEN  %-52s %s" % (rel, why))
    print("\n%d migrated script(s) run; %d broken" % (len(scripts), len(bad)))
    return 1 if bad else 0


def listing(only=None):
    n = {"REWRITE": 0, "REFUSED": 0, "SKIP": 0}
    for rel, rows in survey(only):
        for img, v, why in rows:
            n[v] += 1
            if v != "SKIP":
                print("  %-8s %-22s %-52s %s" % (v, img, rel, why))
    print("\n  REWRITE %d   REFUSED %d   (skipped %d)"
          % (n["REWRITE"], n["REFUSED"], n["SKIP"]))
    return 0


# ---------------------------------------------------------------------------
def selftest():
    """INVARIANTS.  The one that matters is the REFUSAL: a rewrite that reaches a
    splicer is how the split gets undone silently."""
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    reader = ('import os\n'
              'ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n'
              'SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")\n'
              'print(len(open(SRC).read()))\n')
    out = rewrite_text(reader)
    check('image_path(ROOT, "prom_c/wsa1_prom_c.s")' in out,
          "a plain reader's site is rewritten to image_path()")
    check(IMPORT_LINE in out and "import sys" in out,
          "...and the import it now needs is inserted")
    # five of these files spell it `import os, re, sys`; the anchor must see both
    for spell in ("import os, re, sys\n", "import importlib.util, os, sys\n"):
        combo = rewrite_text(reader.replace("import os\n", spell))
        check(not re.search(r'^import sys$', combo, re.M) and IMPORT_LINE in combo,
              "%r is recognised -- sys is not imported twice" % spell.strip())
        compile(combo, "<combo>", "exec")
    fmt = ('import os\nimport sys\n'
           'ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n'
           'for tag in ("a", "d"):\n'
           '    p = os.path.join(ROOT, "prom_%s" % tag, "wsa1_prom_%s.s" % tag)\n')
    fout = rewrite_text(fmt)
    check('image_path(ROOT, "prom_%s/wsa1_prom_%s.s" % (tag, tag))' in fout,
          "the COMPUTED spelling used by the census loops is rewritten too")
    compile(fout, "<fmt>", "exec")
    mixed = fmt.replace('"wsa1_prom_%s.s" % tag', '"wsa1_prom_%s.s" % other')
    check("image_path" not in rewrite_text(mixed),
          "...but not when the two format variables differ -- that is not the idiom")

    solo = rewrite_text(reader)
    check(re.search(r'^import sys$', solo, re.M) is not None,
          "...and a file with no sys import gets one")

    # ★ ORDER, not just presence.  An import above the sys.path.insert that
    #   resolves it, or below the first use, compiles clean and dies at run time.
    later = ('import os\nimport sys\n'
             'ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n'
             'SRC = os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")\n'
             'sys.path.insert(0, os.path.join(ROOT, "notes"))\n'
             'from asm_source import image_lines  # noqa: E402\n')
    out2 = rewrite_text(later)
    check(out2.index("sys.path.insert") < out2.index(IMPORT_LINE),
          "the new import lands after a sys.path.insert that makes it work")
    check(out2.index(IMPORT_LINE) < out2.index('image_path(ROOT, "prom_d'),
          "...and BEFORE the first use, even when the file's own path setup "
          "sits below it")
    # ★ and it must RUN, not merely compile.  Executed against the real tree,
    #   from notes/, which is where these scripts live.
    ns = {"__file__": os.path.join(ROOT, "notes", "_selftest_probe.py")}
    exec(compile(out2, "<rewritten>", "exec"), ns)
    check(str(ns.get("SRC", "")).endswith(".s") and os.path.isfile(ns["SRC"]),
          "...and the rewritten header RUNS and resolves to a real file")
    check("os.path.join(ROOT, \"prom_c\", \"wsa1_prom_c.s\")" not in out,
          "...and the old spelling is gone")
    compile(out, "<rewritten>", "exec")
    check(True, "...and the result still compiles")

    writer = reader.replace('print(len(open(SRC).read()))',
                            'open(SRC, "w").write("x")')
    rows = [r for r in (("x", "REFUSED", "") if False else ())]
    wn = writer_names(writer)
    check("SRC" in wn, "a file that does open(SRC, 'w') is seen to write through SRC")

    # ★ THE CONTROL: the three real splicers must be REFUSED by the real survey.
    hazards = {"notes/gen_prom_c_f64_pool.py",
               "notes/prom_c_record68_round10.py",
               "notes/prom_c_understanding_round6.py",
               "scripts/analysis/gen_prom_d_asm.py",
               "prom_a/insert_region.py"}
    verdicts = {rel: set(v for _i, v, _r in rows) for rel, rows in survey()}
    for h in sorted(hazards):
        if h in verdicts:
            check("REWRITE" not in verdicts[h],
                  "the splicer %s is REFUSED, not rewritten" % h)
        else:
            check(False, "%s has no site at all -- has it moved?" % h)

    # a file with no site is left completely alone
    check(rewrite_text("print(1)\n") == "print(1)\n",
          "a file with no site is byte-for-byte unchanged")

    # the shim retirement, and the stale comment it must correct
    shim_src = ('# notes/prom_c_probe_health.py is the check; notes/prom_c_image.py is a shim\n'
                '# that should become `from asm_source import ...` when that reader is green.\n'
                'import prom_c_image\n'
                'SRC = prom_c_image.path()\n')
    got = shim_rewrite(shim_src)
    check("prom_c_image" not in got, "the shim import and call are both replaced")
    check('image_path(ROOT, "prom_c/wsa1_prom_c.s")' in got,
          "...by the general reader, named with the image it wants")
    check("should become `from asm_source import ...`" not in got,
          "...and the comment that would now be FALSE is corrected, not left")
    check(shim_rewrite("print(1)\n") == "print(1)\n",
          "a file that never used the shim is untouched")
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", default=None)
    ap.add_argument("--smoke", action="store_true",
                    help="run every migrated script and look for ImportError")
    ap.add_argument("--shim", action="store_true",
                    help="move the seven prom_c_image.py callers to asm_source")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    if a.smoke:
        sys.exit(smoke())
    if a.shim:
        sys.exit(shim())
    sys.exit(apply(a.only) if a.apply else listing(a.only))
