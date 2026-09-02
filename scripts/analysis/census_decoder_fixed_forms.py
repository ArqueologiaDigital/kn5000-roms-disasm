#!/usr/bin/env python3
"""census_decoder_fixed_forms.py -- what else did today's decoder fixes unblock?

QUESTION ANSWERED
  Two TLCS900 decoder bugs were fixed on 2026-09-02 (ad8129f59880), one of
  them a SILENT MISCOMPILE. Their known cost was 569 bytes in three
  DSP_Bytecode handlers, but nobody had asked how many OTHER `.byte` sites
  across the tree are blocked by the same two forms. This searches for them.

  The two forms:
    1. dst-mem-prefix immediate store, OpByte==0x02 (mnemonic `ldw`),
       ROM shape `bf 04 02 xx xx`. Before the fix the decoder chose the
       wrong opcode, so the text it emitted re-encoded to `bf 04 14 ...`
       -- accepted, no diagnostic, WRONG BYTES.
    2. the direct-address ALU family, addda16/subda16/andda16/xorda16/
       orda16/cpda16 and their _24 and mem-dest siblings, ROM shape
       `d1 40 xx xx xx`.

RUN
  python3 scripts/analysis/census_decoder_fixed_forms.py

⚠ A BYTE-PATTERN HIT IS A CANDIDATE, NOT A SITE. These shapes occur by
  chance inside genuine data, and this tree is full of typed tables and
  erased flash. Every hit needs the region checked before conversion, and
  a clean decode still is not proof -- the byte gate cannot catch data
  framed as code, because re-assembling a wrong interpretation reproduces
  the same bytes. Corroborate with call targets landing on already-named
  routines before converting anything this reports.
"""
import re, sys, os
sys.path.insert(0, os.path.expanduser(
    '~/compartilhado/disasm-lanes/subcpudsp/scripts/lanes'))
import convert_lane_sub_byte_code as m

ALU_DA16 = re.compile(r'\b(addda16|subda16|andda16|xorda16|orda16|cpda16)(_24)?\b')
LDW_MEM_STORE = re.compile(r'\bldw\s+\(')

def scan(path):
    lines = open(path, encoding='latin-1').readlines()
    blocks = m.find_blocks(lines)
    hits = []
    for b in blocks:
        n = len(b['bytes'])
        if n < 3 or len(set(b['bytes'])) == 1:
            continue
        insns, warnings = m.disasm(b['bytes'])
        if warnings or not insns:
            continue
        rt = m.roundtrip_bytes(insns)
        if rt != bytes(b['bytes']):
            continue
        text = '\n'.join(insns)
        if ALU_DA16.search(text) or LDW_MEM_STORE.search(text):
            label = None
            for j in range(b['start']-1, max(b['start']-60,-1), -1):
                mm = m.LABEL_RE.match(lines[j])
                if mm:
                    label = mm.group(1)
                    break
            hits.append((path, b['start']+1, b['end']+1, n, label, text))
    return hits

def main():
    total_bytes = 0
    total_sites = 0
    for path in sys.argv[1:]:
        for (p, s, e, n, label, text) in scan(path):
            total_sites += 1
            total_bytes += n
            print(f"{p}:{s}-{e}  {n} bytes  label~={label}")
            for l in text.splitlines():
                print(f"    {l}")
    print(f"\nTOTAL: {total_sites} sites, {total_bytes} bytes")

if __name__ == '__main__':
    main()
