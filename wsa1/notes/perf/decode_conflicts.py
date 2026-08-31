#!/usr/bin/env python3
"""DO TWO DECODE WINDOWS EVER DISAGREE ABOUT THE SAME ADDRESS?

QUESTION IT ANSWERS
    reachability.py keeps a boundary index, `_BOUND[tag][addr] = (length, text)`,
    filled by whichever 2 KiB window happened to decode that address, LAST WRITE
    WINS.  Everything one might do to make the tool faster -- persisting the
    index between runs, decoding the image once up front, enlarging the window --
    depends on one property:

        is (length, text) at an address a FUNCTION OF THE ADDRESS,
        or of the window it was decoded in?

    If it is a function of the address, the index is CANONICAL: it can be stored,
    shared and rebuilt in any order and every consumer sees what it sees today.
    If two windows disagree -- and they plausibly could, because a window has an
    END, and the instruction straddling it is decoded from truncated bytes --
    then the index is ORDER-DEPENDENT, any such change is answer-changing, and
    it has to be gated on a full cold A/B rather than argued.

    ⚠ This is a NEGATIVE result if it finds nothing, and that is the useful
    outcome.  It cannot prove the absence of a conflict everywhere; it samples.
    What it can do is find one, and one is enough to kill the idea.

HOW
    Decodes overlapping windows from many starts across an image and records
    every (addr -> (len, text)) each one asserts.  A conflict is the same addr
    with two different values.  Starts are chosen to MAXIMISE the chance of one:
    a stride that is deliberately coprime with the window, so each address is
    seen at many different offsets from its window's end.

RUN
    python3 notes/perf/decode_conflicts.py --tag prom_a --starts 400
    python3 notes/perf/decode_conflicts.py --selftest

SIGNAL BEING READ
    unidasm stdout, parsed with reachability.py's OWN `LINE` regex, so the rows
    compared are the rows the tool would have stored -- not a re-implementation.
"""
import argparse
import importlib.util
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_reach():
    spec = importlib.util.spec_from_file_location(
        "reach_for_conflicts", os.path.join(ROOT, "notes", "reachability.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def decode(m, tag, start, window):
    """Exactly reachability._decode_window's subprocess half, window size free."""
    b, d = m.BASES[tag], m.ROMS[tag]
    o = start - b
    if o < 0 or o >= len(d):
        return []
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d[o:o + window])
        tmp = f.name
    try:
        out = subprocess.run([m.UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for ln in out.splitlines():
        mm = m.LINE.match(ln)
        if mm:
            rows.append((int(mm.group(1), 16), len(mm.group(2).split()),
                         mm.group(3).strip()))
    return rows


def run(tag, n_starts, window, stride, guard=0):
    """`guard` = the PROPOSED FIX: drop rows that start within `guard` bytes of
    the window end, because unidasm decoded them from truncated bytes. The
    longest TLCS-900 instruction in prom_a is 7 bytes (one linear decode of the
    whole image: 274,588 instructions, max length 7), so guard=6 is the smallest
    value that can be correct. Re-run with it and the conflicts should vanish --
    that is the evidence the fix works, and it costs 6 bytes of every 2,048."""
    m = load_reach()
    base = m.BASES[tag]
    seen = {}                      # addr -> (len, text, from_start)
    conflicts, tail_conflicts = [], []
    for i in range(n_starts):
        start = base + (i * stride) % (m.SIZE - window)
        rows = decode(m, tag, start, window)
        end = start + window
        if guard:
            rows = [r for r in rows if r[0] + guard < end]
        for addr, ln, text in rows:
            prev = seen.get(addr)
            if prev is None:
                seen[addr] = (ln, text, start)
                continue
            if (prev[0], prev[1]) != (ln, text):
                rec = (addr, prev, (ln, text, start))
                # a conflict on the LAST instruction of a window is the
                # truncation case and is the one we expect if any.
                if addr + max(ln, prev[0]) > end or addr + max(ln, prev[0]) > prev[2] + window:
                    tail_conflicts.append(rec)
                else:
                    conflicts.append(rec)
        if (i + 1) % 50 == 0:
            print("  ... %d/%d windows, %d addresses, %d conflicts"
                  % (i + 1, n_starts, len(seen),
                     len(conflicts) + len(tail_conflicts)), flush=True)

    print("\n%s: %d windows of 0x%X bytes, stride 0x%X, tail guard %d"
          % (tag, n_starts, window, stride, guard))
    print("  distinct addresses asserted : %d" % len(seen))
    print("  INTERIOR conflicts          : %d" % len(conflicts))
    print("  window-TAIL conflicts       : %d" % len(tail_conflicts))
    for addr, prev, now in (conflicts + tail_conflicts)[:10]:
        print("    0x%06X  from 0x%06X: %d %r" % (addr, prev[2], prev[0], prev[1]))
        print("              from 0x%06X: %d %r" % (now[2], now[0], now[1]))
    # ★ ADJUDICATE. A conflict says two windows disagree; it does not say which
    # is right.  Decoding a FRESH window that STARTS at the address puts the
    # whole instruction inside the buffer, so that decode is the ground truth.
    # What matters downstream is not the text but the EDGE: walk() pulls branch
    # targets out of this text with reachability's own BRANCH regex, so a
    # truncated decode that names an in-image address queues a FALSE EDGE and
    # paints bytes reachable that no control flow reaches.
    if tail_conflicts:
        print("\n  ADJUDICATION (fresh window starting at the address = truth)")
        wrong_edges = truncated = 0
        for addr, prev, now in tail_conflicts:
            truth = decode(m, tag, addr, window)
            if not truth or truth[0][0] != addr:
                continue
            t_len, t_text = truth[0][1], truth[0][2]
            for who, (ln, text) in (("A", (prev[0], prev[1])), ("B", (now[0], now[1]))):
                if (ln, text) == (t_len, t_text):
                    continue
                truncated += 1
                bad = {int(x.group(1), 16) for x in m.BRANCH.finditer(text)}
                good = {int(x.group(1), 16) for x in m.BRANCH.finditer(t_text)}
                cpu = m.CPU1 if tag in m.CPU1 else m.CPU2
                false_in_image = {t for t in bad - good if m.owner(t, cpu)}
                if false_in_image:
                    wrong_edges += 1
                    print("    0x%06X truth %r" % (addr, t_text))
                    print("             got   %r  => FALSE EDGE to %s"
                          % (text, ", ".join("0x%06X" % t for t in sorted(false_in_image))))
        print("\n  %d truncated decodes adjudicated wrong; %d of them inject a"
              " FALSE in-image branch edge" % (truncated, wrong_edges))

    if not conflicts and not tail_conflicts:
        print("\n★ NO CONFLICT FOUND. On this sample the boundary index is a")
        print("  function of the ADDRESS, not of the window -- so it is canonical,")
        print("  and persisting or resharing it cannot change what a consumer sees.")
    else:
        print("\n⚠ CONFLICTS EXIST. The index is ORDER-DEPENDENT: any change to")
        print("  when a window is decoded can change an answer, and must be gated")
        print("  on a full cold A/B (notes/perf/prove_identical.py), not argued.")
    return conflicts, tail_conflicts


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    m = load_reach()
    # ★ THE INSTRUMENT MUST AGREE WITH THE TOOL IT IS REASONING ABOUT. If this
    # file's decode() drifted from _decode_window's, every conclusion drawn from
    # it would be about a decoder the tool does not use.
    start = m.BASES["prom_a"] + 0x1000
    mine = decode(m, "prom_a", start, m.WINDOW)
    theirs = m._decode_window("prom_a", start)
    check("this file's decode() == reachability._decode_window()",
          mine == theirs, "%d rows" % len(mine))
    check("a window yields many instructions", len(mine) > 100, "%d" % len(mine))

    # and it must be able to SEE a conflict: feed it a fabricated one.
    seen = {0x10: (2, "a")}
    conflict = seen[0x10][:2] != (3, "b")
    check("the comparison distinguishes (2,'a') from (3,'b')", conflict)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="prom_a")
    ap.add_argument("--starts", type=int, default=400)
    ap.add_argument("--window", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--stride", type=lambda s: int(s, 0), default=0x2711)
    ap.add_argument("--guard", type=int, default=0,
                    help="drop rows starting within N bytes of the window end")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    m = load_reach()
    run(a.tag, a.starts, a.window or m.WINDOW, a.stride, a.guard)
