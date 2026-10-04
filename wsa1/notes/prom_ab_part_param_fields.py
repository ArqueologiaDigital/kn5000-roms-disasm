#!/usr/bin/env python3
"""Name the part-parameter field descriptors (prom_b Record_F1Axxx) and the prom_a handlers that edit them.

QUESTION IT ANSWERS
  sub_FBB800 (adjust) and sub_FBB93C (number entry) dispatch a field id H through prom_b's PtrTable_F1AB13 ..
  PtrTable_F1ACDB to prom_a handlers.  Most handlers are a three-line wrapper
      lda XBC,<Record_F1Axxx> / push / push 0 / push (XIZ+8) / call T_IndexedParam_AdjustField   (or _SetFieldFromAsciiEntry)
  and the record is a field descriptor: +0 byte offset in the IndexedTable object, +1 mask, +3 maximum, +4 minimum
  (IndexedParam_AdjustField's header).  Two independent facts name the field:
    1. the SysEx parameter descriptors (notes/prom_b_sysex_param_descriptors.py) give every Reference-Guide-named
       parameter its (record, offset, mask, range).  A field record whose (offset, mask, max, min) equals that of
       exactly ONE parameter of the PART area (address 20 xx) is that parameter -- e.g. offset 9, 28..100 is
       KEY SHIFT and offset 11, 0..12 PITCH BEND RANGE;
    2. two records match two PART parameters each (offset 8: PANPOT / KEY LAYER HIGH, offset 7: REVERB SEND / KEY
       LAYER LOW).  Both are entries of PtrTable_F1AB13, whose field ids follow the COMBINATION EDIT INTERNAL SOUND
       page (DL_InternalSound_F18CDD: VOLUME / PAN / KEY SHIFT / FINE TUNE / BEND RANGE, then EFFECT1 SEND /
       EFFECT2 / REVERB SEND): id 2 sits between VOLUME and KEY SHIFT, so it is PAN; and the DSP EFFECT screen asks
       for ids 6 / 7 / 8 for its EFFECT 1 / EFFECT 2 / REVERB blocks (sub_F10222), so id 8 is REVERB SEND.
  Names: the record PartParamField_<Name>; an adjust handler PartParam_Step<Name>; a number-entry handler
  PartParam_Enter<Name>; the shared refusal at 0xFBBA83 (`Blink_SetEnable(0)`, return 0) PartParam_RefuseNumberEntry;
  the EFFECT2 handler at id 7 (toggles byte 6 between 0 and 0x7F) PartParam_StepEffect2.
  REFUSED: a record with no unique PART match that position does not settle; a handler of any other shape.

RUN
  python3 notes/prom_ab_part_param_fields.py           # the plan
  python3 notes/prom_ab_part_param_fields.py --records # 'old=new|header' for the rename helper (prom_b records)
  python3 notes/prom_ab_part_param_fields.py --place   # 'ADDR=Name|header' for wsa1_place.py (prom_a handlers)
"""
import collections
import contextlib
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes", "sysex-probes"))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1").split("\n")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1").split("\n")
H = "(notes/prom_ab_part_param_fields.py)"
BY_POSITION = {"PartParamField_Panpot": ("PANPOT", "PtrTable_F1AB13[2], between VOLUME [1] and KEY SHIFT [3] as on the INTERNAL SOUND page"),
               "PartParamField_ReverbSend": ("REVERB SEND", "PtrTable_F1AB13[8], the id the DSP EFFECT screen asks for its REVERB block")}
SPECIAL = {0xFBBA83: ("PartParam_RefuseNumberEntry", "the number-entry slot of a field that takes none: Blink_SetEnable(0), returns 0"),
           0xFBBBAB: ("PartParam_StepEffect2", "PtrTable_F1AB13[7], EFFECT2 on the INTERNAL SOUND page: byte 6 of the part record toggles 0 <-> 0x7F")}


def camel(s):
    s = re.sub(r'[^A-Za-z0-9]+', ' ', s.replace("&", " and ")).strip()
    return "".join(w[:1].upper() + w[1:].lower() for w in s.split())


def sysex():
    with contextlib.redirect_stdout(io.StringIO()):
        saved, sys.argv = sys.argv, ["x"]
        import sysex_param_addresses as P
        sys.argv = saved
    names = json.load(open(os.path.join(ROOT, "notes", "sysex-probes", "param_names.json")))
    out = collections.defaultdict(list)
    for p in P.PARAMS:
        if p.b7 == 0x20:
            out[(p.off, p.mask, p.hi, p.lo)].append(names["%02X/%02X" % (p.b7, p.b8)]["name"])
    return out


def records():
    out = {}
    for i, l in enumerate(B):
        m = re.match(r'^(Record_F1A[C-F]\w+|PartParamField_\w+):', l)   # the second spelling: after the rename
        if m:
            mm = re.match(r'^\s*\.byte\s+([^;]+)', B[i + 1])
            if mm:
                v = [int(x, 0) for x in mm.group(1).split(",")]
                if len(v) >= 5:
                    out[m.group(1)] = v
    return out


def handlers():
    at = {}
    for i, l in enumerate(A):
        m = re.search(r';\s*([0-9A-F]{6})\s', l)
        c = l.split(";")[0].strip()
        if m and c and not re.match(r'^[\w.]+:$', c):
            at.setdefault(int(m.group(1), 16), i)
    out = {}
    for i, l in enumerate(B):
        m = re.match(r'^(PtrTable_F1A[BC][0-9A-F]{2}):', l)
        if not m:
            continue
        k = 0
        for x in B[i + 1:i + 40]:
            mm = re.match(r'^\s*\.long\s+0x00(F[89A-F][0-9A-F]{4})\b', x)
            if mm:
                a = int(mm.group(1), 16)
                j = " | ".join(re.sub(r'\s+', ' ', A[q].split(";")[0]).strip() for q in range(at[a], at[a] + 8)) if a in at else ""
                rec = re.search(r'lda xbc, \(((?:Record|PartParamField)_\w+):24\)', j)
                kind = "Step" if "T_IndexedParam_AdjustField" in j else ("Enter" if "T_IndexedParam_SetFieldFromAsciiEntry" in j else None)
                out.setdefault(a, []).append((m.group(1), k, kind, rec.group(1) if rec else None))
            elif not re.match(r'^\s*\.long', x) and x.strip() and not x.startswith(";"):
                break
            if re.match(r'^\s*\.long', x):
                k += 1
    return out, at


def plan():
    sx, recs = sysex(), records()
    rname, refused = {}, []
    for r, v in recs.items():
        if r in BY_POSITION:
            rname[r] = (BY_POSITION[r][0], "named by position: " + BY_POSITION[r][1])
            continue
        c = sx.get((v[0], v[1], v[3], v[4]), [])
        if len(c) == 1:
            rname[r] = (c[0], "offset %d, mask 0x%02X, %d..%d -- the only PART parameter with that field: %s" % (v[0], v[1], v[4], v[3], c[0]))
        elif c:
            refused.append((r, "matches %s" % c))
    base = collections.Counter(camel(n) for n, _w in rname.values())
    rlab = {r: "PartParamField_" + camel(n) + ("" if base[camel(n)] == 1 else "_" + r[-6:]) for r, (n, _w) in rname.items()}
    hs, at = handlers()
    place = {}
    for a, uses in hs.items():
        if a in SPECIAL:
            place[a] = SPECIAL[a]
            continue
        kinds = {(k, rec) for _t, _i, k, rec in uses}
        if len(kinds) != 1:
            continue
        kind, rec = kinds.pop()
        if kind and rec in rlab:
            place[a] = ("PartParam_%s%s" % (kind, rlab[rec][len("PartParamField_"):]),
                        "%s handler of %s (%s), slot %s" % ("the adjust" if kind == "Step" else "the number-entry", rlab[rec], rname[rec][0],
                                                            ", ".join("%s[%d]" % (t, i) for t, i, _k, _r in uses)))
    return rlab, rname, place, refused, at


def main():
    rlab, rname, place, refused, at = plan()
    if "--records" in sys.argv:
        for r, n in sorted(rlab.items()):
            print("%s=%s|%s: the part-parameter field descriptor of %s -- %s %s" % (r, n, n, rname[r][0], rname[r][1], H))
        return
    if "--place" in sys.argv:
        for a, (n, w) in sorted(place.items()):
            if a in at:
                print("%06X=%s|%s: %s %s" % (a, n, n, w, H))
        return
    for r, n in sorted(rlab.items()):
        print("%-14s -> %-44s %s" % (r, n, rname[r][1][:70]))
    for a, (n, w) in sorted(place.items()):
        print("0x%06X -> %-40s %s" % (a, n, w[:80]))
    for r, why in refused:
        print("REFUSED %s: %s" % (r, why))
    print("records %d, handlers %d, refused %d" % (len(rlab), len(place), len(refused)))


if __name__ == "__main__":
    main()
