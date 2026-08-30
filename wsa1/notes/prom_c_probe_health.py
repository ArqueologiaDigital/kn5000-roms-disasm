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


def shadow_tree(dst):
    """A tree of symlinks to ROOT, with the ONE master replaced by the pre-split
    listing.  Symlinks, not a copy: the ROMs alone are 2 MB and the point is that
    exactly one file differs."""
    for name in os.listdir(ROOT):
        if name == ".git":
            continue
        os.symlink(os.path.join(ROOT, name), os.path.join(dst, name))
    # prom_c must become a real directory so the one file can be swapped
    os.unlink(os.path.join(dst, "prom_c"))
    os.mkdir(os.path.join(dst, "prom_c"))
    for name in os.listdir(os.path.join(ROOT, "prom_c")):
        if name != os.path.basename(MASTER):
            os.symlink(os.path.join(ROOT, "prom_c", name),
                       os.path.join(dst, "prom_c", name))
    pre = subprocess.run(["git", "show", f"{BASE_COMMIT}:{MASTER}"],
                         cwd=ROOT, capture_output=True, check=True).stdout
    with open(os.path.join(dst, MASTER), "wb") as fh:
        fh.write(pre)


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


def main():
    with tempfile.TemporaryDirectory() as d:
        shadow_tree(d)
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
    return 0


def selftest():
    """INVARIANTS.  None of these pins today's bucket counts -- they check that
    the instrument can tell the two trees apart at all, which is the only thing
    that makes a grade of UNAFFECTED meaningful."""
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    with tempfile.TemporaryDirectory() as d:
        shadow_tree(d)
        a = open(os.path.join(ROOT, MASTER), encoding="utf-8").read().split("\n")
        b = open(os.path.join(d, MASTER), encoding="utf-8").read().split("\n")
        check(len(b) > 20 * len(a),
              f"the shadow tree's master is the WHOLE listing "
              f"({len(b):,} lines vs {len(a):,})")
        check(os.path.islink(os.path.join(d, "original_ROMs")),
              "everything except that one file is a symlink to the real tree")
        check(os.path.realpath(os.path.join(d, "notes")) ==
              os.path.realpath(os.path.join(ROOT, "notes")),
              "the probes themselves are the same files in both trees")
        # a probe that reads the master MUST see the difference; one that reads
        # only the ROM must NOT.  Both directions, so neither grade is free.
        seer = ["notes/prom_c_header_audit.py"]
        s = run(ROOT, seer)[1] != run(d, seer)[1]
        check(s, "a master-reading probe is SEEN to differ between the trees")
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
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
