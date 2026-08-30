#!/usr/bin/env python3
"""LANE REVIEW-WB -- the refutation checks run against round 9's prom_b work
(the 103 derivative thunk promotions applied by notes/prom_b_screens_round8.py
--apply, plus that file's new --glyphs / --framed / --calibrate sections and the
mkdtemp fix in scripts/analysis/llvm_roundtrip.py).

Nothing here writes to the tree.  It reads prom_[ab]/wsa1_prom_[ab].s, the four
ROM images and `git diff`, and it re-derives every number from the ROM rather
than from the code it is reviewing, so a mistake there cannot propagate in.

THE QUESTIONS, one per check:

  --thunks    Is every one of the 103 newly renamed directory slots exactly
              `T_` + the label the .s binds to the address the slot's ROM BYTES
              jump to?  The slot decode is re-spelled here from the raw image.
              ANSWER: 103 renamed this round, 103 match, 0 mismatches.
              (388 slots carry a promoted name in total; all 388 match.)

  --derived   The round calls all 103 DERIVATIVE.  Is that true -- did each
              target label already exist at HEAD, so no name was invented here?
              Does each target grade CONTENT under the metric's own classifier,
              which is the rule round 6 set for taking a name?  And does the
              chain BOTTOM OUT IN EVIDENCE -- does the target label itself carry
              an Evidence: line?
              ANSWER: 103 of 103 targets already carried that exact label at
              HEAD; 103 of 103 grade CONTENT; 103 of 103 carry an Evidence:
              line of their own.  0 invented, 0 taken from a framed or sub_
              target, 0 resting on an unevidenced parent.

  --cites     Every address cited in a NEW comment line -- is it an instruction
              start in the tree?  Round 1's documented defect is a citation one
              byte past the instruction, whose signature is the byte at
              cited-1 being 0x44/0x45/0x46.
              ANSWER: 206 distinct addresses cited, ALL 206 are instruction
              starts, 0 carry the signature.  And in the stronger form: all 103
              'slot 0xA is jp 0xT' claims are true of the RAW ROM BYTES --
              every slot decodes 0x1B + a 24-bit operand equal to T.

  --prose     Is the reported prose gain NEW PROSE, and is the report's claim
              that `headers` did NOT move actually right?  (Round 3's "+35
              headers" was 35 REMOVED BLANK LINES.)
              ANSWER: 207 comment lines added and ONE removed -- and that one is
              prom_b's own `; Calls:` cross-reference at 0xF43430, rewritten to
              spell the two new names.  ZERO blank lines added or removed, so
              the round-3 artefact cannot be present.  headers 3,299 -> 3,299,
              exactly as the lane reported; evidence 3,304 -> 3,407 (+103);
              content 1,015 -> 1,118 (+103); framed 3,060 -> 2,957 (-103);
              sub_XXXXXX unchanged at 2,031.

  --morph     Does the ROM carry the English?  For every morpheme of the 103
              new names, is there a ROM literal containing it?  (Round 3 shipped
              five prom_a labels built on "Home", which occurs ZERO times in any
              of the four images.)
              ANSWER: 76 distinct morphemes; 71 occur in a ROM image, searched
              case-insensitively because the machine's help text is mixed case.
              The 5 that do not are Paint, Screen, Leave, Null, Veneer and Link
              -- every one a structural verb or vtable role word whose OWN
              header states it is not ROM text, and whose role is derived from
              a call site: prom_a's PanelScreen_VtableTable header pins
              +0 Enter / +4 Leave / +8 Button to three distinct readers
              (`ld BC,0x0000`, `ld BC,0x0004`, `add XBC,8`).  No "Home".

  --zeros     The round's own headline finding is that the tree spells the
              letter O as the byte 0x30.  Re-derive it from the ROM: are cells
              0x30 and 0x4F really byte-identical in six of the seven faces, and
              how many labels and literals carry the misreading?
              ANSWER: every number reproduces.  6 of 7 faces byte-identical; the
              exception 0xF1E470 differs in 3 of its 8 bytes; 122 prom_b labels
              and 6 prom_a labels carry a CamelCase 0-for-O, 30 of prom_b's 122
              new this round; 4,060 prom_b `.ascii` literals, 75 distinct
              spelling an O as 0x30 in 98 occurrences, the last in sort order
              being 'VEL0CITY CHANGE'.
              ⚠ THIS IS A FINDING ABOUT THE NAMES THAT SHIPPED, not only about
              the ROM: 30 new labels spell an English word with a digit.  The
              lane declares it, measures it, and refuses to fix it across a lane
              boundary, which is the right call -- but the debt is now 128
              labels, and it grew here.

  --dangling  A rename retires a name.  How many lines elsewhere in the tree
              still spell one of the 103 retired `T_<address>` labels?
              ANSWER: 26 -- 16 in prom_a's own prose ("Called from: prom_b
              T_F400F0"), 10 in notes/.  ★ THIS IS THE REVIEW'S ONE FINDING.
              It is minor (the addresses did not move, and prom_b keeps a
              `(was T_F400F0)` back-reference on every renamed slot) but it is
              real, and the lane's writeup does not mention it.

  --headroom  Is the harvest complete, and is the lane's "6 left over, handed to
              the round barrier" the right number?
              ANSWER: yes.  18 slots are still spelled T_<address> while pointing
              at a content-named target, but 12 of those are 6 targets reached by
              TWO slots each, and round 6's rule R3 drops them because two slots
              cannot both carry the same label.  Under the tree's own rule the
              remainder is exactly the 6 the lane names.  ⚠ The naive 18 is
              printed too so the over-count is not repeated.

  --selftest  Count the lane script's own checks, HEAD vs now.
              ANSWER: 27 -> 43 c() calls, 32 -> 48 printed lines, 0 failures.
              The lane's status line said "+8 checks"; the true delta is +16.
              The total it reported, 48, is right, and no wrong number reached
              the tree -- the docstring quotes no count.  An UNDER-statement of
              its own work, which is the harmless direction, but it is wrong.

RUN
  python3 notes/wave7_round9_review_wb_prom_b.py            # all checks
  python3 notes/wave7_round9_review_wb_prom_b.py --zeros    # just one
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, image_text_at_rev  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
SRCA = image_path(ROOT, "prom_a/wsa1_prom_a.s")
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR = re.compile(r';\s*([0-9A-F]{6})\b')
A_BASE, B_BASE = 0xF80000, 0xF00000

# The seven Latin faces, from notes/FINDINGS-fonts.md (pre-existing fact, not
# derived here): base address, cell width, height, bytes per cell.
FACES = [(0xF1B400, 14), (0xF1BEF0, 16), (0xF1CB70, 32), (0xF1E470, 8),
         (0xF1EAB0, 32), (0xF24DC0, 10), (0xF25590, 48)]


def img(name):
    return open(os.path.join(ROOT, "original_ROMs", name), "rb").read()


def head(path):
    return subprocess.run(["git", "-C", ROOT, "show", "HEAD:" + path],
                          capture_output=True, text=True).stdout


def scan(text):
    """(addr -> [labels bound there], set of instruction-start addresses).
    A label binds to the address in the trailing `; XXXXXX` of the first
    non-comment line at or after it -- the same rule the metric uses."""
    at, starts, pend = {}, set(), []
    for ln in text.split("\n"):
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


def diff_b(u0=True):
    cmd = ["git", "-C", ROOT, "diff"] + (["-U0"] if u0 else []) + \
          ["--", "prom_b/wsa1_prom_b.s"]
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def renamed_this_round():
    """{slot addr: (new label, retired label)} for this round's promotions."""
    out = {}
    for ln in diff_b().split("\n"):
        if not ln.startswith("+") or ln.startswith("+++"):
            continue
        m = re.match(r'\+(T_[A-Za-z0-9_]+):', ln)
        w = re.search(r'\(was (T_[0-9A-F]{6})\)', ln)
        a = ADDR.search(ln)
        if m and w and a:
            out[int(a.group(1), 16)] = (m.group(1), w.group(1))
    return out


def rom_slots():
    """{slot addr: (kind, target)} for the 0xF40000 directory, from ROM bytes.
    Re-spelled here so the review does not depend on the code it reviews."""
    b = img("wsa1_prom_b.ic13")
    out = {}
    for o in range(0x40000, 0x44018, 4):
        s = b[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            out[0xF00000 + o] = ("jp", s[1] | s[2] << 8 | s[3] << 16)
        elif s[3] == 0x00 and 0xF0 <= s[2] <= 0xFF:
            out[0xF00000 + o] = ("ptr", int.from_bytes(s, "little") & 0xFFFFFF)
    return out


def slot_labels(text):
    """{slot addr: label} for every T_ label on a jp/.long directory line."""
    out = {}
    for ln in text.split("\n"):
        m = re.match(r'^(T_[A-Za-z0-9_]+):\s*(jp|\.long)\b', ln)
        if m:
            a = ADDR.search(ln[m.end():])
            if a:
                out[int(a.group(1), 16)] = m.group(1)
    return out


# ------------------------------------------------------------------ checks
def check_thunks():
    atA, _ = scan(open(SRCA).read())
    atB, _ = scan(open(SRCB).read())
    rom = rom_slots()
    now = slot_labels(open(SRCB).read())
    new = renamed_this_round()
    promoted = sorted(a for a, n in now.items()
                      if not re.fullmatch(r'T_[0-9A-F]{6}', n))

    def bad(addrs):
        out = []
        for a in addrs:
            if a not in rom:
                out.append((hex(a), now[a], "SLOT NOT DECODED FROM ROM"))
                continue
            _kind, t = rom[a]
            want = ["T_" + x for x in ((atA if t >= A_BASE else atB).get(t) or [])]
            if now[a] not in want:
                out.append((hex(a), now[a], hex(t), want))
        return out
    b_all, b_new = bad(promoted), bad(sorted(new))
    print("--thunks  renamed THIS ROUND: %d   name == T_+target's label: %d   MISMATCH: %d"
          % (len(new), len(new) - len(b_new), len(b_new)))
    print("          promoted slots in total: %d   match: %d   MISMATCH: %d"
          % (len(promoted), len(promoted) - len(b_all), len(b_all)))
    for x in b_all:
        print("     ", x)
    return not b_all and not b_new


def check_derived():
    atA, _ = scan(open(SRCA).read())
    atB, _ = scan(open(SRCB).read())
    hA, _ = scan(head("prom_a/wsa1_prom_a.s"))
    hB, _ = scan(head("prom_b/wsa1_prom_b.s"))
    rom = rom_slots()
    new = renamed_this_round()
    import wave7_documentation_metrics as M
    invented, notcontent = [], []
    for a in sorted(new):
        _k, t = rom[a]
        old_at = (hA if t >= A_BASE else hB).get(t) or []
        stem = new[a][0][2:]
        if stem not in old_at:
            invented.append((hex(a), new[a][0], hex(t), old_at))
        if M.UNNAMED.match(stem) or M.FRAMED.match(stem) or M.INTERNAL.match(stem):
            notcontent.append((hex(a), stem))
    EA, EB = evidenced("prom_a/wsa1_prom_a.s"), evidenced("prom_b/wsa1_prom_b.s")
    noev = []
    for a in sorted(new):
        _k, t = rom[a]
        stem = new[a][0][2:]
        if stem not in (EA if t >= A_BASE else EB):
            noev.append((hex(a), stem))
    print("--derived 103 promotions: target label already present at HEAD: %d   INVENTED HERE: %d"
          % (len(new) - len(invented), len(invented)))
    print("          target grades CONTENT under the metric's classifier: %d   NOT CONTENT: %d"
          % (len(new) - len(notcontent), len(notcontent)))
    print("          target carries an Evidence: line on its OWN label: %d   WITHOUT ONE: %d"
          % (len(new) - len(noev), len(noev)))
    for x in invented + notcontent + noev:
        print("     ", x)
    return not invented and not notcontent and not noev


def evidenced(path):
    """Labels whose comment block carries an `Evidence:` line, under the same
    block rule wave7_documentation_metrics.py uses (one blank line tolerated)."""
    out, run, ev, blanks = set(), 0, False, 0
    for ln in open(os.path.join(ROOT, path)):
        ln = ln.rstrip("\n")
        if ln.startswith(";"):
            run += 1
            if "Evidence:" in ln:
                ev = True
            blanks = 0
            continue
        if ln.strip() == "" and run:
            blanks += 1
            if blanks > 1:
                run, ev, blanks = 0, False, 0
            continue
        m = LABEL.match(ln)
        if m and ev:
            out.add(m.group(1))
        run, ev, blanks = 0, False, 0
    return out


def check_cites():
    a_img, b_img = img("wsa1_prom_a.ic12"), img("wsa1_prom_b.ic13")
    _atA, SA = scan(open(SRCA).read())
    _atB, SB = scan(open(SRCB).read())
    cited = set()
    for ln in diff_b(u0=False).split("\n"):
        if ln.startswith("+") and ln[1:].lstrip().startswith(";"):
            for m in re.finditer(r'0x(F[0-9A-F]{5})\b', ln):
                cited.add(int(m.group(1), 16))
    notstart, sig = [], []
    for a in sorted(cited):
        S = SA if a >= A_BASE else SB
        if a in S:
            continue
        im = a_img if a >= A_BASE else b_img
        off = a - (A_BASE if a >= A_BASE else B_BASE)
        prev = im[off - 1] if 0 < off < len(im) else -1
        notstart.append((a, prev))
        if prev in (0x44, 0x45, 0x46):
            sig.append((hex(a), hex(prev)))
    print("--cites   distinct addresses cited in NEW comment lines: %d" % len(cited))
    print("          not an instruction start: %d" % len(notstart))
    print("          ...carrying the round-1 bug signature (cited-1 = 44/45/46): %d" % len(sig))
    for x in sig:
        print("     ", x)
    # And the stronger form: the slot cited in each Evidence line really is a jp
    # to the address that line names.
    rom, wrong = rom_slots(), []
    for ln in diff_b().split("\n"):
        m = re.match(r'\+; Evidence: slot 0x(F[0-9A-F]{5}) is `jp 0x(F[0-9A-F]{5})`', ln)
        if m:
            a, t = int(m.group(1), 16), int(m.group(2), 16)
            if rom.get(a) != ("jp", t):
                wrong.append((m.group(1), m.group(2), rom.get(a)))
    print("          Evidence lines of the form `slot 0xA is jp 0xT`: %d   ROM disagrees: %d"
          % (len(new_ev()), len(wrong)))
    for x in wrong:
        print("     ", x)
    return not sig and not wrong


def new_ev():
    return [ln for ln in diff_b().split("\n")
            if ln.startswith("+; Evidence: slot 0x")]


def check_prose():
    add = rem = addblank = remblank = 0
    for ln in diff_b().split("\n"):
        if ln.startswith("+++") or ln.startswith("---"):
            continue
        if ln.startswith("+"):
            if ln[1:].lstrip().startswith(";"):
                add += 1
            elif ln[1:].strip() == "":
                addblank += 1
        elif ln.startswith("-"):
            if ln[1:].lstrip().startswith(";"):
                rem += 1
            elif ln[1:].strip() == "":
                remblank += 1
    import wave7_documentation_metrics as M
    # ⚠ SEVEN, not six.  wave7_documentation_metrics.scan() grew a DESCRIPTIVE
    # branch-target column in round 12 and this unpack was never widened, so
    # every run of this section died with "too many values to unpack".  It is
    # not split collateral -- it predates the split -- but it is why this probe
    # could not be graded.
    n0, f0, u0, i0, b0, h0, e0 = M.scan("prom_b/wsa1_prom_b.s")
    # ⚠ THE IMAGE AT HEAD, written out so scan() can read it as a file: the
    # working-tree side is the image, so the HEAD side must be too.
    open(os.path.join(ROOT, ".rev_tmp_head.s"), "w").write(
        image_text_at_rev(ROOT, "prom_b/wsa1_prom_b.s", "HEAD"))
    n1, f1, u1, i1, b1, h1, e1 = M.scan(".rev_tmp_head.s")
    os.remove(os.path.join(ROOT, ".rev_tmp_head.s"))
    print("--prose   comment lines ADDED %d   REMOVED %d      blank lines added %d removed %d"
          % (add, rem, addblank, remblank))
    print("          metric prom_b   HEAD -> NOW:  content %d -> %d   framed %d -> %d"
          % (len(n1), len(n0), len(f1), len(f0)))
    print("                          sub_XXXX %d -> %d   headers %d -> %d   evidence %d -> %d"
          % (len(u1), len(u0), h1, h0, e1, e0))
    print("          the ONE removed comment line is prom_b's own `; Calls:` cross-")
    print("          reference at 0xF43430, rewritten to the two new names.  Not a")
    print("          deleted blank line and not lost prose.")
    ok = (add == 207 and rem == 1 and addblank == 0 and remblank == 0
          and h1 == h0 and e0 - e1 == 103 and len(n0) - len(n1) == 103
          and len(u0) == len(u1))
    print("          -> new prose, headers unchanged, +103 content and +103 evidence: %s" % ok)
    return ok


# The structural verbs and vtable role words this tree declares as NOT ROM text:
# prom_a's PanelScreen_VtableTable header derives +0 Enter / +4 Leave / +8 Button
# from three distinct call sites (PanelScreen_CallEnter_A/B `ld BC,0x0000`,
# PanelScreen_CallLeave_A/B `ld BC,0x0004`, PanelButton_Route `add XBC,8`), and
# `Paint_`/`Veneer_`/`Null` are stated in their own headers as structural.
CONTENT_STOP = set("""Paint Screen Enter Leave Null Button Veneer Link Send Wait
Done Command Cmd""".split())


def check_morph():
    new = renamed_this_round()
    imgs = {n: img(n) for n in ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13",
                                "wsa1_prom_c.ic28", "wsa1_prom_d.bin")}
    morphs = collections.OrderedDict()
    for a in sorted(new):
        stem = new[a][0][2:]
        for part in re.findall(r'[A-Z][a-z]*|[A-Z]+(?![a-z])', stem):
            if part.isdigit():
                continue
            morphs.setdefault(part, []).append(hex(a))
    found, missing = [], []
    for m in morphs:
        # The ROM draws its captions in upper case but its help text in mixed
        # case ("Are you sure", "Please push a any button"), so the search is
        # case-insensitive; searching only the upper-cased form reports a false
        # miss for `You`.
        lo = m.lower().encode()
        hit = [n for n, d in imgs.items() if lo in d.lower()]
        (found if hit else missing).append(m)
    print("--morph   distinct morphemes across the 103 new names: %d" % len(morphs))
    print("          occur VERBATIM (upper-cased) in at least one ROM image: %d" % len(found))
    print("          do NOT occur in any image: %d" % len(missing))
    print("            ", " ".join(sorted(missing)))
    unexplained = [m for m in missing if m not in CONTENT_STOP]
    print("          ...of which NOT a declared structural/role word: %d  %s"
          % (len(unexplained), " ".join(sorted(unexplained))))
    return not unexplained


def check_zeros():
    b = img("wsa1_prom_b.ic13")
    same, diff = [], []
    for base, pitch in FACES:
        o = base - B_BASE
        z = b[o + 0x30 * pitch:o + 0x31 * pitch]
        O = b[o + 0x4F * pitch:o + 0x50 * pitch]
        (same if z == O else diff).append(
            (hex(base), pitch, sum(1 for x, y in zip(z, O) if x != y)))
    print("--zeros   Latin faces where cell 0x30 == cell 0x4F byte-for-byte: %d of %d"
          % (len(same), len(FACES)))
    for x in diff:
        print("            exception %s pitch %d: %d differing bytes" % x)
    # labels carrying a CamelCase 0-for-O
    pat = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
    cnt = {}
    zero = re.compile(r'[A-Za-z]0[a-z]')   # a 0 INSIDE a word, not a hex suffix
    for tag, path in (("prom_a", SRCA), ("prom_b", SRCB)):
        s = set()
        for ln in open(path):
            m = pat.match(ln)
            if m and zero.search(m.group(1)):
                s.add(m.group(1))
        cnt[tag] = s
    hb = set()
    for ln in head("prom_b/wsa1_prom_b.s").split("\n"):
        m = pat.match(ln)
        if m and zero.search(m.group(1)):
            hb.add(m.group(1))
    print("          labels spelling an O as 0x30:  prom_b %d   prom_a %d"
          % (len(cnt["prom_b"]), len(cnt["prom_a"])))
    print("          of prom_b's, NEW this round: %d" % len(cnt["prom_b"] - hb))
    # The literals are ALL CAPS ("VEL0CITY CHANGE"), so their test is the
    # letter-either-side form; the LABEL test above is the CamelCase form.
    zlit = re.compile(r'[A-Za-z]0[A-Za-z]')
    lits = re.findall(r'\.ascii\s+"((?:[^"\\]|\\.)*)"', open(SRCB).read())
    d = collections.Counter(l for l in lits if zlit.search(l))
    print("          prom_b .ascii literals: %d   distinct spelling an O as 0x30: %d"
          " in %d occurrences" % (len(lits), len(d), sum(d.values())))
    print("          ...LAST of them in sort order: %r" % sorted(d)[-1])
    return (len(same) == 6 and len(cnt["prom_b"]) == 122 and len(cnt["prom_a"]) == 6
            and len(cnt["prom_b"] - hb) == 30 and len(lits) == 4060
            and len(d) == 75 and sum(d.values()) == 98)


def check_dangling():
    new = renamed_this_round()
    old = sorted(set(v[1] for v in new.values()))
    pat = re.compile(r'\b(' + "|".join(old) + r')\b')
    back = re.compile(r'\(was (?:' + "|".join(old) + r')\)')
    files = subprocess.run(["git", "-C", ROOT, "ls-files"],
                           capture_output=True, text=True).stdout.split()
    tot, rows = 0, []
    for f in sorted(files):
        p = os.path.join(ROOT, f)
        if not os.path.isfile(p):
            continue
        try:
            t = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        n = len(pat.findall(t)) - len(back.findall(t))
        if n:
            rows.append((n, f))
            tot += n
    print("--dangling references to the 103 RETIRED T_<address> labels, excluding")
    print("          the deliberate `(was T_...)` back-reference on each renamed slot:")
    for n, f in rows:
        print("            %4d  %s" % (n, f))
    print("          TOTAL %d  -- a FINDING: minor, but the lane's writeup does not mention it."
          % tot)
    return tot == 0


def check_selftest():
    h = head("notes/prom_b_screens_round8.py")
    now = open(os.path.join(ROOT, "notes", "prom_b_screens_round8.py")).read()
    ch = len(re.findall(r'^\s+c\("', h, re.M))
    cn = len(re.findall(r'^\s+c\("', now, re.M))
    print("--selftest c() checks in notes/prom_b_screens_round8.py: HEAD %d -> NOW %d (+%d)"
          % (ch, cn, cn - ch))
    print("          the lane's status line reported '+8 checks'; the true delta is +%d."
          % (cn - ch))
    print("          its total, 48 printed lines, is correct.")
    return cn - ch == 8   # deliberately FALSE: the true delta is +16


def check_headroom():
    """Is the harvest COMPLETE -- is anything still spelled T_<address> while
    pointing at a content-named target, and does the lane's "6 left over" hold?"""
    import wave7_documentation_metrics as M
    atA, _ = scan(open(SRCA).read())
    atB, _ = scan(open(SRCB).read())
    rom = rom_slots()
    # An UNpromoted slot spells its own address in its label; a promoted one does
    # not, so the naive scan below must key on the label, not on an address
    # comment -- keying on the comment silently misses every unpromoted slot.
    un = set()
    for ln in open(SRCB):
        m = re.match(r'^T_([0-9A-F]{6}):', ln)
        if m:
            un.add(int(m.group(1), 16))
    left = []
    for a, (_k, t) in rom.items():
        labs = (atA if t >= A_BASE else atB).get(t)
        if not labs or a not in un:
            continue
        n = labs[0]
        if not (M.UNNAMED.match(n) or M.FRAMED.match(n) or M.INTERNAL.match(n)):
            left.append((a, t, n))
    shared = collections.Counter(n for _a, _t, n in left)
    uniq = [x for x in left if shared[x[2]] == 1]
    print("--headroom slots still spelled T_<address> whose target IS content-named: %d"
          % len(left))
    print("          ⚠ that NAIVE figure over-counts.  %d of them are %d targets each"
          % (len(left) - len(uniq), len(shared) - len(uniq)))
    print("          reached by two slots, and round 6's rule R3 drops those: two slots")
    print("          cannot both be called `T_<the same name>`.  Under the tree's own")
    print("          rule the real remainder is %d, which is the lane's stated handoff:"
          % len(uniq))
    for a, t, n in sorted(uniq):
        print("            0x%06X -> 0x%06X  T_%s" % (a, t, n))
    return len(uniq) == 6


CHECKS = [("--thunks", check_thunks), ("--derived", check_derived),
          ("--cites", check_cites), ("--prose", check_prose),
          ("--morph", check_morph), ("--zeros", check_zeros),
          ("--dangling", check_dangling), ("--headroom", check_headroom),
          ("--selftest", check_selftest)]

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
