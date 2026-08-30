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

# `os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")` and the one-string spelling.
SITE = re.compile(
    r'os\.path\.join\(\s*ROOT\s*,\s*"(prom_[abcd])"\s*,\s*"(wsa1_prom_[abcd]\.s)"\s*\)'
    r'|os\.path\.join\(\s*ROOT\s*,\s*"(prom_[abcd])/(wsa1_prom_[abcd]\.s)"\s*\)')

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


def survey(only=None):
    """(path, [(image, verdict, reason), ...]) for every file with a site."""
    out = []
    for rel in committed_py():
        text = open(os.path.join(ROOT, rel), encoding="utf-8",
                    errors="replace").read()
        ms = list(SITE.finditer(text))
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
    if new == text:
        return text
    if IMPORT_LINE not in new:
        ins = ""
        if not SYSPATH_RE.search(new):
            ins += 'sys.path.insert(0, os.path.join(ROOT, "notes"))\n'
        ins += IMPORT_LINE + "  # noqa: E402  (the image, not the master)\n"
        m = ROOT_ASSIGN.search(new)
        if not m:
            raise AssertionError("no `ROOT =` line to anchor the import to")
        at = m.end() + 1
        new = new[:at] + ins + new[at:]
    if not re.search(r'^import sys$|^import sys,', new, re.M):
        m = re.search(r'^import os$', new, re.M)
        if m:
            new = new[:m.end()] + "\nimport sys" + new[m.end():]
        else:
            raise AssertionError("no `import os` to anchor `import sys` to")
    return new


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
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    sys.exit(apply(a.only) if a.apply else listing(a.only))
