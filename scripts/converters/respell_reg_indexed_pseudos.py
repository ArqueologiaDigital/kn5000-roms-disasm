#!/usr/bin/env python3
"""respell_reg_indexed_pseudos.py -- `ld_rrb c, xbc, wa` -> `ld c, (xbc+wa)`, proven encoding by encoding.

QUESTION THIS ANSWERS / JOB IT DOES
  Until TOOLCHAIN_VERSION UPDATE 21 (2026-10-02) the assembler could not spell the TLCS-900
  register-indexed operand (xrr+rr) / (xrr+r8) (prefix c3/d3/e3/f3, mode byte 07 / 03), so
  the sources carry it as raw pseudo-instructions that name the registers positionally:
      ld_rrb / ld_rrw / ld_rrl  R, X, I     load  R <- (X+I), I a 16-bit index
      ld_rr8b / ld_rr8w / ld_rr8l R, X, I   the same, I an 8-bit index
      st_rrb / st_rrw / st_rrl  R, X, I     store (X+I) <- R
      st_rr8b / st_rr8w         R, X, I     the same, 8-bit index
      lda_rr  R, X, I                       lda R, (X+I)
      jp_rr   CC, X, I                      jp cc, (X+I) (CC numeric, 8 = T)
      jp_24   cc, (A)                       jp cc, (A:24)
  -- about 3,200 lines over v10/v9/v7, the sub-CPU payload and WSA1 on that day.  Each line is
  rewritten in the native spelling ONLY when llvm-mc (the pinned build) gives the native line
  exactly the encoding (bytes and fixups) it gives the pseudo line; anything else is reported
  and left.  Same encoding, same bytes: `make gate-all` then proves the whole image.

USAGE
  python3 scripts/converters/respell_reg_indexed_pseudos.py --tree v10/maincpu [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess
import sys
import tempfile

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
CC = ["f", "lt", "le", "ule", "ov", "mi", "z", "c", "t", "ge", "gt", "ugt", "nov", "pl", "nz", "nc"]
LINE = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s+)(?P<mn>ld_rr8?[bwl]|st_rr8?[bwl]|lda_rr|jp_rr|jp_24)'
                  r'(?P<ws>\s+)(?P<ops>[^;]*?)(?P<post>\s*(?:;.*)?)$')


def native(mn, ops):
    o = [x.strip() for x in ops.split(",")]
    if mn == "jp_24":
        m = re.match(r'^(\w+)\s*,\s*\((.+)\)$', ops.strip())
        return "jp\t%s, (%s:24)" % (m.group(1), m.group(2)) if m and ":" not in m.group(2) else None
    if len(o) != 3:
        return None
    r, x, i = o
    if mn.startswith("ld_rr"):
        return "ld\t%s, (%s+%s)" % (r, x, i)
    if mn.startswith("st_rr"):
        return "ld\t(%s+%s), %s" % (x, i, r)
    if mn == "lda_rr":
        return "lda\t%s, (%s+%s)" % (r, x, i)
    if mn == "jp_rr":
        try:
            return "jp\t%s, (%s+%s)" % (CC[int(r, 0)], x, i)
        except (ValueError, IndexError):
            return None
    return None


def encodings(lines):
    """llvm-mc -show-encoding for each line, in order (None where it does not assemble)."""
    out = []
    for k in range(0, len(lines), 400):
        chunk = lines[k:k + 400]
        with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False) as f:
            for l in chunk:
                f.write("\t%s\n\tnop\n" % l)
            name = f.name
        r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", name], capture_output=True, text=True)
        os.unlink(name)
        enc = [m.group(1) for m in re.finditer(r'encoding: (\[[^\]]*\])', r.stdout)]
        # a line that fails (or warns into two) breaks the alternation: fall back to one by one
        if r.returncode or len(enc) != 2 * len(chunk):
            for l in chunk:
                q = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input="\t%s\n" % l,
                                   capture_output=True, text=True)
                e = re.findall(r'encoding: (\[[^\]]*\])', q.stdout)
                out.append(e[0] if q.returncode == 0 and len(e) == 1 else None)
        else:
            out.extend(enc[0::2])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(REPO, a.tree, "**", "*.s"), recursive=True))
    texts = {f: open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    pairs = {}
    for f, L in texts.items():
        for l in L:
            m = LINE.match(l)
            if m:
                key = "%s\t%s" % (m.group("mn"), m.group("ops").strip())
                if key not in pairs:
                    pairs[key] = native(m.group("mn"), m.group("ops"))
    keys = [k for k, v in pairs.items() if v]
    # symbols need not resolve: -show-encoding prints the fixup placeholder for both spellings
    e_old = encodings(keys)
    e_new = encodings([pairs[k] for k in keys])
    ok = {k: pairs[k] for k, x, y in zip(keys, e_old, e_new) if x and x == y}
    st = collections.Counter()
    bad = collections.Counter()
    for k in pairs:
        if k not in ok:
            bad[k.split("\t")[0]] += 1
    for f, L in texts.items():
        changed = False
        for i, l in enumerate(L):
            m = LINE.match(l)
            if not m:
                continue
            key = "%s\t%s" % (m.group("mn"), m.group("ops").strip())
            if key in ok:
                L[i] = m.group("pre") + ok[key] + m.group("post")
                st[m.group("mn")] += 1
                changed = True
            else:
                st["left"] += 1
        if changed and a.apply:
            open(f, "wb").write("\n".join(L).encode("latin-1"))
    print("%s: respelled %s; unique forms left %s%s" % (a.tree, dict(st), dict(bad), "" if a.apply else " (dry run)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
