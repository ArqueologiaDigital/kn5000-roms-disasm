#!/usr/bin/env python3
r"""Turn the drawing primitives' "*_ParamBlock" byte rows into the routines they are.

QUESTION ANSWERED
    ui/drawing_primitives.s holds nine 21-24 byte `.byte` blocks named
    <Prim>_ParamBlock (DrawLine, DrawBox, DrawFrame, MovePixels, DrawBitmap,
    DrawBitmapFast, DrawIcons, DrawFrameSP, DrawBitmapFile).  They are code:
    <Prim>_DeferredPath allocates a draw-queue entry (DrawQueue_Alloc), stores
    `lda xbc,(<Prim>_ParamBlock)` at entry +0 and the call's parameters at +4..,
    and DrawTask_FuncDispatch (ui/ui_widget_defs.s) later runs
    `ld xhl,(xiz); ld xwa,xiz; call (xhl)` -- i.e. calls entry+0 with xwa = the
    entry.  Each block decodes as: reload the parameters from (xwa+4...),
    `cpw (0x3044E),0; ret z` (the test <Prim> makes before drawing directly),
    `ld xwa,<reg>; calr <Prim>_Impl; ret` with <Prim>_Impl the very next label.

    ui/ui_control_panel.s's UI_DialRangeData (12 bytes) is likewise code: two
    3-instruction setters `ld (RAM),a; ret` that nothing calls or points at.

    --check decodes every block in v10/v9/v7 and asserts that shape; --apply
    writes the instructions (tree spelling), renames the labels with
    scripts/renaming/rename_draw_queued_exec.sed, and adds a header.

RUN
    python3 scripts/converters/convert_draw_queued_exec.py --check
    python3 scripts/converters/convert_draw_queued_exec.py --apply v10 v9 v7
    make gate
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import v10_reframe as R  # noqa: E402  (disassemble(): image independent)

B = 0xE00000
PRIMS = ["DrawLine", "DrawBox", "DrawFrame", "MovePixels", "DrawBitmap", "DrawBitmapFast",
         "DrawIcons", "DrawFrameSP", "DrawBitmapFile"]
SED = os.path.join(ROOT, "scripts/renaming/rename_draw_queued_exec.sed")


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def syms(v):
    out = subprocess.run([os.path.join(R.LLVM, "llvm-nm"), "--defined-only",
                          os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    by = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            by[p[2]] = int(p[0], 16)
    return by


def spell(text):
    t = text.strip()
    t = re.sub(r"\((x\w+)\+(\d+)\)", r"(\1 + \2)", t)
    m = re.match(r"cpw_da\s+\((\d+)\),\s*0$", t)
    if m:
        return "cpw (0x%06x:24), 0" % int(m.group(1))
    m = re.match(r"stb_da\s+\((\d+)\),\s*a$", t)
    if m:
        return "ld (0x%06x:24), a" % int(m.group(1))
    return t


def decode(d, a, n):
    out, off = [], a
    for k, t in R.disassemble(d[a - B:a - B + n]):
        out.append((off, k, t.strip()))
        off += k
    return out


def plan(v):
    d, S = rom(v), syms(v)
    res = {}
    for p in PRIMS:
        lab, impl = p + "_ParamBlock", p + "_Impl"
        a, e = S[lab], S[impl]
        ins = decode(d, a, e - a)
        texts = [t for _, _, t in ins]
        assert not any(t.startswith(".byte") for t in texts), (v, p, texts)
        assert texts[-1] == "ret" and texts[-2] == "calr 1" and texts[-4] == "ret z", (v, p, texts)
        assert re.match(r"cpw_da \(\d+\), 0$", texts[-5]), (v, p, texts)
        assert ins[-2][0] + 3 + 1 == e, "calr target is not %s" % impl
        body = [spell(t) for t in texts[:-2]] + ["calr %s" % impl, "ret"]
        res[lab] = (a, body, int(re.search(r"\((\d+)\)", texts[-5]).group(1)))
    a = S["UI_DialRangeData"]
    ins = decode(d, a, 12)
    texts = [t for _, _, t in ins]
    assert len(texts) == 4 and texts[1] == texts[3] == "ret" and all(t.startswith("stb_da") for t in texts[::2]), texts
    res["UI_DialRangeData"] = (a, [spell(t) for t in texts],
                               [int(re.search(r"\((\d+)\)", t).group(1)) for t in texts[::2]])
    return res


def check():
    for v in ("v10", "v9", "v7"):
        P = plan(v)
        for lab, (a, body, extra) in P.items():
            print("%s %-28s 0x%06X  %s" % (v, lab, a, " / ".join(body)))
    return 0


def header(prim, ram):
    return [
        "; Executor of a queued %s: %s_DeferredPath stores this address at +0 of a" % (prim, prim),
        "; DrawQueue_Alloc entry and the call's parameters at +4.., and DrawTask_FuncDispatch",
        "; (ui/ui_widget_defs.s) runs `ld xhl,(xiz); ld xwa,xiz; call (xhl)`.  It reloads the",
        "; parameters from (xwa + 4..), returns when the word at RAM 0x%05X is 0 (the test" % ram,
        "; %s makes before drawing directly) and otherwise calls %s_Impl." % (prim, prim),
        "; (Formerly %s_ParamBlock, held as `.byte`.)" % prim]


def apply(v):
    P = plan(v)
    for rel in ("ui/drawing_primitives.s", "ui/ui_control_panel.s"):
        path = os.path.join(ROOT, v, "maincpu", rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        out, k = [], 0
        while k < len(lines):
            m = re.match(r"^([A-Za-z_]\w*):\s*$", lines[k])
            if m and m.group(1) in P:
                lab = m.group(1)
                j = k + 1
                while j < len(lines) and lines[j].strip().startswith(".byte"):
                    assert ";" not in lines[j], "comment on a replaced line"
                    j += 1
                a, body, extra = P[lab]
                if lab == "UI_DialRangeData":
                    out += ["; Two setters, `ld (RAM),a; ret`, for RAM 0x%05X and 0x%05X.  Nothing" % tuple(extra),
                            "; calls or points at either: no 24- or 32-bit value in the ROM and no",
                            "; jr/jrl/calr displacement reaches 0x%06X or 0x%06X.  (Formerly UI_DialRangeData," % (a, a + 6),
                            "; held as `.byte`; it is not data.)",
                            "UI_StoreA_Ram%05X:" % extra[0], "\t" + body[0], "\t" + body[1],
                            "UI_StoreA_Ram%05X:" % extra[1], "\t" + body[2], "\t" + body[3]]
                else:
                    prim = lab[:-len("_ParamBlock")]
                    out += header(prim, extra) + [lines[k]] + ["\t" + b for b in body]
                k = j
                continue
            out.append(lines[k])
            k += 1
        open(path, "wb").write("\n".join(out).encode("latin-1"))
    dp = os.path.join(ROOT, v, "maincpu/ui/drawing_primitives.s")
    subprocess.run(["sed", "-i", "-f", SED, dp], check=True)
    # the sed also renamed the old name inside the "(Formerly ...)" notes: undo that there
    t = open(dp, "rb").read().decode("latin-1")
    t = re.sub(r"\(Formerly (\w+)_QueuedExec, held", r"(Formerly \1_ParamBlock, held", t)
    open(dp, "wb").write(t.encode("latin-1"))
    print("%s: converted" % v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if a.apply:
        for v in a.apply:
            apply(v)
        return 0
    return check()


if __name__ == "__main__":
    sys.exit(main())
