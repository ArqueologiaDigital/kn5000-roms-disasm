#!/usr/bin/env python3
"""Name screen 0x0E's per-sub-screen panel-button tables and their handlers (prom_b 0xF67xxx).

QUESTION IT ANSWERS
  Two 19-entry tables are indexed by UI_Screen0E_SubScreen (0x0EF5, "which sub-screen of screen 0x0E
  is showing", FINDINGS-prom_b-for-the-mame-driver.md):
      sub_F676B6: `ld E,(UI_Screen0E_SubScreen) / sla DE,2 / ld XHL,DispatchTable_F67723 / call (XIY)`
      sub_F6776F: the same over DispatchTable_F67789
  Each live entry is a button reader of one shape -- `cp HL,0x1F / jr UGT / sla 2,HL /
  ld XIX,<table> / call (XIX+HL)` -- over a 32-entry table that round 11 already proved is indexed
  by the PANEL BUTTON CODE (Screen0ESub00_ButtonTable's header: the five never-emitted codes hold the
  do-nothing stub 80 of 80, and slot 0x0F holds an ExitKey-shaped handler in 15 of 16 tables).
  So a slot is a control, by round 11's own map (wave7_panel_names_round11.CONTROL) and rules:
    * the variant-1 already-held slots 0x11-0x18 fold onto their base code (slot - 0x11);
    * slots 0x0D, 0x0E, 0x19 are refused (REFUSE_SLOT), and 0x1A-0x1F other than 0x1B have no control;
    * a handler whose slots fold to TWO different controls is refused -- one routine, no one name.
  The sub-screen's identity is its NUMBER; what each sub-screen shows is not established here, so
  the spelling is <Control>_Screen0ESub<NN> (NN decimal, the UI_Screen0E_SubScreen value), the
  reader Screen0ESub<NN>_ButtonDispatch and the table Screen0ESub<NN>_ButtonTable.  A reader at
  several sub-screens (Screen0ESub02_ButtonDispatch is entries 2 and 6) takes the first and lists the rest.  A
  handler several sub-screens share under ONE control is <Control>_Screen0E (its header lists every
  table and slot); if two different handlers would take the same shared name, each falls back to
  <Control>_Screen0ESub<first>.

RUN
  python3 notes/prom_b_screen0e_button_names.py          # the plan and the refusals
  python3 notes/prom_b_screen0e_button_names.py --args   # 'old=new|header' lines for the rename helper
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import wave7_panel_names_round11 as R11  # noqa: E402

PROM_B = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
SUBTABLES = ["DispatchTable_F67723", "DispatchTable_F67789"]
SPELL = {"Exit": "ExitKey", "NumberPad": "NumberPadKey", "Page": "PageKey"}


def lines():
    return open(PROM_B, "rb").read().decode("latin-1").split("\n")


def table_entries(L, tab):
    i = [k for k, l in enumerate(L) if l.startswith(tab + ":")][0]
    out = []
    for l in L[i + 1:i + 40]:
        m = re.match(r'^\s*\.long\s+(\S+)\s*;\s*[0-9A-F]{6}\s+\[(\d+)\]', l)
        if not m:
            break
        out.append((int(m.group(2)), m.group(1)))
    return out


def reader_table(L, reader):
    """The 32-entry button table a reader loads with `ld xix, <table>`, or None."""
    i = [k for k, l in enumerate(L) if l.startswith(reader + ":")][0]
    for l in L[i + 1:i + 40]:
        if re.match(r'^[A-Za-z_][\w$]*:', l) and not l.startswith(reader):
            break
        m = re.search(r'\bld\s+xix,\s*(DispatchTable_F6[0-9A-F]{4}|Screen0ESub\d\d_ButtonTable)\b', l.split(";")[0])
        if m:
            return m.group(1)
    return None


def control_of(slot):
    base = slot - 0x11 if 0x11 <= slot <= 0x18 else slot
    if base in R11.REFUSE_SLOT or base not in R11.CONTROL:
        return None
    ctl, gloss = R11.CONTROL[base]
    return SPELL.get(ctl, ctl), gloss


def plan():
    L = lines()
    subs = collections.OrderedDict()            # reader -> [sub-screen numbers]
    for tab in SUBTABLES:
        for k, tgt in table_entries(L, tab):
            if tgt.startswith("sub_"):
                subs.setdefault(tgt, [])
                if k not in subs[tgt]:
                    subs[tgt].append(k)
    rows, refused = [], []
    hand = collections.OrderedDict()             # handler -> [(sub-screen, slot)]
    for reader, ks in subs.items():
        t = reader_table(L, reader)
        if t is None:
            refused.append((reader, "no 32-entry button table loaded"))
            continue
        scr = "Screen0ESub%02d" % ks[0]
        also = (" (also sub-screen%s %s)" % ("s" if len(ks) > 2 else "", ", ".join(str(x) for x in ks[1:]))) if ks[1:] else ""
        rows.append((reader, scr + "_ButtonDispatch",
                     "%s_ButtonDispatch: the panel-button reader of screen 0x0E sub-screen %d%s -- DispatchTable_F67723/F67789\\n"
                     "  entry %d (indexed by UI_Screen0E_SubScreen); calls %s_ButtonTable[code & 0x1F]." % (scr, ks[0], also, ks[0], scr)))
        rows.append((t, scr + "_ButtonTable", ""))
        ents = table_entries(L, t)
        assert len(ents) == 32, (t, len(ents))
        for slot, tgt in ents:
            if re.match(r'^sub_F[0-9A-F]{5}$', tgt):
                hand.setdefault(tgt, []).append((ks[0], slot))
    for tgt, uses in hand.items():
        ctls = {control_of(s) for _k, s in uses}
        subs_ = sorted({k for k, _s in uses})
        where = "; ".join("Screen0ESub%02d_ButtonTable slot 0x%02X" % u for u in uses)
        if None in ctls or len(ctls) != 1:
            refused.append((tgt, where + ": no single control"))
            continue
        (ctl, gloss), = ctls
        scr = "Screen0ESub%02d" % subs_[0] if len(subs_) == 1 else "Screen0E"
        name = "%s_%s" % (ctl, scr)
        rows.append((tgt, name, "%s: %s; %s.  Slot -> control: wave7_panel_names_round11.CONTROL." % (name, gloss, where)))
    # a shared name two different routines would both take: fall back to each one's first sub-screen
    cnt = collections.Counter(r[1] for r in rows)
    fixed = []
    for old, new, hdr in rows:
        if cnt[new] > 1 and new.endswith("_Screen0E"):
            k = int(re.search(r'Screen0ESub(\d\d)_ButtonTable', hdr).group(1))
            new2 = "%sSub%02d" % (new, k)
            fixed.append((old, new2, hdr.replace(new + ":", new2 + ":", 1)))
        else:
            fixed.append((old, new, hdr))
    rows = fixed
    return rows, refused


def main():
    rows, refused = plan()
    names = collections.Counter(r[1] for r in rows)
    dup = {n for n, v in names.items() if v > 1}
    if "--args" in sys.argv:
        for old, new, hdr in rows:
            if new not in dup:
                print("%s=%s%s" % (old, new, ("|" + hdr) if hdr else ""))
        return
    for old, new, _ in rows:
        print("%-24s -> %s%s" % (old, new, "  DUPLICATE" if new in dup else ""))
    for t, why in refused:
        print("REFUSED %s: %s" % (t, why))
    print("rename %d (duplicates withheld %d), refused %d" % (len([r for r in rows if r[1] not in dup]),
                                                             len([r for r in rows if r[1] in dup]), len(refused)))


if __name__ == "__main__":
    main()
