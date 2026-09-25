#!/usr/bin/env python3
r"""prom_b 0xF32FE6-0xF33361 (ex `Data_F32FE6`): a record-pointer array and two string tables.

QUESTION THIS ANSWERS
    `Data_F32FE6` (892 bytes) was filed as data the reachability walk marked,
    "96% printable ASCII", with no layout.  Its readers fix three objects:

      0xF32FE6  12 x 32-bit pointers to interpreter-B records.  Read by
                SoundEditController_PaintHeader (`ld XIY,0xF32FE6 / call
                RunDisplayListBFromPointerArray` at 0xF09957), which indexes it
                with A (`sla 2,WA / add XIY,XWA / ld XIY,(XIY)`) and runs ONE
                record.  Its address is also the END of the interpreter-B list
                that starts at DL_F32FC8 (`ld XIY,DL_F32FC8 / ld XIX,0xF32FE6 /
                call T_DisplayListB_Run` at 0xF0983A and three more sites).
      0xF33016  4 entries of 3 bytes -- "OFF", "ON ", "---", "INV" -- read by
                four interpreter-B op-0x02 records, one per 2-bit field of
                (0x27B2) (masks 0x03/0x0C/0x30/0xC0), +0x0B width 3.
      0xF33022  64 entries of 13 bytes: the controller DESTINATION names
                ("PITCH BEND", "SUSTAIN LEVEL", ... "REV DYNAMIC", then
                "           50".."63").  Read by op-0x02 records with mask 0x3F
                and width 13 (DL_F32F43 ..) and by UiText_CopyLabel13_To_22F0
                (`and A,0x3F / mul A,13 / ld XIY,0xF33022` at 0xF5B804).
                64 x 13 = 832 bytes ends exactly at 0xF33362, where the
                interpreter-A list DL_F33362 begins.

RUN
    python3 notes/promb-2026-09-25/controller_destination_names.py            # checks
    python3 notes/promb-2026-09-25/controller_destination_names.py --apply    # write the source
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
PTRS, ONOFF, NAMES, END = 0xF32FE6, 0xF33016, 0xF33022, 0xF33362
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    ptrs = [int.from_bytes(at(PTRS + 4 * k, 4), "little") for k in range(12)]
    check("0xF32FE6: 12 pointers, each to an interpreter-B record start (op < 0x0F, length 11 "
          "or 15) in 0xF32F43-0xF32FA0", all(0xF32F43 <= p <= 0xF32FA0 and at(p, 1)[0] < 0x0F
                                               for p in ptrs))
    check("SoundEditController_PaintHeader: `ld XIY,0x00F32FE6` (45 e6 2f f3 00) at 0xF09957, "
          "`call 0xF09AE1` (RunDisplayListBFromPointerArray) at 0xF0995C",
          at(0xF09957, 5).hex() == "45e62ff300" and at(0xF0995C, 4).hex() == "1de19af0")
    check("`ld XIY,0x00F32FC8 / ld XIX,0x00F32FE6` (the list's end) at 0xF0983A, 0xF09896, "
          "0xF099D3, 0xF5D75D and 0xF5D7CD",
          all(at(a, 10).hex() == "45c82ff30044e62ff300"
              for a in (0xF0983A, 0xF09896, 0xF099D3, 0xF5D75D, 0xF5D7CD)))
    onoff = [at(ONOFF + 3 * k, 3).decode() for k in range(4)]
    check("0xF33016: OFF / ON / --- / INV, 3 bytes each", onoff == ["OFF", "ON ", "---", "INV"])
    names = [at(NAMES + 13 * k, 13).decode() for k in range(64)]
    check("0xF33022: 64 x 13 printable bytes, ending exactly at 0xF33362",
          NAMES + 64 * 13 == END and all(all(0x20 <= ord(c) < 0x7F for c in n) for n in names))
    check("  entries 50..63 are the placeholders '           50'..'63'",
          all(names[k] == "%13d" % k for k in range(50, 64)))
    check("UiText_CopyLabel13_To_22F0: `and A,0x3F / mul A,13 / ld XIY,0x00F33022` at 0xF5B804",
          at(0xF5B804, 3).hex() == "c9cc3f" and at(0xF5B807, 3).hex() == "c9080d" and
          at(0xF5B80A, 5).hex() == "452230f300")
    # the op-0x02 records that read the two tables: +0x07 pointer, +0x0B width, +0x04 mask
    recs = []
    i = b.find(ONOFF.to_bytes(4, "little"))
    while i >= 0:
        p = BASE + i - 7
        if b[i - 7] == 0x02 and b[i - 6] == 0x0F:
            recs.append((p, "onoff", b[i - 3], int.from_bytes(b[i + 4:i + 6], "little")))
        i = b.find(ONOFF.to_bytes(4, "little"), i + 1)
    i = b.find(NAMES.to_bytes(4, "little"))
    while i >= 0:
        p = BASE + i - 7
        if b[i - 7] == 0x02 and b[i - 6] == 0x0F:
            recs.append((p, "names", b[i - 3], int.from_bytes(b[i + 4:i + 6], "little")))
        i = b.find(NAMES.to_bytes(4, "little"), i + 1)
    on = [r for r in recs if r[1] == "onoff"]
    nm = [r for r in recs if r[1] == "names"]
    check("%d op-0x02 records read 0xF33016 with width 3, masks 0x03/0x0C/0x30/0xC0 -- the four "
          "2-bit fields of (0x27B2)" % len(on),
          sorted(r[2] for r in on) == [0x03, 0x0C, 0x30, 0xC0] and all(r[3] == 3 for r in on))
    check("%d op-0x02 records read 0xF33022 with mask 0x3F and width 13" % len(nm),
          nm and all(r[2] == 0x3F and r[3] == 13 for r in nm))
    return ptrs, onoff, names, len(on), len(nm)


def emit(ptrs, onoff, names, n_on, n_nm):
    out = [r"""; --------------------------------------------------------------------------
; SoundEditController_HeaderRecords -- 0xF32FE6, 12 pointers to single
;   interpreter-B records (0xF32F43-0xF32FA0).  Read by
;   SoundEditController_PaintHeader: `ld XIY,this / call
;   RunDisplayListBFromPointerArray` at 0xF09957 -- A indexes it and ONE record
;   is run.  Entries 6-11 all name 0xF32FA0.  This address is also the END of
;   the interpreter-B list at DL_F32FC8 (`ld XIY,DL_F32FC8 / ld XIX,this /
;   call T_DisplayListB_Run` at 0xF0983A, 0xF09896, 0xF099D3, 0xF5D75D and
;   0xF5D7CD).
; ⚠ REPLACES `Data_F32FE6` (892 bytes: this array and the two string tables
;   below), whose header gave no layout and put its extent down to the
;   reachability walk.  python3 notes/promb-2026-09-25/
;   controller_destination_names.py checks every claim here.
; --------------------------------------------------------------------------
SoundEditController_HeaderRecords:"""]
    for k, p in enumerate(ptrs):
        out.append("\t.long\t0x%08X\t; %06X  [%d]" % (p, PTRS + 4 * k, k))
    out.append(r"""; ControllerSwitchStateText -- 0xF33016, 4 entries of 3 bytes: OFF / ON /
;   --- / INV.  Read by %d interpreter-B op-0x02 records at 0xF32FAA-0xF32FD7,
;   one per 2-bit field of (0x27B2) (masks 0x03/0x0C/0x30/0xC0, shifts 0/2/4/6,
;   entry width 3 at +0x0B): four switches, each OFF, ON, --- or INV.
ControllerSwitchStateText:""" % n_on)
    for k, s in enumerate(onoff):
        out.append('\t.ascii\t"%s"\t; %06X  [%d]' % (s, ONOFF + 3 * k, k))
    out.append(r"""; --------------------------------------------------------------------------
; ControllerDestinationNames -- 0xF33022, 64 entries of 13 bytes: the names of
;   what a sound-edit controller can be assigned to -- PITCH BEND, SUSTAIN
;   LEVEL, FILTER CUTOFF, the pitch/amp/filter LFO depths and speeds,
;   FITTING .. REV DYNAMIC -- then 14 numbered placeholders "           50" ..
;   "           63".
; Read by: %d interpreter-B op-0x02 records (DL_F32F43 and on: mask 0x3F,
;   width 13 at +0x0B) and UiText_CopyLabel13_To_22F0 (0xF5B800: `and
;   A,0x3F / mul A,13 / ld XIY,this` then a 13-byte copy to 0x22F0).  The
;   0x3F mask is the 64-entry bound; 64 x 13 ends exactly at DL_F33362.
; --------------------------------------------------------------------------
ControllerDestinationNames:""" % n_nm)
    for k, s in enumerate(names):
        out.append('\t.ascii\t"%s"\t; %06X  [%d]' % (s, NAMES + 13 * k, k))
    return "\n".join(out) + "\n"


def apply(d):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    i = [k for k, t in enumerate(L) if t.startswith("Data_F32FE6:")]
    assert len(i) == 1
    s = i[0]
    while L[s - 1].startswith(";"):
        s -= 1
    e = i[0] + 1
    while e < len(L) and (L[e].startswith("\t.byte") or not L[e].strip()):
        e += 1
    last = max(k for k in range(i[0], e) if L[k].startswith("\t.byte"))
    assert "F3335" in L[last], L[last]
    L = L[:s] + ["@@BLOCK@@"] + L[last + 1:]
    txt = "\n".join(L)
    txt = re.sub(r'\bData_F32FE6 \+ 0x3C\b', "ControllerDestinationNames", txt)
    txt = re.sub(r'\bData_F32FE6 \+ 0x30\b', "ControllerSwitchStateText", txt)
    txt = re.sub(r'\bData_F32FE6\b', "SoundEditController_HeaderRecords", txt)
    txt = txt.replace("@@BLOCK@@", emit(*d).encode("utf-8").decode("latin-1").rstrip("\n"))
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC)


def main():
    d = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
