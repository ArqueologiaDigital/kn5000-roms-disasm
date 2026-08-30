#!/usr/bin/env python3
"""prom_b's 2,002 thunk slots: what does each one POINT AT, and can the slot
therefore be NAMED?

QUESTION IT ANSWERS
    prom_b's routine directory at 0xF40000-0xF44017 is the single biggest block
    of FRAMED labels anywhere in the tree: 2,002 slots spelled `T_<address>`.
    A slot is a POINTER, and a pointer's meaning is fully determined by what it
    points at.  So:
      (a) for each slot, what is the TARGET's label, and what GRADE does
          notes/wave7_documentation_metrics.py give that label?
      (b) which slots can therefore be promoted from `T_<address>` to a name?
      (c) ★ how many point at a target that is STILL `sub_XXXXXX` -- the number
          nobody had, and the sharpest available measure of prom_b's remaining
          work, because it counts routines the machine's own directory says
          exist and that nobody has understood.

★★ THE ANSWER, and it is mostly a NEGATIVE result
    Of 2,002 slots (run this script with no arguments to reproduce):

        target label grade      slots
        ---------------------   -----
        CONTENT                   285      <- promotable
        FRAMED                      9      <- rejected, see R2
        sub_XXXXXX               1,435     <- rejected, see R1.  ★ (c)
        no label at all            273         115 of them at an address the
                                                .s DOES disassemble, 158 in a
                                                span that is still .incbin

    So 1,435 + 273 = 1,708 of 2,002 slots (85.3%) point at something nobody has
    named.  The directory is not 2,002 pieces of missing documentation; it is a
    faithful INDEX of 1,708 pieces of missing documentation that live elsewhere.
    Naming the pointers cannot fix that and this script does not pretend to.

⚠⚠ EVERY NAME THIS SCRIPT PRODUCES IS DERIVATIVE.  It invents nothing.  A slot
    is renamed to `T_` + the name that ANOTHER LANE gave the target, and the
    understanding was theirs.  273 promotions here are 273 pointers made
    readable, NOT 273 new facts about the machine.  Report them as derivative or
    the metric becomes a lie.

★ THE RULE: TAKE A NAME ONLY FROM A **CONTENT** TARGET
    A slot pointing at `sub_F86066` stays `T_F40F34`.  Promoting it would spell
    an unnamed routine as a named-looking pointer -- laundering, and strictly
    worse than leaving the slot framed, because the framed spelling at least
    tells the reader that nothing is known.

⚠ THREE RELAXATIONS MEASURED AND REJECTED, so a later round does not re-invent
  them.  `--rejected` re-measures all three and prints their yield.

    R1  TAKE THE NAME FROM A sub_XXXXXX TARGET TOO.
        Yield: +1,435 slots, i.e. it would take the directory from 13.6%
        "named" to 85.3% in one pass.  Rejected: `T_sub_F86066` is not a name,
        and the variant that strips the prefix (`T_F86066`) is the SAME framed
        spelling with a different address in it -- the metric would grade it
        framed, correctly.  The number this relaxation would buy is exactly the
        number reported in (c) as REMAINING WORK.  They are the same 1,435
        slots; one framing is honest and the other is not.

    R2  TAKE THE NAME FROM A FRAMED TARGET.
        Yield: +9 slots (T_F40F1C -> SC1_Entry_F40F1C, T_F42C70 ->
        Stub_Ret_F55018, ...).  Rejected, and this one is free to reject
        because it buys LITERALLY NOTHING: `T_Stub_Ret_F55018` still ends in six
        hex digits, so wave7_documentation_metrics.py grades the result FRAMED
        exactly as it grades `T_F42C70`.  A rename that changes the spelling and
        not the grade is churn.  --rejected asserts this: it re-grades all nine.

    R3  DISAMBIGUATE THE ALIAS PAIRS WITH A SUFFIX.
        Six CONTENT targets are each named by TWO slots (0xF86AE9, 0xF31BA1,
        0xF31C14, 0xF31B57, 0xF8584A, 0xF85904 -- the same address twice, not
        two entry points).  A suffix would have to say which slot is primary,
        and nothing measured here says that.  `_A`/`_B` is invention and
        `T_Kernel_ExitTask_F42D70` is framed again (R2).  So all 12 slots stay
        `T_<address>` WITH A STATED REASON, which is this project's rule:
        prefer sub_XXXXXX plus a stated gap over a plausible guess.
        285 - 12 = 273 promotions.

★ WHY THE OLD SPELLING SURVIVES IN THE COMMENT
    prom_a's source carries 328 cross-references of the form `T_F40F34`
    ("entry: prom_b directory slot T_F40F34"), 210 of them naming a slot this
    pass promotes -- and prom_a belongs to another lane, so this pass may not
    touch it.  Renaming the label without a trace would strand all 210.  So the
    rewritten slot line reads

        T_PanelTask_Step:	jp 0xF86066  ; F40F34 (was T_F40F34) -> prom_a 0x06066

    and `grep -rn T_F40F34` still lands on exactly one line.  ZERO references
    dangle, in either image.  `--stale` proves it by grepping both.

⚠ THE EVIDENCE BLOCK IS DELIBERATELY **TWO** LINES, NOT THREE.
    wave7_documentation_metrics.py counts a "header" as >= 3 consecutive comment
    lines above a label.  A three-line block here would have added 273 headers
    to the tree's score for prose that is one derivative sentence repeated 273
    times -- which is the same defect a wave-7 reviewer caught when a "+35
    headers" gain turned out to be 35 removed blank lines.  Two lines carry the
    evidence and do not move the header count.  `--selftest` checks the block is
    two lines wherever this pass wrote one.

RUN
    python3 notes/prom_b_thunks_round6.py            # the census -- the table above
    python3 notes/prom_b_thunks_round6.py --proposals
    python3 notes/prom_b_thunks_round6.py --rejected # re-measures R1, R2, R3
    python3 notes/prom_b_thunks_round6.py --stale    # dangling-reference check
    python3 notes/prom_b_thunks_round6.py --proseaudit  # prose a rename can break
    python3 notes/prom_b_thunks_round6.py --fillcalls
    python3 notes/prom_b_thunks_round6.py --unnamed  # the 1,435 + the 115, ranked
    python3 notes/prom_b_thunks_round6.py --apply    # rewrite prom_b/wsa1_prom_b.s
    python3 notes/prom_b_thunks_round6.py --selftest # 24 checks, incl. the LAST slot
`--apply` is idempotent: a slot it has already renamed is skipped, and a second
run rewrites nothing.  Run the gate afterwards:
    python3 scripts/analysis/assert_byte_identical.py
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import wave7_documentation_metrics as M                            # noqa: E402
import prom_b_thunk_table as TT                                    # noqa: E402

SRCA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR = re.compile(r';\s*([0-9A-F]{6})\b')
TREF = re.compile(r'\bT_F4[0-9A-F]{4}\b')
# the marker this pass leaves on a slot line it has renamed
MARK = re.compile(r';\s*([0-9A-F]{6}) \(was (T_[0-9A-F]{6})\)')
SLOTDEF = re.compile(r'^(T_[A-Za-z0-9_]+):(\s*)(jp\b|\.long\b)')

RANK = {"content": 3, "framed": 2, "sub": 1, "internal": 0}


def grade(name):
    """The grade wave7_documentation_metrics.py would give this label. Imported
    classifiers, not a re-implementation -- so 'content' means here exactly what
    it means in the goal metric."""
    if M.UNNAMED.match(name):
        return "sub"
    if M.INTERNAL.match(name):
        return "internal"
    if M.FRAMED.match(name):
        return "framed"
    return "content"


def scan(path):
    """(addr -> [labels defined there], set of addresses the .s disassembles).

    A label is bound to the address printed in the trailing `; XXXXXX` comment of
    the first CONTENT line after it. `.L` compiler-locals are skipped, as
    wave7_documentation_metrics.py skips them."""
    at, seen, pend = {}, set(), []
    for ln in open(path):
        ln = ln.rstrip("\n")
        m = LABEL.match(ln)
        rest = ln
        if m:
            pend.append(m.group(1))
            rest = ln[m.end():]
        if rest.lstrip().startswith(";") or rest.strip() == "":
            continue
        a = ADDR.search(rest)
        if a:
            v = int(a.group(1), 16)
            seen.add(v)
            if pend:
                at.setdefault(v, []).extend(pend)
        pend = []
    return at, seen


_CACHE = {}


def maps():
    if not _CACHE:
        _CACHE["a"] = scan(SRCA)
        _CACHE["b"] = scan(SRCB)
    return _CACHE["a"], _CACHE["b"]


def slots():
    """[(slot_address, kind, target)] for every non-fill slot, DERIVED FROM THE
    ROM through the committed classifier -- never from the .s text, so a mistake
    in the assembly's comments cannot propagate into a name."""
    _a, b = TT.load()
    out = []
    for o in range(TT.TBL_LO, TT.TBL_HI, 4):
        k, v = TT.classify(b, o)
        if k == "fill":
            continue
        out.append((0xF00000 + o, k, v & 0xFFFFFF))
    return out


def target_label(t):
    """(name, grade, where) for the thunk target at address t."""
    (la, sa), (lb, sb) = maps()
    labs, seen, where = (la.get(t), sa, "prom_a") if t >= 0xF80000 else (lb.get(t), sb, "prom_b")
    if not labs:
        return (None, "disassembled" if t in seen else "incbin", where)
    best = max(labs, key=lambda n: RANK[grade(n)])
    return (best, grade(best), where)


def census():
    rows = []
    for slot, kind, t in slots():
        name, g, where = target_label(t)
        rows.append((slot, kind, t, name, g, where))
    return rows


def proposals():
    """{slot_address: (new_name, target, target_name)} plus the exclusion log."""
    rows = census()
    content = [r for r in rows if r[4] == "content"]
    used = collections.Counter(r[3] for r in content)
    keep, drop = {}, []
    for slot, kind, t, name, g, where in content:
        if used[name] > 1:
            drop.append((slot, t, name, "R3: %d slots share this target" % used[name]))
            continue
        new = "T_" + name
        if grade(new) != "content":
            drop.append((slot, t, name, "R2: T_%s would still grade %s" % (name, grade(new))))
            continue
        keep[slot] = (new, t, name)
    return keep, drop, rows


# ------------------------------------------------------------------ reporting
def report():
    rows = census()
    g = collections.Counter(r[4] for r in rows)
    keep, drop, _ = proposals()
    print("prom_b thunk directory 0xF40000-0xF44017 -- %d non-fill slots" % len(rows))
    print()
    print("  %-24s %6s" % ("target label grade", "slots"))
    for k in ("content", "framed", "sub", "internal", "disassembled", "incbin"):
        if g[k]:
            print("  %-24s %6d" % (k, g[k]))
    print("  %-24s %6d" % ("TOTAL", sum(g.values())))
    print()
    unnamed = g["sub"] + g["disassembled"] + g["incbin"]
    print("  ★ %d of %d slots (%.1f%%) point at something nobody has named."
          % (unnamed, len(rows), 100.0 * unnamed / len(rows)))
    print("    %d point at a sub_XXXXXX routine; %d at an address the .s DOES"
          % (g["sub"], g["disassembled"]))
    print("    disassemble but that carries no label; %d into a span still .incbin."
          % g["incbin"])
    print()
    print("  promotable: %d  (%d content targets, %d dropped: %s)"
          % (len(keep), g["content"], len(drop),
             ", ".join(sorted(set(d[3].split(":")[0] for d in drop)))))
    print("  ⚠ every one of those %d names is DERIVATIVE -- it is the target's own"
          % len(keep))
    print("    name, given by another lane.  See this file's docstring.")


def show_proposals():
    keep, drop, _ = proposals()
    for slot in sorted(keep):
        new, t, name = keep[slot]
        print("  T_%06X -> %-44s  (target 0x%06X = %s)" % (slot, new, t, name))
    print("  %d promotions" % len(keep))
    print()
    for slot, t, name, why in sorted(drop):
        print("  T_%06X KEPT FRAMED -- %s (target 0x%06X = %s)" % (slot, why, t, name))
    print("  %d kept framed although the target is content-named" % len(drop))


def show_unnamed():
    """★ The remaining work, ranked by how hard the machine leans on the slot."""
    a, b = TT.load()
    xr = TT.xrefs(a, b)
    rows = [r for r in census() if r[4] in ("sub", "disassembled", "incbin")]
    rows.sort(key=lambda r: -xr.get(r[0], 0))
    print("  %-10s %5s  %-10s %s" % ("slot", "xrefs", "target", "state"))
    for slot, kind, t, name, g, where in rows[:60]:
        print("  T_%06X %5d  0x%06X  %s %s"
              % (slot, xr.get(slot, 0), t, where, name or "(" + g + ")"))
    print("  ... %d slots in total; xref counts are the UPPER BOUND documented in"
          % len(rows))
    print("  scripts/analysis/prom_b_thunk_table.py -- they RANK slots, they do not count calls.")


def show_rejected():
    """Re-measure R1, R2 and R3 rather than asserting them from prose."""
    rows = census()
    g = collections.Counter(r[4] for r in rows)
    print("R1  name a slot after a sub_XXXXXX target")
    print("      yield: +%d slots" % g["sub"])
    print("      the stripped variant `T_<target address>` re-grades as: %s"
          % grade("T_F86066"))
    print("      -> rejected: it launders %d unnamed routines and the metric is right"
          % g["sub"])
    print("         to call the stripped spelling framed.")
    print()
    print("R2  name a slot after a FRAMED target")
    fr = [r for r in rows if r[4] == "framed"]
    print("      yield: +%d slots, and every one of them re-grades as:" % len(fr))
    for slot, kind, t, name, gg, where in fr:
        print("        T_%06X -> T_%-34s %s" % (slot, name, grade("T_" + name)))
    print("      -> rejected: 0 of %d would change grade.  Pure churn." % len(fr))
    print()
    print("R3  disambiguate the alias pairs with a suffix")
    content = [r for r in rows if r[4] == "content"]
    used = collections.Counter(r[3] for r in content)
    dups = {k: v for k, v in used.items() if v > 1}
    print("      %d content targets are each named by 2 slots (%d slots):"
          % (len(dups), sum(dups.values())))
    for name in sorted(dups):
        ss = [r for r in content if r[3] == name]
        print("        0x%06X <- %s" % (ss[0][2], " ".join("T_%06X" % r[0] for r in ss)))
    print("      -> rejected: the two slots share ONE target address, so a suffix")
    print("         would have to invent which is primary.  All %d stay framed."
          % sum(dups.values()))


def show_stale():
    """Prove the pass strands nothing: every T_<address> spelling still referred to
    anywhere in the tree must still occur in prom_b."""
    keep, _drop, _rows = proposals()
    bsrc = open(SRCB).read()
    bad = 0
    for path in (SRCA, SRCB, os.path.join(ROOT, "prom_c", "wsa1_prom_c.s"),
                 os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")):
        refs = collections.Counter(TREF.findall(open(path).read()))
        miss = [k for k in refs if k not in bsrc]
        print("  %-28s %4d distinct T_ spellings referenced, %d not present in prom_b"
              % (os.path.basename(path), len(refs), len(miss)))
        bad += len(miss)
        for k in sorted(miss)[:10]:
            print("      DANGLING %s (x%d)" % (k, refs[k]))
    print("  %d dangling references" % bad)
    return bad


# --------------------------------------------------------------------- apply
def slot_of_line(ln):
    """The slot address a thunk-table line defines, in EITHER state: the
    unrenamed `T_<hex>:` spelling, or a renamed line carrying this pass's
    `; XXXXXX (was T_XXXXXX)` marker.  Returns None for anything else."""
    m = SLOTDEF.match(ln)
    if not m:
        return None
    lab = m.group(1)
    if re.fullmatch(r'T_[0-9A-F]{6}', lab):
        return int(lab[2:], 16)
    k = MARK.search(ln)
    return int(k.group(1), 16) if k else None


EV1 = ("; Evidence: slot 0x%06X is `%s 0x%06X`; %s 0x%06X carries the label %s,")
EV2 = ("            which wave7_documentation_metrics.py grades CONTENT.  "
       "DERIVATIVE name.")


def apply_():
    keep, _drop, _rows = proposals()
    src = open(SRCB).read().split("\n")
    out, renamed, already = [], 0, 0
    ren = {}
    # pass 1: rewrite the slot definitions
    for ln in src:
        slot = slot_of_line(ln)
        if slot is None or slot not in keep:
            out.append(ln)
            continue
        if MARK.search(ln):
            already += 1
            out.append(ln)
            continue
        new, t, name = keep[slot]
        old = "T_%06X" % slot
        m = SLOTDEF.match(ln)
        body = ln[m.end(1) + 1:]
        i = body.find(";")
        head, tail = body[:i], body[i:]
        tail = "; %06X (was %s) %s" % (slot, old, tail[1:].strip())
        out.append("; Evidence: slot 0x%06X is `%s 0x%06X`; %s 0x%06X carries the label"
                   % (slot, "jp" if m.group(3).startswith("jp") else "ptr", t,
                      "prom_a" if t >= 0xF80000 else "prom_b", t))
        out.append(";           %s (graded CONTENT).  DERIVATIVE name." % name)
        out.append(new + ":" + head + tail)
        ren[old] = new
        renamed += 1
    # pass 2: rewrite every other reference (all of them are in comments -- this
    # pass measured 0 code operands naming a T_ label anywhere in the tree)
    fixed = 0
    for i, ln in enumerate(out):
        if slot_of_line(ln) is not None:
            continue                     # the slot's own line keeps the marker
        if "T_F4" not in ln:
            continue
        new = TREF.sub(lambda mm: ren.get(mm.group(0), mm.group(0)), ln)
        if new != ln:
            fixed += len(TREF.findall(ln)) - len(TREF.findall(new))
            out[i] = new
    # ---- the one NON-derivative name (see NOP_STUB above)
    # ⚠ This REPLACES the routine's whole comment block rather than prepending a
    # second one.  Prepending left two headers, the older of which still said
    # "Unknown: what the routine is FOR.  Left as sub_XXXXXX" directly above a
    # named label -- exactly the self-contradicting header a wave-7 reviewer
    # caught in round 3.  The old block's MEASURED lines (Called from / Touches
    # / Calls) are carried over; its superseded prose is dropped.
    old, new = NOP_STUB
    stub = 0
    names = (old, new)
    idx = [i for i, ln in enumerate(out)
           if any(ln.startswith(n + ":") for n in names)]
    if idx:
        sites = [x for x in fill_call_sites() if x[1] == 0xF45D04]
        assert len(sites) == 1, sites
        i = idx[0]
        j = i
        while j > 0 and out[j - 1].startswith(";"):
            j -= 1
        # Keep ONLY the three measured facts, each of which is a single line in
        # this block.  An earlier version also kept "indented continuation"
        # lines and so re-absorbed its OWN body text on every run -- the block
        # grew by five lines per --apply.  The rule is now exact, and the assert
        # fails loudly if a continuation ever appears rather than silently
        # dropping it.
        keep = [ln for ln in out[j:i]
                if re.match(r'^; (Called from|Touches|Calls):', ln)]
        for k, ln in enumerate(out[j:i]):
            if re.match(r'^; (Called from|Touches|Calls):', ln):
                nxt = out[j:i][k + 1] if k + 1 < i - j else ""
                assert not re.match(r'^;\s{6,}\S', nxt), \
                    "unexpected continuation line in the %s block: %r" % (old, nxt)
        bar = "; " + "-" * 74
        blk = [bar,
               "; %s -- prom_b 0xF45D04.  Five bytes, and it does nothing." % new]
        blk += keep
        blk += [";   `call 0xF414E0` then `ret`.  0xF414E0 is a slot of the 0xF40000",
                ";   directory and its four bytes are `0E 0E 0E 0E`; 0x0E is RET",
                ";   (mame dasm900.cpp:1267).  So the call returns immediately and the",
                ";   routine returns.  No register, no memory and no device is touched;",
                ";   the only effect is the push and pop of a return address.",
                "; Evidence: prom_b file 0x45D04 = `1d e0 14 f4 0e`, file 0x414E0 = `0e`.",
                ";           notes/prom_b_thunks_round6.py --fillcalls re-reads both and",
                ";           shows this is the ONLY decoded call into any of the 2,100",
                ";           fill slots -- one site, so an observation, not a mechanism.",
                "; Unknown: what it was FOR.  A stubbed-out feature is the obvious guess",
                ";          and is NOT asserted; the name states what the code does.",
                bar]
        body = out[:j] + blk + [new + ":" + out[i][len(out[i].split(":")[0]) + 1:]] + out[i + 1:]
        out = [re.sub(r'\b%s\b' % old, new, ln) if old in ln else ln for ln in body]
        stub = 1
    write_part(SRCB_MASTER, "\n".join(out))
    print("renamed %d slots (%d already renamed), rewrote %d references in %s"
          % (renamed, already, fixed, SRCB))
    print("plus %d non-derivative rename (%s -> %s)" % (stub, old, new))
    print("⚠ run  python3 scripts/analysis/assert_byte_identical.py  now")
    return 0


def show_proseaudit():
    """★ THE DAMAGE A MASS RENAME DOES TO PROSE, and the check for it.

    Rewriting 446 comment references is not a mechanical win: a slot name that
    appears inside a RANGE or a run shorthand stops meaning anything when one
    endpoint is renamed.  This pass produced four such lines and they were
    repaired by hand:

        `T_F42E20/24/28/2C/30`            -> `(0xF42E20, 24, 28, 2C, 30)`
        `Slots T_F40F00..T_F40F24`        -> `Slots 0xF40F00..0xF40F24`
        `T_F42770-T_F42830, point into`   -> `0xF42770-0xF42830, point into`
        `T_F42880-T_F42894 (6 slots)`     -> `0xF42880-0xF42894 (6 slots)`

    plus six sentences the rename turned into tautologies
    (`T_DisplayListB_RunOne_Stack is DisplayListB_RunOne_Stack`), rewritten to
    name the SLOT ADDRESS on one side.  This mode re-finds the pattern so the
    next mass rename does not ship it: a promoted name touching `-`, `..` or `/`
    on either side, or a line that says `X is X`."""
    names = sorted(set(v[0] for v in proposals()[0].values()), key=len, reverse=True)
    alt = "|".join(names)
    # A RANGE is a promoted name with an ADDRESS-SHAPED endpoint on the other side
    # of `..`, `-` or `/`.  Requiring the address endpoint is what separates a
    # broken range from ordinary prose: `->` and ` -- ` are everywhere in this
    # file, and without the endpoint this check fired on 14 healthy lines.
    end_r = r'(?:T_)?(?:0x)?[0-9A-F]{2,6}\b'
    end_l = r'\b(?:T_)?(?:0x)?[0-9A-F]{4,6}'
    sep = r'\s*(?:\.\.|-|/)\s*'
    rng = re.compile(r'(?:(?:%s)%s%s|%s%s(?:%s))'
                     % (alt, sep, end_r, end_l, sep, alt))
    # A TAUTOLOGY is `T_Foo <up to 12 chars> Foo` -- the sentence that used to
    # read `T_F42E0C is DisplayListB_RunOne_Stack` and now says nothing.
    taut = re.compile(r'\bT_([A-Za-z][A-Za-z0-9_]*)\b.{0,12}?\b\1\b')
    # ★ PROVE THE DETECTOR CAN FIRE.  A check that cannot fail is not a pass, and
    # these five strings are the ACTUAL lines this pass broke, before repair.
    probes = ["; Five consecutive thunk slots T_Blink_Command/24/28/2C/30 name five",
              ";   2. The thunk table.  Slots T_SC1_Vtable..T_F40F24 are one run",
              "; T_BStore_ValidateSavedCursor-T_F42830, point into it.",
              "; sits T_F42880-T_BStore_AppendBytes_Veneer (6 slots), whose target"]
    assert all(rng.search(x) for x in probes), \
        [x for x in probes if not rng.search(x)]
    assert taut.search("; and T_DisplayListB_RunOne_Stack is DisplayListB_RunOne_Stack --")
    # ...and that it does NOT fire on the healthy prose it used to flag
    healthy = ["; Called from: everywhere, through thunk T_DisplayList_Run -- the most",
               ";   T_IndexedTable_GetByte -> 0xF5533C  119 opcode-anchored references",
               "; T_Dispatch_Code80 -> 0xF5B9B8 (109), ranked by"]
    assert not any(rng.search(x) or taut.search(x) for x in healthy), \
        [x for x in healthy if rng.search(x) or taut.search(x)]
    bad = 0
    for n, ln in enumerate(open(SRCB), 1):
        ln = ln.rstrip("\n")
        if not ln.lstrip().startswith(";"):
            continue
        why = []
        if rng.search(ln):
            why.append("range/shorthand")
        if taut.search(ln):
            why.append("tautology")
        if why:
            bad += 1
            print("  %6d  %-22s %s" % (n, ",".join(why), ln.strip()[:96]))
    print("  %d suspect lines" % bad)
    return bad


# ---------------------------------------------------------- the one real find
# ★ NOT DERIVATIVE, and it came out of the census as a by-product.
# The dangling-reference sweep found THREE `T_F4xxxx` spellings referenced in
# prom_b that are not slots at all: 0xF40EFC and 0xF40F28 are named in a comment
# that correctly calls them `0E 0E 0E 0E` fill, and 0xF414E0 is named in a
# `Calls:` header -- i.e. something in prom_b CALLS a directory slot that is
# empty.  It does:
#
#     sub_F45D04:  1d e0 14 f4   call 0xF414E0      <- the slot is `0E` = ret
#                  0e            ret
#
# Five bytes, and both of them return.  The routine has no effect but stack
# traffic.  That is a name taken from WHAT THE ROUTINE CONTAINS, not from
# somebody else's label, so it is the only name in this file that is not
# derivative.  It is also a SINGLETON and this file says so: scanning every
# `call`/`jp` decoded in prom_a and prom_b for an operand landing on one of the
# 2,100 fill slots finds exactly ONE site, this one (`--fillcalls`).  One
# occurrence is an observation, not a mechanism.
# ⚠ WHAT IT WAS FOR IS UNKNOWN.  A stubbed-out feature is the obvious guess and
# is NOT asserted: the name says what the code does, which is nothing.
NOP_STUB = ("sub_F45D04", "Nop_CallsEmptyDirectorySlot")


def fill_slots():
    _a, b = TT.load()
    return set(0xF00000 + o for o in range(TT.TBL_LO, TT.TBL_HI, 4)
               if TT.classify(b, o)[0] == "fill")


CALLSITE = re.compile(r';\s*([0-9A-F]{6})\s+(call|jp)\s+0x([0-9a-f]{6})')


def fill_call_sites():
    """Every call/jp DECODED IN THE ASSEMBLY whose operand is an empty slot.
    Decoded, not byte-scanned: a byte-scan of the table's own address space
    would count operand bytes inside other instructions (the upper-bound trap
    documented in scripts/analysis/prom_b_thunk_table.py)."""
    fs = fill_slots()
    out = []
    for tag, path in (("prom_a", SRCA), ("prom_b", SRCB)):
        for ln in open(path):
            m = CALLSITE.search(ln)
            if m and int(m.group(3), 16) in fs:
                out.append((tag, int(m.group(1), 16), m.group(2), int(m.group(3), 16)))
    return out


def show_fillcalls():
    fs = fill_slots()
    sites = fill_call_sites()
    print("  %d slots in the directory are `0E`/`00` fill." % len(fs))
    print("  %d call/jp sites decoded in prom_a+prom_b target one:" % len(sites))
    for tag, a, k, t in sites:
        print("    %s 0x%06X  %s 0x%06X" % (tag, a, k, t))


# ------------------------------------------------------------------ selftest
def selftest():
    ok = fail = 0

    def chk(desc, got, want):
        nonlocal ok, fail
        good = got == want
        ok, fail = ok + good, fail + (not good)
        print("  %-64s %-26s (want %-26s) %s"
              % (desc, got, want, "OK" if good else "FAIL"))

    rows = census()
    chk("non-fill slots (= the published 1,976 jp + 26 ptr)", len(rows), 2002)
    chk("kinds", (sum(1 for r in rows if r[1] == "jp"),
                  sum(1 for r in rows if r[1] == "ptr")), (1976, 26))
    g = collections.Counter(r[4] for r in rows)
    chk("target grades sum to the slot count",
        g["content"] + g["framed"] + g["sub"] + g["internal"]
        + g["disassembled"] + g["incbin"], 2002)
    chk("no thunk target resolves to an INTERNAL branch label", g["internal"], 0)

    # ★ TESTED ON THE LAST ELEMENT AS WELL AS THE FIRST -- the rule this project
    # pays for when it is skipped.
    first, last = rows[0], rows[-1]
    chk("FIRST slot is the 0xF40000 pointer to prom_a 0xF82010",
        (("T_%06X" % first[0]), first[1], ("0x%06X" % first[2])),
        ("T_F40000", "ptr", "0xF82010"))
    chk("LAST slot address, kind and target", (("T_%06X" % last[0]), last[1],
                                               ("0x%06X" % last[2])),
        ("T_F44010", "jp", "0xF44095"))
    chk("LAST slot's target label and grade -- it is NOT promotable",
        (last[3], last[4]), ("sub_F44095", "sub"))
    a, b = TT.load()
    o = last[0] - 0xF00000
    chk("LAST slot's ROM bytes really spell `jp <target>`",
        (b[o], b[o + 1] | b[o + 2] << 8 | b[o + 3] << 16), (0x1B, last[2]))
    chk("LAST slot's grade is one of the six the report prints",
        last[4] in ("content", "framed", "sub", "disassembled", "incbin"), True)

    keep, drop, _ = proposals()
    # ⚠ NOT A PIN.  This number MUST grow: every time another lane gives a
    # content name to a routine a slot points at, one more slot becomes
    # promotable.  It went 273 -> 277 within this same round, when
    # notes/gen_prom_b_f5553f_module.py named four routines in 0xF5553F-0xF57D1D.
    # A constant here would have failed on the tree getting BETTER -- the exact
    # trap wave7_documentation_metrics.py documents in its own selftest.  So the
    # check is the INVARIANT and the count is printed.
    chk("promotions -- a floor, not a pin (it grows as targets get named): %d"
        % len(keep), len(keep) >= 273, True)
    chk("kept framed although content-named (R3 alias pairs)", len(drop), 12)
    chk("every promotion's new name grades CONTENT",
        all(grade(v[0]) == "content" for v in keep.values()), True)
    chk("no promotion collides with an existing prom_b label",
        len(set(v[0] for v in keep.values()) &
            set(re.findall(r'^([A-Za-z_][A-Za-z0-9_]*):', open(SRCB).read(), re.M))
            - set(v[0] for v in keep.values())), 0)
    chk("promotion names are unique", len(set(v[0] for v in keep.values())), len(keep))
    chk("every promotion's target label is CONTENT, never sub_ or framed",
        sorted(set(grade(v[2]) for v in keep.values())), ["content"])
    # R2 is free to reject: it changes no grade
    fr = [r for r in rows if r[4] == "framed"]
    chk("R2: framed targets whose T_ spelling would change grade",
        sum(1 for r in fr if grade("T_" + r[3]) == "content"), 0)
    # R1's stripped variant
    chk("R1: `T_<target address>` re-grades as framed", grade("T_F86066"), "framed")

    # the promotable set is exactly the slots the apply pass would touch
    src = open(SRCB).read().split("\n")
    defs = [ln for ln in src if slot_of_line(ln) is not None]
    chk("slot definition lines found in the .s", len(defs), 2002)
    chk("every slot address in the .s matches a ROM-derived slot",
        sorted(slot_of_line(ln) for ln in defs) == sorted(r[0] for r in rows), True)

    # the evidence block is TWO lines wherever this pass wrote one
    # ⚠ THE HEADER COUNT MUST NOT MOVE.  wave7_documentation_metrics.py calls a
    # block of >= 3 comment lines above a label a HEADER.  This pass writes TWO
    # lines, so it adds no headers -- except where the slot ALREADY had prose
    # above it, and those slots were already headed or already close to it.
    # The check reports both populations rather than demanding one number.
    two = pre = 0
    for i, ln in enumerate(src):
        if MARK.search(ln) and slot_of_line(ln) is not None:
            n, j = 0, i - 1
            while j >= 0 and src[j].startswith(";"):
                n += 1
                j -= 1
            two += (n == 2)
            pre += (n > 2)
    chk("every renamed slot carries a comment block written by this pass",
        two + pre, len(keep))
    chk("...of which %d are exactly this pass's two lines" % two, two, len(keep) - pre)
    chk("...and %d already had prose above them, so the pass adds at most that "
        "many headers" % pre, pre <= 2, True)

    chk("dangling T_<address> references anywhere in the tree", show_stale_quiet(), 0)
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        n_pro = show_proseaudit()
    chk("comment lines where a promoted name sits in a range or a tautology", n_pro, 0)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


def show_stale_quiet():
    bsrc = open(SRCB).read()
    bad = 0
    for path in (SRCA, SRCB, os.path.join(ROOT, "prom_c", "wsa1_prom_c.s"),
                 os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")):
        for k in set(TREF.findall(open(path).read())):
            if k not in bsrc:
                bad += 1
    return bad


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--apply" in sys.argv:
        return apply_()
    if "--proposals" in sys.argv:
        show_proposals()
        return 0
    if "--rejected" in sys.argv:
        show_rejected()
        return 0
    if "--stale" in sys.argv:
        show_stale()
        return 0
    if "--unnamed" in sys.argv:
        show_unnamed()
        return 0
    if "--fillcalls" in sys.argv:
        show_fillcalls()
        return 0
    if "--proseaudit" in sys.argv:
        show_proseaudit()
        return 0
    report()
    return 0


if __name__ == "__main__":
    sys.exit(main())
