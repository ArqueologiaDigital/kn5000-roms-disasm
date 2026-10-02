#!/usr/bin/env python3
"""rename_wsa1_call_wrappers.py -- WSA1 `sub_<ADDR>` routines that only call one named routine are named for that call.

QUESTION THIS ANSWERS / JOB IT DOES
  Many WSA1 routines are wrappers: load or push a constant or two, call ONE routine, clean the
  stack, return -- `ld a, 8:opc / call T_Msg0716_DispatchIndex / ret`.  Their whole behaviour is
  that call, so the call names them: `<Callee>_<args>` -- the callee without the routine-directory
  `T_` prefix, then each argument in source order: a constant (`Msg0716_DispatchIndex_8`,
  `Blink_SetEnable_1`) or a symbol, `DL_` dropped, plus its offset in decimal
  (`DisplayList_Run_M0delingSoundEditToneDriver`, the end pointer `+ 0xA8` of the same list
  skipped); a store to RAM is a side effect and not named -- or `<Callee>_Wrap` when an argument
  is a register or memory load,
  unique with 2, 3, ...  Only when the callee's name and the arguments are not address-based
  (no 6-hex-digit run, no `_0x..`): naming after `T_F41020` or `DL_F3BD07` would only spread
  address names.  A wrapper qualifies when it is a `sub_<ADDR>` label whose code up to the next
  label is at most 8 lines, ends in `ret`, holds exactly one call/jump, and otherwise only
  push/pop/ld/`inc N, xsp`/`lda xsp`.  Renames go through
  scripts/renaming/rename_wsa1_call_wrappers.sed over wsa1/**/*.s.  No byte changes.

USAGE
  python3 scripts/renaming/rename_wsa1_call_wrappers.py [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
OK = re.compile(r'^(push\w*|pop\w*|ld\w*|inc\s+\d+\s*,\s*xsp|lda\s+xsp|ret|retd)\b', re.I)
ADDRISH = re.compile(r'[0-9A-Fa-f]{6}|_0x[0-9A-Fa-f]+')
COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')


def const_of(arg):
    """`ld a, 8:opc` -> '8'; `pushw 0x01` -> '1'; a register or memory operand -> None."""
    m = re.match(r'^(?:ld\w*|push\w*)\s+(?:[a-z]+\s*,\s*)?(-?(?:0x[0-9a-fA-F]+|\d+))(?::\w+)?$', arg, re.I)
    if not m:
        return None
    return str(int(m.group(1), 0))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(REPO, "wsa1", "**", "*.s"), recursive=True))
    taken = set()
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = COL0.match(l)
            if m:
                taken.add(m.group(1))
    ren, st = {}, collections.Counter()
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        for i, l in enumerate(L):
            m = re.match(r'^(sub_[0-9A-F]{6}):', l)
            if not m:
                continue
            body = []
            for j in range(i + 1, min(i + 30, len(L))):
                if COL0.match(L[j]):
                    break
                c = L[j].split(";")[0].strip()
                if c:
                    body.append(c)
            if not body or len(body) > 8 or not re.match(r'^ret', body[-1], re.I):
                continue
            calls = [b for b in body if re.match(r'^(call|calr|jp|jrl|jr)\b', b, re.I)]
            others = [b for b in body if b not in calls]
            if len(calls) != 1 or not all(OK.match(b) for b in others):
                continue
            tgt = calls[0].split()[-1]
            if not re.match(r'^[A-Za-z_]\w*$', tgt) or re.match(r'^(sub_|loc_)', tgt) or ADDRISH.search(tgt):
                st["callee address-named"] += 1
                continue
            args = [b for b in others if not re.match(r'^(ret|retd|inc\s+\d+\s*,\s*xsp|pop|lda\s+xsp)', b, re.I)]
            if any(ADDRISH.search(x) for x in args):
                st["argument address-named"] += 1
                continue
            parts, seen, wrap = [], set(), False
            for x in args:
                if re.match(r'^ld\w*\s+\(', x, re.I):
                    continue                    # a store to RAM: a side effect, not an argument
                c = const_of(x)
                if c is not None:
                    parts.append(c)
                    continue
                s = re.match(r'^(?:ld\w*|push\w*)\s+(?:[a-z]+\s*,\s*)?([A-Za-z_]\w*)(?:\s*\+\s*(0x[0-9a-fA-F]+|\d+))?$', x, re.I)
                if s and not re.match(r'^(x?[a-z]{1,3}\d?)$', s.group(1), re.I):
                    if s.group(1) in seen:
                        continue                # the same object again (a display list's end)
                    seen.add(s.group(1))
                    parts.append(re.sub(r'^DL_', '', s.group(1)) + ("_%d" % int(s.group(2), 0) if s.group(2) else ""))
                    continue
                wrap = True
            stem = re.sub(r'^T_', '', tgt)
            base = stem + ("_Wrap" if wrap else "_" + "_".join(parts) if parts else "_Call")
            nm, k = base, 1
            while nm in taken:
                k += 1
                nm = "%s_%d" % (base, k)
            taken.add(nm)
            ren[m.group(1)] = nm
            st["renamed"] += 1
    print("%s%s" % (dict(st), "" if a.apply else " (dry run)"))
    if a.apply and ren:
        sed = os.path.join(REPO, "scripts", "renaming", "rename_wsa1_call_wrappers.sed")
        with open(sed, "w") as s:
            s.write("# generated by scripts/renaming/rename_wsa1_call_wrappers.py: single-call wrapper routines.\n")
            for old, new in sorted(ren.items()):
                s.write("s/\\b%s\\b/%s/g\n" % (old, new))
        subprocess.run(["sed", "-i", "-f", sed] + files, check=True)
    for o, n in sorted(ren.items())[:12]:
        print("  ", o, "->", n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
