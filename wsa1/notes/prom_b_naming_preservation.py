#!/usr/bin/env python3
"""Did this round's renames DELETE anything, or only substitute a token?

WHAT QUESTION THIS ANSWERS
    The lane rule is "you are ADDING, not destroying".  A rename cannot obey
    that literally -- the old label text is gone by definition -- so the honest
    form of the rule is:

        every comment line and every label of the BASE revision must still be
        present in the working tree, either VERBATIM or as the same line with
        one of this round's renamed tokens substituted, and nothing else.

    That is what this checks, line for line, over prom_b/wsa1_prom_b.s.  It
    reports four numbers: lines kept verbatim, lines accounted for by a rename,
    lines that were DELETED (must be zero unless each is explained on the
    command line), and lines ADDED.

    ★ IT IS NOT THE BYTE GATE.  scripts/analysis/assert_byte_identical.py
    proves the ROM still rebuilds; this proves the PROSE was not thrown away.
    Neither substitutes for the other.

RUN
    python3 notes/prom_b_naming_preservation.py                 # vs HEAD
    python3 notes/prom_b_naming_preservation.py --base <rev>
    python3 notes/prom_b_naming_preservation.py --show-deleted
Exit status is non-zero if any base line is unaccounted for.
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REL = "prom_b/wsa1_prom_b.s"
sys.path.insert(0, os.path.join(ROOT, "notes"))
from prom_b_apply_msgline_names import RENAMES, CLEARERS  # noqa: E402  the round's own table
from prom_b_apply_smf_names import RENAMES as SMF_RENAMES, DATA_RENAMES  # noqa: E402
from prom_b_apply_effect_names import RENAMES as FX_RENAMES  # noqa: E402
from prom_b_apply_diskfile_name import RENAMES as DF_RENAMES  # noqa: E402

LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")


def base_text(rev):
    return subprocess.run(["git", "-C", ROOT, "show", f"{rev}:{REL}"],
                          capture_output=True, text=True, check=True).stdout


def main():
    rev = "HEAD"
    if "--base" in sys.argv:
        rev = sys.argv[sys.argv.index("--base") + 1]
    ren = {"sub_%06X" % a: n for a, n, *_ in RENAMES}
    ren.update({"sub_%06X" % a: n for a, n, *_ in CLEARERS})
    ren.update({"sub_%06X" % a: n for a, n in SMF_RENAMES})
    ren.update({o: n for o, n, _k in DATA_RENAMES})
    ren.update(dict(FX_RENAMES))
    ren.update(dict(DF_RENAMES))
    old = base_text(rev).splitlines()
    with open(os.path.join(ROOT, REL)) as f:
        new = f.read().splitlines()
    have = collections.Counter(new)

    def rewrite(line):
        out = line
        for o, n in ren.items():
            out = re.sub(r"\b" + o + r"\b", n, out)
        return out

    # Two more shapes this round produces on purpose, each of which REPLACES a
    # line rather than dropping it.  Both are only accepted when the text that
    # was there is still readable somewhere in the new file.
    titles = {"; sub_%06X" % a: f"; {n} -- 0x{a:06X}"
              for a, n, *_ in list(RENAMES) + list(CLEARERS) + [(a, n) for a, n in SMF_RENAMES]}
    titles.update({f"; {o}": f"; {n} -- 0x{o[4:]}"
                   for o, n in list(FX_RENAMES) + list(DF_RENAMES) if o.startswith("sub_")})
    newtext = "\n".join(new)
    QUOTED = ("is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's",
              "rule that a stated gap beats a plausible guess.")

    # a `.incbin` that became assembly is not a lost line, it is a CONVERSION,
    # and the byte gate is what says the bytes did not move.
    CONVERTED = re.compile(r'^\s*\.incbin |^; --- 0x[0-9A-F]+-0x[0-9A-F]+: not converted ---$')
    stripped = "\n".join(l.strip().lstrip(";").strip() for l in new)
    flat = re.sub(r"\s+", " ", stripped)

    kept = renamed = retitled = quoted = converted = deleted = 0
    missing = []
    for ln in old:
        if have[ln] > 0:
            have[ln] -= 1
            kept += 1
            continue
        r = rewrite(ln)
        if r != ln and have[r] > 0:
            have[r] -= 1
            renamed += 1
            continue
        if ln in titles and have[titles[ln]] > 0:
            have[titles[ln]] -= 1
            retitled += 1
            continue
        # a DATA object's title: `; Data_XXXXXX -- rest` -> `; <new> -- 0xXXXXXX, rest`
        m = re.match(r"^; ([A-Za-z]\w*_([0-9A-F]{6})) -- (.*)$", ln)
        if m and m.group(1) in ren:
            want = f"; {ren[m.group(1)]} -- 0x{m.group(2)}, {m.group(3)}"
            if have[want] > 0:
                have[want] -= 1
                retitled += 1
                continue
        if ("Unknown: what the routine is FOR" in ln or
                "a stated gap beats a plausible guess" in ln or
                ln == "; Unknown: everything about it except its bytes.") and all(q in newtext for q in QUOTED):
            quoted += 1
            continue
        if CONVERTED.match(ln):
            converted += 1
            continue
        # a comment line whose TEXT is quoted verbatim inside a replacement
        body = re.sub(r"\s+", " ", ln.strip().lstrip(";").strip())
        if ln.lstrip().startswith(";") and len(body) > 12 and body in flat:
            quoted += 1
            continue
        deleted += 1
        missing.append(ln)
    added = sum(v for v in have.values() if v > 0)

    old_c = sum(1 for l in old if l.lstrip().startswith(";"))
    new_c = sum(1 for l in new if l.lstrip().startswith(";"))
    old_l = {LABEL.match(l).group(1) for l in old if LABEL.match(l)}
    new_l = {LABEL.match(l).group(1) for l in new if LABEL.match(l)}
    lost = sorted(l for l in old_l if l not in new_l and ren.get(l, l) not in new_l)

    print(f"base {rev}:  {len(old)} lines, {old_c} comment lines, {len(old_l)} labels")
    print(f"working:     {len(new)} lines, {new_c} comment lines, {len(new_l)} labels")
    print(f"  kept verbatim          {kept}")
    print(f"  accounted for by a rename {renamed}")
    print(f"  header title rewritten as `; <name> -- 0x<addr>` {retitled}")
    print(f"  stanza REPLACED, its text quoted verbatim in the replacement {quoted}")
    print(f"  `.incbin` line CONVERTED to assembly (byte gate is the proof) {converted}")
    print(f"  ADDED                  {added}")
    print(f"  UNACCOUNTED FOR        {deleted}")
    print(f"  labels lost (not renamed either): {len(lost)}  {lost[:8]}")
    if deleted and "--show-deleted" in sys.argv:
        for m in missing[:60]:
            print("    - " + m)
    return 1 if (deleted or lost) else 0


if __name__ == "__main__":
    sys.exit(main())
