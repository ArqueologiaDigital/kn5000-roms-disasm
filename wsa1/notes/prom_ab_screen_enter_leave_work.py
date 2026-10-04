#!/usr/bin/env python3
"""Name the unnamed routine that is a screen's ENTER or LEAVE work: <Screen>_OnEnter / <Screen>_OnLeave.

QUESTION IT ANSWERS
  A screen object's +0 ENTER and +4 LEAVE methods (PanelScreen_VtableTable; their names are
  ScreenEnter_<Screen> / ScreenLeave_<Screen>, or the ScreenEnterBody_ / ScreenLeaveBody_<Screen> they
  call) mostly do their work in one routine of the other image, reached through the thunk directory:
  ScreenLeaveBody_MeasureDelete is `call T_MeasureDelete_OnLeave / ret`, and T_MeasureDelete_OnLeave is `jp MeasureDelete_OnLeave`.  When
      the method body (the lines between its label and the next label) calls exactly ONE still-unnamed
      `sub_` (directly or through a T_F4xxxx thunk), and
      every caller of that sub_ is a method of the SAME role (Enter / Leave),
  the sub_ is that role's work for those screens and is named <Group>_OnEnter / <Group>_OnLeave,
  <Group> as notes/prom_a_screen_key_actions.py groups screens (one screen: its name;
  ScreenEnter_SoundEditAmpLfo / _FilterLfo / _PitchLfo: SoundEditLfo).
  A label with a branch-target suffix (_Skip, _Join, _Loop, _Return, _Nop) is never a method: some of
  those sit inside OTHER routines (ScreenLeaveBody_MeasureDelete_Skip is in SoftKeyCol5_MeasureDelete_StageZero),
  and a method whose span does not end in `ret` before the next label is refused, its body may go on.
  REFUSED: a method body with two or more unnamed callees (which one is "the" work is not said), a
  callee with any other caller, a callee that is also a `.long` table entry, a numbered screen
  (Code<XX> -- its name is not known yet), and a group that comes out empty.

RUN
  python3 notes/prom_ab_screen_enter_leave_work.py          # the plan and the refusals
  python3 notes/prom_ab_screen_enter_leave_work.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import prom_a_screen_key_actions as KA  # noqa: E402  group(), THUNK, TABLED, A, B

METHOD = re.compile(r'^(ScreenEnter|ScreenEnterBody|ScreenLeave|ScreenLeaveBody)_(\w+)$')
ROLE = {"ScreenEnter": "Enter", "ScreenEnterBody": "Enter", "ScreenLeave": "Leave", "ScreenLeaveBody": "Leave"}


LOCAL = re.compile(r'_(Skip|Join|Loop|Return|Nop)\d*$')   # a branch target inside a routine, not a routine


def calls_by_label():
    """({label: [callee, ...]}, {label: last instruction}) over the lines between a label and the next
    one; thunks resolved.  The last instruction says whether that span is a whole routine."""
    out, last = collections.defaultdict(list), {}
    for text in (KA.A, KA.B):
        cur = None
        for l in text.split("\n"):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if m:
                cur = m.group(1)
                continue
            code = l.split(";")[0].strip()
            if code and not code.startswith("."):
                last[cur] = code
            for t in re.findall(r'\b(?:call|calr|jp|jr|jrl)\s+(?:\w+,\s*)?(\w+)\b', code, re.I):
                out[cur].append(KA.THUNK.get(t, t))
    return out, last


def plan():
    calls, last = calls_by_label()
    callers = collections.defaultdict(set)
    for r, ts in calls.items():
        for t in ts:
            callers[t].add(r)
    work = collections.defaultdict(set)          # sub_ -> {method}
    refused = []
    for r, ts in sorted(calls.items(), key=lambda x: x[0] or ""):
        m = METHOD.match(r or "")
        if not m or LOCAL.search(r):
            continue
        if not re.match(r'^(ret|retd\b|jp\s+\w+$|jrl\s+\w+$)', last.get(r, "")):
            refused.append((r, "its span ends at another label, not at `ret` -- the body may go on"))
            continue
        subs = list(dict.fromkeys(t for t in ts if re.match(r'^sub_F[0-9A-F]{5}$', t)))
        if len(subs) > 1:
            refused.append((r, "calls %d unnamed routines: %s" % (len(subs), ", ".join(subs))))
            continue
        if subs:
            work[subs[0]].add(r)
    rows = []
    for t, ms in sorted(work.items()):
        roles = {ROLE[METHOD.match(c).group(1)] for c in ms}
        others = sorted(c for c in callers[t] if not METHOD.match(c or "") or LOCAL.search(c))
        screens = sorted({METHOD.match(c).group(2) for c in ms})
        if others:
            refused.append((t, "also called by %s" % ", ".join(others)))
            continue
        if t in KA.TABLED:
            refused.append((t, "also a table entry"))
            continue
        if len(roles) != 1:
            refused.append((t, "work of both Enter and Leave (%s)" % ", ".join(sorted(ms))))
            continue
        if any(re.match(r'^Code[0-9A-F]{2}$', s) for s in screens):
            refused.append((t, "a numbered screen: %s" % ", ".join(screens)))
            continue
        g = KA.group(screens)
        if not g:
            refused.append((t, "no common screen name for %s" % screens))
            continue
        role = roles.pop()
        name = "%s_On%s" % (g, role)
        rows.append((t, name, "%s: the %s work of %s -- the one unnamed routine %s calls, and nothing else calls it\\n"
                     "  (notes/prom_ab_screen_enter_leave_work.py)." % (name, role.upper(), ", ".join(screens), " / ".join(sorted(ms)))))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', KA.A + KA.B))
    cnt = collections.Counter(n for _o, n, _h in rows)
    for o, n, h in rows:
        bad = cnt[n] > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-12s -> %s%s" % (o, n, "  CONFLICT" if bad else ""))
    if "--args" not in sys.argv:
        for t, why in refused:
            print("REFUSED %s: %s" % (t, why))
        print("rename %d (conflicts %d), refused %d" % (sum(1 for _o, n, _h in rows if not (cnt[n] > 1 or n in taken)),
                                                       sum(1 for _o, n, _h in rows if cnt[n] > 1 or n in taken), len(refused)))


if __name__ == "__main__":
    main()
