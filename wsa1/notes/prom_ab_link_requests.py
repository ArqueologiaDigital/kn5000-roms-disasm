#!/usr/bin/env python3
"""Pair every CPU 1 link request builder with the CPU 2 (prom_c) server arm that answers it.

QUESTION IT ANSWERS
  CPU 1 (prom_a / prom_b) asks CPU 2 things by sending a 6-byte link packet through T_Link_SendBlockIn32ByteChunks:
      +0 server byte 0x80..0x8F   +1 part   +2 opcode / record offset   +3 count / arg   +4 reply channel   +5 arg
  prom_c's ToneMsg_Dispatch (prom_c/tone_db/tone_db_module.s) reads +0: bits 0-2 pick the arm and bit 3 the family
  -- clear: one of 8 QUERY arms (ToneMsg_Dispatch_JumpTable_FC27EA), set: one of 8 WRITE arms
  (ToneMsg_Dispatch_JumpTable_FC2754).  Its header says the panel-side names of the arms "live in prom_a, which this
  lane does not own", and ToneQuery_Dispatch's says what CPU 1 calls its 23 opcodes is not known.  This script lists,
  for every routine in prom_a / prom_b that stores a constant 0x80..0x8F at the packet's +0 and then sends 6 bytes:
  the server byte, the arm it reaches (by ToneMsg_Dispatch's rule), and the constant or register at +2 / +3 / +4.
  A builder counts only when, inside its own body (up to its `ret`), the send is preceded by `pushw 6`.
  It reads the sources only (both CPUs' listings); every pairing is the rule above applied to a byte the source
  stores, nothing else.

RUN
  python3 notes/prom_ab_link_requests.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUERY = {0: "ToneQuery_Dispatch", 1: "LinkQuery_ReplyPartRecordBytes", 2: "LinkQuery_ReplyElementBlockBytes_Elements01",
         3: "LinkQuery_ReplyElementBlockBytes_Elements23", 4: "LinkQuery_ReplyElementWaveSelectBytes",
         5: "LinkQuery_ReplyToneRecordBytes", 6: "query arm 6 (prom_c 0xFC2430)", 7: "query arm 7 (prom_c 0xFC24F6)"}
WRITE = {0: "ToneEdit_Dispatch", 1: "write arm 1 (prom_c 0xFBB793)", 2: "write arm 2 (prom_c 0xFBC39D, 0 / 1)",
         3: "write arm 3 (prom_c 0xFBC39D, 2 / 3)", 4: "ToneMsg_WriteWaveSelectParam", 5: "write arm 5 (prom_c 0xFBCD17)",
         6: "write arm 6 (prom_c 0xFBD46B)", 7: "write arm 7 (prom_c 0xFBD6FC)"}


def arm(server):
    return (WRITE if server & 8 else QUERY)[server & 7]


def main():
    for img in ("prom_a", "prom_b"):
        L = open(os.path.join(ROOT, img, "wsa1_%s.s" % img), "rb").read().decode("latin-1").split("\n")
        cur = None
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if m and not re.search(r'_(Skip|Join|Loop|Return|Epilogue|Nop)\d*$', m.group(1)):
                cur = m.group(1)
            c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
            mm = re.match(r'ld \((XI[XY]|xi[xy])\), ?(0x8[0-9a-f]|1[23][0-9]|14[0-3])$', c)
            if not mm:
                continue
            v = int(mm.group(2), 0)
            if not 0x80 <= v <= 0x8F:
                continue
            body = []
            for k in range(i, i + 40):              # the routine's own body: up to its ret
                b = re.sub(r'\s+', ' ', L[k].split(";")[0]).strip()
                body.append(b)
                if b == "ret":
                    break
            # a 6-byte link request: `pushw 6` (the length) right before the send
            sends = [j for j, b in enumerate(body) if "T_Link_SendBlockIn32ByteChunks" in b]
            if not any(any(re.match(r'pushw (0x06|6)$', body[j - d]) for d in (1, 2) if j - d >= 0) for j in sends):
                continue
            fld = {}
            for b in body:
                f = re.match(r'ld \((?:XI[XY]|xi[xy])\+(0x0[1-5]|[1-5])\), ?(.+)$', b)
                if f and int(f.group(1), 0) not in fld:
                    fld[int(f.group(1), 0)] = f.group(2)
            print("%-7s %-34s 0x%02X -> %-46s +2 %-6s +3 %-6s +4 %s" % (img, cur, v, arm(v), fld.get(2, "?"), fld.get(3, "?"), fld.get(4, "?")))


if __name__ == "__main__":
    main()
