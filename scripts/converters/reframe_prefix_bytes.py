#!/usr/bin/env python3
"""reframe_prefix_bytes.py -- code that went out of frame at a lone prefix byte, put back in frame.

QUESTION THIS ANSWERS / JOB IT DOES
  Before TOOLCHAIN_VERSION UPDATE 21 the assembler could not spell the register-indexed forms
  `(xrr+rr)` (prefix c3/d3/e3/f3, mode byte 07) and some others; the conversion wrote the
  prefix as `.byte 0xc3` and decoded the REST of the instruction's bytes as instructions --
  sound_editor_ui.s had `.byte 0xc3 / reti / or xwa, xwa / push xsp / ld w, 110:opc / ldf 0xc7
  / swi 1 / jr lt, -57 ...` for what is `cp (xde+wa), 0x20 / jr nz, 23 / inc1b_erp 249 ...`.
  symbolize_numeric_branches.py refuses the numeric branches of such blocks as "R3 absurd
  block" (509 in v10), so they stay numbers too.
  For every `.byte 0xPP` line holding one prefix byte (c1-c3, c7, d1-d3, d7, e1-e3, e7, f1-f3,
  f7) that execution FALLS INTO -- the line before is an instruction that continues (not a
  jump, return, halt, swi or nop, and not a directive) -- this decodes from it with MAME's
  unidasm (an independent decoder) until the decode resyncs with the source: four consecutive
  instructions starting exactly where source lines start, with the same lengths.  Refused
  unless the new decode holds none of normal/max/min/halt/swi/decf/incf/ldf/reti/ei/di (a
  "resync" through data decodes to those), the old lines were visibly broken (another `.byte`
  or one of those), and the three code lines before the prefix are clean (no directive, none
  of those) -- a first run without these guards turned `ld a, (xhl+1) / res 7, a` into
  `normal / max / decf` where the code before was itself mis-framed.  The span up to the
  resync, at most 96 bytes, with no undecodable byte in it, is re-spelled as code by
  scripts/converters/scoop_reframe.py apply, which assembles and links the whole image,
  cross-checks every instruction against unidasm, carries every label and comment to its
  address, and rolls back unless the image is byte-identical.  Then the rendered lines take
  the house format (tab after the mnemonic, ", " between operands, no comment that only
  repeats the instruction).

  --any-bytes starts from ANY `.byte` line execution falls into (an instruction written as bytes
  whose neighbours went out of frame with it), under the same guards.

USAGE
  make all
  python3 scripts/converters/reframe_prefix_bytes.py --image v10 [--any-bytes] [--apply] [--report OUT.json]
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import scoop_reframe as SR                    # noqa: E402

PREFIX = {0xc1, 0xc2, 0xc3, 0xc7, 0xd1, 0xd2, 0xd3, 0xd7, 0xe1, 0xe2, 0xe3, 0xe7, 0xf1, 0xf2, 0xf3, 0xf7}
BYTEN = re.compile(r'^\s*\.byte\s+(0x[0-9a-fA-F]+)\s*(?:,\s*0x[0-9a-fA-F]+\s*)*$')
BYTE1 = re.compile(r'^\s*\.byte\s+(0x[0-9a-fA-F]+)\s*$')
# `ret <cc>` (`ret nz` ...) falls through when its condition fails, so it is not a stop (2026-10-03)
STOPS = re.compile(r'^\s*(?:jp|jr|jrl)\s+(?:t\s*,\s*)?[^,]+$|^\s*jp\s+t\s*,|^\s*ret\s*(?:;.*)?$|^\s*(?:reti|retd|halt|swi|nop)\b', re.I)
LABEL_ONLY = re.compile(r'^[A-Za-z_][\w.$]*:\s*$')
INCLUDE = re.compile(r'^(?:[A-Za-z_][\w.$]*:)?\s*\.include\s+"([^"]+)"')
# instructions that real code here does not contain (the absurd-block markers of
# symbolize_numeric_branches.py): mode switches, traps, register-bank stepping, halt
ABSURD = re.compile(r'^\s*(normal|max|min|halt|swi|decf|incf|ldf|reti|ei|di)\b', re.I)
RENDERED = re.compile(r'^\t([a-z_][\w.]*) ([^\t;]+?)\t; (.+)$')


def assembled(img):
    top = os.path.join(REPO, img, "maincpu", "kn5000_%s_program.s" % img)
    root, seen, stack = os.path.dirname(top), [], [top]
    while stack:
        f = stack.pop()
        if f in seen or not os.path.exists(f):
            continue
        seen.append(f)
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = INCLUDE.match(l)
            if m:
                for base in (os.path.dirname(f), root):
                    p = os.path.normpath(os.path.join(base, m.group(1)))
                    if os.path.exists(p):
                        stack.append(p)
                        break
    return [os.path.relpath(f, REPO) for f in seen]


def tidy(line):
    """`\\tcp (xde+wa),0x20\\t; cp (XDE+WA),0x20` -> `\\tcp\\t(xde+wa), 0x20`."""
    m = RENDERED.match(line)
    if not m:
        return line
    ops = re.sub(r',(?=\S)', ', ', m.group(2).strip())
    same = re.sub(r'\s', '', (m.group(1) + m.group(2)).lower()) == re.sub(r'\s', '', m.group(3).lower())
    return "\t%s\t%s%s" % (m.group(1), ops, "" if same else "\t; " + m.group(3))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--any-bytes", action="store_true",
                    help="start from any `.byte` line execution falls into, not only a lone prefix byte")
    a = ap.parse_args()
    files = assembled(a.image)
    amap, _ = SR.linemap(a.image, files)
    st, specs, rows = collections.Counter(), collections.defaultdict(list), []
    for rel in files:
        L = open(os.path.join(REPO, rel), "rb").read().decode("latin-1").split("\n")
        addrs = amap[rel]
        ext = SR.line_extents(addrs)
        starts = {addrs[i]: ext[i] for i in range(len(L)) if addrs[i] is not None and ext[i] > 0}
        prev, recent = None, []
        for i, l in enumerate(L):
            code = SR.strip_comment(l)[0].rstrip()
            if not code.strip() or LABEL_ONLY.match(code):
                continue
            m = BYTE1.match(code) or (BYTEN.match(code) if a.any_bytes else None)
            if m and (a.any_bytes or int(m.group(1), 16) in PREFIX) and addrs[i] is not None and prev is not None \
                    and not prev.lstrip().startswith(".") and not STOPS.match(prev):
                S = addrs[i]
                U = SR.unidasm(a.image, S, 48)
                E = None
                for j in range(1, len(U) - 4):
                    if all(U[k][0] in starts and starts[U[k][0]] == U[k][1] for k in range(j, j + 4)):
                        E = U[j][0]
                        break
                bad = E is None or E - S > 96 or any(re.search(r'\b(db|invalid|illegal|\?\?)\b', t, re.I)
                                                    for ad, n, t in U if S <= ad < E)
                why = "no resync / undecodable"
                if not bad and any(ABSURD.match(t) for ad, n, t in U if S <= ad < E):
                    bad, why = True, "new decode absurd"
                ctx = [x for x in recent[-3:]]
                if not bad and (len(ctx) < 3 or any(x.lstrip().startswith(".") or ABSURD.match(x.strip()) for x in ctx)):
                    bad, why = True, "context before not clean code"
                old_lines = [SR.strip_comment(L[k])[0].strip() for k in range(i + 1, len(L))
                             if E is not None and addrs[k] is not None and S < addrs[k] < E]
                if not bad and not any(x.startswith(".byte") or ABSURD.match(x) for x in old_lines):
                    bad, why = True, "old decode looked sane"
                if bad:
                    st[why] += 1
                    rows.append(dict(file=rel, line=i + 1, addr=hex(S), result="refused: " + why))
                else:
                    specs[rel].append(dict(file=rel, start="0x%X" % S, end="0x%X" % E,
                                           segments=[dict(kind="code", len=E - S)]))
                    st["candidate"] += 1
                    rows.append(dict(file=rel, line=i + 1, addr=hex(S), end=hex(E), result="candidate"))
            prev = code
            recent.append(code)
    print("%s: %s" % (a.image, dict(st)))
    if a.apply:
        done = 0
        os.makedirs(SR.SCRATCH, exist_ok=True)
        for rel, sp in sorted(specs.items()):
            sp = [x for k, x in enumerate(sp) if all(int(x["start"], 16) >= int(y["end"], 16) or
                                                     int(x["end"], 16) <= int(y["start"], 16) for y in sp[:k])]
            for chunk in ([sp] if len(sp) > 1 else []) + [[x] for x in sp]:
                path = os.path.join(SR.SCRATCH, "reframe-%s.json" % os.getpid())
                json.dump(chunk, open(path, "w"))
                r = subprocess.run([sys.executable, os.path.join(REPO, "scripts", "converters", "scoop_reframe.py"),
                                    "apply", "--image", a.image, "--spec", path], capture_output=True, text=True)
                if r.returncode == 0 and "REJECT" not in r.stdout + r.stderr and "refus" not in (r.stdout + r.stderr).lower():
                    done += len(chunk)
                    for x in chunk:
                        x["applied"] = True
                    if len(chunk) > 1:
                        break                      # the whole file at once: no need for singles
                else:
                    for x in chunk:
                        x.setdefault("why", (r.stdout + r.stderr).strip().splitlines()[-1:] or ["?"])
                    if len(chunk) == 1 and not chunk[0].get("applied"):
                        st["refused by scoop_reframe"] += 1
            p = os.path.join(REPO, rel)
            t = open(p, "rb").read().decode("latin-1")
            t2 = "\n".join(tidy(l) for l in t.split("\n"))
            if t2 != t:
                open(p, "wb").write(t2.encode("latin-1"))
        st["applied"] = done
        print("%s: %s" % (a.image, dict(st)))
    if a.report:
        json.dump(dict(rows=rows, specs=specs), open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
