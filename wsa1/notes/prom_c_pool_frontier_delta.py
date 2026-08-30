#!/usr/bin/env python3
"""What did converting the 0xFCD0F7 byte-stream pool do to notes/prom_c_frontier.py?

QUESTION IT ANSWERS
  A conversion round must report the frontier before and after and say whether it fell by
  the expected amount.  For prom_c that number is now MISLEADING in a specific, checkable
  way, and this script measures the effect rather than asserting it.

  `prom_c_frontier.py` disassembles every CONVERTED span LINEARLY and reports control
  transfers that land in an unconverted span.  While 0xFCD0F7-0xFDD2AA was one `.incbin`
  the tool skipped all 65,972 of its bytes.  Now that the same bytes are `.byte`
  directives inside a converted span, unidasm decodes THE POOL'S DATA as instructions, and
  every `jr`/`jrl`/`calr` it hallucinates there becomes a from-site.

  So the count falling is only half the story: it fell because there is less unconverted
  ROM, AND the surviving from-site list is now entirely phantoms.

METHOD -- the frontier tool's OWN code, run twice
  Imports `notes/prom_c_frontier.py` and reuses its `converted_spans`, `dis` and `TARGET`
  regex, so both numbers are the tool's and not a reimplementation.  BEFORE re-adds
  0xFCD0F7-0xFDD2AA to the unconverted span list -- i.e. the state of the source at the
  end of wave 5 round 1 -- and AFTER uses the source as it stands.

  Each from-site is classified by which region it lies in:
      PHANTOM  the from-site is inside a region this tree has established as DATA -- the
               byte-stream pool, the voice/DSP table zone, the preset bank, the f64 pool
               or the touch/EQ zone.  A linear decode of data invents instructions.
      REAL     anywhere else, i.e. inside converted CODE.

RUN
    python3 notes/prom_c_pool_frontier_delta.py
"""
import importlib.util, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
spec = importlib.util.spec_from_file_location("fr", os.path.join(ROOT, "notes", "prom_c_frontier.py"))
FR = importlib.util.module_from_spec(spec); spec.loader.exec_module(FR)

BASE = 0xF80000
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
IMG = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
POOL = (0xFCD0F7 - BASE, 0xFDD2AB - BASE)

DATA_REGIONS = [("preset bank",        0xF80000, 0xF98000),
                ("f64 pool + RAM img", 0xFCB27E, 0xFCC53F),
                ("touch / EQ zone",    0xFCC53F, 0xFCD0F7),
                ("byte-stream pool",   0xFCD0F7, 0xFDD2AB),
                ("voice/DSP tables",   0xFDD2AB, 0xFDF7E0)]

def frontier(unconv):
    conv = FR.converted_spans(unconv, len(IMG))
    hits = []
    for lo, hi in conv:
        for line in FR.dis(IMG, BASE, lo, hi).splitlines():
            m = FR.TARGET.search(line.rstrip())
            if not m: continue
            try: tgt = int(m.group(2), 16)
            except ValueError: continue
            off = tgt - BASE
            if not any(a <= off < b for a, b in unconv): continue
            frm = int(line.split(":")[0], 16)
            hits.append((frm, tgt))
    return conv, hits

def report(tag, unconv):
    conv, hits = frontier(unconv)
    tgts = sorted({t for _, t in hits})
    ph = [(f, t) for f, t in hits if any(a <= f < b for _, a, b in DATA_REGIONS)]
    real = [(f, t) for f, t in hits if not any(a <= f < b for _, a, b in DATA_REGIONS)]
    print(f"{tag}: {sum(h-l for l,h in unconv)} bytes unconverted in {len(unconv)} span(s); "
          f"{len(tgts)} distinct target(s) from {len(hits)} site(s)")
    print(f"      from-sites: {len(ph)} PHANTOM (inside established data), {len(real)} REAL")
    inpool = [t for t in tgts if POOL[0] <= t - BASE < POOL[1]]
    print(f"      targets that land inside the byte-stream pool: {len(inpool)}")
    return tgts, real

def main():
    now = FR.unconverted_spans(SRC)
    before = sorted(now + [POOL])
    b_t, b_real = report("BEFORE (pool as .incbin)", before)
    a_t, a_real = report("AFTER  (pool converted) ", now)
    print()
    print(f"targets: {len(b_t)} -> {len(a_t)}")
    gone = [t for t in b_t if t not in a_t]
    new  = [t for t in a_t if t not in b_t]
    print(f"  {len(gone)} target(s) gone, {len(new)} NEW target(s) that the pool's own data-decode invented")
    for f, t in a_real: print(f"      still REAL: 0x{f:06X} -> 0x{t:06X}")
    print()
    print("READING: rank prom_c by the .incbin list, not by this tool.")

if __name__ == "__main__":
    main()
