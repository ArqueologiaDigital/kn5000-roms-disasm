#!/usr/bin/env python3
r"""v7: SPLIT THE 449-BYTE ROMSLICE THAT ENDS INSIDE THE ENVELOPE-CURVE TABLE.

QUESTION ANSWERED
-----------------
v7 audio/sound_editor_ui.s pulls 0xF0F2EF-0xF0F4B0 from
includes/romslices/v7_transplant_SeMenu_ShowConfirmDialog_Data_tail_tail_tail.bin.
se_reframe_code.py --runs refuses it, correctly: its last 4 bytes are entry 0
of the envelope-curve pointer table (v10/v9 SeEnvCurve_BitmapTable at
0xF0F4D6 = v7 0xF0F4AC), a DATA line in the v10 witness.  This splits it by
hand: [0xF0F2EF, 0xF0F4AC) is decoded with the same lock-step decoder and the
same v10 witness rule (>= 90% of comparable instructions start a v10
instruction line), and [0xF0F4AC, 0xF0F4B0) becomes `.long SeBitmap_EnvCurve6`
under a new label SeEnvCurve_BitmapTable, as in v10/v9.

RUN
    python3 scripts/lanes/seui/seui_amap.py --image v7 --out A7.json --files audio/sound_editor_ui.s
    python3 scripts/lanes/seui/seui_amap.py --image v10 --out A10.json --files audio/sound_editor_ui.s
    python3 scripts/lanes/seui/v7_curve_table_fix.py A7.json A10.json [--apply]
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import se_reframe_code as R            # noqa: E402
import se_screendata_model as sm       # noqa: E402

A, SPLIT, B = 0xF0F2EF, 0xF0F4AC, 0xF0F4B0
REL = "audio/sound_editor_ui.s"


def main():
    a7, a10 = sys.argv[1], sys.argv[2]
    r = R.Reframer("v7", REL, a7)
    rom10 = open(os.path.join(R.ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    sp = [x for x in json.load(open(a10)) if x[2] == REL]
    wl = open(os.path.join(R.ROOT, "v10/maincpu", REL), encoding="latin-1").read().split("\n")

    def insn(li):
        c = re.sub(r"^[\w.$]+:\s*", "", wl[li].split(";")[0].strip())
        return bool(c) and not c.startswith(".") and not R.ABS.match(c.lower())
    starts10 = {x[0] for x in sp if insn(x[3])}
    dec = r.lockstep(A, SPLIT)
    end = dec[-1][0] + dec[-1][1]
    assert end == SPLIT, "decode does not end at the table (%06x)" % end
    delta = 0x2A
    ag = cp = 0
    for (p, k, t) in dec:
        if rom10[p + delta - R.BASE:p + delta - R.BASE + k] == r.rom[p - R.BASE:p - R.BASE + k]:
            cp += 1
            ag += (p + delta) in starts10
    print("witness v10 (+0x2A): %d / %d comparable instructions start a v10 instruction line" % (ag, cp))
    assert cp and ag >= 0.9 * cp
    assert r.rom[SPLIT - R.BASE:B - R.BASE] == bytes.fromhex("6c10f100"), "entry 0 is not 0x00F1106C"
    table = [(SPLIT, 4, "SeEnvCurve_BitmapTable:\n\t.long\tSeBitmap_EnvCurve6")]
    res, why = r.render(A, B, dec + table)
    assert res, why
    first, last, new = res
    # the reader loads the table's address; name it
    new = [re.sub(r"\bld\txiz, 0xf0f4ac\b", "ld\txiz, SeEnvCurve_BitmapTable", x) for x in new]
    hdr = ["; -----------------------------------------------------------------------------",
           "; SeEnvCurve_BitmapTable (see v10): 7 LE32 pointers to the 40x40 envelope-curve",
           "; bitmaps, read by the code just above (`ld xiz, table / ld xiy,(xiz+wa*4)`),",
           "; drawn by SeGfx_StaticOp03_BlitAtCell with BC = 5 bytes/row, HL = 40 rows.",
           "; Entry 0 was the last 4 bytes of a verbatim ROM slice here; entries 1-6",
           "; follow under SeMenu_WaveformSelect_Init.",
           "; -----------------------------------------------------------------------------"]
    k = [i for i, x in enumerate(new) if "SeEnvCurve_BitmapTable:" in x][0]
    new[k] = "SeEnvCurve_BitmapTable:\n\t.long\tSeBitmap_EnvCurve6"
    new = new[:k] + hdr + new[k:]
    print("lines %d-%d -> %d lines" % (first + 1, last + 1, len(new)))
    if "--apply" in sys.argv:
        L = r.L[:first] + new + r.L[last + 1:]
        open(r.path, "wb").write("\n".join(L).encode("latin-1"))
        print("written", r.path)


if __name__ == "__main__":
    main()
