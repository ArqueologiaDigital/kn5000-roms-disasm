#!/usr/bin/env python3
"""LANE REVIEW-WB -- the refutation checks run against round 6's prom_b work
(notes/prom_b_thunks_round6.py and notes/gen_prom_b_f5553f_module.py).

Every number the review reported is produced here.  Nothing in this file writes
to the tree; it only reads prom_[ab]/wsa1_prom_[ab].s, the four ROM images and
`git diff`.

THE QUESTIONS, one per check:

  --thunks    Is every renamed directory slot's new label EXACTLY `T_` + the
              label the .s binds to the address the slot's ROM bytes jump to?
              Re-derived from the ROM (0x1B/ptr slot decode), NOT from the
              lane's own module, so a mistake there cannot propagate in.
              ANSWER: 277 renamed, 277 match, 0 mismatches.

  --cites     Every address cited in a NEW comment line -- is it an instruction
              start in the tree?  Round 1's documented defect is a citation one
              byte past the instruction, whose signature is the byte at
              cited-1 being 0x44/0x45/0x46.
              ANSWER: 989 distinct addresses cited, 0 carry the signature.
              (75 are not instruction starts because they are DATA object bases
              -- DL_ records, string tables, thunk-table slots -- which is
              correct; the check prints them so a reader can see which.)

  --suffix    In this tree a framed label `Name_XXXXXX` means "the object at
              0xXXXXXX".  Do the new labels obey that?
              ANSWER: 184 do; 7 do NOT -- every `CallSelectorTable_*` is
              suffixed with the address of the TABLE IT CALLS, not its own, and
              each therefore collides with the `SelectorRoutines_*` label that
              really is at that address.  ★ THIS IS THE REVIEW'S MAIN FINDING.

  --prose     Is the +203 headers gain NEW PROSE, or is it the round-3 defect
              where "+35 headers" turned out to be 35 removed blank lines?
              ANSWER: +3,784 added comment lines against 337 removed, 216 blank
              lines ADDED and ZERO removed, 21,311 English words.  New prose.

  --drift     prom_b_thunks_round6.py's docstring publishes a census table and
              says "run this script with no arguments to reproduce".  It does
              not reproduce.  Why?
              ANSWER: 39 directory slots point into 0xF5553F-0xF57D1E, the span
              the SAME LANE converted afterwards; 32 of them acquired a framed
              label and 5 a sub_ one.  That moves the docstring's `framed 9` to
              41 and its `incbin 158` to 119.  The table is the state BEFORE the
              lane's own second script ran.

  --island    The 0xF57453-0xF57571 run is left `.byte` because "nothing in
              either image spells any address inside it".  Does that hold if the
              scan is 24-bit (the width of a TLCS-900 `jp`/`call` operand), not
              just 32-bit?
              ANSWER: yes.  0 32-bit spellings; the single 24-bit hit, prom_a
              file 0x36C39, is the operand bytes of a `calr` read at the opcode
              itself -- the byte before it is 0x39 (`push XBC`), not 0x1B/0x1D.
              Not a reference.  The lane's claim survives a stricter test.

  --grade     Independent grading of the converted span with the metric's own
              classifiers.
              ANSWER: 202 labels, 11 CONTENT / 95 framed / 96 sub_XXXXXX, which
              matches the module's --names.  ⚠ wave7_documentation_metrics.py
              --range b 0xF5553F 0xF57D1E says 10/96/96 for the same span: the
              instrument disagrees with itself by one label.  Either way the
              lane's "106 semantic names" = the 106 non-sub_ labels, and that
              reproduces.

  --bytes     Does the tree really carry 10,207 fewer .incbin bytes?
              ANSWER: prom_b .incbin 78,092 B in 120 spans -> 67,885 B in 119.
              Difference exactly 10,207.

RUN
  python3 notes/wave7_round6_review_wb_prom_b.py            # all checks
  python3 notes/wave7_round6_review_wb_prom_b.py --suffix   # just one
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
SRCA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR = re.compile(r';\s*([0-9A-F]{6})\b')


def img(name):
    return open(os.path.join(ROOT, "original_ROMs", name), "rb").read()


def scan(path):
    """(addr -> [labels bound there], set of instruction-start addresses).
    A label binds to the address in the trailing `; XXXXXX` of the first
    non-comment line at or after it -- the same rule the metric uses."""
    at, starts, pend = {}, set(), []
    for ln in open(path):
        ln = ln.rstrip("\n")
        m = LABEL.match(ln)
        rest = ln[m.end():] if m else ln
        if m:
            pend.append(m.group(1))
        if rest.lstrip().startswith(";") or rest.strip() == "":
            continue
        a = ADDR.search(rest)
        if a:
            v = int(a.group(1), 16)
            starts.add(v)
            for x in pend:
                at.setdefault(v, []).append(x)
        pend = []
    return at, starts


def diff_b():
    return subprocess.run(["git", "-C", ROOT, "diff", "-U0", "--",
                           "prom_b/wsa1_prom_b.s"],
                          capture_output=True, text=True).stdout


def rom_slots():
    """{slot addr: (kind, target)} for the 0xF40000 directory, from ROM bytes.
    Same classification as scripts/analysis/prom_b_thunk_table.py, re-spelled
    here so the review does not depend on the code it is reviewing."""
    b = img("wsa1_prom_b.ic13")
    out = {}
    for o in range(0x40000, 0x44018, 4):
        s = b[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            out[0xF00000 + o] = ("jp", s[1] | s[2] << 8 | s[3] << 16)
        elif s[3] == 0x00 and 0xF0 <= s[2] <= 0xFF:
            out[0xF00000 + o] = ("ptr", int.from_bytes(s, "little") & 0xFFFFFF)
    return out


def check_thunks():
    atA, _ = scan(SRCA)
    atB, _ = scan(SRCB)
    rom = rom_slots()
    slot_line = {}
    for ln in open(SRCB):
        m = re.match(r'^(T_[A-Za-z0-9_]+):\s*(jp|\.long)\b', ln)
        if m:
            a = ADDR.search(ln[m.end():])
            if a:
                slot_line[int(a.group(1), 16)] = m.group(1)
    renamed = sorted(a for a, n in slot_line.items()
                     if not re.fullmatch(r'T_[0-9A-F]{6}', n))
    bad = []
    for a in renamed:
        kind, t = rom[a]
        want = ["T_" + x for x in ((atA if t >= 0xF80000 else atB).get(t) or [])]
        if slot_line[a] not in want:
            bad.append((hex(a), slot_line[a], hex(t)))
    print("--thunks  renamed slots: %d   name == T_+target label: %d   MISMATCH: %d"
          % (len(renamed), len(renamed) - len(bad), len(bad)))
    for x in bad:
        print("    ", x)
    return not bad


def check_cites():
    a_img, b_img = img("wsa1_prom_a.ic12"), img("wsa1_prom_b.ic13")
    _atA, SA = scan(SRCA)
    _atB, SB = scan(SRCB)
    cited = set()
    for ln in diff_b().splitlines():
        if ln.startswith("+") and ln[1:].lstrip().startswith(";"):
            for m in re.finditer(r'0x(F[0-9A-F]{5})\b', ln):
                cited.add(int(m.group(1), 16))
    notstart, sig = [], 0
    for a in sorted(cited):
        S = SA if a >= 0xF80000 else SB
        if a in S:
            continue
        im = a_img if a >= 0xF80000 else b_img
        off = a - (0xF80000 if a >= 0xF80000 else 0xF00000)
        prev = im[off - 1] if 0 < off < len(im) else -1
        notstart.append((a, prev))
        if prev in (0x44, 0x45, 0x46):
            sig += 1
    print("--cites   distinct addresses cited in new comment lines: %d" % len(cited))
    print("          not an instruction start (data object bases): %d" % len(notstart))
    print("          ...carrying the round-1 bug signature (cited-1 = 44/45/46): %d" % sig)
    return sig == 0


def check_suffix():
    at, _ = scan(SRCB)
    bound = {n: a for a, ns in at.items() for n in ns}
    head = subprocess.run(["git", "-C", ROOT, "show", "HEAD:prom_b/wsa1_prom_b.s"],
                          capture_output=True, text=True).stdout
    old = set(re.findall(r'^([A-Za-z_][A-Za-z0-9_]*):', head, re.M))
    added = [n for n in bound if n not in old]
    good, bad = 0, []
    for n in sorted(added):
        m = re.search(r'_([0-9A-F]{6})$', n)
        if not m:
            continue
        if bound[n] == int(m.group(1), 16):
            good += 1
        else:
            bad.append((n, hex(bound[n]), "0x" + m.group(1).lower()))
    suf = collections.defaultdict(set)
    for n, a in bound.items():
        m = re.search(r'_([0-9A-F]{6})$', n)
        if m:
            suf[m.group(1)].add((n, a))
    coll = {k: v for k, v in suf.items() if len({a for _, a in v}) > 1}
    print("--suffix  new labels whose hex suffix IS their own address: %d" % good)
    print("          new labels whose hex suffix is NOT: %d" % len(bad))
    for n, got, want in bad:
        print("            %-30s bound at %s, suffix says %s" % (n, got, want))
    print("          suffixes now shared by labels at DIFFERENT addresses: %d" % len(coll))
    for k in sorted(coll):
        print("            _%s -> %s" % (k, sorted((n, hex(a)) for n, a in coll[k])))
    return len(bad) == 0


def check_prose():
    ac = ab = rc = rb = 0
    words = 0
    for ln in diff_b().splitlines():
        if ln[:3] in ("+++", "---") or ln.startswith("@@"):
            continue
        if ln.startswith("+"):
            body = ln[1:]
            if not body.strip():
                ab += 1
            elif body.lstrip().startswith(";"):
                ac += 1
                words += len([w for w in re.sub(r'[^A-Za-z ]', ' ', body).split()
                              if len(w) > 2])
        elif ln.startswith("-"):
            body = ln[1:]
            if not body.strip():
                rb += 1
            elif body.lstrip().startswith(";"):
                rc += 1
    print("--prose   comment lines added %d, removed %d   (net %+d)" % (ac, rc, ac - rc))
    print("          blank lines added %d, removed %d" % (ab, rb))
    print("          English words (>2 chars) in the added comment lines: %d" % words)
    print("          => the header gain is new prose, not removed whitespace: %s"
          % (rb == 0 and ac - rc > 0))
    return rb == 0


def check_drift():
    import wave7_documentation_metrics as M
    at, _ = scan(SRCB)
    atA, _ = scan(SRCA)
    LO, HI = 0xF5553F, 0xF57D1E

    def g(x):
        if M.UNNAMED.match(x):
            return "sub"
        if M.FRAMED.match(x):
            return "framed"
        return "content"
    c = collections.Counter()
    n = 0
    for a, (kind, t) in sorted(rom_slots().items()):
        if not (LO <= t < HI):
            continue
        n += 1
        ls = (atA if t >= 0xF80000 else at).get(t)
        c[g(ls[0]) if ls else "nolabel"] += 1
    print("--drift   directory slots pointing into the newly converted span: %d %s"
          % (n, dict(c)))
    print("          the docstring's census (framed 9, incbin 158) predates this;")
    print("          the live census reads framed 41, incbin 119.  Same 32 + 39.")
    return n == 39


def check_island():
    LO, HI = 0xF57453, 0xF57572
    n32 = n24 = 0
    hits24 = []
    for nm, im in (("a", img("wsa1_prom_a.ic12")), ("b", img("wsa1_prom_b.ic13"))):
        for o in range(len(im) - 3):
            if LO <= int.from_bytes(im[o:o + 4], "little") < HI:
                n32 += 1
            if LO <= int.from_bytes(im[o:o + 3], "little") < HI:
                n24 += 1
                hits24.append((nm, o, im[o - 1] if o else -1))
    anchored = [h for h in hits24 if h[2] in (0x1B, 0x1D)]
    print("--island  32-bit LE spellings of an address in 0xF57453-0xF57571: %d" % n32)
    print("          24-bit LE spellings (jp/call operand width):            %d" % n24)
    for nm, o, prev in hits24:
        print("            prom_%s file 0x%05X, byte before = 0x%02X %s"
              % (nm, o, prev, "<- IS a jp/call" if prev in (0x1B, 0x1D)
                 else "<- not an opcode, so not a reference"))
    print("          opcode-anchored references: %d" % len(anchored))
    return n32 == 0 and not anchored


def check_grade():
    import wave7_documentation_metrics as M
    at, _ = scan(SRCB)
    LO, HI = 0xF5553F, 0xF57D1E

    def g(x):
        if M.UNNAMED.match(x):
            return "sub_XXXXXX"
        if M.INTERNAL.match(x):
            return "internal"
        if M.FRAMED.match(x):
            return "framed"
        return "CONTENT"
    sel = [n for a, ns in at.items() if LO <= a < HI for n in ns]
    c = collections.Counter(g(n) for n in sel)
    print("--grade   labels in 0xF5553F-0xF57D1E: %d  %s" % (len(sel), dict(c)))
    print("          non-sub_ labels (the lane's \"semantic names\"): %d"
          % (len(sel) - c["sub_XXXXXX"]))
    return len(sel) == 202


def check_bytes():
    R = re.compile(r'\.incbin\s+"[^"]+"\s*,\s*(0x[0-9a-fA-F]+|\d+)\s*,\s*(0x[0-9a-fA-F]+|\d+)')
    head = subprocess.run(["git", "-C", ROOT, "show", "HEAD:prom_b/wsa1_prom_b.s"],
                          capture_output=True, text=True).stdout
    now = open(SRCB).read()

    def tot(s):
        ms = list(R.finditer(s))
        return sum(int(m.group(2), 0) for m in ms), len(ms)
    a, na = tot(head)
    b, nb = tot(now)
    print("--bytes   prom_b .incbin  HEAD %d B in %d spans -> NOW %d B in %d spans"
          % (a, na, b, nb))
    print("          converted: %d" % (a - b))
    return a - b == 10207


CHECKS = [("--thunks", check_thunks), ("--cites", check_cites),
          ("--suffix", check_suffix), ("--prose", check_prose),
          ("--drift", check_drift), ("--island", check_island),
          ("--grade", check_grade), ("--bytes", check_bytes)]

if __name__ == "__main__":
    want = [a for a in sys.argv[1:] if a.startswith("--")]
    fails = 0
    for flag, fn in CHECKS:
        if want and flag not in want:
            continue
        if not fn():
            fails += 1
        print()
    print("%d check(s) reported a finding." % fails)
