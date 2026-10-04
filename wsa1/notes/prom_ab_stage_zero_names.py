#!/usr/bin/env python3
"""Name the screen routines that drop a two-stage screen back to its stage 0: <Screen>_ReturnToStageZero.

QUESTION IT ANSWERS
  Several screens have a stage 0 and a stage 1, kept in UI_ScreenStage (FINDINGS-prom_ab-screen-stage-and-flags.md).
  The key-actions planner (notes/prom_a_screen_key_actions.py) refuses a routine that keys of two different
  controls call, typically ExitKey plus one LcdKeyRowN.  Many of those have one body:
      [cp UI_ScreenStage,1 / jr nz ret]  UI_ScreenStage = 0  UI_Request_Hi |= 0x10  [a few plain stores]  ret
  It puts the screen back in stage 0 and raises the repaint request bit 4 of UI_Request_Hi.  The reading log
  already names one routine of this shape TrackAssign_ReturnToStageZero (prom_ab_read_names_2026_10_04.py).
  A routine is named <Group>_ReturnToStageZero when
    * its body stores 0 to UI_ScreenStage and ORs 0x10 into UI_Request_Hi;
    * it calls nothing (no call / calr / jp / jrl out of it) and ends `ret` or `jr <X>_Return<n>`; and
    * every caller is a <Control>_<Screen> or <Screen>_<Control> key handler, after crediting branch-target labels
      to their routine and resolving prom_b's thunk directory (the key-actions planner's callers()).
  <Group> is the screen, or key-actions' group() of several screens, less a _StageNonZero / _StageZero suffix
  (the handlers of a two-stage screen carry the stage they serve; the routine is the screen's).  REFUSED: a caller that is not a key
  handler, an empty group, a name taken.

RUN
  python3 notes/prom_ab_stage_zero_names.py          # the plan and the refusals
  python3 notes/prom_ab_stage_zero_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prom_a_screen_key_actions as KA

LOCAL = re.compile(r'_(Skip|Join|Loop|Return|Epilogue)\d*$')


def bodies():
    for text in (KA.A, KA.B):
        L = text.split("\n")
        st = [(i, m.group(1)) for i, l in enumerate(L) for m in [re.match(r'^([A-Za-z_][\w$]*):', l)] if m]
        for k, (i, n) in enumerate(st):
            if not re.match(r'^sub_F[0-9A-F]{5}$', n):
                continue
            j = k + 1
            while j < len(st) and LOCAL.search(st[j][1]):
                j += 1                       # branch targets stay in the body, whatever routine their name came from
            end = st[j][0] if j < len(st) else len(L)
            b = [re.sub(r'\s+', ' ', l.split(";")[0]).strip() for l in L[i + 1:end]]
            yield n, [x for x in b if x and not re.match(r'^[A-Za-z_.][\w$.]*:', x)]


def plan():
    cs = KA.callers()
    rows, refused = [], []
    for n, b in bodies():
        t = " | ".join(b)
        if not (re.search(r'ld \(UI_ScreenStage:16\), 0\b', t) and re.search(r'UI_Request_Hi, 0x10\b', t)):
            continue
        # a last `jr <X>_Return<n>` is a tail jump to another routine's bare `ret`
        last_ok = b and (b[-1] == "ret" or re.match(r'^jr \w+_Return\d*$', b[-1]))
        if re.search(r'\b(call|calr|jp|jrl)\b', t, re.I) or not last_ok or len(b) > 14:
            refused.append((n, "not the plain shape (%d instructions)" % len(b)))
            continue
        callers = cs.get(n, set())
        ms = [re.match(r'^%s_(\w+)$' % KA.CTRL, c or "") or re.match(r'^(\w+?)_%s$' % KA.CTRL, c or "") for c in callers]
        if not callers or not all(ms):
            refused.append((n, "callers %s" % sorted(c or "?" for c in callers)))
            continue
        screens = sorted({(m.group(2) if m.re.pattern.startswith('^' + KA.CTRL) else m.group(1)) for m in ms})
        g = re.sub(r'_Stage(Non)?Zero$', '', KA.group(screens))   # the stage is what the routine changes
        if not g:
            refused.append((n, "no common group for %s" % screens))
            continue
        new = g + "_ReturnToStageZero"
        rows.append((n, new, "%s: UI_ScreenStage = 0 and UI_Request_Hi |= 0x10 -- back to stage 0 of %s;\\n"
                     "  called by %s (notes/prom_ab_stage_zero_names.py)." % (new, ", ".join(screens), ", ".join(sorted(callers)))))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', KA.A + KA.B))
    names = [r[1] for r in rows]
    for o, n, h in rows:
        bad = names.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-12s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if not (names.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
