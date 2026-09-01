#!/usr/bin/env python3
"""Read ONE IMAGE's assembly source, following `.include`.

WHAT QUESTION THIS ANSWERS
--------------------------
  "Which lines is this image made of?" -- as opposed to "what is in the file
  that used to be the whole of it".

★ WHY IT EXISTS.  On 2026-08-30 two lanes split their image's single .s into a
primary file plus included parts within the same hour, and every tool that had
opened `prom_X/wsa1_prom_X.s` and scanned it silently began measuring a file
with no payload in it.  The first symptom was not a wrong number, it was an
IndexError: notes/prom_d_documentation_round3.py's census of prom_c's directory
reads went from 99 sites over 33 slots to 0 over 0, and then indexed RAW[0].
Nothing about the ROM had changed.  A tool that wants an image must ask for the
image.

USE
---
    import sys, os
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    from asm_source import image_lines, image_text, image_files

    for ln in image_lines(ROOT, "prom_c/wsa1_prom_c.s"):
        ...

★ AND IF YOU ASK GIT FOR A FILE, ASK THROUGH git_path()/git_show().  os.path
paths in this tree are relative to ROOT; git's `<rev>:<path>` is relative to the
REPOSITORY, and since 2026-09-01 those are not the same directory.  See the
"GIT PATHS ARE REPO-RELATIVE" section below.

RESOLUTION follows what the Makefile passes llvm-mc, which is `-I . -I <image
dir>`: an `.include "x"` is looked up relative to ROOT first and then to the
directory of the file doing the including.  Both spellings in this tree work --
prom_c uses ROOT-relative paths (`prom_c/boot/boot_and_main.s`) and prom_d uses
bare names resolved through `-I prom_d` (`tone_database_aux.s`), mirroring
../kn5000-roms-disasm/table_data/.

⚠ A MISSING INCLUDE RAISES.  Skipping it would return a short listing, which is
precisely the failure this module exists to prevent.

⚠ A `.s` INCLUDED TWICE RAISES TOO: this tree's images are laid out by emission
order, so a repeated content part would mean repeated bytes.  A `.inc` may
legitimately repeat -- include/tlcs900_mem_ops.inc reaches prom_a both directly
and through kernel/kernel.s -- because it defines macros and equates and emits
nothing where it is included.  Such a repeat is EXPANDED ONCE: counting its
lines twice would inflate every census taken over the result.

⚠ IT RETURNS TEXT, NOT BYTES.  Nothing here certifies anything.  The gate is
scripts/analysis/assert_byte_identical.py and it stays the only certificate.

    python3 notes/asm_source.py            # the four images, file by file
    python3 notes/asm_source.py --selftest # the invariants
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

INCLUDE_RE = re.compile(r'^\s*\.include\s+"([^"]+)"')

IMAGES = [
    ("prom_a", "prom_a/wsa1_prom_a.s"),
    ("prom_b", "prom_b/wsa1_prom_b.s"),
    ("prom_c", "prom_c/wsa1_prom_c.s"),
    ("prom_d", "prom_d/wsa1_prom_d.s"),
]


def _resolve(root, spec, including_file):
    """`-I .` then `-I <dir of the includer>`, the two the Makefile passes."""
    for cand in (os.path.join(root, spec),
                 os.path.join(os.path.dirname(including_file), spec)):
        if os.path.isfile(cand):
            return os.path.normpath(cand)
    raise FileNotFoundError(
        "%s: .include %r resolves to nothing (tried ROOT and %s).  Returning a "
        "short listing instead of raising is the bug this module prevents."
        % (os.path.relpath(including_file, root), spec,
           os.path.relpath(os.path.dirname(including_file), root)))


def image_files(root, primary):
    """Every file the image is assembled from, in INCLUDE ORDER (= address order).

    The primary comes first, then each included file at the point its .include
    appears.  Nested includes are followed depth-first, which is what the
    assembler does.
    """
    out = []
    seen = set()

    def walk(path):
        real = os.path.normpath(path)
        if real in seen:
            if real.endswith(".s"):
                raise AssertionError(
                    "%s is included twice; in an image laid out by emission "
                    "order that would duplicate its bytes"
                    % os.path.relpath(real, root))
            return                      # a definitions .inc: expand it once
        seen.add(real)
        out.append(real)
        with open(real, encoding="utf-8") as fh:
            for ln in fh:
                m = INCLUDE_RE.match(ln)
                if m:
                    walk(_resolve(root, m.group(1), real))

    walk(os.path.join(root, primary) if not os.path.isabs(primary) else primary)
    return out


def image_lines(root, primary, expand=True, skip=()):
    """The image's lines, newline-stripped, with each .include replaced INLINE
    by the lines of the file it names -- the token stream the assembler sees.

    expand=False returns the primary's own lines only, which is what every
    caller used to get by accident.  It exists so a test can show the two differ.

    ★ skip = ROOT-relative paths NOT to expand.  A caller that already accounts
    for a shared source separately -- kernel/kernel.s belongs to prom_a AND
    prom_c, and a tree-wide label census that expands both counts it twice --
    names it here.  The `.include` LINE IS KEPT: deleting it would join the
    comment block above it to the label below, which moved two header counts by
    three each the one time it was tried.
    """
    files = image_files(root, primary) if expand else [
        os.path.join(root, primary)]
    if not expand:
        return open(files[0], encoding="utf-8").read().split("\n")
    skip = {os.path.normpath(os.path.join(root, s)) for s in skip}
    text = {p: open(p, encoding="utf-8").read().split("\n") for p in files}
    root_file = files[0]

    done = set()

    def emit(path):
        out = []
        if path in done:
            return out                  # the repeated definitions .inc
        done.add(path)
        for ln in text[path]:
            m = INCLUDE_RE.match(ln)
            if m:
                target = _resolve(root, m.group(1), path)
                if target in skip:
                    out.append(ln)      # keep the directive, drop the content
                else:
                    out.extend(emit(target))
            else:
                out.append(ln)
        return out

    return emit(root_file)


def image_text(root, primary):
    return "\n".join(image_lines(root, primary))


# ---------------------------------------------------------------------------
# A MATERIALISED PATH, for callers whose scan is `open(SRC)`
# ---------------------------------------------------------------------------
# ★ This absorbs notes/prom_c_image.py, the temporary prom_c-only shim written
#   while this module's --selftest was still red.  That file's own docstring said
#   it "should not survive"; what survives it are its two warnings:
#
#   ⚠ IT IS A READ PATH ONLY.  Several probes SPLICE a block back into the
#     primary.  Pointing such a probe's READ here while its WRITE stays on the
#     primary would overwrite a 2,517-line master with the whole 132,304-line
#     image and undo a per-subject split silently -- and the BYTE GATE WOULD
#     STILL PASS, because the bytes are the same.  Writers use locate() and
#     write_part() below, which refuse exactly that.
#
#   ⚠ THE EXPANSION IS DERIVED AND IS NOT COMMITTED.  It is rebuilt whenever any
#     source is newer than it, and written atomically, so two lanes running
#     probes at once cannot read a half-written file.


def image_path(root, primary):
    """A file whose CONTENT is the whole image, so `open(image_path(...))` works.

    Prefer image_lines() / image_text() in new code.  This exists so that an
    existing scan can be migrated by changing ONE line instead of being
    rewritten, which is the difference between converting 30 probes and
    converting three.
    """
    files = image_files(root, primary)
    if len(files) == 1:
        return files[0]                    # not split; nothing to expand
    cache = os.path.join(root, "notes", ".image-" + os.path.basename(primary))
    newest = max([os.path.getmtime(p) for p in files]
                 + [os.path.getmtime(os.path.abspath(__file__))])
    if not os.path.exists(cache) or os.path.getmtime(cache) < newest:
        tmp = "%s.%d" % (cache, os.getpid())
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write(image_text(root, primary))
        os.replace(tmp, cache)             # atomic; concurrent lanes are safe
    return cache


# ---------------------------------------------------------------------------
# THE SAME IMAGE, AT A GIT REVISION
# ---------------------------------------------------------------------------
# ★ THE ONE PLACE A LAYOUT FLIP CANNOT REACH.  Several review probes compare the
# working tree with `git show HEAD:prom_X/wsa1_prom_X.s`.  Since the split IS
# committed, that command returns the 494-line or 2,517-line MASTER while the
# working-tree side, once migrated, returns the whole image -- so the comparison
# has an image on one side and a header on the other and reports thousands of
# added labels that nobody added.  Before the migration BOTH sides were headers,
# which compared nothing with nothing.  Neither is a measurement.
#
#     old = image_text_at_rev(ROOT, "prom_d/wsa1_prom_d.s", "HEAD")
#
# resolves the includes THROUGH GIT, so both sides are the same object.


# ---------------------------------------------------------------------------
# ★★ GIT PATHS ARE REPO-RELATIVE.  os.path PATHS ARE ROOT-RELATIVE.
# ---------------------------------------------------------------------------
# On 2026-09-01 this disassembly moved from the root of its own repository into
# `wsa1/` of the unified tree.  Everything built on os.path survived, because
# ROOT comes from `__file__` and simply became one directory deeper.  ★ THE GIT
# READS DID NOT.  `<rev>:<path>` is resolved from the REPOSITORY ROOT and takes
# no notice of `-C` or `cwd=`, so every `git show HEAD:prom_a/wsa1_prom_a.s` in
# this tree began asking for a path that no longer exists.
#
# Hardcoding "wsa1/" would fix today and break the next move, and it would be
# wrong at the pinned pre-migration revisions, whose trees ARE root-relative.
# So the prefix is asked for, per revision:
#
#     git_path("prom_a/wsa1_prom_a.s")             -> "wsa1/prom_a/wsa1_prom_a.s"
#     git_path("prom_a/wsa1_prom_a.s", "8ff84e5")  -> "prom_a/wsa1_prom_a.s"
#
# ⚠ THE PREFIX IS NOT COSMETIC, IT SELECTS THE FILE.  `notes/`, `scripts/`,
# `notas/`, `original_ROMs/`, `Makefile` and `README.md` all exist BOTH at the
# unified root (the KN5000 disassembly) and under `wsa1/`, and
# `scripts/analysis/assert_byte_identical.py` is a file on both sides.  An
# unprefixed read of that path does not miss -- it silently returns the OTHER
# product's file.  That is why the prefixed spelling is tried FIRST and the bare
# one is only reached when the revision has no such directory at all.
#
# ⚠ NOT A GIT REPOSITORY RAISES.  A caller under `git archive` output, or in a
# scratch tree with no `.git`, gets an exception rather than a bare path that
# would then read whatever the ambient repository happens to hold.

_PREFIX_CACHE = {}


def git_prefix(root=ROOT):
    """Where `root` sits inside its repository: "wsa1/", or "" at the root."""
    key = os.path.realpath(root)
    if key not in _PREFIX_CACHE:
        r = subprocess.run(["git", "-C", root, "rev-parse", "--show-prefix"],
                           capture_output=True, text=True)
        if r.returncode:
            raise FileNotFoundError(
                "%s is not inside a git repository, so no revision can be read "
                "from it (%s)" % (root, r.stderr.strip()))
        _PREFIX_CACHE[key] = r.stdout.strip()
    return _PREFIX_CACHE[key]


def _exists_at(root, rev, path):
    return subprocess.run(["git", "-C", root, "cat-file", "-e",
                           "%s:%s" % (rev, path)],
                          capture_output=True).returncode == 0


def git_path(rel, rev="HEAD", root=ROOT):
    """The REPO-relative path of a ROOT-relative one, as `rev` spells it.

    ⚠ RAISES when the revision holds neither spelling.  A helper that fell back
    to `rel` would hand `git show` a path that resolves to the other product's
    file of the same name, which is worse than the miss it replaced.
    """
    rel = rel.replace(os.sep, "/")
    if rel.startswith("/") or rel.startswith("../"):
        raise ValueError("git_path wants a ROOT-relative path, got %r" % rel)
    prefix = git_prefix(root)
    cands = [prefix + rel, rel] if prefix else [rel]
    for cand in cands:
        if _exists_at(root, rev, cand):
            return cand
    raise FileNotFoundError(
        "%s holds none of %s -- the file is not in that revision under any "
        "spelling this tree has used" % (rev, " or ".join(cands)))


def git_pathspec(rel, rev="HEAD", root=ROOT):
    """The same, as a PATHSPEC for `git diff`/`git show <rev> -- ...`.

    A pathspec is relative to the CURRENT DIRECTORY, not to the repository, so
    it needs the opposite treatment: `:(top)` anchors it at the repository root
    and the path is then spelled as `rev` spells it.
    """
    return ":(top)" + git_path(rel, rev, root)


def git_show(rel, rev="HEAD", root=ROOT):
    """`rev`'s copy of the ROOT-relative file `rel`, as text.  Raises if absent."""
    path = git_path(rel, rev, root)
    r = subprocess.run(["git", "-C", root, "show", "%s:%s" % (rev, path)],
                       capture_output=True)
    if r.returncode:
        raise FileNotFoundError(
            "%s:%s does not exist -- returning a short listing instead of "
            "raising is the bug this module prevents (%s)"
            % (rev, path, r.stderr.decode("utf-8", "replace").strip()))
    return r.stdout.decode("utf-8", "replace")


def git_diff_lines(rel, rev, root=ROOT, context=3, text=None):
    """A unified diff of `rev`'s copy of `rel` against the WORKING TREE copy.

    ★ WHY NOT `git diff <rev> -- <rel>`.  The two sides of this comparison are
    spelled differently once a revision predates the move: the old side holds
    `prom_a/wsa1_prom_a.s` and the new one `wsa1/prom_a/wsa1_prom_a.s`.  One
    pathspec cannot name both, and naming both turns a line diff into one
    deletion plus one addition -- 175,190 lines "added" that nobody added, with
    no error anywhere.  So the old side is fetched by object and the diff is
    computed here.  The output keeps git's `+`/`-`/`@@` shape, which is what the
    callers scan.

    `text` overrides the working-tree side (pass the expanded image).
    """
    import difflib
    old = git_show(rel, rev, root).split("\n")
    if text is None:
        with open(os.path.join(root, rel), encoding="utf-8") as fh:
            text = fh.read()
    new = text.split("\n")
    return list(difflib.unified_diff(old, new, fromfile="a/" + rel,
                                     tofile="b/" + rel, n=context, lineterm=""))


def _git_show(root, rev, rel):
    return git_show(rel, rev, root)


def image_lines_at_rev(root, primary, rev="HEAD"):
    """The image's lines as they stood at `rev`, `.include`s resolved via git.

    Same rules as image_lines(): a missing include RAISES, a content `.s`
    included twice RAISES, a definitions `.inc` is expanded once.
    """
    seen = set()

    def emit(rel):
        if rel in seen:
            if rel.endswith(".s"):
                raise AssertionError(
                    "%s is included twice at %s; in an image laid out by "
                    "emission order that would duplicate its bytes" % (rel, rev))
            return []
        seen.add(rel)
        out = []
        for ln in _git_show(root, rev, rel).split("\n"):
            m = INCLUDE_RE.match(ln)
            if not m:
                out.append(ln)
                continue
            spec = m.group(1)
            here = os.path.normpath(os.path.join(os.path.dirname(rel), spec))
            for cand in (spec, here.replace(os.sep, "/")):
                try:
                    out.extend(emit(cand))
                    break
                except FileNotFoundError:
                    continue
            else:
                raise FileNotFoundError(
                    "%s: .include %r resolves to nothing at %s"
                    % (rel, spec, rev))
        return out

    return emit(primary)


def image_text_at_rev(root, primary, rev="HEAD"):
    return "\n".join(image_lines_at_rev(root, primary, rev))


# ---------------------------------------------------------------------------
# THE WRITE PATH.  ★★ THIS IS THE HALF THAT CAN DESTROY THE TREE
# ---------------------------------------------------------------------------
# A probe that splices generated assembly back into the listing did its
# read-modify-write on `prom_X/wsa1_prom_X.s` when that file WAS the image.  It
# no longer is.  Redirecting only the READ to the expansion above, and leaving
# the WRITE where it was, replaces the master with the entire image; 26 files
# are orphaned, the split is gone, and every gate in this tree stays green.  So
# a writer must write THE FILE THAT OWNS THE TEXT:
#
#     path = locate(ROOT, PRIMARY, "\nDev10C_SetChanReg:\n")
#     text = open(path, encoding="utf-8").read()
#     ...
#     write_part(path, new_text)
#
# SHARED SOURCES ARE OPT-IN.  kernel/kernel.s, dsp/dsp_channel_regs.s and
# maincpu/shared/*.s are included by TWO images, so a prom_c tool that rewrote
# one would silently edit prom_a.  They are excluded unless shared=True is passed.
SHARED_PREFIXES = ("kernel/", "dsp/", "include/", "maincpu/")


def _is_shared(root, path):
    rel = os.path.relpath(path, root).replace(os.sep, "/")
    return rel.startswith(SHARED_PREFIXES)


def image_writable_files(root, primary, shared=False):
    """The image's constituent files that a tool for THIS image may rewrite."""
    return [f for f in image_files(root, primary)
            if shared or not _is_shared(root, f)]


def locate(root, primary, needle, shared=False):
    """The ONE file of the image whose text contains `needle`.

    ⚠ RAISES when the count is not exactly one.  Zero means the anchor is gone
    (or lives in a shared source and shared=False); more than one means the
    anchor does not identify a site.  Both used to be spelled "the regex
    missed", which a caller could read -- and did read -- as "nothing to do".
    """
    hits = [f for f in image_writable_files(root, primary, shared)
            if needle in open(f, encoding="utf-8").read()]
    if len(hits) != 1:
        raise LookupError(
            "%r occurs in %d file(s) of %s%s -- a splice needs exactly one%s"
            % (needle[:60], len(hits), primary,
               "" if shared else " (shared sources excluded)",
               (": " + ", ".join(os.path.relpath(h, root) for h in hits))
               if hits else ""))
    return hits[0]


# A splice that replaces one `.incbin` line with a decoded table is the biggest
# LEGITIMATE growth this tree does: gen_prom_c_f64_pool --apply turns one line
# into about 4,700 in a 12,000-line source.  Writing a whole 132,304-line image
# into a part is not in that league, so the threshold sits between them and the
# opt-out is explicit.
GROWTH_FLOOR = 8192


def edit_image(root, primary, fn, shared=False, allow_growth=False):
    """Apply `fn(text, relpath) -> text` to EVERY writable file of the image.

    ★ THIS IS WHAT A RENAME NEEDS.  A tool that renamed a label by rewriting
    `prom_c/wsa1_prom_c.s` reached the whole image while that file WAS the
    image.  It now reaches 1.9% of it, and would rename a label in the master's
    prose while leaving the definition in prom_c/voice/note_engine.s untouched
    -- a listing that no longer says the same thing in two places, with the byte
    gate green either way.

    Returns the ROOT-relative paths it changed.  Every write goes through
    write_part(), so both of its guards apply per file.
    """
    changed = []
    for f in image_writable_files(root, primary, shared):
        rel = os.path.relpath(f, root).replace(os.sep, "/")
        text = open(f, encoding="utf-8").read()
        new = fn(text, rel)
        if new != text:
            write_part(f, new, root=root, allow_growth=allow_growth)
            changed.append(rel)
    return changed


def write_part(path, text, root=ROOT, allow_growth=False):
    """Write one constituent file back, refusing the accident described above.

    ★ GUARD 1: a file that carries `.include` directives must still carry at
    least as many afterwards.  Overwriting a split master with the expanded
    image drops every one of them at once, which is exactly the mistake this
    refuses, and no legitimate splice removes an include.

    ★ GUARD 2: the file must not EXPLODE.  Guard 1 alone is blind to the other
    half of the same accident -- a part file carries no includes, so writing the
    whole image into one passes guard 1 without a murmur.  A write may add at
    most 4x the file's own lines, or GROWTH_FLOOR, whichever is larger.
    allow_growth=True says the growth is meant, and has to be typed.
    """
    before = open(path, encoding="utf-8").read()
    old, new = before.split("\n"), text.split("\n")
    n_before = sum(1 for l in old if INCLUDE_RE.match(l))
    n_after = sum(1 for l in new if INCLUDE_RE.match(l))
    if n_after < n_before:
        raise AssertionError(
            "%s carries %d .include directive(s); the text about to replace it "
            "carries %d.  Writing it would orphan the included sources and undo "
            "the split -- splice into the file that owns the text (locate())."
            % (os.path.relpath(path, root), n_before, n_after))
    cap = max(4 * len(old), GROWTH_FLOOR)
    if not allow_growth and len(new) - len(old) > cap:
        raise AssertionError(
            "%s has %s lines and the text about to replace it has %s -- +%s, "
            "over the +%s a splice is allowed without saying so.  Writing a whole "
            "image into a part passes the .include guard, so this one exists too; "
            "pass allow_growth=True if the growth is meant."
            % (os.path.relpath(path, root), format(len(old), ","),
               format(len(new), ","), format(len(new) - len(old), ","),
               format(cap, ",")))
    tmp = "%s.tmp%d" % (path, os.getpid())
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(text)
    os.replace(tmp, path)
    return path


# ---------------------------------------------------------------------------
def _selftest():
    """INVARIANTS, not today's numbers.  Every check below is true of any
    correctly resolved image and would fail on a resolver that quietly skipped
    an include or read only the primary."""
    fails = []

    def check(name, cond, detail=""):
        print("  %s  %s%s" % ("PASS" if cond else "FAIL", name,
                              ("   " + detail) if detail and not cond else ""))
        if not cond:
            fails.append(name)

    for tag, primary in IMAGES:
        p = os.path.join(ROOT, primary)
        if not os.path.isfile(p):
            check("%-7s primary exists" % tag, False, primary)
            continue
        files = image_files(ROOT, primary)
        lines = image_lines(ROOT, primary)
        own = image_lines(ROOT, primary, expand=False)
        check("%-7s every resolved file exists" % tag,
              all(os.path.isfile(f) for f in files))
        check("%-7s no file resolved twice" % tag, len(set(files)) == len(files))
        check("%-7s every CONTENT part is a .s and appears once" % tag,
              len({f for f in files if f.endswith(".s")})
              == len([f for f in files if f.endswith(".s")]))
        check("%-7s the primary is first" % tag,
              os.path.normpath(files[0]) == os.path.normpath(p))
        check("%-7s expansion is a superset of the primary's own lines" % tag,
              len(lines) >= len(own) - files.__len__())
        n_inc = sum(1 for ln in lines if INCLUDE_RE.match(ln))
        check("%-7s no .include survives expansion" % tag, n_inc == 0,
              "%d left" % n_inc)
        if len(files) > 1:
            check("%-7s an image WITH includes expands to more lines than its "
                  "primary alone" % tag, len(lines) > len(own),
                  "%d vs %d" % (len(lines), len(own)))
        print("     %-7s %d file(s), %s line(s)" % (tag, len(files),
                                                    format(len(lines), ",")))

    # ★ THE REPEAT RULE, both directions: a .s repeated must RAISE, a .inc must not.
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        open(os.path.join(td, "part.s"), "w").write("; part\n")
        open(os.path.join(td, "defs.inc"), "w").write("; defs\n")
        open(os.path.join(td, "dup_s.s"), "w").write(
            '\t.include "part.s"\n\t.include "part.s"\n')
        open(os.path.join(td, "dup_inc.s"), "w").write(
            '\t.include "defs.inc"\n\t.include "defs.inc"\n')
        raised = False
        try:
            image_files(td, os.path.join(td, "dup_s.s"))
        except AssertionError:
            raised = True
        check("a CONTENT part included twice RAISES", raised)
        n = len(image_lines(td, os.path.join(td, "dup_inc.s")))
        check("a definitions .inc included twice is expanded ONCE",
              image_files(td, os.path.join(td, "dup_inc.s")).__len__() == 2
              and n == 3, "%d file(s), %d line(s)"
              % (len(image_files(td, os.path.join(td, "dup_inc.s"))), n))

    # a resolver that cannot fail is not a resolver
    try:
        _resolve(ROOT, "no/such/file.s", os.path.join(ROOT, "notes", "x.s"))
        check("a missing include RAISES", False)
    except FileNotFoundError:
        check("a missing include RAISES", True)

    # ---- the materialised read path -------------------------------------
    for tag, primary in IMAGES:
        if not os.path.isfile(os.path.join(ROOT, primary)):
            continue
        pth = image_path(ROOT, primary)
        check("%-7s image_path() holds exactly image_text()" % tag,
              open(pth, encoding="utf-8").read() == image_text(ROOT, primary))
        if len(image_files(ROOT, primary)) > 1:
            check("%-7s image_path() does NOT hand back the primary while the "
                  "image is split" % tag,
                  os.path.realpath(pth) != os.path.realpath(
                      os.path.join(ROOT, primary)))

    # ---- skip: a shared source a caller accounts for separately ----------
    for tag, primary in IMAGES:
        if not os.path.isfile(os.path.join(ROOT, primary)):
            continue
        full = image_lines(ROOT, primary)
        cut = image_lines(ROOT, primary, skip=("kernel/kernel.s",))
        if any(f.endswith("kernel/kernel.s") for f in image_files(ROOT, primary)):
            check("%-7s skip= removes the shared kernel's lines" % tag,
                  len(cut) < len(full))
            check("%-7s ...and KEEPS the .include directive that named it" % tag,
                  sum(1 for l in cut if INCLUDE_RE.match(l)
                      and "kernel/kernel.s" in l) == 1)
        else:
            check("%-7s skip= of a source this image does not include is a "
                  "no-op" % tag, cut == full)

    # ---- the same image, at a git revision -------------------------------
    for tag, primary in IMAGES:
        if not os.path.isfile(os.path.join(ROOT, primary)):
            continue
        at = image_lines_at_rev(ROOT, primary, "HEAD")
        check("%-7s no .include survives the git-side expansion either" % tag,
              not any(INCLUDE_RE.match(l) for l in at))
        check("%-7s the git side is an IMAGE, not the master alone" % tag,
              len(at) >= len(image_lines(ROOT, primary, expand=False)))
    try:
        image_lines_at_rev(ROOT, "prom_c/no_such_file.s", "HEAD")
        check("a missing file at a revision RAISES", False)
    except FileNotFoundError:
        check("a missing file at a revision RAISES", True)

    # ---- git_path: the repo-relative spelling, per revision ---------------
    prefix = git_prefix(ROOT)
    check("git_prefix is empty or ends in a slash",
          prefix == "" or prefix.endswith("/"), repr(prefix))
    top = subprocess.run(["git", "-C", ROOT, "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True).stdout.strip()
    check("ROOT is exactly <toplevel>/<prefix>",
          os.path.realpath(os.path.join(top, prefix)) == os.path.realpath(ROOT),
          "%s + %r" % (top, prefix))
    for tag, primary in IMAGES:
        if not os.path.isfile(os.path.join(ROOT, primary)):
            continue
        gp = git_path(primary)
        check("%-7s git_path() names a path HEAD actually holds" % tag,
              _exists_at(ROOT, "HEAD", gp), gp)
        check("%-7s git_path() = prefix + the ROOT-relative path" % tag,
              gp == prefix + primary, "%s vs %s" % (gp, prefix + primary))
        check("%-7s git_show() returns the committed file, byte for byte" % tag,
              git_show(primary) == open(os.path.join(ROOT, primary),
                                        encoding="utf-8").read())
    # ★ THE CONTROL.  With a non-empty prefix the BARE spelling is the bug, so
    #   the bug must be visible from here: git must refuse it (or, worse, hand
    #   back the other product's file).  Where the prefix is empty there is no
    #   bug to see and the check says so rather than passing quietly.
    if prefix:
        bare_wrong = 0
        for tag, primary in IMAGES:
            if not os.path.isfile(os.path.join(ROOT, primary)):
                continue
            # ⚠ GIT_AUDIT_EXPECT_FAIL marks this as a NEGATIVE control for
            #   notes/git_path_audit.py.  Without it the auditor counts the four
            #   deliberate misses this check needs as four broken reads, in every
            #   scratch tree probe_health builds -- 16 phantom faults attributed
            #   to the file that proves the bug is fixed.
            r = subprocess.run(["git", "-C", ROOT, "show", "HEAD:" + primary],
                               capture_output=True,
                               env=dict(os.environ, GIT_AUDIT_EXPECT_FAIL="1"))
            if r.returncode or r.stdout.decode("utf-8", "replace") != git_show(primary):
                bare_wrong += 1
        check("the UNPREFIXED spelling is wrong for every image -- the bug this "
              "helper exists for is reproducible from here", bare_wrong == 4,
              "%d of 4" % bare_wrong)
    else:
        check("(prefix is empty: ROOT is the repository root, nothing to prefix)",
              True)
    try:
        git_path("prom_a/no_such_file_anywhere.s")
        check("git_path RAISES on a path no spelling reaches", False)
    except FileNotFoundError:
        check("git_path RAISES on a path no spelling reaches", True)
    try:
        git_path("/absolute/path.s")
        check("git_path REFUSES an absolute path", False)
    except ValueError:
        check("git_path REFUSES an absolute path", True)
    check("git_pathspec anchors at the repository root",
          git_pathspec(IMAGES[0][1]).startswith(":(top)"))
    with tempfile.TemporaryDirectory() as td:
        try:
            git_prefix(td)
            check("git_prefix RAISES outside a repository", False)
        except FileNotFoundError:
            check("git_prefix RAISES outside a repository", True)

    # ---- git_diff_lines: a mutation control -------------------------------
    primary = IMAGES[0][1]
    if os.path.isfile(os.path.join(ROOT, primary)):
        same = git_diff_lines(primary, "HEAD",
                              text=git_show(primary))
        check("git_diff_lines is EMPTY when the two sides agree",
              same == [], "%d line(s)" % len(same))
        mutated = git_show(primary).replace("\n", "\n", 1) + "\n; injected\n"
        diff = git_diff_lines(primary, "HEAD", text=mutated)
        check("...and reports the ONE line a mutation adds",
              [l for l in diff if l.startswith("+; injected")] != [],
              "%d line(s)" % len(diff))

    # ---- the write path, and the accident it exists to refuse ------------
    with tempfile.TemporaryDirectory() as td:
        os.makedirs(os.path.join(td, "img"))
        os.makedirs(os.path.join(td, "kernel"))
        open(os.path.join(td, "img", "one.s"), "w").write("; part\nAnchor:\n")
        open(os.path.join(td, "img", "two.s"), "w").write("; other\nBoth:\n")
        open(os.path.join(td, "img", "three.s"), "w").write("; more\nBoth:\n")
        open(os.path.join(td, "kernel", "kernel.s"), "w").write("Shared:\n")
        master = os.path.join(td, "img", "main.s")
        open(master, "w").write(
            '; master prose\n'
            '\t.include "img/one.s"\n\t.include "img/two.s"\n'
            '\t.include "img/three.s"\n\t.include "kernel/kernel.s"\n')
        prim = "img/main.s"
        check("locate() finds THE file that owns an anchor",
              os.path.basename(locate(td, prim, "Anchor:")) == "one.s")
        for needle, why in (("Nowhere:", "an anchor that is gone"),
                            ("Both:", "an anchor in two files")):
            try:
                locate(td, prim, needle)
                check("locate() RAISES on %s" % why, False)
            except LookupError:
                check("locate() RAISES on %s" % why, True)
        try:
            locate(td, prim, "Shared:")
            check("locate() will not hand a tool a SHARED source by default", False)
        except LookupError:
            check("locate() will not hand a tool a SHARED source by default", True)
        check("...but shared=True opts in",
              os.path.basename(locate(td, prim, "Shared:", shared=True)) == "kernel.s")
        # ★ THE GUARD.  Splicing the expanded image over the master is the one
        #   mistake that leaves every gate in this tree green.
        try:
            write_part(master, image_text(td, prim), root=td)
            check("write_part() REFUSES to overwrite a master with its own "
                  "expansion", False)
        except AssertionError:
            check("write_part() REFUSES to overwrite a master with its own "
                  "expansion", True)
        part = os.path.join(td, "img", "one.s")
        write_part(part, "; part\nAnchor:\n; spliced\n", root=td)
        check("write_part() DOES write a part that carries no includes",
              "spliced" in open(part).read())
        # edit_image reaches every part, which is what a rename needs
        # ⚠ check() here is check(NAME, COND) -- the first version of these three
        #   passed them the other way round, so the CONDITION became the label
        #   and the non-empty label became the condition.  All three printed
        #   PASS unconditionally.  A vacuous check, in the module written to
        #   stop vacuous checks.
        n = edit_image(td, prim, lambda t, rel: t.replace("Anchor:", "Renamed:"))
        check("edit_image touches exactly the file that held the token",
              n == ["img/one.s"], "%s" % n)
        n = edit_image(td, prim, lambda t, rel: t.replace("; ", ";; "))
        check("...and a tree-wide edit reaches EVERY writable part, master included",
              set(n) == {"img/main.s", "img/one.s", "img/two.s", "img/three.s"},
              "%s" % sorted(n))
        check("...but never a shared source unless shared=True",
              "kernel/kernel.s" not in n)
        # ★ GUARD 2, both directions.  A part has no includes, so guard 1 is
        #   blind to the whole image being written INTO one.
        try:
            write_part(part, "\n".join(["x"] * 60000), root=td)
            check("write_part() REFUSES to explode a part into an image-sized "
                  "file", False)
        except AssertionError:
            check("write_part() REFUSES to explode a part into an image-sized "
                  "file", True)
        write_part(part, "\n".join(["y"] * 60000), root=td, allow_growth=True)
        check("...unless allow_growth=True is typed",
              len(open(part).read().split("\n")) == 60000)

    print("\nFAILURES: %d" % len(fails))
    return 1 if fails else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(_selftest())
    for tag, primary in IMAGES:
        if not os.path.isfile(os.path.join(ROOT, primary)):
            print("%-7s %s  MISSING" % (tag, primary))
            continue
        files = image_files(ROOT, primary)
        print("%-7s %s  ->  %d file(s), %s line(s)"
              % (tag, primary, len(files),
                 format(len(image_lines(ROOT, primary)), ",")))
        for f in files:
            print("          %s" % os.path.relpath(f, ROOT))
