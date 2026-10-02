export const meta = {
  name: 'event-code-catalog',
  description: 'Research names for the 702 numeric firmware event codes / class ids used as operands (v10/v9/v7/hdae5000): one researcher per value group, each catalog checked by a skeptic; read-only',
  phases: [
    { title: 'Research', detail: 'per group: handler + sender evidence -> constant name' },
    { title: 'Verify', detail: 'skeptic re-derives a sample of names from the code' },
  ],
}
const REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
const DOCS = '/home/fsanches/compartilhado/technics-docs'
const D = '/home/fsanches/compartilhado/disasm-lanes/event-naming'

const CAT = { type: 'object', properties: {
  group: { type: 'string' },
  entries: { type: 'array', items: { type: 'object', properties: {
    value: { type: 'string', description: '0x01XXXXXX' },
    name: { type: 'string', description: 'proposed constant name, or "" if not established' },
    meaning: { type: 'string' },
    evidence: { type: 'string', description: 'handler(s) and sender(s) by label + address, what they do' },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] } },
    required: ['value', 'name', 'meaning', 'evidence', 'confidence'] } },
  existing_conflicts: { type: 'string', description: 'existing constants/doc names that disagree with the code' },
  notes: { type: 'string' } },
  required: ['group', 'entries', 'existing_conflicts', 'notes'] }

const VERD = { type: 'object', properties: {
  group: { type: 'string' }, checked: { type: 'integer' },
  rejected: { type: 'array', items: { type: 'object', properties: {
    value: { type: 'string' }, why: { type: 'string' }, better_name: { type: 'string' } },
    required: ['value', 'why', 'better_name'] } },
  reliable: { type: 'boolean' }, notes: { type: 'string' } },
  required: ['group', 'checked', 'rejected', 'reliable', 'notes'] }

const CONTEXT = `REPO ${REPO} (KN5000 ROM disassembly, byte-exact; v10/maincpu is the best-understood tree, v9/v7 are the same firmware at other revisions, hdae5000/ is the HD-AE5000 extension ROM). READ-ONLY: no edits, no commits, no make. Use \`command grep\` (never the bare grep: it silently skips the latin-1 .s files) and read .s files as bytes/latin-1. Scratch under ${D}/scratch/ (TMPDIR ~/compartilhado/tmp; never /tmp).
The worklist ${D}/event_values_v10_hdae.json lists every value in 0x01000000..0x01FFFFFF used as an instruction operand in v10 + hdae5000: value, occurrence count, existing constant(s) if any, and up to 12 sites (file:line mnemonic).
PRIOR KNOWLEDGE (verify, do not copy blindly): ${DOCS}/event-codes.md (the canonical event reference; families 0x01E0 lifecycle/object via ClassProc/ObjectProc/InheritedProc, 0x01C0 request/action, 0x01E4 widget responses...), ${DOCS}/hdae5000-homebrew.md, existing EVT_* .equ in v10/maincpu/shared/event_codes.s and hdae5000/shared/event_codes.s, and the NAKA class system (class id = table_id<<16 | index; 292 ClassProc descriptors; scripts/analysis/nakarest_objtab_map.py "THE CLASS SYSTEM"; the naka_*.c files name classes, e.g. 0x01600025 = AcWindowPage).
NAMING: events -> EVT_<WHAT> in UPPER_SNAKE like the existing ones (EVT_GET_HL, EVT_KEYPRESS); class ids -> the convention the tree already uses for class constants if one exists (search), else NAKA_CLASS_<ClassName> with the firmware's own class name. A name must follow from what the HANDLER does with the event (the routine reached when the code compares equal) and/or what the SENDER is doing when it sends it -- cite both by label and address. A value used only as data that is NOT an event/class (a coincidental constant) gets name "" and meaning saying what it really is. Leave name "" when not established. Check every proposed name is unique and does not collide with an existing symbol.`

const GROUPS = args
phase('Research')
const out = await pipeline(GROUPS,
  (g) => agent(`${CONTEXT}

YOUR GROUP: ${g.name} -- the worklist entries whose value is in ${g.range}. Produce a catalog entry for EVERY value in your range (even if name stays ""). Start from how the code dispatches on these values (the compare chains / jump tables in ClassProc/ObjectProc/handlers) -- one dispatcher often explains a whole family.`,
    { label: `research:${g.name}`, phase: 'Research', schema: CAT }),
  (cat, g) => cat && agent(`${CONTEXT}

You are an INDEPENDENT SKEPTIC of an event-code catalog for group ${g.name} (${g.range}). Catalog: ${JSON.stringify(cat.entries).slice(0, 50000)}
Check at least 30 entries with a non-empty name (all if fewer), favouring medium/low confidence and the most-used values: re-derive the meaning from the handler and a sender. Reject names the code does not support, that are too specific/generic, or that collide (give a better name if you can). reliable=false if more than a quarter of checked names are wrong.`,
    { label: `verify:${g.name}`, phase: 'Verify', schema: VERD }).then(v => ({ group: g.name, catalog: cat, verdict: v })))
const res = out.filter(Boolean)
log(`${res.length}/${GROUPS.length} groups; ${res.reduce((a, r) => a + r.catalog.entries.filter(e => e.name).length, 0)} named values, ${res.reduce((a, r) => a + (r.verdict ? r.verdict.rejected.length : 0), 0)} rejected`)
return res