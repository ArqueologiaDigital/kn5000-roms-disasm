#!/usr/bin/env python3
"""fix_v7_displaced_names.py -- give each v7 address in the 0x41A band the name v10 gives the same code.

QUESTION IT ANSWERS / WHAT IT DOES
  In v7 0xFCC000-0xFF2000 many labels carry the name v10 gives to code 0x41A bytes EARLIER in v7: an old port
  placed v10's names at v10 - 0x3B7 where the code is at v10 - 0x7D1 (ce32defb5 measured it and fixed three midi
  files, keeping 54 old names that other files used, each with a `v7 NAME DISPLACED` note).  Example: v7's
  `Free_Compare2` (0xFF0770, 422 references) is v10's `Strcpy` -- same bytes -- while v7's `Strcpy` label is at
  0xFF0B8A.  The ROM is byte-identical either way; only the names are permuted.

  The correspondence is measured, not assumed.  Every 12-byte sequence that occurs exactly once in each ROM is an
  anchor (v7 a <-> v10 a + d); runs of >= 8 anchors with one d, at most 0x400 apart, are segments (a few anchors
  with another d are noise: v7's ReallocEnabledVoices copies CollectEnabledVoices, which gives a 0x126 cluster).
  A v7 address has the counterpart a + d when it lies in a segment of that d, or between two segments of that d
  at most 0x400 apart, or else when its first 8 bytes agree with v10's at a + d (d of a neighbouring segment) at
  >= 6 positions including the first, or its first 16 at >= 12 (absolute operands differ between the versions).

  For every v7 symbol site in the band whose counterpart is known:
    * v10 names it and none of v10's names is a v7 name there -> RENAME: the site's first v7 name becomes v10's
      name, a second v7 name (alias) is dropped and its references take the same new name.  By site, so every
      reference keeps its address (`X + N` becomes `Y + N`);
    * v10 does not name it, and a v7 name there is a v10 name whose code is elsewhere -> VACATE: the definition goes
      and each reference `X +/- N` is respelled from the final labels (the label at the target, else the nearest
      symbol before it + offset);
    * a v10 name whose v7 home (v10 address - d) is an unnamed v7 row start, and which is free in v7 after the
      above -> INSERT a label there.
  The renames are one simultaneous token map over the code of v7's .s/.c/.h files (X->Y and Y->X can coexist), so
  the image is unchanged.  Comments are left alone (they mostly name routines by v10's name, which is now v7's),
  except a comment that pairs a renamed name with its OLD v7 address (`X (0xFEA45D)`), which describes that site
  and takes the site's new name.  The `v7 NAME DISPLACED` notes and the `v10 name for this address: X -- not a
  label here` notes whose name is now placed are removed.

RUN (repository root; built tree; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/fix_v7_displaced_names.py            # report
  python3 scripts/tools/fix_v7_displaced_names.py --apply    # then make all; regenerate symbols
  python3 scripts/tools/fix_v7_displaced_names.py --audit    # exit 1 if a band name is away from v10's code of it
"""
import bisect
import collections
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
VERBOSE = "-v" in sys.argv
AUDIT = "--audit" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000
K = 12
BAND = (0xFCC000, 0xFF2000)
# sites the byte alignment cannot pair (v7's code differs) but a table slot does: address -> (v10 name, basis)
SLOT = {0xFEF1CF: ("SendPartDataBlock_DoGetError",
                   "SoundRam_HandlerTable[2] in both versions; v7's body is v10's tail without the "
                   "SubCPU_Payload_GetErrorFlag check")}
TOK = r'[A-Za-z_]\w*'
OFF = re.compile(r'\s*([-+])\s*(0x[0-9a-fA-F]+|\d+)\b')
BRANCH = re.compile(r'^\s*(?:[A-Za-z_]\w*:)?\s*(jr|jrl|jp|call|calr|djnz)\b', re.I)


def syms(tree):
    out = subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % tree)],
                         capture_output=True, text=True, check=True).stdout
    d = {}
    for line in out.splitlines():
        f = line.split()
        if len(f) == 3 and f[1] in "tT":
            d[f[2]] = int(f[0], 16)
    return d


def anchors(r7, r10):
    def uniq(r):
        c = {}
        for i in range(len(r) - K):
            g = r[i:i + K]
            c[g] = -1 if g in c else i
        return c
    u10 = uniq(r10)
    return sorted((i + B, u10[g] - i) for g, i in uniq(r7).items()
                  if i >= 0 and len(set(g)) >= 4 and u10.get(g, -1) >= 0)


def segments(anch):
    segs = []
    for a, d in anch:
        if segs and segs[-1][2] == d and a - segs[-1][1] < 0x400:
            segs[-1][1] = a
            segs[-1][3] += 1
        else:
            segs.append([a, a, d, 1])
    return [s for s in segs if s[3] >= 8]


def correspondence():
    """the measured v7 <-> v10 map: (s10, s7, at10, at7, delta7, home7)"""
    s10, s7 = syms("v10"), syms("v7")
    r10 = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    r7 = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    segs = segments(anchors(r7, r10))
    at10, at7 = collections.defaultdict(list), collections.defaultdict(list)
    for n, a in s10.items():
        at10[a].append(n)
    for n, a in s7.items():
        at7[a].append(n)

    def agree(a7, a10):
        x, y = r7[a7 - B:a7 - B + 16], r10[a10 - B:a10 - B + 16]
        same = [p == q for p, q in zip(x, y)]
        return x[:1] == y[:1] and (sum(same[:8]) >= 6 or sum(same) >= 12)

    starts = [sg[0] for sg in segs]

    def delta7(a7):                            # v7 address -> d, or None
        ds = {sg[2] for sg in segs if sg[0] <= a7 <= sg[1]}
        if ds:
            return ds.pop() if len(ds) == 1 else None
        k = bisect.bisect_right(starts, a7)    # a7 is between segs[k-1] and segs[k]
        prv = segs[k - 1] if k > 0 else None
        nxt = segs[k] if k < len(segs) else None
        if prv and nxt and prv[2] == nxt[2] and nxt[0] - prv[1] <= 0x400:
            return prv[2]
        for sg in (prv, nxt):
            if sg and agree(a7, a7 + sg[2]):
                return sg[2]
        return None

    seg10 = sorted((s[0] + s[2], s[1] + s[2], s[2]) for s in segs)
    starts10 = [sg[0] for sg in seg10]

    def home7(name):                           # v7 address of v10's code of `name`, or None
        a10 = s10.get(name)
        if a10 is None:
            return None
        ds = [d for lo, hi, d in seg10 if lo - 0x40 <= a10 <= hi + 0x40]
        k = bisect.bisect_right(starts10, a10)  # else the segments on either side, in v10 addresses
        ds += [seg10[j][2] for j in (k - 1, k) if 0 <= j < len(seg10)]
        for d in dict.fromkeys(ds):
            if delta7(a10 - d) == d:
                return a10 - d
        return None

    return s10, s7, at10, at7, delta7, home7


def main():
    s10, s7, at10, at7, delta7, home7 = correspondence()
    if AUDIT:
        return audit(s7, home7)

    # v7 source: files and definitions (name -> (file, line index, kind))
    root = os.path.join(REPO, "v7/maincpu")
    files, defs = {}, {}
    for dp, _, fs in os.walk(root):
        for f in sorted(fs):
            if f.endswith((".s", ".c", ".h")):
                p = os.path.join(dp, f)
                rel = os.path.relpath(p, root)
                files[rel] = open(p, "rb").read().decode("latin-1").split("\n")
                if f.endswith(".s"):
                    for i, line in enumerate(files[rel]):
                        m = re.match(r'^(' + TOK + r'):', line)
                        if m:
                            defs[m.group(1)] = (rel, i, "label")
                        m = re.match(r'^\s*\.set\s+(' + TOK + r')\s*,', line)
                        if m:
                            defs[m.group(1)] = (rel, i, "set")

    v10mid = {}                                 # v10 names defined `.set X, . + k` (mid-instruction)
    for dp, _, fs in os.walk(os.path.join(REPO, "v10/maincpu")):
        for f in fs:
            if f.endswith(".s"):
                for line in open(os.path.join(dp, f), "rb").read().decode("latin-1").split("\n"):
                    m = re.match(r'^\s*\.set\s+(' + TOK + r')\s*,\s*\.\s*\+\s*(\d+)\b', line)
                    if m:
                        v10mid[m.group(1)] = int(m.group(2))

    ren, drop, vacate, report = {}, set(), {}, collections.Counter()
    measured = {}                               # name -> the v7 address the measurement gives it
    for a in sorted(x for x in at7 if BAND[0] <= x < BAND[1]):
        d = delta7(a)
        n7 = sorted(at7[a], key=lambda n: (defs.get(n, ("", 0, "z"))[2] != "label", n))
        if a in SLOT:
            n10 = [SLOT[a][0]]
        elif d is None:
            report["no counterpart"] += 1
            for x in n7:                       # a v10 name whose code is measured elsewhere still leaves
                h = home7(x)
                if h is not None and h != a:
                    vacate[x] = a
                    drop.add(x)
                    report["vacated name (site without counterpart)"] += 1
            continue
        else:
            n10 = sorted(at10.get(a + d, []), key=lambda n: (n not in s7, n))
        common = [x for x in n7 if x in n10]
        if common:
            report["same"] += 1
            for x in common:
                measured[x] = a
            for x in n7:
                h = home7(x) if x not in n10 else None
                if h is not None and h != a:     # a displaced second name of a correct site
                    ren[x] = common[0]
                    drop.add(x)
                    report["displaced alias dropped"] += 1
            continue
        if n10:
            report["renamed site"] += 1
            ren[n7[0]] = n10[0]
            measured[n10[0]] = a
            for x in n7[1:]:
                ren[x] = n10[0]
                drop.add(x)
            continue
        for x in n7:
            h = home7(x)
            if h is not None and h != a:
                vacate[x] = a
                drop.add(x)
                report["vacated name"] += 1

    # a `v7 NAME DISPLACED` name that v10 does not have and nothing references is dropped with its note
    noted = set()
    for rel, L in files.items():
        if rel.endswith(".s"):
            for line in L:
                m = re.match(r'^\s*; v7 NAME DISPLACED: `(' + TOK + r')`', line)
                if m:
                    noted.add(m.group(1))
    for x in sorted(noted):
        if x in s7 and x not in s10 and x not in drop and BAND[0] <= s7[x] < BAND[1]:
            used = sum(1 for rel, L in files.items() for i, line in enumerate(L)
                       if re.search(r'\b%s\b' % x, line.split(";", 1)[0] if rel.endswith(".s")
                                    else re.sub(r'/\*.*?\*/|//.*', '', line))
                       and defs.get(x, (None, None))[:2] != (rel, i))
            if not used:
                drop.add(x)
                report["unreferenced displaced alias dropped"] += 1

    # a name the measurement puts elsewhere leaves a site the measurement could not read
    for n, a in s7.items():
        if n in drop or n in ren or not (BAND[0] <= a < BAND[1]):
            continue
        if n in measured and measured[n] != a:
            other = [x for x in at7[a] if x != n and x not in drop]
            if other:
                ren[n] = ren.get(other[0], other[0])
                drop.add(n)
                report["unmeasured alias dropped"] += 1
            else:
                vacate[n] = a
                drop.add(n)
                report["unmeasured site vacated"] += 1

    # final symbol table: address -> names
    final = collections.defaultdict(list)
    for n, a in s7.items():
        if n in drop:
            continue
        final[a].append(ren.get(n, n))
    placed = {n for ns in final.values() for n in ns}
    m7 = census.load("v7")
    insert = {}
    unplaced = []
    for n in sorted(set(vacate) | set(ren) | set(ren.values())):
        if n in placed or n not in s10:
            continue
        h = home7(n)
        if h is None or final.get(h) or h in insert:
            unplaced.append((n, h, "no v7 home" if h is None else "home named %s" % "/".join(final.get(h, ["?"]))))
            continue
        r = census.find(m7, h)
        if r and r[0] == h and (census.is_insn_row("v7", r) or r[4] == "data"):
            insert[h] = (n, r[2], r[3], n + ":")
            final[h].append(n)
            placed.add(n)
        elif r and census.is_insn_row("v7", r) and v10mid.get(n) == h - r[0]:
            # v10 defines the name mid-instruction too (`.set X, . + k`): the same spelling in v7
            insert[h] = (n, r[2], r[3], "\t.set\t%s, . + %d\t; no instruction starts here, as in v10: the name points "
                         "%d byte(s) into the one below" % (n, h - r[0], h - r[0]))
            final[h].append(n)
            placed.add(n)
        else:
            unplaced.append((n, h, "home is not a row start"))
    faddr = sorted(final)

    def spell(t, avoid=None):
        names = [n for n in final.get(t, []) if n != avoid]
        if names:
            return names[0]
        k = bisect.bisect_right(faddr, t) - 1
        while k >= 0 and not [n for n in final[faddr[k]] if n != avoid]:
            k -= 1
        p = faddr[k]
        return "%s + %d" % ([n for n in final[p] if n != avoid][0], t - p)

    # rewrite code tokens
    tokmap = {x: y for x, y in ren.items()}
    alln = sorted(set(tokmap) | set(vacate), key=len, reverse=True)
    pat = re.compile(r'\b(' + "|".join(map(re.escape, alln)) + r')\b' if alln else r'(?!x)x')
    oldaddr = {x: s7[x] for x in alln}
    edits, needlabel, dup = {}, [], []
    stats = collections.Counter()
    for x in vacate:
        for rel, L in files.items():
            if not rel.endswith(".s") and any(re.search(r'\b%s\b' % x, re.sub(r'/\*.*?\*/|//.*', '', ln)) for ln in L):
                assert x in placed, ("a C file names vacated %s, which is not placed again" % x, rel)

    def sub_code(code, branch, is_c, avoid=None):
        out, pos = [], 0
        for m in pat.finditer(code):
            x = m.group(1)
            out.append(code[pos:m.start()])
            pos = m.end()
            if x in vacate:
                if is_c:
                    out.append(x)                       # the name is placed again (asserted above)
                    continue
                mo = OFF.match(code, pos)
                n = 0
                if mo:
                    n = int(mo.group(2), 0) * (1 if mo.group(1) == "+" else -1)
                    pos = mo.end()
                t = vacate[x] + n
                s_ = spell(t, avoid)
                if branch and "+" in s_:
                    needlabel.append((x, t))
                out.append(s_)
            else:
                out.append(tokmap[x])
        out.append(code[pos:])
        return "".join(out)

    LONG = re.compile(r'^(\s*(?:' + TOK + r':)?\s*\.long\s+)(.*?)(\s*)$')
    OPND = re.compile(r'\b(' + TOK + r')\b(' + OFF.pattern + r')?')

    def sub_long(code):
        """a `.long` operand whose target (old address + offset) is in the band and has a final name takes it"""
        m = LONG.match(code)

        def one(mo):
            x = mo.group(1)
            if x not in s7:
                return mo.group(0)
            n = int(mo.group(4), 0) * (1 if mo.group(3) == "+" else -1) if mo.group(2) else 0
            t = s7[x] + n
            if BAND[0] <= t < BAND[1] and final.get(t):
                if final[t][0] != (tokmap.get(x, x) if not n else None):
                    stats["table entries respelled"] += 1 if (n or x in tokmap or x in vacate) else 0
                return final[t][0]
            return sub_code(mo.group(0), False, False) if pat.search(mo.group(0)) else mo.group(0)
        return m.group(1) + OPND.sub(one, m.group(2)) + m.group(3)

    resolved = set(ren) | set(vacate)             # names whose old site this run changed
    placed_now = {v[0] for v in insert.values()} | set(ren.values())   # names this run put at their v10 code
    final_at = {n: a for a, ns in final.items() for n in ns}

    def at_home(x):                            # x ends up exactly at the v7 code v10 gives that name
        return x in final_at and home7(x) == final_at[x]
    DISPLACED = re.compile(r'^\s*; v7 NAME DISPLACED: `(' + TOK + r')`')
    CONT = re.compile(r'^\s*; (correct framing \(v10|file references this address by this name|'
                      r'The v7 code v10 calls `|Kept because another v7 file references this address)')
    KEPT = re.compile(r'^\s*; (' + TOK + r') is kept at this address only for ')
    V10NAME = re.compile(r'^\s*; v10 name for this address: (' + TOK + r') -- not a label here')
    HINT = re.compile(r'\s*;\s*no label at this \w+(?: \w+)? yet; v10: (' + TOK + r')\s*$')
    insert_at = collections.defaultdict(list)
    for h, (n, f, li, text) in insert.items():
        insert_at[(f, li)].append(text)
    for rel, L in files.items():
        new = []
        is_s = rel.endswith(".s")
        changed = False
        in_note = False
        for i, line in enumerate(L):
            for text in insert_at.get((rel, i), ()):
                new.append(text)
                changed = True
            m = re.match(r'^(' + TOK + r'):', line) if is_s else None
            ms = re.match(r'^\s*\.set\s+(' + TOK + r')\s*,', line) if is_s else None
            dn = (m or ms).group(1) if (m or ms) else None
            if dn in drop and defs.get(dn, (None, None))[:2] == (rel, i):
                rest = line[m.end():] if m else ""
                changed = True
                if m and rest.strip() and not rest.strip().startswith(";"):
                    line = "\t" + rest.lstrip()          # `X:\tinsn` -> keep the instruction
                else:
                    continue
            if is_s:
                md = DISPLACED.match(line)
                if md and (md.group(1) in resolved or md.group(1) in drop or at_home(md.group(1))):
                    in_note = True
                    changed = True
                    stats["notes removed"] += 1
                    continue
                if in_note and CONT.match(line):
                    continue
                in_note = False
                mk = KEPT.match(line)
                mv = V10NAME.match(line)
                if mk and (mk.group(1) in resolved or at_home(mk.group(1))) or mv and mv.group(1) in placed_now:
                    changed = True
                    stats["notes removed"] += 1
                    continue
                code, sep, cmt = line.partition(";")
            else:
                code, cmt, sep = line, "", ""
                if "/*" in line or line.lstrip().startswith("*") or "//" in line:
                    # C: only touch the code before a comment
                    j = min([k for k in (line.find("/*"), line.find("//")) if k >= 0] or [len(line)])
                    if line.lstrip().startswith("*"):
                        j = 0
                    code, cmt, sep = line[:j], line[j:], ""
            if is_s and LONG.match(code):
                nc = sub_long(code)
                mh = HINT.match(sep + cmt) if sep else None
                if mh and re.match(r'^\s*(?:' + TOK + r':)?\s*\.long\s+(' + TOK + r')\s*$', nc):
                    label = re.match(r'^\s*(?:' + TOK + r':)?\s*\.long\s+(' + TOK + r')\s*$', nc).group(1)
                    if label == mh.group(1):
                        sep, cmt = "", ""
                        nc = nc.rstrip()
                        stats["hint comments resolved"] += 1
                    else:
                        stats["hint names a different label"] += 1
                        if VERBOSE:
                            print("  HINT %s:%d label %s, hint %s" % (rel, i + 1, label, mh.group(1)))
            else:
                nc = sub_code(code, bool(BRANCH.match(code)), not is_s, ms.group(1) if ms else None) \
                    if pat.search(code) else code
            if is_s and cmt and pat.search(cmt):
                def csub(m):
                    x = m.group(1)
                    tail = cmt[m.end():m.end() + 14]
                    ma = re.match(r'\s*\(?\s*(?:v7\s+)?0x([0-9A-Fa-f]{6})\b', tail)
                    if ma and int(ma.group(1), 16) == oldaddr[x]:
                        if x in vacate:
                            return spell(vacate[x])
                        return tokmap[x]
                    return x
                nm2 = pat.sub(csub, cmt)
                if nm2 != cmt:
                    stats["comment sites"] += 1
                cmt = nm2
            nl = nc + (sep + cmt if is_s else cmt)
            if nl != line:
                changed = True
            new.append(nl)
        if changed:
            edits[rel] = new
    newdefs = collections.Counter()
    for a, ns in final.items():
        for n in ns:
            newdefs[n] += 1
    dup = sorted(n for n, c in newdefs.items() if c > 1)

    print("v7 band 0x%06X-0x%06X: %s" % (BAND[0], BAND[1], dict(report)))
    print("renamed %d, dropped aliases %d, vacated %d, inserted %d, duplicate names %d, "
          "branch operands left as Label+N %d; %s"
          % (len(ren), len(drop - set(vacate)), len(vacate), len(insert), len(dup), len(needlabel), dict(stats)))
    if VERBOSE:
        for x, y in sorted(ren.items(), key=lambda kv: s7[kv[0]]):
            print("  %06X %-48s -> %s%s" % (s7[x], x, y, "  (alias dropped)" if x in drop else ""))
        for x, a in sorted(vacate.items(), key=lambda kv: kv[1]):
            print("  %06X %-48s vacated (v10's code of it is v7 0x%06X)" % (a, x, home7(x)))
        for h, (n, f, li, text) in sorted(insert.items()):
            print("  %06X + %-46s %s:%d%s" % (h, n, f, li + 1, "  (.set mid-instruction)" if ".set" in text else ""))
    for n, h, why in unplaced:
        print("  NOT PLACED %-44s %s  (%s)" % (n, "0x%06X" % h if h else "", why))
    for n in dup:
        print("  DUP", n, [hex(a) for a, ns in final.items() if n in ns])
    for x, t in needlabel:
        print("  BRANCH to vacated %s -> 0x%06X has no label" % (x, t))
    if not APPLY:
        return
    assert not dup and not needlabel
    for rel, L in edits.items():
        p = os.path.join(root, rel)
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
    print("wrote %d files" % len(edits))



def audit(s7, home7):
    """every v7 name of the band that is also a v10 name: at the v7 home of v10's code, or not measurable"""
    bad = []
    for n, a in sorted(s7.items(), key=lambda kv: kv[1]):
        if BAND[0] <= a < BAND[1]:
            h = home7(n)
            if h is not None and h != a:
                bad.append((a, n, h))
    for a, n, h in bad:
        print("  0x%06X %-48s v10's code of it is v7 0x%06X" % (a, n, h))
    print("v7 band: %d names away from v10's code of them" % len(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
