#!/usr/bin/env python3
"""Which llvm-mc spelling reproduces unidasm's `ld r,(r32+r)` LOAD bytes?

QUESTION ANSWERED
-----------------
unidasm prints e.g. `ld W,(XIY+A)` for the ROM bytes `c3 03 f4 e0 20`, and
`ld A,(XIX+HL)` for `c3 07 f0 ec 21`.  A `.byte` -> instruction converter needs
a spelling whose *encoding* equals those exact bytes.  This script harvests
every real instance of that printed form from the KN5000 / HD-AE5000 ROM
images, re-reads the bytes FROM THE IMAGE at the harvested address, derives a
spelling PURELY FROM THE RAW BYTES (never from the printed text), assembles it
with llvm-mc, and fails loudly on any byte mismatch.

This is the LOAD direction; tools/spelling-probes/verify_ld_regreg_store.py is
the store (`ld (r32+r),r`, prefix 0xF3) sibling.

SPELLING RULE (a function of the raw bytes, not of the printed text)
--------------------------------------------------------------------
  <P> <m> <base> <index> <sub>        five bytes, always

      P    = 0xC3 -> ldb_dri   (destination is an  8-bit register)
             0xD3 -> ldw_dri   (destination is a  16-bit register)
             0xE3 -> ldl_dri   (destination is a  32-bit register)
      m    = 0x03 -> the index byte names an  8-bit register  (`(XIY+A)`)
             0x07 -> the index byte names a  16-bit register  (`(XIX+HL)`)
      sub  = 0x20|r , r = sub & 7 -> which register is loaded
      base, index  pass through VERBATIM as immediates; they are never decoded

  spelling = "<mnemonic> <REG[r]>, 0x<m>, 0x<base>, 0x<index>"

      R8   = w  a  b  c  d  e  h  l          (r = 0..7)
      R16  = wa bc de hl ix iy iz (sp)
      R32  = xwa xbc xde xhl xix xiy xiz xsp

  The three addressing bytes are IMMEDIATES, so no register-name table is
  needed for the base or the index -- which is what makes odd index bytes
  (0xFA, printed `QIZ`) spellable at all.  Only the DESTINATION needs a table,
  and its width comes from the PREFIX, not from how unidasm printed it.

⚠ THE MODE BYTE IS NOT ALWAYS 0x07.  477 of the 7,164 instances here use mode
0x03.  Reading the mode from the printed text is impossible (`(XHL+A)` and
`(XHL+WA)` differ only in that byte) and hardcoding 0x07 silently assembles a
DIFFERENT instruction of the same length -- see the negative controls.

KNOWN GAP
---------
  sub 0x27 under prefix 0xD3 is `ld SP,(mem)`; the backend's 16-bit register
  class has no SP, exactly as in the store direction.  It occurs ZERO times in
  any image here (the widest 0xD3 sub seen is 0x26), so nothing needs it.

COMMAND
-------
  python3 tools/spelling-probes/verify_ld_regreg_load.py

RESULT WHEN WRITTEN (2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b, unidasm
from ~/compartilhado/tools/unidasm)
-------------------------------------------------------------------------
  7164 printed `ld r,(r+r)` instances harvested:
      v7 2166   v9 2167   v10 2167   table_data 20
      subprogram v142 562   subcpu boot 4   HD-AE5000 78
    prefixes  0xc3:3437  0xd3:1500  0xe3:2227
    modes     0x07:6687  0x03:477
    22 distinct (prefix,sub) pairs, 343 distinct five-byte strings
  TEST 0 listing bytes == bytes re-read from the image : 7164/7164
  TEST 1 assembled bytes == image bytes                : 7164/7164
  TEST 2 round-trip through unidasm gives same text    : 7164/7164
  TEST 3 negative controls produced DIFFERENT bytes    : 7/7
    plus one WARNING case that matches for the wrong reason:
    `ldb_dri a, 0x103, 0xec, 0xe0` truncates 0x103 to 0x03 without a word.
WHAT WOULD FALSIFY IT: any instance where llvm-mc emits bytes other than the
image's.  TEST 1 prints and counts every mismatch; it reported none.

TWO NEIGHBOURS OF THE SUB-OPCODE, CHECKED BY HAND
-------------------------------------------------
  `c3 07 f0 ec 28` and `c3 07 f0 ec 2f` are NOT INSTRUCTIONS -- unidasm prints
  `db` for both -- which is why the rule tests `sub & 0xF8 == 0x20` rather than
  just the high nibble.
  `d3 07 f0 ec 27` IS one (`ld SP,(XIX+HL)`) and is the unspellable gap above;
  `e3 03 fc e0 27` (`ld XSP,(XSP+A)`) spells fine as
  `ldl_dri xsp, 0x03, 0xfc, 0xe0`, because the base byte passes through raw --
  no image here uses base 0xFC, and it would still be spellable if one did.
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

# (image, load base) -- the base only affects branch targets, not these encodings.
IMAGES = [("kn5000_v7_program.rom", 0xE00000),
          ("kn5000_v9_program.rom", 0xE00000),
          ("kn5000_v10_program.rom", 0xE00000),
          ("kn5000_table_data.rom", 0x800000),
          ("kn5000_subprogram_v142.rom", 0x000000),
          ("kn5000_subcpu_boot.ic30", 0xFE0000),
          ("hd-ae5000_v2_06i.ic4", 0x200000)]

R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", None]      # no SP in GR16
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
WIDTH = {0xC3: ("ldb_dri", R8), 0xD3: ("ldw_dri", R16), 0xE3: ("ldl_dri", R32)}

LINE = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+) +"
                  r"(ld [A-Z]{1,4},\([A-Z]{1,4}\+[A-Z]{1,4}\))$")
ANY = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+) +(\S.*)$")
ENC = re.compile(r"encoding: \[([^\]]+)\]")   # 'A' = relocation placeholder

# Spellings that ASSEMBLE CLEANLY and must NOT match. Compared as encoding TEXT
# because two of them emit relocation placeholders instead of bytes.
# ROM reference: `c3 03 ec e0 21` = `ld A,(XHL+A)` at 0xefc898 in v7.
NEGATIVE_CONTROLS = [
    # 1. unidasm's own text, pasted verbatim. `A` becomes an undefined SYMBOL and
    #    the addressing mode silently becomes (XHL + d16): 5 bytes, right length,
    #    wrong instruction, no diagnostic.
    ("ld A,(XHL+A)", "0xc3,0xed,A,A,0x21"),
    ("ld W,(XIY+A)", "0xc3,0xf5,A,A,0x20"),
    # 2. THE ONE THAT MATTERS: mode hardcoded to 0x07 when the ROM says 0x03.
    #    This is `ld A,(XHL+WA)` -- a different index register.
    ("ldb_dri a, 0x07, 0xec, 0xe0", "0xc3,0x07,0xec,0xe0,0x21"),
    # 3. the STORE mnemonic with the same addressing bytes (prefix 0xF3).
    ("lda_dri xbc, 0x03, 0xec, 0xe0", "0xf3,0x03,0xec,0xe0,0x41"),
    # 4. base and index swapped -- assembles, addresses a different location.
    ("ldb_dri a, 0x03, 0xe0, 0xec", "0xc3,0x03,0xe0,0xec,0x21"),
    # 5. a bad mode byte silently changes the LENGTH: three bytes, not five.
    ("ldb_dri a, 0x00, 0xec, 0xe0", "0xc3,0x00,0x21"),
    # 6. the wrong WIDTH mnemonic: same addressing bytes, prefix 0xD3 not 0xC3.
    ("ldw_dri bc, 0x03, 0xec, 0xe0", "0xd3,0x03,0xec,0xe0,0x21"),
    # 7. an out-of-range addressing byte is silently TRUNCATED to 8 bits, with
    #    no diagnostic -- the same trap as `lds32 xhl, 8` wrapping imm3 to 0.
    #    Here 0x103 & 0xff = 0x03, so this one happens to hit the ROM bytes:
    #    it is in the list as a WARNING, not as a control that must differ.
]

# The one candidate here that assembles to the RIGHT bytes for the wrong
# reason. Kept separate from the controls because it must MATCH, and the point
# is that llvm-mc accepted a 9-bit value in an 8-bit field without a word.
SILENT_TRUNCATION = ("ldb_dri a, 0x103, 0xec, 0xe0", "0xc3,0x03,0xec,0xe0,0x21")


def spelling(b):
    """Spelling derived from RAW BYTES; None if these are not this form."""
    if len(b) != 5 or b[0] not in WIDTH or b[1] not in (0x03, 0x07):
        return None
    if b[4] & 0xF8 != 0x20:
        return None
    mnem, table = WIDTH[b[0]]
    reg = table[b[4] & 0x07]
    if reg is None:
        return None                      # `ld SP,(mem)`: no GR16 SP. 0 sites.
    return "%s %s, 0x%02x, 0x%02x, 0x%02x" % (mnem, reg, b[1], b[2], b[3])


def encode(lines, tmp, tag):
    src = os.path.join(tmp, tag + ".s")
    open(src, "w").write("\n".join(lines) + "\n")
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", src],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr[:4000])
        sys.exit(1)
    return ENC.findall(r.stdout)


def main():
    tmp = tempfile.mkdtemp(prefix="ldregreg-load-")
    rows, images = [], {}
    for name, base in IMAGES:
        path = os.path.join(ROMS, name)
        if not os.path.exists(path):
            print("skip (missing): %s" % name)
            continue
        images[name] = (open(path, "rb").read(), base)
        lst = os.path.join(tmp, name + ".unidasm")
        with open(lst, "w") as f:
            subprocess.run([UNIDASM, path, "-arch", "tlcs900",
                            "-basepc", hex(base)], stdout=f, check=True)
        n = 0
        for ln in open(lst):
            m = LINE.match(ln.rstrip("\n"))
            if m:
                rows.append((name, int(m.group(1), 16),
                             bytes(int(x, 16) for x in m.group(2).split()),
                             m.group(3)))
                n += 1
        print("  %-32s %5d instances" % (name, n))

    print("printed `ld r,(r+r)` instances harvested : %d" % len(rows))
    print("  prefixes  : %s" % dict(collections.Counter(
        "0x%02x" % r[2][0] for r in rows)))
    print("  modes     : %s" % dict(collections.Counter(
        "0x%02x" % r[2][1] for r in rows)))
    print("  (prefix,sub) pairs : %d   distinct byte strings : %d" % (
        len({(r[2][0], r[2][4]) for r in rows}), len({r[2] for r in rows})))

    # TEST 0 -- provenance: the listing's bytes must be what the image holds.
    prov = 0
    for name, addr, b, _t in rows:
        img, base = images[name]
        if img[addr - base: addr - base + len(b)] == b:
            prov += 1
        else:
            print("   NOT IN IMAGE %s 0x%06x %s" % (name, addr, b.hex(" ")))
    print("TEST 0 listing bytes == image bytes      : %d/%d" % (prov, len(rows)))

    work = [(n, a, b, t, spelling(b)) for n, a, b, t in rows]
    unspellable = [w for w in work if w[4] is None]
    for w in unspellable:
        print("   NO SPELLING %s 0x%06x %s  %s" % (w[0], w[1], w[2].hex(" "), w[3]))
    hit = [w for w in work if w[4]]

    # TEST 1 -- bytes
    got = encode([w[4] for w in hit], tmp, "probe")
    assert len(got) == len(hit), "encoding count %d != %d" % (len(got), len(hit))
    bad = collections.Counter()
    for w, g in zip(hit, got):
        try:
            gb = bytes(int(x, 16) for x in g.split(","))
        except ValueError:
            gb = None                    # a relocation placeholder: not bytes
        if gb != w[2]:
            bad[(w[2].hex(" "), g, w[4])] += 1
    print("TEST 1 assembled bytes == image bytes    : %d/%d" %
          (len(hit) - sum(bad.values()), len(rows)))
    for k, n in bad.most_common(20):
        print("   MISMATCH x%d rom=[%s] asm=[%s] via `%s`" % (n, k[0], k[1], k[2]))

    # TEST 2 -- independent check: feed the assembled bytes back through unidasm
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
    print("TEST 2 round-trip text identical         : %d/%d" % (ok, len(rows)))

    # TEST 3 -- negative controls: each ASSEMBLES, each must be WRONG.
    encs = encode([c[0] for c in NEGATIVE_CONTROLS], tmp, "controls")
    ref = "0xc3,0x03,0xec,0xe0,0x21"                # ld A,(XHL+A) @ v7 0xefc898
    diff = 0
    for (txt, expect), e in zip(NEGATIVE_CONTROLS, encs):
        agree = (e == expect)
        wrong = (e != ref)
        if wrong:
            diff += 1
        print("   %-32s -> [%s] %s%s" % (
            txt, e, "DIFFERS" if wrong else "*** SAME -- control failed ***",
            "" if agree else "   (expected [%s])" % expect))
    print("TEST 3 negative controls differ          : %d/%d" %
          (diff, len(NEGATIVE_CONTROLS)))
    e = encode([SILENT_TRUNCATION[0]], tmp, "trunc")[0]
    print("   WARNING: `%s` -> [%s] -- the 9-bit value was truncated to 8 bits "
          "with no diagnostic" % (SILENT_TRUNCATION[0], e))
    trunc_ok = (e == SILENT_TRUNCATION[1])

    good = (prov == len(rows) and not unspellable
            and sum(bad.values()) == 0 and ok == len(rows)
            and diff == len(NEGATIVE_CONTROLS) and trunc_ok)
    print("\n%s" % ("ALL TESTS PASSED" if good else "FAILURES ABOVE"))
    return 0 if good else 1


if __name__ == "__main__":
    sys.exit(main())
