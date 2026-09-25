#!/usr/bin/env python3
r"""Evidence headers for the 120 ToneKit_* slices of tonekit_param_blocks.bin.

QUESTION ANSWERED
    Each `ToneKit_ParamBlock_NNN:` / `ToneKit_NullParams:` / `ToneKit_DefaultParams:`
    / `NakaInst_PFTK:` label in ui_widgets/widget_dispatch.s slices the C blob
    compiled from ui_widgets/tonekit_param_blocks.c.  Which DSP effect uses each
    slice, and as what?  Two 100-entry tables indexed by DSP effect number point
    into the blob (see the headers of ToneKit_VoiceDispatch_Table and
    DspFxSettingsPtrTable, and scripts/generators/gen_dsp_effect_records.py):
      range table    base 0xEE6044 -> {min,max,param_id} u16 x count  (count byte
                     0xEE5FE0+n; DSPCfg_LookupAndExtract 0xFDC41D `mul wa,6`)
      settings table base 0xEE61D4 -> 24-byte block, +0 = effect number
                     (DSPCfg_ReadViaTableLookup 0xFDC364)
    This script reads both tables from the ROM, and in front of every slice
    label writes a two-line header naming the effect(s) (DspEffectName_PtrTable
    0xE32A7A) and the role.  A slice no table points at says so.

    The headers' first line starts "; DSP effect data:"; --apply refuses a file
    that already has one (no stacking).

RUN
    python3 scripts/generators/gen_tonekit_block_headers.py --check      # print the plan
    python3 scripts/generators/gen_tonekit_block_headers.py --apply v10 v9 v7
"""
import argparse
import collections
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = 0xE00000
TAG = "; DSP effect data:"


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def u32(d, a):
    return struct.unpack_from("<I", d, a - B)[0]


def names(d):
    out = []
    for i in range(100):
        p = u32(d, 0xE32A7A + 4 * i)
        out.append(d[p - B:p - B + 16].decode("latin-1").strip())
    return out


def fxlist(fx, nm):
    if len(fx) <= 3:
        return ", ".join("%d %s" % (f, nm[f]) for f in fx)
    return "%d effect numbers (%s ...)" % (len(fx), ", ".join(str(f) for f in fx[:6]))


def plan(v="v10"):
    d = rom(v)
    nm = names(d)
    cnt = d[0xEE5FE0 - B:0xEE6044 - B]
    useA, useB = collections.defaultdict(list), collections.defaultdict(list)
    for i in range(100):
        useA[u32(d, 0xEE6044 + 4 * i)].append(i)
        useB[u32(d, 0xEE61D4 + 4 * i)].append(i)
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)
    nmout = subprocess.run([os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm"),
                            "--defined-only", elf], capture_output=True, text=True, check=True).stdout
    hdr = {}
    for ln in nmout.splitlines():
        p = ln.split()
        if len(p) != 3:
            continue
        a, n = int(p[0], 16), p[2]
        if not (0xEE4FC6 <= a < 0xEE6044) or "_0x" in n:
            continue
        if not (n.startswith("ToneKit_") or n == "NakaInst_PFTK"):
            continue
        fa, fb = useA.get(a, []), useB.get(a, [])
        if fa:
            c = sorted({cnt[f] for f in fa})
            h = ["%s parameter ranges of %s:" % (TAG, fxlist(fa, nm)),
                 "; %s x {min,max,param_id}; range-table entry(ies) %s (base 0xEE6044)."
                 % ("/".join(map(str, c)), ",".join(map(str, fa[:8])) + (" ..." if len(fa) > 8 else ""))]
        elif fb:
            h = ["%s 24-byte settings block of %s:" % (TAG, fxlist(fb, nm)),
                 "; +0 = effect number, +1.. parameter bytes; DspFxSettingsPtrTable entry(ies) %s."
                 % (",".join(map(str, fb[:8])) + (" ..." if len(fb) > 8 else ""))]
        else:
            h = ["%s no range-table or settings-table entry points here;" % TAG,
                 "; checked all 100 entries of both (0xEE6044, 0xEE61D4)."]
        if n == "ToneKit_NullParams":
            h = ["%s range block of the %d effect numbers with no DSP record list" % (TAG, len(fa)),
                 "; (%s ...): 2 x {min,max,param_id} = 12 bytes, though those effects'"
                 % ", ".join(map(str, fa[:6])),
                 "; count bytes (0xEE5FE0+n) say 5; range-table entries %s ..." % ",".join(map(str, fa[:8]))]
        if n == "ToneKit_ParamBlock_116":
            h.append("; The C slice named ToneKit_ParamBlock_116 is 0x80 bytes: its +0x18..+0x7B")
            h.append("; are the DSP parameter-count bytes (DSPCfg_GetSlotCount, 0xEE5FE0) and")
            h.append("; +0x7C..+0x7F is entry 0 of the range table (0xEE6044).")
        hdr[n] = h
    return hdr


def apply(v, hdr):
    """Insert the headers.  Refuses if the file already carries any (re-running
    would stack them); regenerate from the parent commit instead."""
    path = os.path.join(ROOT, v, "maincpu/ui_widgets/widget_dispatch.s")
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    if any(l.startswith(TAG) for l in lines):
        sys.exit("%s already has these headers" % path)
    out, done = [], 0
    for ln in lines:
        m = re.match(r"^([A-Za-z_][\w]*):", ln)
        if m and m.group(1) in hdr:
            out.extend(hdr[m.group(1)])
            done += 1
        out.append(ln)
    open(path, "wb").write("\n".join(out).encode("latin-1"))
    print("%s: %d headers" % (path, done))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    hdr = plan("v10")
    if a.check or not a.apply:
        for n, h in sorted(hdr.items()):
            print(n)
            for x in h:
                print("   " + x)
        return 0
    for v in a.apply:
        apply(v, hdr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
