#!/usr/bin/env python3
"""Are the two machines' DSP effect programs the same bytes, or merely related?

QUESTION IT ANSWERS: both instruments drive NEC uPD6383GF effect DSPs -- the
KN5000's IC311 is one, and the SX-WSA1R's parts list carries three -- so their
effect microcode is written for the SAME processor and could in principle be
shared source.  Felipe asked whether the snippets are "similar enough across
chips and across device models" to declare as common files with ifdefs for minor
divergences.  This measures that instead of guessing.

RUN:  python3 notes/sound/effect_bytecode_shared.py
      python3 notes/sound/effect_bytecode_shared.py --selftest

METHOD.  Recover every `DSP_EffNN_Coef_Bytecode` block from the KN5000 sub-CPU
source, anchor its 24-byte head in the WSA1R's prom_c ROM image, and measure both
the common PREFIX and the whole-block agreement at that alignment.

★ THE ANSWER IS NO, AND IT IS NOT CLOSE.  Of 50 blocks of 32 bytes or more, 13
have their head present in the WSA1R at all, and **not one is byte-identical end
to end**.  Agreement at the best alignment runs 30%-70%, median 44%.  The single
closest, effect 5 (PHASER), shares a 164-byte prefix of 293 and then diverges at
+0xA4 -- `28` against `1e`, one coefficient.  Sharing these as common files would
mean an ifdef every few bytes through the middle of a coefficient table, which
obscures both copies rather than uniting them.

⚠ THE 37 NOT FOUND ARE NOT EVIDENCE OF ABSENCE.  Anchoring on a 24-byte head
misses any counterpart that differs inside those 24 bytes, so 13 is a LOWER bound
on how many are related.  It is an upper bound on nothing: for every block that
could be aligned, the answer was still "not identical".

⚠ AND THIS CORRECTS AN EARLIER CLAIM IN THIS PROJECT.  Effect 5's stream at WSA1R
0xFD7764 was reported as "byte-identical" to `DSP_Eff05_Coef_Bytecode`.  It is
not: that comparison looked at the first 48 bytes.  The finding that P7 programs
ARE DSP effects still stands on its own evidence (a 56/56 name-to-record
bijection); only the word "byte-identical" was wrong.

WHAT IS GENUINELY SHARED, and is worth sharing, is the DRIVER, not the data:
prom_a 0xF85F0F and prom_c 0xF98000 are 231 of 234 bytes identical, differing
only in the base literal.  See notes/FINDINGS-sound-subsystem-boundary.md.
"""
import os, re, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
WSA_ROM = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_c.ic28")
LAB = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
BYTE = re.compile(r'^\s*\.byte\s+(.*?)(?:;|$)')
WANT = re.compile(r'^DSP_Eff\d+_Coef_Bytecode$')
HEAD = 24


def kn_blocks():
    out = {}
    for p in glob.glob(os.path.join(ROOT, "v142", "subcpu", "*.s")):
        cur, buf = None, []
        for l in open(p, errors="replace"):
            m = LAB.match(l)
            if m:
                if cur and buf:
                    out[cur] = bytes(buf)
                cur = m.group(1) if WANT.match(m.group(1)) else None
                buf = []
                continue
            if cur:
                b = BYTE.match(l)
                if b:
                    for t in b.group(1).split(","):
                        t = t.strip()
                        if t.startswith("0x"):
                            buf.append(int(t, 16))
                elif l.strip() and not l.lstrip().startswith(";"):
                    if buf:
                        out[cur] = bytes(buf)
                    cur, buf = None, []
        if cur and buf:
            out[cur] = bytes(buf)
    return out


def compare():
    kn, rom = kn_blocks(), open(WSA_ROM, "rb").read()
    rows = []
    for name, blob in sorted(kn.items()):
        if len(blob) < 32:
            continue
        i = rom.find(blob[:HEAD])
        if i < 0:
            rows.append((name, len(blob), None, 0, 0))
            continue
        ws = rom[i:i + len(blob)]
        n = min(len(blob), len(ws))
        pref = 0
        while pref < n and blob[pref] == ws[pref]:
            pref += 1
        same = sum(1 for k in range(n) if blob[k] == ws[k])
        rows.append((name, len(blob), i, pref, 100 * same // n))
    return rows


def main():
    rows = compare()
    found = [r for r in rows if r[2] is not None]
    if "--selftest" in sys.argv:
        f = 0
        def ck(d, c, extra=""):
            nonlocal f
            print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
            f += not c
        ck("KN5000 effect blocks were recovered from source", len(rows) > 0, f"{len(rows)} block(s)")
        ck("the WSA1R prom_c image is readable", os.path.exists(WSA_ROM))
        ck("at least one block aligns in the WSA1R", len(found) > 0, f"{len(found)} aligned")
        # ★ the finding itself, as an invariant: if this ever FAILS, the two
        # machines' effect data has converged and sharing becomes worth revisiting.
        ck("NO aligned block is byte-identical end to end",
           all(r[4] < 100 for r in found), "a failure here is GOOD NEWS -- re-read the docstring")
        ck("effect 5 is the closest and is still not identical",
           any(r[0].startswith("DSP_Eff05") and 60 <= r[4] < 100 for r in found))
        print(f"\n5 checks, {f} failures")
        return 1 if f else 0
    print(f"KN5000 DSP_EffNN_Coef_Bytecode blocks >= 32 bytes : {len(rows)}")
    print(f"  head present in the WSA1R prom_c image          : {len(found)}")
    print(f"  ★ byte-identical end to end                     : {sum(1 for r in found if r[4] == 100)}")
    if found:
        s = sorted(r[4] for r in found)
        print(f"  agreement at best alignment: min {s[0]}%  median {s[len(s)//2]}%  max {s[-1]}%")
        print("\n  block                          size  prefix  identical")
        for r in sorted(found, key=lambda r: -r[4]):
            print(f"    {r[0]:<30} {r[1]:5d} {r[3]:7d} {r[4]:9d}%")
    print("\n★ Related, not shared. Sharing these as common files would need an ifdef")
    print("  every few bytes through a coefficient table. The DRIVER is what is shared.")
    return 0

sys.exit(main())
