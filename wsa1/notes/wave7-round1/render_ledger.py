#!/usr/bin/env python3
"""Render wave 7 round 1's ledger from the run's raw return value.

QUESTION IT ANSWERS
    "What did each recon lane claim, what did its skeptic reproduce, and what must
     be corrected before any of it is applied?"

WHY IT IS A SCRIPT AND NOT A HAND-WRITTEN TABLE
    The same reason WAVE7-BRIEFING.md's frontier table is generated: a status table
    maintained by hand goes stale, and this project has the receipts. README.md in
    this directory is OUTPUT. Edit round1-results.json (or re-run the wave) and
    regenerate; do not hand-edit the markdown.

RUN
    python3 notes/wave7-round1/render_ledger.py          # rewrites README.md
    python3 notes/wave7-round1/render_ledger.py --stdout # print instead
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SEV = {"fatal": 0, "serious": 1, "minor": 2}


def render(r):
    out = []
    W = out.append
    W("# Wave 7, round 1 — the recon ledger\n")
    W("Ten read-only lanes, each followed by an independent skeptic. **Nothing here has been applied to\n"
      "a `.s` file or a findings document yet**, and several entries must be corrected before any of it\n"
      "is. This file is generated from `round1-results.json`, which is the run's raw return value.\n")
    W("Regenerate with `python3 notes/wave7-round1/render_ledger.py`.\n")
    W("**What has been DONE about these is tracked separately, in `APPLIED.md`.**\n")
    W("## Status at a glance\n")
    W("| lane | target | verdict | fatal | serious | minor |")
    W("|---|---|---|---:|---:|---:|")
    for L in r["lanes"]:
        probs = L.get("problems") or []
        c = {k: sum(1 for p in probs if p["severity"] == k) for k in SEV}
        ref = L["refuted"]
        v = "**REFUTED**" if ref is True else ("not refuted" if ref is False else "*unverified*")
        W("| %s | %s | %s | %d | %d | %d |"
          % (L["lane"], L["label"].replace("recon:", ""), v, c["fatal"], c["serious"], c["minor"]))
    W("")
    W("`unverified` means the lane produced a dossier but its skeptic died on an API error, or the lane\n"
      "itself died. **An unverified dossier is not evidence.** In this project's history every documented\n"
      "error was gate-clean and plausible, so a dossier nobody attacked has the status of a hypothesis.\n")
    W("\n## The corrections owed, per lane\n")
    W("These are what the skeptics reproduced against the ROM. Each must be fixed in the lane's committed\n"
      "script and in any prose derived from it **before** the span is converted.\n")
    for L in r["lanes"]:
        probs = sorted(L.get("problems") or [], key=lambda p: SEV[p["severity"]])
        if not probs and L["refuted"] == "verifier-died":
            W("\n### %s — %s\n" % (L["lane"], L["label"]))
            W("⚠ **Unverified.** %s\n"
              % ("The lane died before returning a dossier." if not L.get("dossier")
                 else "A dossier exists but no skeptic attacked it. Treat as a hypothesis."))
            continue
        if not probs:
            continue
        W("\n### %s — %s\n" % (L["lane"], L["label"]))
        for p in probs:
            W("* **%s — %s**" % (p["severity"].upper(), " ".join(p["claim"].split())[:200]))
            W("  %s\n" % " ".join(p["problem"].split())[:900])
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    r = json.load(open(os.path.join(HERE, "round1-results.json")))
    text = render(r)
    if "--stdout" in sys.argv:
        sys.stdout.write(text)
    else:
        open(os.path.join(HERE, "README.md"), "w").write(text)
        print("wrote %s (%d lanes)" % (os.path.join(HERE, "README.md"), len(r["lanes"])))
