export const meta = {
  name: 'review-wave2-claims',
  description: 'Adversarially verify the semantic claims (headers, renames, retypes, code/data framing) the 20 merged Wave 2 lanes made; read-only, findings feed Wave 3b',
  phases: [{ title: 'Review', detail: 'one skeptic per pair of related lanes, spot-checking claims against readers, ROM bytes and unidasm' }],
}

const REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const ELF = '/home/fsanches/compartilhado/disasm-lanes/review-w2-frozen'
const SCR = '/home/fsanches/compartilhado/disasm-lanes/review-w2'
const PAIRS = args

const CLAIM = { type: 'object', properties: {
  lane: { type: 'string' }, file: { type: 'string' }, line: { type: 'integer' },
  label_or_addr: { type: 'string' }, claim: { type: 'string' },
  kind: { type: 'string', enum: ['header', 'rename', 'retype-data', 'code-from-bytes', 'reframe', 'other'] },
  why: { type: 'string', description: 'evidence: reader file:line, bytes, unidasm text' },
  fix: { type: 'string' } },
  required: ['lane', 'file', 'line', 'label_or_addr', 'claim', 'kind', 'why', 'fix'] }

const SCHEMA = { type: 'object', properties: {
  lanes: { type: 'array', items: { type: 'object', properties: {
    lane: { type: 'string' }, checked: { type: 'integer' }, confirmed: { type: 'integer' },
    false_count: { type: 'integer' }, unsupported_count: { type: 'integer' },
    sampling: { type: 'string', description: 'how the claims were chosen' } },
    required: ['lane', 'checked', 'confirmed', 'false_count', 'unsupported_count', 'sampling'] } },
  false_claims: { type: 'array', items: CLAIM },
  unsupported_claims: { type: 'array', items: CLAIM },
  patterns: { type: 'string', description: 'systematic failure patterns that likely recur beyond the sample, with how to find the rest' },
  probe_scripts: { type: 'array', items: { type: 'string' } } },
  required: ['lanes', 'false_claims', 'unsupported_claims', 'patterns', 'probe_scripts'] }

phase('Review')
const out = await parallel(PAIRS.map(p => () => agent(
`You are an ADVERSARIAL REVIEWER of two merged lanes of the KN5000 / SX-WSA1R ROM disassembly in ${REPO}. READ-ONLY: do not edit or commit anything in any repo, and do NOT run make in ${REPO} (another agent owns its build tree). Put any probe scripts under ${SCR}/${p.map(x => x.lane).join('-')}/ (TMPDIR is ~/compartilhado/tmp; never /tmp).

The lanes: ${p.map(x => `\`${x.lane}\` merged as ${x.merge}`).join(' and ')}. See each lane's changes with \`cd ${REPO} && git show --stat <merge>\` and \`git diff <merge>^1 <merge> -- <file>\`; each lane's own structured report (what it claims, its figures, its not-done list) is ${REPO}/notes/lanes/wave2-2026-09-25/lane-reports/<lane>.json.

The byte gate already proved the bytes are identical. Your job is what the gate CANNOT see: are the SEMANTIC claims TRUE? For EACH lane, check at least 15 claims (more if you find problems -- then probe the pattern), favouring the largest objects and the boldest statements:
- header comments: what the data IS, who reads it (the cited reader must exist and actually read it at that address/stride), entry counts, strides, field meanings;
- label renames: does the routine/data do what the name says?
- data retyped from instructions: is it really data (nothing calls/jumps into it; the reader treats it as data)?
- code converted from bytes / re-framed: is it reachable code on the CPU's real instruction boundaries (MAME unidasm framing from a known entry), not data decoded as instructions (look for halt/swi 7/reti/nop runs, 0xFF padding)?
Tools: symbol addresses from the FROZEN ELFs in ${ELF}/ (built at commit ${'$'}(cat ${ELF}/AT_COMMIT)): \`~/compartilhado/llvm-project/build/bin/llvm-nm ${ELF}/<image>.llvm.elf\`; ROM bytes in ${REPO}/original_ROMs/ and ${REPO}/wsa1/original_ROMs/ (check names with ls); MAME's decoder \`~/compartilhado/tools/unidasm <rom> -arch tlcs900 -basepc <base> -skip <off> -count <n>\` (bases: maincpu 0xE00000, table data 0x800000, custom data 0x300000?, HD-AE5000 0x280000, sub-CPU payload per its linker script; check each image's .ld). Find readers with \`command grep -rn\` (NEVER the bare grep wrapper: it silently skips the latin-1 .s files) by label AND by numeric address. The .s files are latin-1.
Default to skepticism: a claim whose evidence you cannot reproduce is UNSUPPORTED; a claim contradicted by code or bytes is FALSE. Give each finding a concrete fix (the corrected header text / name / framing). Report per-lane counts, every false and unsupported claim, and the systematic PATTERNS (e.g. "headers cite the caller of the caller as the reader", "stride stated from one entry") with a recipe to find the rest.`,
  { label: `review:${p.map(x => x.lane).join('+')}`, phase: 'Review', schema: SCHEMA })))
const res = out.filter(Boolean)
const tot = res.flatMap(r => r.lanes).reduce((a, l) => ({ checked: a.checked + l.checked, f: a.f + l.false_count, u: a.u + l.unsupported_count }), { checked: 0, f: 0, u: 0 })
log(`reviewed ${tot.checked} claims: ${tot.f} false, ${tot.u} unsupported (${res.length}/${PAIRS.length} reviewers returned)`)
return res