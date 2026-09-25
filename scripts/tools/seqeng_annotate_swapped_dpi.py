#!/usr/bin/env python3
r"""seqeng_annotate_swapped_dpi.py -- say what `lda_dpi` / `stb_dpi` lines really do.

⚠ OBSOLETE since TOOLCHAIN_VERSION UPDATE 17 (2026-09-25), kept as the record
of what wave 2 did.  The backend now has real post-increment syntax and the
swap is fixed (llvm-project ac3f1ed19ab6): `f5 e8 41` prints `ld (xde+), a`
and `f5 e0 31` prints `lda xbc, (xwa+:1)`.  Every line this script annotated
was respelled to that syntax by scripts/converters/wave3a_respell.py autoinc,
which also removed the annotations.  Running it now finds nothing to do.

QUESTION ANSWERED
-----------------
"Which lines in lane seqeng's files use the backend's F5-prefix (r32+) /
(-r32) mnemonics whose names are swapped, and what does each really do?"

The LLVM TLCS-900 backend prints `f5 e8 41` as `lda_dpi xbc, 232`, but the
CPU executes it as `ld (XDE+),A` (0x40+r in the destination-memory group is
LD (mem),r8); and it prints `f5 e0 31` as `stb_dpi a, 224`, which is
`lda XBC,(XWA+)` (0x30+r is LDA r32,mem).  MAME unidasm reads both correctly
(checked on synthetic bytes, notes/seqeng-2026-09-25/README.md).  The bytes
are right, so the gate cannot see it; a reader of `lda_dpi XBC, 0xe8` after
`ldb_spi A, 0xe4` sees an address computation where the code copies a byte
(`ld A,(XBC+) / ld (XDE+),A`).

There is no llvm-mc syntax for post-increment operands to rewrite them into
(`ld (xde+), a` is a parse error, and `ld (+xde), a` silently assembles an
ABSOLUTE address expression), so each line gets a trailing comment with
unidasm's decode of its own bytes.  Idempotent.

RUN
    python3 scripts/tools/seqeng_annotate_swapped_dpi.py v10 [--apply]
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
from seqeng_line_map import line_map, ROOT, IMAGES  # noqa: E402

FILES = ["sequencer/sequencer_engine.s", "sequencer/seq_event_playback.s",
         "sequencer/smf_event_processor.s", "sequencer/smf_tonegen_core.s",
         "sequencer/smf_playback.s"]
UNIDASM = os.environ.get("UNIDASM", os.path.expanduser("~/compartilhado/tools/unidasm"))
PAT = re.compile(r'^\s*(lda_dpi|stb_dpi|lda_dpd|stb_dpd)\b')
TAG = "backend mnemonic is swapped"


def unidasm(bs):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(bytes(bs))
        t = f.name
    try:
        out = subprocess.run([UNIDASM, t, "-arch", "tlcs900", "-basepc", "0"],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(t)
    lines = [l for l in out.split("\n") if l.strip()]
    m = re.match(r'^\s*0:\s+((?:[0-9a-f]{2} )+)\s*(.*)$', lines[0]) if lines else None
    return m.group(2).strip() if m and len(m.group(1).split()) == len(bs) else None


def main():
    image = sys.argv[1]
    apply = "--apply" in sys.argv
    img = IMAGES[image]
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    maps = line_map(image, FILES)
    tot = 0
    for rel in FILES:
        p = os.path.join(ROOT, image, "maincpu", rel)
        src = open(p, "rb").read().decode("latin-1").split("\n")
        by = {ln: (a, sz) for ln, a, sz in maps[rel]}
        n = 0
        for i, t in enumerate(src):
            if not PAT.match(t) or "; = " in t:
                continue
            a, sz = by[i + 1]
            u = unidasm(rom[a - img["base"]:a - img["base"] + sz])
            if not u:
                print("SKIP %s:%d unidasm did not decode %d bytes" % (rel, i + 1, sz))
                continue
            mn = PAT.match(t).group(1)
            swapped = (mn.startswith("lda") and u.split()[0].lower() == "ld") or \
                      (mn.startswith("stb") and u.split()[0].lower() == "lda")
            src[i] = t.rstrip() + ("\t; = %s (%s)" % (u.lower(), TAG) if swapped
                                   else "\t; = %s (unidasm)" % u.lower())
            n += 1
        tot += n
        if apply and n:
            open(p, "wb").write("\n".join(src).encode("latin-1"))
    print("%s: %d lines annotated" % (image, tot))


if __name__ == "__main__":
    main()
