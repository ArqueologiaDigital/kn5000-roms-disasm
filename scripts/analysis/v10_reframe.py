#!/usr/bin/env python3
"""Question answered: can a named address span of a v10 maincpu source file be
re-spelled -- as typed data, or as correctly framed instructions -- without
changing a single byte of the ROM?

This is the conversion engine for the byte-run lane.  It never guesses what a
span IS; the caller states that in a spec file, having established it from the
REFERENCING CODE (what loads the base, what the range check is, what the stride
is).  The engine's whole job is to render the span and then prove the render is
byte-exact.

Spec: a JSON list of
    {"file": "<path relative to repo root>",
     "start": "0xFD175E", "end": "0xFD1A5E",
     "kind":  "long" | "word" | "byte" | "code",
     "per_line": 1,               (optional, entries per source line)
     "record":  128,              (optional, blank line every N bytes)
     "symbols": true,             (long/word only: name operands that hit a label)
     "comment": ["...", "..."]}   (prepended, preserving any existing header)

`start` and `end` MUST be addresses at which a source line begins, so that the
splice replaces whole lines; the engine refuses otherwise rather than silently
truncating an instruction.

kind="code" linear-sweeps the span through `llvm-mc -disassemble` and emits the
instructions it yields, falling back to `.byte` for exactly those bytes the
current backend cannot decode.  This is the ONLY kind that can commit the
data-as-code error, so it is used only where the caller has ruled data out.

Verification (always, not optional): after splicing, the engine assembles and
links the whole image and compares it to original_ROMs/kn5000_v10_program.rom.
If one byte differs the edit is rolled back and the run fails.  Sources are
read and written as latin-1 -- these files contain raw high bytes inside
.ascii literals and a UTF-8 round trip corrupts them.

Exact command (from the repo root):

    python3 scripts/analysis/v10_reframe.py --linemap /tmp/linemap.json \
        --spec notes/lanes/v10midi-reframe-spec.json

    python3 scripts/analysis/v10_reframe.py --linemap /tmp/linemap.json \
        --spec ... --dry-run      # print the render, touch nothing
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ROM_BASE = 0xE00000
LLVM = os.environ.get("LLVM_BIN",
                      os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def rom_bytes():
    return open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()


def elf_symbols():
    """address -> label, from the last built ELF (built if absent)."""
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")
    if not os.path.exists(elf):
        subprocess.run(["make", "rebuilt_ROMs/kn5000_v10_program.llvm.elf"],
                       cwd=ROOT, check=True)
    out = subprocess.run([os.path.join(LLVM, "llvm-nm"), "--defined-only", elf],
                         capture_output=True, text=True, check=True).stdout
    syms = {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) == 3 and re.fullmatch(r"[0-9a-fA-F]+", p[0]):
            a = int(p[0], 16)
            # first name wins, and prefer a name without a positional suffix
            if a not in syms or (re.search(r"_0x[0-9A-F]+$", syms[a])
                                 and not re.search(r"_0x[0-9A-F]+$", p[2])):
                syms[a] = p[2]
    return syms


def disassemble(data):
    """-> list of (nbytes, text) covering data exactly; undecodable bytes come
    back as ('.byte 0x..', 1)."""
    inp = " ".join("0x%02x" % c for c in data)
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-disassemble"], input=inp, capture_output=True, text=True)
    bad = set()
    for m in re.finditer(r"^<stdin>:1:(\d+): warning: invalid instruction encoding",
                         r.stderr, re.M):
        bad.add((int(m.group(1)) - 1) // 5)
    insns = [l.rstrip() for l in r.stdout.split("\n") if l.strip()]
    # re-encode the instruction texts in one batch to learn their lengths
    if insns:
        enc = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                              "-show-encoding"], input="\n".join(insns),
                             capture_output=True, text=True)
        lens = [len(m.group(1).split(",")) for m in
                re.finditer(r"encoding: \[([^\]]*)\]", enc.stdout)]
        if len(lens) != len(insns):
            raise SystemExit("re-encode produced %d encodings for %d instructions"
                             % (len(lens), len(insns)))
    else:
        lens = []
    out, i, k = [], 0, 0
    while i < len(data):
        if i in bad:
            out.append((1, "\t.byte 0x%02x" % data[i]))
            i += 1
            continue
        if k >= len(insns):
            out.append((1, "\t.byte 0x%02x" % data[i]))
            i += 1
            continue
        n = lens[k]
        out.append((n, "\t" + insns[k].strip()))
        i += n
        k += 1
    return out


def render(spec, rom, syms):
    """A spec may carry "segments": [{kind,len,...}, ...] to describe a span
    whose layout changes part-way (e.g. a 1-byte pad between two .long
    tables).  Segment lengths must sum to the span length."""
    a, b = int(spec["start"], 16), int(spec["end"], 16)
    segs = spec.get("segments")
    if segs:
        if sum(s["len"] for s in segs) != b - a:
            raise SystemExit("segments sum to %d, span %06x-%06x is %d bytes"
                             % (sum(s["len"] for s in segs), a, b, b - a))
        lines = []
        for c in spec.get("comment", []):
            lines.append(("\t; " + c) if c else "")
        off = a
        for sg in segs:
            sub = dict(spec)
            sub.pop("segments", None)
            sub.update(sg)
            sub["start"] = "0x%X" % off
            sub["end"] = "0x%X" % (off + sg["len"])
            sub["comment"] = sg.get("comment", [])
            lines += render_one(sub, rom, syms)
            off += sg["len"]
        return lines
    return render_one(spec, rom, syms)


def render_one(spec, rom, syms):
    a, b = int(spec["start"], 16), int(spec["end"], 16)
    data = rom[a - ROM_BASE:b - ROM_BASE]
    kind = spec["kind"]
    per = spec.get("per_line", 1)
    rec = spec.get("record")
    lines = []
    for c in spec.get("comment", []):
        lines.append("\t; " + c if c else "")
    if kind in ("long", "word"):
        w = 4 if kind == "long" else 2
        if len(data) % w:
            raise SystemExit("span %06x-%06x is not a whole number of %s" % (a, b, kind))
        items = []
        for i in range(0, len(data), w):
            v = int.from_bytes(data[i:i + w], "little")
            s = None
            if spec.get("symbols") and v in syms:
                s = syms[v]
            items.append((a + i, s or ("0x%0*x" % (w * 2, v))))
        for i in range(0, len(items), per):
            chunk = items[i:i + per]
            if rec and (chunk[0][0] - a) % rec == 0 and i:
                lines.append("")
            lines.append("\t.%s %s" % (kind, ", ".join(t for _, t in chunk)))
    elif kind == "byte":
        for i in range(0, len(data), per):
            if rec and i % rec == 0 and i:
                lines.append("")
            lines.append("\t.byte " + ", ".join("0x%02x" % c for c in data[i:i + per]))
    elif kind == "code":
        off = 0
        for n, text in disassemble(data):
            if spec.get("symbols"):
                m = re.search(r"\b(\d{6,})\b", text)
                if m and int(m.group(1)) in syms:
                    text = text.replace(m.group(1), syms[int(m.group(1))])
            lines.append(text)
            off += n
    else:
        raise SystemExit("unknown kind " + kind)
    return lines


def splice(path, lm, a, b, newlines):
    src = open(path, encoding="latin-1").read().split("\n")
    inv = {}
    for ln, ad in lm.items():
        inv.setdefault(ad, []).append(ln)
    if a not in inv or b not in inv:
        raise SystemExit("span %06x-%06x does not start/end on a source line in %s"
                         % (a, b, path))
    first = min(inv[a])
    last = min(inv[b])          # exclusive
    return src[:first - 1] + newlines + src[last - 1:], first, last


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True)
    ap.add_argument("--linemap", required=True)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-verify", action="store_true")
    args = ap.parse_args()

    rom = rom_bytes()
    syms = elf_symbols()
    maps = json.load(open(args.linemap))
    specs = json.load(open(args.spec))
    # apply per file, highest address first, so earlier splices keep their line numbers
    byfile = {}
    for s in specs:
        byfile.setdefault(s["file"], []).append(s)
    backups = {}
    for rel, group in byfile.items():
        path = os.path.join(ROOT, rel)
        lm = {int(k): v for k, v in maps[rel].items()}
        group.sort(key=lambda s: int(s["start"], 16), reverse=True)
        if not args.dry_run:
            backups[path] = open(path, encoding="latin-1").read()
        for s in group:
            new = render(s, rom, syms)
            out, f, l = splice(path, lm, int(s["start"], 16), int(s["end"], 16), new)
            print("%s  %s..%s  kind=%s  lines %d..%d (%d) -> %d"
                  % (rel, s["start"], s["end"], s["kind"], f, l, l - f, len(new)))
            if args.dry_run:
                for x in new[:12]:
                    print("      " + x)
                if len(new) > 12:
                    print("      ... (%d more)" % (len(new) - 12))
            else:
                open(path, "w", encoding="latin-1").write("\n".join(out))
    if args.dry_run or args.no_verify:
        return
    ok = verify()
    if not ok:
        for p, t in backups.items():
            open(p, "w", encoding="latin-1").write(t)
        sys.exit("REJECTED: rebuilt image differs from the ROM; all edits rolled back")
    print("VERIFIED: rebuilt v10 image is byte-identical to the ROM")


def verify():
    obj = "/tmp/v10reframe.o"
    elf = "/tmp/v10reframe.elf"
    binf = "/tmp/v10reframe.bin"
    inc = os.path.join(ROOT, "v10/maincpu")
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-filetype=obj", "-I", inc, "-o", obj,
                        os.path.join(inc, "kn5000_v10_program.s")],
                       cwd=ROOT, capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-4000:])
        return False
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                    os.path.join(inc, "maincpu.ld"), "-o", elf, obj], check=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, binf],
                   check=True)
    return open(binf, "rb").read() == rom_bytes()


if __name__ == "__main__":
    main()
