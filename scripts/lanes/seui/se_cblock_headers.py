#!/usr/bin/env python3
r"""GIVE EACH C SCREEN DESCRIPTOR INSIDE SeScreenData THE READER EVIDENCE ITS HEADER LACKS.

QUESTION ANSWERED
-----------------
The byte-exact C descriptors (`.incbin "includes/generated/se_*.bin"`) that
earlier lanes put inside the sound editor's screen-data block carry a header
saying what file they were compiled from, but not what READS them -- so the
census grades them "descriptive name + header" (KNOWN-B).  The model
(se_screendata_model.py) knows, for every C block start, which record lists
begin there, which family (static / bound) and which code draws them.  This
inserts that as one or two comment lines directly above the block's label,
after the existing header lines (which are kept verbatim).

RUN
    python3 scripts/lanes/seui/se_cblock_headers.py --image v10 [--apply]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
import se_screendata_model as sm          # noqa: E402
import se_screendata_render as sr         # noqa: E402

REL = "audio/sound_editor_ui.s"
TAG = "; reader (se_screendata_model.py):"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    s = sm.symbols(a.image)
    m, gaps = sm.build(a.image, s=s)
    r = sr.Render.__new__(sr.Render)
    r.syms = s
    path = os.path.join(ROOT, a.image, "maincpu", REL)
    L = open(path, "rb").read().decode("latin-1").split("\n")
    lists_at = {}
    for (x, e), o in m.lists.items():
        lists_at.setdefault(x, []).append(o)
    n = 0
    out = []
    i = 0
    while i < len(L):
        ln = L[i]
        mm = re.match(r"^(SeScreenData_0x([0-9A-F]{4})|TuningSys_Param_01):\s*$", ln)
        j = i + 1
        while j < len(L) and L[j].strip().startswith(".set"):
            j += 1
        if mm and j < len(L) and '.incbin "includes/generated/' in L[j] and TAG not in L[i - 2]:
            # the label's address
            nm = mm.group(1)
            addr = s.get(nm)
            ls = lists_at.get(addr, [])
            if ls:
                fams = sorted({x["family"] for x in ls})
                fam = {"S": "static", "B": "bound"}
                reader = " and ".join("GraphicsRender_ProcessEntries" if f == "S" else "GraphicsRender_Start"
                                      for f in fams)
                cites = []
                for x in ls:
                    for ev in x["ev"]:
                        g = re.match(r"code ([0-9a-f]{6})", ev)
                        if g:
                            rt = sr.Render.routine(r, int(g.group(1), 16))
                            if rt not in cites:
                                cites.append(rt)
                        elif ev not in cites:
                            cites.append(re.sub(r" ([0-9a-f]{6})", lambda q: " SeScreenData_0x%04X" % (int(q.group(1), 16) - m.lo), ev))
                out.append("%s %s record list(s) from here, read by %s;" % (
                    TAG, "/".join(fam[f] for f in fams), reader))
                out.append("; evidence: " + ", ".join(cites[:4]) + (" (+%d more)" % (len(cites) - 4) if len(cites) > 4 else ""))
                n += 1
        out.append(ln)
        i += 1
    print("%s: %d C-block labels get a reader header" % (a.image, n))
    if a.apply and n:
        open(path, "wb").write("\n".join(out).encode("latin-1"))


if __name__ == "__main__":
    main()
