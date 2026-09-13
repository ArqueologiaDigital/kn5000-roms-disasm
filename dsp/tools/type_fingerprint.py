#!/usr/bin/env python3
"""type_fingerprint.py -- WHICH effect program did the machine actually load?

QUESTION IT ANSWERS
    `dsp/analysis/data/typewalk/TYPE_MAP.md` maps a DSP EFFECT TYPE index to a program, and it is
    **off by one above index 8** — two adjacent slots that share a program image collapsed into one
    row when the map was built. That blocks the catalogue regression for 28 of the 38 programs,
    because a sweep addressed by index would silently test the wrong program.

    The map's own header says how to do it right: **match the uploaded program image against the
    listings on 16 words** (4 is not enough — it collides for 8 of 38 programs in 4 groups). This
    is that matcher, and it answers the question for any run:

        python3 dsp/tools/type_fingerprint.py <kn5000_dsp1_upload.txt> [--base 84] [--words 16]

    It replays the uC-IF capture's command-0x01 transfers into a 384-word I-RAM image, takes the
    16 words at the unit-0 body base, and reports which of the 38 committed listings matches.

⚠ WHY IT IS NEEDED IN EVERY RUN, not once
    §193's standing requirement: a transport that is merely *more* reliable is not a transport that
    is correct. `type_select.lua` saturates UP and steps DOWN to reduce dropped steps, but the
    obligation is to FINGERPRINT THE LOADED PROGRAM IN THE SAME RUN and copy the capture before the
    next launch overwrites it.

⚠ TWO PRACTICAL NOTES, both of which cost a run on 2026-09-13
    * `type_enum.lua` and `type_select.lua` print to **stdout/stderr, not `error.log`** — capture
      with `> out.txt 2>&1`, not with `-log` + `cp error.log`.
    * the panel-title read at `0x30AE5` does **not** return the effect name in the current build,
      so the display cannot be used to identify the program. This matcher exists because of that.
"""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DISASM = os.path.join(os.path.dirname(HERE), "disasm")
XFER = re.compile(r"transfer\s+(\d+):\s+cmd\s+0x([0-9A-Fa-f]+)\s+(\d+) bytes")
HEXL = re.compile(r"\s+([0-9A-Fa-f]{4}):\s+((?:[0-9A-Fa-f]{2}\s*)+)$")
ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")


def transfers(path):
    out, cur = [], None
    for line in open(path, errors="replace"):
        m = XFER.match(line)
        if m:
            cur = {"cmd": int(m.group(2), 16), "data": bytearray()}
            out.append(cur)
            continue
        m = HEXL.match(line)
        if m and cur is not None:
            cur["data"] += bytes.fromhex(m.group(2).replace(" ", ""))
    return out


def iram_image(path):
    """Replay every cmd-0x01 transfer into a 384-word I-RAM image.

    A command-0x01 payload is a 16-bit word address followed by N x 5 bytes, one 36-bit I-RAM
    word each (the Sub CPU's own handlers divide by literal 5, and captured uploads tile I-RAM
    exactly). LAST WRITE WINS, which is what makes the image the program actually resident.
    """
    ram = [None] * 384
    for t in transfers(path):
        if t["cmd"] != 0x01 or len(t["data"]) < 2:
            continue
        addr = (t["data"][0] << 8) | t["data"][1]
        body = t["data"][2:]
        for i in range(len(body) // 5):
            w = body[i * 5:i * 5 + 5]
            a = addr + i
            if 0 <= a < 384:
                ram[a] = int.from_bytes(w, "big") & 0xfffffffff
    return ram


def listings():
    out = {}
    for f in sorted(glob.glob(os.path.join(DISASM, "prog*.dsm"))):
        ws = []
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                ws.append((int(m.group(1)), int(m.group(2), 16)))
        ws.sort()
        out[os.path.basename(f)[:-4]] = [w for _, w in ws]
    return out


def main():
    argv = sys.argv[1:]
    caps = [a for i, a in enumerate(argv)
            if not a.startswith("--") and (i == 0 or argv[i - 1] not in ("--base", "--words"))]
    base = int(argv[argv.index("--base") + 1]) if "--base" in argv else 84
    nw = int(argv[argv.index("--words") + 1]) if "--words" in argv else 16
    if not caps:
        print(__doc__)
        return 2

    progs = listings()
    rc = 0
    for cap in caps:
        ram = iram_image(cap)
        got = ram[base:base + nw]
        name = os.path.basename(cap)
        if any(w is None for w in got):
            print("%-40s ⛔ I-RAM %d..%d not fully uploaded in this capture"
                  % (name, base, base + nw - 1))
            rc = 1
            continue
        hits = [p for p, ws in progs.items() if len(ws) >= nw and ws[:nw] == got]
        if len(hits) == 1:
            print("%-40s ✅ %s" % (name, hits[0]))
        elif hits:
            print("%-40s ⚠ AMBIGUOUS on %d words: %s" % (name, nw, ", ".join(hits)))
            rc = 1
        else:
            print("%-40s ⛔ no listing matches; first words %s"
                  % (name, " ".join("%010X" % w for w in got[:4])))
            rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
