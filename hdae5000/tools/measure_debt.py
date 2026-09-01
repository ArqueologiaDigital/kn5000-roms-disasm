#!/usr/bin/env python3
"""measure_debt.py -- how many of the HD-AE5000's 524,288 bytes are NOT reproduced by real source?

QUESTION ANSWERED: for the single hdae5000 image, built from hd-ae5000_v2_06i.s and everything it
.includes, how many bytes come back through `.incbin` of a blob with no honest rebuild rule, and
how many sit as un-decoded `.byte`/`.word` runs -- as opposed to real instructions, `.asciz`/`.zero`
typed data, or bytes that ARE individually decoded/typed (an inline comment says what the byte
means) even though they are written with a raw directive because the pinned LLVM tlcs900 backend
will not accept the mnemonic form, or because the byte is one character of an extended-ASCII
string.

WHY A SEPARATE SCRIPT, NOT scripts/analysis/kn5000_source_coverage.py
    That shared script is being fixed by a different lane in this same push (it currently reports
    an impossible 626,152 verbatim bytes against this ROM's 524,288, because its regex matches
    `.incbin` inside "; Was: .incbin ..." RETRACTION COMMENTS as if they were live directives --
    every one of the 10 real image incbins in this tree carries exactly one such comment, so each
    is double-counted with a stale offset/length). Editing that file would collide with that lane's
    work, so this tree gets its own instrument instead, scoped to one ROM, with its own bug budget.

WHAT COUNTS AS DEBT (per notes/lanes/BRIEF-2026-09-01.md)
    * `.incbin` of a blob that has no committed, verified rebuild rule.                    DEBT
    * `.incbin` of `includes/generated/*.bin` -- these do not exist in git; they are built at
      compile time by `python3 scripts/build/hdae5000_images.py build` FROM committed PNGs and
      palette .txt files, and `... verify` asserts the round trip is byte-exact.               HONEST
    * a `.byte`/`.word` line with NO trailing comment -- nothing on record says what it is.     DEBT
    * a `.byte`/`.word` line WITH a trailing comment (a decoded mnemonic, a character, "padding",
      an offset note, etc.) -- decoded/typed, just not expressed as a mnemonic or a `.asciz`/
      `.zero` directive.                                                            DOCUMENTED, not counted
      in the headline number, but reported on its own line because it is not clean source either.
    * real TLCS900 instructions, `.asciz`/`.zero`/`.set` directives, labels                    SOURCE

There is no clang-compiled C in this image (HDAE_SRC in the Makefile is `.s` files only, no
`.c` -- unlike maincpu's ui_widgets tables) so that carve-out from the brief does not apply here.

RUN (from the hdae5000 lane worktree root):
    python3 hdae5000/tools/measure_debt.py
    python3 hdae5000/tools/measure_debt.py --list-debt      # also print every debt line found
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HDAE_DIR = os.path.join(ROOT, "hdae5000")
ROOT_SRC = os.path.join(HDAE_DIR, "hd-ae5000_v2_06i.s")
ROM_SIZE = 524288

INCLUDE_RE = re.compile(r'^\s*\.include\s+"([^"]+)"')
INCBIN_RE = re.compile(r'^\s*(?:\S+\s*:\s*)?\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')
BYTE_RE = re.compile(r'^\s*(?:\S+\s*:\s*)?\.byte\b(.*)$', re.IGNORECASE)
WORD_RE = re.compile(r'^\s*(?:\S+\s*:\s*)?\.word\b(.*)$', re.IGNORECASE)


def strip_comment(line):
    """Return (code_part, comment_part). ';' inside a "..." string does not count."""
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == ';' and not in_str:
            return line[:i], line[i + 1:].strip()
    return line, ""


def count_operands(rest):
    """Count comma-separated operands in the tail of a .byte/.word line (post-comment-strip)."""
    rest = rest.strip()
    if not rest:
        return 0
    return len([p for p in rest.split(",") if p.strip() != ""])


def resolve_incbin(from_file, path):
    candidates = [
        os.path.join(os.path.dirname(from_file), path),
        os.path.join(HDAE_DIR, path),
        path,
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return None


def walk(path, seen, out):
    path = os.path.abspath(path)
    if path in seen:
        return
    seen.add(path)
    with open(path, encoding="latin-1") as f:
        lines = f.readlines()

    for line in lines:
        code, comment = strip_comment(line)

        m = INCLUDE_RE.match(code)
        if m:
            inc_path = m.group(1)
            candidates = [os.path.join(os.path.dirname(path), inc_path),
                          os.path.join(HDAE_DIR, inc_path)]
            for c in candidates:
                if os.path.exists(c):
                    walk(c, seen, out)
                    break
            continue

        m = INCBIN_RE.match(code)
        if m:
            inc_path, off, ln = m.groups()
            real = resolve_incbin(path, inc_path)
            if real is None:
                out["incbin_unresolved"].append((path, inc_path))
                continue
            fsz = os.path.getsize(real)
            size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
            honest = "includes/generated/" in inc_path.replace("\\", "/")
            bucket = "incbin_honest" if honest else "incbin_raw"
            out[bucket] += size
            out[bucket + "_lines"].append((path, inc_path, size))
            continue

        m = BYTE_RE.match(code)
        if m:
            n = count_operands(m.group(1))
            if n == 0:
                continue
            if comment:
                out["byte_documented"] += n
            else:
                out["byte_bare"] += n
                out["byte_bare_lines"].append((path, line.rstrip("\n")))
            continue

        m = WORD_RE.match(code)
        if m:
            n = count_operands(m.group(1)) * 2
            if n == 0:
                continue
            if comment:
                out["word_documented"] += n
            else:
                out["word_bare"] += n
                out["word_bare_lines"].append((path, line.rstrip("\n")))
            continue


def main():
    out = {
        "incbin_honest": 0, "incbin_honest_lines": [],
        "incbin_raw": 0, "incbin_raw_lines": [],
        "incbin_unresolved": [],
        "byte_documented": 0,
        "byte_bare": 0, "byte_bare_lines": [],
        "word_documented": 0,
        "word_bare": 0, "word_bare_lines": [],
    }
    seen = set()
    walk(ROOT_SRC, seen, out)

    files = sorted(os.path.relpath(p, ROOT) for p in seen)
    print(f"hdae5000 image: {ROM_SIZE:,} bytes, root {os.path.relpath(ROOT_SRC, ROOT)}")
    print(f"{len(files)} source files walked via .include:")
    for f in files:
        print(f"  {f}")
    print()
    print(f"incbin, honest (generated/ from committed PNG+palette, round-trip verified): "
          f"{out['incbin_honest']:,} B")
    print(f"incbin, raw (no rebuild rule -- DEBT):                                       "
          f"{out['incbin_raw']:,} B")
    if out["incbin_raw_lines"]:
        for p, ip, sz in out["incbin_raw_lines"]:
            print(f"    {os.path.relpath(p, ROOT)}: {ip} ({sz:,} B)")
    if out["incbin_unresolved"]:
        print(f"  ! {len(out['incbin_unresolved'])} .incbin path(s) could not be resolved on disk:")
        for p, ip in out["incbin_unresolved"]:
            print(f"    {os.path.relpath(p, ROOT)}: {ip}")
    print()
    print(f".byte operand bytes, undocumented (no trailing comment -- DEBT):             "
          f"{out['byte_bare']:,} B")
    print(f".byte operand bytes, documented (decoded/typed via a trailing comment):      "
          f"{out['byte_documented']:,} B")
    print(f".word operand bytes, undocumented (no trailing comment -- DEBT):             "
          f"{out['word_bare']:,} B")
    print(f".word operand bytes, documented (decoded/typed via a trailing comment):      "
          f"{out['word_documented']:,} B")
    print()
    debt = out["incbin_raw"] + out["byte_bare"] + out["word_bare"]
    documented_raw = out["byte_documented"] + out["word_documented"]
    print(f"HEADLINE DEBT (raw incbin + undocumented .byte/.word):  {debt:,} B "
          f"({100 * debt / ROM_SIZE:.3f}% of the ROM)")
    print(f"  + {documented_raw:,} B more sit as documented-but-untyped .byte/.word "
          f"(decoded, not debt by the brief's wording, but not clean source either)")
    print(f"real source (assembly + .asciz/.zero + honest-generated incbin): "
          f"{ROM_SIZE - debt - documented_raw:,} B "
          f"({100 * (ROM_SIZE - debt - documented_raw) / ROM_SIZE:.3f}%)")

    if "--list-debt" in sys.argv:
        print("\n--- undocumented .byte lines ---")
        for p, line in out["byte_bare_lines"]:
            print(f"{os.path.relpath(p, ROOT)}: {line}")
        print("\n--- undocumented .word lines ---")
        for p, line in out["word_bare_lines"]:
            print(f"{os.path.relpath(p, ROOT)}: {line}")


if __name__ == "__main__":
    main()
