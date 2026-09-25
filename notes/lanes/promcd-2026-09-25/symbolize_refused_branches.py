#!/usr/bin/env python3
r"""Convert the ten prom_c branches the symboliser's R3/R6 guards refused, after review.

QUESTION THIS ANSWERS
    symbolize_numeric_branches.py refuses a branch when the ROM AROUND it looks
    like a pointer table (R6) or holds "absurd" instructions (R3).  In prom_c
    that fired on ten real instructions, each checked by eye on 2026-09-25:
      * R6 x4 (tone_db_module.s): the `jrl` that closes a computed-goto switch,
        sitting immediately after its own `.long` case table -- the table is
        what R6 saw;
      * R3 x6: calls/jumps in note_engine.s, link_interrupts.s and
        dev10c_dev104_drivers.s whose neighbourhood holds the 5 x `nop`
        device-settle delays the marker census counts as absurd.
    Each target is an instruction boundary (the `; ADDR` comment of a code line
    names it); an existing label there is reused, else `<routine>__<ADDR>` is
    inserted (house style).  The byte gate certifies every one: a wrong label
    changes the displacement or the absolute address and the image goes red.

RUN
    python3 notes/lanes/promcd-2026-09-25/symbolize_refused_branches.py [--apply]; make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
PC = os.path.join(ROOT, "wsa1", "prom_c")
# (source file, source line as the symboliser's --report of 2026-09-25 gives it, source addr, target)
SITES = [("tone_db/tone_db_module.s", 11715, 0xFBE0D1, 0xFBDFE6), ("tone_db/tone_db_module.s", 13403, 0xFBF1A0, 0xFBF0B5),
         ("tone_db/tone_db_module.s", 13918, 0xFBF696, 0xFBF5B7), ("tone_db/tone_db_module.s", 14773, 0xFBFF3A, 0xFBFE5B),
         ("link/link_interrupts.s", 333, 0xF99D3B, 0xF99E56), ("voice/note_engine.s", 5507, 0xFB391C, 0xFC4C85),
         ("voice/note_engine.s", 5647, 0xFB3A67, 0xFC4C85), ("voice/note_engine.s", 5739, 0xFB3B44, 0xFAB818),
         ("voice/note_engine.s", 5767, 0xFB3B85, 0xFC4C85), ("devices/dev10c_dev104_drivers.s", 4263, 0xFB821E, 0xFB7E13)]
STRUCT = re.compile(r"__|_(JumpTable|Data)_[0-9A-F]{6}$|_(Loop|Join|Skip|Sub|Return|Epilogue|Entry|Helper)\d*$")
LABEL = re.compile(r"^([A-Za-z_.$][\w.$@]*):")
NUM = re.compile(r"\(0x0*[0-9A-F]{6}\s*-\s*0x0*[0-9A-F]{6}\)|-?0x[0-9A-Fa-f]+|\b\d+\b")


def files():
    out = {}
    for dp, _, fn in os.walk(PC):
        for f in fn:
            if f.endswith(".s"):
                p = os.path.join(dp, f)
                out[os.path.relpath(p, PC)] = open(p, "rb").read().decode("latin-1").split("\n")
    return out


def find(F, addr, want_code=True):
    tag = re.compile(r";\s+%06X\b" % addr)
    for rel, L in F.items():
        for i, ln in enumerate(L):
            if tag.search(ln) and ln.strip() and not ln.strip().startswith(";"):
                return rel, i
    raise AssertionError("no line for 0x%06X" % addr)


def main():
    F = files()
    inserts, edits = {}, {}
    for src_rel, src_line, src, tgt in SITES:
        rel, i = find(F, tgt)
        L = F[rel]
        lab = None
        j = i - 1
        while j >= 0 and LABEL.match(L[j]):
            lab = LABEL.match(L[j]).group(1)
            j -= 1
        if lab is None:
            k = i
            while k >= 0:
                m = LABEL.match(L[k])
                if m and not STRUCT.search(m.group(1)):
                    break
                k -= 1
            lab = "%s__%06X" % (m.group(1), tgt)
            inserts[(rel, i)] = lab
        srel, si = src_rel, src_line - 1
        assert "%06X" % src in F[srel][si].upper() or "(0X00%06X" % tgt in F[srel][si].upper() or \
            "0X%06X" % tgt in F[srel][si].upper() or "-0X" in F[srel][si].upper(), F[srel][si]
        code, sep, com = F[srel][si].partition(";")
        assert len(NUM.findall(code.split(None, 1)[1] if len(code.split(None, 1)) > 1 else "")) >= 1, code
        mn = code.split()[0]
        ops = code[code.index(mn) + len(mn):]
        m = list(NUM.finditer(ops))[-1]
        new_ops = ops[:m.start()] + lab + ops[m.end():]
        edits[(srel, si)] = code[:code.index(mn) + len(mn)] + new_ops + sep + com
        print("  0x%06X -> %-44s %s" % (src, lab, edits[(srel, si)].strip()[:60]))
    if "--apply" in sys.argv:
        touched = {r for r, _ in inserts} | {r for r, _ in edits}
        for rel in touched:
            out = []
            for i, ln in enumerate(F[rel]):
                if (rel, i) in inserts:
                    out.append(inserts[(rel, i)] + ":")
                out.append(edits.get((rel, i), ln))
            data = "\n".join(out).encode("latin-1")
            open(os.path.join(PC, rel), "wb").write(data)
        print("applied: %d sites, %d new labels" % (len(edits), len(inserts)))


if __name__ == "__main__":
    main()
