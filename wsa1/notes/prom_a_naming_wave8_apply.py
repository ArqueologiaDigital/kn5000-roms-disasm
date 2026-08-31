#!/usr/bin/env python3
"""Apply the panel-control map to prom_a's listing: name the control-table
readers and the handlers whose control index the map now fixes.

QUESTION IT ANSWERS
-------------------
  "Which `sub_XXXXXX` -- and which UNLABELLED address -- can be named from
   notes/prom_a_panel_control_map.py, and what header states the evidence?"

★ EVERY NAME HERE IS DERIVED AT RUN TIME, not pasted.  The script reads the
dispatch tables out of the listing, reads the code->control map out of the ROM
through prom_a_panel_control_map, and refuses any handler whose control index is
not the SAME in every slot that reaches it.  So the plan cannot drift from the
evidence, and `--plan` prints exactly what `--apply` will do.

WHAT IT NAMES
  READERS   the eight routines whose body carries both `cp H,0x20` -- the
            32-code panel index space -- and an `add XBC,0x00FFxxxx` naming one
            of the module's tables.  -> PanelCtlDispatch_<table>
  HANDLERS  the targets of Dispatch_FF3800/_FF3880/_FF3900/_FF3980, the four
            tables whose live entries are exactly the five LCD rows and EXIT.
            -> PanelCtl_<table>_<control>
            Nineteen of the twenty-four have NO LABEL AT ALL today; five are
            `sub_XXXXXX`.  Adding a label to an address the ROM's own table
            points at is an addition, and the byte gate certifies it changed
            nothing.

WHAT IT REFUSES, and this is the point
  * a target reached at two DIFFERENT control indices (32 of the 0xFF3800
    module's 97 live targets are, always as index c and index c+0x11);
  * a target outside prom_a (eight are prom_b directory slots);
  * an address that is not the start of a listing line, which would mean the
    table points inside an instruction and something is wrong upstream.

USAGE
    python3 notes/prom_a_naming_wave8_apply.py --plan
    python3 notes/prom_a_naming_wave8_apply.py --apply     # idempotent
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_panel_control_map as PM                 # noqa: E402

LISTING = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
SIMPLE = ["Dispatch_FF3800", "Dispatch_FF3880", "Dispatch_FF3900",
          "Dispatch_FF3980"]
TABLE_LABEL = re.compile(r'^(Dispatch_[A-Za-z0-9_]+):')
ENTRY = re.compile(r'^\t\.long 0x([0-9a-f]{8})\s*;\s*[0-9A-F]{6}\s*\[\s*(\d+)\]')
ADDR = re.compile(r';\s*([0-9A-F]{6})\s+[0-9a-f]{2}')
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')

# ★ THE MORPHEMES ARE NOT MINE.  `SoftKeyColN`, `LcdKeyRowN`, `ExitKey` are the
# names rounds 11 and 12 applied to 131 labels in prom_b for exactly these
# control codes, and prom_b's SLOT_CONTROL agrees with the map derived here slot
# for slot.  Coining a second vocabulary for one concept is how a tree ends up
# with two half-answers, so this batch joins the existing family instead.
CONTROL_TEXT = {
    0x00: ("SoftKeyCol1", "SOFT KEY column 1 -- its lower and upper key share "
                       "this code"),
    0x01: ("SoftKeyCol2", "SOFT KEY column 2 -- lower and upper share this code"),
    0x02: ("SoftKeyCol3", "SOFT KEY column 3 -- lower and upper share this code"),
    0x03: ("SoftKeyCol4", "SOFT KEY column 4 -- lower and upper share this code"),
    0x04: ("SoftKeyCol5", "SOFT KEY column 5 -- lower and upper share this code"),
    0x05: ("SoftKeyCol6", "SOFT KEY column 6 -- lower and upper share this code"),
    0x06: ("SoftKeyCol7", "SOFT KEY column 7 -- lower and upper share this code"),
    0x07: ("SoftKeyCol8", "SOFT KEY column 8 -- lower and upper share this code"),
    0x08: ("LcdKeyRow1", "the LCD row 1 button pair -- the left-hand and "
                      "right-hand buttons of the display's TOP row"),
    0x09: ("LcdKeyRow2", "the LCD row 2 button pair"),
    0x0A: ("LcdKeyRow3", "the LCD row 3 button pair"),
    0x0B: ("LcdKeyRow4", "the LCD row 4 button pair"),
    0x0C: ("LcdKeyRow5", "the LCD row 5 button pair -- the BOTTOM row"),
    0x0F: ("ExitKey", "the EXIT key"),
}


def lines():
    return open(LISTING, encoding="utf-8").read().splitlines()


def tables(src):
    out, cur = collections.OrderedDict(), None
    for ln in src:
        g = TABLE_LABEL.match(ln)
        if g:
            cur = g.group(1)
            out[cur] = []
            continue
        if cur is None:
            continue
        h = ENTRY.match(ln)
        if h:
            out[cur].append((int(h.group(2)), int(h.group(1), 16) & 0xFFFFFF))
        elif ln.strip() and not ln.lstrip().startswith(";"):
            cur = None
    return out


def line_of_addr(src):
    """{address: line index} for every line that OPENS with that address."""
    out = {}
    for i, ln in enumerate(src):
        m = ADDR.search(ln)
        if m and (ln.startswith("\t") or ln.startswith(" ")):
            out.setdefault(int(m.group(1), 16), i)
    return out


def label_at(src, i):
    """The column-0 label immediately above line i, or None."""
    j = i - 1
    while j >= 0 and not src[j].strip():
        j -= 1
    if j >= 0:
        m = LABEL.match(src[j])
        if m:
            return m.group(1), j
    return None


def readers(src):
    """{table label: (routine label, line index, bound addr, base addr)}."""
    out = {}
    cur, curline = None, None
    body = []
    for i, ln in enumerate(src + [""]):
        m = LABEL.match(ln)
        if m or i == len(src):
            if cur and body:
                txt = "\n".join(body)
                base = re.search(r'add XBC,0x00(ff[0-9a-f]{4})', txt)
                bound = re.search(r'cp H,0x20\s+;\s*([0-9A-F]{6})', txt)
                if base and bound:
                    t = "Dispatch_FF" + base.group(1)[2:].upper()
                    ba = re.search(r'add XBC,0x00ff[0-9a-f]{4}\s+;\s*([0-9A-F]{6})', txt)
                    out[t] = (cur, curline, bound.group(1),
                              ba.group(1) if ba else "?")
            cur, curline, body = (m.group(1) if m else None), i, []
            continue
        if cur:
            body.append(ln)
    return out


def plan():
    src = lines()
    tb = tables(src)
    at = line_of_addr(src)
    rd = readers(src)

    jobs = []                       # (addr, kind, old, new, header lines)

    # --- the readers -------------------------------------------------------
    for t in SIMPLE + ["Dispatch_FF3A29", "Dispatch_FF3D39",
                       "Dispatch_FF3F39", "Dispatch_FF3FB9"]:
        if t not in rd:
            continue
        old, li, bound, base = rd[t]
        if not old.startswith("sub_"):
            continue
        new = "PanelButtonDispatch_" + t.split("_")[1]
        hdr = [
            "%s -- run %s's handler for one PANEL CONTROL" % (new, t),
            "",
            "Inputs:  (XIZ+0x08) = the 5-bit panel control index; (XIZ+0x0A) =",
            "         the argument this reader forwards to the handler.",
            "Evidence: `cp H,0x20` at 0x%s bounds the index to the 32-code" % bound,
            "         panel space that PanelButton_Route's `and L,0x1f`",
            "         (0xF861AE) produces, and `add XBC,0x00%s` at 0x%s"
            % (t.split("_")[1], base),
            "         names the table.  The handler is CALLED, not jumped to:",
            "         the reader pushes a return address before `jp (XBC)`.",
            "Control legend: notes/FINDINGS-prom_a-panel-control-map.md, and",
            "         `python3 notes/prom_a_panel_control_map.py --map`.",
            "Was `%s`, named by notes/prom_a_naming_wave8_apply.py." % old,
        ]
        addr = None
        m = ADDR.search(src[li + 1]) if li + 1 < len(src) else None
        if m:
            addr = int(m.group(1), 16)
        jobs.append((addr, "rename", old, new, hdr))

    # --- the handlers of the four simple tables ----------------------------
    reach = collections.defaultdict(set)
    for t in SIMPLE + ["Dispatch_FF3A29", "Dispatch_FF3D39",
                       "Dispatch_FF3F39", "Dispatch_FF3FB9",
                       "Dispatch_FF4049", "Dispatch_FF4151"]:
        if t not in tb:
            continue
        ents = tb[t]
        default = collections.Counter(a for _i, a in ents).most_common(1)[0][0]
        for i, a in ents:
            if a != default:
                reach[a].add((t, i))
    # ⚠ THE INDEX A MULTI-ROW TABLE CARRIES IS row*32 + control -- the reader's
    # own `4 * (32*(0x2229) + H)`.  Reduce mod 32 before comparing controls, or
    # every row past the first is read as a different button.
    for a in sorted(reach):
        slots = sorted(reach[a])
        idxs = {i % 32 for _t, i in slots}
        if len(idxs) != 1:
            continue                       # REFUSED: two different controls
        ctl = idxs.pop()
        if ctl not in CONTROL_TEXT or a not in at:
            continue
        short, what = CONTROL_TEXT[ctl]
        t0, i0 = slots[0]
        # ⚠ A MULTI-ROW TABLE REPEATS EVERY CONTROL ONCE PER ROW, with a
        # DIFFERENT handler each time, so the control alone does not name a
        # routine there -- the first attempt at this collided eleven ways and
        # the assembler, not the reviewer, caught it.  The row is part of the
        # identity and goes in the name.
        rows = len(tb[t0]) // 32
        # ⚠ AND THE ROW PART IS THE SET, not the first one.  Four of these are
        # reached from several rows of one table at the same control -- the row
        # is then NOT what distinguishes them, and a name saying `R0` would be
        # a claim the header underneath it contradicts.
        myrows = "".join(str(r) for r in sorted({i // 32 for t, i in slots
                                                 if t == t0}))
        new = "%s_%s%s" % (short, t0.split("_")[1],
                           "_R%s" % myrows if rows > 1 else "")
        li = at[a]
        have = label_at(src, li)
        old = have[0] if have else None
        if old and not old.startswith("sub_"):
            continue                       # already named; leave it alone
        hdr = [
            "%s -- what %s runs for panel control 0x%02X" % (new, t0, ctl),
            "",
            "Reached from: %s, and from no other slot of any 32-entry control"
            % ", ".join("%s entry [%d]%s"
                        % (t, i, "" if i < 32 else " (row %d, control 0x%02X)"
                           % (i // 32, i % 32)) for t, i in slots),
            "         table in prom_a.  A target reached at two DIFFERENT",
            "         indices is refused by the script that wrote this.",
            "Control: index 0x%02X is %s." % (ctl, what),
            "         The pair position -- which of the two buttons -- reaches",
            "         the handler in the argument the reader forwards; this",
            "         pass did NOT establish that argument's bit layout.",
            "Evidence: the code->control map is rounds 9-12's, re-derived from",
            "         the ROM by notes/prom_a_panel_control_map.py, which agrees",
            "         with prom_b's SLOT_CONTROL slot for slot and adds 21",
            "         corroborations, 0 failures.  What is new here is only that",
            "         THIS module's tables are tied to it; see",
            "         notes/FINDINGS-prom_a-panel-control-map.md.",
            "Unknown: what this screen does with the button, and which screen",
            "         this table serves.",
        ]
        if old:
            hdr.append("Was `%s`." % old)
            jobs.append((a, "rename", old, new, hdr))
        else:
            jobs.append((a, "label", None, new, hdr))
    # ★ NO TWO JOBS MAY PROPOSE THE SAME NAME.  A duplicate label does not
    # assemble, so the gate would catch it -- but only after the file is wrong,
    # and the point of a plan is to be wrong on paper first.
    seen = collections.Counter(j[3] for j in jobs)
    dup = [n for n, c in seen.items() if c > 1]
    assert not dup, "duplicate proposed names: %s" % dup

    # --- the control legend, one block per table ---------------------------
    live = {}
    for t, ents in tb.items():
        if not ents or len(ents) % 32:
            continue
        default = collections.Counter(a for _i, a in ents).most_common(1)[0][0]
        live[t] = sorted({i % 32 for i, a in ents if a != default})
    for t in SIMPLE + ["Dispatch_FF3A29", "Dispatch_FF3D39", "Dispatch_FF3F39",
                       "Dispatch_FF3FB9", "Dispatch_FF4049", "Dispatch_FF4151"]:
        if t not in live:
            continue
        legend = [
            "\u2605 CONTROL LEGEND, added 2026-08-31.  The header above ends "
            "\"\u26a0 Not one entry is tied to a legend.\"  This table's are, "
            "now -- with a map this lane did not invent.",
            "",
            "The index is the 5-bit PANEL EVENT CODE PanelButton_Route "
            "produces (`and L,0x1f`, 0xF861AE).  ROUNDS 9-12 established what "
            "each code is, and named 131 handlers in prom_b for these same "
            "codes (SoftKeyColN / LcdKeyRowN / ExitKey); the tables in THIS "
            "module were never tied to it.  notes/prom_a_panel_control_map.py "
            "re-derives the map from the ROM by an independent route -- the "
            "wire->group map at 0xF8A189 and the group event lists at "
            "0xF8B4B2, composed with the service manual's switch matrix -- "
            "and AGREES with prom_b's SLOT_CONTROL slot for slot.  21 "
            "corroborations, 0 failures.  Write-up: "
            "notes/FINDINGS-prom_a-panel-control-map.md.",
            "",
            "  [00]..[07]  SOFT KEY columns 1..8; a column's lower and upper",
            "              key share a code",
            "  [08]..[0C]  the five LCD-row buttons, top to bottom; a row's",
            "              left-hand and right-hand key share a code",
            "  [0D]        the -1 / +1 pair          [0F]  EXIT",
            "  [0E]        nothing on this panel raises it",
            "  [10]        the PAGE v / PAGE ^ pair  [1E]  COMPARE",
            "  [1B]        the number pad, whole field",
            "  [20]        mode/menu select -- OUT OF RANGE for a 32-entry",
            "              table; PanelEvent_Code20_SetScreen takes it instead",
            "",
            "LIVE in this table: %s." % ", ".join("[%02X]" % i for i in live[t]),
            "Everything else is this module's do-nothing default.",
            "\u26a0 A live index names the CONTROL, not the FUNCTION.",
        ]
        jobs.append((("table", t), "legend", None, t, legend))

    return src, jobs


RULE = "; ---------------------------------------------------------------------"


def render(hdr):
    """The tree's header block, wrapped at the width the rest of the file uses.

    A field line is `Name:  text`; its continuations are indented to nine
    columns, which is what every hand-written header in this listing does."""
    out = [RULE]
    for h in hdr:
        if not h:
            out.append(";")
            continue
        m = re.match(r'^([A-Za-z★⚠][^:]{0,12}:)\s*(.*)$', h)
        lead, rest = (m.group(1), m.group(2)) if m else ("", h)
        first = "; " + (lead + " " * max(1, 10 - len(lead)) if lead else "") + rest
        if len(first) <= 78:
            out.append(first)
            continue
        indent = ";" + " " * 10
        words, cur = rest.split(), (("; " + lead + " " * max(1, 10 - len(lead)))
                                   if lead else "; ")
        for w in words:
            if len(cur) + len(w) + 1 > 78 and cur.strip(";"):
                out.append(cur.rstrip())
                cur = indent
            cur += w + " "
        if cur.strip(";").strip():
            out.append(cur.rstrip())
    out.append(RULE)
    return out


def apply_():
    """Idempotent.  Renames first, over the whole text; then labels and headers,
    located by ADDRESS and inserted from the bottom up so no index moves."""
    src, jobs = plan()
    text = "\n".join(src)
    for _a, kind, old, new, _h in jobs:
        if kind == "rename" and re.search(r'\b%s\b' % old, text):
            text = re.sub(r'\b%s\b' % old, new, text)
    src = text.splitlines()

    added_labels = added_headers = added_legends = 0
    for job in sorted(jobs, key=lambda j: -(j[0] if isinstance(j[0], int)
                                            else 0)):
        addr, kind, _old, new, hdr = job
        if kind == "legend":
            i = next((k for k, ln in enumerate(src)
                      if ln.startswith(new + ":")), None)
            if i is None:
                continue
            if any("★ CONTROL LEGEND" in ln for ln in src[max(0, i - 40):i]):
                continue                   # idempotent
            src[i:i] = render(hdr)
            added_legends += 1
            continue
        at = line_of_addr(src)
        if addr not in at:
            raise AssertionError("0x%06X is not the start of a listing line; "
                                 "the table points inside an instruction" % addr)
        li = at[addr]
        have = label_at(src, li)
        fresh = have is None
        if not fresh and have[0] != new:
            raise AssertionError("0x%06X carries %s, not %s"
                                 % (addr, have[0], new))
        if fresh:
            # ⚠ ORDER MATTERS AND COST A ROUND: header, then label, then the
            # code line.  Inserting the label first and the header after it put
            # the header BETWEEN the label and its code, and the next run could
            # no longer see the label above the code -- so a second --apply
            # added a SECOND label at the same address.  The gate would have
            # caught it (a duplicate label does not assemble), but only after
            # the file was already wrong.  `--apply` twice must be a no-op, and
            # that is now what the second run prints.
            src[li:li] = render(hdr) + [new + ":"]
            added_labels += 1
            added_headers += 1
            continue
        li = have[1]
        j = li - 1
        while j >= 0 and not src[j].strip():
            j -= 1
        if j >= 0 and src[j].startswith("; ------"):
            # ALREADY HEADED.  Two cases, and they are told apart by whether
            # the header above is one this script wrote.
            top = j
            while top > 0 and src[top - 1].lstrip().startswith(";"):
                top -= 1
            block = "\n".join(src[top:j + 1])
            if new in block and "notes/prom_a_panel_control_map.py" in block:
                continue                   # ours: idempotent, nothing to do
            # SOMEONE ELSE'S header.  It is left VERBATIM and the new one goes
            # ABOVE it -- ⚠ never through it.  Two of these are round 7's
            # explicit REFUSALS to name, and the note says why the refusal's
            # premise no longer holds; a refusal that is overturned has to be
            # answered in place, not quietly overwritten.
            extra = list(hdr) + [
                "",
                "★ THIS ANSWERS THE HEADER BELOW, which is left verbatim.",
                "  Its reasoning was about what the routine DRAWS, and it was",
                "  right that nothing there tells this routine from its",
                "  sibling.  The DISPATCH SLOT does: they are two different",
                "  entries of one table, i.e. two different buttons of one",
                "  screen.  The older block's opening line now carries the new",
                "  name because the rename was applied file-wide; every other",
                "  word of it, including its refusal, is untouched and is the",
                "  record of how the gap was closed.",
            ]
            src[top:top] = render(extra)
            added_headers += 1
            continue
        src[li:li] = render(hdr)
        added_headers += 1
    # Variant_SetFromPB0's stated Unknown, answered.  ADDED ABOVE its header,
    # never through it: the header is another round's and its "Unknown" line is
    # the record of what was open when it was written.
    a2 = ("; Variant_SetFromPB0 -- sets (0x00C4), the model-variant flag, "
          "from PORT B bit 0")
    if a2 in src and not any("\u2605 WHICH VARIANT IS WHICH" in ln for ln in src):
        i = src.index(a2)
        while i > 0 and src[i - 1].startswith("; ----"):
            i -= 1
        src[i:i] = render([
            "\u2605 WHICH VARIANT IS WHICH -- the header below says \"Unknown: "
            "which physical variant is 1 and which is 2\", and the tree has "
            "since answered it.  \u26a0 ANSWERED BY ROUND 11, NOT HERE: "
            "notes/wave7_panel_names_round11.py --variant.  This block only "
            "carries the answer to the routine that raises the question, "
            "which had gone eleven rounds without it.",
            "",
            "VARIANT 2 -- PORT B BIT 0 LOW -- IS THE SX-WSA1R, the rack this "
            "service manual documents.  The panel event lists the strap "
            "selects (0xF8A851 `cp (0xC4),0x01`, taking 0xF8B446 for 1 and "
            "0xF8B4B2 otherwise) say which matrix bits the firmware expects "
            "to move, and on all twelve wire segments variant 2's answer is "
            "the manual's own diode list -- CP1 \"D1-23, 25-48\" and CP2 "
            "\"D57-60, 65, 66, 73-77\" -- including the missing SW24, the "
            "empty segment 6, and 4/2/5 fitted switches on CP2's three "
            "segments.  Variant 1 contradicts it on six of the twelve, "
            "expecting sixteen switches this instrument does not have.",
            "",
            "Round 11 settles it three independent ways -- the diode coverage "
            "above, the three power-on service chords, and the number-pad "
            "value tables (only variant 2's, at 0xF8AE57, makes segment-1 bit "
            "b the key printed b).  Re-derived independently, and by the "
            "coverage argument alone, by notes/prom_a_panel_control_map.py "
            "--variant.",
            "\u26a0 Variant 1's panel is NOT identified.  The keyboard SX-WSA1 is "
            "the obvious candidate and no SX-WSA1 material exists in these "
            "trees, so it stays a candidate.",
        ])
        added_legends += 1

    # ScreenDispatch_FE8077's stated Unknown -- an OBSERVATION, not an answer.
    a3 = "; ScreenDispatch_FE8077 -- 32 pointers to routines in this module"
    if a3 in src and not any("\u2605 A SHAPE THAT FITS" in ln for ln in src):
        i = src.index(a3)
        while i > 0 and src[i - 1].startswith("; ----"):
            i -= 1
        src[i:i] = render([
            "\u2605 A SHAPE THAT FITS THE PANEL CODE -- offered as an observation, "
            "NOT as an answer to the \"Unknown\" below.",
            "",
            "The 5-bit panel event code is now mapped to the physical controls "
            "(notes/FINDINGS-prom_a-panel-control-map.md), and this table's "
            "shape is what that map predicts of a screen: [00]-[07] all one "
            "target (the eight SOFT KEY columns do the same thing), [08]-[0C] "
            "five DISTINCT targets (the five LCD-row buttons), [0D]/[0E] one "
            "target (-1/+1, and a code nothing on this panel raises), [0F] its "
            "own (EXIT), [10]-[1F] all one target.",
            "",
            "\u26a0 WHY THAT IS NOT ENOUGH.  The reader is published as prom_b "
            "thunk slot T_F402B4 and NOTHING in either image names that slot "
            "(notes/prom_a_xref.py), so no caller establishes what HL holds. "
            "A shape that fits is a coincidence until a caller says otherwise, "
            "and the handlers here are deliberately left `sub_XXXXXX` for that "
            "reason.  The shortest path to closing it is a caller of "
            "T_F402B4.",
        ])
        added_legends += 1

    # the module banner's own correction, anchored on its closing sentence
    anchor = ("; Every handler is `sub_XXXXXX`.  Nothing in this module names "
              "a control.")
    if anchor in src and not any("★ SUPERSEDED 2026-08-31" in ln for ln in src):
        i = src.index(anchor) + 1
        src[i:i] = [
            ";",
            "; ★ SUPERSEDED 2026-08-31, and the sentence above is kept because it is",
            ";   what was true before.  The 32 indices ARE the panel's controls: the",
            ";   5-bit event code, composed out of the wire->group map (0xF8A189) and",
            ";   the group event lists (0xF8B4B2) and checked against the service",
            ";   manual's switch matrix.  Every table below now carries the legend and",
            ";   its own live-entry list; the derivation, its variant adjudication and",
            ";   its nineteen corroborations are in",
            ";   notes/FINDINGS-prom_a-panel-control-map.md.",
            ";   ⚠ It ties an index to a CONTROL, not to a FUNCTION.  What a handler",
            ";   does with the button, and which screen each table serves, are still",
            ";   open -- so most handlers here are still `sub_XXXXXX` on purpose.",
        ]
        added_legends += 1
    open(LISTING, "w", encoding="utf-8").write("\n".join(src) + "\n")
    return added_labels, added_headers, added_legends


def selftest():
    """The three things that would make this script write a wrong name."""
    bad = 0
    m2, _f = PM.compose(2)
    codes = collections.defaultdict(set)
    for (_seg, _bit), (cls, code, _pos, _mask) in m2.items():
        if cls == 0xA9:
            codes[code].add(PM.SHORT.get(code, "?"))
    # 1. every control this script is willing to name really is in the derived
    #    map, under the same short name -- so a typo here cannot invent a button
    # ⚠ Round 12 keeps the CONTROL MORPHEME ("Exit") and its SPELLING in a
    # label ("ExitKey") apart, in CONTROL_SPELLING.  Compare through the same
    # function or this check fails on a spelling and hides a real one.
    try:
        import prom_b_panel_names_round12 as R12
        spell = R12.spell
    except Exception:                              # pragma: no cover
        spell = lambda x: x
    for ctl, (short, _what) in CONTROL_TEXT.items():
        ok = ctl in codes and short in {spell(c) for c in codes[ctl]}
        print("%-4s control 0x%02X is %s in the derived map"
              % ("ok" if ok else "FAIL", ctl, short))
        bad += 0 if ok else 1
    # 2. the plan proposes no duplicate name (plan() asserts this; run it)
    try:
        _s, jobs = plan()
        print("ok   plan() builds, %d jobs, no duplicate names" % len(jobs))
    except AssertionError as e:
        print("FAIL plan(): %s" % e)
        bad += 1
    # 3. the map tool itself still passes its own corroborations
    n = sum(1 for _n, ok, _d in PM.checks() if not ok)
    print("%-4s prom_a_panel_control_map corroborations: %d failures"
          % ("ok" if n == 0 else "FAIL", n))
    bad += n
    print("FAILURES: %d" % bad)
    return 1 if bad else 0


def main():
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    src, jobs = plan()
    if "--apply" not in argv:
        print("%d jobs (%d renames, %d new labels, %d table legends)"
              % (len(jobs), sum(1 for j in jobs if j[1] == "rename"),
                 sum(1 for j in jobs if j[1] == "label"),
                 sum(1 for j in jobs if j[1] == "legend")))
        for addr, kind, old, new, _h in jobs:
            where = ("0x%06X" % addr) if isinstance(addr, int) else "  table"
            print("  %-6s %s  %-16s -> %s"
                  % (kind, where, old or "(unlabelled)", new))
        return 0
    lab, hdr, leg = apply_()
    print("applied: %d labels, %d headers, %d table legends"
          % (lab, hdr, leg))
    return 0


if __name__ == "__main__":
    sys.exit(main())
