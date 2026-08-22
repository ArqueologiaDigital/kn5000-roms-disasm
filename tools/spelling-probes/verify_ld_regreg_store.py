#!/usr/bin/env python3
"""Which llvm-mc spelling reproduces unidasm's `ld (r32+r),r` STORE bytes?

QUESTION ANSWERED
-----------------
unidasm prints e.g. `ld (XIX+HL),WA` for the ROM bytes `f3 07 f0 ec 50`.
A .byte -> instruction converter needs a spelling whose *encoding* equals
those exact bytes.  This script harvests every real instance of that printed
form from the KN5000/HD-AE5000 ROMs, derives a spelling PURELY FROM THE RAW
BYTES (never from the printed text), assembles it with llvm-mc, and fails
loudly on any byte mismatch.

THE RULE APPLIED
----------------
"it assembled" is not success.  Every instance is graded on
    assembled bytes == ROM bytes
and, as an independent second check, the assembled bytes are fed back through
unidasm and the printed text must equal the original listing text.  A third
section is a NEGATIVE CONTROL: spellings that look right, assemble cleanly,
and are asserted to produce DIFFERENT bytes.

SPELLING RULE (a function of the raw bytes, not of the printed text)
--------------------------------------------------------------------
  f3 <m> <base> <index> <sub>      with m in {0x03, 0x07}
      m = 0x03 -> index byte is an 8-bit  register  (prints `(XIX+C)`)
      m = 0x07 -> index byte is a 16-bit register  (prints `(XIX+HL)`)
      sub = 0x40|r  ->  lda_dri  GPR[r],  m, base, index   (stores an  8-bit reg)
      sub = 0x50|r  ->  stw_dri  GR16[r], m, base, index   (stores a  16-bit reg)
      sub = 0x60|r  ->  stl_dri  GPR[r],  m, base, index   (stores a  32-bit reg)
  GPR[r]  = XWA XBC XDE XHL XIX XIY XIZ XSP
  GR16[r] = WA  BC  DE  HL  IX  IY  IZ   (GR16 has no SP)
The three addressing bytes go through verbatim; the mnemonic is chosen by the
SUB-OPCODE HIGH NIBBLE, and the register operand only supplies the low nibble
r -- so for a byte store you write a *32-bit* register name whose encoding
equals the 8-bit register's encoding (A -> xbc, both r=1).

THE MOST DANGEROUS CANDIDATE: pasting unidasm's own text
--------------------------------------------------------
  `ld (XIX+HL),WA` ASSEMBLES.  It emits [0xf3,0xf1,A,A,0x50] -- the
  (XIX + d16) addressing mode, with `HL` parsed as an undefined SYMBOL that
  becomes a 2-byte relocation.  Five bytes, right length, wrong instruction,
  no diagnostic.

TWO BACKEND MNEMONICS ARE MISNAMED (verified against unidasm and the ROM)
-------------------------------------------------------------------------
  sub 0x30|r is really `lda XRR,mem`  but the backend calls it `stb_dri`
  sub 0x40|r is really `ld (mem),r8`  but the backend calls it `lda_dri`
  `f3 07 e0 e4 30` occurs 111x in v7 and unidasm prints `lda XWA,XWA+BC`.

KNOWN GAP
---------
  sub 0x57 = `ld (mem),SP` is unreachable: GR16 excludes SP.  It occurs zero
  times in any ROM here, so nothing needs it; use .byte if it ever turns up.

COMMAND
-------
  python3 tools/spelling-probes/verify_ld_regreg_store.py

RESULT WHEN WRITTEN (2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b)
-------------------------------------------------------------------
  2218 printed `ld (r+r),...` instances across v7 / v9 / v10 / table_data /
  subprogram v142 / subcpu boot / HD-AE5000.  1648 of them are the
  register-source form; 570 are immediate (sub 0x00 / 0x02) or memory-source
  (sub 0x14) and are a different instruction.
  TEST 1  1648/1648 assembled byte-identical
  TEST 2  1648/1648 round-tripped to identical printed text
  TEST 3  4/4 negative controls produced different bytes, as required
  26 distinct (mode, sub-opcode) pairs; 133 distinct full byte strings.
"""

import collections
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROMS = os.path.join(REPO, "original_ROMs")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

# (image, base) -- base only affects branch targets, not these encodings.
IMAGES = [("kn5000_v7_program.rom", 0xE00000),
          ("kn5000_v9_program.rom", 0xE00000),
          ("kn5000_v10_program.rom", 0xE00000),
          ("kn5000_table_data.rom", 0x800000),
          ("kn5000_subprogram_v142.rom", 0x000000),
          ("kn5000_subcpu_boot.ic30", 0xFE0000),
          ("hd-ae5000_v2_06i.ic4", 0x200000)]

GPR = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
GR16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", None]

LINE = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+) +(ld \(X[A-Z0-9]+\+[A-Z]+\),.*)$")
ANY = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+) +(\S.*)$")
ENC = re.compile(r"encoding: \[([0-9a-fx,]+)\]")

# Spellings that assemble but must NOT match, compared as encoding TEXT because
# one of them emits relocation placeholders rather than bytes.
NEGATIVE_CONTROLS = [
    # the unidasm text pasted verbatim: assembles, but "HL" becomes a SYMBOL and
    # the addressing mode silently becomes (XIX + d16).
    ("ld (XIX+HL),WA", "0xf3,0x07,0xf0,0xec,0x50"),
    # "store byte" by name, but sub-opcode 0x30 is really `lda XRR,mem`.
    ("stb_dri a, 0x07, 0xf0, 0xec", "0xf3,0x07,0xf0,0xec,0x41"),
    # the load direction (prefix C3/D3), not the store.
    ("ldb_dri a, 0x07, 0xf0, 0xec", "0xf3,0x07,0xf0,0xec,0x41"),
    ("ldw_dri wa, 0x07, 0xf0, 0xec", "0xf3,0x07,0xf0,0xec,0x50"),
]


def spelling(b):
    """Spelling derived from RAW BYTES; None if not a register-source store."""
    if len(b) != 5 or b[0] != 0xF3 or b[1] not in (0x03, 0x07):
        return None
    hi, r = b[4] & 0xF0, b[4] & 0x0F
    if r > 7:
        return None
    args = "0x%02x, 0x%02x, 0x%02x" % (b[1], b[2], b[3])
    if hi == 0x40:
        return "lda_dri %s, %s" % (GPR[r], args)
    if hi == 0x50:
        return None if GR16[r] is None else "stw_dri %s, %s" % (GR16[r], args)
    if hi == 0x60:
        return "stl_dri %s, %s" % (GPR[r], args)
    return None


def encode(lines, tmp, tag):
    src = os.path.join(tmp, tag + ".s")
    open(src, "w").write("\n".join(lines) + "\n")
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", src],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr[:4000])
        sys.exit(1)
    return [bytes(int(x, 16) for x in m.split(",")) for m in ENC.findall(r.stdout)]


def main():
    tmp = tempfile.mkdtemp(prefix="ldregreg-")
    rows = []
    for name, base in IMAGES:
        path = os.path.join(ROMS, name)
        if not os.path.exists(path):
            print("skip (missing): %s" % name)
            continue
        lst = os.path.join(tmp, name + ".unidasm")
        with open(lst, "w") as f:
            subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(base)],
                           stdout=f, check=True)
        for ln in open(lst):
            m = LINE.match(ln.rstrip("\n"))
            if m:
                rows.append((name, m.group(1),
                             bytes(int(x, 16) for x in m.group(2).split()),
                             m.group(3)))

    work = [(rom, a, b, t, spelling(b)) for rom, a, b, t in rows]
    hit = [w for w in work if w[4]]
    miss = [w for w in work if not w[4]]
    print("printed `ld (r+r),...` instances harvested : %d" % len(rows))
    print("  register-source (the form under test)    : %d" % len(hit))
    print("  immediate / memory-source (other form)   : %d" % len(miss))
    print("  distinct (mode,sub) pairs                : %d" %
          len({(w[2][1], w[2][4]) for w in hit}))
    print("  distinct full byte strings               : %d" % len({w[2] for w in hit}))

    got = encode([w[4] for w in hit], tmp, "probe")
    assert len(got) == len(hit), "encoding count %d != %d" % (len(got), len(hit))
    bad = collections.Counter()
    for w, g in zip(hit, got):
        if g != w[2]:
            bad[(w[2].hex(" "), g.hex(" "), w[4])] += 1
    print("TEST 1 assembled bytes == ROM bytes       : %d/%d" %
          (len(hit) - sum(bad.values()), len(hit)))
    for k, n in bad.most_common(20):
        print("   MISMATCH x%d rom=[%s] asm=[%s] via `%s`" % (n, k[0], k[1], k[2]))

    blob = os.path.join(tmp, "roundtrip.bin")
    pad = b"\x00" * 8
    with open(blob, "wb") as f:
        for w in hit:
            f.write(w[2] + pad)
    out = subprocess.run([UNIDASM, blob, "-arch", "tlcs900", "-basepc", "0"],
                         capture_output=True, text=True).stdout.splitlines()
    seen = {}
    for ln in out:
        m = ANY.match(ln)
        if m:
            seen[int(m.group(1), 16)] = (m.group(2).strip(), m.group(3).strip())
    ok, off = 0, 0
    for w in hit:
        t = seen.get(off)
        if t and t[1] == w[3] and bytes(int(x, 16) for x in t[0].split()) == w[2]:
            ok += 1
        off += len(w[2]) + len(pad)
    print("TEST 2 round-trip text identical          : %d/%d" % (ok, len(hit)))

    src = os.path.join(tmp, "neg.s")
    open(src, "w").write("\n".join(s for s, _ in NEGATIVE_CONTROLS) + "\n")
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", src],
                       capture_output=True, text=True)
    negs = re.findall(r"encoding: \[([^\]]+)\]", r.stdout)
    if r.returncode != 0 or len(negs) != len(NEGATIVE_CONTROLS):
        print("   a negative control failed to ASSEMBLE (that is fine, but then it "
              "is not a silent trap); llvm-mc said:")
        print("   " + r.stderr.strip().replace("\n", "\n   ")[:800])
    good = 0
    for (spell, want), g in zip(NEGATIVE_CONTROLS, negs):
        if g != want:
            good += 1
        else:
            print("   NEGATIVE CONTROL FAILED TO FAIL: `%s` == [%s]" % (spell, want))
        print("   `%-28s` -> [%s]   (ROM has [%s])" % (spell, g, want))
    print("TEST 3 negative controls differ           : %d/%d" %
          (good, len(NEGATIVE_CONTROLS)))

    c = collections.Counter((w[2][1], w[2][4]) for w in miss)
    print("other-form (mode/sub) tally: %s" %
          ", ".join("%02x/%02x:%d" % (k[0], k[1], v) for k, v in sorted(c.items())))
    print("scratch listings under %s" % tmp)


if __name__ == "__main__":
    main()
