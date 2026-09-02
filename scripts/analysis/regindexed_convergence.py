#!/usr/bin/env python3
r"""regindexed_convergence.py -- how many raw-byte pseudo-instruction sites become
spellable with a MODELLED operand, and does the modelled spelling emit the same
bytes?

QUESTION ANSWERED
-----------------
notes/ASSESSMENT-syntax-convergence-2026-09-02.md class 3: 98 mnemonics over
22,135 sites whose operands are LITERAL BYTES -- `lda_dri xix, 7, 236, 232` --
so no rename can reach them.  Those bytes are the TLCS-900 memory-prefix
addressing mode.  This script decodes them, writes the native spelling, and
requires llvm-mc to give back the SAME bytes for both.

    lda_dri XDE, 0x07, 0xE4, 0xE0     f3 07 e4 e0 32
    lda xde, (xbc+wa)                 f3 07 e4 e0 32     <- must be equal

A site is counted RENAMEABLE only when both spellings assemble and the byte
strings are identical.  A site whose native spelling assembles to DIFFERENT
bytes is a defect and is reported separately -- that is the silent class this
project keeps being burned by, so it is never folded into a total.

⚠ THIS IS A PROPERTY OF THE BUILD.  llvm-mc is shared and mutable; the
toolchain commit is printed with every result and belongs beside any number
taken from here.

RUN (from the tree root)
    python3 scripts/analysis/regindexed_convergence.py                 # census
    python3 scripts/analysis/regindexed_convergence.py --selftest      # can it fail?
    python3 scripts/analysis/regindexed_convergence.py --sites         # ROM sites for the lit test
"""
import collections
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("LLVM_MC") or os.path.join(BIN, "llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/mame/unidasm")

# --- the register file, as the encoder writes it ---------------------------
# 32-bit base:  0xE0 + enc*4
GPR32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
# 16-bit index (mode 0x07): 0xE0 + enc*4  (+2 selects the PREVIOUS bank)
GR16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
QGR16 = ["qwa", "qbc", "qde", "qhl", "qix", "qiy", "qiz", "qsp"]
# 8-bit index (mode 0x03): the file is byte-addressed and little-endian, so the
# LOW half of a word register is at offset 0 -- A=0xE0, W=0xE1, C=0xE4, B=0xE5.
GR8_BY_BYTE = {0xE0: "a", 0xE1: "w", 0xE4: "c", 0xE5: "b",
               0xE8: "e", 0xE9: "d", 0xEC: "l", 0xED: "h"}

CC = ["f", "lt", "le", "ule", "ov", "mi", "z", "c",
      "t", "ge", "gt", "ugt", "nov", "pl", "nz", "nc"]


def base_name(b):
    if b < 0xE0 or (b - 0xE0) % 4:
        return None
    return GPR32[(b - 0xE0) // 4]


def idx16_name(b):
    if b < 0xE0:
        return None
    off = (b - 0xE0) % 4
    enc = (b - 0xE0) // 4
    if enc > 7:
        return None
    if off == 0:
        return GR16[enc]
    if off == 2:
        return QGR16[enc]
    return None


def idx8_name(b):
    return GR8_BY_BYTE.get(b)


def memrr(mode, b1, b2):
    """The `(base+index)` operand text for mode byte 0x07 / 0x03, or None."""
    base = base_name(b1)
    if base is None:
        return None
    idx = idx16_name(b2) if mode == 0x07 else idx8_name(b2)
    if idx is None:
        return None
    return "(%s+%s)" % (base, idx)


# --- the raw-byte spellings this script knows how to rewrite ----------------
# name -> (kind, how to build the native line)
#   'ld_r_m'  : <mn> R, b0, b1, b2      ->  ld R, (base+idx)
#   'ld_m_r'  : <mn> R, b0, b1, b2      ->  ld (base+idx), R
#   'lda'     : <mn> R, b0, b1, b2      ->  lda R, (base+idx)
#   'jpcall'  : <mn> cc, b0, b1, b2     ->  jp/call cc, (base+idx)
FAMILIES = {
    "ldb_sri":  ("ld_r_m", "ld"),
    "ldw_sri":  ("ld_r_m", "ld"),
    "ld_sril3": ("ld_r_m", "ld"),
    "ldb_dri":  ("ld_r_m", "ld"),
    "ldw_dri":  ("ld_r_m", "ld"),
    "ldl_dri":  ("ld_r_m", "ld"),
    "stb_dri":  ("ld_m_r", "ld"),
    "stw_dri":  ("ld_m_r", "ld"),
    "stl_dri":  ("ld_m_r", "ld"),
    "lda_dri":  ("lda",    "lda"),
    "jp_ind":   ("jpcall", "jp"),
    "call_ind": ("jpcall", "call"),
}

LINE = re.compile(r"^\s*([A-Za-z_][\w]*)\s+(.*?)\s*$")


def split_ops(rest):
    """Operands of a source line, comments stripped."""
    for cut in (";", "//"):
        i = rest.find(cut)
        if i >= 0:
            rest = rest[:i]
    return [o.strip() for o in rest.split(",") if o.strip()]


def as_int(tok):
    try:
        return int(tok, 0)
    except ValueError:
        return None


def native_for(mn, ops):
    """The native spelling of one raw-byte site, or (None, reason)."""
    kind, out_mn = FAMILIES[mn]
    if len(ops) != 4:
        return None, "operand-count"
    head = ops[0]
    b = [as_int(o) for o in ops[1:]]
    if any(x is None for x in b):
        return None, "non-literal-bytes"
    mode, b1, b2 = b
    if mode in (0x07, 0x03):
        m = memrr(mode, b1, b2)
        if m is None:
            return None, "unnameable-register-file-address"
    else:
        # The OTHER sub-form these same mnemonics carry: mode byte
        # 0xE0 + base*4 + 1 is `(Xrr+d16)`, with b1/b2 the little-endian
        # displacement.  It needs NO backend change -- the operand has been
        # modelled since UPDATE 7 -- so it is measured here beside the R+R
        # sites rather than assumed.
        if mode < 0xE0 or (mode - 0xE0) % 4 != 1:
            return None, "not-a-known-addressing-mode"
        base = GPR32[(mode - 0xE0) // 4]
        d16 = b1 | (b2 << 8)
        # ⚠ The d16 field is SIGNED in the source syntax: llvm-mc refuses an
        # operand that fits its field neither signed nor unsigned (95f7f2d40428).
        # Writing the raw unsigned value scored 571 sites as "bytes differ" on
        # the first run of this script -- a defect in the PROBE, not the
        # backend, and exactly the shape it exists to catch.
        if d16 >= 0x8000:
            d16 -= 0x10000
        m = "(%s%+d)" % (base, d16) if d16 else "(%s+0)" % base
    if kind == "ld_r_m":
        return "%s %s, %s" % (out_mn, head.lower(), m), None
    if kind == "ld_m_r":
        return "%s %s, %s" % (out_mn, m, head.lower()), None
    if kind == "lda":
        return "lda %s, %s" % (head.lower(), m), None
    if kind == "jpcall":
        cc = as_int(head)
        if cc is None or not 0 <= cc < 16:
            return None, "bad-condition-code"
        return "%s %s, %s" % (out_mn, CC[cc], m), None
    return None, "unhandled"


SENTINEL = "nop"          # 1 byte, 0x00; no R+R encoding can collide with it


def assemble(lines):
    """Assemble each line in isolation; return [bytes|None] parallel to lines.

    ⚠ POSITION IS NOT A SAFE INDEX.  llvm-mc prints an `encoding:` line for a
    line it merely diagnosed (see notes/syntax-convergence-probes/README.md)
    but prints NOTHING for one that fails to match any instruction, so the
    output list and the input list drift apart at the first refusal -- which
    silently pairs every later candidate with its NEIGHBOUR's bytes.  A
    SENTINEL instruction after each candidate re-synchronises them.
    """
    out = []
    CHUNK = 2000
    for start in range(0, len(lines), CHUNK):
        part = lines[start:start + CHUNK]
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "a.s")
            with open(p, "w") as f:
                for ln in part:
                    f.write("\t" + ln + "\n\t" + SENTINEL + "\n")
            r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", p],
                               capture_output=True, text=True, errors="replace")
            got = []
            for line in r.stdout.split("\n"):
                m = re.search(r"; encoding: \[([^\]]*)\]", line)
                if m:
                    got.append(m.group(1))
            sent = None
            # The first sentinel encoding is whatever `nop` assembles to; take
            # it from a line we know assembled, rather than hard-coding a byte.
            for g in got:
                if g == "0x00":
                    sent = g
                    break
            if sent is None:
                raise SystemExit("sentinel never assembled -- cannot align output")
            res, group = [], []
            for g in got:
                if g == sent:
                    res.append(group[0] if len(group) == 1 else None)
                    group = []
                else:
                    group.append(g)
            while len(res) < len(part):
                res.append(None)
            out.extend(res[:len(part)])
    return out


def walk_sources():
    for dp, dn, fns in os.walk(ROOT):
        if os.sep + ".git" in dp:
            continue
        for fn in sorted(fns):
            if fn.endswith(".s"):
                yield os.path.join(dp, fn)


def harvest():
    sites = []
    for path in walk_sources():
        try:
            src = open(path, encoding="latin-1").read()
        except OSError:
            continue
        for ln, line in enumerate(src.split("\n"), 1):
            m = LINE.match(line)
            if not m:
                continue
            mn = m.group(1)
            if mn not in FAMILIES:
                continue
            ops = split_ops(m.group(2))
            sites.append((os.path.relpath(path, ROOT), ln, mn, ops,
                          line.strip()))
    return sites


def toolchain():
    r = subprocess.run(["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
                        "log", "-1", "--format=%h"], capture_output=True, text=True)
    return r.stdout.strip() or "?"


def census():
    sites = harvest()
    print("llvm-mc          : %s" % MC)
    print("toolchain commit : tlcs900_backend@%s" % toolchain())
    print("raw-byte sites in the families this script models: %d" % len(sites))

    old_lines, new_lines, meta = [], [], []
    skipped = collections.Counter()
    for rel, ln, mn, ops, raw in sites:
        nat, why = native_for(mn, ops)
        if nat is None:
            skipped[(mn, why)] += 1
            continue
        old_lines.append("%s %s" % (mn, ", ".join(ops)))
        new_lines.append(nat)
        meta.append((rel, ln, mn, raw, nat))

    old_b = assemble(old_lines)
    new_b = assemble(new_lines)

    same = collections.Counter()
    differ, refused = [], []
    for i, (rel, ln, mn, raw, nat) in enumerate(meta):
        o, n = old_b[i], new_b[i]
        if o is None:
            refused.append((rel, ln, "old-refused", raw, nat))
        elif n is None:
            refused.append((rel, ln, "new-refused", raw, nat))
        elif o == n:
            same[mn] += 1
        else:
            differ.append((rel, ln, raw, nat, o, n))

    print("\nRENAMEABLE (both spellings assemble, bytes identical):")
    for mn, c in same.most_common():
        print("  %-10s %6d" % (mn, c))
    print("  %-10s %6d" % ("TOTAL", sum(same.values())))

    print("\nNOT register-indexed / not rewritten by this script:")
    for (mn, why), c in sorted(skipped.items(), key=lambda kv: -kv[1]):
        print("  %-10s %-32s %6d" % (mn, why, c))
    print("  %-10s %-32s %6d" % ("TOTAL", "", sum(skipped.values())))

    print("\nREFUSED by llvm-mc: %d" % len(refused))
    for r in refused[:20]:
        print("   %s:%d %s | %s | %s" % r)
    print("\n⚠ BYTES DIFFER (a defect, never counted as progress): %d" % len(differ))
    for r in differ[:20]:
        print("   %s:%d\n     old %s -> %s\n     new %s -> %s" % r)
    return 1 if differ else 0


def selftest():
    """A verdict rule tested on SYNTHETIC input, so that fixing the tree cannot
    break the test and a green run cannot be vacuous."""
    ok = True
    cases = [
        # (mode, base byte, index byte, expected operand text)
        (0x07, 0xE4, 0xE0, "(xbc+wa)"),
        (0x07, 0xF0, 0xF8, "(xix+iz)"),   # TOOLCHAIN_VERSION UPDATE 8's example
        (0x07, 0xE4, 0xE2, "(xbc+qwa)"),  # previous-bank index
        (0x03, 0xE4, 0xE1, "(xbc+w)"),    # 8-bit index, high half at +1
        (0x03, 0xE4, 0xE0, "(xbc+a)"),    # 8-bit index, low half at +0
        (0x07, 0xE1, 0xE0, None),         # base is not a 32-bit file address
        (0x07, 0xE4, 0xE3, None),         # +3 is not a register
        (0x03, 0xE4, 0xF0, None),         # XIX has no byte halves
    ]
    for mode, b1, b2, want in cases:
        got = memrr(mode, b1, b2)
        if got != want:
            print("FAIL memrr(%#x,%#x,%#x) = %r want %r" % (mode, b1, b2, got, want))
            ok = False
    # the rewrite rule itself
    rw = [
        ("lda_dri", ["XDE", "0x07", "0xE4", "0xE0"], "lda xde, (xbc+wa)"),
        ("ldb_sri", ["L", "0x07", "0xE8", "0xE4"], "ld l, (xde+bc)"),
        ("stl_dri", ["XWA", "0x07", "0xE8", "0xE4"], "ld (xde+bc), xwa"),
        ("jp_ind", ["8", "0x07", "0xF0", "0xE4"], "jp t, (xix+bc)"),
        ("lda_dri", ["XWA", "0xFD", "0x14", "0x01"], None),  # d16, not R+R
    ]
    for mn, ops, want in rw:
        got, _ = native_for(mn, ops)
        if got != want:
            print("FAIL native_for(%s,%s) = %r want %r" % (mn, ops, got, want))
            ok = False
    # and that llvm-mc agrees the pair is byte-identical, plus a FOIL that must
    # differ -- a check that has only ever passed is not evidence.
    pairs = [("lda_dri XDE, 0x07, 0xE4, 0xE0", "lda xde, (xbc+wa)", True),
             ("lda_dri XDE, 0x07, 0xE4, 0xE0", "lda xde, (xbc+bc)", False)]
    enc = assemble([p for pr in pairs for p in pr[:2]])
    for i, (a, b, want_same) in enumerate(pairs):
        same = enc[2 * i] is not None and enc[2 * i] == enc[2 * i + 1]
        if same != want_same:
            print("FAIL foil: %r vs %r -> same=%s want %s (%s / %s)"
                  % (a, b, same, want_same, enc[2 * i], enc[2 * i + 1]))
            ok = False
    print("selftest:", "PASS" if ok else "FAIL")
    return 0 if ok else 1




# --- REAL ROM SITES --------------------------------------------------------
# Which committed dump does a source tree build?  A site is only evidence if
# the bytes are actually IN the image the source belongs to.
IMAGES = [
    ("v7/maincpu",   "original_ROMs/kn5000_v7_program.rom"),
    ("v9/maincpu",   "original_ROMs/kn5000_v9_program.rom"),
    ("v10/maincpu",  "original_ROMs/kn5000_v10_program.rom"),
    ("v142/subcpu",  "original_ROMs/kn5000_subprogram_v142.rom"),
    ("subcpu/boot",  "original_ROMs/kn5000_subcpu_boot.ic30"),
    ("hdae5000",     "original_ROMs/hd-ae5000_v2_06i.ic4"),
    ("table_data",   "original_ROMs/kn5000_table_data.rom"),
    ("wsa1/prom_a",  "wsa1/original_ROMs/wsa1_prom_a.ic12"),
    ("wsa1/prom_b",  "wsa1/original_ROMs/wsa1_prom_b.ic13"),
    ("wsa1/prom_c",  "wsa1/original_ROMs/wsa1_prom_c.ic28"),
    ("wsa1/prom_d",  "wsa1/original_ROMs/wsa1_prom_d.bin"),
]


def image_for(rel):
    for prefix, rom in IMAGES:
        if rel.startswith(prefix):
            return prefix, rom
    return None, None


def find_offsets(blob, want, limit=4):
    offs, i = [], 0
    while len(offs) < limit:
        i = blob.find(want, i)
        if i < 0:
            break
        offs.append(i)
        i += 1
    return offs


def sites():
    """For every renameable site, locate its bytes in the image its source
    builds, so a lit test can cite a real address rather than a plausible one.

    ⚠ A byte-pattern search alone would prove nothing -- the same five bytes
    can sit inside a table.  What makes each row evidence is the SOURCE line:
    the tree already frames those bytes as this instruction, at that file and
    line, and the gate rebuilds the image from it.  The offset is where the
    bytes are; the source line is why they are code.
    """
    rows = []
    blobs = {}
    for rel, ln, mn, ops, raw in harvest():
        nat, why = native_for(mn, ops)
        if nat is None:
            continue
        prefix, rom = image_for(rel)
        if rom is None:
            continue
        if rom not in blobs:
            path = os.path.join(ROOT, rom)
            blobs[rom] = open(path, "rb").read() if os.path.exists(path) else b""
        rows.append((rel, ln, mn, nat, prefix, rom))
    encs = assemble(["%s %s" % (r[2], "") for r in rows]) if False else None
    # assemble the NATIVE spelling (the one the lit test will carry)
    encs = assemble([r[3] for r in rows])
    seen = set()
    out = []
    for (rel, ln, mn, nat, prefix, rom), enc in zip(rows, encs):
        if enc is None:
            continue
        byts = bytes(int(x, 16) for x in enc.split(","))
        key = (rom, byts)
        if key in seen:
            continue
        seen.add(key)
        offs = find_offsets(blobs[rom], byts)
        if not offs:
            continue
        out.append((prefix, rom, offs[0], len(offs), byts.hex(), nat, rel, ln))
    out.sort()
    print("%-14s %-44s %-9s %-5s %-13s %s" %
          ("tree", "image", "offset", "hits", "bytes", "spelling"))
    for prefix, rom, off, n, hexs, nat, rel, ln in out:
        print("%-14s %-44s 0x%07X %-5d %-13s %-26s %s:%d" %
              (prefix, os.path.basename(rom), off, n, hexs, nat, rel, ln))
    print("\n%d distinct (image, byte string) sites" % len(out))
    return 0




# --- the lit test ----------------------------------------------------------
UNI_NAME = {"ld": "ld", "lda": "lda", "jp": "jp", "call": "call"}


def unidasm_text(byts):
    if not os.path.exists(UNIDASM):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(byts)
        path = f.name
    try:
        r = subprocess.run([UNIDASM, path, "-arch", "tlcs900"],
                           capture_output=True, text=True)
    finally:
        os.unlink(path)
    line = (r.stdout.splitlines() or [""])[0]
    m = re.match(r"^\s*\S+:\s+(?:[0-9a-f]{2} )+\s*(.*)$", line)
    return m.group(1).strip() if m else line.strip()


def shape_key(nat):
    """One representative per (mnemonic, operand widths, index kind)."""
    mn, rest = nat.split(" ", 1)
    m = re.search(r"\((\w+)\+(\w+)\)", rest)
    base, idx = m.group(1), m.group(2)
    if idx.startswith("q"):
        kind = "q"
    elif idx in GR8_BY_BYTE.values():
        kind = "r8"
    else:
        kind = "r16"
    other = re.sub(r"\([^)]*\)", "", rest).replace(",", "").strip()
    if other in GR8_BY_BYTE.values():
        w = "b"
    elif other in GR16:
        w = "w"
    elif other in GPR32:
        w = "l"
    else:
        w = other  # a condition code
    order = "m," if rest.strip().startswith("(") else ",m"
    return (mn, w, kind, order)


def emit():
    """Write llvm/test/MC/TLCS900/reg-indexed-operand.s from REAL ROM sites.

    ⚠ unidasm is asked for its own reading of every byte string and the OPERATION
    is compared: a round trip cannot tell an ADD called SUB from an ADD.
    """
    rows = []
    blobs = {}
    for rel, ln, mn, ops, raw in harvest():
        nat, why = native_for(mn, ops)
        if nat is None:
            continue
        prefix, rom = image_for(rel)
        if rom is None:
            continue
        if rom not in blobs:
            path = os.path.join(ROOT, rom)
            blobs[rom] = open(path, "rb").read() if os.path.exists(path) else b""
        rows.append([rel, ln, nat, prefix, rom])
    encs = assemble([r[2] for r in rows])
    best = {}
    for r, enc in zip(rows, encs):
        if enc is None:
            continue
        byts = bytes(int(x, 16) for x in enc.split(","))
        offs = find_offsets(blobs[r[4]], byts, limit=64)
        if not offs:
            continue
        k = shape_key(r[2])
        cand = (len(offs), r[3], offs[0], byts, r[2], r[0], r[1])
        # prefer the rarest byte string, then spread over images
        if k not in best or cand[0] < best[k][0]:
            best[k] = cand
    print("; RUN: llvm-mc -triple=tlcs900 -show-encoding < %s | FileCheck %s")
    print("; RUN: llvm-mc -triple=tlcs900 -disassemble < %s | FileCheck %s")
    bad = 0
    for k in sorted(best):
        n, prefix, off, byts, nat, rel, ln = best[k]
        uni = unidasm_text(byts)
        mn = nat.split()[0]
        if uni and not uni.lower().startswith(UNI_NAME[mn]):
            print("; ⚠ unidasm DISAGREES: %r vs %r" % (uni, nat))
            bad += 1
        print("%-30s ; %s @0x%06X (%d hit%s)  %s:%d  unidasm: %s  ; [%s]"
              % (nat, prefix, off, n, "" if n == 1 else "s", rel, ln, uni,
                 ",".join("0x%02x" % b for b in byts)))
    print("\n; %d shapes; unidasm operation disagreements: %d" % (len(best), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--sites" in sys.argv:
        sys.exit(sites())
    if "--emit" in sys.argv:
        sys.exit(emit())
    sys.exit(census())
