#!/usr/bin/env python3
"""Name the field machinery of the sequencer's EDIT jobs (MEASURE DELETE, MEASURE ERASE, VELOCITY CHANGE, ...).

QUESTION IT ANSWERS
  Each EDIT job page (prom_b 0xF7A400-0xF7CFFF, painters Paint_<Job> at 0xF7Exxx) has the same machinery, and none
  of it was named:
    * Paint_<Job> calls, at stage 0, a thunk onto an INIT routine:  calr <loader> / ld (<cursor>),1 / ...
      -- the loader copies the job's saved fields out of battery RAM (0x6034xx) into the working cells;
    * two STEP routines store the step direction in (0x0C4F) -- 0 = up, 0x80 = down (SeqJob_StepTrack /
      SeqJob_StepMeasure test `cp (0x0C4F),0x80` and subtract on equality) -- and then dispatch on the field
      cursor: `cp (<cursor>),k / jr nz / calr <field stepper k>`;
    * the UP step routine first tests `cp UI_ScreenStage,1 / jr nz / jr <R>`: at stage 1 it leaves through <R>,
      whose body is the return-to-stage-zero shape (UI_ScreenStage = 0, UI_Request_Hi |= 0x10).
  Field k is the k-th line of the page's own text, which is printed top to bottom in one column:
      MEASURE DELETE   TRACK / FIRST MEASURE / LAST MEASURE
      MEASURE ERASE    TRACK / FIRST MEASURE / LAST MEASURE / ERASE DATA
      VEL0CITY CHANGE  TRACK / FIRST MEASURE / LAST MEASURE / VELOCITY
      TRANSP0SE        TRACK / FIRST MEASURE / LAST MEASURE / TRANSPOSE
      ADVANCE/DELAY    TRACK / FIRST MEASURE / LAST MEASURE / ADVANCE/DELAY
  and that order is CHECKED, not assumed: the TRACK stepper must call SeqJob_StepTrack (step 1, bounded at 18) and
  the two MEASURE steppers SeqJob_StepMeasure (step from SongStore_StepSizeTable, 1..999); a job that fails is refused
  whole.  (QUANTIZE prints two columns and MEASURE INSERT / COPY a FROM / TO layout: left for a reading.)
  Names: <Job>_InitFields, <Job>_LoadSavedFields, <Job>_StepFieldUp / _StepFieldDown, <Job>_ReturnToStageZero,
  <Job>_Step<Field>, the thunks T_<same>, and the two shared helpers.

RUN
  python3 notes/prom_b_seqjob_field_names.py          # the plan
  python3 notes/prom_b_seqjob_field_names.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
L = B.split("\n")
G = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Resume|Nop)\d*$')
IDX = {G.match(l).group(1): i for i, l in enumerate(L) if G.match(l)}
THUNK = {m.group(1): m.group(2) for l in L for m in [re.match(r'^(T_\w+):\s*jp\s+(\w+)', l)] if m}
BACK = {v: k for k, v in THUNK.items()}
JOBS = {"MeasureDelete": ["Track", "FirstMeasure", "LastMeasure"],
        "MeasureErase": ["Track", "FirstMeasure", "LastMeasure", "EraseData"],
        "Vel0cityChange": ["Track", "FirstMeasure", "LastMeasure", "Velocity"],
        "Transp0se": ["Track", "FirstMeasure", "LastMeasure", "Transpose"],
        "AdvanceDelay": ["Track", "FirstMeasure", "LastMeasure", "AdvanceDelay"]}
STEP_TRACK, STEP_MEASURE = "SeqJob_StepTrack", "SeqJob_StepMeasure"
# VELOCITY CHANGE steps its TRACK with the twin helper 0xF7CD01, whose up path tests 17 instead of 18 (see the rows)
TRACK_HELPERS = (STEP_TRACK, "SeqJob_StepTrack17", "SeqJob_StepTrack17")


def body(n):
    i, out = IDX[n] + 1, []
    while i < len(L) and not (G.match(L[i]) and not LOC.search(G.match(L[i]).group(1))):
        c = re.sub(r'\s+', ' ', L[i].split(";")[0]).strip()
        if c:
            out.append(c)
        i += 1
    return out


def resolve(t):
    return THUNK.get(t, t)


def plan():
    rows, refused = [], []
    steppers = [n for n in IDX if not LOC.search(n) and re.match(r'^sub_F7[A-C]', n)
                and any(re.match(r'ld \(3151:16\), (0|128)$', c) for c in body(n))]
    for job, fields in JOBS.items():
        paint = "Paint_" + job
        pb = body(paint)
        calls = [resolve(m.group(1)) for c in pb[:6] for m in [re.match(r'call (T_\w+)$', c)] if m]
        init = next((c for c in calls if c.startswith("sub_")), None)
        if not init:
            refused.append((job, "no init call at stage 0"))
            continue
        ib = body(init)
        lm = next((m for c in ib for m in [re.match(r'calr (sub_\w+)$', c)] if m), None)
        cm = None
        for k, c in enumerate(ib):
            m = re.match(r'ld \((\w+):16\), (1|a)$', c)
            if m and (m.group(2) == "1" or (k and ib[k - 1] == "ld a, 1:opc")) and "DisplayListB_Stage" not in m.group(1):
                cm = m
                break
        if not cm:
            refused.append((job, "init %s sets no field cursor to 1" % init))
            continue
        tok = cm.group(1)
        cursor = int(tok) if tok.isdigit() else tok
        cur_hex = ("0x%04x" % cursor) if isinstance(cursor, int) else cursor
        loader = lm.group(1) if lm else None
        if loader and not re.search(r'\(630[34]\d{3}:24\)', " ".join(body(loader))):
            loader = None                     # a calr that is not the battery-RAM loader is not named here
        mine = [s for s in steppers if any(c.startswith("m_cp_mi8 MB16, %s, 0x01" % cur_hex) for c in body(s))]
        up = [s for s in mine if "ld (3151:16), 0" in body(s)]
        down = [s for s in mine if "ld (3151:16), 128" in body(s)]
        if len(up) != 1 or len(down) != 1:
            refused.append((job, "step routines up %s down %s" % (up, down)))
            continue
        ub = body(up[0])
        rm = re.match(r'jr (sub_\w+)$', ub[2]) if len(ub) > 2 and ub[0] == "m_cp_mi8 MB16, UI_ScreenStage, 0x01" else None
        ret0 = rm.group(1) if rm else None
        if not ret0 or "ld (UI_ScreenStage:16), 0" not in body(ret0):
            refused.append((job, "no return-to-stage-zero exit in %s" % up[0]))
            continue
        fs = {}
        for s in (up[0], down[0]):
            b = body(s)
            for k, c in enumerate(b):
                m = re.match(r'm_cp_mi8 MB16, %s, 0x0(\d)$' % cur_hex, c)
                if m:
                    t = next((mm.group(1) for c2 in b[k + 1:k + 4] for mm in [re.match(r'calr (\w+)$', c2)] if mm), None)
                    if t:
                        fs.setdefault(int(m.group(1)), set()).add(t)
        if sorted(fs) != list(range(1, len(fields) + 1)) or any(len(v) != 1 for v in fs.values()):
            refused.append((job, "field dispatch %s does not match %d fields" % (fs, len(fields))))
            continue
        fs = {k: v.pop() for k, v in fs.items()}
        bad = [k for k, f in enumerate(fields, 1) if f == "Track" and not any(("calr %s" % t) in body(fs[k]) for t in TRACK_HELPERS)
               or f.endswith("Measure") and ("calr %s" % STEP_MEASURE) not in body(fs[k])]
        if bad:
            refused.append((job, "fields %s do not call the helper their text implies" % bad))
            continue
        H = "(notes/prom_b_seqjob_field_names.py)"
        rows += [(init, job + "_InitFields", "%s_InitFields: Paint_%s's stage-0 init: %sfield cursor (%s) = 1 %s" % (
                     job, job, (job + "_LoadSavedFields, ") if loader else "", cur_hex, H))]
        if loader:
            rows.append((loader, job + "_LoadSavedFields", "%s_LoadSavedFields: copies the job's saved fields from battery RAM 0x6034xx into the working cells %s" % (job, H)))
        rows += [
                 (up[0], job + "_StepFieldUp", "%s_StepFieldUp: at stage 1 leaves through %s_ReturnToStageZero; else (0x0C4E) = W, (0x0C4F) = 0 (up) and\n  steps field (%s) %s" % (job, job, cur_hex, H)),
                 (down[0], job + "_StepFieldDown", "%s_StepFieldDown: (0x0C4E) = W, (0x0C4F) = 0x80 (down), steps field (%s) %s" % (job, cur_hex, H)),
                 (ret0, job + "_ReturnToStageZero", "%s_ReturnToStageZero: UI_ScreenStage = 0, UI_Request_Hi |= 0x10 %s" % (job, H))]
        for k, f in enumerate(fields, 1):
            rows.append((fs[k], "%s_Step%s" % (job, f), "%s_Step%s: field %d of the page (%s), stepped in the direction (0x0C4F) holds %s" % (job, f, k, ", ".join(fields), H)))
        for n, new in ((init, job + "_InitFields"), (up[0], job + "_StepFieldUp"), (down[0], job + "_StepFieldDown"), (ret0, job + "_ReturnToStageZero")):
            if n in BACK and re.match(r'^T_F4\w+$', BACK[n]):
                rows.append((BACK[n], "T_" + new, ""))
    if "SeqJob_StepTrack17" not in B:
        rows.append(("SeqJob_StepTrack17", "SeqJob_StepTrack17", "SeqJob_StepTrack17: A +- 1 by (0x0C4F); up: past 17 -> H, down: below L -> L.  The TRACK helper of VEL0CITY CHANGE\n"
                     "  and the SongStore dispatchers.  SeqJob_StepTrack's UP path is THIS code: its `jr NZ` at 0xF7CD3B jumps to 0xF7CD10, so\n"
                     "  SeqJob_StepTrack's own `cp A,18` copy (0xF7CD3F-0xF7CD4F) never runs (notes/prom_b_seqjob_field_names.py)"))
    if any(o == STEP_TRACK for o, _n, _h in rows) is False:
        rows.append((STEP_TRACK, "SeqJob_StepTrack", "SeqJob_StepTrack: A +- 1 by (0x0C4F) (0x80 = down), bounded L..18 -- the TRACK field of every EDIT job (notes/prom_b_seqjob_field_names.py)"))
        rows.append((STEP_MEASURE, "SeqJob_StepMeasure", "SeqJob_StepMeasure: WA +- SongStore_StepSizeTable[(0x0E18)] by (0x0C4F), clamped 1..999 -- the MEASURE fields (notes/prom_b_seqjob_field_names.py)"))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    news = [n for _o, n, _h in rows]
    for o, n, h in rows:
        bad = news.count(n) > 1 or n in taken or not o.startswith(("sub_", "T_F4"))
        if "--args" in sys.argv:
            if not bad:
                print(("%s=%s|%s" % (o, n, h.replace("\n", "\\n"))) if h else "%s=%s" % (o, n))
        else:
            print("%-14s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for o, n, _h in rows if not (news.count(n) > 1 or n in taken or not o.startswith(("sub_", "T_F4")))), len(refused)))


if __name__ == "__main__":
    main()
