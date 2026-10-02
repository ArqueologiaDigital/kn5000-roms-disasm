#!/usr/bin/env python3
"""fix_unreached_naka_headers.py -- rewrite the nakarest "nothing points into" headers the tables contradict.

QUESTION THIS ANSWERS / JOB IT DOES
  The nakarest lane wrote, for 22 spans per KN5000 maincpu tree, "purpose not established: N B
  at 0xADDR that no registered NAKA table, symbol, 24/32-bit literal or data word points into".
  The claims review of 2026-10-02 (open items 39, 40) found two of them inside registered tables
  after all; nakarest_objtab_map.py (whose registry parser had stopped seeing the NAKA_CLASS_*
  spellings -- fixed the same day) places 16 of the 22 exactly:
    CLASSDEF    bytes 4..23 of a 24-byte class definition whose proc word ends the slice before
                (5 per tree);
    TERMINATOR  entry <count> of a name table: a pointer to the empty string right after it --
                every ResName table and every Function/ApFunction/MainFunction NAME table ends so;
    ZERO        a zero word after the last entry -- every Viewable, ResEvent and ResMethod table,
                and every Function/ApFunction/MainFunction code table, ends so.  Measured over
                v10's 496 registered non-Class tables: Viewable 209, ResEvent 10, ResMethod 10
                and the 29 function code tables end in a zero word; ResName 209 and the 29
                function name tables in the pointer to an empty string; no table ends otherwise;
  and four more are the rest of the pointer table just above them: the slice above is labelled
  after its reader and says "K x 32-bit pointer" but holds only the first entries, and the span
  starts a second, unreferenced label.  Those are MERGED: the two slices become one under the
  reader's name, the second label goes, and comments that cited it cite the table.
  The remaining pointer-table spans whose words are all ROM pointers or zero are described as
  slots of the table they continue (PTRTAIL); spans that a later pass split into labelled pieces
  which code or data uses (v7: 19) say so.  Anything else is left alone and reported.
  Then every `EmbeddedPtrTable_<tree>_<blob>_<offset>:` label -- a positional name that the
  `.long` conversion of a slice left in the middle of a pointer table, read by nothing -- retires
  into the table it is part of: the label at the same address, else the nearest preceding label
  from which every word up to it is a ROM pointer or zero.  Its mentions in comments follow.
  Files the top-level source never includes are skipped (they are not assembled).
  Comments and labels emit no bytes: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/fix_unreached_naka_headers.py --tree v10 [--apply]
"""
import argparse
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import nakarest_objtab_map as nom  # noqa: E402

HDR = re.compile(r'^; \[nakarest\] purpose not established: (\d+) B at (0x[0-9a-f]+) that no registered.*$')
TITLE = re.compile(r'^; \[nakarest\] (\S+)\s+\+0x[0-9a-f]+\.\.\+0x[0-9a-f]+ \((0x[0-9a-f]+), (\d+) B\)\s*$')
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')
PTRSLICE = re.compile(r'^(?P<lab>[A-Za-z_][\w.$]*):(?P<ws>\s*)\.incbin\s+"(?P<f>[^"]+)",\s*(?P<o>0x[0-9A-Fa-f]+),\s*(?P<n>0x[0-9A-Fa-f]+)(?P<cws>\s*); (?P<k>\d+) x 32-bit pointer\s*$')
BARE = re.compile(r'^\s*\.incbin\s+"(?P<f>[^"]+)",\s*(?P<o>0x[0-9A-Fa-f]+),\s*(?P<n>0x[0-9A-Fa-f]+)\s*$')
INCLUDE = re.compile(r'^(?:[A-Za-z_][\w.$]*:)?\s*\.include\s+"([^"]+)"')
NAMES = ("ResName", "Function", "ApFunction", "MainFunction")


def assembled(tree):
    top = os.path.join(REPO, tree, "maincpu", "kn5000_%s_program.s" % tree)
    root, seen, stack = os.path.dirname(top), set(), [top]
    while stack:
        f = stack.pop()
        if f in seen or not os.path.exists(f):
            continue
        seen.add(f)
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = INCLUDE.match(l)
            if m:
                for base in (os.path.dirname(f), root):
                    p = os.path.normpath(os.path.join(base, m.group(1)))
                    if os.path.exists(p):
                        stack.append(p)
                        break
    return seen


def classify(m, a, n):
    for r in m.regs:
        name = nom.CLASS.get(r["cls"])
        if not name or not m.inrom(r["table"]):
            continue
        T, cnt = r["table"], r["count"]
        where = "%s slot 0x%x (table 0x%06x, %d entries, %s)" % (name, r["slot"], T, cnt, r["init"])
        if name == "Class" and T <= a < T + 24 * cnt and (a - T) % 24 == 4 and n == 20:
            k = (a - T) // 24
            c = m.classes.get(((r["slot"] & 0xFFF) << 16) | k)
            return ("; [nakarest] bytes 4-23 of class definition %d (%s) of %s: its parent, allsize, "
                    "selfsize, name, propdata and propname; its proc word, bytes 0-3, ends the slice "
                    "before." % (k, c["name"] if c else "?", where))
        if name != "Class" and a == T + 4 * cnt and n in (4, 6):
            w = m.u32(a)
            tail = m.rom[w - nom.BASE:w - nom.BASE + 2] if m.inrom(w) else b""
            if w == a + 4 and tail == b"\0\xff":
                return ("; [nakarest] %d B at 0x%06x: the end marker of %s -- entry %d, a pointer to "
                        "the empty string right after it (\"\", 00 ff%s), as every %s ends."
                        % (n, a, where, cnt, "" if n == 6 else ", which starts the next slice",
                           "ResName table" if name == "ResName" else "function name table"))
            if w == 0 and n == 4:
                return ("; [nakarest] 4 B at 0x%06x: the end marker of %s -- a zero word after "
                        "entry %d, the last, as every %s table ends." % (a, where, cnt - 1, name))
    return None


def ptrtail(m, syms_before, a, n):
    """The span continues a table of 32-bit ROM pointers (then zero words) that starts at the
    nearest preceding symbol B: every word from B to the span's end is a pointer or 0."""
    for B, name in syms_before:
        words = [m.u32(x) for x in range(B, a + n, 4)]
        if (a - B) % 4 or not words or not all(w == 0 or m.inrom(w) for w in words):
            continue
        used = next((i for i, w in enumerate(words) if w == 0), len(words))
        if used == 0 or any(words[used:]) is True:
            continue
        i0, i1 = (a - B) // 4, (a + n - B) // 4 - 1
        p = [i for i in range(i0, i1 + 1) if words[i]]
        z = [i for i in range(i0, i1 + 1) if not words[i]]
        part = []
        if p:
            part.append("entries %d-%d of %s (pointers)" % (p[0], p[-1], name))
        if z:
            part.append("%s%d zero words (slots %d-%d)" % ("then " if p else "", len(z), z[0], z[-1]))
        return ("; [nakarest] %d B at 0x%06x: %s.  %s holds %d pointers from 0x%06x, then zero "
                "words; its readers index it from there." % (n, a, ", ".join(part), name, used, B))
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = nom.Map(a.tree)
    live = assembled(a.tree)
    files = sorted(glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.s"), recursive=True))
    texts = {f: open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    alltext = "\n".join("\n".join(L) for L in texts.values())

    def refs(name):
        return [l for l in re.findall(r'^.*(?<![\w.$])%s(?![\w$]).*$' % re.escape(name), alltext, re.M)
                if not l.startswith(name + ":") and "[nakarest]" not in l]
    retire, stats = {}, {}
    for f in files:
        L = texts[f]
        if os.path.normpath(f) not in live:
            if any(HDR.match(l) for l in L):
                stats["skipped (file not assembled)"] = stats.get("skipped (file not assembled)", 0) + 1
            continue
        i = 0
        while i < len(L):
            h = HDR.match(L[i])
            if not h:
                i += 1
                continue
            n, ad = int(h.group(1)), int(h.group(2), 16)
            # MERGE: `X: .incbin F, O, N ; K x 32-bit pointer` / title / this / `L:` / `.incbin F, O+N, M`
            px = PTRSLICE.match(L[i - 2]) if i >= 2 else None
            t = TITLE.match(L[i - 1])
            lab = LABEL.match(L[i + 1]) if i + 1 < len(L) else None
            nb = BARE.match(L[i + 2]) if i + 2 < len(L) else None
            if px and t and lab and nb and nb.group("f") == px.group("f") and \
                    int(nb.group("o"), 16) == int(px.group("o"), 16) + int(px.group("n"), 16) and \
                    L[i + 1].strip() == lab.group(1) + ":" and not refs(lab.group(1)):
                N, M, K = int(px.group("n"), 16), int(nb.group("n"), 16), int(px.group("k"))
                if N + M <= 4 * K:
                    L[i - 2] = "%s:%s.incbin \"%s\", %s, 0x%X%s; %d x 32-bit pointer" % (
                        px.group("lab"), px.group("ws"), px.group("f"), px.group("o"), N + M,
                        px.group("cws"), K)
                    retire[lab.group(1)] = px.group("lab")
                    del L[i - 1:i + 3]
                    stats["merged into the table above"] = stats.get("merged into the table above", 0) + 1
                    print("%s: merged %s (0x%06x, %d B) into %s" % (a.tree, lab.group(1), ad, n, px.group("lab")))
                    i -= 1
                    continue
            new = classify(m, ad, n)
            kind = "registered table" if new else None
            if not new:
                before = sorted(((s, nm_) for s, nm_ in m.rev if s < ad and nm_ not in retire
                                 and not nm_.startswith("EmbeddedPtrTable_")), reverse=True)[:6]
                new = ptrtail(m, before, ad, n)
                kind = "pointer-table tail" if new else None
            if not new:
                # split since: labels inside the span that code or data use (not comments)
                used = []
                for s, x in m.rev:
                    if ad <= s < ad + n and not x.startswith("EmbeddedPtrTable_"):
                        k = [q for q in refs(x) if re.search(r'(?<![\w.$])%s(?![\w$])' % re.escape(x), q.split(";", 1)[0])]
                        if k and x not in used:
                            used.append(x)
                if used:
                    new = ("; [nakarest] %d B at 0x%06x: split since into the labelled pieces below; "
                           "code or data uses %s." % (n, ad, ", ".join(used[:4]) + (" and %d more" % (len(used) - 4) if len(used) > 4 else "")))
                    kind = "split since, pieces in use"
            if new:
                L[i] = new
                stats[kind] = stats.get(kind, 0) + 1
            else:
                stats["left"] = stats.get("left", 0) + 1
                print("%s: left 0x%06x (%d B) %s:%d" % (a.tree, ad, n, os.path.relpath(f, REPO), i + 1))
            i += 1
    # positional EmbeddedPtrTable_* labels inside pointer tables
    at = {}
    for s, nm_ in m.rev:
        at.setdefault(s, []).append(nm_)
    sym = {nm_: s for s, nm_ in m.rev}
    for f in files:
        if os.path.normpath(f) not in live:
            continue
        L = texts[f]
        for i in range(len(L) - 1, -1, -1):
            mm = re.match(r'^(EmbeddedPtrTable_\w+):\s*$', L[i])
            if not mm or refs(mm.group(1)) or mm.group(1) not in sym:
                continue
            ad = sym[mm.group(1)]
            co = [x for x in at.get(ad, []) if x != mm.group(1) and not x.startswith("EmbeddedPtrTable_")]
            box = co[0] if co else None
            if not box:
                for s, nm_ in sorted(((s, x) for s, x in m.rev if s < ad and x not in retire and
                                      not x.startswith("EmbeddedPtrTable_")), reverse=True)[:3]:
                    if all(m.u32(w) == 0 or m.inrom(m.u32(w)) for w in range(s, ad, 4)) and (ad - s) % 4 == 0:
                        box = nm_
                        break
            if not box:
                print("%s: kept %s (0x%06x): no containing pointer table" % (a.tree, mm.group(1), ad))
                continue
            retire[mm.group(1)] = box
            del L[i]
            stats["EmbeddedPtrTable label retired"] = stats.get("EmbeddedPtrTable label retired", 0) + 1
            print("%s: %s (0x%06x) -> %s (0x%06x)" % (a.tree, mm.group(1), ad, box, sym[box]))
    if retire:
        pat = re.compile(r'(?<![\w.$])(%s)(?![\w$])' % "|".join(map(re.escape, retire)))
        for f in files:
            texts[f] = [pat.sub(lambda mm: retire[mm.group(1)], l) for l in texts[f]]
    print("%s: %s%s" % (a.tree, stats, "" if a.apply else " (dry run)"))
    if a.apply:
        for f in files:
            t = "\n".join(texts[f])
            if t != open(f, "rb").read().decode("latin-1"):
                open(f, "wb").write(t.encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
