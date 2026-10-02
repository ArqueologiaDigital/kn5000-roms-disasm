#!/usr/bin/env python3
"""label_naka_records.py -- every NAKA widget record a registered Viewable table points at gets a label.

QUESTION THIS ANSWERS / JOB IT DOES
  The firmware registers 209 Viewable tables (RegObjTabl NAKA_CLASS_Viewable ...); each entry
  points at a widget record, 3,340 records in ROM per KN5000 maincpu tree
  (scripts/analysis/nakarest_objtab_map.py).  On 2026-10-02 only 507 of them had a label, so
  the tables that point at them were written as numbers -- 600-odd `.long 0x00E2841C` lines in
  effects_sequencer_screens.s alone -- or hidden inside `.incbin` slices.  And 55 of the
  NakaWidget_* labels contradicted the firmware: v10's NakaWidget_SmfDpFileList is an
  AcMuteToggleBox that the firmware itself calls "SMFMuteSw".

  The firmware names its records: a Viewable table in registry slot S has a ResName table in
  slot S + 0x300 whose entry k is the name string of element k (600 of the 3,340 are named; the
  rest are ""). So, per record:
    * NAME: NakaWidget_<ResName> when the firmware names it; otherwise
      NakaWidget_<Screen>_<k>_<Class> -- Screen the ResName of element 0 of the same table
      (the screen; 151 of the 209 tables name it), else <Module>View<slot>; k the element index
      (the object id is 0x01000000 | S << 16 | k); Class the record's class (its first word).
      A name two records would share takes _<slot>.
    * a record that has a label keeps it -- except a NakaWidget_* label that disagrees with
      the firmware's name and that the record's own captions do not support -- kept only when
      every caption word (3+ letters) appears in it by its first three letters, which keeps
      NakaWidget_PerfMainMedley (caption "Main Medley", firmware "DemoSong0") and renames
      NakaWidget_SmfMdlyContainer (caption "SMF DIRECT PLAY", firmware "DpSmfLyr"):
      those are renamed through scripts/renaming/rename_naka_records_<tree>.sed;
    * otherwise a label is placed (scripts/tools/place_labels.py: in front of the line, or by
      cutting the `.incbin` slice / list there); a positional alias (`X_0x1C, X + 28`) of the
      same address retires into it.
  Then every `.long` / `.4byte` value in the tree that is a numeric address with a column-0
  label (new or old) is written as that label.
  Labels and symbol spellings emit no byte: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/label_naka_records.py --tree v10 [--apply] [--report OUT.json]
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import nakarest_objtab_map as nom             # noqa: E402
import place_labels                           # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')
POSSET = re.compile(r'^\s*\.(?:set|equ)\s+(\w+_0x[0-9A-Fa-f]+)\s*,\s*[A-Za-z_][\w.$]*\s*\+\s*(?:0x[0-9a-fA-F]+|\d+)\s*(?:;.*)?$')
LONG = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*\.(?:long|4byte)\s+)(?P<items>[^;]*?)(?P<post>\s*(?:;.*)?)$')
IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')


def words(s):
    return [w.lower() for w in re.findall(r'[A-Za-z]{3,}', s or "")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    m = nom.Map(a.tree)
    elf, tree, (lo, hi) = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)                          # addr -> names (t and a)
    files = sorted(glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.s"), recursive=True))
    col0, possets = set(), {}
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            mm = COL0.match(l)
            if mm:
                col0.add(mm.group(1))
            mm = POSSET.match(l)
            if mm:
                possets[mm.group(1)] = f
    addr_of = {n: ad for ad, ns in syms.items() for n in ns}
    taken = set(addr_of)

    # ---- the wanted name of every record
    recs = []
    for r in m.regs:
        if nom.CLASS.get(r["cls"]) != "Viewable" or not m.inrom(r["table"]):
            continue
        rn = m.by_slot.get(r["slot"] + 0x300)
        nm = lambda k: (m.string_at(m.u32(rn["table"] + 4 * k)) if rn and k < rn["count"] else "") or ""
        screen = nm(0) if IDENT.match(nm(0) or "-") else "%sView%03X" % ((r["init"] or "Initialize")[10:], r["slot"])
        for k, e in enumerate(m.entries(r)):
            if not m.inrom(e):
                continue
            c = m.record_class(e)
            own = nm(k)
            if own and IDENT.match(own):
                want = "NakaWidget_" + own
            else:
                want = "NakaWidget_%s_%d_%s" % (screen, k, c["name"] if c else "Record")
            caps = []
            if c:
                for off, fname, ch in m.class_fields(c):
                    if ch == "X" and m.inrom(m.u32(e + off)):
                        caps.append(m.string_at(m.u32(e + off)))
            recs.append(dict(addr=e, slot=r["slot"], k=k, want=want, fw=own, caps=caps))
    cnt = collections.Counter(x["want"] for x in recs)
    for x in recs:
        if cnt[x["want"]] > 1:
            x["want"] = "%s_%03X" % (x["want"], x["slot"])

    # ---- decide per record
    stats, rows, renames, place = collections.Counter(), [], {}, {}
    for x in recs:
        have = [n for n in syms.get(x["addr"], []) if n in col0]
        if have:
            nw = [n for n in have if n.startswith("NakaWidget_")]
            if x["fw"] and nw and x["want"] not in have:
                old = nw[0]
                capw = set(w for cap in x["caps"] for w in words(cap))
                if capw and all(w[:3] in old.lower() for w in capw):
                    stats["kept: caption supports the old name"] += 1
                    rows.append(dict(addr=hex(x["addr"]), old=old, fw=x["fw"], result="kept (caption)", caps=x["caps"]))
                elif x["want"] in taken:
                    stats["kept: firmware name taken"] += 1
                else:
                    renames[old] = x["want"]
                    taken.add(x["want"])
                    stats["renamed to the firmware name"] += 1
                    rows.append(dict(addr=hex(x["addr"]), old=old, new=x["want"], result="renamed", caps=x["caps"]))
            else:
                stats["has a label"] += 1
            continue
        nm, kk = x["want"], 2
        while nm in taken:
            nm, kk = "%s_%d" % (x["want"], kk), kk + 1
        taken.add(nm)
        place[x["addr"]] = nm
    planner = place_labels.Planner(a.tree)
    placed, retire = {}, {}
    for ad, nm in sorted(place.items()):
        how = planner.add(ad, nm)
        stats["placed: " + how] += 1
        if how in ("line-start", "incbin", "list"):
            placed[ad] = nm
            for n in syms.get(ad, []):
                if n in possets:
                    retire[n] = nm
        rows.append(dict(addr=hex(ad), new=nm, result=how))
    stats["positional aliases retired"] = len(retire)

    # ---- numeric .long values that now have a label
    best = {}
    for ad, ns in syms.items():
        c = [n for n in ns if n in col0 and n not in retire]
        if c and lo <= ad <= hi:
            best[ad] = renames.get(fp.pick(c, col0), fp.pick(c, col0))
    best.update(placed)
    n_long = 0
    if a.apply:
        planner.apply()
        rp = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted({**renames, **retire}, key=len, reverse=True)))) \
            if (renames or retire) else None
        for f in files:
            L = open(f, "rb").read().decode("latin-1").split("\n")
            out = []
            for l in L:
                mm = POSSET.match(l)
                if mm and mm.group(1) in retire:
                    continue
                ml = LONG.match(l)
                if ml:
                    its = ml.group("items").split(",")
                    new = []
                    for it in its:
                        s = it.strip()
                        if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', s) and int(s, 0) in best:
                            new.append(it.replace(s, best[int(s, 0)]))
                            n_long += 1
                        else:
                            new.append(it)
                    l = ml.group("pre") + ",".join(new) + ml.group("post")
                if rp:
                    l = rp.sub(lambda q: {**renames, **retire}[q.group(1)], l)
                out.append(l)
            t = "\n".join(out)
            if t != "\n".join(L):
                open(f, "wb").write(t.encode("latin-1"))
        for p in sum((glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", g), recursive=True)
                      for g in ("*.c", "*.h", "*.ld")), []):     # the C blobs link against *_link.ld
            t = open(p, "rb").read().decode("latin-1")
            rpc = re.compile(r'(?<![\w$])(%s)(?![\w$])' % "|".join(map(re.escape, {**renames, **retire}))) if rp else None
            t2 = rpc.sub(lambda q: {**renames, **retire}[q.group(1)], t) if rpc else t   # `.member` too
            if t2 != t:
                open(p, "wb").write(t2.encode("latin-1"))
        if renames:
            with open(os.path.join(REPO, "scripts", "renaming", "rename_naka_records_%s.sed" % a.tree), "w") as s:
                s.write("# generated by scripts/tools/label_naka_records.py: NakaWidget_* labels that contradict\n"
                        "# the firmware's own ResName for the record (and no caption of it supports them).\n")
                for old, new in sorted(renames.items(), key=lambda kv: -len(kv[0])):
                    s.write("s/\\b%s\\b/%s/g\n" % (old, new))
        stats["numeric .long values symbolized"] = n_long
    print("%s: records %d; %s%s" % (a.tree, len(recs), dict(stats), "" if a.apply else " (dry run)"))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
