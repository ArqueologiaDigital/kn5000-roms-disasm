#!/usr/bin/env python3
"""How much STRUCTURE is hiding INSIDE blobs that whole-file triage calls OPAQUE?

THE BLIND SPOT
--------------
`l3_slice_structure_triage.py` classifies each blob as a whole. That works for a
small blob that is entirely one thing, and fails silently for a large one that is
mostly opaque with structured regions inside it -- the statistics of the majority
drown the minority.

The case that exposed it: `naka_widget_descriptors.bin` (150,888 B, class OPAQUE,
counted as "earns no better format"). Its own header comment documents four
tables inside it, and one is `DspEffectName_PtrTable`, 128 x u32 of which
128/128 land in the ROM address range. 512 bytes of pointer table cannot move
the statistics of a 150 KB file, so the audit passed it while the answer was
written in the comment directly above the `.incbin`.

WHAT THIS DOES: slides a window over every blob and classifies each window, then
reports contiguous structured regions. A region is reported only if it is large
enough to be worth expressing and its class survives the shuffle control.

⚠ CONTROL: each candidate region is re-scored after shuffling ITS OWN bytes.
Shuffling preserves the byte histogram and destroys order, so a classifier
keying on frequency alone scores the shuffled copy the same and is exposed.
PTR_TABLE and ASCII both key on order and both collapse under shuffling.

⚠ LOWER BOUND, and knowably so: windows are aligned to WIN, so a structured
region that does not start on a WIN boundary is split across windows that are
each part-structure, part-something-else, and may classify as neither. The
`DspEffectName_PtrTable` that motivated this scan sits at blob offset 0x1c1a and
is NOT counted below for exactly that reason -- the scan that found the blind
spot has a smaller version of the same blind spot. Re-running at several window
offsets would tighten it.

⚠ This finds regions worth a HUMAN look. It does not prove a region's meaning,
and a reported region is not automatically convertible -- see the naka case,
where the bytes are `.incbin`'d as one unit that other modules index into.

Run:  python3 scripts/analysis/l3_embedded_structure_scan.py [--min-bytes N]
"""
import argparse, importlib.util, os, pathlib, random, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
WIN = 256
ROM_LO, ROM_HI = 0xE00000, 0x1000000


def win_class(b):
    """Classify one window. Returns 'PTR_TABLE', 'ASCII' or None."""
    n = len(b)
    if n < 64:
        return None
    words = [struct.unpack("<I", b[i:i + 4])[0] for i in range(0, n - 3, 4)]
    if words:
        hits = sum(1 for w in words if ROM_LO <= w < ROM_HI)
        if hits >= 0.75 * len(words):
            return "PTR_TABLE"
    printable = sum(1 for c in b if 0x20 <= c < 0x7F)
    if printable >= 0.90 * n:
        # Require actual word-like runs, not just bytes in range: shuffled pixel
        # data is 99% "printable" too (that is how the TEXT class fooled itself).
        runs = 0; cur = 0
        for c in b:
            if 0x41 <= (c & 0xDF) <= 0x5A or 0x30 <= c <= 0x39:
                cur += 1
                if cur == 3:
                    runs += 1
            else:
                cur = 0
        if runs >= n // 32:
            return "ASCII"
    return None


def scan(b):
    """Return [(start, end, kind)] of contiguous same-class windows."""
    out, cur, start = [], None, 0
    for off in range(0, len(b) - WIN + 1, WIN):
        k = win_class(b[off:off + WIN])
        if k != cur:
            if cur is not None:
                out.append((start, off, cur))
            cur, start = k, off
    if cur is not None:
        out.append((start, len(b) - (len(b) % WIN), cur))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-bytes", type=int, default=256)
    ap.add_argument("--top", type=int, default=30)
    a = ap.parse_args()

    tri = REPO / "scripts/analysis/l3_slice_structure_triage.py"
    spec = importlib.util.spec_from_file_location("_triage", tri)
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

    found, tot_bytes, n_opaque = [], 0, 0
    by_kind = {}
    for f in mod.blobs():
        b = open(f, "rb").read()
        if len(b) < WIN:
            continue
        k, _ = mod.classify(b)
        if k != "OPAQUE":
            continue
        n_opaque += 1
        for s, e, kind in scan(b):
            if e - s < a.min_bytes:
                continue
            reg = b[s:e]
            sh = bytearray(reg); random.Random(7).shuffle(sh)
            ctrl = [x for x in scan(bytes(sh)) if x[2] == kind]
            if sum(y - x for x, y, _ in ctrl) > 0.25 * len(reg):
                continue                      # survives shuffling => artefact
            found.append((e - s, kind, str(f.relative_to(REPO)), s, e))
            tot_bytes += e - s
            by_kind[kind] = by_kind.get(kind, 0) + (e - s)

    print(f"  OPAQUE blobs scanned                       : {n_opaque}")
    print(f"  window                                     : {WIN} B")
    print(f"  embedded structured regions (control-clean): {len(found)}")
    print(f"  bytes inside them                          : {tot_bytes:,}")
    for k, v in sorted(by_kind.items()):
        print(f"      {k:10} {v:9,} B")
    print()
    print(f"  {'bytes':>8} {'kind':10} region                       file")
    for n, kind, f, s, e in sorted(found, reverse=True)[:a.top]:
        print(f"  {n:8,} {kind:10} 0x{s:06x}-0x{e:06x}  {f}")
    if not found:
        print("  none -- whole-file triage was not hiding anything at this window size")
    return 0


if __name__ == "__main__":
    sys.exit(main())
