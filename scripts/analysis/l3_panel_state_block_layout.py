#!/usr/bin/env python3
"""What is the layout of the 26-byte panel-state block?

The NAKA query handlers read state through a table at `0x00EE1160` holding 23
pointers at stride 0x1A into work RAM `0x00F9B6..0x00FBF2` -- the `.LSW` panel
memory (see notes/FINDINGS-naka-record-format.md).

RAM contents cannot be read from a ROM dump. But the ROM carries the FACTORY
DEFAULT panel image at `0x00EDB3DC` (it begins `5A 5A 00 00 48 4B`, and
docs/kn-disk-file-formats.md records that this image satisfies the `.LSW`
loader's own signature check -- the live panel area IS a `.LSW`). That image is
the initial content of `0xF980` onward, so block N is at

    0x00EDB3DC + (0xF9B6 - 0xF980) + 26*N

Stacking the 23 blocks and classifying each byte position gives the layout.

⚠ WHAT THIS IS EVIDENCE OF. These are DEFAULT values. A position constant across
all 23 blocks is constant AT THE FACTORY DEFAULT; it may still be written at
runtime. So CONST here means "not used to distinguish parts in the default
image", which is weaker than "never varies". Positions that already vary in the
defaults are certainly per-part fields.

⚠ CONTROL: the same classifier over 23 randomly-placed 26-byte windows from the
same factory image. If the layout is real, the true framing yields far more
constant positions than arbitrary framing does.

Run:  python3 scripts/analysis/l3_panel_state_block_layout.py
"""
import collections, random, sys

ROM = "original_ROMs/kn5000_v7_program.rom"
BASE = 0xE00000
IMG = 0x00EDB3DC          # factory default panel image
DRAM_BASE = 0xF980        # what the image maps to
BLOCK0 = 0xF9B6           # first state block
STRIDE = 26
N = 23


def classify(blocks):
    out = []
    for off in range(STRIDE):
        vals = collections.Counter(b[off] for b in blocks)
        if len(vals) == 1:
            out.append((off, "CONST", f"0x{blocks[0][off]:02X}"))
        elif len(vals) <= 3:
            out.append((off, "FLAG",
                        " ".join(f"0x{v:02X}x{c}" for v, c in vals.most_common(3))))
        else:
            seq = [b[off] for b in blocks]
            if seq == list(range(seq[0], seq[0] + len(seq))):
                out.append((off, "INDEX", f"runs {seq[0]}..{seq[-1]} step 1"))
            else:
                out.append((off, "VARY", f"{len(vals)} values"))
    return out


def main():
    rom = open(ROM, "rb").read()
    o = IMG - BASE
    if rom[o:o + 6].hex(" ") != "5a 5a 00 00 48 4b":
        sys.exit("factory image signature not found -- refusing to guess")
    d = BLOCK0 - DRAM_BASE
    blocks = [rom[o + d + STRIDE * i: o + d + STRIDE * (i + 1)] for i in range(N)]
    rows = classify(blocks)

    print(f"  {N} blocks of {STRIDE} B from the factory image at 0x{IMG:06X}+0x{d:02X}")
    print()
    for off, kind, desc in rows:
        print(f"    +0x{off:02X}  {kind:5}  {desc}")

    rng = random.Random(23)
    ctrl = [rom[(s := rng.randrange(o, o + 0xE00 - STRIDE)):s + STRIDE] for _ in range(N)]
    cr = classify(ctrl)
    nc = sum(1 for _o, k, _d in rows if k == "CONST")
    ncc = sum(1 for _o, k, _d in cr if k == "CONST")
    print()
    print(f"  CONST positions, true framing        : {nc}/{STRIDE}")
    print(f"  CONST positions, random 26 B windows : {ncc}/{STRIDE}"
          + ("   <-- discriminates" if ncc < nc * 0.6 else
             "   <-- DOES NOT discriminate"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
