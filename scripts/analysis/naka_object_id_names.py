#!/usr/bin/env python3
"""naka_object_id_names.py -- the firmware's own names for NAKA object ids, from its registrations.

QUESTION THIS ANSWERS
  The event-code catalog of 2026-10-02 (notes/event-codes-2026-10-02/) named the object ids its
  worklist met as INSTRUCTION operands in v10.  The same ids are passed far more often as
  arguments of the registration macros -- `RegMode 0x4, InitializeSuna_Str_MD_SND_ARG, 0x11,
  0x1440016, 0x1a000dc` -- and v7, which expands those macros, shows 57 of them as bare
  operands (`ld XBC,0x01440016`).  What does every such id mean, by the firmware's own name?

  All of it is in the registration calls of the v10 source and the ROM bytes they point at:
    * Function / ApFunction / MainFunction objects: `RegObjTabl <class>, <proc>, <count>,
      <table>, S` registers object table S; the same class registered at S + 0x300 is its NAME
      table -- u32 pointers to the firmware's own strings.  Object id 0x01SSnnnn is entry n of
      slot S; its name is string n of slot S + 0x300 ("MiddleNameFunc").  Constants
      NAKA_FUNC_<name> / NAKA_APFUNC_<name> / NAKA_MAINFUNC_<name>, the catalog's convention;
      a name that two modules share takes `_<Module>` (ApPlaySyori_Yoko).
    * Titles: `RegTitle <module>, <"TT_X" string>, <index>, ...` -> id 0x01A00000 + index,
      constant TITLE_X.
    * Modes: `RegMode <module>, <"MD_X" string>, <index>, ...` -> id 0x01800000 + index,
      constant NAKA_MODE_MD_X.
  Output: a catalog (JSON list, the format scripts/tools/apply_event_constants.py reads) of the
  ids NOT yet named in v10's shared/event_codes.s, each with its derivation as `meaning`; and,
  on stdout, every already-named id whose existing name disagrees with the derived one (those
  are reported, never renamed here).

USAGE
  make rebuilt_ROMs/kn5000_v10_program.llvm.elf
  python3 scripts/analysis/naka_object_id_names.py --out CATALOG.json
  python3 scripts/tools/apply_event_constants.py CATALOG.json --macros     # then make gate-all
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ELF = os.path.join(REPO, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")
ROMF = os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000
TREE = os.path.join(REPO, "v10/maincpu")
MAC = re.compile(r'^\s+(RegObjTable|RegObjTabl|RegObjTableHama|RegObjTablHama|RegMode|RegTitle|'
                 r'RegTitleHama)\s+([^;]*?)\s*(?:;.*)?$')
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')
EQU = re.compile(r'^\s*\.(?:equ|set)\s+([A-Za-z_]\w*)\s*,\s*(0x[0-9a-fA-F]+|\d+)\b')
KIND = {0x1600001: ("NAKA_FUNC_", "Function"), 0x1600002: ("NAKA_APFUNC_", "ApFunction"),
        0x1600003: ("NAKA_MAINFUNC_", "MainFunction")}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    rom = open(ROMF, "rb").read()
    sym = {}
    for l in subprocess.run([NM, "--defined-only", ELF], capture_output=True, text=True,
                            check=True).stdout.splitlines():
        ad, t, n = l.split()
        sym[n] = int(ad, 16)

    def val(x):
        x = x.strip()
        if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', x):
            return int(x, 0)
        return sym.get(x)

    def cstr(ad):
        o = ad - BASE
        if not 0 <= o < len(rom):
            return None
        e = rom.find(b"\0", o, o + 64)
        s = rom[o:e] if e > o else b""
        return s.decode("latin-1") if s and all(0x20 < b < 0x7f for b in s) else None

    named = {}                                          # value -> existing constant
    for f in glob.glob(os.path.join(TREE, "**", "*.s"), recursive=True):
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = EQU.match(l)
            if m and 0x01000000 <= int(m.group(2), 0) < 0x02000000:
                named.setdefault(int(m.group(2), 0), m.group(1))

    regs, titles, modes = {}, [], []                    # slot -> (class, table, count, module)
    for f in sorted(glob.glob(os.path.join(TREE, "**", "*.s"), recursive=True)):
        reader = None
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = LABEL.match(l)
            if m and m.group(1).startswith("Initialize"):
                reader = m.group(1)
            m = MAC.match(l)
            if not m:
                continue
            args = [x.strip() for x in m.group(2).split(",")]
            module = (reader or "?")[len("Initialize"):] or "?"
            if m.group(1).startswith("RegObj"):
                cls, cnt, tab, slot = val(args[0]), val(args[2]), val(args[3]), val(args[4])
                if None not in (cls, cnt, tab, slot) and cls in KIND:
                    if m.group(1) in ("RegObjTable", "RegObjTableHama"):
                        o = cnt - BASE                  # ParamC is the ADDRESS of a u16 count
                        cnt = int.from_bytes(rom[o:o + 2], "little") if 0 <= o < len(rom) else None
                    regs[slot] = (cls, tab, cnt, module)
            else:
                s = cstr(val(args[1])) if val(args[1]) is not None else None
                idx = val(args[2])
                if s and idx is not None:
                    (titles if m.group(1).startswith("RegTitle") else modes).append((idx, s, module))

    found = []                                          # (value, name, meaning)
    for slot, (cls, tab, cnt, module) in sorted(regs.items()):
        if slot >= 0x300 or slot + 0x300 not in regs or not cnt:
            continue
        ncls, ntab, ncnt, _ = regs[slot + 0x300]
        if ncls != cls:
            continue
        pre, kname = KIND[cls]
        for n in range(min(cnt, ncnt or cnt)):
            o = ntab - BASE + 4 * n
            p = int.from_bytes(rom[o:o + 4], "little")
            s = cstr(p)
            if not s or not re.match(r'^[A-Za-z_]\w*$', s):
                continue
            v = 0x01000000 | (slot << 16) | n
            found.append((v, pre + s, module,
                          "NAKA %s object id: entry %d of the %s %s table (registry slot 0x%X, "
                          "table 0x%06X), firmware name \"%s\" (name table slot 0x%X, 0x%06X). "
                          "Derived by scripts/analysis/naka_object_id_names.py." %
                          (kname, n, module, kname, slot, tab, s, slot + 0x300, ntab)))
    for idx, s, module in titles:
        if s.startswith("TT_"):
            found.append((0x01A00000 | idx, "TITLE_" + s[3:], module,
                          "Title id 0x%X, \"%s\": registered by RegTitle in Initialize%s. Derived by "
                          "scripts/analysis/naka_object_id_names.py." % (idx, s, module)))
    for idx, s, module in modes:
        if s.startswith("MD_"):
            found.append((0x01800000 | idx, "NAKA_MODE_" + s, module,
                          "NAKA mode id: entry %d of the Mode table (slot 0x180), registered by "
                          "RegMode as \"%s\" in Initialize%s. Derived by "
                          "scripts/analysis/naka_object_id_names.py." % (idx, s, module)))

    # one name per value, one value per name: a name two modules share takes _<Module>
    byname = collections.defaultdict(set)
    for v, n, mod, _ in found:
        byname[n].add(v)
    out, seen, disagree = [], set(), []
    for v, n, mod, meaning in sorted(found):
        if v in seen:
            continue
        seen.add(v)
        if len(byname[n]) > 1:
            n = "%s_%s" % (n, mod)
        if v in named:
            if named[v] != n and not named[v].startswith(n):
                disagree.append("0x%08X existing %s, derived %s" % (v, named[v], n))
            continue
        out.append({"value": "0x%08X" % v, "name": n, "meaning": meaning, "confidence": "derived"})
    json.dump(out, open(a.out, "w"), indent=1)
    print("derived %d ids; %d already named (%d disagree); %d new -> %s" %
          (len(seen), len(seen) - len(out), len(disagree), len(out), a.out))
    for d in disagree:
        print("  DISAGREE " + d)
    return 0


if __name__ == "__main__":
    sys.exit(main())
