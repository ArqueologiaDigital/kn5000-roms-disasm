#!/usr/bin/env python3
r"""rawbyte_decode_convergence.py -- of the 22,135 sites whose operands are
LITERAL BYTES, how many can now be written with a modelled operand instead?

QUESTION ANSWERED
-----------------
notes/ASSESSMENT-syntax-convergence-2026-09-02.md class 3 is 98 mnemonics over
22,135 sites that spell an instruction as its bytes -- `lda_dri xix, 7, 236,
232`, `link32 238, 12, 248, 255`.  The assessment says no rename reaches them
until the operand is modelled.  This measures how far that is now true, per
site, without assuming anything about which families were done.

METHOD, and why it is not circular
----------------------------------
For each site: assemble the committed source line, DISASSEMBLE those bytes, and
re-assemble the disassembler's own text.  A site counts as convertible only if

  1. the decoder's text is not itself one of the 98 raw-byte names, and
  2. re-assembling it gives back the ROM's bytes exactly, and
  3. MAME unidasm names the same OPERATION for those bytes.

(2) alone would pass a decoder that echoes the raw-byte spelling back -- which
is precisely what the refused `ld (mem),(nn)` decode would have done, and why
that lane refused it.  (3) is there because a round trip cannot tell an ADD
called SUB from an ADD; it is checked once per distinct byte string.

⚠ THIS IS A PROPERTY OF THE BUILD.  The toolchain commit is printed with the
result and belongs beside any number taken from here.

★ The output is also the WORK LIST for the renaming lane: every CONVERTIBLE row
carries the file, the line, and the exact text to put there -- derived from THIS
backend's decoder, never from unidasm's text, so the tree does not inherit
another decoder's framing.

RUN (from the tree root)
    python3 scripts/analysis/rawbyte_decode_convergence.py            # summary
    python3 scripts/analysis/rawbyte_decode_convergence.py --list     # work list
    python3 scripts/analysis/rawbyte_decode_convergence.py --selftest
"""
import collections
import csv
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("LLVM_MC") or os.path.join(BIN, "llvm-mc")
CENSUS = os.path.join(ROOT, "notes/syntax-convergence-probes/out/mnemonic_census.csv")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from regindexed_convergence import assemble, walk_sources, toolchain
from unidasm_bytes import dis as unidasm_dis


def raw_byte_names():
    """The 98 names, read from the committed census rather than retyped."""
    with open(CENSUS) as f:
        return {r["mnemonic"] for r in csv.DictReader(f)
                if r["raw_byte_operands"] == "1"}


def _dis_one(bs):
    r = subprocess.run([MC, "-triple=tlcs900", "-disassemble"],
                       input=" ".join("0x%02x" % b for b in bs) + "\n",
                       capture_output=True, text=True, errors="replace")
    if "warning:" in r.stderr:
        return None
    lines = [re.sub(r"\s+", " ", l.strip())
             for l in r.stdout.split("\n") if l.strip()]
    # ⚠ ONE CALL PER BYTE STRING, and exactly one instruction out of it.
    # Batching by line does NOT work: llvm-mc -disassemble consumes a byte
    # STREAM, so a line whose first instruction is shorter than the line spills
    # into extra output lines and silently shifts every later result.  The
    # selftest pins this with a foil (ff ff ff ff ff decodes as two `swi 7`).
    # Requiring exactly one line is also the LENGTH check: a decode that
    # consumes fewer bytes than the site has cannot be the site's instruction.
    return lines[0] if len(lines) == 1 else None


def disassemble(byte_lists):
    """Decode each byte string; None if refused or if it is not exactly one
    instruction.  Memoised on the byte string -- the tree repeats them."""
    from concurrent.futures import ThreadPoolExecutor
    uniq = list(dict.fromkeys(bytes(b) for b in byte_lists))
    with ThreadPoolExecutor(max_workers=8) as ex:
        res = dict(zip(uniq, ex.map(_dis_one, uniq)))
    return [res[bytes(b)] for b in byte_lists]


# The two vocabularies name the same operation differently in two places, and
# both are documented rather than inferred:
#   * this tree splits LD into a load and a STORE direction (`st_rrb`,
#     `stb_dri`); unidasm writes both as `ld` with the memory operand on the
#     side that receives.  Toshiba's manual agrees with unidasm.
#   * this tree carries the operand SIZE in the mnemonic suffix (`_rrb`, `w`,
#     `l`, `8`, `16`, `32`); unidasm mostly does not.
# Anything NOT covered here is printed in full by the census -- a real
# disagreement must not be absorbed by a permissive rule.
SAME_OP = {
    "st": "ld",
    "lda": "lda",
    "ld": "ld",
}
SUFFIX = re.compile(r"^([a-z]+?)(?:_?(?:rr|sri|dri|erp|ind|da|mm)?[0-9]*[bwl]?"
                    r"(?:8|16|32)?)?(?:_m)?$")


def stem(name):
    n = name.lower().split("_")[0]
    n = re.sub(r"(?<=[a-z])(8|16|32)$", "", n)
    n = re.sub(r"(?<=[a-z]{2})[bwl]$", "", n)
    return n


def same_operation(ours, theirs):
    """Do the two names denote the same OPERATION?"""
    if not theirs:
        return False          # unidasm refused: not corroborated, not counted
    a, b = stem(ours), stem(theirs)
    return a == b or SAME_OP.get(a) == b or SAME_OP.get(b) == a


def uni_op(byts):
    out, err = unidasm_dis(bytes(byts))
    line = (out.splitlines() or [""])[0]
    m = re.match(r"^\s*\S+:\s+(?:[0-9a-f]{2} )+\s*(\S+)", line)
    return m.group(1).lower() if m else None


def main(list_mode=False):
    NAMES = raw_byte_names()
    pat = re.compile(r"^\s*(" + "|".join(sorted(NAMES, key=len, reverse=True))
                     + r")\b\s*(.*?)\s*$")
    src_lines, meta = [], []
    for path in walk_sources():
        rel = os.path.relpath(path, ROOT)
        try:
            text = open(path, encoding="latin-1").read()
        except OSError:
            continue
        for ln, line in enumerate(text.split("\n"), 1):
            m = pat.match(line)
            if not m:
                continue
            body = m.group(2).split(";")[0].split("//")[0].strip()
            src_lines.append("%s %s" % (m.group(1), body))
            meta.append((rel, ln, m.group(1)))

    print("llvm-mc          : %s" % MC)
    print("toolchain commit : tlcs900_backend@%s" % toolchain())
    print("class-3 raw-byte sites found: %d over %d names"
          % (len(src_lines), len(set(m[2] for m in meta))))

    encs = assemble(src_lines)
    rows = [(meta[i], bytes(int(x, 16) for x in e.split(",")))
            for i, e in enumerate(encs) if e]
    print("assembled        : %d" % len(rows))

    texts = disassemble([b for _, b in rows])
    cand = [(m, b, t) for (m, b), t in zip(rows, texts) if t]
    reenc = assemble([t for _, _, t in cand])

    # unidasm's operation, once per distinct byte string
    ops = {}
    for _, b, _ in cand:
        if b not in ops:
            ops[b] = uni_op(b)

    verdict = collections.Counter()
    pairs = collections.Counter()
    per_name = collections.defaultdict(collections.Counter)
    work = []
    for ((rel, ln, mn), b, t), e in zip(cand, reenc):
        got = bytes(int(x, 16) for x in e.split(",")) if e else None
        head = t.split()[0]
        if head in NAMES:
            v = "STILL_RAW_BYTES"
        elif got != b:
            v = "ASYMMETRIC"
        elif not same_operation(head, ops[b]):
            v = "UNIDASM_OP_DIFFERS"
            pairs[(head, ops[b])] += 1
        else:
            v = "CONVERTIBLE"
            work.append((rel, ln, mn, t))
        verdict[v] += 1
        per_name[mn][v] += 1
    refused = len(rows) - len(cand)
    verdict["DECODE_REFUSED"] = refused
    for (rel, ln, mn), b in rows[:0]:
        pass
    for i, ((m, b), t) in enumerate(zip(rows, texts)):
        if t is None:
            per_name[m[2]]["DECODE_REFUSED"] += 1

    print("\nVERDICT (per site)")
    for k, c in verdict.most_common():
        print("  %-20s %6d" % (k, c))

    print("\nPER MNEMONIC (top 30 by site count)")
    tot = sorted(per_name.items(), key=lambda kv: -sum(kv[1].values()))
    print("  %-14s %7s %7s %7s %7s %7s" %
          ("name", "sites", "conv", "stillraw", "asym", "refused"))
    for mn, c in tot[:30]:
        print("  %-14s %7d %7d %7d %7d %7d"
              % (mn, sum(c.values()), c["CONVERTIBLE"], c["STILL_RAW_BYTES"],
                 c["ASYMMETRIC"], c["DECODE_REFUSED"]))

    if pairs:
        print("\n⚠ NAME PAIRS THIS BACKEND AND unidasm DO NOT AGREE ON")
        print("  (listed in full: a disagreement folded into a total is the "
              "defect this census exists to find)")
        for (ours, theirs), c in pairs.most_common():
            print("  %-18s vs unidasm %-10s %6d" % (ours, theirs, c))

    if list_mode:
        print("\nWORK LIST")
        for rel, ln, mn, t in work:
            print("%s:%d\t%s\t%s" % (rel, ln, mn, t))
    return 0


def selftest():
    """Pure verdict rules on synthetic input, so a change to the tree cannot
    make the test pass or fail for the wrong reason."""
    ok = True
    NAMES = raw_byte_names()
    for want, name in ((True, "lda_dri"), (True, "link32"), (False, "lda"),
                       (False, "ld")):
        if (name in NAMES) != want:
            print("FAIL raw_byte_names: %s in set = %s, want %s"
                  % (name, name in NAMES, want))
            ok = False
    # the batched disassembler must keep its alignment across a REFUSED line
    got = disassemble([b"\xee\x0c\xf8\xff", b"\xff\xff\xff\xff\xff",
                       b"\xc3\x07\xe8\xe4\x27"])
    want = ["link xiz, -8", None, "ld_rrb l, xde, bc"]
    if got != want:
        print("FAIL batched disassembly alignment: %r want %r" % (got, want))
        ok = False
    print("selftest:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    sys.exit(main("--list" in sys.argv))
