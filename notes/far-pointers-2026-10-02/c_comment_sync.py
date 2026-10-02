#!/usr/bin/env python3
"""c_comment_sync.py -- bring the NAKA C sources' comments in line with what the pipeline did.

QUESTION THIS ANSWERS
  The NAKA C files (v*/maincpu/**/*.c) carry, per struct member, the same header text as the
  .s label of that member.  After far_pointer_pipeline.sh (2026-10-02) two things in those
  comments are stale, and this fixes both, comments only (it refuses a file where a name to be
  replaced sits outside a comment):
    1. positional aliases the splitter retired (`Str_No_0x754`, `NakaInst_NO_OPERATION_0x12`)
       -> the label that replaced them, per tree, from the splitter's --report JSON
       (`aliases_retired`);
    2. a member comment that says "no (registration or) code reference reaches them" while the
       .s header of the same label no longer says so (fix_unread_claims.py or the splitter
       corrected it) -> "that code DOES reach (readers: the .s header ...)", dropping the
       "(searched: ...)" note and "Which code uses them is not established."
  Idempotent.  Changes no byte (the generated bins are built from code, not comments):
  `make gate-all` must stay 13/13.

USAGE (repo root, after the pipeline; REPORTS = the pipeline's $OUT)
  python3 notes/far-pointers-2026-10-02/c_comment_sync.py REPORTS
"""
import glob
import json
import os
import re
import sys

S = r'(?:\s|\*|;)+'
CLAIM = re.compile(r'(that' + S + r')?no' + S + r'(registration' + S + r'or' + S + r')?code' + S +
                   r'reference' + S + r'reaches(' + S + r'(them|it))?', re.I)
WHICH = re.compile(r'\s*Which' + S + r'code' + S + r'uses' + S + r'them' + S + r'is' + S + r'not' + S +
                   r'established\.')
SEARCHED = re.compile(r'\s*\(searched:[^)]*\)\.?')
BLOCK = re.compile(r'/\* -{20,}\n((?:[ \t]*\*(?! -{20,} \*/).*\n)+?)[ \t]*\* -{20,} \*/')


def s_headers(v):
    shdr = {}
    for f in glob.glob(v + "/maincpu/**/*.s", recursive=True):
        L = open(f, "rb").read().decode("latin-1").split("\n")
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_]\w*):', l)
            if not m:
                continue
            j = i - 1 if i > 0 and L[i - 1].startswith("; ---") else i
            k = j
            while k > 0 and L[k - 1].startswith(";") and not L[k - 1].startswith("; ---"):
                k -= 1
            shdr[m.group(1)] = "\n".join(L[k:j])
    return shdr


def tidy(t):
    """drop a bare ` *` line left before a closing rule; wrap comment lines over 100 columns"""
    t = re.sub(r'\n[ \t]+\*[ \t]*\n([ \t]+\* -{20,} \*/)', r'\n\1', t)
    out = []
    for l in t.split("\n"):
        m = re.match(r'^([ \t]+\* )(.*)$', l)
        while m and len(l) > 100 and " " in l[len(m.group(1)):100]:
            k = l.rindex(" ", len(m.group(1)), 100)
            out.append(l[:k])
            l = m.group(1) + l[k + 1:]
        out.append(l)
    return "\n".join(out)


def main():
    reports = sys.argv[1]
    total = 0
    for v in ("v10", "v9", "v7"):
        ret = json.load(open(os.path.join(reports, "split_%s.json" % v)))["aliases_retired"]
        ret = {k: x for k, x in ret.items() if k != x}
        shdr = s_headers(v)
        for p in sorted(glob.glob(v + "/maincpu/**/*.c", recursive=True) +
                        glob.glob(v + "/maincpu/**/*.h", recursive=True)):
            t0 = t = open(p, "rb").read().decode("latin-1")
            hits = [n for n in ret if n in t]
            if hits:
                pat = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' %
                                 "|".join(map(re.escape, sorted(hits, key=len, reverse=True))))
                code = [l for l in t.split("\n") if pat.search(l) and
                        not re.match(r'^\s*(\*|/\*|//)', l) and "/*" not in l and "//" not in l]
                if code:
                    print("REFUSED %s: a name outside a comment: %s" % (p, code[0][:80]))
                    continue
                n = len(pat.findall(t))
                t = pat.sub(lambda m: ret[m.group(1)], t)
                print("%s: %d retired alias name(s)" % (p, n))
                total += n
            nclaim = 0
            for b in reversed(list(BLOCK.finditer(t))):
                body = b.group(1)
                if not CLAIM.search(body):
                    continue
                m = re.search(r'^\s*\*\s*([A-Za-z_]\w*)\s+--', body, re.M)
                h = shdr.get(m.group(1)) if m else None
                if h is None or CLAIM.search(h):
                    continue
                split = "reaches: the labels below" in h
                nb = CLAIM.sub("that code DOES reach (readers: the .s header%s)" %
                               (", which also labels each string" if split else ""), body, count=1)
                nb = SEARCHED.sub("", WHICH.sub("", nb))
                t = t[:b.start(1)] + nb + t[b.end(1):]
                nclaim += 1
            if nclaim:
                print("%s: %d no-reader claim(s) corrected" % (p, nclaim))
            if t != t0:
                open(p, "wb").write(tidy(t).encode("latin-1"))
    print("retired alias names replaced: %d" % total)


if __name__ == "__main__":
    main()
