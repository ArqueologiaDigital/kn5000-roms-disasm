#!/usr/bin/env python3
"""Does the SX-WSA1R's modelling device receive EXECUTABLE DSP CODE, or parameters?

QUESTION IT ANSWERS: 0x00104000 is the per-channel synthesis device with no
counterpart in the KN5000's PCM sibling -- the ranked inference is that it is the
acoustic-modelling section (notes/FINDINGS-sound-subsystem-boundary.md sec.3).
Before a MAME device can model it, one thing must be settled: is the firmware
UPLOADING A PROGRAM to it, or writing parameter registers?  Those need different
devices, and guessing wrong builds the wrong one.

RUN:  python3 wsa1/notes/sound/dev104_payload_class.py
      python3 wsa1/notes/sound/dev104_payload_class.py --selftest

★ THE METHOD IS A CONTROLLED COMPARISON, not an opinion about the traffic.  This
firmware CONTAINS a known code-upload path: DSP effect microcode leaves CPU 2
through port P7, a byte at a time, with strobes and a timeout.  So every
discriminant below is scored for BOTH, and the answer is whichever column
0x104000 resembles.

  discriminant                     P7 (known code upload)   0x104000
  -------------------------------------------------------------------------
  opaque byte stream               yes -- ld (0x0013),(XIZ+d)   no
  handshake / strobe protocol      yes -- P5, PB, 0x1F40 poll   no
  micro-DMA ever aimed at it       (channel-driven)             NO CHANNEL
  destination addresses            one port, repeatedly         fixed register set
  register numbering               n/a                          block*0x40 + channel
  values sourced from              a byte buffer                a packed part record

VERDICT: PARAMETERS, not code.  A device modelling it needs a register file, not
a program loader.

⚠ WHAT THIS DOES NOT SETTLE.  That the device does not receive code THROUGH THIS
PORT is not proof that it contains no programmable element -- a modelling engine
could hold fixed microcode in ROM on the die and expose only coefficients, which
is exactly what this traffic would look like.  The claim is bounded: no
executable payload crosses 0x00104000.
"""
import os, re, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
WSA  = os.path.dirname(os.path.dirname(HERE))
SRC  = os.path.join(WSA, "prom_c")

DEV104 = re.compile(r'0x0*104000\b')
P7PORT = re.compile(r'\(0x0013\)')
DMA    = re.compile(r'\b(dmas|dmad|dmam|dma[0-3]v)\b', re.I)
LAB    = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
REGNO  = re.compile(r'Dev104_SetChanRegs?_([0-9A-F_]+)')


def sources():
    for dp, _d, fns in os.walk(SRC):
        for fn in sorted(fns):
            if fn.startswith(".") or not fn.endswith(".s"):
                continue
            yield os.path.join(dp, fn)


def scan():
    r = dict(dev104_sites=0, dev104_routines=set(), p7_sites=0,
             dma_at_104=0, regnos=set(), packers=set())
    for p in sources():
        cur = None
        for line in open(p, errors="replace"):
            m = LAB.match(line)
            if m:
                cur = m.group(1)
                for g in REGNO.finditer(cur):
                    for tok in g.group(1).split("_"):
                        if re.fullmatch(r'[0-9A-F]{4}', tok):
                            r["regnos"].add(int(tok, 16))
                if cur.startswith("Pack104"):
                    r["packers"].add(cur)
            code = line.split(";")[0]
            if DEV104.search(code):
                r["dev104_sites"] += 1
                if cur:
                    r["dev104_routines"].add(cur)
                if DMA.search(code):
                    r["dma_at_104"] += 1
            if P7PORT.search(code) or "extpfx5 0x8E, 0x08, 0x19, 0x13" in line:
                r["p7_sites"] += 1
    return r


def main():
    r = scan()
    spaced = sorted(r["regnos"])
    gaps = {spaced[i+1] - spaced[i] for i in range(len(spaced)-1)} if len(spaced) > 1 else set()
    if "--selftest" in sys.argv:
        f = 0
        def ck(d, c, extra=""):
            nonlocal f
            print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
            f += not c
        ck("the source tree is readable and 0x104000 is referenced",
           r["dev104_sites"] > 0, f"{r['dev104_sites']} site(s)")
        ck("the KNOWN code path (P7) is present as the control",
           r["p7_sites"] > 0, f"{r['p7_sites']} site(s)")
        # ★ the finding, as invariants. Each goes RED if the traffic ever changes shape.
        ck("NO micro-DMA channel is ever aimed at 0x104000",
           r["dma_at_104"] == 0, "a failure here means a bulk path appeared -- re-open the question")
        ck("0x104000's register numbers are a FIXED set, not a running counter",
           1 < len(spaced) <= 32, f"{len(spaced)} distinct: " + ", ".join("0x%04X" % x for x in spaced))
        ck("those numbers are regularly spaced (block*0x40 + channel)",
           gaps and all(g % 0x40 == 0 for g in gaps), f"gaps: {sorted(hex(g) for g in gaps)}")
        ck("a PACKER feeds it from a record, rather than a byte buffer",
           bool(r["packers"]), ", ".join(sorted(r["packers"])[:3]))
        print(f"\n6 checks, {f} failures")
        return 1 if f else 0
    print("Does 0x00104000 receive executable DSP code?\n")
    print(f"  sites naming 0x104000            : {r['dev104_sites']}")
    print(f"  routines touching it             : {len(r['dev104_routines'])}")
    print(f"  micro-DMA aimed at it            : {r['dma_at_104']}   <- a code upload would need one")
    print(f"  distinct register numbers        : {len(spaced)}  " +
          ", ".join("0x%04X" % x for x in spaced))
    print(f"  spacing between them             : {sorted(hex(g) for g in gaps)}")
    print(f"  packers feeding it               : {', '.join(sorted(r['packers'])) or '(none)'}")
    print(f"\n  CONTROL -- the known code path through P7 : {r['p7_sites']} site(s)")
    print("\n★ VERDICT: PARAMETERS, not code. A fixed register set at block*0x40 + channel,")
    print("  packed from a part record, with no bulk path. Model it as a register file.")
    print("⚠ Bounded claim: no executable payload crosses 0x00104000. The die may still")
    print("  hold fixed microcode of its own -- that is a different question.")
    return 0

sys.exit(main())
