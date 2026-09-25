#!/usr/bin/env python3
r"""WHERE DOES THE SOURCE'S INSTRUCTION FRAMING DISAGREE WITH AN INDEPENDENT DECODER?

QUESTION ANSWERED
-----------------
A source line `nop` or `max` or `pop sr` can assemble to the right byte and still
be a lie: it may be the 4th byte of a 7-byte instruction that an older decoder
split into phantoms (`.byte 0xd2 / popw iz / max / pop sr / push xsp / nop / nop`
is one `cp (0x03044e),0`).  The byte gate cannot see this.  This audit can: for
each run of address-contiguous instruction / `.byte` lines of a file it asks MAME's
unidasm to decode the run LINEARLY from the run's first instruction, and reports

  * MISFRAME  -- an instruction line whose address is not an instruction start
                 in unidasm's decode (the source starts an instruction inside
                 one of unidasm's).  The report gives the window of lines from
                 the first to the last disagreement, and whether unidasm's decode
                 of that window ends ON a source boundary (a clean re-frame is
                 then possible with scripts/converters/lane_uiproc_reframe.py);
  * BYTE-CODE -- a `.byte` line, inside a run of code, whose bytes unidasm
                 covers with whole instructions that start and end on source
                 line boundaries (a code-as-data island).

unidasm is linear, so a genuine data island inside a run makes unidasm lose sync
too: every hit is a CANDIDATE to be read, not a verdict.  Absurd decodes (halt,
swi, ldf, max/min/normal, incf/decf, `db`) inside unidasm's decode are counted per
window, as a data smell.

RUN
    python3 scripts/analysis/lane_uiproc_framing_audit.py --image v10 \
        --file ui/ui_window_procs.s [--file ...] [--map /tmp/map_v10.json]
  (--map: a map saved by lane_uiproc_listing.py --save-map; otherwise one is built)
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import data_range_census as drc  # noqa: E402
import lane_uiproc_listing as L  # noqa: E402

ABSURD = re.compile(r'^(halt|swi|ldf|max|min|normal|incf|decf|db)\b', re.I)


def kind(text):
    c = drc.strip_comment(text).strip()
    c = re.sub(r'^[A-Za-z_.$][\w.$@]*:\s*', '', c)
    if not c:
        return None
    if c.startswith(".byte"):
        return "B"
    if c.startswith("."):
        return "D"
    if re.match(r'^[a-z_][a-z0-9_]*\b', c, re.I):
        return "I"
    return "D"


def audit(img, rom, amap, rel):
    """-> list of (kind, from_line, to_line, from_addr, to_addr, nbad, nabsurd, dlines)
    kind: MISFRAME (window with no data directive), MISFRAME-D (window that holds
    `.ascii`/`.long`/... lines: review by hand, it may be real data), BYTE-CODE."""
    src = open(os.path.join(ROOT, img["mirror"], rel), encoding="latin-1").read().split("\n")
    emit = sorted((ad, int(k.rsplit(":", 1)[1])) for k, ad in amap.items()
                  if k.rsplit(":", 1)[0] == rel)
    rows = []
    for i, (ad, li) in enumerate(emit):
        end = emit[i + 1][0] if i + 1 < len(emit) else ad
        rows.append((ad, end, li, kind(src[li])))
    # runs of emitting lines, address-contiguous, starting with an instruction
    runs, cur = [], []
    for r in rows:
        if r[1] == r[0]:
            continue        # a label-only line: emits nothing, must not split a run
        if cur and cur[-1][1] == r[0]:
            cur.append(r)
        else:
            if cur:
                runs.append(cur)
            cur = [r] if r[1] > r[0] else []
    if cur:
        runs.append(cur)
    out = []
    for run in runs:
        while run and run[0][3] != "I":
            run = run[1:]
        if not run or run[-1][1] <= run[0][0]:
            continue
        a, b = run[0][0], run[-1][1]
        dec = L_unidasm(rom, img, a, b)
        U = {d[0] for d in dec}
        uend = {d[0] + d[1] for d in dec}
        absurd_at = {d[0]: d[2] for d in dec if ABSURD.match(d[2])}
        bad = [r for r in run if r[3] in ("I", "B", "D") and r[0] not in U]
        if bad:
            wins = []
            for r in bad:
                if wins and r[0] - wins[-1][-1][0] <= 64:
                    wins[-1].append(r)
                else:
                    wins.append([r])
            for w in wins:
                lo_ad = w[0][0]
                prev = [r for r in run if r[0] < lo_ad and r[0] in U and r[3] == "I"]
                start = prev[-1] if prev else run[0]
                nxt = [r for r in run if r[0] > w[-1][0] and r[0] in U and r[3] == "I"]
                stop = nxt[0] if nxt else None
                end_ad = stop[0] if stop else b
                nabs = sum(1 for x in absurd_at if start[0] <= x < end_ad)
                dl = [r[2] + 1 for r in run if start[0] <= r[0] < end_ad and r[3] == "D"]
                out.append(("MISFRAME-D" if dl else "MISFRAME", start[2] + 1,
                            (stop[2] if stop else run[-1][2] + 1),
                            start[0], end_ad, len(w), nabs, dl))
        for r in run:
            # `\t.byte\t...\t; reading` is the re-framer's own spelling of an
            # instruction the backend cannot encode: already handled
            if r[3] == "B" and re.match(r'^\t\.byte\t[^;]*;', src[r[2]]):
                continue
            if r[3] == "B" and r[0] in U and r[1] in (U | uend):
                out.append(("BYTE-CODE", r[2] + 1, r[2] + 1, r[0], r[1], 1, 0, []))
    return out


def L_unidasm(rom, img, a, b):
    off = a - img["base"]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(rom[off:off + (b - a)])
        p = f.name
    try:
        txt = subprocess.run([L.UNIDASM, p, "-arch", "tlcs900", "-basepc", "%x" % a],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(p)
    res = []
    for line in txt.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            res.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", action="append", required=True)
    ap.add_argument("--map")
    ap.add_argument("--summary", action="store_true")
    ap.add_argument("--windows-out", help="write merged [FROM, TO] line windows (JSON) for "
                    "lane_uiproc_reframe.py --windows; only valid with one --file")
    a = ap.parse_args()
    img = L.image(a.image)
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    if a.map:
        amap = json.load(open(a.map))["amap"]
    else:
        amap, rom, _ = L.build(img)
    for rel in a.file:
        res = audit(img, rom, amap, rel)
        mis = [r for r in res if r[0] == "MISFRAME"]
        misd = [r for r in res if r[0] == "MISFRAME-D"]
        bc = [r for r in res if r[0] == "BYTE-CODE"]
        print("== %s %s: %d misframe windows (%d bad lines), %d more holding data directives "
              "(%d bad lines), %d .byte lines that decode as aligned code (%d B)" % (
                  a.image, rel, len(mis), sum(r[5] for r in mis), len(misd),
                  sum(r[5] for r in misd), len(bc), sum(r[4] - r[3] for r in bc)))
        if not a.summary:
            for r in mis:
                print("  MISFRAME lines %d-%d  %06X-%06X  bad=%d absurd=%d" % r[1:7])
            for r in misd:
                print("  MISFRAME-D lines %d-%d  %06X-%06X  bad=%d absurd=%d  data lines %s"
                      % (r[1:7] + (r[7][:8],)))
            # merge BYTE-CODE into line ranges
            m = []
            for r in bc:
                if m and r[1] - m[-1][1] <= 3 and r[3] - m[-1][3] <= 64:
                    m[-1][1] = r[1]
                    m[-1][3] = r[4]
                else:
                    m.append([r[1], r[1], r[3], r[4]])
            for x in m:
                print("  BYTE-CODE lines %d-%d  %06X-%06X" % tuple(x))
        if a.windows_out:
            w = sorted([r[1], r[2]] for r in res if r[0] != "MISFRAME-D")
            merged = []
            for x in w:
                if merged and x[0] <= merged[-1][1] + 1:
                    merged[-1][1] = max(merged[-1][1], x[1])
                else:
                    merged.append(list(x))
            json.dump(merged, open(a.windows_out, "w"))
            print("wrote %d windows to %s" % (len(merged), a.windows_out))
            wd = sorted([r[1], r[2]] for r in res if r[0] == "MISFRAME-D")
            json.dump(wd, open(a.windows_out + ".data-review", "w"))
            print("wrote %d data-holding windows (REVIEW BY HAND) to %s.data-review"
                  % (len(wd), a.windows_out))


if __name__ == "__main__":
    main()
