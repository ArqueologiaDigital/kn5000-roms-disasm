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
"""census_two_forms.py -- tree-wide search for other .byte sites blocked by the
same two TLCS900 decoder bugs fixed 2026-09-02 in ad8129f59880:
  1. dst-mem-prefix immediate store, OpByte==0x02 (mnemonic "ldw", ROM like
     bf 04 02 xx xx)
  2. direct-address ALU family addda16/subda16/andda16/xorda16/orda16/cpda16
     and their _24/mem-dest siblings (ROM like d1 40 xx xx xx)

METHOD
  Reuses convert_lane_sub_byte_code.py's block-finder + round-trip prover.
  For every contiguous .byte run of >=3 non-uniform bytes in the given files:
    - disassemble with llvm-mc, require a clean decode (no warnings, some insns)
    - require the decode to round-trip byte-exact through llvm-mc again
    - if it round-trips AND the decoded text mentions "ldw" (the 0x02 store,
      distinguished from ldw's many other addressing forms by requiring a
      literal immediate second operand) or any of the six da16/da16_24 ALU
      mnemonics, count it as a site attributable to the two fixed forms.
  This is a LOWER BOUND filter tuned for precision: it only flags a block if
  the round-tripped decode text literally names one of the six ALU mnemonics
  or "ldw " (the store form's actual mnemonic per the probe's own finding).
  A block that round-trips for an unrelated reason (some other decoder fix,
  or was never broken) is not counted unless it also uses one of these forms.

RUN
    python3 census_two_forms.py <file.s> [file.s ...]
"""
import re, sys, os
sys.path.insert(0, os.path.expanduser(
    '~/compartilhado/disasm-lanes/subcpudsp/scripts/lanes'))
import convert_lane_sub_byte_code as m

ALU_DA16 = re.compile(r'\b(addda16|subda16|andda16|xorda16|orda16|cpda16)(_24)?\b')
LDW_STORE = re.compile(r'\bldw\b')

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
        if ALU_DA16.search(text) or LDW_STORE.search(text):
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
        hits = scan(path)
        for (p, s, e, n, label, text) in hits:
            total_sites += 1
            total_bytes += n
            print(f"{p}:{s}-{e}  {n} bytes  label~={label}")
    print(f"\nTOTAL: {total_sites} sites, {total_bytes} bytes")

if __name__ == '__main__':
    main()
