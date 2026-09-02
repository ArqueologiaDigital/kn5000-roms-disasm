#!/usr/bin/env python3
"""refilter_decoder_form_hits.py -- strip the false positives out of the
broad census of decoder-fixed-form sites.

QUESTION ANSWERED
  census_decoder_fixed_forms.py casts a deliberately wide net over byte
  patterns. This re-checks each raw hit against a strict filter and reports
  what survives.

★ THE FALSE POSITIVE IS THE POINT, AND IT IS INSTRUCTIVE.
  The dst-mem-store form only counts when it is `ldw` with a MEMORY
  destination -- `ldw (...)`. The dominant false positive is `ldw reg, imm`,
  an unrelated and long-supported encoding that merely SHARES THE MNEMONIC
  NAME. So `.byte 0x30, 0x00, 0xff` decodes as `ldw wa, 65280`: a perfectly
  plausible instruction, from three bytes of an ordinary data record.

  That is this tree's recurring trap in miniature -- a decode that looks
  right, from bytes that are not code -- and it is why a mnemonic-name match
  can never be the acceptance test. The ALU da16 family is kept as
  originally matched; its coincidental hits are far rarer.

RUN
  python3 scripts/analysis/refilter_decoder_form_hits.py

⚠ Surviving the strict filter still makes a site a CANDIDATE, not a
  confirmed instruction. Corroborate before converting: the byte gate
  cannot catch data framed as code, because re-assembling a wrong
  interpretation reproduces the same bytes.
"""
import re, sys, os
sys.path.insert(0, os.path.expanduser('~/compartilhado/disasm-lanes/subcpudsp/scripts/lanes'))
import convert_lane_sub_byte_code as m

ALU_DA16 = re.compile(r'\b(addda16|subda16|andda16|xorda16|orda16|cpda16)(_24)?\b')
LDW_MEM_STORE = re.compile(r'\bldw\s+\(')

LINE_RE = re.compile(r'^(\S+):(\d+)-(\d+)\s+(\d+) bytes\s+label~=(\S+)$')

def main(hits_file):
    kept = []
    dropped = []
    for line in open(hits_file):
        mm = LINE_RE.match(line.strip())
        if not mm:
            continue
        path, s, e, n, label = mm.group(1), int(mm.group(2)), int(mm.group(3)), int(mm.group(4)), mm.group(5)
        lines = open(path, encoding='latin-1').readlines()
        blocks = m.find_blocks(lines)
        # find the block matching this start line
        target = None
        for b in blocks:
            if b['start']+1 == s and b['end']+1 == e:
                target = b
                break
        if target is None:
            dropped.append((path, s, e, n, label, 'BLOCK NOT FOUND (file changed?)'))
            continue
        insns, warnings = m.disasm(target['bytes'])
        if warnings or not insns:
            dropped.append((path, s, e, n, label, 'no longer decodes cleanly'))
            continue
        rt = m.roundtrip_bytes(insns)
        if rt != bytes(target['bytes']):
            dropped.append((path, s, e, n, label, 'no longer round-trips'))
            continue
        text = '\n'.join(insns)
        alu_hit = ALU_DA16.search(text)
        ldw_hit = LDW_MEM_STORE.search(text)
        if alu_hit or ldw_hit:
            kept.append((path, s, e, n, label, text))
        else:
            dropped.append((path, s, e, n, label, f'coincidental ldw-reg match only: {text!r}'))
    print(f"KEPT (genuinely matches one of the two fixed forms): {len(kept)} sites, {sum(k[3] for k in kept)} bytes")
    for k in kept:
        print(f"  {k[0]}:{k[1]}-{k[2]}  {k[3]}B  label~={k[4]}")
        print(f"    {k[5]!r}")
    print(f"\nDROPPED (false positive on broad filter): {len(dropped)} sites, {sum(d[3] for d in dropped)} bytes")

if __name__ == '__main__':
    main(sys.argv[1])
