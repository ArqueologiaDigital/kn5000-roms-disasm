#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF7E2D8-0xF7FFFF -- THE PANEL-SCREEN METHOD
BLOCK: 15 screens' Enter bodies, their 15 Leave targets (three of which are a
bare `ret`), one Button body, 124 button handlers, and five blink-template
pointer tables.

QUESTION IT ANSWERS
  "What is the assembly text for this 7,464-byte `.incbin`, in a form the byte
   gate accepts, with every label and header attached to the right address --
   and which of its objects can be NAMED rather than framed?"

────────────────────────────────────────────────────────────────────────────────
★ READ THIS BEFORE QUOTING THE CONVERSION AS PROGRESS
────────────────────────────────────────────────────────────────────────────────
  Round 7 named this span as the next lever because 15 of the 25 panel screens'
  Enter methods live in it.  They do, and the title rule reaches all 14 of them
  that draw a titled list.  But the span is 210 routines, and 124 of them are
  BUTTON HANDLERS whose only distinguishing feature is a button NUMBER -- the
  thing round 6 refused to spell into a name.  So the honest yield is

      30 CONTENT names, 5 FRAMED, 180 sub_XXXXXX

  and 14.0% of the labels this splice adds are content, against prom_b's
  standing LOWER bound of 16.2%.  ★ SO THE SPLICE ON ITS OWN MOVES prom_b's
  LOWER BOUND DOWN, and this is MEASURED, not estimated:

      prom_b   content  framed  sub_XXXX   LOWER   UPPER  headers  evidence
      before       953   3,087     1,851   16.2%   68.6%    3,233     3,057
      after        983   3,092     2,031   16.1%   66.7%    3,268     3,272

  It is a smaller fall than round 7's 0xF78029 splice (16.5% -> 16.2%) because
  this span is code with readable screens in it -- but it is a fall, and it
  belongs in the report next to the byte count.

  ★★ WHAT PAYS FOR IT is a separate, deliberate move in the same session:
  `notes/prom_b_screens_round8.py --promote --apply` promotes the 32 button
  tables at 0xF7D2D8 from `Table_<address>` -- framed -- to
  `ButtonTable_<Screen>` -- content -- because round 7 established what they
  are and this round has the owner map.  With that:

      after +32   1,015   3,060     2,031   16.6%   66.7%    3,299     3,304

  So prom_b ends the round 0.4 points UP on LOWER, not 0.1 down.  Both numbers
  are in the report, because quoting only the second would hide the cost of the
  conversion, and quoting only the first would hide what the round did about it.

  ⚠ 190 ADDRESSES THAT ARE ENTRY POINTS DELIBERATELY GET NO LABEL.  510 of the
  649 button-table slots that land here point at a single `ret` BYTE -- the
  unused-button convention.  Labelling each would add 190 framed labels to say
  one thing 190 times; instead each is a trailing comment on the `ret` line it
  falls on.  `notes/prom_b_screens_round8.py --buttons` measures it.

────────────────────────────────────────────────────────────────────────────────
WHAT THE SPAN IS, AND WHAT PINS EACH PART
────────────────────────────────────────────────────────────────────────────────
    code    7,359   six segments
    ptrtab    104   five blink-template pointer tables (4, 5, 7, 5 and 5 words)
    pad         1   one 0x0E (`ret`) byte below the 0xF7F521 table
    -----   7,464

  THE FIVE TABLES ARE FOUND BY THEIR OWN READERS, not by a rule over bytes: the
  span holds exactly five `ld XIY,imm32` whose immediate lands inside the span,
  and each is followed by `ld XIY,(XIY+WA)`, `push XIY` and `call 0xF42E20` --
  `T_Blink_Command`, prom_b 0xF0E9CF (notes/FINDINGS-prom_b-field-blink.md).
  The same shape, callee and two-leading-NULLs opening as prom_a's documented
  `BlinkArgPtrs_F8024D`.  Each table ends where the next ENTRY POINT begins, and
  for the last of the five that boundary is 0xF7FF27 -- the Enter body of the
  ADVANCE/DELAY screen, so the bound is a call target and not a guess.

  EVERYTHING ELSE IS CODE, and the layout is not a linear-decode assumption:
  all 314 button-table targets and 37 of the 38 opcode-anchored `call nnn` /
  `jp nnn` targets fall on an instruction boundary of the whole-span linear
  decode.  The ONE that does not is 0xF7FF27, and the reason is the pointer
  table immediately above it -- which is how the fifth table was found.  ★ BOTH
  HALVES OF THAT SENTENCE ARE REPRODUCED BY CHECKS, not just its consequence:
  the two `CODE` checks re-run the whole-span linear decode and list the
  exceptions, and the list is exactly [0xF7FF27].

NOTHING HERE CAN BREAK THE GATE
  Every byte is printed from the ROM through llvm_roundtrip_autoforce, which
  assembles what it prints before printing it.  verify_region() then assembles
  the WHOLE emitted text and compares all 7,464 bytes against the ROM, and
  --splice refuses to write if that differs or if any check fails.

RUN
  python3 notes/gen_prom_b_f7e2d8_module.py             # the assembly
  python3 notes/gen_prom_b_f7e2d8_module.py --layout    # the segment table
  python3 notes/gen_prom_b_f7e2d8_module.py --cost      # the naming cost
  python3 notes/gen_prom_b_f7e2d8_module.py --selftest  # checks, incl. the LAST
  python3 notes/gen_prom_b_f7e2d8_module.py --splice    # write it into the .s
Then, always:
  python3 scripts/analysis/assert_byte_identical.py
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_screens_round8 as S                                  # noqa: E402

LO, HI = S.LO, S.HI
B_BASE = S.B_BASE
SRCB = S.SRCB
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
FAIL = []
_c = {}


# ------------------------------------------------------------------ layout
def layout():
    """[(kind, start, length)] tiling [LO,HI).

    Re-derived on EVERY run from prom_b_screens_round8.ptr_tables(), which finds
    the tables through their readers.  The emitter refuses to print if the
    segments stop tiling."""
    if "ly" in _c:
        return _c["ly"]
    segs, p = [], LO
    for base, n, pad, _v, _r in S.ptr_tables():
        if base > p:
            segs.append(("code", p, base - p))
        segs.append(("ptrtab", base, 4 * n))
        if pad:
            segs.append(("pad", base + 4 * n, pad))
        p = base + 4 * n + pad
    if p < HI:
        segs.append(("code", p, HI - p))
    _c["ly"] = segs
    return segs


# ----------------------------------------------------------- transcription
def transcribe(start, length):
    key = ("t", start, length)
    if key not in _c:
        out = subprocess.run([sys.executable, AUTOFORCE, "b", hex(start), hex(length),
                              "--quiet"], capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, out.stderr[-2000:]))
        _c[key] = out.stdout.rstrip("\n").split("\n")
    return _c[key]


def code_lines():
    """[(address, emitted line)] for every code segment, in address order."""
    if "cl" not in _c:
        out = []
        for kind, s, n in layout():
            if kind != "code":
                continue
            for ln in transcribe(s, n):
                m = re.search(r";\s*([0-9A-F]{6})\s", ln)
                if m:
                    out.append((int(m.group(1), 16), ln))
        _c["cl"] = out
    return _c["cl"]


def boundaries():
    return set(a for a, _l in code_lines())


# -------------------------------------------------------------- annotation
def button_index():
    """{target: [(table base, index, screen)]} for the in-span button slots."""
    if "bi" not in _c:
        own = S.table_owner()
        d = collections.defaultdict(list)
        for t, i, v in S.button_slots():
            if LO <= v < HI:
                d[v].append((t, i, " / ".join(own.get(t, ["?"]))))
        _c["bi"] = d
    return _c["bi"]


def callers(a):
    """The non-button reasons prom_b_screens_round8 recorded for this address."""
    out = []
    for r in S.entry_points().get(a, []):
        if r.startswith("button"):
            continue
        m = re.match(r"(\S+) (0x[0-9A-Fa-f]+) ([ab])$", r)
        out.append("%s from prom_%s %s" % (m.group(1), m.group(3), m.group(2))
                   if m else r)
    return out


def wrap(prefix, text, width=76):
    """Comment lines.  ★ EVERY line this returns starts with `;` -- including the
    continuations.  The first draft indented continuations with spaces, and
    llvm-mc read them as instructions; verify_region() caught it, which is what
    it is for."""
    cont = ";" + " " * (len(prefix) - 1)
    out, cur, first = [], prefix, True
    for w in text.split():
        if not first and len(cur) + 1 + len(w) > width:
            out.append(cur.rstrip())
            cur = cont + w
        else:
            cur = (cur + w) if first else (cur + " " + w)
        first = False
    if cur.strip(" ;"):
        out.append(cur.rstrip())
    return out or [prefix.rstrip()]


def header_for(start, end, label, ev):
    """The comment block above a label.

    ★ TWO SHAPES ON PURPOSE.  A NAMED routine gets a full header -- what it is,
    who reaches it, the evidence for the name, and what is still unknown.  A
    `sub_XXXXXX` routine gets a TWO-LINE Evidence block carrying only the facts
    that differ between one handler and the next (its screen, its table, its
    index, its caller); the prose that would be identical in 180 copies lives in
    the block banner instead.  That is round 7's discipline from the 0xF78029
    splice, and the reason is the same: a header count made of one templated
    sentence repeated is the "+35 headers that were 35 blank lines" defect."""
    bi, cl = button_index().get(start, []), callers(start)
    mb = S.method_bodies().get(start)
    if ev:                                                  # a NAMED routine
        L = ["; ---------------------------------------------------------------------"]
        L += wrap("; %s -- " % label, _one_liner(label, start, mb))
        L.append(";")
        if mb:
            role, base, nm = mb
            L += wrap("; Reached by: ", "the +%d method stub of screen object 0x%06X, "
                      "which prom_a's PanelScreen_VtableTable names."
                      % ({"Enter": 0, "Leave": 4, "Button": 8, "Null": 0x0C}[role], base))
        if cl:
            L += wrap("; Called from: ", "; ".join(cl[:6])
                      + ("" if len(cl) <= 6 else "; and %d more" % (len(cl) - 6)))
        if bi:
            L += wrap("; Button slots: ", "; ".join(
                "table 0x%06X entry %d (%s)" % (t, i, s) for t, i, s in bi[:4]))
        L += wrap("; Evidence: ", " ".join(ev))
        L.append("; ---------------------------------------------------------------------")
        return L
    # an UNNAMED routine: two lines, facts only
    if bi:
        more = "" if len(bi) == 1 else " (+%d more slots)" % (len(bi) - 1)
        txt = ("table 0x%06X entry %d, screen %s%s.  A bare button number, so "
               "no name; see the banner." % (bi[0][0], bi[0][1], bi[0][2], more))
    elif mb:
        txt = ("screen 0x%06X's %s method body; that screen's Enter draws no "
               "titled list, so it has no name." % (mb[1], mb[0]))
    elif cl:
        txt = "reached from %s, and from nothing else the scans see." % "; ".join(cl[:2])
    else:
        txt = ("no caller: not in the four-image opcode scan, the .s calr/jrl scan "
               "or the 32 button tables.")
    L = wrap("; Evidence: ", txt)
    # ★ TWO LINES, GUARANTEED, and NEVER a truncated sentence.  An earlier draft
    # sliced the list to [:2] and cut sentences in half; the fix is to shorten
    # the SENTENCE, not the block.  Check EV2 asserts the bound holds.
    while len(L) > 2:
        txt = txt[:txt.rindex(".  ")] + "." if ".  " in txt else txt
        nl = wrap("; Evidence: ", txt)
        if nl == L:
            break
        L = nl
    return L[:2]


def _one_liner(label, start, mb):
    if label.startswith("Paint_TrackLabels"):
        return "draws the eight track labels its own list spells"
    if label.startswith("Paint_"):
        return "paints the panel screen whose own title text reads \"%s\"" \
               % S.painters()[start][0]
    if label.startswith("ScreenLeaveBody_"):
        return "the whole body of the %s screen's Leave method" % label.split("_", 1)[1]
    if label.startswith("ScreenButtonBody_"):
        return "the whole body of the %s screen's Button method" % label.split("_", 1)[1]
    if label.startswith("LCD_ScreenRedraw_Begin"):
        return ("blank the panel, re-issue SYSTEM SET for three layers, select "
                "layer 0 -- prom_b's own copy of the prom_a routine of this name")
    if label.startswith("LCD_ScreenRedraw_End"):
        return ("make all three layers visible again -- prom_b's own copy of the "
                "prom_a routine of this name")
    if label.startswith("BlinkArgPtrs_"):
        return "pointers to blink templates, read through Blink_Command"
    return "see the evidence below"


# -------------------------------------------------------------------- emit
def banner():
    cen = S.button_census()
    nm = S.names()
    g = collections.Counter(S.grade(v[0]) for v in nm.values())
    return [
        "; " + "=" * 78,
        "; 0x%06X-0x%06X -- THE PANEL-SCREEN METHOD BLOCK: 15 Enter bodies, 15 Leave"
        % (LO, HI - 1),
        "; targets (three of them a bare `ret`), one Button body, %d button handlers,"
        % cen["code_targets"],
        "; and five blink-template pointer tables",
        "; " + "=" * 78,
        ";",
        "; %d bytes.  This is the other half of the block above it: 0xF7D000-0xF7E2D7"
        % (HI - LO),
        "; holds the 25 screens' four-word method STUBS and their 32 button tables,",
        "; and every stub is a one-line forwarder into the bytes below.",
        ";",
        "; ★ THE NAMES.  A screen's Enter body draws the screen, and the leading run",
        "; of op-0x1C records in the display list it hands the interpreter spells the",
        "; screen's own title.  That is round 7's rule and it is CALIBRATED, not",
        "; asserted: seven screens whose Enter body is in prom_a carry names prom_a",
        "; derived independently months earlier, and the rule reproduces all seven as",
        "; a prefix and six exactly.  Re-run it with",
        ";     python3 notes/prom_b_screens_round8.py --calibrate",
        "; 14 routines here draw a titled list and are named Paint_<Title>, keeping",
        "; the ROM's own spelling -- VEL0CITY, TRANSP0SE, zeros for O's included.",
        ";",
        "; ★ TWO ROUTINES ARE prom_a ROUTINES.  0x%06X is byte-identical to prom_a's"
        % S.TWINS[0][0],
        "; LCD_ScreenRedraw_Begin (0x%06X) over both whole extents -- %d bytes, 0"
        % (S.TWINS[0][2], S.TWINS[0][1]),
        "; differing -- and 0x%06X to LCD_ScreenRedraw_End (0x%06X), %d bytes, 0"
        % (S.TWINS[1][0], S.TWINS[1][2], S.TWINS[1][1]),
        "; differing.  They keep prom_a's spelling so the pair reads as one object.",
        ";",
        "; ⚠ %d OF THE %d ROUTINES KEEP sub_XXXXXX, AND THE REASON IS ONE FACT."
        % (g["unnamed"], len(S.routines())),
        "; The 32 tables at 0xF7D2D8 are indexed by the PANEL BUTTON NUMBER (round 7",
        "; established that: two independent 5-bit masks over a 128-byte table).  So",
        "; what distinguishes one handler from the next is a bare number, and a name",
        "; built on it -- ScreenBtn_Quantize_11 -- would grade as content while",
        "; stating nothing.  Round 6 refused exactly that shape (Write3602_Index5)",
        "; and this block refuses it again.  The ROM names only THREE of the 32",
        "; codes, in prom_a's PanelButton_Route: 0x0D the data dial, 0x0E and 0x0F.",
        "; The service screen that would be the natural place for a switch list,",
        '; Paint_PanelSwLedCheck, draws "Please push a any button." and no per-switch',
        "; text.  There is nothing to map an index onto, so the gap is stated instead",
        "; of filled.  Each handler's own Evidence line names its screen and index.",
        ";",
        "; ⚠ %d ADDRESSES IN HERE ARE ENTRY POINTS AND CARRY NO LABEL, ON PURPOSE."
        % cen["ret_targets"],
        "; %d of the %d button-table slots that land in this span (%.1f%%) point at a"
        % (cen["ret_slots"], cen["inspan"], 100.0 * cen["ret_slots"] / cen["inspan"]),
        "; single `ret` BYTE -- an unused button on that screen, pointed at whatever",
        "; `ret` happens to end the routine above it.  They are annotated where they",
        "; fall, as a trailing comment on the `ret` line, because %d framed labels"
        % cen["ret_targets"],
        "; saying one thing %d times is not documentation." % cen["ret_targets"],
        ";",
        "; ★ THE FIVE POINTER TABLES ARE FOUND BY THEIR OWN READERS.  Each is the",
        "; immediate of an `ld XIY,imm32` inside this span, followed by",
        "; `ld XIY,(XIY+WA)`, `push XIY` and `call 0x%06X` = T_Blink_Command ->"
        % S.BLINK_CMD,
        "; prom_b 0xF0E9CF (notes/FINDINGS-prom_b-field-blink.md).  Same shape, same",
        "; callee and the same two leading NULL entries as prom_a's BlinkArgPtrs_F8024D.",
        "; ⚠ NOTHING BOUNDS THE INDEX, so the entry counts below are 'words that fit",
        "; before the code resumes' -- the same claim prom_a's header makes -- and the",
        "; tables keep FRAMED names.",
        ";",
        "; ★ THE FOUR SCREENS ROUND 7 LEFT UNNAMED STAY UNNAMED, and now the reason is",
        "; exact: 0xF43040's Enter (0x%06X, three instructions, here) draws no display"
        % 0xF7E971,
        "; list at all; 0xF43048's is prom_a ModeEnterBody_StepRecord and draws none; and 0xF43160",
        "; and 0xF431D0 SHARE ONE ENTER METHOD, prom_a ScreenEnterBody_StepRecord -- so a rule that",
        "; names a screen after what its Enter draws cannot separate those two even in",
        "; principle.  `--screens4` prints it from the ROM.",
        ";",
        "; Re-derive all of it, and the naming cost, with",
        ";     python3 notes/prom_b_screens_round8.py --selftest --buttons --cost",
        ";     python3 notes/gen_prom_b_f7e2d8_module.py --selftest --cost",
        "; " + "=" * 78]


def emit():
    nm = S.names()
    ends = {s: e for s, e in S.routines()}
    bi = button_index()
    out = [""] + banner() + [""]
    lines = dict(code_lines())
    for kind, s, n in layout():
        if kind == "ptrtab":
            base, cnt, pad, vals, reader = next(t for t in S.ptr_tables() if t[0] == s)
            lab, ev = nm[base]
            out += header_for(base, base + n, lab, ev)
            out.append("%s:" % lab)
            for k, v in enumerate(vals):
                out.append("\t.long 0x%08X\t; %06X  [%d]%s"
                           % (v, base + 4 * k, k, "  NULL" if v == 0 else ""))
            out.append("")
            continue
        if kind == "pad":
            out.append("\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding below the "
                       "table above" % (n, s, s + n - 1))
            out.append("")
            continue
        for a in range(s, s + n):
            if a not in lines:
                continue
            if a in ends:
                lab, ev = nm[a]
                out.append("")
                out += header_for(a, ends[a], lab, ev)
                out.append("%s:" % lab)
            ln = lines[a]
            if a in bi and a not in ends:
                ln += ("   <- button table 0x%06X entry %d (%s)%s"
                       % (bi[a][0][0], bi[a][0][1], bi[a][0][2],
                          "" if len(bi[a]) == 1 else " and %d more slot(s)" % (len(bi[a]) - 1)))
            out.append(ln)
    out.append("")
    return out


def verify_region(lines):
    import llvm_roundtrip as RT
    body = [l + "\n" for l in lines if not l.startswith(";") and l.strip()
            and not re.match(r"^[A-Za-z_][A-Za-z0-9_]*:$", l)]
    labs = [l for l in lines if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:$", l)]
    got, err = RT.assemble(body)
    if got is None:
        return False, "llvm-mc refused the emitted text:\n" + err[-2000:], labs
    want = S.bs(LO, HI - LO)
    if got != want:
        for i in range(min(len(got), len(want))):
            if got[i] != want[i]:
                return False, ("first difference at 0x%06X: emitted 0x%02X, ROM 0x%02X"
                               % (LO + i, got[i], want[i])), labs
        return False, "length differs: emitted %d, ROM %d" % (len(got), len(want)), labs
    return True, "%d bytes re-assemble to the ROM exactly" % len(got), labs


# --------------------------------------------------------------------- cost
def cost():
    nm = S.names()
    g = collections.Counter(S.grade(v[0]) for v in nm.values())
    lines = emit()
    labs = [l for l in lines if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:$", l)]
    heads = sum(1 for i, l in enumerate(lines)
                if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:$", l)
                and i >= 3 and all(lines[i - k].startswith(";") for k in (1, 2, 3)))
    ev = sum(1 for l in lines if "; Evidence:" in l)
    print("  bytes converted            : %d" % (HI - LO))
    print("  labels emitted             : %d" % len(labs))
    print("      content %d, framed %d, sub_XXXXXX %d"
          % (g["content"], g["framed"], g["unnamed"]))
    print("  headers (>=3 comment lines above a label): %d" % heads)
    print("      ⚠ every one of them is above a NAMED label.  The %d sub_XXXXXX"
          % g["unnamed"])
    print("      routines get a TWO-line Evidence block on purpose, so a templated")
    print("      sentence repeated %d times cannot enter the tree's header count."
          % g["unnamed"])
    print("  Evidence: lines            : %d" % ev)
    print("  labels NOT emitted         : %d (the `ret` button targets)"
          % S.button_census()["ret_targets"])
    print("  ⚠ %.1f%% of the new labels are content, against prom_b's standing LOWER"
          % (100.0 * g["content"] / len(nm)))
    print("    bound of 16.2%, so this splice moves that bound DOWN.  Measure it,")
    print("    do not predict it:  python3 notes/wave7_documentation_metrics.py")


# ------------------------------------------------------------------ checks
def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    if verbose:
        print(("  ok    " if ok else "  FAIL  ") + desc)
    return ok


def checks(verbose=True):
    del FAIL[:]
    L = layout()
    c("LAYOUT tiles 0x%06X-0x%06X with no gap and no overlap" % (LO, HI),
      (L[0][1], sum(n for _k, _s, n in L)), (LO, HI - LO), verbose)
    p, tiles = LO, True
    for _k, s, n in L:
        tiles = tiles and s == p
        p = s + n
    c("LAYOUT every segment starts where the previous one ends", (tiles, p),
      (True, HI), verbose)
    c("LAYOUT six code segments, five ptrtab, one pad",
      sorted(collections.Counter(k for k, _s, _n in L).items()),
      [("code", 6), ("pad", 1), ("ptrtab", 5)], verbose)
    bnd = boundaries()
    ep = S.entry_points()
    c("CODE  every entry point falls on an instruction boundary or inside a table",
      sorted("0x%06X" % a for a in ep
             if a not in bnd and not any(k != "code" and s <= a < s + n
                                         for k, s, n in L)), [], verbose)
    c("CODE  ★ the LAST entry point 0x%06X is an instruction boundary" % max(ep),
      max(ep) in bnd, True, verbose)
    # ★ REPRODUCE THE CLAIM, do not just assert its consequence.  S.decode() IS
    # the whole-span linear decode from 0xF7E2D8; the banner says every button
    # target and 37 of the 38 opcode-anchored call/jp targets land on one of its
    # boundaries, and that the single exception is 0xF7FF27.  Both halves here.
    lin = set(a for a, _t in S.decode())
    btn = sorted({v for _t, _i, v in S.button_slots() if LO <= v < HI})
    opc = set()
    for k in ("a", "b"):
        d, base = S.rom(k), (S.A_BASE if k == "a" else S.B_BASE)
        for o in range(len(d) - 3):
            if d[o] in (0x1D, 0x1B):
                v = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
                if LO <= v < HI:
                    opc.add(v)
    c("CODE  in the WHOLE-SPAN linear decode, all %d button targets are boundaries"
      % len(btn), [a for a in btn if a not in lin], [], verbose)
    c("CODE  ...and %d of the %d opcode-anchored call/jp targets are, the ONE"
      " exception being 0x%06X" % (len(opc) - 1, len(opc), 0xF7FF27),
      sorted("0x%06X" % a for a in opc if a not in lin), ["0xF7FF27"], verbose)
    c("CODE  ...and carving the table above it out makes 0x%06X a boundary here"
      % 0xF7FF27, 0xF7FF27 in bnd, True, verbose)
    lines = emit()
    labs = [l[:-1] for l in lines if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:$", l)]
    c("LABEL every label is unique", len(labs), len(set(labs)), verbose)
    c("LABEL one label per routine start plus the five tables",
      len(labs), len(S.routines()) + len(S.ptr_tables()), verbose)
    cen = S.button_census()
    ann = sum(1 for l in lines if "<- button table" in l)
    c("ANNOT the %d UNLABELLED button targets each get one trailing annotation"
      % cen["ret_targets"], ann, cen["ret_targets"], verbose)
    bi = button_index()
    labelled = [a for a in bi if a in dict(S.routines())]
    missing = [a for a in labelled
               if not any(("0x%06X" % bi[a][0][0]) in h
                          for h in header_for(a, 0, S.names()[a][0], S.names()[a][1]))]
    c("ANNOT ...and every one of the %d LABELLED button targets names its table"
      " in its own header instead" % len(labelled),
      (len(labelled), sorted("0x%06X" % a for a in missing)[:5]), (124, []), verbose)
    unnamed = [a for a, (lab, ev) in S.names().items() if not ev]
    bad = []
    for a in unnamed:
        h = header_for(a, 0, "x", [])
        if len(h) > 2 or not h[-1].rstrip().endswith((".", ")")):
            bad.append("0x%06X" % a)
    c("EV2   every sub_XXXXXX Evidence block is <=2 lines and ends a sentence",
      sorted(bad)[:5], [], verbose)
    c("ANNOT ...and %d of those lines are a bare `ret`" % cen["ret_targets"],
      sum(1 for l in lines if "<- button table" in l and re.match(r"^\tret\b", l)),
      cen["ret_targets"], verbose)
    good, msg, _labs = verify_region(lines)
    c("BYTES %s" % msg, good, True, verbose)
    if verbose and FAIL:
        print("\n%d FAILED:\n%s" % (len(FAIL), "\n".join("  " + f for f in FAIL)))
    return not FAIL


# -------------------------------------------------------------------- splice
def splice():
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to splice: a check failed (see above)")
    lines = emit()
    good, msg, _l = verify_region(lines)
    if not good:
        raise SystemExit("refusing to splice: " + msg)
    src = open(SRCB, encoding="utf-8").read().split("\n")
    want = ('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X'
            % (LO - B_BASE, HI - LO))
    hit = [i for i, l in enumerate(src) if l == want]
    if len(hit) == 1:
        i = hit[0]
        lo_ = i
        while lo_ and (src[lo_ - 1].startswith(";") or not src[lo_ - 1].strip()):
            lo_ -= 1
        hi_, how = i, "over the `.incbin`"
    else:
        body = [k for k, l in enumerate(lines) if l.strip() and not l.startswith(";")]
        first, last = lines[body[0]], lines[body[-1]]
        a_ = [k for k, l in enumerate(src) if l == first]
        b2 = [k for k, l in enumerate(src) if l == last]
        if len(a_) != 1 or len(b2) != 1:
            raise SystemExit("cannot locate the spliced region: %d head anchors, "
                             "%d tail anchors" % (len(a_), len(b2)))
        lo_, hi_ = a_[0], b2[0]
        while lo_ and (src[lo_ - 1].startswith(";") or not src[lo_ - 1].strip()):
            lo_ -= 1
        while hi_ + 1 < len(src) and not src[hi_ + 1].strip():
            hi_ += 1
        how = "in place over lines %d-%d" % (lo_ + 1, hi_ + 1)
    open(SRCB, "w", encoding="utf-8").write("\n".join(src[:lo_] + lines + src[hi_ + 1:]))
    print("spliced %d lines %s; %s" % (len(lines), how, msg))
    return 0


def main():
    a = sys.argv[1:]
    if "--splice" in a:
        return splice()
    if "--layout" in a:
        for k, s, n in layout():
            print("  %-8s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        return 0
    if "--cost" in a:
        cost()
        return 0
    if "--selftest" in a:
        return 0 if checks() else 1
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
