#!/usr/bin/env python3
r"""memtomem_test_sites.py -- the REAL ROM sites behind
llvm/test/MC/TLCS900/mem-to-mem.s, and the check that they are real.

QUESTION ANSWERED
-----------------
`ld (mem),(nn)` / `ld (nn),(mem)` -- a memory-to-memory move with one
register-indirect operand and one 16-bit direct address -- was the largest
remaining decoder refusal (274 of 294 samples in the v10 sub-opcode census,
notes/lanes/llvmalumem-2026-09-02.md).  It had no instruction definition, and
the tree writes those bytes as raw escapes: `ldmi16 (xwa), 36152`,
`mrdb5 0x89, 0x01, 0x19, 0x48, 0x4A`, `ldmm_srib 0x07, 0xe4, 0xe0, 0xa4, 0x28`.

⚠ `ldmi16` and `ldmw2` are also the WRONG INSTRUCTION for their bytes: MAME
unidasm reads `b0 14 38 8d` as `ld (XWA),(0x8d38)`, a memory-to-memory load,
not a store-immediate.  The store-immediate is sub-opcode 0x00 (byte) / 0x02
(word).  This script does not rename anything -- it collects the evidence that
the new definitions read those bytes the way an independent decoder does.

WHAT EACH ROW ESTABLISHES
  1. a committed source line already frames those bytes as an instruction;
  2. the bytes are present in the dump that source builds, at the offset shown;
  3. this backend's decode of them re-assembles to the same bytes;
  4. MAME unidasm agrees on the OPERATION, not merely on the length.

RUN (from the tree root)
    python3 scripts/analysis/memtomem_test_sites.py            # the sites
    python3 scripts/analysis/memtomem_test_sites.py --emit     # the lit test body
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("LLVM_MC") or os.path.join(BIN, "llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/mame/unidasm")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from regindexed_convergence import (IMAGES, image_for, find_offsets, assemble,
                                    walk_sources, toolchain)

# The raw-byte spellings that can hold a memory-to-memory move.  Which of them
# actually IS one is decided by the bytes, not by the name -- these mnemonics
# are generic prefix escapes and carry many different sub-opcodes.
ESCAPES = ("ldmi16", "ldmw2", "mrib4", "mriw4", "mrdb5", "mrdw5", "mrdw3",
           "ldmm_srib", "ldmm_sriw", "ldmm_dri", "ldmmb_dri", "ldmmw_dri")
LINE = re.compile(r"^\s*(" + "|".join(ESCAPES) + r")\s+(.*?)\s*$")
MM = re.compile(r"^(ld|ldw)\s+.*\(.*\).*\(.*\)")


def decode(byte_lists):
    """Disassemble each byte string; return the text or None."""
    out = []
    for byts in byte_lists:
        r = subprocess.run([MC, "-triple=tlcs900", "-disassemble"],
                           input=" ".join("0x%02x" % b for b in byts),
                           capture_output=True, text=True)
        txt = [l.strip() for l in r.stdout.split("\n") if l.strip()]
        out.append(re.sub(r"\s+", " ", txt[0]) if txt and "warning" not in r.stderr
                   else None)
    return out


def unidasm_text(byts):
    if not os.path.exists(UNIDASM):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(bytes(byts))
        path = f.name
    try:
        r = subprocess.run([UNIDASM, path, "-arch", "tlcs900"],
                           capture_output=True, text=True)
    finally:
        os.unlink(path)
    line = (r.stdout.splitlines() or [""])[0]
    m = re.match(r"^\s*\S+:\s+(?:[0-9a-f]{2} )+\s*(.*)$", line)
    return m.group(1).strip() if m else line.strip()


def collect():
    raw, meta = [], []
    for path in walk_sources():
        rel = os.path.relpath(path, ROOT)
        if image_for(rel)[1] is None:
            continue
        try:
            src = open(path, encoding="latin-1").read()
        except OSError:
            continue
        for ln, line in enumerate(src.split("\n"), 1):
            m = LINE.match(line)
            if not m:
                continue
            body = m.group(2).split(";")[0].split("//")[0].strip()
            raw.append("%s %s" % (m.group(1), body))
            meta.append((rel, ln))
    encs = assemble(raw)
    blobs = {}
    rows, seen = [], set()
    for (rel, ln), enc in zip(meta, encs):
        if enc is None:
            continue
        byts = bytes(int(x, 16) for x in enc.split(","))
        prefix, rom = image_for(rel)
        if rom not in blobs:
            p = os.path.join(ROOT, rom)
            blobs[rom] = open(p, "rb").read() if os.path.exists(p) else b""
        offs = find_offsets(blobs[rom], byts, limit=64)
        if not offs:
            continue
        key = (rom, byts)
        if key in seen:
            continue
        seen.add(key)
        rows.append((prefix, rom, offs[0], len(offs), byts, rel, ln))
    return rows


def main(emit=False):
    rows = collect()
    texts = decode([r[4] for r in rows])
    print("toolchain: tlcs900_backend@%s" % toolchain())
    # ⚠ RE-ASSEMBLE EVERY DECODE.  A decode that prints plausible text but does
    # not encode back to the ROM's own bytes is the failure class this project
    # keeps meeting, and it is invisible to a refusal count.
    cand = [(r, t) for r, t in zip(rows, texts) if t and MM.match(t)]
    reenc = assemble([t for _, t in cand])
    kept, bad, asym = [], 0, []
    for (r, t), enc in zip(cand, reenc):
        got = bytes(int(x, 16) for x in enc.split(",")) if enc else None
        if got != r[4]:
            asym.append((r, t, got))
            continue
        uni = unidasm_text(r[4])
        ok = uni and uni.split()[0].lower() == t.split()[0].lower()
        if not ok:
            print("⚠ unidasm DISAGREES: %r vs %r  bytes %s"
                  % (uni, t, r[4].hex()))
            bad += 1
            continue
        kept.append((r, t, uni))
    # one row per distinct instruction shape
    shapes, out = set(), []
    for r, t, uni in kept:
        k = (t.split()[0], "m," if t.split(None, 1)[1].startswith("(0x") or
             re.match(r"^\(\d", t.split(None, 1)[1]) else ",m",
             len(r[4]), r[4][0] & 0xF0)
        if k in shapes:
            continue
        shapes.add(k)
        out.append((r, t, uni))
    for (prefix, rom, off, n, byts, rel, ln), t, uni in out:
        if emit:
            print("; %s @0x%06X (%d hit%s)  %s:%d  unidasm: %s"
                  % (prefix, off, n, "" if n == 1 else "s", rel, ln, uni))
            print("; CHECK: %s ; encoding: [%s]"
                  % (t, ",".join("0x%02x" % b for b in byts)))
            print(t)
            print()
        else:
            print("%-12s 0x%06X %-2d %-16s %-30s %s:%d  unidasm: %s"
                  % (prefix, off, n, byts.hex(), t, rel, ln, uni))
    if not emit:
        print("\n%d memory-to-memory sites over %d distinct byte strings; "
              "%d shapes; unidasm operation disagreements: %d"
              % (len(kept), len(set(r[4] for r, _, _ in kept)), len(out), bad))
        if asym:
            print("\n⚠ %d decode(s) that do NOT re-assemble to the ROM's bytes "
                  "-- reported, never counted as progress:" % len(asym))
            for r, t, got in asym:
                print("   %s:%d  rom %s  ->  %r  ->  %s"
                      % (r[5], r[6], r[4].hex(), t,
                         got.hex() if got else "REFUSED"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main("--emit" in sys.argv))
