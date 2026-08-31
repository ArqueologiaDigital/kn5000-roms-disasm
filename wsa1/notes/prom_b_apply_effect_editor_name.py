#!/usr/bin/env python3
"""Name prom_b 0xF11057: the DSP effect parameter EDITOR page.

WHAT IT DOES, read off its own instructions
    `lda XIX,0x2796` (0xF1107A) then `ld A,(XIX)` (0xF11096) -- the effect
    ALGORITHM number -- `mul A,4`, `add XWA,0x00f12f24`, `ld XWA,(XWA)`: the
    same descriptor fetch DspEffect_LoadParamNames makes.  Then, per screen
    line, with `C = (0x2792) + E` the parameter index and `XBC = 4*C` the
    descriptor group:

      byte +1  -> (0x2640) (0xF110AC), and 4*byte1 indexes the 32-entry array
                  at 0xF13264 (0xF110EA, jumped to at 0xF110F8) and the one at
                  0xF132E4 (0xF110FA), whose entry + 15*line is the
                  interpreter-B record that draws the VALUE
      byte +2  -> pushed at 0xF110DF for the handler above
      byte +3  -> compared against the byte IndexedTable_GetByte returns for
                  0x61 + (0x2797) (0xF11061-0xF11070, 0xF1112B); equal puts 1
                  in (0x2640), 0xFF puts 0, otherwise 2, and a record from the
                  SECOND group of DLB_Records_F157A8 (0xF15820) draws that --
                  the cursor marker

    The line loop is `add H,0x0F` / `inc 1,E` / `cp H,0x69` / `jrl ULE`
    (0xF1115F-0xF11168), so H runs 0, 15, ... 105: EIGHT lines, the same eight
    DL_EffectParamPage names.

WHAT THE NAME CLAIMS
    That this paints the effect parameter editor's page.  It does NOT claim what
    byte 2 means, what selects a record GROUP above 0, or what (0x2797) counts
    beyond being the index whose match puts the cursor on a line.

RUN
    python3 notes/prom_b_apply_effect_editor_name.py
    python3 notes/prom_b_apply_effect_editor_name.py --apply
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
RENAMES = [("sub_F11057", "DspEffect_PaintParamEditor")]

OLD_UNKNOWN = (
    "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
    ";          per this tree's rule that a stated gap beats a plausible guess.\n"
)

NOTE = """; Name:    DspEffect_PaintParamEditor -- named 2026-08-31.
; Evidence (TABLE): `lda XIX,0x2796` at 0xF1107A and `ld A,(XIX)` at 0xF11096
;          fetch the effect ALGORITHM number, and `mul A,4` /
;          `add XWA,0x00f12f24` / `ld XWA,(XWA)` is the same descriptor fetch
;          DspEffect_LoadParamNames makes.  Per line it takes the parameter
;          index `C = (0x2792) + E` and the group `XBC = 4*C`, and uses three of
;          the group's four bytes:
;            +1  -> (0x2640) at 0xF110AC; 4*byte1 indexes the 32-entry arrays at
;                   0xF13264 (0xF110EA, jumped to at 0xF110F8) and 0xF132E4
;                   (0xF110FA), and THAT entry + 15*line is the interpreter-B
;                   record that draws the value -- the arrays
;                   notes/gen_prom_b_dsp_value_lists.py frames.
;            +2  -> pushed at 0xF110DF for the handler above.
;            +3  -> compared at 0xF1112B with the byte IndexedTable_GetByte
;                   returns for 0x61 + (0x2797); equal writes 1 to (0x2640),
;                   0xFF writes 0, otherwise 2, and a record from the SECOND
;                   group of DLB_Records_F157A8 (0xF15820) draws it -- the
;                   cursor marker.
;          The line loop is `add H,0x0F` / `inc 1,E` / `cp H,0x69` / `jrl ULE`
;          at 0xF1115F-0xF11168, so H runs 0, 15 ... 105: EIGHT lines, the same
;          eight DL_EffectParamPage names.
;          Write-up: notes/FINDINGS-prom_b-dsp-effect-parameters.md sec. 6.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine
;          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's
;          rule that a stated gap beats a plausible guess.`
; Unknown: what descriptor byte 2 means, what selects a record GROUP above 0
;          (this loop never exceeds offset 105), and what (0x2792) counts.
"""


def check():
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    from prom_b_effect_param_map import ROM, B  # noqa
    # the three constants the header rests on, straight out of the ROM
    got = {
        "0xF1107A lda XIX,0x2796": ROM[0xF1107A - B:0xF1107F - B].hex(),
        "0xF1109D add XWA,0xf12f24": ROM[0xF1109D - B:0xF110A3 - B].hex(),
        "0xF1115F add H,0x0f": ROM[0xF1115F - B:0xF11162 - B].hex(),
        "0xF11165 cp H,0x69": ROM[0xF11165 - B:0xF11168 - B].hex(),
    }
    for k, v in got.items():
        print(f"  {k:34s} {v}")
    ok = ("9627" in got["0xF1107A lda XIX,0x2796"] and
          "242ff1" in got["0xF1109D add XWA,0xf12f24"] and
          got["0xF11165 cp H,0x69"].endswith("69"))
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


def apply():
    with open(SRC) as f:
        s = f.read()
    SEP = re.compile(r"^; -{10,}\n", re.M)
    for old, new in RENAMES:
        i = s.index("\n" + old + ":") + 1
        st = [m.start() for m in SEP.finditer(s, 0, i)]
        h = st[-2] if len(st) >= 2 else st[-1]
        blk = s[h:i]
        assert OLD_UNKNOWN in blk, old
        blk = blk.replace(OLD_UNKNOWN, NOTE).replace(f"; {old}\n", f"; {new} -- 0x{old[4:]}\n", 1)
        s = s[:h] + blk + s[i:]
        s = re.sub(r"\b" + old + r"\b", new, s)
    with open(SRC, "w") as f:
        f.write(s)
    print(f"renamed {len(RENAMES)}")
    return 0


if __name__ == "__main__":
    sys.exit(apply() if "--apply" in sys.argv else check())
