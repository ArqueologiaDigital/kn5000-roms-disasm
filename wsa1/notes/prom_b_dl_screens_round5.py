#!/usr/bin/env python3
"""Name prom_b's still-FRAMED display lists from what they PUT ON THE SCREEN.

QUESTION IT ANSWERS
    "Round 4 named 229 of prom_b's 672 `DL_<address>` labels from the `.ascii`
     records inside them, and left 443 FRAMED because those lists carry no text
     of their own.  Which of the 443 can still be named -- and by WHICH
     mechanism -- and which cannot?"

★ THE THESIS, UNCHANGED FROM ROUND 4
    NAME AN OBJECT FROM WHAT IT CONTAINS, OR FROM WHAT READS IT.  This file adds
    two more ways for a display list to contain its own name, and one way for
    the screen around it to supply one.  Nothing here is inference: every name
    is a string that this list causes to appear on the screen, or the caption
    the value is printed immediately after.

────────────────────────────────────────────────────────────────────────────────
THE FOUR MECHANISMS, STRONGEST FIRST.  A list is named by the first that reaches
it; everything else keeps `DL_<address>` and a stated gap.
────────────────────────────────────────────────────────────────────────────────

M1  OWN TEXT, USED TO THE END.
    Round 4's `--dl-names` accumulated CamelCase from the list's own `.ascii`
    literals and STOPPED at 24 characters (`SLUG_MIN`), so two lists whose text
    begins the same way produced the same name and both were left framed.  48 of
    the 443 do carry text.  This file keeps accumulating from the SAME literals
    until the name is unique.  No new evidence -- the same evidence, read to the
    end of the list instead of the first 24 characters.
    ⚠ 38 of the 48 are left framed anyway: their WHOLE text is identical to
    another list's (nine lists whose only word is `OK`, six `YES`/`NO`, three
    `SAVE`, two `Please set the Password.`, ...).  Extending cannot separate two
    lists that draw the same words; nothing in the list says which screen it
    belongs to, so nothing here names them.

M2  THE OPERAND TABLE'S TEXT.
    An interpreter-B record draws a LIVE VARIABLE, not a literal: it carries the
    variable's 16-bit address at `+2` and, for the string-table opcodes, a 32-bit
    pointer to the table of NAMES the value indexes (`FINDINGS-ui-display-list.md`,
    "The second interpreter").  When that table is a table of names -- `MULTI`
    `SINGLE` `OMNI`, `NORMAL` `TECH` `REMAP`, the 64 resonator names of
    `DLTable_F03241` -- those names are what the list puts on the screen, one at
    a time.  Same claim as M1, one level of indirection.
    ⚠ 22 of the lists this reaches would be called `DL_OffOn` -- eight of them
    through `DLTable_F0CE75` and fourteen through `StringTable_F197EC` -- and a
    further seven `DL_IntOff`, so most of them collide and stay framed.  A name
    23 lists could have is not a name.

M3  THE CAPTION THE VALUE ABUTS.  ★ THIS ONE IS ARITHMETIC, NOT PROXIMITY.
    An interpreter-A text record whose handler is `0xF31A3A` carries ONE 16-bit
    screen position at `+2` and `length - 4` characters after it; an
    interpreter-B readout carries its own position in the field the `.s` already
    annotates `-> IX`.  On the MIDI screen at 0xF0CA19:

        caption  IX 0x06E6  "MIDI INPUT MODE : "   18 chars -> ends at 0x06F8
        readout  IX 0x06F8                          <-- exactly there

    The readout starts on the byte the caption ends on, so the value is printed
    into that caption's field.  The arithmetic is exact: `pos + (len-4) == IX`,
    no tolerance, no window.  Successive rows differ by 0x3C0 = 960 = 12 screen
    rows of 80 bytes, which is why a row's caption and its value never collide
    with the row above.
    ⚠ AND THE CAPTION POOL IS SCOPED TO THE SCREEN.  A file-wide search matches
    coincidences across screens -- it offered the German word "Bitte" and a
    fragment of a French sentence as field names.  The pool used here is only the
    text of the OTHER lists run by the SAME ROUTINE as this one, taken from the
    call-site census in `notes/prom_b_dl_call_shapes.py`.  `--census` prints how
    many lists each restriction costs.

⚠ TWO RELAXATIONS MEASURED AND REJECTED, so a later round does not re-invent them
    (both are re-measured by `--selftest`, which prints their yield):
      * searching the caption FILE-WIDE instead of within the screen reaches 61
        lists instead of 9 and offers the German word "Bitte" and a fragment of a
        French sentence as field names;
      * relaxing "ends exactly here" to "the nearest caption to the LEFT on the
        same 80-byte row" adds NINE lists, and what it gives them is "--", "K",
        "dB", "OK" and a "SELECT" 42 bytes away.  Six of the nine are not even
        captions; the rule buys nothing and costs the exactness.

M4  THE OPERAND TABLE NAMES ITSELF.  ★ AND IT IS THE SAME MECHANISM AGAIN.
    The tables M2 reads are themselves FRAMED labels -- `DLTable_F03241`,
    `StringTable_F1828A`, `Text_F6E34D` -- a kind plus an address, on objects
    whose entire content is a list of words the machine puts on the screen.
    `--tables` names them from those words, exactly as round 4 named the lists:
    `DLTable_F03241` holds ORIGINAL / STRING / CYLINDER / CONE ... and becomes
    `DLTable_OriginalStringCylinder`.  The structural KIND is kept, because it is
    true and useful; only the address is replaced by the content.
    ⚠ `MsgTail_*` is excluded.  The tree's own name says the object is the TAIL of
    a message, so its first characters are the middle of a word: `MsgTail_F2F2AF`
    begins "rmat0 file".  A name built from that says nothing.

M5  NOTHING.  Kept `DL_<address>`, which is the honest output.  The four reasons
    are counted separately by `--census`: no call site at all, a call site whose
    routine runs no other named list, a caption pool with no caption ending where
    this list starts printing, and a name that collides with another list's.

────────────────────────────────────────────────────────────────────────────────
WHAT A NAME FROM THIS FILE CLAIMS, AND WHAT IT DOES NOT
────────────────────────────────────────────────────────────────────────────────
    It claims the list DRAWS those words (M1, M2) or prints its value into the
    field that caption labels (M3).  It does NOT claim to know what the value
    means, which page of a screen it is on, or what the routine that runs it is
    for.  Those routines stay `sub_XXXXXX`.
    The ROM writes the digit 0 for the letter O in several captions ("S0NG",
    "P0SITI0N", "C0MBINATI0N"); the names keep that spelling rather than silently
    correcting the ROM, exactly as round 4 did.

RUN
    python3 notes/prom_b_dl_screens_round5.py            # the census + proposals
    python3 notes/prom_b_dl_screens_round5.py --tables   # M4, the operand tables
    python3 notes/prom_b_dl_screens_round5.py --tables --apply
    python3 notes/prom_b_dl_screens_round5.py --census   # only the counts
    python3 notes/prom_b_dl_screens_round5.py --why DL_F3ACF0
    python3 notes/prom_b_dl_screens_round5.py --selftest # every number above
    python3 notes/prom_b_dl_screens_round5.py --apply    # rewrite the .s
`--apply` is idempotent: a name it has already applied is no longer a
`DL_<address>` label and is simply not a candidate on the next run.
"""
import bisect
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
SRCB = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")

LAB = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
FRAMED_DL = re.compile(r'^DL_([0-9A-F]{6})$')
ASC = re.compile(r'\.ascii\s+"([^"]*)"')
QUOTE = re.compile(r"'([^']*)'")
SHORT = re.compile(r'\.short\s+0x([0-9A-Fa-f]{4})')
LONG = re.compile(r'\.long\s+0x00([0-9A-F]{6})')
ADDRC = re.compile(r';\s*([0-9A-F]{6})\s')
IXLINE = re.compile(r'\.short\s+0x([0-9A-Fa-f]{4})\s*;\s*\+0x[0-9A-Fa-f]{2}\s*->\s*IX')
# `.byte 0x20, 0x16   ; op 20, 22 bytes -> handler 0xF31A3A`  (a leading `B ` marks
# an interpreter-B record; the caption scan wants interpreter A only)
RECHDR = re.compile(r'\.byte\s+0x([0-9A-Fa-f]{2}),\s*0x([0-9A-Fa-f]{2})\s*;\s*'
                    r'(B )?op ([0-9A-Fa-f]{2}), (\d+) bytes -> handler 0x([0-9A-F]{6})')
TEXT_HANDLER = "F31A3A"        # +2 word -> IX, +4.. characters (BC = len-4)
SLUG_MIN = 24                  # round 4's threshold, kept so M1 extends rather than shortens
SLUG_MAX = 60
_c = {}


# ----------------------------------------------------------------- the source
def lines():
    if "src" not in _c:
        _c["src"] = open(SRCB).read().split("\n")
    return _c["src"]


def blocks():
    """{label: (first line after the label, end line)} for every column-0 label.

    The end is the next label or the next `; --- ` section rule, so a block holds
    the label's OWN bytes and nothing else's."""
    if "blk" in _c:
        return _c["blk"]
    src = lines()
    idx = [i for i, l in enumerate(src) if LAB.match(l)]
    out = {}
    for k, i in enumerate(idx):
        j = idx[k + 1] if k + 1 < len(idx) else len(src)
        for m in range(i + 1, j):
            if src[m].startswith("; ---"):
                j = m
                break
        out[LAB.match(src[i]).group(1)] = (i, j)
    _c["blk"] = out
    return out


def dl_address(name, i):
    """The ROM address of a DL label: from its own name when framed, otherwise
    from the `0x......` its header block already carries."""
    m = FRAMED_DL.match(name)
    if m:
        return int(m.group(1), 16)
    src = lines()
    for j in range(i - 1, max(-1, i - 30), -1):
        if not src[j].startswith(";"):
            break
        mm = re.search(r'0x([0-9A-F]{6})', src[j])
        if mm:
            return int(mm.group(1), 16)
    return None


def dl_labels():
    """{label: address} for every DL_ label whose address is recoverable."""
    if "dl" in _c:
        return _c["dl"]
    out = {}
    for n, (i, _j) in blocks().items():
        if not n.startswith("DL_"):
            continue
        a = dl_address(n, i)
        if a is not None:
            out[n] = a
    _c["dl"] = out
    return out


def _has_text(t, minletters):
    return bool(re.search(r"[A-Za-z]{2}", t)) if minletters >= 2 \
        else bool(re.search(r"[A-Za-z]", t))


def literals(name, quoted=False, minletters=2):
    """The list's own text: `.ascii` payloads with two adjacent letters.

    `quoted=True` also reads the `'TEXT'` the `.s` prints in the trailing comment
    of a `.byte` row -- that is how StringTable_* objects are rendered, and
    without it an operand table of names looks empty.

    ⚠ THE DEFAULT TEST IS TWO *ADJACENT* LETTERS, AND IT IS NOT COSMETIC.
    Round 4's emitter documents why: a printable run inside a display list is
    often a coordinate and an opcode, not text.  A draft of this file counted
    letters anywhere in the run instead, and immediately proposed `DL_V6fV6f`
    from the four bytes `V#6F`.  `minletters=1` (one letter, anywhere) is used
    ONLY for the operand tables of M4, where every entry is by construction a
    string and a two-letter rule threw away `P10`, `P18` and `P26`."""
    src, (i, j) = lines(), blocks()[name]
    out = []
    for ln in src[i + 1:j]:
        for t in ASC.findall(ln):
            t = t.strip()
            if _has_text(t, minletters):
                out.append(t)
        if quoted and ".byte" in ln:
            for t in QUOTE.findall(ln):
                t = t.strip()
                if _has_text(t, minletters):
                    out.append(t)
    return out


def camel(s):
    return "".join(w[0].upper() + w[1:].lower()
                   for w in re.split(r"[^A-Za-z0-9]+", s) if w)


# --------------------------------------------------- captions and readouts
def captions(name):
    """[(end_position, text)] for the interpreter-A text records of one list.

    end_position = the record's `+2` word plus `length - 4` characters, i.e. the
    screen byte the caption stops writing at.  Bytes below 0x20 inside a payload
    are custom glyphs (FINDINGS-ui-display-list.md, "The character set"); the
    `.s` prints them as a `.byte` row marked `character codes below 0x20` and
    they are COUNTED, because the handler passes them to the same service."""
    src, (i, j) = lines(), blocks()[name]
    out, k = [], i
    while k < j:
        m = RECHDR.search(src[k])
        if m and m.group(6) == TEXT_HANDLER and not m.group(3):
            ln, pos, txt = int(m.group(5)), None, ""
            p = k + 1
            while p < j and p < k + 6:
                s = SHORT.search(src[p])
                if pos is None and s:
                    pos = int(s.group(1), 16)
                    p += 1
                    continue
                a = ASC.search(src[p])
                if a:
                    txt += a.group(1)
                    p += 1
                    continue
                if ".byte" in src[p] and "character codes" in src[p]:
                    p += 1
                    continue
                break
            if pos is not None and txt.strip():
                out.append((pos + ln - 4, txt))
        k += 1
    return out


def readouts(name):
    """The screen positions of the interpreter-B readout records of one list,
    taken from the `-> IX` annotation the `.s` already carries."""
    src, (i, j) = lines(), blocks()[name]
    return [int(m.group(1), 16)
            for k in range(i + 1, j) for m in [IXLINE.search(src[k])] if m]


def byaddr():
    """{ROM address: label} for every labelled object, resolved so that it keeps
    working AFTER `--tables` has taken the address out of the name.

    ⚠ THIS WAS A REAL BUG.  The first version read the address out of the label
    text, so the moment `--tables` renamed `DLTable_F03241` the M2 mechanism
    stopped finding any operand table at all and the file quietly lost half its
    evidence.  Three sources are tried, in order: the address still in the name;
    the `renamed from <Kind>_<ADDR>` line this file writes; and any `0xADDRESS`
    in the header block above the label."""
    if "byaddr" in _c:
        return _c["byaddr"]
    src, out = lines(), {}
    for n, (i, _j) in blocks().items():
        m = re.match(r'^[A-Za-z_][A-Za-z0-9]*_([0-9A-F]{6})$', n)
        if m:
            out[int(m.group(1), 16)] = n
            continue
        # ⚠ THE BLOCK IS JOINED BEFORE IT IS SEARCHED.  textwrap breaks
        # "renamed from DLTable_F03241" across two comment lines, so a per-line
        # search finds neither the phrase nor the address and the whole M2
        # mechanism goes silent.
        blk, k = [], i - 1
        while k >= 0 and (src[k].startswith(";") or not src[k].strip()):
            blk.append(src[k].lstrip("; ").rstrip())
            k -= 1
        joined = " ".join(reversed(blk))
        mm = re.search(r'renamed from [A-Za-z_][A-Za-z0-9]*_([0-9A-F]{6})', joined) \
            or re.search(r'0x([0-9A-F]{6})', joined)
        if mm:
            out.setdefault(int(mm.group(1), 16), n)
    _c["byaddr"] = out
    return out


def operand_tables(name):
    """[(label, [entry, ...])] for the `.long` operands of one list that name a
    labelled object whose entries are TEXT."""
    src, (i, j) = lines(), blocks()[name]
    byaddr()
    seen, out = [], []
    for k in range(i + 1, j):
        for x in LONG.findall(src[k]):
            nm = byaddr().get(int(x, 16))
            if nm and nm not in seen and nm != name:
                seen.append(nm)
    for nm in seen:
        lit = literals(nm, quoted=True)
        if lit:
            out.append((nm, lit))
    return out


# ------------------------------------------------------- the call-site census
def code_labels(img):
    src = open(os.path.join(ROOT, "prom_%s" % img,
                            "wsa1_prom_%s.s" % img)).read().split("\n")
    order, pend = [], []
    for ln in src:
        m = LAB.match(ln)
        if m:
            pend.append(m.group(1))
            continue
        a = ADDRC.search(ln)
        if a and pend:
            ad = int(a.group(1), 16)
            for nm in pend:
                order.append((ad, nm))
            pend = []
    order.sort()
    return order


def screens():
    """({list address: {routine, ...}}, {routine: {list address, ...}}).

    The routine is the nearest label at or below the call site, over the four
    call shapes of notes/prom_b_dl_call_shapes.py.  Two lists run by the same
    routine are on the same screen; that is the whole of the claim."""
    if "scr" in _c:
        return _c["scr"]
    import prom_b_dl_call_shapes as CS
    import prom_b_display_lists as DLM
    oa, ob = code_labels("a"), code_labels("b")
    ka, kb = [x[0] for x in oa], [x[0] for x in ob]

    def encl(a):
        k, o = (ka, oa) if a >= 0xF80000 else (kb, ob)
        i = bisect.bisect_right(k, a) - 1
        return o[i][1] if i >= 0 else "?"

    a, b = DLM.load()
    of, by = collections.defaultdict(set), collections.defaultdict(set)
    for _sh, site, s, _e, _t in CS.scan(a, b):
        r = encl(site)
        of[s].add(r)
        by[r].add(s)
    _c["scr"] = (of, by)
    return _c["scr"]


# ------------------------------------------------------------- the proposals
def slugs(lit, cap=SLUG_MAX):
    """Every prefix of the CamelCase accumulation, shortest first."""
    out, s = [], ""
    for t in lit:
        s += camel(t)
        out.append(s[:cap])
        if len(s) >= cap:
            break
    return out


def taken_names():
    return set(blocks())


METRIC_FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                           r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                           r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')


def is_caption(s):
    """Is this text a FIELD CAPTION rather than a fragment of prose?

    ⚠ MEASURED, NOT ASSUMED.  Without this test the screen-scoped abutment
    offered `dB`, `from` and `A current` as field names -- the first two are
    units and the third is three characters of a sentence in a warning box that
    happen to stop on the byte a value starts at.  Every real caption in this
    ROM is UPPER CASE (`TIME SIG.=`, `LAST MEASURE    :`, `P0SITI0N  :`), and
    prose in the warning boxes is mixed case, so the rule is: at least three
    letters, and every letter upper case."""
    L = re.findall(r"[A-Za-z]", s)
    return len(L) >= 3 and all(c.isupper() for c in L)


def field_captions(name, of, by, addr2name, dl):
    """[(position, caption text)] for this list's interpreter-B readouts, where a
    caption of ANOTHER list on the SAME SCREEN stops writing exactly there."""
    ro = readouts(name)
    if not ro:
        return None, "no interpreter-B readout"
    pool = {}
    for r in of.get(dl.get(name), ()):
        for other in by[r]:
            onm = addr2name.get(other)
            if onm and onm != name:
                for e, t in captions(onm):
                    pool.setdefault(e, set()).add(t.strip())
    if not pool:
        return None, "no caption pool"
    got, seen = [], set()
    for x in ro:
        t = pool.get(x)
        if t and len(t) == 1:
            s = next(iter(t))
            if is_caption(s) and camel(s) not in seen:
                seen.add(camel(s))
                got.append((x, s))
    if not got:
        return None, "no caption ends where this list prints"
    return got, None


def trim_camel(s, n):
    """Truncate a CamelCase slug at a word boundary, never mid-word."""
    if len(s) <= n:
        return s
    cuts = [m.start() for m in re.finditer(r'[A-Z]', s) if 0 < m.start() <= n]
    return s[:cuts[-1]] if cuts else s[:n]


def screen_slug(n, of, by, addr2name, dl):
    """The name of THE ONE content-named list on the same screen, as a prefix of
    last resort.  It says WHICH SCREEN and nothing else.

    ⚠ TWO GUARDS, BOTH FOUND BY LOOKING AT WHAT THIS RETURNED WITHOUT THEM.
    (a) A sibling whose own name is still framed is not used -- borrowing
        `DL_InternalSound_F18A1D` into a name puts the address straight back.
    (b) THE SIBLING MUST BE THE ONLY CONTENT-NAMED ONE.  The "routine" here is
        the nearest label at or below the call site, and for the 0xF7Dxxx sites
        that is `StubBlock_F7D000`, which covers a whole module: 60 lists from a
        dozen different screens.  Picking the longest of those as "the screen"
        gave `DL_AfterT0uchSettingSelectS0ng` to a list on the SONG screen.  When
        more than one content-named list shares the routine, this returns
        nothing and the list keeps its address.
    (c) A sibling THIS FILE named is not used either.  Without that, a second
        `--apply` builds a name on a name the first one invented -- a chain with
        no new evidence behind it -- and the pass stops being idempotent."""
    best = set()
    for r in of.get(dl.get(n), ()):
        for other in by[r]:
            onm = addr2name.get(other)
            if onm and onm != n and not FRAMED_DL.match(onm) \
                    and not METRIC_FRAMED.match(onm) and onm not in named_here():
                best.add(onm[3:])
    if len(best) != 1:
        return None
    return trim_camel(sorted(best)[0], 28)


def proposals():
    """{label: (new name, mechanism, [evidence, ...])} plus the census.

    ★ THE AWARD IS BY UNIQUENESS, NOT BY WHO ASKS FIRST.  Every list offers an
    ORDERED list of candidate names, strongest mechanism first.  A name is
    awarded only in a round where exactly ONE list is still asking for it and no
    existing label has it; everyone else advances to their next candidate.  That
    is round 4's rule (`taken ONLY if the resulting name is unique`) applied to
    the candidates as well as to the file: 22 lists draw the same OFF/ON table,
    and handing `DL_OffOn` to whichever came first would say that one of them is
    THE off/on list."""
    if "prop" in _c:
        return _c["prop"]
    dl = dl_labels()
    framed = sorted(n for n in dl if FRAMED_DL.match(n))
    taken = set(taken_names())
    of, by = screens()
    addr2name = {v: k for k, v in dl.items()}
    own = {n: literals(n) for n in framed}
    fullslug = {n: slugs(v)[-1] for n, v in own.items() if v}
    dupe = collections.Counter(fullslug.values())
    tabs = {n: operand_tables(n) for n in framed if not own[n]}
    fields, fieldwhy = {}, {}
    for n in framed:
        if own[n]:
            continue
        g, w = field_captions(n, of, by, addr2name, dl)
        fields[n], fieldwhy[n] = g, w

    tries = {}
    for n in framed:
        t = []
        if own[n] and dupe[fullslug[n]] == 1:
            ev = ['"%s"' % x for x in own[n][:8]]
            for s in slugs(own[n]):
                if len(s) >= SLUG_MIN:
                    t.append(("DL_" + s, "M1", ev))
            if not t:
                t.append(("DL_" + fullslug[n], "M1", ev))
        cap = fields.get(n) or []
        tab = tabs.get(n) or []
        capslug = "".join(camel(x) for _p, x in cap)[:SLUG_MAX]
        words = []
        for _t, lit in tab:
            for x in lit:
                words.append(x)
                if len("".join(camel(w) for w in words)) >= SLUG_MIN:
                    break
            if len("".join(camel(w) for w in words)) >= SLUG_MIN:
                break
        tabslug = "".join(camel(w) for w in words)[:SLUG_MAX]
        capev = ['"%s" ends at 0x%04X' % (x, p) for p, x in cap[:6]]
        tabev = ["%s: %s" % (o, ", ".join('"%s"' % x for x in lit[:6]))
                 for o, lit in tab[:3]]
        ss = screen_slug(n, of, by, addr2name, dl)
        if capslug:
            t.append(("DL_" + capslug, "M3", capev))
        if capslug and tabslug:
            t.append(("DL_" + (capslug + tabslug)[:SLUG_MAX], "M3+M2", capev + tabev))
        if tabslug:
            t.append(("DL_" + tabslug, "M2", tabev))
        if ss and capslug:
            t.append(("DL_" + trim_camel(ss + capslug, SLUG_MAX), "M3+screen",
                      capev + ["on the screen of DL_%s, which shares this list's "
                               "painting routine" % ss]))
        if ss and tabslug:
            t.append(("DL_" + trim_camel(ss + tabslug, SLUG_MAX), "M2+screen",
                      tabev + ["on the screen of DL_%s, which shares this list's "
                               "painting routine" % ss]))
        tries[n] = t

    cand, pos = {}, dict((n, 0) for n in framed)
    # A SHORT name is REFUSED when an existing or already-awarded label extends
    # it: `DL_Page22` beside `DL_Page22KeyFollowSlopeRange` is a pair nobody can
    # tell apart at a glance.  ⚠ The rule is deliberately limited to names whose
    # slug is under 12 characters.  Applied to every length it also refused
    # `DL_MultiSingleOmni` because `DL_MultiSingle` exists -- two lists that draw
    # two DIFFERENT tables (three entries and two), where both names are exact.
    # Refusing an accurate name to avoid a similar-looking one is the wrong trade.
    def prefix_clash(nm, others):
        if len(nm) - 3 >= 12:
            return False
        for o in others:
            if o != nm and (o.startswith(nm) or nm.startswith(o)):
                return True
        return False

    progress = True
    while progress:
        progress = False
        ask = collections.defaultdict(list)
        for n in framed:
            if n in cand or pos[n] >= len(tries[n]):
                continue
            ask[tries[n][pos[n]][0]].append(n)
        pool = taken | set(v[0] for v in cand.values())
        for nm, who in sorted(ask.items()):
            if len(who) == 1 and nm not in pool and not prefix_clash(nm, pool):
                n = who[0]
                cand[n] = tries[n][pos[n]]
                pool.add(nm)                 # so two awards in ONE round cannot
                progress = True              # end up as A and A+B
        for n in framed:
            if n not in cand and pos[n] < len(tries[n]):
                pos[n] += 1
                progress = True

    why = collections.Counter()
    for n in framed:
        if n in cand:
            continue
        if own[n] and dupe[fullslug[n]] > 1:
            why["text identical to another list's, whole"] += 1
        elif tries[n]:
            why["every name its evidence yields is shared with another list"] += 1
        elif fieldwhy.get(n) == "no interpreter-B readout":
            why["no text, no readout: geometry only"] += 1
        elif fieldwhy.get(n) == "no caption pool":
            why["no call site, or no sibling list with text"] += 1
        else:
            why["no caption ends where this list prints"] += 1
    _c["prop"] = (cand, why, framed)
    return _c["prop"]


# ---------------------------------------------------- M4: the operand tables
TABLE_KINDS = ("DLTable", "DLBTable", "DLTab", "DLText", "StringTable", "Text",
               "Table")
TABLE_LABEL = re.compile(r'^(%s)_([0-9A-F]{6})$' % "|".join(TABLE_KINDS))


def table_proposals():
    """{label: (new name, [entry, ...])} for the FRAMED operand-table labels
    whose whole content is a list of words.

    The kind is kept and the address replaced: an object called `StringTable_`
    plus six digits is delimited and typed and nobody has said what is in it,
    and what is in it is printed two lines below the label."""
    if "tp" in _c:
        return _c["tp"]
    taken = set(taken_names())
    cand, lits = {}, {}
    for n in sorted(blocks()):
        m = TABLE_LABEL.match(n)
        if not m:
            continue
        # ⚠ minletters=1 HERE ONLY.  These objects are TABLES OF SHORT CODES:
        # StringTable_F18419 reads PT2 / P10 / P18 / P26, and the default
        # two-letter filter (which keeps M1 and M2 from quoting a coordinate
        # byte as text) threw away three of its four entries and named it after
        # the first.  Every entry of a table is content; a stray printable run
        # inside a display list is not, which is why the filter differs.
        L = literals(n, quoted=True, minletters=1)
        if not L:
            continue
        lits[n] = L
        s = ""
        for t in L:
            s += camel(t)
            if len(s) >= 20:
                break
        # ⚠ A THREE-CHARACTER FLOOR, and it was put here by a rename that had to
        # be undone: StringTable_F1A515 holds the two bytes 'o' and '-', so the
        # rule produced `StringTable_O`, which names nothing.  A slug shorter
        # than three characters is not a description of anything.
        slug = trim_camel(s, 44)
        if len(slug) < 3:
            continue
        cand[n] = (m.group(1) + "_" + slug, L)
    counts = collections.Counter(v[0] for v in cand.values())
    out = {}
    for n, (nm, L) in cand.items():
        if counts[nm] == 1 and nm not in taken:
            out[n] = (nm, L)
    _c["tp"] = (out, cand, lits, counts)
    return _c["tp"]


def tables(apply=False):
    out, cand, lits, counts = table_proposals()
    print("prom_b framed operand-table labels carrying text: %d" % len(cand))
    print("  named            : %d" % len(out))
    print("  left framed      : %d, because another table holds the same words"
          % (len(cand) - len(out)))
    for n in sorted(cand):
        mark = "->" if n in out else "  (collides)"
        print("  %-24s %s %-46s %s"
              % (n, mark, cand[n][0], " / ".join(lits[n][:4])[:44]))
    if not apply:
        print("\n(dry run; add --apply to rewrite prom_b/wsa1_prom_b.s)")
        return 0
    src = lines()
    ren = dict((o, v[0]) for o, v in out.items())
    if not ren:
        print("nothing to apply")
        return 0
    rx = re.compile(r"\b(%s)\b" % "|".join(sorted(ren)))
    res, k = [], 0
    for ln in src:
        m = LAB.match(ln)
        if m and m.group(1) in ren:
            old = m.group(1)
            new, L = out[old]
            res += wrap("; %s -- " % new,
                        "renamed from %s: the object's own entries are %s.%s"
                        % (old, "; ".join('"%s"' % x for x in L[:8]),
                           " +%d more" % (len(L) - 8) if len(L) > 8 else ""))
            res += wrap("; Evidence: ", "the text printed below this label IS "
                        "the object's whole content; the name is CamelCase of its "
                        "first entries and claims only what the object HOLDS -- "
                        "not what indexes it, and not what the words mean.  The "
                        "KIND is the one the tree already established and is "
                        "kept; only the address is replaced.  Generated by "
                        "notes/prom_b_dl_screens_round5.py --tables --apply.")
            res.append(new + ":" + ln[m.end():])
            k += 1
            continue
        if "_F" in ln:
            ln = rx.sub(lambda mm: ren[mm.group(1)], ln)
        res.append(ln)
    open(SRCB, "w").write("\n".join(res))
    print("renamed %d operand tables in %s" % (k, SRCB))
    print("⚠ run  python3 scripts/analysis/assert_byte_identical.py  now")
    return 0


# ------------------------------------------------------------------- reports
def census():
    cand, why, framed = proposals()
    withtext = sum(1 for n in framed if literals(n))
    ro = sum(1 for n in framed if not literals(n) and readouts(n))
    print("prom_b FRAMED display lists (DL_<address>): %d" % len(framed))
    print("  carrying text of their own                : %d" % withtext)
    print("  no text, but an interpreter-B readout     : %d" % ro)
    print("  no text and no readout                    : %d"
          % (len(framed) - withtext - ro))
    print()
    for m in sorted(set(v[1] for v in cand.values())):
        k = [n for n, v in cand.items() if v[1] == m]
        print("  %s named %3d" % (m, len(k)))
    print("  ---------------")
    print("  NAMED     %3d of %d (%.1f%%)"
          % (len(cand), len(framed), 100.0 * len(cand) / len(framed)))
    print("  left FRAMED %d, by reason:" % (len(framed) - len(cand)))
    for k, v in why.most_common():
        print("      %-58s %4d" % (k, v))
    return 0


def show(name):
    cand, _why, _f = proposals()
    if name not in cand:
        print("%s: not named by any mechanism" % name)
        return 1
    nm, m, ev = cand[name]
    print("%s -> %s   [%s]" % (name, nm, m))
    for e in ev:
        print("    %s" % e)
    return 0


EV = {
    "M1": ("the `.ascii` literals printed below this label, which the display-list "
           "interpreter draws verbatim.  Round 4 stopped its CamelCase at 24 "
           "characters and this list collided; the name is the SAME literals read "
           "further, and says what the list PUTS ON THE SCREEN and nothing more."),
    "M2": ("this list has no text of its own.  Its interpreter-B records name the "
           "table below by a 32-bit operand, and that table holds the NAMES the "
           "drawn value indexes, so those names are what the list puts on the "
           "screen -- one of them at a time."),
    "M3": ("this list has no text of its own.  Each of its interpreter-B records "
           "prints at a screen position that is EXACTLY where a caption of "
           "another list on the same screen stops writing (caption `+2` word plus "
           "`length - 4` characters), so the value goes in that caption's field.  "
           "The captions are quoted above with the position they end on; the "
           "screen is the set of lists run by the SAME routine, per "
           "notes/prom_b_dl_call_shapes.py."),
}


def wrap(prefix, text, width=78):
    import textwrap
    body = textwrap.wrap(text, width - len(prefix)) or [""]
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def apply_():
    cand, _why, framed = proposals()
    if not cand:
        print("nothing to apply")
        return 0
    src = lines()
    ren = dict((o, v[0]) for o, v in cand.items())
    rx = re.compile(r"\b(%s)\b" % "|".join(sorted(ren)))
    out, k = [], 0
    for ln in src:
        m = LAB.match(ln)
        if m and m.group(1) in ren:
            old = m.group(1)
            new, mech, ev = cand[old]
            addr = dl_labels()[old]
            out += wrap("; %s -- " % new,
                        "the display list at 0x%06X, named by mechanism %s of "
                        "notes/prom_b_dl_screens_round5.py.  %s"
                        % (addr, mech, "  ".join(ev)))
            out += wrap("; Evidence: ", EV[mech] +
                        "  Generated by notes/prom_b_dl_screens_round5.py --apply.")
            out.append(new + ":" + ln[m.end():])
            k += 1
            continue
        if "DL_F" in ln:
            ln = rx.sub(lambda mm: ren[mm.group(1)], ln)
        out.append(ln)
    open(SRCB, "w").write("\n".join(out))
    print("renamed %d display lists in %s" % (k, SRCB))
    print("⚠ run  python3 scripts/analysis/assert_byte_identical.py  now")
    return 0


# ------------------------------------------------------------------ selftest
FAIL = []
MARKER = "prom_b_dl_screens_round5.py"


def named_here():
    """The labels this file has already renamed, from the marker it writes into
    every header it generates.  --selftest uses this so its numbers are
    INVARIANTS rather than pins that break the moment --apply succeeds -- the
    failure mode notes/wave7_documentation_metrics.py documents ("a constant
    pinned to a number that is supposed to move").
    ⚠ TWO THINGS THIS GOT WRONG, BOTH CAUGHT BY --selftest.
    (a) The marker is matched per HEADER BLOCK, not per line: textwrap breaks the
        sentence that carries it, and counting lines gave 20 for 28 renames.
    (b) The file NAME alone is not a marker.  notes/gen_prom_b_f353ab_module.py
        cites this file in the header it writes for DL_YesAreYouSure, so the
        count went to 29 and the invariant 415 + 28 = 443 failed by one.  A block
        counts only if it also carries one of the two phrases THIS file's
        appliers write."""
    if "nh" not in _c:
        src, out = lines(), set()
        for n, (i, _j) in blocks().items():
            blk, k = [], i - 1
            while k >= 0 and (src[k].startswith(";") or not src[k].strip()):
                blk.append(src[k].lstrip("; ").rstrip())
                k -= 1
            j2 = " ".join(reversed(blk))
            if MARKER in j2 and ("named by mechanism" in j2 or "renamed from" in j2):
                out.add(n)
        _c["nh"] = out
    return _c["nh"]


def applied():
    return len(named_here())


def label_at(addr):
    """The label this ROM address carries NOW, whatever it has been renamed to."""
    for n, a in dl_labels().items():
        if a == addr:
            return n
    return None


def chk(desc, got, want):
    ok = got == want
    print(("  ok    " if ok else "  FAIL  ") + desc)
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    return ok


def selftest():
    del FAIL[:]
    dl = dl_labels()
    framed = sorted(n for n in dl if FRAMED_DL.match(n))
    cand, why, fr2 = proposals()
    chk("every DL_<address> label is either named or counted as left framed",
        len(fr2), len(cand) + sum(why.values()))
    dln = sum(1 for n in named_here() if n.startswith("DL_"))
    chk("framed display lists now (%d) plus the ones this file has renamed (%d) "
        "is the 443 this round started from" % (len(framed), dln),
        len(framed) + dln, 443)
    chk("no proposed name collides with an existing label",
        [v[0] for v in cand.values() if v[0] in blocks()], [])
    chk("no two proposals share a name",
        len(set(v[0] for v in cand.values())), len(cand))
    chk("no proposed name would still grade FRAMED (a numeric or hex tail)",
        [v[0] for v in cand.values() if METRIC_FRAMED.match(v[0])], [])
    chk("every proposal keeps the DL_ prefix and is a legal label",
        [v[0] for v in cand.values()
         if not re.match(r'^DL_[A-Za-z][A-Za-z0-9]*$', v[0])], [])

    # ---- M3's arithmetic, on the MIDI screen: the FIRST row and the LAST row
    caps = dict((e, t) for e, t in captions(label_at(0xF0C964)))
    chk("M3  the caption 'MIDI INPUT MODE : ' ends at 0x06F8",
        caps.get(0x06F8), "MIDI INPUT MODE : ")
    chk("M3  ...and DL_F0CA2F's only readout prints exactly there",
        readouts(label_at(0xF0CA2F)), [0x06F8])
    chk("M3  the LAST caption of that screen, 'SINGLE CH PROG CHANGE: ', "
        "ends at 0x19BD", caps.get(0x19BD), "SINGLE CH PROG CHANGE: ")
    chk("M3  ...and DL_F0CA7A's only readout prints exactly there",
        readouts(label_at(0xF0CA7A)), [0x19BD])
    # ⚠ CORRECTED BY THIS CHECK.  The first draft asserted the five caption ENDS
    # were 0x3C0 apart; they are not, because a caption's end is its start plus
    # its own length and the five captions are not the same length (0x3C5 and
    # 0x780 also appear).  It is the STARTS that lie on the row grid, and the
    # fourth row is two grid steps below the third because that screen leaves a
    # row blank.
    starts = []
    src2, (i2, j2) = lines(), blocks()[label_at(0xF0C964)]
    k2 = i2
    while k2 < j2:
        m2 = RECHDR.search(src2[k2])
        if m2 and m2.group(6) == TEXT_HANDLER and not m2.group(3):
            s2 = SHORT.search(src2[k2 + 1])
            if s2:
                starts.append(int(s2.group(1), 16))
        k2 += 1
    chk("M3  the five caption STARTS of that screen are on a 0x3C0 grid, with "
        "one blank row", starts, [0x06E6, 0x0AA6, 0x0E66, 0x15E6, 0x19A6])
    chk("M3  ...i.e. the row pitch is 0x3C0 and the one gap is exactly twice it",
        sorted(set(b - a for a, b in zip(starts, starts[1:]))), [0x3C0, 0x780])
    # the whole point of the caption rule: it is EXACT, so a shift of one byte
    # must find nothing
    off = sum(1 for x in readouts(label_at(0xF3ACF0)) if (x + 1) in caps or (x - 1) in caps)
    chk("M3  shifting a readout by one byte matches no caption (the rule has no "
        "tolerance and needs none)", off, 0)

    # ---- M1: the pair round 4 could not separate
    chk("M1  DL_F04415 and DL_F04B6C share their first 24 characters of text",
        slugs(literals(label_at(0xF04415)))[-1][:24] == slugs(literals(label_at(0xF04B6C)))[-1][:24],
        True)
    chk("M1  ...and differ once the whole text is read",
        slugs(literals(label_at(0xF04415)))[-1] == slugs(literals(label_at(0xF04B6C)))[-1], False)
    if "DL_F04415" in cand:
        chk("M1  ...so both are named by M1, and the names differ",
            (cand["DL_F04415"][0] != cand["DL_F04B6C"][0],
             cand["DL_F04415"][1], cand["DL_F04B6C"][1]), (True, "M1", "M1"))
    else:
        chk("M1  ...and both are already renamed, to two different names",
            (label_at(0xF04415) != label_at(0xF04B6C),
             bool(FRAMED_DL.match(label_at(0xF04415)))), (True, False))

    # ---- M2, on the resonator table the tree had already decoded
    # ⚠ Addressed by ROM ADDRESS, not by label: --tables renames the table
    # itself, so a check spelled `DLTable_F03241` breaks the moment the file
    # succeeds at its own second job.
    tabs = operand_tables(label_at(0xF0302A))
    chk("M2  the list at 0xF0302A names exactly one operand table, the one at "
        "0xF03241", [_c["byaddr"].get(0xF03241)], [t for t, _l in tabs])
    chk("M2  ...whose FIRST entry is ORIGINAL and whose entry count is 64",
        (tabs[0][1][0], len(tabs[0][1])), ("ORIGINAL", 64))

    # ---- the three reasons a list is left framed, each reproduced
    own = dict((n, literals(n)) for n in framed if literals(n))
    full = dict((n, slugs(v)[-1]) for n, v in own.items())
    d = collections.Counter(full.values())
    chk("38 text-bearing lists have text IDENTICAL to another list's",
        sum(1 for n in full if d[full[n]] > 1), 38)
    chk("...and the biggest such group is the nine lists whose only word is OK",
        d.most_common(1)[0], ("Ok", 9))
    # ⚠ CORRECTED BY THIS CHECK.  The first draft said "22 lists draw the same
    # OFF/ON table".  22 lists PROPOSE the name DL_OffOn, but they do it through
    # SEVERAL tables -- 8 of them through DLTable_F0CE75 and 14 through
    # StringTable_F197EC.  One table, one name, and one wrong sentence.
    t_offon = byaddr()[0xF0CE75]
    offon = [n for n in framed if not literals(n)
             and any(t == t_offon for t, _l in operand_tables(n))]
    prop = collections.Counter()
    for n in framed:
        if literals(n):
            continue
        tab = operand_tables(n)
        if not tab:
            continue
        w = []
        for _o, lit in tab:
            for x in lit:
                w.append(x)
                if len("".join(camel(y) for y in w)) >= SLUG_MIN:
                    break
            if len("".join(camel(y) for y in w)) >= SLUG_MIN:
                break
        prop["DL_" + "".join(camel(y) for y in w)[:SLUG_MAX]] += 1
    chk("22 lists would be called DL_OffOn -- 8 through the table at 0xF0CE75 "
        "(now %s) and 14 through 0xF197EC -- so none of them may have it"
        % t_offon,
        (prop["DL_OffOn"], len(offon), "DL_OffOn" in [v[0] for v in cand.values()]),
        (22, 8, False))
    chk("...and 7 more would be DL_IntOff, through StringTable_F19AB3",
        (prop["DL_IntOff"],
         sum(1 for n in framed if not literals(n)
             and any(t == byaddr()[0xF19AB3] for t, _l in operand_tables(n)))),
        (7, 7))

    # ---- the two rules MEASURED AND REJECTED, so a later round does not
    #      re-invent them
    of0, by0 = screens()
    a2n0 = dict((v, k) for k, v in dl.items())
    allcaps = collections.defaultdict(set)
    for n in dl:
        for e, t in captions(n):
            allcaps[e].add(t.strip())
    loose = sum(1 for n in framed if not literals(n)
                and any(len(allcaps.get(x, ())) == 1 for x in readouts(n)))
    chk("REJECTED-1  the FILE-WIDE caption search reaches %d lists, more than "
        "the screen-scoped rule, and is rejected: it offered the German word "
        "'Bitte' and a French sentence fragment as field names" % loose,
        loose > sum(1 for v in cand.values() if v[1] == "M3"), True)
    # REJECTED-3, measured here so a later round does not re-invent it: relaxing
    # the abutment to "the nearest caption to the LEFT on the same 80-byte row"
    # instead of "ends exactly here".
    relaxed = []
    for n in framed:
        if literals(n):
            continue
        ro = readouts(n)
        if not ro:
            continue
        pool = {}
        for r in of0.get(dl.get(n), ()):
            for other in by0[r]:
                onm = a2n0.get(other)
                if onm and onm != n:
                    for e, t in captions(onm):
                        pool.setdefault(e, set()).add(t.strip())
        if not pool or any(len(pool.get(x, ())) == 1 for x in ro):
            continue
        for x in ro:
            c2 = [(e, t) for e, ts in pool.items() for t in ts
                  if e // 0x50 == x // 0x50 and e <= x]
            if c2:
                relaxed.append((n, max(c2)[1]))
                break
    chk("REJECTED-3  the same-row relaxation reaches only %d more lists, and it "
        "offers them '--', 'K', 'dB', 'OK' and a 'SELECT' 42 bytes away -- "
        "rejected" % len(relaxed), len(relaxed), 9)
    chk("REJECTED-3  ...and only three of the nine are a plausible caption",
        sorted(t for _n, t in relaxed if is_caption(t)),
        ["KEY OFF MODE :", "SELECT", "TOUCH :"])
    chk("REJECTED-2  is_caption() rejects the prose fragments that made it "
        "necessary", [s for s in ("dB", "from", "A current", "Please try again.")
                      if is_caption(s)], [])
    chk("...and accepts the captions the rule lives on",
        [s for s in ("TIME SIG.=", "LAST MEASURE    :", "P0SITI0N  :", "CTR")
         if not is_caption(s)], [])

    # ---- the screen slug, and the guard that had to be put on it
    a2n, of, by = a2n0, of0, by0
    chk("StubBlock_F7D000 is the 'routine' of a whole module, not a screen: it "
        "runs more than 40 lists, which is why a screen slug taken from it was "
        "withdrawn", len(by["StubBlock_F7D000"]) > 40, True)
    chk("...so screen_slug() returns nothing for a list run only from there",
        screen_slug(label_at(0xF3A429), of, by, a2n, dl), None)
    # ---- M4, the operand tables
    out, cand, tlits, tcounts = table_proposals()
    done = sorted(n for n in named_here() if not n.startswith("DL_"))
    chk("M4  tables renamed so far (%d), plus those still framed with text (%d), "
        "plus the one the 3-character floor refuses, is the 65 that carry text"
        % (len(done), len(cand)), len(done) + len(cand) + 1, 65)
    chk("M4  every renamed table kept its structural KIND",
        [n for n in done if n.split("_")[0] not in TABLE_KINDS], [])
    chk("M4  no renamed table still carries an address",
        [n for n in done if re.search(r'_[0-9A-F]{6}$', n)], [])
    chk("M4  the FOUR left framed are two pairs holding the same words",
        sorted(tcounts[v[0]] for v in cand.values()), [2, 2, 2, 2])
    # ⚠ AND THE TWO PAIRS ARE NOT THE SAME KIND OF DUPLICATE.  0xF1828A and
    # 0xF19238 hold the SAME BYTES; 0xF1834A and 0xF193BE differ (`R1-` against
    # `R1`) and collide only after CamelCase drops the hyphen.  Both are correct
    # refusals, and saying they are the same thing would be a made-up sentence.
    chk("M4  one pair is byte-identical, the other differs by a trailing '-'",
        sorted(["|".join(tlits[byaddr()[0xF1828A]]) == "|".join(tlits[byaddr()[0xF19238]]),
                "|".join(tlits[byaddr()[0xF1834A]]) == "|".join(tlits[byaddr()[0xF193BE]])]),
        [False, True])
    chk("M4  ...and the hyphen is what the two differ by",
        (tlits[byaddr()[0xF1834A]][0], tlits[byaddr()[0xF193BE]][0]), ("R1-", "R1"))
    chk("M4  the 3-character floor still refuses StringTable_F1A515, whose whole "
        "content is the two bytes 'o' and '-'",
        ("StringTable_F1A515" in blocks(), "StringTable_F1A515" in cand),
        (True, False))
    # the FIRST and the LAST renamed table, by address, both checked
    rev = dict((v, k) for k, v in byaddr().items())
    addrs = dict((n, rev[n]) for n in done if n in rev)
    chk("M4  every renamed table is still resolvable to its ROM address",
        len(addrs), len(done))
    lo = min(addrs, key=lambda n: addrs[n])
    hi = max(addrs, key=lambda n: addrs[n])
    chk("M4  the LOWEST and the HIGHEST renamed table, and the first words each "
        "holds",
        [(hex(addrs[lo]), lo, literals(lo, quoted=True, minletters=1)[0]),
         (hex(addrs[hi]), hi, literals(hi, quoted=True, minletters=1)[0])],
        [("0xf03241", "DLTable_OriginalStringCylinder", "ORIGINAL"),
         ("0xf6e6ed", "Text_MSAOffOn23", "M.S.A. OFF ON  #2  #3")])
    print("\n%d failures" % len(FAIL))
    for f in FAIL:
        print("   ! " + f)
    return 1 if FAIL else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--tables" in sys.argv:
        return tables("--apply" in sys.argv)
    if "--census" in sys.argv:
        return census()
    if "--why" in sys.argv:
        return show(sys.argv[sys.argv.index("--why") + 1])
    if "--apply" in sys.argv:
        return apply_()
    census()
    cand, _w, _f = proposals()
    print("\nproposals:")
    for n, (nm, m, ev) in sorted(cand.items()):
        print("  %-14s %s  %-44s %s" % (n, m, nm, ev[0][:60] if ev else ""))
    print("\n(dry run; add --apply to rewrite prom_b/wsa1_prom_b.s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
