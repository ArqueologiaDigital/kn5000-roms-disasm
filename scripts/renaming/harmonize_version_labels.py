#!/usr/bin/env python3
"""harmonize_version_labels.py -- give v7 (or v9) the v10 name of the same code.

QUESTION THIS ANSWERS / JOB IT DOES
  CLAUDE.md's cross-version policies want one name per thing in every version, so that a
  v10/v7 diff shows firmware changes and not naming noise.  The claims review of 2026-10-02
  kept meeting the opposite: v10's ScoopParam_ValueTable_Sub_Helper is v7's
  PerfMode_Handler_EvtB_Helper2_Helper8, v7's CC94 reader had no label at all.

  Correspondence, deterministically:
    * ANCHORS: every label defined, under the same name, in both images' linked ELFs.  For a
      v10 label between two consecutive anchors whose v10->v7 address deltas are EQUAL, the
      v7 address is the v10 address minus that delta.  An isolated anchor whose delta differs
      from both neighbours (which agree) is a same-named local placed elsewhere and is dropped;
    * PROOF: the 12 ROM bytes at the two addresses are identical, except where a 3-byte run is
      a ROM address in both (a call target or pointer the two builds place differently); any
      other difference skips the label.
  Then (a STRUCTURAL v10 name -- `X_Skip3` -- is used only when its parent X is v7's
  enclosing routine at that address too; otherwise the parents disagree, which is reported
  as "parent differs" and left for the parent's own correspondence):
    * v7 has a STRUCTURAL label there (`_Skip`, `_Helper3`, positional `_0x..`) under another
      name -> renamed to the v10 name, unless the v10 name is already defined in v7
      (reported) or several v10 names share the address (the first, by the same pick order
      as the symbolizers).  A v7 name that says something is never replaced: when v10's is
      structural it is reported as "target-name-better" (v10 should take v7's name), when
      both say something different, as "both-named-differently" -- a human's call, except when a reviewed
      proposal in analysis/kn5000-naming/ renamed exactly that old name to exactly this one in v10
      ("rename-by-proposal");
    * v7 has no label there -> the v10 label is inserted in front of the source line that
      emits that address (symbolize_numeric_branches.build_map: the census marker mirror,
      refused unless it reproduces the dump), when that line starts exactly there.
  Renames go through a generated sed script (project rule: batch renames are sed scripts),
  scripts/renaming/harmonize_<to>_from_<from>.sed, applied to the target tree only.
  Labels emit no bytes: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/renaming/harmonize_version_labels.py --to v7 [--from v10] [--apply] [--report OUT]
"""
import argparse
import bisect
import collections
import datetime
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Entry|Tail|Next|Done|Exit|End|'
                    r'Code|Data|Block|Sub|Case|Default)\d*$|_0x[0-9A-Fa-f]+$|^LABEL_|^sub_|^loc_')


def same_code(a, b):
    """Equal, except where a byte run is a 24-bit little-endian ROM address in BOTH (a call or
    a pointer the two builds place differently)."""
    if len(a) != len(b):
        return False
    i = 0
    while i < len(a):
        if a[i] == b[i]:
            i += 1
            continue
        for j in (i - 2, i - 1, i):
            if 0 <= j and j + 3 <= len(a):
                x, y = int.from_bytes(a[j:j + 3], "little"), int.from_bytes(b[j:j + 3], "little")
                if 0xE00000 <= x <= 0xFFFFFF and 0xE00000 <= y <= 0xFFFFFF:
                    i = j + 3
                    break
        else:
            return False
    return True


def syms(v):
    out = subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs",
                          "kn5000_%s_program.llvm.elf" % v)], capture_output=True, text=True,
                         check=True).stdout
    by, at = {}, collections.defaultdict(list)
    for l in out.splitlines():
        a, t, n = l.split()
        if n.startswith(".L"):
            continue
        a = int(a, 16)
        by[n] = a
        if t.lower() == "t":
            at[a].append(n)
    return by, at


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--to", required=True, choices=("v7", "v9", "v10"))
    ap.add_argument("--from", dest="frm", default="v10", choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    sF, aF = syms(a.frm)
    sT, aT = syms(a.to)
    rF = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % a.frm), "rb").read()
    rT = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % a.to), "rb").read()
    files = sorted(glob.glob(os.path.join(REPO, a.to, "maincpu", "**", "*.s"), recursive=True))
    col0T = set()
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_][\w.$]*):', l)
            if m:
                col0T.add(m.group(1))
    anch = sorted((sF[n], sF[n] - sT[n]) for n in sF
                  if n in sT and 0xE00000 <= sF[n] < 0x1000000 and n in col0T)
    # An anchor whose delta disagrees with both neighbours while they agree with each other is a
    # same-named local placed elsewhere in the target (v7's UIStateEvt_VoiceParamHandler_Skip3 is not
    # in the routine v10's is in); left in, it made every v10 label between its neighbours look
    # unanchored.  Drop such isolated outliers until none is left.
    while True:
        bad = {i for i in range(1, len(anch) - 1) if anch[i][1] != anch[i - 1][1]
               and anch[i][1] != anch[i + 1][1] and anch[i - 1][1] == anch[i + 1][1]}
        if not bad:
            break
        anch = [x for i, x in enumerate(anch) if i not in bad]
    keys = [x for x, _ in anch]
    stats, renames, inserts, rows = collections.Counter(), {}, {}, []
    # the enclosing routine of an address: nearest non-structural label at or before it
    def enclosing(at_map, addr):
        ks = sorted(at_map)
        idx = {}
        return ks
    def parent_of(at_sorted, at_map, addr):
        i = bisect.bisect_right(at_sorted, addr) - 1
        while i >= 0:
            ns = [n for n in at_map[at_sorted[i]] if not STRUCT.search(n)]
            if ns:
                return sorted(ns)
            i -= 1
        return []
    kF, kT = sorted(aF), sorted(aT)

    def stem(n):
        prev = None
        while prev != n:
            prev = n
            n = STRUCT.sub("", n)
        return n
    taken = set(sT) | col0T          # col0T too: the ELF can be older than the source
    proposed = {}
    for f in glob.glob(os.path.join(REPO, "analysis", "kn5000-naming", "proposals-*.json")):
        for r in json.load(open(f)):
            if isinstance(r, dict) and r.get("verdict", "name") == "name" and r.get("old") and r.get("new"):
                proposed[r["old"]] = r["new"]
    for A, names in sorted(aF.items()):
        k = bisect.bisect_right(keys, A) - 1
        if k < 0 or k + 1 >= len(anch) or anch[k][1] != anch[k + 1][1]:
            continue
        B = A - anch[k][1]
        oF, oT = A - 0xE00000, B - 0xE00000
        if not (0 <= oT < len(rT)) or not same_code(rF[oF:oF + 12], rT[oT:oT + 12]):
            continue
        namesF = sorted(names, key=lambda n: (bool(STRUCT.search(n)), len(n), n))
        nf = namesF[0]
        tn = [n for n in aT.get(B, []) if n in col0T]
        if nf in aT.get(B, []):
            stats["same"] += 1
            continue
        if STRUCT.search(nf) and stem(nf) not in parent_of(kT, aT, B):
            # v10's structural name hangs off a parent v7 calls something else (or places
            # elsewhere): the disagreement is at the parent, not here
            stats["parent-differs"] += 1
            rows.append({"addr": hex(A), "from": nf, "to_has": tn, "result": "parent differs",
                         "v7_parent": parent_of(kT, aT, B)[:1]})
            continue
        if nf in taken:
            stats["v10-name-taken-in-target"] += 1
            rows.append({"addr": hex(A), "from": nf, "to_has": tn, "result": "name taken"})
            continue
        if tn:
            old = sorted(tn, key=lambda n: (bool(STRUCT.search(n)), len(n), n))[0]
            if old in renames:
                continue
            if not STRUCT.search(old) and proposed.get(old) != nf:
                # the target's name says something: never trade it for another name here -- unless a reviewed
                # proposal (analysis/kn5000-naming/proposals-*.json) replaced exactly that old name with exactly
                # this one in v10: then the old name was shown wrong for this code (2026-10-06, owner renames
                # like EasyCmp_GridCheck -> AcEasyCmpGridBoxProc_OnGetFixedColStr)
                kind = "target-name-better" if STRUCT.search(nf) else "both-named-differently"
                stats[kind] += 1
                rows.append({"addr": hex(A), "from": nf, "old": old, "result": kind})
                continue
            renames[old] = nf
            taken.add(nf)
            kind = "rename" if STRUCT.search(old) else "rename-by-proposal"
            stats[kind] += 1
            rows.append({"addr": hex(A), "from": nf, "old": old, "result": kind})
        else:
            inserts[B] = nf
            taken.add(nf)
    # chains (a new name that is another rename's old name) are refused
    for old in list(renames):
        if renames[old] in renames:
            stats["refused-chain"] += 1
            del renames[old]
    # insertion points from the marker mirror
    if inserts:
        import symbolize_numeric_branches as snb
        img = snb.image_by_key(a.to)
        srcroot = os.path.join(REPO, img["mirror"])
        marks, addrs, spans, rom_ok, src, macros = snb.build_map(img, srcroot)
        if not rom_ok:
            sys.exit("marker mirror does not reproduce the dump: refusing")
        start_of = {s[0]: s for s in spans}
        texts = {}
        ins_at = collections.defaultdict(list)
        for B, nf in sorted(inserts.items()):
            sp = start_of.get(B)
            if not sp:
                stats["insert-mid-line"] += 1
                continue
            ins_at[sp[2]].append((sp[3], nf))
            stats["insert"] += 1
            rows.append({"addr_to": hex(B), "from": nf, "result": "insert", "at": "%s:%d" % (sp[2], sp[3] + 1)})
    sed = os.path.join(REPO, "scripts", "renaming", "harmonize_%s_from_%s.sed" % (a.to, a.frm))
    run_sed = None
    if a.apply and renames:
        # this run's renames go to a scratch sed that is applied, and are APPENDED to the record: the record keeps
        # every earlier run (rename_orphan_locals.py follows those chains), but re-applying an old line could rename
        # a label that later reused the old name, so only this run's lines are ever applied
        lines = ["s/\\b%s\\b/%s/g\n" % (re.escape(old), new)
                 for old, new in sorted(renames.items(), key=lambda kv: -len(kv[0]))]
        fd, run_sed = tempfile.mkstemp(suffix=".sed")
        with os.fdopen(fd, "w") as s:
            s.writelines(lines)
        fresh = not os.path.exists(sed)
        with open(sed, "a") as s:
            if fresh:
                s.write("# generated by scripts/renaming/harmonize_version_labels.py: %s labels renamed to the\n"
                        "# %s name of the same code (anchor deltas + 12 identical ROM bytes).\n" % (a.to, a.frm))
            s.write("# run %s\n" % datetime.date.today().isoformat())
            s.writelines(lines)
    if a.apply and inserts:
        for rel, items in ins_at.items():
            p = os.path.join(srcroot, rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for li, nf in sorted(items, key=lambda x: -x[0]):
                L.insert(li, "%s:" % nf)
            open(p, "wb").write("\n".join(L).encode("latin-1"))
    if a.apply and renames:
        # the link scripts too: a NAKA_ADDR(name) in a C blob is defined by its <stem>_link.ld (2026-10-06: the C was
        # renamed and the .ld kept the old name, so v9/v7's naka_extension_device failed to link)
        targets = [f for f in files] + glob.glob(os.path.join(REPO, a.to, "maincpu", "**", "*.ld"), recursive=True)
        subprocess.run(["sed", "-i", "-f", run_sed] + targets, check=True)
        os.unlink(run_sed)
        # C: code segments only -- a name quoted in a C comment stays, as the C comment gate requires
        # (2026-10-06: a whole-text sed renamed one inside a v9 comment)
        sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
        from name_resname_strings import segments
        rx = re.compile(r'\b(%s)\b' % "|".join(sorted(map(re.escape, renames), key=len, reverse=True)))
        for f in glob.glob(os.path.join(REPO, a.to, "maincpu", "**", "*.c"), recursive=True):
            txt = open(f, "rb").read().decode("latin-1")
            new_txt = "".join(rx.sub(lambda mm: renames[mm.group(1)], s) if k == "code" else s for k, s in segments(txt))
            if new_txt != txt:
                data = new_txt.encode("latin-1")
                with open(f + ".tmp", "wb") as fh:
                    fh.write(data)
                os.replace(f + ".tmp", f)
    print("%s <- %s: %s%s" % (a.to, a.frm, dict(stats), "" if a.apply else " (dry run)"))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
