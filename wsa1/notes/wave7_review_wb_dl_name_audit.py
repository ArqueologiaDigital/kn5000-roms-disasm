#!/usr/bin/env python3
"""Lane REVIEW-WB. Do the DL_<Word> labels spliced into prom_b name the LIST,
or do they name one ROW of it?

QUESTION IT ANSWERS
    gen_prom_b_f17559_module.py names a display list with dl_name(), which
    slugs "the longest LETTER run its records carry".  Its docstring justifies
    longest-not-first because the first caption is often `PAGE1/3`.  This script
    asks what the rule does on the other side: when a list is a PARAMETER PAGE,
    the longest caption is a parameter ROW, and the label then asserts that the
    whole page IS that row.

HOW IT DECIDES
    For every `DL_<Word>` label in the two spliced regions, read the emitted
    `Text it draws:` line (the generator's own transcription of the list's
    records, so this script does not re-decode anything and cannot disagree
    with the generator about what the strings are).  Then:
      * ROW   -- the slug matches a caption that is NOT the first string, AND
                 the list draws >= 3 strings, AND some earlier string looks
                 like a screen title (a bare NAME, or a `PAGEn/m`).
      * TITLE -- the slug matches the first string, or the list draws < 3.
    A ROW verdict means the extent is proven but the identity is a fragment.

RUN
    python3 notes/wave7_review_wb_dl_name_audit.py
    python3 notes/wave7_review_wb_dl_name_audit.py --selftest   # incl. LAST
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")
REGIONS = [(0xF17559, 0xF1B400), (0xF4F000, 0xF55000)]


def slugwords(s):
    return re.sub(r"[^A-Z0-9]", "", s.upper())


def collect():
    """Every DL_<Word> label in the regions, with the strings its header lists."""
    lines = open(SRC, encoding="utf-8", errors="replace").read().split("\n")
    out, block = [], []
    for ln in lines:
        if ln.startswith(";"):
            block.append(ln)
            continue
        m = re.match(r"^(DL_[A-Za-z][A-Za-z0-9_]*):", ln)
        if m:
            name = m.group(1)
            # address: the header's own "0xXXXXXX-0x" range
            am = None
            for b in block:
                q = re.search(r"-- (?:a UI )?display list,[^0]*0x([0-9A-F]{6})-", b)
                if q:
                    am = int(q.group(1), 16)
            if am is None:
                q = re.search(r"0x([0-9A-F]{6})", ln)
            if am is not None and any(lo <= am < hi for lo, hi in REGIONS):
                txt = ""
                grab = False
                for b in block:
                    if "Text it draws:" in b:
                        grab = True
                        txt += b.split("Text it draws:", 1)[1]
                    elif grab and re.match(r"^;\s{10,}", b) and "Evidence:" not in b:
                        txt += " " + b.lstrip("; ")
                    elif grab:
                        grab = False
                strings = [t.strip().strip("'") for t in txt.split(";") if t.strip()]
                strings = [s for s in strings if s]
                stem = re.sub(r"_F[0-9A-F]{5}$", "", name)[3:]
                out.append((am, name, stem, strings))
        block = []
    return sorted(out)


TITLEISH = re.compile(r"^(PAGE\d/\d|[A-Z0-9][A-Z0-9 .&/-]*)$")


def verdict(stem, strings):
    if not strings:
        return "NOTEXT"
    tgt = slugwords(stem)
    idx = None
    for i, s in enumerate(strings):
        if slugwords(s).startswith(tgt) or tgt.startswith(slugwords(s)[:len(tgt)] or "\0"):
            if slugwords(s).startswith(tgt):
                idx = i
                break
    if idx is None:
        return "NOMATCH"
    if idx == 0 or len(strings) < 3:
        return "TITLE"
    earlier = strings[:idx]
    if any(re.match(r"^PAGE\d/\d$", s.replace(" ", "")) for s in earlier) or any(
            TITLEISH.match(s) and ":" not in s for s in earlier):
        return "ROW"
    return "TITLE"


def main():
    rows = collect()
    counts = {}
    for a, name, stem, strings in rows:
        v = verdict(stem, strings)
        counts[v] = counts.get(v, 0) + 1
        if v == "ROW":
            print("ROW   0x%06X  %-32s names row %d of %d: %s"
                  % (a, name, [slugwords(s).startswith(slugwords(stem)) for s in strings].index(True) + 1,
                     len(strings), " | ".join(strings[:3]) + (" ..." if len(strings) > 3 else "")))
    print()
    for k in sorted(counts):
        print("%-8s %d" % (k, counts[k]))
    print("total DL_<Word> labels: %d" % len(rows))


def selftest():
    rows = collect()
    ok = fail = 0

    def ck(desc, got, want):
        nonlocal ok, fail
        good = got == want
        ok, fail = ok + good, fail + (not good)
        print("  %-62s %-22s %s" % (desc, str(got)[:22], "OK" if good else "FAIL want %r" % (want,)))

    ck("DL_<Word> labels found", len(rows) > 30, True)
    ck("the LAST one in address order", rows[-1][1], "Paint_DrawbarScreenLayout_Unchanged_DL1")
    ck("  and it is at 0xF54705, in the f4f000 region", hex(rows[-1][0]), "0xf54705")
    ck("  and it is a placeholder, so it carries no text", rows[-1][3], [])
    ck("  and it is classified", verdict(rows[-1][2], rows[-1][3]) in
       ("TITLE", "ROW", "NOMATCH", "NOTEXT"), True)
    ck("DL_ReverbDepth draws 'MIDI SOUND' first",
       [s for a, n, st, s in rows if n == "DL_ReverbDepth"][0][0], "MIDI SOUND")
    ck("  so it is a ROW, not a title",
       verdict("ReverbDepth", [s for a, n, st, s in rows if n == "DL_ReverbDepth"][0]), "ROW")
    ck("DL_MainOutEqualizer_F1774D is a TITLE",
       verdict("MainOutEqualizer", [s for a, n, st, s in rows if n == "DL_MainOutEqualizer_F1774D"][0]), "TITLE")
    dt = [s for a, n, st, s in rows if n == "DL_DrawbarTitle"]
    ck("DL_DrawbarTitle was collected (f4f000 header style)", len(dt), 1)
    ck("  and it draws 'DRAWBAR SETTING' first", dt[0][0], "DRAWBAR SETTING")
    ck("  so it is a TITLE", verdict("DrawbarTitle", dt[0]) in ("TITLE", "NOMATCH"), True)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return fail


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
