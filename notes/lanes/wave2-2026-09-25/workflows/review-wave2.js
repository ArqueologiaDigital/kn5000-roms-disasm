export const meta = {
  name: 'review-wave2-claims',
  description: 'Adversarially verify the semantic claims (headers, renames, retypes) each merged Wave 2 lane made',
  phases: [{ title: 'Review', detail: 'one skeptic per merged lane, spot-checking claims against code and ROM bytes' }],
}
// args: [{lane, merge_commit}]
const REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const SCHEMA = {
  type: 'object',
  properties: {
    lane: { type: 'string' },
    checked: { type: 'integer' },
    false_claims: { type: 'array', items: { type: 'object', properties: {
      file: { type: 'string' }, line: { type: 'integer' }, claim: { type: 'string' },
      why_false: { type: 'string' }, fix: { type: 'string' } },
      required: ['file', 'line', 'claim', 'why_false', 'fix'] } },
    unsupported_claims: { type: 'array', items: { type: 'object', properties: {
      file: { type: 'string' }, line: { type: 'integer' }, claim: { type: 'string' }, missing: { type: 'string' } },
      required: ['file', 'line', 'claim', 'missing'] } },
    notes: { type: 'string' },
  },
  required: ['lane', 'checked', 'false_claims', 'unsupported_claims', 'notes'],
}
phase('Review')
const out = await parallel(args.map(m => () => agent(
`You are an adversarial reviewer of a merged disassembly lane in ${REPO} (READ-ONLY: do not edit or commit anything).
Lane \`${m.lane}\` was merged as ${m.merge_commit}. See its changes with \`cd ${REPO} && git show --stat ${m.merge_commit}\` and \`git diff ${m.merge_commit}^1 ${m.merge_commit} -- <file>\`.
The byte gate already proved the bytes are identical; your job is what the gate cannot see: are the SEMANTIC claims true?
Pick at least 25 claims, favouring the largest objects and the boldest statements: new/changed header comments (what the data IS, its reader, stride, field meanings, entry counts), label renames (does the routine do what the name says?), data retyped from instructions (is it really data: does anything call/jump into it?), code converted from bytes (is it reachable code?).
For each, verify against the code that reads/writes it (find the reader by label or address with \`command grep -rn\`; addresses via the ELF: \`~/compartilhado/llvm-project/build/bin/llvm-nm rebuilt_ROMs/<image>.llvm.elf\`), the ROM bytes (original_ROMs/, wsa1/original_ROMs/), and MAME unidasm (../tools/unidasm <rom> -arch tlcs900 -basepc <base>). Default to skepticism: a claim with no evidence you can reproduce is UNSUPPORTED; a claim contradicted by code is FALSE.
Report false claims (with the concrete fix) and unsupported ones, plus how many you checked.`,
  { label: `review:${m.lane}`, phase: 'Review', schema: SCHEMA })))
return out.filter(Boolean)
