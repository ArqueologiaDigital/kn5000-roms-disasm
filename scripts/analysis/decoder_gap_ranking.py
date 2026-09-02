#!/usr/bin/env python3
"""decoder_gap_ranking.py -- which TLCS-900 leading opcode bytes does the
DISASSEMBLER fail on, ranked by how much conversion work they block?

THE QUESTION THIS ANSWERS
-------------------------
Three re-framing passes over v7/v9/v10 refused spans 14,239 times because the
linear sweep hit a byte it could not read.  "The decoder has gaps" is not
actionable; *which* gaps, ranked by the work they block, and *whether the
encoder already has the form*, is.

It matters which half is missing.  If llvm-mc can ENCODE a form that
llvm-objdump cannot DECODE, then the tree's existing source for that form is
correct and only the reading of it is broken -- so an independent decode
disagreeing with the source is evidence about the DECODER, not about the source.
That is exactly the situation at the largest embedded-in-code span in the
census: `add bc, (xsp+6)` encodes to 9f 06 81, and 0x9f decodes as <unknown>.

⚠ AND IT IS CHECKED IN BOTH DIRECTIONS BEFORE BEING CALLED A GAP.  "The
toolchain cannot spell it" has been wrong repeatedly in this project, so every
row below states what the ENCODER does with the same text as well as what the
decoder does with the bytes.

METHOD
------
The ground truth is v10's OWN SOURCE: llvm-mc -show-encoding over the whole tree
gives, for every instruction statement, its exact bytes and its exact text.  For
each leading byte, up to three such statements are taken and their bytes -- plus
six bytes of following context, without which llvm-objdump refuses a form merely
for reaching the end of its input -- are handed to llvm-objdump.  A row is a GAP
when the decoder refuses the leading byte or consumes a different number of
bytes than the assembler emitted.

RUN
    python3 scripts/analysis/decoder_gap_ranking.py
    python3 scripts/analysis/decoder_gap_ranking.py --selftest
"""
import collections
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import twin_framed_spans as T                                   # noqa: E402

# Leading bytes that blocked a span, summed over the v7, v9 and v10 re-framing
# runs of 2026-09-02 (the "undecodable byte values that blocked a span" lines of
# scripts/analysis/v10_reframe_code_runs.py --apply).  Regenerate by re-running
# those three passes and re-summing; the ranking is what makes this list, the
# list is not itself evidence.
SAMPLE = int(os.environ.get("GAP_SAMPLE", "40"))

BLOCKERS = [(0xc1, 1952), (0xf1, 1134), (0x8f, 1073), (0x9f, 716), (0x80, 649),
            (0xd1, 598), (0xee, 500), (0xaf, 379), (0x90, 328), (0x95, 308),
            (0x87, 274), (0x50, 213), (0x98, 213), (0x81, 210), (0xbf, 209),
            (0xe3, 184), (0xe4, 181), (0xb0, 168), (0xb2, 168), (0xe0, 166)]


def objdump_first(blob):
    """-> (consumed bytes, text) for the FIRST instruction llvm-objdump reads."""
    ins = []
    with tempfile.TemporaryDirectory() as td:
        b = os.path.join(td, "b.bin")
        open(b, "wb").write(blob)
        s = os.path.join(td, "b.s")
        open(s, "w").write('.text\n.incbin "%s"\n' % b)
        o = os.path.join(td, "b.o")
        subprocess.run([T.MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                       check=True, capture_output=True)
        r = subprocess.run([T.OBJDUMP, "-d", "--triple=tlcs900", o],
                           capture_output=True, text=True)
    for line in r.stdout.split("\n"):
        m = re.match(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            ins.append((bytes(int(x, 16) for x in m.group(2).split()),
                        m.group(3).strip()))
    return ins[0] if ins else (b"", "(nothing)")


def encode(text):
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "a.s")
        open(s, "w").write(".text\n" + text + "\n")
        o = os.path.join(td, "a.o")
        r = subprocess.run([T.MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                           capture_output=True, text=True)
        if r.returncode:
            return None
        b = os.path.join(td, "a.bin")
        subprocess.run([os.path.join(os.path.dirname(T.MC), "llvm-objcopy"),
                        "-O", "binary", "-j", ".text", o, b], check=True)
        return open(b, "rb").read()


def run():
    print("toolchain: %s" % subprocess.run(
        ["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
         "log", "-1", "--format=%h"], capture_output=True, text=True).stdout.strip())
    T.load_roms()
    instrs = T.flatten("v10")[5]
    rom = T.ROMS["v10"]
    by_lead = collections.defaultdict(list)
    for off, ln, txt, rl in instrs:
        if rl:
            continue                    # a relocated operand cannot be re-encoded here
        by_lead[rom[off]].append((off, ln, txt))
    print("\n%-5s %7s %6s  %-40s %s"
          % ("byte", "blocks", "gap", "an example the decoder cannot read", "asm"))
    tot_s = tot_g = 0
    for lead, count in BLOCKERS:
        seen, cands = set(), []
        for off, ln, txt in by_lead.get(lead, []):
            key = txt.strip()
            if key in seen:
                continue
            seen.add(key)
            cands.append((off, ln, txt))
            if len(cands) >= SAMPLE:
                break
        if not cands:
            print("%-5s %7d %6s  %-40s %s"
                  % ("0x%02x" % lead, count, "-", "(no unrelocated v10 statement)", "-"))
            continue
        gap, example, asm = 0, "", "-"
        for off, ln, txt in cands:
            got_raw, got_txt = objdump_first(rom[off:off + ln + 6])
            bad = got_txt.startswith("<unknown>") or len(got_raw) != ln
            if bad:
                gap += 1
                if not example:
                    example = txt.strip().replace("\t", " ")[:40]
                    enc = encode(txt.strip())
                    asm = ("ok" if enc == rom[off:off + ln]
                           else "REJECT" if enc is None else "differs")
        tot_s += len(cands)
        tot_g += gap
        print("%-5s %7d %5d/%-3d %-40s %s"
              % ("0x%02x" % lead, count, gap, len(cands),
                 example or "(all sampled forms decode)", asm))
    print("\n%d of %d sampled statements are refused or mis-sized by the decoder."
          % (tot_g, tot_s))
    print("`asm ok` means llvm-mc ENCODES that exact text back to the ROM's bytes:"
          "\nfor those rows the tree's source is right and only the reading of it "
          "is missing.")
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    T.load_roms()
    raw, txt = objdump_first(bytes([0x11, 0x11, 0x11]))
    ck("a form the decoder DOES read is not reported as a gap",
       raw == bytes([0x11]) and txt == "scf", "%r %r" % (raw, txt))
    raw, txt = objdump_first(bytes([0x9f, 0x06, 0x81, 0xb8, 0x04, 0x51, 0x9e]))
    ck("0x9f is refused by llvm-objdump", txt.startswith("<unknown>"), txt)
    ck("...and llvm-mc encodes the same instruction fine",
       encode("add bc, (xsp+6)") == bytes([0x9f, 0x06, 0x81]))
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else run())
