#!/usr/bin/env python3
r"""lane_accomp_v7_rhythmrom.py -- v7 RhythmROM_LoadPattern: the routine as code,
its offset table as data.

QUESTION ANSWERED
-----------------
In v7, RhythmROM_LoadPattern (0x34 bytes of code) and the 16 x LE16 offset
table right after it (RhythmROM_LoadPattern_0x34, 32 bytes) were ONE `.byte`
run plus a few phantom instructions.  The island re-framer refuses such a run
as a whole (the decode runs into the table), so this script splits it where
v9/v10 split it: it decodes [label, label+0x34) with the re-framer's decoder
(llvm-mc, SRI fallback, native re-spelling) and REQUIRES the decode to end
exactly at +0x34 with a `jr` (the routine's tail); it types [+0x34, +0x54) as
16 x LE16, and it requires +0x54 to be RhythmROM_PatternDisp_ReadByte.  The
`ld xix, <+0x34>` operand is written as the positional symbol
RhythmROM_LoadPattern_0x34 when the decoded constant equals it.  The label
RhythmROM_PatternDisp_InitLoop that sat inside the table is dropped only if
nothing in v7 references it.  The byte gate checks the result.

RUN
    python3 scripts/converters/lane_accomp_v7_rhythmrom.py --map7 M7.json [--apply]
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import lane_reframe_islands as RF  # noqa: E402

REL = "sequencer/accompaniment_engine.s"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map7", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    mp = json.load(open(a.map7))
    rows, syms = mp["files"][REL], mp["symbols"]
    path = os.path.join(ROOT, "v7/maincpu", REL)
    L = open(path, encoding="latin-1").read().split("\n")
    for ln, ad, sz, t in rows:
        if L[ln - 1] != t:
            sys.exit("stale map")
    base = syms["RhythmROM_LoadPattern"]
    if syms.get("RhythmROM_PatternDisp_ReadByte") != base + 0x54:
        sys.exit("RhythmROM_PatternDisp_ReadByte is not at +0x54")
    rp = os.path.join(ROOT, "original_ROMs/kn5000_v7_program.rom")
    rom = open(rp, "rb").read()
    dec, bad = RF.robust_decode(rp, rom, base, 0x34)
    if bad is not None or dec[-1][0] + dec[-1][1] != base + 0x34 or not dec[-1][2].startswith("jr"):
        sys.exit("routine does not decode cleanly to a jr ending at +0x34")
    texts, _ = RF.respell([t for (_, _, t) in dec])
    if RF.assemble(texts) != rom[base - 0xE00000:base - 0xE00000 + 0x34]:
        texts = [t for (_, _, t) in dec]
    code = []
    for t in texts:
        parts = re.split(r'\s+', t.strip(), maxsplit=1)
        ops = parts[1] if len(parts) > 1 else ""
        if parts[0] == "ld" and ops.endswith(", %d" % (base + 0x34)):
            ops = ops.rsplit(",", 1)[0] + ", RhythmROM_LoadPattern_0x34"
        code.append("\t" + parts[0] + ("\t" + ops if ops else ""))
    tb = rom[base + 0x34 - 0xE00000:base + 0x54 - 0xE00000]
    words = [tb[k] | tb[k + 1] << 8 for k in range(0, 32, 2)]
    table = [
        "; RhythmROM_LoadPattern +0x34 -- 16 x LE16 byte offsets into the rhythm pattern",
        "; buffer, read by the routine above: ld l,(<var>) / and l,0xf / sla hl,1 /",
        "; ld xix, RhythmROM_LoadPattern_0x34 / ld_rrw wa,(xix+hl), then",
        "; RhythmROM_PatternDisp_ReadByte adds WA to the pattern pointer.  Typed as in",
        "; v9/v10 (lane accomp 2026-09-25, scripts/converters/lane_accomp_v7_rhythmrom.py);",
        "; before, the routine and this table were one .byte run with phantom",
        "; instructions (neg wa / pop sr / reti) in the table.",
        "\t.short " + ", ".join("0x%04x" % w for w in words[:8]),
        "\t.short " + ", ".join("0x%04x" % w for w in words[8:]),
    ]
    # lines to replace: from the first line after the label to the line before ReadByte
    lab_ln = [ln for ln, ad, sz, t in rows if t.strip() == "RhythmROM_LoadPattern:"][0]
    end_ln = [ln for ln, ad, sz, t in rows if t.strip() == "RhythmROM_PatternDisp_ReadByte:"][0]
    old = L[lab_ln:end_ln - 1]
    drop = [x for x in old if re.match(r'^[A-Za-z_]\w*:', x.strip())]
    for lab in drop:
        name = lab.strip()[:-1]
        if name != "RhythmROM_PatternDisp_InitLoop":
            sys.exit("unexpected label inside: " + name)
        for dp, _, fn in os.walk(os.path.join(ROOT, "v7/maincpu")):
            for f in fn:
                if f.endswith(".s"):
                    for x in open(os.path.join(dp, f), encoding="latin-1"):
                        c = x.split(";")[0]
                        if re.search(r'\b%s\b' % name, c) and c.strip() != name + ":":
                            sys.exit("label referenced: " + x.strip())
    # every comment is kept except the two this lane wrote into these rows in
    # 578ad7ff ("data: part of the 16 x LE16 table ... (typed in v9/v10)"),
    # which this typing replaces
    keep_comments = [x.strip() for x in old if ";" in x and "(typed in v9/v10)" not in x]
    new = code + table
    if keep_comments:
        new = ["; -- comments that sat in this range before, in order:"] + \
              ["\t" + c[c.index(";"):] for c in keep_comments] + new
    print("\n".join(new))
    if a.apply:
        L[lab_ln:end_ln - 1] = new
        tmp = path + ".tmp"
        open(tmp, "w", encoding="latin-1").write("\n".join(L))
        os.replace(tmp, path)
        print("replaced %d lines with %d" % (len(old), len(new)))


if __name__ == "__main__":
    main()
