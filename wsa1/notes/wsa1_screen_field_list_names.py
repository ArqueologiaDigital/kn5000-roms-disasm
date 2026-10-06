#!/usr/bin/env python3
"""wsa1_screen_field_list_names.py -- name each prom_b ScreenFieldList after the one screen that uses it.

QUESTION IT ANSWERS
  prom_b ScreenFieldListPtrs (0xF2D000) holds 256 pointers indexed by the SCREEN ID at RAM 0x207C (prom_a
  0xF9940B reads it); the 127 lists they point at were named by address (ScreenFieldList_F2Dxxx).  prom_a
  PanelScreen_VtableTable entry 32 + id is that screen's object, and its label names the screen
  (T_ScreenEnter_StepRecord, T_ToneEditPage_A5_FittingMutingTuning, T_InstallPainter_SoundMode_Entry).  A list
  that exactly ONE screen id points at, where that screen's object has a name, becomes
  ScreenFieldList_<Screen> (the object label without T_, ScreenEnter_ / ScreenEnterBody_ / InstallPainter_ /
  Paint_, _Fwd, _Entry[_n]; a second screen with the same name gets 2, 3, ...).  Lists shared by several
  screen ids -- the empty list most of all -- keep their address.

RUN (from wsa1/)
  python3 notes/wsa1_screen_field_list_names.py --list
  python3 notes/wsa1_screen_field_list_names.py --args     # 'old=new|header' items for wsa1_rename.py
"""
import collections
import re
import sys


def longs_after(lines, label, n):
    i = next(k for k, l in enumerate(lines) if l.startswith(label + ":"))
    out = []
    for l in lines[i + 1:]:
        m = re.match(r'^\s*\.long\s+([^\s;,]+)', l)
        if m:
            out.append(m.group(1))
            if len(out) == n:
                break
    return out


def screen_name(obj):
    if obj.startswith("PanelScreen_NullVtable") or re.match(r'^(T_F[0-9A-F]{5}|0x)', obj):
        return None
    s = re.sub(r'^T_', '', obj)
    s = re.sub(r'^(ScreenEnterBody_|ScreenEnter_|InstallPainter_|Paint_)', '', s)
    s = re.sub(r'(_Fwd|_Entry(_\d+)?)$', '', s)
    return s


def plan():
    a = open("prom_a/wsa1_prom_a.s", "rb").read().decode("latin-1").split("\n")
    b = open("prom_b/wsa1_prom_b.s", "rb").read().decode("latin-1").split("\n")
    vt = longs_after(a, "PanelScreen_VtableTable", 256)
    lists = longs_after(b, "ScreenFieldListPtrs", 256)
    users = collections.defaultdict(list)
    for sid, lst in enumerate(lists):
        users[lst].append(sid)
    out = {}
    for lst, sids in users.items():
        if not re.match(r'^ScreenFieldList_F[0-9A-F]{5}$', lst) or len(sids) != 1:
            continue
        sid = sids[0]
        nm = screen_name(vt[32 + sid]) if 32 + sid < len(vt) else None
        if nm:
            new, k = "ScreenFieldList_" + nm, 2
            while new in {v[2] for v in out.values()}:
                new, k = "ScreenFieldList_%s%d" % (nm, k), k + 1
            out[lst] = (sid, vt[32 + sid], new)
    return out, users


def main():
    out, users = plan()
    if "--args" in sys.argv:
        for old, (sid, obj, new) in sorted(out.items()):
            print("%s=%s|; the field list of screen id 0x%02X only (ScreenFieldListPtrs[0x%02X]; screen object %s)"
                  % (old, new, sid, sid, obj))
    else:
        for old, (sid, obj, new) in sorted(out.items()):
            print("%-24s id 0x%02X  %-44s %s" % (old, sid, obj, new))
        bare = [l for l in users if re.match(r'^ScreenFieldList_F[0-9A-F]{5}$', l)]
        print("%d address-named lists in ScreenFieldListPtrs; %d used by exactly one named screen"
              % (len(bare), len(out)))


if __name__ == "__main__":
    main()
