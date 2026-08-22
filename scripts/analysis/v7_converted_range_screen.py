#!/usr/bin/env python3
"""Read what a conversion round actually wrote, range by range.

QUESTION ANSWERED. `make clean-all && make all` reporting 100.00% says a round
kept the ROM byte-identical. It says NOTHING about whether the instructions it
wrote are instructions: a mis-framed decode re-assembles exactly too. The only
way to know is to read the emitted code, and a round emits thousands of lines.

This groups the added lines of `git diff -- v7/maincpu` into the contiguous
INSTRUCTION RUNS a converter emitted (a run ends at a `.incbin`, a `.byte` or an
unchanged line; labels do not end one), and ranks them by how many CPU-control
mnemonics they hold -- the forms ROM TABLE BYTES decode to. Reviewing the top of
that list is a few seconds' work and is what caught the five table decodes the
byte gate passed.

    python3 scripts/analysis/v7_converted_range_screen.py            # vs the working tree
    git diff REV~1 REV -- v7/maincpu | python3 scripts/analysis/v7_converted_range_screen.py -

MEASURED 2026-08-22. On the UNSCREENED `--apply`, six runs held a CPU-control
mnemonic and five of the six were data: ToneKit_FrequencyTable (a frequency
TABLE, `nop / swi 7 / max / ei 0x04 / ldwio / normal / halt`), CharMap_ValueData_B
(`rcf / incf / retd 0x1009`), WidgetParam_Entry_018 and SeqStep_ByteBlockEA5F.
The sixth was real code opening `ldb A,0x00 ; ei 0x06` -- which is why `ei` is
not in the set convert_reachable_ranges.py screens on. On the commit that shipped
(`git diff -U0 4cff1ba~1 4cff1ba -- v7/maincpu`) this reports 47 runs, 2,044
instructions and ZERO CPU-control hits.

⚠ A run with zero hits is NOT thereby proven code. This ranks; it does not
verify. The 38 clean runs were read too.
"""
import re
import subprocess
import sys

CTRL = ("swi", "normal", "max", "halt", "ldio", "ldwio", "retd")
NAMED = re.compile(r'^(call|calr|jp|jrl)\s+(?:\w+,\s*)?[A-Za-z_.]')


def runs_of(diff):
    runs, cur, f = [], None, None
    for ln in diff.split("\n"):
        if ln.startswith("+++ "):
            f = ln[6:]
            continue
        if ln.startswith(("@@", "---")):
            continue
        if not ln.startswith("+"):
            if cur:
                runs.append((f, cur))
            cur = None
            continue
        s = ln[1:].strip()
        if s.startswith((".incbin", ".byte", ".long", ".short", ".ascii")):
            if cur:
                runs.append((f, cur))
            cur = None
            continue
        if s.endswith(":") or not s:
            cur = cur if cur is not None else []
            continue
        cur = cur if cur is not None else []
        cur.append(s)
    if cur:
        runs.append((f, cur))
    return runs


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "-":
        diff = sys.stdin.buffer.read().decode("latin-1")
    else:
        diff = subprocess.run(["git", "diff", "-U0", "--", "v7/maincpu"],
                              capture_output=True).stdout.decode("latin-1")
    runs = runs_of(diff)
    print(f"{len(runs)} converted range(s), "
          f"{sum(len(r) for _f, r in runs):,} instructions\n")
    print(f"{'insns':>5} {'ctrl':>5} {'named':>5}  file / first instructions")
    for f, r in sorted(runs, key=lambda x: -sum(
            1 for i in x[1] if i.split()[0].lower() in CTRL)):
        ctrl = sum(1 for i in r if i.split()[0].lower() in CTRL)
        named = sum(1 for i in r if NAMED.match(i))
        print(f"{len(r):5} {ctrl:5} {named:5}  "
              f"{(f or '?').split('/')[-1]:28} {' | '.join(r[:4])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
