#!/usr/bin/env python3
"""What is inside the 0xFC40F4-region .incbin span (prom_a 0xFC4000-0xFC52F7)?

QUESTION IT ANSWERS
  This span (4,856 bytes) sits between two already-established modules --
  0xFC3000-0xFC3FFF (verified uniform 0x0E .fill) and the 0xFC5400 message
  module of notes/FINDINGS-prom_a-message-module.md -- and reachability.py
  reports ZERO bytes of it reached by any known control-flow edge. This
  script answers "is it at least DATA of a known kind" the same way the
  0xFA15CC span's header does: a plain ASCII-string scan, nothing more.

  notes/FINDINGS-prom_a-for-the-mame-driver.md already names this location
  in one line ("DSP EFFECT / SOUND EDIT at 0xFC40F4") without mapping it;
  this script is the byte-level confirmation of that claim, so the source
  header can cite something committed instead of repeating the prose.

RUN
  python3 notes/prom_a_fc40f4_strings_scan.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()

BASE = 0xF80000
LO, HI = 0x044000, 0x0452F8   # file offsets; addresses 0xFC4000-0xFC52F7


def main():
    seg = ROM[LO:HI]
    strings = list(re.finditer(rb"[\x20-\x7e]{4,}", seg))
    total_string_bytes = sum(m.end() - m.start() for m in strings)
    print(f"span 0x{BASE+LO:06X}-0x{BASE+HI-1:06X}: {HI-LO} bytes, "
          f"{len(strings)} printable-ASCII runs of >=4 chars, "
          f"{total_string_bytes} bytes ({100*total_string_bytes//(HI-LO)}%)")
    print()
    print("first 20:")
    for m in strings[:20]:
        addr = BASE + LO + m.start()
        print(f"  0x{addr:06X}  {m.group()!r}")
    # The recognisable DSP-effect parameter vocabulary, checked as a set membership
    # test rather than eyeballed -- this is the claim the header cites.
    vocab = {b"DEPTH", b"SPEED", b"DETUNE", b"DELAY", b"BALANCE", b"WAVE",
             b"REVERB", b"TYPE", b"INTENSITY", b"KEY SHIFT", b"DIGITAL EFFECT",
             b"SOUND EDIT"}
    hits = sorted({m.group() for m in strings} & vocab, key=lambda b: b)
    print()
    print(f"DSP-effect-parameter vocabulary hits: {len(hits)}/{len(vocab)}")
    for h in hits:
        print("  ", h)
    ok = len(hits) >= 8   # a loose but checkable bar: most of the vocabulary present
    print("\nRESULT:", "PASS (reads as a DSP-effect/sound-edit parameter-label table)"
          if ok else "FAIL (vocabulary not found -- revise the header's claim)")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
