#!/usr/bin/env python3
"""respell_raw_pseudos.py -- raw-byte pseudo-instructions -> the real spelling, proven byte for byte.

QUESTION THIS ANSWERS / JOB IT DOES
  The trees still hold ~13,700 pseudo-instructions that spell an addressing mode as literal
  bytes: `ldb_sri C, 0x07, 0xe4, 0xec` is `ld c, (xbc+hl)`, `stl_dri XDE, 0xfd, 0x36, 0x01` is
  `ld (xsp+310), xde`, `bit_dri 7, 0x07, 0xec, 0xf4` is `bit 7, (xhl+iy)`.  They were written
  when the assembler could not express those modes; many it now can.  CLAUDE.md "Native
  Instructions Over .byte" and the encoding-quirks table want the real spelling.

  For every line whose mnemonic is such a pseudo (`*_sri*`, `*_dri*`, `*_ind`, `*_sril*`):
    1. assemble it with the pinned llvm-mc -> its bytes;
    2. read the bytes with MAME's unidasm (the project's reference decoder);
    3. translate that reading into this assembler's syntax, as a short list of candidates
       (displacements in decimal, signed for d16; `:16`/`:8` width forcing; the size suffix
       b/w/l for memory-only operations; `(xrr+rr)` index forms);
    4. assemble every candidate and keep the FIRST whose bytes equal the original's.
  A line with no matching candidate is left alone and counted under the form unidasm gave, so
  the report says exactly which spellings the backend still lacks.  Every replacement is
  proven by step 4 before it is written; `make gate-all` proves the whole tree again.

USAGE
  python3 scripts/converters/respell_raw_pseudos.py --tree v10/maincpu [--apply] [--report OUT]
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
REGS = set("a w b c d e h l wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz xsp "
           "qwa qbc qde qhl qix qiy qiz qw qa qb qc qd qe qh ql ixl ixh iyl iyh izl izh".split())
LINE = re.compile(r'^(?P<pre>\s*(?:[A-Za-z_.$][\w.$]*:)?\s*)(?P<mn>[a-z]\w*_(?:sri|dri|ind|sril)\w*)'
                  r'(?P<ws>\s+)(?P<ops>[^;]*?)(?P<post>\s*(?:;.*)?)$', re.I)


def assemble(lines, tmpdir):
    """-> list of bytes or None, one per input line (a line that does not assemble -> None).
    Each line is followed by a `nop` (encoding [0x00]) so a line's encodings are delimited
    even when it fails or expands to several instructions."""
    p = os.path.join(tmpdir, "a.s")
    body = []
    for l in lines:
        body += [l, "nop"]
    open(p, "w", encoding="latin-1").write("\n".join(body) + "\n")
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", p], capture_output=True,
                       text=True, encoding="latin-1")
    encs = [bytes(int(x, 16) for x in e.split(","))
            for e in re.findall(r'encoding: \[([^\]]*)\]', r.stdout)]
    out, cur = [], b""
    for e in encs:
        if e == b"\x00":
            out.append(cur or None)
            cur = b""
        else:
            cur += e
    if len(out) != len(lines):
        sys.exit("line/encoding grouping mismatch (%d vs %d): refusing" % (len(out), len(lines)))
    bad = {int(m.group(1)) for m in re.finditer(r'a\.s:(\d+):\d+: error', r.stderr)}
    return [None if (2 * i + 1) in bad else b for i, b in enumerate(out)]


def unidasm(seqs, tmpdir):
    """-> list of unidasm text (mnemonic + operands) per byte sequence, decoded at offset 0 each"""
    blob, offs = b"", []
    for s in seqs:
        offs.append(len(blob))
        blob += s
    p = os.path.join(tmpdir, "u.bin")
    open(p, "wb").write(blob)
    r = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", "0"], capture_output=True,
                       text=True, encoding="latin-1").stdout
    at = {}
    for l in r.split("\n"):
        m = re.match(r'^\s*([0-9a-fA-F]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', l)
        if m:
            at[int(m.group(1), 16)] = (m.group(2).split(), m.group(3).strip())
    out = []
    for s, o in zip(seqs, offs):
        e = at.get(o)
        out.append(e[1] if e and len(e[0]) == len(s) else None)
    return out


def disp(m, width):
    v = int(m, 16)
    if width == 16 and v >= 0x8000:
        v -= 0x10000
    return v


def candidates(text):
    """this assembler's spellings for one unidasm reading, most natural first"""
    t = text.strip()
    m = re.match(r'^(\S+)\s*(.*)$', t)
    if not m:
        return []
    mn, ops = m.group(1).lower(), m.group(2)
    ops = re.sub(r'\b([A-Z]{1,3}\d?)\b', lambda x: x.group(1).lower(), ops)
    if mn == "jp" and ops.startswith("t,"):          # `jp T,XIX+WA` = jump through (xix+wa)
        ops = ops[2:]
    if mn == "lda" and "," in ops and "(" not in ops.split(",", 1)[1]:
        a, b = ops.split(",", 1)
        ops = "%s,(%s)" % (a, b)
    forms = []

    def disp_variants(s):
        out = [s]
        m2 = re.search(r'\((x\w\w)\+0x([0-9a-f]{4})\)', s)
        if m2:
            v16 = disp(m2.group(2), 16)
            r = m2.group(1)
            sign = "%+d" % v16
            out = [s.replace(m2.group(0), "(%s%s)" % (r, sign)),
                   s.replace(m2.group(0), "(%s%s:16)" % (r, sign)),
                   s.replace(m2.group(0), "(%s+%d:16)" % (r, int(m2.group(2), 16)))]
        m2 = re.search(r'\((x\w\w)\+0x([0-9a-f]{2})\)', s)
        if m2:
            v = int(m2.group(2), 16)
            v8 = v - 0x100 if v >= 0x80 else v
            r = m2.group(1)
            out = [s.replace(m2.group(0), "(%s%+d)" % (r, v8)),
                   s.replace(m2.group(0), "(%s%+d:8)" % (r, v8))]
        res = []
        for o in out:
            m3 = re.search(r'\((0x[0-9a-f]+)\)', o)
            if m3:
                for w in (8, 16, 24):
                    res.append(o.replace(m3.group(0), "(%s:%d)" % (m3.group(1), w)))
            res.append(o)
        return res

    spaced = re.sub(r',\s*', ', ', ops)
    for o in disp_variants(spaced):
        base = mn.rstrip("wbl") if mn not in ("sll", "srl", "rl", "call", "bit", "decf") else mn
        names = [mn]
        for sfx in ("", "b", "w", "l"):
            nm = (base if mn != base else mn) + sfx
            if nm not in names:
                names.append(nm)
        for nm in names:
            forms.append("%s\t%s" % (nm, o) if o else nm)
    return forms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(REPO, a.tree, "**", "*.s"), recursive=True))
    sites = []                                          # (file, line index, match)
    texts = {}
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        texts[f] = L
        for i, l in enumerate(L):
            m = LINE.match(l)
            # only operands made of registers and numbers: a symbolic operand would be
            # replaced by unidasm's number, which loses the name
            if m and all(w.lower() in REGS for w in re.findall(r'(?<![0-9])\b[A-Za-z_]\w*', m.group("ops"))):
                sites.append((f, i, m))
    uniq = sorted({"%s %s" % (m.group("mn"), m.group("ops").strip()) for _, _, m in sites})
    stats, report = collections.Counter(), collections.Counter()
    with tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR")) as tmp:
        orig = assemble(uniq, tmp)
        seqs = sorted({b for b in orig if b})
        readings = dict(zip(seqs, unidasm(seqs, tmp)))
        cand_lines, owner = [], []
        for u, b in zip(uniq, orig):
            if not b or not readings.get(b):
                continue
            for c in candidates(readings[b]):
                cand_lines.append(c)
                owner.append(u)
        got = assemble(cand_lines, tmp) if cand_lines else []
    origb = dict(zip(uniq, orig))
    best = {}
    for c, u, b in zip(cand_lines, owner, got):
        if u not in best and b is not None and b == origb[u]:
            best[u] = c
    for u, b in zip(uniq, orig):
        if u not in best:
            r = readings.get(b) if b else None
            form = re.sub(r'0x[0-9a-f]+', 'N', (r or "?").split(" ")[0] + " " +
                          re.sub(r'\b(X?[A-Z]{1,2}\d?)\b', 'R', " ".join((r or "").split(" ")[1:])))
            report[form] += 1
    changed = collections.Counter()
    for f, i, m in sites:
        u = "%s %s" % (m.group("mn"), m.group("ops").strip())
        if u in best:
            texts[f][i] = m.group("pre") + best[u] + m.group("post")
            changed[f] += 1
            stats["respelled"] += 1
        else:
            stats["left"] += 1
    if a.apply:
        for f in changed:
            open(f, "wb").write("\n".join(texts[f]).encode("latin-1"))
    print("tree %s: %s, %d files%s" % (a.tree, dict(stats), len(changed), "" if a.apply else " (dry run)"))
    for form, n in report.most_common(25):
        print("  left: %4d unique  %s" % (n, form))
    if a.report:
        json.dump({"respelled": best, "left_forms": report}, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
