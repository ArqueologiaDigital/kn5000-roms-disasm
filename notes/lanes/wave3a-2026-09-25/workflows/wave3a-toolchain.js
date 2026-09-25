export const meta = {
  name: 'wave3a-toolchain',
  description: 'Wave 3a: fix the TLCS-900 backend semantic bugs and missing spellings, respell sources in lockstep, promote the pin; adversarially verified',
  phases: [
    { title: 'T1 semantic bugs', detail: 'di, F5 swap, printer misnames, post-increment trap, disp truncation' },
    { title: 'V1 verify', detail: 'adversarial check of T1' },
    { title: 'T2 spellings', detail: 'missing encodings/decodes, hi16/lo16, retire .byte instructions tree-wide' },
    { title: 'V2 verify', detail: 'adversarial check of T2' },
  ],
}

const DIS = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const LLVM = '/home/fsanches/compartilhado/llvm-project'
const COMMON = `You work on the TLCS-900 LLVM backend (${LLVM}, branch tlcs900_backend, build dir ${LLVM}/build, ninja) and the ROM disassembly that uses it (${DIS}, branch main). NO other agent is running: you have exclusive use of the shared llvm-mc and of ${DIS} main. Prefix shell commands with cd <dir> && ...

READ FIRST: ${DIS}/TOOLCHAIN_VERSION (the pin procedure: its header Commit/Binary lines, the UPDATE 15/16 entries show exactly how a change is certified and promoted -- clean-tree build, binary sha256, llvm-lit MC+CodeGen, a NULL RUN of make gate-all on an unconverted tree where the change must not move a byte, then source conversion, snapshot at ~/compartilhado/toolchain-snapshot/llvm-mc.snap with the old one kept as llvm-mc.snap.<commit>-<sha8>, header + snapshot + LLVM: trailer move together), ${DIS}/notes/SPEC-encoding-selectors-2026-09-04.md (a previous backend feature done the same way), ${DIS}/notes/lanes/wave2-2026-09-25/WAVE3-LEADS.md and WAVE3-PLAN.md (where the defects below were found, with byte examples), and ${DIS}/notes/lanes/BRIEF-2026-09-01.md (repo discipline; the .s files are LATIN-1: edit with explicit latin-1 I/O; use \`command grep\`).

HARD RULES: LLVM history is immutable -- new commits on tlcs900_backend only, never amend/rebase/reset/stash/force; do not touch the untracked ${LLVM}/2026-04-18_llvm_tlcs900_patches/. Every ${DIS} commit carries \`LLVM: tlcs900_backend@<short> (<full>)\` of the llvm commit whose binary it was gated with, and \`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>\`. Never push. Byte gate: \`cd ${DIS} && make gate-all\` must be 9/9 KN5000 IDENTICAL + 4/4 wsa1 ok + toolchain-prerequisite PASS before every ${DIS} commit. Every encoding claim is cross-checked against MAME's decoder (\`${'$'}HOME/compartilhado/tools/unidasm <file> -arch tlcs900 -basepc 0\` on synthetic bytes) AND against the ROMs' own use; the TMP94C241 reference is in ${DIS}/.claude/skills/tmp94c241 (note: its references/sfr.md has known errors in the 8-bit timer / port FC table -- do not trust that table). When a fix changes what an EXISTING source spelling assembles to, respell those sources in lockstep, tree-wide (v10, v9, v7, v142, subcpu/boot, table_data, hdae5000, custom_data, wsa1/*), with a committed script, and prove bytes unchanged with the gate. When a fix only changes PRINTING or adds syntax, the null run must be zero-delta. Update TOOLCHAIN_VERSION with a new UPDATE entry describing each change, the binary sha256, lit results and the gate, and promote the header pin + snapshot when done. Commit granularly (llvm and disasm). Put scratch under /home/fsanches/compartilhado/disasm-lanes/wave3a-scratch/ (NOT /tmp).`

const T_SCHEMA = { type: 'object', properties: {
  llvm_commits: { type: 'array', items: { type: 'string' } },
  disasm_commits: { type: 'array', items: { type: 'string' } },
  binary_sha256: { type: 'string' },
  pin_promoted: { type: 'boolean' },
  gate: { type: 'string' }, lit: { type: 'string' },
  done: { type: 'string' }, not_done: { type: 'string' }, leads: { type: 'string' } },
  required: ['llvm_commits', 'disasm_commits', 'binary_sha256', 'pin_promoted', 'gate', 'lit', 'done', 'not_done', 'leads'] }
const V_SCHEMA = { type: 'object', properties: {
  verdict: { type: 'string', enum: ['PASS', 'ISSUES'] },
  issues: { type: 'array', items: { type: 'object', properties: {
    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, what: { type: 'string' }, evidence: { type: 'string' }, fix: { type: 'string' } },
    required: ['severity', 'what', 'evidence', 'fix'] } },
  checked: { type: 'string' } }, required: ['verdict', 'issues', 'checked'] }

const T1_TASK = `TASK T1 -- SEMANTIC BUGS (the text the tools produce/accept says something false). Fix, in this order:
1. \`di\`: InstAlias<"di", (EI 0)> -> DI is EI 7 (06 07). A ready patch is at ${DIS}/notes/lanes/wave2-2026-09-25/di-alias.patch (parse-only alias (EI 7), 0 + 7 MC test updates) -- review it, apply, test. No source spells \`di\` any more (all were rewritten to \`ei 0\`), so the null run must be zero-delta; confirm with command grep.
2. F5-prefix (r32+) sub-opcodes 0x31/0x41 print/parse SWAPPED: \`f5 e0 31\` is lda XBC,(XWA+) (C idiom p=q++) but prints \`stb_dpi a, 224\`; \`f5 e8 41\` is ld (XDE+),A but prints \`lda_dpi xbc, 232\` (found by lane seqeng; ~228 source lines in v10; seqeng annotated some lines with "; = ld (xde+),a (backend mnemonic is swapped)" via scripts/tools/seqeng_annotate_swapped_dpi.py). Establish the truth from MAME's decoder and the TLCS-900 opcode map, fix the backend, and respell every affected source line tree-wide in lockstep (byte gate proves it); remove the now-obsolete "backend mnemonic is swapped" annotations.
3. Printer register misnames that round-trip but print the wrong register/size: \`cpda8 xbc,(8990)\` is cp A,(0x231E); \`addda16 xwa,(..)\` is add WA,(..); \`andda16 xhl,..\` is and HL,..; \`div xwa,xbc\` is div XWA,BC; \`c1 7f c0 c1\` prints \`andda8 xbc, (49279)\` but is and A,(0xc07f) (8-bit register code printed through the 32-bit table). Fix the printer (and make the parser accept the true spelling), then respell affected SOURCE lines to the true spelling (byte gate proves it). scripts/converters/lane_uiproc_respell.py (keeps a spelling only if unidasm and llvm-mc agree) is prior art.
4. Post-increment / pre-decrement operands: \`ld (xde+),a\` is a parse error and \`ld (+xde),a\` SILENTLY assembles an ABSOLUTE address expression (a trap). Add real syntax for the (r32+) / (-r32) addressing modes the hardware has, make \`(+reg)\` a hard error, and respell the sources that currently use a workaround (\`.byte\` or the F5 pseudo mnemonics) where the new syntax expresses the same bytes.
5. \`lda xwa, (xsp+256)\` silently assembles the 3-byte \`bf 00 30\` = (xsp+0): the 16-bit displacement is truncated (the +136 case correctly takes the 5-byte form with a warning). Make it encode correctly (the ROM has \`f3 fd 00 01 30\` for it) or be a hard error, never silent.
Also check for the same classes of defect in neighbouring instructions (other DPI sub-opcodes, other alias/printer tables) and report what you find even if you do not fix it.
Deliver: llvm commits with lit tests pinning each fix (bytes cross-checked with unidasm), source respell commits in ${DIS}, TOOLCHAIN_VERSION UPDATE entry, pin promoted, gate 13/13.`

const T2_TASK = `TASK T2 -- MISSING SPELLINGS / DECODES, then retire \`.byte\` instructions tree-wide. T1 (semantic bugs) has already landed and the pin was promoted; read its TOOLCHAIN_VERSION entry first. Add assembler spellings and disassembler decodes, each pinned by lit tests cross-checked with unidasm, for the forms the Wave 2 lanes could not express (examples in WAVE3-LEADS.md; confirm each against the ROM bytes that need it): SRI ALU decode (\`e3 07 e8 e4 80\` add XWA,(XDE+BC); \`c3 07 f0 e4 3f 00\` cp (XIX+BC),0); SRI store-immediate \`f3 .. 00 imm\` (ld (r32+r),imm); \`ld (XIX+WA),imm16\` 7-byte form; \`mul RR,(mem)\` direct forms (\`d1/c1 xx xx 40+r\`); shift/rotate-by-A (\`cb fe\` sll A,C; \`d9 fd\` sra A,BC; C8+r FE/FD/FC); register-indexed \`ld r,(XRR+RR)\` (\`c3 07 e0 e4 21\`); (r32+r16)+imm and compare/ALU-with-immediate register-indexed forms (\`and (XBC+WA),imm\`, \`cp (XBC+IZ),0\`, \`cp (XIX+HL),imm\`); \`bit n,(XDE+IY)\` / \`bit n,(XWA+DE)\`; 0x85-prefixed ldi/ldir; \`rlc N,W\`; \`sla N,QBC\`; \`sla A,r\`; \`d3 07 f0 f8 f1/f5\`; \`c7 3d 2b/2c\`; \`minc1\`; \`ldc DMAS2,XHL\`, \`ldc cr[0x48]\`; and hi16/lo16 relocation operators so \`pushw (Sym >> 16)\` / \`pushw (Sym & 0xffff)\` (or %hi/%lo style) assemble as relocations (extension_init.s RegMode/RegTitle name pointers are written as numeric halves for lack of this).
Then a TREE-WIDE pass: every \`.byte\` line that holds one whole instruction (many carry MAME's reading as a comment) becomes the instruction when unidasm and the new llvm-mc agree on the decode AND re-assembly reproduces the bytes; same for the numeric hi/lo pushw halves (symbolic now). Use or consolidate the existing re-framers (scripts/converters/sequi_reframe.py, lane_reframe_islands.py, scoop_reframe.py, lane_uiproc_respell.py); never convert a \`.byte\` that is data (check the region is code: reachable, not in a table). Measure \`.byte\` instruction islands before/after per tree with a committed script. Pin promotion + gate 13/13 as in T1.`

const verifyPrompt = (stage, rep) => `${COMMON}

You are the ADVERSARIAL VERIFIER of stage ${stage}. Do not trust its report; try to break it. READ-ONLY on git history: you may build and run anything, but do not commit to either repo (write any probe scripts under /home/fsanches/compartilhado/disasm-lanes/wave3a-scratch/verify-${stage}/ and mention them). The implementer reported: ${JSON.stringify(rep).slice(0, 6000)}

Check at least: (a) each claimed encoding/decoding against MAME unidasm on synthetic bytes and against the ROM sites that use it, including edge cases (negative/large displacements, every register of each class, all sub-opcodes of each touched family) -- look for new silent wrong-encodings; (b) assemble -> llvm-mc disassemble -> reassemble round trips for the touched families; (c) llvm-lit results reproduce; (d) the binary at ${LLVM}/build/bin/llvm-mc has the sha256 the report and TOOLCHAIN_VERSION header state, and ~/compartilhado/toolchain-snapshot/llvm-mc.snap matches it (the previous snapshot kept); (e) \`make gate-all\` in ${DIS} is 13/13 from a clean state (make clean && make gate-all is enough for KN5000; wsa1 gate rebuilds itself); (f) source respells: sample 40 respelled lines across trees and confirm the new text is the TRUE meaning of the bytes (unidasm) -- a respell that is byte-exact but still names the wrong operation is a failure; (g) grep for remaining sites of each defect class the stage claims to have fixed. Return PASS only if nothing blocker/major remains.`

phase('T1 semantic bugs')
let t1 = await agent(COMMON + '\n\n' + T1_TASK, { label: 'T1:semantic', phase: 'T1 semantic bugs', schema: T_SCHEMA })
phase('V1 verify')
let v1 = await agent(verifyPrompt('T1', t1), { label: 'V1:verify', phase: 'V1 verify', schema: V_SCHEMA })
if (v1 && v1.verdict === 'ISSUES' && v1.issues.some(i => i.severity !== 'minor')) {
  log('V1 found issues; running one T1 fix round')
  t1 = await agent(COMMON + '\n\n' + T1_TASK + `\n\nYOU ALREADY DID THIS STAGE once (report: ${JSON.stringify(t1).slice(0, 3000)}). An adversarial verifier found these issues -- fix every blocker/major one (new commits only), re-gate, re-promote the pin if the binary changes, and report: ${JSON.stringify(v1.issues).slice(0, 6000)}`, { label: 'T1:fix', phase: 'T1 semantic bugs', schema: T_SCHEMA })
  v1 = await agent(verifyPrompt('T1-fix', t1), { label: 'V1:reverify', phase: 'V1 verify', schema: V_SCHEMA })
}
phase('T2 spellings')
let t2 = await agent(COMMON + '\n\n' + T2_TASK + `\n\nT1's final report: ${JSON.stringify(t1).slice(0, 3000)}\nV1's final verdict: ${JSON.stringify(v1).slice(0, 2000)}`, { label: 'T2:spellings', phase: 'T2 spellings', schema: T_SCHEMA })
phase('V2 verify')
let v2 = await agent(verifyPrompt('T2', t2), { label: 'V2:verify', phase: 'V2 verify', schema: V_SCHEMA })
if (v2 && v2.verdict === 'ISSUES' && v2.issues.some(i => i.severity !== 'minor')) {
  log('V2 found issues; running one T2 fix round')
  t2 = await agent(COMMON + '\n\n' + T2_TASK + `\n\nYOU ALREADY DID THIS STAGE once (report: ${JSON.stringify(t2).slice(0, 3000)}). An adversarial verifier found these issues -- fix every blocker/major one (new commits only), re-gate, re-promote the pin if the binary changes, and report: ${JSON.stringify(v2.issues).slice(0, 6000)}`, { label: 'T2:fix', phase: 'T2 spellings', schema: T_SCHEMA })
  v2 = await agent(verifyPrompt('T2-fix', t2), { label: 'V2:reverify', phase: 'V2 verify', schema: V_SCHEMA })
}
return { t1, v1, t2, v2 }
