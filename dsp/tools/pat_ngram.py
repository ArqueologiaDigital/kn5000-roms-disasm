#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""pat_ngram.py -- RECURRING MULTI-WORD IDIOMS in the uPD6383GF corpus.

Slides a window of length 2..6 over every program (38 distinct body images +
the 60-word header + the 23-word output stage = 3057 words) and ranks n-gram
families by frequency x number of distinct programs.

TWO KEYS, and the difference matters:
    exact   the whole 36-bit word
    m8      addr8 MASKED OUT  (hi12, class4, lo12) -- catches the families whose
            only varying field is addr8, e.g. the LFO block `092.A.dd.200`

THE NULL is computed for every claim, two ways:
    analytic   product of pooled marginal word frequencies x window count
    shuffle    B within-program permutations (preserves each program's word
               multiset and its length); reports mean / sd / max

CONTROLS (`python3 pat_ngram.py control`): the three idioms that are already
established -- the 6-word all-pass motif, the 3-word LFO block and the 4-word
table-lookup motif -- must come out of the ranking.  A method that does not
rediscover them is not working.

    python3 dsp/tools/pat_ngram.py [top|control|null|families|det|all]

stdlib only.  Findings: dsp/analysis/data/SPECULATIVE_PATTERNS.md
"""
import argparse
import collections
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, fmt, decode_str, F                     # noqa: E402


# --------------------------------------------------------------------------
#  keys
# --------------------------------------------------------------------------
def key_exact(w):
    return w


def key_m8(w):
    """addr8 masked out.  For a C-format word addr8 is immediate data, so this
    key deliberately merges immediates -- flagged wherever it is used."""
    return (w & ~0x000FF000) & 0xFFFFFFFFF


KEYS = {"exact": key_exact, "m8": key_m8}


def kstr(k, kind):
    if kind == "exact":
        return fmt(k)
    return "%03X.%X.**.%03X" % ((k >> 24) & 0xFFF, (k >> 20) & 0xF, k & 0xFFF)


# --------------------------------------------------------------------------
#  counting
# --------------------------------------------------------------------------
def count_ngrams(progs, n, kind, minlen=1):
    """-> {gram: (total, {prog: count})}"""
    kf = KEYS[kind]
    out = collections.defaultdict(lambda: [0, collections.Counter()])
    for name, ws in progs.items():
        ks = [kf(w) for w in ws]
        for i in range(len(ks) - n + 1):
            g = tuple(ks[i:i + n])
            e = out[g]
            e[0] += 1
            e[1][name] += 1
    return {g: (t, c) for g, (t, c) in out.items() if t >= minlen}


def rank(counts, top=25):
    scored = [(t * len(c), t, len(c), g) for g, (t, c) in counts.items()]
    scored.sort(key=lambda x: (-x[0], -x[1], x[3]))
    return scored[:top]


# --------------------------------------------------------------------------
#  nulls
# --------------------------------------------------------------------------
def marginal_null(progs, gram, kind):
    """E[count] under a pooled-marginal i.i.d. null: sum over programs of
    (L-n+1) * prod(p_i).  p_i = pooled frequency of that key."""
    kf = KEYS[kind]
    pool = collections.Counter()
    tot = 0
    for ws in progs.values():
        for w in ws:
            pool[kf(w)] += 1
            tot += 1
    n = len(gram)
    p = 1.0
    for g in gram:
        p *= pool[g] / tot
    windows = sum(max(0, len(ws) - n + 1) for ws in progs.values())
    return p * windows


def shuffle_null(progs, grams, kind, B=200, seed=1):
    """-> {gram: (mean, sd, mx)} over B within-program shuffles."""
    kf = KEYS[kind]
    rng = random.Random(seed)
    keyed = {nm: [kf(w) for w in ws] for nm, ws in progs.items()}
    want = {g: [] for g in grams}
    lens = sorted({len(g) for g in grams})
    for _b in range(B):
        cur = collections.Counter()
        for ks in keyed.values():
            s = ks[:]
            rng.shuffle(s)
            for n in lens:
                for i in range(len(s) - n + 1):
                    t = tuple(s[i:i + n])
                    if t in want:
                        cur[t] += 1
        for g in want:
            want[g].append(cur.get(g, 0))
    out = {}
    for g, xs in want.items():
        m = sum(xs) / len(xs)
        v = sum((x - m) ** 2 for x in xs) / len(xs)
        out[g] = (m, math.sqrt(v), max(xs))
    return out


def global_null(progs, kind, B=100, seed=2, ns=(2, 3, 4, 5, 6)):
    """How many distinct n-grams recur (count >= 2) -- observed vs shuffled."""
    kf = KEYS[kind]
    rng = random.Random(seed)
    keyed = {nm: [kf(w) for w in ws] for nm, ws in progs.items()}
    obs = {}
    for n in ns:
        c = collections.Counter()
        for ks in keyed.values():
            for i in range(len(ks) - n + 1):
                c[tuple(ks[i:i + n])] += 1
        obs[n] = sum(1 for v in c.values() if v >= 2)
    null = {n: [] for n in ns}
    for _b in range(B):
        per = {n: collections.Counter() for n in ns}
        for ks in keyed.values():
            s = ks[:]
            rng.shuffle(s)
            for n in ns:
                for i in range(len(s) - n + 1):
                    per[n][tuple(s[i:i + n])] += 1
        for n in ns:
            null[n].append(sum(1 for v in per[n].values() if v >= 2))
    out = {}
    for n in ns:
        xs = null[n]
        m = sum(xs) / len(xs)
        sd = math.sqrt(sum((x - m) ** 2 for x in xs) / len(xs))
        out[n] = (obs[n], m, sd, max(xs))
    return out


# --------------------------------------------------------------------------
#  the controls -- the three KNOWN idioms
# --------------------------------------------------------------------------
CONTROLS = {
    "all-pass motif (6 words, R1)": [
        0x880160_2D4, 0x104200_000, 0x000200_419,
        0x012200_680, 0x880120_655, 0x102A00_64B],
    "all-pass inner run (4 words, 115/115)": [
        0x104200_000, 0x000200_419, 0x012200_680, 0x880120_655],
    "LFO block (3 words, lfo-ramp.md)": [
        0x092A00_200, 0x082200_1C0, 0x094A00_200],
    "table-lookup motif (instruction-set.md)": [
        0x040000_C63, 0x000618_4CD, 0x012401_1CE],
}


def cmd_control(progs, args):
    print("=" * 78)
    print("CONTROL -- do the three ESTABLISHED idioms come out of the method?")
    print("=" * 78)
    for kind in ("exact", "m8"):
        print("\n--- key = %s ---" % kind)
        kf = KEYS[kind]
        for label, words in CONTROLS.items():
            g = tuple(kf(w) for w in words)
            n = len(g)
            cnt = count_ngrams(progs, n, kind)
            t, per = cnt.get(g, (0, collections.Counter()))
            allr = rank(cnt, top=10 ** 9)
            pos = next((i for i, r in enumerate(allr) if r[3] == g), None)
            print("  %-42s n=%d  count=%-4d progs=%-3d rank=%s"
                  % (label, n, t, len(per),
                     ("#%d of %d" % (pos + 1, len(allr))) if pos is not None
                     else "ABSENT"))
    print("\nNote: the LFO block and the all-pass motif both carry a varying")
    print("addr8, so the `m8` key is the one that must find them; `exact`")
    print("finds only the majority variant.  That is the intended split.")


# --------------------------------------------------------------------------
#  reports
# --------------------------------------------------------------------------
def cmd_top(progs, args):
    for kind in (args.key,) if args.key else ("exact", "m8"):
        for n in range(2, 7):
            cnt = count_ngrams(progs, n, kind, minlen=2)
            top = rank(cnt, args.top)
            if not top:
                continue
            print("\n" + "=" * 78)
            print("n=%d  key=%s   top %d by (freq x programs)" % (n, kind, len(top)))
            print("=" * 78)
            grams = [g for *_r, g in top]
            sh = shuffle_null(progs, grams, kind, B=args.B)
            for score, t, np_, g in top:
                mn = marginal_null(progs, g, kind)
                m, sd, mx = sh[g]
                print("  score %-6d count %-4d progs %-3d | null: marg %.3f  "
                      "shuf %.2f+-%.2f max %d"
                      % (score, t, np_, mn, m, sd, mx))
                for w in g:
                    print("        %s" % kstr(w, kind))


def cmd_null(progs, args):
    print("=" * 78)
    print("GLOBAL NULL -- distinct n-grams recurring (count>=2), obs vs shuffled")
    print("=" * 78)
    for kind in ("exact", "m8"):
        print("\nkey=%s" % kind)
        g = global_null(progs, kind, B=args.B)
        for n in sorted(g):
            obs, m, sd, mx = g[n]
            z = (obs - m) / sd if sd > 0 else float("inf")
            print("   n=%d  obs %-6d   null %8.1f +- %5.1f (max %d)   z=%+.1f"
                  % (n, obs, m, sd, mx, z))


def cmd_families(progs, args):
    """n-gram families keyed m8, printed with the field decode of each member."""
    kind = "m8"
    cnt = count_ngrams(progs, args.n, kind, minlen=2)
    top = rank(cnt, args.top)
    grams = [g for *_r, g in top]
    sh = shuffle_null(progs, grams, kind, B=args.B)
    for score, t, np_, g in top:
        mn = marginal_null(progs, g, kind)
        m, sd, mx = sh[g]
        print("-" * 78)
        print("score %d  count %d  progs %d | null marg %.4f  shuf %.2f+-%.2f max %d"
              % (score, t, np_, mn, m, sd, mx))
        for w in g:
            print("   %s" % decode_str(w))
        who = cnt[g][1]
        print("   in: %s" % ", ".join("%s x%d" % (k, v)
                                      for k, v in sorted(who.items())))


def cmd_det(progs, args):
    """DETERMINISTIC SUCCESSORS: words w with P(next | w) == 1 over the corpus.
    A macro-assembled program should have many; a hand-written one fewer."""
    nxt = collections.defaultdict(collections.Counter)
    occ = collections.Counter()
    for ws in progs.values():
        for i in range(len(ws) - 1):
            nxt[ws[i]][ws[i + 1]] += 1
            occ[ws[i]] += 1
    rows = []
    for w, c in nxt.items():
        if occ[w] < args.minocc:
            continue
        tot = sum(c.values())
        best, bn = c.most_common(1)[0]
        rows.append((bn / tot, tot, w, best))
    rows.sort(key=lambda r: (-r[0], -r[1]))
    det = [r for r in rows if r[0] == 1.0]
    print("words occurring >= %d times: %d" % (args.minocc, len(rows)))
    print("of which DETERMINISTIC (one successor only): %d (%.1f%%)"
          % (len(det), 100.0 * len(det) / max(1, len(rows))))
    # null: shuffle within program, recount
    rng = random.Random(7)
    fr = []
    for _b in range(args.B):
        n2 = collections.defaultdict(collections.Counter)
        o2 = collections.Counter()
        for ws in progs.values():
            s = ws[:]
            rng.shuffle(s)
            for i in range(len(s) - 1):
                n2[s[i]][s[i + 1]] += 1
                o2[s[i]] += 1
        r2 = [(max(c.values()) / sum(c.values()))
              for w, c in n2.items() if o2[w] >= args.minocc]
        fr.append(sum(1 for x in r2 if x == 1.0) / max(1, len(r2)))
    m = sum(fr) / len(fr)
    sd = math.sqrt(sum((x - m) ** 2 for x in fr) / len(fr))
    print("null (within-program shuffle): %.1f%% +- %.1f%%"
          % (100 * m, 100 * sd))
    print("\ntop deterministic pairs by frequency:")
    for p, tot, w, b in det[:args.top]:
        print("   x%-3d  %s  ->  %s" % (tot, fmt(w), fmt(b)))


def cmd_maximal(progs, args):
    """MAXIMAL idioms: grow every recurring gram to its longest form and drop
    every gram that is only ever seen inside a longer kept one.

    This is what turns the n=2..6 sliding window into a MACRO LIBRARY."""
    kind = args.key or "m8"
    kf = KEYS[kind]
    keyed = {nm: [kf(w) for w in ws] for nm, ws in progs.items()}
    maxn = args.maxn
    kept = []
    covered = set()                       # (prog, position) already inside a kept idiom
    for n in range(maxn, args.minn - 1, -1):
        cnt = collections.defaultdict(list)
        for nm, ks in keyed.items():
            for i in range(len(ks) - n + 1):
                cnt[tuple(ks[i:i + n])].append((nm, i))
        cand = []
        for g, occ in cnt.items():
            if len(occ) < args.mincount:
                continue
            if len({o[0] for o in occ}) < args.minprogs:
                continue
            fresh = [o for o in occ
                     if not all((o[0], o[1] + j) in covered for j in range(n))]
            if len(fresh) < args.mincount:
                continue
            cand.append((len(occ), len({o[0] for o in occ}), g, occ))
        cand.sort(key=lambda c: (-c[0] * c[1], -c[0]))
        for tot, npg, g, occ in cand:
            fresh = [o for o in occ
                     if not all((o[0], o[1] + j) in covered for j in range(n))]
            if len(fresh) < args.mincount:
                continue
            kept.append((n, tot, npg, g, occ))
            for nm, i in occ:
                for j in range(n):
                    covered.add((nm, i + j))
    kept.sort(key=lambda k: (-k[0], -k[1] * k[2]))
    total_words = sum(len(v) for v in progs.values())
    print("=" * 78)
    print("MAXIMAL IDIOMS  key=%s  (count>=%d, progs>=%d, len %d..%d)"
          % (kind, args.mincount, args.minprogs, args.minn, maxn))
    print("corpus %d words; %d word-slots (%.1f%%) lie inside a maximal idiom"
          % (total_words, len(covered), 100.0 * len(covered) / total_words))
    print("=" * 78)
    for n, tot, npg, g, occ in kept[:args.top]:
        print("\n--- len %d   count %d   programs %d   score %d ---"
              % (n, tot, npg, tot * npg))
        for w in g:
            print("      %s" % decode_str(w))
        who = collections.Counter(o[0] for o in occ)
        print("      in: %s" % ", ".join("%s x%d" % (k, v)
                                         for k, v in sorted(who.items())))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["top", "control", "null", "families", "det",
                             "maximal", "all"])
    ap.add_argument("--maxn", type=int, default=24)
    ap.add_argument("--minn", type=int, default=3)
    ap.add_argument("--mincount", type=int, default=2)
    ap.add_argument("--minprogs", type=int, default=2)
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("-n", type=int, default=4)
    ap.add_argument("-B", type=int, default=100)
    ap.add_argument("--key", default=None, choices=["exact", "m8"])
    ap.add_argument("--minocc", type=int, default=4)
    args = ap.parse_args()
    progs, _meta = load()
    if args.cmd in ("control", "all"):
        cmd_control(progs, args)
    if args.cmd in ("null", "all"):
        print()
        cmd_null(progs, args)
    if args.cmd in ("top", "all"):
        cmd_top(progs, args)
    if args.cmd == "families":
        cmd_families(progs, args)
    if args.cmd in ("maximal", "all"):
        print()
        cmd_maximal(progs, args)
    if args.cmd in ("det", "all"):
        print()
        cmd_det(progs, args)


if __name__ == "__main__":
    main()
