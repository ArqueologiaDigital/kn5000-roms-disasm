#!/usr/bin/env python3
"""Which instruction reaches each v7 call target that lands in DATA territory?

QUESTION ANSWERED, AND ANSWERED "NO". `v7_reachable_from_code.py` collects
`call`/`calr`/`jp`/`jrl` targets and warns that some of them are junk -- calls
into data, or references read out of a CODE run that was itself mis-framed. When
`convert_reachable_ranges.py` started converting ranges inside `.incbin` ROM
slices, five of its decodes were obviously table data, so the obvious hypothesis
was that the REFERENCE KIND separates the two: a `call` is a function entry, a
`jrl` into a table is a mis-decode.

    python3 scripts/analysis/v7_target_reference_kind.py [ADDR ...]

MEASURED 2026-08-22, against a HEAD-restored copy (3,613 CODE runs, 758 targets
in DATA territory). THE HYPOTHESIS IS FALSE:

    0xEE4997  jrl   ToneKit region, decodes `nop / swi 7 / reti`   -- data
    0xEE4BFB  jrl   ToneKit_FrequencyTable                          -- data
    0xEE91D1  jrl   CharMap_ValueData_B                             -- data
    0xF4E67B  jrl   SeqStep_ByteBlockEA5F                           -- data
    0xFC5CB4  jrl   FileIO_BytecodeData -- 80 instructions of plainly REAL code
    0xF09AA6  jp    SeMenu_RefreshPartDisplay_Data -- 76 instructions, REAL

So `jrl`/`jp` references reach real functions as readily as junk, and reference
kind cannot be used as a filter. The screen that does work is the one on the
DECODE (see `IMPLAUSIBLE` in convert_reachable_ranges.py and
v7_mnemonic_census.py). Keeping this probe records why the cheaper idea was
dropped, so nobody re-derives it.

⚠ Runs against a copy of `v7/maincpu` with every file `git diff HEAD` names
restored to HEAD, because the converter's own output turns former targets into
CODE territory and would change the answer.
"""
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
REF_RE = re.compile(r'^([0-9a-f]+):\s+(?:[0-9a-f]{2} )+\s*'
                    r'(call|calr|jp|jrl)\s+(?:\w+,\s*)?0x([0-9a-f]+)$')


def head_tree():
    work = tempfile.mkdtemp(prefix="refkind_")
    shutil.copytree(os.path.join(REPO, "v7/maincpu"),
                    os.path.join(work, "v7", "maincpu"), symlinks=True)
    mod = subprocess.run(["git", "diff", "--name-only", "HEAD", "--", "v7/maincpu"],
                         cwd=REPO, capture_output=True, text=True).stdout.split()
    for rel in mod:
        open(os.path.join(work, rel), "wb").write(
            subprocess.run(["git", "show", f"HEAD:{rel}"], cwd=REPO,
                           capture_output=True).stdout)
    print(f"{len(mod)} file(s) restored to HEAD in {work}")
    return work


def main():
    work = head_tree()
    spec = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
    spans.l1.ROOT = work
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()

    runs, i = [], 0
    while i < len(terr):
        if terr[i] == 1:
            j = i
            while j < len(terr) and terr[j] == 1:
                j += 1
            if j - i >= 8:
                runs.append((i, j))
            i = j
        else:
            i += 1
    refs, tmp = {}, os.path.join(work, "_run.bin")
    for a, b in runs:
        open(tmp, "wb").write(rom[a:b])
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + a)],
                             capture_output=True, text=True).stdout
        for line in out.split("\n"):
            m = REF_RE.match(line.strip())
            if not m:
                continue
            t = int(m.group(3), 16)
            if 0 <= t - BASE < len(rom) and terr[t - BASE] == 2:
                refs.setdefault(t, []).append([m.group(2), f"0x{int(m.group(1), 16):06X}"])
    print(f"{len(runs)} CODE runs walked; {len(refs)} targets land in DATA territory")
    kinds = {}
    for v in refs.values():
        for k, _a in v:
            kinds[k] = kinds.get(k, 0) + 1
    print("  references by kind: " + ", ".join(f"{k} {n}" for k, n in sorted(kinds.items())))
    out_path = os.path.join(REPO, "analysis/v7-reachability/v7_target_reference_kind.json")
    json.dump({"generated_by": "scripts/analysis/v7_target_reference_kind.py",
               "targets": {f"0x{k:06X}": v for k, v in sorted(refs.items())}},
              open(out_path, "w"), indent=1)
    print(f"  wrote {os.path.relpath(out_path, REPO)}")
    for arg in sys.argv[1:]:
        t = int(arg, 16)
        print(f"0x{t:06X}: {refs.get(t, 'NOT REFERENCED FROM CODE TERRITORY')}")
    shutil.rmtree(work, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
