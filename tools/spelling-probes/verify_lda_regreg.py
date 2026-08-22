#!/usr/bin/env python3
"""Which llvm-mc spelling reproduces unidasm's `lda r,r+r` bytes EXACTLY?

QUESTION ANSWERED
-----------------
unidasm prints e.g. `lda XBC,XBC+WA` for the ROM bytes `f3 07 e4 e0 31`.
A .byte -> instruction converter needs a spelling whose *encoding* equals those
exact bytes.  This script harvests every real instance from the KN5000 /
HD-AE5000 images, derives the spelling PURELY FROM THE RAW BYTES (never from
the printed text), assembles it with llvm-mc, and fails loudly on any mismatch.

THE SPELLING RULE (a function of the raw bytes)
----------------------------------------------
    f3 <m> <base> <index> <sub>       m = 0x03 -> 8-bit  index register
                                      m = 0x07 -> 16-bit index register
    sub = 0x30|r   ->   stb_dri  GR8[r], m, base, index
    GR8[r] = w a b c d e h l          (r = sub & 7)
The three addressing bytes pass through VERBATIM as plain immediates; the
register operand exists only to supply the low nibble r.  The GR8 letter is
therefore NOT related to either printed register name -- it is an index into a
completely different table:

    printed destination   XWA XBC XDE XHL XIX XIY XIZ XSP
    sub-opcode r            0   1   2   3   4   5   6   7
    GR8[r] you must write   w   a   b   c   d   e   h   l

So `lda XIY,XIY+A` (`f3 03 f4 e0 35`) is written `stb_dri e, 0x03, 0xf4, 0xe0`
and the `e` has nothing to do with XIY or with A.

The backend mnemonic is MISNAMED: `ST_DRI3B` / "stb_dri" is described in the
.td as a byte store, but sub-opcode 0x30 is really `lda XRR,mem`.  Its GR8
operand is what makes all eight destinations reachable, including `lda XSP,...`
(r=7 -> `l`), which the 32-bit-typed siblings could not reach.

PASSES
------
  rom         every printed `lda r,r+r` in all seven images: listing bytes are
              re-read from the ROM FILE, spelled from the raw bytes, assembled,
              and compared; then the assembled bytes are re-disassembled and the
              printed text must be identical.
  exhaustive  synthetic sweep of all 2*32*32*8 = 16384 encodings of the shape.
  blobs       the sites still sitting inside `.byte` blobs in the source trees
              (i.e. the ones a converter is currently blocked on).
  real        the `stb_dri` lines already present in the byte-exact v9/v7 trees,
              located at their real ROM addresses.
  neg         NEGATIVE CONTROLS: spellings that assemble and are WRONG.
  all         all of the above (default).

COMMAND
-------
  python3 tools/spelling-probes/verify_lda_regreg.py
  python3 tools/spelling-probes/verify_lda_regreg.py exhaustive

RESULT WHEN WRITTEN (2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b)
-------------------------------------------------------------------
  rom         1918 printed instances across v7 (566), v9 (565), v10 (565),
              subprogram v142 (215), subcpu boot (2), HD-AE5000 (5),
              table_data (0).  EVERY one is `f3 {03,07} base index 0x30|r`
              -- 1915 with mode 0x07, 3 with mode 0x03; 118 distinct byte
              strings; sub-opcodes 0x30..0x36 (0x37, `lda XSP,..`, never
              occurs in real code but is spellable -- see exhaustive).
              TEST 1  1918/1918 assembled byte-identical to the ROM FILE
              TEST 2  1918/1918 re-disassemble to the identical printed text
  exhaustive  16384/16384 byte-exact.  9216 of them (= 8 r x 24 base x
              24 index x 2 modes) re-print as `lda r,r+r`; the other 7168 use
              base/index bytes == 3 (mod 4), which unidasm renders `rE3L`
              style -- they still assemble byte-exactly, they are just not
              this printed form.
  blobs       323 sites still inside located `.byte` blobs -- v7 248,
              subprogram v142 45, v10 20, v9 10 -- 323/323 spellable
              byte-exactly, 0 unspellable.  Top files: midi_dispatch_handlers.s
              47, note_voice_mapping.s 46, kn5000_subprogram_v142.s 45,
              single_load.s 33.
  real        96 `stb_dri` source lines in the byte-exact trees are uniquely
              locatable by content in their ROM; 96/96 byte-exact.
  neg         6/6 dangerous candidates produced different bytes.
"""

import collections
import glob
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
if not os.path.isdir(os.path.join(REPO, "original_ROMs")):
    REPO = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
ROMS = os.path.join(REPO, "original_ROMs")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

# (image, load base, source trees that declare it)
IMAGES = [
    ("kn5000_v7_program.rom",      0xE00000, ["v7/maincpu"]),
    ("kn5000_v9_program.rom",      0xE00000, ["v9/maincpu"]),
    ("kn5000_v10_program.rom",     0xE00000, ["v10/maincpu", "v10"]),
    ("kn5000_table_data.rom",      0x800000, ["table_data"]),
    ("kn5000_subprogram_v142.rom", 0x000000, ["v142/subcpu"]),
    ("kn5000_subcpu_boot.ic30",    0xFE0000, ["subcpu/boot", "subcpu"]),
    ("hd-ae5000_v2_06i.ic4",       0x200000, ["hdae5000"]),
]

GR8 = ["w", "a", "b", "c", "d", "e", "h", "l"]

FORM = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+) +(lda [A-Z]+,[A-Z]+\+[A-Z]+)\s*$")
ANY = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+) +(\S.*?)\s*$")
ENC = re.compile(r"encoding: \[([0-9a-fx,]+)\]")

TMP = tempfile.mkdtemp(prefix="ldaregreg-")


def spell(b):
    """Spelling derived from RAW BYTES only.  None if this is not the form."""
    if len(b) != 5 or b[0] != 0xF3 or b[1] not in (0x03, 0x07):
        return None
    if b[4] & 0xF0 != 0x30:
        return None
    return "stb_dri %s, 0x%02x, 0x%02x, 0x%02x" % (GR8[b[4] & 7], b[1], b[2], b[3])


def encode(lines, tag):
    """Assemble `lines`, return one bytes() per line (order preserved)."""
    out = []
    CH = 4000
    for i in range(0, len(lines), CH):
        src = os.path.join(TMP, "%s_%d.s" % (tag, i))
        open(src, "w").write("\n".join(lines[i:i + CH]) + "\n")
        r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", src],
                           capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit("llvm-mc failed on %s:\n%s" % (src, r.stderr[:4000]))
        got = ENC.findall(r.stdout)
        if len(got) != len(lines[i:i + CH]):
            sys.exit("encoding count %d != %d in %s" % (len(got), len(lines[i:i + CH]), src))
        out += [bytes(int(x, 16) for x in m.split(",")) for m in got]
    return out


def disasm(path, base):
    # The listing MUST go to scratch: an earlier version wrote it next to the
    # ROM and littered original_ROMs/ with untracked *.unidasm.txt files.
    lst = os.path.join(TMP, os.path.basename(path) + ".unidasm.txt")
    with open(lst, "w") as f:
        subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(base)],
                       stdout=f, check=True)
    return lst


def redisasm_map(items):
    """items = [bytes]; return {offset: (bytes, text)} from a padded blob."""
    blob = os.path.join(TMP, "roundtrip_%d.bin" % len(items))
    pad = b"\x00" * 8
    with open(blob, "wb") as f:
        for b in items:
            f.write(b + pad)
    out = subprocess.run([UNIDASM, blob, "-arch", "tlcs900", "-basepc", "0"],
                         capture_output=True, text=True).stdout.splitlines()
    seen = {}
    for ln in out:
        m = ANY.match(ln)
        if m:
            seen[int(m.group(1), 16)] = (bytes(int(x, 16) for x in m.group(2).split()),
                                         m.group(3))
    return seen, pad


# --------------------------------------------------------------------------
def pass_rom():
    print("=== pass `rom`: every printed `lda r,r+r` in the seven images ===")
    rows = []
    shapes = collections.Counter()
    for name, base, _ in IMAGES:
        path = os.path.join(ROMS, name)
        if not os.path.exists(path):
            print("  skip (missing): %s" % name)
            continue
        rom = open(path, "rb").read()
        n = 0
        for ln in open(disasm(path, base)):
            m = FORM.match(ln.rstrip("\n"))
            if not m:
                continue
            addr = int(m.group(1), 16)
            b = bytes(int(x, 16) for x in m.group(2).split())
            # THE LISTING IS NOT THE EVIDENCE: re-read from the ROM FILE.
            real = rom[addr - base: addr - base + len(b)]
            assert real == b, "listing/ROM disagree at %s %06x" % (name, addr)
            rows.append((name, addr, b, m.group(3)))
            shapes[(b[0], b[1], len(b))] += 1
            n += 1
        print("  %-30s %5d instances" % (name, n))
    print("  byte shapes (b0, mode, len): %s" %
          ", ".join("%02x/%02x/%d:%d" % (k[0], k[1], k[2], v)
                    for k, v in sorted(shapes.items())))

    sp = [spell(r[2]) for r in rows]
    assert all(sp), "%d instances the rule refuses to spell" % sum(1 for s in sp if not s)
    got = encode(sp, "rom")
    bad = collections.Counter()
    for r, s, g in zip(rows, sp, got):
        if g != r[2]:
            bad[(r[2].hex(" "), g.hex(" "), s)] += 1
    print("  TEST 1 assembled bytes == ROM bytes : %d/%d" %
          (len(rows) - sum(bad.values()), len(rows)))
    for k, v in bad.most_common(20):
        print("     MISMATCH x%d rom=[%s] asm=[%s] via `%s`" % (v, k[0], k[1], k[2]))

    seen, pad = redisasm_map([r[2] for r in rows])
    ok, off = 0, 0
    for r in rows:
        t = seen.get(off)
        if t and t[0] == r[2] and t[1] == r[3]:
            ok += 1
        off += len(r[2]) + len(pad)
    print("  TEST 2 round-trip text identical    : %d/%d" % (ok, len(rows)))
    print("  distinct full byte strings          : %d" % len({r[2] for r in rows}))
    print("  distinct sub-opcodes                : %s" %
          sorted({"0x%02x" % r[2][4] for r in rows}))
    return len(rows) - sum(bad.values()) == len(rows) == ok


def pass_exhaustive():
    print("=== pass `exhaustive`: all 2*32*32*8 = 16384 encodings of the shape ===")
    enc = [bytes([0xF3, m, base, idx, 0x30 | r])
           for m in (0x03, 0x07)
           for base in range(0xE0, 0x100)
           for idx in range(0xE0, 0x100)
           for r in range(8)]
    got = encode([spell(b) for b in enc], "exh")
    exact = sum(1 for b, g in zip(enc, got) if b == g)
    print("  byte-exact                          : %d/%d" % (exact, len(enc)))
    for b, g in zip(enc, got):
        if b != g:
            print("     MISMATCH want=[%s] got=[%s] via `%s`" %
                  (b.hex(" "), g.hex(" "), spell(b)))
            break
    seen, pad = redisasm_map(enc)
    formcnt, off = 0, 0
    other = collections.Counter()
    for b in enc:
        t = seen.get(off)
        if t and t[0] == b and re.match(r"^lda [A-Z]+,[A-Z]+\+[A-Z]+$", t[1]):
            formcnt += 1
        elif t:
            other[t[1]] += 1
        off += len(b) + len(pad)
    print("  unidasm re-prints as `lda r,r+r`    : %d/%d" % (formcnt, len(enc)))
    if other:
        print("  other printed forms: %s" %
              ", ".join("%s x%d" % (k, v) for k, v in other.most_common(5)))
    return exact == len(enc)


def blob_runs(dirs):
    """Yield (file, firstline, bytes) for every maximal `.byte` run."""
    byte_re = re.compile(r"^\s*\.byte\s+(.*)$")
    for d in dirs:
        root = os.path.join(REPO, d)
        if not os.path.isdir(root):
            continue
        for f in sorted(glob.glob(root + "/**/*.s", recursive=True)):
            cur, start = b"", None
            for i, line in enumerate(open(f, errors="replace"), 1):
                m = byte_re.match(line)
                if m:
                    vals = [v.strip() for v in m.group(1).split(";")[0].split(",") if v.strip()]
                    try:
                        b = bytes(int(v, 0) & 0xFF for v in vals)
                    except ValueError:
                        if cur:
                            yield f, start, cur
                        cur, start = b"", None
                        continue
                    if not cur:
                        start = i
                    cur += b
                else:
                    s = line.strip()
                    if s.startswith(";") or s.startswith("#") or s.endswith(":") or not s:
                        continue   # labels/comments do not break a run
                    if cur:
                        yield f, start, cur
                    cur, start = b"", None
            if cur:
                yield f, start, cur


def pass_blobs():
    print("=== pass `blobs`: sites still inside `.byte` blobs (converter blockers) ===")
    total, allrows = 0, []
    for name, base, dirs in IMAGES:
        path = os.path.join(ROMS, name)
        if not os.path.exists(path):
            continue
        rom = open(path, "rb").read()
        located = []
        for f, ln, b in blob_runs(dirs):
            if len(b) < 8:
                continue
            i = rom.find(b)
            if i < 0 or rom.find(b, i + 1) >= 0:
                continue          # unlocatable or ambiguous -> not counted
            located.append((f, ln, base + i, b))
        rows = []
        for f, ln, addr, b in located:
            tf = os.path.join(TMP, "blob.bin")
            open(tf, "wb").write(b)
            out = subprocess.run([UNIDASM, tf, "-arch", "tlcs900", "-basepc", hex(addr)],
                                 capture_output=True, text=True).stdout
            for line in out.split("\n"):
                m = FORM.match(line)
                if m:
                    rows.append((os.path.relpath(f, REPO), ln, int(m.group(1), 16),
                                 bytes(int(x, 16) for x in m.group(2).split()), m.group(3)))
        print("  %-30s %4d blob sites" % (name, len(rows)))
        total += len(rows)
        allrows += rows
    if allrows:
        sp = [spell(r[3]) for r in allrows]
        bad = sum(1 for s in sp if s is None)
        got = encode([s for s in sp if s], "blob")
        ok = sum(1 for r, g in zip([r for r, s in zip(allrows, sp) if s], got) if r[3] == g)
        print("  total blob sites                    : %d" % total)
        print("  spellable byte-exactly              : %d/%d (unspellable %d)" %
              (ok, total, bad))
        by_file = collections.Counter(r[0] for r in allrows)
        for f, n in by_file.most_common(8):
            print("     %4d  %s" % (n, f))
        print("  first five sites:")
        for r in allrows[:5]:
            print("     %06x  [%s]  %-22s -> %s" %
                  (r[2], r[3].hex(" "), r[4], spell(r[3])))
        return ok == total
    return True


def pass_real():
    """The `stb_dri R, 0x03|0x07, ...` lines the byte-exact trees ALREADY carry."""
    print("=== pass `real`: already-converted source lines vs the real ROM ===")
    line_re = re.compile(r"^\s*stb_dri\s+([A-Za-z]+)\s*,\s*(0x0[37])\s*,\s*"
                         r"(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)", re.I)
    found = []
    for name, base, dirs in IMAGES:
        path = os.path.join(ROMS, name)
        if not os.path.exists(path):
            continue
        rom = open(path, "rb").read()
        for d in dirs:
            root = os.path.join(REPO, d)
            if not os.path.isdir(root):
                continue
            for f in sorted(glob.glob(root + "/**/*.s", recursive=True)):
                for i, line in enumerate(open(f, errors="replace"), 1):
                    m = line_re.match(line)
                    if not m:
                        continue
                    r = GR8.index(m.group(1).lower())
                    b = bytes([0xF3, int(m.group(2), 16), int(m.group(3), 16),
                               int(m.group(4), 16), 0x30 | r])
                    j = rom.find(b)
                    if j < 0 or rom.find(b, j + 1) >= 0:
                        continue     # not uniquely locatable by content alone
                    found.append((name, base + j, b, os.path.relpath(f, REPO), i,
                                  line.strip()))
    if not found:
        print("  no uniquely locatable source line (all byte strings repeat)")
        return True
    got = encode([spell(x[2]) for x in found], "real")
    ok = sum(1 for x, g in zip(found, got) if x[2] == g)
    print("  uniquely located source lines       : %d" % len(found))
    print("  byte-exact                          : %d/%d" % (ok, len(found)))
    for x in found[:6]:
        print("     %-26s %06x [%s]  %s:%d  `%s`" %
              (x[0], x[1], x[2].hex(" "), x[3], x[4], x[5]))
    return ok == len(found)


# Spellings that ASSEMBLE and are WRONG.  Compared as encoding TEXT because two
# of them emit relocation placeholders ("A") instead of bytes.
NEGATIVE_CONTROLS = [
    # 1. The converter's documented "parenthesise reg+reg" rule
    #    (scripts/converters/convert_corroborated_blocks.py docstring).  `bc`
    #    is swallowed as an undefined SYMBOL and the mode silently becomes
    #    (XWA + d16): five bytes, right length, wrong instruction, no warning.
    #    In a real object file it is `f3 e1 00 00 30` plus a dangling
    #    R_TLCS900_LO16 relocation against an undefined symbol named `bc`
    #    (llvm-mc -filetype=obj; llvm-objdump -s -r).
    ("lda xwa, (xwa+bc)",             "0xf3,0x07,0xe0,0xe4,0x30"),
    ("lda xbc, (xbc+wa)",             "0xf3,0x07,0xe4,0xe0,0x31"),
    # 2. Same trap with 32-bit index names.
    ("lda xwa, (xwa+xbc)",            "0xf3,0x07,0xe0,0xe4,0x30"),
    # 3. Naming the GR8 operand after the printed destination's "obvious"
    #    letter: `lda XWA,XWA+BC` is r=0 -> `w`, but `a` gives sub 0x31.
    ("stb_dri a, 0x07, 0xe0, 0xe4",   "0xf3,0x07,0xe0,0xe4,0x30"),
    # 4. The 32-bit-typed sibling with the same-looking operands: sub 0x60.
    ("stl_dri xwa, 0x07, 0xe0, 0xe4", "0xf3,0x07,0xe0,0xe4,0x30"),
    # 5. `lda_dri` -- the mnemonic whose NAME says lda, but sub 0x40 is the
    #    8-bit STORE `ld (mem),r8`.
    ("lda_dri xwa, 0x07, 0xe0, 0xe4", "0xf3,0x07,0xe0,0xe4,0x30"),
]

# Spellings that do not even parse -- harmless, recorded so nobody retries them.
NON_PARSING = ["lda XWA,XWA+BC", "lda XBC,XBC+WA", "stb_dri xwa, 0x07, 0xe0, 0xe4"]


def pass_neg():
    print("=== pass `neg`: candidates that ASSEMBLE but give the WRONG bytes ===")
    src = os.path.join(TMP, "neg.s")
    open(src, "w").write("\n".join(s for s, _ in NEGATIVE_CONTROLS) + "\n")
    r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", src],
                       capture_output=True, text=True)
    negs = re.findall(r"encoding: \[([^\]]+)\]", r.stdout)
    if len(negs) != len(NEGATIVE_CONTROLS):
        print("  !! only %d/%d negative controls assembled; llvm-mc said:\n   %s" %
              (len(negs), len(NEGATIVE_CONTROLS),
               r.stderr.strip().replace("\n", "\n   ")[:600]))
    good = 0
    for (s, want), g in zip(NEGATIVE_CONTROLS, negs):
        differs = (g != want)
        good += differs
        print("  %-33s -> [%s]%s  (ROM has [%s])" %
              ("`%s`" % s, g, "" if differs else "   <-- FAILED TO FAIL", want))
    print("  differ from the ROM bytes           : %d/%d" % (good, len(NEGATIVE_CONTROLS)))
    print("  and these do not parse at all (safe): %s" % ", ".join("`%s`" % s for s in NON_PARSING))
    for s in NON_PARSING:
        open(src, "w").write(s + "\n")
        rr = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", src],
                            capture_output=True, text=True)
        assert rr.returncode != 0, "`%s` unexpectedly ASSEMBLED -- re-classify it" % s
    return good == len(NEGATIVE_CONTROLS)


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    res = {}
    if what in ("all", "rom"):
        res["rom"] = pass_rom()
    if what in ("all", "exhaustive"):
        res["exhaustive"] = pass_exhaustive()
    if what in ("all", "blobs"):
        res["blobs"] = pass_blobs()
    if what in ("all", "real"):
        res["real"] = pass_real()
    if what in ("all", "neg"):
        res["neg"] = pass_neg()
    print("=== summary: %s ===" %
          ", ".join("%s=%s" % (k, "PASS" if v else "FAIL") for k, v in res.items()))
    print("scratch under %s" % TMP)
    sys.exit(0 if all(res.values()) else 1)


if __name__ == "__main__":
    main()
