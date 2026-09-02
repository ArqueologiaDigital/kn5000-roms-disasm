#!/usr/bin/env python3
r"""Spell this lane's one-instruction `.byte` islands as instructions.

QUESTION IT ANSWERS
    lane_v10storage_island_feasibility.py finds 409 `.byte` runs in
    v10/maincpu/{storage,ui,factory_test,file_io,boot,demo} that hold exactly
    one instruction, 330 of which llvm-mc can spell byte-identically.  This
    rewrites those lines.

    ★ THE ROM IS THE SPECIFICATION.  Every line comes from decoding
    original_ROMs/kn5000_v10_program.rom at the run's address; the old `.byte`
    text is only used to locate the run.  A line is written ONLY if llvm-mc
    hands back the exact bytes that were there.  "llvm-mc accepted it" is not
    the test.

    ★ ANCHORED, not self-consistent.  A `.byte` run whose neighbours are
    themselves mis-framed would still look like a clean fit, because the source
    would merely be agreeing with itself.  So before rewriting, unidasm decodes
    LINEARLY from the enclosing label -- an address that something in the tree
    branches to or stores as a handler, i.e. a real entry point -- and the run's
    start and end must both fall on that walk's instruction boundaries.  Runs
    that fail the walk are REFUSED and counted, not converted.

    ★ REFUSED ON PURPOSE: a run whose first byte is one of
      {0x01, 0x04, 0x17, 0x1a, 0x1c}.  ⚠ NOT for the reason first given here.
      These were briefly thought to be instructions blocked in the toolchain;
      that was RETRACTED on 2026-09-02 (notes/DEBT-INVENTORY-2026-09-02.md,
      a4e94fcb) -- all five already assembled, only the DECODER lacked them, and
      with the decoder taught them 82.8% of v10's blind-starting runs decode
      clean against 82.1% for a shuffle of the same bytes.  The refusal stands
      on the corrected reading: such a run carries no instruction structure and
      is most likely DATA that a linear force-disassembly pass broke at the byte
      it could not consume.  Turning it into an instruction would deepen a
      data-as-code error while passing the byte gate.  Counted, not converted.

    ★ Nothing is renamed and no comment is removed; only `.byte` lines change.

RUN
    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/converters/convert_v10storage_islands.py /tmp/amap.json --dry-run
    python3 scripts/converters/convert_v10storage_islands.py /tmp/amap.json
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
from lane_v10storage_island_feasibility import (  # noqa: E402
    decode, assembles_to, BASE, ROM, UNI, DASM)

# Leading opcode bytes with no decode in tlcs900_backend that unidasm reads as
# real instructions -- see scripts/analysis/byte_run_start_enrichment.py.
BLIND = {0x01, 0x04, 0x17, 0x1a, 0x1c}


def walk(addr, nbytes):
    """Instruction boundaries of a linear unidasm decode from `addr`."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(ROM[addr - BASE:addr - BASE + nbytes])
        p = f.name
    out = subprocess.run([UNI, p, "-arch", "tlcs900", "-basepc", hex(addr)],
                         capture_output=True, text=True).stdout
    os.unlink(p)
    bounds, cur = {addr}, addr
    for line in out.split("\n"):
        m = DASM.match(line)
        if m:
            cur += len(m.group(2).split())
            bounds.add(cur)
    return bounds



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
    dry = "--dry-run" in sys.argv
    addr_of = collections.defaultdict(dict)
    for e in amap:
        addr_of[e["src"]][e["line"]] = e["addr"]

    refk = tree_reference_kinds()
    defined = set(refk)
    stats = collections.Counter()
    edits = collections.defaultdict(list)

    for d in DIRS:
        dp = os.path.join(SRC, d)
        for fn in sorted(os.listdir(dp)):
            if not fn.endswith(".s"):
                continue
            rel = os.path.relpath(os.path.join(dp, fn), REPO)
            lines = open(os.path.join(dp, fn), encoding="latin-1").read().split("\n")
            labs = [(i, LABEL_RE.match(l).group(1))
                    for i, l in enumerate(lines) if LABEL_RE.match(l)]
            wcache = {}
            for i, last, nb, before, after in runs_in(lines):
                if not (before == "instr" and after == "instr") or i != last:
                    continue                       # single-line runs only
                encl_i = next((k for k, _ in reversed(labs) if k <= i), None)
                encl = next((n for k, n in reversed(labs) if k <= i), None)
                if refk.get(encl) != "BRANCHED" and \
                        not block_call_targets(lines, labs, i, defined):
                    continue
                a = addr_of[rel].get(i + 1)
                la = addr_of[rel].get(encl_i + 1) if encl_i is not None else None
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
                if ROM[a - BASE] in BLIND:
                    stats["refused_blind_start"] += 1
                    stats["refused_blind_start_bytes"] += nb
                    continue
                n, text = decode(a)
                if n != nb:
                    continue                       # OVERRUN / UNDERRUN
                if la is None or not (0 <= a - la <= 1024):
                    stats["refused_no_anchor"] += 1
                    stats["refused_no_anchor_bytes"] += nb
                    continue
                key = (rel, la)
                if key not in wcache:
                    wcache[key] = walk(la, (a - la) + n + 8)
                bounds = wcache[key]
                if a not in bounds or a + n not in bounds:
                    stats["refused_anchor_walk"] += 1
                    stats["refused_anchor_walk_bytes"] += nb
                    continue
                cand = assembles_to(text, ROM[a - BASE:a - BASE + n])
                if not cand:
                    stats["refused_unspellable"] += 1
                    stats["refused_unspellable_bytes"] += nb
                    continue
                old = lines[i]
                indent = old[:len(old) - len(old.lstrip())] or "\t"
                edits[rel].append((i, f"{indent}{cand}\t; {a:06X} "
                                      f"({unidasm_note(text)})"))
                stats["converted"] += 1
                stats["converted_bytes"] += nb

    for k in ("converted", "converted_bytes", "refused_blind_start",
              "refused_blind_start_bytes", "refused_stale_map",
              "refused_stale_map_bytes", "refused_unspellable",
              "refused_unspellable_bytes", "refused_anchor_walk",
              "refused_anchor_walk_bytes", "refused_no_anchor",
              "refused_no_anchor_bytes", "no_address"):
        print(f"  {k:<28} {stats[k]}")

    if dry:
        for rel in sorted(edits):
            for i, new in edits[rel][:4]:
                print(f"    {rel}:{i + 1}  ->{new}")
        return 0

    for rel, es in edits.items():
        p = os.path.join(REPO, rel)
        lines = open(p, encoding="latin-1").read().split("\n")
        for i, new in es:
            lines[i] = new
        data = "\n".join(lines).encode("latin-1")
        tmp = p + ".tmp"
        open(tmp, "wb").write(data)
        os.replace(tmp, p)
        print(f"  wrote {rel}: {len(es)} lines")
    return 0


def unidasm_note(text):
    return " ".join(text.split()).lower()


if __name__ == "__main__":
    sys.exit(main())
