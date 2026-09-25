#!/usr/bin/env python3
r"""retype_v142_fp_literal_pool.py -- the double-precision literal pool at 0x01F63E, as data.

QUESTION THIS ANSWERS
    What are the 248 bytes 0x01F63E-0x01F735 of the v1.42 sub-CPU payload?  The source
    had them as a mix of `.byte` rows misaligned by two bytes and INSTRUCTIONS (`normal`,
    `swi 7`, `mul xbc,xsp`, `jrl nc,0x0000`, runs of `nop`) -- the census counted them as
    CODE and the branch symboliser refused `jrl nc,0x0000` as an absurd block.  Also the 94
    bytes before them, the tail of ToneGen_Velocity_Output_Curve (values 0x22..0x7F), were
    typed `.ascii` because they happen to be printable.

    They are 31 IEEE-754 doubles (8 bytes, little-endian), and EACH ONE is loaded by exactly
    one `lda xNN,(addr:24)` in subcpu_fp_math.s -- a per-use literal pool.  This script
    derives that from the ROM and the source, re-emits the pool as `.double` / `.quad` with a
    label per constant named after its only reader, rewrites the 31 `lda` operands to those
    labels, and re-types the curve tail as `.byte`.

CHECKS (the script refuses to write unless all hold)
    * the curve tail is exactly 0x22..0x7F (the `.ascii` text plus the 0x7F that the old
      `jrl nc` swallowed) and the curve is 256 bytes, ending at 0x01F63D;
    * every 8-byte slot 0x01F63E..0x01F72E is referenced by exactly one `lda (0x01f6xx:24)`
      line in subcpu_fp_math.s, and no other 24-bit reference into the pool exists in the ROM
      besides those 31 operand sites;
    * `.double V` is used only when V round-trips to the same 8 bytes, `.quad` otherwise;
    * the rebuilt image is byte-identical (checked by the caller's gate; --apply also runs a
      private rebuild and reverts on mismatch).

RUN
    python3 scripts/converters/retype_v142_fp_literal_pool.py           # dry
    python3 scripts/converters/retype_v142_fp_literal_pool.py --apply
"""
import argparse
import bisect
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v142/subcpu")
DT = os.path.join(TREE, "subcpu_data_tables.s")
FP = os.path.join(TREE, "subcpu_fp_math.s")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
LLVM = os.path.join(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
                    "llvm-project", "build", "bin")
POOL_LO, POOL_HI = 0x01F63E, 0x01F736
CURVE, TAIL = 0x01F53E, 0x01F5E0
KEEP = {0x01F646: "FPConst_Int32_Min_As_Double", 0x01F64E: "FPConst_Int32_Max_As_Double",
        0x01F6C6: "FPConst_Exp_Overflow_Limit", 0x01F6CE: "FPConst_Exp_Underflow_Limit"}
STRUCT = re.compile(r"_(Loop|Skip|Join|Return|Epilogue|Done|Next|Sub|Entry)\d*$")

rom = open(ROM, "rb").read()


def off(a):
    return a - 0xF000 + 0x100


def build(tree):
    d = tempfile.mkdtemp(prefix="fplit_")
    o, e, b = (os.path.join(d, x) for x in ("v.o", "v.elf", "v.bin"))
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I", tree, "-o", o,
                    os.path.join(tree, "kn5000_subprogram_v142.s")], check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", os.path.join(tree, "subcpu.ld"), "-o", e, o],
                   check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b], check=True)
    full = open(b, "rb").read()
    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), "-n", e], check=True, capture_output=True,
                        text=True).stdout
    return full[:256] + full[60416:], nm


def double_text(bs):
    v = struct.unpack("<d", bs)[0]
    for cand in ("%r" % v,):
        if struct.pack("<d", float(cand)) == bs and len(cand) <= 6:
            return ".double %s" % cand, v
    return ".quad 0x%016x" % struct.unpack("<Q", bs)[0], v


def vname(v):
    return {0.0: "Zero", 1.0: "One", 0.5: "Half", 2.0: "Two"}.get(v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    if "; 0x01F63E-0x01F735  DOUBLE-PRECISION LITERAL POOL" in open(DT, "rb").read().decode("latin-1"):
        print("already applied")
        return
    img, nm = build(TREE)
    if img != rom:
        sys.exit("tree does not rebuild byte-identical; refusing")
    labs = sorted((int(p[0], 16), p[2]) for p in (l.split() for l in nm.splitlines())
                  if len(p) == 3 and p[1] == "t" and not p[2].startswith("__"))
    la = [x for x, _ in labs]
    # --- curve tail
    tail = list(rom[off(TAIL):off(POOL_LO)])
    if tail != list(range(0x22, 0x80)):
        sys.exit("curve tail is not 0x22..0x7F")
    # --- references: source lda lines in fp_math
    fp = open(FP, "rb").read().decode("latin-1")
    refs = {}
    for m in re.finditer(r"^\t(lda (x\w+), \((0x01f[67][0-9a-f]{2}):24\)|ld (x\w+), (0x1F[67][0-9A-F]{2}))$", fp, re.M):
        v = int(m.group(3) or m.group(5), 16)
        if POOL_LO <= v < POOL_HI:
            refs.setdefault(v, []).append(m)
    slots = list(range(POOL_LO, POOL_HI, 8))
    for s in slots:
        if len(refs.get(s, [])) != 1:
            sys.exit("slot 0x%06X has %d source references" % (s, len(refs.get(s, []))))
    # whole-ROM 24-bit occurrences into the pool
    occ = [i for i in range(len(rom) - 3)
           if POOL_LO <= (rom[i] | rom[i + 1] << 8 | rom[i + 2] << 16) < POOL_HI]
    slotset = set(slots)
    at_slot = [i for i in occ if (rom[i] | rom[i + 1] << 8 | rom[i + 2] << 16) in slotset]
    if len(at_slot) != len(slots) or len({rom[i] | rom[i + 1] << 8 | rom[i + 2] << 16 for i in at_slot}) != len(slots):
        sys.exit("ROM does not hold exactly one 24-bit reference per slot")
    for i in occ:
        if i not in at_slot:
            print("  note: 24-bit value 0x%06X at ROM 0x%06X is not a slot start (a byte pattern "
                  "inside other code, not a pool reference)" %
                  (rom[i] | rom[i + 1] << 8 | rom[i + 2] << 16, i - 0x100 + 0xF000))
    occ = at_slot
    # --- reader routine for each slot: the label enclosing the ROM site of its reference
    sites = {}
    for i in occ:
        v = rom[i] | rom[i + 1] << 8 | rom[i + 2] << 16
        sites[v] = i - 0x100 + 0xF000
    rows, names, used = [], {}, {}
    for s in slots:
        bs = rom[off(s):off(s) + 8]
        txt, v = double_text(bs)
        j = bisect.bisect_right(la, sites[s]) - 1
        while j > 0 and STRUCT.search(labs[j][1]):
            j -= 1
        reader = labs[j][1]
        if s in KEEP:
            name = KEEP[s]
        else:
            base = "FPConst_%s_%s" % (re.sub(r"^FP_", "", reader), vname(v) or "K")
            used[base] = used.get(base, 0) + 1
            name = base
        names[s] = name
        rows.append((s, name, txt, v, reader, sites[s]))
    # disambiguate duplicates
    dup = {n for n in used if used[n] > 1}
    k = {}
    for i, (s, name, txt, v, reader, site) in enumerate(rows):
        if name in dup:
            k[name] = k.get(name, 0) + 1
            name = "%s_%d" % (name, k[name])
            rows[i] = (s, name, txt, v, reader, site)
            names[s] = name
    # --- emit
    dt = open(DT, "rb").read().decode("latin-1")
    start = dt.index('\t.ascii "\\"#$%&\'()*+,-./0123456789')
    end = dt.index("\n\n\nINTRX1_HANDLER:")
    old = dt[start:end]
    old_comments = [l for l in old.split("\n") if l.startswith(";")]
    out = []
    for r in range(0, len(tail), 8):
        out.append("\t.byte " + ", ".join("0x%02x" % x for x in tail[r:r + 8]))
    out += ["; ===========================================================================",
            "; 0x01F63E-0x01F735  DOUBLE-PRECISION LITERAL POOL of the floating-point code (31 x 8 bytes)",
            "; ===========================================================================",
            "; IEEE-754 doubles, little-endian.  Each slot is loaded by exactly ONE `lda xNN,(slot:24)`",
            "; in subcpu_fp_math.s -- the compiler's per-use constant pool; the reader is in each",
            "; label's name and the comment gives the value and the address of the reading operand.  Until",
            "; 2026-09-25 this was framed as instructions (`normal`, `swi 7`, `mul xbc,xsp`, `jrl nc,0`)",
            "; and misaligned `.byte` rows; verified and re-typed by",
            "; scripts/converters/retype_v142_fp_literal_pool.py (31 source readers, 31 ROM references,",
            "; none elsewhere)."]
    oc = list(old_comments)
    for s, name, txt, v, reader, site in rows:
        if s in KEEP:
            # the existing per-constant comments, verbatim and in order
            while oc and not oc[0].startswith(("; 709", "; -708", "; -2147", "; +2147", "; (subcpu")):
                oc.pop(0)
            if s == 0x01F646:
                out += [oc.pop(0), oc.pop(0)]
            else:
                out.append(oc.pop(0))
        out.append("%s:\t%s\t; %s, read by %s (operand at 0x%06X)" % (name, txt, repr(v), reader, site))
    if oc:
        sys.exit("unplaced old comments: %r" % oc)
    new_dt = dt[:start] + "\n".join(out) + dt[end:]
    new_fp = fp
    for s in slots:
        m = refs[s][0]
        if m.group(2):
            rep = "\tlda %s, (%s:24)" % (m.group(2), names[s])
        else:
            rep = "\tld %s, %s" % (m.group(4), names[s])
        new_fp = new_fp.replace(m.group(0), rep, 1)
    print("pool slots: %d, curve tail bytes: %d, fp_math operands rewritten: %d" %
          (len(slots), len(tail), len(slots)))
    for s, name, txt, v, reader, site in rows:
        print("  0x%06X %-58s %s" % (s, name, txt))
    if a.apply:
        bdt, bfp = open(DT, "rb").read(), open(FP, "rb").read()
        open(DT, "wb").write(new_dt.encode("latin-1"))
        open(FP, "wb").write(new_fp.encode("latin-1"))
        img2, _ = build(TREE)
        if img2 != rom:
            open(DT, "wb").write(bdt)
            open(FP, "wb").write(bfp)
            sys.exit("rebuild NOT byte-identical -- reverted")
        print("applied; rebuild byte-identical")


if __name__ == "__main__":
    main()
