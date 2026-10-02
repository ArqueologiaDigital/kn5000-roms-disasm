export const meta = {
  name: 'wave3a-v1-resume',
  description: 'Resume Wave 3a: adversarially verify T1 (toolchain semantic fixes, pin 4867e03232a6) with a 3-lens panel; one fix round + reverify if blockers/majors survive',
  phases: [
    { title: 'V1 verify', detail: 'three independent lenses: encoding truth, tree truth, certification' },
    { title: 'T1 fix', detail: 'only if blocker/major issues; then one re-verification' },
  ],
}

const DIS = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const LLVM = '/home/fsanches/compartilhado/llvm-project'
const SCR = '/home/fsanches/compartilhado/disasm-lanes/wave3a-scratch'
const UNI = '/home/fsanches/compartilhado/tools/unidasm'

const COMMON = `You work on the TLCS-900 LLVM backend (${LLVM}, branch tlcs900_backend, build dir ${LLVM}/build, ninja) and the ROM disassembly that uses it (${DIS}, branch main). No other session is running. Prefix shell commands with cd <dir> && ... . TMPDIR is ${'$'}HOME/compartilhado/tmp; never write under /tmp (owner's strict rule) -- put every scratch file under ${SCR}/<your-stage-dir>/.

CONTEXT: Wave 3a stage T1 fixed semantic bugs of the backend (text that said something false about the bytes) and respelled the sources in lockstep. Its report is ${DIS}/notes/lanes/wave3a-2026-09-25/T1-report.json; the handoff is ${DIS}/notes/lanes/wave3a-2026-09-25/README.md; the certification record is the UPDATE 17 entry in ${DIS}/TOOLCHAIN_VERSION; T1's own probes are ${DIS}/notes/wave3a-toolchain-probes/ (README explains each). An earlier verifier was interrupted; its unreviewed tools are in ${DIS}/notes/lanes/wave3a-2026-09-25/v1-interrupted/ (strict_sweep.py, tree_audit.py, roundtrip_tree.py, verify_respells.py, ...; dis.sh points at an old scratch dir) -- a head start you may reuse or fix, NOT a verdict. T1 llvm commits: 6488ae7d520a..4867e03232a6. T1 disasm commits: 09b760eb..08896b73 (git log in ${DIS}).

TOOLS: MAME's decoder ${UNI} <file> -arch tlcs900 -basepc 0 (the reference for what bytes MEAN); llvm-mc at ${LLVM}/build/bin/llvm-mc (-triple=tlcs900 -show-encoding / --disassemble); llvm-objdump likewise. The TMP94C241 reference is in ${DIS}/.claude/skills/tmp94c241 (its references/sfr.md 8-bit timer / port FC table has known errors). The .s files are LATIN-1 (read bytes; use \`command grep\`, never the grep wrapper, for recursive search -- it silently skips files with high bytes).`

const V_SCHEMA = { type: 'object', properties: {
  lens: { type: 'string' },
  verdict: { type: 'string', enum: ['PASS', 'ISSUES'] },
  issues: { type: 'array', items: { type: 'object', properties: {
    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] },
    what: { type: 'string' }, evidence: { type: 'string' }, fix: { type: 'string' } },
    required: ['severity', 'what', 'evidence', 'fix'] } },
  checked: { type: 'string', description: 'what was checked, how, with counts, and where the probe scripts are' },
  probe_scripts: { type: 'array', items: { type: 'string' } } },
  required: ['lens', 'verdict', 'issues', 'checked', 'probe_scripts'] }

const T_SCHEMA = { type: 'object', properties: {
  llvm_commits: { type: 'array', items: { type: 'string' } },
  disasm_commits: { type: 'array', items: { type: 'string' } },
  binary_sha256: { type: 'string' }, pin_promoted: { type: 'boolean' },
  gate: { type: 'string' }, lit: { type: 'string' },
  fixed: { type: 'string' }, not_fixed: { type: 'string' }, leads: { type: 'string' } },
  required: ['llvm_commits', 'disasm_commits', 'binary_sha256', 'pin_promoted', 'gate', 'lit', 'fixed', 'not_fixed', 'leads'] }

const SEVERITY = `Severity: BLOCKER = the toolchain or a source line now says something FALSE about bytes (wrong register/operation/direction/value/size), or an assembler spelling silently encodes something other than what it says, or the gate/pin is not what the record claims. MAJOR = a claimed fix is incomplete (sites of a fixed defect class remain), a claim in the record does not reproduce, or a round trip fails for a family T1 touched. MINOR = cosmetics, pre-existing issues T1 did not touch (record them as minor with "pre-existing" in what), documentation gaps. Return PASS only if no blocker/major remains. Every issue needs concrete evidence: bytes, the llvm text, the unidasm text, file:line.`

const READONLY = `You are an ADVERSARIAL VERIFIER: do not trust the report -- try to break it. READ-ONLY on both git histories (no commits, no edits to tracked files, no stash/reset/checkout).`

const LENSES = [
  { key: 'V1a-encoding', dir: 'verify-V1a', text: `LENS: ENCODING TRUTH of the toolchain itself. Do NOT run make in ${DIS} (another verifier owns the build tree); assemble/disassemble scratch files only.
For every instruction family T1 touched -- di/ei; post-increment/pre-decrement operands (r32+)/(-r32) with :1/:2/:4 steps across every prefix that takes them and every register incl. bank registers; register-indirect displacement width :8/:16 including negative, 127/128, 255/256, -128/-129, 32767; true register names printed for 8/16/32-bit register codes in every printer table T1 changed; MUL/MULS/DIV/DIVS register forms; the extended-register (ERP) LD pair direction (ldto_/ldfr_ werp/berp); the deleted pseudo-instructions (must now be errors, not silently accepted under another meaning); the refused memory-to-memory decode -- do all three:
 (1) sweep synthetic bytes (vary register byte, mode byte, displacement over the WHOLE field) through llvm's disassembler and unidasm; compare operation AND every operand value/register/direction;
 (2) re-assemble every llvm-printed text and require byte-identical output (asymmetric decode = issue);
 (3) hunt for SILENT WRONG ENCODINGS in the assembler: write spellings a human would plausibly write (old pseudo names, (+xde), (xde-), (xsp+256), cp/ld with :24 direct addresses, ldto/ldfr with each operand order) and check each either errors or encodes exactly what it says per unidasm.
Also rerun llvm-lit for TLCS900 (build/bin/llvm-lit -sv ${LLVM}/llvm/test/MC/TLCS900 ${LLVM}/llvm/test/MC/Disassembler/TLCS900 ${LLVM}/llvm/test/CodeGen/TLCS900) and confirm the report's count (95/95).` },
  { key: 'V1b-tree', dir: 'verify-V1b', text: `LENS: TREE TRUTH -- do the SOURCES now say what the bytes do? Do NOT run make in ${DIS} (another verifier owns the build tree); extract lines/bytes yourself (the built ELFs/ROMs in ${DIS}/rebuilt_ROMs/ are current; the original ROMs are in ${DIS}/original_ROMs/ and wsa1/).
 (1) Sample at least 60 lines respelled by T1's disasm commits (git show 09b760eb..08896b73), spread over v10, v9, v7, v142, subcpu/boot, table_data, hdae5000, custom_data and wsa1/prom_*; for each, get the bytes at that address and confirm the new text is the TRUE meaning per unidasm (operation, registers, direction, displacement, step). A byte-exact respell that names the wrong thing is a BLOCKER.
 (2) Grep the whole tree (all trees above, with \`command grep\` or python bytes) for REMAINING sites of each defect class T1 claims fixed: \`di\` spelled anywhere; \`_spi\`/\`_dpi\`/\`_spd\`/\`_dpd\`/\`stib_dsp\`/\`stiw_dsp\` pseudo spellings; \`(+x\`/\`(x..-)\` absolute traps; \`(xsp+256)\`-style displacement sentinels; \`cpda16_24\`/\`cpdm16_24\`/\`ldda16_24\`/\`ldda32_24\`/\`ldada_24\`; \`stw_erp\`/\`ldw_erp\`/\`stb_erp\`/\`ldb_erp\`; stale comments that still state the OLD (wrong) meaning ("backend mnemonic is swapped", "disables interrupts" next to ei 0, etc.). Each surviving site of a class T1 claimed fixed = MAJOR.
 (3) Round-trip every instruction line of the touched families across the tree (assemble line -> disassemble -> compare text meaning to unidasm). roundtrip_tree.py / tree_audit.py in v1-interrupted are a head start (fix them as needed). Classify every failure: introduced or left wrong by T1 (blocker/major) vs. a pre-existing deferred spelling T1 explicitly listed in not_done (lda_dri, direct-address pseudos, ERP raw numbers, E8+r, masked immediates -- record counts as minor "known deferred").` },
  { key: 'V1c-cert', dir: 'verify-V1c', text: `LENS: CERTIFICATION -- does the record match reality? You OWN the build tree: you are the only verifier allowed to run make in ${DIS}.
 (1) ${LLVM}/build/bin/llvm-mc sha256 == TOOLCHAIN_VERSION header Binary line == ~/compartilhado/toolchain-snapshot/llvm-mc.snap; the previous snapshot is kept as llvm-mc.snap.<commit>-<sha8>; llvm HEAD is 4867e03232a6 and the build is not stale (ninja -C ${LLVM}/build -n llvm-mc reports nothing to do, or explain).
 (2) cd ${DIS} && make clean && make gate-all  -> must be 9/9 KN5000 IDENTICAL + 4/4 wsa1 ok + toolchain-prerequisite PASS. Paste the summary lines.
 (3) Every disasm commit 09b760eb..08896b73 carries the right \`LLVM: tlcs900_backend@<short> (<full>)\` trailer for the binary it was gated with (the pin moved during T1: 8e188b215251 -> 4867e03232a6; check each commit's trailer against TOOLCHAIN_VERSION history), and llvm history is linear with no rewritten commits (reflog / merge-base checks).
 (4) Re-derive at least 4 numbers T1 quoted (in T1-report.json, the UPDATE 17 entry, commit messages, notes/wave3a-toolchain-probes/README.md) with the committed scripts -- e.g. the two-decoder sweep class counts at the final pin (notes/wave3a-toolchain-probes/two_decoder_sweep.py), a respell report's site counts, lit 95/95. A quoted number that does not reproduce = MAJOR.
 (5) The CLAUDE.md "LLVM TLCS-900 Assembler Encoding Quirks" table rows changed by 828894fa: every example in them assembles to the stated bytes with the pinned llvm-mc.` },
]

phase('V1 verify')
const panel = await parallel(LENSES.map(L => () => agent(
  `${COMMON}\n\n${READONLY} Put probe scripts under ${SCR}/${L.dir}/ and list them.\n\n${L.text}\n\n${SEVERITY}`,
  { label: L.key, phase: 'V1 verify', schema: V_SCHEMA })))
const verdicts = panel.filter(Boolean)
log(`V1 panel: ${verdicts.map(v => `${v.lens}=${v.verdict}(${v.issues.length})`).join(', ')}${verdicts.length < LENSES.length ? ' -- ' + (LENSES.length - verdicts.length) + ' verifier(s) returned nothing' : ''}`)
const serious = verdicts.flatMap(v => v.issues.map(i => ({ lens: v.lens, ...i }))).filter(i => i.severity !== 'minor')

let fix = null, reverify = null
if (serious.length) {
  phase('T1 fix')
  log(`${serious.length} blocker/major issue(s); running one T1 fix round`)
  fix = await agent(`${COMMON}

TASK: T1 FIX ROUND. An adversarial verifier panel found these blocker/major issues with stage T1. Fix every one that is real (if you conclude one is NOT real, say why with evidence in not_fixed). HARD RULES: LLVM history is immutable -- new commits on tlcs900_backend only, never amend/rebase/reset/stash/force; do not touch the untracked ${LLVM}/2026-04-18_llvm_tlcs900_patches/. Every ${DIS} commit carries \`LLVM: tlcs900_backend@<short> (<full>)\` of the llvm commit whose binary it was gated with, and ends with \`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\`. Never push. Byte gate \`cd ${DIS} && make gate-all\` (13/13) before every ${DIS} commit. Lit tests for every backend change, byte strings cross-checked with unidasm. If the llvm-mc binary changes, follow the TOOLCHAIN_VERSION pin procedure (clean build, sha256, lit, NULL RUN zero-delta where the change only affects printing/new syntax, source respell in lockstep with a committed script where an existing spelling changes meaning, new UPDATE entry, header + snapshot (keep the old one) + trailer move together). Commit granularly. Scratch under ${SCR}/T1-fix/.

ISSUES (from three lenses):
${JSON.stringify(serious, null, 1).slice(0, 14000)}`, { label: 'T1:fix', phase: 'T1 fix', schema: T_SCHEMA })

  reverify = await agent(`${COMMON}\n\n${READONLY} Put probe scripts under ${SCR}/verify-V1-re/.\n\nLENS: RE-VERIFICATION after a T1 fix round. The panel's issues were:\n${JSON.stringify(serious, null, 1).slice(0, 9000)}\n\nThe fixer reported:\n${JSON.stringify(fix).slice(0, 5000)}\n\nFor EACH issue: is it fixed (reproduce the original evidence and show it is gone), or justifiably rejected? Then check the fix round did not break anything: llvm-lit TLCS900 all pass; you own the build tree: cd ${DIS} && make clean && make gate-all 13/13; pin consistency (binary sha256 == TOOLCHAIN_VERSION header == snapshot) if the binary changed; new commits carry correct trailers. Re-run the round-trip / two-decoder probes the panel used on the families the fix touched.\n\n${SEVERITY}`,
    { label: 'V1:reverify', phase: 'T1 fix', schema: V_SCHEMA })
}

return { panel: verdicts, serious_count: serious.length, fix, reverify }