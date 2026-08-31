#!/usr/bin/env python3
"""Which prom_b semantic labels are NOT backed by an Evidence line?

QUESTION IT ANSWERS
    Round-1 audit finding F16 said "prom_b 50/89 semantic labels new since HEAD
    have no line containing 'Evidence' in the comment block above".  That was a
    keyword grep, and the audit itself flagged that the raw count OVER-states
    the problem: several labels sit under one shared block comment that argues
    its case at length without ever using the word.  This script separates the
    two cases so the number can be quoted honestly:

        BACKED    -- an Evidence line in its own immediately-preceding header
        GROUP     -- no header of its own, but the nearest preceding header
                     BOTH names this label verbatim AND carries an Evidence
                     line.  This is the module-with-a-group-header shape the
                     SC1 block uses ("SC1_Service / SC1_TxFlush / ... -- the
                     module's public entry points"), and it is real backing.
        SECTION   -- no header of its own and not named in one, but the `; ===`
                     banner for the whole section carries an Evidence line.
                     WEAK: the banner is not about this label.
        UNBACKED  -- none of the above.

    A "semantic label" is any label that is not sub_XXXXXX / L_XXXXXX / T_XXXXXX
    / __*, i.e. one that asserts a meaning and therefore owes evidence.

RUN
    python3 notes/prom_b_evidence_audit.py             # summary + unbacked list
    python3 notes/prom_b_evidence_audit.py --all       # every label, graded
    python3 notes/prom_b_evidence_audit.py --since HEAD  # only labels not in git HEAD
    python3 notes/prom_b_evidence_audit.py --scopes    # BOTH scopes, side by side
    python3 notes/prom_b_evidence_audit.py --selftest

⚠ THE TWO SCOPES ARE NOT THE SAME NUMBER, AND ROUND 2 QUOTED THE NARROW ONE
    Round-2 audit finding F10: this lane's headline "zero unbacked" is true of
    `--since HEAD` and NOT of `--all`.  `--since HEAD` is a set difference by
    label NAME against `git show HEAD:prom_b/wsa1_prom_b.s`, and the generated
    modules emit mostly `sub_XXXXXX`, which is not a semantic label at all -- so
    a round that converts 34,777 bytes can still add only a few dozen names.
    `--scopes` prints both figures from one command precisely so a report cannot
    quote one and read as the other.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")

LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
GENERIC = re.compile(r"^(sub_[0-9A-Fa-f]{6}|L_[0-9A-Fa-f]{6}|T_[0-9A-Fa-f]{6}|__)")
BANNER = re.compile(r"^;\s*={10,}")


def grade(lines):
    """-> list of (lineno, name, grade).

    Grades: BACKED / GROUP / SECTION / UNBACKED, defined in the module
    docstring."""
    out = []
    # section = the text of the most recent `; ===` banner block
    section_has_ev = False
    # prev_header = the most recent free-standing comment block of any kind
    prev_header = []
    i = 0
    while i < len(lines):
        l = lines[i]
        if BANNER.match(l):
            # a banner block: consecutive comment lines from here to the next
            # banner line inclusive, then the body until the NEXT banner block
            j = i + 1
            body = []
            while j < len(lines) and lines[j].startswith(";"):
                body.append(lines[j])
                j += 1
            section_has_ev = any("Evidence" in x for x in body)
            i = j
            continue
        m = LABEL.match(l)
        if m and not GENERIC.match(m.group(1)):
            # its own header = the run of comment lines immediately above,
            # stopping at a blank line or at code
            k = i - 1
            own = []
            while k >= 0 and (lines[k].startswith(";") or lines[k].strip() == ""):
                if lines[k].strip() == "":
                    if own:
                        break
                    k -= 1
                    continue
                own.append(lines[k])
                k -= 1
            name = m.group(1)
            if own:
                prev_header = own
            if any("Evidence" in x for x in own):
                g = "BACKED"
            elif (any("Evidence" in x for x in prev_header)
                  and any(re.search(r"\b%s\b" % re.escape(name), x)
                          for x in prev_header)):
                g = "GROUP"
            elif section_has_ev:
                g = "SECTION"
            else:
                g = "UNBACKED"
            out.append((i + 1, name, g))
        i += 1
    return out


def since_head():
    """Names of semantic labels already present in git HEAD's prom_b."""
    try:
        old = subprocess.run(["git", "-C", ROOT, "show", "HEAD:prom_b/wsa1_prom_b.s"],
                             capture_output=True, text=True, check=True).stdout
    except Exception as e:  # pragma: no cover
        raise SystemExit("cannot read HEAD:prom_b/wsa1_prom_b.s -- %s" % e)
    return set(n for _, n, _ in grade(old.split("\n")))


def main():
    argv = sys.argv[1:]
    lines = open(SRC).read().split("\n")
    rows = grade(lines)

    if "--since" in argv:
        old = since_head()
        rows = [r for r in rows if r[1] not in old]

    if "--selftest" in argv:
        # the grader must distinguish the three cases on KNOWN examples
        by = {n: g for _, n, g in grade(lines)}
        fails = []
        # BStore_SeekBlock's header contains "Evidence:" verbatim
        if by.get("BStore_SeekBlock") != "BACKED":
            fails.append("BStore_SeekBlock graded %s, expected BACKED"
                         % by.get("BStore_SeekBlock"))
        # a grader that just greps the whole file would call everything BACKED
        if all(g == "BACKED" for g in by.values()):
            fails.append("grader calls EVERY label BACKED -- it cannot fail")
        if len(set(by.values())) < 2:
            fails.append("grader emits only one grade -- it cannot discriminate")
        if not rows:
            fails.append("no semantic labels found at all")
        print("labels graded: %d" % len(by))
        for f in fails:
            print("SELF-CHECK FAILED: " + f)
        return 1 if fails else 0

    if "--scopes" in argv:
        old = since_head()
        for tag, rs in (("image-wide  (--all)", rows),
                        ("new since HEAD", [r for r in rows if r[1] not in old])):
            k = {"BACKED": 0, "GROUP": 0, "SECTION": 0, "UNBACKED": 0}
            for _, _, g in rs:
                k[g] += 1
            print("%-22s %4d labels   BACKED %3d  GROUP %3d  SECTION %3d  "
                  "UNBACKED %3d" % (tag, len(rs), k["BACKED"], k["GROUP"],
                                    k["SECTION"], k["UNBACKED"]))
        print("(HEAD itself has %d semantic labels; the worktree has %d.)"
              % (len(old), len(rows)))
        return 0

    n = {"BACKED": 0, "GROUP": 0, "SECTION": 0, "UNBACKED": 0}
    for _, _, g in rows:
        n[g] += 1
    print("prom_b semantic labels%s: %d"
          % (" new since HEAD" if "--since" in argv else "", len(rows)))
    print("  BACKED   own Evidence line                        %4d" % n["BACKED"])
    print("  GROUP    named in a group header that has one     %4d" % n["GROUP"])
    print("  SECTION  only the section banner has one   (WEAK) %4d" % n["SECTION"])
    print("  UNBACKED none of the above                        %4d" % n["UNBACKED"])
    print()
    want = (("BACKED", "GROUP", "SECTION", "UNBACKED") if "--all" in argv
            else ("SECTION", "UNBACKED"))
    for ln, name, g in rows:
        if g in want:
            print("  %-8s %-40s %s:%d" % (g, name, "prom_b/wsa1_prom_b.s", ln))
    return 0


if __name__ == "__main__":
    sys.exit(main())
