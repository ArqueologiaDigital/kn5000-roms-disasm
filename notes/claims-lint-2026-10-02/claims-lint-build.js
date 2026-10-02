export const meta = {
  name: 'claims-lint-build',
  description: 'Build scripts/analysis/claims_lint.py (mechanical checks of header claims vs ELF/ROM), then adversarially measure its precision; no commits',
  phases: [
    { title: 'Build', detail: 'consolidate the Wave 2 reviewers probes into one tree-wide instrument' },
    { title: 'Verify', detail: 'hand-check a sample of hits per check; controls; precision' },
  ],
}
const REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const SCR = '/home/fsanches/compartilhado/disasm-lanes/claims-lint'
const PROBES = '/home/fsanches/compartilhado/disasm-lanes/review-w2'

const REPORT = { type: 'object', properties: {
  script: { type: 'string' }, usage: { type: 'string' },
  checks: { type: 'array', items: { type: 'object', properties: {
    name: { type: 'string' }, question: { type: 'string' }, hits_total: { type: 'integer' },
    hits_per_image: { type: 'string' }, control: { type: 'string' } },
    required: ['name', 'question', 'hits_total', 'hits_per_image', 'control'] } },
  output_files: { type: 'array', items: { type: 'string' } }, notes: { type: 'string' } },
  required: ['script', 'usage', 'checks', 'output_files', 'notes'] }

const VERDICT = { type: 'object', properties: {
  per_check: { type: 'array', items: { type: 'object', properties: {
    name: { type: 'string' }, sampled: { type: 'integer' }, true_hits: { type: 'integer' },
    precision: { type: 'string' }, false_hit_patterns: { type: 'string' }, missed: { type: 'string' } },
    required: ['name', 'sampled', 'true_hits', 'precision', 'false_hit_patterns', 'missed'] } },
  fixes_applied: { type: 'string', description: 'changes you made to the script to remove false-hit patterns, with before/after hit counts' },
  usable: { type: 'boolean' }, notes: { type: 'string' } },
  required: ['per_check', 'fixes_applied', 'usable', 'notes'] }

const BASE = `REPO ${REPO} (KN5000 + SX-WSA1R ROM disassembly; byte-exact; .s files are LATIN-1 -- read them as bytes; use \`command grep\`, never the bare grep wrapper). Do NOT commit, and do NOT run make in ${REPO} (other agents own its build tree). Work in ${SCR}/ (TMPDIR is ~/compartilhado/tmp; never /tmp; guard every variable in any rm path as "\${VAR:?}"). Current symbols: run ~/compartilhado/llvm-project/build/bin/llvm-nm on ${REPO}/rebuilt_ROMs/*.llvm.elf and ${REPO}/wsa1/rebuilt_ROMs/*.llvm.elf (copy them to ${SCR}/elf/ first and use the copies: another agent may run make clean mid-way; if a file is missing use /home/fsanches/compartilhado/disasm-lanes/review-w2-frozen/). ROMs: ${REPO}/original_ROMs/, ${REPO}/wsa1/original_ROMs/ (check names). Image -> source-tree map: v10/maincpu, v9/maincpu, v7/maincpu, v142/subcpu, subcpu/boot, table_data, custom_data, hdae5000, wsa1/prom_a..d.`

phase('Build')
const built = await agent(`${BASE}

TASK: write ${REPO}/scripts/analysis/claims_lint.py -- a tree-wide instrument for the SEMANTIC claims in comments/headers that the byte gate cannot see. Seed material: an adversarial review of the Wave 2 lanes wrote probes under ${PROBES}/*/ (e.g. midi-sys/check_header_addrs.py, check_table_counts.py, check_unread_slices.py; accomp-audio/check_reader_addrs.py, v7_label_alignment.py). The review found these recurring defect patterns:
 1. stale names in comments after renames (whole-word seds miss abbreviated/elided names: '..._CC3_TableLookup', '_11 (0xFD00E0)');
 2. "purpose not established / no reader found" claims contradicted by LE24 pointers into the range (including from inside the same blob) or by block copies (\`ld xiy, X / ldw bc, N / ldirw\`) that run past the next label;
 3. stated entry counts ("table of N pointers", "N x u32", "N entries") that differ from the rows the source emits or from the reader's bound;
 4. header-quoted addresses ("Name (0xADDR)", "Name = 0xADDR", "Name at 0xADDR", "reader Foo (0xADDR)") that are not where the ELF puts Name -- per IMAGE (v7 addresses differ from v10);
 5. templated headers with no content (e.g. a line ending 'what that code does with it:' with nothing after it).
Implement one subcommand/check per pattern (names: stale-names, unread-claims, table-counts, header-addrs, empty-templates), over all images by default or --images LIST, writing a TSV per check (image, file, line, label, detail) to --out DIR and a summary table to stdout. Each check needs a docstring paragraph: the question it answers, the signal, what a hit means, known false-positive shapes. Include a --selftest that plants one known-bad example per check (in a temp copy, not the tree) and asserts it is caught. For stale-names, a token counts as a symbol-like name if it has an underscore and an uppercase letter (or is CamelCase with >= 2 humps) and length >= 6; it is STALE when it is not defined in ANY image's ELF symbol table nor as a label/.set/.equ anywhere in the tree nor as a C identifier in the tree -- report also whether it appears on the OLD side of scripts/renaming/*.sed / *.map (that is the strongest signal). Run it over the whole tree and report counts per check per image, and where the TSVs are.`,
  { label: 'build:claims_lint', phase: 'Build', schema: REPORT })

phase('Verify')
const verdict = built && await agent(`${BASE}

You are an ADVERSARIAL VERIFIER of a new instrument, ${REPO}/scripts/analysis/claims_lint.py. Its author reported: ${JSON.stringify(built).slice(0, 5000)}
For EACH check: draw a sample of at least 25 hits spread across images and files (fewer only if there are fewer hits), and decide by reading the source and the ELF/ROM whether each hit is a TRUE defect in the claim. Compute precision. Identify the false-hit patterns and FIX them in the script (you may edit claims_lint.py, nothing else in the repo), re-run, and report before/after counts. Also probe for misses: plant 3 realistic defects per check in a temp copy of one source file (not the tree) and confirm they are caught. Mark usable=false if any check stays below 80% precision after your fixes (and say which).`,
  { label: 'verify:claims_lint', phase: 'Verify', schema: VERDICT })

return { built, verdict }