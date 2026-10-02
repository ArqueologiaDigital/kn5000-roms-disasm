#!/usr/bin/env python3
"""label_style_browser.py -- every style-name string and variation table of the MstStyle browser gets a label.

QUESTION THIS ANSWERS / JOB IT DOES
  The MstStyle browser tree (nakarest_objtab_map.Map.index_style_browser: 10 groups of
  {u32 style name, u32 variation table} pairs) names 250 styles.  On 2026-10-02, 143 style-name
  strings carried the lane's `NakaInst_<Words>` labels and 139 variation tables
  `StyleVar_<CamelCase>`; the other 107 / 109 had none, so the group tables pointing at them were
  `.long 0x00ECFC5C` numbers or bytes.  This labels each unlabelled one in the same convention,
  from the style's own name string ("Rhumba Espana" -> NakaInst_Rhumba_Espana, its variation
  table StyleVar_RhumbaEspana), through scripts/tools/place_labels.py.  Then run
  scripts/tools/symbolize_long_pointers.py.  A label emits no byte: `make gate-all`.

USAGE
  make all
  python3 scripts/tools/label_style_browser.py --tree v10 [--apply]
"""
import argparse
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import nakarest_objtab_map as nom             # noqa: E402
import place_labels                           # noqa: E402


def words(s):
    s = s.replace("&", " And ").replace("'", "")
    return [w for w in re.split(r'[^A-Za-z0-9]+', s) if w]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = nom.Map(a.tree)
    have = {}
    for ad, n in m.rev:
        have.setdefault(ad, []).append(n)
    taken = set(n for _, n in m.rev)
    pairs = []
    for ad, vs in m.addr.items():
        for kind, r, k in vs:
            if kind == "sbsname":
                g, i = k
                gp = m.u32(r["table"] + 8 * g + 4)
                pairs.append((ad, m.u32(gp + 8 * i + 4)))
    p = place_labels.Planner(a.tree)
    st = {}
    for sn, vt in sorted(set(pairs)):
        w = words(m.string_at(sn))
        if not w:
            continue
        for ad, nm in ((sn, "NakaInst_" + "_".join(w)), (vt, "StyleVar_" + "".join(x[:1].upper() + x[1:] for x in w))):
            if have.get(ad):
                st["has a label"] = st.get("has a label", 0) + 1
                continue
            b, k = nm, 2
            while nm in taken:
                nm, k = "%s_%d" % (b, k), k + 1
            how = p.add(ad, nm)
            if how in ("line-start", "incbin", "list"):
                taken.add(nm)
                have[ad] = [nm]
            st[how] = st.get(how, 0) + 1
    print("%s: %d styles; %s%s" % (a.tree, len(set(pairs)), st, "" if a.apply else " (dry run)"))
    if a.apply:
        p.apply()
    return 0


if __name__ == "__main__":
    sys.exit(main())
