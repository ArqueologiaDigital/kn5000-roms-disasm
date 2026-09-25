#!/usr/bin/env python3
r"""scoop_rename_unref.py -- rename the `Unref_<ADDR>_*` placeholder labels that
turned out to HAVE a reader (it loaded them as a bare number, invisible until
scoop_symbolize_imm.py made the operand symbolic), together with the
`<that label>_Target<k>` labels derived from them.

QUESTION ANSWERED
-----------------
"Which labels in display/scoop_display.s still claim, by their name, that
nothing reads them, although something now visibly does?"  A placeholder
name that states a falsehood is worse than an address; each is renamed after
its reader (`<ReaderRoutine>_<Kind>`, as scoop_auto_headers.py names), in code
and in the comments this lane generated, in this file only.  The image is
rebuilt and compared.

RUN
    python3 scripts/analysis/scoop_data_headers.py --image v7 --file F --out DRAFT.json
    python3 scripts/converters/scoop_rename_unref.py --image v7 --draft DRAFT.json
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402

KIND = {"handler dispatch table": "DispatchTbl", "pointer table": "PtrTbl",
        "LCD text": "Text", "byte data": "Tbl", "UIRender display list": "DisplayList"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--draft", required=True)
    a = ap.parse_args()
    draft = json.load(open(a.draft))
    rel = draft[0]["file"]
    p = os.path.join(R.ROOT, rel)
    backup = open(p, "rb").read()
    text = backup.decode("latin-1")
    existing = set(re.findall(r'^([A-Za-z_][\w.$]*):', text, re.M))
    ren = {}
    for e in draft:
        un = [x for x in e["names"] if re.match(r'^Unref_[0-9A-F]{6}_', x)]
        if not un or not e["sites"]:
            continue
        rn = next((s["routine"] for s in e["sites"] if s.get("routine")
                   and not s["routine"].startswith("Unref_")), None)
        if not rn:
            continue
        base = "%s_%s" % (rn, KIND.get(e["kind"], "Tbl"))
        nm, k = base, 2
        while nm in existing or nm in ren.values():
            nm = "%s%d" % (base, k)
            k += 1
        ren[un[0]] = nm
    # derived target labels
    for old, new in list(ren.items()):
        for lab in existing:
            if lab.startswith(old + "_Target"):
                ren[lab] = new + lab[len(old):]
    if not ren:
        print("nothing to rename")
        return
    pat = re.compile(r'(?<![\w.$])(%s)(?![\w.$])' % "|".join(re.escape(o) for o in
                                                          sorted(ren, key=len, reverse=True)))
    text = pat.sub(lambda m: ren[m.group(1)], text)
    open(p, "wb").write(text.encode("latin-1"))
    ok, _, data = R.build(a.image)
    if not ok or data != R.rom(a.image):
        open(p, "wb").write(backup)
        raise SystemExit("REJECTED: restored")
    for o, n in sorted(ren.items()):
        print("  %s -> %s" % (o, n))
    print("%s: %d labels renamed; image byte-identical" % (rel, len(ren)))


if __name__ == "__main__":
    main()
