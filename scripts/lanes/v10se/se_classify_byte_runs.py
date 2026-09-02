#!/usr/bin/env python3
r"""WHICH OF THE SOUND-EDITOR CORNER'S `.byte` OPERANDS ARE ACTUALLY DEBT?

QUESTION ANSWERED
-----------------
`v10/maincpu/audio/sound_editor_ui.s` and `semenu_routines.s` carry 8,611
`.byte` operands between them.  A raw count is NOT a debt figure: a genuine
byte-valued table written as `.byte` is already correctly represented.  This
tool splits every operand three ways:

  (a) CODE-AS-BYTE   -- a real TLCS-900 instruction the assembler cannot spell,
      left as raw bytes inside a live instruction stream.  Evidence required:
      the run is flanked by real instructions on BOTH sides in the source, AND
      an independent decoder (MAME `unidasm -arch tlcs900`) decoding the ROM
      from the run's own start address produces an instruction that CONSUMES
      the run (usually overrunning it -- the "fragment" shape documented in
      v9_v10_undisassembled_census.py, where 67% of such runs are the head of
      an instruction whose tail the source then mis-frames as the next line).
      Converting these needs an ASSEMBLER change, not a source change.

  (b) STRUCTURED DATA -- bytes that a typed description already exists for, or
      could exist for.  The decisive evidence used here is EXTERNAL and
      byte-exact: `v10/maincpu/audio/sound_editor_screens/se_*.c` compiles, with
      the project's own toolchain, to bytes identical to the ROM at the base
      address stated in each file's header (checked by the sibling script
      se_c_descriptor_vs_rom.py).  A run inside such a span is untyped data
      with a ready-made type.

  (d) BLOCKED ON A KNOWN DECODER GAP -- the run STARTS with one of the five
      leading opcode bytes the tlcs900 backend has no encoding for at all,
      {0x01, 0x04, 0x17, 0x1a, 0x1c} = normal / max / ldf / JP nnnn /
      CALL nnnn (see scripts/analysis/byte_run_start_enrichment.py and
      leading_byte_reserved_probe.py).  These CANNOT be converted until lane
      w10/missinginsns lands the five instructions; forcing them now risks a
      wrong reading that re-assembles to the same bytes and passes the gate.
      Reported as a TAG, not a verdict -- the enrichment behind it is a
      per-image statistic.  --enrichment recomputes it for these two files.

  (c) GENUINE BYTE TABLE -- everything else: byte-valued content that `.byte`
      already represents correctly (bitmap rows, single padding/fill bytes,
      string-adjacent tables) and for which no better type is known.

HOW THE CLASSIFIER COULD BE WRONG, AND THE CONTROL
--------------------------------------------------
The (a) test is a DECODE test, and a decode test on data is exactly the
data-as-code hazard: random bytes decode into plausible instructions.  Two
guards:

  * The flanking test is a SOURCE-STRUCTURE test, independent of the decoder:
    it asks whether the tree already believes the surrounding bytes are code.
    A run only reaches (a) if BOTH the source structure and the decoder agree.
  * CONTROL (--control): the same decode test is run over byte runs drawn from
    spans PROVEN to be data -- the interiors of the 23 se_*.c descriptor spans,
    which are certified data by an external byte-exact compile, not by any
    decoder.  The fraction of those windows that the (a) test would accept is
    the classifier's false-positive rate on data.  Quote it with any (a) number.

The (b) test has no such weakness: `MATCH` in se_c_descriptor_vs_rom.py means
the compiler emitted those exact ROM bytes from a typed struct, which no
decoder opinion can overturn.

INPUT
    An address->source-line map, produced by the tree's own tool:
        python3 scripts/analysis/address_line_map.py --dump /path/amap.json

RUN
    python3 scripts/lanes/v10se/se_classify_byte_runs.py --amap /path/amap.json
    python3 scripts/lanes/v10se/se_classify_byte_runs.py --amap /path/amap.json --control
    python3 scripts/lanes/v10se/se_classify_byte_runs.py --amap /path/amap.json --list b
"""
import argparse
import bisect
import json
import os
import random
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "lanes", "v10se"))
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000

# Leading opcode bytes with no encoding anywhere in tlcs900_backend, which
# unidasm decodes as real instructions.  Source: the shared tree's
# scripts/analysis/leading_byte_reserved_probe.py (393,216 operand
# continuations each) and unmapped_byte_oracle.py.
BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf",
         0x1a: "JP nnnn", 0x1c: "CALL nnnn"}
# Decodable bytes of similar magnitude -- the control set that makes any
# blind-byte rate mean something.  Do NOT widen this to all 256 values.
CONTROL_BYTES = {0x02, 0x03, 0x05, 0x16, 0x1b}

from se_byte_run_census import scan, TARGETS          # noqa: E402
import se_c_descriptor_vs_rom as cdesc                # noqa: E402

# Directives that emit bytes but are not instructions.
DIRECTIVE = re.compile(r"^\s*\.(byte|word|hword|long|dword|ascii|asciz|zero|"
                       r"fill|space|incbin|p2align|org|globl|include|equ|set)\b")
LABEL_ONLY = re.compile(r"^[A-Za-z_.$][\w.$]*:\s*(;.*)?$")


def load_amap(path):
    entries = json.load(open(path))
    keys, vals = [], []
    for e in entries:
        keys.append(e["addr"])
        vals.append((e["src"], e["line"]))
    return keys, vals


def line_addr_index(keys, vals):
    """(src, line) -> addr"""
    d = {}
    for a, (s, l) in zip(keys, vals):
        d.setdefault((s, l), a)
    return d


def source_lines(path):
    return open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")


def prev_next_kind(lines, start_line, end_line):
    """Is the run flanked by INSTRUCTION source lines on both sides?"""
    def kind(i):
        while 0 <= i < len(lines):
            s = lines[i].strip()
            if not s or s.startswith(";") or LABEL_ONLY.match(s):
                i += step
                continue
            return "directive" if DIRECTIVE.match(lines[i]) else "insn"
        return "edge"
    step = -1
    prev = kind(start_line - 2)
    step = 1
    nxt = kind(end_line)
    return prev, nxt


_UNI_CACHE = {}


def decode_len(rom, off):
    """Length in bytes of the first instruction unidasm decodes at `off`."""
    if off in _UNI_CACHE:
        return _UNI_CACHE[off]
    win = rom[off:off + 16]
    tmp = "/tmp/.se_uni_%d.bin" % os.getpid()
    open(tmp, "wb").write(win)
    out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc",
                          hex(BASE + off), "-count", "1"],
                         capture_output=True, text=True).stdout
    n = None
    for line in out.split("\n"):
        m = re.match(r"^[0-9A-Fa-f]+:\s+((?:[0-9A-Fa-f]{2}\s)+)", line)
        if m:
            n = len(m.group(1).split())
            break
    _UNI_CACHE[off] = n
    return n


def descriptor_spans():
    """[(lo, hi, name)] for every se_*.c whose compile MATCHES the ROM."""
    import tempfile
    rom = open(ROM, "rb").read()
    tmp = tempfile.mkdtemp(prefix="se-cdesc-cls-")
    spans = []
    for f in sorted(os.listdir(cdesc.SEDIR)):
        if not f.endswith(".c"):
            continue
        n = f[:-2]
        c = os.path.join(cdesc.SEDIR, f)
        base = cdesc.header_base(c)
        blob, err = cdesc.compile_bin(c, tmp)
        if blob is None or base is None:
            continue
        off = base - BASE
        if rom[off:off + len(blob)] == blob:
            spans.append((base, base + len(blob), n, n in cdesc.INTEGRATED))
    spans.sort()
    return spans


def covering(spans, lo, hi):
    """Descriptor overlapping [lo,hi), and how many of the run's bytes it covers.

    Containment is NOT required: the run scanner merges `.byte` lines that are
    separated only by comments, so one run can straddle a descriptor boundary.
    Attributing at BYTE level stops a 10-byte descriptor from being missed
    because the run around it is 50 bytes long.
    """
    for s, e, n, wired in spans:
        ov = min(hi, e) - max(lo, s)
        if ov > 0:
            return n, wired, ov
    return None, None, 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--control", action="store_true")
    ap.add_argument("--list", choices=["a", "b", "c", "d"])
    ap.add_argument("--enrichment", action="store_true",
                    help="blind-vs-control run-start rates for THESE two files")
    ap.add_argument("--json")
    args = ap.parse_args()

    rom = open(ROM, "rb").read()
    keys, vals = load_amap(args.amap)
    l2a = line_addr_index(keys, vals)
    spans = descriptor_spans()

    runs = []
    for t in TARGETS:
        rs = scan(os.path.join(ROOT, t))
        lines = source_lines(t)
        for r in rs:
            r["file"] = t
            a = l2a.get((t, r["start_line"]))
            if a is None:
                r["addr"] = None
                runs.append(r)
                continue
            r["addr"] = a
            r["prev_kind"], r["next_kind"] = prev_next_kind(
                lines, r["start_line"], r["end_line"])
            runs.append(r)

    unmapped = [r for r in runs if r["addr"] is None]
    mapped = [r for r in runs if r["addr"] is not None]

    for r in mapped:
        lo, hi = r["addr"], r["addr"] + r["nbytes"]
        name, wired, ov = covering(spans, lo, hi)
        r["cdesc"], r["cdesc_wired"], r["cdesc_bytes"] = name, wired, ov
        dl = decode_len(rom, lo - BASE)
        r["declen"] = dl
        flanked = r["prev_kind"] == "insn" and r["next_kind"] == "insn"
        r["flanked"] = flanked
        r["first"] = rom[lo - BASE]
        if name is not None and ov == r["nbytes"]:
            r["cls"] = "b"
            r["why"] = "inside byte-exact C descriptor %s%s" % (
                name, "" if wired else " (NOT yet in the build)")
        elif name is not None:
            r["cls"] = "b"
            r["why"] = ("straddles byte-exact C descriptor %s (%d of %d bytes"
                        " inside)%s" % (name, ov, r["nbytes"],
                                        "" if wired else " (NOT yet in the build)"))
        elif r["first"] in BLIND:
            r["cls"] = "d"
            r["why"] = ("starts with 0x%02X (%s) -- no encoding in the "
                        "tlcs900 backend; blocked until w10/missinginsns lands"
                        % (r["first"], BLIND[r["first"]]))
        elif flanked and dl is not None and dl >= r["nbytes"]:
            r["cls"] = "a"
            r["why"] = ("flanked by instructions; unidasm decodes a %d-byte "
                        "instruction over a %d-byte run" % (dl, r["nbytes"]))
        else:
            r["cls"] = "c"
            r["why"] = "no typed description and %s" % (
                "not flanked by code" if not flanked
                else "decoder does not span the run")

    # ------------------------------------------------------------ tally
    # BYTE-level, not run-level: a run that straddles a descriptor boundary
    # contributes its inside part to (b) and its outside part to (a)/(c).
    tot = {c: [0, 0] for c in "abcd"}
    for r in mapped:
        inb = r.get("cdesc_bytes", 0)
        rest = r["nbytes"] - inb
        if inb:
            tot["b"][0] += 1
            tot["b"][1] += inb
        if rest:
            k = r["cls"]
            if k == "b":
                k = "c"
            tot[k][0] += 1
            tot[k][1] += rest

    print("SOUND-EDITOR CORNER `.byte` THREE-WAY SPLIT")
    print("  files: %s" % ", ".join(os.path.basename(t) for t in TARGETS))
    print()
    print("  %-4s %-38s %6s %8s" % ("cls", "meaning", "runs", "bytes"))
    print("  %-4s %-38s %6d %8d" % ("(a)", "code-as-.byte (unspellable form)", *tot["a"]))
    print("  %-4s %-38s %6d %8d" % ("(b)", "structured data, typed C available", *tot["b"]))
    print("  %-4s %-38s %6d %8d" % ("(d)", "blocked: run starts on a backend gap", *tot["d"]))
    print("  %-4s %-38s %6d %8d" % ("(c)", "genuine byte table (already right)", *tot["c"]))
    print("  %-4s %-38s %6d %8d" % ("", "TOTAL mapped", len(mapped),
                                    sum(r["nbytes"] for r in mapped)))
    if unmapped:
        print("  %-4s %-38s %6d %8d" % ("", "UNMAPPED (inside a .macro body)",
                                        len(unmapped),
                                        sum(r["nbytes"] for r in unmapped)))
    print("  (runs may be counted in two classes when they straddle a boundary;")
    print("   the BYTE columns partition the total exactly.)")

    bsel = [r for r in mapped if r.get("cdesc_bytes")]
    unwired = [r for r in bsel if not r["cdesc_wired"]]
    print()
    print("  of (b): %d runs / %d `.byte` operands lie in a descriptor NOT yet"
          " in the build" % (len(unwired), sum(r["cdesc_bytes"] for r in unwired)))
    seen = {}
    for r in bsel:
        seen.setdefault(r["cdesc"], [0, 0, r["cdesc_wired"]])
        seen[r["cdesc"]][0] += 1
        seen[r["cdesc"]][1] += r["cdesc_bytes"]
    for n in sorted(seen):
        c, b, w = seen[n]
        print("      %-28s %2d runs %5d B  %s" % (n, c, b,
                                                  "in build" if w else "NOT in build"))

    if args.enrichment:
        print()
        print("RUN-START ENRICHMENT for these two files")
        print("  method of scripts/analysis/byte_run_start_enrichment.py:")
        print("  a residue of UNDECODED CODE starts disproportionately with a")
        print("  byte the backend refuses; a data residue does not.")
        for t in TARGETS:
            sel = [r for r in mapped if r["file"] == t]
            nb = sum(1 for r in sel if r["first"] in BLIND)
            nc = sum(1 for r in sel if r["first"] in CONTROL_BYTES)
            n = len(sel)
            rb, rc = 100.0 * nb / n, 100.0 * nc / n
            print("    %-24s blind %5.1f%% (%d/%d)   control %5.1f%% (%d/%d)"
                  "   %.0fx" % (os.path.basename(t), rb, nb, n, rc, nc, n,
                                (rb / rc) if rc else float("inf")))
        per = {}
        for r in mapped:
            if r["first"] in BLIND:
                per[r["first"]] = per.get(r["first"], 0) + 1
        for b in sorted(per):
            print("      0x%02X %-10s %4d runs" % (b, BLIND[b], per[b]))

    if args.control:
        print()
        print("CONTROL -- false-positive rate of the (a) decode test on PROVEN data")
        print("  population: every byte offset inside the 23 byte-exact se_*.c spans")
        random.seed(17)
        lens = [r["nbytes"] for r in mapped if r["cls"] == "a"] or [1]
        hits = n = 0
        for _ in range(400):
            s, e, _nm, _w = random.choice(spans)
            L = random.choice(lens)
            if e - s <= L:
                continue
            off = random.randrange(s, e - L) - BASE
            dl = decode_len(rom, off)
            n += 1
            if dl is not None and dl >= L:
                hits += 1
        print("  %d/%d windows (%.1f%%) would pass the DECODE half of the (a) test"
              % (hits, n, 100.0 * hits / max(n, 1)))
        print("  -- so the decoder alone is nearly UNINFORMATIVE at these run")
        print("     lengths: almost any byte starts something that decodes.")
        print("     The (a) verdict therefore rests on the SOURCE-STRUCTURE half.")
        print()
        print("  IN-DOMAIN CONTROL -- the FULL (a) test on runs PROVEN to be data")
        print("  population: the `.byte` runs that fall inside the byte-exact")
        print("  se_*.c descriptor spans.  Those bytes are certified DATA by an")
        print("  external compile, so every (a) verdict on them is a FALSE POSITIVE.")
        # only runs that lie ENTIRELY inside a proven-data span, so the
        # denominator is proven-data bytes and nothing else.
        indom = [r for r in mapped if r.get("cdesc_bytes") == r["nbytes"]]
        fp = [r for r in indom
              if r["flanked"] and r["declen"] is not None
              and r["declen"] >= r["nbytes"]]
        print("  %d/%d runs (%.1f%%), %d/%d bytes (%.1f%%) would be called (a)"
              % (len(fp), len(indom), 100.0 * len(fp) / max(len(indom), 1),
                 sum(r["nbytes"] for r in fp), sum(r["nbytes"] for r in indom),
                 100.0 * sum(r["nbytes"] for r in fp)
                 / max(sum(r["nbytes"] for r in indom), 1)))
        print("  This is the number to quote against the (a) total.")

    if args.list:
        print()
        for r in mapped:
            if r["cls"] == args.list:
                print("  %06X %5d B  %s:%d-%d  %s" % (
                    r["addr"], r["nbytes"], os.path.basename(r["file"]),
                    r["start_line"], r["end_line"], r["why"]))

    if args.json:
        json.dump(runs, open(args.json, "w"), indent=1)
        print("\nwrote %s" % args.json)


if __name__ == "__main__":
    main()
