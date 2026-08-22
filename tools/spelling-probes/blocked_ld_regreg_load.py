#!/usr/bin/env python3
"""Which `ld r,(r32+r)` sites still block the converter, and why exactly?

QUESTION ANSWERED
-----------------
tools/spelling-probes/verify_ld_regreg_load.py proves the spelling rule over
every instance in the ROM images.  This script asks the converter's own,
narrower question:

    of the `ld <reg>,(<r32>+<reg>)` sites the v7/v9 sources still hold as
    `.byte`, which ones does scripts/converters/convert_reachable_ranges.py
    fail to spell today -- and does the raw-byte rule fix them?

It answers it twice, on two different populations:

  A. THE WHOLE `.byte` INVENTORY -- every site of the form inside a `.byte`
     blob in v7/maincpu and v9/maincpu, located in the ROM image before it is
     counted.  This is the work still on the table.
  B. THE CONVERTER'S OWN CENSUS -- the same test restricted to the reachable
     call-target ranges convert_reachable_ranges.py actually walks, which is
     the population its `--forms` count is drawn from.

  C. THE CONVERTER'S EXACT NUMBER -- B counts every site in those ranges, but
     the converter TRUNCATES a range at the first instruction it cannot spell
     and never reaches the rest, so it reports fewer.  Section C replays its
     gates (>=3 instructions, ends at `ret` or at code, branches nameable,
     stop at the first failure) and reproduces its printed count exactly,
     naming the sites it never gets to and what stopped it.

THE ROOT CAUSE IT PINS DOWN
---------------------------
convert_corroborated_blocks.translate() already emits ldb_dri/ldw_dri/ldl_dri
for this form, but it hardcodes the addressing-mode byte as 0x07 and rebuilds
the base/index bytes from a table keyed on the PRINTED register names:

    _RIDX = {"XIX": 0xF0, ..., "A": 0xE0, "C": 0xE4, "E": 0xE8, "L": 0xEC}
    yield f"{pre} {reg}, 0x07, 0x{base:02x}, 0x{index:02x}"

Mode 0x03 -- an 8-BIT index register -- is a real, common encoding, and the
printed text cannot distinguish it: `(XHL+A)` is mode 0x03 index 0xE0 while
`(XHL+WA)` is mode 0x07 index 0xE0.  Every mode-0x03 site therefore fails,
either because the hardcoded 0x07 assembles a DIFFERENT instruction (same
length, no diagnostic) or because the index name (`W`, `B`, `D`, `H`, `QIZ`)
is not in the table at all.  Taking m, base and index straight from the raw
bytes removes the table and the failure together.

COMMAND
-------
  python3 tools/spelling-probes/blocked_ld_regreg_load.py          (A only)
  python3 tools/spelling-probes/blocked_ld_regreg_load.py --ranges (A and B)
  Section A takes ~20 s, A+B ~35 s.

RESULT WHEN WRITTEN (2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b)
-------------------------------------------------------------------
  A. 1138 sites of the form still inside `.byte` blobs (v7: 1100, v9: 38)
       1030 mode 0x07   -- the converter spells all but one of them today
        108 mode 0x03   -- the converter spells NONE of them today
     located in the ROM image                    : 1138/1138
     converter's translate()/canonical() matches : 1029/1138
     raw-byte rule matches                       : 1138/1138
     The single mode-0x07 failure is v7 0xff1bcb `c3 07 e0 fa 21`
     = `ld A,(XWA+QIZ)`: index byte 0xFA is a PREVIOUS-BANK register and is
     not in the converter's name table either.  The raw-byte rule spells it
     without noticing, because the index byte is never decoded.
  B. reachable ranges: 210 sites of the form, 201 mode 0x07 + 9 mode 0x03;
     the 9 mode-0x03 sites are exactly the ones the converter cannot spell:
       0xefc898 c3 03 ec e0 21  ld A,(XHL+A)
       0xf54c3a c3 03 f4 e0 20  ld W,(XIY+A)
       0xf55fc4 d3 03 ec e0 23  ld HL,(XHL+A)
       0xf5619f d3 03 ec e1 23  ld HL,(XHL+W)
       0xf5edce d3 03 f4 e4 23  ld HL,(XIY+C)
       0xf670e8 c3 03 e0 ec 20  ld W,(XWA+L)
       0xf6e2c5 c3 03 f0 ed 27  ld L,(XIX+H)
       0xf6e2cc c3 03 f0 ed 26  ld H,(XIX+H)
       0xfcac9c e3 03 f0 e0 24  ld XIX,(XIX+A)
     raw-byte rule matches all 9.
  C. replaying the converter's gates gives 7, which is what
     `python3 scripts/converters/convert_reachable_ranges.py --forms` prints
     for `ld r,(r+r)` (2026-08-22 run, 257 unspellable instances in total).
     The two of the 9 it never reaches:
       0xefc898 -- its range 0xefc788 truncates 111 bytes earlier at
                   0xefc829 `c3 07 f0 f8 3f 0c` = `cp (XIX+IZ),0x0c`,
                   a DIFFERENT unspellable form
       0xf6e2cc -- its range 0xf6e24d truncates at 0xf6e2c5, which is the
                   previous site of THIS form, 7 bytes earlier
WHAT WOULD FALSIFY IT: a site where the raw-byte spelling assembles to bytes
other than the ROM's.  Both sections print and count every mismatch.
"""
import collections
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
BASE = 0xE00000
SOURCES = [("v7", "v7/maincpu", "original_ROMs/kn5000_v7_program.rom"),
           ("v9", "v9/maincpu", "original_ROMs/kn5000_v9_program.rom")]

R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", None]
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
WIDTH = {0xC3: ("ldb_dri", R8), 0xD3: ("ldw_dri", R16), 0xE3: ("ldl_dri", R32)}

BYTE_LINE = re.compile(r"^\s*\.byte\s+(.*?)\s*(?:;.*)?$")
DASM_LINE = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(.*?)\s*$")
FORM = re.compile(r"^ld [A-Z]{1,4},\([A-Z]{1,4}\+[A-Z]{1,4}\)$")
ENC = re.compile(r"encoding: \[([^\]]+)\]")


def spelling(b):
    """The rule under test: everything comes from the five raw bytes."""
    if len(b) != 5 or b[0] not in WIDTH or b[1] not in (0x03, 0x07):
        return None
    if b[4] & 0xF8 != 0x20:
        return None
    mnem, table = WIDTH[b[0]]
    reg = table[b[4] & 0x07]
    if reg is None:
        return None
    return "%s %s, 0x%02x, 0x%02x, 0x%02x" % (mnem, reg, b[1], b[2], b[3])


def unidasm(blob, basepc=0):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as t:
        t.write(blob)
        name = t.name
    try:
        return subprocess.run([UNIDASM, name, "-arch", "tlcs900",
                               "-basepc", hex(basepc)],
                              capture_output=True, text=True).stdout
    finally:
        os.unlink(name)


def assemble(lines):
    """Assemble a list of instructions in one call; None where it failed."""
    if not lines:
        return []
    src = "".join("\t%s\n" % l for l in lines)
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding"],
                       input=src, capture_output=True, text=True)
    out = []
    for m in ENC.findall(r.stdout):
        try:
            out.append(bytes(int(x, 16) for x in m.split(",")))
        except ValueError:
            out.append(None)            # relocation placeholder: not bytes
    return out


def blobs_of(path):
    out, cur, start = [], [], None
    for lineno, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        m = BYTE_LINE.match(line)
        vals = None
        if m:
            vals = []
            for tok in m.group(1).split(","):
                tok = tok.strip()
                try:
                    vals.append(int(tok, 0) & 0xFF)
                except ValueError:
                    vals = None
                    break
        if vals:
            if not cur:
                start = lineno
            cur.extend(vals)
        elif cur:
            out.append((start, bytes(cur)))
            cur = []
    if cur:
        out.append((start, bytes(cur)))
    return out


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, path))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def converter_candidates(text):
    """The spellings the converter would try today, in its own order."""
    cc = load("cc", "scripts/converters/convert_corroborated_blocks.py")
    return list(cc.translate(text)) + [cc.canonical(text)]


def section_a():
    print("A. every site of the form still inside a `.byte` blob")
    cc = load("cc", "scripts/converters/convert_corroborated_blocks.py")
    sites = []
    for tag, srcdir, rompath in SOURCES:
        rom = open(os.path.join(REPO, rompath), "rb").read()
        for dirpath, _, files in os.walk(os.path.join(REPO, srcdir)):
            for fn in sorted(files):
                if not fn.endswith(".s"):
                    continue
                for _lineno, blob in blobs_of(os.path.join(dirpath, fn)):
                    if len(blob) < 5 or not any(
                            p in blob for p in (b"\xc3", b"\xd3", b"\xe3")):
                        continue
                    at = rom.find(blob)
                    for line in unidasm(blob).splitlines():
                        m = DASM_LINE.match(line)
                        if not (m and FORM.match(m.group(3))):
                            continue
                        off = int(m.group(1), 16)
                        b = blob[off:off + 5]
                        sites.append(dict(
                            tag=tag, addr=(BASE + at + off) if at >= 0 else None,
                            bytes=b, text=m.group(3),
                            inrom=(at >= 0 and rom[at + off:at + off + 5] == b)))
    per = collections.Counter(s["tag"] for s in sites)
    modes = collections.Counter("0x%02x" % s["bytes"][1] for s in sites)
    print("   sites: %d  (%s)" % (len(sites), ", ".join(
        "%s:%d" % kv for kv in sorted(per.items()))))
    print("   modes: %s" % dict(modes))
    print("   located in the ROM image                 : %d/%d" %
          (sum(1 for s in sites if s["inrom"]), len(sites)))

    # what the converter can spell TODAY
    old_ok, old_bad_mode = 0, collections.Counter()
    for s in sites:
        hit = any(cc.encode(c) == s["bytes"] for c in converter_candidates(s["text"]))
        s["old"] = hit
        if hit:
            old_ok += 1
        else:
            old_bad_mode["0x%02x" % s["bytes"][1]] += 1
    print("   converter translate()/canonical() matches : %d/%d   "
          "(failures by mode: %s)" % (old_ok, len(sites), dict(old_bad_mode)))

    # what the raw-byte rule can spell
    spells = [spelling(s["bytes"]) for s in sites]
    missing = [s for s, sp in zip(sites, spells) if sp is None]
    for s in missing:
        print("   NO SPELLING 0x%06x %s  %s" %
              (s["addr"] or 0, s["bytes"].hex(" "), s["text"]))
    encs = assemble([sp for sp in spells if sp])
    todo = [s for s, sp in zip(sites, spells) if sp]
    new_ok = 0
    for s, e in zip(todo, encs):
        if e == s["bytes"]:
            new_ok += 1
        else:
            print("   MISMATCH 0x%06x rom=%s asm=%s" %
                  (s["addr"] or 0, s["bytes"].hex(" "),
                   e.hex(" ") if e else "None"))
    print("   raw-byte rule matches                     : %d/%d" %
          (new_ok, len(sites)))
    return new_ok == len(sites) and all(s["inrom"] for s in sites)


def section_b():
    print("\nB. the converter's own population: reachable call-target ranges")
    sys.argv = [sys.argv[0]]                      # crr reads sys.argv at import
    crr = load("crr", "scripts/converters/convert_reachable_ranges.py")
    cc = crr.cc
    spans = load("spans", "scripts/analysis/v7_undisassembled_spans.py")
    cwd = os.getcwd()
    os.chdir(REPO)
    try:
        rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
        terr = spans.territory(spans.runs(
            "v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
        targets = json.load(open(
            "analysis/v7-reachability/v7_call_targets.json"))["targets"]
        sites, fails = [], []
        for t in sorted(targets):
            insns = crr.decode_range(rom, terr, t)
            if len(insns) < 3:
                continue
            for a, n, x in insns:
                if not FORM.match(x):
                    continue
                want = rom[a - BASE: a - BASE + n]
                hit = any(cc.encode(c) == want
                          for c in list(cc.translate(x)) + [cc.canonical(x)])
                sites.append((a, want, x, hit))
                if not hit:
                    fails.append((a, want, x))
    finally:
        os.chdir(cwd)
    print("   sites in reachable ranges: %d  (modes %s)" % (
        len(sites), dict(collections.Counter("0x%02x" % s[1][1] for s in sites))))
    print("   the converter cannot spell: %d  (modes %s)" % (
        len(fails), dict(collections.Counter("0x%02x" % f[1][1] for f in fails))))
    encs = assemble([spelling(f[1]) for f in fails])
    ok = 0
    for f, e in zip(fails, encs):
        good = (e == f[1])
        ok += good
        print("     0x%06x %-16s %-18s -> %s" % (
            f[0], f[1].hex(" "), f[2],
            "raw-byte rule MATCHES" if good else "MISMATCH %s" %
            (e.hex(" ") if e else "None")))
    print("   raw-byte rule matches      : %d/%d" % (ok, len(fails)))
    return ok == len(fails)


def section_c():
    """Replay the converter's gates to reproduce its printed count exactly."""
    print("\nC. why `--forms` prints fewer: the converter truncates")
    sys.argv = [sys.argv[0]]
    crr = load("crr", "scripts/converters/convert_reachable_ranges.py")
    cc = crr.cc
    spans = load("spans", "scripts/analysis/v7_undisassembled_spans.py")
    cwd = os.getcwd()
    os.chdir(REPO)
    try:
        rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
        terr = spans.territory(spans.runs(
            "v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
        targets = json.load(open(
            "analysis/v7-reachability/v7_call_targets.json"))["targets"]
        syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
        addr2name = dict(syms)
        counted, unreached = [], []
        for t in sorted(targets):
            insns = crr.decode_range(rom, terr, t)
            if len(insns) < 3:
                continue
            off, run = t - BASE, 0
            while off + run < len(terr) and terr[off + run] == 2:
                run += 1
            span = sum(n for _, n, _ in insns)
            ends_at_code = (span == run)
            if (insns[-1][2].split()[0].lower() not in crr.TERMINATORS
                    and not ends_at_code):
                continue
            want = rom[t - BASE: t - BASE + span]
            br = crr.resolve_branches(insns, t, span, addr2name)
            if br is None:
                continue
            br_texts = br[0]
            pos, stopped = 0, None
            for bi, (a, n, x) in enumerate(insns):
                tgt = want[pos:pos + n]
                if br_texts[bi] is not None:
                    e = cc.encode(br_texts[bi])
                    if e is None or len(e) != n:
                        stopped = (a, tgt, x)
                        break
                    pos += n
                    continue
                if any(cc.encode(c) == tgt
                       for c in list(cc.translate(x)) + [cc.canonical(x)]):
                    pos += n
                    continue
                stopped = (a, tgt, x)
                if FORM.match(x):
                    counted.append((a, tgt, x))
                break
            if stopped is None:
                continue
            # Sites of the form PAST the truncation point that the converter
            # also could not spell: they belong to the same problem, but its
            # census never reaches them, so they are missing from its number.
            for a, n, x in insns:
                if a <= stopped[0] or not FORM.match(x):
                    continue
                b = rom[a - BASE: a - BASE + n]
                if any(cc.encode(c) == b
                       for c in list(cc.translate(x)) + [cc.canonical(x)]):
                    continue
                unreached.append((a, b, x, stopped))
    finally:
        os.chdir(cwd)
    print("   sites the converter actually counts: %d" % len(counted))
    for a, b, x in counted:
        print("     0x%06x %-16s %s" % (a, b.hex(" "), x))
    print("   unspellable sites of the form it never reaches: %d"
          % len(unreached))
    for a, b, x, st in unreached:
        print("     0x%06x %-16s %-18s  range stopped at 0x%06x %s (%s)" % (
            a, b.hex(" "), x, st[0], st[2], st[1].hex(" ")))
    return counted, unreached


def main():
    good = section_a()
    if "--ranges" in sys.argv:
        nb = section_b()
        counted, unreached = section_c()
        print("   %d counted + %d never reached = %d, section B's total"
              % (len(counted), len(unreached), len(counted) + len(unreached)))
        good = nb and good
    else:
        print("\n(sections B and C skipped; pass --ranges to run them, "
              "~30 s more)")
    print("\n%s" % ("ALL CHECKS PASSED" if good else "FAILURES ABOVE"))
    return 0 if good else 1


if __name__ == "__main__":
    sys.exit(main())
