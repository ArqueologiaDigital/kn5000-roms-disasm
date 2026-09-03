#!/usr/bin/env python3
"""Make generated cross-reference COMMENTS spell the labels the code now uses.

QUESTION THIS ANSWERS
    A semantic-labelling pass renames `sub_F9ADB5` to `P7Block_Run`. The code
    is updated everywhere, because the assembler would fail otherwise. But the
    tree's GENERATED comments -- `Calls:`, `Called from:`, `Arms:`, and the
    banner headers -- still say `sub_F9ADB5`, and nothing forces them to agree.
    A reader then sees a routine named one thing and cross-referenced as
    another, which is worse than either name alone.

WHY IT IS A SEPARATE TOOL
    `scripts/analysis/assert_comments_preserved.py` forbids altering an
    existing comment, because this tree's prose is the deliverable and the byte
    gate cannot see a comment that was lost. That rule is right, and it means a
    rename cannot fix its own cross-references. So the fix is mechanical,
    auditable, and narrow: substitute ONLY whole-word label names that this
    pass actually renamed, ONLY inside comment text, and never a word of prose.

    Verify the result with the matching narrow exemption:
        python3 scripts/analysis/assert_comments_preserved.py \
            --base <rev> --rename-map <map> <paths>
    which accepts a base comment that becomes the new one under these
    substitutions and NOTHING else -- a reword still fails.

HOW THE MAP IS DERIVED
    Label definitions are compared between <rev> and the working tree, aligned
    by position. A file whose label COUNT changed is skipped and reported,
    because positional alignment is only sound when nothing was added or
    removed. Only `sub_*` -> non-`sub_*` renames are taken.

    ⚠ Longest name first when substituting: `sub_F9ADB5` is a prefix of
    `sub_F9ADB5__F9AE48`, and the short match would corrupt the long one.

RUN
    python3 scripts/converters/sync_comments_to_renamed_labels.py --base <rev> --dry-run <paths>
    python3 scripts/converters/sync_comments_to_renamed_labels.py --base <rev> --apply <paths>
    python3 scripts/converters/sync_comments_to_renamed_labels.py --selftest
"""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LABEL = re.compile(r'^([A-Za-z_.$][\w.$]*):')


def derive_map(rev, paths):
    renames, skipped = {}, []
    for f in paths:
        rel = pathlib.Path(f).resolve().relative_to(ROOT)
        p = subprocess.run(["git", "show", f"{rev}:{rel}"], cwd=ROOT,
                           capture_output=True)
        if p.returncode:
            continue
        old = p.stdout.decode("latin-1").split("\n")
        new = pathlib.Path(f).read_text(encoding="latin-1").split("\n")
        o = [m.group(1) for l in old if (m := LABEL.match(l))]
        n = [m.group(1) for l in new if (m := LABEL.match(l))]
        if len(o) != len(n):
            skipped.append((f, len(o), len(n)))
            continue
        for a, b in zip(o, n):
            if a != b and a.startswith("sub_") and not b.startswith("sub_"):
                renames[a] = b
    return renames, skipped


def substitute_comments(text, renames):
    """Rewrite label names inside comment text only. Returns (text, n_changed)."""
    if not renames:
        return text, 0
    pat = re.compile(r"\b(" + "|".join(
        re.escape(k) for k in sorted(renames, key=len, reverse=True)) + r")\b")
    out, changed = [], 0
    for line in text.split("\n"):
        # find the comment start, respecting string literals
        in_str, cut = False, None
        for i, ch in enumerate(line):
            if ch == '"':
                in_str = not in_str
            elif ch == ";" and not in_str:
                cut = i
                break
        if cut is None:
            out.append(line)
            continue
        code, comment = line[:cut], line[cut:]
        new_comment, n = pat.subn(lambda m: renames[m.group(1)], comment)
        if n:
            changed += 1
        out.append(code + new_comment)
    return "\n".join(out), changed


def selftest():
    ren = {"sub_AA": "Voice_Alloc", "sub_AA__BB": "Voice_Alloc__BB"}
    cases = [
        ("a cross-reference comment is updated",
         "\tcall\tVoice_Alloc\t; Calls: sub_AA\n",
         "\tcall\tVoice_Alloc\t; Calls: Voice_Alloc\n"),
        ("★ CODE IS NEVER TOUCHED, only the comment",
         "sub_AA:\t; defines sub_AA\n",
         "sub_AA:\t; defines Voice_Alloc\n"),
        ("★ longest name first: the prefix does not corrupt the longer label",
         "\tnop\t; see sub_AA__BB and sub_AA\n",
         "\tnop\t; see Voice_Alloc__BB and Voice_Alloc\n"),
        ("a name inside a longer word is not touched",
         "\tnop\t; xsub_AAy stays\n",
         "\tnop\t; xsub_AAy stays\n"),
        ("a `;` inside a string is not a comment",
         '\t.ascii\t"a; sub_AA"\n',
         '\t.ascii\t"a; sub_AA"\n'),
    ]
    ok = True
    print("  --selftest")
    for name, src, want in cases:
        got, _ = substitute_comments(src, ren)
        good = got == want
        ok &= good
        print(f"    {name:<62} {'ok' if good else 'WRONG'}")
        if not good:
            print(f"        want {want!r}\n        got  {got!r}")
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--write-map", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    if a.selftest:
        return 0 if selftest() else 1
    if not a.paths:
        ap.error("give at least one path, or --selftest")

    renames, skipped = derive_map(a.base, a.paths)
    print(f"  {len(renames)} label(s) renamed since {a.base}")
    for f, no, nn in skipped:
        print(f"  ⚠ SKIPPED {f}: label count {no} -> {nn}, "
              f"positional alignment unsound")

    if a.write_map:
        pathlib.Path(a.write_map).write_text(
            "\n".join(f"{k}={v}" for k, v in sorted(renames.items())))
        print(f"  map written to {a.write_map}")

    total = 0
    for f in a.paths:
        text = pathlib.Path(f).read_text(encoding="latin-1")
        new, n = substitute_comments(text, renames)
        if n:
            print(f"  {pathlib.Path(f).name:<40} {n:>5} comment(s)")
            total += n
            if a.apply:
                pathlib.Path(f).write_text(new, encoding="latin-1")
    print(f"\n  {total} comment(s) {'updated' if a.apply else 'would change'}")
    if not a.apply and not a.dry_run:
        print("  (nothing written -- pass --apply)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
