#!/usr/bin/env python3
"""retype_text_field_runs.py -- NAKA C `field_XXXX` word runs that are really text -> char arrays.

QUESTION THIS ANSWERS / JOB IT DOES
  The NAKA C sources (v*/maincpu/ui_widgets/naka_*.c) compile byte-exact into the ROM's widget
  blobs, but their untyped gaps are runs of anonymous members, `uint16_t field_fa1c; ...` with
  `.field_fa1c = 0x614C, .field_fa1e = 0x6D20, ...` -- the little-endian words of
  "La memoria interna es retenida alrededor de 80 minutos ...".  On 2026-10-02 about 7,000 of
  v10's 31,735 `field_` members were such text (Spanish, French, German, Indonesian help and
  warning messages): unreadable in the source, against CLAUDE.md's String Literals policy,
  and counted by semantic_debt_dashboard.py's `field` column.

  For each run of consecutive scalar `uint16_t` / `uint8_t field_XXXX;` declarations (the
  structs are packed, so replacing N words by a char[2N] keeps every offset), the bytes are
  rebuilt from the members' designated initializers and the run is retyped when it is TEXT:
    * every byte is printable ASCII, NUL, the 0xff alignment pad, or a Latin-1 letter
      (0xa0..0xfe: these messages are European), and >= 90 % are printable ASCII or NUL;
    * it holds a word of at least 3 ASCII letters (a table of 0x0707 / 0x2020 is not text).
  A message that the earlier typing cut at its first non-ASCII byte ("Diese Seite wird ge" +
  0xf6 ... then `char str_25[40] = "ffnet, wenn Sie ..."`) continues into the neighbouring
  `char` member(s); those are merged in, so the message is one array.
  The run becomes `char txt_<First_words>[N];` initialized by one string literal per
  NUL-terminated piece (non-ASCII bytes as 3-digit octal escapes, so a following digit can
  never extend them; the implicit terminator is dropped when the array is full, as C allows).
  Anything else is left alone and counted.  The byte gate (`make gate-all`) proves the
  rebuilt blobs unchanged.

USAGE
  python3 scripts/converters/retype_text_field_runs.py --tree v10 [--apply] [--report OUT]
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import unicodedata

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
DECL = re.compile(r'^(\s+)(uint8_t|uint16_t)\s+(field_[0-9a-fA-F]+)\s*;\s*$')
INIT = re.compile(r'^\s+\.(field_[0-9a-fA-F]+)\s*=\s*([^,]+?)\s*,\s*$')
CHARDECL = re.compile(r'^(\s+)char\s+([A-Za-z_]\w*)\s*\[(\d+)\]\s*;\s*$')
CHARINIT = re.compile(r'^\s+\.([A-Za-z_]\w*)\s*=\s*(.+?)\s*,\s*$')
CONST = {"NAKA_NONE": 0xFFFF}


def c_string_bytes(expr):
    """bytes of `"a" "b"` or `ALIGNED_STRING("a")` (naka_types.h: s "\\0\\xFF"), else None"""
    m = re.match(r'^ALIGNED_STRING\((.*)\)$', expr)
    tail = b""
    if m:
        expr, tail = m.group(1), b"\0\xff"
    out = bytearray()
    i = 0
    while i < len(expr):
        if expr[i].isspace():
            i += 1
            continue
        if expr[i] != '"':
            return None
        i += 1
        while i < len(expr) and expr[i] != '"':
            c = expr[i]
            if c != "\\":
                out.append(ord(c) & 0xff)
                i += 1
                continue
            i += 1
            c = expr[i]
            if c in "01234567":
                j = i
                while j < len(expr) and j < i + 3 and expr[j] in "01234567":
                    j += 1
                out.append(int(expr[i:j], 8) & 0xff)
                i = j
            elif c == "x":
                j = i + 1
                while j < len(expr) and expr[j] in "0123456789abcdefABCDEF":
                    j += 1
                out.append(int(expr[i + 1:j], 16) & 0xff)
                i = j
            else:
                out.append({"n": 10, "t": 9, "r": 13, "a": 7, "b": 8, "f": 12, "v": 11}.get(c, ord(c)))
                i += 1
        if i >= len(expr):
            return None
        i += 1
    return bytes(out + tail)


def value(v):
    v = v.strip()
    if v in CONST:
        return CONST[v]
    try:
        return int(v, 0)
    except ValueError:
        return None


def is_text(bs):
    if len(bs) < 4:
        return False
    if any(b < 0x20 and b != 0 or 0x7f <= b < 0xa0 for b in bs):
        return False
    if sum(1 for b in bs if 0x20 <= b < 0x7f or b == 0) < 0.9 * len(bs):
        return False
    return re.search(rb'[A-Za-z]{3}', bs) is not None


def literal(piece):
    out = []
    for i, b in enumerate(piece):
        if b == 0 and (i == len(piece) - 1 or piece[i + 1] > 0x7f or piece[i + 1] == 0):
            out.append("\\0")                       # never followed by a digit here
        elif b == 0:
            out.append("\\000")
        elif b in (0x22, 0x5c):
            out.append("\\" + chr(b))
        elif 0x20 <= b < 0x7f:
            if b == 0x3f and out and out[-1] == "?":
                out.append("\\?")                   # no "??x" trigraphs
            else:
                out.append(chr(b))
        else:
            out.append("\\%03o" % b)
    return '"%s"' % "".join(out)


def pieces(bs):
    out, cur, i = [], bytearray(), 0
    while i < len(bs):
        cur.append(bs[i])
        if bs[i] == 0:
            while i + 1 < len(bs) and bs[i + 1] == 0xff:   # the pad belongs to its string
                i += 1
                cur.append(0xff)
            out.append(bytes(cur))
            cur = bytearray()
        i += 1
    if cur:
        out.append(bytes(cur))
    return out


def name_for(bs, taken):
    first = bs.split(b"\0")[0].decode("latin-1")
    ascii_ = unicodedata.normalize("NFKD", first).encode("ascii", "ignore").decode()
    words = re.findall(r'[A-Za-z0-9]+', ascii_)
    stem = ""
    for w in words:
        if len(stem) + len(w) + 1 > 32:
            break
        stem = (stem + "_" + w) if stem else w
    stem = "txt_" + (stem or "text")
    n, k = stem, 2
    while n in taken:
        n, k = "%s_%d" % (stem, k), k + 1
    taken.add(n)
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    stats, report = collections.Counter(), []
    for p in sorted(glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.c"), recursive=True)):
        L = open(p, "rb").read().decode("latin-1").split("\n")
        inits = {}
        for i, l in enumerate(L):
            m = INIT.match(l)
            if m:
                inits[m.group(1)] = (i, m.group(2))
        taken = set(re.findall(r'\b[A-Za-z_]\w*\b', "\n".join(L)))
        cinits = {}
        for i, l in enumerate(L):
            m = CHARINIT.match(l)
            if m:
                cinits[m.group(1)] = (i, m.group(2))

        def char_member(i):
            """(decl line, name, bytes padded to its size) of a `char X[N];` at line i, else None"""
            if not 0 <= i < len(L):
                return None
            m = CHARDECL.match(L[i])
            if not m or m.group(2) not in cinits:
                return None
            bs = c_string_bytes(cinits[m.group(2)][1])
            n = int(m.group(3))
            if bs is None or len(bs) > n + 1:
                return None
            bs = bs[:n] + bytes(max(0, n - len(bs)))
            return (i, m.group(2), bs)
        # names used anywhere but their own declaration and initializer (SELF(field_5f48) in a
        # pointer table): such a member must start its array, and the use is renamed with it
        used = collections.Counter(re.findall(r'\b(?:field_[0-9a-fA-F]+|str_\w+)\b', "\n".join(L)))
        for nm_ in list(used):
            used[nm_] -= (1 if nm_ in inits or nm_ in cinits else 0) + 1
        runs, cur = [], []
        for i, l in enumerate(L):
            m = DECL.match(l)
            if m:
                cur.append((i, m.group(1), m.group(2), m.group(3)))
            elif cur:
                runs.append(cur)
                cur = []
        if cur:
            runs.append(cur)
        merged_away = set()
        renames = {}
        edits = []                                   # (line, replacement or None)
        for r in runs:
            bs = bytearray()
            ok = True
            for _, _, ty, n in r:
                if n not in inits:
                    ok = False
                    break
                v = value(inits[n][1])
                if v is None:
                    ok = False
                    break
                bs += v.to_bytes(2, "little") if ty == "uint16_t" else bytes([v & 0xff])
            if not ok:
                stats["run-unparsed"] += len(r)
                continue
            if not is_text(bytes(bs)):
                stats["run-not-text"] += len(r)
                continue
            if any(used[x[3]] > 0 for x in r[1:]):
                stats["run-refused-inner-reference"] += len(r)   # a pointer into its middle
                continue
            # a message the earlier typing cut at its first non-ASCII byte continues into the
            # neighbouring `char` member(s): take them in, so each message is one array
            before, after = [], []
            k = r[0][0] - 1
            while True:
                cm = char_member(k)
                if not cm or cm[1] in merged_away or cm[2].endswith((b"\0", b"\xff")) or \
                        not is_text(cm[2] + bytes(bs[:8])) or used[r[0][3]] > 0 or \
                        (before and used[before[0][1]] > 0):
                    break
                before.insert(0, cm)
                k -= 1
            k = r[-1][0] + 1
            while not bytes(bs).endswith((b"\0", b"\xff")) and not (after and after[-1][2].endswith((b"\0", b"\xff"))):
                cm = char_member(k)
                if not cm or cm[1] in merged_away or not is_text(bytes(bs[-8:]) + cm[2]) or \
                        used[cm[1]] > 0:
                    break
                after.append(cm)
                k += 1
            for cm in before + after:
                merged_away.add(cm[1])
            bs = bytearray(b"".join(c[2] for c in before)) + bs + bytearray(b"".join(c[2] for c in after))
            stats["char-members-merged"] += len(before) + len(after)
            nm = name_for(bytes(bs), taken)
            ind = r[0][1]
            first_decl = before[0][0] if before else r[0][0]
            edits.append((first_decl, "%schar %s[%d];" % (ind, nm, len(bs))))
            for i in [c[0] for c in before[1 if before else 0:]] + \
                    [x[0] for x in (r if before else r[1:])] + [c[0] for c in after]:
                if i != first_decl:
                    edits.append((i, None))
            ii = [cinits[c[1]][0] for c in before] + [inits[n][0] for _, _, _, n in r] + \
                 [cinits[c[1]][0] for c in after]
            lit = " ".join(literal(pc) for pc in pieces(bytes(bs)))
            iind = re.match(r'^(\s*)', L[ii[0]]).group(1)
            edits.append((ii[0], "%s.%s = %s," % (iind, nm, lit)))
            for i in ii[1:]:
                edits.append((i, None))
            start = before[0][1] if before else r[0][3]
            if used[start] > 0:
                renames[start] = nm
            stats["members-retyped"] += len(r)
            stats["char-arrays"] += 1
            report.append({"file": os.path.relpath(p, REPO), "name": nm, "bytes": len(bs),
                           "members": len(r), "first": r[0][3], "text": bs.decode("latin-1")[:80],
                           "merged": [c[1] for c in before + after]})
        if not edits:
            continue
        rep = dict(edits)
        out = []
        drop_blank = False
        for i, l in enumerate(L):
            if i in rep:
                if rep[i] is None:
                    drop_blank = True                # the blank line after a dropped initializer
                    continue
                out.append(rep[i])
                drop_blank = False
                continue
            if drop_blank and l.strip() == "":
                drop_blank = False
                continue
            drop_blank = False
            out.append(l)
        if renames:
            rp = re.compile(r'\b(%s)\b' % "|".join(map(re.escape, renames)))
            out = [rp.sub(lambda m: renames[m.group(1)], l) for l in out]
            stats["references-renamed"] += len(renames)
        if a.apply:
            open(p, "wb").write("\n".join(out).encode("latin-1"))
        stats["files"] += 1
    print("tree %s: %s%s" % (a.tree, dict(stats), "" if a.apply else " (dry run)"))
    if a.report:
        json.dump(report, open(a.report, "w"), indent=1, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
