#!/usr/bin/env python3
r"""MainPmanCtrl_DispatchTable is not a table: it is MainPmanControl's six switch cases.

QUESTION ANSWERED
    ui/ui_control_panel.s: MainPmanControl maps event 0x1E00057..0x1E0005C to
    0..5, loads a 16-bit offset from six words at 0xEA99F8 (spelled
    `DiskWarning_ConfirmStrings_0xD4C`, a positional name in another file;
    the words are 0, 17, 34, 100, 125, 150 in v10, v9 and v7), then
    `lda xix,(MainPmanCtrl_DispatchTable); jp t,xix+wa`.  So the 228 bytes
    under that label are the six case bodies, held as `.byte` (with a phantom
    `.long OscScope_UpdateDisplay` and `addr24 Malloc` pieces) in v10/v9 and
    as a romslice `.incbin` in v7.

    --check decodes the bytes of all three versions, asserts that every case
    offset is an instruction boundary of the linear sweep, that no byte is
    undecodable, and that every emitted text assembles to exactly the ROM
    bytes.  --apply replaces the lines between the label and
    MainPmanCtrl_HandleA0 with the instructions, a case label at each offset
    (MainPmanCtrl_Case0 .. _Case5; the old name stays on case 0 as the jump
    base the code names), and absolute call targets spelled with the
    version's ELF label at that address.  Relative branches stay numeric for
    scripts/converters/symbolize_numeric_branches.py.

RUN
    python3 scripts/converters/convert_mainpman_switch.py --check
    python3 scripts/converters/convert_mainpman_switch.py --apply v10 v9 v7
    make gate
"""
import argparse
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import v10_reframe as R  # noqa: E402
import v10_reframe_code_runs as RC  # noqa: E402  (encode_map)

B = 0xE00000
OFFS_AT = 0xEA99F8
LAB, END = "MainPmanCtrl_DispatchTable", "MainPmanCtrl_HandleA0"


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def syms(v):
    out = subprocess.run([os.path.join(R.LLVM, "llvm-nm"), "--defined-only",
                          os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    by_name, by_addr = {}, {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            a = int(p[0], 16)
            by_name[p[2]] = a
            if not re.search(r"_0x[0-9A-Fa-f]+$", p[2]) and not p[2].startswith((".L", "__")):
                by_addr.setdefault(a, []).append(p[2])
    return by_name, by_addr


def plan(v):
    d = rom(v)
    names, at = syms(v)
    a, e = names[LAB], names[END]
    offs = struct.unpack_from("<6h", d, OFFS_AT - B)
    lines, off = [], a
    for n, raw in R.disassemble(d[a - B:e - B]):
        raw = raw.strip()
        assert not raw.startswith(".byte"), (v, hex(off), raw)
        t = raw
        m = re.match(r"(call|jp)\s+(\d+)$", raw)
        if m and int(m.group(2)) in at:
            t = "%s %s" % (m.group(1), sorted(at[int(m.group(2))])[0])
        lines.append((off, n, t, raw))
        off += n
    assert off == e
    starts = {l[0] for l in lines}
    emap, bad = RC.encode_map([l[3] for l in lines])
    assert not bad, (v, bad)
    assert b"".join(emap[l[3]] for l in lines) == d[a - B:e - B], v
    for k, o in enumerate(offs):
        assert a + o in starts, (v, k, o)
    return a, e, offs, lines, d


def check():
    for v in ("v10", "v9", "v7"):
        a, e, offs, lines, d = plan(v)
        print("%s: 0x%06X-0x%06X, %d instructions re-encode to the ROM bytes, case offsets %s"
              % (v, a, e, len(lines), list(offs)))
    return 0


def apply(v):
    a, e, offs, lines, d = plan(v)
    case_at = {a + o: k for k, o in enumerate(offs)}
    out = ["; MainPmanControl's six switch cases, not a table: it takes event - 0x1E00057 as",
           "; the case, `ld wa,(<offset word>)` from the six s16 at 0x%06X (0, 17, 34, 100," % OFFS_AT,
           "; 125, 150; spelled DiskWarning_ConfirmStrings_0xD4C above), then `lda xix,(<this>);",
           "; jp t,xix+wa`.  Held as `.byte` (v10/v9) or a romslice `.incbin` (v7) before",
           "; scripts/converters/convert_mainpman_switch.py; each case offset is an",
           "; instruction boundary and every instruction re-encodes to the ROM bytes.",
           "%s:" % LAB]
    for o, n, t, raw in lines:
        if o in case_at:
            out.append("MainPmanCtrl_Case%d:" % case_at[o])
        out.append("\t" + t)
    path = os.path.join(ROOT, v, "maincpu/ui/ui_control_panel.s")
    src = open(path, "rb").read().decode("latin-1").split("\n")
    i = src.index("%s:" % LAB)
    j = src.index("%s:" % END)
    old = src[i + 1:j]
    body = [x for x in old if x.strip()]
    assert all(x.strip().startswith((".byte", ".long", "addr24", ".incbin")) for x in body), body
    assert not any(";" in x for x in body)
    while i > 0 and src[i - 1].startswith(";"):
        raise SystemExit("unexpected comment above %s" % LAB)
    src[i:j] = out + [""]
    open(path, "wb").write("\n".join(src).encode("latin-1"))
    print("%s: %d instructions, 6 case labels" % (v, len(lines)))


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
