#!/usr/bin/env python3
"""gen_title_switch_case_names.py -- the cases of compiled switches on CURRENT_TITLE take the title's name.

QUESTION IT ANSWERS / WHAT IT DOES
  scripts/tools/frame_switch_cases.py names a switch case <Owner>_Case<value> unless the switch subtracts an EVT_*
  constant (then <Owner>_On<Event>).  Some switches read the current title instead:
      ld a, (CURRENT_TITLE:16) ; extz wa ; sub wa, 0x9b ; ... ; lda xix, (<table>:24) ; ... ; jp t, (xix+wa)
  Their case values are title ids, and shared/event_codes.s names every title after the firmware's own TT_*
  string (TITLE_SQNOTECNG = 0x1A0009F, "TT_SQNOTECNG").  For each `jp t, (...)` site whose 16 lines before it load
  CURRENT_TITLE and subtract a constant, this script reads the table's `.short <Target> - <Base>` lines.  Slot k
  is title (constant + k).  A target named <Prefix>_Case<that value> that is no other slot's target takes
  <Prefix>_OnTitle<Name>, spelled the way frame_switch_cases.py spells events: TITLE_SQNOTECNG -> TitleSqnotecng.
  A target shared by several titles keeps its name.  The rules go to
  scripts/renaming/rename_title_switch_cases_<tree>.sed.

RUN (repository root)
  python3 scripts/renaming/gen_title_switch_case_names.py      # writes the three sed files
  then per tree: sed -i -f scripts/renaming/rename_title_switch_cases_<tree>.sed <files that use the names>
"""
import collections
import glob
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    titles = {}
    for line in open(os.path.join(REPO, "v10/maincpu/shared/event_codes.s"), "rb").read().decode("latin-1").split("\n"):
        m = re.match(r'\.equ\s+(TITLE_\w+),\s*(0x[0-9a-fA-F]+)', line)
        if m:
            v = int(m.group(2), 16) - 0x1A00000
            assert v not in titles, (hex(v), titles.get(v), m.group(1))
            titles[v] = m.group(1)
    for tree in ("v10", "v9", "v7"):
        files = sorted(glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*.s"), recursive=True))
        text = {p: open(p, "rb").read().decode("latin-1").split("\n") for p in files}
        defined = set()
        for L in text.values():
            for line in L:
                m = re.match(r'^(\w+):', line)
                if m:
                    defined.add(m.group(1))
        tables = {}                                     # table label -> list of target names
        for L in text.values():
            for i, line in enumerate(L):
                m = re.match(r'^(\w+):', line)
                if not m:
                    continue
                ents, j = [], i + 1
                while j < len(L):
                    mm = re.match(r'^\s*\.short\s+(\w+)\s*-\s*(\w+)\s*(;.*)?$', L[j])
                    if not mm:
                        break
                    ents.append(mm.group(1))
                    j += 1
                if ents:
                    tables[m.group(1)] = ents
        rules = {}
        for p, L in text.items():
            for i, line in enumerate(L):
                if not re.match(r'\s*jp\s+t,\s*\(', line):
                    continue
                seg = [x.split(";")[0].strip() for x in L[max(0, i - 16):i]]
                if not any(re.match(r'ld\s+[a-z]+,\s*\(CURRENT_TITLE:16\)', x) for x in seg):
                    continue
                sub = [re.match(r'sub\s+wa,\s*(0x[0-9a-fA-F]+|\d+)$', x) for x in seg]
                sub = [s for s in sub if s]
                tab = [re.search(r'lda\s+x\w+,\s*\((\w+):24\)', x) for x in seg]
                tab = [t.group(1) for t in tab if t and t.group(1) in tables]
                if len(sub) != 1 or len(tab) != 1:
                    continue
                base = int(sub[0].group(1), 0)
                ents = tables[tab[0]]
                count = collections.Counter(ents)
                for k, tgt in enumerate(ents):
                    v = base + k
                    m = re.match(r'^(\w+?)_Case(\d+)$', tgt)
                    if not m or int(m.group(2)) != v or count[tgt] != 1 or v not in titles:
                        continue
                    new = "%s_On%s" % (m.group(1), "".join(w.capitalize() for w in titles[v].split("_")))
                    assert new not in defined and new not in rules.values(), (tree, new)
                    rules[tgt] = new
        out = os.path.join(REPO, "scripts/renaming/rename_title_switch_cases_%s.sed" % tree)
        with open(out, "w") as f:
            f.write("# %s: cases of switches on CURRENT_TITLE named by their title (gen_title_switch_case_names.py)\n"
                    % tree)
            for a, b in sorted(rules.items(), key=lambda x: -len(x[0])):
                f.write("s/\\b%s\\b/%s/g\n" % (a, b))
        print("%s: %d case labels -> %s" % (tree, len(rules), os.path.relpath(out, REPO)))


if __name__ == "__main__":
    main()
