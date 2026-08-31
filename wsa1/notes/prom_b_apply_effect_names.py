#!/usr/bin/env python3
"""Apply the DSP-effect parameter-page result to prom_b.

It does four things, all of them consequences of
notes/prom_b_effect_param_map.py (20 checks, 3 of them controls):

  1. converts the last 0x78-byte `.incbin` of the effect region,
     0xF14FAC-0xF15023, into the EIGHT interpreter-B records it is, with the
     field layout FINDINGS-ui-display-list-interpreter-b.md established;
  2. renames DataPtrTable_F12F24 -> EffectParamDescriptors_F12F24 and closes its
     `Unknown: what indexes it, and what the entries mean`;
  3. renames sub_F10FF1 -> DspEffect_LoadParamNames;
  4. closes the `⚠ Unknown: that entry k is effect algorithm k` on
     EffectNames_F147AC, quoting what it used to say.

RUN
    python3 notes/prom_b_apply_effect_names.py            # re-derive, change nothing
    python3 notes/prom_b_apply_effect_names.py --apply
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
sys.path.insert(0, os.path.join(ROOT, "notes"))
from prom_b_effect_param_map import records, ROM, B, txt  # noqa: E402

# the round's rename table, for notes/prom_b_naming_preservation.py
RENAMES = [("DataPtrTable_F12F24", "EffectParamDescriptors_F12F24"),
           ("sub_F10FF1", "DspEffect_LoadParamNames")]

INCBIN = '; --- 0xF14FAC-0xF15023: not converted ---\n\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x014FAC, 0x000078\n'

HEADER = """; --------------------------------------------------------------------------
; DL_EffectParamPage -- 0xF14FAC-0xF15023, the DSP EFFECT screen's eight
;   parameter-name rows.  0x78 bytes, which is EXACTLY eight interpreter-B
;   records of fifteen; converted 2026-08-31 from the last `.incbin` of the
;   effect region.
; Run by: DspEffect_LoadParamNames (0xF10FF1), which pushes 0x00F15024 and
;   0x00F14FAC and calls slot T_F42E04.
; Layout: each record draws entry (0x2640+j) of EffectParamNames_F15024 -- 17
;   bytes per entry, which is the row stride that table's own header states --
;   with `swi 7` function 0x20, prom_a's LCD_Svc_20_DrawText8x10.  The eight
;   cursors are 640 apart, and 640 is 16 display lines of AP = 40 bytes, so the
;   rows land at x = 72, y = 74, 90, 106, 122, 138, 154, 170, 186.
; Evidence: the eight source variables are (0x2640)-(0x2647) and they are
;   EXACTLY the eight bytes DspEffect_LoadParamNames writes, at stride 4, out of
;   the per-algorithm descriptor it fetched from EffectParamDescriptors_F12F24.
;   Re-derived by `python3 notes/prom_b_effect_param_map.py --selftest`;
;   write-up in notes/FINDINGS-prom_b-dsp-effect-parameters.md.
; --------------------------------------------------------------------------
DL_EffectParamPage:
"""

PTRTAB_NOTE = """; ✅ ANSWERED 2026-08-31.  This header used to end `Unknown: what indexes it,
;    and what the entries mean.`  Both are now decoded and neither rests on a
;    count coincidence:
;      * DspEffect_LoadParamNames (0xF10FF1) computes `BC = 4 * (0x2796)` and
;        adds it to 0x00F12F24, so the index is the DSP EFFECT ALGORITHM NUMBER.
;      * an entry points at that algorithm's PARAMETER DESCRIPTOR: four bytes per
;        parameter, of which byte 0 is a row of EffectParamNames_F15024.  All
;        456 such bytes over the 57 distinct descriptors are < 100, and that
;        table has exactly 100 rows.
;      * the 57 distinct values are 56 used once and ONE used 72 times, and the
;        72 slots that share it are EXACTLY the 72 slots whose EffectNames_F147AC
;        entry is the `----------` placeholder -- symmetric difference empty.
;    Read out: `python3 notes/prom_b_effect_param_map.py`.  DISTORTION's four
;    parameters come back WET / DRIVE / ADJUST / VOLUME.
; ⚠ Only byte 0 of each four-byte group is decoded, because that is the only one
;    0xF10FF1 reads.  Bytes 1-3 are NOT interpreted.
"""

SUB_NOTE = """; Name:    DspEffect_LoadParamNames -- named 2026-08-31.
; Evidence (TABLE): it computes `BC = 4 * (0x2796)`, indexes
;          EffectParamDescriptors_F12F24 with it, dereferences the entry, and
;          copies EIGHT bytes at stride 4 -- starting at `4 * (0x2792)` -- into
;          RAM (0x2640)-(0x2647).  Those eight bytes are exactly the eight
;          source variables of DL_EffectParamPage, which it then runs by pushing
;          0x00F15024 / 0x00F14FAC and calling slot T_F42E04.  Each is a row of
;          EffectParamNames_F15024.  20 checks:
;          `python3 notes/prom_b_effect_param_map.py --selftest`.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine
;          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's
;          rule that a stated gap beats a plausible guess.`
; Unknown: what (0x2792) counts.  It offsets the eight-byte window into a
;          descriptor that can be longer than eight parameters, so `scroll
;          position` is the obvious reading and is NOT asserted.
"""

NAMES_OLD = """; ⚠ Unknown: that entry k is effect algorithm k.  The block at
;   0xF0EA9F-0xF13D33 has three 128-entry tables indexed from
;   (0x2796); 128 and 128 is a CORRESPONDENCE, not a decoded fact.
"""
NAMES_NEW = """; ✅ ANSWERED 2026-08-31: entry k IS the name of effect algorithm k, and
;   the `Read by: NOTHING ... spells 0x00F147AC` above still holds -- the
;   join runs through a different table.  This header used to end `⚠ Unknown:
;   that entry k is effect algorithm k.  The block at 0xF0EA9F-0xF13D33 has
;   three 128-entry tables indexed from (0x2796); 128 and 128 is a
;   CORRESPONDENCE, not a decoded fact.`  It is a decoded fact now, and what
;   makes it one is an identity of PARTITIONS rather than of counts:
;   EffectParamDescriptors_F12F24, indexed by 4*(0x2796), has 57 distinct
;   entries -- 56 used once and one used 72 times -- and the 72 slots that
;   share it are EXACTLY the 72 slots that carry the `----------` placeholder
;   here.  The descriptors then name each effect's parameters out of
;   EffectParamNames_F15024, and they read correctly: DISTORTION gets WET /
;   DRIVE / ADJUST / VOLUME, CHORUS gets WET / DEPTH / LFO SPEED / LFO
;   WAVEFORM / VOLUME.  `python3 notes/prom_b_effect_param_map.py`,
;   notes/FINDINGS-prom_b-dsp-effect-parameters.md.
"""

OLD_UNKNOWN = (
    "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
    ";          per this tree's rule that a stated gap beats a plausible guess.\n"
)


def emit():
    out = [HEADER]
    for j, r in enumerate(records()):
        row, col = divmod(r["cursor"], 40)
        out.append(f"\t.byte 0x02, 0x0F\t; F{r['addr'] & 0xFFFFFF:06X}"[:0] or "")
        out.append(
            f"\t.byte 0x{r['opcode']:02X}, 0x{r['length']:02X}\t; {r['addr']:06X}"
            f"  B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout\n"
            f"\t.short 0x{r['var']:04X}\t; +0x02 source variable -- byte {j} of the eight\n"
            f"\t.byte 0x{r['mask']:02X}\t; +0x04 AND mask\n"
            f"\t.byte 0x{r['shift']:02X}\t; +0x05 right shift, low 3 bits\n"
            f"\t.byte 0x{r['svc']:02X}\t; +0x06 swi 7 function -- LCD_Svc_20_DrawText8x10\n"
            f"\t.long 0x00{r['table']:06X}\t; +0x07 -> XIY: EffectParamNames_F15024\n"
            f"\t.short 0x{r['width']:04X}\t; +0x0B -> BC: bytes per entry\n"
            f"\t.short 0x{r['cursor']:04X}\t; +0x0D -> IX: x={col * 8}, y={row}\n")
    return "".join(x for x in out if x)


def check():
    rs = records()
    ok = len(rs) == 8 and all(r["opcode"] == 0x02 for r in rs)
    print(emit()[:400] + " ...")
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


def apply():
    with open(SRC) as f:
        s = f.read()
    assert INCBIN in s, "the 0xF14FAC .incbin is not where it was"
    s = s.replace(INCBIN, emit(), 1)

    SEP = re.compile(r"^; -{10,}\n", re.M)

    def head_of(label):
        i = s.index("\n" + label + ":") + 1
        st = [m.start() for m in SEP.finditer(s, 0, i)]
        return (st[-2] if len(st) >= 2 else st[-1]), i

    # DataPtrTable_F12F24
    h, i = head_of("DataPtrTable_F12F24")
    blk = s[h:i].replace("; Unknown: what indexes it, and what the entries mean.\n", PTRTAB_NOTE)
    blk = blk.replace("; DataPtrTable_F12F24 --", "; EffectParamDescriptors_F12F24 -- 0xF12F24,", 1)
    s = s[:h] + blk + s[i:]
    s = re.sub(r"\bDataPtrTable_F12F24\b", "EffectParamDescriptors_F12F24", s)

    # sub_F10FF1
    h, i = head_of("sub_F10FF1")
    blk = s[h:i]
    assert OLD_UNKNOWN in blk
    blk = blk.replace(OLD_UNKNOWN, SUB_NOTE).replace("; sub_F10FF1\n", "; DspEffect_LoadParamNames -- 0xF10FF1\n", 1)
    s = s[:h] + blk + s[i:]
    s = re.sub(r"\bsub_F10FF1\b", "DspEffect_LoadParamNames", s)

    # EffectNames_F147AC
    assert NAMES_OLD in s
    s = s.replace(NAMES_OLD, NAMES_NEW, 1)

    with open(SRC, "w") as f:
        f.write(s)
    print("converted 0x78 bytes, renamed 2 labels, closed 2 Unknowns")
    return 0


if __name__ == "__main__":
    sys.exit(apply() if "--apply" in sys.argv else check())
