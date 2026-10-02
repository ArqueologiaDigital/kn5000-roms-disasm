export const meta = {
  name: 'wsa1-naming-r1',
  description: 'Name the SX-WSA1R placeholder routines (sub_XXXXXX) from evidence: one namer per ~146-routine slice, each pack checked by an independent skeptic; read-only, returns edit packs',
  phases: [
    { title: 'Name', detail: 'one namer per slice, evidence-backed renames + headers' },
    { title: 'Verify', detail: 'independent skeptic per pack, rejects unsupported names' },
  ],
}

const REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const D = '/home/fsanches/compartilhado/disasm-lanes/wsa1-naming-r1'
const ITEMS = args

const PACK = { type: 'object', properties: {
  lane: { type: 'string' },
  renames: { type: 'array', items: { type: 'object', properties: {
    old: { type: 'string' }, new: { type: 'string' }, evidence: { type: 'string' } },
    required: ['old', 'new', 'evidence'] } },
  headers: { type: 'array', items: { type: 'object', properties: {
    label: { type: 'string', description: 'the NEW name' }, text: { type: 'string' },
    mode: { type: 'string', enum: ['insert', 'append', 'replace'] } },
    required: ['label', 'text', 'mode'] } },
  left_unnamed: { type: 'array', items: { type: 'object', properties: {
    name: { type: 'string' }, why: { type: 'string' } }, required: ['name', 'why'] } },
  notes: { type: 'string', description: 'patterns, cross-slice leads, misframing suspicions' } },
  required: ['lane', 'renames', 'headers', 'left_unnamed', 'notes'] }

const VERDICT = { type: 'object', properties: {
  lane: { type: 'string' }, checked: { type: 'integer' },
  rejected: { type: 'array', items: { type: 'object', properties: {
    old: { type: 'string' }, why: { type: 'string' } }, required: ['old', 'why'] } },
  header_fixes: { type: 'array', items: { type: 'object', properties: {
    label: { type: 'string' }, problem: { type: 'string' }, corrected_text: { type: 'string' } },
    required: ['label', 'problem', 'corrected_text'] } },
  reliable: { type: 'boolean', description: 'false if more than a quarter of the checked renames are wrong -- the whole pack should be discarded' },
  notes: { type: 'string' } },
  required: ['lane', 'checked', 'rejected', 'header_fixes', 'reliable', 'notes'] }

const CONTEXT = `PROJECT: the SX-WSA1R (Technics) ROM disassembly lives in ${REPO}/wsa1/ (byte-exact; built with an LLVM TLCS-900 backend). prom_a is at 0xF80000 (wsa1/prom_a/wsa1_prom_a.s, one 12.5 MB file), prom_b at 0xF00000 (wsa1/prom_b/wsa1_prom_b.s), prom_c/prom_d hold more code/data, wsa1/kernel/kernel.s a shared kernel. The CPU is a TMP95C061-class TLCS-900; its SFR names are in wsa1/include/tmp95c061_sfr.inc; memory-op macros (m_cp_mi8, m_bit, ...) in wsa1/include/tlcs900_mem_ops.inc. Read wsa1/HANDOFF-RESUME-HERE.md (orientation) and the wsa1/notes/FINDINGS-*.md relevant to what you meet (display lists: FINDINGS-ui-display-list.md; MIDI, FDC, LCD, DSP, interprocessor link ... each has one). Instruction lines carry their address in a trailing comment (prom_a: \`; ADDR  bytes\`; prom_b: \`; ADDR  MAME reading\`). Use \`command grep -n\` (never the bare grep: it silently skips these latin-1 files) and \`sed -n 'A,Bp'\` to read code. READ-ONLY: do not edit, commit or build anything; TMPDIR is ~/compartilhado/tmp, never /tmp; put any scratch under ${D}/scratch/<lane>/.`

const NAMING = `NAMING RULES
- A name states what the routine DOES, from evidence you can cite; never from a guess. Leaving a routine as sub_XXXXXX (listed in left_unnamed with a one-line reason) is correct whenever the evidence is not there.
- Follow the prefixes this file already uses for the subsystem (prom_a: LCD_, MidiIn_, MidiOut_, MIDI_, Fdc_, Disk_, Panel*, Screen*, ScreenLeave_, ScreenButton_, ToneEdit*, DigitalEffect_, Ring_, Link_, Ctrl_, Paint_, Evt2030_, Msg0716_ ...; prom_b: Smf_, DspEffect_, EffectEditor_, Blink_, BStore_, MsgLine_, DiskFile_, Paint_, ScreenEnter_/ScreenLeave_ ...); otherwise Subsystem_VerbNoun in CamelCase segments. No address digits in a new name. The name must not already exist anywhere in wsa1/ (\`command grep -rn '^NAME:' ${REPO}/wsa1\` and also check it is not used as any token) and must be unique within your pack.
- Evidence that counts: the SFR / I/O port it touches (by its tmp95c061_sfr.inc name), RAM variables with semantic labels, strings it draws/compares/copies, what it does with the results of NAMED callees, the named table it is an entry of (e.g. entry k of a screen's handler table), what its named callers do around the call. Display-list painters follow the existing rule: name from the text the list draws (see the headers of already-named Paint_ routines).
- Do not rename labels that are not in your worklist slice, and do not rename structural sub-labels (sub_X_Join etc.) yourself -- they follow their parent automatically.
HEADERS: for every rename, one header (2-6 comment lines, text WITHOUT leading semicolons): line 1 "<NewName> -- <what it does>", then "Evidence: ..." (cite labels/ports/addresses), optional "In:/Out:" when clear. If the routine already has a header: mode "append" when that header stays true (add what you established); mode "replace" when it says the purpose is unknown / "stays sub_XXXXXX on purpose" and you resolved it -- then carry over its still-true evidence lines into your text. Otherwise mode "insert".`

phase('Name')
const results = await pipeline(ITEMS,
  (it) => agent(`${CONTEXT}

YOUR LANE: ${it.lane}. Your worklist is the entries with "slice": ${it.slice} in ${it.worklist} (JSON list; each has name, file, addr, lines, callers, callees, referenced_by, data_refs, mem_refs, header, ready). Work through them LEAVES FIRST (entries with ready=true before the others), reading each routine's code and, where needed, its callers and callees.

${NAMING}

Return the edit pack: renames (old, new, one-line evidence), headers, left_unnamed (every slice entry you did not rename, with why), and notes (patterns, misframing suspicions -- e.g. a "routine" that is really data or a fragment of a neighbour -- and leads for other slices).`,
    { label: `name:${it.lane}`, phase: 'Name', schema: PACK }),
  (pack, it) => pack && agent(`${CONTEXT}

You are an INDEPENDENT SKEPTIC checking a naming lane's edit pack for ${it.lane} (worklist ${it.worklist}, slice ${it.slice}). The pack (JSON): ${JSON.stringify({ renames: pack.renames, headers: pack.headers }).slice(0, 60000)}

Check at least 40 renames (all of them if fewer): every one whose evidence is vague or generic, every one whose name asserts something specific (a screen, a MIDI message type, a device, a direction), plus an even spread of the rest. For each, read the routine's code (and the cited callers/callees/ports/strings) and decide: does the code DO what the name says, and does the cited evidence exist and support it? REJECT a rename if the name is unsupported, wrong, over-specific, or collides with an existing name in wsa1/ (\`command grep -rn\`). For each header you read, flag factual errors with a corrected text. Set reliable=false if more than a quarter of the renames you checked are wrong. Report how many you checked.`,
    { label: `verify:${it.lane}`, phase: 'Verify', schema: VERDICT }).then(v => ({ lane: it.lane, item: it, pack, verdict: v })))

const done = results.filter(Boolean)
let named = 0, rejected = 0, unreliable = []
for (const r of done) {
  named += (r.pack && r.pack.renames.length) || 0
  if (r.verdict) { rejected += r.verdict.rejected.length; if (!r.verdict.reliable) unreliable.push(r.lane) }
}
log(`${done.length}/${ITEMS.length} lanes returned; ${named} renames proposed, ${rejected} rejected by skeptics; unreliable packs: ${unreliable.join(', ') || 'none'}`)
return done