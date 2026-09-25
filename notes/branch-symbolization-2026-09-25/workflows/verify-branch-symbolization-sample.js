export const meta = {
  name: 'verify-branch-symbolization-sample',
  description: 'Adversarially judge a random sample of numeric-branch sites the symbolizer would convert, per image',
  phases: [{ title: 'Judge', detail: 'one agent per image, 45 sampled sites each' }],
}
const DIR = '/tmp/claude-1000/-home-fsanches-compartilhado-kn5000-roms-disasm/53b889a2-7a91-44a2-993e-a73c39d83e0d/scratchpad/verify'
const IMAGES = ['v10','v9','v7','v142','hdae5000','prom_a','prom_b','prom_c']
const SCHEMA = {
  type: 'object',
  properties: {
    image: { type: 'string' },
    verdicts: { type: 'array', items: { type: 'object', properties: {
      site: { type: 'integer' },
      source_is: { type: 'string', enum: ['REAL_CODE', 'DATA_AS_CODE', 'UNSURE'] },
      target_ok: { type: 'string', enum: ['YES', 'NO', 'UNSURE'] },
      label_misleading: { type: 'boolean' },
      reason: { type: 'string' },
    }, required: ['site', 'source_is', 'target_ok', 'label_misleading', 'reason'] } },
    patterns: { type: 'string' },
  },
  required: ['image', 'verdicts', 'patterns'],
}
phase('Judge')
const results = await parallel(IMAGES.map(img => () => agent(
`You are an adversarial reviewer for a TLCS-900 ROM disassembly project (repo /home/fsanches/compartilhado/kn5000-roms-disasm; KN5000 maincpu trees v7/v9/v10, subcpu v142, hdae5000; SX-WSA1R trees under wsa1/prom_a, prom_b, prom_c). READ-ONLY: do not modify any file.

A tool is about to replace NUMERIC branch operands (e.g. \`jr z, 17\`, \`calr 2716\`, \`jrl nc, 0x0f00\`, \`call 16569399\`) with symbolic labels it inserts at the computed target. The numeric operand of jr/jrl/calr is a raw PC-relative displacement (target = next-instruction address + signed displacement); call/jp numbers are absolute addresses. The byte gate cannot catch one failure mode: if the SOURCE "branch" is really DATA that was mis-disassembled as instructions (data-as-code — e.g. record tables decoded as \`nop / reti / jr lt, 0 / swi 7\`, strings decoded as garbage, pointer tables decoded as instructions), then the new label would be a meaningless label planted in data or in unrelated code.

Read the sample file ${DIR}/${img}.txt. It holds 45 randomly sampled sites the tool ACCEPTED for image ${img}, each with ~12 lines of source context before the branch, and the target line's context. For EACH site decide:
- source_is: REAL_CODE if the instruction stream around the branch reads as genuine executable code (coherent register use, sensible calls, stack discipline, loops); DATA_AS_CODE if it looks like data decoded as instructions (implausible instruction mixes, mode/system instructions, runs of nop, operands that look like ASCII or table values, fragments between data labels); UNSURE otherwise. Be adversarial: when the context is suspicious, say DATA_AS_CODE and explain.
- target_ok: YES if the target line is a plausible branch destination (an instruction in real code at a sensible place: loop head, join point, error exit, subroutine entry, or the first byte of data-framed bytes that are plausibly undisassembled code); NO if it is implausible; UNSURE.
- label_misleading: true only if the proposed label NAME would actively mislead a reader (e.g. called "_Loop" but it is not a loop head, "_Return" but not a return). Structural roles: Return=target is ret; Epilogue=pops then ret; Loop=some source branch is backward; Sub=all sources are calls; Join=some source is unconditional; Skip=all sources forward conditional; Entry=target is data-framed.
You MAY look at the actual source files and ROM bytes (original_ROMs/ or wsa1/original_ROMs/) and use ../tools/unidasm (e.g. \`../tools/unidasm <rom> -arch tlcs900 -basepc <base> -skip <off> -count <n>\` — check its --help) if a site needs more context. Use \`command grep\` for recursive searches (the grep wrapper skips files with high bytes).

Return one verdict per site (site numbers 0..44), and in 'patterns' summarize any systematic failure pattern you see (e.g. a file or label family that is consistently data-as-code) with file names, so the tool's guard can be tightened.`,
  { label: `judge:${img}`, phase: 'Judge', schema: SCHEMA })))
return results.filter(Boolean)
