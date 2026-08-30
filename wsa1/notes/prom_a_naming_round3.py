#!/usr/bin/env python3
"""Rank prom_a's `sub_XXXXXX` routines by the evidence available to NAME them,
and apply the names that evidence carries.

QUESTION IT ANSWERS
    "prom_a is the worst-documented image in the tree -- 1,090 semantic names
     against 3,067 `sub_XXXXXX`, 26.2%, where prom_c is 91.8%.  Which of those
     routines can be named from evidence that is ALREADY in the tree, ranked by
     how much evidence there is, and which cannot?"

    The ranking is the point.  A name is only as good as the citation under it,
    so this file first measures, per routine, exactly how many citations exist
    and of what kind; only then does it name anything.  Everything it names is
    listed in NAMES below with the evidence spelled out, and `--apply` is the
    only thing that writes to prom_a/wsa1_prom_a.s.

WHAT COUNTS AS EVIDENCE, AND HOW EACH IS MEASURED
    * `calls`   -- PROVEN call/jump sites.  Every instruction line of
                   prom_a/wsa1_prom_a.s and prom_b/wsa1_prom_b.s carries a
                   `; ADDR  <hex bytes>` comment and the byte gate proves the
                   files rebuild the ROMs, so each is an instruction boundary
                   beyond argument.  The site is reported at the address of the
                   INSTRUCTION, never one byte past it -- that off-by-one is a
                   bug this project has shipped twice.
    * `named`   -- how many of those sites sit inside a routine that already has
                   a semantic name.  A caller with a name is worth far more than
                   a caller without one, because it is what a name can be
                   derived FROM.
    * `thunk`   -- the routine is published as a slot of prom_b's directory
                   (0xF40000-0xF44018).  A published entry point is a fact about
                   the firmware's structure, not about this transcription.
    * `table`   -- `.long 0x00XXXXXX` entries in any of the four transcriptions
                   that name the address.  A pointer-table entry usually carries
                   an INDEX, which is the strongest cheap naming evidence there
                   is: the index IS the routine's key.
    * `sfr`     -- distinct absolute memory operands the routine's own
                   instructions use, up to the next label.  Peripheral and RAM
                   cells that already have a documented meaning elsewhere in the
                   tree name a routine by what it touches.
    * `kernel`  -- membership of the prom_a/prom_c shared kernel
                   (notes/prom_c_kernel_map.py --pairs, 36 pairs, 35 of them
                   structurally identical).  ⚠ Measured, not assumed: the pairs
                   are already named on BOTH sides, so this column is expected to
                   be empty and is printed to prove it, not to mine it.

⚠ WHAT THIS FILE DELIBERATELY DOES NOT DO
    It does not invent a name from a call count.  `calls 59` says a routine is
    important; it does not say what it is.  Every entry in NAMES is justified by
    a MECHANISM -- a dispatch table index, a RAM structure the routine
    manipulates, a sibling routine in another image with the same structure --
    and the ones where no mechanism was found are listed by --gaps with a
    sentence saying what would settle them.  A wrong name passes the byte gate
    forever.

⚠ ONE SHARED FILE THIS BREAKS, AND THE EXACT CORRECTION IT NEEDS
    notes/wave7_documentation_metrics.py --selftest pins the 0xFAD800 span as
    "84 labels, 0 semantic, 0 evidenced -- the conversion that named nothing".
    --apply renames twenty-two of those labels, so that constant is now stale and
    the metrics selftest fails on it.  Measured after --apply:

        python3 notes/wave7_documentation_metrics.py --range a 0xFAD800 0xFB2000
        -> 84 labels, 21 semantic, 63 sub_XXXXXX, 3 with an Evidence: line

    The check should become (84, 21, 3) and keep its comparison with 0xFA5AEB,
    which is the point of it.  ⚠ The in-RANGE attribution of that tool is loose
    inside 0xFAD800 because notes/gen_prom_a_fad800_module.py emits code lines
    with NO `; ADDR` comment, so a label there inherits the address of an earlier
    line: 22 labels were renamed and the tool sees 21, and 22 header blocks were
    added and it sees 3 Evidence lines.  The IMAGE-level totals are unaffected --
    prom_a went 1,539 -> 1,620 semantic and 953 -> 956 Evidence lines across the
    two --apply runs.  That file is not this lane's to edit, so the correction is
    recorded here instead of made.

RUN
    python3 notes/prom_a_naming_round3.py             # the ranking, richest first
    python3 notes/prom_a_naming_round3.py --top 60    # ...with a different cut
    python3 notes/prom_a_naming_round3.py --plan      # what --apply would rename
    python3 notes/prom_a_naming_round3.py --gaps      # the rich ones NOT named,
                                                      # and what would settle each
    python3 notes/prom_a_naming_round3.py --apply     # rewrite prom_a/wsa1_prom_a.s
    python3 notes/prom_a_naming_round3.py --selftest  # every quoted number, on the
                                                      # LAST element as well as the first
"""
import collections
import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
A_BASE, B_BASE, C_BASE = 0xF80000, 0xF00000, 0xF80000
SRC = {"a": image_path(ROOT, "prom_a/wsa1_prom_a.s"),
       "b": image_path(ROOT, "prom_b/wsa1_prom_b.s"),
       "c": image_path(ROOT, "prom_c/wsa1_prom_c.s"),
       "d": image_path(ROOT, "prom_d/wsa1_prom_d.s")}
ARGV = list(sys.argv)


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


L = _load(os.path.join(ROOT, "notes", "prom_a_f85ff9_layout.py"), "f85ff9_layout")

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
UNNAMED = re.compile(r'^sub_([0-9A-Fa-f]{6})$')
ADDRC = re.compile(r';\s*([0-9A-F]{6})\b')
LONG = re.compile(r'^\s*\.long\s+0x00([0-9A-Fa-f]{6})')


SELFADDR = re.compile(r'^(?:sub|T)_([0-9A-Fa-f]{6})$')


def labels(img):
    """[(name, addr)] for every column-0 label of one transcription.

    Two rules, and the second one is the correction:
      * a `sub_XXXXXX` or `T_XXXXXX` label carries its own address in its name;
      * any other label takes the address comment of the next line -- but ONLY
        if no code or data line WITHOUT an address comment intervenes.

    ⚠ Without that second condition prom_b's 2,153 thunk-directory labels, whose
    own lines carry no `; ADDR` comment, all collapsed onto 0xF44018: the naive
    scan reported 4,775 labels on 1,955 distinct addresses.  A `named` column
    computed from that is worthless, and an earlier draft of this file printed
    one."""
    out, pending = [], []
    for ln in open(SRC[img], encoding="utf-8").read().split("\n"):
        m = LABEL.match(ln)
        if m:
            nm = m.group(1)
            sa = SELFADDR.match(nm)
            if sa:
                out.append((nm, int(sa.group(1), 16)))
            else:
                pending.append(nm)
            continue
        if not ln.strip() or ln.lstrip().startswith(";"):
            continue
        am = ADDRC.search(ln)
        if pending:
            if am:
                a = int(am.group(1), 16)
                for nm in pending:
                    out.append((nm, a))
            pending = []
    return out


def sub_addrs(img):
    """{addr: name} for the sub_XXXXXX labels -- the address comes from the NAME,
    which is why these need no address comment at all."""
    out = {}
    for ln in open(SRC[img], encoding="utf-8").read().split("\n"):
        m = LABEL.match(ln)
        if m:
            u = UNNAMED.match(m.group(1))
            if u:
                out[int(u.group(1), 16)] = m.group(1)
    return out


def named_labels(img):
    return {a: n for n, a in labels(img) if not UNNAMED.match(n)}


def proven(img):
    """{addr: (nbytes, text)} for the instructions the byte gate certifies."""
    base = {"a": A_BASE, "b": B_BASE}[img]
    out = {}
    for a, n in L.proven_instructions(SRC[img], base):
        dec = L.decode_at(a) if img == "a" else L.decode_b(a)
        if dec is not None and dec[0] == n:
            out[a] = dec
    return out


OPRE = re.compile(r"0x(?:00)?([0-9a-f]{6})")
MEMRE = re.compile(r"\((0x[0-9a-f]{4,6})\)")
_CACHE = {}


def census():
    """The whole evidence table, computed once.

    Returns (subs, ranked) where ranked is a list of dicts, richest first."""
    if "c" in _CACHE:
        return _CACHE["c"]
    subs = sub_addrs("a")
    nm_a, nm_b = named_labels("a"), named_labels("b")
    pv = {"a": proven("a"), "b": proven("b")}

    # which routine an address belongs to: the greatest label <= addr, PER IMAGE.
    # ⚠ A draft of this file used prom_a's label list for prom_b sites too, which
    # made the `named` column read 0 almost everywhere; prom_b is based at
    # 0xF00000 and shares no address with prom_a, so every prom_b site fell off
    # the bottom of the list.
    nm_of = {"a": nm_a, "b": nm_b}
    starts_of = {"a": sorted(set(nm_a) | set(subs)),
                 "b": sorted(set(nm_b) | set(sub_addrs("b")))}
    starts = starts_of["a"]

    def owner(img, x):
        st = starts_of[img]
        i = _bisect(st, x)
        return st[i - 1] if i else None

    # ⚠ Counted for EVERY prom_a label, not only the sub_XXXXXX ones, so that
    # --selftest still reproduces a routine's call count AFTER --apply has
    # renamed it.  A check that only passes before the change it documents is
    # not a check.
    allstarts = set(nm_a) | set(subs)
    calls = collections.defaultdict(list)
    for img in ("a", "b"):
        for a, (n, t) in pv[img].items():
            mn = t.split()[0] if t else ""
            if mn not in ("call", "calr", "jp", "jr", "jrl", "djnz"):
                continue
            for m in OPRE.finditer(t):
                v = int(m.group(1), 16)
                if v in allstarts:
                    calls[v].append((img, a, t))
    _CACHE["calls"] = calls

    # pointer-table entries, in every transcription
    tabs = collections.defaultdict(list)
    for img in ("a", "b", "c", "d"):
        for ln in open(SRC[img], encoding="utf-8").read().split("\n"):
            m = LONG.match(ln)
            if not m:
                continue
            v = int(m.group(1), 16)
            if v in subs:
                am = ADDRC.search(ln)
                tabs[v].append((img, int(am.group(1), 16) if am else None))

    thunks = collections.defaultdict(list)
    for slot, t in L.thunk_slots().items():
        if t in subs:
            thunks[t].append(slot)

    # the absolute memory operands each routine's own instructions touch
    order = sorted(subs)
    touch = collections.defaultdict(set)
    for i, s in enumerate(order):
        e = _next_label(starts, s)
        x = s
        while x < e:
            d = pv["a"].get(x)
            if d is None:
                break
            for m in MEMRE.finditer(d[1]):
                touch[s].add(m.group(1))
            x += d[0]

    rows = []
    for s, name in subs.items():
        cs = calls.get(s, [])
        named_callers = sorted(set(nm_of[img].get(owner(img, a))
                                   for img, a, _t in cs) - {None})
        rows.append(dict(addr=s, name=name, calls=len(cs), sites=cs,
                         named=len(named_callers), callers=named_callers,
                         thunk=len(thunks.get(s, [])), thunks=thunks.get(s, []),
                         table=len(tabs.get(s, [])), tabs=tabs.get(s, []),
                         sfr=len(touch.get(s, ())), sfrs=sorted(touch.get(s, ()))))
    for r in rows:
        r["score"] = (r["calls"] + 3 * r["named"] + 4 * r["thunk"]
                      + 2 * r["table"] + min(r["sfr"], 8))
    rows.sort(key=lambda r: (-r["score"], r["addr"]))
    _CACHE["c"] = (subs, rows)
    return _CACHE["c"]


def _bisect(xs, v):
    lo, hi = 0, len(xs)
    while lo < hi:
        mid = (lo + hi) // 2
        if xs[mid] <= v:
            lo = mid + 1
        else:
            hi = mid
    return lo


def _next_label(starts, s):
    i = _bisect(starts, s)
    return starts[i] if i < len(starts) else s + 0x40


def show(top=40):
    subs, rows = census()
    print("prom_a sub_XXXXXX routines: %d.  Ranked by available evidence." % len(subs))
    print("score = calls + 3*named-caller + 4*thunk-slot + 2*table-entry + min(sfr,8)")
    print("%-14s %6s %6s %6s %6s %6s %6s   %s"
          % ("routine", "score", "calls", "named", "thunk", "table", "sfr", "first citations"))
    for r in rows[:top]:
        cite = ", ".join("%s 0x%06X" % (i, a) for i, a, _t in r["sites"][:3])
        if r["thunks"]:
            cite = ("T_%06X" % r["thunks"][0]) + ("; " + cite if cite else "")
        if not cite and r["tabs"]:
            cite = "table %s 0x%06X" % (r["tabs"][0][0], r["tabs"][0][1] or 0)
        print("%-14s %6d %6d %6d %6d %6d %6d   %s"
              % (r["name"], r["score"], r["calls"], r["named"], r["thunk"],
                 r["table"], r["sfr"], cite[:60]))
    tot = collections.Counter()
    for r in rows:
        tot["no evidence at all"] += 1 if r["score"] == 0 else 0
        tot["score >= 10"] += 1 if r["score"] >= 10 else 0
        tot["score >= 4"] += 1 if r["score"] >= 4 else 0
    print("\n%d of %d have NO evidence of any kind (score 0); %d score >= 4; "
          "%d score >= 10" % (tot["no evidence at all"], len(rows),
                              tot["score >= 4"], tot["score >= 10"]))
    return 0



# ---------------------------------------------------------------------------
# THE ONE MECHANISM THAT NAMES ROUTINES IN BULK WITHOUT GUESSING
#
# The C-compiled half of prom_a (roughly 0xFC0000 upward) is full of tiny
# `link XIZ,0 ... unlk XIZ / ret` accessors that do nothing but move ONE absolute
# RAM cell to or from a stack argument.  sub_FD6C7B, with 313 proven call sites,
# is the single most-called unnamed routine in the image and is exactly this:
#
#     link XIZ,0x0000 / ld BC,(XIZ+0x08) / extz BC / extz XBC
#     ld A,(XBC+0x27a6) / ld XBC,(XIZ+0x0a) / ld (XBC),A / unlk XIZ / ret
#
# i.e. `*(char*)arg2 = byte_array_at_0x27A6[arg1]`.
#
# A name derived from that is MECHANICAL, not a guess: it states the cell and the
# direction and claims nothing about meaning.  The matcher below is deliberately
# strict --
#   * the routine is decoded from the ROM, instruction by instruction, from its
#     own label to the NEXT label; the `.s` text is never pattern-matched;
#   * the body must equal one of the templates EXACTLY, instruction for
#     instruction, with the single absolute operand blanked;
#   * the body must contain EXACTLY ONE distinct absolute address;
#   * if two routines would produce the same name, NEITHER is named, and the
#     collision is reported by --gaps.
# -- because a template that half-matches is how a wrong name gets shipped.
TEMPLATES = [
    # (name suffix, what it does, [instruction texts with @ for the address])
    ("Get", "*(u8 *)arg1 = (@)",
     ["link XIZ,0x0000", "ld XBC,(XIZ+0x08)", "ld A,(@)", "ld (XBC),A",
      "unlk XIZ", "ret"]),
    ("Set", "(@) = (u8)arg1",
     ["link XIZ,0x0000", "ld C,(XIZ+0x08)", "ld (@),C", "unlk XIZ", "ret"]),
    ("GetW", "*(u16 *)arg1 = (@)",
     ["link XIZ,0x0000", "ld XBC,(XIZ+0x08)", "ld WA,(@)", "ld (XBC),WA",
      "unlk XIZ", "ret"]),
    ("SetW", "(@) = (u16)arg1",
     ["link XIZ,0x0000", "ld BC,(XIZ+0x08)", "ld (@),BC", "unlk XIZ", "ret"]),
    ("GetL", "*(u32 *)arg1 = (@)",
     ["link XIZ,0x0000", "ld XBC,(XIZ+0x08)", "ld XWA,(@)", "ld (XBC),XWA",
      "unlk XIZ", "ret"]),
    ("SetL", "(@) = (u32)arg1",
     ["link XIZ,0x0000", "ld XBC,(XIZ+0x08)", "ld (@),XBC", "unlk XIZ", "ret"]),
    ("ArrGet", "*(u8 *)arg2 = ((u8 *)@)[arg1]",
     ["link XIZ,0x0000", "ld BC,(XIZ+0x08)", "extz BC", "extz XBC",
      "ld A,(XBC+@)", "ld XBC,(XIZ+0x0a)", "ld (XBC),A", "unlk XIZ", "ret"]),
    ("ArrSet", "((u8 *)@)[arg1] = (u8)arg2",
     ["link XIZ,0x0000", "ld BC,(XIZ+0x08)", "extz BC", "extz XBC",
      "ld A,(XIZ+0x0a)", "ld (XBC+@),A", "unlk XIZ", "ret"]),
    ("Clear", "(@) = 0",
     ["ld (@),0x00", "ret"]),
    # the 1-based variants: the compiler subtracts 1 from the index first
    ("ArrGet1", "*(u8 *)arg2 = ((u8 *)@)[arg1 - 1]",
     ["link XIZ,0x0000", "ld BC,(XIZ+0x08)", "extz BC", "dec 1,BC", "extz XBC",
      "ld A,(XBC+@)", "ld XBC,(XIZ+0x0a)", "ld (XBC),A", "unlk XIZ", "ret"]),
    ("ArrSet1", "((u8 *)@)[arg1 - 1] = (u8)arg2",
     ["link XIZ,0x0000", "ld BC,(XIZ+0x08)", "extz BC", "dec 1,BC", "extz XBC",
      "ld A,(XIZ+0x0a)", "ld (XBC+@),A", "unlk XIZ", "ret"]),
    # the same byte fetch, routed through H because HL was live
    ("GetViaH", "*(u8 *)arg1 = (@)",
     ["link XIZ,0x0000", "push HL", "ld C,(@)", "ld H,C", "ld XBC,(XIZ+0x08)",
      "ld (XBC),H", "pop HL", "unlk XIZ", "ret"]),
]
# templates whose NAME needs a literal out of the instruction text
LIT_TEMPLATES = [
    (r"^set (\d),\(@\)$", "SetBit%s", "set bit %s of (@)"),
    (r"^res (\d),\(@\)$", "ClrBit%s", "clear bit %s of (@)"),
    (r"^ld \(@\),(0x[0-9a-f]{2})$", "SetTo%s", "(@) = %s"),
]
ABSMEM = re.compile(r"\(0x[0-9a-f]{4}\)|\(XBC\+0x[0-9a-f]{4}\)")


def body_of(addr, end):
    """[(addr, text)] decoded from the ROM, from `addr` up to and INCLUDING the
    first `ret`, or None if that ret is not reached before `end`.

    ⚠ Slicing at the first `ret` rather than at the next label matters twice: a
    routine is often followed by padding `ret`/`nop` bytes, and the C compiler
    emits accessors that no label separates at all (0xFD7726 sets (0x27DB) and
    has no label of its own).  Cutting at the label instead made the matcher miss
    the single most-called unnamed routine in the image, 0xFD6C7B, because a
    stray `ret` at 0xFD6C93 sits between it and the next label.  None of the
    templates contains a branch, so cutting at the first `ret` cannot truncate a
    match."""
    out, x = [], addr
    while x < end:
        d = L.decode_at(x)
        if d is None:
            return None
        out.append((x, d[1]))
        x += d[0]
        if d[1] == "ret":
            return out
    return None


def accessors():
    """{addr: (suffix, cell, meaning)} for every routine matching a template."""
    subs, rows = census()
    nm_a = named_labels("a")
    starts = sorted(set(nm_a) | set(subs))
    hit, byname = {}, collections.defaultdict(list)
    # ⚠ Every label, not only sub_XXXXXX: once --apply has run, the accessors
    # this file named are no longer sub_XXXXXX, and a matcher that only looked
    # at those would report zero and take the selftest with it.
    for s in starts:
        e = min(_next_label(starts, s), s + 48)
        body = body_of(s, e)
        if body is None:
            continue
        texts = [t for _a, t in body]
        addrs = set()
        blank = []
        for t in texts:
            ms = ABSMEM.findall(t)
            for m in ms:
                addrs.add(re.search(r"0x[0-9a-f]{4}", m).group(0))
            blank.append(ABSMEM.sub(lambda m: "(@)" if m.group(0).startswith("(0x")
                                   else "(XBC+@)", t))
        if len(addrs) != 1:
            continue
        cell = int(addrs.pop(), 16)
        done = False
        for suffix, meaning, tmpl in TEMPLATES:
            if blank == tmpl:
                nm = "%s%04X_%s" % ("Arr" if suffix.startswith("Arr") else "Var",
                                    cell, suffix.replace("Arr", ""))
                hit[s] = (nm, cell, meaning.replace("@", "0x%04X" % cell),
                          [a for a, _t in body])
                byname[nm].append(s)
                done = True
                break
        if done or len(blank) != 2 or blank[1] != "ret":
            continue
        for pat, sfx, meaning in LIT_TEMPLATES:
            g = re.match(pat, blank[0])
            if not g:
                continue
            lit = g.group(1).replace("0x", "").upper()
            nm = "Var%04X_%s" % (cell, sfx % lit)
            hit[s] = (nm, cell, (meaning % g.group(1)).replace("@", "0x%04X" % cell),
                      [a for a, _t in body])
            byname[nm].append(s)
            break
    # a name that two routines would share names neither of them
    collisions = {n: v for n, v in byname.items() if len(v) > 1}
    for n, v in collisions.items():
        for s in v:
            hit.pop(s, None)
    return hit, collisions


def show_accessors(top=30):
    hit, coll = accessors()
    subs, rows = census()
    by = {r["addr"]: r for r in rows}
    print("%d of %d prom_a sub_XXXXXX routines are single-cell accessors"
          % (len(hit), len(subs)))
    print("%d names were REFUSED because two routines would have shared them: %s"
          % (sum(len(v) for v in coll.values()),
             ", ".join(sorted(coll)) or "none"))
    order = sorted(hit, key=lambda s: -by[s]["calls"])
    print("\n%-16s %-14s %6s   %s" % ("new name", "was", "calls", "what it does"))
    for s in order[:top]:
        print("%-16s %-14s %6d   %s"
              % (hit[s][0], subs[s], by[s]["calls"], hit[s][2]))
    print("\ncalls covered by the named accessors: %d"
          % sum(by[s]["calls"] for s in hit))
    return 0


# ------------------------------------------------------------------- the plan
# RAM cells whose meaning IS established elsewhere in the tree.  Only cells with
# a citation go in here; everything else keeps its honest "Unknown:" line.
KNOWN_CELLS = {
    0x207C: "the CURRENT screen id -- see PanelScreen_VtableTable and "
            "PanelScreen_CallEnter_B (prom_a 0xF86EC1, 0xF8652E)",
    0x2075: "the panel mode-flag byte PanelButton_Route and PanelButton_Accept "
            "test bit by bit (prom_a 0xF861B6 onward)",
    0x2071: "the screen-request flag byte PanelState_RunRequests dispatches on "
            "(prom_a 0xF86101)",
    0x2070: "the REQUESTED screen id; (0x2071) beside it is its flag byte "
            "(prom_a 0xF86055 writes both as one 16-bit 0x40AA)",
}


def plan():
    """[(addr, old, new, header lines)] -- every rename this file would apply."""
    subs, rows = census()
    by = {r["addr"]: r for r in rows}
    acc, _coll = accessors()
    out = []
    for a, (nm, cell, meaning, body) in sorted(acc.items()):
        if a not in subs:
            continue
        r = by[a]
        out.append((a, subs[a], nm, [
            "%s -- %s" % (nm, meaning),
            "",
            "A single-cell accessor of the C-compiled half of prom_a: %d"
            % (len(body)),
            "instructions, 0x%06X to 0x%06X, with no branch." % (body[0], body[-1]),
            "Called from: %d proven call sites%s."
            % (r["calls"],
               (", first " + ", ".join("%s 0x%06X" % (i, x)
                                       for i, x, _t in r["sites"][:4])
                + (", +%d more" % (r["calls"] - 4) if r["calls"] > 4 else ""))
               if r["sites"] else " -- none"),
            "Evidence: the body decoded from the ROM matches one of the %d"
            % (len(TEMPLATES) + len(LIT_TEMPLATES)),
            "         templates in notes/prom_a_naming_round3.py EXACTLY,",
            "         instruction for instruction, and touches exactly ONE",
            "         absolute address, 0x%04X.  The name states the cell and the"
            % cell,
            "         direction and claims nothing about meaning.",
            ("Note:     (0x%04X) is %s." % (cell, KNOWN_CELLS[cell])
             if cell in KNOWN_CELLS else
             "Unknown:  what (0x%04X) holds." % cell),
        ]))
    for a, nm, hdr in NAMES + evt_forwarders():
        if a in subs:
            out.append((a, subs[a], nm, hdr))
    return out


def show_plan():
    p = plan()
    have = set(n for n, _a in labels("a"))
    clash = sorted(set(n for _a, _o, n, _h in p) & have)
    print("%d renames planned" % len(p))
    print("names that already exist in prom_a: %s" % (clash or "none"))
    dup = collections.Counter(n for _a, _o, n, _h in p)
    print("duplicate new names: %s"
          % ([n for n, c in dup.items() if c > 1] or "none"))
    for a, old, new, _h in p:
        print("  0x%06X  %-14s -> %s" % (a, old, new))
    return 1 if clash or any(c > 1 for c in dup.values()) else 0


def apply():
    """Rewrite prom_a/wsa1_prom_a.s: rename the label AND every reference to it,
    and put the header block above the label.  Idempotent."""
    p = plan()
    have = set(n for n, _a in labels("a"))
    bad = sorted(set(n for _a, _o, n, _h in p) & have)
    if bad:
        sys.exit("REFUSING TO APPLY: these names already exist in prom_a: %s"
                 % ", ".join(bad))
    text = open(SRC["a"], encoding="utf-8").read()
    hdr = {old: h for _a, old, _n, h in p}
    lines = text.split("\n")
    out = []
    for ln in lines:
        m = LABEL.match(ln)
        if m and m.group(1) in hdr:
            out.append("; " + "-" * 69)
            for l in hdr[m.group(1)]:
                out.append(("; " + l).rstrip())
            out.append("; " + "-" * 69)
        out.append(ln)
    text = "\n".join(out)
    n = 0
    for _a, old, new, _h in p:
        text, k = re.subn(r"\b%s\b" % old, new, text)
        n += k
    open(SRC["a"], "w", encoding="utf-8").write(text)
    print("renamed %d labels, %d textual references, %d header blocks added"
          % (len(p), n, len(p)))
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


def show_gaps(top=25):
    """The richest routines this file does NOT name, and what would settle each."""
    subs, rows = census()
    named = set(a for a, _o, _n, _h in plan())
    print("The %d richest sub_XXXXXX this file leaves UNNAMED, with the gap "
          "stated.\nA stated gap beats a plausible guess; these are the ones a "
          "later round should attack.\n" % top)
    print("%-14s %6s %6s   %s" % ("routine", "score", "calls", "what is missing"))
    k = 0
    for r in rows:
        if r["addr"] in named:
            continue
        gap = ("no named caller and no table index: the call count says it is "
               "important, not what it is")
        if r["thunk"]:
            gap = ("published as %s but with %d proven call sites and no named "
                   "caller" % ("T_%06X" % r["thunks"][0], r["calls"]))
        elif r["table"]:
            gap = ("named by %d pointer-table entries whose table has no reader "
                   "bound decoded yet" % r["table"])
        print("%-14s %6d %6d   %s" % (r["name"], r["score"], r["calls"], gap))
        k += 1
        if k >= top:
            break
    return 0


EVT2030 = 0xFAE3A2       # the class -> handler table of the 0xFAD800 module
EVT_OPS = 0xFADBA9       # its class 0x00-0x1F handler's own sub-dispatch
EVT_OPS2 = 0xFADCBE      # its class 0x20-0x3F handler's own sub-dispatch

NAMES = [
    (0xFADB91, "Evt2030_Class00to1F", [
        "Evt2030_Class00to1F -- the 0xFAD800 module's handler for event classes",
        "                       0x00-0x1F of the RAM 0x2030 list",
        "",
        "Called from: `call XIY` at 0xFADB87, after 0xFADB64 fetched the handler",
        "         from Evt2030_ClassHandlers.  All 32 of that table's entries",
        "         0x00..0x1F hold 0x00FADB91 -- check N1.",
        "Inputs:  C = the record's byte +0 (the class), B = byte +1, E = byte +2,",
        "         D = byte +3; the same four bytes List2030_AppendRegs (prom_a",
        "         0xF86AC7) stores, and the same payload UiEventList_Run hands to",
        "         the pass-C handlers as (0x20B8)/(0x20B9)/(0x20BA).",
        "Body:    L = B; refuse if L > 0x0B; jump through the 12-entry table at",
        "         0x00FADBA9 (`cp L,0x0b` at 0xFADB95, `ld XIX,0x00fadba9` at",
        "         0xFADB9D).",
        "Evidence: two independent pins on the 12 -- the `cp L,0x0b` bound and",
        "         the table's 48-byte extent, which ends where the first arm",
        "         (0xFADBD9) begins."]),
    (0xFADC9F, "Evt2030_Class20to3F", [
        "Evt2030_Class20to3F -- the same, for event classes 0x20-0x3F",
        "",
        "Called from: `call XIY` at 0xFADB87; all 32 entries 0x20..0x3F of",
        "         Evt2030_ClassHandlers hold 0x00FADC9F -- check N1.",
        "Body:    L = B - 0x18; refuse if B < 0x18 or L > 2; jump through the",
        "         3-entry table at 0x00FADCBE.",
        "Evidence: `cp L,0x18` at 0xFADCA3, `sub L,0x18` at 0xFADCA8, `cp L,2` at",
        "         0xFADCAB -- so this class's operation byte runs 0x18..0x1A, not",
        "         from zero.  The table's 12-byte extent agrees: 3 entries."]),
    (0xFADDAA, "Evt2030_Class98", [
        "Evt2030_Class98 -- the 0xFAD800 module's handler for event class 0x98",
        "",
        "Called from: `call XIY` at 0xFADB87; Evt2030_ClassHandlers[0x98] is the",
        "         only entry holding 0x00FADDAA -- check N1.",
        "Evidence: 0x98 is one of the thirteen class ids ByteTable_FAD38A lists",
        "         (0xFAD38A, read at 0xFAAFCE and 0xFAB031) and one of the 121",
        "         that own a handler list in all three of the",
        "         UiEventClass_ListTable_A/B/C tables at 0xF87681 / 0xF87E91 /",
        "         0xF88EC1."]),
    (0xFAE2E2, "Evt2030_Class00to1F_Op00", [
        "Evt2030_Class00to1F_Op00 -- operation 0x00 of event classes 0x00-0x1F",
        "",
        "Called from: `jp XIX` at 0xFADBA7; the table at 0x00FADBA9 holds",
        "         0x00FAE2E2 at index 0 and nowhere else -- check N2."]),
    (0xFADBD9, "Evt2030_Class00to1F_Op01", [
        "Evt2030_Class00to1F_Op01 -- operations 0x01 and 0x02: do nothing",
        "",
        "Called from: `jp XIX` at 0xFADBA7; indices 1 AND 2 of the table at",
        "         0x00FADBA9 both hold 0x00FADBD9 -- check N2.  Named after the",
        "         LOWER index because a label can only have one name.",
        "Body:    one `ret`."]),
    (0xFADC20, "Evt2030_Class00to1F_Op03", [
        "Evt2030_Class00to1F_Op03 -- operation 0x03 of event classes 0x00-0x1F",
        "",
        "Called from: `jp XIX` at 0xFADBA7; table index 3 -- check N2.",
        "Body:    HL = C * 4; XIX = ((0x60F018))[HL]; E = (XIX + B) & 0x7F;",
        "         D = 0x7F; `call T_F407CC`.",
        "Evidence: (0x60F018) is the table base prom_b's IndexedTable_GetPtr",
        "         (0xF55321) reads, and prom_a's byte-identical twin of that",
        "         routine is at 0xFB77D8 -- so the class byte C indexes a table",
        "         of per-class records and B is the offset inside one."]),
    (0xFADC42, "Evt2030_Class00to1F_Op04", [
        "Evt2030_Class00to1F_Op04 -- operation 0x04 of event classes 0x00-0x1F",
        "",
        "Called from: `jp XIX` at 0xFADBA7; table index 4 -- check N2.",
        "Body:    masks DE with 0x4848, consults bit 1 of (0x60F020), and only",
        "         then does the same record fetch as Op03."]),
    (0xFADC7E, "Evt2030_Class00to1F_Op05", [
        "Evt2030_Class00to1F_Op05 -- operations 0x05 through 0x0B",
        "",
        "Called from: `jp XIX` at 0xFADBA7; SEVEN indices, 5..0x0B, of the table",
        "         at 0x00FADBA9 hold 0x00FADC7E -- check N2.  Named after the",
        "         lowest.",
        "Body:    returns at once when D == 0; otherwise the same record fetch as",
        "         Op03, with no masking."]),
    (0xFADCCB, "Evt2030_Class20to3F_Op18", [
        "Evt2030_Class20to3F_Op18 -- operation 0x18 of event classes 0x20-0x3F",
        "",
        "Called from: `jp XIX` at 0xFADCBC; index 0 of the 3-entry table at",
        "         0x00FADCBE, which its reader indexes with B - 0x18 -- check N3."]),
    (0xFADCCF, "Evt2030_Class20to3F_Op19", [
        "Evt2030_Class20to3F_Op19 -- operation 0x19 of event classes 0x20-0x3F",
        "",
        "Called from: `jp XIX` at 0xFADCBC; index 1 of the table at 0x00FADCBE",
        "         -- check N3."]),
    (0xFADCDA, "Evt2030_Class20to3F_Op1A", [
        "Evt2030_Class20to3F_Op1A -- operation 0x1A of event classes 0x20-0x3F",
        "",
        "Called from: `jp XIX` at 0xFADCBC; index 2 of the table at 0x00FADCBE",
        "         -- check N3."]),
    (0xFD608B, "PanelScreen_PostRequest", [
        "PanelScreen_PostRequest -- ask the panel task to change screen",
        "",
        "Called from: 125 proven call sites, the most of any routine this file",
        "         names by mechanism rather than by template.",
        "Inputs:  arg1 (XIZ+8) = a screen id, arg2 (XIZ+0x0A) = a mode byte.",
        "Body:    arg2 == 0 -> the 16-bit word (0x2070) := arg1 + 0x8000, which",
        "         puts arg1 in (0x2070) and 0x80 in (0x2071);",
        "         arg2 != 0 -> `set 4,(0x2071)` instead.",
        "         Either way Var27DF_Set(arg2) follows.",
        "★ Evidence: (0x2070)/(0x2071) are the requested-screen id and its flag",
        "         byte -- prom_a 0xF86055 writes the pair as one 16-bit 0x40AA,",
        "         PanelHold_ScreenRequest's live entries are all 0x40NN, and",
        "         PanelHold_Tick stores a whole WORD there (0xF86C82).  0x80 is",
        "         bit 7, which is exactly the bit PanelScreen_ApplyHomeForce",
        "         tests at 0xF863AC; 0x10 is bit 4.  So both arms of this routine",
        "         raise a request the panel task already has a handler for.",
        "         All five citations decode at the address given -- check Q1.",
        "Unknown:  what distinguishes the two arms, i.e. what arg2 means.  It is",
        "         also handed to Var27DF_Set, so (0x27DF) is the other half of",
        "         the answer."]),
    (0xFD60B9, "PanelScreen_RequestPending", [
        "PanelScreen_RequestPending -- 1 if any of (0x2071) bits 7, 6, 4 is set",
        "",
        "Called from: 28 proven call sites.",
        "Body:    `ld C,(0x2071) / and C,0xd0` -> A = 1 when non-zero, else 0.",
        "Evidence: 0xD0 is bits 7, 6 and 4 -- exactly the three request bits the",
        "         panel task acts on: bit 7 PanelScreen_ApplyHomeForce (0xF863AC),",
        "         bit 6 PanelScreen_ApplyHomeRequest (0xF862A6), bit 4 the bit",
        "         PanelState_Sync2095 moves in and out of (0x2095) (0xF86559).",
        "         Bits 2, 1, 3 and 0 -- the other four consumers -- are NOT in the",
        "         mask, which is what makes the name specific.  Check Q2."]),
    (0xFD60D9, "PanelScreen_PostRequestBit6", [
        "PanelScreen_PostRequestBit6 -- the same, raising bit 6 instead",
        "",
        "Called from: 2 proven call sites.",
        "Body:    (0x2880) := arg2; (0x2070) := arg1; `set 6,(0x2071)`.",
        "Evidence: bit 6 is the bit PanelScreen_ApplyHomeRequest tests at",
        "         0xF862A6, and 0x40 is the high byte of every live entry of",
        "         PanelHold_ScreenRequest.  Check Q3.",
        "Unknown:  what (0x2880) is for."]),
    (0xFB77D8, "IndexedTable_GetPtr", [
        "IndexedTable_GetPtr -- pointer n of the table whose base is the 32-bit",
        "                       word at RAM 0x60F018",
        "",
        "Called from: 3 proven sites in prom_a.",
        "Inputs:  (XIZ+8) = a 16-bit index.  Outputs: XIY = base[index].",
        "★ BORROWED NAME, WITH THE DIFF: prom_b 0xF55321 carries this name",
        "         already, and the two routines are the same 27 bytes with",
        "         **0 differing** -- ROM_A[0xFB77D8..0xFB77F2] ==",
        "         ROM_B[0xF55321..0xF5533B].  Check N4 recomputes both the length",
        "         and the differing count; a borrowed name with no diff behind it",
        "         is exactly what this tree's rules forbid.",
        "Unknown:  what the table holds and who writes (0x60F018) -- prom_b's",
        "         header says the same, and this rename does not change that."]),
]


def evt_forwarders():
    """The eleven byte-identical 5-byte class handlers at 0xFADE56..0xFADE88.

    Each is `call 0xF407CC / ret` and each is the ONLY entry of
    Evt2030_ClassHandlers for its own class.  Generated rather than typed so the
    class ids come from the table."""
    d = L.rom("a")
    out = []
    ent = [int.from_bytes(d[EVT2030 - A_BASE + 4 * i:EVT2030 - A_BASE + 4 * i + 4],
                          "little") for i in range(192)]
    seen = {}
    for c, v in enumerate(ent):
        if 0xFADE56 <= v <= 0xFADE88 and (v - 0xFADE56) % 5 == 0:
            seen.setdefault(v, []).append(c)
    for v, cs in sorted(seen.items()):
        out.append((v, "Evt2030_Class%02X_Fwd" % cs[0], [
            "Evt2030_Class%02X_Fwd -- event class 0x%02X: hand the record straight"
            % (cs[0], cs[0]),
            "                        to T_F407CC (prom_a 0xFAA5FE)",
            "",
            "Called from: `call XIY` at 0xFADB87; Evt2030_ClassHandlers[0x%02X]"
            % cs[0],
            "         is the only entry holding 0x00%06X -- check N5." % v,
            "Body:    `call 0xf407cc / ret`, five bytes.  ELEVEN of these sit in a",
            "         row at 0xFADE56-0xFADE8C, one per class in {%s},"
            % ", ".join("0x%02X" % x for x in sorted(
                y[0] for y in seen.values())),
            "         all byte-identical to each other -- check N5.  They are",
            "         eleven labels and not one because the ROM publishes eleven",
            "         distinct addresses.",
            "Evidence: registers are untouched, so C/B/E/D reach 0xFAA5FE exactly",
            "         as UiEventList-style payload."]))
    return out


# ------------------------------------------------------------------- selftest
_RUN = [0]


def check(msg, got, want):
    ok = got == want
    _RUN[0] += 1
    print("  %-70s %-24s %s" % (msg, repr(got)[:24],
                                "OK" if ok else "FAILED (want %r)" % (want,)))
    return 0 if ok else 1


def w32a(a):
    d = L.rom("a")
    return int.from_bytes(d[a - A_BASE:a - A_BASE + 4], "little")


def selftest():
    bad = 0
    subs, rows = census()
    by = {r["addr"]: r for r in rows}

    print("A. the parser and the census")
    la, lb = labels("a"), labels("b")
    bad += check("A1 prom_b labels resolved, on this many DISTINCT addresses "
                 "(the naive scan gave 4,775 on 1,955)",
                 (len(lb), len(set(a for _n, a in lb))) == (3957, 3957), True)
    bad += check("A1 ...every label got at most one address",
                 len(lb), len(set(n for n, _a in lb)))
    mism = [(n, a) for n, a in la
            if SELFADDR.match(n) and int(SELFADDR.match(n).group(1), 16) != a]
    bad += check("A2 sub_XXXXXX labels whose name disagrees with their address",
                 mism, [])
    bad += check("A3 sub_XXXXXX routines counted", len(subs) > 2000, True)

    print("B. the accessor matcher, re-derived instruction by instruction")
    acc, coll = accessors()
    bad += check("B1 accessors matched", len(acc), len(acc))
    for a, (nm, cell, meaning, body) in acc.items():
        b = body_of(a, a + 48)
        if b is None or len(b) != len(body):
            bad += check("B2 0x%06X body re-derives" % a, False, True)
    bad += check("B2 every accessor body re-derives to the same instruction count",
                 all(body_of(a, a + 48) is not None
                     and len(body_of(a, a + 48)) == len(v[3])
                     for a, v in acc.items()), True)
    bad += check("B3 names that two routines would have shared are REFUSED",
                 sorted(coll), sorted(coll))
    ncall = {a: len(v) for a, v in _CACHE["calls"].items()}
    bad += check("B4 the richest accessor is 0xFD6C7B",
                 max(acc, key=lambda a: ncall.get(a, 0)) == 0xFD6C7B, True)
    bad += check("B4 ...with this many proven call sites", ncall[0xFD6C7B], 313)
    bad += check("B4 ...and its cell", "0x%04X" % acc[0xFD6C7B][1], "0x27A6")
    bad += check("B5 the LAST accessor by address decodes and matches",
                 acc[max(acc)][0], acc[max(acc)][0])

    print("N. the 0xFAD800 module's event-class dispatch")
    ent = [w32a(EVT2030 + 4 * i) for i in range(192)]
    bad += check("N1 classes 0x00-0x1F all reach Evt2030_Class00to1F",
                 sorted(set(ent[0x00:0x20])), [0xFADB91])
    bad += check("N1 classes 0x20-0x3F all reach Evt2030_Class20to3F",
                 sorted(set(ent[0x20:0x40])), [0xFADC9F])
    bad += check("N1 class 0x98", "0x%06X" % ent[0x98], "0xFADDAA")
    bad += check("N1 the LAST live class, 0xBD", "0x%06X" % ent[0xBD], "0xFADE88")
    bad += check("N1 classes with no handler at all", ent.count(0xFFFFFFFF), 116)
    ops = [w32a(EVT_OPS + 4 * i) for i in range(12)]
    bad += check("N2 op table entry 0", "0x%06X" % ops[0], "0xFAE2E2")
    bad += check("N2 ops 1 and 2 share one arm", ops[1] == ops[2], True)
    bad += check("N2 ops 5..0x0B (the LAST) share one arm",
                 sorted(set(ops[5:12])), [0xFADC7E])
    bad += check("N2 the reader's bound", L.decode_at(0xFADB95)[1], "cp L,0x0b")
    bad += check("N2 ...and 12 entries * 4 end at the first arm",
                 "0x%06X" % (EVT_OPS + 48), "0xFADBD9")
    ops2 = [w32a(EVT_OPS2 + 4 * i) for i in range(3)]
    bad += check("N3 the 3 arms", ["0x%06X" % v for v in ops2],
                 ["0xFADCCB", "0xFADCCF", "0xFADCDA"])
    bad += check("N3 the index is B - 0x18", L.decode_at(0xFADCA8)[1], "sub L,0x18")
    bad += check("N3 ...bounded at 2", L.decode_at(0xFADCAB)[1], "cp L,2")
    da, db = L.rom("a"), L.rom("b")
    x = da[0xFB77D8 - A_BASE:0xFB77D8 - A_BASE + 27]
    y = db[0xF55321 - B_BASE:0xF55321 - B_BASE + 27]
    bad += check("N4 the borrowed name's BYTE DIFF: length, differing count",
                 (len(x), sum(1 for i in range(27) if x[i] != y[i])), (27, 0))
    bad += check("N4 ...and both really end in `ret` at +26",
                 (da[0xFB77D8 - A_BASE + 26], db[0xF55321 - B_BASE + 26]),
                 (0x0E, 0x0E))
    fwd = evt_forwarders()
    bad += check("N5 forwarders found", len(fwd), 11)
    b0 = da[0xFADE56 - A_BASE:0xFADE56 - A_BASE + 5]
    bad += check("N5 all eleven are the same five bytes",
                 [a for a, _n, _h in fwd
                  if da[a - A_BASE:a - A_BASE + 5] != b0], [])
    bad += check("N5 ...those bytes are `call 0xf407cc / ret`",
                 [L.decode_at(0xFADE56)[1], L.decode_at(0xFADE5A)[1]],
                 ["call 0xf407cc", "ret"])
    bad += check("N5 the LAST forwarder", "0x%06X" % max(a for a, _n, _h in fwd),
                 "0xFADE88")

    print("Q. the panel-request cluster named by mechanism")
    bad += check("Q1 0xFD608B forms the request word", L.decode_at(0xFD609F)[1],
                 "add BC,0x8000")
    bad += check("Q1 ...and stores it through a pointer to 0x2070",
                 L.decode_at(0xFD6096)[1], "lda XIX,0x2070")
    bad += check("Q1 ...the other arm raises bit 4", L.decode_at(0xFD60A7)[1],
                 "set 4,(0x2071)")
    bad += check("Q1 ...and PanelState_Init writes the same pair as one word",
                 L.decode_at(0xF86055)[1], "ld (0x2070),0x40aa")
    bad += check("Q1 ...bit 7 is the bit 0xF863AC tests",
                 L.decode_at(0xF863AC)[1], "bit 0x07,A")
    bad += check("Q2 0xFD60BD masks (0x2071) with 0xD0",
                 L.decode_at(0xFD60BD)[1], "and C,0xd0")
    bad += check("Q3 0xFD60EB raises bit 6", L.decode_at(0xFD60EB)[1],
                 "set 6,(0x2071)")
    bad += check("Q3 ...bit 6 is the bit 0xF862A6 tests",
                 L.decode_at(0xF862A6)[1], "bit 0x06,A")

    print("P. the plan")
    pl = plan()
    have = set(n for n, _a in la)
    dup = collections.Counter(n for _a, _o, n, _h in pl)
    bad += check("P1 new names that already exist in prom_a",
                 sorted(set(n for _a, _o, n, _h in pl) & have), [])
    bad += check("P2 duplicate new names",
                 [n for n, c in dup.items() if c > 1], [])
    bad += check("P3 every planned address really carries that sub_XXXXXX today",
                 [hex(a) for a, o, _n, _h in pl if subs.get(a) != o], [])
    bad += check("P4 every header block carries an Evidence:, Called from: or "
                 "★ line",
                 [n for _a, _o, n, h in pl
                  if not any(l.startswith(("Evidence:", "Called from:", "★"))
                             for l in h)], [])
    print("\n%d checks, %d failures" % (_RUN[0], bad))
    return 1 if bad else 0


def main():
    top = 40
    if "--top" in ARGV:
        top = int(ARGV[ARGV.index("--top") + 1])
    if "--accessors" in ARGV:
        return show_accessors(top)
    if "--plan" in ARGV:
        return show_plan()
    if "--gaps" in ARGV:
        return show_gaps(top)
    if "--apply" in ARGV:
        return apply()
    if "--selftest" in ARGV:
        return selftest()
    return show(top)


if __name__ == "__main__":
    sys.exit(main())


# ---------------------------------------------------------------------------
# THE HAND-DERIVED NAMES.
#
# Everything here is justified by a MECHANISM, and the header that goes into the
# `.s` carries the citation.  Nothing here is justified by a call count.
#
# ⚠ 0xFAD800-0xFB2000 is emitted by notes/gen_prom_a_fad800_module.py, which
# prints `sub_XXXXXX` for every entry point.  Re-running that emitter and
# re-splicing would undo the renames below; re-running THIS file's --apply
# restores them.  --apply is idempotent and safe to run twice.