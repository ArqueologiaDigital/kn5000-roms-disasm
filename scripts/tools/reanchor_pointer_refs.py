#!/usr/bin/env python3
r"""Re-anchor `.long SYM [+ N]` pointer operands whose built value no longer equals the ROM.

QUESTION / JOB
    When two lanes merge, lane A may write `.long Foo + 23` against Foo's address on
    its branch while lane B (merged first) MOVES the label Foo -- e.g. the v7 +0x41A
    drift correction.  Git sees no conflict; the byte gate sees wrong pointer bytes.
    Since the ROM value is the truth, each wrong operand is rewritten against the label
    that now sits AT the target (`.long L`) or, failing that, the nearest real label
    at or below it (`.long L + d`), within --max-delta bytes.  Only `.long`/`.4byte`
    lines whose emitted bytes differ from the ROM are touched; every other line is
    left alone.  The byte gate re-checks the result.

RUN (after a merge whose gate reports wrong bytes; the image must LINK):
    python3 scripts/tools/reanchor_pointer_refs.py --image v7 [--max-delta 0x400] [--apply]
Writes nothing without --apply.  Prints each rewrite as old -> new.
"""
import argparse, bisect, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters")); sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import symbolize_numeric_branches as S
import data_range_census as drc

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--image", required=True)
    ap.add_argument("--max-delta", default="0x400"); ap.add_argument("--apply", action="store_true")
    a = ap.parse_args(); img = S.image_by_key(a.image); maxd = int(a.max_delta, 0)
    srcroot = os.path.join(ROOT, img["mirror"])
    marks, addrs, spans, rom_ok, src, macros = S.build_map(img, srcroot)
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    tmp = os.path.join(ROOT, "rebuilt_ROMs")
    elf = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}[a.image]
    built = open(os.path.join(tmp, elf + ".llvm.rom"), "rb").read()
    nm = subprocess.run([drc.NM, "--defined-only", os.path.join(tmp, elf + ".llvm.elf")], capture_output=True, text=True).stdout
    syms = {}
    for ln in nm.split("\n"):
        p = ln.split()
        if len(p) == 3 and p[1] in "tT" and not p[2].startswith((".L", "__drc_", "__amap")):
            syms.setdefault(int(p[0], 16), []).append(p[2])
    saddr = sorted(syms)
    def best(t):
        if t in syms:
            return sorted(syms[t], key=lambda n: (bool(re.search(r'_(Skip|Join|Loop|Entry)\d*$', n)), len(n)))[0], 0
        k = bisect.bisect_right(saddr, t) - 1
        if k >= 0 and t - saddr[k] <= maxd:
            return sorted(syms[saddr[k]], key=len)[0], t - saddr[k]
        return None, None
    off = drc.rom_offset_fn(img)
    edits = {}
    for (s0, e0, rel, li) in spans:
        o = off(s0)
        if o is None or rom[o:o + (e0 - s0)] == built[o:o + (e0 - s0)]:
            continue
        text = src.text(rel, li)
        code = drc.strip_comment(text)
        m = re.match(r'^(\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?\.(?:long|4byte)\s+)(.*?)\s*$', code)
        if not m:
            print("  NOT A .long LINE (left alone): %s:%d %s" % (rel, li + 1, text.strip()[:90])); continue
        ops = [x.strip() for x in m.group(2).split(",")]
        new_ops = []
        for k, op in enumerate(ops):
            po = o + 4 * k
            want = int.from_bytes(rom[po:po + 4], "little")
            have = int.from_bytes(built[po:po + 4], "little")
            if want == have:
                new_ops.append(op); continue
            name, d = best(want)
            if not name:
                print("  NO LABEL near 0x%06X for %s:%d op %r" % (want, rel, li + 1, op)); new_ops.append(op); continue
            new_ops.append(name if d == 0 else "%s + %d" % (name, d))
        new = m.group(1) + ", ".join(new_ops)
        comment = text[len(code.rstrip()):] if len(text) > len(code.rstrip()) else ""
        edits[(rel, li)] = new + comment
        print("  %s:%d\n     %s\n  -> %s" % (rel, li + 1, code.strip(), new.strip()))
    if a.apply and edits:
        for rel in sorted({r for r, _ in edits}):
            p = os.path.join(srcroot, rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for (r, li), t in edits.items():
                if r == rel:
                    L[li] = t
            open(p, "wb").write("\n".join(L).encode("latin-1"))
        print("APPLIED %d line(s)" % len(edits))

if __name__ == "__main__":
    main()
