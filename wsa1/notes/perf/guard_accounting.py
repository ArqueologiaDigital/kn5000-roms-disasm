#!/usr/bin/env python3
"""WHICH BYTES DID THE WINDOW-TAIL GUARD MOVE, AND WHAT MOVED EACH ONE?

QUESTION IT ANSWERS
    The guard (notes/reachability.py, `MAXLEN`) changes the published figure:
    ANY 1,670 -> 1,702, and a 9,216-byte span leaves the work list. A figure that
    moves is only worth publishing if every byte of the move is ACCOUNTED FOR.
    So, per image:

        which byte addresses does the guarded walk reach that the old one did
        not, which does it no longer reach, and for EACH such run, which
        truncated window-tail decode is responsible?

    ⚠ It is not enough that the new number is "more correct in principle". If a
    moved byte cannot be attributed to a specific truncated decode, this file
    prints it as UNEXPLAINED and the lane is supposed to stop.

HOW, AND WHY IT IS THE SAME TOOL ON BOTH SIDES
    The pre-guard tool is reachability.py with `MAXLEN = 0`: the filter
    `r[0] + MAXLEN <= end` then keeps every row, because every row of a window
    starts before that window's end. So both sides are the SAME FILE, one module
    attribute apart, and there is no second copy of the walk to drift.

    ★ AND THAT EQUIVALENCE IS CHECKED, NOT ASSUMED: --explain refuses to report
    unless the MAXLEN=0 side reproduces, exactly, the figures recorded in
    notes/perf/baseline/ from the committed pre-guard tool (commit b379204).

    Two walks of three images is ~35 minutes and ~8 GB of `_WIN` per side, so
    the sides are run as SEPARATE processes that dump artefacts, and the
    comparison is a third, cheap pass:

        python3 notes/perf/guard_accounting.py --side pre  --out DIR   # ~17 min
        python3 notes/perf/guard_accounting.py --side post --out DIR   # ~17 min
        python3 notes/perf/guard_accounting.py --explain DIR           # seconds
        python3 notes/perf/guard_accounting.py --selftest

    DIR holds ~200 MB of regenerable dumps; put it in scratch, not in the tree.
    The REPORT is what gets committed (notes/perf/GUARD-ACCOUNTING-2026-08-31.txt).

SIGNAL BEING READ
    * reached byte set -- `_walk_from()`'s return, for the STRONG classes and for
      all classes, exactly as analyse() calls it (STRONG first, then all: the
      pre-guard index is order-dependent, so the ORDER is part of the reading).
    * the LIE TABLE -- every row a window would have contributed from its last 6
      bytes, i.e. exactly the rows the guard drops, with the window that produced
      it. A row is a LIE if a fresh decode STARTING at that address (whole
      instruction inside the buffer) disagrees with it.
    * the CANONICAL INDEX -- the guarded side's `_BOUND`, which by construction
      contains no truncated row, used to ask what really branches where.

ATTRIBUTION -- the three mechanisms a lie can move a byte
    RESUME   a lie's LENGTH is wrong, so the old walk resumed at the wrong
             offset and never framed the bytes the true instruction covers.
    EDGE+    the lie hid a REAL branch target: the true text names an address
             the old walk therefore never queued.
    EDGE-    the lie invented a FALSE branch target: the old walk queued an
             address no control flow reaches. This is the 9,216-byte span.
    CASCADE  a run reached from code that one of the above first made reachable.
"""
import argparse
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
# ★ THE PRE-GUARD ANSWERS, FROZEN. notes/perf/baseline/ moves with the tool --
# it was re-recorded when the guard landed -- so the accounting reads a frozen
# copy of what the tool said BEFORE, or it would be checking itself against
# itself.
BASELINE = os.path.join(HERE, "baseline-preguard-2026-08-31")


def load_reach(maxlen):
    spec = importlib.util.spec_from_file_location(
        "reach_guard_acct_%d" % maxlen, os.path.join(ROOT, "notes", "reachability.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    m.MAXLEN = maxlen
    return m


def load_conflicts():
    spec = importlib.util.spec_from_file_location(
        "decode_conflicts_for_acct", os.path.join(HERE, "decode_conflicts.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def runs(seen):
    """A byte set as [(lo, hi)] maximal runs -- 300k ints do not belong in JSON."""
    out = []
    for x in sorted(seen):
        if out and out[-1][1] == x:
            out[-1][1] = x + 1
        else:
            out.append([x, x + 1])
    return out


def unruns(rs):
    s = set()
    for lo, hi in rs:
        s.update(range(lo, hi))
    return s


# ------------------------------------------------------------------ one side
def run_side(side, outdir, tags):
    m = load_reach(7 if side == "post" else 0)
    os.makedirs(outdir, exist_ok=True)
    for tag in tags:
        cpu = m.CPU1 if tag in m.CPU1 else m.CPU2
        proven, spans = m.proven_and_incbin(tag)
        sd = m.seeds(tag, cpu)
        # ⚠ THE ORDER IS PART OF THE MEASUREMENT. analyse() walks STRONG first
        # and then everything, and the pre-guard boundary index depends on which
        # window got somewhere first, so walking them the other way round would
        # be a different experiment.
        strong = m._walk_from(tag, cpu, sd, m.STRONG, proven)
        allc = m._walk_from(tag, cpu, sd, list(sd), proven)
        rec = {"tag": tag, "side": side, "maxlen": m.MAXLEN,
               "spans": [list(s) for s in spans],
               "seeds": {k: sorted(v) for k, v in sd.items()},
               "reached": len(allc), "reached_strong": len(strong),
               "any_runs": runs(allc), "strong_runs": runs(strong)}
        json.dump(rec, open(os.path.join(outdir, "%s.%s.json" % (tag, side)), "w"))
        print("  %s %s: reached %d (strong %d), %d windows decoded"
              % (tag, side, len(allc), len(strong),
                 sum(1 for k in m._WIN if k[0] == tag)), flush=True)

        # ★ THE BOUNDARY INDEX EACH SIDE ENDED WITH. The pre side's is the
        # instrument for everything downstream: an address where it disagrees
        # with the canonical one is a truncated decode the walk actually used,
        # and an address it holds that is not a canonical boundary at all is
        # the walk running down a SHIFTED stream after one.
        bi = {("%d" % a): [ln, text] for a, (ln, text) in m._BOUND[tag].items()}
        json.dump(bi, open(os.path.join(outdir, "%s.bound.%s.json" % (tag, side)), "w"))
        print("     boundary index: %d addresses" % len(bi), flush=True)

        if side == "pre":
            # THE LIE TABLE: every row the guard would drop, with its window.
            d = m.ROMS[tag]
            b = m.BASES[tag]
            tail = []
            for (t_, start), rows in m._WIN.items():
                if t_ != tag:
                    continue
                if start - b + m.WINDOW >= len(d):
                    continue          # window ran off the image; nothing truncated
                end = start + m.WINDOW
                for addr, ln, text in rows:
                    if addr + 7 > end:
                        tail.append([addr, ln, text, start])
            json.dump(tail, open(os.path.join(outdir, "%s.tail.json" % tag), "w"))
            print("     %d tail rows the guard drops" % len(tail), flush=True)
    return 0


# ------------------------------------------------- the pre side must be the old tool
BASE_REACHED = re.compile(
    r'^(\w+)\s+reached\s+([\d,]+) bytes \| still \.incbin\s+([\d,]+) \|.*?UNCONVERTED\s+([\d,]+)')
BASE_SPAN = re.compile(r'^\s+0x([0-9A-F]{6})-0x([0-9A-F]{6})\s+(\d+) bytes,\s+(\d+) reachable')


def parse_baseline_spans():
    """The committed pre-guard answers: {tag: (reached, incbin, reach_in_incbin)}
    and {(tag, lo, hi): reachable}."""
    per_image, per_span, tag = {}, {}, None
    for ln in open(os.path.join(BASELINE, "spans.txt")):
        m = BASE_REACHED.match(ln)
        if m:
            tag = m.group(1)
            per_image[tag] = tuple(int(x.replace(",", "")) for x in m.groups()[1:])
            continue
        m = BASE_SPAN.match(ln)
        if m and tag:
            per_span[(tag, int(m.group(1), 16), int(m.group(2), 16))] = int(m.group(4))
    return per_image, per_span


# ---------------------------------------------------------------- attribution
def targets_of(m, text):
    return {int(x.group(1), 16) for x in m.BRANCH.finditer(text)}


def edge_index(m, bound, reached):
    """target -> [addresses whose decoded text names it], restricted to rows the
    walk actually CONSUMED (a row's own address is marked when it is walked), so
    a window that was decoded and thrown away cannot supply a phantom source."""
    out = {}
    for a, (_ln, text) in bound.items():
        if a not in reached or "0x" not in text:
            continue
        for t in targets_of(m, text):
            out.setdefault(t, []).append(a)
    return out


def chain(m, bound, start, stop, steps=64):
    """The instruction stream one boundary index asserts, from `start`.

    ★ AND IT STOPS WHERE walk() STOPS. walk() returns at the first row matching
    FLOW_END, so a model that reads past a `ret` or a `swi` claims bytes the walk
    never marked -- which is precisely the difference this file is measuring."""
    out, a = [], start
    while a in bound and len(out) < steps and a < stop:
        ln, text = bound[a]
        out.append((a, ln, text))
        if m.FLOW_END.match(text):
            break
        a += ln
    return out


def covered(rows):
    s = set()
    for a, ln, _t in rows:
        s.update(range(a, a + ln))
    return s


class Image(object):
    """One image's two sides, and the questions asked of them."""

    def __init__(self, m, outdir, tag):
        self.m, self.tag = m, tag
        pre = json.load(open(os.path.join(outdir, "%s.pre.json" % tag)))
        post = json.load(open(os.path.join(outdir, "%s.post.json" % tag)))
        self.spans = [tuple(x) for x in pre["spans"]]
        self.pre_any, self.post_any = unruns(pre["any_runs"]), unruns(post["any_runs"])
        self.pre_str, self.post_str = unruns(pre["strong_runs"]), unruns(post["strong_runs"])
        self.pre_b = {int(k): tuple(v) for k, v in json.load(
            open(os.path.join(outdir, "%s.bound.pre.json" % tag))).items()}
        self.post_b = {int(k): tuple(v) for k, v in json.load(
            open(os.path.join(outdir, "%s.bound.post.json" % tag))).items()}
        # ⚠⚠ EVERY VARIANT, NOT THE FIRST. An address near the end of one window
        # is in the MIDDLE of the next, so the same address appears in the tail
        # table twice: once truncated and once whole. Keeping one of them threw
        # away exactly the rows this file exists to find.
        self.tail_rows = {}
        for addr, ln, text, start in json.load(
                open(os.path.join(outdir, "%s.tail.json" % tag))):
            v = self.tail_rows.setdefault(addr, [])
            if (ln, text) not in [(l, t) for l, t, _w in v]:
                v.append((ln, text, start))
        # ⚠ AND THE FINAL INDEX HIDES THE LIE TOO: `_BOUND[addr]` is last write
        # wins, so a window that later decoded the same address from WHOLE bytes
        # overwrote the truncated row the walk had already consumed. The tail
        # table is the only record of what the walk was actually handed.
        lie_rows = {}
        for a2 in self.tail_rows:
            e = self.lie_at(a2)
            if e:
                lie_rows[a2] = (e[0], e[1])
        self.pre_rows = dict(self.pre_b)
        self.pre_rows.update(lie_rows)
        self.pre_e = edge_index(m, self.pre_rows, self.pre_any)
        self.post_e = edge_index(m, self.post_b, self.post_any)
        self.seeds = set()
        for v in pre["seeds"].values():
            self.seeds.update(v)

    # ★ WHAT AN ADDRESS IS, in one word.
    def lie_at(self, a):
        """A row some window asserted at `a` from truncated bytes: `a` IS a
        boundary of the canonical decode, and the window said something else."""
        c = self.post_b.get(a)
        if c is None:
            return None
        for ln, text, w in self.tail_rows.get(a, ()):
            if (ln, text) != c:
                return (ln, text, w)
        return None

    def kind_of(self, a):
        if self.lie_at(a):
            return "truncated"
        if a in self.post_b:
            return "agrees"
        if a in self.pre_b or a in self.tail_rows:
            return "off-stream"       # not a boundary of the canonical decode
        return "absent"

    def arrival_lie(self, a, back=8):
        """★ HOW THE WALK ARRIVED AT AN ADDRESS THAT IS NOT A BOUNDARY: some
        truncated row ENDED exactly there. Its wrong LENGTH is the whole
        mechanism -- the walk resumes inside a real instruction, and what it
        decodes from there is bytes the machine never executes as an
        instruction."""
        for d in range(1, back + 1):
            for ln, text, w in self.tail_rows.get(a - d, ()):
                if a - d + ln == a and (ln, text) != self.post_b.get(a - d):
                    return (a - d, ln, text, w)
        return None

    def canon_anchor(self, a, back=8):
        """The canonical instruction that CONTAINS `a`."""
        for d in range(back):
            e = self.post_b.get(a - d)
            if e and a - d + e[0] > a:
                return a - d
        return None

    def pre_chain(self, start, stop, lie=None, steps=64):
        """The stream the pre-guard walk had: the truncated row at `lie`, and
        then whatever its index holds -- which after a wrong length is a run of
        addresses that are not instruction boundaries at all. Stops at a
        FLOW_END, as walk() does."""
        out, a = [], start
        while len(out) < steps and a < stop:
            e = self.lie_at(a) if (lie is None or a == lie) else None
            r = (e[0], e[1]) if e else self.pre_b.get(a)
            if not r:
                break
            out.append((a, r[0], r[1]))
            if self.m.FLOW_END.match(r[1]):
                break
            a += r[0]
        return out

    def candidates(self, lo, back=256):
        """Addresses before `lo` where the pre side was truncated, or was
        already off the canonical stream. ★ TRUNCATED FIRST: an off-stream
        address is a CONSEQUENCE of a truncated one, and naming the consequence
        as the cause would be a true sentence about the wrong address."""
        rng = range(lo - 1, max(lo - back, 0) - 1, -1)
        return ([a for a in rng if self.kind_of(a) == "truncated"] +
                [a for a in rng if self.kind_of(a) == "off-stream"])

    def stream_test(self, L, lo, hi, gained):
        """Does taking the truncated row at L, instead of the whole-byte one,
        frame [lo,hi) differently? That is the RESUME mechanism, tested rather
        than assumed: follow both streams from the same place and look."""
        anchor = L if L in self.post_b else self.canon_anchor(L)
        if anchor is None:
            return None
        post_c = chain(self.m, self.post_b, anchor, hi + 32)
        pre_c = self.pre_chain(L, hi + 32, lie=L)
        r = set(range(lo, hi))
        pc, qc = covered(pre_c) & r, covered(post_c) & r
        if (gained and qc and not pc) or ((not gained) and pc and not qc):
            return (anchor, pre_c, post_c)
        return None

    def stream_lines(self, L, anchor, pre_c, post_c):
        out = ["        the two decodes part at 0x%06X (%s)" % (L, self.kind_of(L))]
        e = self.lie_at(L)
        if e:
            out.append("          it was the last row of the 2 KiB window at 0x%06X,"
                       " which ends at 0x%06X" % (e[2], e[2] + self.m.WINDOW))
        for name, rows in (("pre ", pre_c[:8]), ("post", post_c[:8])):
            out.append("          %s %s" % (name, "  ".join(
                "%06X:%d %s" % (a, ln, t) for a, ln, t in rows)))
        return out

    def explain(self, lo, hi, gained):
        """(mechanism, lines) for one moved run. The mechanisms are the three a
        truncated tail row has: it invents an edge, it hides one, or it hands the
        walk a wrong LENGTH and the walk runs on down a shifted stream."""
        out = []
        src_pre = sorted(self.pre_e.get(lo, []))
        src_post = sorted(self.post_e.get(lo, []))
        seeded = lo in self.seeds

        # 1 -- A STREAM THAT DIVERGES: the wrong length, framing other bytes.
        for L in self.candidates(lo):
            got = self.stream_test(L, lo, hi, gained)
            if got:
                anchor, pre_c, post_c = got
                return ("STREAM (a wrong length, then a shifted decode)",
                        self.stream_lines(L, anchor, pre_c, post_c))

        # 2 -- AN EDGE THAT EXISTS ON ONE SIDE ONLY.
        if not seeded and (bool(src_pre) != bool(src_post)):
            who, side = (src_pre, "pre") if src_pre else (src_post, "post")
            mech = ("EDGE- (a phantom edge, queued from a truncated decode)" if src_pre
                    else "EDGE+ (a real edge the truncation had hidden)")
            for a in who[:3]:
                b = (self.pre_rows if side == "pre" else self.post_b)[a]
                out.append("        queued from 0x%06X %r  [%s]" % (a, b[1], self.kind_of(a)))
                e = self.lie_at(a)
                if e:
                    # the row was there on both sides, but one of them read it
                    # from truncated bytes -- print BOTH, that is the finding.
                    out.append("          truncated: %d B %r   (window 0x%06X..0x%06X)"
                               % (e[0], e[1], e[2], e[2] + self.m.WINDOW))
                    out.append("          whole bytes: %d B %r"
                               % (self.post_b[a][0], self.post_b[a][1]))
                elif a not in self.post_b:
                    out.append("          ⚠ 0x%06X IS NOT AN INSTRUCTION BOUNDARY. The"
                               " walk was inside a real instruction when it decoded that."
                               % a)
                    anc = self.canon_anchor(a)
                    if anc is not None:
                        out.append("          the canonical instruction covering it:"
                                   " 0x%06X %d B %r"
                                   % (anc, self.post_b[anc][0], self.post_b[anc][1]))
                    arr = self.arrival_lie(a)
                    if arr:
                        aa, ln, text, w = arr
                        out.append("          it arrived there because the window at"
                                   " 0x%06X ends at 0x%06X, mid-instruction:"
                                   % (w, w + self.m.WINDOW))
                        out.append("            0x%06X truncated: %d B %r -> resumes at 0x%06X"
                                   % (aa, ln, text, aa + ln))
                        c = self.post_b.get(aa)
                        if c:
                            out.append("            0x%06X whole bytes: %d B %r -> resumes"
                                       " at 0x%06X" % (aa, c[0], c[1], aa + c[0]))
            return mech, out

        # 3 -- CASCADE: queued from a row that one of the above had already moved.
        moved = (self.post_any - self.pre_any) if gained else (self.pre_any - self.post_any)
        for a in (src_post if gained else src_pre):
            if a in moved:
                b = (self.post_b if gained else self.pre_rows)[a]
                return ("CASCADE (from a byte this same guard moved)",
                        ["        queued from 0x%06X %r" % (a, b[1])])
        return None, out


def explain(outdir, tags):
    m = load_reach(7)
    base_image, _base_span = parse_baseline_spans()
    fail = 0
    print("=" * 78)
    print("GUARD ACCOUNTING -- every byte the window-tail guard moved")
    print("=" * 78)
    grand = {"pa": 0, "qa": 0, "ps": 0, "qs": 0}

    for tag in tags:
        im = Image(m, outdir, tag)
        spans = im.spans
        print("\n" + "-" * 78)
        print("%s" % tag)
        print("-" * 78)

        want = base_image.get(tag)
        got_incbin = sum(hi - lo for lo, hi in spans)
        in_span = lambda s: sum(1 for lo, hi in spans for x in range(lo, hi) if x in s)
        pa, qa = in_span(im.pre_any), in_span(im.post_any)
        ps, qs = in_span(im.pre_str), in_span(im.post_str)
        okr = want and (len(im.pre_any), got_incbin, pa) == want
        print("  %s pre-guard side reproduces the committed baseline: reached %s (want %s),"
              " .incbin %s, reachable-in-.incbin %s (want %s)"
              % ("ok  " if okr else "FAIL", format(len(im.pre_any), ","),
                 format(want[0], ",") if want else "?", format(got_incbin, ","),
                 format(pa, ","), format(want[2], ",") if want else "?"))
        if not okr:
            fail += 1
        for k, v in (("pa", pa), ("qa", qa), ("ps", ps), ("qs", qs)):
            grand[k] += v
        print("  reached          %10s -> %10s  (%+d)"
              % (format(len(im.pre_any), ","), format(len(im.post_any), ","),
                 len(im.post_any) - len(im.pre_any)))
        print("  in .incbin ANY   %10s -> %10s  (%+d)" % (format(pa, ","), format(qa, ","), qa - pa))
        print("  in .incbin STRONG%10s -> %10s  (%+d)" % (format(ps, ","), format(qs, ","), qs - ps))

        moved_spans = []
        for lo, hi in spans:
            a0 = sum(1 for x in range(lo, hi) if x in im.pre_any)
            a1 = sum(1 for x in range(lo, hi) if x in im.post_any)
            s0 = sum(1 for x in range(lo, hi) if x in im.pre_str)
            s1 = sum(1 for x in range(lo, hi) if x in im.post_str)
            if (a0, s0) != (a1, s1):
                moved_spans.append((lo, hi, a0, a1, s0, s1))
        if moved_spans:
            print("\n  SPANS WHOSE COUNTS MOVED  (the work list)")
            for lo, hi, a0, a1, s0, s1 in moved_spans:
                note = ("  <- LEAVES the work list" if a1 == 0 and a0 else
                        "  <- ENTERS the work list" if a0 == 0 and a1 else "")
                print("    0x%06X-0x%06X %8s B   any %5d -> %5d   STRONG %3d -> %3d%s"
                      % (lo, hi, format(hi - lo, ","), a0, a1, s0, s1, note))

        g_runs = runs(sorted(im.post_any - im.pre_any))
        l_runs = runs(sorted(im.pre_any - im.post_any))
        print("\n  bytes GAINED %s in %d run(s);  bytes LOST %s in %d run(s)"
              % (format(sum(h - l for l, h in g_runs), ","), len(g_runs),
                 format(sum(h - l for l, h in l_runs), ","), len(l_runs)))
        unex = 0
        for kind, rs, gained in (("GAINED", g_runs, True), ("LOST", l_runs, False)):
            if not rs:
                continue
            print("\n  %s" % kind)
            for lo, hi in rs:
                where = next(("0x%06X-0x%06X .incbin" % (s0, s1)
                              for s0, s1 in spans if s0 <= lo < s1), "converted code")
                mech, lines = im.explain(lo, hi, gained)
                print("    %s 0x%06X-0x%06X %5d B  in %-26s %s"
                      % ("+" if gained else "-", lo, hi, hi - lo, where,
                         mech or "★ UNEXPLAINED"))
                for ln in lines:
                    print(ln)
                if mech is None:
                    unex += 1
        if unex:
            print("\n  ★ %d RUN(S) UNEXPLAINED -- do not publish the figure" % unex)
            fail += 1
        # ★ AND THE SAME QUESTION OF THE STRONG SET, which is the column lanes
        # convert on. Inside .incbin it must not move at all; image-wide it moves
        # for the same three reasons, and they are tallied rather than listed.
        sg_runs = runs(sorted(im.post_str - im.pre_str))
        sl_runs = runs(sorted(im.pre_str - im.post_str))
        tally = {}
        for rs, gained in ((sg_runs, True), (sl_runs, False)):
            for lo, hi in rs:
                mech, _l = im.explain(lo, hi, gained)
                key = (mech or "★ UNEXPLAINED").split(" (")[0]
                tally[key] = tally.get(key, 0) + (hi - lo)
        print("\n  STRONG byte set: %d gained, %d lost image-wide; inside .incbin %d -> %d"
              % (len(im.post_str - im.pre_str), len(im.pre_str - im.post_str), ps, qs))
        if tally:
            print("     by mechanism: %s" % ", ".join(
                "%s %d B" % (k, v) for k, v in sorted(tally.items())))
        if tally.get("★ UNEXPLAINED"):
            for rs, gained in ((sg_runs, True), (sl_runs, False)):
                for lo, hi in rs:
                    mech, lines = im.explain(lo, hi, gained)
                    if mech is None:
                        print("     %s 0x%06X-0x%06X %4d B  ★ UNEXPLAINED"
                              % ("+" if gained else "-", lo, hi, hi - lo))
            fail += 1

    print("\n" + "=" * 78)
    print("TOTAL reachable-and-unconverted:  STRONG %d -> %d,  ANY %s -> %s"
          % (grand["ps"], grand["qs"], format(grand["pa"], ","), format(grand["qa"], ",")))
    if grand["ps"] != grand["qs"]:
        print("★ STRONG MOVED. Stop: that is the column lanes convert on.")
        fail += 1
    print("=" * 78)
    return 1 if fail else 0


def focus(outdir, tag, addr):
    """Everything known about ONE moved address: the ROM bytes, both decodes,
    who queued it on each side, and what the tree says about the span."""
    m = load_reach(7)
    im = Image(m, outdir, tag)
    d, b = m.ROMS[tag], m.BASES[tag]
    print("FOCUS %s 0x%06X" % (tag, addr))
    print("  in pre-guard reached set : %s" % (addr in im.pre_any))
    print("  in guarded reached set   : %s" % (addr in im.post_any))
    print("  ROM bytes 0x%06X: %s" % (addr, " ".join("%02x" % x for x in
                                                     d[addr - b:addr - b + 12])))
    print("  named by a seed          : %s" % (addr in im.seeds))
    for name, e, bd in (("pre-guard", im.pre_e, im.pre_rows), ("guarded", im.post_e, im.post_b)):
        srcs = sorted(e.get(addr, []))
        print("  %s: queued by %d consumed row(s)%s"
              % (name, len(srcs), (": " + ", ".join("0x%06X" % a for a in srcs[:6])) if srcs else ""))
        for a in srcs[:6]:
            print("      0x%06X %r   [%s]" % (a, bd[a][1], im.kind_of(a)))
            e = im.lie_at(a)
            if e:
                print("           whole-byte decode of the same address: %r"
                      % (im.post_b[a][1],))
                print("           it was the last row of the 2 KiB window at 0x%06X,"
                      " which ends at 0x%06X" % (e[2], e[2] + m.WINDOW))
                print("           ROM bytes there: %s"
                      % " ".join("%02x" % x for x in d[a - b:a - b + 8]))
            elif a not in im.post_b:
                anc = im.canon_anchor(a)
                print("           ⚠ not an instruction boundary; the canonical decode"
                      " covering it starts at %s"
                      % ("0x%06X %r" % (anc, im.post_b[anc][1]) if anc else "?"))
    return 0


# ------------------------------------------------------------------ selftest
def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    # ★ THE TOGGLE IS THE WHOLE EXPERIMENT. MAXLEN=0 must keep every row unidasm
    # emitted, and MAXLEN=7 must keep exactly those wholly inside the buffer.
    dc = load_conflicts()
    m0, m7 = load_reach(0), load_reach(7)
    start = m0.BASES["prom_a"] + 0x1000
    raw = dc.decode(m0, "prom_a", start, m0.WINDOW)
    r0 = m0._decode_window("prom_a", start)
    r7 = m7._decode_window("prom_a", start)
    check("MAXLEN=0 reproduces unidasm's rows exactly (the pre-guard tool)",
          r0 == raw, "%d rows" % len(r0))
    check("MAXLEN=7 keeps a prefix of them", r7 == raw[:len(r7)] and len(r7) <= len(raw),
          "%d of %d rows" % (len(r7), len(raw)))
    end = start + m7.WINDOW
    check("every kept row is wholly inside the buffer",
          all(a + 7 <= end for a, _l, _t in r7))
    check("every dropped row starts in the last 6 bytes",
          all(a + 7 > end for a, _l, _t in raw[len(r7):]),
          "%d dropped" % (len(raw) - len(r7)))

    # a window that runs off the END OF THE IMAGE has no truncation to guard.
    last = m7.BASES["prom_a"] + m7.SIZE - 0x100
    check("the guard does not fire on the image's final window",
          m7._decode_window("prom_a", last) == m0._decode_window("prom_a", last))

    # the run/unrun round trip, which every byte count in the report goes through
    s = {1, 2, 3, 10, 11, 40}
    check("runs()/unruns() round-trip a byte set", unruns(runs(s)) == s, str(runs(s)))

    # the baseline parser must find the committed pre-guard answers
    bi, bs = parse_baseline_spans()
    check("the committed baseline parses: 3 images and their span counts",
          set(bi) == {"prom_a", "prom_b", "prom_c"} and len(bs) > 10,
          "%d spans" % len(bs))
    check("...and it is the PRE-guard baseline (prom_a reached 361,931)",
          bi.get("prom_a", (0,))[0] == 361931, str(bi.get("prom_a")))

    check("targets_of reads an edge out of a decode text",
          targets_of(m7, "jr NC,0xfa980e") == {0xFA980E})
    check("...and finds none in text without one", targets_of(m7, "ret") == set())

    # ★ THE ATTRIBUTION MUST BE ABLE TO SAY "UNEXPLAINED", or it is a rubber
    # stamp. Feed the chain/edge machinery hand-made indexes.
    b = {0x10: (2, "ld A,B"), 0x12: (3, "ld B,C"), 0x15: (1, "ret"), 0x16: (1, "nop")}
    check("chain() follows an index",
          chain(m7, b, 0x10, 0x100) == [(0x10, 2, "ld A,B"), (0x12, 3, "ld B,C"),
                                        (0x15, 1, "ret")])
    check("...and stops at a FLOW_END, where walk() stops",
          chain(m7, b, 0x15, 0x100) == [(0x15, 1, "ret")])
    check("chain() stops at the address asked for",
          chain(m7, b, 0x10, 0x12) == [(0x10, 2, "ld A,B")])
    check("covered() is the bytes those rows frame",
          covered([(0x10, 2, "x")]) == {0x10, 0x11})
    b2 = dict(b)
    b2[0x12] = (3, "jr 0x000030")
    ei = edge_index(m7, b2, {0x12})
    check("edge_index only reports rows the walk CONSUMED",
          ei == {0x30: [0x12]}, str(ei))
    ei2 = edge_index(m7, b2, set())
    check("...and reports none when the walk consumed nothing", ei2 == {})
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--side", choices=("pre", "post"))
    ap.add_argument("--out")
    ap.add_argument("--explain")
    ap.add_argument("--tag", action="append")
    ap.add_argument("--focus", help="one address, e.g. prom_a:0xFC3D54")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    tags = a.tag or ["prom_a", "prom_b", "prom_c"]
    if a.selftest:
        sys.exit(selftest())
    if a.side:
        sys.exit(run_side(a.side, a.out, tags))
    if a.focus:
        t_, ad = a.focus.split(":")
        sys.exit(focus(a.out or a.explain, t_, int(ad, 0)))
    if a.explain:
        sys.exit(explain(a.explain, tags))
    ap.error("one of --side, --explain, --selftest")
