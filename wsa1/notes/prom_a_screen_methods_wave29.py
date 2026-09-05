#!/usr/bin/env python3
"""Finish naming prom_a's SCREEN OBJECTS: the LEAVE (+4) and BUTTON (+8) methods
of every screen whose ENTER (+0) method already carries a NAME but which
notes/prom_a_naming_wave8_apply.py left untouched.

QUESTION IT ANSWERS
-------------------
  "For a screen object in PanelScreen_VtableTable whose +0 ENTER method already
   has a name -- so the screen's identity is established, not guessed -- what
   are its +4 LEAVE and +8 BUTTON methods called, by exactly the evidence wave8
   used for the sixteen it did?"

WHY THIS IS THE LANE'S JOB, AND WHY IT WAS LEFT
  wave8 cascades LEAVE/BUTTON only from an ENTER that starts `Paint_`.  Twenty
  screens name their ENTER with a DIFFERENT family -- `ShowScreen_*`,
  `Screen_*_Enter`, `InstallPainter_*_Entry`, `PageDispatch_*`, and the
  tone-editor lane's `ToneEditPage_A?_*` -- so wave8 skipped their two other
  slots, and they are still `sub_XXXXXX`.  This closes that gap and nothing more.

★ THE SCREEN IDENTITY IS INHERITED, NOT INVENTED.  Every suffix here is lifted
  from the ENTER method's OWN existing label (`ShowScreen_NoteEditPartSelect`
  -> the screen is `NoteEditPartSelect`); no new claim about what a screen IS is
  made.  What is new is only that the object's other two slots are tied to it,
  and the +4/+8 offsets are PanelScreen_VtableTable's own (its header's checks
  V1-V6), not a guess about layout.

  ⚠ IT DOES NOT NAME ANY ENTER METHOD FROM PAINTED TEXT.  That route was tried
  and REFUSED -- see notes/prom_a_screen_titles_probe.py, whose CALIBRATION
  shows the first (or the left-margin) title an ENTER method paints is a shared
  banner or a field label more often than the screen's name: Paint_Sequencer
  paints "REALTIME" first, Paint_DiskL0adFile paints "SAVE".  Following the
  delegation, as FINDINGS-prom_a-panel-control-map.md section 6 advised, does
  not fix it -- the title is data-driven, read from a record by a helper.  So
  the ~90 screens whose ENTER is still `sub_` stay `sub_`, on purpose.

THE ONE ENTER IT DOES NAME
  Paint_DiskMenu (0xFF42CD), and NOT from a title it read.  Round 7 already
  identified this routine as "the DISK menu's INDEX" and REFUSED to name it
  after a caption; wave8's SCREEN_DECLARED then declared screen 0x60 = DiskMenu.
  Naming it after the MENU is what both of those point at, and it is applied by
  ANSWERING round 7's refusal header in place (kept verbatim), the way wave8
  answered round 7's FF4ACB/FF4D5D refusal.

WHAT IT REFUSES, and this is the point
  * a +4/+8 slot SHARED by two screen objects -- a shared routine cannot carry
    one screen's name (same rule as wave8);
  * a slot already NAMED -- including one wave8 or the tone lane named;
  * a BUTTON slot that is a control-table READER -- PanelButtonDispatch_X /
    PageDispatch_X says what ScreenButton_X says and more, so the reader wins;
  * a target not in prom_a, or not the start of a listing line.

USAGE
    python3 notes/prom_a_screen_methods_wave29.py --plan
    python3 notes/prom_a_screen_methods_wave29.py --apply      # idempotent
    python3 notes/prom_a_screen_methods_wave29.py --selftest
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_naming_wave8_apply as W8       # noqa: E402  reuse its machinery

_rom = W8._rom
VTABLE, NULL = W8.VTABLE, W8.NULL_VTABLE
LABEL, ADDR = W8.LABEL, W8.ADDR
screen_id_phrase = W8.screen_id_phrase


def _jp(a):
    b = _rom(a, 4)
    return int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None


# The ONE ENTER method this script names, from wave8's SCREEN_DECLARED evidence
# and round 7's own identification -- never from a title this script read.
ENTER_DECLARED = {
    0x60: ("DiskMenu", 0xFF42CD,
           "round 7 identified 0xFF42CD as \"the DISK menu's INDEX\" and "
           "refused to name it after a CAPTION (its header below); wave8's "
           "SCREEN_DECLARED then declared screen 0x60 = DiskMenu.  This names "
           "it after the MENU, which both point at: it hands the interpreter "
           "the lists at 0xF58014 (\"DISK\"), 0xF580B0 (\"MIDI FILE LOAD\") "
           "and 0xF58127 (\"LOAD\"), choosing on the model strap (0xC4) at "
           "0xFF42EE -- the site this module's banner already calls the disk "
           "menu.  wave8 named the screen's READER "
           "(PanelButtonDispatch_DiskMenu) from this same object"),
}

ENTER_PREFIXES = ("Paint_", "ShowScreen_", "InstallPainter_", "Screen_")


def _suffix(enter_label):
    """The screen name carried by an ENTER label."""
    s = enter_label
    for p in ENTER_PREFIXES:
        if s.startswith(p):
            s = s[len(p):]
            break
    if s.startswith("PageDispatch_"):
        s = s[len("PageDispatch_"):]
    for suf in ("_Entry", "_Enter"):
        if s.endswith(suf):
            s = s[:-len(suf)]
    return s


def _tone_page(enter_label):
    """`ToneEditPage_A3_PositionParameter` -> `A3`, else None."""
    m = re.match(r'ToneEditPage_(A\d)_', enter_label)
    return m.group(1) if m else None


def _labels(src):
    out = {}
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if m and i + 1 < len(src):
            a = ADDR.search(src[i + 1])
            if a:
                out.setdefault(int(a.group(1), 16), m.group(1))
    return out


def plan():
    src = W8.analysis_lines()
    lab = _labels(src)
    at = W8.line_of_addr(src)
    jobs = []          # (addr, kind, old, new, header, overturn?)

    # 1. the one declared ENTER, applied by ANSWERING round 7's refusal
    for i, (name, addr, why) in ENTER_DECLARED.items():
        cur = lab.get(addr)
        if not cur or not cur.startswith("sub_"):
            continue
        new = "Paint_" + name
        hdr = [
            "%s -- the ENTER method (painter) of the screen object at "
            "PanelScreen_VtableTable %s" % (new, screen_id_phrase(i)),
            "",
            "Reached from: PanelScreen_VtableTable entry 0x%02X, +0 slot, "
            "called by PanelScreen_CallEnter_A/B with the id that has just "
            "become current." % i,
            "Evidence: %s." % why,
            "See notes/FINDINGS-prom_a-panel-control-map.md and wave8's "
            "SCREEN_DECLARED.  This name is the MENU, not a caption, so it does "
            "not fall to round 7's refusal below -- it is what that refusal "
            "pointed at.",
            "Was `%s`." % cur,
        ]
        jobs.append((addr, "rename", cur, new, hdr, True))
        lab[addr] = new                    # so the cascade below sees it named

    # 2. share count and reader set, from the CURRENT labels
    use = collections.Counter()
    objs = []
    for i in range(256):
        v = int.from_bytes(_rom(VTABLE + 4 * i, 4), "little") & 0xFFFFFF
        if not v or v == NULL:
            continue
        e, l, b = _jp(v), _jp(v + 4), _jp(v + 8)
        objs.append((i, v, e, l, b))
        for x in (l, b):
            if x:
                use[x] += 1
    readers = {a for a, n in lab.items()
               if n and (n.startswith("PanelButtonDispatch_")
                         or n.startswith("PageDispatch_"))}

    # 3. the LEAVE/BUTTON cascade
    for i, v, e, l, b in objs:
        en = lab.get(e) if e else None
        if not en or en.startswith("sub_") or en.startswith("."):
            continue
        tone = _tone_page(en)
        scr = _suffix(en)
        for off, tgt, root, what in ((4, l, "ScreenLeave", "LEAVE"),
                                     (8, b, "ScreenButton", "BUTTON")):
            if not tgt or not (0xF80000 <= tgt < 0x1000000):
                continue
            cur = lab.get(tgt)
            if cur and not cur.startswith("sub_"):
                continue                    # already named
            if use[tgt] > 1:
                continue                    # shared across objects
            if tgt in readers:
                continue                    # BUTTON that is a control reader
            if tgt not in at:
                continue                    # not a listing-line start
            # tone-editor pages keep THEIR family's spelling: the sibling
            # BUTTON is ToneEditPage_A?_KeyDispatch, so the LEAVE is
            # ToneEditPage_A?_Leave -- consistent, not a second vocabulary.
            if tone and off == 4:
                new = "ToneEditPage_%s_Leave" % tone
            elif tone:
                new = "ToneEditPage_%s_%s" % (tone, what.title())
            else:
                new = "%s_%s" % (root, scr)
            bare = _rom(tgt, 1) == b"\x0e"
            hdr = [
                "%s -- the %s method of the screen object at "
                "PanelScreen_VtableTable %s" % (new, what, screen_id_phrase(i)),
                "",
                "Reached from: PanelScreen_VtableTable entry 0x%02X -> the "
                "screen object at 0x%06X, whose +%d slot is `jp 0x%06X`, and "
                "from no other live screen object's two callable slots."
                % (i, v, off, tgt),
                "Evidence: the +%d offset is PanelScreen_VtableTable's own (its "
                "header's checks V1-V6): +0 ENTER is called by "
                "PanelScreen_CallEnter_A/B, +4 LEAVE by PanelScreen_CallLeave_"
                "A/B with the id that just STOPPED being current, +8 BUTTON by "
                "PanelButton_Route (0xF8621E)." % off,
                "Screen:  %s -- inherited from the +0 ENTER label %s, not from "
                "any text this pass read." % (tone or scr, en),
            ]
            if tone:
                hdr.append("Family:  the tone-editor lane named this screen's "
                           "+0 (%s) and +8 (ToneEditPage_%s_KeyDispatch) but "
                           "not its +4; this fills that one slot in its own "
                           "spelling." % (en, tone))
            if bare:
                hdr.append("Body:    ONE BYTE, 0x0E -- a bare `ret`.  This "
                           "screen does nothing on %s; the slot exists to keep "
                           "the three-method shape." % what.lower())
            hdr.append("Was `%s`." % cur)
            jobs.append((tgt, "rename", cur, new, hdr, False))

    seen = collections.Counter(j[3] for j in jobs)
    dup = [n for n, c in seen.items() if c > 1]
    assert not dup, "duplicate proposed names: %s" % dup
    return src, jobs


def apply_():
    _s, jobs = plan()
    src = W8.lines()
    have = W8.line_of_addr(src)
    stray = [j[0] for j in jobs if j[0] not in have]
    if stray:
        raise AssertionError("addresses not in the primary: %s"
                             % ", ".join("0x%06X" % a for a in stray[:4]))
    text = "\n".join(src)
    for a, kind, old, new, _h, _ov in jobs:
        if kind == "rename" and re.search(r'\b%s\b' % old, text):
            text = re.sub(r'\b%s\b' % old, new, text)
    src = text.splitlines()

    added = 0
    for addr, kind, _old, new, hdr, overturn in sorted(jobs, key=lambda j: -j[0]):
        at = W8.line_of_addr(src)
        li = at[addr]                       # the CODE line for this address
        have = W8.label_at(src, li)         # (label, label-line) above it
        if not have:
            raise AssertionError("0x%06X has no label to head" % addr)
        if have[0] != new:
            raise AssertionError("0x%06X carries %s, not %s"
                                 % (addr, have[0], new))
        li = have[1]                        # ★ insert ABOVE the LABEL, not the code
        # is there already a header block above the label?
        j = li - 1
        while j >= 0 and not src[j].strip():
            j -= 1
        if j >= 0 and src[j].startswith("; ----"):
            top = j
            while top > 0 and src[top - 1].lstrip().startswith(";"):
                top -= 1
            block = "\n".join(src[top:j + 1])
            if new in block and "PanelScreen_VtableTable" in block:
                continue                    # ours already: idempotent
            if overturn:
                # SOMEONE ELSE'S header -- keep it verbatim, answer ABOVE it.
                extra = list(hdr) + [
                    "",
                    "★ THIS ANSWERS THE HEADER BELOW, kept verbatim.  Its "
                    "refusal was of a CAPTION name (\"naming it after one "
                    "would claim a screen another routine paints\") and it was "
                    "right; this names the MENU the header itself identifies, "
                    "which no caption does.  Its opening line now carries the "
                    "new label because the rename is file-wide; every other "
                    "word, refusal included, is the record of how the gap "
                    "closed.",
                ]
                src[top:top] = W8.render(extra)
                added += 1
                continue
            # not an overturn: don't write through another header; skip
            continue
        src[li:li] = W8.render(hdr)
        added += 1
    open(W8.LISTING, "w", encoding="utf-8").write("\n".join(src) + "\n")
    return added


def selftest():
    fails = 0
    v = int.from_bytes(_rom(VTABLE + 4 * 0xF9, 4), "little") & 0xFFFFFF
    lab = _labels(W8.analysis_lines())
    ok = lab.get(_jp(v)) == "Paint_PanelCpuCheck"
    print("%s round 9 anchor: entry 0xF9 +0 -> Paint_PanelCpuCheck"
          % ("ok  " if ok else "FAIL"))
    fails += not ok
    for enter, want in (("Paint_MidiFileL0ad", "MidiFileL0ad"),
                        ("ShowScreen_NoteEditPartSelect", "NoteEditPartSelect"),
                        ("Screen_CombinationNaming_Enter", "CombinationNaming"),
                        ("InstallPainter_SoundGroupMenu_Entry", "SoundGroupMenu"),
                        ("PageDispatch_DiskSaveFile", "DiskSaveFile")):
        got = _suffix(enter)
        ok = got == want
        print("%s suffix(%s) = %s" % ("ok  " if ok else "FAIL", enter, got))
        fails += not ok
    ok = _tone_page("ToneEditPage_A5_FittingMutingTuning") == "A5"
    print("%s tone_page(ToneEditPage_A5_FittingMutingTuning) = A5"
          % ("ok  " if ok else "FAIL"))
    fails += not ok
    try:
        _s, jobs = plan()
        print("ok   plan() builds, %d jobs, no duplicate names" % len(jobs))
    except AssertionError as ex:
        print("FAIL plan():", ex)
        fails += 1
    print("FAILURES:", fails)
    return 1 if fails else 0


def main():
    a = sys.argv[1] if len(sys.argv) > 1 else "--plan"
    if a == "--plan":
        _s, jobs = plan()
        for addr, kind, old, new, _h, ov in sorted(jobs):
            print("  0x%06X  %-8s %-36s <- %-14s%s"
                  % (addr, kind, new, old, "  (overturns a refusal)" if ov else ""))
        print("%d jobs" % len(jobs))
    elif a == "--apply":
        print("applied: %d header/label blocks" % apply_())
    elif a == "--selftest":
        sys.exit(selftest())
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
