#!/usr/bin/env python3
"""v10audio_byte_triage.py -- three-way split of every literal `.byte` run in
the v10 maincpu AUDIO ENGINE sources.

QUESTION ANSWERED
  Of the bytes still spelled as `.byte` in v10/maincpu/audio/ (excluding the
  `sound_data_*` tone tables and the two files owned by another lane), how many
  are

      (a) CODE   real instructions the disassembly never decoded,
      (b) TYPE   structured data carrying a discoverable record shape -- above
                 all 32-bit pointer tables -- that should be spelled as typed
                 data rather than an anonymous byte run,
      (c) DATA   genuine byte-valued tables, already correctly represented,
      (d) BLOCKED  a run the assembler CANNOT SPELL YET because it begins with
                 one of the five leading opcode bytes tlcs900_backend has no
                 encoding for -- {0x01, 0x04, 0x17, 0x1a, 0x1c} = normal, max,
                 ldf, JP nnnn, CALL nnnn per MAME's unidasm.  Forcing one of
                 these into instructions is the worst available move: the
                 assembler will either refuse, or accept some OTHER reading that
                 re-assembles to the same bytes and passes the byte gate.  They
                 are TAGGED with the blocking byte and left alone until lane
                 w10/missinginsns lands the five encodings.

  A raw `.byte` count is NOT debt.  (c) is the answer this project got wrong in
  the other direction once already (120 spans, 3,390 B, were converted back FROM
  mnemonics TO typed data by lane V10DAC, commit f0b79f95), and the un-decoded
  code hiding in a `.byte` run is the error it got wrong in this direction
  (8,496 B of sound code passing an `.incbin`-shaped completeness test).

THE EVIDENCE, AND WHY IT IS NOT "DOES IT DISASSEMBLE"
  Data in this ROM decodes into plausible mnemonics, and re-assembling a wrong
  reading reproduces the same bytes, so `make gate` cannot see the difference.
  This script therefore never classifies on decodability.  It uses:

  R1  CROSS-REFERENCE KIND.  Every maximal CODE run in the image (territory from
      the assembler's own -show-encoding stream, so each run starts on a real
      instruction boundary) is disassembled with MAME unidasm, and every
      call/calr/jp/jr/djnz target and every 32-bit immediate is collected.  A
      run that something JUMPS or CALLS to is a code entry point.  A run whose
      only references LOAD ITS ADDRESS is data (the lane brief's own rule).
  R2  ISLAND CONTEXT TILING.  For a run flanked by CODE on both sides, decode
      forward from up to 48 bytes back inside the established code: if an
      instruction boundary lands exactly on the run's first byte and the decode
      tiles the run exactly, the run is a mis-spelled instruction.  Borrowed
      verbatim from scripts/converters/fill_verified_islands.py.
  R3  TABLE-TAIL GUARD.  The census's own calibrated periodicity term over a
      window spanning the run AND what precedes it.  A fixed-width DATA record
      whose LAST instance abuts real code passes R2 by construction; this is the
      check that catches it (fill_verified_islands.py's 2026-09-02 incident).
  R0  DECODER-GAP BLOCK.  First byte in the BLIND set above.  From
      scripts/analysis/byte_run_start_enrichment.py (commit 15115eae): v10
      starts a `.byte` run with a blind byte 19.2% of the time against 0.4% for
      decodable bytes of similar magnitude, a 46x enrichment, with all four
      SX-WSA1R images flat (0.3x-1.5x) as the negative control.  This script
      re-measures that enrichment for THIS LANE'S FILES ONLY (--enrichment) and
      reports the blocked bytes as their own bucket rather than mixing them into
      either CODE or DATA.
  R4  POINTER-TABLE SHAPE.  A run of k>=4 whole 4-byte little-endian words, each
      landing inside the ROM's own address space, is a pointer table -- and the
      test is strengthened by requiring the targets to be CODE territory or
      known blob starts, which random data does not satisfy.

  Verdict, in order: (b) if R4 fires; else (d) if R0 fires; else (a) if R2 tiles
           and R3 is silent, or R1 says control-flow AND the census rule fires;
           else (c).  (b) outranks (d) because a pointer table is DATA and typing
           it needs no instruction encoding at all.

HOW THIS COULD BE WRONG
  * R1 sees only references the CODE territory already contains.  A run reached
    through a computed jump, a pointer built by arithmetic, or from the SUB-CPU
    image, has NO visible reference and scores as data by default.  That biases
    toward (c) -- conservative for conversion, but it means "(c)" is "no evidence
    of code", not "proven data".
  * R2's 48-byte backward walk assumes the preceding CODE territory is correctly
    framed.  It is the assembler's own framing, so it is as good as the tree.
  * R4 accepts any 4-byte word inside 0xE00000..0xFFFFFF.  A coefficient table
    whose 4th byte happens to be 0x00 and whose 3rd is 0xE0..0xFF would pass; the
    CODE-territory requirement on the target is what makes that unlikely, and the
    control below measures how unlikely.

THE CONTROL
  --control runs the identical classifier over two known-answer populations of
  the same size distribution:
    KNOWN DATA  the `.byte` runs of v10/maincpu/audio/sound_data_*.s -- tone and
                wave tables, round-trip generated from committed C by the
                Makefile, explicitly out of this lane's scope BECAUSE they are
                genuine data.  Any (a) verdict here is a false positive.
    KNOWN CODE  windows cut out of long contiguous CODE runs in the very files
                being triaged, re-fed to the classifier as if they were `.byte`
                runs.  Any non-(a) verdict here is a false negative.

RUN
    python3 scripts/analysis/v10_census_prepare_only.py <workdir> v10
    python3 scripts/analysis/v9_v10_undisassembled_census.py --census v10 --work <workdir>
    python3 scripts/analysis/v10audio_byte_triage.py --work <workdir> [--control] [--csv OUT.csv]

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/v10audio (branch w10/v10audio).
"""
import argparse
import multiprocessing
import os
import pickle
import random
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
from v9_v10_undisassembled_census import metrics as census_metrics, rule as census_rule
import fill_verified_islands as fvi

UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE, SIZE = 0xE00000, 2097152
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')

# files this lane owns: every .s in v10/maincpu/audio/ that is not a
# sound_data_* tone table and not one of the two owned by the SEUI lane.
OTHER_LANE = {"sound_editor_ui.s", "semenu_routines.s"}

# Leading opcode bytes with no encoding in tlcs900_backend, which MAME's unidasm
# decodes as real instructions.  Established by leading_byte_reserved_probe.py /
# unmapped_byte_oracle.py; see byte_run_start_enrichment.py (15115eae).
BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf", 0x1a: "JP nnnn", 0x1c: "CALL nnnn"}
# Decodable bytes of similar magnitude -- the control set.  Do NOT widen this to
# all 256 values: high bytes are prefixes with different data frequencies.
CTRL_SET = {0x02, 0x03, 0x05, 0x16, 0x1b}


def in_scope(relfile):
    p = relfile.replace("\\", "/")
    if not p.startswith("maincpu/audio/"):
        return False
    base = p.split("/")[-1]
    if p.count("/") != 2:          # sound_editor_screens/ subdir -> .c, no .byte
        return False
    return (not base.startswith("sound_data")) and base not in OTHER_LANE


def is_sound_data(relfile):
    p = relfile.replace("\\", "/")
    return p.startswith("maincpu/audio/sound_data") and p.endswith(".s")


# ------------------------------------------------------------------ R1
CTRL = re.compile(r'^(call|calr|jp|jr|djnz)\b', re.I)
HEX = re.compile(r'0x([0-9a-fA-F]{4,8})')


def _one_run(args):
    blob, base = args
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    open(tmp, "wb").write(blob)
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(base)],
                         capture_output=True, text=True).stdout
    os.unlink(tmp)
    ctrl, imm = set(), set()
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if not m:
            continue
        text = m.group(3)
        vals = [int(h, 16) for h in HEX.findall(text)]
        vals = [v for v in vals if BASE <= v < BASE + SIZE]
        (ctrl if CTRL.match(text.strip()) else imm).update(vals)
    return ctrl, imm


def reference_index(rom, terr, jobs=None):
    """Disassemble every maximal CODE run and return (ctrl_targets, imm_values).

    Each run's first byte is an instruction boundary because `terr` comes from
    the assembler's own -show-encoding stream, not from a linear sweep.
    """
    runs, i = [], 0
    while i < SIZE:
        if terr[i] != 1:
            i += 1
            continue
        j = i
        while j < SIZE and terr[j] == 1:
            j += 1
        runs.append((rom[i:j], BASE + i))
        i = j
    ctrl, imm = set(), set()
    with multiprocessing.Pool(jobs or os.cpu_count()) as pool:
        for c, m in pool.imap_unordered(_one_run, runs, chunksize=64):
            ctrl |= c
            imm |= m
    return ctrl, imm


def pointer_refs(rom, terr, incmap):
    """Every 4-aligned LE32 inside DATA territory that lands in the ROM."""
    out = {}
    for off in range(0, SIZE - 3, 2):
        if terr[off] != 2:
            continue
        v = int.from_bytes(rom[off:off + 4], "little")
        if BASE <= v < BASE + SIZE:
            out.setdefault(v - BASE, []).append(off)
    return out


# ------------------------------------------------------------------ R4
def pointer_table_shape(rom, start, end):
    """Is [start,end) k>=4 whole LE32 words all landing in the ROM?"""
    n = end - start
    if n < 16 or n % 4:
        return None
    tgts = []
    for off in range(start, end, 4):
        v = int.from_bytes(rom[off:off + 4], "little")
        if not (BASE <= v < BASE + SIZE):
            return None
        tgts.append(v - BASE)
    return tgts


def classify(rom, terr, blob, ctrl, imm, ptrs, tmp, blobstarts):
    start, end, n = blob["start"], blob["end"], blob["size"]
    ev = {}
    hits = range(start, end)
    ev["ctrl_ref"] = any((BASE + a) in ctrl for a in hits)
    ev["imm_ref"] = any((BASE + a) in imm for a in hits)
    ev["ptr_ref"] = any(a in ptrs for a in hits)

    flanked = start > 0 and end < SIZE and terr[start - 1] == 1 and terr[end] == 1
    ev["flanked"] = flanked
    ev["tile"] = None
    ev["tabletail"] = None
    if flanked:
        fr, ok = fvi.bounds_from_context(rom, terr, start, end, tmp)
        ev["tile"] = fr if fr != "MULTI" else ("MULTI_TILES" if ok else "MULTI_PARTIAL")
        if fr == "ONE_INSN" or (fr == "MULTI" and ok):
            ev["tabletail"] = fvi.looks_like_a_table_tail(rom, end, tmp)

    ev["rule"] = None
    if n >= 32:
        ev["rule"] = bool(census_rule(census_metrics(rom, start, n, tmp)))

    tgts = pointer_table_shape(rom, start, end)
    ev["ptrtable"] = False
    if tgts:
        good = sum(1 for t in tgts if terr[t] == 1 or t in blobstarts)
        ev["ptrtable"] = good == len(tgts)
        ev["ptrtargets"] = tgts

    ev["blind"] = BLIND.get(rom[start])

    # ---- verdict
    if ev["ptrtable"]:
        return "TYPE", ev
    if ev["blind"]:
        return "BLOCKED", ev
    if ev["tile"] in ("ONE_INSN", "MULTI_TILES") and not ev["tabletail"]:
        return "CODE", ev
    if ev["ctrl_ref"] and ev["rule"]:
        return "CODE", ev
    return "DATA", ev


def load(work):
    d = pickle.load(open(os.path.join(work, "v10.map.pkl"), "rb"))
    rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom"), "rb").read()
    return bytes(d["terr"]), d["blobs"], rom


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", required=True)
    ap.add_argument("--control", action="store_true")
    ap.add_argument("--csv")
    a = ap.parse_args()

    terr, blobs, rom = load(a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    blobstarts = {b["start"] for b in blobs}

    cache = os.path.join(a.work, "v10audio.refindex.pkl")
    if os.path.exists(cache):
        sys.stderr.write("reference index from cache ...\n")
        ctrl, imm, ptrs = pickle.load(open(cache, "rb"))
    else:
        sys.stderr.write("building reference index (~16,600 unidasm calls) ...\n")
        ctrl, imm = reference_index(rom, terr)
        ptrs = pointer_refs(rom, terr, None)
        pickle.dump((ctrl, imm, ptrs), open(cache, "wb"))
    sys.stderr.write(f"  {len(ctrl):,} control-flow targets, {len(imm):,} immediates, "
                     f"{len(ptrs):,} pointer-shaped DATA words\n")

    KINDS = ("CODE", "TYPE", "BLOCKED", "DATA")

    def run(pop, title):
        tot = dict.fromkeys(KINDS, 0)
        cnt = dict.fromkeys(KINDS, 0)
        rows = []
        for b in pop:
            v, ev = classify(rom, terr, b, ctrl, imm, ptrs, tmp, blobstarts)
            tot[v] += b["size"]
            cnt[v] += 1
            rows.append((v, b, ev))
        print(f"\n=== {title}")
        for k in KINDS:
            print(f"    {k:5} {cnt[k]:6,} runs {tot[k]:8,} B")
        print(f"    total {sum(cnt.values()):6,} runs {sum(tot.values()):8,} B")
        nb = sum(1 for b in pop if rom[b["start"]] in BLIND)
        nc = sum(1 for b in pop if rom[b["start"]] in CTRL_SET)
        print(f"    run-starts blind {nb}/{len(pop)} = {100.0*nb/max(len(pop),1):.1f}%   "
              f"control {nc}/{len(pop)} = {100.0*nc/max(len(pop),1):.1f}%   "
              f"enrichment {nb/max(nc,1):.1f}x")
        return rows

    scope = [b for b in blobs if b["kind"] == "byteblob" and in_scope(b["file"])]
    rows = run(scope, "v10 maincpu AUDIO ENGINE (this lane's files)")

    perfile = {}
    for v, b, ev in rows:
        d = perfile.setdefault(b["file"], dict.fromkeys(KINDS, 0))
        d[v] += b["size"]
    print("\n    per file:")
    for f in sorted(perfile):
        d = perfile[f]
        print(f"      {os.path.basename(f):32s} CODE {d['CODE']:6,}  TYPE {d['TYPE']:6,}  "
              f"BLOCKED {d['BLOCKED']:6,}  DATA {d['DATA']:6,}")

    print("\n    blocked-byte census for this lane's files (R0 enrichment):")
    nb = sum(1 for _, b, _ in rows if rom[b["start"]] in BLIND)
    nc = sum(1 for _, b, _ in rows if rom[b["start"]] in CTRL_SET)
    n = len(rows)
    print(f"      run-starts in BLIND {{01,04,17,1a,1c}}: {nb}/{n} = {100.0*nb/max(n,1):.1f}%")
    print(f"      run-starts in CONTROL {{02,03,05,16,1b}}: {nc}/{n} = {100.0*nc/max(n,1):.1f}%")
    print(f"      enrichment: {(nb/max(nc,1)):.1f}x")
    perfile_b = {}
    for _, b, _ in rows:
        d = perfile_b.setdefault(os.path.basename(b["file"]), [0, 0, 0])
        d[2] += 1
        if rom[b["start"]] in BLIND:
            d[0] += 1
        if rom[b["start"]] in CTRL_SET:
            d[1] += 1
    for f in sorted(perfile_b):
        bl, ct, tt = perfile_b[f]
        print(f"        {f:32s} blind {bl:4d}/{tt:4d} = {100.0*bl/tt:5.1f}%   control {ct:4d}")

    print("\n    CODE, TYPE and BLOCKED verdicts in detail:")
    for v, b, ev in rows:
        if v == "DATA":
            continue
        print(f"      {v:4} 0x{BASE+b['start']:06X} {b['size']:5,} B  "
              f"{os.path.basename(b['file'])}:{b['line']}  "
              f"tile={ev['tile']} tail={ev['tabletail']} rule={ev['rule']} "
              f"ctrl={ev['ctrl_ref']} imm={ev['imm_ref']} ptrref={ev['ptr_ref']} "
              f"blocked_by={ev.get('blind')} labels={b['labels'][:2]}")

    if a.control:
        sd = [b for b in blobs if b["kind"] == "byteblob" and is_sound_data(b["file"])]
        run(sd, "CONTROL / KNOWN DATA -- sound_data_*.s tone tables "
                "(any CODE verdict is a FALSE POSITIVE)")

        sizes = [b["size"] for b in scope] or [8]
        runs = []
        i = 0
        while i < SIZE:
            if terr[i] == 1:
                j = i
                while j < SIZE and terr[j] == 1:
                    j += 1
                if j - i >= 300:
                    runs.append((i, j))
                i = j
            else:
                i += 1
        rnd = random.Random(20260902)
        # ⚠ THE WINDOW MUST START ON AN INSTRUCTION BOUNDARY.  A first version of
        # this control cut at arbitrary offsets and scored only 55% byte-weighted
        # sensitivity -- but a real `.byte` island was carved out of a source file
        # AT an instruction boundary, so an arbitrary-offset window is a harder
        # problem than the one being measured and understates the classifier.
        # Boundaries come from unidasm decoding the run from its own start, which
        # is a real boundary because the territory map is the assembler's output.
        tmp2 = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
        fake = []
        tries = 0
        while len(fake) < 300 and tries < 4000:
            tries += 1
            sz = rnd.choice(sizes)
            s, e = rnd.choice(runs)
            if e - s < sz + 64:
                continue
            open(tmp2, "wb").write(rom[s:e])
            out = subprocess.run([UNI, tmp2, "-arch", "tlcs900", "-basepc", hex(BASE + s)],
                                 capture_output=True, text=True).stdout
            bnds = []
            for line in out.split("\n"):
                m = DASM.match(line.strip())
                if m:
                    bnds.append(int(m.group(1), 16) - BASE)
            bnds = [b for b in bnds if s + 8 <= b <= e - 8]
            if len(bnds) < 4:
                continue
            b0 = rnd.choice(bnds[:-1])
            after = [b for b in bnds if b > b0]
            if not after:
                continue
            b1 = min(after, key=lambda x: abs((x - b0) - sz))
            if b1 <= b0 or b1 - b0 > 4 * sz + 16:
                continue
            fake.append(dict(start=b0, end=b1, size=b1 - b0,
                             kind="byteblob", file="CONTROL", line=len(fake), labels=[]))
        run(fake, f"CONTROL / KNOWN CODE -- {len(fake)} whole-instruction windows cut from "
                  "long CODE runs, size-matched (any non-CODE verdict is a FALSE NEGATIVE)")

    if a.csv:
        import csv
        with open(a.csv, "w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["verdict", "addr", "size", "file", "line", "tile", "tabletail",
                        "rule", "ctrl_ref", "imm_ref", "ptr_ref", "blocked_by", "labels"])
            for v, b, ev in rows:
                w.writerow([v, "0x%06X" % (BASE + b["start"]), b["size"], b["file"], b["line"],
                            ev["tile"], ev["tabletail"], ev["rule"], ev["ctrl_ref"],
                            ev["imm_ref"], ev["ptr_ref"], ev.get("blind") or "",
                            "|".join(b["labels"])])
        print(f"\nwrote {a.csv}")


if __name__ == "__main__":
    main()
