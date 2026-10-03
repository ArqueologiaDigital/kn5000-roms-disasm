#!/usr/bin/env python3
"""apply_label_edits.py -- apply a lane's EDIT PACK (label renames + header comment blocks) to
assembly sources that several lanes share, safely and reviewably.

QUESTION THIS ANSWERS / WHY IT EXISTS
  Some images are one big source file (wsa1/prom_a/wsa1_prom_a.s holds 3,794 `sub_XXXXXX`
  routines). File-disjoint lanes cannot split such a file, so naming lanes work READ-ONLY and
  hand in an edit pack; one integrator applies the packs one after another, gating after each.
  This tool is that integrator step. It refuses anything that could silently go wrong:
    - a rename whose OLD name is not defined exactly once (as `OLD:` at column 0, or `.set/.equ
      OLD,`) in the target files,
    - a rename whose NEW name is already defined anywhere in the target files, or appears in two
      renames of the pack,
    - a header for a label that is not defined exactly once,
    - a NEW name that is also an OLD name in the same pack (chains and swaps would cascade
      through sed: a->b then b->c turns every a into c),
    - a header for a label that already has one, unless the pack says how to combine them:
      "mode": "append" (add lines at the end of the existing block -- keeps its evidence) or
      "mode": "replace" (discard it; only when the old header is shown wrong).
  Structural children follow their parent: renaming `sub_F0001A` also renames every label
  DEFINED as `sub_F0001A_<suffix>` (`_Join`, `_Return2`, `_Loop`, ...) to `<new>_<suffix>`,
  under the same checks, unless the rename says "children": false.
  Renames are applied by a generated sed script (project policy: batch renames go through sed),
  written to scripts/renaming/rename_<pack-name>.sed so the change is reviewable and replayable.
  Headers are inserted with latin-1 I/O (the .s files hold raw non-UTF-8 bytes; never decode
  them as UTF-8).

EDIT PACK FORMAT (JSON)
  {
    "name": "proma-naming-F80000",              # becomes the sed script name
    "files": ["wsa1/prom_a/wsa1_prom_a.s"],     # every file the renames must be applied to
    "renames": [ {"old": "sub_F8001A", "new": "Panel_ReadKeyMatrix",
                  "evidence": "reads port 0xFFxx ... (one line, kept in the report)"} ],
    "also": ["wsa1/prom_b/wsa1_prom_b.s"],      # optional: files the renames also reach, where OLD
                                                # may only be a `.set OLD, <addr>` cross-ROM alias
    "headers": [ {"label": "Panel_ReadKeyMatrix",   # name AFTER renames
                  "text": "Scan the 8x8 key matrix ...\\nReader: ...",
                  "mode": "insert"} ]               # insert (default) | append | replace
  }
  Header text is inserted as `; ` comment lines directly above the label line, after any blank
  line, and an existing comment block directly above the label counts as "a header".

USAGE
  python3 scripts/tools/apply_label_edits.py PACK.json [--check] [--report OUT.txt]
    --check   validate only; change nothing (exit 1 on any refusal)
  After applying: run `make gate-all`; renames and comments must not move a byte.

EXIT STATUS
  0 applied (or would apply), 1 refused (nothing changed), 2 usage error.
"""
import argparse
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
IDENT = re.compile(r"^[A-Za-z_.$][A-Za-z0-9_.$@]*$")


def read(path):
    with open(os.path.join(REPO, path), "rb") as f:
        return f.read().decode("latin-1")


def write(path, text):
    with open(os.path.join(REPO, path), "wb") as f:
        f.write(text.encode("latin-1"))


DEF = re.compile(r"^(?:([A-Za-z_.$][A-Za-z0-9_.$@]*):|\s*\.(?:set|equ|equiv)\s+([A-Za-z_.$][A-Za-z0-9_.$@]*)\s*,)")
TOKEN = re.compile(r"[A-Za-z_.$][A-Za-z0-9_.$@]*")


def index(texts):
    """{name: [(file, line_index)]} for every definition, and {name: occurrence count}, one pass."""
    defs, count = {}, {}
    for f, t in texts.items():
        for i, line in enumerate(t.split("\n")):
            m = DEF.match(line)
            if m:
                defs.setdefault(m.group(1) or m.group(2), []).append((f, i))
        for tok in TOKEN.findall(t):
            count[tok] = count.get(tok, 0) + 1
    return defs, count


def main():
    ap = argparse.ArgumentParser(description="apply a lane's label edit pack")
    ap.add_argument("pack")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    pack = json.load(open(a.pack, encoding="utf-8"))
    name = pack.get("name") or ""
    files = pack.get("files") or []
    renames = pack.get("renames") or []
    headers = pack.get("headers") or []
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", name) or not files:
        print("pack needs a simple 'name' and a non-empty 'files' list", file=sys.stderr)
        return 2
    texts = {f: read(f) for f in files}
    defs, count = index(texts)
    # "also": files the renames reach without being their home -- another assembly unit that names
    # the label through a cross-ROM alias (`.set sub_FA00EA, 0xFA00EA` in wsa1 prom_b for a prom_a
    # routine) or a linker script.  An alias there is not a second definition; NEW must not occur.
    also = [f for f in (pack.get("also") or []) if f not in files]
    atexts = {f: read(f) for f in also}
    adefs, acount = index(atexts)
    errors, report = [], []

    news = [r["new"] for r in renames]
    olds = [r["old"] for r in renames]
    for dup in sorted({n for n in news if news.count(n) > 1}):
        errors.append("NEW name used twice in the pack: %s" % dup)
    for dup in sorted({o for o in olds if olds.count(o) > 1}):
        errors.append("OLD name renamed twice in the pack: %s" % dup)
    for chain in sorted(set(news) & set(olds)):
        errors.append("NEW name %s is also an OLD name in the pack (chain/swap: split into two packs)" % chain)
    for r in renames:
        o, n = r["old"], r["new"]
        if not IDENT.match(n) or not IDENT.match(o):
            errors.append("not an identifier: %r -> %r" % (o, n))
            continue
        ndef = len(defs.get(o, []))
        if ndef != 1:
            errors.append("OLD %s is defined %d times in the target files (need exactly 1)" % (o, ndef))
        if count.get(n):
            errors.append("NEW %s already occurs in the target files" % n)
        if acount.get(n):
            errors.append("NEW %s already occurs in the 'also' files" % n)
        for f, i in adefs.get(o, []):
            if not re.match(r"^\s*\.(?:set|equ)\s+%s\s*,\s*(?:0x[0-9A-Fa-f]+|\d+)\s*(?:;.*)?$" % re.escape(o),
                            atexts[f].split("\n")[i]):
                errors.append("OLD %s is defined in %s line %d other than as a `.set` alias" % (o, f, i + 1))
        refs = count.get(o, 0)
        report.append("rename %-32s -> %-40s %4d occurrence(s)  | %s" % (o, n, refs, r.get("evidence", "")))

    after = {o: n for o, n in zip(olds, news)}
    for r in renames:                       # structural children follow their parent
        if r.get("children", True):
            for d in list(defs):
                if d.startswith(r["old"] + "_") and d not in after:
                    child = r["new"] + d[len(r["old"]):]
                    if count.get(child):
                        errors.append("child rename %s -> %s collides with an existing name" % (d, child))
                    after[d] = child
                    report.append("  child %-31s -> %s" % (d, child))
    for h in headers:
        lab = h["label"]
        pre = [k for k, v in after.items() if v == lab]
        look = pre[0] if pre else lab
        hits = defs.get(look, [])
        mode = h.get("mode", "replace" if h.get("replace") else "insert")
        if mode not in ("insert", "append", "replace"):
            errors.append("header %s: unknown mode %r" % (lab, mode))
        if len(hits) != 1:
            errors.append("header label %s is defined %d times (need exactly 1)" % (lab, len(hits)))
            continue
        f, i = hits[0]
        lines = texts[f].split("\n")
        has_header = i > 0 and lines[i - 1].lstrip().startswith(";")
        if has_header and mode == "insert":
            errors.append("label %s already has a header (say \"mode\": \"append\" or \"replace\")" % lab)
        report.append("header %-32s %s line %d%s" % (lab, f, i + 1, (" (%s existing)" % mode) if has_header else ""))

    if errors:
        print("REFUSED -- nothing changed:", file=sys.stderr)
        for e in errors:
            print("  " + e, file=sys.stderr)
        return 1
    if a.check:
        print("OK (check only): %d rename(s), %d header(s)" % (len(renames), len(headers)))
        if a.report:
            open(a.report, "w", encoding="utf-8").write("\n".join(report) + "\n")
        return 0

    # 1. renames through a committed, replayable sed script (word-bounded, longest names first)
    if renames:
        sed_path = os.path.join(REPO, "scripts", "renaming", "rename_%s.sed" % name)
        with open(sed_path, "w", encoding="latin-1") as s:
            s.write("# generated by scripts/tools/apply_label_edits.py from edit pack %s\n" % name)
            for o, n in sorted(after.items(), key=lambda kv: -len(kv[0])):
                s.write("s/\\(^\\|[^A-Za-z0-9_.$@]\\)%s\\($\\|[^A-Za-z0-9_.$@]\\)/\\1%s\\2/g\n"
                        % (re.escape(o).replace("/", "\\/"), n))
        # run twice: adjacent occurrences share a separator character, which one pass can consume
        for _ in range(2):
            subprocess.run(["sed", "-i", "-f", sed_path] + [os.path.join(REPO, f) for f in files + also],
                           check=True)
        texts = {f: read(f) for f in files}
        defs, count = index(texts)
        _, acount = index({f: read(f) for f in also})
        for o, n in after.items():
            left = count.get(o, 0) + acount.get(o, 0)
            if left:
                print("ERROR: %d occurrence(s) of %s survived the sed pass" % (left, o), file=sys.stderr)
                return 1

    # 2. headers, bottom-up per file so earlier line indexes stay valid without re-indexing
    if renames is not None and not renames:
        defs, _ = index(texts)
    lines_of = {f: t.split("\n") for f, t in texts.items()}
    jobs = sorted(((defs[h["label"]][0], h) for h in headers), key=lambda j: j[0], reverse=True)
    for (f, i), h in jobs:
        mode = h.get("mode", "replace" if h.get("replace") else "insert")
        lines = lines_of[f]
        start = i
        while start > 0 and lines[start - 1].lstrip().startswith(";"):
            start -= 1
        body = ["; " + ln if ln else ";" for ln in h["text"].rstrip("\n").split("\n")]
        if mode == "replace":
            lines[start:i] = body
        else:   # insert (no block above) or append (after the existing block)
            lines[i:i] = body
    texts = {f: "\n".join(ls) for f, ls in lines_of.items()}
    for f, t in texts.items():
        write(f, t)
    print("applied %d rename(s), %d header(s) from pack %s; now run make gate-all"
          % (len(renames), len(headers), name))
    if a.report:
        open(a.report, "w", encoding="utf-8").write("\n".join(report) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
