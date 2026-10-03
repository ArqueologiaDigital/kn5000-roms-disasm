#!/usr/bin/env python3
"""Name the routines of prom_b's orphaned 0xF00C4D module after the live routines they are old copies of.

QUESTION IT ANSWERS
  FINDINGS-prom_b-f00c4d-orphan-cluster.md: 0xF00CA2-0xF014ED is compiler output that nothing
  reaches, whose 24-bit calls land on prom_a addresses of an OLDER build (N2), so its routines stay
  `sub_`.  Decoding both sides from the ROM bytes (kernel_structural_match's decoder) shows most of
  them are the live SOUND EDIT PITCH screens' key handlers at 0xF0A000+, instruction for
  instruction with EVERY operand equal except the targets of jr / jrl / jp / call / calr / djnz --
  and at one constant distance: live = old + 0x9420 (0xF00F81 -> LcdKeyRow1_SoundEditPitchTune
  0xF0A3A1, 0xF01444 -> LcdKeyRow1_SoundEditPitchLfo 0xF0A864, ...).  The constant pairs routines
  that are identical to SEVERAL live ones (the eight LFO soft keys) with the right one.
  So each old routine whose partner at +0x9420 is a named routine and whose instructions match it
  that way is OldCopy_<live name> -- the tree's spelling for an older build's copy (OldCopy_ at
  0xF6F000).  The module's first routines sit at another distance (the live code before them changed
  length); for those, the ONE named routine in 0xF0A000-0xF0AFFF with an identical body is the partner.
  REFUSED: no partner either way, a partner that is itself `sub_`, or any instruction
  differing in more than its branch/call target.

RUN
  python3 notes/prom_b_f00c4d_oldcopy_names.py          # the plan and the refusals
  python3 notes/prom_b_f00c4d_oldcopy_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import kernel_structural_match as K  # noqa: E402

DELTA = 0x9420
LO, HI = 0xF00CA2, 0xF014EE
BR = re.compile(r'^((?:jr|jrl|jp|call|calr|djnz)\b.*?)0x[0-9a-f]+\s*$')


def labels():
    txt = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
    out = {}
    L = txt.split("\n")
    for i, l in enumerate(L):
        m = re.match(r'^([A-Za-z_][\w$]*):', l)
        if not m or re.search(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop)\d*$', m.group(1)):
            continue
        for j in range(i, min(i + 4, len(L))):
            mm = re.search(r';\s*(F[0-9A-F]{5})\b', L[j])
            if mm and not L[j].lstrip().startswith((".long", ".byte", ".short", ".ascii", ";", ".fill", ".incbin")):
                out.setdefault(int(mm.group(1), 16), m.group(1))
                break
    return out


def body(seq):
    out = []
    for t in seq.text[:300]:
        out.append(BR.sub(r'\1#', t))
        if t.startswith("ret") and not t.startswith("reti"):
            break
    return out


def plan():
    lab = labels()
    olds = sorted(a for a, n in lab.items() if LO <= a < HI and re.match(r'^sub_F[0-9A-F]{5}$', n))
    dec = K.decode_starts("wsa1:b", [K.off_of("wsa1:b", a) for a in olds] +
                          [K.off_of("wsa1:b", a + DELTA) for a in olds], 512)
    lives = sorted(a for a, n in lab.items() if 0xF0A000 <= a < 0xF0B000 and not re.match(r'^sub_F[0-9A-F]{5}$', n))
    ldec = K.decode_starts("wsa1:b", [K.off_of("wsa1:b", a) for a in lives], 512)
    lbody = {a: body(ldec[K.off_of("wsa1:b", a)]) for a in lives if K.off_of("wsa1:b", a) in ldec}
    rows, refused = [], []
    for a in olds:
        live = lab.get(a + DELTA)
        partner = a + DELTA
        if live is None:
            # the module's first routines sit at another distance: accept the ONE named live routine in
            # 0xF0A000-0xF0AFFF whose body is identical, and refuse when there are none or several
            bo = body(dec[K.off_of("wsa1:b", a)])
            same = [x for x in lives if lbody.get(x) == bo]
            if len(same) != 1:
                refused.append((lab[a], "no routine label at 0x%06X, and %d identical named routines in 0xF0A000-0xF0AFFF" % (a + DELTA, len(same))))
                continue
            partner, live = same[0], lab[same[0]]
            dec[K.off_of("wsa1:b", partner)] = ldec[K.off_of("wsa1:b", partner)]
        if re.match(r'^sub_F[0-9A-F]{5}$', live):
            refused.append((lab[a], "its partner 0x%06X is still %s" % (a + DELTA, live)))
            continue
        bo, bl = body(dec[K.off_of("wsa1:b", a)]), body(dec[K.off_of("wsa1:b", partner)])
        if bo != bl:
            n = sum(1 for x, y in zip(bo, bl) if x != y) + abs(len(bo) - len(bl))
            refused.append((lab[a], "differs from %s in %d instruction(s) beyond branch targets" % (live, n)))
            continue
        new = "OldCopy_" + live
        rows.append((lab[a], new, "%s: the older build's copy of %s (0x%06X = this + 0x%X), equal to it in all %d\\n"
                     "  instructions but the targets of its branches and calls, which land on that older build's prom_a\\n"
                     "  (FINDINGS-prom_b-f00c4d-orphan-cluster.md N2; notes/prom_b_f00c4d_oldcopy_names.py)." % (new, live, partner, partner - a, len(bo))))
    return rows, refused


def main():
    rows, refused = plan()
    txt = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
    taken = set(re.findall(r'[A-Za-z_][\w$]*', txt))
    for o, n, h in rows:
        if "--args" in sys.argv:
            if n not in taken:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-11s -> %s%s" % (o, n, "  NAME TAKEN" if n in taken else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
