#!/usr/bin/env python3
r"""scoop_symbolize_rel.py -- make the remaining NUMERIC relative branches in
lane scoop's files symbolic, where the site is code the control-flow plan
verified and the target is an instruction line of these files.

QUESTION ANSWERED
-----------------
"Which `jr/jrl/calr/djnz <number>` operands are still numeric in
display/*.s, and where do they go?"  The shared symboliser refuses sites whose
neighbourhood looks absurd (R3) or whose linear unidasm decode disagrees
(R5) -- guards against misframed code.  After scoop_reframe.py the framing of
these files is flow-verified, so each site is re-checked directly: its bytes
must decode (unidasm, on its own) as a branch of the same kind whose target
lands on the first byte of a source line.  The target gets the label already
there, else a new one named after the enclosing routine (_Skip<n> forward,
_Loop<n> backward, as the shared symboliser names them; `jr cc, 0`, a branch
to the very next instruction, gets _Next<n>).  The image is rebuilt and
compared.

RUN
    python3 scripts/converters/scoop_symbolize_rel.py --image v10
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "analysis"))
import scoop_data_headers as H  # noqa: E402

FILES = ["display/scoop_display.s", "display/scoop_editor_data.s", "display/graphics_text_vga.s"]
BR = re.compile(r'^(\s*(?:[\w.$]+:\s*)?)(jr|jrl|calr|djnz)(\s+)((?:[a-z]+\s*,\s*)?(?:x?[a-z]{1,3}\s*,\s*)?)(-?\d+)(\s*)$', re.I)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    a = ap.parse_args()
    img = a.image
    rels = ["%s/maincpu/%s" % (img, f) for f in FILES]
    amap, elf = R.linemap(img, rels)
    a2n, n2a = R.symbols(elf)
    rb = R.rom(img)
    texts = {r: open(os.path.join(R.ROOT, r), encoding="latin-1").read().split("\n") for r in rels}
    starts = {}
    for r in rels:
        ext = R.line_extents(amap[r])
        for i, x in enumerate(amap[r][:len(texts[r])]):
            if x is not None and ext[i] and x not in starts:
                starts[x] = (r, i)
    existing = set(n2a)
    newlabels = {}          # addr -> name
    edits = []              # (rel, line, new text)
    counters = {}
    for r in rels:
        L, addrs = texts[r], amap[r]
        ext = R.line_extents(addrs)
        for i, ln in enumerate(L):
            code, com = R.strip_comment(ln)
            m = BR.match(code)
            if not m or addrs[i] is None:
                continue
            site, n = addrs[i], ext[i]
            u = R.unidasm(img, site, n)
            if not u or u[0][1] != n or u[0][2].split()[0].lower() != m.group(2).lower():
                continue
            tgt = site + n + int(m.group(5))
            if R.uni_target(u[0][2]) != tgt:
                continue
            names = [x for x in a2n.get(tgt, []) if not x.startswith(("Zsr_", "__drc_", ".L"))
                     and not re.search(r'_0x[0-9A-Fa-f]+$', x)]
            if names:
                nm = sorted(names, key=len)[0]
            elif tgt in newlabels:
                nm = newlabels[tgt]
            elif tgt in starts and starts[tgt][0] in rels:
                tr, ti = starts[tgt]
                rn, _ = H.routine_of(texts[tr], ti, n2a)
                role = "Next" if tgt == site + n else ("Skip" if tgt > site else "Loop")
                base = "%s_%s" % (rn or "Code", role)
                k = counters.get(base, 1)
                nm = base if k == 1 and base not in existing else "%s%d" % (base, max(k, 2))
                while nm in existing:
                    k += 1
                    nm = "%s%d" % (base, k)
                counters[base] = k + 1
                existing.add(nm)
                newlabels[tgt] = nm
            else:
                continue
            edits.append((r, i, m.group(1) + m.group(2) + m.group(3) + m.group(4) + nm + m.group(6) + com))
    backup = {r: open(os.path.join(R.ROOT, r), "rb").read() for r in rels}
    for r, i, t in edits:
        texts[r][i] = t
    # insert new labels (bottom-up per file)
    ins = {}
    for ad, nm in newlabels.items():
        r, i = starts[ad]
        ins.setdefault(r, []).append((i, nm))
    for r, lst in ins.items():
        for i, nm in sorted(lst, reverse=True):
            texts[r].insert(i, nm + ":")
    for r in rels:
        open(os.path.join(R.ROOT, r), "wb").write("\n".join(texts[r]).encode("latin-1"))
    ok, _, data = R.build(img)
    if not ok or data != rb:
        for r, t in backup.items():
            open(os.path.join(R.ROOT, r), "wb").write(t)
        raise SystemExit("REJECTED: restored" + ("" if ok else "\n" + data[-1500:]))
    print("%s: %d numeric branches made symbolic, %d labels added; image byte-identical"
          % (img, len(edits), len(newlabels)))


if __name__ == "__main__":
    main()
