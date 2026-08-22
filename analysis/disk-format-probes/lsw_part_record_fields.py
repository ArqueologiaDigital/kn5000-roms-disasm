#!/usr/bin/env python3
"""Attribute the individual BYTES of the KN5000 .LSW *per-part* record.

QUESTION ANSWERED
-----------------
"The per-part panel record has 24 payload bytes (0x18) and only five of them were
attributed.  What is each of the other nineteen, and which of them cannot be
attributed from the ROM at all?"

The per-part family is 26 records sharing one layout: tags 0x00..0x16 and 0x19 in
schema block 0, tags 0x17 and 0x18 in block 1 (see lsw_panel_schema_from_rom.py).
Offsets below are DECIMAL payload offsets, i.e. exactly the `d` byte of
SwbtWr_QueuePostEvent, and byte `record_start + 2 + offset` in RAM.

FOUR INDEPENDENT SOURCES, all scanned here
------------------------------------------
(1) ROM FIELD DESCRIPTORS.  Each record points at a descriptor list; a descriptor
    carries TYPE, OFFSET, MASK and (types 3/4) MIN/MAX/DEFAULT.  This is the
    firmware's own declaration of a field's shape and it is independent of any
    routine name: min=0/max=1 is a boolean whatever its writer is called, mask
    0x7F is a 7-bit value, type 8 is "byte, no constraint declared".

(2) ABSOLUTE ACCESSES.  Every operand `(0xNNNN)` in 0x00F9A0..0x00FFC0 mapped
    through the schema onto (tag, offset), as in lsw_field_evidence.py -- but
    aggregated BY OFFSET across all 26 part tags, and carrying the immediate
    mask found on the same or the next line.

(3) BASE-POINTER + DISPLACEMENT (new here).  lsw_field_evidence.py can only see
    `(0xF9C3)`; it is blind to `lda_d16 xiy,(0xf9b6)` followed by `(xiy+12)`,
    which is how bitmap_out_routines.s reaches most of the record.  This pass
    binds a long register to a panel address and then resolves every
    `(reg+disp)` use of it.  It also follows the two rewrites the firmware uses
    to reach the three 0x620-byte mirrors of the region:
        sub <reg>, 0xF9A0   then   add <reg>, {0x03C2C4|0x03C8E4|0x03CF04}
    which changes the pointer but not the record offset it denotes.

    *** TRAP: this assembler prints displacement 0 as "+256".  `ld a,(xiy+256)`
    assembles to [0x8d,0x00,0x21] -- displacement byte 0x00.  A probe that takes
    the printed number literally invents an offset 256.  Normalised here. ***

(4) THE EVENT PROTOCOL.  SwbtWr_QueuePostEvent(e=tag, d=offset, a=value, w=mask),
    aggregated by offset over the part tags.  The mask alone is informative: a
    field only ever posted with mask 0x40 is one bit wide.

PASS / FAIL (the falsifiable form)
----------------------------------
Source (3) is new, so it is gated against source (4), which is independent:
wherever a literal (e=tag,d=off) event site sits within WINDOW source lines of a
base+displacement attribution, the two must name the same (tag, offset).  One
disagreement fails the run.  It is a test that can come out negative: the
binding tracker guesses (it assumes a `call` preserves the pointer registers,
which is only a convention), and a wrong guess would put the wrong offset next
to an event that states the right one.

A second, cheaper gate: every attributed offset must be < the record's declared
payload length.  An out-of-record displacement means the base binding was lost.

WHAT THE UNCONVERTED CODE COSTS
-------------------------------
`--gaps` counts, per source file, the raw `.byte` blobs and how many 16-bit
little-endian words inside them would land in 0x00F9A0..0x00FFC0.  Each such
word is a *candidate* panel-address operand that no scan above can see.  It is
an upper bound, not a count of real accesses -- a `.byte` blob is data as often
as it is code -- but it says where converting more code would pay.

    python3 analysis/disk-format-probes/lsw_part_record_fields.py            # v9
    python3 analysis/disk-format-probes/lsw_part_record_fields.py --detail
    python3 analysis/disk-format-probes/lsw_part_record_fields.py --gaps
    python3 analysis/disk-format-probes/lsw_part_record_fields.py v7

Numbers this produced (see README-lsw-part-record-fields.md):
    26 part records, 24 payload bytes each
    v9: 280 absolute accesses, 294 base+displacement attributions, 25 event sites
    v7: 222 absolute accesses, 219 base+displacement attributions,  0 event sites
        (v7's SwbtWr_QueuePostEvent call sites are not converted yet)
    offsets with code evidence, IDENTICAL in v7 and v9 -- 14 of 24:
        +0 +1 +2 +3 +4 +5 +7 +8 +9 +12 +13 +14 +15 +17
    offsets a ROM descriptor declares but no code ever touches -- 9 of 24:
        +6 +11 +16 +18 +19 +20 +21 +22 +23
        (+22 is the only declared BIT field, mask 0x01, that nothing reads)
    offsets with neither a descriptor nor any code -- 1 of 24:  +10
    gate: 15 event sites in 5 routines also reached by the pointer scan; 15/15 agree
    --gaps: 25 candidate hidden absolute panel operands in 107,834 bytes of raw
        .byte, against a chance expectation of 40 -- i.e. BELOW noise.  Converting
        more v9 code would buy nothing for this question.
"""
import collections, os, re, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
ROM_PATH = os.path.join(REPO, 'original_ROMs', 'kn5000_v7_program.rom')
LOAD = 0xE00000
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))
LO, HI = 0xF9A0, 0xFFC0
# tags whose records share the per-part layout, in schema order
PART_TAGS = list(range(0x00, 0x17)) + [0x19, 0x17, 0x18]
# the three 0x620-byte shadow copies of 0xF9A0..0xFFC0; a pointer rebased onto one
# of them still denotes the same (tag, offset)
MIRRORS = (0x03C2C4, 0x03C8E4, 0x03CF04)
LONGREGS = ('xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz')
WINDOW = 12

RE_LBL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
RE_MN = re.compile(r'^\s*([a-z][a-z0-9_]*)')
RE_ABS = re.compile(r'\(\s*(0x[0-9a-fA-F]+|\d+)\s*\)')
RE_LDB = re.compile(r'^\s*ldb\s+([edaw])\s*,\s*(0x[0-9a-fA-F]+|\d+)\s*$')
RE_DISP = re.compile(r'\(\s*(x(?:wa|bc|de|hl|ix|iy|iz))\s*\+\s*(0x[0-9a-fA-F]+|\d+)\s*\)')
RE_IND = re.compile(r'\(\s*(x(?:wa|bc|de|hl|ix|iy|iz))\s*\)')
# binding creators
RE_BIND_ABS = re.compile(r'^\s*(?:lda_d16|lda_24|lda|ld)\s+(x(?:wa|bc|de|hl|ix|iy|iz))\s*,\s*\(?\s*(0x[0-9a-fA-F]+|\d+)\s*\)?\s*$')
RE_BIND_DISP = re.compile(r'^\s*lda\s+(x(?:wa|bc|de|hl|ix|iy|iz))\s*,\s*\(\s*(x(?:wa|bc|de|hl|ix|iy|iz))\s*\+\s*(0x[0-9a-fA-F]+|\d+)\s*\)\s*$')
RE_BIND_MOV = re.compile(r'^\s*ld\s+(x(?:wa|bc|de|hl|ix|iy|iz))\s*,\s*(x(?:wa|bc|de|hl|ix|iy|iz))\s*$')
RE_ARITH = re.compile(r'^\s*(add|sub)\s+(x(?:wa|bc|de|hl|ix|iy|iz))\s*,\s*(\S+)\s*$')
# an immediate mask on the same or an adjacent line
RE_MASK = re.compile(r'^\s*(and|or|xor|andmi8|ormi8|xormi8|anddi8|orddm8|cp)\w*\s+.*?(0x[0-9a-fA-F]+|\b\d+\b)\s*$')
RE_BITN = re.compile(r'^\s*(bit|res|set|bitda|sla|srl|sll)\w*\s+(\d+)\s*,')


def norm_disp(v):
    """This assembler prints displacement 0 as +256; see the module docstring."""
    return 0 if v == 256 else v


def schema():
    rom = open(ROM_PATH, 'rb').read()
    recs, desc = [], {}
    for addr, count, base in TABLES:
        for i in range(count):
            o = addr - LOAD + 10 * i
            off, ptr = struct.unpack_from('<II', rom, o)
            tag, ln = rom[o + 8], rom[o + 9]
            recs.append((base + off, tag, 0 if tag == 0xFF else ln))
            if tag != 0xFF:
                desc.setdefault(tag, parse_descriptors(rom, ptr))
    return recs, desc


def parse_descriptors(rom, ptr):
    """Grammar per README-lsw-panel-schema.md; returns [(type, off, mask, min, max, def)]."""
    out, o = [], ptr - LOAD
    if not (0 <= o < len(rom)):
        return out
    while rom[o] != 0xFF:
        t = rom[o]
        if t in (0, 1, 2):
            out.append((t, rom[o + 1], rom[o + 2], None, None, None)); o += 3
        elif t in (3, 4):
            out.append((t, rom[o + 1], rom[o + 2], rom[o + 3], rom[o + 4], rom[o + 5])); o += 6
        elif t in (5, 6):
            n = rom[o + 3]
            out.append((t, rom[o + 1], rom[o + 2], None, None, None)); o += 4 + n
        elif t == 7:
            out.append((t, rom[o + 1], None, None, None, rom[o + 2])); o += 3
        elif t == 8:
            out.append((t, rom[o + 1], None, None, None, None)); o += 2
        else:
            break
    return out


def sources(ver):
    for dp, _dn, fn in os.walk(os.path.join(REPO, ver)):
        for f in sorted(fn):
            if f.endswith('.s'):
                yield os.path.join(dp, f)


def kind(op):
    if op.startswith('lda'):
        return 'LEA'
    if op.startswith(('st', 'or', 'and', 'xor', 'inc', 'dec', 'res', 'set')):
        return 'W'
    return 'R'


def mask_hint(lines, i):
    """Immediate mask / bit number on this line or the next two.  HEURISTIC: the
    operand register is not tracked, so this is a hint to be read with the quoted
    context, not a proof."""
    for j in range(i, min(i + 3, len(lines))):
        c = lines[j].split(';')[0].rstrip()
        m = RE_BITN.match(c)
        if m and m.group(1) in ('bit', 'res', 'set', 'bitda'):
            return 'bit%s' % m.group(2)
        m = RE_MASK.match(c)
        if m:
            try:
                v = int(m.group(2), 0)
            except ValueError:
                continue
            if 0 <= v <= 0xFF:
                return '&%02X' % v
    return ''



FILE_TLV_START = 0x20


def file_blocks(data, limit=26):
    """Same TLV walk as lsw_file_vs_firmware_schema.py."""
    p, blocks, cur = FILE_TLV_START, [], []
    while p + 1 < len(data) and len(blocks) < limit:
        tag, ln = data[p], data[p + 1]
        if tag == 0xFF and ln == 0xFF:
            blocks.append(cur); cur = []; p += 2; continue
        cur.append((tag, ln, data[p + 2:p + 2 + ln]))
        p += 2 + ln
    return blocks


def file_census(paths):
    """Independent, file-side evidence: what values does each per-part offset actually
    take in real saved panels?  A byte that is 0 in every part of every saved panel on
    every disk is not being used; a byte that is always 0x40 is a centred bipolar
    control.  This cannot name a field, but it can contradict a naming, and it is the
    only source here that is not the firmware."""
    groups = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    nrec = collections.Counter()
    for path in paths:
        data = open(path, 'rb').read()
        for bi, blk in enumerate(file_blocks(data)):
            grp = 'block0' if bi == 0 else 'slots'
            for tag, ln, payload in blk:
                if tag not in PART_TAGS:
                    continue
                nrec[(grp, ln)] += 1
                for off, v in enumerate(payload):
                    groups[(grp, ln)][off][v] += 1
    for key in sorted(groups):
        grp, ln = key
        print('---- %s: %d per-part records of %d payload bytes (from %d file(s))'
              % (grp, nrec[key], ln, len(paths)))
        for off in sorted(groups[key]):
            c = groups[key][off]
            vals = sorted(c)
            tops = ' '.join('%02X:%d' % (v, n) for v, n in c.most_common(4))
            print('   +%-3d %2d distinct  min=%02X max=%02X   %s%s'
                  % (off, len(c), vals[0], vals[-1], tops,
                     '   <-- CONSTANT' if len(c) == 1 else ''))
        print()


def main():
    ver, detail, gaps = 'v9', '--detail' in sys.argv, '--gaps' in sys.argv
    files = [a for a in sys.argv[1:] if a.lower().endswith('.lsw')]
    if files:
        file_census(files)
        return 0
    for a in sys.argv[1:]:
        if not a.startswith('-') and not a.lower().endswith('.lsw'):
            ver = a
    recs, desc = schema()
    lens = {t: l for _s, t, l in recs}
    starts = {t: s for s, t, _l in recs}

    def locate(a):
        for st, tag, ln in recs:
            if st <= a <= st + 1 + ln:
                return tag, a - st - 2
        return None

    absacc = collections.defaultdict(list)   # offset -> [(tag,kind,op,mask,routine,rel,line)]
    ptracc = collections.defaultdict(list)   # offset -> [(tag,kind,op,mask,routine,rel,line,base)]
    events = collections.defaultdict(list)   # offset -> [(tag,val,mask,routine,rel,line)]
    other_ev = []
    ptr_sites = collections.defaultdict(list)   # rel -> [(line, tag, off)]
    ev_sites = []
    oor = []                                  # out-of-record attributions

    for path in sources(ver):
        rel = os.path.relpath(path, REPO)
        lines = open(path, errors='replace').read().split('\n')
        cur = '?'
        bind = {}          # reg -> ('rec', live_addr) | ('mirror', base) | ('const', v)
        pend = {}
        for i, raw in enumerate(lines):
            m = RE_LBL.match(raw)
            if m:
                cur, bind = m.group(1), {}
            code = raw.split(';')[0].rstrip()
            if not code.strip():
                continue

            # ---- (4) event protocol -------------------------------------------------
            mb = RE_LDB.match(code)
            if mb:
                pend[mb.group(1)] = int(mb.group(2), 0)
            elif 'SwbtWr_QueuePostEvent' in code and 'call' in code:
                if 'e' in pend and 'd' in pend:
                    t, off = pend['e'], pend['d']
                    if t in PART_TAGS and 0 <= off < lens.get(t, 0):
                        events[off].append((t, pend.get('a'), pend.get('w'), cur, rel, i + 1))
                        ev_sites.append((t, off, cur, rel, i + 1))
                    else:
                        other_ev.append((t, off, cur, rel, i + 1))
                pend = {}
            elif 'call' in code:
                pend = {}

            # ---- (3) pointer bindings ----------------------------------------------
            m = RE_BIND_ABS.match(code)
            if m:
                r, v = m.group(1), int(m.group(2), 0)
                if LO <= v <= HI:
                    bind[r] = ('rec', v)
                elif v in MIRRORS:
                    bind[r] = ('mirror', v)
                elif v == LO:
                    bind[r] = ('const', v)
                else:
                    bind[r] = ('const', v)
                if v == LO:
                    bind[r] = ('const', LO)
            else:
                m = RE_BIND_DISP.match(code)
                if m:
                    dst, src, d = m.group(1), m.group(2), norm_disp(int(m.group(3), 0))
                    b = bind.get(src)
                    bind[dst] = ('rec', b[1] + d) if b and b[0] == 'rec' else None
                    if bind[dst] is None:
                        bind.pop(dst)
                else:
                    m = RE_BIND_MOV.match(code)
                    if m:
                        b = bind.get(m.group(2))
                        if b:
                            bind[m.group(1)] = b
                        else:
                            bind.pop(m.group(1), None)
                    else:
                        m = RE_ARITH.match(code)
                        if m:
                            opa, r, arg = m.group(1), m.group(2), m.group(3)
                            b = bind.get(r)
                            try:
                                k = int(arg, 0)
                            except ValueError:
                                k = None
                            other = bind.get(arg)
                            if b and b[0] == 'rec' and opa == 'sub' and (
                                    k == LO or (other and other[0] == 'const' and other[1] == LO)):
                                pass                      # pointer -> region offset, same field
                            elif b and b[0] == 'rec' and opa == 'add' and (
                                    (k in MIRRORS) or (other and other[0] == 'mirror')):
                                pass                      # region offset -> mirror, same field
                            elif b and b[0] == 'rec' and k is not None:
                                bind[r] = ('rec', b[1] + (k if opa == 'add' else -k))
                            else:
                                bind.pop(r, None)
                        else:
                            # any other definition of a long register kills the binding
                            m2 = re.match(r'^\s*\w+\s+(x(?:wa|bc|de|hl|ix|iy|iz))\s*,', code)
                            if m2 and not RE_DISP.search(code.split(',')[0]):
                                bind.pop(m2.group(1), None)
                            for r in re.findall(r'^\s*(?:pop|popw)\s+(x(?:wa|bc|de|hl|ix|iy|iz))', code):
                                bind.pop(r, None)

            m0 = RE_MN.match(code)
            op = m0.group(1) if m0 else ''

            # ---- (2) absolute accesses ---------------------------------------------
            for mn in RE_ABS.finditer(code):
                v = int(mn.group(1), 0)
                if LO <= v <= HI:
                    r = locate(v)
                    if r and r[0] in PART_TAGS and r[1] >= 0:
                        absacc[r[1]].append((r[0], kind(op), op, mask_hint(lines, i), cur, rel, i + 1))
                    break

            # ---- (3) uses of a bound pointer ---------------------------------------
            uses = [(g[0], norm_disp(int(g[1], 0))) for g in RE_DISP.findall(code)]
            uses += [(g, 0) for g in RE_IND.findall(code)]
            for r, d in uses:
                b = bind.get(r)
                if not b or b[0] != 'rec':
                    continue
                if RE_BIND_DISP.match(code):
                    continue                       # already handled as a rebinding
                loc = locate(b[1] + d)
                if not loc or loc[0] not in PART_TAGS:
                    continue
                tag, off = loc
                if off < 0 or off >= lens.get(tag, 0):
                    oor.append((tag, off, cur, rel, i + 1, code.strip()))
                    continue
                ptracc[off].append((tag, kind(op), op, mask_hint(lines, i), cur, rel, i + 1, b[1]))
                ptr_sites[rel].append((i + 1, tag, off))

    # ---------------- gate 1: base+disp must agree with the event protocol -----------
    # Routine-scoped, NOT line-scoped.  A line window is the wrong unit here: these
    # routines touch a field ~20 lines before they announce it, and consecutive
    # routines are near-identical clones, so a +-12 line window straddles the
    # boundary and compares one part's pointer against the next part's event.
    # For every routine in which BOTH sources speak:
    #   TAG GATE     every part-tag event posted must name the record the pointer
    #                scan bound in that routine (fails if a binding was mis-tracked
    #                or leaked in from a neighbouring routine);
    #   OFFSET GATE  every (tag, offset) posted must also have been reached through
    #                a pointer in the same routine.
    ev_by_rout = collections.defaultdict(set)
    for tag, off, rout, rel, ln in ev_sites:
        ev_by_rout[(rel, rout)].add((tag, off))
    ptr_by_rout = collections.defaultdict(set)
    for off, L in ptracc.items():
        for tag, _k, _op, _mk, rout, rel, _ln, _b in L:
            ptr_by_rout[(rel, rout)].add((tag, off))
    checked = agree = 0
    bad = []
    for key in sorted(set(ev_by_rout) & set(ptr_by_rout)):
        ev, pt = ev_by_rout[key], ptr_by_rout[key]
        ptags, etags = {t for t, _ in pt}, {t for t, _ in ev}
        checked += len(ev)
        if etags != ptags:
            bad.append((key, 'TAG', sorted(etags), sorted(ptags)))
            continue
        missing = ev - pt
        if missing:
            bad.append((key, 'OFFSET', sorted(missing), sorted(pt)))
            continue
        agree += len(ev)

    # ---------------- report ---------------------------------------------------------
    PLEN = lens[0x00]
    print('#### KN5000 per-part .LSW record: %d records (tags %s), %d payload bytes each'
          % (len(PART_TAGS), ' '.join('%02X' % t for t in PART_TAGS), PLEN))
    print('#### sources: %s  |  descriptors from %s' % (ver, os.path.basename(ROM_PATH)))
    print()
    hdr = '%-4s %-30s %-5s %-5s %-6s %s' % ('off', 'ROM descriptors (all 26 tags)', 'abs', 'ptr', 'events', 'routines')
    print(hdr); print('-' * len(hdr))
    no_evidence, desc_only = [], []
    for off in range(PLEN):
        dd = collections.Counter()
        for t in PART_TAGS:
            for (ty, o, mask, mn, mx, dv) in desc.get(t, ()):
                if o == off:
                    dd['t%d/%s%s' % (ty, ('%02X' % mask) if mask is not None else '--',
                                     (' %d..%d=%d' % (mn, mx, dv)) if mn is not None else '')] += 1
        na, np_, ne = len(absacc[off]), len(ptracc[off]), len(events[off])
        routs = collections.Counter(x[4] for x in absacc[off]) + collections.Counter(x[4] for x in ptracc[off]) \
            + collections.Counter(x[3] for x in events[off])
        print('%-4d %-30s %-5d %-5d %-6d %s'
              % (off, ' '.join('%sx%d' % (k, v) for k, v in dd.most_common(2)) or '(none)',
                 na, np_, ne, ', '.join(r for r, _ in routs.most_common(4))))
        if na == np_ == ne == 0:
            (desc_only if dd else no_evidence).append(off)
    print()
    print('offsets with NO code evidence and NO descriptor: %s'
          % (' '.join('+%d' % o for o in no_evidence) or '(none)'))
    print('offsets declared by a descriptor but never touched by code: %s'
          % (' '.join('+%d' % o for o in desc_only) or '(none)'))
    print('totals: %d absolute accesses, %d base+displacement attributions, %d event sites'
          % (sum(len(v) for v in absacc.values()), sum(len(v) for v in ptracc.values()),
             sum(len(v) for v in events.values())))

    if detail:
        for off in range(PLEN):
            if not (absacc[off] or ptracc[off] or events[off]):
                continue
            print('\n======== payload offset +%d (0x%02X) ========' % (off, off))
            for tag, k, op, mk, rout, rel, ln in absacc[off]:
                print('  ABS  tag %02X %-3s %-9s %-6s %-40s %s:%d' % (tag, k, op, mk, rout, rel, ln))
            for tag, k, op, mk, rout, rel, ln, base in ptracc[off]:
                print('  PTR  tag %02X %-3s %-9s %-6s %-40s %s:%d  [base 0x%04X]'
                      % (tag, k, op, mk, rout, rel, ln, base))
            for tag, val, mk, rout, rel, ln in events[off]:
                print('  EVT  tag %02X value=%-6s mask=%-6s %-40s %s:%d'
                      % (tag, ('0x%02X' % val) if val is not None else '(reg)',
                         ('0x%02X' % mk) if mk is not None else '(reg)', rout, rel, ln))

    if gaps:
        print('\n#### what the still-unconverted code hides ####')
        print('per file: raw .byte lines, bytes in them, and how many byte triples inside')
        print('them encode a TLCS-900 absolute operand {C1|D1|E1|F1} + LE16 in 0x%04X..0x%04X.' % (LO, HI))
        print('Still an UPPER BOUND (a .byte blob is data as often as it is code), but the')
        print('prefix requirement puts the chance rate at 3.7e-4 per byte, so a file well')
        print('above bytes*3.7e-4 is carrying real hidden panel accesses.')
        tot = collections.Counter()
        rows = []
        for path in sources(ver):
            rel = os.path.relpath(path, REPO)
            nb = nby = ncand = 0
            for raw in open(path, errors='replace'):
                s = raw.strip()
                if not s.startswith('.byte'):
                    continue
                vals = []
                for tk in s[5:].split(','):
                    tk = tk.strip()
                    try:
                        vals.append(int(tk, 0) & 0xFF)
                    except ValueError:
                        pass
                nb += 1; nby += len(vals)
                for j in range(len(vals) - 2):
                    # TLCS-900 absolute 16-bit operand = prefix {C1,D1,E1,F1} then LE16.
                    #   ldb_d8 a,(0xF9C3) = C1 C3 F9 21 ;  stb_d8 (0xF9C3),a = F1 C3 F9 41
                    #   lda_d16 xwa,(0xF9B6) = F1 B6 F9 30 ; ldw_d16 xhl,(..) = D1 ..
                    # Requiring the prefix cuts the false-positive rate ~256x: a random
                    # byte triple matches with p = (4/256)*(0x620/65536) = 3.7e-4.
                    if vals[j] in (0xC1, 0xD1, 0xE1, 0xF1):
                        w = vals[j + 1] | (vals[j + 2] << 8)
                        if LO <= w <= HI:
                            ncand += 1
            if nb:
                rows.append((ncand, nby, nb, rel))
                tot['lines'] += nb; tot['bytes'] += nby; tot['cand'] += ncand
        rows.sort(reverse=True)
        for ncand, nby, nb, rel in rows[:15]:
            print('  %5d candidates  %7d bytes in %5d .byte lines   %s' % (ncand, nby, nb, rel))
        print('  TOTAL %d candidate panel operands in %d bytes across %d .byte lines'
              % (tot['cand'], tot['bytes'], tot['lines']))
        print('  chance expectation at that size: %.0f' % (tot['bytes'] * 3.7e-4))

    print('\n#### gates ####')
    print('cross-check: %d literal event site(s) live in %d routine(s) that the pointer scan also'
          % (checked, len(set(ev_by_rout) & set(ptr_by_rout))))
    print('             reaches; %d of them name a (tag, offset) the pointer scan reached too.' % agree)
    if oor:
        print('FAIL: %d base+displacement attribution(s) fell outside the record -- binding lost:' % len(oor))
        for t, o, rout, rel, ln, c in oor[:20]:
            print('   tag %02X off %d  %s (%s:%d)  %s' % (t, o, rout, rel, ln, c))
        return 1
    if bad:
        print('FAIL: base+displacement and the event protocol disagree in:')
        for (rel, rout), what, a, b in bad:
            print('   %-38s %s  events=%s  pointer=%s (%s)'
                  % (rout, what,
                     ' '.join(('%02X' % x) if isinstance(x, int) else '%02X+%d' % x for x in a),
                     ' '.join(('%02X' % x) if isinstance(x, int) else '%02X+%d' % x for x in b), rel))
        return 1
    print('PASS: no base+displacement attribution leaves its record, and none contradicts'
          ' an event site that names the same field.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
