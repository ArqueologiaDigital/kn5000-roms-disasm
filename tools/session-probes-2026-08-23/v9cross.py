#!/usr/bin/env python3
"""Cross-check every blocking label against v9/v10, where the same name IS code."""
import json, os, pathlib, pickle, re, subprocess, sys

REPO = pathlib.Path("/home/fsanches/compartilhado/kn5000-roms-disasm")
S = pathlib.Path(os.environ["SCRATCH"])
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xE00000

ev = json.load(open(S / "evidence.json"))
rom7 = open(REPO / "original_ROMs/kn5000_v7_program.rom", "rb").read()
rom9 = open(REPO / "original_ROMs/kn5000_v9_program.rom", "rb").read()
rom10 = open(REPO / "original_ROMs/kn5000_v10_program.rom", "rb").read()


def syms(elf):
    out = {}
    for line in subprocess.run([NM, "--no-sort", str(REPO / elf)],
                               capture_output=True, text=True).stdout.splitlines():
        p = line.split()
        if len(p) == 3:
            try:
                a = int(p[0], 16)
            except ValueError:
                continue
            if BASE <= a < 0x1000000 and p[2] not in out:
                out[p[2]] = a
    return out


s9 = syms("rebuilt_ROMs/kn5000_v9_program.llvm.elf")
s10 = syms("rebuilt_ROMs/kn5000_v10_program.llvm.elf")


def match_window(a7, aX, romX, lim=512):
    back = 0
    while back < lim and a7 - BASE - back - 1 >= 0 and aX - BASE - back - 1 >= 0 \
            and rom7[a7 - BASE - back - 1] == romX[aX - BASE - back - 1]:
        back += 1
    fwd = 0
    while fwd < lim and a7 - BASE + fwd < len(rom7) and aX - BASE + fwd < len(romX) \
            and rom7[a7 - BASE + fwd] == romX[aX - BASE + fwd]:
        fwd += 1
    return back, fwd


# where each label is DEFINED in v9 sources, and what follows it
def defs(tree):
    out = {}
    for f in sorted((REPO / tree).rglob("*.s")):
        lines = f.read_bytes().decode("latin1").split("\n")
        for i, ln in enumerate(lines):
            m = re.match(r'^([A-Za-z_][\w]*):', ln)
            if m and m.group(1) not in out:
                out[m.group(1)] = (str(f), i, lines)
    return out


d9 = defs("v9/maincpu")
d10 = defs("v10/maincpu")


def kind_after(defs_, nm):
    if nm not in defs_:
        return "not defined"
    path, i, lines = defs_[nm]
    rest = lines[i].split(":", 1)[1].strip()
    j = i
    cand = rest
    while not cand:
        j += 1
        if j >= len(lines):
            return "eof"
        c = lines[j].strip()
        if not c or c.startswith((";", "#")):
            continue
        if re.match(r'^[A-Za-z_][\w]*:', c):
            c = c.split(":", 1)[1].strip()
            if not c:
                continue
        cand = c
    cand = re.split(r'[;#]', cand)[0].strip()
    if cand.startswith(".byte") or cand.startswith(".ascii") or cand.startswith(".long") \
            or cand.startswith(".short") or cand.startswith(".word"):
        return "DATA(" + cand.split()[0] + ")"
    if cand.startswith(".incbin"):
        return "INCBIN"
    if cand.startswith("."):
        return "dir(" + cand.split()[0] + ")"
    return "INSN: " + cand[:40]


rows = []
for rng in ev:
    for l in rng["labels"]:
        nm, a7 = l["name"], l["addr"]
        r = {"range": rng["entry"], "span": rng["span"], "n_off": rng["n_off"],
             "name": nm, "a7": a7}
        for tag, sX, romX, dX in (("v9", s9, rom9, d9), ("v10", s10, rom10, d10)):
            aX = sX.get(nm)
            if aX is None:
                r[tag] = None
                continue
            b, f = match_window(a7, aX, romX)
            r[tag] = {"addr": aX, "back": b, "fwd": f, "after": kind_after(dX, nm)}
        rows.append(r)

json.dump(rows, open(S / "v9cross.json", "w"), indent=1)

n = len(rows)
import collections
cat = collections.Counter()
for r in rows:
    best = None
    for tag in ("v9", "v10"):
        x = r[tag]
        if x and x["after"].startswith("INSN"):
            if best is None or (x["back"] + x["fwd"]) > (best[1]["back"] + best[1]["fwd"]):
                best = (tag, x)
    r["best"] = best[0] if best else None
    if best is None:
        cat["no sibling defines it as an instruction"] += 1
    else:
        b, f = best[1]["back"], best[1]["fwd"]
        if b >= 16 and f >= 16:
            cat[f"sibling INSN boundary, bytes agree >=16 both ways"] += 1
        elif b + f >= 16:
            cat[f"sibling INSN boundary, partial agreement (back {b}, fwd {f})"] += 1
        else:
            cat["sibling INSN boundary but bytes DISAGREE near the label"] += 1
print(f"{n} blocking labels")
for k, v in cat.most_common():
    print(f"  {v:4}  {k}")
json.dump(rows, open(S / "v9cross.json", "w"), indent=1)
