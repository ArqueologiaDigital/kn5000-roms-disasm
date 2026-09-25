#!/usr/bin/env python3
r"""Which prom_b objects filed as "read by nothing (32-bit search)" DO have a reader?

QUESTION THIS ANSWERS
    75 headers in wsa1/prom_b/wsa1_prom_b.s say "Read by: nothing in prom_a or
    prom_b spells this address as a 32-bit word, so whatever reaches it
    computes the address".  A 32-bit search misses every TLCS-900 operand that
    holds a 24-bit address -- `lda XRR,(nnn:24)`, `ld R,(nnn:24)`, `jp`/`call
    nnn` -- which this lane found to be how prom_a names the SysEx strings at
    0xF4FEB4.  This sweep takes every labelled object whose header carries
    that sentence, searches BOTH images for the 3-byte little-endian spelling
    of its address, and keeps a hit only when it is an OPERAND of an
    instruction:
      * prom_a: the hit lies inside a source line of wsa1/prom_a/wsa1_prom_a.s
        whose trailing comment gives its address and bytes, the line is an
        instruction (not a `.byte`/`.long`/`.ascii` row), and the hit is not at
        the line's first byte;
      * prom_b: the same test against the marker map of this image's own
        source (the branch symboliser's build_map), with the census's line
        classifier deciding instruction vs data.
    ⚠ AND the operand must SPELL the address: the prom_a line's text must
    contain it in hex, the prom_b line's code must name the object's label or
    the number.  Without that guard the first run (2026-09-25) reported two
    coincidences as readers -- prom_a 0xFBDC72 `cp C,(0x2766)` followed by an
    `f1` byte, and prom_b 0xF68CBE `calr 0xf6b243` -- both "0xF12766"/"0xF12582"
    only by byte adjacency.
    It prints, per object, the operand sites found.  It writes nothing.

RUN
    python3 notes/promb-2026-09-25/reader24_sweep.py
"""
import bisect
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc              # noqa: E402
import symbolize_numeric_branches as snb     # noqa: E402

PB = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
PA = os.path.join(ROOT, "wsa1", "prom_a", "wsa1_prom_a.s")
ROMB = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
ROMA = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
PHRASE = "spells this address as a 32-bit word"
ALINE = re.compile(r'^(?P<code>[^;]*);\s*(?P<addr>[0-9A-F]{6})\s+(?P<bytes>(?:[0-9a-f]{2}\s)+)')


def prom_a_lines():
    out = []
    for ln in open(PA, encoding="latin-1"):
        m = ALINE.match(ln)
        if not m:
            continue
        code = m.group("code").strip()
        code = re.sub(r'^[\w.$]+:\s*', '', code)
        if not code:
            continue
        n = len(m.group("bytes").split())
        out.append((int(m.group("addr"), 16), n, not code.startswith("."), code.lower()))
    out.sort()
    return out


def main():
    img = snb.image_by_key("prom_b")
    marks, addrs, spans, ok, src, macros = snb.build_map(img, os.path.join(ROOT, "wsa1"))
    assert ok
    bstarts = [s[0] for s in spans]
    L = src.lines("prom_b/wsa1_prom_b.s")
    line_addr = {}
    for a, e, rel, li in spans:
        if rel == "prom_b/wsa1_prom_b.s":
            line_addr[li] = a
    alines = prom_a_lines()
    astarts = [x[0] for x in alines]
    # objects: label line whose header (the comment block above) has the phrase
    objs = []
    for i, t in enumerate(L):
        m = re.match(r'^([A-Za-z_][\w.$]*):', t)
        if not m:
            continue
        hdr = []
        j = i - 1
        while j >= 0 and L[j].startswith(";"):
            hdr.append(L[j])
            j -= 1
        if not any(PHRASE in h for h in hdr):
            continue
        k = i
        while k < len(L) and k not in line_addr:
            k += 1
        if k < len(L):
            objs.append((m.group(1), line_addr[k]))
    found = 0
    for name, a in objs:
        s = a.to_bytes(3, "little")
        hits = []
        for rom, base, which in ((ROMA, 0xF80000, "a"), (ROMB, 0xF00000, "b")):
            i = rom.find(s)
            while i >= 0:
                h = base + i
                if which == "a":
                    k = bisect.bisect_right(astarts, h) - 1
                    if k >= 0 and alines[k][0] < h < alines[k][0] + alines[k][1] and alines[k][2] \
                            and re.search(r'0x(00)?%x\b' % a, alines[k][3]):
                        hits.append("prom_a 0x%06X" % alines[k][0])
                else:
                    k = bisect.bisect_right(bstarts, h) - 1
                    if k >= 0 and spans[k][0] < h < spans[k][1] and spans[k][2] == "prom_b/wsa1_prom_b.s":
                        bk, _ = drc.classify_line(L[spans[k][3]], macros)
                        txt = L[spans[k][3]].split(";")[0]
                        if bk == "code" and (re.search(r'\b%s\b' % re.escape(name), txt) or
                                             re.search(r'(?i)0x(00)?%x\b|\b%d\b' % (a, a), txt)):
                            hits.append("prom_b 0x%06X" % spans[k][0])
                i = rom.find(s, i + 1)
        if hits:
            found += 1
            print("%-36s 0x%06X  %s" % (name, a, " ".join(sorted(set(hits)))))
    print("\n%d of %d objects filed as 'read by nothing (32-bit)' have a 24-bit operand reader"
          % (found, len(objs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
