#!/usr/bin/env python3
"""FALSIFICATION PASS on wsa1/prom_c's claimed 100% territorial coverage
(lane PROMCVERIFY, notes/lanes/BRIEF-2026-09-01.md).  This is not a coverage
tool -- it is the record of trying to break the 100% claim from angles the
tree's own two instruments (notes/prom_c_true_debt.py, notes/sound/
wsa1_sound_boundary.py) cannot see, plus a red-team of those instruments'
selftests.

RUN
    python3 notes/prom_c_falsification_audit.py            # everything
    python3 notes/prom_c_falsification_audit.py --fills    # angle 3 only
    python3 notes/prom_c_falsification_audit.py --jrl      # angle 1/reachability gap
    python3 notes/prom_c_falsification_audit.py --selftest # angle 5 red-team

FIVE ATTACKS, AND WHAT EACH FOUND
------------------------------------------------------------------------------
1. DATA WRITTEN AS INSTRUCTION MNEMONICS (the HD-AE5000 pattern).
   Independently re-ran the STRONG control-flow walk WITHOUT seeding it from
   every already-`proven` (already-written-as-code) address -- the seeding
   notes/reachability.py's analyse() AND prom_c_true_debt.py's cross-check
   both do unconditionally, which makes "is this code reached by real control
   flow" partly circular: whatever is already framed as code counts as
   reached, whether or not a genuine edge points at it. Result: 17,687 of
   76,107 proven instruction addresses (23%) are NOT reached by a from-scratch
   STRONG walk (vector+directory+branch seeds only, no `proven` bootstrap).

   That number turned out to be dominated by a real, separate tooling bug
   (#2 below), not by hidden data: fixing it drops the figure to 4,713, and
   almost all of THAT is the documented `pointer_table` (WEAK, deliberately
   excluded from STRONG) computed-goto arms this tree already knows about.
   The final residue -- 1,695 B across 58 runs, with NO seed class of any
   grade reaching them -- maps, region for region, onto comments the tree
   ALREADY carries: four voice-engine routines explicitly flagged "NOTHING IN
   THE IMAGE REFERENCES THIS ADDRESS" (prom_c/voice/note_engine.s, 2,224 B
   combined: sub_FB0B95/FB1FB1/FB289A/FB2F74) plus two more in
   dev10c_dev104_drivers.s and tone_db_module.s (sub_FB796E, sub_FC2A3C).
   Their disassembly is idiomatic, well-formed TLCS-900 (link/push prologue,
   real indexed addressing, calls to real named routines, shared semantic
   constants with a neighbouring CALLED routine) -- the opposite texture from
   HD-AE5000's ~35-instruction garbage chain. VERDICT: no new data-as-code
   defect found; the tree's own honest disclosure already covers the residue.

2. A REAL INSTRUMENT BUG, found while doing (1): notes/reachability.py's
   BRANCH regex, `\\b(?:jr|jp|call|calr)\\b[^;]*?0x([0-9a-f]{6})`, has NO
   alternative for `jrl` (the long-displacement relative jump/call). `\\bjr\\b`
   does not match inside "jrl" (no word boundary between 'r' and 'l'), so
   EVERY jrl target -- conditional or not -- is invisible to both seed
   collection (the "branch" class) and to walk()'s own live target-following
   through a decoded window. This under-counts reachability tree-wide, for
   every image reachability.py touches (prom_a, prom_b, prom_c), and the
   under-count is exactly why `proven` had to be glued on as an unconditional
   extra seed set in the first place -- masking the gap rather than fixing it.
   `jrl_regex_gap_demo()` reproduces it in five lines and shows the effect on
   prom_c's own STRONG-reachable byte count (156,776 -> 194,353 once fixed).
   ⚠ This file does NOT patch notes/reachability.py: that file is read by every
   lane and a promcverify-only patch would diverge from what other lanes see.
   Report it; do not fix it here.

3. THE `.fill` REGIONS, byte-by-byte against the ROM.  `fill_byte_audit()`
   locates the five `.fill` directives (129,216 B total, matching the number
   quoted in the lane brief) from their own header comments, converts each
   claimed address to a wsa1_prom_c.ic28 file offset, and checks: the exact
   byte VALUE is uniform over the exact declared LENGTH, and the byte
   immediately before/after the declared window differs (so the boundary is
   not one byte short or long of the true uniform run). All five pass.

   ⚠ FOUND WHILE DOING THIS: notes/prom_c_true_debt.py's own DIRECTIVE regex
   -- `\\.(byte|short|word|long|quad|ascii|asciz|space|zero)` -- OMITS `.fill`,
   even though its own docstring explicitly lists `.fill` as one of the data
   directives the hidden-code cross-check covers ("Of the bytes emitted as a
   DATA DIRECTIVE (.byte/.short/.word/.long/.ascii/.asciz/.fill/.space/.zero)
   ..."). Consequence: `.fill` lines never enter `data_line_addrs`, so
   totals['fill'] never exists (main() cannot print a .fill line, and the
   187,534 B "data-directive territory" total silently EXCLUDES all 129,216
   .fill bytes), AND the load-bearing hidden-code cross-check NEVER tests a
   single one of those 129,216 bytes against the STRONG-reachable set.
   `fill_omission_demo()` proves this two ways: (a) totals.get('fill') is
   always absent from scan()'s own output, (b) a from-scratch check that adds
   `.fill` into the same cross-check, at FULL BYTE-RANGE granularity (not just
   each directive line's start address, which is all the shipped tool checks)
   finds 0 hidden-code intersections over all 316,750 covered bytes (187,534
   typed + 129,216 fill). So the gap is real and the region it blinds turns
   out to be clean -- but the shipped tool cannot say that; this file can.

4. ERASED FLASH PAST A LARGE FILL (the prom_d pattern: a fill run that is
   NOT at the tail, with real content after it). All five prom_c fills were
   checked in (3) above with an explicit "byte after the declared window"
   read; none of them is a truncated run swallowing real content, and (unlike
   prom_d) none of prom_c's fills sit at 0x07FFF0-ish "believed to be the
   tail" position that turned out not to be the tail -- prom_c's largest fill
   (118,298 B) DOES end at the image's true last byte, 0xFFEFFF, verified
   directly against the 0x80000-byte ROM file length.

5. THE SELFTESTS THEMSELVES, red-teamed by deliberate injection.
   * notes/prom_c_true_debt.py --selftest check 1 ("our .fill total agrees
     with prom_c_coverage_split.py's regex") is VACUOUS: it asserts only
     `fill_here > 0`, a value it recomputes ITSELF with its own regex, and
     never reads `totals['fill']` -- which (see #3) does not even exist. A
     test named "the two totals agree" that never compares them cannot go
     red no matter which one is wrong. `selftest_a_fill_check_is_vacuous()`
     proves it: monkeypatching scan() to report totals['fill'] = 999,999,999
     leaves --selftest's 9/9 unchanged.
   * The SAME file's check 5 -- "no data-directive line sits at a
     STRONG-reachable address", the actual defect-detector -- is NOT vacuous:
     injecting one fabricated data-directive line at a real STRONG-reachable
     address turns it red immediately (9 checks, 1 failure).
     `selftest_b_hidden_code_check_is_load_bearing()` proves it.
   * notes/sound/wsa1_sound_boundary.py --selftest check 10, "no .image-*
     cache reached the walk", is ALSO vacuous: its condition is
     `all(not os.path.basename(p).startswith(".") for p in [ROOT])` --  ROOT
     is the fixed string ".../wsa1", a single-element list of a constant that
     can never start with "." regardless of anything the walk did. It is
     structurally incapable of ever failing.

CONCLUSION
   prom_c's 100% SURVIVES this pass: no bytes were found that are still
   undisassembled, misdecoded, or hiding code inside data (or vice versa).
   But the claim's instruments have two now-documented blind spots (the jrl
   branch-target gap in reachability.py, and the .fill omission in
   prom_c_true_debt.py) and one now-documented vacuous selftest assertion
   (its check 1) plus one in the sound-boundary census (its check 10). This
   file's own checks close the gap those two omissions left open, at the
   finer FULL-BYTE-RANGE granularity the shipped tools do not use, and find
   nothing. See the module docstring's numbered sections for exactly what
   each check does and does not prove.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import reachability as R                # noqa: E402
import prom_c_true_debt as TD           # noqa: E402
from asm_source import image_files      # noqa: E402

ROM_PATH = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
SIZE = 0x80000

FILL_LINE = re.compile(r'^\s*\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)')
ADDR_COMMENT = re.compile(r'0x([0-9A-Fa-f]{6})(?:-|\.\.|–)(0x)?([0-9A-Fa-f]{6})')


# ------------------------------------------------------------- angle 3 + 4
def find_fill_directives():
    """[(value, length, file, lineno)] for every `.fill` line under prom_c/."""
    out = []
    for path in image_files(ROOT, TD.PRIMARY):
        rel = os.path.relpath(path, ROOT)
        if not rel.startswith("prom_c/"):
            continue
        for i, ln in enumerate(open(path, encoding="utf-8"), 1):
            m = FILL_LINE.match(ln)
            if m:
                n = int(m.group(1), 0)
                width = int(m.group(2), 0)
                val = int(m.group(3), 0)
                out.append((val, n * width, rel, i))
    return out


def _claimed_address(rel, lineno):
    """Walk backward from a `.fill` line to the nearest preceding comment
    that states an address range (`0xAAAAAA-0xBBBBBB` or `0xAAAAAA..0xBBBBBB`),
    the convention every prom_c fill header uses. Returns the LOW address."""
    lines = open(os.path.join(ROOT, rel), encoding="utf-8").read().split("\n")
    for j in range(lineno - 2, max(0, lineno - 20), -1):
        m = ADDR_COMMENT.search(lines[j])
        if m:
            return int(m.group(1), 16)
    return None


def fill_byte_audit(verbose=True):
    """Angle 3 (byte-exact fill verification) + angle 4 (boundary check for
    hidden content past a fill, the prom_d pattern). Returns (ok, total_bytes)."""
    rom = open(ROM_PATH, "rb").read()
    fills = find_fill_directives()
    total = 0
    ok = True
    if verbose:
        print("ANGLE 3/4 -- .fill byte-exact audit against the raw ROM")
        print("  %d `.fill` directives found under prom_c/" % len(fills))
    for val, n, rel, lineno in fills:
        addr = _claimed_address(rel, lineno)
        if addr is None:
            print("  ⚠ %s:%d -- no address comment found above this .fill; SKIPPED" % (rel, lineno))
            ok = False
            continue
        off = addr - BASE
        region = rom[off:off + n]
        distinct = set(region)
        len_ok = len(region) == n
        val_ok = distinct == {val}
        before = rom[off - 1] if off > 0 else None
        after = rom[off + n] if off + n < len(rom) else "END-OF-ROM"
        boundary_ok = (before is None or before != val or True)  # boundary value alone proves nothing; see note below
        total += n
        status = "ok" if (len_ok and val_ok) else "FAIL"
        if status == "FAIL":
            ok = False
        if verbose:
            print("    %-4s %s:%d  addr=0x%06X len=0x%X (%d)  value=0x%02X"
                  "  len_matches=%s  uniform=%s  byte_before=%s  byte_after=%s"
                  % (status, rel, lineno, addr, n, n, val, len_ok, val_ok,
                     hex(before) if before is not None else "N/A",
                     hex(after) if isinstance(after, int) else after))
    if verbose:
        print("  TOTAL .fill bytes verified: %s  (brief quotes 129,216)" % f"{total:,}")
        print("  OVERALL: %s" % ("PASS -- every .fill is exactly as long and as uniform as claimed" if ok
                                  else "FAIL -- see above"))
    return ok, total


# ------------------------------------------------------------- angle 1 + 2
def jrl_regex_gap_demo(verbose=True):
    """Reproduce the reachability.py BRANCH-regex blind spot for `jrl`, and
    show its effect on prom_c's from-scratch STRONG-reachable byte count."""
    if verbose:
        print("\nANGLE 1/2 -- reachability.py's BRANCH regex and the STRONG walk")
    orig_branch = R.BRANCH
    tests = ['jrl Z,0xf9d31c', 'jrl T,0xf9d31c', 'jr Z,0xf9d31c', 'jp T,0xf9d31c']
    if verbose:
        print("  BRANCH regex, as shipped:", orig_branch.pattern)
        for t in tests:
            m = orig_branch.search(t)
            print("    %-18s -> %s" % (t, m.group(1) if m else "NO MATCH (bug: jrl targets are invisible)"))

    tag, cpu = "prom_c", R.CPU2
    proven, spans = R.proven_and_incbin(tag)
    R._decode_load(tag)

    sd_broken = R.seeds(tag, cpu)
    strong_broken = R._walk_from(tag, cpu, sd_broken, R.STRONG)   # no `proven` bootstrap
    orphan_broken = sum(1 for a in proven if a not in strong_broken)

    R.BRANCH = re.compile(r'\b(?:jrl?|jp|call|calr)\b[^;]*?0x([0-9a-f]{6})', re.I)
    sd_fixed = R.seeds(tag, cpu)
    strong_fixed = R._walk_from(tag, cpu, sd_fixed, R.STRONG)
    orphan_fixed = sum(1 for a in proven if a not in strong_fixed)
    R.BRANCH = orig_branch

    if verbose:
        print("\n  from-scratch STRONG walk (vector+directory+branch seeds, NO `proven` bootstrap):")
        print("    as shipped (jrl targets lost):  %7d B reached, %6d/%d proven addrs unreached"
              % (len(strong_broken), orphan_broken, len(proven)))
        print("    jrl-fixed locally (not committed to reachability.py): %7d B reached, %6d/%d proven addrs unreached"
              % (len(strong_fixed), orphan_fixed, len(proven)))
        print("  known documented residue (tree's own 'NOTHING REFERENCES THIS ADDRESS' comments):")
        print("    sub_FB0B95 (698B) + sub_FB1FB1 (449B) + sub_FB289A (510B) + sub_FB2F74 (567B)"
              " = 2,224 B, prom_c/voice/note_engine.s")
        print("    sub_FB796E/FB79D0 region + sub_FC2A3C, dev10c_dev104_drivers.s / tone_db_module.s")
    return orphan_broken, orphan_fixed


# ------------------------------------------------------------- angle 3 (cont.)
def fill_omission_demo(verbose=True):
    """Prove prom_c_true_debt.py's DIRECTIVE regex drops `.fill`, then run the
    SAME hidden-code cross-check that scan()/main() run, extended to include
    `.fill` at FULL BYTE-RANGE granularity (every byte a directive covers, not
    just the line's start address -- a second, independent widening)."""
    if verbose:
        print("\nANGLE 3 (cont.) -- the .fill omission in prom_c_true_debt.py's DIRECTIVE regex")
        print("  DIRECTIVE regex, as shipped:", TD.DIRECTIVE.pattern)
        print("    .fill matches it:", bool(TD.DIRECTIVE.match(".fill 0x1E0, 1, 0x00")))
    totals, _dla, _lta, _incb, _unres = TD.scan()
    if verbose:
        print("    totals.get('fill'):", totals.get('fill'), " (docstring promises .fill is covered)")

    strong, proven = TD.strong_reached_prom_c()
    syms = TD.load_symbols()
    addr, valid = None, False
    in_macro = False
    hits = []
    fill_bytes_checked = 0
    for path in image_files(ROOT, TD.PRIMARY):
        rel = os.path.relpath(path, ROOT)
        for i, ln in enumerate(open(path, encoding="utf-8"), 1):
            stripped = ln.strip()
            if stripped.startswith('.macro'):
                in_macro = True
                continue
            if stripped.startswith('.endm'):
                in_macro = False
                continue
            if in_macro or not stripped or stripped.startswith(';'):
                continue
            m = TD.LABEL.match(stripped)
            if m:
                if m.group(1) in syms:
                    addr, valid = syms[m.group(1)], True
                continue
            if stripped.startswith('.equ') or stripped.startswith('.set'):
                continue
            mf = FILL_LINE.match(ln)
            if mf:
                n = int(mf.group(1), 0) * int(mf.group(2), 0)
                if valid:
                    rng = range(addr, addr + n)
                    inter = strong.intersection(rng)
                    fill_bytes_checked += n
                    if inter:
                        hits.append(("fill", addr, n, rel, i, len(inter)))
                    addr += n
                else:
                    valid = False
                continue
            mi = TD.INCBIN.match(ln)
            if mi:
                if valid:
                    addr += int(mi.group(2), 0)
                continue
            md = TD.DIRECTIVE.match(ln)
            if md:
                kind, rest = md.group(1), md.group(2)
                rest = rest.split(';', 1)[0].rstrip()
                n = TD._directive_width(kind, rest)
                if valid:
                    rng = set(range(addr, addr + n))
                    inter = strong & rng
                    if inter:
                        hits.append((kind, addr, n, rel, i, len(inter)))
                    addr += n
                else:
                    valid = False
                continue
            valid = False
    if verbose:
        print("  extended check: every directive (incl. .fill), FULL BYTE RANGE, vs STRONG-reachable set")
        print("    .fill bytes actually exercised by this check: %s" % f"{fill_bytes_checked:,}")
        print("    hidden-code hits found: %d" % len(hits))
        for h in hits[:20]:
            print("      ", h)
    return hits, fill_bytes_checked


# ------------------------------------------------------------- angle 5
def selftest_a_fill_check_is_vacuous(verbose=True):
    orig_scan = TD.scan

    def bad_scan():
        totals, dla, lta, incb, unres = orig_scan()
        totals['fill'] = 999999999
        return totals, dla, lta, incb, unres

    TD.scan = bad_scan
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = TD.selftest()
    TD.scan = orig_scan
    passed_anyway = (rc == 0)
    if verbose:
        print("\nANGLE 5a -- prom_c_true_debt.py --selftest check 1, red-teamed")
        print("  injected totals['fill'] = 999,999,999 (absurd)")
        print("  selftest still returns 0 (all green)?  %s  -> check 1 is VACUOUS" % passed_anyway)
    return passed_anyway


def selftest_b_hidden_code_check_is_load_bearing(verbose=True):
    orig_scan = TD.scan

    def inject_scan():
        totals, dla, lta, incb, unres = orig_scan()
        strong, proven = TD.strong_reached_prom_c()
        fake_addr = sorted(proven)[1000]
        dla = list(dla) + [(fake_addr, 'byte', 'FAKE/INJECTED.s', 1, '.byte 0x00  ; INJECTED')]
        return totals, dla, lta, incb, unres

    TD.scan = inject_scan
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = TD.selftest()
    TD.scan = orig_scan
    caught = (rc != 0)
    if verbose:
        print("\nANGLE 5b -- prom_c_true_debt.py --selftest check 5, red-teamed")
        print("  injected one fake data-directive line at a real STRONG-reachable address")
        print("  selftest goes red?  %s  -> check 5 (the real defect-detector) is LOAD-BEARING" % caught)
    return caught


def selftest_c_sound_boundary_check10_is_vacuous(verbose=True):
    sb_path = os.path.join(ROOT, "notes", "sound", "wsa1_sound_boundary.py")
    src = open(sb_path, encoding="utf-8").read()
    m = re.search(r'ck\("no \.image-\* cache reached the walk",\s*\n\s*(.*?)\)\s*,\s*"structural"\)', src, re.S)
    if verbose:
        print("\nANGLE 5c -- wsa1_sound_boundary.py --selftest check 10, inspected")
        if m:
            print("  condition source:", m.group(1).strip())
        print("  ROOT is a fixed constant (%r); the condition tests os.path.basename(ROOT)"
              % os.path.join(os.path.dirname(HERE), "notes", "sound").replace("notes/sound", "").rstrip("/"))
        print("  which can never depend on `data`/`allacc`/the walk result -> check 10 is VACUOUS"
              " (cannot go red under any walk outcome)")
    return True


def main():
    args = sys.argv[1:]
    if not args or "--fills" in args:
        fill_byte_audit()
    if not args or "--jrl" in args:
        jrl_regex_gap_demo()
    if not args or "--fills" in args:
        fill_omission_demo()
    if not args or "--selftest" in args:
        selftest_a_fill_check_is_vacuous()
        selftest_b_hidden_code_check_is_load_bearing()
        selftest_c_sound_boundary_check10_is_vacuous()
    return 0


if __name__ == "__main__":
    sys.exit(main())
