#!/usr/bin/env python3
"""VERIFY-A1 -- an INDEPENDENT audit of the shared-kernel merge (lane a1).

    python3 notes/verify_a1_independent_check.py

Written from scratch by the verify lane; it deliberately does NOT reuse
notes/kernel_join_probe.py's own movement machinery, because a probe checking
itself proves nothing.  It reads the pre-merge text straight from git
(8ff84e5 = the commit the merge was made on top of) and the post-merge text
from the working tree.

WHAT EACH SECTION ANSWERS
  1  Did any pre-existing COMMENT line vanish?             -> constraint 2
  2  Did any semantic LABEL NAME vanish, tree-wide?        -> constraint 2
  3  Did the prose trailing a LABEL line survive?          -> constraint 2
     (kernel_join_probe's own check only covers whole-line comments)
  4  How much prose in kernel.s is NEW, and where is it?   -> constraint 2
  5  Are the diff's hunks confined to the kernel region?   -> constraint 2
  6  Reconcile "21 symbols / 77 sites" with "80 of 81".    -> the lane's report

NOT AUTOMATED HERE, run by hand and recorded in the verify report:
  * BOTH BYTE GATES, after `rm -rf rebuilt_ROMs` so the build cannot be stale:
        cd ~/compartilhado/kn5000-roms-disasm/wsa1  && python3 scripts/analysis/assert_byte_identical.py
        cd ~/compartilhado/kn5000-roms-disasm && python3 scripts/analysis/assert_byte_identical.py
  * ★ THE MUTATION TEST -- the check that makes the whole claim falsifiable.
    A gate that passes proves nothing unless it can also fail.  Copy the tree
    to scratch (`tar -c --exclude=.git --exclude=rebuilt_ROMs . | tar -x -C /tmp/mut`)
    and perturb one thing at a time:
        kernel_maincpu.inc  KERNEL_STACK_TOP 0x0060EB80 -> ...81
            => prom_a DIFFERS, 3 bytes, first at 0x5607;  prom_c still ok
        kernel_subcpu.inc   KERNEL_STACK_TOP 0x0000FA00 -> ...01
            => prom_c DIFFERS, 3 bytes, first at 0x1816C; prom_a still ok
        kernel.s, the LAST line of the shared body (`ret` -> `nop`)
            => BOTH differ, 1 byte each, prom_a 0x5E89 and prom_c 0x189EE,
               which are exactly 0x12B65 apart.
    The third is the one that matters: it shows the sharing is live at the LAST
    element of the block, not just the first.
  * The pre-merge baseline of notes/prom_a_byte_checks.py, to prove the lane's
    edit to it did not hide a failure:
        git archive 8ff84e5 | tar -x -C /tmp/headtree && cd /tmp/headtree
        python3 notes/prom_a_byte_checks.py   -> 470 checks, 2 FAILED
    and in the working tree                   -> 470 checks, 1 FAILED
    The one that cleared is the span banner ("0 of 1").  The survivor
    ("41 .fill, 26 claimed") FAILS IDENTICALLY at 8ff84e5 -- it is pre-existing,
    not a regression.
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402  (the image, not the master)
from asm_source import git_show, git_diff_lines  # noqa: E402  (repo-relative)
PRE_MERGE = "8ff84e5"
A_SRC = "prom_a/wsa1_prom_a.s"
C_SRC = "prom_c/wsa1_prom_c.s"
KERNEL = "kernel/kernel.s"
INCS = ["kernel/kernel_maincpu.inc", "kernel/kernel_subcpu.inc"]
# What nowlines() does NOT expand: the kernel sources this script counts
# separately, and the DEFINITIONS includes.  The latter matter for
# nowlines(KERNEL) -- kernel/kernel.s `.include`s include/tlcs900_mem_ops.inc,
# and inlining its 92 comment lines makes them read as prose the kernel join
# introduced, which it did not.
SKIP = [KERNEL] + INCS + ["include/tlcs900_mem_ops.inc",
                          "include/tmp95c061_sfr.inc"]

# ⚠ The leading dot is IN the class: `.L` compiler locals must be matched so we
# can EXCLUDE them deliberately rather than by an accident of the regex.  The
# tree has been bitten by a label count inflated by 8,237 of them.
LABEL = re.compile(r'^([A-Za-z_.$][A-Za-z0-9_.$]*):(.*)$')

OK = FAIL = 0


def check(desc, cond, detail=""):
    global OK, FAIL
    print(("  ok   " if cond else "  FAIL ") + desc + ("   " + detail if detail else ""))
    OK, FAIL = OK + (1 if cond else 0), FAIL + (0 if cond else 1)


def at(commit, rel):
    try:
        return git_show(rel, commit).split("\n")
    except FileNotFoundError as e:
        raise SystemExit("cannot read %s at %s: %s" % (rel, commit, e))


def nowlines(rel):
    """The IMAGE `rel` names -- minus the kernel sources, which this script
    counts SEPARATELY.

    ⚠ TWO WAYS TO GET THIS WRONG, and this file hit both.
      * Reading the primary with os.path.join sees 2% of prom_c since the
        per-subject split: "no label NAME is lost tree-wide" then FAILED,
        naming ten prom_c labels that had not gone anywhere.
      * Expanding the image WITHOUT skip= inlines kernel/kernel.s into prom_a
        and into prom_c, and this script then adds nowlines(KERNEL) on top --
        the same 4,148 lines three times.  "definitions removed equals names
        de-duplicated" went to -123, which is not a count of anything.
    """
    return image_lines(ROOT, rel, skip=SKIP)


# ⚠ NOT `git diff PRE_MERGE -- <rel>`.  A pathspec is relative to the CURRENT
# DIRECTORY, so it is spelled `wsa1/prom_a/...` here -- and PRE_MERGE predates
# the move into wsa1/ and holds that file as `prom_a/...`.  One pathspec cannot
# name both sides: git matched nothing on the old side and reported all 175,190
# working-tree lines as ADDED, with no error and no empty result to notice.
# asm_source.git_diff_lines fetches the old side BY OBJECT, at that revision's
# own spelling, and diffs here.
def _diff(rel, context=3):
    # ⚠ THE FILE, NOT THE IMAGE, on both sides -- that is what `git diff` did and
    # what these checks mean.  The kernel was FACTORED OUT of this file into
    # kernel/kernel.s, so its lines are `-` in a file diff and present in an
    # expanded one; section 1 exists to prove they reappear in kernel/.
    return git_diff_lines(rel, PRE_MERGE, context=context)


def deleted_lines(rel):
    """The `-` side of the working-tree diff against the pre-merge commit."""
    return [l[1:] for l in _diff(rel)
            if l.startswith("-") and not l.startswith("---")]


def added_lines(rel):
    return [l[1:] for l in _diff(rel)
            if l.startswith("+") and not l.startswith("+++")]


# --- 1. no pre-existing comment line may vanish ------------------------------
def section_comments():
    print("\n1. COMMENT LINES deleted from an image must reappear in kernel/")
    dest = collections.Counter(nowlines(KERNEL))
    for f in INCS:
        dest.update(nowlines(f))
    strip = collections.Counter(x.strip() for x in dest)
    out = {}
    for img, rel in (("prom_a", A_SRC), ("prom_c", C_SRC)):
        dl = deleted_lines(rel)
        com = [x for x in dl if x.strip().startswith(";") or x.strip().startswith("#")]
        verbatim = [x for x in com if dest[x]]
        reindent = [x for x in com if not dest[x] and strip[x.strip()]]
        gone = [x for x in com if not dest[x] and not strip[x.strip()]]
        out[img] = (len(dl), len(com), len(verbatim), len(reindent), gone)
        check("%s: every deleted comment line is VERBATIM in kernel/ "
              "(%d deleted lines, %d of them comments)" % (img, len(dl), len(com)),
              not reindent and len(gone) <= (1 if img == "prom_a" else 0),
              "%d verbatim, %d re-indented, %d absent" % (len(verbatim), len(reindent), len(gone)))
        for g in gone:
            print("        absent: %r" % g)
    # the ONE absentee must be the enumerated correction, and its claim must hold
    gone_a = out["prom_a"][4]
    check("the one absentee is the enumerated banner correction",
          gone_a == ["; 0xF85D1C-0xF85E89 -- not yet converted"], str(gone_a))
    # ...and it was FALSE before the merge: no .incbin under it at PRE_MERGE
    old = at(PRE_MERGE, A_SRC)
    i = old.index("; 0xF85D1C-0xF85E89 -- not yet converted")
    win = old[i + 1:i + 16]
    check("...and it was WRONG at %s -- no `.incbin` in the 15 lines under it" % PRE_MERGE,
          not any(l.startswith('\t.incbin "original_ROMs/wsa1_prom_a.ic12"') for l in win))
    return out


# --- 2. no semantic label name may vanish ------------------------------------
def labels(lines_list, skip_locals=True):
    c = collections.Counter()
    for lines in lines_list:
        for l in lines:
            m = LABEL.match(l)
            if m and not (skip_locals and m.group(1).startswith(".L")):
                c[m.group(1)] += 1
    return c


def section_labels():
    print("\n2. LABEL NAMES, tree-wide -- de-duplication is fine, LOSS is not")
    imgs = ["prom_%s/wsa1_prom_%s.s" % (k, k) for k in "abcd"]
    old = labels([at(PRE_MERGE, r) for r in imgs])
    new = labels([nowlines(r) for r in imgs] + [nowlines(KERNEL)])
    lost, gained = sorted(set(old) - set(new)), sorted(set(new) - set(old))
    check("no label NAME is lost tree-wide (%d distinct, .L excluded)" % len(old),
          not lost, str(lost[:10]))
    check("no label NAME is invented tree-wide", not gained, str(gained[:10]))
    # the de-duplication the metrics fall is blamed on, counted here rather than quoted
    o2 = labels([at(PRE_MERGE, A_SRC), at(PRE_MERGE, C_SRC)])
    n2 = labels([nowlines(A_SRC), nowlines(C_SRC), nowlines(KERNEL)])
    dedup = sorted(set(k for k, v in o2.items() if v > 1) - set(k for k, v in n2.items() if v > 1))
    check("definitions removed equals names de-duplicated (each was defined exactly twice)",
          sum(o2.values()) - sum(n2.values()) == len(dedup),
          "%d definitions, %d names" % (sum(o2.values()) - sum(n2.values()), len(dedup)))
    print("     ⚠ %d names de-duplicated.  kernel_join_probe.py's cmd_metrics docstring"
          % len(dedup))
    print("       says 46; that figure is hard-coded prose and no mode prints it.")
    check("every de-duplicated name is still defined once", all(n2[n] == 1 for n in dedup))
    check("kernel.s defines each of its %d labels exactly once"
          % len(set(m.group(1) for m in (LABEL.match(l) for l in nowlines(KERNEL)) if m)),
          all(v == 1 for v in labels([nowlines(KERNEL)], skip_locals=False).values()))
    return dedup


# --- 3. prose that trails a LABEL line, which check 1 does not see -----------
def section_label_prose():
    print("\n3. TRAILING PROSE on label lines ('; entry: ...')")
    kl = collections.defaultdict(set)
    for l in nowlines(KERNEL):
        m = LABEL.match(l)
        if m:
            kl[m.group(1)].add(m.group(2).strip())
    for img, rel in (("prom_a", A_SRC), ("prom_c", C_SRC)):
        labs = [m for m in (LABEL.match(l) for l in deleted_lines(rel)) if m]
        prose = [m for m in labs if m.group(2).strip()]
        kept = [m for m in prose
                if any(m.group(2).strip().lstrip(";").strip() in s for s in kl[m.group(1)])]
        check("%s: all %d deleted label lines' names exist in kernel.s" % (img, len(labs)),
              all(m.group(1) in kl for m in labs))
        check("%s: all %d trailing-prose texts survive (as a substring -- the merge "
              "PREFIXES a provenance note, it does not rewrite)" % (img, len(prose)),
              len(kept) == len(prose), "%d of %d" % (len(kept), len(prose)))


# --- 4. account for every line of NEW prose in kernel.s ----------------------
def section_new_prose():
    print("\n4. NEW PROSE in kernel.s -- every line accounted for")
    old = set(at(PRE_MERGE, A_SRC)) | set(at(PRE_MERGE, C_SRC))
    k = nowlines(KERNEL)
    com = [(i, l) for i, l in enumerate(k) if l.strip().startswith(";")]
    new = [(i, l) for i, l in com if l not in old]
    banners = [x for x in new if x[1].startswith("; >>>>>>")]
    header = [x for x in new if x[0] < 200 and not x[1].startswith("; >>>>>>")]
    rest = [x for x in new if x[0] >= 200 and not x[1].startswith("; >>>>>>")]
    print("     %d comment lines; %d already existed pre-merge; %d are new"
          % (len(com), len(com) - len(new), len(new)))
    print("     new = %d tool header + %d provenance banners + %d other"
          % (len(header), len(banners), len(rest)))
    # ⚠ Not a keyword sniff: the replacement text must be EXACTLY the lines
    # kernel_join_probe.py enumerates in CORRECTIONS, and nothing else.
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import kernel_join_probe as P
    allowed = [l for v in P.CORRECTIONS.values() for l in v]
    # ⚠ `rest` holds only lines that are new AS STRINGS.  One of the seven
    # (`; notes/prom_a_byte_checks.py fails if a "not yet converted" banner has
    # no`) is word-for-word a line prom_a already carried above the neighbouring
    # 0xF85904 banner, so it does not register as new.  Test the BLOCK instead.
    lo = k.index(allowed[0])
    check("the ONLY new prose outside the header and the banners is the text "
          "kernel_join_probe.CORRECTIONS enumerates, contiguous at line %d" % (lo + 1),
          k[lo:lo + len(allowed)] == allowed
          and set(l for _i, l in rest) <= set(allowed),
          "%d new lines, %d enumerated" % (len(rest), len(allowed)))
    for i, l in rest:
        print("        %5d %s" % (i + 1, l[:100]))


# --- 5. the diff must not stray outside the kernel region -------------------
def section_hunks():
    print("\n5. HUNK CONTAINMENT -- the merge must not touch unrelated code")
    for img, rel in (("prom_a", A_SRC), ("prom_c", C_SRC)):
        hunks = [l for l in _diff(rel, context=0) if l.startswith("@@")]
        starts = [int(re.match(r"@@ -(\d+)", h).group(1)) for h in hunks]
        # the file's own contents banner near the top, then the kernel block
        toc = [s for s in starts if s < 400]
        blk = [s for s in starts if s >= 400]
        check("%s: %d hunks, all in the table-of-contents or the kernel block"
              % (img, len(hunks)),
              len(toc) <= 1 and blk and max(blk) - min(blk) < 3000,
              "toc %s, block %s..%s" % (toc, min(blk), max(blk)))


# --- 6. reconcile the lane's two symbol denominators ------------------------
def section_symbols():
    print("\n6. SYMBOL SITES -- '21 symbols over 77 sites' vs '80 of the 81 differ'")
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import kernel_join_probe as P
    bd = P.byte_diff_map()
    sites = collections.Counter()
    slots = differ = 0
    for a, ai, ci in P.paired():
        if not (ai and ci):
            continue
        kind, _ = P.classify(a, ai[1], ci[1], bd[a])
        if ":" in kind:
            slots += 1
            differ += 1 if bd[a] else 0
            for n in kind.split(":", 1)[1].split(","):
                sites[n.split("-")[0]] += 1
    tbl = {n for n, _a, _c, _m in P.SYMBOL_TABLE}
    extra = {n: c for n, c in sites.items() if n not in tbl}
    check("81 slots name a symbol, and 80 of them are slots where the ROMs differ",
          (slots, differ) == (81, 80), "%d slots, %d differ" % (slots, differ))
    check("the 4-site gap between 81 and the tabulated 77 is LABEL SELF-REFERENCE, "
          "not a missing equate", sum(extra.values()) == 4 and len(extra) == 3, str(extra))
    check("exactly one equate has the same value on both CPUs (KERNEL_TIMER_COUNT)",
          [n for n, av, cv, _m in P.SYMBOL_TABLE if av == cv] == ["KERNEL_TIMER_COUNT"])
    check("the 21 tabulated symbols account for 77 sites",
          sum(sites[n] for n, _a, _c, _m in P.SYMBOL_TABLE) == 77 and len(P.SYMBOL_TABLE) == 21,
          "%d sites over %d symbols" % (sum(sites[n] for n, _a, _c, _m in P.SYMBOL_TABLE),
                                        len(P.SYMBOL_TABLE)))


def main():
    print("VERIFY-A1: independent audit of the shared-kernel merge, "
          "pre-merge text read from %s" % PRE_MERGE)
    section_comments()
    section_labels()
    section_label_prose()
    section_new_prose()
    section_hunks()
    section_symbols()
    print("\n%d checks, %d failures" % (OK + FAIL, FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
