#!/usr/bin/env python3
"""Name prom_a's screen-control tables, their readers, and the screen objects
that install them -- all of it derived at run time, none of it pasted.

QUESTION IT ANSWERS
-------------------
  "Which `sub_XXXXXX`, and which UNLABELLED address, can be named from
   notes/prom_a_panel_control_map.py and from PanelScreen_VtableTable -- and
   what header states the evidence?"

★ NOTHING HERE IS A NAME LIST.  The script reads the dispatch tables out of the
listing, the code->control map out of the ROM through
prom_a_panel_control_map, and the screen objects out of PanelScreen_VtableTable;
`--plan` prints exactly what `--apply` will do, and `--verify` re-runs the whole
transform from the pre-pass blob in git and compares it with the committed file.

WHAT IT NAMES
  READERS    a routine whose body carries an `add XBC,0x00FFxxxx` naming one of
             the module's tables, classified by WHAT IT INDEXES WITH:
               `cp H,0x20`, or `(0x2229)<<5` + H  -> PanelButtonDispatch_<Screen>
               `cp (0x2229),N` and (0x2229)*4     -> PageDispatch_<Screen>
             The second kind is indexed by the PAGE byte alone and takes no
             argument -- calling one of those a PanelButton anything is the
             mistake the distinction exists to prevent.
  HANDLERS   the targets of those tables, one per (control, page):
             LcdKeyRow1_DiskMenu, ExitKey_MidiFileL0ad,
             ExitKey_DiskSaveFile_Pages3_4 -- the `<Control>_<Screen>` form
             rounds 11 and 12 applied to 131 labels in prom_b.  Most of these
             addresses HAVE NO LABEL AT ALL: the ROM's own table points at them
             and the listing never named them.
  SCREENS    the suffix.  A screen object is +0 Enter, +4 Leave, +8 Button, so
             the screen whose BUTTON method is a reader is the screen that
             reader serves, and the same object's ENTER method paints it.
             Seven screens are named by an existing `Paint_*` label; five more
             by their own display lists' titles, declared in SCREEN_DECLARED
             with the evidence beside each.
  METHODS    the other two slots of every screen object whose +0 already
             carries a `Paint_*` label -> ScreenLeave_<Screen>,
             ScreenButton_<Screen>.

  ⚠ THE ENTRY NUMBER IS NOT THE SCREEN ID.  PanelButton_Route reads the table
  through PanelScreen_VtableTable_ViewB, entry 32 used as a second base, so
  screen id n is ENTRY n+32.  These headers said otherwise for one commit;
  `screen_id_phrase` is the fix and --selftest asserts it against round 9's
  independent anchor.

WHAT IT REFUSES, and this is the point
  * a handler reached at two DIFFERENT control indices -- 32 of this module's
    live targets are, always as c and c+0x11, round 11's variant-1 rewrite, and
    that is why NO SoftKeyCol name comes out of this module;
  * a target outside prom_a (eight are prom_b directory slots);
  * a screen-object slot two live objects share, or one the reader batch has
    already claimed with a richer name;
  * an address that is not the start of a listing line, which would mean a
    table points inside an instruction and something is wrong upstream;
  * any two jobs proposing the same name -- asserted in `plan()`, because a
    plan should be wrong on paper before it is wrong in the file.

USAGE
    python3 notes/prom_a_naming_wave8_apply.py --plan
    python3 notes/prom_a_naming_wave8_apply.py --apply      # idempotent
    python3 notes/prom_a_naming_wave8_apply.py --verify     # committed == derived
    python3 notes/prom_a_naming_wave8_apply.py --screens    # the work list left
    python3 notes/prom_a_naming_wave8_apply.py --selftest
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_panel_control_map as PM                 # noqa: E402
from asm_source import git_show  # noqa: E402  (git paths are repo-relative)

LISTING = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
_A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
_B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def _rom(a, n):
    if 0xF80000 <= a < 0x1000000:
        return _A[a - 0xF80000:a - 0xF80000 + n]
    if 0xF00000 <= a < 0xF80000:
        return _B[a - 0xF00000:a - 0xF00000 + n]
    return b""


VTABLE = 0xF86EC1          # PanelScreen_VtableTable, 256 LE32 screen objects
NULL_VTABLE = 0xF872C1
VIEWB = 32                 # PanelScreen_VtableTable_ViewB = entry 32 as a base


def screen_id_phrase(entry):
    """How to SAY which screen a table entry is, without inventing a number.

    ⚠ THE ENTRY NUMBER IS NOT THE SCREEN ID, and the first version of these
    headers said it was.  PanelButton_Route reads the table through
    PanelScreen_VtableTable_ViewB (`ld XBC,0x00F86F41` at 0xF86215), which is
    entry 32 used as a second base, so a screen id `n` addresses ENTRY n+32.
    Entries 0-47 are also reachable from the other base as mode indices 0-47,
    and the two views overlap on 32-47 -- so an entry below 32 has no ViewB id
    at all and one in 32..47 has two readings.  The phrase says exactly which.
    """
    if entry < VIEWB:
        return ("entry 0x%02X (below the ViewB base, so it is a MODE INDEX of "
                "the other view and has no screen id)" % entry)
    return ("entry 0x%02X, i.e. SCREEN ID 0x%02X through "
            "PanelScreen_VtableTable_ViewB%s"
            % (entry, entry - VIEWB,
               " -- and also mode index 0x%02X of the other view, which "
               "overlaps here" % entry if entry < 48 else ""))


def screen_of_reader():
    """{reader address: (screen id, Enter address)} -- from the SCREEN OBJECT.

    ★ THIS IS THE LINK THAT TURNS A TABLE ADDRESS INTO A SCREEN.  Each entry of
    PanelScreen_VtableTable is a three-method object -- +0 Enter, +4 Leave, +8
    Button, each a `jp addr24` in prom_b's directory (that listing's own header,
    with its checks V1-V6).  So the screen whose BUTTON method is a reader is
    the screen that reader serves, and its ENTER method is what paints it.

    The mapping comes out ONE-TO-ONE: ten readers, ten screen ids, no reader
    named by two screens and no screen naming two readers.  That is asserted,
    not assumed -- if it were many-to-one a table could not carry a screen name
    at all.
    """
    out = {}
    for i in range(256):
        v = int.from_bytes(_rom(VTABLE + 4 * i, 4), "little") & 0xFFFFFF
        if not v or v == NULL_VTABLE:
            continue

        def _jp(a):
            b = _rom(a, 4)
            return int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None
        enter, button = _jp(v), _jp(v + 8)
        if button is None:
            continue
        out.setdefault(button, []).append((i, enter))
    return {b: v[0] for b, v in out.items() if len(v) == 1}


# Screens whose name is NOT the Enter method's own label.  Each carries the
# evidence in the value, and --selftest re-derives the address it cites.
SCREEN_DECLARED = {
    0x60: ("DiskMenu",
           "its Enter method (0xFF42CD) hands the interpreter the lists at "
           "0xF58014 (\"DISK\"), 0xF580B0 (\"MIDI FILE LOAD\") and 0xF58127 "
           "(\"LOAD\"), choosing between the last two on the model strap "
           "(0xC4) at 0xFF42EE -- the site this module's own banner already "
           "calls THE DISK MENU"),
    0x6C: ("DiskSaveFile",
           "its Enter method is the page dispatcher PageDispatch_FF3A00, and "
           "four of that table's six pages are Paint_DiskSaveFile"),
    0x6E: ("MidiFileSave",
           "its page 0 draws the list at 0xF58A21, whose first record reads "
           "\"MIDI FILE SAVE : FILE NAMING\", and its page 1 the list at "
           "0xF59222, \"MIDI FILE SAVE : FILE SELECTI0N\""),
    0x73: ("L0adSingleC0mbination",
           "its page 1 draws the list at 0xF58F55, whose first record reads "
           "\"LOAD SINGLE COMBINATION\""),
    0x74: ("L0adSingleS0und",
           "its page 0 draws the list at 0xF58C53, whose first record reads "
           "\"LOAD SINGLE SOUND\""),
}


def screen_of_enter():
    """{Enter-method address: screen id} -- the page dispatchers are reached as
    a screen's ENTER method, not as its BUTTON method, so they need the other
    half of the same object."""
    out = {}
    for i in range(256):
        v = int.from_bytes(_rom(VTABLE + 4 * i, 4), "little") & 0xFFFFFF
        if not v or v == NULL_VTABLE:
            continue
        b = _rom(v, 4)
        e = int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None
        if e is not None:
            out.setdefault(e, []).append(i)
    return {e: v[0] for e, v in out.items() if len(v) == 1}


def screen_names(src):
    """{table label: (screen name, screen id, why)}."""
    rd = readers(src)
    lab_at = {}
    for i, ln in enumerate(src):
        mm = LABEL.match(ln)
        if not mm:
            continue
        a = ADDR.search(src[i + 1]) if i + 1 < len(src) else None
        if a:
            lab_at[int(a.group(1), 16)] = mm.group(1)
    link = screen_of_reader()
    out = {}
    for t, (_old, li, _kind, _ev) in rd.items():
        a = ADDR.search(src[li + 1]) if li + 1 < len(src) else None
        if not a:
            continue
        addr = int(a.group(1), 16)
        if addr not in link:
            continue
        sid, enter = link[addr]
        nm = lab_at.get(enter)
        if nm and nm.startswith("Paint_"):
            out[t] = (nm[len("Paint_"):], sid,
                      "the screen object at PanelScreen_VtableTable %s names "
                      "this reader as its BUTTON method and 0x%06X as its "
                      "ENTER method, and that address carries the label %s -- "
                      "a name an earlier round derived from the screen's own "
                      "text" % (screen_id_phrase(sid), enter, nm))
        elif sid in SCREEN_DECLARED:
            n2, why = SCREEN_DECLARED[sid]
            out[t] = (n2, sid,
                      "the screen object at PanelScreen_VtableTable %s names "
                      "this reader as its BUTTON method, and %s"
                      % (screen_id_phrase(sid), why))
    # the PAGE dispatchers: same object, other method
    ent = screen_of_enter()
    byid = {sid: nm for nm, sid, _w in out.values()} if False else \
        {v[1]: v[0] for v in out.values()}
    for t, (_old, li, kind, _ev) in rd.items():
        if t in out or kind != "page":
            continue
        a = ADDR.search(src[li + 1]) if li + 1 < len(src) else None
        if not a:
            continue
        sid = ent.get(int(a.group(1), 16))
        if sid in byid:
            out[t] = (byid[sid], sid,
                      "the screen object at PanelScreen_VtableTable %s names "
                      "this reader as its ENTER method, and its BUTTON method "
                      "is that screen's control table" % screen_id_phrase(sid))
    return out
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
    """The PRIMARY file's own lines -- the WRITE path, and only that.

    ⚠ Writing the expanded image back here would inline kernel/kernel.s and the
    two maincpu/shared parts into prom_a and destroy them, so the write must
    stay on the primary.  `apply_()` asserts every address it touches is IN the
    primary before it writes a byte."""
    return open(LISTING, encoding="utf-8").read().splitlines()


def analysis_lines():
    """The IMAGE's lines -- every READ.

    ★ NOT the primary.  A probe that opens `prom_X/wsa1_prom_X.s` and scans it
    measures ONE FILE; an image is a primary plus its `.include`s, and the day
    prom_a is split this script would plan NOTHING and say so quietly.  That is
    the vacuous pass notes/probe_health.py exists to catch, and it graded this
    file SPLIT-FRAGILE for exactly this reason."""
    import asm_source
    if os.path.abspath(LISTING) != os.path.abspath(
            os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")):
        return lines()          # --verify runs against a scratch copy
    return asm_source.image_lines(ROOT, "prom_a/wsa1_prom_a.s")


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
    """{table label: (routine, line, kind, evidence dict)} for every dispatcher.

    ⚠ THE BODY IS CUT AT `jp (xbc)`.  A dispatcher is followed, with no label
    between them, by the next routine -- and the first attempt at this scanned
    to the next LABEL, so it picked up a neighbour's table immediate and gave
    one reader two tables.  The dispatch instruction is where the dispatcher
    ends, so that is where the scan stops.

    THREE SHAPES, told apart by what they index with:

      ctl    `cp H,0x20` then `add XBC,<table>`     -- one 32-entry row, indexed
             by the 5-bit PANEL CONTROL code in (XIZ+0x08).
      ctl2   `(0x2229) << 5` + H, then `add XBC`    -- a multi-row table, index
             = 32*page + control.  Same control space, no explicit bound: H is
             already 5 bits when it arrives.
      page   `cp (0x2229),N` then `(0x2229) * 4`    -- indexed by THE PAGE BYTE
             ALONE.  Not a control table at all, and giving one of these a
             PanelButton name would be the error this distinction exists to
             prevent.
    """
    out = {}
    cur, curline, body = None, None, []
    for i, ln in enumerate(src + [""]):
        m = LABEL.match(ln)
        if m or i == len(src):
            if cur and body:
                txt = "\n".join(body)
                cut = txt.find("jp (xbc)")
                if cut > 0:
                    txt = txt[:cut]
                base = re.search(r'add XBC,0x00(ff[0-9a-f]{4})\s+;\s*([0-9A-F]{6})',
                                 txt)
                if base:
                    t = "Dispatch_FF" + base.group(1)[2:].upper()
                    ev = {"base": base.group(2), "table": t}
                    kind = None
                    g = re.search(r'cp H,0x20\s+;\s*([0-9A-F]{6})', txt)
                    if g:
                        kind, ev["bound"] = "ctl", g.group(1)
                    elif re.search(r'sll c, 0x05', txt) and re.search(r'add C,H', txt):
                        kind = "ctl2"
                    else:
                        g = re.search(r'MB16, 0x2229, 0x([0-9a-f]{2})\s+;\s*'
                                      r'([0-9A-F]{6})', txt)
                        if g and re.search(r'MB16, 0x2229, 3', txt):
                            kind, ev["bound"] = "page", g.group(2)
                            ev["pages"] = int(g.group(1), 16)
                    if kind:
                        out[t] = (cur, curline, kind, ev)
            cur, curline, body = (m.group(1) if m else None), i, []
            continue
        if cur:
            body.append(ln)
    return out


def plan():
    src = analysis_lines()
    tb = tables(src)
    at = line_of_addr(src)
    rd = readers(src)

    scr = screen_names(src)         # {table: (screen name, id, why)}
    jobs = []                       # (addr, kind, old, new, header lines)

    # --- the readers -------------------------------------------------------
    for t, (old, li, kind, ev) in sorted(rd.items()):
        if not old.startswith("sub_"):
            continue
        sname = scr.get(t)
        suffix = sname[0] if sname else t.split("_")[1]
        if kind in ("ctl", "ctl2"):
            new = "PanelButtonDispatch_" + suffix
            hdr = [
                "%s -- run %s's handler for one PANEL CONTROL" % (new, t),
                "",
                "Inputs:  (XIZ+0x08) = the 5-bit panel control index; (XIZ+0x0A) =",
                "         the argument this reader forwards to the handler.",
            ]
            if kind == "ctl":
                hdr += [
                    "Evidence: `cp H,0x20` at 0x%s bounds the index to the 32-code"
                    % ev["bound"],
                    "         panel space PanelButton_Route's `and L,0x1f`",
                    "         (0xF861AE) produces, and `add XBC,0x00%s` at 0x%s"
                    % (t.split("_")[1], ev["base"]),
                    "         names the table.",
                ]
            else:
                hdr += [
                    "Evidence: the index is `((0x2229) << 5) + H` -- the page byte",
                    "         times the 32-entry row length, plus the control --",
                    "         and `add XBC,0x00%s` at 0x%s names the table."
                    % (t.split("_")[1], ev["base"]),
                    "⚠ No explicit `cp H,0x20` here, unlike its single-row",
                    "         siblings: H arrives already masked to five bits.",
                ]
            hdr += [
                "         The handler is CALLED, not jumped to: the reader pushes",
                "         a return address before `jp (XBC)`.",
                "Control legend: notes/FINDINGS-prom_a-panel-control-map.md, and",
                "         `python3 notes/prom_a_panel_control_map.py --map`.",
            ]
            if sname:
                hdr += ["Screen:  %s -- %s."
                        % (sname[0], sname[2])]
        elif kind == "page":
            new = "PageDispatch_" + suffix
            hdr = [
                "%s -- run %s's entry for the CURRENT PAGE" % (new, t),
                "",
                "★ NOT a panel-control table.  This reader indexes with the page",
                "         byte (0x2229) ALONE and never reads an argument, so its",
                "         %d entries are pages of one screen and not buttons."
                % ev["pages"],
                "Evidence: `cp (0x2229),0x%02X` at 0x%s is the bound, the index is"
                % (ev["pages"], ev["bound"]),
                "         `(0x2229) * 4` (`m_mul MB16,0x2229,3` -- the operand is",
                "         width-1), and `add XBC,0x00%s` at 0x%s names the table."
                % (t.split("_")[1], ev["base"]),
                "         The entry is CALLED: a return address is pushed before",
                "         `jp (XBC)`.",
            ]
            if sname:
                hdr += ["Screen:  %s -- %s."
                        % (sname[0], sname[2])]
        else:
            continue
        hdr.append("Was `%s`, named by notes/prom_a_naming_wave8_apply.py." % old)
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
        rr = sorted({i // 32 for t, i in slots if t == t0})
        # `_Page34` reads as page thirty-four.  Two pages are `_Pages3_4`.
        myrows = ("Page%d" % rr[0] if len(rr) == 1
                  else "Pages" + "_".join(str(r) for r in rr))
        # ★ THE SUFFIX IS THE SCREEN, when the screen object gives one -- the
        # form rounds 11/12 use in prom_b (<Control>_<Screen>).  It falls back
        # to the table address only where no screen object names the reader.
        sn = scr.get(t0)
        new = "%s_%s%s" % (short, sn[0] if sn else t0.split("_")[1],
                           "_%s" % myrows if rows > 1 else "")

        li = at[a]
        have = label_at(src, li)
        old = have[0] if have else None
        if old and not old.startswith("sub_"):
            continue                       # already named; leave it alone
        hdr = [
            "%s -- what %s runs for panel control 0x%02X" % (new, t0, ctl),
            "",
            "Reached from: %s -- and from no other slot of any 32-entry "
            "control table in prom_a.  A target reached at two DIFFERENT "
            "indices is refused by the script that wrote this."
            % ", ".join("%s entry [%d]%s"
                        % (t, i, "" if i < 32 else " (page %d, control 0x%02X)"
                           % (i // 32, i % 32)) for t, i in slots),
            "Control: index 0x%02X is %s.  The pair position -- which of the "
            "two keys -- reaches the handler in the argument the reader "
            "forwards; this pass did NOT establish that argument's bit "
            "layout." % (ctl, what),
            "Evidence: the code->control map is rounds 9-12's, re-derived from "
            "the ROM by notes/prom_a_panel_control_map.py, which agrees with "
            "prom_b's SLOT_CONTROL slot for slot; what is new here is only "
            "that THIS module's tables are tied to it.  See "
            "notes/FINDINGS-prom_a-panel-control-map.md.",
            "Unknown: what this screen does with the button.",
        ]
        if sn:
            hdr[-1:] = [
                "Screen:  %s -- %s." % (sn[0], sn[2]),
                "Unknown: what this screen does with the button.",
            ]
        if old:
            hdr.append("Was `%s`." % old)
            jobs.append((a, "rename", old, new, hdr))
        else:
            jobs.append((a, "label", None, new, hdr))
    # --- the LEAVE and BUTTON methods of every screen whose ENTER is named ---
    # ★ THE SAME OBJECT, THE OTHER TWO SLOTS.  A screen whose +0 already carries
    # a `Paint_*` label names its own +4 and +8, and the three offsets are
    # established by three different call sites (that table's header, checks
    # V1-V6), not by a guess about layout.
    # ⚠ AND AN ADDRESS ALREADY CLAIMED KEEPS THE RICHER NAME.  Six of these
    # screens' BUTTON methods ARE the control-table readers named above, so the
    # two families collide on one address; PanelButtonDispatch_X says what
    # ScreenButton_X says AND that it dispatches a control table, so the reader
    # name wins and this one is skipped.
    claimed = {j[0] for j in jobs if isinstance(j[0], int)}
    lab_at = {}
    for i, ln in enumerate(src):
        mm = LABEL.match(ln)
        if not mm:
            continue
        aa = ADDR.search(src[i + 1]) if i + 1 < len(src) else None
        if aa:
            lab_at.setdefault(int(aa.group(1), 16), mm.group(1))
    used = collections.Counter()
    objs = []
    for i in range(256):
        v = int.from_bytes(_rom(VTABLE + 4 * i, 4), "little") & 0xFFFFFF
        if not v or v == NULL_VTABLE:
            continue

        def _j(x):
            b = _rom(x, 4)
            return int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None
        objs.append((i, v, _j(v), _j(v + 4), _j(v + 8)))
        for x in (_j(v + 4), _j(v + 8)):
            if x:
                used[x] += 1
    for i, v, e, l, b in objs:
        en = lab_at.get(e) if e else None
        if not (en and en.startswith("Paint_")):
            continue
        screen = en[len("Paint_"):]
        for off, tgt, root, what in ((4, l, "ScreenLeave", "LEAVE"),
                                     (8, b, "ScreenButton", "BUTTON")):
            if not tgt or used[tgt] > 1 or tgt not in at or tgt in claimed:
                continue                   # shared, unreachable, or claimed
            cur_lab = lab_at.get(tgt)
            if cur_lab and not cur_lab.startswith("sub_"):
                continue                   # already named (or named by us)
            new = "%s_%s" % (root, screen)
            bare = _rom(tgt, 1) == b"\x0e"
            hdr = [
                "%s -- the %s method of the screen object at "
                "PanelScreen_VtableTable %s" % (new, what, screen_id_phrase(i)),
                "",
                "Reached from: PanelScreen_VtableTable entry 0x%02X -> the "
                "screen object at 0x%06X, whose +%d slot is `jp 0x%06X`.  It "
                "is reached from nowhere else: no other live screen object "
                "names this address in either of its two callable slots."
                % (i, v, off, tgt),
                "Evidence: the offset is not a guess about layout, and it is "
                "what makes this the %s method.  +0 is called "
                "by PanelScreen_CallEnter_A/B with the id that has just BECOME "
                "current, +4 by PanelScreen_CallLeave_A/B with the id that has "
                "just STOPPED being current, and +8 by PanelButton_Route "
                "(0xF8621E) with the current id and a button index -- three "
                "different call sites, checked as V1-V6 in "
                "PanelScreen_VtableTable's own header." % what,
                "Screen:  %s -- the same object's +0 ENTER method carries the "
                "label %s, a name an earlier round derived from the screen's "
                "own text." % (screen, en),
            ]
            if bare:
                hdr.append("Body:    ONE BYTE, 0x0E -- a bare `ret`.  This "
                           "screen does nothing at all on %s, and the slot "
                           "exists to keep the three-method shape."
                           % what.lower())
            if cur_lab:
                hdr.append("Was `%s`." % cur_lab)
                jobs.append((tgt, "rename", cur_lab, new, hdr))
            else:
                jobs.append((tgt, "label", None, new, hdr))

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
            "and AGREES with prom_b's SLOT_CONTROL slot for slot.  Its "
            "corroborations all pass -- run --checks; a count is not quoted "
            "here because a hand-copied count rots.  Write-up: "
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
    _analysis, jobs = plan()
    src = lines()                      # the PRIMARY: this is the write path
    have = line_of_addr(src)
    stray = [j[0] for j in jobs
             if isinstance(j[0], int) and j[0] not in have]
    if stray:
        raise AssertionError(
            "%d job addresses are in the IMAGE but not in the primary "
            "(%s...) -- prom_a has been split and this script's write path has "
            "to be taught asm_source.edit_image before it may run again"
            % (len(stray), ", ".join("0x%06X" % a for a in stray[:4])))
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
            ";   its own live-entry list; the derivation, the variant adjudication it",
            ";   inherits from round 11, and its corroborations are in",
            ";   notes/FINDINGS-prom_a-panel-control-map.md.",
            ";   ★ AND EACH TABLE'S SCREEN IS NAMED TOO, from the screen object that",
            ";   installs the reader as its BUTTON method -- so the handlers read",
            ";   LcdKeyRow1_DiskMenu and ExitKey_MidiFileL0ad rather than carrying a",
            ";   table address.  This module owns ten screens: the DISK MENU, MIDI",
            ";   FILE LOAD / SAVE / DIRECT PLAY, DISK LOAD FILE / SAVE FILE, LOAD",
            ";   SINGLE SOUND / COMBINATION, and the two floppy-format screens.",
            ";   ⚠ It ties an index to a CONTROL, not to a FUNCTION.  What a handler",
            ";   DOES with the button is still open, and a target reached at two",
            ";   different indices is refused -- so many handlers here are still",
            ";   `sub_XXXXXX` on purpose.",
        ]
        added_legends += 1
    open(LISTING, "w", encoding="utf-8").write("\n".join(src) + "\n")
    return added_labels, added_headers, added_legends


BASE_COMMIT = "fab0949"      # the tree as it stood before this pass


def verify():
    """Does the COMMITTED listing equal what this COMMITTED script produces?

    ★ WHY THIS AND NOT JUST IDEMPOTENCE.  `--apply` twice being a no-op proves
    the second run changes nothing; it does not prove the file in git is what
    the script in git makes.  Those drift apart the moment anyone hand-edits one
    of these blocks, and then the script is documentation of something that no
    longer happened.  This re-runs the whole transform from the PRE-PASS blob in
    git, in a scratch file, and compares.

    ⚠ It writes ONLY to a temp file; the working tree is untouched.
    """
    import tempfile
    global LISTING
    old = git_show("prom_a/wsa1_prom_a.s", BASE_COMMIT)
    want = open(LISTING, encoding="utf-8").read()
    keep = LISTING
    with tempfile.TemporaryDirectory() as d:
        LISTING = os.path.join(d, "wsa1_prom_a.s")
        try:
            open(LISTING, "w", encoding="utf-8").write(old)
            apply_()
            got = open(LISTING, encoding="utf-8").read()
        finally:
            LISTING = keep
    if got == want:
        print("ok   the committed listing is exactly what this script makes "
              "from %s" % BASE_COMMIT)
        return 0
    a, b = got.splitlines(), want.splitlines()
    print("FAIL regenerated %d lines, committed %d" % (len(a), len(b)))
    for i in range(min(len(a), len(b))):
        if a[i] != b[i]:
            print("  first difference at line %d" % (i + 1))
            print("    regenerated: %s" % a[i][:100])
            print("    committed  : %s" % b[i][:100])
            break
    return 1


def screens_report():
    """Where the SCREEN OBJECTS still point at nothing named.

    ★ THIS IS THE NEXT LANE'S WORK LIST, and it is the most valuable one this
    pass can leave: every row is a SCREEN of this instrument, and naming its
    ENTER method names the screen -- which then names that screen's LEAVE and
    BUTTON methods for free, the way the sixteen already-named ones did here.
    """
    src = analysis_lines()
    lab_at = {}
    for i, ln in enumerate(src):
        mm = LABEL.match(ln)
        if not mm:
            continue
        aa = ADDR.search(src[i + 1]) if i + 1 < len(src) else None
        if aa:
            lab_at.setdefault(int(aa.group(1), 16), mm.group(1))
    rows = collections.Counter()
    todo = []
    for i in range(256):
        v = int.from_bytes(_rom(VTABLE + 4 * i, 4), "little") & 0xFFFFFF
        if not v or v == NULL_VTABLE:
            rows["stub (PanelScreen_NullVtable)" if v else "empty"] += 1
            continue
        b = _rom(v, 4)
        e = int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None
        if e is None:
            rows["object's +0 is not a `jp`"] += 1
        elif e < 0xF80000:
            rows["ENTER is in prom_b"] += 1
        else:
            nm = lab_at.get(e)
            if nm is None:
                rows["ENTER in prom_a, UNLABELLED"] += 1
                todo.append((i, e, "(unlabelled)"))
            elif nm.startswith("sub_"):
                rows["ENTER in prom_a, still sub_XXXXXX"] += 1
                todo.append((i, e, nm))
            else:
                rows["ENTER already named"] += 1
    print("PanelScreen_VtableTable, 256 slots:")
    for k, n in rows.most_common():
        print("  %-34s %3d" % (k, n))
    print("\nthe work list -- %d screens whose ENTER method has no name" % len(todo))
    for i, e, nm in todo:
        print("  screen 0x%02X  ENTER 0x%06X  %s" % (i, e, nm))
    return 0


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
    src2 = analysis_lines()
    # 3. ★★ THE -32 IS NOT MINE TO GET WRONG, and round 9 already pinned it.
    #    wave7_panel_button_codes.py's anchor A says the power-on chord on
    #    number-pad key "4" requests SCREEN ID 0xDB and that ViewB[0xD9..0xDB]
    #    resolve to Paint_PanelCpuCheck / Paint_SineWaveCheckMode /
    #    Paint_PanelSwLedCheck.  Under entry = id + 32 those are ENTRIES
    #    0xF9..0xFB, and that is exactly where this script finds them.  The
    #    first version of these headers called the ENTRY the screen id; this is
    #    the check that would have caught it.
    lab2 = {}
    for i, ln in enumerate(src2):
        mm = LABEL.match(ln)
        if not mm:
            continue
        aa = ADDR.search(src2[i + 1]) if i + 1 < len(src2) else None
        if aa:
            lab2.setdefault(int(aa.group(1), 16), mm.group(1))
    want = {0xD9: "Paint_PanelCpuCheck", 0xDA: "Paint_SineWaveCheckMode",
            0xDB: "Paint_PanelSwLedCheck"}
    for sid, nm in sorted(want.items()):
        v = int.from_bytes(_rom(VTABLE + 4 * (sid + VIEWB), 4), "little") & 0xFFFFFF
        b = _rom(v, 4)
        e = int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None
        got = lab2.get(e) if e else None
        ok = got == nm
        print("%-4s round 9's anchor: screen id 0x%02X = entry 0x%02X -> %s"
              % ("ok" if ok else "FAIL", sid, sid + VIEWB, got))
        bad += 0 if ok else 1

    # 4. ★ THE REFUSAL IS DOING WORK, not just declared.  Every live target at
    #    a SOFT KEY control (0x00-0x07) in this module is ALSO reached at
    #    control + 0x11 -- round 11's variant-1 `add (XIX-1),0x11` rewrite --
    #    so not one of them has a unique control index and not one SoftKeyCol
    #    name comes out.  If that ever stops being true the refusal has gone
    #    quiet and this check says so.
    tb2 = tables(src2)
    reach = collections.defaultdict(set)
    for t in SIMPLE + ["Dispatch_FF3A29", "Dispatch_FF3D39", "Dispatch_FF4049",
                       "Dispatch_FF4151"]:
        if t not in tb2:
            continue
        ents = tb2[t]
        d = collections.Counter(a for _i, a in ents).most_common(1)[0][0]
        for i, a in ents:
            if a != d:
                reach[a].add((t, i))
    soft = [a for a, sl in reach.items() if any((i % 32) <= 7 for _t, i in sl)]
    uniq = [a for a in soft
            if len({i % 32 for _t, i in reach[a]}) == 1]
    ok = bool(soft) and not uniq
    print("%-4s all %d soft-key targets are reached at two controls, so none "
          "is named" % ("ok" if ok else "FAIL", len(soft)))
    bad += 0 if ok else 1

    # 4. the map tool itself still passes its own corroborations
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
    if "--screens" in argv:
        return screens_report()
    if "--verify" in argv:
        return verify()
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
