#!/usr/bin/env python3
"""name_naka_view_ids.py -- NAKA view (widget) object ids passed as event targets become NAKA_VIEW_<name>, not ROM addresses.

QUESTION THIS ANSWERS / JOB IT DOES
  A NAKA object id is (slot << 16) | entry.  Slots 0x00-0xFF are the Viewable tables
  (`RegObjTable NAKA_CLASS_Viewable, ViewableProc, count, table, S`), so a VIEW id is 0x00SSnnnn --
  and for S >= 0xE0 that is numerically a main-CPU ROM address.  Passes that symbolized ROM
  operands took such ids for pointers: on 2026-10-03, 52 `ld xwa, <id>` before an event post in v10
  read `ld xwa, IvAccordion_ShowHide_Data` (view "Accordion1", 0x00EB0009) and the like, with labels
  CREATED at those addresses; one v10 header even says "object handle 0xf8000c ... not an address"
  over `ld xwa, AudioCtrl_PageHandler_Code`.  The firmware names every view: the ResName table
  registered at slot S + 0x300 holds a u32 pointer to each entry's name ("TEST54", "MainTable").

  This finds, per tree:
    * `ld xwa, X` followed within six lines (a label in between allowed: AcWelcomScreen's
      `ld xwa / ld xbc, EVT_SHOW / ld xde / <label>: / call SendEvent`), or by one unconditional
      jump to a shared tail that makes the call (IvDrawbar's `jrl IvDrawbar_DispatchEvent`), by a
      call to an event routine (SendEvent, ApPostEvent,
      PostEvent, MainPostEvent, SeMenu_SendEvent, SwbtWr_QueuePostEvent -- XWA is the TARGET OBJECT)
      where X, a number or a label of the image, is a view id: slot S has a Viewable registration
      and entry n is below S + 0x300's count;
    * the view argument (the fifth) of RegTitle, when numeric and a view id -- and in v7, which
      expands the macro, the `ld xde, N` right before `call RegisterTitle`;
  defines `.equ NAKA_VIEW_<name>, 0x00SSnnnn` (the ResName string; `_<SS>` added when two views
  share it) in the tree's shared/event_codes.s, and rewrites those operands.  A label that loses
  its last use and is one a symbolizer made (`*_Data`, `*_Code`, `*_Data_N`, `*_Code_N`) is
  retired: the name goes, the line's directive stays.  Same bytes: make gate-all.

USAGE
  make all
  python3 scripts/tools/name_naka_view_ids.py --tree v10 [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import nakarest_objtab_map as M  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
VIEWABLE = 0x1600010
CALL = re.compile(r'^\s*(?:call|jp|jr|jrl)\s+(SendEvent|ApPostEvent|PostEvent|MainPostEvent|SeMenu_SendEvent|'
                  r'SwbtWr_QueuePostEvent)\b')     # a tail jump (`jp ApPostEvent`) posts too
LDXWA = re.compile(r'^(\s*ld\s+xwa\s*,\s*)([A-Za-z_][\w.$]*|0x[0-9a-fA-F]+|\d+)(\s*(?:;.*)?)$', re.I)
LDXDE = re.compile(r'^(\s*ld\s+xde\s*,\s*)(0x[0-9a-fA-F]+|\d+)(\s*(?:;.*)?)$', re.I)
REGCALL = re.compile(r'^\s*call\s+RegisterTitle\b')
REGTITLE = re.compile(r'^(\s*RegTitle\s+[^,]+,[^,]+,[^,]+,[^,]+,\s*)(0x[0-9a-fA-F]+|\d+)(\s*(?:;.*)?)$')
MADE = re.compile(r'_(Data|Code)(_\d+)?$')
BLOCK = "; ---- NAKA VIEW (widget) object ids"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = M.Map(a.tree)
    elf = os.path.join(REPO, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % a.tree)
    addr = {}
    for l in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True,
                            check=True).stdout.splitlines():
        v, t, n = l.split()
        addr[n] = (int(v, 16), t)

    def view(val):
        if not 0xE00000 <= val <= 0xFFFFFF:
            return None
        s, k = (val >> 16) & 0xFFF, val & 0xFFFF
        r, rn = m.by_slot.get(s), m.by_slot.get(s + 0x300)
        if not r or r.get("cls") != VIEWABLE or not rn or k >= rn["count"]:
            return None
        p = m.u32(rn["table"] + 4 * k)
        return m.string_at(p, 40) if m.inrom(p) else None

    files = sorted(glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.s"), recursive=True))
    text = {f: open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    where = {}
    for f, L in text.items():
        for i, l in enumerate(L):
            mm = re.match(r'^([A-Za-z_.][\w.$]*):', l)
            if mm:
                where[mm.group(1)] = (f, i)

    def posts(L, i):
        """an event call within six lines of line i, or within six lines of the target of one
        unconditional jr / jrl / jp met first (a shared `..._DispatchEvent:` tail)"""
        for x in L[i + 1:i + 7]:
            if CALL.match(x):
                return True
            j = re.match(r'^\s*(?:jr|jrl|jp)\s+([A-Za-z_.][\w.$]*)\s*(?:;.*)?$', x)
            if j and j.group(1) in where:
                f2, k = where[j.group(1)]
                return any(CALL.match(y) for y in text[f2][k + 1:k + 7])
        return False
    sites, ids = [], {}
    for f, L in text.items():
        for i, l in enumerate(L):
            g, how = LDXWA.match(l), "event target"
            if g and not posts(L, i):
                g = None
            if not g:
                g, how = REGTITLE.match(l), "RegTitle view"
            if not g:
                g, how = LDXDE.match(l), "RegisterTitle view (expanded, v7)"
                if g and not any(REGCALL.match(x) for x in L[i + 1:i + 3]):
                    g = None
            if not g:
                continue
            tok = g.group(2)
            if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', tok):
                val = int(tok, 0)
            elif tok in addr and addr[tok][1] in "tT" and not tok.startswith(("EVT_", "NAKA_", "TITLE_")):
                val = addr[tok][0]
            else:
                continue
            nm = view(val)
            if not nm:
                continue
            ids[val] = nm
            sites.append((f, i, g, val, tok, how))
    byname = collections.defaultdict(set)
    for val, nm in ids.items():
        byname[re.sub(r'\W', '_', nm)].add(val)
    const = {}
    for base, vals in byname.items():
        for val in vals:
            const[val] = "NAKA_VIEW_%s" % base if len(vals) == 1 else "NAKA_VIEW_%s_%02X" % (base, (val >> 16) & 0xFF)
    st = collections.Counter(("numeric" if re.match(r'^(0x|\d)', s[4]) else "ROM label") + ", " + s[5] for s in sites)
    replaced_labels = collections.Counter(s[4] for s in sites if not re.match(r'^(0x|\d)', s[4]))
    print("%s: %d sites, %d distinct view ids; %s" % (a.tree, len(sites), len(ids), dict(st)))
    if not a.apply:
        for val in sorted(ids):
            print("  0x%06x %-40s %s" % (val, const[val], ids[val]))
        return 0
    for f, i, g, val, tok, how in sites:
        text[f][i] = g.group(1) + const[val] + g.group(3)
    # retire symbolizer-made labels that lost their last use
    uses = collections.Counter()
    for L in text.values():
        for l in L:
            code = l.split(";")[0]
            code = re.sub(r'^[A-Za-z_.][\w.$]*:', '', code)
            for t in re.findall(r'[A-Za-z_.][\w.$]*', code):
                uses[t] += 1
    for extra in glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.[ch]"), recursive=True) + \
            glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.ld"), recursive=True):
        body = re.sub(r'/\*.*?\*/|//[^\n]*', ' ', open(extra, "rb").read().decode("latin-1"), flags=re.S)
        for t in re.findall(r'[A-Za-z_][\w$]*', body):
            uses[t] += 1
    retired = []
    for lab in replaced_labels:
        if uses[lab] == 0 and MADE.search(lab):
            for f, L in text.items():
                for i, l in enumerate(L):
                    if l is None:
                        continue
                    mm = re.match(r'^%s:(\s*)(.*)$' % re.escape(lab), l)
                    if mm:
                        L[i] = ("\t" + mm.group(2)) if mm.group(2).strip() else None
                        retired.append(lab)
    for f, L in text.items():
        text[f] = [x for x in L if x is not None]
    ev = os.path.join(REPO, a.tree, "maincpu", "shared", "event_codes.s")
    E = text[ev]
    # keep the views an earlier run defined (a re-run sees only what is still numeric)
    for x in E:
        mm = re.match(r'^\.equ (NAKA_VIEW_\w+), (0x[0-9a-fA-F]+)\s*; view "(.*)"', x)
        if mm and int(mm.group(2), 16) not in ids:
            ids[int(mm.group(2), 16)] = mm.group(3)
            const[int(mm.group(2), 16)] = mm.group(1)
    E = [x for x in E if not x.startswith(".equ NAKA_VIEW_")]
    if BLOCK not in "\n".join(E):
        E += ["", BLOCK + ": 0x00SSnnnn = entry nnnn of Viewable slot SS, named by the ResName",
              "; table registered at slot SS + 0x300 (scripts/tools/name_naka_view_ids.py)."]
    for val in sorted(ids):
        s, k = (val >> 16) & 0xFF, val & 0xFFFF
        E.append(".equ %s, 0x%06x\t; view \"%s\": Viewable slot 0x%02X entry %d" % (const[val], val, ids[val], s, k))
    text[ev] = E
    for f, L in text.items():
        new = "\n".join(L)
        if new != open(f, "rb").read().decode("latin-1"):
            open(f, "wb").write(new.encode("latin-1"))
    print("  retired %d symbolizer-made labels: %s" % (len(retired), " ".join(sorted(set(retired)))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
