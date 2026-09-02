#!/usr/bin/env python3
"""census_two_forms.py -- tree-wide search for OTHER .byte sites blocked by
the same two TLCS900 decoder bugs fixed 2026-09-02 in llvm-project commit
ad8129f59880 (see notes/llvm_roundtrip_probe.py for the bugs themselves):

  1. dst-mem-prefix immediate store, OpByte==0x02 -- mnemonic "ldw" with a
     MEMORY destination, e.g. "ldw (xsp+4), 1". Distinguished from the far
     more common "ldw reg, imm16" register-load form, which is an unrelated,
     long-supported encoding that happens to share the mnemonic name and was
     the dominant false positive in an earlier (unfiltered) pass of this
     script: e.g. `.byte 0x30, 0x00, 0xff` -- a 3-byte "PatchEntry" DATA
     record in v9/maincpu/audio/sound_data_world_perc.s -- round-trips
     cleanly as `ldw wa, 65280`, a coincidence, not evidence of either fixed
     decoder bug.
  2. the direct-address ALU family addda16/subda16/andda16/xorda16/orda16/
     cpda16 and their _24/mem-dest siblings.

METHOD (two-stage, reusing convert_lane_sub_byte_code.py's own proof):
  For every contiguous, non-uniform `.byte` run of >= 3 bytes in a given file:
    1. disassemble with llvm-mc; require a clean decode (no warnings, >=1 insn)
    2. re-assemble that text and require an EXACT byte match (round trip)
    3. only THEN check whether the decoded text names one of the two forms,
       using the memory-destination-only "ldw" pattern above.
  A block that round-trips for an unrelated reason, or that only coincidentally
  contains the "ldw" mnemonic via its OTHER (register-dest) encoding, is not
  counted. This is a precision-first filter: it will under-count sites that
  use the two forms in some spelling this regex does not anticipate, but it
  will not repeat the PatchEntry false-positive.

RUN
    python3 scripts/analysis/census_two_forms.py <file.s> [file.s ...]

RESULT, 2026-09-02 (subcpudsp lane), run against every v9/maincpu, v10/maincpu
and subcpu/boot .s file (313 files):

  An UNFILTERED first pass (grep-equivalent: round-trips AND text contains
  "ldw" anywhere, or any da16 ALU mnemonic) found 189 candidate blocks /
  1,096 B. Manually spot-checking the smallest ones (3-4 B, labelled things
  like "WorldPerc_PatchEntry_048") showed they were DATA tables that happen to
  decode as `ldw reg, imm16` -- see the PatchEntry example above. Applying the
  memory-destination filter in THIS script dropped 169 of those 189 sites
  (1,016 B) as coincidental.

  The remaining 20 hits (80 B) are 10 distinct code sites, each duplicated
  once in v9 and once in v10 (the two images share this source in lockstep --
  see README-v9v10-census.md's own note that v9/v10 "cannot corroborate each
  other" by diffing). All 10 were manually inspected in context and are
  genuine misframed CODE islands -- single mis-decoded instructions sitting
  between already-disassembled real instructions on both sides, e.g.
  bmdredit_routines.s:3972 `.byte 0xd1, 0xba, 0x27, 0x80` sits directly next
  to `stda16 10170, wa` in the same function, and decodes byte-exact as
  `addda16 xwa, (10170)` -- the same address, an ALU op instead of a store.
  This is the "misframed islands" shape README-v9v10-census.md already
  measured (~14,727 B/image, deliberately not attempted that session) --
  this script narrows which of those islands are attributable to TODAY's
  two decoder fixes specifically, rather than the >64B unsupported forms.

  Sites (v9 path; v10 has byte-identical duplicates at the same line numbers):
    v9/maincpu/ui/drawbar_panel_ui.s:1211   ldw (xbc), 1
    v9/maincpu/ui/drawbar_panel_ui.s:1225   ldw (xwa), 0
    v9/maincpu/ui/drawbar_panel_ui.s:1443   ldw (xwa), 2
    v9/maincpu/ui/ui_widget_defs.s:7913     ldw (xwa), 164
    v9/maincpu/ui/ui_widget_defs.s:7915     ldw (xwa), 196
    v9/maincpu/display/scoop_display.s:8306 cpda16 xwa, (14106)
    v9/maincpu/sequencer/sequencer_engine.s:25465  subda16 xwa, (61911)
    v9/maincpu/sequencer/sequencer_engine.s:25481  subda16 xwa, (61922)
    v9/maincpu/sequencer/bmdredit_routines.s:3960  addda16 xbc, (10192)
    v9/maincpu/sequencer/bmdredit_routines.s:3972  addda16 xwa, (10170)

  NOT converted by this lane: v9/maincpu and v10/maincpu are the V10V9 lane's
  territory, not subcpudsp's, and each of these 10 sites is a single
  instruction inside a longer run whose neighbouring bytes were already
  reframed by that lane -- converting just the flagged 4 B without touching
  the surrounding lines could shift instruction boundaries there. Left for
  that lane to apply with its own reframing tooling and gate.

  subcpu/boot/kn5000_subcpu_boot.s: 0 hits (only 7 candidate blocks / 650 B
  total in that file; none use either form).
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
