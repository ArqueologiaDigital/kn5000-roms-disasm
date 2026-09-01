#!/usr/bin/env python3
"""Which prom_c probes did the per-subject SPLIT break -- and do they say so?

WHAT QUESTION THIS ANSWERS
--------------------------
  notes/prom_c_split.py moved 125,264 of prom_c's 127,731 lines into 26 included
  files.  Twenty-nine committed probes open `prom_c/wsa1_prom_c.s` and scan it.
  Every one of them now scans 2% of the image.

  ★ THE FAILURE THAT MATTERS IS NOT THE ONE THAT CRASHES.  A probe that raises
    is a probe that told you.  A probe that still prints "ALL CHECKS PASSED" over
    an input with no payload in it is a VACUOUS PASS, and this tree has been
    burned by exactly that before (the byte gate run for 106 commits against
    three-hour-stale ROMs).  So this script does not ask "does it still run".  It
    asks "does it give a DIFFERENT ANSWER when it is given the whole image", and
    it grades a probe that does not notice the difference as VACUOUS.

HOW
---
  Each probe is run twice, in two trees that differ in ONE file:
    A  the tree as it is -- prom_c/wsa1_prom_c.s is the 2,517-line master
    B  a shadow tree of symlinks in which that one file is the PRE-SPLIT listing
       from git (notes/prom_c_split.py's BASE_COMMIT)
  Same probe, same ROMs, same everything else.

    UNAFFECTED  identical output.  It never needed the moved lines.
    LOUD        differs, and A fails (non-zero, "FAIL", or a traceback).
    VACUOUS     differs, and A still reports success.  ★ FIX THESE FIRST.

★ THE RIGHT FIX is not to teach 29 probes to follow `.include` one at a time.
  It is ONE reader that resolves an image the way llvm-mc does -- lane A5 was
  writing notes/asm_source.py for this while the split landed.  This script is
  the WORK LIST for that migration, and it goes to zero when the migration is
  done.

⚠⚠ AND ONE HAZARD THAT IS NOT IN ANY BUCKET.  Three of these probes have a
  SPLICE mode that WRITES prom_c/wsa1_prom_c.s back:

      notes/gen_prom_c_f64_pool.py       --apply    (line 382)
      notes/prom_c_record68_round10.py   --emit68   (lines 986, 995, 1011)
      notes/prom_c_understanding_round6.py --apply  (lines 1519, 1588)

  Each does read-modify-write on the master.  After the split the block it means
  to splice usually lives in an INCLUDED file, so the regex misses and the write
  raises -- which is the good case, and is what happens today.  ★ DO NOT "fix"
  these by pointing their READ at the expanded image while leaving their WRITE on
  the master: that combination would overwrite the 2,517-line master with the
  whole 127,731-line image and undo the split silently.  Whoever migrates them
  must move the WRITE to the right included file in the same change.

RUN
---
  python3 notes/prom_c_probe_health.py             grade every probe
  python3 notes/prom_c_probe_health.py --selftest  the instrument's controls
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import git_prefix, git_show  # noqa: E402  (repo-relative paths)

PREFIX = git_prefix(ROOT)                       # "wsa1/", or "" at a repo root
GITDIR = os.path.abspath(os.path.join(ROOT, subprocess.run(
    ["git", "-C", ROOT, "rev-parse", "--git-common-dir"],
    capture_output=True, text=True, check=True).stdout.strip()))
MASTER = "prom_c/wsa1_prom_c.s"
BASE_COMMIT = "df84060a8d9cb95561d363597bfa90172107d42c"
TIMEOUT = 180

# The probes prom_c's own text tells a reader to run, one representative
# invocation each.  Collected with:
#   grep -rhoE 'python3 notes/[a-z0-9_]+\.py( --[a-z0-9-]+)?' prom_c/ | sort -u
# and reduced to those that OPEN the master (the rest read only the ROM and
# cannot be affected).
PROBES = [
    ["notes/gen_prom_c_f64_pool.py", "--verify"],
    ["notes/gen_prom_c_tail_tables.py", "--verify"],
    ["notes/gen_prom_c_preset_bank.py", "--verify"],
    ["notes/prom_c_reg_bytepair_check.py", "--selftest"],
    ["notes/prom_c_phantom_callsites.py", "--selftest"],
    ["notes/prom_c_finish_round12.py", "--selftest"],
    ["notes/prom_c_header_audit.py"],
    ["notes/prom_c_coverage_split.py"],
    ["notes/prom_c_module_map.py", "0xFACE67", "0xFAD142"],
    ["notes/prom_c_curve_table_census.py"],
    ["notes/prom_c_dev10c_field_sources.py"],
    ["notes/prom_c_voice_module_check.py"],
    ["notes/prom_c_record68_round10.py", "--selftest"],
    ["notes/prom_c_inventory_round8.py", "--cites"],
    ["notes/prom_c_naming_round3.py", "--struct"],
    ["notes/prom_c_understanding_round4.py"],
    ["notes/prom_c_understanding_round6.py"],
    ["notes/prom_c_audit_callsites.py"],
    ["notes/prom_c_round3_frontier_delta.py"],
    ["notes/prom_c_fcd0f7_interpreter.py"],
]

FAILWORD = re.compile(r'\bFAIL\b|Traceback|Error|FAILURES?:', re.I)


def shadow_tree(top):
    """A tree of symlinks to ROOT, with the ONE master replaced by the pre-split
    listing.  Symlinks, not a copy: the ROMs alone are 2 MB and the point is that
    exactly one file differs.  Returns the tree's ROOT-counterpart.

    ★ IT REPRODUCES THIS TREE'S GIT PREFIX.  `top` becomes the shadow
    REPOSITORY root and the tree sits under it at the same prefix ROOT has, with
    `.git` symlinked in -- otherwise a probe that reads the listing out of git
    fails in the shadow tree for a reason that has nothing to do with the
    master, which is exactly the artefact the blind control below was written to
    avoid.  Before the 2026-09-01 move into wsa1/ there was nothing to do here,
    because ROOT was the repository root."""
    dst = os.path.join(top, PREFIX.rstrip("/")) if PREFIX else top
    os.makedirs(dst, exist_ok=True)
    os.symlink(GITDIR, os.path.join(top, ".git"))
    for name in os.listdir(ROOT):
        if name == ".git":
            continue
        os.symlink(os.path.join(ROOT, name), os.path.join(dst, name))
    # ⚠⚠ `notes` MUST BE A REAL DIRECTORY, not a symlink to the real one.
    # asm_source.image_path() materialises the expanded image at
    # `<root>/notes/.image-<primary>`; with notes symlinked, a probe run in the
    # SHADOW tree wrote the PRE-SPLIT expansion into the REAL tree's cache, and
    # every image_path() reader there then silently read a 131,665-line image
    # instead of the 132,304-line one -- from a probe run that only claimed to
    # read.  Caught by notes/asm_source.py --selftest, whose "image_path() holds
    # exactly image_text()" check is the only thing that looks at it.
    os.unlink(os.path.join(dst, "notes"))
    os.mkdir(os.path.join(dst, "notes"))
    for name in os.listdir(os.path.join(ROOT, "notes")):
        if name.startswith(".image-"):
            continue
        os.symlink(os.path.join(ROOT, "notes", name),
                   os.path.join(dst, "notes", name))
    # prom_c must become a real directory so the one file can be swapped
    os.unlink(os.path.join(dst, "prom_c"))
    os.mkdir(os.path.join(dst, "prom_c"))
    for name in os.listdir(os.path.join(ROOT, "prom_c")):
        if name != os.path.basename(MASTER):
            os.symlink(os.path.join(ROOT, "prom_c", name),
                       os.path.join(dst, "prom_c", name))
    pre = git_show(MASTER, BASE_COMMIT)
    with open(os.path.join(dst, MASTER), "w", encoding="utf-8") as fh:
        fh.write(pre)
    return dst


def run(tree, argv):
    try:
        r = subprocess.run([sys.executable] + argv, cwd=tree,
                           capture_output=True, text=True, timeout=TIMEOUT)
        return r.returncode, (r.stdout + r.stderr)
    except subprocess.TimeoutExpired:
        return None, "<timeout>"


def grade(a_rc, a_out, b_rc, b_out):
    if a_out == b_out and a_rc == b_rc:
        return "UNAFFECTED"
    if a_rc != 0 or FAILWORD.search(a_out or ""):
        return "LOUD"
    return "VACUOUS"


# ★ WHERE THE SHADOW IS NOT A RE-ARRANGEMENT BUT AN OLDER TREE.
#
# The shadow replaces prom_c's master with BASE_COMMIT's, on the premise that the
# two trees hold THE SAME TEXT, differently arranged.  A later round that changes
# what prom_c's image CONTAINS breaks that premise, and the difference then shows
# up as VACUOUS -- "the probe noticed, and still reported success" -- when what
# the probe noticed is real and correct.
#
# ⚠ THIS IS A FOOTNOTE, NOT A RECLASSIFICATION.  The grade and the counts are
# printed unchanged; a lane that disagrees with a reason below should say so
# rather than find the row quietly missing.  Each entry names the exact thing the
# shadow cannot have, so it can be checked in one command.
PIN_ARTEFACTS = {
    "notes/prom_c_header_audit.py":
        "prom_c's image gained ONE label on 2026-09-01 that a BASE_COMMIT master "
        "cannot contain: DSP_ChannelRegs_Init_Loop, prom_a's name for the address "
        "prom_c calls DSP_ChannelRegs_Init__loop.  Both are defined in the SHARED "
        "source dsp/dsp_channel_regs.s, which prom_c did not have then.  The "
        "audit's answer moves by exactly that one label (1,203 -> 1,204, tier B "
        "680 -> 681, tier C 0 both sides), and it reads the image through "
        "asm_source, so it is not blind to anything.  Check: "
        "`python3 notes/prom_c_header_audit.py --all | grep DSP_ChannelRegs`.",
}


def main():
    with tempfile.TemporaryDirectory() as top:
        d = shadow_tree(top)
        rows = []
        for argv in PROBES:
            a_rc, a_out = run(ROOT, argv)
            b_rc, b_out = run(d, argv)
            rows.append((grade(a_rc, a_out, b_rc, b_out), " ".join(argv)))
    order = {"VACUOUS": 0, "LOUD": 1, "UNAFFECTED": 2}
    rows.sort(key=lambda r: (order[r[0]], r[1]))
    for g, name in rows:
        print(f"  {g:11s} {name}")
    n = {k: sum(1 for g, _ in rows if g == k) for k in order}
    print(f"\n  VACUOUS {n['VACUOUS']}   LOUD {n['LOUD']}   UNAFFECTED {n['UNAFFECTED']}"
          f"   of {len(rows)} probe(s) prom_c's own text cites")
    print("  ★ VACUOUS is the bucket that matters: those still report success.")
    noted = [(g, n) for g, n in rows if n in PIN_ARTEFACTS]
    if noted:
        print("\n  FOOTNOTES -- rows whose difference is traced to the shadow being")
        print("  OLDER than the tree, not to the probe being blind.  Counts above are")
        print("  UNCHANGED; judge these, do not skip them:")
        for g, n in noted:
            print("    %s  %s" % (g, n))
            for chunk in _wrap(PIN_ARTEFACTS[n], 68):
                print("      " + chunk)
    stale = sorted(set(PIN_ARTEFACTS) - {n for _g, n in rows})
    if stale:
        print("\n  ⚠ %d STALE footnote(s) for probes no longer graded here: %s"
              % (len(stale), ", ".join(stale)))
        return 1
    return 0


def _wrap(text, width):
    out, cur = [], ""
    for w in text.split():
        if len(cur) + len(w) + 1 > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        out.append(cur)
    return out


def selftest():
    """INVARIANTS.  None of these pins today's bucket counts -- they check that
    the instrument can tell the two trees apart at all, which is the only thing
    that makes a grade of UNAFFECTED meaningful."""
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    # ⚠ WRITTEN BEFORE THE SHADOW TREE IS BUILT.  The shadow's notes/ is a
    #   directory of symlinks taken at build time (see shadow_tree), so a file
    #   created afterwards is not in it.
    seer_src = ("import os\n"
                "r=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n"
                "print(len(open(os.path.join(r,%r),encoding='utf-8')"
                ".read().split(chr(10))))\n" % MASTER)
    seer_name = "notes/.pch_seer.py"
    with open(os.path.join(ROOT, seer_name), "w") as fh:
        fh.write(seer_src)
    with tempfile.TemporaryDirectory() as top:
        d = shadow_tree(top)
        a = open(os.path.join(ROOT, MASTER), encoding="utf-8").read().split("\n")
        b = open(os.path.join(d, MASTER), encoding="utf-8").read().split("\n")
        check(len(b) > 20 * len(a),
              f"the shadow tree's master is the WHOLE listing "
              f"({len(b):,} lines vs {len(a):,})")
        check(os.path.islink(os.path.join(d, "original_ROMs")),
              "everything except that one file is a symlink to the real tree")
        check(os.path.realpath(os.path.join(d, "notes", os.path.basename(__file__)))
              == os.path.realpath(os.path.join(ROOT, "notes",
                                               os.path.basename(__file__))),
              "the probes themselves are the same files in both trees")
        # a probe that reads the master MUST see the difference; one that reads
        # only the ROM must NOT.  Both directions, so neither grade is free.
        # ⚠ THE SEER IS SYNTHETIC, and this is the second time that lesson has
        #   had to be learned here.  It used to be notes/prom_c_header_audit.py,
        #   chosen because it read the master by path.  That probe has since been
        #   migrated to read the IMAGE through asm_source -- so it now gives the
        #   SAME answer in both trees, correctly, and the control failed.  ★ A
        #   CONTROL THAT NAMES A REAL PROBE GOES RED WHEN THAT PROBE IS FIXED.
        sa, sb = run(ROOT, [seer_name])[1], run(d, [seer_name])[1]
        check(sa != sb, "a master-reading probe is SEEN to differ between the "
                        "trees (%s vs %s)" % (sa.strip(), sb.strip()))
        # ⚠ The blind control is WRITTEN HERE rather than borrowed from notes/.
        #   The first version borrowed a real probe and the control failed for a
        #   reason that had nothing to do with the master: the shadow tree has no
        #   .git, so a probe that shells out to `git show` differs in both trees
        #   for free.  A control has to be blind to the master and to nothing else.
        blind_src = ("import os\n"
                     "r=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n"
                     "print(len(open(os.path.join(r,'original_ROMs',"
                     "'wsa1_prom_c.ic28'),'rb').read()))\n")
        for tree in (ROOT, d):
            with open(os.path.join(tree, "notes", ".blind_control.py"), "w") as fh:
                fh.write(blind_src)
        try:
            b_ = run(ROOT, ["notes/.blind_control.py"])[1] == \
                 run(d, ["notes/.blind_control.py"])[1]
        finally:
            os.remove(os.path.join(ROOT, "notes", ".blind_control.py"))
        check(b_, "a probe that reads only the ROM does NOT differ")
    os.remove(os.path.join(ROOT, seer_name))
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
