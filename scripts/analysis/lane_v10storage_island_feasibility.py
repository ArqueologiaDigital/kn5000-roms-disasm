#!/usr/bin/env python3
r"""CAN THIS LANE'S CODE-AS-.byte DEBT ACTUALLY BE CONVERTED, AND IF NOT, WHY?

QUESTION ANSWERED
-----------------
lane_v10storage_byte_split.py says 2,667 `.byte` operands in
v10/maincpu/{storage,ui,factory_test,file_io,boot,demo} are real code spelled as
data.  Saying so is not the same as being able to fix it.  For every one of
those runs this script asks, in order:

  1. WHERE is it?  From scripts/analysis/address_line_map.py's dump, which is
     self-tested against the real ROM, so the addresses are this tree's.
  2. WHAT is there?  MAME unidasm decodes the ORIGINAL ROM bytes at that
     address -- unidasm is complete where the LLVM TLCS-900 backend is not.
  3. DOES THE SOURCE FRAME IT RIGHT?  Compare the decoded instruction's length
     against the `.byte` run's length:
        FIT      the instruction is exactly the run -> a one-line rewrite
        OVERRUN  the real instruction runs PAST the run, so the source's next
                 "instruction" starts mid-instruction and is MIS-FRAMED; fixing
                 it means replacing the run AND its followers
        UNDERRUN the run holds more than one instruction
  4. CAN THE ASSEMBLER SAY IT?  Hand unidasm's text to llvm-mc and require the
     encoding to come back BYTE-IDENTICAL.  "llvm-mc accepted it" is not the
     test; "llvm-mc reproduced these exact bytes" is.  Operand order is tried
     both ways, because unidasm prints `sla 0x02,WA` where llvm-mc wants
     `sla wa, 2` and without the swap every shift reads as a backend gap
     (same correction scripts/analysis/llvm_missing_instruction_forms.py
     already had to make).

The output is the convertible set, plus a ranked table of the forms that block
the rest -- which is the honest answer to "why is this still `.byte`".

RUN
    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/analysis/lane_v10storage_island_feasibility.py /tmp/amap.json
"""
import collections
import json
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
from lane_v10storage_byte_split import (  # noqa: E402
    DIRS, SRC, LABEL_RE, runs_in, tree_reference_kinds, block_call_targets)

UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ROM = open(os.path.join(REPO, "original_ROMs",
                        "kn5000_v10_program.rom"), "rb").read()
BASE = 0xE00000
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
ENC = re.compile(r'encoding:\s*\[([^\]]*)\]')


def decode(addr, n=24):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(ROM[addr - BASE:addr - BASE + n])
        p = f.name
    out = subprocess.run([UNI, p, "-arch", "tlcs900", "-basepc", hex(addr)],
                         capture_output=True, text=True).stdout
    os.unlink(p)
    for line in out.split("\n"):
        m = DASM.match(line)
        if m:
            return len(m.group(2).split()), m.group(3).strip()
    return None, None


def spellings(text):
    """Candidate llvm-mc spellings of one unidasm line, both operand orders."""
    t = text.strip()
    if " " not in t:
        return [t.lower()]
    mn, ops = t.split(None, 1)
    parts = [x.strip() for x in ops.split(",")]
    out = [f"{mn} {', '.join(parts)}"]
    if len(parts) == 2:
        out.append(f"{mn} {parts[1]}, {parts[0]}")
    return [s.lower() for s in out]


def assembles_to(text, want):
    for cand in spellings(text):
        r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"],
                           input=cand + "\n", capture_output=True, text=True)
        if r.returncode:
            continue
        m = ENC.search(r.stdout)
        if not m:
            continue
        toks = [b.strip() for b in m.group(1).split(",") if b.strip()]
        if not all(re.fullmatch(r'0x[0-9a-fA-F]{1,2}', t) for t in toks):
            continue          # a relocation placeholder ('A'), not a byte
        got = bytes(int(t, 16) for t in toks)
        if got == want:
            return cand
    return None


def form_of(text):
    """Coarse shape of an instruction, for ranking blockers."""
    t = text.strip()
    if " " not in t:
        return t.lower()
    mn, ops = t.split(None, 1)
    shape = []
    for o in ops.split(","):
        o = o.strip()
        if o.startswith("("):
            shape.append("(mem)")
        elif re.match(r'^0x[0-9a-f]+$', o, re.I):
            shape.append("imm")
        else:
            shape.append("reg")
    return f"{mn.lower()} " + ",".join(shape)



def src_first_byte(line):
    """The first byte the source line itself says it emits, or None."""
    m = re.match(r'^\s*(?:[A-Za-z_.$][\w.$]*:\s*)?\.byte\s+(.*)$', line)
    if not m:
        return None
    try:
        return int(m.group(1).split(";")[0].split(",")[0].strip(), 0)
    except ValueError:
        return None


def main():
    amap = json.load(open(sys.argv[1]))
    addr_of = collections.defaultdict(dict)
    for e in amap:
        addr_of[e["src"]][e["line"]] = e["addr"]

    refk = tree_reference_kinds()
    defined = set(refk)
    stats = collections.Counter()
    blockers = collections.Counter()
    convertible = []

    for d in DIRS:
        dp = os.path.join(SRC, d)
        for fn in sorted(os.listdir(dp)):
            if not fn.endswith(".s"):
                continue
            rel = os.path.relpath(os.path.join(dp, fn), REPO)
            lines = open(os.path.join(dp, fn), encoding="latin-1").read().split("\n")
            labs = [(i, LABEL_RE.match(l).group(1))
                    for i, l in enumerate(lines) if LABEL_RE.match(l)]
            for i, last, nb, before, after in runs_in(lines):
                if not (before == "instr" and after == "instr"):
                    continue
                encl = next((n for k, n in reversed(labs) if k <= i), None)
                if refk.get(encl) != "BRANCHED" and \
                        not block_call_targets(lines, labs, i, defined):
                    continue
                a = addr_of[rel].get(i + 1)
                if a is None:
                    stats["no_address"] += 1
                    continue
                # ★ STALE-MAP GUARD.  The address map is a separate build; if it
                # is one revision behind the source it silently points at the
                # wrong bytes and every downstream check still "passes" -- this
                # cost a reverted conversion on 2026-09-02.  The source line
                # states its own first byte, so demand that it match the ROM.
                if src_first_byte(lines[i]) != ROM[a - BASE]:
                    stats["refused_stale_map"] += 1
                    stats["refused_stale_map_bytes"] += nb
                    continue
                n, text = decode(a)
                if n is None:
                    stats["undecodable"] += 1
                    continue
                if n == nb:
                    stats["FIT"] += 1
                    stats["FIT_bytes"] += nb
                    want = ROM[a - BASE:a - BASE + n]
                    cand = assembles_to(text, want)
                    if cand:
                        stats["FIT_spellable"] += 1
                        stats["FIT_spellable_bytes"] += nb
                        convertible.append((rel, i + 1, a, nb, text, cand))
                    else:
                        blockers[form_of(text)] += nb
                elif n > nb:
                    stats["OVERRUN"] += 1
                    stats["OVERRUN_bytes"] += nb
                else:
                    stats["UNDERRUN"] += 1
                    stats["UNDERRUN_bytes"] += nb

    print("FRAMING of this lane's code-as-.byte runs")
    for k in ("FIT", "OVERRUN", "UNDERRUN", "undecodable", "no_address"):
        print(f"  {k:<12} {stats[k]:>5} runs  {stats.get(k + '_bytes', 0):>6} B")
    print()
    print(f"  of the FIT runs, llvm-mc reproduces the exact bytes for "
          f"{stats['FIT_spellable']} ({stats['FIT_spellable_bytes']} B)")
    print()
    print("BLOCKING FORMS (bytes the assembler cannot spell), top 20")
    for form, nbytes in blockers.most_common(20):
        print(f"  {nbytes:>5} B  {form}")
    print()
    print(f"total blocked by a missing spelling: {sum(blockers.values())} B "
          f"in {len(blockers)} distinct forms")
    with open("/tmp/lane_v10storage_convertible.json", "w") as f:
        json.dump(convertible, f, indent=1)
    print(f"\nconvertible set written to /tmp/lane_v10storage_convertible.json "
          f"({len(convertible)} runs)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
