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


def image_lines(root, primary, expand=True):
    """The image's lines, newline-stripped, with each .include replaced INLINE
    by the lines of the file it names -- the token stream the assembler sees.

    expand=False returns the primary's own lines only, which is what every
    caller used to get by accident.  It exists so a test can show the two differ.
    """
    files = image_files(root, primary) if expand else [
        os.path.join(root, primary)]
    if not expand:
        return open(files[0], encoding="utf-8").read().split("\n")
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
                out.extend(emit(_resolve(root, m.group(1), path)))
            else:
                out.append(ln)
        return out

    return emit(root_file)


def image_text(root, primary):
    return "\n".join(image_lines(root, primary))


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
