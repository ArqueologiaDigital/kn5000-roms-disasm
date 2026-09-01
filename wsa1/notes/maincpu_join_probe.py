#!/usr/bin/env python3
"""prom_a and prom_b are ONE program. Which routines does it carry TWICE, and why?

QUESTION IT ANSWERS
    "Exactly four labels are defined in both prom_a/wsa1_prom_a.s and
     prom_b/wsa1_prom_b.s.  Are they the same routine at two addresses, or two
     different things wearing one name -- and if the first, what makes a compiler
     emit a routine twice into a FLAT address space?"

WHAT IT ESTABLISHES, and each is a measurement rather than a reading

  --collisions   the four names, the bytes at each site, and the differing count.
                 Three are byte-identical duplicates.  The fourth, `end`, is an
                 end-of-image marker that three of the four images carry and
                 nothing references: an artefact, not a routine.

  --callers      ★ THE REASON THE GUESS IS WRONG.  The obvious explanation --
                 "each ROM carries its own copy so it can be called without a
                 bank switch" -- is REFUTED by this machine's own call sites.
                 prom_a and prom_b are one contiguous 1 MiB image on CS2
                 (prom_b/prom_b.ld), so there is no bank to switch, and prom_a
                 CALLS prom_b's copy sixteen times.  Eight of those sixteen are
                 `calr`, a 16-bit PC-relative call, which cannot cross a bank in
                 any machine that has one.

  --nearest      ★ WHAT IS ACTUALLY TRUE, stated as a decidable invariant: every
                 reference to any copy targets the copy NEAREST IN THE ADDRESS
                 SPACE.  All of them, prom_a's reaching down into prom_b
                 included.  That is what a linker does when a routine is emitted
                 once per link unit and each unit's references bind to its own
                 copy -- and it is why the chip boundary at 0xF80000 is invisible
                 to the call graph.

  --shared       the two source files the duplicates now live in, and where each
                 is included from.

  --crossings    how often a 16-bit PC-RELATIVE call crosses the chip boundary,
                 counted from the tree's own DECODED lines rather than from a
                 byte scan -- a raw scan for opcode 0x1E finds the byte in data
                 too.  `calr` has a +/-32 KB reach, so a crossing is only
                 possible at all because the two chips are one flat window, and
                 it happens in BOTH directions.

  --split-cost   ★ WHY THE PER-SUBJECT SPLIT IS NOT IN THIS PASS.  prom_c and
                 prom_d have been split into subject sources; prom_a and prom_b
                 have not.  This counts the committed analysis scripts that open
                 either image BY PATH and read it line by line -- every one of
                 which a split would empty WITHOUT FAILING, which is the same
                 silent-emptying failure notes/reachability.py's own comments
                 describe.  The number is the size of the inventory the split
                 has to do first; it is not an argument that the split is wrong.

RUN
    python3 notes/maincpu_join_probe.py --collisions --callers --nearest --shared
    python3 notes/maincpu_join_probe.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import git_show  # noqa: E402  (git paths are repo-relative)
IMAGES = {"prom_a": ("prom_a/wsa1_prom_a.s", "wsa1_prom_a.ic12", 0xF80000),
          "prom_b": ("prom_b/wsa1_prom_b.s", "wsa1_prom_b.ic13", 0xF00000)}
# ⚠ ENUMERATED, NOT PATTERN-MATCHED.  A regex over "any line citing a listing by
# line number" would waive any FUTURE comment that happened to contain one, which
# is exactly the hole this check exists to close.  These are the two specific lines
# of one reflowed comment, quoted verbatim as they stood before the correction.
REFLOWED_BY_PROM_C_SPLIT = (
    ";          \u26a0 prom_c/wsa1_prom_c.s:58817 still cross-references this table under",
    ";          its OLD name; that file belongs to another lane and was not edited.",
)
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.$]*):')

# The three duplicated routines, by the address of each copy and its extent.
# Extents are read off the listing's own `ret` line, not asserted here.
# The commit the join was made on top of: --selftest reads the two images as they
# were there and checks that everything the join REMOVED from them is in the
# shared source.  ⚠ A rev, not a file: prose that is only in the working tree
# cannot prove prose was not lost.
JOIN_BASE = os.environ.get("JOIN_BASE", "c099e1cf7b20")

DUPLICATES = [("IndexedTable_GetPtr",    0xFB77D8, 0xF55321, 27),
              ("LCD_ScreenRedraw_Begin", 0xF999F0, 0xF7E2D9, 14),
              ("LCD_ScreenRedraw_End",   0xF999FE, 0xF7E2E7, 6)]


def rom(tag):
    return open(os.path.join(ROOT, "original_ROMs", IMAGES[tag][1]), "rb").read()


def src(tag):
    return open(os.path.join(ROOT, IMAGES[tag][0])).read().split('\n')


def at(tag, addr, n):
    return rom(tag)[addr - IMAGES[tag][2]: addr - IMAGES[tag][2] + n]


def labels(tag):
    out = {}
    for i, ln in enumerate(src(tag)):
        m = LABEL.match(ln)
        if m:
            out.setdefault(m.group(1), []).append(i + 1)
    return out


def collisions():
    la, lb = labels("prom_a"), labels("prom_b")
    return sorted(set(la) & set(lb)), la, lb


def refs(targets):
    """Every jp/call imm24 and calr d16 in either image that names one of
    `targets`. The three opcodes are 0x1B, 0x1D and 0x1E; a `calr`'s target is
    (address of the opcode) + 3 + signed 16-bit displacement."""
    out = {t: [] for t in targets}
    for tag in IMAGES:
        d, base = rom(tag), IMAGES[tag][2]
        for i in range(len(d) - 3):
            op = d[i]
            if op in (0x1B, 0x1D):
                t = d[i + 1] | d[i + 2] << 8 | d[i + 3] << 16
                kind = 'call' if op == 0x1D else 'jp'
            elif op == 0x1E:
                disp = d[i + 1] | d[i + 2] << 8
                t = base + i + 3 + (disp - 0x10000 if disp >= 0x8000 else disp)
                kind = 'calr'
            else:
                continue
            if t in out:
                out[t].append((tag, base + i, kind))
    return out


def main():
    a = sys.argv[1:]
    if '--selftest' in a:
        return selftest()
    if not a:
        print(__doc__)
        return 0
    if '--collisions' in a:
        names, la, lb = collisions()
        print("labels defined in BOTH prom_a and prom_b: %d\n" % len(names))
        byname = {n: (x, y, k) for n, x, y, k in DUPLICATES}
        for n in names:
            if n in byname:
                pa, pb, k = byname[n]
                ba, bb = at("prom_a", pa, k), at("prom_b", pb, k)
                diff = sum(1 for x, y in zip(ba, bb) if x != y)
                print("  %-24s prom_a 0x%06X / prom_b 0x%06X   %d bytes, %d differing"
                      % (n, pa, pb, k, diff))
                print("      %s" % ba.hex(' '))
                print("      %s" % bb.hex(' '))
            else:
                print("  %-24s prom_a line %d / prom_b line %d   -- not a routine:"
                      % (n, la[n][0], lb[n][0]))
                print("      the end-of-image marker.  prom_c defines it too, and no")
                print("      instruction or linker script in this tree references it.")
        print()
    if '--callers' in a:
        tg = {}
        for n, pa, pb, _k in DUPLICATES:
            tg[pa] = "prom_a %s" % n
            tg[pb] = "prom_b %s" % n
        r = refs(tg)
        cross = 0
        for t in sorted(tg, key=lambda x: tg[x]):
            byimg = {}
            for tag, _s, _k in r[t]:
                byimg[tag] = byimg.get(tag, 0) + 1
            print("  %-34s 0x%06X  %2d refs  %s" % (tg[t], t, len(r[t]), byimg))
            if tg[t].startswith("prom_b"):
                cross += byimg.get("prom_a", 0)
        print("\n  ★ prom_a references into prom_b's copies: %d" % cross)
        print("    of which `calr` (16-bit PC-relative, cannot cross a bank): %d"
              % sum(1 for t in tg if tg[t].startswith("prom_b")
                    for tag, _s, k in r[t] if tag == "prom_a" and k == 'calr'))
        print("    -> the 'each ROM carries a copy so it need not bank-switch'")
        print("       reading is refuted: there is no bank (one contiguous 1 MiB")
        print("       image on CS2) and prom_a calls prom_b's copy anyway.")
        print()
    if '--nearest' in a:
        tg = {}
        for n, pa, pb, _k in DUPLICATES:
            tg.setdefault(n, []).extend([pa, pb])
        allt = {a_: n for n, v in tg.items() for a_ in v}
        r = refs(allt)
        total = far = 0
        for n, copies in tg.items():
            for t in copies:
                for tag, site, kind in r[t]:
                    total += 1
                    best = min(copies, key=lambda c: abs(c - site))
                    if best != t:
                        far += 1
                        print("  NOT NEAREST: %s at 0x%06X (%s) -> 0x%06X, "
                              "but 0x%06X is closer" % (n, site, kind, t, best))
        print("  references to a duplicated copy: %d" % total)
        print("  that target a copy which is NOT the nearest: %d" % far)
        print("\n  ★ Every reference binds to the copy nearest in the flat address")
        print("    space, including the sixteen that cross from prom_a into prom_b.")
        print("    That is a per-LINK-UNIT copy, not a bank workaround.")
        print()
    if '--crossings' in a:
        for tag, other in (("prom_a", "prom_b"), ("prom_b", "prom_a")):
            hits = crossings(tag, other)
            print("  %s calr -> %s : %d decoded site(s)" % (tag, other, len(hits)))
            for site, t in hits[:4]:
                print("      0x%06X -> 0x%06X" % (site, t))
        print()
    if '--split-cost' in a:
        n, files = split_cost()
        print("  committed .py files that open prom_a/wsa1_prom_a.s or")
        print("  prom_b/wsa1_prom_b.s by path: %d" % n)
        for f in files[:12]:
            print("      %s" % f)
        if n > 12:
            print("      ... and %d more" % (n - 12))
        print()
    if '--shared' in a:
        for rel in ("maincpu/shared/indexed_table.s",
                    "maincpu/shared/lcd_screen_redraw.s"):
            p = os.path.join(ROOT, rel)
            print("  %-42s %s" % (rel, "present" if os.path.exists(p) else "ABSENT"))
        for tag in IMAGES:
            got = [ln for ln in src(tag) if 'maincpu/shared/' in ln and '.include' in ln]
            print("  %s includes %d shared source(s)" % (tag, len(got)))
            for g in got:
                print("      %s" % g.strip())
    return 0


# ⚠ THE TWO IMAGES WRITE `calr` DIFFERENTLY, and one of them does not write the
# target at all.  prom_b's comment carries unidasm's `calr 0xf7c6e5`; prom_a
# writes the raw 16-bit DISPLACEMENT -- `calr 0xf23b ; F80007 1e 3b f2` -- so a
# scan of prom_a's TEXT for a target finds nothing, and a first version of this
# probe duly reported "prom_a calr -> prom_b : 0" for something the linker script
# proves happens.  So the sites are found in the BYTES and validated against the
# listing: a 0x1E is only counted where the tree's own source says an instruction
# starts at that address.  Opcode 0x1E occurs in data too, and without that
# filter this number is about six times too big.
SRC_LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$')
DATA_DIR = re.compile(r'^\.(byte|ascii|asciz|short|word|long|quad|fill|space|zero|incbin|align|org)\b')


def decoded_addrs(tag):
    out = set()
    for ln in src(tag):
        m = SRC_LINE.match(ln)
        if m and not DATA_DIR.match(m.group(1)):
            out.add(int(m.group(2), 16))
    return out


def crossings(tag, other):
    """[(site, target)] for every `calr` at a DECODED address in `tag` whose
    target lands in `other`."""
    d, base = rom(tag), IMAGES[tag][2]
    lo = IMAGES[other][2]
    known = decoded_addrs(tag)
    out = []
    for i in range(len(d) - 2):
        if d[i] != 0x1E or (base + i) not in known:
            continue
        disp = d[i + 1] | d[i + 2] << 8
        t = base + i + 3 + (disp - 0x10000 if disp >= 0x8000 else disp)
        if lo <= t < lo + 0x80000:
            out.append((base + i, t))
    return out


PATH_REF = re.compile(r'prom_[ab]/wsa1_prom_[ab]\.s')


def split_cost():
    """(count, sorted paths) of committed .py files naming either image's path.
    ⚠ COMMITTED ones: a working-tree script nobody has kept is not a cost."""
    import subprocess
    tracked = subprocess.run(["git", "ls-files", "*.py"], cwd=ROOT,
                             capture_output=True, text=True, check=True).stdout.split()
    hits = []
    for rel in tracked:
        try:
            t = open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        if PATH_REF.search(t):
            hits.append(rel)
    return len(hits), sorted(hits)


def selftest():
    ok = fail = 0

    def check(name, cond, extra=""):
        nonlocal ok, fail
        if cond:
            ok += 1
        else:
            fail += 1
            print("  FAIL  %s%s" % (name, extra))

    names, la, lb = collisions()
    # ★ AFTER THE JOIN THIS IS EMPTY, and that is the point.  The three
    # duplicated routines are one source included at both sites, so their labels
    # are defined once per image by ONE file; `end` is renamed per image.
    check("no label name is defined in both prom_a and prom_b any more",
          not names, "  still shared: %s" % names)
    for tag, want in (("prom_a", "prom_a_image_end"), ("prom_b", "prom_b_image_end")):
        check("%s's end-of-image marker is %s" % (tag, want),
              want in labels(tag))
    # ★ THE MOVED PROSE.  Every comment line and label that left the two images
    # when the duplicates were shared must be in the shared source, VERBATIM.
    import subprocess
    shared = set()
    for rel in ("maincpu/shared/indexed_table.s", "maincpu/shared/lcd_screen_redraw.s"):
        shared |= set(open(os.path.join(ROOT, rel)).read().split('\n'))
    lost, moved, corrected = [], 0, 0
    for tag in IMAGES:
        rel = IMAGES[tag][0]
        try:
            was = git_show(rel, JOIN_BASE).split('\n')
        except FileNotFoundError:
            was = None
        if was is None:
            continue
        have = set(src(tag))
        for ln in was:
            if (ln.lstrip().startswith(';') or LABEL.match(ln)) and ln not in have:
                # ⚠ ONE DELIBERATE EXCEPTION, and it is a RENAME rather than a
                # move: `end:` became prom_a_image_end:/prom_b_image_end:.  It is
                # named here so the exception is a listed one instead of a hole.
                if ln == "end:":
                    continue
                # ⚠ SECOND LISTED EXCEPTION, and it is a CORRECTION rather than a
                # loss.  These lines cited prom_c by LINE NUMBER; the 26-file split
                # of prom_c made every such number point nowhere, so the citation
                # was rewritten to name the symbol instead.  The prose survives and
                # says more than it did -- see the live text in prom_a:
                #   was:  ⚠ prom_c/wsa1_prom_c.s:58817 still cross-references this
                #         table under its OLD name; that file belongs to another lane
                #   now:  ⚠ prom_c still cross-references this table under its OLD name,
                #         at prom_c/midi/midi_controllers.s:6906 (0xFAF87F) ...
                #         ⚠ THE CITATION WAS `prom_c/wsa1_prom_c.s:58817` and pointed
                #         nowhere after the split.
                # The replacement names a LIVE path AND the address, and records the
                # dead citation -- strictly more than the original said.
                # Enumerated, not waived: a comment that merely VANISHED would still
                # fail here, which is the whole point of this check.
                if ln in REFLOWED_BY_PROM_C_SPLIT:
                    corrected += 1
                    continue
                moved += 1
                if ln not in shared:
                    lost.append(ln)
    check("every comment and label the join moved out of the two images is in "
          "the shared source verbatim (%d moved, %d lost, %d line-number citations "
          "corrected by the prom_c split)" % (moved, len(lost), corrected),
          not lost, "  e.g. %r" % (lost[0][:90] if lost else ''))
    for n, pa, pb, k in DUPLICATES:
        ba, bb = at("prom_a", pa, k), at("prom_b", pb, k)
        check("%s: the two copies are byte-identical over all %d bytes" % (n, k),
              ba == bb, "  %s vs %s" % (ba.hex(), bb.hex()))
        # ⚠ NOT A PREFIX MATCH: each extent must end at its own `ret` (0x0E) and
        # the byte after it must not continue the routine.
        check("%s: both extents end at their own `ret`" % n,
              ba[-1] == 0x0E and bb[-1] == 0x0E)
    # The end-of-image marker is an artefact: nothing references it, and it is
    # the last label in its file.  (Named per image since the join; the check
    # follows whichever name the file carries.)
    for tag in IMAGES:
        s = src(tag)
        i = next(k for k, ln in enumerate(s)
                 if ln in ("end:", "%s_image_end:" % tag))
        rest = [ln for ln in s[i + 1:] if ln.strip() and not ln.lstrip().startswith(';')]
        check("%s: `end` is the last thing in the file" % tag, not rest,
              "  %d lines follow" % len(rest))
        # ⚠ PER LINE, and skipping the definition.  Joining the file and
        # searching for `[\s,(]end\b` matches the newline before `end:` itself,
        # so the first version of this check failed on both images for a symbol
        # neither of them uses.
        used = [ln for ln in s
                if not LABEL.match(ln)
                and re.search(r'[\s,(](end|%s_image_end)\b' % tag,
                              ln.split(';')[0])]
        check("%s: nothing references the end-of-image symbol (%d lines)"
              % (tag, len(used)), not used,
              "  e.g. %r" % (used[0][:90] if used else ''))
    # the nearest-copy invariant, as a check rather than a report
    tg = {}
    for n, pa, pb, _k in DUPLICATES:
        tg.setdefault(n, []).extend([pa, pb])
    allt = {a_: n for n, v in tg.items() for a_ in v}
    r = refs(allt)
    far = [(n, site, t) for n, copies in tg.items() for t in copies
           for _g, site, _k in r[t]
           if min(copies, key=lambda c: abs(c - site)) != t]
    total = sum(len(r[t]) for t in allt)
    check("all %d references bind to the NEAREST copy (%d do not)" % (total, len(far)),
          not far, "  %s" % far[:3])
    # and the refutation is not vacuous: prom_a really does reach into prom_b
    cross = sum(1 for n, _pa, pb, _k in DUPLICATES
                for g, _s, _k2 in r[pb] if g == "prom_a")
    check("prom_a references prom_b's copies (%d) -- the refutation has a witness"
          % cross, cross > 0)
    # the crossing claim is "in BOTH directions", so both must be non-empty --
    # and every target must really be in the other image
    for tag, other in (("prom_a", "prom_b"), ("prom_b", "prom_a")):
        h = crossings(tag, other)
        lo = IMAGES[other][2]
        check("%s has decoded `calr` sites reaching %s (%d)" % (tag, other, len(h)), h)
        check("%s: every one of them lands in %s" % (tag, other),
              all(lo <= t < lo + 0x80000 for _s, t in h))

    # the split-cost figure is a measurement, so it gets an invariant too: it is
    # a count of COMMITTED files and every one of them really names an image path
    n, files = split_cost()
    check("the split-cost census finds committed scripts naming an image path "
          "(%d)" % n, n > 0)
    bad = [f for f in files
           if not PATH_REF.search(open(os.path.join(ROOT, f), encoding="utf-8",
                                       errors="replace").read())]
    check("every file it counts really names one (%d that do not)" % len(bad), not bad)
    print("\n%d checks, %d failed" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
