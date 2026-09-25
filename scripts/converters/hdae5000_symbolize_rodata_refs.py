#!/usr/bin/env python3
r"""hdae5000_symbolize_rodata_refs.py -- code operands that name .rodata objects.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
After scripts/generators/gen_hdae5000_rodata.py labelled every object of the
program's .rodata (0x2E1C82-0x2E3703), the code still reached them through
numbers: `lda xde,(0x2e1c8a:24)`, `ld xbc,0x002e2922`, `ld xwa,(0x2e2922)`,
`pushw 0x002e / pushw 0x2eac`.  This tool rewrites every such operand whose
value is the address of a label in that block to the label (the encodings are
unchanged: the assembler resolves the symbol to the same number), and for the
pointer pushed as two 16-bit halves -- which has no relocation form in this
backend -- appends "; low half of <label>" to the low half.

Guards: the value must equal a label's address exactly (an address inside an
object is left alone and reported); the tree must re-link byte-identical
(scripts/analysis/hdae5000_line_map.py refuses otherwise).

RUN (repo root, after a build of the hdae5000 image)
    python3 scripts/converters/hdae5000_symbolize_rodata_refs.py            # counts
    python3 scripts/converters/hdae5000_symbolize_rodata_refs.py --apply
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

LO, HI = 0x2E1C82, 0x2E3704
LABEL = re.compile(r"^([.A-Za-z_][\w.$]*):")
FORMS = [
    re.compile(r"^(?P<pre>\s*lda\s+x\w+,\s*\()(?P<num>0x[0-9a-fA-F]+)(?P<post>:24\).*)$"),
    re.compile(r"^(?P<pre>\s*ld\s+x\w+,\s*)(?P<num>0x[0-9a-fA-F]+)(?P<post>\s*(;.*)?)$"),
    re.compile(r"^(?P<pre>\s*ld\s+x?\w+,\s*\()(?P<num>0x[0-9a-fA-F]+)(?P<post>(:24)?\).*)$"),
    re.compile(r"^(?P<pre>\s*add\s+x\w+,\s*)(?P<num>0x[0-9a-fA-F]+)(?P<post>\s*(;.*)?)$"),
]


def main(apply):
    rows, rom = hlm.build_map()
    labels = {}
    for a, rel, n, t in rows:
        m = LABEL.match(t)
        if m and rel == "hdae5000_data_tables.s" and LO <= a < HI and not m.group(1).startswith("."):
            labels.setdefault(a, m.group(1))
    files = {}
    edits = collections.Counter()
    inside = []
    hi_line = None
    for a, rel, n, t in rows:
        if rel in ("hdae5000_data_tables.s", "hdae5000_init_data.s") or a >= 0x29BAFC:
            continue
        body = t
        m = LABEL.match(body)
        if m:
            body = body[m.end():]
            if not body.strip():
                continue
        code = body.split(";")[0].strip()
        mm = re.match(r"pushw\s+0x([0-9a-fA-F]{4})$", code)
        if mm:
            v = int(mm.group(1), 16)
            if hi_line is not None:
                full = 0x2E0000 | v
                if LO <= full < HI:
                    if full in labels:
                        L = files.setdefault(rel, open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n"))
                        if "low half of" not in L[n - 1]:
                            L[n - 1] = L[n - 1].rstrip() + "\t\t; low half of " + labels[full]
                            edits["pushw pair"] += 1
                    else:
                        inside.append((a, rel, n, full))
                hi_line = None
                continue
            hi_line = n if v == 0x2E else None
            continue
        hi_line = None
        L = None
        for rx in FORMS:
            mm = rx.match(t if not m else t[m.end():])
            if not mm:
                continue
            v = int(mm.group("num"), 16)
            if not (LO <= v < HI):
                break
            if v not in labels:
                inside.append((a, rel, n, v))
                break
            L = files.setdefault(rel, open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n"))
            line = L[n - 1]
            old = mm.group("num")
            idx = line.find(old)
            if idx < 0:
                break
            L[n - 1] = line[:idx] + labels[v] + line[idx + len(old):]
            edits[rx.pattern.split("\\s")[1] if False else code.split()[0]] += 1
            break
    print("operands rewritten:", dict(edits), "total", sum(edits.values()))
    print("addresses inside an object (left numeric): %d" % len(inside))
    for a, rel, n, v in inside:
        print("  %06X %s:%d -> 0x%06X" % (a, rel, n, v))
    if not apply:
        return
    for rel, L in files.items():
        open(os.path.join(hlm.HDAE, rel), "w", encoding="latin-1").write("\n".join(L))
    hlm.build_map()
    print("applied; relinked mirror byte-identical")


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
