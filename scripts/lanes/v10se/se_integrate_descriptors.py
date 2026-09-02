#!/usr/bin/env python3
r"""REPLACE THE SOUND-EDITOR SCREEN-DATA SPANS WITH THEIR TYPED C DESCRIPTORS.

QUESTION ANSWERED
-----------------
`se_c_descriptor_vs_rom.py` shows that 14 `se_*.c` screen descriptors compile,
byte for byte, to the ROM bytes at the base address stated in their own header,
yet the Makefile's SE_NAMES list never builds them and no assembly file
`.incbin`s them.  Meanwhile the same bytes are spelled in
`v10/maincpu/audio/sound_editor_ui.s` as a mixture of `.byte` runs, `.ascii`
literals and *disassembled instructions* -- the latter being data-as-code, the
hazard the byte gate is structurally unable to object to.

This tool works out, for each descriptor, EXACTLY which source lines emit the
descriptor's byte span, and rewrites those lines into a single `.incbin` of the
compiled struct.

WHY THE LINE RANGE IS TRUSTWORTHY
  The address of the first byte each source line emits comes from the tree's own
  `scripts/analysis/address_line_map.py`, which inserts a label before every
  byte-emitting line, links the marked mirror and reads the addresses out of the
  ELF -- and self-tests that the marked mirror still produces a ROM identical to
  the dump.

BOUNDARY SPLITS
  A descriptor's span rarely starts and ends on a source-line boundary.  Where a
  line straddles the boundary its outside bytes are re-emitted as a `.byte` line
  taken FROM THE ROM ITSELF, so the rewrite is byte-neutral by construction and
  the gate is what proves it.

  ⚠ A straddling line is, by that fact, MIS-FRAMED: the descriptor proves where
  the record ends, so an "instruction" reaching across that boundary was never
  an instruction.  Its outside bytes therefore become `.byte`, not a guess at
  some other instruction.

RUN
    python3 scripts/lanes/v10se/se_integrate_descriptors.py --amap /tmp/amap.json --plan
    python3 scripts/lanes/v10se/se_integrate_descriptors.py --amap /tmp/amap.json --apply
"""
import argparse
import bisect
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
import se_c_descriptor_vs_rom as cdesc            # noqa: E402

BASE = 0xE00000
TARGET = "v10/maincpu/audio/sound_editor_ui.s"
MAKEFILE = os.path.join(ROOT, "Makefile")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")


def byte_line(blob, indent="\t"):
    return indent + ".byte " + ", ".join("0x%02x" % b for b in blob)


def plan(amap_path):
    rom = open(ROM, "rb").read()
    entries = json.load(open(amap_path))
    addrs = [e["addr"] for e in entries]

    tmp = tempfile.mkdtemp(prefix="se-integrate-")
    out = []
    for f in sorted(os.listdir(cdesc.SEDIR)):
        if not f.endswith(".c"):
            continue
        name = f[:-2]
        if name in cdesc.INTEGRATED:
            continue
        c = os.path.join(cdesc.SEDIR, f)
        base = cdesc.header_base(c)
        blob, err = cdesc.compile_bin(c, tmp)
        if blob is None or base is None:
            out.append(dict(name=name, skip="does not compile: %s" % err))
            continue
        size = len(blob)
        if rom[base - BASE:base - BASE + size] != blob:
            out.append(dict(name=name, skip="compiled bytes differ from the ROM"))
            continue

        i = bisect.bisect_right(addrs, base) - 1          # line owning `base`
        j = bisect.bisect_right(addrs, base + size - 1) - 1  # line owning last byte
        if entries[i]["src"] != TARGET or entries[j]["src"] != TARGET:
            out.append(dict(name=name, skip="span lives in %s, not this lane's file"
                            % entries[i]["src"]))
            continue
        line0, line1 = entries[i]["line"], entries[j]["line"]
        a0 = entries[i]["addr"]
        a_next = entries[j + 1]["addr"]                  # first byte after line1
        out.append(dict(name=name, base=base, size=size,
                        line0=line0, line1=line1,
                        prefix=list(rom[a0 - BASE:base - BASE]),
                        suffix=list(rom[base + size - BASE:a_next - BASE])))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--plan", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    p = plan(args.amap)
    total = 0
    for d in p:
        if "skip" in d:
            print("SKIP  %-24s %s" % (d["name"], d["skip"]))
            continue
        total += d["size"]
        print("PLAN  %-24s %6X +%-4d  lines %d..%d  prefix %d B  suffix %d B"
              % (d["name"], d["base"], d["size"], d["line0"], d["line1"],
                 len(d["prefix"]), len(d["suffix"])))
    print("\n%d descriptors, %d bytes" % (sum(1 for d in p if "skip" not in d), total))
    if not args.apply:
        return

    path = os.path.join(ROOT, TARGET)
    lines = open(path, encoding="latin-1").read().split("\n")
    todo = sorted((d for d in p if "skip" not in d), key=lambda d: -d["line0"])
    for d in todo:
        repl = []
        # PRESERVATION: never drop an existing comment.  Earlier lanes left
        # per-range verdicts inside these spans; the descriptor supersedes the
        # verdict but not the record of it, so it is carried over verbatim.
        kept = [ln for ln in lines[d["line0"] - 1:d["line1"]]
                if ln.strip().startswith(";")]
        if d["prefix"]:
            repl.append("\t; tail of the record before %s, split off at its"
                        " proven boundary" % d["name"])
            repl.append(byte_line(d["prefix"]))
        repl.append("; %s: %d bytes -- screen layout data, base 0x%06X"
                    % (d["name"], d["size"], d["base"]))
        repl.append("; Compiled from C source"
                    " (maincpu/audio/sound_editor_screens/%s.c)" % d["name"])
        repl.append("\t.incbin \"includes/generated/%s.bin\"" % d["name"])
        if kept:
            repl.append("; --- comments carried over from the lines this"
                        " .incbin replaced; the byte-exact C descriptor")
            repl.append(";     supersedes their verdicts but not the record"
                        " of them: ---")
            repl += kept
        if d["suffix"]:
            repl.append("\t; head of the next record, split off at %s's proven end"
                        % d["name"])
            repl.append(byte_line(d["suffix"]))
        lines[d["line0"] - 1:d["line1"]] = repl
    open(path, "w", encoding="latin-1").write("\n".join(lines))
    print("\nrewrote %s" % TARGET)

    # Makefile: add the newly integrated names to SE_NAMES.
    mk = open(MAKEFILE, encoding="latin-1").read()
    names = [d["name"] for d in p if "skip" not in d]
    # `se_screen_*` blocks are v10-only (this lane derived them from the v10 ROM);
    # SE_NAMES is patsubst'd into v7/ and v9/ too, so they go in SE_V10_NAMES.
    for var, sel in (("SE_NAMES", lambda n: not n.startswith("se_screen_")),
                     ("SE_V10_NAMES", lambda n: n.startswith("se_screen_"))):
        want = [n for n in names if sel(n)]
        if not want:
            continue
        for ln in mk.split("\n"):
            if ln.startswith(var + " = "):
                cur = ln[len(var) + 3:].split()
                new = cur + [n for n in want if n not in cur]
                mk = mk.replace(ln, var + " = " + " ".join(new), 1)
                break
    mk = mk.replace(
        "# Note: se_drumkit_display and se_rhythm_transport_tables are"
        " .incbin'd in assembly.\n"
        "# The remaining SE files are compiled but awaiting .incbin"
        " integration.\n",
        "# Every name above is .incbin'd by assembly; se_apply_confirm and\n"
        "# se_setup_editor_full/se_setup_sel4 land in storage/flash_floppy_handlers.s,\n"
        "# the rest in audio/sound_editor_ui.s.\n")
    open(MAKEFILE, "w", encoding="latin-1").write(mk)
    print("updated SE_NAMES in Makefile")


if __name__ == "__main__":
    main()
