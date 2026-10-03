#!/usr/bin/env python3
"""Name the prom_a routines that implement one panel key's action for one screen or one group of screens.

QUESTION IT ANSWERS
  Once the screens and their key handlers carry names (<Control>_<Screen>: SoftKeyCol2_SoundEditAmpLfo,
  ...), a sub_ routine that is called ONLY by handlers of ONE control is that control's action: the
  handler passes its screen's index and the routine does the work (SoundEditLfo_SoftKeyCol2, called by
  SoftKeyCol2_ of the three LFO pages, posts the repaint of 0x8A / 0x8F / 0x99 by that index).  Such a
  routine is named <Group>_<Control>:
      <Group> = the screen when one screen calls it, else the longest common CamelCase prefix of the
                screens' names (SoundEditAmpLfo + SoundEditFilterLfo + SoundEditPitchLfo -> SoundEdit +
                the common suffix Lfo -> SoundEditLfo; see group());
      <Control> = the callers' common control (SoftKeyCol1-8, LcdKeyRow1-5, ExitKey, PageKey, NumberPadKey).
  REFUSED: any routine with a caller that is not a <Control>_<Screen> handler, callers of two
  different controls, a group name that would be empty, or a routine that is ALSO a `.long` table
  entry (a button-table slot gives it a role its call sites do not show).

RUN
  python3 notes/prom_a_screen_key_actions.py          # the plan and the refusals
  python3 notes/prom_a_screen_key_actions.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
CTRL = r'(SoftKeyCol\d|LcdKeyRow\d|ExitKey|PageKey|NumberPadKey)'
LABELS = set(re.findall(r'^([A-Za-z_][\w$]*):', A + "\n" + B, re.M))
TABLED = set(re.findall(r'^\s*(?:[A-Za-z_][\w$]*:)?\s*\.long\s+(sub_F[0-9A-F]{5})\b', A + "\n" + B, re.M))


def callers():
    out = collections.defaultdict(set)
    for text in (A, B):
        cur = None
        for l in text.split("\n"):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if m:
                cur = m.group(1)
                continue
            for t in re.findall(r'\b(?:call|calr|jp|jr|jrl)\s+(?:\w+,\s*)?(sub_F[0-9A-F]{5})\b', l.split(";")[0], re.I):
                out[t].add(cur)
    return out


def words(n):
    return re.findall(r'[A-Z][a-z0-9]*|[0-9]+', n)


def group(screens):
    if len(screens) == 1:
        return screens[0]
    ws = [words(s) for s in screens]
    pre = []
    for t in zip(*ws):
        if len(set(t)) == 1:
            pre.append(t[0])
        else:
            break
    suf = []
    for t in zip(*[w[::-1] for w in ws]):
        if len(set(t)) == 1 and len(pre) + len(suf) < min(map(len, ws)):
            suf.append(t[0])
        else:
            break
    return "".join(pre + suf[::-1])


def plan():
    rows, refused = [], []
    for t, cs in sorted(callers().items()):
        if t not in LABELS:
            continue                        # prom_a or prom_b (2026-10-03: prom_b added)
        if t in TABLED:
            refused.append((t, "also a table entry; its call sites are not its only role"))
            continue
        ms = [re.match(r'^%s_(\w+)$' % CTRL, c or "") for c in cs]
        if not all(ms):
            continue                        # not purely a key action
        ctrls = {m.group(1) for m in ms}
        screens = sorted({m.group(2) for m in ms})
        if len(ctrls) != 1:
            refused.append((t, "callers of %s" % sorted(ctrls)))
            continue
        g = group(screens)
        if g == "Edit" and set(screens) == {"NoteEdit", "DrumEdit"}:
            g = "EditScreen"                # the convention <Control>_EditScreen already uses
        if not g or g in ("SoundEdit", "Edit"):
            refused.append((t, "no common screen group for %s" % screens))
            continue
        ctl = ctrls.pop()
        name = "%s_%s" % (g, ctl)
        rows.append((t, name, "%s: the %s action of %s -- called only by %s." % (
            name, ctl, ", ".join(screens), ", ".join(sorted(cs)))))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    cnt = collections.Counter(r[1] for r in rows)
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
